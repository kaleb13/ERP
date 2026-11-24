import { ref } from 'vue';
import type { BadgeColor } from '../../components/BaseBadge.vue';

export type RowState = 'active' | 'inactive';

// ─── Authoritative Schema Lookup: PROCUREMENT_COMMITTEE_PURPOSE (procurement-v4.sql Lines 139–140, 526) ───
export type ProcurementCommitteePurpose =
  | 'bid_opening'
  | 'technical_evaluation'
  | 'financial_evaluation'
  | 'combined_evaluation'
  | 'award_review'
  | 'inspection'
  | 'contract_negotiation';

export interface ProcurementCommitteeMandateRecord {
  id: number;
  uuid: string;
  committee_id: number; // XFK Committee
  committee_code: string;
  committee_name: string;
  committee_chair: string;
  committee_member_count: number;
  purpose: ProcurementCommitteePurpose; // purpose_lookup_value_id
  quorum: number; // smallint -- signed members needed for the event to count
  minimum_amount: number | null; // numeric(18,4) nullable -- NULL = no floor
  maximum_amount: number | null; // numeric(18,4) nullable -- NULL = no limit
  currency_code: string;
  procurement_unit_id: number | null; // FK ProcurementUnit nullable -- NULL = all
  unit_name?: string;
  procurement_category_id: number | null; // FK ProcurementCategory nullable -- NULL = all
  category_name?: string;
  effective_from: string; // date YYYY-MM-DD
  effective_to: string | null; // date nullable -- NULL = still in force
  entity_id: number; // XFK Entity
  notes?: string;
  state: RowState;
}

// ─── Purpose Lookup Options (PROCUREMENT_COMMITTEE_PURPOSE) ───
export const committeePurposeOptions: {
  value: ProcurementCommitteePurpose;
  label: string;
  badgeColor: BadgeColor;
}[] = [
  { value: 'bid_opening', label: 'Bid Opening', badgeColor: 'primary' },
  { value: 'technical_evaluation', label: 'Technical Evaluation', badgeColor: 'indigo' },
  { value: 'financial_evaluation', label: 'Financial Evaluation', badgeColor: 'blue' },
  { value: 'combined_evaluation', label: 'Combined Evaluation', badgeColor: 'purple' },
  { value: 'award_review', label: 'Award Review', badgeColor: 'warning' },
  { value: 'inspection', label: 'Inspection', badgeColor: 'blue' },
  { value: 'contract_negotiation', label: 'Contract Negotiation', badgeColor: 'indigo' }
];

export const getPurposeLabel = (purpose: ProcurementCommitteePurpose): string => {
  return committeePurposeOptions.find((o) => o.value === purpose)?.label ?? purpose;
};

export const getPurposeBadgeColor = (purpose: ProcurementCommitteePurpose): BadgeColor => {
  return committeePurposeOptions.find((o) => o.value === purpose)?.badgeColor ?? 'blue';
};

// ─── Core Committees (XFK Committee) ───
export interface CoreCommitteeOption {
  value: string;
  label: string;
  code: string;
  name: string;
  chair: string;
  memberCount: number;
}

export const coreCommitteeOptions: CoreCommitteeOption[] = [
  {
    value: '31',
    label: 'Tender Committee (COM-TND-031)',
    code: 'COM-TND-031',
    name: 'Tender Committee',
    chair: 'Amanuel Tesfaye',
    memberCount: 5
  },
  {
    value: '32',
    label: 'Technical Panel (COM-TEC-032)',
    code: 'COM-TEC-032',
    name: 'Technical Panel',
    chair: 'Dr. Selamawit Bekele',
    memberCount: 5
  },
  {
    value: '33',
    label: 'Receiving Panel (COM-RCV-033)',
    code: 'COM-RCV-033',
    name: 'Receiving Panel',
    chair: 'Dawit Mekonnen',
    memberCount: 4
  },
  {
    value: '34',
    label: 'Management Committee (COM-MGT-034)',
    code: 'COM-MGT-034',
    name: 'Management Committee',
    chair: 'Hanna Girma',
    memberCount: 7
  },
  {
    value: '35',
    label: 'Financial Evaluation Board (COM-FIN-035)',
    code: 'COM-FIN-035',
    name: 'Financial Evaluation Board',
    chair: 'Bereket Alemu',
    memberCount: 4
  },
  {
    value: '36',
    label: 'Contract Negotiation Committee (COM-CNT-036)',
    code: 'COM-CNT-036',
    name: 'Contract Negotiation Committee',
    chair: 'Mekdes Tadesse',
    memberCount: 5
  }
];

export const getCoreCommittee = (committeeId: number): CoreCommitteeOption | undefined => {
  return coreCommitteeOptions.find((c) => Number(c.value) === committeeId);
};

// ─── Procurement Category Scope Options (FK ProcurementCategory) ───
export const categoryScopeOptions = [
  { value: '10', label: 'Food & Beverage' },
  { value: '11', label: 'Perishables' },
  { value: '20', label: 'Kitchen Equipment' },
  { value: '30', label: 'Cleaning Services' },
  { value: '50', label: 'Office Consumables' }
];

// ─── Procurement Unit Scope Options (FK ProcurementUnit) ───
export const unitScopeOptions = [
  { value: '1', label: 'Central Procurement Unit' },
  { value: '2', label: 'Branch Buying Desk' },
  { value: '3', label: 'Le Spa Buying Desk' }
];

// ─── Legal Entity Options (XFK Entity) ───
export const entityOptions = [
  { value: '2', label: 'Haleta General Hospital (HQ Entity)' },
  { value: '3', label: 'Haleta Pharmaceuticals Branch' },
  { value: '6', label: 'Haleta Wellness Center' }
];

export const getEntityName = (entityId: number): string => {
  return entityOptions.find((e) => Number(e.value) === entityId)?.label ?? `Entity #${entityId}`;
};

export const formatAmountBand = (
  min: number | null,
  max: number | null,
  currency = 'ETB'
): string => {
  const fmt = (val: number) =>
    new Intl.NumberFormat('en-US', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2
    }).format(val);

  if (min === null && max === null) return 'All Values';
  if (min !== null && max === null) {
    return min === 0 ? `${currency} 0 – Unlimited` : `${currency} ${fmt(min)}+`;
  }
  if (min === null && max !== null) {
    return `Up to ${currency} ${fmt(max)}`;
  }
  return `${currency} ${fmt(min!)} – ${fmt(max!)}`;
};

import { formatDisplayDate } from '../../utils/dateFormat';

export const formatEffectivePeriod = (from: string, to: string | null): string => {
  const start = formatDisplayDate(from);
  return to ? `${start} → ${formatDisplayDate(to)}` : `${start} → Open-ended`;
};

// ─── Initial Seed Data (procurement-v4.sql Lines 536–543) ───
export const initialCommitteeMandates: ProcurementCommitteeMandateRecord[] = [
  {
    id: 1,
    uuid: 'pcm-0001-bid-opening',
    committee_id: 31,
    committee_code: 'COM-TND-031',
    committee_name: 'Tender Committee',
    committee_chair: 'Amanuel Tesfaye',
    committee_member_count: 5,
    purpose: 'bid_opening',
    quorum: 3,
    minimum_amount: 0,
    maximum_amount: null,
    currency_code: 'ETB',
    procurement_unit_id: null,
    procurement_category_id: null,
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    notes:
      'Presides over public sealed-bid openings across all procurement categories and buying units. At least 3 signed committee members must witness and countersign the bid opening minutes.',
    state: 'active'
  },
  {
    id: 2,
    uuid: 'pcm-0002-tech-eval-capex',
    committee_id: 32,
    committee_code: 'COM-TEC-032',
    committee_name: 'Technical Panel',
    committee_chair: 'Dr. Selamawit Bekele',
    committee_member_count: 5,
    purpose: 'technical_evaluation',
    quorum: 3,
    minimum_amount: 0,
    maximum_amount: null,
    currency_code: 'ETB',
    procurement_unit_id: null,
    procurement_category_id: 20,
    category_name: 'Kitchen Equipment',
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    notes:
      'Conducts technical specification compliance scoring and vendor capability assessment for capital kitchen equipment tenders prior to financial envelope opening.',
    state: 'active'
  },
  {
    id: 3,
    uuid: 'pcm-0003-inspection-perishables',
    committee_id: 33,
    committee_code: 'COM-RCV-033',
    committee_name: 'Receiving Panel',
    committee_chair: 'Dawit Mekonnen',
    committee_member_count: 4,
    purpose: 'inspection',
    quorum: 2,
    minimum_amount: 0,
    maximum_amount: null,
    currency_code: 'ETB',
    procurement_unit_id: 2,
    unit_name: 'Branch Buying Desk',
    procurement_category_id: 11,
    category_name: 'Perishables',
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    notes:
      'Performs mandatory physical quality, cold-chain temperature, and expiry inspection on perishable deliveries received by the Branch Buying Desk before GRN acceptance.',
    state: 'active'
  },
  {
    id: 4,
    uuid: 'pcm-0004-award-review-high',
    committee_id: 34,
    committee_code: 'COM-MGT-034',
    committee_name: 'Management Committee',
    committee_chair: 'Hanna Girma',
    committee_member_count: 7,
    purpose: 'award_review',
    quorum: 4,
    minimum_amount: 500000,
    maximum_amount: null,
    currency_code: 'ETB',
    procurement_unit_id: null,
    procurement_category_id: null,
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    notes:
      'Final award review and executive endorsement required for all procurement awards meeting or exceeding ETB 500,000. Requires a minimum quorum of 4 signed executives.',
    state: 'active'
  },
  {
    id: 5,
    uuid: 'pcm-0005-financial-eval',
    committee_id: 35,
    committee_code: 'COM-FIN-035',
    committee_name: 'Financial Evaluation Board',
    committee_chair: 'Bereket Alemu',
    committee_member_count: 4,
    purpose: 'financial_evaluation',
    quorum: 3,
    minimum_amount: 100000,
    maximum_amount: 500000,
    currency_code: 'ETB',
    procurement_unit_id: 1,
    unit_name: 'Central Procurement Unit',
    procurement_category_id: null,
    effective_from: '2026-07-01',
    effective_to: null,
    entity_id: 2,
    notes:
      'Evaluates commercial pricing, total cost of ownership, tax implications, and payment terms for Central Procurement Unit RFQs and mid-tier tenders between ETB 100,000 and ETB 500,000.',
    state: 'active'
  },
  {
    id: 6,
    uuid: 'pcm-0006-contract-negotiation',
    committee_id: 36,
    committee_code: 'COM-CNT-036',
    committee_name: 'Contract Negotiation Committee',
    committee_chair: 'Mekdes Tadesse',
    committee_member_count: 5,
    purpose: 'contract_negotiation',
    quorum: 3,
    minimum_amount: 250000,
    maximum_amount: null,
    currency_code: 'ETB',
    procurement_unit_id: null,
    procurement_category_id: 30,
    category_name: 'Cleaning Services',
    effective_from: '2026-01-01',
    effective_to: '2026-06-30',
    entity_id: 2,
    notes:
      'Negotiates SLA penalties, renewal caps, and annual service contract terms for multi-year facility service agreements.',
    state: 'inactive'
  }
];

export const committeeMandatesStore = ref<ProcurementCommitteeMandateRecord[]>(
  initialCommitteeMandates.map((item) => ({ ...item }))
);

