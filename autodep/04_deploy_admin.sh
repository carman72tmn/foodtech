#!/bin/bash

###############################################################################
# FoodTech Auto-Installer: Развертывание Admin Panel (Этап 4)
# Описание: Установка и настройка Laravel Admin Panel
# Версия: 1.0
###############################################################################

set -e  # Прерывать выполнение при ошибках

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Параметры
INSTALL_DIR="/opt/foodtech"
ADMIN_DIR="$INSTALL_DIR/admin-panel"
CONFIG_FILE="/opt/foodtech/config/database.conf"

# Логирование
LOG_FILE="/var/log/foodtech-install.log"

# Функция для вывода заголовков
print_header() {
    echo ""
    echo -e "${BLUE}==========================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}==========================================================${NC}"
    echo ""
}

# Функция для вывода подзаголовков
print_subheader() {
    echo ""
    echo -e "${MAGENTA}----------------------------------------------------------${NC}"
    echo -e "${MAGENTA}$1${NC}"
    echo -e "${MAGENTA}----------------------------------------------------------${NC}"
}

# Функция для вывода успеха
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Функция для вывода информации
print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Функция для вывода ошибок
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Логирование
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Проверка прав root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Этот скрипт должен быть запущен с правами root (используйте sudo)"
        exit 1
    fi
}

# Проверка директории admin panel
check_admin_directory() {
    print_subheader "Проверка директории Admin Panel"

    if [ ! -d "$ADMIN_DIR" ]; then
        print_info "Директория admin-panel не найдена: $ADMIN_DIR"
        print_info "Создание базовой структуры..."

        mkdir -p "$ADMIN_DIR"
        print_success "Директория создана"
    fi

    print_success "Директория admin-panel доступна"
    log "Admin directory verified: $ADMIN_DIR"
}

# Загрузка конфигурации базы данных
load_database_config() {
    print_subheader "Загрузка конфигурации базы данных"

    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Файл конфигурации БД не найден: $CONFIG_FILE"
        print_info "Сначала выполните скрипт 02_setup_database.sh"
        exit 1
    fi

    source "$CONFIG_FILE"
    print_success "Конфигурация БД загружена"
    log "Database config loaded"
}

# Установка зависимостей Composer
install_composer_dependencies() {
    print_subheader "Установка зависимостей Composer"

    cd "$ADMIN_DIR"

    # Проверяем наличие composer.json
    if [ ! -f "composer.json" ]; then
        print_info "Файл composer.json не найден"
        print_info "Инициализация нового Laravel проекта с Filament..."

        # Создаем новый Laravel проект
        composer create-project laravel/laravel . "12.*" --prefer-dist > /dev/null 2>&1
        print_success "Laravel 12 установлен"

        # Устанавливаем Filament
        print_info "Установка Filament 3..."
        composer require filament/filament:"^3.2" -W > /dev/null 2>&1
        print_success "Filament 3 установлен"

        log "Laravel and Filament installed"
    else
        print_info "Установка зависимостей из composer.json..."
        composer install --no-dev --optimize-autoloader > /dev/null 2>&1
        print_success "Зависимости установлены"
        log "Composer dependencies installed"
    fi
}

# Настройка файла .env для Laravel
setup_laravel_env() {
    print_subheader "Настройка файла окружения Laravel"

    ENV_FILE="$ADMIN_DIR/.env"

    # Запрос домена
    echo ""
    read -p "Введите доменное имя для админ-панели (например: admin.example.com): " ADMIN_DOMAIN
    ADMIN_DOMAIN=${ADMIN_DOMAIN:-localhost}

    # Копируем пример или создаем новый
    if [ ! -f "$ENV_FILE" ]; then
        if [ -f "$ADMIN_DIR/.env.example" ]; then
            cp "$ADMIN_DIR/.env.example" "$ENV_FILE"
            print_success "Файл .env создан из примера"
        else
            touch "$ENV_FILE"
            print_success "Создан новый файл .env"
        fi
    fi

    # Генерация APP_KEY
    cd "$ADMIN_DIR"
    php artisan key:generate --force > /dev/null 2>&1
    print_success "APP_KEY сгенерирован"

    # Обновляем параметры БД в .env
    print_info "Настройка параметров базы данных..."

    sed -i "s/^DB_CONNECTION=.*/DB_CONNECTION=pgsql/" "$ENV_FILE"
    sed -i "s/^DB_HOST=.*/DB_HOST=localhost/" "$ENV_FILE"
    sed -i "s/^DB_PORT=.*/DB_PORT=5432/" "$ENV_FILE"
    sed -i "s/^DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" "$ENV_FILE"
    sed -i "s/^DB_USERNAME=.*/DB_USERNAME=$DB_USER/" "$ENV_FILE"
    sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" "$ENV_FILE"

    # Обновляем APP_URL
    sed -i "s|^APP_URL=.*|APP_URL=https://$ADMIN_DOMAIN|" "$ENV_FILE"

    # Устанавливаем режим продакшена
    sed -i "s/^APP_ENV=.*/APP_ENV=production/" "$ENV_FILE"
    sed -i "s/^APP_DEBUG=.*/APP_DEBUG=false/" "$ENV_FILE"

    print_success "Файл .env настроен"
    log "Laravel .env configured"
}

# Запуск миграций
run_migrations() {
    print_subheader "Запуск миграций базы данных"

    cd "$ADMIN_DIR"

    print_info "Выполнение миграций..."
    if php artisan migrate --force > /dev/null 2>&1; then
        print_success "Миграции выполнены"
        log "Migrations executed"
    else
        print_error "Ошибка выполнения миграций"
        print_info "Проверьте подключение к БД и попробуйте вручную: cd $ADMIN_DIR && php artisan migrate"
        log "Migration failed"
    fi
}

# Установка Filament (если еще не установлен)
setup_filament() {
    print_subheader "Настройка Filament"

    cd "$ADMIN_DIR"

    # Проверяем, установлен ли Filament
    if ! composer show | grep -q "filament/filament"; then
        print_info "Установка Filament..."
        composer require filament/filament:"^3.2" -W > /dev/null 2>&1
        print_success "Filament установлен"
    else
        print_success "Filament уже установлен"
    fi

    # Публикация ресурсов Filament
    print_info "Публикация ресурсов Filament..."
    php artisan filament:install --panels > /dev/null 2>&1 || true
    print_success "Ресурсы опубликованы"

    log "Filament configured"
}

# Создание администратора
create_admin_user() {
    print_subheader "Создание пользователя администратора"

    cd "$ADMIN_DIR"

    echo ""
    print_info "Создайте учетную запись администратора:"
    echo ""

    # Интерактивное создание пользователя
    if php artisan make:filament-user 2>&1 | tee /tmp/filament-user.log; then
        print_success "Администратор создан"
        log "Admin user created"
    else
        print_info "Если команда не работает, создайте пользователя вручную после установки"
        log "Admin user creation skipped"
    fi
}

# Настройка прав доступа
setup_permissions() {
    print_subheader "Настройка прав доступа"

    cd "$ADMIN_DIR"

    print_info "Настройка прав на директории..."
    chown -R www-data:www-data "$ADMIN_DIR"
    chmod -R 755 "$ADMIN_DIR"

    # Специальные права для storage и cache
    chmod -R 775 "$ADMIN_DIR/storage" 2>/dev/null || true
    chmod -R 775 "$ADMIN_DIR/bootstrap/cache" 2>/dev/null || true

    print_info "Защита файла .env..."
    chmod 600 "$ADMIN_DIR/.env"

    print_success "Права настроены"
    log "Permissions configured"
}

# Оптимизация Laravel
optimize_laravel() {
    print_subheader "Оптимизация Laravel"

    cd "$ADMIN_DIR"

    print_info "Кэширование конфигурации..."
    php artisan config:cache > /dev/null 2>&1
    print_success "Конфигурация кэширована"

    print_info "Кэширование маршрутов..."
    php artisan route:cache > /dev/null 2>&1
    print_success "Маршруты кэшированы"

    print_info "Кэширование представлений..."
    php artisan view:cache > /dev/null 2>&1
    print_success "Представления кэшированы"

    log "Laravel optimized"
}

# Настройка Nginx для админ-панели
setup_nginx() {
    print_subheader "Настройка Nginx"

    # Запрашиваем домен, если не задан
    if [ -z "$ADMIN_DOMAIN" ]; then
        read -p "Введите доменное имя для админ-панели: " ADMIN_DOMAIN
        ADMIN_DOMAIN=${ADMIN_DOMAIN:-localhost}
    fi

    NGINX_CONFIG="/etc/nginx/sites-available/foodtech-admin"

    print_info "Создание конфигурации Nginx..."

    cat > "$NGINX_CONFIG" <<EOF
server {
    listen 80;
    server_name $ADMIN_DOMAIN;
    root $ADMIN_DIR/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

    print_success "Конфигурация Nginx создана"

    # Активируем сайт
    print_info "Активация сайта..."
    ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/foodtech-admin
    print_success "Сайт активирован"

    # Проверяем конфигурацию Nginx
    print_info "Проверка конфигурации Nginx..."
    if nginx -t > /dev/null 2>&1; then
        print_success "Конфигурация Nginx корректна"

        print_info "Перезагрузка Nginx..."
        systemctl reload nginx
        print_success "Nginx перезагружен"
    else
        print_error "Ошибка в конфигурации Nginx"
        nginx -t
    fi

    log "Nginx configured for admin panel"
}

# Настройка SSL
setup_ssl() {
    print_subheader "Настройка SSL сертификата (опционально)"

    if [ "$ADMIN_DOMAIN" == "localhost" ] || [ "$ADMIN_DOMAIN" == "" ]; then
        print_info "SSL пропущен для localhost"
        return 0
    fi

    read -p "Настроить SSL сертификат с Let's Encrypt? (y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Получение SSL сертификата..."
        read -p "Введите email для уведомлений Let's Encrypt: " LETSENCRYPT_EMAIL

        if certbot --nginx -d "$ADMIN_DOMAIN" --non-interactive --agree-tos -m "$LETSENCRYPT_EMAIL" > /dev/null 2>&1; then
            print_success "SSL сертификат установлен"
            log "SSL certificate installed for $ADMIN_DOMAIN"
        else
            print_error "Не удалось получить SSL сертификат"
            print_info "Убедитесь, что домен указывает на этот сервер"
            log "SSL certificate installation failed"
        fi
    else
        print_info "SSL настройка пропущена"
        log "SSL setup skipped"
    fi
}

# Вывод информации о доступе
print_access_info() {
    print_subheader "Информация о доступе"

    echo ""
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║          ADMIN PANEL УСТАНОВЛЕНА                       ║${NC}"
    echo -e "${YELLOW}╠════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║${NC} URL: http://$ADMIN_DOMAIN"
    echo -e "${YELLOW}║${NC} Путь к панели: http://$ADMIN_DOMAIN/admin"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""

    print_info "Войдите используя учетные данные, созданные ранее"
}

# Основная функция
main() {
    print_header "FoodTech Auto-Installer: Развертывание Admin Panel (Этап 4/6)"

    log "=== Admin panel deployment started ==="

    # Проверки
    check_root
    check_admin_directory
    load_database_config

    # Установка
    install_composer_dependencies
    setup_laravel_env
    run_migrations
    setup_filament
    create_admin_user

    # Настройка
    setup_permissions
    optimize_laravel

    # Веб-сервер
    setup_nginx
    setup_ssl

    # Информация
    print_access_info

    # Финал
    print_header "Этап 4: Завершено"
    print_success "Admin Panel развернута!"
    echo ""
    print_info "Следующий шаг: Выполните скрипт 05_deploy_bot.sh"
    echo ""

    log "=== Admin panel deployment completed successfully ==="
}

# Запуск
main
