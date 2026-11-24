<!--
  Authoritative QMT BaseTooltip Component (Figma 3345:33314)
  ==============================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Contextual hover microcopy on interactive icons, compact utility buttons, and truncated text.
  - Examples: Hover hint on `.btn-action-dots` (More Actions), column toggle trigger (`IconColumnSolid`),
    refresh buttons, view density switches, and truncated status pills.
  - Supports dark theme (`#171717`) or light theme (`#ffffff` with `#e5e5e5` border) with optional arrow.

  WHEN NOT TO USE:
  - DO NOT use for primary form field descriptions or instructions (use `helper-text` / `hint` on `FormInput` / `FormSelect`).
  - DO NOT hide critical validation rules or required field indicators inside tooltips.
  - DO NOT place complex interactive elements (buttons, inputs) inside tooltips (use popover or modal instead).
-->
<script setup lang="ts">
import { ref, computed } from 'vue';

interface Props {
  /** Tooltip main text */
  text?: string;
  /** Optional secondary supporting description */
  supportingText?: string;
  /** Color theme: dark (default #171717) or light (#ffffff with border) */
  theme?: 'dark' | 'light';
  /** Arrow placement relative to target */
  placement?: 'top' | 'bottom' | 'left' | 'right';
  /** Whether to show arrow pointer */
  arrow?: boolean;
  /** Delay in milliseconds before opening */
  delay?: number;
  /** Whether tooltip is disabled */
  disabled?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  theme: 'dark',
  placement: 'top',
  arrow: true,
  delay: 100,
  disabled: false
});

const isVisible = ref(false);
let timer: ReturnType<typeof setTimeout> | null = null;

const showTooltip = () => {
  if (props.disabled) return;
  if (timer) clearTimeout(timer);
  timer = setTimeout(() => {
    isVisible.value = true;
  }, props.delay);
};

const hideTooltip = () => {
  if (timer) clearTimeout(timer);
  isVisible.value = false;
};
</script>

<template>
  <div 
    class="qmt-tooltip-target-wrapper" 
    @mouseenter="showTooltip" 
    @mouseleave="hideTooltip"
    @focusin="showTooltip"
    @focusout="hideTooltip"
  >
    <!-- Trigger Element Slot -->
    <slot />

    <!-- Tooltip Floating Bubble (Figma Node 3345:33407) -->
    <Transition name="qmt-tooltip-fade">
      <div 
        v-if="isVisible && !disabled && (text || supportingText || $slots.content)"
        :class="[
          'qmt-tooltip-bubble',
          `qmt-tooltip-bubble--${theme}`,
          `qmt-tooltip-bubble--${placement}`,
          { 'qmt-tooltip-bubble--has-arrow': arrow }
        ]"
        role="tooltip"
      >
        <div class="qmt-tooltip-content">
          <slot name="content">
            <span v-if="text" class="qmt-tooltip-text">{{ text }}</span>
            <p v-if="supportingText" class="qmt-tooltip-supporting">{{ supportingText }}</p>
          </slot>
        </div>

        <!-- Arrow element -->
        <div v-if="arrow" class="qmt-tooltip-arrow" />
      </div>
    </Transition>
  </div>
</template>

<style scoped>
/* QMT Tooltip (Figma Node 3345:33314 / 3345:33407) */
.qmt-tooltip-target-wrapper {
  position: relative;
  display: inline-flex;
}

.qmt-tooltip-bubble {
  position: absolute;
  z-index: 9999;
  border-radius: var(--qmt-tooltip-radius, 8px);
  padding: var(--qmt-tooltip-padding-y, 8px) var(--qmt-tooltip-padding-x, 12px);
  box-shadow: 0px 12px 16px -4px rgba(10, 13, 18, 0.08), 0px 4px 6px -2px rgba(10, 13, 18, 0.03);
  font-family: var(--qmt-font-family-sans, 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif);
  pointer-events: none;
  box-sizing: border-box;
  max-width: 280px;
  width: max-content;
}

/* Placements */
.qmt-tooltip-bubble--top {
  bottom: 100%;
  left: 50%;
  transform: translateX(-50%);
  margin-bottom: 8px;
}

.qmt-tooltip-bubble--bottom {
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
  margin-top: 8px;
}

.qmt-tooltip-bubble--left {
  right: 100%;
  top: 50%;
  transform: translateY(-50%);
  margin-right: 8px;
}

.qmt-tooltip-bubble--right {
  left: 100%;
  top: 50%;
  transform: translateY(-50%);
  margin-left: 8px;
}

/* Themes (Figma 3345:33407 Theme=Dark vs Theme=Light) */
.qmt-tooltip-bubble--dark {
  background-color: var(--qmt-tooltip-bg-dark, #171717);
  color: var(--qmt-tooltip-fg-dark, #f5f5f5);
}

.qmt-tooltip-bubble--dark .qmt-tooltip-supporting {
  color: var(--qmt-tooltip-desc-dark, #d4d4d4);
}

.qmt-tooltip-bubble--light {
  background-color: var(--qmt-tooltip-bg-light, #ffffff);
  color: var(--qmt-tooltip-fg-light, #171717);
  border: 1px solid var(--qmt-tooltip-border-light, #e5e5e5);
}

.qmt-tooltip-bubble--light .qmt-tooltip-supporting {
  color: var(--qmt-tooltip-desc-light, #737373);
}

/* Content */
.qmt-tooltip-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.qmt-tooltip-text {
  font-size: 13px;
  font-weight: 500;
  line-height: 18px;
  white-space: normal;
}

.qmt-tooltip-supporting {
  font-size: 12px;
  font-weight: 400;
  line-height: 16px;
  margin: 0;
  white-space: normal;
}

/* Arrow Pointer */
.qmt-tooltip-arrow {
  position: absolute;
  width: 0;
  height: 0;
  border-style: solid;
}

.qmt-tooltip-bubble--top .qmt-tooltip-arrow {
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
  border-width: 6px 6px 0 6px;
  border-color: var(--qmt-tooltip-bg-dark, #171717) transparent transparent transparent;
}

.qmt-tooltip-bubble--light.qmt-tooltip-bubble--top .qmt-tooltip-arrow {
  border-color: #ffffff transparent transparent transparent;
}

.qmt-tooltip-bubble--bottom .qmt-tooltip-arrow {
  bottom: 100%;
  left: 50%;
  transform: translateX(-50%);
  border-width: 0 6px 6px 6px;
  border-color: transparent transparent var(--qmt-tooltip-bg-dark, #171717) transparent;
}

.qmt-tooltip-bubble--light.qmt-tooltip-bubble--bottom .qmt-tooltip-arrow {
  border-color: transparent transparent #ffffff transparent;
}

.qmt-tooltip-bubble--left .qmt-tooltip-arrow {
  left: 100%;
  top: 50%;
  transform: translateY(-50%);
  border-width: 6px 0 6px 6px;
  border-color: transparent transparent transparent var(--qmt-tooltip-bg-dark, #171717);
}

.qmt-tooltip-bubble--light.qmt-tooltip-bubble--left .qmt-tooltip-arrow {
  border-color: transparent transparent transparent #ffffff;
}

.qmt-tooltip-bubble--right .qmt-tooltip-arrow {
  right: 100%;
  top: 50%;
  transform: translateY(-50%);
  border-width: 6px 6px 6px 0;
  border-color: transparent var(--qmt-tooltip-bg-dark, #171717) transparent transparent;
}

.qmt-tooltip-bubble--light.qmt-tooltip-bubble--right .qmt-tooltip-arrow {
  border-color: transparent #ffffff transparent transparent;
}

/* Transition Animations */
.qmt-tooltip-fade-enter-active,
.qmt-tooltip-fade-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}

.qmt-tooltip-fade-enter-from,
.qmt-tooltip-fade-leave-to {
  opacity: 0;
  transform: scale(0.95);
}

.qmt-tooltip-bubble--top.qmt-tooltip-fade-enter-from,
.qmt-tooltip-bubble--top.qmt-tooltip-fade-leave-to {
  transform: translate(-50%, 4px);
}

.qmt-tooltip-bubble--bottom.qmt-tooltip-fade-enter-from,
.qmt-tooltip-bubble--bottom.qmt-tooltip-fade-leave-to {
  transform: translate(-50%, -4px);
}
</style>
