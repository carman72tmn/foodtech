"""
Настройка подключения к базе данных PostgreSQL
Использует SQLModel (построен на SQLAlchemy 2.0)
"""
from sqlmodel import Session, create_engine
from sqlalchemy.orm import sessionmaker
from .config import settings

# Создание движка базы данных
# echo=True выводит SQL запросы в консоль (только для отладки)
engine = create_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_pre_ping=True,  # Проверка соединения перед использованием
    pool_size=5,  # Количество постоянных соединений в пуле
    max_overflow=10  # Максимальное количество дополнительных соединений
)

# Фабрика сессий
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
    class_=Session
)


def get_session():
    """
    Dependency для получения сессии базы данных в FastAPI endpoints
    Автоматически закрывает сессию после завершения запроса
    """
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()
