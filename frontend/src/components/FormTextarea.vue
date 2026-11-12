<script setup lang="ts">
import { computed } from 'vue';
import { AlertCircle } from 'lucide-vue-next';

interface Props {
  modelValue?: string;
  label?: string;
  required?: boolean;
  placeholder?: string;
  rows?: number;
  disabled?: boolean;
  readonly?: boolean;
  error?: string;
  helperText?: string;
  hint?: string;
  id?: string;
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: '',
  label: '',
  required: false,
  placeholder: '',
  rows: 3,
  disabled: false,
  readonly: false,
  error: '',
  helperText: '',
  hint: '',
  id: undefined
});

const displayHelper = computed(() => props.hint || props.helperText || '');

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void;
  (e: 'blur', event: FocusEvent): void;
  (e: 'focus', event: FocusEvent): void;
}>();

const handleInput = (e: Event) => {
  const target = e.target as HTMLTextAreaElement;
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

    <!-- Textarea -->
    <div class="textarea-container">
      <textarea
        :id="id"
        :value="modelValue"
        :placeholder="placeholder"
        :rows="rows"
        :disabled="disabled"
        :readonly="readonly"
        class="form-textarea"
        :class="{ 'with-error-icon': !!error }"
        @input="handleInput"
        @blur="(e) => emit('blur', e)"
        @focus="(e) => emit('focus', e)"
      />
      <AlertCircle
        v-if="error"
        :size="16"
        class="textarea-error-icon"
        aria-hidden="true"
      />
    </div>

    <!-- Error Message or Helper Text -->
    <p v-if="error" class="error-text">{{ error }}</p>
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

.textarea-container {
  position: relative;
  width: 100%;
  display: flex;
}

.form-textarea {
  width: 100%;
  padding: 8px 12px;
  background-color: var(--qmt-input-bg, #ffffff);
  border: var(--qmt-input-border-width, 1px) solid var(--qmt-input-border, #d4d4d4);
  border-radius: var(--qmt-input-radius, 8px);
  font-size: 13.5px;
  color: var(--qmt-input-fg, #404040);
  outline: none;
  resize: vertical;
  min-height: 76px;
  box-shadow: 0 1px 2px 0 var(--qmt-color-shadow-faint);
  transition: border-color 0.15s ease, box-shadow 0.15s ease, background-color 0.15s ease;
  font-family: inherit;
  line-height: 1.5;
}

.form-textarea.with-error-icon {
  padding-right: 36px;
}

.form-textarea::placeholder {
  color: var(--qmt-input-placeholder, #737373);
}

.form-textarea:focus {
  border-color: var(--qmt-input-border-focus, #83bff6);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-brand, #e1eefd),
    0 1px 2px 0 var(--qmt-color-shadow-faint);
}

.textarea-error-icon {
  position: absolute;
  top: 10px;
  right: 12px;
  color: var(--qmt-input-error-icon, #e7000b);
  pointer-events: none;
}

/* ERROR STATE (QMT Destructive=True) */
.has-error .form-textarea {
  border-color: var(--qmt-input-border-error, #ffa2a2);
}

.has-error .form-textarea:focus {
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

.helper-text {
  font-size: 11.5px;
  color: var(--qmt-input-hint, #737373);
  margin: 2px 0 0 0;
  line-height: 1.35;
}

/* DISABLED STATE */
.is-disabled .form-textarea {
  background-color: var(--qmt-input-bg-disabled, #fafafa);
  color: var(--qmt-input-fg-disabled, #a1a1a1);
  cursor: not-allowed;
  border-color: var(--qmt-input-border-disabled, #d4d4d4);
}
</style>
