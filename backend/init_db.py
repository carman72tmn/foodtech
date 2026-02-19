"""
Скрипт для инициализации базы данных
Создает все таблицы на основе моделей SQLModel
"""
from sqlmodel import SQLModel
from app.core.database import engine
from app.models import User, Category, Product, Order, OrderItem


def init_db():
    """Создание всех таблиц в базе данных"""
    print("Создание таблиц в базе данных...")
    SQLModel.metadata.create_all(engine)
    print("✓ Все таблицы созданы успешно!")


if __name__ == "__main__":
    init_db()
