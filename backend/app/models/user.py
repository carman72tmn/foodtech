"""
Модель пользователя (для админ-панели и API аутентификации)
"""
from typing import Optional
from datetime import datetime
from sqlmodel import Field, SQLModel


class User(SQLModel, table=True):
    """Таблица пользователей системы"""
    __tablename__ = "users"

    id: Optional[int] = Field(default=None, primary_key=True)
    username: str = Field(unique=True, index=True, max_length=100)
    email: str = Field(unique=True, index=True, max_length=255)
    hashed_password: str = Field(max_length=255)
    full_name: Optional[str] = Field(default=None, max_length=255)
    is_active: bool = Field(default=True)
    is_superuser: bool = Field(default=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        """Настройки модели"""
        json_schema_extra = {
            "example": {
                "username": "admin",
                "email": "admin@foodtech.com",
                "full_name": "Administrator",
                "is_active": True,
                "is_superuser": True
            }
        }
