"""
API эндпоинты для работы с заказами
"""
from typing import List, Optional
from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from app.core.database import get_session
from app.models.order import Order, OrderItem, OrderStatus
from app.models.product import Product
from app.schemas import OrderCreate, OrderUpdate, OrderResponse, OrderItemResponse
from app.services.iiko_service import iiko_service

router = APIRouter(prefix="/orders", tags=["Orders"])


@router.get("/", response_model=List[OrderResponse])
async def get_orders(
    skip: int = 0,
    limit: int = 100,
    status_filter: Optional[OrderStatus] = None,
    telegram_user_id: Optional[int] = None,
    session: Session = Depends(get_session)
):
    """
    Получить список заказов

    - **skip**: Количество пропускаемых записей
    - **limit**: Максимальное количество возвращаемых записей
    - **status_filter**: Фильтр по статусу
    - **telegram_user_id**: Фильтр по пользователю Telegram
    """
    query = select(Order).order_by(Order.created_at.desc()).offset(skip).limit(limit)

    if status_filter:
        query = query.where(Order.status == status_filter)

    if telegram_user_id:
        query = query.where(Order.telegram_user_id == telegram_user_id)

    orders = session.exec(query).all()

    # Добавляем позиции к каждому заказу
    for order in orders:
        items_query = select(OrderItem).where(OrderItem.order_id == order.id)
        order.items = list(session.exec(items_query).all())

    return orders


@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(order_id: int, session: Session = Depends(get_session)):
    """Получить заказ по ID"""
    order = session.get(Order, order_id)
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Order with id {order_id} not found"
        )

    # Получаем позиции заказа
    items_query = select(OrderItem).where(OrderItem.order_id == order_id)
    order.items = list(session.exec(items_query).all())

    return order


@router.post("/", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
async def create_order(
    order_data: OrderCreate,
    session: Session = Depends(get_session)
):
    """
    Создать новый заказ

    1. Проверяем наличие товаров
    2. Вычисляем общую сумму
    3. Создаем заказ в БД
    4. Отправляем заказ в iiko
    """
    # Проверяем товары и вычисляем сумму
    total_amount = Decimal("0.00")
    order_items_data = []

    for item in order_data.items:
        product = session.get(Product, item.product_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Product with id {item.product_id} not found"
            )
        if not product.is_available:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Product '{product.name}' is not available"
            )

        item_total = product.price * item.quantity
        total_amount += item_total

        order_items_data.append({
            "product_id": product.id,
            "product_name": product.name,
            "quantity": item.quantity,
            "price": product.price,
            "total": item_total
        })

    # Создаем заказ
    order = Order(
        telegram_user_id=order_data.telegram_user_id,
        telegram_username=order_data.telegram_username,
        customer_name=order_data.customer_name,
        customer_phone=order_data.customer_phone,
        delivery_address=order_data.delivery_address,
        total_amount=total_amount,
        comment=order_data.comment,
        status=OrderStatus.NEW
    )
    session.add(order)
    session.commit()
    session.refresh(order)

    # Создаем позиции заказа
    for item_data in order_items_data:
        order_item = OrderItem(order_id=order.id, **item_data)
        session.add(order_item)

    session.commit()

    # Отправляем заказ в iiko (асинхронно, не блокируем ответ)
    try:
        iiko_items = [
            {
                "product_id": item["product_id"],
                "quantity": item["quantity"],
                "price": item["price"]
            }
            for item in order_items_data
        ]

        iiko_response = await iiko_service.create_delivery_order(
            customer_name=order.customer_name,
            customer_phone=order.customer_phone,
            address=order.delivery_address,
            items=iiko_items,
            comment=order.comment
        )

        # Сохраняем ID заказа из iiko
        if iiko_response.get("orderId"):
            order.iiko_order_id = iiko_response["orderId"]
            order.status = OrderStatus.CONFIRMED
            session.add(order)
            session.commit()
    except Exception as e:
        # Логируем ошибку, но не блокируем создание заказа
        print(f"Error sending order to iiko: {e}")

    # Получаем позиции для ответа
    items_query = select(OrderItem).where(OrderItem.order_id == order.id)
    order.items = list(session.exec(items_query).all())

    return order


@router.patch("/{order_id}", response_model=OrderResponse)
async def update_order(
    order_id: int,
    order_data: OrderUpdate,
    session: Session = Depends(get_session)
):
    """Обновить заказ"""
    order = session.get(Order, order_id)
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Order with id {order_id} not found"
        )

    # Обновляем только предоставленные поля
    update_data = order_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(order, key, value)

    session.add(order)
    session.commit()
    session.refresh(order)

    # Получаем позиции для ответа
    items_query = select(OrderItem).where(OrderItem.order_id == order_id)
    order.items = list(session.exec(items_query).all())

    return order


@router.post("/{order_id}/cancel", response_model=OrderResponse)
async def cancel_order(order_id: int, session: Session = Depends(get_session)):
    """Отменить заказ"""
    order = session.get(Order, order_id)
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Order with id {order_id} not found"
        )

    if order.status in [OrderStatus.DELIVERED, OrderStatus.CANCELLED]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot cancel order with status {order.status}"
        )

    # Отменяем в iiko
    if order.iiko_order_id:
        try:
            await iiko_service.cancel_order(order.iiko_order_id)
        except Exception as e:
            print(f"Error cancelling order in iiko: {e}")

    # Обновляем статус
    order.status = OrderStatus.CANCELLED
    session.add(order)
    session.commit()
    session.refresh(order)

    # Получаем позиции для ответа
    items_query = select(OrderItem).where(OrderItem.order_id == order_id)
    order.items = list(session.exec(items_query).all())

    return order
