from typing import Optional

from pydantic import BaseModel, Field


class WhoAmIResponse(BaseModel):
    uid: str
    email: Optional[str] = None
    name: Optional[str] = None


class EchoRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=500, examples=["hello"])


class EchoResponse(BaseModel):
    echoed: str
    uid: str
