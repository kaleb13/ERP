// =============================================================================
// Haleta ERP -- Human Resources (HR) Module
// Section 12: Separation & Settlement Authoritative Data Model & Mock Data
// Aligned 100% with HR Schema Designer 1.sql lines 1983-2100 & HR_Schema_final-v4.sql
// =============================================================================

import { ref } from 'vue';

// ─── LOOKUP DEFINITIONS (Exact Schema Enums) ──────────────────────────────────
export type SeparationType =
  | 'resignation'
  | 'termination'
  | 'end_of_contract'
  | 'retirement'
  | 'death'
  | 'redundancy'
  | 'mutual_agreement';

export type SeparationStatus =
  | 'draft'
  | 'pending'
  | 'approved'
  | 'in_clearance'
  | 'cleared'
  | 'settled'
  | 'cancelled';

export type ClearanceItemState =
  | 'pending'
  | 'cleared'
  | 'flagged'
  | 'waived';

export type SettlementState =
  | 'draft'
  | 'calculated'
  | 'approved'
  | 'paid';

export type SettlementLineType =
  | 'prorated_salary'
  | 'severance'
  | 'notice_pay'
  | 'leave_encashment'
  | 'bonus'
  | 'loan_recovery'
  | 'deduction'
  | 'other';

// Human-friendly label mappings
export const SEPARATION_TYPE_MAP: Record<SeparationType, string> = {
  resignation: 'Resignation',
  termination: 'Termination',
  end_of_contract: 'End of Contract',
  retirement: 'Retirement',
  death: 'Death in Service',
  redundancy: 'Redundancy',
  mutual_agreement: 'Mutual Agreement'
};

export const SEPARATION_STATUS_MAP: Record<SeparationStatus, { label: string; color: string; bg: string }> = {
  draft: { label: 'Draft', color: '#1d4ed8', bg: '#eff6ff' },
  pending: { label: 'Pending Approval', color: '#b45309', bg: '#fef3c7' },
  approved: { label: 'Approved', color: '#0369a1', bg: '#e0f2fe' },
  in_clearance: { label: 'In Clearance', color: '#7c3aed', bg: '#f3e8ff' },
  cleared: { label: 'Cleared', color: '#059669', bg: '#ecfdf5' },
  settled: { label: 'Settled', color: '#475569', bg: '#f1f5f9' },
  cancelled: { label: 'Cancelled', color: '#dc2626', bg: '#fee2e2' }
};

export const CLEARANCE_STATE_MAP: Record<ClearanceItemState, { label: string; color: string; bg: string }> = {
  pending: { label: 'Pending', color: '#b45309', bg: '#fef3c7' },
  cleared: { label: 'Cleared', color: '#059669', bg: '#ecfdf5' },
  flagged: { label: 'Flagged (Deduction)', color: '#dc2626', bg: '#fee2e2' },
  waived: { label: 'Waived', color: '#64748b', bg: '#f1f5f9' }
};

export const SETTLEMENT_STATE_MAP: Record<SettlementState, { label: string; color: string; bg: string }> = {
  draft: { label: 'Draft', color: '#1d4ed8', bg: '#eff6ff' },
  calculated: { label: 'Calculated', color: '#7c3aed', bg: '#f3e8ff' },
  approved: { label: 'Approved', color: '#059669', bg: '#ecfdf5' },
  paid: { label: 'Paid & Disbursed', color: '#0f766e', bg: '#ccfbf1' }
};

export const SETTLEMENT_LINE_TYPE_MAP: Record<SettlementLineType, string> = {
  prorated_salary: 'Prorated Monthly Salary',
  severance: 'Statutory Severance Pay',
  notice_pay: 'Payment in Lieu of Notice',
  leave_encashment: 'Accrued Leave Encashment',
  bonus: 'Accrued Performance Bonus',
  loan_recovery: 'Salary Advance / Loan Recovery',
  deduction: 'Clearance Flagged Deduction',
  other: 'Other Discretionary Line'
};

// ─── INTERFACES (Mapped to SQL Schema Tables) ─────────────────────────────────

export interface EmployeeSeparationRecord {
  id: number;
  uuid: string;
  code: string; // DocumentSequence SEP-2026-0011
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_avatar: string;
  department: string;
  position: string;
  tenant_id: number;
  entity_id: number;
  separation_type: SeparationType;
  separation_state: SeparationStatus;
  notice_date: string; // YYYY-MM-DD
  last_working_date: string; // YYYY-MM-DD
  reason: string; // JSONB localized narrative
  disciplinary_action_id?: number | null;
  disciplinary_reference?: string | null;
  is_rehire_eligible: boolean | null;
  exit_interview_note?: string | null;
  employee_movement_id?: number | null;
  approved_by_employee_id?: number | null;
  approved_by_name?: string | null;
  approved_at?: string | null;
  user_id: number;
  state: 'active' | 'inactive';
}

export interface ClearanceItemRecord {
  id: number;
  uuid: string;
  tenant_id: number;
  entity_id: number;
  employee_separation_id: number;
  separation_code: string;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  department: string;
  organization_unit_id: number;
  organization_unit_name: string;
  clearance_state: ClearanceItemState;
  title: string; // Localized e.g. "Revoke ERP access", "Return laptop"
  flagged_amount: number | null; // feeds FinalSettlementLine deduction
  cleared_by_employee_id: number | null;
  cleared_by_name?: string | null;
  cleared_at: string | null;
  notes?: string | null;
  order: number;
  state: 'active' | 'inactive';
}

export interface FinalSettlementLineRecord {
  id: number;
  uuid: string;
  tenant_id: number;
  entity_id: number;
  final_settlement_id: number;
  line_type: SettlementLineType;
  payroll_component_id?: number | null;
  description: string;
  quantity?: number | null;
  rate?: number | null;
  amount: number; // Signed: earnings +, deductions -
  source_type: 'LeaveAllocation' | 'EmployeeLoan' | 'ClearanceItem' | 'StatutoryRule' | 'Manual';
  source_id?: number | null;
  order: number;
  state: 'active' | 'inactive';
}

export interface FinalSettlementRecord {
  id: number;
  uuid: string;
  code: string; // DocumentSequence FST-2026-0008
  employee_separation_id: number;
  separation_code: string;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_avatar: string;
  department: string;
  position: string;
  tenant_id: number;
  entity_id: number;
  settlement_state: SettlementState;
  service_years: number; // e.g. 3.50, 21.30
  gross_amount: number;
  deduction_amount: number;
  net_amount: number;
  currency_id: number;
  currency_code: string;
  payroll_run_id?: number | null;
  payroll_run_code?: string | null;
  approved_by_employee_id?: number | null;
  approved_by_name?: string | null;
  approved_at?: string | null;
  paid_at?: string | null;
  user_id: number;
  state: 'active' | 'inactive';
  lines: FinalSettlementLineRecord[];
}

// ─── SEED DATASETS (Directly Seeded from Designer 1 Schema Examples) ──────────

export const separationsData = ref<EmployeeSeparationRecord[]>([
  {
    id: 11,
    uuid: '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
    code: 'SEP-2026-0011',
    employee_id: 18,
    employee_name: 'Kidst Tesfaye',
    employee_code: 'EMP-0018',
    employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    department: 'Plant Operations & Security',
    position: 'HQ Security Supervisor',
    tenant_id: 1,
    entity_id: 3,
    separation_type: 'termination',
    separation_state: 'settled',
    notice_date: '2026-02-01',
    last_working_date: '2026-03-02',
    reason: 'Termination following formal disciplinary review regarding breach of safety protocols.',
    disciplinary_action_id: 104,
    disciplinary_reference: 'DISC-2026-0104',
    is_rehire_eligible: false,
    exit_interview_note: 'Employee informed of formal termination decision per Disciplinary Committee hearing.',
    approved_by_employee_id: 7,
    approved_by_name: 'Solomon Worku',
    approved_at: '2026-02-05T14:30:00Z',
    user_id: 1,
    state: 'active'
  },
  {
    id: 12,
    uuid: 'c827b5e4-2391-4235-9852-c08df8b65219',
    code: 'SEP-2026-0012',
    employee_id: 19,
    employee_name: 'Binyam Getachew',
    employee_code: 'EMP-0019',
    employee_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
    department: 'Finance & Accounting',
    position: 'Senior Accountant',
    tenant_id: 1,
    entity_id: 3,
    separation_type: 'resignation',
    separation_state: 'in_clearance',
    notice_date: '2026-07-01',
    last_working_date: '2026-07-31',
    reason: 'Tendered resignation to pursue postgraduate studies abroad.',
    disciplinary_action_id: null,
    is_rehire_eligible: true,
    exit_interview_note: 'Employee expressed high appreciation for Haleta team. Offered positive feedback regarding peer culture.',
    approved_by_employee_id: 7,
    approved_by_name: 'Solomon Worku',
    approved_at: '2026-07-03T09:15:00Z',
    user_id: 1,
    state: 'active'
  },
  {
    id: 13,
    uuid: 'e712a109-1834-4530-9b43-b671a5472013',
    code: 'SEP-2026-0013',
    employee_id: 20,
    employee_name: 'Tigist Alemu',
    employee_code: 'EMP-0020',
    employee_avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
    department: 'Human Resources',
    position: 'Recruitment Specialist',
    tenant_id: 1,
    entity_id: 3,
    separation_type: 'end_of_contract',
    separation_state: 'approved',
    notice_date: '2026-07-15',
    last_working_date: '2026-08-16',
    reason: 'Expiry of fixed-term project agreement for workforce scaling FY2026.',
    disciplinary_action_id: null,
    is_rehire_eligible: true,
    exit_interview_note: 'Contract concluded with distinction. Eligible for priority hiring on future project expansions.',
    approved_by_employee_id: 7,
    approved_by_name: 'Solomon Worku',
    approved_at: '2026-07-16T11:00:00Z',
    user_id: 1,
    state: 'active'
  },
  {
    id: 14,
    uuid: 'f5619b02-5321-4209-913a-df01b7a21014',
    code: 'SEP-2026-0014',
    employee_id: 21,
    employee_name: 'Kassahun Bekele',
    employee_code: 'EMP-0021',
    employee_avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80',
    department: 'Operations & Logistics',
    position: 'Fleet & Logistics Director',
    tenant_id: 1,
    entity_id: 3,
    separation_type: 'retirement',
    separation_state: 'cleared',
    notice_date: '2026-05-01',
    last_working_date: '2026-06-30',
    reason: 'Statutory age-based retirement following 21+ years of honorable service.',
    disciplinary_action_id: null,
    is_rehire_eligible: null,
    exit_interview_note: 'Long-standing veteran honored with corporate commendation letter and retirement gratuity.',
    approved_by_employee_id: 7,
    approved_by_name: 'Solomon Worku',
    approved_at: '2026-05-05T16:00:00Z',
    user_id: 1,
    state: 'active'
  },
  {
    id: 15,
    uuid: 'a381df44-9011-4710-8b11-a890b1c52015',
    code: 'SEP-2026-0015',
    employee_id: 15,
    employee_name: 'Marta Tadesse',
    employee_code: 'EMP-0015',
    employee_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    department: 'Information Technology',
    position: 'Systems Analyst',
    tenant_id: 1,
    entity_id: 3,
    separation_type: 'resignation',
    separation_state: 'draft',
    notice_date: '2026-07-28',
    last_working_date: '2026-08-27',
    reason: 'Personal relocation to regional branch area.',
    disciplinary_action_id: null,
    is_rehire_eligible: null,
    exit_interview_note: null,
    approved_by_employee_id: null,
    approved_by_name: null,
    approved_at: null,
    user_id: 1,
    state: 'active'
  }
]);

export const clearanceItemsData = ref<ClearanceItemRecord[]>([
  {
    id: 1,
    uuid: 'clr-001-9b1d',
    tenant_id: 1,
    entity_id: 3,
    employee_separation_id: 12,
    separation_code: 'SEP-2026-0012',
    employee_id: 19,
    employee_name: 'Binyam Getachew',
    employee_code: 'EMP-0019',
    department: 'Finance & Accounting',
    organization_unit_id: 5,
    organization_unit_name: 'Information Technology',
    clearance_state: 'cleared',
    title: 'Revoke ERP access & Email Account',
    flagged_amount: null,
    cleared_by_employee_id: 7,
    cleared_by_name: 'Solomon Worku',
    cleared_at: '2026-07-25T10:14:00Z',
    notes: 'ERP user role deactivated and G-Suite email archived.',
    order: 1,
    state: 'active'
  },
  {
    id: 2,
    uuid: 'clr-002-c827',
    tenant_id: 1,
    entity_id: 3,
    employee_separation_id: 12,
    separation_code: 'SEP-2026-0012',
    employee_id: 19,
    employee_name: 'Binyam Getachew',
    employee_code: 'EMP-0019',
    department: 'Finance & Accounting',
    organization_unit_id: 4,
    organization_unit_name: 'Facilities & Hardware Assets',
    clearance_state: 'pending',
    title: 'Return Laptop (Dell Latitude 5540 & Charger)',
    flagged_amount: null,
    cleared_by_employee_id: null,
    cleared_by_name: null,
    cleared_at: null,
    notes: 'Pending physical return to IT inventory desk.',
    order: 2,
    state: 'active'
  },
  {
    id: 3,
    uuid: 'clr-003-e712',
    tenant_id: 1,
    entity_id: 3,
    employee_separation_id: 12,
    separation_code: 'SEP-2026-0012',
    employee_id: 19,
    employee_name: 'Binyam Getachew',
    employee_code: 'EMP-0019',
    department: 'Finance & Accounting',
    organization_unit_id: 2,
    organization_unit_name: 'Finance & Payroll',
    clearance_state: 'flagged',
    title: 'Outstanding Salary Advance Balance',
    flagged_amount: 4333.34,
    cleared_by_employee_id: 22,
    cleared_by_name: 'Hana Mesfin',
    cleared_at: '2026-07-26T15:20:00Z',
    notes: 'Remaining unamortized advance balance; feeds final settlement deduction line.',
    order: 3,
    state: 'active'
  },
  {
    id: 4,
    uuid: 'clr-004-f561',
    tenant_id: 1,
    entity_id: 3,
    employee_separation_id: 14,
    separation_code: 'SEP-2026-0014',
    employee_id: 21,
    employee_name: 'Kassahun Bekele',
    employee_code: 'EMP-0021',
    department: 'Operations & Logistics',
    organization_unit_id: 2,
    organization_unit_name: 'Finance & Accounts',
    clearance_state: 'cleared',
    title: 'Till float & Fuel card reconciliation',
    flagged_amount: null,
    cleared_by_employee_id: 22,
    cleared_by_name: 'Hana Mesfin',
    cleared_at: '2026-06-28T16:00:00Z',
    notes: 'All receipts surrendered and cash float balanced with zero variance.',
    order: 1,
    state: 'active'
  },
  {
    id: 5,
    uuid: 'clr-005-a381',
    tenant_id: 1,
    entity_id: 3,
    employee_separation_id: 11,
    separation_code: 'SEP-2026-0011',
    employee_id: 18,
    employee_name: 'Kidst Tesfaye',
    employee_code: 'EMP-0018',
    department: 'Plant Operations & Security',
    organization_unit_id: 3,
    organization_unit_name: 'Plant Operations & Security',
    clearance_state: 'cleared',
    title: 'Security Badge & Uniform Return',
    flagged_amount: null,
    cleared_by_employee_id: 14,
    cleared_by_name: 'Abebe Kebede',
    cleared_at: '2026-03-01T11:30:00Z',
    notes: 'Access keys and security uniform returned in full.',
    order: 1,
    state: 'active'
  },
  {
    id: 6,
    uuid: 'clr-006-b912',
    tenant_id: 1,
    entity_id: 3,
    employee_separation_id: 13,
    separation_code: 'SEP-2026-0013',
    employee_id: 20,
    employee_name: 'Tigist Alemu',
    employee_code: 'EMP-0020',
    department: 'Human Resources',
    organization_unit_id: 1,
    organization_unit_name: 'Human Resources',
    clearance_state: 'cleared',
    title: 'Recruitment Records Handover',
    flagged_amount: null,
    cleared_by_employee_id: 7,
    cleared_by_name: 'Solomon Worku',
    cleared_at: '2026-08-10T14:00:00Z',
    notes: 'Candidate pipelines and interview assessment forms transferred to incoming lead.',
    order: 1,
    state: 'active'
  }
]);

export const finalSettlementsData = ref<FinalSettlementRecord[]>([
  {
    id: 8,
    uuid: 'fst-008-9b1d',
    code: 'FST-2026-0008',
    employee_separation_id: 11,
    separation_code: 'SEP-2026-0011',
    employee_id: 18,
    employee_name: 'Kidst Tesfaye',
    employee_code: 'EMP-0018',
    employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    department: 'Plant Operations & Security',
    position: 'HQ Security Supervisor',
    tenant_id: 1,
    entity_id: 3,
    settlement_state: 'paid',
    service_years: 3.50,
    gross_amount: 42100.00,
    deduction_amount: 9400.00,
    net_amount: 32700.00,
    currency_id: 1,
    currency_code: 'ETB',
    payroll_run_id: 88,
    payroll_run_code: 'PAY-2026-M03-FINAL',
    approved_by_employee_id: 7,
    approved_by_name: 'Solomon Worku',
    approved_at: '2026-03-03T10:00:00Z',
    paid_at: '2026-03-05T12:00:00Z',
    user_id: 1,
    state: 'active',
    lines: [
      {
        id: 1,
        uuid: 'fsl-001-8',
        tenant_id: 1,
        entity_id: 3,
        final_settlement_id: 8,
        line_type: 'prorated_salary',
        description: 'February worked days (28 days)',
        quantity: 28,
        rate: 650.00,
        amount: 18200.00,
        source_type: 'Manual',
        order: 1,
        state: 'active'
      },
      {
        id: 2,
        uuid: 'fsl-002-8',
        tenant_id: 1,
        entity_id: 3,
        final_settlement_id: 8,
        line_type: 'severance',
        description: 'Statutory Severance (3.50 yrs tenure)',
        quantity: 3.5,
        rate: 5000.00,
        amount: 17400.00,
        source_type: 'StatutoryRule',
        order: 2,
        state: 'active'
      },
      {
        id: 3,
        uuid: 'fsl-003-8',
        tenant_id: 1,
        entity_id: 3,
        final_settlement_id: 8,
        line_type: 'notice_pay',
        description: 'Notice period pay (30 days)',
        quantity: 30,
        rate: 216.6667,
        amount: 6500.00,
        source_type: 'Manual',
        order: 3,
        state: 'active'
      },
      {
        id: 4,
        uuid: 'fsl-004-8',
        tenant_id: 1,
        entity_id: 3,
        final_settlement_id: 8,
        line_type: 'deduction',
        description: 'Terminal statutory income tax & adjustments',
        quantity: null,
        rate: null,
        amount: -9400.00,
        source_type: 'Manual',
        order: 4,
        state: 'active'
      }
    ]
  },
  {
    id: 9,
    uuid: 'fst-009-c827',
    code: 'FST-2026-0009',
    employee_separation_id: 14,
    separation_code: 'SEP-2026-0014',
    employee_id: 21,
    employee_name: 'Kassahun Bekele',
    employee_code: 'EMP-0021',
    employee_avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80',
    department: 'Operations & Logistics',
    position: 'Fleet & Logistics Director',
    tenant_id: 1,
    entity_id: 3,
    settlement_state: 'approved',
    service_years: 21.30,
    gross_amount: 386000.00,
    deduction_amount: 41200.00,
    net_amount: 344800.00,
    currency_id: 1,
    currency_code: 'ETB',
    payroll_run_id: null,
    payroll_run_code: null,
    approved_by_employee_id: 7,
    approved_by_name: 'Solomon Worku',
    approved_at: '2026-07-02T16:00:00Z',
    paid_at: null,
    user_id: 1,
    state: 'active',
    lines: [
      {
        id: 5,
        uuid: 'fsl-005-9',
        tenant_id: 1,
        entity_id: 3,
        final_settlement_id: 9,
        line_type: 'severance',
        description: 'Severance (21.3 yrs, statutory cap formula)',
        quantity: null,
        rate: null,
        amount: 288000.00,
        source_type: 'StatutoryRule',
        order: 1,
        state: 'active'
      },
      {
        id: 6,
        uuid: 'fsl-006-9',
        tenant_id: 1,
        entity_id: 3,
        final_settlement_id: 9,
        line_type: 'leave_encashment',
        description: '30 unused annual leave days encashment',
        quantity: 30.00,
        rate: 1230.7692,
        amount: 36923.08,
        source_type: 'LeaveAllocation',
        order: 2,
        state: 'active'
      },
      {
        id: 7,
        uuid: 'fsl-007-9',
        tenant_id: 1,
        entity_id: 3,
        final_settlement_id: 9,
        line_type: 'prorated_salary',
        description: 'June worked days (30 days full month)',
        quantity: 30.00,
        rate: 2035.90,
        amount: 61076.92,
        source_type: 'Manual',
        order: 3,
        state: 'active'
      },
      {
        id: 8,
        uuid: 'fsl-008-9',
        tenant_id: 1,
        entity_id: 3,
        final_settlement_id: 9,
        line_type: 'deduction',
        description: 'Terminal progressive income tax deduction',
        quantity: null,
        rate: null,
        amount: -41200.00,
        source_type: 'Manual',
        order: 4,
        state: 'active'
      }
    ]
  },
  {
    id: 10,
    uuid: 'fst-010-e712',
    code: 'FST-2026-0010',
    employee_separation_id: 12,
    separation_code: 'SEP-2026-0012',
    employee_id: 19,
    employee_name: 'Binyam Getachew',
    employee_code: 'EMP-0019',
    employee_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
    department: 'Finance & Accounting',
    position: 'Senior Accountant',
    tenant_id: 1,
    entity_id: 3,
    settlement_state: 'calculated',
    service_years: 2.10,
    gross_amount: 21500.00,
    deduction_amount: 6800.00,
    net_amount: 14700.00,
    currency_id: 1,
    currency_code: 'ETB',
    payroll_run_id: null,
    payroll_run_code: null,
    approved_by_employee_id: null,
    approved_by_name: null,
    approved_at: null,
    paid_at: null,
    user_id: 1,
    state: 'active',
    lines: [
      {
        id: 9,
        uuid: 'fsl-009-10',
        tenant_id: 1,
        entity_id: 3,
        final_settlement_id: 10,
        line_type: 'prorated_salary',
        description: 'July worked days (22 days)',
        quantity: 22.00,
        rate: 250.00,
        amount: 5500.00,
        source_type: 'Manual',
        order: 1,
        state: 'active'
      },
      {
        id: 10,
        uuid: 'fsl-010-10',
        tenant_id: 1,
        entity_id: 3,
        final_settlement_id: 10,
        line_type: 'leave_encashment',
        description: '16 unused accrued leave days',
        quantity: 16.00,
        rate: 1000.00,
        amount: 16000.00,
        source_type: 'LeaveAllocation',
        order: 2,
        state: 'active'
      },
      {
        id: 11,
        uuid: 'fsl-011-10',
        tenant_id: 1,
        entity_id: 3,
        final_settlement_id: 10,
        line_type: 'loan_recovery',
        description: 'Clearance recovery: Outstanding salary advance balance',
        quantity: null,
        rate: null,
        amount: -4333.34,
        source_type: 'ClearanceItem',
        source_id: 3,
        order: 3,
        state: 'active'
      },
      {
        id: 12,
        uuid: 'fsl-012-10',
        tenant_id: 1,
        entity_id: 3,
        final_settlement_id: 10,
        line_type: 'deduction',
        description: 'Statutory income tax adjustments',
        quantity: null,
        rate: null,
        amount: -2466.66,
        source_type: 'Manual',
        order: 4,
        state: 'active'
      }
    ]
  },
  {
    id: 11,
    uuid: 'fst-011-f561',
    code: 'FST-2026-0011',
    employee_separation_id: 13,
    separation_code: 'SEP-2026-0013',
    employee_id: 20,
    employee_name: 'Tigist Alemu',
    employee_code: 'EMP-0020',
    employee_avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
    department: 'Human Resources',
    position: 'Recruitment Specialist',
    tenant_id: 1,
    entity_id: 3,
    settlement_state: 'draft',
    service_years: 1.00,
    gross_amount: 11800.00,
    deduction_amount: 2100.00,
    net_amount: 9700.00,
    currency_id: 1,
    currency_code: 'ETB',
    payroll_run_id: null,
    payroll_run_code: null,
    approved_by_employee_id: null,
    approved_by_name: null,
    approved_at: null,
    paid_at: null,
    user_id: 1,
    state: 'active',
    lines: [
      {
        id: 13,
        uuid: 'fsl-013-11',
        tenant_id: 1,
        entity_id: 3,
        final_settlement_id: 11,
        line_type: 'prorated_salary',
        description: 'August worked days (16 days)',
        quantity: 16.00,
        rate: 550.00,
        amount: 8800.00,
        source_type: 'Manual',
        order: 1,
        state: 'active'
      },
      {
        id: 14,
        uuid: 'fsl-014-11',
        tenant_id: 1,
        entity_id: 3,
        final_settlement_id: 11,
        line_type: 'bonus',
        description: 'Project contract completion bonus',
        quantity: null,
        rate: null,
        amount: 3000.00,
        source_type: 'Manual',
        order: 2,
        state: 'active'
      },
      {
        id: 15,
        uuid: 'fsl-015-11',
        tenant_id: 1,
        entity_id: 3,
        final_settlement_id: 11,
        line_type: 'deduction',
        description: 'Statutory income tax withholding',
        quantity: null,
        rate: null,
        amount: -2100.00,
        source_type: 'Manual',
        order: 3,
        state: 'active'
      }
    ]
  }
]);

// ─── STATE MUTATION METHODS ───────────────────────────────────────────────────

export function addSeparationRecord(
  record: Omit<EmployeeSeparationRecord, 'id' | 'uuid' | 'code' | 'tenant_id' | 'entity_id' | 'user_id' | 'state'>,
  customClearanceItems?: Array<{ organization_unit_id: number; title: string; notes?: string | null }>
): EmployeeSeparationRecord {
  const newId = separationsData.value.length ? Math.max(...separationsData.value.map(s => s.id)) + 1 : 1;
  const newCode = `SEP-2026-${String(newId).padStart(4, '0')}`;
  const fullRecord: EmployeeSeparationRecord = {
    ...record,
    id: newId,
    uuid: `sep-${newId}-${Date.now()}`,
    code: newCode,
    tenant_id: 1,
    entity_id: 3,
    user_id: 1,
    state: 'active'
  };
  separationsData.value.unshift(fullRecord);

  const ouNameMap: Record<number, string> = {
    1: 'Human Resources',
    2: 'Finance & Accounts',
    3: 'Plant Operations & Security',
    4: 'Facilities & Hardware Assets',
    5: 'Information Technology',
    6: 'Procurement & Logistics'
  };

  const defaultDepts = [
    { ouId: 5, ouName: 'Information Technology', title: 'Revoke ERP & Email Credentials', notes: null },
    { ouId: 4, ouName: 'Facilities & Hardware Assets', title: 'Asset Return & Custody Handover', notes: null },
    { ouId: 2, ouName: 'Finance & Accounts', title: 'Loans, Float & Financial Clearance', notes: null },
    { ouId: 1, ouName: 'Human Resources', title: 'ID Card Surrender & Exit Interview', notes: null }
  ];

  const itemsToCreate = (customClearanceItems && customClearanceItems.length > 0)
    ? customClearanceItems.map((c, i) => ({
        ouId: c.organization_unit_id,
        ouName: ouNameMap[c.organization_unit_id] || 'General Administration',
        title: c.title,
        notes: c.notes || null,
        order: i + 1
      }))
    : defaultDepts.map((d, i) => ({ ...d, order: i + 1 }));

  itemsToCreate.forEach((d, idx) => {
    clearanceItemsData.value.push({
      id: clearanceItemsData.value.length + 1,
      uuid: `clr-${Date.now()}-${idx}`,
      tenant_id: 1,
      entity_id: 3,
      employee_separation_id: newId,
      separation_code: newCode,
      employee_id: fullRecord.employee_id,
      employee_name: fullRecord.employee_name,
      employee_code: fullRecord.employee_code,
      department: fullRecord.department,
      organization_unit_id: d.ouId,
      organization_unit_name: d.ouName,
      clearance_state: 'pending',
      title: d.title,
      flagged_amount: null,
      cleared_by_employee_id: null,
      cleared_by_name: null,
      cleared_at: null,
      notes: d.notes,
      order: d.order,
      state: 'active'
    });
  });

  return fullRecord;
}

export function updateClearanceState(itemId: number, newState: ClearanceItemState, flaggedAmount?: number | null, notes?: string | null) {
  const item = clearanceItemsData.value.find(c => c.id === itemId);
  if (item) {
    item.clearance_state = newState;
    item.notes = notes || item.notes;
    if (newState === 'cleared') {
      item.cleared_by_employee_id = 7;
      item.cleared_by_name = 'Solomon Worku (HR Officer)';
      item.cleared_at = new Date().toISOString();
      item.flagged_amount = null;
    } else if (newState === 'flagged') {
      item.flagged_amount = flaggedAmount !== undefined ? flaggedAmount : item.flagged_amount;
      item.cleared_by_employee_id = 7;
      item.cleared_by_name = 'Solomon Worku (HR Officer)';
      item.cleared_at = new Date().toISOString();
    } else if (newState === 'waived') {
      item.cleared_by_employee_id = 7;
      item.cleared_by_name = 'Solomon Worku (HR Officer)';
      item.cleared_at = new Date().toISOString();
      item.flagged_amount = null;
    }
  }
}

export function updateSettlementStatus(settlementId: number, newState: SettlementState) {
  const st = finalSettlementsData.value.find(s => s.id === settlementId);
  if (st) {
    st.settlement_state = newState;
    if (newState === 'approved') {
      st.approved_by_employee_id = 7;
      st.approved_by_name = 'Solomon Worku';
      st.approved_at = new Date().toISOString();
    } else if (newState === 'paid') {
      st.paid_at = new Date().toISOString();
      st.payroll_run_code = 'PAY-2026-FINAL';
    }
  }
}

export function addClearanceItem(data: {
  employee_separation_id: number;
  organization_unit_id: number;
  title: string;
  notes?: string | null;
}): ClearanceItemRecord | null {
  const sep = separationsData.value.find(s => s.id === data.employee_separation_id);
  if (!sep) return null;

  const ouNameMap: Record<number, string> = {
    1: 'Human Resources',
    2: 'Finance & Accounts',
    3: 'Plant Operations & Security',
    4: 'Facilities & Hardware Assets',
    5: 'Information Technology',
    6: 'Procurement & Logistics'
  };

  const newId = clearanceItemsData.value.length ? Math.max(...clearanceItemsData.value.map(c => c.id)) + 1 : 1;
  const newItem: ClearanceItemRecord = {
    id: newId,
    uuid: `clr-${Date.now()}-${newId}`,
    tenant_id: 1,
    entity_id: 3,
    employee_separation_id: sep.id,
    separation_code: sep.code,
    employee_id: sep.employee_id,
    employee_name: sep.employee_name,
    employee_code: sep.employee_code,
    department: sep.department,
    organization_unit_id: data.organization_unit_id,
    organization_unit_name: ouNameMap[data.organization_unit_id] || 'General Administration',
    clearance_state: 'pending',
    title: data.title,
    flagged_amount: null,
    cleared_by_employee_id: null,
    cleared_by_name: null,
    cleared_at: null,
    notes: data.notes || null,
    order: clearanceItemsData.value.filter(c => c.employee_separation_id === sep.id).length + 1,
    state: 'active'
  };

  clearanceItemsData.value.unshift(newItem);

  // Transition separation to in_clearance if currently approved
  if (sep.separation_state === 'approved') {
    sep.separation_state = 'in_clearance';
  }

  return newItem;
}

export function initializeClearanceForSeparation(separationId: number): number {
  const sep = separationsData.value.find(s => s.id === separationId);
  if (!sep) return 0;

  const defaultDepts = [
    { ouId: 5, ouName: 'Information Technology', title: 'Revoke ERP access & Email credentials' },
    { ouId: 4, ouName: 'Facilities & Hardware Assets', title: 'Return laptop, hardware & peripheral assets' },
    { ouId: 2, ouName: 'Finance & Accounts', title: 'Reconcile salary advance, loans & till float' },
    { ouId: 1, ouName: 'Human Resources', title: 'ID card surrender & medical insurance badge' }
  ];

  defaultDepts.forEach((d) => {
    addClearanceItem({
      employee_separation_id: sep.id,
      organization_unit_id: d.ouId,
      title: d.title,
      notes: null
    });
  });

  sep.separation_state = 'in_clearance';
  return defaultDepts.length;
}

