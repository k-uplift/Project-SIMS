from fastapi import APIRouter, Depends, HTTPException, status

from app.auth import CurrentUser, get_current_user
from app.schemas.fcm import FCMRegisterRequest, FCMRegisterResponse

router = APIRouter(prefix="/fcm", tags=["fcm"])

_NOT_IMPL = HTTPException(
    status_code=status.HTTP_501_NOT_IMPLEMENTED,
    detail="Not implemented yet (Week 3)",
)


@router.post(
    "/register",
    response_model=FCMRegisterResponse,
    summary="앱 디바이스 토큰 등록 (FCM 푸시용)",
)
def register_device(
    body: FCMRegisterRequest,
    user: CurrentUser = Depends(get_current_user),
):
    raise _NOT_IMPL
