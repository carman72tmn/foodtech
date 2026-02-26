<script setup>
import { ref, onMounted } from "vue"

const loading = ref(false)
const snackbar = ref(false)
const snackbarColor = ref("success")
const snackbarText = ref("")

const companies = ref([])

const API_BASE = "/api/v1/companies"

const headers = [
  { title: "ID", key: "id", sortable: true, width: 70 },
  { title: "Название", key: "name", sortable: true },
  { title: "ИНН", key: "inn", sortable: false },
  { title: "iiko Орг. ID", key: "iiko_organization_id", sortable: false },
  { title: "Активна", key: "is_active", sortable: true, width: 100 },
  { title: "Действия", key: "actions", sortable: false, width: 150 },
]

const showMessage = (text, color = "success") => {
  snackbarText.value = text
  snackbarColor.value = color
  snackbar.value = true
}

const loadCompanies = async () => {
  loading.value = true
  try {
    const res = await fetch(`${API_BASE}/`)
    if (res.ok) {
      companies.value = await res.json()
    }
  } catch (e) {
    showMessage("Ошибка загрузки компаний", "error")
  } finally {
    loading.value = false
  }
}

onMounted(loadCompanies)
</script>

<template>
  <VRow>
    <VCol cols="12">
      <VCard>
        <VCardTitle class="d-flex align-center">
          <VIcon icon="bx-buildings" class="me-2" />
          Мои компании
          <VSpacer />
          <VBtn color="primary" @click="loadCompanies" class="me-2" :loading="loading" variant="tonal" size="small">
            <VIcon icon="bx-refresh" /> Обновить
          </VBtn>
          <VBtn color="primary" size="small">
            <VIcon icon="bx-plus" /> Добавить
          </VBtn>
        </VCardTitle>
        <VCardText>
          <VDataTable
            :headers="headers"
            :items="companies"
            :loading="loading"
            :items-per-page="10"
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
            <template #item.iiko_organization_id="{ item }">
              <span v-if="item.iiko_organization_id" class="text-caption text-medium-emphasis">
                {{ item.iiko_organization_id.substring(0, 8) }}...
              </span>
              <VChip v-else size="x-small" color="grey" variant="tonal">Нет</VChip>
            </template>
            <template #item.actions="{ item }">
              <VBtn icon="bx-pencil" variant="text" size="small" color="primary"></VBtn>
              <VBtn icon="bx-trash" variant="text" size="small" color="error"></VBtn>
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
