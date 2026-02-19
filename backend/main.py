from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.core.config import settings
from app.core.database import init_db
from app.api.endpoints import menu, orders, loyalty

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Запуск: Создание таблиц БД
    await init_db()
    
    # Фоновая задача: мониторинг заказов
    from app.services.order_monitor import OrderMonitor
    import asyncio
    
    async def monitor_orders():
        monitor = OrderMonitor()
        while True:
            try:
                await monitor.check_active_orders()
            except Exception as e:
                print(f"Ошибка в мониторе заказов: {e}")
            await asyncio.sleep(30) # Проверка каждые 30 секунд

    task = asyncio.create_task(monitor_orders())
    
    yield
    
    # Завершение работы
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        pass

app = FastAPI(
    title=settings.PROJECT_NAME,
    lifespan=lifespan,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

app.include_router(menu.router, prefix=f"{settings.API_V1_STR}/menu", tags=["menu"])
app.include_router(orders.router, prefix=f"{settings.API_V1_STR}/orders", tags=["orders"])
app.include_router(loyalty.router, prefix=f"{settings.API_V1_STR}/loyalty", tags=["loyalty"])

@app.get("/")
def root():
    return {"message": f"Welcome to {settings.PROJECT_NAME} API"}

@app.get("/health")
def health_check():
    return {"status": "ok"}
