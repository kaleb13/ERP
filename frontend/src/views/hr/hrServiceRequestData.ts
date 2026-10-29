import { ref } from 'vue';

export type HRServiceRequestCategory =
  | 'letter'
  | 'id_card'
  | 'payslip_copy'
  | 'data_correction'
  | 'benefit_inquiry'
  | 'general';

export type HRServiceRequestState =
  | 'open'
  | 'assigned'
  | 'in_progress'
  | 'resolved'
  | 'closed'
  | 'cancelled';

export interface HRServiceRequestRecord {
  id: number;
  uuid: string;
  code: string; // DocumentSequence (HSR-2026-0102)
  employee_id: number; // FK Employee -- requester
  employee_name: string;
  employee_code: string;
  department: string;
  position: string;
  tenant_id: number;
  entity_id: number; // FK Entity -- owning tenant/branch
  entity_name: string;
  category_lookup_value_id: HRServiceRequestCategory;
  subject: string; // jsonb in schema ({ en: "Salary certificate for CBE mortgage" })
  description: string | null; // jsonb nullable
  request_state_lookup_value_id: HRServiceRequestState;
  assigned_to_employee_id: number | null; // FK Employee nullable -- HR handler
  assigned_to_name: string | null;
  linked_reference: {
    employee_letter_id?: number;
    employee_letter_code?: string;
    note?: string;
    sent_via_email?: boolean;
  } | null; // jsonb nullable ({ employee_letter_id: 67 })
  resolution_note: string | null; // jsonb nullable
  resolved_at: string | null; // timestamp nullable
  user_id: number; // FK User -- who created the row
  state: 'active' | 'inactive';
  created_at: string;
}

// ─── AUTHORITATIVE SEED DATA (HR Schema Designer 1.sql lines 2248-2256) ────
export const seedServiceRequests: HRServiceRequestRecord[] = [
  {
    id: 102,
    uuid: 'hsr-2026-0102-aa19',
    code: 'HSR-2026-0102',
    employee_id: 22,
    employee_name: 'Hana Mesfin Tadesse',
    employee_code: 'EMP-0022',
    department: 'Finance & Accounting Division',
    position: 'Senior Financial Analyst',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Corporate Headquarters',
    category_lookup_value_id: 'letter',
    subject: 'Salary certificate for CBE loan',
    description: 'Require a certified salary confirmation letter addressed to Commercial Bank of Ethiopia (Bole Branch) for mortgage loan processing.',
    request_state_lookup_value_id: 'resolved',
    assigned_to_employee_id: 14,
    assigned_to_name: 'Solomon Bekele Worku',
    linked_reference: {
      employee_letter_id: 67,
      employee_letter_code: 'LTR-2026-0067'
    },
    resolution_note: 'Official salary confirmation letter issued and stamped under LTR-2026-0067.',
    resolved_at: '2026-07-21T08:30:00Z',
    user_id: 7,
    state: 'active',
    created_at: '2026-07-20T09:15:00Z'
  },
  {
    id: 103,
    uuid: 'hsr-2026-0103-bb84',
    code: 'HSR-2026-0103',
    employee_id: 14,
    employee_name: 'Solomon Bekele Worku',
    employee_code: 'EMP-0014',
    department: 'Executive Management',
    position: 'Director of Human Resources',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Corporate Headquarters',
    category_lookup_value_id: 'id_card',
    subject: 'Replace lost staff ID card',
    description: 'Damaged biometric RFID access badge needs replacement before building turnstile entry.',
    request_state_lookup_value_id: 'in_progress',
    assigned_to_employee_id: 14,
    assigned_to_name: 'Solomon Bekele Worku',
    linked_reference: null,
    resolution_note: null,
    resolved_at: null,
    user_id: 7,
    state: 'active',
    created_at: '2026-07-22T11:20:00Z'
  },
  {
    id: 104,
    uuid: 'hsr-2026-0104-cc31',
    code: 'HSR-2026-0104',
    employee_id: 31,
    employee_name: 'Helen Berhanu Haile',
    employee_code: 'EMP-0031',
    department: 'Human Resources & People Operations',
    position: 'Talent Acquisition Partner',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Corporate Headquarters',
    category_lookup_value_id: 'data_correction',
    subject: 'Birth date wrong on my profile',
    description: 'National ID Fayda record shows birth year 1994, but ERP profile currently records 1995. Official Fayda digital card presented for verification.',
    request_state_lookup_value_id: 'assigned',
    assigned_to_employee_id: 14,
    assigned_to_name: 'Solomon Bekele Worku',
    linked_reference: null,
    resolution_note: null,
    resolved_at: null,
    user_id: 7,
    state: 'active',
    created_at: '2026-07-23T14:05:00Z'
  },
  {
    id: 105,
    uuid: 'hsr-2026-0105-dd44',
    code: 'HSR-2026-0105',
    employee_id: 44,
    employee_name: 'Dawit Tadesse Mengistu',
    employee_code: 'EMP-0044',
    department: 'Internal Audit & Risk',
    position: 'Lead Internal Auditor',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Corporate Headquarters',
    category_lookup_value_id: 'benefit_inquiry',
    subject: 'Add newborn to NIB medical cover',
    description: 'Submitted birth certificate to enroll new infant dependent under statutory corporate group medical insurance policy.',
    request_state_lookup_value_id: 'open',
    assigned_to_employee_id: null,
    assigned_to_name: null,
    linked_reference: null,
    resolution_note: null,
    resolved_at: null,
    user_id: 7,
    state: 'active',
    created_at: '2026-07-24T08:40:00Z'
  },
  {
    id: 106,
    uuid: 'hsr-2026-0106-ee15',
    code: 'HSR-2026-0106',
    employee_id: 15,
    employee_name: 'Yared Alemu Kassaye',
    employee_code: 'EMP-0015',
    department: 'Information Technology',
    position: 'Network Infrastructure Lead',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Corporate Headquarters',
    category_lookup_value_id: 'payslip_copy',
    subject: 'June + July payslip copies',
    description: 'Need certified digital copies of June and July 2026 payroll slips for visa application appointment.',
    request_state_lookup_value_id: 'closed',
    assigned_to_employee_id: 14,
    assigned_to_name: 'Solomon Bekele Worku',
    linked_reference: {
      sent_via_email: true,
      note: 'Certified PDF payslips sent via secure registered email.'
    },
    resolution_note: 'Copies generated from Payroll run and sent via registered corporate email.',
    resolved_at: '2026-07-25T16:00:00Z',
    user_id: 7,
    state: 'active',
    created_at: '2026-07-24T10:30:00Z'
  }
];

export const serviceRequestsData = ref<HRServiceRequestRecord[]>([...seedServiceRequests]);

// ─── HELPER METHODS & WORKFLOWS ───────────────────────────────────────────

export const createServiceRequest = (
  payload: Omit<HRServiceRequestRecord, 'id' | 'uuid' | 'code' | 'created_at'>
): HRServiceRequestRecord => {
  const newId = (Math.max(...serviceRequestsData.value.map(r => r.id), 106) + 1);
  const newRecord: HRServiceRequestRecord = {
    ...payload,
    id: newId,
    uuid: `hsr-2026-${String(newId).padStart(4, '0')}-${Date.now().toString(36)}`,
    code: `HSR-2026-${String(newId).padStart(4, '0')}`,
    created_at: new Date().toISOString()
  };

  serviceRequestsData.value.unshift(newRecord);
  return newRecord;
};

export const updateServiceRequest = (
  id: number,
  updates: Partial<HRServiceRequestRecord>
) => {
  const item = serviceRequestsData.value.find(r => r.id === id);
  if (item) {
    Object.assign(item, updates);
    return item;
  }
  return null;
};

export const assignServiceRequest = (
  id: number,
  handlerEmployeeId: number,
  handlerName: string
) => {
  const item = serviceRequestsData.value.find(r => r.id === id);
  if (item) {
    item.assigned_to_employee_id = handlerEmployeeId;
    item.assigned_to_name = handlerName;
    if (item.request_state_lookup_value_id === 'open') {
      item.request_state_lookup_value_id = 'assigned';
    }
    return item;
  }
  return null;
};

export const resolveServiceRequest = (
  id: number,
  resolutionNote: string,
  linkedLetterId?: number,
  linkedLetterCode?: string
) => {
  const item = serviceRequestsData.value.find(r => r.id === id);
  if (item) {
    item.request_state_lookup_value_id = 'resolved';
    item.resolution_note = resolutionNote;
    item.resolved_at = new Date().toISOString();
    if (linkedLetterId) {
      item.linked_reference = {
        employee_letter_id: linkedLetterId,
        employee_letter_code: linkedLetterCode
      };
    }
    return item;
  }
  return null;
};

export const updateServiceRequestState = (
  id: number,
  state: HRServiceRequestState
) => {
  const item = serviceRequestsData.value.find(r => r.id === id);
  if (item) {
    item.request_state_lookup_value_id = state;
    if (state === 'resolved' && !item.resolved_at) {
      item.resolved_at = new Date().toISOString();
    }
    return item;
  }
  return null;
};

export const deleteServiceRequest = (id: number) => {
  const idx = serviceRequestsData.value.findIndex(r => r.id === id);
  if (idx !== -1) {
    serviceRequestsData.value.splice(idx, 1);
    return true;
  }
  return false;
};
