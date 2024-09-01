import os
from authing import AuthenticationClient


class AuthingClient:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(AuthenticationClient, cls).__new__(cls)
            cls._instance._initialize()
        return cls._instance

    def _initialize(self):
        app_id = os.environ.get('AUTHING_APP_ID')
        app_secret = os.environ.get('AUTHING_APP_SECRET')
        app_host = os.environ.get('AUTHING_APP_HOST')
        redirect_uri = os.environ.get('AUTHING_REDIRECT_URI')
        if not app_id or not app_secret or not app_host or not redirect_uri:
            raise ValueError("Missing AUTHING_APP_ID or AUTHING_APP_SECRET or AUTHING_APP_HOST or AUTHING_REDIRECT_URI  environment variable")
        self.client: AuthenticationClient = AuthenticationClient(app_id, app_secret, app_host, redirect_uri)

    def get_client(self) -> AuthenticationClient:
        return self.client
