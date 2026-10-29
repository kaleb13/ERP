import { ref } from 'vue';

export type LetterType =
  | 'employment_confirmation'
  | 'experience'
  | 'salary_certificate'
  | 'offer'
  | 'warning'
  | 'promotion'
  | 'transfer'
  | 'termination'
  | 'bank_reference';

export type LetterState =
  | 'draft'
  | 'pending_approval'
  | 'approved'
  | 'issued'
  | 'revoked';

export type LetterDirection = 'outgoing' | 'incoming';

export interface LetterTemplateRecord {
  id: number;
  uuid: string;
  code: string; // LT-EXP, LT-SALCERT, etc.
  name: string;
  description: string;
  letter_type: LetterType;
  entity_id: number | null;
  entity_name: string;
  document_type_id: number;
  body: string; // Rich text with {{merge_fields}}
  requires_approval: boolean;
  is_system: boolean;
  status: 'pending' | 'acceptForAll' | 'acceptForThis' | 'reject';
  user_id: number;
  state: 'active' | 'inactive';
}

export interface EmployeeLetterRecord {
  id: number;
  uuid: string;
  code: string; // DocumentSequence LTR-2026-0067
  direction: LetterDirection;
  remind_on_separation: boolean;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_avatar: string;
  department: string;
  position: string;
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  letter_template_id: number;
  template_name: string;
  letter_type: LetterType;
  letter_state: LetterState;
  merge_data: {
    salary?: number;
    position?: string;
    hire_date?: string;
    department?: string;
    monthly_allowance?: number;
    probation_passed?: boolean;
    guarantor_amount?: number;
    [key: string]: any;
  };
  addressed_to?: {
    organization: string;
    attention?: string;
  } | null;
  purpose?: string | null;
  requested_by_employee_id: number;
  requested_by_name: string;
  issued_by_employee_id?: number | null;
  issued_by_name?: string | null;
  issued_at?: string | null;
  revoked_at?: string | null;
  revoke_reason?: string | null;
  user_id: number;
  state: 'active' | 'inactive';
}

export const LETTER_TYPE_MAP: Record<LetterType, { label: string; badgeVariant: string }> = {
  employment_confirmation: { label: 'Employment Confirmation', badgeVariant: 'primary' },
  experience: { label: 'Experience Letter', badgeVariant: 'info' },
  salary_certificate: { label: 'Salary Certificate', badgeVariant: 'accent' },
  offer: { label: 'Job Offer', badgeVariant: 'success' },
  warning: { label: 'Warning Letter', badgeVariant: 'danger' },
  promotion: { label: 'Promotion Letter', badgeVariant: 'primary' },
  transfer: { label: 'Transfer Letter', badgeVariant: 'warning' },
  termination: { label: 'Termination Letter', badgeVariant: 'danger' },
  bank_reference: { label: 'Bank Reference', badgeVariant: 'neutral' }
};

export const LETTER_STATE_MAP: Record<LetterState, { label: string; badgeVariant: 'default' | 'primary' | 'success' | 'warning' | 'danger' | 'info' }> = {
  draft: { label: 'Draft', badgeVariant: 'default' },
  pending_approval: { label: 'Pending Approval', badgeVariant: 'warning' },
  approved: { label: 'Approved', badgeVariant: 'primary' },
  issued: { label: 'Issued', badgeVariant: 'success' },
  revoked: { label: 'Revoked', badgeVariant: 'danger' }
};

export const LETTER_DIRECTION_MAP: Record<LetterDirection, { label: string }> = {
  outgoing: { label: 'Outgoing (Issued by HR)' },
  incoming: { label: 'Incoming (Received External)' }
};

// ─── SEED TEMPLATES (From Section 13 Schema lines 2128-2134) ─────────────
export const letterTemplatesData = ref<LetterTemplateRecord[]>([
  {
    id: 1,
    uuid: 'lt-001-exp',
    code: 'LT-EXP',
    name: 'Certificate of Work Experience',
    description: 'Official proof of tenure, designations, and duties performed per Ethiopian Labour Proclamation.',
    letter_type: 'experience',
    entity_id: null,
    entity_name: 'Haleta Enterprise Group',
    document_type_id: 101,
    body: `To Whom It May Concern,\n\nThis is to certify that **{{employee_name}}** was employed at **Haleta Enterprise Group** from **{{hire_date}}** to **{{last_working_date}}** as a **{{position}}** in the **{{department}}** department.\n\nDuring their tenure, they have demonstrated high professional competence, diligence, and integrity.\n\nWe wish them all the best in their future endeavors.`,
    requires_approval: true,
    is_system: true,
    status: 'acceptForAll',
    user_id: 1,
    state: 'active'
  },
  {
    id: 2,
    uuid: 'lt-002-salcert',
    code: 'LT-SALCERT',
    name: 'Salary & Earnings Certificate',
    description: 'Certified breakdown of basic monthly salary and regular allowances for bank loans and credit facilities.',
    letter_type: 'salary_certificate',
    entity_id: null,
    entity_name: 'Haleta Enterprise Group',
    document_type_id: 102,
    body: `To: **{{addressed_organization}}**\nAttn: **{{addressed_attention}}**\n\nSubject: **Confirmation of Employment and Monthly Earnings**\n\nWe hereby confirm that **{{employee_name}}** is a permanent full-time employee at Haleta Enterprise Group, currently serving as **{{position}}** since **{{hire_date}}**.\n\nTheir current monthly gross compensation is structured as follows:\n- Basic Monthly Salary: **ETB {{basic_salary}}**\n- Taxable Allowances: **ETB {{monthly_allowance}}**\n\nThis letter is issued upon the request of the employee for the purpose of: **{{purpose}}**.`,
    requires_approval: true,
    is_system: true,
    status: 'acceptForAll',
    user_id: 1,
    state: 'active'
  },
  {
    id: 3,
    uuid: 'lt-003-conf',
    code: 'LT-CONF',
    name: 'Employment Confirmation Letter',
    description: 'General confirmation of active employment status, role, and permanent contractual standing.',
    letter_type: 'employment_confirmation',
    entity_id: null,
    entity_name: 'Haleta Enterprise Group',
    document_type_id: 103,
    body: `To Whom It May Concern,\n\nThis serves to confirm that **{{employee_name}}** is currently an active, full-time staff member of **Haleta Enterprise Group**, holding the position of **{{position}}** within the **{{department}}** department since **{{hire_date}}**.\n\nPlease do not hesitate to contact our HR department should you require any additional validation.`,
    requires_approval: false,
    is_system: true,
    status: 'acceptForAll',
    user_id: 1,
    state: 'active'
  },
  {
    id: 4,
    uuid: 'lt-004-warn',
    code: 'LT-WARN',
    name: 'Written Warning Letter',
    description: 'Statutory formal disciplinary notice following documented policy infraction or hearing verdict.',
    letter_type: 'warning',
    entity_id: null,
    entity_name: 'Haleta Enterprise Group',
    document_type_id: 104,
    body: `Strictly Confidential\n\nTo: **{{employee_name}}** (ID: {{employee_code}})\nPosition: **{{position}}**\n\nSubject: **Formal Written Warning Notice**\n\nFollowing a formal review of recent operational incidents, this letter constitutes an official written warning in accordance with the Haleta Group Disciplinary Code. Continued failure to meet organizational expectations may lead to escalating disciplinary sanctions up to contract termination.`,
    requires_approval: true,
    is_system: true,
    status: 'acceptForAll',
    user_id: 1,
    state: 'active'
  },
  {
    id: 5,
    uuid: 'lt-005-bankref',
    code: 'LT-BANKREF',
    name: 'Bank Reference & Undertaking',
    description: 'Employer undertaking for employee mortgage, auto loan, or salary-backed personal credit.',
    letter_type: 'bank_reference',
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa Branch',
    document_type_id: 105,
    body: `To: **{{addressed_organization}}**\n\nSubject: **Letter of Undertaking for Salary Credit Facility**\n\nRegarding our employee **{{employee_name}}**, we confirm that in the event of separation from employment, Haleta will endeavor to notify the lending institution and remit any terminal settlement due in accordance with applicable statutory guidelines.`,
    requires_approval: true,
    is_system: false,
    status: 'acceptForThis',
    user_id: 1,
    state: 'active'
  },
  {
    id: 6,
    uuid: 'lt-006-offer',
    code: 'LT-OFFER',
    name: 'Official Job Offer & Terms of Employment',
    description: 'Formal letter of appointment specifying starting compensation, probationary period, and reporting line.',
    letter_type: 'offer',
    entity_id: null,
    entity_name: 'Haleta Enterprise Group',
    document_type_id: 106,
    body: `Dear **{{employee_name}}**,\n\nWe are pleased to formally offer you employment with **Haleta Enterprise Group** in the capacity of **{{position}}** reporting to the **{{department}}** Department.\n\nYour starting basic salary will be **ETB {{basic_salary}}** per month, with effective commencement on **{{hire_date}}**.\n\nPlease sign and return the duplicate copy of this letter indicating your acceptance.`,
    requires_approval: true,
    is_system: true,
    status: 'acceptForAll',
    user_id: 1,
    state: 'active'
  },
  {
    id: 7,
    uuid: 'lt-007-promo',
    code: 'LT-PROMO',
    name: 'Promotion & Title Upgrade Notice',
    description: 'Official notice of grade advancement, increased executive responsibilities, and revised compensation.',
    letter_type: 'promotion',
    entity_id: null,
    entity_name: 'Haleta Enterprise Group',
    document_type_id: 107,
    body: `Dear **{{employee_name}}**,\n\nIn recognition of your exceptional performance and leadership, Executive Management is pleased to announce your promotion to **{{position}}** within the **{{department}}** division, effective **{{effective_date}}**.\n\nYour revised monthly basic salary will be adjusted to **ETB {{basic_salary}}**.\n\nWe congratulate you on this milestone and look forward to your ongoing contributions.`,
    requires_approval: true,
    is_system: true,
    status: 'acceptForAll',
    user_id: 1,
    state: 'active'
  },
  {
    id: 8,
    uuid: 'lt-008-trans',
    code: 'LT-TRANS',
    name: 'Inter-Branch Transfer Directive',
    description: 'Formal organizational notice transferring employee to a new operating unit, branch, or duty station.',
    letter_type: 'transfer',
    entity_id: null,
    entity_name: 'Haleta Enterprise Group',
    document_type_id: 108,
    body: `To: **{{employee_name}}** (Staff ID: {{employee_code}})\n\nSubject: **Internal Transfer Order**\n\nPlease be advised that management has approved your transfer from your current post to **{{department}}** as **{{position}}**, with immediate reporting to your new unit head on **{{hire_date}}**.\n\nAll existing terms of service and accrued benefits remain intact.`,
    requires_approval: true,
    is_system: true,
    status: 'acceptForAll',
    user_id: 1,
    state: 'active'
  },
  {
    id: 9,
    uuid: 'lt-009-term',
    code: 'LT-TERM',
    name: 'Separation & Employment Termination Notice',
    description: 'Formal release letter documenting termination of contractual relations and exit clearance instructions.',
    letter_type: 'termination',
    entity_id: null,
    entity_name: 'Haleta Enterprise Group',
    document_type_id: 109,
    body: `Dear **{{employee_name}}**,\n\nThis letter serves as formal notification that your employment with Haleta Enterprise Group as **{{position}}** will conclude on **{{last_working_date}}**.\n\nPlease liaise with the HR Administration Division to initiate exit clearance and surrender all company properties to facilitate the preparation of your final settlement.`,
    requires_approval: true,
    is_system: true,
    status: 'acceptForAll',
    user_id: 1,
    state: 'active'
  }
]);

// ─── SEED EMPLOYEE LETTERS (Directly from Section 13 Schema lines 2158-2164) ───
export const employeeLettersData = ref<EmployeeLetterRecord[]>([
  {
    id: 67,
    uuid: 'ltr-067-9b1d',
    code: 'LTR-2026-0067',
    direction: 'outgoing',
    remind_on_separation: true,
    employee_id: 22,
    employee_name: 'Hana Mesfin',
    employee_code: 'EMP-0022',
    employee_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    department: 'Finance & Accounting',
    position: 'Senior Financial Analyst',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa Branch',
    letter_template_id: 2,
    template_name: 'Salary & Earnings Certificate',
    letter_type: 'salary_certificate',
    letter_state: 'issued',
    merge_data: {
      salary: 28500.0,
      monthly_allowance: 4500.0,
      position: 'Senior Financial Analyst',
      department: 'Finance & Accounting',
      hire_date: '2023-04-01'
    },
    addressed_to: {
      organization: 'Commercial Bank of Ethiopia (CBE)',
      attention: 'Bole Branch Loan Officer'
    },
    purpose: 'Mortgage loan application requirement',
    requested_by_employee_id: 22,
    requested_by_name: 'Hana Mesfin',
    issued_by_employee_id: 7,
    issued_by_name: 'Solomon Worku',
    issued_at: '2026-07-21T08:30:00Z',
    revoked_at: null,
    revoke_reason: null,
    user_id: 1,
    state: 'active'
  },
  {
    id: 68,
    uuid: 'ltr-068-c827',
    code: 'LTR-2026-0068',
    direction: 'outgoing',
    remind_on_separation: false,
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-0014',
    employee_avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    department: 'Operations & Logistics',
    position: 'Operations Director',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa Branch',
    letter_template_id: 3,
    template_name: 'Employment Confirmation Letter',
    letter_type: 'employment_confirmation',
    letter_state: 'issued',
    merge_data: {
      salary: 52000.0,
      position: 'Operations Director',
      department: 'Operations & Logistics',
      hire_date: '2021-02-15'
    },
    addressed_to: null,
    purpose: 'Visa and travel sponsorship application',
    requested_by_employee_id: 14,
    requested_by_name: 'Abebe Kebede',
    issued_by_employee_id: 7,
    issued_by_name: 'Solomon Worku',
    issued_at: '2026-07-15T10:00:00Z',
    revoked_at: null,
    revoke_reason: null,
    user_id: 1,
    state: 'active'
  },
  {
    id: 69,
    uuid: 'ltr-069-e712',
    code: 'LTR-2026-0069',
    direction: 'outgoing',
    remind_on_separation: true,
    employee_id: 44,
    employee_name: 'Dawit Tadesse',
    employee_code: 'EMP-0044',
    employee_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
    department: 'Plant Operations & Engineering',
    position: 'Electrical Systems Engineer',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa Branch',
    letter_template_id: 5,
    template_name: 'Bank Reference & Undertaking',
    letter_type: 'bank_reference',
    letter_state: 'pending_approval',
    merge_data: {
      salary: 31000.0,
      position: 'Electrical Systems Engineer',
      department: 'Plant Operations & Engineering',
      hire_date: '2024-01-10'
    },
    addressed_to: {
      organization: 'Awash Bank S.C.',
      attention: 'Credit & Guarantee Division, Bole Branch'
    },
    purpose: 'Personal auto asset financing undertaking',
    requested_by_employee_id: 44,
    requested_by_name: 'Dawit Tadesse',
    issued_by_employee_id: null,
    issued_by_name: null,
    issued_at: null,
    revoked_at: null,
    revoke_reason: null,
    user_id: 1,
    state: 'active'
  },
  {
    id: 70,
    uuid: 'ltr-070-f561',
    code: 'LTR-2026-0070',
    direction: 'outgoing',
    remind_on_separation: false,
    employee_id: 18,
    employee_name: 'Kidst Tesfaye',
    employee_code: 'EMP-0018',
    employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    department: 'Plant Operations & Security',
    position: 'HQ Security Supervisor',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa Branch',
    letter_template_id: 1,
    template_name: 'Certificate of Work Experience',
    letter_type: 'experience',
    letter_state: 'issued',
    merge_data: {
      salary: 19500.0,
      position: 'HQ Security Supervisor',
      department: 'Plant Operations & Security',
      hire_date: '2022-09-01'
    },
    addressed_to: null,
    purpose: 'Terminal service verification following exit',
    requested_by_employee_id: 18,
    requested_by_name: 'Kidst Tesfaye',
    issued_by_employee_id: 7,
    issued_by_name: 'Solomon Worku',
    issued_at: '2026-03-05T09:00:00Z',
    revoked_at: null,
    revoke_reason: null,
    user_id: 1,
    state: 'active'
  },
  {
    id: 71,
    uuid: 'ltr-071-a381',
    code: 'LTR-2026-0071',
    direction: 'outgoing',
    remind_on_separation: false,
    employee_id: 15,
    employee_name: 'Yonas Mulugeta',
    employee_code: 'EMP-0015',
    employee_avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80',
    department: 'Supply Chain & Procurement',
    position: 'Senior Procurement Officer',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa Branch',
    letter_template_id: 4,
    template_name: 'Written Warning Letter',
    letter_type: 'warning',
    letter_state: 'draft',
    merge_data: {
      position: 'Senior Procurement Officer',
      department: 'Supply Chain & Procurement',
      hire_date: '2023-06-15'
    },
    addressed_to: null,
    purpose: 'Internal disciplinary record - unauthorized procurement variance',
    requested_by_employee_id: 7,
    requested_by_name: 'Solomon Worku (HR Director)',
    issued_by_employee_id: null,
    issued_by_name: null,
    issued_at: null,
    revoked_at: null,
    revoke_reason: null,
    user_id: 1,
    state: 'active'
  }
]);

// Helper to add new letter
export const addEmployeeLetter = (record: Omit<EmployeeLetterRecord, 'id' | 'uuid' | 'code'>) => {
  const newId = (Math.max(...employeeLettersData.value.map(l => l.id), 71) + 1);
  const codeYear = new Date().getFullYear();
  const codeSeq = String(newId).padStart(4, '0');
  const code = `LTR-${codeYear}-${codeSeq}`;

  const newRecord: EmployeeLetterRecord = {
    ...record,
    id: newId,
    uuid: `ltr-${newId}-${Date.now()}`,
    code
  };

  employeeLettersData.value.unshift(newRecord);
  return newRecord;
};

// Helper to update status
export const updateLetterStatus = (id: number, status: LetterState, issuedByName?: string) => {
  const item = employeeLettersData.value.find(l => l.id === id);
  if (item) {
    item.letter_state = status;
    if (status === 'issued') {
      item.issued_at = new Date().toISOString();
      if (issuedByName) item.issued_by_name = issuedByName;
    } else if (status === 'revoked') {
      item.revoked_at = new Date().toISOString();
    }
  }
};

// ─── TEMPLATE CRUD HELPERS ──────────────────────────────────────────────────
export const addLetterTemplate = (record: Omit<LetterTemplateRecord, 'id' | 'uuid'>) => {
  const newId = (Math.max(...letterTemplatesData.value.map(t => t.id), 0) + 1);
  const newRecord: LetterTemplateRecord = {
    ...record,
    id: newId,
    uuid: `lt-${String(newId).padStart(3, '0')}-${Date.now()}`
  };
  letterTemplatesData.value.unshift(newRecord);
  return newRecord;
};

export const updateLetterTemplate = (id: number, updates: Partial<LetterTemplateRecord>) => {
  const item = letterTemplatesData.value.find(t => t.id === id);
  if (item) {
    Object.assign(item, updates);
    return item;
  }
  return null;
};

export const deleteLetterTemplate = (id: number) => {
  const idx = letterTemplatesData.value.findIndex(t => t.id === id);
  if (idx !== -1) {
    letterTemplatesData.value.splice(idx, 1);
    return true;
  }
  return false;
};

export const duplicateLetterTemplate = (id: number) => {
  const original = letterTemplatesData.value.find(t => t.id === id);
  if (!original) return null;

  const newId = (Math.max(...letterTemplatesData.value.map(t => t.id), 0) + 1);
  const duplicateRecord: LetterTemplateRecord = {
    ...original,
    id: newId,
    uuid: `lt-${String(newId).padStart(3, '0')}-${Date.now()}`,
    code: `${original.code}-COPY`,
    name: `${original.name} (Copy)`,
    is_system: false,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa Branch',
    status: 'pending'
  };

  letterTemplatesData.value.unshift(duplicateRecord);
  return duplicateRecord;
};

// Standard available merge tokens
export interface MergeToken {
  token: string;
  label: string;
  category: 'Employee' | 'Position & Org' | 'Compensation' | 'Dates' | 'Recipient';
  sampleValue: string;
}

export const AVAILABLE_MERGE_TOKENS: MergeToken[] = [
  { token: '{{employee_name}}', label: 'Employee Full Name', category: 'Employee', sampleValue: 'Hana Mesfin Tadesse' },
  { token: '{{employee_code}}', label: 'Employee Staff ID', category: 'Employee', sampleValue: 'EMP-0022' },
  { token: '{{national_id}}', label: 'National ID / Fayda', category: 'Employee', sampleValue: 'ET-NID-88392019' },
  { token: '{{gender}}', label: 'Gender', category: 'Employee', sampleValue: 'Female' },
  { token: '{{position}}', label: 'Job Position', category: 'Position & Org', sampleValue: 'Senior Financial Analyst' },
  { token: '{{department}}', label: 'Department / Unit', category: 'Position & Org', sampleValue: 'Finance & Accounting Division' },
  { token: '{{job_grade}}', label: 'Job Grade', category: 'Position & Org', sampleValue: 'Grade IX' },
  { token: '{{basic_salary}}', label: 'Basic Monthly Salary', category: 'Compensation', sampleValue: '28,500.00' },
  { token: '{{monthly_allowance}}', label: 'Monthly Allowance', category: 'Compensation', sampleValue: '6,200.00' },
  { token: '{{hire_date}}', label: 'Employment Hire Date', category: 'Dates', sampleValue: '15 January 2023' },
  { token: '{{effective_date}}', label: 'Effective Date', category: 'Dates', sampleValue: '01 November 2026' },
  { token: '{{last_working_date}}', label: 'Last Working Date / Separation', category: 'Dates', sampleValue: '31 October 2026' },
  { token: '{{current_date}}', label: 'Document Issue Date', category: 'Dates', sampleValue: new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' }) },
  { token: '{{addressed_organization}}', label: 'Addressed Organization / Bank', category: 'Recipient', sampleValue: 'Commercial Bank of Ethiopia (Bole Branch)' },
  { token: '{{addressed_attention}}', label: 'Attention Person / Officer', category: 'Recipient', sampleValue: 'Credit & Mortgages Officer' },
  { token: '{{purpose}}', label: 'Specific Request Purpose', category: 'Recipient', sampleValue: 'Home mortgage qualification application' }
];

export const renderTemplatePreview = (templateBody: string, sampleData?: Record<string, string>) => {
  let rendered = templateBody;
  const sampleMap: Record<string, string> = {
    ...AVAILABLE_MERGE_TOKENS.reduce((acc, t) => {
      acc[t.token] = t.sampleValue;
      return acc;
    }, {} as Record<string, string>),
    ...(sampleData || {})
  };

  for (const [token, value] of Object.entries(sampleMap)) {
    rendered = rendered.split(token).join(value);
  }
  return rendered;
};

