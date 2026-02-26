<script setup>
import { ref, onMounted, computed } from "vue"

const loading = ref(false)
const saving = ref(false)
const syncing = ref(false)
const syncingPrices = ref(false)
const syncingStopList = ref(false)
const snackbar = ref(false)
const snackbarColor = ref("success")
const snackbarText = ref("")

const products = ref([])
const categories = ref([])
const branches = ref([])
const search = ref("")
const categoryFilter = ref(null)

// Диалог редактирования
const isDialogVisible = ref(false)
const currentTab = ref('main')
const editedItem = ref({})

const API_BASE = "/api/v1"

const headers = [
  { title: "ID", key: "id", sortable: true, width: 70 },
  { title: "Фото", key: "image_url", sortable: false, width: 70 },
  { title: "Название", key: "name", sortable: true },
  { title: "Цена", key: "price", sortable: true, width: 100 },
  { title: "Статус", key: "status_labels", sortable: false, width: 150 },
  { title: "iiko ID", key: "iiko_id", sortable: false, width: 100 },
  { title: "Доступен", key: "is_available", sortable: true, width: 100 },
  { title: "Действия", key: "actions", sortable: false, align: "end", width: 100 },
]

const showMessage = (text, color = "success") => {
  snackbarText.value = text
  snackbarColor.value = color
  snackbar.value = true
}

const loadData = async () => {
  loading.value = true
  try {
    const [prodRes, catRes, branchRes] = await Promise.all([
      fetch(`${API_BASE}/products/`),
      fetch(`${API_BASE}/categories/`),
      fetch(`${API_BASE}/branches/`)
    ])
    
    if (prodRes.ok) products.value = await prodRes.json()
    if (catRes.ok) categories.value = await catRes.json()
    if (branchRes.ok) branches.value = await branchRes.json()
  } catch (e) {
    showMessage("Ошибка загрузки данных", "error")
  } finally {
    loading.value = false
  }
}

const saveProduct = async () => {
  if (!editedItem.value.id) return
  saving.value = true
  try {
    const res = await fetch(`${API_BASE}/products/${editedItem.value.id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(editedItem.value)
    })
    
    if (res.ok) {
        showMessage("Товар успешно сохранен")
        isDialogVisible.value = false
        await loadData()
    } else {
        const errorData = await res.json()
        showMessage(`Ошибка при сохранении: ${errorData.detail || ''}`, "error")
    }
  } catch (e) {
      showMessage("Ошибка подключения к серверу", "error")
  } finally {
      saving.value = false
  }
}

const editItem = (item) => {
    editedItem.value = Object.assign({}, item)
    // Убедимся, что массив для филиалов инициализирован
    if (!editedItem.value.stop_list_branch_ids) {
        editedItem.value.stop_list_branch_ids = []
    }
    currentTab.value = 'main'
    isDialogVisible.value = true
}

// Заглушки синхронизации
const doSync = async (endpoint, successMsg) => {
  const stateRef = endpoint.includes('menu') ? syncing : (endpoint.includes('prices') ? syncingPrices : syncingStopList)
  stateRef.value = true
  try {
    const res = await fetch(`${API_BASE}/iiko/${endpoint}`, { method: "POST" })
    const data = await res.json()
    if (data.success) {
      showMessage(successMsg(data))
      await loadData()
    } else showMessage(data.message || "Ошибка API iiko", "error")
  } catch (e) { showMessage("Сетевая ошибка iiko", "error") } finally { stateRef.value = false }
}

const syncMenu = () => doSync('sync-menu', d => `Синхронизировано: ${d.products_synced} товаров`)
const syncPrices = () => doSync('sync-prices', d => `Обновлены цены для ${d.products_updated || 0} товаров`)
const syncStopList = () => doSync('sync-stop-lists', d => `В стопе: ${d.stopped_count || 0} товаров`)

const filteredProducts = computed(() => {
  let result = products.value
  if (categoryFilter.value) {
      result = result.filter(p => p.category_id === categoryFilter.value)
  }
  if (!search.value) return result
  
  const q = search.value.toLowerCase()
  return result.filter(
    p => p.name?.toLowerCase().includes(q) || p.article?.toLowerCase().includes(q) || p.iiko_id?.toLowerCase().includes(q)
  )
})

const formatPrice = price => {
  return new Intl.NumberFormat("ru-RU", { style: "currency", currency: "RUB", minimumFractionDigits: 0 }).format(price || 0)
}

onMounted(loadData)
</script>

<template>
  <VRow>
    <VCol cols="12">
      <VCard>
        <VCardTitle class="d-flex align-center flex-wrap gap-4 py-4">
          <h2 class="text-h4 mb-0">Каталог товаров</h2>
          <VSpacer />
          <div class="d-flex gap-4 align-center" style="width: 500px;">
             <VSelect
              v-model="categoryFilter"
              :items="categories"
              item-title="name"
              item-value="id"
              label="Категория"
              density="compact"
              hide-details
              clearable
              style="width: 200px"
            />
            <VTextField
              v-model="search"
              density="compact"
              placeholder="Поиск (название, арт)"
              prepend-inner-icon="mdi-magnify"
              hide-details
              clearable
              style="flex-grow: 1"
            />
          </div>
        </VCardTitle>
        <VDivider />
        <VCardText class="pt-4">
          <div class="d-flex gap-2 flex-wrap mb-4">
            <VBtn color="primary" :loading="syncing" prepend-icon="mdi-sync" @click="syncMenu">
              Синхронизировать iiko
            </VBtn>
            <VBtn color="secondary" variant="outlined" :loading="syncingPrices" prepend-icon="mdi-currency-rub" @click="syncPrices">
              Обновить цены
            </VBtn>
            <VBtn color="warning" variant="outlined" :loading="syncingStopList" prepend-icon="mdi-cancel" @click="syncStopList">
              Обновить стоп-листы
            </VBtn>
          </div>

          <VDataTable
            :headers="headers"
            :items="filteredProducts"
            :loading="loading"
            :items-per-page="25"
            hover
          >
            <!-- Фото -->
            <template #item.image_url="{ item }">
               <VAvatar rounded size="40" variant="tonal" color="primary">
                 <VImg v-if="item.image_url" :src="item.image_url" />
                 <VIcon v-else icon="mdi-food" />
               </VAvatar>
            </template>
            
            <!-- Название и описание -->
            <template #item.name="{ item }">
               <div class="d-flex flex-column py-2">
                  <span class="font-weight-medium">{{ item.name }}</span>
                  <span class="text-caption text-medium-emphasis" v-if="item.article">Арт: {{ item.article }}</span>
               </div>
            </template>

            <!-- Цены -->
            <template #item.price="{ item }">
              <div class="d-flex flex-column">
                  <span>{{ formatPrice(item.price) }}</span>
                  <span v-if="item.old_price" class="text-caption text-decoration-line-through text-error">
                      {{ formatPrice(item.old_price) }}
                  </span>
              </div>
            </template>
            
            <!-- Лейблы и статусы -->
            <template #item.status_labels="{ item }">
                <div class="d-flex gap-1 flex-wrap py-2">
                   <VChip v-if="item.is_popular" color="warning" size="x-small" label>ХИТ</VChip>
                   <VChip v-if="item.stop_list_branch_ids && item.stop_list_branch_ids.length > 0" color="error" size="x-small" label>В СТОПЕ</VChip>
                </div>
            </template>

            <!-- Доступность -->
            <template #item.is_available="{ item }">
              <VChip :color="item.is_available ? 'success' : 'error'" variant="tonal" size="small">
                {{ item.is_available ? "Да" : "Скрыт" }}
              </VChip>
            </template>

            <!-- iiko ID -->
            <template #item.iiko_id="{ item }">
              <span v-if="item.iiko_id" class="text-caption text-medium-emphasis" title="Скопировать ID">
                {{ item.iiko_id.substring(0, 8) }}...
              </span>
              <span v-else class="text-caption">Нет</span>
            </template>

            <!-- Действия -->
            <template #item.actions="{ item }">
                <VBtn icon="mdi-pencil" size="small" variant="text" color="primary" @click="editItem(item)" />
            </template>
          </VDataTable>
        </VCardText>
      </VCard>
    </VCol>
  </VRow>

  <!-- Диалог редактирования товара -->
  <VDialog v-model="isDialogVisible" max-width="900" persistent scrollable>
    <VCard>
      <VCardTitle class="bg-primary text-white d-flex align-center py-3">
        <span>Настройки: {{ editedItem.name }}</span>
        <VSpacer />
        <VBtn icon="mdi-close" variant="text" color="white" @click="isDialogVisible = false" />
      </VCardTitle>

      <VTabs v-model="currentTab" bg-color="transparent" class="px-4 pt-2">
        <VTab value="main">Основное</VTab>
        <VTab value="characteristics">КБЖУ и Вес</VTab>
        <VTab value="modifiers">Размеры и Опции</VTab>
        <VTab value="marketing">Маркетинг и Стопы</VTab>
      </VTabs>
      <VDivider />

      <VCardText class="pt-6" style="height: 60vh;">
        <VWindow v-model="currentTab">
          <!-- Вкладка Основное -->
          <VWindowItem value="main">
            <VRow>
               <VCol cols="12" md="8">
                 <VTextField v-model="editedItem.name" label="Название товара" class="mb-4" />
                 <VSelect
                     v-model="editedItem.category_id"
                     :items="categories"
                     item-title="name"
                     item-value="id"
                     label="Категория"
                     class="mb-4"
                 />
                 <VTextarea v-model="editedItem.description" label="Описание" rows="3" class="mb-4" />
                 <VRow>
                    <VCol cols="6"><VTextField v-model.number="editedItem.price" label="Цена (₽)" type="number" /></VCol>
                    <VCol cols="6"><VTextField v-model.number="editedItem.old_price" label="Старая цена (₽)" type="number" hint="Больше текущей для 'зачеркнутой' скидки" /></VCol>
                 </VRow>
               </VCol>
               <VCol cols="12" md="4">
                   <div class="d-flex flex-column gap-4">
                       <VCard variant="outlined" class="pa-4 text-center">
                           <VImg v-if="editedItem.image_url" :src="editedItem.image_url" height="150" class="mb-2" />
                           <VIcon v-else icon="mdi-image-outline" size="64" color="grey" class="mb-2" />
                           <VTextField v-model="editedItem.image_url" label="URL Изображения" placeholder="https://" density="compact" hide-details />
                       </VCard>
                       <VSwitch v-model="editedItem.is_available" color="success" label="Показывать в каталоге" hide-details />
                       <VSwitch v-model="editedItem.is_popular" color="warning" label="Отметка ХИТ / TOP" hide-details />
                       <VTextField v-model="editedItem.article" label="Артикул" />
                   </div>
               </VCol>
            </VRow>
          </VWindowItem>

          <!-- Вкладка КБЖУ и Вес -->
          <VWindowItem value="characteristics">
            <VRow>
              <VCol cols="6" md="3"><VTextField v-model.number="editedItem.weight_grams" label="Вес (граммы)" type="number" prepend-inner-icon="mdi-weight" /></VCol>
              <VCol cols="6" md="3"><VTextField v-model.number="editedItem.volume_ml" label="Объем (мл)" type="number" prepend-inner-icon="mdi-cup-water" /></VCol>
              <VCol cols="6" md="3"><VTextField v-model.number="editedItem.calories" label="Калории (ккал)" type="number" prepend-inner-icon="mdi-fire" /></VCol>
            </VRow>
            <VRow>
              <VCol cols="4"><VTextField v-model.number="editedItem.proteins" label="Белки (г)" type="number" /></VCol>
              <VCol cols="4"><VTextField v-model.number="editedItem.fats" label="Жиры (г)" type="number" /></VCol>
              <VCol cols="4"><VTextField v-model.number="editedItem.carbohydrates" label="Углеводы (г)" type="number" /></VCol>
            </VRow>
            <VAlert type="info" variant="tonal" class="mt-4" icon="mdi-information">
                Характеристики отображаются на детальной карточке продукта на сайте и в боте доставки. Они повышают доверие пользователей.
            </VAlert>
          </VWindowItem>

          <!-- Вкладка Модификаторы -->
          <VWindowItem value="modifiers">
              <VAlert type="warning" variant="tonal" class="mb-4" icon="mdi-sync">
                 Управление размерами и модификаторами для данного товара осуществляется через систему iiko. Все изменения (состав пиццы, добавки, топпинги) автоматически импортируются при синхронизации меню.
              </VAlert>
              
              <template v-if="editedItem.sizes && editedItem.sizes.length > 0">
                 <h4 class="text-h6 mb-2">Размеры товара:</h4>
                 <div class="d-flex gap-2 flex-wrap mb-6">
                    <VChip v-for="s in editedItem.sizes" :key="s.id" color="primary" variant="outlined">
                        {{ s.name }} — {{ formatPrice(s.price) }}
                    </VChip>
                 </div>
              </template>

              <template v-if="editedItem.modifier_groups && editedItem.modifier_groups.length > 0">
                 <h4 class="text-h6 mb-2">Группы модификаторов:</h4>
                 <VExpansionPanels>
                     <VExpansionPanel v-for="g in editedItem.modifier_groups" :key="g.id">
                         <VExpansionPanelTitle class="font-weight-bold">
                             {{ g.name }} (Мин: {{ g.min_amount }}, Макс: {{ g.max_amount }})
                         </VExpansionPanelTitle>
                         <VExpansionPanelText>
                             <ul class="ms-4 my-2">
                                 <li v-for="m in g.modifiers" :key="m.id" class="text-body-2">
                                     {{ m.name }} — +{{ formatPrice(m.price) }}
                                 </li>
                             </ul>
                         </VExpansionPanelText>
                     </VExpansionPanel>
                 </VExpansionPanels>
              </template>
              <div v-else class="text-center py-8 text-medium-emphasis">
                  К данному товару не привязано ни одной группы модификаторов.
              </div>
          </VWindowItem>

          <!-- Вкладка Маркетинг -->
          <VWindowItem value="marketing">
             <VRow>
                <VCol cols="12" md="6">
                    <VTextField 
                       v-model.number="editedItem.max_discount_percent" 
                       label="Максимальная скидка (%)" 
                       type="number" max="100" min="0" 
                       hint="Если установить 0, промокоды для товара работать не будут" persistent-hint
                    />
                </VCol>
                <VCol cols="12" md="6">
                    <VTextField 
                       v-model.number="editedItem.bonus_accrual_percent" 
                       label="Персональный кэшбек (%)" 
                       type="number" max="100" min="0" 
                       hint="Процент программы лояльности именно для этого товара" persistent-hint
                    />
                </VCol>
             </VRow>
             <VDivider class="my-6" />
             <VRow>
                <VCol cols="12">
                   <h4 class="text-h6 mb-2 text-error d-flex align-center">
                       <VIcon icon="mdi-cancel" class="me-2" />
                       Ручное управление Стоп-листами
                   </h4>
                   <p class="text-body-2 text-medium-emphasis mb-4">
                       Выберите филиалы, в которых товар недоступен для заказа. Это имеет приоритет над статусом в iiko. Позволяет оперативно отключить продажи позиции на конкретной точке.
                   </p>
                   
                   <VSelect
                      v-model="editedItem.stop_list_branch_ids"
                      :items="branches"
                      item-title="name"
                      item-value="id"
                      label="Отключить в филиалах (Стоп-лист)"
                      multiple
                      chips
                      clearable
                      variant="outlined"
                   ></VSelect>
                </VCol>
             </VRow>
          </VWindowItem>
        </VWindow>
      </VCardText>

      <VDivider />
      <VCardActions class="pa-4 bg-grey-lighten-4">
        <VSpacer />
        <VBtn variant="outlined" color="secondary" @click="isDialogVisible = false" class="me-2">Отмена</VBtn>
        <VBtn variant="elevated" color="primary" @click="saveProduct" :loading="saving" prepend-icon="mdi-content-save">Сохранить</VBtn>
      </VCardActions>
    </VCard>
  </VDialog>

  <VSnackbar v-model="snackbar" :color="snackbarColor" :timeout="4000" location="top">
    {{ snackbarText }}
  </VSnackbar>
</template>
