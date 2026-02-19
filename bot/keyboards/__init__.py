"""
Клавиатуры для Telegram бота
"""
from aiogram.types import (
    ReplyKeyboardMarkup,
    KeyboardButton,
    InlineKeyboardMarkup,
    InlineKeyboardButton
)
from aiogram.utils.keyboard import ReplyKeyboardBuilder, InlineKeyboardBuilder
from typing import List, Dict, Any


def get_main_menu_keyboard() -> ReplyKeyboardMarkup:
    """Главное меню бота"""
    builder = ReplyKeyboardBuilder()
    builder.row(
        KeyboardButton(text="🍕 Меню"),
        KeyboardButton(text="🛒 Корзина")
    )
    builder.row(
        KeyboardButton(text="📝 Мои заказы"),
        KeyboardButton(text="ℹ️ Помощь")
    )
    return builder.as_markup(resize_keyboard=True)


def get_categories_keyboard(categories: List[Dict[str, Any]]) -> InlineKeyboardMarkup:
    """Клавиатура с категориями"""
    builder = InlineKeyboardBuilder()

    for category in categories:
        builder.row(
            InlineKeyboardButton(
                text=category["name"],
                callback_data=f"category:{category['id']}"
            )
        )

    builder.row(
        InlineKeyboardButton(text="◀️ Назад", callback_data="back_to_menu")
    )

    return builder.as_markup()


def get_products_keyboard(
    products: List[Dict[str, Any]],
    category_id: int
) -> InlineKeyboardMarkup:
    """Клавиатура со товарами категории"""
    builder = InlineKeyboardBuilder()

    for product in products:
        price = float(product["price"])
        builder.row(
            InlineKeyboardButton(
                text=f"{product['name']} - {price:.0f}₽",
                callback_data=f"product:{product['id']}"
            )
        )

    builder.row(
        InlineKeyboardButton(
            text="◀️ Назад к категориям",
            callback_data="back_to_categories"
        )
    )

    return builder.as_markup()


def get_product_keyboard(product_id: int, category_id: int) -> InlineKeyboardMarkup:
    """Клавиатура для отдельного товара"""
    builder = InlineKeyboardBuilder()

    builder.row(
        InlineKeyboardButton(
            text="➕ Добавить в корзину",
            callback_data=f"add_to_cart:{product_id}"
        )
    )
    builder.row(
        InlineKeyboardButton(
            text="◀️ Назад к товарам",
            callback_data=f"category:{category_id}"
        )
    )

    return builder.as_markup()


def get_cart_keyboard(items_count: int) -> InlineKeyboardMarkup:
    """Клавиатура корзины"""
    builder = InlineKeyboardBuilder()

    if items_count > 0:
        builder.row(
            InlineKeyboardButton(
                text="✅ Оформить заказ",
                callback_data="checkout"
            )
        )
        builder.row(
            InlineKeyboardButton(
                text="🗑 Очистить корзину",
                callback_data="clear_cart"
            )
        )

    builder.row(
        InlineKeyboardButton(
            text="◀️ Назад в меню",
            callback_data="back_to_menu"
        )
    )

    return builder.as_markup()


def get_cancel_keyboard() -> ReplyKeyboardMarkup:
    """Клавиатура для отмены действия"""
    builder = ReplyKeyboardBuilder()
    builder.row(KeyboardButton(text="❌ Отмена"))
    return builder.as_markup(resize_keyboard=True)
