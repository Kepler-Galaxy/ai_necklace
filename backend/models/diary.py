from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field
from database._client import document_id_from_seed
from utils.diary.process_diary import generate_diary_for_uid
from models.memory import Memory

class Diary(BaseModel):
    footprint_jpeg: Optional[str] = Field(description="The serialized content of the footprint jpeg")
    content: str = Field(description="The summary text generated by llm")

class DiaryDB(Diary):
    id: str
    uid: str
    created_at: datetime
    updated_at: datetime
    memory_ids: list[str]

    user_deleted: bool = False
    # topic_to_memory_ids_in_timerange: dict[str, list[str]]
    # topic_to_memory_ids_related: dict[str, list[str]]
    # TODO(yiqi): let user add/remove memory for diary. allow user to add/delete diary in app.
    
    # # don't allow user to add Diary directly, only memory is allowed to add
    # # user can trigger diary regeneration by adding/removing related memory
    # edited: bool = False
    # user_added_topic_to_memory_ids: dict[str, list[str]]
    # user_removed_topic_to_memory_ids: dict[str, list[str]]
    # # TODO: should add diary status?

    @staticmethod
    def from_memories(uid: str, memories: list[Memory]) -> 'DiaryDB':
        memory_ids=[memory['id'] for memory in memories]

        return DiaryDB(
            id=document_id_from_seed(uid.join(memory_ids)),
            uid=uid,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
            memory_ids = memory_ids,
            footprint_jpeg="",
            content = generate_diary_for_uid(uid, memories)
        )
