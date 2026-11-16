<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  MoreVertical, X, CheckCircle2,
  FileText
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormRichText from '../../components/FormRichText.vue';
import { useToast } from '../../composables/useToast';
import { 
  staffMembers, 
  createAllocation, 
  type AllocationStaffMember 
} from './leaveAllocationData';
import { leaveTypesData, leavePoliciesData } from './leavePolicyData';

const router = useRouter();
const route = useRoute();

// ─── Breadcrumb Navigation Standard (AGENTS.md) ───
const breadcrumbItems = [
  { label: 'Leave Allocations', to: '/hr/leave-allocations' },
  { label: 'Create Leave Allocation' }
];

// Top bar state
const { toast } = useToast();
const isSaved = ref(false);
const isDraft = ref(false);
const showMoreDropdown = ref(false);

const showToast = (msg: string) => {
  toast.success(msg);
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
  isDraft.value = true;
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
  isDraft.value = false;
  showToast(`Leave allocation ${record.code} granted successfully.`);
  setTimeout(() => {
    router.push(`/hr/leave-allocations/${record.id}`);
  }, 800);
};
</script>

<template>
  <div class="allocation-create-page" @click="showMoreDropdown = false">
    <!-- Top Action & Breadcrumb Navigation Bar -->
    <div class="create-header-bar">
      <div class="header-left">
        <AppBreadcrumb :items="breadcrumbItems" noMargin>
          <template #badge>
            <SaveStateBadge :isSaved="isSaved" :isDraft="isDraft" />
          </template>
        </AppBreadcrumb>
      </div>

      <div class="header-actions">
        <!-- 3-Dots Action Menu (Available for Draft support) -->
        <div class="header-more-menu-wrapper" @click.stop>
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
            <div v-if="showMoreDropdown" class="header-more-dropdown">
              <button type="button" class="more-menu-item" @click="handleSaveDraft">
                <FileText :size="14" class="menu-item-icon" />
                <span>Save as Draft</span>
              </button>
            </div>
          </Transition>
        </div>

        <AppButton 
          variant="outline" 
          size="sm" 
          @click="handleClearForm"
        >
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>

        <AppButton 
          variant="primary" 
          size="sm" 
          @click="handleSubmit"
        >
          Save
        </AppButton>
      </div>
    </div>

    <!-- Main Creation Form Content -->
    <div class="create-content-stack">
      <!-- Master Form Card: Allocation Details -->
      <div class="clean-card">
        <div class="section-title-box">
          <h2 class="section-title">Leave Allocation Details</h2>
        </div>

        <div class="form-grid-2">
          <!-- Entitlement Holder (Employee) -->
          <div class="form-group">
            <label class="form-label required">Entitlement Holder (Employee)</label>
            <FormSelect
              v-model="form.employee_id"
              :options="employeeOptions"
              placeholder="Select Employee"
              :searchable="true"
              @update:modelValue="handleEmployeeChange"
            />
          </div>

          <!-- Leave Type -->
          <div class="form-group">
            <label class="form-label required">Leave Type</label>
            <FormSelect
              v-model="form.leave_type_id"
              :options="leaveTypeOptions"
              placeholder="Select Leave Type"
            />
          </div>
        </div>

        <!-- Policy Rule Binding Section -->
        <div class="policy-binding-section">
          <FormCheckbox
            v-model="form.is_policy_linked"
            label="Link to Organizational Policy Rule"
          />

          <div v-if="form.is_policy_linked" class="rule-dropdown-wrap">
            <label class="form-label required">Applicable Leave Policy Rule</label>
            <FormSelect
              v-model="form.leave_policy_rule_id"
              :options="policyRuleSelectOptions"
              placeholder="Select Rule"
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

        <!-- Days & Quota Allocation Grid -->
        <div class="form-grid-3">
          <div class="form-group">
            <label class="form-label required">Base Allocated Days</label>
            <FormInput
              type="number"
              v-model.number="form.allocated_days"
            />
          </div>

          <div class="form-group">
            <label class="form-label">Carried Forward Days (Rollover)</label>
            <FormInput
              type="number"
              v-model.number="form.carried_forward_days"
            />
          </div>

          <div class="form-group">
            <label class="form-label">Total Authorized Quota</label>
            <div class="quota-total-display">
              <span class="quota-total-value">{{ computedTotalEntitled.toFixed(1) }} Days</span>
              <span class="quota-total-breakdown">({{ form.allocated_days || 0 }}d Base + {{ form.carried_forward_days || 0 }}d Rollover)</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Description / Justification Card: FormRichText -->
      <div class="clean-card">
        <div class="section-title-box">
          <h2 class="section-title">Allocation Notes & Justification</h2>
        </div>
        <div class="rich-text-container">
          <FormRichText
            v-model="form.notes"
            placeholder="Enter administrative notes, statutory justification, or policy reference..."
            min-height="160px"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.allocation-create-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding: 0;
  background-color: var(--color-background-primary, #fafafa);
  min-height: 100vh;
}

/* Top Nav Bar (AGENTS.md: Breadcrumb bar is strictly transparent on canvas, NEVER a white card) */
.create-header-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: transparent;
  border: none;
  box-shadow: none;
  padding: 0;
  width: 100%;
}

.header-left {
  display: flex;
  align-items: center;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.header-more-menu-wrapper {
  position: relative;
}

.header-more-dropdown {
  position: absolute;
  top: calc(100% + 6px);
  right: 0;
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
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
  color: var(--alias-color-text-secondary, #404040);
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.15s ease;
}

.more-menu-item:hover {
  background-color: var(--color-background-primary, #fafafa);
}

.menu-item-icon {
  color: var(--alias-color-text-secondary, #404040);
}

.dropdown-fade-enter-active,
.dropdown-fade-leave-active {
  transition: all 0.15s ease;
}
.dropdown-fade-enter-from,
.dropdown-fade-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}

/* Content Stack */
.create-content-stack {
  display: flex;
  flex-direction: column;
  gap: 16px;
  width: 100%;
}

.clean-card {
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 12px;
  padding: 24px;
}

.section-title-box {
  margin-bottom: 20px;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  margin: 0;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
  margin-bottom: 20px;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  margin-bottom: 8px;
}

.form-group {
  display: flex;
  flex-direction: column;
}

.form-label {
  font-size: 13px;
  font-weight: 500;
  color: var(--alias-color-text-secondary, #404040);
  margin-bottom: 6px;
}

.form-label.required::after {
  content: ' *';
  color: #e7000b;
}

.policy-binding-section {
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding: 16px;
  background-color: var(--color-background-primary, #fafafa);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 8px;
  margin-bottom: 20px;
}

.rule-dropdown-wrap {
  display: flex;
  flex-direction: column;
}

.quota-total-display {
  display: flex;
  align-items: baseline;
  gap: 8px;
  height: 42px;
  padding: 0 14px;
  background-color: var(--color-background-primary, #fafafa);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 8px;
  box-sizing: border-box;
}

.quota-total-value {
  font-size: 15px;
  font-weight: 600;
  color: #0b529c;
  line-height: 42px;
}

.quota-total-breakdown {
  font-size: 12px;
  color: var(--alias-color-text-tertiary, #737373);
  line-height: 42px;
}

.rich-text-container {
  width: 100%;
}
</style>
