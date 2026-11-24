<!--
  Authoritative QMT Table Toggle Cell Component
  Figma Copy Source: Column Presets Strip 3 - To Copy (10178:34635) in Haleta-ERP---Procurement-Module
  =====================================================================================================
  WHEN TO USE:
  - Fast inline boolean toggle cells inside standard data tables (AppDataTable / BaseTable)
    and dynamic sub-tables (DynamicSubTable via `type: 'switch'`).
  - Displays a 36x20 QMT pill toggle (`#0B529C` active, `#E5E5E5` inactive) + 12px gap + `Yes` / `No`
    label (`14px` Medium `#404040`).
-->
<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    modelValue: boolean;
    yesLabel?: string;
    noLabel?: string;
    disabled?: boolean;
    ariaLabel?: string;
  }>(),
  {
    yesLabel: 'Yes',
    noLabel: 'No',
    disabled: false,
    ariaLabel: 'Toggle value'
  }
);

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'change', value: boolean): void;
}>();

const handleToggle = () => {
  if (props.disabled) return;
  const next = !props.modelValue;
  emit('update:modelValue', next);
  emit('change', next);
};
</script>

<template>
  <div class="qmt-table-toggle-cell" :class="{ 'is-disabled': disabled }" @click.stop>
    <button
      type="button"
      class="qmt-table-toggle-track"
      :class="{ 'is-active': modelValue }"
      role="switch"
      :aria-checked="modelValue"
      :aria-label="ariaLabel"
      :disabled="disabled"
      @click="handleToggle"
    >
      <span class="qmt-table-toggle-thumb"></span>
    </button>
    <span class="qmt-table-toggle-label">{{ modelValue ? yesLabel : noLabel }}</span>
  </div>
</template>

<style scoped>
.qmt-table-toggle-cell {
  display: inline-flex;
  align-items: center;
  gap: 12px;
}

.qmt-table-toggle-cell.is-disabled {
  opacity: 0.6;
}

.qmt-table-toggle-track {
  width: 36px;
  height: 20px;
  background-color: #e5e5e5;
  border-radius: 9999px;
  border: none;
  cursor: pointer;
  position: relative;
  padding: 2px;
  flex-shrink: 0;
  transition: background-color 0.2s ease;
  display: inline-flex;
  align-items: center;
  outline: none;
}

.qmt-table-toggle-track:disabled {
  cursor: not-allowed;
}

.qmt-table-toggle-track.is-active {
  background-color: var(--alias-color-brand-default, #0b529c);
}

.qmt-table-toggle-thumb {
  width: 16px;
  height: 16px;
  background-color: #ffffff;
  border-radius: 9999px;
  display: block;
  transition: transform 0.2s ease;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.15);
}

.qmt-table-toggle-track.is-active .qmt-table-toggle-thumb {
  transform: translateX(16px);
}

.qmt-table-toggle-label {
  font-size: 14px;
  line-height: 20px;
  font-weight: 500;
  color: var(--alias-color-text-secondary, #404040);
  min-width: 24px;
  user-select: none;
}
</style>

