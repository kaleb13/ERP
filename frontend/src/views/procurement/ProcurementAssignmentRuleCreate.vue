<!--
  ══════════════════════════════════════════════════════════════════════════════
  HALETA ERP ARCHITECTURAL SPECIFICATION — ENTITY CREATION STANDARD:
  1. DESCRIPTION INVARIANT: NEVER place descriptions as a textarea in the master card.
     Always render in a dedicated collapsible card (<div class="clean-card accordion-card">)
     with overflow: hidden and border-radius: 12px using <FormRichText />.
  2. CONTROLS: All boolean flags must use <FormCheckbox /> with Title + Description.
  3. TOP BAR: Breadcrumb sits directly on canvas; Save button has ZERO icons.
  4. SELECTORS: All placeholder text strictly follows "Select [core noun]".
  ══════════════════════════════════════════════════════════════════════════════
-->
<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { X, ChevronDown, ChevronRight } from 'lucide-vue-next';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckboxCard from '../../components/FormCheckboxCard.vue';
import FormRichText from '../../components/FormRichText.vue';
import { useToast } from '../../composables/useToast';

import {
  assignmentRulesStore,
  type ProcurementAssignmentRuleRecord,
  type SourcingOrigin,
  unitOptions,
  buyerOptions,
  originOptions,
  categoryScopeOptions,
  methodScopeOptions,
  requestingEntityOptions,
  priorityOptions,
  getBuyerName,
  getBuyerAvatar,
  getCategoryName,
  getEntityName
} from './procurementAssignmentRuleData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

const editingId = computed(() => (route.query.editId ? Number(route.query.editId) : null));
const isSaved = ref(false);
const isNotesOpen = ref(true);

const fieldErrors = ref<{
  procurement_unit_id?: string;
  minimum_amount?: string;
  maximum_amount?: string;
  effective_from?: string;
}>({});

const form = ref({
  procurement_unit_id: '',
  default_buyer_employee_id: '',
  priority: '1',
  procurement_category_id: '',
  origin_lookup_value_id: '' as SourcingOrigin | '',
  requesting_entity_id: '',
  no_floor: true,
  minimum_amount: null as number | null,
  maximum_amount: null as number | null,
  is_unlimited: true,
  purchase_method_id: '',
  effective_from: new Date().toISOString().split('T')[0],
  effective_to: '',
  entity_id: '2',
  notes: ''
});

// Owning entity options (excluding the "All" entry)
const owningEntityOptions = computed(() => {
  return requestingEntityOptions.filter((e) => e.value !== '');
});

// ─── Breadcrumbs (Rule 3 & Rule 30) ───
const breadcrumbItems = computed<BreadcrumbItem[]>(() => [
  { label: 'Approval & Assignment Rules', to: '/procurement/routing-rules?tab=assignment' },
  { label: editingId.value ? 'Edit Assignment Rule' : 'Create Assignment Rule' }
]);

watch(
  form,
  () => {
    isSaved.value = false;
    if (form.value.procurement_unit_id) fieldErrors.value.procurement_unit_id = undefined;
    if (form.value.no_floor || (form.value.minimum_amount !== null && form.value.minimum_amount >= 0)) {
      fieldErrors.value.minimum_amount = undefined;
    }
    if (form.value.effective_from) fieldErrors.value.effective_from = undefined;
  },
  { deep: true }
);

watch(
  () => form.value.no_floor,
  (val) => {
    if (val) {
      form.value.minimum_amount = null;
      fieldErrors.value.minimum_amount = undefined;
    } else if (form.value.minimum_amount === null) {
      form.value.minimum_amount = 0;
    }
  }
);

// Toggle unlimited ceiling
watch(
  () => form.value.is_unlimited,
  (val) => {
    if (val) {
      form.value.maximum_amount = null;
      fieldErrors.value.maximum_amount = undefined;
    }
  }
);

onMounted(() => {
  if (editingId.value) {
    const existing = assignmentRulesStore.value.find((r) => r.id === editingId.value);
    if (existing) {
      form.value = {
        procurement_unit_id: String(existing.procurement_unit_id),
        default_buyer_employee_id: existing.default_buyer_employee_id ? String(existing.default_buyer_employee_id) : '',
        priority: String(existing.priority),
        procurement_category_id: existing.procurement_category_id ? String(existing.procurement_category_id) : '',
        origin_lookup_value_id: existing.origin_lookup_value_id || '',
        requesting_entity_id: existing.requesting_entity_id ? String(existing.requesting_entity_id) : '',
        no_floor: existing.minimum_amount === null,
        minimum_amount: existing.minimum_amount,
        maximum_amount: existing.maximum_amount,
        is_unlimited: existing.maximum_amount === null,
        purchase_method_id: existing.purchase_method_id ? String(existing.purchase_method_id) : '',
        effective_from: existing.effective_from,
        effective_to: existing.effective_to || '',
        entity_id: String(existing.entity_id),
        notes: existing.notes || ''
      };
      if (existing.notes) {
        isNotesOpen.value = true;
      }
      isSaved.value = true;
    }
    return;
  }

  // Hydrate values passed from QuickCreateModal "Expand Full Form"
  if (route.query.procurement_unit_id) form.value.procurement_unit_id = String(route.query.procurement_unit_id);
  if (route.query.default_buyer_employee_id) form.value.default_buyer_employee_id = String(route.query.default_buyer_employee_id);
  if (route.query.priority) form.value.priority = String(route.query.priority);
  if (route.query.procurement_category_id) form.value.procurement_category_id = String(route.query.procurement_category_id);
  if (route.query.origin_lookup_value_id) form.value.origin_lookup_value_id = String(route.query.origin_lookup_value_id) as SourcingOrigin;
  if (route.query.requesting_entity_id) form.value.requesting_entity_id = String(route.query.requesting_entity_id);
  if (route.query.minimum_amount !== undefined) form.value.minimum_amount = Number(route.query.minimum_amount);
  if (route.query.maximum_amount !== undefined && route.query.maximum_amount !== '') {
    form.value.maximum_amount = Number(route.query.maximum_amount);
  }
  if (route.query.is_unlimited === '1') {
    form.value.is_unlimited = true;
    form.value.maximum_amount = null;
  } else if (route.query.is_unlimited === '0') {
    form.value.is_unlimited = false;
  }
  if (route.query.effective_from) form.value.effective_from = String(route.query.effective_from);
});

const clearForm = () => {
  fieldErrors.value = {};
  form.value = {
    procurement_unit_id: '',
    default_buyer_employee_id: '',
    priority: '1',
    procurement_category_id: '',
    origin_lookup_value_id: '',
    requesting_entity_id: '',
    no_floor: true,
    minimum_amount: null,
    maximum_amount: null,
    is_unlimited: true,
    purchase_method_id: '',
    effective_from: new Date().toISOString().split('T')[0],
    effective_to: '',
    entity_id: '2',
    notes: ''
  };
  isSaved.value = false;
};

const handleSave = () => {
  const errors: typeof fieldErrors.value = {};
  const missingLabels: string[] = [];

  if (!form.value.procurement_unit_id) {
    errors.procurement_unit_id = 'Procurement Unit is required.';
    missingLabels.push('Procurement Unit');
  }
  if (!form.value.no_floor) {
    if (form.value.minimum_amount === null || form.value.minimum_amount < 0) {
      errors.minimum_amount = 'Floor amount cannot be negative.';
      missingLabels.push('Valid Floor Amount');
    }
  }
  if (!form.value.is_unlimited) {
    if (form.value.maximum_amount === null || form.value.maximum_amount <= 0) {
      errors.maximum_amount = 'Provide a ceiling amount or enable Unlimited Ceiling.';
      missingLabels.push('Valid Ceiling Amount');
    } else if (
      !form.value.no_floor &&
      form.value.minimum_amount !== null &&
      form.value.maximum_amount < form.value.minimum_amount
    ) {
      errors.maximum_amount = 'Ceiling amount must be greater than or equal to floor amount.';
      missingLabels.push('Ceiling >= Floor Amount');
    }
  }
  if (!form.value.effective_from) {
    errors.effective_from = 'Effective From date is required.';
    missingLabels.push('Effective From Date');
  }

  fieldErrors.value = errors;

  if (missingLabels.length > 0) {
    toast.error(
      'Please fill in all required fields',
      `Missing: ${missingLabels.join(', ')}.`
    );
    return;
  }

  const selectedUnit = unitOptions.find((u) => u.value === form.value.procurement_unit_id);
  const buyerId = form.value.default_buyer_employee_id ? Number(form.value.default_buyer_employee_id) : null;
  const buyerName = buyerId ? getBuyerName(buyerId) : undefined;
  const buyerAvatar = buyerId ? getBuyerAvatar(buyerId) : undefined;
  const categoryId = form.value.procurement_category_id ? Number(form.value.procurement_category_id) : null;
  const categoryName = categoryId ? getCategoryName(categoryId) : undefined;
  const methodId = form.value.purchase_method_id ? Number(form.value.purchase_method_id) : null;
  const requestingEntityId = form.value.requesting_entity_id ? Number(form.value.requesting_entity_id) : null;
  const requestingEntityName = requestingEntityId ? getEntityName(requestingEntityId) : 'All Branches (Enterprise)';
  const floor = form.value.no_floor ? null : Number(form.value.minimum_amount ?? 0);
  const ceiling = form.value.is_unlimited ? null : form.value.maximum_amount;
  const origin = form.value.origin_lookup_value_id ? (form.value.origin_lookup_value_id as SourcingOrigin) : null;

  if (editingId.value) {
    const idx = assignmentRulesStore.value.findIndex((r) => r.id === editingId.value);
    if (idx !== -1) {
      const existing = assignmentRulesStore.value[idx];
      assignmentRulesStore.value[idx] = {
        ...existing,
        procurement_unit_id: Number(form.value.procurement_unit_id),
        unit_name: selectedUnit?.label ?? `Procurement Unit #${form.value.procurement_unit_id}`,
        default_buyer_employee_id: buyerId,
        buyer_name: buyerName,
        buyer_avatar: buyerAvatar,
        procurement_category_id: categoryId,
        category_name: categoryName,
        origin_lookup_value_id: origin,
        purchase_method_id: methodId,
        minimum_amount: floor,
        maximum_amount: ceiling,
        priority: Number(form.value.priority),
        requesting_entity_id: requestingEntityId,
        requesting_entity_name: requestingEntityName,
        effective_from: form.value.effective_from,
        effective_to: form.value.effective_to ? form.value.effective_to : null,
        entity_id: Number(form.value.entity_id) || 2,
        notes: form.value.notes.trim()
      };
    }
  } else {
    const nextId = Math.max(0, ...assignmentRulesStore.value.map((r) => r.id)) + 1;
    assignmentRulesStore.value.unshift({
      id: nextId,
      uuid: `par-${String(nextId).padStart(4, '0')}-custom`,
      procurement_unit_id: Number(form.value.procurement_unit_id),
      unit_name: selectedUnit?.label ?? `Procurement Unit #${form.value.procurement_unit_id}`,
      default_buyer_employee_id: buyerId,
      buyer_name: buyerName,
      buyer_avatar: buyerAvatar,
      procurement_category_id: categoryId,
      category_name: categoryName,
      origin_lookup_value_id: origin,
      purchase_method_id: methodId,
      minimum_amount: floor,
      maximum_amount: ceiling,
      currency_code: 'ETB',
      priority: Number(form.value.priority),
      requesting_entity_id: requestingEntityId,
      requesting_entity_name: requestingEntityName,
      entity_id: Number(form.value.entity_id) || 2,
      effective_from: form.value.effective_from,
      effective_to: form.value.effective_to ? form.value.effective_to : null,
      notes: form.value.notes.trim(),
      state: 'active'
    });
  }

  isSaved.value = true;
  toast.success(
    editingId.value ? 'Assignment rule updated' : 'Assignment rule created',
    `Assignment policy for ${selectedUnit?.code ?? ''} saved successfully.`
  );
  router.push('/procurement/routing-rules?tab=assignment');
};
</script>

<template>
  <div class="rule-create-page">
    <!-- ═══ TOP BAR (Rule 29: Canvas Background, Rule 30: SaveStateBadge, Rule 27: Icon-free Save) ═══ -->
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
        <!-- Rule 27: Save button MUST have plain text and zero icons -->
        <AppButton variant="primary" size="sm" @click="handleSave">
          Save
        </AppButton>
      </div>
    </div>

    <!-- ═══ MASTER CONFIGURATION CARD (Clean White Form Card) ═══ -->
    <div class="clean-card form-card-body">
      <!-- Grid 1: Procurement Unit, Default Buyer & Priority -->
      <div class="form-grid-3">
        <FormSelect
          v-model="form.procurement_unit_id"
          label="Procurement Unit"
          :options="unitOptions"
          placeholder="Select Unit"
          :error="fieldErrors.procurement_unit_id"
          required
        />

        <FormSelect
          v-model="form.default_buyer_employee_id"
          label="Default Assigned Buyer"
          :options="buyerOptions"
          placeholder="Select Buyer"
        />

        <FormSelect
          v-model="form.priority"
          label="Precedence Priority"
          :options="priorityOptions"
          placeholder="Select Priority"
          required
        />
      </div>

      <!-- Grid 2: Scope & Sourcing Eligibility -->
      <div class="form-grid-3">
        <FormSelect
          v-model="form.procurement_category_id"
          label="Procurement Category Scope"
          :options="categoryScopeOptions"
          placeholder="Select Category"
        />

        <FormSelect
          v-model="form.origin_lookup_value_id"
          label="Sourcing Origin"
          :options="originOptions"
          placeholder="Select Origin"
        />

        <FormSelect
          v-model="form.requesting_entity_id"
          label="Requesting Branch / Entity"
          :options="requestingEntityOptions"
          placeholder="Select Entity"
        />
      </div>

      <!-- Value Band Expandable Checkbox Cards (Nullable minimum_amount & maximum_amount) -->
      <div class="checkbox-cards-grid">
        <FormCheckboxCard
          v-model="form.no_floor"
          :expand-when-checked="false"
          label="No Minimum Floor"
          description="Applies starting from any requisition value with no lower monetary threshold."
        >
          <FormInput
            v-model.number="form.minimum_amount"
            type="number"
            label="Minimum Floor Requisition Value (ETB)"
            :error="fieldErrors.minimum_amount"
            required
          />
        </FormCheckboxCard>

        <FormCheckboxCard
          v-model="form.is_unlimited"
          :expand-when-checked="false"
          label="Unlimited / Open Ceiling"
          description="Applies to all requisition amounts at or above the floor without an upper limit."
        >
          <FormInput
            v-model.number="form.maximum_amount"
            type="number"
            label="Maximum Ceiling Requisition Value (ETB)"
            :error="fieldErrors.maximum_amount"
            required
          />
        </FormCheckboxCard>
      </div>

      <!-- Grid 3: Purchase Method & Validity Dates -->
      <div class="form-grid-3">
        <FormSelect
          v-model="form.purchase_method_id"
          label="Purchase Method Scope"
          :options="methodScopeOptions"
          placeholder="Select Method"
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
        />
      </div>

      <!-- Grid 4: Owning Legal Entity -->
      <div class="form-grid-3">
        <FormSelect
          v-model="form.entity_id"
          label="Owning Legal Entity"
          :options="owningEntityOptions"
          placeholder="Select Entity"
          required
        />
      </div>
    </div>

    <!-- ═══ DEDICATED COLLAPSIBLE CARD: SOURCING GUIDELINES & OPERATIONAL MEMO ═══ -->
    <div class="clean-card accordion-card">
      <div
        class="card-accordion-header"
        :class="{ 'is-collapsed': !isNotesOpen }"
        @click="isNotesOpen = !isNotesOpen"
      >
        <span class="card-accordion-title">Sourcing Guidelines & Memo</span>
        <ChevronDown v-if="isNotesOpen" :size="16" class="header-chevron" />
        <ChevronRight v-else :size="16" class="header-chevron" />
      </div>

      <div v-show="isNotesOpen" class="card-accordion-body">
        <FormRichText
          v-model="form.notes"
          placeholder="Document approved supplier rosters, customs tariff classifications, delivery lead times, or emergency substitution protocols..."
          :max-length="5000"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.rule-create-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
  width: 100%;
}

/* Rule 29: Top bar on transparent canvas */
.create-top-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: transparent;
  padding: 0;
  margin: 0;
}

.top-bar-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

/* Master Form Card */
.clean-card.form-card-body {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}

.checkbox-cards-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
  align-items: start;
}

.checkbox-container {
  padding: 4px 0;
}

/* Rule 1: Dedicated Collapsible Accordion Card */
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
</style>
