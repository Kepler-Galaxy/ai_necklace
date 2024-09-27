import asyncio
import concurrent.futures
from datetime import datetime, timedelta
from datetime import time
from loguru import logger

import pytz

import database.chat as chat_db
import database.memories as memories_db
import database.notifications as notification_db
import database.diary as diaries_db
from models.diary import DiaryConfig, diary_from_configs
from models.notification_message import NotificationMessage
from utils.llm import get_memory_summary
from utils.notifications import send_notification, send_bulk_notification


async def start_cron_job():
    if should_run_job():
        logger.info("sending notifications")
        await asyncio.gather(
            send_daily_notification(),
            send_daily_summary_notification(),
            send_daily_dairy_notification()
        )


def should_run_job():
    current_utc = datetime.now(pytz.utc)
    target_hours = {8, 22}

    for tz in pytz.all_timezones:
        local_time = current_utc.astimezone(pytz.timezone(tz))
        if local_time.hour in target_hours and local_time.minute == 0:
            return True

    return False


async def send_daily_summary_notification():
    try:
        daily_summary_target_time = "22:00"
        timezones_in_time = _get_timezones_at_time(daily_summary_target_time)
        user_in_time_zone = await notification_db.get_users_id_in_timezones(timezones_in_time)
        if not user_in_time_zone:
            return None

        await _send_bulk_summary_notification(user_in_time_zone)
    except Exception as e:
        logger.error(f'Error sending message: {e}')
        return None


def _send_summary_notification(user_data: tuple):
    uid = user_data[0]
    fcm_token = user_data[1]
    daily_summary_title = "Here is your action plan for tomorrow"  # TODO: maybe include llm a custom message for this
    memories = memories_db.filter_memories_by_date(
        uid, datetime.now() - timedelta(days=1), datetime.now()
    )
    if not memories:
        return
    else:
        summary = get_memory_summary(uid, memories)

    ai_message = NotificationMessage(
        text=summary,
        from_integration='false',
        type='day_summary',
        notification_type='daily_summary',
    )
    chat_db.add_summary_message(summary, uid)
    send_notification(fcm_token, daily_summary_title, summary, NotificationMessage.get_message_as_dict(ai_message))
    

async def _send_bulk_summary_notification(users: list):
    loop = asyncio.get_running_loop()
    with concurrent.futures.ThreadPoolExecutor() as pool:
        tasks = [
            loop.run_in_executor(pool, _send_summary_notification, uid)
            for uid in users
        ]
        await asyncio.gather(*tasks)


async def send_daily_dairy_notification():
    try:
        daily_summary_target_time = "22:00"
        timezones_in_time = _get_timezones_at_time(daily_summary_target_time)
        user_in_time_zone = await notification_db.get_users_id_in_timezones(timezones_in_time)
        if not user_in_time_zone:
            return None

        await _send_bulk_dairy_notification(user_in_time_zone)
    except Exception as e:
        logger.error(f"Error sending message: {e}")
        return None
    

async def _send_bulk_dairy_notification(users: list):
    logger.info(f"Sending dairy notification to {len(users)} users")
    for user_data in users:
        logger.info(f"Sending dairy notification to user {user_data[0]}")
    tasks = [_generate_dairy_and_send_notification(user_data) for user_data in users]
    await asyncio.gather(*tasks)


async def _generate_dairy_and_send_notification(user_data: tuple):
    try:
        uid = user_data[0]
        fcm_token = user_data[1]

        start_at_utc = datetime.now(pytz.utc) - timedelta(days=1)
        end_at_utc = datetime.now(pytz.utc)
        config = DiaryConfig(
            uid=uid,
            diary_start_utc=datetime.fromisoformat(start_at_utc),
            diary_end_utc=datetime.fromisoformat(end_at_utc)
        )
        diary = await diary_from_configs(config)
        diaries_db.save_diary(uid, diary.dict())

        diary_notification_title = "Memories consolidated to your digital brain. Check the diary out!"
        diary_notification_body = "Wear your Kepler Star and capture more personal conversation memories tomorrow."
        send_notification(fcm_token, diary_notification_title, diary_notification_body)

    except Exception as e:
        logger.error(f'Error sending message: {e}')
        return
    

async def send_daily_notification():
    try:
        morning_alert_title = "Don\'t forget to wear Friend today"
        morning_alert_body = "Wear your friend and capture your memories today."
        morning_target_time = "08:00"

        await _send_notification_for_time(morning_target_time, morning_alert_title, morning_alert_body)

    except Exception as e:
        logger.error(f'Error sending message: {e}')
        return None


async def _send_notification_for_time(target_time: str, title: str, body: str):
    user_in_time_zone = await _get_users_in_timezone(target_time)
    if not user_in_time_zone:
        logger.warning("No users found in time zone")
        return None
    await send_bulk_notification(user_in_time_zone, title, body)
    return user_in_time_zone


async def _get_users_in_timezone(target_time: str):
    timezones_in_time = _get_timezones_at_time(target_time)
    return await notification_db.get_users_token_in_timezones(timezones_in_time)


def _get_timezones_at_time(target_time):
    target_timezones = []
    for tz_name in pytz.all_timezones:
        tz = pytz.timezone(tz_name)
        current_time = datetime.now(tz).strftime("%H:%M")
        if current_time == target_time:
            target_timezones.append(tz_name)
    return target_timezones
