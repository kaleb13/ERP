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
    /** Route target for the root icon link. Defaults to '/dashboard'. */
    homeTo?: string;
    /** Tooltip for the root icon link. */
    homeTitle?: string;
    /** Optional custom icon for the root link (defaults to Monitor). */
    homeIcon?: Component;
  }>(),
  {
    items: () => [],
    homeTo: '/home',
    homeTitle: 'Home',
    homeIcon: undefined
  }
);
</script>

<template>
  <nav aria-label="Breadcrumb" class="breadcrumb-nav">
    <!-- Root Home / Dashboard Icon Link -->
    <router-link :to="homeTo" class="breadcrumb-root-link" :title="homeTitle">
      <component :is="homeIcon || Monitor" :size="15" />
    </router-link>

    <!-- Intermediate & Final Crumb Items -->
    <template v-for="(item, index) in items" :key="index">
      <ChevronRight :size="12" class="breadcrumb-divider" />

      <!-- Clickable link for non-last items that have a 'to' property -->
      <router-link 
        v-if="item.to && index < items.length - 1" 
        :to="item.to" 
        class="breadcrumb-link"
        @click="item.onClick ? item.onClick() : undefined"
      >
        <component :is="item.icon" v-if="item.icon" :size="13" class="breadcrumb-item-icon" />
        <span>{{ item.label }}</span>
      </router-link>

      <!-- Active / Current Page for the last item or items without 'to' -->
      <span v-else class="breadcrumb-current">
        <component :is="item.icon" v-if="item.icon" :size="13" class="breadcrumb-item-icon" />
        <span>{{ item.label }}</span>
      </span>
    </template>

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
  gap: 8px;
  font-size: 13px;
  margin-bottom: 20px;
  user-select: none;
  font-family: inherit;
}

.breadcrumb-root-link {
  color: #64748b;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 4px;
  border-radius: 6px;
  transition: all 0.15s ease;
}

.breadcrumb-root-link:hover {
  color: #0f172a;
  background-color: #f1f5f9;
}

.breadcrumb-divider {
  color: #94a3b8;
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
}

.breadcrumb-link {
  color: #64748b;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 2px 4px;
  border-radius: 4px;
  font-weight: 450;
  transition: all 0.15s ease;
}

.breadcrumb-link:hover {
  color: #0f172a;
  background-color: #f1f5f9;
}

.breadcrumb-current {
  color: #0f172a;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  gap: 5px;
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
