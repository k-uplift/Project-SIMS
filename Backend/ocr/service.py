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
from .preprocess import preprocess_for_ocr


_DEFAULT_OCR_PROMPT = "<|grounding|>Convert the document to markdown."


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
        ocr_bytes = preprocess_for_ocr(image_bytes)
        text = await extract_text(ocr_bytes, prompt=prompt)
        return ProcessResult(source_kind="receipt", text=text, model=get_ocr_model())
    text = await describe(image_bytes, prompt=prompt)
    return ProcessResult(source_kind="object", text=text, model=get_vision_model())
