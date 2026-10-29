import { ref } from 'vue';

export type ClientAssignmentState =
  | 'draft'
  | 'active'
  | 'completed'
  | 'recalled'
  | 'terminated';

export interface PayslipCostAllocationRecord {
  id: number;
  uuid: string;
  tenant_id: number;
  entity_id: number;
  payslip_id: number;
  payslip_number: string;
  target_entity_id: number | null;
  target_entity_name: string | null;
  organization_unit_id: number | null;
  organization_unit_name: string | null;
  client_assignment_id: number | null;
  percent: number | null; // numeric(7,4)
  amount: number | null; // numeric(15,4)
  order: number;
  state: 'active' | 'inactive';
}

export interface ClientAssignmentRecord {
  id: number;
  uuid: string;
  code: string; // DocumentSequence (CAS-2026-0041)
  tenant_id: number;
  employee_id: number; // FK Employee -- legal employment stays with provider
  employee_code: string;
  employee_name: string;
  hr_service_agreement_id: number; // FK HRServiceAgreement -- carries client & payroll resp
  hr_service_agreement_code: string;
  client_party_id: number; // Denormalized from agreement for fast querying
  client_party_name: string;
  is_tenant_client: boolean; // Computed from agreement (whether client is Haleta tenant)
  client_branch_entity_id: number | null; // FK Entity (tenant clients only)
  client_branch_name: string | null;
  client_organization_unit_id: number | null; // FK OrganizationUnit (tenant clients only)
  client_organization_unit_name: string | null;
  client_position_id: number | null; // FK JobPosition (tenant clients only)
  client_position_name: string | null;
  client_role_title: string | null; // Verbatim role at external client (e.g. Claims Clerk, Site Cleaner)
  duty_station_admin_unit_id: number | null; // FK AdminUnit -- physical location
  duty_station_name: string | null;
  assignment_state_lookup_value_id: ClientAssignmentState;
  start_date: string;
  end_date: string | null; // NULL = current / ongoing
  notes: string | null;
  cost_allocations?: PayslipCostAllocationRecord[];
  user_id: number;
  state: 'active' | 'inactive';
  created_at: string;
}

// ─── AUTHORITATIVE SEED RECORDS (HR Schema Designer 1.sql lines 2332-2338) ──
export const seedClientAssignments: ClientAssignmentRecord[] = [
  {
    id: 41,
    uuid: 'cas-uuid-0041',
    code: 'CAS-2026-0041',
    tenant_id: 1,
    employee_id: 61,
    employee_code: 'EMP-0061',
    employee_name: 'Abebe Kebede Wolde',
    hr_service_agreement_id: 3,
    hr_service_agreement_code: 'HSA-2026-0003',
    client_party_id: 940,
    client_party_name: 'Haleta Retail Group S.C.',
    is_tenant_client: true,
    client_branch_entity_id: 7,
    client_branch_name: 'Bole Branch (Entity #7)',
    client_organization_unit_id: 14,
    client_organization_unit_name: 'Store Frontline Operations',
    client_position_id: 24,
    client_position_name: 'Senior POS Cashier',
    client_role_title: null,
    duty_station_admin_unit_id: 315,
    duty_station_name: 'Bole Sub-City, Addis Ababa (AdminUnit #315)',
    assignment_state_lookup_value_id: 'completed',
    start_date: '2026-01-05',
    end_date: '2026-06-30',
    notes: 'Completed initial 6-month retail staffing deployment at Bole branch. Transitioned to Nyala Insurance placement.',
    cost_allocations: [
      {
        id: 1,
        uuid: 'pca-uuid-0001',
        tenant_id: 1,
        entity_id: 20,
        payslip_id: 7755,
        payslip_number: 'PAY-2026-01-0061',
        target_entity_id: null,
        target_entity_name: null,
        organization_unit_id: null,
        organization_unit_name: null,
        client_assignment_id: 41,
        percent: 100.0,
        amount: null,
        order: 1,
        state: 'active'
      }
    ],
    user_id: 7,
    state: 'active',
    created_at: '2025-12-28T09:00:00Z'
  },
  {
    id: 42,
    uuid: 'cas-uuid-0042',
    code: 'CAS-2026-0042',
    tenant_id: 1,
    employee_id: 61,
    employee_code: 'EMP-0061',
    employee_name: 'Abebe Kebede Wolde',
    hr_service_agreement_id: 4,
    hr_service_agreement_code: 'HSA-2026-0004',
    client_party_id: 960,
    client_party_name: 'Nyala Insurance Share Company',
    is_tenant_client: false,
    client_branch_entity_id: null,
    client_branch_name: null,
    client_organization_unit_id: null,
    client_organization_unit_name: null,
    client_position_id: null,
    client_position_name: null,
    client_role_title: 'Claims Clerk',
    duty_station_admin_unit_id: 305,
    duty_station_name: 'Kirkos Sub-City, Addis Ababa (AdminUnit #305)',
    assignment_state_lookup_value_id: 'active',
    start_date: '2026-07-01',
    end_date: null, // Current / Ongoing
    notes: 'External client EOR placement. Assigned to underwriting claims verification desk at Nyala HQ.',
    cost_allocations: [
      {
        id: 2,
        uuid: 'pca-uuid-0002',
        tenant_id: 1,
        entity_id: 20,
        payslip_id: 7762,
        payslip_number: 'PAY-2026-07-0061',
        target_entity_id: null,
        target_entity_name: null,
        organization_unit_id: null,
        organization_unit_name: null,
        client_assignment_id: 42,
        percent: 100.0,
        amount: null,
        order: 1,
        state: 'active'
      }
    ],
    user_id: 7,
    state: 'active',
    created_at: '2026-06-25T14:30:00Z'
  },
  {
    id: 43,
    uuid: 'cas-uuid-0043',
    code: 'CAS-2026-0043',
    tenant_id: 1,
    employee_id: 62,
    employee_code: 'EMP-0062',
    employee_name: 'Almaz Tefera Desta',
    hr_service_agreement_id: 3,
    hr_service_agreement_code: 'HSA-2026-0003',
    client_party_id: 940,
    client_party_name: 'Haleta Retail Group S.C.',
    is_tenant_client: true,
    client_branch_entity_id: 9,
    client_branch_name: 'Bahir Dar Branch (Entity #9)',
    client_organization_unit_id: 14,
    client_organization_unit_name: 'Store Frontline Operations',
    client_position_id: 24,
    client_position_name: 'Senior POS Cashier',
    client_role_title: null,
    duty_station_admin_unit_id: 401,
    duty_station_name: 'Bahir Dar Central, Amhara (AdminUnit #401)',
    assignment_state_lookup_value_id: 'active',
    start_date: '2026-02-01',
    end_date: null, // Current / Ongoing
    notes: 'Leased cashier deployed at Bahir Dar flagship store. Payroll reimbursed by Haleta Retail Group + 8% fee.',
    cost_allocations: [],
    user_id: 7,
    state: 'active',
    created_at: '2026-01-20T10:15:00Z'
  },
  {
    id: 44,
    uuid: 'cas-uuid-0044',
    code: 'CAS-2026-0044',
    tenant_id: 1,
    employee_id: 63,
    employee_code: 'EMP-0063',
    employee_name: 'Dawit Tadesse Mengistu',
    hr_service_agreement_id: 5,
    hr_service_agreement_code: 'HSA-2026-0005',
    client_party_id: 961,
    client_party_name: 'Habesha Breweries S.C.',
    is_tenant_client: false,
    client_branch_entity_id: null,
    client_branch_name: null,
    client_organization_unit_id: null,
    client_organization_unit_name: null,
    client_position_id: null,
    client_position_name: null,
    client_role_title: 'Site Cleaner',
    duty_station_admin_unit_id: 320,
    duty_station_name: 'Debre Birhan Industrial Park (AdminUnit #320)',
    assignment_state_lookup_value_id: 'active',
    start_date: '2026-02-15',
    end_date: null, // Current / Ongoing
    notes: 'Facility maintenance and industrial cleaning staff at Debre Birhan plant. Governed by 45,000 ETB monthly retainer agreement.',
    cost_allocations: [],
    user_id: 7,
    state: 'active',
    created_at: '2026-02-10T11:45:00Z'
  },
  {
    id: 45,
    uuid: 'cas-uuid-0045',
    code: 'CAS-2025-0045',
    tenant_id: 1,
    employee_id: 62,
    employee_code: 'EMP-0062',
    employee_name: 'Almaz Tefera Desta',
    hr_service_agreement_id: 6,
    hr_service_agreement_code: 'HSA-2025-0006',
    client_party_id: 940,
    client_party_name: 'Haleta Retail Group S.C.',
    is_tenant_client: true,
    client_branch_entity_id: 12,
    client_branch_name: 'Piazza Shop (Entity #12)',
    client_organization_unit_id: 14,
    client_organization_unit_name: 'Store Frontline Operations',
    client_position_id: 24,
    client_position_name: 'Senior POS Cashier',
    client_role_title: null,
    duty_station_admin_unit_id: 320,
    duty_station_name: 'Arada Sub-City, Addis Ababa (AdminUnit #320)',
    assignment_state_lookup_value_id: 'completed',
    start_date: '2025-03-01',
    end_date: '2025-12-31',
    notes: 'Prior year staffing agreement assignment. Concluded successfully upon annual contract expiration.',
    cost_allocations: [],
    user_id: 7,
    state: 'active',
    created_at: '2025-02-20T16:00:00Z'
  }
];

// ─── REACTIVE STATE STORE ─────────────────────────────────────────────────
export const clientAssignmentsData = ref<ClientAssignmentRecord[]>([...seedClientAssignments]);

// ─── CRUD & WORKFLOW ACTIONS ──────────────────────────────────────────────
export const createClientAssignment = (
  payload: Omit<ClientAssignmentRecord, 'id' | 'uuid' | 'code' | 'created_at'>
): ClientAssignmentRecord => {
  const nextId = clientAssignmentsData.value.length > 0
    ? Math.max(...clientAssignmentsData.value.map(a => a.id)) + 1
    : 46;

  const currentYear = new Date().getFullYear();
  const sequenceStr = String(nextId).padStart(4, '0');
  const code = `CAS-${currentYear}-${sequenceStr}`;

  const newRecord: ClientAssignmentRecord = {
    ...payload,
    id: nextId,
    uuid: `cas-uuid-${sequenceStr}`,
    code,
    created_at: new Date().toISOString()
  };

  clientAssignmentsData.value.unshift(newRecord);
  return newRecord;
};

export const updateClientAssignment = (
  id: number,
  payload: Partial<ClientAssignmentRecord>
): boolean => {
  const idx = clientAssignmentsData.value.findIndex(a => a.id === id);
  if (idx === -1) return false;

  clientAssignmentsData.value[idx] = {
    ...clientAssignmentsData.value[idx],
    ...payload
  };
  return true;
};

export const updateAssignmentState = (
  id: number,
  state: ClientAssignmentState
): boolean => {
  const item = clientAssignmentsData.value.find(a => a.id === id);
  if (!item) return false;
  item.assignment_state_lookup_value_id = state;
  return true;
};

export const deleteClientAssignment = (id: number): boolean => {
  const idx = clientAssignmentsData.value.findIndex(a => a.id === id);
  if (idx === -1) return false;
  clientAssignmentsData.value.splice(idx, 1);
  return true;
};
