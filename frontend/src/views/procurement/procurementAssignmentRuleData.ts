import { ref } from 'vue';

export type RowState = 'active' | 'inactive';
export type SourcingOrigin = 'local' | 'foreign';

export interface ProcurementAssignmentRuleRecord {
  id: number;
  uuid: string;
  procurement_unit_id: number; // Buying desk responsible for sourcing
  unit_name: string;
  default_buyer_employee_id: number | null; // null = Unit lead dispatches manually
  buyer_name?: string;
  buyer_avatar?: string;
  procurement_category_id: number | null; // null = Global / All categories
  category_name?: string;
  origin_lookup_value_id: SourcingOrigin | null; // null = Local and Foreign
  purchase_method_id: number | null; // null = All methods
  method_name?: string;
  minimum_amount: number | null; // null = No floor
  maximum_amount: number | null; // null = Unlimited / Open ceiling
  currency_code: string;
  priority: number; // 1 = highest, lowest wins on tie
  requesting_entity_id: number | null; // null = All branches/entities
  requesting_entity_name?: string;
  entity_id: number; // Owning entity (HQ = 2)
  effective_from: string; // YYYY-MM-DD
  effective_to: string | null; // YYYY-MM-DD | null
  notes?: string;
  state: RowState;
}

// ─── Procurement Units / Buying Desks (procurement-v4.sql Line 409) ───
export const unitOptions = [
  { value: '1', label: 'Central Procurement Unit (CPU - HQ)', code: 'PU-CENT' },
  { value: '2', label: 'Branch Buying Desk (Pharmacy & Clinic)', code: 'PU-BRANCH' },
  { value: '3', label: 'Le Spa Buying Desk (Specialized Hospitality)', code: 'PU-SPA' }
];

// ─── Dedicated Buyers / Employees ───
export const buyerOptions = [
  { value: '', label: 'Unassigned (Buying Desk Lead Dispatches)' },
  { value: '88', label: 'Abebe Bekele — Senior Tactical Buyer (F&B / Perishables)', avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&h=120&q=80' },
  { value: '90', label: 'Dr. Selamawit Tadesse — Unit Approver & Lead Buyer', avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=120&h=120&q=80' },
  { value: '92', label: 'Tigist Alemu — International & Capital Equipment Specialist', avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80' },
  { value: '95', label: 'Yonas Getachew — Operations & Consumables Buyer', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&h=120&q=80' }
];

// ─── Sourcing Origin Options (PROCUREMENT_ORIGIN) ───
export const originOptions = [
  { value: '', label: 'All Sourcing Origins (Local & Foreign)' },
  { value: 'local', label: 'Local Market (Domestic Suppliers)', desc: 'Suppliers registered in domestic tax jurisdiction' },
  { value: 'foreign', label: 'Foreign / Import (Cross-Border Sourcing)', desc: 'Imported equipment, LC financing, customs clearance' }
];

// ─── Spend Category Options ───
export const categoryScopeOptions = [
  { value: '', label: 'Global Scope (All Spend Categories)' },
  { value: '10', label: 'Food & Beverage' },
  { value: '11', label: 'Perishables' },
  { value: '20', label: 'Kitchen Equipment' },
  { value: '30', label: 'Cleaning Services' },
  { value: '50', label: 'Office Consumables' }
];

// ─── Purchase Method Options ───
export const methodScopeOptions = [
  { value: '', label: 'Global Scope (All Purchase Methods)' },
  { value: '1', label: 'Direct Purchase' },
  { value: '2', label: 'Proforma (RFQ)' },
  { value: '3', label: 'Open Tender' },
  { value: '4', label: 'Closed Tender (Invited)' },
  { value: '5', label: 'Framework Call-Off' },
  { value: '6', label: 'Emergency Purchase' }
];

// ─── Requesting Branch / Legal Entities ───
export const requestingEntityOptions = [
  { value: '', label: 'All Branches & Requesting Entities' },
  { value: '2', label: 'Haleta General Hospital (HQ Entity)' },
  { value: '3', label: 'Haleta Pharmaceuticals Branch' },
  { value: '6', label: 'Haleta Wellness Center' }
];

// ─── Precedence Priority Options ───
export const priorityOptions = [
  { value: '1', label: 'Priority 1 (Highest Precedence - Wins on Tie)' },
  { value: '2', label: 'Priority 2 (High Specificity Rule)' },
  { value: '3', label: 'Priority 3 (Standard Operational Assignment)' },
  { value: '4', label: 'Priority 4 (Fallback Desk Rule)' },
  { value: '5', label: 'Priority 5 (Lowest Precedence)' }
];

// ─── Initial Assignment Rules Seed (procurement-v4.sql Lines 510–515) ───
export const initialAssignmentRules: ProcurementAssignmentRuleRecord[] = [
  {
    id: 1,
    uuid: 'par-0001-perish-local',
    procurement_unit_id: 2,
    unit_name: 'Branch Buying Desk (Pharmacy & Clinic)',
    default_buyer_employee_id: 88,
    buyer_name: 'Abebe Bekele',
    buyer_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&h=120&q=80',
    procurement_category_id: 11, // Perishables
    category_name: 'Perishables',
    origin_lookup_value_id: 'local',
    purchase_method_id: null,
    minimum_amount: 0,
    maximum_amount: 50000,
    currency_code: 'ETB',
    priority: 1,
    requesting_entity_id: 3, // Haleta Pharmaceuticals Branch
    requesting_entity_name: 'Haleta Pharmaceuticals Branch',
    entity_id: 2,
    effective_from: '2026-07-01',
    effective_to: null,
    notes: 'Local perishable provisions up to 50,000 ETB for the pharmacy branch are assigned directly to Senior Tactical Buyer Abebe Bekele.',
    state: 'active'
  },
  {
    id: 2,
    uuid: 'par-0002-capex-foreign',
    procurement_unit_id: 1,
    unit_name: 'Central Procurement Unit (CPU - HQ)',
    default_buyer_employee_id: 92,
    buyer_name: 'Tigist Alemu',
    buyer_avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80',
    procurement_category_id: 20, // Kitchen Equipment
    category_name: 'Kitchen Equipment',
    origin_lookup_value_id: 'foreign',
    purchase_method_id: null,
    minimum_amount: 0,
    maximum_amount: null, // Unlimited
    currency_code: 'ETB',
    priority: 1,
    requesting_entity_id: null, // All entities
    requesting_entity_name: 'All Branches (Enterprise)',
    entity_id: 2,
    effective_from: '2026-07-01',
    effective_to: null,
    notes: 'All foreign cross-border equipment purchases route to Central Procurement Unit under Tigist Alemu for customs, LC financing, and import clearance.',
    state: 'active'
  },
  {
    id: 3,
    uuid: 'par-0003-cleaning-spa',
    procurement_unit_id: 3,
    unit_name: 'Le Spa Buying Desk (Specialized Hospitality)',
    default_buyer_employee_id: null, // Unit lead assigns
    procurement_category_id: 30, // Cleaning Services
    category_name: 'Cleaning Services',
    origin_lookup_value_id: 'local',
    purchase_method_id: null,
    minimum_amount: 0,
    maximum_amount: 20000,
    currency_code: 'ETB',
    priority: 2,
    requesting_entity_id: 6, // Haleta Wellness Center
    requesting_entity_name: 'Haleta Wellness Center',
    entity_id: 2,
    effective_from: '2026-07-01',
    effective_to: null,
    notes: 'Hospitality cleaning contracts for the Wellness Center are sourced by Le Spa desk; the desk lead delegates the contract officer upon arrival.',
    state: 'active'
  },
  {
    id: 4,
    uuid: 'par-0004-fb-central',
    procurement_unit_id: 1,
    unit_name: 'Central Procurement Unit (CPU - HQ)',
    default_buyer_employee_id: 92,
    buyer_name: 'Tigist Alemu',
    buyer_avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80',
    procurement_category_id: 10, // Food & Beverage
    category_name: 'Food & Beverage',
    origin_lookup_value_id: 'local',
    purchase_method_id: null,
    minimum_amount: 50000.01,
    maximum_amount: null, // Unlimited
    currency_code: 'ETB',
    priority: 1,
    requesting_entity_id: null,
    requesting_entity_name: 'All Branches (Enterprise)',
    entity_id: 2,
    effective_from: '2026-07-01',
    effective_to: null,
    notes: 'Major bulk food & beverage contracts exceeding 50,000 ETB escalate from branch desks to CPU HQ for volume price negotiations.',
    state: 'active'
  },
  {
    id: 5,
    uuid: 'par-0005-office-general',
    procurement_unit_id: 2,
    unit_name: 'Branch Buying Desk (Pharmacy & Clinic)',
    default_buyer_employee_id: 95,
    buyer_name: 'Yonas Getachew',
    buyer_avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&h=120&q=80',
    procurement_category_id: 50, // Office Consumables
    category_name: 'Office Consumables',
    origin_lookup_value_id: null, // Local and Foreign
    purchase_method_id: null,
    minimum_amount: 0,
    maximum_amount: 100000,
    currency_code: 'ETB',
    priority: 3,
    requesting_entity_id: null,
    requesting_entity_name: 'All Branches (Enterprise)',
    entity_id: 2,
    effective_from: '2026-07-01',
    effective_to: null,
    notes: 'Standard stationery and office consumables are fulfilled across all hospital departments by Yonas Getachew.',
    state: 'active'
  }
];

// ─── Reactive Application Store ───
export const assignmentRulesStore = ref<ProcurementAssignmentRuleRecord[]>([...initialAssignmentRules]);

// ─── Formatting & Helper Lookups ───
export function formatCurrency(amount: number | null | undefined): string {
  if (amount === null || amount === undefined) return 'Unlimited (Open)';
  return new Intl.NumberFormat('en-ET', {
    style: 'decimal',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount) + ' ETB';
}

export function getUnitName(id: number | string): string {
  return unitOptions.find((u) => u.value === String(id))?.label ?? `Buying Unit #${id}`;
}

export function getBuyerName(id: number | string | null): string {
  if (!id) return 'Unassigned (Lead Dispatches)';
  return buyerOptions.find((b) => b.value === String(id))?.label.split('—')[0].trim() ?? `Employee #${id}`;
}

export function getBuyerAvatar(id: number | string | null): string | undefined {
  if (!id) return undefined;
  return buyerOptions.find((b) => b.value === String(id))?.avatar;
}

export function getCategoryName(id: number | string | null): string {
  if (!id) return 'All Categories (Global)';
  return categoryScopeOptions.find((c) => c.value === String(id))?.label ?? `Category #${id}`;
}

export function getOriginLabel(origin: SourcingOrigin | null | string): string {
  if (!origin) return 'All Origins (Local & Foreign)';
  return origin === 'foreign' ? 'Foreign / Import' : 'Local Market';
}

export function getEntityName(id: number | string | null): string {
  if (!id) return 'All Branches (Enterprise)';
  return requestingEntityOptions.find((e) => e.value === String(id))?.label ?? `Entity #${id}`;
}

export function getMethodName(id: number | string | null): string {
  if (!id) return 'All Purchase Methods';
  return methodScopeOptions.find((m) => m.value === String(id))?.label ?? `Method #${id}`;
}
