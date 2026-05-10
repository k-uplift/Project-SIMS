"""OCR 결과를 vision LLM으로 카테고리 분류 (JSON 출력).

PaddleOCR 초안과 원본 이미지를 LLM에 함께 제공해서 영수증 항목을 server의
schema-v1.md 2.8 표준 12종 카테고리로 분류한 JSON을 반환한다. 글자 보정은
부수적이고 분류·구조화가 주 목적.

LLM 호출 실패·유효 JSON 아닌 경우 PaddleOCR 초안을 그대로 반환 (fail-soft).
LLM이 12종 외 카테고리명을 내면 자동으로 "기타"로 정규화한다.

토글: OCR_REFINE_ENABLED 환경변수 ("true"/"false", 기본 true)
"""
from __future__ import annotations

import json
import os

from .client import generate_with_image, get_vision_model


# server schema-v1.md 2.8 표준 12종. 변경 시 server enum과 동시 갱신 필수.
_VALID_CATEGORIES = {
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
}


_SCHEMA_EXAMPLE = """{
  "items": [
    {"category": "<카테고리명>", "name": "<상품명>", "price": "<가격 or 빈 문자열>", "quantity": "<수량 or 빈 문자열>"}
  ],
  "metadata": [
    "<매장명/일시/합계/카드번호 등 상품이 아닌 라인>"
  ]
}"""


_PROMPT_TEMPLATE = """이 이미지는 한국 영수증입니다. 다음은 OCR이 추출한 초안입니다:

---
{draft}
---

이미지와 초안을 참고해 영수증 항목을 분류한 다음 **JSON 형식만으로** 응답하세요.

[카테고리 정의 — 정확히 이 12종 중 하나만 사용]
- 야채: 신선 채소·버섯·나물 (양파·시금치·당근·마늘·생강·고추·새송이버섯 등)
- 과일: 신선 과일 (사과·바나나·딸기·산딸기·포도·수박 등)
- 육류: 정육·가공육 (삼겹살·소고기·닭가슴살·햄·소시지·스팸·베이컨 등)
- 수산물: 생선·해산물·참치캔 (고등어·새우·오징어·참치·연어 등)
- 유제품: 우유·치즈·요거트·버터·아이스크림·콩우유
- 달걀: 계란
- 곡물/면: 쌀·잡곡·밀가루·국수·라면·짜파게티·파스타·시리얼
- 조미료/소스: 간장·된장·고추장·케찹·드레싱·식초·잼·꿀·솔트·후추·조미료
- 음료: 생수·주스·콜라·사이다·차·커피·맥주·소주·와인·양주·토닉워터
- 냉동식품: 만두·냉동피자·즉석조리·HMR·냉동치킨·냉동만두
- 간식/과자: 과자·스낵·빵·떡·젤리·캔디·초콜릿·꼬깔콘·새우깡·시리얼바
- 기타: 위 11종에 명확히 들지 않는 항목 (두부·콩가공품·생활용품·봉투·쇼핑백·세제 등)

[분류 규칙]
1. 사람이 먹거나 마실 수 있는 것은 위 11개 식품 카테고리 중 가장 가까운 것으로. 애매하면 기타.
2. 모르는 한국 브랜드 상품도 영수증 문맥상 식품이면 가장 가까운 카테고리.
3. 두부·콩가공품·청국장 → 기타 (12종에 명확한 카테고리 없음).
4. 생활용품·봉투·쇼핑백·세제·휴지 → 기타.
5. 라면·짜파게티 → 곡물/면 (간식/과자 아님).
6. 빵 → 간식/과자 (곡물/면 아님).

[JSON 스키마 — 정확히 이 구조로]
{schema}

[엄격한 규칙]
- name은 OCR 초안 그대로. 띄어쓰기 보정만 허용. 글자 자체 수정 금지.
- category 값은 정확히 위 12종 중 하나만. 다른 표기 (예: "채소", "유제품류", "가공식품류") 절대 금지.
- 영수증의 매장명·주소·일시·POS·합계·부가세·결제·카드번호는 items가 아닌 metadata 배열에.
- 응답은 JSON 객체 하나만. 마크다운 fence(```), 앞뒤 설명 모두 금지.
- 가격/수량을 OCR 초안에서 못 찾으면 빈 문자열 "" 사용. 절대 추측하지 말 것."""


def is_enabled() -> bool:
    return os.getenv("OCR_REFINE_ENABLED", "true").strip().lower() in ("1", "true", "yes", "on")


def _strip_json_fence(text: str) -> str:
    """LLM이 ```json ... ``` 같은 fence로 감싸면 벗긴다."""
    text = text.strip()
    if text.startswith("```"):
        lines = text.split("\n")
        if lines and lines[0].strip().startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        text = "\n".join(lines).strip()
    return text


def _normalize_categories(parsed: dict) -> dict:
    """LLM이 12종 외 카테고리명을 내면 '기타'로 정규화."""
    items = parsed.get("items", [])
    if not isinstance(items, list):
        return parsed
    for item in items:
        if not isinstance(item, dict):
            continue
        if item.get("category") not in _VALID_CATEGORIES:
            item["category"] = "기타"
    return parsed


async def refine(image_bytes: bytes, draft: str) -> str:
    """LLM이 유효 JSON을 못 만들면 초안을 그대로 돌려줌."""
    if not draft.strip():
        return draft

    prompt = _PROMPT_TEMPLATE.format(draft=draft, schema=_SCHEMA_EXAMPLE)
    try:
        result = await generate_with_image(
            image_bytes=image_bytes,
            prompt=prompt,
            model=get_vision_model(),
        )
    except Exception as exc:
        print(f"[refine] LLM call failed, falling back to draft: {type(exc).__name__}: {exc}", flush=True)
        return draft

    cleaned = _strip_json_fence(result)
    try:
        parsed = json.loads(cleaned)
    except json.JSONDecodeError as exc:
        print(f"[refine] invalid JSON, falling back to draft: {exc}", flush=True)
        return draft

    parsed = _normalize_categories(parsed)
    return json.dumps(parsed, ensure_ascii=False, indent=2)
