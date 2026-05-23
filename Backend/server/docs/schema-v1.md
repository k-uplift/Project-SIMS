# Firestore 스키마 v2 (운영본)

> 상태: **v2 확정 — 이윤수 작성, 2026-05-11 운영 반영**
> v1 (2026-05-08, 고범창 임시본) → v2로 교체. v1 변경 이력은 7번 참조.
> 작성: 이윤수 (DB 담당) / 문서 정리: 고범창 (서버 담당)
> 출처: 운영 Firestore (`projectsims-9dc71`) 실제 데이터 + 프로젝트 제안서

## 0. 설계 원칙

- **컬렉션-하위컬렉션 구조** (조인 없음, 읽기 빠름).
- **냉장고 단위로 공유** — 동거인은 같은 `fridges/{fridgeId}` 문서를 공유.
- **타임스탬프는 Firestore Timestamp 타입** 사용 (ISO 문자열 X). API 응답 시 ISO 8601 UTC로 직렬화.
- **문서 ID**는 Firestore auto-id 기본 사용.
- **명명 규칙**: Firestore 키 + API JSON = `camelCase`. Python 코드(Pydantic) = `snake_case` + alias로 변환.
- **Security Rules**는 Week 3 마지막에 최종 확정. v1에서는 키 구조만 합의.

---

## 1. 컬렉션 트리

```
users/{uid}
  └─ (기본 정보 + 소속 fridge 목록)

fridges/{fridgeId}
  ├─ (냉장고 메타: 이름, 멤버 uid 목록)
  ├─ ingredients/{ingredientId}
  │   └─ (식재료 1건)
  └─ shoppingItems/{itemId}        # 부족 재료 자동 생성 (Week 2~3)

recipesHistory/{uid}/items/{recipeId}
  └─ (사용자가 본/저장한 레시피 이력)

chats/{uid}/sessions/{sessionId}
  ├─ (채팅 세션 메타)
  └─ messages/{messageId}
      └─ (개별 메시지)

fcmTokens/{uid}/devices/{deviceId}
  └─ (푸시 알림용 디바이스 토큰)
```

---

## 2. 컬렉션별 필드

### 2.1 `users/{uid}`

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `email` | string | ✅ | Firebase Auth에서 가져옴 |
| `fridgeIds` | array\<string\> | ✅ | 소속된 냉장고 ID (보통 1~2개) |
| `createdAt` | Timestamp | ✅ | 가입일 |
| `updatedAt` | Timestamp | ✅ | 마지막 갱신 |

> ℹ️ `displayName`, `photoURL`은 **Firebase Auth 토큰 클레임에 이미 포함**되어 있어 Firestore에 중복 저장하지 않음. 서버가 토큰 검증할 때 직접 읽어서 사용.

### 2.2 `fridges/{fridgeId}`

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `name` | string | ✅ | 예: "내 냉장고" |
| `ownerUid` | string | ✅ | 생성자 uid (멤버 추가/제거 권한) |
| `memberUids` | array\<string\> | ✅ | 동거인 uid 목록 (Security Rules에서 `request.auth.uid in memberUids` 체크) |
| `inviteCode` | string (6자) | ✅ | **동거인 초대 코드** (영문 대문자 6자, 예: `"SZCSYJ"`). 다른 사용자가 이 코드로 `memberUids`에 합류 |
| `createdAt` | Timestamp | ✅ | |
| `updatedAt` | Timestamp | ✅ | |

> 🛡️ **`inviteCode` 운영 메모**:
> - 26^6 ≈ 3억 조합으로 학생 프로젝트에 충분.
> - 발급 시 **중복 체크** 로직 필요 (Firestore에서 동일 코드 존재 여부 확인 후 재생성).
> - 보안 강화 필요 시 만료 시간 / 재발급 기능 검토 (W3 이후).

### 2.3 `fridges/{fridgeId}/ingredients/{ingredientId}` ⭐ 핵심 컬렉션

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `name` | string | ✅ | 예: "양파" |
| `category` | string (enum, 2.8 참조) | ✅ | 12종 표준 카테고리 |
| `emoji` | string | ❌ | 예: "🧅" (1~4자, 화면 표시용) |
| `count` | integer (≥1) | ✅ | 수량 (개수만, 단위는 추후 `unit` 필드 추가 검토) |
| `expireDate` | Timestamp | ✅ | 유통기한 (D-day는 Flutter에서 계산) |
| `imageURL` | string (URL) | ❌ | Cloud Storage URL (실물 사진/영수증) |
| `addedBy` | string (uid) | ✅ | 추가한 사용자 uid |
| `addedVia` | string (enum) | ✅ | `"manual" \| "receipt" \| "image"` |
| `createdAt` | Timestamp | ✅ | |
| `updatedAt` | Timestamp | ✅ | |

**인덱스**: `fridgeId + expireDate` (오름차순) — 유통기한 임박 쿼리용.

> 🚨 **`imageURL` 운영 이슈 발견 (2026-05-11)**:
> 현재 실제 데이터에 `/data/user/0/com.fridge.my_fridge_app/cache/...jpg` 같은 **Flutter 안드로이드 로컬 캐시 경로**가 저장되어 있음.
> 이는 그 디바이스에서만 보이는 경로라 **동거인 공유 시 다른 사람은 이미지를 못 봄** — 핵심 기능 결함.
> → W2 작업: Flutter가 Firebase Storage에 업로드한 후 받은 `https://firebasestorage.googleapis.com/...` URL을 저장하도록 수정 필요 (김규섭님 협업).

### 2.4 `fridges/{fridgeId}/shoppingItems/{itemId}` (Week 2~3)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `name` | string | ✅ | 부족한 재료명 |
| `requestedFor` | string | ❌ | recipeId (이 레시피 때문에 필요) |
| `checked` | bool | ✅ | 구매 완료 여부 (기본 false) |
| `createdAt` | Timestamp | ✅ | |

### 2.5 `recipesHistory/{uid}/items/{recipeId}`

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `title` | string | ✅ | |
| `time` | string | ✅ | 예: "20분" |
| `description` | string | ✅ | |
| `ownedIngredients` | array\<string\> | ✅ | 보유 재료 이름 |
| `missingIngredients` | array\<string\> | ✅ | 부족 재료 이름 |
| `steps` | array\<string\> | ✅ | 조리 단계 |
| `source` | string (enum) | ✅ | `"llm" \| "saved"` |
| `viewedAt` | Timestamp | ✅ | |

### 2.6 `chats/{uid}/sessions/{sessionId}` + `messages/{messageId}`

**세션 메타** (`chats/{uid}/sessions/{sessionId}`):

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `title` | string | ✅ | 첫 메시지에서 자동 생성 |
| `recipeId` | string | ❌ | 레시피 챗봇이면 관련 레시피 ID |
| `createdAt` | Timestamp | ✅ | |
| `updatedAt` | Timestamp | ✅ | |

**메시지** (`.../messages/{messageId}`):

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `text` | string | ✅ | |
| `role` | string (enum) | ✅ | `"user" \| "assistant" \| "system"` |
| `createdAt` | Timestamp | ✅ | |

> Flutter `ChatMessage`(text, isUser)와 매핑: `isUser == (role == "user")`.

### 2.7 `fcmTokens/{uid}/devices/{deviceId}`

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `token` | string | ✅ | FCM 디바이스 토큰 |
| `platform` | string (enum) | ✅ | `"android" \| "ios"` |
| `lastSeenAt` | Timestamp | ✅ | 마지막 갱신 |

### 2.8 `category` enum 표준값

영수증 OCR / 이미지 인식 결과를 매핑할 표준 12종 (한국 마트 카테고리 기준):

| enum 값 | 예시 |
|---------|------|
| `야채` | 양파, 시금치, 당근 |
| `과일` | 사과, 바나나, 딸기 |
| `육류` | 삼겹살, 닭가슴살, 소고기 |
| `수산물` | 고등어, 새우, 오징어 |
| `유제품` | 우유, 치즈, 요거트 |
| `달걀` | 계란 |
| `곡물/면` | 쌀, 라면, 파스타 |
| `조미료/소스` | 간장, 된장, 케찹 |
| `음료` | 콜라, 주스, 생수 |
| `냉동식품` | 만두, 냉동피자 |
| `간식/과자` | 과자, 빵, 초콜릿 |
| `기타` | 분류 안 되는 항목 |

> 매핑 규칙: OCR/이미지 인식이 위 12종에 들지 않으면 `"기타"` + Flutter에서 사용자가 수정 가능.

---

## 3. Security Rules 방향성 (v1 메모, 최종은 Week 3)

```
match /fridges/{fridgeId} {
  allow read, write: if request.auth.uid in resource.data.memberUids;

  match /ingredients/{ingredientId} {
    allow read, write: if request.auth.uid in
      get(/databases/$(database)/documents/fridges/$(fridgeId)).data.memberUids;
  }
}

match /users/{uid} {
  allow read, write: if request.auth.uid == uid;
}

match /recipesHistory/{uid}/items/{recipeId} {
  allow read, write: if request.auth.uid == uid;
}
```

---

## 4. 마이그레이션/시드 데이터 (선택)

테스트용 더미 데이터 1세트:
- user 1명 (본인 계정)
- fridge 1개 (멤버 = 본인)
- ingredients 5개 (양파, 우유, 계란, 삼겹살, 시금치) — `expireDate`를 D-1, D-3, D-7로 분산

→ Week 1 끝나기 전 Firestore 콘솔에서 직접 입력 or seed 스크립트로.

---

## 5. 결정 사항 기록

| # | 질문 | 결정 |
|---|------|------|
| 1 | 위 컬렉션 구조 OK? | ✅ 사용 |
| 2 | `ingredients`를 `fridges` 하위컬렉션으로? | ✅ **하위컬렉션** |
| 3 | `expireDate` 타입 | ✅ **Timestamp 통일** |
| 4 | `memberUids` array 방식 | ✅ OK |
| 5 | Flutter 모델과 필드명 차이 | 서버 기준 통일 (아래 5-1) |

### 5-1. Flutter 모델 ↔ 서버 스키마 매핑 (서버가 정답)

| Flutter `Ingredient` | 서버 스키마 | 처리 |
|----------------------|-------------|------|
| `id` | `id` (Firestore 문서 ID) | API 응답에 포함 |
| `userId` | `addedBy` | Flutter 모델 갱신 필요 (`userId` → `addedBy`) |
| `name` | `name` | 그대로 |
| `category` | `category` (enum) | Flutter도 동일 enum 따름 |
| `emoji` | `emoji` | 그대로 |
| `dday` | (없음) | Flutter가 `expireDate - now()`로 계산 |
| `count` | `count` (integer) | 그대로 |
| `expireDate` | `expireDate` (Timestamp) | Flutter는 `DateTime`으로 파싱 |
| `imagePath` | `imageURL` | Flutter 모델 갱신 필요 |
| (없음) | `addedVia`, `createdAt`, `updatedAt` | Flutter 모델에 추가 |

### 5-2. 추가 결정 사항 (서버 담당이 알아서 정함)

- **명명 규칙**: API JSON / Firestore = `camelCase`. Pydantic 모델은 `snake_case` + alias 변환.
- **`category` enum**: 위 2.8의 12종 한글 표준 사용. Flutter도 같은 enum 정의 필요.
- **`count` 단위**: 정수 개수만 (`1, 2, 3...`). "200g" 같은 단위가 필요하면 Week 2에서 별도 `unit` 필드 추가 검토.
- **필수/선택**: 위 표의 "필수" 컬럼대로. 식별·조회용 핵심 필드는 필수, 부가 표시용은 선택.
- **`expireDate` 형식**: Firestore Timestamp 저장, API 응답에서는 ISO 8601 UTC 문자열 (예: `"2026-05-15T00:00:00Z"`).
- **이미지 업로드 경로**: Week 2 결정 (앱 → Firebase Storage 직접 업로드 후 URL을 서버로 전달하는 방식이 유력).

---

## 6. 향후 변경 정책

- 스키마 변경은 GitHub Issue로만 통보 (구두/카톡 X).
- 변경 시 v2, v3로 버전 올림. 이 문서는 변경 이력 보존.
- Week 2 시작 전까지는 자유롭게 수정, 그 이후엔 마이그레이션 비용 고려.

---

## 7. 변경 이력 (Changelog)

### v1 → v2 (2026-05-11, 이윤수)

**추가:**
- `fridges.inviteCode` (string, 6자) — 동거인 초대 코드 도입. `memberUids`에 합류시키는 메커니즘.

**제거:**
- `users.displayName` — Firebase Auth 클레임에 이미 존재 (중복 제거)
- `users.photoURL` — Firebase Auth 클레임에 이미 존재 (중복 제거)

**구조 그대로 유지:**
- `users.email`, `users.fridgeIds`, `users.createdAt`, `users.updatedAt`
- `fridges.name`, `fridges.ownerUid`, `fridges.memberUids`, `fridges.createdAt`, `fridges.updatedAt`
- `ingredients` 전체 (모든 필드/타입 동일)
- `shoppingItems`, `recipesHistory`, `chats`, `fcmTokens` 전체

**알려진 이슈 (v2에서 발견):**
- `ingredients.imageURL`이 Flutter 로컬 캐시 경로로 저장되는 버그 → W2 수정 필요 (2.3 참조)
- `fridges.inviteCode` 발급 시 중복 체크 로직 필요 (2.2 참조)
