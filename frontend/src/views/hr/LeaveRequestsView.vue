<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, Search, CheckCircle2, Clock,
  Check, X, FileText, User,
  MoreVertical, Eye, Users
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import MetricCard from '../../components/MetricCard.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import { useToast } from '../../composables/useToast';

const router = useRouter();

// ─── Breadcrumbs (Rule 3: [Monitor] > Leave Requests strictly) ───
const breadcrumbItems = [
  { label: 'Leave Requests' }
];

// ─── Current Logged-in Approver / User Context ───
const currentUser = {
  id: 7,
  name: 'Marta Tadesse',
  code: 'EMP-0007',
  role: 'Branch Manager & Approver'
};

// ─── Schema-Aligned Datasets (HR_Schema_final-v4.sql lines 1688–1760) ───
export interface LeaveRequestRecord {
  id: number;
  code: string;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_avatar: string;
  leave_type_id: number;
  leave_type_name: string;
  start_date: string;
  end_date: string;
  duration_text: string;
  requested_days: number;
  approved_days: number | null;
  is_half_day: boolean;
  day_portion?: string;
  handover_employee_name: string;
  reason: string;
  request_state: 'draft' | 'pending' | 'approved' | 'rejected' | 'taken';
  is_pending_my_decision: boolean;
  is_currently_on_leave: boolean;
  current_step_name: string;
  created_at: string;
}

const requests = ref<LeaveRequestRecord[]>([
  {
    id: 731,
    code: 'LVR-2026-0731',
    employee_id: 12,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP 0012',
    employee_avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&h=120&q=80',
    leave_type_id: 1,
    leave_type_name: 'Annual leave',
    start_date: '2026-07-08',
    end_date: '2026-07-11',
    duration_text: '2.0 Days',
    requested_days: 2.0,
    approved_days: 2.0,
    is_half_day: false,
    handover_employee_name: 'Sara Tesfera',
    reason: 'Family matters in Debre Zeit. Tasks transitioned.',
    request_state: 'approved',
    is_pending_my_decision: false,
    is_currently_on_leave: false,
    current_step_name: 'Approved',
    created_at: '2026-07-02'
  },
  {
    id: 732,
    code: 'LVR-2026-0732',
    employee_id: 18,
    employee_name: 'Kidst Tesfaye',
    employee_code: 'EMP 0018',
    employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&h=120&q=80',
    leave_type_id: 1,
    leave_type_name: 'Annual leave',
    start_date: '2026-07-08',
    end_date: '2026-07-11',
    duration_text: '3.0 Days',
    requested_days: 3.0,
    approved_days: null,
    is_half_day: false,
    handover_employee_name: 'Dawit Yohannes',
    reason: 'Personal leave request.',
    request_state: 'rejected',
    is_pending_my_decision: false,
    is_currently_on_leave: false,
    current_step_name: 'Rejected',
    created_at: '2026-07-03'
  },
  {
    id: 733,
    code: 'LVR-2026-0733',
    employee_id: 812,
    employee_name: 'Mihret Abera',
    employee_code: 'EMP 0812',
    employee_avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=120&h=120&q=80',
    leave_type_id: 2,
    leave_type_name: 'Sick Leave',
    start_date: '2026-07-08',
    end_date: '2026-07-22',
    duration_text: '14.0 Days',
    requested_days: 14.0,
    approved_days: null,
    is_half_day: false,
    handover_employee_name: 'Ephrem Tadese',
    reason: 'Medical consultation & post-procedure doctor recovery certificate.',
    request_state: 'pending',
    is_pending_my_decision: true,
    is_currently_on_leave: false,
    current_step_name: 'Branch Manager Endorsement',
    created_at: '2026-07-06'
  },
  {
    id: 734,
    code: 'LVR-2026-0734',
    employee_id: 124,
    employee_name: 'Almaz Kebede',
    employee_code: 'EMP 0124',
    employee_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=120&h=120&q=80',
    leave_type_id: 1,
    leave_type_name: 'Annual leave',
    start_date: '2026-09-01',
    end_date: '2026-09-02',
    duration_text: '2.0 Days',
    requested_days: 2.0,
    approved_days: null,
    is_half_day: false,
    handover_employee_name: 'Abebe Kebede',
    reason: 'Annual personal leave allocation booking.',
    request_state: 'pending',
    is_pending_my_decision: true,
    is_currently_on_leave: false,
    current_step_name: 'Operations Manager Authorization',
    created_at: '2026-08-01'
  },
  {
    id: 735,
    code: 'LVR-2026-0735',
    employee_id: 44,
    employee_name: 'Kassahun Belay',
    employee_code: 'EMP 0044',
    employee_avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&h=120&q=80',
    leave_type_id: 1,
    leave_type_name: 'Annual leave',
    start_date: '2026-09-10',
    end_date: '2026-09-15',
    duration_text: '5.0 Days',
    requested_days: 5.0,
    approved_days: null,
    is_half_day: false,
    handover_employee_name: 'Marta Tadesse',
    reason: 'Statutory annual break.',
    request_state: 'pending',
    is_pending_my_decision: true,
    is_currently_on_leave: false,
    current_step_name: 'Awaiting Your Decision',
    created_at: '2026-08-02'
  },
  {
    id: 736,
    code: 'LVR-2026-0736',
    employee_id: 22,
    employee_name: 'Sara Tefera',
    employee_code: 'EMP 0022',
    employee_avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80',
    leave_type_id: 3,
    leave_type_name: 'Maternity Leave',
    start_date: '2026-08-01',
    end_date: '2026-10-30',
    duration_text: '90.0 Days',
    requested_days: 90.0,
    approved_days: 90.0,
    is_half_day: false,
    handover_employee_name: 'Dawit Yohannes',
    reason: 'Statutory maternity leave booking.',
    request_state: 'approved',
    is_pending_my_decision: false,
    is_currently_on_leave: true,
    current_step_name: 'Approved / Active On Leave',
    created_at: '2026-07-20'
  },
  {
    id: 737,
    code: 'LVR-2026-0737',
    employee_id: 31,
    employee_name: 'Dawit Yohannes',
    employee_code: 'EMP 0031',
    employee_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&h=120&q=80',
    leave_type_id: 5,
    leave_type_name: 'Bereavement Leave',
    start_date: '2026-07-15',
    end_date: '2026-07-18',
    duration_text: '3.0 Days',
    requested_days: 3.0,
    approved_days: 3.0,
    is_half_day: false,
    handover_employee_name: 'Marta Tadesse',
    reason: 'Bereavement emergency family absence.',
    request_state: 'approved',
    is_pending_my_decision: false,
    is_currently_on_leave: false,
    current_step_name: 'Completed',
    created_at: '2026-07-14'
  }
]);

// ─── Filter Tabs & State ───
type TabFilterKey = 'all' | 'pending_decision' | 'all_pending' | 'approved' | 'rejected' | 'on_leave';
const activeTab = ref<TabFilterKey>('all');

const pendingDecisionCount = computed(() => requests.value.filter(r => r.is_pending_my_decision).length);
const allPendingCount = computed(() => requests.value.filter(r => r.request_state === 'pending').length);
const approvedCount = computed(() => requests.value.filter(r => r.request_state === 'approved').length);
const onLeaveCount = computed(() => requests.value.filter(r => r.is_currently_on_leave).length);

const subTabs = computed<UnderlineTabItem[]>(() => [
  { id: 'all', label: 'All Requests' },
  { id: 'pending_decision', label: 'Pending My Decision', count: pendingDecisionCount.value },
  { id: 'all_pending', label: 'All Pending Queue', count: allPendingCount.value },
  { id: 'approved', label: 'Approved' },
  { id: 'rejected', label: 'Rejected' }
]);

// ─── Filtering & Selection ───
const searchQuery = ref('');
const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const { toast } = useToast();

const showToast = (msg: string) => {
  toast.success(msg);
};

const filteredRequests = computed(() => {
  return requests.value.filter(item => {
    // Tab filter
    if (activeTab.value === 'pending_decision' && !item.is_pending_my_decision) return false;
    if (activeTab.value === 'all_pending' && item.request_state !== 'pending') return false;
    if (activeTab.value === 'approved' && item.request_state !== 'approved') return false;
    if (activeTab.value === 'rejected' && item.request_state !== 'rejected') return false;
    if (activeTab.value === 'on_leave' && !item.is_currently_on_leave) return false;

    // Search query
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase().trim();
      const matchName = item.employee_name.toLowerCase().includes(q);
      const matchCode = item.employee_code.toLowerCase().includes(q);
      const matchType = item.leave_type_name.toLowerCase().includes(q);
      const matchHandover = item.handover_employee_name.toLowerCase().includes(q);
      if (!matchName && !matchCode && !matchType && !matchHandover) return false;
    }

    return true;
  });
});

const isAllSelected = computed(() => {
  return (
    filteredRequests.value.length > 0 &&
    filteredRequests.value.every(r => selectedRowIds.value.includes(r.id))
  );
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
  if (idx > -1) {
    selectedRowIds.value.splice(idx, 1);
  } else {
    selectedRowIds.value.push(id);
  }
};

// ─── Table Columns (Exact match with user screenshot) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Name', visible: true, sortable: true },
  { key: 'leave_type', label: 'Leave Type', visible: true, sortable: true },
  { key: 'duration', label: 'Duration', visible: true, sortable: true },
  { key: 'period', label: 'Leave Period', visible: true, sortable: true },
  { key: 'handover', label: 'Handover Cover', visible: true, sortable: true },
  { key: 'status', label: 'Status', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

const handleToggleColumn = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  if (col) col.visible = !col.visible;
};

const isColVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

// ─── Inline Approval & Rejection Actions ───
const handleApprove = (item: LeaveRequestRecord) => {
  item.request_state = 'approved';
  item.is_pending_my_decision = false;
  item.current_step_name = 'Approved by Marta Tadesse';
  activeActionMenuId.value = null;
  showToast(`Leave request for ${item.employee_name} has been approved.`);
};

const handleReject = (item: LeaveRequestRecord) => {
  item.request_state = 'rejected';
  item.is_pending_my_decision = false;
  item.current_step_name = 'Rejected by Marta Tadesse';
  activeActionMenuId.value = null;
  showToast(`Leave request for ${item.employee_name} has been rejected.`);
};

// ─── Quick Create Modal State & Handlers ───
const isCreateModalOpen = ref(false);
const createForm = ref({
  leave_type_id: 1,
  start_date: new Date().toISOString().slice(0, 10),
  end_date: new Date().toISOString().slice(0, 10),
  handover_employee_id: 14,
  is_half_day: false,
  portion: 'First Half (Morning)'
});

const leaveTypeOptions: SelectOption[] = [
  { value: 1, label: 'Annual leave' },
  { value: 2, label: 'Sick Leave' },
  { value: 3, label: 'Maternity Leave' },
  { value: 4, label: 'Paternity Leave' },
  { value: 5, label: 'Bereavement Leave' },
  { value: 6, label: 'Unpaid Leave' }
];

const colleagueOptions: SelectOption[] = [
  { value: 12, label: 'Abebe Kebede (EMP 0012)' },
  { value: 18, label: 'Sara Tesfera (Shift Supervisor)' },
  { value: 31, label: 'Dawit Yohannes (Logistics Officer)' },
  { value: 44, label: 'Kassahun Belay (Branch Head)' }
];

const openCreateModal = () => {
  isCreateModalOpen.value = true;
};

const closeCreateModal = () => {
  isCreateModalOpen.value = false;
};

const handleSubmitQuickCreate = () => {
  const selectedType = leaveTypeOptions.find(t => t.value === createForm.value.leave_type_id);
  const newId = 740 + Math.floor(Math.random() * 100);
  
  const newRow: LeaveRequestRecord = {
    id: newId,
    code: `LVR-2026-0${newId}`,
    employee_id: currentUser.id,
    employee_name: currentUser.name,
    employee_code: currentUser.code,
    employee_avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80',
    leave_type_id: createForm.value.leave_type_id,
    leave_type_name: selectedType?.label || 'Annual leave',
    start_date: createForm.value.start_date,
    end_date: createForm.value.end_date,
    duration_text: createForm.value.is_half_day ? '0.5 Day' : '1.0 Day',
    requested_days: createForm.value.is_half_day ? 0.5 : 1.0,
    approved_days: null,
    is_half_day: createForm.value.is_half_day,
    handover_employee_name: 'Sara Tesfera',
    reason: 'Personal leave request.',
    request_state: 'pending',
    is_pending_my_decision: false,
    is_currently_on_leave: false,
    current_step_name: 'Department Head Authorization',
    created_at: new Date().toISOString().slice(0, 10)
  };

  requests.value.unshift(newRow);
  showToast(`Leave request ${newRow.code} submitted successfully.`);
  closeCreateModal();
};

const handleExpandToFull = () => {
  isCreateModalOpen.value = false;
  router.push({
    path: '/hr/leave-requests/create',
    query: {
      leave_type_id: createForm.value.leave_type_id,
      start_date: createForm.value.start_date,
      end_date: createForm.value.end_date,
      handover_employee_id: createForm.value.handover_employee_id,
      is_half_day: createForm.value.is_half_day ? '1' : '0'
    }
  });
};

const goToDetail = (id: number) => {
  activeActionMenuId.value = null;
  router.push(`/hr/leave-requests/${id}`);
};

const formatDateRange = (start: string, end: string) => {
  const dStart = new Date(start);
  const dEnd = new Date(end);
  const opt: Intl.DateTimeFormatOptions = { month: 'short', day: 'numeric', year: 'numeric' };
  return `${dStart.toLocaleDateString('en-US', opt)} - ${dEnd.toLocaleDateString('en-US', opt)}`;
};
</script>

<template>
  <div class="leave-requests-page" @click="activeActionMenuId = null">
    <!-- Breadcrumb (Rule 3: [Monitor] > Leave Requests strictly) -->
    <div class="breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ─── 4 UNIFIED METRIC CARDS (Exact Match to User Screenshot) ─── -->
    <div class="metrics-grid">
      <!-- Card 1: PENDING MY DECISION -->
      <MetricCard
        label="PENDING MY DECISION"
        value="3 Requests"
        subtext="Awaiting your authorization"
        :icon="Clock"
        :show-menu="false"
        class="metric-interactive"
        :class="{ 'metric-active': activeTab === 'pending_decision' }"
        @click="activeTab = activeTab === 'pending_decision' ? 'all' : 'pending_decision'"
      />

      <!-- Card 2: ALL PENDING QUEUE -->
      <MetricCard
        label="ALL PENDING QUEUE"
        value="4 In Review"
        subtext="Departmental review pipeline"
        :icon="FileText"
        :show-menu="false"
        class="metric-interactive"
        :class="{ 'metric-active': activeTab === 'all_pending' }"
        @click="activeTab = activeTab === 'all_pending' ? 'all' : 'all_pending'"
      />

      <!-- Card 3: APPROVED THIS MONTH -->
      <MetricCard
        label="APPROVED THIS MONTH"
        value="11 Requests"
        subtext="Successfully endorsed"
        :icon="CheckCircle2"
        :show-menu="false"
        class="metric-interactive"
        :class="{ 'metric-active': activeTab === 'approved' }"
        @click="activeTab = activeTab === 'approved' ? 'all' : 'approved'"
      />

      <!-- Card 4: CURRENTLY ON LEAVE -->
      <MetricCard
        label="CURRENTLY ON LEAVE"
        value="5 Staff"
        subtext="Active out-of-office coverage"
        :icon="Users"
        :show-menu="false"
        class="metric-interactive"
        :class="{ 'metric-active': activeTab === 'on_leave' }"
        @click="activeTab = activeTab === 'on_leave' ? 'all' : 'on_leave'"
      />
    </div>

    <!-- ─── MASTER UNIFIED DATA TABLE (Rule 10: Unified card layout) ─── -->
    <AppDataTable
      title="Leave Requests"
      subtitle="Submit and track personal leave applications, schedule half-day leaves, handover coverage, and monitor approval progression."
      v-model:searchQuery="searchQuery"
      :columns="tableColumns"
      :totalEntries="filteredRequests.length"
      :show-view-action="false"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Primary Action in Top Right Slot (+ Create Leave Request matching screenshot) -->
      <template #actions>
        <AppButton variant="primary" size="sm" @click="openCreateModal">
  <template #icon-left><Plus :size="15" /></template>
  Create Leave Request
</AppButton>
      </template>

      <!-- Table Body (Exact Columns & Data from User Screenshot) -->
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
              <th v-if="isColVisible('name')">Name</th>
              <th v-if="isColVisible('leave_type')">Leave Type</th>
              <th v-if="isColVisible('duration')">Duration</th>
              <th v-if="isColVisible('period')">Leave Period</th>
              <th v-if="isColVisible('handover')">Handover Cover</th>
              <th v-if="isColVisible('status')">Status</th>
              <th v-if="isColVisible('actions')" class="th-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="item in filteredRequests"
              :key="item.id"
              class="table-row-hover"
              @click="goToDetail(item.id)"
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

              <!-- Name Column: Avatar + Full Name in bold + Code underneath (Exact Match to Screenshot) -->
              <td v-if="isColVisible('name')" class="td-name-cell">
                <div class="employee-identity-block">
                  <img :src="item.employee_avatar" :alt="item.employee_name" class="table-avatar" />
                  <div class="name-subtext-group">
                    <span class="table-name-primary">{{ item.employee_name }}</span>
                    <span class="table-code-subtext">{{ item.employee_code }}</span>
                  </div>
                </div>
              </td>

              <!-- Leave Type: Tertiary Color #737373 -->
              <td v-if="isColVisible('leave_type')" class="td-tertiary">
                {{ item.leave_type_name }}
              </td>

              <!-- Duration (Tertiary color #737373) -->
              <td v-if="isColVisible('duration')" class="td-tertiary">
                {{ item.duration_text }}
              </td>

              <!-- Leave Period (Tertiary color #737373) -->
              <td v-if="isColVisible('period')" class="td-tertiary">
                {{ formatDateRange(item.start_date, item.end_date) }}
              </td>

              <!-- Handover Cover (Tertiary color #737373) -->
              <td v-if="isColVisible('handover')" class="td-tertiary">
                {{ item.handover_employee_name || '—' }}
              </td>

              <!-- Status Badge (BaseBadge: Approved: success, Rejected: error, Pending: warning) -->
              <td v-if="isColVisible('status')">
                <BaseBadge
                  :color="item.request_state === 'approved' ? 'success' : item.request_state === 'rejected' ? 'error' : 'warning'"
                  size="sm"
                >
                  {{ item.request_state.charAt(0).toUpperCase() + item.request_state.slice(1) }}
                </BaseBadge>
              </td>

              <!-- Actions (⋮ 3-dots button with Approval / Detail actions) -->
              <td v-if="isColVisible('actions')" class="td-actions" @click.stop>
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
                        <span>View Details</span>
                      </button>

                      <template v-if="item.request_state === 'pending'">
                        <button type="button" class="action-item text-green" @click="handleApprove(item)">
                          <Check :size="13" />
                          <span>Approve Request</span>
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

            <!-- Empty State -->
            <tr v-if="filteredRequests.length === 0">
              <td colspan="8" class="empty-state-cell">
                <span class="empty-text">No leave requests found in this view.</span>
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
      title="Create Leave Request"
      save-label="Save"
      width="lg"
      :show-expand-button="true"
      @update:show="isCreateModalOpen = $event"
      @expand="handleExpandToFull"
      @save="handleSubmitQuickCreate"
      @cancel="closeCreateModal"
    >
      <div class="modal-form-content">
        <!-- Leave Type -->
        <div class="form-row-single">
          <FormSelect
            v-model="createForm.leave_type_id"
            label="Leave Type"
            :options="leaveTypeOptions"
            placeholder="Select Type"
            :required="true"
          />
        </div>

        <!-- Date Range Grid -->
        <div class="form-grid-2col">
          <FormInput
            v-model="createForm.start_date"
            type="date"
            label="Start Date"
            :required="true"
          />
          <FormInput
            v-model="createForm.end_date"
            type="date"
            label="End Date"
            :required="true"
          />
        </div>

        <!-- Handover Colleague -->
        <div class="form-row-single">
          <FormSelect
            v-model="createForm.handover_employee_id"
            label="Hand Over Employee"
            :options="colleagueOptions"
            placeholder="Select Employee"
          />
        </div>

        <!-- Half Day Checkbox -->
        <div class="checkbox-wrapper-row">
          <FormCheckbox
            v-model="createForm.is_half_day"
            label="Half day Leave"
            description="Indicate whether this request applies only to morning or afternoon operational shift portion."
          />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.leave-requests-page {
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

/* 4 Metric Cards Grid */
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
  transition: transform 0.15s, border-color 0.15s, box-shadow 0.15s;
}

.metric-interactive:hover {
  transform: translateY(-2px);
  border-color: #cbd5e1;
}

.metric-active {
  border-color: #0B529C !important;
  box-shadow: 0 4px 14px rgba(11, 82, 156, 0.12) !important;
}

/* Sub-views Tabs */
.tabs-subview-wrapper {
  margin-top: 4px;
}

/* Create Button */
.btn-create-leave-primary {
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

.btn-create-leave-primary:hover {
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
  cursor: pointer;
  transition: background-color 0.1s;
}

.table-row-hover:hover {
  background-color: #fafafa;
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
  background-color: #f5f5f5;
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
  min-width: 140px;
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
  background-color: #fafafa;
}

.text-green {
  color: #059669;
}

.text-red {
  color: #dc2626;
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

.checkbox-wrapper-row {
  padding-top: 4px;
}
</style>
