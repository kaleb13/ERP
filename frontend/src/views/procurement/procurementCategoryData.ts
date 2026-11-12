import { ref } from 'vue';

export type SpendClass = 'goods' | 'service' | 'capital_asset' | 'project' | 'non_stock';
export type ReceiptMode = 'goods_receipt' | 'service_acceptance';
export type GovernanceStatus = 'pending' | 'acceptForAll' | 'acceptForThis' | 'reject';
export type RowState = 'active' | 'inactive';

export interface ProcurementCategoryRecord {
  id: number;
  uuid: string;
  code: string;
  name: string;
  description: string;
  requires_inspection: boolean;
  requires_contract: boolean;
  requires_budget_line: boolean;
  class_code: SpendClass;
  receipt_mode: ReceiptMode;
  parent_id: number | null;
  entity_id: number | null;
  item_category_id: number | null;
  status: GovernanceStatus;
  state: RowState;
}

export const spendClassOptions = [
  { value: 'goods', label: 'Goods' },
  { value: 'service', label: 'Service' },
  { value: 'capital_asset', label: 'Capital Asset' },
  { value: 'project', label: 'Project' },
  { value: 'non_stock', label: 'Non-Stock' }
];

export const receiptModeOptions = [
  { value: 'goods_receipt', label: 'Goods Receipt' },
  { value: 'service_acceptance', label: 'Service Acceptance' }
];

export const entityOptions = [
  { value: 'shared', label: 'Shared (All Tenants)' },
  { value: '2', label: 'Sheraton Ethiopia' },
  { value: '3', label: 'Sheraton Addis Branch' }
];

export const itemCategoryOptions = [
  { value: '101', label: 'Kitchen & Culinary Consumables' },
  { value: '102', label: 'Fresh Produce & Dairy' },
  { value: '103', label: 'Beverages & Spirits' },
  { value: '201', label: 'Commercial Kitchen Equipment' },
  { value: '301', label: 'Stationery & Office Supplies' }
];

export const governanceStatusOptions = [
  { value: 'acceptForAll', label: 'Approved for All Entities' },
  { value: 'acceptForThis', label: 'Approved for This Entity Only' },
  { value: 'pending', label: 'Pending Approval' },
  { value: 'reject', label: 'Rejected' }
];

export function getSpendClassLabel(val: SpendClass): string {
  return spendClassOptions.find((o) => o.value === val)?.label ?? val;
}

export function getReceiptModeLabel(val: ReceiptMode): string {
  return receiptModeOptions.find((o) => o.value === val)?.label ?? val;
}

export function getGovernanceStatusLabel(val: GovernanceStatus): string {
  return governanceStatusOptions.find((o) => o.value === val)?.label ?? val;
}

export function getEntityName(entityId: number | null): string {
  if (entityId === null) return 'Shared (All Tenants)';
  return entityOptions.find((o) => o.value === String(entityId))?.label ?? `Entity #${entityId}`;
}

export function getItemCategoryName(itemCatId: number | null): string {
  if (itemCatId === null) return '—';
  return itemCategoryOptions.find((o) => o.value === String(itemCatId))?.label ?? `Item Category #${itemCatId}`;
}

export function generateCategoryCode(name: string, existingCodes: string[]): string {
  const words = name
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9\s]/g, '')
    .split(/\s+/)
    .filter(Boolean);

  let base = 'CAT';
  if (words.length === 1) {
    base = words[0].slice(0, 8);
  } else if (words.length >= 2) {
    base = words.map((w) => w.slice(0, 4)).join('-').slice(0, 12);
  }

  let candidate = base;
  let seq = 1;
  while (existingCodes.includes(candidate)) {
    candidate = `${base}-${seq}`;
    seq += 1;
  }
  return candidate;
}

// Initial dataset aligned with procurement-v4.sql lines 355-363
export const procurementCategoriesStore = ref<ProcurementCategoryRecord[]>([
  {
    id: 10,
    uuid: 'pc-uuid-010',
    code: 'FB',
    name: 'Food & Beverage',
    description: 'Top-level spend category covering culinary ingredients, dry goods, and beverage stock.',
    requires_inspection: false,
    requires_contract: false,
    requires_budget_line: true,
    class_code: 'goods',
    receipt_mode: 'goods_receipt',
    parent_id: null,
    entity_id: 2,
    item_category_id: 101,
    status: 'acceptForAll',
    state: 'active'
  },
  {
    id: 11,
    uuid: 'pc-uuid-011',
    code: 'FB-PERISH',
    name: 'Perishables',
    description: 'Temperature-sensitive fresh produce, dairy, poultry, and seafood requiring gate quality inspection.',
    requires_inspection: true,
    requires_contract: false,
    requires_budget_line: true,
    class_code: 'goods',
    receipt_mode: 'goods_receipt',
    parent_id: 10,
    entity_id: 2,
    item_category_id: 102,
    status: 'acceptForAll',
    state: 'active'
  },
  {
    id: 12,
    uuid: 'pc-uuid-012',
    code: 'FB-BEV',
    name: 'Beverages & Spirits',
    description: 'Bottled beverages, specialty coffee, and bar inventory.',
    requires_inspection: false,
    requires_contract: false,
    requires_budget_line: true,
    class_code: 'goods',
    receipt_mode: 'goods_receipt',
    parent_id: 10,
    entity_id: 2,
    item_category_id: 103,
    status: 'acceptForAll',
    state: 'active'
  },
  {
    id: 20,
    uuid: 'pc-uuid-020',
    code: 'CAPEX-KIT',
    name: 'Kitchen Equipment',
    description: 'Fixed capital kitchen appliances, industrial ovens, and refrigeration units requiring formal contracts and QC sign-off.',
    requires_inspection: true,
    requires_contract: true,
    requires_budget_line: true,
    class_code: 'capital_asset',
    receipt_mode: 'goods_receipt',
    parent_id: null,
    entity_id: 2,
    item_category_id: 201,
    status: 'acceptForAll',
    state: 'active'
  },
  {
    id: 30,
    uuid: 'pc-uuid-030',
    code: 'SVC-CLEAN',
    name: 'Cleaning Services',
    description: 'Outsourced facility cleaning and janitorial service engagements confirmed via Service Acceptance.',
    requires_inspection: false,
    requires_contract: true,
    requires_budget_line: true,
    class_code: 'service',
    receipt_mode: 'service_acceptance',
    parent_id: null,
    entity_id: 2,
    item_category_id: null,
    status: 'acceptForAll',
    state: 'active'
  },
  {
    id: 31,
    uuid: 'pc-uuid-031',
    code: 'SVC-LAUND',
    name: 'Linen & Laundry Services',
    description: 'External commercial laundry and dry-cleaning vendor contracts.',
    requires_inspection: false,
    requires_contract: true,
    requires_budget_line: false,
    class_code: 'service',
    receipt_mode: 'service_acceptance',
    parent_id: 30,
    entity_id: 3,
    item_category_id: null,
    status: 'acceptForThis',
    state: 'active'
  },
  {
    id: 40,
    uuid: 'pc-uuid-040',
    code: 'PROJ-REN',
    name: 'Facility Renovation Projects',
    description: 'Turnkey civil works and interior refurbishment projects tracked by milestone completion.',
    requires_inspection: true,
    requires_contract: true,
    requires_budget_line: true,
    class_code: 'project',
    receipt_mode: 'service_acceptance',
    parent_id: null,
    entity_id: null,
    item_category_id: null,
    status: 'pending',
    state: 'active'
  },
  {
    id: 50,
    uuid: 'pc-uuid-050',
    code: 'OFFICE',
    name: 'Office Consumables',
    description: 'Non-stocked stationery, printer cartridges, and administrative supplies expensed directly upon receipt.',
    requires_inspection: false,
    requires_contract: false,
    requires_budget_line: false,
    class_code: 'non_stock',
    receipt_mode: 'goods_receipt',
    parent_id: null,
    entity_id: 2,
    item_category_id: 301,
    status: 'acceptForAll',
    state: 'active'
  }
]);

