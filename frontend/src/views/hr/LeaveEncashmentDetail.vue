<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import {
  CheckCircle2, XCircle, ShieldCheck, Calendar,
  Check, X, Printer, Edit3
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import FormInput from '../../components/FormInput.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import { 
  encashmentsData, 
  getEncashmentById, 
  submitApprovalDecision, 
  cancelEncashment, 
  type LeaveEncashmentRecord 
} from './leaveEncashmentData';

const route = useRoute();
const router = useRouter();

// ─── Record ID from Route ───
const encashmentId = computed(() => Number(route.params.id) || 2);

const currentItem = computed<LeaveEncashmentRecord>(() => {
  const item = getEncashmentById(encashmentId.value);
  if (item) return item;
  return encashmentsData.value[1] || encashmentsData.value[0];
});

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3 & 4) ───
// Breadcrumb IS the navigation (ZERO separate back buttons permitted)
const breadcrumbItems = computed(() => [
  { label: 'Leave Encashments', to: '/hr/leave-encashments' },
  { label: currentItem.value.code }
]);

// ─── Approver Decision Form State (Specific to Approval Stage) ───
// Fields that exist ONLY during approval:
// - resolution (approve | modify | reject)
// - approved_days (numeric 6,2 nullable - schema line 1796)
// - decisionRemarks (stored in approval audit / remarks)
const resolution = ref<'approve' | 'modify' | 'reject'>('approve');
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

// ─── Toast Feedback ───
const toastMessage = ref<string | null>(null);
const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Top Bar Actions ───
const handlePrintSlip = () => {
  window.print();
};

const handleCancelRequest = () => {
  if (confirm(`Are you sure you want to cancel encashment request ${currentItem.value.code}?`)) {
    cancelEncashment(currentItem.value.id);
    showToast(`Encashment request ${currentItem.value.code} has been cancelled.`);
  }
};

// ─── Submit Approver Decision Handler ───
const handleSubmitDecision = () => {
  if (resolution.value === 'modify') {
    if (!adjustedDaysInput.value || adjustedDaysInput.value <= 0) {
      alert('Please enter a valid number of adjusted days.');
      return;
    }
    if (adjustedDaysInput.value > currentItem.value.available_balance_before) {
      alert(`Adjusted days (${adjustedDaysInput.value}) cannot exceed available quota balance (${currentItem.value.available_balance_before} days).`);
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
        showToast(`Encashment ${currentItem.value.code} has been rejected.`);
      } else {
        showToast(`Encashment ${currentItem.value.code} approved! Quota debited and frozen daily rate locked.`);
      }
      decisionRemarks.value = '';
    }
  }, 350);
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
</script>

<template>
  <div class="encashment-approval-page">
    <!-- ─── TOP BAR (AGENTS.md Rule 3: AppBreadcrumb IS the navigation, ZERO back buttons) ─── -->
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
          Print Slip
        </AppButton>

        <AppButton
          v-if="currentItem.request_state === 'pending' || currentItem.request_state === 'draft'"
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

    <!-- ─── 1. DOCUMENT & REQUESTER HEADER CARD ─── -->
    <div class="approval-header-card">
      <div class="header-left">
        <img
          :src="currentItem.employee_avatar"
          :alt="currentItem.employee_name"
          class="requester-avatar"
        />
        <div class="header-details">
          <div class="title-row">
            <h1 class="requester-name">{{ currentItem.employee_name }}</h1>
            <span class="doc-code-pill font-mono">{{ currentItem.code }}</span>
            <span class="status-badge" :class="`status-${currentItem.request_state}`">
              {{ currentItem.request_state === 'approved' ? 'Approved' : currentItem.request_state === 'rejected' ? 'Rejected' : 'Pending Review' }}
            </span>
          </div>
          <p class="requester-meta">
            {{ currentItem.employee_code }} &bull; {{ currentItem.job_position }} &bull; {{ currentItem.department }}
          </p>
        </div>
      </div>

      <div class="header-right">
        <div class="bucket-pill" title="Debited LeaveAllocation Bucket">
          <Calendar :size="12" />
          <span>Bucket: {{ currentItem.allocation_code }}</span>
        </div>
        <div class="policy-pill">
          <ShieldCheck :size="12" />
          <span>{{ currentItem.leave_type_name }} &bull; Statutory Encashable</span>
        </div>
      </div>
    </div>

    <!-- ─── 2. ENCASED SNAPSHOT & STATUTORY RATE METRICS ─── -->
    <div class="metrics-summary-card">
      <div class="metric-block">
        <span class="m-label">Available Balance</span>
        <span class="m-value">{{ currentItem.available_balance_before.toFixed(1) }} Days</span>
        <span class="m-sub">{{ currentItem.total_entitled_days }}d entitled &bull; {{ currentItem.taken_days }}d taken</span>
      </div>

      <div class="m-divider"></div>

      <div class="metric-block">
        <span class="m-label">Requested Units</span>
        <span class="m-value font-semibold">{{ currentItem.requested_days.toFixed(1) }} Days</span>
        <span class="m-sub">Provisional quota deduction</span>
      </div>

      <div class="m-divider"></div>

      <div class="metric-block">
        <span class="m-label">Frozen Daily Rate</span>
        <span class="m-value font-semibold text-brand">ETB {{ formatCurrency(currentItem.daily_rate) }}</span>
        <span class="m-sub">Basic salary &divide; {{ currentItem.payroll_days_basis }} days basis</span>
      </div>

      <div class="m-divider"></div>

      <div class="metric-block highlight-payout">
        <span class="m-label">{{ currentItem.approved_days !== null ? 'Final Approved Payout' : 'Estimated Gross Payout' }}</span>
        <span class="m-value-big font-bold text-green">
          ETB {{ formatCurrency(currentItem.approved_days !== null ? currentItem.amount : computedAdjustedPayout) }}
        </span>
        <span class="m-sub">
          {{ (currentItem.approved_days ?? computedEffectiveDays).toFixed(1) }} Days &times; ETB {{ formatCurrency(currentItem.daily_rate) }}
        </span>
      </div>
    </div>

    <!-- ─── 3. EMPLOYEE JUSTIFICATION (SUBMITTED REASON) ─── -->
    <div class="justification-card">
      <h3 class="section-title">Encashment Justification &amp; Purpose</h3>
      <p class="justification-text">&ldquo;{{ currentItem.reason }}&rdquo;</p>
      <div class="justification-footer">
        <span>Submitted by employee on {{ formatDate(currentItem.created_at) }}</span>
        <span class="currency-tag">Currency: {{ currentItem.currency }}</span>
      </div>
    </div>

    <!-- ─── 4. APPROVAL-STAGE ONLY CONTROLS & LEDGER AUDIT ─── -->
    <!-- This section contains the controls and outputs that exist SOLELY during approval -->
    <div class="approval-action-card">
      <div class="action-card-header">
        <h3 class="section-title">Approver Authorization &amp; Ledger Sign-off</h3>
        <span class="stage-tag">Approval Stage Only</span>
      </div>

      <!-- STATE A: PENDING APPROVAL (Active interactive approver form) -->
      <div v-if="currentItem.request_state === 'pending'" class="pending-decision-form">
        <!-- 1. Resolution Mode Selector -->
        <div class="resolution-pills-row">
          <label class="form-label-top">Decision Verdict:</label>
          <div class="pills-container">
            <button
              type="button"
              class="btn-decision-pill"
              :class="{ 'is-selected approve': resolution === 'approve' }"
              @click="resolution = 'approve'"
            >
              <Check :size="14" />
              <span>Approve Full Request ({{ currentItem.requested_days.toFixed(1) }} Days)</span>
            </button>

            <button
              type="button"
              class="btn-decision-pill"
              :class="{ 'is-selected modify': resolution === 'modify' }"
              @click="resolution = 'modify'"
            >
              <Edit3 :size="14" />
              <span>Approve with Adjusted Days</span>
            </button>

            <button
              type="button"
              class="btn-decision-pill"
              :class="{ 'is-selected reject': resolution === 'reject' }"
              @click="resolution = 'reject'"
            >
              <X :size="14" />
              <span>Reject Request</span>
            </button>
          </div>
        </div>

        <!-- 2. Schema approved_days: appears ONLY when "modify" is selected -->
        <Transition name="fade">
          <div v-if="resolution === 'modify'" class="modify-days-panel">
            <div class="modify-input-group">
              <label class="form-label">Approved Days (numeric 6,2 per Schema line 1796):</label>
              <FormInput
                v-model="adjustedDaysInput"
                type="number"
                min="0.5"
                :max="currentItem.available_balance_before"
                step="0.5"
              />
            </div>
            <div class="modify-calc-feedback">
              <span>Recalculated Payout:</span>
              <strong class="text-green font-bold">ETB {{ formatCurrency(computedAdjustedPayout) }}</strong>
              <span class="text-sub">({{ adjustedDaysInput || 0 }}d &times; ETB {{ formatCurrency(currentItem.daily_rate) }} / day)</span>
            </div>
          </div>
        </Transition>

        <!-- 3. Approver Remarks -->
        <div class="form-group-remarks">
          <label class="form-label">
            {{ resolution === 'reject' ? 'Rejection Reason (Required for audit):' : 'Approver Authorization Remarks (Optional):' }}
          </label>
          <FormTextarea
            v-model="decisionRemarks"
            rows="2"
            :placeholder="resolution === 'reject' ? 'State operational workload or policy ceiling justification for rejection...' : 'Add any sign-off or payroll instructions...'"
          />
        </div>

        <!-- 4. Post-Approval Projection Summary -->
        <div class="pre-approval-impact">
          <Info :size="14" class="text-slate-500" />
          <span v-if="resolution !== 'reject'">
            Confirming will stamp <strong>frozen daily rate ETB {{ formatCurrency(currentItem.daily_rate) }}</strong>, 
            debit <strong>{{ computedEffectiveDays }} days</strong> from allocation <code>{{ currentItem.allocation_code }}</code> 
            (leaving <strong>{{ remainingAfterApproval }}d</strong>), and queue the cash payout for payroll.
          </span>
          <span v-else class="text-rose-600">
            Rejecting will close this request without any deductions to the employee's leave quota balance.
          </span>
        </div>

        <!-- 5. Decision Action Button -->
        <div class="decision-footer">
          <AppButton
            :variant="resolution === 'reject' ? 'destructive' : 'primary'"
            size="md"
            :disabled="isSubmittingDecision"
            :loading="isSubmittingDecision"
            @click="handleSubmitDecision"
          >
            <span v-if="resolution === 'approve'">Confirm Approval &amp; Lock Rate</span>
            <span v-else-if="resolution === 'modify'">Confirm Adjusted Approval ({{ adjustedDaysInput }}d)</span>
            <span v-else>Confirm Rejection</span>
          </AppButton>
        </div>
      </div>

      <!-- STATE B: ALREADY APPROVED (Immutable Ledger Stamping & Payroll Feeder) -->
      <div v-else-if="currentItem.request_state === 'approved'" class="approved-summary-box">
        <div class="status-summary-row">
          <div class="check-icon-wrap">
            <CheckCircle2 :size="20" class="text-emerald" />
          </div>
          <div class="summary-text-block">
            <h4 class="summary-title">Encashment Approved &amp; Rate Frozen</h4>
            <p class="summary-desc">
              Approved <strong>{{ currentItem.approved_days?.toFixed(1) }} Days</strong> at frozen daily rate 
              <strong>ETB {{ formatCurrency(currentItem.daily_rate) }}</strong> for a gross payout of 
              <strong class="text-emerald font-bold">ETB {{ formatCurrency(currentItem.amount) }}</strong>.
            </p>
          </div>
        </div>

        <!-- Schema Fields Generated Specifically on Approval -->
        <div class="ledger-fields-grid">
          <div class="lf-item">
            <span class="lf-lbl">Signed Ledger Transaction (line 1803):</span>
            <span class="lf-val font-mono text-brand">{{ currentItem.leave_transaction_id || 'LTR-2026-88124' }}</span>
          </div>

          <div class="lf-item">
            <span class="lf-lbl">Authorized By (line 1801):</span>
            <span class="lf-val">{{ currentItem.approver_name }} ({{ currentItem.approver_role }})</span>
          </div>

          <div class="lf-item">
            <span class="lf-lbl">Approved At (line 1802):</span>
            <span class="lf-val">{{ formatDate(currentItem.approved_at) }}</span>
          </div>

          <div class="lf-item">
            <span class="lf-lbl">PayrollInput Feeder (line 1806):</span>
            <span class="lf-val text-emerald font-medium">Billed to {{ currentItem.payroll_settlement_month }}</span>
          </div>
        </div>

        <div v-if="currentItem.approval_remarks" class="approval-remark-note">
          <span class="remark-lbl">Approver Note:</span>
          <p class="remark-content">&ldquo;{{ currentItem.approval_remarks }}&rdquo;</p>
        </div>
      </div>

      <!-- STATE C: REJECTED -->
      <div v-else-if="currentItem.request_state === 'rejected'" class="rejected-summary-box">
        <div class="status-summary-row">
          <XCircle :size="20" class="text-rose" />
          <div>
            <h4 class="summary-title text-rose">Encashment Request Rejected</h4>
            <p class="summary-desc">Request was reviewed and rejected. No quota was debited from allocation.</p>
          </div>
        </div>
        <div v-if="currentItem.approval_remarks" class="approval-remark-note">
          <span class="remark-lbl">Rejection Rationale:</span>
          <p class="remark-content">&ldquo;{{ currentItem.approval_remarks }}&rdquo;</p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.encashment-approval-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  width: 100%;
}

/* ─── Top Nav Bar (AppBreadcrumb IS navigation, ZERO back button) ─── */
.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0;
  background: transparent;
}
.top-nav-left {
  display: flex;
  align-items: center;
}
.top-nav-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-secondary-action {
  height: 38px;
  padding: 0 16px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  color: #404040;
  font-size: 13px;
  font-weight: 500;
  border-radius: 8px;
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-secondary-action:hover { background-color: #f8fafc; }

.btn-danger-action {
  height: 38px;
  padding: 0 16px;
  background-color: #ffffff;
  border: 1px solid #fecaca;
  color: #dc2626;
  font-size: 13px;
  font-weight: 500;
  border-radius: 8px;
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-danger-action:hover { background-color: #fef2f2; }

/* ─── 1. Document & Requester Header Card ─── */
.approval-header-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}
.header-left {
  display: flex;
  align-items: center;
  gap: 14px;
}
.requester-avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  object-fit: cover;
  border: 1.5px solid #e2e8f0;
}
.header-details {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.title-row {
  display: flex;
  align-items: center;
  gap: 8px;
}
.requester-name {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.doc-code-pill {
  font-size: 11.5px;
  color: #64748b;
  background-color: #f1f5f9;
  padding: 1px 6px;
  border-radius: 4px;
}
.status-badge {
  font-size: 11.5px;
  font-weight: 500;
  padding: 2px 8px;
  border-radius: 9999px;
}
.status-pending { background-color: #fef3c7; color: #b45309; }
.status-approved { background-color: #ecfdf5; color: #047857; }
.status-rejected { background-color: #fef2f2; color: #b91c1c; }

.requester-meta {
  font-size: 12px;
  color: #737373;
  margin: 0;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 8px;
}
.bucket-pill, .policy-pill {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 11.5px;
  color: #64748b;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 3px 8px;
  border-radius: 6px;
}
.policy-pill {
  color: #047857;
  background-color: #ecfdf5;
  border-color: #a7f3d0;
}

/* ─── 2. Metrics Summary Card ─── */
.metrics-summary-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
}
.metric-block {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.m-label {
  font-size: 11.5px;
  color: #737373;
  font-weight: 500;
}
.m-value {
  font-size: 17px;
  font-weight: 600;
  color: #404040;
}
.m-value-big {
  font-size: 20px;
}
.m-sub {
  font-size: 11px;
  color: #94a3b8;
}
.m-divider {
  width: 1px;
  height: 42px;
  background-color: #e2e8f0;
}

/* ─── 3. Justification Card ─── */
.justification-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 18px 24px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.section-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.justification-text {
  font-size: 13.5px;
  color: #404040;
  line-height: 1.5;
  margin: 0;
  background-color: #fafbfc;
  padding: 10px 14px;
  border-radius: 6px;
  border-left: 3px solid #0B529C;
}
.justification-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 11.5px;
  color: #737373;
}
.currency-tag {
  font-weight: 600;
  color: #64748b;
}

/* ─── 4. Approver Action Card (Approval Stage Only) ─── */
.approval-action-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.action-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid #f1f5f9;
  padding-bottom: 10px;
}
.stage-tag {
  font-size: 11px;
  font-weight: 600;
  color: #0B529C;
  background-color: #eff6ff;
  padding: 2px 8px;
  border-radius: 4px;
}

/* Pending Form */
.pending-decision-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.resolution-pills-row {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.form-label-top {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}
.pills-container {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}
.btn-decision-pill {
  height: 36px;
  padding: 0 14px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  background-color: #f8fafc;
  color: #404040;
  font-size: 12.5px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-decision-pill:hover { background-color: #f1f5f9; }
.btn-decision-pill.is-selected.approve {
  background-color: #ecfdf5;
  border-color: #10b981;
  color: #047857;
}
.btn-decision-pill.is-selected.modify {
  background-color: #eff6ff;
  border-color: #3b82f6;
  color: #1d4ed8;
}
.btn-decision-pill.is-selected.reject {
  background-color: #fef2f2;
  border-color: #ef4444;
  color: #b91c1c;
}

.modify-days-panel {
  display: flex;
  align-items: center;
  gap: 16px;
  background-color: #f8fafc;
  border: 1px dashed #cbd5e1;
  border-radius: 8px;
  padding: 12px 16px;
}
.modify-input-group {
  width: 240px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.modify-calc-feedback {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #404040;
}

.form-group-remarks {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.pre-approval-impact {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: #64748b;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 8px 14px;
  border-radius: 6px;
}
.pre-approval-impact code {
  font-family: monospace;
  background-color: #e2e8f0;
  padding: 1px 4px;
  border-radius: 3px;
}

.decision-footer {
  display: flex;
  justify-content: flex-end;
}
.btn-submit-verdict {
  height: 38px;
  padding: 0 20px;
  border: none;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  cursor: pointer;
  color: #ffffff;
  transition: opacity 0.15s ease;
}
.btn-submit-verdict.approve { background-color: #0B529C; }
.btn-submit-verdict.modify { background-color: #0B529C; }
.btn-submit-verdict.reject { background-color: #dc2626; }
.btn-submit-verdict:hover { opacity: 0.9; }

/* Approved Summary Box */
.approved-summary-box {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.status-summary-row {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}
.summary-title {
  font-size: 14.5px;
  font-weight: 600;
  color: #047857;
  margin: 0;
}
.summary-desc {
  font-size: 13px;
  color: #404040;
  margin: 2px 0 0 0;
}

.ledger-fields-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px 24px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 16px;
}
.lf-item {
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.lf-lbl {
  font-size: 11px;
  color: #737373;
}
.lf-val {
  font-size: 13px;
  color: #404040;
  font-weight: 500;
}

.approval-remark-note {
  background-color: #fafbfc;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  padding: 8px 12px;
  font-size: 12.5px;
}
.remark-lbl {
  font-weight: 600;
  color: #64748b;
  font-size: 11px;
}
.remark-content {
  margin: 2px 0 0 0;
  color: #404040;
}

/* Rejected Summary Box */
.rejected-summary-box {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

/* Utilities */
.text-brand { color: #0B529C; }
.text-green { color: #059669; }
.text-emerald { color: #047857; }
.text-rose { color: #dc2626; }
.font-bold { font-weight: 700; }
.font-semibold { font-weight: 600; }
.font-mono { font-family: monospace; }

/* Toast */
.toast-bar {
  position: fixed;
  top: 24px;
  right: 28px;
  background-color: #047857;
  color: #ffffff;
  padding: 10px 18px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 8px;
  box-shadow: 0 4px 14px rgba(4, 120, 87, 0.25);
  z-index: 9999;
}
</style>
