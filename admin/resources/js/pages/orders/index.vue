<script setup>
import { ref, onMounted } from "vue"

const orders = ref([])
const loading = ref(true)

const fetchOrders = async () => {
  try {
    // Assuming axios is globally available or we use fetch
    const response = await fetch("/api/orders")
    if (response.ok) {
      orders.value = await response.json()
    } else {
      console.error("Failed to fetch orders")
    }
  } catch (error) {
    console.error("Error fetching orders:", error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchOrders()
})
</script>

<template>
  <VCard title="Заказы">
    <VCardText>
      <VTable>
        <thead>
          <tr>
            <th class="text-uppercase">
              ID
            </th>
            <th>Клиент</th>
            <th>Статус</th>
            <th>Сумма</th>
            <th>Адрес</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="order in orders"
            :key="order.id"
          >
            <td>{{ order.id }}</td>
            <td>
              {{ order.customer_name }}<br>
              <small>{{ order.customer_phone }}</small>
            </td>
            <td>{{ order.status }}</td>
            <td>{{ order.total_amount }}</td>
            <td>{{ order.delivery_address }}</td>
          </tr>
          <tr v-if="orders.length === 0 && !loading">
            <td
              colspan="5"
              class="text-center"
            >
              Нет заказов
            </td>
          </tr>
          <tr v-if="loading">
            <td
              colspan="5"
              class="text-center"
            >
              Загрузка...
            </td>
          </tr>
        </tbody>
      </VTable>
    </VCardText>
  </VCard>
</template>
