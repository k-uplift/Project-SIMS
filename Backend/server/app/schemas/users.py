from datetime import datetime
from typing import List, Optional

from pydantic import Field

from app.schemas._base import CamelModel


class User(CamelModel):
    """Firestore `users/{uid}` 문서 표현.
    displayName, photoURL은 Firebase Auth 클레임에 있으므로 여기 없음.
    """

    uid: str = Field(..., description="Firebase Auth uid (문서 ID와 동일)")
    email: str
    fridge_ids: List[str] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime


class UserMeResponse(CamelModel):
    """GET /users/me 응답.
    Firebase Auth 토큰에서 가져온 클레임(displayName, photoURL)도 합쳐서 반환.
    """

    uid: str
    email: str
    display_name: Optional[str] = Field(None, description="Firebase Auth 클레임에서")
    photo_url: Optional[str] = Field(None, description="Firebase Auth 클레임에서")
    fridge_ids: List[str] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime
