from fastapi import APIRouter, Depends

from app.auth import CurrentUser, get_current_user
from app.schemas import EchoRequest, EchoResponse, WhoAmIResponse

router = APIRouter(prefix="/dummy", tags=["dummy"])


@router.get(
    "/whoami",
    response_model=WhoAmIResponse,
    summary="Firebase ID 토큰 검증 + 사용자 정보 반환",
)
def whoami(user: CurrentUser = Depends(get_current_user)) -> WhoAmIResponse:
    return WhoAmIResponse(uid=user.uid, email=user.email, name=user.name)


@router.post(
    "/echo",
    response_model=EchoResponse,
    summary="요청 본문 그대로 반환 (인증 필요)",
)
def echo(
    body: EchoRequest,
    user: CurrentUser = Depends(get_current_user),
) -> EchoResponse:
    return EchoResponse(echoed=body.message, uid=user.uid)
