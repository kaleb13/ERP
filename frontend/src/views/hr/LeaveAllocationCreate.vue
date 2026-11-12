<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  MoreVertical, X, CheckCircle2, Scale,
  Save, FileText
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import { 
  staffMembers, 
  createAllocation, 
  type AllocationStaffMember 
} from './leaveAllocationData';
import { leaveTypesData, leavePoliciesData } from './leavePolicyData';

const router = useRouter();
const route = useRoute();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3 & 4) ───
// STRICTLY NO separate back button! Breadcrumb itself is the sole navigation.
const breadcrumbItems = [
  { label: 'Leave Allocations', to: '/hr/leave-allocations' },
  { label: 'Create Leave Allocation' }
];

// Top bar state
const isSaved = ref(false);
const showMoreDropdown = ref(false);
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Staff Options ───
const employeeOptions = computed<SelectOption[]>(() => {
  return staffMembers.map(e => ({
    value: e.id,
    label: `${e.name} (${e.code} • ${e.position} • ${e.entity_name})`
  }));
});

// ─── Leave Type Options ───
const leaveTypeOptions = computed<SelectOption[]>(() => {
  return leaveTypesData.value.map(lt => ({
    value: lt.id,
    label: `${lt.name} (${lt.code})`
  }));
});

// ─── Master Form State (Schema Lines 1632–1652) ───
const form = ref<{
  employee_id: number;
  leave_type_id: number;
  is_policy_linked: boolean;
  leave_policy_rule_id: number | null;
  period_start: string;
  period_end: string;
  allocated_days: number;
  carried_forward_days: number;
  notes: string;
}>({
  employee_id: 14,
  leave_type_id: 1,
  is_policy_linked: true,
  leave_policy_rule_id: 101,
  period_start: '2026-07-08',
  period_end: '2027-07-07',
  allocated_days: 18.0,
  carried_forward_days: 0.0,
  notes: ''
});

// Selected Staff Profile
const selectedStaff = computed<AllocationStaffMember>(() => {
  return staffMembers.find(s => s.id === form.value.employee_id) || staffMembers[0];
});

// Available Policy Rules based on selected leave type
const availablePolicyRules = computed(() => {
  const rulesList: { value: number; label: string; days: number; extraPerYear: number; maxDays: number }[] = [];
  leavePoliciesData.value.forEach(pol => {
    pol.rules.forEach(r => {
      if (r.leave_type_id === form.value.leave_type_id) {
        rulesList.push({
          value: r.id,
          label: `${pol.code} • ${r.leave_type_name} (${r.days_per_year}d + ${r.extra_days_per_service_year}d/yr)`,
          days: r.days_per_year,
          extraPerYear: r.extra_days_per_service_year,
          maxDays: r.max_days
        });
      }
    });
  });
  return rulesList;
});

const policyRuleSelectOptions = computed<SelectOption[]>(() => {
  return availablePolicyRules.value.map(r => ({
    value: r.value,
    label: r.label
  }));
});

// Auto-compute statutory base when employee or policy changes
const applyPolicyCalculation = () => {
  if (!form.value.is_policy_linked) return;
  const staff = selectedStaff.value;
  const rule = availablePolicyRules.value.find(r => r.value === form.value.leave_policy_rule_id);
  
  if (rule) {
    // Ethiopian statutory formula: base + extra per service year
    const extra = Math.floor(staff.service_years / 2) * (rule.extraPerYear || 1.0);
    const computedDays = Math.min(rule.days + extra, rule.maxDays || 30.0);
    form.value.allocated_days = computedDays;
  }
};

const handleEmployeeChange = () => {
  applyPolicyCalculation();
};

const handlePolicyRuleChange = () => {
  applyPolicyCalculation();
};

// Real-time calculated total entitled
const computedTotalEntitled = computed(() => {
  return Number(form.value.allocated_days || 0) + Number(form.value.carried_forward_days || 0);
});

// Interactive Service Year Simulator in Assistant Panel
const simYears = ref(3);
const simCalculatedQuota = computed(() => {
  const bonus = Math.floor(simYears.value / 2);
  return Math.min(16 + bonus, 30);
});

// Sync from route query params if expanded from modal
onMounted(() => {
  if (route.query.employee_id) form.value.employee_id = Number(route.query.employee_id);
  if (route.query.leave_type_id) form.value.leave_type_id = Number(route.query.leave_type_id);
  if (route.query.period_start) form.value.period_start = String(route.query.period_start);
  if (route.query.period_end) form.value.period_end = String(route.query.period_end);
  if (route.query.allocated_days) form.value.allocated_days = Number(route.query.allocated_days);
  if (route.query.carried_forward_days) form.value.carried_forward_days = Number(route.query.carried_forward_days);
  applyPolicyCalculation();
});

const handleClearForm = () => {
  form.value = {
    employee_id: 14,
    leave_type_id: 1,
    is_policy_linked: true,
    leave_policy_rule_id: 101,
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    allocated_days: 18.0,
    carried_forward_days: 0.0,
    notes: ''
  };
  showToast('Form cleared.');
};

const handleSaveDraft = () => {
  showMoreDropdown.value = false;
  const chosenRule = availablePolicyRules.value.find(r => r.value === form.value.leave_policy_rule_id);
  const record = createAllocation({
    employee_id: form.value.employee_id,
    leave_type_id: form.value.leave_type_id,
    leave_policy_rule_id: form.value.is_policy_linked ? form.value.leave_policy_rule_id : null,
    policy_rule_label: form.value.is_policy_linked ? chosenRule?.label : 'Manual / Ad-Hoc Entitlement Grant',
    period_start: form.value.period_start,
    period_end: form.value.period_end,
    allocated_days: Number(form.value.allocated_days),
    carried_forward_days: Number(form.value.carried_forward_days),
    notes: form.value.notes,
    isDraft: true
  });
  isSaved.value = true;
  showToast(`Allocation ${record.code} saved as Draft.`);
  setTimeout(() => {
    router.push(`/hr/leave-allocations/${record.id}`);
  }, 800);
};

const handleSubmit = () => {
  if (!form.value.period_start || !form.value.period_end) {
    alert('Please specify valid fiscal period dates.');
    return;
  }
  if (computedTotalEntitled.value <= 0) {
    alert('Total entitled days must be greater than zero.');
    return;
  }

  const chosenRule = availablePolicyRules.value.find(r => r.value === form.value.leave_policy_rule_id);
  const record = createAllocation({
    employee_id: form.value.employee_id,
    leave_type_id: form.value.leave_type_id,
    leave_policy_rule_id: form.value.is_policy_linked ? form.value.leave_policy_rule_id : null,
    policy_rule_label: form.value.is_policy_linked ? chosenRule?.label : 'Manual / Ad-Hoc Entitlement Grant',
    period_start: form.value.period_start,
    period_end: form.value.period_end,
    allocated_days: Number(form.value.allocated_days),
    carried_forward_days: Number(form.value.carried_forward_days),
    notes: form.value.notes,
    isDraft: false
  });

  isSaved.value = true;
  showToast(`Leave allocation ${record.code} granted successfully.`);
  setTimeout(() => {
    router.push(`/hr/leave-allocations/${record.id}`);
  }, 800);
};
</script>

<template>
  <div class="allocation-create-page" @click="showMoreDropdown = false">
    <!-- Top Bar (AGENTS.md Rule 4 & Breadcrumb Standard) -->
    <div class="top-nav-bar">
      <!-- STRICTLY NO separate back button! Breadcrumb itself navigates. -->
      <div class="breadcrumb-group">
        <AppBreadcrumb :items="breadcrumbItems" />
        <SaveStateBadge :isSaved="isSaved" />
      </div>

      <div class="actions-group">
        <!-- Dynamic 3-Dots More Menu [ ⋮ ] (Draft Support per Rule 4) -->
        <div class="more-menu-wrapper" @click.stop>
          <AppButton 
            variant="outline" 
            size="sm" 
            iconOnly
            title="More actions"
            @click="showMoreDropdown = !showMoreDropdown"
          >
            <MoreVertical :size="16" />
          </AppButton>

          <Transition name="dropdown-fade">
            <div v-if="showMoreDropdown" class="more-dropdown-menu">
              <button type="button" class="more-menu-item" @click="handleSaveDraft">
                <FileText :size="14" />
                <span>Save as Draft</span>
              </button>
            </div>
          </Transition>
        </div>

        <!-- Clear Form Secondary Button -->
        <AppButton 
          variant="outline" 
          size="sm" 
          @click="handleClearForm"
        >
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>

        <!-- Save Primary Button (Rule 6: Rectangular 8px, text: Save) -->
        <AppButton 
          variant="primary" 
          size="sm" 
          @click="handleSubmit"
        >
          Save
        </AppButton>
      </div>
    </div>

    <!-- Toast Notification -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <div class="allocation-layout-columns">
      <!-- MAIN COLUMN: ALLOCATION SPECIFICATION FORM -->
      <div class="main-form-column">
        <div class="clean-card">
          <div class="card-header-bar">
            <div>
              <h2 class="card-title">Entitlement Holder &amp; Fiscal Period</h2>
              <p class="card-subtitle">Designates the employee receiving annual leave and the Ethiopian statutory fiscal year.</p>
            </div>
          </div>

          <div class="form-grid-2">
            <!-- Select Employee -->
            <div class="form-group">
              <label class="form-label required">Entitlement Holder (Employee)</label>
              <FormSelect
                v-model="form.employee_id"
                :options="employeeOptions"
                placeholder="Select"
                @update:modelValue="handleEmployeeChange"
              />
            </div>

            <!-- Leave Type -->
            <div class="form-group">
              <label class="form-label required">Leave Type</label>
              <FormSelect
                v-model="form.leave_type_id"
                :options="leaveTypeOptions"
                placeholder="Select"
              />
            </div>
          </div>

          <!-- Policy Rule Binding (Schema Line 1640: leave_policy_rule_id) -->
          <div class="policy-binding-section">
            <FormCheckbox
              v-model="form.is_policy_linked"
              label="Link to Organizational Policy Rule"
              description="Calculate statutory baseline and service year additions automatically using the enterprise rulebook."
            />

            <div v-if="form.is_policy_linked" class="rule-dropdown-wrap">
              <label class="form-label required">Applicable Leave Policy Rule</label>
              <FormSelect
                v-model="form.leave_policy_rule_id"
                :options="policyRuleSelectOptions"
                placeholder="Select"
                @update:modelValue="handlePolicyRuleChange"
              />
            </div>
          </div>

          <!-- Fiscal Period Grid -->
          <div class="form-grid-2">
            <div class="form-group">
              <label class="form-label required">Fiscal Period Start</label>
              <FormInput
                type="date"
                v-model="form.period_start"
              />
            </div>

            <div class="form-group">
              <label class="form-label required">Fiscal Period End</label>
              <FormInput
                type="date"
                v-model="form.period_end"
              />
            </div>
          </div>

          <!-- Days Configuration Grid -->
          <div class="form-grid-2">
            <div class="form-group">
              <label class="form-label required">Base Allocated Days</label>
              <FormInput
                type="number"
                v-model="form.allocated_days"
                hint="Statutory base (16.0d) plus completed service additions (+1.0d per 2 years)"
              />
            </div>

            <div class="form-group">
              <label class="form-label">Carried Forward Days (Rollover)</label>
              <FormInput
                type="number"
                v-model="form.carried_forward_days"
                hint="Unused quota brought forward from prior fiscal cycle. Subject to 2-year statutory expiry"
              />
            </div>
          </div>

          <!-- Notes / Justification -->
          <div class="form-group">
            <label class="form-label">Allocation Notes &amp; Statutory Justification</label>
            <FormInput
              v-model="form.notes"
            />
          </div>
        </div>
      </div>

      <!-- SIDEBAR COLUMN: LIVE QUOTA SUMMARY & STATUTORY ACCRUAL ASSISTANT -->
      <div class="side-assistant-column">
        <!-- Live Entitlement Card -->
        <div class="clean-card preview-card">
          <h3 class="side-card-title">Live Entitlement Calculation</h3>

          <!-- Employee mini avatar -->
          <div class="staff-mini-hero">
            <img :src="selectedStaff.avatar" :alt="selectedStaff.name" class="staff-avatar-mini" />
            <div>
              <span class="staff-name-bold">{{ selectedStaff.name }}</span>
              <span class="staff-code-sub">{{ selectedStaff.code }} • {{ selectedStaff.position }}</span>
            </div>
          </div>

          <div class="entitlement-stat-block">
            <span class="entitlement-label">TOTAL AUTHORIZED QUOTA</span>
            <span class="entitlement-hero-val">{{ computedTotalEntitled.toFixed(1) }} Working Days</span>
            <span class="entitlement-calc-sub">
              {{ form.allocated_days.toFixed(1) }} Base + {{ form.carried_forward_days.toFixed(1) }} Rollover
            </span>
          </div>

          <div class="statutory-specs-box">
            <div class="spec-row">
              <span class="spec-k">Service Tenancy:</span>
              <span class="spec-v">{{ selectedStaff.service_years }} Completed Years</span>
            </div>
            <div class="spec-row">
              <span class="spec-k">Rollover Expiry:</span>
              <span class="spec-v">Jul 7, 2028 (2 Fiscal Cycles)</span>
            </div>
            <div class="spec-row">
              <span class="spec-k">Encashable Rights:</span>
              <span class="spec-v">Permitted at Separation</span>
            </div>
          </div>
        </div>

        <!-- Statutory Policy Helper Assistant -->
        <div class="clean-card helper-card">
          <div class="helper-header">
            <Scale :size="16" class="text-blue" />
            <h4 class="helper-title">Ethiopian Labor Law Proclamation 1156/2019</h4>
          </div>

          <p class="helper-text">
            Every full-time staff member completing 1 continuous service year is entitled to <b>16 working days</b> minimum rest leave, plus <b>+1 extra day</b> for every additional 2 service years, capped at <b>30 working days</b>.
          </p>

          <div class="simulator-mini">
            <label class="sim-label">
              Service Simulator: <b>{{ simYears }} Years</b> ➔ <b>{{ simCalculatedQuota }} Days</b>
            </label>
            <input 
              type="range" 
              v-model.number="simYears" 
              min="1" 
              max="25" 
              class="sim-slider" 
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.allocation-create-page {
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
  padding: 12px 18px;
  border-radius: 10px;
  border: 1px solid #e2e8f0;
}

.breadcrumb-group {
  display: flex;
  align-items: center;
  gap: 12px;
}

.save-badge {
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 4px;
}
.badge-not-saved {
  background-color: #fef3c7;
  color: #d97706;
}
.badge-saved {
  background-color: #ecfdf5;
  color: #059669;
}

.actions-group {
  display: flex;
  align-items: center;
  gap: 10px;
}

.more-menu-wrapper {
  position: relative;
}

.btn-more-options {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  color: #404040;
  cursor: pointer;
}
.btn-more-options:hover {
  background-color: #f8fafc;
}

.more-dropdown-menu {
  position: absolute;
  top: 40px;
  right: 0;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  padding: 4px;
  min-width: 150px;
  z-index: 50;
}
.more-menu-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border: none;
  background: transparent;
  font-size: 13px;
  color: #404040;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
}
.more-menu-item:hover {
  background-color: #f8fafc;
}

/* Button Standard (Rule 6: 8px to 10px rounded rectangle, NEVER pills) */
.btn-clear-form {
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
}
.btn-clear-form:hover {
  background-color: #f8fafc;
}

.btn-save-primary {
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
}
.btn-save-primary:hover {
  background-color: #09427d;
}

/* Toast */
.toast-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #ecfdf5;
  color: #065f46;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  padding: 10px 14px;
  font-size: 13px;
  font-weight: 500;
  width: fit-content;
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

/* 2-Column Responsive Layout */
.allocation-layout-columns {
  display: grid;
  grid-template-columns: 1fr 340px;
  gap: 16px;
  align-items: start;
}

.clean-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 20px 24px;
}

.card-header-bar {
  margin-bottom: 18px;
}
.card-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.card-subtitle {
  font-size: 12.5px;
  color: #737373;
  margin: 4px 0 0;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
  margin-bottom: 16px;
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

.policy-binding-section {
  background-color: #f8fafc;
  border-radius: 8px;
  padding: 14px 16px;
  margin-bottom: 16px;
}

.rule-dropdown-wrap {
  margin-top: 12px;
}

/* Side Assistant */
.side-assistant-column {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.preview-card {
  padding: 18px;
}
.side-card-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 12px;
}

.staff-mini-hero {
  display: flex;
  align-items: center;
  gap: 10px;
  padding-bottom: 12px;
  border-bottom: 1px solid #f1f5f9;
  margin-bottom: 14px;
}
.staff-avatar-mini {
  width: 42px;
  height: 42px;
  border-radius: 50%;
  object-fit: cover;
}
.staff-name-bold {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}
.staff-code-sub {
  font-size: 11.5px;
  color: #737373;
}

.entitlement-stat-block {
  display: flex;
  flex-direction: column;
  align-items: center;
  background-color: #eff6ff;
  border-radius: 8px;
  padding: 14px 12px;
  margin-bottom: 14px;
}
.entitlement-label {
  font-size: 10.5px;
  font-weight: 600;
  color: #1e40af;
  letter-spacing: 0.5px;
}
.entitlement-hero-val {
  font-size: 22px;
  font-weight: 700;
  color: #0B529C;
  margin: 2px 0;
}
.entitlement-calc-sub {
  font-size: 11.5px;
  color: #3b82f6;
}

.statutory-specs-box {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.spec-row {
  display: flex;
  justify-content: space-between;
  font-size: 11.5px;
}
.spec-k {
  color: #737373;
}
.spec-v {
  color: #404040;
  font-weight: 500;
}

.helper-card {
  padding: 16px;
}
.helper-header {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
}
.helper-title {
  font-size: 12px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.text-blue {
  color: #0B529C;
}
.helper-text {
  font-size: 12px;
  color: #737373;
  line-height: 1.45;
  margin: 0 0 12px;
}
.simulator-mini {
  background-color: #f8fafc;
  padding: 10px;
  border-radius: 6px;
}
.sim-label {
  display: block;
  font-size: 11px;
  color: #404040;
  margin-bottom: 6px;
}
.sim-slider {
  width: 100%;
  accent-color: #0B529C;
  cursor: pointer;
}
</style>
