from enum import Enum
from typing import Optional

from pydantic import Field

from app.schemas._base import CamelModel


class MessageRole(str, Enum):
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"


class ChatRequest(CamelModel):
    message: str = Field(..., min_length=1, max_length=2000)
    session_id: Optional[str] = Field(None, description="이어 대화하려면 기존 세션 ID")
    recipe_id: Optional[str] = Field(None, description="레시피 챗봇 모드일 때")


class ChatResponse(CamelModel):
    session_id: str
    reply: str
