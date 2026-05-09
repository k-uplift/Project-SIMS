"""이미지 처리 엔드포인트.

업로드된 이미지를 분류해 영수증이면 OCR(deepseek-ocr), 실물 사진이면
사물 인식(vision LLM)으로 자동 분기한다.
"""
from __future__ import annotations

from typing import Literal, Optional

import httpx
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pydantic import BaseModel

from .auth import CurrentUser, get_current_user
from .service import process_image


router = APIRouter(prefix="/ocr", tags=["ocr"])


_ALLOWED_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/heic",
    "image/heif",
}
_MAX_BYTES = 10 * 1024 * 1024  # 10MB


class OcrTextResponse(BaseModel):
    source_kind: Literal["receipt", "object"]
    text: str
    model: str


@router.post(
    "/text",
    response_model=OcrTextResponse,
    summary="이미지 분류 후 OCR 또는 사물 인식",
    description=(
        "이미지를 비전 LLM으로 분류 → "
        "영수증이면 OLLAMA_OCR_MODEL(기본 deepseek-ocr)로 텍스트 추출, "
        "실물 사진이면 OLLAMA_VISION_MODEL(기본 qwen2.5vl:7b)로 한국어 사물 설명을 반환한다."
    ),
)
async def ocr_text(
    file: UploadFile = File(..., description="처리할 이미지"),
    prompt: Optional[str] = Form(None, description="커스텀 프롬프트 (옵션, 분기 후 단계에 적용)"),
    user: CurrentUser = Depends(get_current_user),
) -> OcrTextResponse:
    if file.content_type not in _ALLOWED_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported content type: {file.content_type}",
        )

    image_bytes = await file.read()
    if len(image_bytes) > _MAX_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"Image larger than {_MAX_BYTES} bytes",
        )
    if not image_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Empty image upload",
        )

    try:
        result = await process_image(image_bytes, prompt)
    except httpx.TimeoutException as exc:
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail="Ollama request timed out",
        ) from exc
    except httpx.HTTPStatusError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Ollama returned {exc.response.status_code}: {exc.response.text[:200]}",
        ) from exc
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Ollama unreachable: {exc}",
        ) from exc

    return OcrTextResponse(
        source_kind=result.source_kind,
        text=result.text,
        model=result.model,
    )
