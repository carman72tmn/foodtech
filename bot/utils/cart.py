"""
Утилиты для работы с корзиной пользователя
Корзина хранится в памяти (для продакшена лучше использовать Redis)
"""
from typing import Dict, List


class Cart:
    """Простое хранилище корзин в памяти"""

    def __init__(self):
        # user_id -> {product_id: quantity}
        self._carts: Dict[int, Dict[int, int]] = {}

    def add_item(self, user_id: int, product_id: int, quantity: int = 1):
        """Добавить товар в корзину"""
        if user_id not in self._carts:
            self._carts[user_id] = {}

        if product_id in self._carts[user_id]:
            self._carts[user_id][product_id] += quantity
        else:
            self._carts[user_id][product_id] = quantity

    def remove_item(self, user_id: int, product_id: int):
        """Удалить товар из корзины"""
        if user_id in self._carts and product_id in self._carts[user_id]:
            del self._carts[user_id][product_id]

    def update_quantity(self, user_id: int, product_id: int, quantity: int):
        """Обновить количество товара"""
        if quantity <= 0:
            self.remove_item(user_id, product_id)
        else:
            if user_id not in self._carts:
                self._carts[user_id] = {}
            self._carts[user_id][product_id] = quantity

    def get_cart(self, user_id: int) -> Dict[int, int]:
        """Получить корзину пользователя"""
        return self._carts.get(user_id, {})

    def clear_cart(self, user_id: int):
        """Очистить корзину"""
        if user_id in self._carts:
            del self._carts[user_id]

    def get_items_count(self, user_id: int) -> int:
        """Получить количество товаров в корзине"""
        cart = self.get_cart(user_id)
        return sum(cart.values())


# Глобальный экземпляр корзины
cart_storage = Cart()
