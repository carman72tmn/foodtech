#!/bin/bash

###############################################################################
# FoodTech Auto-Installer: Настройка базы данных (Этап 2)
# Описание: Создание базы данных PostgreSQL и пользователя для FoodTech
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

# Параметры базы данных (по умолчанию)
DB_NAME="foodtech_db"
DB_USER="foodtech_user"
DB_PASSWORD=""

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

# Проверка установки PostgreSQL
check_postgresql() {
    if ! command -v psql &> /dev/null; then
        print_error "PostgreSQL не установлен. Сначала выполните скрипт 01_prepare_server.sh"
        exit 1
    fi

    if ! systemctl is-active --quiet postgresql; then
        print_error "Служба PostgreSQL не запущена"
        print_info "Попытка запуска..."
        systemctl start postgresql
        print_success "PostgreSQL запущен"
    fi

    print_success "PostgreSQL доступен"
}

# Генерация безопасного пароля
generate_password() {
    # Генерируем случайный пароль длиной 32 символа
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
}

# Запрос параметров у пользователя
prompt_database_config() {
    print_subheader "Конфигурация базы данных"

    echo ""
    read -p "Имя базы данных [$DB_NAME]: " input_db_name
    DB_NAME=${input_db_name:-$DB_NAME}

    read -p "Имя пользователя базы данных [$DB_USER]: " input_db_user
    DB_USER=${input_db_user:-$DB_USER}

    echo ""
    print_info "Выберите способ создания пароля:"
    echo "  1) Сгенерировать автоматически (рекомендуется)"
    echo "  2) Ввести свой пароль"
    read -p "Ваш выбор (1/2) [1]: " password_choice
    password_choice=${password_choice:-1}

    if [ "$password_choice" == "1" ]; then
        generate_password
        print_success "Пароль сгенерирован автоматически"
    else
        while true; do
            read -sp "Введите пароль: " DB_PASSWORD
            echo ""
            read -sp "Повторите пароль: " DB_PASSWORD_CONFIRM
            echo ""

            if [ "$DB_PASSWORD" == "$DB_PASSWORD_CONFIRM" ]; then
                if [ ${#DB_PASSWORD} -lt 8 ]; then
                    print_error "Пароль должен быть не менее 8 символов"
                else
                    break
                fi
            else
                print_error "Пароли не совпадают. Попробуйте снова."
            fi
        done
    fi

    echo ""
    print_info "Конфигурация базы данных:"
    echo "  • База данных: $DB_NAME"
    echo "  • Пользователь: $DB_USER"
    echo "  • Пароль: [скрыт]"
    echo ""

    log "Database config: DB=$DB_NAME, USER=$DB_USER"
}

# Проверка существования базы данных
check_database_exists() {
    if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
        return 0
    else
        return 1
    fi
}

# Проверка существования пользователя
check_user_exists() {
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
        return 0
    else
        return 1
    fi
}

# Создание пользователя базы данных
create_database_user() {
    print_subheader "Создание пользователя базы данных"

    if check_user_exists; then
        print_info "Пользователь '$DB_USER' уже существует"

        read -p "Обновить пароль для существующего пользователя? (y/n): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Обновление пароля..."
            sudo -u postgres psql -c "ALTER USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" > /dev/null
            print_success "Пароль обновлен"
            log "Password updated for user: $DB_USER"
        else
            print_info "Пароль не изменен"
        fi
    else
        print_info "Создание пользователя '$DB_USER'..."
        sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" > /dev/null
        print_success "Пользователь создан"
        log "User created: $DB_USER"
    fi
}

# Создание базы данных
create_database() {
    print_subheader "Создание базы данных"

    if check_database_exists; then
        print_info "База данных '$DB_NAME' уже существует"

        read -p "Пересоздать базу данных? ВНИМАНИЕ: Все данные будут удалены! (y/n): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Удаление существующей базы данных..."
            sudo -u postgres psql -c "DROP DATABASE $DB_NAME;" > /dev/null
            print_success "Старая база удалена"
            log "Database dropped: $DB_NAME"

            print_info "Создание новой базы данных..."
            sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" > /dev/null
            print_success "База данных создана"
            log "Database created: $DB_NAME"
        else
            print_info "База данных не изменена"
        fi
    else
        print_info "Создание базы данных '$DB_NAME'..."
        sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" > /dev/null
        print_success "База данных создана"
        log "Database created: $DB_NAME"
    fi
}

# Настройка прав доступа
setup_permissions() {
    print_subheader "Настройка прав доступа"

    print_info "Назначение прав пользователю '$DB_USER'..."
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" > /dev/null
    print_success "Права назначены"

    # Подключаемся к БД и даем права на схему public
    sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL ON SCHEMA public TO $DB_USER;" > /dev/null
    print_success "Права на схему public назначены"

    log "Permissions granted to user: $DB_USER"
}

# Проверка подключения к базе данных
test_connection() {
    print_subheader "Проверка подключения к базе данных"

    print_info "Тестирование подключения..."

    if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" > /dev/null 2>&1; then
        print_success "Подключение к базе данных успешно!"
        log "Database connection test successful"
    else
        print_error "Не удалось подключиться к базе данных"
        log "Database connection test failed"
        exit 1
    fi
}

# Сохранение конфигурации
save_config() {
    print_subheader "Сохранение конфигурации"

    # Создаем директорию для конфигурации
    CONFIG_DIR="/opt/foodtech/config"
    mkdir -p "$CONFIG_DIR"

    # Сохраняем параметры подключения
    CONFIG_FILE="$CONFIG_DIR/database.conf"
    cat > "$CONFIG_FILE" <<EOF
# Конфигурация базы данных FoodTech
# Создано: $(date '+%Y-%m-%d %H:%M:%S')

DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_HOST=localhost
DB_PORT=5432

# Строка подключения для приложений
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
EOF

    # Защищаем файл конфигурации
    chmod 600 "$CONFIG_FILE"
    chown root:root "$CONFIG_FILE"

    print_success "Конфигурация сохранена в: $CONFIG_FILE"
    print_info "ВАЖНО: Сохраните эти учетные данные в безопасном месте!"

    echo ""
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║          ПАРАМЕТРЫ ПОДКЛЮЧЕНИЯ К БД                    ║${NC}"
    echo -e "${YELLOW}╠════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║${NC} База данных:  $DB_NAME"
    echo -e "${YELLOW}║${NC} Пользователь: $DB_USER"
    echo -e "${YELLOW}║${NC} Пароль:       $DB_PASSWORD"
    echo -e "${YELLOW}║${NC} Хост:         localhost"
    echo -e "${YELLOW}║${NC} Порт:         5432"
    echo -e "${YELLOW}╠════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║${NC} DATABASE_URL:"
    echo -e "${YELLOW}║${NC} postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""

    log "Configuration saved to: $CONFIG_FILE"
}

# Настройка автоматического бэкапа
setup_backup() {
    print_subheader "Настройка автоматического бэкапа (опционально)"

    read -p "Настроить автоматический ежедневный бэкап базы данных? (y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        BACKUP_DIR="/var/backups/foodtech"
        mkdir -p "$BACKUP_DIR"

        # Создаем скрипт бэкапа
        BACKUP_SCRIPT="/usr/local/bin/foodtech-db-backup.sh"
        cat > "$BACKUP_SCRIPT" <<EOF
#!/bin/bash
# Автоматический бэкап базы данных FoodTech

BACKUP_DIR="$BACKUP_DIR"
DB_NAME="$DB_NAME"
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="\$BACKUP_DIR/foodtech_db_\$TIMESTAMP.sql"

# Создание бэкапа
sudo -u postgres pg_dump "\$DB_NAME" > "\$BACKUP_FILE"

# Сжатие бэкапа
gzip "\$BACKUP_FILE"

# Удаление старых бэкапов (старше 30 дней)
find "\$BACKUP_DIR" -name "foodtech_db_*.sql.gz" -mtime +30 -delete

echo "Backup completed: \$BACKUP_FILE.gz"
EOF

        chmod +x "$BACKUP_SCRIPT"
        print_success "Скрипт бэкапа создан: $BACKUP_SCRIPT"

        # Добавляем задание в cron
        CRON_JOB="0 2 * * * $BACKUP_SCRIPT >> /var/log/foodtech-backup.log 2>&1"
        (crontab -l 2>/dev/null | grep -v "$BACKUP_SCRIPT"; echo "$CRON_JOB") | crontab -
        print_success "Ежедневный бэкап настроен (каждый день в 02:00)"
        print_info "Бэкапы будут сохраняться в: $BACKUP_DIR"
        print_info "Старые бэкапы (>30 дней) будут автоматически удаляться"

        log "Automatic backup configured"
    else
        print_info "Автоматический бэкап не настроен"
        log "Automatic backup skipped"
    fi
}

# Основная функция
main() {
    print_header "FoodTech Auto-Installer: Настройка базы данных (Этап 2/6)"

    log "=== Database setup started ==="

    # Проверки
    check_root
    check_postgresql

    # Конфигурация
    prompt_database_config

    # Создание БД и пользователя
    create_database_user
    create_database
    setup_permissions

    # Проверка
    test_connection

    # Сохранение конфигурации
    save_config

    # Бэкап
    setup_backup

    # Финал
    print_header "Этап 2: Завершено"
    print_success "База данных настроена и готова к использованию!"
    echo ""
    print_info "Следующий шаг: Выполните скрипт 03_deploy_backend.sh"
    echo ""

    log "=== Database setup completed successfully ==="
}

# Запуск
main
