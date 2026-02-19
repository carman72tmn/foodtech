"""
API эндпоинты для работы с товарами
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from app.core.database import get_session
from app.models.product import Product
from app.schemas import ProductCreate, ProductUpdate, ProductResponse

router = APIRouter(prefix="/products", tags=["Products"])


@router.get("/", response_model=List[ProductResponse])
async def get_products(
    skip: int = 0,
    limit: int = 100,
    category_id: Optional[int] = None,
    is_available: Optional[bool] = None,
    session: Session = Depends(get_session)
):
    """
    Получить список всех товаров

    - **skip**: Количество пропускаемых записей
    - **limit**: Максимальное количество возвращаемых записей
    - **category_id**: Фильтр по категории
    - **is_available**: Фильтр по доступности
    """
    query = select(Product).order_by(Product.sort_order, Product.name).offset(skip).limit(limit)

    if category_id is not None:
        query = query.where(Product.category_id == category_id)

    if is_available is not None:
        query = query.where(Product.is_available == is_available)

    products = session.exec(query).all()
    return products


@router.get("/{product_id}", response_model=ProductResponse)
async def get_product(product_id: int, session: Session = Depends(get_session)):
    """Получить товар по ID"""
    product = session.get(Product, product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with id {product_id} not found"
        )
    return product


@router.post("/", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
async def create_product(
    product_data: ProductCreate,
    session: Session = Depends(get_session)
):
    """Создать новый товар"""
    product = Product(**product_data.model_dump())
    session.add(product)
    session.commit()
    session.refresh(product)
    return product


@router.patch("/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: int,
    product_data: ProductUpdate,
    session: Session = Depends(get_session)
):
    """Обновить существующий товар"""
    product = session.get(Product, product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with id {product_id} not found"
        )

    # Обновляем только предоставленные поля
    update_data = product_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(product, key, value)

    session.add(product)
    session.commit()
    session.refresh(product)
    return product


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product(product_id: int, session: Session = Depends(get_session)):
    """Удалить товар"""
    product = session.get(Product, product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with id {product_id} not found"
        )

    session.delete(product)
    session.commit()
