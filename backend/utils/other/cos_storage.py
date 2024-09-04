import json
import os
import datetime
from typing import List
from qcloud_cos import CosConfig, CosS3Client
from database.redis_db import cache_signed_url, get_cached_signed_url

# 初始化腾讯云COS客户端
secret_id = os.getenv("TENCENT_COS_SECRET_ID")
secret_key = os.getenv("TENCENT_COS_SECRET_KEY")
region = os.getenv("TENCENT_COS_REGION")  # 例如 'ap-guangzhou'
token = None  # 如果使用临时密钥，请设置 token

config = CosConfig(Region=region, SecretId=secret_id, SecretKey=secret_key, Token=token)
cos_client = CosS3Client(config)

speech_profiles_bucket = os.getenv('BUCKET_SPEECH_PROFILES')
postprocessing_audio_bucket = os.getenv('BUCKET_POSTPROCESSING')
memories_recordings_bucket = os.getenv('BUCKET_MEMORIES_RECORDINGS')


# *******************************************
# ************* SPEECH PROFILE **************
# *******************************************
def upload_profile_audio(file_path: str, uid: str):
    path = f'{uid}/speech_profile.wav'
    cos_client.upload_file(
        Bucket=speech_profiles_bucket,
        LocalFilePath=file_path,
        Key=path
    )
    return f'https://{speech_profiles_bucket}.cos.{region}.myqcloud.com/{path}'


def get_profile_audio_if_exists(uid: str, download: bool = True) -> str:
    path = f'{uid}/speech_profile.wav'
    try:
        response = cos_client.head_object(
            Bucket=speech_profiles_bucket,
            Key=path
        )
        if download:
            file_path = f'_temp/{uid}_speech_profile.wav'
            cos_client.download_file(
                Bucket=speech_profiles_bucket,
                Key=path,
                DestFilePath=file_path
            )
            return file_path
        return _get_signed_url(path, 60)
    except Exception:
        return None


def upload_additional_profile_audio(file_path: str, uid: str) -> None:
    path = f'{uid}/additional_profile_recordings/{os.path.basename(file_path)}'
    cos_client.upload_file(
        Bucket=speech_profiles_bucket,
        LocalFilePath=file_path,
        Key=path
    )


def delete_additional_profile_audio(uid: str, file_name: str) -> None:
    path = f'{uid}/additional_profile_recordings/{file_name}'
    cos_client.delete_object(
        Bucket=speech_profiles_bucket,
        Key=path
    )


def get_additional_profile_recordings(uid: str, download: bool = False) -> List[str]:
    prefix = f'{uid}/additional_profile_recordings/'
    response = cos_client.list_objects(
        Bucket=speech_profiles_bucket,
        Prefix=prefix
    )
    blobs = response.get('Contents', [])

    if download:
        paths = []
        for blob in blobs:
            file_path = f'_temp/{uid}_{os.path.basename(blob["Key"])}'
            cos_client.download_file(
                Bucket=speech_profiles_bucket,
                Key=blob['Key'],
                DestFilePath=file_path
            )
            paths.append(file_path)
        return paths

    return [_get_signed_url(blob['Key'], 60) for blob in blobs]


# ********************************************
# ************* PEOPLE PROFILES **************
# ********************************************

def upload_user_person_speech_sample(file_path: str, uid: str, person_id: str) -> None:
    path = f'{uid}/people_profiles/{person_id}/{os.path.basename(file_path)}'
    cos_client.upload_file(
        Bucket=speech_profiles_bucket,
        LocalFilePath=file_path,
        Key=path
    )


def delete_user_person_speech_sample(uid: str, person_id: str, file_name: str) -> None:
    path = f'{uid}/people_profiles/{person_id}/{file_name}'
    cos_client.delete_object(
        Bucket=speech_profiles_bucket,
        Key=path
    )


def delete_speech_sample_for_people(uid: str, file_name: str) -> None:
    prefix = f'{uid}/people_profiles/'
    response = cos_client.list_objects(
        Bucket=speech_profiles_bucket,
        Prefix=prefix
    )
    blobs = response.get('Contents', [])

    for blob in blobs:
        if file_name in blob['Key']:
            cos_client.delete_object(
                Bucket=speech_profiles_bucket,
                Key=blob['Key']
            )


def delete_user_person_speech_samples(uid: str, person_id: str) -> None:
    prefix = f'{uid}/people_profiles/{person_id}/'
    response = cos_client.list_objects(
        Bucket=speech_profiles_bucket,
        Prefix=prefix
    )
    blobs = response.get('Contents', [])

    for blob in blobs:
        cos_client.delete_object(
            Bucket=speech_profiles_bucket,
            Key=blob['Key']
        )


def get_user_people_ids(uid: str) -> List[str]:
    prefix = f'{uid}/people_profiles/'
    response = cos_client.list_objects(
        Bucket=speech_profiles_bucket,
        Prefix=prefix
    )
    blobs = response.get('Contents', [])

    return list({blob['Key'].split("/")[-2] for blob in blobs})


def get_user_person_speech_samples(uid: str, person_id: str, download: bool = False) -> List[str]:
    prefix = f'{uid}/people_profiles/{person_id}/'
    response = cos_client.list_objects(
        Bucket=speech_profiles_bucket,
        Prefix=prefix
    )
    blobs = response.get('Contents', [])

    if download:
        paths = []
        for blob in blobs:
            file_path = f'_temp/{uid}_person_{os.path.basename(blob["Key"])}'
            cos_client.download_file(
                Bucket=speech_profiles_bucket,
                Key=blob['Key'],
                DestFilePath=file_path
            )
            paths.append(file_path)
        return paths

    return [_get_signed_url(blob['Key'], 60) for blob in blobs]


# ********************************************
# ************* POST PROCESSING **************
# ********************************************
def upload_postprocessing_audio(file_path: str):
    cos_client.upload_file(
        Bucket=postprocessing_audio_bucket,
        LocalFilePath=file_path,
        Key=file_path
    )
    return f'https://{postprocessing_audio_bucket}.cos.{region}.myqcloud.com/{file_path}'


def delete_postprocessing_audio(file_path: str):
    cos_client.delete_object(
        Bucket=postprocessing_audio_bucket,
        Key=file_path
    )


def create_signed_postprocessing_audio_url(file_path: str):
    return _get_signed_url(file_path, 15)


# ************************************************
# ************* MEMORIES RECORDINGS **************
# ************************************************

def upload_memory_recording(file_path: str, uid: str, memory_id: str):
    path = f'{uid}/{memory_id}.wav'
    cos_client.upload_file(
        Bucket=memories_recordings_bucket,
        LocalFilePath=file_path,
        Key=path
    )
    return f'https://{memories_recordings_bucket}.cos.{region}.myqcloud.com/{path}'


def get_memory_recording_if_exists(uid: str, memory_id: str) -> str:
    path = f'{uid}/{memory_id}.wav'
    try:
        response = cos_client.head_object(
            Bucket=memories_recordings_bucket,
            Key=path
        )
        file_path = f'_temp/{memory_id}.wav'
        cos_client.download_file(
            Bucket=memories_recordings_bucket,
            Key=path,
            DestFilePath=file_path
        )
        return file_path
    except Exception:
        return None


def delete_all_memory_recordings(uid: str):
    if not uid:
        return
    prefix = uid
    response = cos_client.list_objects(
        Bucket=memories_recordings_bucket,
        Prefix=prefix
    )
    blobs = response.get('Contents', [])

    for blob in blobs:
        cos_client.delete_object(
            Bucket=memories_recordings_bucket,
            Key=blob['Key']
        )


# 获取签名的URL
def _get_signed_url(key, minutes):
    if cached := get_cached_signed_url(key):
        return cached

    signed_url = cos_client.get_presigned_url(
        Bucket=speech_profiles_bucket,  # 此处假定所有桶使用相同的签名逻辑
        Key=key,
        Method='GET',
        Expired=minutes * 60
    )
    cache_signed_url(key, signed_url, minutes * 60)
    return signed_url
