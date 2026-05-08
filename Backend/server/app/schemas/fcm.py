from enum import Enum

from pydantic import Field

from app.schemas._base import CamelModel


class DevicePlatform(str, Enum):
    ANDROID = "android"
    IOS = "ios"


class FCMRegisterRequest(CamelModel):
    token: str = Field(..., description="FCM 디바이스 토큰")
    device_id: str = Field(..., description="앱이 생성한 고유 디바이스 ID")
    platform: DevicePlatform


class FCMRegisterResponse(CamelModel):
    ok: bool = True
