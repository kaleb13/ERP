<script setup lang="ts">
export interface ChartTooltipRow {
  label: string;
  value: string;
  color: string;
}

defineProps<{
  visible: boolean;
  title: string;
  rows: ChartTooltipRow[];
  x: number;
  y: number;
  align?: 'left' | 'right' | 'center';
}>();
</script>

<template>
  <Transition name="qmt-tooltip-fade">
    <div
      v-if="visible && rows.length > 0"
      class="qmt-chart-tooltip"
      :class="[`qmt-chart-tooltip--${align || 'center'}`]"
      :style="{ left: `${x}px`, top: `${y}px` }"
      role="tooltip"
    >
      <div v-if="title" class="qmt-tooltip-title">{{ title }}</div>
      <div class="qmt-tooltip-rows">
        <div v-for="(row, idx) in rows" :key="`${row.label}-${idx}`" class="qmt-tooltip-row">
          <span class="qmt-tooltip-key" :style="{ backgroundColor: row.color }"></span>
          <span class="qmt-tooltip-value">{{ row.value }}</span>
          <span class="qmt-tooltip-name">{{ row.label }}</span>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.qmt-chart-tooltip {
  position: absolute;
  z-index: 20;
  pointer-events: none;
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 6px;
  padding: 8px 10px;
  min-width: 120px;
  box-shadow: 0 4px 12px rgba(10, 13, 18, 0.08);
  display: flex;
  flex-direction: column;
  gap: 4px;
  transform: translate(-50%, -100%);
  margin-top: -10px;
  white-space: nowrap;
}

.qmt-chart-tooltip--left {
  transform: translate(0, -100%);
}

.qmt-chart-tooltip--right {
  transform: translate(-100%, -100%);
}

.qmt-tooltip-title {
  font-size: 12px;
  line-height: 18px;
  font-weight: 400;
  color: #737373;
}

.qmt-tooltip-rows {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.qmt-tooltip-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  line-height: 20px;
}

.qmt-tooltip-key {
  width: 12px;
  height: 2px;
  border-radius: 9999px;
  flex-shrink: 0;
}

.qmt-tooltip-value {
  font-weight: 600;
  color: #404040;
  font-variant-numeric: tabular-nums;
}

.qmt-tooltip-name {
  font-weight: 400;
  color: #737373;
}

.qmt-tooltip-fade-enter-active,
.qmt-tooltip-fade-leave-active {
  transition: opacity 120ms cubic-bezier(0.2, 0, 0, 1);
}

.qmt-tooltip-fade-enter-from,
.qmt-tooltip-fade-leave-to {
  opacity: 0;
}
</style>
