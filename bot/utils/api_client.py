"""
Утилиты для работы с Backend API
"""
import httpx
from typing import List, Dict, Any, Optional
from config import settings


class APIClient:
    """Клиент для взаимодействия с Backend API"""

    def __init__(self):
        self.base_url = settings.API_URL

    async def get_categories(self, is_active: bool = True) -> List[Dict[str, Any]]:
        """Получить список категорий"""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/categories/",
                params={"is_active": is_active}
            )
            response.raise_for_status()
            return response.json()

    async def get_products(
        self,
        category_id: Optional[int] = None,
        is_available: bool = True
    ) -> List[Dict[str, Any]]:
        """Получить список товаров"""
        params = {"is_available": is_available}
        if category_id:
            params["category_id"] = category_id

        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/products/",
                params=params
            )
            response.raise_for_status()
            return response.json()

    async def get_product(self, product_id: int) -> Dict[str, Any]:
        """Получить товар по ID"""
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.base_url}/products/{product_id}")
            response.raise_for_status()
            return response.json()

    async def create_order(self, order_data: Dict[str, Any]) -> Dict[str, Any]:
        """Создать новый заказ"""
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{self.base_url}/orders/",
                json=order_data
            )
            response.raise_for_status()
            return response.json()

    async def get_user_orders(self, telegram_user_id: int) -> List[Dict[str, Any]]:
        """Получить заказы пользователя"""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/orders/",
                params={"telegram_user_id": telegram_user_id}
            )
            response.raise_for_status()
            return response.json()

    async def get_order(self, order_id: int) -> Dict[str, Any]:
        """Получить заказ по ID"""
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.base_url}/orders/{order_id}")
            response.raise_for_status()
            return response.json()


# Глобальный экземпляр клиента
api_client = APIClient()
