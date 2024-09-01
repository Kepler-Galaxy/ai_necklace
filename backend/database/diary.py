from typing import List

from google.cloud import firestore
from google.cloud.firestore_v1 import FieldFilter

from ._client import db
from database.memories import get_memories_by_id
from utils.retrieval.rag import retrieve_memories_for_topics, retrieve_for_topic


def get_diaries(uid: str, limit: int = 100, offset: int = 0):
    diaries_ref = db.collection('users').document(uid).collection('diaries')
    diaries_ref = diaries_ref.order_by('created_at', direction=firestore.Query.DESCENDING).where(
        filter=FieldFilter('deleted', '==', False))
    diaries_ref = diaries_ref.limit(limit).offset(offset)
    return [doc.to_dict() for doc in diaries_ref.stream()]