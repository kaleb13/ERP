<script setup lang="ts">
import { computed } from 'vue';

interface Props {
  variant?: 'primary' | 'secondary' | 'outline' | 'icon' | 'destructive' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  active?: boolean;
  disabled?: boolean;
  type?: 'button' | 'submit' | 'reset';
  title?: string;
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'md',
  active: false,
  disabled: false,
  type: 'button',
  title: undefined
});

const emit = defineEmits<{
  (e: 'click', event: MouseEvent): void;
}>();

const handleClick = (e: MouseEvent) => {
  if (!props.disabled) {
    emit('click', e);
  }
};
</script>

<template>
  <button
    :type="props.type"
    :disabled="props.disabled"
    :title="props.title"
    :class="[
      'base-button',
      `btn-${props.variant}`,
      `btn-size-${props.size}`,
      { 'btn-active': props.active, 'btn-disabled': props.disabled }
    ]"
    @click="handleClick"
  >
    <slot name="icon-left" />
    <slot />
    <slot name="icon-right" />
  </button>
</template>

<style scoped>
.base-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border-radius: 10px;
  font-family: inherit;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
  user-select: none;
  white-space: nowrap;
  outline: none;
  text-decoration: none;
}

/* SIZES */
.btn-size-sm {
  height: 34px;
  padding: 0 12px;
  font-size: 12.5px;
}

.btn-size-md {
  height: 40px;
  padding: 0 16px;
  font-size: 13.5px;
}

.btn-size-lg {
  height: 44px;
  padding: 0 20px;
  font-size: 14px;
}

/* PRIMARY BUTTON (Brand Blue #0B529C) */
.btn-primary {
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  font-weight: 600;
  box-shadow: 0 1px 2px rgba(11, 82, 156, 0.15);
}

.btn-primary:hover:not(:disabled) {
  background-color: #09427D;
  box-shadow: 0 3px 6px rgba(11, 82, 156, 0.25);
  transform: translateY(-0.5px);
}

.btn-primary:active:not(:disabled) {
  transform: translateY(0);
}

/* SECONDARY / OUTLINE BUTTON (White surface, #e2e8f0 border) */
.btn-secondary,
.btn-outline {
  background-color: #ffffff;
  color: #334155;
  border: 1px solid #e2e8f0;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
}

.btn-secondary:hover:not(:disabled),
.btn-outline:hover:not(:disabled) {
  background-color: #f8fafc;
  border-color: #cbd5e1;
  color: #0f172a;
}

.btn-secondary.btn-active,
.btn-outline.btn-active {
  border-color: #0B529C;
  background-color: #eff6ff;
  color: #0B529C;
}

/* ICON BUTTON (Square 38px/40px icon toggle) */
.btn-icon {
  width: 40px;
  height: 40px;
  padding: 0;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  color: #64748b;
  border-radius: 10px;
}

.btn-icon.btn-size-sm {
  width: 34px;
  height: 34px;
  border-radius: 8px;
}

.btn-icon:hover:not(:disabled) {
  background-color: #f8fafc;
  border-color: #cbd5e1;
  color: #0f172a;
}

.btn-icon.btn-active {
  border-color: #0B529C;
  background-color: #eff6ff;
  color: #0B529C;
}

/* DESTRUCTIVE BUTTON */
.btn-destructive {
  background-color: #ef4444;
  color: #ffffff;
  border: none;
  font-weight: 600;
}

.btn-destructive:hover:not(:disabled) {
  background-color: #dc2626;
}

/* GHOST BUTTON */
.btn-ghost {
  background-color: transparent;
  color: #64748b;
  border: none;
}

.btn-ghost:hover:not(:disabled) {
  background-color: #f1f5f9;
  color: #0f172a;
}

/* DISABLED STATE */
.btn-disabled,
.base-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  pointer-events: none;
  box-shadow: none;
  transform: none !important;
}
</style>
