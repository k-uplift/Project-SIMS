"""이미지 종류 분류기.

비전 LLM에 1-토큰 응답 prompt를 보내 영수증/실물 사진을 구분한다.
모호하면 'object' 로 fallback — 비전 모델은 영수증 텍스트도 어느 정도 처리 가능하지만
OCR 특화 모델은 일반 사물 사진에 약하기 때문.
"""
from __future__ import annotations

from typing import Literal

from .client import generate_with_image, get_vision_model


SourceKind = Literal["receipt", "object"]


_PROMPT = (
    "이미지가 다음 둘 중 어느 쪽에 가까운지 분류하세요:\n"
    "- 영수증·인쇄된 문서·텍스트 위주 캡처 → RECEIPT\n"
    "- 실제 사물(식재료·제품·풍경 등)을 찍은 사진 → OBJECT\n"
    "정확히 한 단어(RECEIPT 또는 OBJECT)만 출력하세요. 다른 설명은 금지."
)


async def classify(image_bytes: bytes) -> SourceKind:
    response = await generate_with_image(
        image_bytes=image_bytes,
        prompt=_PROMPT,
        model=get_vision_model(),
    )
    head = response.strip().upper()[:32]
    if "RECEIPT" in head:
        return "receipt"
    return "object"
