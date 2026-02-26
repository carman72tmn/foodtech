# Шаг 4: Развертывание Admin Panel (Vue)

## 4.1 Подготовка директории

```bash
# Переходим в директорию admin
cd /opt/foodtech/admin
```

## 4.2 Установка зависимостей NPM

```bash
# Устанавливаем зависимости
npm install

# Собираем билд для продакшена
npm run build
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
VITE_API_URL=http://localhost:8000/api/v1
```

## 4.5 Настройка директорий

```bash
# Настраиваем права доступа
sudo chown -R www-data:www-data /opt/foodtech/admin/dist
sudo chmod -R 755 /opt/foodtech/admin/dist
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
    root /opt/foodtech/admin/dist;

    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

**Или копируем готовый файл:**

```bash
sudo cp /opt/foodtech/configs/nginx/admin.conf /etc/nginx/sites-available/foodtech-admin
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

## 4.14 Проверка работы

```bash
# Откройте в браузере:
# https://admin.yourdomain.com

# Вы должны увидеть страницу входа панели администратора
```

## Следующий шаг

Переходите к [05_bot_deployment.md](05_bot_deployment.md) для развертывания Telegram бота.
