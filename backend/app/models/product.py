"""
Модель товара/продукта
"""
from typing import Optional
from datetime import datetime
from decimal import Decimal
from sqlmodel import Field, SQLModel


class Product(SQLModel, table=True):
    """Таблица товаров"""
    __tablename__ = "products"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(max_length=255, index=True)
    description: Optional[str] = Field(default=None)
    price: Decimal = Field(max_digits=10, decimal_places=2)
    image_url: Optional[str] = Field(default=None, max_length=500)
    category_id: Optional[int] = Field(default=None, foreign_key="categories.id")
    iiko_id: Optional[str] = Field(default=None, unique=True, index=True, max_length=255)
    is_available: bool = Field(default=True)
    sort_order: int = Field(default=0)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        """Настройки модели"""
        json_schema_extra = {
            "example": {
                "name": "Маргарита",
                "description": "Классическая пицца с моцареллой и томатами",
                "price": 450.00,
                "category_id": 1,
                "is_available": True
            }
        }
