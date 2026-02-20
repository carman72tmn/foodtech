"""
Сервис для интеграции с iiko Cloud API
Документация API: https://api-ru.iiko.services/
"""
import httpx
import asyncio
import logging
from typing import Optional, Dict, List, Any
from datetime import datetime, timedelta
from app.core.config import settings

logger = logging.getLogger(__name__)


class IikoService:
    """Сервис для работы с iiko Cloud API"""

    def __init__(self):
        self.api_url = settings.IIKO_API_URL
        self.api_login = settings.IIKO_API_LOGIN
        self.organization_id = settings.IIKO_ORGANIZATION_ID
        self.access_token: Optional[str] = None
        self.token_expires_at: Optional[datetime] = None

    # =========================================================================
    # Аутентификация
    # =========================================================================

    async def _get_access_token(self, api_login: Optional[str] = None) -> str:
        """
        Получение токена доступа к iiko API
        """
        login = api_login or self.api_login
        if login:
            login = login.strip()

        # Если просим тот же логин, что и в кеше, и он не протух — возвращаем
        if not api_login and self.access_token and self.token_expires_at:
            if datetime.utcnow() < self.token_expires_at:
                return self.access_token

        masked_login = f"{login[:4]}...{login[-4:]}" if login and len(login) > 8 else "INVALID"
        logger.info(f"Requesting iiko access token with login: {masked_login}")

        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{self.api_url}/api/1/access_token",
                    json={"apiLogin": login}
                )
                response.raise_for_status()
                data = response.json()

                token = data["token"]
                
                # Кешируем только если это "глобальный" логин
                if not api_login:
                    self.access_token = token
                    self.token_expires_at = datetime.utcnow() + timedelta(minutes=14)

                return token
            except httpx.HTTPStatusError as e:
                logger.error(f"Failed to get access token: {e.response.text}")
                raise

    async def _request(
        self,
        method: str,
        endpoint: str,
        json_data: Optional[Dict] = None,
        timeout: float = 30.0,
        api_login: Optional[str] = None,
        organization_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """Универсальный метод для запросов к iiko API с авторизацией"""
        token = await self._get_access_token(api_login=api_login)
        org_id = organization_id or self.organization_id

        # Если в json_data есть organizationId или organizationIds - подменяем если передали organization_id
        if json_data and org_id:
            if "organizationId" in json_data:
                json_data["organizationId"] = org_id
            if "organizationIds" in json_data and isinstance(json_data["organizationIds"], list):
                if not json_data["organizationIds"] or len(json_data["organizationIds"]) == 1:
                    json_data["organizationIds"] = [org_id]

        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.request(
                method,
                f"{self.api_url}{endpoint}",
                headers={"Authorization": f"Bearer {token}"},
                json=json_data
            )
            response.raise_for_status()
            return response.json()

    # =========================================================================
    # Проверка подключения
    # =========================================================================

    async def test_connection(
        self,
        api_login: Optional[str] = None,
        organization_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Проверка подключения к iiko API
        """
        try:
            token = await self._get_access_token(api_login=api_login)
            orgs = await self._request(
                "POST", 
                "/api/1/organizations", 
                {"organizationIds": [], "returnAdditionalInfo": False},
                api_login=api_login,
                organization_id=organization_id
            )
            return {
                "success": True,
                "token_valid": bool(token),
                "organizations": orgs.get("organizations", [])
            }
        except Exception as e:
            logger.error(f"iiko connection test failed: {e}")
            return {
                "success": False,
                "error": str(e)
            }

    # =========================================================================
    # Организация и справочники
    # =========================================================================

    async def get_organizations(
        self,
        api_login: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Получение списка всех организаций"""
        data = await self._request(
            "POST", "/api/1/organizations", 
            {"organizationIds": [], "returnAdditionalInfo": True},
            api_login=api_login
        )
        return data.get("organizations", [])

    async def get_organization_info(
        self,
        api_login: Optional[str] = None,
        organization_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """Получение информации о текущей организации"""
        org_id = organization_id or self.organization_id
        data = await self._request(
            "POST", "/api/1/organizations", 
            {"organizationIds": [org_id], "returnAdditionalInfo": True},
            api_login=api_login,
            organization_id=org_id
        )
        return data["organizations"][0] if data.get("organizations") else {}

    async def get_terminal_groups(
        self,
        api_login: Optional[str] = None,
        organization_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Получение списка терминальных групп"""
        org_id = organization_id or self.organization_id
        data = await self._request(
            "POST", "/api/1/terminal_groups", 
            {"organizationIds": [org_id]},
            api_login=api_login,
            organization_id=org_id
        )
        groups = data.get("terminalGroups", [])
        result = []
        for org_group in groups:
            for item in org_group.get("items", []):
                result.append(item)
        return result

    async def get_payment_types(
        self,
        api_login: Optional[str] = None,
        organization_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Получение типов оплаты"""
        org_id = organization_id or self.organization_id
        data = await self._request(
            "POST", "/api/1/payment_types", 
            {"organizationIds": [org_id]},
            api_login=api_login,
            organization_id=org_id
        )
        types = data.get("paymentTypes", [])
        result = []
        for org_types in types:
            for item in org_types.get("items", []):
                result.append(item)
        return result

    async def get_order_types(
        self,
        api_login: Optional[str] = None,
        organization_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Получение типов заказа"""
        org_id = organization_id or self.organization_id
        data = await self._request(
            "POST", "/api/1/deliveries/order_types", 
            {"organizationIds": [org_id]},
            api_login=api_login,
            organization_id=org_id
        )
        types = data.get("orderTypes", [])
        result = []
        for org_types in types:
            for item in org_types.get("items", []):
                result.append(item)
        return result

    async def get_discount_types(
        self,
        api_login: Optional[str] = None,
        organization_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Получение доступных типов скидок"""
        org_id = organization_id or self.organization_id
        data = await self._request(
            "POST", "/api/1/discounts", 
            {"organizationIds": [org_id]},
            api_login=api_login,
            organization_id=org_id
        )
        discounts = data.get("discounts", [])
        result = []
        for org_disc in discounts:
            for item in org_disc.get("items", []):
                result.append(item)
        return result

    # =========================================================================
    # Меню и номенклатура
    # =========================================================================

    async def get_nomenclature(self) -> Dict[str, Any]:
        """
        Получение номенклатуры (меню) из iiko
        Возвращает категории (groups) и товары (products)
        """
        return await self._request("POST", "/api/1/nomenclature", {
            "organizationId": self.organization_id
        })

    async def get_external_menus(
        self,
        api_login: Optional[str] = None,
        organization_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Получение списка внешних меню
        """
        org_id = organization_id or self.organization_id
        data = await self._request(
            "POST", "/api/2/menu", 
            {"organizationIds": [org_id]},
            api_login=api_login,
            organization_id=org_id
        )
        return data.get("externalMenus", [])

    async def get_external_menu_by_id(self, external_menu_id: str, price_category_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Получение конкретного внешнего меню по ID

        Args:
            external_menu_id: ID внешнего меню
            price_category_id: ID ценовой категории (опционально)
        """
        payload: Dict[str, Any] = {
            "externalMenuId": external_menu_id,
            "organizationIds": [self.organization_id]
        }
        if price_category_id:
            payload["priceCategoryId"] = price_category_id

        return await self._request("POST", "/api/2/menu/by_id", payload)

    # =========================================================================
    # Стоп-листы
    # =========================================================================

    async def get_stop_lists(self) -> List[Dict[str, Any]]:
        """
        Получение стоп-листов (недоступные позиции)

        Возвращает список продуктов, которые временно недоступны.
        """
        data = await self._request("POST", "/api/1/stop_lists", {
            "organizationIds": [self.organization_id]
        })
        stop_list_items = []
        for org_stop in data.get("terminalGroupStopLists", []):
            for tg in org_stop.get("items", []):
                for item in tg.get("items", []):
                    stop_list_items.append({
                        "productId": item.get("productId"),
                        "balance": item.get("balance", 0)
                    })
        return stop_list_items

    # =========================================================================
    # Заказы
    # =========================================================================

    async def create_delivery_order(
        self,
        customer_name: str,
        customer_phone: str,
        address: str,
        items: List[Dict[str, Any]],
        comment: Optional[str] = None,
        payment_type_id: Optional[str] = None,
        payment_sum: Optional[float] = None,
        discount_info: Optional[Dict] = None,
        terminal_group_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Создание заказа доставки в iiko с retry-логикой

        При неудаче — повтор через 15 секунд (до 3 раз).
        """
        order_data: Dict[str, Any] = {
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

        if terminal_group_id:
            order_data["terminalGroupId"] = terminal_group_id

        # Добавляем оплату
        if payment_type_id and payment_sum:
            order_data["order"]["payments"] = [{
                "paymentTypeKind": "Cash",
                "paymentTypeId": payment_type_id,
                "sum": payment_sum,
                "isProcessedExternally": False
            }]

        # Добавляем скидку
        if discount_info:
            order_data["order"]["discountsInfo"] = discount_info

        # Retry логика: до 3 попыток с интервалом 15 секунд
        last_error = None
        for attempt in range(3):
            try:
                result = await self._request(
                    "POST",
                    "/api/1/deliveries/create",
                    order_data,
                    timeout=30.0
                )
                return result
            except Exception as e:
                last_error = e
                logger.warning(
                    f"Order delivery attempt {attempt + 1}/3 failed: {e}"
                )
                if attempt < 2:
                    await asyncio.sleep(15)

        raise last_error

    async def get_order_status(self, order_id: str) -> Dict[str, Any]:
        """Получение статуса заказа из iiko"""
        data = await self._request("POST", "/api/1/deliveries/by_id", {
            "organizationIds": [self.organization_id],
            "orderIds": [order_id]
        })
        orders = data.get("orders", [])
        return orders[0] if orders else {}

    async def cancel_order(self, order_id: str) -> bool:
        """Отмена заказа в iiko"""
        try:
            await self._request("POST", "/api/1/deliveries/cancel", {
                "organizationId": self.organization_id,
                "orderId": order_id
            })
            return True
        except Exception:
            return False

    # =========================================================================
    # Программа лояльности (iikoCard)
    # =========================================================================

    async def get_customer_info(
        self,
        phone: str,
        api_login: Optional[str] = None,
        organization_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Получение информации о клиенте из программы лояльности iiko
        """
        org_id = organization_id or self.organization_id
        try:
            data = await self._request(
                "POST", "/api/1/loyalty/iiko/customer/info", 
                {"organizationId": org_id, "type": "phone", "phone": phone},
                api_login=api_login,
                organization_id=org_id
            )
            return data
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 404:
                return {"found": False, "phone": phone}
            raise

    async def get_customer_balance(
        self,
        phone: str,
        api_login: Optional[str] = None,
        organization_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """Получение баланса бонусов клиента"""
        customer = await self.get_customer_info(
            phone,
            api_login=api_login,
            organization_id=organization_id
        )
        if customer.get("found") is False:
            return {"balance": 0, "found": False}
        return {
            "balance": customer.get("walletBalances", [{}])[0].get("balance", 0)
                if customer.get("walletBalances") else 0,
            "found": True,
            "name": customer.get("name", "")
        }

    # =========================================================================
    # Вебхуки
    # =========================================================================

    async def get_webhook_settings(
        self,
        api_login: Optional[str] = None,
        organization_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Получение текущих настроек вебхуков для организации
        """
        org_id = organization_id or self.organization_id
        return await self._request(
            "POST", "/api/1/webhooks/settings", 
            {"organizationId": org_id},
            api_login=api_login,
            organization_id=org_id
        )

    async def update_webhook_settings(
        self,
        webhook_url: str,
        auth_token: Optional[str] = None,
        api_login: Optional[str] = None,
        organization_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Обновление настроек вебхуков.
        """
        org_id = organization_id or self.organization_id
        payload = {
            "organizationId": org_id,
            "webHooksUri": webhook_url,
            "webHooksFilter": {
                "deliveryOrderFilter": {
                    "orderStatuses": [
                        "Unconfirmed", "WaitCooking", "ReadyForCooking",
                        "CookingStarted", "CookingCompleted", "Waiting",
                        "OnWay", "Delivered", "DeliveredWithProblems",
                        "Cancelled", "Closed"
                    ],
                    "errors": True
                },
                "stopListUpdateFilter": {
                    "updates": True
                }
            }
        }
        if auth_token:
            payload["authToken"] = auth_token

        return await self._request(
            "POST", "/api/1/webhooks/update_settings", 
            payload,
            api_login=api_login,
            organization_id=org_id
        )


# Глобальный экземпляр сервиса
iiko_service = IikoService()
