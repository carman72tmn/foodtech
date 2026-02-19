#!/bin/bash

###############################################################################
# FoodTech Auto-Installer: Подготовка сервера (Этап 1)
# Описание: Установка всех необходимых компонентов на чистый Ubuntu сервер
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

# Проверка версии Ubuntu
check_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" ]]; then
            print_error "Этот скрипт предназначен только для Ubuntu"
            exit 1
        fi

        VERSION_MAJOR=$(echo "$VERSION_ID" | cut -d'.' -f1)
        if [[ "$VERSION_MAJOR" -lt 22 ]]; then
            print_error "Требуется Ubuntu 22.04 LTS или новее. Текущая версия: $VERSION_ID"
            exit 1
        fi

        print_success "Обнаружена совместимая версия: Ubuntu $VERSION_ID"
        log "Ubuntu version check passed: $VERSION_ID"
    else
        print_error "Не удалось определить версию операционной системы"
        exit 1
    fi
}

# Обновление системы
update_system() {
    print_subheader "Обновление системы"

    print_info "Обновление списков пакетов..."
    apt update > /dev/null 2>&1
    print_success "Списки пакетов обновлены"
    log "apt update completed"

    print_info "Установка обновлений (это может занять несколько минут)..."
    DEBIAN_FRONTEND=noninteractive apt upgrade -y > /dev/null 2>&1
    print_success "Система обновлена"
    log "apt upgrade completed"

    print_info "Установка основных утилит..."
    apt install -y software-properties-common curl git wget zip unzip build-essential > /dev/null 2>&1
    print_success "Основные утилиты установлены"
    log "Basic utilities installed"
}

# Установка Python
install_python() {
    print_subheader "Установка Python 3.11+"

    PYTHON_VERSION=$(python3 --version 2>&1 | grep -oP '(?<=Python )\d+\.\d+' || echo "0.0")

    print_info "Установка Python 3 и необходимых компонентов..."
    apt install -y python3 python3-pip python3-venv python3-dev > /dev/null 2>&1
    print_success "Python установлен"

    INSTALLED_VERSION=$(python3 --version 2>&1 | grep -oP '(?<=Python )\d+\.\d+')
    print_success "Установленная версия Python: $INSTALLED_VERSION"
    log "Python $INSTALLED_VERSION installed"

    print_info "Обновление pip..."
    python3 -m pip install --upgrade pip > /dev/null 2>&1
    print_success "pip обновлен"
    log "pip upgraded"
}

# Установка PHP
install_php() {
    print_subheader "Установка PHP 8.2"

    print_info "Добавление репозитория Ondrej для PHP..."
    add-apt-repository ppa:ondrej/php -y > /dev/null 2>&1
    apt update > /dev/null 2>&1
    print_success "Репозиторий добавлен"
    log "Ondrej PHP repository added"

    print_info "Установка PHP 8.2 и расширений (это может занять несколько минут)..."
    apt install -y php8.2 php8.2-fpm php8.2-cli php8.2-common \
        php8.2-pgsql php8.2-curl php8.2-xml php8.2-mbstring \
        php8.2-zip php8.2-bcmath php8.2-gd php8.2-intl > /dev/null 2>&1
    print_success "PHP 8.2 установлен"

    PHP_VERSION=$(php -v | head -n1)
    print_success "Установленная версия: $PHP_VERSION"
    log "PHP 8.2 installed: $PHP_VERSION"
}

# Установка Composer
install_composer() {
    print_subheader "Установка Composer"

    if command -v composer &> /dev/null; then
        COMPOSER_VERSION=$(composer --version 2>&1 | grep -oP '(?<=Composer version )\S+')
        print_success "Composer уже установлен: $COMPOSER_VERSION"
        return 0
    fi

    print_info "Скачивание установщика Composer..."
    curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
    print_success "Установщик скачан"

    print_info "Установка Composer глобально..."
    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer > /dev/null 2>&1
    rm /tmp/composer-setup.php
    print_success "Composer установлен"

    COMPOSER_VERSION=$(composer --version 2>&1 | grep -oP '(?<=Composer version )\S+')
    print_success "Установленная версия: Composer $COMPOSER_VERSION"
    log "Composer installed: $COMPOSER_VERSION"
}

# Установка PostgreSQL
install_postgresql() {
    print_subheader "Установка PostgreSQL"

    print_info "Установка PostgreSQL 15..."
    apt install -y postgresql postgresql-contrib > /dev/null 2>&1
    print_success "PostgreSQL установлен"

    print_info "Запуск службы PostgreSQL..."
    systemctl start postgresql
    systemctl enable postgresql > /dev/null 2>&1
    print_success "PostgreSQL запущен и добавлен в автозагрузку"

    PSQL_VERSION=$(sudo -u postgres psql --version | grep -oP '(?<=psql \(PostgreSQL\) )\S+')
    print_success "Установленная версия: PostgreSQL $PSQL_VERSION"
    log "PostgreSQL installed: $PSQL_VERSION"
}

# Установка Nginx
install_nginx() {
    print_subheader "Установка Nginx"

    print_info "Установка Nginx..."
    apt install -y nginx > /dev/null 2>&1
    print_success "Nginx установлен"

    print_info "Запуск службы Nginx..."
    systemctl start nginx
    systemctl enable nginx > /dev/null 2>&1
    print_success "Nginx запущен и добавлен в автозагрузку"

    NGINX_VERSION=$(nginx -v 2>&1 | grep -oP '(?<=nginx/)\S+')
    print_success "Установленная версия: nginx $NGINX_VERSION"
    log "Nginx installed: $NGINX_VERSION"
}

# Установка Redis (опционально)
install_redis() {
    print_subheader "Установка Redis (опционально)"

    read -p "Установить Redis для кэширования? (y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Установка Redis..."
        apt install -y redis-server > /dev/null 2>&1
        print_success "Redis установлен"

        print_info "Запуск службы Redis..."
        systemctl start redis-server
        systemctl enable redis-server > /dev/null 2>&1
        print_success "Redis запущен и добавлен в автозагрузку"

        REDIS_VERSION=$(redis-cli --version | grep -oP '(?<=redis-cli )\S+')
        print_success "Установленная версия: Redis $REDIS_VERSION"
        log "Redis installed: $REDIS_VERSION"
    else
        print_info "Установка Redis пропущена"
        log "Redis installation skipped"
    fi
}

# Настройка Firewall
setup_firewall() {
    print_subheader "Настройка Firewall (UFW)"

    print_info "Разрешение SSH (OpenSSH)..."
    ufw allow OpenSSH > /dev/null 2>&1
    print_success "SSH разрешен"

    print_info "Разрешение HTTP и HTTPS (Nginx Full)..."
    ufw allow 'Nginx Full' > /dev/null 2>&1
    print_success "HTTP и HTTPS разрешены"

    print_info "Включение firewall..."
    echo "y" | ufw enable > /dev/null 2>&1
    print_success "Firewall включен"

    log "Firewall configured"
}

# Установка Certbot
install_certbot() {
    print_subheader "Установка Certbot для SSL"

    print_info "Установка Certbot и плагина для Nginx..."
    apt install -y certbot python3-certbot-nginx > /dev/null 2>&1
    print_success "Certbot установлен"

    print_info "SSL сертификаты будут настроены позже, после настройки доменов"
    log "Certbot installed"
}

# Установка nano (если не установлен)
install_nano() {
    print_subheader "Проверка текстового редактора nano"

    if command -v nano &> /dev/null; then
        print_success "Редактор nano уже установлен"
    else
        print_info "Установка редактора nano..."
        apt install -y nano > /dev/null 2>&1
        print_success "Редактор nano установлен"
        log "nano editor installed"
    fi
}

# Проверка установки всех компонентов
verify_installation() {
    print_header "Проверка установленных компонентов"

    local ALL_OK=true

    # Python
    if command -v python3 &> /dev/null; then
        PYTHON_VER=$(python3 --version 2>&1 | grep -oP '(?<=Python )\S+')
        print_success "Python $PYTHON_VER"
    else
        print_error "Python не установлен"
        ALL_OK=false
    fi

    # PHP
    if command -v php &> /dev/null; then
        PHP_VER=$(php -v | head -n1 | grep -oP '(?<=PHP )\S+')
        print_success "PHP $PHP_VER"
    else
        print_error "PHP не установлен"
        ALL_OK=false
    fi

    # Composer
    if command -v composer &> /dev/null; then
        COMPOSER_VER=$(composer --version 2>&1 | grep -oP '(?<=Composer version )\S+')
        print_success "Composer $COMPOSER_VER"
    else
        print_error "Composer не установлен"
        ALL_OK=false
    fi

    # PostgreSQL
    if command -v psql &> /dev/null; then
        PSQL_VER=$(sudo -u postgres psql --version | grep -oP '(?<=psql \(PostgreSQL\) )\S+')
        print_success "PostgreSQL $PSQL_VER"
    else
        print_error "PostgreSQL не установлен"
        ALL_OK=false
    fi

    # Nginx
    if command -v nginx &> /dev/null; then
        NGINX_VER=$(nginx -v 2>&1 | grep -oP '(?<=nginx/)\S+')
        print_success "Nginx $NGINX_VER"
    else
        print_error "Nginx не установлен"
        ALL_OK=false
    fi

    # Redis (опционально)
    if command -v redis-cli &> /dev/null; then
        REDIS_VER=$(redis-cli --version | grep -oP '(?<=redis-cli )\S+')
        print_success "Redis $REDIS_VER (опционально)"
    fi

    # Certbot
    if command -v certbot &> /dev/null; then
        print_success "Certbot установлен"
    else
        print_error "Certbot не установлен"
        ALL_OK=false
    fi

    # nano
    if command -v nano &> /dev/null; then
        print_success "nano редактор установлен"
    else
        print_error "nano не установлен"
        ALL_OK=false
    fi

    echo ""
    if [ "$ALL_OK" = true ]; then
        print_success "Все компоненты установлены успешно!"
        return 0
    else
        print_error "Некоторые компоненты не были установлены"
        return 1
    fi
}

# Основная функция
main() {
    print_header "FoodTech Auto-Installer: Подготовка сервера (Этап 1/6)"

    # Создание файла логов
    touch "$LOG_FILE"
    log "=== Installation started ==="

    # Проверки
    check_root
    check_ubuntu_version

    # Установка компонентов
    update_system
    install_python
    install_php
    install_composer
    install_postgresql
    install_nginx
    install_redis
    setup_firewall
    install_certbot
    install_nano

    # Проверка
    verify_installation

    # Финал
    print_header "Этап 1: Завершено"
    print_success "Сервер подготовлен для развертывания FoodTech!"
    echo ""
    print_info "Логи установки сохранены в: $LOG_FILE"
    echo ""
    print_info "Следующий шаг: Выполните скрипт 02_setup_database.sh"
    echo ""

    log "=== Installation completed successfully ==="
}

# Запуск
main
