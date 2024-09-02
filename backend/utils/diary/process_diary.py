from typing import List, Dict

from models.memory import Memory
from database.memories import get_memories_by_id
from database.facts import get_facts
from database.auth import get_user_name
from utils.llm import obtain_diary

def _get_categorized_memories_by_ids(uid: str, memory_ids: List[str]) -> Dict[str, List[Memory]]:
    category_to_memories = {}
    memories = get_memories_by_id(uid, memory_ids)
    for memory in memories:
        category = memory.structured.category.value
        if category not in category_to_memories:
            category_to_memories[category] = []

        category_to_memories[category].append(memory)

    return category_to_memories

def generate_diary_for_uid(uid: str, memory_ids: list[str]) -> str:
    user_name = get_user_name(uid)
    user_facts = get_facts(uid)
    category_to_memories = _get_categorized_memories_by_ids(uid, memory_ids)

    return obtain_diary(user_name, user_facts, category_to_memories)