<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  MoreVertical, X, Info, ChevronDown,
  ChevronUp, CheckCircle2, FileText, Check,
  Bold, Italic, Underline, List,
  RotateCcw
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import FormRichText from '../../components/FormRichText.vue';
import { useToast } from '../../composables/useToast';
import { 
  staffList, 
  createEncashment, 
  type StaffQuotaContext 
} from './leaveEncashmentData';

const router = useRouter();
const route = useRoute();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3 & 4) ───
const breadcrumbItems = [
  { label: 'Leave Encashments', to: '/hr/leave-encashments' },
  { label: 'Create Leave Encashment' }
];

const leaveTypeOptions: SelectOption[] = [
  { value: 1, label: 'Annual Leave (Encashable — Policy Rule 2026)' },
  { value: 2, label: 'Sick Leave (Not Encashable — Statutory Leave)' },
  { value: 3, label: 'Maternity Leave (Not Encashable — Statutory Leave)' }
];

// ─── Schema-Aligned Form State (LeaveEncashmentRequest: HR Schema lines 1785–1812) ───
// Strictly contains fields that map directly to the database schema:
// - employee_id (FK Employee)
// - leave_type_id (FK LeaveType)
// - leave_allocation_id (FK LeaveAllocation)
// - requested_days (numeric)
// - daily_rate (numeric - frozen)
// - amount (numeric - requested_days x daily_rate)
// - currency_id (ETB)
// - reason (jsonb)
const form = ref({
  employee_id: 124, // Almaz Kebede (EMP-00124) from mockup
  leave_type_id: 1, // Annual Leave
  requested_days: 5.0,
  reason: ''
});

const isEmployeePickerOpen = ref(false);
const isReasonOpen = ref(true);

const selectedStaff = computed<StaffQuotaContext>(() => {
  return staffList.find(s => s.id === form.value.employee_id) || staffList[0];
});

// ─── Schema Rate & Payout Calculations (lines 1797–1798) ───
// daily_rate = basic_salary / WorkCalendar.payroll_days_per_month
const computedDailyRate = computed(() => {
  const staff = selectedStaff.value;
  return Number((staff.basic_salary / staff.payroll_days).toFixed(4));
});

// amount = requested_days * daily_rate
const computedGrossAmount = computed(() => {
  return Number((computedDailyRate.value * Number(form.value.requested_days || 0)).toFixed(2));
});

// Real-time remaining balance projection
const remainingAvailableDays = computed(() => {
  const diff = selectedStaff.value.available_days - Number(form.value.requested_days || 0);
  return Number(Math.max(0, diff).toFixed(1));
});

const isExceedingQuota = computed(() => {
  return Number(form.value.requested_days || 0) > selectedStaff.value.available_days;
});

// ─── Top Bar State & Lifecycle (Rule 4 & Rule 30) ───
const { toast } = useToast();
const isSaved = ref(false);
const isDraft = ref(false);
const showMoreDropdown = ref(false);

const showToast = (msg: string) => {
  toast.success(msg);
};

// Sync query parameters if navigated from modal
onMounted(() => {
  if (route.query.employee_id) form.value.employee_id = Number(route.query.employee_id);
  if (route.query.requested_days) form.value.requested_days = Number(route.query.requested_days);
  if (route.query.reason) form.value.reason = String(route.query.reason);
});

// Quick Actions
const setMaxDays = () => {
  form.value.requested_days = selectedStaff.value.available_days;
};

// Form Actions
const handleClearForm = () => {
  form.value.requested_days = 1.0;
  form.value.reason = '';
  isSaved.value = false;
  isDraft.value = false;
  showToast('Form cleared.');
};

const handleSaveDraft = () => {
  showMoreDropdown.value = false;
  const newRecord = createEncashment({
    employee_id: form.value.employee_id,
    requested_days: Number(form.value.requested_days) || 1,
    reason: form.value.reason,
    isDraft: true
  });
  isSaved.value = true;
  isDraft.value = true;
  showToast(`Encashment request ${newRecord.code} saved as draft.`);
  setTimeout(() => {
    router.push(`/hr/leave-encashments/${newRecord.id}`);
  }, 850);
};

const handleSave = () => {
  if (!form.value.requested_days || form.value.requested_days <= 0) {
    alert('Please enter a valid number of days to encash.');
    return;
  }
  if (isExceedingQuota.value) {
    alert(`Requested days (${form.value.requested_days}) exceed available quota (${selectedStaff.value.available_days} days).`);
    return;
  }

  const newRecord = createEncashment({
    employee_id: form.value.employee_id,
    requested_days: Number(form.value.requested_days),
    reason: form.value.reason,
    isDraft: false
  });

  isSaved.value = true;
  isDraft.value = false;
  showToast(`Leave encashment request ${newRecord.code} submitted successfully.`);
  setTimeout(() => {
    router.push(`/hr/leave-encashments/${newRecord.id}`);
  }, 850);
};

const formatCurrency = (val: number) => {
  return (val || 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
};
</script>

<template>
  <div class="create-encashment-page" @click="showMoreDropdown = false; isEmployeePickerOpen = false">
    <!-- ─── TOP BAR (AGENTS.md Rule 4, Rule 27 Zero-Icon Save, Rule 30 SaveStateBadge) ─── -->
    <div class="top-bar">
      <div class="top-bar-left">
        <AppBreadcrumb :items="breadcrumbItems" no-margin>
          <template #badge>
            <SaveStateBadge :isSaved="isSaved" :isDraft="isDraft" />
          </template>
        </AppBreadcrumb>
      </div>

      <div class="top-bar-actions">
        <!-- 3-Dots More Menu (Rule 4: Mandatory because LEAVE_REQUEST_STATE supports draft) -->
        <div class="more-menu-wrapper" @click.stop>
          <AppButton
            variant="outline"
            size="sm"
            iconOnly
            title="More Options"
            @click="showMoreDropdown = !showMoreDropdown"
          >
            <MoreVertical :size="16" />
          </AppButton>

          <Transition name="dropdown-fade">
            <div v-if="showMoreDropdown" class="more-dropdown">
              <button type="button" class="more-dropdown-item" @click="handleSaveDraft">
                <FileText :size="14" />
                <span>Save as Draft</span>
              </button>
            </div>
          </Transition>
        </div>

        <!-- Clear Form Secondary Button (Rule 31: 38px height, 16px padding, 8px radius) -->
        <AppButton
          variant="outline"
          size="sm"
          @click="handleClearForm"
        >
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>

        <!-- Save Primary Button (Rule 27: Plain text "Save", ZERO icons, 8px radius) -->
        <AppButton
          variant="primary"
          size="sm"
          :disabled="isExceedingQuota"
          @click="handleSave"
        >
          Save
        </AppButton>
      </div>
    </div>

    <!-- ─── TOP CARD: CLEAN & FOCUSED (EXACTLY MATCHING USER MOCKUP) ─── -->
    <!-- Contains ONLY essential requester context and quota balance snapshot -->
    <div class="top-summary-card">
      <!-- Left: Requester Identity -->
      <div class="requester-col">
        <img :src="selectedStaff.avatar" :alt="selectedStaff.name" class="requester-avatar" />
        <div class="requester-details">
          <div class="requester-name-row">
            <h2 class="requester-name">{{ selectedStaff.name }}</h2>
            <!-- Subtle staff switcher -->
            <div class="staff-picker-wrap" @click.stop>
              <button 
                type="button" 
                class="btn-switch-text" 
                @click="isEmployeePickerOpen = !isEmployeePickerOpen"
                title="Change Employee"
              >
                <span>Change</span>
                <ChevronDown :size="11" />
              </button>

              <Transition name="dropdown-fade">
                <div v-if="isEmployeePickerOpen" class="staff-picker-dropdown">
                  <div class="picker-header">Select Staff Member</div>
                  <div class="picker-list">
                    <button
                      v-for="staff in staffList"
                      :key="staff.id"
                      type="button"
                      class="picker-item"
                      :class="{ 'is-active': staff.id === form.employee_id }"
                      @click="form.employee_id = staff.id; isEmployeePickerOpen = false"
                    >
                      <img :src="staff.avatar" :alt="staff.name" class="picker-avatar" />
                      <div class="picker-item-info">
                        <span class="picker-item-name">{{ staff.name }}</span>
                        <span class="picker-item-sub">{{ staff.code }} &bull; {{ staff.available_days }}d available</span>
                      </div>
                      <Check v-if="staff.id === form.employee_id" :size="14" class="text-brand ml-auto" />
                    </button>
                  </div>
                </div>
              </Transition>
            </div>
          </div>
          <span class="requester-subtitle">{{ selectedStaff.code }} - {{ selectedStaff.position }}</span>
        </div>
      </div>

      <!-- Right: Quota Balance Metric & Itemized Columns (Direct from mockup) -->
      <div class="quota-kpi-col">
        <div class="kpi-available-box">
          <span class="kpi-label">Available Balance</span>
          <span class="kpi-available-val">{{ selectedStaff.available_days.toFixed(1) }} Days</span>
        </div>

        <div class="kpi-divider"></div>

        <div class="kpi-columns-group">
          <div class="kpi-column">
            <span class="kpi-column-lbl">Entitled</span>
            <span class="kpi-column-val">{{ selectedStaff.total_entitled_days.toFixed(1) }} d</span>
          </div>
          <div class="kpi-column">
            <span class="kpi-column-lbl">Taken</span>
            <span class="kpi-column-val">{{ selectedStaff.taken_days.toFixed(1) }} d</span>
          </div>
          <div class="kpi-column">
            <span class="kpi-column-lbl">In Review</span>
            <span class="kpi-column-val">{{ (selectedStaff.in_review_days || 0).toFixed(1) }} d</span>
          </div>
        </div>
      </div>
    </div>

    <!-- ─── FORM CONTENT (STRICTLY SCHEMA-ALIGNED) ─── -->
    <div class="form-cards-stack">
      <!-- Section 1: Encashment Details (Leave Type, Days, Rate, Gross Payout) -->
      <div class="form-card">
        <div class="form-grid-3">
          <!-- Col 1: Leave Type (Schema: leave_type_id FK) -->
          <div class="form-group">
            <label class="form-label required-mark">Leave Type</label>
            <FormSelect
              v-model="form.leave_type_id"
              :options="leaveTypeOptions"
              placeholder="Select Type"
            />
          </div>

          <!-- Col 2: Days to Encash (Schema: requested_days numeric) -->
          <div class="form-group">
            <div class="label-with-action">
              <label class="form-label required-mark">Days to Encash</label>
              <button 
                type="button" 
                class="btn-quick-max" 
                @click="setMaxDays"
                title="Fill with all remaining available quota"
              >
                Max: {{ selectedStaff.available_days }}d
              </button>
            </div>
            <FormInput
              v-model="form.requested_days"
              type="number"
              min="0.5"
              :max="selectedStaff.available_days"
              step="0.5"
              :class="{ 'input-field-error': isExceedingQuota }"
            />
          </div>

          <!-- Col 3: Daily Rate Basis (Schema: daily_rate numeric frozen) -->
          <div class="form-group">
            <label class="form-label">Daily Rate</label>
            <FormInput
              :model-value="`ETB ${formatCurrency(computedDailyRate)} / Day`"
              readonly
              disabled
            />
          </div>
        </div>

        <!-- Dynamic Calculation Strip: Resulting Gross Amount & Projected Balance -->
        <div class="calculation-result-bar">
          <div class="calc-output-item">
            <span class="calc-lbl">Calculated Gross Encashment Payout</span>
            <span class="calc-val-hero font-bold text-green">ETB {{ formatCurrency(computedGrossAmount) }}</span>
            <span class="calc-sub">{{ form.requested_days || 0 }} Days &times; ETB {{ formatCurrency(computedDailyRate) }} (Frozen rate)</span>
          </div>

          <div class="calc-output-divider"></div>

          <div class="calc-output-item">
            <span class="calc-lbl">Remaining Available Quota After Request</span>
            <span class="calc-val-remaining font-semibold" :class="{ 'text-red': isExceedingQuota, 'text-brand': !isExceedingQuota }">
              {{ remainingAvailableDays }} Days
            </span>
            <span v-if="!isExceedingQuota" class="calc-sub">Debited from bucket {{ selectedStaff.allocation_code }} upon sign-off</span>
            <span v-else class="calc-sub text-red font-medium">Exceeds available balance ({{ selectedStaff.available_days }}d)</span>
          </div>
        </div>

        <!-- Informational Note regarding Payroll Integration (Schema line 1806) -->
        <div class="payroll-feeder-hint">
          <Info :size="13" class="text-slate-500" />
          <span>
            Upon approval, this encashment generates a signed <code>LeaveTransaction</code> and reaches the payslip automatically through a <code>PayrollInput</code> row disbursed to the employee's verified salary account.
          </span>
        </div>
      </div>

      <!-- Section 2: Encashment Justification / Reason (Schema: reason jsonb) -->
      <div class="form-card accordion-card">
        <div 
          class="accordion-header" 
          @click="isReasonOpen = !isReasonOpen"
          title="Click to toggle justification section"
        >
          <div class="acc-header-left">
            <h3 class="card-title">Encashment Description / Reason</h3>
          </div>
          <button type="button" class="btn-acc-toggle">
            <ChevronUp v-if="isReasonOpen" :size="18" />
            <ChevronDown v-else :size="18" />
          </button>
        </div>

        <Transition name="accordion-slide">
          <div v-if="isReasonOpen" class="accordion-body">
            <!-- Preset Quick Reason Chips -->
            <!-- Standard FormRichText Component (Figma 3345:21147 & Node 7009:114735) -->
            <FormRichText
              v-model="form.reason"
              placeholder="State the employee's rationale or business justification for liquidating unutilized annual leave..."
              :max-length="5000"
            />
          </div>
        </Transition>
      </div>
    </div>
  </div>
</template>

<style scoped>
.create-encashment-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  position: relative;
  width: 100%;
}

/* ─── Top Bar (AGENTS.md Rule 4 & 27) ─── */
.top-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0;
  background: transparent;
  border: none;
}
.top-bar-left {
  display: flex;
  align-items: center;
}
.top-bar-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.more-menu-wrapper {
  position: relative;
}
.btn-icon-more {
  width: 38px;
  height: 38px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  color: #404040;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-icon-more:hover { background-color: #fafafa; }

.more-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  margin-top: 4px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
  min-width: 160px;
  z-index: 50;
  padding: 4px;
}
.more-dropdown-item {
  width: 100%;
  height: 32px;
  padding: 0 10px;
  font-size: 12.5px;
  color: #404040;
  background: transparent;
  border: none;
  border-radius: 6px;
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  text-align: left;
}
.more-dropdown-item:hover { background-color: #fafafa; }

.btn-secondary-clear {
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
.btn-secondary-clear:hover { background-color: #fafafa; }

.btn-primary-save {
  height: 38px;
  padding: 0 22px;
  background-color: #0B529C;
  border: none;
  color: #ffffff;
  font-size: 13.5px;
  font-weight: 500;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-primary-save:hover:not(:disabled) { background-color: #083c72; }
.btn-primary-save:disabled { opacity: 0.6; cursor: not-allowed; }

/* ─── TOP SUMMARY CARD (MINIMAL, ELEGANT, NON-BLOATED) ─── */
.top-summary-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
}

.requester-col {
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
.requester-details {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.requester-name-row {
  display: flex;
  align-items: center;
  gap: 8px;
}
.requester-name {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.requester-subtitle {
  font-size: 12px;
  color: #737373;
}

/* Staff Picker */
.staff-picker-wrap {
  position: relative;
}
.btn-switch-text {
  display: flex;
  align-items: center;
  gap: 2px;
  font-size: 11px;
  color: #0B529C;
  background: transparent;
  border: none;
  padding: 0 4px;
  cursor: pointer;
}
.btn-switch-text:hover { text-decoration: underline; }

.staff-picker-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  margin-top: 6px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.12);
  width: 270px;
  z-index: 60;
  overflow: hidden;
}
.picker-header {
  padding: 8px 12px;
  font-size: 11px;
  font-weight: 600;
  color: #737373;
  text-transform: uppercase;
  background-color: #fafafa;
  border-bottom: 1px solid #f1f5f9;
}
.picker-list {
  max-height: 200px;
  overflow-y: auto;
}
.picker-item {
  width: 100%;
  padding: 8px 12px;
  display: flex;
  align-items: center;
  gap: 8px;
  border: none;
  background: transparent;
  text-align: left;
  cursor: pointer;
  border-bottom: 1px solid #f8fafc;
}
.picker-item:hover { background-color: #f5f5f5; }
.picker-item.is-active { background-color: #eff6ff; }
.picker-avatar {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  object-fit: cover;
}
.picker-item-info {
  display: flex;
  flex-direction: column;
}
.picker-item-name {
  font-size: 12px;
  font-weight: 600;
  color: #404040;
}
.picker-item-sub {
  font-size: 10.5px;
  color: #737373;
}

/* Quota KPI Col (From Mockup) */
.quota-kpi-col {
  display: flex;
  align-items: center;
  gap: 20px;
}
.kpi-available-box {
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.kpi-label {
  font-size: 11.5px;
  color: #737373;
  font-weight: 500;
}
.kpi-available-val {
  font-size: 20px;
  font-weight: 700;
  color: #404040;
}

.kpi-divider {
  width: 1px;
  height: 40px;
  background-color: #e5e5e5;
}

.kpi-columns-group {
  display: flex;
  align-items: center;
  gap: 18px;
}
.kpi-column {
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.kpi-column-lbl {
  font-size: 11.5px;
  color: #737373;
}
.kpi-column-val {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
}

/* ─── Stack Form Sections ─── */
.form-cards-stack {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}
.required-mark::after {
  content: ' *';
  color: #dc2626;
}

.label-with-action {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.btn-quick-max {
  font-size: 11px;
  font-weight: 500;
  color: #0B529C;
  background-color: #eff6ff;
  border: 1px solid #bfdbfe;
  padding: 1px 7px;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-quick-max:hover { background-color: #dbeafe; }

.input-field-error :deep(input) {
  border-color: #ef4444 !important;
  background-color: #fef2f2 !important;
}

/* Dynamic Calculation Result Bar */
.calculation-result-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: #fafbfc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 14px 20px;
}
.calc-output-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.calc-lbl {
  font-size: 11px;
  color: #737373;
  font-weight: 500;
}
.calc-val-hero {
  font-size: 18px;
  color: #059669;
}
.calc-val-remaining {
  font-size: 16px;
}
.calc-sub {
  font-size: 11px;
  color: #94a3b8;
}
.calc-output-divider {
  width: 1px;
  height: 42px;
  background-color: #e5e5e5;
}

.payroll-feeder-hint {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 11.5px;
  color: #737373;
  background-color: #fafafa;
  border: 1px solid #f1f5f9;
  padding: 8px 12px;
  border-radius: 6px;
  line-height: 1.4;
}
.payroll-feeder-hint code {
  font-family: monospace;
  background-color: #e5e5e5;
  padding: 1px 4px;
  border-radius: 3px;
  color: #404040;
}

/* ─── Accordion Justification Section ─── */
.accordion-card {
  padding: 0;
  overflow: hidden;
}
.accordion-header {
  padding: 16px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: pointer;
  background-color: #ffffff;
  transition: background-color 0.15s ease;
}
.accordion-header:hover { background-color: #fafbfc; }
.btn-acc-toggle {
  background: transparent;
  border: none;
  color: #737373;
  cursor: pointer;
}

.accordion-body {
  padding: 0 24px 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  border-top: 1px solid #f1f5f9;
}


.justification-editor-box {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  overflow: hidden;
  transition: border-color 0.15s ease;
}
.justification-editor-box:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}
.editor-mini-toolbar {
  padding: 6px 10px;
  background-color: #fafbfc;
  border-bottom: 1px solid #f1f5f9;
}
.toolbar-tools {
  display: flex;
  align-items: center;
  gap: 4px;
}
.toolbar-label {
  font-size: 11.5px;
  color: #737373;
  font-weight: 500;
  padding: 0 4px;
}
.toolbar-divider {
  width: 1px;
  height: 14px;
  background-color: #e5e5e5;
  margin: 0 2px;
}
.btn-tool {
  width: 24px;
  height: 24px;
  border: none;
  background: transparent;
  color: #737373;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.btn-tool:hover { background-color: #f5f5f5; color: #404040; }

.editor-textarea-field {
  width: 100%;
  padding: 10px 12px;
  border: none;
  outline: none;
  font-size: 13.5px;
  color: #404040;
  font-family: inherit;
  resize: vertical;
  line-height: 1.5;
}

.editor-counter-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 4px 10px;
  background-color: #fafbfc;
  border-top: 1px solid #f1f5f9;
}
.counter-text {
  font-size: 11px;
  color: #737373;
}
.autosave-tag {
  font-size: 10.5px;
  color: #94a3b8;
  font-family: monospace;
}

.dropdown-fade-enter-active, .dropdown-fade-leave-active { transition: opacity 0.15s, transform 0.15s; }
.dropdown-fade-enter-from, .dropdown-fade-leave-to { opacity: 0; transform: translateY(-4px); }

.text-brand { color: #0B529C; }
.text-green { color: #059669; }
.text-red { color: #dc2626; }
.font-bold { font-weight: 700; }
.font-semibold { font-weight: 600; }
.ml-auto { margin-left: auto; }
</style>
