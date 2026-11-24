<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { X } from 'lucide-vue-next';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import DynamicSubTable, { type DynamicTableColumn } from '../../components/DynamicSubTable.vue';
import { useToast } from '../../composables/useToast';
import { formatDisplayDateRange } from '../../utils/dateFormat';

import {
  procurementPlansStore,
  procurementPlanLinesStore,
  getCurrentPlanVersion,
  getVersionLines,
  getPlanPeriodTypeLabel,
  formatCurrencyETB,
  productOptions,
  measurementOptions,
  categoryOptions,
  purchaseMethodOptions,
  entityOptions,
  organizationUnitOptions,
  locationOptions,
  budgetLineOptions,
  costCenterOptions
} from './procurementPlanData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

const isSaved = ref(false);

const breadcrumbItems: BreadcrumbItem[] = [
  { label: 'Procurement Plans', to: '/procurement/plans?tab=lines' },
  { label: 'Add Planned Items' }
];

const selectedPlanId = ref<string>(route.query.planId ? String(route.query.planId) : '');
const planError = ref<string | undefined>(undefined);

const planOptions = computed(() =>
  procurementPlansStore.value.map((p) => {
    const ver = getCurrentPlanVersion(p.id);
    const verLabel = ver ? `v${ver.version_number}` : 'v0';
    return {
      value: String(p.id),
      label: `${p.plan_number} — ${p.name} (${verLabel})`
    };
  })
);

const selectedPlan = computed(() => {
  if (!selectedPlanId.value) return null;
  return procurementPlansStore.value.find((p) => String(p.id) === selectedPlanId.value) || null;
});

const selectedPlanVersion = computed(() =>
  selectedPlan.value ? getCurrentPlanVersion(selectedPlan.value.id) || null : null
);

interface PlannedItemDraft {
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

const createDefaultItemRow = (): PlannedItemDraft => ({
  product_id: 'PROD-101',
  description: 'Fresh Roma Tomato — Grade A kitchen supply',
  procurement_category_id: '11',
  planned_quantity: 100,
  estimated_unit_price: 62,
  measurement_id: 'KG',
  purchase_method_id: '2',
  required_from: selectedPlan.value?.period_start || '2026-07-01',
  required_to: selectedPlan.value?.period_end || '2027-06-30',
  is_recurring: false,
  entity_id: selectedPlan.value ? String(selectedPlan.value.entity_id) : '2',
  organization_unit_id: '12',
  location_id: 'LOC-MAIN',
  budget_line_id: 'BL-5100',
  cost_center_dimension_id: 'CC-FB-01'
});

const itemRows = ref<PlannedItemDraft[]>([createDefaultItemRow()]);

const itemColumns: DynamicTableColumn[] = [
  {
    key: 'product_id',
    label: 'Item / Product',
    type: 'select',
    options: productOptions,
    placeholder: 'Select Product',
    minWidth: '210px',
    tooltipTitle: 'Catalogued Product',
    tooltipDesc: 'Select a product from the catalog or choose Free-Text and enter a description.'
  },
  {
    key: 'description',
    label: 'Description',
    type: 'text',
    placeholder: 'Item specification...',
    minWidth: '220px',
    tooltipTitle: 'Line Description',
    tooltipDesc: 'Required when no catalogued product is selected.'
  },
  {
    key: 'procurement_category_id',
    label: 'Category',
    type: 'select',
    options: categoryOptions,
    placeholder: 'Select Category',
    minWidth: '180px'
  },
  {
    key: 'planned_quantity',
    label: 'Planned Qty',
    type: 'number',
    align: 'right',
    minWidth: '120px'
  },
  {
    key: 'estimated_unit_price',
    label: 'Est. Unit Price',
    type: 'number',
    align: 'right',
    minWidth: '140px'
  }
];

const totalBatchEstimate = computed(() =>
  itemRows.value.reduce(
    (sum, r) => sum + (Number(r.planned_quantity) || 0) * (Number(r.estimated_unit_price) || 0),
    0
  )
);

watch(selectedPlanId, () => {
  planError.value = undefined;
  if (selectedPlan.value) {
    itemRows.value.forEach((r) => {
      r.required_from = selectedPlan.value!.period_start;
      r.required_to = selectedPlan.value!.period_end;
      r.entity_id = String(selectedPlan.value!.entity_id);
    });
  }
});

watch(
  [selectedPlanId, itemRows],
  () => {
    isSaved.value = false;
  },
  { deep: true }
);

const clearForm = () => {
  selectedPlanId.value = '';
  planError.value = undefined;
  itemRows.value = [createDefaultItemRow()];
  isSaved.value = false;
  toast.info('Form cleared.');
};

const handleSave = () => {
  planError.value = undefined;
  if (!selectedPlanId.value || !selectedPlan.value || !selectedPlanVersion.value) {
    planError.value = 'Please select a target procurement plan.';
    toast.error('Please select a target procurement plan.');
    return;
  }
  if (itemRows.value.length === 0) {
    toast.error('Please add at least one planned item row.');
    return;
  }

  const existingVersionLines = getVersionLines(selectedPlanVersion.value.id);
  let nextLineNumber =
    existingVersionLines.length > 0
      ? Math.max(...existingVersionLines.map((l) => l.line_number)) + 1
      : 1;
  let nextId = Math.max(0, ...procurementPlanLinesStore.value.map((l) => l.id)) + 1;

  itemRows.value.forEach((row) => {
    const qty = Number(row.planned_quantity) || 0;
    const price = Number(row.estimated_unit_price) || 0;
    const prodLabel =
      productOptions.find((p) => p.value === row.product_id)?.label.split(' (')[0] ||
      'Free-Text Item';
    const catLabel =
      categoryOptions
        .find((c) => c.value === row.procurement_category_id)
        ?.label.split(' (')[0] || 'General';
    const methodLabel =
      purchaseMethodOptions
        .find((m) => m.value === row.purchase_method_id)
        ?.label.split(' (')[0] || 'Decide Later';
    const orgLabel =
      organizationUnitOptions.find((o) => o.value === row.organization_unit_id)?.label ||
      'Entity-Wide';
    const locLabel =
      locationOptions.find((loc) => loc.value === row.location_id)?.label ||
      'Default Receiving Store';

    procurementPlanLinesStore.value.unshift({
      id: nextId,
      uuid: `ppl-${nextId}-${Date.now()}`,
      procurement_plan_version_id: selectedPlanVersion.value!.id,
      line_number: nextLineNumber,
      description: row.description || prodLabel,
      planned_quantity: qty,
      estimated_unit_price: price,
      estimated_amount: qty * price,
      requisitioned_quantity: 0,
      ordered_quantity: 0,
      received_quantity: 0,
      actual_amount: 0,
      required_from: row.required_from || selectedPlan.value!.period_start,
      required_to: row.required_to || selectedPlan.value!.period_end,
      is_recurring: Boolean(row.is_recurring),
      decision_note: '',
      carried_from_line_id: null,
      procurement_category_id: Number(row.procurement_category_id) || 10,
      category_name: catLabel,
      purchase_method_id: row.purchase_method_id ? Number(row.purchase_method_id) : null,
      purchase_method_name: methodLabel,
      tenant_id: 1,
      entity_id: Number(row.entity_id) || selectedPlan.value!.entity_id,
      organization_unit_id: row.organization_unit_id || null,
      organization_unit_name: orgLabel,
      product_id: row.product_id || null,
      product_name: prodLabel,
      measurement_id: row.measurement_id || 'PCS',
      location_id: row.location_id || null,
      location_name: locLabel,
      budget_line_id: row.budget_line_id || null,
      cost_center_dimension_id: row.cost_center_dimension_id || null,
      plan_line_status_lookup_value_id: 'pending',
      user_id: 10,
      state: 'active'
    });

    nextId += 1;
    nextLineNumber += 1;
  });

  isSaved.value = true;
  toast.success(
    `${itemRows.value.length} planned item(s) added to ${selectedPlan.value.plan_number} (v${selectedPlanVersion.value.version_number}).`
  );
  router.push('/procurement/plans?tab=lines');
};
</script>

<template>
  <div class="plan-item-create-page">
    <!-- Top Bar directly on transparent canvas -->
    <div class="create-top-bar">
      <AppBreadcrumb :items="breadcrumbItems" :noMargin="true">
        <template #badge>
          <SaveStateBadge :isSaved="isSaved" :isDraft="false" />
        </template>
      </AppBreadcrumb>

      <div class="top-bar-actions">
        <AppButton variant="secondary-gray" size="sm" @click="clearForm">
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>
        <AppButton variant="primary" size="sm" @click="handleSave">
          Save
        </AppButton>
      </div>
    </div>

    <!-- CARD 1: TARGET PROCUREMENT PLAN SELECTOR -->
    <div class="clean-card form-card-body">
      <div class="plan-selector-header">
        <div>
          <h3 class="card-section-title">Target Procurement Plan</h3>
          <p class="card-section-subtitle">
            Select the procurement plan and active version to add planned items to.
          </p>
        </div>
        <div class="estimated-total-pill">
          <span class="pill-label">Batch Estimated Total:</span>
          <span class="pill-value">
            {{ formatCurrencyETB(totalBatchEstimate, selectedPlan?.currency_id || 'ETB') }}
          </span>
        </div>
      </div>

      <div class="form-grid-3">
        <FormSelect
          v-model="selectedPlanId"
          label="Procurement Plan"
          :options="planOptions"
          placeholder="Select Plan"
          :error="planError"
          :searchable="true"
          required
        />
      </div>

      <div v-if="selectedPlan" class="plan-context-strip">
        <div class="context-item">
          <span class="context-label">Active Version</span>
          <span class="context-val">
            v{{ selectedPlanVersion?.version_number ?? 0 }} ({{ selectedPlan.plan_status_lookup_value_id }})
          </span>
        </div>
        <div class="context-item">
          <span class="context-label">Period Type</span>
          <span class="context-val">
            {{ getPlanPeriodTypeLabel(selectedPlan.period_type_lookup_value_id) }}
          </span>
        </div>
        <div class="context-item">
          <span class="context-label">Coverage Window</span>
          <span class="context-val">{{ formatDisplayDateRange(selectedPlan.period_start, selectedPlan.period_end) }}</span>
        </div>
        <div class="context-item">
          <span class="context-label">Owning Unit</span>
          <span class="context-val">{{ selectedPlan.procurement_unit_name }}</span>
        </div>
      </div>
    </div>

    <!-- CARD 2: MULTIPLE PLANNED ITEMS VIA DYNAMIC SUB-TABLE -->
    <div class="clean-card subtable-card-container">
      <div class="subtable-summary-bar">
        <div>
          <h3 class="card-section-title">Planned Items ({{ itemRows.length }})</h3>
          <p class="card-section-subtitle">
            Add one or more planned items below. Click the expand icon (↗) on any row to set unit, dates, department, location, and budget line.
          </p>
        </div>
      </div>

      <DynamicSubTable
        v-model="itemRows"
        :columns="itemColumns"
        entityName="Planned Item"
        entityNamePlural="Planned Items"
        :defaultInitialRow="true"
        :newRowFactory="createDefaultItemRow"
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
              placeholder="Enter item specification or scope notes (required when no catalogued product is selected)..."
              :rows="3"
            />
          </div>
        </template>
      </DynamicSubTable>
    </div>
  </div>
</template>

<style scoped>
.plan-item-create-page {
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

.plan-selector-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}

.card-section-title {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.card-section-subtitle {
  margin: 4px 0 0;
  font-size: 13px;
  color: #737373;
}

.estimated-total-pill {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  background-color: #fafafa;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
}

.pill-label {
  font-size: 12.5px;
  color: #737373;
}

.pill-value {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  font-variant-numeric: tabular-nums;
}

.plan-context-strip {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
  padding: 12px 16px;
  background-color: #fafafa;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
}

.context-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.context-label {
  font-size: 11.5px;
  color: #737373;
}

.context-val {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 20px;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 20px;
}

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
  .form-grid-3,
  .form-grid-2,
  .plan-context-strip,
  .modal-checkbox-grid {
    grid-template-columns: 1fr;
  }
}
</style>
