from fastapi import APIRouter, Depends, HTTPException, status

from app.auth import CurrentUser, get_current_user
from app.schemas.fridges import (
    Fridge,
    FridgeCreate,
    FridgeJoinRequest,
    FridgeJoinResponse,
    FridgeListResponse,
)

router = APIRouter(prefix="/fridges", tags=["fridges"])

_NOT_IMPL = HTTPException(
    status_code=status.HTTP_501_NOT_IMPLEMENTED,
    detail="Not implemented yet (Week 2)",
)


@router.post(
    "",
    response_model=Fridge,
    status_code=status.HTTP_201_CREATED,
    summary="냉장고 생성 (자동으로 초대 코드 발급)",
)
def create_fridge(
    body: FridgeCreate,
    user: CurrentUser = Depends(get_current_user),
):
    raise _NOT_IMPL


@router.get(
    "/me",
    response_model=FridgeListResponse,
    summary="내가 속한 냉장고 목록",
)
def list_my_fridges(
    user: CurrentUser = Depends(get_current_user),
):
    raise _NOT_IMPL


@router.post(
    "/join",
    response_model=FridgeJoinResponse,
    summary="초대 코드로 냉장고 합류 (memberUids에 본인 uid 추가)",
)
def join_fridge(
    body: FridgeJoinRequest,
    user: CurrentUser = Depends(get_current_user),
):
    raise _NOT_IMPL
