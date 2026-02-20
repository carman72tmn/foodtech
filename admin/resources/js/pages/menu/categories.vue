<script setup>
import { ref, onMounted } from "vue"

const loading = ref(false)
const snackbar = ref(false)
const snackbarColor = ref("success")
const snackbarText = ref("")

const categories = ref([])

const API_BASE = "/api"

const headers = [
  { title: "ID", key: "id", sortable: true, width: 70 },
  { title: "Название", key: "name", sortable: true },
  { title: "Описание", key: "description", sortable: false },
  { title: "iiko ID", key: "iiko_id", sortable: false, width: 100 },
  { title: "Порядок", key: "sort_order", sortable: true, width: 90 },
  { title: "Активна", key: "is_active", sortable: true, width: 100 },
]

const showMessage = (text, color = "success") => {
  snackbarText.value = text
  snackbarColor.value = color
  snackbar.value = true
}

const loadCategories = async () => {
  loading.value = true
  try {
    const res = await fetch(`${API_BASE}/categories/`)
    if (res.ok) {
      categories.value = await res.json()
    }
  } catch (e) {
    showMessage("Ошибка загрузки категорий", "error")
  } finally {
    loading.value = false
  }
}

onMounted(loadCategories)
</script>

<template>
  <VRow>
    <VCol cols="12">
      <VCard>
        <VCardTitle class="d-flex align-center">
          <VIcon
            icon="mdi-shape"
            class="me-2"
          />
          Категории
          <VSpacer />
          <VChip
            color="primary"
            variant="tonal"
          >
            {{ categories.length }} категорий
          </VChip>
        </VCardTitle>
        <VCardText>
          <VDataTable
            :headers="headers"
            :items="categories"
            :loading="loading"
            :items-per-page="25"
            class="elevation-1"
            density="compact"
          >
            <template #item.is_active="{ item }">
              <VChip
                :color="item.is_active ? 'success' : 'error'"
                variant="tonal"
                size="small"
              >
                {{ item.is_active ? "Да" : "Нет" }}
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
    :timeout="3000"
    location="top"
  >
    {{ snackbarText }}
  </VSnackbar>
</template>
