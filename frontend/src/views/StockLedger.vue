<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import {
  Monitor, ChevronRight, Search, Filter, RotateCcw,
  ArrowDownLeft, ArrowUpRight, ArrowLeftRight, SlidersHorizontal,
  ExternalLink, ArrowLeft, ArrowRight, MoreVertical, Eye, FileText,
  X, Package, MapPin, Layers, Coins, User, ClipboardList, Boxes, ArrowRightLeft
} from 'lucide-vue-next';
import BaseButton from '../components/BaseButton.vue';

/**
 * Immutable StockLedger rows. Every movement traces to a StockOperation and a
 * source Document, carries the InventoryValuationLayer that priced it, and the
 * StockSummary balance it updated (before -> after). Modelled after the schema in
 * "Inventory and its related schema.md" (section 4.2 Stock Operation).
 */
const ledgerRows = ref([
  {
    id: 'LD-100245',
    date: 'May 16, 2026 - 14:20',
    operation: 'STOCK_OUT',
    product: 'A4 Copy Paper (80gsm)',
    sku: 'STN-A4-080',
    batch: 'B-2026-014',
    serial: null,
    measurement: 'Ream',
    qty: -120,
    unitCost: 145.0,
    unitPrice: 210.0,
    location: 'Main Warehouse',
    entity: 'Haleta Trading PLC',
    actor: 'You',
    document: {
      number: 'SIV-0098-2026', typeCode: 'SIV', typeName: 'Store Issue Voucher',
      date: 'May 16, 2026', postingDate: 'May 16, 2026', status: 'completed', posting: 'posted',
      reference: 'SO-4471', createdBy: 'Marta Tadesse', approvedBy: 'Daniel Bekele',
      remarks: 'Issued against confirmed sales order SO-4471.',
    },
    operationDoc: {
      name: 'Sales issue — A4 Paper', barcode: 'OPSO00098', typeCode: 'STOCK_OUT',
      reason: 'Sale', status: 'completed', source: 'Main Warehouse', destination: null,
      operationDate: 'May 16, 2026', postingDate: 'May 16, 2026',
      createdBy: 'Marta Tadesse', approvedBy: 'Daniel Bekele', remarks: 'POS-linked issue.',
    },
    valuation: { quantity: 120, unitCost: 145.0, totalCost: 17400.0, remainingQty: 380, costingRule: 'FIFO' },
    summaryBefore: { physical: 500, reserved: 120, available: 380 },
    summaryAfter: { physical: 380, reserved: 0, available: 380 },
  },
  {
    id: 'LD-100244',
    date: 'May 15, 2026 - 09:05',
    operation: 'STOCK_IN',
    product: 'HP LaserJet Toner 26A',
    sku: 'ELC-TNR-26A',
    batch: 'B-2026-061',
    serial: null,
    measurement: 'Piece',
    qty: 60,
    unitCost: 1850.0,
    unitPrice: null,
    location: 'Main Warehouse',
    entity: 'Haleta Trading PLC',
    actor: 'Abebe Mola',
    document: {
      number: 'GRN-0231-2026', typeCode: 'GRN', typeName: 'Goods Receiving Note',
      date: 'May 15, 2026', postingDate: 'May 15, 2026', status: 'posted', posting: 'posted',
      reference: 'PO-2098', createdBy: 'Abebe Mola', approvedBy: 'Selam Girma',
      remarks: 'Received from supplier Tech Imports Ltd.',
    },
    operationDoc: {
      name: 'Goods receipt — Toner 26A', barcode: 'OPGR00231', typeCode: 'STOCK_IN',
      reason: 'Purchase Receipt', status: 'completed', source: null, destination: 'Main Warehouse',
      operationDate: 'May 15, 2026', postingDate: 'May 15, 2026',
      createdBy: 'Abebe Mola', approvedBy: 'Selam Girma', remarks: 'QC passed on arrival.',
    },
    valuation: { quantity: 60, unitCost: 1850.0, totalCost: 111000.0, remainingQty: 60, costingRule: 'FIFO' },
    summaryBefore: { physical: 12, reserved: 0, available: 12 },
    summaryAfter: { physical: 72, reserved: 0, available: 72 },
  },
  {
    id: 'LD-100243',
    date: 'May 14, 2026 - 11:42',
    operation: 'TRANSFER_OUT',
    product: 'Wireless Mouse - Logitech',
    sku: 'ELC-MSE-LG',
    batch: null,
    serial: null,
    measurement: 'Piece',
    qty: -25,
    unitCost: 420.0,
    unitPrice: null,
    location: 'Main Warehouse',
    entity: 'Haleta Trading PLC',
    actor: 'You',
    document: {
      number: 'TRN-0044-2026', typeCode: 'TRANSFER', typeName: 'Transfer Voucher',
      date: 'May 14, 2026', postingDate: 'May 14, 2026', status: 'completed', posting: 'posted',
      reference: 'IBT-0044', createdBy: 'Marta Tadesse', approvedBy: 'Daniel Bekele',
      remarks: 'Inter-branch transfer to Warehouse 22.',
    },
    operationDoc: {
      name: 'Transfer out — Mouse', barcode: 'OPTR00044', typeCode: 'TRANSFER_OUT',
      reason: 'Internal Transfer', status: 'completed', source: 'Main Warehouse', destination: 'Warehouse 22',
      operationDate: 'May 14, 2026', postingDate: 'May 14, 2026',
      createdBy: 'Marta Tadesse', approvedBy: 'Daniel Bekele', remarks: 'Awaiting receipt confirmation at destination.',
    },
    valuation: { quantity: 25, unitCost: 420.0, totalCost: 10500.0, remainingQty: 95, costingRule: 'Weighted Avg' },
    summaryBefore: { physical: 120, reserved: 0, available: 120 },
    summaryAfter: { physical: 95, reserved: 0, available: 95 },
  },
  {
    id: 'LD-100242',
    date: 'May 12, 2026 - 16:30',
    operation: 'ADJUSTMENT_MINUS',
    product: 'Stapler Heavy Duty',
    sku: 'STN-STP-HD',
    batch: null,
    serial: null,
    measurement: 'Piece',
    qty: -3,
    unitCost: 310.0,
    unitPrice: null,
    location: 'Warehouse 22',
    entity: 'Haleta Trading PLC',
    actor: 'Abebe Mola',
    document: {
      number: 'ADJ-0012-2026', typeCode: 'ADJUSTMENT', typeName: 'Stock Adjustment',
      date: 'May 12, 2026', postingDate: 'May 12, 2026', status: 'posted', posting: 'posted',
      reference: 'STR-0021', createdBy: 'Abebe Mola', approvedBy: 'Selam Girma',
      remarks: 'Negative adjustment from stock-taking session STR-0021.',
    },
    operationDoc: {
      name: 'Adjustment — Stapler', barcode: 'OPAD00012', typeCode: 'ADJUSTMENT_MINUS',
      reason: 'Damage', status: 'completed', source: 'Warehouse 22', destination: null,
      operationDate: 'May 12, 2026', postingDate: 'May 12, 2026',
      createdBy: 'Abebe Mola', approvedBy: 'Selam Girma', remarks: '3 units found damaged during count.',
    },
    valuation: { quantity: 3, unitCost: 310.0, totalCost: 930.0, remainingQty: 41, costingRule: 'Weighted Avg' },
    summaryBefore: { physical: 44, reserved: 0, available: 44 },
    summaryAfter: { physical: 41, reserved: 0, available: 41 },
  },
  {
    id: 'LD-100241',
    date: 'May 10, 2026 - 08:15',
    operation: 'STOCK_OUT',
    product: 'Ballpoint Pen (Box of 50)',
    sku: 'STN-PEN-50',
    batch: 'B-2026-009',
    serial: null,
    measurement: 'Box',
    qty: -45,
    unitCost: 230.0,
    unitPrice: 320.0,
    location: 'Main Warehouse',
    entity: 'Haleta Trading PLC',
    actor: 'You',
    document: {
      number: 'SIV-0091-2026', typeCode: 'SIV', typeName: 'Store Issue Voucher',
      date: 'May 10, 2026', postingDate: 'May 10, 2026', status: 'completed', posting: 'posted',
      reference: 'SO-4460', createdBy: 'Marta Tadesse', approvedBy: 'Daniel Bekele',
      remarks: 'Issued against sales order SO-4460.',
    },
    operationDoc: {
      name: 'Sales issue — Pens', barcode: 'OPSO00091', typeCode: 'STOCK_OUT',
      reason: 'Sale', status: 'completed', source: 'Main Warehouse', destination: null,
      operationDate: 'May 10, 2026', postingDate: 'May 10, 2026',
      createdBy: 'Marta Tadesse', approvedBy: 'Daniel Bekele', remarks: '',
    },
    valuation: { quantity: 45, unitCost: 230.0, totalCost: 10350.0, remainingQty: 155, costingRule: 'FIFO' },
    summaryBefore: { physical: 200, reserved: 45, available: 155 },
    summaryAfter: { physical: 155, reserved: 0, available: 155 },
  },
  {
    id: 'LD-100240',
    date: 'May 09, 2026 - 13:50',
    operation: 'STOCK_IN',
    product: 'Desktop Monitor 24"',
    sku: 'ELC-MON-24',
    batch: null,
    serial: 'SN-MN24-0098',
    measurement: 'Piece',
    qty: 18,
    unitCost: 7400.0,
    unitPrice: null,
    location: 'Main Warehouse',
    entity: 'Haleta Trading PLC',
    actor: 'Abebe Mola',
    document: {
      number: 'GRN-0228-2026', typeCode: 'GRN', typeName: 'Goods Receiving Note',
      date: 'May 09, 2026', postingDate: 'May 09, 2026', status: 'posted', posting: 'posted',
      reference: 'PO-2090', createdBy: 'Abebe Mola', approvedBy: 'Selam Girma',
      remarks: 'Serialized receipt — 18 units logged.',
    },
    operationDoc: {
      name: 'Goods receipt — Monitor 24"', barcode: 'OPGR00228', typeCode: 'STOCK_IN',
      reason: 'Purchase Receipt', status: 'completed', source: null, destination: 'Main Warehouse',
      operationDate: 'May 09, 2026', postingDate: 'May 09, 2026',
      createdBy: 'Abebe Mola', approvedBy: 'Selam Girma', remarks: '',
    },
    valuation: { quantity: 18, unitCost: 7400.0, totalCost: 133200.0, remainingQty: 18, costingRule: 'FIFO' },
    summaryBefore: { physical: 6, reserved: 0, available: 6 },
    summaryAfter: { physical: 24, reserved: 0, available: 24 },
  },
]);

const searchQuery = ref('');
const filterOperation = ref('All');
const showFilterPanel = ref(false);

const formatETB = (n: number) =>
  'ETB ' + Math.abs(n).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

type OpKey = 'STOCK_IN' | 'STOCK_OUT' | 'TRANSFER_IN' | 'TRANSFER_OUT' | 'ADJUSTMENT_PLUS' | 'ADJUSTMENT_MINUS';
const opMeta = (op: string) => {
  const map: Record<OpKey, { icon: any; cls: string; label: string }> = {
    STOCK_IN: { icon: ArrowDownLeft, cls: 'op-in', label: 'Stock In' },
    STOCK_OUT: { icon: ArrowUpRight, cls: 'op-out', label: 'Stock Out' },
    TRANSFER_IN: { icon: ArrowLeftRight, cls: 'op-transfer', label: 'Transfer In' },
    TRANSFER_OUT: { icon: ArrowLeftRight, cls: 'op-transfer', label: 'Transfer Out' },
    ADJUSTMENT_PLUS: { icon: SlidersHorizontal, cls: 'op-adjust', label: 'Adjustment +' },
    ADJUSTMENT_MINUS: { icon: SlidersHorizontal, cls: 'op-adjust', label: 'Adjustment −' },
  };
  return map[op as OpKey] ?? { icon: ArrowDownLeft, cls: '', label: op };
};

const statusClass = (status: string) => {
  switch (status) {
    case 'completed': return 'badge-green';
    case 'posted': return 'badge-blue';
    case 'pending': return 'badge-amber';
    case 'draft': return 'badge-gray';
    case 'cancelled':
    case 'rejected': return 'badge-red';
    default: return 'badge-gray';
  }
};
const cap = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

const filteredRows = computed(() =>
  ledgerRows.value.filter((r) => {
    const q = searchQuery.value.toLowerCase();
    const matchesSearch = q === '' ||
      r.product.toLowerCase().includes(q) ||
      r.document.number.toLowerCase().includes(q) ||
      r.location.toLowerCase().includes(q) ||
      r.id.toLowerCase().includes(q);
    const matchesOp = filterOperation.value === 'All' || r.operation === filterOperation.value;
    return matchesSearch && matchesOp;
  })
);

const resetFilters = () => {
  searchQuery.value = '';
  filterOperation.value = 'All';
};

// ---- Action menu + detail drawer ----
type LedgerRow = (typeof ledgerRows.value)[number];
const activeMenuId = ref<string | null>(null);
const drawerRow = ref<LedgerRow | null>(null);

const toggleMenu = (e: Event, id: string) => {
  e.stopPropagation();
  activeMenuId.value = activeMenuId.value === id ? null : id;
};
const closeMenus = () => { activeMenuId.value = null; };

const openDrawer = (row: LedgerRow) => {
  drawerRow.value = row;
  activeMenuId.value = null;
};
const closeDrawer = () => { drawerRow.value = null; };

const goToDocument = (row: LedgerRow) => {
  activeMenuId.value = null;
  alert(`Navigating to document ${row.document.number} (${row.document.typeName}).\n\nIn the connected system this opens the full document record.`);
};
const goToOperation = (row: LedgerRow) => {
  activeMenuId.value = null;
  alert(`Navigating to Stock Operation ${row.operationDoc.barcode} (${opMeta(row.operation).label}).`);
};

const onKeydown = (e: KeyboardEvent) => { if (e.key === 'Escape') closeDrawer(); };

onMounted(() => {
  window.addEventListener('click', closeMenus);
  window.addEventListener('keydown', onKeydown);
});
onUnmounted(() => {
  window.removeEventListener('click', closeMenus);
  window.removeEventListener('keydown', onKeydown);
});
</script>

<template>
  <div class="stock-ledger-page">
    <!-- Breadcrumbs -->
    <div class="breadcrumbs">
      <router-link to="/dashboard" class="breadcrumb-link">
        <Monitor :size="16" />
      </router-link>
      <ChevronRight :size="12" class="breadcrumb-separator" />
      <router-link to="/stock-summary" class="breadcrumb-mid">Stock Summary</router-link>
      <ChevronRight :size="12" class="breadcrumb-separator" />
      <span class="breadcrumb-active">Stock Ledger</span>
    </div>

    <div class="content-card">
      <header class="page-header">
        <div class="title-area">
          <h1 class="page-title">Stock Ledger</h1>
          <p class="page-description">
            Immutable record of every stock movement. Each entry traces back to a StockOperation and its source Document —
            and records the valuation layer it priced and the on-hand balance it updated. Use the row action to inspect the
            full chain of changes.
          </p>
        </div>
      </header>

      <!-- Action bar -->
      <div class="action-bar">
        <div class="action-bar-left">
          <div class="search-input-wrapper">
            <Search :size="18" class="search-icon" />
            <input v-model="searchQuery" type="text" placeholder="Search by product, document, location or ledger ID..." class="table-search" />
          </div>
          <BaseButton
            variant="secondary"
            :active="showFilterPanel || filterOperation !== 'All'"
            @click="showFilterPanel = !showFilterPanel"
          >
            <template #icon-left><Filter :size="16" /></template>
            <span>Filter</span>
          </BaseButton>
        </div>
      </div>

      <!-- Filter panel -->
      <transition name="slide-down">
        <div v-if="showFilterPanel" class="filter-panel">
          <div class="filter-group">
            <label class="filter-label">Operation</label>
            <select v-model="filterOperation" class="filter-select">
              <option value="All">All Operations</option>
              <option value="STOCK_IN">Stock In</option>
              <option value="STOCK_OUT">Stock Out</option>
              <option value="TRANSFER_OUT">Transfer Out</option>
              <option value="TRANSFER_IN">Transfer In</option>
              <option value="ADJUSTMENT_MINUS">Adjustment −</option>
              <option value="ADJUSTMENT_PLUS">Adjustment +</option>
            </select>
          </div>
          <BaseButton variant="secondary" size="sm" @click="resetFilters">
            <template #icon-left><RotateCcw :size="14" /></template>
            <span>Reset Filters</span>
          </BaseButton>
        </div>
      </transition>

      <!-- Table -->
      <div class="table-wrapper">
        <table class="ledger-table">
          <thead>
            <tr>
              <th width="130">Ledger ID</th>
              <th width="170">Date</th>
              <th width="150">Document</th>
              <th>Product</th>
              <th width="140">Operation</th>
              <th width="90" class="text-right">Qty</th>
              <th width="140" class="text-right">Unit Cost</th>
              <th width="70" class="text-center">Action</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in filteredRows" :key="row.id" class="ledger-row" @click="openDrawer(row)">
              <td class="font-medium text-gray-800">{{ row.id }}</td>
              <td class="text-gray-500">{{ row.date }}</td>
              <td class="text-gray-700">{{ row.document.number }}</td>
              <td class="text-gray-700">{{ row.product }}</td>
              <td>
                <span class="op-badge" :class="opMeta(row.operation).cls">
                  <component :is="opMeta(row.operation).icon" :size="14" />
                  {{ opMeta(row.operation).label }}
                </span>
              </td>
              <td class="text-right font-semibold" :class="row.qty >= 0 ? 'text-emerald-600' : 'text-red-600'">
                {{ row.qty >= 0 ? '+' : '' }}{{ row.qty }}
              </td>
              <td class="text-right text-gray-700">{{ formatETB(row.unitCost) }}</td>
              <td class="text-center" @click.stop>
                <div class="action-menu-container">
                  <button @click="toggleMenu($event, row.id)" class="btn-three-dots" :class="{ active: activeMenuId === row.id }" title="Actions">
                    <MoreVertical :size="18" />
                  </button>
                  <div v-if="activeMenuId === row.id" class="action-dropdown-menu" @click.stop>
                    <button class="action-dropdown-item" @click="openDrawer(row)">
                      <Eye :size="15" class="text-gray-500" />
                      <span>View</span>
                    </button>
                    <button class="action-dropdown-item" @click="goToDocument(row)">
                      <FileText :size="15" class="text-gray-500" />
                      <span>Go to Document</span>
                    </button>
                    <button class="action-dropdown-item" @click="goToOperation(row)">
                      <ClipboardList :size="15" class="text-gray-500" />
                      <span>Go to Stock Operation</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
            <tr v-if="filteredRows.length === 0">
              <td colspan="8" class="empty-state">No ledger entries match your filters.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Footer -->
      <div class="table-footer">
        <div class="footer-info">Showing 1 to {{ filteredRows.length }} of {{ ledgerRows.length }} entries</div>
        <div class="pagination-controls">
          <button class="page-nav-btn"><ArrowLeft :size="14" class="mr-1" /> Previous</button>
          <button class="page-num active">1</button>
          <button class="page-num">2</button>
          <button class="page-num">3</button>
          <button class="page-nav-btn">Next <ArrowRight :size="14" class="ml-1" /></button>
        </div>
      </div>
    </div>

    <!-- DETAIL DRAWER -->
    <transition name="drawer">
      <div v-if="drawerRow" class="drawer-overlay" @click.self="closeDrawer">
        <aside class="drawer">
          <!-- Header -->
          <header class="drawer-header">
            <div class="drawer-head-left">
              <span class="op-badge lg" :class="opMeta(drawerRow.operation).cls">
                <component :is="opMeta(drawerRow.operation).icon" :size="15" />
                {{ opMeta(drawerRow.operation).label }}
              </span>
              <div>
                <h2 class="drawer-title">{{ drawerRow.id }}</h2>
                <p class="drawer-subtitle">Full traceability of this stock movement</p>
              </div>
            </div>
            <button class="drawer-close" @click="closeDrawer"><X :size="18" /></button>
          </header>

          <div class="drawer-body">
            <!-- Movement summary -->
            <div class="movement-summary">
              <div class="movement-qty" :class="drawerRow.qty >= 0 ? 'pos' : 'neg'">
                {{ drawerRow.qty >= 0 ? '+' : '' }}{{ drawerRow.qty }}
                <span class="movement-uom">{{ drawerRow.measurement }}</span>
              </div>
              <div class="movement-meta">
                <span class="movement-product">{{ drawerRow.product }}</span>
                <span class="movement-loc"><MapPin :size="13" /> {{ drawerRow.location }} · {{ drawerRow.date }}</span>
              </div>
            </div>

            <!-- Quantity & cost -->
            <section class="drawer-section">
              <h3 class="section-title"><Coins :size="15" /> Quantity &amp; Cost</h3>
              <div class="detail-grid">
                <div class="detail"><span class="d-label">Quantity</span><span class="d-value">{{ drawerRow.qty >= 0 ? '+' : '' }}{{ drawerRow.qty }} {{ drawerRow.measurement }}</span></div>
                <div class="detail"><span class="d-label">Unit Cost</span><span class="d-value">{{ formatETB(drawerRow.unitCost) }}</span></div>
                <div class="detail"><span class="d-label">Total Cost</span><span class="d-value">{{ formatETB(drawerRow.unitCost * Math.abs(drawerRow.qty)) }}</span></div>
                <div class="detail"><span class="d-label">Unit Price</span><span class="d-value">{{ drawerRow.unitPrice ? formatETB(drawerRow.unitPrice) : '—' }}</span></div>
                <div class="detail"><span class="d-label">Entity</span><span class="d-value">{{ drawerRow.entity }}</span></div>
                <div class="detail"><span class="d-label">Ledgered By</span><span class="d-value">{{ drawerRow.actor }}</span></div>
              </div>
            </section>

            <!-- Product & batch -->
            <section class="drawer-section">
              <h3 class="section-title"><Package :size="15" /> Product &amp; Batch</h3>
              <div class="detail-grid">
                <div class="detail"><span class="d-label">Product</span><span class="d-value">{{ drawerRow.product }}</span></div>
                <div class="detail"><span class="d-label">SKU</span><span class="d-value">{{ drawerRow.sku }}</span></div>
                <div class="detail"><span class="d-label">Measurement</span><span class="d-value">{{ drawerRow.measurement }}</span></div>
                <div class="detail"><span class="d-label">Batch No</span><span class="d-value">{{ drawerRow.batch ?? '—' }}</span></div>
                <div class="detail"><span class="d-label">Serial No</span><span class="d-value">{{ drawerRow.serial ?? '—' }}</span></div>
                <div class="detail"><span class="d-label">Location</span><span class="d-value">{{ drawerRow.location }}</span></div>
              </div>
            </section>

            <!-- Source document -->
            <section class="drawer-section">
              <div class="section-head-row">
                <h3 class="section-title"><FileText :size="15" /> Source Document</h3>
                <button class="btn-link-open" @click="goToDocument(drawerRow)">Open <ExternalLink :size="13" /></button>
              </div>
              <div class="detail-grid">
                <div class="detail"><span class="d-label">Document No</span><span class="d-value strong">{{ drawerRow.document.number }}</span></div>
                <div class="detail"><span class="d-label">Type</span><span class="d-value">{{ drawerRow.document.typeName }} ({{ drawerRow.document.typeCode }})</span></div>
                <div class="detail"><span class="d-label">Document Date</span><span class="d-value">{{ drawerRow.document.date }}</span></div>
                <div class="detail"><span class="d-label">Posting Date</span><span class="d-value">{{ drawerRow.document.postingDate }}</span></div>
                <div class="detail"><span class="d-label">Status</span><span class="badge" :class="statusClass(drawerRow.document.status)">{{ cap(drawerRow.document.status) }}</span></div>
                <div class="detail"><span class="d-label">Posting</span><span class="badge" :class="statusClass(drawerRow.document.posting)">{{ cap(drawerRow.document.posting) }}</span></div>
                <div class="detail"><span class="d-label">Reference</span><span class="d-value">{{ drawerRow.document.reference }}</span></div>
                <div class="detail"><span class="d-label">Created By</span><span class="d-value">{{ drawerRow.document.createdBy }}</span></div>
                <div class="detail"><span class="d-label">Approved By</span><span class="d-value">{{ drawerRow.document.approvedBy }}</span></div>
                <div class="detail full"><span class="d-label">Remarks</span><span class="d-value">{{ drawerRow.document.remarks || '—' }}</span></div>
              </div>
            </section>

            <!-- Stock operation -->
            <section class="drawer-section">
              <div class="section-head-row">
                <h3 class="section-title"><ClipboardList :size="15" /> Stock Operation</h3>
                <button class="btn-link-open" @click="goToOperation(drawerRow)">Open <ExternalLink :size="13" /></button>
              </div>
              <div class="detail-grid">
                <div class="detail"><span class="d-label">Operation</span><span class="d-value">{{ drawerRow.operationDoc.name }}</span></div>
                <div class="detail"><span class="d-label">Barcode</span><span class="d-value">{{ drawerRow.operationDoc.barcode }}</span></div>
                <div class="detail"><span class="d-label">Type</span><span class="d-value">{{ opMeta(drawerRow.operation).label }}</span></div>
                <div class="detail"><span class="d-label">Reason</span><span class="d-value">{{ drawerRow.operationDoc.reason }}</span></div>
                <div class="detail full">
                  <span class="d-label">Movement</span>
                  <span class="d-value flow">
                    {{ drawerRow.operationDoc.source ?? 'External' }}
                    <ArrowRight :size="14" class="flow-arrow" />
                    {{ drawerRow.operationDoc.destination ?? 'External' }}
                  </span>
                </div>
                <div class="detail"><span class="d-label">Status</span><span class="badge" :class="statusClass(drawerRow.operationDoc.status)">{{ cap(drawerRow.operationDoc.status) }}</span></div>
                <div class="detail"><span class="d-label">Operation Date</span><span class="d-value">{{ drawerRow.operationDoc.operationDate }}</span></div>
                <div class="detail"><span class="d-label">Created By</span><span class="d-value">{{ drawerRow.operationDoc.createdBy }}</span></div>
                <div class="detail"><span class="d-label">Approved By</span><span class="d-value">{{ drawerRow.operationDoc.approvedBy }}</span></div>
                <div class="detail full"><span class="d-label">Remarks</span><span class="d-value">{{ drawerRow.operationDoc.remarks || '—' }}</span></div>
              </div>
            </section>

            <!-- System effects header -->
            <div class="effects-banner">
              <Layers :size="14" />
              System effects — derived records this movement updated
            </div>

            <!-- Inventory valuation layer -->
            <section class="drawer-section">
              <h3 class="section-title"><Coins :size="15" /> Inventory Valuation Layer</h3>
              <div class="detail-grid">
                <div class="detail"><span class="d-label">Costing Rule</span><span class="d-value">{{ drawerRow.valuation.costingRule }}</span></div>
                <div class="detail"><span class="d-label">Layer Quantity</span><span class="d-value">{{ drawerRow.valuation.quantity }} {{ drawerRow.measurement }}</span></div>
                <div class="detail"><span class="d-label">Unit Cost</span><span class="d-value">{{ formatETB(drawerRow.valuation.unitCost) }}</span></div>
                <div class="detail"><span class="d-label">Total Cost</span><span class="d-value">{{ formatETB(drawerRow.valuation.totalCost) }}</span></div>
                <div class="detail"><span class="d-label">Remaining Qty</span><span class="d-value">{{ drawerRow.valuation.remainingQty }} {{ drawerRow.measurement }}</span></div>
              </div>
            </section>

            <!-- Stock summary balance impact -->
            <section class="drawer-section">
              <h3 class="section-title"><Boxes :size="15" /> Stock Balance Impact</h3>
              <p class="section-note">Cached StockSummary balance for this product &amp; location, before and after the movement.</p>
              <div class="balance-grid">
                <div class="balance-row balance-head">
                  <span></span><span>Physical</span><span>Reserved</span><span>Available</span>
                </div>
                <div class="balance-row">
                  <span class="balance-label">Before</span>
                  <span>{{ drawerRow.summaryBefore.physical }}</span>
                  <span>{{ drawerRow.summaryBefore.reserved }}</span>
                  <span>{{ drawerRow.summaryBefore.available }}</span>
                </div>
                <div class="balance-row after">
                  <span class="balance-label"><ArrowRightLeft :size="12" /> After</span>
                  <span class="strong">{{ drawerRow.summaryAfter.physical }}</span>
                  <span class="strong">{{ drawerRow.summaryAfter.reserved }}</span>
                  <span class="strong">{{ drawerRow.summaryAfter.available }}</span>
                </div>
              </div>
            </section>
          </div>

          <!-- Footer -->
          <footer class="drawer-footer">
            <button class="btn-secondary" @click="closeDrawer">Close</button>
            <button class="btn-primary" @click="goToDocument(drawerRow)">
              <FileText :size="16" />
              Open Document
            </button>
          </footer>
        </aside>
      </div>
    </transition>
  </div>
</template>

<style scoped>
.stock-ledger-page {
  animation: fadeIn 0.4s ease-out;
  display: flex;
  flex-direction: column;
  gap: 16px;
}
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Breadcrumbs */
.breadcrumbs { display: flex; align-items: center; gap: 8px; font-size: 13px; }
.breadcrumb-link { color: #9ca3af; text-decoration: none; display: flex; align-items: center; transition: color 0.15s ease; }
.breadcrumb-link:hover { color: #111827; }
.breadcrumb-mid { color: #6b7280; text-decoration: none; transition: color 0.15s ease; }
.breadcrumb-mid:hover { color: #111827; }
.breadcrumb-separator { color: #9ca3af; display: flex; align-items: center; }
.breadcrumb-active { color: #111827; font-weight: 500; }

/* Content card */
.content-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
  overflow: hidden;
}
.page-header { padding: 16px 16px 8px 16px; }
.page-title { font-size: 24px; font-weight: 700; color: #111827; margin-bottom: 8px; }
.page-description { font-size: 14px; color: #6b7280; line-height: 1.6; max-width: 920px; }

/* Action bar */
.action-bar { display: flex; align-items: center; justify-content: space-between; padding: 0 16px 12px 16px; gap: 16px; }
.action-bar-left { display: flex; align-items: center; gap: 12px; flex: 1; }
.search-input-wrapper { position: relative; flex: 1; max-width: 380px; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; z-index: 10; }
.table-search {
  width: 100%;
  padding: 10px 12px 10px 40px;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  font-size: 14px;
  outline: none;
  height: 42px;
  background: white;
  transition: all 0.2s;
}
.table-search:focus { border-color: #d1d5db; box-shadow: 0 0 0 4px rgba(0, 0, 0, 0.02); }
.btn-filter {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 16px;
  height: 42px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 500;
  color: #374151;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-filter:hover { background: #f9fafb; border-color: #d1d5db; }
.btn-filter.active { background: #f3f4f6; color: #111827; border-color: #d1d5db; }

/* Filter panel */
.filter-panel {
  display: flex;
  align-items: flex-end;
  gap: 20px;
  background: #f9fafb;
  border-top: 1px solid #e5e7eb;
  border-bottom: 1px solid #e5e7eb;
  padding: 12px 16px;
  animation: slideDown 0.2s ease-out;
}
@keyframes slideDown {
  from { opacity: 0; transform: translateY(-8px); }
  to { opacity: 1; transform: translateY(0); }
}
.filter-group { display: flex; flex-direction: column; gap: 6px; min-width: 220px; }
.filter-label { font-size: 11px; font-weight: 700; color: #6b7280; text-transform: uppercase; letter-spacing: 0.05em; }
.filter-select {
  width: 100%;
  height: 40px;
  padding: 0 32px 0 12px;
  background: white url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e") no-repeat right 12px center/16px;
  appearance: none;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13px;
  color: #374151;
  outline: none;
  cursor: pointer;
}
.filter-select:focus { border-color: #111827; box-shadow: 0 0 0 1px #111827; }
.btn-reset-filters {
  height: 40px;
  padding: 0 16px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13px;
  color: #374151;
  font-weight: 500;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.15s ease;
}
.btn-reset-filters:hover { background: #f9fafb; border-color: #d1d5db; }

/* Table */
.table-wrapper { overflow-x: auto; border-top: 1px solid #e5e7eb; border-bottom: 1px solid #e5e7eb; background: white; }
.ledger-table { width: 100%; border-collapse: collapse; }
.ledger-table th {
  text-align: left;
  padding: 12px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background: #fafafa;
  border-bottom: 1px solid #e5e7eb;
  white-space: nowrap;
}
.ledger-table td {
  padding: 12px 16px;
  font-size: 13.5px;
  color: #737373;
  border-bottom: 1px solid #f3f4f6;
  vertical-align: middle;
}
.ledger-table td:first-child {
  color: #262626;
  font-weight: 600;
}
.ledger-table tr:last-child td { border-bottom: none; }
.ledger-row { cursor: pointer; transition: background 0.12s ease; }
.ledger-row:hover { background: #f9fafb; }
.text-right { text-align: right; }
.text-center { text-align: center; }

.op-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 500;
  white-space: nowrap;
}
.op-badge.lg { padding: 5px 12px; font-size: 12.5px; }
.op-in { background: #ecfdf5; color: #059669; }
.op-out { background: #fef2f2; color: #dc2626; }
.op-transfer { background: #eff6ff; color: #155dfc; }
.op-adjust { background: #fffbeb; color: #b45309; }

.empty-state { text-align: center; color: #9ca3af; padding: 32px 16px; font-size: 14px; }

/* Row action menu */
.action-menu-container { position: relative; display: inline-block; }
.btn-three-dots {
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  padding: 6px;
  border-radius: 8px;
  display: flex;
  transition: all 0.15s ease;
}
.btn-three-dots:hover, .btn-three-dots.active { background: #f3f4f6; color: #111827; }
.action-dropdown-menu {
  position: absolute;
  top: 100%;
  right: 0;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.08), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
  z-index: 50;
  min-width: 200px;
  padding: 6px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  animation: dropFade 0.15s ease-out;
}
@keyframes dropFade {
  from { opacity: 0; transform: translateY(-5px); }
  to { opacity: 1; transform: translateY(0); }
}
.action-dropdown-item {
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
.action-dropdown-item:hover { background: #f1f5f9; color: #0f172a; }

/* Footer */
.table-footer { display: flex; justify-content: space-between; align-items: center; padding: 12px 16px 16px 16px; }
.footer-info { font-size: 13px; color: #6b7280; }
.pagination-controls {
  display: flex;
  align-items: center;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  overflow: hidden;
  background: white;
}
.page-nav-btn, .page-num {
  border: none;
  border-right: 1px solid #e5e7eb;
  background: white;
  color: #374151;
  height: 36px;
  padding: 0 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}
.page-nav-btn:last-child { border-right: none; }
.page-num { width: 36px; padding: 0; }
.page-num.active { background: #111827; color: white; font-weight: 600; }
.page-nav-btn:hover, .page-num:hover:not(.active) { background: #f9fafb; color: #111827; }
.mr-1 { margin-right: 4px; }
.ml-1 { margin-left: 4px; }

/* ===== DETAIL DRAWER ===== */
.drawer-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.4);
  backdrop-filter: blur(3px);
  z-index: 1100;
  display: flex;
  justify-content: flex-end;
}
.drawer {
  width: 540px;
  max-width: 94vw;
  height: 100%;
  background: #ffffff;
  display: flex;
  flex-direction: column;
  box-shadow: -12px 0 30px -10px rgba(0, 0, 0, 0.18);
}

/* Drawer transition */
.drawer-enter-active, .drawer-leave-active { transition: opacity 0.25s ease; }
.drawer-enter-active .drawer, .drawer-leave-active .drawer { transition: transform 0.28s cubic-bezier(0.4, 0, 0.2, 1); }
.drawer-enter-from, .drawer-leave-to { opacity: 0; }
.drawer-enter-from .drawer, .drawer-leave-to .drawer { transform: translateX(100%); }

.drawer-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  padding: 20px 24px;
  border-bottom: 1px solid #f1f5f9;
  flex-shrink: 0;
}
.drawer-head-left { display: flex; align-items: center; gap: 14px; }
.drawer-title { font-size: 18px; font-weight: 700; color: #0f172a; }
.drawer-subtitle { font-size: 12.5px; color: #94a3b8; margin-top: 2px; }
.drawer-close {
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 6px;
  border-radius: 8px;
  display: flex;
  transition: all 0.15s ease;
}
.drawer-close:hover { background: #f1f5f9; color: #475569; }

.drawer-body { flex: 1; overflow-y: auto; padding: 20px 24px; }

/* Movement summary */
.movement-summary {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  border: 1px solid #f1f5f9;
  border-radius: 12px;
  background: #fafafa;
  margin-bottom: 8px;
}
.movement-qty { font-size: 26px; font-weight: 700; white-space: nowrap; }
.movement-qty.pos { color: #059669; }
.movement-qty.neg { color: #dc2626; }
.movement-uom { font-size: 13px; font-weight: 500; color: #94a3b8; margin-left: 4px; }
.movement-meta { display: flex; flex-direction: column; gap: 4px; }
.movement-product { font-size: 15px; font-weight: 600; color: #111827; }
.movement-loc { display: inline-flex; align-items: center; gap: 5px; font-size: 12.5px; color: #6b7280; }

/* Sections */
.drawer-section { padding: 18px 0; border-bottom: 1px solid #f1f5f9; }
.section-head-row { display: flex; align-items: center; justify-content: space-between; }
.section-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  font-weight: 700;
  color: #334155;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  margin-bottom: 14px;
}
.section-title svg { color: #94a3b8; }
.section-note { font-size: 12px; color: #94a3b8; margin: -8px 0 12px; }

.detail-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px 20px;
}
.detail { display: flex; flex-direction: column; gap: 3px; min-width: 0; }
.detail.full { grid-column: span 2; }
.d-label { font-size: 11px; font-weight: 700; color: #9ca3af; text-transform: uppercase; letter-spacing: 0.04em; }
.d-value { font-size: 13.5px; color: #334155; word-break: break-word; }
.d-value.strong { font-weight: 600; color: #0f172a; }
.d-value.flow { display: inline-flex; align-items: center; gap: 8px; font-weight: 500; }
.flow-arrow { color: #94a3b8; }

.btn-link-open {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  background: none;
  border: none;
  color: var(--alias-color-brand-blue-primary);
  font-size: 12.5px;
  font-weight: 600;
  cursor: pointer;
  padding: 0;
  margin-bottom: 14px;
}
.btn-link-open:hover { text-decoration: underline; }

/* Status badges */
.badge {
  display: inline-flex;
  align-items: center;
  width: fit-content;
  padding: 3px 10px;
  border-radius: 20px;
  font-size: 11.5px;
  font-weight: 600;
}
.badge-green { background: #ecfdf5; color: #059669; }
.badge-blue { background: #eff6ff; color: #155dfc; }
.badge-amber { background: #fffbeb; color: #b45309; }
.badge-gray { background: #f3f4f6; color: #6b7280; }
.badge-red { background: #fef2f2; color: #dc2626; }

/* System effects banner */
.effects-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 18px;
  padding: 10px 14px;
  background: var(--alias-color-brand-blue-primary-surface, #f1f7fe);
  border: 1px solid var(--alias-color-border-brand-subtle, #bddbfa);
  border-radius: 10px;
  font-size: 12.5px;
  font-weight: 600;
  color: var(--alias-color-brand-blue-primary, #0b529c);
}
.effects-banner svg { color: var(--alias-color-brand-blue-primary, #0b529c); }

/* Balance impact */
.balance-grid { display: flex; flex-direction: column; gap: 6px; }
.balance-row {
  display: grid;
  grid-template-columns: 1.2fr 1fr 1fr 1fr;
  align-items: center;
  padding: 9px 12px;
  border-radius: 8px;
  font-size: 13.5px;
  color: #334155;
}
.balance-row span:not(:first-child) { text-align: right; }
.balance-head { font-size: 11px; font-weight: 700; color: #9ca3af; text-transform: uppercase; letter-spacing: 0.04em; padding: 0 12px; }
.balance-row.after { background: #f0f9ff; }
.balance-label { display: inline-flex; align-items: center; gap: 5px; font-weight: 600; color: #475569; }
.balance-row .strong { font-weight: 700; color: #0f172a; }

/* Drawer footer */
.drawer-footer {
  display: flex;
  gap: 12px;
  padding: 16px 24px;
  border-top: 1px solid #f1f5f9;
  flex-shrink: 0;
}
.btn-secondary {
  flex: 0 0 auto;
  padding: 10px 20px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 500;
  color: #374151;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-secondary:hover { background: #f9fafb; border-color: #d1d5db; }
.btn-primary {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 10px 20px;
  background: var(--alias-color-brand-blue-primary);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}
.btn-primary:hover { background: var(--alias-color-brand-blue-primary-hover); }
</style>
