"""
Модели Клиентов (Покупателей) для системы Лояльности
"""
from typing import Optional
from datetime import datetime, date
from decimal import Decimal
from sqlmodel import Field, SQLModel, Relationship
from sqlalchemy import Numeric


class Customer(SQLModel, table=True):
    """
    Таблица клиентов для профилей, истории заказов и программы лояльности
    """
    __tablename__ = "customers"

    id: Optional[int] = Field(default=None, primary_key=True)
    
    # Основные данные
    phone: str = Field(max_length=20, unique=True, index=True, description="Телефон (основной идентификатор)")
    telegram_id: Optional[int] = Field(default=None, index=True, description="ID в Telegram если авторизован через бота")
    name: Optional[str] = Field(default=None, max_length=255)
    email: Optional[str] = Field(default=None, max_length=255)
    birthday: Optional[date] = Field(default=None, description="Дата рождения")
    
    # Данные лояльности
    loyalty_status_id: Optional[int] = Field(
        default=None, foreign_key="loyalty_statuses.id",
        description="Текущий статус лояльности (если есть)"
    )
    bonus_points: Decimal = Field(
        sa_type=Numeric(10, 2), default=0,
        description="Текущий баланс бонусных баллов (для оплаты)"
    )
    status_points: int = Field(
        default=0,
        description="Статусные баллы (для достижения уровней)"
    )
    
    # Данные из iiko (при необходимости)
    iiko_customer_id: Optional[str] = Field(default=None, max_length=100, index=True)
    
    # Статистика и сегментация
    total_orders_count: int = Field(default=0, description="Общее количество заказов")
    total_orders_amount: Decimal = Field(
        sa_type=Numeric(12, 2), default=0,
        description="Общая сумма выкупленных заказов"
    )
    last_order_date: Optional[datetime] = Field(default=None, description="Дата последнего заказа")
    
    is_blocked: bool = Field(default=False, description="Заблокирован ли клиент")
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
