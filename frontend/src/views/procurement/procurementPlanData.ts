import { ref } from 'vue';

export type PlanPeriodType = 'annual' | 'semi_annual' | 'quarterly' | 'monthly';
export type PlanStatus =
  | 'draft'
  | 'submitted'
  | 'returned'
  | 'approved'
  | 'revised'
  | 'rejected'
  | 'closed'
  | 'cancelled';
export type PlanVersionStatus = 'submitted' | 'approved' | 'rejected';
export type PlanLineStatus = 'pending' | 'approved' | 'on_hold' | 'rejected';
export type RowState = 'active' | 'inactive';

export interface ProcurementPlanRecord {
  id: number;
  uuid: string;
  plan_number: string;
  name: string;
  period_start: string;
  period_end: string;
  approved_at: string | null;
  notes: string;
  period_type_lookup_value_id: PlanPeriodType;
  procurement_unit_id: number | null;
  procurement_unit_name: string;
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  currency_id: string;
  fiscal_year_id: string;
  budget_id: string | null;
  budget_name: string;
  document_id: string | null;
  plan_status_lookup_value_id: PlanStatus;
  user_id: number;
  state: RowState;
}

export interface ProcurementPlanVersionRecord {
  id: number;
  uuid: string;
  procurement_plan_id: number;
  version_number: number;
  reason: string | null;
  revised_at: string;
  superseded_at: string | null;
  document_id: string | null;
  revised_by: string;
  plan_version_status_lookup_value_id: PlanVersionStatus;
  user_id: number;
  state: RowState;
}

export interface ProcurementPlanVersionLineRecord {
  id: number;
  uuid: string;
  procurement_plan_version_id: number;
  line_number: number;
  description: string;
  planned_quantity: number;
  estimated_unit_price: number;
  estimated_amount: number;
  requisitioned_quantity: number;
  ordered_quantity: number;
  received_quantity: number;
  actual_amount: number;
  required_from: string;
  required_to: string;
  is_recurring: boolean;
  decision_note: string;
  carried_from_line_id: number | null;
  procurement_category_id: number;
  category_name: string;
  purchase_method_id: number | null;
  purchase_method_name: string;
  tenant_id: number;
  entity_id: number;
  organization_unit_id: string | null;
  organization_unit_name: string;
  product_id: string | null;
  product_name: string;
  measurement_id: string | null;
  location_id: string | null;
  location_name: string;
  budget_line_id: string | null;
  cost_center_dimension_id: string | null;
  plan_line_status_lookup_value_id: PlanLineStatus;
  user_id: number;
  state: RowState;
}

// ─── Lookup Options (procurement-v4.sql Lines 155-159) ────────────────────────
export const planPeriodTypeOptions = [
  { value: 'annual', label: 'Annual' },
  { value: 'semi_annual', label: 'Semi-Annual' },
  { value: 'quarterly', label: 'Quarterly' },
  { value: 'monthly', label: 'Monthly' }
];

export const planStatusOptions = [
  { value: 'draft', label: 'Draft' },
  { value: 'submitted', label: 'Submitted' },
  { value: 'returned', label: 'Returned' },
  { value: 'approved', label: 'Approved' },
  { value: 'revised', label: 'Revised' },
  { value: 'rejected', label: 'Rejected' },
  { value: 'closed', label: 'Closed' },
  { value: 'cancelled', label: 'Cancelled' }
];

export const planVersionStatusOptions = [
  { value: 'submitted', label: 'Submitted' },
  { value: 'approved', label: 'Approved' },
  { value: 'rejected', label: 'Rejected' }
];

export const planLineStatusOptions = [
  { value: 'pending', label: 'Pending' },
  { value: 'approved', label: 'Approved' },
  { value: 'on_hold', label: 'On Hold' },
  { value: 'rejected', label: 'Rejected' }
];

export const fiscalYearOptions = [
  { value: 'FY-2026', label: 'FY 2026 (2026-07-01 – 2027-06-30)' },
  { value: 'FY-2027', label: 'FY 2027 (2027-07-01 – 2028-06-30)' }
];

export const currencyOptions = [
  { value: 'ETB', label: 'ETB — Ethiopian Birr' },
  { value: 'USD', label: 'USD — US Dollar' },
  { value: 'EUR', label: 'EUR — Euro' }
];

export const budgetOptions = [
  { value: '', label: 'No Linked Budget' },
  { value: 'BUD-2026-FB', label: 'BUD-2026-FB — F&B Operating Budget' },
  { value: 'BUD-2026-CAPEX', label: 'BUD-2026-CAPEX — Capital Expenditure Budget' },
  { value: 'BUD-2026-OPS', label: 'BUD-2026-OPS — General Operations Budget' }
];

export const unitOptions = [
  { value: '', label: 'Whole Entity (Shared)' },
  { value: '1', label: 'Central Procurement Hub (CPU-HQ)' },
  { value: '2', label: 'F&B Purchasing Desk (CPU-FB)' },
  { value: '3', label: 'IT & Capital Projects Desk (CPU-IT)' }
];

export const entityOptions = [
  { value: '2', label: 'Sheraton Ethiopia' },
  { value: '3', label: 'Sheraton Addis Branch' }
];

export const productOptions = [
  { value: '', label: 'Free-Text / Uncatalogued Item' },
  { value: 'PROD-101', label: 'Fresh Roma Tomato (PROD-101)' },
  { value: 'PROD-102', label: 'Red Onion Grade A (PROD-102)' },
  { value: 'PROD-205', label: 'Commercial Planetary Mixer 40L (PROD-205)' },
  { value: 'PROD-301', label: 'Enterprise Laptop Workstation (PROD-301)' },
  { value: 'PROD-302', label: 'A4 Printing Paper 80gsm Carton (PROD-302)' }
];

export const measurementOptions = [
  { value: 'KG', label: 'Kilogram (KG)' },
  { value: 'PCS', label: 'Pieces (PCS)' },
  { value: 'LTR', label: 'Litre (LTR)' },
  { value: 'BOX', label: 'Box / Carton (BOX)' },
  { value: 'SET', label: 'Set (SET)' }
];

export const categoryOptions = [
  { value: '10', label: 'Food & Beverage (FB)' },
  { value: '11', label: 'Fresh Produce (FB-PROD)' },
  { value: '20', label: 'Capital Equipment (CAPEX)' },
  { value: '30', label: 'IT & Office Supplies (IT-OPS)' }
];

export const purchaseMethodOptions = [
  { value: '', label: 'Decide Later' },
  { value: '1', label: 'Direct Purchase (DIRECT)' },
  { value: '2', label: 'Proforma / RFQ (RFQ)' },
  { value: '3', label: 'Open Competitive Tender (OPEN_TENDER)' },
  { value: '5', label: 'Framework Agreement Call-Off (FRAMEWORK)' }
];

export const organizationUnitOptions = [
  { value: '', label: 'Entity-Wide' },
  { value: '12', label: 'Food & Beverage (Dept 12)' },
  { value: '14', label: 'Engineering & Maintenance (Dept 14)' },
  { value: '18', label: 'Information Technology (Dept 18)' },
  { value: '22', label: 'Finance & Administration (Dept 22)' }
];

export const locationOptions = [
  { value: '', label: 'Default Receiving Store' },
  { value: 'LOC-MAIN', label: 'Main Cold & Dry Store (Addis HQ)' },
  { value: 'LOC-IT', label: 'IT Asset Vault (HQ)' },
  { value: 'LOC-ENG', label: 'Engineering Workshop Store' }
];

export const budgetLineOptions = [
  { value: '', label: 'Unallocated' },
  { value: 'BL-5100', label: 'BL-5100 — Culinary Raw Materials' },
  { value: 'BL-6200', label: 'BL-6200 — Kitchen Machinery CAPEX' },
  { value: 'BL-5400', label: 'BL-5400 — IT Hardware & Office Consumables' }
];

export const costCenterOptions = [
  { value: '', label: 'None' },
  { value: 'CC-FB-01', label: 'CC-FB-01 — Banquet & Kitchens' },
  { value: 'CC-IT-01', label: 'CC-IT-01 — Corporate IT' },
  { value: 'CC-ADM-01', label: 'CC-ADM-01 — General Administration' }
];

// ─── Label & Badge Helpers ────────────────────────────────────────────────────
export function getPlanPeriodTypeLabel(val: PlanPeriodType): string {
  return planPeriodTypeOptions.find((o) => o.value === val)?.label ?? val;
}

export function getPlanStatusLabel(val: PlanStatus): string {
  return planStatusOptions.find((o) => o.value === val)?.label ?? val;
}

export function getPlanStatusBadgeColor(
  val: PlanStatus
): 'success' | 'warning' | 'error' | 'blue' | 'indigo' | 'purple' | 'primary' | 'gray' {
  switch (val) {
    case 'approved':
      return 'success';
    case 'submitted':
      return 'indigo';
    case 'returned':
    case 'revised':
      return 'warning';
    case 'rejected':
    case 'cancelled':
      return 'error';
    case 'closed':
      return 'blue';
    case 'draft':
    default:
      return 'primary';
  }
}

export function getPlanVersionStatusBadgeColor(
  val: PlanVersionStatus
): 'success' | 'indigo' | 'error' {
  if (val === 'approved') return 'success';
  if (val === 'rejected') return 'error';
  return 'indigo';
}

export function getPlanLineStatusLabel(val: PlanLineStatus): string {
  return planLineStatusOptions.find((o) => o.value === val)?.label ?? val;
}

export function getPlanLineStatusBadgeColor(
  val: PlanLineStatus
): 'success' | 'warning' | 'error' | 'blue' {
  switch (val) {
    case 'approved':
      return 'success';
    case 'on_hold':
      return 'blue';
    case 'rejected':
      return 'error';
    case 'pending':
    default:
      return 'warning';
  }
}

export function formatCurrencyETB(amount: number, currency = 'ETB'): string {
  return `${currency} ${amount.toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })}`;
}

export function generatePlanNumber(existingNumbers: string[]): string {
  const year = new Date().getFullYear();
  let seq = existingNumbers.length + 1;
  let candidate = `PP-${year}-0${seq}`;
  while (existingNumbers.includes(candidate)) {
    seq += 1;
    candidate = `PP-${year}-${String(seq).padStart(2, '0')}`;
  }
  return candidate;
}

// ─── Seed Data (Aligned with procurement-v4.sql Lines 652-720) ───────────────
export const procurementPlansStore = ref<ProcurementPlanRecord[]>([
  {
    id: 300,
    uuid: 'pp-0300-fb-2026',
    plan_number: 'PP-2026-FB',
    name: 'FY 2026 Food & Beverage Annual Procurement Plan',
    period_start: '2026-07-01',
    period_end: '2027-06-30',
    approved_at: '2026-06-20 14:30',
    notes:
      'Covers recurring culinary ingredients and kitchen capital equipment for Sheraton Ethiopia F&B operations. Revised in July to reflect seasonal produce market rates.',
    period_type_lookup_value_id: 'annual',
    procurement_unit_id: 2,
    procurement_unit_name: 'F&B Purchasing Desk',
    tenant_id: 1,
    entity_id: 2,
    entity_name: 'Sheraton Ethiopia',
    currency_id: 'ETB',
    fiscal_year_id: 'FY-2026',
    budget_id: 'BUD-2026-FB',
    budget_name: 'BUD-2026-FB — F&B Operating Budget',
    document_id: 'DOC-PP-300',
    plan_status_lookup_value_id: 'approved',
    user_id: 10,
    state: 'active'
  },
  {
    id: 301,
    uuid: 'pp-0301-cx-2026',
    plan_number: 'PP-2026-CX',
    name: 'FY 2026 IT & Capital Infrastructure Plan',
    period_start: '2026-07-01',
    period_end: '2027-06-30',
    approved_at: '2026-06-22 10:15',
    notes:
      'Annual capital expenditure plan for workstation refreshes, network upgrades, and enterprise software renewals.',
    period_type_lookup_value_id: 'annual',
    procurement_unit_id: 3,
    procurement_unit_name: 'IT & Capital Projects Desk',
    tenant_id: 1,
    entity_id: 2,
    entity_name: 'Sheraton Ethiopia',
    currency_id: 'ETB',
    fiscal_year_id: 'FY-2026',
    budget_id: 'BUD-2026-CAPEX',
    budget_name: 'BUD-2026-CAPEX — Capital Expenditure Budget',
    document_id: 'DOC-PP-301',
    plan_status_lookup_value_id: 'approved',
    user_id: 10,
    state: 'active'
  },
  {
    id: 302,
    uuid: 'pp-0302-q1-2027',
    plan_number: 'PP-2027-Q1',
    name: 'Q1 2027 General Operations & Consumables Plan',
    period_start: '2026-07-01',
    period_end: '2026-09-30',
    approved_at: null,
    notes:
      'Quarterly replenishment plan for stationery, housekeeping consumables, and general administrative supplies.',
    period_type_lookup_value_id: 'quarterly',
    procurement_unit_id: null,
    procurement_unit_name: 'Whole Entity (Shared)',
    tenant_id: 1,
    entity_id: 2,
    entity_name: 'Sheraton Ethiopia',
    currency_id: 'ETB',
    fiscal_year_id: 'FY-2026',
    budget_id: 'BUD-2026-OPS',
    budget_name: 'BUD-2026-OPS — General Operations Budget',
    document_id: 'DOC-PP-302',
    plan_status_lookup_value_id: 'draft',
    user_id: 10,
    state: 'active'
  },
  {
    id: 303,
    uuid: 'pp-0303-eng-2026',
    plan_number: 'PP-2026-ENG',
    name: 'FY 2026 Engineering & Facilities Maintenance Plan',
    period_start: '2026-07-01',
    period_end: '2027-06-30',
    approved_at: null,
    notes:
      'Annual preventative maintenance spares, HVAC consumables, and electrical switchgear replacement plan submitted for admin review and budget sign-off.',
    period_type_lookup_value_id: 'annual',
    procurement_unit_id: 1,
    procurement_unit_name: 'Central Procurement Hub',
    tenant_id: 1,
    entity_id: 2,
    entity_name: 'Sheraton Ethiopia',
    currency_id: 'ETB',
    fiscal_year_id: 'FY-2026',
    budget_id: 'BUD-2026-OPS',
    budget_name: 'BUD-2026-OPS — General Operations Budget',
    document_id: 'DOC-PP-303',
    plan_status_lookup_value_id: 'submitted',
    user_id: 10,
    state: 'active'
  }
]);

export const procurementPlanVersionsStore = ref<ProcurementPlanVersionRecord[]>([
  {
    id: 1,
    uuid: 'ppv-0001-300-v0',
    procurement_plan_id: 300,
    version_number: 0,
    reason: null,
    revised_at: '2026-06-20',
    superseded_at: '2026-07-25',
    document_id: 'DOC-PP-300-V0',
    revised_by: 'Abebe Bikila',
    plan_version_status_lookup_value_id: 'approved',
    user_id: 10,
    state: 'active'
  },
  {
    id: 2,
    uuid: 'ppv-0002-300-v1',
    procurement_plan_id: 300,
    version_number: 1,
    reason: 'July market price revision',
    revised_at: '2026-07-25',
    superseded_at: null,
    document_id: 'DOC-PP-300-V1',
    revised_by: 'Marta Tadesse',
    plan_version_status_lookup_value_id: 'approved',
    user_id: 10,
    state: 'active'
  },
  {
    id: 3,
    uuid: 'ppv-0003-301-v0',
    procurement_plan_id: 301,
    version_number: 0,
    reason: null,
    revised_at: '2026-06-22',
    superseded_at: null,
    document_id: 'DOC-PP-301-V0',
    revised_by: 'Dawit Mekonnen',
    plan_version_status_lookup_value_id: 'approved',
    user_id: 10,
    state: 'active'
  },
  {
    id: 4,
    uuid: 'ppv-0004-302-v0',
    procurement_plan_id: 302,
    version_number: 0,
    reason: null,
    revised_at: '2026-06-28',
    superseded_at: null,
    document_id: 'DOC-PP-302-V0',
    revised_by: 'Selamawit Girma',
    plan_version_status_lookup_value_id: 'submitted',
    user_id: 10,
    state: 'active'
  },
  {
    id: 5,
    uuid: 'ppv-0005-303-v0',
    procurement_plan_id: 303,
    version_number: 0,
    reason: 'Initial annual engineering & HVAC submission',
    revised_at: '2026-07-02',
    superseded_at: null,
    document_id: 'DOC-PP-303-V0',
    revised_by: 'Yonas Alemu',
    plan_version_status_lookup_value_id: 'submitted',
    user_id: 10,
    state: 'active'
  }
]);

export const procurementPlanLinesStore = ref<ProcurementPlanVersionLineRecord[]>([
  {
    id: 1,
    uuid: 'ppl-0001',
    procurement_plan_version_id: 2,
    line_number: 1,
    description: 'Fresh Roma Tomato — Grade A kitchen supply',
    planned_quantity: 12000,
    estimated_unit_price: 62.0,
    estimated_amount: 744000,
    requisitioned_quantity: 6200,
    ordered_quantity: 6000,
    received_quantity: 5840,
    actual_amount: 362080,
    required_from: '2026-07-01',
    required_to: '2027-06-30',
    is_recurring: true,
    decision_note: '',
    carried_from_line_id: null,
    procurement_category_id: 11,
    category_name: 'Fresh Produce',
    purchase_method_id: 5,
    purchase_method_name: 'Framework Agreement Call-Off',
    tenant_id: 1,
    entity_id: 2,
    organization_unit_id: '12',
    organization_unit_name: 'Food & Beverage (Dept 12)',
    product_id: 'PROD-101',
    product_name: 'Fresh Roma Tomato',
    measurement_id: 'KG',
    location_id: 'LOC-MAIN',
    location_name: 'Main Cold & Dry Store (Addis HQ)',
    budget_line_id: 'BL-5100',
    cost_center_dimension_id: 'CC-FB-01',
    plan_line_status_lookup_value_id: 'approved',
    user_id: 10,
    state: 'active'
  },
  {
    id: 2,
    uuid: 'ppl-0002',
    procurement_plan_version_id: 2,
    line_number: 2,
    description: 'Red Onion Grade A — bulk culinary stock',
    planned_quantity: 9000,
    estimated_unit_price: 38.0,
    estimated_amount: 342000,
    requisitioned_quantity: 4100,
    ordered_quantity: 4100,
    received_quantity: 4100,
    actual_amount: 155800,
    required_from: '2026-07-01',
    required_to: '2027-06-30',
    is_recurring: true,
    decision_note: '',
    carried_from_line_id: null,
    procurement_category_id: 11,
    category_name: 'Fresh Produce',
    purchase_method_id: 5,
    purchase_method_name: 'Framework Agreement Call-Off',
    tenant_id: 1,
    entity_id: 2,
    organization_unit_id: '12',
    organization_unit_name: 'Food & Beverage (Dept 12)',
    product_id: 'PROD-102',
    product_name: 'Red Onion Grade A',
    measurement_id: 'KG',
    location_id: 'LOC-MAIN',
    location_name: 'Main Cold & Dry Store (Addis HQ)',
    budget_line_id: 'BL-5100',
    cost_center_dimension_id: 'CC-FB-01',
    plan_line_status_lookup_value_id: 'approved',
    user_id: 10,
    state: 'active'
  },
  {
    id: 3,
    uuid: 'ppl-0003',
    procurement_plan_version_id: 2,
    line_number: 3,
    description: 'Commercial Planetary Mixer 40L for main pastry kitchen',
    planned_quantity: 2,
    estimated_unit_price: 85000.0,
    estimated_amount: 170000,
    requisitioned_quantity: 0,
    ordered_quantity: 0,
    received_quantity: 0,
    actual_amount: 0,
    required_from: '2026-09-01',
    required_to: '2026-10-31',
    is_recurring: false,
    decision_note: 'Held pending Q2 CAPEX budget release confirmation.',
    carried_from_line_id: null,
    procurement_category_id: 20,
    category_name: 'Capital Equipment',
    purchase_method_id: 2,
    purchase_method_name: 'Proforma / RFQ',
    tenant_id: 1,
    entity_id: 2,
    organization_unit_id: '12',
    organization_unit_name: 'Food & Beverage (Dept 12)',
    product_id: 'PROD-205',
    product_name: 'Commercial Planetary Mixer 40L',
    measurement_id: 'PCS',
    location_id: 'LOC-MAIN',
    location_name: 'Main Cold & Dry Store (Addis HQ)',
    budget_line_id: 'BL-6200',
    cost_center_dimension_id: 'CC-FB-01',
    plan_line_status_lookup_value_id: 'on_hold',
    user_id: 10,
    state: 'active'
  },
  {
    id: 4,
    uuid: 'ppl-0004',
    procurement_plan_version_id: 1,
    line_number: 1,
    description: 'Fresh Roma Tomato — initial baseline estimate',
    planned_quantity: 12000,
    estimated_unit_price: 55.0,
    estimated_amount: 660000,
    requisitioned_quantity: 2000,
    ordered_quantity: 2000,
    received_quantity: 1800,
    actual_amount: 99000,
    required_from: '2026-07-01',
    required_to: '2027-06-30',
    is_recurring: true,
    decision_note: '',
    carried_from_line_id: null,
    procurement_category_id: 11,
    category_name: 'Fresh Produce',
    purchase_method_id: 5,
    purchase_method_name: 'Framework Agreement Call-Off',
    tenant_id: 1,
    entity_id: 2,
    organization_unit_id: '12',
    organization_unit_name: 'Food & Beverage (Dept 12)',
    product_id: 'PROD-101',
    product_name: 'Fresh Roma Tomato',
    measurement_id: 'KG',
    location_id: 'LOC-MAIN',
    location_name: 'Main Cold & Dry Store (Addis HQ)',
    budget_line_id: 'BL-5100',
    cost_center_dimension_id: 'CC-FB-01',
    plan_line_status_lookup_value_id: 'approved',
    user_id: 10,
    state: 'active'
  },
  {
    id: 5,
    uuid: 'ppl-0005',
    procurement_plan_version_id: 3,
    line_number: 1,
    description: 'Enterprise Laptop Workstation — 16GB RAM / 512GB NVMe',
    planned_quantity: 25,
    estimated_unit_price: 92000.0,
    estimated_amount: 2300000,
    requisitioned_quantity: 15,
    ordered_quantity: 15,
    received_quantity: 10,
    actual_amount: 915000,
    required_from: '2026-07-15',
    required_to: '2026-12-31',
    is_recurring: false,
    decision_note: '',
    carried_from_line_id: null,
    procurement_category_id: 30,
    category_name: 'IT & Office Supplies',
    purchase_method_id: 3,
    purchase_method_name: 'Open Competitive Tender',
    tenant_id: 1,
    entity_id: 2,
    organization_unit_id: '18',
    organization_unit_name: 'Information Technology (Dept 18)',
    product_id: 'PROD-301',
    product_name: 'Enterprise Laptop Workstation',
    measurement_id: 'PCS',
    location_id: 'LOC-IT',
    location_name: 'IT Asset Vault (HQ)',
    budget_line_id: 'BL-6200',
    cost_center_dimension_id: 'CC-IT-01',
    plan_line_status_lookup_value_id: 'approved',
    user_id: 10,
    state: 'active'
  },
  {
    id: 6,
    uuid: 'ppl-0006',
    procurement_plan_version_id: 4,
    line_number: 1,
    description: 'A4 Printing Paper 80gsm Carton (5 reams/box)',
    planned_quantity: 300,
    estimated_unit_price: 2450.0,
    estimated_amount: 735000,
    requisitioned_quantity: 0,
    ordered_quantity: 0,
    received_quantity: 0,
    actual_amount: 0,
    required_from: '2026-07-01',
    required_to: '2026-09-30',
    is_recurring: true,
    decision_note: '',
    carried_from_line_id: null,
    procurement_category_id: 30,
    category_name: 'IT & Office Supplies',
    purchase_method_id: 2,
    purchase_method_name: 'Proforma / RFQ',
    tenant_id: 1,
    entity_id: 2,
    organization_unit_id: '22',
    organization_unit_name: 'Finance & Administration (Dept 22)',
    product_id: 'PROD-302',
    product_name: 'A4 Printing Paper 80gsm Carton',
    measurement_id: 'BOX',
    location_id: 'LOC-MAIN',
    location_name: 'Main Cold & Dry Store (Addis HQ)',
    budget_line_id: 'BL-5400',
    cost_center_dimension_id: 'CC-ADM-01',
    plan_line_status_lookup_value_id: 'pending',
    user_id: 10,
    state: 'active'
  },
  {
    id: 7,
    uuid: 'ppl-0007',
    procurement_plan_version_id: 5,
    line_number: 1,
    description: 'HVAC Chiller Compressor & Filter Kit — quarterly preventive service',
    planned_quantity: 12,
    estimated_unit_price: 42000.0,
    estimated_amount: 504000,
    requisitioned_quantity: 0,
    ordered_quantity: 0,
    received_quantity: 0,
    actual_amount: 0,
    required_from: '2026-07-15',
    required_to: '2027-06-30',
    is_recurring: true,
    decision_note: '',
    carried_from_line_id: null,
    procurement_category_id: 20,
    category_name: 'Capital Equipment',
    purchase_method_id: 2,
    purchase_method_name: 'Proforma / RFQ',
    tenant_id: 1,
    entity_id: 2,
    organization_unit_id: '14',
    organization_unit_name: 'Engineering & Maintenance (Dept 14)',
    product_id: null,
    product_name: 'HVAC Chiller Service Kit',
    measurement_id: 'SET',
    location_id: 'LOC-ENG',
    location_name: 'Engineering Workshop Store',
    budget_line_id: 'BL-6200',
    cost_center_dimension_id: 'CC-ADM-01',
    plan_line_status_lookup_value_id: 'pending',
    user_id: 10,
    state: 'active'
  },
  {
    id: 8,
    uuid: 'ppl-0008',
    procurement_plan_version_id: 5,
    line_number: 2,
    description: 'Industrial LED Floodlight & Circuit Breaker Spares',
    planned_quantity: 80,
    estimated_unit_price: 3850.0,
    estimated_amount: 308000,
    requisitioned_quantity: 0,
    ordered_quantity: 0,
    received_quantity: 0,
    actual_amount: 0,
    required_from: '2026-08-01',
    required_to: '2027-03-31',
    is_recurring: false,
    decision_note: '',
    carried_from_line_id: null,
    procurement_category_id: 20,
    category_name: 'Capital Equipment',
    purchase_method_id: 2,
    purchase_method_name: 'Proforma / RFQ',
    tenant_id: 1,
    entity_id: 2,
    organization_unit_id: '14',
    organization_unit_name: 'Engineering & Maintenance (Dept 14)',
    product_id: null,
    product_name: 'Electrical Switchgear Spares',
    measurement_id: 'PCS',
    location_id: 'LOC-ENG',
    location_name: 'Engineering Workshop Store',
    budget_line_id: 'BL-6200',
    cost_center_dimension_id: 'CC-ADM-01',
    plan_line_status_lookup_value_id: 'pending',
    user_id: 10,
    state: 'active'
  }
]);

// ─── Store Helpers ────────────────────────────────────────────────────────────
export function getCurrentPlanVersion(planId: number): ProcurementPlanVersionRecord | undefined {
  const versions = procurementPlanVersionsStore.value.filter((v) => v.procurement_plan_id === planId);
  return (
    versions.find((v) => v.superseded_at === null) ||
    versions.slice().sort((a, b) => b.version_number - a.version_number)[0]
  );
}

export function getPlanVersions(planId: number): ProcurementPlanVersionRecord[] {
  return procurementPlanVersionsStore.value
    .filter((v) => v.procurement_plan_id === planId)
    .slice()
    .sort((a, b) => b.version_number - a.version_number);
}

export function getVersionLines(versionId: number): ProcurementPlanVersionLineRecord[] {
  return procurementPlanLinesStore.value
    .filter((l) => l.procurement_plan_version_id === versionId)
    .slice()
    .sort((a, b) => a.line_number - b.line_number);
}

export function getPlanTotalEstimatedAmount(planId: number): number {
  const current = getCurrentPlanVersion(planId);
  if (!current) return 0;
  return getVersionLines(current.id).reduce((sum, l) => sum + (Number(l.estimated_amount) || 0), 0);
}

export function getPlanTotalActualAmount(planId: number): number {
  const current = getCurrentPlanVersion(planId);
  if (!current) return 0;
  return getVersionLines(current.id).reduce((sum, l) => sum + (Number(l.actual_amount) || 0), 0);
}
