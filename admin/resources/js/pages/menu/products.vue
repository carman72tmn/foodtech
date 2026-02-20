<script setup>
import { ref, onMounted, computed } from "vue"

const loading = ref(false)
const syncing = ref(false)
const syncingPrices = ref(false)
const syncingStopList = ref(false)
const snackbar = ref(false)
const snackbarColor = ref("success")
const snackbarText = ref("")

const products = ref([])
const search = ref("")

const API_BASE = "/api"

const headers = [
  { title: "ID", key: "id", sortable: true, width: 70 },
  { title: "Название", key: "name", sortable: true },
  { title: "Артикул", key: "article", sortable: true, width: 120 },
  { title: "Цена", key: "price", sortable: true, width: 100 },
  { title: "Категория", key: "category_id", sortable: true, width: 120 },
  { title: "iiko ID", key: "iiko_id", sortable: false, width: 100 },
  { title: "Доступен", key: "is_available", sortable: true, width: 100 },
]

const showMessage = (text, color = "success") => {
  snackbarText.value = text
  snackbarColor.value = color
  snackbar.value = true
}

const loadProducts = async () => {
  loading.value = true
  try {
    const res = await fetch(`${API_BASE}/products/`)
    if (res.ok) {
      products.value = await res.json()
    }
  } catch (e) {
    showMessage("Ошибка загрузки товаров", "error")
  } finally {
    loading.value = false
  }
}

const syncMenu = async () => {
  syncing.value = true
  try {
    const res = await fetch(`${API_BASE}/iiko/sync-menu`, { method: "POST" })
    const data = await res.json()
    if (data.success) {
      showMessage(
        `Синхронизировано: ${data.categories_synced} категорий, ${data.products_synced} товаров`,
      )
      await loadProducts()
    } else {
      showMessage(data.message || "Ошибка синхронизации", "error")
    }
  } catch (e) {
    showMessage("Ошибка синхронизации меню", "error")
  } finally {
    syncing.value = false
  }
}

const syncPrices = async () => {
  syncingPrices.value = true
  try {
    const res = await fetch(`${API_BASE}/iiko/sync-prices`, { method: "POST" })
    const data = await res.json()
    if (data.success) {
      showMessage(`Обновлены цены для ${data.products_updated || 0} товаров`)
      await loadProducts()
    } else {
      showMessage("Ошибка синхронизации цен", "error")
    }
  } catch (e) {
    showMessage("Ошибка синхронизации цен", "error")
  } finally {
    syncingPrices.value = false
  }
}

const syncStopList = async () => {
  syncingStopList.value = true
  try {
    const res = await fetch(`${API_BASE}/iiko/sync-stop-lists`, {
      method: "POST",
    })

    const data = await res.json()
    if (data.success) {
      showMessage(
        `Обновлена доступность: ${data.products_updated || 0} товаров, в стоп-листе: ${data.stopped_count || 0}`,
      )
      await loadProducts()
    } else {
      showMessage("Ошибка синхронизации стоп-листа", "error")
    }
  } catch (e) {
    showMessage("Ошибка стоп-листа", "error")
  } finally {
    syncingStopList.value = false
  }
}

const filteredProducts = computed(() => {
  if (!search.value) return products.value
  const q = search.value.toLowerCase()
  
  return products.value.filter(
    p =>
      p.name?.toLowerCase().includes(q) ||
      p.article?.toLowerCase().includes(q) ||
      p.iiko_id?.toLowerCase().includes(q),
  )
})

const formatPrice = price => {
  return new Intl.NumberFormat("ru-RU", {
    style: "currency",
    currency: "RUB",
    minimumFractionDigits: 0,
  }).format(price)
}

onMounted(loadProducts)
</script>

<template>
  <VRow>
    <!-- Панель действий -->
    <VCol cols="12">
      <VCard>
        <VCardTitle class="d-flex align-center flex-wrap gap-4">
          <VIcon
            icon="mdi-food"
            class="me-2"
          />
          Товары
          <VSpacer />
          <VTextField
            v-model="search"
            density="compact"
            placeholder="Поиск..."
            prepend-inner-icon="mdi-magnify"
            style="max-width: 300px"
            hide-details
            clearable
          />
        </VCardTitle>
        <VCardText>
          <div class="d-flex gap-2 flex-wrap mb-4">
            <VBtn
              color="primary"
              :loading="syncing"
              prepend-icon="mdi-sync"
              @click="syncMenu"
            >
              Синхронизировать меню
            </VBtn>
            <VBtn
              color="secondary"
              variant="outlined"
              :loading="syncingPrices"
              prepend-icon="mdi-currency-rub"
              @click="syncPrices"
            >
              Обновить цены
            </VBtn>
            <VBtn
              color="warning"
              variant="outlined"
              :loading="syncingStopList"
              prepend-icon="mdi-cancel"
              @click="syncStopList"
            >
              Синхронизировать стоп-лист
            </VBtn>
          </div>

          <!-- Таблица товаров -->
          <VDataTable
            :headers="headers"
            :items="filteredProducts"
            :loading="loading"
            :items-per-page="25"
            class="elevation-1"
            density="compact"
          >
            <template #item.price="{ item }">
              {{ formatPrice(item.price) }}
            </template>
            <template #item.is_available="{ item }">
              <VChip
                :color="item.is_available ? 'success' : 'error'"
                variant="tonal"
                size="small"
              >
                {{ item.is_available ? "Да" : "Нет" }}
              </VChip>
            </template>
            <template #item.iiko_id="{ item }">
              <span
                v-if="item.iiko_id"
                class="text-caption text-medium-emphasis"
              >
                {{ item.iiko_id.substring(0, 8) }}...
              </span>
              <VChip
                v-else
                size="x-small"
                color="grey"
                variant="tonal"
              >
                Нет
              </VChip>
            </template>
          </VDataTable>
        </VCardText>
      </VCard>
    </VCol>
  </VRow>

  <VSnackbar
    v-model="snackbar"
    :color="snackbarColor"
    :timeout="4000"
    location="top"
  >
    {{ snackbarText }}
  </VSnackbar>
</template>
