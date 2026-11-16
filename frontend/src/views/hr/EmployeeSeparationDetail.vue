<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  Clock, ShieldCheck, CheckSquare,
  Receipt, AlertCircle, X, AlertTriangle,
  ArrowRight, Banknote, DollarSign, Plus,
  Zap
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseTabs from '../../components/BaseTabs.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import { useToast } from '../../composables/useToast';
import {
  separationsData,
  clearanceItemsData,
  finalSettlementsData,
  SEPARATION_TYPE_MAP,
  SEPARATION_STATUS_MAP,
  CLEARANCE_STATE_MAP,
  updateClearanceState,
  updateSettlementStatus,
  type EmployeeSeparationRecord,
  type SeparationStatus,
  type ClearanceItemState
} from './separationData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

const separationId = computed(() => Number(route.params.id) || 12);

const separationCase = computed<EmployeeSeparationRecord | undefined>(() => {
  return separationsData.value.find(s => s.id === separationId.value) || separationsData.value[1];
});

// Breadcrumb Standard (AGENTS.md Rule 3 & 4)
// [Monitor] > Employee Separations > SEP-2026-0012 - Binyam Getachew
const breadcrumbItems = computed(() => [
  { label: 'Employee Separations', to: '/hr/separations' },
  { label: `${separationCase.value?.code || 'Exit Case'} - ${separationCase.value?.employee_name || 'Details'}` }
]);

const activeTab = ref('overview');
const detailTabs = [
  { id: 'overview', label: 'Case Overview & Narrative' },
  { id: 'clearance', label: 'Department Clearance Status' },
  { id: 'settlement', label: 'Settlement & Terminal Pay' }
];

const relatedClearanceItems = computed(() => {
  if (!separationCase.value) return [];
  return clearanceItemsData.value.filter(c => c.employee_separation_id === separationCase.value?.id);
});

const relatedSettlement = computed(() => {
  if (!separationCase.value) return undefined;
  return finalSettlementsData.value.find(s => s.employee_separation_id === separationCase.value?.id);
});

// Universal Date Formatter (AGENTS.md Rule 22)
const formatDate = (dateStr?: string | null) => {
  if (!dateStr) return '-';
  try {
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  } catch {
    return dateStr;
  }
};

const getSeparationStatusBadgeColor = (state: SeparationStatus): 'success' | 'warning' | 'error' | 'blue' | 'purple' | 'gray' => {
  switch (state) {
    case 'approved':
    case 'cleared':
    case 'settled':
      return 'success';
    case 'pending':
      return 'warning';
    case 'in_clearance':
      return 'purple';
    case 'draft':
      return 'blue';
    case 'cancelled':
      return 'error';
    default:
      return 'gray';
  }
};

const getClearanceItemBadgeColor = (state: ClearanceItemState): 'success' | 'warning' | 'error' | 'gray' => {
  switch (state) {
    case 'cleared':
      return 'success';
    case 'pending':
      return 'warning';
    case 'flagged':
      return 'error';
    case 'waived':
      return 'gray';
    default:
      return 'gray';
  }
};

const handleApproveCase = () => {
  if (!separationCase.value) return;
  separationCase.value.separation_state = 'approved';
  separationCase.value.approved_by_name = 'Solomon Worku (HR Director)';
  separationCase.value.approved_at = new Date().toISOString();
  toast.success('Case Approved', `Exit case ${separationCase.value.code} approved. Clearance initiated.`);
};

const handleRejectCase = () => {
  if (!separationCase.value) return;
  separationCase.value.separation_state = 'cancelled';
  toast.error('Case Cancelled', `Exit case ${separationCase.value.code} rejected and cancelled.`);
};

const handleSendToClearance = () => {
  if (!separationCase.value) return;
  separationCase.value.separation_state = 'in_clearance';
  toast.info('Clearance Active', `Exit case ${separationCase.value.code} advanced to active clearance.`);
};

const handleApproveSettlement = () => {
  if (!relatedSettlement.value) return;
  relatedSettlement.value.settlement_state = 'approved';
  relatedSettlement.value.approved_by_name = 'Solomon Worku (HR Director)';
  relatedSettlement.value.approved_at = new Date().toISOString();
  toast.success('Settlement Approved', `Settlement ${relatedSettlement.value.code} approved for payment disbursement.`);
};

const handleDisburseSettlement = () => {
  if (!relatedSettlement.value) return;
  relatedSettlement.value.settlement_state = 'paid';
  relatedSettlement.value.paid_at = new Date().toISOString();
  relatedSettlement.value.payroll_run_code = 'PR-2026-FST-008';
  toast.success('Settlement Disbursed', `Settlement ${relatedSettlement.value.code} successfully disbursed via payroll batch.`);
};
</script>

<template>
  <div class="detail-page-container">
    <!-- Top Bar: Breadcrumbs (Rule 10 & 15: Zero Back Buttons, Breadcrumbs Only) -->
    <div class="detail-top-nav">
      <AppBreadcrumb :items="breadcrumbItems" noMargin>
        <template #badge>
          <BaseBadge 
            v-if="separationCase"
            :color="getSeparationStatusBadgeColor(separationCase.separation_state)"
            size="sm"
          >
            {{ SEPARATION_STATUS_MAP[separationCase.separation_state].label }}
          </BaseBadge>
        </template>
      </AppBreadcrumb>
    </div>

    <!-- Master-to-Detail Split Layout (Rule 15: Golden Triad) -->
    <div v-if="separationCase" class="detail-layout-grid">
      
      <!-- Left Column: Sticky Identity Profile Card -->
      <div class="left-profile-sidebar">
        <div class="sidebar-identity-card">
          <div class="avatar-hero-container">
            <img :src="separationCase.employee_avatar" :alt="separationCase.employee_name" class="hero-avatar" />
            <BaseBadge 
              :color="getSeparationStatusBadgeColor(separationCase.separation_state)"
              size="sm"
            >
              {{ SEPARATION_STATUS_MAP[separationCase.separation_state].label }}
            </BaseBadge>
          </div>

          <h2 class="profile-name">{{ separationCase.employee_name }}</h2>
          <span class="profile-sub">{{ separationCase.employee_code }} • {{ separationCase.position }}</span>
          <span class="profile-dept">{{ separationCase.department }}</span>

          <div class="sidebar-divider"></div>

          <!-- Exit Metadata Rows -->
          <div class="sidebar-meta-list">
            <div class="meta-item">
              <span class="meta-label">Document Code</span>
              <span class="meta-value font-mono">{{ separationCase.code }}</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Separation Mode</span>
              <span class="meta-value">{{ SEPARATION_TYPE_MAP[separationCase.separation_type] }}</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Notice Date</span>
              <span class="meta-value">{{ formatDate(separationCase.notice_date) }}</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Last Working Date</span>
              <span class="meta-value">{{ formatDate(separationCase.last_working_date) }}</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Rehire Verdict</span>
              <span class="meta-value" :class="separationCase.is_rehire_eligible ? 'text-success' : 'text-danger'">
                {{ separationCase.is_rehire_eligible ? 'Eligible for Rehire' : 'Restricted / Ineligible' }}
              </span>
            </div>
            <div v-if="separationCase.approved_by_name" class="meta-item">
              <span class="meta-label">Approved By</span>
              <span class="meta-value">{{ separationCase.approved_by_name }}</span>
            </div>
          </div>

          <!-- Quick Case Actions Block -->
          <div class="sidebar-actions-block">
            <AppButton 
              v-if="separationCase.separation_state === 'pending'"
              variant="primary"
              size="sm"
              @click="handleApproveCase"
            >
              Approve Separation
            </AppButton>
            <router-link 
              v-if="separationCase.separation_state === 'approved'"
              :to="{ path: '/hr/exit-clearance', query: { separation_id: String(separationCase.id), openRegister: 'true' } }"
              class="btn-sidebar-action is-accent"
            >
              <Plus :size="14" />
              <span>Register Clearance</span>
            </router-link>
            <router-link 
              :to="{ path: '/hr/exit-clearance', query: { separation_id: String(separationCase.id) } }" 
              class="btn-sidebar-action is-secondary"
            >
              <CheckSquare :size="14" />
              <span>Exit Clearance Board</span>
            </router-link>
          </div>
        </div>
      </div>

      <!-- Right Column: Tabbed Content Container -->
      <div class="right-content-area">
        <!-- Top Tabs (AGENTS.md Rule 1: BaseTabs) -->
        <div class="tabs-bar-wrapper">
          <BaseTabs 
            v-model="activeTab" 
            :tabs="detailTabs" 
          />
        </div>

        <!-- TAB 1: Case Overview & Narrative -->
        <div v-if="activeTab === 'overview'" class="content-tab-card">
          <div class="card-section">
            <h3 class="section-heading">Resignation Notice & Reason</h3>
            <p class="narrative-paragraph">{{ separationCase.reason }}</p>
          </div>

          <div v-if="separationCase.exit_interview_note" class="card-section" style="margin-top: 20px;">
            <h3 class="section-heading">Exit Interview Feedback & Remarks</h3>
            <p class="narrative-paragraph">{{ separationCase.exit_interview_note }}</p>
          </div>

          <div v-if="separationCase.disciplinary_reference" class="card-section" style="margin-top: 20px;">
            <h3 class="section-heading">Disciplinary Committee Origin</h3>
            <div class="disciplinary-callout">
              <AlertTriangle :size="16" class="text-warning" />
              <div>
                <span class="callout-title">Cause Reference: {{ separationCase.disciplinary_reference }}</span>
                <p class="callout-desc">Termination initiated following formal disciplinary finding and board sign-off.</p>
              </div>
            </div>
          </div>

          <!-- Executive Approval & Governance Seal (Schema lines 2008-2009) -->
          <div class="card-section" style="margin-top: 24px; padding-top: 20px; border-top: 1px solid #f1f5f9;">
            <h3 class="section-heading">Governance &amp; Approval Sign-off</h3>
            
            <!-- When Pending: Action Decision Box -->
            <div v-if="separationCase.separation_state === 'pending'" class="approval-action-box">
              <div class="approval-header-flex">
                <div class="flex items-center gap-3">
                  <div class="icon-circle is-pending">
                    <Clock :size="18" />
                  </div>
                  <div>
                    <span class="approval-box-title">Separation Notice Awaiting Formal Approval</span>
                    <p class="approval-box-desc">Requires HR Director endorsement to authorize statutory notice period and unlock departmental clearance items.</p>
                  </div>
                </div>
              </div>
              <div class="approval-btn-group">
                <AppButton 
                  variant="destructive" 
                  size="sm" 
                  @click="handleRejectCase"
                >
                  <template #icon-left><X :size="14" /></template>
                  Reject / Cancel Notice
                </AppButton>
                <AppButton 
                  variant="primary" 
                  size="sm" 
                  @click="handleApproveCase"
                >
                  Approve &amp; Authorize Clearance
                </AppButton>
              </div>
            </div>

            <!-- When Approved / In Clearance / Settled: Official Certified Seal -->
            <div v-else-if="separationCase.approved_by_name || ['approved', 'in_clearance', 'cleared', 'settled'].includes(separationCase.separation_state)" class="certified-signoff-card">
              <div class="seal-icon-circle">
                <ShieldCheck :size="20" class="text-emerald" />
              </div>
              <div class="seal-content">
                <div class="seal-title-row">
                  <span class="seal-title">Authorized &amp; Approved for Clearance</span>
                  <span class="seal-pill">Approved</span>
                </div>
                <div class="signatory-row">
                  <span class="signatory-label">Authorized Signatory:</span>
                  <span class="signatory-name">{{ separationCase.approved_by_name || 'Solomon Worku (HR Director)' }}</span>
                  <span class="dot-sep">&bull;</span>
                  <span class="signatory-time">Timestamp: {{ formatDate(separationCase.approved_at) || 'Jul 15, 2026' }}</span>
                </div>
              </div>
            </div>

            <!-- When Approved: Prominent Clearance Registration Prompt (Direct handoff to Exit Clearance) -->
            <div v-if="separationCase.separation_state === 'approved'" class="clearance-handoff-banner">
              <div class="handoff-content">
                <div class="handoff-icon">
                  <CheckSquare :size="18" />
                </div>
                <div>
                  <h4 class="handoff-title">Ready for Departmental Exit Clearance</h4>
                  <p class="handoff-desc">Official sign-off is complete. You can now register checkpoints (IT, Facilities, Finance, HR) on the dedicated Exit Clearance page.</p>
                </div>
              </div>
              <router-link
                :to="{ path: '/hr/exit-clearance', query: { separation_id: String(separationCase.id), openRegister: 'true' } }"
                class="btn-handoff-action"
              >
                <Plus :size="14" />
                <span>Register Clearance Items</span>
                <ArrowRight :size="14" />
              </router-link>
            </div>

            <!-- When Cancelled -->
            <div v-else-if="separationCase.separation_state === 'cancelled'" class="cancelled-signoff-card">
              <AlertCircle :size="18" class="text-danger" />
              <span>This separation notice was formally rejected and cancelled. No further clearance or settlement actions are permitted.</span>
            </div>
          </div>
        </div>

        <!-- TAB 2: Department Clearance Status -->
        <div v-if="activeTab === 'clearance'" class="content-tab-card">
          <div class="tab-header-row">
            <div>
              <h3 class="section-heading">Department Sign-off Registry (ClearanceItem)</h3>
              <p class="section-subtitle">Track hardware surrender, IT access revocation, and financial float clearances.</p>
            </div>
            <router-link 
              :to="{ path: '/hr/exit-clearance', query: { separation_id: String(separationCase.id) } }" 
              class="btn-link-action"
            >
              Open in Exit Clearance Workspace →
            </router-link>
          </div>

          <!-- If Approved & No Items Registered Yet: Action Box to Register Checkpoints -->
          <div v-if="separationCase.separation_state === 'approved' && relatedClearanceItems.length === 0" class="clearance-empty-action-box">
            <div class="empty-icon-circle">
              <CheckSquare :size="20" />
            </div>
            <div class="empty-text-wrap">
              <span class="empty-action-title">No Clearance Checkpoints Registered Yet</span>
              <p class="empty-action-desc">
                Since this exit case has been approved by HR, open the Exit Clearance workspace to register checkpoints or initialize the standard 4-checkpoint checklist.
              </p>
            </div>
            <router-link
              :to="{ path: '/hr/exit-clearance', query: { separation_id: String(separationCase.id), openRegister: 'true' } }"
              class="btn-primary-action-compact"
            >
              <Plus :size="14" />
              <span>Register Clearance Items</span>
            </router-link>
          </div>

          <!-- Nested Mini-Table (AGENTS.md Rule 15) -->
          <table class="nested-mini-table">
            <thead>
              <tr>
                <th>#</th>
                <th>Clearance Item</th>
                <th>Department</th>
                <th>Clearance Status</th>
                <th>Flagged Deduction</th>
                <th>Cleared By</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="relatedClearanceItems.length === 0">
                <td colspan="6" class="td-empty">No clearance items provisioned for this exit case.</td>
              </tr>
              <tr v-for="(item, idx) in relatedClearanceItems" :key="item.id">
                <td class="td-num">{{ idx + 1 }}</td>
                <td class="td-title">{{ item.title }}</td>
                <td class="td-dept">{{ item.organization_unit_name }}</td>
                <td>
                  <BaseBadge 
                    :color="getClearanceItemBadgeColor(item.clearance_state)" 
                    size="sm"
                  >
                    {{ CLEARANCE_STATE_MAP[item.clearance_state].label }}
                  </BaseBadge>
                </td>
                <td class="font-numeric">
                  <span v-if="item.flagged_amount" class="text-danger">
                    {{ item.flagged_amount.toLocaleString('en-US', { minimumFractionDigits: 2 }) }} ETB
                  </span>
                  <span v-else>-</span>
                </td>
                <td class="td-cleared-by">{{ item.cleared_by_name || '-' }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- TAB 3: Settlement & Terminal Pay -->
        <div v-if="activeTab === 'settlement'" class="content-tab-card">
          <div v-if="relatedSettlement" class="settlement-detail-stack">
            <div class="settlement-summary-box">
              <div class="summary-col">
                <span class="sum-label">Settlement Reference</span>
                <span class="sum-val font-mono">{{ relatedSettlement.code }}</span>
              </div>
              <div class="summary-col">
                <span class="sum-label">Tenure</span>
                <span class="sum-val">{{ relatedSettlement.service_years.toFixed(2) }} Years</span>
              </div>
              <div class="summary-col">
                <span class="sum-label">Total Gross</span>
                <span class="sum-val text-success">+{{ relatedSettlement.gross_amount.toLocaleString() }} ETB</span>
              </div>
              <div class="summary-col">
                <span class="sum-label">Deductions</span>
                <span class="sum-val text-danger">-{{ relatedSettlement.deduction_amount.toLocaleString() }} ETB</span>
              </div>
              <div class="summary-col is-net">
                <span class="sum-label">Net Payable</span>
                <span class="sum-val text-net">{{ relatedSettlement.net_amount.toLocaleString() }} ETB</span>
              </div>
            </div>

            <!-- Dynamic Sub-Table of Lines -->
            <h4 class="subtable-heading">Final Settlement Line Items</h4>
            <table class="nested-mini-table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Line Type</th>
                  <th>Description</th>
                  <th style="text-align: right;">Amount (ETB)</th>
                  <th>Source</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(l, idx) in relatedSettlement.lines" :key="l.id">
                  <td class="td-num">{{ idx + 1 }}</td>
                  <td class="td-title">{{ l.line_type }}</td>
                  <td class="td-dept">{{ l.description }}</td>
                  <td class="font-numeric" style="text-align: right;" :class="l.amount >= 0 ? 'text-success' : 'text-danger'">
                    {{ l.amount >= 0 ? '+' : '' }}{{ l.amount.toLocaleString('en-US', { minimumFractionDigits: 2 }) }}
                  </td>
                  <td class="td-cleared-by">{{ l.source_type }}</td>
                </tr>
              </tbody>
            </table>

            <!-- Settlement Payout Governance & Sign-off Card (Schema lines 2061-2063) -->
            <div class="card-section" style="margin-top: 24px; padding-top: 20px; border-top: 1px solid #f1f5f9;">
              <h4 class="subtable-heading" style="margin-bottom: 12px;">Settlement Governance &amp; Payment Sign-off</h4>
              
              <!-- State: Draft -> Ready for Calculation -->
              <div v-if="relatedSettlement.settlement_state === 'draft'" class="approval-action-box">
                <div class="approval-header-flex">
                  <div class="flex items-center gap-3">
                    <div class="icon-circle is-pending">
                      <Zap :size="18" />
                    </div>
                    <div>
                      <span class="approval-box-title">Exit Case Ready for Terminal Settlement Calculation</span>
                      <p class="approval-box-desc">Clearance and separation notice are completed. Compute severance, accrued leave, and clearance deduction offsets.</p>
                    </div>
                  </div>
                  <router-link to="/hr/final-settlements" class="btn-approval-confirm">
                    <Zap :size="14" />
                    <span>Open in Final Settlements to Compute</span>
                  </router-link>
                </div>
              </div>

              <!-- State: Calculated -> Ready for Approval -->
              <div v-else-if="relatedSettlement.settlement_state === 'calculated'" class="approval-action-box">
                <div class="approval-header-flex">
                  <div class="flex items-center gap-3">
                    <div class="icon-circle is-pending">
                      <Receipt :size="18" />
                    </div>
                    <div>
                      <span class="approval-box-title">Terminal Payout Awaiting Sign-off</span>
                      <p class="approval-box-desc">Verify severance, leave accruals, and clearance deduction offsets before approving payroll disbursement.</p>
                    </div>
                  </div>
                  <AppButton variant="primary" size="sm" @click="handleApproveSettlement">
                    Approve Settlement for Payout
                  </AppButton>
                </div>
              </div>

              <!-- State: Approved -> Ready for Disbursement -->
              <div v-else-if="relatedSettlement.settlement_state === 'approved'" class="approval-action-box">
                <div class="approval-header-flex">
                  <div class="flex items-center gap-3">
                    <div class="icon-circle is-pending">
                      <Banknote :size="18" />
                    </div>
                    <div>
                      <span class="approval-box-title">Approved &amp; Ready for Batch Payout</span>
                      <p class="approval-box-desc">Approved by {{ relatedSettlement.approved_by_name || 'Solomon Worku (HR Director)' }}. Ready to settle terminal payout through PaymentBatch.</p>
                    </div>
                  </div>
                  <AppButton variant="primary" size="sm" @click="handleDisburseSettlement">
                    <template #icon-left><DollarSign :size="14" /></template>
                    Disburse Payment (Batch Payroll)
                  </AppButton>
                </div>
              </div>

              <!-- State: Paid -> Certified Disbursed Seal -->
              <div v-else-if="relatedSettlement.settlement_state === 'paid'" class="certified-signoff-card">
                <div class="seal-icon-circle">
                  <ShieldCheck :size="20" class="text-emerald" />
                </div>
                <div class="seal-content">
                  <div class="seal-title-row">
                    <span class="seal-title">Terminal Compensation Fully Disbursed</span>
                    <span class="seal-pill" style="background-color: #ecfdf5; color: #059669;">Disbursed &amp; Closed</span>
                  </div>
                  <div class="signatory-row">
                    <span class="signatory-label">Payroll Batch Ref:</span>
                    <span class="font-mono text-xs font-semibold">{{ relatedSettlement.payroll_run_code || 'PR-2026-FST-008' }}</span>
                    <span class="dot-sep">&bull;</span>
                    <span class="signatory-time">Disbursed Date: {{ formatDate(relatedSettlement.paid_at) || 'Aug 5, 2026' }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div v-else class="empty-settlement-state">
            <Receipt :size="32" class="empty-icon" />
            <h4 class="empty-title">Final Settlement Pending</h4>
            <p class="empty-desc">Terminal compensation has not yet been computed for this exit case. Complete clearance to calculate severance and leave encashment.</p>
            <router-link to="/hr/final-settlements" class="btn-create-calc">
              Calculate Settlement
            </router-link>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>

<style scoped>
.detail-page-container {
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  background-color: var(--primitive-color-neutral-50, #f8fafc);
  min-height: 100vh;
}

.detail-top-nav {
  display: flex;
  align-items: center;
}

/* Master Split Layout */
.detail-layout-grid {
  display: grid;
  grid-template-columns: 320px 1fr;
  gap: 20px;
  align-items: start;
}

/* Left Profile Sidebar */
.sidebar-identity-card {
  background-color: #ffffff;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  padding: 24px 20px;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.04);
  display: flex;
  flex-direction: column;
  position: sticky;
  top: 16px;
}

.avatar-hero-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}

.hero-avatar {
  width: 72px;
  height: 72px;
  border-radius: 50%;
  object-fit: cover;
  border: 3px solid #f1f5f9;
}

.profile-name {
  font-size: 17px;
  font-weight: 600;
  color: #404040;
  text-align: center;
  margin: 10px 0 2px;
}

.profile-sub {
  font-size: 12.5px;
  color: #737373;
  text-align: center;
}

.profile-dept {
  font-size: 12px;
  color: #94a3b8;
  text-align: center;
  margin-top: 2px;
}

.sidebar-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 16px 0;
}

.sidebar-meta-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.meta-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12.5px;
}

.meta-label {
  color: #737373;
}

.meta-value {
  color: #404040;
  font-weight: 500;
}

.font-mono {
  font-family: monospace;
}

.text-success {
  color: #059669;
}

.text-danger {
  color: #dc2626;
}

.sidebar-actions-block {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 20px;
}

.btn-sidebar-action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: 36px;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
  border: none;
  text-decoration: none;
  transition: all 0.15s ease;
}

.btn-sidebar-action.is-primary {
  background-color: #059669;
  color: #ffffff;
}

.btn-sidebar-action.is-primary:hover {
  background-color: #047857;
}

.btn-sidebar-action.is-accent {
  background-color: #0b529c;
  color: #ffffff;
}

.btn-sidebar-action.is-secondary {
  background-color: #f8fafc;
  color: #404040;
  border: 1px solid #e2e8f0;
}

.btn-sidebar-action.is-secondary:hover {
  background-color: #f1f5f9;
}

/* Right Content Area */
.right-content-area {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.tabs-bar-wrapper {
  margin-bottom: 2px;
}

.content-tab-card {
  background-color: #ffffff;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  padding: 24px;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.04);
}

.section-heading {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 6px;
}

.section-subtitle {
  font-size: 12px;
  color: #737373;
  margin: 0;
}

.narrative-paragraph {
  font-size: 13.5px;
  color: #404040;
  line-height: 1.6;
  background-color: #f8fafc;
  padding: 14px 16px;
  border-radius: 8px;
  border: 1px solid #f1f5f9;
  margin: 0;
}

.disciplinary-callout {
  display: flex;
  gap: 10px;
  background-color: #fffbeb;
  border: 1px solid #fef3c7;
  padding: 12px 16px;
  border-radius: 8px;
}

.callout-title {
  font-size: 13px;
  font-weight: 600;
  color: #92400e;
}

.callout-desc {
  font-size: 12px;
  color: #b45309;
  margin: 2px 0 0;
}

.tab-header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.btn-link-action {
  font-size: 12.5px;
  font-weight: 500;
  color: #0b529c;
  text-decoration: none;
}

/* Nested Mini Table */
.nested-mini-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12.5px;
}

.nested-mini-table th {
  height: 32px;
  padding: 6px 12px;
  background-color: #f8fafc;
  color: #737373;
  font-size: 11.5px;
  font-weight: 500;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

.nested-mini-table td {
  padding: 9px 12px;
  border-bottom: 1px solid #f1f5f9;
}

.td-num {
  width: 32px;
  color: #94a3b8;
}

.td-title {
  font-weight: 500;
  color: #404040;
}

.td-dept {
  color: #737373;
}

.td-cleared-by {
  color: #737373;
}



.font-numeric {
  font-variant-numeric: tabular-nums;
}

.settlement-summary-box {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 12px;
  background-color: #f8fafc;
  padding: 14px 18px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  margin-bottom: 20px;
}

.summary-col {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.sum-label {
  font-size: 11px;
  color: #737373;
}

.sum-val {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.text-net {
  color: #0b529c;
  font-size: 14.5px;
}

.subtable-heading {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 10px;
}

.empty-settlement-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px 20px;
  text-align: center;
}

.empty-icon {
  color: #94a3b8;
  margin-bottom: 10px;
}

.empty-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 6px;
}

.empty-desc {
  font-size: 13px;
  color: #737373;
  max-width: 440px;
  margin: 0 0 18px;
  line-height: 1.5;
}

.btn-create-calc {
  display: inline-flex;
  align-items: center;
  height: 36px;
  padding: 0 18px;
  border-radius: 8px;
  background-color: #0b529c;
  color: #ffffff;
  font-size: 13px;
  font-weight: 500;
  text-decoration: none;
}

/* Approval & Governance Sign-off Box Styles */
.approval-action-box {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.approval-header-flex {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}

.icon-circle {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.icon-circle.is-pending {
  background-color: #fef3c7;
  color: #b45309;
}

.approval-box-title {
  display: block;
  font-size: 13.5px;
  font-weight: 600;
  color: #1e293b;
  margin-bottom: 2px;
}

.approval-box-desc {
  font-size: 12px;
  color: #64748b;
  margin: 0;
  line-height: 1.45;
}

.approval-btn-group {
  display: flex;
  align-items: center;
  gap: 10px;
  align-self: flex-end;
}

.btn-approval-confirm {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 16px;
  border-radius: 8px;
  background-color: #0b529c;
  color: #ffffff;
  font-size: 12.5px;
  font-weight: 500;
  border: none;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-approval-confirm:hover {
  background-color: #09427d;
}

.btn-approval-reject {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 14px;
  border-radius: 8px;
  background-color: #fee2e2;
  color: #dc2626;
  font-size: 12.5px;
  font-weight: 500;
  border: none;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-approval-reject:hover {
  background-color: #fecaca;
}

.certified-signoff-card {
  display: flex;
  align-items: center;
  gap: 14px;
  background-color: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 10px;
  padding: 14px 18px;
}

.seal-icon-circle {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background-color: #d1fae5;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.seal-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.seal-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.seal-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #065f46;
}

.seal-pill {
  font-size: 11px;
  font-weight: 600;
  background-color: #d1fae5;
  color: #047857;
  padding: 2px 8px;
  border-radius: 9999px;
}

.signatory-row {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #047857;
}

.signatory-label {
  color: #065f46;
  font-weight: 500;
}

.signatory-name {
  font-weight: 600;
}

.signatory-time {
  color: #059669;
}

.cancelled-signoff-card {
  display: flex;
  align-items: center;
  gap: 10px;
  background-color: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 10px;
  padding: 14px 18px;
  font-size: 12.5px;
  color: #991b1b;
}

/* ─── Clearance Handoff Banners (AGENTS.md Rule 6: 8px Radius Buttons) ─── */
.clearance-handoff-banner {
  margin-top: 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
  border: 1px solid #bae6fd;
  border-radius: 10px;
  padding: 14px 18px;
}

.handoff-content {
  display: flex;
  align-items: center;
  gap: 12px;
}

.handoff-icon {
  width: 38px;
  height: 38px;
  border-radius: 8px;
  background-color: #0B529C;
  color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.handoff-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #0369a1;
  margin: 0 0 3px 0;
}

.handoff-desc {
  font-size: 12px;
  color: #0c4a6e;
  margin: 0;
  line-height: 1.45;
}

.btn-handoff-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 34px;
  padding: 0 14px;
  border-radius: 8px;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 12.5px;
  font-weight: 500;
  text-decoration: none;
  white-space: nowrap;
  flex-shrink: 0;
  transition: all 0.15s ease;
}

.btn-handoff-action:hover {
  background-color: #09427d;
  transform: translateY(-1px);
}

.clearance-empty-action-box {
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  background-color: #f8fafc;
  border: 1px dashed #cbd5e1;
  border-radius: 10px;
  padding: 16px 20px;
}

.empty-icon-circle {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  background-color: #e0f2fe;
  color: #0B529C;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.empty-text-wrap {
  flex: 1;
}

.empty-action-title {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
  display: block;
  margin-bottom: 2px;
}

.empty-action-desc {
  font-size: 12px;
  color: #737373;
  margin: 0;
  line-height: 1.4;
}

.btn-primary-action-compact {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 14px;
  border-radius: 8px;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 12.5px;
  font-weight: 500;
  text-decoration: none;
  white-space: nowrap;
  flex-shrink: 0;
  transition: all 0.15s ease;
}

.btn-primary-action-compact:hover {
  background-color: #09427d;
}
</style>
