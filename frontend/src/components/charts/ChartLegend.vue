<script setup lang="ts">
export interface ChartLegendItem {
  label: string;
  color: string;
  value?: string;
  share?: string;
}

const props = withDefaults(
  defineProps<{
    items: ChartLegendItem[];
    mark?: 'line' | 'square' | 'circle';
    direction?: 'horizontal' | 'vertical';
    activeIndex?: number | null;
  }>(),
  {
    mark: 'square',
    direction: 'horizontal',
    activeIndex: null
  }
);

const emit = defineEmits<{
  (e: 'hover', index: number | null): void;
}>();
</script>

<template>
  <ul
    class="qmt-chart-legend"
    :class="[`qmt-chart-legend--${direction}`]"
    role="list"
  >
    <li
      v-for="(item, idx) in items"
      :key="`${item.label}-${idx}`"
      class="qmt-legend-item"
      :class="{
        'is-dimmed': activeIndex !== null && activeIndex !== idx,
        'is-active': activeIndex === idx
      }"
      @mouseenter="emit('hover', idx)"
      @mouseleave="emit('hover', null)"
    >
      <span class="qmt-legend-left">
        <span
          class="qmt-legend-swatch"
          :class="[`qmt-legend-swatch--${mark}`]"
          :style="{ backgroundColor: item.color }"
          aria-hidden="true"
        ></span>
        <span class="qmt-legend-label">{{ item.label }}</span>
      </span>

      <span v-if="item.value || item.share" class="qmt-legend-meta">
        <span v-if="item.value" class="qmt-legend-value">{{ item.value }}</span>
        <span v-if="item.share" class="qmt-legend-share">{{ item.share }}</span>
      </span>
    </li>
  </ul>
</template>

<style scoped>
.qmt-chart-legend {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-wrap: wrap;
  gap: 8px 16px;
}

.qmt-chart-legend--vertical {
  flex-direction: column;
  flex-wrap: nowrap;
  gap: 10px;
  width: 100%;
}

.qmt-legend-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  font-size: 13px;
  line-height: 20px;
  color: #404040;
  cursor: default;
  transition: opacity 150ms cubic-bezier(0.2, 0, 0, 1);
}

.qmt-legend-item.is-dimmed {
  opacity: 0.4;
}

.qmt-legend-left {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}

.qmt-legend-swatch {
  flex-shrink: 0;
  display: inline-block;
}

.qmt-legend-swatch--line {
  width: 14px;
  height: 2px;
  border-radius: 9999px;
}

.qmt-legend-swatch--square {
  width: 10px;
  height: 10px;
  border-radius: 2px;
}

.qmt-legend-swatch--circle {
  width: 9px;
  height: 9px;
  border-radius: 9999px;
}

.qmt-legend-label {
  color: #404040;
  font-weight: 400;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.qmt-legend-meta {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
  font-variant-numeric: tabular-nums;
}

.qmt-legend-value {
  color: #404040;
  font-weight: 500;
}

.qmt-legend-share {
  color: #737373;
  font-weight: 400;
  min-width: 38px;
  text-align: right;
}
</style>
