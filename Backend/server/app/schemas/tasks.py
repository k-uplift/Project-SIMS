from app.schemas._base import CamelModel


class CheckExpiryResponse(CamelModel):
    ok: bool = True
    notified_count: int = 0
    checked_fridges: int = 0
