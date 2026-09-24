<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Plus, Edit2, Trash2, Check, X,
  CheckCircle2, ShieldCheck, ArrowUpDown
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

const router = useRouter();

// ─── Lookups & Types (HR Schema Designer 1.sql lines 1202–1235) ───
export type RowState = 'active' | 'inactive';
export type BudgetState = 'draft' | 'approved' | 'active' | 'closed';

export interface HeadcountPlanRecord {
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
  annual_budget_amount: number;
  currency_id: string;
  budget_state_lookup_value_id: BudgetState;
  budget_state_label: string;
  approved_by_name?: string;
  approved_at?: string;
  notes?: string;
  state: RowState;
}

// ─── Breadcrumbs (Rule: Exact Page Name from Sidebar Only: "Headcount Planning") ───
const breadcrumbItems = [
  { label: 'Headcount Planning' }
];

// ─── State Management ───
const searchQuery = ref('');
const filterYear = ref('All');
const filterEntity = ref('All');
const filterStatus = ref('All');
const selectedRows = ref<number[]>([]);
const currentSort = ref('unit_name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const toastMessage = ref('');

// Quick Approval Modal State
const isApproveModalOpen = ref(false);
const planToApprove = ref<HeadcountPlanRecord | null>(null);
const approverNameInput = ref('Sofia Hailu (Chief Human Resources Officer)');

// ─── Canonical Seed Data (Directly aligned with HR Schema Designer 1.sql lines 1227–1234) ───
const plans = ref<HeadcountPlanRecord[]>([
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
    annual_budget_amount: 936000,
    currency_id: 'ETB',
    budget_state_lookup_value_id: 'active',
    budget_state_label: 'Active',
    approved_by_name: 'Sofia Hailu (CHRO)',
    approved_at: '15/06/2026',
    notes: 'Approved operational headcount for hotel hospitality and culinary staff.',
    state: 'active'
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
    annual_budget_amount: 1152000,
    currency_id: 'ETB',
    budget_state_lookup_value_id: 'active',
    budget_state_label: 'Active',
    approved_by_name: 'Yonas Tadesse (VP Eng)',
    approved_at: '20/06/2026',
    notes: 'Expansion headcount for core platform backend and DevOps personnel.',
    state: 'active'
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
    annual_budget_amount: 720000,
    currency_id: 'ETB',
    budget_state_lookup_value_id: 'active',
    budget_state_label: 'Active',
    approved_by_name: 'Abebe Kebede (CFO)',
    approved_at: '10/06/2026',
    notes: 'Accounting and tax audit positions approved under corporate quota.',
    state: 'active'
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
    annual_budget_amount: 468000,
    currency_id: 'ETB',
    budget_state_lookup_value_id: 'approved',
    budget_state_label: 'Approved',
    approved_by_name: 'Marta Getachew (Director)',
    approved_at: '28/06/2026',
    notes: 'Heavy vehicle operators and freight coordinators quota.',
    state: 'active'
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
    annual_budget_amount: 900000,
    currency_id: 'ETB',
    budget_state_lookup_value_id: 'draft',
    budget_state_label: 'Draft',
    approved_by_name: undefined,
    approved_at: undefined,
    notes: 'People operations partners and talent acquisition specialists.',
    state: 'active'
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
    annual_budget_amount: 840000,
    currency_id: 'ETB',
    budget_state_lookup_value_id: 'closed',
    budget_state_label: 'Closed',
    approved_by_name: 'Sofia Hailu (CHRO)',
    approved_at: '12/06/2025',
    notes: 'FY2026 closed operating headcount budget.',
    state: 'inactive'
  }
]);

// ─── Table Columns (Rule 9: Atomic columns, Name-first order, clean plain text) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'unit_name', label: 'Organization Unit', visible: true, sortable: true },
  { key: 'fiscal_year', label: 'Fiscal Year', visible: true, sortable: true },
  { key: 'entity_name', label: 'Owning Entity', visible: true, sortable: true },
  { key: 'approved_headcount', label: 'Target Capacity', visible: true, sortable: true },
  { key: 'annual_budget_amount', label: 'Annual Salary Budget', visible: true, sortable: true },
  { key: 'budget_state_label', label: 'Budget Status', visible: true, sortable: true },
  { key: 'approved_by_name', label: 'Sanctioned By', visible: true, sortable: true },
  { key: 'period', label: 'Effective Period', visible: false, sortable: false },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

// ─── Filter Options ───
const uniqueFiscalYears = computed(() => {
  const yrs = Array.from(new Set(plans.value.map(p => p.fiscal_year))).filter(Boolean);
  return ['All', ...yrs];
});

const uniqueEntities = computed(() => {
  const ents = Array.from(new Set(plans.value.map(p => p.entity_name))).filter(Boolean);
  return ['All', ...ents];
});

const statusOptions = ['All', 'Draft', 'Approved', 'Active', 'Closed'];

const activeFilterCount = computed(() => {
  let count = 0;
  if (filterYear.value !== 'All') count++;
  if (filterEntity.value !== 'All') count++;
  if (filterStatus.value !== 'All') count++;
  return count;
});

// ─── Filtered Plans with Sorting ───
const filteredPlans = computed(() => {
  return plans.value.filter(item => {
    // Search query matches Unit, Code, or Approver
    const q = searchQuery.value.toLowerCase().trim();
    if (q) {
      const matchUnit = item.unit_name.toLowerCase().includes(q);
      const matchCode = item.unit_code.toLowerCase().includes(q);
      const matchEntity = item.entity_name.toLowerCase().includes(q);
      const matchApprover = (item.approved_by_name || '').toLowerCase().includes(q);
      if (!matchUnit && !matchCode && !matchEntity && !matchApprover) return false;
    }
    // Fiscal Year filter
    if (filterYear.value !== 'All' && item.fiscal_year !== filterYear.value) return false;
    // Entity filter
    if (filterEntity.value !== 'All' && item.entity_name !== filterEntity.value) return false;
    // Status filter
    if (filterStatus.value !== 'All' && item.budget_state_label.toLowerCase() !== filterStatus.value.toLowerCase()) return false;

    return true;
  }).sort((a, b) => {
    let valA = a[currentSort.value as keyof HeadcountPlanRecord];
    let valB = b[currentSort.value as keyof HeadcountPlanRecord];
    if (valA === undefined || valA === null) valA = '';
    if (valB === undefined || valB === null) valB = '';
    if (valA < valB) return sortOrder.value === 'asc' ? -1 : 1;
    if (valA > valB) return sortOrder.value === 'asc' ? 1 : -1;
    return 0;
  });
});

// ─── Selection Logic ───
const isAllSelected = computed(() => {
  return filteredPlans.value.length > 0 && filteredPlans.value.every(p => selectedRows.value.includes(p.id));
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRows.value = [];
  } else {
    selectedRows.value = filteredPlans.value.map(p => p.id);
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

// ─── Actions ───
const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = ''; }, 3500);
};

const handleCreate = () => {
  router.push('/hr/headcount-planning/create');
};

const openApproveModal = (plan: HeadcountPlanRecord) => {
  planToApprove.value = plan;
  isApproveModalOpen.value = true;
};

const confirmApproval = () => {
  if (!planToApprove.value) return;
  planToApprove.value.budget_state_lookup_value_id = 'approved';
  planToApprove.value.budget_state_label = 'Approved';
  planToApprove.value.approved_by_name = approverNameInput.value;
  planToApprove.value.approved_at = new Date().toLocaleDateString('en-GB');
  showToast(`Headcount plan for ${planToApprove.value.unit_name} has been formally sanctioned.`);
  isApproveModalOpen.value = false;
  planToApprove.value = null;
};

const handleDelete = (id: number) => {
  const plan = plans.value.find(p => p.id === id);
  if (!plan) return;
  if (!confirm(`Are you sure you want to delete the headcount budget plan for "${plan.unit_name}"?`)) return;
  plans.value = plans.value.filter(p => p.id !== id);
  selectedRows.value = selectedRows.value.filter(rowId => rowId !== id);
  showToast('Headcount budget plan removed.');
};

const handleBatchDelete = () => {
  if (!confirm(`Delete ${selectedRows.value.length} selected budget plans?`)) return;
  plans.value = plans.value.filter(p => !selectedRows.value.includes(p.id));
  showToast(`Successfully removed ${selectedRows.value.length} budget plans.`);
  selectedRows.value = [];
};

const getBudgetStatusBadgeClass = (status: BudgetState) => {
  switch (status) {
    case 'draft': return 'status-badge-draft';
    case 'approved': return 'status-badge-approved';
    case 'active': return 'status-badge-active';
    case 'closed': return 'status-badge-closed';
    default: return 'status-badge-draft';
  }
};
</script>

<template>
  <div class="headcount-planning-page">
    <!-- Breadcrumb: EXACT Sidebar Page Name Only (Rule 3) -->
    <AppBreadcrumb :items="breadcrumbItems" />

    <!-- Unified Table Card Standard (Rule 10: AppDataTable) -->
    <AppDataTable
      title="Headcount Planning"
      subtitle="Annual workforce quota planning, compensation ceilings, and governance approvals per fiscal period."
      v-model:searchQuery="searchQuery"
      searchPlaceholder="Search by unit name, code, or approver..."
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
      <!-- Action Slot: Primary Action in Top Right Toolbar -->
      <template #actions>
        <button 
          type="button" 
          class="btn-primary-create"
          @click="handleCreate"
        >
          <Plus :size="15" />
          <span>Create Budget Plan</span>
        </button>
      </template>

      <!-- Custom Filter Panel (Reveals when Filter button clicked) -->
      <template #filter>
        <div class="planning-filters-row">
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
            <span class="filter-label">Budget Status:</span>
            <select v-model="filterStatus" class="filter-select">
              <option v-for="st in statusOptions" :key="st" :value="st">{{ st }}</option>
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

            <!-- Name Column: Secondary color (#404040), Subtext code in tertiary (#737373) -->
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

            <th v-if="isColumnVisible('entity_name')" class="col-entity">Owning Entity</th>
            <th v-if="isColumnVisible('approved_headcount')" class="col-capacity">Target Capacity</th>
            <th v-if="isColumnVisible('annual_budget_amount')" class="col-budget">Annual Salary Budget</th>
            <th v-if="isColumnVisible('budget_state_label')" class="col-status">Budget Status</th>
            <th v-if="isColumnVisible('approved_by_name')" class="col-approver">Sanctioned By</th>
            <th v-if="isColumnVisible('period')" class="col-period">Effective Period</th>

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
            v-for="row in filteredPlans" 
            :key="row.id"
            class="erp-row cursor-pointer"
            :class="{ 'row-selected': selectedRows.includes(row.id) }"
            @click="router.push(`/hr/headcount-planning/create?id=${row.id}`)"
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

            <!-- Owning Entity -->
            <td v-if="isColumnVisible('entity_name')" class="col-entity">
              <span class="text-tertiary">{{ row.entity_name }}</span>
            </td>

            <!-- Target Capacity -->
            <td v-if="isColumnVisible('approved_headcount')" class="col-capacity">
              <span class="text-tertiary font-medium text-slate-700">{{ row.approved_headcount }} Seats</span>
            </td>

            <!-- Annual Salary Budget -->
            <td v-if="isColumnVisible('annual_budget_amount')" class="col-budget">
              <span class="text-tertiary font-mono">{{ Number(row.annual_budget_amount).toLocaleString() }} {{ row.currency_id }}</span>
            </td>

            <!-- Budget Status Pill -->
            <td v-if="isColumnVisible('budget_state_label')" class="col-status">
              <span class="status-pill" :class="getBudgetStatusBadgeClass(row.budget_state_lookup_value_id)">
                {{ row.budget_state_label }}
              </span>
            </td>

            <!-- Sanctioned By -->
            <td v-if="isColumnVisible('approved_by_name')" class="col-approver">
              <span class="text-tertiary">{{ row.approved_by_name || '—' }}</span>
            </td>

            <!-- Effective Period -->
            <td v-if="isColumnVisible('period')" class="col-period">
              <span class="text-tertiary font-mono text-xs">{{ row.period_start }} – {{ row.period_end }}</span>
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
              <div class="table-actions-cluster">
                <!-- Quick Sanction / Approve Button for Draft budgets -->
                <button 
                  v-if="row.budget_state_lookup_value_id === 'draft'"
                  type="button" 
                  class="btn-row-sanction"
                  @click="openApproveModal(row)"
                  title="Approve / Sanction Plan"
                >
                  <ShieldCheck :size="13" />
                  <span>Approve</span>
                </button>

                <!-- Edit -->
                <button 
                  type="button" 
                  class="btn-action-icon"
                  @click="router.push(`/hr/headcount-planning/create?id=${row.id}`)"
                  title="Edit Plan"
                >
                  <Edit2 :size="13" />
                </button>

                <!-- Delete -->
                <button 
                  type="button" 
                  class="btn-action-icon text-rose-500 hover:text-rose-700"
                  @click="handleDelete(row.id)"
                  title="Delete Plan"
                >
                  <Trash2 :size="13" />
                </button>
              </div>
            </td>
          </tr>

          <!-- Empty State -->
          <tr v-if="filteredPlans.length === 0">
            <td colspan="11" class="table-empty-row">
              <div class="empty-state-box">
                <p class="empty-title">No Headcount Budget Plans Found</p>
                <p class="empty-subtitle">Adjust your filter options or create a new headcount budget plan.</p>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </AppDataTable>

    <!-- Floating Batch Bar (Rule 11) -->
    <TableFloatingBar 
      :count="selectedRows.length" 
      @delete="handleBatchDelete" 
    />

    <!-- Quick Sanction / Approval Dialog -->
    <div v-if="isApproveModalOpen" class="modal-backdrop" @click="isApproveModalOpen = false">
      <div class="modal-card" @click.stop>
        <div class="modal-header">
          <h3 class="modal-title">Sanction Headcount Budget Plan</h3>
          <button type="button" class="btn-modal-close" @click="isApproveModalOpen = false">
            <X :size="16" />
          </button>
        </div>

        <div class="modal-body" v-if="planToApprove">
          <p class="modal-guidance-text">
            You are authorizing the official workforce headcount allocation and salary expenditure ceiling for 
            <strong>{{ planToApprove.unit_name }}</strong> for Fiscal Year <strong>{{ planToApprove.fiscal_year }}</strong>.
          </p>

          <div class="modal-summary-panel">
            <div class="summary-line">
              <span class="line-label">Target Seat Capacity:</span>
              <span class="line-val font-semibold">{{ planToApprove.approved_headcount }} Seats</span>
            </div>
            <div class="summary-line">
              <span class="line-label">Annual Salary Pool:</span>
              <span class="line-val font-mono font-semibold">{{ Number(planToApprove.annual_budget_amount).toLocaleString() }} {{ planToApprove.currency_id }}</span>
            </div>
            <div class="summary-line">
              <span class="line-label">Owning Branch:</span>
              <span class="line-val">{{ planToApprove.entity_name }}</span>
            </div>
          </div>

          <div class="form-field-wrap mt-3">
            <label class="field-label">Sanctioning Executive Authority</label>
            <input 
              type="text" 
              v-model="approverNameInput" 
              class="form-input-simple"
            />
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn-secondary-cancel" @click="isApproveModalOpen = false">Cancel</button>
          <button type="button" class="btn-primary-confirm" @click="confirmApproval">
            <Check :size="14" />
            <span>Confirm & Sanction Budget</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Notification Toast -->
    <div v-if="toastMessage" class="toast-popup">
      <CheckCircle2 :size="15" class="text-emerald-500" />
      <span>{{ toastMessage }}</span>
    </div>
  </div>
</template>

<style scoped>
.headcount-planning-page {
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* Primary Create Button (Rule 6: 8-10px radius) */
.btn-primary-create {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-primary-create:hover {
  background-color: #09427d;
}

/* Filters Ribbon */
.planning-filters-row {
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

/* Unit Cell Stack (Name First + Subtext Code) */
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

/* Budget Status Badges */
.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 2.5px 9px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
  white-space: nowrap;
}

.status-badge-draft {
  background-color: #eff6ff;
  color: #1d4ed8;
}

.status-badge-approved {
  background-color: #faf5ff;
  color: #7e22ce;
}

.status-badge-active {
  background-color: #ecfdf5;
  color: #059669;
}

.status-badge-closed {
  background-color: #f1f5f9;
  color: #475569;
}

.state-active {
  background-color: #ecfdf5;
  color: #059669;
}

.state-inactive {
  background-color: #f1f5f9;
  color: #64748b;
}

/* Action Buttons Cluster */
.table-actions-cluster {
  display: flex;
  align-items: center;
  gap: 6px;
}

.btn-row-sanction {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  height: 26px;
  padding: 0 8px;
  background-color: #eff6ff;
  color: #0B529C;
  border: 1px solid #bfdbfe;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-row-sanction:hover {
  background-color: #0B529C;
  color: #ffffff;
}

.btn-action-icon {
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  background-color: #ffffff;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-action-icon:hover {
  background-color: #f8fafc;
  color: #0f172a;
}

/* Sanction Modal */
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

.modal-card {
  background-color: #ffffff;
  border-radius: 12px;
  width: 100%;
  max-width: 480px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid #f1f5f9;
}

.modal-title {
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

.modal-body {
  padding: 20px;
}

.modal-guidance-text {
  font-size: 13px;
  color: #404040;
  line-height: 1.5;
  margin-bottom: 14px;
}

.modal-summary-panel {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 14px;
}

.summary-line {
  display: flex;
  justify-content: space-between;
  font-size: 12.5px;
}

.line-label {
  color: #737373;
}

.line-val {
  color: #404040;
}

.form-field-wrap {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.field-label {
  font-size: 12px;
  font-weight: 500;
  color: #404040;
}

.form-input-simple {
  height: 38px;
  padding: 0 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  outline: none;
}
.form-input-simple:focus {
  border-color: #0B529C;
}

.modal-footer {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
  padding: 14px 20px;
  border-top: 1px solid #f1f5f9;
  background-color: #fafafa;
}

.btn-secondary-cancel {
  height: 36px;
  padding: 0 14px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  color: #404040;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-primary-confirm {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 16px;
  border: none;
  border-radius: 8px;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

/* Toast */
.toast-popup {
  position: fixed;
  bottom: 24px;
  right: 24px;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  font-size: 13px;
  color: #404040;
  z-index: 1100;
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
