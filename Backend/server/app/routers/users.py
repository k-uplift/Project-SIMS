from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from google.cloud.firestore import SERVER_TIMESTAMP

from app.auth import CurrentUser, get_current_user
from app.firestore import get_db
from app.schemas.users import UserMeResponse

router = APIRouter(prefix="/users", tags=["users"])


@router.get(
    "/me",
    response_model=UserMeResponse,
    summary="현재 로그인 사용자 정보 (첫 호출 시 Firestore 자동 생성)",
)
def get_me(user: CurrentUser = Depends(get_current_user)) -> UserMeResponse:
    """
    동작:
    1. Firebase ID 토큰 검증 (get_current_user 의존성)
    2. Firestore `users/{uid}` 조회
    3. 문서 없으면 (= 첫 로그인) 자동 생성 후 재조회
    4. Firestore 데이터 + Auth 토큰 클레임을 합쳐서 반환
    """
    db = get_db()
    doc_ref = db.collection("users").document(user.uid)
    snapshot = doc_ref.get()

    if not snapshot.exists:
        # 첫 로그인 — Firestore에 사용자 문서 자동 생성
        doc_ref.set(
            {
                "email": user.email or "",
                "fridgeIds": [],
                "createdAt": SERVER_TIMESTAMP,
                "updatedAt": SERVER_TIMESTAMP,
            }
        )
        snapshot = doc_ref.get()

    data = snapshot.to_dict() or {}

    # Firestore Timestamp → Python datetime (이미 datetime 객체로 옴)
    created_at = data.get("createdAt") or datetime.now(timezone.utc)
    updated_at = data.get("updatedAt") or datetime.now(timezone.utc)

    return UserMeResponse(
        uid=user.uid,
        email=data.get("email") or user.email or "",
        display_name=user.name,
        photo_url=user.picture,
        fridge_ids=data.get("fridgeIds", []),
        created_at=created_at,
        updated_at=updated_at,
    )
