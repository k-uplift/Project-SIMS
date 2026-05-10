import os
import secrets as _secrets
from typing import Optional

import firebase_admin
from firebase_admin import auth as fb_auth, credentials
from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer


_bearer = HTTPBearer(auto_error=True)


def _init_firebase() -> None:
    if firebase_admin._apps:
        return

    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if cred_path and os.path.isfile(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    else:
        firebase_admin.initialize_app()


_init_firebase()


class CurrentUser:
    def __init__(self, uid: str, email: Optional[str], name: Optional[str]):
        self.uid = uid
        self.email = email
        self.name = name


def get_current_user(
    creds: HTTPAuthorizationCredentials = Depends(_bearer),
) -> CurrentUser:
    token = creds.credentials
    if os.getenv("DEV_AUTH_ENABLED") == "1" and token == "dev-token":
        return CurrentUser(uid="user_1", email="dev@example.com", name="개발자")

    try:
        decoded = fb_auth.verify_id_token(token)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Firebase ID token: {e}",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return CurrentUser(
        uid=decoded["uid"],
        email=decoded.get("email"),
        name=decoded.get("name"),
    )


def verify_cron_secret(
    x_cron_secret: Optional[str] = Header(default=None, alias="X-Cron-Secret"),
) -> bool:
    expected = os.getenv("CRON_SECRET")
    if not expected:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="CRON_SECRET not configured on server",
        )
    if not x_cron_secret or not _secrets.compare_digest(x_cron_secret, expected):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid or missing X-Cron-Secret header",
        )
    return True
