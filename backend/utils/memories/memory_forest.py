from collections import deque
from typing import List
from models.memory import Memory, MemoryConnectionNode
import database.memories as memories_db

async def build_memory_connection_tree(uid: str, root_id: str, max_depth: int, is_include_memory: bool = False) -> MemoryConnectionNode:
    queue = deque([(root_id, None, 0)])
    nodes = {}
    
    while queue:
        level_memory_ids = [memory_id for memory_id, _, depth in queue if depth == queue[0][2]]
        current_depth = queue[0][2]
        
        if current_depth > max_depth:
            break
        
        # Fetch all memories for the current level at once
        level_memories = {}
        for memory_data in await memories_db.get_memories_by_id(uid, level_memory_ids):  # Await the async call
            memory = Memory(**memory_data)
            level_memories[memory.id] = memory
        
        for memory_id, explanation, _ in queue:
            if memory_id not in level_memories:
                continue  # User might delete a memory afterwards, skip if memory is not found
            
            memory = level_memories[memory_id]
            if memory_id not in nodes:
                nodes[memory_id] = MemoryConnectionNode(memory_id=memory_id, explanation=explanation, memory=memory if is_include_memory else None, children=[])
            
            if current_depth < max_depth:
                for connection in memory.connections:
                    if connection.memory_id not in nodes:
                        queue.append((connection.memory_id, connection.explanation, current_depth + 1))
                    nodes[memory_id].children.append(MemoryConnectionNode(memory_id=connection.memory_id, explanation=connection.explanation, children=[]))
        
        # Remove processed memories from the queue
        queue = deque([item for item in queue if item[2] > current_depth])
    
    return nodes[root_id]

def get_all_memories_from_tree(node: MemoryConnectionNode, is_only_id: bool = False) -> List[Memory]:
    if is_only_id:
        nodes = [node.memory_id]
    else:
        nodes = [node.memory]

    for child in node.children:
        nodes.extend(get_all_memories_from_tree(child, is_only_id))
    return nodes

async def build_memory_forest(uid: str, memory_ids: List[str], max_depth: int, is_include_memory: bool = False) -> List[MemoryConnectionNode]:
    forest = []
    visited = set()
    
    for memory_id in memory_ids:
        if memory_id not in visited:
            tree = await build_memory_connection_tree(uid, memory_id, max_depth, is_include_memory)
            forest.append(tree)
            visited.update(get_all_memories_from_tree(tree, is_only_id=True))

    return forest

def get_all_memories_from_forest(forest: List[MemoryConnectionNode], is_only_id: bool = False) -> List[Memory]:
    memories = []
    for tree in forest:
        memories.extend(get_all_memories_from_tree(tree, is_only_id))
    return memories