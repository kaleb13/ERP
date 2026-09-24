<script setup lang="ts">
import { ref, computed } from 'vue';
import { 
  Search, ShieldAlert, ShieldCheck, X, Eye, 
  Users, Briefcase, FileText, CheckCircle2, Lock, Unlock,
  Layers, ArrowUpRight, ArrowUpDown
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import MetricCard from '../../components/MetricCard.vue';
import AppDataTable from '../../components/AppDataTable.vue';
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
  active_requisitions_list?: { req_code: string; title: string; stage: string; candidate_count: number }[];
  occupying_staff_list?: { emp_code: string; full_name: string; role: string; hire_date: string }[];
}

// ─── Breadcrumbs (Rule: Exact Page Name from Sidebar Only: "Headcount Monitoring") ───
const breadcrumbItems = [
  { label: 'Headcount Monitoring' }
];

// ─── State Management ───
const searchQuery = ref('');
const filterYear = ref('All');
const filterEntity = ref('All');
const filterGateStatus = ref('All');
const selectedRows = ref<number[]>([]);
const currentSort = ref('unit_name');
const sortOrder = ref<'asc' | 'desc'>('asc');

// Drawer / Inspection Modal State
const isInspectModalOpen = ref(false);
const inspectedGateRecord = ref<HeadcountGateRecord | null>(null);
const inspectActiveTab = ref<'gate' | 'requisitions' | 'staff'>('gate');

// ─── Live Monitoring Data (Exact Schema Aligned) ───
const monitorRecords = ref<HeadcountGateRecord[]>([
  {
    id: 1,
    uuid: 'hcb-001-corp-2027',
    tenant_id: 1,
    entity_id: 7,
    entity_name: 'Haleta Addis Ababa Hospitality',
    organization_unit_id: 3,
    unit_name: 'Commercial & Sales Operations',
    unit_code: 'COMM-OPS',
    fiscal_year: '2027',
    period_start: '08/07/2026',
    period_end: '07/07/2027',
    approved_headcount: 12,
    filled_headcount: 10,
    open_requisitions: 2,
    annual_budget_amount: 936000,
    currency_id: 'ETB',
    budget_state: 'active',
    state: 'active',
    active_requisitions_list: [
      { req_code: 'REQ-2027-018', title: 'Corporate Sales Lead', stage: 'Technical Assessment', candidate_count: 4 },
      { req_code: 'REQ-2027-031', title: 'Event Banquets Officer', stage: 'Final Panel Interview', candidate_count: 2 }
    ],
    occupying_staff_list: [
      { emp_code: 'EMP-001', full_name: 'Abebe Kebede', role: 'Commercial Director', hire_date: '12/01/2024' },
      { emp_code: 'EMP-014', full_name: 'Sara Tesfaye', role: 'VIP Sales Specialist', hire_date: '01/03/2025' },
      { emp_code: 'EMP-022', full_name: 'Biniyam Haile', role: 'Hospitality Coordinator', hire_date: '15/06/2025' }
    ]
  },
  {
    id: 2,
    uuid: 'hcb-002-eng-2027',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Technologies Group',
    organization_unit_id: 2,
    unit_name: 'Engineering & Technology',
    unit_code: 'ENG-TECH',
    fiscal_year: '2027',
    period_start: '08/07/2026',
    period_end: '07/07/2027',
    approved_headcount: 8,
    filled_headcount: 7,
    open_requisitions: 1,
    annual_budget_amount: 1152000,
    currency_id: 'ETB',
    budget_state: 'active',
    state: 'active',
    active_requisitions_list: [
      { req_code: 'REQ-2027-094', title: 'Senior Backend Engineer', stage: 'Executive Offer Pending', candidate_count: 1 }
    ],
    occupying_staff_list: [
      { emp_code: 'EMP-003', full_name: 'Dawit Bekele', role: 'Staff Systems Architect', hire_date: '10/02/2023' },
      { emp_code: 'EMP-009', full_name: 'Selam Mengistu', role: 'Frontend Engineer', hire_date: '14/11/2024' }
    ]
  },
  {
    id: 3,
    uuid: 'hcb-003-fin-2027',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Technologies Group',
    organization_unit_id: 1,
    unit_name: 'Finance & Compliance',
    unit_code: 'FIN-CORP',
    fiscal_year: '2027',
    period_start: '08/07/2026',
    period_end: '07/07/2027',
    approved_headcount: 4,
    filled_headcount: 3,
    open_requisitions: 0,
    annual_budget_amount: 720000,
    currency_id: 'ETB',
    budget_state: 'active',
    state: 'active',
    active_requisitions_list: [],
    occupying_staff_list: [
      { emp_code: 'EMP-007', full_name: 'Tigist Alemayehu', role: 'Senior Tax Accountant', hire_date: '05/05/2022' },
      { emp_code: 'EMP-019', full_name: 'Kassahun Wolde', role: 'Payroll Specialist', hire_date: '18/09/2024' }
    ]
  },
  {
    id: 4,
    uuid: 'hcb-004-hosp-2027',
    tenant_id: 1,
    entity_id: 9,
    entity_name: 'Haleta Logistics & Cargo',
    organization_unit_id: 3,
    unit_name: 'Fleet Logistics & Freight',
    unit_code: 'FLEET-LOG',
    fiscal_year: '2027',
    period_start: '08/07/2026',
    period_end: '07/07/2027',
    approved_headcount: 6,
    filled_headcount: 4,
    open_requisitions: 0,
    annual_budget_amount: 468000,
    currency_id: 'ETB',
    budget_state: 'active',
    state: 'active',
    active_requisitions_list: [],
    occupying_staff_list: [
      { emp_code: 'EMP-041', full_name: 'Yared Berhanu', role: 'Freight Route Supervisor', hire_date: '11/04/2024' }
    ]
  },
  {
    id: 5,
    uuid: 'hcb-005-hr-2027',
    tenant_id: 1,
    entity_id: 7,
    entity_name: 'Haleta Addis Ababa Hospitality',
    organization_unit_id: 5,
    unit_name: 'People & Culture',
    unit_code: 'HR-PEOPLE',
    fiscal_year: '2027',
    period_start: '08/07/2026',
    period_end: '07/07/2027',
    approved_headcount: 5,
    filled_headcount: 4,
    open_requisitions: 0,
    annual_budget_amount: 900000,
    currency_id: 'ETB',
    budget_state: 'active',
    state: 'active',
    active_requisitions_list: [],
    occupying_staff_list: [
      { emp_code: 'EMP-002', full_name: 'Sofia Hailu', role: 'HR Director', hire_date: '01/01/2021' }
    ]
  },
  {
    id: 6,
    uuid: 'hcb-006-cs-2026',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Technologies Group',
    organization_unit_id: 4,
    unit_name: 'Customer Success & Support',
    unit_code: 'CS-SUPP',
    fiscal_year: '2026',
    period_start: '08/07/2025',
    period_end: '07/07/2026',
    approved_headcount: 10,
    filled_headcount: 2,
    open_requisitions: 0,
    annual_budget_amount: 840000,
    currency_id: 'ETB',
    budget_state: 'closed',
    state: 'inactive',
    active_requisitions_list: [],
    occupying_staff_list: []
  }
]);

// ─── Table Columns (Rule 9: Atomic columns, Name-first order, plain text default) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'unit_name', label: 'Organization Unit', visible: true, sortable: true },
  { key: 'fiscal_year', label: 'Fiscal Year', visible: true, sortable: true },
  { key: 'gate_status', label: 'Hiring Gate Status', visible: true, sortable: true },
  { key: 'approved_headcount', label: 'Approved Ceiling', visible: true, sortable: true },
  { key: 'filled_headcount', label: 'Filled Headcount', visible: true, sortable: true },
  { key: 'open_requisitions', label: 'Open Requisitions', visible: true, sortable: true },
  { key: 'available_seats', label: 'Available Capacity', visible: true, sortable: true },
  { key: 'utilization', label: 'Capacity Utilization', visible: true, sortable: false },
  { key: 'annual_budget_amount', label: 'Annual Salary Budget', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

// ─── Metric Calculations (Rule 2: MetricCard Standard) ───
const totalApprovedCeiling = computed(() => {
  return monitorRecords.value
    .filter(r => r.state === 'active')
    .reduce((sum, r) => sum + r.approved_headcount, 0);
});

const totalFilledHeadcount = computed(() => {
  return monitorRecords.value
    .filter(r => r.state === 'active')
    .reduce((sum, r) => sum + r.filled_headcount, 0);
});

const totalOpenRequisitions = computed(() => {
  return monitorRecords.value
    .filter(r => r.state === 'active')
    .reduce((sum, r) => sum + r.open_requisitions, 0);
});

const totalAvailableCapacity = computed(() => {
  return Math.max(0, totalApprovedCeiling.value - (totalFilledHeadcount.value + totalOpenRequisitions.value));
});

const overallOccupancyRate = computed(() => {
  if (totalApprovedCeiling.value === 0) return '0%';
  const pct = Math.round((totalFilledHeadcount.value / totalApprovedCeiling.value) * 100);
  return `${pct}%`;
});

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
    // Search query matches Unit, Code, or Entity
    const q = searchQuery.value.toLowerCase().trim();
    if (q) {
      const matchUnit = item.unit_name.toLowerCase().includes(q);
      const matchCode = item.unit_code.toLowerCase().includes(q);
      const matchEntity = item.entity_name.toLowerCase().includes(q);
      if (!matchUnit && !matchCode && !matchEntity) return false;
    }
    // Fiscal Year filter
    if (filterYear.value !== 'All' && item.fiscal_year !== filterYear.value) return false;
    // Entity filter
    if (filterEntity.value !== 'All' && item.entity_name !== filterEntity.value) return false;
    // Gate Status filter
    if (filterGateStatus.value !== 'All') {
      const isOpen = (item.filled_headcount + item.open_requisitions) < item.approved_headcount;
      if (filterGateStatus.value === 'Open' && !isOpen) return false;
      if (filterGateStatus.value === 'Locked' && isOpen) return false;
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

// ─── Helper Functions ───
const getAvailableSeats = (row: HeadcountGateRecord) => {
  return Math.max(0, row.approved_headcount - (row.filled_headcount + row.open_requisitions));
};

const isGateOpen = (row: HeadcountGateRecord) => {
  return (row.filled_headcount + row.open_requisitions) < row.approved_headcount;
};

const getUtilizationPercent = (row: HeadcountGateRecord) => {
  if (row.approved_headcount === 0) return 0;
  return Math.min(100, Math.round(((row.filled_headcount + row.open_requisitions) / row.approved_headcount) * 100));
};

const openInspectionDrawer = (row: HeadcountGateRecord) => {
  inspectedGateRecord.value = row;
  inspectActiveTab.value = 'gate';
  isInspectModalOpen.value = true;
};
</script>

<template>
  <div class="headcount-monitoring-page">
    <!-- Breadcrumb: EXACT Sidebar Page Name Only (Rule 3) -->
    <AppBreadcrumb :items="breadcrumbItems" />

    <!-- Top KPI / Metric Cards Ribbon (Rule 2 Standard) -->
    <div class="monitoring-kpis-grid">
      <MetricCard 
        label="Approved Seat Ceiling" 
        :value="`${totalApprovedCeiling} Seats`" 
        subtext="Sanctioned active capacity across units" 
      />
      <MetricCard 
        label="Active Filled Headcount" 
        :value="`${totalFilledHeadcount} Occupied`" 
        :subtext="`${overallOccupancyRate} current seat occupancy rate`" 
      />
      <MetricCard 
        label="In-Flight Requisitions" 
        :value="`${totalOpenRequisitions} Active`" 
        subtext="Open hiring vacancies consuming gate quota" 
      />
      <MetricCard 
        label="Available Remaining Capacity" 
        :value="`${totalAvailableCapacity} Seats Left`" 
        :subtext="totalAvailableCapacity > 0 ? 'Hiring gate open for requisitions' : 'Hiring gate locked across ceiling'" 
      />
    </div>

    <!-- Unified Table Card Standard (Rule 10: AppDataTable) -->
    <AppDataTable
      title="Headcount Monitoring & Hiring Gates"
      subtitle="Real-time seat occupancy, recruitment pipeline consumption, and operational capacity enforcement."
      v-model:searchQuery="searchQuery"
      searchPlaceholder="Search by organization unit, code, or entity..."
      :showSearch="true"
      :showFilter="true"
      :filterCount="activeFilterCount"
      :showSort="true"
      v-model:currentSort="currentSort"
      v-model:sortOrder="sortOrder"
      :showColumns="true"
      :columns="tableColumns"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Custom Filter Panel (revealed on filter button click) -->
      <template #filter>
        <div class="monitoring-filters-row">
          <div class="filter-item">
            <span class="filter-label">Fiscal Year:</span>
            <select v-model="filterYear" class="filter-select">
              <option v-for="fy in uniqueFiscalYears" :key="fy" :value="fy">{{ fy }}</option>
            </select>
          </div>

          <div class="filter-item">
            <span class="filter-label">Owning Entity:</span>
            <select v-model="filterEntity" class="filter-select">
              <option v-for="ent in uniqueEntities" :key="ent" :value="ent">{{ ent }}</option>
            </select>
          </div>

          <div class="filter-item">
            <span class="filter-label">Gate State:</span>
            <select v-model="filterGateStatus" class="filter-select">
              <option v-for="gt in gateOptions" :key="gt" :value="gt">{{ gt }}</option>
            </select>
          </div>
        </div>
      </template>

      <!-- Canonical ERP Table Listing -->
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

            <!-- Unit Column: Secondary color (#404040) with subtext code in tertiary (#737373) -->
            <th v-if="isColumnVisible('unit_name')" class="col-unit sortable" @click="currentSort = 'unit_name'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
              <div class="th-content">
                <span>Organization Unit</span>
                <ArrowUpDown v-if="currentSort === 'unit_name'" :size="12" class="sort-icon active-sort" />
              </div>
            </th>

            <!-- Subsequent Columns strictly in Tertiary Color -->
            <th v-if="isColumnVisible('fiscal_year')" class="col-fy sortable" @click="currentSort = 'fiscal_year'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
              <div class="th-content">
                <span>Fiscal Year</span>
                <ArrowUpDown v-if="currentSort === 'fiscal_year'" :size="12" class="sort-icon active-sort" />
              </div>
            </th>

            <th v-if="isColumnVisible('gate_status')" class="col-gate">Hiring Gate Status</th>
            <th v-if="isColumnVisible('approved_headcount')" class="col-ceiling">Approved Ceiling</th>
            <th v-if="isColumnVisible('filled_headcount')" class="col-filled">Filled Headcount</th>
            <th v-if="isColumnVisible('open_requisitions')" class="col-reqs">Open Requisitions</th>
            <th v-if="isColumnVisible('available_seats')" class="col-avail">Available Capacity</th>
            <th v-if="isColumnVisible('utilization')" class="col-util">Capacity Utilization</th>
            <th v-if="isColumnVisible('annual_budget_amount')" class="col-budget">Annual Salary Budget</th>

            <th v-if="isColumnVisible('state')" class="col-state sortable" @click="currentSort = 'state'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
              <div class="th-content">
                <span>State</span>
                <ArrowUpDown v-if="currentSort === 'state'" :size="12" class="sort-icon active-sort" />
              </div>
            </th>

            <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr 
            v-for="row in filteredRecords" 
            :key="row.id"
            class="erp-row cursor-pointer"
            :class="{ 'row-selected': selectedRows.includes(row.id) }"
            @click="openInspectionDrawer(row)"
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

            <!-- Organization Unit (Name First + Subtext Code) -->
            <td v-if="isColumnVisible('unit_name')" class="col-unit">
              <div class="unit-cell-stack">
                <span class="table-name-primary">{{ row.unit_name }}</span>
                <span class="table-code-subtext font-mono">{{ row.unit_code }}</span>
              </div>
            </td>

            <!-- Fiscal Year (String) -->
            <td v-if="isColumnVisible('fiscal_year')" class="col-fy">
              <span class="text-tertiary font-mono">{{ row.fiscal_year }}</span>
            </td>

            <!-- Hiring Gate Status Badge -->
            <td v-if="isColumnVisible('gate_status')" class="col-gate">
              <span 
                class="gate-status-pill"
                :class="isGateOpen(row) ? 'gate-open' : 'gate-locked'"
              >
                <component :is="isGateOpen(row) ? Unlock : Lock" :size="12" />
                <span>{{ isGateOpen(row) ? `Open (${getAvailableSeats(row)} Avail)` : 'Locked (0 Avail)' }}</span>
              </span>
            </td>

            <!-- Approved Ceiling -->
            <td v-if="isColumnVisible('approved_headcount')" class="col-ceiling">
              <span class="text-tertiary font-medium text-slate-700">{{ row.approved_headcount }} Seats</span>
            </td>

            <!-- Filled Headcount -->
            <td v-if="isColumnVisible('filled_headcount')" class="col-filled">
              <span class="text-tertiary">{{ row.filled_headcount }} Filled</span>
            </td>

            <!-- Open Requisitions -->
            <td v-if="isColumnVisible('open_requisitions')" class="col-reqs">
              <span class="text-tertiary font-medium" :class="row.open_requisitions > 0 ? 'text-amber-700' : ''">
                {{ row.open_requisitions }} Open
              </span>
            </td>

            <!-- Available Capacity -->
            <td v-if="isColumnVisible('available_seats')" class="col-avail">
              <span 
                class="font-mono font-medium"
                :class="getAvailableSeats(row) > 0 ? 'text-emerald-700' : 'text-rose-600'"
              >
                {{ getAvailableSeats(row) }} Seats
              </span>
            </td>

            <!-- Capacity Utilization Progress Bar -->
            <td v-if="isColumnVisible('utilization')" class="col-util">
              <div class="utilization-cell">
                <div class="utilization-track">
                  <div 
                    class="utilization-fill" 
                    :style="{ width: `${getUtilizationPercent(row)}%` }"
                    :class="getUtilizationPercent(row) >= 100 ? 'fill-full' : 'fill-normal'"
                  ></div>
                </div>
                <span class="utilization-pct font-mono">{{ getUtilizationPercent(row) }}%</span>
              </div>
            </td>

            <!-- Annual Salary Budget -->
            <td v-if="isColumnVisible('annual_budget_amount')" class="col-budget">
              <span class="text-tertiary font-mono">{{ Number(row.annual_budget_amount).toLocaleString() }} {{ row.currency_id }}</span>
            </td>

            <!-- State Pill -->
            <td v-if="isColumnVisible('state')" class="col-state">
              <span 
                class="status-pill" 
                :class="row.state === 'active' ? 'state-active' : 'state-inactive'"
              >
                {{ row.state === 'active' ? 'Active' : 'Inactive' }}
              </span>
            </td>

            <!-- Actions -->
            <td v-if="isColumnVisible('actions')" class="col-actions" @click.stop>
              <button 
                type="button" 
                class="btn-inspect-gate"
                @click="openInspectionDrawer(row)"
                title="Inspect Gate & Allocations"
              >
                <Eye :size="13" />
                <span>Inspect</span>
              </button>
            </td>
          </tr>

          <!-- Empty State -->
          <tr v-if="filteredRecords.length === 0">
            <td colspan="12" class="table-empty-row">
              <div class="empty-state-box">
                <p class="empty-title">No Headcount Gate Records Found</p>
                <p class="empty-subtitle">Adjust your filter options or search criteria.</p>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </AppDataTable>

    <!-- Inspection Modal / Detail Drawer -->
    <div v-if="isInspectModalOpen && inspectedGateRecord" class="modal-backdrop" @click="isInspectModalOpen = false">
      <div class="drawer-modal-card" @click.stop>
        <div class="drawer-header">
          <div class="drawer-title-stack">
            <span class="drawer-pretitle">Hiring Approval Gate Inspection</span>
            <h3 class="drawer-title">{{ inspectedGateRecord.unit_name }} ({{ inspectedGateRecord.unit_code }})</h3>
          </div>
          <button type="button" class="btn-modal-close" @click="isInspectModalOpen = false">
            <X :size="16" />
          </button>
        </div>

        <div class="drawer-body">
          <!-- Gate Enforcement Formula Card -->
          <div 
            class="gate-formula-card"
            :class="isGateOpen(inspectedGateRecord) ? 'card-gate-open' : 'card-gate-locked'"
          >
            <div class="gate-card-top">
              <div class="gate-icon-badge">
                <component :is="isGateOpen(inspectedGateRecord) ? Unlock : Lock" :size="18" />
              </div>
              <div class="gate-card-meta">
                <span class="gate-state-title">
                  {{ isGateOpen(inspectedGateRecord) ? 'Hiring Gate is OPEN' : 'Hiring Gate is LOCKED' }}
                </span>
                <span class="gate-state-desc">
                  {{ isGateOpen(inspectedGateRecord) 
                    ? `Unit has ${getAvailableSeats(inspectedGateRecord)} unallocated seat(s) available. New Job Requisitions will pass approval.` 
                    : 'All approved seats are fully occupied or committed to in-flight job requisitions. New requisitions will be blocked.' }}
                </span>
              </div>
            </div>

            <!-- Mathematical Formula Breakdown (Rule from Schema Note) -->
            <div class="formula-breakdown-row font-mono">
              <div class="f-block">
                <span class="f-label">Filled Headcount</span>
                <span class="f-val">{{ inspectedGateRecord.filled_headcount }}</span>
              </div>
              <span class="f-operator">+</span>
              <div class="f-block">
                <span class="f-label">Open Requisitions</span>
                <span class="f-val text-amber-700">{{ inspectedGateRecord.open_requisitions }}</span>
              </div>
              <span class="f-operator">=</span>
              <div class="f-block">
                <span class="f-label">Committed Seats</span>
                <span class="f-val font-semibold">{{ inspectedGateRecord.filled_headcount + inspectedGateRecord.open_requisitions }}</span>
              </div>
              <span class="f-operator">/</span>
              <div class="f-block">
                <span class="f-label">Approved Ceiling</span>
                <span class="f-val font-bold text-slate-800">{{ inspectedGateRecord.approved_headcount }}</span>
              </div>
            </div>
          </div>

          <!-- Drawer Navigation Tabs -->
          <div class="drawer-nav-tabs">
            <button 
              type="button" 
              class="d-tab" 
              :class="{ 'd-tab-active': inspectActiveTab === 'gate' }"
              @click="inspectActiveTab = 'gate'"
            >
              Overview & Ceiling
            </button>
            <button 
              type="button" 
              class="d-tab" 
              :class="{ 'd-tab-active': inspectActiveTab === 'requisitions' }"
              @click="inspectActiveTab = 'requisitions'"
            >
              Consuming Requisitions ({{ inspectedGateRecord.active_requisitions_list?.length || 0 }})
            </button>
            <button 
              type="button" 
              class="d-tab" 
              :class="{ 'd-tab-active': inspectActiveTab === 'staff' }"
              @click="inspectActiveTab = 'staff'"
            >
              Current Occupants ({{ inspectedGateRecord.occupying_staff_list?.length || 0 }})
            </button>
          </div>

          <!-- Tab 1: Overview & Ceiling Specs -->
          <div v-if="inspectActiveTab === 'gate'" class="drawer-tab-content">
            <div class="specs-grid">
              <div class="spec-card">
                <span class="spec-label">Fiscal Year</span>
                <span class="spec-val font-mono">{{ inspectedGateRecord.fiscal_year }}</span>
              </div>
              <div class="spec-card">
                <span class="spec-label">Annual Salary Budget</span>
                <span class="spec-val font-mono">{{ Number(inspectedGateRecord.annual_budget_amount).toLocaleString() }} {{ inspectedGateRecord.currency_id }}</span>
              </div>
              <div class="spec-card">
                <span class="spec-label">Period Coverage</span>
                <span class="spec-val font-mono text-xs">{{ inspectedGateRecord.period_start }} – {{ inspectedGateRecord.period_end }}</span>
              </div>
              <div class="spec-card">
                <span class="spec-label">Owning Branch</span>
                <span class="spec-val">{{ inspectedGateRecord.entity_name }}</span>
              </div>
            </div>
          </div>

          <!-- Tab 2: Consuming Active Requisitions -->
          <div v-if="inspectActiveTab === 'requisitions'" class="drawer-tab-content">
            <div v-if="(inspectedGateRecord.active_requisitions_list || []).length > 0" class="sub-records-list">
              <div 
                v-for="req in inspectedGateRecord.active_requisitions_list" 
                :key="req.req_code" 
                class="sub-record-card"
              >
                <div class="sub-record-main">
                  <span class="sub-req-code font-mono">{{ req.req_code }}</span>
                  <span class="sub-req-title">{{ req.title }}</span>
                </div>
                <div class="sub-record-meta">
                  <span class="stage-tag font-mono">{{ req.stage }}</span>
                  <span class="cand-tag">{{ req.candidate_count }} Applicants</span>
                </div>
              </div>
            </div>
            <div v-else class="drawer-empty-state">
              <CheckCircle2 :size="24" class="text-slate-300 mb-1" />
              <p>No active requisitions currently consuming capacity in this unit.</p>
            </div>
          </div>

          <!-- Tab 3: Current Staff Occupants -->
          <div v-if="inspectActiveTab === 'staff'" class="drawer-tab-content">
            <div v-if="(inspectedGateRecord.occupying_staff_list || []).length > 0" class="sub-records-list">
              <div 
                v-for="st in inspectedGateRecord.occupying_staff_list" 
                :key="st.emp_code" 
                class="sub-record-card"
              >
                <div class="sub-record-main">
                  <span class="sub-req-code font-mono">{{ st.emp_code }}</span>
                  <span class="sub-req-title">{{ st.full_name }}</span>
                  <span class="sub-req-role text-xs text-neutral-500">{{ st.role }}</span>
                </div>
                <div class="sub-record-meta">
                  <span class="text-xs text-slate-500">Hired {{ st.hire_date }}</span>
                </div>
              </div>
            </div>
            <div v-else class="drawer-empty-state">
              <Users :size="24" class="text-slate-300 mb-1" />
              <p>No staff records mapped to this unit.</p>
            </div>
          </div>
        </div>

        <div class="drawer-footer">
          <button type="button" class="btn-secondary-close" @click="isInspectModalOpen = false">Close</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.headcount-monitoring-page {
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* KPI Ribbon (Rule 2: MetricCard Grid) */
.monitoring-kpis-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
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

/* Filters Ribbon */
.monitoring-filters-row {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
  padding: 8px 16px;
  background-color: #f8fafc;
  border-radius: 8px;
  margin-bottom: 12px;
}

.filter-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

.filter-label {
  font-size: 12px;
  color: #737373;
  font-weight: 500;
}

.filter-select {
  height: 30px;
  padding: 0 10px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12px;
  color: #404040;
  background-color: #ffffff;
  outline: none;
}

/* Unit Cell Stack */
.unit-cell-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.table-code-subtext {
  font-size: 11px;
  color: #737373;
}

.text-tertiary {
  color: #737373;
  font-size: 12.5px;
}

/* Hiring Gate Status Pill */
.gate-status-pill {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 2.5px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
  white-space: nowrap;
}

.gate-open {
  background-color: #ecfdf5;
  color: #059669;
}

.gate-locked {
  background-color: #fff1f2;
  color: #e11d48;
}

/* Capacity Utilization Progress Bar */
.utilization-cell {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 120px;
}

.utilization-track {
  flex: 1;
  height: 6px;
  background-color: #e2e8f0;
  border-radius: 9999px;
  overflow: hidden;
}

.utilization-fill {
  height: 100%;
  border-radius: 9999px;
  transition: width 0.3s ease;
}

.fill-normal {
  background-color: #0B529C;
}

.fill-full {
  background-color: #e11d48;
}

.utilization-pct {
  font-size: 11.5px;
  color: #737373;
  width: 32px;
  text-align: right;
}

/* Status Pills */
.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 2.5px 9px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
  white-space: nowrap;
}

.state-active {
  background-color: #ecfdf5;
  color: #059669;
}

.state-inactive {
  background-color: #f1f5f9;
  color: #64748b;
}

/* Inspect Action Button */
.btn-inspect-gate {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 28px;
  padding: 0 10px;
  background-color: #f8fafc;
  color: #0B529C;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-inspect-gate:hover {
  background-color: #eff6ff;
  border-color: #bfdbfe;
}

/* Drawer / Inspection Modal */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 16px;
}

.drawer-modal-card {
  background-color: #ffffff;
  border-radius: 12px;
  width: 100%;
  max-width: 620px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.drawer-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid #f1f5f9;
}

.drawer-title-stack {
  display: flex;
  flex-direction: column;
}

.drawer-pretitle {
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #0B529C;
}

.drawer-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.btn-modal-close {
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 4px;
}

.drawer-body {
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* Gate Formula Card */
.gate-formula-card {
  border-radius: 10px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.card-gate-open {
  background-color: #f0fdf4;
  border: 1px solid #bbf7d0;
}

.card-gate-locked {
  background-color: #fff1f2;
  border: 1px solid #fecdd3;
}

.gate-card-top {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.gate-icon-badge {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.card-gate-open .gate-icon-badge {
  background-color: #dcfce7;
  color: #059669;
}
.card-gate-locked .gate-icon-badge {
  background-color: #ffe4e6;
  color: #e11d48;
}

.gate-card-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.gate-state-title {
  font-size: 13.5px;
  font-weight: 600;
}
.card-gate-open .gate-state-title { color: #065f46; }
.card-gate-locked .gate-state-title { color: #9f1239; }

.gate-state-desc {
  font-size: 12px;
  line-height: 1.4;
}
.card-gate-open .gate-state-desc { color: #166534; }
.card-gate-locked .gate-state-desc { color: #be123c; }

/* Formula Breakdown Row */
.formula-breakdown-row {
  display: flex;
  align-items: center;
  justify-content: space-around;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 14px;
}

.f-block {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.f-label {
  font-size: 10.5px;
  color: #737373;
}

.f-val {
  font-size: 14px;
  color: #404040;
}

.f-operator {
  font-size: 14px;
  color: #94a3b8;
  font-weight: 600;
}

/* Drawer Navigation Tabs */
.drawer-nav-tabs {
  display: flex;
  border-bottom: 1px solid #e2e8f0;
  gap: 8px;
}

.d-tab {
  padding: 8px 12px;
  background: none;
  border: none;
  border-bottom: 2px solid transparent;
  font-size: 12.5px;
  font-weight: 500;
  color: #737373;
  cursor: pointer;
}
.d-tab:hover {
  color: #0B529C;
}
.d-tab-active {
  color: #0B529C;
  border-bottom-color: #0B529C;
  font-weight: 600;
}

.specs-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.spec-card {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 14px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.spec-label {
  font-size: 11px;
  color: #737373;
}

.spec-val {
  font-size: 13px;
  color: #404040;
  font-weight: 500;
}

.sub-records-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 240px;
  overflow-y: auto;
}

.sub-record-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 14px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}

.sub-record-main {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.sub-req-code {
  font-size: 11px;
  color: #0B529C;
}

.sub-req-title {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.sub-record-meta {
  display: flex;
  align-items: center;
  gap: 8px;
}

.stage-tag {
  font-size: 11px;
  padding: 2px 8px;
  background-color: #f1f5f9;
  color: #475569;
  border-radius: 4px;
}

.cand-tag {
  font-size: 11.5px;
  color: #737373;
}

.drawer-empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 32px 16px;
  text-align: center;
  color: #94a3b8;
  font-size: 12.5px;
}

.drawer-footer {
  display: flex;
  justify-content: flex-end;
  padding: 14px 20px;
  border-top: 1px solid #f1f5f9;
  background-color: #fafafa;
}

.btn-secondary-close {
  height: 36px;
  padding: 0 16px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  color: #404040;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}
/* Table headers & sort */
.col-checkbox {
  width: 44px;
  text-align: center;
}

.custom-checkbox {
  width: 16px;
  height: 16px;
  border-radius: 4px;
  border: 1px solid #cbd5e1;
  cursor: pointer;
  accent-color: #0B529C;
}

.th-content {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.sortable {
  cursor: pointer;
  user-select: none;
}

.sort-icon {
  color: #94a3b8;
}

.active-sort {
  color: #0B529C;
}

.row-selected {
  background-color: #f8fafc !important;
}

.table-empty-row {
  padding: 48px 16px !important;
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
  font-weight: 500;
  color: #404040;
}

.empty-subtitle {
  font-size: 12.5px;
  color: #737373;
}
</style>
