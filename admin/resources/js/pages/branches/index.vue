<script setup>
import { ref, onMounted } from "vue"

const loading = ref(false)
const snackbar = ref(false)
const snackbarColor = ref("success")
const snackbarText = ref("")

const branches = ref([])

const API_BASE = "/api/v1/branches"

const headers = [
  { title: "ID", key: "id", sortable: true, width: 70 },
  { title: "Название", key: "name", sortable: true },
  { title: "Адрес", key: "address", sortable: false },
  { title: "Телефон", key: "phone", sortable: false },
  { title: "ID компании", key: "company_id", sortable: true },
  { title: "Активен", key: "is_active", sortable: true, width: 100 },
  { title: "Заказы", key: "is_accepting_orders", sortable: true, width: 100 },
  { title: "Доставка", key: "is_accepting_delivery", sortable: true, width: 100 },
  { title: "Самовывоз", key: "is_accepting_pickup", sortable: true, width: 100 },
  { title: "Действия", key: "actions", sortable: false, width: 150 },
]

const showMessage = (text, color = "success") => {
  snackbarText.value = text
  snackbarColor.value = color
  snackbar.value = true
}

const loadBranches = async () => {
  loading.value = true
  try {
    const res = await fetch(`${API_BASE}/`)
    if (res.ok) {
      branches.value = await res.json()
    }
  } catch (e) {
    showMessage("Ошибка загрузки филиалов", "error")
  } finally {
    loading.value = false
  }
}

const updateBranchStatus = async (branch, field) => {
  try {
    const res = await fetch(`${API_BASE}/${branch.id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        [field]: branch[field],
      }),
    })

    if (!res.ok) {
      throw new Error('Network response was not ok')
    }
    
    showMessage("Статус обновлен", "success")
  } catch (e) {
    // Revert change on error
    branch[field] = !branch[field]
    showMessage("Ошибка обновления статуса", "error")
  }
}

onMounted(loadBranches)
</script>

<template>
  <VRow>
    <VCol cols="12">
      <VCard>
        <VCardTitle class="d-flex align-center">
          <VIcon icon="bx-store" class="me-2" />
          Все филиалы
          <VSpacer />
          <VBtn color="primary" @click="loadBranches" class="me-2" :loading="loading" variant="tonal" size="small">
            <VIcon icon="bx-refresh" /> Обновить
          </VBtn>
          <VBtn color="primary" size="small">
            <VIcon icon="bx-plus" /> Добавить
          </VBtn>
        </VCardTitle>
        <VCardText>
          <VDataTable
            :headers="headers"
            :items="branches"
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
            <template #item.is_accepting_orders="{ item }">
              <VSwitch
                v-model="item.is_accepting_orders"
                inset
                color="success"
                hide-details
                @change="updateBranchStatus(item, 'is_accepting_orders')"
              />
            </template>
            <template #item.is_accepting_delivery="{ item }">
              <VSwitch
                v-model="item.is_accepting_delivery"
                inset
                color="success"
                hide-details
                @change="updateBranchStatus(item, 'is_accepting_delivery')"
              />
            </template>
            <template #item.is_accepting_pickup="{ item }">
              <VSwitch
                v-model="item.is_accepting_pickup"
                inset
                color="success"
                hide-details
                @change="updateBranchStatus(item, 'is_accepting_pickup')"
              />
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
