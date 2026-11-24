import { ref } from 'vue';

export type RowState = 'active' | 'inactive';

export type DelegationType =
  | 'planned_leave'
  | 'sick_leave'
  | 'travel'
  | 'workload'
  | 'vacancy'
  | 'permanent_acting';

export type DelegationStatus =
  | 'draft'
  | 'pending_approval'
  | 'active'
  | 'expired'
  | 'revoked'
  | 'rejected';

export interface ApprovalDelegationRecord {
  id: number;
  uuid: string;
  delegator_user_id: number; // The approver who is away
  delegator_name: string;
  delegator_role: string;
  delegator_title?: string;
  delegator_avatar?: string;
  delegate_user_id: number; // The acting user who approves in their place
  delegate_name: string;
  delegate_role: string;
  delegate_title?: string;
  delegate_avatar?: string;
  document_type_id: string | null; // null = Global / All Document Types
  document_type_name: string;
  maximum_amount: number | null; // null = Unlimited / Delegator's Full Limit
  currency_code: string;
  valid_from: string; // YYYY-MM-DD
  valid_to: string; // YYYY-MM-DD
  type_lookup_value_id: DelegationType;
  type_label?: string;
  delegation_status_lookup_value_id: DelegationStatus;
  status_label?: string;
  document_id: number | null; // XFK Document (delegation letter or memo)
  document_number?: string;
  note?: string;
  tenant_id: number;
  entity_id: number;
  user_id: number;
  state: RowState;
}

// ─── Supported Delegation Types (procurement-v4.sql Line 150) ───
export const delegationTypeOptions = [
  { value: 'planned_leave', label: 'Planned Annual Leave', desc: 'Pre-scheduled annual or personal leave' },
  { value: 'travel', label: 'Business Travel / Mission', desc: 'Official travel or external site mission' },
  { value: 'sick_leave', label: 'Medical / Sick Leave', desc: 'Medical emergency or unplanned health absence' },
  { value: 'workload', label: 'Workload Surge Rebalancing', desc: 'Temporary capacity delegation during procurement surges' },
  { value: 'vacancy', label: 'Position Vacancy Cover', desc: 'Interim sign-off coverage during recruitment' },
  { value: 'permanent_acting', label: 'Permanent Acting Appointment', desc: 'Formally gazetted acting delegation' }
];

// ─── Delegation Status Options (procurement-v4.sql Line 151) ───
export const delegationStatusOptions = [
  { value: '', label: 'All Statuses' },
  { value: 'active', label: 'Active', desc: 'Currently operative and granting sign-off rights' },
  { value: 'pending_approval', label: 'Pending Approval', desc: 'Awaiting executive sign-off or HR verification' },
  { value: 'draft', label: 'Draft', desc: 'Work-in-progress delegation' },
  { value: 'expired', label: 'Expired', desc: 'Validity window has concluded' },
  { value: 'revoked', label: 'Revoked', desc: 'Manually terminated before expiration' }
];

// ─── Document Type Scopes (procurement-v4.sql Line 610) ───
export const delegationDocTypeOptions = [
  { value: '', label: 'All Document Types (Global Authority)', code: 'ALL', desc: 'Covers Requisitions, Orders, Goods Receipts, and Variances' },
  { value: 'PREQ', label: 'Purchase Requisition (PREQ)', code: 'PREQ', desc: 'Demand & internal budget approval' },
  { value: 'PO', label: 'Purchase Order (PO)', code: 'PO', desc: 'External supplier commercial orders' },
  { value: 'PGRN', label: 'Goods Receipt Note (PGRN)', code: 'PGRN', desc: 'Physical receiving & inspection acceptance' },
  { value: 'MTCH', label: 'Invoice Match Variance (MTCH)', code: 'MTCH', desc: 'Two-way and three-way invoice matching tolerances' },
  { value: 'RFP', label: 'Tender & RFP Award (RFP)', code: 'RFP', desc: 'Competitive supplier award sanction' }
];

// ─── Approvers & Users (XFK User / Employee) ───
export const delegatorUserOptions = [
  {
    value: '90',
    label: 'Dr. Selamawit Tadesse — Unit Approver & CMO',
    role: 'Unit Approver & Lead Buyer',
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    value: '91',
    label: 'Solomon Worku — Receiving & Warehouse Lead',
    role: 'Receiving Inspection Lead',
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    value: '88',
    label: 'Abebe Bekele — Senior Tactical Buyer',
    role: 'Procurement Specialist (F&B)',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    value: '95',
    label: 'Yonas Getachew — Operations & Consumables Lead',
    role: 'Operations Procurement Lead',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    value: '92',
    label: 'Tigist Alemu — Commercial & Capital Specialist',
    role: 'Capital Equipment Specialist',
    avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    value: '94',
    label: 'Meron Tesfaye — General Manager & VP',
    role: 'Executive Approver (GM)',
    avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=120&h=120&q=80'
  }
];

export const delegateUserOptions = [
  {
    value: '93',
    label: 'Dawit Haile — Deputy Procurement Officer',
    role: 'Deputy Procurement Officer',
    avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    value: '92',
    label: 'Tigist Alemu — Commercial & Capital Specialist',
    role: 'Capital Equipment Specialist',
    avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    value: '88',
    label: 'Abebe Bekele — Senior Tactical Buyer',
    role: 'Procurement Specialist (F&B)',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    value: '95',
    label: 'Yonas Getachew — Operations & Consumables Lead',
    role: 'Operations Procurement Lead',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    value: '96',
    label: 'Eden Assefa — Assistant Controller',
    role: 'Finance Approver (Deputy)',
    avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=120&h=120&q=80'
  }
];

// ─── Initial Seed Data (procurement-v4.sql Lines 618–623) ───
export const initialApprovalDelegations: ApprovalDelegationRecord[] = [
  {
    id: 1,
    uuid: 'del-0001-po-leave',
    delegator_user_id: 90,
    delegator_name: 'Dr. Selamawit Tadesse',
    delegator_role: 'Unit Approver & CMO',
    delegator_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=120&h=120&q=80',
    delegate_user_id: 93,
    delegate_name: 'Dawit Haile',
    delegate_role: 'Deputy Procurement Officer',
    delegate_avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=120&h=120&q=80',
    document_type_id: 'PO',
    document_type_name: 'Purchase Order (PO)',
    maximum_amount: 200000,
    currency_code: 'ETB',
    valid_from: '2026-09-01',
    valid_to: '2026-09-14',
    type_lookup_value_id: 'planned_leave',
    delegation_status_lookup_value_id: 'active',
    document_id: 1204,
    document_number: 'DEL-2026-001',
    note: 'Acting approval for all standard POs during annual leave. Excludes board-level awards.',
    tenant_id: 1,
    entity_id: 2,
    user_id: 10,
    state: 'active'
  },
  {
    id: 2,
    uuid: 'del-0002-all-travel',
    delegator_user_id: 90,
    delegator_name: 'Dr. Selamawit Tadesse',
    delegator_role: 'Unit Approver & CMO',
    delegator_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=120&h=120&q=80',
    delegate_user_id: 92,
    delegate_name: 'Tigist Alemu',
    delegate_role: 'Capital Equipment Specialist',
    delegate_avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80',
    document_type_id: null,
    document_type_name: 'All Documents (Global Scope)',
    maximum_amount: 50000,
    currency_code: 'ETB',
    valid_from: '2026-11-09',
    valid_to: '2026-11-13',
    type_lookup_value_id: 'travel',
    delegation_status_lookup_value_id: 'active',
    document_id: 1208,
    document_number: 'DEL-2026-002',
    note: 'International trade conference mission in Nairobi. Urgent POs and PREQs up to ETB 50,000.',
    tenant_id: 1,
    entity_id: 2,
    user_id: 10,
    state: 'active'
  },
  {
    id: 3,
    uuid: 'del-0003-pgrn-sick',
    delegator_user_id: 91,
    delegator_name: 'Solomon Worku',
    delegator_role: 'Receiving Inspection Lead',
    delegator_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&h=120&q=80',
    delegate_user_id: 88,
    delegate_name: 'Abebe Bekele',
    delegate_role: 'Senior Tactical Buyer',
    delegate_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&h=120&q=80',
    document_type_id: 'PGRN',
    document_type_name: 'Goods Receipt Note (PGRN)',
    maximum_amount: null, // Full authority
    currency_code: 'ETB',
    valid_from: '2026-10-12',
    valid_to: '2026-10-12',
    type_lookup_value_id: 'sick_leave',
    delegation_status_lookup_value_id: 'expired',
    document_id: null,
    note: 'Single-day medical absence. Physical warehouse receiving sign-off authority.',
    tenant_id: 1,
    entity_id: 2,
    user_id: 10,
    state: 'active'
  },
  {
    id: 4,
    uuid: 'del-0004-preq-leave',
    delegator_user_id: 95,
    delegator_name: 'Yonas Getachew',
    delegator_role: 'Operations Procurement Lead',
    delegator_avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&h=120&q=80',
    delegate_user_id: 93,
    delegate_name: 'Dawit Haile',
    delegate_role: 'Deputy Procurement Officer',
    delegate_avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=120&h=120&q=80',
    document_type_id: 'PREQ',
    document_type_name: 'Purchase Requisition (PREQ)',
    maximum_amount: 100000,
    currency_code: 'ETB',
    valid_from: '2026-12-01',
    valid_to: '2026-12-15',
    type_lookup_value_id: 'planned_leave',
    delegation_status_lookup_value_id: 'pending_approval',
    document_id: 1215,
    document_number: 'DEL-2026-004',
    note: 'Year-end operations leave. Requisition sign-offs up to ETB 100,000.',
    tenant_id: 1,
    entity_id: 2,
    user_id: 10,
    state: 'active'
  },
  {
    id: 5,
    uuid: 'del-0005-po-workload',
    delegator_user_id: 88,
    delegator_name: 'Abebe Bekele',
    delegator_role: 'Senior Tactical Buyer',
    delegator_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&h=120&q=80',
    delegate_user_id: 95,
    delegate_name: 'Yonas Getachew',
    delegate_role: 'Operations Procurement Lead',
    delegate_avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&h=120&q=80',
    document_type_id: 'PO',
    document_type_name: 'Purchase Order (PO)',
    maximum_amount: 150000,
    currency_code: 'ETB',
    valid_from: '2026-08-01',
    valid_to: '2026-08-10',
    type_lookup_value_id: 'workload',
    delegation_status_lookup_value_id: 'revoked',
    document_id: null,
    note: 'Hospitality renovation procurement surge. Revoked after project completion.',
    tenant_id: 1,
    entity_id: 2,
    user_id: 10,
    state: 'inactive'
  },
  {
    id: 6,
    uuid: 'del-0006-all-vacancy',
    delegator_user_id: 94,
    delegator_name: 'Meron Tesfaye',
    delegator_role: 'Executive Approver (GM)',
    delegator_avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=120&h=120&q=80',
    delegate_user_id: 92,
    delegate_name: 'Tigist Alemu',
    delegate_role: 'Capital Equipment Specialist',
    delegate_avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80',
    document_type_id: null,
    document_type_name: 'All Documents (Global Scope)',
    maximum_amount: 500000,
    currency_code: 'ETB',
    valid_from: '2026-07-01',
    valid_to: '2026-07-31',
    type_lookup_value_id: 'vacancy',
    delegation_status_lookup_value_id: 'expired',
    document_id: 1198,
    document_number: 'DEL-2026-000',
    note: 'Interim sign-off coverage during senior management transition.',
    tenant_id: 1,
    entity_id: 2,
    user_id: 10,
    state: 'active'
  }
];

// ─── Shared Reactive Store ───
export const approvalDelegationsStore = ref<ApprovalDelegationRecord[]>([...initialApprovalDelegations]);

// ─── Helpers ───
export const formatDelegationCurrency = (amount: number | null): string => {
  if (amount === null || amount === undefined) {
    return 'Full Authority (No Ceiling)';
  }
  return new Intl.NumberFormat('en-ET', {
    style: 'currency',
    currency: 'ETB',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount);
};

export const getDelegationTypeLabel = (type: DelegationType): string => {
  const match = delegationTypeOptions.find((t) => t.value === type);
  return match ? match.label : type;
};

export const getDelegationStatusLabel = (status: DelegationStatus): string => {
  const match = delegationStatusOptions.find((s) => s.value === status);
  return match ? match.label : status;
};

export const getDelegationTypeBadgeColor = (type: DelegationType): 'blue' | 'purple' | 'warning' | 'indigo' | 'gray' => {
  switch (type) {
    case 'planned_leave':
      return 'blue';
    case 'travel':
      return 'purple';
    case 'sick_leave':
      return 'warning';
    case 'workload':
      return 'indigo';
    case 'vacancy':
    case 'permanent_acting':
      return 'indigo';
    default:
      return 'gray';
  }
};

export const getDelegationStatusBadgeColor = (status: DelegationStatus): 'success' | 'warning' | 'gray' | 'error' | 'indigo' => {
  switch (status) {
    case 'active':
      return 'success';
    case 'pending_approval':
      return 'warning';
    case 'draft':
      return 'indigo';
    case 'expired':
      return 'gray';
    case 'revoked':
    case 'rejected':
      return 'error';
    default:
      return 'gray';
  }
};

// Initialize labels on initialApprovalDelegations
initialApprovalDelegations.forEach((item) => {
  item.type_label = getDelegationTypeLabel(item.type_lookup_value_id);
  item.status_label = getDelegationStatusLabel(item.delegation_status_lookup_value_id);
  item.delegator_title = item.delegator_role;
  item.delegate_title = item.delegate_role;
});
