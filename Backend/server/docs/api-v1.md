# API 명세 v1 (초안)

> Week 1 더미 단계 + Week 2 본 구현 예정 엔드포인트.
> Swagger UI 자동 생성: `http://localhost:8000/docs` (또는 Cloud Run URL `/docs`)

## 인증

- 모든 보호된 엔드포인트는 헤더에 Firebase ID 토큰 필요:
  ```
  Authorization: Bearer <Firebase ID Token>
  ```
- 토큰은 Flutter에서 `FirebaseAuth.instance.currentUser?.getIdToken()`으로 발급.

## 응답 형식 공통 규칙

- 성공: 명세된 `response_model` 그대로
- 실패: `{ "detail": "에러 메시지" }` (FastAPI 기본)
- 시간 필드: ISO 8601 UTC (예: `"2026-05-08T13:00:00Z"`)

---

## Week 1 (구현 완료)

| 메서드 | 경로 | 인증 | 설명 |
|--------|------|------|------|
| GET | `/` | ❌ | 루트 헬스체크 |
| GET | `/healthz` | ❌ | Liveness probe (Render 헬스체크) |
| GET | `/dummy/whoami` | ✅ Bearer | Firebase ID 토큰 검증 + 사용자 정보 반환 |
| POST | `/dummy/echo` | ✅ Bearer | `{ "message": "..." }` 그대로 반환 |

---

## Week 2 (Stub 등록 완료, 구현 예정)

> 모두 Swagger UI에 노출됨. 호출 시 `501 Not Implemented` 반환.
> 인증 미들웨어 + Pydantic 검증은 작동함 (요청 형식 사전 검증 가능).

### 사용자
| 메서드 | 경로 | 인증 | 설명 |
|--------|------|------|------|
| GET | `/users/me` | ✅ | 현재 사용자 정보 (첫 호출 시 Firestore `users/{uid}` 자동 생성) |

### 냉장고 / 동거인 공유
| 메서드 | 경로 | 인증 | 설명 |
|--------|------|------|------|
| POST | `/fridges` | ✅ | 냉장고 생성 (서버가 `inviteCode` 6자 자동 발급) |
| GET | `/fridges/me` | ✅ | 내가 속한 냉장고 목록 |
| POST | `/fridges/join` | ✅ | 초대 코드(`inviteCode`)로 합류 → `memberUids`에 본인 추가 |

### 식재료
| 메서드 | 경로 | 인증 | 설명 |
|--------|------|------|------|
| GET | `/fridges/{fridgeId}/ingredients` | ✅ | 식재료 목록 (유통기한 오름차순) |
| POST | `/fridges/{fridgeId}/ingredients` | ✅ | 단건 추가 (수동 입력) |
| PATCH | `/fridges/{fridgeId}/ingredients/{ingredientId}` | ✅ | 수량/유통기한 수정 |
| DELETE | `/fridges/{fridgeId}/ingredients/{ingredientId}` | ✅ | 삭제 |
| POST | `/ingredients/from-receipt` | ✅ | 영수증 이미지 → OCR → Firestore 저장 |
| POST | `/ingredients/from-image` | ✅ | 식재료 사진 → 인식 → Firestore 저장 |

### 레시피
| 메서드 | 경로 | 인증 | 설명 |
|--------|------|------|------|
| POST | `/recipes/recommend` | ✅ | 보유 재료 기반 LLM 레시피 추천 |
| GET | `/recipes/history` | ✅ | 본인이 본 레시피 이력 |

### 챗봇
| 메서드 | 경로 | 인증 | 설명 |
|--------|------|------|------|
| POST | `/chat` | ✅ | 단발 질문/응답 (시간 남으면 SSE 스트리밍) |

---

## Week 3 (Stub 등록 완료, 구현 예정)

### 알림 / 스케줄
| 메서드 | 경로 | 인증 | 설명 |
|--------|------|------|------|
| POST | `/fcm/register` | ✅ Bearer | Flutter 앱이 디바이스 토큰 등록 |
| POST | `/tasks/check-expiry` | 🔑 `X-Cron-Secret` | [cron-job.org](https://cron-job.org)가 매일 09:00 KST 호출 → 유통기한 임박 탐지 → FCM 발송 |

> Cloud Run → Render 전환으로 Cloud Scheduler 사용 불가.
> 대안: cron-job.org에서 cron 표현식으로 예약 + `X-Cron-Secret` 헤더로 인증.
> `CRON_SECRET` 환경변수에 비밀값 주입 (`.env.example` 참조).

---

## 에러 코드

| HTTP | 의미 | 발생 케이스 |
|------|------|------|
| 401 | Unauthorized | ID 토큰 누락 / 만료 / 위변조 |
| 403 | Forbidden | 다른 냉장고 자원 접근 시도 |
| 404 | Not Found | 존재하지 않는 fridgeId / ingredientId |
| 422 | Validation | Pydantic 검증 실패 |
| 500 | Internal | 서버 내부 오류 (Cloud Run 로그 확인) |
| 502/503 | External Failure | OpenAI / Vision API 장애 — Week 3에서 fallback 추가 |
