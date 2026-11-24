import { ref } from 'vue';

export type RowState = 'active' | 'inactive';

export interface ProcurementApprovalRouteRecord {
  id: number;
  uuid: string;
  document_type_id: string; // PREQ, PO, PGRN, MTCH, RFP
  document_type_name: string;
  workflow_id: number;
  workflow_name: string;
  minimum_amount: number;
  maximum_amount: number | null; // null = Unlimited / Open Ceiling
  currency_code: string;
  priority: number; // 1 = highest priority, wins tie
  procurement_category_id: number | null; // null = All Categories (Global Scope)
  category_name?: string;
  purchase_method_id: number | null; // null = All Methods (Global Scope)
  method_name?: string;
  procurement_unit_id: number | null; // null = All Units (Global Scope)
  unit_name?: string;
  effective_from: string; // YYYY-MM-DD
  effective_to: string | null; // YYYY-MM-DD | null
  entity_id: number;
  notes?: string;
  state: RowState;
}

// ─── Supported Document Types (procurement-v4.sql Line 476) ───
export const documentTypeOptions = [
  { value: 'PREQ', label: 'Purchase Requisition (PREQ)', code: 'PREQ', desc: 'Internal purchase demand & budget authorization' },
  { value: 'PO', label: 'Purchase Order (PO)', code: 'PO', desc: 'Legally binding supplier commercial commitment' },
  { value: 'PGRN', label: 'Goods Receipt Note (PGRN)', code: 'PGRN', desc: 'Physical receiving inspection & inventory posting' },
  { value: 'MTCH', label: 'Invoice Match Variance (MTCH)', code: 'MTCH', desc: 'Two-way and three-way invoice matching tolerances' },
  { value: 'RFP', label: 'Tender & RFP Award (RFP)', code: 'RFP', desc: 'Competitive supplier award sanction' }
];

// ─── Document Type Workflows (XFK Workflow) ───
export const workflowOptions = [
  { value: '410', label: 'Standard Low-Value Requisition Approval (Unit Head)', docType: 'PREQ' },
  { value: '411', label: 'Dual Requisition Sign-Off (Unit Head + Finance)', docType: 'PREQ' },
  { value: '412', label: 'Executive Committee Capital Requisition Flow', docType: 'PREQ' },
  { value: '420', label: 'Standard Purchase Order Approval Flow', docType: 'PO' },
  { value: '423', label: 'Major Commercial Commitment Ladder (GM + Board)', docType: 'PO' },
  { value: '430', label: 'Technical Receiving & Goods Inspection Route', docType: 'PGRN' },
  { value: '440', label: 'Price & Quantity Variance Reconciliation Flow', docType: 'MTCH' },
  { value: '450', label: 'Tender Opening Board & Award Approval Flow', docType: 'RFP' }
];

// ─── Priority Options ───
export const priorityOptions = [
  { value: '1', label: 'Priority 1 (Highest - Wins on Tie)' },
  { value: '2', label: 'Priority 2 (High Priority Override)' },
  { value: '3', label: 'Priority 3 (Standard Operational Route)' },
  { value: '4', label: 'Priority 4 (Fallback Rule)' },
  { value: '5', label: 'Priority 5 (Lowest Precedence)' }
];

// ─── Category Scope Options ───
export const categoryScopeOptions = [
  { value: '10', label: 'Food & Beverage' },
  { value: '11', label: 'Perishables' },
  { value: '20', label: 'Kitchen Equipment' },
  { value: '30', label: 'Cleaning Services' },
  { value: '50', label: 'Office Consumables' }
];

// ─── Purchase Method Scope Options ───
export const methodScopeOptions = [
  { value: '1', label: 'Direct Purchase' },
  { value: '2', label: 'Proforma (RFQ)' },
  { value: '3', label: 'Open Tender' },
  { value: '4', label: 'Closed Tender (Invited)' },
  { value: '5', label: 'Framework Call-Off' },
  { value: '6', label: 'Emergency Purchase' }
];

// ─── Procurement Unit Scope Options ───
export const unitScopeOptions = [
  { value: '1', label: 'Central Procurement Unit' },
  { value: '2', label: 'Branch Buying Desk' },
  { value: '3', label: 'Le Spa Buying Desk' }
];

// ─── Legal Entity Options ───
export const entityOptions = [
  { value: '2', label: 'Haleta General Hospital (HQ Entity)' },
  { value: '3', label: 'Haleta Pharmaceuticals Branch' },
  { value: '6', label: 'Haleta Wellness Center' }
];

// ─── Initial Approval Routes Seed (procurement-v4.sql Lines 483–489) ───
export const initialApprovalRoutes: ProcurementApprovalRouteRecord[] = [
  {
    id: 1,
    uuid: 'par-0001-preq-low',
    document_type_id: 'PREQ',
    document_type_name: 'Purchase Requisition (PREQ)',
    workflow_id: 410,
    workflow_name: 'Standard Low-Value Requisition Approval (Unit Head)',
    minimum_amount: 0,
    maximum_amount: 50000,
    currency_code: 'ETB',
    priority: 1,
    procurement_category_id: null,
    purchase_method_id: null,
    procurement_unit_id: null,
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    notes: 'Standard low-value threshold routing requisitions up to 50,000 ETB directly to the originating department head.',
    state: 'active'
  },
  {
    id: 2,
    uuid: 'par-0002-preq-high',
    document_type_id: 'PREQ',
    document_type_name: 'Purchase Requisition (PREQ)',
    workflow_id: 411,
    workflow_name: 'Dual Requisition Sign-Off (Unit Head + Finance)',
    minimum_amount: 50000.01,
    maximum_amount: null, // Unlimited
    currency_code: 'ETB',
    priority: 1,
    procurement_category_id: null,
    purchase_method_id: null,
    procurement_unit_id: null,
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    notes: 'Requisitions exceeding 50,000 ETB require mandatory budget reservation and dual sign-off from Head of Finance.',
    state: 'active'
  },
  {
    id: 3,
    uuid: 'par-0003-po-capex',
    document_type_id: 'PO',
    document_type_name: 'Purchase Order (PO)',
    workflow_id: 423,
    workflow_name: 'Major Commercial Commitment Ladder (GM + Board)',
    minimum_amount: 200000.01,
    maximum_amount: null, // Unlimited
    currency_code: 'ETB',
    priority: 1,
    procurement_category_id: 20, // Kitchen Equipment
    category_name: 'Kitchen Equipment',
    purchase_method_id: null,
    procurement_unit_id: null,
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    notes: 'Capital expenditure orders for commercial kitchen equipment over 200,000 ETB mandate Board Executive sanction.',
    state: 'active'
  },
  {
    id: 4,
    uuid: 'par-0004-po-standard',
    document_type_id: 'PO',
    document_type_name: 'Purchase Order (PO)',
    workflow_id: 420,
    workflow_name: 'Standard Purchase Order Approval Flow',
    minimum_amount: 0,
    maximum_amount: 200000,
    currency_code: 'ETB',
    priority: 2,
    procurement_category_id: null,
    purchase_method_id: null,
    procurement_unit_id: null,
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    notes: 'Baseline purchase order approval routing directly to Procurement Unit Lead and Financial Controller.',
    state: 'active'
  },
  {
    id: 5,
    uuid: 'par-0005-pgrn-inspection',
    document_type_id: 'PGRN',
    document_type_name: 'Goods Receipt Note (PGRN)',
    workflow_id: 430,
    workflow_name: 'Technical Receiving & Goods Inspection Route',
    minimum_amount: 0,
    maximum_amount: null,
    currency_code: 'ETB',
    priority: 1,
    procurement_category_id: 11, // Perishables
    category_name: 'Perishables',
    purchase_method_id: null,
    procurement_unit_id: 2,
    unit_name: 'Branch Buying Desk',
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    notes: 'Enforces mandatory technical quality inspection before warehouse inventory posting for perishable provisions.',
    state: 'active'
  },
  {
    id: 6,
    uuid: 'par-0006-mtch-variance',
    document_type_id: 'MTCH',
    document_type_name: 'Invoice Match Variance (MTCH)',
    workflow_id: 440,
    workflow_name: 'Price & Quantity Variance Reconciliation Flow',
    minimum_amount: 500,
    maximum_amount: null,
    currency_code: 'ETB',
    priority: 1,
    procurement_category_id: null,
    purchase_method_id: null,
    procurement_unit_id: null,
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    notes: 'Dispatches invoice line items exceeding tolerance thresholds to Purchasing Lead for contract reconciliation.',
    state: 'active'
  }
];

// ─── Reactive Application Store ───
export const approvalRoutesStore = ref<ProcurementApprovalRouteRecord[]>([...initialApprovalRoutes]);

// ─── Formatting & Helper Functions ───
export function formatCurrency(amount: number | null | undefined): string {
  if (amount === null || amount === undefined) return 'Unlimited (Open)';
  return new Intl.NumberFormat('en-ET', {
    style: 'decimal',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount) + ' ETB';
}

export function getDocumentTypeLabel(code: string): string {
  return documentTypeOptions.find((d) => d.value === code)?.label ?? code;
}

export function getWorkflowLabel(id: number | string): string {
  return workflowOptions.find((w) => w.value === String(id))?.label ?? `Workflow #${id}`;
}

export function getCategoryLabel(id: number | null): string {
  if (!id) return 'All Categories (Global)';
  return categoryScopeOptions.find((c) => c.value === String(id))?.label ?? `Category #${id}`;
}

export function getMethodLabel(id: number | null): string {
  if (!id) return 'All Methods (Global)';
  return methodScopeOptions.find((m) => m.value === String(id))?.label ?? `Method #${id}`;
}

export function getUnitLabel(id: number | null): string {
  if (!id) return 'All Units (Global)';
  return unitScopeOptions.find((u) => u.value === String(id))?.label ?? `Unit #${id}`;
}
