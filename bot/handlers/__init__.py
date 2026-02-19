"""
Обработчики команд и сообщений
"""
from aiogram import Router, F
from aiogram.types import Message, CallbackQuery
from aiogram.filters import Command, StateFilter
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from keyboards import (
    get_main_menu_keyboard,
    get_categories_keyboard,
    get_products_keyboard,
    get_product_keyboard,
    get_cart_keyboard,
    get_cancel_keyboard
)
from utils.api_client import api_client
from utils.cart import cart_storage

router = Router()


# ============= Состояния FSM =============

class OrderState(StatesGroup):
    """Состояния для оформления заказа"""
    waiting_for_name = State()
    waiting_for_phone = State()
    waiting_for_address = State()
    waiting_for_comment = State()


# ============= Команды =============

@router.message(Command("start"))
async def cmd_start(message: Message):
    """Обработка команды /start"""
    await message.answer(
        f"👋 Добро пожаловать в FoodTech!\n\n"
        f"Я помогу вам заказать вкусную еду с доставкой.\n\n"
        f"Используйте кнопки меню ниже для навигации:",
        reply_markup=get_main_menu_keyboard()
    )


@router.message(Command("help"))
async def cmd_help(message: Message):
    """Обработка команды /help"""
    await message.answer(
        "📖 Помощь по боту:\n\n"
        "🍕 Меню - Просмотр доступных блюд\n"
        "🛒 Корзина - Ваши выбранные товары\n"
        "📝 Мои заказы - История заказов\n"
        "ℹ️ Помощь - Это сообщение\n\n"
        "Для заказа выберите категорию, затем товар и добавьте его в корзину."
    )


# ============= Главное меню =============

@router.message(F.text == "🍕 Меню")
async def show_menu(message: Message):
    """Показать меню (категории)"""
    try:
        categories = await api_client.get_categories()

        if not categories:
            await message.answer("😔 К сожалению, меню пока пусто.")
            return

        await message.answer(
            "📋 Выберите категорию:",
            reply_markup=get_categories_keyboard(categories)
        )
    except Exception as e:
        await message.answer(f"❌ Ошибка при загрузке меню: {str(e)}")


@router.message(F.text == "🛒 Корзина")
async def show_cart(message: Message):
    """Показать корзину"""
    await show_cart_handler(message)


@router.message(F.text == "📝 Мои заказы")
async def show_orders(message: Message):
    """Показать историю заказов"""
    try:
        orders = await api_client.get_user_orders(message.from_user.id)

        if not orders:
            await message.answer("У вас пока нет заказов.")
            return

        orders_text = "📝 Ваши заказы:\n\n"
        for order in orders[:5]:  # Показываем последние 5
            status_emoji = {
                "new": "🆕",
                "confirmed": "✅",
                "cooking": "👨‍🍳",
                "ready": "🍕",
                "delivering": "🚗",
                "delivered": "✅",
                "cancelled": "❌"
            }.get(order["status"], "❓")

            orders_text += (
                f"{status_emoji} Заказ #{order['id']}\n"
                f"Сумма: {float(order['total_amount']):.0f}₽\n"
                f"Статус: {order['status']}\n"
                f"Адрес: {order['delivery_address']}\n\n"
            )

        await message.answer(orders_text)
    except Exception as e:
        await message.answer(f"❌ Ошибка при загрузке заказов: {str(e)}")


@router.message(F.text == "ℹ️ Помощь")
async def show_help(message: Message):
    """Показать помощь"""
    await cmd_help(message)


# ============= Обработчики callback =============

@router.callback_query(F.data == "back_to_menu")
async def back_to_menu(callback: CallbackQuery):
    """Вернуться в главное меню"""
    await callback.message.delete()
    await callback.message.answer(
        "Главное меню:",
        reply_markup=get_main_menu_keyboard()
    )
    await callback.answer()


@router.callback_query(F.data == "back_to_categories")
async def back_to_categories(callback: CallbackQuery):
    """Вернуться к категориям"""
    try:
        categories = await api_client.get_categories()
        await callback.message.edit_text(
            "📋 Выберите категорию:",
            reply_markup=get_categories_keyboard(categories)
        )
        await callback.answer()
    except Exception as e:
        await callback.answer(f"Ошибка: {str(e)}", show_alert=True)


@router.callback_query(F.data.startswith("category:"))
async def show_category_products(callback: CallbackQuery):
    """Показать товары категории"""
    try:
        category_id = int(callback.data.split(":")[1])
        products = await api_client.get_products(category_id=category_id)

        if not products:
            await callback.answer("В этой категории пока нет товаров", show_alert=True)
            return

        await callback.message.edit_text(
            "🍽 Выберите блюдо:",
            reply_markup=get_products_keyboard(products, category_id)
        )
        await callback.answer()
    except Exception as e:
        await callback.answer(f"Ошибка: {str(e)}", show_alert=True)


@router.callback_query(F.data.startswith("product:"))
async def show_product_detail(callback: CallbackQuery):
    """Показать детали товара"""
    try:
        product_id = int(callback.data.split(":")[1])
        product = await api_client.get_product(product_id)

        text = (
            f"🍽 <b>{product['name']}</b>\n\n"
            f"{product.get('description', 'Без описания')}\n\n"
            f"💰 Цена: <b>{float(product['price']):.0f}₽</b>"
        )

        await callback.message.edit_text(
            text,
            parse_mode="HTML",
            reply_markup=get_product_keyboard(product_id, product.get("category_id", 0))
        )
        await callback.answer()
    except Exception as e:
        await callback.answer(f"Ошибка: {str(e)}", show_alert=True)


@router.callback_query(F.data.startswith("add_to_cart:"))
async def add_to_cart(callback: CallbackQuery):
    """Добавить товар в корзину"""
    try:
        product_id = int(callback.data.split(":")[1])
        product = await api_client.get_product(product_id)

        cart_storage.add_item(callback.from_user.id, product_id, 1)

        await callback.answer(
            f"✅ {product['name']} добавлен в корзину!",
            show_alert=True
        )
    except Exception as e:
        await callback.answer(f"Ошибка: {str(e)}", show_alert=True)


async def show_cart_handler(message: Message):
    """Вспомогательная функция для отображения корзины"""
    try:
        cart = cart_storage.get_cart(message.from_user.id)

        if not cart:
            await message.answer(
                "🛒 Ваша корзина пуста.\n\nВыберите товары из меню!",
                reply_markup=get_cart_keyboard(0)
            )
            return

        # Получаем информацию о товарах
        total = 0
        cart_text = "🛒 <b>Ваша корзина:</b>\n\n"

        for product_id, quantity in cart.items():
            product = await api_client.get_product(product_id)
            price = float(product["price"])
            item_total = price * quantity
            total += item_total

            cart_text += (
                f"• {product['name']}\n"
                f"  {quantity} × {price:.0f}₽ = {item_total:.0f}₽\n\n"
            )

        cart_text += f"<b>Итого: {total:.0f}₽</b>"

        await message.answer(
            cart_text,
            parse_mode="HTML",
            reply_markup=get_cart_keyboard(len(cart))
        )
    except Exception as e:
        await message.answer(f"❌ Ошибка: {str(e)}")


@router.callback_query(F.data == "clear_cart")
async def clear_cart(callback: CallbackQuery):
    """Очистить корзину"""
    cart_storage.clear_cart(callback.from_user.id)
    await callback.message.edit_text("🗑 Корзина очищена")
    await callback.answer()


@router.callback_query(F.data == "checkout")
async def start_checkout(callback: CallbackQuery, state: FSMContext):
    """Начать оформление заказа"""
    await callback.message.edit_text(
        "📝 Оформление заказа\n\n"
        "Введите ваше имя:",
        reply_markup=None
    )
    await state.set_state(OrderState.waiting_for_name)
    await callback.answer()


# ============= Оформление заказа =============

@router.message(OrderState.waiting_for_name)
async def process_name(message: Message, state: FSMContext):
    """Обработка имени"""
    if message.text == "❌ Отмена":
        await state.clear()
        await message.answer("Оформление заказа отменено", reply_markup=get_main_menu_keyboard())
        return

    await state.update_data(name=message.text)
    await message.answer(
        "📱 Введите ваш номер телефона\n(например: +79991234567):",
        reply_markup=get_cancel_keyboard()
    )
    await state.set_state(OrderState.waiting_for_phone)


@router.message(OrderState.waiting_for_phone)
async def process_phone(message: Message, state: FSMContext):
    """Обработка телефона"""
    if message.text == "❌ Отмена":
        await state.clear()
        await message.answer("Оформление заказа отменено", reply_markup=get_main_menu_keyboard())
        return

    await state.update_data(phone=message.text)
    await message.answer(
        "📍 Введите адрес доставки:",
        reply_markup=get_cancel_keyboard()
    )
    await state.set_state(OrderState.waiting_for_address)


@router.message(OrderState.waiting_for_address)
async def process_address(message: Message, state: FSMContext):
    """Обработка адреса"""
    if message.text == "❌ Отмена":
        await state.clear()
        await message.answer("Оформление заказа отменено", reply_markup=get_main_menu_keyboard())
        return

    await state.update_data(address=message.text)
    await message.answer(
        "💬 Добавьте комментарий к заказу или нажмите 'Отмена' чтобы пропустить:",
        reply_markup=get_cancel_keyboard()
    )
    await state.set_state(OrderState.waiting_for_comment)


@router.message(OrderState.waiting_for_comment)
async def process_comment(message: Message, state: FSMContext):
    """Обработка комментария и создание заказа"""
    comment = None if message.text == "❌ Отмена" else message.text

    # Получаем данные заказа
    data = await state.get_data()
    cart = cart_storage.get_cart(message.from_user.id)

    if not cart:
        await state.clear()
        await message.answer(
            "❌ Ваша корзина пуста!",
            reply_markup=get_main_menu_keyboard()
        )
        return

    # Формируем заказ
    items = [
        {"product_id": product_id, "quantity": quantity}
        for product_id, quantity in cart.items()
    ]

    order_data = {
        "telegram_user_id": message.from_user.id,
        "telegram_username": message.from_user.username,
        "customer_name": data["name"],
        "customer_phone": data["phone"],
        "delivery_address": data["address"],
        "comment": comment,
        "items": items
    }

    try:
        # Создаем заказ через API
        order = await api_client.create_order(order_data)

        # Очищаем корзину
        cart_storage.clear_cart(message.from_user.id)

        # Отправляем подтверждение
        await message.answer(
            f"✅ <b>Заказ #{order['id']} создан!</b>\n\n"
            f"Сумма: <b>{float(order['total_amount']):.0f}₽</b>\n"
            f"Адрес доставки: {order['delivery_address']}\n\n"
            f"Мы свяжемся с вами в ближайшее время!",
            parse_mode="HTML",
            reply_markup=get_main_menu_keyboard()
        )

        await state.clear()
    except Exception as e:
        await message.answer(
            f"❌ Ошибка при создании заказа: {str(e)}\n\n"
            f"Попробуйте позже или свяжитесь с поддержкой.",
            reply_markup=get_main_menu_keyboard()
        )
        await state.clear()
