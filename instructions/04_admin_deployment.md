# Шаг 4: Развертывание Admin Panel (Laravel + Filament)

## 4.1 Подготовка директории

```bash
# Переходим в директорию admin-panel
cd /opt/foodtech/admin-panel
```

## 4.2 Установка зависимостей Composer

```bash
# Устанавливаем зависимости (без dev-пакетов для продакшена)
composer install --no-dev --optimize-autoloader

# Это может занять несколько минут
```

## 4.3 Настройка окружения

```bash
# Копируем файл с примером переменных окружения
cp .env.example .env

# Редактируем .env файл
nano .env
```

**Важные переменные в .env:**

```ini
APP_NAME=FoodTech
APP_ENV=production
APP_DEBUG=false
APP_URL=https://admin.yourdomain.com

# База данных (те же данные, что и для Backend)
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=foodtech_db
DB_USERNAME=foodtech_user
DB_PASSWORD=your_strong_password_here

# URL Backend API
API_URL=http://localhost:8000/api/v1
```

## 4.4 Генерация ключа приложения

```bash
# Генерируем APP_KEY
php artisan key:generate

# Ключ автоматически добавится в .env
```

## 4.5 Настройка директорий

```bash
# Создаем необходимые директории
mkdir -p storage/framework/{sessions,views,cache}
mkdir -p storage/logs
mkdir -p bootstrap/cache

# Настраиваем права доступа
sudo chown -R www-data:www-data /opt/foodtech/admin-panel
sudo chmod -R 755 /opt/foodtech/admin-panel
sudo chmod -R 775 /opt/foodtech/admin-panel/storage
sudo chmod -R 775 /opt/foodtech/admin-panel/bootstrap/cache
```

## 4.6 Запуск миграций

```bash
# Запускаем миграции Laravel
php artisan migrate --force

# Публикуем ассеты Filament
php artisan filament:assets
```

## 4.7 Создание администратора

```bash
# Создаем первого пользователя-администратора для Filament
php artisan make:filament-user

# Введите:
# - Name: Admin
# - Email: admin@foodtech.com
# - Password: (выберите надежный пароль)
```

## 4.8 Оптимизация для продакшена

```bash
# Кэшируем конфигурацию
php artisan config:cache

# Кэшируем маршруты
php artisan route:cache

# Кэшируем views
php artisan view:cache

# Оптимизируем автозагрузку
composer dump-autoload --optimize
```

## 4.9 Настройка Nginx для админ-панели

```bash
# Создаем конфигурацию Nginx
sudo nano /etc/nginx/sites-available/foodtech-admin
```

**Содержимое файла:**

```nginx
server {
    listen 80;
    server_name admin.yourdomain.com;
    root /opt/foodtech/admin-panel/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

**Или копируем готовый файл:**

```bash
sudo cp /opt/foodtech/configs/nginx/admin-panel.conf /etc/nginx/sites-available/foodtech-admin
```

## 4.10 Активация сайта

```bash
# Создаем символическую ссылку
sudo ln -s /etc/nginx/sites-available/foodtech-admin /etc/nginx/sites-enabled/

# Проверяем конфигурацию Nginx
sudo nginx -t

# Должно показать "syntax is ok" и "test is successful"

# Перезагружаем Nginx
sudo systemctl reload nginx
```

## 4.11 Настройка SSL с Certbot

```bash
# Получаем SSL сертификат от Let's Encrypt
sudo certbot --nginx -d admin.yourdomain.com

# Следуйте инструкциям:
# 1. Введите email для уведомлений
# 2. Согласитесь с условиями
# 3. Выберите опцию перенаправления HTTP на HTTPS (рекомендуется)

# Certbot автоматически настроит HTTPS и обновит конфигурацию Nginx
```

## 4.12 Настройка автообновления сертификата

```bash
# Проверяем, что certbot добавлен в cron
sudo systemctl status certbot.timer

# Тестируем автообновление
sudo certbot renew --dry-run
```

## 4.13 Настройка PHP-FPM (опционально)

```bash
# Оптимизируем настройки PHP-FPM для продакшена
sudo nano /etc/php/8.2/fpm/pool.d/www.conf

# Найдите и измените:
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35

# Перезапускаем PHP-FPM
sudo systemctl restart php8.2-fpm
```

## 4.14 Проверка работы

```bash
# Откройте в браузере:
# https://admin.yourdomain.com

# Вы должны увидеть страницу входа Filament
# Войдите с данными администратора, которые создали ранее
```

## 4.15 Планировщик задач Laravel

```bash
# Добавляем планировщик в crontab
sudo crontab -e -u www-data

# Добавьте строку:
* * * * * cd /opt/foodtech/admin-panel && php artisan schedule:run >> /dev/null 2>&1
```

## 4.16 Полезные команды

```bash
# Очистка кэша
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Просмотр логов
tail -f /opt/foodtech/admin-panel/storage/logs/laravel.log

# Просмотр логов Nginx
sudo tail -f /var/log/nginx/error.log
```

## Следующий шаг

Переходите к [05_bot_deployment.md](05_bot_deployment.md) для развертывания Telegram бота.
