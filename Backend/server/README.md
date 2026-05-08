# 냉장고를 부탁해 - Server

Python + FastAPI + **Render.com** 기반 백엔드.
Firebase는 Auth/Firestore/FCM 용도로만 사용 (Spark 무료 플랜).

- **담당**: 고범창 (서버)
- **Firebase 프로젝트**: `projectsims-9dc71`
- **모노레포 위치**: `Backend/server/`
- **관련 문서**: [Firestore 스키마 v1](docs/schema-v1.md) · [API 명세 v1](docs/api-v1.md)

---

## 1. 폴더 구조

```
Backend/server/
├── app/
│   ├── main.py            # FastAPI 인스턴스 + CORS + 라우터 등록
│   ├── auth.py            # Firebase ID 토큰 검증 + cron secret 검증
│   ├── schemas/           # Pydantic 모델 (도메인별 분리)
│   │   ├── _base.py       # CamelModel (snake_case ↔ camelCase 변환)
│   │   ├── common.py
│   │   ├── dummy.py
│   │   ├── ingredients.py
│   │   ├── recipes.py
│   │   ├── chat.py
│   │   ├── fcm.py
│   │   └── tasks.py
│   └── routers/
│       ├── health.py      # GET / , GET /healthz
│       ├── dummy.py       # GET /dummy/whoami , POST /dummy/echo
│       ├── ingredients.py # 식재료 CRUD + OCR/이미지 등록 (stub)
│       ├── recipes.py     # 레시피 추천/이력 (stub)
│       ├── chat.py        # 챗봇 (stub)
│       ├── fcm.py         # FCM 디바이스 등록 (stub)
│       └── tasks.py       # cron-job.org 호출 endpoint (stub)
├── docs/
│   ├── api-v1.md
│   └── schema-v1.md
├── .env.example
├── .dockerignore
├── Dockerfile
├── README.md
├── render.yaml            # Render Blueprint (자동 배포 설정)
└── requirements.txt
```

---

## 2. 로컬 실행 (Week 1 합격 기준)

### 사전 준비 (1회)

1. **Python 3.11 권장** (3.13도 동작은 함)
2. **Firebase Admin SDK 서비스 계정 키 발급**
   - [Firebase Console](https://console.firebase.google.com/project/projectsims-9dc71/settings/serviceaccounts/adminsdk) → "새 비공개 키 생성"
   - 다운로드한 JSON 파일을 `Backend/server/service-account.json` 으로 저장 (`.gitignore` 처리됨)
3. **`.env` 파일 생성**
   ```powershell
   cp .env.example .env
   ```

### 실행

```powershell
# 가상환경
python -m venv venv
.\venv\Scripts\Activate.ps1

# 의존성 설치
pip install -r requirements.txt

# 서버 실행
$env:GOOGLE_APPLICATION_CREDENTIALS = ".\service-account.json"
uvicorn app.main:app --reload --port 8000
```

### 동작 확인

- 브라우저에서 [http://localhost:8000/docs](http://localhost:8000/docs) 접속 → Swagger UI
- `GET /` 호출 → `{"status":"ok",...}` 반환
- `GET /dummy/whoami` 호출하려면 Firebase ID 토큰 필요:
  - Flutter 앱에서 `FirebaseAuth.instance.currentUser?.getIdToken()` 출력
  - Swagger UI 우측 상단 "Authorize" → `Bearer <토큰>` 입력 → "Try it out"

---

## 3. Docker로 실행 (배포 전 검증)

```powershell
docker build -t naengbu-server:dev .

docker run --rm -p 8080:8080 `
  -v "${PWD}/service-account.json:/app/service-account.json:ro" `
  -e GOOGLE_APPLICATION_CREDENTIALS=/app/service-account.json `
  naengbu-server:dev
```

→ [http://localhost:8080/docs](http://localhost:8080/docs) 접속.

---

## 4. Render.com 배포 (사용자분이 직접 실행)

> 카드 등록 불필요. GitHub 로그인만으로 시작 가능.
> 한도 초과 시 자동 정지 (예상 못한 청구 X).

### 사전 준비 (1회)

1. https://render.com 접속 → **Sign in with GitHub**
2. GitHub 권한 승인 (Render가 repo 읽기 권한 받음)
3. 코드를 GitHub `main` 브랜치에 미리 push 해두기 (`Backend/server/` 포함)

### 첫 배포 절차

#### Step 1. Blueprint로 서비스 생성

1. Render 대시보드 → **New +** → **Blueprint**
2. **Connect a repository** → `Project-SIMS` 선택
3. Render가 `Backend/server/render.yaml` 자동 인식 → "Apply" 클릭
4. 서비스 이름 `naengbu-server`로 자동 생성됨

#### Step 2. Secret File 업로드 (Firebase 서비스 계정 키)

1. 생성된 서비스 → **Environment** 탭
2. **Secret Files** 섹션 → **Add Secret File**
3. Filename: `service-account.json`
4. Contents: 로컬에 받아둔 `service-account.json` 내용 전체 복붙
5. Save

> Render가 `/etc/secrets/service-account.json` 경로에 마운트해줍니다.
> `render.yaml`에서 `GOOGLE_APPLICATION_CREDENTIALS=/etc/secrets/service-account.json`로 이미 설정됨.

#### Step 3. CORS 환경변수 설정

1. 같은 **Environment** 탭 → **Environment Variables** 섹션
2. `CORS_ORIGINS` 값 입력 (Flutter 앱은 모바일이라 빈 값/localhost만 둬도 무방):
   ```
   http://localhost:3000,http://localhost:8000
   ```
3. Save → 자동 재배포 시작

#### Step 4. 배포 확인

1. **Logs** 탭에서 빌드/배포 진행 상황 확인 (5~10분 소요)
2. 완료되면 상단에 URL 표시: `https://naengbu-server.onrender.com` (서비스명에 따라 다름)
3. 브라우저에서 `https://<URL>/docs` 접속 → Swagger UI 뜨면 성공
4. 팀 단톡방에 URL 공유

### ⚠️ 무료 플랜 주의사항

- **15분 무사용 시 sleep** → 첫 요청 시 30초~1분 콜드스타트
- **시연 5분 전에 미리 한 번 호출**해서 깨워두기 (예: `curl https://<URL>/healthz`)
- 750시간/월 무료 (한 달 = 720~744시간이라 24/7 운영 가능)
- 메모리 512MB / CPU 0.1 vCPU 제한

### 이후 자동 배포

`render.yaml`의 `autoDeploy: true` 덕분에, **GitHub `main` 브랜치에 push만 하면 Render가 자동으로 다시 빌드/배포**합니다.

---

## 5. 환경 변수

| 이름 | 필수? | 설명 |
|------|-------|------|
| `GOOGLE_APPLICATION_CREDENTIALS` | ✅ | 서비스 계정 키 경로 (로컬: 파일 경로 / Render: `/etc/secrets/service-account.json`) |
| `CORS_ORIGINS` | 선택 | 콤마 구분 도메인 (기본: localhost:3000, localhost:8000) |
| `PORT` | Render 자동 주입 | 컨테이너 리스닝 포트 (기본 10000) |

---

## 6. 1주차 체크리스트

- [x] FastAPI 스캐폴딩 + 헬스체크
- [x] Firebase Auth 의존성 (`get_current_user`)
- [x] 더미 엔드포인트 (`/dummy/whoami`, `/dummy/echo`)
- [x] Dockerfile
- [x] Render Blueprint (`render.yaml`)
- [x] Firestore 스키마 v1 **확정** (`docs/schema-v1.md`)
- [x] API 명세 v1 (`docs/api-v1.md`)
- [x] Week 2/3 Stub 라우터 11개 (Pydantic 검증 + 501 반환, Swagger UI 노출)
- [x] Cron 보호 의존성 (`verify_cron_secret`, `X-Cron-Secret` 헤더)
- [x] **로컬 검증**: `uvicorn` + Docker 실행 통과
- [ ] **사용자분 직접**: Firebase Auth/Firestore/FCM 콘솔 활성화
- [ ] **사용자분 직접**: 코드 GitHub `main`에 push
- [ ] **사용자분 직접**: Render에 Blueprint 배포 + Secret File 업로드
- [ ] **사용자분 직접**: `CRON_SECRET` 32자 랜덤 생성 + Render 환경변수 등록
- [ ] **사용자분 직접**: 팀에 Render URL 공유
