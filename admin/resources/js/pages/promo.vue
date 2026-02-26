<script setup>
import { ref, onMounted } from 'vue'

const promoCodes = ref([])
const loading = ref(true)

const headers = [
  { title: 'ID', key: 'id' },
  { title: 'Код', key: 'code' },
  { title: 'Название', key: 'name' },
  { title: 'Тип', key: 'promo_type' },
  { title: 'Значение', key: 'discount_value' },
  { title: 'Использований', key: 'current_uses' },
  { title: 'Статус', key: 'is_active' },
  { title: 'Действия', key: 'actions', sortable: false, align: 'end' },
]

const getPromoTypeName = (type) => {
  const types = {
    percent: 'Скидка %',
    fixed: 'Скидка ₽',
    gift: 'Подарок',
    free_items: 'Бесплатные товары',
    funnel: 'Воронка'
  }
  return types[type] || type
}

const getPromoTypeColor = (type) => {
  const colors = {
    percent: 'info',
    fixed: 'primary',
    gift: 'success',
    free_items: 'warning',
    funnel: 'secondary'
  }
  return colors[type] || 'default'
}

const fetchPromoCodes = async () => {
  loading.value = true
  try {
    // В реальном приложении здесь будет вызов API (useFetch или axios)
    const response = await fetch('/api/v1/promo-codes/')
    if (response.ok) {
      promoCodes.value = await response.json()
    } else {
      console.error('Failed to fetch promo codes')
      // Fallback data if API is not responding or not mocked properly in this context
      promoCodes.value = [
         { id: 1, code: 'NEW2025', name: 'Скидка новому клиенту', promo_type: 'percent', discount_value: 15, current_uses: 120, is_active: true },
         { id: 2, code: 'GIFTROLL', name: 'Ролл в подарок', promo_type: 'gift', discount_value: 0, current_uses: 45, is_active: true },
         { id: 3, code: 'MINUS500', name: 'Скидка 500р', promo_type: 'fixed', discount_value: 500, current_uses: 12, is_active: false },
      ]
    }
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

const toggleStatus = async (item) => {
   try {
    const response = await fetch(`/api/v1/promo-codes/${item.id}/toggle`, {
        method: 'POST'
    })
    if(response.ok) {
        item.is_active = !item.is_active
    }
   } catch(e) {
       console.error(e)
   }
}

const duplicatePromo = async (item) => {
   try {
    const response = await fetch(`/api/v1/promo-codes/${item.id}/duplicate`, {
        method: 'POST'
    })
    if(response.ok) {
        await fetchPromoCodes()
    }
   } catch(e) {
       console.error(e)
   }
}

const deletePromo = async (item) => {
   if(!confirm(`Удалить промокод ${item.code}?`)) return
   try {
    const response = await fetch(`/api/v1/promo-codes/${item.id}`, {
        method: 'DELETE'
    })
    if(response.ok) {
        await fetchPromoCodes()
    }
   } catch(e) {
       console.error(e)
   }
}


onMounted(() => {
  fetchPromoCodes()
})
</script>

<template>
  <div>
    <div class="d-flex align-center justify-space-between mb-4">
      <h2 class="text-h4 mb-0">Промокоды</h2>
      <div>
        <VBtn
          color="primary"
          prepend-icon="ri-add-line"
          class="me-2"
        >
          Создать
        </VBtn>
        <VBtn
          color="secondary"
          variant="tonal"
          prepend-icon="ri-file-copy-line"
        >
          Массовая генерация
        </VBtn>
      </div>
    </div>

    <VCard>
      <VCardText class="d-flex align-center flex-wrap gap-4">
        <div style="width: 250px;">
          <VTextField
            placeholder="Поиск по коду или названию"
            prepend-inner-icon="ri-search-line"
            density="compact"
            hide-details
          />
        </div>
        <VSpacer />
        <div style="width: 200px;">
          <VSelect
            label="Статус"
            :items="['Все', 'Активные', 'Архив']"
            density="compact"
            hide-details
          />
        </div>
        <div style="width: 200px;">
          <VSelect
            label="Тип"
            :items="['Все', 'Скидка %', 'Скидка ₽', 'Подарок', 'Бесплатные товары']"
            density="compact"
            hide-details
          />
        </div>
      </VCardText>

      <VDivider />

      <VDataTable
        :headers="headers"
        :items="promoCodes"
        :loading="loading"
        hover
      >
        <template #item.code="{ item }">
          <span class="font-weight-bold text-primary">{{ item.code }}</span>
        </template>
        
        <template #item.promo_type="{ item }">
          <VChip
            :color="getPromoTypeColor(item.promo_type)"
            size="small"
            label
          >
            {{ getPromoTypeName(item.promo_type) }}
          </VChip>
        </template>
        
        <template #item.discount_value="{ item }">
          <span v-if="item.promo_type === 'percent'">{{ item.discount_value }}%</span>
          <span v-else-if="item.promo_type === 'fixed'">{{ item.discount_value }} ₽</span>
          <span v-else class="text-disabled">-</span>
        </template>

        <template #item.is_active="{ item }">
          <VSwitch
            v-model="item.is_active"
            color="success"
            density="compact"
            hide-details
            @change="toggleStatus(item)"
          />
        </template>

        <template #item.actions="{ item }">
          <div class="d-flex justify-end pr-1">
             <VBtn
                icon="ri-edit-line"
                size="small"
                variant="text"
                color="primary"
                class="me-1"
             />
             <VBtn
                icon="ri-file-copy-line"
                size="small"
                variant="text"
                color="secondary"
                class="me-1"
                @click="duplicatePromo(item)"
             />
             <VBtn
                icon="ri-delete-bin-line"
                size="small"
                variant="text"
                color="error"
                @click="deletePromo(item)"
             />
          </div>
        </template>
      </VDataTable>
    </VCard>
  </div>
</template>
