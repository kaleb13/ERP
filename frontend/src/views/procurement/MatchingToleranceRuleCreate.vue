<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { X, ChevronDown, ChevronRight } from 'lucide-vue-next';
import { useToast } from '../../composables/useToast';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import {
  matchingToleranceRulesStore,
  type MatchType,
  type MatchExceptionAction,
  matchTypeOptions,
  exceptionActionOptions,
  matchingCategoryOptions,
  matchingSupplierOptions,
  matchingEntityOptions,
  getMatchingEntityName
} from './matchingToleranceRuleData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

const editingId = computed(() => (route.params.id ? Number(route.params.id) : null));
const isSaved = ref(false);
const isScopeOpen = ref(false);

const form = ref<{
  match_type_lookup_value_id: MatchType;
  exception_action_lookup_value_id: MatchExceptionAction;
  price_variance_percent: number;
  price_variance_amount: number;
  quantity_variance_percent: number;
  total_variance_amount: number;
  auto_match_enabled: boolean;
  priority: number;
  entity_id: string;
  effective_from: string;
  effective_to: string;
  procurement_category_id: string;
  supplier_id: string;
}>({
  match_type_lookup_value_id: 'three_way',
  exception_action_lookup_value_id: 'require_approval',
  price_variance_percent: 2,
  price_variance_amount: 500,
  quantity_variance_percent: 0,
  total_variance_amount: 2000,
  auto_match_enabled: true,
  priority: 10,
  entity_id: '2',
  effective_from: new Date().toISOString().split('T')[0],
  effective_to: '',
  procurement_category_id: '',
  supplier_id: ''
});

const fieldErrors = ref<Record<string, string>>({});

watch(
  form,
  () => {
    if (isSaved.value) isSaved.value = false;
  },
  { deep: true }
);

onMounted(() => {
  if (editingId.value) {
    const existing = matchingToleranceRulesStore.value.find((r) => r.id === editingId.value);
    if (existing) {
      form.value = {
        match_type_lookup_value_id: existing.match_type_lookup_value_id,
        exception_action_lookup_value_id: existing.exception_action_lookup_value_id,
        price_variance_percent: existing.price_variance_percent,
        price_variance_amount: existing.price_variance_amount,
        quantity_variance_percent: existing.quantity_variance_percent,
        total_variance_amount: existing.total_variance_amount,
        auto_match_enabled: existing.auto_match_enabled,
        priority: existing.priority,
        entity_id: String(existing.entity_id || 2),
        effective_from: existing.effective_from,
        effective_to: existing.effective_to || '',
        procurement_category_id: existing.procurement_category_id ? String(existing.procurement_category_id) : '',
        supplier_id: existing.supplier_id ? String(existing.supplier_id) : ''
      };
      if (existing.procurement_category_id || existing.supplier_id) {
        isScopeOpen.value = true;
      }
      isSaved.value = true;
    } else {
      toast.error('Matching tolerance rule not found.');
      router.push('/procurement/tolerances?tab=matching');
    }
  }
});

const breadcrumbItems = computed<BreadcrumbItem[]>(() => {
  const base: BreadcrumbItem = {
    label: 'Receipt & Matching Rule',
    to: '/procurement/tolerances?tab=matching'
  };
  if (editingId.value) {
    return [base, { label: `Edit Matching Rule #${editingId.value}` }];
  }
  return [base, { label: 'Create Matching Tolerance' }];
});

const clearForm = () => {
  form.value = {
    match_type_lookup_value_id: 'three_way',
    exception_action_lookup_value_id: 'require_approval',
    price_variance_percent: 2,
    price_variance_amount: 500,
    quantity_variance_percent: 0,
    total_variance_amount: 2000,
    auto_match_enabled: true,
    priority: 10,
    entity_id: '2',
    effective_from: new Date().toISOString().split('T')[0],
    effective_to: '',
    procurement_category_id: '',
    supplier_id: ''
  };
  fieldErrors.value = {};
  isSaved.value = false;
  toast.info('Form cleared.');
};

const validate = (): boolean => {
  const errors: Record<string, string> = {};
  const missing: string[] = [];

  if (form.value.price_variance_percent < 0) {
    errors.price_variance_percent = 'Price variance % cannot be negative.';
    missing.push('Valid Price Variance %');
  }
  if (form.value.price_variance_amount < 0) {
    errors.price_variance_amount = 'Price variance cap cannot be negative.';
    missing.push('Valid Price Cap');
  }
  if (form.value.quantity_variance_percent < 0) {
    errors.quantity_variance_percent = 'Quantity variance % cannot be negative.';
    missing.push('Valid Quantity Variance %');
  }
  if (form.value.total_variance_amount < 0) {
    errors.total_variance_amount = 'Total variance cap cannot be negative.';
    missing.push('Valid Total Cap');
  }
  if (!form.value.priority || form.value.priority < 1) {
    errors.priority = 'Priority must be at least 1.';
    missing.push('Priority');
  }
  if (!form.value.effective_from) {
    errors.effective_from = 'Effective From date is required.';
    missing.push('Effective From');
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

  const catOption = matchingCategoryOptions.find((c) => c.value === form.value.procurement_category_id);
  const supOption = matchingSupplierOptions.find((s) => s.value === form.value.supplier_id);
  const categoryId = form.value.procurement_category_id ? Number(form.value.procurement_category_id) : null;
  const supplierId = form.value.supplier_id ? Number(form.value.supplier_id) : null;
  const entityId = Number(form.value.entity_id) || 2;

  if (editingId.value) {
    const idx = matchingToleranceRulesStore.value.findIndex((r) => r.id === editingId.value);
    if (idx !== -1) {
      matchingToleranceRulesStore.value[idx] = {
        ...matchingToleranceRulesStore.value[idx],
        match_type_lookup_value_id: form.value.match_type_lookup_value_id,
        exception_action_lookup_value_id: form.value.exception_action_lookup_value_id,
        price_variance_percent: Number(form.value.price_variance_percent),
        price_variance_amount: Number(form.value.price_variance_amount),
        quantity_variance_percent: Number(form.value.quantity_variance_percent),
        total_variance_amount: Number(form.value.total_variance_amount),
        auto_match_enabled: Boolean(form.value.auto_match_enabled),
        priority: Number(form.value.priority),
        entity_id: entityId,
        entity_name: getMatchingEntityName(entityId),
        effective_from: form.value.effective_from,
        effective_to: form.value.effective_to || null,
        procurement_category_id: categoryId,
        supplier_id: supplierId,
        category_name: categoryId ? catOption?.label : undefined,
        supplier_name: supplierId ? supOption?.label : undefined
      };
    }
    isSaved.value = true;
    toast.success('Matching tolerance rule updated.');
  } else {
    const nextId = Math.max(0, ...matchingToleranceRulesStore.value.map((r) => r.id)) + 1;
    matchingToleranceRulesStore.value.unshift({
      id: nextId,
      uuid: `9b2e5c34-8f32-4a23-b2c8-e4f85d9200${nextId.toString().padStart(2, '0')}`,
      match_type_lookup_value_id: form.value.match_type_lookup_value_id,
      exception_action_lookup_value_id: form.value.exception_action_lookup_value_id,
      price_variance_percent: Number(form.value.price_variance_percent),
      price_variance_amount: Number(form.value.price_variance_amount),
      quantity_variance_percent: Number(form.value.quantity_variance_percent),
      total_variance_amount: Number(form.value.total_variance_amount),
      auto_match_enabled: Boolean(form.value.auto_match_enabled),
      priority: Number(form.value.priority),
      entity_id: entityId,
      entity_name: getMatchingEntityName(entityId),
      effective_from: form.value.effective_from,
      effective_to: form.value.effective_to || null,
      procurement_category_id: categoryId,
      supplier_id: supplierId,
      tenant_id: 1,
      user_id: 10,
      state: 'active',
      category_name: categoryId ? catOption?.label : undefined,
      supplier_name: supplierId ? supOption?.label : undefined
    });
    isSaved.value = true;
    toast.success('Matching tolerance rule created.');
  }

  router.push('/procurement/tolerances?tab=matching');
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
        <AppButton variant="primary" size="sm" @click="handleSave">
          Save
        </AppButton>
      </div>
    </div>

    <!-- ═══ MASTER CONFIGURATION CARD (Divider Lines Only — Zero Section Titles) ═══ -->
    <div class="clean-card form-card-body">
      <!-- Group 1: Match Type & Exception Action -->
      <div class="form-grid-2">
        <FormSelect
          v-model="form.match_type_lookup_value_id"
          label="Match Type"
          :options="matchTypeOptions"
          placeholder="Select Match Type"
          required
        />

        <FormSelect
          v-model="form.exception_action_lookup_value_id"
          label="Exception Action"
          :options="exceptionActionOptions"
          placeholder="Select Action"
          required
        />
      </div>

      <div class="card-row-divider"></div>

      <!-- Group 2: Price & Quantity Variance Boundaries -->
      <div class="form-grid-2">
        <FormInput
          v-model.number="form.price_variance_percent"
          type="number"
          label="Price Variance Allowed (%)"
          placeholder="0.00"
          :error="fieldErrors.price_variance_percent"
          required
        />

        <FormInput
          v-model.number="form.price_variance_amount"
          type="number"
          label="Price Variance Cap (ETB)"
          placeholder="0.00"
          :error="fieldErrors.price_variance_amount"
          helper-text="The lower of percentage or absolute cap governs"
          required
        />
      </div>

      <div class="form-grid-2">
        <FormInput
          v-model.number="form.quantity_variance_percent"
          type="number"
          label="Quantity Variance Allowed (%)"
          placeholder="0.00"
          :error="fieldErrors.quantity_variance_percent"
          required
        />

        <FormInput
          v-model.number="form.total_variance_amount"
          type="number"
          label="Total Invoice Variance Cap (ETB)"
          placeholder="0.00"
          :error="fieldErrors.total_variance_amount"
          required
        />
      </div>

      <div class="card-row-divider"></div>

      <!-- Group 3: Entity, Precedence & Validity Dates -->
      <div class="form-grid-2">
        <FormSelect
          v-model="form.entity_id"
          label="Owning Legal Entity"
          :options="matchingEntityOptions"
          placeholder="Select Entity"
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

      <div class="form-grid-2">
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

      <!-- Dedicated Bottom Policy Checkboxes Container (2-Col Half-Width Grid, 16px horizontal / 20px vertical gap) -->
      <div class="controls-checkbox-grid">
        <FormCheckbox
          v-model="form.auto_match_enabled"
          label="Auto-Match Enabled"
          description="Match and approve invoices without human review when all variances stay within the allowed band."
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
        <span class="card-accordion-title">Scope Overrides (Category, Supplier)</span>
        <ChevronDown v-if="isScopeOpen" :size="16" class="header-chevron" />
        <ChevronRight v-else :size="16" class="header-chevron" />
      </div>

      <div v-show="isScopeOpen" class="card-accordion-body">
        <div class="form-grid-2">
          <FormSelect
            v-model="form.procurement_category_id"
            label="Procurement Category Scope"
            :options="matchingCategoryOptions"
            placeholder="Select Category"
          />

          <FormSelect
            v-model="form.supplier_id"
            label="Supplier Scope"
            :options="matchingSupplierOptions"
            placeholder="Select Supplier"
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

.form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
  align-items: start;
}

/* Dedicated Policy Checkboxes Section (2-Col Half-Width, 16px H / 20px V gap) */
.controls-checkbox-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px 16px;
  padding-top: 16px;
  border-top: 1px solid #f0f0f0;
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
  .form-grid-2,
  .controls-checkbox-grid {
    grid-template-columns: 1fr;
  }
}
</style>

