<script setup lang="ts">
import type { Component } from 'vue';

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
}

withDefaults(defineProps<Props>(), {
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
  autocomplete: 'off'
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
</script>

<template>
  <div class="form-control-wrapper" :class="{ 'has-error': !!error, 'is-disabled': disabled }">
    <!-- Form Label -->
    <label v-if="label" :for="id" class="form-label">
      {{ label }}
      <span v-if="required" class="required-asterisk">*</span>
    </label>

    <!-- Input Field Container -->
    <div class="input-container" :class="{ 'with-leading-icon': !!icon }">
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

    <!-- Error Message or Helper Text -->
    <p v-if="error" class="error-text">{{ error }}</p>
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

.leading-icon {
  position: absolute;
  left: 12px;
  color: #737373;
  pointer-events: none;
  flex-shrink: 0;
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

.error-text {
  font-size: 11.5px;
  color: #dc2626;
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
</style>
