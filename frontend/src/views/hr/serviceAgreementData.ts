import { ref } from 'vue';

export type AgreementType =
  | 'staffing'
  | 'outsourcing'
  | 'employer_of_record'
  | 'secondment_out'
  | 'consultancy';

export type AgreementState =
  | 'draft'
  | 'pending_approval'
  | 'active'
  | 'suspended'
  | 'expired'
  | 'terminated';

export type PayrollResponsibility =
  | 'employer_pays'
  | 'client_funds_employer_pays'
  | 'client_pays_directly';

export type ServiceFeeType =
  | 'percent_of_payroll'
  | 'fixed_per_employee'
  | 'fixed_monthly'
  | 'markup_percent';

export interface HRServiceAgreementRecord {
  id: number;
  uuid: string;
  code: string; // DocumentSequence (HSA-2026-0003)
  tenant_id: number;
  provider_entity_id: number;
  provider_name: string;
  client_party_id: number;
  client_party_name: string;
  client_entity_id: number | null; // Set ONLY when client is a Haleta tenant
  client_entity_name: string | null;
  agreement_type_lookup_value_id: AgreementType;
  agreement_state_lookup_value_id: AgreementState;
  start_date: string;
  end_date: string | null; // NULL = open-ended
  max_employees: number | null; // NULL = uncapped
  payroll_responsibility_lookup_value_id: PayrollResponsibility;
  service_fee_type_lookup_value_id: ServiceFeeType | null;
  service_fee_value: number | null;
  billing_currency_id: number;
  billing_currency_code: string;
  notes: string | null;
  user_id: number;
  state: 'active' | 'inactive';
  created_at: string;
}

// ─── AUTHORITATIVE SEED RECORDS (HR Schema Designer 1.sql lines 2304-2310) ──
export const seedServiceAgreements: HRServiceAgreementRecord[] = [
  {
    id: 3,
    uuid: 'hsa-uuid-0003',
    code: 'HSA-2026-0003',
    tenant_id: 1,
    provider_entity_id: 20,
    provider_name: 'Selam Workforce Solutions Ltd.',
    client_party_id: 940,
    client_party_name: 'Haleta Retail Group S.C.',
    client_entity_id: 1,
    client_entity_name: 'Haleta Corporate Headquarters',
    agreement_type_lookup_value_id: 'staffing',
    agreement_state_lookup_value_id: 'active',
    start_date: '2026-01-01',
    end_date: '2026-12-31',
    max_employees: 30,
    payroll_responsibility_lookup_value_id: 'client_funds_employer_pays',
    service_fee_type_lookup_value_id: 'percent_of_payroll',
    service_fee_value: 8.0,
    billing_currency_id: 1,
    billing_currency_code: 'ETB',
    notes: 'Primary leased cashiers, frontline POS operators, and retail customer attendants deployed across Addis Ababa branches.',
    user_id: 7,
    state: 'active',
    created_at: '2025-12-15T09:00:00Z'
  },
  {
    id: 4,
    uuid: 'hsa-uuid-0004',
    code: 'HSA-2026-0004',
    tenant_id: 1,
    provider_entity_id: 20,
    provider_name: 'Selam Workforce Solutions Ltd.',
    client_party_id: 960,
    client_party_name: 'Nyala Insurance Share Company',
    client_entity_id: null, // External client
    client_entity_name: null,
    agreement_type_lookup_value_id: 'employer_of_record',
    agreement_state_lookup_value_id: 'active',
    start_date: '2026-03-01',
    end_date: null, // Open-ended
    max_employees: 15,
    payroll_responsibility_lookup_value_id: 'employer_pays',
    service_fee_type_lookup_value_id: 'fixed_per_employee',
    service_fee_value: 1500.0,
    billing_currency_id: 1,
    billing_currency_code: 'ETB',
    notes: 'Employer of record facility for underwriting claims clerks and field assessors. Billed monthly via provider Sales invoice.',
    user_id: 7,
    state: 'active',
    created_at: '2026-02-10T11:30:00Z'
  },
  {
    id: 5,
    uuid: 'hsa-uuid-0005',
    code: 'HSA-2026-0005',
    tenant_id: 1,
    provider_entity_id: 20,
    provider_name: 'Selam Workforce Solutions Ltd.',
    client_party_id: 961,
    client_party_name: 'Habesha Breweries S.C.',
    client_entity_id: null, // External client
    client_entity_name: null,
    agreement_type_lookup_value_id: 'outsourcing',
    agreement_state_lookup_value_id: 'active',
    start_date: '2026-02-01',
    end_date: '2027-01-31',
    max_employees: 25,
    payroll_responsibility_lookup_value_id: 'employer_pays',
    service_fee_type_lookup_value_id: 'fixed_monthly',
    service_fee_value: 45000.0,
    billing_currency_id: 1,
    billing_currency_code: 'ETB',
    notes: 'Outsourced warehouse logistics, industrial facility cleaning, and packaging operations staff at Debre Birhan plant.',
    user_id: 7,
    state: 'active',
    created_at: '2026-01-18T14:15:00Z'
  },
  {
    id: 6,
    uuid: 'hsa-uuid-0006',
    code: 'HSA-2025-0006',
    tenant_id: 1,
    provider_entity_id: 20,
    provider_name: 'Selam Workforce Solutions Ltd.',
    client_party_id: 940,
    client_party_name: 'Haleta Retail Group S.C.',
    client_entity_id: 1,
    client_entity_name: 'Haleta Corporate Headquarters',
    agreement_type_lookup_value_id: 'staffing',
    agreement_state_lookup_value_id: 'expired',
    start_date: '2025-01-01',
    end_date: '2025-12-31',
    max_employees: 20,
    payroll_responsibility_lookup_value_id: 'client_funds_employer_pays',
    service_fee_type_lookup_value_id: 'percent_of_payroll',
    service_fee_value: 7.0,
    billing_currency_id: 1,
    billing_currency_code: 'ETB',
    notes: 'Prior year staffing agreement for retail shop inventory assistants and cashiers. Superseded by HSA-2026-0003.',
    user_id: 7,
    state: 'active',
    created_at: '2024-12-10T10:00:00Z'
  },
  {
    id: 7,
    uuid: 'hsa-uuid-0007',
    code: 'HSA-2026-0007',
    tenant_id: 1,
    provider_entity_id: 1,
    provider_name: 'Haleta Corporate Headquarters',
    client_party_id: 962,
    client_party_name: 'Zafir Hotels & Resorts PLC',
    client_entity_id: null, // External client
    client_entity_name: null,
    agreement_type_lookup_value_id: 'secondment_out',
    agreement_state_lookup_value_id: 'pending_approval',
    start_date: '2026-09-01',
    end_date: '2027-08-31',
    max_employees: 5,
    payroll_responsibility_lookup_value_id: 'client_funds_employer_pays',
    service_fee_type_lookup_value_id: 'markup_percent',
    service_fee_value: 12.0,
    billing_currency_id: 1,
    billing_currency_code: 'ETB',
    notes: 'Executive secondment of senior hospitality systems implementation specialists and financial controllers.',
    user_id: 7,
    state: 'active',
    created_at: '2026-07-20T16:00:00Z'
  }
];

// ─── REACTIVE STATE STORE ─────────────────────────────────────────────────
export const serviceAgreementsData = ref<HRServiceAgreementRecord[]>([...seedServiceAgreements]);

// ─── CRUD & WORKFLOW ACTIONS ──────────────────────────────────────────────
export const createServiceAgreement = (
  payload: Omit<HRServiceAgreementRecord, 'id' | 'uuid' | 'code' | 'created_at'>
): HRServiceAgreementRecord => {
  const nextId = serviceAgreementsData.value.length > 0
    ? Math.max(...serviceAgreementsData.value.map(a => a.id)) + 1
    : 1;

  const currentYear = new Date().getFullYear();
  const sequenceStr = String(nextId).padStart(4, '0');
  const code = `HSA-${currentYear}-${sequenceStr}`;

  const newRecord: HRServiceAgreementRecord = {
    ...payload,
    id: nextId,
    uuid: `hsa-uuid-${sequenceStr}`,
    code,
    created_at: new Date().toISOString()
  };

  serviceAgreementsData.value.unshift(newRecord);
  return newRecord;
};

export const updateServiceAgreement = (
  id: number,
  payload: Partial<HRServiceAgreementRecord>
): boolean => {
  const idx = serviceAgreementsData.value.findIndex(a => a.id === id);
  if (idx === -1) return false;

  serviceAgreementsData.value[idx] = {
    ...serviceAgreementsData.value[idx],
    ...payload
  };
  return true;
};

export const updateAgreementState = (
  id: number,
  state: AgreementState
): boolean => {
  const item = serviceAgreementsData.value.find(a => a.id === id);
  if (!item) return false;
  item.agreement_state_lookup_value_id = state;
  return true;
};

export const deleteServiceAgreement = (id: number): boolean => {
  const idx = serviceAgreementsData.value.findIndex(a => a.id === id);
  if (idx === -1) return false;
  serviceAgreementsData.value.splice(idx, 1);
  return true;
};
