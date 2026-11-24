<!--
  Authoritative QMT BaseButton Component (Figma 4503:1152)
  =============================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Primary button standard across the entire ERP for all actions, forms, headers, and dialogs.
  - Hierarchy Variants:
    * `primary`: Brand blue `#0B529C` (`Save`, `Create Entity`). Note: Zero icons on top Save buttons!
    * `secondary-gray`: White background `#FFFFFF`, subtle border `#E5E5E5`, `#404040` text (Filter button, Sort button, Clear Form, Cancel).
    * `secondary-color`: Brand subtle `#E1EEFD` background with brand blue text.
    * `tertiary-gray`: Ghost button with `#737373` text, no border.
    * `error`: Destructive red `#E7000B` (`Delete`, `Reject`).
    * `success`: Emerald green `#009966` (`Approve`).

  WHEN NOT TO USE:
  - DO NOT style the Sort button as brand blue (Sort MUST ALWAYS use `secondary-gray`, identical to Filter).
  - DO NOT render bare inline action buttons (View, Edit, Delete) side-by-side in table rows (use 3-dot kebab menu instead).
-->
<script setup lang="ts">
import { computed } from 'vue';

export type QmtButtonHierarchy =
  | 'primary'
  | 'secondary-color'
  | 'secondary-gray'
  | 'secondary-gray-circle'
  | 'tertiary-color'
  | 'tertiary-gray'
  | 'success'
  | 'error'
  | 'warning';

export type LegacyButtonVariant =
  | 'secondary'
  | 'outline'
  | 'icon'
  | 'destructive'
  | 'ghost';

export type ButtonVariant = QmtButtonHierarchy | LegacyButtonVariant;
export type ButtonSize = 'xs' | 'sm' | 'md' | 'lg' | 'xl';

interface Props {
  variant?: ButtonVariant;
  size?: ButtonSize;
  iconOnly?: boolean;
  loading?: boolean;
  active?: boolean;
  disabled?: boolean;
  type?: 'button' | 'submit' | 'reset';
  title?: string;
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'md',
  iconOnly: false,
  loading: false,
  active: false,
  disabled: false,
  type: 'button',
  title: undefined
});

const emit = defineEmits<{
  (e: 'click', event: MouseEvent): void;
}>();

const VARIANT_ALIAS_MAP: Record<ButtonVariant, QmtButtonHierarchy> = {
  primary: 'primary',
  'secondary-color': 'secondary-color',
  'secondary-gray': 'secondary-gray',
  'secondary-gray-circle': 'secondary-gray-circle',
  'tertiary-color': 'tertiary-color',
  'tertiary-gray': 'tertiary-gray',
  success: 'success',
  error: 'error',
  warning: 'warning',
  secondary: 'secondary-gray',
  outline: 'secondary-gray',
  icon: 'secondary-gray',
  destructive: 'error',
  ghost: 'tertiary-gray'
};

const resolvedHierarchy = computed<QmtButtonHierarchy>(
  () => VARIANT_ALIAS_MAP[props.variant] ?? 'primary'
);

const isIconOnly = computed<boolean>(
  () => props.iconOnly || props.variant === 'icon' || props.variant === 'secondary-gray-circle'
);

const isInteractiveDisabled = computed<boolean>(() => props.disabled || props.loading);

const handleClick = (e: MouseEvent) => {
  if (!isInteractiveDisabled.value) {
    emit('click', e);
  }
};
</script>

<template>
  <button
    :type="props.type"
    :disabled="props.disabled"
    :aria-busy="props.loading || undefined"
    :aria-disabled="isInteractiveDisabled || undefined"
    :title="props.title"
    :class="[
      'base-button',
      'qmt-btn',
      `qmt-btn--${resolvedHierarchy}`,
      `btn-${props.variant}`,
      `btn-size-${props.size}`,
      `qmt-btn--${props.size}`,
      {
        'qmt-btn--icon-only': isIconOnly,
        'qmt-btn--loading': props.loading,
        'btn-active': props.active,
        'btn-disabled': props.disabled
      }
    ]"
    @click="handleClick"
  >
    <svg
      v-if="props.loading"
      class="qmt-btn__spinner"
      viewBox="0 0 20 20"
      fill="none"
      aria-hidden="true"
    >
      <circle
        class="qmt-btn__spinner-track"
        cx="10"
        cy="10"
        r="8"
        stroke="currentColor"
        stroke-width="2"
      />
      <path
        d="M10 2a8 8 0 0 1 8 8"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
      />
    </svg>
    <slot v-else name="icon-left" />
    <slot v-if="!isIconOnly" />
    <slot v-else-if="!props.loading" />
    <slot v-if="!isIconOnly" name="icon-right" />
  </button>
</template>

<style scoped>
.qmt-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--qmt-button-gap, 8px);
  border-radius: var(--qmt-button-radius, 8px);
  border-width: var(--qmt-button-border-width, 1px);
  border-style: solid;
  border-color: transparent;
  font-family: var(--qmt-font-family-sans, inherit);
  font-weight: var(--qmt-font-weight-semibold, 600);
  cursor: pointer;
  transition: background-color 0.15s ease, border-color 0.15s ease, color 0.15s ease, box-shadow 0.15s ease;
  user-select: none;
  white-space: nowrap;
  outline: none;
  text-decoration: none;
  box-sizing: border-box;
  line-height: var(--qmt-alias-line-height-sm, 20px);
}

.qmt-btn :deep(svg) {
  flex-shrink: 0;
}

/* SIZES (QMT Button 4503:1152) */
.qmt-btn--xs {
  height: var(--qmt-button-xs-height, 32px);
  padding: 0 var(--qmt-button-xs-padding-x, 12px);
  font-size: var(--qmt-alias-font-size-sm, 14px);
  line-height: var(--qmt-alias-line-height-sm, 20px);
}

.qmt-btn--sm {
  height: var(--qmt-button-sm-height, 36px);
  padding: 0 var(--qmt-button-sm-padding-x, 14px);
  font-size: var(--qmt-alias-font-size-sm, 14px);
  line-height: var(--qmt-alias-line-height-sm, 20px);
}

.qmt-btn--md {
  height: var(--qmt-button-md-height, 40px);
  padding: 0 var(--qmt-button-md-padding-x, 16px);
  font-size: var(--qmt-alias-font-size-sm, 14px);
  line-height: var(--qmt-alias-line-height-sm, 20px);
}

.qmt-btn--lg {
  height: var(--qmt-button-lg-height, 44px);
  padding: 0 var(--qmt-button-lg-padding-x, 18px);
  font-size: var(--qmt-alias-font-size-md, 16px);
  line-height: var(--qmt-alias-line-height-md, 24px);
}

.qmt-btn--xl {
  height: var(--qmt-button-xl-height, 48px);
  padding: 0 var(--qmt-button-xl-padding-x, 20px);
  font-size: var(--qmt-alias-font-size-md, 16px);
  line-height: var(--qmt-alias-line-height-md, 24px);
}

/* ICON-ONLY SIZES */
.qmt-btn--icon-only {
  padding: 0;
}

.qmt-btn--icon-only.qmt-btn--xs {
  width: var(--qmt-button-xs-icon-only-size, 28px);
  height: var(--qmt-button-xs-icon-only-size, 28px);
}

.qmt-btn--icon-only.qmt-btn--sm {
  width: var(--qmt-button-sm-icon-only-size, 32px);
  height: var(--qmt-button-sm-icon-only-size, 32px);
}

.qmt-btn--icon-only.qmt-btn--md {
  width: var(--qmt-button-md-icon-only-size, 36px);
  height: var(--qmt-button-md-icon-only-size, 36px);
}

.qmt-btn--icon-only.qmt-btn--lg {
  width: var(--qmt-button-lg-icon-only-size, 40px);
  height: var(--qmt-button-lg-icon-only-size, 40px);
}

.qmt-btn--icon-only.qmt-btn--xl {
  width: var(--qmt-button-xl-icon-only-size, 48px);
  height: var(--qmt-button-xl-icon-only-size, 48px);
}

/* PRIMARY */
.qmt-btn--primary {
  background-color: var(--qmt-button-primary-bg, #0b529c);
  border-color: var(--qmt-button-primary-border, #0b529c);
  color: var(--qmt-button-primary-fg, #ffffff);
  box-shadow: 0 1px 2px 0 var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

.qmt-btn--primary:hover:not(:disabled):not(.qmt-btn--loading) {
  background-color: var(--qmt-button-primary-bg-hover, #0d457f);
  border-color: var(--qmt-button-primary-border-hover, #0d457f);
}

.qmt-btn--primary:focus-visible:not(:disabled) {
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-brand, #e1eefd),
    0 1px 2px 0 var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

.qmt-btn--primary:disabled {
  background-color: var(--qmt-button-primary-bg-disabled, #f1f7fe);
  border-color: var(--qmt-button-primary-border-disabled, #e1eefd);
  color: var(--qmt-button-primary-fg-disabled, #83bff6);
}

/* SECONDARY COLOR */
.qmt-btn--secondary-color {
  background-color: var(--qmt-button-secondary-color-bg, #f1f7fe);
  border-color: var(--qmt-button-secondary-color-border, #bddbfa);
  color: var(--qmt-button-secondary-color-fg, #0b529c);
  box-shadow: 0 1px 2px 0 var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

.qmt-btn--secondary-color:hover:not(:disabled):not(.qmt-btn--loading) {
  background-color: var(--qmt-button-secondary-color-bg-hover, #e1eefd);
  border-color: var(--qmt-button-secondary-color-border-hover, #83bff6);
}

.qmt-btn--secondary-color:focus-visible:not(:disabled) {
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-brand, #e1eefd),
    0 1px 2px 0 var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

.qmt-btn--secondary-color:disabled {
  background-color: var(--qmt-button-secondary-color-bg-disabled, #f1f7fe);
  border-color: var(--qmt-button-secondary-color-border-disabled, #bddbfa);
  color: var(--qmt-button-secondary-color-fg-disabled, #83bff6);
}

/* SECONDARY GRAY (includes legacy secondary / outline / icon) */
.qmt-btn--secondary-gray {
  background-color: var(--qmt-button-secondary-gray-bg, #ffffff);
  border-color: var(--qmt-button-secondary-gray-border, #d4d4d4);
  color: var(--qmt-button-secondary-gray-fg, #404040);
  box-shadow: 0 1px 2px 0 var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

.qmt-btn--secondary-gray:hover:not(:disabled):not(.qmt-btn--loading) {
  background-color: var(--qmt-button-secondary-gray-bg-hover, #fafafa);
  border-color: var(--qmt-button-secondary-gray-border, #d4d4d4);
  color: var(--qmt-button-secondary-gray-fg-hover, #404040);
}

.qmt-btn--secondary-gray:focus-visible:not(:disabled) {
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-gray, #f5f5f5),
    0 1px 2px 0 var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

.qmt-btn--secondary-gray.btn-active {
  border-color: var(--qmt-button-primary-bg, #0b529c);
  background-color: var(--qmt-button-secondary-color-bg, #f1f7fe);
  color: var(--qmt-button-primary-bg, #0b529c);
}

.qmt-btn--secondary-gray:disabled {
  background-color: var(--qmt-button-secondary-gray-bg-disabled, #ffffff);
  border-color: var(--qmt-button-secondary-gray-border-disabled, #e5e5e5);
  color: var(--qmt-button-secondary-gray-fg-disabled, #a1a1a1);
}

/* SECONDARY GRAY CIRCLE */
.qmt-btn--secondary-gray-circle {
  border-radius: var(--qmt-button-radius-circle, 9999px);
  background-color: var(--qmt-button-secondary-gray-circle-bg, #ffffff);
  border-color: transparent;
  color: var(--qmt-button-secondary-gray-circle-icon, #737373);
}

.qmt-btn--secondary-gray-circle:hover:not(:disabled):not(.qmt-btn--loading) {
  background-color: var(--qmt-button-secondary-gray-circle-bg-hover, #f5f5f5);
  color: var(--qmt-button-secondary-gray-circle-icon-hover, #404040);
  box-shadow: 0 1px 2px 0 var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

.qmt-btn--secondary-gray-circle:focus-visible:not(:disabled) {
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-gray, #f5f5f5),
    0 1px 2px 0 var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

.qmt-btn--secondary-gray-circle.btn-active {
  background-color: var(--qmt-button-secondary-color-bg, #f1f7fe);
  color: var(--qmt-button-primary-bg, #0b529c);
}

.qmt-btn--secondary-gray-circle:disabled {
  background-color: var(--qmt-button-secondary-gray-circle-bg-disabled, #ffffff);
  color: var(--qmt-button-secondary-gray-circle-icon-disabled, #a1a1a1);
}

/* TERTIARY COLOR */
.qmt-btn--tertiary-color {
  background-color: transparent;
  border-color: transparent;
  color: var(--qmt-button-tertiary-color-fg, #0b529c);
  box-shadow: none;
}

.qmt-btn--tertiary-color:hover:not(:disabled):not(.qmt-btn--loading) {
  background-color: var(--qmt-button-tertiary-color-bg-hover, #f1f7fe);
}

.qmt-btn--tertiary-color:focus-visible:not(:disabled) {
  box-shadow: 0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-brand, #e1eefd);
}

.qmt-btn--tertiary-color:disabled {
  color: var(--qmt-button-tertiary-color-fg-disabled, #bddbfa);
}

/* TERTIARY GRAY (includes legacy ghost) */
.qmt-btn--tertiary-gray {
  background-color: transparent;
  border-color: transparent;
  color: var(--qmt-button-tertiary-gray-fg, #404040);
  box-shadow: none;
}

.qmt-btn--tertiary-gray:hover:not(:disabled):not(.qmt-btn--loading) {
  background-color: var(--qmt-button-tertiary-gray-bg-hover, #f5f5f5);
  color: var(--qmt-button-tertiary-gray-fg-hover, #404040);
}

.qmt-btn--tertiary-gray:focus-visible:not(:disabled) {
  box-shadow: 0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-gray, #f5f5f5);
}

.qmt-btn--tertiary-gray:disabled {
  color: var(--qmt-button-tertiary-gray-fg-disabled, #a1a1a1);
}

/* SUCCESS (QMT Button node 4503:1508) */
.qmt-btn--success {
  background-color: var(--qmt-button-success-bg, #00bc7d);
  border-color: var(--qmt-button-success-border, #5ee9b5);
  color: var(--qmt-button-success-fg, #ffffff);
  box-shadow: 0 1px 2px 0 var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

.qmt-btn--success:hover:not(:disabled):not(.qmt-btn--loading) {
  background-color: var(--qmt-button-success-bg-hover, #009966);
  border-color: var(--qmt-button-success-border, #5ee9b5);
}

.qmt-btn--success:focus-visible:not(:disabled) {
  background-color: var(--qmt-button-success-bg-focus, #009966);
  border-color: var(--qmt-button-success-border, #5ee9b5);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-success, #d0fae5),
    0 1px 2px 0 var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

.qmt-btn--success:disabled {
  background-color: var(--qmt-button-success-bg-disabled, #ecfdf5);
  border-color: var(--qmt-button-success-border-disabled, #d0fae5);
  color: var(--qmt-button-success-fg-disabled, #5ee9b5);
}

/* ERROR (includes legacy destructive) */
.qmt-btn--error {
  background-color: var(--qmt-button-error-bg, #fb2c36);
  border-color: var(--qmt-button-error-border, #ffa2a2);
  color: var(--qmt-button-error-fg, #ffffff);
  box-shadow: 0 1px 2px 0 var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

.qmt-btn--error:hover:not(:disabled):not(.qmt-btn--loading) {
  background-color: var(--qmt-button-error-bg-hover, #e7000b);
  border-color: var(--qmt-button-error-border, #ffa2a2);
}

.qmt-btn--error:focus-visible:not(:disabled) {
  background-color: var(--qmt-button-error-bg-focus, #e7000b);
  border-color: var(--qmt-button-error-border-focus, #ffa2a2);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-error, #ffe2e2),
    0 1px 2px 0 var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

.qmt-btn--error:disabled {
  background-color: var(--qmt-button-error-bg-disabled, #fef2f2);
  border-color: var(--qmt-button-error-border-disabled, #ffe2e2);
  color: var(--qmt-button-error-fg-disabled, #ffa2a2);
}

/* WARNING */
.qmt-btn--warning {
  background-color: var(--qmt-button-warning-bg, #fe9a00);
  border-color: var(--qmt-button-warning-border, #ffd230);
  color: var(--qmt-button-warning-fg, #ffffff);
  box-shadow: 0 1px 2px 0 var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

.qmt-btn--warning:hover:not(:disabled):not(.qmt-btn--loading) {
  background-color: var(--qmt-button-warning-bg-hover, #e17100);
  border-color: var(--qmt-button-warning-border, #ffd230);
}

.qmt-btn--warning:focus-visible:not(:disabled) {
  background-color: var(--qmt-button-warning-bg-focus, #e17100);
  border-color: var(--qmt-button-warning-border, #ffd230);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-warning, #fef3c6),
    0 1px 2px 0 var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

.qmt-btn--warning:disabled {
  background-color: var(--qmt-button-warning-bg-disabled, #fffbeb);
  border-color: var(--qmt-button-warning-border-disabled, #fef3c6);
  color: var(--qmt-button-warning-fg-disabled, #ffd230);
}

/* SPINNER (QMT _Spinner 5041:26121: 20x20, 30% track + quarter arc, 800ms loop) */
.qmt-btn__spinner {
  width: 20px;
  height: 20px;
  animation: qmt-btn-spin 800ms linear infinite;
}

.qmt-btn--icon-only.qmt-btn--xs .qmt-btn__spinner {
  width: var(--qmt-button-xs-icon-only-icon-size, 12px);
  height: var(--qmt-button-xs-icon-only-icon-size, 12px);
}

.qmt-btn--icon-only.qmt-btn--sm .qmt-btn__spinner {
  width: var(--qmt-button-sm-icon-only-icon-size, 16px);
  height: var(--qmt-button-sm-icon-only-icon-size, 16px);
}

.qmt-btn--icon-only.qmt-btn--lg .qmt-btn__spinner,
.qmt-btn--icon-only.qmt-btn--xl .qmt-btn__spinner {
  width: var(--qmt-button-lg-icon-only-icon-size, 24px);
  height: var(--qmt-button-lg-icon-only-icon-size, 24px);
}

.qmt-btn__spinner-track {
  opacity: var(--qmt-button-spinner-track-opacity, 0.3);
}

@keyframes qmt-btn-spin {
  to {
    transform: rotate(360deg);
  }
}

/* LOADING & DISABLED STATES */
.qmt-btn--loading {
  cursor: wait;
  pointer-events: none;
}

.btn-disabled,
.qmt-btn:disabled {
  cursor: not-allowed;
  pointer-events: none;
}
</style>
