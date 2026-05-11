"""OCR 모듈용 인증 의존성 placeholder.

ocr/ 가 server 통합 없이 단독으로 import/실행될 수 있도록 자체 더미를 제공한다.
server 에 통합할 때는 FastAPI app.dependency_overrides 로 실제 Firebase 인증을 주입한다.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Optional


@dataclass
class CurrentUser:
    uid: str
    email: Optional[str] = None
    name: Optional[str] = None


def get_current_user() -> CurrentUser:
    return CurrentUser(uid="dev-local")
