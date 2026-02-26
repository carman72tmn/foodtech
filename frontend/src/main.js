import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import './assets/index.css'
import App from './App.vue'

// Basic routes
const routes = [
  { path: '/', component: () => import('./views/Home.vue') },
  { path: '/cart', component: () => import('./views/Cart.vue') },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

const pinia = createPinia()
const app = createApp(App)

app.use(router)
app.use(pinia)
app.mount('#app')
