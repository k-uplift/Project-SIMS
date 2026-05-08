from app.schemas.chat import ChatRequest, ChatResponse, MessageRole
from app.schemas.common import ErrorResponse, HealthResponse
from app.schemas.dummy import EchoRequest, EchoResponse, WhoAmIResponse
from app.schemas.fcm import DevicePlatform, FCMRegisterRequest, FCMRegisterResponse
from app.schemas.ingredients import (
    ImageIngestRequest,
    IngestResponse,
    Ingredient,
    IngredientCategory,
    IngredientCreate,
    IngredientSource,
    IngredientUpdate,
    ReceiptIngestRequest,
)
from app.schemas.recipes import (
    Recipe,
    RecipeHistoryItem,
    RecipeHistoryResponse,
    RecipeRecommendRequest,
    RecipeRecommendResponse,
)
from app.schemas.tasks import CheckExpiryResponse

__all__ = [
    # common
    "ErrorResponse",
    "HealthResponse",
    # dummy
    "EchoRequest",
    "EchoResponse",
    "WhoAmIResponse",
    # ingredients
    "ImageIngestRequest",
    "IngestResponse",
    "Ingredient",
    "IngredientCategory",
    "IngredientCreate",
    "IngredientSource",
    "IngredientUpdate",
    "ReceiptIngestRequest",
    # recipes
    "Recipe",
    "RecipeHistoryItem",
    "RecipeHistoryResponse",
    "RecipeRecommendRequest",
    "RecipeRecommendResponse",
    # chat
    "ChatRequest",
    "ChatResponse",
    "MessageRole",
    # fcm
    "DevicePlatform",
    "FCMRegisterRequest",
    "FCMRegisterResponse",
    # tasks
    "CheckExpiryResponse",
]
