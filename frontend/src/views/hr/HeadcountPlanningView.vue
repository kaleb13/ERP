<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, Edit2, Trash2, X,
  CheckCircle2, ShieldCheck, ArrowUpDown, User,
  MoreVertical, Eye
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import MetricCard from '../../components/MetricCard.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import FormSelect from '../../components/FormSelect.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import { useToast } from '../../composables/useToast';

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

// ─── Breadcrumbs (Image 1 & 4: "[Monitor] > Headcount Budgets") ───
const breadcrumbItems = [
  { label: 'Headcount Budgets' }
];

// ─── State Management ───
// Role Persona: 'approver' sees Metric Cards & approval tools; 'creator' sees clean proposal directory without metric cards
const userRole = ref<'approver' | 'creator'>('approver');
const searchQuery = ref('');
const filterYear = ref('All');
const filterEntity = ref('All');
const filterStatus = ref('All');
const selectedRows = ref<number[]>([]);
const currentSort = ref('unit_name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const { toast } = useToast();
const activeDropdownId = ref<number | null>(null);

// Quick Approval Modal State
const isApproveModalOpen = ref(false);
const planToApprove = ref<HeadcountPlanRecord | null>(null);
const approverNameInput = ref('Sofia Hailu (Chief Human Resources Officer)');

// ─── Canonical Seed Data (Matching Image 1 & Image 4) ───
const plans = ref<HeadcountPlanRecord[]>([
  {
    id: 1,
    uuid: 'hcb-001-bole-2028',
    tenant_id: 1,
    entity_id: 7,
    entity_name: 'QMT Bole',
    organization_unit_id: 3,
    unit_name: 'Commercial Sales',
    unit_code: 'COMM-SALES',
    fiscal_year: 'FY 2028',
    period_start: 'Jul 8, 2028',
    period_end: 'Jul 7, 2028',
    approved_headcount: 12,
    annual_budget_amount: 1404000,
    currency_id: 'ETB',
    budget_state_lookup_value_id: 'draft',
    budget_state_label: 'Draft',
    approved_by_name: '-',
    approved_at: undefined,
    notes: 'Operational workforce proposal for new commercial hospitality wing.',
    state: 'active'
  },
  {
    id: 2,
    uuid: 'hcb-002-mekanisa-2026',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'QMT Mekanisa',
    organization_unit_id: 2,
    unit_name: 'Senior Cashier',
    unit_code: 'SR-CASHIER',
    fiscal_year: 'FY 2026/27',
    period_start: 'Jul 8, 2026',
    period_end: 'Jul 7, 2027',
    approved_headcount: 6,
    annual_budget_amount: 720000,
    currency_id: 'ETB',
    budget_state_lookup_value_id: 'active',
    budget_state_label: 'Active',
    approved_by_name: 'Sofia Hailu (CFO)',
    approved_at: '15/06/2026',
    notes: 'Senior Cashier quota approved under corporate branch allocation.',
    state: 'active'
  },
  {
    id: 3,
    uuid: 'hcb-003-koye-2025',
    tenant_id: 1,
    entity_id: 9,
    entity_name: 'QMT koye',
    organization_unit_id: 5,
    unit_name: 'Human Resource',
    unit_code: 'HR-DEPT',
    fiscal_year: 'FY 2025',
    period_start: 'Jul 8, 2025',
    period_end: 'Jul 7, 2025',
    approved_headcount: 8,
    annual_budget_amount: 960000,
    currency_id: 'ETB',
    budget_state_lookup_value_id: 'approved',
    budget_state_label: 'Approved',
    approved_by_name: 'Abebe Mola (Director)',
    approved_at: '10/06/2025',
    notes: 'Human Resource regional desk staffing quota.',
    state: 'active'
  }
]);

// ─── Table Columns (Exact to Image 1 & Image 4) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'unit_name', label: 'Organization Units', visible: true, sortable: true },
  { key: 'entity_name', label: 'Owning Entity', visible: true, sortable: true },
  { key: 'period', label: 'Fiscal Period', visible: true, sortable: true },
  { key: 'approved_headcount', label: 'Target Capacity', visible: true, sortable: true },
  { key: 'approved_by_name', label: 'Approved By', visible: true, sortable: true },
  { key: 'budget_state_label', label: 'Status', visible: true, sortable: true },
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

// ─── Approver Executive Metric Values (Matching Image 4) ───
const pendingApprovalCount = computed(() => {
  return plans.value.filter(p => p.budget_state_lookup_value_id === 'draft').length;
});

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
  toast.success(msg);
};

const handleCreate = () => {
  router.push(`/hr/headcount-planning/create?role=${userRole.value}`);
};

const openApproveModal = (plan: HeadcountPlanRecord) => {
  planToApprove.value = plan;
  isApproveModalOpen.value = true;
  activeDropdownId.value = null;
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
  activeDropdownId.value = null;
};

const handleBatchDelete = () => {
  if (!confirm(`Delete ${selectedRows.value.length} selected budget plans?`)) return;
  plans.value = plans.value.filter(p => !selectedRows.value.includes(p.id));
  showToast(`Successfully removed ${selectedRows.value.length} budget plans.`);
  selectedRows.value = [];
};

const currentPage = ref(1);
const perPage = ref(10);

const paginatedPlans = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredPlans.value.slice(start, start + perPage.value);
});

const toggleDropdown = (id: number) => {
  activeDropdownId.value = activeDropdownId.value === id ? null : id;
};

const closeDropdowns = () => {
  activeDropdownId.value = null;
};

const getBudgetStatusBadgeClass = (status: BudgetState) => {
  switch (status) {
    case 'draft': return 'badge-status-draft';
    case 'approved': return 'badge-status-approved';
    case 'active': return 'badge-status-active';
    case 'closed': return 'badge-status-closed';
    default: return 'badge-status-draft';
  }
};
</script>

<template>
  <div class="headcount-planning-page" @click="closeDropdowns">
    <!-- Top Bar: EXACT Breadcrumb on Left + Role Persona Toggle on Right -->
    <div class="planning-header-row">
      <AppBreadcrumb :items="breadcrumbItems" />

      <!-- Role View Persona Switcher (Approver vs Creator for testing) -->
      <div class="role-switcher-container">
        <span class="role-switcher-label">View Mode:</span>
        <div class="role-pill-group">
          <button 
            type="button" 
            class="role-pill-btn"
            :class="{ 'role-active': userRole === 'approver' }"
            @click="userRole = 'approver'"
            title="Switch to Approver view (Image 4)"
          >
            <ShieldCheck :size="13" />
            <span>Approver</span>
          </button>
          <button 
            type="button" 
            class="role-pill-btn"
            :class="{ 'role-active': userRole === 'creator' }"
            @click="userRole = 'creator'"
            title="Switch to Creator view (Image 1)"
          >
            <User :size="13" />
            <span>Creator</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Executive Metric Cards: VISIBLE FOR APPROVER ONLY (Image 4), HIDDEN FOR CREATOR (Image 1) -->
    <transition name="fade-slide">
      <div v-if="userRole === 'approver'" class="planning-kpis-grid">
        <MetricCard 
          label="PENDING APPROVAL REQUESTS" 
          value="1 Plans" 
          subtext="Awaiting Executive Approval" 
        />
        <MetricCard 
          label="TOTAL PROPOSED SEATS" 
          value="45 Seats" 
          subtext="Total Workforce Demanded" 
        />
        <MetricCard 
          label="TOTAL APPROVED CAPACITY" 
          value="30 Seats" 
          subtext="Formally Approved headcount" 
        />
        <MetricCard 
          label="CORPORATE SALARY POOL" 
          value="5,616,000 ETB" 
          subtext="Total Roll-up Annual Payroll Ceiling" 
        />
      </div>
    </transition>

    <!-- Unified Table Card Standard (Image 1 & Image 4) -->
    <AppDataTable
      title="Headcount Planning"
      subtitle="Annual workforce quota planning, compensation ceilings, and governance approvals per fiscal period."
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
      :totalEntries="filteredPlans.length"
      v-model:currentPage="currentPage"
      v-model:perPage="perPage"
      :showPagination="true"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Action Slot: Primary Action in Top Right Toolbar (+ Create Budgets) -->
      <template #actions>
        <AppButton 
          variant="primary"
          size="sm"
          @click="handleCreate"
        >
          <template #icon-left>
            <Plus :size="15" />
          </template>
          Create Budgets
        </AppButton>
      </template>

      <!-- Custom Filter Panel (Reveals when Filter button clicked) -->
      <template #filter>
        <div class="planning-filters-row">
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
              v-model="filterStatus"
              label="Budget Status:"
              :options="statusOptions.map(st => ({ value: st, label: st }))"
              placeholder="Select Status"
            />
          </div>
        </div>
      </template>

      <!-- Canonical ERP Table Listing (Matching Image 1 & 4) -->
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

            <!-- Organization Units Column (Secondary color #404040 500) -->
            <th v-if="isColumnVisible('unit_name')" class="col-unit sortable" @click="currentSort = 'unit_name'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
              <div class="th-content">
                <span>Organization Units</span>
                <ArrowUpDown v-if="currentSort === 'unit_name'" :size="12" class="sort-icon active-sort" />
              </div>
            </th>

            <th v-if="isColumnVisible('entity_name')" class="col-entity">Owning Entity</th>
            
            <th v-if="isColumnVisible('period')" class="col-period sortable" @click="currentSort = 'fiscal_year'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
              <div class="th-content">
                <span>Fiscal Period</span>
                <ArrowUpDown v-if="currentSort === 'fiscal_year'" :size="12" class="sort-icon active-sort" />
              </div>
            </th>

            <th v-if="isColumnVisible('approved_headcount')" class="col-capacity">Target Capacity</th>
            <th v-if="isColumnVisible('approved_by_name')" class="col-approver">Approved By</th>
            <th v-if="isColumnVisible('budget_state_label')" class="col-status">Status</th>
            <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr 
            v-for="row in paginatedPlans" 
            :key="row.id"
            class="erp-row cursor-pointer"
            :class="{ 'row-selected': selectedRows.includes(row.id) }"
            @click="router.push(`/hr/headcount-planning/create?id=${row.id}&role=${userRole}`)"
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

            <!-- Organization Units: Primary Secondary Color (#404040, Medium 500) -->
            <td v-if="isColumnVisible('unit_name')" class="col-unit">
              <span class="table-name-primary">{{ row.unit_name }}</span>
            </td>

            <!-- Owning Entity: Tertiary Color (#737373) -->
            <td v-if="isColumnVisible('entity_name')" class="col-entity">
              <span class="text-tertiary">{{ row.entity_name }}</span>
            </td>

            <!-- Fiscal Period: Stacked (FY on Top in #404040, Dates below in #737373) -->
            <td v-if="isColumnVisible('period')" class="col-period">
              <div class="period-cell-stack">
                <span class="period-fy font-medium text-slate-700">{{ row.fiscal_year }}</span>
                <span class="period-dates text-tertiary text-xs">{{ row.period_start }} – {{ row.period_end }}</span>
              </div>
            </td>

            <!-- Target Capacity: Tertiary Color with Seats suffix -->
            <td v-if="isColumnVisible('approved_headcount')" class="col-capacity">
              <span class="text-tertiary">{{ row.approved_headcount }} Seats</span>
            </td>

            <!-- Approved By -->
            <td v-if="isColumnVisible('approved_by_name')" class="col-approver">
              <span class="text-tertiary">{{ row.approved_by_name || '-' }}</span>
            </td>

            <!-- Status Badge (Matching Image 1 & 4) -->
            <td v-if="isColumnVisible('budget_state_label')" class="col-status">
              <span class="status-badge-pill" :class="getBudgetStatusBadgeClass(row.budget_state_lookup_value_id)">
                {{ row.budget_state_label }}
              </span>
            </td>

            <!-- Actions: 3-Dots Dropdown Menu -->
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
                    @click="router.push(`/hr/headcount-planning/create?id=${row.id}&role=approver`); activeDropdownId = null"
                  >
                    <Eye :size="13" />
                    <span>View / Review</span>
                  </button>
                  <button 
                    type="button" 
                    class="action-menu-item"
                    @click="router.push(`/hr/headcount-planning/create?id=${row.id}&role=creator`); activeDropdownId = null"
                  >
                    <Edit2 :size="13" />
                    <span>Edit Plan</span>
                  </button>
                  <button 
                    type="button" 
                    class="action-menu-item text-danger"
                    @click="handleDelete(row.id)"
                  >
                    <Trash2 :size="13" />
                    <span>Delete</span>
                  </button>
                </div>
              </div>
            </td>
          </tr>

          <!-- Empty State -->
          <tr v-if="filteredPlans.length === 0">
            <td colspan="8" class="table-empty-row">
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
          <AppButton variant="outline" size="sm" @click="isApproveModalOpen = false">Cancel</AppButton>
          <AppButton variant="primary" size="sm" @click="confirmApproval">
            Confirm &amp; Sanction Budget
          </AppButton>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.headcount-planning-page {
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
}

/* Planning Header Row (Breadcrumbs + Role Switcher) */
.planning-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}

.role-switcher-container {
  display: flex;
  align-items: center;
  gap: 8px;
}

.role-switcher-label {
  font-size: 11.5px;
  font-weight: 500;
  color: #737373;
}

.role-pill-group {
  display: inline-flex;
  background-color: #f1f5f9;
  padding: 2px;
  border-radius: 8px;
  gap: 2px;
}

.role-pill-btn {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
  background: transparent;
  border: none;
  cursor: pointer;
  transition: all 0.15s ease;
}

.role-pill-btn.role-active {
  background-color: #ffffff;
  color: #404040;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06);
}

/* KPI Grid for Approver (Rule 2: MetricCard Standard) */
.planning-kpis-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
  margin-bottom: 4px;
}

@media (max-width: 1024px) {
  .planning-kpis-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 640px) {
  .planning-kpis-grid {
    grid-template-columns: 1fr;
  }
}

/* Primary Create Action Button in Toolbar */
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
  font-size: 13.5px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
  white-space: nowrap;
}

.btn-primary-create:hover {
  background-color: #09427d;
}

/* Filter Row */
.planning-filters-row {
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
  min-width: 140px;
}

.col-period {
  min-width: 160px;
}

.col-capacity {
  min-width: 120px;
}

.col-approver {
  min-width: 150px;
}

.col-status {
  min-width: 100px;
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

.period-cell-stack {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.period-fy {
  font-size: 13px;
  color: #404040;
}

.period-dates {
  font-size: 11.5px;
  color: #737373;
}

/* Status Badges (Image 1 & 4) */
.status-badge-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  border-radius: 100px;
  font-size: 11.5px;
  font-weight: 500;
}

.badge-status-draft {
  background-color: #FEF3C7;
  color: #D97706;
}

.badge-status-active {
  background-color: #DCFCE7;
  color: #16A34A;
}

.badge-status-approved {
  background-color: #DBEAFE;
  color: #0B529C;
}

.badge-status-closed {
  background-color: #F1F5F9;
  color: #64748B;
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

.action-menu-item.text-danger {
  color: #ef4444;
}

.action-menu-item.text-danger:hover {
  background-color: #fef2f2;
}

/* Pagination Bar (Matching Image 1 & 4) */
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

/* Modal */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
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
  padding: 16px 20px;
  border-bottom: 1px solid #f1f5f9;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.modal-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0;
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
  color: #64748b;
  margin: 0 0 16px 0;
  line-height: 1.5;
}

.modal-summary-panel {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.summary-line {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 12.5px;
}

.line-label {
  color: #737373;
}

.line-val {
  color: #404040;
}

.modal-footer {
  padding: 12px 20px;
  background-color: #fafafa;
  border-top: 1px solid #f1f5f9;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
}

.btn-secondary-cancel {
  height: 36px;
  padding: 0 14px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  cursor: pointer;
}

.btn-primary-confirm {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 16px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}
</style>
