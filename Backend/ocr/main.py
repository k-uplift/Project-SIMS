"""OCR 단독 시험 가동용 FastAPI 진입점 (Gemini 버전).

실행 (Backend/ 디렉터리에서, PowerShell):
    # Backend/.env 에 GEMINI_API_KEY 등 환경변수 작성 후
    uvicorn ocr.main:app --reload --port 8081

전제:
- Google AI Studio에서 발급한 API key 보유
- Backend/.env 에 GEMINI_API_KEY 작성 (자동 로드됨)
- pip install -r ocr/requirements.txt

옛 로컬 (Mac Mini Ollama + PaddleOCR) 버전이 필요하면:
    uvicorn ocr.localocr.main:app --reload --port 8081
"""
from __future__ import annotations

from dotenv import load_dotenv
from fastapi import FastAPI

# .env 자동 로드 — 모듈 import 시점에 실행되어 이후 os.getenv() 호출이 값을 본다.
# Backend/.env 또는 상위 디렉터리에서 탐색 (기본 동작).
load_dotenv()

from .router import router as ocr_router


app = FastAPI(title="OCR Dev (Gemini)", version="0.2.0")
app.include_router(ocr_router)


@app.get("/healthz", tags=["health"])
def healthz() -> dict:
    return {"ok": True}
