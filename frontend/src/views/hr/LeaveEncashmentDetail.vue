<script setup lang="ts">
import { ref, computed, nextTick, onMounted, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import {
  Check, Clock, X, ShieldCheck, Printer, FileText,
  AlertCircle, Calendar, Wallet, DollarSign,
  PanelLeft
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import FormToggle from '../../components/FormToggle.vue';
import PrintPreviewDrawer from '../../components/PrintPreviewDrawer.vue';
import { useToast } from '../../composables/useToast';
import { 
  encashmentsData, 
  getEncashmentById, 
  submitApprovalDecision, 
  cancelEncashment, 
  type LeaveEncashmentRecord 
} from './leaveEncashmentData';

const route = useRoute();
const router = useRouter();
const { toast } = useToast();

// ─── Record ID from Route ───
const encashmentId = computed(() => Number(route.params.id) || 2);

const currentItem = computed<LeaveEncashmentRecord>(() => {
  const item = getEncashmentById(encashmentId.value);
  if (item) return item;
  return encashmentsData.value.find(e => e.id === 2) || encashmentsData.value[0];
});

// ─── Breadcrumb Navigation Standard (AGENTS.md Canvas Standard) ───
const breadcrumbItems = computed(() => [
  { label: 'Leave Encashments', to: '/hr/leave-encashments' },
  { label: currentItem.value.code }
]);

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

// ─── Approver Decision Form State (Resolution Dropdown Format) ───
const resolution = ref<'approve' | 'modify' | 'reject'>('approve');
const resolutionOptions: SelectOption[] = [
  { value: 'approve', label: 'Approve Full Request' },
  { value: 'modify', label: 'Approve with Adjusted Days' },
  { value: 'reject', label: 'Reject Encashment Request' }
];

const adjustedDaysInput = ref<number>(currentItem.value.requested_days);
const decisionRemarks = ref('');
const isSubmittingDecision = ref(false);

// Live recalculated payout if days are modified during approval
const computedEffectiveDays = computed(() => {
  if (resolution.value === 'modify') {
    return Number(adjustedDaysInput.value || 0);
  }
  return currentItem.value.requested_days;
});

const computedAdjustedPayout = computed(() => {
  return Number((computedEffectiveDays.value * currentItem.value.daily_rate).toFixed(2));
});

const remainingAfterApproval = computed(() => {
  const days = currentItem.value.approved_days !== null 
    ? currentItem.value.approved_days 
    : computedEffectiveDays.value;
  return Number(Math.max(0, currentItem.value.available_balance_before - days).toFixed(1));
});

// ─── Top Bar Actions ───
// ─── Print Drawer State (Figma Node 5005:78527) ───
const isPrintDrawerOpen = ref(false);
const printOptions = ref({
  showTaxComputation: true,
  showLedgerImpact: true,
  showOfficialSeal: true
});

const handlePrintSlip = () => {
  isPrintDrawerOpen.value = true;
};

const handleDownloadVoucher = () => {
  toast.info('Voucher Generated', `Payroll payment voucher for ${currentItem.value.code} downloaded.`);
};

// ─── Submit Approver Decision Handler ───
const handleSubmitDecision = () => {
  if (resolution.value === 'modify') {
    if (!adjustedDaysInput.value || adjustedDaysInput.value <= 0) {
      toast.warning('Invalid Days', 'Please enter a valid number of adjusted days.');
      return;
    }
    if (adjustedDaysInput.value > currentItem.value.available_balance_before) {
      toast.warning('Quota Exceeded', `Adjusted days (${adjustedDaysInput.value}) cannot exceed available quota balance (${currentItem.value.available_balance_before} days).`);
      return;
    }
  }

  isSubmittingDecision.value = true;

  setTimeout(() => {
    isSubmittingDecision.value = false;
    const finalDays = resolution.value === 'modify' ? Number(adjustedDaysInput.value) : currentItem.value.requested_days;
    const success = submitApprovalDecision(
      currentItem.value.id,
      resolution.value,
      finalDays,
      decisionRemarks.value
    );

    if (success) {
      if (resolution.value === 'reject') {
        toast.error('Encashment Rejected', `Encashment request ${currentItem.value.code} has been rejected.`);
      } else {
        toast.success('Encashment Approved', `Encashment ${currentItem.value.code} certified! Quota debited and frozen daily rate locked.`);
      }
      decisionRemarks.value = '';
    }
  }, 350);
};

// ─── Stepper States & Reactive Connector Line Calculation ───
const step1State = computed(() => {
  if (currentItem.value.request_state === 'draft') return 'pending';
  return currentItem.value.approvals[0]?.approval_state || 'approved';
});
const step2State = computed(() => {
  if (currentItem.value.request_state === 'draft') return 'queued';
  const explicit = currentItem.value.approvals[1]?.approval_state;
  if (explicit) return explicit;
  if (step1State.value !== 'approved') return 'queued';
  if (currentItem.value.request_state === 'approved') return 'approved';
  return 'pending';
});
const step3State = computed(() => {
  if (currentItem.value.request_state === 'draft') return 'queued';
  const explicit = currentItem.value.approvals[2]?.approval_state;
  if (explicit) return explicit;
  if (currentItem.value.request_state === 'approved') return 'approved';
  if (step2State.value === 'approved') return 'pending';
  return 'queued';
});

const getConnectorLineClass = (fromState: string, toState: string): string => {
  if (fromState === 'approved' && toState === 'approved') return 'step-line-solid-blue';
  if (fromState === 'approved' && toState === 'pending') return 'step-line-gradient-blue-to-orange';
  if (fromState === 'approved' && toState === 'rejected') return 'step-line-gradient-blue-to-red';
  if (fromState === 'approved' && (toState === 'queued' || toState === 'waiting')) return 'step-line-gradient-blue-to-gray';
  if (fromState === 'pending' && (toState === 'queued' || toState === 'waiting')) return 'step-line-gradient-orange-to-gray';
  if (fromState === 'pending' && toState === 'approved') return 'step-line-solid-blue';
  if (fromState === 'rejected') return 'step-line-solid-gray';
  if (fromState === 'queued' || toState === 'queued') return 'step-line-solid-gray';
  return 'step-line-solid-gray';
};

const formatCurrency = (val: number) => {
  return (val || 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
};

const formatDate = (dateStr?: string | null) => {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return dateStr;
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
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
</script>

<template>
  <div class="encashment-detail-page">
    <!-- Breadcrumb Bar (Strict Canvas Standard: Transparent, no card box) -->
    <div class="breadcrumb-strip">
      <AppBreadcrumb :items="breadcrumbItems" noMargin>
        <template #badge>
          <BaseBadge 
            :color="currentItem.request_state === 'approved' ? 'success' : (currentItem.request_state === 'rejected' ? 'error' : 'warning')" 
            size="sm"
          >
            {{ currentItem.request_state === 'approved' ? 'Approved & Locked' : (currentItem.request_state === 'rejected' ? 'Rejected' : 'Pending Authorization') }}
          </BaseBadge>
        </template>
      </AppBreadcrumb>
    </div>

    <!-- Master Two-Column Layout (Responsive Split: 1fr Left, 360px Right) -->
    <div class="detail-split-layout" :class="{ 'is-focus-mode': isFocusMode }">
      <!-- ═════════════════════════════════════════════════════════════
           LEFT COLUMN: Encashment Dossier Stack
           ═════════════════════════════════════════════════════════════ -->
      <div class="dossier-column">
        <!-- 1. Employee Hero Card (Figma Node 8841:36806 Style) -->
        <div class="dossier-card hero-card">
          <div class="hero-card-main">
            <!-- Left Profile Section -->
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
                  <h1 class="hero-name">{{ currentItem.employee_name }}</h1>
                </div>
                <div class="hero-id-row">
                  <span class="hero-code">{{ currentItem.employee_code }} -</span>
                  <BaseBadge color="gray" size="sm">
                    {{ currentItem.job_position }}
                  </BaseBadge>
                </div>
                <p class="hero-dept">Works at {{ currentItem.entity_name }} &bull; {{ currentItem.department }}</p>
              </div>
            </div>

            <!-- Right Meta Section (2 Lines Symmetry) -->
            <div class="hero-right">
              <p class="meta-line">
                <span class="meta-label">Requested Units: </span>
                <span class="meta-value-bold">{{ currentItem.requested_days.toFixed(1) }} Working Days</span>
              </p>
              <p class="meta-line">
                <span class="meta-label">Encashment ID: </span>
                <span class="meta-value font-mono">{{ currentItem.code }}</span>
              </p>
              <div class="meta-leave-type-row">
                <span class="meta-label">Leave Type: </span>
                <BaseBadge color="primary" size="sm">
                  {{ currentItem.leave_type_name }}
                </BaseBadge>
              </div>
            </div>
          </div>

          <!-- Total Quota & Bank Details Strip -->
          <div class="quota-pool-bar">
            <div class="pool-left">
              <Wallet :size="16" class="pool-icon-award" />
              <span class="pool-title">Disbursement Account:</span>
              <strong class="pool-number">{{ currentItem.bank_name }}</strong>
              <span class="pool-formula font-mono">({{ currentItem.bank_account }})</span>
            </div>
            <div class="pool-right">
              <span class="period-window-badge">
                Debited Quota: {{ currentItem.allocation_code }} ({{ formatDate(currentItem.period_start) }} – {{ formatDate(currentItem.period_end) }})
              </span>
            </div>
          </div>
        </div>

        <!-- 2. Encashment Snapshot & Statutory Rate Metrics (Standard 4-KPI Grid) -->
        <div class="dossier-card">
          <div class="card-title-block">
            <h2 class="card-title">Encashment Snapshot &amp; Statutory Rate Metrics</h2>
            <p class="card-desc">Quota availability, locked daily wage conversion basis, and computed cash disbursement value.</p>
          </div>

          <div class="kpi-grid">
            <!-- 1. Available Balance -->
            <div class="kpi-card">
              <span class="kpi-label">AVAILABLE BALANCE</span>
              <span class="kpi-value">{{ currentItem.available_balance_before.toFixed(1) }} Days</span>
              <span class="kpi-sub">{{ currentItem.total_entitled_days }}d entitled &bull; {{ currentItem.taken_days }}d taken</span>
            </div>

            <!-- 2. Requested Units -->
            <div class="kpi-card">
              <span class="kpi-label">REQUESTED ENCASHMENT</span>
              <span class="kpi-value">{{ currentItem.requested_days.toFixed(1) }} Days</span>
              <span class="kpi-sub">Provisional quota deduction</span>
            </div>

            <!-- 3. Frozen Daily Rate -->
            <div class="kpi-card">
              <span class="kpi-label">FROZEN DAILY RATE</span>
              <span class="kpi-value">ETB {{ formatCurrency(currentItem.daily_rate) }}</span>
              <span class="kpi-sub">Basic salary &divide; {{ currentItem.payroll_days_basis }}d basis</span>
            </div>

            <!-- 4. Payout Amount (Brand Blue Highlight Card) -->
            <div class="kpi-card kpi-card-brand">
              <span class="kpi-label">{{ currentItem.approved_days !== null ? 'FINAL APPROVED PAYOUT' : 'ESTIMATED GROSS PAYOUT' }}</span>
              <span class="kpi-value kpi-value-brand">
                ETB {{ formatCurrency(currentItem.approved_days !== null ? currentItem.amount : computedAdjustedPayout) }}
              </span>
              <span class="kpi-sub">
                {{ (currentItem.approved_days ?? computedEffectiveDays).toFixed(1) }}d &times; ETB {{ formatCurrency(currentItem.daily_rate) }}
              </span>
            </div>
          </div>
        </div>

        <!-- 3. Employee Justification (Submitted Reason) -->
        <div class="dossier-card">
          <div class="card-title-block">
            <h2 class="card-title">Encashment Justification &amp; Purpose</h2>
            <p class="card-desc">Employee formal motivation and statutory declaration for leave cash conversion.</p>
          </div>

          <!-- Quoted Reason Box -->
          <div class="statement-box">
            <p class="statement-text">&ldquo;{{ currentItem.reason }}&rdquo;</p>
          </div>

          <div class="justification-meta-strip">
            <span class="meta-submitted">Submitted by employee on {{ formatDate(currentItem.created_at) }}</span>
            <span class="meta-currency font-mono">Disbursement Currency: {{ currentItem.currency }}</span>
          </div>
        </div>

        <!-- 4. Statutory Policy & Payroll Feeder Parameters -->
        <div class="dossier-card">
          <div class="card-title-block">
            <h2 class="card-title">Statutory Policy &amp; Payroll Feeder Parameters</h2>
            <p class="card-desc">Compliance rules under Ethiopian Labor Proclamation No. 1156/2019 and organizational payroll feeder.</p>
          </div>

          <div class="params-four-grid">
            <div class="param-item">
              <span class="param-label">Payroll Settlement</span>
              <span class="param-val">{{ currentItem.payroll_settlement_month }}</span>
              <span class="param-sub">Automated PayrollInput feeder</span>
            </div>

            <div class="param-item">
              <span class="param-label">Ledger Transaction</span>
              <span class="param-val font-mono">{{ currentItem.leave_transaction_id || 'Pending Ledger Commit' }}</span>
              <span class="param-sub">Signed quota audit debit row</span>
            </div>

            <div class="param-item">
              <span class="param-label">Payroll Synchronization</span>
              <div class="param-badge-row">
                <BaseBadge :color="currentItem.is_synced_to_payroll ? 'success' : 'blue'" size="sm">
                  {{ currentItem.is_synced_to_payroll ? 'Committed & Synced' : 'Queued for Payroll' }}
                </BaseBadge>
              </div>
              <span class="param-sub">Billed to monthly compensation</span>
            </div>

            <div class="param-item">
              <span class="param-label">Seniority Tier</span>
              <span class="param-val">{{ currentItem.service_years }} Years of Service</span>
              <span class="param-sub">Hired on {{ formatDate(currentItem.hire_date) }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- ═════════════════════════════════════════════════════════════
           RIGHT COLUMN: Approval Workflow Rail & Contextual Actions (360px)
           (Figma Node 7009:114669 & 9066:90379)
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
            <PanelLeft :size="20" class="btn-focus-icon" />
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
              <PanelLeft :size="18" class="btn-focus-icon" />
              <span>Focus</span>
            </button>
          </div>

          <!-- ──────────────────────────────────────────────────────────
               SECTION 1: APPROVER DECISION OR CERTIFIED SIGNOFF BY STATUS
               ────────────────────────────────────────────────────────── -->

          <!-- STATE A: PENDING / DRAFT (Interactive Approver Form) -->
          <div v-if="currentItem.request_state === 'pending' || currentItem.request_state === 'draft'" class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Approver Decision</h3>
              <p class="section-desc">You are authorized to review and certify this leave encashment request. Please enter optional remarks before submitting your decision.</p>
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

              <!-- Adjusted Days Input: appears ONLY when "modify" is selected -->
              <div v-if="resolution === 'modify'" class="modify-days-panel">
                <div class="form-group">
                  <label class="form-label required">Approved Days (Quota Debit)</label>
                  <FormInput
                    v-model="adjustedDaysInput"
                    type="number"
                    min="0.5"
                    :max="currentItem.available_balance_before"
                    step="0.5"
                    placeholder="Enter approved days"
                  />
                </div>
                <div class="modify-calc-feedback">
                  <span class="calc-label">Recalculated Payout:</span>
                  <strong class="calc-value font-mono">ETB {{ formatCurrency(computedAdjustedPayout) }}</strong>
                  <span class="calc-sub">({{ adjustedDaysInput || 0 }}d &times; ETB {{ formatCurrency(currentItem.daily_rate) }})</span>
                </div>
              </div>

              <div class="form-group">
                <label class="form-label">Remark</label>
                <textarea
                  ref="remarkTextareaRef"
                  v-model="decisionRemarks"
                  class="remark-textarea"
                  :placeholder="resolution === 'reject' ? 'State operational workload or policy ceiling justification for rejection...' : 'Enter your decision reason or sign-off notes...'"
                  rows="3"
                />
              </div>

              <!-- Pre-Approval Impact Notice -->
              <div class="pre-approval-impact">
                <span v-if="resolution !== 'reject'">
                  Confirming will lock <strong>frozen rate ETB {{ formatCurrency(currentItem.daily_rate) }}</strong>, 
                  debit <strong>{{ computedEffectiveDays }} days</strong> from <code>{{ currentItem.allocation_code }}</code> 
                  (leaving <strong>{{ remainingAfterApproval }}d</strong>), and queue payout.
                </span>
                <span v-else class="text-danger">
                  Rejecting will close this request without deducting employee leave quota.
                </span>
              </div>

              <AppButton
                :variant="resolution === 'reject' ? 'destructive' : 'primary'"
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
              <p class="section-desc">Statutorily certified, rate frozen, and committed to the payroll settlement feeder.</p>
            </div>

            <!-- Certified Seal Card -->
            <div class="certified-signoff-card">
              <div class="seal-header">
                <div class="seal-icon-wrap">
                  <ShieldCheck :size="20" class="seal-icon" />
                </div>
                <div class="seal-titles">
                  <span class="seal-heading">Approved &amp; Rate Locked</span>
                  <span class="seal-meta-date">Certified: {{ formatDate(currentItem.approved_at) }}</span>
                </div>
              </div>

              <!-- Signatory Info -->
              <div class="signatory-row">
                <img 
                  src="https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80" 
                  alt="Marta Tadesse" 
                  class="signatory-avatar" 
                />
                <div class="signatory-meta">
                  <span class="signatory-name">{{ currentItem.approver_name || 'Marta Tadesse' }}</span>
                  <span class="signatory-role">{{ currentItem.approver_role || 'Financial Controller' }}</span>
                </div>
              </div>

              <!-- Approver Endorsement Quote -->
              <div v-if="currentItem.approval_remarks" class="approval-quote-box">
                <p class="approval-quote-text">&ldquo;{{ currentItem.approval_remarks }}&rdquo;</p>
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
                Print Encashment Slip
              </AppButton>

              <AppButton
                variant="outline"
                size="sm"
                class="w-full"
                @click="handleDownloadVoucher"
              >
                <template #icon-left><FileText :size="14" /></template>
                Download Payroll Voucher
              </AppButton>
            </div>
          </div>

          <!-- STATE C: REJECTED -->
          <div v-else-if="currentItem.request_state === 'rejected'" class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Request Rejected</h3>
              <p class="section-desc">Encashment authorization has been denied per departmental exigency.</p>
            </div>

            <div class="rejected-signoff-card">
              <div class="seal-header">
                <div class="seal-icon-wrap seal-icon-wrap-rejected">
                  <X :size="20" class="seal-icon-rejected" />
                </div>
                <div class="seal-titles">
                  <span class="seal-heading text-danger">Encashment Request Denied</span>
                  <span class="seal-meta-date">Rejected: {{ formatDate(currentItem.approved_at) }}</span>
                </div>
              </div>
              <div v-if="currentItem.approval_remarks" class="approval-quote-box">
                <p class="approval-quote-text">&ldquo;{{ currentItem.approval_remarks }}&rdquo;</p>
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

          <!-- Section 2: Approval Steps (Living Multi-Stage Stepper) -->
          <div class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Authorization Steps</h3>
              <p class="section-desc">Sequential multi-stage authorization workflow.</p>
            </div>

            <!-- Stepper Container (Figma Node 7009:114683 & 7009:114684 Standard) -->
            <div class="stepper-wrap">
              <!-- Left Track with Circles and Reactive Connector Lines -->
              <div class="stepper-track">
                <!-- Step 1 Icon -->
                <div
                  class="step-circle"
                  :class="'step-circle-' + step1State"
                  :style="stepperTrackPositions.circles[0] ? { top: stepperTrackPositions.circles[0].top + 'px' } : undefined"
                  :title="step1State"
                >
                  <Check v-if="step1State === 'approved'" :size="20" class="step-icon-white" :stroke-width="2.5" />
                  <Clock v-else-if="step1State === 'pending'" :size="20" class="step-icon-white" :stroke-width="2" />
                  <X v-else-if="step1State === 'rejected'" :size="20" class="step-icon-white" :stroke-width="2.5" />
                  <Clock v-else :size="20" class="step-icon-disabled" :stroke-width="2" />
                </div>
                
                <!-- Connector Line 1: Step 1 -> Step 2 (Solid Blue if both approved; Gradient if opposite) -->
                <div
                  class="step-line-1"
                  :class="getConnectorLineClass(step1State, step2State)"
                  :style="stepperTrackPositions.lines[0] ? { top: stepperTrackPositions.lines[0].top + 'px', height: stepperTrackPositions.lines[0].height + 'px' } : undefined"
                ></div>

                <!-- Step 2 Icon -->
                <div
                  class="step-circle"
                  :class="'step-circle-' + step2State"
                  :style="stepperTrackPositions.circles[1] ? { top: stepperTrackPositions.circles[1].top + 'px' } : undefined"
                  :title="step2State"
                >
                  <Check v-if="step2State === 'approved'" :size="20" class="step-icon-white" :stroke-width="2.5" />
                  <Clock v-else-if="step2State === 'pending'" :size="20" class="step-icon-white" :stroke-width="2" />
                  <X v-else-if="step2State === 'rejected'" :size="20" class="step-icon-white" :stroke-width="2.5" />
                  <Clock v-else :size="20" class="step-icon-disabled" :stroke-width="2" />
                </div>
                
                <!-- Connector Line 2: Step 2 -> Step 3 (Solid Blue if both approved; Gradient if opposite) -->
                <div
                  class="step-line-2"
                  :class="getConnectorLineClass(step2State, step3State)"
                  :style="stepperTrackPositions.lines[1] ? { top: stepperTrackPositions.lines[1].top + 'px', height: stepperTrackPositions.lines[1].height + 'px' } : undefined"
                ></div>

                <!-- Step 3 Icon -->
                <div
                  class="step-circle"
                  :class="'step-circle-' + step3State"
                  :style="stepperTrackPositions.circles[2] ? { top: stepperTrackPositions.circles[2].top + 'px' } : undefined"
                  :title="step3State"
                >
                  <Check v-if="step3State === 'approved'" :size="20" class="step-icon-white" :stroke-width="2.5" />
                  <Clock v-else-if="step3State === 'pending'" :size="20" class="step-icon-white" :stroke-width="2" />
                  <X v-else-if="step3State === 'rejected'" :size="20" class="step-icon-white" :stroke-width="2.5" />
                  <Clock v-else :size="20" class="step-icon-disabled" :stroke-width="2" />
                </div>
              </div>

              <!-- Right Content Cards Stack -->
              <div ref="stepperContentRef" class="stepper-content">
                <!-- Step 1 Card: Encashment Request Submission -->
                <div class="step-card">
                  <div class="step-meta">
                    <span class="step-title">Encashment Request Submission</span>
                    <span class="step-actor">{{ currentItem.employee_name }} (Requester)</span>
                    <span class="step-time">{{ formatDate(currentItem.created_at) }}, 08:45 AM</span>
                  </div>
                  <div class="step-quote-box">
                    <p class="step-quote-text">&ldquo;Submitted request for {{ currentItem.requested_days.toFixed(1) }} days encashment.&rdquo;</p>
                  </div>
                </div>

                <!-- Step 2 Card: Line Manager Endorsement -->
                <div class="step-card">
                  <div class="step-meta" :class="{ 'step-meta-queued': step2State === 'queued' }">
                    <span class="step-title" :class="{ 'text-muted': step2State === 'queued' }">Line Manager Endorsement</span>
                    <span class="step-actor" :class="{ 'text-muted': step2State === 'queued' }">{{ currentItem.approvals[1]?.approver_name || 'Sara Tefera' }} &bull; {{ currentItem.approvals[1]?.approver_role || 'Shift Supervisor' }}</span>
                    <span v-if="step2State === 'approved'" class="step-time">{{ formatDate(currentItem.created_at) }}, 02:30 PM</span>
                  </div>
                  <div v-if="step2State === 'approved'" class="step-quote-box">
                    <p class="step-quote-text">&ldquo;{{ currentItem.approvals[1]?.remarks || 'Cashier staffing capacity verified. Endorsed for cash conversion.' }}&rdquo;</p>
                  </div>
                </div>

                <!-- Step 3 Card: Finance & Payroll Authorization -->
                <div class="step-card">
                  <div class="step-meta" :class="{ 'step-meta-queued': step3State === 'queued' }">
                    <span class="step-title" :class="{ 'text-muted': step3State === 'queued' }">Finance &amp; Payroll Authorization</span>
                    <span class="step-actor" :class="{ 'text-muted': step3State === 'queued' }">{{ currentItem.approvals[2]?.approver_name || currentItem.approver_name || 'Marta Tadesse' }} ({{ currentItem.approvals[2]?.approver_role || currentItem.approver_role || 'Financial Controller' }})</span>
                    <span v-if="step3State === 'approved'" class="step-time">{{ formatDate(currentItem.approved_at) }}</span>
                  </div>
                  <div v-if="step3State === 'approved'" class="step-quote-box">
                    <p class="step-quote-text">&ldquo;{{ currentItem.approval_remarks || 'Daily rate frozen. Quota debited from allocation.' }}&rdquo;</p>
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
      documentTitle="Leave Encashment Settlement Voucher"
      :documentSubtitle="currentItem.employee_name + ' • ' + currentItem.employee_code"
      :documentCode="currentItem.code"
      :documentDate="formatDate(currentItem.requested_at)"
      :documentMeta="formatCurrency(currentItem.net_payout_amount) + ' • ' + currentItem.days_requested + ' Days'"
      :currentPage="1"
      :totalPages="1"
    >
      <!-- Left Dynamic Customizations -->
      <template #settings>
        <div class="print-setting-toggle-row">
          <span class="print-setting-toggle-title">Tax Computation Details</span>
          <FormToggle v-model="printOptions.showTaxComputation" size="sm" aria-label="Tax Computation Details" />
        </div>
        <div class="print-setting-toggle-row">
          <span class="print-setting-toggle-title">Ledger Balance Impact</span>
          <FormToggle v-model="printOptions.showLedgerImpact" size="sm" aria-label="Ledger Balance Impact" />
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
            <span class="print-meta-val">{{ currentItem.employee_name }} ({{ currentItem.employee_code }})</span>
          </div>
          <div class="print-meta-item">
            <span class="print-meta-lbl">Department &amp; Job</span>
            <span class="print-meta-val">{{ currentItem.department_name }} • {{ currentItem.job_title }}</span>
          </div>
          <div class="print-meta-item">
            <span class="print-meta-lbl">Settlement Net Total</span>
            <span class="print-meta-val text-brand">{{ formatCurrency(currentItem.net_payout_amount) }}</span>
          </div>
        </div>

        <!-- Encashment Parameters Card -->
        <div class="print-sheet-section">
          <h4 class="print-section-title">Encashment Parameters</h4>
          <div class="print-info-grid">
            <div class="print-info-cell">
              <span class="cell-lbl">Approved Days to Liquidate</span>
              <span class="cell-val font-bold">{{ currentItem.days_requested }} Working Days</span>
            </div>
            <div class="print-info-cell">
              <span class="cell-lbl">Daily Rate Basis</span>
              <span class="cell-val font-mono">{{ formatCurrency(currentItem.daily_rate) }} / day</span>
            </div>
            <div class="print-info-cell">
              <span class="cell-lbl">Gross Encashment Pay</span>
              <span class="cell-val font-mono font-bold">{{ formatCurrency(currentItem.gross_payout_amount) }}</span>
            </div>
            <div class="print-info-cell">
              <span class="cell-lbl">Payroll Cycle Batch</span>
              <span class="cell-val">{{ currentItem.payroll_cycle_name }}</span>
            </div>
          </div>
        </div>

        <!-- Statutory Tax & Deduction Breakdown -->
        <div v-if="printOptions.showTaxComputation" class="print-sheet-section">
          <h4 class="print-section-title">Statutory Withholding &amp; Net Disbursable</h4>
          <table class="print-audit-table">
            <thead>
              <tr>
                <th>Item Description</th>
                <th>Calculation Basis</th>
                <th>Deduction / Addition</th>
                <th>Net Impact</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td class="font-medium">Gross Statutory Encashment Value</td>
                <td>{{ currentItem.days_requested }} days × {{ formatCurrency(currentItem.daily_rate) }}</td>
                <td class="text-success font-mono">+{{ formatCurrency(currentItem.gross_payout_amount) }}</td>
                <td class="font-mono font-bold">{{ formatCurrency(currentItem.gross_payout_amount) }}</td>
              </tr>
              <tr>
                <td class="font-medium">Statutory Income Tax Withholding</td>
                <td>Marginal income tax bracket (35%)</td>
                <td class="text-danger font-mono">-{{ formatCurrency(currentItem.tax_deduction_amount) }}</td>
                <td class="font-mono font-bold text-brand">{{ formatCurrency(currentItem.net_payout_amount) }}</td>
              </tr>
              <tr class="table-row-highlight">
                <td colspan="3" class="font-bold text-right">Net Payable Settlement:</td>
                <td class="font-bold text-brand font-mono">{{ formatCurrency(currentItem.net_payout_amount) }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Ledger Balance Impact -->
        <div v-if="printOptions.showLedgerImpact" class="print-sheet-section">
          <h4 class="print-section-title">Annual Leave Quota Ledger Impact</h4>
          <div class="print-info-grid">
            <div class="print-info-cell">
              <span class="cell-lbl">Balance Prior to Encashment</span>
              <span class="cell-val">{{ currentItem.available_balance_before }} Days</span>
            </div>
            <div class="print-info-cell">
              <span class="cell-lbl">Liquidated Days</span>
              <span class="cell-val text-danger font-bold">-{{ currentItem.days_requested }} Days</span>
            </div>
            <div class="print-info-cell">
              <span class="cell-lbl">Remaining Balance Available</span>
              <span class="cell-val font-bold">{{ computedRemainingBalance }} Days</span>
            </div>
            <div class="print-info-cell">
              <span class="cell-lbl">Effective Deduction Date</span>
              <span class="cell-val">{{ formatDate(currentItem.requested_at) }}</span>
            </div>
          </div>
        </div>

        <!-- Official Seal & Signatures Block -->
        <div v-if="printOptions.showOfficialSeal" class="print-endorsement-footer">
          <div class="official-seal-wrapper">
            <svg class="official-stamp-svg" viewBox="0 0 160 160">
              <circle cx="80" cy="80" r="74" stroke="#0B529C" stroke-width="2.5" fill="none" opacity="0.85" />
              <circle cx="80" cy="80" r="68" stroke="#0B529C" stroke-width="1.2" stroke-dasharray="3,2" fill="none" opacity="0.85" />
              <path id="curveTopEncash" d="M 22 80 A 58 58 0 0 1 138 80" fill="none" />
              <text font-size="8.5" font-weight="700" fill="#0B529C" opacity="0.85" letter-spacing="1.2">
                <textPath href="#curveTopEncash" startOffset="50%" text-anchor="middle">
                  ★ HALETA FINANCE / PAYROLL SETTLEMENT ★
                </textPath>
              </text>
              <polygon points="80,50 83,62 95,62 85,70 88,82 80,74 72,82 75,70 65,62 77,62" fill="#0B529C" opacity="0.85" />
              <text x="80" y="96" font-size="10" font-weight="800" fill="#0B529C" text-anchor="middle" opacity="0.85">DISBURSED</text>
              <text x="80" y="107" font-size="7.5" font-weight="600" fill="#0B529C" text-anchor="middle" opacity="0.85">PAYROLL VOUCHER</text>
              <path id="curveBottomEncash" d="M 138 80 A 58 58 0 0 1 22 80" fill="none" />
              <text font-size="8.5" font-weight="700" fill="#0B529C" opacity="0.85" letter-spacing="1.2">
                <textPath href="#curveBottomEncash" startOffset="50%" text-anchor="middle">
                  QMT ENTERPRISE MANAGEMENT
                </textPath>
              </text>
            </svg>
          </div>
          <div class="print-signatures-group">
            <div class="sig-column">
              <div class="sig-line"></div>
              <span class="sig-role">Employee Sign-off</span>
              <span class="sig-note">{{ currentItem.employee_name }}</span>
            </div>
            <div class="sig-column">
              <div class="sig-line"></div>
              <span class="sig-role">Compensation Officer</span>
              <span class="sig-note">Daily Rate Verified</span>
            </div>
            <div class="sig-column">
              <div class="sig-line"></div>
              <span class="sig-role">Financial Controller</span>
              <span class="sig-note">Approved for Disbursement</span>
            </div>
          </div>
        </div>
      </template>
    </PrintPreviewDrawer>
  </div>
</template>

<style scoped>
.encashment-detail-page {
  display: flex;
  flex-direction: column;
  gap: 24px;
  padding: 0;
  background-color: var(--color-background-primary, #fafafa);
  min-height: 100vh;
}

/* ─── Top Breadcrumb Navigation (Strict Canvas Standard) ─── */
.breadcrumb-strip {
  display: flex;
  align-items: center;
  background: transparent;
  border: none;
  box-shadow: none;
  padding: 0;
  width: 100%;
}

/* ─── Two-Column Split Layout (1fr Left, 360px Right) ─── */
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

.card-title-block {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.card-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  line-height: 24px;
  margin: 0;
}

.card-desc {
  font-size: 13px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 18px;
  margin: 0;
}

/* ─── 1. Employee Hero Card (Figma Node 8841:36806) ─── */
.hero-card {
  padding: 20px 24px;
  gap: 16px;
}

.hero-card-main {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
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
  font-size: 20px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  line-height: 28px;
  margin: 0;
}

.hero-id-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.hero-code {
  font-size: 14px;
  color: var(--alias-color-text-tertiary, #737373);
}

.hero-dept {
  font-size: 13px;
  color: var(--alias-color-text-tertiary, #737373);
  margin: 0;
}

.hero-right {
  display: flex;
  flex-direction: column;
  gap: 6px;
  align-items: flex-end;
  text-align: right;
}

.meta-line {
  font-size: 13px;
  margin: 0;
  line-height: 18px;
}

.meta-label {
  color: var(--alias-color-text-tertiary, #737373);
}

.meta-value {
  color: var(--alias-color-text-secondary, #404040);
}

.meta-value-bold {
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
}

.meta-leave-type-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.quota-pool-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 14px;
  background-color: var(--color-background-primary, #fafafa);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 10px;
  width: 100%;
  box-sizing: border-box;
}

.pool-left {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12.5px;
}

.pool-icon-award {
  color: #0b529c;
}

.pool-title {
  color: var(--alias-color-text-tertiary, #737373);
}

.pool-number {
  color: var(--alias-color-text-secondary, #404040);
  font-weight: 600;
}

.pool-formula {
  color: #737373;
  font-size: 12px;
}

.period-window-badge {
  font-size: 11.5px;
  font-weight: 500;
  color: #0b529c;
  background-color: #f1f7fe;
  border: 1px solid #c8e1fd;
  border-radius: 6px;
  padding: 4px 10px;
}

/* ─── 2. Metric Cards (Standard 4-KPI Grid) ─── */
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
  width: 100%;
}

@media (max-width: 900px) {
  .kpi-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

.kpi-card {
  background-color: var(--color-background-primary, #fafafa);
  border: 1px solid #e9eaeb;
  border-radius: 16px;
  padding: 14px 18px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.kpi-label {
  font-size: 11.5px;
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

/* ─── 3. Justification Statement Box ─── */
.statement-box {
  background-color: var(--color-background-primary, #fafafa);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 12px;
  padding: 16px 20px;
}

.statement-text {
  font-size: 13px;
  line-height: 20px;
  color: var(--alias-color-text-secondary, #404040);
  margin: 0;
  font-style: italic;
}

.justification-meta-strip {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  color: var(--alias-color-text-tertiary, #737373);
  padding: 0 4px;
}

/* ─── 4. Statutory Compliance 4-Grid ─── */
.params-four-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
  width: 100%;
}

@media (max-width: 900px) {
  .params-four-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

.param-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.param-label {
  font-size: 12.5px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 18px;
}

.param-val {
  font-size: 13.5px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  line-height: 20px;
}

.param-sub {
  font-size: 11.5px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 16px;
}

.param-badge-row {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 2px;
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
  gap: 16px;
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

.modify-days-panel {
  display: flex;
  flex-direction: column;
  gap: 10px;
  background-color: #fafafa;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 12px 14px;
}

.modify-calc-feedback {
  display: flex;
  flex-direction: column;
  gap: 2px;
  font-size: 12px;
}

.calc-label {
  color: var(--alias-color-text-tertiary, #737373);
}

.calc-value {
  font-size: 15px;
  color: #009966;
}

.calc-sub {
  color: #737373;
  font-size: 11.5px;
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

.pre-approval-impact {
  font-size: 12px;
  line-height: 18px;
  color: var(--alias-color-text-tertiary, #737373);
  background-color: var(--color-background-primary, #fafafa);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 8px;
  padding: 10px 12px;
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

/* Fallback default top positions if JS has not run yet */
.step-circle:nth-of-type(1) { top: 46px; }
.step-circle:nth-of-type(2) { top: 180px; }
.step-circle:nth-of-type(3) { top: 290px; }

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
.step-line-1,
.step-line-2 {
  position: absolute;
  left: 21px;
  width: 2px;
  z-index: 1;
  transition: top 0.15s ease, height 0.15s ease;
}

/* Fallbacks */
.step-line-1 { top: 90px; height: 90px; }
.step-line-2 { top: 224px; height: 66px; }

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

.table-row-highlight {
  background: #f8fafc;
}

.text-right {
  text-align: right;
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
