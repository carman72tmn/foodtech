#!/bin/bash

###############################################################################
# FoodTech Auto-Installer: Проверка системы (Этап 6)
# Описание: Полная проверка работоспособности всех компонентов
# Версия: 1.0
###############################################################################

set -e  # Прерывать выполнение при ошибках

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Параметры
INSTALL_DIR="$HOME/foodtech"
BACKEND_DIR="$INSTALL_DIR/backend"
ADMIN_DIR="$INSTALL_DIR/admin-panel"
BOT_DIR="$INSTALL_DIR/bot"

# Счетчики
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

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

# Функция для выполнения теста
run_test() {
    local test_name="$1"
    local test_command="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if eval "$test_command" > /dev/null 2>&1; then
        print_success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        print_error "$test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
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

# Проверка установленных компонентов
check_installed_components() {
    print_subheader "Проверка установленных компонентов"

    run_test "Python 3 установлен" "command -v python3"
    run_test "PHP 8.2 установлен" "command -v php"
    run_test "Composer установлен" "command -v composer"
    run_test "PostgreSQL установлен" "command -v psql"
    run_test "Nginx установлен" "command -v nginx"
    run_test "Certbot установлен" "command -v certbot"

    echo ""
}

# Проверка служб systemd
check_systemd_services() {
    print_subheader "Проверка служб systemd"

    run_test "PostgreSQL запущен" "systemctl is-active --quiet postgresql"
    run_test "Nginx запущен" "systemctl is-active --quiet nginx"
    run_test "FoodTech API запущен" "systemctl is-active --quiet foodtech-api"
    run_test "FoodTech Bot запущен" "systemctl is-active --quiet foodtech-bot"

    # PHP-FPM
    if systemctl list-unit-files | grep -q "php8.2-fpm"; then
        run_test "PHP-FPM запущен" "systemctl is-active --quiet php8.2-fpm"
    fi

    echo ""
}

# Проверка директорий проекта
check_project_directories() {
    print_subheader "Проверка директорий проекта"

    run_test "Директория backend существует" "test -d $BACKEND_DIR"
    run_test "Директория admin-panel существует" "test -d $ADMIN_DIR"
    run_test "Директория bot существует" "test -d $BOT_DIR"

    run_test "Файл backend/main.py существует" "test -f $BACKEND_DIR/main.py"
    run_test "Файл backend/.env существует" "test -f $BACKEND_DIR/.env"
    run_test "Файл bot/main.py существует" "test -f $BOT_DIR/main.py"
    run_test "Файл bot/.env существует" "test -f $BOT_DIR/.env"

    echo ""
}

# Проверка базы данных
check_database() {
    print_subheader "Проверка базы данных PostgreSQL"

    # Загружаем конфигурацию БД
    if [ -f "$HOME/foodtech/config/database.conf" ]; then
        source "$HOME/foodtech/config/database.conf"

        run_test "База данных существует" "sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME"
        run_test "Пользователь базы данных существует" "sudo -u postgres psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'\" | grep -q 1"

        # Проверка подключения
        if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
            print_success "Подключение к базе данных работает"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            print_error "Подключение к базе данных не работает"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
    else
        print_info "Файл конфигурации БД не найден, пропускаем проверку"
    fi

    echo ""
}

# Проверка Backend API
check_backend_api() {
    print_subheader "Проверка Backend API"

    # Health check
    if curl -s -f http://localhost:8000/health > /dev/null 2>&1; then
        print_success "API health check успешен"
        TESTS_PASSED=$((TESTS_PASSED + 1))

        # Проверка документации
        if curl -s -f http://localhost:8000/docs > /dev/null 2>&1; then
            print_success "Swagger документация доступна"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            print_error "Swagger документация недоступна"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi

        # Проверка API endpoints
        if curl -s -f http://localhost:8000/api/v1/categories/ > /dev/null 2>&1; then
            print_success "API endpoint /categories/ работает"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            print_error "API endpoint /categories/ не работает"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi

    else
        print_error "API health check неудачен"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        print_info "Проверьте статус: sudo systemctl status foodtech-api"
        print_info "Проверьте логи: sudo journalctl -u foodtech-api -n 50"
    fi

    TESTS_TOTAL=$((TESTS_TOTAL + 4))

    echo ""
}

# Проверка Admin Panel
check_admin_panel() {
    print_subheader "Проверка Admin Panel"

    # Проверка Nginx конфигурации
    if [ -f "/etc/nginx/sites-enabled/foodtech-admin" ]; then
        print_success "Nginx конфигурация для Admin Panel существует"
        TESTS_PASSED=$((TESTS_PASSED + 1))

        # Проверка Laravel
        if [ -f "$ADMIN_DIR/artisan" ]; then
            print_success "Laravel установлен"
            TESTS_PASSED=$((TESTS_PASSED + 1))

            # Проверка Filament
            if [ -d "$ADMIN_DIR/vendor/filament" ]; then
                print_success "Filament установлен"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                print_error "Filament не установлен"
                TESTS_FAILED=$((TESTS_FAILED + 1))
            fi
        else
            print_error "Laravel не установлен"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        print_info "Nginx конфигурация для Admin Panel не найдена"
        TESTS_FAILED=$((TESTS_FAILED + 3))
    fi

    TESTS_TOTAL=$((TESTS_TOTAL + 3))

    echo ""
}

# Проверка Telegram Bot
check_telegram_bot() {
    print_subheader "Проверка Telegram Bot"

    # Проверка логов на наличие критических ошибок
    if ! journalctl -u foodtech-bot -n 50 --no-pager 2>/dev/null | grep -qi "critical\|exception"; then
        print_success "Telegram Bot работает без критических ошибок"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_error "Обнаружены критические ошибки в логах бота"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        print_info "Проверьте логи: sudo journalctl -u foodtech-bot -n 50"
    fi

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    echo ""
}

# Проверка портов
check_ports() {
    print_subheader "Проверка открытых портов"

    run_test "Порт 80 (HTTP) открыт" "netstat -tuln | grep -q ':80'"
    run_test "Порт 8000 (API) открыт" "netstat -tuln | grep -q ':8000'"

    # Проверка 443 только если есть SSL
    if [ -d "/etc/letsencrypt/live" ]; then
        run_test "Порт 443 (HTTPS) открыт" "netstat -tuln | grep -q ':443'"
    fi

    echo ""
}

# Проверка логов на ошибки
check_logs_for_errors() {
    print_subheader "Проверка логов на критические ошибки"

    local has_errors=false

    # Backend API
    if journalctl -u foodtech-api -n 100 --no-pager 2>/dev/null | grep -qi "critical\|fatal"; then
        print_error "Критические ошибки в логах Backend API"
        has_errors=true
    fi

    # Telegram Bot
    if journalctl -u foodtech-bot -n 100 --no-pager 2>/dev/null | grep -qi "critical\|fatal"; then
        print_error "Критические ошибки в логах Telegram Bot"
        has_errors=true
    fi

    # Nginx
    if [ -f "/var/log/nginx/error.log" ]; then
        if tail -n 100 /var/log/nginx/error.log 2>/dev/null | grep -qi "emerg\|alert\|crit"; then
            print_error "Критические ошибки в логах Nginx"
            has_errors=true
        fi
    fi

    if [ "$has_errors" = false ]; then
        print_success "Критических ошибок в логах не обнаружено"
    fi

    echo ""
}

# Проверка firewall
check_firewall() {
    print_subheader "Проверка Firewall (UFW)"

    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: active"; then
            print_success "UFW активен"

            # Проверка правил
            if ufw status | grep -q "Nginx Full\|80/tcp\|443/tcp"; then
                print_success "Правила для Nginx настроены"
            else
                print_error "Правила для Nginx не найдены"
            fi

            if ufw status | grep -q "OpenSSH\|22/tcp"; then
                print_success "Правила для SSH настроены"
            else
                print_error "Правила для SSH не найдены"
            fi
        else
            print_info "UFW не активен"
        fi
    else
        print_info "UFW не установлен"
    fi

    echo ""
}

# Проверка SSL сертификатов
check_ssl_certificates() {
    print_subheader "Проверка SSL сертификатов"

    if [ -d "/etc/letsencrypt/live" ]; then
        CERT_COUNT=$(ls -1 /etc/letsencrypt/live 2>/dev/null | wc -l)

        if [ "$CERT_COUNT" -gt 0 ]; then
            print_success "Найдено сертификатов: $CERT_COUNT"

            # Проверка срока действия
            for domain in $(ls -1 /etc/letsencrypt/live 2>/dev/null); do
                if [ -f "/etc/letsencrypt/live/$domain/cert.pem" ]; then
                    EXPIRY_DATE=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$domain/cert.pem" 2>/dev/null | cut -d= -f2)
                    if [ -n "$EXPIRY_DATE" ]; then
                        print_success "Сертификат для $domain действителен до: $EXPIRY_DATE"
                    fi
                fi
            done
        else
            print_info "SSL сертификаты не установлены"
        fi
    else
        print_info "Let's Encrypt не настроен"
    fi

    echo ""
}

# Вывод результатов
print_results() {
    print_header "Результаты проверки"

    local success_rate=0
    if [ $TESTS_TOTAL -gt 0 ]; then
        success_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    fi

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              СТАТИСТИКА ПРОВЕРКИ                       ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Всего тестов:        $TESTS_TOTAL"
    echo -e "${CYAN}║${NC} Успешно пройдено:    ${GREEN}$TESTS_PASSED${NC}"
    echo -e "${CYAN}║${NC} Провалено:           ${RED}$TESTS_FAILED${NC}"
    echo -e "${CYAN}║${NC} Процент успеха:      ${GREEN}${success_rate}%${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        print_success "Все проверки пройдены успешно! 🎉"
        echo ""
        print_info "Система FoodTech полностью работоспособна!"
    else
        print_error "Некоторые проверки не пройдены"
        echo ""
        print_info "Проверьте ошибки выше и исправьте проблемы"
    fi

    log "Verification completed: $TESTS_PASSED/$TESTS_TOTAL tests passed"
}

# Рекомендации по дальнейшим действиям
print_recommendations() {
    print_subheader "Рекомендации"

    echo ""
    echo "1. Мониторинг системы:"
    echo "   • Регулярно проверяйте логи: sudo journalctl -u foodtech-api -f"
    echo "   • Мониторьте использование ресурсов: htop"
    echo "   • Проверяйте статус служб: systemctl status foodtech-*"
    echo ""
    echo "2. Резервное копирование:"
    echo "   • Настройте автоматическое резервное копирование БД"
    echo "   • Сохраняйте конфигурационные файлы"
    echo "   • Регулярно тестируйте восстановление из бэкапов"
    echo ""
    echo "3. Безопасность:"
    echo "   • Регулярно обновляйте систему: sudo apt update && sudo apt upgrade"
    echo "   • Следите за обновлениями безопасности"
    echo "   • Проверяйте логи на подозрительную активность"
    echo ""
    echo "4. Производительность:"
    echo "   • Мониторьте время отклика API"
    echo "   • Оптимизируйте запросы к БД при необходимости"
    echo "   • Настройте кэширование для Admin Panel"
    echo ""
    echo "5. Тестирование:"
    echo "   • Откройте Telegram бота и протестируйте полный цикл заказа"
    echo "   • Проверьте Admin Panel: создание категорий и товаров"
    echo "   • Протестируйте синхронизацию с iiko (если настроена)"
    echo ""
}

# Полезные команды
print_useful_commands() {
    print_subheader "Полезные команды"

    echo ""
    echo "Проверка статуса всех служб:"
    echo "  systemctl status foodtech-api foodtech-bot nginx postgresql"
    echo ""
    echo "Просмотр логов:"
    echo "  sudo journalctl -u foodtech-api -f     # Backend API"
    echo "  sudo journalctl -u foodtech-bot -f     # Telegram Bot"
    echo "  sudo tail -f /var/log/nginx/error.log  # Nginx"
    echo ""
    echo "Перезапуск служб:"
    echo "  sudo systemctl restart foodtech-api"
    echo "  sudo systemctl restart foodtech-bot"
    echo "  sudo systemctl reload nginx"
    echo ""
    echo "Повторная проверка системы:"
    echo "  sudo $0"
    echo ""
}

# Основная функция
main() {
    print_header "FoodTech Auto-Installer: Проверка системы (Этап 6/6)"

    log "=== System verification started ==="

    # Проверка прав
    check_root

    # Выполнение проверок
    check_installed_components
    check_systemd_services
    check_project_directories
    check_database
    check_backend_api
    check_admin_panel
    check_telegram_bot
    check_ports
    check_logs_for_errors
    check_firewall
    check_ssl_certificates

    # Результаты
    print_results
    print_recommendations
    print_useful_commands

    # Финал
    print_header "Проверка завершена"

    if [ $TESTS_FAILED -eq 0 ]; then
        print_success "✨ Поздравляем! FoodTech успешно установлена и работает! ✨"
        echo ""
        print_info "Начните использовать систему:"
        echo "  • Backend API: http://localhost:8000/docs"
        echo "  • Admin Panel: http://your-domain/admin"
        echo "  • Telegram Bot: Откройте бота в Telegram и отправьте /start"
        echo ""
    fi

    log "=== System verification completed ==="
}

# Запуск
main
