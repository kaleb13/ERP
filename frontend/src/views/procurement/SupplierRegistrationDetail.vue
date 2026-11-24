<!--
  ══════════════════════════════════════════════════════════════════════════════
  HALETA ERP DETAIL PAGE — ARCHETYPE 1: TWO-COLUMN SPLIT WORKFLOW DETAIL
  (detail-pages.instructions.md): left dossier + right 360px Approver Decision /
  Registration Steps rail (collapsible to 68px via Focus). Breadcrumb has zero
  buttons; Edit/Delete live in the directory 3-dot menu. Schema: SupplierRegistration
  + SupplierRegistrationCategory (procurement-v4.sql #3).
  ══════════════════════════════════════════════════════════════════════════════
-->
<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRoute } from 'vue-router';
import {
  PanelRightClose, PanelRightOpen, Check, Clock, X,
  ChevronDown, ChevronRight, MoreVertical
} from 'lucide-vue-next';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseAvatar from '../../components/BaseAvatar.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import BaseDropdownMenu, { type DropdownMenuItem } from '../../components/BaseDropdownMenu.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import { useToast } from '../../composables/useToast';
import { formatDisplayDate } from '../../utils/dateFormat';
import {
  supplierRegistrationsStore,
  supplierRegistrationCategoriesStore,
  type SupplierRegistrationStatus,
  type SupplierRegistrationCategoryRecord,
  resolutionOptions,
  getRegistrationCategories,
  getRegistrationDocuments,
  getRegistrationPortalUsers,
  getDocumentTypeLabel,
  getStatusLabel,
  getStatusBadgeColor,
  getBusinessTypeLabel,
  getOriginLabel,
  getEntityLabel,
  getFiscalYearLabel,
  getCategoryLabel,
  getCategoryDecisionLabel,
  getCategoryDecisionColor,
  maskAccountNumber
} from './supplierRegistrationData';

const route = useRoute();
const { toast } = useToast();

const registrationId = computed(() => Number(route.params.id));
const registration = computed(() =>
  supplierRegistrationsStore.value.find((r) => r.id === registrationId.value)
);
const categories = computed(() => getRegistrationCategories(registrationId.value));
const documents = computed(() => getRegistrationDocuments(registrationId.value));
const portalUsers = computed(() => getRegistrationPortalUsers(registrationId.value));
const status = computed<SupplierRegistrationStatus>(
  () => registration.value?.supplier_registration_status_lookup_value_id ?? 'draft'
);

const formattedMaxOrderValue = computed(() => {
  const reg = registration.value;
  if (!reg || reg.maximum_order_value === null) return 'No maximum cap';
  return `${reg.currency_id || 'ETB'} ${reg.maximum_order_value.toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })}`;
});

const getCategoryActionItems = (cat: SupplierRegistrationCategoryRecord): DropdownMenuItem[] => [
  {
    key: 'grant',
    label: 'Grant Category',
    icon: Check,
    onClick: () => {
      cat.is_approved = true;
      toast.success(`${getCategoryLabel(cat.procurement_category_id)} granted.`);
    }
  },
  {
    key: 'decline',
    label: 'Decline Category',
    icon: X,
    destructive: true,
    onClick: () => {
      cat.is_approved = false;
      toast.info(`${getCategoryLabel(cat.procurement_category_id)} declined.`);
    }
  }
];

const breadcrumbItems = computed<BreadcrumbItem[]>(() => [
  { label: 'Supplier Registrations', to: '/procurement/supplier-registrations' },
  { label: registration.value ? registration.value.registration_number : 'Registration Detail' }
]);

// ─── Rail State ──────────────────────────────────────────────────────────────
const isRailCollapsed = ref(false);
const isDecisionNoteOpen = ref(true);

// ─── Approver Decision ───────────────────────────────────────────────────────
const resolution = ref('');
const remark = ref('');
const decisionErrors = ref<{ resolution?: string; remark?: string }>({});

const canDecide = computed(() => status.value === 'pending_review');

const submitDecision = () => {
  const reg = registration.value;
  if (!reg) return;

  const errors: typeof decisionErrors.value = {};
  if (!resolution.value) errors.resolution = 'Resolution is required.';
  if (['returned', 'rejected'].includes(resolution.value) && !remark.value.trim()) {
    errors.remark = 'A remark is required when returning or rejecting.';
  }
  decisionErrors.value = errors;
  if (Object.keys(errors).length > 0) {
    toast.error('Please complete the decision form.');
    return;
  }

  const now = new Date();
  reg.decided_at = `${now.toISOString().split('T')[0]} ${now.toTimeString().slice(0, 5)}`;
  reg.decided_by = 'Marta Tadesse';
  reg.decision_note = remark.value.trim();
  reg.supplier_registration_status_lookup_value_id = resolution.value as SupplierRegistrationStatus;

  if (resolution.value === 'approved') {
    supplierRegistrationCategoriesStore.value
      .filter((c) => c.supplier_registration_id === reg.id && c.is_approved === null)
      .forEach((c) => {
        c.is_approved = true;
      });
  }

  toast.success(`${reg.registration_number} ${getStatusLabel(reg.supplier_registration_status_lookup_value_id).toLowerCase()}.`);
  resolution.value = '';
  remark.value = '';
};

// ─── Registration Steps (living stepper) ─────────────────────────────────────
type StepState = 'done' | 'active' | 'queued' | 'error';

const stepStates = computed<StepState[]>(() => {
  switch (status.value) {
    case 'draft':
      return ['active', 'queued', 'queued', 'queued'];
    case 'pending_verification':
      return ['done', 'active', 'queued', 'queued'];
    case 'pending_review':
      return ['done', 'done', 'active', 'queued'];
    case 'returned':
      return ['done', 'done', 'done', 'active'];
    case 'rejected':
      return ['done', 'done', 'done', 'error'];
    case 'approved':
    case 'inactive':
    default:
      return ['done', 'done', 'done', 'done'];
  }
});

const steps = computed(() => {
  const reg = registration.value;
  const states = stepStates.value;
  return [
    {
      title: 'Application Submitted',
      subtitle: reg?.submitted_at ? formatDisplayDate(reg.submitted_at) : 'Not submitted yet',
      state: states[0]
    },
    {
      title: 'Contact Verification',
      subtitle: reg?.email_verified_at
        ? `Email verified ${formatDisplayDate(reg.email_verified_at)}`
        : 'Awaiting email and phone confirmation',
      state: states[1]
    },
    {
      title: 'Officer Review',
      subtitle: states[2] === 'active' ? 'Awaiting officer decision' : 'Review of documents and categories',
      state: states[2]
    },
    {
      title: status.value === 'returned' ? 'Returned for Correction' : 'Final Decision',
      subtitle: reg?.decided_at
        ? `${getStatusLabel(status.value)} ${formatDisplayDate(reg.decided_at)}`
        : status.value === 'returned'
          ? 'Awaiting correction'
          : 'Pending',
      state: states[3]
    }
  ];
});

const STEP_COLORS: Record<StepState, string> = {
  done: '#0b529c',
  active: '#fe9a00',
  queued: '#d4d4d4',
  error: '#e7000b'
};

const connectorStyle = (index: number) => {
  const upper = steps.value[index].state;
  const lower = steps.value[index + 1].state;
  return {
    background: `linear-gradient(180deg, ${STEP_COLORS[upper]} 0%, ${STEP_COLORS[lower]} 100%)`
  };
};

const maskedBank = computed(() => {
  const bank = registration.value?.bank_details;
  if (!bank) return 'No bank details provided';
  return `${bank.bank_name}, ${bank.branch} — ${maskAccountNumber(bank.account_number)}`;
});
</script>

<template>
  <div class="registration-detail-page">
    <AppBreadcrumb :items="breadcrumbItems" :noMargin="true" />

    <div v-if="!registration" class="detail-card empty-detail-card">
      <p class="empty-title">Supplier registration not found</p>
      <p class="empty-sub">The requested registration does not exist in the current store.</p>
    </div>

    <div v-else class="detail-layout" :class="{ 'rail-collapsed': isRailCollapsed }">
      <!-- ═════════ LEFT DOSSIER ═════════ -->
      <div class="dossier-column">
        <!-- Hero Card -->
        <div class="detail-card hero-card">
          <div class="hero-left">
            <BaseAvatar :src="registration.logo_url" :name="registration.legal_name" size="xl" />
            <div class="hero-identity">
              <h2 class="hero-title">{{ registration.legal_name }}</h2>
              <span class="hero-code">
                {{ registration.registration_number }}
                <template v-if="registration.trade_name"> • Trades as {{ registration.trade_name }}</template>
              </span>
              <span class="hero-meta">Applied to {{ getEntityLabel(registration.entity_id) }}</span>
            </div>
          </div>
          <div class="hero-right">
            <BaseBadge size="sm" :color="getStatusBadgeColor(status)">
              {{ getStatusLabel(status) }}
            </BaseBadge>
            <div class="hero-meta-grid">
              <div class="meta-pair">
                <span class="meta-label">Business Type</span>
                <span class="meta-value">{{ getBusinessTypeLabel(registration.business_type_lookup_value_id) }}</span>
              </div>
              <div class="meta-pair">
                <span class="meta-label">Origin</span>
                <span class="meta-value">{{ getOriginLabel(registration.origin_lookup_value_id) }}</span>
              </div>
              <div class="meta-pair">
                <span class="meta-label">Submitted On</span>
                <span class="meta-value">{{ formatDisplayDate(registration.submitted_at) }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Registration Blueprint Card -->
        <div class="detail-card blueprint-card">
          <div class="card-heading">
            <h3 class="card-title">Business Identity</h3>
            <p class="card-subtitle">Trade licence, tax identifiers, and fiscal coverage as entered.</p>
          </div>
          <div class="detail-grid-3">
            <div class="detail-field">
              <span class="detail-label">TIN</span>
              <span class="detail-value">{{ registration.tin }}</span>
            </div>
            <div class="detail-field">
              <span class="detail-label">VAT Registration Number</span>
              <span class="detail-value">{{ registration.vat_registration_number || 'Not VAT-registered' }}</span>
            </div>
            <div class="detail-field">
              <span class="detail-label">Business License Number</span>
              <span class="detail-value">{{ registration.business_license_number || '—' }}</span>
            </div>
            <div class="detail-field">
              <span class="detail-label">Fiscal Year</span>
              <span class="detail-value">{{ getFiscalYearLabel(registration.fiscal_year_id) }}</span>
            </div>
            <div class="detail-field">
              <span class="detail-label">Core Supplier</span>
              <span class="detail-value">
                {{ registration.supplier_id ? `Supplier #${registration.supplier_id}` : 'Created on approval' }}
              </span>
            </div>
            <div class="detail-field">
              <span class="detail-label">Decided By</span>
              <span class="detail-value">{{ registration.decided_by || '—' }}</span>
            </div>
          </div>
        </div>

        <!-- Contact & Verification Card -->
        <div class="detail-card blueprint-card">
          <div class="card-heading">
            <h3 class="card-title">Contact &amp; Verification</h3>
            <p class="card-subtitle">Who procurement deals with and how the contact was verified.</p>
          </div>
          <div class="detail-grid-3">
            <div class="detail-field">
              <span class="detail-label">Contact Person</span>
              <span class="detail-value">{{ registration.contact_person_name }}</span>
            </div>
            <div class="detail-field">
              <span class="detail-label">Email</span>
              <span class="detail-value">{{ registration.email }}</span>
              <BaseBadge size="sm" :color="registration.email_verified_at ? 'success' : 'warning'">
                {{ registration.email_verified_at ? `Verified ${formatDisplayDate(registration.email_verified_at)}` : 'Not verified' }}
              </BaseBadge>
            </div>
            <div class="detail-field">
              <span class="detail-label">Phone</span>
              <span class="detail-value">{{ registration.phone }}</span>
              <BaseBadge size="sm" :color="registration.phone_verified_at ? 'success' : 'warning'">
                {{ registration.phone_verified_at ? `Verified ${formatDisplayDate(registration.phone_verified_at)}` : 'Not verified' }}
              </BaseBadge>
            </div>
            <div class="detail-field detail-field-span">
              <span class="detail-label">Head Office Address</span>
              <span class="detail-value">{{ registration.address }}</span>
            </div>
            <div class="detail-field detail-field-span">
              <span class="detail-label">Bank Details</span>
              <span class="detail-value">{{ maskedBank }}</span>
            </div>
          </div>
        </div>

        <!-- Qualification Terms (SupplierQualification) -->
        <div class="detail-card blueprint-card">
          <div class="card-heading">
            <h3 class="card-title">Qualification Terms</h3>
            <p class="card-subtitle">Initial eligibility window and single-PO value ceiling proposed for approval.</p>
          </div>
          <div class="detail-grid-3">
            <div class="detail-field">
              <span class="detail-label">Qualified From</span>
              <span class="detail-value">{{ formatDisplayDate(registration.qualified_from) }}</span>
            </div>
            <div class="detail-field">
              <span class="detail-label">Qualified To</span>
              <span class="detail-value">{{ formatDisplayDate(registration.qualified_to) }}</span>
            </div>
            <div class="detail-field">
              <span class="detail-label">Maximum Order Value</span>
              <span class="detail-value">{{ formattedMaxOrderValue }}</span>
            </div>
          </div>
        </div>

        <!-- Requested Categories (SupplierRegistrationCategory) -->
        <div class="detail-card table-card">
          <div class="card-heading table-heading">
            <h3 class="card-title">Requested Categories</h3>
            <p class="card-subtitle">Categories the applicant asked to supply; the approver grants some or all.</p>
          </div>
          <table class="erp-table">
            <thead>
              <tr>
                <th class="th-seq">No.</th>
                <th>Procurement Category</th>
                <th>Approver Decision</th>
                <th v-if="canDecide" class="th-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="categories.length === 0">
                <td :colspan="canDecide ? 4 : 3" class="empty-lines-cell">No categories requested.</td>
              </tr>
              <tr v-for="(cat, index) in categories" :key="cat.id" class="erp-row">
                <td class="td-seq">{{ index + 1 }}</td>
                <td><span class="cell-primary">{{ getCategoryLabel(cat.procurement_category_id) }}</span></td>
                <td>
                  <BaseBadge size="sm" :color="getCategoryDecisionColor(cat.is_approved)">
                    {{ getCategoryDecisionLabel(cat.is_approved) }}
                  </BaseBadge>
                </td>
                <td v-if="canDecide" class="td-actions">
                  <BaseDropdownMenu :items="getCategoryActionItems(cat)" minWidth="180px">
                    <template #trigger="{ toggle }">
                      <button type="button" class="btn-action-dots" title="Category Decision" @click.stop="toggle">
                        <MoreVertical :size="18" />
                      </button>
                    </template>
                  </BaseDropdownMenu>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Compliance Documents (SupplierQualificationDocument) -->
        <div class="detail-card table-card">
          <div class="card-heading table-heading">
            <h3 class="card-title">Compliance Documents</h3>
            <p class="card-subtitle">Licences, tax certificates, and compliance documents submitted for verification.</p>
          </div>
          <table class="erp-table">
            <thead>
              <tr>
                <th class="th-seq">No.</th>
                <th>Document Type</th>
                <th>Reference Number</th>
                <th>Issued</th>
                <th>Expires</th>
                <th>Mandatory</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="documents.length === 0">
                <td colspan="6" class="empty-lines-cell">No compliance documents submitted.</td>
              </tr>
              <tr v-for="(doc, index) in documents" :key="doc.id" class="erp-row">
                <td class="td-seq">{{ index + 1 }}</td>
                <td><span class="cell-primary">{{ getDocumentTypeLabel(doc.document_type_lookup_value_id) }}</span></td>
                <td><span class="cell-muted">{{ doc.reference_number || '—' }}</span></td>
                <td><span class="cell-muted">{{ formatDisplayDate(doc.issued_at) }}</span></td>
                <td><span class="cell-muted">{{ formatDisplayDate(doc.expires_at) }}</span></td>
                <td>
                  <BaseBadge size="sm" :color="doc.is_mandatory ? 'indigo' : 'blue'">
                    {{ doc.is_mandatory ? 'Mandatory' : 'Optional' }}
                  </BaseBadge>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Portal Contacts (SupplierUser) -->
        <div class="detail-card table-card">
          <div class="card-heading table-heading">
            <h3 class="card-title">Portal Contacts</h3>
            <p class="card-subtitle">Supplier contacts who will receive portal invites upon approval.</p>
          </div>
          <table class="erp-table">
            <thead>
              <tr>
                <th class="th-seq">No.</th>
                <th>Contact Name</th>
                <th>Portal Email</th>
                <th>Designation</th>
                <th>Primary Contact</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="portalUsers.length === 0">
                <td colspan="5" class="empty-lines-cell">No portal contacts listed.</td>
              </tr>
              <tr v-for="(user, index) in portalUsers" :key="user.id" class="erp-row">
                <td class="td-seq">{{ index + 1 }}</td>
                <td><span class="cell-primary">{{ user.full_name }}</span></td>
                <td><span class="cell-muted">{{ user.email }}</span></td>
                <td><span class="cell-muted">{{ user.designation || '—' }}</span></td>
                <td>
                  <BaseBadge size="sm" :color="user.is_primary_contact ? 'primary' : 'blue'">
                    {{ user.is_primary_contact ? 'Primary' : 'Secondary' }}
                  </BaseBadge>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Decision Note (only when the approver left one) -->
        <div v-if="registration.decision_note" class="detail-card accordion-card">
          <div
            class="card-accordion-header"
            :class="{ 'is-collapsed': !isDecisionNoteOpen }"
            @click="isDecisionNoteOpen = !isDecisionNoteOpen"
          >
            <span>Decision Note</span>
            <ChevronDown v-if="isDecisionNoteOpen" :size="16" class="header-chevron" />
            <ChevronRight v-else :size="16" class="header-chevron" />
          </div>
          <div v-show="isDecisionNoteOpen" class="card-accordion-body">
            <p class="detail-description">{{ registration.decision_note }}</p>
          </div>
        </div>
      </div>

      <!-- ═════════ RIGHT APPROVAL RAIL ═════════ -->
      <aside class="approval-rail" :class="{ collapsed: isRailCollapsed }">
        <template v-if="isRailCollapsed">
          <button type="button" class="btn-focus-collapsed" title="Expand rail" @click="isRailCollapsed = false">
            <PanelRightOpen :size="18" />
          </button>
        </template>
        <template v-else>
          <button type="button" class="btn-focus" @click="isRailCollapsed = true">
            <PanelRightClose :size="18" />
            <span>Focus</span>
          </button>

          <section class="rail-section">
            <h3 class="rail-title">Approver Decision</h3>
            <template v-if="canDecide">
              <FormSelect
                v-model="resolution"
                label="Resolution"
                :options="resolutionOptions"
                placeholder="Select Resolution"
                :error="decisionErrors.resolution"
                required
              />
              <FormTextarea
                v-model="remark"
                label="Remark"
                :rows="3"
                :error="decisionErrors.remark"
              />
              <AppButton variant="primary" size="md" class="btn-full" @click="submitDecision">
                Submit Decision
              </AppButton>
            </template>
            <p v-else class="rail-note">
              {{
                status === 'pending_verification'
                  ? 'A decision can be made once the supplier confirms the email link and phone code.'
                  : status === 'draft'
                    ? 'Submit the registration to start verification and review.'
                    : status === 'returned'
                      ? 'Returned to the officer for correction. Resubmit to continue.'
                      : 'This registration has already been decided.'
              }}
            </p>
          </section>

          <div class="rail-divider"></div>

          <section class="rail-section">
            <div>
              <h3 class="rail-title">Registration Steps</h3>
              <p class="rail-subtitle">Verification and review progress.</p>
            </div>
            <ol class="step-list">
              <li v-for="(step, index) in steps" :key="step.title" class="step-row">
                <div class="step-track">
                  <span class="step-circle" :class="`step-${step.state}`">
                    <Check v-if="step.state === 'done'" :size="20" />
                    <X v-else-if="step.state === 'error'" :size="20" />
                    <Clock v-else :size="20" />
                  </span>
                  <span
                    v-if="index < steps.length - 1"
                    class="step-connector"
                    :style="connectorStyle(index)"
                  ></span>
                </div>
                <div class="step-content">
                  <span class="step-title">{{ step.title }}</span>
                  <span class="step-subtitle">{{ step.subtitle }}</span>
                </div>
              </li>
            </ol>
          </section>
        </template>
      </aside>
    </div>
  </div>
</template>

<style scoped>
.registration-detail-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.detail-layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 360px;
  gap: 24px;
  align-items: start;
}

.detail-layout.rail-collapsed {
  grid-template-columns: minmax(0, 1fr) 68px;
}

.dossier-column {
  display: flex;
  flex-direction: column;
  gap: 20px;
  min-width: 0;
}

.detail-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  overflow: hidden;
}

.empty-detail-card {
  padding: 48px 24px;
  text-align: center;
}

.empty-title {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #404040;
}

.empty-sub {
  margin: 6px 0 0;
  font-size: 13.5px;
  color: #737373;
}

/* Hero */
.hero-card {
  padding: 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  flex-wrap: wrap;
}

.hero-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.hero-identity {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.hero-title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #404040;
}

.hero-code,
.hero-meta {
  font-size: 13px;
  color: #737373;
}

.hero-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 12px;
}

.hero-meta-grid {
  display: flex;
  gap: 24px;
}

.meta-pair {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.meta-label {
  font-size: 12px;
  color: #737373;
}

.meta-value {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
}

/* Blueprint cards */
.blueprint-card {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.card-heading {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.card-title {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #404040;
}

.card-subtitle {
  margin: 0;
  font-size: 14px;
  color: #737373;
}

.detail-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 20px 24px;
}

.detail-field {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 4px;
}

.detail-field-span {
  grid-column: span 3;
}

.detail-label {
  font-size: 12px;
  font-weight: 500;
  color: #737373;
}

.detail-value {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
}

/* Categories table */
.table-card {
  display: flex;
  flex-direction: column;
}

.table-heading {
  padding: 20px 24px;
  border-bottom: 1px solid #e9eaeb;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table thead th {
  height: 44px;
  padding: 0 16px;
  background-color: #fafafa;
  border-bottom: 1px solid #e9eaeb;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  text-align: left;
}

.erp-table thead th.th-seq {
  padding-left: 24px;
  width: 72px;
}

.erp-row {
  height: 64px;
  border-bottom: 1px solid #e9eaeb;
}

.erp-row:last-child {
  border-bottom: none;
}

.erp-table tbody td {
  padding: 12px 16px;
  vertical-align: middle;
}

.erp-table tbody td.td-seq {
  padding-left: 24px;
  font-size: 13px;
  font-weight: 500;
  color: #737373;
}

.cell-primary {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
}

.cell-muted {
  font-size: 13.5px;
  color: #737373;
}

.erp-table thead th.th-actions {
  text-align: center;
  padding-right: 24px;
  width: 80px;
}

.erp-table tbody td.td-actions {
  text-align: center;
  padding-right: 24px;
}

.btn-action-dots {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: none;
  background: transparent;
  color: #737373;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  outline: none !important;
  box-shadow: none !important;
  -webkit-tap-highlight-color: transparent !important;
}

.btn-action-dots:hover {
  background-color: #f5f5f5;
  color: #404040;
}

.empty-lines-cell {
  padding: 36px 24px !important;
  text-align: center;
  color: #737373;
  font-size: 13.5px;
}

/* Accordion (Decision Note) */
.accordion-card {
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
}

.card-accordion-header.is-collapsed {
  border-bottom: none;
}

.card-accordion-header:hover {
  background-color: #fafafa;
}

.header-chevron {
  color: #737373;
  flex-shrink: 0;
}

.card-accordion-body {
  padding: 20px 24px 24px;
}

.detail-description {
  margin: 0;
  font-size: 14px;
  line-height: 1.6;
  color: #404040;
}

/* Approval Rail */
.approval-rail {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.approval-rail.collapsed {
  padding: 20px 16px;
  min-height: 240px;
  align-items: center;
}

.btn-focus,
.btn-focus-collapsed {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  background: #ffffff;
  border: 1px solid #d5d7da;
  border-radius: 8px;
  color: #404040;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  outline: none;
}

.btn-focus {
  align-self: flex-start;
  padding: 8px 14px;
}

.btn-focus-collapsed {
  width: 36px;
  height: 36px;
}

.btn-focus:hover,
.btn-focus-collapsed:hover {
  background-color: #fafafa;
}

.rail-section {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.rail-title {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
  color: #404040;
}

.rail-subtitle {
  margin: 4px 0 0;
  font-size: 14px;
  color: #737373;
}

.rail-note {
  margin: 0;
  font-size: 14px;
  line-height: 1.5;
  color: #737373;
}

.btn-full {
  width: 100%;
}

.rail-divider {
  border-top: 1px solid #e5e5e5;
  margin: 4px 0;
}

/* Stepper */
.step-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
}

.step-row {
  display: flex;
  gap: 16px;
}

.step-track {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex-shrink: 0;
}

.step-circle {
  width: 44px;
  height: 44px;
  border-radius: 9999px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  flex-shrink: 0;
}

.step-done {
  background-color: #0b529c;
}

.step-active {
  background-color: #fe9a00;
}

.step-error {
  background-color: #e7000b;
}

.step-queued {
  background-color: #e5e5e5;
  border: 1px solid #d4d4d4;
}

.step-connector {
  width: 2px;
  flex: 1;
  min-height: 32px;
}

.step-content {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding-top: 4px;
  padding-bottom: 32px;
}

.step-row:last-child .step-content {
  padding-bottom: 0;
}

.step-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.step-subtitle {
  font-size: 13px;
  color: #737373;
}

@media (max-width: 1100px) {
  .detail-layout,
  .detail-layout.rail-collapsed {
    grid-template-columns: minmax(0, 1fr);
  }

  .detail-grid-3 {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .detail-field-span {
    grid-column: span 2;
  }
}
</style>

