<!--
  Authoritative QMT FormInput Component (Figma 3345:19141)
  ============================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Primary single-line input across the entire ERP for text, numbers, codes, dates, email, and phone.
  - Supports leading icons, trailing icons, leading prefixes (e.g. `ETB`), currency formatting, helper text, and error states.

  WHEN NOT TO USE:
  - DO NOT use for multi-line text, operational descriptions, or circular notes (use `FormRichText.vue` or `FormTextarea.vue`).
  - DO NOT use for choices/options (use `FormSelect.vue` or `FormCombobox.vue`).
  - DO NOT use raw HTML `<input>` elements directly in templates.
-->
<script setup lang="ts">
import type { Component } from 'vue';
import { computed } from 'vue';
import { AlertCircle, HelpCircle, Calendar, ChevronUp, ChevronDown } from 'lucide-vue-next';

interface Props {
  modelValue?: string | number | null;
  label?: string;
  required?: boolean;
  type?: string;
  placeholder?: string;
  disabled?: boolean;
  readonly?: boolean;
  error?: string;
  helperText?: string;
  hint?: string;
  helpText?: string;
  helpIcon?: boolean;
  leadingText?: string;
  icon?: Component;
  id?: string;
  autocomplete?: string;
  min?: number;
  max?: number;
  step?: number;
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: '',
  label: '',
  required: false,
  type: 'text',
  placeholder: '',
  disabled: false,
  readonly: false,
  error: '',
  helperText: '',
  hint: '',
  helpText: '',
  helpIcon: false,
  leadingText: '',
  icon: undefined,
  id: undefined,
  autocomplete: 'off',
  min: undefined,
  max: undefined,
  step: 1
});

const displayHelper = computed(() => props.hint || props.helperText || '');
const hasError = computed(() => !!(props.error || rangeWarning.value));

const emit = defineEmits<{
  (e: 'update:modelValue', value: string | number): void;
  (e: 'blur', event: FocusEvent): void;
  (e: 'focus', event: FocusEvent): void;
}>();

const handleInput = (e: Event) => {
  const target = e.target as HTMLInputElement;
  emit('update:modelValue', target.value);
};

const numericValue = computed(() => Number(props.modelValue) || 0);

const rangeWarning = computed(() => {
  if (props.type !== 'number' || props.modelValue === '' || props.modelValue === null || props.modelValue === undefined) {
    return '';
  }
  const val = numericValue.value;
  if (props.min !== undefined && val < props.min) return `Value is below the minimum (${props.min.toLocaleString()})`;
  if (props.max !== undefined && val > props.max) return `Value exceeds the maximum (${props.max.toLocaleString()})`;
  return '';
});

const increment = () => {
  if (props.disabled || props.readonly) return;
  const next = numericValue.value + (props.step ?? 1);
  emit('update:modelValue', props.max !== undefined ? Math.min(next, props.max) : next);
};

const decrement = () => {
  if (props.disabled || props.readonly) return;
  const next = numericValue.value - (props.step ?? 1);
  emit('update:modelValue', props.min !== undefined ? Math.max(next, props.min) : next);
};
</script>

<template>
  <div
    class="form-control-wrapper"
    :class="{
      'has-error': hasError,
      'is-disabled': disabled,
      'has-leading-text': !!leadingText
    }"
  >
    <!-- Form Label -->
    <label v-if="label" :for="id" class="form-label">
      {{ label }}
      <span v-if="required" class="required-asterisk">*</span>
    </label>

    <!-- NUMBER INPUT: custom spinner -->
    <div v-if="type === 'number'" class="input-container number-input-container">
      <span v-if="leadingText" class="leading-addon">{{ leadingText }}</span>
      <component :is="icon" v-if="icon && !leadingText" :size="16" class="leading-icon" />
      <input
        :id="id"
        type="number"
        :value="modelValue"
        :placeholder="placeholder"
        :disabled="disabled"
        :readonly="readonly"
        :min="min"
        :max="max"
        :step="step"
        :autocomplete="autocomplete"
        class="form-input number-input"
        :class="{
          'with-leading-icon': !!icon && !leadingText,
          'with-error-trailing': hasError
        }"
        @input="handleInput"
        @blur="(e) => emit('blur', e)"
        @focus="(e) => emit('focus', e)"
      />
      <AlertCircle
        v-if="hasError"
        :size="16"
        class="trailing-status-icon trailing-error-icon trailing-error-icon--number"
        aria-hidden="true"
      />
      <div class="number-spinner-col">
        <button type="button" class="spinner-btn spinner-up" :disabled="disabled" @click="increment">
          <ChevronUp :size="10" stroke-width="2.5" />
        </button>
        <button type="button" class="spinner-btn spinner-down" :disabled="disabled" @click="decrement">
          <ChevronDown :size="10" stroke-width="2.5" />
        </button>
      </div>
    </div>

    <!-- TEXT / OTHER INPUT -->
    <div
      v-else
      class="input-container"
      :class="{ 'with-leading-icon': !!icon && !leadingText }"
    >
      <span v-if="leadingText" class="leading-addon">{{ leadingText }}</span>
      <component :is="icon" v-if="icon && !leadingText" :size="16" class="leading-icon" />
      <input
        :id="id"
        :type="type"
        :value="modelValue"
        :placeholder="placeholder"
        :disabled="disabled"
        :readonly="readonly"
        :autocomplete="autocomplete"
        class="form-input"
        :class="{
          'with-trailing-slot': !!$slots.suffix || hasError || helpIcon || !!helpText || type === 'date'
        }"
        @input="handleInput"
        @blur="(e) => emit('blur', e)"
        @focus="(e) => emit('focus', e)"
      />
      <div v-if="$slots.suffix || hasError || helpIcon || helpText || type === 'date'" class="input-suffix">
        <slot name="suffix" />
        <AlertCircle
          v-if="hasError && !$slots.suffix"
          :size="16"
          class="trailing-status-icon trailing-error-icon"
          aria-hidden="true"
        />
        <span
          v-else-if="(helpIcon || helpText) && !$slots.suffix"
          class="trailing-status-icon trailing-help-icon"
          :title="helpText || undefined"
        >
          <HelpCircle :size="16" />
        </span>
        <span
          v-else-if="type === 'date' && !$slots.suffix"
          class="trailing-status-icon trailing-date-icon"
        >
          <Calendar :size="16" class="text-neutral-400" />
        </span>
      </div>
    </div>

    <!-- Range warning (out-of-bounds) -->
    <p v-if="rangeWarning" class="range-warning-text">{{ rangeWarning }}</p>
    <!-- Error or helper -->
    <p v-else-if="error" class="error-text">{{ error }}</p>
    <p v-else-if="displayHelper" class="helper-text">{{ displayHelper }}</p>
  </div>
</template>

<style scoped>
.form-control-wrapper {
  display: flex;
  flex-direction: column;
  gap: 3px;
  width: 100%;
  font-family: inherit;
}

.form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: var(--qmt-input-label, #404040);
  user-select: none;
  display: inline-flex;
  align-items: center;
  margin-bottom: 0;
  line-height: 1.2;
}

.required-asterisk {
  color: var(--qmt-input-error-icon, #e7000b);
  font-weight: 600;
  margin-left: 3px;
}

.input-container {
  position: relative;
  width: 100%;
  display: flex;
  align-items: center;
}

/* ── Number input container ── */
.number-input-container {
  position: relative;
  display: flex;
  align-items: stretch;
  width: 100%;
}

.leading-addon {
  display: inline-flex;
  align-items: center;
  height: var(--qmt-input-sm-height, 38px);
  padding: 0 12px;
  background-color: var(--qmt-input-bg, #ffffff);
  border: var(--qmt-input-border-width, 1px) solid var(--qmt-input-border, #d4d4d4);
  border-right: none;
  border-radius: var(--qmt-input-radius, 8px) 0 0 var(--qmt-input-radius, 8px);
  color: var(--qmt-input-placeholder, #737373);
  font-size: 13.5px;
  white-space: nowrap;
  flex-shrink: 0;
  box-shadow: 0 1px 2px 0 var(--qmt-color-shadow-faint);
}

.has-leading-text .form-input {
  border-top-left-radius: 0;
  border-bottom-left-radius: 0;
}

.is-disabled .leading-addon {
  background-color: var(--qmt-input-bg-disabled, #fafafa);
  color: var(--qmt-input-fg-disabled, #a1a1a1);
  border-color: var(--qmt-input-border-disabled, #d4d4d4);
}

.leading-icon {
  position: absolute;
  left: 12px;
  color: var(--qmt-input-icon, #737373);
  pointer-events: none;
  flex-shrink: 0;
  z-index: 1;
}

.form-input {
  width: 100%;
  height: var(--qmt-input-sm-height, 38px);
  padding: 0 var(--qmt-input-sm-padding-x, 12px);
  background-color: var(--qmt-input-bg, #ffffff);
  border: var(--qmt-input-border-width, 1px) solid var(--qmt-input-border, #d4d4d4);
  border-radius: var(--qmt-input-radius, 8px);
  font-size: 13.5px;
  color: var(--qmt-input-fg, #404040);
  outline: none;
  box-shadow: 0 1px 2px 0 var(--qmt-color-shadow-faint);
  transition: border-color 0.15s ease, box-shadow 0.15s ease, background-color 0.15s ease;
  font-family: inherit;
}

.with-trailing-slot {
  padding-right: 36px;
}

.form-input[type="date"]::-webkit-calendar-picker-indicator {
  position: absolute;
  right: 10px;
  top: 50%;
  transform: translateY(-50%);
  opacity: 0;
  width: 24px;
  height: 24px;
  cursor: pointer;
}

.trailing-date-icon {
  color: var(--qmt-input-placeholder, #737373);
  pointer-events: none;
}

/* Number input: hide native browser spinners, make room for custom ones */
.number-input {
  padding-right: 32px;
  border-radius: var(--qmt-input-radius, 8px);
  -moz-appearance: textfield;
}

.number-input.with-error-trailing {
  padding-right: 54px;
}

.number-input::-webkit-outer-spin-button,
.number-input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

/* Custom spinner column */
.number-spinner-col {
  position: absolute;
  right: 8px;
  top: 50%;
  transform: translateY(-50%);
  width: 16px;
  height: 26px;
  display: flex;
  flex-direction: column;
  background: transparent;
  gap: 0;
}

.spinner-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  cursor: pointer;
  color: var(--qmt-input-icon, #737373);
  padding: 0;
  transition: background-color 0.1s ease, color 0.1s ease;
  line-height: 1;
}
.spinner-btn:hover:not(:disabled) {
  background-color: var(--qmt-input-option-bg-active, #f5f5f5);
  color: var(--qmt-input-fg, #404040);
}
.spinner-btn:active:not(:disabled) {
  background-color: var(--qmt-input-popover-border, #e5e5e5);
}
.spinner-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.with-leading-icon .form-input {
  padding-left: 36px;
}

.form-input::placeholder {
  color: var(--qmt-input-placeholder, #737373);
}

.form-input:focus {
  border-color: var(--qmt-input-border-focus, #83bff6);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-brand, #e1eefd),
    0 1px 2px 0 var(--qmt-color-shadow-faint);
}

.number-input-container:focus-within .number-input {
  border-color: var(--qmt-input-border-focus, #83bff6);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-brand, #e1eefd),
    0 1px 2px 0 var(--qmt-color-shadow-faint);
}

.input-suffix {
  position: absolute;
  right: 12px;
  display: flex;
  align-items: center;
  gap: 6px;
}

.trailing-status-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.trailing-error-icon {
  color: var(--qmt-input-error-icon, #e7000b);
  pointer-events: none;
}

.trailing-error-icon--number {
  position: absolute;
  right: 30px;
  top: 50%;
  transform: translateY(-50%);
}

.trailing-help-icon {
  color: var(--qmt-input-help-icon, #737373);
  cursor: help;
}

/* ERROR STATE (QMT Destructive=True) */
.has-error .form-input,
.has-error .leading-addon {
  border-color: var(--qmt-input-border-error, #ffa2a2);
}

.has-error .form-input:focus,
.has-error .number-input-container:focus-within .number-input {
  border-color: var(--qmt-input-border-error, #ffa2a2);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-error, #ffe2e2),
    0 1px 2px 0 var(--qmt-color-shadow-faint);
}

.error-text {
  font-size: 11.5px;
  color: var(--qmt-input-hint-error, #c10007);
  margin: 2px 0 0 0;
  line-height: 1.35;
}

/* RANGE WARNING */
.range-warning-text {
  font-size: 11.5px;
  color: var(--qmt-badge-warning-fg, #bb4d00);
  margin: 2px 0 0 0;
  line-height: 1.35;
}

.helper-text {
  font-size: 11.5px;
  color: var(--qmt-input-hint, #737373);
  margin: 2px 0 0 0;
  line-height: 1.35;
}

/* DISABLED STATE */
.is-disabled .form-input {
  background-color: var(--qmt-input-bg-disabled, #fafafa);
  color: var(--qmt-input-fg-disabled, #a1a1a1);
  cursor: not-allowed;
  border-color: var(--qmt-input-border-disabled, #d4d4d4);
}
.is-disabled .number-spinner-col {
  background-color: var(--qmt-input-bg-disabled, #fafafa);
}
</style>
