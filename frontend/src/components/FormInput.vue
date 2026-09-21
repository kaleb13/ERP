<script setup lang="ts">
import type { Component } from 'vue';
import { computed, ref } from 'vue';

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
  icon: undefined,
  id: undefined,
  autocomplete: 'off',
  min: undefined,
  max: undefined,
  step: 1
});

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
  if (props.type !== 'number' || !props.modelValue) return '';
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
  <div class="form-control-wrapper" :class="{ 'has-error': !!(error || rangeWarning), 'is-disabled': disabled }">
    <!-- Form Label -->
    <label v-if="label" :for="id" class="form-label">
      {{ label }}
      <span v-if="required" class="required-asterisk">*</span>
    </label>

    <!-- NUMBER INPUT: custom spinner -->
    <div v-if="type === 'number'" class="input-container number-input-container">
      <component :is="icon" v-if="icon" :size="15" class="leading-icon" />
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
        :class="{ 'with-leading-icon': !!icon }"
        @input="handleInput"
        @blur="(e) => emit('blur', e)"
        @focus="(e) => emit('focus', e)"
      />
      <div class="number-spinner-col">
        <button type="button" class="spinner-btn spinner-up" :disabled="disabled" @click="increment">
          <svg width="10" height="6" viewBox="0 0 10 6" fill="none">
            <path d="M1 5L5 1L9 5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </button>
        <button type="button" class="spinner-btn spinner-down" :disabled="disabled" @click="decrement">
          <svg width="10" height="6" viewBox="0 0 10 6" fill="none">
            <path d="M1 1L5 5L9 1" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </button>
      </div>
    </div>

    <!-- TEXT / OTHER INPUT -->
    <div v-else class="input-container" :class="{ 'with-leading-icon': !!icon }">
      <component :is="icon" v-if="icon" :size="15" class="leading-icon" />
      <input
        :id="id"
        :type="type"
        :value="modelValue"
        :placeholder="placeholder"
        :disabled="disabled"
        :readonly="readonly"
        :autocomplete="autocomplete"
        class="form-input"
        @input="handleInput"
        @blur="(e) => emit('blur', e)"
        @focus="(e) => emit('focus', e)"
      />
      <div v-if="$slots.suffix" class="input-suffix">
        <slot name="suffix" />
      </div>
    </div>

    <!-- Range warning (out-of-bounds) -->
    <p v-if="rangeWarning" class="range-warning-text">⚠ {{ rangeWarning }}</p>
    <!-- Error or helper -->
    <p v-else-if="error" class="error-text">{{ error }}</p>
    <p v-else-if="helperText" class="helper-text">{{ helperText }}</p>
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
  color: #404040;
  user-select: none;
  display: inline-flex;
  align-items: center;
  margin-bottom: 0;
  line-height: 1.2;
}

.required-asterisk {
  color: #dc2626;
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

.leading-icon {
  position: absolute;
  left: 12px;
  color: #737373;
  pointer-events: none;
  flex-shrink: 0;
  z-index: 1;
}

.form-input {
  width: 100%;
  height: 38px;
  padding: 0 12px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  color: #404040;
  outline: none;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
  font-family: inherit;
}

/* Number input: hide native browser spinners, make room for custom ones */
.number-input {
  padding-right: 32px;
  border-radius: 8px;
  -moz-appearance: textfield;
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
  color: #94a3b8;
  padding: 0;
  transition: background-color 0.1s ease, color 0.1s ease;
  line-height: 1;
}
.spinner-btn:hover:not(:disabled) {
  background-color: #f1f5f9;
  color: #404040;
}
.spinner-btn:active:not(:disabled) {
  background-color: #e2e8f0;
}
.spinner-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}
.spinner-up {
  /* no divider */
}

.with-leading-icon .form-input {
  padding-left: 36px;
}

.form-input::placeholder {
  color: #a1a1a1;
}

.form-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}
/* Keep spinner visible on focus */
.number-input-container:focus-within .number-spinner-col {
  /* no border to update on focus */
}
.number-input-container:focus-within .number-input {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.input-suffix {
  position: absolute;
  right: 12px;
  display: flex;
  align-items: center;
}

/* ERROR STATE */
.has-error .form-input {
  border-color: #dc2626;
}
.has-error .form-input:focus {
  border-color: #dc2626;
  box-shadow: 0 0 0 3px rgba(220, 38, 38, 0.08);
}
.has-error .number-spinner-col {
  /* no border to update on error */
}

.error-text {
  font-size: 11.5px;
  color: #dc2626;
  margin: 2px 0 0 0;
  line-height: 1.3;
}

/* RANGE WARNING */
.range-warning-text {
  font-size: 11.5px;
  color: #d97706;
  margin: 2px 0 0 0;
  line-height: 1.3;
}

.helper-text {
  font-size: 11.5px;
  color: #737373;
  margin: 2px 0 0 0;
  line-height: 1.3;
}

/* DISABLED STATE */
.is-disabled .form-input {
  background-color: #f8fafc;
  color: #94a3b8;
  cursor: not-allowed;
  border-color: #e2e8f0;
}
.is-disabled .number-spinner-col {
  background-color: #f8fafc;
}
</style>
