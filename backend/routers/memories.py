from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from loguru import logger
import os
import aiofiles
from utils.memories.memory_forest import build_memory_connection_tree, get_all_nodes

import database.memories as memories_db
import database.redis_db as redis_db
from database.vector_db import delete_vector
from models.memory import *
from routers.speech_profile import expand_speech_profile
from utils.memories.location import get_google_maps_location
from utils.memories.process_memory import process_memory
from utils.other import endpoints as auth
from utils.other.cos_storage import get_memory_recording_if_exists, \
    delete_additional_profile_audio, delete_speech_sample_for_people, upload_memory_recording
from utils.plugins import trigger_external_integrations
from utils.string import words_count
from datetime import datetime
from fastapi import Body

router = APIRouter()


def _get_memory_by_id(uid: str, memory_id: str) -> dict:
    memory = memories_db.get_memory(uid, memory_id)
    if memory is None or memory.get('deleted', False):
        raise HTTPException(status_code=404, detail="Memory not found")
    return memory


@router.post("/v1/memories", response_model=CreateMemoryResponse, tags=['memories'])
def create_memory(
        create_memory: CreateMemory, trigger_integrations: bool, language_code: Optional[str] = None,
        source: Optional[str] = None, uid: str = Depends(auth.get_current_user_uid)
):
    """
    Create Memory endpoint.
    :param source:
    :param create_memory: data to create memory
    :param trigger_integrations: determine if triggering the on_memory_created plugins webhooks.
    :param language_code: language.
    :param uid: user id.
    :return: The new memory created + any messages triggered by on_memory_created integrations.

    TODO: Should receive raw segments by deepgram, instead of the beautified ones? and get beautified on read?
    """
    if not create_memory.transcript_segments and not create_memory.photos:
        logger.error(uid, "No transcript segments or photos provided")
        raise HTTPException(status_code=400, detail="Transcript segments or photos are required")

    geolocation = create_memory.geolocation
    if geolocation and not geolocation.google_place_id:
        create_memory.geolocation = get_google_maps_location(geolocation.latitude, geolocation.longitude)

    if not language_code:
        language_code = create_memory.language
    else:
        create_memory.language = language_code

    if create_memory.processing_memory_id:
        print(
            f"warn: split-brain in memory (maybe) by forcing new memory creation during processing. uid: {uid}, processing_memory_id: {create_memory.processing_memory_id}")

    memory = process_memory(uid, language_code, create_memory, force_process=source == 'speech_profile_onboarding')
    if not trigger_integrations:
        return CreateMemoryResponse(memory=memory, messages=[])

    if not memory.discarded:
        memories_db.set_postprocessing_status(uid, memory.id, PostProcessingStatus.not_started)
        memory.postprocessing = MemoryPostProcessing(status=PostProcessingStatus.not_started,
                                                     model=PostProcessingModel.fal_whisperx)
    # TODO(yiqi): turn off external plugins for now, since fetching from github results in a lot of
    # failing memory creations. Need to think about how to handle plugins before our product release.
    # messages = trigger_external_integrations(uid, memory)
    return CreateMemoryResponse(memory=memory, messages=[])


@router.post('/v1/memories/{memory_id}/reprocess', response_model=Memory, tags=['memories'])
def reprocess_memory(
        memory_id: str, language_code: Optional[str] = None, uid: str = Depends(auth.get_current_user_uid)
):
    """
    Whenever a user wants to reprocess a memory, or wants to force process a discarded one
    :return: The updated memory after reprocessing.
    """
    print('')
    memory = memories_db.get_memory(uid, memory_id)
    if memory is None:
        raise HTTPException(status_code=404, detail="Memory not found")
    memory = Memory(**memory)
    if not language_code:
        language_code = memory.language or 'en'

    return process_memory(uid, language_code, memory, force_process=True)


@router.get('/v1/memories', response_model=List[Memory], tags=['memories'])
def get_memories(limit: int = 100, offset: int = 0, uid: str = Depends(auth.get_current_user_uid)):
    logger.info(uid, "get_memories", limit, offset)
    return memories_db.get_memories(uid, limit, offset, include_discarded=True)


@router.get("/v1/memories/{memory_id}", response_model=Memory, tags=['memories'])
def get_memory_by_id(memory_id: str, uid: str = Depends(auth.get_current_user_uid)):
    return _get_memory_by_id(uid, memory_id)


@router.get("/v1/memories/{memory_id}/photos", response_model=List[MemoryPhoto], tags=['memories'])
def get_memory_photos(memory_id: str, uid: str = Depends(auth.get_current_user_uid)):
    _get_memory_by_id(uid, memory_id)
    return memories_db.get_memory_photos(uid, memory_id)


@router.get(
    "/v1/memories/{memory_id}/transcripts", response_model=Dict[str, List[TranscriptSegment]], tags=['memories']
)
def get_memory_transcripts_by_models(memory_id: str, uid: str = Depends(auth.get_current_user_uid)):
    _get_memory_by_id(uid, memory_id)
    return memories_db.get_memory_transcripts_by_model(uid, memory_id)


@router.delete("/v1/memories/{memory_id}", status_code=204, tags=['memories'])
def delete_memory(memory_id: str, uid: str = Depends(auth.get_current_user_uid)):
    print('delete_memory', memory_id, uid)
    memories_db.delete_memory(uid, memory_id)
    delete_vector(memory_id)
    return {"status": "Ok"}


@router.get("/v1/memories/{memory_id}/recording", response_model=dict, tags=['memories'])
def memory_has_audio_recording(memory_id: str, uid: str = Depends(auth.get_current_user_uid)):
    _get_memory_by_id(uid, memory_id)
    return {'has_recording': get_memory_recording_if_exists(uid, memory_id) is not None}


@router.patch("/v1/memories/{memory_id}/events", response_model=dict, tags=['memories'])
def set_memory_events_state(
        memory_id: str, data: SetMemoryEventsStateRequest, uid: str = Depends(auth.get_current_user_uid)
):
    memory = _get_memory_by_id(uid, memory_id)
    memory = Memory(**memory)
    events = memory.structured.events
    for i, event_idx in enumerate(data.events_idx):
        if event_idx >= len(events):
            continue
        events[event_idx].created = data.values[i]

    memories_db.update_memory_events(uid, memory_id, [event.dict() for event in events])
    return {"status": "Ok"}


@router.patch('/v1/memories/{memory_id}/segments/{segment_idx}/assign', response_model=Memory, tags=['memories'])
def set_assignee_memory_segment(
        memory_id: str, segment_idx: int, assign_type: str, value: Optional[str] = None,
        use_for_speech_training: bool = True, uid: str = Depends(auth.get_current_user_uid)
):
    """
    Another complex endpoint.

    Modify the assignee of a segment in the transcript of a memory.
    But,
    if `use_for_speech_training` is True, the corresponding audio segment will be used for speech training.

    Speech training of whom?

    If `assign_type` is 'is_user', the segment will be used for the user speech training.
    If `assign_type` is 'person_id', the segment will be used for the person with the given id speech training.

    What is required for a segment to be used for speech training?
    1. The segment must have more than 5 words.
    2. The memory audio file shuold be already stored in the user's bucket.

    :return: The updated memory.
    """
    logger.info(uid, "set_assignee_memory_segment", memory_id, segment_idx, assign_type, value,)
    memory = _get_memory_by_id(uid, memory_id)
    memory = Memory(**memory)

    if value == 'null':
        value = None

    is_unassigning = value is None or value is False

    if assign_type == 'is_user':
        memory.transcript_segments[segment_idx].is_user = bool(value) if value is not None else False
        memory.transcript_segments[segment_idx].person_id = None
    elif assign_type == 'person_id':
        memory.transcript_segments[segment_idx].is_user = False
        memory.transcript_segments[segment_idx].person_id = value
    else:
        logger.error(uid, "set_assignee_memory_segment", "Invalid assign type", assign_type)
        raise HTTPException(status_code=400, detail="Invalid assign type")

    memories_db.update_memory_segments(uid, memory_id, [segment.dict() for segment in memory.transcript_segments])
    segment_words = words_count(memory.transcript_segments[segment_idx].text)

    # TODO: can do this async
    if use_for_speech_training and not is_unassigning and segment_words > 15:  # some decent sample at least
        person_id = value if assign_type == 'person_id' else None
        expand_speech_profile(memory_id, uid, segment_idx, assign_type, person_id)
    else:
        path = f'{memory_id}_segment_{segment_idx}.wav'
        delete_additional_profile_audio(uid, path)
        delete_speech_sample_for_people(uid, path)

    return memory


# *********************************************
# ************* SHARING MEMORIES **************
# *********************************************

@router.patch('/v1/memories/{memory_id}/visibility', tags=['memories'])
def set_memory_visibility(
        memory_id: str, value: MemoryVisibility, uid: str = Depends(auth.get_current_user_uid)
):
    print('update_memory_visibility', memory_id, value, uid)
    _get_memory_by_id(uid, memory_id)
    memories_db.set_memory_visibility(uid, memory_id, value)
    if value == MemoryVisibility.private:
        redis_db.remove_memory_to_uid(memory_id)
        redis_db.remove_public_memory(memory_id)
    else:
        redis_db.store_memory_to_uid(memory_id, uid)
        redis_db.add_public_memory(memory_id)

    return {"status": "Ok"}


@router.get("/v1/memories/{memory_id}/shared", response_model=Memory, tags=['memories'])
def get_shared_memory_by_id(memory_id: str):
    uid = redis_db.get_memory_uid(memory_id)
    if not uid:
        raise HTTPException(status_code=404, detail="Memory is private")

    # TODO: include speakers and people matched?
    # TODO: other fields that  shouldn't be included?
    memory = _get_memory_by_id(uid, memory_id)
    visibility = memory.get('visibility', MemoryVisibility.private)
    if not visibility or visibility == MemoryVisibility.private:
        raise HTTPException(status_code=404, detail="Memory is private")
    memory = Memory(**memory)
    memory.geolocation = None
    return memory


@router.get("/v1/public-memories", response_model=List[Memory], tags=['memories'])
def get_public_memories(offset: int = 0, limit: int = 1000):
    memories = redis_db.get_public_memories()
    data = []
    for memory_id in memories:
        uid = redis_db.get_memory_uid(memory_id)
        if not uid:
            continue
        data.append([uid, memory_id])
    # TODO: sort in some way to have proper pagination

    memories = memories_db.run_get_public_memories(data[offset:offset + limit])
    for memory in memories:
        memory['geolocation'] = None
    return memories

@router.post("/v1/memories/{memory_id}/upload_audio", status_code=200, tags=['memories'])
async def upload_memory_audio_recording(
    memory_id: str,
    file: UploadFile = File(...),
    uid: str = Depends(auth.get_current_user_uid)
):
    """
    Upload an audio recording for a specific memory.
    """
    memory = _get_memory_by_id(uid, memory_id)
    
    try:
        file_size = file.file.seek(0, 2)
        file.file.seek(0)  # Reset file pointer to the beginning
        
        # if file_size > 20 * 1024 * 1024:  # 20 MB limit
        #     raise HTTPException(status_code=400, detail="File size exceeds the 20 MB limit.")
        temp_file_path = f'_temp/{memory_id}.wav'
        async with aiofiles.open(temp_file_path, 'wb') as temp_file:
            while chunk := await file.read(1024 * 1024):  # Read in 1MB chunks
                await temp_file.write(chunk)
        
        upload_memory_recording(temp_file_path, uid, memory_id)
        
        os.remove(temp_file_path)  # Clean up temporary file
        
        return {"message": "Audio file uploaded successfully"}
    except Exception as e:
        logger.error(f"Error uploading audio file for memory {memory_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to upload audio file")

@router.post("/v1/memories/wechat-article", response_model=Memory, tags=['memories'])
def create_memory_from_wechat_article(
    article_link: str = Body(..., embed=True),
    uid: str = Depends(auth.get_current_user_uid)
):
    """
    Create a memory from a WeChat article link.
    :param article_link: The URL of the WeChat article.
    :param uid: User ID.
    :return: The newly created memory.
    """
    logger.info(f'create_memory_from_wechat_article from {article_link}')

    try:
        create_memory = CreateMemory(
            started_at=datetime.utcnow(),
            finished_at=datetime.utcnow(),
            external_link=ExternalLink(external_link_description=ExternalLinkDescription.from_web_article(article_link), 
                                       web_content_response=None),
            source=MemorySource.web_link,
            language="zh",  # It only affects the conversation, the CreateMemory and Structured should be refactored to separate all sources completely.
        )

        memory = process_memory(uid, "zh", create_memory, force_process=True)
        return memory

    except Exception as e:
        logger.error(f'Failed to create memory from WeChat article: {str(e)}')
        raise HTTPException(status_code=500, detail=f"Failed to create memory: {str(e)}")
    
@router.post("/v1/memories/connections_graph", response_model=MemoryConnectionsGraphResponse, tags=['memories'])
async def get_memory_connections_graph(request: MemoryConnectionsGraphRequest, uid: str = Depends(auth.get_current_user_uid)):
    memory_ids = set(request.memory_ids)
    depth = request.memory_connection_depth
    
    forest = []
    visited = set()
    
    for memory_id in memory_ids:
        if memory_id not in visited:
            tree = await build_memory_connection_tree(uid, memory_id, depth)
            forest.append(tree)
            visited.update(get_all_nodes(tree))
    
    return MemoryConnectionsGraphResponse(forest=forest)

