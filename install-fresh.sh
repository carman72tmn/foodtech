#!/bin/bash
# install-fresh.sh — Полная переустановка проекта (Hard Reset)
# ВНИМАНИЕ: УДАЛЯЕТ ВСЁ И СТАВИТ ЗАНОВО!

if [ "$EUID" -ne 0 ]; then
    echo "❌ Запустите с sudo!"
    exit 1
fi

PROJECT_DIR="/opt/foodtech/admin"
LOG_FILE="/opt/foodtech/install.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "🧨 ЗАПУСК ПОЛНОЙ ПЕРЕУСТАНОВКИ..."
date

# 1. Остановка сервисов
echo "🛑 [1/8] Остановка сервисов..."
systemctl stop nginx php8.2-fpm apache2 2>/dev/null || true
systemctl disable apache2 2>/dev/null || true

# 2. Очистка старой версии (оставляем .env)
echo "🗑 [2/8] Удаление старых файлов (кроме .env)..."
if [ -d "$PROJECT_DIR" ]; then
    cp "$PROJECT_DIR/.env" "/opt/foodtech/.env.bak" 2>/dev/null || true
    rm -rf "$PROJECT_DIR"
fi
mkdir -p "$PROJECT_DIR"

# 3. Клонирование
echo "⬇️ [3/8] Клонирование репозитория..."
git clone https://github.com/dovezukatmn/foodtech.git /opt/foodtech/src
cp -r /opt/foodtech/src/admin/* "$PROJECT_DIR/"
rm -rf /opt/foodtech/src
cd "$PROJECT_DIR"

# 4. Настройка .env (Принудительно HTTPS)
echo "📝 [4/8] Настройка .env..."
if [ -f "/opt/foodtech/.env.bak" ]; then
    cp "/opt/foodtech/.env.bak" "$PROJECT_DIR/.env"
else
    cp .env.example .env
fi

# Жесткие правки .env для Production
sed -i 's|^APP_URL=.*|APP_URL=https://vezuroll.ru|g' .env
sed -i 's|^ASSET_URL=.*|ASSET_URL=https://vezuroll.ru|g' .env
sed -i 's|^APP_ENV=.*|APP_ENV=production|g' .env
sed -i 's|^APP_DEBUG=.*|APP_DEBUG=false|g' .env

# Убедимся что эти параметры есть
grep -q "APP_URL=" .env || echo "APP_URL=https://vezuroll.ru" >> .env
grep -q "ASSET_URL=" .env || echo "ASSET_URL=https://vezuroll.ru" >> .env

# 5. Установка зависимостей
echo "📦 [5/8] Установка зависимостей..."
composer install --no-dev --optimize-autoloader --no-interaction
npm install
npm run build

# 6. База данных и Laravel
echo "🗄 [6/8] Миграции и настройка Laravel..."
php artisan key:generate --force
php artisan migrate:fresh --seed --force # Сброс БД и сидирование
php artisan storage:link

php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

# 7. Настройка прав
echo "🔑 [7/8] Настройка прав доступа..."
chown -R www-data:www-data storage bootstrap/cache public
chmod -R 777 storage bootstrap/cache

# 8. Nginx (Сразу правильный конфиг)
echo "🌐 [8/8] Настройка Nginx..."
cat > /etc/nginx/sites-available/foodtech << 'NGINX_CONF'
server {
    listen 80;
    server_name _;
    root /opt/foodtech/admin/public;
    index index.php index.html;
    client_max_body_size 50M;

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript image/svg+xml;

    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 7d;
        access_log off;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        
        # HTTPS FORCE
        fastcgi_param HTTPS on;
        fastcgi_param HTTP_SCHEME https;
    }

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
}
NGINX_CONF

ln -sf /etc/nginx/sites-available/foodtech /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Финальный перезапуск
systemctl restart php8.2-fpm
systemctl restart nginx

echo "✅ ПЕРЕУСТАНОВКА ЗАВЕРШЕНА!"
echo "👉 Админка: https://vezuroll.ru/admin"
echo "👉 Логин: admin@foodtech.ru / password"
