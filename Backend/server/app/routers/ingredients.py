from typing import List

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

_NOT_IMPL = HTTPException(
    status_code=status.HTTP_501_NOT_IMPLEMENTED,
    detail="Not implemented yet (Week 2)",
)


@router.get(
    "/fridges/{fridge_id}/ingredients",
    response_model=List[Ingredient],
    summary="냉장고 식재료 목록 (유통기한 오름차순)",
)
def list_ingredients(
    fridge_id: str,
    user: CurrentUser = Depends(get_current_user),
):
    raise _NOT_IMPL


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
    raise _NOT_IMPL


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
    raise _NOT_IMPL


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
    raise _NOT_IMPL


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
