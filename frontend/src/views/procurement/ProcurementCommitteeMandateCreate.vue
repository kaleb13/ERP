<!--
  ══════════════════════════════════════════════════════════════════════════════
  HALETA ERP ARCHITECTURAL SPECIFICATION — ENTITY CREATION STANDARD:
  1. DESCRIPTION INVARIANT: NEVER place descriptions/notes as a textarea in the master card.
     Always render in a dedicated collapsible card (<div class="clean-card accordion-card">)
     with overflow: hidden and border-radius: 12px using <FormRichText />.
  2. CONTROLS: All boolean flags use <FormCheckbox /> with Title + Description.
  3. TOP BAR: Breadcrumb sits directly on canvas with SaveStateBadge sealed in #badge;
     Save button has ZERO icons.
  4. ZERO SECTION TITLES inside the master form card.
  5. SELECTORS: All placeholder text strictly follows "Select [core noun]".
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
  committeeMandatesStore,
  committeePurposeOptions,
  coreCommitteeOptions,
  categoryScopeOptions,
  unitScopeOptions,
  entityOptions,
  getCoreCommittee,
  getPurposeLabel,
  type ProcurementCommitteePurpose
} from './procurementCommitteeMandateData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

const editingId = computed(() => {
  if (route.params.id) return Number(route.params.id);
  if (route.query.editId) return Number(route.query.editId);
  return null;
});

const isSaved = ref(false);
const isNotesOpen = ref(false);

const fieldErrors = ref<{
  committee_id?: string;
  purpose?: string;
  quorum?: string;
  minimum_amount?: string;
  maximum_amount?: string;
  effective_from?: string;
  effective_to?: string;
}>({});

const form = ref({
  committee_id: '',
  purpose: '' as ProcurementCommitteePurpose | '',
  quorum: 3,
  no_floor: false,
  minimum_amount: 0 as number | null,
  is_unlimited: true,
  maximum_amount: null as number | null,
  procurement_category_id: '',
  procurement_unit_id: '',
  entity_id: '2',
  effective_from: new Date().toISOString().split('T')[0],
  effective_to: '',
  notes: ''
});

const selectedCommitteeMeta = computed(() => {
  if (!form.value.committee_id) return null;
  return getCoreCommittee(Number(form.value.committee_id)) ?? null;
});

const quorumHelperText = computed(() => {
  if (selectedCommitteeMeta.value) {
    return `Signed members needed for decisions to count (${selectedCommitteeMeta.value.memberCount} total members in ${selectedCommitteeMeta.value.name}).`;
  }
  return 'Minimum signed members needed for the committee event to count.';
});

const fullCategoryOptions = computed(() => [
  { value: '', label: 'All Categories (Global Scope)' },
  ...categoryScopeOptions
]);

const fullUnitOptions = computed(() => [
  { value: '', label: 'All Buying Units (Global Scope)' },
  ...unitScopeOptions
]);

const breadcrumbItems = computed<BreadcrumbItem[]>(() => [
  { label: 'Committee Mandates', to: '/procurement/committee-mandates' },
  { label: editingId.value ? 'Edit Committee Mandate' : 'Create Committee Mandate' }
]);

watch(
  form,
  () => {
    isSaved.value = false;
    if (form.value.committee_id) fieldErrors.value.committee_id = undefined;
    if (form.value.purpose) fieldErrors.value.purpose = undefined;
    if (form.value.quorum >= 1) fieldErrors.value.quorum = undefined;
    if (form.value.no_floor || (form.value.minimum_amount !== null && form.value.minimum_amount >= 0)) {
      fieldErrors.value.minimum_amount = undefined;
    }
    if (form.value.effective_from) fieldErrors.value.effective_from = undefined;
    if (!form.value.effective_to || form.value.effective_to >= form.value.effective_from) {
      fieldErrors.value.effective_to = undefined;
    }
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
    const existing = committeeMandatesStore.value.find((m) => m.id === editingId.value);
    if (existing) {
      form.value = {
        committee_id: String(existing.committee_id),
        purpose: existing.purpose,
        quorum: existing.quorum,
        no_floor: existing.minimum_amount === null,
        minimum_amount: existing.minimum_amount,
        is_unlimited: existing.maximum_amount === null,
        maximum_amount: existing.maximum_amount,
        procurement_category_id: existing.procurement_category_id
          ? String(existing.procurement_category_id)
          : '',
        procurement_unit_id: existing.procurement_unit_id
          ? String(existing.procurement_unit_id)
          : '',
        entity_id: String(existing.entity_id),
        effective_from: existing.effective_from,
        effective_to: existing.effective_to || '',
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
  if (route.query.committee_id) form.value.committee_id = String(route.query.committee_id);
  if (route.query.purpose) form.value.purpose = String(route.query.purpose) as ProcurementCommitteePurpose;
  if (route.query.quorum) form.value.quorum = Number(route.query.quorum);
  if (route.query.effective_from) form.value.effective_from = String(route.query.effective_from);
});

const clearForm = () => {
  fieldErrors.value = {};
  form.value = {
    committee_id: '',
    purpose: '',
    quorum: 3,
    no_floor: false,
    minimum_amount: 0,
    is_unlimited: true,
    maximum_amount: null,
    procurement_category_id: '',
    procurement_unit_id: '',
    entity_id: '2',
    effective_from: new Date().toISOString().split('T')[0],
    effective_to: '',
    notes: ''
  };
  isSaved.value = false;
};

const handleSave = () => {
  const errors: typeof fieldErrors.value = {};
  const missingLabels: string[] = [];

  if (!form.value.committee_id) {
    errors.committee_id = 'Core Committee is required.';
    missingLabels.push('Core Committee');
  }
  if (!form.value.purpose) {
    errors.purpose = 'Procurement Purpose is required.';
    missingLabels.push('Procurement Purpose');
  }
  if (!form.value.quorum || form.value.quorum < 1) {
    errors.quorum = 'Quorum must be at least 1 signed member.';
    missingLabels.push('Valid Quorum');
  } else if (
    selectedCommitteeMeta.value &&
    form.value.quorum > selectedCommitteeMeta.value.memberCount
  ) {
    errors.quorum = `Quorum cannot exceed the ${selectedCommitteeMeta.value.memberCount} members in ${selectedCommitteeMeta.value.name}.`;
    missingLabels.push('Quorum within Committee Size');
  }

  if (!form.value.no_floor) {
    if (form.value.minimum_amount === null || form.value.minimum_amount < 0) {
      errors.minimum_amount = 'Minimum floor amount cannot be negative.';
      missingLabels.push('Valid Floor Amount');
    }
  }

  if (!form.value.is_unlimited) {
    if (form.value.maximum_amount === null || form.value.maximum_amount <= 0) {
      errors.maximum_amount = 'Provide a ceiling amount or enable Unlimited Ceiling.';
      missingLabels.push('Maximum Ceiling Amount');
    } else if (
      !form.value.no_floor &&
      form.value.minimum_amount !== null &&
      form.value.maximum_amount < form.value.minimum_amount
    ) {
      errors.maximum_amount = 'Ceiling amount must be greater than or equal to the floor amount.';
      missingLabels.push('Ceiling >= Floor Amount');
    }
  }

  if (!form.value.effective_from) {
    errors.effective_from = 'Effective From date is required.';
    missingLabels.push('Effective From Date');
  }
  if (
    form.value.effective_to &&
    form.value.effective_from &&
    form.value.effective_to < form.value.effective_from
  ) {
    errors.effective_to = 'Effective To date must be on or after Effective From.';
    missingLabels.push('Valid Effective Period');
  }

  fieldErrors.value = errors;

  if (missingLabels.length > 0) {
    toast.error('Please check the mandate details', `Review: ${missingLabels.join(', ')}.`);
    return;
  }

  const committeeId = Number(form.value.committee_id);
  const committee = getCoreCommittee(committeeId);
  const purpose = form.value.purpose as ProcurementCommitteePurpose;
  const minAmount = form.value.no_floor ? null : Number(form.value.minimum_amount ?? 0);
  const maxAmount = form.value.is_unlimited ? null : Number(form.value.maximum_amount);
  const categoryId = form.value.procurement_category_id
    ? Number(form.value.procurement_category_id)
    : null;
  const unitId = form.value.procurement_unit_id ? Number(form.value.procurement_unit_id) : null;
  const categoryName = categoryId
    ? categoryScopeOptions.find((c) => Number(c.value) === categoryId)?.label
    : undefined;
  const unitName = unitId
    ? unitScopeOptions.find((u) => Number(u.value) === unitId)?.label
    : undefined;

  if (editingId.value) {
    const idx = committeeMandatesStore.value.findIndex((m) => m.id === editingId.value);
    if (idx !== -1) {
      const existing = committeeMandatesStore.value[idx];
      committeeMandatesStore.value[idx] = {
        ...existing,
        committee_id: committeeId,
        committee_code: committee?.code ?? `COM-${committeeId}`,
        committee_name: committee?.name ?? `Committee #${committeeId}`,
        committee_chair: committee?.chair ?? 'Committee Chair',
        committee_member_count: committee?.memberCount ?? Math.max(form.value.quorum, 3),
        purpose,
        quorum: Number(form.value.quorum),
        minimum_amount: minAmount,
        maximum_amount: maxAmount,
        procurement_category_id: categoryId,
        category_name: categoryName,
        procurement_unit_id: unitId,
        unit_name: unitName,
        effective_from: form.value.effective_from,
        effective_to: form.value.effective_to ? form.value.effective_to : null,
        entity_id: Number(form.value.entity_id) || 2,
        notes: form.value.notes.trim()
      };
    }
  } else {
    const nextId = Math.max(0, ...committeeMandatesStore.value.map((m) => m.id)) + 1;
    committeeMandatesStore.value.unshift({
      id: nextId,
      uuid: `pcm-${String(nextId).padStart(4, '0')}-${purpose}`,
      committee_id: committeeId,
      committee_code: committee?.code ?? `COM-${committeeId}`,
      committee_name: committee?.name ?? `Committee #${committeeId}`,
      committee_chair: committee?.chair ?? 'Committee Chair',
      committee_member_count: committee?.memberCount ?? Math.max(form.value.quorum, 3),
      purpose,
      quorum: Number(form.value.quorum),
      minimum_amount: minAmount,
      maximum_amount: maxAmount,
      currency_code: 'ETB',
      procurement_category_id: categoryId,
      category_name: categoryName,
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
    editingId.value ? 'Committee mandate updated' : 'Committee mandate created',
    `${committee?.name ?? 'Committee'} assigned to ${getPurposeLabel(purpose)} with quorum ${form.value.quorum}.`
  );
  router.push('/procurement/committee-mandates');
};
</script>

<template>
  <div class="mandate-create-page">
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

    <!-- ═══ MASTER CONFIGURATION CARD (Zero Section Titles) ═══ -->
    <div class="clean-card form-card-body">
      <!-- Row 1: Core Committee, Procurement Purpose, Quorum -->
      <div class="form-grid-3">
        <FormSelect
          v-model="form.committee_id"
          label="Core Committee"
          :options="coreCommitteeOptions"
          placeholder="Select Committee"
          :error="fieldErrors.committee_id"
          required
        />

        <FormSelect
          v-model="form.purpose"
          label="Procurement Purpose"
          :options="committeePurposeOptions"
          placeholder="Select Purpose"
          :error="fieldErrors.purpose"
          required
        />

        <FormInput
          v-model.number="form.quorum"
          type="number"
          label="Minimum Quorum"
          :helper-text="quorumHelperText"
          :error="fieldErrors.quorum"
          required
        />
      </div>

      <!-- Row 2: Event Value Band — Expandable Checkbox Cards (Collapsed: #FAFAFA, Expanded: #FFFFFF) -->
      <div class="checkbox-cards-grid">
        <FormCheckboxCard
          v-model="form.no_floor"
          :expand-when-checked="false"
          label="No Minimum Floor"
          description="Mandate applies starting from any event value with no lower threshold."
        >
          <FormInput
            v-model.number="form.minimum_amount"
            type="number"
            label="Minimum Event Value (ETB)"
            :error="fieldErrors.minimum_amount"
            required
          />
        </FormCheckboxCard>

        <FormCheckboxCard
          v-model="form.is_unlimited"
          :expand-when-checked="false"
          label="Unlimited / Open Ceiling"
          description="Mandate covers all event values at or above the floor with no upper limit."
        >
          <FormInput
            v-model.number="form.maximum_amount"
            type="number"
            label="Maximum Event Value (ETB)"
            :error="fieldErrors.maximum_amount"
            required
          />
        </FormCheckboxCard>
      </div>

      <!-- Row 3: Resolution Scope & Owning Entity -->
      <div class="form-grid-3">
        <FormSelect
          v-model="form.procurement_category_id"
          label="Procurement Category Scope"
          :options="fullCategoryOptions"
          placeholder="Select Category"
          helper-text="Resolution precedence: Category -> Unit -> Entity -> Value Band."
        />

        <FormSelect
          v-model="form.procurement_unit_id"
          label="Procurement Unit Scope"
          :options="fullUnitOptions"
          placeholder="Select Unit"
          helper-text="Leave as All Buying Units for an entity-wide committee mandate."
        />

        <FormSelect
          v-model="form.entity_id"
          label="Owning Legal Entity"
          :options="entityOptions"
          placeholder="Select Entity"
          required
        />
      </div>

      <!-- Row 4: Effective Dates -->
      <div class="form-grid-3">
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
          helper-text="Leave blank if the mandate remains in force indefinitely."
          :error="fieldErrors.effective_to"
        />
      </div>
    </div>

    <!-- ═══ DEDICATED COLLAPSIBLE CARD: MANDATE GUIDELINES ═══ -->
    <div class="clean-card accordion-card">
      <div
        class="card-accordion-header"
        :class="{ 'is-collapsed': !isNotesOpen }"
        @click="isNotesOpen = !isNotesOpen"
      >
        <span class="card-accordion-title">Mandate Guidelines</span>
        <ChevronDown v-if="isNotesOpen" :size="16" class="header-chevron" />
        <ChevronRight v-else :size="16" class="header-chevron" />
      </div>

      <div v-show="isNotesOpen" class="card-accordion-body">
        <FormRichText
          v-model="form.notes"
          placeholder="Document voting rules, conflict-of-interest declarations, attendance sign-off requirements, or escalation terms for this committee mandate..."
          :max-length="5000"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.mandate-create-page {
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

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 20px;
  align-items: start;
}

.checkbox-cards-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 20px;
  align-items: start;
}

/* Dedicated Collapsible Accordion Card */
.accordion-card {
  overflow: hidden;
  border-radius: 12px;
}

.card-accordion-header {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 4px;
  padding: 16px 24px;
  cursor: pointer;
  user-select: none;
  font-size: 14px;
  font-weight: 600;
  color: #404040;
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

@media (max-width: 1024px) {
  .form-grid-3 {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 768px) {
  .form-grid-3,
  .checkbox-cards-grid {
    grid-template-columns: 1fr;
  }

  .create-top-bar {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>

