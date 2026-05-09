"""OCR 단독 시험 가동용 FastAPI 진입점.

server 통합 전, ocr 모듈만으로 Ollama 비전 호출을 검증하기 위한 앱.

실행 (Backend/ 디렉터리에서, PowerShell):
    $env:OLLAMA_BASE_URL    = "http://119.66.214.191:31342"
    $env:OLLAMA_OCR_MODEL   = "deepseek-ocr:latest"
    $env:OLLAMA_VISION_MODEL= "qwen2.5vl:7b"
    uvicorn ocr.main:app --reload --port 8081

전제: Mac Mini Ollama 에 두 모델이 모두 설치되어 있어야 함.
    ollama pull deepseek-ocr
    ollama pull qwen2.5vl:7b
"""
from __future__ import annotations

from fastapi import FastAPI

from .router import router as ocr_router


app = FastAPI(title="OCR Dev", version="0.1.0")
app.include_router(ocr_router)


@app.get("/healthz", tags=["health"])
def healthz() -> dict:
    return {"ok": True}
