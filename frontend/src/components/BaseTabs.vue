<script setup lang="ts" generic="T extends string | number">
import type { Component } from 'vue';

export interface BaseTabItem<IdType = T> {
  id: IdType;
  label: string;
  icon?: Component;
  count?: number | string;
  badge?: string;
  badgeVariant?: 'default' | 'success' | 'warning' | 'danger' | 'info' | 'primary';
  disabled?: boolean;
  tooltip?: string;
  customClass?: string;
}

withDefaults(
  defineProps<{
    /** Currently active tab id (use with v-model). */
    modelValue: T;
    /** Tabs to render. `icon` is an optional lucide component. */
    tabs: BaseTabItem<T>[];
    /** Visual size. `sm` (compact), `md` (standard default), `lg` (prominent). */
    size?: 'sm' | 'md' | 'lg';
    /** Whether tabs expand to fill 100% width. */
    fullWidth?: boolean;
  }>(),
  {
    size: 'md',
    fullWidth: false
  }
);

const emit = defineEmits<{
  'update:modelValue': [value: T];
  'tab-click': [tab: BaseTabItem<T>];
}>();

const handleTabClick = (tab: BaseTabItem<T>) => {
  if (!tab.disabled) {
    emit('update:modelValue', tab.id);
    emit('tab-click', tab);
  }
};
</script>

<template>
  <div class="base-tabs-wrapper" :class="{ 'base-tabs-wrapper--full': fullWidth }">
    <!-- Optional Prefix Slot -->
    <slot name="prefix" />

    <!-- Main Capsule Tab Bar -->
    <div 
      class="base-tabs" 
      :class="[
        `base-tabs--${size}`, 
        { 'base-tabs--full': fullWidth }
      ]"
    >
      <button
        v-for="tab in tabs"
        :key="tab.id"
        type="button"
        :disabled="tab.disabled"
        :title="tab.tooltip"
        :class="[
          'base-tab',
          `base-tab--${size}`,
          tab.customClass,
          { 
            active: modelValue === tab.id,
            'is-disabled': tab.disabled,
            'flex-1': fullWidth
          }
        ]"
        @click="handleTabClick(tab)"
      >
        <!-- Custom Tab Scoped Slot -->
        <slot name="tab" :tab="tab" :isActive="modelValue === tab.id">
          <!-- Leading Icon -->
          <component
            :is="tab.icon"
            v-if="tab.icon"
            :size="size === 'sm' ? 14 : size === 'lg' ? 17 : 15"
            class="base-tab__icon"
          />

          <!-- Label -->
          <span class="base-tab__label">{{ tab.label }}</span>

          <!-- Count Badge -->
          <span 
            v-if="tab.count !== undefined" 
            :class="[
              'base-tab__count',
              `count-variant-${tab.badgeVariant || 'default'}`,
              { 'count-active': modelValue === tab.id }
            ]"
          >
            {{ tab.count }}
          </span>

          <!-- Badge text -->
          <span 
            v-if="tab.badge" 
            :class="[
              'base-tab__badge',
              `badge-variant-${tab.badgeVariant || 'primary'}`
            ]"
          >
            {{ tab.badge }}
          </span>
        </slot>
      </button>

      <!-- Optional Suffix Slot inside pill -->
      <slot name="suffix" />
    </div>

    <!-- Right Actions Slot (e.g. action buttons or search) -->
    <div v-if="$slots.right" class="base-tabs-right">
      <slot name="right" />
    </div>
  </div>
</template>

<style scoped>
.base-tabs-wrapper {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  max-width: 100%;
}

.base-tabs-wrapper--full {
  display: flex;
  width: 100%;
}

.base-tabs {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px;
  background: #f4f4f5;
  border: 1px solid #e4e4e7;
  border-radius: 30px;
  user-select: none;
  overflow-x: auto;
}

.base-tabs--full {
  display: flex;
  width: 100%;
}

.base-tab {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border: none;
  background: none;
  font-weight: 600;
  color: #64748b;
  border-radius: 22px;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  outline: none;
  text-decoration: none;
}

.base-tab:hover:not(.is-disabled) {
  color: #0f172a;
}

.base-tab.active {
  background: #ffffff;
  color: #0f172a;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08), 0 1px 2px rgba(0, 0, 0, 0.04);
}

.base-tab.is-disabled {
  opacity: 0.45;
  cursor: not-allowed;
  pointer-events: none;
}

.base-tab__icon {
  color: currentColor;
  flex-shrink: 0;
}

.base-tab__label {
  line-height: 1;
}

/* Count Badges */
.base-tab__count {
  font-size: 11px;
  font-weight: 700;
  padding: 1.5px 6.5px;
  border-radius: 12px;
  background: #e2e8f0;
  color: #475569;
  line-height: 1.2;
  transition: all 0.2s ease;
}

.base-tab.active .base-tab__count {
  background: #eff6ff;
  color: #0B529C;
}

.count-variant-success { background: #dcfce7 !important; color: #15803d !important; }
.count-variant-warning { background: #fef3c7 !important; color: #b45309 !important; }
.count-variant-danger  { background: #fee2e2 !important; color: #b91c1c !important; }
.count-variant-info    { background: #e0f2fe !important; color: #0369a1 !important; }

/* Text Badges */
.base-tab__badge {
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  padding: 2px 6px;
  border-radius: 6px;
}
.badge-variant-primary { background: #0B529C; color: #ffffff; }

/* Sizes */
.base-tabs--sm .base-tab {
  padding: 6px 14px;
  font-size: 12px;
  border-radius: 18px;
}

.base-tabs--md .base-tab {
  padding: 8px 18px;
  font-size: 13px;
  border-radius: 22px;
}

.base-tabs--lg .base-tab {
  padding: 10px 22px;
  font-size: 14px;
  border-radius: 26px;
}

.base-tabs-right {
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 8px;
}
</style>
