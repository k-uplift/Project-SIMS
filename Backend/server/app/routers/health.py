from fastapi import APIRouter

from app.schemas import HealthResponse

router = APIRouter(tags=["health"])


@router.get("/", response_model=HealthResponse, summary="Root health check")
def root() -> HealthResponse:
    return HealthResponse(status="ok", service="naengbu-server", version="0.1.0")


@router.get("/healthz", response_model=HealthResponse, summary="Liveness probe")
def healthz() -> HealthResponse:
    return HealthResponse(status="ok", service="naengbu-server", version="0.1.0")
