"""
Сервис-оркестратор для синхронизации данных с iiko
"""
import logging
from typing import Optional, Dict, Any
from datetime import datetime
from sqlmodel import Session, select
from app.models.category import Category
from app.models.product import Product, ProductSize, ProductModifierGroup, ProductModifier
from app.models.sync_log import SyncLog
from app.services.iiko_service import iiko_service

logger = logging.getLogger(__name__)


class IikoSyncService:
    """Оркестратор синхронизации данных между iiko и локальной БД"""

    async def sync_menu(self, session: Session) -> Dict[str, Any]:
        """
        Полная синхронизация меню из iiko

        Загружает номенклатуру (категории + товары) и обновляет локальную БД.
        Сопоставление по iiko_id.
        """
        log = SyncLog(sync_type="menu", status="running")
        session.add(log)
        session.commit()

        try:
            nomenclature = await iiko_service.get_nomenclature()

            categories_synced = 0
            products_synced = 0

            # Синхронизация категорий (groups)
            if "groups" in nomenclature:
                for iiko_group in nomenclature["groups"]:
                    query = select(Category).where(
                        Category.iiko_id == iiko_group["id"]
                    )
                    category = session.exec(query).first()

                    if category:
                        category.name = iiko_group["name"]
                        category.updated_at = datetime.utcnow()
                    else:
                        category = Category(
                            name=iiko_group["name"],
                            iiko_id=iiko_group["id"],
                            is_active=not iiko_group.get("isDeleted", False)
                        )
                        session.add(category)

                    categories_synced += 1

            session.commit()

            # Parsing sizes from root to map size_id to size_name
            size_map = {}
            if "sizes" in nomenclature:
                for size in nomenclature["sizes"]:
                    size_map[size["id"]] = size

            # Синхронизация товаров (products)
            if "products" in nomenclature:
                for iiko_product in nomenclature["products"]:
                    query = select(Product).where(
                        Product.iiko_id == iiko_product["id"]
                    )
                    product = session.exec(query).first()

                    # Поиск категории
                    category_id = None
                    if iiko_product.get("parentGroup"):
                        cat_query = select(Category).where(
                            Category.iiko_id == iiko_product["parentGroup"]
                        )
                        cat = session.exec(cat_query).first()
                        if cat:
                            category_id = cat.id

                    # Извлечение цены
                    price = 0
                    if iiko_product.get("sizePrices"):
                        price = (
                            iiko_product["sizePrices"][0]
                            .get("price", {})
                            .get("currentPrice", 0)
                        )

                    # Извлечение артикула
                    article = iiko_product.get("code", "")

                    if product:
                        product.name = iiko_product["name"]
                        product.description = iiko_product.get("description")
                        product.price = price
                        product.category_id = category_id
                        product.article = article
                        product.is_available = not iiko_product.get(
                            "isDeleted", False
                        )
                        product.updated_at = datetime.utcnow()
                    else:
                        product = Product(
                            name=iiko_product["name"],
                            description=iiko_product.get("description"),
                            price=price,
                            category_id=category_id,
                            iiko_id=iiko_product["id"],
                            article=article,
                            is_available=not iiko_product.get(
                                "isDeleted", False
                            )
                        )
                        session.add(product)
                        
                    session.flush() # ensure product.id is available

                    # Sync Sizes
                    # Remove existing sizes
                    for existing_size in product.sizes:
                        session.delete(existing_size)
                    product.sizes = []
                    
                    if iiko_product.get("sizePrices"):
                        for sp in iiko_product["sizePrices"]:
                            size_id = sp.get("sizeId")
                            size_price = sp.get("price", {}).get("currentPrice", 0)
                            size_info = size_map.get(size_id, {})
                            size_name = size_info.get("name", "Стандарт")
                            is_default = size_info.get("isDefault", False)
                            
                            new_size = ProductSize(
                                product_id=product.id,
                                iiko_id=size_id or "default",
                                name=size_name,
                                price=size_price,
                                is_default=is_default
                            )
                            session.add(new_size)

                    # Sync Modifier Groups
                    for existing_mg in product.modifier_groups:
                        session.delete(existing_mg)
                    product.modifier_groups = []

                    if iiko_product.get("groupModifiers"):
                        for gm in iiko_product["groupModifiers"]:
                            mg = ProductModifierGroup(
                                product_id=product.id,
                                iiko_id=gm.get("modifierId", ""),
                                name="Группа модификаторов", # To be replaced by cross-referencing products if needed, but often iiko sends it as ID pointing to another product. For now use placeholder or fetch name if available.
                                min_amount=gm.get("minAmount", 0),
                                max_amount=gm.get("maxAmount", 1),
                                is_required=gm.get("required", False)
                            )
                            # Try to find group name from nomenclature products if modifierId points to a group
                            group_product = next((p for p in nomenclature["products"] if p["id"] == gm.get("modifierId")), None)
                            if group_product:
                                mg.name = group_product.get("name", "Группа модификаторов")
                                
                            session.add(mg)
                            session.flush() # get mg.id
                            
                            for child in gm.get("childModifiers", []):
                                child_product = next((p for p in nomenclature["products"] if p["id"] == child.get("modifierId")), None)
                                child_name = child_product.get("name", "Модификатор") if child_product else "Модификатор"
                                child_price = 0
                                if child_product and child_product.get("sizePrices"):
                                    child_price = child_product["sizePrices"][0].get("price", {}).get("currentPrice", 0)
                                    
                                mod = ProductModifier(
                                    group_id=mg.id,
                                    iiko_id=child.get("modifierId", ""),
                                    name=child_name,
                                    price=child_price,
                                    default_amount=child.get("defaultAmount", 0),
                                    min_amount=child.get("minAmount", 0),
                                    max_amount=child.get("maxAmount", 1)
                                )
                                session.add(mod)

                    products_synced += 1

            session.commit()

            # Обновляем лог
            log.status = "success"
            log.categories_count = categories_synced
            log.products_count = products_synced
            log.details = f"Synced {categories_synced} categories, {products_synced} products"
            session.commit()

            return {
                "success": True,
                "categories_synced": categories_synced,
                "products_synced": products_synced,
                "message": log.details
            }

        except Exception as e:
            logger.error(f"Menu sync failed: {e}")
            log.status = "error"
            log.details = str(e)
            session.commit()
            raise

    async def sync_prices(self, session: Session) -> Dict[str, Any]:
        """
        Синхронизация только цен из iiko

        Обновляет цены у существующих товаров, сопоставляя по артикулу (article).
        """
        log = SyncLog(sync_type="prices", status="running")
        session.add(log)
        session.commit()

        try:
            nomenclature = await iiko_service.get_nomenclature()
            updated = 0

            if "products" in nomenclature:
                for iiko_product in nomenclature["products"]:
                    # Сопоставляем по iiko_id
                    query = select(Product).where(
                        Product.iiko_id == iiko_product["id"]
                    )
                    product = session.exec(query).first()

                    if product:
                        price = 0
                        if iiko_product.get("sizePrices"):
                            price = (
                                iiko_product["sizePrices"][0]
                                .get("price", {})
                                .get("currentPrice", 0)
                            )
                        if product.price != price:
                            product.price = price
                            product.updated_at = datetime.utcnow()
                            updated += 1

            session.commit()

            log.status = "success"
            log.products_count = updated
            log.details = f"Updated prices for {updated} products"
            session.commit()

            return {
                "success": True,
                "products_updated": updated,
                "message": log.details
            }

        except Exception as e:
            logger.error(f"Price sync failed: {e}")
            log.status = "error"
            log.details = str(e)
            session.commit()
            raise

    async def sync_stop_lists(self, session: Session) -> Dict[str, Any]:
        """
        Синхронизация стоп-листов

        Помечает позиции как недоступные (is_available=False)
        """
        log = SyncLog(sync_type="stop_lists", status="running")
        session.add(log)
        session.commit()

        try:
            stop_items = await iiko_service.get_stop_lists()
            stopped_product_ids = {
                item["productId"] for item in stop_items
                if item.get("balance", 0) <= 0
            }

            # Сначала помечаем все как доступные
            all_products = session.exec(select(Product)).all()
            updated = 0
            for product in all_products:
                if product.iiko_id in stopped_product_ids:
                    if product.is_available:
                        product.is_available = False
                        updated += 1
                else:
                    if not product.is_available:
                        product.is_available = True
                        updated += 1

            session.commit()

            log.status = "success"
            log.products_count = updated
            log.details = f"Updated availability for {updated} products, {len(stopped_product_ids)} on stop-list"
            session.commit()

            return {
                "success": True,
                "products_updated": updated,
                "stopped_count": len(stopped_product_ids),
                "message": log.details
            }

        except Exception as e:
            logger.error(f"Stop-list sync failed: {e}")
            log.status = "error"
            log.details = str(e)
            session.commit()
            raise


# Глобальный экземпляр
iiko_sync_service = IikoSyncService()
