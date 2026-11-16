<script setup lang="ts">
import { ref, computed } from 'vue';
import { 
  ArrowUpDown, MoreVertical, Eye
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import MetricCard from '../../components/MetricCard.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import FormSelect from '../../components/FormSelect.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';

// ─── Types & Models ───
export interface HeadcountGateRecord {
  id: number;
  uuid: string;
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  organization_unit_id: number;
  unit_name: string;
  unit_code: string;
  fiscal_year: string;
  period_start: string;
  period_end: string;
  approved_headcount: number;
  filled_headcount: number;
  open_requisitions: number;
  annual_budget_amount: number;
  currency_id: string;
  budget_state: 'active' | 'approved' | 'closed';
  state: 'active' | 'inactive';
}

// ─── Breadcrumbs (Image 2: "[Monitor] > Headcount Budgets") ───
const breadcrumbItems = [
  { label: 'Headcount Budgets' }
];

// ─── State Management ───
const searchQuery = ref('');
const filterYear = ref('All');
const filterEntity = ref('All');
const filterGateStatus = ref('All');
const selectedRows = ref<number[]>([]);
const currentSort = ref('unit_name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const activeDropdownId = ref<number | null>(null);

// ─── Live Monitoring Data (Matching Image 2) ───
const monitorRecords = ref<HeadcountGateRecord[]>([
  {
    id: 1,
    uuid: 'hcb-001-bole-2027',
    tenant_id: 1,
    entity_id: 7,
    entity_name: 'QMT Bole',
    organization_unit_id: 3,
    unit_name: 'Commercial Sales',
    unit_code: 'COMM-SALES',
    fiscal_year: 'FY 2027',
    period_start: '08/07/2026',
    period_end: '07/07/2027',
    approved_headcount: 12,
    filled_headcount: 12,
    open_requisitions: 0,
    annual_budget_amount: 1404000,
    currency_id: 'ETB',
    budget_state: 'active',
    state: 'active'
  },
  {
    id: 2,
    uuid: 'hcb-002-mekanisa-2027',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'QMT Mekanisa',
    organization_unit_id: 2,
    unit_name: 'Senior Cashier',
    unit_code: 'SR-CASHIER',
    fiscal_year: 'FY 2027',
    period_start: '08/07/2026',
    period_end: '07/07/2027',
    approved_headcount: 6,
    filled_headcount: 4,
    open_requisitions: 2,
    annual_budget_amount: 720000,
    currency_id: 'ETB',
    budget_state: 'active',
    state: 'active'
  },
  {
    id: 3,
    uuid: 'hcb-003-koye-2027',
    tenant_id: 1,
    entity_id: 9,
    entity_name: 'QMT koye',
    organization_unit_id: 5,
    unit_name: 'Human Resource',
    unit_code: 'HR-DEPT',
    fiscal_year: 'FY 2027',
    period_start: '08/07/2026',
    period_end: '07/07/2027',
    approved_headcount: 10,
    filled_headcount: 2,
    open_requisitions: 0,
    annual_budget_amount: 960000,
    currency_id: 'ETB',
    budget_state: 'active',
    state: 'active'
  }
]);

// ─── Table Columns (Matching Image 2) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'unit_name', label: 'Organization Units', visible: true, sortable: true },
  { key: 'entity_name', label: 'Owning Entity', visible: true, sortable: true },
  { key: 'fiscal_year', label: 'Fiscal Period', visible: true, sortable: true },
  { key: 'open_requisitions', label: 'Open Requisitions', visible: true, sortable: true },
  { key: 'filled_headcount', label: 'Filled Headcount', visible: true, sortable: true },
  { key: 'gate_status', label: 'Hiring Gate Status', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

// ─── Filter Options ───
const uniqueFiscalYears = computed(() => {
  const yrs = Array.from(new Set(monitorRecords.value.map(p => p.fiscal_year))).filter(Boolean);
  return ['All', ...yrs];
});

const uniqueEntities = computed(() => {
  const ents = Array.from(new Set(monitorRecords.value.map(p => p.entity_name))).filter(Boolean);
  return ['All', ...ents];
});

const gateOptions = ['All', 'Open', 'Locked'];

const activeFilterCount = computed(() => {
  let count = 0;
  if (filterYear.value !== 'All') count++;
  if (filterEntity.value !== 'All') count++;
  if (filterGateStatus.value !== 'All') count++;
  return count;
});

// ─── Filtered Records with Sorting ───
const filteredRecords = computed(() => {
  return monitorRecords.value.filter(item => {
    const q = searchQuery.value.toLowerCase().trim();
    if (q) {
      const matchUnit = item.unit_name.toLowerCase().includes(q);
      const matchCode = item.unit_code.toLowerCase().includes(q);
      const matchEntity = item.entity_name.toLowerCase().includes(q);
      if (!matchUnit && !matchCode && !matchEntity) return false;
    }
    if (filterYear.value !== 'All' && item.fiscal_year !== filterYear.value) return false;
    if (filterEntity.value !== 'All' && item.entity_name !== filterEntity.value) return false;
    if (filterGateStatus.value !== 'All') {
      const isLocked = item.filled_headcount >= item.approved_headcount;
      if (filterGateStatus.value === 'Locked' && !isLocked) return false;
      if (filterGateStatus.value === 'Open' && isLocked) return false;
    }
    return true;
  }).sort((a, b) => {
    let valA = a[currentSort.value as keyof HeadcountGateRecord];
    let valB = b[currentSort.value as keyof HeadcountGateRecord];
    if (valA === undefined || valA === null) valA = '';
    if (valB === undefined || valB === null) valB = '';
    if (valA < valB) return sortOrder.value === 'asc' ? -1 : 1;
    if (valA > valB) return sortOrder.value === 'asc' ? 1 : -1;
    return 0;
  });
});

// ─── Selection Logic ───
const isAllSelected = computed(() => {
  return filteredRecords.value.length > 0 && filteredRecords.value.every(r => selectedRows.value.includes(r.id));
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRows.value = [];
  } else {
    selectedRows.value = filteredRecords.value.map(r => r.id);
  }
};

const toggleRowSelection = (id: number) => {
  const index = selectedRows.value.indexOf(id);
  if (index > -1) {
    selectedRows.value.splice(index, 1);
  } else {
    selectedRows.value.push(id);
  }
};

const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

const handleToggleColumn = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  if (col) col.visible = !col.visible;
};

const getAvailableSeats = (row: HeadcountGateRecord) => {
  return Math.max(0, row.approved_headcount - row.filled_headcount);
};

const getFillPercentage = (row: HeadcountGateRecord) => {
  if (row.approved_headcount === 0) return 0;
  return Math.min(100, Math.round((row.filled_headcount / row.approved_headcount) * 100));
};

const toggleDropdown = (id: number) => {
  activeDropdownId.value = activeDropdownId.value === id ? null : id;
};

const closeDropdowns = () => {
  activeDropdownId.value = null;
};

const currentPage = ref(1);
const perPage = ref(10);

const paginatedRecords = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredRecords.value.slice(start, start + perPage.value);
});
</script>

<template>
  <div class="headcount-monitoring-page" @click="closeDropdowns">
    <!-- Breadcrumb: Image 2 "[Monitor] > Headcount Budgets" -->
    <AppBreadcrumb :items="breadcrumbItems" />

    <!-- Top KPI / Metric Cards (Matching Image 2) -->
    <div class="monitoring-kpis-grid">
      <MetricCard 
        label="APPROVED SEAT CEILING" 
        value="45 Seats" 
        subtext="Approved Active Capacity" 
      />
      <MetricCard 
        label="ACTIVE FILLED HEADCOUNT" 
        value="30 Occupied" 
        subtext="80% Seat Occupancy Rate" 
      />
      <MetricCard 
        label="IN FLIGHT REQUISITION" 
        value="6 Active" 
        subtext="Open Hiring Vacancies" 
      />
      <MetricCard 
        label="AVAILABLE REMAINING CAPACITY" 
        value="4 Seats Left" 
        subtext="Hiring Gate Open For Requisitions" 
      />
    </div>

    <!-- Unified Table Card (Matching Image 2) -->
    <AppDataTable
      title="Headcount Monitoring"
      subtitle="Real-time seat occupancy, recruitment pipeline consumption, and operational capacity enforcement."
      v-model:searchQuery="searchQuery"
      searchPlaceholder="Search Name..."
      :showSearch="true"
      :showFilter="true"
      :filterCount="activeFilterCount"
      :showSort="true"
      v-model:currentSort="currentSort"
      v-model:sortOrder="sortOrder"
      :showColumns="true"
      :columns="tableColumns"
      :totalEntries="filteredRecords.length"
      v-model:currentPage="currentPage"
      v-model:perPage="perPage"
      :showPagination="true"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Filter Panel -->
      <template #filter>
        <div class="monitoring-filters-row">
          <div class="filter-item">
            <FormSelect
              v-model="filterYear"
              label="Fiscal Year:"
              :options="uniqueFiscalYears.map(fy => ({ value: fy, label: String(fy) }))"
              placeholder="Select Year"
            />
          </div>

          <div class="filter-item">
            <FormSelect
              v-model="filterEntity"
              label="Owning Entity:"
              :options="uniqueEntities.map(ent => ({ value: ent, label: ent }))"
              placeholder="Select Entity"
            />
          </div>

          <div class="filter-item">
            <FormSelect
              v-model="filterGateStatus"
              label="Gate State:"
              :options="gateOptions.map(gt => ({ value: gt, label: gt }))"
              placeholder="Select State"
            />
          </div>
        </div>
      </template>

      <!-- Table Listing (Matching Image 2) -->
      <table class="erp-table">
        <thead>
          <tr>
            <th class="col-checkbox">
              <input 
                type="checkbox" 
                class="custom-checkbox" 
                :checked="isAllSelected" 
                @change="toggleSelectAll"
                aria-label="Select All" 
              />
            </th>

            <th v-if="isColumnVisible('unit_name')" class="col-unit sortable" @click="currentSort = 'unit_name'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
              <div class="th-content">
                <span>Organization Units</span>
                <ArrowUpDown v-if="currentSort === 'unit_name'" :size="12" class="sort-icon active-sort" />
              </div>
            </th>

            <th v-if="isColumnVisible('entity_name')" class="col-entity">Owning Entity</th>
            <th v-if="isColumnVisible('fiscal_year')" class="col-fy">Fiscal Period</th>
            <th v-if="isColumnVisible('open_requisitions')" class="col-reqs">Open Requisitions</th>
            <th v-if="isColumnVisible('filled_headcount')" class="col-filled">Filled Headcount</th>
            <th v-if="isColumnVisible('gate_status')" class="col-gate">Hiring Gate Status</th>
            <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr 
            v-for="row in paginatedRecords" 
            :key="row.id"
            class="erp-row cursor-pointer"
            :class="{ 'row-selected': selectedRows.includes(row.id) }"
          >
            <td class="col-checkbox" @click.stop>
              <input 
                type="checkbox" 
                class="custom-checkbox" 
                :checked="selectedRows.includes(row.id)" 
                @change="toggleRowSelection(row.id)" 
                aria-label="Select Row" 
              />
            </td>

            <!-- Organization Units: Primary Secondary Color (#404040) -->
            <td v-if="isColumnVisible('unit_name')" class="col-unit">
              <span class="table-name-primary">{{ row.unit_name }}</span>
            </td>

            <!-- Owning Entity: Tertiary Color (#737373) -->
            <td v-if="isColumnVisible('entity_name')" class="col-entity">
              <span class="text-tertiary">{{ row.entity_name }}</span>
            </td>

            <!-- Fiscal Period -->
            <td v-if="isColumnVisible('fiscal_year')" class="col-fy">
              <span class="text-tertiary font-mono">{{ row.fiscal_year }}</span>
            </td>

            <!-- Open Requisitions -->
            <td v-if="isColumnVisible('open_requisitions')" class="col-reqs">
              <span class="text-tertiary">{{ row.open_requisitions }} Open</span>
            </td>

            <!-- Filled Headcount with Ratio, Percentage & Progress Bar (Matching Image 2) -->
            <td v-if="isColumnVisible('filled_headcount')" class="col-filled">
              <div class="progress-cell-wrap">
                <div class="progress-numbers-row">
                  <span class="numbers-ratio font-mono">{{ row.filled_headcount }} / {{ row.approved_headcount }}</span>
                  <span class="numbers-pct font-mono">{{ getFillPercentage(row) }}%</span>
                </div>
                <div class="progress-bar-track">
                  <div 
                    class="progress-bar-fill" 
                    :class="getFillPercentage(row) >= 100 ? 'fill-locked' : 'fill-active'"
                    :style="{ width: `${getFillPercentage(row)}%` }"
                  ></div>
                </div>
              </div>
            </td>

            <!-- Hiring Gate Status (BaseBadge) -->
            <td v-if="isColumnVisible('gate_status')" class="col-gate">
              <BaseBadge 
                v-if="row.filled_headcount >= row.approved_headcount" 
                color="error"
              >
                Locked (0 Avail)
              </BaseBadge>
              <BaseBadge 
                v-else 
                color="success"
              >
                Open ({{ getAvailableSeats(row) }} Avail)
              </BaseBadge>
            </td>

            <!-- Actions: 3-Dots Button -->
            <td v-if="isColumnVisible('actions')" class="col-actions" @click.stop>
              <div class="actions-dropdown-wrap">
                <button 
                  type="button" 
                  class="btn-action-dots"
                  @click="toggleDropdown(row.id)"
                  title="Actions"
                >
                  <MoreVertical :size="15" />
                </button>

                <div v-if="activeDropdownId === row.id" class="actions-menu-popup" @click.stop>
                  <button 
                    type="button" 
                    class="action-menu-item"
                    @click="activeDropdownId = null"
                  >
                    <Eye :size="13" />
                    <span>View Requisitions</span>
                  </button>
                </div>
              </div>
            </td>
          </tr>

          <!-- Empty State -->
          <tr v-if="filteredRecords.length === 0">
            <td colspan="8" class="table-empty-row">
              <div class="empty-state-box">
                <p class="empty-title">No Headcount Records Found</p>
                <p class="empty-subtitle">Adjust your filter options or select another fiscal period.</p>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </AppDataTable>
  </div>
</template>

<style scoped>
.headcount-monitoring-page {
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
}

/* Metric Cards Grid */
.monitoring-kpis-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
  margin-bottom: 4px;
}

@media (max-width: 1024px) {
  .monitoring-kpis-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 640px) {
  .monitoring-kpis-grid {
    grid-template-columns: 1fr;
  }
}

/* Filter Row */
.monitoring-filters-row {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 12px 16px;
  background-color: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
  flex-wrap: wrap;
}

.filter-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

.filter-label {
  font-size: 12px;
  font-weight: 500;
  color: #737373;
}

.filter-select {
  height: 32px;
  padding: 0 10px;
  font-size: 12.5px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  outline: none;
}

/* ERP Table Styling */
.erp-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
  user-select: none;
}

.erp-table th.sortable {
  cursor: pointer;
}

.th-content {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.sort-icon {
  color: #94a3b8;
}

.sort-icon.active-sort {
  color: #0B529C;
}

.erp-table td {
  height: 48px;
  padding: 8px 16px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.erp-row:hover {
  background-color: #f8fafc;
}

.row-selected {
  background-color: #f0f7ff !important;
}

/* Col Widths */
.col-checkbox {
  width: 44px;
  text-align: center;
  padding: 8px 12px !important;
}

.col-unit {
  min-width: 170px;
}

.col-entity {
  min-width: 130px;
}

.col-fy {
  min-width: 110px;
}

.col-reqs {
  min-width: 130px;
}

.col-filled {
  min-width: 180px;
}

.col-gate {
  min-width: 130px;
}

.col-actions {
  width: 60px;
  text-align: center;
}

/* Cell Elements */
.custom-checkbox {
  width: 16px;
  height: 16px;
  accent-color: #0B529C;
  cursor: pointer;
  vertical-align: middle;
}

.table-name-primary {
  font-weight: 500;
  color: #404040;
  font-size: 13.5px;
}

.text-tertiary {
  color: #737373;
}

/* Progress Cell (Image 2) */
.progress-cell-wrap {
  display: flex;
  flex-direction: column;
  gap: 5px;
  width: 100%;
  max-width: 160px;
}

.progress-numbers-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 12px;
}

.numbers-ratio {
  color: #404040;
  font-weight: 500;
}

.numbers-pct {
  color: #737373;
  font-size: 11.5px;
}

.progress-bar-track {
  width: 100%;
  height: 5px;
  background-color: #e2e8f0;
  border-radius: 9999px;
  overflow: hidden;
}

.progress-bar-fill {
  height: 100%;
  border-radius: 9999px;
  transition: width 0.3s ease;
}

.progress-bar-fill.fill-active {
  background-color: #0B529C;
}

.progress-bar-fill.fill-locked {
  background-color: #94a3b8;
}

/* Action Dots & Menu */
.actions-dropdown-wrap {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #94a3b8;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.actions-menu-popup {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  min-width: 140px;
  z-index: 50;
  padding: 4px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.action-menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 6px 10px;
  font-size: 12.5px;
  color: #404040;
  background: transparent;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
}

.action-menu-item:hover {
  background-color: #f8fafc;
}

/* Pagination Bar (Image 2) */
.table-pagination-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-top: 1px solid #f1f5f9;
  font-size: 12.5px;
  color: #737373;
  flex-wrap: wrap;
  gap: 12px;
}

.pagination-info {
  color: #737373;
}

.pagination-per-page {
  display: flex;
  align-items: center;
  gap: 8px;
}

.per-page-select {
  height: 28px;
  padding: 0 6px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12px;
  color: #404040;
  outline: none;
  background-color: #ffffff;
}

.pagination-controls {
  display: flex;
  align-items: center;
  gap: 4px;
}

.btn-page-nav {
  height: 28px;
  padding: 0 10px;
  font-size: 12px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  cursor: pointer;
}

.btn-page-nav:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-page-number {
  min-width: 28px;
  height: 28px;
  padding: 0 6px;
  font-size: 12px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  cursor: pointer;
}

.btn-page-number.page-active {
  background-color: #0B529C;
  color: #ffffff;
  border-color: #0B529C;
  font-weight: 500;
}

.page-ellipsis {
  padding: 0 4px;
  color: #94a3b8;
}

/* Empty State */
.table-empty-row {
  padding: 48px 16px;
  text-align: center;
}

.empty-state-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.empty-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.empty-subtitle {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}
</style>
