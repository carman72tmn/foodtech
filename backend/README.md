# Backend API - DovezU

> **FastAPI Backend** для системы управления доставкой DovezU

## 📋 Обзор

Backend API предоставляет RESTful интерфейс для:
- Управления меню и товарами
- Обработки заказов
- Интеграции с iiko Cloud
- Программы лояльности
- Telegram Bot взаимодействия

## 🛠️ Технологии

- **FastAPI 0.109+** - Современный веб-фреймворк
- **SQLAlchemy 2.0+** - ORM для работы с БД
- **PostgreSQL 15+** - База данных
- **Redis** - Кэширование и очереди
- **Pydantic** - Валидация данных
- **asyncpg** - Async драйвер PostgreSQL
- **httpx** - HTTP клиент для iiko API

## 📁 Структура проекта

```
backend/
├── app/
│   ├── api/
│   │   ├── endpoints/
│   │   │   ├── __init__.py
│   │   │   ├── menu.py           # Endpoints для меню
│   │   │   ├── orders.py         # Endpoints для заказов
│   │   │   └── loyalty.py        # Endpoints лояльности
│   │   └── __init__.py
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py             # Конфигурация (pydantic-settings)
│   │   └── database.py           # Подключение к БД
│   ├── models/
│   │   ├── __init__.py
│   │   ├── menu.py               # Модели меню
│   │   ├── order.py              # Модели заказов
│   │   └── loyalty.py            # Модели лояльности
│   ├── services/
│   │   ├── __init__.py
│   │   ├── iiko_cloud.py         # iiko Cloud integration
│   │   ├── menu_service.py       # Бизнес-логика меню
│   │   ├── menu_sync.py          # Синхронизация меню
│   │   ├── order_service.py      # Бизнес-логика заказов
│   │   ├── order_monitor.py      # Мониторинг заказов
│   │   └── loyalty.py            # Логика лояльности
│   └── __init__.py
├── main.py                        # Точка входа приложения
├── requirements.txt               # Python зависимости
├── .env.example                   # Пример конфигурации
└── README.md                      # Этот файл
```

## ⚙️ Установка

### Вариант 1: Локальная разработка

```bash
# Перейти в директорию backend
cd backend

# Создать виртуальное окружение
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# или
venv\Scripts\activate  # Windows

# Установить зависимости
pip install -r requirements.txt

# Настроить окружение
cp .env.example .env
nano .env  # Заполнить переменные

# Запустить сервер
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Вариант 2: Docker

```bash
# Из корневой директории проекта
docker compose up backend -d

# Просмотр логов
docker compose logs -f backend
```

## 🔧 Конфигурация

### Файл .env

```env
# Название проекта
PROJECT_NAME="DovezU Food Delivery"
API_V1_STR="/api/v1"

# База данных PostgreSQL
POSTGRES_SERVER=localhost  # или postgres для Docker
POSTGRES_USER=foodtech
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=foodtech_db

# iiko Cloud Integration
IIKO_API_LOGIN=your_iiko_api_key
IIKO_API_BASE_URL=https://api-ru.iiko.services

# Redis (опционально)
REDIS_HOST=localhost  # или redis для Docker
REDIS_PORT=6379

# Telegram Bot (для уведомлений)
BOT_TOKEN=your_telegram_bot_token
```

### Переменные окружения

| Переменная | Описание | По умолчанию |
|-----------|----------|--------------|
| `PROJECT_NAME` | Название проекта | DovezU Food Delivery |
| `API_V1_STR` | Префикс API | /api/v1 |
| `POSTGRES_SERVER` | Хост PostgreSQL | localhost |
| `POSTGRES_USER` | Пользователь БД | foodtech |
| `POSTGRES_PASSWORD` | Пароль БД | - |
| `POSTGRES_DB` | Имя БД | foodtech_db |
| `IIKO_API_LOGIN` | API ключ iiko | - |
| `IIKO_API_BASE_URL` | URL iiko API | https://api-ru.iiko.services |

## 🚀 Запуск

### Development режим

```bash
# С автоперезагрузкой
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Или через Python
python -m uvicorn main:app --reload
```

### Production режим

```bash
# С несколькими worker'ами
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4

# Или через Gunicorn
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

## 📚 API Документация

После запуска сервера доступна автоматическая документация:

- **Swagger UI**: http://localhost:8000/api/v1/docs
- **ReDoc**: http://localhost:8000/api/v1/redoc
- **OpenAPI JSON**: http://localhost:8000/api/v1/openapi.json

## 🔌 API Endpoints

### Health Check

```bash
GET /health
# Response: {"status": "ok"}
```

### Меню

```bash
# Получить все меню
GET /api/v1/menu
Query params: ?category=pizza&available=true

# Получить товар по ID
GET /api/v1/menu/{product_id}

# Синхронизировать с iiko
POST /api/v1/menu/sync
Body: {"organization_id": "uuid"}

# Получить категории
GET /api/v1/menu/categories
```

### Заказы

```bash
# Создать заказ
POST /api/v1/orders
Body: {
  "user_id": 1,
  "items": [
    {"product_id": 10, "quantity": 2},
    {"product_id": 15, "quantity": 1}
  ],
  "address": "ул. Ленина, 1",
  "phone": "+79001234567",
  "comment": "Домофон не работает"
}

# Получить список заказов
GET /api/v1/orders
Query params: ?status=new&user_id=1

# Получить заказ по ID
GET /api/v1/orders/{order_id}

# Обновить статус заказа
PUT /api/v1/orders/{order_id}/status
Body: {"status": "confirmed"}

# Отменить заказ
DELETE /api/v1/orders/{order_id}
```

### Лояльность

```bash
# Получить карту лояльности по телефону
GET /api/v1/loyalty/{phone}

# Создать карту
POST /api/v1/loyalty
Body: {"phone": "+79001234567", "name": "Иван Иванов"}

# Начислить баллы
POST /api/v1/loyalty/earn
Body: {"phone": "+79001234567", "points": 100, "order_id": 123}

# Списать баллы
POST /api/v1/loyalty/spend
Body: {"phone": "+79001234567", "points": 50, "order_id": 124}

# История операций
GET /api/v1/loyalty/{phone}/history
```

## 🔄 Интеграция с iiko Cloud

### Основные методы

```python
from app.services.iiko_cloud import IikoCloudService

iiko = IikoCloudService()

# Авторизация
token = await iiko.get_access_token()

# Получить номенклатуру (меню)
menu = await iiko.get_nomenclature(organization_id)

# Создать заказ
order = await iiko.create_order({
    "organizationId": "uuid",
    "terminalId": "uuid",
    "items": [...],
    "customer": {...}
})

# Получить статус заказа
status = await iiko.get_order_status(order_id)
```

### Синхронизация меню

```python
from app.services.menu_sync import MenuSyncService

sync = MenuSyncService()

# Синхронизировать меню
result = await sync.sync_menu(organization_id)
# Returns: {"synced": 150, "added": 10, "updated": 140}
```

## 🔔 Мониторинг заказов

Backend автоматически мониторит активные заказы каждые 30 секунд:

```python
# В main.py автоматически запускается
async def monitor_orders():
    monitor = OrderMonitor()
    while True:
        await monitor.check_active_orders()
        await asyncio.sleep(30)
```

При изменении статуса заказа автоматически отправляется уведомление в Telegram Bot.

## 🧪 Тестирование

### Запуск тестов

```bash
# Установить dev зависимости
pip install pytest pytest-asyncio httpx

# Запустить тесты
pytest

# С coverage
pytest --cov=app tests/
```

### Пример теста

```python
import pytest
from httpx import AsyncClient
from main import app

@pytest.mark.asyncio
async def test_get_menu():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.get("/api/v1/menu")
    assert response.status_code == 200
    assert "items" in response.json()
```

## 🐛 Отладка

### Логирование

```python
import logging

logger = logging.getLogger(__name__)

# В коде
logger.info("Order created", extra={"order_id": order.id})
logger.error("Failed to sync menu", exc_info=True)
```

### Просмотр логов

```bash
# Docker
docker compose logs -f backend

# Native
tail -f /var/log/foodtech/backend.log

# Или stdout при запуске через uvicorn
```

## 🔒 Безопасность

### Валидация данных

Все входные данные валидируются через Pydantic models:

```python
from pydantic import BaseModel, validator
from typing import List

class OrderCreate(BaseModel):
    user_id: int
    items: List[OrderItem]
    address: str
    phone: str

    @validator('phone')
    def validate_phone(cls, v):
        if not v.startswith('+7'):
            raise ValueError('Phone must start with +7')
        return v
```

### Rate Limiting

```python
from fastapi import HTTPException
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.get("/api/v1/menu")
@limiter.limit("100/minute")
async def get_menu():
    ...
```

## 📊 Производительность

### Оптимизация запросов

```python
# Используйте selectinload для eager loading
from sqlalchemy.orm import selectinload

orders = await session.execute(
    select(Order)
    .options(selectinload(Order.items))
    .where(Order.status == "active")
)
```

### Кэширование

```python
from app.core.cache import cache

@cache(expire=300)  # 5 минут
async def get_menu():
    return await db.fetch_menu()
```

## 🚨 Решение проблем

### Ошибка подключения к БД

```bash
# Проверить PostgreSQL
systemctl status postgresql

# Проверить параметры в .env
grep POSTGRES backend/.env

# Проверить подключение
psql -U foodtech -d foodtech_db -h localhost
```

### iiko API не отвечает

```bash
# Проверить API ключ
curl -X POST https://api-ru.iiko.services/api/1/access_token \
  -H "Content-Type: application/json" \
  -d '{"apiLogin": "your_api_key"}'

# Проверить логи
docker compose logs backend | grep iiko
```

### Ошибка импорта модулей

```bash
# Убедитесь что все __init__.py файлы существуют
find app -type d -exec touch {}/__init__.py \;

# Переустановите зависимости
pip install -r requirements.txt --force-reinstall
```

## 📝 Разработка

### Добавление нового endpoint

1. Создайте модель данных в `app/models/`
2. Добавьте endpoint в `app/api/endpoints/`
3. Зарегистрируйте router в `main.py`
4. Добавьте тесты

```python
# app/api/endpoints/new_feature.py
from fastapi import APIRouter, Depends
from app.models.new_feature import NewFeature

router = APIRouter()

@router.get("/new-feature")
async def get_new_feature():
    return {"message": "New feature"}

# main.py
from app.api.endpoints import new_feature
app.include_router(
    new_feature.router,
    prefix=f"{settings.API_V1_STR}/new-feature",
    tags=["new-feature"]
)
```

### Миграции базы данных

```bash
# Создать миграцию (через Alembic, если настроен)
alembic revision --autogenerate -m "Add new table"

# Применить миграции
alembic upgrade head

# Откатить
alembic downgrade -1
```

## 🔗 Полезные ссылки

- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org)
- [Pydantic Documentation](https://docs.pydantic.dev)
- [iiko Cloud API](https://api-ru.iiko.services/docs)
- [Главная документация проекта](../README.md)

## 📞 Поддержка

Для вопросов и проблем:
- Создайте Issue на GitHub
- См. [FIXES_README.md](../FIXES_README.md)
- Проверьте [AI_INSTRUCTIONS.md](../AI_INSTRUCTIONS.md)

---

*Последнее обновление: 2026-02-19*
