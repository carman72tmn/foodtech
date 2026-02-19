#!/bin/bash

###############################################################################
# FoodTech Auto-Installer: Развертывание Backend API (Этап 3)
# Описание: Установка и настройка FastAPI Backend
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
INSTALL_DIR="$HOME/foodtech"
BACKEND_DIR="$INSTALL_DIR/backend"
VENV_DIR="$BACKEND_DIR/venv"
CONFIG_FILE="$HOME/foodtech/config/database.conf"

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

# Проверка существования директории проекта
check_project_directory() {
    print_subheader "Проверка директории проекта"

    if [ ! -d "$BACKEND_DIR" ]; then
        print_error "Директория backend не найдена: $BACKEND_DIR"
        print_info "Убедитесь, что код проекта находится в $INSTALL_DIR"
        exit 1
    fi

    if [ ! -f "$BACKEND_DIR/main.py" ]; then
        print_error "Файл main.py не найден в $BACKEND_DIR"
        exit 1
    fi

    if [ ! -f "$BACKEND_DIR/requirements.txt" ]; then
        print_error "Файл requirements.txt не найден в $BACKEND_DIR"
        exit 1
    fi

    print_success "Директория backend найдена"
    log "Backend directory verified: $BACKEND_DIR"
}

# Загрузка конфигурации базы данных
load_database_config() {
    print_subheader "Загрузка конфигурации базы данных"

    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Файл конфигурации БД не найден: $CONFIG_FILE"
        print_info "Сначала выполните скрипт 02_setup_database.sh"
        exit 1
    fi

    # Загружаем переменные из конфигурации
    source "$CONFIG_FILE"

    print_success "Конфигурация БД загружена"
    print_info "База данных: $DB_NAME"
    print_info "Пользователь: $DB_USER"
    log "Database config loaded from: $CONFIG_FILE"
}

# Создание виртуального окружения
create_virtual_environment() {
    print_subheader "Создание виртуального окружения Python"

    if [ -d "$VENV_DIR" ]; then
        print_info "Виртуальное окружение уже существует"

        read -p "Пересоздать виртуальное окружение? (y/n): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Удаление старого виртуального окружения..."
            rm -rf "$VENV_DIR"
            print_success "Старое окружение удалено"
        else
            print_info "Использование существующего окружения"
            return 0
        fi
    fi

    print_info "Создание виртуального окружения..."
    cd "$BACKEND_DIR"
    python3 -m venv venv
    print_success "Виртуальное окружение создано"
    log "Virtual environment created: $VENV_DIR"
}

# Установка зависимостей Python
install_dependencies() {
    print_subheader "Установка зависимостей Python"

    print_info "Обновление pip..."
    "$VENV_DIR/bin/pip" install --upgrade pip > /dev/null 2>&1
    print_success "pip обновлен"

    print_info "Установка зависимостей из requirements.txt (это может занять несколько минут)..."
    "$VENV_DIR/bin/pip" install -r "$BACKEND_DIR/requirements.txt" > /dev/null 2>&1
    print_success "Зависимости установлены"
    log "Python dependencies installed"
}

# Генерация SECRET_KEY
generate_secret_key() {
    SECRET_KEY=$(openssl rand -hex 32)
    echo "$SECRET_KEY"
}

# Настройка файла .env
setup_environment_file() {
    print_subheader "Настройка файла окружения (.env)"

    ENV_FILE="$BACKEND_DIR/.env"

    # Если .env уже существует
    if [ -f "$ENV_FILE" ]; then
        print_info "Файл .env уже существует"

        read -p "Пересоздать файл .env? (y/n): " -n 1 -r
        echo

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Файл .env не изменен"
            return 0
        fi
    fi

    # Запрос дополнительных параметров
    echo ""
    print_info "Настройка параметров окружения"
    echo ""

    # iiko API
    read -p "Введите IIKO_API_LOGIN (или оставьте пустым для настройки позже): " IIKO_API_LOGIN
    read -p "Введите IIKO_ORGANIZATION_ID (или оставьте пустым): " IIKO_ORGANIZATION_ID

    # Генерация SECRET_KEY
    SECRET_KEY=$(generate_secret_key)

    # Создание файла .env
    print_info "Создание файла .env..."
    cat > "$ENV_FILE" <<EOF
# Конфигурация FoodTech Backend API
# Создано: $(date '+%Y-%m-%d %H:%M:%S')

# База данных
DATABASE_URL=$DATABASE_URL

# Безопасность
SECRET_KEY=$SECRET_KEY

# iiko Cloud API
IIKO_API_LOGIN=${IIKO_API_LOGIN:-your_iiko_api_login}
IIKO_ORGANIZATION_ID=${IIKO_ORGANIZATION_ID:-your_organization_id}

# Режим отладки (для продакшена - False)
DEBUG=False

# CORS (при необходимости добавьте разрешенные домены)
ALLOWED_ORIGINS=["http://localhost:3000"]
EOF

    # Защита файла
    chmod 600 "$ENV_FILE"
    print_success "Файл .env создан"
    print_info "ВАЖНО: Проверьте и отредактируйте $ENV_FILE при необходимости"
    log "Environment file created: $ENV_FILE"
}

# Инициализация базы данных
initialize_database() {
    print_subheader "Инициализация базы данных"

    if [ -f "$BACKEND_DIR/init_db.py" ]; then
        print_info "Создание таблиц в базе данных..."

        cd "$BACKEND_DIR"
        if "$VENV_DIR/bin/python" init_db.py > /dev/null 2>&1; then
            print_success "Таблицы созданы успешно"
            log "Database initialized"
        else
            print_error "Ошибка при создании таблиц"
            print_info "Попробуйте выполнить вручную: cd $BACKEND_DIR && source venv/bin/activate && python init_db.py"
            log "Database initialization failed"
        fi
    else
        print_info "Скрипт init_db.py не найден, пропускаем инициализацию"
    fi
}

# Тестовый запуск
test_api() {
    print_subheader "Тестовый запуск API"

    print_info "Запуск API для проверки (15 секунд)..."

    cd "$BACKEND_DIR"
    "$VENV_DIR/bin/python" main.py > /tmp/foodtech-api-test.log 2>&1 &
    API_PID=$!

    # Ждем запуска
    sleep 5

    # Проверяем, запустился ли API
    if kill -0 $API_PID 2>/dev/null; then
        print_success "API запущен (PID: $API_PID)"

        # Ждем еще немного
        sleep 5

        # Тестовый запрос
        if curl -s http://localhost:8000/health > /dev/null 2>&1; then
            print_success "API отвечает на запросы"
            log "API test successful"
        else
            print_info "API запущен, но не отвечает на health check"
        fi

        # Останавливаем тестовый запуск
        kill $API_PID 2>/dev/null || true
        wait $API_PID 2>/dev/null || true
        print_info "Тестовый запуск остановлен"
    else
        print_error "Не удалось запустить API"
        print_info "Проверьте логи: /tmp/foodtech-api-test.log"
        log "API test failed"
    fi
}

# Создание systemd сервиса
create_systemd_service() {
    print_subheader "Создание systemd сервиса"

    SERVICE_FILE="/etc/systemd/system/foodtech-api.service"

    # Проверяем наличие готового конфига
    if [ -f "$INSTALL_DIR/configs/systemd/foodtech-api.service" ]; then
        print_info "Копирование готового файла сервиса..."
        cp "$INSTALL_DIR/configs/systemd/foodtech-api.service" "$SERVICE_FILE"
        print_success "Файл сервиса скопирован"
    else
        print_info "Создание файла сервиса..."
        cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=FoodTech FastAPI Backend
After=network.target postgresql.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=$BACKEND_DIR
Environment="PATH=$VENV_DIR/bin"
ExecStart=$VENV_DIR/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        print_success "Файл сервиса создан"
    fi

    log "Systemd service created: $SERVICE_FILE"
}

# Настройка прав доступа
setup_permissions() {
    print_subheader "Настройка прав доступа"

    print_info "Изменение владельца директории на www-data..."
    chown -R www-data:www-data "$BACKEND_DIR"
    print_success "Владелец изменен"

    print_info "Защита файла .env..."
    chmod 600 "$BACKEND_DIR/.env"
    print_success "Права на .env настроены"

    log "Permissions configured"
}

# Запуск сервиса
start_service() {
    print_subheader "Запуск сервиса"

    print_info "Перезагрузка конфигурации systemd..."
    systemctl daemon-reload
    print_success "Конфигурация перезагружена"

    print_info "Включение автозапуска сервиса..."
    systemctl enable foodtech-api > /dev/null 2>&1
    print_success "Автозапуск включен"

    print_info "Запуск сервиса foodtech-api..."
    systemctl start foodtech-api
    print_success "Сервис запущен"

    # Ждем немного
    sleep 3

    # Проверяем статус
    if systemctl is-active --quiet foodtech-api; then
        print_success "Сервис работает корректно"
        log "Service started successfully"
    else
        print_error "Сервис не запущен"
        print_info "Проверьте логи: sudo journalctl -u foodtech-api -n 50"
        log "Service start failed"
    fi
}

# Проверка API
verify_api() {
    print_subheader "Проверка работы API"

    print_info "Ожидание готовности API..."
    sleep 5

    # Health check
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        print_success "API доступен на http://localhost:8000"
        print_success "Документация Swagger: http://localhost:8000/docs"
        log "API verification successful"
    else
        print_error "API не отвечает"
        print_info "Проверьте статус: sudo systemctl status foodtech-api"
        print_info "Проверьте логи: sudo journalctl -u foodtech-api -f"
        log "API verification failed"
    fi
}

# Вывод полезных команд
print_useful_commands() {
    print_subheader "Полезные команды"

    echo ""
    echo "Управление сервисом:"
    echo "  sudo systemctl status foodtech-api    # Проверка статуса"
    echo "  sudo systemctl restart foodtech-api   # Перезапуск"
    echo "  sudo systemctl stop foodtech-api      # Остановка"
    echo "  sudo systemctl start foodtech-api     # Запуск"
    echo ""
    echo "Просмотр логов:"
    echo "  sudo journalctl -u foodtech-api -f    # В реальном времени"
    echo "  sudo journalctl -u foodtech-api -n 50 # Последние 50 строк"
    echo ""
    echo "Тестирование API:"
    echo "  curl http://localhost:8000/health     # Health check"
    echo "  curl http://localhost:8000/docs       # Документация"
    echo ""
}

# Основная функция
main() {
    print_header "FoodTech Auto-Installer: Развертывание Backend API (Этап 3/6)"

    log "=== Backend deployment started ==="

    # Проверки
    check_root
    check_project_directory
    load_database_config

    # Установка
    create_virtual_environment
    install_dependencies
    setup_environment_file
    initialize_database

    # Тестирование
    test_api

    # Настройка сервиса
    create_systemd_service
    setup_permissions
    start_service

    # Проверка
    verify_api

    # Полезная информация
    print_useful_commands

    # Финал
    print_header "Этап 3: Завершено"
    print_success "Backend API развернут и запущен!"
    echo ""
    print_info "Следующий шаг: Выполните скрипт 04_deploy_admin.sh"
    echo ""

    log "=== Backend deployment completed successfully ==="
}

# Запуск
main
