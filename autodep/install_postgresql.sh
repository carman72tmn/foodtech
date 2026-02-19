#!/bin/bash

###############################################################################
# FoodTech Auto-Installer: Установка PostgreSQL
# Описание: Автоматическая установка PostgreSQL для всего сервера
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

# Проверка, установлен ли уже PostgreSQL
check_postgresql_installed() {
    if command -v psql &> /dev/null; then
        PSQL_VERSION=$(sudo -u postgres psql --version | grep -oP '(?<=psql \(PostgreSQL\) )\S+')
        print_info "PostgreSQL уже установлен: версия $PSQL_VERSION"

        read -p "Переустановить PostgreSQL? (y/n): " -n 1 -r
        echo

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Установка отменена"
            exit 0
        fi
    fi
}

# Обновление системы
update_system() {
    print_subheader "Обновление системы"

    print_info "Обновление списков пакетов..."
    apt update > /dev/null 2>&1
    print_success "Списки пакетов обновлены"
    log "apt update completed"
}

# Установка PostgreSQL
install_postgresql() {
    print_subheader "Установка PostgreSQL"

    print_info "Установка PostgreSQL 15+..."
    apt install -y postgresql postgresql-contrib > /dev/null 2>&1
    print_success "PostgreSQL установлен"
    log "PostgreSQL package installed"

    print_info "Запуск службы PostgreSQL..."
    systemctl start postgresql
    systemctl enable postgresql > /dev/null 2>&1
    print_success "PostgreSQL запущен и добавлен в автозагрузку"
    log "PostgreSQL service started and enabled"

    PSQL_VERSION=$(sudo -u postgres psql --version | grep -oP '(?<=psql \(PostgreSQL\) )\S+')
    print_success "Установленная версия: PostgreSQL $PSQL_VERSION"
    log "PostgreSQL installed: $PSQL_VERSION"
}

# Настройка PostgreSQL для удаленного доступа (опционально)
configure_remote_access() {
    print_subheader "Настройка удаленного доступа (опционально)"

    read -p "Разрешить удаленный доступ к PostgreSQL? (y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Настройка удаленного доступа..."

        # Найти конфигурационный файл PostgreSQL
        PG_VERSION=$(sudo -u postgres psql --version | grep -oP '(?<=psql \(PostgreSQL\) )\d+')
        PG_CONF_DIR="/etc/postgresql/$PG_VERSION/main"

        if [ ! -d "$PG_CONF_DIR" ]; then
            print_error "Не удалось найти конфигурационный каталог PostgreSQL"
            return
        fi

        # Резервная копия конфигураций
        cp "$PG_CONF_DIR/postgresql.conf" "$PG_CONF_DIR/postgresql.conf.backup"
        cp "$PG_CONF_DIR/pg_hba.conf" "$PG_CONF_DIR/pg_hba.conf.backup"

        # Настройка прослушивания на всех интерфейсах
        sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" "$PG_CONF_DIR/postgresql.conf"

        # Добавление правила для удаленного доступа
        echo "# Remote access for FoodTech" >> "$PG_CONF_DIR/pg_hba.conf"
        echo "host    all             all             0.0.0.0/0               md5" >> "$PG_CONF_DIR/pg_hba.conf"

        # Перезапуск PostgreSQL
        systemctl restart postgresql

        print_success "Удаленный доступ настроен"
        print_info "Не забудьте настроить firewall для порта 5432"
        log "PostgreSQL remote access configured"
    else
        print_info "Удаленный доступ не настроен"
    fi
}

# Настройка firewall
configure_firewall() {
    print_subheader "Настройка Firewall (опционально)"

    if ! command -v ufw &> /dev/null; then
        print_info "UFW не установлен, пропускаем настройку firewall"
        return
    fi

    read -p "Открыть порт PostgreSQL (5432) в firewall? (y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Открытие порта 5432..."
        ufw allow 5432/tcp > /dev/null 2>&1
        print_success "Порт 5432 открыт"
        log "PostgreSQL port opened in firewall"
    else
        print_info "Порт не открыт в firewall"
    fi
}

# Проверка установки
verify_installation() {
    print_subheader "Проверка установки"

    # Проверка службы
    if systemctl is-active --quiet postgresql; then
        print_success "Служба PostgreSQL работает"
    else
        print_error "Служба PostgreSQL не запущена"
        return 1
    fi

    # Проверка версии
    PSQL_VERSION=$(sudo -u postgres psql --version | grep -oP '(?<=psql \(PostgreSQL\) )\S+')
    print_success "PostgreSQL версия: $PSQL_VERSION"

    # Проверка подключения
    if sudo -u postgres psql -c "SELECT version();" > /dev/null 2>&1; then
        print_success "Подключение к PostgreSQL работает"
    else
        print_error "Не удалось подключиться к PostgreSQL"
        return 1
    fi

    # Информация о портах
    PSQL_PORT=$(sudo -u postgres psql -t -c "SHOW port;" | xargs)
    print_success "PostgreSQL слушает на порту: $PSQL_PORT"

    log "PostgreSQL installation verified successfully"
}

# Вывод итоговой информации
print_summary() {
    print_header "Установка PostgreSQL завершена"

    echo ""
    echo "📊 Информация о PostgreSQL:"
    echo "   Версия: $(sudo -u postgres psql --version | grep -oP '(?<=psql \(PostgreSQL\) )\S+')"
    echo "   Статус: $(systemctl is-active postgresql)"
    echo "   Автозапуск: $(systemctl is-enabled postgresql)"
    echo ""
    echo "📝 Полезные команды:"
    echo "   Проверка статуса:     sudo systemctl status postgresql"
    echo "   Перезапуск службы:    sudo systemctl restart postgresql"
    echo "   Подключение к БД:     sudo -u postgres psql"
    echo "   Просмотр логов:       sudo journalctl -u postgresql -f"
    echo ""
    echo "📖 Следующие шаги:"
    echo "   1. Используйте скрипт 02_setup_database.sh для создания базы данных"
    echo "   2. Или создайте базу данных вручную:"
    echo "      sudo -u postgres psql"
    echo "      CREATE DATABASE foodtech_db;"
    echo "      CREATE USER foodtech_user WITH PASSWORD 'your_password';"
    echo "      GRANT ALL PRIVILEGES ON DATABASE foodtech_db TO foodtech_user;"
    echo ""
    echo "🔒 Рекомендации по безопасности:"
    echo "   - Используйте сильные пароли для пользователей БД"
    echo "   - Ограничьте удаленный доступ к PostgreSQL"
    echo "   - Регулярно делайте резервные копии баз данных"
    echo ""
    echo "📁 Логи установки: $LOG_FILE"
    echo ""
}

# Основная функция
main() {
    print_header "FoodTech: Установка PostgreSQL"

    log "=== PostgreSQL Installation Started ==="

    check_root
    check_ubuntu_version
    check_postgresql_installed
    update_system
    install_postgresql
    configure_remote_access
    configure_firewall
    verify_installation
    print_summary

    log "=== PostgreSQL Installation Completed Successfully ==="
}

# Запуск
main
