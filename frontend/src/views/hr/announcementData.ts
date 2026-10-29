import { ref } from 'vue';

export type AnnouncementAudience =
  | 'all'
  | 'organization_unit'
  | 'grade'
  | 'position'
  | 'employee_list';

export type AnnouncementState = 'draft' | 'scheduled' | 'published' | 'archived';

export interface AnnouncementTarget {
  id: number;
  announcement_id: number;
  target_type: 'organization_unit' | 'job_grade' | 'job_position' | 'employee';
  organization_unit_id?: number;
  unit_name?: string;
  job_grade_id?: number;
  grade_name?: string;
  job_position_id?: number;
  position_name?: string;
  employee_id?: number;
  employee_name?: string;
  employee_code?: string;
  state: 'active' | 'inactive';
}

export interface AnnouncementAcknowledgment {
  id: number;
  announcement_id: number;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_avatar: string;
  department: string;
  position: string;
  acknowledged_at: string | null;
  state: 'active' | 'inactive';
}

export interface AnnouncementRecord {
  id: number;
  uuid: string;
  code: string; // HRA-2026-0021
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  title: string;
  body: string;
  audience: AnnouncementAudience;
  target_summary: string;
  targets: AnnouncementTarget[];
  publish_from: string;
  publish_to: string | null;
  requires_acknowledgment: boolean;
  acknowledgment_deadline: string | null;
  announcement_state: AnnouncementState;
  published_by_employee_id: number | null;
  published_by_name: string | null;
  published_by_role: string | null;
  user_id: number;
  state: 'active' | 'inactive';
  created_at: string;
}

// ─── SEED ACKNOWLEDGMENTS (Section 13 Schema lines 3731-3738) ────────────
export const seedAcknowledgments: AnnouncementAcknowledgment[] = [
  // For Announcement 21 (Updated Safety Policy)
  {
    id: 1,
    announcement_id: 21,
    employee_id: 22,
    employee_name: 'Hana Mesfin Tadesse',
    employee_code: 'EMP-0022',
    employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    department: 'Finance & Accounting Division',
    position: 'Senior Financial Analyst',
    acknowledged_at: '2026-07-02T08:15:00Z',
    state: 'active'
  },
  {
    id: 2,
    announcement_id: 21,
    employee_id: 14,
    employee_name: 'Solomon Bekele Worku',
    employee_code: 'EMP-0014',
    employee_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
    department: 'Executive Management',
    position: 'Director of Human Resources',
    acknowledged_at: '2026-07-03T09:40:00Z',
    state: 'active'
  },
  {
    id: 3,
    announcement_id: 21,
    employee_id: 31,
    employee_name: 'Helen Berhanu Haile',
    employee_code: 'EMP-0031',
    employee_avatar: 'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=150&auto=format&fit=crop&q=80',
    department: 'Human Resources & People Operations',
    position: 'Talent Acquisition Partner',
    acknowledged_at: null, // Pending compliance
    state: 'active'
  },
  {
    id: 4,
    announcement_id: 21,
    employee_id: 124,
    employee_name: 'Almaz Kebede Desta',
    employee_code: 'EMP-00124',
    employee_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    department: 'Finance & Accounting Division',
    position: 'Senior Accountant',
    acknowledged_at: '2026-07-04T11:20:00Z',
    state: 'active'
  },
  {
    id: 5,
    announcement_id: 21,
    employee_id: 12,
    employee_name: 'Abebe Kebede Wolde',
    employee_code: 'EMP-0012',
    employee_avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    department: 'Retail Operations & Sales',
    position: 'Head of Retail',
    acknowledged_at: '2026-07-02T14:10:00Z',
    state: 'active'
  },
  {
    id: 6,
    announcement_id: 21,
    employee_id: 18,
    employee_name: 'Kidst Tesfaye Girma',
    employee_code: 'EMP-0018',
    employee_avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
    department: 'Retail Operations & Sales',
    position: 'Senior Store Manager',
    acknowledged_at: null, // Pending
    state: 'active'
  },
  {
    id: 7,
    announcement_id: 21,
    employee_id: 44,
    employee_name: 'Dawit Tadesse Mengistu',
    employee_code: 'EMP-0044',
    employee_avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80',
    department: 'Internal Audit & Risk',
    position: 'Lead Internal Auditor',
    acknowledged_at: '2026-07-05T08:45:00Z',
    state: 'active'
  },
  // For Announcement 23 (New Leave Policy FY2027)
  {
    id: 8,
    announcement_id: 23,
    employee_id: 22,
    employee_name: 'Hana Mesfin Tadesse',
    employee_code: 'EMP-0022',
    employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    department: 'Finance & Accounting Division',
    position: 'Senior Financial Analyst',
    acknowledged_at: '2026-07-09T10:05:00Z',
    state: 'active'
  },
  {
    id: 9,
    announcement_id: 23,
    employee_id: 44,
    employee_name: 'Dawit Tadesse Mengistu',
    employee_code: 'EMP-0044',
    employee_avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80',
    department: 'Internal Audit & Risk',
    position: 'Lead Internal Auditor',
    acknowledged_at: '2026-07-08T14:30:00Z',
    state: 'active'
  },
  {
    id: 10,
    announcement_id: 23,
    employee_id: 15,
    employee_name: 'Yared Alemu Kassaye',
    employee_code: 'EMP-0015',
    employee_avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
    department: 'Information Technology',
    position: 'Network Infrastructure Lead',
    acknowledged_at: null, // Pending
    state: 'active'
  }
];

export const acknowledgmentsData = ref<AnnouncementAcknowledgment[]>([...seedAcknowledgments]);

// ─── SEED ANNOUNCEMENTS (Directly from Section 13 Schema lines 3695-3720) ─
export const seedAnnouncements: AnnouncementRecord[] = [
  {
    id: 21,
    uuid: 'hra-2026-0021-9981',
    code: 'HRA-2026-0021',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Corporate Headquarters',
    title: 'Updated Occupational Health & Safety Emergency Protocols',
    body: `<p>Dear Team,</p>
<p>In accordance with statutory labor safety regulations and our annual compliance audit, management has revised our <strong>Occupational Health & Safety (OHS) Standard Operating Procedures</strong> across all operating branches.</p>
<p>Key highlights include:</p>
<ul>
  <li>Mandatory fire drill participation scheduled bi-annually.</li>
  <li>Updated emergency evacuation muster points for all facility floors.</li>
  <li>Mandatory personal protective equipment (PPE) compliance in warehouse and inventory transit zones.</li>
  <li>Designated first-aid responders and direct safety helpline: <strong>Ext. 4400</strong>.</li>
</ul>
<p>Please review the full attached safety guidelines document. <strong>All staff members are required to electronically sign and acknowledge receipt of this policy notice no later than 15 July 2026.</strong></p>`,
    audience: 'all',
    target_summary: 'All Employees (Company-Wide)',
    targets: [],
    publish_from: '2026-07-01T06:00:00Z',
    publish_to: null,
    requires_acknowledgment: true,
    acknowledgment_deadline: '2026-07-15',
    announcement_state: 'published',
    published_by_employee_id: 14,
    published_by_name: 'Solomon Bekele Worku',
    published_by_role: 'Director of Human Resources',
    user_id: 7,
    state: 'active',
    created_at: '2026-06-30T10:00:00Z'
  },
  {
    id: 22,
    uuid: 'hra-2026-0022-7742',
    code: 'HRA-2026-0022',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Corporate Headquarters',
    title: 'Meskel Holiday Observance & Corporate Office Closure',
    body: `<p>Dear Colleagues,</p>
<p>Haleta Management wishes you and your families a joyous and peaceful <strong>Meskel Holiday celebration</strong>.</p>
<p>Please note that all corporate administrative offices, retail branches, and logistics centers will observe public holiday closure on <strong>Monday, 28 September 2026</strong>. Normal operations will resume on Tuesday, 29 September 2026 at 08:30 AM.</p>
<p>Critical on-duty security and facilities personnel will operate under holiday shift schedules as coordinated by their unit supervisors.</p>`,
    audience: 'all',
    target_summary: 'All Employees (Company-Wide)',
    targets: [],
    publish_from: '2026-09-20T06:00:00Z',
    publish_to: '2026-09-29T18:00:00Z',
    requires_acknowledgment: false,
    acknowledgment_deadline: null,
    announcement_state: 'scheduled',
    published_by_employee_id: 14,
    published_by_name: 'Solomon Bekele Worku',
    published_by_role: 'Director of Human Resources',
    user_id: 7,
    state: 'active',
    created_at: '2026-09-18T14:30:00Z'
  },
  {
    id: 23,
    uuid: 'hra-2026-0023-5519',
    code: 'HRA-2026-0023',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Corporate Headquarters',
    title: 'New Leave Policy & Statutory Rest Guidelines FY2027',
    body: `<p>Dear Employees,</p>
<p>The People & Culture Directorate has published the updated <strong>FY2027 Comprehensive Leave Policy</strong>. This policy introduces enhanced maternity/paternity allowances, streamlined annual leave carry-forward caps, and self-service online leave encashment workflows.</p>
<p>Employees are requested to read the policy handbook attached and acknowledge receipt through your employee portal.</p>`,
    audience: 'all',
    target_summary: 'All Employees (Company-Wide)',
    targets: [],
    publish_from: '2026-07-08T06:00:00Z',
    publish_to: null,
    requires_acknowledgment: true,
    acknowledgment_deadline: '2026-07-31',
    announcement_state: 'published',
    published_by_employee_id: 14,
    published_by_name: 'Solomon Bekele Worku',
    published_by_role: 'Director of Human Resources',
    user_id: 7,
    state: 'active',
    created_at: '2026-07-07T09:15:00Z'
  },
  {
    id: 24,
    uuid: 'hra-2026-0024-3321',
    code: 'HRA-2026-0024',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Corporate Headquarters',
    title: 'Finance & Accounts Month-End General Ledger Freeze',
    body: `<p>Attention Finance & Accounting Team Members,</p>
<p>In preparation for quarterly financial statements consolidation and internal audit review, the ERP general ledger posting window will undergo a strict system freeze starting <strong>25 July 2026 at 18:00 PM</strong>.</p>
<p>All expense claims, purchase invoice accruals, and inter-unit cost center transfers must be submitted and approved before the freeze window begins.</p>`,
    audience: 'organization_unit',
    target_summary: 'Finance & Accounting Division (Unit #2)',
    targets: [
      {
        id: 1,
        announcement_id: 24,
        target_type: 'organization_unit',
        organization_unit_id: 2,
        unit_name: 'Finance & Accounting Division',
        state: 'active'
      }
    ],
    publish_from: '2026-07-25T06:00:00Z',
    publish_to: '2026-08-01T18:00:00Z',
    requires_acknowledgment: false,
    acknowledgment_deadline: null,
    announcement_state: 'published',
    published_by_employee_id: 22,
    published_by_name: 'Hana Mesfin Tadesse',
    published_by_role: 'Finance Manager',
    user_id: 7,
    state: 'active',
    created_at: '2026-07-24T16:00:00Z'
  },
  {
    id: 25,
    uuid: 'hra-2026-0025-1194',
    code: 'HRA-2026-0025',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa Branch',
    title: 'Frontline Cashier Uniform & Customer Service Excellence Protocol',
    body: `<p>To all Store Cashiers and Customer Service Representatives,</p>
<p>A new uniform standard and frontline customer interaction protocol takes effect on 1 August 2026. Staff must review the grooming standards, badge presentation requirements, and cash handling reconciliation checklist.</p>
<p>Mandatory supervisor inspection will occur each morning before counter opening.</p>`,
    audience: 'position',
    target_summary: 'Retail Cashiers & POS Operators (Position #24)',
    targets: [
      {
        id: 2,
        announcement_id: 25,
        target_type: 'job_position',
        job_position_id: 24,
        position_name: 'Frontline Cashier',
        state: 'active'
      }
    ],
    publish_from: '2026-08-01T06:00:00Z',
    publish_to: null,
    requires_acknowledgment: true,
    acknowledgment_deadline: '2026-08-20',
    announcement_state: 'draft',
    published_by_employee_id: null,
    published_by_name: null,
    published_by_role: null,
    user_id: 7,
    state: 'active',
    created_at: '2026-07-28T11:45:00Z'
  },
  {
    id: 26,
    uuid: 'hra-2026-0026-8802',
    code: 'HRA-2026-0026',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Corporate Headquarters',
    title: 'FY2027 Q2 All-Hands Strategy Townhall & Executive Q&A',
    body: `<p>Dear Haleta Team,</p>
<p>You are cordially invited to our quarterly All-Hands Strategy Townhall hosted by the Executive Board on <strong>Thursday, 5 November 2026 at 10:00 AM</strong>.</p>
<p>We will present our regional expansion progress, review company KPIs, and conduct an open floor live Q&A session with leadership. Light refreshments will be served in the main auditorium; remote branch colleagues can join via live stream.</p>`,
    audience: 'all',
    target_summary: 'All Employees (Company-Wide)',
    targets: [],
    publish_from: '2026-11-05T07:00:00Z',
    publish_to: '2026-11-06T18:00:00Z',
    requires_acknowledgment: false,
    acknowledgment_deadline: null,
    announcement_state: 'scheduled',
    published_by_employee_id: 14,
    published_by_name: 'Solomon Bekele Worku',
    published_by_role: 'Director of Human Resources',
    user_id: 7,
    state: 'active',
    created_at: '2026-10-20T15:00:00Z'
  }
];

export const announcementsData = ref<AnnouncementRecord[]>([...seedAnnouncements]);

// ─── HELPER FUNCTIONS ─────────────────────────────────────────────────────

export const getAnnouncementAcknowledgmentStats = (announcementId: number) => {
  const acks = acknowledgmentsData.value.filter(a => a.announcement_id === announcementId);
  const total = acks.length || 40; // Simulated targeted pool (e.g. 40 employees)
  const confirmed = acks.filter(a => a.acknowledged_at !== null).length;
  const rate = total > 0 ? Math.round((confirmed / total) * 100) : 0;
  return {
    total,
    confirmed,
    pending: total - confirmed,
    rate
  };
};

export const createAnnouncement = (
  record: Omit<AnnouncementRecord, 'id' | 'uuid' | 'code' | 'created_at'>
): AnnouncementRecord => {
  const newId = (Math.max(...announcementsData.value.map(a => a.id), 26) + 1);
  const newRecord: AnnouncementRecord = {
    ...record,
    id: newId,
    uuid: `hra-2026-${String(newId).padStart(4, '0')}-${Date.now().toString(36)}`,
    code: `HRA-2026-${String(newId).padStart(4, '0')}`,
    created_at: new Date().toISOString()
  };

  announcementsData.value.unshift(newRecord);
  return newRecord;
};

export const updateAnnouncement = (id: number, updates: Partial<AnnouncementRecord>) => {
  const item = announcementsData.value.find(a => a.id === id);
  if (item) {
    Object.assign(item, updates);
    return item;
  }
  return null;
};

export const updateAnnouncementState = (
  id: number,
  state: AnnouncementState,
  publishedByName?: string
) => {
  const item = announcementsData.value.find(a => a.id === id);
  if (item) {
    item.announcement_state = state;
    if (state === 'published') {
      item.published_by_name = publishedByName || 'Solomon Bekele Worku';
      item.published_by_role = 'Director of Human Resources';
      item.publish_from = new Date().toISOString();
    }
    return item;
  }
  return null;
};

export const deleteAnnouncement = (id: number) => {
  const idx = announcementsData.value.findIndex(a => a.id === id);
  if (idx !== -1) {
    announcementsData.value.splice(idx, 1);
    return true;
  }
  return false;
};

export const acknowledgeNotice = (announcementId: number, employeeId: number) => {
  const ack = acknowledgmentsData.value.find(
    a => a.announcement_id === announcementId && a.employee_id === employeeId
  );
  if (ack) {
    ack.acknowledged_at = new Date().toISOString();
    return ack;
  } else {
    const newAck: AnnouncementAcknowledgment = {
      id: acknowledgmentsData.value.length + 1,
      announcement_id: announcementId,
      employee_id: employeeId,
      employee_name: 'Current Logged-in Employee',
      employee_code: 'EMP-ME',
      employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      department: 'Corporate Staff',
      position: 'Staff Member',
      acknowledged_at: new Date().toISOString(),
      state: 'active'
    };
    acknowledgmentsData.value.push(newAck);
    return newAck;
  }
};
