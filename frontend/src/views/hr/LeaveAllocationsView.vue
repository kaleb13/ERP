<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, Search, CheckCircle2, Clock,
  Check, Award, Repeat, TrendingUp,
  MoreVertical, Eye
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import UnderlineTabs, { type UnderlineTabItem } from '../../components/UnderlineTabs.vue';
import MetricCard from '../../components/MetricCard.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';

const router = useRouter();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3) ───
const breadcrumbItems = [
  { label: 'Leave Allocations' }
];

// ─── Schema-Aligned Datasets: LeaveAllocation [DIST] (Lines 1632–1661) ───
import { 
  allocationsData, 
  createAllocation,
  type LeaveAllocationRecord 
} from './leaveAllocationData';

const allocations = allocationsData;

// ─── Sub-views & Tabs (Rule 1: UnderlineTabs) ───
type TabKey = 'all' | 'approved' | 'pending' | 'consumed' | 'draft';
const activeTab = ref<TabKey>('all');

const pendingCount = computed(() => allocations.value.filter(a => a.allocation_state === 'submitted' || a.allocation_state === 'draft').length);
const approvedCount = computed(() => allocations.value.filter(a => a.allocation_state === 'approved').length);
const consumedCount = computed(() => allocations.value.filter(a => a.allocation_state === 'consumed').length);

const subTabs = computed<UnderlineTabItem[]>(() => [
  { id: 'all', label: 'All Allocations' },
  { id: 'approved', label: 'Active Approved', count: approvedCount.value },
  { id: 'pending', label: 'Pending Review', count: pendingCount.value },
  { id: 'consumed', label: 'Consumed (FY Close)', count: consumedCount.value },
  { id: 'draft', label: 'Drafts' }
]);

// ─── Filtering & Selection ───
const searchQuery = ref('');
const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

const filteredAllocations = computed(() => {
  return allocations.value.filter(item => {
    // Tab filter
    if (activeTab.value === 'approved' && item.allocation_state !== 'approved') return false;
    if (activeTab.value === 'pending' && item.allocation_state !== 'submitted' && item.allocation_state !== 'draft') return false;
    if (activeTab.value === 'consumed' && item.allocation_state !== 'consumed') return false;
    if (activeTab.value === 'draft' && item.allocation_state !== 'draft') return false;

    // Search query
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase().trim();
      const matchName = item.employee_name.toLowerCase().includes(q);
      const matchCode = item.employee_code.toLowerCase().includes(q);
      const matchAllocCode = item.code.toLowerCase().includes(q);
      const matchPosition = item.job_position.toLowerCase().includes(q);
      if (!matchName && !matchCode && !matchAllocCode && !matchPosition) return false;
    }

    return true;
  });
});

const isAllSelected = computed(() => {
  return (
    filteredAllocations.value.length > 0 &&
    filteredAllocations.value.every(r => selectedRowIds.value.includes(r.id))
  );
});

const handleToggleSelectAll = (checked: boolean) => {
  if (checked) {
    selectedRowIds.value = filteredAllocations.value.map(r => r.id);
  } else {
    selectedRowIds.value = [];
  }
};

const handleToggleRow = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx > -1) {
    selectedRowIds.value.splice(idx, 1);
  } else {
    selectedRowIds.value.push(id);
  }
};

// ─── Table Columns (Single Information Architecture per Rule 9) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Name', visible: true, sortable: true },
  { key: 'leave_type', label: 'Leave Type', visible: true, sortable: true },
  { key: 'period', label: 'Fiscal Period', visible: true, sortable: true },
  { key: 'allocated_days', label: 'Base Allocated', visible: true, sortable: true },
  { key: 'carried_forward', label: 'Carried Forward', visible: true, sortable: true },
  { key: 'total_entitled', label: 'Total Entitled', visible: true, sortable: true },
  { key: 'available', label: 'Available', visible: true, sortable: true },
  { key: 'status', label: 'Status', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

const handleToggleColumn = (colKey: string | { key: string; visible: boolean }) => {
  const k = typeof colKey === 'string' ? colKey : colKey.key;
  const col = tableColumns.value.find(c => c.key === k);
  if (col) col.visible = typeof colKey === 'string' ? !col.visible : colKey.visible;
};

const isColVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

// ─── Quick Create Modal State & Handlers ───
const isCreateModalOpen = ref(false);
const createForm = ref({
  employee_id: 14,
  leave_type_id: 1,
  period_start: '2026-07-08',
  period_end: '2027-07-07',
  allocated_days: 18.0,
  carried_forward_days: 0.0
});

const employeeOptions: SelectOption[] = [
  { value: 14, label: 'Abebe Kebede (EMP 0014 • Senior Cashier)' },
  { value: 22, label: 'Almaz Kebede (EMP 0124 • Senior Accountant)' },
  { value: 31, label: 'Dawit Yohannes (EMP 0031 • Logistics Officer)' },
  { value: 44, label: 'Kassahun Belay (EMP 0044 • Branch Head)' },
  { value: 7, label: 'Marta Tadesse (EMP 0007 • Branch Manager)' }
];

const leaveTypeOptions: SelectOption[] = [
  { value: 1, label: 'Annual Leave' }
];

const computedTotalEntitled = computed(() => {
  return Number(createForm.value.allocated_days || 0) + Number(createForm.value.carried_forward_days || 0);
});

const openCreateModal = () => {
  isCreateModalOpen.value = true;
};

const closeCreateModal = () => {
  isCreateModalOpen.value = false;
};

const handleSubmitQuickCreate = () => {
  const newRow = createAllocation({
    employee_id: createForm.value.employee_id,
    leave_type_id: createForm.value.leave_type_id,
    period_start: createForm.value.period_start,
    period_end: createForm.value.period_end,
    allocated_days: createForm.value.allocated_days,
    carried_forward_days: createForm.value.carried_forward_days,
    notes: 'Manual annual quota grant from quick create modal.',
    isDraft: false
  });

  showToast(`Leave allocation ${newRow.code} granted successfully.`);
  closeCreateModal();
};

const handleExpandToFull = () => {
  isCreateModalOpen.value = false;
  router.push({
    path: '/hr/leave-allocations/create',
    query: {
      employee_id: createForm.value.employee_id,
      leave_type_id: createForm.value.leave_type_id,
      period_start: createForm.value.period_start,
      period_end: createForm.value.period_end,
      allocated_days: createForm.value.allocated_days,
      carried_forward_days: createForm.value.carried_forward_days
    }
  });
};

const formatDateRange = (start: string, end: string) => {
  const dStart = new Date(start);
  const dEnd = new Date(end);
  const opt: Intl.DateTimeFormatOptions = { month: 'short', day: 'numeric', year: 'numeric' };
  return `${dStart.toLocaleDateString('en-US', opt)} – ${dEnd.toLocaleDateString('en-US', opt)}`;
};
</script>

<template>
  <div class="leave-allocations-page" @click="activeActionMenuId = null">
    <!-- Breadcrumb Standard (Rule 3: [Monitor] > Leave Allocations strictly) -->
    <div class="breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Toast Notification -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <!-- ─── 4 METRIC CARDS (Category B Operational Status per Rule 2) ─── -->
    <div class="metrics-grid">
      <!-- Card 1: Total Allocated -->
      <MetricCard
        label="TOTAL ALLOCATED (FY 2026/27)"
        value="1,420 Days"
        subtext="Base quota granted across 64 staff"
        :icon="Award"
        :show-menu="false"
        class="metric-interactive"
        :class="{ 'metric-active': activeTab === 'all' }"
        @click="activeTab = 'all'"
      />

      <!-- Card 2: Carried Forward Days -->
      <MetricCard
        label="CARRIED FORWARD"
        value="248 Days"
        subtext="Prior year rollover (2-yr expiry)"
        :icon="Repeat"
        :show-menu="false"
      />

      <!-- Card 3: Pending Allocations -->
      <MetricCard
        label="PENDING ALLOCATIONS"
        value="4 Grants"
        subtext="Awaiting annual review batch"
        :icon="Clock"
        :show-menu="false"
        class="metric-interactive"
        :class="{ 'metric-active': activeTab === 'pending' }"
        @click="activeTab = 'pending'"
      />

      <!-- Card 4: Consumed Rate -->
      <MetricCard
        label="CONSUMED RATE"
        value="18.4%"
        subtext="307.5 days utilized or scheduled"
        :icon="TrendingUp"
        :show-menu="false"
        class="metric-interactive"
        :class="{ 'metric-active': activeTab === 'consumed' }"
        @click="activeTab = 'consumed'"
      />
    </div>

    <!-- ─── MASTER DATA TABLE CARD (Rule 10: Unified card layout) ─── -->
    <AppDataTable
      title="Leave Allocations"
      subtitle="Manage statutory annual leave grants per Ethiopian fiscal year, compute service-year additions, rollover prior year balances, and track consumption."
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

      <!-- Primary Action in Top Right Slot (+ Allocate Leave) -->
      <template #actions>
        <AppButton variant="primary" size="sm" @click="openCreateModal">
  <template #icon-left><Plus :size="15" /></template>
  Allocate Leave
</AppButton>
      </template>

      <!-- Table Body (Atomic Columns per Rule 9) -->
      <template #default>
        <table class="erp-table">
          <thead>
            <tr>
              <th class="th-checkbox">
                <input
                  type="checkbox"
                  class="table-checkbox"
                  :checked="isAllSelected"
                  @change="handleToggleSelectAll(($event.target as HTMLInputElement).checked)"
                />
              </th>
              <th>Name</th>
              <th>Leave Type</th>
              <th>Fiscal Period</th>
              <th>Base Allocated</th>
              <th>Carried Forward</th>
              <th>Total Entitled</th>
              <th>Available</th>
              <th>Status</th>
              <th class="th-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="item in filteredAllocations"
              :key="item.id"
              class="table-row-hover clickable-row"
              @click="router.push(`/hr/leave-allocations/${item.id}`)"
            >
              <!-- Checkbox -->
              <td class="td-checkbox" @click.stop>
                <input
                  type="checkbox"
                  class="table-checkbox"
                  :checked="selectedRowIds.includes(item.id)"
                  @change="handleToggleRow(item.id)"
                />
              </td>

              <!-- Name Column: Avatar + Full Name in bold + Code/Position underneath -->
              <td class="td-name-cell">
                <div class="employee-identity-block">
                  <img :src="item.employee_avatar" :alt="item.employee_name" class="table-avatar" />
                  <div class="name-subtext-group">
                    <span class="table-name-primary">{{ item.employee_name }}</span>
                    <span class="table-code-subtext">{{ item.employee_code }} • {{ item.job_position }}</span>
                  </div>
                </div>
              </td>

              <!-- Leave Type: Plain text in #737373 -->
              <td class="td-tertiary">
                {{ item.leave_type_name }}
              </td>

              <!-- Fiscal Period: Plain text in #737373 -->
              <td class="td-tertiary">
                {{ formatDateRange(item.period_start, item.period_end) }}
              </td>

              <!-- Base Allocated: Plain text in #737373 -->
              <td class="td-tertiary">
                {{ item.allocated_days.toFixed(1) }} d
              </td>

              <!-- Carried Forward: Plain text in #737373 -->
              <td class="td-tertiary">
                {{ item.carried_forward_days.toFixed(1) }} d
              </td>

              <!-- Total Entitled: #404040 Semi-Bold -->
              <td class="td-entitled-bold">
                {{ item.total_entitled_days.toFixed(1) }} d
              </td>

              <!-- Available Days: Brand blue #0B529C -->
              <td class="td-available-blue">
                {{ item.available_days.toFixed(1) }} d
              </td>

              <!-- Status Pill (Lifecycle State) -->
              <td>
                <span class="status-pill" :class="`status-${item.allocation_state}`">
                  {{ item.allocation_state.charAt(0).toUpperCase() + item.allocation_state.slice(1) }}
                </span>
              </td>

              <!-- Actions (⋮ 3-dots button) -->
              <td class="td-actions" @click.stop>
                <div class="action-menu-wrapper">
                  <button
                    type="button"
                    class="btn-action-dots"
                    title="Actions"
                    @click="activeActionMenuId = activeActionMenuId === item.id ? null : item.id"
                  >
                    <MoreVertical :size="15" />
                  </button>

                  <Transition name="dropdown-fade">
                    <div v-if="activeActionMenuId === item.id" class="action-dropdown-popup">
                      <button 
                        type="button" 
                        class="action-item" 
                        @click="router.push(`/hr/leave-allocations/${item.id}`); activeActionMenuId = null"
                      >
                        <Eye :size="13" />
                        <span>View Allocation Details &amp; Ledger</span>
                      </button>

                      <template v-if="item.allocation_state === 'draft' || item.allocation_state === 'submitted'">
                        <button 
                          type="button" 
                          class="action-item text-green" 
                          @click="item.allocation_state = 'approved'; activeActionMenuId = null; showToast('Allocation approved.');"
                        >
                          <Check :size="13" />
                          <span>Approve Allocation</span>
                        </button>
                      </template>
                    </div>
                  </Transition>
                </div>
              </td>
            </tr>

            <!-- Empty State -->
            <tr v-if="filteredAllocations.length === 0">
              <td colspan="10" class="empty-state-cell">
                <span class="empty-text">No leave allocations found for this filter.</span>
              </td>
            </tr>
          </tbody>
        </table>
      </template>
    </AppDataTable>

    <!-- Floating Batch Bar (Rule 11) -->
    <TableFloatingBar
      v-if="selectedRowIds.length > 0"
      :count="selectedRowIds.length"
      @delete="selectedRowIds = []"
    />

    <!-- ─── Quick Create Modal (Rule 4: <=5 required fields) ─── -->
    <QuickCreateModal
      :show="isCreateModalOpen"
      title="Allocate Leave Quota"
      save-label="Save"
      width="lg"
      :show-expand-button="true"
      @update:show="isCreateModalOpen = $event"
      @expand="handleExpandToFull"
      @save="handleSubmitQuickCreate"
      @cancel="closeCreateModal"
    >
      <div class="modal-form-content">
        <!-- Employee Select -->
        <div class="form-row-single">
          <FormSelect
            v-model="createForm.employee_id"
            label="Select Employee"
            :options="employeeOptions"
            placeholder="Select Employee"
            :required="true"
          />
        </div>

        <!-- Leave Type Select -->
        <div class="form-row-single">
          <FormSelect
            v-model="createForm.leave_type_id"
            label="Leave Type"
            :options="leaveTypeOptions"
            placeholder="Select Type"
            :required="true"
          />
        </div>

        <!-- Fiscal Period Range -->
        <div class="form-grid-2col">
          <FormInput
            v-model="createForm.period_start"
            type="date"
            label="Fiscal Period Start"
            :required="true"
          />
          <FormInput
            v-model="createForm.period_end"
            type="date"
            label="Fiscal Period End"
            :required="true"
          />
        </div>

        <!-- Days Inputs -->
        <div class="form-grid-2col">
          <FormInput
            v-model="createForm.allocated_days"
            type="number"
            label="Base Allocated Days"
            :required="true"
            hint="Statutory base (16d) plus completed service-year additions (+1d/year)."
          />
          <FormInput
            v-model="createForm.carried_forward_days"
            type="number"
            label="Carried Forward Days"
            hint="Unused quota brought forward from prior fiscal period."
          />
        </div>

        <!-- Dynamic Entitlement Projection Card -->
        <div class="entitlement-calc-card">
          <div class="ecc-top">
            <span class="ecc-label">Projected Total Entitlement (LeaveBalance)</span>
            <span class="ecc-val">{{ computedTotalEntitled.toFixed(1) }} Working Days</span>
          </div>
          <p class="ecc-sub">
            Combines {{ Number(createForm.allocated_days || 0).toFixed(1) }} base days + {{ Number(createForm.carried_forward_days || 0).toFixed(1) }} rolled-over days for FY 2026/27.
          </p>
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.leave-allocations-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: var(--alias-color-bg-canvas, #f8fafc);
  min-height: 100vh;
}

/* Breadcrumbs */
.breadcrumb-bar {
  display: flex;
  align-items: center;
}

/* Toast */
.toast-bar {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background-color: #0B529C;
  color: #ffffff;
  padding: 8px 16px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  box-shadow: 0 4px 12px rgba(11, 82, 156, 0.2);
  align-self: flex-start;
}

/* Metric Cards Grid */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

@media (max-width: 1100px) {
  .metrics-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 640px) {
  .metrics-grid {
    grid-template-columns: 1fr;
  }
}

.metric-interactive {
  cursor: pointer;
  transition: transform 0.15s, border-color 0.15s;
}

.metric-interactive:hover {
  transform: translateY(-2px);
  border-color: #cbd5e1;
}

.metric-active {
  border-color: #0B529C !important;
  box-shadow: 0 4px 14px rgba(11, 82, 156, 0.12) !important;
}

.tabs-subview-wrapper {
  margin-top: 4px;
}

/* Primary Allocate Button */
.btn-allocate-primary {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 13px;
  font-weight: 500;
  padding: 0 16px;
  height: 36px;
  border-radius: 8px;
  border: none;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-allocate-primary:hover {
  background-color: #094380;
}

/* Table styles */
.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table th {
  background-color: #fafafa;
  color: #737373;
  font-size: 12px;
  font-weight: 500;
  height: 34px;
  padding: 8px 16px;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  font-size: 13px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.table-row-hover {
  transition: background-color 0.1s;
}

.table-row-hover:hover {
  background-color: #f8fafc;
}

.th-checkbox, .td-checkbox {
  width: 40px;
  padding-left: 16px;
  padding-right: 8px;
}

.table-checkbox {
  width: 15px;
  height: 15px;
  accent-color: #0B529C;
  cursor: pointer;
}

/* Name Column with Avatar & Subtitle */
.td-name-cell {
  padding-top: 10px;
  padding-bottom: 10px;
}

.employee-identity-block {
  display: flex;
  align-items: center;
  gap: 12px;
}

.table-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  object-fit: cover;
  border: 1px solid #e2e8f0;
  flex-shrink: 0;
}

.name-subtext-group {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.table-code-subtext {
  font-size: 11.5px;
  color: #737373;
}

.td-tertiary {
  color: #737373;
}

.td-entitled-bold {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.td-available-blue {
  font-size: 13px;
  font-weight: 600;
  color: #0B529C;
}

/* Status Pills */
.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
}

.status-approved {
  background-color: #ecfdf5;
  color: #059669;
}

.status-consumed {
  background-color: #f1f5f9;
  color: #475569;
}

.status-draft {
  background-color: #fffbeb;
  color: #d97706;
}

.status-cancelled {
  background-color: #fef2f2;
  color: #dc2626;
}

/* Action Dots */
.th-actions, .td-actions {
  width: 50px;
  text-align: right;
  padding-right: 16px;
}

.action-menu-wrapper {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.action-dropdown-popup {
  position: absolute;
  top: 32px;
  right: 0;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  padding: 4px;
  min-width: 170px;
  z-index: 50;
}

.action-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 7px 10px;
  border: none;
  background: transparent;
  font-size: 12.5px;
  color: #404040;
  cursor: pointer;
  border-radius: 5px;
  text-align: left;
}

.action-item:hover {
  background-color: #f8fafc;
}

.text-green {
  color: #059669;
}

.empty-state-cell {
  text-align: center;
  padding: 36px;
}

.empty-text {
  font-size: 13px;
  color: #737373;
}

/* Quick Create Modal Content */
.modal-form-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-row-single {
  display: flex;
  flex-direction: column;
}

.form-grid-2col {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

.entitlement-calc-card {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-left: 4px solid #0B529C;
  border-radius: 6px;
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.ecc-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.ecc-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.ecc-val {
  font-size: 14px;
  font-weight: 700;
  color: #0B529C;
}

.ecc-sub {
  margin: 0;
  font-size: 11.5px;
  color: #737373;
}
</style>
