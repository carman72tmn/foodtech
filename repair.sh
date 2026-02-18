#!/bin/bash
# repair.sh — Полное исправление и диагностика

if [ "$EUID" -ne 0 ]; then
    echo "❌ Запустите с sudo!"
    exit 1
fi

echo "🔧 ЗАПУСК ПОЛНОГО РЕМОНТА..."

# 1. Отключаем Apache2 (главный враг Nginx)
echo "🛑 [1/5] Проверка конфликтов портов..."
if systemctl is-active --quiet apache2; then
    echo "   -> Обнаружен Apache2! Останавливаем..."
    systemctl stop apache2
    systemctl disable apache2
    echo "   -> Apache2 отключен."
fi

# 2. Исправляем стили
echo "🎨 [2/5] Исправление стилей (копирование theme.css)..."
# Создаем директорию, если нет
mkdir -p /opt/foodtech/admin/public/css
# Копируем исходник темы в public как обычный CSS
cp /opt/foodtech/admin/resources/css/filament/admin/theme.css /opt/foodtech/admin/public/css/admin-theme.css
echo "   -> Стили скопированы в public/css/admin-theme.css"

# 3. Принудительный HTTPS в Nginx
echo "lock [3/5] Настройка Nginx (HTTPS Force)..."
CONF="/etc/nginx/sites-available/foodtech"
if [ -f "$CONF" ]; then
    if ! grep -q "fastcgi_param HTTPS on;" "$CONF"; then
        sed -i '/fastcgi_param PATH_INFO/a \        fastcgi_param HTTPS on;' "$CONF"
        echo "   -> Добавлен параметр HTTPS on"
    else
        echo "   -> Параметр уже есть."
    fi
else
    echo "⚠️  Конфиг Nginx не найден по пути $CONF"
fi

# 4. Исправление прав
echo "🔑 [4/5] Исправление прав доступа..."
cd /opt/foodtech/admin
chown -R www-data:www-data storage bootstrap/cache public
chmod -R 777 storage bootstrap/cache # Максимальные права для тестов
echo "   -> Права исправлены."

# 5. Очистка и перезапуск
echo "♻️  [5/5] Перезапуск сервисов..."
php artisan optimize:clear
php artisan view:cache # Важно для blade
systemctl restart php8.2-fpm
systemctl restart nginx

echo "✅ РЕМОНТ ЗАВЕРШЕН!"
echo "👉 Пробуйте: https://vezuroll.ru/admin"
