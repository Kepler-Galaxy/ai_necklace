from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field
from typing import Tuple
from models.memory import Memory
from database._client import document_id_from_seed
from utils.llm import obtain_recent_summary
from utils.memories.memory_forest import build_memory_forest, get_all_memories_from_forest
from database.memories import filter_memories_by_date, get_memories_by_id
from database.diary import get_diaries_by_id
from loguru import logger
import asyncio
from openai import RateLimitError
from utils.string import words_count
MAX_WORDS = 50000

def truncate_content(conversation_history: str, articles_read: str, related_memories: str, max_words: int) -> tuple:
    total_words = words_count(conversation_history) + words_count(articles_read) + words_count(related_memories)
    
    if total_words <= max_words:
        return conversation_history, articles_read, related_memories
    
    words_to_remove = total_words - max_words
    
    # Remove words from related_memories first
    if words_to_remove > 0 and related_memories:
        related_words = related_memories.split()
        if words_count(related_words) <= words_to_remove:
            words_to_remove -= words_count(related_words)
            related_memories = ""
        else:
            related_memories = " ".join(related_words[:-words_to_remove])
            words_to_remove = 0
    
    # Then remove from articles_read if necessary
    if words_to_remove > 0 and articles_read:
        article_words = articles_read.split()
        if words_count(article_words) <= words_to_remove:
            words_to_remove -= words_count(article_words)
            articles_read = ""
        else:
            articles_read = " ".join(article_words[:-words_to_remove])
            words_to_remove = 0
    
    # Finally, remove from conversation_history if still necessary
    if words_to_remove > 0:
        conv_words = conversation_history.split()
        conversation_history = " ".join(conv_words[:-words_to_remove])
    
    return conversation_history, articles_read, related_memories

async def obtain_recent_summary_with_retry(conversation_history: str, articles_read: str, related_memories: str) -> str:
    max_retries = 3
    retry_delay = 60  # 1 minute

    for attempt in range(max_retries):
        try:
            truncated_conv, truncated_articles, truncated_memories = truncate_content(
                conversation_history, articles_read, related_memories, MAX_WORDS
            )
            result = await obtain_recent_summary(truncated_conv, truncated_articles, truncated_memories)
            return result
        except RateLimitError:
            if attempt < max_retries - 1:
                logger.warning(f"Rate limit exceeded. Retrying in {retry_delay} seconds...")
                await asyncio.sleep(retry_delay)
            else:
                logger.error("Max retries reached. Unable to obtain recent summary.")
                raise
        except Exception as e:
            logger.error(f"Error obtaining recent summary: {str(e)}")
            raise

class DiaryConfig(BaseModel):
    uid: str
    diary_start_utc: datetime
    diary_end_utc: datetime
    
class DiaryUserConfig(BaseModel):
    # TODO(yiqi): allow user to edit the memory ids, in which way?
    memory_ids_to_add: list[str]
    memory_ids_to_remove: list[str]
    diary_ids_to_add: list[str]
    diary_ids_to_remove: list[str]


class DiaryDescription(BaseModel):
    memory_ids: list[str]
    reference_memory_ids: list[str]
    reference_diary_ids: list[str]

class DiaryRawMaterials(BaseModel):
    memories: list[dict]
    reference_memories: list[dict]
    reference_diaries: list[dict]

async def description_and_raw_materials_from_configs(config: DiaryConfig, user_config: DiaryUserConfig = None) -> Tuple[DiaryDescription, DiaryRawMaterials]:
    memories = filter_memories_by_date(config.uid, config.diary_start_utc, config.diary_end_utc)
    
    if user_config:
        memories = [memory for memory in memories if memory['id'] not in user_config.memory_ids_to_remove]
        memories_to_add = get_memories_by_id(config.uid, user_config.memory_ids_to_add)
        memories.extend(memories_to_add)
    
    memory_ids = [memory['id'] for memory in memories]
    forest = await build_memory_forest(config.uid, memory_ids, max_depth=2, is_include_memory=True)
    reference_memories = get_all_memories_from_forest(forest)
    reference_memories = [memory for memory in reference_memories if memory['id'] not in memory_ids]
    
    if reference_memories:
        reference_memory_ids = [memory['id'] for memory in reference_memories]
    else:
        reference_memory_ids = []
    
    # TODO: Implement reference memories and diaries retrieval
    reference_diaries = []
    
    description = DiaryDescription(
        memory_ids=memory_ids,
        reference_memory_ids=reference_memory_ids,
        reference_diary_ids=[]
    )
    raw_materials = DiaryRawMaterials(
        memories=memories,
        reference_memories=reference_memories,  # No need to call .dict() here
        reference_diaries=reference_diaries
    )
    
    return description, raw_materials

async def raw_materials_from_description(description: DiaryDescription) -> DiaryRawMaterials:
    memories = get_memories_by_id(description.memory_ids)
    reference_memories = get_memories_by_id(description.reference_memory_ids)
    reference_diaries = get_diaries_by_id(description.reference_diary_ids)
    
    return DiaryRawMaterials(
        memories=memories,
        reference_memories=reference_memories,
        reference_diaries=reference_diaries
    )
 
async def diary_content_from_raw_materials(raw_materials: DiaryRawMaterials) -> str:
    conversation_history = []
    articles_read = []
    related_memories = []

    for memory in raw_materials.memories:
        if 'external_link' in memory and memory['external_link']:
            articles_read.append(memory)
        elif 'transcript_segments' in memory and memory['transcript_segments']:
            conversation_history.append(memory)
        else:
            logger.warning(f"Memory {memory.get('id', 'unknown')} doesn't have external_link or transcript_segments")

    related_memories = raw_materials.reference_memories

    conversation_history_str = Memory.memories_to_string(conversation_history, include_raw_data=True)
    articles_read_str = Memory.memories_to_string(articles_read, include_action_items=False, include_raw_data=True)
    related_memories_str = Memory.memories_to_string(related_memories, include_action_items=True, include_raw_data=False)

    result = await obtain_recent_summary_with_retry(conversation_history_str, articles_read_str, related_memories_str)
    logger.info(result)

    return result

class DiaryContent(BaseModel):
    footprint_jpeg: Optional[str] = Field(description="The serialized content of the footprint jpeg")
    content: str = Field(description="The diary content generated by llm")

    @staticmethod
    async def generate_content(raw_materials: 'DiaryRawMaterials') -> 'DiaryContent':
        if len(raw_materials.memories) == 0:
            logger.info(f"No memories found for diary generation, skip it")
            return DiaryContent(
                footprint_jpeg="",
                content=""
            )
        
        return DiaryContent(
            footprint_jpeg="",
            content=await diary_content_from_raw_materials(raw_materials)
        )
    
class Diary(BaseModel):
    id: str
    uid: str
    created_at: datetime
    updated_at: datetime
    user_deleted: bool = False
    
    config: DiaryConfig
    user_config: Optional[DiaryUserConfig]
    description: DiaryDescription
    # Don't store raw materials in the diary, it's too large
    content: DiaryContent

async def diary_from_configs(config: DiaryConfig, user_config: DiaryUserConfig = None, use_end_utc_for_debug: bool = False) -> Diary:
    description, raw_materials = await description_and_raw_materials_from_configs(config, user_config)
    content = await DiaryContent.generate_content(raw_materials)
    return Diary(
        id=document_id_from_seed("".join(description.memory_ids)),
        uid=config.uid,
        created_at=datetime.utcnow() if not use_end_utc_for_debug else config.diary_end_utc,
        updated_at=datetime.utcnow(),
        user_deleted=False,
        config=config,
        user_config=user_config,
        description=description,
        content=content,
    )

# TODO(yiqi): fix the bug when this funciton needs to be called.
# async def diary_regeneration_from_description(description: DiaryDescription) -> Diary:
#     raw_materials = await raw_materials_from_description(description)
#     content = await DiaryContent.generate_content(raw_materials)
#     return Diary(
#         id=description.id,
#         created_at=description.created_at,
#         updated_at=datetime.utcnow(),
#         user_deleted=False,

#         config=description.config,
#         user_config=description.user_config,
#         description=description,
#         content=content,
#     )
