"""OCR 서비스 계층 (Gemini 단일 호출 버전).

이미지 1장 → Gemini Vision → 분류 + 추출 JSON → ProcessResult.
영수증/실물 둘 다 items[]로 통일된 구조 반환.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Literal, Optional

from .gemini import call_gemini, get_model


SourceKind = Literal["receipt", "object"]


@dataclass
class ProcessResult:
    source_kind: SourceKind
    text: str
    model: str


async def process_image(
    image_bytes: bytes,
    prompt: Optional[str] = None,
) -> ProcessResult:
    response = await call_gemini(image_bytes)

    payload = {"items": [item.model_dump() for item in response.items]}
    if response.kind == "receipt":
        payload["metadata"] = response.metadata or []

    text = json.dumps(payload, ensure_ascii=False, indent=2)
    return ProcessResult(
        source_kind=response.kind,
        text=text,
        model=get_model(),
    )
