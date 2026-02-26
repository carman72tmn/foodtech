<script setup>
import { ref, onMounted } from 'vue'

const funnels = ref([])
const loading = ref(true)

const headers = [
  { title: 'ID', key: 'id' },
  { title: 'Название воронки (цель)', key: 'name' },
  { title: 'Условие запуска (Триггер)', key: 'trigger' },
  { title: 'Шагов', key: 'steps_count', align: 'center' },
  { title: 'Попало в воронку', key: 'clients_entered', align: 'end' },
  { title: 'Купили (Конверсия)', key: 'clients_converted', align: 'end' },
  { title: 'Статус', key: 'is_active' },
  { title: 'Опции', key: 'opts', sortable: false, align: 'end' },
]

const getTriggerName = (type, val) => {
    const types = {
        no_orders_n_days: `Нет заказов ${val} дн.`,
        first_order: 'Первый заказ',
        registration: 'Регистрация',
        abandoned_cart: 'Брошенная корзина',
        birthday: `За ${val || 0} дн. до ДР`
    }
    return types[type] || type
}

const fetchFunnels = async () => {
  loading.value = true
  try {
    const response = await fetch('/api/v1/funnels/')
    if (response.ok) {
        funnels.value = await response.json()
    } else {
        // Fallback data
        funnels.value = [
            { id: 1, name: 'Возврат спящих клиентов', trigger_type: 'no_orders_n_days', trigger_value: 30, steps: '[{},{},{}]', clients_entered: 450, clients_converted: 65, is_active: true },
            { id: 2, name: 'Скидка на первый заказ 15%', trigger_type: 'registration', trigger_value: null, steps: '[{}]', clients_entered: 890, clients_converted: 640, is_active: true },
            { id: 3, name: 'Подарок на день рождения', trigger_type: 'birthday', trigger_value: 3, steps: '[{},{}]', clients_entered: 120, clients_converted: 80, is_active: false },
        ]
    }
  } catch (error) {
    console.error('Error fetching funnels', error)
  } finally {
    loading.value = false
  }
}

const toggleStatus = async (item) => {
   try {
    const response = await fetch(`/api/v1/funnels/${item.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ is_active: item.is_active })
    })
   } catch(e) {
       console.error(e)
   }
}

const getStepsCount = (stepsString) => {
    try {
        const steps = JSON.parse(stepsString)
        return steps.length || 0
    } catch(e) {
        return 0
    }
}

const getConversion = (entered, converted) => {
    if(entered === 0) return '0%'
    return ((converted / entered) * 100).toFixed(1) + '%'
}

onMounted(() => {
    fetchFunnels()
})
</script>

<template>
  <div>
    <div class="d-flex align-center justify-space-between mb-4">
      <h2 class="text-h4 mb-0">Воронки и Автоматизации</h2>
      <VBtn color="primary" prepend-icon="ri-filter-3-line">
         Собрать новую воронку
      </VBtn>
    </div>

    <VCard>
       <VCardText class="pb-0">
          <VAlert type="info" variant="text" border="start" border-color="primary" class="mb-4">
            <template #title>
              Авто-цепочки сообщений
            </template>
             Воронки позволяют настроить каскадные уведомления (СМС/Telegram/Отложка) при наступлении определенных событий. Например: <i>Система пришлет СМС если клиент не делал заказ 15 дней.</i>
          </VAlert>
       </VCardText>

      <VDataTable
        :headers="headers"
        :items="funnels"
        :loading="loading"
        hover
      >
        <template #item.name="{ item }">
            <span class="font-weight-medium text-primary">{{ item.name }}</span>
        </template>

        <template #item.trigger="{ item }">
             <VChip size="small" color="secondary" variant="tonal">
                 {{ getTriggerName(item.trigger_type, item.trigger_value) }}
             </VChip>
        </template>

         <template #item.steps_count="{ item }">
             <VAvatar size="24" color="primary" variant="tonal" class="text-caption font-weight-bold">
                 {{ getStepsCount(item.steps) }}
             </VAvatar>
         </template>
        
        <template #item.clients_converted="{ item }">
             <div class="d-flex flex-column align-end">
                <span class="font-weight-medium">{{ item.clients_converted }}</span>
                <span class="text-caption text-success font-weight-bold">{{ getConversion(item.clients_entered, item.clients_converted) }}</span>
             </div>
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
             <VBtn icon="ri-edit-line" size="small" variant="text" color="primary" class="me-1" title="Настроить шаги" />
             <VBtn icon="ri-file-copy-line" size="small" variant="text" color="secondary" class="me-1" title="Копировать воронку" />
             <VBtn icon="ri-delete-bin-line" size="small" variant="text" color="error" />
        </template>
      </VDataTable>
    </VCard>
  </div>
</template>
