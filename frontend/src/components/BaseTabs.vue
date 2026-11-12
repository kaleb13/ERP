<script setup lang="ts" generic="T extends string | number">
import { computed, type Component } from 'vue';

export type TabType = 'rounded' | 'underline' | 'segmented' | 'button' | 'outline';
export type TabColor = 'light' | 'brand';
export type TabSize = 'sm' | 'md' | 'lg';
export type TabOrientation = 'horizontal' | 'vertical';

export interface BaseTabItem<IdType = T> {
  id: IdType;
  label: string;
  icon?: Component;
  count?: number | string;
  badge?: string;
  badgeVariant?: 'default' | 'success' | 'warning' | 'danger' | 'info' | 'primary';
  disabled?: boolean;
  tooltip?: string;
  customClass?: string;
}

// Backwards-compatible alias for existing views
export type TabItem<IdType = string> = BaseTabItem<IdType>;

const props = withDefaults(
  defineProps<{
    /** Currently active tab id (use with v-model). */
    modelValue: T;
    /** Tabs to render. `icon` is an optional component. */
    tabs: BaseTabItem<T>[];
    /** 
     * Tab variant type matching QMT Library:
     * - `rounded` (Primary Tab: Figma Node 5603:2799 - pill bar with white pill active item)
     * - `underline` (Secondary Tab: Figma Node 5578:110 - bottom border with blue accent)
     * - `segmented` (Figma Node 5578:316 - 8px radius pill bar)
     * - `button` (Figma Node 5578:180 - standalone pill buttons)
     * - `outline` (Figma Node 5578:452 - stroked outline tabs)
     */
    type?: TabType;
    /** Color scheme. `light` (default for rounded/segmented) or `brand` (#0b529c, default for underline). */
    color?: TabColor;
    /** Visual size. `sm` (36px standard default), `md` (40px), `lg` (44px). */
    size?: TabSize;
    /** Orientation: `horizontal` (default) or `vertical`. */
    orientation?: TabOrientation;
    /** Whether tabs expand to fill 100% width. */
    fullWidth?: boolean;
    /** Whether to show count badges on tabs. Defaults to true. */
    showCount?: boolean;
  }>(),
  {
    type: 'rounded',
    color: undefined,
    size: 'sm',
    orientation: 'horizontal',
    fullWidth: false,
    showCount: true
  }
);

// Effective color: default to 'brand' for underline, 'light' for rounded/segmented/button/outline
const effectiveColor = computed<TabColor>(() => {
  if (props.color) return props.color;
  return props.type === 'underline' ? 'brand' : 'light';
});

const emit = defineEmits<{
  'update:modelValue': [value: T];
  'tab-click': [tab: BaseTabItem<T>];
}>();

const handleTabClick = (tab: BaseTabItem<T>) => {
  if (!tab.disabled) {
    emit('update:modelValue', tab.id);
    emit('tab-click', tab);
  }
};
</script>

<template>
  <div class="qmt-tabs-wrapper" :class="{ 'qmt-tabs-wrapper--full': fullWidth }">
    <!-- Optional Prefix Slot -->
    <slot name="prefix" />

    <!-- Main Tab Bar -->
    <div 
      :class="[
        'qmt-tabs',
        `qmt-tabs--${type}`,
        `qmt-tabs--${size}`,
        `qmt-tabs--${effectiveColor}`,
        `qmt-tabs--${orientation}`,
        { 'qmt-tabs--full': fullWidth }
      ]"
      role="tablist"
      :aria-orientation="orientation"
    >
      <button
        v-for="tab in tabs"
        :key="tab.id"
        type="button"
        role="tab"
        :aria-selected="modelValue === tab.id"
        :disabled="tab.disabled"
        :title="tab.tooltip"
        :class="[
          'qmt-tab',
          `qmt-tab--${type}`,
          `qmt-tab--${size}`,
          `qmt-tab--${effectiveColor}`,
          `qmt-tab--${orientation}`,
          tab.customClass,
          { 
            active: modelValue === tab.id,
            'is-disabled': tab.disabled,
            'flex-1': fullWidth
          }
        ]"
        @click="handleTabClick(tab)"
      >
        <!-- Custom Tab Scoped Slot -->
        <slot name="tab" :tab="tab" :isActive="modelValue === tab.id">
          <!-- Leading Icon -->
          <component
            :is="tab.icon"
            v-if="tab.icon"
            :size="size === 'sm' ? 16 : size === 'lg' ? 20 : 18"
            class="qmt-tab__icon"
          />

          <!-- Label -->
          <span class="qmt-tab__label">{{ tab.label }}</span>

          <!-- Count Badge -->
          <span 
            v-if="showCount && tab.count !== undefined" 
            :class="[
              'qmt-tab__count',
              `count-variant-${tab.badgeVariant || 'default'}`,
              { 'count-active': modelValue === tab.id }
            ]"
          >
            {{ tab.count }}
          </span>

          <!-- Text Badge -->
          <span 
            v-if="tab.badge" 
            :class="[
              'qmt-tab__badge',
              `badge-variant-${tab.badgeVariant || 'primary'}`
            ]"
          >
            {{ tab.badge }}
          </span>
        </slot>

        <!-- Underline active indicator for underline type -->
        <div 
          v-if="type === 'underline' && modelValue === tab.id" 
          class="qmt-tab__underline-indicator" 
        />
      </button>
    </div>

    <!-- Optional Suffix Slot -->
    <slot name="suffix" />
  </div>
</template>

<style scoped>
/* QMT Tabs Base Wrapper & Containers */
.qmt-tabs-wrapper {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  font-family: var(--qmt-font-family-sans, 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif);
}

.qmt-tabs-wrapper--full {
  display: flex;
  width: 100%;
}

.qmt-tabs {
  display: inline-flex;
  align-items: center;
  position: relative;
  user-select: none;
  box-sizing: border-box;
}

.qmt-tabs--vertical {
  flex-direction: column;
  align-items: stretch;
}

.qmt-tabs--full {
  display: flex;
  width: 100%;
}

/* ══════════════════════════════════════════════════════════════════
   1. PRIMARY TAB: Type Rounded (Figma Node 5603:2799)
   - Pill bar with Fill: color/background/secondary (#F5F5F5)
   - Outline / Stroke: color/border/subtle (1px solid #E5E5E5)
   - Active: White pill with #E5E5E5 border, subtle drop shadow, #404040 text
   ══════════════════════════════════════════════════════════════════ */
.qmt-tabs--rounded {
  background-color: var(--qmt-tab-rounded-list-bg, var(--alias-color-background-secondary, #f5f5f5));
  border: 1px solid var(--qmt-tab-rounded-list-border, var(--alias-color-border-subtle, #e5e5e5));
  border-radius: var(--qmt-tab-rounded-list-radius, 9999px);
  padding: var(--qmt-tab-list-padding, 4px);
  gap: var(--qmt-tab-list-gap, 4px);
  box-sizing: border-box;
}

.qmt-tabs--rounded.qmt-tabs--vertical {
  border-radius: 20px;
}

.qmt-tab--rounded {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--qmt-tab-gap, 8px);
  border-radius: var(--qmt-tab-rounded-radius, 9999px);
  border: 1px solid transparent;
  background-color: transparent;
  color: var(--qmt-tab-segmented-fg, #404040);
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.15s ease-in-out;
  outline: none;
  box-sizing: border-box;
}

.qmt-tab--rounded.qmt-tab--sm {
  height: var(--qmt-tab-sm-height, 36px);
  padding: 0 var(--qmt-tab-sm-padding-x, 12px);
  min-width: 91px;
  font-size: var(--qmt-alias-font-size-sm, 14px);
  line-height: var(--qmt-alias-line-height-sm, 20px);
}

.qmt-tab--rounded.qmt-tab--md {
  height: var(--qmt-tab-md-height, 40px);
  padding: 0 var(--qmt-tab-md-padding-x, 16px);
  min-width: 96px;
  font-size: 14px;
  line-height: 20px;
}

.qmt-tab--rounded.qmt-tab--lg {
  height: var(--qmt-tab-lg-height, 44px);
  padding: 0 var(--qmt-tab-lg-padding-x, 18px);
  min-width: 104px;
  font-size: 15px;
  line-height: 22px;
}

.qmt-tab--rounded:hover:not(.active):not(.is-disabled) {
  color: #404040;
  background-color: rgba(255, 255, 255, 0.4);
}

.qmt-tab--rounded.active.qmt-tab--light {
  background-color: var(--qmt-tab-segmented-current-bg, #ffffff);
  border-color: var(--qmt-tab-rounded-border-current, #e5e5e5);
  box-shadow: 0px 1px 1px rgba(10, 13, 18, 0.06), 0px 1px 1.5px rgba(10, 13, 18, 0.1);
  color: var(--qmt-tab-light-fg-current, #404040);
}

.qmt-tab--rounded.active.qmt-tab--brand {
  background-color: #0b529c;
  border-color: #0b529c;
  box-shadow: 0px 1px 2px rgba(11, 82, 156, 0.2);
  color: #ffffff;
}

/* ══════════════════════════════════════════════════════════════════
   2. SECONDARY TAB: Type Underline (Figma Node 5578:110)
   - Bottom border line across container (#D4D4D4)
   - Active: #E1EEFD bg with #0B529C text and 2px #0B529C bottom indicator
   - Inactive: #737373 text, hover #F5F5F5
   ══════════════════════════════════════════════════════════════════ */
.qmt-tabs--underline {
  gap: var(--qmt-tab-gap, 8px);
  border-bottom: 1px solid var(--qmt-tab-list-border, #d4d4d4);
}

.qmt-tabs--underline.qmt-tabs--vertical {
  border-bottom: none;
  border-right: 1px solid var(--qmt-tab-list-border, #d4d4d4);
}

.qmt-tab--underline {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--qmt-tab-gap, 8px);
  border: none;
  background: transparent;
  color: var(--qmt-tab-fg, #737373);
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  border-radius: 6px 6px 0 0;
  transition: background-color 0.15s ease, color 0.15s ease;
  outline: none;
}

.qmt-tab--underline.qmt-tab--sm {
  height: var(--qmt-tab-sm-height, 36px);
  padding: 0 var(--qmt-tab-sm-padding-x, 12px);
  font-size: var(--qmt-alias-font-size-sm, 14px);
  line-height: var(--qmt-alias-line-height-sm, 20px);
}

.qmt-tab--underline.qmt-tab--md {
  height: var(--qmt-tab-md-height, 40px);
  padding: 0 var(--qmt-tab-md-padding-x, 14px);
  font-size: 14px;
  line-height: 20px;
}

.qmt-tab--underline.qmt-tab--lg {
  height: var(--qmt-tab-lg-height, 44px);
  padding: 0 var(--qmt-tab-lg-padding-x, 16px);
  font-size: 15px;
  line-height: 22px;
}

.qmt-tab--underline:hover:not(.is-disabled) {
  background-color: var(--qmt-tab-bg-hover, #f5f5f5);
  color: var(--qmt-tab-fg-hover, #404040);
}

.qmt-tab--underline.qmt-tab--brand.active {
  background-color: var(--qmt-tab-brand-bg-current, #e1eefd);
  color: var(--qmt-tab-brand-fg-current, #0b529c);
}

.qmt-tab--underline.qmt-tab--light.active {
  background-color: transparent;
  color: var(--qmt-tab-light-fg-current, #404040);
}

.qmt-tab__underline-indicator {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 2px;
  background-color: var(--qmt-tab-brand-indicator, #0b529c);
  border-radius: 2px 2px 0 0;
}

.qmt-tabs--vertical .qmt-tab__underline-indicator {
  bottom: 0;
  top: 0;
  left: auto;
  right: 0;
  width: 2px;
  height: 100%;
  border-radius: 2px 0 0 2px;
}

.qmt-tab--light .qmt-tab__underline-indicator {
  background-color: #404040;
}

/* ══════════════════════════════════════════════════════════════════
   3. TYPE: Segmented Control (Figma Node 5578:316)
   - 8px radius list container with color/background/secondary (#F5F5F5) bg
   - Stroke / Outline: color/border/subtle (1px solid #E5E5E5)
   - Active: White rect with 6px radius, subtle shadow
   ══════════════════════════════════════════════════════════════════ */
.qmt-tabs--segmented {
  background-color: var(--qmt-tab-segmented-list-bg, var(--alias-color-background-secondary, #f5f5f5));
  border: 1px solid var(--qmt-tab-segmented-list-border, var(--alias-color-border-subtle, #e5e5e5));
  border-radius: var(--qmt-tab-list-radius, 8px);
  padding: var(--qmt-tab-list-padding, 4px);
  gap: var(--qmt-tab-list-gap, 4px);
  box-sizing: border-box;
}

.qmt-tab--segmented {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border-radius: 6px;
  border: none;
  background-color: transparent;
  color: var(--qmt-tab-segmented-fg, #404040);
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.15s ease-in-out;
  outline: none;
}

.qmt-tab--segmented.qmt-tab--sm {
  height: var(--qmt-tab-sm-height, 36px);
  padding: 0 var(--qmt-tab-sm-padding-x, 12px);
  font-size: 14px;
}

.qmt-tab--segmented.qmt-tab--md {
  height: var(--qmt-tab-md-height, 40px);
  padding: 0 var(--qmt-tab-md-padding-x, 14px);
  font-size: 14px;
}

.qmt-tab--segmented.qmt-tab--lg {
  height: var(--qmt-tab-lg-height, 44px);
  padding: 0 var(--qmt-tab-lg-padding-x, 16px);
  font-size: 15px;
}

.qmt-tab--segmented:hover:not(.active):not(.is-disabled) {
  color: #404040;
  background-color: rgba(255, 255, 255, 0.4);
}

.qmt-tab--segmented.active.qmt-tab--light {
  background-color: #ffffff;
  color: #404040;
  box-shadow: 0px 1px 1px rgba(10, 13, 18, 0.06), 0px 1px 1.5px rgba(10, 13, 18, 0.1);
}

.qmt-tab--segmented.active.qmt-tab--brand {
  background-color: #0b529c;
  color: #ffffff;
  box-shadow: 0px 1px 2px rgba(11, 82, 156, 0.2);
}

/* ══════════════════════════════════════════════════════════════════
   4. TYPE: Button Tabs (Figma Node 5578:180)
   - Transparent list container with gap 4px
   - Active: #F5F5F5 bg with #404040 text (Light) or #0B529C with white (Brand)
   ══════════════════════════════════════════════════════════════════ */
.qmt-tabs--button {
  gap: var(--qmt-tab-list-gap, 4px);
  background-color: transparent;
}

.qmt-tab--button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border-radius: var(--qmt-tab-radius, 8px);
  border: 1px solid transparent;
  background-color: transparent;
  color: var(--qmt-tab-fg, #737373);
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.15s ease-in-out;
  outline: none;
}

.qmt-tab--button.qmt-tab--sm {
  height: var(--qmt-tab-sm-height, 36px);
  padding: 0 var(--qmt-tab-sm-padding-x, 12px);
  font-size: 14px;
}

.qmt-tab--button.qmt-tab--md {
  height: var(--qmt-tab-md-height, 40px);
  padding: 0 var(--qmt-tab-md-padding-x, 14px);
  font-size: 14px;
}

.qmt-tab--button.qmt-tab--lg {
  height: var(--qmt-tab-lg-height, 44px);
  padding: 0 var(--qmt-tab-lg-padding-x, 16px);
  font-size: 15px;
}

.qmt-tab--button:hover:not(.active):not(.is-disabled) {
  background-color: var(--qmt-tab-bg-hover, #f5f5f5);
  color: var(--qmt-tab-fg-hover, #404040);
}

.qmt-tab--button.active.qmt-tab--light {
  background-color: var(--qmt-tab-light-bg-current, #f5f5f5);
  color: var(--qmt-tab-light-fg-current, #404040);
}

.qmt-tab--button.active.qmt-tab--brand {
  background-color: #0b529c;
  color: #ffffff;
}

/* ══════════════════════════════════════════════════════════════════
   5. TYPE: Outline Tabs (Figma Node 5578:452)
   - Transparent list container with gap 4px
   - Active: White bg with 1px border (#D4D4D4 for Light, #0B529C for Brand)
   ══════════════════════════════════════════════════════════════════ */
.qmt-tabs--outline {
  gap: var(--qmt-tab-list-gap, 4px);
  background-color: transparent;
}

.qmt-tab--outline {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border-radius: var(--qmt-tab-radius, 8px);
  border: 1px solid transparent;
  background-color: transparent;
  color: var(--qmt-tab-fg, #737373);
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.15s ease-in-out;
  outline: none;
}

.qmt-tab--outline.qmt-tab--sm {
  height: var(--qmt-tab-sm-height, 36px);
  padding: 0 var(--qmt-tab-sm-padding-x, 12px);
  font-size: 14px;
}

.qmt-tab--outline.qmt-tab--md {
  height: var(--qmt-tab-md-height, 40px);
  padding: 0 var(--qmt-tab-md-padding-x, 14px);
  font-size: 14px;
}

.qmt-tab--outline.qmt-tab--lg {
  height: var(--qmt-tab-lg-height, 44px);
  padding: 0 var(--qmt-tab-lg-padding-x, 16px);
  font-size: 15px;
}

.qmt-tab--outline:hover:not(.active):not(.is-disabled) {
  background-color: #f5f5f5;
  color: #404040;
}

.qmt-tab--outline.active.qmt-tab--light {
  background-color: #ffffff;
  border-color: var(--qmt-tab-outline-border, #d4d4d4);
  color: #404040;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
}

.qmt-tab--outline.active.qmt-tab--brand {
  background-color: #ffffff;
  border-color: var(--qmt-tab-outline-border-brand, #0b529c);
  color: #0b529c;
  box-shadow: 0 1px 2px rgba(11, 82, 156, 0.1);
}

/* ══════════════════════════════════════════════════════════════════
   Common Shared Elements (Icons, Badges, Count, Disabled)
   ══════════════════════════════════════════════════════════════════ */
.qmt-tab.is-disabled {
  opacity: 0.45;
  cursor: not-allowed;
  pointer-events: none;
}

.qmt-tab__icon {
  color: currentColor;
  flex-shrink: 0;
}

.qmt-tab__label {
  font-family: inherit;
  font-weight: 600;
  white-space: nowrap;
}

/* Count Badge */
.qmt-tab__count {
  font-size: 12px;
  font-weight: 600;
  padding: 1px 7px;
  border-radius: 9999px;
  line-height: 16px;
  min-width: 20px;
  text-align: center;
  transition: all 0.15s ease-in-out;
  display: inline-block;
}

/* Count badges on rounded / segmented tabs */
.qmt-tab--rounded .qmt-tab__count,
.qmt-tab--segmented .qmt-tab__count {
  background-color: rgba(255, 255, 255, 0.65);
  color: #404040;
}

.qmt-tab__count.count-variant-warning {
  background-color: #FEF3C6 !important;
  color: #BB4D00 !important;
}

.qmt-tab__count.count-variant-success {
  background-color: #D0FAE5 !important;
  color: #007A55 !important;
}

.qmt-tab__count.count-variant-danger {
  background-color: #FFE2E2 !important;
  color: #C10007 !important;
}

.qmt-tab__count.count-variant-primary {
  background-color: #E1EEFD !important;
  color: #0B529C !important;
}

.qmt-tab--rounded.active.qmt-tab--light .qmt-tab__count,
.qmt-tab--segmented.active.qmt-tab--light .qmt-tab__count {
  background-color: #f5f5f5;
  color: #404040;
}

.qmt-tab--rounded.active.qmt-tab--brand .qmt-tab__count,
.qmt-tab--segmented.active.qmt-tab--brand .qmt-tab__count {
  background-color: rgba(255, 255, 255, 0.25);
  color: #ffffff;
}

/* Count badges on underline tabs */
.qmt-tab--underline .qmt-tab__count {
  background-color: #f5f5f5;
  color: #737373;
}

.qmt-tab--underline.active.qmt-tab--brand .qmt-tab__count {
  background-color: #0b529c;
  color: #ffffff;
}

.qmt-tab--underline.active.qmt-tab--light .qmt-tab__count {
  background-color: #404040;
  color: #ffffff;
}

/* Text Badges */
.qmt-tab__badge {
  font-size: 11px;
  font-weight: 600;
  padding: 1px 6px;
  border-radius: 4px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.badge-variant-primary {
  background-color: #e1eefd;
  color: #0b529c;
}

.badge-variant-success {
  background-color: #d0fae5;
  color: #007a55;
}

.badge-variant-warning {
  background-color: #fef3c6;
  color: #bb4d00;
}

.badge-variant-danger {
  background-color: #ffe2e2;
  color: #c10007;
}

.badge-variant-info {
  background-color: #f0f9ff;
  color: #0069a8;
}
</style>
