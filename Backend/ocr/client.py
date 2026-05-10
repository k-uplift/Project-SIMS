"""Ollama 비전 모델 호출 클라이언트.

Mac Mini 등 외부 호스트의 Ollama 서버에 base64 이미지를 보내고 텍스트 응답을
받는 저수준 어댑터. 이미지 분류·사물 인식 단계에서만 사용된다 (영수증 OCR은
PaddleOCR 로컬 처리로 분리됨).

- 일반 비전 모델 (분류·사물 인식): OLLAMA_VISION_MODEL (기본 qwen2.5vl:7b)
"""
from __future__ import annotations

import base64
import os
from typing import Optional

import httpx


DEFAULT_BASE_URL = "http://localhost:11434"
DEFAULT_VISION_MODEL = "qwen2.5vl:7b"
DEFAULT_TIMEOUT_SECONDS = 180.0


def get_base_url() -> str:
    return os.getenv("OLLAMA_BASE_URL", DEFAULT_BASE_URL).rstrip("/")


def get_vision_model() -> str:
    return os.getenv("OLLAMA_VISION_MODEL", DEFAULT_VISION_MODEL)


def get_timeout() -> float:
    raw = os.getenv("OLLAMA_TIMEOUT_SECONDS")
    if not raw:
        return DEFAULT_TIMEOUT_SECONDS
    try:
        return float(raw)
    except ValueError:
        return DEFAULT_TIMEOUT_SECONDS


async def generate_with_image(
    image_bytes: bytes,
    prompt: str,
    model: str,
    base_url: Optional[str] = None,
    timeout: Optional[float] = None,
) -> str:
    """Ollama /api/generate 호출. 응답 전체를 한 번에 받는다 (stream=false)."""
    url = (base_url or get_base_url()) + "/api/generate"
    payload = {
        "model": model,
        "prompt": prompt,
        "images": [base64.b64encode(image_bytes).decode("ascii")],
        "stream": False,
    }
    async with httpx.AsyncClient(timeout=timeout or get_timeout()) as client:
        resp = await client.post(url, json=payload)
        resp.raise_for_status()
        data = resp.json()
    return data.get("response", "")
