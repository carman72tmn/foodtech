"""
Модели базы данных для FoodTech
Все модели наследуются от SQLModel для использования с FastAPI
"""
from .user import User
from .category import Category
from .product import Product
from .order import Order, OrderItem, OrderStatus
from .iiko_settings import IikoSettings
from .sync_log import SyncLog
from .loyalty import LoyaltyStatus, LoyaltyRule, LoyaltyTransaction
from .promo_code import PromoCode
from .iiko_webhook_event import IikoWebhookEvent

__all__ = [
    "User",
    "Category",
    "Product",
    "Order",
    "OrderItem",
    "OrderStatus",
    "IikoSettings",
    "SyncLog",
    "LoyaltyStatus",
    "LoyaltyRule",
    "LoyaltyTransaction",
    "PromoCode",
    "IikoWebhookEvent"
]
