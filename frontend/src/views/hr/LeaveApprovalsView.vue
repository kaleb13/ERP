<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { 
  CheckCircle2, XCircle, Clock, ShieldCheck, 
  Check, X, User, Calendar, CalendarDays, AlertCircle,
  FileText, UserCheck, ChevronRight, Eye, MoreVertical
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import UnderlineTabs, { type UnderlineTabItem } from '../../components/UnderlineTabs.vue';
import MetricCard from '../../components/MetricCard.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import FormInput from '../../components/FormInput.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';

const router = useRouter();

// ─── Breadcrumbs (Rule 3: Exact Sidebar Page Name, ZERO section headers) ───
const breadcrumbItems = [
  { label: 'Leave Approvals' }
];

// ─── Tab Sub-views (Rule 1: UnderlineTabs for Sub-views) ───
type ApprovalTabKey = 'pending_my_action' | 'all_pending' | 'approved' | 'rejected';
const activeTab = ref<ApprovalTabKey>('pending_my_action');

// ─── Schema-Aligned Datasets (HR_Schema_final-v4.sql lines 1688–1740) ───
export interface LeaveApprovalItem {
  id: number;
  code: string;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_avatar: string;
  employee_position: string;
  leave_type_code: string;
  leave_type_name: string;
  start_date: string;
  end_date: string;
  requested_days: number;
  approved_days: number | null;
  is_half_day: boolean;
  day_portion?: string;
  handover_employee_name: string;
  reason: string;
  current_step_name: string;
  current_approver_name: string;
  request_state: 'pending' | 'approved' | 'rejected';
  is_my_pending_action: boolean;
  available_balance: number;
  submitted_at: string;
}

const approvalQueue = ref<LeaveApprovalItem[]>([
  {
    id: 732,
    code: 'LVR-2026-0732',
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-014',
    employee_avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    employee_position: 'Senior Cashier • Bole Commercial',
    leave_type_code: 'ANNUAL',
    leave_type_name: 'Annual Leave',
    start_date: '2026-08-10',
    end_date: '2026-08-11',
    requested_days: 2.0,
    approved_days: null,
    is_half_day: false,
    handover_employee_name: 'Sara Tefera',
    reason: 'Personal family matters in Debre Zeit. Cash drawer daily registers fully reconciled.',
    current_step_name: 'Department Head Authorization',
    current_approver_name: 'Marta Tadesse',
    request_state: 'pending',
    is_my_pending_action: true,
    available_balance: 16.0,
    submitted_at: '2026-08-01'
  },
  {
    id: 735,
    code: 'LVR-2026-0735',
    employee_id: 22,
    employee_name: 'Tigist Assefa',
    employee_code: 'EMP-022',
    employee_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    employee_position: 'Inventory Specialist • Modjo Dry Port',
    leave_type_code: 'ANNUAL',
    leave_type_name: 'Annual Leave',
    start_date: '2026-09-14',
    end_date: '2026-09-14',
    requested_days: 0.5,
    approved_days: null,
    is_half_day: true,
    day_portion: 'First Half (Morning)',
    handover_employee_name: 'Dawit Yohannes',
    reason: 'Morning medical consultation. Returning for afternoon shift at 13:30.',
    current_step_name: 'Shift Supervisor Endorsement',
    current_approver_name: 'Marta Tadesse',
    request_state: 'pending',
    is_my_pending_action: true,
    available_balance: 22.0,
    submitted_at: '2026-08-03'
  },
  {
    id: 736,
    code: 'LVR-2026-0736',
    employee_id: 31,
    employee_name: 'Dawit Yohannes',
    employee_code: 'EMP-031',
    employee_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
    employee_position: 'Central Logistics Coordinator • Kality Hub',
    leave_type_code: 'SICK',
    leave_type_name: 'Sick Leave',
    start_date: '2026-08-15',
    end_date: '2026-08-17',
    requested_days: 3.0,
    approved_days: null,
    is_half_day: false,
    handover_employee_name: 'Ephrem Tadesse',
    reason: 'Outpatient medical recovery following minor procedure. Medical certificate attached.',
    current_step_name: 'HR Operations Sign-off',
    current_approver_name: 'Marta Tadesse',
    request_state: 'pending',
    is_my_pending_action: true,
    available_balance: 30.0,
    submitted_at: '2026-08-04'
  },
  {
    id: 737,
    code: 'LVR-2026-0737',
    employee_id: 18,
    employee_name: 'Kidst Tesfaye',
    employee_code: 'EMP-018',
    employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    employee_position: 'HQ Security Guard • Haleta HQ',
    leave_type_code: 'ANNUAL',
    leave_type_name: 'Annual Leave',
    start_date: '2026-08-20',
    end_date: '2026-08-25',
    requested_days: 5.0,
    approved_days: null,
    is_half_day: false,
    handover_employee_name: 'Captain Berhanu',
    reason: 'Annual vacation roster block.',
    current_step_name: 'Chief Security Officer Review',
    current_approver_name: 'Captain Berhanu',
    request_state: 'pending',
    is_my_pending_action: false,
    available_balance: 14.0,
    submitted_at: '2026-08-05'
  },
  {
    id: 731,
    code: 'LVR-2026-0731',
    employee_id: 22,
    employee_name: 'Tigist Assefa',
    employee_code: 'EMP-022',
    employee_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    employee_position: 'Inventory Specialist • Modjo Dry Port',
    leave_type_code: 'ANNUAL',
    leave_type_name: 'Annual Leave',
    start_date: '2026-07-27',
    end_date: '2026-07-31',
    requested_days: 5.0,
    approved_days: 5.0,
    is_half_day: false,
    handover_employee_name: 'Dawit Yohannes',
    reason: 'Pre-scheduled annual leave.',
    current_step_name: 'Completed / Approved',
    current_approver_name: 'Sara Tefera',
    request_state: 'approved',
    is_my_pending_action: false,
    available_balance: 22.0,
    submitted_at: '2026-07-15'
  },
  {
    id: 734,
    code: 'LVR-2026-0734',
    employee_id: 31,
    employee_name: 'Dawit Yohannes',
    employee_code: 'EMP-031',
    employee_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
    employee_position: 'Central Logistics Coordinator • Kality Hub',
    leave_type_code: 'UNPAID',
    leave_type_name: 'Unpaid Leave',
    start_date: '2026-07-21',
    end_date: '2026-07-22',
    requested_days: 2.0,
    approved_days: null,
    is_half_day: false,
    handover_employee_name: 'Ephrem Tadesse',
    reason: 'Emergency extended personal trip.',
    current_step_name: 'Rejected',
    current_approver_name: 'Ephrem Tadesse',
    request_state: 'rejected',
    is_my_pending_action: false,
    available_balance: 0,
    submitted_at: '2026-07-18'
  }
]);

// ─── Metrics (Rule 2: MetricCard standard) ───
const stats = computed(() => {
  const pendingMy = approvalQueue.value.filter(r => r.is_my_pending_action && r.request_state === 'pending').length;
  const allPending = approvalQueue.value.filter(r => r.request_state === 'pending').length;
  const approvedCount = approvalQueue.value.filter(r => r.request_state === 'approved').length;
  const total = approvalQueue.value.length;
  return {
    pendingMyAction: pendingMy,
    allPending,
    approvedMonth: approvedCount + 10,
    onLeaveToday: 5,
    total
  };
});

// ─── Sub-Tabs Definition ───
const approvalTabs = computed<UnderlineTabItem[]>(() => [
  { id: 'pending_my_action', label: 'Pending My Action', count: stats.value.pendingMyAction },
  { id: 'all_pending', label: 'All Pending', count: stats.value.allPending },
  { id: 'approved', label: 'Approved History' },
  { id: 'rejected', label: 'Rejected' }
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

const filteredRecords = computed(() => {
  return approvalQueue.value.filter(item => {
    // Tab filter
    if (activeTab.value === 'pending_my_action' && (!item.is_my_pending_action || item.request_state !== 'pending')) {
      return false;
    }
    if (activeTab.value === 'all_pending' && item.request_state !== 'pending') {
      return false;
    }
    if (activeTab.value === 'approved' && item.request_state !== 'approved') {
      return false;
    }
    if (activeTab.value === 'rejected' && item.request_state !== 'rejected') {
      return false;
    }

    // Search query
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase().trim();
      const matchName = item.employee_name.toLowerCase().includes(q);
      const matchCode = item.code.toLowerCase().includes(q);
      const matchType = item.leave_type_name.toLowerCase().includes(q);
      const matchHandover = item.handover_employee_name.toLowerCase().includes(q);
      if (!matchName && !matchCode && !matchType && !matchHandover) return false;
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

const handleToggleSelectAll = (checked: boolean) => {
  if (checked) {
    selectedRowIds.value = filteredRecords.value.map(r => r.id);
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

// ─── Table Columns Configuration (Rule 9: Atomic columns) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'employee', label: 'Employee', visible: true, sortable: true },
  { key: 'leave_type', label: 'Leave Type', visible: true, sortable: true },
  { key: 'duration', label: 'Duration', visible: true, sortable: true },
  { key: 'period', label: 'Leave Period', visible: true, sortable: true },
  { key: 'handover', label: 'Handover Cover', visible: true, sortable: true },
  { key: 'stage', label: 'Workflow Stage', visible: true, sortable: true },
  { key: 'status', label: 'Status', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

const handleToggleColumn = ({ key, visible }: { key: string; visible: boolean }) => {
  const col = tableColumns.value.find(c => c.key === key);
  if (col) col.visible = visible;
};

// ─── Decision Modal State & Handlers ───
const isDecisionModalOpen = ref(false);
const activeReviewItem = ref<LeaveApprovalItem | null>(null);
const approvalForm = ref({
  approved_days: 0,
  remarks: ''
});

const openReviewModal = (item: LeaveApprovalItem) => {
  activeReviewItem.value = item;
  approvalForm.value = {
    approved_days: item.requested_days,
    remarks: ''
  };
  activeActionMenuId.value = null;
  isDecisionModalOpen.value = true;
};

const closeReviewModal = () => {
  isDecisionModalOpen.value = false;
  activeReviewItem.value = null;
};

const handleApprove = () => {
  if (!activeReviewItem.value) return;
  activeReviewItem.value.request_state = 'approved';
  activeReviewItem.value.approved_days = Number(approvalForm.value.approved_days);
  activeReviewItem.value.is_my_pending_action = false;
  activeReviewItem.value.current_step_name = 'Fully Approved';
  showToast(`Leave request ${activeReviewItem.value.code} approved (${activeReviewItem.value.approved_days} days granted).`);
  closeReviewModal();
};

const handleReject = () => {
  if (!activeReviewItem.value) return;
  activeReviewItem.value.request_state = 'rejected';
  activeReviewItem.value.is_my_pending_action = false;
  activeReviewItem.value.current_step_name = 'Rejected';
  showToast(`Leave request ${activeReviewItem.value.code} rejected.`);
  closeReviewModal();
};

const formatDateRange = (start: string, end: string) => {
  if (start === end) return start;
  return `${start} – ${end}`;
};
</script>

<template>
  <div class="leave-approvals-page">
    <!-- Breadcrumb (Rule 3: [Monitor] > Leave Approvals strictly) -->
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

    <!-- Top KPI Metrics Cards (Rule 2) -->
    <div class="metrics-grid">
      <MetricCard
        label="Pending My Decision"
        :value="`${stats.pendingMyAction} Requests`"
        subtext="Awaiting your authorization"
        :icon="Clock"
        :show-menu="false"
        class="metric-interactive"
        :class="{ 'metric-active': activeTab === 'pending_my_action' }"
        @click="activeTab = 'pending_my_action'"
      />
      <MetricCard
        label="All Pending Queue"
        :value="`${stats.allPending} In Review`"
        subtext="Departmental review pipeline"
        :icon="ShieldCheck"
        :show-menu="false"
        class="metric-interactive"
        :class="{ 'metric-active': activeTab === 'all_pending' }"
        @click="activeTab = 'all_pending'"
      />
      <MetricCard
        label="Approved This Month"
        :value="`${stats.approvedMonth} Requests`"
        subtext="Successfully endorsed"
        :icon="CheckCircle2"
        :show-menu="false"
        class="metric-interactive"
        :class="{ 'metric-active': activeTab === 'approved' }"
        @click="activeTab = 'approved'"
      />
      <MetricCard
        label="Currently On Leave"
        :value="`${stats.onLeaveToday} Staff`"
        subtext="Active out-of-office coverage"
        :icon="UserCheck"
        :show-menu="false"
      />
    </div>

    <!-- Master Unified Table Card (Rule 10) -->
    <AppDataTable
      title="Leave Approvals &amp; Workflow Queue"
      subtitle="Review team leave applications, verify handover coverage, approve or adjust granted days, and log governance remarks."
      :columns="tableColumns"
      :show-view-action="false"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Sub-view Underline Tabs (Rule 1) -->
      <template #header-extra>
        <div class="tabs-subview-wrapper">
          <UnderlineTabs
            v-model="activeTab"
            :tabs="approvalTabs"
            size="sm"
          />
        </div>
      </template>

      <!-- Table Body (Rule 8, 9) -->
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
              <th>Employee</th>
              <th>Leave Type</th>
              <th>Duration</th>
              <th>Leave Period</th>
              <th>Handover Cover</th>
              <th>Workflow Stage</th>
              <th>Status</th>
              <th class="th-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="item in filteredRecords"
              :key="item.id"
              class="table-row-hover"
              @click="openReviewModal(item)"
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

              <!-- Employee: Avatar + Bold Name (#404040) + EMP Code subtext -->
              <td>
                <div class="name-cell-group">
                  <img :src="item.employee_avatar" :alt="item.employee_name" class="table-avatar-img" />
                  <div class="name-meta-col">
                    <span class="table-emp-name">{{ item.employee_name }}</span>
                    <span class="table-emp-code">{{ item.code }} &bull; {{ item.employee_code }}</span>
                  </div>
                </div>
              </td>

              <!-- Leave Type (Tertiary color #737373) -->
              <td class="td-tertiary">
                {{ item.leave_type_name }}
              </td>

              <!-- Duration (Tertiary color #737373) -->
              <td class="td-tertiary">
                <span v-if="item.is_half_day">0.5 Day ({{ item.day_portion }})</span>
                <span v-else>{{ item.requested_days.toFixed(1) }} Days</span>
              </td>

              <!-- Leave Period (Tertiary color #737373) -->
              <td class="td-tertiary">
                {{ formatDateRange(item.start_date, item.end_date) }}
              </td>

              <!-- Handover Cover (Plain text in #737373, zero avatars) -->
              <td class="td-tertiary">
                {{ item.handover_employee_name || '—' }}
              </td>

              <!-- Workflow Stage -->
              <td class="td-tertiary">
                <span class="workflow-stage-text">
                  {{ item.current_step_name }}
                </span>
              </td>

              <!-- Status Pill -->
              <td>
                <span class="status-pill" :class="`status-${item.request_state}`">
                  {{ item.request_state.charAt(0).toUpperCase() + item.request_state.slice(1) }}
                </span>
              </td>

              <!-- Actions (⋮ 3-dots popup) -->
              <td class="td-actions" @click.stop>
                <div class="action-dropdown-wrapper">
                  <button
                    type="button"
                    class="btn-action-dots"
                    title="Review Request"
                    @click="openReviewModal(item)"
                  >
                    <MoreVertical :size="15" />
                  </button>
                </div>
              </td>
            </tr>

            <!-- Empty State -->
            <tr v-if="filteredRecords.length === 0">
              <td colspan="9" class="empty-state-cell">
                <span class="empty-text">No approval requests found in this queue.</span>
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

    <!-- ─── Review & Decision Modal (Rule 4 & 5) ─── -->
    <div v-if="isDecisionModalOpen && activeReviewItem" class="modal-backdrop" @click="closeReviewModal">
      <div class="modal-container review-modal-box" @click.stop>
        <!-- Modal Header: Title ONLY, NO divider (Rule 4) -->
        <div class="modal-header-clean">
          <h3 class="modal-title-clean">Review Leave Application</h3>
          <button type="button" class="btn-close-modal" @click="closeReviewModal">
            <X :size="16" />
          </button>
        </div>

        <div class="modal-body-content">
          <!-- Candidate & Request Dossier Card -->
          <div class="dossier-review-card">
            <div class="candidate-row">
              <img :src="activeReviewItem.employee_avatar" :alt="activeReviewItem.employee_name" class="modal-avatar" />
              <div class="candidate-meta">
                <span class="candidate-name">{{ activeReviewItem.employee_name }}</span>
                <span class="candidate-sub">{{ activeReviewItem.employee_code }} &bull; {{ activeReviewItem.employee_position }}</span>
              </div>
              <div class="balance-badge-box ml-auto">
                <span class="balance-badge-label">Available Balance</span>
                <span class="balance-badge-val">{{ activeReviewItem.available_balance.toFixed(1) }} Days</span>
              </div>
            </div>

            <div class="request-meta-grid">
              <div class="meta-item">
                <span class="meta-k">Leave Type:</span>
                <span class="meta-v">{{ activeReviewItem.leave_type_name }}</span>
              </div>
              <div class="meta-item">
                <span class="meta-k">Requested Period:</span>
                <span class="meta-v">{{ formatDateRange(activeReviewItem.start_date, activeReviewItem.end_date) }}</span>
              </div>
              <div class="meta-item">
                <span class="meta-k">Requested Days:</span>
                <span class="meta-v highlight-val">{{ activeReviewItem.requested_days.toFixed(1) }} Days</span>
              </div>
              <div class="meta-item">
                <span class="meta-k">Handover Coverage:</span>
                <span class="meta-v">{{ activeReviewItem.handover_employee_name }}</span>
              </div>
            </div>

            <div v-if="activeReviewItem.reason" class="reason-quote-box">
              <span class="reason-quote-label">Employee Note / Reason:</span>
              <p class="reason-quote-text">"{{ activeReviewItem.reason }}"</p>
            </div>
          </div>

          <!-- Decision Form Controls (Rule 5: Compact 38px, NO placeholder) -->
          <div class="decision-form-grid">
            <FormInput
              v-model="approvalForm.approved_days"
              type="number"
              label="Approved Days"
              :required="true"
            />
          </div>

          <div class="remarks-form-row">
            <FormTextarea
              v-model="approvalForm.remarks"
              label="Decision Remarks / Comments"
              rows="3"
            />
          </div>
        </div>

        <!-- Modal Actions Bar (Rule 4: Rectangular 8-10px buttons) -->
        <div class="modal-footer-clean">
          <button
            type="button"
            class="btn-reject-modal"
            @click="handleReject"
          >
            <X :size="14" />
            <span>Reject Request</span>
          </button>

          <button
            type="button"
            class="btn-approve-modal"
            @click="handleApprove"
          >
            <Check :size="14" />
            <span>Approve Leave</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.leave-approvals-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 20px 24px 80px 24px;
  background-color: var(--alias-color-bg-canvas, #f8fafc);
  min-height: 100vh;
}

/* Breadcrumb */
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

/* Metrics Grid */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

@media (max-width: 1024px) {
  .metrics-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

.metric-interactive {
  cursor: pointer;
  transition: transform 0.15s, box-shadow 0.15s;
}

.metric-interactive:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.metric-active {
  border: 1.5px solid #0B529C !important;
}

/* Tabs wrapper */
.tabs-subview-wrapper {
  margin-top: 4px;
}

/* Table Typography & Cell Proportions (Rule 8, 9) */
.name-cell-group {
  display: flex;
  align-items: center;
  gap: 10px;
}

.table-avatar-img {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
}

.name-meta-col {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-emp-name {
  font-weight: 600;
  color: #404040;
  font-size: 13px;
}

.table-emp-code {
  font-size: 11px;
  color: #737373;
}

.td-tertiary {
  color: #737373 !important;
  font-size: 12.5px;
}

.workflow-stage-text {
  color: #737373;
  font-size: 12px;
}

/* Status Pills */
.status-pill {
  display: inline-block;
  padding: 2px 10px;
  border-radius: 12px;
  font-size: 11.5px;
  font-weight: 500;
}

.status-pending {
  background-color: #fef3c7;
  color: #b45309;
}

.status-approved {
  background-color: #ecfdf5;
  color: #059669;
}

.status-rejected {
  background-color: #fee2e2;
  color: #dc2626;
}

/* Actions */
.th-actions, .td-actions {
  text-align: right;
  width: 50px;
}

.btn-action-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #404040;
}

/* Modal Styles */
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

.modal-container {
  background-color: #ffffff;
  border-radius: 10px;
  width: 100%;
  max-width: 540px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
}

.modal-header-clean {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 22px 12px 22px;
}

.modal-title-clean {
  margin: 0;
  font-size: 17px;
  font-weight: 600;
  color: #404040;
}

.btn-close-modal {
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  padding: 4px;
  border-radius: 6px;
}

.btn-close-modal:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.modal-body-content {
  padding: 4px 22px 20px 22px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.dossier-review-card {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.candidate-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.modal-avatar {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  object-fit: cover;
}

.candidate-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.candidate-name {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.candidate-sub {
  font-size: 11.5px;
  color: #737373;
}

.balance-badge-box {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
}

.balance-badge-label {
  font-size: 10.5px;
  color: #737373;
}

.balance-badge-val {
  font-size: 12.5px;
  font-weight: 600;
  color: #0B529C;
}

.request-meta-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px 16px;
  border-top: 1px solid #e2e8f0;
  padding-top: 10px;
}

.meta-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 12px;
}

.meta-k {
  color: #737373;
}

.meta-v {
  color: #404040;
  font-weight: 500;
}

.highlight-val {
  color: #0B529C;
  font-weight: 600;
}

.reason-quote-box {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  padding: 8px 12px;
}

.reason-quote-label {
  display: block;
  font-size: 10.5px;
  color: #737373;
  margin-bottom: 2px;
}

.reason-quote-text {
  margin: 0;
  font-size: 12px;
  color: #334155;
  font-style: italic;
  line-height: 1.4;
}

.decision-form-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 12px;
}

.remarks-form-row {
  margin-top: -4px;
}

.modal-footer-clean {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
  padding: 14px 22px 18px 22px;
  border-top: 1px solid #f1f5f9;
}

.btn-reject-modal {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  border-radius: 8px;
  border: 1px solid #fee2e2;
  background-color: #fff1f2;
  color: #e11d48;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-reject-modal:hover {
  background-color: #ffe4e6;
}

.btn-approve-modal {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 18px;
  border-radius: 8px;
  border: none;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-approve-modal:hover {
  background-color: #094380;
}
</style>
