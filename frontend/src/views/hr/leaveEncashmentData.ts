import { ref } from 'vue';

// ─── Approval Step Interface ───
export interface ApprovalStep {
  id: number;
  step_number: number;
  step_name: string;
  approver_name: string;
  approver_role: string;
  approval_state: 'approved' | 'pending' | 'queued' | 'rejected';
  acted_at?: string;
  remarks?: string;
}

// ─── Schema-Aligned Datasets: LeaveEncashmentRequest [DIST] (HR Schema lines 1785–1812) ───
export interface LeaveEncashmentRecord {
  id: number;
  uuid: string;
  code: string;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_avatar: string;
  job_position: string;
  department: string;
  entity_id: number;
  entity_name: string;
  hire_date: string;
  service_years: number;
  bank_name: string;
  bank_account: string;
  leave_type_id: number;
  leave_type_name: string;
  leave_allocation_id: number;
  allocation_code: string;
  period_start: string;
  period_end: string;
  total_entitled_days: number;
  taken_days: number;
  available_balance_before: number;
  requested_days: number;
  approved_days: number | null;
  daily_rate: number;
  amount: number;
  currency: string;
  basic_salary: number;
  payroll_days_basis: number;
  reason: string;
  request_state: 'draft' | 'pending' | 'approved' | 'rejected' | 'cancelled';
  state: 'active' | 'inactive';
  approver_name?: string;
  approver_role?: string;
  approved_at?: string;
  approval_remarks?: string;
  leave_transaction_id?: string;
  payroll_settlement_month: string;
  is_synced_to_payroll: boolean;
  created_at: string;
  approvals: ApprovalStep[];
}

// ─── Staff Dossiers with Quota Buckets for Creation ───
export interface StaffQuotaContext {
  id: number;
  name: string;
  code: string;
  position: string;
  department: string;
  entity_id: number;
  entity_name: string;
  hire_date: string;
  service_years: number;
  basic_salary: number;
  payroll_days: number;
  bank_name: string;
  bank_account: string;
  allocation_id: number;
  allocation_code: string;
  period_start: string;
  period_end: string;
  total_entitled_days: number;
  taken_days: number;
  available_days: number;
  avatar: string;
}

export const staffList: StaffQuotaContext[] = [
  { 
    id: 124, 
    name: 'Almaz Kebede', 
    code: 'EMP-00124', 
    position: 'Senior Accountant', 
    department: 'Finance & Accounts',
    entity_id: 3, 
    entity_name: 'Haleta Corporate Headquarters',
    hire_date: '2022-09-01', 
    service_years: 4, 
    basic_salary: 16500.00,
    payroll_days: 26,
    bank_name: 'Commercial Bank of Ethiopia (CBE)',
    bank_account: '1000293847561',
    allocation_id: 450, 
    allocation_code: 'LAL-2026-0450',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    total_entitled_days: 18.0,
    taken_days: 2.5,
    available_days: 15.5,
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=120&h=120&q=80' 
  },
  { 
    id: 14, 
    name: 'Abebe Kebede', 
    code: 'EMP 0014', 
    position: 'Senior Cashier', 
    department: 'Commercial Retail',
    entity_id: 7, 
    entity_name: 'Bole Commercial Branch',
    hire_date: '2024-06-01', 
    service_years: 2, 
    basic_salary: 6500.00,
    payroll_days: 26,
    bank_name: 'Commercial Bank of Ethiopia (CBE)',
    bank_account: '1000293847561',
    allocation_id: 453, 
    allocation_code: 'LAL-2026-0453',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    total_entitled_days: 18.0,
    taken_days: 2.0,
    available_days: 16.0,
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&h=120&q=80' 
  },
  { 
    id: 22, 
    name: 'Tigist Assefa', 
    code: 'EMP 0124', 
    position: 'Senior Accountant', 
    department: 'Finance & Accounts',
    entity_id: 3, 
    entity_name: 'Haleta Corporate Headquarters',
    hire_date: '2021-09-15', 
    service_years: 5, 
    basic_salary: 12000.00,
    payroll_days: 26,
    bank_name: 'Awash International Bank',
    bank_account: '01304928172600',
    allocation_id: 454, 
    allocation_code: 'LAL-2026-0454',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    total_entitled_days: 27.0,
    taken_days: 5.0,
    available_days: 22.0,
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=120&h=120&q=80' 
  },
  { 
    id: 31, 
    name: 'Dawit Yohannes', 
    code: 'EMP 0031', 
    position: 'Logistics Officer', 
    department: 'Operations & Supply',
    entity_id: 9, 
    entity_name: 'Bahir Dar Regional Hub',
    hire_date: '2025-02-17', 
    service_years: 1, 
    basic_salary: 8000.00,
    payroll_days: 26,
    bank_name: 'Commercial Bank of Ethiopia (CBE)',
    bank_account: '1000987654321',
    allocation_id: 456, 
    allocation_code: 'LAL-2026-0456',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    total_entitled_days: 17.0,
    taken_days: 3.0,
    available_days: 14.0,
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&h=120&q=80' 
  },
  { 
    id: 44, 
    name: 'Kassahun Belay', 
    code: 'EMP 0044', 
    position: 'Branch Head', 
    department: 'Branch Administration',
    entity_id: 3, 
    entity_name: 'Haleta Corporate Headquarters',
    hire_date: '2020-03-02', 
    service_years: 6, 
    basic_salary: 18000.00,
    payroll_days: 26,
    bank_name: 'Dashen Bank',
    bank_account: '5120394857102',
    allocation_id: 455, 
    allocation_code: 'LAL-2026-0455',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    total_entitled_days: 32.0,
    taken_days: 2.0,
    available_days: 30.0,
    avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&h=120&q=80' 
  },
  { 
    id: 7, 
    name: 'Marta Tadesse', 
    code: 'EMP 0007', 
    position: 'Branch Manager', 
    department: 'Executive Governance',
    entity_id: 3, 
    entity_name: 'Haleta Corporate Headquarters',
    hire_date: '2022-01-10', 
    service_years: 4, 
    basic_salary: 22000.00,
    payroll_days: 26,
    bank_name: 'Commercial Bank of Ethiopia (CBE)',
    bank_account: '1000543216789',
    allocation_id: 452, 
    allocation_code: 'LAL-2026-0452',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    total_entitled_days: 44.0,
    taken_days: 3.0,
    available_days: 41.0,
    avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80' 
  },
  { 
    id: 18, 
    name: 'Kidst Tesfaye', 
    code: 'EMP 0018', 
    position: 'Customer Support Lead', 
    department: 'Client Experience',
    entity_id: 7, 
    entity_name: 'Bole Commercial Branch',
    hire_date: '2023-04-12', 
    service_years: 3, 
    basic_salary: 9000.00,
    payroll_days: 26,
    bank_name: 'Hibret Bank',
    bank_account: '29384756102',
    allocation_id: 457, 
    allocation_code: 'LAL-2026-0457',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    total_entitled_days: 18.0,
    taken_days: 6.0,
    available_days: 12.0,
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&h=120&q=80' 
  }
];

// ─── Global Reactive Store for Encashments ───
export const encashmentsData = ref<LeaveEncashmentRecord[]>([
  {
    id: 1,
    uuid: 'len-0001',
    code: 'LEN-2026-0001',
    employee_id: 22,
    employee_name: 'Tigist Assefa',
    employee_code: 'EMP 0124',
    employee_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=120&h=120&q=80',
    job_position: 'Senior Accountant',
    department: 'Finance & Accounts',
    entity_id: 3,
    entity_name: 'Haleta Corporate Headquarters',
    hire_date: '2021-09-15',
    service_years: 5,
    bank_name: 'Awash International Bank',
    bank_account: '01304928172600',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    leave_allocation_id: 454,
    allocation_code: 'LAL-2026-0454',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    total_entitled_days: 27.0,
    taken_days: 5.0,
    requested_days: 10.0,
    approved_days: 10.0,
    daily_rate: 461.54,
    amount: 4615.40,
    currency: 'ETB',
    basic_salary: 12000.00,
    payroll_days_basis: 26,
    available_balance_before: 22.0,
    reason: 'End-of-fiscal-year statutory cash encashment of surplus annual leave quota.',
    request_state: 'approved',
    state: 'active',
    approver_name: 'Marta Tadesse',
    approver_role: 'Financial Controller',
    approved_at: '2026-07-28 10:15',
    approval_remarks: 'Verified against WorkCalendar 26-day basis. Approved statutory payout and authorized quota ledger debit.',
    leave_transaction_id: 'LTR-2026-12004',
    payroll_settlement_month: 'July 2026 Payroll',
    is_synced_to_payroll: true,
    created_at: '2026-07-25',
    approvals: [
      {
        id: 701,
        step_number: 1,
        step_name: 'Encashment Request Submission',
        approver_name: 'Tigist Assefa',
        approver_role: 'Senior Accountant (Requester)',
        approval_state: 'approved',
        acted_at: 'Jul 25, 2026, 09:30 AM',
        remarks: 'Submitted request for 10.0 days surplus annual quota.'
      },
      {
        id: 702,
        step_number: 2,
        step_name: 'Line Manager Endorsement',
        approver_name: 'Yonas Gebre',
        approver_role: 'Finance Operations Director',
        approval_state: 'approved',
        acted_at: 'Jul 26, 2026, 11:20 AM',
        remarks: 'Work deliverables covered. Recommended for cash conversion.'
      },
      {
        id: 703,
        step_number: 3,
        step_name: 'Finance & Payroll Authorization',
        approver_name: 'Marta Tadesse',
        approver_role: 'Financial Controller',
        approval_state: 'approved',
        acted_at: 'Jul 28, 2026, 10:15 AM',
        remarks: 'Daily rate ETB 461.54 frozen. Signed debit row LTR-2026-12004 generated.'
      }
    ]
  },
  {
    id: 2,
    uuid: 'len-0002',
    code: 'LEN-2026-0002',
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP 0014',
    employee_avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&h=120&q=80',
    job_position: 'Senior Cashier',
    department: 'Commercial Retail',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    hire_date: '2024-06-01',
    service_years: 2,
    bank_name: 'Commercial Bank of Ethiopia (CBE)',
    bank_account: '1000293847561',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    leave_allocation_id: 453,
    allocation_code: 'LAL-2026-0453',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    total_entitled_days: 18.0,
    taken_days: 2.0,
    requested_days: 5.0,
    approved_days: null,
    daily_rate: 250.00,
    amount: 1250.00,
    currency: 'ETB',
    basic_salary: 6500.00,
    payroll_days_basis: 26,
    available_balance_before: 16.0,
    reason: 'Family financial requirements; requesting partial encashment of unutilized annual leave days.',
    request_state: 'pending',
    state: 'active',
    payroll_settlement_month: 'August 2026 Payroll',
    is_synced_to_payroll: false,
    created_at: '2026-08-01',
    approvals: [
      {
        id: 704,
        step_number: 1,
        step_name: 'Encashment Request Submission',
        approver_name: 'Abebe Kebede',
        approver_role: 'Senior Cashier (Requester)',
        approval_state: 'approved',
        acted_at: 'Aug 1, 2026, 08:45 AM',
        remarks: 'Submitted request for 5.0 days encashment.'
      },
      {
        id: 705,
        step_number: 2,
        step_name: 'Branch Manager Endorsement',
        approver_name: 'Sara Tefera',
        approver_role: 'Shift Supervisor',
        approval_state: 'approved',
        acted_at: 'Aug 1, 2026, 02:30 PM',
        remarks: 'Cashier staffing capacity verified. Endorsed for approval.'
      },
      {
        id: 706,
        step_number: 3,
        step_name: 'Finance & Payroll Authorization',
        approver_name: 'Marta Tadesse',
        approver_role: 'Financial Controller',
        approval_state: 'pending',
        acted_at: undefined,
        remarks: undefined
      }
    ]
  },
  {
    id: 3,
    uuid: 'len-0003',
    code: 'LEN-2026-0003',
    employee_id: 44,
    employee_name: 'Kassahun Belay',
    employee_code: 'EMP 0044',
    employee_avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&h=120&q=80',
    job_position: 'Branch Head',
    department: 'Branch Administration',
    entity_id: 3,
    entity_name: 'Haleta Corporate Headquarters',
    hire_date: '2020-03-02',
    service_years: 6,
    bank_name: 'Dashen Bank',
    bank_account: '5120394857102',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    leave_allocation_id: 455,
    allocation_code: 'LAL-2026-0455',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    total_entitled_days: 32.0,
    taken_days: 2.0,
    requested_days: 8.0,
    approved_days: 8.0,
    daily_rate: 692.31,
    amount: 5538.48,
    currency: 'ETB',
    basic_salary: 18000.00,
    payroll_days_basis: 26,
    available_balance_before: 30.0,
    reason: 'Operational exigencies prevented taking scheduled leave; statutory payout authorized.',
    request_state: 'approved',
    state: 'active',
    approver_name: 'Yonas Gebre',
    approver_role: 'HR Executive Director',
    approved_at: '2026-08-02 14:30',
    approval_remarks: 'Authorized per executive retention provision. Debited 8.0 days from allocation bucket.',
    leave_transaction_id: 'LTR-2026-12008',
    payroll_settlement_month: 'August 2026 Payroll',
    is_synced_to_payroll: true,
    created_at: '2026-07-29',
    approvals: [
      {
        id: 707,
        step_number: 1,
        step_name: 'Encashment Request Submission',
        approver_name: 'Kassahun Belay',
        approver_role: 'Branch Head (Requester)',
        approval_state: 'approved',
        acted_at: 'Jul 29, 2026, 10:00 AM'
      },
      {
        id: 708,
        step_number: 2,
        step_name: 'Executive Leadership Endorsement',
        approver_name: 'Yonas Gebre',
        approver_role: 'HR Executive Director',
        approval_state: 'approved',
        acted_at: 'Aug 2, 2026, 02:30 PM',
        remarks: 'Executive authorization granted.'
      }
    ]
  },
  {
    id: 4,
    uuid: 'len-0004',
    code: 'LEN-2026-0004',
    employee_id: 31,
    employee_name: 'Dawit Yohannes',
    employee_code: 'EMP 0031',
    employee_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&h=120&q=80',
    job_position: 'Logistics Officer',
    department: 'Operations & Supply',
    entity_id: 9,
    entity_name: 'Bahir Dar Regional Hub',
    hire_date: '2025-02-17',
    service_years: 1,
    bank_name: 'Commercial Bank of Ethiopia (CBE)',
    bank_account: '1000987654321',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    leave_allocation_id: 456,
    allocation_code: 'LAL-2026-0456',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    total_entitled_days: 17.0,
    taken_days: 3.0,
    requested_days: 4.0,
    approved_days: null,
    daily_rate: 307.69,
    amount: 1230.76,
    currency: 'ETB',
    basic_salary: 8000.00,
    payroll_days_basis: 26,
    available_balance_before: 14.0,
    reason: 'Emergency travel expenses compensation.',
    request_state: 'pending',
    state: 'active',
    payroll_settlement_month: 'August 2026 Payroll',
    is_synced_to_payroll: false,
    created_at: '2026-08-03',
    approvals: [
      {
        id: 709,
        step_number: 1,
        step_name: 'Encashment Request Submission',
        approver_name: 'Dawit Yohannes',
        approver_role: 'Logistics Officer',
        approval_state: 'approved',
        acted_at: 'Aug 3, 2026, 09:15 AM'
      },
      {
        id: 710,
        step_number: 2,
        step_name: 'Regional Operations Endorsement',
        approver_name: 'Marta Tadesse',
        approver_role: 'Operations Lead',
        approval_state: 'pending',
        acted_at: undefined
      }
    ]
  },
  {
    id: 5,
    uuid: 'len-0005',
    code: 'LEN-2026-0005',
    employee_id: 7,
    employee_name: 'Marta Tadesse',
    employee_code: 'EMP 0007',
    employee_avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80',
    job_position: 'Branch Manager',
    department: 'Executive Governance',
    entity_id: 3,
    entity_name: 'Haleta Corporate Headquarters',
    hire_date: '2022-01-10',
    service_years: 4,
    bank_name: 'Commercial Bank of Ethiopia (CBE)',
    bank_account: '1000543216789',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    leave_allocation_id: 452,
    allocation_code: 'LAL-2026-0452',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    total_entitled_days: 44.0,
    taken_days: 3.0,
    requested_days: 12.0,
    approved_days: null,
    daily_rate: 846.15,
    amount: 10153.80,
    currency: 'ETB',
    basic_salary: 22000.00,
    payroll_days_basis: 26,
    available_balance_before: 41.0,
    reason: 'Unutilized leave from previous service cycle.',
    request_state: 'draft',
    state: 'active',
    payroll_settlement_month: 'September 2026 Payroll',
    is_synced_to_payroll: false,
    created_at: '2026-08-05',
    approvals: [
      {
        id: 711,
        step_number: 1,
        step_name: 'Draft Request',
        approver_name: 'Marta Tadesse',
        approver_role: 'Branch Manager',
        approval_state: 'pending',
        remarks: 'Draft pending final submission.'
      }
    ]
  },
  {
    id: 6,
    uuid: 'len-0006',
    code: 'LEN-2026-0006',
    employee_id: 18,
    employee_name: 'Kidst Tesfaye',
    employee_code: 'EMP 0018',
    employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&h=120&q=80',
    job_position: 'Customer Support Lead',
    department: 'Client Experience',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    hire_date: '2023-04-12',
    service_years: 3,
    bank_name: 'Hibret Bank',
    bank_account: '29384756102',
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    leave_allocation_id: 457,
    allocation_code: 'LAL-2026-0457',
    period_start: '2026-07-08',
    period_end: '2027-07-07',
    total_entitled_days: 18.0,
    taken_days: 6.0,
    requested_days: 6.0,
    approved_days: null,
    daily_rate: 346.15,
    amount: 2076.90,
    currency: 'ETB',
    basic_salary: 9000.00,
    payroll_days_basis: 26,
    available_balance_before: 12.0,
    reason: 'Exceeded maximum permitted annual encashment quota ceiling.',
    request_state: 'rejected',
    state: 'inactive',
    approver_name: 'Marta Tadesse',
    approver_role: 'Financial Controller',
    approval_remarks: 'Exceeds maximum allowable encashment limit under company policy (ceiling 5.0 days per service year).',
    payroll_settlement_month: 'August 2026 Payroll',
    is_synced_to_payroll: false,
    created_at: '2026-07-20',
    approvals: [
      {
        id: 712,
        step_number: 1,
        step_name: 'Encashment Request Submission',
        approver_name: 'Kidst Tesfaye',
        approver_role: 'Customer Support Lead',
        approval_state: 'approved',
        acted_at: 'Jul 20, 2026, 09:00 AM'
      },
      {
        id: 713,
        step_number: 2,
        step_name: 'Finance & Payroll Authorization',
        approver_name: 'Marta Tadesse',
        approver_role: 'Financial Controller',
        approval_state: 'rejected',
        acted_at: 'Jul 21, 2026, 04:00 PM',
        remarks: 'Policy limit exceeded. Employee encouraged to schedule rest days instead.'
      }
    ]
  }
]);

// ─── Store Actions ───
export const getEncashmentById = (id: number): LeaveEncashmentRecord | undefined => {
  return encashmentsData.value.find(e => e.id === id);
};

export const createEncashment = (payload: {
  employee_id: number;
  requested_days: number;
  reason: string;
  payroll_period?: string;
  isDraft?: boolean;
}): LeaveEncashmentRecord => {
  const staff = staffList.find(s => s.id === payload.employee_id) || staffList[0];
  const newId = encashmentsData.value.length > 0 
    ? Math.max(...encashmentsData.value.map(e => e.id)) + 1 
    : 1;

  const dailyRate = Number((staff.basic_salary / staff.payroll_days).toFixed(4));
  const amount = Number((dailyRate * payload.requested_days).toFixed(2));
  const code = `LEN-2026-${String(newId).padStart(4, '0')}`;
  const requestState = payload.isDraft ? 'draft' : 'pending';

  const newRecord: LeaveEncashmentRecord = {
    id: newId,
    uuid: `len-${String(newId).padStart(4, '0')}`,
    code,
    employee_id: staff.id,
    employee_name: staff.name,
    employee_code: staff.code,
    employee_avatar: staff.avatar,
    job_position: staff.position,
    department: staff.department,
    entity_id: staff.entity_id,
    entity_name: staff.entity_name,
    hire_date: staff.hire_date,
    service_years: staff.service_years,
    bank_name: staff.bank_name,
    bank_account: staff.bank_account,
    leave_type_id: 1,
    leave_type_name: 'Annual Leave',
    leave_allocation_id: staff.allocation_id,
    allocation_code: staff.allocation_code,
    period_start: staff.period_start,
    period_end: staff.period_end,
    total_entitled_days: staff.total_entitled_days,
    taken_days: staff.taken_days,
    available_balance_before: staff.available_days,
    requested_days: Number(payload.requested_days),
    approved_days: null,
    daily_rate: dailyRate,
    amount,
    currency: 'ETB',
    basic_salary: staff.basic_salary,
    payroll_days_basis: staff.payroll_days,
    reason: payload.reason || 'Statutory in-service annual leave quota cash encashment request.',
    request_state: requestState,
    state: 'active',
    payroll_settlement_month: payload.payroll_period ? `${payload.payroll_period} Payroll` : 'August 2026 Payroll',
    is_synced_to_payroll: false,
    created_at: new Date().toISOString().slice(0, 10),
    approvals: [
      {
        id: Date.now() + 1,
        step_number: 1,
        step_name: 'Encashment Request Submission',
        approver_name: staff.name,
        approver_role: `${staff.position} (Requester)`,
        approval_state: 'approved',
        acted_at: 'Just now',
        remarks: payload.isDraft ? 'Draft saved.' : `Submitted for ${payload.requested_days} days encashment.`
      },
      {
        id: Date.now() + 2,
        step_number: 2,
        step_name: 'Line Manager Endorsement',
        approver_name: 'Sara Tefera',
        approver_role: 'Operations Supervisor',
        approval_state: payload.isDraft ? 'queued' : 'approved',
        acted_at: payload.isDraft ? undefined : 'Just now',
        remarks: payload.isDraft ? undefined : 'Quota balance and department workload confirmed.'
      },
      {
        id: Date.now() + 3,
        step_number: 3,
        step_name: 'Finance & Payroll Authorization',
        approver_name: 'Marta Tadesse',
        approver_role: 'Financial Controller',
        approval_state: payload.isDraft ? 'queued' : 'pending',
        acted_at: undefined,
        remarks: undefined
      }
    ]
  };

  encashmentsData.value.unshift(newRecord);
  return newRecord;
};

export const submitApprovalDecision = (
  id: number,
  resolution: 'approve' | 'modify' | 'reject',
  approvedDays: number,
  remarks: string
): boolean => {
  const item = encashmentsData.value.find(e => e.id === id);
  if (!item) return false;

  const nowStr = new Date().toISOString().slice(0, 16).replace('T', ' ');

  // Find active pending step
  const pendingStep = item.approvals.find(s => s.approval_state === 'pending');

  if (resolution === 'reject') {
    if (pendingStep) {
      pendingStep.approval_state = 'rejected';
      pendingStep.acted_at = nowStr;
      pendingStep.remarks = remarks || 'Request rejected per operational or policy ceiling review.';
    }
    item.request_state = 'rejected';
    item.approval_remarks = remarks || 'Encashment request rejected.';
    item.approver_name = 'Marta Tadesse';
    item.approver_role = 'Financial Controller';
    item.approved_at = nowStr;
  } else {
    const finalDays = resolution === 'modify' ? Number(approvedDays) : item.requested_days;
    item.approved_days = finalDays;
    item.amount = Number((item.daily_rate * finalDays).toFixed(2));
    item.request_state = 'approved';
    item.approver_name = 'Marta Tadesse';
    item.approver_role = 'Financial Controller';
    item.approved_at = nowStr;
    item.approval_remarks = remarks || (resolution === 'modify' 
      ? `Approved with adjusted quota: ${finalDays} days.` 
      : 'Authorized statutory payout. Frozen daily rate confirmed.');
    item.leave_transaction_id = `LTR-2026-${String(Math.floor(10000 + Math.random() * 90000))}`;
    item.is_synced_to_payroll = true;

    if (pendingStep) {
      pendingStep.approval_state = 'approved';
      pendingStep.acted_at = nowStr;
      pendingStep.remarks = item.approval_remarks;
    }

    // Advance any queued steps
    const nextQueued = item.approvals.find(s => s.approval_state === 'queued');
    if (nextQueued) {
      nextQueued.approval_state = 'approved';
      nextQueued.acted_at = nowStr;
    }
  }

  return true;
};

export const cancelEncashment = (id: number): boolean => {
  const item = encashmentsData.value.find(e => e.id === id);
  if (!item) return false;
  item.request_state = 'cancelled';
  return true;
};
