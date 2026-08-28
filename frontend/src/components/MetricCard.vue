<script setup lang="ts">
import { MoreVertical, TrendingUp, TrendingDown } from 'lucide-vue-next';

withDefaults(
  defineProps<{
    label: string;
    value: string | number;
    subtext?: string;
    trend?: string;
    trendType?: 'up' | 'down' | 'neutral';
    showMenu?: boolean;
  }>(),
  {
    subtext: '',
    trend: '',
    trendType: 'up',
    showMenu: true
  }
);

defineEmits<{
  'menuClick': [];
}>();
</script>

<template>
  <div class="metric-card">
    <div class="metric-card-top">
      <span class="metric-label-uppercase">{{ label }}</span>
      <button v-if="showMenu" class="btn-more-options" title="More options" @click.stop="$emit('menuClick')">
        <MoreVertical :size="16" />
      </button>
    </div>

    <div class="metric-card-body">
      <span class="metric-value-large">{{ value }}</span>
    </div>

    <div v-if="subtext || trend" class="metric-card-bottom">
      <span v-if="subtext" class="metric-subtext">{{ subtext }}</span>
      <span v-if="trend" :class="['trend-badge', `trend-${trendType}`]">
        <TrendingUp v-if="trendType === 'up'" :size="12" />
        <TrendingDown v-else-if="trendType === 'down'" :size="12" />
        <span>{{ trend }}</span>
      </span>
    </div>
  </div>
</template>

<style scoped>
.metric-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 10px;
  transition: all 0.15s ease;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
  width: 100%;
}

.metric-card:hover {
  border-color: #cbd5e1;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.04);
}

.metric-card-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.metric-label-uppercase {
  font-size: 11.5px;
  font-weight: 700;
  color: #64748b;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.btn-more-options {
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 2px;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: color 0.15s ease;
}

.btn-more-options:hover {
  color: #0f172a;
  background-color: #f1f5f9;
}

.metric-card-body {
  display: flex;
  align-items: baseline;
}

.metric-value-large {
  font-size: 26px;
  font-weight: 800;
  color: #0f172a;
  letter-spacing: -0.02em;
  line-height: 1.1;
}

.metric-card-bottom {
  display: flex;
  align-items: center;
  gap: 8px;
}

.metric-subtext {
  font-size: 12px;
  color: #64748b;
}

.trend-badge {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 700;
}

.trend-up {
  background-color: #dcfce7;
  color: #15803d;
}

.trend-down {
  background-color: #ffe4e6;
  color: #be123c;
}

.trend-neutral {
  background-color: #f1f5f9;
  color: #475569;
}
</style>
