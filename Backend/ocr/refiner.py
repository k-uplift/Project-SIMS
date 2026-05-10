"""OCR 결과를 텍스트 전용 LLM으로 카테고리 분류 (JSON 출력).

PaddleOCR 초안만 텍스트 LLM(gpt-oss:20b 기본)에 보내 server의 schema-v1.md
2.8 표준 12종 카테고리로 분류한 JSON을 반환한다. 이미지를 빼서 vision 모델의
"전체 분위기" 편향(영수증 한 장이 전부 한 카테고리로 락되는 패턴)을 회피.

LLM 호출 실패·유효 JSON 아닌 경우 PaddleOCR 초안을 그대로 반환 (fail-soft).
LLM이 12종 외 카테고리명을 내면 자동으로 "기타"로 정규화한다.

토글: OCR_REFINE_ENABLED 환경변수 ("true"/"false", 기본 true)
모델: OLLAMA_REFINE_MODEL 환경변수 (기본 gpt-oss:20b)
"""
from __future__ import annotations

import json
import os

from .client import generate_text_only, get_refine_model


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


_PROMPT_TEMPLATE = """The following is an OCR draft extracted from a Korean grocery receipt:

---
{draft}
---

Classify each line into ONE of the 12 categories below, then output strict JSON only.

[Categories — use these exact Korean labels, no translation]
- 야채 — fresh vegetables, mushrooms, herbs (양파, 시금치, 당근, 마늘, 생강, 고추, 새송이버섯)
- 과일 — fresh fruits (사과, 바나나, 딸기, 산딸기, 포도, 수박)
- 육류 — meat / processed meat (삼겹살, 소고기, 닭가슴살, 햄, 소시지, 스팸, 베이컨)
- 수산물 — fish, seafood, canned fish (고등어, 새우, 오징어, 참치, 연어)
- 유제품 — dairy: 우유, 치즈, 요거트, 버터, 아이스크림, 콩우유
- 달걀 — eggs (계란)
- 곡물/면 — grains and noodles: 쌀, 잡곡, 밀가루, 국수, 라면, 짜파게티, 파스타, 시리얼
- 조미료/소스 — seasonings, sauces: 간장, 된장, 고추장, 케찹, 드레싱, 식초, 잼, 꿀, 솔트, 후추
- 음료 — drinks (incl. alcohol): 생수, 주스, 콜라, 사이다, 차, 커피, 맥주, 소주, 와인, 양주, 토닉워터
- 냉동식품 — frozen prepared food: 만두, 냉동피자, 즉석조리, HMR, 냉동치킨
- 간식/과자 — snacks and confectionery: 과자, 스낵, 빵, 떡, 젤리, 캔디, 초콜릿, 꼬깔콘, 새우깡
- 기타 — anything else: 두부, 콩가공품, household goods (봉투, 쇼핑백, 세제, 휴지)

[Classification rules]
1. If the item is edible or drinkable, pick the closest food category. If unsure, use 기타.
2. Unknown Korean brand items that look like food → closest food category.
3. 두부, 콩가공품, 청국장 → 기타 (no exact category fits).
4. Bags, wrappers, household goods, detergent → 기타.
5. 라면, 짜파게티 → 곡물/면 (NOT 간식/과자).
6. 빵 → 간식/과자 (NOT 곡물/면).

[JSON schema — output exactly this structure]
{schema}

[Strict requirements]
- `name`: copy the OCR draft text verbatim. Whitespace cleanup OK. NEVER modify Korean characters.
- `category`: must be exactly one of the 12 Korean labels above (야채, 과일, 육류, 수산물, 유제품, 달걀, 곡물/면, 조미료/소스, 음료, 냉동식품, 간식/과자, 기타). No translations, no synonyms.
- Store name, address, datetime, POS, totals, tax, payment, card number → put in `metadata` array, never in `items`.
- Output ONE JSON object only. No markdown fences (```), no preamble, no commentary.
- For `price` / `quantity`: use empty string "" when missing from the OCR draft. NEVER guess."""


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


async def refine(draft: str) -> str:
    """LLM이 유효 JSON을 못 만들면 초안을 그대로 돌려줌."""
    if not draft.strip():
        return draft

    prompt = _PROMPT_TEMPLATE.format(draft=draft, schema=_SCHEMA_EXAMPLE)
    try:
        result = await generate_text_only(
            prompt=prompt,
            model=get_refine_model(),
        )
    except Exception as exc:
        print(f"[refine] LLM call failed, falling back to draft: {type(exc).__name__}: {exc}", flush=True)
        return draft

    # TEMP DEBUG: gpt-oss 출력 형식 확인용
    print(f"[refine] raw LLM response (len={len(result)}):", flush=True)
    print(f"[refine] >>>{result[:1500]}<<<", flush=True)

    cleaned = _strip_json_fence(result)
    try:
        parsed = json.loads(cleaned)
    except json.JSONDecodeError as exc:
        print(f"[refine] invalid JSON, falling back to draft: {exc}", flush=True)
        return draft

    parsed = _normalize_categories(parsed)
    return json.dumps(parsed, ensure_ascii=False, indent=2)
