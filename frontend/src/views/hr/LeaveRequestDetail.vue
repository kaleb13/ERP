<script setup lang="ts">
import { ref, computed, nextTick } from 'vue';
import { useRoute } from 'vue-router';
import {
  Check, Clock, Lock, CheckCircle2,
  PanelRightClose, PanelRightOpen,
  ShieldCheck, Printer, FileText, X, AlertCircle
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import { useToast } from '../../composables/useToast';

const route = useRoute();

// ─── Record ID from Route (Default 1002 from Figma) ───
const requestId = computed(() => Number(route.params.id) || 1002);

export interface LeaveRequestDayItem {
  id: number;
  date: string;
  day_name: string;
  portion: string;
}

export interface LeaveApprovalStepItem {
  id: number;
  step_number: number;
  step_name: string;
  approver_name: string;
  approver_role: string;
  approval_state: 'approved' | 'pending' | 'queued' | 'rejected';
  acted_at?: string;
  remarks?: string;
}

export interface LeaveRequestDetailRecord {
  id: number;
  code: string;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_role: string;
  employee_dept: string;
  employee_avatar: string;
  leave_type_name: string;
  duration_text: string;
  requested_days: number;
  entitled_days: number;
  taken_days: number;
  available_days: number;
  allocation_code: string;
  compensation_tier: string;
  biometric_marking: string;
  reason: string;
  handover_name: string;
  handover_code: string;
  handover_role: string;
  handover_avatar: string;
  expected_return: string;
  shift_name: string;
  days: LeaveRequestDayItem[];
  approvals: LeaveApprovalStepItem[];
  request_state: 'pending' | 'approved' | 'rejected';
}

const leaveDatabase: Record<number, LeaveRequestDetailRecord> = {
  1002: {
    id: 1002,
    code: 'LVR-2026-1002',
    employee_id: 22,
    employee_name: 'Almaz Ayana',
    employee_code: 'EMP-00124',
    employee_role: 'Senior Accountant',
    employee_dept: 'Works at Bole Branch - Finance Department',
    employee_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&h=150&q=80',
    leave_type_name: 'Annual Leave',
    duration_text: '2.0 Working Days',
    requested_days: 2.0,
    entitled_days: 18.0,
    taken_days: 0.0,
    available_days: 15.5,
    allocation_code: 'LAL-2026-0453 (FY 2026/27)',
    compensation_tier: '100% Fully Paid Absence',
    biometric_marking: 'Scheduled Leave (On Leave)',
    reason: 'Personal family matters in Debre Zeit. Cash drawer daily registers fully reconciled and branch key custody formally surrendered to shift supervisor.',
    handover_name: 'Bekele Mola',
    handover_code: 'EMP-00184',
    handover_role: 'Senior Accountant',
    handover_avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&h=120&q=80',
    expected_return: 'Wednesday, Aug 12, 2026 (08:30 AM)',
    shift_name: 'Office Shift (08:30 – 17:30)',
    days: [
      { id: 1, date: 'Sep 1, 2026', day_name: 'Monday', portion: 'Full Day' },
      { id: 2, date: 'Sep 2, 2026', day_name: 'Tuesday', portion: 'Full Day' }
    ],
    approvals: [
      {
        id: 1,
        step_number: 1,
        step_name: 'Shift Supervisor Endorsement',
        approver_name: 'Kassahun Belay',
        approver_role: 'Finance Manager',
        approval_state: 'approved',
        acted_at: 'Oct 2, 2026, 12:40 PM',
        remarks: 'Cash balances reconciled. Handover cover accepted and verified for both days.'
      },
      {
        id: 2,
        step_number: 2,
        step_name: 'HR Records & Roster Clearance',
        approver_name: 'Kassahun Belay',
        approver_role: 'HR Officer',
        approval_state: 'pending'
      },
      {
        id: 3,
        step_number: 3,
        step_name: 'HR Operations Final Sign-off',
        approver_name: 'Almaz Mengistu',
        approver_role: 'HR Operations Director',
        approval_state: 'queued'
      }
    ],
    request_state: 'pending'
  },
  732: {
    id: 732,
    code: 'LVR-2026-0732',
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-0014',
    employee_role: 'Senior Cashier',
    employee_dept: 'Works at Bole Commercial Branch - Retail Operations',
    employee_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&h=150&q=80',
    leave_type_name: 'Annual Leave',
    duration_text: '2.0 Working Days',
    requested_days: 2.0,
    entitled_days: 18.0,
    taken_days: 0.0,
    available_days: 15.5,
    allocation_code: 'LAL-2026-0453 (FY 2026/27)',
    compensation_tier: '100% Fully Paid Absence',
    biometric_marking: 'Scheduled Leave (On Leave)',
    reason: 'Personal family matters in Debre Zeit. Cash drawer daily registers fully reconciled and branch key custody formally surrendered to shift supervisor.',
    handover_name: 'Sara Tefera',
    handover_code: 'EMP-0018',
    handover_role: 'Shift Supervisor',
    handover_avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80',
    expected_return: 'Wednesday, Aug 12, 2026 (08:30 AM)',
    shift_name: 'Office Shift (08:30 – 17:30)',
    days: [
      { id: 1, date: 'Sep 1, 2026', day_name: 'Monday', portion: 'Full Day' },
      { id: 2, date: 'Sep 2, 2026', day_name: 'Tuesday', portion: 'Full Day' }
    ],
    approvals: [
      {
        id: 1,
        step_number: 1,
        step_name: 'Shift Supervisor Endorsement',
        approver_name: 'Sara Tefera',
        approver_role: 'Shift Supervisor',
        approval_state: 'approved',
        acted_at: 'Oct 2, 2026, 12:40 PM',
        remarks: 'Cash balances reconciled. Handover cover accepted and verified for both days.'
      },
      {
        id: 2,
        step_number: 2,
        step_name: 'HR Records & Roster Clearance',
        approver_name: 'Kassahun Belay',
        approver_role: 'HR Officer',
        approval_state: 'pending'
      },
      {
        id: 3,
        step_number: 3,
        step_name: 'HR Operations Final Sign-off',
        approver_name: 'Almaz Mengistu',
        approver_role: 'HR Operations Director',
        approval_state: 'queued'
      }
    ],
    request_state: 'pending'
  }
};

const currentItem = computed<LeaveRequestDetailRecord>(() => {
  return leaveDatabase[requestId.value] || leaveDatabase[1002];
});

// ─── Breadcrumb Items (Figma Node 7009:114556: Transparent Canvas Standard) ───
const breadcrumbItems = computed(() => [
  { label: 'Leave Requests', to: '/hr/leave-requests' },
  { label: currentItem.value.code }
]);

// ─── Decision Panel Form ───
const resolution = ref('approve');
const resolutionOptions: SelectOption[] = [
  { value: 'approve', label: 'Approve Leave Request' },
  { value: 'modify', label: 'Approve with Reduced Days' },
  { value: 'reject', label: 'Reject Leave Request' }
];

const { toast } = useToast();
const decisionRemark = ref('');
const isSubmittingDecision = ref(false);

// ─── Focus Mode State (Sidebar Minimization per Figma 9066:90379) ───
const isFocusMode = ref(false);
const remarkTextareaRef = ref<HTMLTextAreaElement | null>(null);

const toggleFocusMode = () => {
  isFocusMode.value = !isFocusMode.value;
  if (isFocusMode.value) {
    toast.info('Focus Mode Enabled', 'Approval sidebar minimized for full-width dossier review.');
  } else {
    toast.info('Approval Sidebar Restored', 'Dossier and approval action panel returned to standard layout.');
    nextTick(() => {
      remarkTextareaRef.value?.focus();
    });
  }
};

const handleSubmitDecision = () => {
  isSubmittingDecision.value = true;
  setTimeout(() => {
    isSubmittingDecision.value = false;
    const pendingStep = currentItem.value.approvals.find(s => s.approval_state === 'pending');
    if (resolution.value === 'reject') {
      if (pendingStep) {
        pendingStep.approval_state = 'rejected';
        pendingStep.acted_at = 'Just now';
        pendingStep.remarks = decisionRemark.value || 'Request rejected per operational requirements.';
      }
      currentItem.value.request_state = 'rejected';
      toast.error('Leave Request Rejected', `Leave request ${currentItem.value.code} was rejected.`);
    } else {
      // Approve all remaining steps once approved per user design requirement
      currentItem.value.approvals.forEach((step, idx) => {
        if (step.approval_state !== 'approved') {
          step.approval_state = 'approved';
          step.acted_at = 'Just now';
          step.remarks = decisionRemark.value || (idx === 1 ? 'Records cleared and verified.' : 'Authorized and endorsed by HR Operations.');
        }
      });
      currentItem.value.request_state = 'approved';
      toast.success('Leave Request Approved', `Leave request ${currentItem.value.code} has been fully approved.`);
    }
    decisionRemark.value = '';
  }, 400);
};

// ─── Stepper States & Reactive Connector Line Calculation ───
const step1State = computed(() => {
  return currentItem.value.approvals[0]?.approval_state || 'approved';
});
const step2State = computed(() => {
  return currentItem.value.approvals[1]?.approval_state || 'pending';
});
const step3State = computed(() => {
  return currentItem.value.approvals[2]?.approval_state || 'queued';
});

const getConnectorLineClass = (fromState: string, toState: string): string => {
  if (fromState === 'approved' && toState === 'approved') return 'step-line-solid-blue';
  if (fromState === 'approved' && toState === 'pending') return 'step-line-gradient-blue-to-orange';
  if (fromState === 'approved' && toState === 'rejected') return 'step-line-gradient-blue-to-red';
  if (fromState === 'pending' && toState === 'queued') return 'step-line-gradient-orange-to-gray';
  if (fromState === 'pending' && toState === 'approved') return 'step-line-solid-blue';
  if (fromState === 'queued' && toState === 'queued') return 'step-line-solid-gray';
  return 'step-line-solid-blue';
};

const handlePrintSlip = () => {
  window.print();
};

const handleDownloadPass = () => {
  toast.info('Pass Generated', `Duty cover pass for ${currentItem.value.code} downloaded.`);
};
</script>

<template>
  <div class="leave-detail-page">
    <!-- Breadcrumb Bar (Strict Canvas Standard: Transparent, no card box) -->
    <div class="breadcrumb-strip">
      <AppBreadcrumb :items="breadcrumbItems" noMargin>
        <template #badge>
          <BaseBadge 
            :color="currentItem.request_state === 'approved' ? 'success' : (currentItem.request_state === 'rejected' ? 'error' : 'warning')" 
            size="sm"
          >
            {{ currentItem.request_state === 'approved' ? 'Approved & Scheduled' : (currentItem.request_state === 'rejected' ? 'Rejected' : 'Pending Authorization') }}
          </BaseBadge>
        </template>
      </AppBreadcrumb>
    </div>

    <!-- Master Two-Column Layout (Responsive Split: 1fr Left, 360px Right) -->
    <div class="detail-split-layout" :class="{ 'is-focus-mode': isFocusMode }">
      <!-- ═════════════════════════════════════════════════════════════
           LEFT COLUMN: Leave Dossier (Expands when sidebar collapsed)
           ═════════════════════════════════════════════════════════════ -->
      <div class="dossier-column">
        <!-- 1. Employee Hero Card (Figma Node 8841:36806) -->
        <div class="dossier-card hero-card">
          <div class="hero-left">
            <div class="hero-avatar-wrap">
              <img
                :src="currentItem.employee_avatar"
                :alt="currentItem.employee_name"
                class="hero-avatar-img"
              />
            </div>
            <div class="hero-info">
              <div class="hero-name-row">
                <span class="hero-name">{{ currentItem.employee_name }}</span>
              </div>
              <div class="hero-id-row">
                <span class="hero-code">{{ currentItem.employee_code }} -</span>
                <BaseBadge color="gray" size="sm">
                  {{ currentItem.employee_role }}
                </BaseBadge>
              </div>
              <p class="hero-dept">{{ currentItem.employee_dept }}</p>
            </div>
          </div>

          <div class="hero-right">
            <p class="meta-line">
              <span class="meta-label">Duration : </span>
              <span class="meta-value-bold">{{ currentItem.duration_text }}</span>
            </p>
            <p class="meta-line">
              <span class="meta-label">Request ID: </span>
              <span class="meta-value">{{ currentItem.code }}</span>
            </p>
            <div class="meta-leave-type-row">
              <span class="meta-label">Leave Type :</span>
              <BaseBadge color="primary" size="sm">
                {{ currentItem.leave_type_name }}
              </BaseBadge>
            </div>
          </div>
        </div>

        <!-- 2. Leave Balance & Entitlement Card (Figma Node 7009:114582) -->
        <div class="dossier-card">
          <div class="card-title-block">
            <h2 class="card-title">Leave Balance &amp; Entitlement</h2>
            <p class="card-desc">Annual quota position, active cycle utilization, and projected post-approval balance.</p>
          </div>

          <div class="kpi-grid">
            <!-- 1. Annual Entitled -->
            <div class="kpi-card">
              <span class="kpi-label">ANNUAL ENTITLED</span>
              <span class="kpi-value">{{ currentItem.entitled_days.toFixed(1) }} Days</span>
              <span class="kpi-sub">FY 2026/27 Accrual Quota</span>
            </div>

            <!-- 2. Taken to Date -->
            <div class="kpi-card">
              <span class="kpi-label">TAKEN TO DATE</span>
              <span class="kpi-value">{{ currentItem.taken_days.toFixed(0) }} Days</span>
              <span class="kpi-sub">Utilized absence this cycle</span>
            </div>

            <!-- 3. Currently Available -->
            <div class="kpi-card">
              <span class="kpi-label">CURRENTLY AVAILABLE</span>
              <span class="kpi-value">{{ currentItem.available_days.toFixed(1) }} Days</span>
              <span class="kpi-sub">Net of 2.5d other pending</span>
            </div>

            <!-- 4. Requested Balance (Brand Blue Highlight Card) -->
            <div class="kpi-card kpi-card-brand">
              <span class="kpi-label">REQUESTED BALANCE</span>
              <span class="kpi-value kpi-value-brand">{{ currentItem.requested_days.toFixed(1) }} Days</span>
              <span class="kpi-sub">Requested Leave days</span>
            </div>
          </div>
        </div>

        <!-- 3. Allocation & Compensation Tier Card (Figma Node 7009:114608) -->
        <div class="dossier-card key-params-card">
          <div class="param-item">
            <span class="param-label">Debited Allocation</span>
            <span class="param-val">{{ currentItem.allocation_code }}</span>
          </div>

          <div class="param-item">
            <span class="param-label">Compensation Tier</span>
            <span class="param-val">{{ currentItem.compensation_tier }}</span>
          </div>

          <div class="param-item">
            <span class="param-label">Biometric Marking</span>
            <span class="param-val">{{ currentItem.biometric_marking }}</span>
          </div>
        </div>

        <!-- 4. Leave Rationale & Operational Handover Card (Figma Node 7009:114622) -->
        <div class="dossier-card">
          <div class="card-title-block">
            <h2 class="card-title">Leave Rationale &amp; Operational Handover</h2>
            <p class="card-desc">Employee justification, relief delegate arrangements, and duty resumption schedule.</p>
          </div>

          <!-- Quoted Reason Box -->
          <div class="statement-box">
            <p class="statement-text">&ldquo;{{ currentItem.reason }}&rdquo;</p>
          </div>

          <!-- Handover 3-Column Strip -->
          <div class="handover-strip">
            <div class="param-item">
              <span class="param-label">Handover Colleague</span>
              <div class="handover-user">
                <img :src="currentItem.handover_avatar" :alt="currentItem.handover_name" class="handover-avatar" />
                <div class="handover-meta">
                  <span class="handover-name">{{ currentItem.handover_name }}</span>
                  <span class="handover-role">{{ currentItem.handover_code }} - {{ currentItem.handover_role }}</span>
                </div>
              </div>
            </div>

            <div class="param-item">
              <span class="param-label">Expected Return to Duty</span>
              <span class="param-val">{{ currentItem.expected_return }}</span>
            </div>

            <div class="param-item">
              <span class="param-label">Shift Work Pattern</span>
              <span class="param-val">{{ currentItem.shift_name }}</span>
            </div>
          </div>
        </div>

        <!-- 5. Daily Attendance Schedule Table (Figma Node 7009:114645) -->
        <div class="dossier-card">
          <div class="card-title-block">
            <h2 class="card-title">Daily Attendance Schedule</h2>
            <p class="card-desc">Calendar day breakdown debited from leave balance.</p>
          </div>

          <div class="schedule-table-wrap">
            <table class="schedule-table">
              <thead>
                <tr>
                  <th class="th-no">No.</th>
                  <th class="th-date">Date</th>
                  <th class="th-day">Day of the Week</th>
                  <th class="th-portion">Shift Portion</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(day, idx) in currentItem.days" :key="day.id">
                  <td class="td-no">{{ idx + 1 }}</td>
                  <td class="td-date">{{ day.date }}</td>
                  <td class="td-day">{{ day.day_name }}</td>
                  <td class="td-portion">{{ day.portion }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- ═════════════════════════════════════════════════════════════
           RIGHT COLUMN: Approval Timeline & Decision Panel (360px)
           (Figma Node 7009:114669)
           ═════════════════════════════════════════════════════════════ -->
      <aside class="approval-rail" :class="{ 'is-collapsed': isFocusMode }">
        <!-- Collapsed Rail State (Figma Node 9066:90727) -->
        <div v-if="isFocusMode" class="rail-card rail-card-collapsed">
          <button 
            type="button"
            class="btn-sidebar-collapsed"
            @click="toggleFocusMode"
            title="Expand approval sidebar"
            aria-label="Expand approval sidebar"
          >
            <PanelRightOpen :size="20" />
          </button>
        </div>

        <!-- Expanded Full Rail State (Figma Node 7009:114669) -->
        <div v-else class="rail-card">
          <!-- Top Focus Button (Figma Node 7009:114670) -->
          <div class="focus-btn-row">
            <button 
              type="button"
              class="btn-focus"
              @click="toggleFocusMode"
              title="Minimize sidebar to focus on dossier"
              aria-label="Minimize sidebar to focus on dossier"
            >
              <PanelRightClose :size="18" class="btn-focus-icon" />
              <span>Focus</span>
            </button>
          </div>

          <!-- ──────────────────────────────────────────────────────────
               SECTION 1: APPROVER DECISION OR CERTIFIED SIGNOFF BY STATUS
               ────────────────────────────────────────────────────────── -->

          <!-- STATE A: PENDING / DRAFT (Active Interactive Approver Form) -->
          <div v-if="currentItem.request_state === 'pending' || currentItem.request_state === 'draft'" class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Approver Decision</h3>
              <p class="section-desc">You are authorized to sign off on this employee leave request. Please enter optional remarks before submitting your decision.</p>
            </div>

            <div class="decision-form">
              <div class="form-group">
                <label class="form-label required">Resolution</label>
                <FormSelect
                  v-model="resolution"
                  :options="resolutionOptions"
                  placeholder="Select resolution"
                />
              </div>

              <div class="form-group">
                <label class="form-label">Remark</label>
                <textarea
                  ref="remarkTextareaRef"
                  v-model="decisionRemark"
                  class="remark-textarea"
                  placeholder="Enter your decision reason..."
                  rows="3"
                />
              </div>

              <AppButton
                variant="primary"
                size="md"
                class="btn-submit-decision"
                :loading="isSubmittingDecision"
                :disabled="isSubmittingDecision"
                @click="handleSubmitDecision"
              >
                Submit Decision
              </AppButton>
            </div>
          </div>

          <!-- STATE B: APPROVED (Official Certified Seal & Management Actions) -->
          <div v-else-if="currentItem.request_state === 'approved'" class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Certified Authorization</h3>
              <p class="section-desc">Fully authorized through all supervisory gates and recorded in the attendance calendar.</p>
            </div>

            <!-- Certified Seal Card -->
            <div class="certified-signoff-card">
              <div class="seal-header">
                <div class="seal-icon-wrap">
                  <ShieldCheck :size="20" class="seal-icon" />
                </div>
                <div class="seal-titles">
                  <span class="seal-heading">Approved &amp; Scheduled</span>
                  <span class="seal-meta-date">Certified: Oct 2, 2026, 12:40 PM</span>
                </div>
              </div>

              <!-- Signatory Info -->
              <div class="signatory-row">
                <img 
                  src="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=120&h=120&q=80" 
                  alt="Almaz Mengistu" 
                  class="signatory-avatar" 
                />
                <div class="signatory-meta">
                  <span class="signatory-name">Almaz Mengistu</span>
                  <span class="signatory-role">HR Operations Director</span>
                </div>
              </div>

              <!-- Approver Endorsement Quote -->
              <div class="approval-quote-box">
                <p class="approval-quote-text">&ldquo;{{ decisionRemark || 'Leave balance verified. Duty roster adjusted and branch relief colleague confirmed.' }}&rdquo;</p>
              </div>
            </div>

            <!-- Contextual Actions -->
            <div class="context-actions-stack">
              <AppButton
                variant="outline"
                size="sm"
                class="w-full"
                @click="handlePrintSlip"
              >
                <template #icon-left><Printer :size="14" /></template>
                Print Leave Authorization Slip
              </AppButton>

              <AppButton
                variant="outline"
                size="sm"
                class="w-full"
                @click="handleDownloadPass"
              >
                <template #icon-left><FileText :size="14" /></template>
                Download Duty Cover Pass
              </AppButton>
            </div>
          </div>

          <!-- STATE C: REJECTED -->
          <div v-else-if="currentItem.request_state === 'rejected'" class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Request Rejected</h3>
              <p class="section-desc">Absence authorization has been denied per departmental exigency.</p>
            </div>

            <div class="rejected-signoff-card">
              <div class="seal-header">
                <div class="seal-icon-wrap seal-icon-wrap-rejected">
                  <X :size="20" class="seal-icon-rejected" />
                </div>
                <div class="seal-titles">
                  <span class="seal-heading text-danger">Authorization Denied</span>
                  <span class="seal-meta-date">Rejected: Just now</span>
                </div>
              </div>
              <div class="approval-quote-box">
                <p class="approval-quote-text">&ldquo;{{ decisionRemark || 'Peak branch operation requires uninterrupted attendance during month-end closing.' }}&rdquo;</p>
              </div>
            </div>

            <AppButton
              variant="outline"
              size="sm"
              class="w-full"
              @click="handlePrintSlip"
            >
              <template #icon-left><Printer :size="14" /></template>
              Print Rejection Memo
            </AppButton>
          </div>

          <hr class="rail-divider" />

          <!-- Section 2: Approval Steps -->
          <div class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Approval Steps</h3>
              <p class="section-desc">Sequential multi-stage authorization workflow.</p>
            </div>

            <!-- Workflow Stepper Container (Figma Node 7009:114683) -->
            <div class="stepper-wrap">
              <!-- Left Track with Step Circles and Connector Lines (Figma Node 7009:114684) -->
              <div class="stepper-track">
                <!-- Step 1 Icon -->
                <div class="step-circle" :class="'step-circle-' + step1State" :title="step1State">
                  <Check v-if="step1State === 'approved'" :size="20" class="step-icon-white" :stroke-width="2.5" />
                  <Clock v-else-if="step1State === 'pending'" :size="20" class="step-icon-white" :stroke-width="2" />
                  <X v-else-if="step1State === 'rejected'" :size="20" class="step-icon-white" :stroke-width="2.5" />
                  <Clock v-else :size="20" class="step-icon-disabled" :stroke-width="2" />
                </div>
                
                <!-- Connector Line 1: Step 1 -> Step 2 (Solid Blue if both approved; Gradient if opposite) -->
                <div class="step-line-1" :class="getConnectorLineClass(step1State, step2State)"></div>

                <!-- Step 2 Icon -->
                <div class="step-circle" :class="'step-circle-' + step2State" :title="step2State">
                  <Check v-if="step2State === 'approved'" :size="20" class="step-icon-white" :stroke-width="2.5" />
                  <Clock v-else-if="step2State === 'pending'" :size="20" class="step-icon-white" :stroke-width="2" />
                  <X v-else-if="step2State === 'rejected'" :size="20" class="step-icon-white" :stroke-width="2.5" />
                  <Clock v-else :size="20" class="step-icon-disabled" :stroke-width="2" />
                </div>
                
                <!-- Connector Line 2: Step 2 -> Step 3 (Solid Blue if both approved; Gradient if opposite) -->
                <div class="step-line-2" :class="getConnectorLineClass(step2State, step3State)"></div>

                <!-- Step 3 Icon -->
                <div class="step-circle" :class="'step-circle-' + step3State" :title="step3State">
                  <Check v-if="step3State === 'approved'" :size="20" class="step-icon-white" :stroke-width="2.5" />
                  <Clock v-else-if="step3State === 'pending'" :size="20" class="step-icon-white" :stroke-width="2" />
                  <X v-else-if="step3State === 'rejected'" :size="20" class="step-icon-white" :stroke-width="2.5" />
                  <Clock v-else :size="20" class="step-icon-disabled" :stroke-width="2" />
                </div>
              </div>

              <!-- Right Content Cards Stack (Figma Node 7009:114693) -->
              <div class="stepper-content">
                <!-- Step 1 Card: Shift Supervisor Endorsement -->
                <div class="step-card">
                  <div class="step-meta">
                    <span class="step-title">Shift Supervisor Endorsement</span>
                    <span class="step-actor">Kassahun Belay (Finance Manager)</span>
                    <span class="step-time">Oct 2, 2026, 12:40 PM</span>
                  </div>
                  <div class="step-quote-box">
                    <p class="step-quote-text">&ldquo;Cash balances reconciled. Handover cover accepted and verified for both days.&rdquo;</p>
                  </div>
                </div>

                <!-- Step 2 Card: HR Records & Roster Clearance -->
                <div class="step-card">
                  <div class="step-meta" :class="{ 'step-meta-queued': step2State === 'queued' }">
                    <span class="step-title" :class="{ 'text-muted': step2State === 'queued' }">HR Records &amp; Roster Clearance</span>
                    <span class="step-actor" :class="{ 'text-muted': step2State === 'queued' }">Kassahun Belay &bull; HR Officer</span>
                    <span v-if="step2State === 'approved'" class="step-time">Oct 2, 2026, 01:15 PM</span>
                  </div>
                  <div v-if="step2State === 'approved'" class="step-quote-box">
                    <p class="step-quote-text">&ldquo;Roster schedule checked and absence dates recorded in branch roster.&rdquo;</p>
                  </div>
                </div>

                <!-- Step 3 Card: HR Operations Final Sign-off -->
                <div class="step-card">
                  <div class="step-meta" :class="{ 'step-meta-queued': step3State === 'queued' }">
                    <span class="step-title" :class="{ 'text-muted': step3State === 'queued' }">HR Operations Final Sign-off</span>
                    <span class="step-actor" :class="{ 'text-muted': step3State === 'queued' }">Almaz Mengistu (HR Operations Director)</span>
                    <span v-if="step3State === 'approved'" class="step-time">Oct 2, 2026, 02:30 PM</span>
                  </div>
                  <div v-if="step3State === 'approved'" class="step-quote-box">
                    <p class="step-quote-text">&ldquo;Statutory leave certified and committed to attendance database.&rdquo;</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </aside>
    </div>
  </div>
</template>

<style scoped>
.leave-detail-page {
  display: flex;
  flex-direction: column;
  gap: 24px;
  padding: 0;
  background-color: var(--color-background-primary, #fafafa);
  min-height: 100vh;
}

/* ─── Top Breadcrumb Navigation (Canvas Standard) ─── */
.breadcrumb-strip {
  display: flex;
  align-items: center;
  background: transparent;
  border: none;
  box-shadow: none;
  padding: 0;
  width: 100%;
}

/* ─── Two-Column Split Layout (Full-Width Fluid Master-Detail) ─── */
.detail-split-layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 360px;
  gap: 24px;
  align-items: start;
  width: 100%;
  transition: grid-template-columns 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

.detail-split-layout.is-focus-mode {
  grid-template-columns: minmax(0, 1fr) 68px;
}

.dossier-column {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 24px;
  width: 100%;
}

.approval-rail {
  width: 100%;
  max-width: 360px;
  transition: max-width 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

.approval-rail.is-collapsed {
  max-width: 68px;
  width: 68px;
}

@media (max-width: 1100px) {
  .detail-split-layout {
    grid-template-columns: 1fr;
  }
  .detail-split-layout.is-focus-mode {
    grid-template-columns: 1fr;
  }
  .approval-rail {
    max-width: 100%;
  }
  .approval-rail.is-collapsed {
    max-width: 100%;
    width: 100%;
  }
}

/* ─── Dossier Card Standard (Figma: rounded-16px, border #e5e5e5, white) ─── */
.dossier-card {
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* ─── 1. Employee Hero Card (Figma Node 8841:36806) ─── */
.hero-card {
  padding: 20px 24px;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
}

.hero-left {
  display: flex;
  gap: 20px;
  align-items: center;
}

.hero-avatar-wrap {
  width: 76px;
  height: 76px;
  border-radius: 9999px;
  border: 2.26px solid #ffffff;
  box-shadow: 0 6.78px 9.04px -2.26px rgba(10, 13, 18, 0.08), 0 2.26px 3.39px -1.13px rgba(10, 13, 18, 0.03);
  overflow: hidden;
  flex-shrink: 0;
}

.hero-avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.hero-info {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.hero-name-row {
  display: flex;
  align-items: center;
}

.hero-name {
  font-size: 16px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  line-height: 24px;
}

.hero-id-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.hero-code {
  font-size: 14px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 20px;
}

.hero-dept {
  font-size: 14px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 20px;
  margin: 0;
}

.hero-right {
  display: flex;
  flex-direction: column;
  gap: 6px;
  align-items: flex-start;
}

.meta-line {
  font-size: 14px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 20px;
  margin: 0;
}

.meta-label {
  color: var(--alias-color-text-tertiary, #737373);
}

.meta-value {
  color: var(--alias-color-text-secondary, #404040);
}

.meta-value-bold {
  color: var(--alias-color-text-secondary, #404040);
  font-weight: 500;
}

.meta-leave-type-row {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 20px;
}

/* ─── Card Section Title Block ─── */
.card-title-block {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.card-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  margin: 0;
  line-height: 24px;
}

.card-desc {
  font-size: 14px;
  color: var(--alias-color-text-tertiary, #737373);
  margin: 0;
  line-height: 20px;
}

/* ─── 2. KPI Metrics Grid (Figma Node 7009:114587) ─── */
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
}

.kpi-card {
  background-color: #ffffff;
  border: 1px solid #e9eaeb;
  border-radius: 16px;
  padding: 12px 16px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.kpi-label {
  font-size: 12px;
  font-weight: 500;
  color: var(--alias-color-text-tertiary, #737373);
  text-transform: uppercase;
  line-height: 18px;
}

.kpi-value {
  font-size: 18px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  line-height: 28px;
}

.kpi-sub {
  font-size: 12px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 18px;
}

/* Brand blue highlight card */
.kpi-card-brand {
  background-color: #f1f7fe;
  border-color: #83bff6;
}

.kpi-value-brand {
  color: #0b529c;
}

/* ─── 3. Standalone Key Params Strip (Figma Node 7009:114608) ─── */
.key-params-card {
  flex-direction: row;
  justify-content: space-between;
  align-items: flex-start;
}

.param-item {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.param-label {
  font-size: 14px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 20px;
}

.param-val {
  font-size: 14px;
  font-weight: 500;
  color: var(--alias-color-text-secondary, #404040);
  line-height: 20px;
}

/* ─── 4. Rationale & Operational Handover Card ─── */
.statement-box {
  background-color: var(--color-background-primary, #fafafa);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 16px;
  padding: 16px 24px;
}

.statement-text {
  font-size: 12px;
  line-height: 18px;
  color: var(--alias-color-text-secondary, #404040);
  margin: 0;
}

.handover-strip {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  width: 100%;
}

.handover-user {
  display: flex;
  align-items: center;
  gap: 10px;
}

.handover-avatar {
  width: 42px;
  height: 42px;
  border-radius: 9999px;
  border: 1.37px solid #ffffff;
  box-shadow: 0 4.1px 5.47px -1.37px rgba(10, 13, 18, 0.08), 0 1.37px 2.05px -0.68px rgba(10, 13, 18, 0.03);
  object-fit: cover;
}

.handover-meta {
  display: flex;
  flex-direction: column;
}

.handover-name {
  font-size: 14px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  line-height: 20px;
}

.handover-role {
  font-size: 12px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 18px;
}

/* ─── 5. Daily Attendance Schedule Table (Figma Node 7009:114645) ─── */
.schedule-table-wrap {
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 12px;
  overflow: hidden;
  background-color: #ffffff;
}

.schedule-table {
  width: 100%;
  border-collapse: collapse;
}

.schedule-table th {
  background-color: var(--color-background-primary, #fafafa);
  height: 44px;
  padding: 0 24px;
  border-bottom: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-left: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  font-size: 12px;
  font-weight: 500;
  color: #374151;
  text-align: left;
  line-height: 18px;
}

.schedule-table th:first-child {
  border-left: none;
}

.schedule-table td {
  height: 55px;
  padding: 0 24px;
  border-bottom: 1px solid #e9eaeb;
  border-left: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  font-size: 14px;
  line-height: 20px;
}

.schedule-table td:first-child {
  border-left: none;
}

.schedule-table tr:last-child td {
  border-bottom: none;
}

.th-no, .td-no {
  width: 49px;
  padding: 0 11px !important;
  text-align: left;
}

.td-no {
  color: var(--alias-color-text-secondary, #404040);
}

.td-date {
  font-weight: 500;
  color: var(--alias-color-text-secondary, #404040);
}

.td-day, .td-portion {
  font-weight: 500;
  color: var(--alias-color-text-tertiary, #737373);
}

/* ─── Right Column: Approval Timeline (360px / Collapsed 68px) ─── */
.rail-card {
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Collapsed Rail Card & Toggle Button (Figma Node 9066:90727 & 9066:90728) */
.rail-card-collapsed {
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 16px;
  padding: 20px 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  min-height: 800px;
  box-sizing: border-box;
}

.btn-sidebar-collapsed {
  width: 36px;
  height: 36px;
  background-color: #ffffff;
  border: 1px solid #d5d7da;
  border-radius: 8px;
  box-shadow: 0px 1px 2px 0px rgba(10, 13, 18, 0.05);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 8px;
  cursor: pointer;
  color: #414651;
  transition: all 0.15s ease;
}

.btn-sidebar-collapsed:hover {
  background-color: #f9fafb;
  border-color: #d0d5dd;
  color: #1f242f;
}

/* Focus Button in Expanded Rail (Figma Node 7009:114670) */
.focus-btn-row {
  display: flex;
  justify-content: flex-start;
}

.btn-focus {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background-color: #ffffff;
  border: 1px solid #d5d7da;
  border-radius: 8px;
  padding: 8px 14px;
  box-shadow: 0px 1px 2px 0px rgba(10, 13, 18, 0.05);
  font-family: inherit;
  font-weight: 600;
  font-size: 14px;
  line-height: 20px;
  color: #414651;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-focus:hover {
  background-color: #f9fafb;
  border-color: #d0d5dd;
  color: #1f242f;
}

.btn-focus-icon {
  color: #414651;
  flex-shrink: 0;
}

.rail-section {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.section-title-block {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.section-heading {
  font-size: 20px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  line-height: 30px;
  margin: 0;
}

.section-desc {
  font-size: 14px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 20px;
  margin: 0;
}

/* Decision Form */
.decision-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-label {
  font-size: 14px;
  font-weight: 500;
  color: var(--alias-color-text-secondary, #404040);
  line-height: 20px;
}

.form-label.required::after {
  content: ' *';
  color: #e53333;
}

.remark-textarea {
  width: 100%;
  padding: 10px 14px;
  background-color: #ffffff;
  border: 1px solid #d9d9d9;
  border-radius: 8px;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  font-size: 14px;
  color: var(--alias-color-text-secondary, #404040);
  outline: none;
  resize: vertical;
  font-family: inherit;
  box-sizing: border-box;
}

.remark-textarea::placeholder {
  color: #717680;
}

.remark-textarea:focus {
  border-color: #0b529c;
}

.btn-submit-decision {
  width: 100%;
}

/* Certified Sign-off Card (Approved State) */
.certified-signoff-card {
  background-color: #f0fdf4;
  border: 1px solid #bbf7d0;
  border-radius: 12px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.seal-header {
  display: flex;
  align-items: center;
  gap: 10px;
}

.seal-icon-wrap {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background-color: #ffffff;
  border: 1px solid #86efac;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.seal-icon {
  color: #059669;
}

.seal-titles {
  display: flex;
  flex-direction: column;
}

.seal-heading {
  font-size: 13px;
  font-weight: 600;
  color: #065f46;
}

.seal-meta-date {
  font-size: 11px;
  color: #047857;
}

.signatory-row {
  display: flex;
  align-items: center;
  gap: 10px;
  background-color: #ffffff;
  border: 1px solid #dcfce7;
  border-radius: 8px;
  padding: 8px 12px;
}

.signatory-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  object-fit: cover;
}

.signatory-meta {
  display: flex;
  flex-direction: column;
}

.signatory-name {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.signatory-role {
  font-size: 11px;
  color: #737373;
}

.approval-quote-box {
  background-color: #ffffff;
  border-left: 3px solid #059669;
  border-radius: 0 6px 6px 0;
  padding: 8px 12px;
}

.approval-quote-text {
  font-size: 12px;
  line-height: 18px;
  color: #404040;
  margin: 0;
  font-style: italic;
}

.context-actions-stack {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

/* Rejected Card */
.rejected-signoff-card {
  background-color: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 12px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.seal-icon-wrap-rejected {
  border-color: #fca5a5;
}

.seal-icon-rejected {
  color: #dc2626;
}

.text-danger {
  color: #dc2626 !important;
}

.rail-divider {
  border: none;
  border-top: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  margin: 4px 0;
  width: 100%;
}

/* ─── Stepper Workflow (Figma Node 7009:114683 & 7009:114684) ─── */
.stepper-wrap {
  display: flex;
  gap: 20px;
  align-items: flex-start;
  width: 100%;
}

.stepper-track {
  width: 44px;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding-top: 27px;
  flex-shrink: 0;
}

.step-circle {
  width: 44px;
  height: 44px;
  border-radius: 9999px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-sizing: border-box;
}

/* Step 1: Approved (Brand Blue #0b529c) */
.step-circle-approved {
  background-color: var(--color-brand-blue-primary, #0b529c);
  border: none;
}

/* Step 2: Pending (Warning 500 Orange #fe9a00) */
.step-circle-pending {
  background-color: var(--color-warning-500, #fe9a00);
  border: none;
}

/* Step 3: Disabled / Queued (Background Tertiary #e5e5e5 & Primary Border #d4d4d4) */
.step-circle-queued {
  background-color: var(--color-background-tertiary, #e5e5e5);
  border: 1px solid var(--color-border-primary, #d4d4d4);
}

.step-circle-rejected {
  background-color: var(--color-error-500, #e7000b);
  border: none;
}

.step-icon-white {
  color: #ffffff;
}

.step-icon-disabled {
  color: #ffffff;
  opacity: 0.85;
}

/* ─── Reactive Connector Lines (Figma Node 7009:114687 & 7009:114690) ─── */
.step-line-1 {
  width: 2px;
  height: 133px;
  margin: 0 auto;
}

.step-line-2 {
  width: 2px;
  height: 50px;
  margin: 0 auto;
}

.step-line-solid-blue {
  background-color: #0b529c !important;
}

.step-line-solid-gray {
  background-color: #d4d4d4 !important;
}

.step-line-gradient-blue-to-orange {
  background: linear-gradient(180deg, #0b529c 0%, #fe9a00 100%) !important;
}

.step-line-gradient-orange-to-gray {
  background: linear-gradient(180deg, #fe9a00 0%, #d4d4d4 100%) !important;
}

.step-line-gradient-blue-to-red {
  background: linear-gradient(180deg, #0b529c 0%, #e7000b 100%) !important;
}

.stepper-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.step-card {
  background-color: var(--color-background-primary, #fafafa);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 16px;
  padding: 12px 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.step-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
  line-height: 18px;
}

.step-title {
  font-size: 12px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
}

.step-actor {
  font-size: 10px;
  color: var(--alias-color-text-tertiary, #737373);
}

.step-time {
  font-size: 10px;
  color: var(--alias-color-text-tertiary, #737373);
}

.step-quote-box {
  background-color: #f5f5f5;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 8px;
  padding: 8px 12px;
}

.step-quote-text {
  font-size: 12px;
  line-height: 18px;
  color: var(--alias-color-text-secondary, #404040);
  margin: 0;
}

.text-muted {
  color: #a1a1a1 !important;
}
</style>
