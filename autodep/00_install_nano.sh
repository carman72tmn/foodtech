#!/bin/bash

###############################################################################
# FoodTech Auto-Installer: Установка редактора nano
# Описание: Простой скрипт для установки текстового редактора nano
###############################################################################

set -e  # Прерывать выполнение при ошибках

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода заголовков
print_header() {
    echo ""
    echo -e "${BLUE}==========================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}==========================================================${NC}"
    echo ""
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

# Проверка прав root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Этот скрипт должен быть запущен с правами root (используйте sudo)"
        exit 1
    fi
}

# Основная функция
main() {
    print_header "Установка текстового редактора nano"

    # Проверка прав
    check_root

    # Проверяем, установлен ли уже nano
    if command -v nano &> /dev/null; then
        NANO_VERSION=$(nano --version | head -n1)
        print_success "Редактор nano уже установлен: $NANO_VERSION"
        exit 0
    fi

    print_info "Обновление списков пакетов..."
    apt update > /dev/null 2>&1
    print_success "Списки пакетов обновлены"

    print_info "Установка редактора nano..."
    apt install -y nano > /dev/null 2>&1
    print_success "Редактор nano установлен"

    # Проверка установки
    if command -v nano &> /dev/null; then
        NANO_VERSION=$(nano --version | head -n1)
        print_success "Установка завершена: $NANO_VERSION"

        echo ""
        print_info "Основные команды nano:"
        echo "  • Ctrl+O - Сохранить файл"
        echo "  • Ctrl+X - Выход из редактора"
        echo "  • Ctrl+K - Вырезать строку"
        echo "  • Ctrl+U - Вставить строку"
        echo "  • Ctrl+W - Поиск"
        echo "  • Ctrl+G - Справка"
        echo ""
    else
        print_error "Не удалось установить nano"
        exit 1
    fi
}

# Запуск
main
