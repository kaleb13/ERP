// ─── Overtime Data & Types (Conforming to HR_Schema_final-v4.sql Section 7, Lines 1953–1982) ───
import { ref } from 'vue';

export type OvertimeType = 'normal_day' | 'night' | 'weekend' | 'public_holiday';
export type OvertimeRequestState = 'draft' | 'pending' | 'approved' | 'rejected' | 'cancelled';
export type OvertimeCompensation = 'paid' | 'compensatory_leave';

export interface OvertimeRateInfo {
  multiplier: number;
  label: string;
  description: string;
}

export const OVERTIME_TYPE_MAP: Record<OvertimeType, OvertimeRateInfo> = {
  normal_day: {
    multiplier: 1.25,
    label: 'Normal Working Day (1.25×)',
    description: 'Work performed in excess of 8 standard daily hours on regular workdays.'
  },
  night: {
    multiplier: 1.5,
    label: 'Night Shift Work (1.50×)',
    description: 'Work performed between 22:00 (10 PM) and 06:00 (6 AM) per Ethiopian Labour Proclamation.'
  },
  weekend: {
    multiplier: 2.0,
    label: 'Weekly Rest / Weekend (2.00×)',
    description: 'Work performed on an employee’s rostered weekly rest day (Saturday afternoon / Sunday).'
  },
  public_holiday: {
    multiplier: 2.5,
    label: 'Statutory Public Holiday (2.50×)',
    description: 'Work performed on designated national or statutory religious holidays.'
  }
};

export interface OvertimeRequestRecord {
  id: number;
  uuid: string;
  code: string;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_role: string;
  entity_id: number;
  entity_name: string;
  date: string;
  attendance_day_id?: number | null;
  overtime_type: OvertimeType;
  request_state: OvertimeRequestState;
  start_at: string;
  end_at: string;
  requested_minutes: number;
  approved_minutes?: number | null;
  compensation: OvertimeCompensation;
  reason?: string;
  approver_employee_id?: number | null;
  approver_name?: string | null;
  approved_at?: string | null;
  state: 'active' | 'inactive';
}

// ─── Initial Dataset Seed (Schema Lines 1976–1982) ───
const initialOvertimeRequests: OvertimeRequestRecord[] = [
  {
    id: 221,
    uuid: 'ot-req-2026-0221',
    code: 'OT-2026-0221',
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-014',
    employee_role: 'Senior Accountant',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    date: '2026-07-26',
    attendance_day_id: 810225,
    overtime_type: 'weekend',
    request_state: 'approved',
    start_at: '2026-07-26T09:00:00Z',
    end_at: '2026-07-26T11:00:00Z',
    requested_minutes: 120,
    approved_minutes: 120,
    compensation: 'paid',
    reason: 'Fiscal year-end closing audit voucher reconciliations and ledger closing.',
    approver_employee_id: 7,
    approver_name: 'Tewodros Kassahun',
    approved_at: '2026-07-27T08:15:00Z',
    state: 'active'
  },
  {
    id: 222,
    uuid: 'ot-req-2026-0222',
    code: 'OT-2026-0222',
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-014',
    employee_role: 'Senior Accountant',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    date: '2026-07-20',
    attendance_day_id: 810202,
    overtime_type: 'normal_day',
    request_state: 'approved',
    start_at: '2026-07-20T17:30:00Z',
    end_at: '2026-07-20T19:00:00Z',
    requested_minutes: 90,
    approved_minutes: 60,
    compensation: 'paid',
    reason: 'Urgent supplier bank transfer execution for branch logistics.',
    approver_employee_id: 7,
    approver_name: 'Tewodros Kassahun',
    approved_at: '2026-07-21T09:30:00Z',
    state: 'active'
  },
  {
    id: 223,
    uuid: 'ot-req-2026-0223',
    code: 'OT-2026-0223',
    employee_id: 31,
    employee_name: 'Ephrem Tadesse',
    employee_code: 'EMP-031',
    employee_role: 'Operations Analyst',
    entity_id: 7,
    entity_name: 'Bahir Dar Hub',
    date: '2026-07-27',
    attendance_day_id: 810223,
    overtime_type: 'night',
    request_state: 'pending',
    start_at: '2026-07-27T22:00:00Z',
    end_at: '2026-07-28T01:00:00Z',
    requested_minutes: 180,
    approved_minutes: null,
    compensation: 'compensatory_leave',
    reason: 'Overnight systems batch reconciliation and database index maintenance.',
    approver_employee_id: null,
    approver_name: null,
    approved_at: null,
    state: 'active'
  },
  {
    id: 224,
    uuid: 'ot-req-2026-0224',
    code: 'OT-2026-0224',
    employee_id: 22,
    employee_name: 'Bethlehem Haile',
    employee_code: 'EMP-022',
    employee_role: 'Inventory Controller',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    date: '2026-09-11',
    attendance_day_id: null,
    overtime_type: 'public_holiday',
    request_state: 'draft',
    start_at: '2026-09-11T08:00:00Z',
    end_at: '2026-09-11T12:00:00Z',
    requested_minutes: 240,
    approved_minutes: null,
    compensation: 'paid',
    reason: 'Ethiopian New Year (Enkutatash) emergency warehouse logistics dispatch.',
    approver_employee_id: null,
    approver_name: null,
    approved_at: null,
    state: 'active'
  },
  {
    id: 225,
    uuid: 'ot-req-2026-0225',
    code: 'OT-2026-0225',
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-014',
    employee_role: 'Senior Accountant',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    date: '2026-07-13',
    attendance_day_id: 810190,
    overtime_type: 'weekend',
    request_state: 'rejected',
    start_at: '2026-07-13T10:00:00Z',
    end_at: '2026-07-13T14:00:00Z',
    requested_minutes: 240,
    approved_minutes: null,
    compensation: 'paid',
    reason: 'Unscheduled Sunday audit check (rejected due to prior compensatory rest credit).',
    approver_employee_id: 7,
    approver_name: 'Tewodros Kassahun',
    approved_at: '2026-07-14T11:00:00Z',
    state: 'active'
  }
];

export const overtimeRequestsData = ref<OvertimeRequestRecord[]>([...initialOvertimeRequests]);

export const createOvertimeRequest = (payload: Omit<OvertimeRequestRecord, 'id' | 'uuid' | 'code' | 'state'>): OvertimeRequestRecord => {
  const newId = Date.now();
  const sequenceNum = String(overtimeRequestsData.value.length + 1).padStart(4, '0');
  const newRecord: OvertimeRequestRecord = {
    ...payload,
    id: newId,
    uuid: `ot-req-2026-${sequenceNum}`,
    code: `OT-2026-${sequenceNum}`,
    state: 'active'
  };
  overtimeRequestsData.value.unshift(newRecord);
  return newRecord;
};

export const updateOvertimeStatus = (
  id: number,
  status: OvertimeRequestState,
  approvedMinutes?: number,
  compensation?: OvertimeCompensation,
  approverId = 7,
  approverName = 'Tewodros Kassahun'
) => {
  const item = overtimeRequestsData.value.find(r => r.id === id);
  if (item) {
    item.request_state = status;
    if (status === 'approved') {
      item.approved_minutes = approvedMinutes !== undefined ? approvedMinutes : item.requested_minutes;
      if (compensation) item.compensation = compensation;
      item.approver_employee_id = approverId;
      item.approver_name = approverName;
      item.approved_at = new Date().toISOString();
    } else if (status === 'rejected') {
      item.approved_minutes = null;
      item.approver_employee_id = approverId;
      item.approver_name = approverName;
      item.approved_at = new Date().toISOString();
    }
  }
};
