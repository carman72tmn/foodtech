#!/bin/bash
# migrate-adminlte.sh — Миграция на AdminLTE
# Запуск: sudo bash migrate-adminlte.sh

if [ "$EUID" -ne 0 ]; then
    echo "❌ Запустите с sudo!"
    exit 1
fi

PROJECT_DIR="/opt/foodtech/admin"
LOG_FILE="/opt/foodtech/adminlte_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "🚀 ЗАПУСК МИГРАЦИИ НА ADMINLTE..."
date

cd "$PROJECT_DIR"

# 1. Установка пакета (если еще нет)
echo "📦 [1/5] Установка AdminLTE и UI..."
sudo -u www-data composer require jeroennoten/laravel-adminlte --no-interaction
sudo -u www-data composer require laravel/ui --no-interaction

# 2. Публикация ассетов
echo "publish [2/5] Публикация ресурсов..."
php artisan adminlte:install --force --type=full --no-interaction
php artisan ui bootstrap --auth --no-interaction

# 3. Сборка фронтенда
echo "🎨 [3/5] Сборка стилей..."
npm install
npm run build

# 4. Очистка кэша
echo "🧹 [4/5] Очистка..."
php artisan optimize:clear
php artisan view:cache
php artisan config:cache

# 5. Перезапуск FPM
echo "♻️  [5/5] Перезапуск..."
systemctl restart php8.2-fpm nginx

echo "✅ ГОТОВО! AdminLTE установлен."
