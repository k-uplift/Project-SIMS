from fastapi import APIRouter, Depends, HTTPException, status

from app.auth import CurrentUser, get_current_user
from app.schemas.users import UserMeResponse

router = APIRouter(prefix="/users", tags=["users"])

_NOT_IMPL = HTTPException(
    status_code=status.HTTP_501_NOT_IMPLEMENTED,
    detail="Not implemented yet (Week 2)",
)


@router.get(
    "/me",
    response_model=UserMeResponse,
    summary="현재 로그인한 사용자 정보 (없으면 첫 호출 시 Firestore에 자동 생성)",
)
def get_me(
    user: CurrentUser = Depends(get_current_user),
):
    raise _NOT_IMPL
