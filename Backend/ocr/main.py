"""OCR 단독 시험 가동용 FastAPI 진입점.

server 통합 전, ocr 모듈만으로 Ollama 비전 호출을 검증하기 위한 앱.

실행 (Backend/ 디렉터리에서, PowerShell):
    $env:OLLAMA_BASE_URL    = "http://119.66.214.191:31342"
    $env:OLLAMA_VISION_MODEL= "qwen2.5vl:7b"
    # 영수증 OCR 결과를 vision LLM으로 한 번 더 검수 (기본 true)
    # $env:OCR_REFINE_ENABLED = "false"   # 끄려면
    uvicorn ocr.main:app --reload --port 8081

전제:
- Mac Mini Ollama 에 vision 모델 설치 (분류·사물 인식용):
    ollama pull qwen2.5vl:7b
- 데스크탑에 PaddleOCR 의존성 설치 (영수증 OCR용, 첫 호출 시 한국어 모델 자동 다운로드):
    pip install -r ocr/requirements.txt
"""
from __future__ import annotations

from fastapi import FastAPI

from .router import router as ocr_router


app = FastAPI(title="OCR Dev", version="0.1.0")
app.include_router(ocr_router)


@app.get("/healthz", tags=["health"])
def healthz() -> dict:
    return {"ok": True}
