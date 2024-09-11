from typing import List, Dict

from models.memory import Memory
from utils.llm import obtain_diary
from utils.memories.facts import get_prompt_data
from loguru import logger

def _get_categorized_memories(memories: list[Memory.dict]) -> Dict[str, List[Memory.dict]]:
    category_to_memories = {}
    for memory in memories:
        category = memory['structured']['category']
        if category not in category_to_memories:
            category_to_memories[category] = []

        category_to_memories[category].append(memory)

    return category_to_memories

def generate_diary_for_uid(uid: str, memories: list[Memory.dict]) -> str:
    user_name, user_made_facts, generated_facts  = get_prompt_data(uid)
    user_facts = [*user_made_facts, *generated_facts]
    category_to_memories = _get_categorized_memories(memories)

    result = obtain_diary(user_name, user_facts, category_to_memories)
    logger.info(result)

    return result