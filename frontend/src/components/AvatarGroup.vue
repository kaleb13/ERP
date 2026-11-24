<!--
  Authoritative QMT AvatarGroup Component (Figma 3345:28608)
  ==============================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Multi-stakeholder rosters: Evaluation committees, tender opening boards, joint sign-off lists,
    multi-tier approval chains, shift rosters, and department member overviews.
  - Displays up to `max` (default 4) overlapping avatars with a clean +N overflow indicator pill.
  - Can be rendered inside table cells (`Table cell / Avatar group`), summary cards, or inspection headers.

  WHEN NOT TO USE:
  - DO NOT use for single employee profiles or individual users (use `BaseAvatar.vue` instead).
  - DO NOT use in standard form inputs or filter triggers.
-->
<script setup lang="ts">
import { computed } from 'vue';
import BaseAvatar from './BaseAvatar.vue';

interface AvatarItem {
  id?: string | number;
  src?: string;
  name?: string;
  text?: string;
  status?: 'online' | 'company' | 'busy' | 'offline' | boolean;
}

interface Props {
  /** Array of avatar items */
  items: AvatarItem[];
  /** Maximum number of avatars visible before +N pill */
  max?: number;
  /** Avatar dimension */
  size?: 'xs' | 'sm' | 'md' | 'lg';
}

const props = withDefaults(defineProps<Props>(), {
  max: 4,
  size: 'md'
});

const visibleItems = computed(() => {
  return props.items.slice(0, props.max);
});

const remainingCount = computed(() => {
  return Math.max(0, props.items.length - props.max);
});
</script>

<template>
  <div class="qmt-avatar-group" :class="`qmt-avatar-group--${size}`">
    <div 
      v-for="(item, index) in visibleItems" 
      :key="item.id || index"
      class="qmt-avatar-group__item"
    >
      <BaseAvatar
        :src="item.src"
        :name="item.name"
        :text="item.text"
        :size="size"
        :status="item.status"
      />
    </div>

    <!-- Remaining +N counter -->
    <div 
      v-if="remainingCount > 0" 
      class="qmt-avatar-group__item qmt-avatar-group__overflow"
    >
      <div 
        class="qmt-avatar-group__counter" 
        :class="`qmt-avatar-group__counter--${size}`"
      >
        +{{ remainingCount }}
      </div>
    </div>
  </div>
</template>

<style scoped>
.qmt-avatar-group {
  display: inline-flex;
  align-items: center;
  flex-direction: row;
}

.qmt-avatar-group__item {
  position: relative;
  border-radius: 9999px;
  box-shadow: 0 0 0 2px #ffffff;
  transition: transform 0.15s ease, z-index 0.15s ease;
}

.qmt-avatar-group__item:hover {
  transform: translateY(-2px);
  z-index: 10;
}

/* Overlap spacing */
.qmt-avatar-group--xs .qmt-avatar-group__item:not(:first-child) {
  margin-left: -6px;
}

.qmt-avatar-group--sm .qmt-avatar-group__item:not(:first-child) {
  margin-left: -8px;
}

.qmt-avatar-group--md .qmt-avatar-group__item:not(:first-child) {
  margin-left: -10px;
}

.qmt-avatar-group--lg .qmt-avatar-group__item:not(:first-child) {
  margin-left: -12px;
}

/* Counter pill */
.qmt-avatar-group__counter {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background-color: #f5f5f5;
  color: #404040;
  border-radius: 9999px;
  font-family: var(--qmt-font-family-sans, 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif);
  font-weight: 600;
  user-select: none;
}

.qmt-avatar-group__counter--xs {
  width: 24px;
  height: 24px;
  font-size: 10px;
}

.qmt-avatar-group__counter--sm {
  width: 32px;
  height: 32px;
  font-size: 11px;
}

.qmt-avatar-group__counter--md {
  width: 40px;
  height: 40px;
  font-size: 13px;
}

.qmt-avatar-group__counter--lg {
  width: 48px;
  height: 48px;
  font-size: 15px;
}
</style>
