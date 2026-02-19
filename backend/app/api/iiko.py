"""
API эндпоинты для синхронизации с iiko
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from datetime import datetime
from app.core.database import get_session
from app.models.category import Category
from app.models.product import Product
from app.schemas import IikoSyncResponse
from app.services.iiko_service import iiko_service

router = APIRouter(prefix="/iiko", tags=["iiko Integration"])


@router.post("/sync-nomenclature", response_model=IikoSyncResponse)
async def sync_nomenclature(session: Session = Depends(get_session)):
    """
    Синхронизация номенклатуры (меню) с iiko

    Загружает все категории и товары из iiko и обновляет локальную БД
    """
    try:
        # Получаем номенклатуру из iiko
        nomenclature = await iiko_service.get_nomenclature()

        categories_synced = 0
        products_synced = 0

        # Обрабатываем категории
        if "groups" in nomenclature:
            for iiko_group in nomenclature["groups"]:
                # Ищем существующую категорию по iiko_id
                query = select(Category).where(Category.iiko_id == iiko_group["id"])
                category = session.exec(query).first()

                if category:
                    # Обновляем существующую
                    category.name = iiko_group["name"]
                    category.updated_at = datetime.utcnow()
                else:
                    # Создаем новую
                    category = Category(
                        name=iiko_group["name"],
                        iiko_id=iiko_group["id"],
                        is_active=not iiko_group.get("isDeleted", False)
                    )
                    session.add(category)

                categories_synced += 1

        session.commit()

        # Обрабатываем товары
        if "products" in nomenclature:
            for iiko_product in nomenclature["products"]:
                # Ищем существующий товар по iiko_id
                query = select(Product).where(Product.iiko_id == iiko_product["id"])
                product = session.exec(query).first()

                # Находим категорию
                category_id = None
                if iiko_product.get("parentGroup"):
                    cat_query = select(Category).where(Category.iiko_id == iiko_product["parentGroup"])
                    category = session.exec(cat_query).first()
                    if category:
                        category_id = category.id

                # Получаем цену (берем первую размер/модификацию если есть)
                price = 0
                if "sizePrices" in iiko_product and iiko_product["sizePrices"]:
                    price = iiko_product["sizePrices"][0].get("price", {}).get("currentPrice", 0)

                if product:
                    # Обновляем существующий
                    product.name = iiko_product["name"]
                    product.description = iiko_product.get("description")
                    product.price = price
                    product.category_id = category_id
                    product.is_available = not iiko_product.get("isDeleted", False)
                    product.updated_at = datetime.utcnow()
                else:
                    # Создаем новый
                    product = Product(
                        name=iiko_product["name"],
                        description=iiko_product.get("description"),
                        price=price,
                        category_id=category_id,
                        iiko_id=iiko_product["id"],
                        is_available=not iiko_product.get("isDeleted", False)
                    )
                    session.add(product)

                products_synced += 1

        session.commit()

        return IikoSyncResponse(
            success=True,
            categories_synced=categories_synced,
            products_synced=products_synced,
            message=f"Successfully synced {categories_synced} categories and {products_synced} products"
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error syncing with iiko: {str(e)}"
        )


@router.get("/organization-info")
async def get_organization_info():
    """Получить информацию об организации из iiko"""
    try:
        info = await iiko_service.get_organization_info()
        return info
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error getting organization info: {str(e)}"
        )
