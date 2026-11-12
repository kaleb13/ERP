<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  X, ChevronDown, ChevronRight
} from 'lucide-vue-next';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormRichText from '../../components/FormRichText.vue';
import { useToast } from '../../composables/useToast';
import {
  procurementCategoriesStore,
  type SpendClass,
  type ReceiptMode,
  type GovernanceStatus,
  spendClassOptions,
  receiptModeOptions,
  entityOptions,
  itemCategoryOptions,
  governanceStatusOptions,
  generateCategoryCode
} from './procurementCategoryData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

const editingId = computed(() => (route.query.editId ? Number(route.query.editId) : null));
const isSaved = ref(false);
const fieldErrors = ref<{
  name?: string;
  class_code?: string;
  receipt_mode?: string;
}>({});
const isDescriptionOpen = ref(false);

const form = ref({
  name: '',
  class_code: '' as SpendClass | '',
  receipt_mode: '' as ReceiptMode | '',
  parent_id: '',
  entity_id: '2',
  item_category_id: '',
  status: 'pending' as GovernanceStatus,
  requires_inspection: false,
  requires_contract: false,
  requires_budget_line: false,
  description: ''
});

// ─── Breadcrumbs (Rule 3 & Rule 30) ───
const breadcrumbItems = computed<BreadcrumbItem[]>(() => [
  { label: 'Procurement Categories', to: '/procurement/categories' },
  { label: editingId.value ? 'Edit Procurement Category' : 'Create Procurement Category' }
]);

// ─── Parent Options (Prevent self-parenting) ───
const parentCategoryOptions = computed(() => {
  return procurementCategoriesStore.value
    .filter((c) => c.id !== editingId.value && c.state === 'active')
    .map((c) => ({
      value: String(c.id),
      label: c.name
    }));
});

watch(
  form,
  () => {
    isSaved.value = false;
    if (form.value.name.trim()) fieldErrors.value.name = undefined;
    if (form.value.class_code) fieldErrors.value.class_code = undefined;
    if (form.value.receipt_mode) fieldErrors.value.receipt_mode = undefined;
  },
  { deep: true }
);

onMounted(() => {
  if (editingId.value) {
    const existing = procurementCategoriesStore.value.find((c) => c.id === editingId.value);
    if (existing) {
      form.value = {
        name: existing.name,
        class_code: existing.class_code,
        receipt_mode: existing.receipt_mode,
        parent_id: existing.parent_id ? String(existing.parent_id) : '',
        entity_id: existing.entity_id === null ? 'shared' : String(existing.entity_id),
        item_category_id: existing.item_category_id ? String(existing.item_category_id) : '',
        status: existing.status,
        requires_inspection: existing.requires_inspection,
        requires_contract: existing.requires_contract,
        requires_budget_line: existing.requires_budget_line,
        description: existing.description || ''
      };
      if (existing.description) {
        isDescriptionOpen.value = true;
      }
      isSaved.value = true;
    }
    return;
  }

  // Hydrate values passed from QuickCreateModal "Expand Full Form"
  if (route.query.name) form.value.name = String(route.query.name);
  if (route.query.class_code) form.value.class_code = String(route.query.class_code) as SpendClass;
  if (route.query.receipt_mode) form.value.receipt_mode = String(route.query.receipt_mode) as ReceiptMode;
  if (route.query.parent_id) form.value.parent_id = String(route.query.parent_id);
  if (route.query.item_category_id) form.value.item_category_id = String(route.query.item_category_id);
  if (route.query.requires_inspection === '1') form.value.requires_inspection = true;
  if (route.query.requires_contract === '1') form.value.requires_contract = true;
  if (route.query.requires_budget_line === '1') form.value.requires_budget_line = true;
});

const clearForm = () => {
  fieldErrors.value = {};
  form.value = {
    name: '',
    class_code: '',
    receipt_mode: '',
    parent_id: '',
    entity_id: '2',
    item_category_id: '',
    status: 'pending',
    requires_inspection: false,
    requires_contract: false,
    requires_budget_line: false,
    description: ''
  };
  isSaved.value = false;
};

const handleSave = () => {
  const errors: typeof fieldErrors.value = {};
  const missingLabels: string[] = [];

  if (!form.value.name.trim()) {
    errors.name = 'Category Name is required.';
    missingLabels.push('Category Name');
  }
  if (!form.value.class_code) {
    errors.class_code = 'Spend Class is required.';
    missingLabels.push('Spend Class');
  }
  if (!form.value.receipt_mode) {
    errors.receipt_mode = 'Receipt Mode is required.';
    missingLabels.push('Receipt Mode');
  }

  fieldErrors.value = errors;

  if (missingLabels.length > 0) {
    toast.error(
      'Please fill in all required fields',
      `Missing: ${missingLabels.join(', ')}.`
    );
    return;
  }

  const parentId = form.value.parent_id ? Number(form.value.parent_id) : null;
  const entityId = form.value.entity_id === 'shared' || !form.value.entity_id ? null : Number(form.value.entity_id);
  const itemCategoryId = form.value.item_category_id ? Number(form.value.item_category_id) : null;

  if (editingId.value) {
    const idx = procurementCategoriesStore.value.findIndex((c) => c.id === editingId.value);
    if (idx !== -1) {
      const existing = procurementCategoriesStore.value[idx];
      procurementCategoriesStore.value[idx] = {
        ...existing,
        name: form.value.name.trim(),
        description: form.value.description.trim(),
        class_code: form.value.class_code as SpendClass,
        receipt_mode: form.value.receipt_mode as ReceiptMode,
        parent_id: parentId,
        entity_id: entityId,
        item_category_id: itemCategoryId,
        status: form.value.status,
        requires_inspection: form.value.requires_inspection,
        requires_contract: form.value.requires_contract,
        requires_budget_line: form.value.requires_budget_line
      };
    }
  } else {
    const existingCodes = procurementCategoriesStore.value.map((c) => c.code);
    const nextId = Math.max(0, ...procurementCategoriesStore.value.map((c) => c.id)) + 1;
    const generatedCode = generateCategoryCode(form.value.name, existingCodes);

    procurementCategoriesStore.value.unshift({
      id: nextId,
      uuid: `pc-uuid-${nextId}`,
      code: generatedCode,
      name: form.value.name.trim(),
      description: form.value.description.trim(),
      requires_inspection: form.value.requires_inspection,
      requires_contract: form.value.requires_contract,
      requires_budget_line: form.value.requires_budget_line,
      class_code: form.value.class_code as SpendClass,
      receipt_mode: form.value.receipt_mode as ReceiptMode,
      parent_id: parentId,
      entity_id: entityId,
      item_category_id: itemCategoryId,
      status: form.value.status,
      state: 'active'
    });
  }

  isSaved.value = true;
  toast.success(
    editingId.value ? 'Procurement category updated' : 'Procurement category created',
    `"${form.value.name.trim()}" has been saved.`
  );
  router.push('/procurement/categories');
};
</script>

<template>
  <div class="category-create-page">
    <!-- ═══ TOP BAR (Rule 29: Zero Background Card, Rule 30: SaveStateBadge, Rule 27: Icon-free Save) ═══ -->
    <div class="create-top-bar">
      <AppBreadcrumb :items="breadcrumbItems" :noMargin="true">
        <template #badge>
          <SaveStateBadge :isSaved="isSaved" :isDraft="false" />
        </template>
      </AppBreadcrumb>

      <div class="top-bar-actions">
        <AppButton variant="outline" size="sm" @click="clearForm">
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>
        <!-- Rule 27: Save button MUST have zero icons -->
        <AppButton variant="primary" size="sm" @click="handleSave">
          Save
        </AppButton>
      </div>
    </div>

    <!-- ═══ MASTER FORM CARD (No Section Titles) ═══ -->
    <div class="clean-card form-card-body">
      <div class="form-grid-3">
        <!-- Rule 5 & 16: Zero placeholder, zero manual code input -->
        <FormInput
          v-model="form.name"
          label="Category Name"
          :error="fieldErrors.name"
          required
        />

        <FormSelect
          v-model="form.class_code"
          label="Spend Class"
          :options="spendClassOptions"
          placeholder="Select"
          :error="fieldErrors.class_code"
          required
        />

        <FormSelect
          v-model="form.receipt_mode"
          label="Receipt Mode"
          :options="receiptModeOptions"
          placeholder="Select"
          :error="fieldErrors.receipt_mode"
          required
        />
      </div>

      <div class="form-grid-3">
        <FormSelect
          v-model="form.parent_id"
          label="Parent Category"
          :options="parentCategoryOptions"
          placeholder="Select"
        />

        <FormSelect
          v-model="form.entity_id"
          label="Owning Entity"
          :options="entityOptions"
          placeholder="Select"
        />

        <FormSelect
          v-model="form.item_category_id"
          label="Inventory Item Category"
          :options="itemCategoryOptions"
          placeholder="Select"
        />
      </div>

      <div class="form-grid-3">
        <FormSelect
          v-model="form.status"
          label="Governance Sharing Scope"
          :options="governanceStatusOptions"
          placeholder="Select"
        />
      </div>

      <!-- Rule 5: All booleans use <FormCheckbox /> with Title + Description -->
      <div class="controls-checkbox-grid">
        <FormCheckbox
          v-model="form.requires_inspection"
          label="Requires Quality Inspection"
          description="Receipts in this category must pass Goods Inspection before inventory posting."
        />
        <FormCheckbox
          v-model="form.requires_contract"
          label="Requires Contract"
          description="Purchase orders cannot be issued without an active linked procurement contract."
        />
        <FormCheckbox
          v-model="form.requires_budget_line"
          label="Requires Budget Line"
          description="Purchase requisition lines are blocked unless linked to an approved budget line."
        />
      </div>
    </div>

    <!-- ═══ COLLAPSIBLE DESCRIPTION SECTION BELOW (Rule 18, 20, 25) ═══ -->
    <div class="clean-card accordion-card">
      <div class="card-accordion-header" @click="isDescriptionOpen = !isDescriptionOpen">
        <span>Description</span>
        <ChevronDown v-if="isDescriptionOpen" :size="15" class="header-chevron" />
        <ChevronRight v-else :size="15" class="header-chevron" />
      </div>

      <div v-if="isDescriptionOpen" class="card-accordion-divider"></div>

      <div v-if="isDescriptionOpen" class="card-accordion-body">
        <FormRichText
          v-model="form.description"
          placeholder="Enter category description, operational scope, or procurement classification notes..."
          :max-length="5000"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.category-create-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  width: 100%;
  padding: 0;
  box-sizing: border-box;
}

/* Rule 29: Zero background card, border, or box-shadow on top bar */
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

.validation-banner {
  padding: 10px 14px;
  border-radius: 8px;
  background-color: #fef2f2;
  border: 1px solid #fecaca;
  color: #dc2626;
  font-size: 13px;
}

/* Master Card */
.clean-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  overflow: hidden;
}

.form-card-body {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

.controls-checkbox-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
  padding-top: 6px;
}

/* Collapsible Accordion Section (Matches EmployeeCreate.vue) */
.card-accordion-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 22px;
  cursor: pointer;
  user-select: none;
  background: #ffffff;
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
  transition: background-color 0.15s ease;
}

.card-accordion-header:hover {
  background-color: #fafafa;
}

.header-chevron {
  color: #737373;
  flex-shrink: 0;
}

.card-accordion-divider {
  height: 1px;
  background-color: #f1f5f9;
  width: 100%;
}

.card-accordion-body {
  padding: 20px 24px;
  background-color: #ffffff;
}

/* Rule 18 & 25: Rich Text Editor Container */
.rich-editor-container {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  background: #ffffff;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.rich-editor-container:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.editor-toolbar {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
  flex-wrap: wrap;
}

.toolbar-dropdown {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #404040;
  padding: 4px 8px;
  border-radius: 4px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  cursor: pointer;
}

.toolbar-divider {
  width: 1px;
  height: 18px;
  background: #e2e8f0;
  margin: 0 2px;
}

.toolbar-icon-group {
  display: flex;
  align-items: center;
  gap: 2px;
}

.toolbar-right-group {
  margin-left: auto;
}

.editor-icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 2px;
  min-width: 26px;
  height: 26px;
  padding: 0 5px;
  border-radius: 4px;
  border: none;
  background: transparent;
  color: #404040;
  font-size: 12px;
  cursor: pointer;
}

.editor-icon-btn:hover {
  background: #e2e8f0;
}

.editor-color-box {
  width: 18px;
  height: 18px;
  border-radius: 3px;
  border: 1px solid #cbd5e1;
  background: #404040;
  margin: 0 4px;
  cursor: pointer;
}

.editor-textarea {
  width: 100%;
  border: none;
  outline: none;
  padding: 12px 14px;
  font-size: 13.5px;
  color: #404040;
  line-height: 1.55;
  resize: vertical;
  box-sizing: border-box;
  font-family: inherit;
}

.editor-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 12px;
  background: #fafafa;
  border-top: 1px solid #f1f5f9;
}

.char-count-pill {
  font-size: 11.5px;
  color: #737373;
}

.editor-resize-handle {
  font-size: 11px;
  color: #94a3b8;
  user-select: none;
}

@media (max-width: 900px) {
  .form-grid-3,
  .controls-checkbox-grid {
    grid-template-columns: 1fr;
  }
}
</style>
