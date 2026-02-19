# Шаг 3: Развертывание Backend API (FastAPI)

## 3.1 Подготовка директории

```bash
# Создаем директорию для приложения
sudo mkdir -p /opt/foodtech
cd /opt/foodtech

# Клонируем репозиторий (или копируем файлы)
# sudo git clone https://github.com/carman72tmn/foodtech.git .
# Или копируем файлы из локальной директории

# Переходим в директорию backend
cd backend
```

## 3.2 Создание виртуального окружения

```bash
# Создаем виртуальное окружение Python
python3 -m venv venv

# Активируем виртуальное окружение
source venv/bin/activate

# Обновляем pip
pip install --upgrade pip
```

## 3.3 Установка зависимостей

```bash
# Устанавливаем зависимости из requirements.txt
pip install -r requirements.txt

# Проверка установки
pip list
```

## 3.4 Настройка окружения

```bash
# Копируем файл с примером переменных окружения
cp .env.example .env

# Редактируем .env файл
nano .env
```

**Важные переменные в .env:**

```ini
# База данных (используйте пароль из шага 2)
DATABASE_URL=postgresql://foodtech_user:your_strong_password_here@localhost:5432/foodtech_db

# Секретный ключ для JWT (сгенерируйте новый!)
SECRET_KEY=your-very-long-random-secret-key-change-this

# iiko API (получите в личном кабинете iiko)
IIKO_API_LOGIN=your_iiko_api_login
IIKO_ORGANIZATION_ID=your_organization_id

# Режим отладки (для продакшена - False)
DEBUG=False
```

**Генерация SECRET_KEY:**

```bash
# Способ 1: OpenSSL
openssl rand -hex 32

# Способ 2: Python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

## 3.5 Инициализация базы данных

```bash
# Убедитесь, что виртуальное окружение активно
source venv/bin/activate

# Создаем таблицы в БД
python init_db.py

# Должно вывести: "✓ Все таблицы созданы успешно!"
```

## 3.6 Тестовый запуск

```bash
# Запускаем API для проверки
python main.py

# API должно запуститься на http://0.0.0.0:8000
# Откройте в браузере: http://your-server-ip:8000/docs
# Вы должны увидеть Swagger UI с документацией API

# Остановите сервер: Ctrl+C
```

## 3.7 Создание systemd сервиса

```bash
# Создаем файл сервиса
sudo nano /etc/systemd/system/foodtech-api.service
```

**Содержимое файла (уже подготовлено в configs/systemd/foodtech-api.service):**

```ini
[Unit]
Description=FoodTech FastAPI Backend
After=network.target postgresql.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/foodtech/backend
Environment="PATH=/opt/foodtech/backend/venv/bin"
ExecStart=/opt/foodtech/backend/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Или копируем готовый файл:**

```bash
sudo cp /opt/foodtech/configs/systemd/foodtech-api.service /etc/systemd/system/
```

## 3.8 Настройка прав доступа

```bash
# Меняем владельца директории на www-data
sudo chown -R www-data:www-data /opt/foodtech/backend

# Делаем .env файл доступным только для владельца
sudo chmod 600 /opt/foodtech/backend/.env
```

## 3.9 Запуск сервиса

```bash
# Перезагружаем systemd
sudo systemctl daemon-reload

# Включаем автозапуск
sudo systemctl enable foodtech-api

# Запускаем сервис
sudo systemctl start foodtech-api

# Проверяем статус
sudo systemctl status foodtech-api

# Должно показать "active (running)"
```

## 3.10 Проверка логов

```bash
# Просмотр логов в реальном времени
sudo journalctl -u foodtech-api -f

# Последние 50 строк логов
sudo journalctl -u foodtech-api -n 50

# Логи за последний час
sudo journalctl -u foodtech-api --since "1 hour ago"
```

## 3.11 Полезные команды

```bash
# Перезапуск сервиса
sudo systemctl restart foodtech-api

# Остановка сервиса
sudo systemctl stop foodtech-api

# Проверка статуса
sudo systemctl status foodtech-api
```

## 3.12 Тестирование API

```bash
# Проверка здоровья API
curl http://localhost:8000/health

# Должен вернуть: {"status":"healthy","database":"connected"}

# Получение списка категорий (должен вернуть пустой массив)
curl http://localhost:8000/api/v1/categories/
```

## Следующий шаг

Переходите к [04_admin_deployment.md](04_admin_deployment.md) для развертывания админ-панели Laravel.
