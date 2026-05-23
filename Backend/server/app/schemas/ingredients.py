from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import Field

from app.schemas._base import CamelModel


class IngredientCategory(str, Enum):
    """schema-v1.md 2.8 표준 12종"""

    VEGETABLE = "야채"
    FRUIT = "과일"
    MEAT = "육류"
    SEAFOOD = "수산물"
    DAIRY = "유제품"
    EGG = "달걀"
    GRAIN_NOODLE = "곡물/면"
    SAUCE = "조미료/소스"
    BEVERAGE = "음료"
    FROZEN = "냉동식품"
    SNACK = "간식/과자"
    OTHER = "기타"


class IngredientSource(str, Enum):
    MANUAL = "manual"
    RECEIPT = "receipt"
    IMAGE = "image"


class IngredientBase(CamelModel):
    name: str = Field(..., min_length=1, max_length=50, examples=["양파"])
    category: IngredientCategory = Field(..., examples=[IngredientCategory.VEGETABLE])
    emoji: Optional[str] = Field(None, max_length=8, examples=["🧅"])
    count: int = Field(1, ge=1, examples=[3])
    expire_date: datetime = Field(..., description="유통기한 (UTC)")
    image_url: Optional[str] = Field(None, examples=["https://.../onion.jpg"])


class IngredientCreate(IngredientBase):
    added_via: IngredientSource = IngredientSource.MANUAL


class IngredientUpdate(CamelModel):
    name: Optional[str] = Field(None, min_length=1, max_length=50)
    category: Optional[IngredientCategory] = None
    emoji: Optional[str] = Field(None, max_length=8)
    count: Optional[int] = Field(None, ge=1)
    expire_date: Optional[datetime] = None
    image_url: Optional[str] = None


class Ingredient(IngredientBase):
    id: str
    fridge_id: str
    added_by: str = Field(..., description="추가한 사용자 uid")
    added_via: IngredientSource
    created_at: datetime
    updated_at: datetime


class ReceiptIngestRequest(CamelModel):
    fridge_id: str
    image_url: str = Field(..., description="영수증 이미지 (Cloud Storage URL)")


class ImageIngestRequest(CamelModel):
    fridge_id: str
    image_url: str = Field(..., description="식재료 실물 이미지 URL")


class IngestResponse(CamelModel):
    ingested: List[Ingredient] = Field(default_factory=list)
    skipped: List[str] = Field(
        default_factory=list,
        description="OCR/이미지 인식 실패하거나 분류 불가능한 항목 이름",
    )
