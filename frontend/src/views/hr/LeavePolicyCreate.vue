<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  X, Save, Plus, Expand,
  CheckCircle2, ShieldCheck, Layers, ChevronDown,
  ArrowRight, ArrowUp, ArrowDown, Copy
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import IconColumnSolid from '../../components/IconColumnSolid.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import { 
  leaveTypesData, 
  leavePoliciesData, 
  createLeavePolicy, 
  type LeavePolicyRuleRecord 
} from './leavePolicyData';

const router = useRouter();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3) ───
const breadcrumbItems = [
  { label: 'Leave Policies', to: '/hr/leave-policies' },
  { label: 'Create Leave Policy' }
];

const isSaved = ref(false);
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Top Capsule Tabs (<BaseTabs /> AGENTS.md Rule 1) ───
const activeTab = ref<'details' | 'rules'>('details');

const policyTabs = computed<BaseTabItem<string>[]>(() => [
  { id: 'details', label: 'Policy Blueprint & Scope', icon: ShieldCheck },
  { id: 'rules', label: 'Entitlement Rules', icon: Layers, count: rules.value.length }
]);

// ─── Entity & Calendar Options ───
const entityOptions: SelectOption[] = [
  { value: 3, label: 'Haleta Corporate Headquarters (Addis Ababa)' },
  { value: 7, label: 'Bole Commercial Branch' },
  { value: 9, label: 'Bahir Dar Regional Hub' },
  { value: 12, label: 'Piazza Retail Shop' }
];

const workCalendarOptions: SelectOption[] = [
  { value: 1, label: 'CAL-OFFICE (40h Week • 26d Divisor • Sat/Sun off)' },
  { value: 2, label: 'CAL-RETAIL (48h Week • 26d Divisor • Sun off)' },
  { value: 3, label: 'CAL-RETAIL2 (48h Week • Mon off)' }
];

// ─── Tab 1: Master Policy Header Form State ───
const policyForm = ref({
  name: '',
  code: '',
  entity_id: 3,
  work_calendar_id: 1,
  effective_from: '2026-07-08',
  effective_to: '',
  description: ''
});

// Auto-generate code from name on blur
const handleNameBlur = () => {
  if (policyForm.value.name && !policyForm.value.code) {
    const slug = policyForm.value.name
      .toUpperCase()
      .replace(/[^A-Z0-9]/g, '-')
      .replace(/-+/g, '-');
    policyForm.value.code = `POL-${slug}`;
  }
};

// Preset Template / Clone options
const selectedTemplateId = ref<number | string>('');

const templateOptions = computed<SelectOption[]>(() => {
  return [
    { value: '', label: 'Statutory Baseline (Ethiopian Labor Proclamation)' },
    ...leavePoliciesData.value.map(p => ({
      value: p.id,
      label: `Copy from ${p.name} (${p.code})`
    }))
  ];
});

// ─── Smart Statutory Defaults Dictionary ───
const statutoryDefaultsByCode: Record<string, Partial<LeavePolicyRuleRecord>> = {
  ANNUAL: {
    accrual_method: 'per_service_year',
    days_per_year: 16.0,
    extra_days_per_service_year: 1.0,
    max_days: 30.0,
    pay_percent: 100.0,
    min_service_months: 12,
    max_carry_forward_days: 10.0,
    carry_forward_expiry_months: 24,
    notice_days: 14,
    max_splits_per_year: 4,
    rounding: 'half_day',
    gender: null,
    allow_negative_balance: false,
    allow_encashment: true,
    requires_attachment: false,
    allow_half_day: true
  },
  SICK: {
    accrual_method: 'annual_grant',
    days_per_year: 30.0,
    extra_days_per_service_year: 0.0,
    max_days: 180.0,
    pay_percent: 100.0,
    min_service_months: 1,
    max_carry_forward_days: 0.0,
    carry_forward_expiry_months: 0,
    notice_days: 0,
    max_splits_per_year: null,
    rounding: 'full_day',
    gender: null,
    allow_negative_balance: false,
    allow_encashment: false,
    requires_attachment: true,
    allow_half_day: true
  },
  MATERNITY: {
    accrual_method: 'fixed',
    days_per_year: 120.0,
    extra_days_per_service_year: 0.0,
    max_days: 120.0,
    pay_percent: 100.0,
    min_service_months: 6,
    max_carry_forward_days: 0.0,
    carry_forward_expiry_months: 0,
    notice_days: 30,
    max_splits_per_year: 2,
    rounding: 'full_day',
    gender: 'female',
    allow_negative_balance: false,
    allow_encashment: false,
    requires_attachment: true,
    allow_half_day: false
  },
  PATERNITY: {
    accrual_method: 'fixed',
    days_per_year: 5.0,
    extra_days_per_service_year: 0.0,
    max_days: 5.0,
    pay_percent: 100.0,
    min_service_months: 3,
    max_carry_forward_days: 0.0,
    carry_forward_expiry_months: 0,
    notice_days: 3,
    max_splits_per_year: 1,
    rounding: 'full_day',
    gender: 'male',
    allow_negative_balance: false,
    allow_encashment: false,
    requires_attachment: false,
    allow_half_day: false
  },
  BEREAVEMENT: {
    accrual_method: 'fixed',
    days_per_year: 3.0,
    extra_days_per_service_year: 0.0,
    max_days: 3.0,
    pay_percent: 100.0,
    min_service_months: 0,
    max_carry_forward_days: 0.0,
    carry_forward_expiry_months: 0,
    notice_days: 0,
    max_splits_per_year: 2,
    rounding: 'full_day',
    gender: null,
    allow_negative_balance: false,
    allow_encashment: false,
    requires_attachment: false,
    allow_half_day: false
  },
  STUDY: {
    accrual_method: 'annual_grant',
    days_per_year: 10.0,
    extra_days_per_service_year: 0.0,
    max_days: 10.0,
    pay_percent: 100.0,
    min_service_months: 12,
    max_carry_forward_days: 0.0,
    carry_forward_expiry_months: 0,
    notice_days: 14,
    max_splits_per_year: 2,
    rounding: 'half_day',
    gender: null,
    allow_negative_balance: false,
    allow_encashment: false,
    requires_attachment: true,
    allow_half_day: true
  },
  UNPAID: {
    accrual_method: 'annual_grant',
    days_per_year: 30.0,
    extra_days_per_service_year: 0.0,
    max_days: 90.0,
    pay_percent: 0.0,
    min_service_months: 6,
    max_carry_forward_days: 0.0,
    carry_forward_expiry_months: 0,
    notice_days: 14,
    max_splits_per_year: null,
    rounding: 'half_day',
    gender: null,
    allow_negative_balance: false,
    allow_encashment: false,
    requires_attachment: false,
    allow_half_day: true
  }
};

const getStatutoryDefaultRules = (): (LeavePolicyRuleRecord & { selected: boolean })[] => [
  {
    id: 1,
    uuid: 'rul-draft-1',
    leave_policy_id: 0,
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    leave_type_code: 'ANNUAL',
    pay_percent: 100.0,
    accrual_method: 'per_service_year',
    days_per_year: 16.0,
    extra_days_per_service_year: 1.0,
    max_days: 30.0,
    min_service_months: 12,
    max_carry_forward_days: 10.0,
    carry_forward_expiry_months: 24,
    allow_negative_balance: false,
    allow_encashment: true,
    requires_attachment: false,
    allow_half_day: true,
    rounding: 'half_day',
    gender: null,
    notice_days: 14,
    max_splits_per_year: 4,
    state: 'active',
    selected: false
  },
  {
    id: 2,
    uuid: 'rul-draft-2',
    leave_policy_id: 0,
    leave_type_id: 2,
    leave_type_name: 'Sick Leave',
    leave_type_code: 'SICK',
    pay_percent: 100.0,
    accrual_method: 'annual_grant',
    days_per_year: 30.0,
    extra_days_per_service_year: 0.0,
    max_days: 180.0,
    min_service_months: 1,
    max_carry_forward_days: 0.0,
    carry_forward_expiry_months: 0,
    allow_negative_balance: false,
    allow_encashment: false,
    requires_attachment: true,
    allow_half_day: true,
    rounding: 'full_day',
    gender: null,
    notice_days: 0,
    max_splits_per_year: null,
    state: 'active',
    selected: false
  },
  {
    id: 3,
    uuid: 'rul-draft-3',
    leave_policy_id: 0,
    leave_type_id: 3,
    leave_type_name: 'Maternity Leave',
    leave_type_code: 'MATERNITY',
    pay_percent: 100.0,
    accrual_method: 'fixed',
    days_per_year: 120.0,
    extra_days_per_service_year: 0.0,
    max_days: 120.0,
    min_service_months: 6,
    max_carry_forward_days: 0.0,
    carry_forward_expiry_months: 0,
    allow_negative_balance: false,
    allow_encashment: false,
    requires_attachment: true,
    allow_half_day: false,
    rounding: 'full_day',
    gender: 'female',
    notice_days: 30,
    max_splits_per_year: 2,
    state: 'active',
    selected: false
  },
  {
    id: 4,
    uuid: 'rul-draft-4',
    leave_policy_id: 0,
    leave_type_id: 4,
    leave_type_name: 'Paternity Leave',
    leave_type_code: 'PATERNITY',
    pay_percent: 100.0,
    accrual_method: 'fixed',
    days_per_year: 5.0,
    extra_days_per_service_year: 0.0,
    max_days: 5.0,
    min_service_months: 3,
    max_carry_forward_days: 0.0,
    carry_forward_expiry_months: 0,
    allow_negative_balance: false,
    allow_encashment: false,
    requires_attachment: false,
    allow_half_day: false,
    rounding: 'full_day',
    gender: 'male',
    notice_days: 3,
    max_splits_per_year: 1,
    state: 'active',
    selected: false
  }
];

// Helper to create a new blank/default rule for dynamic insertion
const createBlankRule = (): LeavePolicyRuleRecord & { selected: boolean } => {
  const usedTypeIds = rules.value.map(r => r.leave_type_id);
  const unusedType = leaveTypesData.value.find(lt => !usedTypeIds.includes(lt.id));
  const chosenType = unusedType || leaveTypesData.value[0] || { id: 1, name: 'Annual Leave', code: 'ANNUAL', is_paid: true };

  const code = (chosenType.code || '').toUpperCase();
  const defaults = statutoryDefaultsByCode[code] || {
    accrual_method: 'annual_grant',
    days_per_year: 10.0,
    extra_days_per_service_year: 0.0,
    max_days: 10.0,
    pay_percent: chosenType.is_paid ? 100.0 : 0.0,
    min_service_months: 3,
    max_carry_forward_days: 0.0,
    carry_forward_expiry_months: 0,
    notice_days: 7,
    max_splits_per_year: 3,
    rounding: 'half_day',
    gender: null,
    allow_negative_balance: false,
    allow_encashment: false,
    requires_attachment: false,
    allow_half_day: true
  };

  const id = Date.now();
  return {
    id,
    uuid: `rul-draft-${id}`,
    leave_policy_id: 0,
    leave_type_id: chosenType.id,
    leave_type_name: chosenType.name,
    leave_type_code: chosenType.code,
    accrual_method: defaults.accrual_method || 'annual_grant',
    days_per_year: defaults.days_per_year ?? 10.0,
    extra_days_per_service_year: defaults.extra_days_per_service_year ?? 0.0,
    max_days: defaults.max_days ?? 10.0,
    pay_percent: defaults.pay_percent ?? 100.0,
    min_service_months: defaults.min_service_months ?? 3,
    max_carry_forward_days: defaults.max_carry_forward_days ?? 0.0,
    carry_forward_expiry_months: defaults.carry_forward_expiry_months ?? 0,
    notice_days: defaults.notice_days ?? 7,
    max_splits_per_year: defaults.max_splits_per_year ?? null,
    rounding: defaults.rounding ?? 'half_day',
    gender: defaults.gender ?? null,
    allow_negative_balance: defaults.allow_negative_balance ?? false,
    allow_encashment: defaults.allow_encashment ?? false,
    requires_attachment: defaults.requires_attachment ?? false,
    allow_half_day: defaults.allow_half_day ?? true,
    state: 'active',
    selected: false
  };
};

// ─── Rules State (Tab 2 Dynamic Child Sub-Table) ───
const rules = ref<(LeavePolicyRuleRecord & { selected: boolean })[]>(getStatutoryDefaultRules());

// Selection & Batch Action State
const selectedCount = computed(() => rules.value.filter(r => r.selected).length);
const isAllSelected = computed(() => rules.value.length > 0 && selectedCount.value === rules.value.length);

const toggleSelectAll = (e: Event) => {
  const checked = (e.target as HTMLInputElement).checked;
  rules.value.forEach(r => { r.selected = checked; });
};

const clearRuleSelection = () => {
  rules.value.forEach(r => { r.selected = false; });
};

const handleBatchDeleteRules = () => {
  const count = selectedCount.value;
  rules.value = rules.value.filter(r => !r.selected);
  showToast(`Removed ${count} row(s).`);
};

// ─── Dynamic Table Behavior: Add Row Directly Below Table ───
const addRuleRow = () => {
  const newRow = createBlankRule();
  rules.value.push(newRow);
  showToast(`Row ${rules.value.length} added.`);
};

// Auto-fill defaults when leave type is changed inline in the table cell
const onInlineLeaveTypeChange = (row: LeavePolicyRuleRecord & { selected: boolean }) => {
  const chosenType = leaveTypesData.value.find(lt => lt.id === Number(row.leave_type_id));
  if (chosenType) {
    row.leave_type_name = chosenType.name;
    row.leave_type_code = chosenType.code;
    const code = chosenType.code.toUpperCase();
    const defaults = statutoryDefaultsByCode[code];
    if (defaults) {
      if (defaults.accrual_method) row.accrual_method = defaults.accrual_method;
      if (defaults.days_per_year !== undefined) row.days_per_year = defaults.days_per_year;
      if (defaults.extra_days_per_service_year !== undefined) row.extra_days_per_service_year = defaults.extra_days_per_service_year;
      if (defaults.max_days !== undefined) row.max_days = defaults.max_days;
      if (defaults.pay_percent !== undefined) row.pay_percent = defaults.pay_percent;
      if (defaults.min_service_months !== undefined) row.min_service_months = defaults.min_service_months;
      if (defaults.max_carry_forward_days !== undefined) row.max_carry_forward_days = defaults.max_carry_forward_days;
      if (defaults.carry_forward_expiry_months !== undefined) row.carry_forward_expiry_months = defaults.carry_forward_expiry_months;
      if (defaults.notice_days !== undefined) row.notice_days = defaults.notice_days;
      if (defaults.rounding) row.rounding = defaults.rounding;
      if (defaults.gender !== undefined) row.gender = defaults.gender;
      if (defaults.allow_encashment !== undefined) row.allow_encashment = defaults.allow_encashment;
      if (defaults.allow_half_day !== undefined) row.allow_half_day = defaults.allow_half_day;
      if (defaults.requires_attachment !== undefined) row.requires_attachment = defaults.requires_attachment;
      if (defaults.allow_negative_balance !== undefined) row.allow_negative_balance = defaults.allow_negative_balance;
    }
  }
};

// ─── Modal State: Expand Row Modal (Haleta ERP Academic Qualification Standard) ───
const showRowModal = ref(false);
const activeRowData = ref<any>(null);
const activeRowIndex = ref<number>(-1);

const openRowModal = (row: any, idx: number) => {
  activeRowData.value = row;
  activeRowIndex.value = idx;
  showRowModal.value = true;
};

const closeRowModal = () => {
  showRowModal.value = false;
  activeRowData.value = null;
  activeRowIndex.value = -1;
};

// Title matches exact Academic Qualification (Row 1) structure!
const modalTitle = computed(() => {
  return `Entitlement Rule (Row ${activeRowIndex.value + 1})`;
});

const isFirstRow = computed(() => activeRowIndex.value <= 0);
const isLastRow = computed(() => activeRowIndex.value >= rules.value.length - 1);

const deleteModalRow = () => {
  if (activeRowIndex.value < 0 || activeRowIndex.value >= rules.value.length) return;
  rules.value.splice(activeRowIndex.value, 1);
  if (rules.value.length === 0) {
    closeRowModal();
  } else {
    activeRowIndex.value = Math.min(activeRowIndex.value, rules.value.length - 1);
    activeRowData.value = rules.value[activeRowIndex.value];
  }
  showToast('Row deleted.');
};

const moveRowUp = () => {
  const idx = activeRowIndex.value;
  if (idx <= 0) return;
  const temp = rules.value[idx];
  rules.value[idx] = rules.value[idx - 1];
  rules.value[idx - 1] = temp;
  activeRowIndex.value = idx - 1;
};

const moveRowDown = () => {
  const idx = activeRowIndex.value;
  if (idx >= rules.value.length - 1) return;
  const temp = rules.value[idx];
  rules.value[idx] = rules.value[idx + 1];
  rules.value[idx + 1] = temp;
  activeRowIndex.value = idx + 1;
};

const duplicateModalRow = () => {
  const idx = activeRowIndex.value;
  if (!activeRowData.value) return;
  const clone = JSON.parse(JSON.stringify(activeRowData.value));
  clone.id = Date.now();
  clone.uuid = `rul-draft-${Date.now()}`;
  clone.selected = false;
  rules.value.splice(idx + 1, 0, clone);
  activeRowIndex.value = idx + 1;
  activeRowData.value = clone;
  showToast('Row duplicated.');
};

const insertRowAbove = () => {
  const idx = activeRowIndex.value;
  const blank = createBlankRule();
  rules.value.splice(idx, 0, blank);
  activeRowIndex.value = idx;
  activeRowData.value = blank;
  showToast('New row inserted above.');
};

const insertRowBelow = () => {
  const idx = activeRowIndex.value;
  const blank = createBlankRule();
  rules.value.splice(idx + 1, 0, blank);
  activeRowIndex.value = idx + 1;
  activeRowData.value = blank;
  showToast('New row inserted below.');
};

// Modal Leave Type change handler
const onModalLeaveTypeChange = () => {
  if (activeRowData.value) {
    onInlineLeaveTypeChange(activeRowData.value);
  }
};

const handleTemplateChange = (val: any) => {
  if (!val) {
    rules.value = getStatutoryDefaultRules();
    showToast('Reset to statutory baseline minimums.');
    return;
  }
  const sourcePolicy = leavePoliciesData.value.find(p => p.id === Number(val));
  if (sourcePolicy) {
    policyForm.value.work_calendar_id = sourcePolicy.work_calendar_id;
    if (!policyForm.value.description) {
      policyForm.value.description = `Derived from ${sourcePolicy.name}. ` + (sourcePolicy.description || '');
    }
    rules.value = sourcePolicy.rules.map((r, i) => ({
      ...r,
      id: Date.now() + i,
      uuid: `rul-draft-${Date.now() + i}`,
      leave_policy_id: 0,
      selected: false
    }));
    showToast(`Loaded ${sourcePolicy.rules.length} rule(s) from "${sourcePolicy.name}".`);
  }
};

// ─── Save Master Policy ───
const handleSavePolicy = () => {
  if (!policyForm.value.name.trim()) {
    alert('Please enter a policy name.');
    return;
  }
  if (!policyForm.value.code.trim()) {
    alert('Please enter a unique policy code.');
    return;
  }
  if (!policyForm.value.effective_from) {
    alert('Please select an effective from date.');
    return;
  }
  if (rules.value.length === 0) {
    alert('Please define at least one entitlement rule in the policy.');
    return;
  }

  const selectedEntity = entityOptions.find(e => e.value === policyForm.value.entity_id);
  const selectedCal = workCalendarOptions.find(c => c.value === policyForm.value.work_calendar_id);

  createLeavePolicy({
    name: policyForm.value.name,
    code: policyForm.value.code,
    entity_id: policyForm.value.entity_id,
    entity_name: selectedEntity?.label.split('(')[0].trim() || 'Haleta Corporate',
    work_calendar_id: policyForm.value.work_calendar_id,
    work_calendar_name: selectedCal?.label.split('(')[0].trim() || 'CAL-OFFICE',
    effective_from: policyForm.value.effective_from,
    description: policyForm.value.description,
    rules: rules.value.map(r => {
      const { selected, ...cleanRule } = r;
      return cleanRule;
    })
  });

  isSaved.value = true;
  showToast(`Leave policy "${policyForm.value.name}" saved successfully.`);
  setTimeout(() => {
    router.push('/hr/leave-policies');
  }, 900);
};

const handleClearForm = () => {
  if (confirm('Are you sure you want to clear the policy form?')) {
    policyForm.value = {
      name: '',
      code: '',
      entity_id: 3,
      work_calendar_id: 1,
      effective_from: '2026-07-08',
      effective_to: '',
      description: ''
    };
    rules.value = [];
  }
};
</script>

<template>
  <div class="leave-policy-create-page">
    <!-- Top Bar Navigation (AGENTS.md Rule 4 & Breadcrumb Standard) -->
    <div class="top-nav-bar">
      <AppBreadcrumb :items="breadcrumbItems" />

      <div class="top-actions-cluster">
        <!-- Save State Indicator -->
        <SaveStateBadge :isSaved="isSaved" style="margin-left: 0" />

        <!-- Clear Form Secondary Button -->
        <AppButton 
          variant="outline" 
          size="sm" 
          title="Clear all fields"
          @click="handleClearForm"
        >
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>

        <!-- Save Primary Blue Button -->
        <AppButton 
          variant="primary" 
          size="sm" 
          @click="handleSavePolicy"
        >
          Save Policy
        </AppButton>
      </div>
    </div>

    <!-- ═══ PRIMARY TABS (<BaseTabs /> Capsule Standard AGENTS.md Rule 1) ═══ -->
    <BaseTabs 
      v-model="activeTab" 
      :tabs="policyTabs" 
      size="md" 
    />

    <!-- Toast Feedback -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <div class="policy-creation-body">
      <!-- ═══════════════════════════════════════════════════════════════ -->
      <!-- TAB 1: POLICY BLUEPRINT & SCOPE (HR Schema Lines 1576–1597)   -->
      <!-- ═══════════════════════════════════════════════════════════════ -->
      <div v-if="activeTab === 'details'" class="clean-card">
        <div class="card-header-bar flex-between">
          <div class="header-titles">
            <h2 class="card-title">Policy Blueprint & Scope</h2>
            <p class="card-subtitle">General catalog parameters, owning branch hierarchy, and day-counting work calendar.</p>
          </div>
          <div class="template-selector-box">
            <label class="template-label">Preset Template / Clone:</label>
            <FormSelect
              v-model="selectedTemplateId"
              :options="templateOptions"
              placeholder="Select Template"
              @change="handleTemplateChange"
              class="template-select-input"
            />
          </div>
        </div>

        <div class="form-grid-3">
          <!-- Policy Name -->
          <div class="form-group">
            <label class="form-label required">Policy Name</label>
            <FormInput
              v-model="policyForm.name"
              @blur="handleNameBlur"
            />
          </div>

          <!-- Policy Code -->
          <div class="form-group">
            <label class="form-label required">Policy Code</label>
            <FormInput
              v-model="policyForm.code"
              hint="Unique business identifier, e.g. POL-OFFICE-2026"
            />
          </div>

          <!-- Owning Entity / Branch -->
          <div class="form-group">
            <label class="form-label required">Owning Entity</label>
            <FormSelect
              v-model="policyForm.entity_id"
              :options="entityOptions"
              placeholder="Select"
            />
          </div>

          <!-- Work Calendar -->
          <div class="form-group">
            <label class="form-label required">Work Calendar</label>
            <FormSelect
              v-model="policyForm.work_calendar_id"
              :options="workCalendarOptions"
              placeholder="Select"
              hint="Day-counting basis, weekend rules, and monthly payroll divisor"
            />
          </div>

          <!-- Effective From -->
          <div class="form-group">
            <label class="form-label required">Effective From</label>
            <FormInput
              type="date"
              v-model="policyForm.effective_from"
            />
          </div>

          <!-- Effective To -->
          <div class="form-group">
            <label class="form-label">Effective To</label>
            <FormInput
              type="date"
              v-model="policyForm.effective_to"
              hint="Leave blank if policy remains active indefinitely"
            />
          </div>
        </div>

        <!-- Description -->
        <div class="form-group full-width-group">
          <label class="form-label">Policy Scope Description</label>
          <FormInput
            v-model="policyForm.description"
          />
        </div>

        <!-- Footer Navigation to Tab 2 -->
        <div class="tab-step-nav">
          <div class="tab-nav-info">
            <p class="tab-nav-title">Next Step: Entitlement Rules</p>
            <p class="tab-nav-sub">Configure statutory days, carry-forward rollover ceilings, and pay percentages per leave type.</p>
          </div>
          <AppButton variant="primary" size="sm" @click="activeTab = 'rules'">
            Continue to Entitlement Rules
            <template #icon-right><ArrowRight :size="15" /></template>
          </AppButton>
        </div>
      </div>

      <!-- ═══════════════════════════════════════════════════════════════ -->
      <!-- TAB 2: DYNAMIC ENTITLEMENT RULES SUB-TABLE (AGENTS.md Rule 11)  -->
      <!-- ═══════════════════════════════════════════════════════════════ -->
      <div v-if="activeTab === 'rules'" class="clean-card">
        <!-- Header: Clean title ONLY, strictly ZERO add buttons in header -->
        <div class="card-header-bar">
          <div class="header-titles">
            <h2 class="card-title">Leave Entitlement Rules</h2>
            <p class="card-subtitle">Statutory accrual formulas, carry-forward ceilings, and encashment rights per leave type.</p>
          </div>
        </div>

        <!-- Dynamic Child Sub-Table (Canonical Rule 11 & Academic Qualification Standard) -->
        <div class="child-table-wrapper">
          <table class="child-table">
            <thead>
              <tr class="child-table-header">
                <th class="child-th child-th-check">
                  <input
                    type="checkbox"
                    :checked="isAllSelected"
                    @change="toggleSelectAll($event)"
                    class="table-checkbox"
                    aria-label="Select all rules"
                  />
                </th>
                <th class="child-th child-th-no">No.</th>
                <th class="child-th" style="min-width: 220px;">Leave Type</th>
                <th class="child-th" style="min-width: 210px;">Accrual Method</th>
                <th class="child-th" style="min-width: 130px;">Days / Yr</th>
                <th class="child-th" style="min-width: 120px;">Pay %</th>
                <th class="child-th child-th-col-icon">
                  <IconColumnSolid :size="13" class="col-icon-solid" />
                </th>
              </tr>
            </thead>
            <tbody>
              <!-- Empty State -->
              <tr v-if="rules.length === 0">
                <td colspan="7" class="child-td-empty">No Row</td>
              </tr>

              <!-- Dynamic Inline Editable Row -->
              <tr v-else v-for="(row, idx) in rules" :key="row.id" class="child-tr">
                <!-- Checkbox -->
                <td class="child-td child-td-check">
                  <input
                    type="checkbox"
                    v-model="row.selected"
                    class="table-checkbox"
                    aria-label="Select rule row"
                  />
                </td>

                <!-- Sequential index (Rule 11) -->
                <td class="child-td child-td-no">{{ idx + 1 }}</td>

                <!-- Leave Type Inline Dropdown -->
                <td class="child-td">
                  <select 
                    v-model="row.leave_type_id" 
                    class="child-inline-select font-medium"
                    @change="onInlineLeaveTypeChange(row)"
                  >
                    <option v-for="lt in leaveTypesData" :key="lt.id" :value="lt.id">
                      {{ lt.name }} ({{ lt.code }})
                    </option>
                  </select>
                </td>

                <!-- Accrual Method Inline Dropdown -->
                <td class="child-td">
                  <select 
                    v-model="row.accrual_method" 
                    class="child-inline-select"
                  >
                    <option value="per_service_year">Per Service Year (+1d statutory)</option>
                    <option value="annual_grant">Annual Grant (Fiscal lump sum)</option>
                    <option value="monthly_accrual">Monthly Accrual (Prorated)</option>
                    <option value="fixed">Fixed Event Allocation</option>
                  </select>
                </td>

                <!-- Annual Days / Year Inline Input -->
                <td class="child-td">
                  <input 
                    type="number" 
                    step="0.5" 
                    v-model.number="row.days_per_year" 
                    class="child-inline-input text-right font-medium" 
                    min="0"
                  />
                </td>

                <!-- Pay % Inline Input -->
                <td class="child-td">
                  <div class="relative flex items-center">
                    <input 
                      type="number" 
                      v-model.number="row.pay_percent" 
                      class="child-inline-input text-right pr-6" 
                      min="0" 
                      max="100" 
                    />
                    <span class="inline-unit-pct">%</span>
                  </div>
                </td>

                <!-- Expand Row Action Column (<Expand :size="14" />) -->
                <td class="child-td child-td-col-icon">
                  <button 
                    type="button" 
                    class="btn-row-expand" 
                    @click="openRowModal(row, idx)" 
                    title="Expand Row Details"
                  >
                    <Expand :size="14" />
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- The ONE Button Below Table: strictly labeled "Add Row" (Rule 11.2 Standard) -->
        <button 
          type="button" 
          class="btn-add-row" 
          @click="addRuleRow"
        >
          <Plus :size="13" />
          <span>Add Row</span>
        </button>
      </div>
    </div>

    <!-- Floating Batch Action Bar for Rules Sub-Table (Rule 11.3) -->
    <TableFloatingBar 
      :show="selectedCount > 0"
      :selected-count="selectedCount"
      :total-count="rules.length"
      @delete="handleBatchDeleteRules" 
      @close="clearRuleSelection"
    />

    <!-- ═══════════════════════════════════════════════════════════════════ -->
    <!-- EXPAND ROW MODAL (Matching Employee Academic Qualification Standard)-->
    <!-- ═══════════════════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <div v-if="showRowModal && activeRowData" class="row-modal-overlay" @click="closeRowModal">
        <div class="row-modal-container" @click.stop>
          <!-- Modal Header -->
          <div class="row-modal-header">
            <h3 class="row-modal-title">{{ modalTitle }}</h3>
            <button type="button" class="btn-modal-close" @click="closeRowModal" title="Close">
              <X :size="16" />
            </button>
          </div>

          <!-- Modal Body -->
          <div class="row-modal-body">
            <div class="modal-grid-2">
              <!-- Leave Type -->
              <div class="modal-form-group">
                <label class="modal-form-label">Leave Type <span class="required-star">*</span></label>
                <div class="modal-select-wrap">
                  <select 
                    v-model="activeRowData.leave_type_id" 
                    class="modal-form-select" 
                    @change="onModalLeaveTypeChange"
                  >
                    <option v-for="lt in leaveTypesData" :key="lt.id" :value="lt.id">
                      {{ lt.name }} ({{ lt.code }})
                    </option>
                  </select>
                  <ChevronDown :size="14" class="modal-select-chevron" />
                </div>
              </div>

              <!-- Accrual Method -->
              <div class="modal-form-group">
                <label class="modal-form-label">Accrual Method <span class="required-star">*</span></label>
                <div class="modal-select-wrap">
                  <select v-model="activeRowData.accrual_method" class="modal-form-select">
                    <option value="per_service_year">Per Service Year (+1d statutory)</option>
                    <option value="annual_grant">Annual Grant (Fiscal lump sum)</option>
                    <option value="monthly_accrual">Monthly Accrual (Prorated)</option>
                    <option value="fixed">Fixed Event Allocation</option>
                  </select>
                  <ChevronDown :size="14" class="modal-select-chevron" />
                </div>
              </div>

              <!-- Statutory Annual Days -->
              <div class="modal-form-group">
                <label class="modal-form-label">Statutory Annual Days <span class="required-star">*</span></label>
                <input 
                  type="number" 
                  step="0.5" 
                  v-model.number="activeRowData.days_per_year" 
                  class="modal-form-input" 
                />
                <p class="modal-form-hint">Baseline annual quota (e.g. 16.0d annual, 30.0d sick, 120.0d maternity).</p>
              </div>

              <!-- Pay Percent (%) -->
              <div class="modal-form-group">
                <label class="modal-form-label">Pay Percent (%) <span class="required-star">*</span></label>
                <input 
                  type="number" 
                  v-model.number="activeRowData.pay_percent" 
                  class="modal-form-input" 
                  min="0" 
                  max="100" 
                />
                <p class="modal-form-hint">100 for full pay, 50 for half pay, 0 for unpaid leave.</p>
              </div>

              <!-- Extra Days Per Service Year -->
              <div class="modal-form-group">
                <label class="modal-form-label">Extra Days / Service Year</label>
                <input 
                  type="number" 
                  step="0.5" 
                  v-model.number="activeRowData.extra_days_per_service_year" 
                  class="modal-form-input" 
                />
                <p class="modal-form-hint">+1.0 day for each additional completed service year.</p>
              </div>

              <!-- Entitlement Ceiling / Max Days -->
              <div class="modal-form-group">
                <label class="modal-form-label">Entitlement Ceiling / Max Days</label>
                <input 
                  type="number" 
                  step="0.5" 
                  v-model.number="activeRowData.max_days" 
                  class="modal-form-input" 
                />
                <p class="modal-form-hint">Statutory ceiling cap (e.g. 30.0d annual cap, 180.0d sick cap).</p>
              </div>

              <!-- Min Service Months -->
              <div class="modal-form-group">
                <label class="modal-form-label">Min Service Required (Months)</label>
                <input 
                  type="number" 
                  v-model.number="activeRowData.min_service_months" 
                  class="modal-form-input" 
                  min="0" 
                />
                <p class="modal-form-hint">Tenure required before this leave can be requested.</p>
              </div>

              <!-- Max Carry Forward Days -->
              <div class="modal-form-group">
                <label class="modal-form-label">Max Carry Forward Days</label>
                <input 
                  type="number" 
                  step="0.5" 
                  v-model.number="activeRowData.max_carry_forward_days" 
                  class="modal-form-input" 
                  min="0" 
                />
                <p class="modal-form-hint">Unused balance rollable into next fiscal year (0 = forfeiture).</p>
              </div>

              <!-- Carry Forward Expiry (Months) -->
              <div class="modal-form-group">
                <label class="modal-form-label">Carry Forward Expiry (Months)</label>
                <input 
                  type="number" 
                  v-model.number="activeRowData.carry_forward_expiry_months" 
                  class="modal-form-input" 
                  min="0" 
                />
                <p class="modal-form-hint">Statutory limit: 24 months (2 fiscal cycles in Ethiopia).</p>
              </div>

              <!-- Advance Notice Days -->
              <div class="modal-form-group">
                <label class="modal-form-label">Advance Notice Required (Days)</label>
                <input 
                  type="number" 
                  v-model.number="activeRowData.notice_days" 
                  class="modal-form-input" 
                  min="0" 
                />
                <p class="modal-form-hint">Days in advance employee must submit request.</p>
              </div>

              <!-- Fractional Rounding -->
              <div class="modal-form-group">
                <label class="modal-form-label">Fractional Day Rounding</label>
                <div class="modal-select-wrap">
                  <select v-model="activeRowData.rounding" class="modal-form-select">
                    <option value="none">Exact Fractional Days (e.g. 1.33 d)</option>
                    <option value="half_day">Round to Half Day (0.5 d increments)</option>
                    <option value="full_day">Round to Full Day (1.0 d increments)</option>
                  </select>
                  <ChevronDown :size="14" class="modal-select-chevron" />
                </div>
              </div>

              <!-- Gender Eligibility -->
              <div class="modal-form-group">
                <label class="modal-form-label">Gender Eligibility</label>
                <div class="modal-select-wrap">
                  <select v-model="activeRowData.gender" class="modal-form-select">
                    <option :value="null">All Employees (No gender restriction)</option>
                    <option value="female">Female Staff Only (e.g. Maternity)</option>
                    <option value="male">Male Staff Only (e.g. Paternity)</option>
                  </select>
                  <ChevronDown :size="14" class="modal-select-chevron" />
                </div>
              </div>

              <!-- Policy Governance Checkboxes (Col-span-2) -->
              <div class="modal-form-group col-span-2 pt-2">
                <FormCheckbox
                  v-model="activeRowData.allow_encashment"
                  label="Allow Leave Encashment"
                  description="Permit unused balance to be converted to monetary cash payout upon application or separation."
                />
              </div>

              <div class="modal-form-group col-span-2">
                <FormCheckbox
                  v-model="activeRowData.allow_half_day"
                  label="Allow Half-Day Bookings"
                  description="Permit employees to book 0.5 morning or afternoon units against this entitlement."
                />
              </div>

              <div class="modal-form-group col-span-2">
                <FormCheckbox
                  v-model="activeRowData.requires_attachment"
                  label="Mandatory Supporting Evidence"
                  description="Enforce submission of medical certificate, court summons, or official evidence."
                />
              </div>

              <div class="modal-form-group col-span-2">
                <FormCheckbox
                  v-model="activeRowData.allow_negative_balance"
                  label="Allow Negative Balance"
                  description="Permit employees to borrow against next fiscal year's allocation if current balance is depleted."
                />
              </div>
            </div>
          </div>

          <!-- Footer (The Canonical Haleta ERP Row Controls Footer) -->
          <div class="row-modal-footer">
            <button type="button" class="btn-modal-delete" @click="deleteModalRow">
              Delete
            </button>
            <div class="row-modal-actions-right">
              <button 
                type="button" 
                class="btn-modal-ctrl-icon" 
                :disabled="isLastRow" 
                @click="moveRowDown" 
                title="Move Down"
              >
                <ArrowDown :size="15" />
              </button>
              <button 
                type="button" 
                class="btn-modal-ctrl-icon" 
                :disabled="isFirstRow" 
                @click="moveRowUp" 
                title="Move Up"
              >
                <ArrowUp :size="15" />
              </button>
              <button 
                type="button" 
                class="btn-modal-ctrl-action" 
                @click="duplicateModalRow"
              >
                <Copy :size="13" />
                <span>Duplicate Row</span>
              </button>
              <button 
                type="button" 
                class="btn-modal-ctrl-action" 
                @click="insertRowAbove"
              >
                <Plus :size="13" />
                <span>Insert Above</span>
              </button>
              <button 
                type="button" 
                class="btn-modal-ctrl-action" 
                @click="insertRowBelow"
              >
                <Plus :size="13" />
                <span>Insert Below</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.leave-policy-create-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: #f8fafc;
  min-height: 100vh;
}

/* Top Bar Navigation */
.top-nav-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background-color: #ffffff;
  padding: 12px 18px;
  border-radius: 10px;
  border: 1px solid #e2e8f0;
}

.top-actions-cluster {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* Save State Status Pill */
.save-status-pill {
  font-size: 11.5px;
  font-weight: 500;
  padding: 3px 10px;
  border-radius: 9999px;
}
.pill-not-saved {
  background-color: #fef3c7;
  color: #92400e;
}
.pill-saved {
  background-color: #ecfdf5;
  color: #059669;
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

/* Button Standards (Rule 6: 8px to 10px rounded rectangle, NEVER pills) */
.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  height: 38px;
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
  height: 38px;
  padding: 0 14px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-secondary-action:hover {
  background-color: #f8fafc;
}

/* Main Cards */
.policy-creation-body {
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

.card-header-bar {
  margin-bottom: 18px;
}
.card-header-bar.flex-between {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.template-selector-box {
  display: flex;
  align-items: center;
  gap: 10px;
}
.template-label {
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  white-space: nowrap;
}
.template-select-input {
  min-width: 320px;
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

/* Form Layout */
.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
  margin-bottom: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
}

.full-width-group {
  margin-top: 4px;
}

.form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 4px;
}
.form-label.required::after,
.required-star {
  content: ' *';
  color: #dc2626;
}

/* Tab Navigation Footer (Tab 1 -> Tab 2) */
.tab-step-nav {
  margin-top: 24px;
  padding-top: 18px;
  border-top: 1px solid #f1f5f9;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.tab-nav-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.tab-nav-sub {
  font-size: 12px;
  color: #737373;
  margin: 2px 0 0;
}

/* ═════════════════════════════════════════════════════════════════════ */
/* DYNAMIC CHILD SUB-TABLE (Academic Qualification Standard)             */
/* ═════════════════════════════════════════════════════════════════════ */
.child-table-wrapper {
  overflow-x: auto;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  margin-bottom: 12px;
  background-color: #ffffff;
}

.child-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
}

.child-table-header {
  background-color: #fafafa;
}

.child-th {
  height: 34px;
  padding: 6px 10px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  border-bottom: 1px solid #e2e8f0;
  text-align: left;
  white-space: nowrap;
}

.child-th-no, .child-td-no {
  width: 44px;
  text-align: center;
  font-size: 12px;
  color: #94a3b8;
}

.child-th-check, .child-td-check {
  width: 38px;
  text-align: center;
}

.child-th-col-icon, .child-td-col-icon {
  width: 44px;
  text-align: center;
}

.col-icon-solid {
  color: #737373;
  margin: 0 auto;
  display: block;
}

.child-tr {
  transition: background-color 0.12s ease;
}
.child-tr:hover {
  background-color: #fafbfc;
}

.child-td {
  height: 40px;
  padding: 4px 8px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}
.child-tr:last-child .child-td {
  border-bottom: none;
}

.child-td-empty {
  text-align: center;
  padding: 24px 16px;
  font-size: 12.5px;
  color: #94a3b8;
}

.table-checkbox {
  width: 15px;
  height: 15px;
  border-radius: 4px;
  border: 1px solid #cbd5e1;
  accent-color: #0B529C;
  cursor: pointer;
}

/* Child Inline Input / Select System (Direct Rapid Entry) */
.child-inline-input {
  width: 100%;
  height: 30px;
  border: 1px solid transparent;
  border-radius: 4px;
  padding: 0 8px;
  font-size: 12.5px;
  color: #404040;
  background: transparent;
  outline: none;
  transition: all 0.15s ease;
}
.child-inline-input:hover {
  background-color: #f8fafc;
  border-color: #e2e8f0;
}
.child-inline-input:focus {
  background-color: #ffffff;
  border-color: #0B529C;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.08);
}

.child-inline-select {
  width: 100%;
  height: 30px;
  border: 1px solid transparent;
  border-radius: 4px;
  padding: 0 6px;
  font-size: 12.5px;
  color: #404040;
  background: transparent;
  outline: none;
  cursor: pointer;
  transition: all 0.15s ease;
}
.child-inline-select:hover {
  background-color: #f8fafc;
  border-color: #e2e8f0;
}
.child-inline-select:focus {
  background-color: #ffffff;
  border-color: #0B529C;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.08);
}

.text-right {
  text-align: right;
}
.pr-6 {
  padding-right: 22px !important;
}
.inline-unit-pct {
  position: absolute;
  right: 8px;
  font-size: 11px;
  font-weight: 500;
  color: #94a3b8;
  pointer-events: none;
}

.btn-row-expand {
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  padding: 4px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: all 0.15s ease;
}
.btn-row-expand:hover {
  color: #0f172a;
  background-color: #f1f5f9;
}

/* The ONE Add Row button directly below table */
.btn-add-row {
  height: 32px;
  padding: 0 14px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-add-row:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

/* ═════════════════════════════════════════════════════════════════════ */
/* EXPAND ROW MODAL SYSTEM (Academic Qualification Standard)             */
/* ═════════════════════════════════════════════════════════════════════ */
.row-modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  background-color: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(2px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
}

.row-modal-container {
  background-color: #ffffff;
  border-radius: 16px;
  width: 100%;
  max-width: 720px;
  max-height: 88vh;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  animation: modalFadeIn 0.15s ease-out;
}

@keyframes modalFadeIn {
  from {
    opacity: 0;
    transform: scale(0.97);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.row-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px 16px;
  background-color: #ffffff;
}

.row-modal-title {
  margin: 0;
  font-size: 16.5px;
  font-weight: 600;
  color: #404040;
}

.btn-modal-close {
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  padding: 6px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}
.btn-modal-close:hover {
  color: #0f172a;
  background-color: #f1f5f9;
}

.row-modal-body {
  padding: 8px 24px 24px;
  overflow-y: auto;
  flex: 1;
}

.modal-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.modal-form-group {
  display: flex;
  flex-direction: column;
}

.modal-form-group.col-span-2 {
  grid-column: span 2 / span 2;
}

.modal-form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 4px;
}

.modal-form-hint {
  font-size: 11.5px;
  color: #737373;
  line-height: 1.45;
  margin-top: 4px;
}

.modal-select-wrap {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
}

.modal-select-wrap .modal-form-select {
  width: 100%;
  appearance: none;
  -webkit-appearance: none;
  padding-right: 32px;
}

.modal-select-chevron {
  position: absolute;
  right: 12px;
  color: #737373;
  pointer-events: none;
}

.modal-form-input {
  height: 38px;
  padding: 0 12px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
  transition: all 0.15s ease;
}
.modal-form-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.modal-form-select {
  height: 38px;
  padding: 0 12px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
  cursor: pointer;
  transition: all 0.15s ease;
}
.modal-form-select:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

/* Modal Footer */
.row-modal-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 24px;
  background-color: #f8fafc;
  border-top: 1px solid #f1f5f9;
}

.btn-modal-delete {
  background-color: #ef4444;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  padding: 8px 18px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-modal-delete:hover {
  background-color: #dc2626;
}

.row-modal-actions-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-modal-ctrl-icon {
  width: 34px;
  height: 34px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-modal-ctrl-icon:hover:not(:disabled) {
  background-color: #f1f5f9;
  color: #0f172a;
}
.btn-modal-ctrl-icon:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.btn-modal-ctrl-action {
  height: 34px;
  padding: 0 12px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-modal-ctrl-action:hover {
  background-color: #f1f5f9;
  color: #0f172a;
  border-color: #cbd5e1;
}
</style>
