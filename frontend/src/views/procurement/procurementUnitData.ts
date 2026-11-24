import { ref } from 'vue';

export type ProcurementUnitMode = 'centralised' | 'decentralised' | 'hybrid';
export type ProcurementUnitRole = 'buyer' | 'requester' | 'unit_approver' | 'receiver' | 'viewer';
export type GovernanceStatus = 'pending' | 'acceptForAll' | 'acceptForThis' | 'reject';
export type RowState = 'active' | 'inactive';

export interface ProcurementUnitMemberRecord {
  id: number;
  uuid: string;
  procurement_unit_id: number;
  member_employee_id: number;
  employee_name: string;
  employee_code: string;
  avatar?: string;
  role: ProcurementUnitRole;
  organization_unit_id: number | null;
  department_name: string;
  valid_from: string; // YYYY-MM-DD
  valid_to: string | null; // YYYY-MM-DD | null
  state: RowState;
}

export interface ProcurementUnitRecord {
  id: number;
  uuid: string;
  code: string;
  name: string;
  mode: ProcurementUnitMode;
  authority_ceiling: number | null;
  currency_code: string;
  buys_for_descendants: boolean;
  entity_id: number;
  default_location_id: number | null;
  cost_center_dimension_id: string | null;
  status: GovernanceStatus;
  state: RowState;
}

export const unitModeOptions = [
  { value: 'centralised', label: 'Centralised (Central Buying Desk)' },
  { value: 'hybrid', label: 'Hybrid (Branch with Ceiling)' },
  { value: 'decentralised', label: 'Decentralised (Self-Sourcing Unit)' }
];

export const unitRoleOptions = [
  { value: 'buyer', label: 'Buyer (Places Orders)' },
  { value: 'unit_approver', label: 'Unit Approver (Approves Orders)' },
  { value: 'requester', label: 'Requester (Raises Demands)' },
  { value: 'receiver', label: 'Receiver (Confirms Receipts)' },
  { value: 'viewer', label: 'Viewer (Read-Only)' }
];

export const employeeAvatarMap: Record<number, string> = {
  88: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
  90: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
  91: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
  92: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
  95: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
  98: 'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=150&auto=format&fit=crop&q=80',
  99: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80',
  100: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
  101: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80',
  102: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
  103: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
  104: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&auto=format&fit=crop&q=80'
};

export function getEmployeeAvatar(employeeId: number): string | undefined {
  return employeeAvatarMap[employeeId];
}

export const employeeOptions = [
  { value: '88', label: 'Hanna Girma (EMP-0088) • Buyer' },
  { value: '90', label: 'Yonas Alemu (EMP-0090) • Unit Approver' },
  { value: '91', label: 'Meseret Tadesse (EMP-0091) • Storekeeper / Receiver' },
  { value: '92', label: 'Abebe Kassa (EMP-0092) • Import Buyer' },
  { value: '95', label: 'Kidist Bekele (EMP-0095) • Department Requester' },
  { value: '98', label: 'Sara Tesfaye (EMP-0098) • Spa Specialist' },
  { value: '99', label: 'Dawit Mekonnen (EMP-0099) • Senior Buyer' },
  { value: '100', label: 'Tigist Haile (EMP-0100) • F&B Requester' },
  { value: '101', label: 'Bereket Tadesse (EMP-0101) • Receiving Officer' },
  { value: '102', label: 'Selamawit Teshome (EMP-0102) • Procurement Analyst' },
  { value: '103', label: 'Samuel Kebede (EMP-0103) • Branch Approver' },
  { value: '104', label: 'Rahel Demissie (EMP-0104) • Audit Viewer' }
];

export const departmentOptions = [
  { value: '', label: 'All Departments (No Department Filter)' },
  { value: '12', label: 'Food & Beverage (OU-12)' },
  { value: '14', label: 'Housekeeping (OU-14)' },
  { value: '16', label: 'Wellness & Spa (OU-16)' },
  { value: '20', label: 'Corporate HQ Operations (OU-20)' },
  { value: '25', label: 'Finance & Accounts (OU-25)' }
];

export const locationOptions = [
  { value: '', label: 'None (Decided per Requisition)' },
  { value: '40', label: 'Main Store 40 (Central Warehouse)' },
  { value: '41', label: 'F&B Store 41 (Branch Dry Goods)' },
  { value: '42', label: 'Cold Room 42 (Perishables Chiller)' },
  { value: '43', label: 'Spa Consumables Store 43' }
];

export const currencyOptions = [
  { value: 'ETB', label: 'ETB — Ethiopian Birr' },
  { value: 'USD', label: 'USD — US Dollar' },
  { value: 'EUR', label: 'EUR — Euro' }
];

export const costCenterOptions = [
  { value: '', label: 'None (Assigned per PO Line)' },
  { value: 'CC-CORP', label: 'CC-CORP — Corporate Overhead' },
  { value: 'CC-OPS', label: 'CC-OPS — Branch Hotel Operations' },
  { value: 'CC-SPA', label: 'CC-SPA — Wellness & Recreation' },
  { value: 'CC-FNB', label: 'CC-FNB — Food & Beverage Catering' }
];

export const entityOptions = [
  { value: '2', label: 'Sheraton Ethiopia (Entity 2)' },
  { value: '3', label: 'Sheraton Addis Branch (Entity 3)' },
  { value: '6', label: 'Le Spa (Entity 6)' }
];

export const governanceStatusOptions = [
  { value: 'acceptForAll', label: 'Approved for All Entities' },
  { value: 'acceptForThis', label: 'Approved for This Entity Only' },
  { value: 'pending', label: 'Pending Approval' },
  { value: 'reject', label: 'Rejected' }
];

export function getUnitModeLabel(val: ProcurementUnitMode): string {
  return unitModeOptions.find((o) => o.value === val)?.label.split(' ')[0] ?? val;
}

export function getUnitRoleLabel(val: ProcurementUnitRole): string {
  return unitRoleOptions.find((o) => o.value === val)?.label.split(' ')[0] ?? val;
}

export function getGovernanceStatusLabel(status: GovernanceStatus): string {
  return governanceStatusOptions.find((option) => option.value === status)?.label ?? status;
}

export function getEntityName(entityId: number): string {
  return entityOptions.find((o) => o.value === String(entityId))?.label ?? `Entity #${entityId}`;
}

export function getLocationName(locId: number | null): string {
  if (!locId) return '—';
  return locationOptions.find((o) => o.value === String(locId))?.label ?? `Location #${locId}`;
}

export function generateUnitCode(name: string, existingCodes: string[]): string {
  const words = name
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9\s]/g, '')
    .split(/\s+/)
    .filter(Boolean);

  let base = 'PU-UNIT';
  if (words.length === 1) {
    base = `PU-${words[0].slice(0, 5)}`;
  } else if (words.length >= 2) {
    base = `PU-${words.slice(0, 3).map((w) => w.slice(0, 4)).join('-')}`.slice(0, 14);
  }

  let candidate = base;
  let seq = 1;
  while (existingCodes.includes(candidate)) {
    candidate = `${base}-${seq}`;
    seq += 1;
  }
  return candidate;
}

// ─── Initial Procurement Units (Aligned with procurement-v4.sql lines 408-414) ───
export const procurementUnitsStore = ref<ProcurementUnitRecord[]>([
  {
    id: 1,
    uuid: 'pu-uuid-001',
    code: 'PU-CENT',
    name: 'Central Procurement Unit',
    mode: 'centralised',
    authority_ceiling: null,
    currency_code: 'ETB',
    buys_for_descendants: true,
    entity_id: 2,
    default_location_id: 40,
    cost_center_dimension_id: 'CC-CORP',
    status: 'acceptForAll',
    state: 'active'
  },
  {
    id: 2,
    uuid: 'pu-uuid-002',
    code: 'PU-BRANCH',
    name: 'Branch Buying Desk',
    mode: 'hybrid',
    authority_ceiling: 50000,
    currency_code: 'ETB',
    buys_for_descendants: false,
    entity_id: 3,
    default_location_id: 41,
    cost_center_dimension_id: 'CC-OPS',
    status: 'acceptForAll',
    state: 'active'
  },
  {
    id: 3,
    uuid: 'pu-uuid-003',
    code: 'PU-SPA',
    name: 'Le Spa Buying Desk',
    mode: 'decentralised',
    authority_ceiling: 20000,
    currency_code: 'ETB',
    buys_for_descendants: false,
    entity_id: 6,
    default_location_id: 42,
    cost_center_dimension_id: 'CC-SPA',
    status: 'acceptForThis',
    state: 'active'
  }
]);

// ─── Initial Procurement Unit Members (Aligned with procurement-v4.sql lines 428-436) ───
export const unitMembersStore = ref<ProcurementUnitMemberRecord[]>([
  {
    id: 1,
    uuid: 'pum-uuid-001',
    procurement_unit_id: 2,
    member_employee_id: 88,
    employee_name: 'Hanna Girma',
    employee_code: 'EMP-0088',
    avatar: employeeAvatarMap[88],
    role: 'buyer',
    organization_unit_id: null,
    department_name: 'All Departments',
    valid_from: '2026-07-01',
    valid_to: null,
    state: 'active'
  },
  {
    id: 2,
    uuid: 'pum-uuid-002',
    procurement_unit_id: 2,
    member_employee_id: 90,
    employee_name: 'Yonas Alemu',
    employee_code: 'EMP-0090',
    avatar: employeeAvatarMap[90],
    role: 'unit_approver',
    organization_unit_id: null,
    department_name: 'All Departments',
    valid_from: '2026-07-01',
    valid_to: null,
    state: 'active'
  },
  {
    id: 3,
    uuid: 'pum-uuid-003',
    procurement_unit_id: 2,
    member_employee_id: 91,
    employee_name: 'Meseret Tadesse',
    employee_code: 'EMP-0091',
    avatar: employeeAvatarMap[91],
    role: 'receiver',
    organization_unit_id: null,
    department_name: 'All Departments',
    valid_from: '2026-07-01',
    valid_to: null,
    state: 'active'
  },
  {
    id: 4,
    uuid: 'pum-uuid-004',
    procurement_unit_id: 2,
    member_employee_id: 95,
    employee_name: 'Kidist Bekele',
    employee_code: 'EMP-0095',
    avatar: employeeAvatarMap[95],
    role: 'requester',
    organization_unit_id: 12,
    department_name: 'Food & Beverage (OU-12)',
    valid_from: '2026-07-01',
    valid_to: null,
    state: 'active'
  },
  {
    id: 5,
    uuid: 'pum-uuid-005',
    procurement_unit_id: 2,
    member_employee_id: 95,
    employee_name: 'Kidist Bekele',
    employee_code: 'EMP-0095',
    avatar: employeeAvatarMap[95],
    role: 'requester',
    organization_unit_id: 14,
    department_name: 'Housekeeping (OU-14)',
    valid_from: '2026-07-01',
    valid_to: null,
    state: 'active'
  },
  {
    id: 6,
    uuid: 'pum-uuid-006',
    procurement_unit_id: 1,
    member_employee_id: 92,
    employee_name: 'Abebe Kassa',
    employee_code: 'EMP-0092',
    avatar: employeeAvatarMap[92],
    role: 'buyer',
    organization_unit_id: null,
    department_name: 'All Departments',
    valid_from: '2026-07-01',
    valid_to: null,
    state: 'active'
  },
  {
    id: 7,
    uuid: 'pum-uuid-007',
    procurement_unit_id: 1,
    member_employee_id: 90,
    employee_name: 'Yonas Alemu',
    employee_code: 'EMP-0090',
    avatar: employeeAvatarMap[90],
    role: 'unit_approver',
    organization_unit_id: null,
    department_name: 'All Departments',
    valid_from: '2026-07-01',
    valid_to: null,
    state: 'active'
  },
  {
    id: 8,
    uuid: 'pum-uuid-008',
    procurement_unit_id: 3,
    member_employee_id: 98,
    employee_name: 'Sara Tesfaye',
    employee_code: 'EMP-0098',
    avatar: employeeAvatarMap[98],
    role: 'buyer',
    organization_unit_id: 16,
    department_name: 'Wellness & Spa (OU-16)',
    valid_from: '2026-08-01',
    valid_to: null,
    state: 'active'
  },
  {
    id: 9,
    uuid: 'pum-uuid-009',
    procurement_unit_id: 2,
    member_employee_id: 99,
    employee_name: 'Dawit Mekonnen',
    employee_code: 'EMP-0099',
    avatar: employeeAvatarMap[99],
    role: 'buyer',
    organization_unit_id: 12,
    department_name: 'Food & Beverage (OU-12)',
    valid_from: '2026-07-01',
    valid_to: null,
    state: 'active'
  },
  {
    id: 10,
    uuid: 'pum-uuid-010',
    procurement_unit_id: 2,
    member_employee_id: 100,
    employee_name: 'Tigist Haile',
    employee_code: 'EMP-0100',
    avatar: employeeAvatarMap[100],
    role: 'requester',
    organization_unit_id: 12,
    department_name: 'Food & Beverage (OU-12)',
    valid_from: '2026-07-01',
    valid_to: null,
    state: 'active'
  },
  {
    id: 11,
    uuid: 'pum-uuid-011',
    procurement_unit_id: 2,
    member_employee_id: 101,
    employee_name: 'Bereket Tadesse',
    employee_code: 'EMP-0101',
    avatar: employeeAvatarMap[101],
    role: 'receiver',
    organization_unit_id: 14,
    department_name: 'Housekeeping (OU-14)',
    valid_from: '2026-07-01',
    valid_to: null,
    state: 'active'
  },
  {
    id: 12,
    uuid: 'pum-uuid-012',
    procurement_unit_id: 2,
    member_employee_id: 102,
    employee_name: 'Selamawit Teshome',
    employee_code: 'EMP-0102',
    avatar: employeeAvatarMap[102],
    role: 'buyer',
    organization_unit_id: 20,
    department_name: 'Corporate HQ Operations (OU-20)',
    valid_from: '2026-07-01',
    valid_to: null,
    state: 'active'
  },
  {
    id: 13,
    uuid: 'pum-uuid-013',
    procurement_unit_id: 2,
    member_employee_id: 103,
    employee_name: 'Samuel Kebede',
    employee_code: 'EMP-0103',
    avatar: employeeAvatarMap[103],
    role: 'unit_approver',
    organization_unit_id: 25,
    department_name: 'Finance & Accounts (OU-25)',
    valid_from: '2026-07-01',
    valid_to: null,
    state: 'active'
  },
  {
    id: 14,
    uuid: 'pum-uuid-014',
    procurement_unit_id: 2,
    member_employee_id: 104,
    employee_name: 'Rahel Demissie',
    employee_code: 'EMP-0104',
    avatar: employeeAvatarMap[104],
    role: 'viewer',
    organization_unit_id: 25,
    department_name: 'Finance & Accounts (OU-25)',
    valid_from: '2026-07-01',
    valid_to: null,
    state: 'active'
  }
]);
