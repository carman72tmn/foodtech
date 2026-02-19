"""
Pydantic схемы для валидации данных API
"""
from typing import Optional, List
from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel, Field, ConfigDict
from app.models.order import OrderStatus


# ============= Схемы категорий =============

class CategoryBase(BaseModel):
    """Базовые поля категории"""
    name: str = Field(max_length=255)
    description: Optional[str] = None
    sort_order: int = 0
    is_active: bool = True


class CategoryCreate(CategoryBase):
    """Создание категории"""
    pass


class CategoryUpdate(BaseModel):
    """Обновление категории"""
    name: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class CategoryResponse(CategoryBase):
    """Ответ API с категорией"""
    id: int
    iiko_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============= Схемы товаров =============

class ProductBase(BaseModel):
    """Базовые поля товара"""
    name: str = Field(max_length=255)
    description: Optional[str] = None
    price: Decimal = Field(ge=0, decimal_places=2)
    image_url: Optional[str] = None
    category_id: Optional[int] = None
    is_available: bool = True
    sort_order: int = 0


class ProductCreate(ProductBase):
    """Создание товара"""
    pass


class ProductUpdate(BaseModel):
    """Обновление товара"""
    name: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = None
    price: Optional[Decimal] = Field(None, ge=0, decimal_places=2)
    image_url: Optional[str] = None
    category_id: Optional[int] = None
    is_available: Optional[bool] = None
    sort_order: Optional[int] = None


class ProductResponse(ProductBase):
    """Ответ API с товаром"""
    id: int
    iiko_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============= Схемы заказов =============

class OrderItemCreate(BaseModel):
    """Позиция в новом заказе"""
    product_id: int
    quantity: int = Field(ge=1)


class OrderItemResponse(BaseModel):
    """Ответ API с позицией заказа"""
    id: int
    product_id: int
    product_name: str
    quantity: int
    price: Decimal
    total: Decimal

    model_config = ConfigDict(from_attributes=True)


class OrderCreate(BaseModel):
    """Создание нового заказа"""
    telegram_user_id: int
    telegram_username: Optional[str] = None
    customer_name: str = Field(max_length=255)
    customer_phone: str = Field(max_length=20)
    delivery_address: str = Field(max_length=500)
    comment: Optional[str] = None
    items: List[OrderItemCreate] = Field(min_length=1)


class OrderUpdate(BaseModel):
    """Обновление заказа"""
    status: Optional[OrderStatus] = None
    customer_name: Optional[str] = Field(None, max_length=255)
    customer_phone: Optional[str] = Field(None, max_length=20)
    delivery_address: Optional[str] = Field(None, max_length=500)
    comment: Optional[str] = None


class OrderResponse(BaseModel):
    """Ответ API с заказом"""
    id: int
    telegram_user_id: int
    telegram_username: Optional[str] = None
    customer_name: str
    customer_phone: str
    delivery_address: str
    total_amount: Decimal
    status: OrderStatus
    iiko_order_id: Optional[str] = None
    comment: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    items: List[OrderItemResponse] = []

    model_config = ConfigDict(from_attributes=True)


# ============= Схемы синхронизации с iiko =============

class IikoSyncResponse(BaseModel):
    """Результат синхронизации с iiko"""
    success: bool
    categories_synced: int
    products_synced: int
    message: str
