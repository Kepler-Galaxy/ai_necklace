from typing import List
from models.memory import Memory, MemoryConnection
import database.memories as memories_db
from database.vector_db import query_vectors
from utils.llm import generate_embedding, explain_relationship
from loguru import logger

def get_similar_memories(memory: Memory, uid:str, top_k: int = 5) -> List[str]:
    """
    Retrieves the IDs of the top_k most similar memories to the given memory.
    """
    try:
        content = memory.structured
        if not content:
            raise ValueError(f"No content found for memory_id: {memory.id}")
        
        # Use query_vectors to get similar memory IDs
        similar_ids = query_vectors(str(content), uid, k=top_k + 1)
        # Exclude the original memory_id if present in the results
        similar_ids = [id for id in similar_ids if id != memory.id]
        return similar_ids[:top_k]
    except Exception as e:
        print(f"Error in get_similar_memories: {e}")
        return []

def explain_related_memories(memory: Memory, uid:str, top_k: int = 3) -> List[MemoryConnection]:
    """
    Fetches related memories and explains their relevance.
    """
    similar_memory_ids = get_similar_memories(memory, uid, top_k)
    
    if not similar_memory_ids:
        return []
    
    # Fetch related memories from the database
    related_memories = memories_db.get_memories_by_id(uid, memory_ids=similar_memory_ids)
    
    connections = []
    for related_memory in related_memories:
        try:
            logger.info(f'Explaining relationship between {memory.id} and {related_memory["id"]}')
            relationship_output = explain_relationship(memory, Memory(**related_memory))
            if relationship_output.related:
                connections.append(MemoryConnection(memory_id=related_memory['id'], explanation=relationship_output.explanation))
        except Exception as e:
            print(f"Error explaining relationship between {memory.id} and {related_memory['id']}: {e}")
    
    return connections