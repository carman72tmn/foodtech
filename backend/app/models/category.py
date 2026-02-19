"""
Модель категории товаров
"""
from typing import Optional
from datetime import datetime
from sqlmodel import Field, SQLModel


class Category(SQLModel, table=True):
    """Таблица категорий товаров"""
    __tablename__ = "categories"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(max_length=255, index=True)
    description: Optional[str] = Field(default=None)
    iiko_id: Optional[str] = Field(default=None, unique=True, index=True, max_length=255)
    sort_order: int = Field(default=0)
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        """Настройки модели"""
        json_schema_extra = {
            "example": {
                "name": "Пицца",
                "description": "Вкусная пицца на любой вкус",
                "sort_order": 1,
                "is_active": True
            }
        }
