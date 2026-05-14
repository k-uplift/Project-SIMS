from app.schemas.chat import ChatRequest, ChatResponse, MessageRole
from app.schemas.common import ErrorResponse, HealthResponse
from app.schemas.dummy import EchoRequest, EchoResponse, WhoAmIResponse
from app.schemas.fcm import DevicePlatform, FCMRegisterRequest, FCMRegisterResponse
from app.schemas.fridges import (
    Fridge,
    FridgeCreate,
    FridgeJoinRequest,
    FridgeJoinResponse,
    FridgeListResponse,
)
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
from app.schemas.users import User, UserMeResponse

__all__ = [
    "ErrorResponse",
    "HealthResponse",
    "EchoRequest",
    "EchoResponse",
    "WhoAmIResponse",
    "ImageIngestRequest",
    "IngestResponse",
    "Ingredient",
    "IngredientCategory",
    "IngredientCreate",
    "IngredientSource",
    "IngredientUpdate",
    "ReceiptIngestRequest",
    "Recipe",
    "RecipeHistoryItem",
    "RecipeHistoryResponse",
    "RecipeRecommendRequest",
    "RecipeRecommendResponse",
    "ChatRequest",
    "ChatResponse",
    "MessageRole",
    "DevicePlatform",
    "FCMRegisterRequest",
    "FCMRegisterResponse",
    "CheckExpiryResponse",
    # fridges
    "Fridge",
    "FridgeCreate",
    "FridgeJoinRequest",
    "FridgeJoinResponse",
    "FridgeListResponse",
    # users
    "User",
    "UserMeResponse",
]
