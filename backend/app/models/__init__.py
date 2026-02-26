"""
Модели базы данных для FoodTech
Все модели наследуются от SQLModel для использования с FastAPI
"""
from .user import User
from .category import Category
from .product import Product, ProductSize, ProductModifierGroup, ProductModifier
from .order import Order, OrderItem, OrderStatus
from .iiko_settings import IikoSettings
from .sync_log import SyncLog
from .loyalty import LoyaltyStatus, LoyaltyRule, LoyaltyTransaction
from .promo_code import PromoCode
from .iiko_webhook_event import IikoWebhookEvent
from .company import Company, Branch, DeliveryZone
from .customer import Customer
from .action import Action
from .nps import NpsReview
from .mailing import Mailing
from .story import Story
from .funnel import Funnel

__all__ = [
    "User",
    "Category",
    "Product",
    "ProductSize",
    "ProductModifierGroup",
    "ProductModifier",
    "Order",
    "OrderItem",
    "OrderStatus",
    "IikoSettings",
    "SyncLog",
    "LoyaltyStatus",
    "LoyaltyRule",
    "LoyaltyTransaction",
    "PromoCode",
    "IikoWebhookEvent",
    "Company",
    "Branch",
    "DeliveryZone",
    "Customer",
    "Action",
    "NpsReview",
    "Mailing",
    "Story",
    "Funnel"
]
