from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field
from database._client import document_id_from_seed
from utils.diary.process_diary import generate_diary_for_uid
from models.memory import Memory
from utils.memories.memory_forest import build_memory_forest, 

class DiaryDescription(BaseModel):
    uid: str = Field(description="The user id")
    diary_start_utc: datetime = Field(description="The start time of the memories")
    diary_end_utc: datetime = Field(description="The end time of the memories")
    memory_ids: list[str] = Field(description="Selected memories ids within the time range")
    reference_memory_ids: list[str] = Field(description="The memory ids that are related to the selected memories")
    reference_diary_ids: list[str] = Field(description="The diary ids that are related for this diary generation")

    async def diary_description_from_daily_memories(uid: str, memories: list[Memory], start_utc: datetime = None, 
                                                    end_utc: datetime = None) -> 'DiaryDescription':
        forest = []
        visited = set()

        for memory_id in memory_ids:
            if memory_id not in visited:
                tree = await build_memory_connection_tree(uid, memory_id, depth)
                forest.append(tree)
                visited.update(get_all_nodes(tree))

        return DiaryDescription(
            uid=uid,
            diary_start_utc=start_utc,
            diary_end_utc=end_utc,
            memory_ids=[memory['id'] for memory in memories],
            reference_memory_ids=[]
            reference_diary_ids=[]
        )

    async def diary_description_from_memory_ids(uid: str, memory_ids: list[str], start_utc: datetime = None, 
                                                end_utc: datetime = None) -> 'DiaryDescription':
        return DiaryDescription(
            uid=uid,
            memory_start_utc=start_utc,
            memory_end_utc=end_utc,
            memory_ids=memory_ids,
            reference_memory_ids=[]
        )

class DiaryContent(BaseModel):
    footprint_jpeg: Optional[str] = Field(description="The serialized content of the footprint jpeg")
    content: str = Field(description="The diary content generated by llm")

    @staticmethod
    async def generate_content(metadata: 'DiaryMetadata') -> 'DiaryContent':
        return DiaryContent(
            footprint_jpeg="",
            content=await generate_diary_for_uid(metadata.uid, metadata.memory_ids)
        )
    
class Diary(BaseModel):
    id: str
    created_at: datetime
    updated_at: datetime
    user_deleted: bool = False

    description: DiaryDescription
    content: DiaryContent

    @staticmethod
    async def from_description(uid: str, memories: list[Memory], user_specified_created_at: None) -> 'DiaryMetadata':
        memory_ids=[memory['id'] for memory in memories]

        return DiaryMetadata(
            id=document_id_from_seed(uid.join(memory_ids)),
            uid=uid,
            created_at=user_specified_created_at if user_specified_created_at else datetime.utcnow(),
            updated_at=datetime.utcnow(),
            memory_ids = memory_ids,
            reference_memory_ids=[],
            user_deleted=False
        )
