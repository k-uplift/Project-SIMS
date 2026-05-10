"""Vision LLM 호출 전 이미지 전처리.

- preprocess_common:   모든 분기 공통 (EXIF 회전 보정 + resize + JPEG 재인코딩).
                       토큰 수를 결정하는 가장 큰 레버.
- preprocess_for_ocr:  OCR 분기 추가 처리 (grayscale + autocontrast).
                       흐릿한 영수증의 인식률을 보강. 공통 전처리 결과를 입력으로 가정.
"""
from __future__ import annotations

import io

from PIL import Image, ImageOps


_DEFAULT_MAX_EDGE = 1536
_JPEG_QUALITY = 85


def preprocess_common(
    image_bytes: bytes,
    max_edge: int = _DEFAULT_MAX_EDGE,
) -> bytes:
    img = Image.open(io.BytesIO(image_bytes))
    img = ImageOps.exif_transpose(img)
    img.thumbnail((max_edge, max_edge))
    img = img.convert("RGB")

    out = io.BytesIO()
    img.save(out, "JPEG", quality=_JPEG_QUALITY, optimize=True)
    return out.getvalue()


def preprocess_for_ocr(image_bytes: bytes) -> bytes:
    img = Image.open(io.BytesIO(image_bytes))
    img = img.convert("L")
    img = ImageOps.autocontrast(img)
    # 일부 vision 백엔드가 3채널을 가정하므로 RGB로 복원해서 JPEG 저장
    img = img.convert("RGB")

    out = io.BytesIO()
    img.save(out, "JPEG", quality=_JPEG_QUALITY, optimize=True)
    return out.getvalue()
