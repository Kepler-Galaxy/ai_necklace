import asyncio
import json
from typing import List

import requests
import websockets

from database.redis_db import get_user_webhook_db
from models.memory import Memory
from models.users import WebhookType
from loguru import logger


def memory_created_webhook(uid, memory: Memory):
    webhook_url = get_user_webhook_db(uid, WebhookType.memory_created)
    if not webhook_url:
        return
    webhook_url += f'?uid={uid}'
    response = requests.post(
        webhook_url,
        json=memory.as_dict_cleaned_dates(),    
        headers={'Content-Type': 'application/json'}
    )
    logger.info('memory_created_webhook:', response.status_code)


async def realtime_transcript_webhook(uid, segments: List[dict]):
    webhook_url = get_user_webhook_db(uid, WebhookType.realtime_transcript)
    if not webhook_url:
        return
    webhook_url += f'?uid={uid}'
    try:
        response = requests.post(
            webhook_url,
            json={'segments': segments, 'session_id': uid},
            headers={'Content-Type': 'application/json'}
        )
        logger.info('realtime_transcript_webhook:', response.status_code)
    except Exception as e:
        logger.error(f"Error sending realtime transcript to developer webhook: {e}")


def get_audio_bytes_webhook_seconds(uid: str):
    webhook_url = get_user_webhook_db(uid, WebhookType.audio_bytes)
    if not webhook_url:
        return
    parts = webhook_url.split(',')
    if len(parts) == 2:
        try:
            return int(parts[1])
        except ValueError:
            pass
    return 5


async def send_audio_bytes_developer_webhook(uid: str, sample_rate: int, data: bytearray):
    # TODO: add a lock, send shorter segments, validate regex.
    webhook_url = get_user_webhook_db(uid, WebhookType.audio_bytes)
    webhook_url = webhook_url.split(',')[0]
    if not webhook_url:
        return
    webhook_url += f'?sample_rate={sample_rate}&uid={uid}'
    try:
        response = requests.post(webhook_url, data=data, headers={'Content-Type': 'application/octet-stream'})
        logger.info('send_audio_bytes_developer_webhook:', response.status_code)
    except Exception as e:
        logger.error(f"Error sending audio bytes to developer webhook: {e}")


# continue?
async def connect_user_webhook_ws(sample_rate: int, language: str, preseconds: int = 0):
    uri = ''

    try:
        socket = await websockets.connect(uri, extra_headers={})
        await socket.send(json.dumps({}))

        async def on_message():
            try:
                async for message in socket:
                    response = json.loads(message)
            except websockets.exceptions.ConnectionClosedOK:
                logger.info("Speechmatics connection closed normally.")
            except Exception as e:
                logger.error(f"Error receiving from Speechmatics: {e}")
            finally:
                if not socket.closed:
                    await socket.close()
                    logger.info("Speechmatics WebSocket closed in on_message.")

        asyncio.create_task(on_message())
        return socket
    except Exception as e:
        logger.error(f"Exception in process_audio_speechmatics: {e}")
        raise
