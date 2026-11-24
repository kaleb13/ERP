<!--
  ══════════════════════════════════════════════════════════════════════════════
  HALETA ERP ARCHITECTURAL SPECIFICATION — ENTITY CREATION STANDARD:
  1. SCHEMA RELATIONAL INTEGRITY: PurchaseMethod is an aggregate root with 1:N
     PurchaseMethodThreshold lines. Both are unified here via <BaseTabs />:
     - Tab 1: Master Parameters (PurchaseMethod)
     - Tab 2: Configured Threshold Bands (PurchaseMethodThreshold via <DynamicSubTable />)
  2. DESCRIPTION INVARIANT: NEVER place descriptions as a textarea in the master card.
     Always render in a dedicated collapsible card (<div class="clean-card accordion-card">)
     with overflow: hidden and border-radius: 12px using <FormRichText />.
  3. DYNAMIC SUBTABLE: Strictly 3 to 5 mandatory scanning columns. All secondary/scope
     attributes (Category, Buying Desk, Validity) are edited in the Expand Row Modal (↗).
     Container must provide 24px padding (padding: 24px).
  4. ZERO FLOATING ACTION BUTTONS: Breadcrumbs sit directly on canvas; Save button has 0 icons.
  ══════════════════════════════════════════════════════════════════════════════
-->
<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { X, Layers, Scale, ChevronDown, ChevronRight } from 'lucide-vue-next';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormRichText from '../../components/FormRichText.vue';
import DynamicSubTable, { type DynamicTableColumn } from '../../components/DynamicSubTable.vue';
import { useToast } from '../../composables/useToast';
import {
  purchaseMethodsStore,
  thresholdBandsStore,
  type GovernanceStatus,
  type PurchaseMethodRecord,
  type PurchaseMethodThresholdRecord,
  governanceStatusOptions,
  categoryOptions,
  unitOptions,
  generateMethodCode
} from './procurementMethodData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

const editingId = computed(() => (route.query.editId ? Number(route.query.editId) : null));
const isSaved = ref(false);
const isDescriptionOpen = ref(true);
const fieldErrors = ref<{
  name?: string;
  minimum_quotations?: string;
  status?: string;
}>({});

// ─── Tab Navigation (AGENTS.md & creation-ux.instructions.md Standard) ───
type TabId = 'details' | 'bands';
const activeTab = ref<TabId>('details');

const tabs = computed<BaseTabItem<TabId>[]>(() => [
  { id: 'details', label: 'Method Details', icon: Scale },
  { id: 'bands', label: 'Threshold Bands', icon: Layers, count: bandsList.value.length }
]);

const form = ref({
  name: '',
  description: '',
  minimum_quotations: 3,
  requires_committee: false,
  requires_sealed_bid: false,
  requires_post_facto_approval: false,
  allows_single_source: false,
  is_open_invitation: false,
  status: 'acceptForAll' as GovernanceStatus
});

// ─── Threshold Bands Factory & State (PurchaseMethodThreshold [DIST][INH]) ───
const newBandFactory = () => {
  return {
    id: Date.now() + Math.random(),
    minimum_amount: 0,
    maximum_amount: 50000 as number | null,
    is_mandatory: true,
    procurement_category_id: '',
    procurement_unit_id: '',
    effective_from: new Date().toISOString().split('T')[0],
    effective_to: ''
  };
};

// Rule: Dynamic tables must never start empty; initialize with 1 default row
const bandsList = ref<Array<{
  id: number;
  minimum_amount: number;
  maximum_amount: number | null;
  is_mandatory: boolean;
  procurement_category_id: string;
  procurement_unit_id: string;
  effective_from: string;
  effective_to: string;
}>>([newBandFactory()]);

// ─── Sub-Table Column Definitions: Strictly Core Mandatory Scanning Columns ───
// Non-mandatory/scope attributes (Category, Buying Desk, Validity dates) are configured in the Expand Row Modal (↗)
const bandTableColumns: DynamicTableColumn[] = [
  { key: 'minimum_amount', label: 'Floor Amount (ETB)', minWidth: '180px', type: 'custom' },
  { key: 'maximum_amount', label: 'Ceiling Amount (ETB)', minWidth: '180px', type: 'custom' },
  { key: 'is_mandatory', label: 'Enforcement Mode', minWidth: '180px', type: 'custom' }
];

const enforcementOptions = [
  { value: true, label: 'Mandatory (Forces Procedure)' },
  { value: false, label: 'Permissive (Permits Alternative)' }
];

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3 & 29) ───
const breadcrumbItems = computed<BreadcrumbItem[]>(() => [
  { label: 'Purchase Methods', to: '/procurement/methods' },
  { label: editingId.value ? 'Edit Purchase Method' : 'Create Purchase Method' }
]);

// ─── Hydration from Editing ID or Route Query Params (Expand Full Form) ───
const hydrateForm = () => {
  if (editingId.value) {
    const existing = purchaseMethodsStore.value.find((m) => m.id === editingId.value);
    if (existing) {
      form.value = {
        name: existing.name,
        description: existing.description || '',
        minimum_quotations: existing.minimum_quotations,
        requires_committee: existing.requires_committee,
        requires_sealed_bid: existing.requires_sealed_bid,
        requires_post_facto_approval: existing.requires_post_facto_approval,
        allows_single_source: existing.allows_single_source,
        is_open_invitation: existing.is_open_invitation,
        status: existing.status
      };

      const existingBands = thresholdBandsStore.value.filter((b) => b.purchase_method_id === editingId.value);
      if (existingBands.length > 0) {
        bandsList.value = existingBands.map((b) => ({
          id: b.id,
          minimum_amount: b.minimum_amount,
          maximum_amount: b.maximum_amount,
          is_mandatory: b.is_mandatory,
          procurement_category_id: b.procurement_category_id ? String(b.procurement_category_id) : '',
          procurement_unit_id: b.procurement_unit_id ? String(b.procurement_unit_id) : '',
          effective_from: b.effective_from,
          effective_to: b.effective_to || ''
        }));
      }
      return;
    }
  }

  // Hydrate query params passed when expanding from QuickCreateModal
  const q = route.query;
  if (q.name) form.value.name = String(q.name);
  if (q.minimum_quotations !== undefined) form.value.minimum_quotations = Number(q.minimum_quotations);
  if (q.requires_committee !== undefined) form.value.requires_committee = q.requires_committee === '1' || q.requires_committee === 'true';
  if (q.requires_sealed_bid !== undefined) form.value.requires_sealed_bid = q.requires_sealed_bid === '1' || q.requires_sealed_bid === 'true';
  if (q.is_open_invitation !== undefined) form.value.is_open_invitation = q.is_open_invitation === '1' || q.is_open_invitation === 'true';
  if (q.allows_single_source !== undefined) form.value.allows_single_source = q.allows_single_source === '1' || q.allows_single_source === 'true';
  if (q.requires_post_facto_approval !== undefined) form.value.requires_post_facto_approval = q.requires_post_facto_approval === '1' || q.requires_post_facto_approval === 'true';
};

onMounted(hydrateForm);
watch(editingId, hydrateForm);

const clearForm = () => {
  form.value = {
    name: '',
    description: '',
    minimum_quotations: 3,
    requires_committee: false,
    requires_sealed_bid: false,
    requires_post_facto_approval: false,
    allows_single_source: false,
    is_open_invitation: false,
    status: 'acceptForAll'
  };
  bandsList.value = [newBandFactory()];
  fieldErrors.value = {};
  toast.info('Form Cleared', 'All fields have been reset to defaults.');
};

// ─── Save Execution ───
const handleSave = () => {
  const errors: typeof fieldErrors.value = {};
  if (!form.value.name.trim()) errors.name = 'Method Name is required.';
  if (form.value.minimum_quotations === undefined || form.value.minimum_quotations === null || form.value.minimum_quotations < 0) {
    errors.minimum_quotations = 'Minimum quotations must be 0 or greater.';
  }

  fieldErrors.value = errors;

  if (Object.keys(errors).length > 0) {
    activeTab.value = 'details';
    toast.error('Validation Error', 'Please complete all required fields on the Method Details tab.');
    return;
  }

  // Validate threshold bands
  const hasInvalidBand = bandsList.value.some((band) => {
    const min = Number(band.minimum_amount);
    const max = band.maximum_amount !== null && band.maximum_amount !== undefined && band.maximum_amount !== ('' as any)
      ? Number(band.maximum_amount)
      : null;
    if (min < 0) return true;
    if (max !== null && max <= min) return true;
    if (!band.effective_from) return true;
    if (band.effective_to && band.effective_to < band.effective_from) return true;
    return false;
  });

  if (hasInvalidBand) {
    activeTab.value = 'bands';
    toast.error(
      'Invalid Threshold Bands',
      'Ensure ceiling amount is greater than floor amount, valid-from is provided, and valid-to is not earlier than valid-from.'
    );
    return;
  }

  let methodId: number;
  let methodCode: string;

  if (editingId.value) {
    methodId = editingId.value;
    const idx = purchaseMethodsStore.value.findIndex((m) => m.id === editingId.value);
    if (idx !== -1) {
      const existing = purchaseMethodsStore.value[idx];
      methodCode = existing.code;
      purchaseMethodsStore.value[idx] = {
        ...existing,
        name: form.value.name.trim(),
        description: form.value.description.trim(),
        minimum_quotations: Number(form.value.minimum_quotations),
        requires_committee: form.value.requires_committee,
        requires_sealed_bid: form.value.requires_sealed_bid,
        requires_post_facto_approval: form.value.requires_post_facto_approval,
        allows_single_source: form.value.allows_single_source,
        is_open_invitation: form.value.is_open_invitation,
        status: form.value.status
      };
    } else {
      methodCode = generateMethodCode(form.value.name);
    }
  } else {
    const existingCodes = purchaseMethodsStore.value.map((m) => m.code);
    const nextId = Math.max(0, ...purchaseMethodsStore.value.map((m) => m.id)) + 1;
    methodId = nextId;
    methodCode = generateMethodCode(form.value.name, existingCodes);

    const newMethod: PurchaseMethodRecord = {
      id: nextId,
      uuid: `pm-uuid-${nextId}`,
      code: methodCode,
      name: form.value.name.trim(),
      description: form.value.description.trim(),
      minimum_quotations: Number(form.value.minimum_quotations),
      requires_committee: form.value.requires_committee,
      requires_sealed_bid: form.value.requires_sealed_bid,
      requires_post_facto_approval: form.value.requires_post_facto_approval,
      allows_single_source: form.value.allows_single_source,
      is_open_invitation: form.value.is_open_invitation,
      entity_id: 2,
      status: form.value.status,
      state: 'active'
    };
    purchaseMethodsStore.value.unshift(newMethod);
  }

  // Update threshold bands in store
  const existingBands = editingId.value
    ? thresholdBandsStore.value.filter((b) => b.purchase_method_id === editingId.value)
    : [];

  let nextBandId = Math.max(0, ...thresholdBandsStore.value.map((b) => b.id)) + 1;
  const updatedBands: PurchaseMethodThresholdRecord[] = bandsList.value.map((b) => {
    const existingBand = existingBands.find((eb) => eb.id === b.id);
    const cat = categoryOptions.find((c) => c.value === b.procurement_category_id);
    const unit = unitOptions.find((u) => u.value === b.procurement_unit_id);
    const max = b.maximum_amount !== null && b.maximum_amount !== undefined && b.maximum_amount !== ('' as any)
      ? Number(b.maximum_amount)
      : null;

    const id = existingBand?.id ?? nextBandId++;
    return {
      id,
      uuid: existingBand?.uuid ?? `pmt-uuid-${id}`,
      purchase_method_id: methodId,
      method_name: form.value.name.trim(),
      method_code: methodCode,
      minimum_amount: Number(b.minimum_amount),
      maximum_amount: max,
      currency_code: 'ETB',
      is_mandatory: b.is_mandatory,
      procurement_category_id: b.procurement_category_id ? Number(b.procurement_category_id) : null,
      category_name: cat && cat.value ? cat.label.split(' (')[0] : 'All Categories',
      procurement_unit_id: b.procurement_unit_id ? Number(b.procurement_unit_id) : null,
      unit_name: unit && unit.value ? unit.label.split(' (')[0] : 'All Buying Units',
      effective_from: b.effective_from,
      effective_to: b.effective_to || null,
      entity_id: 2,
      state: existingBand?.state ?? 'active'
    };
  });

  thresholdBandsStore.value = [
    ...thresholdBandsStore.value.filter((b) => b.purchase_method_id !== methodId),
    ...updatedBands
  ];

  isSaved.value = true;
  toast.success(
    editingId.value ? 'Purchase Method Updated' : 'Purchase Method Created',
    `"${form.value.name.trim()}" and its configured threshold bands have been saved.`
  );
  router.push('/procurement/methods');
};
</script>

<template>
  <div class="method-create-page">
    
    <!-- ═══ TOP BAR (Rule 29: Transparent Canvas, Rule 30: SaveStateBadge, Rule 27: Icon-Free Save) ═══ -->
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
        <!-- Rule 27: Save button MUST have zero icons -->
        <AppButton variant="primary" size="sm" @click="handleSave">
          Save
        </AppButton>
      </div>
    </div>

    <!-- ═══ TOP TABS: <BaseTabs /> (Primary Capsule Tab Standard) ═══ -->
    <div class="tabs-header-wrap">
      <BaseTabs
        v-model="activeTab"
        :tabs="tabs"
      />
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 1: MASTER METHOD DETAILS (PurchaseMethod [REF])            -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'details'" class="tab-pane">
      <div class="clean-card form-card-body">
        
        <!-- Row 1: Core Identity & Parameters -->
        <div class="form-grid-3">
          <FormInput
            v-model="form.name"
            label="Method Name"
            :error="fieldErrors.name"
            required
          />

          <FormInput
            v-model="form.minimum_quotations"
            type="number"
            label="Minimum Quotations Required"
            :error="fieldErrors.minimum_quotations"
            required
          />
        </div>

        <!-- Row 2: Statutory Policy Checkboxes (Rule 5: FormCheckbox with Title + Description) -->
        <div class="controls-checkbox-grid">
          <FormCheckbox
            v-model="form.requires_committee"
            label="Requires Procurement Committee Evaluation"
            description="A designated procurement evaluation committee must review, score, and sanction supplier awards."
          />
          <FormCheckbox
            v-model="form.requires_sealed_bid"
            label="Requires Simultaneous Sealed Bids"
            description="Supplier bids must remain cryptographically sealed and opened simultaneously in committee session."
          />
          <FormCheckbox
            v-model="form.is_open_invitation"
            label="Open Public Advert"
            description="Notice is advertised publicly to all qualified market suppliers rather than restricted to an invited shortlist."
          />
          <FormCheckbox
            v-model="form.allows_single_source"
            label="Allows Single Source Supplier"
            description="Permits direct award to a sole-source or proprietary supplier without solicitation of multiple quotes."
          />
          <FormCheckbox
            v-model="form.requires_post_facto_approval"
            label="Allows Emergency Post-Facto Ratification"
            description="Permits immediate operational procurement with formal committee ratification conducted after placement."
          />
        </div>

      </div>

      <!-- ═══ COLLAPSIBLE DESCRIPTION SECTION (creation-ux.instructions.md Section 5) ═══ -->
      <div class="clean-card accordion-card">
        <div
          class="card-accordion-header"
          :class="{ 'is-collapsed': !isDescriptionOpen }"
          @click="isDescriptionOpen = !isDescriptionOpen"
        >
          <span>Description</span>
          <ChevronDown v-if="isDescriptionOpen" :size="16" class="header-chevron" />
          <ChevronRight v-else :size="16" class="header-chevron" />
        </div>

        <div v-show="isDescriptionOpen" class="card-accordion-body">
          <FormRichText
            v-model="form.description"
            placeholder="Enter statutory procedural guidelines, regulatory mandates, and operational rationale..."
            :max-length="5000"
          />
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 2: THRESHOLD BANDS (PurchaseMethodThreshold [DIST][INH])   -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'bands'" class="tab-pane">
      <div class="clean-card subtable-card">
        <div class="subtable-header-box">
          <h3 class="section-title">Threshold Bands</h3>
          <p class="section-subtitle">
            Order value thresholds (ETB) that force or permit this procurement procedure across categories and buying desks.
          </p>
        </div>

        <DynamicSubTable
          v-model="bandsList"
          :columns="bandTableColumns"
          entity-name="Threshold Band"
          entity-name-plural="Threshold Bands"
          empty-text="No threshold bands configured for this method yet."
          :can-add-row="true"
          :can-delete="true"
          :new-row-factory="newBandFactory"
        >
          <!-- Custom Cell: Floor Amount -->
          <template #minimum_amount="{ row }">
            <div class="cell-wrap">
              <input
                v-model.number="row.minimum_amount"
                type="number"
                step="0.01"
                min="0"
                class="cell-grid-input text-right font-mono"
                placeholder="0.00"
              />
            </div>
          </template>

          <!-- Custom Cell: Ceiling Amount -->
          <template #maximum_amount="{ row }">
            <div class="cell-wrap">
              <input
                v-model.number="row.maximum_amount"
                type="number"
                step="0.01"
                min="0"
                class="cell-grid-input text-right font-mono"
                placeholder="No limit"
              />
            </div>
          </template>

          <!-- Custom Cell: Enforcement Mode -->
          <template #is_mandatory="{ row }">
            <div class="cell-wrap">
              <FormSelect
                v-model="row.is_mandatory"
                :options="enforcementOptions"
                variant="cell"
                :teleport="true"
              />
            </div>
          </template>

          <!-- ─── Expand Row Modal Slot (Figma 6095:96370 Standard) ─── -->
          <template #expand-modal="{ row }">
            <div class="expand-modal-form">
              <div class="modal-grid-2">
                <FormInput
                  v-model="row.minimum_amount"
                  type="number"
                  label="Floor Amount (ETB)"
                  required
                />

                <FormInput
                  v-model="row.maximum_amount"
                  type="number"
                  label="Ceiling Amount (ETB)"
                />
              </div>

              <div class="modal-grid-2">
                <FormSelect
                  v-model="row.is_mandatory"
                  label="Enforcement Mode"
                  :options="enforcementOptions"
                  placeholder="Select Mode"
                  required
                />

                <FormSelect
                  v-model="row.procurement_category_id"
                  label="Category Scope"
                  :options="categoryOptions"
                  placeholder="Select Scope"
                  :searchable="true"
                />
              </div>

              <div class="modal-grid-2">
                <FormSelect
                  v-model="row.procurement_unit_id"
                  label="Buying Desk Scope"
                  :options="unitOptions"
                  placeholder="Select Scope"
                  :searchable="true"
                />

                <FormInput
                  v-model="row.effective_from"
                  type="date"
                  label="Valid From"
                  required
                />
              </div>

              <div class="modal-grid-2">
                <FormInput
                  v-model="row.effective_to"
                  type="date"
                  label="Valid To"
                />
              </div>
            </div>
          </template>
        </DynamicSubTable>
      </div>
    </div>

  </div>
</template>

<style scoped>
.method-create-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-xl, 16px);
  width: 100%;
}

/* TOP BAR (Directly on canvas, zero container card) */
.create-top-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--alias-spacing-xl, 16px);
  background: transparent;
  padding: 0;
  border: none;
}

.top-bar-actions {
  display: flex;
  align-items: center;
  gap: var(--alias-spacing-sm, 8px);
}

/* TABS HEADER */
.tabs-header-wrap {
  display: flex;
  align-items: center;
}

/* FORM CARDS */
.clean-card {
  background: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: var(--alias-radius-xl, 12px);
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.05);
  overflow: hidden;
}

.form-card-body {
  padding: var(--alias-spacing-3xl, 24px);
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-2xl, 20px);
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--alias-spacing-xl, 16px);
}

.form-grid-1 {
  display: flex;
  flex-direction: column;
  width: 100%;
}

.controls-checkbox-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: var(--alias-spacing-lg, 14px) var(--alias-spacing-2xl, 20px);
  padding-top: var(--alias-spacing-sm, 8px);
  border-top: 1px solid var(--alias-color-border-subtle, #f0f0f0);
}

/* SUB-TABLE CARD (With proper 24px left/right/vertical padding) */
.subtable-card {
  padding: var(--alias-spacing-3xl, 24px);
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-xl, 16px);
}

.subtable-header-box {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.section-title {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
}

.section-subtitle {
  margin: 0;
  font-size: 13px;
  color: var(--alias-color-text-tertiary, #737373);
}

/* ─── Collapsible Description Section (Accordion Card) ─── */
.clean-card.accordion-card {
  display: flex;
  flex-direction: column;
  border-radius: var(--alias-radius-xl, 12px);
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
  background: #ffffff;
  font-size: 14px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  border-bottom: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  transition: background-color 0.15s ease;
  border-top-left-radius: var(--alias-radius-xl, 12px);
  border-top-right-radius: var(--alias-radius-xl, 12px);
}

.card-accordion-header.is-collapsed {
  border-bottom: none;
  border-bottom-left-radius: var(--alias-radius-xl, 12px);
  border-bottom-right-radius: var(--alias-radius-xl, 12px);
}

.card-accordion-header:hover {
  background-color: #fafafa;
}

.header-chevron {
  color: var(--alias-color-text-tertiary, #737373);
  flex-shrink: 0;
}

.card-accordion-body {
  padding: 20px 24px 24px;
  background-color: #ffffff;
  border-bottom-left-radius: var(--alias-radius-xl, 12px);
  border-bottom-right-radius: var(--alias-radius-xl, 12px);
}

.cell-wrap {
  width: 100%;
  display: flex;
  align-items: center;
}

.cell-grid-input {
  width: 100%;
  height: 40px;
  background: transparent;
  border: none;
  outline: none;
  padding: 0 12px;
  font-size: 13.5px;
  color: var(--alias-color-text-secondary, #404040);
}

.cell-grid-date {
  width: 100%;
  height: 40px;
  background: transparent;
  border: none;
  outline: none;
  padding: 0 12px;
  font-size: 13px;
  color: var(--alias-color-text-secondary, #404040);
}

/* ─── Expand Row Modal Inside DynamicSubTable (Figma 6095:96370) ─── */
.expand-modal-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.modal-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.tab-pane {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-xl, 16px);
}

@media (max-width: 1024px) {
  .form-grid-3 {
    grid-template-columns: 1fr;
  }
  .controls-checkbox-grid {
    grid-template-columns: 1fr;
  }
  .modal-grid-2 {
    grid-template-columns: 1fr;
  }
}
</style>
