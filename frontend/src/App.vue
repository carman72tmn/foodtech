<template>
  <div class="app-container">
    <header class="header">
      <div class="logo">Result.Rest</div>
      <nav>
        <router-link to="/">Меню</router-link>
      </nav>
      <div class="cart-btn" @click="$router.push('/cart')">
        Корзина ({{ cartStore.totalItems }})
      </div>
    </header>

    <main class="main-content">
      <router-view></router-view>
    </main>

    <footer class="footer">
      <p>&copy; 2026 FoodTech Delivery</p>
    </footer>
  </div>
</template>

<script setup>
import { useCartStore } from './store/cart'
const cartStore = useCartStore()
</script>

<style scoped>
.app-container {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 5%;
  background-color: var(--surface-color);
  border-bottom: 1px solid var(--border-color);
  position: sticky;
  top: 0;
  z-index: 100;
}

.logo {
  font-size: 1.5rem;
  font-weight: 800;
  color: var(--primary-color);
}

nav a {
  color: var(--text-primary);
  text-decoration: none;
  font-weight: 500;
  transition: color 0.3s;
}

nav a:hover {
  color: var(--primary-color);
}

.cart-btn {
  background: var(--primary-color);
  color: white;
  padding: 0.5rem 1rem;
  border-radius: var(--radius-md);
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s, background 0.3s;
}

.cart-btn:hover {
  transform: translateY(-2px);
  background: var(--primary-hover);
}

.main-content {
  flex: 1;
  padding: 2rem 5%;
}

.footer {
  text-align: center;
  padding: 2rem;
  color: var(--text-secondary);
  border-top: 1px solid var(--border-color);
}
</style>
