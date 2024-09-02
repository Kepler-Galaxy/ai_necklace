import datetime

from fastapi import APIRouter, Depends, HTTPException

import database.memories as memories_db
import database.diary as diaries_db
from utils.other import endpoints as auth
from models.diary import DiaryDB

router = APIRouter()

@router.get('/v1/diaries', tags=['diaries'])
def get_diaries(limit: int = 100, offset: int = 0, uid: str = Depends(auth.get_current_user_uid)):
    return diaries_db.get_diaries(uid, limit, offset)

@router.delete('/v1/diaries/{diary_id}', tags=['diaries'])
def delete_fact(diary_id: str, uid: str = Depends(auth.get_current_user_uid)):
    diaries_db.delete_diary(uid, diary_id)
    return {'status': 'ok'}

@router.post('/v1/diaries/', tags=['diaries'])
def add_diary_for_datetime_range(created_at: datetime, end_at: datetime, uid: str = Depends(auth.get_current_user_uid)):
    memories = memories_db.filter_memories_by_date(uid, created_at, end_at)
    diary = DiaryDB.from_memories(uid, memories)
    diaries_db.save_diary(uid, diary)
    return {'status': 'ok'}