<script setup>
import { ref, onMounted } from 'vue'

const rules = ref([])
const loading = ref(true)

const headers = [
  { title: 'ID', key: 'id' },
  { title: 'Название (статус)', key: 'title' },
  { title: 'Тип', key: 'rule_type' },
  { title: 'Кэшбек %', key: 'cashback_percent' },
  { title: 'Срок бонусов (дн)', key: 'bonus_ttl_days' },
  { title: 'Срок статуса (дн)', key: 'status_ttl_days' },
  { title: 'Активен', key: 'is_active' },
  { title: 'Действия', key: 'actions', sortable: false, align: 'end' },
]

const fetchRules = async () => {
  loading.value = true
  try {
    const response = await fetch('/api/v1/loyalty/rules/')
    if (response.ok) {
        rules.value = await response.json()
    } else {
        rules.value = [
            { id: 1, title: 'Базовый (Новичок)', rule_type: 'cashback', cashback_percent: 3, bonus_ttl_days: 90, status_ttl_days: 0, is_active: true },
            { id: 2, title: 'Бронзовый (от 5000₽)', rule_type: 'cashback', cashback_percent: 5, bonus_ttl_days: 90, status_ttl_days: 365, is_active: true },
            { id: 3, title: 'Серебряный (от 15000₽)', rule_type: 'cashback', cashback_percent: 7, bonus_ttl_days: 90, status_ttl_days: 365, is_active: true },
            { id: 4, title: 'Золотой (от 30000₽)', rule_type: 'cashback', cashback_percent: 10, bonus_ttl_days: 180, status_ttl_days: 365, is_active: true },
        ]
    }
  } catch (error) {
    console.error('Error fetching loyalty rules', error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
    fetchRules()
})
</script>

<template>
  <div>
    <div class="d-flex align-center justify-space-between mb-4">
      <h2 class="text-h4 mb-0">Программа лояльности</h2>
      <div>
          <VBtn color="primary" variant="tonal" prepend-icon="ri-settings-3-line" class="me-2">
            Настройки iikoCard
          </VBtn>
          <VBtn color="primary" prepend-icon="ri-add-line">
            Добавить правило
          </VBtn>
      </div>
    </div>

    <VRow class="mb-4">
        <VCol cols="12" md="4">
            <VCard>
                <VCardItem title="Оплата бонусами" />
                <VCardText>
                    <div class="d-flex align-center justify-space-between">
                        <span class="text-body-1">Лимит списания</span>
                        <span class="text-h6 font-weight-bold">50%</span>
                    </div>
                </VCardText>
            </VCard>
        </VCol>
        <VCol cols="12" md="8">
             <VCard>
                <VCardItem title="Интеграция" />
                <VCardText>
                    <div class="d-flex align-center gap-4">
                        <VChip color="success" label>iikoCard подключена</VChip>
                        <span class="text-body-2 text-medium-emphasis">Синхронизация балансов происходит автоматически при каждом изменении статуса заказа.</span>
                    </div>
                </VCardText>
            </VCard>
        </VCol>
    </VRow>

    <VCard>
      <VCardItem title="Уровни и правила начисления" />
      <VDivider />

      <VDataTable
        :headers="headers"
        :items="rules"
        :loading="loading"
        hover
        density="comfortable"
      >
         <template #item.title="{ item }">
             <span class="font-weight-medium">{{ item.title }}</span>
         </template>

         <template #item.rule_type="{ item }">
             <VChip size="small" color="primary" variant="tonal">
                 Кэшбек
             </VChip>
         </template>
         
         <template #item.cashback_percent="{ item }">
              <span class="font-weight-bold">{{ item.cashback_percent }}%</span>
         </template>

        <template #item.is_active="{ item }">
            <VSwitch
                v-model="item.is_active"
                color="success"
                density="compact"
                hide-details
            />
        </template>

        <template #item.actions="{ item }">
             <VBtn icon="ri-edit-line" size="small" variant="text" color="primary" class="me-1" />
        </template>
      </VDataTable>
    </VCard>
  </div>
</template>
