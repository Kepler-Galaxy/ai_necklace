import json
import os
import asyncio
import uuid
from datetime import datetime
from typing import List, Tuple
from pymongo import MongoClient, ASCENDING, DESCENDING
from bson import ObjectId
import utils.other.hume as hume
from models.memory import MemoryPhoto, PostProcessingStatus, PostProcessingModel
from models.transcript_segment import TranscriptSegment

# 初始化 MongoDB 客户端
mongo_uri = os.getenv('MONGO_URI')
client = MongoClient(mongo_uri)
db = client['your_database_name']


def upsert_memory(uid: str, memory_data: dict):
    if 'audio_base64_url' in memory_data:
        del memory_data['audio_base64_url']
    if 'photos' in memory_data:
        del memory_data['photos']
    db.collec
    user_ref = db['users'].find_one({"_id": uid})
    memory_ref = db['memories'].replace_one(
        {'_id': memory_data['id'], 'uid': uid},
        memory_data,
        upsert=True
    )


def get_memory(uid, memory_id):
    return db['memories'].find_one({"_id": memory_id, "uid": uid})


def get_memories(uid: str, limit: int = 100, offset: int = 0, include_discarded: bool = False):
    query = {"uid": uid, "deleted": False}
    if not include_discarded:
        query["discarded"] = False
    memories_ref = db['memories'].find(query).sort("created_at", DESCENDING).skip(offset).limit(limit)
    return list(memories_ref)


def update_memory(uid: str, memory_id: str, memory_data: dict):
    db['memories'].update_one({"_id": memory_id, "uid": uid}, {"$set": memory_data})


def delete_memory(uid, memory_id):
    db['memories'].update_one({"_id": memory_id, "uid": uid}, {"$set": {"deleted": True}})


def filter_memories_by_date(uid, start_date, end_date):
    query = {
        "uid": uid,
        "created_at": {"$gte": start_date, "$lte": end_date},
        "discarded": False,
    }
    return list(db['memories'].find(query).sort("created_at", DESCENDING))


def get_memories_by_id(uid, memory_ids):
    memories = db['memories'].find({"_id": {"$in": memory_ids}, "uid": uid})
    return list(memories)


# Open Glass
def store_memory_photos(uid: str, memory_id: str, photos: List[MemoryPhoto]):
    batch = []
    for photo in photos:
        photo_id = str(uuid.uuid4())
        data = photo.dict()
        data['id'] = photo_id
        data['memory_id'] = memory_id
        batch.append(data)
    if batch:
        db['photos'].insert_many(batch)


def get_memory_photos(uid: str, memory_id: str):
    return list(db['photos'].find({"memory_id": memory_id, "uid": uid}))


def update_memory_events(uid: str, memory_id: str, events: List[dict]):
    db['memories'].update_one({"_id": memory_id, "uid": uid}, {"$set": {"structured.events": events}})


# VISIBILITY
def set_memory_visibility(uid: str, memory_id: str, visibility: str):
    db['memories'].update_one({"_id": memory_id, "uid": uid}, {"$set": {"visibility": visibility}})


# Claude outputs
async def _get_public_memory(db, uid: str, memory_id: str):
    memory_data = db['memories'].find_one({"_id": memory_id, "uid": uid, "visibility": "public", "deleted": False})
    return memory_data


async def _get_public_memories(data: List[Tuple[str, str]]):
    tasks = [_get_public_memory(db, uid, memory_id) for uid, memory_id in data]
    memories = await asyncio.gather(*tasks)
    return [memory for memory in memories if memory is not None]


def run_get_public_memories(data: List[Tuple[str, str]]):
    return asyncio.run(_get_public_memories(data))


# POST PROCESSING
def set_postprocessing_status(uid: str, memory_id: str, status: PostProcessingStatus, fail_reason: str = None,
                              model: PostProcessingModel = PostProcessingModel.fal_whisperx):
    db['memories'].update_one({"_id": memory_id, "uid": uid}, {"$set": {
        "postprocessing.status": status,
        "postprocessing.model": model,
        "postprocessing.fail_reason": fail_reason
    }})


def store_model_segments_result(uid: str, memory_id: str, model_name: str, segments: List[TranscriptSegment]):
    batch = []
    for segment in segments:
        segment_data = segment.dict()
        segment_data["memory_id"] = memory_id
        segment_data["model_name"] = model_name
        batch.append(segment_data)
    if batch:
        db['segments'].insert_many(batch)


def update_memory_segments(uid: str, memory_id: str, segments: List[dict]):
    db['memories'].update_one({"_id": memory_id, "uid": uid}, {"$set": {"transcript_segments": segments}})


def store_model_emotion_predictions_result(uid: str, memory_id: str, model_name: str,
                                           predictions: List[hume.HumeJobModelPredictionResponseModel]):
    now = datetime.now()
    batch = []
    for prediction in predictions:
        prediction_data = {
            "memory_id": memory_id,
            "model_name": model_name,
            "created_at": now,
            "start": prediction.time[0],
            "end": prediction.time[1],
            "emotions": json.dumps(hume.HumePredictionEmotionResponseModel.to_multi_dict(prediction.emotions)),
        }
        batch.append(prediction_data)
    if batch:
        db['predictions'].insert_many(batch)
