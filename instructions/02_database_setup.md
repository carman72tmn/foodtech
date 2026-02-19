# Шаг 2: Настройка базы данных PostgreSQL

## 2.1 Вход в PostgreSQL

```bash
# Входим в PostgreSQL от имени пользователя postgres
sudo -u postgres psql
```

## 2.2 Создание базы данных и пользователя

Выполните следующие команды в консоли PostgreSQL:

```sql
-- Создаем пользователя для приложения
CREATE USER foodtech_user WITH PASSWORD 'your_strong_password_here';

-- Создаем базу данных
CREATE DATABASE foodtech_db OWNER foodtech_user;

-- Даем права пользователю
GRANT ALL PRIVILEGES ON DATABASE foodtech_db TO foodtech_user;

-- Подключаемся к созданной БД
\c foodtech_db

-- Даем права на схему public
GRANT ALL ON SCHEMA public TO foodtech_user;

-- Выходим из psql
\q
```

## 2.3 Проверка подключения

```bash
# Проверяем, что можем подключиться к БД
psql -U foodtech_user -d foodtech_db -h localhost -W

# Введите пароль, который указали выше
# Если подключение успешно, вы увидите приглашение psql

# Выйдите из psql
\q
```

## 2.4 Настройка доступа (опционально)

Если вы планируете подключаться к БД с других машин:

```bash
# Редактируем конфигурацию PostgreSQL
sudo nano /etc/postgresql/15/main/postgresql.conf

# Находим строку listen_addresses и меняем на:
listen_addresses = 'localhost'  # Или '*' для всех интерфейсов (не рекомендуется)

# Редактируем pg_hba.conf для разрешения локальных подключений
sudo nano /etc/postgresql/15/main/pg_hba.conf

# Убедитесь, что есть строка:
# local   all             all                                     md5

# Перезапускаем PostgreSQL
sudo systemctl restart postgresql
```

## 2.5 Создание таблиц

Таблицы будут созданы автоматически при первом запуске Backend API через скрипт `init_db.py` или миграции Alembic.

## Структура базы данных

База данных будет содержать следующие таблицы:

- **users** - Пользователи системы (для админ-панели)
- **categories** - Категории товаров
- **products** - Товары/блюда
- **orders** - Заказы
- **order_items** - Позиции заказов

## Важные заметки

⚠️ **БЕЗОПАСНОСТЬ:**
- Используйте сложный пароль для пользователя БД
- Сохраните пароль в безопасном месте
- Не используйте пользователя `postgres` для приложений
- Регулярно делайте резервные копии БД

## Резервное копирование

```bash
# Создание бэкапа
pg_dump -U foodtech_user -d foodtech_db -F c -f /backup/foodtech_$(date +%Y%m%d).dump

# Восстановление из бэкапа
pg_restore -U foodtech_user -d foodtech_db -c /backup/foodtech_YYYYMMDD.dump
```

## Следующий шаг

Переходите к [03_backend_deployment.md](03_backend_deployment.md) для развертывания Backend API.
