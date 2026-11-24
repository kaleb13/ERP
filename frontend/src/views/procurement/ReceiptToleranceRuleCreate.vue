<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { X, ChevronDown, ChevronRight } from 'lucide-vue-next';
import { useToast } from '../../composables/useToast';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import {
  receiptToleranceRulesStore,
  type ReceiptToleranceRuleRecord,
  type ReceiptToleranceAction,
  actionOptions,
  categoryScopeOptions,
  supplierScopeOptions,
  productScopeOptions,
  entityOptions,
  getEntityName
} from './receiptToleranceRuleData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

const editingId = computed(() => (route.params.id ? Number(route.params.id) : null));
// On initial new record creation, isSaved is false so badge displays "Not Saved"
const isSaved = ref(false);
const isScopeOpen = ref(false);

const form = ref<{
  entity_id: string;
  procurement_category_id: string;
  supplier_id: string;
  product_id: string;
  over_receipt_percent: number;
  over_action_lookup_value_id: ReceiptToleranceAction;
  under_receipt_percent: number;
  under_action_lookup_value_id: ReceiptToleranceAction;
  early_delivery_days: number;
  late_delivery_days: number;
  priority: number;
  effective_from: string;
  effective_to: string;
}>({
  entity_id: '2',
  procurement_category_id: '',
  supplier_id: '',
  product_id: '',
  over_receipt_percent: 0,
  over_action_lookup_value_id: 'block',
  under_receipt_percent: 0,
  under_action_lookup_value_id: 'keep_open',
  early_delivery_days: 0,
  late_delivery_days: 0,
  priority: 10,
  effective_from: new Date().toISOString().split('T')[0],
  effective_to: ''
});

const fieldErrors = ref<Record<string, string>>({});

onMounted(() => {
  if (editingId.value) {
    const existing = receiptToleranceRulesStore.value.find((r) => r.id === editingId.value);
    if (existing) {
      form.value = {
        entity_id: String(existing.entity_id || 2),
        procurement_category_id: existing.procurement_category_id ? String(existing.procurement_category_id) : '',
        supplier_id: existing.supplier_id ? String(existing.supplier_id) : '',
        product_id: existing.product_id ? String(existing.product_id) : '',
        priority: existing.priority,
        over_receipt_percent: existing.over_receipt_percent,
        under_receipt_percent: existing.under_receipt_percent,
        early_delivery_days: existing.early_delivery_days,
        late_delivery_days: existing.late_delivery_days,
        over_action_lookup_value_id: existing.over_action_lookup_value_id,
        under_action_lookup_value_id: existing.under_action_lookup_value_id,
        effective_from: existing.effective_from,
        effective_to: existing.effective_to || ''
      };
      if (existing.procurement_category_id || existing.supplier_id || existing.product_id) {
        isScopeOpen.value = true;
      }
      isSaved.value = true;
    } else {
      toast.error('Tolerance rule not found.');
      router.push('/procurement/tolerances?tab=receipt');
    }
  }
});

const breadcrumbItems = computed<BreadcrumbItem[]>(() => {
  const base: BreadcrumbItem = {
    label: 'Receipt & Matching Rule',
    onClick: () => router.push('/procurement/tolerances?tab=receipt')
  };
  if (editingId.value) {
    return [base, { label: `Edit Rule #${editingId.value}` }];
  }
  return [base, { label: 'Create Receipt Tolerance' }];
});

const clearForm = () => {
  form.value = {
    entity_id: '2',
    procurement_category_id: '',
    supplier_id: '',
    product_id: '',
    over_receipt_percent: 0,
    over_action_lookup_value_id: 'block',
    under_receipt_percent: 0,
    under_action_lookup_value_id: 'keep_open',
    early_delivery_days: 0,
    late_delivery_days: 0,
    priority: 10,
    effective_from: new Date().toISOString().split('T')[0],
    effective_to: ''
  };
  fieldErrors.value = {};
  isSaved.value = false;
  toast.info('Form cleared.');
};

const validate = (): boolean => {
  const errors: Record<string, string> = {};
  const missing: string[] = [];

  if (form.value.over_receipt_percent < 0) {
    errors.over_receipt_percent = 'Over-receipt % cannot be negative.';
    missing.push('Valid Over-Receipt %');
  }
  if (form.value.under_receipt_percent < 0) {
    errors.under_receipt_percent = 'Under-receipt % cannot be negative.';
    missing.push('Valid Under-Receipt %');
  }
  if (form.value.early_delivery_days < 0) {
    errors.early_delivery_days = 'Early delivery days cannot be negative.';
    missing.push('Valid Early Days');
  }
  if (form.value.late_delivery_days < 0) {
    errors.late_delivery_days = 'Late delivery days cannot be negative.';
    missing.push('Valid Late Days');
  }
  if (!form.value.priority || form.value.priority < 1) {
    errors.priority = 'Priority must be at least 1.';
    missing.push('Priority');
  }
  if (!form.value.effective_from) {
    errors.effective_from = 'Effective From date is required.';
    missing.push('Effective From Date');
  }
  if (form.value.effective_to && form.value.effective_to < form.value.effective_from) {
    errors.effective_to = 'Effective To cannot precede Effective From.';
    missing.push('Valid Date Window');
  }

  fieldErrors.value = errors;
  if (missing.length > 0) {
    toast.error('Please review the form errors', `Missing/Invalid: ${missing.join(', ')}.`);
    return false;
  }
  return true;
};

const handleSave = () => {
  if (!validate()) return;

  const catOption = categoryScopeOptions.find((c) => c.value === form.value.procurement_category_id);
  const supOption = supplierScopeOptions.find((s) => s.value === form.value.supplier_id);
  const prodOption = productScopeOptions.find((p) => p.value === form.value.product_id);

  const categoryId = form.value.procurement_category_id ? Number(form.value.procurement_category_id) : null;
  const supplierId = form.value.supplier_id ? Number(form.value.supplier_id) : null;
  const productId = form.value.product_id ? Number(form.value.product_id) : null;
  const entityId = Number(form.value.entity_id) || 2;

  if (editingId.value) {
    const idx = receiptToleranceRulesStore.value.findIndex((r) => r.id === editingId.value);
    if (idx !== -1) {
      receiptToleranceRulesStore.value[idx] = {
        ...receiptToleranceRulesStore.value[idx],
        entity_id: entityId,
        entity_name: getEntityName(entityId),
        procurement_category_id: categoryId,
        supplier_id: supplierId,
        product_id: productId,
        priority: Number(form.value.priority),
        over_receipt_percent: Number(form.value.over_receipt_percent),
        under_receipt_percent: Number(form.value.under_receipt_percent),
        early_delivery_days: Number(form.value.early_delivery_days),
        late_delivery_days: Number(form.value.late_delivery_days),
        over_action_lookup_value_id: form.value.over_action_lookup_value_id,
        under_action_lookup_value_id: form.value.under_action_lookup_value_id,
        effective_from: form.value.effective_from,
        effective_to: form.value.effective_to || null,
        category_name: categoryId ? catOption?.label : undefined,
        supplier_name: supplierId ? supOption?.label : undefined,
        product_name: productId ? prodOption?.label : undefined
      };
    }
    isSaved.value = true;
    toast.success('Receipt tolerance rule updated.');
  } else {
    const nextId = Math.max(0, ...receiptToleranceRulesStore.value.map((r) => r.id)) + 1;
    receiptToleranceRulesStore.value.unshift({
      id: nextId,
      uuid: `8a1f4b23-7e21-4f12-a1b9-d3e74c8100${nextId.toString().padStart(2, '0')}`,
      entity_id: entityId,
      entity_name: getEntityName(entityId),
      procurement_category_id: categoryId,
      supplier_id: supplierId,
      product_id: productId,
      priority: Number(form.value.priority),
      over_receipt_percent: Number(form.value.over_receipt_percent),
      under_receipt_percent: Number(form.value.under_receipt_percent),
      early_delivery_days: Number(form.value.early_delivery_days),
      late_delivery_days: Number(form.value.late_delivery_days),
      over_action_lookup_value_id: form.value.over_action_lookup_value_id,
      under_action_lookup_value_id: form.value.under_action_lookup_value_id,
      effective_from: form.value.effective_from,
      effective_to: form.value.effective_to || null,
      tenant_id: 1,
      user_id: 10,
      state: 'active', // Standard: Created records default to active
      category_name: categoryId ? catOption?.label : undefined,
      supplier_name: supplierId ? supOption?.label : undefined,
      product_name: productId ? prodOption?.label : undefined
    });
    isSaved.value = true;
    toast.success('Receipt tolerance rule created.');
  }

  router.push('/procurement/tolerances?tab=receipt');
};
</script>

<template>
  <div class="tolerance-create-page">
    <!-- ═══ TOP BAR (Transparent Canvas, Sealed SaveStateBadge, Zero-Icon Save) ═══ -->
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
        <!-- Save button: plain text, zero icons per standard -->
        <AppButton variant="primary" size="sm" @click="handleSave">
          Save
        </AppButton>
      </div>
    </div>

    <!-- ═══ MASTER CONFIGURATION CARD (Divider Lines Only — Zero Section Titles/Descriptions) ═══ -->
    <div class="clean-card form-card-body">
      <!-- Group 1: Quantity Over-Receipt & Under-Receipt Limits and Actions -->
      <div class="form-grid-2">
        <FormInput
          v-model.number="form.over_receipt_percent"
          type="number"
          label="Over-Receipt Allowed (%)"
          placeholder="0.00"
          :error="fieldErrors.over_receipt_percent"
          required
        />

        <FormSelect
          v-model="form.over_action_lookup_value_id"
          label="Over-Receipt Action"
          :options="actionOptions"
          placeholder="Select Action"
          required
        />
      </div>

      <div class="form-grid-2">
        <FormInput
          v-model.number="form.under_receipt_percent"
          type="number"
          label="Under-Receipt Shortfall (%)"
          placeholder="0.00"
          :error="fieldErrors.under_receipt_percent"
          required
        />

        <FormSelect
          v-model="form.under_action_lookup_value_id"
          label="Under-Receipt Action"
          :options="actionOptions"
          placeholder="Select Action"
          required
        />
      </div>

      <div class="card-row-divider"></div>

      <!-- Group 2: Schedule Grace Windows & Resolution Precedence -->
      <div class="form-grid-3">
        <FormInput
          v-model.number="form.early_delivery_days"
          type="number"
          label="Early Delivery Allowed (Days)"
          placeholder="0"
          :error="fieldErrors.early_delivery_days"
          required
        />

        <FormInput
          v-model.number="form.late_delivery_days"
          type="number"
          label="Late Delivery Grace (Days)"
          placeholder="0"
          :error="fieldErrors.late_delivery_days"
          required
        />

        <FormInput
          v-model.number="form.priority"
          type="number"
          label="Resolution Priority"
          placeholder="10"
          :error="fieldErrors.priority"
          helper-text="Lowest integer wins on a tie (e.g. 1 overrides 10)"
          required
        />
      </div>

      <div class="card-row-divider"></div>

      <!-- Group 3: Owning Entity & Validity Window -->
      <div class="form-grid-3">
        <FormSelect
          v-model="form.entity_id"
          label="Owning Legal Entity"
          :options="entityOptions"
          placeholder="Select Entity"
          required
        />

        <FormInput
          v-model="form.effective_from"
          type="date"
          label="Effective From"
          :error="fieldErrors.effective_from"
          required
        />

        <FormInput
          v-model="form.effective_to"
          type="date"
          label="Effective To"
          placeholder="Indefinite"
          :error="fieldErrors.effective_to"
          helper-text="Leave blank if in force indefinitely"
        />
      </div>
    </div>

    <!-- ═══ DEDICATED COLLAPSIBLE CARD: OPTIONAL SCOPE OVERRIDES (Nullable FKs) ═══ -->
    <div class="clean-card accordion-card">
      <div
        class="card-accordion-header"
        :class="{ 'is-collapsed': !isScopeOpen }"
        @click="isScopeOpen = !isScopeOpen"
      >
        <span class="card-accordion-title">Scope Overrides (Category, Supplier, Product)</span>
        <ChevronDown v-if="isScopeOpen" :size="16" class="header-chevron" />
        <ChevronRight v-else :size="16" class="header-chevron" />
      </div>

      <div v-show="isScopeOpen" class="card-accordion-body">
        <div class="form-grid-3">
          <FormSelect
            v-model="form.procurement_category_id"
            label="Procurement Category Scope"
            :options="categoryScopeOptions"
            placeholder="Select Category"
          />

          <FormSelect
            v-model="form.supplier_id"
            label="Supplier Scope"
            :options="supplierScopeOptions"
            placeholder="Select Supplier"
          />

          <FormSelect
            v-model="form.product_id"
            label="Product / Item Scope"
            :options="productScopeOptions"
            placeholder="Select Product"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.tolerance-create-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Top Bar directly on transparent canvas */
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

/* White Card */
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

.card-row-divider {
  height: 1px;
  background-color: #e5e5e5;
  margin: 4px 0;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
  align-items: start;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
  align-items: start;
}

/* Dedicated Collapsible Card */
.clean-card.accordion-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  overflow: hidden;
}

.card-accordion-header {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 4px;
  padding: 16px 24px;
  font-size: 14px;
  font-weight: 600;
  color: #404040;
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
  background-color: #ffffff;
}

@media (max-width: 960px) {
  .form-grid-3,
  .form-grid-2 {
    grid-template-columns: 1fr;
  }
}
</style>
