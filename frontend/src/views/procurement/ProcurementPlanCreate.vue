<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { X, ClipboardList, Layers, ChevronDown, ChevronRight, MoreVertical, Save } from 'lucide-vue-next';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormRichText from '../../components/FormRichText.vue';
import DynamicSubTable, { type DynamicTableColumn } from '../../components/DynamicSubTable.vue';
import { useToast } from '../../composables/useToast';

import {
  procurementPlansStore,
  procurementPlanVersionsStore,
  procurementPlanLinesStore,
  type PlanPeriodType,
  type PlanStatus,
  planPeriodTypeOptions,
  planStatusOptions,
  fiscalYearOptions,
  currencyOptions,
  budgetOptions,
  unitOptions,
  entityOptions,
  productOptions,
  measurementOptions,
  categoryOptions,
  purchaseMethodOptions,
  organizationUnitOptions,
  locationOptions,
  budgetLineOptions,
  costCenterOptions,
  generatePlanNumber,
  getCurrentPlanVersion,
  getVersionLines,
  formatCurrencyETB
} from './procurementPlanData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

const editingId = computed(() => (route.params.id ? Number(route.params.id) : null));
const revisingId = computed(() => (route.query.reviseId ? Number(route.query.reviseId) : null));
const isReviseMode = computed(() => Boolean(revisingId.value));
const isSaved = ref(false);
const isNotesOpen = ref(true);
const showTopActionsMenu = ref(false);

const closeTopActionsMenu = () => {
  showTopActionsMenu.value = false;
};

onUnmounted(() => {
  document.removeEventListener('click', closeTopActionsMenu);
});

type TabId = 'details' | 'lines';
const activeTab = ref<TabId>('details');
const tabs = computed<BaseTabItem<TabId>[]>(() => [
  { id: 'details', label: 'Plan Details', icon: ClipboardList },
  { id: 'lines', label: 'Planned Items', icon: Layers, count: planLines.value.length }
]);

const fieldErrors = ref<{
  plan_number?: string;
  name?: string;
  period_start?: string;
  period_end?: string;
  revision_reason?: string;
}>({});

const form = ref({
  plan_number: generatePlanNumber(procurementPlansStore.value.map((p) => p.plan_number)),
  name: '',
  period_type_lookup_value_id: 'annual' as PlanPeriodType,
  fiscal_year_id: 'FY-2026',
  period_start: '2026-07-01',
  period_end: '2027-06-30',
  procurement_unit_id: '',
  entity_id: '2',
  currency_id: 'ETB',
  budget_id: '',
  plan_status_lookup_value_id: 'draft' as PlanStatus,
  notes: '',
  revision_reason: ''
});

interface PlanLineDraft {
  id?: number;
  carried_from_line_id: number | null;
  product_id: string;
  description: string;
  procurement_category_id: string;
  planned_quantity: number;
  estimated_unit_price: number;
  measurement_id: string;
  purchase_method_id: string;
  required_from: string;
  required_to: string;
  is_recurring: boolean;
  entity_id: string;
  organization_unit_id: string;
  location_id: string;
  budget_line_id: string;
  cost_center_dimension_id: string;
}

const createDefaultLine = (): PlanLineDraft => ({
  carried_from_line_id: null,
  product_id: 'PROD-101',
  description: 'Fresh Roma Tomato — Grade A kitchen supply',
  procurement_category_id: '11',
  planned_quantity: 100,
  estimated_unit_price: 62,
  measurement_id: 'KG',
  purchase_method_id: '2',
  required_from: form.value.period_start || '2026-07-01',
  required_to: form.value.period_end || '2027-06-30',
  is_recurring: false,
  entity_id: form.value.entity_id || '2',
  organization_unit_id: '12',
  location_id: 'LOC-MAIN',
  budget_line_id: 'BL-5100',
  cost_center_dimension_id: 'CC-FB-01'
});

const planLines = ref<PlanLineDraft[]>([createDefaultLine()]);

const lineColumns: DynamicTableColumn[] = [
  {
    key: 'product_id',
    label: 'Item / Product',
    type: 'select',
    options: productOptions,
    placeholder: 'Select Product',
    minWidth: '230px',
    tooltipTitle: 'Catalogued Product',
    tooltipDesc: 'Select a product from the catalog or choose Free-Text and enter a description in the row modal.'
  },
  {
    key: 'procurement_category_id',
    label: 'Category',
    type: 'select',
    options: categoryOptions,
    placeholder: 'Select Category',
    minWidth: '200px'
  },
  {
    key: 'planned_quantity',
    label: 'Planned Qty',
    type: 'number',
    align: 'right',
    minWidth: '130px'
  },
  {
    key: 'estimated_unit_price',
    label: 'Est. Unit Price',
    type: 'number',
    align: 'right',
    minWidth: '150px'
  }
];

const totalPlannedAmount = computed(() =>
  planLines.value.reduce(
    (sum, l) => sum + (Number(l.planned_quantity) || 0) * (Number(l.estimated_unit_price) || 0),
    0
  )
);

const breadcrumbItems = computed<BreadcrumbItem[]>(() => {
  const label = isReviseMode.value
    ? `Raise Revision (${form.value.plan_number})`
    : editingId.value
      ? `Edit ${form.value.plan_number}`
      : 'Create Procurement Plan';
  return [
    { label: 'Procurement Plans', to: '/procurement/plans' },
    { label }
  ];
});

watch(
  [form, planLines],
  () => {
    isSaved.value = false;
  },
  { deep: true }
);

const loadPlanIntoForm = (planId: number, asRevision: boolean) => {
  const existing = procurementPlansStore.value.find((p) => p.id === planId);
  if (!existing) return;

  form.value = {
    plan_number: existing.plan_number,
    name: existing.name,
    period_type_lookup_value_id: existing.period_type_lookup_value_id,
    fiscal_year_id: existing.fiscal_year_id,
    period_start: existing.period_start,
    period_end: existing.period_end,
    procurement_unit_id: existing.procurement_unit_id ? String(existing.procurement_unit_id) : '',
    entity_id: String(existing.entity_id),
    currency_id: existing.currency_id,
    budget_id: existing.budget_id || '',
    plan_status_lookup_value_id: asRevision ? 'revised' : existing.plan_status_lookup_value_id,
    notes: existing.notes || '',
    revision_reason: ''
  };

  const currentVer = getCurrentPlanVersion(existing.id);
  if (currentVer) {
    const existingLines = getVersionLines(currentVer.id);
    if (existingLines.length > 0) {
      planLines.value = existingLines.map((l) => ({
        id: asRevision ? undefined : l.id,
        carried_from_line_id: asRevision ? l.id : l.carried_from_line_id,
        product_id: l.product_id || '',
        description: l.description,
        procurement_category_id: String(l.procurement_category_id),
        planned_quantity: l.planned_quantity,
        estimated_unit_price: l.estimated_unit_price,
        measurement_id: l.measurement_id || 'PCS',
        purchase_method_id: l.purchase_method_id ? String(l.purchase_method_id) : '',
        required_from: l.required_from,
        required_to: l.required_to,
        is_recurring: l.is_recurring,
        entity_id: String(l.entity_id || existing.entity_id),
        organization_unit_id: l.organization_unit_id || '',
        location_id: l.location_id || '',
        budget_line_id: l.budget_line_id || '',
        cost_center_dimension_id: l.cost_center_dimension_id || ''
      }));
    }
  }
  isSaved.value = !asRevision;
};

onMounted(() => {
  document.addEventListener('click', closeTopActionsMenu);
  if (revisingId.value) {
    loadPlanIntoForm(revisingId.value, true);
  } else if (editingId.value) {
    loadPlanIntoForm(editingId.value, false);
  } else {
    if (typeof route.query.name === 'string') {
      form.value.name = route.query.name;
    }
    if (typeof route.query.period_type === 'string') {
      form.value.period_type_lookup_value_id = route.query.period_type as PlanPeriodType;
    }
    if (typeof route.query.fiscal_year_id === 'string') {
      form.value.fiscal_year_id = route.query.fiscal_year_id;
    }
    if (typeof route.query.period_start === 'string') {
      form.value.period_start = route.query.period_start;
    }
    if (typeof route.query.period_end === 'string') {
      form.value.period_end = route.query.period_end;
    }
  }
});

const clearForm = () => {
  form.value = {
    plan_number: generatePlanNumber(procurementPlansStore.value.map((p) => p.plan_number)),
    name: '',
    period_type_lookup_value_id: 'annual',
    fiscal_year_id: 'FY-2026',
    period_start: '2026-07-01',
    period_end: '2027-06-30',
    procurement_unit_id: '',
    entity_id: '2',
    currency_id: 'ETB',
    budget_id: '',
    plan_status_lookup_value_id: 'draft',
    notes: '',
    revision_reason: ''
  };
  planLines.value = [createDefaultLine()];
  fieldErrors.value = {};
  isSaved.value = false;
  toast.info('Form cleared.');
};

const validateForm = (): boolean => {
  fieldErrors.value = {};
  if (!form.value.name.trim()) {
    fieldErrors.value.name = 'Plan name is required.';
  }
  if (!form.value.period_start) {
    fieldErrors.value.period_start = 'Period start date is required.';
  }
  if (!form.value.period_end) {
    fieldErrors.value.period_end = 'Period end date is required.';
  } else if (form.value.period_start && form.value.period_end < form.value.period_start) {
    fieldErrors.value.period_end = 'Period end must be on or after period start.';
  }
  if (isReviseMode.value && !form.value.revision_reason.trim()) {
    fieldErrors.value.revision_reason = 'Revision reason is required when raising a new version.';
  }
  if (Object.keys(fieldErrors.value).length > 0) {
    activeTab.value = 'details';
    toast.error('Please resolve the highlighted required fields.');
    return false;
  }
  if (planLines.value.length === 0) {
    activeTab.value = 'lines';
    toast.error('At least one planned item line is required.');
    return false;
  }
  const missingFreeText = planLines.value.some((l) => !l.product_id && !l.description.trim());
  if (missingFreeText) {
    activeTab.value = 'lines';
    toast.error('Free-text items without a catalogued product require a description.');
    return false;
  }
  return true;
};

const persistLinesForVersion = (versionId: number) => {
  procurementPlanLinesStore.value = procurementPlanLinesStore.value.filter(
    (l) => l.procurement_plan_version_id !== versionId
  );

  let nextLineId = Math.max(0, ...procurementPlanLinesStore.value.map((l) => l.id)) + 1;

  planLines.value.forEach((line, idx) => {
    const qty = Number(line.planned_quantity) || 0;
    const price = Number(line.estimated_unit_price) || 0;
    const prodLabel =
      productOptions.find((p) => p.value === line.product_id)?.label.split(' (')[0] ||
      'Free-Text Item';
    const catLabel =
      categoryOptions.find((c) => c.value === line.procurement_category_id)?.label.split(' (')[0] ||
      'General';
    const methodLabel =
      purchaseMethodOptions.find((m) => m.value === line.purchase_method_id)?.label.split(' (')[0] ||
      'Decide Later';
    const orgLabel =
      organizationUnitOptions.find((o) => o.value === line.organization_unit_id)?.label ||
      'Entity-Wide';
    const locLabel =
      locationOptions.find((loc) => loc.value === line.location_id)?.label ||
      'Default Receiving Store';

    procurementPlanLinesStore.value.push({
      id: nextLineId,
      uuid: `ppl-${nextLineId}-${Date.now()}`,
      procurement_plan_version_id: versionId,
      line_number: idx + 1,
      description: line.description || prodLabel,
      planned_quantity: qty,
      estimated_unit_price: price,
      estimated_amount: qty * price,
      requisitioned_quantity: 0,
      ordered_quantity: 0,
      received_quantity: 0,
      actual_amount: 0,
      required_from: line.required_from || form.value.period_start,
      required_to: line.required_to || form.value.period_end,
      is_recurring: Boolean(line.is_recurring),
      decision_note: '',
      carried_from_line_id: line.carried_from_line_id,
      procurement_category_id: Number(line.procurement_category_id) || 10,
      category_name: catLabel,
      purchase_method_id: line.purchase_method_id ? Number(line.purchase_method_id) : null,
      purchase_method_name: methodLabel,
      tenant_id: 1,
      entity_id: Number(line.entity_id) || Number(form.value.entity_id) || 2,
      organization_unit_id: line.organization_unit_id || null,
      organization_unit_name: orgLabel,
      product_id: line.product_id || null,
      product_name: prodLabel,
      measurement_id: line.measurement_id || 'PCS',
      location_id: line.location_id || null,
      location_name: locLabel,
      budget_line_id: line.budget_line_id || null,
      cost_center_dimension_id: line.cost_center_dimension_id || null,
      plan_line_status_lookup_value_id: 'pending',
      user_id: 10,
      state: 'active'
    });
    nextLineId += 1;
  });
};

const handleSave = (targetStatus: PlanStatus = 'submitted') => {
  showTopActionsMenu.value = false;
  if (!validateForm()) return;

  const unitLabel =
    unitOptions.find((u) => u.value === form.value.procurement_unit_id)?.label.split(' (')[0] ||
    'Whole Entity (Shared)';
  const entityLabel =
    entityOptions.find((e) => e.value === form.value.entity_id)?.label || 'Sheraton Ethiopia';
  const budgetLabel =
    budgetOptions.find((b) => b.value === form.value.budget_id)?.label || 'No Linked Budget';
  const today = new Date().toISOString().split('T')[0];

  if (isReviseMode.value && revisingId.value) {
    const plan = procurementPlansStore.value.find((p) => p.id === revisingId.value);
    if (plan) {
      plan.plan_status_lookup_value_id = 'revised';
      plan.notes = form.value.notes;

      const currentVer = getCurrentPlanVersion(plan.id);
      if (currentVer) {
        currentVer.superseded_at = today;
      }
      const nextVerNum = currentVer ? currentVer.version_number + 1 : 0;
      const nextVerId = Math.max(0, ...procurementPlanVersionsStore.value.map((v) => v.id)) + 1;

      procurementPlanVersionsStore.value.push({
        id: nextVerId,
        uuid: `ppv-${nextVerId}-rev`,
        procurement_plan_id: plan.id,
        version_number: nextVerNum,
        reason: form.value.revision_reason,
        revised_at: today,
        superseded_at: null,
        document_id: `DOC-PP-${plan.id}-V${nextVerNum}`,
        revised_by: 'Marta Tadesse',
        plan_version_status_lookup_value_id: 'submitted',
        user_id: 10,
        state: 'active'
      });

      persistLinesForVersion(nextVerId);
      isSaved.value = true;
      toast.success(`Revision v${nextVerNum} raised for ${plan.plan_number}.`);
      router.push(`/procurement/plans/${plan.id}`);
      return;
    }
  } else if (editingId.value) {
    const plan = procurementPlansStore.value.find((p) => p.id === editingId.value);
    if (plan) {
      plan.plan_number = form.value.plan_number;
      plan.name = form.value.name;
      plan.period_type_lookup_value_id = form.value.period_type_lookup_value_id;
      plan.fiscal_year_id = form.value.fiscal_year_id;
      plan.period_start = form.value.period_start;
      plan.period_end = form.value.period_end;
      plan.procurement_unit_id = form.value.procurement_unit_id
        ? Number(form.value.procurement_unit_id)
        : null;
      plan.procurement_unit_name = unitLabel;
      plan.entity_id = Number(form.value.entity_id) || 2;
      plan.entity_name = entityLabel;
      plan.currency_id = form.value.currency_id;
      plan.budget_id = form.value.budget_id || null;
      plan.budget_name = budgetLabel;
      plan.plan_status_lookup_value_id = targetStatus;
      plan.notes = form.value.notes;

      const currentVer = getCurrentPlanVersion(plan.id);
      if (currentVer) {
        persistLinesForVersion(currentVer.id);
      }
      isSaved.value = true;
      toast.success(
        targetStatus === 'draft'
          ? `Procurement plan ${plan.plan_number} saved as draft.`
          : `Procurement plan ${plan.plan_number} submitted for approval.`
      );
      router.push(`/procurement/plans/${plan.id}`);
      return;
    }
  } else {
    const nextPlanId = Math.max(0, ...procurementPlansStore.value.map((p) => p.id)) + 1;
    procurementPlansStore.value.unshift({
      id: nextPlanId,
      uuid: `pp-${nextPlanId}-created`,
      plan_number: form.value.plan_number,
      name: form.value.name,
      period_start: form.value.period_start,
      period_end: form.value.period_end,
      approved_at: null,
      notes: form.value.notes,
      period_type_lookup_value_id: form.value.period_type_lookup_value_id,
      procurement_unit_id: form.value.procurement_unit_id
        ? Number(form.value.procurement_unit_id)
        : null,
      procurement_unit_name: unitLabel,
      tenant_id: 1,
      entity_id: Number(form.value.entity_id) || 2,
      entity_name: entityLabel,
      currency_id: form.value.currency_id,
      fiscal_year_id: form.value.fiscal_year_id,
      budget_id: form.value.budget_id || null,
      budget_name: budgetLabel,
      document_id: `DOC-PP-${nextPlanId}`,
      plan_status_lookup_value_id: targetStatus,
      user_id: 10,
      state: 'active'
    });

    const nextVerId = Math.max(0, ...procurementPlanVersionsStore.value.map((v) => v.id)) + 1;
    procurementPlanVersionsStore.value.push({
      id: nextVerId,
      uuid: `ppv-${nextVerId}-v0`,
      procurement_plan_id: nextPlanId,
      version_number: 0,
      reason: null,
      revised_at: today,
      superseded_at: null,
      document_id: `DOC-PP-${nextPlanId}-V0`,
      revised_by: 'Marta Tadesse',
      plan_version_status_lookup_value_id: 'submitted',
      user_id: 10,
      state: 'active'
    });

    persistLinesForVersion(nextVerId);
    isSaved.value = true;
    toast.success(
      targetStatus === 'draft'
        ? `Procurement plan ${form.value.plan_number} saved as draft.`
        : `Procurement plan ${form.value.plan_number} submitted for approval.`
    );
    router.push(`/procurement/plans/${nextPlanId}`);
    return;
  }

  router.push('/procurement/plans');
};
</script>

<template>
  <div class="plan-create-page">
    <!-- Top Bar directly on transparent canvas -->
    <div class="create-top-bar">
      <AppBreadcrumb :items="breadcrumbItems" :noMargin="true">
        <template #badge>
          <SaveStateBadge :isSaved="isSaved" :isDraft="false" />
        </template>
      </AppBreadcrumb>

      <div class="top-bar-actions">
        <div class="top-more-wrapper" @click.stop>
          <AppButton
            variant="secondary-gray"
            size="sm"
            title="More actions"
            @click="showTopActionsMenu = !showTopActionsMenu"
          >
            <MoreVertical :size="16" />
          </AppButton>
          <div v-if="showTopActionsMenu" class="top-more-dropdown">
            <button type="button" class="top-dropdown-item" @click="handleSave('draft')">
              <Save :size="14" class="dropdown-icon" />
              <span>Save as Draft</span>
            </button>
          </div>
        </div>

        <AppButton variant="secondary-gray" size="sm" @click="clearForm">
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>
        <AppButton variant="primary" size="sm" @click="handleSave('submitted')">
          Submit
        </AppButton>
      </div>
    </div>

    <!-- Primary Pill Capsule Tabs -->
    <div class="tabs-header-wrap">
      <BaseTabs v-model="activeTab" :tabs="tabs" />
    </div>

    <!-- TAB 1: PLAN DETAILS -->
    <div v-show="activeTab === 'details'" class="tab-panel-stack">
      <!-- Revision Reason Card (Only when raising a new ProcurementPlanVersion) -->
      <div v-if="isReviseMode" class="clean-card form-card-body">
        <div class="form-grid-3">
          <FormInput
            v-model="form.revision_reason"
            label="Revision Reason"
            :error="fieldErrors.revision_reason"
            required
          />
        </div>
      </div>

      <!-- Master Plan Parameters Card -->
      <div class="clean-card form-card-body">
        <div class="form-grid-3">
          <FormInput
            v-model="form.name"
            label="Plan Name"
            :error="fieldErrors.name"
            required
          />
          <FormSelect
            v-model="form.period_type_lookup_value_id"
            label="Period Type"
            :options="planPeriodTypeOptions"
            placeholder="Select Type"
            required
          />
          <FormSelect
            v-model="form.fiscal_year_id"
            label="Fiscal Year"
            :options="fiscalYearOptions"
            placeholder="Select Year"
            required
          />
        </div>

        <div class="card-row-divider"></div>

        <div class="form-grid-3">
          <FormInput
            v-model="form.period_start"
            type="date"
            label="Effective Period Start"
            :error="fieldErrors.period_start"
            required
          />
          <FormInput
            v-model="form.period_end"
            type="date"
            label="Effective Period End"
            :error="fieldErrors.period_end"
            required
          />
          <FormSelect
            v-model="form.entity_id"
            label="Owning Entity"
            :options="entityOptions"
            placeholder="Select Entity"
            required
          />
        </div>

        <div class="card-row-divider"></div>

        <div class="form-grid-3">
          <FormSelect
            v-model="form.procurement_unit_id"
            label="Owning Procurement Unit"
            :options="unitOptions"
            placeholder="Select Unit"
          />
          <FormSelect
            v-model="form.currency_id"
            label="Currency"
            :options="currencyOptions"
            placeholder="Select Currency"
            required
          />
          <FormSelect
            v-model="form.budget_id"
            label="Accounting Budget"
            :options="budgetOptions"
            placeholder="Select Budget"
          />
        </div>
      </div>

      <!-- Dedicated Collapsible Notes Card (4px icon gap + header bottom border) -->
      <div class="clean-card accordion-card">
        <div
          class="card-accordion-header"
          :class="{ 'is-collapsed': !isNotesOpen }"
          @click="isNotesOpen = !isNotesOpen"
        >
          <span class="card-accordion-title">Planning Notes & Guidelines</span>
          <ChevronDown v-if="isNotesOpen" :size="16" class="header-chevron" />
          <ChevronRight v-else :size="16" class="header-chevron" />
        </div>

        <div v-show="isNotesOpen" class="card-accordion-body">
          <FormRichText
            v-model="form.notes"
            placeholder="Record planning assumptions, budget constraints, or notes for planners and approvers..."
            :max-length="5000"
          />
        </div>
      </div>
    </div>

    <!-- TAB 2: PLANNED ITEMS (ProcurementPlanVersionLine) -->
    <div v-show="activeTab === 'lines'" class="tab-panel-stack">
      <div class="clean-card subtable-card-container">
        <div class="subtable-summary-bar">
          <div>
            <h3 class="subtable-heading">Planned Items ({{ planLines.length }})</h3>
            <p class="subtable-subheading">
              Click the expand icon on any row to configure measurement unit, required dates, department, location, and budget line.
            </p>
          </div>
          <div class="total-badge-box">
            <span class="total-label">Estimated Total:</span>
            <span class="total-value">{{ formatCurrencyETB(totalPlannedAmount, form.currency_id) }}</span>
          </div>
        </div>

        <DynamicSubTable
          v-model="planLines"
          :columns="lineColumns"
          entityName="Planned Item"
          entityNamePlural="Planned Items"
          :defaultInitialRow="true"
          :newRowFactory="createDefaultLine"
        >
          <template #expand-modal="{ row }">
            <div class="modal-expand-grid">
              <div class="form-grid-2">
                <FormSelect
                  v-model="row.product_id"
                  label="Item / Product"
                  :options="productOptions"
                  placeholder="Select Product"
                  :searchable="true"
                />
                <FormSelect
                  v-model="row.procurement_category_id"
                  label="Category"
                  :options="categoryOptions"
                  placeholder="Select Category"
                  :searchable="true"
                  required
                />
              </div>

              <div class="form-grid-2">
                <FormInput
                  v-model.number="row.planned_quantity"
                  type="number"
                  label="Planned Qty"
                  required
                />
                <FormInput
                  v-model.number="row.estimated_unit_price"
                  type="number"
                  label="Est. Unit Price"
                  required
                />
              </div>

              <div class="form-grid-2">
                <FormSelect
                  v-model="row.entity_id"
                  label="Entity Planned For"
                  :options="entityOptions"
                  placeholder="Select Entity"
                  required
                />
                <FormSelect
                  v-model="row.organization_unit_id"
                  label="Department Planned For"
                  :options="organizationUnitOptions"
                  placeholder="Select Department"
                />
              </div>

              <div class="form-grid-2">
                <FormSelect
                  v-model="row.measurement_id"
                  label="Measurement Unit"
                  :options="measurementOptions"
                  placeholder="Select Unit"
                />
                <FormSelect
                  v-model="row.purchase_method_id"
                  label="Planned Purchase Method"
                  :options="purchaseMethodOptions"
                  placeholder="Select Method"
                />
              </div>

              <div class="form-grid-2">
                <FormInput
                  v-model="row.required_from"
                  type="date"
                  label="Required From"
                />
                <FormInput
                  v-model="row.required_to"
                  type="date"
                  label="Required To"
                />
              </div>

              <div class="form-grid-2">
                <FormSelect
                  v-model="row.location_id"
                  label="Delivery Location"
                  :options="locationOptions"
                  placeholder="Select Location"
                />
                <FormSelect
                  v-model="row.budget_line_id"
                  label="Budget Line"
                  :options="budgetLineOptions"
                  placeholder="Select Budget Line"
                />
              </div>

              <div class="form-grid-2">
                <FormSelect
                  v-model="row.cost_center_dimension_id"
                  label="Cost Center"
                  :options="costCenterOptions"
                  placeholder="Select Cost Center"
                />
              </div>

              <div class="modal-checkbox-grid">
                <FormCheckbox
                  v-model="row.is_recurring"
                  label="Recurring Purchase"
                  description="Item is bought repeatedly throughout the plan coverage period."
                />
              </div>

              <FormTextarea
                v-model="row.description"
                label="Item Description"
                placeholder="Specification or free-text item description..."
                hint="Required when no catalogued product is selected."
                :rows="3"
                :required="!row.product_id"
              />
            </div>
          </template>
        </DynamicSubTable>
      </div>
    </div>
  </div>
</template>

<style scoped>
.plan-create-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.create-top-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  background: transparent;
  border: none;
  box-shadow: none;
  padding: 0;
}

.top-bar-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.top-more-wrapper {
  position: relative;
  display: inline-flex;
}

.top-more-dropdown {
  position: absolute;
  right: 0;
  top: calc(100% + 6px);
  z-index: 60;
  min-width: 170px;
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 10px;
  box-shadow: 0 8px 24px rgba(10, 13, 18, 0.12);
  padding: 6px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.top-dropdown-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 10px;
  border: none;
  background: transparent;
  border-radius: 6px;
  font-size: 13px;
  color: #404040;
  cursor: pointer;
  text-align: left;
}

.top-dropdown-item:hover {
  background-color: #fafafa;
}

.dropdown-icon {
  color: #737373;
  flex-shrink: 0;
}

.tabs-header-wrap {
  display: flex;
  align-items: center;
}

.tab-panel-stack {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.clean-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
}

.form-card-body {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 20px;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 20px;
}

.card-row-divider {
  height: 1px;
  background-color: #e5e5e5;
  width: 100%;
}

/* Collapsible Accordion Card */
.accordion-card {
  overflow: hidden;
}

.card-accordion-header {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 4px;
  padding: 16px 24px;
  cursor: pointer;
  user-select: none;
  background-color: #ffffff;
  border-bottom: 1px solid #e5e5e5;
  transition: background-color 0.15s ease;
}

.card-accordion-header.is-collapsed {
  border-bottom: none;
}

.card-accordion-header:hover {
  background-color: #fafafa;
}

.card-accordion-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.header-chevron {
  color: #737373;
  flex-shrink: 0;
}

.card-accordion-body {
  padding: 20px 24px 24px;
}

/* DynamicSubTable Container (24px inset padding) */
.subtable-card-container {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.subtable-summary-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}

.subtable-heading {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #404040;
}

.subtable-subheading {
  margin: 4px 0 0;
  font-size: 13px;
  color: #737373;
}

.total-badge-box {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  background-color: #fafafa;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
}

.total-label {
  font-size: 12.5px;
  color: #737373;
}

.total-value {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  font-variant-numeric: tabular-nums;
}

.modal-expand-grid {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.modal-checkbox-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 20px 16px;
  padding-top: 12px;
  border-top: 1px solid #f0f0f0;
}

@media (max-width: 960px) {
  .form-grid-2,
  .form-grid-3,
  .modal-checkbox-grid {
    grid-template-columns: 1fr;
  }
}
</style>
