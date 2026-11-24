<!--
  Authoritative QMT FormRadio Component (Figma 3345:19141)
  ==============================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Mutually exclusive option selection where all choices (2 to 4 options) need to be visible simultaneously.
  - Examples: Calculation basis ("Percentage" vs "Fixed Amount"), shift timing ("Fixed Hours" vs "Flexible Window").
  - Includes label and optional description beneath each radio choice.

  WHEN NOT TO USE:
  - DO NOT use for long lists of choices (>4 options, use `FormSelect.vue` dropdown instead).
  - DO NOT use for multi-select options (use `FormCheckbox.vue`).
-->
<script setup lang="ts">
import { computed } from 'vue';

type RadioValue = string | number | boolean;

interface Props {
  modelValue?: RadioValue | null;
  value: RadioValue;
  name?: string;
  label?: string;
  description?: string;
  size?: 'sm' | 'md';
  disabled?: boolean;
  error?: boolean | string;
  id?: string;
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: null,
  name: undefined,
  label: '',
  description: '',
  size: 'sm',
  disabled: false,
  error: false,
  id: undefined
});

const emit = defineEmits<{
  (e: 'update:modelValue', value: RadioValue): void;
  (e: 'change', value: RadioValue): void;
}>();

const isChecked = computed(() => props.modelValue === props.value);
const hasError = computed(() => Boolean(props.error));
const errorMessage = computed(() => (typeof props.error === 'string' ? props.error : ''));

const onChange = () => {
  if (props.disabled) return;
  emit('update:modelValue', props.value);
  emit('change', props.value);
};
</script>

<template>
  <label
    class="qmt-radio-wrapper"
    :class="[
      `qmt-radio--${size}`,
      {
        'is-checked': isChecked,
        'is-disabled': disabled,
        'has-error': hasError,
        'is-standalone': !label && !description && !$slots.default
      }
    ]"
  >
    <input
      type="radio"
      :id="id"
      :name="name"
      :value="value"
      :checked="isChecked"
      :disabled="disabled"
      :aria-invalid="hasError || undefined"
      class="qmt-radio-input"
      @change="onChange"
    />

    <span class="qmt-radio-circle" aria-hidden="true">
      <span class="qmt-radio-dot"></span>
    </span>

    <span v-if="label || description || errorMessage || $slots.default" class="qmt-radio-meta">
      <span v-if="label || $slots.default" class="qmt-radio-label">
        <slot>{{ label }}</slot>
      </span>
      <span v-if="description" class="qmt-radio-desc">{{ description }}</span>
      <span v-if="errorMessage" class="qmt-radio-error">{{ errorMessage }}</span>
    </span>
  </label>
</template>

<style scoped>
.qmt-radio-wrapper {
  position: relative;
  display: inline-flex;
  align-items: flex-start;
  cursor: pointer;
  user-select: none;
  vertical-align: middle;
}

.qmt-radio--sm {
  gap: var(--qmt-checkbox-sm-gap, 8px);
}

.qmt-radio--md {
  gap: var(--qmt-checkbox-md-gap, 12px);
}

.qmt-radio-wrapper.is-standalone {
  gap: 0;
  align-items: center;
  justify-content: center;
}

.qmt-radio-input {
  position: absolute;
  opacity: 0;
  width: 1px;
  height: 1px;
  margin: 0;
  pointer-events: none;
}

.qmt-radio-circle {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  border-radius: var(--qmt-checkbox-radio-radius, 9999px);
  background-color: var(--qmt-checkbox-bg, #ffffff);
  border: var(--qmt-checkbox-border-width, 1px) solid var(--qmt-checkbox-border, #d4d4d4);
  transition: background-color 0.15s ease, border-color 0.15s ease, box-shadow 0.15s ease, transform 0.1s ease;
}

.qmt-radio-wrapper:not(.is-standalone) .qmt-radio-circle {
  margin-top: var(--qmt-checkbox-box-offset, 2px);
}

.qmt-radio--sm .qmt-radio-circle {
  width: var(--qmt-checkbox-sm-box-size, 16px);
  height: var(--qmt-checkbox-sm-box-size, 16px);
}

.qmt-radio--md .qmt-radio-circle {
  width: var(--qmt-checkbox-md-box-size, 20px);
  height: var(--qmt-checkbox-md-box-size, 20px);
}

.qmt-radio-dot {
  border-radius: var(--qmt-checkbox-radio-radius, 9999px);
  background-color: var(--qmt-checkbox-radio-mark, #0b529c);
  opacity: 0;
  transform: scale(0.5);
  transition: opacity 0.14s ease, transform 0.14s ease, background-color 0.15s ease;
}

.qmt-radio--sm .qmt-radio-dot {
  width: 6px;
  height: 6px;
}

.qmt-radio--md .qmt-radio-dot {
  width: 8px;
  height: 8px;
}

/* Hover - Unchecked */
.qmt-radio-wrapper:not(.is-disabled):not(.is-checked):hover .qmt-radio-circle {
  background-color: var(--qmt-checkbox-bg-hover, #f1f7fe);
  border-color: var(--qmt-checkbox-border-hover, #0b529c);
}

/* Focus & Active Press - Unchecked */
.qmt-radio-wrapper:not(.is-disabled):not(.is-checked):active .qmt-radio-circle,
.qmt-radio-input:focus-visible + .qmt-radio-circle {
  background-color: var(--qmt-checkbox-bg-hover, #f1f7fe);
  border-color: var(--qmt-checkbox-border-focus, #83bff6);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-checkbox-focus-ring, #e1eefd),
    0 1px 2px 0 var(--qmt-color-shadow-faint, #0a0d120d);
}

/* Checked State */
.qmt-radio-wrapper.is-checked .qmt-radio-circle {
  background-color: var(--qmt-checkbox-radio-bg-checked, #f1f7fe);
  border-color: var(--qmt-checkbox-radio-border-checked, #0b529c);
}

.qmt-radio-wrapper.is-checked .qmt-radio-dot {
  opacity: 1;
  transform: scale(1);
}

/* Checked Hover */
.qmt-radio-wrapper.is-checked:not(.is-disabled):hover .qmt-radio-circle {
  background-color: var(--qmt-checkbox-radio-bg-checked, #f1f7fe);
  border-color: var(--qmt-checkbox-bg-checked-hover, #0d457f);
}

.qmt-radio-wrapper.is-checked:not(.is-disabled):hover .qmt-radio-dot {
  background-color: var(--qmt-checkbox-bg-checked-hover, #0d457f);
}

/* Checked Focus & Active Press */
.qmt-radio-wrapper.is-checked:not(.is-disabled):active .qmt-radio-circle,
.qmt-radio-wrapper.is-checked .qmt-radio-input:focus-visible + .qmt-radio-circle {
  border-color: var(--qmt-checkbox-radio-border-checked, #0b529c);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-checkbox-focus-ring, #e1eefd),
    0 1px 2px 0 var(--qmt-color-shadow-faint, #0a0d120d);
}

/* Error State */
.qmt-radio-wrapper.has-error:not(.is-disabled) .qmt-radio-circle {
  border-color: var(--qmt-checkbox-border-error, #ffa2a2);
  background-color: var(--qmt-checkbox-bg-error, #ffe2e2);
}

.qmt-radio-wrapper.has-error:not(.is-disabled).is-checked .qmt-radio-dot {
  background-color: var(--qmt-checkbox-mark-error, #c10007);
}

.qmt-radio-wrapper.has-error:not(.is-disabled):active .qmt-radio-circle,
.qmt-radio-wrapper.has-error .qmt-radio-input:focus-visible + .qmt-radio-circle {
  border-color: var(--qmt-checkbox-border-error, #ffa2a2);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-checkbox-focus-ring-error, #ffe2e2),
    0 1px 2px 0 var(--qmt-color-shadow-faint, #0a0d120d);
}

/* Disabled State (Unchecked & Checked) */
.qmt-radio-wrapper.is-disabled {
  cursor: not-allowed;
}

.qmt-radio-wrapper.is-disabled .qmt-radio-circle {
  background-color: var(--qmt-checkbox-bg-disabled, #fafafa);
  border-color: var(--qmt-checkbox-border-disabled, #e5e5e5);
}

.qmt-radio-wrapper.is-disabled.is-checked .qmt-radio-dot {
  background-color: var(--qmt-checkbox-mark-disabled, #a1a1a1);
}

.qmt-radio-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.qmt-radio-label {
  font-weight: 500;
  color: var(--qmt-checkbox-label, #404040);
}

.qmt-radio--sm .qmt-radio-label {
  font-size: var(--qmt-checkbox-sm-font, 14px);
  line-height: 20px;
}

.qmt-radio--md .qmt-radio-label {
  font-size: var(--qmt-checkbox-md-font, 16px);
  line-height: 24px;
}

.qmt-radio-desc {
  font-weight: 400;
  color: var(--qmt-checkbox-supporting, #737373);
}

.qmt-radio--sm .qmt-radio-desc {
  font-size: var(--qmt-checkbox-sm-supporting-font, 12px);
  line-height: 18px;
}

.qmt-radio--md .qmt-radio-desc {
  font-size: var(--qmt-checkbox-md-supporting-font, 14px);
  line-height: 20px;
}

.qmt-radio-error {
  font-size: 12px;
  line-height: 16px;
  color: var(--qmt-checkbox-mark-error, #c10007);
}

.qmt-radio-wrapper.is-disabled .qmt-radio-label,
.qmt-radio-wrapper.is-disabled .qmt-radio-desc {
  color: var(--qmt-checkbox-label-disabled, #a1a1a1);
}
</style>
