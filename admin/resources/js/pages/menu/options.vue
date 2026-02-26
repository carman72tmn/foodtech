<script setup>
import { ref, onMounted, computed } from "vue"

const loading = ref(false)
const products = ref([])
const activeTab = ref('sizes')

const API_BASE = "/api/v1"

const loadData = async () => {
  loading.value = true
  try {
    const res = await fetch(`${API_BASE}/products/`)
    if (res.ok) {
      products.value = await res.json()
    }
  } catch (e) {
    console.error("Ошибка загрузки данных", e)
  } finally {
    loading.value = false
  }
}

// Flat lists for tables
const allSizes = computed(() => {
  const sizes = []
  products.value.forEach(p => {
    if (p.sizes && p.sizes.length > 0) {
      p.sizes.forEach(s => sizes.push({ ...s, product_name: p.name }))
    }
  })
  return sizes
})

const allModifierGroups = computed(() => {
  const groups = []
  products.value.forEach(p => {
    if (p.modifier_groups && p.modifier_groups.length > 0) {
      p.modifier_groups.forEach(mg => groups.push({ ...mg, product_name: p.name }))
    }
  })
  return groups
})

onMounted(loadData)
</script>

<template>
  <VRow>
    <VCol cols="12">
      <VCard>
        <VTabs
          v-model="activeTab"
          color="primary"
        >
          <VTab value="sizes">Размеры</VTab>
          <VTab value="modifiers">Модификаторы</VTab>
        </VTabs>

        <VCardText>
          <VWindow v-model="activeTab">
            <!-- Вкладка Размеры -->
            <VWindowItem value="sizes">
              <VDataTable
                :headers="[
                  { title: 'Товар', key: 'product_name' },
                  { title: 'Размер', key: 'name' },
                  { title: 'Цена', key: 'price' },
                  { title: 'По умолчанию', key: 'is_default' },
                  { title: 'iiko ID', key: 'iiko_id' }
                ]"
                :items="allSizes"
                :loading="loading"
                class="elevation-1 mt-4"
                density="compact"
              >
                <template #item.is_default="{ item }">
                  <VChip
                    :color="item.is_default ? 'success' : 'grey'"
                    size="small"
                  >
                    {{ item.is_default ? "Да" : "Нет" }}
                  </VChip>
                </template>
              </VDataTable>
            </VWindowItem>

            <!-- Вкладка Модификаторы -->
            <VWindowItem value="modifiers">
              <VDataTable
                :headers="[
                  { title: 'Товар', key: 'product_name' },
                  { title: 'Группа', key: 'name' },
                  { title: 'Обязательно', key: 'is_required' },
                  { title: 'Мин/Макс', key: 'limits', sortable: false },
                  { title: 'Модификаторы', key: 'modifiers_count' }
                ]"
                :items="allModifierGroups"
                :loading="loading"
                class="elevation-1 mt-4"
                density="compact"
              >
                <template #item.is_required="{ item }">
                  <VChip
                    :color="item.is_required ? 'warning' : 'grey'"
                    size="small"
                  >
                    {{ item.is_required ? "Да" : "Нет" }}
                  </VChip>
                </template>
                <template #item.limits="{ item }">
                  {{ item.min_amount }} - {{ item.max_amount }}
                </template>
                <template #item.modifiers_count="{ item }">
                  <VBtn
                    size="small"
                    variant="tonal"
                    color="primary"
                  >
                    {{ item.modifiers?.length || 0 }} шт.
                  </VBtn>
                </template>
              </VDataTable>
            </VWindowItem>
          </VWindow>
        </VCardText>
      </VCard>
    </VCol>
  </VRow>
</template>
