<script setup lang="ts">
import { ref, computed } from 'vue';
import { Table2, TrendingUp } from 'lucide-vue-next';
import ChartLegend, { type ChartLegendItem } from './ChartLegend.vue';
import ChartTooltip, { type ChartTooltipRow } from './ChartTooltip.vue';
import {
  type ChartPalette,
  QMT_CHART_TOKENS,
  getChartSeriesColor,
  computeNiceTicks,
  defaultValueFormat
} from './chartTokens';

export interface LineChartSeries {
  name: string;
  data: number[];
  color?: string;
}

const props = withDefaults(
  defineProps<{
    title: string;
    subtitle?: string;
    categories: string[];
    series: LineChartSeries[];
    variant?: 'line' | 'area';
    palette?: ChartPalette;
    minValue?: number;
    maxValue?: number;
    valueFormatter?: (value: number) => string;
    referenceLine?: { value: number; label?: string };
    showTableToggle?: boolean;
    height?: number;
    bare?: boolean;
    emptyText?: string;
  }>(),
  {
    subtitle: '',
    variant: 'area',
    palette: 'brand',
    minValue: 0,
    maxValue: undefined,
    valueFormatter: undefined,
    referenceLine: undefined,
    showTableToggle: true,
    height: 236,
    bare: false,
    emptyText: 'No trend data available.'
  }
);

const viewMode = ref<'chart' | 'table'>('chart');
const hoveredIdx = ref<number | null>(null);
const hoveredSeriesIdx = ref<number | null>(null);
const plotRef = ref<HTMLDivElement | null>(null);

const formatVal = (v: number) =>
  props.valueFormatter ? props.valueFormatter(v) : defaultValueFormat(v);

const hasData = computed(
  () => props.categories.length > 0 && props.series.length > 0 && props.series.some((s) => s.data.length > 0)
);

const effectiveSeries = computed(() => props.series.slice(0, 3));

const seriesColors = computed(() =>
  effectiveSeries.value.map((s, idx) =>
    getChartSeriesColor(props.palette, idx, { customColor: s.color })
  )
);

const legendItems = computed<ChartLegendItem[]>(() =>
  effectiveSeries.value.map((s, idx) => ({
    label: s.name,
    color: seriesColors.value[idx]
  }))
);

const showLegend = computed(() => effectiveSeries.value.length > 1);

const axisScale = computed(() => {
  let rawMax = props.minValue + 1;
  for (const s of effectiveSeries.value) {
    for (const v of s.data) {
      if (Number(v) > rawMax) rawMax = Number(v);
    }
  }
  return computeNiceTicks(rawMax, {
    min: props.minValue,
    max: props.maxValue,
    tickCount: 5
  });
});

// ─── SVG Geometry (Matches QMT 560px Plot Width) ─────────────────────────────
const svgWidth = 560;
const svgHeight = computed(() => props.height);
const pad = { top: 14, right: 24, bottom: 26, left: 30 };
const plotW = svgWidth - pad.left - pad.right;
const plotH = computed(() => svgHeight.value - pad.top - pad.bottom);

function getX(cIdx: number): number {
  const n = props.categories.length;
  if (n <= 1) return pad.left + plotW / 2;
  return pad.left + (cIdx / (n - 1)) * plotW;
}

function getY(val: number): number {
  const span = Math.max(1, axisScale.value.max - axisScale.value.min);
  const ratio = (val - axisScale.value.min) / span;
  return pad.top + plotH.value - ratio * plotH.value;
}

const plottedSeries = computed(() =>
  effectiveSeries.value.map((s, sIdx) => {
    const pts = props.categories.map((_, cIdx) => {
      const val = Number(s.data[cIdx]) || 0;
      return { x: getX(cIdx), y: getY(val), val, cIdx };
    });

    const linePath = pts
      .map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x.toFixed(1)} ${p.y.toFixed(1)}`)
      .join(' ');

    const baselineY = pad.top + plotH.value;
    const areaPath =
      pts.length > 1
        ? `${linePath} L ${pts[pts.length - 1].x.toFixed(1)} ${baselineY.toFixed(1)} L ${pts[0].x.toFixed(1)} ${baselineY.toFixed(1)} Z`
        : '';

    return {
      name: s.name,
      color: seriesColors.value[sIdx],
      pts,
      linePath,
      areaPath
    };
  })
);

const referenceY = computed(() =>
  props.referenceLine ? getY(props.referenceLine.value) : null
);

const hitSlices = computed(() => {
  const n = props.categories.length;
  if (n === 0) return [];
  if (n === 1) {
    return [{ cIdx: 0, x: pad.left, w: plotW }];
  }
  const step = plotW / (n - 1);
  return props.categories.map((_, cIdx) => {
    const cx = getX(cIdx);
    const x = cIdx === 0 ? pad.left : cx - step / 2;
    const w = cIdx === 0 || cIdx === n - 1 ? step / 2 : step;
    return { cIdx, x, w };
  });
});

const tooltipPosition = computed(() => {
  if (hoveredIdx.value === null || !plotRef.value) {
    return { x: 0, y: 0, align: 'center' as 'left' | 'right' | 'center' };
  }
  const rect = plotRef.value.getBoundingClientRect();
  const scaleX = rect.width / svgWidth;
  const scaleY = rect.height / svgHeight.value;
  const px = getX(hoveredIdx.value) * scaleX;
  const topY = Math.min(
    ...plottedSeries.value.map((s) => s.pts[hoveredIdx.value!]?.y ?? pad.top)
  );
  const py = Math.max(24, topY * scaleY - 4);
  let align: 'left' | 'right' | 'center' = 'center';
  if (px < 90) align = 'left';
  else if (px > rect.width - 90) align = 'right';
  return { x: px, y: py, align };
});

const tooltipRows = computed<ChartTooltipRow[]>(() => {
  if (hoveredIdx.value === null) return [];
  const idx = hoveredIdx.value;
  return plottedSeries.value.map((s) => ({
    label: s.name,
    value: formatVal(s.pts[idx]?.val ?? 0),
    color: s.color
  }));
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
          <TrendingUp v-if="viewMode === 'table'" :size="15" />
          <Table2 v-else :size="15" />
        </button>
      </div>
    </div>

    <ChartLegend
      v-if="showLegend && hasData && viewMode === 'chart'"
      :items="legendItems"
      mark="line"
      direction="horizontal"
      :active-index="hoveredSeriesIdx"
      @hover="hoveredSeriesIdx = $event"
    />

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
            <th>Period</th>
            <th v-for="s in effectiveSeries" :key="s.name" class="is-num">{{ s.name }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(cat, cIdx) in categories" :key="cat">
            <td>{{ cat }}</td>
            <td v-for="s in effectiveSeries" :key="s.name" class="is-num">
              {{ formatVal(Number(s.data[cIdx]) || 0) }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Interactive SVG Chart Mode -->
    <div
      v-else
      ref="plotRef"
      class="qmt-chart-plot"
      @mouseleave="hoveredIdx = null"
    >
      <svg
        :viewBox="`0 0 ${svgWidth} ${svgHeight}`"
        class="qmt-chart-svg"
        role="img"
        :aria-label="title"
      >
        <!-- Horizontal Gridlines & Y Ticks -->
        <g v-for="tick in axisScale.ticks" :key="`lt-${tick}`">
          <line
            :x1="pad.left"
            :x2="svgWidth - pad.right"
            :y1="getY(tick)"
            :y2="getY(tick)"
            :stroke="tick === axisScale.min ? QMT_CHART_TOKENS.axis : QMT_CHART_TOKENS.grid"
            stroke-width="1"
          />
          <text
            :x="pad.left - 8"
            :y="getY(tick) + 4"
            text-anchor="end"
            class="qmt-axis-tick"
          >
            {{ tick }}
          </text>
        </g>

        <!-- Optional Target / Benchmark Dashed Line -->
        <g v-if="referenceLine && referenceY !== null">
          <line
            :x1="pad.left"
            :x2="svgWidth - pad.right"
            :y1="referenceY"
            :y2="referenceY"
            stroke="#a3a3a3"
            stroke-width="1"
            stroke-dasharray="4 4"
          />
          <text
            v-if="referenceLine.label"
            :x="svgWidth - pad.right"
            :y="referenceY - 5"
            text-anchor="end"
            class="qmt-ref-label"
          >
            {{ referenceLine.label }}
          </text>
        </g>

        <!-- Area Fills (10% QMT opacity) -->
        <template v-if="variant === 'area'">
          <path
            v-for="(s, sIdx) in plottedSeries"
            :key="`area-${s.name}`"
            v-show="s.areaPath"
            :d="s.areaPath"
            :fill="s.color"
            fill-opacity="0.1"
            class="qmt-line-area"
            :class="{ 'is-dimmed': hoveredSeriesIdx !== null && hoveredSeriesIdx !== sIdx }"
          />
        </template>

        <!-- Hover Crosshair -->
        <line
          v-if="hoveredIdx !== null"
          :x1="getX(hoveredIdx)"
          :x2="getX(hoveredIdx)"
          :y1="pad.top"
          :y2="pad.top + plotH"
          :stroke="QMT_CHART_TOKENS.crosshair"
          stroke-width="1"
        />

        <!-- 2px Round-Cap Series Lines -->
        <path
          v-for="(s, sIdx) in plottedSeries"
          :key="`line-${s.name}`"
          :d="s.linePath"
          fill="none"
          :stroke="s.color"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="qmt-line-stroke"
          :class="{ 'is-dimmed': hoveredSeriesIdx !== null && hoveredSeriesIdx !== sIdx }"
        />

        <!-- Resting Subtle Dots (only when single point) + Ringed 8px Active Hover Markers -->
        <g v-for="(s, sIdx) in plottedSeries" :key="`pts-${s.name}`">
          <circle
            v-for="pt in s.pts"
            :key="`dot-${sIdx}-${pt.cIdx}`"
            :cx="pt.x"
            :cy="pt.y"
            :r="hoveredIdx === pt.cIdx ? 4.5 : s.pts.length === 1 ? 4 : 3"
            :fill="hoveredIdx === pt.cIdx ? '#FFFFFF' : s.color"
            :stroke="s.color"
            :stroke-width="hoveredIdx === pt.cIdx ? 2.2 : 0"
            class="qmt-point-dot"
            :class="{
              'is-visible': hoveredIdx === pt.cIdx || s.pts.length <= 6
            }"
          />
        </g>

        <!-- X Axis Category Ticks -->
        <text
          v-for="(cat, cIdx) in categories"
          :key="`xc-${cat}-${cIdx}`"
          :x="getX(cIdx)"
          :y="svgHeight - 8"
          text-anchor="middle"
          class="qmt-axis-tick"
          :class="{ 'is-active-tick': hoveredIdx === cIdx }"
        >
          {{ cat }}
        </text>

        <!-- Invisible Hover Columns -->
        <rect
          v-for="slice in hitSlices"
          :key="`hit-${slice.cIdx}`"
          :x="slice.x"
          :y="pad.top"
          :width="slice.w"
          :height="plotH"
          fill="transparent"
          class="qmt-hit-col"
          @mouseenter="hoveredIdx = slice.cIdx"
        />
      </svg>

      <ChartTooltip
        :visible="hoveredIdx !== null"
        :title="hoveredIdx !== null ? categories[hoveredIdx] : ''"
        :rows="tooltipRows"
        :x="tooltipPosition.x"
        :y="tooltipPosition.y"
        :align="tooltipPosition.align"
      />
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

.qmt-chart-plot {
  position: relative;
  width: 100%;
}

.qmt-chart-svg {
  display: block;
  width: 100%;
  height: auto;
  overflow: visible;
}

.qmt-line-stroke,
.qmt-line-area {
  transition: opacity 150ms cubic-bezier(0.2, 0, 0, 1);
}

.qmt-line-stroke.is-dimmed,
.qmt-line-area.is-dimmed {
  opacity: 0.25;
}

.qmt-point-dot {
  opacity: 0;
  transition: opacity 120ms ease, r 120ms ease;
}

.qmt-point-dot.is-visible {
  opacity: 1;
}

.qmt-hit-col {
  cursor: pointer;
}

.qmt-axis-tick {
  font-size: 11.5px;
  fill: #737373;
  font-variant-numeric: tabular-nums;
}

.qmt-axis-tick.is-active-tick {
  fill: #404040;
  font-weight: 500;
}

.qmt-ref-label {
  font-size: 10.5px;
  fill: #737373;
}

.qmt-chart-empty {
  min-height: 180px;
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
