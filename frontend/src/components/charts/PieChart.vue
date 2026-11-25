<script setup lang="ts">
import { ref, computed } from 'vue';
import { Table2, PieChart as PieChartIcon } from 'lucide-vue-next';
import ChartLegend, { type ChartLegendItem } from './ChartLegend.vue';
import ChartTooltip, { type ChartTooltipRow } from './ChartTooltip.vue';
import {
  type ChartPalette,
  getChartSeriesColor,
  defaultValueFormat
} from './chartTokens';

export interface PieChartSlice {
  label: string;
  value: number;
  isOther?: boolean;
  color?: string;
}

const props = withDefaults(
  defineProps<{
    title: string;
    subtitle?: string;
    slices: PieChartSlice[];
    variant?: 'pie' | 'donut';
    palette?: ChartPalette;
    centerLabel?: string;
    centerValue?: string;
    valueFormatter?: (value: number) => string;
    showTableToggle?: boolean;
    size?: number;
    bare?: boolean;
    emptyText?: string;
  }>(),
  {
    subtitle: '',
    variant: 'donut',
    palette: 'brand',
    centerLabel: 'Total',
    centerValue: undefined,
    valueFormatter: undefined,
    showTableToggle: true,
    size: 176,
    bare: false,
    emptyText: 'No distribution data available.'
  }
);

const viewMode = ref<'chart' | 'table'>('chart');
const hoveredIdx = ref<number | null>(null);
const plotRef = ref<HTMLDivElement | null>(null);
const tooltipPos = ref({ x: 0, y: 0 });

const formatVal = (v: number) =>
  props.valueFormatter ? props.valueFormatter(v) : defaultValueFormat(v);

// QMT rule: up to 4 coloured slices + 1 muted "Other" bucket
const normalizedSlices = computed(() => {
  const positive = props.slices.filter((s) => s.value > 0);
  if (positive.length <= 5) return positive;
  const top4 = positive.slice(0, 4);
  const restSum = positive.slice(4).reduce((acc, s) => acc + s.value, 0);
  return [...top4, { label: 'Other', value: restSum, isOther: true }];
});

const totalValue = computed(() =>
  normalizedSlices.value.reduce((acc, s) => acc + s.value, 0)
);

const hasData = computed(() => totalValue.value > 0);

const computedSlices = computed(() => {
  const total = totalValue.value || 1;
  const cx = props.size / 2;
  const cy = props.size / 2;
  const outerR = props.size / 2 - 4;
  const innerR = props.variant === 'donut' ? outerR * 0.62 : 0;

  let startAngle = -Math.PI / 2;

  return normalizedSlices.value.map((slice, idx) => {
    const share = slice.value / total;
    const angle = Math.min(Math.PI * 1.9999, share * Math.PI * 2);
    const endAngle = startAngle + angle;
    const largeArc = angle > Math.PI ? 1 : 0;

    const x1 = cx + outerR * Math.cos(startAngle);
    const y1 = cy + outerR * Math.sin(startAngle);
    const x2 = cx + outerR * Math.cos(endAngle);
    const y2 = cy + outerR * Math.sin(endAngle);

    let d = '';
    if (innerR > 0) {
      const ix1 = cx + innerR * Math.cos(endAngle);
      const iy1 = cy + innerR * Math.sin(endAngle);
      const ix2 = cx + innerR * Math.cos(startAngle);
      const iy2 = cy + innerR * Math.sin(startAngle);
      d = [
        `M ${x1.toFixed(2)} ${y1.toFixed(2)}`,
        `A ${outerR} ${outerR} 0 ${largeArc} 1 ${x2.toFixed(2)} ${y2.toFixed(2)}`,
        `L ${ix1.toFixed(2)} ${iy1.toFixed(2)}`,
        `A ${innerR} ${innerR} 0 ${largeArc} 0 ${ix2.toFixed(2)} ${iy2.toFixed(2)}`,
        'Z'
      ].join(' ');
    } else {
      d = [
        `M ${cx} ${cy}`,
        `L ${x1.toFixed(2)} ${y1.toFixed(2)}`,
        `A ${outerR} ${outerR} 0 ${largeArc} 1 ${x2.toFixed(2)} ${y2.toFixed(2)}`,
        'Z'
      ].join(' ');
    }

    const midAngle = startAngle + angle / 2;
    const midR = innerR > 0 ? (outerR + innerR) / 2 : outerR * 0.6;
    const midX = cx + midR * Math.cos(midAngle);
    const midY = cy + midR * Math.sin(midAngle);

    startAngle = endAngle;

    return {
      ...slice,
      idx,
      sharePct: `${(share * 100).toFixed(1)}%`,
      color: getChartSeriesColor(props.palette, idx, {
        isOther: slice.isOther,
        customColor: slice.color
      }),
      d,
      midX,
      midY
    };
  });
});

const legendItems = computed<ChartLegendItem[]>(() =>
  computedSlices.value.map((s) => ({
    label: s.label,
    color: s.color,
    value: formatVal(s.value),
    share: s.sharePct
  }))
);

function handleSliceHover(idx: number) {
  hoveredIdx.value = idx;
  const s = computedSlices.value[idx];
  if (s) {
    tooltipPos.value = { x: s.midX, y: s.midY };
  }
}

const tooltipRows = computed<ChartTooltipRow[]>(() => {
  if (hoveredIdx.value === null) return [];
  const s = computedSlices.value[hoveredIdx.value];
  if (!s) return [];
  return [
    {
      label: s.sharePct,
      value: formatVal(s.value),
      color: s.color
    }
  ];
});
</script>

<template>
  <div class="qmt-chart-card" :class="{ 'qmt-chart-card--bare': bare }">
    <div class="qmt-chart-header">
      <div class="qmt-chart-heading">
        <h3 class="qmt-chart-title">{{ title }}</h3>
        <p v-if="subtitle" class="qmt-chart-subtitle">{{ subtitle }}</p>
      </div>
      <div class="qmt-chart-header-actions">
        <slot name="actions"></slot>
        <button
          v-if="showTableToggle && hasData"
          type="button"
          class="qmt-chart-toggle-btn"
          :class="{ 'is-active': viewMode === 'table' }"
          :title="viewMode === 'table' ? 'Switch to chart view' : 'Switch to table view'"
          :aria-label="viewMode === 'table' ? 'Switch to chart view' : 'Switch to table view'"
          @click="viewMode = viewMode === 'chart' ? 'table' : 'chart'"
        >
          <PieChartIcon v-if="viewMode === 'table'" :size="15" />
          <Table2 v-else :size="15" />
        </button>
      </div>
    </div>

    <div v-if="!hasData" class="qmt-chart-empty">
      <slot name="empty">
        <span>{{ emptyText }}</span>
      </slot>
    </div>

    <!-- Accessible QMT Data Table Mode -->
    <div v-else-if="viewMode === 'table'" class="qmt-chart-table-wrap">
      <table class="qmt-chart-table">
        <thead>
          <tr>
            <th>Segment</th>
            <th class="is-num">Value</th>
            <th class="is-num">Share</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="s in computedSlices" :key="s.label">
            <td>{{ s.label }}</td>
            <td class="is-num">{{ formatVal(s.value) }}</td>
            <td class="is-num">{{ s.sharePct }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Side-by-Side Pie/Donut + Vertical Legend (QMT Spec) -->
    <div v-else class="qmt-pie-layout">
      <div
        ref="plotRef"
        class="qmt-pie-plot"
        :style="{ width: `${size}px`, height: `${size}px` }"
        @mouseleave="hoveredIdx = null"
      >
        <svg
          :width="size"
          :height="size"
          :viewBox="`0 0 ${size} ${size}`"
          class="qmt-pie-svg"
          role="img"
          :aria-label="title"
        >
          <path
            v-for="s in computedSlices"
            :key="`slice-${s.idx}`"
            :d="s.d"
            :fill="s.color"
            stroke="#FFFFFF"
            stroke-width="2"
            stroke-linejoin="round"
            class="qmt-pie-slice"
            :class="{ 'is-dimmed': hoveredIdx !== null && hoveredIdx !== s.idx }"
            @mouseenter="handleSliceHover(s.idx)"
          />
          <g v-if="variant === 'donut'" class="qmt-donut-center">
            <text
              :x="size / 2"
              :y="size / 2 - 2"
              text-anchor="middle"
              class="qmt-donut-total"
            >
              {{ centerValue ?? formatVal(totalValue) }}
            </text>
            <text
              :x="size / 2"
              :y="size / 2 + 16"
              text-anchor="middle"
              class="qmt-donut-label"
            >
              {{ centerLabel }}
            </text>
          </g>
        </svg>

        <ChartTooltip
          :visible="hoveredIdx !== null"
          :title="hoveredIdx !== null ? computedSlices[hoveredIdx]?.label ?? '' : ''"
          :rows="tooltipRows"
          :x="tooltipPos.x"
          :y="tooltipPos.y"
        />
      </div>

      <div class="qmt-pie-legend-col">
        <ChartLegend
          :items="legendItems"
          mark="circle"
          direction="vertical"
          :active-index="hoveredIdx"
          @hover="hoveredIdx = $event"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.qmt-chart-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  min-width: 0;
}

.qmt-chart-card--bare {
  border: none;
  border-radius: 0;
  padding: 0;
}

.qmt-chart-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.qmt-chart-heading {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.qmt-chart-title {
  margin: 0;
  font-size: 16px;
  line-height: 24px;
  font-weight: 600;
  color: #404040;
}

.qmt-chart-subtitle {
  margin: 0;
  font-size: 13px;
  line-height: 20px;
  font-weight: 400;
  color: #737373;
}

.qmt-chart-header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

.qmt-chart-toggle-btn {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: 1px solid #e5e5e5;
  background-color: #ffffff;
  color: #737373;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background-color 150ms ease, color 150ms ease, border-color 150ms ease;
}

.qmt-chart-toggle-btn:hover,
.qmt-chart-toggle-btn.is-active {
  background-color: #fafafa;
  border-color: #d4d4d4;
  color: #404040;
}

.qmt-pie-layout {
  display: flex;
  align-items: center;
  gap: 28px;
  flex-wrap: wrap;
}

.qmt-pie-plot {
  position: relative;
  flex-shrink: 0;
}

.qmt-pie-svg {
  display: block;
  overflow: visible;
}

.qmt-pie-slice {
  cursor: pointer;
  transition: opacity 150ms cubic-bezier(0.2, 0, 0, 1);
}

.qmt-pie-slice.is-dimmed {
  opacity: 0.35;
}

.qmt-donut-total {
  font-size: 20px;
  font-weight: 600;
  fill: #404040;
  font-variant-numeric: tabular-nums;
}

.qmt-donut-label {
  font-size: 12px;
  font-weight: 400;
  fill: #737373;
}

.qmt-pie-legend-col {
  flex: 1;
  min-width: 180px;
}

.qmt-chart-empty {
  min-height: 176px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  color: #737373;
  font-size: 13.5px;
  background-color: #fafafa;
  border: 1px dashed #e5e5e5;
  border-radius: 12px;
  padding: 24px;
}

.qmt-chart-table-wrap {
  border: 1px solid #e5e5e5;
  border-radius: 10px;
  overflow: hidden;
}

.qmt-chart-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.qmt-chart-table thead th {
  background-color: #fafafa;
  border-bottom: 1px solid #e5e5e5;
  padding: 10px 14px;
  text-align: left;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
}

.qmt-chart-table tbody td {
  padding: 10px 14px;
  border-bottom: 1px solid #f0f0f0;
  color: #404040;
}

.qmt-chart-table tbody tr:last-child td {
  border-bottom: none;
}

.qmt-chart-table th.is-num,
.qmt-chart-table td.is-num {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
</style>
