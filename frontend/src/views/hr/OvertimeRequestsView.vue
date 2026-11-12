<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, CheckCircle2, XCircle, Search,
  Eye, X
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import MetricCard from '../../components/MetricCard.vue';
import UnderlineTabs, { type UnderlineTabItem } from '../../components/UnderlineTabs.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import { 
  overtimeRequestsData, 
  OVERTIME_TYPE_MAP, 
  updateOvertimeStatus,
  type OvertimeRequestRecord, 
  type OvertimeRequestState,
  type OvertimeCompensation
} from './overtimeData';

const router = useRouter();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3) ───
// Exact Sidebar Page Name Only: [Monitor] > Overtime Requests
const breadcrumbItems = [
  { label: 'Overtime Requests' }
];

// ─── Active Tab Filter (UnderlineTabs Standard AGENTS.md Rule 1) ───
type TabKey = 'all' | 'pending' | 'approved' | 'compensatory' | 'rejected';
const activeTab = ref<TabKey>('all');

const searchQuery = ref('');
const selectedTypeFilter = ref<string>('all');
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Metric Cards Computed (AGENTS.md Rule 2) ───
const metrics = computed(() => {
  const pending = overtimeRequestsData.value.filter(r => r.request_state === 'pending').length;
  const approved = overtimeRequestsData.value.filter(r => r.request_state === 'approved').length;
  const compRest = overtimeRequestsData.value.filter(r => r.compensation === 'compensatory_leave' && r.request_state === 'approved').length;
  const totalApprovedMinutes = overtimeRequestsData.value
    .filter(r => r.request_state === 'approved')
    .reduce((sum, r) => sum + (r.approved_minutes || 0), 0);
  const totalHours = (totalApprovedMinutes / 60).toFixed(1);

  return {
    pending,
    approved,
    compRest,
    totalHours
  };
});

// ─── Tabs Configuration ───
const underlineTabs = computed<UnderlineTabItem<TabKey>[]>(() => [
  { id: 'all', label: 'All Requests', count: overtimeRequestsData.value.length },
  { id: 'pending', label: 'Pending Approval', count: overtimeRequestsData.value.filter(r => r.request_state === 'pending').length, badgeVariant: 'warning' },
  { id: 'approved', label: 'Approved (Payroll Ready)', count: overtimeRequestsData.value.filter(r => r.request_state === 'approved').length, badgeVariant: 'success' },
  { id: 'compensatory', label: 'Compensatory Rest Credits', count: overtimeRequestsData.value.filter(r => r.compensation === 'compensatory_leave').length },
  { id: 'rejected', label: 'Rejected / Cancelled', count: overtimeRequestsData.value.filter(r => r.request_state === 'rejected' || r.request_state === 'cancelled').length }
]);

// ─── Filtered Dataset ───
const filteredRequests = computed(() => {
  return overtimeRequestsData.value.filter(r => {
    // Tab filter
    if (activeTab.value === 'pending' && r.request_state !== 'pending') return false;
    if (activeTab.value === 'approved' && r.request_state !== 'approved') return false;
    if (activeTab.value === 'compensatory' && r.compensation !== 'compensatory_leave') return false;
    if (activeTab.value === 'rejected' && r.request_state !== 'rejected' && r.request_state !== 'cancelled') return false;

    // Type filter
    if (selectedTypeFilter.value !== 'all' && r.overtime_type !== selectedTypeFilter.value) return false;

    // Search query
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase();
      const matchName = r.employee_name.toLowerCase().includes(q);
      const matchCode = r.code.toLowerCase().includes(q);
      const matchRole = r.employee_role.toLowerCase().includes(q);
      if (!matchName && !matchCode && !matchRole) return false;
    }

    return true;
  });
});

// ─── Table Columns (AGENTS.md Rule 9: Atomic Columns) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'employee', label: 'Employee', visible: true },
  { key: 'date', label: 'Work Date', visible: true },
  { key: 'overtime_type', label: 'Overtime Type', visible: true },
  { key: 'requested_hours', label: 'Requested Time', visible: true },
  { key: 'approved_hours', label: 'Approved Time', visible: true },
  { key: 'compensation', label: 'Compensation', visible: true },
  { key: 'status', label: 'Approval Status', visible: true },
  { key: 'attendance_day', label: 'Attendance Day', visible: false },
  { key: 'location', label: 'Facility', visible: false },
  { key: 'state', label: 'State', visible: false },
  { key: 'actions', label: 'Actions', visible: true }
]);

const handleToggleColumn = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  if (col) col.visible = !col.visible;
};

// ─── Selection State ───
const selectedRowIds = ref<number[]>([]);
const isAllSelected = computed(() => {
  return filteredRequests.value.length > 0 && selectedRowIds.value.length === filteredRequests.value.length;
});

const handleToggleSelectAll = (checked: boolean) => {
  if (checked) {
    selectedRowIds.value = filteredRequests.value.map(r => r.id);
  } else {
    selectedRowIds.value = [];
  }
};

const handleToggleRow = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx > -1) selectedRowIds.value.splice(idx, 1);
  else selectedRowIds.value.push(id);
};

// ─── Inspection & Approval Modal ───
const inspectingRequest = ref<OvertimeRequestRecord | null>(null);
const approvalForm = ref({
  approved_minutes: 0,
  compensation: 'paid' as OvertimeCompensation
});

const openInspectionModal = (req: OvertimeRequestRecord) => {
  inspectingRequest.value = req;
  approvalForm.value = {
    approved_minutes: req.approved_minutes ?? req.requested_minutes,
    compensation: req.compensation
  };
};

const handleApprove = () => {
  if (!inspectingRequest.value) return;
  updateOvertimeStatus(
    inspectingRequest.value.id,
    'approved',
    approvalForm.value.approved_minutes,
    approvalForm.value.compensation
  );
  showToast(`Overtime request ${inspectingRequest.value.code} approved (${(approvalForm.value.approved_minutes / 60).toFixed(1)}h).`);
  inspectingRequest.value = null;
};

const handleReject = () => {
  if (!inspectingRequest.value) return;
  updateOvertimeStatus(inspectingRequest.value.id, 'rejected');
  showToast(`Overtime request ${inspectingRequest.value.code} rejected.`);
  inspectingRequest.value = null;
};

const formatMinutesToHours = (minutes: number | null | undefined): string => {
  if (minutes === null || minutes === undefined) return '—';
  const hrs = Math.floor(minutes / 60);
  const mins = minutes % 60;
  if (mins === 0) return `${hrs}h 00m`;
  return `${hrs}h ${mins}m`;
};
</script>

<template>
  <div class="overtime-page">
    <!-- Breadcrumb Standard -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Toast Notification -->
    <transition name="toast-fade">
      <div v-if="toastMessage" class="toast-box">
        <CheckCircle2 :size="16" class="toast-icon" />
        <span>{{ toastMessage }}</span>
      </div>
    </transition>

    <!-- KPI / Metric Cards (AGENTS.md Rule 2 Standard) -->
    <div class="metrics-grid">
      <MetricCard
        label="Pending OT Approvals"
        :value="String(metrics.pending)"
        subtext="Requires supervisory authorization"
      />
      <MetricCard
        label="Approved OT Requests"
        :value="String(metrics.approved)"
        subtext="Processed for current payroll run"
      />
      <MetricCard
        label="Total Approved OT Hours"
        :value="`${metrics.totalHours} hrs`"
        subtext="Net extra duty hours"
      />
      <MetricCard
        label="Compensatory Rest Credits"
        :value="String(metrics.compRest)"
        subtext="Credited to leave balances"
      />
    </div>

    <!-- Sub-Section Tabs (AGENTS.md Rule 1: UnderlineTabs Standard) -->
    <div class="tabs-header-wrap">
      <UnderlineTabs
        v-model="activeTab"
        :tabs="underlineTabs"
      />
    </div>

    <!-- Unified Table Card (AGENTS.md Rule 10 Standard) -->
    <AppDataTable
      title="Overtime Authorizations"
      subtitle="Manage extra-hours duty requests, statutory Ethiopian rate multipliers (1.25×–2.5×), and compensatory rest credits."
      :columns="tableColumns"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Action Toolbar (Rule 10: Primary Action in #actions Slot) -->
      <template #actions>
        <AppButton variant="primary" size="sm" @click="router.push('/hr/overtime-requests/create')">
          <template #icon-left><Plus :size="15" /></template>
          Log Overtime Request
        </AppButton>
      </template>

      <!-- Custom Filter Controls -->
      <template #custom-filters>
        <div class="filter-controls-row">
          <!-- Search input -->
          <div class="search-input-wrap">
            <Search :size="14" class="search-icon" />
            <input
              type="text"
              v-model="searchQuery"
              class="table-search-input"
            />
          </div>

          <!-- Type filter dropdown -->
          <div class="filter-select-wrap">
            <select v-model="selectedTypeFilter" class="filter-select">
              <option value="all">All Overtime Types</option>
              <option value="normal_day">Normal Working Day (1.25×)</option>
              <option value="night">Night Shift Work (1.50×)</option>
              <option value="weekend">Weekly Rest / Weekend (2.00×)</option>
              <option value="public_holiday">Statutory Public Holiday (2.50×)</option>
            </select>
          </div>
        </div>
      </template>

      <!-- Table Body -->
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
              <th v-if="tableColumns.find(c => c.key === 'employee')?.visible">Employee</th>
              <th v-if="tableColumns.find(c => c.key === 'date')?.visible">Work Date</th>
              <th v-if="tableColumns.find(c => c.key === 'overtime_type')?.visible">Overtime Type</th>
              <th v-if="tableColumns.find(c => c.key === 'requested_hours')?.visible">Requested Time</th>
              <th v-if="tableColumns.find(c => c.key === 'approved_hours')?.visible">Approved Time</th>
              <th v-if="tableColumns.find(c => c.key === 'compensation')?.visible">Compensation</th>
              <th v-if="tableColumns.find(c => c.key === 'status')?.visible">Approval Status</th>
              <th v-if="tableColumns.find(c => c.key === 'attendance_day')?.visible">Attendance Day</th>
              <th v-if="tableColumns.find(c => c.key === 'location')?.visible">Facility</th>
              <th v-if="tableColumns.find(c => c.key === 'state')?.visible">State</th>
              <th v-if="tableColumns.find(c => c.key === 'actions')?.visible" class="th-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <!-- Empty State -->
            <tr v-if="filteredRequests.length === 0">
              <td colspan="11" class="td-empty-state">
                No overtime requests found for this filter view.
              </td>
            </tr>

            <!-- Data Rows (AGENTS.md Rule 9 Standard) -->
            <tr
              v-for="item in filteredRequests"
              :key="item.id"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
              @click="openInspectionModal(item)"
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

              <!-- Name & Code Column (Rule 4 & 9: Secondary Color for Name, Code underneath) -->
              <td v-if="tableColumns.find(c => c.key === 'employee')?.visible">
                <div class="identity-cell">
                  <div class="avatar-squircle">
                    {{ item.employee_name.split(' ').map(n => n[0]).join('') }}
                  </div>
                  <div class="identity-info">
                    <span class="table-name-primary">{{ item.employee_name }}</span>
                    <span class="table-code-subtext">{{ item.code }} &bull; {{ item.employee_role }}</span>
                  </div>
                </div>
              </td>

              <!-- Date (Rule 5 & 9: Tertiary Color #737373) -->
              <td v-if="tableColumns.find(c => c.key === 'date')?.visible" class="td-tertiary">
                {{ item.date }}
              </td>

              <!-- Overtime Type (Plain text with multiplier, Rule 6 anti-badge) -->
              <td v-if="tableColumns.find(c => c.key === 'overtime_type')?.visible" class="td-tertiary">
                <span class="type-title">{{ OVERTIME_TYPE_MAP[item.overtime_type]?.label }}</span>
              </td>

              <!-- Requested Hours (Tertiary text) -->
              <td v-if="tableColumns.find(c => c.key === 'requested_hours')?.visible" class="td-tertiary font-mono">
                {{ formatMinutesToHours(item.requested_minutes) }}
              </td>

              <!-- Approved Hours (Tertiary text) -->
              <td v-if="tableColumns.find(c => c.key === 'approved_hours')?.visible" class="td-tertiary font-mono">
                {{ formatMinutesToHours(item.approved_minutes) }}
              </td>

              <!-- Compensation Mode (Rule 6: Plain text) -->
              <td v-if="tableColumns.find(c => c.key === 'compensation')?.visible" class="td-tertiary">
                <span v-if="item.compensation === 'paid'" class="comp-text">
                  Monetary Payout (100% Rate)
                </span>
                <span v-else class="comp-text">
                  Compensatory Leave
                </span>
              </td>

              <!-- Status (Rule 9: Badges strictly for lifecycle state) -->
              <td v-if="tableColumns.find(c => c.key === 'status')?.visible">
                <span class="status-pill" :class="`status-${item.request_state}`">
                  {{ item.request_state.toUpperCase() }}
                </span>
              </td>

              <!-- Attendance Day (FK AttendanceDay nullable, Schema line 1961) -->
              <td v-if="tableColumns.find(c => c.key === 'attendance_day')?.visible" class="td-tertiary">
                {{ item.attendance_day_id ? `#${item.attendance_day_id}` : '—' }}
              </td>

              <!-- Location (Optional Hidden by Default) -->
              <td v-if="tableColumns.find(c => c.key === 'location')?.visible" class="td-tertiary">
                {{ item.entity_name }}
              </td>

              <!-- State (Rule 9: Active / Inactive reserved for State) -->
              <td v-if="tableColumns.find(c => c.key === 'state')?.visible">
                <span class="status-pill" :class="item.state === 'active' ? 'status-active' : 'status-inactive'">
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </span>
              </td>

              <!-- Action Menu (Rule 8: 28x28 Action Button) -->
              <td v-if="tableColumns.find(c => c.key === 'actions')?.visible" class="td-actions" @click.stop>
                <button
                  type="button"
                  class="btn-action-dots"
                  title="Inspect & Review Overtime"
                  @click="openInspectionModal(item)"
                >
                  <Eye :size="14" />
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </template>
    </AppDataTable>

    <!-- ═══ Overtime Inspection & Approval Modal ═══ -->
    <div v-if="inspectingRequest" class="modal-backdrop" @click="inspectingRequest = null">
      <div class="details-modal-box" @click.stop>
        <div class="modal-header">
          <span class="modal-title">Overtime Request Authorization &bull; {{ inspectingRequest.code }}</span>
          <button type="button" class="btn-close-modal" @click="inspectingRequest = null">
            <X :size="16" />
          </button>
        </div>

        <div class="modal-content-grid">
          <div class="info-group">
            <span class="info-label">Employee</span>
            <span class="info-val-bold">{{ inspectingRequest.employee_name }}</span>
            <span class="info-sub">{{ inspectingRequest.employee_code }} &bull; {{ inspectingRequest.employee_role }}</span>
          </div>

          <div class="info-group">
            <span class="info-label">Work Date &amp; Overtime Type</span>
            <span class="info-val">{{ inspectingRequest.date }}</span>
            <span class="info-sub">{{ OVERTIME_TYPE_MAP[inspectingRequest.overtime_type]?.label }}</span>
          </div>

          <div class="info-group">
            <span class="info-label">Evidence Attendance Day</span>
            <span class="info-val">
              {{ inspectingRequest.attendance_day_id ? `Attendance Day #${inspectingRequest.attendance_day_id}` : 'None (Pre-approved / Advance)' }}
            </span>
            <span class="info-sub">{{ inspectingRequest.attendance_day_id ? 'Linked to validated daily punch log' : 'Pre-approved extra duty hours' }}</span>
          </div>

          <div class="info-group">
            <span class="info-label">Statutory Multiplier</span>
            <span class="info-val font-bold text-blue-700">
              {{ OVERTIME_TYPE_MAP[inspectingRequest.overtime_type]?.multiplier }}× Base Hourly Rate
            </span>
            <span class="info-sub">Ethiopian Labour Proclamation statutory schedule</span>
          </div>

          <div class="info-group">
            <span class="info-label">Current Approval Lifecycle</span>
            <span class="status-pill mt-1" :class="`status-${inspectingRequest.request_state}`">
              {{ inspectingRequest.request_state.toUpperCase() }}
            </span>
          </div>

          <div class="info-group">
            <span class="info-label">Compensation Method</span>
            <span class="info-val">
              {{ inspectingRequest.compensation === 'paid' ? 'Monetary Payout' : 'Compensatory Leave' }}
            </span>
            <span class="info-sub">
              {{ inspectingRequest.compensation === 'paid' ? 'Disbursed via PayrollInput' : 'Credits LeaveTransaction balance' }}
            </span>
          </div>

          <div class="info-group" v-if="inspectingRequest.approver_name">
            <span class="info-label">Authorized / Reviewed By</span>
            <span class="info-val">{{ inspectingRequest.approver_name }}</span>
            <span class="info-sub" v-if="inspectingRequest.approved_at">{{ inspectingRequest.approved_at.slice(0, 10) }}</span>
          </div>

          <div class="info-group full-width">
            <span class="info-label">Operational Reason</span>
            <p class="info-justification">{{ inspectingRequest.reason || 'No justification entered.' }}</p>
          </div>

          <!-- Review & Modification Controls (If Pending or Draft) -->
          <div v-if="inspectingRequest.request_state === 'pending' || inspectingRequest.request_state === 'draft'" class="review-box full-width">
            <h4 class="review-box-title">Supervisor Authorization Adjustments</h4>
            <div class="review-grid">
              <div class="form-group">
                <label class="form-label">Authorized Overtime (Minutes)</label>
                <input
                  type="number"
                  step="15"
                  v-model.number="approvalForm.approved_minutes"
                  class="modal-input"
                  min="0"
                  :max="inspectingRequest.requested_minutes"
                />
                <span class="input-hint">Approver may trim minutes (Requested: {{ inspectingRequest.requested_minutes }} mins / {{ (inspectingRequest.requested_minutes / 60).toFixed(1) }}h)</span>
              </div>

              <div class="form-group">
                <label class="form-label">Compensation Method</label>
                <select v-model="approvalForm.compensation" class="modal-select">
                  <option value="paid">Monetary Payout (Transferred to PayrollInput)</option>
                  <option value="compensatory_leave">Compensatory Rest (Credits LeaveTransaction)</option>
                </select>
                <span class="input-hint">Choose monetary payroll bonus or additional compensatory rest day</span>
              </div>
            </div>
          </div>
        </div>

        <div class="modal-footer-row">
          <AppButton variant="outline" size="sm" @click="inspectingRequest = null">
            Cancel
          </AppButton>

          <template v-if="inspectingRequest.request_state === 'pending' || inspectingRequest.request_state === 'draft'">
            <AppButton variant="destructive" size="sm" @click="handleReject">
              <template #icon-left><XCircle :size="14" /></template>
              <span>Reject Request</span>
            </AppButton>
            <AppButton variant="primary" size="sm" @click="handleApprove">
              <template #icon-left><CheckCircle2 :size="14" /></template>
              <span>Approve Overtime</span>
            </AppButton>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.overtime-page {
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

/* Toast */
.toast-box {
  position: fixed;
  top: 20px;
  right: 24px;
  z-index: 9999;
  display: flex;
  align-items: center;
  gap: 10px;
  background: #0f172a;
  color: #ffffff;
  padding: 10px 18px;
  border-radius: 8px;
  font-size: 13.5px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.2);
}

.toast-icon {
  color: #10b981;
}

.toast-fade-enter-active, .toast-fade-leave-active {
  transition: all 0.2s ease;
}
.toast-fade-enter-from, .toast-fade-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

/* Metrics Grid (Rule 2 Standard) */
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

/* Sub-Section Tabs Header */
.tabs-header-wrap {
  margin-top: 4px;
  margin-bottom: -4px;
}

/* Buttons */
.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  background-color: var(--alias-color-brand-primary, #0B529C);
  color: #ffffff;
  padding: 0 16px;
  height: 38px;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  border: none;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-primary-action:hover {
  background-color: #09427d;
}

/* Filter Controls Row */
.filter-controls-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.search-input-wrap {
  position: relative;
  width: 260px;
}

.search-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: #94a3b8;
}

.table-search-input {
  width: 100%;
  height: 38px;
  padding: 0 12px 0 32px;
  font-size: 13.5px;
  color: #404040;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  outline: none;
  transition: all 0.15s ease;
}

.table-search-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.filter-select {
  height: 38px;
  padding: 0 12px;
  font-size: 13.5px;
  color: #404040;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  outline: none;
  cursor: pointer;
}

.filter-select:focus {
  border-color: #0B529C;
}

/* ERP Table Standards (Rule 8 & Rule 9) */
.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 600;
  color: #737373;
  background-color: #fafafa;
  text-align: left;
  border-bottom: 1px solid #f1f5f9;
}

.erp-table td {
  height: 44px;
  padding: 8px 16px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
}

.erp-table tr:hover {
  background-color: #f8fafc;
  cursor: pointer;
}

.th-checkbox, .td-checkbox {
  width: 44px;
  text-align: center !important;
  padding-left: 14px !important;
  padding-right: 14px !important;
}

.table-checkbox {
  width: 16px;
  height: 16px;
  accent-color: #0B529C;
  cursor: pointer;
  border-radius: 4px;
}

.identity-cell {
  display: flex;
  align-items: center;
  gap: 12px;
}

.avatar-squircle {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background-color: #e0f2fe;
  color: #0369a1;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11.5px;
  font-weight: 600;
}

.identity-info {
  display: flex;
  flex-direction: column;
}

.table-name-primary {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040; /* Rule 9 Secondary Color */
}

.table-code-subtext {
  font-size: 11.5px;
  color: #737373;
}

.td-tertiary {
  color: #737373 !important; /* Rule 9 Tertiary Color for non-name columns */
}

.type-title {
  font-weight: 500;
  color: #404040;
}

.comp-text {
  font-size: 12.5px;
  color: #737373;
}

/* Status Pills (Rule 9) */
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

.status-pending {
  background-color: #fffbeb;
  color: #b45309;
}

.status-draft {
  background-color: #f1f5f9;
  color: #64748b;
}

.status-rejected, .status-cancelled {
  background-color: #fef2f2;
  color: #dc2626;
}

.status-active {
  background-color: #ecfdf5;
  color: #059669;
}

.status-inactive {
  background-color: #f1f5f9;
  color: #64748b;
}

.th-actions, .td-actions {
  width: 50px;
  text-align: right;
}

.btn-action-dots {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
  background: #ffffff;
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
  border-color: #cbd5e1;
}

.td-empty-state {
  text-align: center;
  padding: 40px !important;
  color: #94a3b8;
  font-size: 13px;
}

/* ─── Inspection & Review Modal ─── */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(2px);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.details-modal-box {
  background: #ffffff;
  border-radius: 12px;
  width: 100%;
  max-width: 620px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  display: flex;
  flex-direction: column;
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
}

.btn-close-modal {
  background: transparent;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
}

.btn-close-modal:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.modal-content-grid {
  padding: 20px;
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
  max-height: 70vh;
  overflow-y: auto;
}

.info-group {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.info-group.full-width {
  grid-column: span 2;
}

.info-label {
  font-size: 11.5px;
  font-weight: 500;
  color: #737373;
}

.info-val-bold {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.info-val {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
}

.info-sub {
  font-size: 11.5px;
  color: #94a3b8;
}

.info-justification {
  font-size: 13px;
  color: #404040;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 12px;
  margin-top: 4px;
  line-height: 1.45;
}

.review-box {
  background: #f0f9ff;
  border: 1px solid #bae6fd;
  border-radius: 8px;
  padding: 14px 16px;
}

.review-box-title {
  font-size: 12.5px;
  font-weight: 600;
  color: #0369a1;
  margin-bottom: 12px;
}

.review-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.form-label {
  font-size: 12px;
  font-weight: 500;
  color: #404040;
}

.modal-input, .modal-select {
  height: 38px;
  padding: 0 10px;
  border-radius: 8px;
  border: 1px solid #cbd5e1;
  background: #ffffff;
  font-size: 13px;
  color: #404040;
  outline: none;
}

.modal-input:focus, .modal-select:focus {
  border-color: #0B529C;
}

.input-hint {
  font-size: 11px;
  color: #64748b;
  line-height: 1.35;
}

.modal-footer-row {
  padding: 14px 20px;
  border-top: 1px solid #f1f5f9;
  background: #fafafa;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
}

.btn-modal-dismiss {
  height: 38px;
  padding: 0 16px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  background: #ffffff;
  color: #404040;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-reject {
  height: 38px;
  padding: 0 16px;
  border-radius: 8px;
  border: 1px solid #fecaca;
  background: #fef2f2;
  color: #dc2626;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.btn-reject:hover {
  background: #fee2e2;
}

.btn-approve {
  height: 38px;
  padding: 0 18px;
  border-radius: 8px;
  border: none;
  background: #0B529C;
  color: #ffffff;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.btn-approve:hover {
  background: #09427d;
}
</style>
