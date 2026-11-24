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
  approvalRoutesStore,
  type ProcurementApprovalRouteRecord,
  documentTypeOptions,
  workflowOptions,
  priorityOptions,
  categoryScopeOptions,
  methodScopeOptions,
  unitScopeOptions,
  entityOptions
} from './procurementApprovalRouteData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

const editingId = computed(() => (route.query.editId ? Number(route.query.editId) : null));
const isSaved = ref(false);
const isNotesOpen = ref(true);

const fieldErrors = ref<{
  document_type_id?: string;
  workflow_id?: string;
  minimum_amount?: string;
  maximum_amount?: string;
  effective_from?: string;
}>({});

const form = ref({
  document_type_id: '',
  workflow_id: '',
  priority: '1',
  minimum_amount: 0,
  maximum_amount: null as number | null,
  is_unlimited: true,
  procurement_category_id: '',
  purchase_method_id: '',
  procurement_unit_id: '',
  effective_from: new Date().toISOString().split('T')[0],
  effective_to: '',
  entity_id: '2',
  notes: ''
});

// Dynamic workflow filtering based on selected document type
const availableWorkflowOptions = computed(() => {
  if (!form.value.document_type_id) {
    return workflowOptions;
  }
  const filtered = workflowOptions.filter((w) => w.docType === form.value.document_type_id);
  return filtered.length > 0 ? filtered : workflowOptions;
});

// Category options with Global default
const fullCategoryOptions = computed(() => [
  { value: '', label: 'Global Scope (All Categories)' },
  ...categoryScopeOptions
]);

// Method options with Global default
const fullMethodOptions = computed(() => [
  { value: '', label: 'Global Scope (All Purchase Methods)' },
  ...methodScopeOptions
]);

// Unit options with Global default
const fullUnitOptions = computed(() => [
  { value: '', label: 'Global Scope (All Buying Desks)' },
  ...unitScopeOptions
]);

// ─── Breadcrumbs (Rule 3 & Rule 30) ───
const breadcrumbItems = computed<BreadcrumbItem[]>(() => [
  { label: 'Approval & Assignment Rules', to: '/procurement/routing-rules?tab=approval' },
  { label: editingId.value ? 'Edit Approval Route' : 'Create Approval Route' }
]);

watch(
  form,
  () => {
    isSaved.value = false;
    if (form.value.document_type_id) fieldErrors.value.document_type_id = undefined;
    if (form.value.workflow_id) fieldErrors.value.workflow_id = undefined;
    if (form.value.minimum_amount >= 0) fieldErrors.value.minimum_amount = undefined;
    if (form.value.effective_from) fieldErrors.value.effective_from = undefined;
  },
  { deep: true }
);

// Toggle unlimited ceiling
watch(
  () => form.value.is_unlimited,
  (val) => {
    if (val) {
      form.value.maximum_amount = null;
    }
  }
);

onMounted(() => {
  if (editingId.value) {
    const existing = approvalRoutesStore.value.find((r) => r.id === editingId.value);
    if (existing) {
      form.value = {
        document_type_id: existing.document_type_id,
        workflow_id: String(existing.workflow_id),
        priority: String(existing.priority),
        minimum_amount: existing.minimum_amount,
        maximum_amount: existing.maximum_amount,
        is_unlimited: existing.maximum_amount === null,
        procurement_category_id: existing.procurement_category_id ? String(existing.procurement_category_id) : '',
        purchase_method_id: existing.purchase_method_id ? String(existing.purchase_method_id) : '',
        procurement_unit_id: existing.procurement_unit_id ? String(existing.procurement_unit_id) : '',
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
  if (route.query.document_type_id) form.value.document_type_id = String(route.query.document_type_id);
  if (route.query.workflow_id) form.value.workflow_id = String(route.query.workflow_id);
  if (route.query.priority) form.value.priority = String(route.query.priority);
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
    document_type_id: '',
    workflow_id: '',
    priority: '1',
    minimum_amount: 0,
    maximum_amount: null,
    is_unlimited: true,
    procurement_category_id: '',
    purchase_method_id: '',
    procurement_unit_id: '',
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

  if (!form.value.document_type_id) {
    errors.document_type_id = 'Document Type is required.';
    missingLabels.push('Document Type');
  }
  if (!form.value.workflow_id) {
    errors.workflow_id = 'Workflow is required.';
    missingLabels.push('Assigned Workflow');
  }
  if (form.value.minimum_amount < 0) {
    errors.minimum_amount = 'Floor amount cannot be negative.';
    missingLabels.push('Valid Floor Amount');
  }
  if (!form.value.is_unlimited) {
    if (form.value.maximum_amount === null || form.value.maximum_amount <= 0) {
      errors.maximum_amount = 'Provide a ceiling amount or enable Unlimited Ceiling.';
      missingLabels.push('Valid Ceiling Amount');
    } else if (form.value.maximum_amount < form.value.minimum_amount) {
      errors.maximum_amount = 'Ceiling amount must exceed floor amount.';
      missingLabels.push('Ceiling > Floor Amount');
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

  const selectedDocType = documentTypeOptions.find((d) => d.value === form.value.document_type_id);
  const selectedWorkflow = workflowOptions.find((w) => w.value === form.value.workflow_id);
  const categoryId = form.value.procurement_category_id ? Number(form.value.procurement_category_id) : null;
  const methodId = form.value.purchase_method_id ? Number(form.value.purchase_method_id) : null;
  const unitId = form.value.procurement_unit_id ? Number(form.value.procurement_unit_id) : null;
  const ceiling = form.value.is_unlimited ? null : form.value.maximum_amount;

  const categoryName = categoryId ? categoryScopeOptions.find((c) => c.value === String(categoryId))?.label : undefined;
  const methodName = methodId ? methodScopeOptions.find((m) => m.value === String(methodId))?.label : undefined;
  const unitName = unitId ? unitScopeOptions.find((u) => u.value === String(unitId))?.label : undefined;

  if (editingId.value) {
    const idx = approvalRoutesStore.value.findIndex((r) => r.id === editingId.value);
    if (idx !== -1) {
      const existing = approvalRoutesStore.value[idx];
      approvalRoutesStore.value[idx] = {
        ...existing,
        document_type_id: form.value.document_type_id,
        document_type_name: selectedDocType?.label ?? form.value.document_type_id,
        workflow_id: Number(form.value.workflow_id),
        workflow_name: selectedWorkflow?.label ?? `Workflow #${form.value.workflow_id}`,
        minimum_amount: Number(form.value.minimum_amount),
        maximum_amount: ceiling,
        priority: Number(form.value.priority),
        procurement_category_id: categoryId,
        category_name: categoryName,
        purchase_method_id: methodId,
        method_name: methodName,
        procurement_unit_id: unitId,
        unit_name: unitName,
        effective_from: form.value.effective_from,
        effective_to: form.value.effective_to ? form.value.effective_to : null,
        entity_id: Number(form.value.entity_id) || 2,
        notes: form.value.notes.trim()
      };
    }
  } else {
    const nextId = Math.max(0, ...approvalRoutesStore.value.map((r) => r.id)) + 1;
    approvalRoutesStore.value.unshift({
      id: nextId,
      uuid: `par-${String(nextId).padStart(4, '0')}-custom`,
      document_type_id: form.value.document_type_id,
      document_type_name: selectedDocType?.label ?? form.value.document_type_id,
      workflow_id: Number(form.value.workflow_id),
      workflow_name: selectedWorkflow?.label ?? `Workflow #${form.value.workflow_id}`,
      minimum_amount: Number(form.value.minimum_amount),
      maximum_amount: ceiling,
      currency_code: 'ETB',
      priority: Number(form.value.priority),
      procurement_category_id: categoryId,
      category_name: categoryName,
      purchase_method_id: methodId,
      method_name: methodName,
      procurement_unit_id: unitId,
      unit_name: unitName,
      effective_from: form.value.effective_from,
      effective_to: form.value.effective_to ? form.value.effective_to : null,
      entity_id: Number(form.value.entity_id) || 2,
      notes: form.value.notes.trim(),
      state: 'active'
    });
  }

  isSaved.value = true;
  toast.success(
    editingId.value ? 'Approval route updated' : 'Approval route created',
    `Route policy for ${selectedDocType?.code ?? ''} saved successfully.`
  );
  router.push('/procurement/routing-rules?tab=approval');
};
</script>

<template>
  <div class="route-create-page">
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
      <!-- Grid 1: Core Routing Identity & Workflow -->
      <div class="form-grid-3">
        <FormSelect
          v-model="form.document_type_id"
          label="Document Type"
          :options="documentTypeOptions"
          placeholder="Select Type"
          :error="fieldErrors.document_type_id"
          required
        />

        <FormSelect
          v-model="form.workflow_id"
          label="Target Approval Workflow"
          :options="availableWorkflowOptions"
          placeholder="Select Workflow"
          :error="fieldErrors.workflow_id"
          required
        />

        <FormSelect
          v-model="form.priority"
          label="Precedence Priority"
          :options="priorityOptions"
          placeholder="Select Priority"
          required
        />
      </div>

      <!-- Grid 2: Monetary Floor & Owning Legal Entity -->
      <div class="form-grid-2">
        <FormInput
          v-model.number="form.minimum_amount"
          type="number"
          label="Minimum Floor Amount (ETB)"
          :error="fieldErrors.minimum_amount"
          required
        />

        <FormSelect
          v-model="form.entity_id"
          label="Owning Legal Entity"
          :options="entityOptions"
          placeholder="Select Entity"
          required
        />
      </div>

      <!-- Conditional Ceiling Checkbox Card (Collapsed when Unlimited checked; Expanded reveals Maximum Ceiling input) -->
      <div class="checkbox-cards-grid">
        <FormCheckboxCard
          v-model="form.is_unlimited"
          :expand-when-checked="false"
          label="Unlimited / Open Ceiling"
          description="Applies to all document amounts meeting or exceeding the minimum floor without upper limit."
        >
          <FormInput
            v-model.number="form.maximum_amount"
            type="number"
            label="Maximum Ceiling Amount (ETB)"
            :error="fieldErrors.maximum_amount"
            placeholder="Enter Ceiling"
            required
          />
        </FormCheckboxCard>
      </div>

      <!-- Grid 3: Scope Rules & Context Constraints -->
      <div class="form-grid-3">
        <FormSelect
          v-model="form.procurement_category_id"
          label="Procurement Category Scope"
          :options="fullCategoryOptions"
          placeholder="Select Category"
        />

        <FormSelect
          v-model="form.purchase_method_id"
          label="Purchase Method Scope"
          :options="fullMethodOptions"
          placeholder="Select Method"
        />

        <FormSelect
          v-model="form.procurement_unit_id"
          label="Procurement Unit Scope"
          :options="fullUnitOptions"
          placeholder="Select Unit"
        />
      </div>

      <!-- Grid 4: Validity Period -->
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
        />
      </div>
    </div>

    <!-- ═══ DEDICATED COLLAPSIBLE CARD: ROUTING RATIONALE ═══ -->
    <div class="clean-card accordion-card">
      <div
        class="card-accordion-header"
        :class="{ 'is-collapsed': !isNotesOpen }"
        @click="isNotesOpen = !isNotesOpen"
      >
        <span class="card-accordion-title">Approval Routing Rationale</span>
        <ChevronDown v-if="isNotesOpen" :size="16" class="header-chevron" />
        <ChevronRight v-else :size="16" class="header-chevron" />
      </div>

      <div v-show="isNotesOpen" class="card-accordion-body">
        <FormRichText
          v-model="form.notes"
          placeholder="Document statutory procurement directives, budget authorization thresholds, board resolution mandates, or exception handling pathways..."
          :max-length="5000"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.route-create-page {
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

.form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
}

.checkbox-cards-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
  align-items: start;
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
