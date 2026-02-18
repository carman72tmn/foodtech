#!/bin/bash
# =============================================
# FoodTech Admin — Установка БЕЗ Docker
# Для Ubuntu 24.04 (OpenVZ / LXC VPS)
# =============================================
# Запуск: sudo bash install-native.sh
# =============================================

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

PROJECT_DIR="/opt/foodtech/admin"
DOMAIN="_"

echo ""
echo -e "${PURPLE}╔══════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║  🚀 FoodTech Admin — Установка (Native)  ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════╝${NC}"
echo ""

# === Проверка root ===
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Запустите от root: sudo bash install-native.sh${NC}"
    exit 1
fi

# === 1. Обновление системы ===
echo -e "${BLUE}[1/9]${NC} Обновление системы..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq
echo -e "${GREEN}  ✅ Система обновлена${NC}"

# === 2. Установка утилит ===
echo -e "${BLUE}[2/9]${NC} Установка утилит..."
apt-get install -y -qq \
    software-properties-common \
    curl wget git unzip zip \
    htop nano acl \
    ca-certificates gnupg lsb-release
echo -e "${GREEN}  ✅ Утилиты установлены${NC}"

# === 3. PHP 8.2 ===
echo -e "${BLUE}[3/9]${NC} Установка PHP 8.2..."
add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1 || true
apt-get update -qq
apt-get install -y -qq \
    php8.2-fpm \
    php8.2-pgsql \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-curl \
    php8.2-zip \
    php8.2-gd \
    php8.2-intl \
    php8.2-bcmath \
    php8.2-redis \
    php8.2-opcache \
    php8.2-readline

# Настройка PHP для production
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 50M/' /etc/php/8.2/fpm/php.ini
sed -i 's/post_max_size = .*/post_max_size = 50M/' /etc/php/8.2/fpm/php.ini
sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php/8.2/fpm/php.ini
sed -i 's/max_execution_time = .*/max_execution_time = 120/' /etc/php/8.2/fpm/php.ini

systemctl enable php8.2-fpm
systemctl restart php8.2-fpm
echo -e "${GREEN}  ✅ PHP 8.2 установлен${NC}"

# === 4. Composer ===
echo -e "${BLUE}[4/9]${NC} Установка Composer..."
if ! command -v composer &> /dev/null; then
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi
echo -e "${GREEN}  ✅ Composer установлен${NC}"

# === 5. Node.js 20 ===
echo -e "${BLUE}[5/9]${NC} Установка Node.js 20..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
    apt-get install -y -qq nodejs
fi
echo -e "${GREEN}  ✅ Node.js $(node -v) установлен${NC}"

# === 6. PostgreSQL 15 ===
echo -e "${BLUE}[6/9]${NC} Установка PostgreSQL..."
if ! command -v psql &> /dev/null; then
    apt-get install -y -qq postgresql postgresql-contrib
fi
systemctl enable postgresql
systemctl start postgresql

# Загружаем пароль из .env
if [ -f "/opt/foodtech/.env" ]; then
    source /opt/foodtech/.env 2>/dev/null || true
fi
DB_NAME="${POSTGRES_DB:-foodtech_db}"
DB_USER="${POSTGRES_USER:-foodtech}"
DB_PASS="${POSTGRES_PASSWORD:-foodtech_secret}"

# Создаём БД и пользователя
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"

echo -e "${GREEN}  ✅ PostgreSQL: БД '${DB_NAME}', пользователь '${DB_USER}'${NC}"

# === 7. Redis ===
echo -e "${BLUE}[7/9]${NC} Установка Redis..."
apt-get install -y -qq redis-server
systemctl enable redis-server
systemctl start redis-server
echo -e "${GREEN}  ✅ Redis установлен${NC}"

# === 8. Nginx ===
echo -e "${BLUE}[8/9]${NC} Установка и настройка Nginx..."
apt-get install -y -qq nginx

# Nginx конфигурация
cat > /etc/nginx/sites-available/foodtech << 'NGINX_CONF'
server {
    listen 80;
    server_name _;

    root /opt/foodtech/admin/public;
    index index.php index.html;

    client_max_body_size 50M;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript image/svg+xml;

    # Статика — кэширование
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 7d;
        access_log off;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # PHP
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_read_timeout 300;
    }

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # Скрытые файлы
    location ~ /\. {
        deny all;
    }
}
NGINX_CONF

# Активируем сайт
ln -sf /etc/nginx/sites-available/foodtech /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t && systemctl enable nginx && systemctl restart nginx
echo -e "${GREEN}  ✅ Nginx настроен${NC}"

# === 9. Laravel — установка ===
echo -e "${BLUE}[9/9]${NC} Настройка Laravel..."
cd "$PROJECT_DIR"

# .env для Laravel
cat > "$PROJECT_DIR/.env" << ENV_FILE
APP_NAME=FoodTech
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=${DB_NAME}
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASS}

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

FILESYSTEM_DISK=local
ENV_FILE

# Composer install
echo -e "${BLUE}  Composer install...${NC}"
cd "$PROJECT_DIR"
composer install --no-dev --optimize-autoloader --no-interaction 2>&1 | tail -3

# NPM
echo -e "${BLUE}  NPM install + build...${NC}"
npm install --silent 2>&1 | tail -1
npm run build 2>&1 | tail -3 || true

# Laravel setup
php artisan key:generate --force --no-interaction
php artisan migrate --force --no-interaction 2>&1 | tail -5
php artisan storage:link 2>/dev/null || true

# Сидеры
php artisan db:seed --class=RoleSeeder --force 2>&1 || true
php artisan db:seed --class=AppSettingSeeder --force 2>&1 || true

# Кэширование для production
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Права
chown -R www-data:www-data "$PROJECT_DIR/storage" "$PROJECT_DIR/bootstrap/cache"
chmod -R 775 "$PROJECT_DIR/storage" "$PROJECT_DIR/bootstrap/cache"

echo -e "${GREEN}  ✅ Laravel настроен${NC}"

# === ИТОГ ===
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
echo -e "${PURPLE}╔══════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   🎉 Установка завершена!                ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}  🌐 Админ-панель: ${NC}http://${SERVER_IP}/admin"
echo -e "${GREEN}  📧 Логин:        ${NC}admin@foodtech.ru"
echo -e "${GREEN}  🔑 Пароль:       ${NC}password"
echo ""
echo -e "${YELLOW}  ⚠️  ОБЯЗАТЕЛЬНО:${NC}"
echo -e "    1. Смените пароль admin@foodtech.ru через панель"
echo -e "    2. Для SSL: apt install certbot python3-certbot-nginx"
echo -e "       certbot --nginx -d ваш-домен.ru"
echo ""
echo -e "${BLUE}  📖 Полезные команды:${NC}"
echo -e "    systemctl status php8.2-fpm nginx postgresql redis-server"
echo -e "    cd $PROJECT_DIR && php artisan tinker"
echo -e "    tail -f $PROJECT_DIR/storage/logs/laravel.log"
echo ""
