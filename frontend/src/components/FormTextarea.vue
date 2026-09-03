<script setup lang="ts">
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
  id?: string;
}

withDefaults(defineProps<Props>(), {
  modelValue: '',
  label: '',
  required: false,
  placeholder: '',
  rows: 3,
  disabled: false,
  readonly: false,
  error: '',
  helperText: '',
  id: undefined
});

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
    <textarea
      :id="id"
      :value="modelValue"
      :placeholder="placeholder"
      :rows="rows"
      :disabled="disabled"
      :readonly="readonly"
      class="form-textarea"
      @input="handleInput"
      @blur="(e) => emit('blur', e)"
      @focus="(e) => emit('focus', e)"
    />

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

.form-textarea {
  width: 100%;
  padding: 8px 12px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  color: #404040;
  outline: none;
  resize: vertical;
  min-height: 76px;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
  font-family: inherit;
  line-height: 1.5;
}

.form-textarea::placeholder {
  color: #a1a1a1;
}

.form-textarea:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

/* ERROR STATE */
.has-error .form-textarea {
  border-color: #dc2626;
}

.has-error .form-textarea:focus {
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
.is-disabled .form-textarea {
  background-color: #f8fafc;
  color: #94a3b8;
  cursor: not-allowed;
  border-color: #e2e8f0;
}
</style>
