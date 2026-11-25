<script setup lang="ts">
import { ref, computed } from 'vue';
import { Table2, BarChart3 } from 'lucide-vue-next';
import ChartLegend, { type ChartLegendItem } from './ChartLegend.vue';
import ChartTooltip, { type ChartTooltipRow } from './ChartTooltip.vue';
import {
  type ChartPalette,
  QMT_CHART_TOKENS,
  getChartSeriesColor,
  computeNiceTicks,
  defaultValueFormat
} from './chartTokens';

export interface BarChartSeries {
  name: string;
  data: number[];
  color?: string;
  barColors?: string[];
}

const props = withDefaults(
  defineProps<{
    title: string;
    subtitle?: string;
    categories: string[];
    series: BarChartSeries[];
    orientation?: 'vertical' | 'horizontal';
    layout?: 'single' | 'grouped' | 'stacked';
    palette?: ChartPalette;
    maxValue?: number;
    valueFormatter?: (value: number) => string;
    categorySubtitles?: string[];
    showValues?: boolean;
    showTableToggle?: boolean;
    height?: number;
    bare?: boolean;
    emptyText?: string;
  }>(),
  {
    subtitle: '',
    orientation: 'vertical',
    layout: 'single',
    palette: 'brand',
    maxValue: undefined,
    valueFormatter: undefined,
    categorySubtitles: () => [],
    showValues: false,
    showTableToggle: true,
    height: 236,
    bare: false,
    emptyText: 'No data available.'
  }
);

const viewMode = ref<'chart' | 'table'>('chart');
const hoveredCategoryIdx = ref<number | null>(null);
const hoveredSeriesIdx = ref<number | null>(null);
const plotRef = ref<HTMLDivElement | null>(null);
const tooltipPos = ref({ x: 0, y: 0, align: 'center' as 'left' | 'right' | 'center' });

const formatVal = (v: number) =>
  props.valueFormatter ? props.valueFormatter(v) : defaultValueFormat(v);

const hasData = computed(
  () => props.categories.length > 0 && props.series.length > 0 && props.series.some((s) => s.data.length > 0)
);

const effectiveSeries = computed(() =>
  props.layout === 'single' ? props.series.slice(0, 1) : props.series
);

const seriesColors = computed(() =>
  effectiveSeries.value.map((s, idx) =>
    getChartSeriesColor(props.palette, idx, { customColor: s.color })
  )
);

function getBarColor(sIdx: number, cIdx: number): string {
  const customBarColor = effectiveSeries.value[sIdx]?.barColors?.[cIdx];
  if (customBarColor) return customBarColor;
  return seriesColors.value[sIdx];
}

const legendItems = computed<ChartLegendItem[]>(() =>
  effectiveSeries.value.map((s, idx) => ({
    label: s.name,
    color: seriesColors.value[idx]
  }))
);

const showLegend = computed(() => effectiveSeries.value.length > 1);

const axisScale = computed(() => {
  let rawMax = 0;
  if (props.layout === 'stacked') {
    for (let c = 0; c < props.categories.length; c++) {
      const sum = effectiveSeries.value.reduce((acc, s) => acc + (Number(s.data[c]) || 0), 0);
      if (sum > rawMax) rawMax = sum;
    }
  } else {
    for (const s of effectiveSeries.value) {
      for (const v of s.data) {
        if (Number(v) > rawMax) rawMax = Number(v);
      }
    }
  }
  return computeNiceTicks(rawMax, {
    min: 0,
    max: props.maxValue,
    tickCount: props.maxValue === 100 ? 6 : 5
  });
});

// ─── SVG Geometry (Matches QMT 560px Plot Width & 10883:61882 Proportions) ───
const svgWidth = 560;
const svgHeight = computed(() => props.height);

// Vertical bar chart padding (flush left ticks, tight right margin)
const vPad = { top: 14, right: 12, bottom: 26, left: 32 };
const vPlotW = svgWidth - vPad.left - vPad.right;
const vPlotH = computed(() => svgHeight.value - vPad.top - vPad.bottom);

// Horizontal bar chart padding (compact right-aligned labels like QMT 10883:61882)
const hLabelW = computed(() => {
  const longest = props.categories.reduce((m, c) => Math.max(m, c.length), 0);
  return Math.min(118, Math.max(62, Math.round(longest * 6.8 + 14)));
});
const hRightPad = computed(() => (props.showValues ? 44 : 14));
const hPad = computed(() => ({ top: 8, right: hRightPad.value, bottom: 26, left: hLabelW.value }));
const hPlotW = computed(() => svgWidth - hPad.value.left - hPad.value.right);
const hPlotH = computed(() => svgHeight.value - hPad.value.top - hPad.value.bottom);

/** Builds an SVG path for a horizontal bar with flat left edge and rounded right corners (QMT spec). */
function rightRoundedRectPath(x: number, y: number, w: number, h: number, r = 4): string {
  const width = Math.max(0, w);
  if (width <= 0) return '';
  const rad = Math.min(r, width / 2, h / 2);
  return [
    `M ${x.toFixed(1)} ${y.toFixed(1)}`,
    `H ${(x + width - rad).toFixed(1)}`,
    `Q ${(x + width).toFixed(1)} ${y.toFixed(1)} ${(x + width).toFixed(1)} ${(y + rad).toFixed(1)}`,
    `V ${(y + h - rad).toFixed(1)}`,
    `Q ${(x + width).toFixed(1)} ${(y + h).toFixed(1)} ${(x + width - rad).toFixed(1)} ${(y + h).toFixed(1)}`,
    `H ${x.toFixed(1)}`,
    'Z'
  ].join(' ');
}

const verticalBars = computed(() => {
  const cats = props.categories.length;
  if (!cats) return [];
  const slotW = vPlotW / cats;
  const maxV = axisScale.value.max || 1;
  const sCount = effectiveSeries.value.length;

  return props.categories.map((cat, cIdx) => {
    const cx = vPad.left + slotW * cIdx + slotW / 2;
    const rects: Array<{
      sIdx: number;
      x: number;
      y: number;
      w: number;
      h: number;
      val: number;
      color: string;
    }> = [];

    if (props.layout === 'stacked') {
      const barW = Math.min(34, Math.max(14, slotW * 0.42));
      let accY = vPad.top + vPlotH.value;
      effectiveSeries.value.forEach((s, sIdx) => {
        const val = Math.max(0, Number(s.data[cIdx]) || 0);
        const h = (val / maxV) * vPlotH.value;
        accY -= h;
        rects.push({
          sIdx,
          x: cx - barW / 2,
          y: accY,
          w: barW,
          h,
          val,
          color: getBarColor(sIdx, cIdx)
        });
      });
    } else {
      const gap = sCount > 1 ? 4 : 0;
      const groupMaxW = Math.min(slotW * 0.68, sCount === 1 ? 32 : 68);
      const barW = Math.max(8, (groupMaxW - gap * (sCount - 1)) / sCount);
      const totalW = barW * sCount + gap * (sCount - 1);
      const startX = cx - totalW / 2;
      effectiveSeries.value.forEach((s, sIdx) => {
        const val = Math.max(0, Number(s.data[cIdx]) || 0);
        const h = (val / maxV) * vPlotH.value;
        rects.push({
          sIdx,
          x: startX + sIdx * (barW + gap),
          y: vPad.top + vPlotH.value - h,
          w: barW,
          h,
          val,
          color: getBarColor(sIdx, cIdx)
        });
      });
    }

    return { cat, cIdx, cx, slotX: vPad.left + slotW * cIdx, slotW, rects };
  });
});

const horizontalBars = computed(() => {
  const cats = props.categories.length;
  if (!cats) return [];
  const slotH = hPlotH.value / cats;
  const maxV = axisScale.value.max || 1;
  const sCount = effectiveSeries.value.length;

  return props.categories.map((cat, cIdx) => {
    const cy = hPad.value.top + slotH * cIdx + slotH / 2;
    const rects: Array<{
      sIdx: number;
      x: number;
      y: number;
      w: number;
      h: number;
      val: number;
      color: string;
    }> = [];

    if (props.layout === 'stacked') {
      const barH = Math.min(22, Math.max(12, slotH * 0.46));
      let accX = hPad.value.left;
      effectiveSeries.value.forEach((s, sIdx) => {
        const val = Math.max(0, Number(s.data[cIdx]) || 0);
        const w = (val / maxV) * hPlotW.value;
        rects.push({
          sIdx,
          x: accX,
          y: cy - barH / 2,
          w,
          h: barH,
          val,
          color: getBarColor(sIdx, cIdx)
        });
        accX += w;
      });
    } else {
      const gap = sCount > 1 ? 3 : 0;
      const groupMaxH = Math.min(slotH * 0.64, sCount === 1 ? 24 : 34);
      const barH = Math.max(7, (groupMaxH - gap * (sCount - 1)) / sCount);
      const totalH = barH * sCount + gap * (sCount - 1);
      const startY = cy - totalH / 2;
      effectiveSeries.value.forEach((s, sIdx) => {
        const val = Math.max(0, Number(s.data[cIdx]) || 0);
        const w = (val / maxV) * hPlotW.value;
        rects.push({
          sIdx,
          x: hPad.value.left,
          y: startY + sIdx * (barH + gap),
          w,
          h: barH,
          val,
          color: getBarColor(sIdx, cIdx)
        });
      });
    }

    const totalVal = effectiveSeries.value.reduce((acc, s) => acc + (Number(s.data[cIdx]) || 0), 0);
    const maxEndX = rects.reduce((m, r) => Math.max(m, r.x + r.w), hPad.value.left);

    return {
      cat,
      subtitle: props.categorySubtitles[cIdx] || '',
      cIdx,
      cy,
      slotY: hPad.value.top + slotH * cIdx,
      slotH,
      rects,
      totalVal,
      maxEndX
    };
  });
});

function handleCategoryEnter(cIdx: number, event: MouseEvent) {
  hoveredCategoryIdx.value = cIdx;
  updateTooltipPosition(event);
}

function handleCategoryMove(event: MouseEvent) {
  if (hoveredCategoryIdx.value !== null) {
    updateTooltipPosition(event);
  }
}

function updateTooltipPosition(event: MouseEvent) {
  const el = plotRef.value;
  if (!el) return;
  const rect = el.getBoundingClientRect();
  const relX = event.clientX - rect.left;
  const relY = event.clientY - rect.top;
  let align: 'left' | 'right' | 'center' = 'center';
  if (relX < 90) align = 'left';
  else if (relX > rect.width - 90) align = 'right';
  tooltipPos.value = { x: relX, y: Math.max(24, relY), align };
}

function clearHover() {
  hoveredCategoryIdx.value = null;
}

const tooltipTitle = computed(() => {
  if (hoveredCategoryIdx.value === null) return '';
  const cat = props.categories[hoveredCategoryIdx.value] || '';
  const sub = props.categorySubtitles[hoveredCategoryIdx.value];
  return sub ? `${cat} (${sub})` : cat;
});

const tooltipRows = computed<ChartTooltipRow[]>(() => {
  if (hoveredCategoryIdx.value === null) return [];
  const cIdx = hoveredCategoryIdx.value;
  return effectiveSeries.value.map((s, sIdx) => ({
    label: s.name,
    value: formatVal(Number(s.data[cIdx]) || 0),
    color: getBarColor(sIdx, cIdx)
  }));
});

function isBarDimmed(cIdx: number, sIdx: number): boolean {
  if (hoveredSeriesIdx.value !== null && hoveredSeriesIdx.value !== sIdx) return true;
  if (hoveredCategoryIdx.value !== null && hoveredCategoryIdx.value !== cIdx) return true;
  return false;
}
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
          <BarChart3 v-if="viewMode === 'table'" :size="15" />
          <Table2 v-else :size="15" />
        </button>
      </div>
    </div>

    <ChartLegend
      v-if="showLegend && hasData && viewMode === 'chart'"
      :items="legendItems"
      mark="square"
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
            <th>Category</th>
            <th v-for="s in effectiveSeries" :key="s.name" class="is-num">{{ s.name }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(cat, cIdx) in categories" :key="cat">
            <td>
              <span class="qmt-table-cat">{{ cat }}</span>
              <span v-if="categorySubtitles[cIdx]" class="qmt-table-sub">
                {{ categorySubtitles[cIdx] }}
              </span>
            </td>
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
      @mousemove="handleCategoryMove"
      @mouseleave="clearHover"
    >
      <svg
        :viewBox="`0 0 ${svgWidth} ${svgHeight}`"
        class="qmt-chart-svg"
        role="img"
        :aria-label="title"
      >
        <!-- VERTICAL ORIENTATION -->
        <template v-if="orientation === 'vertical'">
          <!-- Horizontal Gridlines & Y Ticks -->
          <g v-for="tick in axisScale.ticks" :key="`vt-${tick}`">
            <line
              :x1="vPad.left"
              :x2="svgWidth - vPad.right"
              :y1="vPad.top + vPlotH - (tick / (axisScale.max || 1)) * vPlotH"
              :y2="vPad.top + vPlotH - (tick / (axisScale.max || 1)) * vPlotH"
              :stroke="tick === 0 ? QMT_CHART_TOKENS.axis : QMT_CHART_TOKENS.grid"
              stroke-width="1"
            />
            <text
              :x="vPad.left - 8"
              :y="vPad.top + vPlotH - (tick / (axisScale.max || 1)) * vPlotH + 4"
              text-anchor="end"
              class="qmt-axis-tick"
            >
              {{ tick }}
            </text>
          </g>

          <!-- Vertical Bars & Hover Hit Targets -->
          <g
            v-for="group in verticalBars"
            :key="`vg-${group.cIdx}`"
            class="qmt-bar-group"
            @mouseenter="handleCategoryEnter(group.cIdx, $event)"
          >
            <rect
              :x="group.slotX"
              :y="vPad.top"
              :width="group.slotW"
              :height="vPlotH"
              fill="transparent"
            />
            <rect
              v-for="bar in group.rects"
              :key="`vb-${group.cIdx}-${bar.sIdx}`"
              :x="bar.x"
              :y="bar.y"
              :width="bar.w"
              :height="Math.max(0, bar.h)"
              :fill="bar.color"
              rx="4"
              ry="4"
              class="qmt-bar-rect"
              :class="{ 'is-dimmed': isBarDimmed(group.cIdx, bar.sIdx) }"
            />
            <text
              :x="group.cx"
              :y="svgHeight - 8"
              text-anchor="middle"
              class="qmt-axis-tick"
            >
              {{ group.cat }}
            </text>
          </g>
        </template>

        <!-- HORIZONTAL ORIENTATION -->
        <template v-else>
          <!-- Vertical Gridlines & X Ticks -->
          <g v-for="tick in axisScale.ticks" :key="`ht-${tick}`">
            <line
              :x1="hPad.left + (tick / (axisScale.max || 1)) * hPlotW"
              :x2="hPad.left + (tick / (axisScale.max || 1)) * hPlotW"
              :y1="hPad.top"
              :y2="hPad.top + hPlotH"
              :stroke="tick === 0 ? QMT_CHART_TOKENS.axis : QMT_CHART_TOKENS.grid"
              stroke-width="1"
            />
            <text
              :x="hPad.left + (tick / (axisScale.max || 1)) * hPlotW"
              :y="svgHeight - 8"
              text-anchor="middle"
              class="qmt-axis-tick"
            >
              {{ tick }}
            </text>
          </g>

          <!-- Horizontal Bars & Category Labels -->
          <g
            v-for="row in horizontalBars"
            :key="`hg-${row.cIdx}`"
            class="qmt-bar-group"
            @mouseenter="handleCategoryEnter(row.cIdx, $event)"
          >
            <rect
              :x="0"
              :y="row.slotY"
              :width="svgWidth"
              :height="row.slotH"
              fill="transparent"
            />
            <text
              :x="hPad.left - 10"
              :y="row.cy + 4"
              text-anchor="end"
              class="qmt-axis-cat-label"
            >
              {{ row.cat }}
            </text>

            <path
              v-for="bar in row.rects"
              :key="`hb-${row.cIdx}-${bar.sIdx}`"
              :d="rightRoundedRectPath(bar.x, bar.y, bar.w, bar.h, 4)"
              :fill="bar.color"
              class="qmt-bar-rect"
              :class="{ 'is-dimmed': isBarDimmed(row.cIdx, bar.sIdx) }"
            />

            <text
              v-if="showValues && effectiveSeries.length === 1"
              :x="row.maxEndX + 8"
              :y="row.cy + 4.5"
              text-anchor="start"
              class="qmt-bar-value-label"
              :class="{ 'is-dimmed': isBarDimmed(row.cIdx, 0) }"
            >
              {{ formatVal(row.totalVal) }}
            </text>
          </g>
        </template>
      </svg>

      <ChartTooltip
        :visible="hoveredCategoryIdx !== null"
        :title="tooltipTitle"
        :rows="tooltipRows"
        :x="tooltipPos.x"
        :y="tooltipPos.y"
        :align="tooltipPos.align"
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

.qmt-bar-group {
  cursor: pointer;
}

.qmt-bar-rect {
  transition: opacity 150ms cubic-bezier(0.2, 0, 0, 1);
}

.qmt-bar-rect.is-dimmed,
.qmt-bar-value-label.is-dimmed {
  opacity: 0.32;
}

.qmt-axis-tick {
  font-size: 11.5px;
  fill: #737373;
  font-variant-numeric: tabular-nums;
}

.qmt-axis-cat-label {
  font-size: 12px;
  font-weight: 400;
  fill: #737373;
}

.qmt-bar-value-label {
  font-size: 13.5px;
  font-weight: 400;
  fill: #404040;
  font-variant-numeric: tabular-nums;
  transition: opacity 150ms cubic-bezier(0.2, 0, 0, 1);
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

.qmt-table-cat {
  color: #404040;
  font-weight: 400;
}

.qmt-table-sub {
  margin-left: 6px;
  font-size: 12px;
  color: #737373;
}
</style>
