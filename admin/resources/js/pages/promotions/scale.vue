<script setup>
import { ref, onMounted } from 'vue'

const actions = ref([])
const loading = ref(true)

const headers = [
  { title: 'ID', key: 'id' },
  { title: 'Название акции', key: 'name' },
  { title: 'Тип скидки', key: 'action_type' },
  { title: 'От суммы (₽)', key: 'min_order_amount' },
  { title: 'Скидка', key: 'discount_value' },
  { title: 'Статус', key: 'is_active' },
  { title: 'Приоритет', key: 'priority' },
  { title: 'Действия', key: 'opts', sortable: false, align: 'end' },
]

const getActionTypeName = (type) => {
  const types = {
    gift_product: 'Товар в подарок',
    cart_discount: 'Скидка на корзину',
    delivery_discount: 'Бесплатная доставка'
  }
  return types[type] || type
}

const fetchActions = async () => {
  loading.value = true
  try {
    const response = await fetch('/api/v1/actions/')
    if (response.ok) {
        actions.value = await response.json()
    } else {
        // Fallback or demo data if backend gives error
        actions.value = [
            { id: 1, name: 'Сет в подарок от 3000', action_type: 'gift_product', min_order_amount: 3000, discount_value: 0, is_active: true, priority: 10 },
            { id: 2, name: 'Скидка 10% на корзину от 5000', action_type: 'cart_discount', min_order_amount: 5000, discount_value: 10, is_active: true, priority: 20 },
        ]
    }
  } catch (error) {
    console.error('Error fetching actions', error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
    fetchActions()
})
</script>

<template>
  <div>
    <div class="d-flex align-center justify-space-between mb-4">
      <h2 class="text-h4 mb-0">Акции (Шкала подарков)</h2>
      <VBtn color="primary" prepend-icon="ri-add-line">
        Добавить акцию
      </VBtn>
    </div>

    <VCard>
        <VCardText class="d-flex align-center">
            <span class="text-body-2 text-medium-emphasis">Автоматические акции применяются при достижении суммы корзины или других условий, без ввода промокода.</span>
        </VCardText>
        <VDivider />
      <VDataTable
        :headers="headers"
        :items="actions"
        :loading="loading"
        hover
      >
        <template #item.name="{ item }">
            <span class="font-weight-medium">{{ item.name }}</span>
        </template>
        <template #item.action_type="{ item }">
            <VChip size="small" color="primary" variant="tonal">
                {{ getActionTypeName(item.action_type) }}
            </VChip>
        </template>
        <template #item.discount_value="{ item }">
            <span v-if="item.action_type === 'cart_discount'">{{ item.discount_value }}%</span>
            <span v-else-if="item.action_type === 'delivery_discount'">100%</span>
            <span v-else>-</span>
        </template>
        <template #item.is_active="{ item }">
            <VSwitch
                v-model="item.is_active"
                color="success"
                density="compact"
                hide-details
            />
        </template>
        <template #item.opts="{ item }">
             <VBtn icon="ri-edit-line" size="small" variant="text" color="primary" class="me-1" />
             <VBtn icon="ri-delete-bin-line" size="small" variant="text" color="error" />
        </template>
      </VDataTable>
    </VCard>
  </div>
</template>
