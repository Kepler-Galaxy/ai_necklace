from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field

from database._client import document_id_from_seed
from database.memories import get_memories_by_id
from utils.retrieval.rag import retrieve_memories_for_topics, retrieve_for_topic

class Diary(BaseModel):
    footprint_jpeg: str = Field(description="The serialized content of the footprint jpeg")
    topic_to_summary: dict[str, str]
    content: str

    @staticmethod
    def from_memories(uid: str, start_timestamp, end_timestamp) -> 'DiaryDB':
        return DiaryDB(
            id=document_id_from_seed(fact.content),
            uid=uid,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
            # TODO
        )

    @staticmethod
    def get_facts_as_str(facts):
        existing_facts = [f"{f.content} ({f.category.value})" for f in facts]
        return '' if not existing_facts else '\n- ' + '\n- '.join(existing_facts)


class DiaryDB(Diary):
    id: str
    uid: str
    created_at: datetime
    updated_at: datetime

    topic_to_memory_ids_in_timerange: dict[str, list[str]]
    topic_to_memory_ids_related: dict[str, list[str]]


    # don't allow user to add Diary directly, only memory is allowed to add
    # user can trigger diary regeneration by adding/removing related memory
    edited: bool = False
    user_added_topic_to_memory_ids: dict[str, list[str]]
    user_removed_topic_to_memory_ids: dict[str, list[str]]

    user_deleted: bool = False

    # TODO: should add diary status?
    diary: Diary

    @staticmethod
    def from_memories(uid: str, start_timestamp, end_timestamp) -> 'DiaryDB':
        return DiaryDB(
            id=document_id_from_seed(fact.content),
            uid=uid,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
            # TODO
        )
