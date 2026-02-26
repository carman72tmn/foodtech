<script setup>
import { ref } from "vue"

const loadingMenu = ref(false)
const loadingPrices = ref(false)
const loadingStops = ref(false)

const snackbar = ref(false)
const snackbarColor = ref("success")
const snackbarText = ref("")

const API_BASE = "/api/v1/iiko"

const showMessage = (text, color = "success") => {
  snackbarText.value = text
  snackbarColor.value = color
  snackbar.value = true
}

const syncIiko = async (endpoint, loadingRef) => {
  loadingRef.value = true
  try {
    const res = await fetch(`${API_BASE}/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    })
    const data = await res.json()
    if (res.ok && data.success) {
      showMessage(data.message || "Синхронизация успешно завершена", "success")
    } else {
      showMessage(data.detail || data.message || "Ошибка синхронизации", "error")
    }
  } catch (e) {
    showMessage("Произошла ошибка при выполнении запроса", "error")
  } finally {
    loadingRef.value = false
  }
}
</script>

<template>
  <VRow>
    <VCol cols="12" md="6" lg="4">
      <VCard class="text-center pb-4">
        <VCardText class="d-flex flex-column justify-center align-center">
          <VAvatar
            color="primary"
            variant="tonal"
            size="50"
            class="mb-4"
          >
            <VIcon icon="bx-sync" size="30" />
          </VAvatar>
          <h6 class="text-h6 mb-2">Синхронизация Меню</h6>
          <span class="text-body-2 text-center text-medium-emphasis mb-4">
            Полная загрузка категорий, товаров, опций и размеров из IIKO.
          </span>
          <VBtn
            :loading="loadingMenu"
            color="primary"
            @click="syncIiko('sync-menu', loadingMenu)"
          >
            Синхронизировать
          </VBtn>
        </VCardText>
      </VCard>
    </VCol>

    <VCol cols="12" md="6" lg="4">
      <VCard class="text-center pb-4">
        <VCardText class="d-flex flex-column justify-center align-center">
          <VAvatar
            color="info"
            variant="tonal"
            size="50"
            class="mb-4"
          >
            <VIcon icon="bx-dollar" size="30" />
          </VAvatar>
          <h6 class="text-h6 mb-2">Обновление Цен</h6>
          <span class="text-body-2 text-center text-medium-emphasis mb-4">
            Быстрое обновление цен без полной перезагрузки структуры каталога.
          </span>
          <VBtn
            :loading="loadingPrices"
            color="info"
            @click="syncIiko('sync-prices', loadingPrices)"
          >
            Обновить цены
          </VBtn>
        </VCardText>
      </VCard>
    </VCol>

    <VCol cols="12" md="6" lg="4">
      <VCard class="text-center pb-4">
        <VCardText class="d-flex flex-column justify-center align-center">
          <VAvatar
            color="error"
            variant="tonal"
            size="50"
            class="mb-4"
          >
            <VIcon icon="bx-stop-circle" size="30" />
          </VAvatar>
          <h6 class="text-h6 mb-2">Стоп-листы</h6>
          <span class="text-body-2 text-center text-medium-emphasis mb-4">
            Синхронизация стоп-листов для скрытия недоступных товаров и ингредиентов.
          </span>
          <VBtn
            :loading="loadingStops"
            color="error"
            @click="syncIiko('sync-stop-lists', loadingStops)"
          >
            Загрузить стопы
          </VBtn>
        </VCardText>
      </VCard>
    </VCol>
  </VRow>

  <VSnackbar
    v-model="snackbar"
    :color="snackbarColor"
    :timeout="3000"
    location="top"
  >
    {{ snackbarText }}
  </VSnackbar>
</template>
