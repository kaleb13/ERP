<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import {
  CheckCircle2, XCircle, Clock, Calendar,
  FileText, Printer, AlertCircle, CornerDownLeft,
  X, Check, Award
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import MetricCard from '../../components/MetricCard.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import FormInput from '../../components/FormInput.vue';

const route = useRoute();
const router = useRouter();

// ─── Record ID from Route ───
const requestId = computed(() => Number(route.params.id) || 732);

// ─── Leave Request Record Database (HR_Schema_final-v4.sql lines 1688–1760) ───
export interface LeaveRequestDetailRecord {
  id: number;
  code: string;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_role: string;
  employee_dept: string;
  employee_avatar: string;
  leave_type_id: number;
  leave_type_name: string;
  is_paid: boolean;
  leave_allocation_id: number;
  allocation_code: string;
  period_start: string;
  period_end: string;
  start_date: string;
  end_date: string;
  requested_days: number;
  approved_days: number | null;
  is_half_day: boolean;
  day_portion?: string;
  shift_name?: string;
  handover_employee_id: number;
  handover_employee_name: string;
  handover_employee_role: string;
  handover_confirmed: boolean;
  reason: string;
  request_state: 'draft' | 'pending' | 'approved' | 'rejected' | 'taken';
  current_step_name: string;
  created_at: string;
  has_attachment: boolean;
  attachment_name?: string;
  attachment_size?: string;
  actual_return_date?: string | null;
  recalled_at?: string | null;
  recall_reason?: string | null;
  
  // Entitlement context
  entitled_days: number;
  taken_days: number;
  pending_days: number;
  available_days: number;
  
  // Exploded Daily Schedule (LeaveRequestDay)
  days: {
    id: number;
    date: string;
    day_name: string;
    portion: string;
    day_value: number;
    attendance_status: string;
  }[];
  
  // Workflow Approvals (LeaveRequestApproval)
  approvals: {
    id: number;
    step_number: number;
    step_name: string;
    approver_name: string;
    approver_role: string;
    approval_state: 'pending' | 'approved' | 'rejected' | 'queued';
    acted_at?: string;
    remarks?: string;
  }[];
}

const leaveDatabase: Record<number, LeaveRequestDetailRecord> = {
  732: {
    id: 732,
    code: 'LVR-2026-0732',
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-014',
    employee_role: 'Senior Cashier',
    employee_dept: 'Bole Commercial Branch - Retail Operations',
    employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120&h=120&fit=crop&crop=faces',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    is_paid: true,
    leave_allocation_id: 453,
    allocation_code: 'LAL-2026-0453 (FY 2026/27)',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    start_date: '2026-08-10',
    end_date: '2026-08-11',
    requested_days: 2.0,
    approved_days: null,
    is_half_day: false,
    shift_name: 'Commercial Office Shift (08:30 – 17:30)',
    handover_employee_id: 18,
    handover_employee_name: 'Sara Tefera',
    handover_employee_role: 'Shift Supervisor',
    handover_confirmed: true,
    reason: 'Personal family matters in Debre Zeit. Cash drawer daily registers fully reconciled and branch key custody formally surrendered to shift supervisor.',
    request_state: 'pending',
    current_step_name: 'Department Head Authorization',
    created_at: '2026-08-01 09:30',
    has_attachment: false,
    entitled_days: 18.0,
    taken_days: 0.0,
    pending_days: 2.5,
    available_days: 15.5,
    days: [
      { id: 101, date: '2026-08-10', day_name: 'Monday', portion: 'Full Day', day_value: 1.0, attendance_status: 'Scheduled Leave (On Leave)' },
      { id: 102, date: '2026-08-11', day_name: 'Tuesday', portion: 'Full Day', day_value: 1.0, attendance_status: 'Scheduled Leave (On Leave)' }
    ],
    approvals: [
      {
        id: 8101,
        step_number: 1,
        step_name: 'Shift Supervisor Endorsement',
        approver_name: 'Sara Tefera',
        approver_role: 'Shift Supervisor',
        approval_state: 'approved',
        acted_at: 'Aug 1, 2026, 11:20 AM',
        remarks: 'Cash balances reconciled. Handover cover accepted and verified for both days.'
      },
      {
        id: 8102,
        step_number: 2,
        step_name: 'Department Head Authorization',
        approver_name: 'Marta Tadesse',
        approver_role: 'Head of Branch Operations',
        approval_state: 'pending',
        acted_at: undefined,
        remarks: undefined
      },
      {
        id: 8103,
        step_number: 3,
        step_name: 'HR Records & Roster Clearance',
        approver_name: 'Kassahun Belay',
        approver_role: 'HR Officer',
        approval_state: 'queued',
        acted_at: undefined,
        remarks: undefined
      }
    ]
  },
  735: {
    id: 735,
    code: 'LVR-2026-0735',
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-014',
    employee_role: 'Senior Cashier',
    employee_dept: 'Bole Commercial Branch - Retail Operations',
    employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120&h=120&fit=crop&crop=faces',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    is_paid: true,
    leave_allocation_id: 453,
    allocation_code: 'LAL-2026-0453 (FY 2026/27)',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    start_date: '2026-09-14',
    end_date: '2026-09-14',
    requested_days: 0.5,
    approved_days: null,
    is_half_day: true,
    day_portion: 'First Half (Morning Shift)',
    shift_name: 'Morning Window (08:30 – 12:30)',
    handover_employee_id: 18,
    handover_employee_name: 'Sara Tefera',
    handover_employee_role: 'Shift Supervisor',
    handover_confirmed: true,
    reason: 'Morning medical consultation appointment at Landmark General Hospital.',
    request_state: 'pending',
    current_step_name: 'Shift Supervisor Endorsement',
    created_at: '2026-08-03 14:10',
    has_attachment: true,
    attachment_name: 'Clinic_Appointment_Slip.pdf',
    attachment_size: '420 KB',
    entitled_days: 18.0,
    taken_days: 0.0,
    pending_days: 0.5,
    available_days: 17.5,
    days: [
      { id: 103, date: '2026-09-14', day_name: 'Monday', portion: 'First Half (Morning)', day_value: 0.5, attendance_status: 'Half-Day Leave' }
    ],
    approvals: [
      {
        id: 8104,
        step_number: 1,
        step_name: 'Shift Supervisor Endorsement',
        approver_name: 'Sara Tefera',
        approver_role: 'Shift Supervisor',
        approval_state: 'pending',
        acted_at: undefined,
        remarks: undefined
      },
      {
        id: 8105,
        step_number: 2,
        step_name: 'Department Head Authorization',
        approver_name: 'Marta Tadesse',
        approver_role: 'Head of Branch Operations',
        approval_state: 'queued',
        acted_at: undefined,
        remarks: undefined
      }
    ]
  },
  731: {
    id: 731,
    code: 'LVR-2026-0731',
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-014',
    employee_role: 'Senior Cashier',
    employee_dept: 'Bole Commercial Branch - Retail Operations',
    employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120&h=120&fit=crop&crop=faces',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    is_paid: true,
    leave_allocation_id: 453,
    allocation_code: 'LAL-2026-0453 (FY 2026/27)',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    start_date: '2026-07-27',
    end_date: '2026-07-31',
    requested_days: 5.0,
    approved_days: 5.0,
    is_half_day: false,
    shift_name: 'Commercial Office Shift (08:30 – 17:30)',
    handover_employee_id: 18,
    handover_employee_name: 'Sara Tefera',
    handover_employee_role: 'Shift Supervisor',
    handover_confirmed: true,
    reason: 'Pre-scheduled annual leave block for personal rest and domestic travel.',
    request_state: 'approved',
    current_step_name: 'Fully Approved & Authorized',
    created_at: '2026-07-15 10:00',
    has_attachment: false,
    entitled_days: 18.0,
    taken_days: 0.0,
    pending_days: 0.0,
    available_days: 13.0,
    days: [
      { id: 104, date: '2026-07-27', day_name: 'Monday', portion: 'Full Day', day_value: 1.0, attendance_status: 'On Leave' },
      { id: 105, date: '2026-07-28', day_name: 'Tuesday', portion: 'Full Day', day_value: 1.0, attendance_status: 'On Leave' },
      { id: 106, date: '2026-07-29', day_name: 'Wednesday', portion: 'Full Day', day_value: 1.0, attendance_status: 'On Leave' },
      { id: 107, date: '2026-07-30', day_name: 'Thursday', portion: 'Full Day', day_value: 1.0, attendance_status: 'On Leave' },
      { id: 108, date: '2026-07-31', day_name: 'Friday', portion: 'Full Day', day_value: 1.0, attendance_status: 'On Leave' }
    ],
    approvals: [
      {
        id: 8106,
        step_number: 1,
        step_name: 'Shift Supervisor Endorsement',
        approver_name: 'Sara Tefera',
        approver_role: 'Shift Supervisor',
        approval_state: 'approved',
        acted_at: 'Jul 16, 2026, 08:30 AM',
        remarks: 'Cover arranged across the cashier team.'
      },
      {
        id: 8107,
        step_number: 2,
        step_name: 'Department Head Authorization',
        approver_name: 'Marta Tadesse',
        approver_role: 'Head of Branch Operations',
        approval_state: 'approved',
        acted_at: 'Jul 16, 2026, 02:15 PM',
        remarks: 'Approved as planned per the branch leave schedule.'
      },
      {
        id: 8108,
        step_number: 3,
        step_name: 'HR Records & Roster Clearance',
        approver_name: 'Kassahun Belay',
        approver_role: 'HR Officer',
        approval_state: 'approved',
        acted_at: 'Jul 17, 2026, 09:00 AM',
        remarks: 'Balance deducted and roster updated.'
      }
    ]
  },
  733: {
    id: 733,
    code: 'LVR-2026-0733',
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-014',
    employee_role: 'Senior Cashier',
    employee_dept: 'Bole Commercial Branch - Retail Operations',
    employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120&h=120&fit=crop&crop=faces',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    is_paid: true,
    leave_allocation_id: 453,
    allocation_code: 'LAL-2026-0453 (FY 2026/27)',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    start_date: '2026-07-14',
    end_date: '2026-07-16',
    requested_days: 3.0,
    approved_days: 3.0,
    is_half_day: false,
    shift_name: 'Commercial Office Shift (08:30 – 17:30)',
    handover_employee_id: 18,
    handover_employee_name: 'Sara Tefera',
    handover_employee_role: 'Shift Supervisor',
    handover_confirmed: true,
    reason: 'Attending regional family gathering in Hawassa.',
    request_state: 'taken',
    current_step_name: 'Completed & Returned to Duty',
    created_at: '2026-07-02 11:00',
    has_attachment: false,
    actual_return_date: '2026-07-17',
    entitled_days: 18.0,
    taken_days: 3.0,
    pending_days: 0.0,
    available_days: 15.0,
    days: [
      { id: 109, date: '2026-07-14', day_name: 'Tuesday', portion: 'Full Day', day_value: 1.0, attendance_status: 'Completed Leave' },
      { id: 110, date: '2026-07-15', day_name: 'Wednesday', portion: 'Full Day', day_value: 1.0, attendance_status: 'Completed Leave' },
      { id: 111, date: '2026-07-16', day_name: 'Thursday', portion: 'Full Day', day_value: 1.0, attendance_status: 'Completed Leave' }
    ],
    approvals: [
      {
        id: 8109,
        step_number: 1,
        step_name: 'Shift Supervisor Endorsement',
        approver_name: 'Sara Tefera',
        approver_role: 'Shift Supervisor',
        approval_state: 'approved',
        acted_at: 'Jul 3, 2026, 09:10 AM',
        remarks: 'Cover verified.'
      },
      {
        id: 8110,
        step_number: 2,
        step_name: 'Department Head Authorization',
        approver_name: 'Marta Tadesse',
        approver_role: 'Head of Branch Operations',
        approval_state: 'approved',
        acted_at: 'Jul 3, 2026, 03:30 PM',
        remarks: 'Authorized.'
      }
    ]
  }
};

const currentItem = computed<LeaveRequestDetailRecord>(() => {
  return leaveDatabase[requestId.value] || leaveDatabase[732];
});

// ─── Breadcrumb Items (Rule 3 & 4: [Monitor] > Leave Requests > LVR-XXXX) ───
const breadcrumbItems = computed(() => [
  { label: 'Leave Requests', to: '/hr/leave-requests' },
  { label: currentItem.value.code }
]);

// ─── Approver Decision Form State ───
const resolution = ref<'approve' | 'modify' | 'reject'>('approve');
const resolutionOptions: SelectOption[] = [
  { value: 'approve', label: 'Approve Leave Request' },
  { value: 'modify', label: 'Approve with Reduced Days' },
  { value: 'reject', label: 'Reject Leave Request' }
];

const approvedDaysInput = ref<number>(currentItem.value.requested_days);
const decisionRemark = ref('');
const isSubmittingDecision = ref(false);

const toastMessage = ref<string | null>(null);
const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

const handleCancelRequest = () => {
  if (confirm(`Are you sure you want to cancel leave request ${currentItem.value.code}?`)) {
    currentItem.value.request_state = 'draft';
    showToast(`Leave request ${currentItem.value.code} cancelled.`);
  }
};

const handlePrintSlip = () => {
  window.print();
};

const handleSubmitDecision = () => {
  isSubmittingDecision.value = true;
  
  setTimeout(() => {
    isSubmittingDecision.value = false;
    
    // Find active pending step
    const pendingStep = currentItem.value.approvals.find(s => s.approval_state === 'pending');
    
    if (resolution.value === 'reject') {
      if (pendingStep) {
        pendingStep.approval_state = 'rejected';
        pendingStep.acted_at = 'Just now';
        pendingStep.remarks = decisionRemark.value || 'Request rejected per operational requirements.';
      }
      currentItem.value.request_state = 'rejected';
      showToast(`Leave request ${currentItem.value.code} was rejected.`);
    } else {
      if (pendingStep) {
        pendingStep.approval_state = 'approved';
        pendingStep.acted_at = 'Just now';
        pendingStep.remarks = decisionRemark.value || 'Authorized and endorsed.';
      }
      
      if (resolution.value === 'modify') {
        currentItem.value.approved_days = Number(approvedDaysInput.value);
      } else {
        currentItem.value.approved_days = currentItem.value.requested_days;
      }

      // Check if there is a next queued step
      const nextStep = currentItem.value.approvals.find(s => s.approval_state === 'queued');
      if (nextStep) {
        nextStep.approval_state = 'pending';
        currentItem.value.current_step_name = nextStep.step_name;
        showToast(`Decision recorded. Advanced to ${nextStep.step_name}.`);
      } else {
        currentItem.value.request_state = 'approved';
        currentItem.value.current_step_name = 'Fully Approved & Authorized';
        showToast(`Leave request ${currentItem.value.code} fully approved!`);
      }
    }
    
    decisionRemark.value = '';
  }, 400);
};

const formatDateRange = (start: string, end: string) => {
  if (start === end) return start;
  return `${start} – ${end}`;
};
</script>

<template>
  <div class="leave-detail-page">
    <!-- ═══ TOP DOCUMENT NAVIGATION BAR (Standard Haleta ERP Top Bar) ═══ -->
    <div class="top-nav-bar no-print">
      <div class="top-nav-left">
        <AppBreadcrumb :items="breadcrumbItems" no-margin />
      </div>

      <div class="top-nav-actions">
        <AppButton
          variant="outline"
          size="sm"
          @click="handlePrintSlip"
        >
          <template #icon-left><Printer :size="14" /></template>
          Print Leave Slip
        </AppButton>
        <AppButton
          v-if="currentItem.request_state === 'pending'"
          variant="destructive"
          size="sm"
          @click="handleCancelRequest"
        >
          <template #icon-left><XCircle :size="14" /></template>
          Cancel Request
        </AppButton>
      </div>
    </div>

    <!-- Toast Notification -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar no-print">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <!-- ═══ MASTER TWO-COLUMN LAYOUT (Dossier Split Grid: 68% Left, 32% Right) ═══ -->
    <div class="detail-split-layout">
      <!-- ═════════════════════════════════════════════════════════════
           LEFT COLUMN: Leave Dossier, Entitlement & Schedules
           ═════════════════════════════════════════════════════════════ -->
      <div class="main-dossier-column">
        <!-- 1. Employee Hero Card -->
        <div class="dossier-card hero-card">
          <div class="hero-left">
            <img
              :src="currentItem.employee_avatar"
              :alt="currentItem.employee_name"
              class="hero-avatar"
            />
            <div class="hero-meta">
              <div class="hero-title-row">
                <h1 class="hero-name">{{ currentItem.employee_name }}</h1>
                <span class="badge-leave-type">{{ currentItem.leave_type_name }}</span>
                <span class="status-pill" :class="`status-${currentItem.request_state}`">
                  {{ currentItem.request_state }}
                </span>
                <span v-if="currentItem.is_paid" class="badge-paid">Paid Absence</span>
              </div>
              <p class="hero-subtext">
                {{ currentItem.employee_code }} &bull; {{ currentItem.employee_role }} &bull; {{ currentItem.employee_dept }}
              </p>
            </div>
          </div>

          <div class="hero-right">
            <div class="meta-stat-block">
              <span class="meta-label">Leave Period</span>
              <span class="meta-value">{{ formatDateRange(currentItem.start_date, currentItem.end_date) }}</span>
            </div>
            <div class="meta-stat-block">
              <span class="meta-label">Duration</span>
              <span class="meta-value font-bold-duration">{{ currentItem.requested_days.toFixed(1) }} Working Days</span>
            </div>
            <div class="meta-stat-block">
              <span class="meta-label">Request ID</span>
              <span class="meta-value font-mono">{{ currentItem.code }}</span>
            </div>
          </div>
        </div>

        <!-- 2. Leave Balance & Entitlement Impact (KPI Metrics Standard) -->
        <div class="dossier-card">
          <div class="card-header-bar">
            <div>
              <h2 class="card-section-title">Leave Balance &amp; Entitlement</h2>
              <p class="card-section-subtitle">Annual quota position, active cycle utilization, and projected post-approval balance.</p>
            </div>
            <span class="allocation-badge">{{ currentItem.allocation_code }}</span>
          </div>

          <!-- 4-Card KPI Grid (Standard MetricCard Component) -->
          <div class="balance-kpi-grid">
            <MetricCard
              label="ANNUAL ENTITLED"
              :value="currentItem.entitled_days.toFixed(1) + ' Days'"
              subtext="FY 2026/27 Accrual Quota"
              :icon="Award"
              :showMenu="false"
            />
            <MetricCard
              label="TAKEN TO DATE"
              :value="currentItem.taken_days.toFixed(1) + ' Days'"
              subtext="Utilized absence this cycle"
              :icon="CheckCircle2"
              :showMenu="false"
            />
            <MetricCard
              label="CURRENTLY AVAILABLE"
              :value="currentItem.available_days.toFixed(1) + ' Days'"
              subtext="Net of 2.5d other pending"
              :icon="Clock"
              :showMenu="false"
            />
            <MetricCard
              label="PROJECTED BALANCE"
              :value="(currentItem.available_days - (currentItem.approved_days ?? currentItem.requested_days)).toFixed(1) + ' Days'"
              subtext="Remaining after this request"
              :icon="Calendar"
              :showMenu="false"
              class="metric-projected"
            />
          </div>

          <!-- Entitlement Reference Strip -->
          <div class="balance-meta-strip">
            <div class="bms-item">
              <span class="bms-label">Debited Allocation</span>
              <span class="bms-value font-mono">{{ currentItem.allocation_code }}</span>
            </div>
            <div class="bms-item">
              <span class="bms-label">Period Validity</span>
              <span class="bms-value">{{ currentItem.period_start }} &ndash; {{ currentItem.period_end }}</span>
            </div>
            <div class="bms-item">
              <span class="bms-label">Compensation Tier</span>
              <span class="bms-value">{{ currentItem.is_paid ? '100% Fully Paid Absence' : 'Unpaid Absence' }}</span>
            </div>
            <div class="bms-item">
              <span class="bms-label">Biometric Marking</span>
              <span class="bms-value text-emerald-600 font-medium">Scheduled Leave (On Leave)</span>
            </div>
          </div>
        </div>

        <!-- 3. Rationale & Operational Handover Card -->
        <div class="dossier-card">
          <div class="card-header-bar">
            <div>
              <h2 class="card-section-title">Leave Rationale &amp; Operational Handover</h2>
              <p class="card-section-subtitle">Employee justification, relief delegate arrangements, and duty resumption schedule.</p>
            </div>
            <div v-if="currentItem.has_attachment" class="attachment-pill">
              <FileText :size="13" class="text-blue-600" />
              <span class="att-filename">{{ currentItem.attachment_name }}</span>
              <span class="att-filesize">({{ currentItem.attachment_size }})</span>
            </div>
          </div>

          <!-- Quoted Reason Box -->
          <div class="reason-quote-box">
            <div class="quote-accent-bar"></div>
            <div class="quote-content">
              <span class="quote-label">Employee Statement of Purpose</span>
              <p class="quote-text">&ldquo;{{ currentItem.reason }}&rdquo;</p>
            </div>
          </div>

          <!-- Handover & Shift Coverage Parameters -->
          <div class="handover-grid">
            <div class="handover-cell">
              <span class="h-label">Handover Colleague</span>
              <div class="h-val-row">
                <span class="h-val">{{ currentItem.handover_employee_name }}</span>
                <span class="h-role">({{ currentItem.handover_employee_role }})</span>
                <span v-if="currentItem.handover_confirmed" class="h-verified-tag">
                  <Check :size="11" />
                  <span>Cover Confirmed</span>
                </span>
              </div>
            </div>

            <div class="handover-cell">
              <span class="h-label">Shift Work Pattern</span>
              <span class="h-val">{{ currentItem.shift_name }}</span>
            </div>

            <div class="handover-cell">
              <span class="h-label">Expected Return to Duty</span>
              <span class="h-val h-highlight">Wednesday, Aug 12, 2026 (08:30 AM)</span>
            </div>

            <div class="handover-cell">
              <span class="h-label">Duty Handover Scope</span>
              <span class="h-val">Branch registers reconciled &amp; key custody surrendered</span>
            </div>
          </div>
        </div>

        <!-- 4. Exploded Daily Attendance Schedule -->
        <div class="dossier-card">
          <div class="card-header-bar">
            <div>
              <h2 class="card-section-title">Daily Attendance Schedule</h2>
              <p class="card-section-subtitle">Calendar day breakdown debited from leave balance (LeaveRequestDay).</p>
            </div>
            <span class="schedule-count-pill">{{ currentItem.days.length }} Days Total</span>
          </div>

          <table class="erp-table">
            <thead>
              <tr>
                <th style="width: 48px;">#</th>
                <th>Date</th>
                <th>Day of Week</th>
                <th>Shift Portion</th>
                <th>Duration Value</th>
                <th>Biometric Attendance Marking</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(day, idx) in currentItem.days" :key="day.id">
                <td class="td-tertiary">{{ idx + 1 }}</td>
                <td class="td-primary-name">{{ day.date }}</td>
                <td class="td-tertiary">{{ day.day_name }}</td>
                <td class="td-tertiary">{{ day.portion }}</td>
                <td class="td-tertiary">{{ day.day_value.toFixed(2) }} Days</td>
                <td>
                  <span class="attendance-pill">{{ day.attendance_status }}</span>
                </td>
              </tr>
            </tbody>
          </table>

          <!-- Return to Duty audit row if completed/taken -->
          <div v-if="currentItem.actual_return_date || currentItem.recalled_at" class="return-record-box">
            <div v-if="currentItem.actual_return_date" class="return-row">
              <CornerDownLeft :size="14" class="text-blue-600" />
              <span class="ret-k">Resumed Duty On:</span>
              <span class="ret-v">{{ currentItem.actual_return_date }}</span>
            </div>
            <div v-if="currentItem.recalled_at" class="return-row">
              <AlertCircle :size="14" class="text-amber-600" />
              <span class="ret-k">Recalled By Operations:</span>
              <span class="ret-v">{{ currentItem.recalled_at }}</span>
              <span class="ret-sub">&mdash; {{ currentItem.recall_reason }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- ═════════════════════════════════════════════════════════════
           RIGHT COLUMN: Approver Action Card & Approval Workflow Chain
           ═════════════════════════════════════════════════════════════ -->
      <div class="approval-rail-column">
        <!-- 1. Approver Decision Sign-off Card -->
        <div class="rail-card">
          <div class="rail-header">
            <div>
              <h3 class="rail-title">Approver Decision</h3>
              <p class="rail-subtitle">Authorized review for {{ currentItem.current_step_name }}.</p>
            </div>
          </div>

          <div class="decision-form-stack">
            <div class="form-field-wrapper">
              <FormSelect
                v-model="resolution"
                label="Resolution"
                :options="resolutionOptions"
                :required="true"
              />
            </div>

            <div v-if="resolution === 'modify'" class="form-field-wrapper">
              <FormInput
                v-model="approvedDaysInput"
                type="number"
                label="Adjusted Approved Days"
                :required="true"
                hint="Specify granted days (numeric 6,2 per schema approved_days)."
              />
            </div>

            <div class="form-field-wrapper">
              <label class="field-label">Remarks</label>
              <textarea
                v-model="decisionRemark"
                class="decision-textarea"
                rows="3"
              />
            </div>

            <AppButton
              variant="primary"
              size="md"
              :disabled="isSubmittingDecision"
              :loading="isSubmittingDecision"
              @click="handleSubmitDecision"
            >
              Submit Decision
            </AppButton>
          </div>
        </div>

        <!-- 2. Sequential Approval Workflow Timeline -->
        <div class="rail-card">
          <div class="rail-header">
            <div>
              <h3 class="rail-title">Approval Workflow</h3>
              <p class="rail-subtitle">Sequential multi-stage authorization chain.</p>
            </div>
          </div>

          <div class="approval-timeline">
            <div
              v-for="(step, idx) in currentItem.approvals"
              :key="step.id"
              class="timeline-item"
              :class="`step-${step.approval_state}`"
            >
              <div v-if="idx < currentItem.approvals.length - 1" class="timeline-line"></div>
              
              <div class="timeline-badge">
                <Check v-if="step.approval_state === 'approved'" :size="13" />
                <Clock v-else-if="step.approval_state === 'pending'" :size="13" />
                <X v-else-if="step.approval_state === 'rejected'" :size="13" />
                <span v-else class="bullet-queued"></span>
              </div>

              <div class="timeline-content">
                <div class="step-top-line">
                  <span class="step-name">{{ step.step_name }}</span>
                  <span class="step-status-tag" :class="`tag-${step.approval_state}`">
                    {{ step.approval_state === 'pending' ? 'Pending' : step.approval_state }}
                  </span>
                </div>

                <span class="step-approver">{{ step.approver_name }} &bull; {{ step.approver_role }}</span>
                
                <span v-if="step.acted_at" class="step-time">{{ step.acted_at }}</span>
                <span v-else-if="step.approval_state === 'pending'" class="step-time text-pending">
                  Awaiting Decision (Current Step)
                </span>
                <span v-else class="step-time text-queued">Queued for Next Review</span>

                <div v-if="step.remarks" class="step-remarks-box">
                  <p class="step-remarks-text">&ldquo;{{ step.remarks }}&rdquo;</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.leave-detail-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: var(--alias-color-bg-canvas, #f8fafc);
  min-height: 100vh;
}

/* ═══ Top Bar Navigation (Clean & Standard) ═══ */
.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.top-nav-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.btn-back-nav {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 500;
  color: #0B529C;
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 4px 6px;
  border-radius: 6px;
  transition: background-color 0.15s;
}

.btn-back-nav:hover {
  background-color: #f1f5f9;
}

.divider-v {
  width: 1px;
  height: 18px;
  background-color: #cbd5e1;
}

.top-nav-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-secondary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 14px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-secondary-action:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.btn-danger-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 14px;
  font-size: 13px;
  font-weight: 500;
  color: #dc2626;
  background-color: #ffffff;
  border: 1px solid #fecaca;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-danger-action:hover {
  background-color: #fef2f2;
  border-color: #fca5a5;
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

/* ═══ Master Split Layout ═══ */
.detail-split-layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 380px;
  gap: 20px;
  align-items: start;
}

@media (max-width: 1100px) {
  .detail-split-layout {
    grid-template-columns: 1fr;
  }
}

.main-dossier-column {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* ═══ Dossier Card Base ═══ */
.dossier-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* ─── Hero Card ─── */
.hero-card {
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  padding: 18px 24px;
}

.hero-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.hero-avatar {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid #f1f5f9;
}

.hero-meta {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.hero-title-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.hero-name {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #404040;
}

.badge-leave-type {
  font-size: 11.5px;
  font-weight: 600;
  color: #0B529C;
  background-color: #eff6ff;
  padding: 2px 9px;
  border-radius: 4px;
}

.status-pill {
  padding: 2px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
  text-transform: capitalize;
}

.status-pending {
  background-color: #fef3c7;
  color: #d97706;
}

.status-approved {
  background-color: #ecfdf5;
  color: #059669;
}

.status-taken {
  background-color: #eff6ff;
  color: #0B529C;
}

.status-rejected {
  background-color: #fef2f2;
  color: #dc2626;
}

.status-draft {
  background-color: #f1f5f9;
  color: #64748b;
}

.badge-paid {
  font-size: 11px;
  font-weight: 500;
  color: #059669;
  background-color: #ecfdf5;
  padding: 2px 8px;
  border-radius: 4px;
}

.hero-subtext {
  margin: 0;
  font-size: 12.5px;
  color: #737373;
}

.hero-right {
  display: flex;
  align-items: center;
  gap: 24px;
  flex-shrink: 0;
}

.meta-stat-block {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
}

.meta-label {
  font-size: 11px;
  color: #737373;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  font-weight: 500;
}

.meta-value {
  font-size: 13.5px;
  color: #404040;
  font-weight: 500;
}

.font-bold-duration {
  font-weight: 700;
  color: #0B529C;
}

/* ─── Card Header Bar ─── */
.card-header-bar {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.card-section-title {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.card-section-subtitle {
  margin: 2px 0 0 0;
  font-size: 12px;
  color: #737373;
}

.allocation-badge {
  font-size: 11.5px;
  font-weight: 500;
  color: #0B529C;
  background-color: #eff6ff;
  padding: 3px 10px;
  border-radius: 6px;
  white-space: nowrap;
}

/* ─── Balance KPI Grid ─── */
.balance-kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}

@media (max-width: 900px) {
  .balance-kpi-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

:deep(.metric-projected) {
  border-left: 3px solid #0B529C;
}

:deep(.metric-projected .metric-value) {
  color: #0B529C !important;
}

.balance-meta-strip {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
  padding-top: 14px;
  border-top: 1px solid #f1f5f9;
}

@media (max-width: 900px) {
  .balance-meta-strip {
    grid-template-columns: 1fr 1fr;
  }
}

.bms-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.bms-label {
  font-size: 11px;
  color: #737373;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.bms-value {
  font-size: 12.5px;
  color: #404040;
  font-weight: 500;
}

/* ─── Reason & Handover Card ─── */
.attachment-pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 12px;
  color: #404040;
}

.att-filename {
  font-weight: 500;
  color: #0B529C;
}

.att-filesize {
  color: #737373;
  font-size: 11px;
}

.reason-quote-box {
  display: flex;
  gap: 12px;
  background-color: #f8fafc;
  border-radius: 8px;
  padding: 14px 18px;
}

.quote-accent-bar {
  width: 3px;
  background-color: #0B529C;
  border-radius: 2px;
  flex-shrink: 0;
  align-self: stretch;
}

.quote-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.quote-label {
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #737373;
}

.quote-text {
  margin: 0;
  font-size: 13.5px;
  color: #404040;
  line-height: 1.55;
  font-style: italic;
}

.handover-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px 20px;
  padding-top: 14px;
  border-top: 1px solid #f1f5f9;
}

@media (max-width: 768px) {
  .handover-grid {
    grid-template-columns: 1fr;
  }
}

.handover-cell {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.h-label {
  font-size: 11px;
  color: #737373;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.h-val-row {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.h-val {
  font-size: 13px;
  color: #404040;
  font-weight: 500;
}

.h-role {
  font-size: 12px;
  color: #737373;
}

.h-verified-tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  font-weight: 500;
  color: #059669;
  background-color: #ecfdf5;
  padding: 1px 7px;
  border-radius: 4px;
}

.h-highlight {
  color: #0B529C;
  font-weight: 600;
}

/* ─── Schedule Card Table ─── */
.schedule-count-pill {
  font-size: 11.5px;
  font-weight: 500;
  color: #737373;
  background-color: #f1f5f9;
  padding: 2px 8px;
  border-radius: 4px;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table th {
  background-color: #fafafa;
  color: #737373;
  font-size: 12px;
  font-weight: 500;
  padding: 8px 16px;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
  height: 34px;
}

.erp-table td {
  padding: 8px 16px;
  font-size: 13px;
  border-bottom: 1px solid #f1f5f9;
  height: 38px;
}

.td-primary-name {
  color: #404040;
  font-weight: 600;
}

.td-tertiary {
  color: #737373;
}

.attendance-pill {
  display: inline-block;
  padding: 2px 9px;
  border-radius: 4px;
  background-color: #ecfdf5;
  color: #059669;
  font-size: 11.5px;
  font-weight: 500;
}

.return-record-box {
  background-color: #f8fafc;
  border-radius: 8px;
  padding: 10px 14px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.return-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12.5px;
}

.ret-k {
  color: #737373;
}

.ret-v {
  font-weight: 600;
  color: #404040;
}

.ret-sub {
  color: #737373;
}

/* ═════════════════════════════════════════════════════════════
   RIGHT COLUMN: Approver Action Card & Approval Rail
   ═════════════════════════════════════════════════════════════ */
.approval-rail-column {
  display: flex;
  flex-direction: column;
  gap: 16px;
  position: sticky;
  top: 20px;
}

.rail-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 18px 20px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.rail-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding-bottom: 12px;
  border-bottom: 1px solid #f1f5f9;
}

.rail-title {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.rail-subtitle {
  margin: 2px 0 0 0;
  font-size: 11.5px;
  color: #737373;
}

/* Decision Form */
.decision-form-stack {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.form-field-wrapper {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.decision-textarea {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 12px;
  font-size: 13.5px;
  color: #404040;
  outline: none;
  resize: vertical;
  min-height: 76px;
  font-family: inherit;
  transition: border-color 0.15s, box-shadow 0.15s;
}

.decision-textarea:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.btn-submit-decision {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 38px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-submit-decision:hover {
  background-color: #094380;
}

.btn-submit-decision:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Timeline */
.approval-timeline {
  display: flex;
  flex-direction: column;
  gap: 0;
  margin-top: 4px;
}

.timeline-item {
  position: relative;
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding-bottom: 22px;
}

.timeline-item:last-child {
  padding-bottom: 4px;
}

.timeline-line {
  position: absolute;
  top: 24px;
  left: 12px;
  bottom: 0;
  width: 2px;
  background-color: #e2e8f0;
}

.timeline-badge {
  position: relative;
  z-index: 1;
  width: 26px;
  height: 26px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 600;
  flex-shrink: 0;
  background-color: #f1f5f9;
  color: #64748b;
  border: 2px solid #ffffff;
  box-shadow: 0 0 0 1px #cbd5e1;
}

.step-approved .timeline-badge {
  background-color: #10b981;
  color: #ffffff;
  box-shadow: 0 0 0 1px #10b981;
}

.step-rejected .timeline-badge {
  background-color: #ef4444;
  color: #ffffff;
  box-shadow: 0 0 0 1px #ef4444;
}

.step-pending .timeline-badge {
  background-color: #0B529C;
  color: #ffffff;
  box-shadow: 0 0 0 1px #0B529C;
}

.bullet-queued {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background-color: #94a3b8;
}

.timeline-content {
  display: flex;
  flex-direction: column;
  gap: 3px;
  flex: 1;
}

.step-top-line {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.step-name {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.step-status-tag {
  font-size: 10.5px;
  font-weight: 600;
  padding: 1px 8px;
  border-radius: 4px;
  text-transform: capitalize;
}

.tag-approved {
  background-color: #ecfdf5;
  color: #059669;
}

.tag-pending {
  background-color: #eff6ff;
  color: #0B529C;
}

.tag-rejected {
  background-color: #fef2f2;
  color: #dc2626;
}

.tag-queued {
  background-color: #f8fafc;
  color: #94a3b8;
}

.step-approver {
  font-size: 11.5px;
  color: #737373;
}

.step-time {
  font-size: 11px;
  color: #94a3b8;
}

.text-pending {
  color: #d97706 !important;
  font-weight: 500;
}

.text-queued {
  color: #94a3b8 !important;
}

.step-remarks-box {
  background-color: #f8fafc;
  border-radius: 6px;
  padding: 8px 12px;
  margin-top: 4px;
}

.step-remarks-text {
  margin: 0;
  font-size: 12px;
  color: #404040;
  font-style: italic;
  line-height: 1.45;
}

/* Toast animation */
.toast-fade-enter-active,
.toast-fade-leave-active {
  transition: opacity 0.3s ease;
}
.toast-fade-enter-from,
.toast-fade-leave-to {
  opacity: 0;
}
</style>
