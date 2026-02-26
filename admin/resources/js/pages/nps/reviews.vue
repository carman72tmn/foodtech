<script setup>
import { ref, onMounted } from 'vue'

const reviews = ref([])
const loading = ref(true)
const statusFilter = ref('Все')

const headers = [
  { title: 'ID', key: 'id' },
  { title: 'Заказ', key: 'order_id' },
  { title: 'Оценки', key: 'scores' },
  { title: 'Комментарий клиента', key: 'comment', width: '30%' },
  { title: 'Обработан', key: 'is_processed' },
  { title: 'Решение менеджера', key: 'manager_comment', width: '25%' },
  { title: 'Действия', key: 'actions', sortable: false, align: 'end' },
]

const fetchReviews = async () => {
  loading.value = true
  try {
    const response = await fetch('/api/v1/nps/')
    if (response.ok) {
        reviews.value = await response.json()
    } else {
        reviews.value = [
            { id: 1, order_id: 1045, score: 5, kitchen_score: 5, delivery_score: 5, comment: 'Всё супер вкусно, спасибо!', is_processed: true, manager_comment: 'Поблагодарили клиента в ответном СМС.' },
            { id: 2, order_id: 1042, score: 2, kitchen_score: 4, delivery_score: 1, comment: 'Курьер опоздал на час, роллы приехали холодные.', is_processed: false, manager_comment: null },
            { id: 3, order_id: 1040, score: 4, kitchen_score: 4, delivery_score: 5, comment: '', is_processed: false, manager_comment: null },
        ]
    }
  } catch (error) {
    console.error('Error fetching reviews', error)
  } finally {
    loading.value = false
  }
}

const toggleStatus = async (item) => {
   try {
    const response = await fetch(`/api/v1/nps/${item.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ is_processed: item.is_processed })
    })
   } catch(e) {
       console.error(e)
   }
}

onMounted(() => {
    fetchReviews()
})
</script>

<template>
  <div>
    <div class="d-flex align-center justify-space-between mb-4">
      <h2 class="text-h4 mb-0">Отзывы (NPS)</h2>
    </div>

    <VCard>
      <VCardText class="d-flex align-center flex-wrap gap-4">
        <div style="width: 200px;">
          <VSelect
            v-model="statusFilter"
            label="Статус"
            :items="['Все', 'Новые (не обработаны)', 'Решённые']"
            density="compact"
            hide-details
          />
        </div>
      </VCardText>
      <VDivider />

      <VDataTable
        :headers="headers"
        :items="reviews"
        :loading="loading"
        hover
      >
        <template #item.scores="{ item }">
            <div class="d-flex flex-column gap-1">
                <VChip size="x-small" :color="item.score >= 4 ? 'success' : (item.score === 3 ? 'warning' : 'error')" variant="flat">
                    Общая: {{ item.score }}
                </VChip>
                <div class="d-flex gap-1" v-if="item.kitchen_score || item.delivery_score">
                    <VChip size="x-small" variant="outlined" v-if="item.kitchen_score">Кухня: {{ item.kitchen_score }}</VChip>
                    <VChip size="x-small" variant="outlined" v-if="item.delivery_score">Доставка: {{ item.delivery_score }}</VChip>
                </div>
            </div>
        </template>
        
        <template #item.order_id="{ item }">
            <a href="#" class="text-primary font-weight-medium text-decoration-none">#{{ item.order_id }}</a>
        </template>
        
        <template #item.is_processed="{ item }">
            <VSwitch
                v-model="item.is_processed"
                color="success"
                density="compact"
                hide-details
                @change="toggleStatus(item)"
            />
        </template>

        <template #item.manager_comment="{ item }">
            <div v-if="item.manager_comment" class="text-body-2 text-medium-emphasis">
                {{ item.manager_comment }}
            </div>
            <div v-else class="text-disabled text-caption">
                Без комментария
            </div>
        </template>

        <template #item.actions="{ item }">
             <VBtn icon="ri-chat-check-line" size="small" variant="text" color="primary" class="me-1" title="Добавить решение" />
        </template>
      </VDataTable>
    </VCard>
  </div>
</template>
