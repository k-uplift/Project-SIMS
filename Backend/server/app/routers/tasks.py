from fastapi import APIRouter, Depends, HTTPException, status

from app.auth import verify_cron_secret
from app.schemas.tasks import CheckExpiryResponse

router = APIRouter(prefix="/tasks", tags=["tasks"])

_NOT_IMPL = HTTPException(
    status_code=status.HTTP_501_NOT_IMPLEMENTED,
    detail="Not implemented yet (Week 3)",
)


@router.post(
    "/check-expiry",
    response_model=CheckExpiryResponse,
    summary="유통기한 임박 식재료 탐지 → FCM 발송 (cron-job.org가 매일 09:00 KST 호출)",
)
def check_expiry(
    _ok: bool = Depends(verify_cron_secret),
):
    raise _NOT_IMPL
