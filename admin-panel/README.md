# Инструкция по установке Laravel Admin Panel

## Структура

Админ-панель построена на:
- Laravel 12
- Filament 3 (современная панель администрирования)
- PostgreSQL (общая БД с Backend)

## Быстрая установка

После установки PHP, Composer и PostgreSQL (см. `/instructions/01_server_setup.md`):

```bash
cd /home/runner/work/foodtech/foodtech/admin-panel

# Установка зависимостей
composer install --no-dev --optimize-autoloader

# Настройка окружения
cp .env.example .env
php artisan key:generate

# Редактируем .env и указываем данные БД

# Миграции (БД уже создана через Backend)
php artisan migrate

# Создание админ-пользователя
php artisan make:filament-user

# Публикация ассетов Filament
php artisan filament:assets

# Оптимизация для продакшена
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

## Доступ

После настройки Nginx (см. `/instructions/04_admin_deployment.md`):

- URL: https://admin.yourdomain.com
- Логин: созданный через `make:filament-user`

## Основные возможности

1. **Управление категориями** - добавление/редактирование категорий
2. **Управление товарами** - управление меню
3. **Просмотр заказов** - мониторинг заказов в реальном времени
4. **Синхронизация с iiko** - кнопка для синхронизации номенклатуры
5. **Управление пользователями** - роли и права доступа

## Кастомизация

Ресурсы Filament находятся в `app/Filament/Resources/`
Страницы Filament в `app/Filament/Pages/`

Для создания нового ресурса:
```bash
php artisan make:filament-resource Order --generate
```
