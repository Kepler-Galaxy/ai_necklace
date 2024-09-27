from collections import deque
from typing import List, Union, Dict, Set
from models.memory import Memory, MemoryConnectionNode
import database.memories as memories_db
from loguru import logger

async def build_memory_connection_forest(uid: str, memory_ids: List[str], max_depth: int, is_include_memory: bool = False) -> List[MemoryConnectionNode]:
    visited = set()
    memory_cache = {}
    
    async def build_tree(memory_id: str, depth: int, explanation: str = None) -> MemoryConnectionNode:
        if depth > max_depth or memory_id in visited:
            return None
        
        visited.add(memory_id)
        
        if memory_id not in memory_cache:
            memory_data = memories_db.get_memories_by_id(uid, [memory_id])
            if not memory_data:
                return None
            memory_cache[memory_id] = memory_data[0]  # Store the dict directly
        
        memory = memory_cache[memory_id]
        
        children = []
        if depth < max_depth and memory.get('connections'):
            for connection in memory['connections']:
                child_node = await build_tree(connection['memory_id'], depth + 1, connection['explanation'])
                if child_node:
                    children.append(child_node)
        
        return MemoryConnectionNode(
            memory_id=memory_id,
            explanation=explanation,
            memory=memory if is_include_memory else None,
            children=children
        )
    
    forest = []
    for memory_id in memory_ids:
        if memory_id not in visited:
            tree = await build_tree(memory_id, 0)
            if tree:
                forest.append(tree)
    
    return forest

async def build_memory_forest(uid: str, memory_ids: List[str], max_depth: int, is_include_memory: bool = False) -> List[MemoryConnectionNode]:
    logger.info(f"Building memory forest for {len(memory_ids)} memories with max depth {max_depth}")
    return await build_memory_connection_forest(uid, memory_ids, max_depth, is_include_memory)

def get_all_memories_from_tree(node: MemoryConnectionNode, is_only_id: bool = False) -> Union[List[Dict], List[str]]:
    if node is None:
        return []
    
    if is_only_id:
        nodes = [node.memory_id]
    else:
        assert node.memory is not None, "Memory is None"
        nodes = [node.memory]

    for child in node.children:
        nodes.extend(get_all_memories_from_tree(child, is_only_id))
    return nodes

def get_all_memories_from_forest(forest: List[MemoryConnectionNode], is_only_id: bool = False) -> Union[List[Dict], List[str]]:
    if not forest:
        return []
    
    memories = []
    for tree in forest:
        memories.extend(get_all_memories_from_tree(tree, is_only_id))
    return memories