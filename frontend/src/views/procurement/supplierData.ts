import { ref } from 'vue';
import ethioTelecomLogo from '../../assets/ethio-telecom-logo.png';

/**
 * Supplier 360° Monitoring & Lifecycle data layer.
 * Schema source: procurement-v4.sql #3 (SupplierQualification, SupplierQualificationDocument,
 * SupplierProcurementCategory, SupplierStatusLog, SupplierRiskProfile, SupplierRiskEvent,
 * SupplierPriceList, SupplierPriceListItem, SupplierUser, SupplierChangeRequest)
 * + read-only summary from #11 (SupplierScorecard, SupplierImprovementAction).
 */

export type SupplierEligibilityStatus = 'active' | 'suspended' | 'blacklisted' | 'expired';
export type RiskLevel = 'low' | 'medium' | 'high' | 'critical';
export type ScorecardGrade = 'excellent' | 'satisfactory' | 'needs_improvement' | 'unsatisfactory';
export type DocumentReviewResult = 'pending' | 'compliant' | 'non_compliant' | 'waived';
export type RiskEventStatus = 'open' | 'mitigated' | 'closed';
export type PortalAccountStatus = 'invited' | 'active' | 'suspended' | 'revoked';
export type ChangeRequestStatus = 'draft' | 'submitted' | 'approved' | 'rejected';

export interface SupplierQualificationSummary {
  qualification_number: string;
  application_type: 'new' | 'renewal' | 'category_extension' | 'reinstatement';
  channel: 'internal' | 'supplier_portal';
  qualified_from: string;
  qualified_to: string;
  maximum_order_value: number | null;
  currency_id: string;
  status: 'approved' | 'submitted' | 'under_review' | 'expired';
  decided_by: string;
  decided_at: string;
}

export interface SupplierQualificationDocItem {
  id: number;
  document_type: string;
  reference_number: string;
  issued_at: string;
  expires_at: string | null;
  is_mandatory: boolean;
  review_result: DocumentReviewResult;
  verified_by: string | null;
}

export interface SupplierCategoryEligibility {
  id: number;
  category_name: string;
  category_code: string;
  is_preferred: boolean;
  minimum_order_value: number | null;
  approved_at: string;
  status: 'active' | 'suspended' | 'expired';
}

export interface SupplierStatusLogEntry {
  id: number;
  scope: string;
  from_status: string;
  to_status: string;
  effective_from: string;
  effective_to: string | null;
  changed_at: string;
  changed_by: string;
  reason: string;
}

export interface SupplierRiskEventItem {
  id: number;
  risk_type: 'delivery' | 'financial' | 'compliance' | 'quality';
  risk_level: RiskLevel;
  description: string;
  evidence_note: string;
  mitigation: string;
  raised_at: string;
  review_due_at: string | null;
  status: RiskEventStatus;
}

export interface SupplierRiskProfileData {
  risk_level: RiskLevel;
  risk_score: number;
  concentration_percent: number;
  requires_dual_approval: boolean;
  restrictions: string;
  assessed_at: string;
  next_review_at: string;
  assessed_by: string;
  events: SupplierRiskEventItem[];
}

export interface SupplierPriceListItemRow {
  id: number;
  product_name: string;
  supplier_item_code: string;
  minimum_quantity: number;
  maximum_quantity: number | null;
  unit_price: number;
  measurement_id: string;
  lead_time_days: number;
  minimum_billable_quantity: number | null;
  is_available: boolean;
}

export interface SupplierPriceListData {
  id: number;
  code: string;
  name: string;
  source: 'catalogue' | 'contract';
  valid_from: string;
  valid_to: string | null;
  currency_id: string;
  includes_tax: boolean;
  includes_delivery: boolean;
  status: 'active' | 'draft' | 'expired';
  items: SupplierPriceListItemRow[];
}

export interface SupplierPortalUserItem {
  id: number;
  full_name: string;
  email: string;
  designation: string;
  is_primary_contact: boolean;
  status: PortalAccountStatus;
}

export interface SupplierChangeRequestItem {
  id: number;
  request_number: string;
  scope: 'bank' | 'tax' | 'contact' | 'address';
  channel: 'supplier_portal' | 'internal';
  reason: string;
  effective_from: string | null;
  status: ChangeRequestStatus;
  current_values: Record<string, string>;
  proposed_values: Record<string, string>;
}

export interface SupplierScorecardSummary {
  scorecard_number: string;
  period_label: string;
  overall_score: number;
  grade: ScorecardGrade;
  status: 'approved' | 'published' | 'reviewed';
  lines: Array<{ code: string; name: string; weight: number; score: number }>;
}

export interface SupplierImprovementItem {
  id: number;
  code: string;
  title: string;
  action_type: 'corrective' | 'preventive' | 'warning';
  target_date: string;
  status: 'open' | 'in_progress' | 'verified';
}

export interface SupplierRecord {
  id: number;
  code: string;
  logo_url?: string;
  legal_name: string;
  trade_name: string;
  tin: string;
  vat_registration_number: string;
  business_type: string;
  origin: 'local' | 'foreign';
  entity_name: string;
  contact_person: string;
  email: string;
  phone: string;
  address: string;
  bank_summary: string;
  eligibility_status: SupplierEligibilityStatus;
  qualification: SupplierQualificationSummary;
  documents: SupplierQualificationDocItem[];
  categories: SupplierCategoryEligibility[];
  status_logs: SupplierStatusLogEntry[];
  risk: SupplierRiskProfileData;
  price_lists: SupplierPriceListData[];
  portal_users: SupplierPortalUserItem[];
  change_requests: SupplierChangeRequestItem[];
  scorecard: SupplierScorecardSummary | null;
  improvement_actions: SupplierImprovementItem[];
  linked_counts: {
    purchase_orders: number;
    returns: number;
    invoices: number;
    contracts: number;
  };
}

// ─── Formatting & Badge Helpers ──────────────────────────────────────────────
export function formatCurrency(amount: number, currency = 'ETB'): string {
  return `${currency} ${amount.toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })}`;
}

export function getEligibilityBadgeColor(
  status: SupplierEligibilityStatus
): 'success' | 'warning' | 'error' | 'gray' {
  if (status === 'active') return 'success';
  if (status === 'suspended') return 'warning';
  if (status === 'blacklisted') return 'error';
  return 'gray';
}

export function getEligibilityLabel(status: SupplierEligibilityStatus): string {
  if (status === 'active') return 'Active';
  if (status === 'suspended') return 'Suspended';
  if (status === 'blacklisted') return 'Blacklisted';
  return 'Expired';
}

export function getRiskBadgeColor(level: RiskLevel): 'success' | 'warning' | 'error' | 'indigo' {
  if (level === 'low') return 'success';
  if (level === 'medium') return 'warning';
  return 'error';
}

export function getRiskLabel(level: RiskLevel): string {
  if (level === 'low') return 'Low Risk';
  if (level === 'medium') return 'Medium Risk';
  if (level === 'high') return 'High Risk';
  return 'Critical Risk';
}

export function getGradeBadgeColor(grade: ScorecardGrade): 'success' | 'blue' | 'warning' | 'error' {
  if (grade === 'excellent') return 'success';
  if (grade === 'satisfactory') return 'blue';
  if (grade === 'needs_improvement') return 'warning';
  return 'error';
}

export function getGradeLabel(grade: ScorecardGrade): string {
  if (grade === 'excellent') return 'Excellent';
  if (grade === 'satisfactory') return 'Satisfactory';
  if (grade === 'needs_improvement') return 'Needs Improvement';
  return 'Unsatisfactory';
}

export function getDocReviewBadgeColor(
  result: DocumentReviewResult
): 'success' | 'warning' | 'error' | 'blue' {
  if (result === 'compliant') return 'success';
  if (result === 'waived') return 'blue';
  if (result === 'non_compliant') return 'error';
  return 'warning';
}

export function getPortalStatusBadgeColor(
  status: PortalAccountStatus
): 'success' | 'indigo' | 'warning' | 'error' {
  if (status === 'active') return 'success';
  if (status === 'invited') return 'indigo';
  if (status === 'suspended') return 'warning';
  return 'error';
}

export function getChangeStatusBadgeColor(
  status: ChangeRequestStatus
): 'success' | 'indigo' | 'primary' | 'error' {
  if (status === 'approved') return 'success';
  if (status === 'submitted') return 'indigo';
  if (status === 'rejected') return 'error';
  return 'primary';
}

// ─── Seed Data (Aligned with procurement-v4.sql #3 & #11 examples) ──────────
export const suppliersStore = ref<SupplierRecord[]>([
  {
    id: 501,
    code: 'SUP-501',
    logo_url: ethioTelecomLogo,
    legal_name: 'Ethio Telecom',
    trade_name: 'ethio telecom',
    tin: '0011223344',
    vat_registration_number: 'VAT-0044821',
    business_type: 'Telecom & Connectivity',
    origin: 'local',
    entity_name: 'Sheraton Ethiopia',
    contact_person: 'Abebe Kebede',
    email: 'enterprise@ethiotelecom.et',
    phone: '+251 11 551 5700',
    address: 'Churchill Avenue, Addis Ababa',
    bank_summary: 'Awash Bank, Bole Branch — •••• 9000',
    eligibility_status: 'active',
    qualification: {
      qualification_number: 'SQUAL-2026-0600',
      application_type: 'new',
      channel: 'internal',
      qualified_from: '2026-07-01',
      qualified_to: '2027-06-30',
      maximum_order_value: 1500000,
      currency_id: 'ETB',
      status: 'approved',
      decided_by: 'Marta Tadesse',
      decided_at: '2026-06-28'
    },
    documents: [
      {
        id: 1,
        document_type: 'Trade License',
        reference_number: 'AA/1123/18',
        issued_at: '2026-01-15',
        expires_at: '2027-01-15',
        is_mandatory: true,
        review_result: 'compliant',
        verified_by: 'Marta Tadesse'
      },
      {
        id: 2,
        document_type: 'VAT Certificate',
        reference_number: 'VAT-0044821',
        issued_at: '2024-07-01',
        expires_at: null,
        is_mandatory: true,
        review_result: 'compliant',
        verified_by: 'Marta Tadesse'
      }
    ],
    categories: [
      {
        id: 1,
        category_name: 'Telecom & IT Services',
        category_code: 'IT-TEL',
        is_preferred: true,
        minimum_order_value: 5000,
        approved_at: '2026-07-01',
        status: 'active'
      },
      {
        id: 2,
        category_name: 'Food & Beverage',
        category_code: 'FB',
        is_preferred: false,
        minimum_order_value: 10000,
        approved_at: '2026-07-01',
        status: 'suspended'
      }
    ],
    status_logs: [
      {
        id: 3,
        scope: 'Category: Food & Beverage',
        from_status: 'active',
        to_status: 'suspended',
        effective_from: '2026-11-02',
        effective_to: '2026-12-02',
        changed_at: '2026-11-02 10:15',
        changed_by: 'Marta Tadesse',
        reason: 'Short weight on 2 consecutive deliveries.'
      },
      {
        id: 1,
        scope: 'Whole Supplier',
        from_status: 'pending',
        to_status: 'active',
        effective_from: '2026-07-01',
        effective_to: null,
        changed_at: '2026-07-01 09:00',
        changed_by: 'Marta Tadesse',
        reason: 'Initial qualification SQUAL-2026-0600 approved.'
      }
    ],
    risk: {
      risk_level: 'low',
      risk_score: 18,
      concentration_percent: 62.4,
      requires_dual_approval: false,
      restrictions: 'Standard PO ceiling applies (ETB 1.5M).',
      assessed_at: '2026-07-01',
      next_review_at: '2027-01-01',
      assessed_by: 'Dawit Mekonnen',
      events: [
        {
          id: 3,
          risk_type: 'compliance',
          risk_level: 'low',
          description: 'Trade licence expires on Jan 15, 2027',
          evidence_note: 'Licence AA/1123/18',
          mitigation: 'Automated renewal reminder sent 60 days prior.',
          raised_at: '2026-11-01',
          review_due_at: '2026-12-15',
          status: 'open'
        }
      ]
    },
    price_lists: [
      {
        id: 700,
        code: 'SPL-501-1',
        name: 'H2 2026 Fresh Produce Catalogue',
        source: 'catalogue',
        valid_from: '2026-07-01',
        valid_to: '2026-12-31',
        currency_id: 'ETB',
        includes_tax: false,
        includes_delivery: true,
        status: 'active',
        items: [
          {
            id: 1,
            product_name: 'Fresh Roma Tomato',
            supplier_item_code: 'AB-TOM-A',
            minimum_quantity: 1,
            maximum_quantity: 99,
            unit_price: 47,
            measurement_id: 'kg',
            lead_time_days: 1,
            minimum_billable_quantity: null,
            is_available: true
          },
          {
            id: 2,
            product_name: 'Fresh Roma Tomato (Bulk)',
            supplier_item_code: 'AB-TOM-A',
            minimum_quantity: 100,
            maximum_quantity: null,
            unit_price: 45,
            measurement_id: 'kg',
            lead_time_days: 1,
            minimum_billable_quantity: null,
            is_available: true
          }
        ]
      }
    ],
    portal_users: [
      {
        id: 1,
        full_name: 'Abebe Kebede',
        email: 'sales@abebeproduce.example',
        designation: 'Sales Manager',
        is_primary_contact: true,
        status: 'active'
      }
    ],
    change_requests: [
      {
        id: 1,
        request_number: 'SCR-2026-001',
        scope: 'bank',
        channel: 'supplier_portal',
        reason: 'Migrated settlement account to Awash Bank Bole Branch.',
        effective_from: '2026-09-01',
        status: 'approved',
        current_values: { Bank: 'Commercial Bank of Ethiopia', 'Account Number': '1000098765432' },
        proposed_values: { Bank: 'Awash Bank', 'Account Number': '01320456789000' }
      }
    ],
    scorecard: {
      scorecard_number: 'SSC-2026-Q3-501',
      period_label: 'Q3 2026 (Jul 1 – Sep 30)',
      overall_score: 79.3,
      grade: 'satisfactory',
      status: 'approved',
      lines: [
        { code: 'OTD', name: 'On-Time Delivery', weight: 35, score: 80.0 },
        { code: 'QUALITY', name: 'Quality Acceptance', weight: 35, score: 92.1 },
        { code: 'PRICE', name: 'Price Variance', weight: 20, score: 58.0 },
        { code: 'COMMS', name: 'Responsiveness', weight: 10, score: 75.0 }
      ]
    },
    improvement_actions: [
      {
        id: 2,
        code: 'SIA-0008',
        title: 'Standardize produce weight calibration before dispatch',
        action_type: 'preventive',
        target_date: '2026-10-31',
        status: 'verified'
      }
    ],
    linked_counts: { purchase_orders: 18, returns: 1, invoices: 16, contracts: 1 }
  },
  {
    id: 502,
    code: 'SUP-502',
    logo_url: '',
    legal_name: 'Shoa Supermarket',
    trade_name: 'Shoa Shopping Center',
    tin: '0022334455',
    vat_registration_number: 'VAT-0055102',
    business_type: 'Supermarket & Wholesale',
    origin: 'local',
    entity_name: 'Sheraton Ethiopia',
    contact_person: 'Yonas Tadesse',
    email: 'wholesale@shoasupermarket.example',
    phone: '+251 11 662 4400',
    address: 'Bole Road, Addis Ababa',
    bank_summary: 'Dashen Bank, Mexico Branch — •••• 4412',
    eligibility_status: 'suspended',
    qualification: {
      qualification_number: 'SQUAL-2026-0601',
      application_type: 'reinstatement',
      channel: 'internal',
      qualified_from: '2026-07-01',
      qualified_to: '2027-06-30',
      maximum_order_value: 500000,
      currency_id: 'ETB',
      status: 'approved',
      decided_by: 'Marta Tadesse',
      decided_at: '2026-10-15'
    },
    documents: [
      {
        id: 4,
        document_type: 'Trade License',
        reference_number: 'AA/4512/19',
        issued_at: '2026-03-01',
        expires_at: '2027-03-01',
        is_mandatory: true,
        review_result: 'compliant',
        verified_by: 'Marta Tadesse'
      },
      {
        id: 5,
        document_type: 'Tax Clearance',
        reference_number: 'MOR-TC-2026-44',
        issued_at: '2026-04-01',
        expires_at: '2026-10-01',
        is_mandatory: true,
        review_result: 'non_compliant',
        verified_by: 'Dawit Mekonnen'
      }
    ],
    categories: [
      {
        id: 5,
        category_name: 'Fresh Produce, Food & Beverage',
        category_code: 'FB-RET',
        is_preferred: false,
        minimum_order_value: null,
        approved_at: '2026-07-01',
        status: 'active'
      }
    ],
    status_logs: [
      {
        id: 2,
        scope: 'Whole Supplier',
        from_status: 'suspended',
        to_status: 'reinstated',
        effective_from: '2026-10-15',
        effective_to: null,
        changed_at: '2026-10-15 11:00',
        changed_by: 'Marta Tadesse',
        reason: 'Corrective action verified; reinstated under dual-approval monitoring.'
      },
      {
        id: 1,
        scope: 'Whole Supplier',
        from_status: 'active',
        to_status: 'suspended',
        effective_from: '2026-09-14',
        effective_to: '2026-10-14',
        changed_at: '2026-09-14 14:20',
        changed_by: 'Marta Tadesse',
        reason: 'Three late deliveries within one month.'
      }
    ],
    risk: {
      risk_level: 'high',
      risk_score: 71,
      concentration_percent: 12.0,
      requires_dual_approval: true,
      restrictions: 'Every PO requires secondary Finance Director sign-off.',
      assessed_at: '2026-10-02',
      next_review_at: '2026-12-01',
      assessed_by: 'Dawit Mekonnen',
      events: [
        {
          id: 1,
          risk_type: 'delivery',
          risk_level: 'high',
          description: 'Three late deliveries in a month',
          evidence_note: 'GRN-4401, GRN-4418, GRN-4430',
          mitigation: '30-day suspension completed; weekly SLA check-in active.',
          raised_at: '2026-09-14',
          review_due_at: '2026-11-15',
          status: 'mitigated'
        },
        {
          id: 2,
          risk_type: 'financial',
          risk_level: 'medium',
          description: 'Tax arrears reported by MOR',
          evidence_note: 'MOR notice dated Oct 2, 2026',
          mitigation: 'Awaiting updated tax clearance certificate.',
          raised_at: '2026-10-02',
          review_due_at: '2026-11-30',
          status: 'open'
        }
      ]
    },
    price_lists: [],
    portal_users: [
      {
        id: 4,
        full_name: 'Yonas Tadesse',
        email: 'ops@ethioexpress.example',
        designation: 'Operations Director',
        is_primary_contact: true,
        status: 'active'
      }
    ],
    change_requests: [
      {
        id: 2,
        request_number: 'SCR-2026-002',
        scope: 'tax',
        channel: 'internal',
        reason: 'Updated VAT registration status following MOR audit.',
        effective_from: '2026-11-01',
        status: 'submitted',
        current_values: { 'VAT Registered': 'No', 'VAT Number': '—' },
        proposed_values: { 'VAT Registered': 'Yes', 'VAT Number': 'VAT-0055102' }
      }
    ],
    scorecard: {
      scorecard_number: 'SSC-2026-Q3-502',
      period_label: 'Q3 2026 (Jul 1 – Sep 30)',
      overall_score: 58.2,
      grade: 'needs_improvement',
      status: 'published',
      lines: [
        { code: 'OTD', name: 'On-Time Delivery', weight: 35, score: 42.0 },
        { code: 'QUALITY', name: 'Quality Acceptance', weight: 35, score: 74.0 },
        { code: 'PRICE', name: 'Price Variance', weight: 20, score: 62.0 },
        { code: 'COMMS', name: 'Responsiveness', weight: 10, score: 52.0 }
      ]
    },
    improvement_actions: [
      {
        id: 1,
        code: 'SIA-0007',
        title: 'Submit weekly fleet dispatch schedule to guarantee 95% OTD',
        action_type: 'corrective',
        target_date: '2026-11-15',
        status: 'open'
      },
      {
        id: 3,
        code: 'SIA-0009',
        title: 'Provide renewed MOR Tax Clearance Certificate',
        action_type: 'warning',
        target_date: '2026-12-31',
        status: 'in_progress'
      }
    ],
    linked_counts: { purchase_orders: 9, returns: 2, invoices: 8, contracts: 0 }
  },
  {
    id: 503,
    code: 'SUP-503',
    logo_url: '',
    legal_name: 'Siemens AG',
    trade_name: 'Siemens Industrial',
    tin: 'DE-812904411',
    vat_registration_number: 'DE812904411',
    business_type: 'Manufacturer',
    origin: 'foreign',
    entity_name: 'Sheraton Ethiopia',
    contact_person: 'Lukas Weber',
    email: 'export@siemens.example',
    phone: '+49 89 636 00',
    address: 'Werner-von-Siemens-Strasse 1, Munich, Germany',
    bank_summary: 'Deutsche Bank, Munich — •••• 7781',
    eligibility_status: 'active',
    qualification: {
      qualification_number: 'SQUAL-2026-0602',
      application_type: 'new',
      channel: 'internal',
      qualified_from: '2026-08-01',
      qualified_to: '2028-07-31',
      maximum_order_value: null,
      currency_id: 'EUR',
      status: 'approved',
      decided_by: 'Marta Tadesse',
      decided_at: '2026-07-28'
    },
    documents: [
      {
        id: 6,
        document_type: 'ISO Certificate',
        reference_number: 'ISO-9001-DE-882',
        issued_at: '2025-05-01',
        expires_at: '2028-05-01',
        is_mandatory: true,
        review_result: 'compliant',
        verified_by: 'Marta Tadesse'
      }
    ],
    categories: [
      {
        id: 3,
        category_name: 'Capital Equipment',
        category_code: 'CAPEX',
        is_preferred: true,
        minimum_order_value: null,
        approved_at: '2026-08-01',
        status: 'active'
      }
    ],
    status_logs: [
      {
        id: 4,
        scope: 'Whole Supplier',
        from_status: 'pending',
        to_status: 'active',
        effective_from: '2026-08-01',
        effective_to: null,
        changed_at: '2026-08-01 08:30',
        changed_by: 'Marta Tadesse',
        reason: '2-year capital equipment qualification approved.'
      }
    ],
    risk: {
      risk_level: 'medium',
      risk_score: 44,
      concentration_percent: 100.0,
      requires_dual_approval: false,
      restrictions: 'Single-source concentration monitored annually.',
      assessed_at: '2026-08-01',
      next_review_at: '2027-02-01',
      assessed_by: 'Dawit Mekonnen',
      events: []
    },
    price_lists: [
      {
        id: 702,
        code: 'SPL-530-1',
        name: '2026–2027 Kitchen Maintenance & Service Rates',
        source: 'contract',
        valid_from: '2026-07-01',
        valid_to: '2027-06-30',
        currency_id: 'EUR',
        includes_tax: false,
        includes_delivery: false,
        status: 'active',
        items: [
          {
            id: 3,
            product_name: 'Certified Kitchen Technician (Service Rate)',
            supplier_item_code: 'TECH-KITCHEN',
            minimum_quantity: 1,
            maximum_quantity: null,
            unit_price: 85,
            measurement_id: 'hour',
            lead_time_days: 3,
            minimum_billable_quantity: 4,
            is_available: true
          }
        ]
      }
    ],
    portal_users: [
      {
        id: 2,
        full_name: 'Lukas Weber',
        email: 'export@eurotech-kitchen.example',
        designation: 'Export Manager',
        is_primary_contact: true,
        status: 'active'
      }
    ],
    change_requests: [],
    scorecard: {
      scorecard_number: 'SSC-2026-Q3-503',
      period_label: 'Q3 2026 (Jul 1 – Sep 30)',
      overall_score: 88.6,
      grade: 'excellent',
      status: 'reviewed',
      lines: [
        { code: 'OTD', name: 'On-Time Delivery', weight: 35, score: 86.0 },
        { code: 'QUALITY', name: 'Quality Acceptance', weight: 35, score: 96.0 },
        { code: 'PRICE', name: 'Price Variance', weight: 20, score: 80.0 },
        { code: 'COMMS', name: 'Responsiveness', weight: 10, score: 89.0 }
      ]
    },
    improvement_actions: [],
    linked_counts: { purchase_orders: 4, returns: 0, invoices: 4, contracts: 1 }
  },
  {
    id: 540,
    code: 'SUP-540',
    logo_url: '',
    legal_name: 'Queens Supermarket',
    trade_name: 'Queens Retail PLC',
    tin: '0012345678',
    vat_registration_number: 'VAT-0044821',
    business_type: 'Retail & Supplies',
    origin: 'local',
    entity_name: 'Sheraton Ethiopia',
    contact_person: 'Lemlem Haile',
    email: 'corporate@queenssupermarket.example',
    phone: '+251 11 667 3040',
    address: 'Bole Sub-city, Woreda 03, Addis Ababa',
    bank_summary: 'Awash Bank, Bole Branch — •••• 9000',
    eligibility_status: 'active',
    qualification: {
      qualification_number: 'SQUAL-2026-0604',
      application_type: 'new',
      channel: 'internal',
      qualified_from: '2026-07-05',
      qualified_to: '2027-06-30',
      maximum_order_value: 200000,
      currency_id: 'ETB',
      status: 'approved',
      decided_by: 'Marta Tadesse',
      decided_at: '2026-07-05'
    },
    documents: [
      {
        id: 3,
        document_type: 'Tax Clearance',
        reference_number: 'MOR-TC-2026-11',
        issued_at: '2026-04-01',
        expires_at: '2026-09-30',
        is_mandatory: true,
        review_result: 'compliant',
        verified_by: 'Marta Tadesse'
      }
    ],
    categories: [
      {
        id: 4,
        category_name: 'Office Supplies',
        category_code: 'OFFICE',
        is_preferred: false,
        minimum_order_value: 2000,
        approved_at: '2026-07-05',
        status: 'active'
      }
    ],
    status_logs: [
      {
        id: 5,
        scope: 'Whole Supplier',
        from_status: 'pending',
        to_status: 'active',
        effective_from: '2026-07-05',
        effective_to: null,
        changed_at: '2026-07-05 14:30',
        changed_by: 'Marta Tadesse',
        reason: 'Created from approved registration SREG-041.'
      }
    ],
    risk: {
      risk_level: 'low',
      risk_score: 12,
      concentration_percent: 18.5,
      requires_dual_approval: false,
      restrictions: 'None',
      assessed_at: '2026-07-05',
      next_review_at: '2027-01-05',
      assessed_by: 'Dawit Mekonnen',
      events: []
    },
    price_lists: [
      {
        id: 701,
        code: 'SPL-540-1',
        name: 'FY 2026 Office Stationery Price List',
        source: 'catalogue',
        valid_from: '2026-07-05',
        valid_to: '2027-06-30',
        currency_id: 'ETB',
        includes_tax: true,
        includes_delivery: true,
        status: 'active',
        items: [
          {
            id: 4,
            product_name: 'A4 Printing Paper 80gsm Carton',
            supplier_item_code: 'LM-A4-80',
            minimum_quantity: 1,
            maximum_quantity: null,
            unit_price: 2450,
            measurement_id: 'box',
            lead_time_days: 2,
            minimum_billable_quantity: null,
            is_available: true
          }
        ]
      }
    ],
    portal_users: [
      {
        id: 3,
        full_name: 'Lemlem Haile',
        email: 'sales@lemlemoffice.example',
        designation: 'Owner',
        is_primary_contact: true,
        status: 'invited'
      }
    ],
    change_requests: [
      {
        id: 3,
        request_number: 'SCR-2026-003',
        scope: 'contact',
        channel: 'supplier_portal',
        reason: 'Updated primary office phone number.',
        effective_from: null,
        status: 'draft',
        current_values: { Phone: '+251 911 20 30 40' },
        proposed_values: { Phone: '+251 911 22 33 44' }
      }
    ],
    scorecard: null,
    improvement_actions: [],
    linked_counts: { purchase_orders: 3, returns: 0, invoices: 2, contracts: 0 }
  }
]);

