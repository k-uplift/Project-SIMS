"""실물 이미지 → 사물 인식 + 한국어 텍스트화."""
from __future__ import annotations

from typing import Optional

from .client import generate_with_image, get_vision_model


_DEFAULT_PROMPT = (
    "이 이미지에 보이는 사물들을 한국어로 자세히 설명하세요. "
    "특히 식재료·제품인 경우 종류·수량·상태(신선도 등)를 가능한 한 구체적으로 적어주세요. "
    "추측이나 부연 해석 없이, 보이는 것만 기술하세요."
)


async def describe(image_bytes: bytes, prompt: Optional[str] = None) -> str:
    return await generate_with_image(
        image_bytes=image_bytes,
        prompt=prompt or _DEFAULT_PROMPT,
        model=get_vision_model(),
    )
