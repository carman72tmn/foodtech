<script setup>
import { ref, onMounted, onUnmounted } from "vue"

const loading = ref(false)
const snackbar = ref(false)
const snackbarColor = ref("success")
const snackbarText = ref("")

const orders = ref([])
const expanded = ref([])

const API_BASE = "/api/v1/orders"

const headers = [
  { title: "ID", key: "id", sortable: true, width: 70 },
  { title: "iiko ID", key: "iiko_order_id", sortable: false },
  { title: "Клиент", key: "customer_name", sortable: true },
  { title: "Телефон", key: "customer_phone", sortable: false },
  { title: "Адрес", key: "delivery_address", sortable: false },
  { title: "Сумма", key: "total_amount", sortable: true },
  { title: "Статус", key: "status", sortable: true },
  { title: "Создан", key: "created_at", sortable: true },
  { title: "", key: "data-table-expand", sortable: false },
]

const statusColors = {
  new: "info",
  confirmed: "primary",
  cooking: "warning",
  ready: "success",
  delivering: "info",
  delivered: "success",
  cancelled: "error"
}

const statusNames = {
  new: "Новый",
  confirmed: "Подтвержден",
  cooking: "Готовится",
  ready: "Готов",
  delivering: "В пути",
  delivered: "Доставлен",
  cancelled: "Отменен"
}

let updateInterval = null

const showMessage = (text, color = "success") => {
  snackbarText.value = text
  snackbarColor.value = color
  snackbar.value = true
}

const loadOrders = async (silent = false) => {
  if (!silent) loading.value = true
  try {
    const res = await fetch(`${API_BASE}/`)
    if (res.ok) {
      orders.value = await res.json()
    }
  } catch (e) {
    if (!silent) showMessage("Ошибка загрузки заказов", "error")
  } finally {
    if (!silent) loading.value = false
  }
}

const cancelOrder = async (id) => {
  if (!confirm("Вы уверены, что хотите отменить этот заказ?")) return
  
  try {
    const res = await fetch(`${API_BASE}/${id}/cancel`, {
      method: 'POST'
    })
    if (res.ok) {
      showMessage("Заказ успешно отменен")
      loadOrders(false)
    } else {
      const data = await res.json()
      showMessage(data.detail || "Ошибка при отмене", "error")
    }
  } catch (e) {
    showMessage("Ошибка при отмене заказа", "error")
  }
}

const formatDate = (dateString) => {
  if (!dateString) return ""
  const date = new Date(dateString)
  return new Intl.DateTimeFormat('ru-RU', {
    day: '2-digit', month: '2-digit', year: 'numeric',
    hour: '2-digit', minute: '2-digit'
  }).format(date)
}

onMounted(() => {
  loadOrders()
  // Автообновление каждые 30 секунд
  updateInterval = setInterval(() => {
    loadOrders(true)
  }, 30000)
})

onUnmounted(() => {
  if (updateInterval) {
    clearInterval(updateInterval)
  }
})
</script>

<template>
  <VRow>
    <VCol cols="12">
      <VCard>
        <VCardTitle class="d-flex align-center">
          <VIcon icon="bx-cart" class="me-2" />
          Управление заказами
          <VSpacer />
          <VBtn color="primary" @click="loadOrders(false)" class="me-2" :loading="loading" variant="tonal" size="small">
            <VIcon icon="bx-refresh" /> Обновить
          </VBtn>
        </VCardTitle>
        <VCardText>
          <VDataTable
            v-model:expanded="expanded"
            :headers="headers"
            :items="orders"
            :loading="loading"
            :items-per-page="15"
            item-value="id"
            show-expand
            class="elevation-1"
            density="compact"
          >
            <template #item.iiko_order_id="{ item }">
              <span v-if="item.iiko_order_id" class="text-caption text-medium-emphasis">
                {{ item.iiko_order_id.substring(0, 8) }}...
              </span>
              <VChip v-else size="x-small" color="grey" variant="tonal">В iiko не передан</VChip>
            </template>
            
            <template #item.total_amount="{ item }">
              <strong>{{ item.total_amount }} ₽</strong>
            </template>

            <template #item.status="{ item }">
              <VChip
                :color="statusColors[item.status] || 'grey'"
                variant="elevated"
                size="small"
              >
                {{ statusNames[item.status] || item.status }}
              </VChip>
            </template>

            <template #item.created_at="{ item }">
              {{ formatDate(item.created_at) }}
            </template>
            
            <template #expanded-row="{ columns, item }">
              <tr>
                <td :colspan="columns.length" class="pa-4 bg-var-theme-background">
                  <VRow>
                    <VCol cols="12" md="8">
                      <h4 class="mb-2">Состав заказа</h4>
                      <VTable density="compact" class="elevation-1">
                        <thead>
                          <tr>
                            <th>Товар</th>
                            <th>Кол-во</th>
                            <th>Цена</th>
                            <th>Сумма</th>
                          </tr>
                        </thead>
                        <tbody>
                          <tr v-for="orderItem in item.items" :key="orderItem.id">
                            <td>{{ orderItem.product_name }}</td>
                            <td>{{ orderItem.quantity }} шт.</td>
                            <td>{{ orderItem.price }} ₽</td>
                            <td><strong>{{ orderItem.total }} ₽</strong></td>
                          </tr>
                        </tbody>
                      </VTable>
                      <div class="mt-2 text-wrap">
                        <strong class="text-caption">Комментарий клиента:</strong>
                        <p class="text-body-2 font-italic">{{ item.comment || 'Нет комментария' }}</p>
                      </div>
                    </VCol>
                    <VCol cols="12" md="4">
                      <h4 class="mb-2">Действия с заказом</h4>
                      <div class="d-flex flex-column gap-2">
                        <VBtn size="small" color="primary" variant="outlined" block>
                          <VIcon icon="bx-sync" class="me-2" /> Синхронизировать с iiko
                        </VBtn>
                        <VBtn 
                          size="small" 
                          color="error" 
                          variant="tonal" 
                          block 
                          @click="cancelOrder(item.id)"
                          :disabled="['delivered', 'cancelled'].includes(item.status)"
                        >
                          <VIcon icon="bx-x" class="me-2" /> Отменить заказ
                        </VBtn>
                        <div class="mt-4">
                           <small class="text-medium-emphasis">Telegram: 
                             <a v-if="item.telegram_username" :href="`https://t.me/${item.telegram_username}`" target="_blank">@{{ item.telegram_username }}</a>
                             <span v-else>{{ item.telegram_user_id }}</span>
                           </small>
                        </div>
                      </div>
                    </VCol>
                  </VRow>
                </td>
              </tr>
            </template>
            
          </VDataTable>
        </VCardText>
      </VCard>
    </VCol>
  </VRow>

  <VSnackbar v-model="snackbar" :color="snackbarColor" :timeout="3000" location="top">
    {{ snackbarText }}
  </VSnackbar>
</template>
