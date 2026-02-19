import asyncio
import os
import sys

# Добавляем текущую директорию в путь поиска модулей
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import init_db
from app.models.menu import Category, Product, Modifier, ModifierGroup
from app.models.order import Order, OrderItem

async def run_init():
    print("🚀 Инициализация базы данных...")
    try:
        await init_db()
        print("✅ Таблицы заказов и каталога успешно созданы!")
    except Exception as e:
        print(f"❌ Ошибка: {e}")

if __name__ == "__main__":
    asyncio.run(run_init())

