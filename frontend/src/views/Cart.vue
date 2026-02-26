<template>
  <div class="cart-page">
    <h1 class="page-title fade-in">Оформление заказа</h1>
    
    <div v-if="cartStore.items.length === 0" class="empty-cart fade-in">
      <h2>Ваша корзина пуста</h2>
      <p>Перейдите в меню, чтобы добавить вкусные блюда!</p>
      <router-link to="/" class="primary-btn mt-4">В меню</router-link>
    </div>
    
    <div v-else class="cart-content fade-in" style="animation-delay: 0.1s">
      <div class="cart-items">
        <div v-for="item in cartStore.items" :key="item.id" class="cart-item">
          <div class="item-img">
            <img :src="item.image_url" :alt="item.name">
          </div>
          <div class="item-details">
            <h3>{{ item.name }}</h3>
            <span class="item-price">{{ item.price }} ₽</span>
          </div>
          <div class="item-actions">
            <button class="qty-btn" @click="cartStore.removeItem(item.id)">-</button>
            <span class="qty">{{ item.quantity }}</span>
            <button class="qty-btn" @click="cartStore.addItem(item)">+</button>
          </div>
          <div class="item-total">
            {{ item.price * item.quantity }} ₽
          </div>
        </div>
      </div>
      
      <div class="checkout-sidebar">
        <div class="summary">
          <h2>Итого:</h2>
          <div class="total-price">{{ cartStore.totalPrice }} ₽</div>
        </div>
        
        <form class="checkout-form" @submit.prevent="submitOrder">
          <div class="form-group">
            <label>Имя</label>
            <input type="text" v-model="form.name" required placeholder="Ваше имя">
          </div>
          <div class="form-group">
            <label>Телефон</label>
            <input type="tel" v-model="form.phone" required placeholder="+7 (999) 000-00-00">
          </div>
          <div class="form-group">
            <label>Адрес доставки</label>
            <input type="text" v-model="form.address" required placeholder="Улица, дом, квартира">
          </div>
          <div class="form-group">
            <label>Промокод (если есть)</label>
            <div class="promo-input">
              <input type="text" v-model="form.promo_code" placeholder="Введите код">
            </div>
          </div>
          
          <button type="submit" class="primary-btn full-width mt-4" :disabled="isSubmitting">
            {{ isSubmitting ? 'Оформляем...' : 'Заказать' }}
          </button>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useCartStore } from '../store/cart'
import { createOrder } from '../api/order'

const cartStore = useCartStore()
const isSubmitting = ref(false)

const form = reactive({
  name: '',
  phone: '',
  address: '',
  promo_code: ''
})

const submitOrder = async () => {
  if (cartStore.items.length === 0) return
  isSubmitting.value = true
  
  try {
    const orderData = {
      telegram_user_id: 1, // Dummy ID since we are on the web 
      branch_id: 1, // Default branch
      customer_name: form.name,
      customer_phone: form.phone,
      delivery_address: form.address,
      promo_code: form.promo_code || null,
      bonus_spent: 0,
      items: cartStore.items.map(item => ({
        product_id: item.id,
        quantity: item.quantity,
        modifiers: []
      }))
    }
    
    await createOrder(orderData)
    alert('Заказ успешно создан! Ожидайте звонка оператора.')
    cartStore.clearCart()
    form.name = ''
    form.phone = ''
    form.address = ''
    form.promo_code = ''
  } catch (error) {
    alert('Ошибка при создании заказа: ' + error.message)
  } finally {
    isSubmitting.value = false
  }
}
</script>

<style scoped>
.page-title {
  margin-bottom: 2rem;
  font-size: 2.5rem;
}

.empty-cart {
  text-align: center;
  padding: 4rem 2rem;
  background: var(--surface-color);
  border-radius: var(--radius-lg);
  border: 1px solid var(--border-color);
}

.empty-cart h2 {
  margin-bottom: 1rem;
}

.empty-cart p {
  color: var(--text-secondary);
  margin-bottom: 2rem;
}

.cart-content {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 2rem;
  align-items: start;
}

@media (max-width: 768px) {
  .cart-content {
    grid-template-columns: 1fr;
  }
}

.cart-item {
  display: flex;
  align-items: center;
  background: var(--surface-color);
  padding: 1rem;
  border-radius: var(--radius-md);
  margin-bottom: 1rem;
  border: 1px solid var(--border-color);
  gap: 1.5rem;
}

.item-img {
  width: 80px;
  height: 80px;
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.item-img img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.item-details {
  flex: 1;
}

.item-price {
  color: var(--text-secondary);
}

.item-actions {
  display: flex;
  align-items: center;
  gap: 1rem;
  background: var(--surface-color-elevated);
  padding: 0.25rem;
  border-radius: var(--radius-sm);
}

.qty-btn {
  width: 30px;
  height: 30px;
  background: var(--surface-color);
  border: 1px solid var(--border-color);
  color: white;
  border-radius: var(--radius-sm);
  font-size: 1.2rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.qty-btn:hover {
  border-color: var(--primary-color);
  color: var(--primary-color);
}

.qty {
  font-weight: 700;
  min-width: 20px;
  text-align: center;
}

.item-total {
  font-weight: 700;
  font-size: 1.2rem;
  min-width: 100px;
  text-align: right;
}

.checkout-sidebar {
  background: var(--surface-color);
  padding: 2rem;
  border-radius: var(--radius-md);
  border: 1px solid var(--border-color);
  position: sticky;
  top: 100px;
}

.summary {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--border-color);
}

.total-price {
  font-size: 2rem;
  font-weight: 800;
  color: var(--primary-color);
}

.form-group {
  margin-bottom: 1.5rem;
}

label {
  display: block;
  margin-bottom: 0.5rem;
  color: var(--text-secondary);
  font-size: 0.9rem;
}

input {
  width: 100%;
  background: var(--surface-color-elevated);
  border: 1px solid var(--border-color);
  color: white;
  padding: 0.75rem 1rem;
  border-radius: var(--radius-sm);
  font-size: 1rem;
  transition: border-color 0.2s;
}

input:focus {
  outline: none;
  border-color: var(--primary-color);
}

.mt-4 { margin-top: 2rem; }
.full-width { width: 100%; display: block; text-align: center; }

.primary-btn {
  background: var(--primary-color);
  color: white;
  padding: 1rem 2rem;
  border-radius: var(--radius-md);
  font-weight: 700;
  font-size: 1.1rem;
  text-decoration: none;
  display: inline-block;
  cursor: pointer;
  transition: background 0.2s;
}

.primary-btn:hover {
  background: var(--primary-hover);
}

.primary-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}
</style>
