from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel


class CamelModel(BaseModel):
    """API JSON / Firestore 키는 camelCase, Python 필드는 snake_case.
    Pydantic이 자동으로 변환해주는 베이스 모델.
    """

    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        from_attributes=True,
    )
