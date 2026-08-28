<script setup lang="ts" generic="T extends string | number">
import type { Component } from 'vue';

defineProps<{
  /** Currently active tab id (use with v-model). */
  modelValue: T;
  /** Tabs array with optional count and icon. */
  tabs: { id: T; label: string; count?: number; icon?: Component }[];
}>();

defineEmits<{
  'update:modelValue': [value: T];
}>();
</script>

<template>
  <div class="underline-tabs">
    <button
      v-for="tab in tabs"
      :key="tab.id"
      type="button"
      :class="['underline-tab', { active: modelValue === tab.id }]"
      @click="$emit('update:modelValue', tab.id)"
    >
      <component :is="tab.icon" v-if="tab.icon" :size="15" class="tab-icon" />
      <span>{{ tab.label }}</span>
      <span v-if="tab.count !== undefined" class="tab-count-badge">{{ tab.count }}</span>
      <div v-if="modelValue === tab.id" class="active-indicator"></div>
    </button>
  </div>
</template>

<style scoped>
.underline-tabs {
  display: flex;
  align-items: center;
  gap: 8px;
  border-bottom: 1px solid #e2e8f0;
  width: 100%;
  overflow-x: auto;
}

.underline-tab {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  border: none;
  background: none;
  font-size: 13.5px;
  font-weight: 500;
  color: #64748b;
  cursor: pointer;
  white-space: nowrap;
  transition: color 0.15s ease;
}

.underline-tab:hover {
  color: #0f172a;
}

.underline-tab.active {
  color: #0B529C;
  font-weight: 600;
}

.active-indicator {
  position: absolute;
  bottom: -1px;
  left: 0;
  right: 0;
  height: 2.5px;
  background-color: #0B529C;
  border-radius: 2px 2px 0 0;
}

.tab-count-badge {
  font-size: 11px;
  font-weight: 600;
  padding: 2px 7px;
  border-radius: 10px;
  background: #f1f5f9;
  color: #475569;
}

.underline-tab.active .tab-count-badge {
  background: #eff6ff;
  color: #0B529C;
}
</style>
