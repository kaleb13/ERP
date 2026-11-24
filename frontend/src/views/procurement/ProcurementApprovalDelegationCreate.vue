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
  approvalDelegationsStore,
  type ApprovalDelegationRecord,
  type DelegationType,
  type DelegationStatus,
  delegationTypeOptions,
  delegationDocTypeOptions,
  delegatorUserOptions,
  delegateUserOptions
} from './procurementApprovalDelegationData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

const editingId = computed(() => (route.query.editId ? Number(route.query.editId) : (route.params.id ? Number(route.params.id) : null)));
const isSaved = ref(false);
const isNotesOpen = ref(true);

const fieldErrors = ref<{
  delegator_user_id?: string;
  delegate_user_id?: string;
  valid_from?: string;
  valid_to?: string;
  type_lookup_value_id?: string;
  maximum_amount?: string;
}>({});

const form = ref({
  delegator_user_id: '',
  delegate_user_id: '',
  type_lookup_value_id: 'planned_leave' as DelegationType,
  document_type_id: '',
  valid_from: new Date().toISOString().split('T')[0],
  valid_to: new Date(Date.now() + 14 * 86400000).toISOString().split('T')[0],
  is_unlimited: true,
  maximum_amount: null as number | null,
  delegation_status_lookup_value_id: 'active' as DelegationStatus,
  document_number: '',
  note: ''
});

// Filter delegate options to exclude selected delegator (segregation of duties)
const filteredDelegateOptions = computed(() => {
  if (!form.value.delegator_user_id) return delegateUserOptions;
  return delegateUserOptions.filter((d) => d.value !== form.value.delegator_user_id);
});

// Breadcrumbs
const breadcrumbItems = computed<BreadcrumbItem[]>(() => [
  { label: 'Approval & Assignment Rules', to: '/procurement/routing-rules?tab=delegations' },
  { label: editingId.value ? 'Edit Approval Delegation' : 'Create Approval Delegation' }
]);

watch(
  form,
  () => {
    isSaved.value = false;
    if (form.value.delegator_user_id) fieldErrors.value.delegator_user_id = undefined;
    if (form.value.delegate_user_id) fieldErrors.value.delegate_user_id = undefined;
    if (form.value.valid_from) fieldErrors.value.valid_from = undefined;
    if (form.value.valid_to) fieldErrors.value.valid_to = undefined;
    if (form.value.type_lookup_value_id) fieldErrors.value.type_lookup_value_id = undefined;
    if (form.value.is_unlimited || (form.value.maximum_amount !== null && form.value.maximum_amount >= 0)) {
      fieldErrors.value.maximum_amount = undefined;
    }
  },
  { deep: true }
);

watch(
  () => form.value.is_unlimited,
  (val) => {
    if (val) {
      form.value.maximum_amount = null;
      fieldErrors.value.maximum_amount = undefined;
    } else if (form.value.maximum_amount === null) {
      form.value.maximum_amount = 50000;
    }
  }
);

onMounted(() => {
  if (editingId.value) {
    const existing = approvalDelegationsStore.value.find((r) => r.id === editingId.value);
    if (existing) {
      form.value = {
        delegator_user_id: String(existing.delegator_user_id),
        delegate_user_id: String(existing.delegate_user_id),
        type_lookup_value_id: existing.type_lookup_value_id,
        document_type_id: existing.document_type_id || '',
        valid_from: existing.valid_from,
        valid_to: existing.valid_to,
        is_unlimited: existing.maximum_amount === null,
        maximum_amount: existing.maximum_amount,
        delegation_status_lookup_value_id: existing.delegation_status_lookup_value_id,
        document_number: existing.document_number || '',
        note: existing.note || ''
      };
      if (existing.note) {
        isNotesOpen.value = true;
      }
      isSaved.value = true;
    }
    return;
  }

  // Handle pre-filled values from QuickCreateModal
  if (route.query.delegator_user_id) {
    form.value.delegator_user_id = String(route.query.delegator_user_id);
  }
  if (route.query.delegate_user_id) {
    form.value.delegate_user_id = String(route.query.delegate_user_id);
  }
  if (route.query.type_lookup_value_id) {
    form.value.type_lookup_value_id = route.query.type_lookup_value_id as DelegationType;
  }
  if (route.query.valid_from) {
    form.value.valid_from = String(route.query.valid_from);
  }
  if (route.query.valid_to) {
    form.value.valid_to = String(route.query.valid_to);
  }
});

const clearForm = () => {
  form.value = {
    delegator_user_id: '',
    delegate_user_id: '',
    type_lookup_value_id: 'planned_leave',
    document_type_id: '',
    valid_from: new Date().toISOString().split('T')[0],
    valid_to: new Date(Date.now() + 14 * 86400000).toISOString().split('T')[0],
    is_unlimited: true,
    maximum_amount: null,
    delegation_status_lookup_value_id: 'active',
    document_number: '',
    note: ''
  };
  fieldErrors.value = {};
  isSaved.value = false;
  toast.info('Form cleared.');
};

const validate = (): boolean => {
  const errors: Record<string, string> = {};
  let isValid = true;

  if (!form.value.delegator_user_id) {
    errors.delegator_user_id = 'Absent approver is required.';
    isValid = false;
  }
  if (!form.value.delegate_user_id) {
    errors.delegate_user_id = 'Acting delegate is required.';
    isValid = false;
  } else if (form.value.delegator_user_id && form.value.delegator_user_id === form.value.delegate_user_id) {
    errors.delegate_user_id = 'Delegate cannot be the same user as the absent approver.';
    isValid = false;
  }

  if (!form.value.valid_from) {
    errors.valid_from = 'Start date is required.';
    isValid = false;
  }
  if (!form.value.valid_to) {
    errors.valid_to = 'End date is required.';
    isValid = false;
  } else if (form.value.valid_from && form.value.valid_to < form.value.valid_from) {
    errors.valid_to = 'End date cannot precede start date.';
    isValid = false;
  }

  if (!form.value.type_lookup_value_id) {
    errors.type_lookup_value_id = 'Delegation reason is required.';
    isValid = false;
  }

  if (!form.value.is_unlimited) {
    if (form.value.maximum_amount === null || form.value.maximum_amount < 0) {
      errors.maximum_amount = 'Please enter a valid ceiling amount or enable Full Authority.';
      isValid = false;
    }
  }

  fieldErrors.value = errors;
  if (!isValid) {
    toast.error('Validation failed. Please correct the highlighted fields.');
  }
  return isValid;
};

const handleSave = () => {
  if (!validate()) return;

  const delegator = delegatorUserOptions.find((u) => u.value === form.value.delegator_user_id);
  const delegate = delegateUserOptions.find((u) => u.value === form.value.delegate_user_id);
  const docType = delegationDocTypeOptions.find((d) => d.value === form.value.document_type_id);

  if (editingId.value) {
    const idx = approvalDelegationsStore.value.findIndex((r) => r.id === editingId.value);
    if (idx !== -1) {
      approvalDelegationsStore.value[idx] = {
        ...approvalDelegationsStore.value[idx],
        delegator_user_id: Number(form.value.delegator_user_id),
        delegator_name: delegator ? delegator.label.split(' — ')[0] : 'Approver',
        delegator_role: delegator ? delegator.role : 'Approver',
        delegator_avatar: delegator?.avatar,
        delegate_user_id: Number(form.value.delegate_user_id),
        delegate_name: delegate ? delegate.label.split(' — ')[0] : 'Delegate',
        delegate_role: delegate ? delegate.role : 'Delegate',
        delegate_avatar: delegate?.avatar,
        document_type_id: form.value.document_type_id ? form.value.document_type_id : null,
        document_type_name: docType ? docType.label : 'All Documents',
        maximum_amount: form.value.is_unlimited ? null : form.value.maximum_amount,
        valid_from: form.value.valid_from,
        valid_to: form.value.valid_to,
        type_lookup_value_id: form.value.type_lookup_value_id,
        delegation_status_lookup_value_id: form.value.delegation_status_lookup_value_id,
        note: form.value.note
      };
      isSaved.value = true;
      toast.success('Approval delegation updated.');
    }
  } else {
    const nextId = Math.max(0, ...approvalDelegationsStore.value.map((r) => r.id)) + 1;
    approvalDelegationsStore.value.unshift({
      id: nextId,
      uuid: `del-000${nextId}-created`,
      delegator_user_id: Number(form.value.delegator_user_id),
      delegator_name: delegator ? delegator.label.split(' — ')[0] : 'Approver',
      delegator_role: delegator ? delegator.role : 'Approver',
      delegator_avatar: delegator?.avatar,
      delegate_user_id: Number(form.value.delegate_user_id),
      delegate_name: delegate ? delegate.label.split(' — ')[0] : 'Delegate',
      delegate_role: delegate ? delegate.role : 'Delegate',
      delegate_avatar: delegate?.avatar,
      document_type_id: form.value.document_type_id ? form.value.document_type_id : null,
      document_type_name: docType ? docType.label : 'All Documents',
      maximum_amount: form.value.is_unlimited ? null : form.value.maximum_amount,
      currency_code: 'ETB',
      valid_from: form.value.valid_from,
      valid_to: form.value.valid_to,
      type_lookup_value_id: form.value.type_lookup_value_id,
      delegation_status_lookup_value_id: form.value.delegation_status_lookup_value_id,
      document_id: null,
      document_number: `DEL-2026-00${nextId}`,
      note: form.value.note,
      tenant_id: 1,
      entity_id: 2,
      user_id: 10,
      state: 'active'
    });
    isSaved.value = true;
    toast.success('Approval delegation created.');
  }

  router.push('/procurement/routing-rules?tab=delegations');
};
</script>

<template>
  <div class="delegation-create-page">
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

    <!-- ═══ MASTER CONFIGURATION CARD (2-Column Pairs + Dividers) ═══ -->
    <div class="clean-card form-card-body">
      <!-- Pair 1: Absent Approver & Acting Delegate -->
      <div class="form-grid-2">
        <FormSelect
          v-model="form.delegator_user_id"
          label="Absent Approver (Delegator)"
          :options="delegatorUserOptions"
          placeholder="Select Approver"
          :error="fieldErrors.delegator_user_id"
          required
        />

        <FormSelect
          v-model="form.delegate_user_id"
          label="Acting Delegate (Sign-Off Proxy)"
          :options="filteredDelegateOptions"
          placeholder="Select Delegate"
          :error="fieldErrors.delegate_user_id"
          required
        />
      </div>

      <div class="card-row-divider"></div>

      <!-- Pair 2: Delegation Reason & Document Scope -->
      <div class="form-grid-2">
        <FormSelect
          v-model="form.type_lookup_value_id"
          label="Delegation Reason / Type"
          :options="delegationTypeOptions"
          placeholder="Select Type"
          :error="fieldErrors.type_lookup_value_id"
          required
        />

        <FormSelect
          v-model="form.document_type_id"
          label="Document Type Scope"
          :options="delegationDocTypeOptions"
          placeholder="Select Scope"
          helper-text="Leave as 'All Documents' for global procurement authority"
        />
      </div>

      <div class="card-row-divider"></div>

      <!-- Pair 3: Effective Date Window -->
      <div class="form-grid-2">
        <FormInput
          v-model="form.valid_from"
          type="date"
          label="Effective From"
          :error="fieldErrors.valid_from"
          required
        />

        <FormInput
          v-model="form.valid_to"
          type="date"
          label="Effective To"
          :error="fieldErrors.valid_to"
          required
        />
      </div>

      <!-- Dedicated Policy Checkbox Section: Approval Ceiling Limit -->
      <div class="controls-checkbox-grid">
        <FormCheckboxCard
          v-model="form.is_unlimited"
          :expand-when-checked="false"
          label="Full Authority (No Monetary Ceiling)"
          description="Grant the delegate the full approval authority ceiling of the absent approver."
        >
          <div class="conditional-amount-wrapper">
            <FormInput
              v-model.number="form.maximum_amount"
              type="number"
              label="Maximum Approval Ceiling (ETB)"
              placeholder="0.00"
              :error="fieldErrors.maximum_amount"
              helper-text="Disapprovals or documents exceeding this cap require escalation to executive management"
              required
            />
          </div>
        </FormCheckboxCard>
      </div>
    </div>

    <!-- ═══ DEDICATED COLLAPSIBLE CARD: HANDOVER INSTRUCTIONS & AUDIT MEMO ═══ -->
    <div class="clean-card accordion-card">
      <div
        class="card-accordion-header"
        :class="{ 'is-collapsed': !isNotesOpen }"
        @click="isNotesOpen = !isNotesOpen"
      >
        <span class="card-accordion-title">Handover Instructions & Audit Memo</span>
        <ChevronDown v-if="isNotesOpen" :size="16" class="header-chevron" />
        <ChevronRight v-else :size="16" class="header-chevron" />
      </div>

      <div v-show="isNotesOpen" class="card-accordion-body">
        <FormRichText
          v-model="form.note"
          placeholder="Record operational guidelines, critical exceptions, escalation contacts, or formal delegation letters..."
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.delegation-create-page {
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

/* Master Card */
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
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
}

.card-row-divider {
  height: 1px;
  background-color: #e5e5e5;
  width: 100%;
}

/* Dedicated Bottom Policy Checkbox Container (2-Col Half-Width) */
.controls-checkbox-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px 16px;
  padding-top: 16px;
  border-top: 1px solid #f0f0f0;
}

.conditional-amount-wrapper {
  margin-top: 12px;
}

/* Collapsible Accordion Card */
.accordion-card {
  overflow: hidden;
}

.card-accordion-header {
  padding: 16px 24px;
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 4px;
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
</style>
