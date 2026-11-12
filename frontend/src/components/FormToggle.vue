<script setup lang="ts">
import { computed } from 'vue';

interface Props {
  modelValue?: boolean;
  size?: 'sm' | 'md';
  labelPosition?: 'right' | 'left';
  label?: string;
  description?: string;
  disabled?: boolean;
  error?: boolean | string;
  id?: string;
  name?: string;
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: false,
  size: 'sm',
  labelPosition: 'right',
  label: '',
  description: '',
  disabled: false,
  error: false,
  id: undefined,
  name: undefined
});

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'change', value: boolean): void;
}>();

const isPressed = computed(() => Boolean(props.modelValue));
const hasError = computed(() => Boolean(props.error));
const errorMessage = computed(() => (typeof props.error === 'string' ? props.error : ''));

const onChange = (event: Event) => {
  if (props.disabled) return;
  const target = event.target as HTMLInputElement;
  emit('update:modelValue', target.checked);
  emit('change', target.checked);
};
</script>

<template>
  <label
    class="qmt-toggle-wrapper"
    :class="[
      `qmt-toggle--${size}`,
      `qmt-toggle--label-${labelPosition}`,
      {
        'is-on': isPressed,
        'is-disabled': disabled,
        'has-error': hasError,
        'is-standalone': !label && !description && !$slots.default
      }
    ]"
  >
    <input
      type="checkbox"
      role="switch"
      :id="id"
      :name="name"
      :checked="isPressed"
      :disabled="disabled"
      :aria-checked="isPressed"
      :aria-invalid="hasError || undefined"
      class="qmt-toggle-input"
      @change="onChange"
    />

    <span class="qmt-toggle-track" aria-hidden="true">
      <span class="qmt-toggle-thumb"></span>
    </span>

    <span v-if="label || description || errorMessage || $slots.default" class="qmt-toggle-meta">
      <span v-if="label || $slots.default" class="qmt-toggle-label">
        <slot>{{ label }}</slot>
      </span>
      <span v-if="description" class="qmt-toggle-desc">{{ description }}</span>
      <span v-if="errorMessage" class="qmt-toggle-error">{{ errorMessage }}</span>
    </span>
  </label>
</template>

<style scoped>
.qmt-toggle-wrapper {
  position: relative;
  display: inline-flex;
  align-items: flex-start;
  cursor: pointer;
  user-select: none;
  vertical-align: middle;
}

.qmt-toggle--sm {
  gap: var(--qmt-toggle-sm-gap, 8px);
}

.qmt-toggle--md {
  gap: var(--qmt-toggle-md-gap, 12px);
}

.qmt-toggle--label-left {
  flex-direction: row-reverse;
  justify-content: space-between;
}

.qmt-toggle-wrapper.is-standalone {
  gap: 0;
  align-items: center;
  justify-content: center;
}

.qmt-toggle-input {
  position: absolute;
  opacity: 0;
  width: 1px;
  height: 1px;
  margin: 0;
  pointer-events: none;
}

.qmt-toggle-track {
  display: inline-flex;
  align-items: center;
  flex-shrink: 0;
  padding: var(--qmt-toggle-padding, 2px);
  border-radius: var(--qmt-toggle-radius, 9999px);
  background-color: var(--qmt-toggle-track-bg, #f5f5f5);
  transition: background-color 0.18s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.15s ease;
  box-sizing: border-box;
}

.qmt-toggle--sm .qmt-toggle-track {
  width: var(--qmt-toggle-sm-track-width, 36px);
  height: var(--qmt-toggle-sm-track-height, 20px);
}

.qmt-toggle--md .qmt-toggle-track {
  width: var(--qmt-toggle-md-track-width, 44px);
  height: var(--qmt-toggle-md-track-height, 24px);
}

.qmt-toggle-thumb {
  display: block;
  border-radius: var(--qmt-toggle-radius, 9999px);
  background-color: var(--qmt-toggle-thumb-bg, #ffffff);
  box-shadow:
    0 1px 3px 0 rgba(10, 13, 18, 0.1),
    0 1px 2px -1px rgba(10, 13, 18, 0.08);
  transition: transform 0.18s cubic-bezier(0.16, 1, 0.3, 1), background-color 0.15s ease;
}

.qmt-toggle--sm .qmt-toggle-thumb {
  width: var(--qmt-toggle-sm-thumb-size, 16px);
  height: var(--qmt-toggle-sm-thumb-size, 16px);
}

.qmt-toggle--md .qmt-toggle-thumb {
  width: var(--qmt-toggle-md-thumb-size, 20px);
  height: var(--qmt-toggle-md-thumb-size, 20px);
}

/* Hover - Off */
.qmt-toggle-wrapper:not(.is-disabled):not(.is-on):hover .qmt-toggle-track {
  background-color: var(--qmt-toggle-track-bg-hover, #e5e5e5);
}

/* Pressed / On */
.qmt-toggle-wrapper.is-on .qmt-toggle-track {
  background-color: var(--qmt-toggle-track-bg-on, #0b529c);
}

.qmt-toggle--sm.is-on .qmt-toggle-thumb {
  transform: translateX(16px);
}

.qmt-toggle--md.is-on .qmt-toggle-thumb {
  transform: translateX(20px);
}

/* Hover - On */
.qmt-toggle-wrapper.is-on:not(.is-disabled):hover .qmt-toggle-track {
  background-color: var(--qmt-toggle-track-bg-on-hover, #0d457f);
}

/* Focus & Active Press */
.qmt-toggle-wrapper:not(.is-disabled):active .qmt-toggle-track,
.qmt-toggle-input:focus-visible + .qmt-toggle-track {
  box-shadow: 0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-checkbox-focus-ring, #e1eefd);
}

/* Error State */
.qmt-toggle-wrapper.has-error:not(.is-disabled):not(.is-on) .qmt-toggle-track {
  background-color: var(--qmt-checkbox-bg-error, #ffe2e2);
  box-shadow: inset 0 0 0 1px var(--qmt-checkbox-border-error, #ffa2a2);
}

.qmt-toggle-wrapper.has-error:not(.is-disabled).is-on .qmt-toggle-track {
  background-color: var(--qmt-checkbox-mark-error, #c10007);
}

.qmt-toggle-wrapper.has-error:not(.is-disabled):active .qmt-toggle-track,
.qmt-toggle-wrapper.has-error .qmt-toggle-input:focus-visible + .qmt-toggle-track {
  box-shadow: 0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-checkbox-focus-ring-error, #ffe2e2);
}

/* Disabled State (On & Off) */
.qmt-toggle-wrapper.is-disabled {
  cursor: not-allowed;
}

.qmt-toggle-wrapper.is-disabled .qmt-toggle-track {
  background-color: var(--qmt-toggle-track-bg-disabled, #f5f5f5);
}

.qmt-toggle-wrapper.is-disabled .qmt-toggle-thumb {
  background-color: var(--qmt-toggle-thumb-bg-disabled, #fafafa);
  box-shadow: 0 1px 2px 0 rgba(10, 13, 18, 0.05);
}

.qmt-toggle-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.qmt-toggle-label {
  font-weight: 500;
  color: var(--qmt-toggle-label, #404040);
}

.qmt-toggle--sm .qmt-toggle-label {
  font-size: var(--qmt-checkbox-sm-font, 14px);
  line-height: 20px;
}

.qmt-toggle--md .qmt-toggle-label {
  font-size: var(--qmt-checkbox-md-font, 16px);
  line-height: 24px;
}

.qmt-toggle-desc {
  font-weight: 400;
  color: var(--qmt-toggle-supporting, #737373);
}

.qmt-toggle--sm .qmt-toggle-desc {
  font-size: var(--qmt-checkbox-sm-supporting-font, 12px);
  line-height: 18px;
}

.qmt-toggle--md .qmt-toggle-desc {
  font-size: var(--qmt-checkbox-md-supporting-font, 14px);
  line-height: 20px;
}

.qmt-toggle-error {
  font-size: 12px;
  line-height: 16px;
  color: var(--qmt-checkbox-mark-error, #c10007);
}

.qmt-toggle-wrapper.is-disabled .qmt-toggle-label,
.qmt-toggle-wrapper.is-disabled .qmt-toggle-desc {
  color: var(--qmt-toggle-label-disabled, #a1a1a1);
}
</style>
