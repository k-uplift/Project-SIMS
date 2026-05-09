"""OCR 서비스 계층.

- extract_text:   영수증·인쇄 텍스트 → raw text (deepseek-ocr 직접 호출)
- describe:       실물 이미지 → 한국어 사물 설명 (vision LLM)
- process_image:  분류 후 위 두 파이프라인으로 자동 분기
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from .classifier import SourceKind, classify
from .client import generate_with_image, get_ocr_model, get_vision_model
from .object_vision import describe


_DEFAULT_OCR_PROMPT = (
    "다음 이미지에서 보이는 모든 텍스트를 정확히 그대로 추출해 주세요. "
    "원문의 줄바꿈과 공백 구조를 최대한 보존하고, 추가 설명이나 해석은 포함하지 마세요."
)


async def extract_text(
    image_bytes: bytes,
    prompt: Optional[str] = None,
) -> str:
    return await generate_with_image(
        image_bytes=image_bytes,
        prompt=prompt or _DEFAULT_OCR_PROMPT,
        model=get_ocr_model(),
    )


@dataclass
class ProcessResult:
    source_kind: SourceKind
    text: str
    model: str


async def process_image(
    image_bytes: bytes,
    prompt: Optional[str] = None,
) -> ProcessResult:
    kind = await classify(image_bytes)
    if kind == "receipt":
        text = await extract_text(image_bytes, prompt=prompt)
        return ProcessResult(source_kind="receipt", text=text, model=get_ocr_model())
    text = await describe(image_bytes, prompt=prompt)
    return ProcessResult(source_kind="object", text=text, model=get_vision_model())
