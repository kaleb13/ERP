<script setup lang="ts">
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import {
  Award, Clock, CheckCircle2,
  X, AlertCircle, ArrowRight, ShieldCheck,
  RefreshCw, ArrowUpRight, Printer, CornerDownLeft,
  Check, PanelLeft
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
  getAllocationById, 
  rescheduleAllocation, 
  approveAllocation, 
  rejectAllocation, 
  allocationsData, 
  type LeaveAllocationRecord 
} from './leaveAllocationData';

const route = useRoute();
const router = useRouter();
const { toast } = useToast();

// ─── Reactive Record Loader ───
const allocation = ref<LeaveAllocationRecord | undefined>(undefined);

const loadAllocation = () => {
  const idNum = Number(route.params.id) || 452;
  const target = getAllocationById(idNum) || allocationsData.value.find(a => a.id === 452) || allocationsData.value[0];
  allocation.value = target;
};

// Initial load + watch route params for reactivity
watch(() => route.params.id, () => {
  loadAllocation();
}, { immediate: true });

// ─── Breadcrumb Navigation Standard (AGENTS.md Canvas Standard) ───
const breadcrumbItems = computed(() => [
  { label: 'Leave Allocations', to: '/hr/leave-allocations' },
  { label: allocation.value ? allocation.value.code : 'Allocation Detail' }
]);

// ─── Status Badge Mappings ───
const getAllocationBadgeColor = (state: string): 'success' | 'warning' | 'gray' | 'purple' | 'error' | 'primary' => {
  switch (state) {
    case 'approved':
      return 'success';
    case 'draft':
    case 'submitted':
      return 'warning';
    case 'rescheduled':
      return 'purple';
    case 'consumed':
      return 'gray';
    case 'cancelled':
      return 'error';
    default:
      return 'primary';
  }
};

const getAllocationStateLabel = (state: string): string => {
  switch (state) {
    case 'approved':
      return 'Approved & Active';
    case 'draft':
      return 'Draft Quota Grant';
    case 'submitted':
      return 'Submitted for Sign-off';
    case 'rescheduled':
      return 'Rescheduled (Superseded)';
    case 'consumed':
      return 'Consumed (Closed)';
    case 'cancelled':
      return 'Cancelled / Void';
    default:
      return state.charAt(0).toUpperCase() + state.slice(1);
  }
};

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

// ─── Interactive Approver Decision State (Resolution Dropdown Format) ───
const allocationResolution = ref('certify');
const allocationResolutionOptions: SelectOption[] = [
  { value: 'certify', label: 'Certify Quota Grant' },
  { value: 'modify', label: 'Certify with Adjusted Days' },
  { value: 'reject', label: 'Reject Allocation Request' }
];

const approverRemarks = ref('');
const isSubmittingDecision = ref(false);

const handleSubmitAllocationDecision = () => {
  if (!allocation.value) return;
  isSubmittingDecision.value = true;
  setTimeout(() => {
    isSubmittingDecision.value = false;
    if (!allocation.value) return;
    if (allocationResolution.value === 'reject') {
      const ok = rejectAllocation(allocation.value.id, approverRemarks.value);
      if (ok) {
        loadAllocation();
        toast.error('Allocation Request Rejected', `Leave allocation ${allocation.value.code} was rejected.`);
      }
    } else {
      const ok = approveAllocation(allocation.value.id, approverRemarks.value);
      if (ok) {
        loadAllocation();
        toast.success('Quota Certified', `Leave allocation ${allocation.value.code} officially certified and active on the ledger.`);
      }
    }
    approverRemarks.value = '';
  }, 350);
};

// ─── Stepper States & Connector Line Calculation ───
const step1State = computed(() => 'approved');
const step2State = computed(() => 'approved');
const step3State = computed(() => {
  if (allocation.value?.allocation_state === 'cancelled') return 'rejected';
  if (allocation.value?.allocation_state === 'draft' || allocation.value?.allocation_state === 'submitted') return 'pending';
  return 'approved';
});
const step4State = computed(() => {
  if (allocation.value?.allocation_state === 'draft' || allocation.value?.allocation_state === 'submitted' || allocation.value?.allocation_state === 'cancelled') return 'queued';
  return 'approved';
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

const handleMarkConsumed = () => {
  if (!allocation.value) return;
  allocation.value.allocation_state = 'consumed';
  allocation.value.available_days = 0;
  toast.info('Quota Marked Consumed', `Allocation ${allocation.value.code} marked as consumed at fiscal year close.`);
};

// ─── Print Drawer State (Figma Node 5005:78527) ───
const isPrintDrawerOpen = ref(false);
const printOptions = ref({
  showAccrualFormula: true,
  showLedgerHistory: true,
  showOfficialSeal: true
});

const handlePrintSlip = () => {
  isPrintDrawerOpen.value = true;
};

// ─── Rescheduling Modal ───
const isRescheduleModalOpen = ref(false);
const rescheduleForm = ref({
  new_period_start: '2026-09-01',
  new_period_end: '2027-08-31',
  reason: 'Operational deferral approved by branch leadership due to peak audit.'
});

const openRescheduleModal = () => {
  if (!allocation.value) return;
  rescheduleForm.value.new_period_start = allocation.value.period_start;
  rescheduleForm.value.new_period_end = allocation.value.period_end;
  isRescheduleModalOpen.value = true;
};

const submitReschedule = () => {
  if (!allocation.value) return;
  if (!rescheduleForm.value.reason.trim()) {
    toast.warning('Justification Required', 'Please enter a business justification for rescheduling this allocation window.');
    return;
  }

  const nextRecord = rescheduleAllocation(
    allocation.value.id,
    rescheduleForm.value.new_period_start,
    rescheduleForm.value.new_period_end,
    rescheduleForm.value.reason
  );

  isRescheduleModalOpen.value = false;
  toast.success('Window Rescheduled', `Allocation rescheduled into successor ${nextRecord?.code}.`);
  if (nextRecord) {
    setTimeout(() => {
      router.push(`/hr/leave-allocations/${nextRecord.id}`);
    }, 600);
  }
};

const formatDate = (val?: string | null) => {
  if (!val) return '—';
  const d = new Date(val);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
};
</script>

<template>
  <div class="allocation-detail-page">
    <!-- Breadcrumb Bar (Strict Canvas Standard: Transparent, no card box) -->
    <div class="breadcrumb-strip no-print">
      <AppBreadcrumb :items="breadcrumbItems" noMargin>
        <template #badge>
          <BaseBadge 
            v-if="allocation"
            :color="getAllocationBadgeColor(allocation.allocation_state)"
            size="sm"
          >
            {{ getAllocationStateLabel(allocation.allocation_state) }}
          </BaseBadge>
        </template>
      </AppBreadcrumb>
    </div>

    <div v-if="allocation" class="detail-split-layout" :class="{ 'is-focus-mode': isFocusMode }">
      <!-- ═════════════════════════════════════════════════════════════
           LEFT COLUMN: Main Entitlement Dossier
           ═════════════════════════════════════════════════════════════ -->
      <div class="dossier-column">
        <!-- Forward-Chain Superseded Notice Banner (if this row was rescheduled) -->
        <div v-if="allocation.allocation_state === 'rescheduled'" class="superseded-callout-card">
          <div class="callout-icon-box">
            <RefreshCw :size="18" class="text-purple-600" />
          </div>
          <div class="callout-body">
            <h4 class="callout-title">Allocation Window Superseded by Rescheduling</h4>
            <p class="callout-text">
              Per Haleta ERP schema governance, this record is frozen and immutable. 
              Operationally deferred due to: <em>&ldquo;{{ allocation.reschedule_reason || 'Peak operational audit requirements.' }}&rdquo;</em>
            </p>
            <div v-if="allocation.rescheduled_to_id" class="callout-forward-action">
              <button 
                class="btn-forward-link" 
                @click="router.push(`/hr/leave-allocations/${allocation.rescheduled_to_id}`)"
              >
                <span>Navigate to Successor Allocation ({{ allocation.rescheduled_to_code || 'Successor Window' }})</span>
                <ArrowRight :size="14" />
              </button>
            </div>
          </div>
        </div>

        <!-- Predecessor Link Banner (if this row was rescheduled FROM an older record) -->
        <div v-else-if="allocation.rescheduled_from_id" class="predecessor-callout-card">
          <CornerDownLeft :size="16" class="text-purple-600" />
          <span>
            Successor record forward-chained from 
            <strong 
              class="predecessor-link font-mono" 
              @click="router.push(`/hr/leave-allocations/${allocation.rescheduled_from_id}`)"
            >
              {{ allocation.rescheduled_from_code || 'Prior Record' }}
            </strong>. 
            Reason: {{ allocation.reschedule_reason || 'Window adjustment.' }}
          </span>
        </div>

        <!-- 1. MASTER ENTITLEMENT HOLDER CARD (Figma Node 8841:36806 Style) -->
        <div class="dossier-card hero-card">
          <div class="hero-card-main">
            <!-- Left Profile Section -->
            <div class="hero-left">
              <div class="hero-avatar-wrap">
                <img 
                  :src="allocation.employee_avatar" 
                  :alt="allocation.employee_name" 
                  class="hero-avatar-img" 
                />
              </div>
              <div class="hero-info">
                <div class="hero-name-row">
                  <h1 class="hero-name">{{ allocation.employee_name }}</h1>
                </div>
                <div class="hero-id-row">
                  <span class="hero-code">{{ allocation.employee_code }} -</span>
                  <BaseBadge color="gray" size="sm">
                    {{ allocation.job_position }}
                  </BaseBadge>
                </div>
                <p class="hero-dept">Works at {{ allocation.entity_name }}</p>
              </div>
            </div>

            <!-- Right Meta Section (2 Lines Symmetry) -->
            <div class="hero-right">
              <p class="meta-line">
                <span class="meta-label">Total Pool: </span>
                <span class="meta-value-bold">{{ allocation.total_entitled_days.toFixed(1) }} Working Days</span>
              </p>
              <p class="meta-line">
                <span class="meta-label">Allocation ID: </span>
                <span class="meta-value font-mono">{{ allocation.code }}</span>
              </p>
              <div class="meta-leave-type-row">
                <span class="meta-label">Leave Type: </span>
                <BaseBadge color="primary" size="sm">
                  {{ allocation.leave_type_name }}
                </BaseBadge>
              </div>
            </div>
          </div>

          <!-- Total Quota Pool Breakdown Bar -->
          <div class="quota-pool-bar">
            <div class="pool-left">
              <Award :size="16" class="pool-icon-award" />
              <span class="pool-title">Authorized Quota Grant:</span>
              <strong class="pool-number font-mono">{{ allocation.total_entitled_days.toFixed(1) }} Days</strong>
              <span class="pool-formula">
                ({{ allocation.allocated_days.toFixed(1) }}d Base Grant + {{ allocation.carried_forward_days.toFixed(1) }}d Carried Rollover)
              </span>
            </div>
            <div class="pool-right">
              <span class="period-window-badge">
                Window: {{ formatDate(allocation.period_start) }} – {{ formatDate(allocation.period_end) }}
              </span>
            </div>
          </div>
        </div>

        <!-- 2. METRIC CARDS (Standard 4-KPI Grid, rounded-16px, border #e5e5e5) -->
        <div class="dossier-card">
          <div class="card-title-block">
            <h2 class="card-title">Allocation Quota &amp; Utilization Balance</h2>
            <p class="card-desc">Annual statutory quota position, active cycle deductions, and live available balance.</p>
          </div>

          <div class="kpi-grid">
            <!-- 1. BASE ALLOCATED -->
            <div class="kpi-card">
              <span class="kpi-label">BASE ALLOCATED</span>
              <span class="kpi-value">{{ allocation.allocated_days.toFixed(1) }} Days</span>
              <span class="kpi-sub">Statutory grant from policy</span>
            </div>

            <!-- 2. CARRIED FORWARD -->
            <div class="kpi-card">
              <span class="kpi-label">CARRIED FORWARD</span>
              <span class="kpi-value">{{ allocation.carried_forward_days.toFixed(1) }} Days</span>
              <span class="kpi-sub">Rolled over (2-yr statutory cap)</span>
            </div>

            <!-- 3. TAKEN / CONSUMED -->
            <div class="kpi-card">
              <span class="kpi-label">TAKEN / CONSUMED</span>
              <span class="kpi-value">{{ allocation.taken_days.toFixed(1) }} Days</span>
              <span class="kpi-sub">Deducted by leave requests</span>
            </div>

            <!-- 4. AVAILABLE BALANCE (Brand Blue Highlight Card) -->
            <div class="kpi-card kpi-card-brand">
              <span class="kpi-label">AVAILABLE BALANCE</span>
              <span class="kpi-value kpi-value-brand">{{ allocation.available_days.toFixed(1) }} Days</span>
              <span class="kpi-sub">Out of {{ allocation.total_entitled_days.toFixed(1) }}d authorized</span>
            </div>
          </div>
        </div>

        <!-- 3. QUOTA CONSUMPTION LEDGER SUB-TABLE -->
        <div class="dossier-card">
          <div class="card-header-flex">
            <div class="card-title-block">
              <h2 class="card-title">Quota Consumption Ledger</h2>
              <p class="card-desc">Approved employee leave requests drawing authorized days from this fiscal allocation bucket.</p>
            </div>
            <BaseBadge color="blue" size="sm">
              {{ allocation.consumptions.length }} Draws Recorded
            </BaseBadge>
          </div>

          <div class="schedule-table-wrap">
            <table class="schedule-table">
              <thead>
                <tr>
                  <th class="th-no">No.</th>
                  <th>Request Document</th>
                  <th>Authorized Period</th>
                  <th>Deducted Days</th>
                  <th>Request Status</th>
                  <th class="th-action">Action</th>
                </tr>
              </thead>
              <tbody>
                <tr 
                  v-for="(item, idx) in allocation.consumptions" 
                  :key="item.request_id"
                  class="table-row-clickable"
                  @click="router.push(`/hr/leave-requests/${item.request_id}`)"
                >
                  <td class="td-no">{{ idx + 1 }}</td>
                  <td>
                    <span class="doc-code-link font-mono">{{ item.request_code }}</span>
                  </td>
                  <td class="td-meta-text">{{ item.date_range }}</td>
                  <td>
                    <span class="td-days-bold">{{ item.deducted_days.toFixed(1) }} Days</span>
                  </td>
                  <td>
                    <BaseBadge color="success" size="sm">
                      {{ item.request_status }}
                    </BaseBadge>
                  </td>
                  <td class="td-action" @click.stop>
                    <button 
                      type="button"
                      class="btn-icon-link" 
                      @click="router.push(`/hr/leave-requests/${item.request_id}`)"
                      title="Inspect Leave Request"
                    >
                      <ArrowUpRight :size="16" />
                    </button>
                  </td>
                </tr>

                <!-- Empty State -->
                <tr v-if="allocation.consumptions.length === 0">
                  <td colspan="6" class="empty-table-cell">
                    <Clock :size="22" class="empty-icon text-muted" />
                    <p class="empty-text">No employee leave requests have drawn from this allocation bucket yet.</p>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- 4. STATUTORY POLICY & COMPLIANCE PARAMETERS -->
        <div class="dossier-card">
          <div class="card-title-block">
            <h2 class="card-title">Statutory Policy &amp; Compliance Parameters</h2>
            <p class="card-desc">Formal rules under Ethiopian Labor Proclamation No. 1156/2019 and organizational HR policy.</p>
          </div>

          <div class="params-four-grid">
            <div class="param-item">
              <span class="param-label">2-Year Rollover Expiry</span>
              <span class="param-val">Jul 7, 2028 (FY 2028 Close)</span>
              <span class="param-sub">Carried forward days expire if unused</span>
            </div>

            <div class="param-item">
              <span class="param-label">Accrual Method</span>
              <span class="param-val">Per Service Year (+1d / 2yr)</span>
              <span class="param-sub">Statutory seniority addition</span>
            </div>

            <div class="param-item">
              <span class="param-label">Initiated By</span>
              <span class="param-val">{{ allocation.created_by_name || 'System Accrual Engine' }}</span>
              <span class="param-sub">Granted on {{ formatDate(allocation.created_at) }}</span>
            </div>

            <div class="param-item">
              <span class="param-label">In-Service Encashment</span>
              <div class="param-badge-row">
                <BaseBadge color="success" size="sm">Eligible (Under Cap)</BaseBadge>
              </div>
              <span class="param-sub">Permitted via LeaveEncashment</span>
            </div>
          </div>

          <!-- Notes Callout Box -->
          <div class="statement-box" v-if="allocation.notes">
            <span class="statement-tag">Statutory Justification &amp; Personnel Notes</span>
            <p class="statement-text">&ldquo;{{ allocation.notes }}&rdquo;</p>
          </div>
        </div>
      </div>

      <!-- ═════════════════════════════════════════════════════════════
           RIGHT COLUMN: Approval Workflow Rail & Contextual Actions (360px)
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
               SECTION 1: DECISION / CERTIFICATION BY STATE
               ────────────────────────────────────────────────────────── -->

          <!-- STATE A: DRAFT OR SUBMITTED (Active Interactive Approver Form) -->
          <div v-if="allocation.allocation_state === 'draft' || allocation.allocation_state === 'submitted'" class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Approver Decision</h3>
              <p class="section-desc">You are authorized to review and certify this employee leave quota grant. Please enter optional remarks before submitting your decision.</p>
            </div>

            <div class="decision-form">
              <div class="form-group">
                <label class="form-label required">Resolution</label>
                <FormSelect
                  v-model="allocationResolution"
                  :options="allocationResolutionOptions"
                  placeholder="Select resolution"
                />
              </div>

              <div class="form-group">
                <label class="form-label">Remark</label>
                <textarea
                  ref="remarkTextareaRef"
                  v-model="approverRemarks"
                  class="remark-textarea"
                  placeholder="Enter your decision reason..."
                  rows="3"
                />
              </div>

              <AppButton
                variant="primary"
                size="md"
                class="btn-submit-decision w-full"
                :loading="isSubmittingDecision"
                :disabled="isSubmittingDecision"
                @click="handleSubmitAllocationDecision"
              >
                Submit Decision
              </AppButton>
            </div>
          </div>

          <!-- STATE B: APPROVED (Official Certified Seal & Management Actions) -->
          <div v-else-if="allocation.allocation_state === 'approved'" class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Certified Authorization</h3>
              <p class="section-desc">Statutorily certified and committed to the live employee leave ledger.</p>
            </div>

            <!-- Certified Seal Card -->
            <div class="certified-signoff-card">
              <div class="seal-header">
                <div class="seal-icon-wrap">
                  <ShieldCheck :size="20" class="seal-icon" />
                </div>
                <div class="seal-titles">
                  <span class="seal-heading">Active &amp; Ledger-Committed</span>
                  <span class="seal-meta-date">Certified: {{ allocation.approved_at || 'Jul 9, 2026 11:15' }}</span>
                </div>
              </div>

              <!-- Signatory Info -->
              <div class="signatory-row">
                <img 
                  :src="allocation.approver_avatar || 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&h=120&q=80'" 
                  :alt="allocation.approved_by_name || 'Approver'" 
                  class="signatory-avatar" 
                />
                <div class="signatory-meta">
                  <span class="signatory-name">{{ allocation.approved_by_name || 'Dawit Mengistu' }}</span>
                  <span class="signatory-role">{{ allocation.approver_role || 'Director of Human Resources' }}</span>
                </div>
              </div>

              <!-- Approver Endorsement Quote -->
              <div v-if="allocation.approval_remarks" class="approval-quote-box">
                <p class="approval-quote-text">&ldquo;{{ allocation.approval_remarks }}&rdquo;</p>
              </div>
            </div>

            <!-- Contextual Actions -->
            <div class="context-actions-stack">
              <AppButton
                variant="outline"
                size="sm"
                class="w-full"
                @click="openRescheduleModal"
              >
                <template #icon-left><RefreshCw :size="14" /></template>
                Reschedule Allocation Window
              </AppButton>

              <AppButton
                variant="outline"
                size="sm"
                class="w-full"
                @click="handleMarkConsumed"
              >
                <template #icon-left><Clock :size="14" /></template>
                Close &amp; Mark Consumed
              </AppButton>

              <AppButton
                variant="outline"
                size="sm"
                class="w-full"
                @click="handlePrintSlip"
              >
                <template #icon-left><Printer :size="14" /></template>
                Print Entitlement Slip
              </AppButton>
            </div>
          </div>

          <!-- STATE C: CONSUMED (Closed Fiscal Ledger) -->
          <div v-else-if="allocation.allocation_state === 'consumed'" class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Fiscal Quota Consumed</h3>
              <p class="section-desc">This fiscal year allocation has been 100% utilized and closed.</p>
            </div>

            <div class="consumed-audit-box">
              <div class="qsb-row">
                <span class="qsb-label">Total Entitled:</span>
                <span class="qsb-value font-mono">{{ allocation.total_entitled_days.toFixed(1) }} Days</span>
              </div>
              <div class="qsb-row">
                <span class="qsb-label">Taken to Date:</span>
                <span class="qsb-value font-mono font-bold">{{ allocation.taken_days.toFixed(1) }} Days</span>
              </div>
              <div class="qsb-row">
                <span class="qsb-label">Remaining Balance:</span>
                <span class="qsb-value font-mono text-muted">0.0 Days</span>
              </div>
            </div>

            <AppButton
              variant="outline"
              size="sm"
              class="w-full"
              @click="handlePrintSlip"
            >
              <template #icon-left><Printer :size="14" /></template>
              Print Archival Entitlement Slip
            </AppButton>
          </div>

          <!-- STATE D: RESCHEDULED (Superseded Window) -->
          <div v-else-if="allocation.allocation_state === 'rescheduled'" class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Window Rescheduled</h3>
              <p class="section-desc">Superseded and frozen. A forward-chained successor allocation is active.</p>
            </div>

            <div class="statement-box">
              <span class="statement-tag">Operational Deferral Justification</span>
              <p class="statement-text">&ldquo;{{ allocation.reschedule_reason || 'Peak operational requirements.' }}&rdquo;</p>
            </div>

            <AppButton
              v-if="allocation.rescheduled_to_id"
              variant="primary"
              size="sm"
              class="w-full"
              @click="router.push(`/hr/leave-allocations/${allocation.rescheduled_to_id}`)"
            >
              <template #icon-left><ArrowRight :size="14" /></template>
              View Successor Allocation
            </AppButton>
          </div>

          <hr class="rail-divider" />

          <!-- ──────────────────────────────────────────────────────────
               SECTION 2: LIVING MULTI-STAGE STEPPER (Figma 7009:114684 Standard)
               ────────────────────────────────────────────────────────── -->
          <div class="rail-section">
            <div class="section-title-block">
              <h3 class="section-heading">Authorization Steps</h3>
              <p class="section-desc">Multi-stage governance and ledger commitment audit trail.</p>
            </div>

            <div class="stepper-wrap">
              <!-- Stepper Track with State Circles & Linear Gradient Connector Lines -->
              <div class="stepper-track">
                <!-- Step 1: Accrual & Service Computation (Approved) -->
                <div
                  class="step-circle step-circle-approved"
                  :style="stepperTrackPositions.circles[0] ? { top: stepperTrackPositions.circles[0].top + 'px' } : undefined"
                  title="Approved"
                >
                  <Check :size="20" class="step-icon-white" :stroke-width="2.5" />
                </div>

                <!-- Connector Line 1: Step 1 (Blue) -> Step 2 (Blue) => SOLID BLUE ONLY (No orange gradient!) -->
                <div 
                  class="step-line-1"
                  :class="getConnectorLineClass(step1State, step2State)"
                  :style="stepperTrackPositions.lines[0] ? { top: stepperTrackPositions.lines[0].top + 'px', height: stepperTrackPositions.lines[0].height + 'px' } : undefined"
                ></div>

                <!-- Step 2: Statutory Policy Compliance (Approved) -->
                <div
                  class="step-circle step-circle-approved"
                  :style="stepperTrackPositions.circles[1] ? { top: stepperTrackPositions.circles[1].top + 'px' } : undefined"
                  title="Approved"
                >
                  <Check :size="20" class="step-icon-white" :stroke-width="2.5" />
                </div>

                <!-- Connector Line 2: Step 2 (Blue) -> Step 3 -->
                <div 
                  class="step-line-2"
                  :class="getConnectorLineClass(step2State, step3State)"
                  :style="stepperTrackPositions.lines[1] ? { top: stepperTrackPositions.lines[1].top + 'px', height: stepperTrackPositions.lines[1].height + 'px' } : undefined"
                ></div>

                <!-- Step 3: Executive HR Authorization -->
                <div 
                  class="step-circle"
                  :class="'step-circle-' + step3State"
                  :style="stepperTrackPositions.circles[2] ? { top: stepperTrackPositions.circles[2].top + 'px' } : undefined"
                  :title="step3State === 'pending' ? 'Pending Sign-off' : (step3State === 'rejected' ? 'Rejected' : 'Approved')"
                >
                  <Clock v-if="step3State === 'pending'" :size="20" class="step-icon-white" :stroke-width="2" />
                  <X v-else-if="step3State === 'rejected'" :size="20" class="step-icon-white" :stroke-width="2.5" />
                  <Check v-else :size="20" class="step-icon-white" :stroke-width="2.5" />
                </div>

                <!-- Connector Line 3: Step 3 -> Step 4 -->
                <div 
                  class="step-line-3"
                  :class="getConnectorLineClass(step3State, step4State)"
                  :style="stepperTrackPositions.lines[2] ? { top: stepperTrackPositions.lines[2].top + 'px', height: stepperTrackPositions.lines[2].height + 'px' } : undefined"
                ></div>

                <!-- Step 4: Active Quota Deployment -->
                <div 
                  class="step-circle"
                  :class="'step-circle-' + step4State"
                  :style="stepperTrackPositions.circles[3] ? { top: stepperTrackPositions.circles[3].top + 'px' } : undefined"
                  :title="step4State === 'queued' ? 'Queued' : 'Stamped'"
                >
                  <Clock v-if="step4State === 'queued'" :size="20" class="step-icon-disabled" :stroke-width="2" />
                  <Check v-else :size="20" class="step-icon-white" :stroke-width="2.5" />
                </div>
              </div>

              <!-- Stepper Content Cards Stack -->
              <div ref="stepperContentRef" class="stepper-content">
                <!-- Step 1 Card: Accrual & Service Computation -->
                <div class="step-card">
                  <div class="step-meta">
                    <span class="step-title">Accrual &amp; Service Computation</span>
                    <span class="step-actor">{{ allocation.created_by_name || 'Kassahun Belay (HR Operations)' }}</span>
                    <span class="step-time">Jul 8, 2026, 09:00 AM</span>
                  </div>
                </div>

                <!-- Step 2 Card: Statutory Policy Compliance -->
                <div class="step-card">
                  <div class="step-meta">
                    <span class="step-title">Statutory Policy Compliance</span>
                    <span class="step-actor">Automated Policy Rules Engine</span>
                    <span class="step-time">Jul 8, 2026, 09:05 AM</span>
                  </div>
                </div>

                <!-- Step 3 Card: Executive HR Authorization -->
                <div class="step-card">
                  <div class="step-meta" :class="{ 'step-meta-pending': allocation.allocation_state === 'draft' }">
                    <span class="step-title">Executive HR Authorization</span>
                    <span class="step-actor">{{ allocation.approved_by_name || 'Dawit Mengistu (HR Director)' }}</span>
                    <span class="step-time">{{ allocation.approved_at || 'Awaiting Sign-off' }}</span>
                  </div>
                </div>

                <!-- Step 4 Card: Active Quota Deployment -->
                <div class="step-card">
                  <div class="step-meta" :class="{ 'step-meta-queued': allocation.allocation_state === 'draft' }">
                    <span class="step-title" :class="{ 'text-muted': allocation.allocation_state === 'draft' }">
                      Active Quota Deployment
                    </span>
                    <span class="step-actor" :class="{ 'text-muted': allocation.allocation_state === 'draft' }">
                      Core Leave Ledger Stamping
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </aside>
    </div>

    <!-- ─── RESCHEDULE WINDOW MODAL ─── -->
    <div v-if="isRescheduleModalOpen" class="modal-backdrop" @click="isRescheduleModalOpen = false">
      <div class="reschedule-modal-card" @click.stop>
        <div class="modal-header">
          <div class="modal-title-block">
            <h3 class="modal-title">Reschedule Allocation Window</h3>
            <span class="modal-subtitle">Forward-chain {{ allocation?.code }} with formal statutory justification</span>
          </div>
          <button type="button" class="modal-close-btn" @click="isRescheduleModalOpen = false" aria-label="Close">
            <X :size="18" />
          </button>
        </div>

        <div class="modal-body">
          <div class="alert-info-box">
            <AlertCircle :size="18" class="text-blue flex-shrink-0" />
            <p class="alert-text">
              Per Haleta ERP schema governance, superseded allocation rows are immutable. Rescheduling marks the current row as <b>rescheduled</b> and automatically spawns a forward-chained successor allocation.
            </p>
          </div>

          <div class="modal-grid-2">
            <div class="form-group">
              <label class="form-label required">New Period Start</label>
              <FormInput
                type="date"
                v-model="rescheduleForm.new_period_start"
              />
            </div>

            <div class="form-group">
              <label class="form-label required">New Period End</label>
              <FormInput
                type="date"
                v-model="rescheduleForm.new_period_end"
              />
            </div>
          </div>

          <div class="form-group">
            <label class="form-label required">Business Justification / Reason</label>
            <FormInput
              v-model="rescheduleForm.reason"
              placeholder="Document operational necessity for deferring statutory rest period"
            />
          </div>
        </div>

        <div class="modal-footer">
          <AppButton variant="outline" size="sm" @click="isRescheduleModalOpen = false">
            Cancel
          </AppButton>
          <AppButton variant="primary" size="sm" @click="submitReschedule">
            <template #icon-left><RefreshCw :size="14" /></template>
            Confirm &amp; Spawn Forward-Chain
          </AppButton>
        </div>
      </div>
    </div>

    <!-- ═══ BOTTOM DRAWER: PRINT PREVIEW (Figma Node 5005:78527) ═══ -->
    <PrintPreviewDrawer
      v-if="allocation"
      v-model:show="isPrintDrawerOpen"
      title="Print Settings"
      subtitle="Configure Document layout and Visibility"
      documentTitle="Leave Entitlement Quota Certificate"
      :documentSubtitle="allocation.employee_name + ' • ' + allocation.employee_code"
      :documentCode="allocation.code"
      :documentDate="allocation.period_start + ' – ' + allocation.period_end"
      :documentMeta="allocation.total_entitled_days + ' Days • ' + allocation.leave_type_name"
      :currentPage="1"
      :totalPages="1"
    >
      <!-- Left Dynamic Customizations -->
      <template #settings>
        <div class="print-setting-toggle-row">
          <span class="print-setting-toggle-title">Accrual Formula Rules</span>
          <FormToggle v-model="printOptions.showAccrualFormula" size="sm" aria-label="Accrual Formula Rules" />
        </div>
        <div class="print-setting-toggle-row">
          <span class="print-setting-toggle-title">Ledger Usage History</span>
          <FormToggle v-model="printOptions.showLedgerHistory" size="sm" aria-label="Ledger Usage History" />
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
            <span class="print-meta-val">{{ allocation.employee_name }} ({{ allocation.employee_code }})</span>
          </div>
          <div class="print-meta-item">
            <span class="print-meta-lbl">Department &amp; Branch</span>
            <span class="print-meta-val">{{ allocation.department_name }} • {{ allocation.branch_name }}</span>
          </div>
          <div class="print-meta-item">
            <span class="print-meta-lbl">Entitlement Pool</span>
            <span class="print-meta-val">{{ allocation.total_entitled_days.toFixed(1) }} Days ({{ allocation.leave_type_name }})</span>
          </div>
        </div>

        <!-- Quota Balances Card -->
        <div class="print-sheet-section">
          <h4 class="print-section-title">Current Quota Ledger Balances</h4>
          <div class="print-info-grid">
            <div class="print-info-cell">
              <span class="cell-lbl">Total Entitled</span>
              <span class="cell-val font-bold">{{ allocation.total_entitled_days.toFixed(1) }} Days</span>
            </div>
            <div class="print-info-cell">
              <span class="cell-lbl">Consumed to Date</span>
              <span class="cell-val">{{ allocation.taken_days.toFixed(1) }} Days</span>
            </div>
            <div class="print-info-cell">
              <span class="cell-lbl">Remaining Available</span>
              <span class="cell-val font-bold text-success">{{ allocation.available_days.toFixed(1) }} Days</span>
            </div>
            <div class="print-info-cell">
              <span class="cell-lbl">Fiscal Validity Window</span>
              <span class="cell-val">{{ allocation.period_start }} – {{ allocation.period_end }}</span>
            </div>
          </div>
        </div>

        <!-- Accrual Formula Breakdown -->
        <div v-if="printOptions.showAccrualFormula" class="print-sheet-section">
          <h4 class="print-section-title">Statutory Accrual Formula Computation</h4>
          <table class="print-audit-table">
            <thead>
              <tr>
                <th>Entitlement Component</th>
                <th>Statutory Basis</th>
                <th>Accrual Formula</th>
                <th>Allotted Days</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td class="font-medium">Base Statutory Entitlement</td>
                <td>Proclamation 1156/2019</td>
                <td>16 working days for year 1</td>
                <td class="font-bold">16.0 Days</td>
              </tr>
              <tr>
                <td class="font-medium">Tenure Service Increment</td>
                <td>Article 77 Sub-Art 2</td>
                <td>+1 day per completed 2 years</td>
                <td class="font-bold">+{{ (allocation.total_entitled_days - 16.0).toFixed(1) }} Days</td>
              </tr>
              <tr class="table-row-highlight">
                <td colspan="3" class="font-bold text-right">Total Verified Fiscal Quota:</td>
                <td class="font-bold text-brand">{{ allocation.total_entitled_days.toFixed(1) }} Days</td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Official Seal & Signatures Block -->
        <div v-if="printOptions.showOfficialSeal" class="print-endorsement-footer">
          <div class="official-seal-wrapper">
            <svg class="official-stamp-svg" viewBox="0 0 160 160">
              <circle cx="80" cy="80" r="74" stroke="#0B529C" stroke-width="2.5" fill="none" opacity="0.85" />
              <circle cx="80" cy="80" r="68" stroke="#0B529C" stroke-width="1.2" stroke-dasharray="3,2" fill="none" opacity="0.85" />
              <path id="curveTopAlloc" d="M 22 80 A 58 58 0 0 1 138 80" fill="none" />
              <text font-size="8.5" font-weight="700" fill="#0B529C" opacity="0.85" letter-spacing="1.2">
                <textPath href="#curveTopAlloc" startOffset="50%" text-anchor="middle">
                  ★ HALETA HR OPERATIONS / AUDIT LEDGER ★
                </textPath>
              </text>
              <polygon points="80,50 83,62 95,62 85,70 88,82 80,74 72,82 75,70 65,62 77,62" fill="#0B529C" opacity="0.85" />
              <text x="80" y="96" font-size="10" font-weight="800" fill="#0B529C" text-anchor="middle" opacity="0.85">COMMITTED</text>
              <text x="80" y="107" font-size="7.5" font-weight="600" fill="#0B529C" text-anchor="middle" opacity="0.85">QUOTA CERTIFICATE</text>
              <path id="curveBottomAlloc" d="M 138 80 A 58 58 0 0 1 22 80" fill="none" />
              <text font-size="8.5" font-weight="700" fill="#0B529C" opacity="0.85" letter-spacing="1.2">
                <textPath href="#curveBottomAlloc" startOffset="50%" text-anchor="middle">
                  QMT ENTERPRISE MANAGEMENT
                </textPath>
              </text>
            </svg>
          </div>
          <div class="print-signatures-group">
            <div class="sig-column">
              <div class="sig-line"></div>
              <span class="sig-role">Compensation Analyst</span>
              <span class="sig-note">Calculated &amp; Verified</span>
            </div>
            <div class="sig-column">
              <div class="sig-line"></div>
              <span class="sig-role">HR Operations Director</span>
              <span class="sig-note">Authorized Ledger Seal</span>
            </div>
          </div>
        </div>
      </template>
    </PrintPreviewDrawer>
  </div>
</template>

<style scoped>
.allocation-detail-page {
  display: flex;
  flex-direction: column;
  gap: 24px;
  padding: 0;
  background-color: var(--color-background-primary, #fafafa);
  min-height: 100vh;
  width: 100%;
}

/* ─── Breadcrumb Bar (Strict Canvas Standard) ─── */
.breadcrumb-strip {
  display: flex;
  align-items: center;
  background: transparent;
  border: none;
  box-shadow: none;
  padding: 0;
  width: 100%;
}

/* ─── Master Split Layout (minmax(0, 1fr) 360px) ─── */
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
}

/* ─── Standard Dossier Card (Figma: rounded-16px, border #e5e5e5, white) ─── */
.dossier-card {
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* ─── 1. Master Entitlement Hero Card (Figma Node 8841:36806 Style) ─── */
.hero-card {
  padding: 20px 24px;
  gap: 16px;
}

.hero-card-main {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 20px;
}

.hero-left {
  display: flex;
  align-items: center;
  gap: 20px;
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
  margin: 0;
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
  font-weight: 600;
}

.meta-leave-type-row {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 20px;
}

/* Quota Pool Bar */
.quota-pool-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background-color: var(--color-background-primary, #fafafa);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 12px;
  padding: 10px 16px;
  flex-wrap: wrap;
  gap: 12px;
}

.pool-left {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--alias-color-text-secondary, #404040);
}

.pool-icon-award {
  color: var(--color-brand-blue-primary, #0b529c);
  flex-shrink: 0;
}

.pool-title {
  font-weight: 500;
}

.pool-number {
  color: var(--color-brand-blue-primary, #0b529c);
  font-size: 14px;
}

.pool-formula {
  font-size: 12px;
  color: var(--alias-color-text-tertiary, #737373);
}

.period-window-badge {
  font-size: 12px;
  font-weight: 500;
  color: var(--alias-color-text-tertiary, #737373);
}

/* ─── Callout Banners ─── */
.superseded-callout-card {
  display: flex;
  align-items: flex-start;
  gap: 14px;
  background-color: #faf5ff;
  border: 1px solid #e9d5ff;
  border-radius: 16px;
  padding: 16px 20px;
}

.callout-icon-box {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  background-color: #f3e8ff;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.callout-body {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.callout-title {
  font-size: 14px;
  font-weight: 600;
  color: #6b21a8;
  margin: 0;
}

.callout-text {
  font-size: 13px;
  color: #7e22ce;
  margin: 0;
  line-height: 20px;
}

.callout-forward-action {
  margin-top: 8px;
}

.btn-forward-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #7e22ce;
  color: #ffffff;
  border: none;
  border-radius: 6px;
  padding: 6px 12px;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-forward-link:hover {
  background-color: #6b21a8;
}

.predecessor-callout-card {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #fafafa;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  padding: 10px 16px;
  font-size: 13px;
  color: var(--alias-color-text-secondary, #404040);
}

.predecessor-link {
  color: #7e22ce;
  cursor: pointer;
  text-decoration: underline;
}

/* ─── 2. KPI Metrics Grid ─── */
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

.card-header-flex {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
}

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

.kpi-card-brand {
  background-color: #f1f7fe;
  border-color: #83bff6;
}

.kpi-value-brand {
  color: #0b529c;
}

/* ─── 3. Sub-Table Styling (Figma Node 7009:114645 Clean Standard) ─── */
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
  padding: 0 20px;
  border-bottom: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  font-size: 12px;
  font-weight: 500;
  color: #374151;
  text-align: left;
  line-height: 18px;
}

.schedule-table td {
  height: 52px;
  padding: 0 20px;
  border-bottom: 1px solid #e9eaeb;
  font-size: 14px;
  line-height: 20px;
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

.th-action, .td-action {
  width: 60px;
  text-align: center;
}

.table-row-clickable {
  cursor: pointer;
  transition: background-color 0.12s ease;
}

.table-row-clickable:hover {
  background-color: #fafafa;
}

.doc-code-link {
  font-weight: 600;
  color: var(--color-brand-blue-primary, #0b529c);
}

.td-meta-text {
  color: var(--alias-color-text-tertiary, #737373);
}

.td-days-bold {
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
}

.btn-icon-link {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: var(--color-brand-blue-primary, #0b529c);
  cursor: pointer;
  transition: background-color 0.12s ease;
}

.btn-icon-link:hover {
  background-color: #eff6ff;
}

.empty-table-cell {
  text-align: center;
  padding: 36px 20px !important;
}

.empty-icon {
  margin-bottom: 6px;
}

.empty-text {
  font-size: 13px;
  color: var(--alias-color-text-tertiary, #737373);
  margin: 0;
}

/* ─── 4. Compliance Parameters Grid ─── */
.params-four-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
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
  font-size: 12px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 18px;
  font-weight: 500;
}

.param-val {
  font-size: 14px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  line-height: 20px;
}

.param-sub {
  font-size: 12px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 16px;
}

.param-badge-row {
  margin-top: 2px;
}

.statement-box {
  background-color: var(--color-background-primary, #fafafa);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 12px;
  padding: 14px 18px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.statement-tag {
  font-size: 11px;
  font-weight: 600;
  color: var(--alias-color-text-tertiary, #737373);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.statement-text {
  font-size: 13px;
  line-height: 20px;
  color: var(--alias-color-text-secondary, #404040);
  margin: 0;
  font-style: italic;
}

/* ─── Right Column: Approval Timeline Rail (360px / Collapsed 68px) ─── */
.rail-card {
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.rail-card-collapsed {
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

/* Quota Review Box */
.quota-summary-box {
  background-color: var(--color-background-primary, #fafafa);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 12px;
  padding: 12px 16px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.qsb-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13px;
}

.qsb-label {
  color: var(--alias-color-text-tertiary, #737373);
}

.qsb-value {
  color: var(--alias-color-text-secondary, #404040);
  font-weight: 600;
}

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

.approver-action-buttons {
  display: flex;
  align-items: center;
  gap: 10px;
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

/* Consumed State */
.consumed-audit-box {
  background-color: #f5f5f5;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 12px 16px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.rail-divider {
  border: none;
  border-top: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  margin: 4px 0;
  width: 100%;
}

/* ─── Stepper Workflow (Figma Node 7009:114684 Standard) ─── */
.stepper-wrap {
  display: flex;
  gap: 16px;
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

/* Fallback default top positions */
.step-circle:nth-of-type(1) { top: 6px; }
.step-circle:nth-of-type(2) { top: 80px; }
.step-circle:nth-of-type(3) { top: 154px; }
.step-circle:nth-of-type(4) { top: 228px; }

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
.step-line-2,
.step-line-3 {
  position: absolute;
  left: 21px;
  width: 2px;
  z-index: 1;
  transition: top 0.15s ease, height 0.15s ease;
}

/* Fallbacks */
.step-line-1 { top: 50px; height: 30px; }
.step-line-2 { top: 124px; height: 30px; }
.step-line-3 { top: 198px; height: 30px; }

.step-line-solid-blue {
  background-color: #0b529c;
}

.step-line-solid-gray {
  background-color: #d4d4d4;
}

.step-line-gradient-blue-to-orange {
  background: linear-gradient(180deg, #0b529c 0%, #fe9a00 100%);
}

.step-line-gradient-orange-to-gray {
  background: linear-gradient(180deg, #fe9a00 0%, #d4d4d4 100%);
}

.step-line-gradient-blue-to-red {
  background: linear-gradient(180deg, #0b529c 0%, #e7000b 100%);
}

.step-line-gradient-blue-to-gray {
  background: linear-gradient(180deg, #0b529c 0%, #d4d4d4 100%);
}

.stepper-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.step-card {
  background-color: var(--color-background-primary, #fafafa);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 12px;
  padding: 8px 14px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-height: 54px;
  justify-content: center;
}

.step-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.step-title {
  font-size: 12px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  line-height: 16px;
}

.step-actor {
  font-size: 11px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 14px;
}

.step-time {
  font-size: 10px;
  color: var(--alias-color-text-tertiary, #737373);
}

.text-muted {
  color: #a1a1a1 !important;
}

/* ─── Reschedule Modal ─── */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(2px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.reschedule-modal-card {
  background-color: #ffffff;
  border-radius: 16px;
  width: 100%;
  max-width: 580px;
  display: flex;
  flex-direction: column;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.12);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  overflow: hidden;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 20px 24px;
  border-bottom: 1px solid var(--alias-color-border-subtle, #e5e5e5);
}

.modal-title-block {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.modal-title {
  font-size: 18px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  margin: 0;
}

.modal-subtitle {
  font-size: 13px;
  color: var(--alias-color-text-tertiary, #737373);
}

.modal-close-btn {
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 4px;
  border-radius: 6px;
}

.modal-close-btn:hover {
  background-color: #f5f5f5;
  color: #404040;
}

.modal-body {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.alert-info-box {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  background-color: #f0f9ff;
  border: 1px solid #b9e6fe;
  border-radius: 12px;
  padding: 12px 14px;
}

.alert-text {
  font-size: 13px;
  line-height: 18px;
  color: #026aa2;
  margin: 0;
}

.modal-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 16px 24px;
  background-color: var(--color-background-primary, #fafafa);
  border-top: 1px solid var(--alias-color-border-subtle, #e5e5e5);
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
