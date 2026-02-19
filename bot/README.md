# Telegram Bot - DovezU

> **Telegram Bot** для приема заказов и взаимодействия с клиентами

## 📋 Обзор

Telegram Bot предоставляет удобный интерфейс для клиентов:

- 🍕 Просмотр меню
- 🛒 Добавление товаров в корзину
- 📦 Оформление заказов
- 🔔 Уведомления о статусе заказа
- 🎁 Управление бонусами лояльности
- 📍 Выбор адреса доставки

## 🛠️ Технологии

- **aiogram 3.17+** - Асинхронный фреймворк для Telegram Bot API
- **httpx** - HTTP клиент для Backend API
- **pydantic** - Валидация данных
- **redis** (опционально) - Хранение состояний FSM

## 📁 Структура проекта

```
bot/
├── handlers/
│   ├── __init__.py
│   ├── start.py          # Команда /start и приветствие
│   ├── menu.py           # Просмотр меню
│   ├── cart.py           # Корзина покупок
│   ├── orders.py         # Заказы и история
│   └── loyalty.py        # Программа лояльности
├── keyboards/
│   ├── __init__.py
│   ├── inline.py         # Inline клавиатуры
│   └── reply.py          # Reply клавиатуры
├── middlewares/
│   ├── __init__.py
│   └── auth.py           # Middleware аутентификации
├── services/
│   ├── __init__.py
│   └── api_client.py     # Клиент для Backend API
├── states/
│   ├── __init__.py
│   └── order.py          # FSM состояния заказа
├── utils/
│   ├── __init__.py
│   └── formatters.py     # Форматирование сообщений
├── config.py             # Конфигурация бота
├── main.py               # Точка входа
├── requirements.txt      # Python зависимости
└── README.md            # Этот файл
```

## ⚙️ Установка

# Перейти в директорию bot

cd bot

# Создать виртуальное окружение

python3 -m venv venv
source venv/bin/activate # Linux/Mac

# или

venv\Scripts\activate # Windows

# Установить зависимости

pip install -r requirements.txt

# Настроить окружение

export BOT_TOKEN="your_telegram_bot_token"
export BACKEND_API_URL="http://localhost:8000/api/v1"

# Запустить бота

python main.py

## 🔧 Конфигурация

### Переменные окружения

```env
# Telegram Bot Token (получить у @BotFather)
BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz

# Backend API URL
BACKEND_API_URL=http://localhost:8000/api/v1

# Redis (опционально, для FSM storage)
REDIS_HOST=localhost
REDIS_PORT=6379
```

### Создание бота в Telegram

1. Откройте Telegram и найдите [@BotFather](https://t.me/BotFather)
2. Отправьте команду `/newbot`
3. Следуйте инструкциям:

   ```
   BotFather: Alright, a new bot. How are we going to call it?
   Вы: DovezU Food Bot

   BotFather: Good. Now let's choose a username for your bot.
   Вы: dovezu_food_bot

   BotFather: Done! Here's your token:
   123456789:ABCdefGHIjklMNOpqrsTUVwxyz
   ```

4. Скопируйте токен и используйте в `BOT_TOKEN`

### Настройка команд бота

Отправьте @BotFather команду `/setcommands` и укажите:

```
start - 🏠 Главное меню
menu - 🍕 Посмотреть меню
cart - 🛒 Моя корзина
orders - 📦 Мои заказы
loyalty - 🎁 Бонусная программа
help - ❓ Помощь
```

## 🚀 Запуск

### Development режим

```bash
# С подробными логами
python main.py --log-level DEBUG

# Или обычный запуск
python main.py
```

### Production режим

Рекомендуется использовать systemd или PM2 для управления процессом бота на сервере.

## 💬 Команды бота

### Основные команды

| Команда    | Описание                   | Пример     |
| ---------- | -------------------------- | ---------- |
| `/start`   | Запуск бота и главное меню | `/start`   |
| `/menu`    | Просмотр меню              | `/menu`    |
| `/cart`    | Корзина покупок            | `/cart`    |
| `/orders`  | История заказов            | `/orders`  |
| `/loyalty` | Бонусная программа         | `/loyalty` |
| `/help`    | Справка                    | `/help`    |

### Workflow заказа

1. **Пользователь**: `/start`
   - Бот отправляет приветствие и главное меню

2. **Пользователь**: Нажимает "🍕 Меню"
   - Бот показывает категории меню

3. **Пользователь**: Выбирает категорию (например, "Пицца")
   - Бот показывает список товаров с ценами

4. **Пользователь**: Нажимает на товар
   - Бот показывает детали и кнопку "Добавить в корзину"

5. **Пользователь**: Добавляет товары в корзину
   - Бот подтверждает добавление

6. **Пользователь**: "🛒 Корзина" → "Оформить заказ"
   - Бот запрашивает адрес доставки

7. **Пользователь**: Вводит адрес
   - Бот запрашивает телефон (или использует Telegram)

8. **Пользователь**: Подтверждает заказ
   - Бот создает заказ через Backend API
   - Отправляет подтверждение с номером заказа

9. **Автоматически**: Бот отправляет уведомления при изменении статуса
   - "Заказ принят"
   - "Заказ готовится"
   - "Курьер в пути"
   - "Заказ доставлен"

## 🔌 Интеграция с Backend API

### API Client

```python
from services.api_client import APIClient

client = APIClient(base_url="http://localhost:8000/api/v1")

# Получить меню
menu = await client.get_menu()

# Создать заказ
order = await client.create_order({
    "user_id": telegram_user_id,
    "items": [
        {"product_id": 1, "quantity": 2}
    ],
    "address": "ул. Ленина, 1",
    "phone": "+79001234567"
})

# Получить статус заказа
status = await client.get_order_status(order_id)
```

### Обработка ошибок

```python
try:
    order = await client.create_order(data)
except APIError as e:
    await message.answer(f"Ошибка: {e.message}")
except NetworkError:
    await message.answer("Проблемы с сетью, попробуйте позже")
```

## 🎨 Клавиатуры

### Inline клавиатуры

```python
from keyboards.inline import get_menu_keyboard

# Клавиатура категорий
keyboard = get_menu_keyboard(categories)
await message.answer("Выберите категорию:", reply_markup=keyboard)

# Клавиатура товаров
keyboard = get_products_keyboard(products)
await message.answer("Выберите товар:", reply_markup=keyboard)
```

### Reply клавиатуры

```python
from keyboards.reply import main_menu_keyboard

# Главное меню
await message.answer(
    "Главное меню:",
    reply_markup=main_menu_keyboard()
)
```

## 🔄 FSM (Finite State Machine)

### Состояния заказа

```python
from states.order import OrderStates

class OrderStates(StatesGroup):
    selecting_category = State()
    selecting_product = State()
    entering_quantity = State()
    entering_address = State()
    entering_phone = State()
    confirming_order = State()
```

### Использование

```python
from aiogram.fsm.context import FSMContext

@router.message(OrderStates.entering_address)
async def process_address(message: Message, state: FSMContext):
    await state.update_data(address=message.text)
    await state.set_state(OrderStates.entering_phone)
    await message.answer("Введите номер телефона:")
```

## 🔔 Уведомления

### Отправка уведомлений

```python
from aiogram import Bot

async def send_order_notification(
    bot: Bot,
    user_id: int,
    order_id: int,
    status: str
):
    messages = {
        "confirmed": "✅ Ваш заказ #{} принят и передан в обработку!",
        "cooking": "👨‍🍳 Ваш заказ #{} готовится",
        "on_way": "🚗 Курьер выехал с вашим заказом #{}!",
        "delivered": "🎉 Заказ #{} доставлен! Приятного аппетита!"
    }

    text = messages.get(status, "Статус заказа #{} изменен")
    await bot.send_message(user_id, text.format(order_id))
```

### Webhook для уведомлений

Backend API может вызывать webhook для отправки уведомлений:

```python
# В Backend API
async def notify_order_status_changed(order_id: int, user_telegram_id: int, status: str):
    async with httpx.AsyncClient() as client:
        await client.post(
            f"http://bot:8001/webhook/order-status",
            json={
                "order_id": order_id,
                "user_id": user_telegram_id,
                "status": status
            }
        )
```

## 🧪 Тестирование

### Запуск тестов

```bash
# Установить dev зависимости
pip install pytest pytest-asyncio

# Запустить тесты
pytest

# С coverage
pytest --cov=. tests/
```

### Пример теста

```python
import pytest
from aiogram.methods import SendMessage
from handlers.start import start_handler

@pytest.mark.asyncio
async def test_start_command():
    message = MockMessage(text="/start")
    result = await start_handler(message)

    assert isinstance(result, SendMessage)
    assert "Добро пожаловать" in result.text
```

## 🐛 Отладка

### Логирование

```python
import logging

logger = logging.getLogger(__name__)

# В handlers
logger.info("User started bot", extra={"user_id": message.from_user.id})
logger.error("Failed to create order", exc_info=True)
```

### Просмотр логов

```bash
# Docker
docker compose logs -f bot

# Native
tail -f /var/log/foodtech/bot.log

# Или stdout при запуске через python
```

### Отладочный режим

```python
# config.py
DEBUG = True  # Включить подробные логи

# main.py
logging.basicConfig(level=logging.DEBUG if DEBUG else logging.INFO)
```

## 🔒 Безопасность

### Валидация пользователей

```python
from middlewares.auth import AuthMiddleware

# Проверка пользователя перед обработкой
router.message.middleware(AuthMiddleware())

# В middleware
class AuthMiddleware(BaseMiddleware):
    async def __call__(self, handler, event, data):
        user = event.from_user

        # Проверка блокировки
        if await is_user_blocked(user.id):
            await event.answer("Вы заблокированы")
            return

        return await handler(event, data)
```

### Защита от спама

```python
from aiogram.utils.chat_action import ChatActionMiddleware

# Автоматическая отправка "typing..."
router.message.middleware(ChatActionMiddleware())

# Rate limiting
from utils.rate_limiter import rate_limit

@rate_limit(max_calls=5, period=60)  # 5 вызовов в минуту
async def some_handler(message: Message):
    ...
```

## 📊 Производительность

### Оптимизация

```python
# Кэширование меню
from functools import lru_cache

@lru_cache(maxsize=1)
async def get_cached_menu():
    return await api_client.get_menu()

# Batch операции
async def send_bulk_notifications(users, message):
    tasks = [bot.send_message(user_id, message) for user_id in users]
    await asyncio.gather(*tasks, return_exceptions=True)
```

## 🚨 Решение проблем

### Бот не отвечает

```bash
# Проверить токен
curl https://api.telegram.org/bot<TOKEN>/getMe

# Проверить запущен ли бот
ps aux | grep python | grep main.py

# Проверить логи
docker compose logs bot
```

### Ошибка подключения к Backend API

```bash
# Проверить доступность API
curl http://localhost:8000/health

# Проверить переменные окружения
echo $BACKEND_API_URL

# Проверить сеть в Docker
docker compose exec bot ping backend
```

### Сообщения не отправляются

```bash
# Проверить права бота
# Убедитесь что бот не заблокирован пользователем

# Проверить лимиты Telegram API
# Max 30 сообщений в секунду
# Max 20 сообщений в минуту одному пользователю
```

## 📝 Разработка

### Добавление нового handler

```python
# handlers/new_feature.py
from aiogram import Router
from aiogram.types import Message
from aiogram.filters import Command

router = Router()

@router.message(Command("new"))
async def new_feature_handler(message: Message):
    await message.answer("New feature!")

# main.py
from handlers import new_feature

dp.include_router(new_feature.router)
```

### Добавление новой клавиатуры

```python
# keyboards/inline.py
from aiogram.types import InlineKeyboardMarkup, InlineKeyboardButton

def get_new_keyboard():
    return InlineKeyboardMarkup(inline_keyboard=[
        [
            InlineKeyboardButton(text="Кнопка 1", callback_data="btn1"),
            InlineKeyboardButton(text="Кнопка 2", callback_data="btn2")
        ]
    ])
```

## 🎨 Форматирование сообщений

### HTML форматирование

```python
await message.answer(
    "<b>Жирный текст</b>\n"
    "<i>Курсив</i>\n"
    "<code>Код</code>\n"
    '<a href="https://example.com">Ссылка</a>',
    parse_mode="HTML"
)
```

### Markdown форматирование

```python
await message.answer(
    "*Жирный текст*\n"
    "_Курсив_\n"
    "`Код`\n"
    "[Ссылка](https://example.com)",
    parse_mode="Markdown"
)
```

## 🔗 Полезные ссылки

- [aiogram Documentation](https://docs.aiogram.dev/en/latest/)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [BotFather](https://t.me/BotFather)
- [Главная документация проекта](../README.md)

## 📞 Поддержка

Для вопросов и проблем:

- Создайте Issue на GitHub
- См. [FIXES_README.md](../FIXES_README.md)
- Проверьте [AI_INSTRUCTIONS.md](../AI_INSTRUCTIONS.md)

---

_Последнее обновление: 2026-02-19_
