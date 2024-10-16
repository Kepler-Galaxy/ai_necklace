import json
import os
import time

from fastapi import Header, HTTPException
from fastapi import Request
from firebase_admin import auth
from firebase_admin.auth import InvalidIdTokenError
from utils.authing.auth_client import AuthenticationClient
from loguru import logger
from utils.mgdbstore.client import db


# todo: Change to tpns or mps
def get_fcm_token():
    return "fLpP2UnAFECDu5Nmj6RxEd:APA91bEhvoHgtkooKvvvE094_5CE0-PVsYRz6seIw0TdpVu8p5LpLgxVHGih7qVfkSHXC5r9moG1K5C2iFqEgsmmEtFpw1uys9E3W5RaVxvKuvAH5pGxP6cmA8IlztAz_kKQ-U0Ahymj"
def get_current_user_uid(authorization: str = Header(None), provider: str = Header(None)):
    if os.getenv('ADMIN_KEY') in authorization:
        return authorization.split(os.getenv('ADMIN_KEY'))[1]

    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header not found")
    elif len(str(authorization).split(' ')) != 2:
        raise HTTPException(status_code=401, detail="Invalid authorization token")

    try:
        token = authorization.split(' ')[1]
        # 如果使用的authing

        if provider == 'authing':
            data = AuthenticationClient(
                app_id=os.environ.get('AUTHING_APP_ID'),
                app_secret=os.environ.get('AUTHING_APP_SECRET'),
                app_host=os.environ.get('AUTHING_APP_HOST'),
                redirect_uri=os.environ.get('AUTHING_REDIRECT_URI'),
                access_token=token,
            ).get_profile(True, True, True)
            if data.get("statusCode", "500") != 200:
                raise HTTPException(status_code=401, detail="Invalid authorization token")
            uid = data.get('data', {}).get('userId', "")
            logger.info(f'get_current_user_uid: {uid}')
            # update user collection
            db.collection("users").document(uid).set({"_id": uid, "time_zone": "Asia/Shanghai", "fcm_token": get_fcm_token()})
            return uid
        else:
            decoded_token = auth.verify_id_token(token)
            if decoded_token.get("uid", None) == None:
                raise HTTPException(status_code=401, detail="Invalid authorization token")
            logger.info(f'get_current_user_uid: {decoded_token["uid"]}')
            return decoded_token['uid']
    except InvalidIdTokenError as e:
        if os.getenv('LOCAL_DEVELOPMENT') == 'true':
            return '123'
        logger.error(e)
        raise HTTPException(status_code=401, detail="Invalid authorization token")


cached = {}


def rate_limit_custom(endpoint: str, request: Request, requests_per_window: int, window_seconds: int):
    ip = request.client.host
    key = f"rate_limit:{endpoint}:{ip}"

    # Check if the IP is already rate-limited
    current = cached.get(key)
    if current:
        current = json.loads(current)
        remaining = current["remaining"]
        timestamp = current["timestamp"]
        current_time = int(time.time())

        # Check if the time window has expired
        if current_time - timestamp >= window_seconds:
            remaining = requests_per_window - 1  # Reset the counter for the new window
            timestamp = current_time
        elif remaining == 0:
            logger.error("Too Many Requests")
            raise HTTPException(status_code=429, detail="Too Many Requests")

        remaining -= 1

    else:
        # If no previous data found, start a new time window
        remaining = requests_per_window - 1
        timestamp = int(time.time())

    # Update the rate limit info in Redis
    current = {"timestamp": timestamp, "remaining": remaining}
    cached[key] = json.dumps(current)

    return True


# Dependency to enforce custom rate limiting for specific endpoints
def rate_limit_dependency(endpoint: str = "", requests_per_window: int = 60, window_seconds: int = 60):
    def rate_limit(request: Request):
        return rate_limit_custom(endpoint, request, requests_per_window, window_seconds)

    return rate_limit


def timeit(func):
    """
    Decorator for measuring function's running time.
    """

    def measure_time(*args, **kw):
        start_time = time.time()
        result = func(*args, **kw)
        logger.info("Processing time of %s(): %.2f seconds."
              % (func.__qualname__, time.time() - start_time))
        return result

    return measure_time
