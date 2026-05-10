"""Gemini API 클라이언트 — 영수증/실물 사진 통합 처리.

단일 호출 아키텍처:
- 이미지 → Gemini Vision → response_schema 강제 JSON
- kind 필드로 영수증/실물 분기, 동일 응답에 양쪽 필드 포함
- 양쪽 모두 items[] 통일 (category/name/quantity). 영수증의 가격 정보는 추출 대상 아님.

env vars:
- GEMINI_API_KEY (필수)
- GEMINI_MODEL   (기본 gemini-3.1-flash-lite)
"""
from __future__ import annotations

import os
import re
from typing import Literal, Optional

from google import genai
from google.genai import types
from pydantic import BaseModel, field_validator


_LEADING_DIGITS = re.compile(r"\d+")


DEFAULT_MODEL = "gemini-3.1-flash-lite"


def get_api_key() -> str:
    key = os.getenv("GEMINI_API_KEY")
    if not key:
        raise RuntimeError("GEMINI_API_KEY 환경변수가 설정되지 않았습니다.")
    return key


def get_model() -> str:
    return os.getenv("GEMINI_MODEL", DEFAULT_MODEL)


# server schema-v1.md 2.8 표준 12종. 변경 시 server enum과 동시 갱신 필수.
Category = Literal[
    "야채",
    "과일",
    "육류",
    "수산물",
    "유제품",
    "달걀",
    "곡물/면",
    "조미료/소스",
    "음료",
    "냉동식품",
    "간식/과자",
    "기타",
]


class Item(BaseModel):
    category: Category
    name: str
    quantity: str

    @field_validator("quantity")
    @classmethod
    def _quantity_first_run(cls, v: str) -> str:
        # 첫 digit run만. "1개"→"1", "약간"→"". "1박스에 5개"같은 경우엔 앞쪽(1) 우선.
        if not v:
            return ""
        m = _LEADING_DIGITS.search(v)
        return m.group(0) if m else ""


class OcrResponse(BaseModel):
    """단일 호출 응답. kind 에 따라 metadata 사용 여부가 달라진다."""

    kind: Literal["receipt", "object"]
    items: list[Item]
    metadata: Optional[list[str]] = None


_PROMPT = """You receive a single image. Classify and extract structured info as JSON.

[Branch 1] Korean grocery RECEIPT (printed text/POS receipt):
- kind = "receipt"
- items: each product line → {category, name (Korean verbatim), quantity}
- quantity: digits only as string. Examples: "1", "2", "12". NEVER include unit suffix (개, 단, 박스, etc.). "" if not visible.
- metadata: store name, address, datetime, POS/card info, totals, tax, payment, barcodes, headers ("상품명", "단가" etc.)
- Categories (use ONLY these 12 Korean labels): 야채, 과일, 육류, 수산물, 유제품, 달걀, 곡물/면, 조미료/소스, 음료, 냉동식품, 간식/과자, 기타
- Minor OCR typos can be corrected based on grocery context (e.g., "샘칼국수" → "생칼국수"). Preserve unambiguous text verbatim.
- Receipt-specific item rules:
  * 라면, 짜파게티, 국수, 쌀, 시리얼 → 곡물/면
  * 빵, 과자, 젤리, 초콜릿, 쇼콜라(초콜릿 음료가 아닌 한) → 간식/과자
  * 두부, 콩가공품, 생활용품(봉투, 쇼핑백, 세제) → 기타
  * 만두, 냉동피자, 즉석조리 → 냉동식품
  * 오이스터(블레이드/스테이크) → 육류 (호주산 소고기 부위)
  * 커피류 음료(쇼콜라 라떼 등) → 음료

[Branch 2] Real-world PHOTO of food/ingredients/products:
- kind = "object"
- items: each visible food/ingredient → {category, name (Korean), quantity}
- quantity: digits only as string counted from the image. Examples: "1", "2", "5". NEVER include unit suffix (개, 단, 박스, etc.). "" only when truly uncountable.
- Skip non-food items entirely (do not list household goods, utensils, packaging)
- metadata = null (only used for receipt)
- name 가능한 한국어 단일 식재료명 (사과, 양파, 브로콜리, 방울토마토 등). 카탈로그 사진처럼 종류가 섞여있으면 종류별로 한 줄씩.

[Strict rules]
- Korean text verbatim (after typo correction for receipts), no translation
- quantity = "" (empty string) when not visible/applicable
- Output JSON only, no commentary
- All items in `items` field. metadata only for receipt.
"""


async def call_gemini(image_bytes: bytes, mime_type: str = "image/jpeg") -> OcrResponse:
    """이미지 1장을 Gemini로 보내고 구조화 응답을 받는다."""
    client = genai.Client(api_key=get_api_key())
    response = await client.aio.models.generate_content(
        model=get_model(),
        contents=[
            types.Part.from_bytes(data=image_bytes, mime_type=mime_type),
            _PROMPT,
        ],
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=OcrResponse,
        ),
    )
    parsed = response.parsed
    if parsed is None:
        raise RuntimeError(f"Gemini가 schema-conformant 응답을 만들지 못함. raw={response.text[:500]}")
    return parsed
