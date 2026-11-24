import { ref } from 'vue';

export type ReceiptToleranceAction = 'block' | 'warn' | 'require_approval' | 'auto_close' | 'keep_open';

export interface ReceiptToleranceRuleRecord {
  id: number;
  uuid: string;
  over_receipt_percent: number;      // numeric(18,6) -- extra delivery allowed, %; 0 blocks any
  under_receipt_percent: number;     // numeric(18,6) -- shortfall, %, that still lets the line close
  early_delivery_days: number;       // smallint -- days early a delivery may still be accepted
  late_delivery_days: number;        // smallint -- grace days before a delivery counts as late
  priority: number;                  // smallint -- lowest wins on a tie (e.g. 1 = highest precedence)
  effective_from: string;            // date -- first day the rule applies (YYYY-MM-DD)
  effective_to: string | null;       // date nullable -- last day; NULL = still in force
  over_action_lookup_value_id: ReceiptToleranceAction;  // action when over the limit
  under_action_lookup_value_id: ReceiptToleranceAction; // action when under the limit
  procurement_category_id: number | null; // FK ProcurementCategory nullable; NULL = any
  supplier_id: number | null;        // XFK Supplier nullable; NULL = any
  product_id: number | null;         // XFK Product nullable; NULL = any
  tenant_id: number;
  entity_id: number;
  user_id: number;
  state: 'active' | 'inactive';

  // Joined display attributes for rich rendering
  category_name?: string;
  supplier_name?: string;
  product_name?: string;
  product_sku?: string;
  entity_name?: string;
}

export const actionOptions = [
  { value: 'block', label: 'Block Delivery', description: 'Strictly reject delivery attempt at receiving dock' },
  { value: 'require_approval', label: 'Require Approval', description: 'Quarantine items & route to procurement officer for waiver' },
  { value: 'warn', label: 'Accept with Warning', description: 'Permit receipt but log cautionary variance flag on GRN' },
  { value: 'auto_close', label: 'Auto Close Line', description: 'Close purchase line without expecting remaining shortfall' },
  { value: 'keep_open', label: 'Keep Line Open', description: 'Accept partial receipt and keep line open for remainder' }
];

export const categoryScopeOptions = [
  { value: '', label: 'All Categories (Global / Enterprise Default)' },
  { value: '11', label: 'Medical & Surgical Consumables (11)' },
  { value: '20', label: 'Information & Communication Tech (20)' },
  { value: '30', label: 'Laboratory Diagnostics & Reagents (30)' },
  { value: '40', label: 'Facilities, Power & Fleet Maintenance (40)' },
  { value: '50', label: 'Pharmaceuticals & Raw Compounds (50)' }
];

export const supplierScopeOptions = [
  { value: '', label: 'All Suppliers (Enterprise Default)' },
  { value: '502', label: 'Ethio-Pharm International Ltd. (#502)' },
  { value: '310', label: 'Global Diagnostics Corp (#310)' },
  { value: '405', label: 'Addis IT Solutions SC (#405)' },
  { value: '220', label: 'Nile Chemical Industries (#220)' },
  { value: '180', label: 'Bole Power & Electricals (#180)' }
];

export const productScopeOptions = [
  { value: '', label: 'All Products (Enterprise Default)' },
  { value: '1004', label: 'High-Precision MRI Contrast Reagents [SKU-MED-1004]' },
  { value: '8820', label: 'Sterile Nitrile Examination Gloves [SKU-GLV-8820]' },
  { value: '2401', label: 'Enterprise Rack Server 2U [SKU-SRV-2401]' },
  { value: '5102', label: 'Liquid Nitrogen Refrigerant 50L [SKU-GAS-5102]' }
];

export const entityOptions = [
  { value: '2', label: 'Haleta General Hospital (HQ Entity)' },
  { value: '3', label: 'Haleta Pharmaceuticals Branch' },
  { value: '6', label: 'Haleta Wellness Center' }
];

export function getEntityName(entityId: number | null): string {
  if (!entityId) return 'All Entities (Enterprise)';
  const match = entityOptions.find((e) => Number(e.value) === entityId);
  return match ? match.label : `Entity #${entityId}`;
}

export function getActionLabel(action: ReceiptToleranceAction): string {
  switch (action) {
    case 'block':
      return 'Block Delivery';
    case 'require_approval':
      return 'Require Approval';
    case 'warn':
      return 'Accept with Warning';
    case 'auto_close':
      return 'Auto Close Line';
    case 'keep_open':
      return 'Keep Line Open';
    default:
      return action;
  }
}

export function getScopeLevel(rule: ReceiptToleranceRuleRecord): {
  level: number;
  title: string;
  badgeLabel: string;
  badgeColor: 'indigo' | 'purple' | 'blue' | 'primary';
  summary: string;
} {
  if (rule.product_id) {
    return {
      level: 4,
      title: 'Product Specific',
      badgeLabel: 'Product',
      badgeColor: 'indigo',
      summary: rule.product_name || `Product #${rule.product_id}`
    };
  }
  if (rule.supplier_id) {
    return {
      level: 3,
      title: 'Supplier Specific',
      badgeLabel: 'Supplier',
      badgeColor: 'purple',
      summary: rule.supplier_name || `Supplier #${rule.supplier_id}`
    };
  }
  if (rule.procurement_category_id) {
    return {
      level: 2,
      title: 'Category Specific',
      badgeLabel: 'Category',
      badgeColor: 'blue',
      summary: rule.category_name || `Category #${rule.procurement_category_id}`
    };
  }
  return {
    level: 1,
    title: 'Entity Default',
    badgeLabel: 'Entity Default',
    badgeColor: 'primary',
    summary: rule.entity_name || 'Enterprise Baseline (Entity 2)'
  };
}

export const initialReceiptToleranceRules: ReceiptToleranceRuleRecord[] = [
  {
    id: 1,
    uuid: '8a1f4b23-7e21-4f12-a1b9-d3e74c810001',
    over_receipt_percent: 0,
    under_receipt_percent: 0,
    early_delivery_days: 0,
    late_delivery_days: 0,
    priority: 99,
    effective_from: '2026-01-01',
    effective_to: null,
    over_action_lookup_value_id: 'block',
    under_action_lookup_value_id: 'keep_open',
    procurement_category_id: null,
    supplier_id: null,
    product_id: null,
    tenant_id: 1,
    entity_id: 2,
    user_id: 10,
    state: 'active',
    entity_name: 'Entity 2 Default Policy'
  },
  {
    id: 2,
    uuid: '8a1f4b23-7e21-4f12-a1b9-d3e74c810002',
    over_receipt_percent: 5.0,
    under_receipt_percent: 10.0,
    early_delivery_days: 2,
    late_delivery_days: 1,
    priority: 20,
    effective_from: '2026-01-15',
    effective_to: null,
    over_action_lookup_value_id: 'require_approval',
    under_action_lookup_value_id: 'auto_close',
    procurement_category_id: 11,
    supplier_id: null,
    product_id: null,
    tenant_id: 1,
    entity_id: 2,
    user_id: 10,
    state: 'active',
    category_name: 'Medical & Surgical Consumables'
  },
  {
    id: 3,
    uuid: '8a1f4b23-7e21-4f12-a1b9-d3e74c810003',
    over_receipt_percent: 10.0,
    under_receipt_percent: 15.0,
    early_delivery_days: 1,
    late_delivery_days: 1,
    priority: 10,
    effective_from: '2026-02-01',
    effective_to: null,
    over_action_lookup_value_id: 'require_approval',
    under_action_lookup_value_id: 'auto_close',
    procurement_category_id: 11,
    supplier_id: 502,
    product_id: null,
    tenant_id: 1,
    entity_id: 2,
    user_id: 12,
    state: 'active',
    category_name: 'Medical & Surgical Consumables',
    supplier_name: 'Ethio-Pharm International Ltd.'
  },
  {
    id: 4,
    uuid: '8a1f4b23-7e21-4f12-a1b9-d3e74c810004',
    over_receipt_percent: 0,
    under_receipt_percent: 0,
    early_delivery_days: 0,
    late_delivery_days: 0,
    priority: 1,
    effective_from: '2026-01-01',
    effective_to: null,
    over_action_lookup_value_id: 'block',
    under_action_lookup_value_id: 'block',
    procurement_category_id: 30,
    supplier_id: 310,
    product_id: 1004,
    tenant_id: 1,
    entity_id: 2,
    user_id: 8,
    state: 'active',
    category_name: 'Laboratory Diagnostics & Reagents',
    supplier_name: 'Global Diagnostics Corp',
    product_name: 'High-Precision MRI Contrast Reagents',
    product_sku: 'SKU-MED-1004'
  },
  {
    id: 5,
    uuid: '8a1f4b23-7e21-4f12-a1b9-d3e74c810005',
    over_receipt_percent: 0,
    under_receipt_percent: 5.0,
    early_delivery_days: 0,
    late_delivery_days: 3,
    priority: 25,
    effective_from: '2026-03-01',
    effective_to: null,
    over_action_lookup_value_id: 'block',
    under_action_lookup_value_id: 'keep_open',
    procurement_category_id: 20,
    supplier_id: null,
    product_id: null,
    tenant_id: 1,
    entity_id: 2,
    user_id: 14,
    state: 'active',
    category_name: 'Information & Communication Tech'
  },
  {
    id: 6,
    uuid: '8a1f4b23-7e21-4f12-a1b9-d3e74c810006',
    over_receipt_percent: 2.0,
    under_receipt_percent: 5.0,
    early_delivery_days: 3,
    late_delivery_days: 2,
    priority: 12,
    effective_from: '2026-02-15',
    effective_to: '2026-12-31',
    over_action_lookup_value_id: 'warn',
    under_action_lookup_value_id: 'keep_open',
    procurement_category_id: 30,
    supplier_id: 310,
    product_id: null,
    tenant_id: 1,
    entity_id: 2,
    user_id: 9,
    state: 'active',
    category_name: 'Laboratory Diagnostics & Reagents',
    supplier_name: 'Global Diagnostics Corp'
  },
  {
    id: 7,
    uuid: '8a1f4b23-7e21-4f12-a1b9-d3e74c810007',
    over_receipt_percent: 15.0,
    under_receipt_percent: 20.0,
    early_delivery_days: 5,
    late_delivery_days: 2,
    priority: 5,
    effective_from: '2026-01-01',
    effective_to: null,
    over_action_lookup_value_id: 'warn',
    under_action_lookup_value_id: 'auto_close',
    procurement_category_id: 11,
    supplier_id: 502,
    product_id: 8820,
    tenant_id: 1,
    entity_id: 2,
    user_id: 12,
    state: 'active',
    category_name: 'Medical & Surgical Consumables',
    supplier_name: 'Ethio-Pharm International Ltd.',
    product_name: 'Sterile Nitrile Examination Gloves',
    product_sku: 'SKU-GLV-8820'
  },
  {
    id: 8,
    uuid: '8a1f4b23-7e21-4f12-a1b9-d3e74c810008',
    over_receipt_percent: 5.0,
    under_receipt_percent: 8.0,
    early_delivery_days: 1,
    late_delivery_days: 0,
    priority: 18,
    effective_from: '2025-01-01',
    effective_to: '2025-12-31',
    over_action_lookup_value_id: 'require_approval',
    under_action_lookup_value_id: 'keep_open',
    procurement_category_id: 40,
    supplier_id: 220,
    product_id: null,
    tenant_id: 1,
    entity_id: 2,
    user_id: 10,
    state: 'inactive',
    category_name: 'Facilities, Power & Fleet Maintenance',
    supplier_name: 'Nile Chemical Industries'
  }
];

export const receiptToleranceRulesStore = ref<ReceiptToleranceRuleRecord[]>([...initialReceiptToleranceRules]);

