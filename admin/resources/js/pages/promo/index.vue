<script setup>
import { ref, onMounted, computed } from "vue"

const loading = ref(false)
const promoCodes = ref([])
const search = ref("")
const typeFilter = ref(null)
const activeFilter = ref(null)

// Диалоги
const promoDialog = ref(false)
const massDialog = ref(false)
const editingPromo = ref(null)

const promoForm = ref(resetPromoForm())

function resetPromoForm() {
  return {
    name: "",
    code: "",
    description: "",
    is_active: true,
    promo_type: "percent",
    discount_value: 0,
    gift_product_ids: [], // Array
    usage_type: "multi",
    max_uses: null,
    no_combine: false,
    first_order_only: false,
    min_order_amount: null,
    min_items_count: null,
    required_product_ids: [], // Array
    valid_from: null,
    valid_until: null,
    time_from: null,
    time_until: null,
    valid_days: [], // Array
    platforms: [], // Array
    delivery_types: [], // Array
    branch_ids: [], // Array
  }
}

const massForm = ref({
  prefix: "",
  count: 10,
  code_length: 8,
  name: "",
  description: "",
  promo_type: "percent",
  discount_value: 0,
  usage_type: "single",
  valid_from: null,
  valid_until: null,
})

// Справочники
const products = ref([])
const organizations = ref([])

const weekDays = [
  { title: "Понедельник", value: 1 },
  { title: "Вторник", value: 2 },
  { title: "Среда", value: 3 },
  { title: "Четверг", value: 4 },
  { title: "Пятница", value: 5 },
  { title: "Суббота", value: 6 },
  { title: "Воскресенье", value: 7 },
]

const platformOptions = [
  { title: "Сайт", value: "web" },
  { title: "Telegram", value: "telegram" },
  { title: "Мобильное приложение", value: "app" },
]

const deliveryTypeOptions = [
  { title: "Доставка", value: "delivery" },
  { title: "Самовывоз", value: "pickup" },
]

const headers = [
  { title: "ID", key: "id", width: 60 },
  { title: "Название", key: "name" },
  { title: "Код", key: "code", width: 140 },
  { title: "Тип", key: "promo_type", width: 120 },
  { title: "Значение", key: "discount_value", width: 100 },
  { title: "Использований", key: "usage_info", width: 140 },
  { title: "Активен", key: "is_active", width: 90 },
  { title: "Период", key: "period", width: 140 },
  { title: "Действия", key: "actions", width: 160, sortable: false },
]

const promoTypes = [
  { title: "Скидка %", value: "percent" },
  { title: "Скидка ₽", value: "fixed" },
  { title: "Подарки", value: "gift" },
  { title: "Бесплатные товары", value: "free_items" },
  { title: "Воронки", value: "funnel" },
]

const usageTypes = [
  { title: "Многоразовый", value: "multi" },
  { title: "Одноразовый", value: "single" },
  { title: "Раз для клиента", value: "single_per_user" },
]

const snackbar = ref(false)
const snackbarText = ref("")
const snackbarColor = ref("success")

const showMsg = (text, color = "success") => {
  snackbarText.value = text
  snackbarColor.value = color
  snackbar.value = true
}

const API = "/api/v1/promo-codes"

const loadPromos = async () => {
  loading.value = true
  try {
    let url = `${API}/?limit=200`
    if (typeFilter.value) url += `&promo_type=${typeFilter.value}`
    if (activeFilter.value !== null) url += `&is_active=${activeFilter.value}`
    if (search.value) url += `&search=${encodeURIComponent(search.value)}`
    const res = await fetch(url)
    if (res.ok) promoCodes.value = await res.json()
  } finally {
    loading.value = false
  }
}

const loadProducts = async () => {
  try {
    const res = await fetch("/api/v1/products/?limit=1000") // Загружаем все для селекта
    if (res.ok) products.value = await res.json()
  } catch (e) {}
}

const loadOrganizations = async () => {
  try {
    const res = await fetch("/api/v1/iiko/organizations")
    if (res.ok) {
      const data = await res.json()

      organizations.value = data.map(o => ({
        title: o.name || o.id,
        value: o.id,
      }))
    }
  } catch (e) {}
}

const parseJsonField = val => {
  if (!val) return []
  try {
    return typeof val === "string" ? JSON.parse(val) : val
  } catch (e) {
    return []
  }
}

const openPromoDialog = async (item = null) => {
  if (products.value.length === 0) await loadProducts()
  if (organizations.value.length === 0) await loadOrganizations()

  editingPromo.value = item
  if (item) {
    promoForm.value = {
      ...item,
      gift_product_ids: parseJsonField(item.gift_product_ids),
      required_product_ids: parseJsonField(item.required_product_ids),
      valid_days: parseJsonField(item.valid_days),
      platforms: parseJsonField(item.platforms),
      delivery_types: parseJsonField(item.delivery_types),
      branch_ids: parseJsonField(item.branch_ids),
    }
  } else {
    promoForm.value = resetPromoForm()
  }
  promoDialog.value = true
}

const savePromo = async () => {
  const method = editingPromo.value ? "PUT" : "POST"

  const url = editingPromo.value
    ? `${API}/${editingPromo.value.id}`
    : API + "/"

  const payload = {
    ...promoForm.value,
    gift_product_ids: JSON.stringify(promoForm.value.gift_product_ids),
    required_product_ids: JSON.stringify(promoForm.value.required_product_ids),
    valid_days: JSON.stringify(promoForm.value.valid_days),
    platforms: JSON.stringify(promoForm.value.platforms),
    delivery_types: JSON.stringify(promoForm.value.delivery_types),
    branch_ids: JSON.stringify(promoForm.value.branch_ids),
  }

  const res = await fetch(url, {
    method,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  })

  if (res.ok) {
    showMsg(editingPromo.value ? "Промокод обновлён" : "Промокод создан")
    promoDialog.value = false
    await loadPromos()
  } else {
    const err = await res.json()

    showMsg(err.detail || "Ошибка сохранения", "error")
  }
}

const deletePromo = async id => {
  if (!confirm("Удалить промокод?")) return
  await fetch(`${API}/${id}`, { method: "DELETE" })
  showMsg("Промокод удалён")
  await loadPromos()
}

const togglePromo = async id => {
  const res = await fetch(`${API}/${id}/toggle`, { method: "POST" })
  if (res.ok) {
    const data = await res.json()

    showMsg(data.is_active ? "Промокод активирован" : "Промокод деактивирован")
    await loadPromos()
  }
}

const duplicatePromo = async id => {
  const res = await fetch(`${API}/${id}/duplicate`, { method: "POST" })
  if (res.ok) {
    showMsg("Промокод скопирован")
    await loadPromos()
  }
}

const massGenerate = async () => {
  const res = await fetch(`${API}/mass-generate`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(massForm.value),
  })

  if (res.ok) {
    const data = await res.json()

    showMsg(`Сгенерировано ${data.length} промокодов`)
    massDialog.value = false
    await loadPromos()
  } else {
    const err = await res.json()

    showMsg(err.detail || "Ошибка генерации", "error")
  }
}

const typeLabel = type => {
  const map = {
    percent: "Скидка %",
    fixed: "Скидка ₽",
    gift: "Подарки",
    free_items: "Бесп. товары",
    funnel: "Воронка",
  }

  
  return map[type] || type
}

const typeColor = type => {
  const map = {
    percent: "primary",
    fixed: "info",
    gift: "success",
    free_items: "warning",
    funnel: "secondary",
  }

  
  return map[type] || "grey"
}

const formatDate = d => (d ? new Date(d).toLocaleDateString("ru-RU") : "—")

onMounted(loadPromos)
</script>

<template>
  <VRow>
    <VCol cols="12">
      <VCard>
        <VCardTitle class="d-flex align-center flex-wrap gap-4">
          <VIcon
            icon="mdi-ticket-percent"
            class="me-2"
          />
          Промокоды
          <VSpacer />
          <VChip
            color="primary"
            variant="tonal"
          >
            {{ promoCodes.length }} шт
          </VChip>
        </VCardTitle>
        <VCardText>
          <!-- Фильтры и действия -->
          <VRow class="mb-4">
            <VCol
              cols="12"
              md="3"
            >
              <VTextField
                v-model="search"
                placeholder="Поиск по коду/названию..."
                prepend-inner-icon="mdi-magnify"
                density="compact"
                hide-details
                clearable
                @keyup.enter="loadPromos"
                @click:clear="loadPromos"
              />
            </VCol>
            <VCol
              cols="6"
              md="2"
            >
              <VSelect
                v-model="typeFilter"
                :items="[{ title: 'Все типы', value: null }, ...promoTypes]"
                density="compact"
                hide-details
                @update:model-value="loadPromos"
              />
            </VCol>
            <VCol
              cols="6"
              md="2"
            >
              <VSelect
                v-model="activeFilter"
                :items="[
                  { title: 'Все', value: null },
                  { title: 'Активные', value: true },
                  { title: 'Неактивные', value: false },
                ]"
                density="compact"
                hide-details
                @update:model-value="loadPromos"
              />
            </VCol>
            <VCol
              cols="auto"
              class="d-flex gap-2"
            >
              <VBtn
                color="primary"
                prepend-icon="mdi-plus"
                @click="openPromoDialog"
              >
                Создать
              </VBtn>
              <VBtn
                color="secondary"
                variant="outlined"
                prepend-icon="mdi-cogs"
                @click="massDialog = true"
              >
                Массовая генерация
              </VBtn>
            </VCol>
          </VRow>

          <!-- Таблица -->
          <VDataTable
            :headers="headers"
            :items="promoCodes"
            :loading="loading"
            density="compact"
            class="elevation-1"
            :items-per-page="25"
          >
            <template #item.code="{ item }">
              <code class="text-primary">{{ item.code }}</code>
            </template>
            <template #item.promo_type="{ item }">
              <VChip
                :color="typeColor(item.promo_type)"
                size="small"
                variant="tonal"
              >
                {{ typeLabel(item.promo_type) }}
              </VChip>
            </template>
            <template #item.discount_value="{ item }">
              <span v-if="item.promo_type === 'percent'">{{ item.discount_value }}%</span>
              <span v-else-if="item.promo_type === 'fixed'">{{ item.discount_value }} ₽</span>
              <span v-else>—</span>
            </template>
            <template #item.usage_info="{ item }">
              {{ item.current_uses }} / {{ item.max_uses || "∞" }}
            </template>
            <template #item.is_active="{ item }">
              <VChip
                :color="item.is_active ? 'success' : 'grey'"
                size="small"
                variant="tonal"
              >
                {{ item.is_active ? "Да" : "Нет" }}
              </VChip>
            </template>
            <template #item.period="{ item }">
              <span class="text-caption">
                {{ formatDate(item.valid_from) }} —
                {{ formatDate(item.valid_until) }}
              </span>
            </template>
            <template #item.actions="{ item }">
              <VBtn
                icon="mdi-pencil"
                size="small"
                variant="text"
                @click="openPromoDialog(item)"
              />
              <VBtn
                :icon="item.is_active ? 'mdi-eye-off' : 'mdi-eye'"
                size="small"
                variant="text"
                :color="item.is_active ? 'warning' : 'success'"
                @click="togglePromo(item.id)"
              />
              <VBtn
                icon="mdi-content-copy"
                size="small"
                variant="text"
                @click="duplicatePromo(item.id)"
              />
              <VBtn
                icon="mdi-delete"
                size="small"
                variant="text"
                color="error"
                @click="deletePromo(item.id)"
              />
            </template>
          </VDataTable>
        </VCardText>
      </VCard>
    </VCol>
  </VRow>

  <!-- ==================== Диалог создания/редактирования ==================== -->
  <VDialog
    v-model="promoDialog"
    max-width="700"
    scrollable
  >
    <VCard :title="editingPromo ? 'Редактировать промокод' : 'Новый промокод'">
      <VCardText style="max-height: 70vh">
        <VRow>
          <VCol
            cols="12"
            md="6"
          >
            <VTextField
              v-model="promoForm.name"
              label="Название"
            />
          </VCol>
          <VCol
            cols="12"
            md="6"
          >
            <VTextField
              v-model="promoForm.code"
              label="Код"
              :disabled="!!editingPromo"
            />
          </VCol>
          <VCol cols="12">
            <VTextarea
              v-model="promoForm.description"
              label="Описание"
              rows="2"
            />
          </VCol>

          <!-- Тип и значение -->
          <VCol
            cols="12"
            md="6"
          >
            <VSelect
              v-model="promoForm.promo_type"
              :items="promoTypes"
              label="Тип промокода"
            />
          </VCol>
          <VCol
            cols="12"
            md="6"
          >
            <VTextField
              v-model.number="promoForm.discount_value"
              label="Значение"
              type="number"
            />
          </VCol>
          <VCol
            v-if="['gift', 'free_items'].includes(promoForm.promo_type)"
            cols="12"
          >
            <VAutocomplete
              v-model="promoForm.gift_product_ids"
              :items="products"
              item-title="name"
              item-value="id"
              label="Подарочные товары"
              multiple
              chips
              closable-chips
            />
          </VCol>

          <!-- Условия -->
          <VCol cols="12">
            <VDivider />
            <p class="text-subtitle-2 mt-2">
              Условия использования
            </p>
          </VCol>
          <VCol
            cols="12"
            md="4"
          >
            <VSelect
              v-model="promoForm.usage_type"
              :items="usageTypes"
              label="Тип использования"
            />
          </VCol>
          <VCol
            cols="12"
            md="4"
          >
            <VTextField
              v-model.number="promoForm.max_uses"
              label="Макс. использований"
              type="number"
              clearable
            />
          </VCol>
          <VCol
            cols="12"
            md="4"
          >
            <VTextField
              v-model.number="promoForm.min_order_amount"
              label="Мин. сумма заказа"
              type="number"
              clearable
            />
          </VCol>
          <VCol
            cols="12"
            md="4"
          >
            <VTextField
              v-model.number="promoForm.min_items_count"
              label="Мин. кол-во товаров"
              type="number"
              clearable
            />
          </VCol>
          <VCol cols="12">
            <VAutocomplete
              v-model="promoForm.required_product_ids"
              :items="products"
              item-title="name"
              item-value="id"
              label="Обязательные товары в корзине"
              multiple
              chips
              closable-chips
            />
          </VCol>

          <VCol
            cols="12"
            md="6"
          >
            <VSwitch
              v-model="promoForm.no_combine"
              label="Не суммировать с другими"
              color="primary"
            />
          </VCol>
          <VCol
            cols="12"
            md="6"
          >
            <VSwitch
              v-model="promoForm.first_order_only"
              label="Только первый заказ"
              color="primary"
            />
          </VCol>

          <!-- Период -->
          <VCol cols="12">
            <VDivider />
            <p class="text-subtitle-2 mt-2">
              Период действия
            </p>
          </VCol>
          <VCol
            cols="12"
            md="6"
          >
            <VTextField
              v-model="promoForm.valid_from"
              label="Действует с"
              type="date"
            />
          </VCol>
          <VCol
            cols="12"
            md="6"
          >
            <VTextField
              v-model="promoForm.valid_until"
              label="Действует до"
              type="date"
            />
          </VCol>
          <VCol
            cols="12"
            md="6"
          >
            <VTextField
              v-model="promoForm.time_from"
              label="Время с (HH:MM)"
              placeholder="09:00"
            />
          </VCol>
          <VCol
            cols="12"
            md="6"
          >
            <VTextField
              v-model="promoForm.time_until"
              label="Время до (HH:MM)"
              placeholder="22:00"
            />
          </VCol>

          <VCol cols="12">
            <VSelect
              v-model="promoForm.valid_days"
              :items="weekDays"
              label="Дни недели"
              multiple
              chips
              closable-chips
              clearable
            />
          </VCol>

          <VCol cols="12">
            <VDivider />
            <p class="text-subtitle-2 mt-2">
              Ограничения
            </p>
          </VCol>
          <VCol
            cols="12"
            md="6"
          >
            <VSelect
              v-model="promoForm.platforms"
              :items="platformOptions"
              label="Платформы"
              multiple
              chips
              closable-chips
            />
          </VCol>
          <VCol
            cols="12"
            md="6"
          >
            <VSelect
              v-model="promoForm.delivery_types"
              :items="deliveryTypeOptions"
              label="Тип получения"
              multiple
              chips
              closable-chips
            />
          </VCol>
          <VCol cols="12">
            <VAutocomplete
              v-model="promoForm.branch_ids"
              :items="organizations"
              label="Филиалы (Организации)"
              multiple
              chips
              closable-chips
            />
          </VCol>

          <VCol cols="12">
            <VSwitch
              v-model="promoForm.is_active"
              label="Активен"
              color="primary"
            />
          </VCol>
        </VRow>
      </VCardText>
      <VCardActions>
        <VSpacer />
        <VBtn
          variant="text"
          @click="promoDialog = false"
        >
          Отмена
        </VBtn>
        <VBtn
          color="primary"
          @click="savePromo"
        >
          Сохранить
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>

  <!-- ==================== Массовая генерация ==================== -->
  <VDialog
    v-model="massDialog"
    max-width="500"
  >
    <VCard title="Массовая генерация промокодов">
      <VCardText>
        <VTextField
          v-model="massForm.prefix"
          label="Префикс кода"
          placeholder="SALE"
          class="mb-3"
        />
        <VTextField
          v-model.number="massForm.count"
          label="Количество"
          type="number"
          class="mb-3"
        />
        <VTextField
          v-model.number="massForm.code_length"
          label="Длина кода (без префикса)"
          type="number"
          class="mb-3"
        />
        <VTextField
          v-model="massForm.name"
          label="Название (шаблон)"
          class="mb-3"
        />
        <VSelect
          v-model="massForm.promo_type"
          :items="promoTypes"
          label="Тип"
          class="mb-3"
        />
        <VTextField
          v-model.number="massForm.discount_value"
          label="Значение скидки"
          type="number"
          class="mb-3"
        />
        <VTextField
          v-model="massForm.valid_from"
          label="Действует с"
          type="date"
          class="mb-3"
        />
        <VTextField
          v-model="massForm.valid_until"
          label="Действует до"
          type="date"
          class="mb-3"
        />
      </VCardText>
      <VCardActions>
        <VSpacer />
        <VBtn
          variant="text"
          @click="massDialog = false"
        >
          Отмена
        </VBtn>
        <VBtn
          color="primary"
          @click="massGenerate"
        >
          Сгенерировать
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>

  <VSnackbar
    v-model="snackbar"
    :color="snackbarColor"
    :timeout="3000"
    location="top"
  >
    {{ snackbarText }}
  </VSnackbar>
</template>
