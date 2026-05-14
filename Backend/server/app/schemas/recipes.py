from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import Field

from app.schemas._base import CamelModel


class RecipeSource(str, Enum):
    LLM = "llm"
    SAVED = "saved"


class Recipe(CamelModel):
    id: str
    title: str = Field(..., examples=["김치찌개"])
    time: str = Field(..., examples=["20분"])
    description: str
    owned_ingredients: List[str] = Field(default_factory=list)
    missing_ingredients: List[str] = Field(default_factory=list)
    steps: List[str] = Field(default_factory=list)


class RecipeRecommendIngredient(CamelModel):
    name: str
    category: str
    count: int
    expire_date: str
    dday: int


class RecipeRecommendRequest(CamelModel):
    fridge_id: str
    ingredients: List[RecipeRecommendIngredient] = Field(default_factory=list)
    cuisine: Optional[str] = Field(None, examples=["한식", "양식", "중식", "일식"])
    difficulty: Optional[str] = Field(None, examples=["쉬움", "보통", "어려움"])
    max_results: int = Field(3, ge=1, le=10)


class RecipeRecommendResponse(CamelModel):
    recipes: List[Recipe]


class RecipeHistoryItem(Recipe):
    source: RecipeSource
    viewed_at: datetime


class RecipeHistoryResponse(CamelModel):
    items: List[RecipeHistoryItem]
