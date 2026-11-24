<!--
  Authoritative QMT BaseToast Component (Figma 4055:37)
  ======================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Platform-wide feedback toasts for user actions (create, edit, delete, status change, errors).
  - Typically dispatched via the centralized `useToast()` composable and rendered globally by `<BaseToaster />`:
      import { useToast } from '../../composables/useToast';
      const { toast } = useToast();
      toast.success('Saved successfully', 'Record has been persisted.');
  - Supports types: `flat` (default surface with colored icon & border) and `solid` (prominent colored background).
  - Supports statuses: `success`, `error`, `warning`, `info`, `loading`.

  WHEN NOT TO USE:
  - NEVER construct inline, in-page `.toast-bar` banners or custom transition alert divs that push page layouts.
  - DO NOT use for form field validation errors (use `error` prop on `FormInput` / `FormSelect`).
-->
<script setup lang="ts">
import { computed } from 'vue';
import {
  AlertCircle,
  AlertTriangle,
  CheckCircle2,
  Info,
  Loader2,
  X
} from 'lucide-vue-next';

export type ToastType = 'flat' | 'solid';
export type ToastStatus = 'default' | 'success' | 'error' | 'warning' | 'info' | 'loading';

const props = withDefaults(
  defineProps<{
    type?: ToastType;
    status?: ToastStatus;
    title: string;
    description?: string;
    showClose?: boolean;
    actionLabel?: string;
    cancelLabel?: string;
  }>(),
  {
    type: 'flat',
    status: 'default',
    description: '',
    showClose: true,
    actionLabel: '',
    cancelLabel: ''
  }
);

const emit = defineEmits<{
  (e: 'close'): void;
  (e: 'action'): void;
  (e: 'cancel'): void;
}>();

const statusIcon = computed(() => {
  switch (props.status) {
    case 'success':
      return CheckCircle2;
    case 'error':
      return AlertCircle;
    case 'warning':
      return AlertTriangle;
    case 'loading':
      return Loader2;
    case 'info':
    case 'default':
    default:
      return Info;
  }
});

const toastClasses = computed(() => [
  'qmt-toast',
  `qmt-toast--type-${props.type}`,
  `qmt-toast--status-${props.status}`
]);
</script>

<template>
  <div :class="toastClasses" role="status" aria-live="polite">
    <div class="qmt-toast__icon-wrap">
      <component
        :is="statusIcon"
        :size="16"
        class="qmt-toast__icon"
        :class="{ 'animate-spin': status === 'loading' }"
        aria-hidden="true"
      />
    </div>

    <div class="qmt-toast__content">
      <div class="qmt-toast__text">
        <p class="qmt-toast__title">{{ title }}</p>
        <p v-if="description" class="qmt-toast__description">{{ description }}</p>
      </div>

      <div v-if="actionLabel || cancelLabel" class="qmt-toast__actions">
        <button
          v-if="actionLabel"
          type="button"
          class="qmt-toast__action-btn"
          @click="emit('action')"
        >
          {{ actionLabel }}
        </button>
        <button
          v-if="cancelLabel"
          type="button"
          class="qmt-toast__cancel-btn"
          @click="emit('cancel')"
        >
          {{ cancelLabel }}
        </button>
      </div>
    </div>

    <button
      v-if="showClose"
      type="button"
      class="qmt-toast__close"
      aria-label="Close notification"
      @click="emit('close')"
    >
      <X :size="12" stroke-width="2.2" />
    </button>
  </div>
</template>

<style scoped>
.qmt-toast {
  --_toast-bg: var(--qmt-toast-bg, #ffffff);
  --_toast-title-fg: var(--qmt-toast-title-fg, #404040);
  --_toast-desc-fg: var(--qmt-toast-description-fg, #737373);
  --_toast-icon-fg: var(--qmt-toast-icon-default, #737373);
  --_toast-accent: var(--qmt-toast-accent-default, #d4d4d4);
  --_toast-border: var(--qmt-toast-border-subtle, #e5e5e5);
  --_toast-close-fg: var(--qmt-toast-icon-default, #737373);

  display: flex;
  align-items: flex-start;
  gap: var(--qmt-toast-gap, 8px);
  width: 380px;
  max-width: calc(100vw - 32px);
  padding: var(--qmt-toast-padding, 16px);
  border-radius: var(--qmt-toast-radius, 8px);
  background-color: var(--_toast-bg);
  font-family: var(--qmt-font-family-sans);
  box-shadow:
    0 4px 6px -1px rgba(10, 13, 18, 0.08),
    0 2px 4px -2px rgba(10, 13, 18, 0.05);
  box-sizing: border-box;
}

/* Type: Flat (White card with 3px colored left accent) */
.qmt-toast--type-flat {
  border: 1px solid var(--_toast-border);
  border-left: 3px solid var(--_toast-accent);
}

.qmt-toast--type-flat.qmt-toast--status-default,
.qmt-toast--type-flat.qmt-toast--status-loading {
  --_toast-icon-fg: var(--qmt-toast-icon-default, #737373);
  --_toast-accent: var(--qmt-toast-accent-default, #d4d4d4);
}

.qmt-toast--type-flat.qmt-toast--status-success {
  --_toast-icon-fg: var(--qmt-toast-icon-success, #009966);
  --_toast-accent: var(--qmt-toast-accent-success, #5ee9b5);
}

.qmt-toast--type-flat.qmt-toast--status-error {
  --_toast-icon-fg: var(--qmt-toast-icon-error, #e7000b);
  --_toast-accent: var(--qmt-toast-accent-error, #ffa2a2);
}

.qmt-toast--type-flat.qmt-toast--status-warning {
  --_toast-icon-fg: var(--qmt-toast-icon-warning, #e17100);
  --_toast-accent: var(--qmt-toast-accent-warning, #ffd230);
}

.qmt-toast--type-flat.qmt-toast--status-info {
  --_toast-icon-fg: var(--qmt-toast-icon-info, #0084d1);
  --_toast-accent: var(--qmt-toast-accent-info, #74d4ff);
}

/* Type: Solid (Status fill with white text) */
.qmt-toast--type-solid {
  border: none;
  --_toast-title-fg: var(--qmt-toast-solid-fg, #ffffff);
  --_toast-desc-fg: rgba(255, 255, 255, 0.88);
  --_toast-icon-fg: var(--qmt-toast-solid-icon, #ffffff);
  --_toast-close-fg: var(--qmt-toast-solid-icon, #ffffff);
}

.qmt-toast--type-solid.qmt-toast--status-default,
.qmt-toast--type-solid.qmt-toast--status-loading {
  --_toast-bg: var(--qmt-toast-solid-bg-default, #171717);
  --_toast-title-fg: var(--qmt-toast-solid-fg-default, #f5f5f5);
  --_toast-icon-fg: var(--qmt-toast-solid-icon-default, #f5f5f5);
  --_toast-close-fg: var(--qmt-toast-solid-icon-default, #f5f5f5);
}

.qmt-toast--type-solid.qmt-toast--status-success {
  --_toast-bg: var(--qmt-toast-solid-bg-success, #007a55);
}

.qmt-toast--type-solid.qmt-toast--status-error {
  --_toast-bg: var(--qmt-toast-solid-bg-error, #c10007);
}

.qmt-toast--type-solid.qmt-toast--status-warning {
  --_toast-bg: var(--qmt-toast-solid-bg-warning, #bb4d00);
}

.qmt-toast--type-solid.qmt-toast--status-info {
  --_toast-bg: var(--qmt-toast-solid-bg-info, #0069a8);
}

.qmt-toast__icon-wrap {
  display: flex;
  align-items: flex-start;
  padding-top: 2px;
  flex-shrink: 0;
}

.qmt-toast__icon {
  color: var(--_toast-icon-fg);
}

.qmt-toast__content {
  display: flex;
  flex: 1 0 0;
  flex-direction: column;
  gap: var(--qmt-toast-text-gap, 4px);
  min-width: 0;
}

.qmt-toast__text {
  display: flex;
  flex-direction: column;
  gap: var(--qmt-toast-text-gap, 4px);
  word-break: break-word;
}

.qmt-toast__title {
  margin: 0;
  font-size: var(--qmt-alias-font-size-sm, 14px);
  line-height: var(--qmt-alias-line-height-sm, 20px);
  font-weight: 500;
  color: var(--_toast-title-fg);
}

.qmt-toast__description {
  margin: 0;
  font-size: var(--qmt-alias-font-size-xs, 12px);
  line-height: var(--qmt-alias-line-height-xs, 18px);
  font-weight: 400;
  color: var(--_toast-desc-fg);
}

.qmt-toast__actions {
  display: flex;
  align-items: center;
  gap: var(--qmt-toast-actions-gap, 8px);
  padding-top: var(--qmt-toast-text-gap, 4px);
}

.qmt-toast__action-btn {
  height: 32px;
  padding: 0 12px;
  border-radius: var(--qmt-button-radius, 8px);
  border: 1px solid #d4d4d4;
  background-color: #ffffff;
  color: #404040;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}

.qmt-toast__cancel-btn {
  height: 32px;
  padding: 0 10px;
  border: none;
  background: transparent;
  color: var(--_toast-desc-fg);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}

.qmt-toast__close {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 22px;
  height: 22px;
  border-radius: 9999px;
  border: none;
  background: transparent;
  color: var(--_toast-close-fg);
  cursor: pointer;
  flex-shrink: 0;
  opacity: 0.8;
  transition: opacity 0.15s ease, background-color 0.15s ease;
}

.qmt-toast__close:hover {
  opacity: 1;
  background-color: rgba(115, 115, 115, 0.12);
}

.qmt-toast--type-solid .qmt-toast__close:hover {
  background-color: rgba(255, 255, 255, 0.18);
}
</style>
