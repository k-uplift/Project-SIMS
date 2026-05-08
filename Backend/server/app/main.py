import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import chat, dummy, fcm, health, ingredients, recipes, tasks


app = FastAPI(
    title="냉장고를 부탁해 - Server",
    description="Flutter 앱과 연동되는 FastAPI 백엔드 (Render.com 배포)",
    version="0.1.0",
)


_default_origins = "http://localhost:3000,http://localhost:8000"
_origins = [
    o.strip()
    for o in os.getenv("CORS_ORIGINS", _default_origins).split(",")
    if o.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(health.router)
app.include_router(dummy.router)
app.include_router(ingredients.router)
app.include_router(recipes.router)
app.include_router(chat.router)
app.include_router(fcm.router)
app.include_router(tasks.router)
