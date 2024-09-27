from datetime import datetime

from fastapi import APIRouter, Depends

import database.diary as diaries_db
from utils.other import endpoints as auth
from models.diary import diary_from_configs, DiaryConfig

router = APIRouter()

@router.get('/v1/diaries', tags=['diaries'])
def get_diaries(limit: int = 100, offset: int = 0, uid: str = Depends(auth.get_current_user_uid)):
    return diaries_db.get_diaries(uid, limit, offset)

@router.delete('/v1/diaries/{diary_id}', tags=['diaries'])
def delete_diary(diary_id: str, uid: str = Depends(auth.get_current_user_uid)):
    diaries_db.delete_diary(uid, diary_id)
    return {'status': 'ok'}

@router.post('/v1/diaries/', tags=['diaries'])
async def add_diary_for_datetime_range(start_at_utc: str, end_at_utc: str, uid: str = Depends(auth.get_current_user_uid)):
    
    config = DiaryConfig(
        uid=uid,
        diary_start_utc=datetime.fromisoformat(start_at_utc),
        diary_end_utc=datetime.fromisoformat(end_at_utc)
    )
    diary = await diary_from_configs(config)
    diaries_db.save_diary(uid, diary.dict())
    return {'status': 'ok'}