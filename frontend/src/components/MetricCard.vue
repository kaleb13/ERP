<script setup lang="ts">
import type { Component } from 'vue';
import { MoreVertical, TrendingUp, TrendingDown } from 'lucide-vue-next';

withDefaults(
  defineProps<{
    label: string;
    value: string | number;
    subtext?: string;
    trend?: string;
    trendType?: 'up' | 'down' | 'neutral';
    showMenu?: boolean;
    icon?: Component;
    size?: 'sm' | 'md' | 'lg';
  }>(),
  {
    subtext: '',
    trend: '',
    trendType: 'up',
    showMenu: true,
    size: 'md'
  }
);

defineEmits<{
  'menuClick': [];
}>();
</script>

<template>
  <div class="metric-card" :class="`metric-card--${size}`">
    <div class="metric-card-top">
      <div class="metric-label-group">
        <component :is="icon" v-if="icon" :size="size === 'sm' ? 14 : 15" class="metric-icon" />
        <span class="metric-label">{{ label }}</span>
      </div>
      <button 
        v-if="showMenu" 
        type="button"
        class="btn-more-options" 
        title="More options" 
        @click.stop="$emit('menuClick')"
      >
        <MoreVertical :size="15" />
      </button>
    </div>

    <div class="metric-card-body">
      <span class="metric-value">{{ value }}</span>
    </div>

    <div v-if="subtext || trend || $slots.bottom" class="metric-card-bottom">
      <slot name="bottom">
        <span v-if="subtext" class="metric-subtext">{{ subtext }}</span>
        <span v-if="trend" :class="['trend-badge', `trend-${trendType}`]">
          <TrendingUp v-if="trendType === 'up'" :size="11.5" />
          <TrendingDown v-else-if="trendType === 'down'" :size="11.5" />
          <span>{{ trend }}</span>
        </span>
      </slot>
    </div>
  </div>
</template>

<style scoped>
.metric-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  padding: 15px 18px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 10px;
  min-height: 106px;
  transition: all 0.15s ease;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
  width: 100%;
}

.metric-card:hover {
  border-color: #cbd5e1;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.04);
}

/* SIZES */
.metric-card--sm {
  padding: 12px 15px;
  gap: 6px;
  min-height: 94px;
}

.metric-card--md {
  padding: 15px 18px;
  gap: 10px;
  min-height: 106px;
}

.metric-card--lg {
  padding: 18px 22px;
  gap: 12px;
  min-height: 120px;
}

/* TOP ROW */
.metric-card-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.metric-label-group {
  display: flex;
  align-items: center;
  gap: 6px;
}

.metric-icon {
  color: #737373;
  flex-shrink: 0;
}

/* Top text: #737373 and medium weight */
.metric-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #737373;
  line-height: 1.2;
}

.btn-more-options {
  background: none;
  border: none;
  color: #a3a3a3;
  cursor: pointer;
  padding: 2.5px;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}

.btn-more-options:hover {
  color: #404040;
  background-color: #f5f5f5;
}

/* CENTER / MAIN TEXT: #404040 and semi-bold weight */
.metric-card-body {
  display: flex;
  align-items: baseline;
}

.metric-value {
  font-size: 24px;
  font-weight: 600;
  color: #404040;
  letter-spacing: -0.02em;
  line-height: 1.15;
}

.metric-card--lg .metric-value {
  font-size: 28px;
}

/* BOTTOM TEXT: #737373 and medium weight */
.metric-card-bottom {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.metric-subtext {
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  line-height: 1.2;
}

/* Trend Badges */
.trend-badge {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  padding: 2px 7px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
  line-height: 1.2;
}

.trend-up {
  background-color: #dcfce7;
  color: #15803d;
}

.trend-down {
  background-color: #fee2e2;
  color: #b91c1c;
}

.trend-neutral {
  background-color: #f5f5f5;
  color: #737373;
}
</style>
