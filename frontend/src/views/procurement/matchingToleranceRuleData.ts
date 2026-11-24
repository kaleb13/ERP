import { ref } from 'vue';

export type MatchType = 'two_way' | 'three_way' | 'four_way';
export type MatchExceptionAction = 'block' | 'require_approval' | 'auto_accept';

export interface MatchingToleranceRuleRecord {
  id: number;
  uuid: string;
  price_variance_percent: number;      // numeric(18,6) -- allowed unit-price difference, %
  price_variance_amount: number;       // numeric(18,4) -- absolute price cap; lower of the two governs
  quantity_variance_percent: number;   // numeric(18,6) -- allowed quantity difference, %
  total_variance_amount: number;       // numeric(18,4) -- allowed difference on the whole invoice
  auto_match_enabled: boolean;         // bool -- match without a person when every variance is in the band
  priority: number;                    // smallint -- lowest wins on a tie
  effective_from: string;              // date -- first day the rule applies (YYYY-MM-DD)
  effective_to: string | null;         // date nullable -- last day; NULL = still in force
  match_type_lookup_value_id: MatchType;               // FK LookupValue (MATCH_TYPE)
  exception_action_lookup_value_id: MatchExceptionAction; // FK LookupValue (MATCH_EXCEPTION_ACTION)
  procurement_category_id: number | null; // FK ProcurementCategory nullable; NULL = any
  tenant_id: number;
  entity_id: number;
  supplier_id: number | null;          // XFK Supplier nullable; NULL = any
  user_id: number;
  state: 'active' | 'inactive';

  // Joined display attributes for UI rendering
  category_name?: string;
  supplier_name?: string;
  entity_name?: string;
}

export const matchTypeOptions = [
  { value: 'two_way', label: '2-Way Match (PO vs. Invoice)' },
  { value: 'three_way', label: '3-Way Match (PO vs. GRN vs. Invoice)' },
  { value: 'four_way', label: '4-Way Match (PO vs. GRN vs. QC vs. Invoice)' }
];

export const exceptionActionOptions = [
  { value: 'block', label: 'Block Invoice Posting' },
  { value: 'require_approval', label: 'Require Exception Approval' },
  { value: 'auto_accept', label: 'Auto-Accept Variance' }
];

export const matchingCategoryOptions = [
  { value: '', label: 'All Categories (Global)' },
  { value: '11', label: 'Medical & Surgical Consumables (11)' },
  { value: '20', label: 'Information & Communication Tech (20)' },
  { value: '30', label: 'Laboratory Diagnostics & Reagents (30)' },
  { value: '40', label: 'Facilities, Power & Fleet Maintenance (40)' },
  { value: '50', label: 'Pharmaceuticals & Raw Compounds (50)' }
];

export const matchingSupplierOptions = [
  { value: '', label: 'All Suppliers (Global)' },
  { value: '502', label: 'Ethio-Pharm International Ltd. (#502)' },
  { value: '310', label: 'Global Diagnostics Corp (#310)' },
  { value: '405', label: 'Addis IT Solutions SC (#405)' },
  { value: '220', label: 'Nile Chemical Industries (#220)' }
];

export const matchingEntityOptions = [
  { value: '2', label: 'Haleta General Hospital (HQ Entity)' },
  { value: '3', label: 'Haleta Pharmaceuticals Branch' },
  { value: '6', label: 'Haleta Wellness Center' }
];

export function getMatchTypeLabel(type: MatchType): string {
  switch (type) {
    case 'two_way':
      return '2-Way Match';
    case 'three_way':
      return '3-Way Match';
    case 'four_way':
      return '4-Way Match';
    default:
      return type;
  }
}

export function getMatchTypeBadgeColor(type: MatchType): 'blue' | 'indigo' | 'purple' {
  switch (type) {
    case 'two_way':
      return 'blue';
    case 'three_way':
      return 'indigo';
    case 'four_way':
      return 'purple';
    default:
      return 'blue';
  }
}

export function getExceptionActionLabel(action: MatchExceptionAction): string {
  switch (action) {
    case 'block':
      return 'Block Invoice';
    case 'require_approval':
      return 'Require Approval';
    case 'auto_accept':
      return 'Auto-Accept';
    default:
      return action;
  }
}

export function getMatchingEntityName(entityId: number | null): string {
  if (!entityId) return 'Haleta General Hospital (HQ Entity)';
  const match = matchingEntityOptions.find((e) => Number(e.value) === entityId);
  return match ? match.label : `Entity #${entityId}`;
}

export function getMatchingScopeSummary(rule: MatchingToleranceRuleRecord): {
  level: number;
  title: string;
  summary: string;
} {
  if (rule.supplier_id) {
    return {
      level: 3,
      title: 'Supplier Specific',
      summary: rule.supplier_name || `Supplier #${rule.supplier_id}`
    };
  }
  if (rule.procurement_category_id) {
    return {
      level: 2,
      title: 'Category Specific',
      summary: rule.category_name || `Category #${rule.procurement_category_id}`
    };
  }
  return {
    level: 1,
    title: 'Entity Default',
    summary: rule.entity_name || getMatchingEntityName(rule.entity_id)
  };
}

export function formatEtb(amount: number): string {
  return `ETB ${amount.toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })}`;
}

// Authoritative Seed Data aligned with procurement-v4.sql (Lines 591–597)
export const initialMatchingToleranceRules: MatchingToleranceRuleRecord[] = [
  {
    id: 1,
    uuid: '9b2e5c34-8f32-4a23-b2c8-e4f85d920001',
    price_variance_percent: 2.0,
    price_variance_amount: 500.0,
    quantity_variance_percent: 0.0,
    total_variance_amount: 2000.0,
    auto_match_enabled: true,
    priority: 30,
    effective_from: '2026-01-01',
    effective_to: null,
    match_type_lookup_value_id: 'three_way',
    exception_action_lookup_value_id: 'require_approval',
    procurement_category_id: null,
    tenant_id: 1,
    entity_id: 2,
    supplier_id: null,
    user_id: 10,
    state: 'active',
    entity_name: 'Haleta General Hospital (HQ Entity)'
  },
  {
    id: 2,
    uuid: '9b2e5c34-8f32-4a23-b2c8-e4f85d920002',
    price_variance_percent: 0.0,
    price_variance_amount: 0.0,
    quantity_variance_percent: 0.0,
    total_variance_amount: 0.0,
    auto_match_enabled: false,
    priority: 15,
    effective_from: '2026-01-15',
    effective_to: null,
    match_type_lookup_value_id: 'two_way',
    exception_action_lookup_value_id: 'block',
    procurement_category_id: 30,
    tenant_id: 1,
    entity_id: 2,
    supplier_id: null,
    user_id: 10,
    state: 'active',
    category_name: 'Laboratory Diagnostics & Reagents'
  },
  {
    id: 3,
    uuid: '9b2e5c34-8f32-4a23-b2c8-e4f85d920003',
    price_variance_percent: 5.0,
    price_variance_amount: 1000.0,
    quantity_variance_percent: 2.0,
    total_variance_amount: 5000.0,
    auto_match_enabled: true,
    priority: 10,
    effective_from: '2026-02-01',
    effective_to: null,
    match_type_lookup_value_id: 'three_way',
    exception_action_lookup_value_id: 'require_approval',
    procurement_category_id: null,
    tenant_id: 1,
    entity_id: 2,
    supplier_id: 502,
    user_id: 12,
    state: 'active',
    supplier_name: 'Ethio-Pharm International Ltd.'
  },
  {
    id: 4,
    uuid: '9b2e5c34-8f32-4a23-b2c8-e4f85d920004',
    price_variance_percent: 0.5,
    price_variance_amount: 250.0,
    quantity_variance_percent: 0.0,
    total_variance_amount: 500.0,
    auto_match_enabled: false,
    priority: 5,
    effective_from: '2026-01-01',
    effective_to: null,
    match_type_lookup_value_id: 'four_way',
    exception_action_lookup_value_id: 'block',
    procurement_category_id: 50,
    tenant_id: 1,
    entity_id: 3,
    supplier_id: null,
    user_id: 8,
    state: 'active',
    category_name: 'Pharmaceuticals & Raw Compounds',
    entity_name: 'Haleta Pharmaceuticals Branch'
  },
  {
    id: 5,
    uuid: '9b2e5c34-8f32-4a23-b2c8-e4f85d920005',
    price_variance_percent: 1.5,
    price_variance_amount: 750.0,
    quantity_variance_percent: 1.0,
    total_variance_amount: 1500.0,
    auto_match_enabled: true,
    priority: 20,
    effective_from: '2025-01-01',
    effective_to: '2025-12-31',
    match_type_lookup_value_id: 'three_way',
    exception_action_lookup_value_id: 'auto_accept',
    procurement_category_id: 20,
    tenant_id: 1,
    entity_id: 2,
    supplier_id: 405,
    user_id: 14,
    state: 'inactive',
    category_name: 'Information & Communication Tech',
    supplier_name: 'Addis IT Solutions SC'
  }
];

export const matchingToleranceRulesStore = ref<MatchingToleranceRuleRecord[]>([
  ...initialMatchingToleranceRules
]);

