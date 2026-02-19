"""
Сервис для интеграции с iiko Cloud API
Документация API: https://api-ru.iiko.services/
"""
import httpx
from typing import Optional, Dict, List, Any
from datetime import datetime, timedelta
from app.core.config import settings


class IikoService:
    """Сервис для работы с iiko Cloud API"""

    def __init__(self):
        self.api_url = settings.IIKO_API_URL
        self.api_login = settings.IIKO_API_LOGIN
        self.organization_id = settings.IIKO_ORGANIZATION_ID
        self.access_token: Optional[str] = None
        self.token_expires_at: Optional[datetime] = None

    async def _get_access_token(self) -> str:
        """
        Получение токена доступа к iiko API
        Токен действителен несколько минут, поэтому кешируем его
        """
        # Проверяем, есть ли валидный токен
        if self.access_token and self.token_expires_at:
            if datetime.utcnow() < self.token_expires_at:
                return self.access_token

        # Получаем новый токен
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.api_url}/api/1/access_token",
                json={"apiLogin": self.api_login}
            )
            response.raise_for_status()
            data = response.json()

            self.access_token = data["token"]
            # Токен действителен 5 минут, оставляем запас 1 минута
            self.token_expires_at = datetime.utcnow() + timedelta(minutes=4)

            return self.access_token

    async def get_nomenclature(self) -> Dict[str, Any]:
        """
        Получение номенклатуры (меню) из iiko
        Возвращает категории и товары
        """
        token = await self._get_access_token()

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.api_url}/api/1/nomenclature",
                headers={"Authorization": f"Bearer {token}"},
                json={"organizationId": self.organization_id}
            )
            response.raise_for_status()
            return response.json()

    async def get_organization_info(self) -> Dict[str, Any]:
        """Получение информации об организации"""
        token = await self._get_access_token()

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.api_url}/api/1/organizations",
                headers={"Authorization": f"Bearer {token}"},
                json={"organizationIds": [self.organization_id]}
            )
            response.raise_for_status()
            data = response.json()
            return data["organizations"][0] if data.get("organizations") else {}

    async def create_delivery_order(
        self,
        customer_name: str,
        customer_phone: str,
        address: str,
        items: List[Dict[str, Any]],
        comment: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Создание заказа доставки в iiko

        Args:
            customer_name: Имя клиента
            customer_phone: Телефон клиента
            address: Адрес доставки
            items: Список товаров [{product_id, quantity, price}]
            comment: Комментарий к заказу

        Returns:
            Dict с информацией о созданном заказе
        """
        token = await self._get_access_token()

        # Формируем заказ в формате iiko
        order_data = {
            "organizationId": self.organization_id,
            "order": {
                "customer": {
                    "name": customer_name,
                    "phone": customer_phone
                },
                "deliveryPoint": {
                    "address": {
                        "street": {
                            "name": address
                        }
                    }
                },
                "items": [
                    {
                        "productId": item["product_id"],
                        "amount": item["quantity"],
                        "price": float(item["price"])
                    }
                    for item in items
                ],
                "comment": comment or ""
            }
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{self.api_url}/api/1/deliveries/create",
                headers={"Authorization": f"Bearer {token}"},
                json=order_data
            )
            response.raise_for_status()
            return response.json()

    async def get_order_status(self, order_id: str) -> Dict[str, Any]:
        """
        Получение статуса заказа из iiko

        Args:
            order_id: ID заказа в iiko

        Returns:
            Dict со статусом заказа
        """
        token = await self._get_access_token()

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.api_url}/api/1/deliveries/by_id",
                headers={"Authorization": f"Bearer {token}"},
                json={
                    "organizationIds": [self.organization_id],
                    "orderIds": [order_id]
                }
            )
            response.raise_for_status()
            data = response.json()
            return data["orders"][0] if data.get("orders") else {}

    async def cancel_order(self, order_id: str) -> bool:
        """
        Отмена заказа в iiko

        Args:
            order_id: ID заказа в iiko

        Returns:
            True если отменен успешно
        """
        token = await self._get_access_token()

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.api_url}/api/1/deliveries/cancel",
                headers={"Authorization": f"Bearer {token}"},
                json={
                    "organizationId": self.organization_id,
                    "orderId": order_id
                }
            )
            return response.status_code == 200


# Глобальный экземпляр сервиса
iiko_service = IikoService()
