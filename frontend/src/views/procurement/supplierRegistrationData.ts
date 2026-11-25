import { ref } from 'vue';
import ethioTelecomLogo from '../../assets/Ethiotelecom.png';
import shoaLogo from '../../assets/Shoa.png';
import siemensLogo from '../../assets/Siemens.png';
import queensLogo from '../../assets/Queens.png';

/**
 * Supplier Registration data layer.
 * Schema source: procurement-v4.sql #3 -> SupplierRegistration + SupplierRegistrationCategory.
 * Lookups: SUPPLIER_REGISTRATION_STATUS, SUPPLIER_BUSINESS_TYPE, PROCUREMENT_ORIGIN.
 */

export type SupplierRegistrationStatus =
  | 'draft'
  | 'pending_verification'
  | 'pending_review'
  | 'returned'
  | 'approved'
  | 'rejected'
  | 'inactive';
export type SupplierBusinessType =
  | 'manufacturer'
  | 'distributor'
  | 'retailer'
  | 'importer'
  | 'service_provider'
  | 'contractor'
  | 'consultant';
export type ProcurementOrigin = 'local' | 'foreign';
export type SupplierDocumentType =
  | 'trade_license'
  | 'business_registration'
  | 'tin_certificate'
  | 'vat_certificate'
  | 'tax_clearance'
  | 'ppa_registration'
  | 'professional_license'
  | 'bank_statement'
  | 'audited_financials'
  | 'experience_letter'
  | 'iso_certificate';
export type RowState = 'active' | 'inactive';

export interface SupplierBankDetails {
  bank_name: string;
  branch: string;
  account_name: string;
  account_number: string;
}

export interface SupplierRegistrationCategoryRecord {
  id: number;
  uuid: string;
  supplier_registration_id: number;
  procurement_category_id: string;
  /** NULL = undecided by the approver */
  is_approved: boolean | null;
  state: RowState;
}

export interface SupplierRegistrationDocumentRecord {
  id: number;
  uuid: string;
  supplier_registration_id: number;
  document_type_lookup_value_id: SupplierDocumentType | '';
  reference_number: string;
  issued_at: string;
  expires_at: string;
  is_mandatory: boolean;
  remarks: string;
  state: RowState;
}

export interface SupplierRegistrationPortalUserRecord {
  id: number;
  uuid: string;
  supplier_registration_id: number;
  full_name: string;
  email: string;
  designation: string;
  is_primary_contact: boolean;
  state: RowState;
}

export interface SupplierRegistrationRecord {
  id: number;
  uuid: string;
  registration_number: string;
  logo_url?: string;
  legal_name: string;
  trade_name: string;
  tin: string;
  vat_registration_number: string;
  business_license_number: string;
  contact_person_name: string;
  email: string;
  phone: string;
  address: string;
  bank_details: SupplierBankDetails | null;
  email_verified_at: string | null;
  phone_verified_at: string | null;
  verification_expires_at: string | null;
  submitted_at: string | null;
  decided_at: string | null;
  decision_note: string;
  business_type_lookup_value_id: SupplierBusinessType;
  origin_lookup_value_id: ProcurementOrigin;
  entity_id: string;
  fiscal_year_id: string;
  qualified_from: string;
  qualified_to: string;
  maximum_order_value: number | null;
  currency_id: string;
  supplier_id: number | null;
  decided_by: string | null;
  supplier_registration_status_lookup_value_id: SupplierRegistrationStatus;
  state: RowState;
}

// ─── Lookup Options ──────────────────────────────────────────────────────────
export const registrationStatusOptions = [
  { value: 'draft', label: 'Draft' },
  { value: 'pending_verification', label: 'Pending Verification' },
  { value: 'pending_review', label: 'Pending Review' },
  { value: 'returned', label: 'Returned' },
  { value: 'approved', label: 'Approved' },
  { value: 'rejected', label: 'Rejected' },
  { value: 'inactive', label: 'Inactive' }
];

export const businessTypeOptions = [
  { value: 'manufacturer', label: 'Manufacturer' },
  { value: 'distributor', label: 'Distributor' },
  { value: 'retailer', label: 'Retailer' },
  { value: 'importer', label: 'Importer' },
  { value: 'service_provider', label: 'Service Provider' },
  { value: 'contractor', label: 'Contractor' },
  { value: 'consultant', label: 'Consultant' }
];

export const originOptions = [
  { value: 'local', label: 'Local' },
  { value: 'foreign', label: 'Foreign' }
];

export const entityOptions = [
  { value: '2', label: 'Sheraton Ethiopia' },
  { value: '3', label: 'Sheraton Addis Branch' }
];

export const fiscalYearOptions = [
  { value: 'FY-2026', label: 'FY 2026 (Jul 1, 2026 – Jun 30, 2027)' },
  { value: 'FY-2027', label: 'FY 2027 (Jul 1, 2027 – Jun 30, 2028)' }
];

export const currencyOptions = [
  { value: 'ETB', label: 'ETB — Ethiopian Birr' },
  { value: 'USD', label: 'USD — US Dollar' },
  { value: 'EUR', label: 'EUR — Euro' }
];

export const categoryOptions = [
  { value: '10', label: 'Food & Beverage (FB)' },
  { value: '11', label: 'Fresh Produce (FB-PROD)' },
  { value: '20', label: 'Capital Equipment (CAPEX)' },
  { value: '30', label: 'Cleaning Services (CLEAN)' },
  { value: '50', label: 'Office Supplies (OFFICE)' }
];

export const supplierDocumentTypeOptions = [
  { value: 'trade_license', label: 'Trade License' },
  { value: 'business_registration', label: 'Business Registration' },
  { value: 'tin_certificate', label: 'TIN Certificate' },
  { value: 'vat_certificate', label: 'VAT Certificate' },
  { value: 'tax_clearance', label: 'Tax Clearance' },
  { value: 'ppa_registration', label: 'PPA Registration' },
  { value: 'professional_license', label: 'Professional License' },
  { value: 'bank_statement', label: 'Bank Statement' },
  { value: 'audited_financials', label: 'Audited Financials' },
  { value: 'experience_letter', label: 'Experience Letter' },
  { value: 'iso_certificate', label: 'ISO Certificate' }
];

export const resolutionOptions = [
  { value: 'approved', label: 'Approve Registration' },
  { value: 'returned', label: 'Return for Correction' },
  { value: 'rejected', label: 'Reject Registration' }
];

// ─── Label & Badge Helpers ───────────────────────────────────────────────────
export function getStatusLabel(val: SupplierRegistrationStatus): string {
  return registrationStatusOptions.find((o) => o.value === val)?.label ?? val;
}

export function getStatusBadgeColor(
  val: SupplierRegistrationStatus
): 'success' | 'warning' | 'error' | 'indigo' | 'purple' | 'primary' | 'gray' {
  switch (val) {
    case 'approved':
      return 'success';
    case 'pending_verification':
      return 'warning';
    case 'pending_review':
      return 'indigo';
    case 'returned':
      return 'purple';
    case 'rejected':
      return 'error';
    case 'inactive':
      return 'gray';
    case 'draft':
    default:
      return 'primary';
  }
}

export function getBusinessTypeLabel(val: SupplierBusinessType): string {
  return businessTypeOptions.find((o) => o.value === val)?.label ?? val;
}

export function getOriginLabel(val: ProcurementOrigin): string {
  return originOptions.find((o) => o.value === val)?.label ?? val;
}

export function getEntityLabel(val: string): string {
  return entityOptions.find((o) => o.value === val)?.label ?? val;
}

export function getFiscalYearLabel(val: string): string {
  return val ? (fiscalYearOptions.find((o) => o.value === val)?.label ?? val) : '—';
}

export function getCategoryLabel(val: string): string {
  return categoryOptions.find((o) => o.value === val)?.label ?? val;
}

export function getCategoryDecisionLabel(val: boolean | null): string {
  if (val === true) return 'Granted';
  if (val === false) return 'Declined';
  return 'Undecided';
}

export function getCategoryDecisionColor(val: boolean | null): 'success' | 'error' | 'warning' {
  if (val === true) return 'success';
  if (val === false) return 'error';
  return 'warning';
}

export function maskAccountNumber(val: string): string {
  if (!val) return '—';
  return val.length <= 4 ? val : `•••• ${val.slice(-4)}`;
}

export function generateRegistrationNumber(existing: string[]): string {
  const max = existing.reduce((acc, num) => {
    const n = Number(num.replace(/\D/g, ''));
    return Number.isFinite(n) && n > acc ? n : acc;
  }, 0);
  return `SREG-${String(max + 1).padStart(3, '0')}`;
}

// ─── Seed Data (Aligned with procurement-v4.sql examples, lines 765-786) ─────
export const supplierRegistrationsStore = ref<SupplierRegistrationRecord[]>([
  {
    id: 1,
    uuid: 'sreg-0001-ethio-telecom',
    registration_number: 'SREG-041',
    logo_url: ethioTelecomLogo,
    legal_name: 'Ethio Telecom',
    trade_name: 'ethio telecom',
    tin: '0011223344',
    vat_registration_number: 'VAT-0044821',
    business_license_number: 'AA/1123/18',
    contact_person_name: 'Abebe Kebede',
    email: 'enterprise@ethiotelecom.et',
    phone: '+251 11 551 5700',
    address: 'Churchill Avenue, Addis Ababa',
    bank_details: {
      bank_name: 'Awash Bank',
      branch: 'Bole Branch',
      account_name: 'Ethio Telecom',
      account_number: '01320456789000'
    },
    email_verified_at: '2026-07-02 10:15',
    phone_verified_at: '2026-07-02 10:22',
    verification_expires_at: null,
    submitted_at: '2026-07-01 09:00',
    decided_at: '2026-07-03 14:30',
    decision_note: '',
    business_type_lookup_value_id: 'service_provider',
    origin_lookup_value_id: 'local',
    entity_id: '2',
    fiscal_year_id: 'FY-2026',
    qualified_from: '2026-07-01',
    qualified_to: '2027-06-30',
    maximum_order_value: 1500000,
    currency_id: 'ETB',
    supplier_id: 501,
    decided_by: 'Marta Tadesse',
    supplier_registration_status_lookup_value_id: 'approved',
    state: 'active'
  },
  {
    id: 2,
    uuid: 'sreg-0002-shoa',
    registration_number: 'SREG-042',
    logo_url: shoaLogo,
    legal_name: 'Shoa Supermarket',
    trade_name: 'Shoa Shopping Center',
    tin: '0022334455',
    vat_registration_number: 'VAT-0055102',
    business_license_number: 'AA/4512/19',
    contact_person_name: 'Yonas Tadesse',
    email: 'wholesale@shoasupermarket.example',
    phone: '+251 11 662 4400',
    address: 'Bole Road, Addis Ababa',
    bank_details: {
      bank_name: 'Dashen Bank',
      branch: 'Mexico Branch',
      account_name: 'Shoa Supermarket',
      account_number: '5018229044412'
    },
    email_verified_at: null,
    phone_verified_at: null,
    verification_expires_at: '2026-07-25 23:59',
    submitted_at: '2026-07-18 11:40',
    decided_at: null,
    decision_note: '',
    business_type_lookup_value_id: 'distributor',
    origin_lookup_value_id: 'local',
    entity_id: '2',
    fiscal_year_id: 'FY-2026',
    qualified_from: '2026-07-20',
    qualified_to: '2027-06-30',
    maximum_order_value: 500000,
    currency_id: 'ETB',
    supplier_id: 502,
    decided_by: null,
    supplier_registration_status_lookup_value_id: 'pending_verification',
    state: 'active'
  },
  {
    id: 3,
    uuid: 'sreg-0003-gondar',
    registration_number: 'SREG-043',
    legal_name: 'Gondar Dairy Union',
    trade_name: '',
    tin: '0034567890',
    vat_registration_number: 'VAT-0051930',
    business_license_number: 'AM/0455/17',
    contact_person_name: 'Wubet Alemu',
    email: 'union@gondardairy.example',
    phone: '+251 918 55 66 77',
    address: 'Gondar City, Amhara Region',
    bank_details: null,
    email_verified_at: '2026-07-18 08:05',
    phone_verified_at: '2026-07-18 08:12',
    verification_expires_at: null,
    submitted_at: '2026-07-17 16:20',
    decided_at: '2026-07-20 10:00',
    decision_note: 'Trade licence expired on 2026-06-30; resubmit with a renewed licence.',
    business_type_lookup_value_id: 'manufacturer',
    origin_lookup_value_id: 'local',
    entity_id: '2',
    fiscal_year_id: 'FY-2026',
    qualified_from: '',
    qualified_to: '',
    maximum_order_value: null,
    currency_id: 'ETB',
    supplier_id: null,
    decided_by: 'Marta Tadesse',
    supplier_registration_status_lookup_value_id: 'rejected',
    state: 'active'
  },
  {
    id: 4,
    uuid: 'sreg-0004-siemens',
    registration_number: 'SREG-044',
    logo_url: siemensLogo,
    legal_name: 'Siemens AG',
    trade_name: 'Siemens Industrial',
    tin: 'DE-812904411',
    vat_registration_number: 'DE812904411',
    business_license_number: 'ISO-9001-DE-882',
    contact_person_name: 'Lukas Weber',
    email: 'export@siemens.example',
    phone: '+49 89 636 00',
    address: 'Werner-von-Siemens-Strasse 1, Munich, Germany',
    bank_details: {
      bank_name: 'Deutsche Bank',
      branch: 'Munich Branch',
      account_name: 'Siemens AG',
      account_number: 'DE89 3704 0044 0532 0130 7781'
    },
    email_verified_at: '2026-08-02 09:10',
    phone_verified_at: '2026-08-02 09:18',
    verification_expires_at: null,
    submitted_at: '2026-08-01 15:00',
    decided_at: null,
    decision_note: '',
    business_type_lookup_value_id: 'manufacturer',
    origin_lookup_value_id: 'foreign',
    entity_id: '2',
    fiscal_year_id: 'FY-2026',
    qualified_from: '2026-08-01',
    qualified_to: '2028-07-31',
    maximum_order_value: null,
    currency_id: 'EUR',
    supplier_id: null,
    decided_by: null,
    supplier_registration_status_lookup_value_id: 'pending_review',
    state: 'active'
  },
  {
    id: 5,
    uuid: 'sreg-0005-queens',
    registration_number: 'SREG-045',
    logo_url: queensLogo,
    legal_name: 'Queens Supermarket',
    trade_name: 'Queens Retail PLC',
    tin: '0012345678',
    vat_registration_number: 'VAT-0044821',
    business_license_number: 'AA/4410/21',
    contact_person_name: 'Lemlem Haile',
    email: 'corporate@queenssupermarket.example',
    phone: '+251 11 667 3040',
    address: 'Bole Sub-city, Woreda 03, Addis Ababa',
    bank_details: {
      bank_name: 'Awash Bank',
      branch: 'Bole Branch',
      account_name: 'Queens Supermarket',
      account_number: '01320456789000'
    },
    email_verified_at: '2026-08-05 12:00',
    phone_verified_at: '2026-08-05 12:07',
    verification_expires_at: null,
    submitted_at: '2026-08-04 10:30',
    decided_at: '2026-08-06 13:45',
    decision_note: 'Renewed tax clearance certificate required before final sign-off.',
    business_type_lookup_value_id: 'retailer',
    origin_lookup_value_id: 'local',
    entity_id: '2',
    fiscal_year_id: 'FY-2026',
    qualified_from: '2026-07-05',
    qualified_to: '2027-06-30',
    maximum_order_value: 200000,
    currency_id: 'ETB',
    supplier_id: 540,
    decided_by: 'Marta Tadesse',
    supplier_registration_status_lookup_value_id: 'returned',
    state: 'active'
  },
  {
    id: 6,
    uuid: 'sreg-0006-selam',
    registration_number: 'SREG-046',
    legal_name: 'Selam Catering Services',
    trade_name: '',
    tin: '0067890123',
    vat_registration_number: '',
    business_license_number: '',
    contact_person_name: 'Selam Worku',
    email: 'hello@selamcatering.example',
    phone: '+251 955 44 33 22',
    address: 'Yeka Sub-city, Addis Ababa',
    bank_details: null,
    email_verified_at: null,
    phone_verified_at: null,
    verification_expires_at: null,
    submitted_at: null,
    decided_at: null,
    decision_note: '',
    business_type_lookup_value_id: 'service_provider',
    origin_lookup_value_id: 'local',
    entity_id: '2',
    fiscal_year_id: '',
    qualified_from: '',
    qualified_to: '',
    maximum_order_value: null,
    currency_id: 'ETB',
    supplier_id: null,
    decided_by: null,
    supplier_registration_status_lookup_value_id: 'draft',
    state: 'active'
  }
]);

export const supplierRegistrationCategoriesStore = ref<SupplierRegistrationCategoryRecord[]>([
  { id: 1, uuid: 'srcat-0001', supplier_registration_id: 1, procurement_category_id: '50', is_approved: true, state: 'active' },
  { id: 2, uuid: 'srcat-0002', supplier_registration_id: 1, procurement_category_id: '10', is_approved: false, state: 'active' },
  { id: 3, uuid: 'srcat-0003', supplier_registration_id: 2, procurement_category_id: '30', is_approved: null, state: 'active' },
  { id: 4, uuid: 'srcat-0004', supplier_registration_id: 3, procurement_category_id: '10', is_approved: false, state: 'active' },
  { id: 5, uuid: 'srcat-0005', supplier_registration_id: 4, procurement_category_id: '20', is_approved: null, state: 'active' },
  { id: 6, uuid: 'srcat-0006', supplier_registration_id: 4, procurement_category_id: '50', is_approved: null, state: 'active' },
  { id: 7, uuid: 'srcat-0007', supplier_registration_id: 5, procurement_category_id: '50', is_approved: null, state: 'active' },
  { id: 8, uuid: 'srcat-0008', supplier_registration_id: 6, procurement_category_id: '10', is_approved: null, state: 'active' }
]);

export function getRegistrationCategories(registrationId: number) {
  return supplierRegistrationCategoriesStore.value.filter(
    (c) => c.supplier_registration_id === registrationId
  );
}

export const supplierRegistrationDocumentsStore = ref<SupplierRegistrationDocumentRecord[]>([
  {
    id: 1,
    uuid: 'srdoc-0001',
    supplier_registration_id: 1,
    document_type_lookup_value_id: 'trade_license',
    reference_number: 'AA/1123/18',
    issued_at: '2026-01-15',
    expires_at: '2027-01-15',
    is_mandatory: true,
    remarks: '',
    state: 'active'
  },
  {
    id: 2,
    uuid: 'srdoc-0002',
    supplier_registration_id: 1,
    document_type_lookup_value_id: 'vat_certificate',
    reference_number: 'VAT-0044821',
    issued_at: '2025-07-01',
    expires_at: '',
    is_mandatory: true,
    remarks: '',
    state: 'active'
  },
  {
    id: 3,
    uuid: 'srdoc-0003',
    supplier_registration_id: 2,
    document_type_lookup_value_id: 'trade_license',
    reference_number: 'AA/4512/19',
    issued_at: '2026-02-01',
    expires_at: '2027-02-01',
    is_mandatory: true,
    remarks: '',
    state: 'active'
  },
  {
    id: 4,
    uuid: 'srdoc-0004',
    supplier_registration_id: 4,
    document_type_lookup_value_id: 'trade_license',
    reference_number: 'DE-HRB-6684',
    issued_at: '2026-01-10',
    expires_at: '2028-01-10',
    is_mandatory: true,
    remarks: '',
    state: 'active'
  },
  {
    id: 5,
    uuid: 'srdoc-0005',
    supplier_registration_id: 4,
    document_type_lookup_value_id: 'iso_certificate',
    reference_number: 'ISO-9001-DE-882',
    issued_at: '2025-05-01',
    expires_at: '2028-05-01',
    is_mandatory: false,
    remarks: '',
    state: 'active'
  }
]);

export function getRegistrationDocuments(registrationId: number) {
  return supplierRegistrationDocumentsStore.value.filter(
    (d) => d.supplier_registration_id === registrationId
  );
}

export function getDocumentTypeLabel(val: string): string {
  return supplierDocumentTypeOptions.find((o) => o.value === val)?.label ?? val;
}

export const supplierRegistrationPortalUsersStore = ref<SupplierRegistrationPortalUserRecord[]>([
  {
    id: 1,
    uuid: 'srpu-0001',
    supplier_registration_id: 1,
    full_name: 'Abebe Kebede',
    email: 'enterprise@ethiotelecom.et',
    designation: 'Enterprise Account Director',
    is_primary_contact: true,
    state: 'active'
  },
  {
    id: 2,
    uuid: 'srpu-0002',
    supplier_registration_id: 2,
    full_name: 'Yonas Tadesse',
    email: 'wholesale@shoasupermarket.example',
    designation: 'Wholesale Manager',
    is_primary_contact: true,
    state: 'active'
  },
  {
    id: 3,
    uuid: 'srpu-0003',
    supplier_registration_id: 4,
    full_name: 'Lukas Weber',
    email: 'export@siemens.example',
    designation: 'Export Manager',
    is_primary_contact: true,
    state: 'active'
  },
  {
    id: 4,
    uuid: 'srpu-0004',
    supplier_registration_id: 4,
    full_name: 'Hannah Klein',
    email: 'tenders@siemens.example',
    designation: 'Bid Coordinator',
    is_primary_contact: false,
    state: 'active'
  }
]);

export function getRegistrationPortalUsers(registrationId: number) {
  return supplierRegistrationPortalUsersStore.value.filter(
    (u) => u.supplier_registration_id === registrationId
  );
}

