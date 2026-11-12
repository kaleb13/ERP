<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Search, ShieldCheck, CheckCircle2, Eye,
  Check, X, ArrowUpRight, Briefcase,
  Filter, ArrowLeft, Clock, GitPullRequest,
  ShieldAlert
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import UnderlineTabs, { type UnderlineTabItem } from '../../components/UnderlineTabs.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import MetricCard from '../../components/MetricCard.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';

const router = useRouter();

// Breadcrumb (Rule 3: Exact Sidebar Page Name)
const breadcrumbItems = [
  { label: 'Movement Admin' }
];

// Tabs (Rule 1: UnderlineTabs for Sub-views)
type AdminTabKey = 'pending_my_action' | 'all_pending' | 'ready_to_effect' | 'history';
const activeTab = ref<AdminTabKey>('pending_my_action');

// Datasets
interface MovementAdminItem {
  id: number;
  code: string;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  movement_type: string;
  from_placement: string;
  to_placement: string;
  salary_delta: number;
  current_step_name: string;
  current_approver_name: string;
  effective_date: string;
  submitted_at: string;
  status: 'pending' | 'approved' | 'effected' | 'rejected';
  is_my_pending_action: boolean;
  require_guarantee_refresh?: boolean;
}

const adminMovements = ref<MovementAdminItem[]>([
  {
    id: 4,
    code: 'MOV-2026-0124',
    employee_id: 124,
    employee_name: 'Almaz Kebede',
    employee_code: 'EMP-00124',
    movement_type: 'promotion',
    from_placement: 'Senior Accountant • Bole Branch',
    to_placement: 'Finance Operations Lead • Haleta HQ',
    salary_delta: 3350,
    current_step_name: 'Financial Controller Sign-off',
    current_approver_name: 'Marta Tadesse',
    effective_date: '2026-10-12',
    submitted_at: '2026-10-01',
    status: 'pending',
    is_my_pending_action: true,
    require_guarantee_refresh: true
  },
  {
    id: 102,
    code: 'MOV-2026-0102',
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-014',
    movement_type: 'promotion',
    from_placement: 'Senior Cashier • Bole Commercial',
    to_placement: 'Shift Supervisor • Bole Commercial',
    salary_delta: 3350,
    current_step_name: 'Department Head Authorization',
    current_approver_name: 'Kassahun Belay',
    effective_date: '2026-09-01',
    submitted_at: '2026-08-01',
    status: 'pending',
    is_my_pending_action: true,
    require_guarantee_refresh: true
  },
  {
    id: 105,
    code: 'MOV-2026-0110',
    employee_id: 7,
    employee_name: 'Tewodros Kassahun',
    employee_code: 'EMP-007',
    movement_type: 'transfer',
    from_placement: 'HQ Security • Haleta HQ',
    to_placement: 'Plant Security • Hawassa Plant',
    salary_delta: 0,
    current_step_name: 'HR Operations Final Sign-off',
    current_approver_name: 'Almaz Mengistu',
    effective_date: '2026-10-01',
    submitted_at: '2026-08-03',
    status: 'pending',
    is_my_pending_action: true
  },
  {
    id: 107,
    code: 'MOV-2026-0118',
    employee_id: 31,
    employee_name: 'Dawit Yohannes',
    employee_code: 'EMP-031',
    movement_type: 'transfer',
    from_placement: 'Logistics Officer • Modjo Dry Port',
    to_placement: 'Central Distribution • Kality Hub',
    salary_delta: 0,
    current_step_name: 'Logistics Director Review',
    current_approver_name: 'Ephrem Tadesse',
    effective_date: '2026-11-01',
    submitted_at: '2026-08-04',
    status: 'pending',
    is_my_pending_action: false
  },
  {
    id: 106,
    code: 'MOV-2026-0114',
    employee_id: 22,
    employee_name: 'Bethlehem Haile',
    employee_code: 'EMP-022',
    movement_type: 'grade_change',
    from_placement: 'Inventory Controller • Grade C2 Step 1',
    to_placement: 'Inventory Controller • Grade C2 Step 2',
    salary_delta: 1500,
    current_step_name: 'Ready for Effectuation',
    current_approver_name: 'HR Operations',
    effective_date: '2026-08-15',
    submitted_at: '2026-07-28',
    status: 'approved',
    is_my_pending_action: false
  },
  {
    id: 108,
    code: 'MOV-2026-0125',
    employee_id: 18,
    employee_name: 'Sara Tefera',
    employee_code: 'EMP-018',
    movement_type: 'promotion',
    from_placement: 'Shift Supervisor • Bole Commercial',
    to_placement: 'Branch Operations Lead • Bole Commercial',
    salary_delta: 4200,
    current_step_name: 'Ready for Effectuation',
    current_approver_name: 'HR Operations',
    effective_date: '2026-09-15',
    submitted_at: '2026-08-02',
    status: 'approved',
    is_my_pending_action: false
  },
  {
    id: 104,
    code: 'MOV-2025-0071',
    employee_id: 29,
    employee_name: 'Solomon Tadesse',
    employee_code: 'EMP-029',
    movement_type: 'secondment',
    from_placement: 'Procurement Specialist • Haleta HQ',
    to_placement: 'Project Procurement Lead • Hawassa Expansion',
    salary_delta: 2500,
    current_step_name: 'Completed',
    current_approver_name: 'HR Operations',
    effective_date: '2025-07-01',
    submitted_at: '2025-06-15',
    status: 'effected',
    is_my_pending_action: false
  },
  {
    id: 101,
    code: 'MOV-2024-0014',
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-014',
    movement_type: 'hire',
    from_placement: 'Candidate Pool',
    to_placement: 'Senior Cashier • Bole Branch',
    salary_delta: 6500,
    current_step_name: 'Completed',
    current_approver_name: 'HR Operations',
    effective_date: '2024-06-01',
    submitted_at: '2024-05-25',
    status: 'effected',
    is_my_pending_action: false
  }
]);

// Reactive Metric Stats (Rule 2: MetricCard Standard)
const stats = computed(() => {
  const pendingMyAction = adminMovements.value.filter(
    m => m.is_my_pending_action && m.status === 'pending'
  ).length;
  const allPending = adminMovements.value.filter(
    m => m.status === 'pending'
  ).length;
  const readyToEffect = adminMovements.value.filter(
    m => m.status === 'approved'
  ).length;
  const effected = adminMovements.value.filter(
    m => m.status === 'effected'
  ).length;
  const total = adminMovements.value.length;

  return {
    pendingMyAction,
    allPending,
    readyToEffect,
    effected,
    total
  };
});

const subTabs = computed<UnderlineTabItem<AdminTabKey>[]>(() => [
  {
    id: 'pending_my_action',
    label: 'Awaiting My Action',
    count: stats.value.pendingMyAction
  },
  {
    id: 'all_pending',
    label: 'All Pending Queue',
    count: stats.value.allPending
  },
  {
    id: 'ready_to_effect',
    label: 'Approved (Ready to Effect)',
    count: stats.value.readyToEffect
  },
  {
    id: 'history',
    label: 'All Records',
    count: stats.value.total
  }
]);

// Table Columns (Rule 9: Atomic columns)
const tableColumns = ref<ColumnDef[]>([
  { key: 'employee', label: 'Employee', visible: true },
  { key: 'type', label: 'Movement Type', visible: true },
  { key: 'transition', label: 'Proposed Transition', visible: true },
  { key: 'current_step', label: 'Workflow Step', visible: true },
  { key: 'effective_date', label: 'Effective Date', visible: true },
  { key: 'status', label: 'Status', visible: true },
  { key: 'actions', label: 'Actions', visible: true }
]);

const handleToggleColumn = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  if (col) col.visible = !col.visible;
};

// Filter & Selection State
const searchQuery = ref('');
const selectedRowIds = ref<number[]>([]);
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

const filteredRecords = computed(() => {
  return adminMovements.value.filter(m => {
    // Tab filter
    if (activeTab.value === 'pending_my_action' && (!m.is_my_pending_action || m.status !== 'pending')) {
      return false;
    }
    if (activeTab.value === 'all_pending' && m.status !== 'pending') {
      return false;
    }
    if (activeTab.value === 'ready_to_effect' && m.status !== 'approved') {
      return false;
    }

    // Search query
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase();
      return (
        m.employee_name.toLowerCase().includes(q) ||
        m.code.toLowerCase().includes(q) ||
        m.employee_code.toLowerCase().includes(q)
      );
    }
    return true;
  });
});

const isAllSelected = computed(() => {
  return (
    filteredRecords.value.length > 0 &&
    filteredRecords.value.every(r => selectedRowIds.value.includes(r.id))
  );
});

const handleToggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = filteredRecords.value.map(r => r.id);
  }
};

const handleToggleRowSelect = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx > -1) {
    selectedRowIds.value.splice(idx, 1);
  } else {
    selectedRowIds.value.push(id);
  }
};

// Action Handlers
const handleInspectDossier = (id: number) => {
  router.push(`/hr/movements/${id}`);
};

const handleApproveSingle = (record: MovementAdminItem) => {
  record.status = 'approved';
  record.is_my_pending_action = false;
  record.current_step_name = 'Ready for Effectuation';
  showToast(`Movement ${record.code} approved successfully.`);
};

const handleRejectSingle = (record: MovementAdminItem) => {
  record.status = 'rejected';
  record.is_my_pending_action = false;
  record.current_step_name = 'Rejected';
  showToast(`Movement ${record.code} rejected.`);
};

const handleEffectSingle = (record: MovementAdminItem) => {
  record.status = 'effected';
  record.current_step_name = 'Effected';
  showToast(`Movement ${record.code} formally effected into active assignments.`);
};

// Batch Actions
const handleBatchApprove = () => {
  adminMovements.value.forEach(m => {
    if (selectedRowIds.value.includes(m.id) && m.status === 'pending') {
      m.status = 'approved';
      m.is_my_pending_action = false;
      m.current_step_name = 'Ready for Effectuation';
    }
  });
  showToast(`Approved ${selectedRowIds.value.length} selected movements.`);
  selectedRowIds.value = [];
};

const handleBatchEffect = () => {
  adminMovements.value.forEach(m => {
    if (selectedRowIds.value.includes(m.id) && m.status === 'approved') {
      m.status = 'effected';
      m.current_step_name = 'Effected';
    }
  });
  showToast(`Formally effected ${selectedRowIds.value.length} approved movements.`);
  selectedRowIds.value = [];
};

const handleBatchDelete = () => {
  adminMovements.value = adminMovements.value.filter(m => !selectedRowIds.value.includes(m.id));
  showToast(`Removed ${selectedRowIds.value.length} records.`);
  selectedRowIds.value = [];
};

const formatMovementType = (type: string) => {
  const map: Record<string, string> = {
    promotion: 'Promotion',
    transfer: 'Lateral Transfer',
    grade_change: 'Grade Increment',
    hire: 'Initial Hire'
  };
  return map[type] || type;
};
</script>

<template>
  <div class="movement-admin-page">
    <!-- Breadcrumb Standard (Rule 3) -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Toast Notification -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <!-- Top KPI / Metrics Cards Grid (Rule 2 Standard) -->
    <div class="metrics-grid">
      <MetricCard
        label="Awaiting My Action"
        :value="`${stats.pendingMyAction} Pending`"
        subtext="Requires your immediate endorsement"
        :icon="Clock"
        :show-menu="false"
        class="metric-card-interactive"
        :class="{ 'metric-card--active': activeTab === 'pending_my_action' }"
        @click="activeTab = 'pending_my_action'"
      />
      <MetricCard
        label="All Pending Queue"
        :value="`${stats.allPending} In Review`"
        subtext="Active departmental approval chains"
        :icon="GitPullRequest"
        :show-menu="false"
        class="metric-card-interactive"
        :class="{ 'metric-card--active': activeTab === 'all_pending' }"
        @click="activeTab = 'all_pending'"
      />
      <MetricCard
        label="Ready to Effect"
        :value="`${stats.readyToEffect} Approved`"
        subtext="Endorsed by governance, ready to sync"
        :icon="CheckCircle2"
        :show-menu="false"
        class="metric-card-interactive"
        :class="{ 'metric-card--active': activeTab === 'ready_to_effect' }"
        @click="activeTab = 'ready_to_effect'"
      />
      <MetricCard
        label="All Lifecycle Records"
        :value="`${stats.total} Total`"
        subtext="Complete organizational movement registry"
        :icon="Briefcase"
        :show-menu="false"
        class="metric-card-interactive"
        :class="{ 'metric-card--active': activeTab === 'history' }"
        @click="activeTab = 'history'"
      />
    </div>

    <!-- Master Unified Table Card (Rule 10) -->
    <AppDataTable
      title="Movement Admin &amp; Approvals"
      subtitle="Dedicated administrative workspace to review, endorse, and effectuate employee movement proposals across branches."
      :columns="tableColumns"
      :show-view-action="false"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Sub-view Underline Tabs (Rule 1) -->
      <template #header-extra>
        <div class="tabs-subview-wrapper">
          <UnderlineTabs
            v-model="activeTab"
            :tabs="subTabs"
            size="sm"
          />
        </div>
      </template>

      <!-- Top Right Toolbar Actions -->
      <template #actions>
        <AppButton variant="outline" size="sm" @click="router.push('/hr/movements')">
          <template #icon-left><ArrowLeft :size="15" /></template>
          General Movements Directory
        </AppButton>
      </template>

      <!-- Filter Strip -->
      <template #filters>
        <div class="filter-controls-row">
          <div class="filter-search-box">
            <Search :size="14" class="search-icon" />
            <input
              v-model="searchQuery"
              type="text"
              class="filter-search-input"
              placeholder="Search by employee, code, or role..."
            />
          </div>
        </div>
      </template>

      <!-- Table Rows (Rule 8, 9: Atomic Columns) -->
      <template #default>
        <table class="erp-table">
          <thead>
            <tr>
              <th class="th-checkbox">
                <input
                  type="checkbox"
                  class="table-checkbox"
                  :checked="isAllSelected"
                  @change="handleToggleSelectAll"
                />
              </th>
              <th>Name</th>
              <th>Movement Type</th>
              <th>Proposed Transition</th>
              <th>Workflow Stage</th>
              <th>Effective Date</th>
              <th>Status</th>
              <th class="th-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="item in filteredRecords"
              :key="item.id"
              class="table-row-hover"
              @click="handleInspectDossier(item.id)"
            >
              <!-- Checkbox -->
              <td class="td-checkbox" @click.stop>
                <input
                  type="checkbox"
                  class="table-checkbox"
                  :checked="selectedRowIds.includes(item.id)"
                  @change="handleToggleRowSelect(item.id)"
                />
              </td>

              <!-- Employee Name (Rule 5: Secondary Color #404040) -->
              <td>
                <div class="emp-name-cell">
                  <span class="emp-name-text">{{ item.employee_name }}</span>
                  <span class="emp-code-sub">{{ item.code }} &bull; {{ item.employee_code }}</span>
                </div>
              </td>

              <!-- Type (Rule 5: Tertiary Color #737373) -->
              <td class="td-tertiary">
                <div class="movement-type-cell">
                  <span>{{ formatMovementType(item.movement_type) }}</span>
                  <span v-if="item.require_guarantee_refresh" class="admin-surety-pill" title="Financial Surety / Guarantor Refresh Required">
                    <ShieldAlert :size="10" />
                    <span>Surety Req.</span>
                  </span>
                </div>
              </td>

              <!-- Proposed Transition (Rule 5 & 6: Plain Text Tertiary) -->
              <td class="td-tertiary">
                <div class="transition-summary-cell">
                  <span class="to-placement-text">{{ item.to_placement }}</span>
                  <span v-if="item.salary_delta !== 0" class="salary-delta-mini">
                    {{ item.salary_delta > 0 ? '+' : '' }}ETB {{ item.salary_delta }}
                  </span>
                </div>
              </td>

              <!-- Workflow Stage -->
              <td class="td-tertiary">
                <span class="workflow-stage-pill">
                  {{ item.current_step_name }}
                </span>
              </td>

              <!-- Effective Date -->
              <td class="td-tertiary">
                {{ item.effective_date }}
              </td>

              <!-- Status (Rule 9: Status Column) -->
              <td>
                <span class="status-pill" :class="`status-${item.status}`">
                  {{ item.status }}
                </span>
              </td>

              <!-- Actions (Rule 8) -->
              <td class="td-actions" @click.stop>
                <div class="row-actions-group">
                  <button
                    type="button"
                    class="btn-action-icon"
                    title="View Full Movement Dossier"
                    @click="handleInspectDossier(item.id)"
                  >
                    <Eye :size="14" />
                  </button>

                  <button
                    v-if="item.status === 'pending'"
                    type="button"
                    class="btn-action-approve"
                    title="Approve Step"
                    @click="handleApproveSingle(item)"
                  >
                    <Check :size="13" />
                  </button>

                  <button
                    v-if="item.status === 'pending'"
                    type="button"
                    class="btn-action-reject"
                    title="Reject Step"
                    @click="handleRejectSingle(item)"
                  >
                    <X :size="13" />
                  </button>

                  <button
                    v-if="item.status === 'approved'"
                    type="button"
                    class="btn-action-effect"
                    title="Effect Movement into Live Records"
                    @click="handleEffectSingle(item)"
                  >
                    <ArrowUpRight :size="13" />
                  </button>
                </div>
              </td>
            </tr>

            <!-- Empty State -->
            <tr v-if="filteredRecords.length === 0">
              <td colspan="8" class="empty-state-cell">
                <div class="empty-message-wrap">
                  <ShieldCheck :size="24" class="text-tertiary" />
                  <span class="empty-title">No movement records found</span>
                  <span class="empty-sub">There are no movement approvals matching this filter.</span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </template>
    </AppDataTable>

    <!-- Floating Batch Action Bar -->
    <TableFloatingBar
      :count="selectedRowIds.length"
      @delete="handleBatchDelete"
    >
      <template #custom-actions>
        <button
          v-if="activeTab !== 'ready_to_effect'"
          type="button"
          class="btn-floating-action"
          @click="handleBatchApprove"
        >
          <CheckCircle2 :size="13" />
          <span>Approve Selected</span>
        </button>

        <button
          v-if="activeTab === 'ready_to_effect' || activeTab === 'history'"
          type="button"
          class="btn-floating-action"
          @click="handleBatchEffect"
        >
          <ArrowUpRight :size="13" />
          <span>Effect Selected</span>
        </button>
      </template>
    </TableFloatingBar>
  </div>
</template>

<style scoped>
.movement-admin-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: var(--alias-color-bg-canvas, #f8fafc);
  min-height: 100vh;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
}

/* Metric Cards Grid (Rule 2 Standard) */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

@media (max-width: 1024px) {
  .metrics-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 640px) {
  .metrics-grid {
    grid-template-columns: 1fr;
  }
}

.metric-card-interactive {
  cursor: pointer;
  user-select: none;
  transition: all 0.15s ease;
}

.metric-card-interactive.metric-card--active {
  border-color: #0B529C;
  box-shadow: 0 0 0 1px #0B529C, 0 2px 8px rgba(11, 82, 156, 0.08);
}

.tabs-subview-wrapper {
  margin-top: 4px;
}

.btn-nav-general {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 34px;
  padding: 0 12px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-nav-general:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

/* Filters */
.filter-controls-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.filter-search-box {
  position: relative;
  width: 320px;
}

.search-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: #94a3b8;
}

.filter-search-input {
  width: 100%;
  height: 34px;
  padding: 0 12px 0 32px;
  font-size: 13px;
  color: #404040;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  outline: none;
}

.filter-search-input:focus {
  border-color: #0B529C;
}

/* Table */
.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background-color: #fafafa;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
}

.table-row-hover {
  cursor: pointer;
  transition: background-color 0.15s;
}

.table-row-hover:hover {
  background-color: #f8fafc;
}

.th-checkbox, .td-checkbox {
  width: 40px;
  text-align: center;
  padding: 8px !important;
}

.table-checkbox {
  width: 15px;
  height: 15px;
  cursor: pointer;
  accent-color: #0B529C;
}

/* Typography Hierarchy (Rule 5) */
.emp-name-cell {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.emp-name-text {
  font-weight: 600;
  color: #404040;
}

.emp-code-sub {
  font-size: 11.5px;
  color: #737373;
}

.td-tertiary {
  color: #737373 !important;
}

.movement-type-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.admin-surety-pill {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  font-size: 10px;
  font-weight: 600;
  background-color: #fffbeb;
  color: #b45309;
  border: 1px solid #fde68a;
  padding: 1px 6px;
  border-radius: 4px;
}

.transition-summary-cell {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.to-placement-text {
  color: #404040;
  font-size: 12.5px;
}

.salary-delta-mini {
  font-size: 11px;
  color: #059669;
  font-weight: 500;
}

.workflow-stage-pill {
  font-size: 11.5px;
  color: #475569;
  background-color: #f1f5f9;
  padding: 2px 8px;
  border-radius: 4px;
}

/* Status Pills */
.status-pill {
  display: inline-block;
  padding: 2px 10px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 600;
  text-transform: capitalize;
}

.status-pending {
  background-color: #eff6ff;
  color: #0B529C;
}

.status-approved {
  background-color: #ecfdf5;
  color: #059669;
}

.status-effected {
  background-color: #f0fdf4;
  color: #15803d;
}

.status-rejected {
  background-color: #fef2f2;
  color: #dc2626;
}

/* Actions */
.th-actions {
  text-align: right;
  width: 130px;
}

.td-actions {
  text-align: right;
}

.row-actions-group {
  display: inline-flex;
  align-items: center;
  gap: 4px;
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
  transition: all 0.15s;
}

.btn-action-icon:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.btn-action-approve {
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #bbf7d0;
  border-radius: 6px;
  background-color: #f0fdf4;
  color: #15803d;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-action-approve:hover {
  background-color: #dcfce7;
}

.btn-action-reject {
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #fecdd3;
  border-radius: 6px;
  background-color: #fff1f2;
  color: #be123c;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-action-reject:hover {
  background-color: #ffe4e6;
}

.btn-action-effect {
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  background-color: #f8fafc;
  color: #0B529C;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-action-effect:hover {
  background-color: #eff6ff;
}

/* Empty State */
.empty-state-cell {
  text-align: center;
  padding: 40px !important;
}

.empty-message-wrap {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.text-tertiary {
  color: #94a3b8;
}

.empty-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.empty-sub {
  font-size: 12px;
  color: #737373;
}

/* Floating Bar Button */
.btn-floating-action {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 30px;
  padding: 0 10px;
  font-size: 12px;
  font-weight: 500;
  color: #ffffff;
  background-color: rgba(255, 255, 255, 0.15);
  border: 1px solid rgba(255, 255, 255, 0.25);
  border-radius: 6px;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-floating-action:hover {
  background-color: rgba(255, 255, 255, 0.25);
}

/* Toast */
.toast-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  background-color: #064e3b;
  color: #ffffff;
  border-radius: 8px;
  font-size: 13px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 100;
}

.toast-fade-enter-active,
.toast-fade-leave-active {
  transition: opacity 0.2s, transform 0.2s;
}

.toast-fade-enter-from,
.toast-fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}
</style>
