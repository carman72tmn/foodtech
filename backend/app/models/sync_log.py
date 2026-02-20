"""
Модель лога синхронизации
"""
from typing import Optional
from datetime import datetime
from sqlmodel import Field, SQLModel


class SyncLog(SQLModel, table=True):
    """Лог операций синхронизации с iiko"""
    __tablename__ = "sync_logs"

    id: Optional[int] = Field(default=None, primary_key=True)
    sync_type: str = Field(
        max_length=50, index=True,
        description="Тип синхронизации: menu, prices, stop_lists, orders"
    )
    status: str = Field(
        max_length=20, index=True,
        description="Статус: running, success, error, partial"
    )
    categories_count: int = Field(
        default=0,
        description="Количество обработанных категорий"
    )
    products_count: int = Field(
        default=0,
        description="Количество обработанных товаров"
    )
    details: Optional[str] = Field(
        default=None,
        description="Детали операции / сообщение об ошибке"
    )
    created_at: datetime = Field(default_factory=datetime.utcnow)
