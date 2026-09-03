<script setup lang="ts">
import { Check } from 'lucide-vue-next';

interface Props {
  modelValue?: boolean;
  label: string;
  description?: string;
  disabled?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: false,
  description: '',
  disabled: false
});

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'change', value: boolean): void;
}>();

const toggle = () => {
  if (!props.disabled) {
    const next = !props.modelValue;
    emit('update:modelValue', next);
    emit('change', next);
  }
};
</script>

<template>
  <label 
    class="custom-checkbox-row" 
    :class="{ 'is-disabled': disabled }" 
    @click.prevent="toggle"
  >
    <div class="custom-checkbox-box" :class="{ 'checked': modelValue }">
      <Check v-if="modelValue" :size="13" stroke-width="2.5" class="checkbox-checkmark" />
    </div>

    <div class="checkbox-label-block">
      <span class="checkbox-label-title">{{ label }}</span>
      <span v-if="description" class="checkbox-label-desc">{{ description }}</span>
    </div>
  </label>
</template>

<style scoped>
.custom-checkbox-row {
  display: flex;
  gap: 12px;
  align-items: flex-start;
  cursor: pointer;
  padding: 4px 0;
  user-select: none;
  font-family: inherit;
}

.custom-checkbox-box {
  width: 18px;
  height: 18px;
  border: 1.5px solid #d4d4d4;
  border-radius: 5px;
  background-color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  margin-top: 1px;
  transition: all 0.15s ease;
}

.custom-checkbox-box.checked {
  background-color: #0B529C;
  border-color: #0B529C;
}

.checkbox-checkmark {
  color: #ffffff;
}

.checkbox-label-block {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.checkbox-label-title {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  line-height: 1.3;
}

.checkbox-label-desc {
  font-size: 12px;
  color: #737373;
  line-height: 1.4;
}

.is-disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
