<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  X, Building2, Briefcase, FileText,
  DollarSign, MoreVertical, CheckCircle2
} from 'lucide-vue-next';;

import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormRichText from '../../components/FormRichText.vue';
import { useToast } from '../../composables/useToast';

import {
  serviceAgreementsData,
  createServiceAgreement,
  updateServiceAgreement,
  type HRServiceAgreementRecord,
  type AgreementType,
  type AgreementState,
  type PayrollResponsibility,
  type ServiceFeeType
} from './serviceAgreementData';

const router = useRouter();
const route = useRoute();

// ─── EDIT MODE DETECTION ──────────────────────────────────────────────────
const editId = computed(() => {
  if (route.params.id) return Number(route.params.id);
  if (route.query.id) return Number(route.query.id);
  return null;
});

const isEditMode = computed(() => editId.value !== null);

// ─── BREADCRUMBS (Rule 3 & 4: Exact Sidebar Page Name > Sub-page) ─────────
const breadcrumbItems = computed(() => [
  { label: 'HR Service Agreements', to: '/hr/service-agreements' },
  { label: isEditMode.value ? 'Edit Service Agreement' : 'Create Service Agreement' }
]);

// ─── SAVE STATE & TOAST ───────────────────────────────────────────────────
const { toast } = useToast();
const isSaved = ref(false);

const showToast = (msg: string) => {
  toast.success(msg);
};

// ─── MORE MENU DROPDOWN (Rule 4: Draft state support) ─────────────────────
const isMoreMenuOpen = ref(false);
const toggleMoreMenu = () => {
  isMoreMenuOpen.value = !isMoreMenuOpen.value;
};
const closeMoreMenu = () => {
  isMoreMenuOpen.value = false;
};

// ─── FORM DATA MODEL (Strict 1:1 Schema Mapping) ──────────────────────────
const formData = ref<{
  provider_entity_id: number;
  client_party_id: number;
  client_entity_id: number | null;
  agreement_type_lookup_value_id: AgreementType;
  agreement_state_lookup_value_id: AgreementState;
  start_date: string;
  end_date: string;
  max_employees: number | null;
  payroll_responsibility_lookup_value_id: PayrollResponsibility;
  service_fee_type_lookup_value_id: ServiceFeeType;
  service_fee_value: number | null;
  billing_currency_id: number;
  notes: string;
}>({
  provider_entity_id: 20,
  client_party_id: 940,
  client_entity_id: 1,
  agreement_type_lookup_value_id: 'staffing',
  agreement_state_lookup_value_id: 'active',
  start_date: new Date().toISOString().substring(0, 10),
  end_date: '',
  max_employees: 25,
  payroll_responsibility_lookup_value_id: 'client_funds_employer_pays',
  service_fee_type_lookup_value_id: 'percent_of_payroll',
  service_fee_value: 8.0,
  billing_currency_id: 1,
  notes: ''
});

// ─── OPTIONS CATALOGS ─────────────────────────────────────────────────────
const providerOptions = [
  { value: 20, label: 'Selam Workforce Solutions Ltd. (Entity #20)' },
  { value: 1, label: 'Haleta Corporate Headquarters (Entity #1)' },
  { value: 3, label: 'Haleta Addis Ababa Branch (Entity #3)' }
];

const clientPartyOptions = [
  { value: 940, label: 'Haleta Retail Group S.C. (Party #940)' },
  { value: 960, label: 'Nyala Insurance Share Company (Party #960)' },
  { value: 961, label: 'Habesha Breweries S.C. (Party #961)' },
  { value: 962, label: 'Zafir Hotels & Resorts PLC (Party #962)' },
  { value: 963, label: 'Ethiopian Airlines Group (Party #963)' },
  { value: 964, label: 'Commercial Bank of Ethiopia (Party #964)' }
];

const clientEntityOptions = [
  { value: 0, label: 'None (External Client / Sales Invoice Billing)' },
  { value: 1, label: 'Haleta Corporate Headquarters (Tenant Entity #1)' },
  { value: 3, label: 'Haleta Addis Ababa Branch (Tenant Entity #3)' }
];

const agreementTypeOptions = [
  { value: 'staffing', label: 'Staffing Supply (Dedicated Leased Personnel)' },
  { value: 'outsourcing', label: 'Operations Outsourcing (Deliverable-Based Service)' },
  { value: 'employer_of_record', label: 'Employer of Record - EOR (Legal Employment Host)' },
  { value: 'secondment_out', label: 'Secondment Outbound (Temporary Executive Lending)' },
  { value: 'consultancy', label: 'Workforce Consultancy (Specialized Project Advisory)' }
];

const payrollRespOptions = [
  { value: 'client_funds_employer_pays', label: 'Provider Runs Payroll & Client Funds / Reimburses' },
  { value: 'employer_pays', label: 'Provider Directly Runs & Funds Payroll' },
  { value: 'client_pays_directly', label: 'Client Direct Payroll (Client entity disburses wages)' }
];

const feeTypeOptions = [
  { value: 'percent_of_payroll', label: 'Percentage Markup on Gross Payroll (Cost-Plus %)' },
  { value: 'fixed_per_employee', label: 'Fixed Monthly Fee per Deployed Employee' },
  { value: 'fixed_monthly', label: 'Fixed Monthly Retainer Amount' },
  { value: 'markup_percent', label: 'Standard Percentage Margin' }
];

const currencyOptions = [
  { value: 1, label: 'ETB - Ethiopian Birr' },
  { value: 2, label: 'USD - United States Dollar' },
  { value: 3, label: 'EUR - Euro' }
];

// Helper provider & client names
const selectedProviderName = computed(() => {
  const p = providerOptions.find(o => o.value === formData.value.provider_entity_id);
  return p ? p.label.split(' (')[0] : 'Selam Workforce Solutions Ltd.';
});

const selectedClientPartyName = computed(() => {
  const c = clientPartyOptions.find(o => o.value === formData.value.client_party_id);
  return c ? c.label.split(' (')[0] : 'Client Organization';
});

// ─── INITIALIZATION / EDIT PREFILL ────────────────────────────────────────
onMounted(() => {
  if (editId.value) {
    const existing = serviceAgreementsData.value.find(a => a.id === editId.value);
    if (existing) {
      formData.value = {
        provider_entity_id: existing.provider_entity_id,
        client_party_id: existing.client_party_id,
        client_entity_id: existing.client_entity_id ?? 0,
        agreement_type_lookup_value_id: existing.agreement_type_lookup_value_id,
        agreement_state_lookup_value_id: existing.agreement_state_lookup_value_id,
        start_date: existing.start_date,
        end_date: existing.end_date || '',
        max_employees: existing.max_employees,
        payroll_responsibility_lookup_value_id: existing.payroll_responsibility_lookup_value_id,
        service_fee_type_lookup_value_id: existing.service_fee_type_lookup_value_id || 'percent_of_payroll',
        service_fee_value: existing.service_fee_value,
        billing_currency_id: existing.billing_currency_id,
        notes: existing.notes || ''
      };
      isSaved.value = true;
    }
  }
});

// ─── SAVE HANDLER (Rule 27: Plain text Save button) ───────────────────────
const handleSave = (stateOverride?: AgreementState) => {
  if (!formData.value.provider_entity_id || !formData.value.client_party_id) {
    alert('Please select both the Provider Entity and the Client Party.');
    return;
  }
  if (!formData.value.start_date) {
    alert('Please specify the agreement effective start date.');
    return;
  }

  const finalState = stateOverride || formData.value.agreement_state_lookup_value_id;
  const clientEntityVal = formData.value.client_entity_id === 0 ? null : formData.value.client_entity_id;

  if (isEditMode.value && editId.value) {
    updateServiceAgreement(editId.value, {
      provider_entity_id: formData.value.provider_entity_id,
      provider_name: selectedProviderName.value,
      client_party_id: formData.value.client_party_id,
      client_party_name: selectedClientPartyName.value,
      client_entity_id: clientEntityVal,
      client_entity_name: clientEntityVal ? 'Haleta Corporate Headquarters' : null,
      agreement_type_lookup_value_id: formData.value.agreement_type_lookup_value_id,
      agreement_state_lookup_value_id: finalState,
      start_date: formData.value.start_date,
      end_date: formData.value.end_date || null,
      max_employees: formData.value.max_employees ? Number(formData.value.max_employees) : null,
      payroll_responsibility_lookup_value_id: formData.value.payroll_responsibility_lookup_value_id,
      service_fee_type_lookup_value_id: formData.value.service_fee_type_lookup_value_id,
      service_fee_value: formData.value.service_fee_value ? Number(formData.value.service_fee_value) : null,
      billing_currency_id: formData.value.billing_currency_id,
      billing_currency_code: formData.value.billing_currency_id === 1 ? 'ETB' : (formData.value.billing_currency_id === 2 ? 'USD' : 'EUR'),
      notes: formData.value.notes.trim() || null
    });
    isSaved.value = true;
    showToast('Service Agreement updated successfully.');
  } else {
    createServiceAgreement({
      tenant_id: 1,
      provider_entity_id: formData.value.provider_entity_id,
      provider_name: selectedProviderName.value,
      client_party_id: formData.value.client_party_id,
      client_party_name: selectedClientPartyName.value,
      client_entity_id: clientEntityVal,
      client_entity_name: clientEntityVal ? 'Haleta Corporate Headquarters' : null,
      agreement_type_lookup_value_id: formData.value.agreement_type_lookup_value_id,
      agreement_state_lookup_value_id: finalState,
      start_date: formData.value.start_date,
      end_date: formData.value.end_date || null,
      max_employees: formData.value.max_employees ? Number(formData.value.max_employees) : null,
      payroll_responsibility_lookup_value_id: formData.value.payroll_responsibility_lookup_value_id,
      service_fee_type_lookup_value_id: formData.value.service_fee_type_lookup_value_id,
      service_fee_value: formData.value.service_fee_value ? Number(formData.value.service_fee_value) : null,
      billing_currency_id: formData.value.billing_currency_id,
      billing_currency_code: formData.value.billing_currency_id === 1 ? 'ETB' : (formData.value.billing_currency_id === 2 ? 'USD' : 'EUR'),
      notes: formData.value.notes.trim() || null,
      user_id: 7,
      state: 'active'
    });
    isSaved.value = true;
    showToast('Service Agreement created successfully.');
  }

  setTimeout(() => {
    router.push('/hr/service-agreements');
  }, 900);
};

const handleSaveDraft = () => {
  closeMoreMenu();
  handleSave('draft');
};

const handleClear = () => {
  if (confirm('Are you sure you want to clear this creation form?')) {
    formData.value = {
      provider_entity_id: 20,
      client_party_id: 940,
      client_entity_id: 1,
      agreement_type_lookup_value_id: 'staffing',
      agreement_state_lookup_value_id: 'active',
      start_date: new Date().toISOString().substring(0, 10),
      end_date: '',
      max_employees: 25,
      payroll_responsibility_lookup_value_id: 'client_funds_employer_pays',
      service_fee_type_lookup_value_id: 'percent_of_payroll',
      service_fee_value: 8.0,
      billing_currency_id: 1,
      notes: ''
    };
    isSaved.value = false;
  }
};
</script>

<template>
  <div class="service-agreement-create-page" @click="closeMoreMenu">
    <!-- Top Action Bar (Rule 4) -->
    <div class="top-action-bar">
      <div class="left-nav-meta">
        <AppBreadcrumb :items="breadcrumbItems">
          <template #badge>
            <SaveStateBadge :saved="isSaved" />
          </template>
        </AppBreadcrumb>
      </div>

      <div class="right-actions-cluster" @click.stop>
        <!-- 3-Dots More Menu for Draft State (Rule 4) -->
        <div class="relative-more-dropdown">
          <AppButton
            variant="outline"
            size="sm"
            iconOnly
            title="More Options"
            @click="toggleMoreMenu"
          >
            <MoreVertical :size="16" />
          </AppButton>

          <div v-if="isMoreMenuOpen" class="more-dropdown-menu">
            <button
              type="button"
              class="dropdown-action-btn"
              @click="handleSaveDraft"
            >
              <FileText :size="14" />
              <span>Save as Draft</span>
            </button>
          </div>
        </div>

        <!-- Clear Form Secondary Button -->
        <AppButton
          variant="outline"
          size="sm"
          @click="handleClear"
        >
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>

        <!-- Save Primary Button (Rule 27: Plain text "Save", zero icon) -->
        <AppButton
          variant="primary"
          size="sm"
          @click="() => handleSave()"
        >
          Save
        </AppButton>
      </div>
    </div>

    <!-- Master Form Cards Container (Single Page Stacked Flow) -->
    <div class="form-cards-layout">
      <!-- Card 1: Contracting Entities & Multi-Entity Tenancy -->
      <div class="creation-card">
        <div class="card-header">
          <Building2 :size="18" class="card-header-icon" />
          <div class="card-header-text">
            <h3 class="card-title">Contracting Entities & Tenancy Model</h3>
            <p class="card-subtitle">
              Establish the legal employing provider, client commercial counterparty, and optional internal tenant mapping.
            </p>
          </div>
        </div>

        <div class="form-grid-3">
          <!-- Provider Entity -->
          <FormSelect
            v-model="formData.provider_entity_id"
            label="Provider Entity (Legal Employer)"
            :options="providerOptions"
            required
          />

          <!-- Client Party -->
          <FormSelect
            v-model="formData.client_party_id"
            label="Client Party (Commercial Counterparty)"
            :options="clientPartyOptions"
            required
          />

          <!-- Client Entity (Tenancy Separation Principle) -->
          <FormSelect
            v-model="formData.client_entity_id"
            label="Linked Internal Tenant Entity (Optional)"
            :options="clientEntityOptions"
            hint="Set only if the client organization is also an active tenant entity within Haleta multi-tenancy."
          />
        </div>
      </div>

      <!-- Card 2: Classification, Term & Placement Capacity -->
      <div class="creation-card">
        <div class="card-header">
          <Briefcase :size="18" class="card-header-icon" />
          <div class="card-header-text">
            <h3 class="card-title">Agreement Classification & Term Timeline</h3>
            <p class="card-subtitle">
              Define the service operational model, binding contract period, and maximum placement headcount.
            </p>
          </div>
        </div>

        <div class="form-grid-4">
          <!-- Agreement Type -->
          <FormSelect
            v-model="formData.agreement_type_lookup_value_id"
            label="Agreement Operational Type"
            :options="agreementTypeOptions"
            required
          />

          <!-- Start Date -->
          <FormInput
            v-model="formData.start_date"
            type="date"
            label="Effective Start Date"
            required
          />

          <!-- End Date (Optional for open-ended) -->
          <FormInput
            v-model="formData.end_date"
            type="date"
            label="End Date (Blank = Open-Ended)"
          />

          <!-- Headcount Placement Ceiling -->
          <FormInput
            v-model="formData.max_employees"
            type="number"
            label="Headcount Ceiling (Staff Max)"
            hint="Leave blank if agreement permits unlimited staffing capacity."
          />
        </div>
      </div>

      <!-- Card 3: Commercial & Billing Terms -->
      <div class="creation-card">
        <div class="card-header">
          <DollarSign :size="18" class="card-header-icon" />
          <div class="card-header-text">
            <h3 class="card-title">Payroll Governance & Service Fee Model</h3>
            <p class="card-subtitle">
              Configure payroll funding flows, commercial service charge structures, and invoicing currencies.
            </p>
          </div>
        </div>

        <div class="form-grid-4">
          <!-- Payroll Responsibility -->
          <FormSelect
            v-model="formData.payroll_responsibility_lookup_value_id"
            label="Payroll Governance Flow"
            :options="payrollRespOptions"
            required
          />

          <!-- Service Fee Model -->
          <FormSelect
            v-model="formData.service_fee_type_lookup_value_id"
            label="Service Fee Calculation Model"
            :options="feeTypeOptions"
            required
          />

          <!-- Service Fee Value -->
          <FormInput
            v-model="formData.service_fee_value"
            type="number"
            label="Fee Value / Rate (% or Amount)"
            hint="Percentage rate (e.g. 8.0%) or monetary figure depending on fee model."
            required
          />

          <!-- Billing Currency -->
          <FormSelect
            v-model="formData.billing_currency_id"
            label="Settlement Currency"
            :options="currencyOptions"
            required
          />
        </div>
      </div>

      <!-- Card 4: Scope & SLA Notes -->
      <div class="creation-card">
        <div class="card-header">
          <FileText :size="18" class="card-header-icon" />
          <div class="card-header-text">
            <h3 class="card-title">Scope of Work, SLA & Statutory Notes</h3>
            <p class="card-subtitle">
              Detail specific job categories supplied, client operational requirements, and regulatory compliance stipulations.
            </p>
          </div>
        </div>

        <!-- Standardized WYSIWYG Editor Container -->
        <!-- Standardized Rich Text Component -->
        <FormRichText
          v-model="formData.notes"
          placeholder="Detail specific job categories supplied, client operational requirements, and regulatory compliance stipulations..."
          :max-length="5000"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.service-agreement-create-page {
  padding: 0;
  background-color: #f8fafc;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
}

/* Top Action Bar (Rule 4) */
.top-action-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding-bottom: 4px;
}

.left-nav-meta {
  display: flex;
  align-items: center;
  gap: 14px;
}

.right-actions-cluster {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* More Dots Menu */
.relative-more-dropdown {
  position: relative;
}

.btn-more-dots {
  width: 36px;
  height: 36px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-more-dots:hover {
  background-color: #f1f5f9;
  border-color: #cbd5e1;
}

.more-dropdown-menu {
  position: absolute;
  left: 0;
  top: calc(100% + 4px);
  width: 170px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  padding: 4px;
  z-index: 50;
  display: flex;
  flex-direction: column;
}

.dropdown-action-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 10px;
  border: none;
  background: transparent;
  border-radius: 6px;
  font-size: 13px;
  color: #404040;
  cursor: pointer;
  text-align: left;
}

.dropdown-action-btn:hover {
  background-color: #f1f5f9;
  color: #0b529c;
}

/* Secondary Button (Clear Form) */
.btn-secondary-clear {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 14px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-secondary-clear:hover {
  background-color: #fef2f2;
  border-color: #fecaca;
  color: #dc2626;
}

/* Primary Button (Rule 27: strictly plain text "Save", zero icons) */
.btn-primary-save {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 36px;
  padding: 0 24px;
  background-color: #0b529c;
  border: none;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  color: #ffffff;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-primary-save:hover {
  background-color: #083e77;
}

/* Form Tabs */
.form-tabs-container {
  display: flex;
}

/* Cards Layout */
.form-cards-layout {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.tab-pane {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.creation-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 20px 24px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.card-header {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.card-header-icon {
  color: #0b529c;
  margin-top: 2px;
}

.card-header-text {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.card-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.card-subtitle {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

/* Grids */
.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

.form-grid-4 {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

@media (max-width: 1024px) {
  .form-grid-3,
  .form-grid-4 {
    grid-template-columns: 1fr;
  }
}

/* Rich Editor Wrapper */
.rich-editor-wrapper {
  display: flex;
  flex-direction: column;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  background-color: #ffffff;
}

.editor-toolbar {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 6px 10px;
  background-color: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}

.editor-tool-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  border-radius: 4px;
  color: #64748b;
  cursor: pointer;
  transition: all 0.12s;
}

.editor-tool-btn:hover {
  background-color: #e2e8f0;
  color: #404040;
}

.toolbar-sep {
  width: 1px;
  height: 16px;
  background-color: #cbd5e1;
  margin: 0 4px;
}

.editor-textarea {
  width: 100%;
  padding: 12px 14px;
  border: none;
  font-size: 13.5px;
  font-family: inherit;
  color: #404040;
  line-height: 1.5;
  resize: vertical;
  outline: none;
}

.editor-footer {
  display: flex;
  justify-content: flex-end;
  padding: 6px 12px;
  background-color: #f8fafc;
  border-top: 1px solid #f1f5f9;
}

.char-counter {
  font-size: 11.5px;
  color: #737373;
}
</style>
