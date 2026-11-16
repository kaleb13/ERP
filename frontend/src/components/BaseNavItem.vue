<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, type Component } from 'vue';
import { RouterLink, type RouteLocationRaw } from 'vue-router';
import { ChevronDown } from 'lucide-vue-next';

export type NavItemType = 'sidebar' | 'sub-item' | 'collapsed' | 'horizontal' | 'mega';
export type NavItemSurface = 'light' | 'brand';
export type NavItemActiveStyle = 'neutral' | 'brand';
export type NavItemBadgeVariant = 'brand' | 'success' | 'warning' | 'error' | 'gray';

export interface BaseNavItemProps {
  /**
   * Component type matching Figma Node 3345:24551:
   * - `sidebar`: Standard sidebar navigation item (40px height, 12px padding-x, 8px padding-y)
   * - `sub-item`: Indented sub-navigation item (36px height, 36px/48px left indent)
   * - `collapsed`: 40px icon-only item with dark tooltip on hover
   * - `mega`: Rich 64px item with icon tile, label, supporting text, and chevron (used for Sidebar Top Module Header)
   * - `horizontal`: Horizontal topbar navigation item (36px height)
   */
  type?: NavItemType;

  /** Surface theme: 'light' (default) or 'brand' (#0B529C background) */
  surface?: NavItemSurface;

  /** Active visual style: 'neutral' (default in ERP sidebar: #f5f5f5 background, #404040 text) or 'brand' (#e1eefd background, #0b529c text) */
  activeStyle?: NavItemActiveStyle;

  /** Main label / title text */
  label?: string;

  /** Supporting text / description (for 'mega' items or rich subheadings) */
  supportingText?: string;

  /** Leading icon component */
  icon?: Component | any;

  /** Whether leading icon is shown */
  showIcon?: boolean;

  /** Custom tile background color (for 'mega' variant tile box) */
  tileBg?: string;

  /** Custom tile icon color (for 'mega' variant tile box) */
  tileColor?: string;

  /** Trailing badge value (e.g. count or status text) */
  badge?: string | number;

  /** Whether to show trailing badge */
  showBadge?: boolean;

  /** Badge color variant */
  badgeVariant?: NavItemBadgeVariant;

  /** Custom chevron component or boolean */
  chevron?: Component | any;

  /** Whether to show trailing chevron */
  showChevron?: boolean;

  /** Expanded state (rotates chevron by 180 degrees or 90 degrees) */
  expanded?: boolean;

  /** Active state override */
  active?: boolean;

  /** Disabled state */
  disabled?: boolean;

  /** Vue Router destination */
  to?: RouteLocationRaw;

  /** Native href destination */
  href?: string;

  /** Explicit HTML tag override */
  tag?: string;

  /** Tooltip text (auto-defaults to label for collapsed rail) */
  tooltip?: string;

  /** Custom CSS classes */
  customClass?: string;
}

const props = withDefaults(defineProps<BaseNavItemProps>(), {
  type: 'sidebar',
  surface: 'light',
  activeStyle: 'neutral',
  label: '',
  supportingText: '',
  icon: undefined,
  showIcon: true,
  tileBg: undefined,
  tileColor: undefined,
  badge: undefined,
  showBadge: false,
  badgeVariant: 'brand',
  chevron: undefined,
  showChevron: false,
  expanded: false,
  active: false,
  disabled: false,
  to: undefined,
  href: undefined,
  tag: undefined,
  tooltip: undefined,
  customClass: ''
});

const emit = defineEmits<{
  (e: 'click', event: MouseEvent): void;
}>();

// Compute the rendered element tag
const resolvedTag = computed(() => {
  if (props.tag) return props.tag;
  if (props.to) return RouterLink;
  if (props.href) return 'a';
  return 'div';
});

// ─── Collapsed Tooltip Teleport State ───
const isTooltipVisible = ref(false);
const tooltipPos = ref({ top: 0, left: 0 });

const updateTooltipPos = (target: HTMLElement) => {
  const rect = target.getBoundingClientRect();
  const sidebar = target.closest('.app-sidebar');
  const sidebarRect = sidebar ? sidebar.getBoundingClientRect() : null;
  
  // Align left edge to the right of the sidebar boundary (or item boundary) with 10px spacing
  const leftPos = sidebarRect ? sidebarRect.right + 10 : rect.right + 10;
  
  tooltipPos.value = {
    top: rect.top + rect.height / 2,
    left: leftPos
  };
};

const handleMouseEnter = (event: MouseEvent) => {
  if (props.type !== 'collapsed' || props.disabled) return;
  const target = event.currentTarget as HTMLElement;
  if (!target) return;
  updateTooltipPos(target);
  isTooltipVisible.value = true;
};

const handleMouseLeave = () => {
  if (props.type !== 'collapsed') return;
  isTooltipVisible.value = false;
};

const handleFocusIn = (event: FocusEvent) => {
  if (props.type !== 'collapsed' || props.disabled) return;
  const target = event.currentTarget as HTMLElement;
  if (!target) return;
  updateTooltipPos(target);
  isTooltipVisible.value = true;
};

const handleFocusOut = () => {
  if (props.type !== 'collapsed') return;
  isTooltipVisible.value = false;
};

const handleScroll = () => {
  if (isTooltipVisible.value) {
    isTooltipVisible.value = false;
  }
};

onMounted(() => {
  window.addEventListener('scroll', handleScroll, true);
});

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll, true);
});

const handleClick = (event: MouseEvent) => {
  if (props.disabled) {
    event.preventDefault();
    event.stopPropagation();
    return;
  }
  isTooltipVisible.value = false;
  emit('click', event);
};
</script>

<template>
  <component
    :is="resolvedTag"
    :to="to"
    :href="href"
    :class="[
      'qmt-nav-item',
      `qmt-nav-item--${type}`,
      `qmt-nav-item--${surface}`,
      `qmt-nav-item--active-${activeStyle}`,
      customClass,
      {
        'is-active': active,
        'is-disabled': disabled,
        'is-expanded': expanded,
        'has-tile': Boolean(tileBg)
      }
    ]"
    :aria-disabled="disabled"
    :title="type !== 'collapsed' ? tooltip : undefined"
    @click="handleClick"
    @mouseenter="handleMouseEnter"
    @mouseleave="handleMouseLeave"
    @focusin="handleFocusIn"
    @focusout="handleFocusOut"
  >
    <!-- MEGA VARIANT (Figma Node 3345:24551 Type=Mega: 64px, tile box 40px, title + subtitle) -->
    <template v-if="type === 'mega'">
      <div 
        class="qmt-nav-item__tile" 
        :style="{ backgroundColor: tileBg || 'var(--qmt-nav-item-mega-tile-bg, #f1f7fe)' }"
      >
        <slot name="icon">
          <component 
            :is="icon" 
            v-if="showIcon && icon" 
            class="qmt-nav-item__tile-icon"
            :style="{ color: tileColor || 'inherit' }"
            :size="20"
          />
        </slot>
      </div>

      <div class="qmt-nav-item__text-block">
        <div class="qmt-nav-item__title-row">
          <span class="qmt-nav-item__title">
            <slot>{{ label }}</slot>
          </span>

          <span 
            v-if="showBadge && (badge !== undefined && badge !== '')" 
            :class="['qmt-nav-item__badge', `qmt-nav-item__badge--${badgeVariant}`]"
          >
            <slot name="badge">{{ badge }}</slot>
          </span>
        </div>

        <p v-if="supportingText || $slots.supportingText" class="qmt-nav-item__supporting-text">
          <slot name="supportingText">{{ supportingText }}</slot>
        </p>
      </div>

      <div v-if="showChevron" class="qmt-nav-item__chevron-wrapper">
        <slot name="chevron">
          <component 
            :is="chevron || ChevronDown" 
            :size="18" 
            class="qmt-nav-item__chevron"
            :class="{ 'is-rotated': expanded }"
          />
        </slot>
      </div>
    </template>

    <!-- COLLAPSED VARIANT (Figma Node 3345:24551 Type=Collapsed: 40px icon with hover tooltip) -->
    <template v-else-if="type === 'collapsed'">
      <!-- When tileBg is provided (e.g. Top Module Icon in Collapsed Sidebar) -->
      <div 
        v-if="tileBg"
        class="qmt-nav-item__tile qmt-nav-item__tile--collapsed"
        :style="{ backgroundColor: tileBg }"
      >
        <slot name="icon">
          <component 
            :is="icon" 
            v-if="icon" 
            class="qmt-nav-item__tile-icon"
            :style="{ color: tileColor || 'inherit' }"
            :size="20"
          />
        </slot>
      </div>

      <!-- Standard Collapsed Icon (e.g. Regular Sidebar Navigation Item) -->
      <slot v-else name="icon">
        <component 
          :is="icon" 
          v-if="icon" 
          class="qmt-nav-item__icon"
          :size="20"
        />
      </slot>

      <!-- QMT Dark Tooltip Portal (Figma Node 3345:33314) Teleported to body to escape overflow clipping -->
      <Teleport to="body">
        <Transition name="qmt-tooltip-fade">
          <div
            v-if="isTooltipVisible && !expanded && (tooltip || label)"
            class="qmt-nav-item__tooltip-portal"
            role="tooltip"
            :style="{
              top: `${tooltipPos.top}px`,
              left: `${tooltipPos.left}px`
            }"
          >
            <span>{{ tooltip || label }}</span>
            <div class="qmt-nav-item__tooltip-arrow" />
          </div>
        </Transition>
      </Teleport>
    </template>

    <!-- STANDARD / SUB-ITEM / HORIZONTAL VARIANTS -->
    <template v-else>
      <slot name="icon">
        <component 
          :is="icon" 
          v-if="showIcon && icon" 
          class="qmt-nav-item__icon"
          :size="type === 'sub-item' ? 16 : 18"
        />
      </slot>

      <span class="qmt-nav-item__label">
        <slot>{{ label }}</slot>
      </span>

      <span 
        v-if="showBadge && (badge !== undefined && badge !== '')" 
        :class="['qmt-nav-item__badge', `qmt-nav-item__badge--${badgeVariant}`]"
      >
        <slot name="badge">{{ badge }}</slot>
      </span>

      <div v-if="showChevron" class="qmt-nav-item__chevron-wrapper">
        <slot name="chevron">
          <component 
            :is="chevron || ChevronDown" 
            :size="16" 
            class="qmt-nav-item__chevron"
            :class="{ 'is-rotated': expanded }"
          />
        </slot>
      </div>
    </template>
  </component>
</template>

<style scoped>
/* ─── BASE NAV ITEM (Figma Node 3345:24551) ─── */
.qmt-nav-item {
  position: relative;
  display: flex;
  align-items: center;
  box-sizing: border-box;
  text-decoration: none;
  cursor: pointer;
  user-select: none;
  border: 1px solid transparent;
  transition: background-color 0.15s ease, color 0.15s ease, border-color 0.15s ease, box-shadow 0.15s ease;
  font-family: var(--qmt-font-family-sans, 'Inter', -apple-system, BlinkMacSystemFont, sans-serif);
}

/* ─── VARIANT: SIDEBAR (Standard row: 40px height, 8px radius, 12px padding-x, 8px padding-y) ─── */
.qmt-nav-item--sidebar {
  width: 100%;
  min-height: var(--qmt-nav-item-height, 40px);
  padding: var(--qmt-nav-item-padding-y, 8px) var(--qmt-nav-item-padding-x, 12px);
  gap: var(--qmt-nav-item-gap, 12px);
  border-radius: var(--qmt-nav-item-radius, 8px);
}

/* ─── VARIANT: SUB-ITEM (Indented row: 36px height, 36px indent) ─── */
.qmt-nav-item--sub-item {
  width: 100%;
  min-height: var(--qmt-nav-item-sub-height, 36px);
  padding: var(--qmt-nav-item-padding-y, 8px) var(--qmt-nav-item-padding-x, 12px) var(--qmt-nav-item-padding-y, 8px) var(--qmt-nav-item-sub-indent, 36px);
  gap: var(--qmt-nav-item-gap, 12px);
  border-radius: var(--qmt-nav-item-radius, 8px);
}

/* ─── VARIANT: COLLAPSED (40px × 40px icon centered with hover tooltip) ─── */
.qmt-nav-item--collapsed {
  width: var(--qmt-nav-item-collapsed-size, 40px);
  height: var(--qmt-nav-item-collapsed-size, 40px);
  padding: 0;
  justify-content: center;
  border-radius: var(--qmt-nav-item-radius, 8px);
}

/* ─── VARIANT: MEGA (Sidebar Top Module Brand Header: 56px height, tile + text) ─── */
.qmt-nav-item--mega {
  width: 100%;
  height: var(--qmt-nav-item-mega-height, 56px);
  min-height: var(--qmt-nav-item-mega-height, 56px);
  max-height: var(--qmt-nav-item-mega-height, 56px);
  padding: var(--qmt-nav-item-mega-padding, 8px 12px);
  gap: var(--qmt-nav-item-gap, 12px);
  border-radius: var(--alias-radius-xl, 12px);
  background-color: var(--alias-color-background-secondary, #f5f5f5);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
}

.qmt-nav-item--mega:hover {
  background-color: #ffffff;
  border-color: #d1d5db;
}

/* ─── VARIANT: HORIZONTAL (Top bar horizontal nav: 36px height) ─── */
.qmt-nav-item--horizontal {
  height: 36px;
  padding: 8px 12px;
  gap: 8px;
  border-radius: var(--qmt-nav-item-radius, 8px);
}

/* ─── INNER ELEMENTS ─── */
.qmt-nav-item__icon {
  flex-shrink: 0;
  color: inherit;
  transition: color 0.15s ease, transform 0.2s ease;
}

.qmt-nav-item__label {
  flex: 1 1 0%;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 14px;
  font-weight: 500;
  line-height: 20px;
  transition: color 0.15s ease;
}

.qmt-nav-item--sub-item .qmt-nav-item__label {
  font-size: 13.5px;
}

/* Mega Tile Box */
.qmt-nav-item__tile {
  width: var(--qmt-nav-item-mega-tile-size, 38px);
  height: var(--qmt-nav-item-mega-tile-size, 38px);
  border-radius: var(--qmt-nav-item-mega-tile-radius, 8px);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  border: 0.5px solid rgba(0, 0, 0, 0.06);
}

.qmt-nav-item__tile-icon {
  flex-shrink: 0;
}

.qmt-nav-item__text-block {
  flex: 1 1 0%;
  min-width: 0;
  display: flex;
  flex-direction: column;
  justify-content: center;
  overflow: hidden;
}

.qmt-nav-item__title-row {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
}

.qmt-nav-item__title {
  font-size: 14px;
  font-weight: 600;
  line-height: 20px;
  color: var(--qmt-nav-item-mega-title-fg, #262626);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.qmt-nav-item__supporting-text {
  margin: 0;
  font-size: 11.5px;
  font-weight: 400;
  line-height: 16px;
  color: var(--qmt-nav-item-mega-desc-fg, #737373);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Chevron */
.qmt-nav-item__chevron-wrapper {
  margin-left: auto;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.qmt-nav-item__chevron {
  color: #737373;
  transition: transform 0.2s ease, color 0.15s ease;
}

.qmt-nav-item__chevron.is-rotated {
  transform: rotate(180deg);
}

/* Trailing Badge (Figma Node 3345:21149 _Badge base) */
.qmt-nav-item__badge {
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: var(--qmt-badge-sm-padding-y, 2px) var(--qmt-badge-sm-padding-x, 8px);
  border-radius: var(--qmt-badge-radius-pill, 9999px);
  font-size: 12px;
  font-weight: 600;
  line-height: 16px;
  white-space: nowrap;
}

.qmt-nav-item__badge--brand {
  background-color: var(--qmt-badge-brand-bg, #e1eefd);
  color: var(--qmt-badge-brand-fg, #0b529c);
}

.qmt-nav-item__badge--success {
  background-color: var(--primitive-color-emerald-100, #d0fae5);
  color: var(--primitive-color-emerald-700, #007a55);
}

.qmt-nav-item__badge--warning {
  background-color: var(--primitive-color-amber-100, #fef3c6);
  color: var(--primitive-color-amber-700, #bb4d00);
}

.qmt-nav-item__badge--error {
  background-color: var(--primitive-color-red-100, #ffe2e2);
  color: var(--primitive-color-red-700, #c10007);
}

.qmt-nav-item__badge--gray {
  background-color: var(--primitive-color-neutral-200, #e5e5e5);
  color: var(--primitive-color-neutral-700, #404040);
}

/* ─── COLOR SURFACES & STATES (Surface=Light) ─── */
.qmt-nav-item--light {
  color: var(--qmt-nav-item-fg, var(--alias-color-text-tertiary, #737373));
  background-color: transparent;
}

.qmt-nav-item--light .qmt-nav-item__icon,
.qmt-nav-item--light .qmt-nav-item__chevron {
  color: var(--qmt-nav-item-icon, var(--alias-color-icon-tertiary, #737373));
}

.qmt-nav-item--light:hover:not(.is-active):not(.is-disabled) {
  background-color: var(--qmt-nav-item-bg-hover, var(--alias-color-background-secondary, #f5f5f5));
  color: var(--qmt-nav-item-fg-hover, var(--alias-color-text-secondary, #404040));
}

.qmt-nav-item--light:hover:not(.is-active):not(.is-disabled) .qmt-nav-item__icon,
.qmt-nav-item--light:hover:not(.is-active):not(.is-disabled) .qmt-nav-item__chevron {
  color: var(--qmt-nav-item-icon-hover, var(--alias-color-icon-secondary, #404040));
}

.qmt-nav-item--light:hover:not(.is-active):not(.is-disabled) .qmt-nav-item__label {
  color: var(--qmt-nav-item-fg-hover, var(--alias-color-text-secondary, #404040));
}

/* Active State: Neutral (Haleta ERP Standard: #f5f5f5 bg, #404040 text, subtle shadow) */
.qmt-nav-item--light.qmt-nav-item--active-neutral.is-active {
  background-color: var(--qmt-nav-item-neutral-bg-current, var(--alias-color-background-secondary, #f5f5f5));
  color: var(--qmt-nav-item-neutral-fg-current, var(--alias-color-text-secondary, #404040));
  font-weight: 600;
  box-shadow: 0px 1px 1px rgba(10, 13, 18, 0.06), 0px 1px 1.5px rgba(10, 13, 18, 0.1);
}

.qmt-nav-item--light.qmt-nav-item--active-neutral.is-active .qmt-nav-item__icon,
.qmt-nav-item--light.qmt-nav-item--active-neutral.is-active .qmt-nav-item__chevron {
  color: var(--qmt-nav-item-neutral-icon-current, var(--alias-color-icon-secondary, #404040));
}

.qmt-nav-item--light.qmt-nav-item--active-neutral.is-active .qmt-nav-item__label {
  color: var(--qmt-nav-item-neutral-fg-current, var(--alias-color-text-secondary, #404040));
}

/* Active State: Brand (QMT Standard: #e1eefd bg, #0b529c text) */
.qmt-nav-item--light.qmt-nav-item--active-brand.is-active {
  background-color: var(--qmt-nav-item-bg-current, #e1eefd);
  color: var(--qmt-nav-item-fg-current, #0b529c);
  font-weight: 600;
}

.qmt-nav-item--light.qmt-nav-item--active-brand.is-active .qmt-nav-item__icon,
.qmt-nav-item--light.qmt-nav-item--active-brand.is-active .qmt-nav-item__chevron {
  color: #0b529c;
}

/* ─── COLOR SURFACES & STATES (Surface=Brand: Blue Background) ─── */
.qmt-nav-item--brand {
  color: rgba(255, 255, 255, 0.85);
  background-color: var(--qmt-nav-item-brand-bg, #0b529c);
}

.qmt-nav-item--brand:hover:not(.is-active):not(.is-disabled) {
  background-color: var(--qmt-nav-item-brand-bg-hover, rgba(255, 255, 255, 0.12));
  color: #ffffff;
}

.qmt-nav-item--brand.is-active {
  background-color: var(--qmt-nav-item-brand-bg-current, #e1eefd);
  color: var(--qmt-nav-item-brand-fg-current, #0b529c);
  font-weight: 600;
}

/* Disabled */
.qmt-nav-item.is-disabled {
  opacity: 0.45;
  cursor: not-allowed;
  pointer-events: none;
}

/* ─── COLLAPSED TILE (When tileBg provided) ─── */
.qmt-nav-item--collapsed.has-tile {
  background-color: transparent !important;
  border-color: transparent !important;
}

.qmt-nav-item--collapsed .qmt-nav-item__tile--collapsed {
  width: var(--qmt-nav-item-collapsed-tile-size, 38px);
  height: var(--qmt-nav-item-collapsed-tile-size, 38px);
  border-radius: var(--qmt-nav-item-mega-tile-radius, 8px);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  border: 0.5px solid rgba(0, 0, 0, 0.06);
  transition: transform 0.15s ease, box-shadow 0.15s ease, filter 0.15s ease;
}

.qmt-nav-item--collapsed.has-tile:hover .qmt-nav-item__tile--collapsed {
  box-shadow: 0 2px 6px rgba(10, 13, 18, 0.12);
  filter: brightness(0.96);
  transform: translateY(-0.5px);
}

.qmt-nav-item--collapsed.has-tile.is-expanded .qmt-nav-item__tile--collapsed {
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.25);
}

/* ─── COLLAPSED TOOLTIP PORTAL (Figma Node 3345:33314) ─── */
.qmt-nav-item__tooltip-portal {
  position: fixed;
  transform: translateY(-50%);
  background-color: var(--qmt-tooltip-bg-dark, #171717);
  color: var(--qmt-tooltip-fg-dark, #f5f5f5);
  font-size: 12px;
  font-weight: 500;
  line-height: 18px;
  white-space: nowrap;
  padding: 6px 10px;
  border-radius: var(--qmt-tooltip-radius, 8px);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1);
  pointer-events: none;
  z-index: 99999;
}

.qmt-nav-item__tooltip-arrow {
  position: absolute;
  right: 100%;
  top: 50%;
  transform: translateY(-50%);
  width: 0;
  height: 0;
  border-width: 5px 5px 5px 0;
  border-style: solid;
  border-color: transparent var(--qmt-tooltip-bg-dark, #171717) transparent transparent;
}

.qmt-tooltip-fade-enter-active,
.qmt-tooltip-fade-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}

.qmt-tooltip-fade-enter-from,
.qmt-tooltip-fade-leave-to {
  opacity: 0;
  transform: translateY(-50%) translateX(-4px);
}
</style>
