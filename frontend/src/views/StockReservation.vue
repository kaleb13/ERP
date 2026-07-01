<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from "vue";
import {
  Plus, Search, Filter, MoreVertical,
  Maximize, ChevronLeft, ChevronRight, Monitor,
  Columns, ArrowUpDown, ChevronDown, ArrowLeft, ArrowRight, RotateCcw,
  Eye, Edit2, Trash2, X, HelpCircle
} from "lucide-vue-next";

interface StockReservation {
  id: number;
  documentNo: string;
  location: string;
  product: string;
  batchNo: string | null;
  measurement: string;
  quantity: number;
  state: "Active" | "Inactive";
}

const reservations = ref<StockReservation[]>([
  { id: 1, documentNo: "SR-2026-0001", location: "Main Warehouse", product: "Notebook A5 (STN-4003)", batchNo: "BCH-1001", measurement: "Pcs", quantity: 10, state: "Active" },
  { id: 2, documentNo: "SR-2026-0001", location: "Main Warehouse", product: "Printer Ink (CY-120)", batchNo: "BCH-1002", measurement: "Box", quantity: 2, state: "Active" },
  { id: 3, documentNo: "SR-2026-0002", location: "Warehouse - 22", product: "Bluetooth Speaker (SPK-3005)", batchNo: null, measurement: "Pcs", quantity: 15, state: "Active" },
  { id: 4, documentNo: "SR-2026-0003", location: "Store - A", product: "Wireless Mouse (MOU-9001)", batchNo: "BCH-3001", measurement: "Pcs", quantity: 5, state: "Inactive" },
]);

const activeActionMenuId = ref<number | null>(null);
const showViewModal = ref(false);
const viewItem = ref<StockReservation | null>(null);

const toggleActionMenu = (e: Event, id: number) => {
  e.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeAllMenus = () => { activeActionMenuId.value = null; };

onMounted(() => window.addEventListener("click", closeAllMenus));
onUnmounted(() => window.removeEventListener("click", closeAllMenus));

const triggerView = (item: StockReservation) => {
  viewItem.value = item;
  showViewModal.value = true;
  closeAllMenus();
};

const triggerEdit = (item: StockReservation) => {
  alert("Editing " + item.documentNo + ". In a fully connected server database system, this would load the record into the document editor.");
  closeAllMenus();
};

const triggerDelete = (id: number) => {
  if (!confirm("Are you sure you want to delete this reservation record?")) return;
  reservations.value = reservations.value.filter(r => r.id !== id);
  closeAllMenus();
};

const selectedRows = ref<number[]>([]);
const selectAll = ref(false);
const toggleSelectAll = () => {
  if (selectAll.value) {
    selectedRows.value = filteredReservations.value.map(r => r.id);
  } else {
    selectedRows.value = [];
  }
};

const visibleColumns = ref({
  documentNo: true,
  location: true,
  product: true,
  batchNo: true,
  measurement: true,
  quantity: true,
  state: true,
  action: true,
});

const showColumnDropdown = ref(false);
const showSortDropdown = ref(false);
const showFilterPanel = ref(false);
const activeSort = ref("doc-asc");
const isFullscreen = ref(false);

const searchQuery = ref("");
const filterLocation = ref("All");
const filterState = ref("All");

const toggleColumnDropdown = () => {
  showColumnDropdown.value = !showColumnDropdown.value;
  if (showColumnDropdown.value) showSortDropdown.value = false;
};
const toggleSortDropdown = () => {
  showSortDropdown.value = !showSortDropdown.value;
  if (showSortDropdown.value) showColumnDropdown.value = false;
};
const toggleFilterPanel = () => { showFilterPanel.value = !showFilterPanel.value; };

const resetFilters = () => {
  filterLocation.value = "All";
  filterState.value = "All";
  searchQuery.value = "";
};

const applySort = (type: string) => {
  activeSort.value = type;
  showSortDropdown.value = false;
  if (type === "doc-asc") {
    reservations.value.sort((a, b) => a.documentNo.localeCompare(b.documentNo));
  } else if (type === "doc-desc") {
    reservations.value.sort((a, b) => b.documentNo.localeCompare(a.documentNo));
  } else if (type === "qty-asc") {
    reservations.value.sort((a, b) => a.quantity - b.quantity);
  } else if (type === "qty-desc") {
    reservations.value.sort((a, b) => b.quantity - a.quantity);
  }
};

const toggleFullscreen = () => { isFullscreen.value = !isFullscreen.value; };

const filteredReservations = computed(() => {
  return reservations.value.filter(r => {
    const q = searchQuery.value.toLowerCase();
    const matchesSearch = q === "" ||
      r.documentNo.toLowerCase().includes(q) ||
      r.location.toLowerCase().includes(q) ||
      r.product.toLowerCase().includes(q) ||
      (r.batchNo && r.batchNo.toLowerCase().includes(q));
    const matchesLocation = filterLocation.value === "All" || r.location === filterLocation.value;
    const matchesState = filterState.value === "All" || r.state === filterState.value;
    return matchesSearch && matchesLocation && matchesState;
  });
});
</script>
<template>
  <div class="reservation-page">
    <div class="breadcrumbs">
      <router-link to="/dashboard" class="breadcrumb-link"><Monitor :size="16" /></router-link>
      <ChevronRight :size="12" class="breadcrumb-separator" />
      <span class="breadcrumb-active">Stock Reservation</span>
    </div>

    <div :class="['content-card', { 'is-fullscreen': isFullscreen }]">
      <header class="page-header">
        <div class="title-area">
          <h1 class="page-title">Stock Reservation</h1>
          <p class="page-description">View and manage reserved stock lines. Each row represents a single product/batch reservation linked to a document.</p>
        </div>
      </header>

      <div class="action-bar">
        <div class="action-bar-left">
          <div class="search-input-wrapper">
            <Search :size="18" class="search-icon" />
            <input v-model="searchQuery" type="text" placeholder="Search reservations..." class="table-search" />
          </div>
          <button @click="toggleFilterPanel" class="btn-filter" :class="{ active: showFilterPanel }">
            <Filter :size="18" /><span>Filter</span>
          </button>
          <div class="sort-toggle-wrapper">
            <button @click="toggleSortDropdown" class="btn-sort" :class="{ active: showSortDropdown }">
              <ArrowUpDown :size="18" /><span>Sort</span><ChevronDown :size="14" class="ml-1" />
            </button>
            <div v-if="showSortDropdown" class="sort-dropdown-menu">
              <div class="dropdown-header">Sort By</div>
              <button @click="applySort('doc-asc')" class="sort-option" :class="{ active: activeSort === 'doc-asc' }"><span>Document No (A–Z)</span><span v-if="activeSort === 'doc-asc'" class="active-dot"></span></button>
              <button @click="applySort('doc-desc')" class="sort-option" :class="{ active: activeSort === 'doc-desc' }"><span>Document No (Z–A)</span><span v-if="activeSort === 'doc-desc'" class="active-dot"></span></button>
              <button @click="applySort('qty-asc')" class="sort-option" :class="{ active: activeSort === 'qty-asc' }"><span>Quantity (Low–High)</span><span v-if="activeSort === 'qty-asc'" class="active-dot"></span></button>
              <button @click="applySort('qty-desc')" class="sort-option" :class="{ active: activeSort === 'qty-desc' }"><span>Quantity (High–Low)</span><span v-if="activeSort === 'qty-desc'" class="active-dot"></span></button>
            </div>
          </div>
        </div>
        <div class="action-bar-right">
          <div class="column-toggle-wrapper">
            <button @click="toggleColumnDropdown" class="btn-icon-square" :class="{ active: showColumnDropdown }" title="Show/Hide Columns">
              <Columns :size="18" />
            </button>
            <div v-if="showColumnDropdown" class="column-dropdown-menu">
              <div class="dropdown-header">Show/Hide Columns</div>
              <label class="column-option"><input type="checkbox" v-model="visibleColumns.documentNo" /><span>Document No</span></label>
              <label class="column-option"><input type="checkbox" v-model="visibleColumns.location" /><span>Location</span></label>
              <label class="column-option"><input type="checkbox" v-model="visibleColumns.product" /><span>Product</span></label>
              <label class="column-option"><input type="checkbox" v-model="visibleColumns.batchNo" /><span>Batch No</span></label>
              <label class="column-option"><input type="checkbox" v-model="visibleColumns.measurement" /><span>Measurement</span></label>
              <label class="column-option"><input type="checkbox" v-model="visibleColumns.quantity" /><span>Quantity</span></label>
              <label class="column-option"><input type="checkbox" v-model="visibleColumns.state" /><span>State</span></label>
            </div>
          </div>
          <button @click="toggleFullscreen" class="btn-icon-square" :class="{ active: isFullscreen }" title="Toggle Fullscreen">
            <Maximize :size="18" />
          </button>
          <router-link to="/stock-reservation/create" class="btn-create" style="text-decoration:none;">
            <Plus :size="20" /><span>Create Reservation</span>
          </router-link>
        </div>
      </div>

      <transition name="slide-down">
        <div v-if="showFilterPanel" class="filter-panel">
          <div class="filter-group">
            <label class="filter-label">Location</label>
            <select v-model="filterLocation" class="filter-select">
              <option value="All">All Locations</option>
              <option value="Main Warehouse">Main Warehouse</option>
              <option value="Warehouse - 22">Warehouse - 22</option>
              <option value="Store - A">Store - A</option>
            </select>
          </div>
          <div class="filter-group">
            <label class="filter-label">State</label>
            <select v-model="filterState" class="filter-select">
              <option value="All">All States</option>
              <option value="Active">Active</option>
              <option value="Inactive">Inactive</option>
            </select>
          </div>
          <button @click="resetFilters" class="btn-reset-filters">
            <RotateCcw :size="14" /> Reset
          </button>
        </div>
      </transition>

      <div class="table-wrapper">
        <table class="reservation-table">
          <thead>
            <tr>
              <th width="40" class="text-center">
                <input type="checkbox" v-model="selectAll" @change="toggleSelectAll" class="table-checkbox" />
              </th>
              <th v-if="visibleColumns.documentNo" width="160">Document No</th>
              <th v-if="visibleColumns.location" width="160">Location</th>
              <th v-if="visibleColumns.product">Product</th>
              <th v-if="visibleColumns.batchNo" width="130">Batch No</th>
              <th v-if="visibleColumns.measurement" width="120">Measurement</th>
              <th v-if="visibleColumns.quantity" width="110" class="text-right">Quantity</th>
              <th v-if="visibleColumns.state" width="110">State</th>
              <th v-if="visibleColumns.action" width="80" class="text-center">Action</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in filteredReservations" :key="item.id" :class="{ 'row-selected': selectedRows.includes(item.id) }">
              <td class="text-center">
                <input type="checkbox" v-model="selectedRows" :value="item.id" class="table-checkbox" />
              </td>
              <td v-if="visibleColumns.documentNo" class="font-medium text-gray-800">{{ item.documentNo }}</td>
              <td v-if="visibleColumns.location" class="text-gray-600">{{ item.location }}</td>
              <td v-if="visibleColumns.product" class="text-gray-800 font-medium">{{ item.product }}</td>
              <td v-if="visibleColumns.batchNo" class="text-gray-500">{{ item.batchNo ?? '—' }}</td>
              <td v-if="visibleColumns.measurement" class="text-gray-600">{{ item.measurement }}</td>
              <td v-if="visibleColumns.quantity" class="text-right font-semibold text-gray-800">{{ item.quantity }}</td>
              <td v-if="visibleColumns.state">
                <span :class="['state-badge', item.state === 'Active' ? 'state-active' : 'state-inactive']">
                  <span class="dot"></span>{{ item.state }}
                </span>
              </td>
              <td v-if="visibleColumns.action" class="text-center">
                <div class="action-menu-container">
                  <button @click="toggleActionMenu($event, item.id)" class="btn-three-dots">
                    <MoreVertical :size="18" />
                  </button>
                  <div v-if="activeActionMenuId === item.id" class="action-dropdown-menu" @click.stop>
                    <button @click="triggerView(item)" class="action-dropdown-item"><Eye :size="14" /><span>View</span></button>
                    <button @click="triggerEdit(item)" class="action-dropdown-item"><Edit2 :size="14" /><span>Edit</span></button>
                    <div class="dropdown-divider"></div>
                    <button @click="triggerDelete(item.id)" class="action-dropdown-item item-danger"><Trash2 :size="14" /><span>Delete</span></button>
                  </div>
                </div>
              </td>
            </tr>
            <tr v-if="filteredReservations.length === 0">
              <td colspan="9" class="empty-row">No reservations found.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="table-footer">
        <div class="footer-info">Showing {{ filteredReservations.length }} of {{ reservations.length }} entries</div>
        <div class="pagination-controls">
          <button class="page-nav-btn" disabled><ArrowLeft :size="14" class="mr-1" />Previous</button>
          <button class="page-num active">1</button>
          <button class="page-nav-btn" disabled>Next<ArrowRight :size="14" class="ml-1" /></button>
        </div>
      </div>

      <!-- VIEW MODAL -->
      <div v-if="showViewModal" class="modal-overlay" @click.self="showViewModal = false">
        <div class="modal-card">
          <button class="modal-close-btn" @click="showViewModal = false"><X :size="18" /></button>
          <header class="modal-card-header">
            <h3>Reservation Detail — {{ viewItem?.documentNo }}</h3>
          </header>
          <div class="modal-body-content">
            <div class="view-details-grid">
              <div class="detail-item"><span class="detail-label">Document No</span><span class="detail-value font-semibold">{{ viewItem?.documentNo }}</span></div>
              <div class="detail-item"><span class="detail-label">Location</span><span class="detail-value">{{ viewItem?.location }}</span></div>
              <div class="detail-item"><span class="detail-label">Product</span><span class="detail-value">{{ viewItem?.product }}</span></div>
              <div class="detail-item"><span class="detail-label">Batch No</span><span class="detail-value">{{ viewItem?.batchNo ?? '—' }}</span></div>
              <div class="detail-item"><span class="detail-label">Measurement</span><span class="detail-value">{{ viewItem?.measurement }}</span></div>
              <div class="detail-item"><span class="detail-label">Quantity</span><span class="detail-value font-semibold">{{ viewItem?.quantity }}</span></div>
              <div class="detail-item"><span class="detail-label">State</span>
                <span :class="['state-badge mt-1', viewItem?.state === 'Active' ? 'state-active' : 'state-inactive']">
                  <span class="dot"></span>{{ viewItem?.state }}
                </span>
              </div>
            </div>
          </div>
          <div class="modal-footer-row">
            <button @click="showViewModal = false" class="btn-modal-close">Close</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.reservation-page { animation: fadeIn 0.3s ease-out; display: flex; flex-direction: column; gap: 16px; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: translateY(0); } }

.breadcrumbs { display: flex; align-items: center; gap: 8px; font-size: 13px; margin-bottom: 20px; }
.breadcrumb-link { color: #9ca3af; text-decoration: none; display: flex; align-items: center; transition: color 0.15s; }
.breadcrumb-link:hover { color: #111827; }
.breadcrumb-separator { color: #9ca3af; }
.breadcrumb-active { color: #111827; font-weight: 500; }

.content-card { background: white; border: 1px solid #e5e7eb; border-radius: 16px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.02); }
.content-card.is-fullscreen { position: fixed; inset: 0; z-index: 9999; border-radius: 0; overflow-y: auto; padding: 32px; }

.page-header { padding: 20px 20px 8px; }
.page-title { font-size: 22px; font-weight: 700; color: #111827; margin-bottom: 6px; }
.page-description { font-size: 13px; color: #6b7280; line-height: 1.6; }

.action-bar { display: flex; align-items: center; justify-content: space-between; padding: 12px 20px; gap: 12px; }
.action-bar-left { display: flex; align-items: center; gap: 10px; flex: 1; }
.action-bar-right { display: flex; align-items: center; gap: 10px; }

.search-input-wrapper { position: relative; flex: 1; max-width: 300px; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }
.table-search { width: 100%; padding: 9px 12px 9px 38px; border: 1px solid #e5e7eb; border-radius: 10px; font-size: 14px; outline: none; height: 40px; }
.table-search:focus { border-color: #d1d5db; }

.btn-filter, .btn-sort { display: flex; align-items: center; gap: 7px; padding: 0 14px; height: 40px; background: white; border: 1px solid #e5e7eb; border-radius: 10px; font-size: 13px; font-weight: 500; color: #374151; cursor: pointer; transition: all 0.15s; }
.btn-filter:hover, .btn-sort:hover { background: #f9fafb; }
.btn-filter.active, .btn-sort.active { background: #f3f4f6; border-color: #d1d5db; }

.sort-toggle-wrapper, .column-toggle-wrapper { position: relative; }
.sort-dropdown-menu, .column-dropdown-menu { position: absolute; top: calc(100% + 6px); left: 0; background: white; border: 1px solid #e5e7eb; border-radius: 10px; box-shadow: 0 8px 16px rgba(0,0,0,0.06); padding: 10px; min-width: 200px; z-index: 100; display: flex; flex-direction: column; gap: 4px; }
.column-dropdown-menu { left: auto; right: 0; min-width: 180px; }
.dropdown-header { font-size: 11px; font-weight: 700; color: #9ca3af; text-transform: uppercase; letter-spacing: 0.05em; padding-bottom: 6px; border-bottom: 1px solid #f3f4f6; margin-bottom: 4px; }
.sort-option { display: flex; align-items: center; justify-content: space-between; width: 100%; padding: 7px 10px; font-size: 13px; color: #374151; background: none; border: none; border-radius: 6px; cursor: pointer; text-align: left; }
.sort-option:hover { background: #f9fafb; }
.sort-option.active { background: #f3f4f6; font-weight: 500; }
.active-dot { width: 6px; height: 6px; background: #111827; border-radius: 50%; }
.column-option { display: flex; align-items: center; gap: 8px; font-size: 13px; color: #374151; cursor: pointer; padding: 4px 0; user-select: none; }
.column-option input { accent-color: #111827; }

.btn-icon-square { width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; background: white; border: 1px solid #e5e7eb; border-radius: 10px; color: #374151; cursor: pointer; transition: all 0.15s; }
.btn-icon-square:hover { background: #f9fafb; }
.btn-icon-square.active { background: #f3f4f6; }

.btn-create { display: flex; align-items: center; gap: 8px; padding: 0 18px; height: 40px; background: #111827; border-radius: 10px; font-size: 13px; font-weight: 600; color: white; transition: background 0.15s; }
.btn-create:hover { background: #1f2937; }

.filter-panel { display: flex; align-items: flex-end; gap: 16px; background: #f9fafb; border-top: 1px solid #e5e7eb; border-bottom: 1px solid #e5e7eb; padding: 12px 20px; }
.filter-group { display: flex; flex-direction: column; gap: 5px; flex: 1; }
.filter-label { font-size: 11px; font-weight: 700; color: #6b7280; text-transform: uppercase; letter-spacing: 0.05em; }
.filter-select { height: 38px; padding: 0 28px 0 10px; background: white url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e") no-repeat right 8px center/14px; appearance: none; border: 1px solid #e5e7eb; border-radius: 8px; font-size: 13px; color: #374151; outline: none; cursor: pointer; }
.filter-select:focus { border-color: #111827; }
.btn-reset-filters { height: 38px; padding: 0 14px; background: white; border: 1px solid #e5e7eb; border-radius: 8px; font-size: 13px; color: #374151; font-weight: 500; cursor: pointer; display: flex; align-items: center; gap: 6px; white-space: nowrap; }
.btn-reset-filters:hover { background: #f9fafb; }

.table-wrapper { overflow-x: auto; border-bottom: 1px solid #e5e7eb; }
.reservation-table { width: 100%; border-collapse: collapse; font-size: 14px; }
.reservation-table th { background: #fafafa; font-weight: 600; color: #4b5563; padding: 11px 16px; border-bottom: 1px solid #e5e7eb; }
.reservation-table td { padding: 13px 16px; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
.reservation-table tbody tr:hover { background: #fafafa; }
.row-selected { background: #f0f7ff !important; }
.table-checkbox { width: 15px; height: 15px; accent-color: #111827; cursor: pointer; }
.empty-row { text-align: center; color: #9ca3af; padding: 32px; font-size: 14px; }

.state-badge { display: inline-flex; align-items: center; gap: 5px; padding: 3px 10px; border-radius: 20px; font-size: 12px; font-weight: 600; }
.state-active { background: #ecfdf5; color: #065f46; }
.state-active .dot { width: 6px; height: 6px; border-radius: 50%; background: #10b981; }
.state-inactive { background: #f3f4f6; color: #6b7280; }
.state-inactive .dot { width: 6px; height: 6px; border-radius: 50%; background: #9ca3af; }

.action-menu-container { position: relative; display: inline-block; }
.btn-three-dots { background: none; border: none; color: #9ca3af; cursor: pointer; padding: 4px; border-radius: 6px; display: flex; align-items: center; transition: all 0.15s; }
.btn-three-dots:hover { background: #f3f4f6; color: #111827; }
.action-dropdown-menu { position: absolute; top: 100%; right: 0; background: white; border: 1px solid #e5e7eb; border-radius: 8px; box-shadow: 0 8px 16px rgba(0,0,0,0.07); padding: 6px; min-width: 130px; z-index: 110; display: flex; flex-direction: column; gap: 2px; }
.action-dropdown-item { display: flex; align-items: center; gap: 8px; width: 100%; padding: 7px 10px; font-size: 13px; font-weight: 500; color: #374151; background: none; border: none; border-radius: 6px; cursor: pointer; text-align: left; }
.action-dropdown-item:hover { background: #f9fafb; }
.item-danger { color: #dc2626; }
.item-danger:hover { background: #fef2f2; }
.dropdown-divider { height: 1px; background: #f3f4f6; margin: 3px 0; }

.table-footer { display: flex; align-items: center; justify-content: space-between; padding: 13px 20px; font-size: 13px; color: #6b7280; }
.pagination-controls { display: flex; align-items: center; gap: 6px; }
.page-nav-btn { display: flex; align-items: center; padding: 5px 12px; border: 1px solid #e5e7eb; background: white; border-radius: 8px; font-size: 13px; font-weight: 500; color: #374151; cursor: pointer; }
.page-nav-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.page-num { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; border: 1px solid #e5e7eb; background: white; border-radius: 8px; font-size: 13px; font-weight: 500; cursor: pointer; }
.page-num.active { background: #111827; color: white; border-color: #111827; }

.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.4); display: flex; align-items: center; justify-content: center; z-index: 9999; }
.modal-card { background: white; border-radius: 16px; padding: 28px; width: 480px; max-width: 95vw; position: relative; box-shadow: 0 20px 40px rgba(0,0,0,0.12); }
.modal-close-btn { position: absolute; top: 16px; right: 16px; background: none; border: none; color: #9ca3af; cursor: pointer; padding: 4px; border-radius: 6px; display: flex; }
.modal-close-btn:hover { background: #f3f4f6; color: #111827; }
.modal-card-header h3 { font-size: 16px; font-weight: 700; color: #111827; margin-bottom: 20px; }
.view-details-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.detail-item { display: flex; flex-direction: column; gap: 3px; }
.detail-label { font-size: 11px; font-weight: 600; color: #9ca3af; text-transform: uppercase; letter-spacing: 0.05em; }
.detail-value { font-size: 14px; color: #111827; }
.modal-footer-row { display: flex; justify-content: flex-end; margin-top: 24px; }
.btn-modal-close { padding: 8px 20px; background: #111827; color: white; border: none; border-radius: 8px; font-size: 14px; font-weight: 600; cursor: pointer; }
.btn-modal-close:hover { background: #1f2937; }
</style>
