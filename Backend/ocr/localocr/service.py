"""OCR 서비스 계층.

- describe:      실물 이미지 → 한국어 사물 설명 (Mac Mini Ollama, vision LLM)
- process_image: 분류 후 분기. 영수증은 PaddleOCR(데스크탑) → vision LLM 검수,
                 실물은 vision LLM(Mac Mini Ollama).
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from .classifier import SourceKind, classify
from .client import get_refine_model, get_vision_model
from .object_vision import describe
from .paddle_ocr import extract_text as paddle_extract_text
from .refiner import is_enabled as refine_enabled, refine as refine_text


_RECEIPT_BASE_MODEL = "paddleocr-korean"


@dataclass
class ProcessResult:
    source_kind: SourceKind
    text: str
    model: str


def _receipt_model_name() -> str:
    if refine_enabled():
        return f"{_RECEIPT_BASE_MODEL}+{get_refine_model()}-classify"
    return _RECEIPT_BASE_MODEL


async def process_image(
    image_bytes: bytes,
    prompt: Optional[str] = None,
) -> ProcessResult:
    kind = await classify(image_bytes)
    if kind == "receipt":
        text = await paddle_extract_text(image_bytes)
        if refine_enabled():
            text = await refine_text(text)
        return ProcessResult(
            source_kind="receipt",
            text=text,
            model=_receipt_model_name(),
        )
    text = await describe(image_bytes, prompt=prompt)
    return ProcessResult(
        source_kind="object",
        text=text,
        model=get_vision_model(),
    )
