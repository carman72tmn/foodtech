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

const syncBranches = async () => {
  loading.value = true
  try {
    const res = await fetch(`${API_BASE}/sync`, { method: 'POST' })
    if (res.ok) {
      const data = await res.json()
      showMessage(data.message || "Успешно синхронизировано", "success")
      await loadBranches()
    } else {
      showMessage("Ошибка синхронизации с iiko", "error")
      loading.value = false
    }
  } catch (e) {
    showMessage("Ошибка связи при синхронизации", "error")
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
    showMessage("Ошибка обновления", "error")
  }
}

// Редактирование филиала
const editDialog = ref(false)
const saving = ref(false)
const editingBranch = ref({
  id: null,
  name: '',
  phone: '',
  address: '',
  working_hours: '',
  min_order_amount: 0,
  free_delivery_threshold: 0,
  latitude: null,
  longitude: null,
  is_active: true
})

const openEditDialog = (branch = null) => {
  if (branch) {
    editingBranch.value = { ...branch }
  } else {
    editingBranch.value = {
      id: null,
      name: '',
      phone: '',
      address: '',
      working_hours: '',
      min_order_amount: 0,
      free_delivery_threshold: 0,
      latitude: null,
      longitude: null,
      is_active: true
    }
  }
  editDialog.value = true
}

const saveBranch = async () => {
  if (!editingBranch.value.name || !editingBranch.value.address) {
    showMessage("Заполните обязательные поля (Название, Адрес)", "error")
    return
  }

  saving.value = true
  const isNew = !editingBranch.value.id
  const url = isNew ? API_BASE : `${API_BASE}/${editingBranch.value.id}`
  const method = isNew ? 'POST' : 'PATCH'

  try {
    const res = await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(editingBranch.value)
    })

    if (res.ok) {
      showMessage(isNew ? "Филиал добавлен" : "Филиал сохранен")
      editDialog.value = false
      loadBranches()
    } else {
      const data = await res.json()
      showMessage(data.detail || "Ошибка при сохранении", "error")
    }
  } catch (e) {
    showMessage("Ошибка сети при сохранении", "error")
  } finally {
    saving.value = false
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
          <VBtn color="primary" @click="syncBranches" class="me-2" :loading="loading" variant="tonal" size="small">
            <VIcon icon="bx-refresh" /> Синхронизировать с iiko
          </VBtn>
          <VBtn color="primary" size="small" @click="openEditDialog()">
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
              <VBtn icon="bx-pencil" variant="text" size="small" color="primary" @click="openEditDialog(item)"></VBtn>
              <VBtn icon="bx-trash" variant="text" size="small" color="error"></VBtn>
            </template>
          </VDataTable>
        </VCardText>
      </VCard>
    </VCol>
  </VRow>

  <VDialog v-model="editDialog" max-width="600">
    <VCard>
      <VCardTitle class="d-flex justify-space-between align-center">
        Редактирование филиала
        <VBtn icon="bx-x" variant="text" @click="editDialog = false"></VBtn>
      </VCardTitle>
      <VCardText>
        <VRow>
          <VCol cols="12" md="6">
            <VTextField v-model="editingBranch.name" label="Название" />
          </VCol>
          <VCol cols="12" md="6">
            <VTextField v-model="editingBranch.phone" label="Телефон" />
          </VCol>
          <VCol cols="12">
            <VTextField v-model="editingBranch.address" label="Адрес" />
          </VCol>
          <VCol cols="12" md="4">
            <VTextField v-model="editingBranch.working_hours" label="Часы работы" placeholder="10:00-22:00" />
          </VCol>
          <VCol cols="12" md="4">
            <VTextField v-model.number="editingBranch.min_order_amount" type="number" label="Мин. заказ (₽)" />
          </VCol>
          <VCol cols="12" md="4">
            <VTextField v-model.number="editingBranch.free_delivery_threshold" type="number" label="Беспл. доставка от (₽)" />
          </VCol>
          <VCol cols="12" md="6">
            <VTextField v-model.number="editingBranch.latitude" type="number" label="Широта" />
          </VCol>
          <VCol cols="12" md="6">
            <VTextField v-model.number="editingBranch.longitude" type="number" label="Долгота" />
          </VCol>
        </VRow>
      </VCardText>
      <VCardActions>
        <VSpacer />
        <VBtn variant="tonal" color="secondary" @click="editDialog = false">Отмена</VBtn>
        <VBtn variant="elevated" color="primary" :loading="saving" @click="saveBranch">Сохранить</VBtn>
      </VCardActions>
    </VCard>
  </VDialog>

  <VSnackbar v-model="snackbar" :color="snackbarColor" :timeout="3000" location="top">
    {{ snackbarText }}
  </VSnackbar>
</template>
