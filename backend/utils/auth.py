import os

from fastapi import Header, HTTPException
from firebase_admin import auth
from firebase_admin.auth import InvalidIdTokenError
from gotrue.errors import AuthApiError
from utils.supabase_client import SupabaseClient


def get_current_user_uid(authorization: str = Header(None)):
    # TODO: has a hardcode and is dangerous
    if os.getenv('ADMIN_KEY') in authorization:
        return authorization.split(os.getenv('ADMIN_KEY'))[1]

    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header not found")
    elif len(str(authorization).split(' ')) != 2:
        raise HTTPException(status_code=401, detail="Invalid authorization token")

    try:
        token = authorization.split(' ')[1]
        decoded_token = auth.verify_id_token(token)
        print('get_current_user_uid', decoded_token['uid'])
        return decoded_token['uid']
    except InvalidIdTokenError as e:
        if os.getenv('LOCAL_DEVELOPMENT') == 'true':
            return '123'
        print(e)
        raise HTTPException(status_code=401, detail="Invalid authorization token")


def get_current_user_uid_supabase(authorization: str = Header(None)):

    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header not found")
    elif len(str(authorization).split(' ')) != 2:
        raise HTTPException(status_code=401, detail="Invalid authorization token")

    try:
        token = authorization.split(' ')[1]
        decoded_token = SupabaseClient().get_client().auth.get_user(token)
        print('get_current_user_uid_supabase', decoded_token.user.id)
        return decoded_token.user.id
    except AuthApiError as e:
        if os.getenv('LOCAL_DEVELOPMENT') == 'true':
            return '123'
        print(e)
        raise HTTPException(status_code=401, detail="Invalid authorization token")