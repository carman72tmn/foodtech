# DovezU - Подробное руководство по установке и настройке

> **Полное руководство** по развертыванию системы управления доставкой DovezU

## 📋 Содержание

1. [Предварительные требования](#предварительные-требования)
2. [Быстрая установка](#быстрая-установка)
3. [Вариант 1: Docker установка](#вариант-1-docker-установка)
4. [Вариант 2: Нативная установка](#вариант-2-нативная-установка)
5. [Вариант 3: Свежая установка](#вариант-3-свежая-установка)
6. [Настройка окружения](#настройка-окружения)
7. [Настройка SSL](#настройка-ssl)
8. [Настройка интеграций](#настройка-интеграций)
9. [Проверка работоспособности](#проверка-работоспособности)
10. [Обслуживание и обновление](#обслуживание-и-обновление)
11. [Решение проблем](#решение-проблем)

---

## 🔧 Предварительные требования

### Системные требования

#### Минимальные (для тестирования)
- **CPU**: 2 ядра
- **RAM**: 4 GB
- **Диск**: 20 GB свободного места
- **ОС**: Ubuntu 20.04+ или Debian 11+

#### Рекомендуемые (для продакшена)
- **CPU**: 4+ ядра
- **RAM**: 8+ GB
- **Диск**: 50+ GB SSD
- **ОС**: Ubuntu 22.04 LTS
- **Сеть**: Статический IP, домен

### Необходимые учетные записи

1. **iiko Cloud Account**
   - Зарегистрируйтесь на https://iiko.biz/
   - Получите API ключ в панели администратора
   - Документация: https://api-ru.iiko.services/docs

2. **Telegram Bot**
   - Откройте @BotFather в Telegram
   - Создайте бота командой `/newbot`
   - Сохраните полученный токен

3. **Домен (опционально, но рекомендуется)**
   - Зарегистрируйте домен
   - Настройте DNS А-запись на IP сервера

---

## ⚡ Быстрая установка

### Самый быстрый способ (Авто-установка)

```bash
# 1. Подключитесь к серверу
ssh root@your-server-ip

# 2. Скачайте проект
git clone https://github.com/carman72tmn/foodtech.git
cd foodtech

# 3. Настройте окружение
cp .env.production .env
nano .env
# Заполните все необходимые параметры (см. раздел "Настройка окружения")

# 4. Запустите автоустановку
sudo bash auto-install.sh

# 5. Следуйте инструкциям на экране
```

Автоустановщик сам определит оптимальный вариант установки для вашей системы.

---

## 🐳 Вариант 1: Docker установка

**Рекомендуется** для большинства случаев. Работает на KVM, VMware, Hyper-V.

### Шаг 1: Проверка совместимости

```bash
# Проверьте виртуализацию
systemd-detect-virt

# Если вывод "openvz" или "lxc" - используйте Нативную установку
# Для всех остальных случаев Docker подходит
```

### Шаг 2: Подготовка системы

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка зависимостей
sudo apt install -y git curl wget
```

### Шаг 3: Клонирование проекта

```bash
# Создание директории
sudo mkdir -p /opt/foodtech
cd /opt/foodtech

# Клонирование
git clone https://github.com/carman72tmn/foodtech.git .

# Или если уже скачали в другое место
cd ~/foodtech
sudo cp -r . /opt/foodtech/
```

### Шаг 4: Настройка окружения

```bash
cd /opt/foodtech

# Создание .env из шаблона
cp .env.production .env

# Редактирование (см. раздел "Настройка окружения")
nano .env
```

**Обязательно измените**:
- `POSTGRES_PASSWORD` - сильный пароль для БД
- `IIKO_API_LOGIN` - ваш API ключ от iiko
- `BOT_TOKEN` - токен вашего Telegram бота
- `DOMAIN` - ваш домен (если есть)

### Шаг 5: Запуск установки

```bash
sudo bash install.sh
```

Скрипт автоматически:
- Установит Docker и Docker Compose
- Настроит файрвол (UFW)
- Соберет и запустит контейнеры
- Выполнит миграции БД
- Создаст начальные данные

### Шаг 6: Проверка установки

```bash
# Проверка запущенных контейнеров
docker compose ps

# Должны быть запущены:
# - admin (Laravel)
# - backend (FastAPI)
# - bot (Telegram Bot)
# - postgres (Database)
# - redis (Cache)
# - nginx (Web Server)

# Проверка логов
docker compose logs -f admin
docker compose logs -f backend
docker compose logs -f bot
```

### Шаг 7: Первый вход

Откройте в браузере: `http://YOUR_SERVER_IP/admin`

- **Логин**: `admin@foodtech.ru`
- **Пароль**: `password`

**⚠️ СРАЗУ СМЕНИТЕ ПАРОЛЬ!**

---

## 🖥️ Вариант 2: Нативная установка

Для VPS без Docker (OpenVZ, LXC) или если нужна максимальная производительность.

### Шаг 1: Подготовка системы

```bash
# Обновление
sudo apt update && sudo apt upgrade -y

# Установка зависимостей
sudo apt install -y software-properties-common curl wget git
```

### Шаг 2: Установка PHP 8.2

```bash
# Добавление репозитория
sudo add-apt-repository -y ppa:ondrej/php
sudo apt update

# Установка PHP и модулей
sudo apt install -y \
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
    php8.2-opcache
```

### Шаг 3: Установка Composer

```bash
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
composer --version
```

### Шаг 4: Установка Node.js 20

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt install -y nodejs
node --version
npm --version
```

### Шаг 5: Установка Python 3.11

```bash
sudo apt install -y \
    python3.11 \
    python3.11-venv \
    python3-pip

# Создание симлинка (если нужно)
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
```

### Шаг 6: Установка PostgreSQL 15

```bash
# Установка
sudo apt install -y postgresql postgresql-contrib

# Запуск
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Создание БД и пользователя
sudo -u postgres psql << EOF
CREATE USER foodtech WITH PASSWORD 'your_secure_password';
CREATE DATABASE foodtech_db OWNER foodtech;
GRANT ALL PRIVILEGES ON DATABASE foodtech_db TO foodtech;
\q
EOF
```

### Шаг 7: Установка Redis

```bash
sudo apt install -y redis-server
sudo systemctl enable redis-server
sudo systemctl start redis-server
```

### Шаг 8: Установка Nginx

```bash
sudo apt install -y nginx
sudo systemctl enable nginx
```

### Шаг 9: Клонирование проекта

```bash
sudo mkdir -p /opt/foodtech
cd /opt/foodtech
sudo git clone https://github.com/carman72tmn/foodtech.git .
```

### Шаг 10: Запуск установки

```bash
cd /opt/foodtech

# Настройка .env
cp .env.production .env
nano .env

# Запуск скрипта установки
sudo bash install-native.sh
```

Скрипт автоматически:
- Настроит Nginx
- Установит зависимости Laravel (composer install)
- Установит зависимости npm (npm install)
- Выполнит миграции
- Настроит права доступа

---

## 🔄 Вариант 3: Свежая установка

Если нужно полностью переустановить систему или возникли проблемы.

```bash
cd /opt/foodtech

# Этот скрипт:
# - Остановит все сервисы
# - Удалит старые данные (с подтверждением)
# - Переустановит все компоненты
# - Создаст новую БД
sudo bash install-fresh.sh
```

**⚠️ ВНИМАНИЕ**: Этот вариант удалит все существующие данные!

---

## ⚙️ Настройка окружения

### Структура файла .env

Откройте `/opt/foodtech/.env` и настройте:

```env
# ============================================
# Основные настройки
# ============================================
APP_NAME=DovezU
APP_ENV=production
APP_URL=https://your-domain.com  # Или http://your-server-ip

# ============================================
# База данных PostgreSQL
# ============================================
POSTGRES_USER=foodtech
POSTGRES_PASSWORD=ИЗМЕНИТЕ_НА_СИЛЬНЫЙ_ПАРОЛЬ
POSTGRES_DB=foodtech_db
POSTGRES_SERVER=localhost  # или postgres для Docker

# ============================================
# iiko Cloud Integration
# ============================================
IIKO_API_LOGIN=ваш_api_ключ_от_iiko
IIKO_API_BASE_URL=https://api-ru.iiko.services

# ============================================
# Telegram Bot
# ============================================
BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz

# ============================================
# Домен и SSL
# ============================================
DOMAIN=your-domain.com
EMAIL=admin@your-domain.com

# ============================================
# Redis (Опционально)
# ============================================
REDIS_HOST=localhost  # или redis для Docker
REDIS_PORT=6379
```

### Получение API ключа iiko

1. Зайдите на https://iiko.biz/
2. Войдите в админ-панель вашей организации
3. Перейдите в раздел "API" или "Интеграции"
4. Создайте новый API ключ
5. Скопируйте ключ в `IIKO_API_LOGIN`

Документация iiko API: https://api-ru.iiko.services/docs

### Создание Telegram бота

1. Откройте Telegram
2. Найдите @BotFather
3. Отправьте команду `/newbot`
4. Следуйте инструкциям:
   ```
   BotFather: Alright, a new bot. How are we going to call it?
   You: DovezU Food Bot

   BotFather: Good. Now let's choose a username for your bot.
   You: dovezu_food_bot

   BotFather: Done! Here's your token:
   123456789:ABCdefGHIjklMNOpqrsTUVwxyz
   ```
5. Скопируйте токен в `BOT_TOKEN`

### Настройка Laravel .env

Дополнительно нужно настроить `/opt/foodtech/admin/.env`:

```bash
cd /opt/foodtech/admin
cp .env.example .env
nano .env
```

Основные параметры:
```env
APP_NAME=FoodTech
APP_ENV=production
APP_KEY=base64:XXXXXX  # Генерируется автоматически
APP_DEBUG=false
APP_URL=http://your-domain.com

DB_CONNECTION=pgsql
DB_HOST=localhost  # или postgres для Docker
DB_PORT=5432
DB_DATABASE=foodtech_db
DB_USERNAME=foodtech
DB_PASSWORD=ваш_пароль

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
```

---

## 🔒 Настройка SSL

### Вариант 1: Let's Encrypt (Бесплатно, Автоматически)

```bash
# Установка certbot
sudo apt install -y certbot python3-certbot-nginx

# Получение сертификата
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Автопродление
sudo certbot renew --dry-run
```

### Вариант 2: Использование готового скрипта

```bash
cd /opt/foodtech
sudo bash setup-ssl.sh your-domain.com your-email@domain.com
```

### Проверка SSL

После установки SSL:
1. Откройте `https://your-domain.com`
2. Проверьте наличие замка в адресной строке
3. Проверьте рейтинг на https://www.ssllabs.com/ssltest/

---

## 🔗 Настройка интеграций

### iiko Cloud

1. **Авторизация**
   ```bash
   # Проверка подключения к iiko API
   curl -X POST https://api-ru.iiko.services/api/1/access_token \
     -H "Content-Type: application/json" \
     -d '{"apiLogin": "ваш_api_ключ"}'
   ```

2. **Синхронизация меню**
   - Откройте админ-панель: `http://your-domain.com/admin`
   - Перейдите в раздел "Меню"
   - Нажмите "Синхронизировать с iiko"

3. **Настройка организации**
   - В админке перейдите "Настройки" → "Интеграции"
   - Введите Organization ID из iiko
   - Настройте параметры синхронизации

### Telegram Bot

1. **Настройка webhook (опционально)**
   ```bash
   curl -X POST https://api.telegram.org/bot<YOUR_BOT_TOKEN>/setWebhook \
     -d "url=https://your-domain.com/api/v1/webhook"
   ```

2. **Запуск бота**
   ```bash
   # Docker
   docker compose restart bot
   docker compose logs -f bot

   # Native
   cd /opt/foodtech/bot
   python3 main.py
   ```

3. **Проверка работы**
   - Найдите своего бота в Telegram
   - Отправьте `/start`
   - Должно прийти приветственное сообщение

---

## ✅ Проверка работоспособности

### Веб-интерфейс

1. **Админ-панель**
   ```
   http://your-domain.com/admin
   Логин: admin@foodtech.ru
   Пароль: password (смените!)
   ```

2. **API Documentation**
   ```
   http://your-domain.com/api/v1/docs
   ```

3. **Health Check**
   ```bash
   curl http://your-domain.com/health
   # Должен вернуть: {"status": "ok"}
   ```

### Сервисы

```bash
# Docker
docker compose ps
# Все контейнеры должны быть "Up"

# Native
systemctl status nginx
systemctl status php8.2-fpm
systemctl status postgresql
systemctl status redis-server
```

### Логи

```bash
# Docker
docker compose logs -f admin    # Laravel
docker compose logs -f backend  # FastAPI
docker compose logs -f bot      # Telegram Bot

# Native
tail -f /opt/foodtech/admin/storage/logs/laravel.log
tail -f /var/log/nginx/error.log
sudo journalctl -u php8.2-fpm -f
```

### База данных

```bash
# Подключение к PostgreSQL
sudo -u postgres psql -d foodtech_db

# Проверка таблиц
\dt

# Проверка пользователей
SELECT * FROM users;

# Выход
\q
```

---

## 🔄 Обслуживание и обновление

### Резервное копирование

#### База данных
```bash
# Создание бэкапа
sudo -u postgres pg_dump foodtech_db > backup_$(date +%Y%m%d).sql

# Восстановление
sudo -u postgres psql foodtech_db < backup_20260219.sql
```

#### Файлы
```bash
# Бэкап всего проекта
tar -czf foodtech_backup_$(date +%Y%m%d).tar.gz /opt/foodtech

# Восстановление
tar -xzf foodtech_backup_20260219.tar.gz -C /
```

#### Автоматизация бэкапов
```bash
# Добавить в crontab
sudo crontab -e

# Ежедневный бэкап в 3:00
0 3 * * * /opt/foodtech/scripts/backup.sh
```

### Обновление системы

#### Docker установка
```bash
cd /opt/foodtech

# Получить обновления
git pull

# Пересобрать контейнеры
docker compose build --no-cache
docker compose up -d

# Выполнить миграции
docker compose exec admin php artisan migrate --force
```

#### Native установка
```bash
cd /opt/foodtech

# Получить обновления
git pull

# Admin Panel
cd admin
composer install --no-dev
npm install
npm run build
php artisan migrate --force
php artisan cache:clear

# Backend
cd ../backend
pip install -r requirements.txt

# Перезапуск сервисов
sudo systemctl restart php8.2-fpm nginx
```

### Мониторинг

#### Установка мониторинга
```bash
# htop для мониторинга ресурсов
sudo apt install -y htop

# netdata для веб-мониторинга
bash <(curl -Ss https://my-netdata.io/kickstart.sh)
```

#### Полезные команды
```bash
# Использование диска
df -h

# Использование памяти
free -h

# Загрузка процессора
top

# Сетевые подключения
netstat -tulpn

# Проверка портов
sudo lsof -i :80
sudo lsof -i :443
sudo lsof -i :8000
```

---

## 🔧 Решение проблем

### Проблема 1: Не запускается Docker контейнер

```bash
# Проверить логи
docker compose logs [service_name]

# Пересоздать контейнер
docker compose down
docker compose up -d --force-recreate [service_name]

# Проверить Docker
sudo systemctl status docker
docker info
```

### Проблема 2: 500 Internal Server Error

```bash
# Laravel
cd /opt/foodtech/admin
php artisan config:clear
php artisan cache:clear
php artisan view:clear

# Проверить права
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache

# Проверить логи
tail -f storage/logs/laravel.log
```

### Проблема 3: Ошибка подключения к БД

```bash
# Проверить PostgreSQL
sudo systemctl status postgresql

# Проверить подключение
psql -U foodtech -d foodtech_db -h localhost

# Проверить пароль в .env
grep POSTGRES /opt/foodtech/.env
```

### Проблема 4: Не работает Telegram бот

```bash
# Проверить токен
curl https://api.telegram.org/bot<YOUR_TOKEN>/getMe

# Проверить логи бота
docker compose logs -f bot  # Docker
# или
journalctl -u foodtech-bot  # Native

# Перезапустить бота
docker compose restart bot
```

### Проблема 5: iiko API не отвечает

```bash
# Проверить API ключ
curl -X POST https://api-ru.iiko.services/api/1/access_token \
  -H "Content-Type: application/json" \
  -d '{"apiLogin": "ваш_ключ"}'

# Проверить логи backend
docker compose logs -f backend

# Проверить сетевое подключение
curl -I https://api-ru.iiko.services
```

### Проблема 6: Nginx не запускается

```bash
# Проверить конфигурацию
sudo nginx -t

# Проверить логи
sudo tail -f /var/log/nginx/error.log

# Перезапустить
sudo systemctl restart nginx

# Проверить порты
sudo lsof -i :80
sudo lsof -i :443
```

### Более подробные решения

См. [FIXES_README.md](FIXES_README.md) для дополнительных инструкций.

---

## 📞 Поддержка

### Документация
- [README.md](README.md) - Общая информация
- [ARCHITECTURE.md](ARCHITECTURE.md) - Архитектура системы
- [AI_INSTRUCTIONS.md](AI_INSTRUCTIONS.md) - Для AI ассистентов
- [FIXES_README.md](FIXES_README.md) - Решение проблем

### Полезные ссылки
- [Laravel Documentation](https://laravel.com/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [aiogram Documentation](https://docs.aiogram.dev)
- [iiko API Documentation](https://api-ru.iiko.services/docs)

### GitHub
- Issues: https://github.com/carman72tmn/foodtech/issues
- Discussions: https://github.com/carman72tmn/foodtech/discussions

---

## 🎓 Дополнительные рекомендации

### Безопасность

1. **Используйте сильные пароли**
   - Минимум 16 символов
   - Комбинация букв, цифр, символов
   - Разные пароли для разных сервисов

2. **Настройте файрвол**
   ```bash
   sudo ufw enable
   sudo ufw allow 22/tcp   # SSH
   sudo ufw allow 80/tcp   # HTTP
   sudo ufw allow 443/tcp  # HTTPS
   ```

3. **Регулярно обновляйте систему**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

4. **Настройте fail2ban**
   ```bash
   sudo apt install -y fail2ban
   sudo systemctl enable fail2ban
   ```

### Производительность

1. **Включите opcache для PHP**
   ```ini
   # /etc/php/8.2/fpm/conf.d/10-opcache.ini
   opcache.enable=1
   opcache.memory_consumption=256
   ```

2. **Настройте Redis**
   ```bash
   # /etc/redis/redis.conf
   maxmemory 512mb
   maxmemory-policy allkeys-lru
   ```

3. **Оптимизируйте PostgreSQL**
   ```bash
   # /etc/postgresql/15/main/postgresql.conf
   shared_buffers = 512MB
   effective_cache_size = 2GB
   ```

---

**Готово!** Ваша система DovezU должна быть полностью настроена и готова к работе.

Если возникли проблемы, обратитесь к разделу [Решение проблем](#решение-проблем) или откройте Issue на GitHub.

---

*Последнее обновление: 2026-02-19*
