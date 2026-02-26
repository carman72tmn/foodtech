<script setup>
import { ref, onMounted } from 'vue'

const stories = ref([])
const loading = ref(true)

const headers = [
  { title: 'ID', key: 'id' },
  { title: 'Миниатюра', key: 'thumbnail', sortable: false },
  { title: 'Название истории (внутреннее)', key: 'title' },
  { title: 'Действие по клику', key: 'action' },
  { title: 'Показы', key: 'views_count', align: 'end' },
  { title: 'Клики', key: 'clicks_count', align: 'end' },
  { title: 'Порядок', key: 'sort_order', align: 'center' },
  { title: 'Статус', key: 'is_active' },
  { title: 'Опции', key: 'opts', sortable: false, align: 'end' },
]

const getActionName = (type, target) => {
    if(!type) return 'Отсутствует (только картинка)'
    const types = {
        open_product: `Товар ID: ${target}`,
        open_category: `Категория ID: ${target}`,
        open_promo: `Акция ID: ${target}`,
        external_link: `Внешняя ссылка: ${target}`,
    }
    return types[type] || type
}

const fetchStories = async () => {
  loading.value = true
  try {
    const response = await fetch('/api/v1/stories/')
    if (response.ok) {
        stories.value = await response.json()
    } else {
        stories.value = [
            { id: 1, title: 'Анонс весеннего меню', image_url: 'https://via.placeholder.com/150x250', action_type: 'open_category', action_target: '34', views_count: 1420, clicks_count: 320, sort_order: 10, is_active: true },
            { id: 2, title: 'Как мы готовим пиццу (видео)', image_url: 'https://via.placeholder.com/150x250/ff7f7f', action_type: null, action_target: null, views_count: 850, clicks_count: 0, sort_order: 20, is_active: true },
            { id: 3, title: 'Секретный промокод', image_url: 'https://via.placeholder.com/150x250/7f7fff', action_type: 'open_promo', action_target: '5', views_count: 400, clicks_count: 150, sort_order: 30, is_active: false },
        ]
    }
  } catch (error) {
    console.error('Error fetching stories', error)
  } finally {
    loading.value = false
  }
}

const toggleStatus = async (item) => {
   try {
    const response = await fetch(`/api/v1/stories/${item.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ is_active: item.is_active })
    })
   } catch(e) {
       console.error(e)
   }
}

onMounted(() => {
    fetchStories()
})
</script>

<template>
  <div>
    <div class="d-flex align-center justify-space-between mb-4">
      <h2 class="text-h4 mb-0">Истории (Stories)</h2>
      <VBtn color="primary" prepend-icon="ri-image-add-line">
         Загрузить историю
      </VBtn>
    </div>

    <VCard>
       <VCardText class="pb-0">
          <VAlert type="info" variant="tonal" class="mb-4">
             Истории отображаются на главной странице сайта и в приложении в виде кружочков (как в соц. сетях). Рекомендуемый размер медиафайлов: 1080x1920px (9:16).
          </VAlert>
       </VCardText>

      <VDataTable
        :headers="headers"
        :items="stories"
        :loading="loading"
        hover
      >
        <template #item.thumbnail="{ item }">
            <VAvatar size="48" rounded class="my-2">
                <VImg :src="item.image_url" cover />
            </VAvatar>
        </template>
        
        <template #item.title="{ item }">
            <span class="font-weight-medium">{{ item.title }}</span>
        </template>

        <template #item.action="{ item }">
             <span class="text-body-2 text-medium-emphasis">{{ getActionName(item.action_type, item.action_target) }}</span>
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

        <template #item.opts="{ item }">
             <VBtn icon="ri-edit-line" size="small" variant="text" color="primary" class="me-1" />
             <VBtn icon="ri-drag-move-2-fill" size="small" variant="text" color="secondary" class="me-1" title="Изменить порядок" />
             <VBtn icon="ri-delete-bin-line" size="small" variant="text" color="error" />
        </template>
      </VDataTable>
    </VCard>
  </div>
</template>
