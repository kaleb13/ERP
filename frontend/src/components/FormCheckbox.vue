<script setup lang="ts">
interface Props {
  modelValue?: boolean;
  label?: string;
  description?: string;
  disabled?: boolean;
  id?: string;
  name?: string;
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: false,
  label: '',
  description: '',
  disabled: false,
  id: undefined,
  name: undefined
});

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'change', value: boolean): void;
}>();

const onInput = (event: Event) => {
  const target = event.target as HTMLInputElement;
  emit('update:modelValue', target.checked);
  emit('change', target.checked);
};
</script>

<template>
  <label 
    class="form-checkbox-wrapper" 
    :class="{ 'is-disabled': disabled, 'is-standalone': !label && !description }"
  >
    <input
      type="checkbox"
      :id="id"
      :name="name"
      :checked="modelValue"
      :disabled="disabled"
      class="custom-squircle-check"
      @change="onInput"
    />
    <span v-if="label || description" class="form-checkbox-meta">
      <span v-if="label" class="form-checkbox-title">{{ label }}</span>
      <span v-if="description" class="form-checkbox-desc">{{ description }}</span>
    </span>
  </label>
</template>

<style scoped>
.form-checkbox-wrapper {
  display: inline-flex;
  align-items: flex-start;
  gap: 10px;
  cursor: pointer;
  user-select: none;
  vertical-align: middle;
}

.form-checkbox-wrapper.is-standalone {
  gap: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.form-checkbox-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
  cursor: pointer;
}

.form-checkbox-title {
  font-size: 13.5px;
  font-weight: 500;
  color: #262626;
  line-height: 1.35;
}

.form-checkbox-desc {
  font-size: 12px;
  color: #737373;
  line-height: 1.4;
}

.form-checkbox-wrapper.is-disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.form-checkbox-wrapper.is-disabled .custom-squircle-check,
.form-checkbox-wrapper.is-disabled .form-checkbox-meta {
  cursor: not-allowed;
}
</style>
