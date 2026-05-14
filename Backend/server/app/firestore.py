"""Firestore client 헬퍼.

firebase_admin.initialize_app()은 app.auth 모듈 import 시점에 호출되므로,
firestore.client()는 그 이후에 호출되어야 한다. lru_cache로 lazy 초기화.
"""

from functools import lru_cache

from firebase_admin import firestore
from google.cloud.firestore import Client


@lru_cache(maxsize=1)
def get_db() -> Client:
    """Firestore 싱글톤 client 반환. 첫 호출 시 초기화."""
    return firestore.client()
