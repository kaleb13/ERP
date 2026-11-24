<!--
  Authoritative QMT BaseBadge Component (Figma 3345:21147)
  ============================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Primary badge component across all tables, cards, drawers, and headers.
  - Used for table Status columns, State columns (`active` / `inactive`), lifecycle states, and salient category tags.
  - Supports types: `pill-color` (default), `solid`, `modern`.
  - Supports dot indicator (`:dot="true"`), leading/trailing icons, and close button (`:closable="true"`).

  MANDATORY CONTRACT RULES:
  - ALWAYS pass color via `:color="..."` (NEVER `:variant="..."`, which causes monochrome fallback).
  - Valid semantic colors:
    * `success`: Active lifecycle state, approved governance, completed (`#009966`).
    * `gray`: STRICTLY reserved for Inactive / Dormant states (`state === 'inactive'`).
    * `indigo`: Statutory policy rules, mandatory compliance, legal enforcement.
    * `blue`: Permissive alternatives, secondary scopes, informational options.
    * `purple`: Specialized operational modes or classifications.
    * `warning`: Pending review, cautionary thresholds.
    * `error`: Rejected, failed, strict breach.
    * `primary`: Brand blue anchor (`#0B529C`).

  WHEN NOT TO USE:
  - NEVER use `gray` for active functional lookups (e.g. `Permissive`), because it makes active records look inactive/dead.
  - NEVER construct raw `<span class="status-pill">` or `<span class="status-dot">` tags.
  - DO NOT use for long compound notifications with action arrows (use `BadgeGroup.vue` instead).
-->
<script setup lang="ts">
import { computed, useSlots } from 'vue';
import { X } from 'lucide-vue-next';

export type BadgeType =
  | 'pill-color'
  | 'color'
  | 'modern'
  | 'solid'
  | 'gradient'
  | 'gradient-outline';

export type BadgeColor =
  | 'primary'
  | 'brand'
  | 'gray'
  | 'error'
  | 'warning'
  | 'success'
  | 'blue'
  | 'indigo'
  | 'purple'
  | 'pink'
  | 'orange'
  | 'ocean'
  | 'sunset';

export type BadgeSize = 'sm' | 'md' | 'lg';

const props = withDefaults(
  defineProps<{
    type?: BadgeType;
    color?: BadgeColor;
    size?: BadgeSize;
    dot?: boolean;
    closable?: boolean;
    iconOnly?: boolean;
  }>(),
  {
    type: 'pill-color',
    color: 'gray',
    size: 'sm',
    dot: false,
    closable: false,
    iconOnly: false,
  }
);

const emit = defineEmits<{
  (e: 'close'): void;
}>();

const slots = useSlots();

const resolvedColor = computed(() => {
  if (props.color === 'brand') return 'primary';
  return props.color;
});

const hasLeadingDecorator = computed(
  () => props.dot || Boolean(slots['icon-left']) || Boolean(slots.avatar)
);

const hasTrailingDecorator = computed(
  () => props.closable || Boolean(slots['icon-right'])
);

const badgeClasses = computed(() => [
  'qmt-badge',
  `qmt-badge--type-${props.type}`,
  `qmt-badge--color-${resolvedColor.value}`,
  `qmt-badge--size-${props.size}`,
  {
    'qmt-badge--has-leading': hasLeadingDecorator.value && !props.iconOnly,
    'qmt-badge--has-trailing': hasTrailingDecorator.value && !props.iconOnly,
    'qmt-badge--has-dot': props.dot && !props.iconOnly,
    'qmt-badge--icon-only': props.iconOnly,
  },
]);
</script>

<template>
  <span :class="badgeClasses">
    <slot name="avatar" />
    <span v-if="dot && !iconOnly" class="qmt-badge__dot" aria-hidden="true" />
    <span v-if="$slots['icon-left']" class="qmt-badge__icon">
      <slot name="icon-left" />
    </span>
    <span v-if="!iconOnly" class="qmt-badge__label">
      <slot />
    </span>
    <span v-if="$slots['icon-right'] && !iconOnly" class="qmt-badge__icon">
      <slot name="icon-right" />
    </span>
    <button
      v-if="closable && !iconOnly"
      type="button"
      class="qmt-badge__close"
      aria-label="Remove"
      @click.stop="emit('close')"
    >
      <X :size="12" stroke-width="2.2" />
    </button>
  </span>
</template>

<style scoped>
.qmt-badge {
  --_badge-bg: var(--qmt-badge-gray-bg);
  --_badge-fg: var(--qmt-badge-gray-fg);
  --_badge-icon: var(--qmt-badge-gray-icon);
  --_badge-border: transparent;
  --_badge-radius: var(--qmt-badge-radius-pill);
  --_badge-gap: var(--qmt-badge-gap-icon);

  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--_badge-gap);
  font-family: var(--qmt-font-family-sans);
  font-weight: var(--qmt-font-weight-semibold);
  white-space: nowrap;
  vertical-align: middle;
  border-radius: var(--_badge-radius);
  background-color: var(--_badge-bg);
  color: var(--_badge-fg);
  border: var(--qmt-badge-border-width) solid var(--_badge-border);
  line-height: var(--qmt-alias-line-height-xs);
  box-sizing: border-box;
  flex-shrink: 0;
}

/* Sizes (QMT Figma Badge 3345:21147) */
.qmt-badge--size-sm {
  font-size: var(--qmt-alias-font-size-xs);
  line-height: var(--qmt-alias-line-height-xs);
  padding: var(--qmt-badge-sm-padding-y) var(--qmt-badge-sm-padding-x);
}

.qmt-badge--size-sm.qmt-badge--has-leading {
  padding-left: var(--qmt-badge-sm-padding-x-icon);
}

.qmt-badge--size-sm.qmt-badge--has-trailing {
  padding-right: var(--qmt-badge-sm-padding-x-icon);
}

.qmt-badge--size-md {
  font-size: var(--qmt-alias-font-size-sm);
  line-height: var(--qmt-alias-line-height-sm);
  padding: var(--qmt-badge-md-padding-y) var(--qmt-badge-md-padding-x);
}

.qmt-badge--size-md.qmt-badge--has-leading {
  padding-left: var(--qmt-badge-md-padding-x-icon);
}

.qmt-badge--size-md.qmt-badge--has-trailing {
  padding-right: var(--qmt-badge-md-padding-x-icon);
}

.qmt-badge--size-lg {
  font-size: var(--qmt-alias-font-size-sm);
  line-height: var(--qmt-alias-line-height-sm);
  padding: var(--qmt-badge-lg-padding-y) var(--qmt-badge-lg-padding-x);
}

.qmt-badge--size-lg.qmt-badge--has-leading {
  padding-left: var(--qmt-badge-lg-padding-x-icon);
}

.qmt-badge--size-lg.qmt-badge--has-trailing {
  padding-right: var(--qmt-badge-lg-padding-x-icon);
}

.qmt-badge--has-dot {
  --_badge-gap: var(--qmt-badge-gap-dot);
}

.qmt-badge--icon-only.qmt-badge--size-sm {
  width: 20px;
  height: 20px;
  padding: 0;
}

.qmt-badge--icon-only.qmt-badge--size-md {
  width: 22px;
  height: 22px;
  padding: 0;
}

.qmt-badge--icon-only.qmt-badge--size-lg {
  width: 24px;
  height: 24px;
  padding: 0;
}

/* Shapes */
.qmt-badge--type-color,
.qmt-badge--type-modern {
  --_badge-radius: var(--qmt-badge-radius-color);
}

.qmt-badge--type-modern {
  --_badge-bg: var(--qmt-badge-modern-bg);
  --_badge-fg: var(--qmt-badge-modern-fg);
  --_badge-border: var(--qmt-badge-modern-border);
  box-shadow: 0 1px 2px 0 var(--qmt-color-shadow-faint);
}

/* Color palettes for Pill color & Color (& dot/icon tint for Modern) */
.qmt-badge--color-primary {
  --_badge-bg: var(--qmt-badge-brand-bg);
  --_badge-fg: var(--qmt-badge-brand-fg);
  --_badge-icon: var(--qmt-badge-brand-icon);
}

.qmt-badge--color-gray {
  --_badge-bg: var(--qmt-badge-gray-bg);
  --_badge-fg: var(--qmt-badge-gray-fg);
  --_badge-icon: var(--qmt-badge-gray-icon);
}

.qmt-badge--color-error {
  --_badge-bg: var(--qmt-badge-error-bg);
  --_badge-fg: var(--qmt-badge-error-fg);
  --_badge-icon: var(--qmt-badge-error-icon);
}

.qmt-badge--color-warning {
  --_badge-bg: var(--qmt-badge-warning-bg);
  --_badge-fg: var(--qmt-badge-warning-fg);
  --_badge-icon: var(--qmt-badge-warning-icon);
}

.qmt-badge--color-success {
  --_badge-bg: var(--qmt-badge-success-bg);
  --_badge-fg: var(--qmt-badge-success-fg);
  --_badge-icon: var(--qmt-badge-success-icon);
}

.qmt-badge--color-blue {
  --_badge-bg: var(--qmt-badge-blue-bg);
  --_badge-fg: var(--qmt-badge-blue-fg);
  --_badge-icon: var(--qmt-badge-blue-icon);
}

.qmt-badge--color-indigo {
  --_badge-bg: var(--qmt-badge-indigo-bg);
  --_badge-fg: var(--qmt-badge-indigo-fg);
  --_badge-icon: var(--qmt-badge-indigo-icon);
}

.qmt-badge--color-purple {
  --_badge-bg: var(--qmt-badge-purple-bg);
  --_badge-fg: var(--qmt-badge-purple-fg);
  --_badge-icon: var(--qmt-badge-purple-icon);
}

.qmt-badge--color-pink {
  --_badge-bg: var(--qmt-badge-pink-bg);
  --_badge-fg: var(--qmt-badge-pink-fg);
  --_badge-icon: var(--qmt-badge-pink-icon);
}

.qmt-badge--color-orange {
  --_badge-bg: var(--qmt-badge-orange-bg);
  --_badge-fg: var(--qmt-badge-orange-fg);
  --_badge-icon: var(--qmt-badge-orange-icon);
}

/* Re-apply neutral modern surface & fg while preserving semantic dot/icon tint */
.qmt-badge--type-modern {
  --_badge-bg: var(--qmt-badge-modern-bg);
  --_badge-fg: var(--qmt-badge-modern-fg);
}

/* Type: Solid */
.qmt-badge--type-solid.qmt-badge--color-primary {
  --_badge-bg: var(--qmt-badge-solid-brand-bg);
  --_badge-fg: var(--qmt-badge-solid-brand-fg);
  --_badge-icon: var(--qmt-badge-solid-brand-fg);
}

.qmt-badge--type-solid.qmt-badge--color-gray {
  --_badge-bg: var(--qmt-badge-solid-gray-bg);
  --_badge-fg: var(--qmt-badge-solid-gray-fg);
  --_badge-icon: var(--qmt-badge-solid-gray-fg);
}

.qmt-badge--type-solid.qmt-badge--color-error {
  --_badge-bg: var(--qmt-badge-solid-error-bg);
  --_badge-fg: var(--qmt-badge-solid-error-fg);
  --_badge-icon: var(--qmt-badge-solid-error-fg);
}

.qmt-badge--type-solid.qmt-badge--color-warning {
  --_badge-bg: var(--qmt-badge-solid-warning-bg);
  --_badge-fg: var(--qmt-badge-solid-warning-fg);
  --_badge-icon: var(--qmt-badge-solid-warning-fg);
}

.qmt-badge--type-solid.qmt-badge--color-success {
  --_badge-bg: var(--qmt-badge-solid-success-bg);
  --_badge-fg: var(--qmt-badge-solid-success-fg);
  --_badge-icon: var(--qmt-badge-solid-success-fg);
}

.qmt-badge--type-solid.qmt-badge--color-blue {
  --_badge-bg: var(--qmt-badge-blue-fg);
  --_badge-fg: var(--qmt-badge-gradient-fg);
  --_badge-icon: var(--qmt-badge-gradient-fg);
}

.qmt-badge--type-solid.qmt-badge--color-indigo {
  --_badge-bg: var(--qmt-badge-solid-indigo-bg);
  --_badge-fg: var(--qmt-badge-solid-indigo-fg);
  --_badge-icon: var(--qmt-badge-solid-indigo-fg);
}

.qmt-badge--type-solid.qmt-badge--color-purple {
  --_badge-bg: var(--qmt-badge-solid-purple-bg);
  --_badge-fg: var(--qmt-badge-solid-purple-fg);
  --_badge-icon: var(--qmt-badge-solid-purple-fg);
}

.qmt-badge--type-solid.qmt-badge--color-pink {
  --_badge-bg: var(--qmt-badge-solid-pink-bg);
  --_badge-fg: var(--qmt-badge-solid-pink-fg);
  --_badge-icon: var(--qmt-badge-solid-pink-fg);
}

.qmt-badge--type-solid.qmt-badge--color-orange {
  --_badge-bg: var(--qmt-badge-orange-fg);
  --_badge-fg: var(--qmt-badge-gradient-fg);
  --_badge-icon: var(--qmt-badge-gradient-fg);
}

/* Type: Gradient */
.qmt-badge--type-gradient {
  --_badge-fg: var(--qmt-badge-gradient-fg);
  --_badge-icon: var(--qmt-badge-gradient-fg);
}

.qmt-badge--type-gradient.qmt-badge--color-primary {
  background-image: linear-gradient(
    90deg,
    var(--qmt-badge-gradient-brand-start),
    var(--qmt-badge-gradient-brand-end)
  );
}

.qmt-badge--type-gradient.qmt-badge--color-ocean {
  background-image: linear-gradient(
    90deg,
    var(--qmt-badge-gradient-ocean-start),
    var(--qmt-badge-gradient-ocean-end)
  );
}

.qmt-badge--type-gradient.qmt-badge--color-sunset {
  background-image: linear-gradient(
    90deg,
    var(--qmt-badge-gradient-sunset-start),
    var(--qmt-badge-gradient-sunset-end)
  );
}

/* Type: Gradient outline */
.qmt-badge--type-gradient-outline {
  --_badge-bg: var(--qmt-badge-gradient-outline-bg);
}

.qmt-badge--type-gradient-outline.qmt-badge--color-primary {
  --_badge-fg: var(--qmt-badge-gradient-brand-text);
  --_badge-icon: var(--qmt-badge-gradient-brand-text);
  --_badge-border: var(--qmt-badge-gradient-brand-start);
}

.qmt-badge--type-gradient-outline.qmt-badge--color-ocean {
  --_badge-fg: var(--qmt-badge-gradient-ocean-text);
  --_badge-icon: var(--qmt-badge-gradient-ocean-text);
  --_badge-border: var(--qmt-badge-gradient-ocean-start);
}

.qmt-badge--type-gradient-outline.qmt-badge--color-sunset {
  --_badge-fg: var(--qmt-badge-gradient-sunset-text);
  --_badge-icon: var(--qmt-badge-gradient-sunset-text);
  --_badge-border: var(--qmt-badge-gradient-sunset-start);
}

/* Sub-elements */
.qmt-badge__dot {
  width: 6px;
  height: 6px;
  border-radius: var(--qmt-badge-radius-pill);
  background-color: var(--_badge-icon);
  flex-shrink: 0;
}

.qmt-badge__icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--_badge-icon);
  flex-shrink: 0;
}

.qmt-badge__label {
  display: inline-block;
  line-height: inherit;
}

.qmt-badge__close {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  margin: 0;
  border: none;
  background: transparent;
  color: var(--_badge-icon);
  cursor: pointer;
  border-radius: var(--qmt-badge-radius-pill);
  opacity: 0.85;
  transition: opacity 0.15s ease;
}

.qmt-badge__close:hover {
  opacity: 1;
}
</style>
