<!--
  Authoritative QMT FormCheckboxCard Component
  (Figma Reference: 10415:37682 Collapsed / 10415:37687 Expanded)
  ==============================================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Conditional form sections where a boolean checkbox toggles whether nested
    input fields are shown or hidden (e.g., "No Minimum Floor" -> Minimum Amount,
    "Unlimited / Open Ceiling" -> Maximum Amount, "Requires Guarantee" -> Amount & Type).
  - Supports BOTH directions via `expandWhenChecked`:
      * `expandWhenChecked = true` (default): Checked = Expanded, Unchecked = Collapsed.
      * `expandWhenChecked = false` (inverted): Checked = Collapsed, Unchecked = Expanded
        (ideal for "No Minimum Floor" or "Unlimited Ceiling" flags).

  VISUAL CONTRACT (QMT Design System):
  - Collapsed State: Primary canvas background (`#FAFAFA`) + subtle border (`1px solid #E5E5E5`).
  - Expanded State:  Clean card white background (`#FFFFFF`) + subtle border (`1px solid #E5E5E5`)
                     with the conditional inputs rendered cleanly inside the slot.
  ==============================================================================
-->
<script setup lang="ts">
import { computed } from 'vue';
import FormCheckbox from './FormCheckbox.vue';

interface Props {
  modelValue: boolean;
  label: string;
  description?: string;
  /**
   * Controls which checkbox state expands the inner content slot:
   * - true (default): expanded when checked, collapsed when unchecked
   * - false: collapsed when checked, expanded when unchecked
   */
  expandWhenChecked?: boolean;
  disabled?: boolean;
  size?: 'sm' | 'md';
}

const props = withDefaults(defineProps<Props>(), {
  description: '',
  expandWhenChecked: true,
  disabled: false,
  size: 'sm'
});

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'change', value: boolean): void;
}>();

const isExpanded = computed(() =>
  props.expandWhenChecked ? Boolean(props.modelValue) : !Boolean(props.modelValue)
);

const handleUpdate = (val: boolean | (string | number)[]) => {
  const boolVal = Boolean(val);
  emit('update:modelValue', boolVal);
  emit('change', boolVal);
};
</script>

<template>
  <div
    class="qmt-checkbox-card"
    :class="{
      'is-expanded': isExpanded,
      'is-collapsed': !isExpanded,
      'is-disabled': disabled
    }"
  >
    <div class="qmt-checkbox-card__header">
      <FormCheckbox
        :model-value="modelValue"
        :label="label"
        :description="description"
        :disabled="disabled"
        :size="size"
        @update:model-value="handleUpdate"
      />
    </div>

    <div v-if="isExpanded && $slots.default" class="qmt-checkbox-card__body">
      <slot />
    </div>
  </div>
</template>

<style scoped>
.qmt-checkbox-card {
  border-radius: 12px;
  border: 1px solid #e5e5e5;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  transition: background-color 0.18s ease, border-color 0.18s ease;
}

/* Collapsed state: primary background (#FAFAFA) + subtle border (#E5E5E5) */
.qmt-checkbox-card.is-collapsed {
  background-color: #fafafa;
}

/* Expanded state: card white background (#FFFFFF) + subtle border (#E5E5E5) */
.qmt-checkbox-card.is-expanded {
  background-color: #ffffff;
}

.qmt-checkbox-card.is-disabled {
  opacity: 0.65;
}

.qmt-checkbox-card__header {
  display: flex;
  align-items: flex-start;
}

.qmt-checkbox-card__body {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
</style>

