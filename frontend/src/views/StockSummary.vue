<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import {
  Monitor, ChevronRight, MoreVertical, TrendingUp,
  Bell, Filter, Calendar, ChevronDown, ExternalLink, ScrollText
} from 'lucide-vue-next';
import MetricCard from '../components/MetricCard.vue';
import AppBreadcrumb from '../components/AppBreadcrumb.vue';

const router = useRouter();

// ---- KPI cards ----
const kpis = [
  { label: 'TOTAL INVENTORY VALUE', value: 'ETB 12.5M', sub: 'vs previous month', trend: '+12.3%', isTrend: true },
  { label: 'TOTAL PRODUCTS', value: '8,432', sub: 'Active catalog' },
  { label: 'TOTAL STOCK QUANTITY', value: '142,580', sub: 'Across 14 warehouses' },
  { label: 'LOW STOCK PRODUCT', value: '10', sub: 'Below order level' },
];

// ---- Inventory status distribution (donut) ----
const statusData = [
  { label: 'Healthy', count: 6400, pct: 73, color: '#00bc7d' },
  { label: 'Low Stock', count: 1120, pct: 13, color: '#ffb900' },
  { label: 'Critical', count: 512, pct: 6, color: '#fb2c36' },
  { label: 'Out of Stock', count: 400, pct: 5, color: '#525252' },
  { label: 'Overstocked', count: 320, pct: 4, color: '#2b7fff' },
];

const RADIUS = 70;
const CIRC = 2 * Math.PI * RADIUS;
const GAP = 6; // visual gap between segments (in px of circumference)

const donutSegments = computed(() => {
  const total = statusData.reduce((sum, s) => sum + s.pct, 0);
  let offset = 0;
  return statusData.map((s) => {
    const len = (s.pct / total) * CIRC;
    const dash = Math.max(len - GAP, 0);
    const seg = {
      color: s.color,
      dashArray: `${dash} ${CIRC - dash}`,
      dashOffset: -offset,
    };
    offset += len;
    return seg;
  });
});

// ---- Inventory alerts ----
const alerts = [
  { title: '15 products below reorder level', sub: 'Across 4 Warehouses', action: 'Reorder' },
  { title: '3 batches near expiration', sub: 'Within 14 days' },
  { title: '4 unresolved stock discrepancies', sub: 'Stock Reconciliation - STR-0021' },
];

// ---- Inventory valuation analysis (bar chart) ----
const AXIS_MAX = 600000;
const valuation = [
  { label: 'Electronics', value: 320000 },
  { label: 'Apparel', value: 250000 },
  { label: 'Hardware', value: 78000 },
  { label: 'Stationary', value: 520322 },
  { label: 'Other', value: 165000 },
];
const axisTicks = [600000, 400000, 300000, 150000, 0];

const formatETB = (n: number) =>
  'ETB ' + n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

const hoveredBar = ref<number | null>(3); // Stationary highlighted by default like the mock

// ---- Stock ledger explorer ----
const showLedgerMenu = ref(false);
const toggleLedgerMenu = (e: Event) => {
  e.stopPropagation();
  showLedgerMenu.value = !showLedgerMenu.value;
};
const closeLedgerMenu = () => { showLedgerMenu.value = false; };
const goToStockLedger = () => {
  showLedgerMenu.value = false;
  router.push('/stock-ledger');
};

onMounted(() => window.addEventListener('click', closeLedgerMenu));
onUnmounted(() => window.removeEventListener('click', closeLedgerMenu));

const ledger = [
  { actor: 'You', action: 'Created Stock Out Document', time: '2 days ago', hasDoc: true },
  { actor: 'Abebe Mola', action: 'Created Stock Out Document', time: '5 days ago' },
  { actor: 'You', action: 'Created Stock Out Document', time: 'May 12, 2026' },
  { actor: 'Abebe Mola', action: 'Created Stock Out Document', time: 'May 10, 2026' },
];
</script>

<template>
  <div class="stock-summary-page">
    <!-- Standard Breadcrumbs -->
    <AppBreadcrumb :items="[{ label: 'Stock Summary' }]" />

    <!-- KPI CARDS (Using Centralized MetricCard Component) -->
    <div class="kpi-grid">
      <MetricCard
        v-for="kpi in kpis"
        :key="kpi.label"
        :label="kpi.label"
        :value="kpi.value"
        :subtext="kpi.sub"
        :trend="kpi.isTrend ? kpi.trend : undefined"
        trendType="up"
        :showMenu="true"
      />
    </div>

    <!-- ROW: STATUS DISTRIBUTION + ALERTS -->
    <div class="split-grid">
      <!-- Status Distribution -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">INVENTORY STATUS DISTRIBUTION</h3>
          <span class="card-tag">GLOBALLY</span>
        </div>
        <div class="distribution-body">
          <div class="donut-wrap">
            <svg class="donut" viewBox="0 0 180 180">
              <circle class="donut-track" cx="90" cy="90" :r="RADIUS" />
              <circle
                v-for="(seg, i) in donutSegments"
                :key="i"
                cx="90"
                cy="90"
                :r="RADIUS"
                :stroke="seg.color"
                :stroke-dasharray="seg.dashArray"
                :stroke-dashoffset="seg.dashOffset"
                class="donut-segment"
              />
            </svg>
            <div class="donut-center">
              <span class="donut-pct">73%</span>
              <span class="donut-pct-label">HEALTH</span>
            </div>
          </div>

          <ul class="legend">
            <li v-for="s in statusData" :key="s.label" class="legend-item">
              <span class="legend-dot" :style="{ backgroundColor: s.color }"></span>
              <span class="legend-label">{{ s.label }}</span>
              <span class="legend-value">{{ s.count.toLocaleString() }} - {{ s.pct }}%</span>
            </li>
          </ul>
        </div>
      </div>

      <!-- Alerts -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title alert-title">
            <Bell :size="16" class="alert-bell" />
            INVENTORY ALERTS
          </h3>
          <a href="#" class="link-view-all">View All</a>
        </div>
        <ul class="alert-list">
          <li v-for="alert in alerts" :key="alert.title" class="alert-item">
            <div class="alert-text">
              <p class="alert-main">{{ alert.title }}</p>
              <p class="alert-sub">{{ alert.sub }}</p>
            </div>
            <button v-if="alert.action" class="btn-alert-action">{{ alert.action }}</button>
          </li>
        </ul>
      </div>
    </div>

    <!-- INVENTORY VALUATION ANALYSIS -->
    <div class="card">
      <div class="card-header">
        <div>
          <h3 class="card-title">INVENTORY VALUATION ANALYSIS</h3>
          <p class="card-subtitle">Breakdown of {{ formatETB(12500680) }} total Value</p>
        </div>
        <div class="header-controls">
          <button class="btn-icon-square"><Filter :size="16" /></button>
          <button class="btn-select">
            <Calendar :size="14" />
            <span>Monthly</span>
            <ChevronDown :size="14" />
          </button>
          <button class="btn-more"><MoreVertical :size="16" /></button>
        </div>
      </div>

      <div class="chart-body">
        <div class="chart-y-axis">
          <span v-for="tick in axisTicks" :key="tick">{{ (tick / 1000) }}K</span>
        </div>
        <div class="chart-plot">
          <div class="chart-gridlines">
            <span v-for="tick in axisTicks" :key="tick"></span>
          </div>
          <div class="bars">
            <div
              v-for="(bar, i) in valuation"
              :key="bar.label"
              class="bar-col"
              @mouseenter="hoveredBar = i"
              @mouseleave="hoveredBar = null"
            >
              <div class="bar-area">
                <div
                  v-if="hoveredBar === i"
                  class="bar-tooltip"
                >
                  <span class="tip-cat">{{ bar.label }}</span>
                  <span class="tip-val">{{ formatETB(bar.value) }}</span>
                  <span class="tip-label">Stock Value</span>
                </div>
                <div
                  class="bar"
                  :class="{ 'bar-active': hoveredBar === i }"
                  :style="{ height: (bar.value / AXIS_MAX * 100) + '%' }"
                ></div>
              </div>
              <span class="bar-label">{{ bar.label }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- STOCK LEDGER EXPLORER (no card / no background) -->
    <div class="ledger-section">
      <div class="ledger-header">
        <div>
          <h3 class="ledger-title">Stock Ledger Explorer</h3>
          <p class="card-subtitle">Immutable StockLedger — every movement traces to a StockOperation &amp; Document.</p>
        </div>
        <div class="header-controls">
          <button class="btn-icon-square"><Filter :size="16" /></button>
          <button class="btn-select">
            <Calendar :size="14" />
            <span>Weekly</span>
            <ChevronDown :size="14" />
          </button>
          <div class="ledger-menu-wrapper">
            <button class="btn-more" @click="toggleLedgerMenu" :class="{ active: showLedgerMenu }">
              <MoreVertical :size="16" />
            </button>
            <div v-if="showLedgerMenu" class="ledger-dropdown-menu" @click.stop>
              <button class="ledger-dropdown-item" @click="goToStockLedger">
                <ScrollText :size="15" class="text-gray-500" />
                <span>Go to Stock Ledger Page</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <ul class="timeline">
        <li v-for="(entry, i) in ledger" :key="i" class="timeline-item">
          <span class="timeline-dot"></span>
          <div class="timeline-content">
            <span class="timeline-text">
              {{ entry.actor }} {{ entry.action }} - {{ entry.time }}
            </span>
            <button v-if="entry.hasDoc" class="btn-open-doc">
              Open Stock Operation document
              <ExternalLink :size="14" />
            </button>
          </div>
        </li>
      </ul>
    </div>
  </div>
</template>

<style scoped>
.stock-summary-page {
  animation: fadeIn 0.4s ease-out;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Breadcrumbs */
.breadcrumbs {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  margin-bottom: 0;
}
.breadcrumb-link {
  color: #9ca3af;
  text-decoration: none;
  display: flex;
  align-items: center;
  transition: color 0.15s ease;
}
.breadcrumb-link:hover { color: #111827; }
.breadcrumb-separator { color: #9ca3af; display: flex; align-items: center; }
.breadcrumb-active { color: #111827; font-weight: 500; }

/* Generic card */
.card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}
.card-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid #f3f4f6;
}
.card-title {
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.04em;
  color: #6b7280;
  text-transform: uppercase;
}
.card-subtitle {
  font-size: 13px;
  color: #9ca3af;
  margin-top: 4px;
}
.card-tag {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.05em;
  color: #9ca3af;
}

.btn-more {
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  padding: 4px;
  border-radius: 6px;
  display: flex;
  transition: all 0.15s ease;
}
.btn-more:hover { color: #111827; background: #f3f4f6; }

/* KPI grid */
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
}
@media (max-width: 1100px) { .kpi-grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 600px) { .kpi-grid { grid-template-columns: 1fr; } }

.kpi-card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  padding: 20px 22px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}
.kpi-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
}
.kpi-label {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.05em;
  color: #9ca3af;
}
.kpi-value {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  line-height: 1.1;
}
.kpi-footer {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 10px;
}
.kpi-sub { font-size: 12px; color: #9ca3af; }
.kpi-trend {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  background: #ecfdf5;
  color: #059669;
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 20px;
}

/* Split row */
.split-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}
@media (max-width: 1024px) { .split-grid { grid-template-columns: 1fr; } }

/* Distribution */
.distribution-body {
  display: flex;
  align-items: center;
  gap: 32px;
  padding: 24px;
}
.donut-wrap {
  position: relative;
  width: 180px;
  height: 180px;
  flex-shrink: 0;
}
.donut {
  width: 100%;
  height: 100%;
  transform: rotate(-90deg);
}
.donut-track {
  fill: none;
  stroke: #f3f4f6;
  stroke-width: 20;
}
.donut-segment {
  fill: none;
  stroke-width: 20;
  stroke-linecap: round;
  transition: stroke-width 0.2s ease;
}
.donut-center {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
.donut-pct { font-size: 32px; font-weight: 700; color: #111827; line-height: 1; }
.donut-pct-label { font-size: 11px; font-weight: 600; letter-spacing: 0.08em; color: #9ca3af; margin-top: 4px; }

.legend {
  list-style: none;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.legend-item {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
}
.legend-dot { width: 9px; height: 9px; border-radius: 50%; flex-shrink: 0; }
.legend-label { color: #374151; }
.legend-value { margin-left: auto; color: #6b7280; font-weight: 500; }

/* Alerts */
.alert-title { display: flex; align-items: center; gap: 8px; }
.alert-bell { color: #6b7280; }
.link-view-all {
  font-size: 13px;
  color: var(--alias-color-brand-blue-primary);
  font-weight: 500;
  text-decoration: none;
}
.link-view-all:hover { text-decoration: underline; }
.alert-list { list-style: none; }
.alert-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 18px 24px;
  border-bottom: 1px solid #f3f4f6;
}
.alert-item:last-child { border-bottom: none; }
.alert-main { font-size: 14px; font-weight: 600; color: #111827; }
.alert-sub { font-size: 12px; color: #9ca3af; margin-top: 3px; }
.btn-alert-action {
  flex-shrink: 0;
  padding: 7px 16px;
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #374151;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-alert-action:hover { background: #f9fafb; border-color: #d1d5db; }

/* Header controls (filter / select / more) */
.header-controls { display: flex; align-items: center; gap: 8px; }
.btn-icon-square {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  color: #6b7280;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-icon-square:hover { background: #f9fafb; border-color: #d1d5db; color: #111827; }
.btn-select {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 36px;
  padding: 0 12px;
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #374151;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-select:hover { background: #f9fafb; border-color: #d1d5db; }

/* Bar chart */
.chart-body {
  display: flex;
  gap: 12px;
  padding: 28px 24px 16px 24px;
  height: 360px;
}
.chart-y-axis {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: flex-end;
  padding-bottom: 28px;
  font-size: 11px;
  color: #9ca3af;
  width: 36px;
  flex-shrink: 0;
}
.chart-plot {
  position: relative;
  flex: 1;
}
.chart-gridlines {
  position: absolute;
  inset: 0 0 28px 0;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}
.chart-gridlines span {
  display: block;
  border-top: 1px dashed #f1f5f9;
  height: 0;
}
.bars {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: stretch;
  gap: 28px;
  padding: 0 16px;
}
.bar-col {
  flex: 1;
  display: flex;
  flex-direction: column;
}
.bar-area {
  position: relative;
  flex: 1;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}
.bar {
  width: 100%;
  max-width: 110px;
  background: #eff6ff;
  border: 1px solid #bedbff;
  border-radius: 8px 8px 0 0;
  transition: all 0.2s ease;
}
.bar-active { background: #dbeafe; border-color: #8ec5ff; }
.bar-label {
  text-align: center;
  font-size: 12px;
  color: #6b7280;
  height: 28px;
  line-height: 28px;
}
.bar-tooltip {
  position: absolute;
  bottom: calc(100% + 8px);
  left: 50%;
  transform: translateX(-50%);
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  box-shadow: 0 10px 20px -5px rgba(0, 0, 0, 0.12);
  padding: 10px 14px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  white-space: nowrap;
  z-index: 10;
  pointer-events: none;
}
.tip-cat { font-size: 12px; font-weight: 600; color: #111827; }
.tip-val { font-size: 13px; font-weight: 700; color: #111827; }
.tip-label { font-size: 11px; color: #9ca3af; }

/* Ledger (no card / no background) */
.ledger-section {
  background: transparent;
  border: none;
  box-shadow: none;
  padding: 4px 4px 0 4px;
}
.ledger-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  border: none;
  padding: 0;
}
.ledger-title { font-size: 18px; font-weight: 700; color: #111827; }
.ledger-section .card-subtitle { color: #6b7280; }

/* Ledger 3-dot dropdown */
.ledger-menu-wrapper { position: relative; }
.btn-more.active { color: #111827; background: #f3f4f6; }
.ledger-dropdown-menu {
  position: absolute;
  top: calc(100% + 6px);
  right: 0;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.08), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
  z-index: 999;
  min-width: 210px;
  padding: 6px;
  animation: dropFade 0.15s ease-out;
}
@keyframes dropFade {
  from { opacity: 0; transform: translateY(-5px); }
  to { opacity: 1; transform: translateY(0); }
}
.ledger-dropdown-item {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  padding: 9px 12px;
  font-size: 13px;
  font-weight: 500;
  color: #475569;
  background: none;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  transition: all 0.15s ease;
}
.ledger-dropdown-item:hover { background: #f1f5f9; color: #0f172a; }

.timeline {
  list-style: none;
  padding: 22px 4px 8px 4px;
}
.timeline-item {
  position: relative;
  padding-left: 24px;
  padding-bottom: 28px;
}
.timeline-item:last-child { padding-bottom: 0; }
.timeline-item::before {
  content: '';
  position: absolute;
  left: 4px;
  top: 14px;
  bottom: -4px;
  width: 1.5px;
  background: #e5e7eb;
}
.timeline-item:last-child::before { display: none; }
.timeline-dot {
  position: absolute;
  left: 0;
  top: 5px;
  width: 9px;
  height: 9px;
  border-radius: 50%;
  background: #d1d5db;
}
.timeline-content {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}
.timeline-text { font-size: 14px; color: #4b5563; }
.btn-open-doc {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 7px 14px;
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #374151;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-open-doc:hover { background: #f9fafb; border-color: #d1d5db; }
</style>
