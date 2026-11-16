<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, Search, CheckCircle2, Clock,
  Check, X, Banknote, Users,
  MoreVertical, Eye
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import MetricCard from '../../components/MetricCard.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import { 
  encashmentsData, 
  staffList, 
  createEncashment, 
  submitApprovalDecision,
  type LeaveEncashmentRecord, 
  type StaffQuotaContext 
} from './leaveEncashmentData';

const router = useRouter();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3: Exact Sidebar Page Name Only) ───
const breadcrumbItems = [
  { label: 'Leave Encashments' }
];

// ─── Shared Reactive Dataset (HR Schema Lines 1785–1812) ───
const encashments = encashmentsData;

// ─── Standard Table Filtering (AGENTS.md Rule 9 & 10) ───
const searchQuery = ref('');
const filterStatus = ref('All');
const filterState = ref('All');

const activeFilterCount = computed(() => {
  let count = 0;
  if (filterStatus.value !== 'All') count++;
  if (filterState.value !== 'All') count++;
  return count;
});

const handleResetFilter = () => {
  filterStatus.value = 'All';
  filterState.value = 'All';
  searchQuery.value = '';
};

// ─── Filtered Datasets ───
const filteredEncashments = computed(() => {
  return encashments.value.filter(item => {
    // Search query matches Employee Name, Code, or Leave Type
    const q = searchQuery.value.toLowerCase().trim();
    if (q) {
      const matchName = item.employee_name.toLowerCase().includes(q);
      const matchCode = item.code.toLowerCase().includes(q);
      const matchEmpCode = item.employee_code.toLowerCase().includes(q);
      const matchType = item.leave_type_name.toLowerCase().includes(q);
      if (!matchName && !matchCode && !matchEmpCode && !matchType) return false;
    }
    // Status Filter (Lifecycle: pending, approved, draft, rejected)
    if (filterStatus.value !== 'All' && item.request_state !== filterStatus.value) return false;
    // State Filter (active, inactive)
    if (filterState.value !== 'All' && item.state !== filterState.value) return false;

    return true;
  });
});

// ─── Table Columns (Rule 9: Table Column Architecture & Single Information Standard) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Name', visible: true, sortable: true },
  { key: 'leave_type', label: 'Leave Type', visible: true, sortable: true },
  { key: 'allocation_code', label: 'Quota Bucket', visible: true, sortable: true },
  { key: 'encashed_days', label: 'Days Encashed', visible: true, sortable: true },
  { key: 'daily_rate', label: 'Daily Rate', visible: true, sortable: true },
  { key: 'gross_amount', label: 'Gross Payout', visible: true, sortable: true },
  { key: 'payroll_sync', label: 'Payroll Settlement', visible: true, sortable: true },
  { key: 'status', label: 'Status', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
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

// ─── Selection State for Batch Operations (Rule 11) ───
const selectedIds = ref<number[]>([]);

const isAllSelected = computed(() => {
  return filteredEncashments.value.length > 0 && selectedIds.value.length === filteredEncashments.value.length;
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedIds.value = [];
  } else {
    selectedIds.value = filteredEncashments.value.map(e => e.id);
  }
};

const toggleSelectRow = (id: number) => {
  const idx = selectedIds.value.indexOf(id);
  if (idx > -1) {
    selectedIds.value.splice(idx, 1);
  } else {
    selectedIds.value.push(id);
  }
};

const handleBatchDelete = () => {
  encashments.value = encashments.value.filter(e => !selectedIds.value.includes(e.id));
  showToast(`Deleted ${selectedIds.value.length} encashment request(s).`);
  selectedIds.value = [];
};

// ─── Staff Options & Active Quota Buckets for Creation ───
const staffSelectOptions = computed<SelectOption[]>(() => {
  return staffList.map(s => ({
    value: s.id,
    label: `${s.name} (${s.code} • ${s.available_days}d available)`
  }));
});

// ─── Quick Create Modal State & Calculation ───
const isCreateModalOpen = ref(false);
const quickForm = ref({
  employee_id: 14,
  requested_days: 5.0,
  reason: ''
});

const selectedQuickStaff = computed<StaffQuotaContext>(() => {
  return staffList.find(s => s.id === quickForm.value.employee_id) || staffList[0];
});

const quickDailyRate = computed(() => {
  const staff = selectedQuickStaff.value;
  return Number((staff.basic_salary / staff.payroll_days).toFixed(2));
});

const quickGrossAmount = computed(() => {
  return Number((quickDailyRate.value * (quickForm.value.requested_days || 0)).toFixed(2));
});

const openCreateModal = () => {
  quickForm.value = {
    employee_id: 14,
    requested_days: 5.0,
    reason: ''
  };
  isCreateModalOpen.value = true;
};

const closeCreateModal = () => {
  isCreateModalOpen.value = false;
};

const handleExpandToFull = () => {
  isCreateModalOpen.value = false;
  router.push({
    path: '/hr/leave-encashments/create',
    query: {
      employee_id: quickForm.value.employee_id,
      requested_days: quickForm.value.requested_days,
      reason: quickForm.value.reason
    }
  });
};

const handleSubmitQuickCreate = () => {
  const newRow = createEncashment({
    employee_id: quickForm.value.employee_id,
    requested_days: Number(quickForm.value.requested_days),
    reason: quickForm.value.reason,
    isDraft: false
  });

  showToast(`Encashment request ${newRow.code} submitted successfully.`);
  closeCreateModal();
};

// ─── Navigation to Dedicated Detail View (Rule 10 Rule 3) ───
const goToDetail = (id: number) => {
  activeActionMenuId.value = null;
  router.push(`/hr/leave-encashments/${id}`);
};

// ─── Action Menu Handlers ───
const activeActionMenuId = ref<number | null>(null);

const handleApprove = (item: LeaveEncashmentRecord) => {
  submitApprovalDecision(item.id, 'approve', item.requested_days, 'Quick approved from directory table.');
  activeActionMenuId.value = null;
  showToast(`Encashment ${item.code} approved for ${item.currency} ${item.amount.toLocaleString()}.`);
};

const handleReject = (item: LeaveEncashmentRecord) => {
  submitApprovalDecision(item.id, 'reject', 0, 'Quick rejected from directory table.');
  activeActionMenuId.value = null;
  showToast(`Encashment ${item.code} rejected.`);
};

// ─── Toast Feedback ───
const toastMessage = ref<string | null>(null);
const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

const formatCurrency = (val: number) => {
  return (val || 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
};
</script>

<template>
  <div class="leave-encashments-page" @click="activeActionMenuId = null">
    <!-- Breadcrumb (Rule 3: [Monitor] > Leave Encashments strictly) -->
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

    <!-- ─── 4 UNIFIED METRIC CARDS (Rule 2: MetricCard Standard) ─── -->
    <div class="metrics-grid">
      <!-- Card 1: PENDING APPROVAL -->
      <MetricCard
        label="PENDING APPROVAL"
        :value="encashments.filter(e => e.request_state === 'pending').length + ' Requests'"
        subtext="Awaiting managerial sign-off"
        :icon="Clock"
        :show-menu="false"
      />

      <!-- Card 2: APPROVED THIS FY -->
      <MetricCard
        label="APPROVED THIS FY"
        :value="encashments.filter(e => e.request_state === 'approved').length + ' Encashed'"
        subtext="Days converted into cash payout"
        :icon="CheckCircle2"
        :show-menu="false"
      />

      <!-- Card 3: TOTAL PAYOUT (YTD) -->
      <MetricCard
        label="TOTAL PAYOUT (YTD)"
        :value="'ETB ' + formatCurrency(encashments.filter(e => e.request_state === 'approved').reduce((acc, curr) => acc + curr.amount, 0))"
        subtext="Processed via payroll inputs"
        :icon="Banknote"
        :show-menu="false"
      />

      <!-- Card 4: ELIGIBLE STAFF POOL -->
      <MetricCard
        label="ELIGIBLE STAFF POOL"
        :value="staffList.length + ' Staff'"
        subtext="Unutilized annual quota holders"
        :icon="Users"
        :show-menu="false"
      />
    </div>

    <!-- ─── MASTER UNIFIED DATA TABLE CARD (Rule 10 & Rule 9) ─── -->
    <AppDataTable
      title="Leave Encashments"
      subtitle="Submit and monitor statutory in-service leave encashment requests, verify accrued quota balances, and review managerial authorizations."
      v-model:searchQuery="searchQuery"
      searchPlaceholder="Search Name or Code..."
      :showSearch="true"
      :showFilter="true"
      :filterCount="activeFilterCount"
      :showColumns="true"
      :columns="tableColumns"
      :show-view-action="false"
      @toggleColumn="handleToggleColumn"
      @resetFilter="handleResetFilter"
    >
      <!-- Standard Filter Popover Panel -->
      <template #filter>
        <div class="encashment-filters-row">
          <div class="filter-item">
            <FormSelect
              v-model="filterStatus"
              label="Status:"
              :options="[
                { value: 'All', label: 'All Statuses' },
                { value: 'pending', label: 'Pending' },
                { value: 'approved', label: 'Approved' },
                { value: 'draft', label: 'Draft' },
                { value: 'rejected', label: 'Rejected' }
              ]"
              placeholder="Select Status"
            />
          </div>

          <div class="filter-item">
            <FormSelect
              v-model="filterState"
              label="State:"
              :options="[
                { value: 'All', label: 'All States' },
                { value: 'active', label: 'Active' },
                { value: 'inactive', label: 'Inactive' }
              ]"
              placeholder="Select State"
            />
          </div>
        </div>
      </template>

      <!-- Primary Action in Top Right Slot (Rule 10 & Rule 6) -->
      <template #actions>
        <AppButton variant="primary" size="sm" @click="openCreateModal">
  <template #icon-left><Plus :size="15" /></template>
  Request Encashment
</AppButton>
      </template>

      <!-- Table Content -->
      <template #default>
        <div class="table-container">
          <table class="erp-table">
            <thead>
              <tr>
                <!-- Selection Checkbox -->
                <th class="th-checkbox">
                  <input
                    type="checkbox"
                    class="table-checkbox"
                    :checked="isAllSelected"
                    @change="toggleSelectAll"
                  />
                </th>

                <!-- Columns -->
                <th v-if="tableColumns[0]?.visible" class="th-name">Name</th>
                <th v-if="tableColumns[1]?.visible">Leave Type</th>
                <th v-if="tableColumns[2]?.visible">Quota Bucket</th>
                <th v-if="tableColumns[3]?.visible">Days Encashed</th>
                <th v-if="tableColumns[4]?.visible">Daily Rate</th>
                <th v-if="tableColumns[5]?.visible">Gross Payout</th>
                <th v-if="tableColumns[6]?.visible">Payroll Settlement</th>
                <th v-if="tableColumns[7]?.visible">Status</th>
                <th v-if="tableColumns[8]?.visible">State</th>
                <th v-if="tableColumns[9]?.visible" class="th-actions">Actions</th>
              </tr>
            </thead>

            <tbody>
              <tr 
                v-for="item in filteredEncashments" 
                :key="item.id"
                class="erp-table-row"
                :class="{ 'row-selected': selectedIds.includes(item.id) }"
                @click="goToDetail(item.id)"
              >
                <!-- Selection Checkbox -->
                <td class="td-checkbox" @click.stop>
                  <input
                    type="checkbox"
                    class="table-checkbox"
                    :checked="selectedIds.includes(item.id)"
                    @change="toggleSelectRow(item.id)"
                  />
                </td>

                <!-- Rule 4: Name Column First with Code as Sub-text -->
                <td v-if="tableColumns[0]?.visible" class="td-identity">
                  <div class="identity-cell">
                    <img :src="item.employee_avatar" :alt="item.employee_name" class="table-avatar" />
                    <div class="identity-info">
                      <span class="table-name-primary">{{ item.employee_name }}</span>
                      <span class="table-code-subtext">{{ item.code }}</span>
                    </div>
                  </div>
                </td>

                <!-- Leave Type: Plain text in #737373 (Rule 5 & 6) -->
                <td v-if="tableColumns[1]?.visible" class="td-tertiary">
                  {{ item.leave_type_name }}
                </td>

                <!-- Quota Bucket: Plain text in #737373 -->
                <td v-if="tableColumns[2]?.visible" class="td-tertiary">
                  {{ item.allocation_code }}
                </td>

                <!-- Days Encashed: Plain text in #737373 -->
                <td v-if="tableColumns[3]?.visible" class="td-tertiary">
                  {{ (item.approved_days ?? item.requested_days).toFixed(1) }} d
                </td>

                <!-- Daily Rate: Plain text in #737373 -->
                <td v-if="tableColumns[4]?.visible" class="td-tertiary">
                  ETB {{ formatCurrency(item.daily_rate) }} / d
                </td>

                <!-- Gross Payout: Semi-bold in #404040 -->
                <td v-if="tableColumns[5]?.visible" class="td-amount-bold">
                  ETB {{ formatCurrency(item.amount) }}
                </td>

                <!-- Payroll Settlement: Plain text in #737373 -->
                <td v-if="tableColumns[6]?.visible" class="td-tertiary">
                  <div class="payroll-cell">
                    <span>{{ item.payroll_settlement_month }}</span>
                    <span v-if="item.is_synced_to_payroll" class="sync-dot" title="Synced to payroll input"></span>
                  </div>
                </td>

                <!-- Status Pill (Rule 9: Lifecycle State) -->
                <td v-if="tableColumns[7]?.visible">
                  <span class="status-pill" :class="`status-${item.request_state}`">
                    {{ item.request_state.charAt(0).toUpperCase() + item.request_state.slice(1) }}
                  </span>
                </td>

                <!-- State Column (Rule 9: Active / Inactive solely on State) -->
                <td v-if="tableColumns[8]?.visible">
                  <span class="state-pill" :class="`state-${item.state}`">
                    {{ item.state.charAt(0).toUpperCase() + item.state.slice(1) }}
                  </span>
                </td>

                <!-- Actions: ⋮ 3-dots button (Rule 8) -->
                <td v-if="tableColumns[9]?.visible" class="td-actions" @click.stop>
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
                        <button type="button" class="action-item" @click="goToDetail(item.id)">
                          <Eye :size="13" />
                          <span>View Encashment Details</span>
                        </button>

                        <template v-if="item.request_state === 'pending'">
                          <button type="button" class="action-item text-green" @click="handleApprove(item)">
                            <Check :size="13" />
                            <span>Approve Encashment</span>
                          </button>
                          <button type="button" class="action-item text-red" @click="handleReject(item)">
                            <X :size="13" />
                            <span>Reject Request</span>
                          </button>
                        </template>
                      </div>
                    </Transition>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>
    </AppDataTable>

    <!-- Floating Batch Action Bar (Rule 11) -->
    <TableFloatingBar
      :count="selectedIds.length"
      @delete="handleBatchDelete"
    />

    <!-- ─── QUICK CREATE MODAL (Rule 4: <= 5 Required Fields Standard) ─── -->
    <QuickCreateModal
      :show="isCreateModalOpen"
      title="Create Leave Encashment"
      save-label="Save"
      width="lg"
      :show-expand-button="true"
      @update:show="isCreateModalOpen = $event"
      @cancel="closeCreateModal"
      @save="handleSubmitQuickCreate"
      @expand="handleExpandToFull"
    >
      <div class="quick-form-body">
        <!-- Staff Picker -->
        <div class="form-group">
          <label class="form-label">Employee</label>
          <FormSelect
            v-model="quickForm.employee_id"
            :options="staffSelectOptions"
            placeholder="Select"
          />
        </div>

        <!-- Staff Dossier Banner -->
        <div class="quick-staff-banner">
          <img :src="selectedQuickStaff.avatar" :alt="selectedQuickStaff.name" class="quick-avatar" />
          <div class="quick-staff-info">
            <span class="quick-staff-name">{{ selectedQuickStaff.name }}</span>
            <span class="quick-staff-role">{{ selectedQuickStaff.position }} &bull; {{ selectedQuickStaff.code }}</span>
            <span class="quick-staff-quota">Available: <strong>{{ selectedQuickStaff.available_days }} Days</strong></span>
          </div>
        </div>

        <!-- Units & Rate Grid -->
        <div class="form-row-2">
          <div class="form-group">
            <label class="form-label">Requested Days to Encash</label>
            <FormInput
              v-model="quickForm.requested_days"
              type="number"
              min="0.5"
              :max="selectedQuickStaff.available_days"
              step="0.5"
            />
          </div>

          <div class="form-group">
            <label class="form-label">Estimated Gross Payout</label>
            <div class="quick-payout-box">
              <span class="m-val-bold">ETB {{ formatCurrency(quickGrossAmount) }}</span>
            </div>
          </div>
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.leave-encashments-page {
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  position: relative;
}

.breadcrumb-bar {
  margin-bottom: 2px;
}

/* Toast */
.toast-bar {
  position: fixed;
  top: 24px;
  right: 28px;
  background-color: #047857;
  color: #ffffff;
  padding: 10px 18px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 8px;
  box-shadow: 0 4px 14px rgba(4, 120, 87, 0.25);
  z-index: 9999;
}
.toast-fade-enter-active, .toast-fade-leave-active { transition: opacity 0.25s, transform 0.25s; }
.toast-fade-enter-from, .toast-fade-leave-to { opacity: 0; transform: translateY(-8px); }

/* Metrics Grid (Rule 2) */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
}
/* Filter Popover Panel Styles */
.encashment-filters-row {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 12px 16px;
  background-color: #fafbfc;
  border-bottom: 1px solid #f1f5f9;
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
  white-space: nowrap;
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
  cursor: pointer;
}
.filter-select:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.08);
}

/* Primary Button (Rule 6: 8px radius, NOT pill) */
.btn-create-encashment-primary {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 38px;
  padding: 0 16px;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 13.5px;
  font-weight: 500;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-create-encashment-primary:hover {
  background-color: #083c72;
}

/* Table Architecture (Rule 8 & 9) */
.table-container {
  overflow-x: auto;
  border-radius: 8px;
}
.erp-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}
.erp-table thead tr {
  background-color: #fafafa;
  border-bottom: 1px solid #f1f5f9;
}
.erp-table th {
  height: 34px;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  white-space: nowrap;
}
.th-checkbox { width: 40px; padding: 0 12px !important; }
.th-name { min-width: 200px; }
.th-actions { width: 50px; text-align: right; }

.erp-table tbody tr {
  height: 38px;
  border-bottom: 1px solid #f1f5f9;
  transition: background-color 0.12s ease;
  cursor: pointer;
}
.erp-table tbody tr:hover {
  background-color: #f8fafc;
}
.row-selected {
  background-color: #f0f7ff !important;
}

.erp-table td {
  padding: 8px 16px;
  font-size: 13px;
  color: #404040;
  white-space: nowrap;
}

.td-checkbox {
  padding: 0 12px !important;
}
.table-checkbox {
  width: 15px;
  height: 15px;
  cursor: pointer;
  accent-color: #0B529C;
}

/* Identity Cell */
.identity-cell {
  display: flex;
  align-items: center;
  gap: 12px;
}
.table-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  object-fit: cover;
  border: 1px solid #e2e8f0;
}
.identity-info {
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.table-name-primary {
  font-weight: 500;
  color: #404040;
}
.table-code-subtext {
  font-size: 11px;
  color: #737373;
  font-family: monospace;
}

/* Text Hierarchy */
.td-tertiary {
  color: #737373 !important;
}
.td-amount-bold {
  font-weight: 600;
  color: #404040;
}

/* Payroll cell */
.payroll-cell {
  display: flex;
  align-items: center;
  gap: 6px;
}
.sync-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background-color: #059669;
}

/* Status Pills (Rule 9) */
.status-pill {
  display: inline-block;
  padding: 2px 10px;
  font-size: 11.5px;
  font-weight: 500;
  border-radius: 9999px;
  text-transform: capitalize;
}
.status-approved { background-color: #ecfdf5; color: #059669; }
.status-pending { background-color: #fffbeb; color: #b45309; }
.status-draft { background-color: #f1f5f9; color: #475569; }
.status-rejected { background-color: #fef2f2; color: #dc2626; }
.status-cancelled { background-color: #f1f5f9; color: #94a3b8; }

/* State Pill */
.state-pill {
  display: inline-block;
  padding: 2px 10px;
  font-size: 11.5px;
  font-weight: 500;
  border-radius: 9999px;
}
.state-active { background-color: #ecfdf5; color: #059669; }
.state-inactive { background-color: #f1f5f9; color: #64748b; }

/* Action Buttons */
.btn-action-dots {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  color: #737373;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-action-dots:hover {
  background-color: #f8fafc;
  color: #404040;
}

.action-menu-wrapper {
  position: relative;
  display: inline-block;
}

.action-dropdown-popup {
  position: absolute;
  top: 100%;
  right: 0;
  margin-top: 4px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
  min-width: 180px;
  z-index: 50;
  padding: 4px;
}

.action-item {
  width: 100%;
  height: 32px;
  padding: 0 10px;
  font-size: 12.5px;
  color: #404040;
  background: transparent;
  border: none;
  border-radius: 6px;
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  text-align: left;
}
.action-item:hover {
  background-color: #f8fafc;
}
.action-item.text-green { color: #059669; }
.action-item.text-green:hover { background-color: #ecfdf5; }
.action-item.text-red { color: #dc2626; }
.action-item.text-red:hover { background-color: #fef2f2; }

/* Quick Create Modal Form Body */
.quick-form-body {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.form-row-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.quick-staff-banner {
  display: flex;
  align-items: center;
  gap: 12px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 14px;
}
.quick-avatar {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  object-fit: cover;
}
.quick-staff-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.quick-staff-name {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}
.quick-staff-role {
  font-size: 11.5px;
  color: #737373;
}
.quick-staff-quota {
  font-size: 11px;
  color: #0B529C;
}

.quick-payout-box {
  height: 38px;
  padding: 0 12px;
  border-radius: 8px;
  background-color: #eff6ff;
  border: 1px solid #dbeafe;
  display: flex;
  align-items: center;
}
.m-val-bold {
  font-size: 14px;
  font-weight: 600;
  color: #0B529C;
}

/* Transitions */
.dropdown-fade-enter-active, .dropdown-fade-leave-active { transition: opacity 0.15s ease, transform 0.15s ease; }
.dropdown-fade-enter-from, .dropdown-fade-leave-to { opacity: 0; transform: translateY(-4px); }
</style>
