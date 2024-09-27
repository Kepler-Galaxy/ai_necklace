from typing import List, Dict

from google.cloud import firestore
from google.cloud.firestore_v1 import FieldFilter

from ._client import db

def get_diaries(uid: str, limit: int = 100, offset: int = 0):
    diaries_ref = db.collection('users').document(uid).collection('diaries')
    diaries_ref = diaries_ref.order_by('created_at', direction=firestore.Query.DESCENDING).where(
        filter=FieldFilter('user_deleted', '==', False))
    diaries_ref = diaries_ref.limit(limit).offset(offset)
    return [doc.to_dict() for doc in diaries_ref.stream()]

def save_diary(uid: str, diary: dict):
    diaries_ref = db.collection('users').document(uid).collection('diaries')
    diary_ref = diaries_ref.document(diary['id'])
    diary_ref.set(diary)

def delete_diary(uid, diary_id):
    user_ref = db.collection('users').document(uid)
    diary_ref = user_ref.collection('diaries').document(diary_id)
    diary_ref.update({'user_deleted': True})

def get_diaries_by_id(uid: str, diary_ids: List[str]) -> List[dict]:
    diaries_ref = db.collection('users').document(uid).collection('diaries')
    diaries_ref = diaries_ref.where(filter=FieldFilter('id', 'in', diary_ids))
    return [doc.to_dict() for doc in diaries_ref.stream()]