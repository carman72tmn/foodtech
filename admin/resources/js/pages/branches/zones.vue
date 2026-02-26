<script setup>
import { ref, onMounted } from "vue"

const loading = ref(false)
const snackbar = ref(false)
const snackbarColor = ref("success")
const snackbarText = ref("")

const branches = ref([])
const selectedBranch = ref(null)
const zones = ref([])

const API_BASE = "/api/v1"

const headers = [
  { title: "ID", key: "id", sortable: true, width: 70 },
  { title: "Название", key: "name", sortable: true },
  { title: "Мин. заказ (₽)", key: "min_order_amount", sortable: true },
  { title: "Ст-ть доставки (₽)", key: "delivery_cost", sortable: true },
  { title: "Бесплатно от (₽)", key: "free_delivery_from", sortable: true },
  { title: "Активна", key: "is_active", sortable: true, width: 100 },
  { title: "Действия", key: "actions", sortable: false, width: 150 },
]

const showMessage = (text, color = "success") => {
  snackbarText.value = text
  snackbarColor.value = color
  snackbar.value = true
}

const loadData = async () => {
  loading.value = true
  try {
    const branchesRes = await fetch(`${API_BASE}/branches/`)
    if (branchesRes.ok) {
      branches.value = await branchesRes.json()
      if (branches.value.length > 0) {
        selectedBranch.value = branches.value[0].id
        await loadZones(selectedBranch.value)
      }
    }
  } catch (e) {
    showMessage("Ошибка загрузки данных", "error")
  } finally {
    loading.value = false
  }
}

const loadZones = async (branchId) => {
  if (!branchId) return
  loading.value = true
  try {
    const res = await fetch(`${API_BASE}/branches/${branchId}/zones`)
    if (res.ok) {
      zones.value = await res.json()
    }
  } catch (e) {
    showMessage("Ошибка загрузки зон доставки", "error")
  } finally {
    loading.value = false
  }
}

const onBranchChange = (newVal) => {
  loadZones(newVal)
}

onMounted(loadData)
</script>

<template>
  <VRow>
    <VCol cols="12">
      <VCard>
        <VCardTitle class="d-flex align-center">
          <VIcon icon="bx-map-alt" class="me-2" />
          Зоны доставки
          <VSpacer />
          <div style="width: 300px" class="me-4">
             <VSelect
              v-model="selectedBranch"
              :items="branches"
              item-title="name"
              item-value="id"
              label="Выберите филиал"
              density="compact"
              hide-details
              @update:modelValue="onBranchChange"
            />
          </div>
          <VBtn color="primary" @click="loadZones(selectedBranch)" class="me-2" :loading="loading" variant="tonal" size="small">
            <VIcon icon="bx-refresh" /> Обновить
          </VBtn>
          <VBtn color="primary" size="small" :disabled="!selectedBranch">
            <VIcon icon="bx-plus" /> Добавить
          </VBtn>
        </VCardTitle>
        <VCardText>
          <VDataTable
            :headers="headers"
            :items="zones"
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
