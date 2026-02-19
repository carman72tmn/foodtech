# Шаг 1: Подготовка сервера Ubuntu

Это руководство для чистой установки Ubuntu 22.04 LTS или 24.04 LTS.

## 1.1 Обновление системы

```bash
# Обновляем списки пакетов
sudo apt update

# Устанавливаем обновления
sudo apt upgrade -y

# Устанавливаем основные утилиты
sudo apt install -y software-properties-common curl git wget zip unzip
```

## 1.2 Установка Python 3.11+

```bash
# Проверяем версию Python (должна быть 3.11 или выше)
python3 --version

# Если версия ниже 3.11, устанавливаем последнюю
sudo apt install -y python3 python3-pip python3-venv python3-dev

# Проверяем установку
python3 --version
pip3 --version
```

## 1.3 Установка PHP 8.2

```bash
# Добавляем репозиторий Ondrej для PHP
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

# Устанавливаем PHP 8.2 и необходимые расширения
sudo apt install -y php8.2 php8.2-fpm php8.2-cli php8.2-common \
    php8.2-pgsql php8.2-curl php8.2-xml php8.2-mbstring \
    php8.2-zip php8.2-bcmath php8.2-gd php8.2-intl

# Проверяем установку
php -v
```

## 1.4 Установка Composer

```bash
# Скачиваем установщик Composer
curl -sS https://getcomposer.org/installer -o composer-setup.php

# Устанавливаем Composer глобально
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Удаляем установщик
rm composer-setup.php

# Проверяем установку
composer --version
```

## 1.5 Установка PostgreSQL

```bash
# Устанавливаем PostgreSQL 15
sudo apt install -y postgresql postgresql-contrib

# Проверяем статус
sudo systemctl status postgresql

# PostgreSQL автоматически запускается после установки
```

## 1.6 Установка Nginx

```bash
# Устанавливаем Nginx
sudo apt install -y nginx

# Проверяем статус
sudo systemctl status nginx

# Включаем автозапуск
sudo systemctl enable nginx
```

## 1.7 Установка Redis (опционально, для кэширования)

```bash
# Устанавливаем Redis
sudo apt install -y redis-server

# Проверяем статус
sudo systemctl status redis-server

# Включаем автозапуск
sudo systemctl enable redis-server
```

## 1.8 Настройка Firewall (UFW)

```bash
# Разрешаем SSH (важно! иначе потеряете доступ)
sudo ufw allow OpenSSH

# Разрешаем HTTP и HTTPS
sudo ufw allow 'Nginx Full'

# Включаем firewall
sudo ufw enable

# Проверяем статус
sudo ufw status
```

## 1.9 Установка Certbot для SSL

```bash
# Устанавливаем Certbot
sudo apt install -y certbot python3-certbot-nginx

# Сертификаты будем получать позже, после настройки Nginx
```

## Проверка установки

```bash
# Все команды должны вернуть версии:
python3 --version      # Python 3.11+
php -v                 # PHP 8.2+
composer --version     # Composer 2.x
psql --version         # PostgreSQL 15+
nginx -v               # Nginx 1.x
redis-cli --version    # Redis 7.x
```

## Следующий шаг

Переходите к [02_database_setup.md](02_database_setup.md) для настройки базы данных.
