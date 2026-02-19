import asyncio
import logging
from typing import List, Dict
from uuid import UUID
from sqlmodel import select
from app.core.database import async_session
from app.models.order import Order
from app.services.iiko_cloud import IikoCloudClient

logger = logging.getLogger(__name__)

class OrderMonitor:
    def __init__(self):
        self.iiko_client = IikoCloudClient()

    async def check_active_orders(self):
        """
        Опрашивает iiko на предмет изменения статусов активных заказов.
        """
        async with async_session() as session:
            # Получаем заказы, которые еще не в конечном статусе
            # Конечные статусы: COMPLETED, CANCELLED, DELIVERED
            # Также игнорируем CREATED, если они еще не отправлены в iiko (нет iiko_order_id)
            stmt = select(Order).where(
                Order.status.notin(["COMPLETED", "CANCELLED", "DELIVERED"]), 
                Order.iiko_order_id != None
            )
            result = await session.execute(stmt)
            active_orders = result.scalars().all()

            if not active_orders:
                return

            # Группируем по организации (пока предполагаем одну, но на будущее полезно)
            # iiko check_delivery_status поддерживает список ID.
            
            # Карта iiko_id -> объект Order
            order_map = {str(order.iiko_order_id): order for order in active_orders}
            order_ids = list(order_map.keys())

            if not order_ids:
                return

            try:
                # Нам нужен org_id. Берём первую организацию.
                orgs = await self.iiko_client.get_organizations()
                if not orgs:
                    logger.warning("Организации не найдены для проверки статусов.")
                    return
                org_id = orgs[0]['id']

                # Обрабатываем каждый заказ отдельно, так как мой метод check_delivery_status
                # в iiko_cloud.py принимает список, но по факту удобнее обрабатывать ответ для каждого.
                
                for order in active_orders:
                     try:
                        info = await self.iiko_client.check_delivery_status(org_id, str(order.iiko_order_id))
                        # Структура ответа:
                        # { "deliveryDeliveries": [...], ... }
                        
                        deliveries = info.get("deliveryDeliveries", [])
                        if not deliveries:
                            continue
                            
                        # Находим нашу доставку
                        delivery = deliveries[0] 
                        
                        iiko_status = delivery.get("status")
                        if not iiko_status:
                            continue

                        # Обновляем, если статус изменился
                        if order.iiko_status_raw != iiko_status:
                            old_status = order.status
                            new_status = self._map_status(iiko_status)
                            
                            order.iiko_status_raw = iiko_status
                            if new_status:
                                order.status = new_status
                            
                            session.add(order)
                            logger.info(f"Обновление статуса заказа {order.id}: {old_status} -> {new_status} (iiko: {iiko_status})")

                     except Exception as e:
                         logger.error(f"Ошибка проверки заказа {order.id}: {e}")
                
                await session.commit()

            except Exception as e:
                logger.error(f"Глобальная ошибка в check_active_orders: {e}")
            finally:
                await self.iiko_client.close()

    def _map_status(self, iiko_status: str) -> str:
        # Статусы iiko: 
        # Unconfirmed, WaitCooking, ReadyForCooking, CookingStarted, CookingCompleted, Waiting, OnWay, Delivered, Closed, Cancelled
        
        mapping = {
            "Unconfirmed": "PENDING_IIKO",    # Неподтвержден
            "WaitCooking": "CONFIRMED",       # Ждет готовки
            "ReadyForCooking": "CONFIRMED",   # Готов к готовке
            "CookingStarted": "COOKING",      # Готовится
            "CookingCompleted": "READY",      # Приготовлен
            "Waiting": "READY",               # Ждет курьера
            "OnWay": "DELIVERING",            # В пути
            "Delivered": "DELIVERED",         # Доставлен
            "Closed": "COMPLETED",            # Закрыт
            "Cancelled": "CANCELLED"          # Отменен
        }
        return mapping.get(iiko_status, "PENDING_IIKO")
