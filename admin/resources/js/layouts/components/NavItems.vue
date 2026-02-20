<script setup>
import VerticalNavSectionTitle from "@/@layouts/components/VerticalNavSectionTitle.vue"
import VerticalNavGroup from "@layouts/components/VerticalNavGroup.vue"
import VerticalNavLink from "@layouts/components/VerticalNavLink.vue"
</script>

<template>
  <!-- 👉 Проект -->
  <VerticalNavSectionTitle
    :item="{
      heading: 'Проект Foodtech',
    }"
  />

  <VerticalNavLink
    :item="{
      title: 'Заказы',
      icon: 'bx-receipt',
      to: '/orders',
    }"
  />

  <VerticalNavGroup
    :item="{
      title: 'Меню',
      icon: 'bx-food-menu',
    }"
  >
    <VerticalNavLink
      :item="{
        title: 'Товары',
        to: '/menu/products',
      }"
    />
    <VerticalNavLink
      :item="{
        title: 'Категории',
        to: '/menu/categories',
      }"
    />
  </VerticalNavGroup>

  <VerticalNavGroup
    :item="{
      title: 'Маркетинг',
      icon: 'bx-badge-check',
    }"
  >
    <VerticalNavLink
      :item="{
        title: 'Промокоды',
        to: '/promo',
        icon: 'bx-purchase-tag',
      }"
    />
    <VerticalNavLink
      :item="{
        title: 'Лояльность',
        to: '/loyalty',
        icon: 'bx-star',
      }"
    />
  </VerticalNavGroup>

  <VerticalNavGroup
    :item="{
      title: 'Настройки iiko',
      icon: 'bx-cog',
    }"
  >
    <VerticalNavLink
      :item="{
        title: 'Параметры iiko',
        to: '/settings/iiko',
      }"
    />
    <VerticalNavLink
      :item="{
        title: 'Логи синхронизации',
        to: '/settings/sync-logs',
      }"
    />
  </VerticalNavGroup>

  <!-- 👉 Администрирование -->
  <VerticalNavSectionTitle
    :item="{
      heading: 'Администрирование',
    }"
  />

  <VerticalNavLink
    :item="{
      title: 'Пользователи',
      icon: 'bx-user',
      to: '/users',
    }"
  />

  <!-- 👉 Дашборд -->
  <VerticalNavLink
    :item="{
      title: 'Дашборд (Аналитика)',
      icon: 'bx-home-smile',
      to: '/dashboard',
    }"
  />

  <!-- 👉 Настройки интерфейса (Оставляем для примера) -->
  <VerticalNavSectionTitle
    :item="{
      heading: 'Интерфейс',
    }"
  />

  <VerticalNavLink
    :item="{
      title: 'Иконки',
      icon: 'bx-package',
      to: '/icons',
    }"
  />

  <VerticalNavLink
    :item="{
      title: 'Карточки',
      icon: 'bx-credit-card',
      to: '/cards',
    }"
  />

  <VerticalNavLink
    :item="{
      title: 'Типографика',
      icon: 'bx-text',
      to: '/typography',
    }"
  />

  <VerticalNavLink
    :item="{
      title: 'Настройки аккаунта',
      icon: 'bx-user-circle',
      to: '/account-settings',
    }"
  />
</template>
