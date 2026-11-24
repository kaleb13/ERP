import { ref } from 'vue';

export type GovernanceStatus = 'pending' | 'acceptForAll' | 'acceptForThis' | 'reject';
export type RowState = 'active' | 'inactive';

export interface PurchaseMethodRecord {
  id: number;
  uuid: string;
  code: string;
  name: string;
  description: string;
  minimum_quotations: number;
  requires_committee: boolean;
  requires_sealed_bid: boolean;
  requires_post_facto_approval: boolean;
  allows_single_source: boolean;
  is_open_invitation: boolean;
  entity_id: number | null;
  status: GovernanceStatus;
  state: RowState;
}

export interface PurchaseMethodThresholdRecord {
  id: number;
  uuid: string;
  purchase_method_id: number;
  method_name: string;
  method_code: string;
  minimum_amount: number;
  maximum_amount: number | null; // null = Unlimited
  currency_code: string;
  is_mandatory: boolean; // true = forces method, false = permits method
  procurement_category_id: number | null; // null = All Categories
  category_name?: string;
  procurement_unit_id: number | null; // null = All Units
  unit_name?: string;
  effective_from: string; // YYYY-MM-DD
  effective_to: string | null; // YYYY-MM-DD | null
  entity_id: number;
  state: RowState;
}

// ─── Initial Sourcing Methods Seed (procurement-v4.sql Lines 364–390) ───
export const initialPurchaseMethods: PurchaseMethodRecord[] = [
  {
    id: 1,
    uuid: 'pm-0001-direct',
    code: 'DIRECT',
    name: 'Direct Purchase',
    description: 'Off-the-shelf single supplier purchase for low-value threshold items without formal competitive quotations.',
    minimum_quotations: 0,
    requires_committee: false,
    requires_sealed_bid: false,
    requires_post_facto_approval: false,
    allows_single_source: true,
    is_open_invitation: false,
    entity_id: 2,
    status: 'acceptForAll',
    state: 'active'
  },
  {
    id: 2,
    uuid: 'pm-0002-rfq',
    code: 'RFQ',
    name: 'Proforma (RFQ)',
    description: 'Request for Quotations from pre-qualified or registered suppliers; requires at least three independent proformas.',
    minimum_quotations: 3,
    requires_committee: false,
    requires_sealed_bid: false,
    requires_post_facto_approval: false,
    allows_single_source: false,
    is_open_invitation: false,
    entity_id: 2,
    status: 'acceptForAll',
    state: 'active'
  },
  {
    id: 3,
    uuid: 'pm-0003-opentender',
    code: 'OPEN_TENDER',
    name: 'Open Competitive Tender',
    description: 'Public advertisement open to all qualified suppliers; requires formal sealed bids opened simultaneously and committee evaluation.',
    minimum_quotations: 3,
    requires_committee: true,
    requires_sealed_bid: true,
    requires_post_facto_approval: false,
    allows_single_source: false,
    is_open_invitation: true,
    entity_id: 2,
    status: 'acceptForAll',
    state: 'active'
  },
  {
    id: 4,
    uuid: 'pm-0004-restricted',
    code: 'RESTRICTED_TENDER',
    name: 'Restricted (Closed) Tender',
    description: 'Formal competitive bidding limited to short-listed pre-qualified vendors due to specialized technical capabilities.',
    minimum_quotations: 3,
    requires_committee: true,
    requires_sealed_bid: true,
    requires_post_facto_approval: false,
    allows_single_source: false,
    is_open_invitation: false,
    entity_id: 2,
    status: 'acceptForAll',
    state: 'active'
  },
  {
    id: 5,
    uuid: 'pm-0005-framework',
    code: 'FRAMEWORK',
    name: 'Framework Agreement Call-Off',
    description: 'Secondary call-off against pre-negotiated corporate master agreements with contracted rates and terms.',
    minimum_quotations: 0,
    requires_committee: false,
    requires_sealed_bid: false,
    requires_post_facto_approval: false,
    allows_single_source: false,
    is_open_invitation: false,
    entity_id: 2,
    status: 'acceptForAll',
    state: 'active'
  },
  {
    id: 6,
    uuid: 'pm-0006-emergency',
    code: 'EMERGENCY',
    name: 'Emergency Sourcing',
    description: 'Immediate critical procurement to prevent clinical or operational disruption; allows post-facto committee ratification.',
    minimum_quotations: 0,
    requires_committee: false,
    requires_sealed_bid: false,
    requires_post_facto_approval: true,
    allows_single_source: true,
    is_open_invitation: false,
    entity_id: 2,
    status: 'acceptForAll',
    state: 'active'
  }
];

// ─── Initial Spend Threshold Bands Seed (procurement-v4.sql Lines 437–462) ───
export const initialThresholdBands: PurchaseMethodThresholdRecord[] = [
  {
    id: 1,
    uuid: 'pmt-0001',
    purchase_method_id: 1,
    method_name: 'Direct Purchase',
    method_code: 'DIRECT',
    minimum_amount: 0,
    maximum_amount: 50000,
    currency_code: 'ETB',
    is_mandatory: true,
    procurement_category_id: null,
    category_name: 'All Categories',
    procurement_unit_id: null,
    unit_name: 'All Buying Units',
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    state: 'active'
  },
  {
    id: 2,
    uuid: 'pmt-0002',
    purchase_method_id: 2,
    method_name: 'Proforma (RFQ)',
    method_code: 'RFQ',
    minimum_amount: 50000.01,
    maximum_amount: 500000,
    currency_code: 'ETB',
    is_mandatory: true,
    procurement_category_id: null,
    category_name: 'All Categories',
    procurement_unit_id: null,
    unit_name: 'All Buying Units',
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    state: 'active'
  },
  {
    id: 3,
    uuid: 'pmt-0003',
    purchase_method_id: 3,
    method_name: 'Open Competitive Tender',
    method_code: 'OPEN_TENDER',
    minimum_amount: 500000.01,
    maximum_amount: null,
    currency_code: 'ETB',
    is_mandatory: true,
    procurement_category_id: null,
    category_name: 'All Categories',
    procurement_unit_id: null,
    unit_name: 'All Buying Units',
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    state: 'active'
  },
  {
    id: 4,
    uuid: 'pmt-0004',
    purchase_method_id: 5,
    method_name: 'Framework Agreement Call-Off',
    method_code: 'FRAMEWORK',
    minimum_amount: 0,
    maximum_amount: null,
    currency_code: 'ETB',
    is_mandatory: false,
    procurement_category_id: 10,
    category_name: 'Food & Beverage',
    procurement_unit_id: null,
    unit_name: 'All Buying Units',
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    state: 'active'
  },
  {
    id: 5,
    uuid: 'pmt-0005',
    purchase_method_id: 4,
    method_name: 'Restricted (Closed) Tender',
    method_code: 'RESTRICTED_TENDER',
    minimum_amount: 500000.01,
    maximum_amount: 2500000,
    currency_code: 'ETB',
    is_mandatory: false,
    procurement_category_id: 20,
    category_name: 'Kitchen & Medical Equipment',
    procurement_unit_id: 1,
    unit_name: 'Central Procurement Directorate',
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    state: 'active'
  }
];

// Reactive stores
export const purchaseMethodsStore = ref<PurchaseMethodRecord[]>([...initialPurchaseMethods]);
export const thresholdBandsStore = ref<PurchaseMethodThresholdRecord[]>([...initialThresholdBands]);

// Options catalogs
export const methodOptions = [
  { value: '1', label: 'Direct Purchase (DIRECT)' },
  { value: '2', label: 'Proforma / RFQ (RFQ)' },
  { value: '3', label: 'Open Competitive Tender (OPEN_TENDER)' },
  { value: '4', label: 'Restricted / Closed Tender (RESTRICTED_TENDER)' },
  { value: '5', label: 'Framework Agreement Call-Off (FRAMEWORK)' },
  { value: '6', label: 'Emergency Sourcing (EMERGENCY)' }
];

export const categoryOptions = [
  { value: '', label: 'All Categories (Global Scope)' },
  { value: '10', label: 'Food & Beverage (FB)' },
  { value: '11', label: 'Perishables (FB-PERISH)' },
  { value: '20', label: 'Kitchen & Medical Equipment (CAPEX-KIT)' },
  { value: '30', label: 'Cleaning & Hospitality Services (SVC-CLEAN)' },
  { value: '50', label: 'Office Supplies & Consumables (OFFICE)' }
];

export const unitOptions = [
  { value: '', label: 'All Buying Units (Global Scope)' },
  { value: '1', label: 'Central Procurement Directorate (PU-CENT)' },
  { value: '2', label: 'Bole Medhanealem Branch Buying Desk (PU-BOLE)' },
  { value: '3', label: 'Adama Regional Buying Hub (PU-ADAMA)' }
];

export const entityOptions = [
  { value: '2', label: 'Haleta General Hospital (HQ)' },
  { value: '3', label: 'Bole Specialty Clinic' },
  { value: '4', label: 'Adama Referral Center' }
];

export const governanceStatusOptions = [
  { value: 'acceptForAll', label: 'Shared with All Subsidiaries' },
  { value: 'acceptForThis', label: 'Restricted to Owning Entity' },
  { value: 'pending', label: 'Pending Governance Review' },
  { value: 'reject', label: 'Rejected / Deprecated' }
];

// Helpers
export const formatCurrency = (amount: number | null, currency: string = 'ETB'): string => {
  if (amount === null || amount === undefined) return 'Unlimited';
  return `${currency} ${amount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
};

export const getGovernanceStatusLabel = (status: GovernanceStatus): string => {
  switch (status) {
    case 'acceptForAll': return 'Shared All';
    case 'acceptForThis': return 'Entity Only';
    case 'pending': return 'Pending';
    case 'reject': return 'Rejected';
    default: return status;
  }
};

export const generateMethodCode = (name: string, existingCodes: string[] = []): string => {
  if (!name.trim()) return '';
  const base = name
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9\s]/g, '')
    .split(/\s+/)
    .slice(0, 3)
    .join('_');
  let code = base;
  let counter = 2;
  while (existingCodes.includes(code)) {
    code = `${base}_${counter}`;
    counter++;
  }
  return code;
};
