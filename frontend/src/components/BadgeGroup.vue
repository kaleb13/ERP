<!--
  Authoritative QMT BadgeGroup Component (Figma 5221:28673)
  ==============================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Compound notifications and longer informational badges across the platform:
    e.g., System notices, feature announcements, live metric highlights, sync summaries,
    and inventory notices (e.g. `StockSummary.vue`).
  - Houses an inner `BaseBadge` pill, descriptive message text, and an optional action arrow (`ArrowRight`).
  - Can be interactive (`clickable: true` or `:to="..."`).

  WHEN NOT TO USE:
  - DO NOT use for standard single-status table cells or state indicators (use `BaseBadge.vue` instead).
  - DO NOT use as form input labels or breadcrumb badges.
-->
<script setup lang="ts">
import { computed } from 'vue';
import { ArrowRight } from 'lucide-vue-next';
import BaseBadge, { type BadgeColor } from './BaseBadge.vue';

export type BadgeGroupPosition = 'leading' | 'trailing';
export type BadgeGroupType = 'pill-color' | 'modern';
export type BadgeGroupSize = 'md' | 'lg';

const props = withDefaults(
  defineProps<{
    /** Position of the embedded badge tag ('leading' or 'trailing') */
    badgePosition?: BadgeGroupPosition;
    /** Text for the inner badge pill */
    badgeLabel?: string;
    /** Message text shown beside the badge */
    message?: string;
    /** Color scheme corresponding to QMT Badge tokens */
    color?: BadgeColor;
    /** Style variant: 'pill-color' (default) or 'modern' (with subtle shadow) */
    type?: BadgeGroupType;
    /** Size: 'md' (30px height) or 'lg' (32px height) */
    size?: BadgeGroupSize;
    /** Show trailing action arrow */
    arrow?: boolean;
    /** Optional router link target */
    to?: string | object;
    /** Clickable interactive mode */
    clickable?: boolean;
    /** Optional status dot on inner badge */
    dot?: boolean;
  }>(),
  {
    badgePosition: 'leading',
    badgeLabel: '',
    message: '',
    color: 'gray',
    type: 'pill-color',
    size: 'md',
    arrow: true,
    to: undefined,
    clickable: false,
    dot: false
  }
);

const emit = defineEmits<{
  (e: 'click', event: MouseEvent): void;
}>();

const resolvedColor = computed(() => (props.color === 'brand' ? 'primary' : props.color));

const rootTag = computed(() => {
  if (props.to) return 'router-link';
  if (props.clickable) return 'button';
  return 'div';
});

const isInteractive = computed(() => Boolean(props.to || props.clickable));

const groupClasses = computed(() => [
  'qmt-badge-group',
  `qmt-badge-group--size-${props.size}`,
  `qmt-badge-group--color-${resolvedColor.value}`,
  `qmt-badge-group--type-${props.type}`,
  `qmt-badge-group--pos-${props.badgePosition}`,
  {
    'is-interactive': isInteractive.value
  }
]);

const handleClick = (e: MouseEvent) => {
  if (isInteractive.value) {
    emit('click', e);
  }
};
</script>

<template>
  <component
    :is="rootTag"
    :to="to"
    :class="groupClasses"
    :type="rootTag === 'button' ? 'button' : undefined"
    @click="handleClick"
  >
    <!-- LEADING BADGE (Figma Node 5221:28673 Standard) -->
    <template v-if="badgePosition === 'leading'">
      <BaseBadge
        v-if="badgeLabel || $slots.badge"
        size="sm"
        type="pill-color"
        :color="color"
        :dot="dot || type === 'modern'"
        class="qmt-badge-group__inner-badge"
      >
        <slot name="badge">{{ badgeLabel }}</slot>
      </BaseBadge>

      <span class="qmt-badge-group__message">
        <slot>{{ message }}</slot>
      </span>

      <span v-if="arrow" class="qmt-badge-group__arrow" aria-hidden="true">
        <slot name="arrow">
          <ArrowRight :size="14" />
        </slot>
      </span>
    </template>

    <!-- TRAILING BADGE -->
    <template v-else>
      <span class="qmt-badge-group__message">
        <slot>{{ message }}</slot>
      </span>

      <BaseBadge
        v-if="badgeLabel || $slots.badge"
        size="sm"
        type="pill-color"
        :color="color"
        :dot="dot || type === 'modern'"
        class="qmt-badge-group__inner-badge"
      >
        <slot name="badge">{{ badgeLabel }}</slot>
        <template v-if="arrow" #icon-right>
          <ArrowRight :size="12" />
        </template>
      </BaseBadge>
    </template>
  </component>
</template>

<style scoped>
/* ════════════════════════════════════════════════════════════════════════════ */
/* QMT BADGE GROUP (Figma Node 5221:28673 / Symbol 5221:3640)                   */
/* ════════════════════════════════════════════════════════════════════════════ */
.qmt-badge-group {
  display: inline-flex;
  align-items: center;
  border-radius: 9999px;
  box-sizing: border-box;
  text-decoration: none;
  font-family: inherit;
  border: 1px solid #E5E5E5;
  background-color: #FAFAFA;
  color: #404040;
  transition: all 0.15s ease-in-out;
  cursor: default;
  user-select: none;
}

.qmt-badge-group.is-interactive {
  cursor: pointer;
}

/* Sizes (Figma Node 5221:28673) */
.qmt-badge-group--size-md {
  height: 30px;
  padding: 4px 8px 4px 4px;
  gap: 8px;
}

.qmt-badge-group--size-lg {
  height: 32px;
  padding: 4px 10px 4px 4px;
  gap: 10px;
}

.qmt-badge-group--pos-trailing.qmt-badge-group--size-md {
  padding: 4px 4px 4px 8px;
}

.qmt-badge-group--pos-trailing.qmt-badge-group--size-lg {
  padding: 4px 4px 4px 10px;
}

/* Inner Badge Base (Figma Node 5221:28673: Always a 100% fully rounded pill 9999px) */
.qmt-badge-group__inner-badge,
:deep(.qmt-badge-group__inner-badge) {
  flex-shrink: 0;
  border-radius: 9999px !important;
}

/* Message Text */
.qmt-badge-group__message {
  font-size: 12px;
  line-height: 18px;
  font-weight: 500;
  white-space: nowrap;
}

/* Action Arrow */
.qmt-badge-group__arrow {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: transform 0.15s ease, color 0.15s ease;
}

.qmt-badge-group.is-interactive:hover .qmt-badge-group__arrow {
  transform: translateX(2px);
}

/* ─── Color Themes: Pill Color (Type = 'pill-color') ─── */
/* Figma Node 5221:28673: Inner pill is solid #FFFFFF with 1px semantic colored outline matching outer border (no drop shadow) */
.qmt-badge-group--type-pill-color :deep(.qmt-badge-group__inner-badge) {
  background-color: #FFFFFF !important;
  box-shadow: none;
  border-width: 1px !important;
  border-style: solid !important;
  border-radius: 9999px !important;
}

/* Gray (5221:3560) */
.qmt-badge-group--color-gray {
  background-color: #FAFAFA;
  border-color: #E5E5E5;
}
.qmt-badge-group--color-gray.is-interactive:hover {
  background-color: #F5F5F5;
  border-color: #D4D4D4;
}
.qmt-badge-group--color-gray .qmt-badge-group__message {
  color: #404040;
}
.qmt-badge-group--color-gray .qmt-badge-group__arrow {
  color: #737373;
}
.qmt-badge-group--type-pill-color.qmt-badge-group--color-gray :deep(.qmt-badge-group__inner-badge) {
  color: #404040 !important;
  border-color: #E5E5E5 !important;
}

/* Primary / Brand Blue (5221:3580) */
.qmt-badge-group--color-primary,
.qmt-badge-group--color-brand {
  background-color: #F1F7FE;
  border-color: #BDDBFA;
}
.qmt-badge-group--color-primary.is-interactive:hover,
.qmt-badge-group--color-brand.is-interactive:hover {
  background-color: #E1EEFD;
  border-color: #83BFF6;
}
.qmt-badge-group--color-primary .qmt-badge-group__message,
.qmt-badge-group--color-brand .qmt-badge-group__message {
  color: #0B529C;
}
.qmt-badge-group--color-primary .qmt-badge-group__arrow,
.qmt-badge-group--color-brand .qmt-badge-group__arrow {
  color: #0B529C;
}
.qmt-badge-group--type-pill-color.qmt-badge-group--color-primary :deep(.qmt-badge-group__inner-badge),
.qmt-badge-group--type-pill-color.qmt-badge-group--color-brand :deep(.qmt-badge-group__inner-badge) {
  color: #0B529C !important;
  border-color: #BDDBFA !important;
}

/* Success Green (5221:3640) */
.qmt-badge-group--color-success {
  background-color: #ECFDF5;
  border-color: #5EE9B5;
}
.qmt-badge-group--color-success.is-interactive:hover {
  background-color: #D1FAE5;
  border-color: #00BC7D;
}
.qmt-badge-group--color-success .qmt-badge-group__message {
  color: #007A55;
}
.qmt-badge-group--color-success .qmt-badge-group__arrow {
  color: #009966;
}
.qmt-badge-group--type-pill-color.qmt-badge-group--color-success :deep(.qmt-badge-group__inner-badge) {
  color: #007A55 !important;
  border-color: #5EE9B5 !important;
}

/* Warning Amber (5221:3620) */
.qmt-badge-group--color-warning {
  background-color: #FFFBEB;
  border-color: #FFD230;
}
.qmt-badge-group--color-warning.is-interactive:hover {
  background-color: #FEF3C7;
  border-color: #F0B100;
}
.qmt-badge-group--color-warning .qmt-badge-group__message {
  color: #BB4D00;
}
.qmt-badge-group--color-warning .qmt-badge-group__arrow {
  color: #BB4D00;
}
.qmt-badge-group--type-pill-color.qmt-badge-group--color-warning :deep(.qmt-badge-group__inner-badge) {
  color: #BB4D00 !important;
  border-color: #FFD230 !important;
}

/* Error Red (5221:3600) */
.qmt-badge-group--color-error {
  background-color: #FEF2F2;
  border-color: #FFA2A2;
}
.qmt-badge-group--color-error.is-interactive:hover {
  background-color: #FEE2E2;
  border-color: #FB2C36;
}
.qmt-badge-group--color-error .qmt-badge-group__message {
  color: #C10007;
}
.qmt-badge-group--color-error .qmt-badge-group__arrow {
  color: #E7000B;
}
.qmt-badge-group--type-pill-color.qmt-badge-group--color-error :deep(.qmt-badge-group__inner-badge) {
  color: #C10007 !important;
  border-color: #FFA2A2 !important;
}

/* ─── Modern Variant (Figma 5221:3660 - 5221:3794, 5221:28413) ─── */
.qmt-badge-group--type-modern {
  background-color: #FFFFFF;
  border-color: #D4D4D4;
  box-shadow: 0 1px 2px rgba(16, 24, 40, 0.05);
}
.qmt-badge-group--type-modern.is-interactive:hover {
  background-color: #FAFAFA;
  border-color: #BFBFBF;
}
.qmt-badge-group--type-modern .qmt-badge-group__message {
  color: #404040;
}
.qmt-badge-group--type-modern .qmt-badge-group__arrow {
  color: #737373;
}
.qmt-badge-group--type-modern :deep(.qmt-badge-group__inner-badge) {
  background-color: #FFFFFF !important;
  border: 1px solid #D4D4D4 !important;
  color: #404040 !important;
  border-radius: 9999px !important;
}
</style>
