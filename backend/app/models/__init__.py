"""
Модели базы данных для FoodTech
Все модели наследуются от SQLModel для использования с FastAPI
"""
from .user import User
from .category import Category
from .product import Product
from .order import Order, OrderItem, OrderStatus

__all__ = [
    "User",
    "Category",
    "Product",
    "Order",
    "OrderItem",
    "OrderStatus"
]
