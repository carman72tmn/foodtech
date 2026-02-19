# DovezU - Food Delivery Management System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Laravel](https://img.shields.io/badge/Laravel-12.x-red.svg)](https://laravel.com)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109-green.svg)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://python.org)

Полнофункциональная система управления доставкой еды с интеграцией iiko Cloud, админ-панелью на Laravel/Filament и Telegram-ботом.

## 📋 Содержание

- [Обзор проекта](#обзор-проекта)
- [Архитектура системы](#архитектура-системы)
- [Быстрый старт](#быстрый-старт)
- [Требования](#требования)
- [Установка](#установка)
- [Документация](#документация)
- [Структура проекта](#структура-проекта)
- [Технологии](#технологии)

## 🎯 Обзор проекта

**DovezU** — это комплексное решение для управления доставкой еды, которое включает:

### 🎛️ Компоненты системы

1. **Admin Panel** (Laravel + Filament 3)
   - Управление меню, заказами, пользователями
   - Интеграция с iiko Cloud
   - Система лояльности
   - Статистика и аналитика

2. **Backend API** (FastAPI + PostgreSQL)
   - RESTful API для мобильных приложений
   - Синхронизация с iiko
   - Обработка заказов в реальном времени
   - Система мониторинга заказов

3. **Telegram Bot** (aiogram 3)
   - Прием заказов через Telegram
   - Уведомления о статусе заказа
   - Программа лояльности

## 🏗️ Архитектура системы

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Admin Panel    │────▶│   Backend API    │────▶│   PostgreSQL    │
│  (Laravel)      │     │   (FastAPI)      │     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │    ▲
                               │    │
                               ▼    │
                        ┌─────────────────┐
                        │  iiko Cloud API │
                        │  (External)     │
                        └─────────────────┘
                               ▲    │
                               │    ▼
┌─────────────────┐     ┌──────────────────┐
│  Telegram Bot   │────▶│   Backend API    │
│  (aiogram)      │     │                  │
└─────────────────┘     └──────────────────┘
```

Подробнее см. [ARCHITECTURE.md](ARCHITECTURE.md)

## ⚡ Быстрый старт

### Автоматическая установка (Рекомендуется)

```bash
# Скачайте проект
git clone https://github.com/carman72tmn/dovezu.git
cd dovezu

# Настройте .env файл
cp .env.production .env
nano .env  # Заполните ваши данные

# Запустите автоустановку
sudo bash auto-install.sh
```

### Ручная установка

См. подробную инструкцию в [SETUP_GUIDE.md](SETUP_GUIDE.md)

## 💻 Требования

### Для Docker-установки (Рекомендуется)
- Ubuntu 20.04+ / Debian 11+
- Docker 24.0+
- Docker Compose 2.0+
- 2 CPU / 4 GB RAM (минимум)
- 20 GB свободного места

### Для нативной установки
- Ubuntu 20.04+ / Debian 11+
- PHP 8.2+
- Python 3.11+
- PostgreSQL 15+
- Redis 7+
- Nginx/Apache
- Node.js 20+

## 📦 Установка

### Вариант 1: Docker (Рекомендуется)

```bash
# 1. Клонируйте репозиторий
git clone https://github.com/carman72tmn/dovezu.git
cd dovezu

# 2. Настройте окружение
cp .env.production .env
nano .env

# 3. Запустите автоустановку
sudo bash auto-install.sh
```

### Вариант 2: Нативная установка

```bash
# Для VPS без Docker (OpenVZ/LXC)
sudo bash install-native.sh
```

### Вариант 3: Свежая установка с нуля

```bash
# Полная переустановка всех компонентов
sudo bash install-fresh.sh
```

## 📚 Документация

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Подробная инструкция по установке и настройке
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Архитектура системы и компонентов
- **[AI_INSTRUCTIONS.md](AI_INSTRUCTIONS.md)** - Инструкции для AI-ассистентов (Google Antigravity)
- **[FIXES_README.md](FIXES_README.md)** - Исправления и решение проблем
- **[admin/README.md](admin/README.md)** - Документация админ-панели
- **[backend/README.md](backend/README.md)** - Документация Backend API
- **[bot/README.md](bot/README.md)** - Документация Telegram-бота

## 📁 Структура проекта

```
dovezu/
├── admin/                  # Laravel Admin Panel (Filament 3)
│   ├── app/               # Приложение Laravel
│   ├── config/            # Конфигурация
│   ├── database/          # Миграции и сидеры
│   ├── resources/         # Views, CSS, JS
│   └── README.md          # Документация админки
│
├── backend/               # FastAPI Backend
│   ├── app/
│   │   ├── api/          # API endpoints
│   │   ├── core/         # Конфигурация и БД
│   │   ├── models/       # Модели данных
│   │   └── services/     # Бизнес-логика
│   ├── main.py           # Точка входа
│   ├── requirements.txt  # Зависимости Python
│   └── README.md         # Документация backend
│
├── bot/                   # Telegram Bot
│   ├── handlers/         # Обработчики команд
│   ├── main.py          # Точка входа бота
│   ├── requirements.txt # Зависимости
│   └── README.md        # Документация бота
│
├── auto-install.sh       # Автоматическая установка
├── install.sh            # Установка с Docker
├── install-native.sh     # Установка без Docker
├── install-fresh.sh      # Свежая установка
├── .env.production       # Пример конфигурации
├── SETUP_GUIDE.md        # Руководство по настройке
├── ARCHITECTURE.md       # Архитектура системы
├── AI_INSTRUCTIONS.md    # Инструкции для AI
└── README.md             # Этот файл
```

## 🛠️ Технологии

### Backend
- **FastAPI** - Современный веб-фреймворк
- **SQLAlchemy** - ORM для работы с БД
- **PostgreSQL** - Основная база данных
- **Redis** - Кэширование и очереди
- **Pydantic** - Валидация данных

### Admin Panel
- **Laravel 12** - PHP фреймворк
- **Filament 3** - Панель администратора
- **Livewire** - Реактивные компоненты
- **AdminLTE 3** - UI тема

### Telegram Bot
- **aiogram 3** - Асинхронный фреймворк для Telegram Bot API
- **httpx** - HTTP клиент

### DevOps
- **Docker** & **Docker Compose** - Контейнеризация
- **Nginx** - Веб-сервер
- **Certbot** - SSL сертификаты

## 🚀 Разработка

### Запуск в режиме разработки

```bash
# Admin Panel
cd admin
composer install
npm install
php artisan serve
npm run dev

# Backend API
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Telegram Bot
cd bot
pip install -r requirements.txt
python main.py
```

### Тестирование

```bash
# Laravel тесты
cd admin
php artisan test

# Backend тесты
cd backend
pytest
```

## 🔧 Конфигурация

### Основные переменные окружения

```env
# База данных
POSTGRES_USER=foodtech
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=foodtech_db

# iiko Cloud
IIKO_API_LOGIN=your_api_key
IIKO_API_BASE_URL=https://api-ru.iiko.services

# Telegram Bot
BOT_TOKEN=your_telegram_bot_token

# Домен
DOMAIN=your-domain.ru
```

Полный список переменных см. в `.env.production`

## 📞 Поддержка

### Полезные команды

```bash
# Просмотр логов Docker
docker compose logs -f

# Перезапуск сервисов
docker compose restart

# Очистка кэша Laravel
docker compose exec admin php artisan cache:clear

# Миграции БД
docker compose exec admin php artisan migrate

# Консоль Laravel
docker compose exec admin php artisan tinker
```

### Решение проблем

См. [FIXES_README.md](FIXES_README.md) для решения типичных проблем.

## 🤝 Вклад в проект

Мы приветствуем вклад в проект! Пожалуйста:

1. Форкните репозиторий
2. Создайте ветку для новой функции (`git checkout -b feature/AmazingFeature`)
3. Закоммитьте изменения (`git commit -m 'Add some AmazingFeature'`)
4. Запушьте в ветку (`git push origin feature/AmazingFeature`)
5. Откройте Pull Request

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. файл [LICENSE](LICENSE) для подробностей.

## 👥 Авторы

- **Команда DovezU** - *Начальная работа*

## 🙏 Благодарности

- [Laravel](https://laravel.com) - PHP фреймворк
- [Filament](https://filamentphp.com) - Админ-панель
- [FastAPI](https://fastapi.tiangolo.com) - Backend фреймворк
- [aiogram](https://docs.aiogram.dev) - Telegram Bot фреймворк
- [iiko](https://iiko.ru) - Система автоматизации ресторанов

---

**Примечание**: Это активно развиваемый проект. Следите за обновлениями!

## 🔗 Полезные ссылки

- [Документация iiko Cloud API](https://api-ru.iiko.services/docs)
- [Документация Telegram Bot API](https://core.telegram.org/bots/api)
- [Документация Laravel](https://laravel.com/docs)
- [Документация FastAPI](https://fastapi.tiangolo.com)
