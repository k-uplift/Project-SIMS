from fastapi import APIRouter, Depends, HTTPException, status

from app.auth import CurrentUser, get_current_user
from app.schemas.chat import ChatRequest, ChatResponse

router = APIRouter(tags=["chat"])

_NOT_IMPL = HTTPException(
    status_code=status.HTTP_501_NOT_IMPLEMENTED,
    detail="Not implemented yet (Week 2)",
)


@router.post(
    "/chat",
    response_model=ChatResponse,
    summary="챗봇 단발 응답 (Week 2: 단발, 시간 남으면 SSE 스트리밍)",
)
def chat(
    body: ChatRequest,
    user: CurrentUser = Depends(get_current_user),
):
    raise _NOT_IMPL
