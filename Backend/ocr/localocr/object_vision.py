"""실물 이미지 → 사물 인식 + 한국어 텍스트화."""
from __future__ import annotations

from typing import Optional

from .client import generate_with_image, get_vision_model


_DEFAULT_PROMPT = (
    "이 이미지에 보이는 식재료·식음료·가공식품·냉동식품 등 "
    "사람이 먹거나 마실 수 있는 식품류만 한국어로 나열하세요. "
    "각 항목은 종류·수량·상태(신선도·포장 상태 등)를 가능한 한 구체적으로 적어주세요. "
    "식품이 아닌 사물(생활용품·세제·샴푸·가구·인물·풍경·도구·배경 등)은 완전히 무시하세요. "
    "보이지 않는 정보는 추측하지 말고, 식품이 하나도 없으면 "
    '정확히 "없음" 한 단어만 출력하세요.'
)


async def describe(image_bytes: bytes, prompt: Optional[str] = None) -> str:
    return await generate_with_image(
        image_bytes=image_bytes,
        prompt=prompt or _DEFAULT_PROMPT,
        model=get_vision_model(),
    )
