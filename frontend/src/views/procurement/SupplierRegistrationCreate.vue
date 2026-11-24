<!--
  ══════════════════════════════════════════════════════════════════════════════
  HALETA ERP ARCHITECTURAL SPECIFICATION — UNIFIED SUPPLIER ONBOARDING FORM:
  1. SCHEMA RELATIONAL INTEGRITY (procurement-v4.sql #3):
     One unified tabular onboarding form (mirroring EmployeeCreate.vue) so the
     officer enters all onboarding data in one place for one single approval:
     - Tab 1: Registration Details (SupplierRegistration — 3 collapsible cards)
     - Tab 2: Requested Categories (SupplierRegistrationCategory via <DynamicSubTable />)
     - Tab 3: Compliance Documents (SupplierQualificationDocument via <DynamicSubTable />)
     - Tab 4: Portal Contacts (SupplierUser via <DynamicSubTable />)
  2. DIRECT CREATE (Tier 3): > 5 required fields + 1:N child lines -> no QuickCreateModal.
  3. WORKFLOW CTA: status lookup includes `draft` -> primary action is "Submit";
     "Save as Draft" lives in the 3-dot menu left of "Clear Form".
  4. ZERO status / state / approver controls, zero text-input placeholders,
     select placeholders use "Select [core noun]".
  ══════════════════════════════════════════════════════════════════════════════
-->
<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  X, MoreVertical, Save, Building2, Layers,
  FileCheck, Users, ChevronDown, ChevronRight,
  Image as ImageIcon, Upload
} from 'lucide-vue-next';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseDropdownMenu, { type DropdownMenuItem } from '../../components/BaseDropdownMenu.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormCheckboxCard from '../../components/FormCheckboxCard.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import DynamicSubTable, { type DynamicTableColumn } from '../../components/DynamicSubTable.vue';
import { useToast } from '../../composables/useToast';
import {
  supplierRegistrationsStore,
  supplierRegistrationCategoriesStore,
  supplierRegistrationDocumentsStore,
  supplierRegistrationPortalUsersStore,
  type SupplierRegistrationStatus,
  type SupplierBusinessType,
  type ProcurementOrigin,
  type SupplierDocumentType,
  businessTypeOptions,
  originOptions,
  entityOptions,
  fiscalYearOptions,
  currencyOptions,
  categoryOptions,
  supplierDocumentTypeOptions,
  generateRegistrationNumber,
  getRegistrationCategories,
  getRegistrationDocuments,
  getRegistrationPortalUsers
} from './supplierRegistrationData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

const editingId = computed(() => (route.params.id ? Number(route.params.id) : null));
const isSaved = ref(false);
const isBankOpen = ref(true);
const isQualificationOpen = ref(true);
const logoFileInput = ref<HTMLInputElement | null>(null);

const triggerLogoUpload = () => {
  logoFileInput.value?.click();
};

const handleLogoChange = (event: Event) => {
  const input = event.target as HTMLInputElement;
  const file = input.files?.[0];
  if (!file) return;
  if (!['image/jpeg', 'image/png'].includes(file.type)) {
    toast.error('Only JPG or PNG images are allowed.');
    return;
  }
  if (file.size > 10 * 1024 * 1024) {
    toast.error('Logo image must be smaller than 10MB.');
    return;
  }
  const reader = new FileReader();
  reader.onload = () => {
    form.value.logo_url = String(reader.result || '');
  };
  reader.readAsDataURL(file);
};

const removeLogo = () => {
  form.value.logo_url = '';
  if (logoFileInput.value) logoFileInput.value.value = '';
};

// ─── Tabs (Primary capsule tabs; reactive count on all child sub-table tabs) ─
type TabId = 'details' | 'categories' | 'documents' | 'portal_users';
const activeTab = ref<TabId>('details');

const tabs = computed<BaseTabItem<TabId>[]>(() => [
  { id: 'details', label: 'Registration Details', icon: Building2 },
  { id: 'categories', label: 'Requested Categories', icon: Layers, count: categoryRows.value.length },
  { id: 'documents', label: 'Qualification', icon: FileCheck, count: documentRows.value.length },
  { id: 'portal_users', label: 'Portal Contacts', icon: Users, count: portalUserRows.value.length }
]);

// ─── Tab 1: Form State (SupplierRegistration) ────────────────────────────────
interface RegistrationForm {
  logo_url: string;
  legal_name: string;
  trade_name: string;
  tin: string;
  vat_registration_number: string;
  business_license_number: string;
  business_type_lookup_value_id: SupplierBusinessType | '';
  origin_lookup_value_id: ProcurementOrigin | '';
  entity_id: string;
  fiscal_year_id: string;
  contact_person_name: string;
  email: string;
  phone: string;
  address: string;
  bank_name: string;
  bank_branch: string;
  bank_account_name: string;
  bank_account_number: string;
  qualified_from: string;
  qualified_to: string;
  no_order_cap: boolean;
  maximum_order_value: number | null;
  currency_id: string;
}

const createEmptyForm = (): RegistrationForm => ({
  logo_url: '',
  legal_name: '',
  trade_name: '',
  tin: '',
  vat_registration_number: '',
  business_license_number: '',
  business_type_lookup_value_id: '',
  origin_lookup_value_id: '',
  entity_id: '2',
  fiscal_year_id: '',
  contact_person_name: '',
  email: '',
  phone: '',
  address: '',
  bank_name: '',
  bank_branch: '',
  bank_account_name: '',
  bank_account_number: '',
  qualified_from: '',
  qualified_to: '',
  no_order_cap: true,
  maximum_order_value: null,
  currency_id: 'ETB'
});

const form = ref<RegistrationForm>(createEmptyForm());

const fieldErrors = ref<{
  legal_name?: string;
  tin?: string;
  business_type?: string;
  origin?: string;
  entity?: string;
  contact_person_name?: string;
  email?: string;
  phone?: string;
  address?: string;
  qualified_to?: string;
  maximum_order_value?: string;
}>({});

// ─── Tab 2: Requested Categories (SupplierRegistrationCategory) ──────────────
interface CategoryRow {
  id?: number;
  procurement_category_id: string;
  is_approved: boolean | null;
}

const createCategoryRow = (): CategoryRow => ({
  procurement_category_id: '',
  is_approved: null
});

const categoryRows = ref<CategoryRow[]>([createCategoryRow()]);

const categoryColumns: DynamicTableColumn[] = [
  {
    key: 'procurement_category_id',
    label: 'Procurement Category',
    type: 'select',
    options: categoryOptions,
    placeholder: 'Select Category',
    minWidth: '300px'
  }
];

// ─── Tab 3: Compliance Documents (SupplierQualificationDocument) ─────────────
interface DocumentRow {
  id?: number;
  document_type_lookup_value_id: SupplierDocumentType | '';
  reference_number: string;
  issued_at: string;
  expires_at: string;
  is_mandatory: boolean;
  remarks: string;
}

const createDocumentRow = (): DocumentRow => ({
  document_type_lookup_value_id: 'trade_license',
  reference_number: '',
  issued_at: '',
  expires_at: '',
  is_mandatory: true,
  remarks: ''
});

const documentRows = ref<DocumentRow[]>([createDocumentRow()]);

const documentColumns: DynamicTableColumn[] = [
  {
    key: 'document_type_lookup_value_id',
    label: 'Document Type',
    type: 'select',
    options: supplierDocumentTypeOptions,
    placeholder: 'Select Document',
    minWidth: '220px'
  },
  {
    key: 'reference_number',
    label: 'Reference Number',
    type: 'text',
    minWidth: '180px'
  },
  {
    key: 'issued_at',
    label: 'Issued Date',
    type: 'date',
    minWidth: '150px'
  },
  {
    key: 'expires_at',
    label: 'Expiry Date',
    type: 'date',
    minWidth: '150px'
  },
  {
    key: 'is_mandatory',
    label: 'Mandatory',
    type: 'switch',
    minWidth: '130px'
  }
];

// ─── Tab 4: Portal Contacts (SupplierUser) ───────────────────────────────────
interface PortalUserRow {
  id?: number;
  full_name: string;
  email: string;
  designation: string;
  is_primary_contact: boolean;
}

const createPortalUserRow = (): PortalUserRow => ({
  full_name: '',
  email: '',
  designation: '',
  is_primary_contact: portalUserRows.value.length === 0
});

const portalUserRows = ref<PortalUserRow[]>([
  {
    full_name: '',
    email: '',
    designation: '',
    is_primary_contact: true
  }
]);

const portalUserColumns: DynamicTableColumn[] = [
  {
    key: 'full_name',
    label: 'Contact Name',
    type: 'text',
    minWidth: '200px'
  },
  {
    key: 'email',
    label: 'Portal Email',
    type: 'text',
    minWidth: '220px'
  },
  {
    key: 'designation',
    label: 'Designation',
    type: 'text',
    minWidth: '180px'
  },
  {
    key: 'is_primary_contact',
    label: 'Primary Contact',
    type: 'switch',
    minWidth: '140px'
  }
];

// ─── Breadcrumbs ─────────────────────────────────────────────────────────────
const editingNumber = computed(
  () => supplierRegistrationsStore.value.find((r) => r.id === editingId.value)?.registration_number
);

const breadcrumbItems = computed<BreadcrumbItem[]>(() => [
  { label: 'Supplier Registrations', to: '/procurement/supplier-registrations' },
  { label: editingId.value ? `Edit ${editingNumber.value ?? 'Registration'}` : 'Create Registration' }
]);

watch(
  [form, categoryRows, documentRows, portalUserRows],
  () => {
    isSaved.value = false;
  },
  { deep: true }
);

// ─── Hydration (edit mode) ───────────────────────────────────────────────────
onMounted(() => {
  if (!editingId.value) return;
  const existing = supplierRegistrationsStore.value.find((r) => r.id === editingId.value);
  if (!existing) return;

  form.value = {
    logo_url: existing.logo_url || '',
    legal_name: existing.legal_name,
    trade_name: existing.trade_name,
    tin: existing.tin,
    vat_registration_number: existing.vat_registration_number,
    business_license_number: existing.business_license_number,
    business_type_lookup_value_id: existing.business_type_lookup_value_id,
    origin_lookup_value_id: existing.origin_lookup_value_id,
    entity_id: existing.entity_id,
    fiscal_year_id: existing.fiscal_year_id,
    contact_person_name: existing.contact_person_name,
    email: existing.email,
    phone: existing.phone,
    address: existing.address,
    bank_name: existing.bank_details?.bank_name ?? '',
    bank_branch: existing.bank_details?.branch ?? '',
    bank_account_name: existing.bank_details?.account_name ?? '',
    bank_account_number: existing.bank_details?.account_number ?? '',
    qualified_from: existing.qualified_from || '',
    qualified_to: existing.qualified_to || '',
    no_order_cap: existing.maximum_order_value === null,
    maximum_order_value: existing.maximum_order_value,
    currency_id: existing.currency_id || 'ETB'
  };

  const existingCategories = getRegistrationCategories(existing.id);
  if (existingCategories.length > 0) {
    categoryRows.value = existingCategories.map((c) => ({
      id: c.id,
      procurement_category_id: c.procurement_category_id,
      is_approved: c.is_approved
    }));
  }

  const existingDocs = getRegistrationDocuments(existing.id);
  if (existingDocs.length > 0) {
    documentRows.value = existingDocs.map((d) => ({
      id: d.id,
      document_type_lookup_value_id: d.document_type_lookup_value_id,
      reference_number: d.reference_number,
      issued_at: d.issued_at,
      expires_at: d.expires_at,
      is_mandatory: d.is_mandatory,
      remarks: d.remarks
    }));
  }

  const existingPortalUsers = getRegistrationPortalUsers(existing.id);
  if (existingPortalUsers.length > 0) {
    portalUserRows.value = existingPortalUsers.map((u) => ({
      id: u.id,
      full_name: u.full_name,
      email: u.email,
      designation: u.designation,
      is_primary_contact: u.is_primary_contact
    }));
  }

  isSaved.value = true;
});

const clearForm = () => {
  form.value = createEmptyForm();
  categoryRows.value = [createCategoryRow()];
  documentRows.value = [createDocumentRow()];
  portalUserRows.value = [
    { full_name: '', email: '', designation: '', is_primary_contact: true }
  ];
  fieldErrors.value = {};
  isSaved.value = false;
  toast.info('Form cleared.');
};

// ─── Validation ──────────────────────────────────────────────────────────────
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const findDuplicate = (key: 'tin' | 'email', value: string) =>
  supplierRegistrationsStore.value.find(
    (r) =>
      r.id !== editingId.value &&
      r.entity_id === form.value.entity_id &&
      r[key].trim().toLowerCase() === value.trim().toLowerCase() &&
      !['rejected', 'inactive'].includes(r.supplier_registration_status_lookup_value_id)
  );

const validateDraft = (): boolean => {
  fieldErrors.value = {};
  if (!form.value.legal_name.trim()) {
    fieldErrors.value.legal_name = 'Legal Name is required.';
    activeTab.value = 'details';
    toast.error('Legal Name is required to save a draft.');
    return false;
  }
  return true;
};

const validateSubmit = (): boolean => {
  const errors: typeof fieldErrors.value = {};

  if (!form.value.legal_name.trim()) errors.legal_name = 'Legal Name is required.';
  if (!form.value.tin.trim()) {
    errors.tin = 'TIN is required.';
  } else {
    const dup = findDuplicate('tin', form.value.tin);
    if (dup) errors.tin = `TIN already registered on ${dup.registration_number}.`;
  }
  if (!form.value.business_type_lookup_value_id) errors.business_type = 'Business Type is required.';
  if (!form.value.origin_lookup_value_id) errors.origin = 'Origin is required.';
  if (!form.value.entity_id) errors.entity = 'Applied-to entity is required.';
  if (!form.value.contact_person_name.trim()) errors.contact_person_name = 'Contact Person is required.';
  if (!form.value.email.trim()) {
    errors.email = 'Email is required.';
  } else if (!EMAIL_PATTERN.test(form.value.email.trim())) {
    errors.email = 'Enter a valid email address.';
  } else {
    const dup = findDuplicate('email', form.value.email);
    if (dup) errors.email = `Email already registered on ${dup.registration_number}.`;
  }
  if (!form.value.phone.trim()) errors.phone = 'Phone is required.';
  if (!form.value.address.trim()) errors.address = 'Head Office Address is required.';
  if (form.value.qualified_from && form.value.qualified_to && form.value.qualified_to < form.value.qualified_from) {
    errors.qualified_to = 'Qualified To must be on or after Qualified From.';
  }
  if (!form.value.no_order_cap && (form.value.maximum_order_value === null || form.value.maximum_order_value <= 0)) {
    errors.maximum_order_value = 'Enter a valid maximum order value.';
  }

  fieldErrors.value = errors;

  const hasDetailErrors = Boolean(
    errors.legal_name ||
      errors.tin ||
      errors.business_type ||
      errors.origin ||
      errors.entity ||
      errors.contact_person_name ||
      errors.email ||
      errors.phone ||
      errors.address
  );
  if (hasDetailErrors) {
    activeTab.value = 'details';
    toast.error('Please resolve the highlighted required fields.');
    return false;
  }
  if (errors.qualified_to || errors.maximum_order_value) {
    activeTab.value = 'documents';
    toast.error('Please resolve the highlighted qualification fields.');
    return false;
  }

  const selectedCategories = categoryRows.value
    .map((r) => r.procurement_category_id)
    .filter(Boolean);
  if (selectedCategories.length === 0) {
    activeTab.value = 'categories';
    toast.error('Request at least one procurement category.');
    return false;
  }
  if (new Set(selectedCategories).size !== selectedCategories.length) {
    activeTab.value = 'categories';
    toast.error('Each procurement category can be requested only once.');
    return false;
  }

  const invalidDoc = documentRows.value.some(
    (d) =>
      d.document_type_lookup_value_id &&
      d.issued_at &&
      d.expires_at &&
      d.expires_at < d.issued_at
  );
  if (invalidDoc) {
    activeTab.value = 'documents';
    toast.error('Document expiry date cannot be earlier than the issued date.');
    return false;
  }

  const invalidPortalEmail = portalUserRows.value.some(
    (u) => u.email.trim() && !EMAIL_PATTERN.test(u.email.trim())
  );
  if (invalidPortalEmail) {
    activeTab.value = 'portal_users';
    toast.error('Enter a valid email address for each portal contact.');
    return false;
  }

  return true;
};

// ─── Persistence ─────────────────────────────────────────────────────────────
const hasBankDetails = () =>
  [
    form.value.bank_name,
    form.value.bank_branch,
    form.value.bank_account_name,
    form.value.bank_account_number
  ].some((v) => v.trim());

const persist = (status: SupplierRegistrationStatus): number => {
  const now = new Date();
  const timestamp = `${now.toISOString().split('T')[0]} ${now.toTimeString().slice(0, 5)}`;
  const isSubmitting = status !== 'draft';

  const payload = {
    logo_url: form.value.logo_url || undefined,
    legal_name: form.value.legal_name.trim(),
    trade_name: form.value.trade_name.trim(),
    tin: form.value.tin.trim(),
    vat_registration_number: form.value.vat_registration_number.trim(),
    business_license_number: form.value.business_license_number.trim(),
    contact_person_name: form.value.contact_person_name.trim(),
    email: form.value.email.trim(),
    phone: form.value.phone.trim(),
    address: form.value.address.trim(),
    bank_details: hasBankDetails()
      ? {
          bank_name: form.value.bank_name.trim(),
          branch: form.value.bank_branch.trim(),
          account_name: form.value.bank_account_name.trim(),
          account_number: form.value.bank_account_number.trim()
        }
      : null,
    business_type_lookup_value_id: (form.value.business_type_lookup_value_id ||
      'distributor') as SupplierBusinessType,
    origin_lookup_value_id: (form.value.origin_lookup_value_id || 'local') as ProcurementOrigin,
    entity_id: form.value.entity_id,
    fiscal_year_id: form.value.fiscal_year_id,
    qualified_from: form.value.qualified_from,
    qualified_to: form.value.qualified_to,
    maximum_order_value: form.value.no_order_cap ? null : Number(form.value.maximum_order_value),
    currency_id: form.value.currency_id || 'ETB',
    supplier_registration_status_lookup_value_id: status
  };

  let registrationId: number;
  const existing = editingId.value
    ? supplierRegistrationsStore.value.find((r) => r.id === editingId.value)
    : undefined;

  if (existing) {
    registrationId = existing.id;
    Object.assign(existing, payload);
    if (isSubmitting) {
      existing.submitted_at = timestamp;
      existing.decided_at = null;
      existing.decided_by = null;
    }
  } else {
    registrationId = Math.max(0, ...supplierRegistrationsStore.value.map((r) => r.id)) + 1;
    supplierRegistrationsStore.value.unshift({
      id: registrationId,
      uuid: `sreg-${registrationId}-${Date.now()}`,
      registration_number: generateRegistrationNumber(
        supplierRegistrationsStore.value.map((r) => r.registration_number)
      ),
      ...payload,
      email_verified_at: null,
      phone_verified_at: null,
      verification_expires_at: null,
      submitted_at: isSubmitting ? timestamp : null,
      decided_at: null,
      decision_note: '',
      supplier_id: null,
      decided_by: null,
      state: 'active'
    });
  }

  // Persist Requested Categories
  const requestedCategories = categoryRows.value.filter((r) => r.procurement_category_id);
  let nextCategoryId =
    Math.max(0, ...supplierRegistrationCategoriesStore.value.map((c) => c.id)) + 1;
  supplierRegistrationCategoriesStore.value = [
    ...supplierRegistrationCategoriesStore.value.filter(
      (c) => c.supplier_registration_id !== registrationId
    ),
    ...requestedCategories.map((r) => {
      const id = r.id ?? nextCategoryId++;
      return {
        id,
        uuid: `srcat-${id}`,
        supplier_registration_id: registrationId,
        procurement_category_id: r.procurement_category_id,
        is_approved: r.is_approved,
        state: 'active' as const
      };
    })
  ];

  // Persist Compliance Documents
  const validDocs = documentRows.value.filter((d) => d.document_type_lookup_value_id);
  let nextDocId = Math.max(0, ...supplierRegistrationDocumentsStore.value.map((d) => d.id)) + 1;
  supplierRegistrationDocumentsStore.value = [
    ...supplierRegistrationDocumentsStore.value.filter(
      (d) => d.supplier_registration_id !== registrationId
    ),
    ...validDocs.map((d) => {
      const id = d.id ?? nextDocId++;
      return {
        id,
        uuid: `srdoc-${id}`,
        supplier_registration_id: registrationId,
        document_type_lookup_value_id: d.document_type_lookup_value_id,
        reference_number: d.reference_number.trim(),
        issued_at: d.issued_at,
        expires_at: d.expires_at,
        is_mandatory: Boolean(d.is_mandatory),
        remarks: d.remarks.trim(),
        state: 'active' as const
      };
    })
  ];

  // Persist Portal Contacts
  const validUsers = portalUserRows.value.filter((u) => u.full_name.trim() || u.email.trim());
  let nextUserId = Math.max(0, ...supplierRegistrationPortalUsersStore.value.map((u) => u.id)) + 1;
  supplierRegistrationPortalUsersStore.value = [
    ...supplierRegistrationPortalUsersStore.value.filter(
      (u) => u.supplier_registration_id !== registrationId
    ),
    ...validUsers.map((u) => {
      const id = u.id ?? nextUserId++;
      return {
        id,
        uuid: `srpu-${id}`,
        supplier_registration_id: registrationId,
        full_name: u.full_name.trim(),
        email: u.email.trim(),
        designation: u.designation.trim(),
        is_primary_contact: Boolean(u.is_primary_contact),
        state: 'active' as const
      };
    })
  ];

  return registrationId;
};

const handleSubmit = () => {
  if (!validateSubmit()) return;
  const previous = editingId.value
    ? supplierRegistrationsStore.value.find((r) => r.id === editingId.value)
    : undefined;
  const nextStatus: SupplierRegistrationStatus =
    previous?.supplier_registration_status_lookup_value_id === 'returned'
      ? 'pending_review'
      : 'pending_verification';
  const id = persist(nextStatus);
  isSaved.value = true;
  toast.success(
    nextStatus === 'pending_review'
      ? 'Registration resubmitted for review.'
      : 'Registration submitted. Verification links sent to the supplier.'
  );
  router.push(`/procurement/supplier-registrations/${id}`);
};

const handleSaveDraft = () => {
  if (!validateDraft()) return;
  const id = persist('draft');
  isSaved.value = true;
  toast.success('Registration saved as draft.');
  router.push(`/procurement/supplier-registrations/${id}`);
};

const topBarMenuItems = computed<DropdownMenuItem[]>(() => [
  { key: 'save-draft', label: 'Save as Draft', icon: Save, onClick: handleSaveDraft }
]);
</script>

<template>
  <div class="registration-create-page">
    <!-- Top Bar directly on transparent canvas -->
    <div class="create-top-bar">
      <AppBreadcrumb :items="breadcrumbItems" :noMargin="true">
        <template #badge>
          <SaveStateBadge :isSaved="isSaved" :isDraft="false" />
        </template>
      </AppBreadcrumb>

      <div class="top-bar-actions">
        <BaseDropdownMenu :items="topBarMenuItems" minWidth="180px">
          <template #trigger="{ toggle }">
            <AppButton variant="secondary-gray" size="sm" @click.stop="toggle">
              <MoreVertical :size="16" />
            </AppButton>
          </template>
        </BaseDropdownMenu>
        <AppButton variant="secondary-gray" size="sm" @click="clearForm">
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>
        <AppButton variant="primary" size="sm" @click="handleSubmit">Submit</AppButton>
      </div>
    </div>

    <div class="tabs-header-wrap">
      <BaseTabs v-model="activeTab" :tabs="tabs" />
    </div>

    <!-- TAB 1: REGISTRATION DETAILS (SupplierRegistration — main card + optional Bank Details) -->
    <div v-show="activeTab === 'details'" class="tab-panel-stack">
      <!-- Main Card: Company Logo + Business Identity + Contact & Address -->
      <div class="clean-card form-card-body">
        <!-- Optional Company Logo Uploader (EmployeeCreate Standard) -->
        <div class="logo-upload-row">
          <div class="logo-preview-circle">
            <img v-if="form.logo_url" :src="form.logo_url" alt="Company Logo" class="logo-preview-img" />
            <div v-else class="logo-empty-placeholder">
              <ImageIcon :size="24" class="logo-empty-icon" />
              <span>No Media</span>
            </div>
          </div>
          <div class="logo-upload-controls">
            <div class="logo-upload-buttons">
              <AppButton variant="outline" size="sm" @click="triggerLogoUpload">
                <template #icon-left><Upload :size="14" /></template>
                Upload New Logo
              </AppButton>
              <button
                v-if="form.logo_url"
                type="button"
                class="btn-remove-logo"
                @click="removeLogo"
              >
                Remove
              </button>
              <input
                ref="logoFileInput"
                type="file"
                accept="image/png,image/jpeg"
                class="hidden-file-input"
                @change="handleLogoChange"
              />
            </div>
            <p class="logo-upload-hint">
              At least 800×800 px recommended and size should be less than 10MB. JPG or PNG is allowed.
            </p>
          </div>
        </div>

        <div class="card-row-divider"></div>

        <div class="form-grid-3">
          <FormInput
            v-model="form.legal_name"
            label="Legal Name"
            :error="fieldErrors.legal_name"
            required
          />
          <FormInput v-model="form.trade_name" label="Trade Name" />
          <FormInput v-model="form.tin" label="TIN" :error="fieldErrors.tin" required />
        </div>

        <div class="form-grid-3">
          <FormInput v-model="form.vat_registration_number" label="VAT Registration Number" />
          <FormInput v-model="form.business_license_number" label="Business License Number" />
          <FormSelect
            v-model="form.business_type_lookup_value_id"
            label="Business Type"
            :options="businessTypeOptions"
            placeholder="Select Type"
            :error="fieldErrors.business_type"
            required
          />
        </div>

        <div class="form-grid-3">
          <FormSelect
            v-model="form.origin_lookup_value_id"
            label="Origin"
            :options="originOptions"
            placeholder="Select Origin"
            :error="fieldErrors.origin"
            required
          />
          <FormSelect
            v-model="form.entity_id"
            label="Applied To Entity"
            :options="entityOptions"
            placeholder="Select Entity"
            :error="fieldErrors.entity"
            required
          />
          <FormSelect
            v-model="form.fiscal_year_id"
            label="Fiscal Year"
            :options="fiscalYearOptions"
            placeholder="Select Year"
          />
        </div>

        <div class="card-row-divider"></div>

        <div class="form-grid-3">
          <FormInput
            v-model="form.contact_person_name"
            label="Contact Person"
            :error="fieldErrors.contact_person_name"
            required
          />
          <FormInput
            v-model="form.email"
            type="email"
            label="Email"
            :error="fieldErrors.email"
            required
          />
          <FormInput v-model="form.phone" type="tel" label="Phone" :error="fieldErrors.phone" required />
        </div>

        <div class="form-grid-3">
          <FormInput
            v-model="form.address"
            label="Head Office Address"
            :error="fieldErrors.address"
            required
          />
        </div>
      </div>

      <!-- Collapsible Card: Bank Details (optional) -->
      <div class="clean-card accordion-card">
        <div
          class="card-accordion-header"
          :class="{ 'is-collapsed': !isBankOpen }"
          @click="isBankOpen = !isBankOpen"
        >
          <span>Bank Details</span>
          <ChevronDown v-if="isBankOpen" :size="16" class="header-chevron" />
          <ChevronRight v-else :size="16" class="header-chevron" />
        </div>
        <div v-show="isBankOpen" class="form-card-body">
          <div class="form-grid-3">
            <FormInput v-model="form.bank_name" label="Bank Name" />
            <FormInput v-model="form.bank_branch" label="Bank Branch" />
            <FormInput v-model="form.bank_account_name" label="Account Name" />
          </div>

          <div class="form-grid-3">
            <FormInput v-model="form.bank_account_number" label="Account Number" />
          </div>
        </div>
      </div>
    </div>

    <!-- TAB 2: REQUESTED CATEGORIES (SupplierRegistrationCategory) -->
    <div v-show="activeTab === 'categories'" class="tab-panel-stack">
      <div class="clean-card subtable-card-container">
        <DynamicSubTable
          v-model="categoryRows"
          :columns="categoryColumns"
          entityName="Requested Category"
          entityNamePlural="Requested Categories"
          :defaultInitialRow="true"
          :newRowFactory="createCategoryRow"
        />
      </div>
    </div>

    <!-- TAB 3: QUALIFICATION (SupplierQualification + SupplierQualificationDocument) -->
    <div v-show="activeTab === 'documents'" class="tab-panel-stack">
      <!-- Collapsible Card: Qualification Terms (SupplierQualification) -->
      <div class="clean-card accordion-card">
        <div
          class="card-accordion-header"
          :class="{ 'is-collapsed': !isQualificationOpen }"
          @click="isQualificationOpen = !isQualificationOpen"
        >
          <span>Qualification Terms</span>
          <ChevronDown v-if="isQualificationOpen" :size="16" class="header-chevron" />
          <ChevronRight v-else :size="16" class="header-chevron" />
        </div>
        <div v-show="isQualificationOpen" class="form-card-body">
          <div class="form-grid-3">
            <FormInput v-model="form.qualified_from" type="date" label="Qualified From" />
            <FormInput
              v-model="form.qualified_to"
              type="date"
              label="Qualified To"
              :error="fieldErrors.qualified_to"
            />
          </div>

          <div class="checkbox-cards-grid">
            <FormCheckboxCard
              v-model="form.no_order_cap"
              :expand-when-checked="false"
              label="No Maximum Order Cap"
              description="Supplier has no single-PO value limit once qualified."
            >
              <div class="form-grid-2">
                <FormInput
                  v-model.number="form.maximum_order_value"
                  type="number"
                  label="Maximum Order Value"
                  :error="fieldErrors.maximum_order_value"
                  required
                />
                <FormSelect
                  v-model="form.currency_id"
                  label="Currency"
                  :options="currencyOptions"
                  placeholder="Select Currency"
                />
              </div>
            </FormCheckboxCard>
          </div>
        </div>
      </div>

      <!-- Compliance Documents (SupplierQualificationDocument) -->
      <div class="clean-card subtable-card-container">
        <DynamicSubTable
          v-model="documentRows"
          :columns="documentColumns"
          entityName="Compliance Document"
          entityNamePlural="Compliance Documents"
          :defaultInitialRow="true"
          :newRowFactory="createDocumentRow"
        >
          <template #expand-modal="{ row }">
            <div class="modal-expand-grid">
              <div class="form-grid-2">
                <FormSelect
                  v-model="row.document_type_lookup_value_id"
                  label="Document Type"
                  :options="supplierDocumentTypeOptions"
                  placeholder="Select Document"
                  :searchable="true"
                  required
                />
                <FormInput v-model="row.reference_number" label="Reference Number" />
              </div>

              <div class="form-grid-2">
                <FormInput v-model="row.issued_at" type="date" label="Issued Date" />
                <FormInput v-model="row.expires_at" type="date" label="Expiry Date" />
              </div>

              <div class="modal-checkbox-grid">
                <FormCheckbox
                  v-model="row.is_mandatory"
                  label="Mandatory for Approval"
                  description="Registration and qualification approval waits until this document is verified compliant."
                />
              </div>

              <FormTextarea v-model="row.remarks" label="Remarks" :rows="3" />
            </div>
          </template>
        </DynamicSubTable>
      </div>
    </div>

    <!-- TAB 4: PORTAL CONTACTS (SupplierUser) -->
    <div v-show="activeTab === 'portal_users'" class="tab-panel-stack">
      <div class="clean-card subtable-card-container">
        <DynamicSubTable
          v-model="portalUserRows"
          :columns="portalUserColumns"
          entityName="Portal Contact"
          entityNamePlural="Portal Contacts"
          :defaultInitialRow="true"
          :newRowFactory="createPortalUserRow"
        >
          <template #expand-modal="{ row }">
            <div class="modal-expand-grid">
              <div class="form-grid-2">
                <FormInput v-model="row.full_name" label="Contact Name" required />
                <FormInput v-model="row.email" type="email" label="Portal Email" required />
              </div>

              <div class="form-grid-2">
                <FormInput v-model="row.designation" label="Designation" />
              </div>

              <div class="modal-checkbox-grid">
                <FormCheckbox
                  v-model="row.is_primary_contact"
                  label="Primary Contact"
                  description="Main supplier contact for RFQs, awards, and portal notifications."
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
.registration-create-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

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

.tabs-header-wrap {
  display: flex;
  align-items: center;
}

.tab-panel-stack {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.clean-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  overflow: hidden;
}

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

.header-chevron {
  color: #737373;
  flex-shrink: 0;
}

.form-card-body {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.logo-upload-row {
  display: flex;
  align-items: center;
  gap: 20px;
}

.logo-preview-circle {
  width: 88px;
  height: 88px;
  border-radius: 9999px;
  border: 1px solid #e5e5e5;
  background-color: #fafafa;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  flex-shrink: 0;
}

.logo-preview-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.logo-empty-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  color: #737373;
}

.logo-empty-icon {
  color: #a1a1a1;
}

.logo-upload-controls {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.logo-upload-buttons {
  display: flex;
  align-items: center;
  gap: 12px;
}

.btn-remove-logo {
  background: none;
  border: none;
  padding: 0;
  font-size: 13px;
  font-weight: 500;
  color: #e7000b;
  cursor: pointer;
}

.hidden-file-input {
  display: none;
}

.logo-upload-hint {
  margin: 0;
  font-size: 12.5px;
  color: #737373;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 20px;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 20px;
}

.card-row-divider {
  height: 1px;
  background-color: #e5e5e5;
  width: 100%;
}

.checkbox-cards-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.subtable-card-container {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.modal-expand-grid {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.modal-checkbox-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 20px 16px;
  padding-top: 12px;
  border-top: 1px solid #f0f0f0;
}

@media (max-width: 960px) {
  .form-grid-2,
  .form-grid-3,
  .modal-checkbox-grid {
    grid-template-columns: 1fr;
  }
}
</style>
