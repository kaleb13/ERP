import { ref } from 'vue';

/**
 * Supplier Performance Setup data layer.
 * Schema source: procurement-v4.sql #11 -> SupplierPerformanceCriterion + SupplierRatingBand.
 */

export type CriterionSource =
  | 'delivery_on_time'
  | 'delivery_in_full'
  | 'quality_acceptance'
  | 'price_variance'
  | 'invoice_accuracy'
  | 'responsiveness'
  | 'manual';

export type ScorecardGradeKey =
  | 'excellent'
  | 'satisfactory'
  | 'needs_improvement'
  | 'unsatisfactory';

export interface PerformanceCriterionRecord {
  id: number;
  code: string;
  name: string;
  source_lookup_value_id: CriterionSource;
  weight_percent: number;
  target_value: number | null;
  floor_value: number | null;
  display_order: number;
  category_label: string;
  effective_from: string;
  effective_to: string | null;
  state: 'active' | 'inactive';
}

export interface RatingBandRecord {
  id: number;
  grade_lookup_value_id: ScorecardGradeKey;
  minimum_score: number;
  maximum_score: number;
  consequence: string;
  requires_improvement_action: boolean;
  effective_from: string;
  effective_to: string | null;
  state: 'active' | 'inactive';
}

export const criterionSourceOptions = [
  { value: 'delivery_on_time', label: 'Delivery On-Time (Derived)' },
  { value: 'delivery_in_full', label: 'Delivery In-Full (Derived)' },
  { value: 'quality_acceptance', label: 'Quality Acceptance (Derived)' },
  { value: 'price_variance', label: 'Price Variance (Derived)' },
  { value: 'invoice_accuracy', label: 'Invoice Accuracy (Derived)' },
  { value: 'responsiveness', label: 'RFQ / Claim Responsiveness' },
  { value: 'manual', label: 'Manual Evaluator Score' }
];

export const scorecardGradeOptions = [
  { value: 'excellent', label: 'Excellent' },
  { value: 'satisfactory', label: 'Satisfactory' },
  { value: 'needs_improvement', label: 'Needs Improvement' },
  { value: 'unsatisfactory', label: 'Unsatisfactory' }
];

export function getCriterionSourceLabel(val: CriterionSource): string {
  return criterionSourceOptions.find((o) => o.value === val)?.label ?? val;
}

export function getScorecardGradeLabel(val: ScorecardGradeKey): string {
  return scorecardGradeOptions.find((o) => o.value === val)?.label ?? val;
}

export function getScorecardGradeColor(
  val: ScorecardGradeKey
): 'success' | 'blue' | 'warning' | 'error' {
  if (val === 'excellent') return 'success';
  if (val === 'satisfactory') return 'blue';
  if (val === 'needs_improvement') return 'warning';
  return 'error';
}

export const performanceCriteriaStore = ref<PerformanceCriterionRecord[]>([
  {
    id: 1,
    code: 'OTD',
    name: 'On-Time Delivery',
    source_lookup_value_id: 'delivery_on_time',
    weight_percent: 35,
    target_value: 95,
    floor_value: 60,
    display_order: 1,
    category_label: 'Default (All Categories)',
    effective_from: '2026-07-01',
    effective_to: null,
    state: 'active'
  },
  {
    id: 2,
    code: 'QUALITY',
    name: 'Quality Acceptance Rate',
    source_lookup_value_id: 'quality_acceptance',
    weight_percent: 35,
    target_value: 99,
    floor_value: 80,
    display_order: 2,
    category_label: 'Default (All Categories)',
    effective_from: '2026-07-01',
    effective_to: null,
    state: 'active'
  },
  {
    id: 3,
    code: 'PRICE',
    name: 'Price Variance',
    source_lookup_value_id: 'price_variance',
    weight_percent: 20,
    target_value: 0,
    floor_value: 5,
    display_order: 3,
    category_label: 'Default (All Categories)',
    effective_from: '2026-07-01',
    effective_to: null,
    state: 'active'
  },
  {
    id: 4,
    code: 'COMMS',
    name: 'Communication & Responsiveness',
    source_lookup_value_id: 'manual',
    weight_percent: 10,
    target_value: 5,
    floor_value: 1,
    display_order: 4,
    category_label: 'Default (All Categories)',
    effective_from: '2026-07-01',
    effective_to: null,
    state: 'active'
  }
]);

export const ratingBandsStore = ref<RatingBandRecord[]>([
  {
    id: 1,
    grade_lookup_value_id: 'excellent',
    minimum_score: 85,
    maximum_score: 100,
    consequence: 'Preferred supplier priority in buyer pickers.',
    requires_improvement_action: false,
    effective_from: '2026-07-01',
    effective_to: null,
    state: 'active'
  },
  {
    id: 2,
    grade_lookup_value_id: 'satisfactory',
    minimum_score: 70,
    maximum_score: 84.99,
    consequence: 'Standard approved vendor standing.',
    requires_improvement_action: false,
    effective_from: '2026-07-01',
    effective_to: null,
    state: 'active'
  },
  {
    id: 3,
    grade_lookup_value_id: 'needs_improvement',
    minimum_score: 50,
    maximum_score: 69.99,
    consequence: 'Triggers mandatory Supplier Improvement Action.',
    requires_improvement_action: true,
    effective_from: '2026-07-01',
    effective_to: null,
    state: 'active'
  },
  {
    id: 4,
    grade_lookup_value_id: 'unsatisfactory',
    minimum_score: 0,
    maximum_score: 49.99,
    consequence: 'Triggers Improvement Action and suspension review.',
    requires_improvement_action: true,
    effective_from: '2026-07-01',
    effective_to: null,
    state: 'active'
  }
]);

