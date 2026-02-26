<template>
  <div class="home">
    <div class="hero-section">
      <h1 class="fade-in">Доставка премиальной еды</h1>
      <p class="fade-in" style="animation-delay: 0.1s">Быстро, вкусно, в любую точку города.</p>
    </div>

    <div class="catalog-section">
      <h2 class="section-title">Наше меню</h2>
      
      <div v-if="loading" class="loading">
        Загрузка меню...
      </div>
      
      <div v-else class="catalog-content">
        <!-- Categories Sidebar / Topbar -->
        <div class="categories-menu">
          <button 
            class="cat-btn" 
            :class="{ active: selectedCategory === null }"
            @click="selectedCategory = null"
          >
            Все
          </button>
          <button 
            v-for="cat in categories" 
            :key="cat.id"
            class="cat-btn"
            :class="{ active: selectedCategory === cat.id }"
            @click="selectedCategory = cat.id"
          >
            {{ cat.name }}
          </button>
        </div>

        <!-- Products Grid -->
        <div class="products-grid">
          <div v-for="product in filteredProducts" :key="product.id" class="product-card fade-in">
            <div class="product-image">
              <img :src="product.image_url || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400&auto=format&fit=crop'" :alt="product.name">
            </div>
            <div class="product-info">
              <h3>{{ product.name }}</h3>
              <p class="desc">{{ product.description }}</p>
              <div class="product-footer">
                <span class="price">{{ product.price }} ₽</span>
                <button class="add-btn" @click="addToCart(product)">
                  В корзину
                </button>
              </div>
            </div>
          </div>
          <div v-if="filteredProducts.length === 0" class="no-products">
            В этой категории пока нет товаров.
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useCartStore } from '../store/cart'
import { fetchProducts, fetchCategories } from '../api/catalog'

const cartStore = useCartStore()
const products = ref([])
const categories = ref([])
const loading = ref(true)
const selectedCategory = ref(null)

onMounted(async () => {
  try {
    const [prodsData, catsData] = await Promise.all([
      fetchProducts(),
      fetchCategories()
    ])
    products.value = prodsData
    categories.value = catsData
  } catch (err) {
    console.error('Error loading catalog', err)
  } finally {
    loading.value = false
  }
})

const filteredProducts = computed(() => {
  if (!selectedCategory.value) return products.value
  return products.value.filter(p => p.category_id === selectedCategory.value)
})

const addToCart = (product) => {
  cartStore.addItem(product)
}
</script>

<style scoped>
.hero-section {
  text-align: center;
  padding: 4rem 1rem;
  background: linear-gradient(135deg, var(--surface-color-elevated) 0%, var(--surface-color) 100%);
  border-radius: var(--radius-lg);
  margin-bottom: 3rem;
  border: 1px solid var(--border-color);
}

.hero-section h1 {
  font-size: 3rem;
  margin-bottom: 1rem;
  background: -webkit-linear-gradient(45deg, var(--primary-color), #ff9e7a);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.hero-section p {
  font-size: 1.2rem;
  color: var(--text-secondary);
}

.section-title {
  font-size: 2rem;
  margin-bottom: 2rem;
  color: var(--text-primary);
}

.categories-menu {
  display: flex;
  gap: 1rem;
  margin-bottom: 2rem;
  overflow-x: auto;
  padding-bottom: 0.5rem;
}

.categories-menu::-webkit-scrollbar {
  height: 4px;
}

.categories-menu::-webkit-scrollbar-thumb {
  background: var(--border-color);
  border-radius: 4px;
}

.cat-btn {
  padding: 0.5rem 1.5rem;
  background: var(--surface-color-elevated);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-full);
  color: var(--text-secondary);
  font-weight: 500;
  white-space: nowrap;
  transition: all 0.2s;
}

.cat-btn:hover {
  background: var(--surface-color);
  color: var(--text-primary);
}

.cat-btn.active {
  background: var(--primary-color);
  border-color: var(--primary-color);
  color: white;
}

.no-products {
  grid-column: 1 / -1;
  text-align: center;
  padding: 3rem;
  color: var(--text-secondary);
  background: var(--surface-color);
  border-radius: var(--radius-md);
  border: 1px dashed var(--border-color);
}

.products-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 2rem;
}

.product-card {
  background: var(--surface-color);
  border-radius: var(--radius-md);
  overflow: hidden;
  border: 1px solid var(--border-color);
  transition: transform 0.3s, box-shadow 0.3s;
  display: flex;
  flex-direction: column;
}

.product-card:hover {
  transform: translateY(-5px);
  box-shadow: var(--shadow-md);
  border-color: var(--primary-color);
}

.product-image {
  height: 200px;
  width: 100%;
  overflow: hidden;
}

.product-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.5s;
}

.product-card:hover .product-image img {
  transform: scale(1.05);
}

.product-info {
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  flex: 1;
}

.product-info h3 {
  font-size: 1.25rem;
  margin-bottom: 0.5rem;
}

.desc {
  color: var(--text-secondary);
  font-size: 0.9rem;
  margin-bottom: 1.5rem;
  flex: 1;
}

.product-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: auto;
}

.price {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--primary-color);
}

.add-btn {
  background: var(--surface-color-elevated);
  color: var(--text-primary);
  padding: 0.5rem 1rem;
  border-radius: var(--radius-sm);
  font-weight: 600;
  border: 1px solid var(--border-color);
  transition: all 0.2s;
}

.add-btn:hover {
  background: var(--primary-color);
  border-color: var(--primary-color);
  color: white;
}

.loading {
  text-align: center;
  padding: 3rem;
  color: var(--text-secondary);
  font-size: 1.2rem;
}
</style>
