<!--
  Authoritative QMT AppBreadcrumb Component (Figma 6095:94972 & 5577:151)
  =======================================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Mandatory on EVERY page, view, and form across Haleta ERP.
  - Sits directly on the transparent canvas background (ZERO white card wrapper, ZERO border).
  - Directory listing pages: `[{ label: 'Exact Page Name' }]` (only exact page name, never module prefix).
  - Detail/create pages: `[{ label: 'Parent Page', onClick: ... }, { label: 'New / Item Name' }]`.
  - Supports optional `#badge` slot directly adjacent to active item for `<SaveStateBadge />`.

  STRICT INVARIANTS:
  - Zero Card Background: Breadcrumb and top bar MUST NEVER be wrapped in a white card container.
  - Zero Back Buttons: Breadcrumbs are the SOLE navigation mechanism to traverse up the hierarchy.
    Never place a back button (`btn-back`, `← Back to...`) anywhere in the application.
-->
<script setup lang="ts">
import type { Component } from 'vue';
import { Monitor, ChevronRight } from 'lucide-vue-next';

export interface BreadcrumbItem {
  label: string;
  to?: string | object;
  icon?: Component;
  onClick?: () => void;
}

withDefaults(
  defineProps<{
    /** List of breadcrumb trail items. The last item is treated as the current page. */
    items?: BreadcrumbItem[];
    /** Route target for the root icon link. Defaults to ERP portal Home ('/'). */
    homeTo?: string;
    /** Tooltip for the root icon link. */
    homeTitle?: string;
    /** Optional custom icon for the root link (defaults to Monitor per QMT Node 6095:94974). */
    homeIcon?: Component;
    /** Suppress bottom margin (useful when placed inside action bars / top headers). */
    noMargin?: boolean;
  }>(),
  {
    items: () => [],
    homeTo: '/',
    homeTitle: 'Home',
    homeIcon: undefined,
    noMargin: false
  }
);
</script>

<template>
  <nav aria-label="Breadcrumb" class="breadcrumb-nav" :class="{ 'no-margin': noMargin }">
    <!-- Root ERP System Icon Link (Monitor per QMT Node 6095:94974) -->
    <router-link :to="homeTo" class="breadcrumb-root-link" :title="homeTitle">
      <component :is="homeIcon || Monitor" :size="16" />
    </router-link>

    <!-- Intermediate & Final Crumb Items -->
    <template v-for="(item, index) in items" :key="index">
      <ChevronRight :size="16" class="breadcrumb-divider" />

      <!-- Clickable link for non-last items that have a 'to' property -->
      <router-link 
        v-if="item.to && index < items.length - 1" 
        :to="item.to" 
        class="breadcrumb-link"
        @click="item.onClick ? item.onClick() : undefined"
      >
        <component :is="item.icon" v-if="item.icon" :size="16" class="breadcrumb-item-icon" />
        <span>{{ item.label }}</span>
      </router-link>

      <!-- Active / Current Page for the last item or items without 'to' -->
      <span v-else class="breadcrumb-current" aria-current="page">
        <component :is="item.icon" v-if="item.icon" :size="16" class="breadcrumb-item-icon" />
        <span>{{ item.label }}</span>
      </span>
    </template>

    <!-- Inline slot immediately following current page title (e.g. SaveStateBadge) -->
    <slot name="badge" />
    <slot />

    <!-- Optional Right-aligned Breadcrumb Extra Slot -->
    <div v-if="$slots.extra" class="breadcrumb-extra">
      <slot name="extra" />
    </div>
  </nav>
</template>

<style scoped>
.breadcrumb-nav {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  line-height: 20px;
  margin-top: 0;
  margin-bottom: 0;
  user-select: none;
  font-family: inherit;
}

.breadcrumb-nav.no-margin {
  margin-bottom: 0 !important;
}

.breadcrumb-nav :deep(.save-state-badge) {
  margin-left: 2px;
  align-self: center;
}

.breadcrumb-root-link {
  color: var(--alias-color-icon-tertiary, #737373);
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 2px;
  border-radius: var(--alias-radius-md, 6px);
  transition: all 0.15s ease;
}

.breadcrumb-root-link:hover {
  color: var(--primitive-color-brand-blue-700, #0B529C);
  background-color: var(--primitive-color-brand-blue-50, #f1f7fe);
}

.breadcrumb-divider {
  color: var(--alias-color-icon-tertiary, #737373);
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
}

.breadcrumb-link {
  color: var(--alias-color-text-tertiary, #737373);
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 4px;
  border-radius: var(--alias-radius-sm, 4px);
  font-weight: 400;
  font-size: 14px;
  line-height: 20px;
  transition: all 0.15s ease;
}

.breadcrumb-link:hover {
  color: var(--primitive-color-brand-blue-700, #0B529C);
  background-color: var(--primitive-color-brand-blue-50, #f1f7fe);
}

.breadcrumb-current {
  color: var(--alias-color-text-secondary, #404040);
  font-weight: 500;
  font-size: 14px;
  line-height: 20px;
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.breadcrumb-item-icon {
  color: currentColor;
  flex-shrink: 0;
}

.breadcrumb-extra {
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 8px;
}
</style>
