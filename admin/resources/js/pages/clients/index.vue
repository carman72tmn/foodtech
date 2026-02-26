<script setup>
import { ref, onMounted } from 'vue'

const clients = ref([])
const loading = ref(true)

const headers = [
  { title: 'ID / Имя', key: 'id_name' },
  { title: 'Телефон', key: 'phone' },
  { title: 'Статус лояльности', key: 'loyalty_status_id' },
  { title: 'Бонусы (₽)', key: 'bonus_points', align: 'end' },
  { title: 'Заказы', key: 'total_orders_count', align: 'end' },
  { title: 'Сумма заказов', key: 'total_orders_amount', align: 'end' },
  { title: 'Дата посещения', key: 'last_order_date' },
  { title: 'Блок', key: 'is_blocked', align: 'center' },
  { title: 'Действия', key: 'actions', sortable: false, align: 'end' },
]

const getLoyaltyStatusName = (id) => {
    const statuses = {
        1: 'Бронзовый',
        2: 'Серебряный',
        3: 'Золотой',
        4: 'Платиновый'
    }
    return statuses[id] || 'Базовый'
}

const getLoyaltyColor = (id) => {
    const colors = {
        1: '#cd7f32',
        2: '#c0c0c0',
        3: '#ffd700',
        4: '#e5e4e2'
    }
    return colors[id] || 'grey'
}

const fetchClients = async () => {
  loading.value = true
  try {
    const response = await fetch('/api/v1/customers/')
    if (response.ok) {
        clients.value = await response.json()
    } else {
        clients.value = [
            { id: 104, name: 'Иван Сергеевич', phone: '79991234567', loyalty_status_id: 3, bonus_points: 1250.50, total_orders_count: 15, total_orders_amount: 25000, last_order_date: '2024-03-15T10:30:00Z', is_blocked: false },
             { id: 105, name: 'Анна', phone: '79009876543', loyalty_status_id: 1, bonus_points: 0, total_orders_count: 2, total_orders_amount: 3500, last_order_date: '2024-03-10T14:15:00Z', is_blocked: false },
              { id: 106, name: 'Тестовый (спамер)', phone: '79111111111', loyalty_status_id: null, bonus_points: 0, total_orders_count: 0, total_orders_amount: 0, last_order_date: null, is_blocked: true }
        ]
    }
  } catch (error) {
    console.error('Error fetching clients', error)
  } finally {
    loading.value = false
  }
}

const snackbar = ref({
    show: false,
    text: '',
    color: 'success'
})

const toggleBlock = async (item) => {
   try {
    const response = await fetch(`/api/v1/customers/${item.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ is_blocked: item.is_blocked })
    })
    
    if (response.ok) {
        snackbar.value = {
            show: true,
            text: item.is_blocked ? `Клиент ${item.name || ''} заблокирован` : `Клиент ${item.name || ''} разблокирован`,
            color: item.is_blocked ? 'error' : 'success'
        }
    } else {
        throw new Error('Failed to update status')
    }
   } catch(e) {
       console.error(e)
       item.is_blocked = !item.is_blocked // Revert UI
       snackbar.value = {
           show: true,
           text: 'Ошибка при обновлении статуса',
           color: 'error'
       }
   }
}

const formatMoney = (val) => {
    if(val === undefined || val === null) return '0'
    return new Intl.NumberFormat('ru-RU').format(val)
}

const formatDate = (val) => {
    if(!val) return 'Нет заказов'
    return new Intl.DateTimeFormat('ru-RU', { day: '2-digit', month: '2-digit', year: 'numeric' }).format(new Date(val))
}

onMounted(() => {
    fetchClients()
})
</script>

<template>
  <div>
    <div class="d-flex align-center justify-space-between mb-4">
      <h2 class="text-h4 mb-0">Все клиенты</h2>
      <div>
           <VBtn color="primary" variant="tonal" prepend-icon="ri-download-line" class="me-2">
            Экспорт
          </VBtn>
          <VBtn color="primary" prepend-icon="ri-add-line">
            Добавить клиента
          </VBtn>
      </div>
    </div>

    <VCard>
      <VCardText class="d-flex align-center flex-wrap gap-4">
        <div style="width: 250px;">
          <VTextField
            placeholder="Поиск по телефону или имени"
            prepend-inner-icon="ri-search-line"
            density="compact"
            hide-details
          />
        </div>
      </VCardText>
      <VDivider />

      <VDataTable
        :headers="headers"
        :items="clients"
        :loading="loading"
        hover
      >
         <template #item.id_name="{ item }">
            <div class="d-flex flex-column align-start">
               <span class="font-weight-medium">{{ item.name || 'Без имени' }}</span>
               <span class="text-caption text-disabled">ID: {{ item.id }}</span>
            </div>
         </template>

         <template #item.phone="{ item }">
             <span class="text-body-2 text-primary font-weight-medium">+{{ item.phone }}</span>
         </template>

         <template #item.loyalty_status_id="{ item }">
             <VChip size="small" :color="getLoyaltyColor(item.loyalty_status_id)">
                 {{ getLoyaltyStatusName(item.loyalty_status_id) }}
             </VChip>
         </template>

         <template #item.bonus_points="{ item }">
              <span class="text-success font-weight-bold">{{ formatMoney(item.bonus_points) }}</span>
         </template>
         
         <template #item.total_orders_amount="{ item }">
              <span>{{ formatMoney(item.total_orders_amount) }}</span>
         </template>

         <template #item.last_order_date="{ item }">
             <span class="text-body-2">{{ formatDate(item.last_order_date) }}</span>
         </template>

        <template #item.is_blocked="{ item }">
            <VSwitch
                v-model="item.is_blocked"
                color="error"
                density="compact"
                hide-details
                @change="toggleBlock(item)"
            />
        </template>

        <template #item.actions="{ item }">
             <VBtn icon="ri-eye-line" size="small" variant="text" color="primary" class="me-1" title="Открыть профиль" />
        </template>
      </VDataTable>
    </VCard>

    <VSnackbar
      v-model="snackbar.show"
      :color="snackbar.color"
      timeout="3000"
    >
      {{ snackbar.text }}
    </VSnackbar>
  </div>
</template>
