<script setup lang="ts">
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  CheckCircle2, Clock, ShieldCheck, ArrowUpRight,
  ArrowRight, User, Check, X, Info,
  Share2, Printer, ShieldAlert,
  PanelRightClose, PanelRightOpen, FileText
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import FormToggle from '../../components/FormToggle.vue';
import PrintPreviewDrawer from '../../components/PrintPreviewDrawer.vue';
import { useToast } from '../../composables/useToast';

const router = useRouter();
const route = useRoute();

// ─── Bottom Drawer Print Preview State ───
const isPrintDrawerOpen = ref(false);
const printOptions = ref({
  showMovementParameters: true,
  showApprovalAudit: true,
  showOfficialSeal: true,
});

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
  const explicit = movement.value.approvals[1]?.approval_state;
  if (explicit) return explicit;
  if (step1State.value !== 'approved') return 'queued';
  if (movement.value.movement_state === 'approved') return 'approved';
  return 'pending';
});
const step3State = computed(() => {
  const explicit = movement.value.approvals[2]?.approval_state;
  if (explicit === 'waiting') return 'queued';
  if (explicit) return explicit;
  if (movement.value.movement_state === 'approved') return 'approved';
  if (step2State.value === 'approved') return 'pending';
  return 'queued';
});

const getConnectorLineClass = (fromState: string, toState: string): string => {
  if (fromState === 'approved' && toState === 'approved') return 'step-line-solid-blue';
  if (fromState === 'approved' && toState === 'pending') return 'step-line-gradient-blue-to-orange';
  if (fromState === 'approved' && toState === 'rejected') return 'step-line-gradient-blue-to-red';
  if (fromState === 'approved' && (toState === 'waiting' || toState === 'queued')) return 'step-line-gradient-blue-to-gray';
  if (fromState === 'pending' && (toState === 'waiting' || toState === 'queued')) return 'step-line-gradient-orange-to-gray';
  if (fromState === 'pending' && toState === 'approved') return 'step-line-solid-blue';
  if (fromState === 'rejected') return 'step-line-solid-gray';
  if (fromState === 'queued' || fromState === 'waiting' || toState === 'waiting' || toState === 'queued') return 'step-line-solid-gray';
  return 'step-line-solid-gray';
};

// ─── Center Stepper Circles on Cards Y-Axis Dynamically ───
const stepperContentRef = ref<HTMLElement | null>(null);
const stepperTrackPositions = ref<{
  circles: { top: number }[];
  lines: { top: number; height: number }[];
}>({
  circles: [],
  lines: []
});

const updateStepperAlignment = () => {
  if (!stepperContentRef.value) return;
  const cards = Array.from(stepperContentRef.value.querySelectorAll('.step-card')) as HTMLElement[];
  if (!cards.length) return;

  const circles: { top: number }[] = [];
  const lines: { top: number; height: number }[] = [];
  const containerRect = stepperContentRef.value.getBoundingClientRect();

  cards.forEach((card) => {
    const cardRect = card.getBoundingClientRect();
    const relativeCenter = (cardRect.top - containerRect.top) + (cardRect.height / 2);
    circles.push({ top: Math.round(relativeCenter - 22) });
  });

  for (let i = 0; i < circles.length - 1; i++) {
    const lineTop = circles[i].top + 44;
    const lineHeight = Math.max(0, circles[i + 1].top - lineTop);
    lines.push({ top: lineTop, height: lineHeight });
  }

  stepperTrackPositions.value = { circles, lines };
};

let stepperResizeObserver: ResizeObserver | null = null;
onMounted(() => {
  nextTick(() => {
    updateStepperAlignment();
    if (stepperContentRef.value && typeof ResizeObserver !== 'undefined') {
      stepperResizeObserver = new ResizeObserver(() => {
        updateStepperAlignment();
      });
      stepperResizeObserver.observe(stepperContentRef.value);
    }
  });
});

onUnmounted(() => {
  if (stepperResizeObserver) {
    stepperResizeObserver.disconnect();
  }
});

const handlePrint = () => {
  isPrintDrawerOpen.value = true;
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
        <!-- Employee Hero Card (Matching Figma 6624:99849 & LeaveRequestDetail) -->
        <div class="dossier-card hero-card">
          <div class="hero-left">
            <div class="hero-avatar-wrap">
              <img
                src="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&h=150&q=80"
                :alt="movement.employee_name"
                class="hero-avatar-img"
              />
            </div>
            <div class="hero-meta">
              <h1 class="hero-name">{{ movement.employee_name }}</h1>
              <div class="hero-id-row">
                <span class="hero-code">{{ movement.employee_code }} -</span>
                <BaseBadge color="gray" size="sm">
                  {{ movement.employee_role }}
                </BaseBadge>
              </div>
              <p class="hero-subtext">
                Works at {{ movement.from_entity_name }} - {{ movement.from_org_unit_name }}
              </p>
            </div>
          </div>

          <div class="hero-right">
            <div class="meta-inline-row">
              <span class="meta-label">Movement Type :</span>
              <BaseBadge color="primary" size="sm">
                {{ formatMovementType(movement.movement_type) }}
              </BaseBadge>
            </div>
            <p class="meta-inline-row">
              <span class="meta-label">Effective Date :</span>
              <span class="meta-value">{{ formatDate(movement.effective_date) }}</span>
            </p>
            <p class="meta-inline-row">
              <span class="meta-label">Movement ID :</span>
              <span class="meta-value font-mono">{{ movement.code }}</span>
            </p>
          </div>
        </div>

        <!-- Transition Comparison Blueprint Card (Matching Figma 6624:99849 & 6624:99659) -->
        <div class="dossier-card">
          <div class="card-header-bar">
            <div>
              <h2 class="card-section-title">Transition Comparison Blueprint</h2>
              <p class="card-section-subtitle">Side-by-side transition parameters from current posting to proposed target assignment.</p>
            </div>
          </div>

          <!-- Side-by-side Blueprint Grid (White Current Card + QMT Brand Blue Proposed Card) -->
          <div class="blueprint-grid-two">
            <!-- Left Side: Current Assignment -->
            <div class="bp-box current-box">
              <div class="bp-rows">
                <div class="bp-row">
                  <span class="bp-label">Current Entity</span>
                  <span class="bp-val">{{ movement.from_entity_name }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Job Position</span>
                  <span class="bp-val">{{ movement.from_position_title }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Seniority Level</span>
                  <span class="bp-val">{{ movement.from_job_grade_code }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Monthly Base Salary</span>
                  <span class="bp-val">{{ formatCurrency(movement.from_salary) }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Shift Work Pattern</span>
                  <span class="bp-val">{{ movement.from_shift_pattern }}</span>
                </div>
              </div>
            </div>

            <!-- Right Side: Proposed Target Assignment (QMT Brand Blue Surface) -->
            <div class="bp-box proposed-box">
              <div class="bp-rows">
                <div class="bp-row">
                  <span class="bp-label">Target Entity</span>
                  <span class="bp-val val-highlight">{{ movement.to_entity_name }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Job Position</span>
                  <span class="bp-val val-highlight">{{ movement.to_position_title }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Seniority Level</span>
                  <span class="bp-val val-highlight">{{ movement.to_job_grade_code }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Monthly Base Salary</span>
                  <span class="bp-val val-highlight">{{ formatCurrency(movement.to_salary) }}</span>
                </div>
                <div class="bp-row">
                  <span class="bp-label">Shift Work Pattern</span>
                  <span class="bp-val val-highlight">{{ movement.to_shift_pattern }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Financial Surety / Guarantor Requirement Callout Card (Matching Figma 6624:99659) -->
          <div v-if="movement.require_guarantee_refresh" class="surety-compliance-card">
            <div class="surety-card-left">
              <ShieldAlert :size="18" class="surety-icon" />
              <div class="surety-text-content">
                <div class="surety-header-row">
                  <h4 class="surety-title">Financial Surety &amp; Guarantor Refresh Required</h4>
                  <BaseBadge color="warning" size="sm">Policy Mandate</BaseBadge>
                </div>
                <p class="surety-description">
                  This target position carries fiduciary or cash-handling obligations. Corporate policy mandates that active guarantor collateral and surety endorsement must be verified prior to effectuating this assignment.
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Movement Description & Compensation Delta Card (Matching Figma 6624:99849 & 6624:99659) -->
        <div class="dossier-card">
          <div class="card-header-bar">
            <div>
              <h2 class="card-section-title">Movement Description</h2>
              <p class="card-section-subtitle">Formal rationale and handover guidance submitted by {{ movement.requested_by_name }}.</p>
            </div>
          </div>

          <div class="justification-quote-box">
            <p class="justification-text">&ldquo;{{ movement.reason }}&rdquo;</p>
          </div>

          <div v-if="movement.notes" class="notes-reminder-block">
            <span class="notes-title">Handover Reminders &amp; Checklists:</span>
            <p class="notes-body">{{ movement.notes }}</p>
          </div>

          <!-- Compensation Delta Callout Banner (QMT Brand Blue Surface) -->
          <div class="delta-banner delta-brand">
            <Info :size="18" class="delta-info-icon" />
            <div class="delta-text">
              <span class="delta-title">
                Compensation Delta: {{ salaryDifference >= 0 ? '+' : '' }}{{ formatCurrency(salaryDifference) }}
                ({{ salaryDifference >= 0 ? '+' : '' }}{{ salaryPercentChange }}%)
              </span>
              <span class="delta-sub">
                Current: {{ formatCurrency(movement.from_salary) }} &rarr; Proposed: {{ formatCurrency(movement.to_salary) }}
              </span>
            </div>
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
                <template v-for="(step, idx) in movement.approvals" :key="'track-' + step.id">
                  <!-- Step Circle -->
                  <div
                    class="step-circle"
                    :class="'step-circle-' + (idx === 0 ? step1State : idx === 1 ? step2State : step3State)"
                    :style="stepperTrackPositions.circles[idx] ? { top: stepperTrackPositions.circles[idx].top + 'px' } : undefined"
                    :title="step.approval_state"
                  >
                    <Check v-if="step.approval_state === 'approved'" :size="20" class="step-icon-white" :stroke-width="2.5" />
                    <Clock v-else-if="step.approval_state === 'pending'" :size="20" class="step-icon-white" :stroke-width="2" />
                    <X v-else-if="step.approval_state === 'rejected'" :size="20" class="step-icon-white" :stroke-width="2.5" />
                    <Clock v-else :size="20" class="step-icon-disabled" :stroke-width="2" />
                  </div>

                  <!-- Connector Line (if not last) -->
                  <div
                    v-if="idx < movement.approvals.length - 1"
                    :class="['step-line', getConnectorLineClass(
                      idx === 0 ? step1State : idx === 1 ? step2State : step3State,
                      idx === 0 ? step2State : idx === 1 ? step3State : 'queued'
                    )]"
                    :style="stepperTrackPositions.lines[idx] ? { top: stepperTrackPositions.lines[idx].top + 'px', height: stepperTrackPositions.lines[idx].height + 'px' } : undefined"
                  ></div>
                </template>
              </div>

              <!-- Right Content Cards Stack -->
              <div ref="stepperContentRef" class="stepper-content">
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

    <!-- ═══ BOTTOM DRAWER: PRINT PREVIEW (Figma Node 5005:78527) ═══ -->
    <PrintPreviewDrawer
      v-model:show="isPrintDrawerOpen"
      title="Print Settings"
      subtitle="Configure Document layout and Visibility"
      documentTitle="Personnel Movement Notice"
      :documentSubtitle="movement.employee_name + ' • ' + movement.employee_code"
      :documentCode="movement.code"
      :documentDate="movement.effective_date"
      :documentMeta="(movement.movement_type || 'PROMOTION').toUpperCase() + ' • ' + (movement.entity_name || 'Haleta HQ')"
      :currentPage="1"
      :totalPages="1"
    >
      <!-- Left Dynamic Customizations -->
      <template #settings>
        <div class="print-setting-toggle-row">
          <span class="print-setting-toggle-title">Movement Transition Details</span>
          <FormToggle v-model="printOptions.showMovementParameters" size="sm" aria-label="Movement Transition Details" />
        </div>
        <div class="print-setting-toggle-row">
          <span class="print-setting-toggle-title">Approval Sign-off Audit Trail</span>
          <FormToggle v-model="printOptions.showApprovalAudit" size="sm" aria-label="Approval Audit Trail" />
        </div>
        <div class="print-setting-toggle-row">
          <span class="print-setting-toggle-title">Official Stamp &amp; Seal</span>
          <FormToggle v-model="printOptions.showOfficialSeal" size="sm" aria-label="Official Stamp and Seal" />
        </div>
      </template>

      <!-- Right Printable Document Sheet -->
      <template #document>
        <!-- Metadata Overview Card -->
        <div class="print-sheet-meta-card">
          <div class="print-meta-item">
            <span class="print-meta-lbl">Employee</span>
            <span class="print-meta-val">{{ movement.employee_name }} ({{ movement.employee_code }})</span>
          </div>
          <div class="print-meta-item">
            <span class="print-meta-lbl">Current Assignment</span>
            <span class="print-meta-val">{{ movement.from_entity_name }} • {{ movement.from_job_title }}</span>
          </div>
          <div class="print-meta-item">
            <span class="print-meta-lbl">Action Type</span>
            <span class="print-meta-val text-brand">{{ (movement.movement_type || '').toUpperCase() }} (Effective {{ movement.effective_date }})</span>
          </div>
        </div>

        <!-- Transition Comparison Block -->
        <div v-if="printOptions.showMovementParameters" class="print-sheet-section">
          <h4 class="print-section-title">Assignment &amp; Grade Transition</h4>
          <div class="print-info-grid">
            <div class="print-info-cell">
              <span class="cell-lbl">Source Unit &amp; Role</span>
              <span class="cell-val">{{ movement.from_org_unit_name }} &bull; {{ movement.from_job_title }}</span>
            </div>
            <div class="print-info-cell">
              <span class="cell-lbl">Target Unit &amp; Role</span>
              <span class="cell-val font-semibold text-brand">{{ movement.to_org_unit_name }} &bull; {{ movement.to_job_title }}</span>
            </div>
            <div class="print-info-cell">
              <span class="cell-lbl">Compensation Grade</span>
              <span class="cell-val">{{ movement.from_job_grade_code || 'JG-08' }} &rarr; {{ movement.to_job_grade_code || 'JG-09' }}</span>
            </div>
            <div class="print-info-cell">
              <span class="cell-lbl">Reporting Supervisor</span>
              <span class="cell-val">{{ movement.to_supervisor_name || 'Almaz Mengistu' }}</span>
            </div>
          </div>
        </div>

        <!-- Approval Audit Trail -->
        <div v-if="printOptions.showApprovalAudit" class="print-sheet-section">
          <h4 class="print-section-title">Sequential Authorization Endorsements</h4>
          <table class="print-audit-table">
            <thead>
              <tr>
                <th>Workflow Stage</th>
                <th>Designated Approver</th>
                <th>Status</th>
                <th>Sign-off Timestamp</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="step in movement.approvals" :key="step.id">
                <td class="font-medium">{{ step.step_name }}</td>
                <td>{{ step.approver_name }} ({{ step.approver_role }})</td>
                <td>
                  <span :class="step.approval_state === 'approved' ? 'text-success' : 'text-muted'">
                    {{ (step.approval_state || '').toUpperCase() }}
                  </span>
                </td>
                <td>{{ step.actioned_at ? formatDateTime(step.actioned_at) : 'Pending' }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Official Seal and Signatures Footer -->
        <div class="print-endorsement-footer">
          <div v-if="printOptions.showOfficialSeal" class="official-seal-wrapper">
            <svg class="official-stamp-svg" viewBox="0 0 160 160" fill="none">
              <circle cx="80" cy="80" r="74" stroke="#0B529C" stroke-width="2.5" stroke-dasharray="4,3" fill="none" opacity="0.85" />
              <circle cx="80" cy="80" r="66" stroke="#0B529C" stroke-width="1.2" fill="none" opacity="0.75" />
              <circle cx="80" cy="80" r="24" fill="#0B529C" fill-opacity="0.08" stroke="#0B529C" stroke-width="1.5" />
              <text x="80" y="77" text-anchor="middle" font-size="9" font-weight="800" fill="#0B529C">HR DIVISION</text>
              <text x="80" y="89" text-anchor="middle" font-size="7" font-weight="600" fill="#0B529C">AUTHORIZED</text>
            </svg>
          </div>
          <div class="print-signatures-group">
            <div class="sig-column">
              <div class="sig-line"></div>
              <span class="sig-role">Employee Acceptance</span>
              <span class="sig-note">{{ movement.employee_name }}</span>
            </div>
            <div class="sig-column">
              <div class="sig-line"></div>
              <span class="sig-role">Department Head</span>
              <span class="sig-note">Releasing Authority</span>
            </div>
            <div class="sig-column">
              <div class="sig-line"></div>
              <span class="sig-role">HR Operations Director</span>
              <span class="sig-note">Final Sign-off</span>
            </div>
          </div>
        </div>
      </template>
    </PrintPreviewDrawer>
  </div>
</template>

<style scoped>
.movement-detail-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: var(--alias-color-background-primary, #fafafa);
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
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 12px;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* Hero Card (Matching Figma 6624:99849) */
.hero-card {
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
}

.hero-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.hero-avatar-wrap {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  overflow: hidden;
  flex-shrink: 0;
  border: 1px solid #e5e5e5;
}

.hero-avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.hero-meta {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.hero-id-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.hero-code {
  font-size: 13px;
  color: #737373;
}

.hero-name {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #404040;
}

.hero-subtext {
  margin: 0;
  font-size: 13px;
  color: #737373;
}

.hero-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 6px;
}

.meta-inline-row {
  margin: 0;
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
}

.meta-label {
  font-size: 13px;
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
  font-size: 16px;
  font-weight: 600;
  color: #404040;
}

.card-section-subtitle {
  margin: 2px 0 0 0;
  font-size: 13px;
  color: #737373;
}

/* Compensation Delta Banner (QMT Brand Blue Surface per Figma 6624:99849) */
.delta-banner {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 14px 16px;
  border-radius: 10px;
}

.delta-brand {
  background-color: var(--primitive-color-brand-blue-50, #f1f7fe);
  border: 1px solid var(--primitive-color-brand-blue-200, #bddbfa);
  color: var(--primitive-color-brand-blue-700, #0b529c);
}

.delta-info-icon {
  color: #0b529c;
  flex-shrink: 0;
  margin-top: 2px;
}

.delta-title {
  display: block;
  font-size: 13.5px;
  font-weight: 600;
  color: #0b529c;
}

.delta-sub {
  display: block;
  font-size: 12.5px;
  color: #404040;
  margin-top: 2px;
}

/* Blueprint Grid (Figma 6624:99849: Clean White Current + Brand Blue Tint Proposed) */
.blueprint-grid-two {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.bp-box {
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 12px;
  padding: 16px 20px;
  background-color: #ffffff;
}

.current-box {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
}

.proposed-box {
  background-color: var(--primitive-color-brand-blue-50, #f1f7fe);
  border: 1px solid var(--primitive-color-brand-blue-200, #bddbfa);
}

.bp-rows {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.bp-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  font-size: 13.5px;
  line-height: 20px;
  padding: 2px 0;
}

.bp-label {
  color: #737373;
  font-weight: 400;
}

.bp-val {
  color: #404040;
  font-weight: 600;
  text-align: right;
}

.val-highlight {
  color: #0b529c;
  font-weight: 600;
}

/* Surety Compliance Card (QMT Warning Surface per Figma 6624:99659) */
.surety-compliance-card {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  background-color: var(--primitive-color-amber-50, #fffbeb);
  border: 1px solid var(--primitive-color-amber-300, #ffd230);
  border-radius: 12px;
  padding: 14px 18px;
}

.surety-card-left {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.surety-icon {
  color: var(--primitive-color-amber-600, #e17100);
  flex-shrink: 0;
  margin-top: 2px;
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
  background-color: #fafafa;
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
  align-items: stretch;
  position: relative;
  width: 100%;
}

.stepper-track {
  width: 44px;
  position: relative;
  flex-shrink: 0;
  min-height: 100%;
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
  position: absolute;
  left: 0;
  z-index: 2;
  transition: top 0.15s ease;
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

.step-circle-queued,
.step-circle-waiting {
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
.step-line {
  position: absolute;
  left: 21px;
  width: 2px;
  z-index: 1;
  transition: top 0.15s ease, height 0.15s ease;
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

.step-line-gradient-blue-to-gray {
  background: linear-gradient(180deg, #0b529c 0%, #d4d4d4 100%) !important;
}

.stepper-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 24px;
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

/* ─── Bottom Drawer Print Sheet Styles ─── */
.print-setting-toggle-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 12px;
  border-bottom: 0.5px solid #f5f5f5;
}

.print-setting-toggle-title {
  font-family: 'Inter', -apple-system, sans-serif;
  font-size: 14px;
  font-weight: 500;
  line-height: 20px;
  color: #404040;
}

.print-sheet-meta-card {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  padding: 16px 20px;
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
}

.print-meta-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.print-meta-lbl {
  font-size: 12px;
  color: #737373;
}

.print-meta-val {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.print-sheet-section {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.print-section-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.print-info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  background: #fafafa;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  padding: 14px 18px;
}

.print-info-cell {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.cell-lbl {
  font-size: 12px;
  color: #737373;
}

.cell-val {
  font-size: 13.5px;
  color: #404040;
}

.print-audit-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12.5px;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
}

.print-audit-table th {
  background: #fafafa;
  padding: 10px 14px;
  border-bottom: 1px solid #e5e5e5;
  text-align: left;
  font-weight: 600;
  color: #404040;
}

.print-audit-table td {
  padding: 10px 14px;
  border-bottom: 1px solid #f1f5f9;
  color: #404040;
}

.text-brand {
  color: #0b529c !important;
}

.text-success {
  color: #009966 !important;
}

.print-endorsement-footer {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-top: 32px;
  padding-top: 24px;
  border-top: 1px solid #e5e5e5;
}

.official-seal-wrapper {
  width: 120px;
  height: 120px;
}

.official-stamp-svg {
  width: 100%;
  height: 100%;
}

.print-signatures-group {
  display: flex;
  gap: 32px;
}

.sig-column {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 140px;
  text-align: center;
  gap: 4px;
}

.sig-line {
  width: 100%;
  height: 1px;
  background: #404040;
  margin-bottom: 6px;
}

.sig-role {
  font-size: 11px;
  font-weight: 600;
  color: #404040;
}

.sig-note {
  font-size: 10px;
  color: #737373;
}
</style>
