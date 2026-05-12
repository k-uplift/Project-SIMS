import json
from datetime import datetime, timezone
from pathlib import Path
from typing import List
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status

from app.auth import CurrentUser, get_current_user
from app.schemas.ingredients import (
    ImageIngestRequest,
    IngestResponse,
    Ingredient,
    IngredientCreate,
    IngredientUpdate,
    ReceiptIngestRequest,
)

router = APIRouter(tags=["ingredients"])

_DATA_DIR = Path(__file__).resolve().parents[2] / "data"
_DATA_FILE = _DATA_DIR / "ingredients.json"

_NOT_IMPL = HTTPException(
    status_code=status.HTTP_501_NOT_IMPLEMENTED,
    detail="Not implemented yet (Week 2)",
)


def _load_ingredients() -> List[Ingredient]:
    if not _DATA_FILE.exists():
        return []

    with _DATA_FILE.open("r", encoding="utf-8") as f:
        raw_items = json.load(f)

    return [Ingredient(**item) for item in raw_items]


def _save_ingredients(items: List[Ingredient]) -> None:
    _DATA_DIR.mkdir(parents=True, exist_ok=True)
    payload = [
        item.model_dump(mode="json", by_alias=True)
        for item in items
    ]

    with _DATA_FILE.open("w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)


def _now() -> datetime:
    return datetime.now(timezone.utc)


@router.get(
    "/fridges/{fridge_id}/ingredients",
    response_model=List[Ingredient],
    summary="냉장고 식재료 목록 (유통기한 오름차순)",
)
def list_ingredients(
    fridge_id: str,
    user: CurrentUser = Depends(get_current_user),
):
    items = [
        item
        for item in _load_ingredients()
        if item.fridge_id == fridge_id and item.added_by == user.uid
    ]

    return sorted(items, key=lambda item: item.expire_date)


@router.post(
    "/fridges/{fridge_id}/ingredients",
    response_model=Ingredient,
    status_code=status.HTTP_201_CREATED,
    summary="식재료 단건 추가 (수동 입력)",
)
def create_ingredient(
    fridge_id: str,
    body: IngredientCreate,
    user: CurrentUser = Depends(get_current_user),
):
    items = _load_ingredients()
    now = _now()
    ingredient = Ingredient(
        id=str(uuid4()),
        fridge_id=fridge_id,
        added_by=user.uid,
        added_via=body.added_via,
        created_at=now,
        updated_at=now,
        **body.model_dump(),
    )

    items.append(ingredient)
    _save_ingredients(items)

    return ingredient


@router.patch(
    "/fridges/{fridge_id}/ingredients/{ingredient_id}",
    response_model=Ingredient,
    summary="식재료 수정 (수량/유통기한 등)",
)
def update_ingredient(
    fridge_id: str,
    ingredient_id: str,
    body: IngredientUpdate,
    user: CurrentUser = Depends(get_current_user),
):
    items = _load_ingredients()
    update_data = body.model_dump(exclude_unset=True)

    for index, item in enumerate(items):
        if item.id != ingredient_id:
            continue

        if item.fridge_id != fridge_id or item.added_by != user.uid:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Ingredient not found",
            )

        updated = item.model_copy(
            update={
                **update_data,
                "updated_at": _now(),
            }
        )
        items[index] = updated
        _save_ingredients(items)
        return updated

    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Ingredient not found",
    )


@router.delete(
    "/fridges/{fridge_id}/ingredients/{ingredient_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="식재료 삭제",
)
def delete_ingredient(
    fridge_id: str,
    ingredient_id: str,
    user: CurrentUser = Depends(get_current_user),
):
    items = _load_ingredients()
    kept_items = [
        item
        for item in items
        if not (
            item.id == ingredient_id
            and item.fridge_id == fridge_id
            and item.added_by == user.uid
        )
    ]

    if len(kept_items) == len(items):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ingredient not found",
        )

    _save_ingredients(kept_items)


@router.post(
    "/ingredients/from-receipt",
    response_model=IngestResponse,
    summary="영수증 이미지 → OCR → 식재료 일괄 등록",
)
def ingest_from_receipt(
    body: ReceiptIngestRequest,
    user: CurrentUser = Depends(get_current_user),
):
    raise _NOT_IMPL


@router.post(
    "/ingredients/from-image",
    response_model=IngestResponse,
    summary="식재료 실물 이미지 → 인식 → 등록",
)
def ingest_from_image(
    body: ImageIngestRequest,
    user: CurrentUser = Depends(get_current_user),
):
    raise _NOT_IMPL
