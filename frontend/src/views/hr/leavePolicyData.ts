import { ref } from 'vue';

// ─── LeaveType [REF] (Schema lines 1553–1575) ───
export interface LeaveTypeRecord {
  id: number;
  uuid: string;
  code: string;
  name: string;
  description: string;
  entity_id?: number | null;
  is_paid: boolean;
  requires_attachment: boolean;
  affects_attendance: boolean;
  icon_name?: string;
  state: 'active' | 'inactive';
  created_at: string;
}

// ─── LeavePolicyRule [LINE] (Schema lines 1598–1631) ───
export interface LeavePolicyRuleRecord {
  id: number;
  uuid: string;
  leave_policy_id: number;
  leave_type_id: number;
  leave_type_name: string;
  leave_type_code: string;
  pay_percent: number; // 100, 50, 0
  accrual_method: 'annual_grant' | 'monthly_accrual' | 'per_service_year' | 'fixed';
  days_per_year: number; // 16.0 statutory minimum for annual
  extra_days_per_service_year: number; // +1.0
  max_days: number; // 30.0 cap
  min_service_months: number;
  max_carry_forward_days: number; // e.g. 10.0
  carry_forward_expiry_months: number; // e.g. 24
  allow_negative_balance: boolean;
  allow_encashment: boolean;
  requires_attachment: boolean;
  allow_half_day: boolean;
  rounding: 'none' | 'half_day' | 'full_day';
  gender?: 'male' | 'female' | null;
  notice_days: number;
  max_splits_per_year?: number | null;
  state: 'active' | 'inactive';
}

// ─── LeavePolicy [DIST] (Schema lines 1576–1597) ───
export interface LeavePolicyRecord {
  id: number;
  uuid: string;
  code: string;
  name: string;
  description: string;
  entity_id: number;
  entity_name: string;
  work_calendar_id: number;
  work_calendar_name: string;
  calendar_weekly_hours: number;
  effective_from: string;
  effective_to?: string | null;
  state: 'active' | 'inactive';
  created_at: string;
  rules_count: number;
  rules: LeavePolicyRuleRecord[];
}

// ─── Seed Data: Leave Types (Schema lines 1568–1574) ───
export const leaveTypesData = ref<LeaveTypeRecord[]>([
  {
    id: 1,
    uuid: 'typ-001',
    code: 'ANNUAL',
    name: 'Annual Leave',
    description: 'Statutory annual rest leave with full pay compensation.',
    is_paid: true,
    requires_attachment: false,
    affects_attendance: true,
    icon_name: 'Calendar',
    state: 'active',
    created_at: '2026-07-08'
  },
  {
    id: 2,
    uuid: 'typ-002',
    code: 'SICK',
    name: 'Sick Leave',
    description: 'Medical and hospitalization absence with statutory certificate requirement.',
    is_paid: true,
    requires_attachment: true,
    affects_attendance: true,
    icon_name: 'Activity',
    state: 'active',
    created_at: '2026-07-08'
  },
  {
    id: 3,
    uuid: 'typ-003',
    code: 'MATERNITY',
    name: 'Maternity Leave',
    description: 'Prenatal and postnatal statutory leave for female staff (120 calendar days).',
    is_paid: true,
    requires_attachment: true,
    affects_attendance: true,
    icon_name: 'Heart',
    state: 'active',
    created_at: '2026-07-08'
  },
  {
    id: 4,
    uuid: 'typ-004',
    code: 'PATERNITY',
    name: 'Paternity Leave',
    description: 'Statutory paid leave for male staff upon childbirth.',
    is_paid: true,
    requires_attachment: false,
    affects_attendance: true,
    icon_name: 'UserCheck',
    state: 'active',
    created_at: '2026-07-08'
  },
  {
    id: 5,
    uuid: 'typ-005',
    code: 'BEREAVEMENT',
    name: 'Bereavement Leave',
    description: 'Compassionate leave for family loss and funeral ceremonies.',
    is_paid: true,
    requires_attachment: false,
    affects_attendance: true,
    icon_name: 'Users',
    state: 'active',
    created_at: '2026-07-08'
  },
  {
    id: 6,
    uuid: 'typ-006',
    code: 'STUDY',
    name: 'Study & Exam Leave',
    description: 'Authorized absence for recognized academic examinations.',
    is_paid: true,
    requires_attachment: true,
    affects_attendance: true,
    icon_name: 'GraduationCap',
    state: 'active',
    created_at: '2026-07-08'
  },
  {
    id: 7,
    uuid: 'typ-007',
    code: 'UNPAID',
    name: 'Unpaid Leave',
    description: 'Authorized absence without basic salary or benefit compensation.',
    is_paid: false,
    requires_attachment: false,
    affects_attendance: true,
    icon_name: 'Clock',
    state: 'active',
    created_at: '2026-07-08'
  }
]);

// ─── Seed Data: Leave Policies & Embedded Rules (Schema lines 1590–1630) ───
export const leavePoliciesData = ref<LeavePolicyRecord[]>([
  {
    id: 1,
    uuid: 'pol-001',
    code: 'POL-OFFICE-2026',
    name: 'Office Policy 2026',
    description: 'Standard working rulebook for Corporate Headquarters and administrative staff on 40-hour office week.',
    entity_id: 3,
    entity_name: 'Haleta Corporate Headquarters',
    work_calendar_id: 1,
    work_calendar_name: 'CAL-OFFICE (40h Week • 26d Divisor)',
    calendar_weekly_hours: 40.0,
    effective_from: '2026-07-08',
    effective_to: null,
    state: 'active',
    created_at: '2026-07-08',
    rules_count: 5,
    rules: [
      {
        id: 101,
        uuid: 'rul-101',
        leave_policy_id: 1,
        leave_type_id: 1,
        leave_type_name: 'Annual Leave',
        leave_type_code: 'ANNUAL',
        pay_percent: 100.0,
        accrual_method: 'per_service_year',
        days_per_year: 16.0,
        extra_days_per_service_year: 1.0,
        max_days: 30.0,
        min_service_months: 12,
        max_carry_forward_days: 10.0,
        carry_forward_expiry_months: 24,
        allow_negative_balance: false,
        allow_encashment: true,
        requires_attachment: false,
        allow_half_day: true,
        rounding: 'half_day',
        gender: null,
        notice_days: 14,
        max_splits_per_year: 4,
        state: 'active'
      },
      {
        id: 102,
        uuid: 'rul-102',
        leave_policy_id: 1,
        leave_type_id: 2,
        leave_type_name: 'Sick Leave',
        leave_type_code: 'SICK',
        pay_percent: 100.0,
        accrual_method: 'annual_grant',
        days_per_year: 30.0,
        extra_days_per_service_year: 0.0,
        max_days: 180.0,
        min_service_months: 1,
        max_carry_forward_days: 0.0,
        carry_forward_expiry_months: 0,
        allow_negative_balance: false,
        allow_encashment: false,
        requires_attachment: true,
        allow_half_day: true,
        rounding: 'full_day',
        gender: null,
        notice_days: 0,
        max_splits_per_year: null,
        state: 'active'
      },
      {
        id: 103,
        uuid: 'rul-103',
        leave_policy_id: 1,
        leave_type_id: 3,
        leave_type_name: 'Maternity Leave',
        leave_type_code: 'MATERNITY',
        pay_percent: 100.0,
        accrual_method: 'fixed',
        days_per_year: 120.0,
        extra_days_per_service_year: 0.0,
        max_days: 120.0,
        min_service_months: 6,
        max_carry_forward_days: 0.0,
        carry_forward_expiry_months: 0,
        allow_negative_balance: false,
        allow_encashment: false,
        requires_attachment: true,
        allow_half_day: false,
        rounding: 'full_day',
        gender: 'female',
        notice_days: 30,
        max_splits_per_year: 2,
        state: 'active'
      },
      {
        id: 104,
        uuid: 'rul-104',
        leave_policy_id: 1,
        leave_type_id: 4,
        leave_type_name: 'Paternity Leave',
        leave_type_code: 'PATERNITY',
        pay_percent: 100.0,
        accrual_method: 'fixed',
        days_per_year: 5.0,
        extra_days_per_service_year: 0.0,
        max_days: 5.0,
        min_service_months: 3,
        max_carry_forward_days: 0.0,
        carry_forward_expiry_months: 0,
        allow_negative_balance: false,
        allow_encashment: false,
        requires_attachment: false,
        allow_half_day: false,
        rounding: 'full_day',
        gender: 'male',
        notice_days: 3,
        max_splits_per_year: 1,
        state: 'active'
      },
      {
        id: 105,
        uuid: 'rul-105',
        leave_policy_id: 1,
        leave_type_id: 5,
        leave_type_name: 'Bereavement Leave',
        leave_type_code: 'BEREAVEMENT',
        pay_percent: 100.0,
        accrual_method: 'fixed',
        days_per_year: 3.0,
        extra_days_per_service_year: 0.0,
        max_days: 7.0,
        min_service_months: 1,
        max_carry_forward_days: 0.0,
        carry_forward_expiry_months: 0,
        allow_negative_balance: false,
        allow_encashment: false,
        requires_attachment: false,
        allow_half_day: false,
        rounding: 'full_day',
        gender: null,
        notice_days: 0,
        max_splits_per_year: 3,
        state: 'active'
      }
    ]
  },
  {
    id: 2,
    uuid: 'pol-002',
    code: 'POL-RETAIL-2026',
    name: 'Retail Policy 2026',
    description: 'Operational store and commercial branch rulebook on 48-hour retail calendar.',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    work_calendar_id: 2,
    work_calendar_name: 'CAL-RETAIL (48h Week • 26d Divisor)',
    calendar_weekly_hours: 48.0,
    effective_from: '2026-07-08',
    effective_to: null,
    state: 'active',
    created_at: '2026-07-08',
    rules_count: 4,
    rules: [
      {
        id: 201,
        uuid: 'rul-201',
        leave_policy_id: 2,
        leave_type_id: 1,
        leave_type_name: 'Annual Leave',
        leave_type_code: 'ANNUAL',
        pay_percent: 100.0,
        accrual_method: 'per_service_year',
        days_per_year: 16.0,
        extra_days_per_service_year: 1.0,
        max_days: 30.0,
        min_service_months: 12,
        max_carry_forward_days: 5.0,
        carry_forward_expiry_months: 12,
        allow_negative_balance: false,
        allow_encashment: true,
        requires_attachment: false,
        allow_half_day: true,
        rounding: 'half_day',
        gender: null,
        notice_days: 21,
        max_splits_per_year: 3,
        state: 'active'
      },
      {
        id: 202,
        uuid: 'rul-202',
        leave_policy_id: 2,
        leave_type_id: 2,
        leave_type_name: 'Sick Leave',
        leave_type_code: 'SICK',
        pay_percent: 100.0,
        accrual_method: 'annual_grant',
        days_per_year: 30.0,
        extra_days_per_service_year: 0.0,
        max_days: 120.0,
        min_service_months: 1,
        max_carry_forward_days: 0.0,
        carry_forward_expiry_months: 0,
        allow_negative_balance: false,
        allow_encashment: false,
        requires_attachment: true,
        allow_half_day: true,
        rounding: 'full_day',
        gender: null,
        notice_days: 0,
        max_splits_per_year: null,
        state: 'active'
      },
      {
        id: 203,
        uuid: 'rul-203',
        leave_policy_id: 2,
        leave_type_id: 3,
        leave_type_name: 'Maternity Leave',
        leave_type_code: 'MATERNITY',
        pay_percent: 100.0,
        accrual_method: 'fixed',
        days_per_year: 120.0,
        extra_days_per_service_year: 0.0,
        max_days: 120.0,
        min_service_months: 6,
        max_carry_forward_days: 0.0,
        carry_forward_expiry_months: 0,
        allow_negative_balance: false,
        allow_encashment: false,
        requires_attachment: true,
        allow_half_day: false,
        rounding: 'full_day',
        gender: 'female',
        notice_days: 30,
        max_splits_per_year: 2,
        state: 'active'
      },
      {
        id: 204,
        uuid: 'rul-204',
        leave_policy_id: 2,
        leave_type_id: 4,
        leave_type_name: 'Paternity Leave',
        leave_type_code: 'PATERNITY',
        pay_percent: 100.0,
        accrual_method: 'fixed',
        days_per_year: 5.0,
        extra_days_per_service_year: 0.0,
        max_days: 5.0,
        min_service_months: 3,
        max_carry_forward_days: 0.0,
        carry_forward_expiry_months: 0,
        allow_negative_balance: false,
        allow_encashment: false,
        requires_attachment: false,
        allow_half_day: false,
        rounding: 'full_day',
        gender: 'male',
        notice_days: 3,
        max_splits_per_year: 1,
        state: 'active'
      }
    ]
  },
  {
    id: 3,
    uuid: 'pol-003',
    code: 'POL-BDR-2026',
    name: 'Bahir Dar Hub Policy',
    description: 'Regional operational supply and logistics distribution center rulebook.',
    entity_id: 9,
    entity_name: 'Bahir Dar Regional Hub',
    work_calendar_id: 3,
    work_calendar_name: 'CAL-RETAIL2 (48h Week)',
    calendar_weekly_hours: 48.0,
    effective_from: '2026-07-08',
    effective_to: null,
    state: 'active',
    created_at: '2026-07-08',
    rules_count: 3,
    rules: [
      {
        id: 301,
        uuid: 'rul-301',
        leave_policy_id: 3,
        leave_type_id: 1,
        leave_type_name: 'Annual Leave',
        leave_type_code: 'ANNUAL',
        pay_percent: 100.0,
        accrual_method: 'per_service_year',
        days_per_year: 16.0,
        extra_days_per_service_year: 1.0,
        max_days: 30.0,
        min_service_months: 12,
        max_carry_forward_days: 8.0,
        carry_forward_expiry_months: 18,
        allow_negative_balance: false,
        allow_encashment: true,
        requires_attachment: false,
        allow_half_day: true,
        rounding: 'half_day',
        gender: null,
        notice_days: 14,
        max_splits_per_year: 3,
        state: 'active'
      }
    ]
  }
]);

// ─── Helper Functions ───
export const getPolicyById = (id: number): LeavePolicyRecord | undefined => {
  return leavePoliciesData.value.find(p => p.id === id);
};

export const createLeaveType = (payload: {
  code: string;
  name: string;
  description?: string;
  is_paid: boolean;
  requires_attachment: boolean;
  affects_attendance: boolean;
}): LeaveTypeRecord => {
  const newId = Date.now();
  const record: LeaveTypeRecord = {
    id: newId,
    uuid: `typ-${String(newId).slice(-4)}`,
    code: payload.code.toUpperCase().trim(),
    name: payload.name.trim(),
    description: payload.description || 'Custom organizational leave category.',
    is_paid: payload.is_paid,
    requires_attachment: payload.requires_attachment,
    affects_attendance: payload.affects_attendance,
    icon_name: 'Calendar',
    state: 'active',
    created_at: new Date().toISOString().slice(0, 10)
  };
  leaveTypesData.value.unshift(record);
  return record;
};

export const createLeavePolicy = (payload: {
  code: string;
  name: string;
  description?: string;
  entity_id: number;
  entity_name: string;
  work_calendar_id: number;
  work_calendar_name: string;
  calendar_weekly_hours?: number;
  effective_from: string;
  rules: LeavePolicyRuleRecord[];
}): LeavePolicyRecord => {
  const newId = Date.now();
  const record: LeavePolicyRecord = {
    id: newId,
    uuid: `pol-${String(newId).slice(-4)}`,
    code: payload.code.toUpperCase().trim(),
    name: payload.name.trim(),
    description: payload.description || 'Operational leave entitlement policy rulebook.',
    entity_id: payload.entity_id,
    entity_name: payload.entity_name,
    work_calendar_id: payload.work_calendar_id,
    work_calendar_name: payload.work_calendar_name,
    calendar_weekly_hours: payload.calendar_weekly_hours || 40.0,
    effective_from: payload.effective_from,
    effective_to: null,
    state: 'active',
    created_at: new Date().toISOString().slice(0, 10),
    rules_count: payload.rules.length,
    rules: payload.rules
  };
  leavePoliciesData.value.unshift(record);
  return record;
};
