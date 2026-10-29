import { ref } from 'vue';

export interface LeaveAllocationApprovalStep {
  id: number;
  step_number: number;
  step_name: string;
  approver_name: string;
  approver_role: string;
  approval_state: 'draft' | 'pending' | 'approved' | 'rejected' | 'queued';
  acted_at?: string;
  remarks?: string;
}

// ─── LeaveAllocation [DIST] (Schema lines 1632–1661) ───
export interface LeaveAllocationRecord {
  id: number;
  uuid: string;
  code: string;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_avatar: string;
  job_position: string;
  entity_id: number;
  entity_name: string;
  leave_type_id: number;
  leave_type_name: string;
  leave_type_code: string;
  leave_policy_rule_id?: number | null;
  policy_rule_label?: string;
  period_start: string;
  period_end: string;
  allocated_days: number;
  carried_forward_days: number;
  total_entitled_days: number;
  taken_days: number;
  available_days: number;
  allocation_state: 'draft' | 'submitted' | 'approved' | 'rescheduled' | 'consumed' | 'cancelled';
  rescheduled_from_id?: number | null;
  rescheduled_from_code?: string | null;
  rescheduled_to_id?: number | null;
  rescheduled_to_code?: string | null;
  reschedule_reason?: string | null;
  created_by_name?: string;
  approved_by_employee_id?: number | null;
  approved_by_name?: string | null;
  approver_role?: string;
  approver_avatar?: string;
  approved_at?: string | null;
  approval_remarks?: string;
  notes?: string;
  created_at: string;
  approvals?: LeaveAllocationApprovalStep[];
  // Consumption history lines (LeaveRequest records drawing from this allocation)
  consumptions: {
    request_id: number;
    request_code: string;
    date_range: string;
    deducted_days: number;
    request_status: string;
  }[];
}

// ─── Staff Options for Allocations ───
export interface AllocationStaffMember {
  id: number;
  name: string;
  code: string;
  position: string;
  entity_id: number;
  entity_name: string;
  hire_date: string;
  service_years: number;
  avatar: string;
}

export const staffMembers: AllocationStaffMember[] = [
  {
    id: 7,
    name: 'Marta Tadesse',
    code: 'EMP 0007',
    position: 'Branch Manager',
    entity_id: 3,
    entity_name: 'Haleta Corporate Headquarters',
    hire_date: '2022-01-10',
    service_years: 4,
    avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    id: 14,
    name: 'Abebe Kebede',
    code: 'EMP 0014',
    position: 'Senior Cashier',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    hire_date: '2024-06-01',
    service_years: 2,
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    id: 22,
    name: 'Almaz Kebede',
    code: 'EMP 0124',
    position: 'Senior Accountant',
    entity_id: 3,
    entity_name: 'Haleta Corporate Headquarters',
    hire_date: '2021-09-15',
    service_years: 5,
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    id: 31,
    name: 'Dawit Yohannes',
    code: 'EMP 0031',
    position: 'Logistics Officer',
    entity_id: 9,
    entity_name: 'Bahir Dar Regional Hub',
    hire_date: '2025-02-17',
    service_years: 1,
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    id: 44,
    name: 'Kassahun Belay',
    code: 'EMP 0044',
    position: 'Branch Head',
    entity_id: 3,
    entity_name: 'Haleta Corporate Headquarters',
    hire_date: '2020-03-02',
    service_years: 6,
    avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&h=120&q=80'
  }
];

// ─── Shared Reactive Dataset: Leave Allocations (Schema Examples lines 1654–1660) ───
export const allocationsData = ref<LeaveAllocationRecord[]>([
  {
    id: 451,
    uuid: 'lal-451',
    code: 'LAL-2025-0451',
    employee_id: 7,
    employee_name: 'Marta Tadesse',
    employee_code: 'EMP 0007',
    employee_avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80',
    job_position: 'Branch Manager',
    entity_id: 3,
    entity_name: 'Haleta Corporate Headquarters',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    leave_type_code: 'ANNUAL',
    leave_policy_rule_id: 101,
    policy_rule_label: 'POL-OFFICE-2026 • Statutory Annual (+1d/2yr)',
    period_start: '2025-07-08',
    period_end: '2026-07-07',
    allocated_days: 20.0,
    carried_forward_days: 4.0,
    total_entitled_days: 24.0,
    taken_days: 24.0,
    available_days: 0.0,
    allocation_state: 'consumed',
    notes: 'Prior Ethiopian fiscal year annual allocation; completely consumed at year close.',
    created_at: '2025-07-08',
    approved_by_name: 'Dawit Mengistu (HR Director)',
    approved_at: '2025-07-09 10:30',
    consumptions: [
      { request_id: 810, request_code: 'ALR-2025-0810', date_range: 'Dec 15, 2025 – Dec 29, 2025', deducted_days: 12.0, request_status: 'Approved' },
      { request_id: 890, request_code: 'ALR-2026-0890', date_range: 'Apr 02, 2026 – Apr 16, 2026', deducted_days: 12.0, request_status: 'Approved' }
    ]
  },
  {
    id: 452,
    uuid: 'lal-452',
    code: 'LAL-2026-0452',
    employee_id: 7,
    employee_name: 'Marta Tadesse',
    employee_code: 'EMP 0007',
    employee_avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80',
    job_position: 'Branch Manager',
    entity_id: 3,
    entity_name: 'Haleta Corporate Headquarters',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    leave_type_code: 'ANNUAL',
    leave_policy_rule_id: 101,
    policy_rule_label: 'POL-OFFICE-2026 • Statutory Annual (+1d/2yr)',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    allocated_days: 20.0,
    carried_forward_days: 24.0,
    total_entitled_days: 44.0,
    taken_days: 3.0,
    available_days: 41.0,
    allocation_state: 'approved',
    notes: 'Current Ethiopian FY 2026/27 annual entitlement with 24.0 days rolled over under 2-year statutory limit.',
    created_at: '2026-07-08',
    created_by_name: 'Kassahun Belay (HR Operations Officer)',
    approved_by_name: 'Dawit Mengistu',
    approver_role: 'Director of Human Resources',
    approver_avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&h=120&q=80',
    approved_at: '2026-07-09 11:15',
    approval_remarks: 'Annual statutory service addition verified (+2.0d for 4 yrs service). Carry-forward capped at 24.0 days under statutory 2-year limit.',
    approvals: [
      {
        id: 1,
        step_number: 1,
        step_name: 'Accrual & Service Computation',
        approver_name: 'Kassahun Belay',
        approver_role: 'HR Operations Officer',
        approval_state: 'approved',
        acted_at: 'Jul 8, 2026, 09:00 AM',
        remarks: 'Batch policy accrual calculated per Ethiopian Labor Proclamation No. 1156/2019.'
      },
      {
        id: 2,
        step_number: 2,
        step_name: 'Statutory Policy Compliance',
        approver_name: 'Automated Compliance Engine',
        approver_role: 'Rules Validator',
        approval_state: 'approved',
        acted_at: 'Jul 8, 2026, 09:05 AM',
        remarks: 'Verified 4-year tenure (+2d service addition). 24.0d carry-forward within statutory 2-year rollover window.'
      },
      {
        id: 3,
        step_number: 3,
        step_name: 'Executive HR Authorization',
        approver_name: 'Dawit Mengistu',
        approver_role: 'Director of Human Resources',
        approval_state: 'approved',
        acted_at: 'Jul 9, 2026, 11:15 AM',
        remarks: 'Annual statutory quota grant certified. Carry-forward approved and committed to employee ledger.'
      },
      {
        id: 4,
        step_number: 4,
        step_name: 'Active Quota Deployment',
        approver_name: 'Core Leave Ledger',
        approver_role: 'System Ledger Stamping',
        approval_state: 'approved',
        acted_at: 'Jul 9, 2026, 11:15 AM',
        remarks: 'Balance activated in LeaveBalance projection. Usable for leave requests.'
      }
    ],
    consumptions: [
      { request_id: 911, request_code: 'ALR-2026-0911', date_range: 'Aug 10, 2026 – Aug 12, 2026', deducted_days: 3.0, request_status: 'Approved' }
    ]
  },
  {
    id: 453,
    uuid: 'lal-453',
    code: 'LAL-2026-0453',
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP 0014',
    employee_avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&h=120&q=80',
    job_position: 'Senior Cashier',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    leave_type_code: 'ANNUAL',
    leave_policy_rule_id: 201,
    policy_rule_label: 'POL-RETAIL-2026 • Operational Shift Rule (+1d/2yr)',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    allocated_days: 18.0,
    carried_forward_days: 0.0,
    total_entitled_days: 18.0,
    taken_days: 2.0,
    available_days: 16.0,
    allocation_state: 'approved',
    notes: 'Standard 2-year service addition applied.',
    created_at: '2026-07-08',
    created_by_name: 'Kassahun Belay (HR Operations Officer)',
    approved_by_name: 'Dawit Mengistu',
    approver_role: 'Director of Human Resources',
    approver_avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&h=120&q=80',
    approved_at: '2026-07-09 11:45',
    approval_remarks: 'Retail operations annual allocation approved per shift staff roster.',
    approvals: [
      {
        id: 1,
        step_number: 1,
        step_name: 'Accrual & Service Computation',
        approver_name: 'Kassahun Belay',
        approver_role: 'HR Operations Officer',
        approval_state: 'approved',
        acted_at: 'Jul 8, 2026, 09:10 AM',
        remarks: 'Base 16d + 2d service addition calculated.'
      },
      {
        id: 2,
        step_number: 2,
        step_name: 'Statutory Policy Compliance',
        approver_name: 'Automated Compliance Engine',
        approver_role: 'Rules Validator',
        approval_state: 'approved',
        acted_at: 'Jul 8, 2026, 09:12 AM',
        remarks: 'Policy rules verified.'
      },
      {
        id: 3,
        step_number: 3,
        step_name: 'Executive HR Authorization',
        approver_name: 'Dawit Mengistu',
        approver_role: 'Director of Human Resources',
        approval_state: 'approved',
        acted_at: 'Jul 9, 2026, 11:45 AM',
        remarks: 'Authorized for branch cashier operations.'
      },
      {
        id: 4,
        step_number: 4,
        step_name: 'Active Quota Deployment',
        approver_name: 'Core Leave Ledger',
        approver_role: 'System Ledger Stamping',
        approval_state: 'approved',
        acted_at: 'Jul 9, 2026, 11:45 AM',
        remarks: 'Live balance stamped.'
      }
    ],
    consumptions: [
      { request_id: 915, request_code: 'ALR-2026-0915', date_range: 'Sep 01, 2026 – Sep 02, 2026', deducted_days: 2.0, request_status: 'Approved' }
    ]
  },
  {
    id: 454,
    uuid: 'lal-454',
    code: 'LAL-2026-0454',
    employee_id: 22,
    employee_name: 'Almaz Kebede',
    employee_code: 'EMP 0124',
    employee_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=120&h=120&q=80',
    job_position: 'Senior Accountant',
    entity_id: 3,
    entity_name: 'Haleta Corporate Headquarters',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    leave_type_code: 'ANNUAL',
    leave_policy_rule_id: 101,
    policy_rule_label: 'POL-OFFICE-2026 • Statutory Annual (+1d/2yr)',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    allocated_days: 21.0,
    carried_forward_days: 6.0,
    total_entitled_days: 27.0,
    taken_days: 5.0,
    available_days: 22.0,
    allocation_state: 'approved',
    notes: 'Approved annual allocation with 6.0 days carry-forward.',
    created_at: '2026-07-08',
    created_by_name: 'Kassahun Belay (HR Operations Officer)',
    approved_by_name: 'Dawit Mengistu',
    approver_role: 'Director of Human Resources',
    approver_avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&h=120&q=80',
    approved_at: '2026-07-09 12:00',
    approval_remarks: 'Approved with 6.0 days carry-forward.',
    approvals: [
      {
        id: 1,
        step_number: 1,
        step_name: 'Accrual & Service Computation',
        approver_name: 'Kassahun Belay',
        approver_role: 'HR Operations Officer',
        approval_state: 'approved',
        acted_at: 'Jul 8, 2026, 09:15 AM'
      },
      {
        id: 2,
        step_number: 2,
        step_name: 'Statutory Policy Compliance',
        approver_name: 'Automated Compliance Engine',
        approver_role: 'Rules Validator',
        approval_state: 'approved',
        acted_at: 'Jul 8, 2026, 09:16 AM'
      },
      {
        id: 3,
        step_number: 3,
        step_name: 'Executive HR Authorization',
        approver_name: 'Dawit Mengistu',
        approver_role: 'Director of Human Resources',
        approval_state: 'approved',
        acted_at: 'Jul 9, 2026, 12:00 PM'
      },
      {
        id: 4,
        step_number: 4,
        step_name: 'Active Quota Deployment',
        approver_name: 'Core Leave Ledger',
        approver_role: 'System Ledger Stamping',
        approval_state: 'approved',
        acted_at: 'Jul 9, 2026, 12:00 PM'
      }
    ],
    consumptions: [
      { request_id: 920, request_code: 'ALR-2026-0920', date_range: 'Jul 20, 2026 – Jul 25, 2026', deducted_days: 5.0, request_status: 'Approved' }
    ]
  },
  {
    id: 455,
    uuid: 'lal-455',
    code: 'LAL-2026-0455',
    employee_id: 44,
    employee_name: 'Kassahun Belay',
    employee_code: 'EMP 0044',
    employee_avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&h=120&q=80',
    job_position: 'Branch Head',
    entity_id: 3,
    entity_name: 'Haleta Corporate Headquarters',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    leave_type_code: 'ANNUAL',
    leave_policy_rule_id: 101,
    policy_rule_label: 'POL-OFFICE-2026 • Statutory Annual (+1d/2yr)',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    allocated_days: 22.0,
    carried_forward_days: 10.0,
    total_entitled_days: 32.0,
    taken_days: 2.0,
    available_days: 30.0,
    allocation_state: 'approved',
    notes: 'Branch leadership statutory allocation; 10.0 days rolled over.',
    created_at: '2026-07-08',
    created_by_name: 'Almaz Mengistu (HR Admin)',
    approved_by_name: 'Dawit Mengistu',
    approver_role: 'Director of Human Resources',
    approver_avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&h=120&q=80',
    approved_at: '2026-07-09 13:00',
    approval_remarks: 'Certified branch executive leave allotment.',
    approvals: [
      {
        id: 1,
        step_number: 1,
        step_name: 'Accrual & Service Computation',
        approver_name: 'Almaz Mengistu',
        approver_role: 'HR Admin',
        approval_state: 'approved',
        acted_at: 'Jul 8, 2026, 09:20 AM'
      },
      {
        id: 2,
        step_number: 2,
        step_name: 'Statutory Policy Compliance',
        approver_name: 'Automated Compliance Engine',
        approver_role: 'Rules Validator',
        approval_state: 'approved',
        acted_at: 'Jul 8, 2026, 09:22 AM'
      },
      {
        id: 3,
        step_number: 3,
        step_name: 'Executive HR Authorization',
        approver_name: 'Dawit Mengistu',
        approver_role: 'Director of Human Resources',
        approval_state: 'approved',
        acted_at: 'Jul 9, 2026, 01:00 PM'
      },
      {
        id: 4,
        step_number: 4,
        step_name: 'Active Quota Deployment',
        approver_name: 'Core Leave Ledger',
        approver_role: 'System Ledger Stamping',
        approval_state: 'approved',
        acted_at: 'Jul 9, 2026, 01:00 PM'
      }
    ],
    consumptions: [
      { request_id: 922, request_code: 'ALR-2026-0922', date_range: 'Aug 04, 2026 – Aug 05, 2026', deducted_days: 2.0, request_status: 'Approved' }
    ]
  },
  {
    id: 456,
    uuid: 'lal-456',
    code: 'LAL-2026-0456',
    employee_id: 31,
    employee_name: 'Dawit Yohannes',
    employee_code: 'EMP 0031',
    employee_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&h=120&q=80',
    job_position: 'Logistics Officer',
    entity_id: 9,
    entity_name: 'Bahir Dar Regional Hub',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    leave_type_code: 'ANNUAL',
    leave_policy_rule_id: null,
    policy_rule_label: 'Manual / Ad-Hoc Entitlement Grant',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    allocated_days: 17.0,
    carried_forward_days: 3.0,
    total_entitled_days: 20.0,
    taken_days: 0.0,
    available_days: 20.0,
    allocation_state: 'draft',
    notes: 'Awaiting annual policy verification batch; ad-hoc initial draft.',
    created_at: '2026-08-01',
    created_by_name: 'Kassahun Belay (HR Operations Officer)',
    approvals: [
      {
        id: 1,
        step_number: 1,
        step_name: 'Accrual & Service Computation',
        approver_name: 'Kassahun Belay',
        approver_role: 'HR Operations Officer',
        approval_state: 'approved',
        acted_at: 'Aug 1, 2026, 10:00 AM',
        remarks: 'Ad-hoc initial grant computed pending HR Director sign-off.'
      },
      {
        id: 2,
        step_number: 2,
        step_name: 'Statutory Policy Compliance',
        approver_name: 'Automated Compliance Engine',
        approver_role: 'Rules Validator',
        approval_state: 'approved',
        acted_at: 'Aug 1, 2026, 10:02 AM',
        remarks: 'Service year quota validated.'
      },
      {
        id: 3,
        step_number: 3,
        step_name: 'Executive HR Authorization',
        approver_name: 'Dawit Mengistu',
        approver_role: 'Director of Human Resources',
        approval_state: 'pending',
        acted_at: undefined,
        remarks: undefined
      },
      {
        id: 4,
        step_number: 4,
        step_name: 'Active Quota Deployment',
        approver_name: 'Core Leave Ledger',
        approver_role: 'System Ledger Stamping',
        approval_state: 'queued',
        acted_at: undefined,
        remarks: undefined
      }
    ],
    consumptions: []
  }
]);

// ─── Helpers ───
export const getAllocationById = (id: number): LeaveAllocationRecord | undefined => {
  return allocationsData.value.find(a => a.id === id);
};

export const approveAllocation = (id: number, remarks?: string): boolean => {
  const target = getAllocationById(id);
  if (!target) return false;

  target.allocation_state = 'approved';
  target.approved_by_name = 'Dawit Mengistu';
  target.approver_role = 'Director of Human Resources';
  target.approver_avatar = 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&h=120&q=80';
  target.approved_at = new Date().toISOString().replace('T', ' ').slice(0, 16);
  target.approval_remarks = remarks || 'Statutory entitlement verified and certified by HR Director.';

  if (target.approvals) {
    const step3 = target.approvals.find(s => s.step_number === 3);
    if (step3) {
      step3.approval_state = 'approved';
      step3.acted_at = new Date().toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' });
      step3.remarks = remarks || 'Certified and signed off.';
    }
    const step4 = target.approvals.find(s => s.step_number === 4);
    if (step4) {
      step4.approval_state = 'approved';
      step4.acted_at = new Date().toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' });
      step4.remarks = 'Balance deployed to active ledger.';
    }
  }

  return true;
};

export const rejectAllocation = (id: number, reason?: string): boolean => {
  const target = getAllocationById(id);
  if (!target) return false;

  target.allocation_state = 'cancelled';
  target.approval_remarks = reason || 'Allocation rejected per statutory ceiling review.';

  if (target.approvals) {
    const step3 = target.approvals.find(s => s.step_number === 3);
    if (step3) {
      step3.approval_state = 'rejected';
      step3.acted_at = new Date().toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' });
      step3.remarks = reason || 'Rejected.';
    }
  }

  return true;
};

export const createAllocation = (payload: {
  employee_id: number;
  leave_type_id: number;
  leave_policy_rule_id?: number | null;
  policy_rule_label?: string;
  period_start: string;
  period_end: string;
  allocated_days: number;
  carried_forward_days: number;
  notes?: string;
  isDraft?: boolean;
}): LeaveAllocationRecord => {
  const staff = staffMembers.find(s => s.id === payload.employee_id) || staffMembers[0];
  const newId = 460 + Math.floor(Math.random() * 50);
  const total = Number(payload.allocated_days) + Number(payload.carried_forward_days);

  const newRecord: LeaveAllocationRecord = {
    id: newId,
    uuid: `lal-${newId}`,
    code: `LAL-2026-0${newId}`,
    employee_id: staff.id,
    employee_name: staff.name,
    employee_code: staff.code,
    employee_avatar: staff.avatar,
    job_position: staff.position,
    entity_id: staff.entity_id,
    entity_name: staff.entity_name,
    leave_type_id: payload.leave_type_id,
    leave_type_name: 'Annual Leave',
    leave_type_code: 'ANNUAL',
    leave_policy_rule_id: payload.leave_policy_rule_id || null,
    policy_rule_label: payload.policy_rule_label || 'Manual / Ad-Hoc Entitlement Grant',
    period_start: payload.period_start,
    period_end: payload.period_end,
    allocated_days: Number(payload.allocated_days),
    carried_forward_days: Number(payload.carried_forward_days),
    total_entitled_days: total,
    taken_days: 0.0,
    available_days: total,
    allocation_state: payload.isDraft ? 'draft' : 'approved',
    notes: payload.notes || 'Granted annual quota.',
    created_at: new Date().toISOString().slice(0, 10),
    created_by_name: 'Kassahun Belay (HR Operations Officer)',
    approved_by_name: payload.isDraft ? undefined : 'Dawit Mengistu',
    approver_role: payload.isDraft ? undefined : 'Director of Human Resources',
    approver_avatar: payload.isDraft ? undefined : 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&h=120&q=80',
    approved_at: payload.isDraft ? undefined : new Date().toISOString().replace('T', ' ').slice(0, 16),
    approval_remarks: payload.isDraft ? undefined : 'Certified statutory quota grant.',
    approvals: [
      {
        id: 1,
        step_number: 1,
        step_name: 'Accrual & Service Computation',
        approver_name: 'Kassahun Belay',
        approver_role: 'HR Operations Officer',
        approval_state: 'approved',
        acted_at: new Date().toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' })
      },
      {
        id: 2,
        step_number: 2,
        step_name: 'Statutory Policy Compliance',
        approver_name: 'Automated Compliance Engine',
        approver_role: 'Rules Validator',
        approval_state: 'approved',
        acted_at: new Date().toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' })
      },
      {
        id: 3,
        step_number: 3,
        step_name: 'Executive HR Authorization',
        approver_name: 'Dawit Mengistu',
        approver_role: 'Director of Human Resources',
        approval_state: payload.isDraft ? 'pending' : 'approved',
        acted_at: payload.isDraft ? undefined : new Date().toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' })
      },
      {
        id: 4,
        step_number: 4,
        step_name: 'Active Quota Deployment',
        approver_name: 'Core Leave Ledger',
        approver_role: 'System Ledger Stamping',
        approval_state: payload.isDraft ? 'queued' : 'approved',
        acted_at: payload.isDraft ? undefined : new Date().toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' })
      }
    ],
    consumptions: []
  };

  allocationsData.value.unshift(newRecord);
  return newRecord;
};

export const rescheduleAllocation = (
  allocationId: number, 
  newPeriodStart: string, 
  newPeriodEnd: string, 
  reason: string
): LeaveAllocationRecord | null => {
  const target = getAllocationById(allocationId);
  if (!target) return null;

  // 1. Mark original row as 'rescheduled' (superseded rows are never edited directly per Schema line 1647)
  const nextId = target.id + 100;
  const nextCode = `LAL-2026-0${nextId}`;

  target.allocation_state = 'rescheduled';
  target.reschedule_reason = reason;
  target.rescheduled_to_id = nextId;
  target.rescheduled_to_code = nextCode;

  // 2. Spawn forward-chained allocation row
  const newRow: LeaveAllocationRecord = {
    ...target,
    id: nextId,
    uuid: `lal-${nextId}`,
    code: nextCode,
    period_start: newPeriodStart,
    period_end: newPeriodEnd,
    allocation_state: 'approved',
    rescheduled_from_id: target.id,
    rescheduled_from_code: target.code,
    rescheduled_to_id: null,
    rescheduled_to_code: null,
    reschedule_reason: reason,
    created_at: new Date().toISOString().slice(0, 10),
    approved_at: new Date().toISOString().replace('T', ' ').slice(0, 16),
    approvals: [
      {
        id: 1,
        step_number: 1,
        step_name: 'Forward-Chain Initiation',
        approver_name: 'Kassahun Belay',
        approver_role: 'HR Operations Officer',
        approval_state: 'approved',
        acted_at: new Date().toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' }),
        remarks: `Rescheduled from ${target.code}. Reason: ${reason}`
      },
      {
        id: 2,
        step_number: 2,
        step_name: 'Statutory Deferral Clearance',
        approver_name: 'Automated Compliance Engine',
        approver_role: 'Rules Validator',
        approval_state: 'approved',
        acted_at: new Date().toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' }),
        remarks: 'Approved deferral under operational emergency provision.'
      },
      {
        id: 3,
        step_number: 3,
        step_name: 'Executive HR Authorization',
        approver_name: 'Dawit Mengistu',
        approver_role: 'Director of Human Resources',
        approval_state: 'approved',
        acted_at: new Date().toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' }),
        remarks: `Authorized forward-chain window: ${newPeriodStart} – ${newPeriodEnd}.`
      },
      {
        id: 4,
        step_number: 4,
        step_name: 'Active Quota Deployment',
        approver_name: 'Core Leave Ledger',
        approver_role: 'System Ledger Stamping',
        approval_state: 'approved',
        acted_at: new Date().toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' }),
        remarks: 'Live quota deployed.'
      }
    ]
  };

  allocationsData.value.unshift(newRow);
  return newRow;
};
