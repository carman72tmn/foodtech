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

## ⚡ Быстрый старт

1. Скопируйте проект: `git clone https://github.com/carman72tmn/foodtech.git`
2. Настройте файлы `.env` в папках `admin` и `backend`.
3. Установите зависимости и запустите сервисы (подробнее см. в разделах ниже).

## 💻 Требования

### Нативная установка

- Ubuntu 20.04+ / Debian 11+
- PHP 8.2+
- Python 3.11+
- PostgreSQL 15+
- Redis 7+
- Nginx/Apache
- Node.js 20+

## 📦 Установка

### Backend API

```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python init_db_manual.py # Инициализация БД
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Admin Panel

```bash
cd admin
composer install
npm install
php artisan migrate
php artisan key:generate
php artisan serve
```

### Telegram Bot

```bash
cd bot
pip install -r requirements.txt
python main.py
```

## 📁 Структура проекта

```
foodtech/
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

### DevOps

- **Nginx** - Веб-сервер
- **Certbot** - SSL сертификаты

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

---

**Примечание**: Это проект с нативной установкой. Docker не поддерживается.
