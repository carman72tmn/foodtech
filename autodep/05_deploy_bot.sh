#!/bin/bash

###############################################################################
# FoodTech Auto-Installer: Развертывание Telegram Bot (Этап 5)
# Описание: Установка и настройка Telegram Bot
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
BOT_DIR="$INSTALL_DIR/bot"
VENV_DIR="$BOT_DIR/venv"

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

# Проверка директории бота
check_bot_directory() {
    print_subheader "Проверка директории Telegram Bot"

    if [ ! -d "$BOT_DIR" ]; then
        print_error "Директория bot не найдена: $BOT_DIR"
        print_info "Убедитесь, что код проекта находится в $INSTALL_DIR"
        exit 1
    fi

    if [ ! -f "$BOT_DIR/main.py" ]; then
        print_error "Файл main.py не найден в $BOT_DIR"
        exit 1
    fi

    if [ ! -f "$BOT_DIR/requirements.txt" ]; then
        print_error "Файл requirements.txt не найден в $BOT_DIR"
        exit 1
    fi

    print_success "Директория bot найдена"
    log "Bot directory verified: $BOT_DIR"
}

# Инструкция по созданию бота
print_bot_creation_guide() {
    print_subheader "Создание Telegram бота"

    echo ""
    print_info "Если вы еще не создали Telegram бота, следуйте инструкциям:"
    echo ""
    echo "1. Откройте Telegram и найдите @BotFather"
    echo "2. Отправьте команду /newbot"
    echo "3. Введите имя вашего бота (например: FoodTech Delivery Bot)"
    echo "4. Введите username бота (должен заканчиваться на 'bot', например: foodtech_delivery_bot)"
    echo "5. BotFather пришлет вам токен - скопируйте его"
    echo ""
    print_info "Токен выглядит примерно так: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
    echo ""

    read -p "Нажмите Enter когда получите токен бота..."
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
    cd "$BOT_DIR"
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
    "$VENV_DIR/bin/pip" install -r "$BOT_DIR/requirements.txt" > /dev/null 2>&1
    print_success "Зависимости установлены"
    log "Python dependencies installed"
}

# Настройка файла .env
setup_environment_file() {
    print_subheader "Настройка файла окружения (.env)"

    ENV_FILE="$BOT_DIR/.env"

    # Запрос токена бота
    echo ""
    read -p "Введите токен Telegram бота: " BOT_TOKEN

    # Проверка токена (базовая)
    if [ -z "$BOT_TOKEN" ]; then
        print_error "Токен не может быть пустым"
        exit 1
    fi

    if [[ ! "$BOT_TOKEN" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
        print_error "Токен имеет неверный формат"
        exit 1
    fi

    # API URL
    API_URL="http://localhost:8000/api/v1"
    read -p "URL Backend API [$API_URL]: " input_api_url
    API_URL=${input_api_url:-$API_URL}

    # Создание файла .env
    print_info "Создание файла .env..."
    cat > "$ENV_FILE" <<EOF
# Конфигурация FoodTech Telegram Bot
# Создано: $(date '+%Y-%m-%d %H:%M:%S')

# Токен Telegram бота
BOT_TOKEN=$BOT_TOKEN

# URL Backend API
API_URL=$API_URL

# Режим отладки (для продакшена - False)
DEBUG=False
EOF

    # Защита файла
    chmod 600 "$ENV_FILE"
    print_success "Файл .env создан"
    log "Environment file created: $ENV_FILE"
}

# Тестовый запуск бота
test_bot() {
    print_subheader "Тестовый запуск бота"

    print_info "Запуск бота для проверки (10 секунд)..."

    cd "$BOT_DIR"
    timeout 10s "$VENV_DIR/bin/python" main.py > /tmp/foodtech-bot-test.log 2>&1 || true

    # Проверяем логи
    if grep -q "error\|Error\|ERROR" /tmp/foodtech-bot-test.log 2>/dev/null; then
        print_error "Обнаружены ошибки при запуске"
        print_info "Проверьте логи: /tmp/foodtech-bot-test.log"
        log "Bot test found errors"
    else
        print_success "Бот запускается без явных ошибок"
        log "Bot test successful"
    fi
}

# Создание systemd сервиса
create_systemd_service() {
    print_subheader "Создание systemd сервиса"

    SERVICE_FILE="/etc/systemd/system/foodtech-bot.service"

    # Проверяем наличие готового конфига
    if [ -f "$INSTALL_DIR/configs/systemd/foodtech-bot.service" ]; then
        print_info "Копирование готового файла сервиса..."
        cp "$INSTALL_DIR/configs/systemd/foodtech-bot.service" "$SERVICE_FILE"
        print_success "Файл сервиса скопирован"
    else
        print_info "Создание файла сервиса..."
        cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=FoodTech Telegram Bot
After=network.target foodtech-api.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=$BOT_DIR
Environment="PATH=$VENV_DIR/bin"
ExecStart=$VENV_DIR/bin/python main.py
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
    chown -R www-data:www-data "$BOT_DIR"
    print_success "Владелец изменен"

    print_info "Защита файла .env..."
    chmod 600 "$BOT_DIR/.env"
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
    systemctl enable foodtech-bot > /dev/null 2>&1
    print_success "Автозапуск включен"

    print_info "Запуск сервиса foodtech-bot..."
    systemctl start foodtech-bot
    print_success "Сервис запущен"

    # Ждем немного
    sleep 3

    # Проверяем статус
    if systemctl is-active --quiet foodtech-bot; then
        print_success "Сервис работает корректно"
        log "Service started successfully"
    else
        print_error "Сервис не запущен"
        print_info "Проверьте логи: sudo journalctl -u foodtech-bot -n 50"
        log "Service start failed"
    fi
}

# Проверка работы бота
verify_bot() {
    print_subheader "Проверка работы бота"

    print_info "Ожидание готовности бота..."
    sleep 5

    # Проверяем логи на наличие ошибок
    if journalctl -u foodtech-bot -n 20 --no-pager | grep -q "error\|Error\|ERROR"; then
        print_error "Обнаружены ошибки в логах"
        print_info "Проверьте логи: sudo journalctl -u foodtech-bot -f"
        log "Bot verification found errors"
    else
        print_success "Бот работает без явных ошибок"
        print_info "Откройте Telegram и отправьте боту команду /start"
        log "Bot verification successful"
    fi
}

# Вывод полезных команд
print_useful_commands() {
    print_subheader "Полезные команды"

    echo ""
    echo "Управление сервисом:"
    echo "  sudo systemctl status foodtech-bot    # Проверка статуса"
    echo "  sudo systemctl restart foodtech-bot   # Перезапуск"
    echo "  sudo systemctl stop foodtech-bot      # Остановка"
    echo "  sudo systemctl start foodtech-bot     # Запуск"
    echo ""
    echo "Просмотр логов:"
    echo "  sudo journalctl -u foodtech-bot -f    # В реальном времени"
    echo "  sudo journalctl -u foodtech-bot -n 50 # Последние 50 строк"
    echo ""
    echo "Тестирование бота:"
    echo "  1. Откройте Telegram"
    echo "  2. Найдите вашего бота по username"
    echo "  3. Отправьте команду /start"
    echo ""
}

# Основная функция
main() {
    print_header "FoodTech Auto-Installer: Развертывание Telegram Bot (Этап 5/6)"

    log "=== Bot deployment started ==="

    # Проверки
    check_root
    check_bot_directory

    # Инструкция
    print_bot_creation_guide

    # Установка
    create_virtual_environment
    install_dependencies
    setup_environment_file

    # Тестирование
    test_bot

    # Настройка сервиса
    create_systemd_service
    setup_permissions
    start_service

    # Проверка
    verify_bot

    # Полезная информация
    print_useful_commands

    # Финал
    print_header "Этап 5: Завершено"
    print_success "Telegram Bot развернут и запущен!"
    echo ""
    print_info "Следующий шаг: Выполните скрипт 06_verify_system.sh для полной проверки"
    echo ""

    log "=== Bot deployment completed successfully ==="
}

# Запуск
main
