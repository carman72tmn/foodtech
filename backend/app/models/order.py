"""
Модели заказа и позиций заказа
"""
from typing import Optional, List
from datetime import datetime
from decimal import Decimal
from enum import Enum
from sqlmodel import Field, SQLModel, Relationship


class OrderStatus(str, Enum):
    """Статусы заказа"""
    NEW = "new"  # Новый заказ
    CONFIRMED = "confirmed"  # Подтвержден
    COOKING = "cooking"  # Готовится
    READY = "ready"  # Готов
    DELIVERING = "delivering"  # Доставляется
    DELIVERED = "delivered"  # Доставлен
    CANCELLED = "cancelled"  # Отменен


class Order(SQLModel, table=True):
    """Таблица заказов"""
    __tablename__ = "orders"

    id: Optional[int] = Field(default=None, primary_key=True)
    telegram_user_id: int = Field(index=True)
    telegram_username: Optional[str] = Field(default=None, max_length=255)
    customer_name: str = Field(max_length=255)
    customer_phone: str = Field(max_length=20)
    delivery_address: str = Field(max_length=500)
    total_amount: Decimal = Field(max_digits=10, decimal_places=2)
    status: OrderStatus = Field(default=OrderStatus.NEW)
    iiko_order_id: Optional[str] = Field(default=None, unique=True, index=True, max_length=255)
    comment: Optional[str] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        """Настройки модели"""
        json_schema_extra = {
            "example": {
                "telegram_user_id": 123456789,
                "customer_name": "Иван Иванов",
                "customer_phone": "+79991234567",
                "delivery_address": "ул. Пушкина, д. 10, кв. 5",
                "total_amount": 1250.00,
                "status": "new"
            }
        }


class OrderItem(SQLModel, table=True):
    """Таблица позиций заказа"""
    __tablename__ = "order_items"

    id: Optional[int] = Field(default=None, primary_key=True)
    order_id: int = Field(foreign_key="orders.id", index=True)
    product_id: int = Field(foreign_key="products.id")
    product_name: str = Field(max_length=255)  # Сохраняем название на момент заказа
    quantity: int = Field(default=1, ge=1)
    price: Decimal = Field(max_digits=10, decimal_places=2)  # Цена на момент заказа
    total: Decimal = Field(max_digits=10, decimal_places=2)  # quantity * price

    class Config:
        """Настройки модели"""
        json_schema_extra = {
            "example": {
                "order_id": 1,
                "product_id": 1,
                "product_name": "Маргарита",
                "quantity": 2,
                "price": 450.00,
                "total": 900.00
            }
        }
