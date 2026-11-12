<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import {
  Award, Clock, User, CheckCircle2,
  X, AlertCircle, ArrowRight, ShieldCheck,
  RefreshCw, ArrowUpRight, Printer, CornerDownLeft
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import MetricCard from '../../components/MetricCard.vue';
import FormInput from '../../components/FormInput.vue';
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

// ─── Reactive Record Loader (Fixes Vue Router Component Reuse Bug) ───
const allocation = ref<LeaveAllocationRecord | undefined>(undefined);

const loadAllocation = () => {
  const idNum = Number(route.params.id) || 452;
  const target = getAllocationById(idNum) || allocationsData.value.find(a => a.id === 452) || allocationsData.value[0];
  allocation.value = target;
};

// Initial load + watch route params for immediate reactivity on forward-chaining
watch(() => route.params.id, () => {
  loadAllocation();
}, { immediate: true });

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3: Child Page Breadcrumb) ───
// STRICTLY NO separate back button! Breadcrumb itself is the sole navigation.
const breadcrumbItems = computed(() => [
  { label: 'Leave Allocations', to: '/hr/leave-allocations' },
  { label: allocation.value ? allocation.value.code : 'Allocation Detail' }
]);

const toastMessage = ref<string | null>(null);
const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Interactive Approver Decision State (Right-Rail Card) ───
const approverRemarks = ref('');
const isSubmittingDecision = ref(false);

const handleApprove = () => {
  if (!allocation.value) return;
  isSubmittingDecision.value = true;
  setTimeout(() => {
    isSubmittingDecision.value = false;
    if (!allocation.value) return;
    approveAllocation(allocation.value.id, approverRemarks.value);
    showToast(`Allocation ${allocation.value.code} officially certified and approved.`);
    approverRemarks.value = '';
  }, 350);
};

const handleReject = () => {
  if (!allocation.value) return;
  if (!approverRemarks.value.trim()) {
    alert('Please enter a justification or reason for rejection.');
    return;
  }
  isSubmittingDecision.value = true;
  setTimeout(() => {
    isSubmittingDecision.value = false;
    if (!allocation.value) return;
    rejectAllocation(allocation.value.id, approverRemarks.value);
    showToast(`Allocation ${allocation.value.code} has been rejected.`);
    approverRemarks.value = '';
  }, 350);
};

const handleMarkConsumed = () => {
  if (!allocation.value) return;
  allocation.value.allocation_state = 'consumed';
  allocation.value.available_days = 0;
  showToast(`Allocation ${allocation.value.code} marked as consumed at fiscal year close.`);
};

const handlePrintSlip = () => {
  window.print();
};

// ─── Rescheduling Modal (Schema Line 1647: forward chain when window moves) ───
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
    alert('Please enter a business justification for rescheduling this allocation window.');
    return;
  }

  const nextRecord = rescheduleAllocation(
    allocation.value.id,
    rescheduleForm.value.new_period_start,
    rescheduleForm.value.new_period_end,
    rescheduleForm.value.reason
  );

  isRescheduleModalOpen.value = false;
  showToast(`Allocation rescheduled into ${nextRecord?.code}.`);
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

const formatDateTime = (val?: string | null) => {
  if (!val) return '—';
  const d = new Date(val);
  return d.toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' });
};
</script>

<template>
  <div class="allocation-detail-page">
    <!-- Top Bar (AGENTS.md Rule 3 & Breadcrumb Standard, ZERO back button) -->
    <div class="top-nav-bar no-print">
      <div class="top-nav-left">
        <AppBreadcrumb :items="breadcrumbItems" no-margin />
      </div>

      <div class="top-actions-cluster" v-if="allocation">
        <!-- Print Slip Button -->
        <AppButton variant="outline" size="sm" @click="handlePrintSlip">
          <template #icon-left><Printer :size="14" /></template>
          Print Entitlement Slip
        </AppButton>

        <!-- Status Pill (LEAVE_ALLOCATION_STATE) -->
        <span class="status-pill" :class="`state-${allocation.allocation_state}`">
          {{ allocation.allocation_state.charAt(0).toUpperCase() + allocation.allocation_state.slice(1) }}
        </span>

        <!-- Contextual Action Buttons in Header -->
        <template v-if="allocation.allocation_state === 'approved'">
          <AppButton variant="outline" size="sm" @click="openRescheduleModal">
            <template #icon-left><RefreshCw :size="14" /></template>
            Reschedule Window
          </AppButton>
          <AppButton variant="outline" size="sm" @click="handleMarkConsumed">
            Close / Consume
          </AppButton>
        </template>
      </div>
    </div>

    <!-- Toast Feedback -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar no-print">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <div v-if="allocation" class="detail-split-layout">
      <!-- ═════════════════════════════════════════════════════════════
           LEFT COLUMN: Main Entitlement Dossier (Dossier Stack ~68%)
           ═════════════════════════════════════════════════════════════ -->
      <div class="main-dossier-column">
        <!-- Forward-Chain Superseded Notice Banner (if this row was rescheduled) -->
        <div v-if="allocation.allocation_state === 'rescheduled'" class="superseded-callout-card">
          <div class="callout-icon-box">
            <RefreshCw :size="18" class="text-purple-600" />
          </div>
          <div class="callout-body">
            <h4 class="callout-title">Allocation Window Superseded by Rescheduling</h4>
            <p class="callout-text">
              Per Haleta ERP schema governance (Line 1647), this record is immutable and frozen. 
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

        <!-- 1. MASTER ENTITLEMENT HOLDER CARD -->
        <div class="clean-card master-holder-card">
          <div class="card-hero-split">
            <!-- Employee Profile -->
            <div class="holder-profile">
              <img :src="allocation.employee_avatar" :alt="allocation.employee_name" class="holder-avatar" />
              <div class="holder-meta">
                <div class="name-row">
                  <h1 class="holder-name">{{ allocation.employee_name }}</h1>
                  <span class="holder-code">{{ allocation.employee_code }}</span>
                </div>
                <p class="holder-subtext">
                  {{ allocation.job_position }} &bull; {{ allocation.entity_name }}
                </p>
              </div>
            </div>

            <!-- Allocation Identification & Policy Link -->
            <div class="holder-alloc-info">
              <div class="alloc-badge-group">
                <span class="alloc-code-pill font-mono">{{ allocation.code }}</span>
                <span class="alloc-type-pill">{{ allocation.leave_type_name }}</span>
              </div>
              <div class="policy-link-note">
                <span class="policy-k">Policy Source:</span>
                <span class="policy-v">{{ allocation.policy_rule_label || 'Manual / Ad-Hoc Entitlement Grant' }}</span>
              </div>
              <div class="period-window-note">
                <span class="period-k">Fiscal Window:</span>
                <span class="period-v">{{ formatDate(allocation.period_start) }} – {{ formatDate(allocation.period_end) }}</span>
              </div>
            </div>
          </div>

          <!-- Total Quota Pool Breakdown Bar -->
          <div class="quota-pool-bar">
            <div class="pool-left">
              <Award :size="15" class="text-brand-blue" />
              <span class="pool-title">Total Authorized Quota Pool:</span>
              <strong class="pool-number font-mono">{{ allocation.total_entitled_days.toFixed(1) }} Days</strong>
              <span class="pool-formula">
                ({{ allocation.allocated_days.toFixed(1) }}d Base Grant + {{ allocation.carried_forward_days.toFixed(1) }}d Carried Rollover)
              </span>
            </div>
            <div class="pool-right">
              <span class="badge-fy">Ethiopian FY 2026/27</span>
            </div>
          </div>
        </div>

        <!-- 2. METRIC CARDS (Rule 2: MetricCard Standard) -->
        <div class="metrics-grid">
          <!-- Card 1: BASE ALLOCATED -->
          <MetricCard
            label="BASE ALLOCATED"
            :value="`${allocation.allocated_days.toFixed(1)} Days`"
            subtext="Statutory grant computed from policy"
            :icon="Award"
            :show-menu="false"
          />

          <!-- Card 2: CARRIED FORWARD -->
          <MetricCard
            label="CARRIED FORWARD"
            :value="`${allocation.carried_forward_days.toFixed(1)} Days`"
            subtext="Rolled over under 2-year statutory limit"
            :icon="RefreshCw"
            :show-menu="false"
          />

          <!-- Card 3: TAKEN / CONSUMED -->
          <MetricCard
            label="TAKEN / CONSUMED"
            :value="`${allocation.taken_days.toFixed(1)} Days`"
            subtext="Deducted by approved leave requests"
            :icon="Clock"
            :show-menu="false"
          />

          <!-- Card 4: AVAILABLE BALANCE -->
          <MetricCard
            label="AVAILABLE BALANCE"
            :value="`${allocation.available_days.toFixed(1)} Days`"
            :subtext="`Out of ${allocation.total_entitled_days.toFixed(1)} total authorized days`"
            :icon="CheckCircle2"
            :show-menu="false"
          />
        </div>

        <!-- 3. CONSUMPTION LEDGER SUB-TABLE (Rule 11: Child Sub-Table) -->
        <div class="clean-card">
          <div class="card-header-bar">
            <div>
              <h2 class="card-title">Quota Consumption Ledger</h2>
              <p class="card-subtitle">Approved leave requests drawing authorized days from this fiscal allocation bucket.</p>
            </div>
            <span class="count-pill">{{ allocation.consumptions.length }} Draws</span>
          </div>

          <div class="sub-table-wrap">
            <table class="erp-table child-table">
              <thead>
                <tr>
                  <th width="40" class="th-no">#</th>
                  <th>Request Document</th>
                  <th>Authorized Period</th>
                  <th>Deducted Days</th>
                  <th>Request Status</th>
                  <th width="60" class="text-center">Action</th>
                </tr>
              </thead>
              <tbody>
                <tr 
                  v-for="(item, idx) in allocation.consumptions" 
                  :key="item.request_id"
                  class="erp-row clickable-row"
                  @click="router.push(`/hr/leave-requests/${item.request_id}`)"
                >
                  <td class="td-no">{{ idx + 1 }}</td>
                  <td>
                    <span class="table-name-primary font-mono">{{ item.request_code }}</span>
                  </td>
                  <td>
                    <span class="table-text-tertiary">{{ item.date_range }}</span>
                  </td>
                  <td>
                    <span class="table-text-tertiary font-bold">{{ item.deducted_days.toFixed(1) }} Days</span>
                  </td>
                  <td>
                    <span class="status-pill state-approved">{{ item.request_status }}</span>
                  </td>
                  <td class="text-center" @click.stop>
                    <button 
                      class="btn-icon-sub" 
                      @click="router.push(`/hr/leave-requests/${item.request_id}`)"
                      title="View Leave Request"
                    >
                      <ArrowUpRight :size="14" />
                    </button>
                  </td>
                </tr>

                <!-- Empty State -->
                <tr v-if="allocation.consumptions.length === 0">
                  <td colspan="6" class="empty-child-cell">
                    <Clock :size="24" class="empty-icon" />
                    <p class="empty-text">No leave requests have drawn from this allocation bucket yet.</p>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- 4. STATUTORY POLICY & AUDIT PARAMETERS -->
        <div class="clean-card">
          <div class="card-header-bar">
            <div>
              <h2 class="card-title">Statutory Policy &amp; Compliance Parameters</h2>
              <p class="card-subtitle">Formal rules under Ethiopian Labor Proclamation No. 1156/2019 and corporate HR governance.</p>
            </div>
          </div>

          <div class="audit-grid">
            <!-- Item 1: Rollover Expiry Date -->
            <div class="audit-item">
              <span class="audit-label">2-Year Rollover Expiry</span>
              <span class="audit-value">Jul 7, 2028 (FY 2028 Close)</span>
              <span class="audit-sub">Carried forward days expire if unused</span>
            </div>

            <!-- Item 2: Accrual Policy Rule -->
            <div class="audit-item">
              <span class="audit-label">Accrual Method</span>
              <span class="audit-value">Per Service Year (+1d / 2yr)</span>
              <span class="audit-sub">Statutory seniority addition</span>
            </div>

            <!-- Item 3: Created By -->
            <div class="audit-item">
              <span class="audit-label">Initiated By</span>
              <span class="audit-value">{{ allocation.created_by_name || 'System Policy Accrual Engine' }}</span>
              <span class="audit-sub">Granted on {{ formatDate(allocation.created_at) }}</span>
            </div>

            <!-- Item 4: Encashment Status -->
            <div class="audit-item">
              <span class="audit-label">In-Service Encashment</span>
              <span class="audit-value text-emerald">Eligible (Under Cap)</span>
              <span class="audit-sub">Permitted via LeaveEncashment</span>
            </div>
          </div>

          <!-- Allocation Notes -->
          <div class="notes-display-box" v-if="allocation.notes">
            <span class="notes-label">Statutory Justification &amp; Personnel Notes</span>
            <p class="notes-text">{{ allocation.notes }}</p>
          </div>
        </div>
      </div>

      <!-- ═════════════════════════════════════════════════════════════
           RIGHT COLUMN: Approver Action Card & Approval Workflow Rail (~380px)
           ═════════════════════════════════════════════════════════════ -->
      <div class="approval-rail-column">
        <!-- 1. APPROVER DECISION & SIGN-OFF CARD -->
        <div class="rail-card">
          <div class="rail-header">
            <div>
              <h3 class="rail-title">Approver Authorization</h3>
              <p class="rail-subtitle">Formal statutory quota certification.</p>
            </div>
            <span class="status-pill" :class="`state-${allocation.allocation_state}`">
              {{ allocation.allocation_state }}
            </span>
          </div>

          <!-- STATE A: PENDING / DRAFT APPROVAL (Active Interactive Approver Form) -->
          <div v-if="allocation.allocation_state === 'draft' || allocation.allocation_state === 'submitted'" class="pending-approval-box">
            <div class="approval-summary-panel">
              <div class="asp-row">
                <span class="asp-lbl">Grant Entitled:</span>
                <span class="asp-val font-mono font-bold">{{ allocation.total_entitled_days.toFixed(1) }} Days</span>
              </div>
              <div class="asp-row">
                <span class="asp-lbl">Initiator:</span>
                <span class="asp-val">{{ allocation.created_by_name || 'HR Specialist' }}</span>
              </div>
            </div>

            <div class="form-field-wrapper">
              <label class="field-label">Approver Endorsement Remarks</label>
              <textarea
                v-model="approverRemarks"
                class="decision-textarea"
                rows="3"
                hint="Add formal sign-off comments or rejection justification."
              />
            </div>

            <div class="approver-actions-row">
              <AppButton
                variant="destructive"
                size="sm"
                :disabled="isSubmittingDecision"
                @click="handleReject"
              >
                <template #icon-left><X :size="14" /></template>
                Reject
              </AppButton>

              <AppButton
                variant="primary"
                size="sm"
                :disabled="isSubmittingDecision"
                :loading="isSubmittingDecision"
                @click="handleApprove"
              >
                Approve &amp; Certify Quota
              </AppButton>
            </div>
          </div>

          <!-- STATE B: ALREADY APPROVED (Official Certified Seal) -->
          <div v-else-if="allocation.allocation_state === 'approved'" class="certified-signoff-box">
            <div class="seal-badge-row">
              <div class="seal-icon-circle">
                <ShieldCheck :size="20" class="text-emerald" />
              </div>
              <div class="seal-meta">
                <span class="seal-title">Statutorily Certified &amp; Approved</span>
                <span class="seal-sub">Committed to live employee leave ledger</span>
              </div>
            </div>

            <!-- Signatory Profile -->
            <div class="signatory-profile-card">
              <img 
                :src="allocation.approver_avatar || 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&h=120&q=80'" 
                :alt="allocation.approved_by_name || 'Approver'" 
                class="signatory-avatar" 
              />
              <div class="signatory-meta">
                <span class="signatory-name">{{ allocation.approved_by_name || 'Dawit Mengistu' }}</span>
                <span class="signatory-role">{{ allocation.approver_role || 'Director of Human Resources' }}</span>
                <span class="signatory-timestamp">Certified: {{ allocation.approved_at || 'Jul 9, 2026 11:15' }}</span>
              </div>
            </div>

            <div v-if="allocation.approval_remarks" class="approval-quote-box">
              <span class="quote-header">Approver Endorsement:</span>
              <p class="quote-body">&ldquo;{{ allocation.approval_remarks }}&rdquo;</p>
            </div>
          </div>

          <!-- STATE C: RESCHEDULED -->
          <div v-else-if="allocation.allocation_state === 'rescheduled'" class="rescheduled-summary-box">
            <div class="rescheduled-icon-row">
              <RefreshCw :size="18" class="text-purple-600" />
              <div>
                <span class="resched-title">Window Rescheduled &amp; Superseded</span>
                <span class="resched-sub">Successor row spawned per Schema line 1647</span>
              </div>
            </div>
            <p v-if="allocation.reschedule_reason" class="resched-reason">
              &ldquo;{{ allocation.reschedule_reason }}&rdquo;
            </p>
          </div>

          <!-- STATE D: CONSUMED OR CANCELLED -->
          <div v-else class="archived-summary-box">
            <Clock :size="16" class="text-slate-400" />
            <span class="archive-text">
              Allocation is {{ allocation.allocation_state }}. Quota ledger is closed.
            </span>
          </div>
        </div>

        <!-- 2. QUOTA ORIGIN & AUDIT METADATA CARD (Schema L1632-1661: user_id, entity_id, policy_rule_id) -->
        <div class="rail-card">
          <div class="rail-header">
            <div>
              <h3 class="rail-title">Quota Origin &amp; Audit</h3>
              <p class="rail-subtitle">Statutory issuance and ledger registration metadata.</p>
            </div>
            <span class="badge-state-pill" :class="allocation.allocation_state === 'approved' ? 'state-active' : 'state-idle'">
              {{ allocation.allocation_state === 'approved' ? 'Active Ledger' : 'Unposted' }}
            </span>
          </div>

          <div class="origin-meta-list">
            <div class="om-item">
              <span class="om-label">Issuance Basis</span>
              <span class="om-value">
                {{ allocation.leave_policy_rule_id ? 'Annual Policy Rule Computation' : 'Manual / Ad-Hoc Entitlement Grant' }}
              </span>
            </div>

            <div class="om-item">
              <span class="om-label">Initiating User (Schema user_id)</span>
              <span class="om-value">{{ allocation.created_by_name || 'Kassahun Belay (HR Operations)' }}</span>
              <span class="om-sub">Registered on {{ formatDate(allocation.created_at) }}</span>
            </div>

            <div class="om-item">
              <span class="om-label">Owning Tenant &amp; Branch (entity_id)</span>
              <span class="om-value">{{ allocation.entity_name }}</span>
            </div>

            <div class="om-item">
              <span class="om-label">Statutory Proclamation Limit</span>
              <span class="om-value text-purple font-medium">2-Year Rollover Protection</span>
              <span class="om-sub">Carried days expire Jul 7, 2028 if unutilized</span>
            </div>

            <div class="om-item" v-if="allocation.rescheduled_from_code">
              <span class="om-label">Forward-Chain Heritage</span>
              <span class="om-value text-purple font-mono">From {{ allocation.rescheduled_from_code }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ─── RESCHEDULE WINDOW MODAL (AGENTS.md Rule 4 & Schema Line 1647) ─── -->
    <div v-if="isRescheduleModalOpen" class="modal-backdrop" @click="isRescheduleModalOpen = false">
      <div class="reschedule-modal-card" @click.stop>
        <div class="modal-header">
          <div>
            <h3 class="modal-title">Reschedule Allocation Window</h3>
            <span class="modal-subtitle">Forward-chain {{ allocation?.code }} with statutory justification</span>
          </div>
          <button class="modal-close-btn" @click="isRescheduleModalOpen = false">
            <X :size="18" />
          </button>
        </div>

        <div class="modal-body">
          <div class="alert-info-box">
            <AlertCircle :size="18" class="text-blue" />
            <p class="alert-text">
              Per Haleta ERP schema governance (Line 1647), superseded allocation rows are never edited in place. Rescheduling marks the current row as <b>rescheduled</b> and automatically spawns a forward-chained successor allocation.
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
              hint="Document operational necessity for deferring statutory rest period"
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
  </div>
</template>

<style scoped>
.allocation-detail-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: #f8fafc;
  min-height: 100vh;
}

/* Top Nav Bar */
.top-nav-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background-color: #ffffff;
  padding: 10px 18px;
  border-radius: 10px;
  border: 1px solid #e2e8f0;
}

.top-nav-left {
  display: flex;
  align-items: center;
}

.top-actions-cluster {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* Status Pill */
.status-pill {
  font-size: 11.5px;
  font-weight: 500;
  padding: 3px 12px;
  border-radius: 9999px;
  text-transform: capitalize;
}
.state-approved {
  background-color: #ecfdf5;
  color: #059669;
}
.state-draft, .state-submitted {
  background-color: #fef3c7;
  color: #92400e;
}
.state-rescheduled {
  background-color: #f3e8ff;
  color: #7e22ce;
}
.state-consumed {
  background-color: #f1f5f9;
  color: #64748b;
}
.state-cancelled {
  background-color: #fee2e2;
  color: #dc2626;
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

.toast-fade-enter-active,
.toast-fade-leave-active {
  transition: all 0.25s ease;
}
.toast-fade-enter-from,
.toast-fade-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}

/* Button Standard (Rule 6: 8px to 10px rounded rectangle, NEVER pills) */
.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  height: 36px;
  padding: 0 16px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-primary-action:hover {
  background-color: #09427d;
}

.btn-secondary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #ffffff;
  color: #404040;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  height: 36px;
  padding: 0 14px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s;
}
.btn-secondary-action:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.btn-outline-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #ffffff;
  color: #64748b;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  height: 36px;
  padding: 0 14px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}
.btn-outline-action:hover {
  background-color: #f8fafc;
  color: #404040;
}

/* ═══ MASTER 2-COLUMN SPLIT LAYOUT ═══ */
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

.clean-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 20px 24px;
}

/* Callout Banners */
.superseded-callout-card {
  display: flex;
  align-items: flex-start;
  gap: 14px;
  background-color: #faf5ff;
  border: 1px solid #e9d5ff;
  border-radius: 10px;
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
  font-size: 12.5px;
  color: #7e22ce;
  margin: 0;
  line-height: 1.45;
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
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 16px;
  font-size: 12.5px;
  color: #404040;
}
.predecessor-link {
  color: #7e22ce;
  cursor: pointer;
  text-decoration: underline;
}

/* Master Holder Card */
.master-holder-card {
  padding: 20px 24px;
}
.card-hero-split {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  padding-bottom: 16px;
  border-bottom: 1px solid #f1f5f9;
}

.holder-profile {
  display: flex;
  align-items: center;
  gap: 16px;
}
.holder-avatar {
  width: 58px;
  height: 58px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid #e2e8f0;
}
.holder-meta {
  display: flex;
  flex-direction: column;
  gap: 3px;
}
.name-row {
  display: flex;
  align-items: center;
  gap: 10px;
}
.holder-name {
  font-size: 18px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.holder-code {
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background-color: #f1f5f9;
  padding: 2px 8px;
  border-radius: 6px;
}
.holder-subtext {
  font-size: 13px;
  color: #737373;
  margin: 0;
}

.holder-alloc-info {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
}
.alloc-badge-group {
  display: flex;
  align-items: center;
  gap: 8px;
}
.alloc-code-pill {
  font-size: 13px;
  font-weight: 600;
  color: #0B529C;
  background-color: #eff6ff;
  padding: 3px 10px;
  border-radius: 6px;
}
.alloc-type-pill {
  font-size: 12px;
  font-weight: 500;
  color: #059669;
  background-color: #ecfdf5;
  padding: 3px 10px;
  border-radius: 6px;
}
.policy-link-note,
.period-window-note {
  font-size: 12px;
  color: #737373;
}
.policy-k, .period-k {
  color: #94a3b8;
  margin-right: 4px;
}
.policy-v, .period-v {
  color: #404040;
  font-weight: 500;
}

/* Quota Pool Bar */
.quota-pool-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background-color: #f8fafc;
  border-radius: 8px;
  padding: 10px 16px;
  margin-top: 14px;
}
.pool-left {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #404040;
}
.text-brand-blue {
  color: #0B529C;
}
.pool-title {
  font-weight: 500;
}
.pool-number {
  color: #0B529C;
  font-size: 14px;
}
.pool-formula {
  font-size: 12px;
  color: #737373;
}
.badge-fy {
  font-size: 11.5px;
  color: #64748b;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  padding: 2px 10px;
  border-radius: 6px;
  font-weight: 500;
}

/* Metrics Grid (Rule 2: MetricCard Standard) */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}
@media (max-width: 900px) {
  .metrics-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Sub-Table (AGENTS.md Rule 11) */
.card-header-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}
.card-title {
  font-size: 15.5px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.card-subtitle {
  font-size: 12.5px;
  color: #737373;
  margin: 4px 0 0;
}
.count-pill {
  font-size: 11.5px;
  font-weight: 500;
  color: #64748b;
  background-color: #f1f5f9;
  padding: 2px 10px;
  border-radius: 6px;
}

.sub-table-wrap {
  overflow-x: auto;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}

.erp-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
}

.child-table th {
  height: 34px;
  padding: 8px 12px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
}

.child-table td {
  height: 40px;
  padding: 6px 12px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.clickable-row {
  cursor: pointer;
  transition: background-color 0.12s ease;
}
.clickable-row:hover {
  background-color: #f8fafc;
}

.th-no, .td-no {
  font-size: 12px;
  color: #94a3b8;
  text-align: center;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.table-text-tertiary {
  color: #737373;
  font-size: 12.5px;
}
.font-bold {
  font-weight: 600;
  color: #404040;
}

.text-center {
  text-align: center;
}

.btn-icon-sub {
  width: 26px;
  height: 26px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  border-radius: 6px;
  color: #0B529C;
  cursor: pointer;
  transition: all 0.12s ease;
}
.btn-icon-sub:hover {
  background-color: #eff6ff;
}

.empty-child-cell {
  text-align: center;
  padding: 32px 16px !important;
}
.empty-icon {
  color: #cbd5e1;
  margin-bottom: 4px;
}
.empty-text {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

/* Audit Grid */
.audit-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 14px;
}
@media (max-width: 900px) {
  .audit-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
.audit-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.audit-label {
  font-size: 11.5px;
  color: #737373;
  font-weight: 500;
}
.audit-value {
  font-size: 13px;
  color: #404040;
  font-weight: 600;
}
.audit-sub {
  font-size: 11.5px;
  color: #94a3b8;
}
.text-emerald {
  color: #059669;
}

.notes-display-box {
  background-color: #f8fafc;
  border-radius: 8px;
  padding: 12px 16px;
  margin-top: 6px;
}
.notes-label {
  font-size: 11px;
  font-weight: 600;
  color: #737373;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
.notes-text {
  font-size: 12.5px;
  color: #404040;
  margin: 4px 0 0;
  line-height: 1.5;
}

/* ═════════════════════════════════════════════════════════════
   RIGHT COLUMN: APPROVAL RAIL (~380px)
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
}

.rail-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 14px;
  padding-bottom: 12px;
  border-bottom: 1px solid #f1f5f9;
}
.rail-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.rail-subtitle {
  font-size: 12px;
  color: #737373;
  margin: 2px 0 0;
}

/* Interactive Decision Box (Draft / Submitted) */
.pending-approval-box {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.approval-summary-panel {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 14px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.asp-row {
  display: flex;
  justify-content: space-between;
  font-size: 12.5px;
}
.asp-lbl {
  color: #737373;
}
.asp-val {
  color: #404040;
}

.form-field-wrapper {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.field-label {
  font-size: 12px;
  font-weight: 500;
  color: #404040;
}
.decision-textarea {
  width: 100%;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 8px 12px;
  font-size: 13px;
  color: #404040;
  font-family: inherit;
  resize: vertical;
  outline: none;
}
.decision-textarea:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.approver-actions-row {
  display: flex;
  align-items: center;
  gap: 10px;
}
.btn-approve-action {
  flex: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  height: 36px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s;
}
.btn-approve-action:hover {
  background-color: #09427d;
}
.btn-reject-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #ffffff;
  color: #dc2626;
  border: 1px solid #fecaca;
  border-radius: 8px;
  height: 36px;
  padding: 0 14px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s;
}
.btn-reject-action:hover {
  background-color: #fef2f2;
}

/* Certified Sign-off Seal Box */
.certified-signoff-box {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.seal-badge-row {
  display: flex;
  align-items: center;
  gap: 10px;
  background-color: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  padding: 8px 12px;
}
.seal-icon-circle {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background-color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.seal-meta {
  display: flex;
  flex-direction: column;
}
.seal-title {
  font-size: 12.5px;
  font-weight: 600;
  color: #065f46;
}
.seal-sub {
  font-size: 11px;
  color: #047857;
}

.signatory-profile-card {
  display: flex;
  align-items: center;
  gap: 12px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 14px;
}
.signatory-avatar {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid #e2e8f0;
}
.signatory-meta {
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.signatory-name {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}
.signatory-role {
  font-size: 11.5px;
  color: #737373;
}
.signatory-timestamp {
  font-size: 11px;
  color: #94a3b8;
}

.approval-quote-box {
  background-color: #f8fafc;
  border-left: 3px solid #059669;
  border-radius: 0 6px 6px 0;
  padding: 8px 12px;
}
.quote-header {
  font-size: 11px;
  font-weight: 600;
  color: #737373;
  text-transform: uppercase;
}
.quote-body {
  font-size: 12px;
  color: #404040;
  margin: 3px 0 0;
  font-style: italic;
  line-height: 1.4;
}

/* Rescheduled Summary Box */
.rescheduled-summary-box {
  display: flex;
  flex-direction: column;
  gap: 8px;
  background-color: #faf5ff;
  border: 1px solid #e9d5ff;
  border-radius: 8px;
  padding: 10px 14px;
}
.rescheduled-icon-row {
  display: flex;
  align-items: center;
  gap: 8px;
}
.resched-title {
  font-size: 12.5px;
  font-weight: 600;
  color: #6b21a8;
  display: block;
}
.resched-sub {
  font-size: 11px;
  color: #7e22ce;
  display: block;
}
.resched-reason {
  font-size: 12px;
  color: #7e22ce;
  margin: 0;
  font-style: italic;
}

/* Archived */
.archived-summary-box {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12.5px;
  color: #64748b;
  padding: 8px 0;
}

/* Quota Origin & Audit Metadata List */
.badge-state-pill {
  font-size: 11px;
  font-weight: 500;
  padding: 2px 8px;
  border-radius: 4px;
}
.state-active {
  background-color: #ecfdf5;
  color: #059669;
}
.state-idle {
  background-color: #f1f5f9;
  color: #64748b;
}

.origin-meta-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.om-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding-bottom: 10px;
  border-bottom: 1px solid #f1f5f9;
}
.om-item:last-child {
  border-bottom: none;
  padding-bottom: 0;
}
.om-label {
  font-size: 11.5px;
  color: #737373;
  font-weight: 500;
}
.om-value {
  font-size: 13px;
  color: #404040;
  font-weight: 500;
}
.om-sub {
  font-size: 11px;
  color: #94a3b8;
}

/* Modal */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
  padding: 20px;
}
.reschedule-modal-card {
  background-color: #ffffff;
  border-radius: 12px;
  width: 100%;
  max-width: 580px;
  display: flex;
  flex-direction: column;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.12);
  overflow: hidden;
}
.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid #e2e8f0;
}
.modal-title {
  font-size: 15.5px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.modal-subtitle {
  font-size: 12px;
  color: #737373;
}
.modal-close-btn {
  border: none;
  background: transparent;
  color: #94a3b8;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}
.modal-close-btn:hover {
  color: #404040;
}
.modal-body {
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.alert-info-box {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  background-color: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 8px;
  padding: 10px 14px;
}
.text-blue {
  color: #0B529C;
  flex-shrink: 0;
}
.alert-text {
  font-size: 12.5px;
  color: #1e3a8a;
  margin: 0;
  line-height: 1.45;
}
.modal-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 14px 18px;
}
.form-group {
  display: flex;
  flex-direction: column;
}
.form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 4px;
}
.form-label.required::after {
  content: ' *';
  color: #dc2626;
}
.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 14px 20px;
  border-top: 1px solid #e2e8f0;
  background-color: #f8fafc;
}
</style>
