<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { 
  ArrowLeft, CheckCircle2, XCircle, Clock, ShieldCheck, 
  ArrowUpRight, ArrowRight, User, Building2, Briefcase, 
  Award, FileText, Check, X, AlertCircle, Share2, Printer,
  ShieldAlert
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import FormTextarea from '../../components/FormTextarea.vue';

const router = useRouter();
const route = useRoute();

// Movement record ID from URL
const movementId = computed(() => Number(route.params.id) || 4);

// ─── Multi-Record Movement Database (Supporting Distinct Roles & Handovers) ───
const movementDatabase: Record<number, any> = {
  // ─── 1. ALMAZ KEBEDE (Finance Promotion & User Approval Request) ───
  4: {
    id: 4,
    code: 'MOV-2026-0124',
    employee_id: 124,
    employee_name: 'Almaz Kebede',
    employee_code: 'EMP-00124',
    employee_role: 'Senior Accountant',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    movement_type: 'promotion',
    movement_state: 'pending',
    require_guarantee_refresh: true,
    
    // Transition Details
    from_entity_id: 7,
    from_entity_name: 'Bole Commercial Branch',
    to_entity_id: 1,
    to_entity_name: 'Haleta Addis Ababa HQ',
    
    from_org_unit_name: 'Branch Finance & Accounting',
    to_org_unit_name: 'Corporate Financial Operations',
    
    from_position_title: 'Senior Accountant',
    to_position_title: 'Finance Operations Lead',
    
    from_job_grade_code: 'Grade B2 (Step 3)',
    to_job_grade_code: 'Grade A1 (Step 1)',
    
    from_salary: 7150,
    to_salary: 10500,
    
    from_manager_name: 'Kassahun Belay (Finance Manager)',
    to_manager_name: 'Sara Tefera (Director of Financial Planning)',
    
    from_shift_pattern: 'Standard Corporate Office (8:30 - 17:30)',
    to_shift_pattern: 'Standard Corporate Office (8:30 - 17:30)',
    
    assignment_type: 'Primary Posting',
    effective_date: '2026-10-12',
    reason: 'Promoted to lead Corporate Financial Operations following exemplary leadership during the FY2026 Q3 statutory audit closure and general ledger automation rollout.',
    notes: '• Handover corporate commercial banking portal tokens & signatory credentials to incoming Senior Financial Analyst.\n• Archival and transfer of FY2026 Q3 tax withholding files and pension remittance ledgers.\n• Brief Department Head on pending vendor payment reconciliation rotas.',
    requested_by_name: 'Kassahun Belay (Finance Manager)',
    created_at: '2026-10-01T08:15:00Z',
    
    // Living Sequential Approval Chain (Step 2 is Pending Approval for User Review)
    approvals: [
      {
        id: 1,
        step_number: 1,
        step_name: 'Finance Department Head Endorsement',
        approver_name: 'Kassahun Belay',
        approver_role: 'Finance Manager',
        approval_state: 'approved',
        remarks: 'Strong analytical diligence, flawless audit compliance, and ready for operational team leadership.',
        actioned_at: '2026-10-02T09:40:00Z'
      },
      {
        id: 2,
        step_number: 2,
        step_name: 'Financial Controller Sign-off',
        approver_name: 'Marta Tadesse',
        approver_role: 'Financial Controller',
        approval_state: 'pending',
        remarks: '',
        actioned_at: null
      },
      {
        id: 3,
        step_number: 3,
        step_name: 'HR Operations Final Sign-off',
        approver_name: 'Almaz Mengistu',
        approver_role: 'HR Operations Director',
        approval_state: 'waiting',
        remarks: '',
        actioned_at: null
      }
    ]
  },

  // ─── 2. KIDST TESFAYE (Security Supervisor Promotion & Transfer) ───
  2: {
    id: 2,
    code: 'MOV-2026-0018',
    employee_id: 18,
    employee_name: 'Kidst Tesfaye',
    employee_code: 'EMP 0018',
    employee_role: 'HQ Security Guard',
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    movement_type: 'promotion',
    movement_state: 'pending',
    require_guarantee_refresh: false,
    
    from_entity_id: 1,
    from_entity_name: 'Haleta Addis Ababa HQ',
    to_entity_id: 3,
    to_entity_name: 'Hawassa Manufacturing Plant',
    
    from_org_unit_name: 'HQ Physical Security',
    to_org_unit_name: 'Plant Protection & Loss Prevention',
    
    from_position_title: 'HQ Security Guard',
    to_position_title: 'Plant Security Supervisor',
    
    from_job_grade_code: 'Grade S1 (Step 1)',
    to_job_grade_code: 'Grade S2 (Step 1)',
    
    from_salary: 5800,
    to_salary: 8200,
    
    from_manager_name: 'Captain Berhanu (HQ Security Lead)',
    to_manager_name: 'Eng. Solomon (Plant General Manager)',
    
    from_shift_pattern: 'Static 12-Hour Shift Roster',
    to_shift_pattern: 'Continuous 2-2-2 Plant Rota',
    
    assignment_type: 'Primary Posting',
    effective_date: '2026-07-08',
    reason: 'Promotion to Plant Security Supervisor following field leadership assessment and training in hazardous facility security protocols.',
    notes: '• Handover HQ perimeter master radio handset (Channel 4) and armory locker keys to the incoming Duty Sergeant.\n• Complete Hawassa industrial park biometric entry badge registration.\n• Sign off on visitor inspection daily log handover.',
    requested_by_name: 'Captain Berhanu (HQ Security Lead)',
    created_at: '2026-06-25T11:00:00Z',
    
    approvals: [
      {
        id: 1,
        step_number: 1,
        step_name: 'Chief Security Officer Endorsement',
        approver_name: 'Captain Berhanu',
        approver_role: 'HQ Security Lead',
        approval_state: 'approved',
        remarks: 'Exemplary discipline, zero safety incidents during tenure, and strong emergency response leadership.',
        actioned_at: '2026-06-26T14:20:00Z'
      },
      {
        id: 2,
        step_number: 2,
        step_name: 'Plant General Manager Authorization',
        approver_name: 'Eng. Solomon Worku',
        approver_role: 'Plant General Manager',
        approval_state: 'pending',
        remarks: '',
        actioned_at: null
      },
      {
        id: 3,
        step_number: 3,
        step_name: 'HR Operations Sign-off',
        approver_name: 'Almaz Mengistu',
        approver_role: 'HR Operations Director',
        approval_state: 'waiting',
        remarks: '',
        actioned_at: null
      }
    ]
  },

  // ─── 3. ABEBE KEBEDE (Cashier Promotion & Safe Handovers) ───
  102: {
    id: 102,
    code: 'MOV-2026-0102',
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-014',
    employee_role: 'Senior Cashier',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    movement_type: 'promotion',
    movement_state: 'pending',
    require_guarantee_refresh: true,
    
    from_entity_id: 7,
    from_entity_name: 'Bole Commercial Branch',
    to_entity_id: 7,
    to_entity_name: 'Bole Commercial Branch',
    
    from_org_unit_name: 'Retail Operations',
    to_org_unit_name: 'Retail Operations',
    
    from_position_title: 'Senior Cashier',
    to_position_title: 'Branch Shift Supervisor',
    
    from_job_grade_code: 'Grade C1 (Step 2)',
    to_job_grade_code: 'Grade C2 (Step 1)',
    
    from_salary: 7150,
    to_salary: 10500,
    
    from_manager_name: 'Sara Tefera (Shift Supervisor)',
    to_manager_name: 'Abebe Kebede (Head of Retail)',
    
    from_shift_pattern: 'Retail 6-Day Rota',
    to_shift_pattern: 'Continuous 2-2-2 Rota',
    
    assignment_type: 'Primary Posting',
    effective_date: '2026-09-01',
    reason: 'Promoted following outstanding annual performance review in Q2 and leadership assessment score of 94.5% (Rank 1). Assumes supervisory responsibilities over cashier team.',
    notes: 'Handover of safe lock codes and cash drawer registers to be completed 3 days prior to effective date. Guarantor endorsement verified.',
    requested_by_name: 'Sara Tefera (Shift Supervisor)',
    created_at: '2026-08-01T09:30:00Z',
    
    approvals: [
      {
        id: 1,
        step_number: 1,
        step_name: 'Line Supervisor Endorsement',
        approver_name: 'Sara Tefera',
        approver_role: 'Shift Supervisor',
        approval_state: 'approved',
        remarks: 'Strong leadership, stellar cash reconciliation audits, and excellent team mentorship.',
        actioned_at: '2026-08-02T10:15:00Z'
      },
      {
        id: 2,
        step_number: 2,
        step_name: 'Department Head Authorization',
        approver_name: 'Kassahun Belay',
        approver_role: 'Head of Branch Operations',
        approval_state: 'pending',
        remarks: '',
        actioned_at: null
      },
      {
        id: 3,
        step_number: 3,
        step_name: 'HR Operations Sign-off',
        approver_name: 'Almaz Mengistu',
        approver_role: 'HR Operations Director',
        approval_state: 'waiting',
        remarks: '',
        actioned_at: null
      }
    ]
  }
};

// Aliases for route convenience
movementDatabase[1] = movementDatabase[102];
movementDatabase[124] = movementDatabase[4];

const getInitialRecord = () => {
  const target = movementDatabase[movementId.value] || movementDatabase[4];
  return JSON.parse(JSON.stringify(target));
};

const movement = ref(getInitialRecord());

watch(
  () => route.params.id,
  (newId) => {
    if (newId) {
      const idNum = Number(newId);
      const target = movementDatabase[idNum] || movementDatabase[4];
      movement.value = JSON.parse(JSON.stringify(target));
    }
  }
);

// Breadcrumb (Rule 3 & 4)
const breadcrumbItems = computed(() => [
  { label: 'Employee Movement', to: '/hr/movements' },
  { label: `${movement.value.code} — ${movement.value.employee_name}` }
]);

// Salary difference calculation
const salaryDifference = computed(() => {
  return movement.value.to_salary - movement.value.from_salary;
});

const salaryPercentChange = computed(() => {
  if (!movement.value.from_salary) return 0;
  return ((salaryDifference.value / movement.value.from_salary) * 100).toFixed(1);
});

const formatCurrency = (val: number) => {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'ETB', maximumFractionDigits: 0 }).format(val);
};

const formatDate = (dateStr?: string | null) => {
  if (!dateStr) return '—';
  return new Date(dateStr).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
};

const formatDateTime = (dateStr?: string | null) => {
  if (!dateStr) return '—';
  return new Date(dateStr).toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

const formatMovementType = (type: string) => {
  const map: Record<string, string> = {
    promotion: 'Promotion',
    transfer: 'Lateral Transfer',
    grade_change: 'Grade Increment',
    confirmation: 'Probation Confirmation',
    secondment: 'Secondment Deployment',
    reinstatement: 'Reinstatement',
    demotion: 'Demotion',
    suspension: 'Suspension',
    hire: 'Initial Hire'
  };
  return map[type] || type;
};

// ─── Approver Interaction State ───
const approverRemarks = ref('');
const isSubmittingAction = ref(false);
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

const handleApproveStep = () => {
  isSubmittingAction.value = true;
  const currentStep = movement.value.approvals.find(a => a.approval_state === 'pending');
  if (currentStep) {
    currentStep.approval_state = 'approved';
    currentStep.remarks = approverRemarks.value || 'Endorsed per organizational budget and performance evaluation.';
    currentStep.actioned_at = new Date().toISOString();
    
    // Advance next step if available
    const nextStep = movement.value.approvals.find(a => a.approval_state === 'waiting');
    if (nextStep) {
      nextStep.approval_state = 'pending';
      showToast(`Step '${currentStep.step_name}' approved. Routed to ${nextStep.approver_name}.`);
    } else {
      movement.value.movement_state = 'approved';
      showToast('Final approval granted! Movement is now Ready to Effect.');
    }
  }
  approverRemarks.value = '';
  isSubmittingAction.value = false;
};

const handleRejectStep = () => {
  if (!approverRemarks.value.trim()) {
    showToast('Please enter rejection remarks before rejecting.');
    return;
  }
  const currentStep = movement.value.approvals.find(a => a.approval_state === 'pending');
  if (currentStep) {
    currentStep.approval_state = 'rejected';
    currentStep.remarks = approverRemarks.value;
    currentStep.actioned_at = new Date().toISOString();
    movement.value.movement_state = 'rejected';
    showToast(`Movement ${movement.value.code} rejected.`);
  }
};

const handleEffectMovement = () => {
  movement.value.movement_state = 'effected';
  showToast(`Movement ${movement.value.code} formally effected! Active assignment updated.`);
};
</script>

<template>
  <div class="movement-detail-page">
    <!-- Top Bar Navigation (Rule 3 & 4) -->
    <div class="top-nav-bar">
      <div class="top-nav-left">
        <AppBreadcrumb :items="breadcrumbItems" no-margin />
      </div>

      <div class="top-nav-actions">
        <button
          type="button"
          class="btn-secondary-action"
          @click="showToast('Movement dossier link copied to clipboard.')"
        >
          <Share2 :size="14" />
          <span>Share</span>
        </button>
        <button
          type="button"
          class="btn-secondary-action"
          @click="window?.print?.()"
        >
          <Printer :size="14" />
          <span>Print Dossier</span>
        </button>
      </div>
    </div>

    <!-- Toast Notification -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <!-- Master Two-Column Layout -->
    <div class="detail-split-layout">
      <!-- ═════════════════════════════════════════════════════════════
           LEFT COLUMN: Transition Dossier & Comparison Blueprint (68%)
           ═════════════════════════════════════════════════════════════ -->
      <div class="main-dossier-column">
        <!-- Employee Hero Card -->
        <div class="dossier-card hero-card">
          <div class="hero-left">
            <div class="hero-avatar">
              {{ movement.employee_name.charAt(0) }}
            </div>
            <div class="hero-meta">
              <div class="hero-title-row">
                <h1 class="hero-name">{{ movement.employee_name }}</h1>
                <span class="movement-badge-type">
                  {{ formatMovementType(movement.movement_type) }}
                </span>
                <span class="status-pill" :class="`status-${movement.movement_state}`">
                  {{ movement.movement_state }}
                </span>
                <span v-if="movement.require_guarantee_refresh" class="badge-surety-pill">
                  <ShieldAlert :size="12" />
                  <span>Guarantor Refresh Required</span>
                </span>
              </div>
              <p class="hero-subtext">
                {{ movement.employee_code }} &bull; Current: {{ movement.from_position_title }} &bull; {{ movement.from_entity_name }}
              </p>
            </div>
          </div>

          <div class="hero-right">
            <div class="meta-stat-block">
              <span class="meta-label">Effective Date</span>
              <span class="meta-value">{{ formatDate(movement.effective_date) }}</span>
            </div>
            <div class="meta-stat-block">
              <span class="meta-label">Movement ID</span>
              <span class="meta-value font-mono">{{ movement.code }}</span>
            </div>
          </div>
        </div>

        <!-- Transition Comparison Blueprint Card -->
        <div class="dossier-card">
          <div class="card-header-bar">
            <div>
              <h2 class="card-section-title">Transition Comparison Blueprint</h2>
              <p class="card-section-subtitle">Side-by-side transition parameters from current posting to proposed target assignment.</p>
            </div>
          </div>

          <!-- Salary Adjustment Callout Banner -->
          <div class="delta-banner" :class="salaryDifference >= 0 ? 'delta-positive' : 'delta-negative'">
            <div class="delta-icon-box">
              <ArrowUpRight v-if="salaryDifference >= 0" :size="20" />
              <ArrowRight v-else :size="20" />
            </div>
            <div class="delta-text">
              <span class="delta-title">
                Base Salary Variance: {{ salaryDifference >= 0 ? '+' : '' }}{{ formatCurrency(salaryDifference) }} 
                ({{ salaryDifference >= 0 ? '+' : '' }}{{ salaryPercentChange }}%)
              </span>
              <span class="delta-sub">
                Current: {{ formatCurrency(movement.from_salary) }} ➔ Proposed Target: {{ formatCurrency(movement.to_salary) }}
              </span>
            </div>
          </div>

          <!-- Side-by-side Blueprint Grid -->
          <div class="blueprint-grid-two">
            <!-- Left Side: Current Assignment -->
            <div class="bp-box current-box">
              <div class="bp-header">
                <span class="bp-tag">Current Assignment</span>
                <span class="bp-entity-code">{{ movement.from_entity_name }}</span>
              </div>

              <div class="bp-rows">
                <div class="bp-row">
                  <span class="bp-label">Facility / Cost Center:</span>
                  <span class="bp-val">{{ movement.from_entity_name }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Department / Unit:</span>
                  <span class="bp-val">{{ movement.from_org_unit_name }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Job Position Title:</span>
                  <span class="bp-val">{{ movement.from_position_title }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Job Grade &amp; Step:</span>
                  <span class="bp-val">{{ movement.from_job_grade_code }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Monthly Base Salary:</span>
                  <span class="bp-val">{{ formatCurrency(movement.from_salary) }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Reporting Line Manager:</span>
                  <span class="bp-val">{{ movement.from_manager_name }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Shift Work Pattern:</span>
                  <span class="bp-val">{{ movement.from_shift_pattern }}</span>
                </div>
              </div>
            </div>

            <!-- Right Side: Proposed Target Assignment -->
            <div class="bp-box proposed-box">
              <div class="bp-header">
                <span class="bp-tag tag-target">Proposed Target</span>
                <span class="bp-entity-code text-brand">{{ movement.to_position_title }}</span>
              </div>

              <div class="bp-rows">
                <div class="bp-row">
                  <span class="bp-label">Facility / Cost Center:</span>
                  <span class="bp-val val-highlight">{{ movement.to_entity_name }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Department / Unit:</span>
                  <span class="bp-val val-highlight">{{ movement.to_org_unit_name }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Job Position Title:</span>
                  <span class="bp-val val-highlight">{{ movement.to_position_title }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Job Grade &amp; Step:</span>
                  <span class="bp-val val-highlight">{{ movement.to_job_grade_code }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Monthly Base Salary:</span>
                  <span class="bp-val val-highlight">{{ formatCurrency(movement.to_salary) }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Reporting Line Manager:</span>
                  <span class="bp-val val-highlight">{{ movement.to_manager_name }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Shift Work Pattern:</span>
                  <span class="bp-val val-highlight">{{ movement.to_shift_pattern }}</span>
                </div>
                <div v-if="movement.require_guarantee_refresh" class="bp-row surety-bp-row">
                  <span class="bp-label">Financial Surety / Guarantor:</span>
                  <span class="bp-val val-surety">
                    <ShieldAlert :size="12" /> Refresh Mandated
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Financial Surety / Guarantor Requirement Callout Card -->
          <div v-if="movement.require_guarantee_refresh" class="surety-compliance-card">
            <div class="surety-card-left">
              <div class="surety-icon-circle">
                <ShieldAlert :size="16" />
              </div>
              <div class="surety-text-content">
                <div class="surety-header-row">
                  <h4 class="surety-title">Financial Surety &amp; Guarantor Refresh Required</h4>
                  <span class="surety-status-chip">Policy Mandate</span>
                </div>
                <p class="surety-description">
                  This target position carries fiduciary or cash-handling obligations. Corporate policy mandates that active guarantor collateral and surety endorsement must be verified prior to effectuating this assignment.
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Business Justification & Operational Reminders Card -->
        <div class="dossier-card">
          <div class="card-header-bar">
            <div>
              <h2 class="card-section-title">Operational Business Justification</h2>
              <p class="card-section-subtitle">Formal rationale and handover guidance submitted by {{ movement.requested_by_name }}.</p>
            </div>
          </div>

          <div class="justification-quote-box">
            <p class="justification-text">"{{ movement.reason }}"</p>
          </div>

          <div v-if="movement.notes" class="notes-reminder-block">
            <span class="notes-title">Handover Reminders &amp; Checklists:</span>
            <p class="notes-body">{{ movement.notes }}</p>
          </div>
        </div>
      </div>

      <!-- ═════════════════════════════════════════════════════════════
           RIGHT COLUMN: Living Approval Process & Action Rail (32%)
           ═════════════════════════════════════════════════════════════ -->
      <div class="approval-rail-column">
        <!-- Approval Status & Workflow Header Card -->
        <div class="rail-card">
          <div class="rail-header">
            <div>
              <h2 class="rail-title">Approval Process</h2>
              <p class="rail-subtitle">Sequential multi-stage authorization workflow.</p>
            </div>
            <span class="status-pill" :class="`status-${movement.movement_state}`">
              {{ movement.movement_state }}
            </span>
          </div>

          <!-- Sequential Timeline Steps -->
          <div class="approval-timeline">
            <div
              v-for="(step, idx) in movement.approvals"
              :key="step.id"
              class="timeline-item"
              :class="`step-${step.approval_state}`"
            >
              <!-- Timeline Connector Line -->
              <div v-if="idx < movement.approvals.length - 1" class="timeline-line"></div>

              <!-- Step Indicator Badge -->
              <div class="timeline-badge">
                <Check v-if="step.approval_state === 'approved'" :size="12" />
                <X v-else-if="step.approval_state === 'rejected'" :size="12" />
                <Clock v-else-if="step.approval_state === 'pending'" :size="12" />
                <span v-else>{{ step.step_number }}</span>
              </div>

              <!-- Step Info Content -->
              <div class="timeline-content">
                <div class="step-top-line">
                  <span class="step-name">{{ step.step_name }}</span>
                  <span class="step-status-tag" :class="`tag-${step.approval_state}`">
                    {{ step.approval_state }}
                  </span>
                </div>

                <div class="step-person">
                  <span class="person-name">{{ step.approver_name }}</span>
                  <span class="person-role">({{ step.approver_role }})</span>
                </div>

                <div v-if="step.actioned_at" class="step-timestamp">
                  {{ formatDateTime(step.actioned_at) }}
                </div>

                <div v-if="step.remarks" class="step-remark-bubble">
                  "{{ step.remarks }}"
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Approver Action Box (Visible for Pending Workflow Decisions) -->
        <div v-if="movement.movement_state === 'pending'" class="rail-card action-card">
          <div class="action-card-header">
            <ShieldCheck :size="16" class="text-brand" />
            <span class="action-card-title">Approver Decision</span>
          </div>
          <p class="action-card-desc">
            You are authorized to sign off on this employee movement request. Please enter optional remarks before submitting your decision.
          </p>

          <div class="action-input-block">
            <FormTextarea
              v-model="approverRemarks"
              label="Decision Remarks / Comments"
              placeholder="Enter approval endorsement notes or reason for rejection..."
              rows="3"
            />
          </div>

          <div class="action-buttons-row">
            <button
              type="button"
              class="btn-reject-action"
              :disabled="isSubmittingAction"
              @click="handleRejectStep"
            >
              <X :size="14" />
              <span>Reject / Return</span>
            </button>

            <button
              type="button"
              class="btn-approve-action"
              :disabled="isSubmittingAction"
              @click="handleApproveStep"
            >
              <Check :size="14" />
              <span>Approve Step</span>
            </button>
          </div>
        </div>

        <!-- Effect Movement Box (When Fully Approved) -->
        <div v-else-if="movement.movement_state === 'approved'" class="rail-card effect-card">
          <div class="action-card-header">
            <CheckCircle2 :size="18" class="text-emerald" />
            <span class="action-card-title">Ready for Effectuation</span>
          </div>
          <p class="action-card-desc">
            All required organizational approvals have been fulfilled. Executing this step will commit the new assignment to live employment records.
          </p>

          <button
            type="button"
            class="btn-effect-action"
            @click="handleEffectMovement"
          >
            <ArrowUpRight :size="15" />
            <span>Formally Effect Assignment</span>
          </button>
        </div>

        <!-- Effected Confirmation Card -->
        <div v-else-if="movement.movement_state === 'effected'" class="rail-card effected-card">
          <div class="effected-badge-row">
            <CheckCircle2 :size="18" class="text-emerald" />
            <span class="effected-title">Assignment Live &amp; Active</span>
          </div>
          <p class="effected-desc">
            This movement was formally executed into active employment records. The employee's assignment, compensation, and line manager hierarchy are live.
          </p>
        </div>

        <!-- Audit Metadata Card -->
        <div class="rail-card audit-card">
          <span class="audit-card-title">Audit Trail &amp; Provenance</span>
          <div class="audit-list">
            <div class="audit-item">
              <span class="audit-k">Initiated By:</span>
              <span class="audit-v">{{ movement.requested_by_name }}</span>
            </div>
            <div class="audit-item">
              <span class="audit-k">Created At:</span>
              <span class="audit-v">{{ formatDateTime(movement.created_at) }}</span>
            </div>
            <div class="audit-item">
              <span class="audit-k">Posting Type:</span>
              <span class="audit-v">{{ movement.assignment_type }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.movement-detail-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 20px 24px 80px 24px;
  background-color: var(--alias-color-bg-canvas, #f8fafc);
  min-height: 100vh;
}

/* Top Nav */
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

/* Split Layout */
.detail-split-layout {
  display: grid;
  grid-template-columns: 1fr 380px;
  gap: 20px;
  align-items: start;
}

@media (max-width: 1100px) {
  .detail-split-layout {
    grid-template-columns: 1fr;
  }
}

/* Dossier Column */
.main-dossier-column {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.dossier-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* Hero Card */
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
  width: 52px;
  height: 52px;
  border-radius: 50%;
  background-color: #eff6ff;
  color: #0B529C;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  font-weight: 600;
  border: 2px solid #dbeafe;
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
}

.hero-name {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #404040;
}

.movement-badge-type {
  font-size: 11.5px;
  font-weight: 600;
  background-color: #f1f5f9;
  color: #475569;
  padding: 2px 10px;
  border-radius: 6px;
}

.badge-surety-pill {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: 11px;
  font-weight: 600;
  background-color: #fffbeb;
  color: #b45309;
  border: 1px solid #fde68a;
  padding: 2px 10px;
  border-radius: 100px;
}

.hero-subtext {
  margin: 0;
  font-size: 13px;
  color: #737373;
}

.hero-right {
  display: flex;
  align-items: center;
  gap: 20px;
}

.meta-stat-block {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
}

.meta-label {
  font-size: 11.5px;
  color: #737373;
}

.meta-value {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.font-mono {
  font-family: monospace;
}

/* Card Header */
.card-header-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.card-section-title {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.card-section-subtitle {
  margin: 2px 0 0 0;
  font-size: 12.5px;
  color: #737373;
}

/* Delta Banner */
.delta-banner {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 12px 16px;
  border-radius: 8px;
}

.delta-positive {
  background-color: #ecfdf5;
  color: #065f46;
  border: 1px solid #a7f3d0;
}

.delta-negative {
  background-color: #fff1f2;
  color: #9f1239;
  border: 1px solid #fecdd3;
}

.delta-title {
  display: block;
  font-size: 13.5px;
  font-weight: 600;
}

.delta-sub {
  display: block;
  font-size: 12px;
  opacity: 0.85;
}

/* Blueprint Grid */
.blueprint-grid-two {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.bp-box {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 16px;
  background-color: #ffffff;
}

.current-box {
  border-left: 3px solid #94a3b8;
}

.proposed-box {
  border-left: 3px solid #0B529C;
  background-color: #fcfdfe;
}

.bp-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-bottom: 10px;
  border-bottom: 1px solid #f1f5f9;
  margin-bottom: 12px;
}

.bp-tag {
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  font-weight: 600;
  color: #64748b;
}

.tag-target {
  color: #0B529C;
}

.bp-entity-code {
  font-size: 12.5px;
  font-weight: 600;
  color: #404040;
}

.text-brand {
  color: #0B529C;
}

.bp-rows {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.bp-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 12.5px;
  padding: 3px 0;
}

.bp-label {
  color: #737373;
}

.bp-val {
  color: #404040;
  font-weight: 500;
}

.val-highlight {
  color: #0B529C;
  font-weight: 600;
}

.surety-bp-row {
  margin-top: 4px;
  padding-top: 6px;
  border-top: 1px dashed #fde68a;
}

.val-surety {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  color: #b45309;
  font-weight: 600;
  font-size: 11px;
  background-color: #fffbeb;
  padding: 2px 8px;
  border-radius: 4px;
  border: 1px solid #fde68a;
}

/* Surety Compliance Card */
.surety-compliance-card {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  background-color: #fffbeb;
  border: 1px solid #fde68a;
  border-left: 4px solid #d97706;
  border-radius: 8px;
  padding: 14px 18px;
  margin-top: 4px;
}

.surety-card-left {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.surety-icon-circle {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background-color: #fef3c7;
  color: #d97706;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  margin-top: 1px;
}

.surety-text-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.surety-header-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.surety-title {
  margin: 0;
  font-size: 13.5px;
  font-weight: 600;
  color: #92400e;
}

.surety-status-chip {
  display: inline-block;
  padding: 1px 7px;
  background-color: #fde68a;
  color: #78350f;
  border-radius: 4px;
  font-size: 10.5px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.surety-description {
  margin: 0;
  font-size: 12px;
  color: #b45309;
  line-height: 1.45;
}

/* Justification */
.justification-quote-box {
  padding: 14px 18px;
  background-color: #f8fafc;
  border-left: 3px solid #0B529C;
  border-radius: 6px;
}

.justification-text {
  margin: 0;
  font-size: 13.5px;
  color: #334155;
  font-style: italic;
  line-height: 1.5;
}

.notes-reminder-block {
  display: flex;
  flex-direction: column;
  gap: 4px;
  font-size: 12.5px;
}

.notes-title {
  font-weight: 600;
  color: #404040;
}

.notes-body {
  margin: 0;
  color: #737373;
  line-height: 1.55;
  white-space: pre-line;
}

/* ═════════════════════════════════════════════════════════════
   RIGHT COLUMN: Living Approval Rail
   ═════════════════════════════════════════════════════════════ */
.approval-rail-column {
  display: flex;
  flex-direction: column;
  gap: 16px;
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

/* Timeline */
.approval-timeline {
  display: flex;
  flex-direction: column;
  gap: 0;
  margin-top: 6px;
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

.tag-waiting {
  background-color: #f8fafc;
  color: #94a3b8;
}

.tag-rejected {
  background-color: #fef2f2;
  color: #dc2626;
}

.step-person {
  font-size: 12px;
  color: #475569;
}

.person-role {
  color: #737373;
}

.step-timestamp {
  font-size: 11px;
  color: #94a3b8;
}

.step-remark-bubble {
  margin-top: 4px;
  padding: 6px 10px;
  background-color: #f8fafc;
  border-radius: 6px;
  font-size: 11.5px;
  color: #334155;
  font-style: italic;
  border-left: 2px solid #cbd5e1;
}

/* Action Card */
.action-card {
  border-color: #bfdbfe;
  background-color: #fcfdfe;
}

.action-card-header {
  display: flex;
  align-items: center;
  gap: 8px;
}

.action-card-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.action-card-desc {
  margin: 0;
  font-size: 12px;
  color: #737373;
  line-height: 1.4;
}

.action-input-block {
  margin-top: 4px;
}

.action-buttons-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin-top: 6px;
}

.btn-reject-action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: 36px;
  border-radius: 8px;
  border: 1px solid #fecdd3;
  background-color: #fff1f2;
  color: #be123c;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-reject-action:hover {
  background-color: #ffe4e6;
}

.btn-approve-action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: 36px;
  border-radius: 8px;
  border: none;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-approve-action:hover {
  background-color: #083e77;
}

/* Effect Card */
.effect-card {
  background-color: #f0fdf4;
  border-color: #bbf7d0;
}

.text-emerald {
  color: #10b981;
}

.btn-effect-action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: 38px;
  border-radius: 8px;
  border: none;
  background-color: #059669;
  color: #ffffff;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-effect-action:hover {
  background-color: #047857;
}

/* Effected Card */
.effected-card {
  background-color: #f8fafc;
  border-color: #e2e8f0;
}

.effected-badge-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.effected-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #065f46;
}

.effected-desc {
  margin: 0;
  font-size: 12px;
  color: #64748b;
  line-height: 1.4;
}

/* Audit Card */
.audit-card {
  background-color: #f8fafc;
}

.audit-card-title {
  font-size: 12px;
  font-weight: 600;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.audit-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.audit-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 12px;
}

.audit-k {
  color: #737373;
}

.audit-v {
  color: #404040;
  font-weight: 500;
}

/* Status Pills */
.status-pill {
  padding: 3px 10px;
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

.status-draft {
  background-color: #f1f5f9;
  color: #64748b;
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
