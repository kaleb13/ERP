<!--
  Authoritative QMT UnderlineTabs Component (Figma 5578:110)
  ==============================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Secondary (Level 2) sub-navigation inside dossier inspection cards:
    e.g., inside an Employee Dossier card to switch between `Personal Details`, `Job History`, `Compensation`, `Documents`.
  - Consecutive / Two-Tier tab layouts: When two levels of tabs appear consecutively,
    Level 1 is ALWAYS Primary (`BaseTabs` with `type="rounded"`), and Level 2 directly underneath is `UnderlineTabs`.

  WHEN NOT TO USE:
  - DO NOT use as the top-level page tab bar (Top-level tabs MUST ALWAYS use `BaseTabs` capsule standard).
  - DO NOT use for Tabular Create Forms (Master Details vs Child Roster MUST use `BaseTabs type="rounded"`).
  - DO NOT use as an isolated single tab bar on a page.
-->
<script setup lang="ts" generic="T extends string | number">
import { ref, onMounted, onUnmounted, watch, nextTick, type Component } from 'vue';
import { ChevronLeft, ChevronRight } from 'lucide-vue-next';

export interface UnderlineTabItem<IdType = T> {
  id: IdType;
  label: string;
  count?: number | string;
  icon?: Component;
  badge?: string;
  badgeVariant?: 'default' | 'success' | 'warning' | 'danger' | 'info' | 'primary';
  disabled?: boolean;
  tooltip?: string;
  customClass?: string;
}

const props = withDefaults(
  defineProps<{
    /** Currently active tab id (use with v-model). */
    modelValue: T;
    /** Tabs array with label, optional count, icon, and badge. */
    tabs: UnderlineTabItem<T>[];
    /** Visual size. `sm` (36px), `md` (40px standard default), `lg` (44px prominent). */
    size?: 'sm' | 'md' | 'lg';
    /** Color scheme. `brand` (#0b529c with #e1eefd active bg) or `light` (neutral). */
    color?: 'brand' | 'light';
    /** Whether tabs expand to fill 100% width. */
    fullWidth?: boolean;
    /** Alignment of tabs: `start` (default), `center`, `end`, `between`. */
    justify?: 'start' | 'center' | 'end' | 'between';
    /** Whether to show the bottom border line across the bar. */
    showBottomBorder?: boolean;
    /** Whether to show count badges on tabs. Defaults to true. */
    showCount?: boolean;
    /** Whether to display scroll indicator arrows when tabs overflow horizontally. Defaults to true. */
    showScrollArrows?: boolean;
  }>(),
  {
    size: 'md',
    color: 'brand',
    fullWidth: false,
    justify: 'start',
    showBottomBorder: true,
    showCount: true,
    showScrollArrows: true
  }
);

const emit = defineEmits<{
  'update:modelValue': [value: T];
  'tab-click': [tab: UnderlineTabItem<T>];
}>();

const tabsRef = ref<HTMLElement | null>(null);
const canScrollLeft = ref(false);
const canScrollRight = ref(false);

const updateScrollState = () => {
  const el = tabsRef.value;
  if (!el) {
    canScrollLeft.value = false;
    canScrollRight.value = false;
    return;
  }
  const scrollLeft = Math.ceil(el.scrollLeft);
  const maxScrollLeft = el.scrollWidth - el.clientWidth;
  canScrollLeft.value = scrollLeft > 2;
  canScrollRight.value = maxScrollLeft - scrollLeft > 2;
};

const scrollTabs = (direction: 'left' | 'right') => {
  const el = tabsRef.value;
  if (!el) return;
  const offset = direction === 'left' ? -180 : 180;
  el.scrollBy({ left: offset, behavior: 'smooth' });
};

const handleTabClick = (tab: UnderlineTabItem<T>) => {
  if (!tab.disabled) {
    emit('update:modelValue', tab.id);
    emit('tab-click', tab);
  }
};

const scrollActiveIntoView = () => {
  nextTick(() => {
    const el = tabsRef.value;
    if (!el) return;
    const activeEl = el.querySelector<HTMLElement>('.qmt-underline-tab.active');
    if (activeEl) {
      activeEl.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'nearest' });
    }
    updateScrollState();
  });
};

let resizeObserver: ResizeObserver | null = null;

onMounted(() => {
  nextTick(() => {
    updateScrollState();
  });
  if (tabsRef.value && typeof ResizeObserver !== 'undefined') {
    resizeObserver = new ResizeObserver(() => {
      updateScrollState();
    });
    resizeObserver.observe(tabsRef.value);
  }
});

onUnmounted(() => {
  if (resizeObserver) {
    resizeObserver.disconnect();
  }
});

watch(
  () => props.modelValue,
  () => {
    scrollActiveIntoView();
  }
);

watch(
  () => props.tabs,
  () => {
    nextTick(() => {
      updateScrollState();
    });
  },
  { deep: true }
);
</script>

<template>
  <div 
    class="qmt-tabs-container"
    :class="{ 'has-bottom-border': showBottomBorder }"
  >
    <!-- Left Scroll Arrow Button -->
    <button 
      v-if="showScrollArrows && canScrollLeft" 
      type="button" 
      class="qmt-tab-scroll-btn qmt-tab-scroll-btn--left" 
      aria-label="Scroll tabs left"
      title="Scroll tabs left"
      @click="scrollTabs('left')"
    >
      <ChevronLeft :size="15" />
    </button>

    <!-- Scrollable Tab Strip -->
    <div 
      ref="tabsRef" 
      class="qmt-underline-tabs"
      :class="[
        `justify-${justify}`,
        { 'qmt-underline-tabs--full': fullWidth }
      ]"
      @scroll.passive="updateScrollState"
    >
      <!-- Optional Prefix Slot inside tabs list -->
      <slot name="prefix" />

      <!-- Individual Tab Buttons (Figma Node 5577:151) -->
      <button
        v-for="tab in tabs"
        :key="tab.id"
        type="button"
        :disabled="tab.disabled"
        :title="tab.tooltip"
        :class="[
          'qmt-underline-tab',
          `qmt-underline-tab--${size}`,
          `qmt-underline-tab--${color}`,
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
            class="qmt-tab-icon" 
          />

          <!-- Label -->
          <span class="qmt-tab-label">{{ tab.label }}</span>

          <!-- Count Badge (Figma QMT Tab Badge Node 5594:966) -->
          <span 
            v-if="showCount && tab.count !== undefined" 
            class="qmt-tab-count-badge"
            :class="{ 'count-active': modelValue === tab.id }"
          >
            {{ tab.count }}
          </span>

          <!-- Text Badge -->
          <span 
            v-if="tab.badge" 
            :class="[
              'qmt-tab-text-badge',
              `badge-variant-${tab.badgeVariant || 'primary'}`
            ]"
          >
            {{ tab.badge }}
          </span>
        </slot>

        <!-- Active Bottom Brand Indicator Line (Figma Node 5594:969) -->
        <div v-if="modelValue === tab.id" class="qmt-active-indicator" />
      </button>

      <!-- Optional Suffix Slot inside tabs list -->
      <slot name="suffix" />
    </div>

    <!-- Right Scroll Arrow Button -->
    <button 
      v-if="showScrollArrows && canScrollRight" 
      type="button" 
      class="qmt-tab-scroll-btn qmt-tab-scroll-btn--right" 
      aria-label="Scroll tabs right"
      title="Scroll tabs right"
      @click="scrollTabs('right')"
    >
      <ChevronRight :size="15" />
    </button>

    <!-- Right Actions Slot -->
    <div v-if="$slots.right" class="qmt-underline-tabs-right">
      <slot name="right" />
    </div>
  </div>
</template>

<style scoped>
/* QMT Underline Tabs Container: Figma Node 3345:29280 / 5577:151 */
.qmt-tabs-container {
  display: flex;
  align-items: center;
  width: 100%;
  position: relative;
  min-width: 0;
  font-family: var(--qmt-font-family-sans, 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif);
}

.qmt-tabs-container.has-bottom-border {
  border-bottom: 1px solid var(--qmt-tab-border-color, #e5e5e5);
}

/* Scroll Arrow Controls */
.qmt-tab-scroll-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  border: 1px solid #e5e5e5;
  background-color: #ffffff;
  color: #737373;
  cursor: pointer;
  flex-shrink: 0;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  transition: all 0.15s ease;
  z-index: 10;
  padding: 0;
}

.qmt-tab-scroll-btn:hover {
  background-color: #f5f5f5;
  color: #171717;
  border-color: #d4d4d4;
}

.qmt-tab-scroll-btn--left {
  margin-right: 6px;
}

.qmt-tab-scroll-btn--right {
  margin-left: 6px;
}

.qmt-underline-tabs {
  display: flex;
  align-items: center;
  gap: var(--qmt-tab-gap, 0px);
  overflow-x: auto;
  user-select: none;
  scrollbar-width: none;
  scroll-behavior: smooth;
  flex: 1;
  min-width: 0;
}

.qmt-underline-tabs::-webkit-scrollbar {
  display: none;
}

.qmt-underline-tabs--full {
  width: 100%;
}

.justify-start { justify-content: flex-start; }
.justify-center { justify-content: center; }
.justify-end { justify-content: flex-end; }
.justify-between { justify-content: space-between; }

/* QMT Tab Base (Figma Node 5577:151) */
.qmt-underline-tab {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  border: none;
  background: transparent;
  color: var(--qmt-tab-fg, #737373);
  cursor: pointer;
  white-space: nowrap;
  transition: background-color 0.15s ease, color 0.15s ease;
  outline: none;
  text-decoration: none;
  border-radius: 6px 6px 0 0;
  box-sizing: border-box;
}

/* Sizes */
.qmt-underline-tab--sm {
  height: var(--qmt-tab-sm-height, 36px);
  padding: 0 var(--qmt-tab-sm-padding-x, 12px);
  font-size: var(--qmt-tab-sm-font-size, 13px);
  font-weight: 600;
  line-height: 18px;
}

.qmt-underline-tab--md {
  height: var(--qmt-tab-md-height, 40px);
  padding: 0 var(--qmt-tab-md-padding-x, 14px);
  font-size: var(--qmt-tab-md-font-size, 14px);
  font-weight: 600;
  line-height: 20px;
}

.qmt-underline-tab--lg {
  height: var(--qmt-tab-lg-height, 44px);
  padding: 0 var(--qmt-tab-lg-padding-x, 16px);
  font-size: var(--qmt-tab-lg-font-size, 15px);
  font-weight: 600;
  line-height: 22px;
}

/* Hover State */
.qmt-underline-tab:hover:not(.is-disabled) {
  background-color: var(--qmt-tab-bg-hover, #f5f5f5);
  color: var(--qmt-tab-fg-hover, #404040);
}

/* Brand Color Scheme Active (Figma 5577:151: bg #e1eefd, text #0b529c) */
.qmt-underline-tab--brand.active {
  background-color: var(--qmt-tab-brand-bg-current, #e1eefd);
  color: var(--qmt-tab-brand-fg-current, #0b529c);
  font-weight: 600;
}

/* Light Color Scheme Active */
.qmt-underline-tab--light.active {
  background-color: transparent;
  color: var(--qmt-tab-light-fg-current, #171717);
  font-weight: 600;
}

.qmt-underline-tab.is-disabled {
  opacity: 0.45;
  cursor: not-allowed;
  pointer-events: none;
}

.qmt-tab-icon {
  color: currentColor;
  flex-shrink: 0;
}

.qmt-tab-label {
  font-family: inherit;
  font-weight: 600;
  white-space: nowrap;
}

/* Active Bottom Indicator Line (Figma Node 5594:969) */
.qmt-active-indicator {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 2px;
  background-color: var(--qmt-tab-brand-indicator, #0b529c);
  border-radius: 2px 2px 0 0;
  z-index: 2;
}

.qmt-underline-tab--light .qmt-active-indicator {
  background-color: var(--qmt-tab-light-indicator, #171717);
}

/* Count Badges (Figma Node 5594:966 / I5594:966;3345:21149) */
.qmt-tab-count-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
  line-height: 18px;
  padding: 2px 8px;
  border-radius: 9999px;
  background-color: var(--qmt-badge-gray-bg, #f5f5f5);
  color: var(--qmt-badge-gray-fg, #404040);
  transition: all 0.15s ease;
}

.qmt-underline-tab--brand.active .qmt-tab-count-badge {
  background-color: var(--qmt-badge-brand-bg, #e1eefd);
  color: var(--qmt-badge-brand-fg, #0b529c);
}

/* Text Badges */
.qmt-tab-text-badge {
  font-size: 11px;
  font-weight: 600;
  padding: 1.5px 6px;
  border-radius: 9999px;
  text-transform: uppercase;
  letter-spacing: 0.02em;
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
  background-color: #dff2fe;
  color: #0069a8;
}

.qmt-underline-tabs-right {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
  margin-left: 16px;
}
</style>
