<script setup lang="ts" generic="T extends string | number">
import type { Component } from 'vue';

withDefaults(
  defineProps<{
    /** Currently active tab id (use with v-model). */
    modelValue: T;
    /** Tabs to render. `icon` is an optional lucide component. */
    tabs: { id: T; label: string; icon?: Component }[];
    /** Visual size. `md` (default) suits icon tabs, `sm` is more compact. */
    size?: 'sm' | 'md';
  }>(),
  { size: 'md' }
);

defineEmits<{
  'update:modelValue': [value: T];
}>();
</script>

<template>
  <div class="base-tabs" :class="`base-tabs--${size}`">
    <button
      v-for="tab in tabs"
      :key="tab.id"
      type="button"
      :class="['base-tab', { active: modelValue === tab.id }]"
      @click="$emit('update:modelValue', tab.id)"
    >
      <component
        :is="tab.icon"
        v-if="tab.icon"
        :size="size === 'sm' ? 14 : 15"
        class="base-tab__icon"
      />
      <span>{{ tab.label }}</span>
    </button>
  </div>
</template>

<style scoped>
.base-tabs {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px;
  background: #f4f4f5;
  border: 1px solid #e4e4e7;
  border-radius: 30px;
}

.base-tab {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  border: none;
  background: none;
  font-weight: 600;
  color: #64748b;
  border-radius: 22px;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.2s ease;
}

.base-tab:hover {
  color: #0f172a;
}

.base-tab.active {
  background: #ffffff;
  color: #0f172a;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08), 0 1px 2px rgba(0, 0, 0, 0.04);
}

.base-tab__icon {
  color: currentColor;
  flex-shrink: 0;
}

/* Sizes */
.base-tabs--md .base-tab {
  padding: 8px 18px;
  font-size: 13px;
}

.base-tabs--sm .base-tab {
  padding: 6px 14px;
  font-size: 12px;
}
</style>
