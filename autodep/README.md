# 🚀 FoodTech Auto-Installer

Автоматические установщики для развертывания системы FoodTech на сервере Ubuntu.

## 📋 Описание

Эта папка содержит набор скриптов для автоматической установки всех компонентов системы FoodTech:
- Backend API (FastAPI)
- Admin Panel (Laravel + Filament)
- Telegram Bot (aiogram)

Каждый скрипт выполняет определенный этап установки с проверками и логированием.

## 🎯 Структура установщиков

### Список скриптов (по порядку выполнения)

1. **00_install_nano.sh** - Установка текстового редактора nano
2. **01_prepare_server.sh** - Подготовка сервера и установка ПО
3. **02_setup_database.sh** - Настройка базы данных PostgreSQL
4. **03_deploy_backend.sh** - Развертывание Backend API
5. **04_deploy_admin.sh** - Развертывание Admin Panel
6. **05_deploy_bot.sh** - Развертывание Telegram Bot
7. **06_verify_system.sh** - Проверка работоспособности системы

## 📦 Требования

### Минимальные требования к серверу

- **Операционная система**: Ubuntu 22.04 LTS / 24.04 LTS
- **RAM**: минимум 2 GB (рекомендуется 4 GB)
- **Диск**: минимум 20 GB свободного места
- **Процессор**: 2 CPU cores
- **Доступ**: root или sudo права

### Предварительные требования

- Чистая установка Ubuntu Server
- Доступ по SSH
- Доменное имя (для SSL, опционально)
- Токен Telegram бота (от @BotFather)
- Учетная запись iiko Cloud (опционально)

## 🛠️ Подготовка сервера

### Шаг 0: Первоначальная подготовка

#### Подключение к серверу

```bash
# Подключитесь к серверу по SSH
ssh root@your-server-ip

# Или с использованием пользователя с sudo
ssh username@your-server-ip
```

#### Обновление системы

```bash
# Обновите списки пакетов
sudo apt update

# Установите обновления
sudo apt upgrade -y

# Установите git для клонирования репозитория
sudo apt install -y git
```

#### Клонирование проекта

```bash
# Создайте директорию для проекта
sudo mkdir -p /opt/foodtech

# Перейдите в директорию
cd /opt/foodtech

# Клонируйте репозиторий
sudo git clone https://github.com/carman72tmn/foodtech.git .

# Или если у вас уже есть код локально, скопируйте его на сервер:
# scp -r /path/to/foodtech root@your-server-ip:/opt/foodtech
```

## 🚀 Процесс установки

### Вариант 1: Пошаговая установка (Рекомендуется)

Выполняйте скрипты последовательно, проверяя результат каждого этапа:

#### Этап 1: Установка nano (опционально)

Если на сервере нет текстового редактора nano:

```bash
cd /opt/foodtech/autodep
sudo chmod +x 00_install_nano.sh
sudo ./00_install_nano.sh
```

#### Этап 2: Подготовка сервера

Установка всех необходимых компонентов:

```bash
cd /opt/foodtech/autodep
sudo chmod +x 01_prepare_server.sh
sudo ./01_prepare_server.sh
```

**Что устанавливается:**
- Python 3.11+
- PHP 8.2
- Composer
- PostgreSQL 15+
- Nginx
- Redis (опционально)
- Certbot
- Firewall (UFW)

**Время выполнения:** 10-15 минут

#### Этап 3: Настройка базы данных

Создание базы данных и пользователя:

```bash
sudo chmod +x 02_setup_database.sh
sudo ./02_setup_database.sh
```

**Что настраивается:**
- База данных PostgreSQL
- Пользователь БД с паролем
- Права доступа
- Автоматическое резервное копирование (опционально)

**Важно:** Сохраните параметры подключения к БД!

**Время выполнения:** 2-3 минуты

#### Этап 4: Развертывание Backend API

Установка и запуск FastAPI сервера:

```bash
sudo chmod +x 03_deploy_backend.sh
sudo ./03_deploy_backend.sh
```

**Что настраивается:**
- Виртуальное окружение Python
- Установка зависимостей
- Файл .env с параметрами
- Инициализация таблиц БД
- systemd сервис
- Автозапуск

**Потребуется:**
- Параметры iiko API (можно указать позже)
- SECRET_KEY (генерируется автоматически)

**Время выполнения:** 5-7 минут

#### Этап 5: Развертывание Admin Panel

Установка Laravel панели администрирования:

```bash
sudo chmod +x 04_deploy_admin.sh
sudo ./04_deploy_admin.sh
```

**Что настраивается:**
- Laravel 12 + Filament 3
- Composer зависимости
- Миграции БД
- Nginx конфигурация
- SSL сертификат (опционально)
- Пользователь администратора

**Потребуется:**
- Доменное имя для админ-панели
- Email для Let's Encrypt (для SSL)

**Время выполнения:** 10-15 минут

#### Этап 6: Развертывание Telegram Bot

Установка и запуск бота:

```bash
sudo chmod +x 05_deploy_bot.sh
sudo ./05_deploy_bot.sh
```

**Что настраивается:**
- Виртуальное окружение Python
- Установка зависимостей aiogram
- Файл .env с токеном бота
- systemd сервис
- Автозапуск

**Потребуется:**
- Токен Telegram бота (от @BotFather)
- URL Backend API

**Время выполнения:** 3-5 минут

#### Этап 7: Проверка системы

Полная проверка работоспособности:

```bash
sudo chmod +x 06_verify_system.sh
sudo ./06_verify_system.sh
```

**Что проверяется:**
- Все установленные компоненты
- Службы systemd
- Подключение к БД
- Работа Backend API
- Доступность Admin Panel
- Работа Telegram Bot
- Порты и Firewall
- SSL сертификаты
- Логи на наличие ошибок

**Время выполнения:** 1-2 минуты

### Вариант 2: Автоматическая установка всех компонентов

⚠️ **Внимание:** Этот вариант запускает все скрипты подряд. Вам потребуется вводить данные в интерактивном режиме.

```bash
cd /opt/foodtech/autodep

# Сделайте все скрипты исполняемыми
sudo chmod +x *.sh

# Запустите установку по порядку
sudo ./01_prepare_server.sh && \
sudo ./02_setup_database.sh && \
sudo ./03_deploy_backend.sh && \
sudo ./04_deploy_admin.sh && \
sudo ./05_deploy_bot.sh && \
sudo ./06_verify_system.sh
```

## 📝 Подготовка данных перед установкой

Перед началом установки подготовьте следующую информацию:

### 1. Telegram Bot

**Создание бота через @BotFather:**

1. Откройте Telegram и найдите [@BotFather](https://t.me/BotFather)
2. Отправьте команду `/newbot`
3. Введите имя бота (например: `FoodTech Delivery Bot`)
4. Введите username бота (должен заканчиваться на `bot`, например: `foodtech_delivery_bot`)
5. Скопируйте полученный токен (формат: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 2. Доменное имя (опционально, но рекомендуется)

**Для Admin Panel:**
- Зарегистрируйте домен (например: `admin.yourdomain.com`)
- Настройте A-запись домена на IP адрес сервера
- Дождитесь распространения DNS (может занять до 24 часов)

### 3. iiko Cloud API (опционально)

Если планируете использовать интеграцию с iiko:
- Войдите в личный кабинет iiko Cloud
- Создайте API ключ в разделе настроек
- Скопируйте `IIKO_API_LOGIN` и `IIKO_ORGANIZATION_ID`

### 4. Email для уведомлений

- Подготовьте email для получения уведомлений от Let's Encrypt (для SSL)

## 🔧 Редактирование конфигураций

### Где находятся конфигурационные файлы

```
/opt/foodtech/
├── backend/.env              # Конфигурация Backend API
├── bot/.env                  # Конфигурация Telegram Bot
├── admin-panel/.env          # Конфигурация Admin Panel
└── config/
    └── database.conf         # Параметры БД (автоматически создается)
```

### Редактирование файлов

```bash
# Используйте nano для редактирования
sudo nano /opt/foodtech/backend/.env

# Основные команды nano:
# Ctrl+O - Сохранить
# Ctrl+X - Выход
# Ctrl+K - Вырезать строку
# Ctrl+U - Вставить строку
```

### Применение изменений

После изменения конфигураций перезапустите соответствующие службы:

```bash
# Перезапуск Backend API
sudo systemctl restart foodtech-api

# Перезапуск Telegram Bot
sudo systemctl restart foodtech-bot

# Для Admin Panel очистите кэш Laravel
cd /opt/foodtech/admin-panel
php artisan config:clear
php artisan cache:clear
```

## 🔍 Мониторинг и диагностика

### Проверка статуса служб

```bash
# Все службы FoodTech
sudo systemctl status foodtech-api foodtech-bot

# Системные службы
sudo systemctl status postgresql nginx

# Краткий статус
sudo systemctl is-active foodtech-api foodtech-bot
```

### Просмотр логов

```bash
# Backend API (в реальном времени)
sudo journalctl -u foodtech-api -f

# Telegram Bot (в реальном времени)
sudo journalctl -u foodtech-bot -f

# Последние 100 строк Backend API
sudo journalctl -u foodtech-api -n 100

# Логи за последний час
sudo journalctl -u foodtech-api --since "1 hour ago"

# Nginx логи
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Логи установки
sudo tail -f /var/log/foodtech-install.log
```

### Проверка работы API

```bash
# Health check
curl http://localhost:8000/health

# Документация Swagger
curl http://localhost:8000/docs

# Список категорий
curl http://localhost:8000/api/v1/categories/

# С форматированием (если установлен jq)
curl http://localhost:8000/api/v1/categories/ | jq
```

### Проверка базы данных

```bash
# Подключение к БД (потребуется пароль из /opt/foodtech/config/database.conf)
sudo -u postgres psql foodtech_db

# Список таблиц
\dt

# Выход из psql
\q
```

## 🛑 Управление службами

### Базовые команды

```bash
# Запуск службы
sudo systemctl start foodtech-api

# Остановка службы
sudo systemctl stop foodtech-api

# Перезапуск службы
sudo systemctl restart foodtech-api

# Перезагрузка конфигурации (без остановки)
sudo systemctl reload foodtech-api

# Включить автозапуск
sudo systemctl enable foodtech-api

# Отключить автозапуск
sudo systemctl disable foodtech-api
```

### Перезапуск всех служб FoodTech

```bash
sudo systemctl restart foodtech-api foodtech-bot nginx
```

## 🔄 Обновление приложений

### Обновление кода из Git

```bash
cd /opt/foodtech

# Сохраните текущие .env файлы
sudo cp backend/.env backend/.env.backup
sudo cp bot/.env bot/.env.backup

# Получите обновления
sudo git pull origin main

# Восстановите .env файлы
sudo cp backend/.env.backup backend/.env
sudo cp bot/.env.backup bot/.env
```

### Обновление Backend API

```bash
cd /opt/foodtech/backend
source venv/bin/activate

# Обновление зависимостей
pip install -r requirements.txt --upgrade

# Применение миграций (если есть)
python init_db.py

# Перезапуск
sudo systemctl restart foodtech-api
```

### Обновление Telegram Bot

```bash
cd /opt/foodtech/bot
source venv/bin/activate

# Обновление зависимостей
pip install -r requirements.txt --upgrade

# Перезапуск
sudo systemctl restart foodtech-bot
```

### Обновление Admin Panel

```bash
cd /opt/foodtech/admin-panel

# Обновление зависимостей
composer update

# Применение миграций
php artisan migrate

# Очистка кэша
php artisan config:clear
php artisan cache:clear
php artisan view:clear
```

## 💾 Резервное копирование

### Ручное резервное копирование базы данных

```bash
# Создание бэкапа
sudo -u postgres pg_dump foodtech_db > /var/backups/foodtech_db_$(date +%Y%m%d_%H%M%S).sql

# Сжатие бэкапа
gzip /var/backups/foodtech_db_*.sql

# Восстановление из бэкапа
sudo -u postgres psql foodtech_db < /var/backups/foodtech_db_YYYYMMDD_HHMMSS.sql
```

### Автоматическое резервное копирование

Автоматический бэкап настраивается во время выполнения скрипта `02_setup_database.sh`.

**Проверка настройки автоматического бэкапа:**

```bash
# Проверка наличия скрипта
ls -la /usr/local/bin/foodtech-db-backup.sh

# Проверка задания cron
sudo crontab -l | grep foodtech

# Ручной запуск бэкапа
sudo /usr/local/bin/foodtech-db-backup.sh

# Просмотр созданных бэкапов
ls -lh /var/backups/foodtech/
```

### Резервное копирование конфигураций

```bash
# Создание архива конфигураций
sudo tar -czf /var/backups/foodtech-configs_$(date +%Y%m%d).tar.gz \
    /opt/foodtech/backend/.env \
    /opt/foodtech/bot/.env \
    /opt/foodtech/admin-panel/.env \
    /opt/foodtech/config/ \
    /etc/nginx/sites-available/foodtech-* \
    /etc/systemd/system/foodtech-*
```

## 🚨 Решение проблем

### Backend API не запускается

```bash
# Проверка логов
sudo journalctl -u foodtech-api -n 50

# Проверка конфигурации
sudo cat /opt/foodtech/backend/.env

# Проверка подключения к БД
cd /opt/foodtech/backend
source venv/bin/activate
python -c "from app.core.database import engine; print('DB OK')"

# Проверка прав
ls -la /opt/foodtech/backend/

# Ручной запуск для диагностики
cd /opt/foodtech/backend
source venv/bin/activate
python main.py
```

### Telegram Bot не отвечает

```bash
# Проверка логов
sudo journalctl -u foodtech-bot -n 50

# Проверка токена
sudo cat /opt/foodtech/bot/.env

# Проверка доступности Backend API
curl http://localhost:8000/health

# Ручной запуск для диагностики
cd /opt/foodtech/bot
source venv/bin/activate
python main.py
```

### Admin Panel не открывается

```bash
# Проверка Nginx
sudo nginx -t
sudo systemctl status nginx

# Проверка конфигурации сайта
sudo cat /etc/nginx/sites-available/foodtech-admin

# Проверка PHP-FPM
sudo systemctl status php8.2-fpm

# Проверка логов Laravel
sudo tail -f /opt/foodtech/admin-panel/storage/logs/laravel.log

# Очистка кэша Laravel
cd /opt/foodtech/admin-panel
php artisan cache:clear
php artisan config:clear
php artisan view:clear
```

### База данных недоступна

```bash
# Проверка статуса PostgreSQL
sudo systemctl status postgresql

# Попытка запуска
sudo systemctl start postgresql

# Проверка подключения
sudo -u postgres psql -l

# Проверка логов PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### Ошибки SSL сертификатов

```bash
# Обновление сертификатов
sudo certbot renew

# Проверка сертификатов
sudo certbot certificates

# Получение нового сертификата
sudo certbot --nginx -d your-domain.com

# Проверка автоматического обновления
sudo systemctl status certbot.timer
```

## 📊 Производительность и оптимизация

### Мониторинг ресурсов

```bash
# Общая информация о системе
htop

# Использование диска
df -h

# Использование памяти
free -h

# Активные процессы FoodTech
ps aux | grep -E "foodtech|uvicorn|python.*main.py"

# Сетевые подключения
sudo netstat -tulnp | grep -E "8000|80|443"
```

### Оптимизация Backend API

```bash
# Увеличение количества workers (в файле сервиса)
sudo nano /etc/systemd/system/foodtech-api.service

# Измените строку ExecStart:
# ExecStart=/opt/foodtech/backend/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4

# Перезагрузите конфигурацию
sudo systemctl daemon-reload
sudo systemctl restart foodtech-api
```

### Настройка PostgreSQL

```bash
# Редактирование конфигурации PostgreSQL
sudo nano /etc/postgresql/*/main/postgresql.conf

# Основные параметры для оптимизации:
# shared_buffers = 256MB
# effective_cache_size = 1GB
# maintenance_work_mem = 128MB
# work_mem = 4MB

# Перезапуск PostgreSQL
sudo systemctl restart postgresql
```

## 🔐 Безопасность

### Рекомендации по безопасности

1. **Регулярно обновляйте систему:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Защитите SSH:**
   ```bash
   # Отключите вход по паролю, используйте только SSH ключи
   sudo nano /etc/ssh/sshd_config
   # PasswordAuthentication no
   sudo systemctl restart sshd
   ```

3. **Настройте fail2ban:**
   ```bash
   sudo apt install -y fail2ban
   sudo systemctl enable fail2ban
   sudo systemctl start fail2ban
   ```

4. **Проверяйте права на файлы:**
   ```bash
   # .env файлы должны быть 600
   sudo chmod 600 /opt/foodtech/backend/.env
   sudo chmod 600 /opt/foodtech/bot/.env
   sudo chmod 600 /opt/foodtech/admin-panel/.env
   ```

5. **Мониторьте логи на подозрительную активность:**
   ```bash
   sudo tail -f /var/log/auth.log
   sudo tail -f /var/log/nginx/access.log
   ```

## 📞 Поддержка

### Получение помощи

- **GitHub Issues:** [github.com/carman72tmn/foodtech/issues](https://github.com/carman72tmn/foodtech/issues)
- **Документация проекта:** `/opt/foodtech/README.md`
- **Инструкции по развертыванию:** `/opt/foodtech/instructions/`

### Полезные ссылки

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Laravel Documentation](https://laravel.com/docs)
- [Filament Documentation](https://filamentphp.com/docs)
- [aiogram Documentation](https://docs.aiogram.dev/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Nginx Documentation](https://nginx.org/ru/docs/)

## 📄 Лицензия

MIT License - см. файл LICENSE в корне проекта

---

**Сделано с ❤️ для упрощения развертывания FoodTech**
