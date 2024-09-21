from collections import deque
from typing import Set, Dict, List
from models.memory import Memory, MemoryConnectionNode
import database.memories as memories_db

async def build_memory_connection_tree(uid: str, root_id: str, max_depth: int) -> MemoryConnectionNode:
    queue = deque([(root_id, None, 0)])
    nodes = {}
    
    while queue:
        level_memory_ids = [memory_id for memory_id, _, depth in queue if depth == queue[0][2]]
        current_depth = queue[0][2]
        
        if current_depth > max_depth:
            break
        
        # Fetch all memories for the current level at once
        level_memories = {}
        for memory_data in memories_db.get_memories_by_id(uid, level_memory_ids):
            memory = Memory(**memory_data)
            level_memories[memory.id] = memory
        
        for memory_id, explanation, _ in queue:    
            memory = level_memories[memory_id]
            if memory_id not in nodes:
                nodes[memory_id] = MemoryConnectionNode(memory_id=memory_id, explanation=explanation)
            
            if current_depth < max_depth:
                for connection in memory.connections:
                    if connection.memory_id not in nodes:
                        queue.append((connection.memory_id, connection.explanation, current_depth + 1))
                    nodes[memory_id].children.append(MemoryConnectionNode(memory_id=connection.memory_id, explanation=connection.explanation))
        
        # Remove processed memories from the queue
        queue = deque([item for item in queue if item[2] > current_depth])
    
    return nodes[root_id]

def get_all_nodes(node: MemoryConnectionNode) -> Set[str]:
    nodes = {node.memory_id}
    for child in node.children:
        nodes.update(get_all_nodes(child))
    return nodes