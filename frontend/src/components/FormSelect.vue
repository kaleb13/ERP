<script setup lang="ts">
import { computed } from 'vue';
import { ChevronDown } from 'lucide-vue-next';

export interface SelectOption {
  value: string | number | boolean;
  label: string;
  disabled?: boolean;
}

interface Props {
  modelValue?: any;
  label?: string;
  required?: boolean;
  placeholder?: string;
  options?: Array<SelectOption | string>;
  disabled?: boolean;
  error?: string;
  helperText?: string;
  id?: string;
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: '',
  label: '',
  required: false,
  placeholder: 'Select',
  options: () => [],
  disabled: false,
  error: '',
  helperText: '',
  id: undefined
});

const emit = defineEmits<{
  (e: 'update:modelValue', value: any): void;
  (e: 'change', event: Event): void;
}>();

const normalizedOptions = computed<SelectOption[]>(() => {
  return props.options.map((opt) => {
    if (typeof opt === 'string') {
      return { value: opt, label: opt };
    }
    return opt;
  });
});

const handleChange = (e: Event) => {
  const target = e.target as HTMLSelectElement;
  emit('update:modelValue', target.value);
  emit('change', e);
};
</script>

<template>
  <div class="form-control-wrapper" :class="{ 'has-error': !!error, 'is-disabled': disabled }">
    <!-- Form Label -->
    <label v-if="label" :for="id" class="form-label">
      {{ label }}
      <span v-if="required" class="required-asterisk">*</span>
    </label>

    <!-- Select Field Container -->
    <div class="select-container">
      <select
        :id="id"
        :value="modelValue"
        :disabled="disabled"
        class="form-select"
        @change="handleChange"
      >
        <option v-if="placeholder" value="" disabled selected hidden>
          {{ placeholder }}
        </option>
        
        <!-- Slot for custom options, fallback to normalized options prop -->
        <slot>
          <option
            v-for="opt in normalizedOptions"
            :key="String(opt.value)"
            :value="opt.value"
            :disabled="opt.disabled"
          >
            {{ opt.label }}
          </option>
        </slot>
      </select>

      <ChevronDown :size="14" class="select-arrow" />
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

.select-container {
  position: relative;
  width: 100%;
  display: flex;
  align-items: center;
}

.form-select {
  width: 100%;
  height: 38px;
  padding: 0 32px 0 12px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  color: #404040;
  outline: none;
  appearance: none;
  cursor: pointer;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
  font-family: inherit;
}

.form-select:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.select-arrow {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: #737373;
  pointer-events: none;
  flex-shrink: 0;
}

/* ERROR STATE */
.has-error .form-select {
  border-color: #dc2626;
}

.has-error .form-select:focus {
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
.is-disabled .form-select {
  background-color: #f8fafc;
  color: #94a3b8;
  cursor: not-allowed;
  border-color: #e2e8f0;
}
</style>
