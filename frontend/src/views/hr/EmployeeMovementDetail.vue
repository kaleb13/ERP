<script setup lang="ts">
import { ref, computed, watch, nextTick } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  CheckCircle2, Clock, ShieldCheck, ArrowUpRight,
  ArrowRight, User, Check, X,
  Share2, Printer, ShieldAlert,
  PanelRightClose, PanelRightOpen, FileText
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import { useToast } from '../../composables/useToast';

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
const { toast } = useToast();

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

// ─── Approver Interaction State (Resolution Dropdown Format) ───
const resolution = ref('approve');
const resolutionOptions: SelectOption[] = [
  { value: 'approve', label: 'Approve Movement Step' },
  { value: 'return', label: 'Return for Modification' },
  { value: 'reject', label: 'Reject Movement Request' }
];

const approverRemarks = ref('');
const isSubmittingAction = ref(false);

const handleSubmitDecision = () => {
  isSubmittingAction.value = true;
  setTimeout(() => {
    isSubmittingAction.value = false;
    const currentStep = movement.value.approvals.find((a: any) => a.approval_state === 'pending');
    if (resolution.value === 'reject') {
      if (currentStep) {
        currentStep.approval_state = 'rejected';
        currentStep.remarks = approverRemarks.value || 'Movement rejected per organizational review.';
        currentStep.actioned_at = new Date().toISOString();
      }
      movement.value.movement_state = 'rejected';
      toast.error('Movement Rejected', `Movement ${movement.value.code} was rejected.`);
    } else if (resolution.value === 'return') {
      if (currentStep) {
        currentStep.remarks = approverRemarks.value || 'Returned for quota / grade clarification.';
      }
      toast.warning('Returned for Review', `Movement ${movement.value.code} returned to initiating department.`);
    } else {
      movement.value.approvals.forEach((step: any, idx: number) => {
        if (step.approval_state !== 'approved') {
          step.approval_state = 'approved';
          step.actioned_at = new Date().toISOString();
          step.remarks = approverRemarks.value || (idx === 1 ? 'Financial compensation verified and approved.' : 'Final endorsement granted by HR Operations.');
        }
      });
      movement.value.movement_state = 'approved';
      toast.success('Movement Approved', `Movement ${movement.value.code} fully approved! Ready to effect.`);
    }
    approverRemarks.value = '';
  }, 350);
};

// ─── Stepper States & Reactive Connector Line Calculation ───
const step1State = computed(() => {
  return movement.value.approvals[0]?.approval_state || 'approved';
});
const step2State = computed(() => {
  return movement.value.approvals[1]?.approval_state || 'pending';
});
const step3State = computed(() => {
  return movement.value.approvals[2]?.approval_state || 'waiting';
});

const getConnectorLineClass = (fromState: string, toState: string): string => {
  if (fromState === 'approved' && toState === 'approved') return 'step-line-solid-blue';
  if (fromState === 'approved' && toState === 'pending') return 'step-line-gradient-blue-to-orange';
  if (fromState === 'approved' && toState === 'rejected') return 'step-line-gradient-blue-to-red';
  if (fromState === 'pending' && (toState === 'waiting' || toState === 'queued')) return 'step-line-gradient-orange-to-gray';
  if (fromState === 'pending' && toState === 'approved') return 'step-line-solid-blue';
  if (toState === 'waiting' || toState === 'queued') return 'step-line-solid-gray';
  return 'step-line-solid-blue';
};

const handlePrint = () => {
  window.print();
};

const handleEffectMovement = () => {
  movement.value.movement_state = 'effected';
  toast.success('Movement Effected', `Movement ${movement.value.code} formally effected! Active assignment updated.`);
};
</script>

<template>
  <div class="movement-detail-page">
    <!-- Breadcrumb Bar (Strict Canvas Standard: Transparent, no card box) -->
    <div class="breadcrumb-strip">
      <AppBreadcrumb :items="breadcrumbItems" noMargin>
        <template #badge>
          <BaseBadge 
            :color="movement.movement_state === 'approved' || movement.movement_state === 'effected' ? 'success' : (movement.movement_state === 'rejected' ? 'error' : 'warning')" 
            size="sm"
          >
            {{ movement.movement_state === 'effected' ? 'Live & Effected' : (movement.movement_state === 'approved' ? 'Approved & Ready' : (movement.movement_state === 'rejected' ? 'Rejected' : 'Pending Authorization')) }}
          </BaseBadge>
        </template>
      </AppBreadcrumb>
    </div>

    <!-- Master Two-Column Layout (Responsive Split: 1fr Left, 360px Right) -->
    <div class="detail-split-layout" :class="{ 'is-focus-mode': isFocusMode }">
      <!-- ═════════════════════════════════════════════════════════════
           LEFT COLUMN: Transition Dossier & Comparison Blueprint
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
                <BaseBadge color="blue" size="sm">
                  {{ formatMovementType(movement.movement_type) }}
                </BaseBadge>
                <BaseBadge 
                  :color="movement.movement_state === 'approved' || movement.movement_state === 'effected' ? 'success' : (movement.movement_state === 'rejected' ? 'error' : 'warning')" 
                  size="sm"
                >
                  {{ movement.movement_state === 'effected' ? 'Live & Effected' : (movement.movement_state === 'approved' ? 'Approved' : (movement.movement_state === 'rejected' ? 'Rejected' : 'Pending Review')) }}
                </BaseBadge>
                <BaseBadge v-if="movement.require_guarantee_refresh" color="warning" size="sm">
                  Guarantor Refresh Required
                </BaseBadge>
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
           RIGHT COLUMN: Living Approval Process & Action Rail (360px)
           (Figma Node 7009:114669 & 9066:90379 Standard)
           ═════════════════════════════════════════════════════════════ -->
      <aside class="approval-rail" :class="{ 'is-collapsed': isFocusMode }">
        <!-- Collapsed Rail State (Figma Node 9066:90727) -->
        <div v-if="isFocusMode" class="rail-card rail-card-collapsed">
          <button 
            type="button"
            class="btn-sidebar-collapsed"
            @click="toggleFocusMode"
            title="Expand authorization sidebar"
            aria-label="Expand authorization sidebar"
          >
            <PanelRightOpen :size="20" />
          </button>
        </div>

        <!-- Expanded Full Rail State -->
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

          <!-- Section 1: Approver Decision or Certified Sign-off by Status -->
          <div v-if="movement.movement_state === 'pending'" class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Approver Decision</h3>
              <p class="section-desc">You are authorized to review and endorse this employee movement transition. Enter optional remarks before submitting.</p>
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
                  v-model="approverRemarks"
                  class="remark-textarea"
                  :placeholder="resolution === 'reject' ? 'State operational workload or policy ceiling justification for rejection...' : 'Enter endorsement notes or rationale...'"
                  rows="3"
                />
              </div>

              <AppButton
                :variant="resolution === 'reject' ? 'destructive' : 'primary'"
                size="md"
                class="btn-submit-decision"
                :loading="isSubmittingAction"
                :disabled="isSubmittingAction"
                @click="handleSubmitDecision"
              >
                Submit Decision
              </AppButton>
            </div>
          </div>

          <!-- STATE B: APPROVED (Certified Seal & Effect Action) -->
          <div v-else-if="movement.movement_state === 'approved'" class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Certified Authorization</h3>
              <p class="section-desc">All required organizational endorsements signed off. Ready to effect live.</p>
            </div>

            <div class="certified-signoff-card">
              <div class="seal-header">
                <div class="seal-icon-wrap">
                  <ShieldCheck :size="20" class="seal-icon" />
                </div>
                <div class="seal-titles">
                  <span class="seal-heading">Approved &amp; Ready to Effect</span>
                  <span class="seal-meta-date">Certified: Just now</span>
                </div>
              </div>

              <div class="signatory-row">
                <div class="signatory-meta">
                  <span class="signatory-name">Marta Tadesse</span>
                  <span class="signatory-role">Financial Controller</span>
                </div>
              </div>

              <div class="approval-quote-box">
                <p class="approval-quote-text">&ldquo;{{ approverRemarks || 'Strong analytical diligence and team leadership demonstrated. Budget approved.' }}&rdquo;</p>
              </div>
            </div>

            <div class="context-actions-stack">
              <AppButton
                variant="primary"
                size="sm"
                class="w-full"
                @click="handleEffectMovement"
              >
                <template #icon-left><CheckCircle2 :size="14" /></template>
                Formally Effect Assignment
              </AppButton>

              <AppButton
                variant="outline"
                size="sm"
                class="w-full"
                @click="handlePrint"
              >
                <template #icon-left><Printer :size="14" /></template>
                Print Transfer Dossier
              </AppButton>
            </div>
          </div>

          <!-- STATE C: EFFECTED -->
          <div v-else-if="movement.movement_state === 'effected'" class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Assignment Live &amp; Active</h3>
              <p class="section-desc">This movement has been executed into core employment records.</p>
            </div>

            <div class="certified-signoff-card">
              <div class="seal-header">
                <div class="seal-icon-wrap">
                  <CheckCircle2 :size="20" class="seal-icon" />
                </div>
                <div class="seal-titles">
                  <span class="seal-heading">Active in Employment Ledger</span>
                  <span class="seal-meta-date">Effective: {{ formatDate(movement.effective_date) }}</span>
                </div>
              </div>
            </div>

            <AppButton
              variant="outline"
              size="sm"
              class="w-full"
              @click="handlePrint"
            >
              <template #icon-left><Printer :size="14" /></template>
              Print Archival Slip
            </AppButton>
          </div>

          <!-- STATE D: REJECTED -->
          <div v-else-if="movement.movement_state === 'rejected'" class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Movement Rejected</h3>
              <p class="section-desc">Transition request was denied per executive review.</p>
            </div>

            <div class="rejected-signoff-card">
              <div class="seal-header">
                <div class="seal-icon-wrap seal-icon-wrap-rejected">
                  <X :size="20" class="seal-icon-rejected" />
                </div>
                <div class="seal-titles">
                  <span class="seal-heading text-danger">Transition Denied</span>
                  <span class="seal-meta-date">Rejected: Just now</span>
                </div>
              </div>
              <div v-if="approverRemarks" class="approval-quote-box">
                <p class="approval-quote-text">&ldquo;{{ approverRemarks }}&rdquo;</p>
              </div>
            </div>
          </div>

          <hr class="rail-divider" />

          <!-- Section 2: Approval Steps (Living Multi-Stage Stepper) -->
          <div class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Authorization Steps</h3>
              <p class="section-desc">Sequential multi-stage authorization workflow.</p>
            </div>

            <div class="stepper-wrap">
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

              <!-- Right Content Cards Stack -->
              <div class="stepper-content">
                <div 
                  v-for="(step, idx) in movement.approvals" 
                  :key="step.id" 
                  class="step-card"
                >
                  <div class="step-meta" :class="{ 'step-meta-queued': step.approval_state === 'waiting' || step.approval_state === 'queued' }">
                    <span class="step-title" :class="{ 'text-muted': step.approval_state === 'waiting' || step.approval_state === 'queued' }">
                      {{ step.step_name }}
                    </span>
                    <span class="step-actor" :class="{ 'text-muted': step.approval_state === 'waiting' || step.approval_state === 'queued' }">
                      {{ step.approver_name }} ({{ step.approver_role }})
                    </span>
                    <span v-if="step.actioned_at" class="step-time">
                      {{ formatDateTime(step.actioned_at) }}
                    </span>
                  </div>
                  <div v-if="step.remarks" class="step-quote-box">
                    <p class="step-quote-text">&ldquo;{{ step.remarks }}&rdquo;</p>
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
.movement-detail-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: var(--alias-color-bg-canvas, #f8fafc);
  min-height: 100vh;
}

/* Breadcrumb Strip (Strict Canvas Standard: Transparent, no card box) */
.breadcrumb-strip {
  display: flex;
  align-items: center;
  background: transparent;
  padding: 0;
}

/* Split Layout (Responsive Split: 1fr Left, 360px Right / Collapsed 68px) */
.detail-split-layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 360px;
  gap: 20px;
  align-items: start;
  transition: grid-template-columns 0.25s ease;
}

.detail-split-layout.is-focus-mode {
  grid-template-columns: minmax(0, 1fr) 68px;
}

@media (max-width: 1100px) {
  .detail-split-layout {
    grid-template-columns: 1fr;
  }
  .detail-split-layout.is-focus-mode {
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
  color: #737373;
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
  color: #404040;
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
   RIGHT COLUMN: Living Approval Process & Action Rail (360px)
   (Figma Node 7009:114669 & 9066:90379 Standard)
   ═════════════════════════════════════════════════════════════ */
.approval-rail {
  display: flex;
  flex-direction: column;
  gap: 20px;
  width: 100%;
  max-width: 360px;
  transition: max-width 0.25s ease;
}

.approval-rail.is-collapsed {
  max-width: 68px;
  width: 68px;
}

@media (max-width: 1100px) {
  .approval-rail {
    max-width: 100%;
  }
  .approval-rail.is-collapsed {
    max-width: 100%;
    width: 100%;
  }
}

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
  gap: 16px;
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
  gap: 14px;
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

.remark-textarea:focus {
  border-color: #0b529c;
}

.btn-submit-decision {
  width: 100%;
}

.rail-divider {
  border: none;
  border-top: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  margin: 4px 0;
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

/* Step Circles */
.step-circle-approved {
  background-color: var(--color-brand-blue-primary, #0b529c);
  border: none;
}

.step-circle-pending {
  background-color: var(--color-warning-500, #fe9a00);
  border: none;
}

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

/* ─── Reactive Connector Lines ─── */
.step-line-1 {
  width: 2px;
  height: 100px;
  margin: 0 auto;
}

.step-line-2 {
  width: 2px;
  height: 100px;
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
