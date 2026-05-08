from fastapi import APIRouter, Depends, HTTPException, status

from app.auth import CurrentUser, get_current_user
from app.schemas.recipes import (
    RecipeHistoryResponse,
    RecipeRecommendRequest,
    RecipeRecommendResponse,
)

router = APIRouter(prefix="/recipes", tags=["recipes"])

_NOT_IMPL = HTTPException(
    status_code=status.HTTP_501_NOT_IMPLEMENTED,
    detail="Not implemented yet (Week 2)",
)


@router.post(
    "/recommend",
    response_model=RecipeRecommendResponse,
    summary="보유 재료 기반 LLM 레시피 추천",
)
def recommend_recipes(
    body: RecipeRecommendRequest,
    user: CurrentUser = Depends(get_current_user),
):
    raise _NOT_IMPL


@router.get(
    "/history",
    response_model=RecipeHistoryResponse,
    summary="본인이 본 레시피 이력",
)
def list_recipe_history(
    user: CurrentUser = Depends(get_current_user),
):
    raise _NOT_IMPL
