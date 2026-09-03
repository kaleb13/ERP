<script setup lang="ts" generic="T extends string | number">
import type { Component } from 'vue';

export interface UnderlineTabItem<IdType = T> {
  id: IdType;
  label: string;
  count?: number | string;
  icon?: Component;
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
    /** Tabs array with label, optional count, icon, and badge. */
    tabs: UnderlineTabItem<T>[];
    /** Visual size. `sm` (compact), `md` (standard default), `lg` (prominent). */
    size?: 'sm' | 'md' | 'lg';
    /** Whether tabs expand to fill 100% width. */
    fullWidth?: boolean;
    /** Alignment of tabs: `start` (default), `center`, `end`, `between`. */
    justify?: 'start' | 'center' | 'end' | 'between';
    /** Whether to show the bottom border line across the bar. */
    showBottomBorder?: boolean;
  }>(),
  {
    size: 'md',
    fullWidth: false,
    justify: 'start',
    showBottomBorder: true
  }
);

const emit = defineEmits<{
  'update:modelValue': [value: T];
  'tab-click': [tab: UnderlineTabItem<T>];
}>();

const handleTabClick = (tab: UnderlineTabItem<T>) => {
  if (!tab.disabled) {
    emit('update:modelValue', tab.id);
    emit('tab-click', tab);
  }
};
</script>

<template>
  <div 
    class="underline-tabs-container"
    :class="[
      { 'has-bottom-border': showBottomBorder },
      `justify-${justify}`
    ]"
  >
    <!-- Optional Prefix Slot -->
    <slot name="prefix" />

    <!-- Tab Buttons List -->
    <div 
      class="underline-tabs"
      :class="[
        `underline-tabs--${size}`,
        `justify-${justify}`,
        { 'underline-tabs--full': fullWidth }
      ]"
    >
      <button
        v-for="tab in tabs"
        :key="tab.id"
        type="button"
        :disabled="tab.disabled"
        :title="tab.tooltip"
        :class="[
          'underline-tab',
          `underline-tab--${size}`,
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
            class="tab-icon" 
          />

          <!-- Label Text -->
          <span class="tab-label">{{ tab.label }}</span>

          <!-- Count Badge Pill -->
          <span 
            v-if="tab.count !== undefined" 
            :class="[
              'tab-count-badge',
              `count-variant-${tab.badgeVariant || 'default'}`,
              { 'count-active': modelValue === tab.id }
            ]"
          >
            {{ tab.count }}
          </span>

          <!-- Text Badge -->
          <span 
            v-if="tab.badge" 
            :class="[
              'tab-text-badge',
              `badge-variant-${tab.badgeVariant || 'primary'}`
            ]"
          >
            {{ tab.badge }}
          </span>
        </slot>

        <!-- Active Bottom Blue Bar Indicator -->
        <div v-if="modelValue === tab.id" class="active-indicator"></div>
      </button>

      <!-- Optional Suffix Slot inside tabs list -->
      <slot name="suffix" />
    </div>

    <!-- Right Actions Slot (e.g. search, filters, or add button) -->
    <div v-if="$slots.right" class="underline-tabs-right">
      <slot name="right" />
    </div>
  </div>
</template>

<style scoped>
.underline-tabs-container {
  display: flex;
  align-items: center;
  width: 100%;
  position: relative;
}

.underline-tabs-container.has-bottom-border {
  border-bottom: 1px solid #e2e8f0;
}

.underline-tabs {
  display: flex;
  align-items: center;
  gap: 8px;
  overflow-x: auto;
  user-select: none;
  scrollbar-width: none;
}

.underline-tabs::-webkit-scrollbar {
  display: none;
}

.underline-tabs--full {
  width: 100%;
}

.justify-start { justify-content: flex-start; }
.justify-center { justify-content: center; }
.justify-end { justify-content: flex-end; }
.justify-between { justify-content: space-between; }

.underline-tab {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border: none;
  background: none;
  color: #64748b;
  cursor: pointer;
  white-space: nowrap;
  transition: color 0.15s ease;
  outline: none;
  text-decoration: none;
}

.underline-tab:hover:not(.is-disabled) {
  color: #0f172a;
}

.underline-tab.active {
  color: #0B529C;
  font-weight: 600;
}

.underline-tab.is-disabled {
  opacity: 0.45;
  cursor: not-allowed;
  pointer-events: none;
}

.tab-icon {
  color: currentColor;
  flex-shrink: 0;
}

.tab-label {
  line-height: 1.2;
}

/* Active Bottom Blue Indicator */
.active-indicator {
  position: absolute;
  bottom: -1px;
  left: 0;
  right: 0;
  height: 2.5px;
  background-color: #0B529C;
  border-radius: 2px 2px 0 0;
  z-index: 2;
}

/* Count Badges */
.tab-count-badge {
  font-size: 11px;
  font-weight: 600;
  padding: 2px 7.5px;
  border-radius: 12px;
  background: #f1f5f9;
  color: #475569;
  line-height: 1.2;
  transition: all 0.2s ease;
}

.underline-tab.active .tab-count-badge {
  background: #eff6ff;
  color: #0B529C;
}

.count-variant-success { background: #dcfce7 !important; color: #15803d !important; }
.count-variant-warning { background: #fef3c7 !important; color: #b45309 !important; }
.count-variant-danger  { background: #fee2e2 !important; color: #b91c1c !important; }
.count-variant-info    { background: #e0f2fe !important; color: #0369a1 !important; }

/* Text Badges */
.tab-text-badge {
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  padding: 2px 6px;
  border-radius: 6px;
}
.badge-variant-primary { background: #0B529C; color: #ffffff; }

/* Sizes */
.underline-tab--sm {
  padding: 8px 12px;
  font-size: 12.5px;
}

.underline-tab--md {
  padding: 10px 16px;
  font-size: 13.5px;
}

.underline-tab--lg {
  padding: 12px 20px;
  font-size: 14.5px;
}

.underline-tabs-right {
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 8px;
  padding-left: 12px;
}
</style>
