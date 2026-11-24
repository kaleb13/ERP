<!--
  ══════════════════════════════════════════════════════════════════════════════
  HALETA ERP — SUPPLIER HUB DETAIL PAGE (Operational Lifecycle Workspace)
  Focused on active operational domains procurement officers act on:
    1. Overview (minimal commercial + risk/performance standing)
    2. Risk (risk profile, dual approval toggle, + Add Risk Event, mitigate/close)
    3. Price Lists (agreed catalogues/contracts, + Add Price List, + Add Rate Item)
    4. Performance (KPI scorecard breakdown, Record Scorecard, + Add Improvement Action)
  Static onboarding data (KYC docs, portal users) stays in Supplier Registration.
  ══════════════════════════════════════════════════════════════════════════════
-->
<script setup lang="ts">
import { ref, reactive, computed } from 'vue';
import { useRoute } from 'vue-router';
import {
  Hash, FileText, MapPin, Edit2, Plus,
  AlertTriangle, FileSpreadsheet, Award, LayoutGrid,
  Eye, EyeOff, ChevronDown, ChevronRight,
  MoreVertical, Check, CheckCircle2
} from 'lucide-vue-next';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseAvatar from '../../components/BaseAvatar.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import BaseDropdownMenu, { type DropdownMenuItem } from '../../components/BaseDropdownMenu.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import DynamicSubTable, { type DynamicTableColumn } from '../../components/DynamicSubTable.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import { useToast } from '../../composables/useToast';
import { formatDisplayDate } from '../../utils/dateFormat';
import StarRating from '../../components/StarRating.vue';
import SupplierRatingModal from './SupplierRatingModal.vue';
import {
  suppliersStore,
  type SupplierRiskEventItem,
  type SupplierPriceListItemRow,
  type SupplierImprovementActionItem,
  formatCurrency,
  getEligibilityBadgeColor,
  getEligibilityLabel,
  getRiskBadgeColor,
  getRiskLabel,
  getGradeBadgeColor,
  getGradeLabel
} from './supplierData';

const route = useRoute();
const { toast } = useToast();

const supplierId = computed(() => Number(route.params.id));
const supplier = computed(() => suppliersStore.value.find((s) => s.id === supplierId.value));

const breadcrumbItems = computed<BreadcrumbItem[]>(() => [
  { label: 'Supplier Hub', to: '/procurement/suppliers' },
  {
    label: supplier.value
      ? `${supplier.value.code} — ${supplier.value.legal_name}`
      : 'Supplier Profile'
  }
]);

// ─── Primary Operational Tabs (BaseTabs Rounded) ─────────────────────────────
type DetailTabId = 'overview' | 'risk' | 'price_lists' | 'performance';
const validTabs: DetailTabId[] = ['overview', 'risk', 'price_lists', 'performance'];
const initialTab = validTabs.includes(route.query.tab as DetailTabId)
  ? (route.query.tab as DetailTabId)
  : 'overview';
const activeTab = ref<DetailTabId>(initialTab);

const tabs = computed<BaseTabItem<DetailTabId>[]>(() => {
  const s = supplier.value;
  return [
    { id: 'overview', label: 'Overview', icon: LayoutGrid },
    { id: 'risk', label: 'Risk', icon: AlertTriangle, count: s?.risk.events.length ?? 0, badgeVariant: 'warning' },
    { id: 'price_lists', label: 'Price Lists', icon: FileSpreadsheet, count: s?.price_lists.length ?? 0 },
    { id: 'performance', label: 'Performance', icon: Award }
  ];
});

const activeCategories = computed(
  () => supplier.value?.categories.filter((c) => c.status === 'active') ?? []
);

const activeCategoriesSummary = computed(() => {
  if (activeCategories.value.length === 0) return 'None';
  return activeCategories.value.map((c) => c.category_name).join(', ');
});

const starRatingValue = computed(() => {
  const score = supplier.value?.scorecard?.overall_score;
  if (score === undefined || score === null || score <= 0) return 0;
  return Math.max(0.5, Math.min(5, Math.round((score / 20) * 2) / 2));
});

const showBankAccount = ref(false);
const fullBankAccounts: Record<number, string> = {
  501: '01320456789000',
  502: '5018229044412',
  503: 'DE89 3704 0044 0532 0130 7781',
  540: '01320456789000'
};

const parsedBank = computed(() => {
  const s = supplier.value;
  const raw = s?.bank_summary || '';
  const parts = raw.split('—').map((p) => p.trim());
  const bankName = parts.length >= 2 ? parts[0] : raw || 'Not configured';
  const maskedAccount = parts.length >= 2 ? parts.slice(1).join(' — ') : '';
  const fullAccount = s ? (fullBankAccounts[s.id] || maskedAccount) : '';
  return { bankName, maskedAccount, fullAccount };
});

const formatAppType = (val: string) =>
  val ? val.charAt(0).toUpperCase() + val.slice(1).replace(/_/g, ' ') : '—';

// ─── Collapsible Section State (Risk, Price Lists, Performance) ──────────────
const collapsedSections = reactive({
  riskProfile: false,
  riskEvents: false,
  scorecard: false,
  improvementActions: false
});

const collapsedPriceLists = reactive<Record<number, boolean>>({});
const isPriceListCollapsed = (id: number) => Boolean(collapsedPriceLists[id]);
const togglePriceListCollapse = (id: number) => {
  collapsedPriceLists[id] = !collapsedPriceLists[id];
};

// ─── Interactive Clickable Hero Star Rating (Opens SupplierRatingModal) ──────
const showRatingModal = ref(false);
const ratingInitialStars = ref(4);

const openRatingFor = (stars: number) => {
  ratingInitialStars.value = stars;
  showRatingModal.value = true;
};

const getScoreBarColor = (score: number) => {
  if (score >= 85) return '#009966';
  if (score >= 70) return '#0b529c';
  if (score >= 50) return '#e17100';
  return '#e7000b';
};

const resolveGrade = (score: number) => {
  if (score >= 85) return 'excellent' as const;
  if (score >= 70) return 'satisfactory' as const;
  if (score >= 50) return 'needs_improvement' as const;
  return 'unsatisfactory' as const;
};

// ─── TAB 2: RISK — Read-Only Table + QuickCreateModal + 3-Dot Lifecycle Menu ─
const riskTypeOptions = [
  { value: 'delivery', label: 'Delivery' },
  { value: 'quality', label: 'Quality' },
  { value: 'compliance', label: 'Compliance' },
  { value: 'financial', label: 'Financial' }
];

const riskLevelOptions = [
  { value: 'low', label: 'Low' },
  { value: 'medium', label: 'Medium' },
  { value: 'high', label: 'High' },
  { value: 'critical', label: 'Critical' }
];

const showRiskProfileModal = ref(false);
const riskProfileForm = reactive({
  risk_level: 'low',
  risk_score: '0',
  concentration_percent: '0',
  next_review_at: '',
  restrictions: '',
  requires_dual_approval: false
});

const openRiskProfileModal = () => {
  const s = supplier.value;
  if (!s) return;
  riskProfileForm.risk_level = s.risk.risk_level;
  riskProfileForm.risk_score = String(s.risk.risk_score);
  riskProfileForm.concentration_percent = String(s.risk.concentration_percent);
  riskProfileForm.next_review_at = s.risk.next_review_at;
  riskProfileForm.restrictions = s.risk.restrictions === 'None' ? '' : s.risk.restrictions;
  riskProfileForm.requires_dual_approval = s.risk.requires_dual_approval;
  showRiskProfileModal.value = true;
};

const handleUpdateRiskProfile = () => {
  const s = supplier.value;
  if (!s) return;
  s.risk.risk_level = riskProfileForm.risk_level as SupplierRiskEventItem['risk_level'];
  s.risk.risk_score = Math.max(0, Math.min(100, Number(riskProfileForm.risk_score) || 0));
  s.risk.concentration_percent = Math.max(0, Math.min(100, Number(riskProfileForm.concentration_percent) || 0));
  s.risk.next_review_at = riskProfileForm.next_review_at || s.risk.next_review_at;
  s.risk.restrictions = riskProfileForm.restrictions.trim() || 'None';
  s.risk.requires_dual_approval = riskProfileForm.requires_dual_approval;
  s.risk.assessed_at = new Date().toISOString().split('T')[0];
  showRiskProfileModal.value = false;
  toast.success('Supplier risk profile updated.');
};

const showRiskModal = ref(false);
const riskForm = reactive({
  risk_type: '',
  risk_level: '',
  description: '',
  evidence_note: '',
  mitigation: '',
  review_due_at: ''
});

const openRiskModal = () => {
  riskForm.risk_type = '';
  riskForm.risk_level = '';
  riskForm.description = '';
  riskForm.evidence_note = '';
  riskForm.mitigation = '';
  riskForm.review_due_at = '';
  showRiskModal.value = true;
};

const handleAddRiskEvent = () => {
  const s = supplier.value;
  if (!s) return;
  if (!riskForm.risk_type || !riskForm.risk_level || !riskForm.description.trim()) {
    toast.error('Please fill Risk Type, Severity, and Incident Summary.');
    return;
  }
  const today = new Date().toISOString().split('T')[0];
  s.risk.events.unshift({
    id: Date.now(),
    risk_type: riskForm.risk_type as SupplierRiskEventItem['risk_type'],
    risk_level: riskForm.risk_level as SupplierRiskEventItem['risk_level'],
    description: riskForm.description.trim(),
    evidence_note: riskForm.evidence_note.trim() || 'Logged in Supplier Hub',
    mitigation: riskForm.mitigation.trim() || 'Under procurement review',
    raised_at: today,
    review_due_at: riskForm.review_due_at || null,
    status: 'open'
  });

  const bump = riskForm.risk_level === 'critical' ? 24 : riskForm.risk_level === 'high' ? 18 : riskForm.risk_level === 'medium' ? 10 : 4;
  s.risk.risk_score = Math.min(100, s.risk.risk_score + bump);
  s.risk.risk_level = s.risk.risk_score >= 65 ? 'high' : s.risk.risk_score >= 35 ? 'medium' : 'low';
  s.risk.assessed_at = today;

  showRiskModal.value = false;
  toast.success('Risk event logged (status: Open).');
};

const getRiskEventActions = (ev: SupplierRiskEventItem): DropdownMenuItem[] => [
  {
    key: 'mitigated',
    label: 'Mark as Mitigated',
    icon: Check,
    disabled: ev.status === 'mitigated' || ev.status === 'closed',
    onClick: () => {
      ev.status = 'mitigated';
      toast.info('Risk event marked as mitigated.');
    }
  },
  {
    key: 'close',
    label: 'Close Risk Event',
    icon: CheckCircle2,
    disabled: ev.status === 'closed',
    onClick: () => {
      ev.status = 'closed';
      toast.success('Risk event closed.');
    }
  }
];

// ─── TAB 3: PRICE LISTS — QuickCreateModal [DIST] + DynamicSubTable [LINE] ──
const showPriceListModal = ref(false);
const priceListForm = reactive({
  name: '',
  source: 'catalogue',
  currency_id: 'ETB',
  valid_from: '',
  valid_to: '',
  includes_tax: false,
  includes_delivery: true
});

const priceListSourceOptions = [
  { value: 'catalogue', label: 'Supplier Catalogue' },
  { value: 'contract', label: 'Contract Rate Sheet' }
];

const currencyOptions = [
  { value: 'ETB', label: 'ETB' },
  { value: 'USD', label: 'USD' },
  { value: 'EUR', label: 'EUR' }
];

const openPriceListModal = () => {
  priceListForm.name = '';
  priceListForm.source = 'catalogue';
  priceListForm.currency_id = 'ETB';
  priceListForm.valid_from = new Date().toISOString().split('T')[0];
  priceListForm.valid_to = '';
  priceListForm.includes_tax = false;
  priceListForm.includes_delivery = true;
  showPriceListModal.value = true;
};

const handleAddPriceList = () => {
  const s = supplier.value;
  if (!s) return;
  if (!priceListForm.name.trim() || !priceListForm.valid_from) {
    toast.error('Please enter a Price List Name and Valid From date.');
    return;
  }
  const code = `SPL-${s.id}-${s.price_lists.length + 1}`;
  s.price_lists.unshift({
    id: Date.now(),
    code,
    name: priceListForm.name.trim(),
    source: priceListForm.source as 'catalogue' | 'contract',
    valid_from: priceListForm.valid_from,
    valid_to: priceListForm.valid_to || null,
    currency_id: priceListForm.currency_id,
    includes_tax: priceListForm.includes_tax,
    includes_delivery: priceListForm.includes_delivery,
    status: 'active',
    items: []
  });

  showPriceListModal.value = false;
  toast.success(`Price list ${code} created. Add itemized rates directly in the table below.`);
};

const priceListItemColumns: DynamicTableColumn[] = [
  {
    key: 'product_name',
    label: 'Item / Service Name',
    type: 'text',
    subtitleKey: 'supplier_item_code',
    minWidth: '220px',
    placeholder: ''
  },
  {
    key: 'unit_price',
    label: 'Unit Price',
    type: 'number',
    width: '130px',
    placeholder: ''
  },
  {
    key: 'measurement_id',
    label: 'UOM',
    type: 'text',
    width: '100px',
    placeholder: ''
  },
  {
    key: 'lead_time_days',
    label: 'Lead Days',
    type: 'number',
    width: '110px',
    placeholder: ''
  },
  {
    key: 'is_available',
    label: 'Available',
    type: 'switch',
    width: '120px'
  }
];

const createPriceListItemRow = (existingCount: number): SupplierPriceListItemRow => ({
  id: Date.now() + Math.floor(Math.random() * 1000),
  product_name: '',
  supplier_item_code: `SKU-${String(existingCount + 1).padStart(2, '0')}`,
  minimum_quantity: 1,
  maximum_quantity: null,
  unit_price: 0,
  measurement_id: 'unit',
  lead_time_days: 2,
  minimum_billable_quantity: null,
  is_available: true
});

// ─── TAB 4: PERFORMANCE — Scorecard QuickCreateModal + Improvement Actions DynamicSubTable
const showScorecardModal = ref(false);
const scorecardDraft = reactive({
  period_label: 'Q4 2026 (Oct 1 – Dec 31)',
  otd: '85',
  quality: '90',
  price: '78',
  comms: '82'
});

const openScorecardModal = () => {
  const s = supplier.value;
  if (s?.scorecard) {
    const find = (code: string, fallback: string) =>
      String(s.scorecard?.lines.find((l) => l.code === code)?.score ?? fallback);
    scorecardDraft.period_label = s.scorecard.period_label;
    scorecardDraft.otd = find('OTD', '80');
    scorecardDraft.quality = find('QUALITY', '85');
    scorecardDraft.price = find('PRICE', '75');
    scorecardDraft.comms = find('COMMS', '80');
  }
  showScorecardModal.value = true;
};

const handleSaveScorecard = () => {
  const s = supplier.value;
  if (!s) return;
  const clamp = (v: string) => Math.max(0, Math.min(100, Number(v) || 0));
  const lines = [
    { code: 'OTD', name: 'On-Time Delivery', weight: 35, score: clamp(scorecardDraft.otd) },
    { code: 'QUALITY', name: 'Quality Acceptance', weight: 35, score: clamp(scorecardDraft.quality) },
    { code: 'PRICE', name: 'Price Variance', weight: 20, score: clamp(scorecardDraft.price) },
    { code: 'COMMS', name: 'Responsiveness', weight: 10, score: clamp(scorecardDraft.comms) }
  ];
  const overall = Number(
    lines.reduce((acc, l) => acc + (l.score * l.weight) / 100, 0).toFixed(1)
  );
  s.scorecard = {
    scorecard_number: s.scorecard?.scorecard_number || `SSC-2026-Q4-${s.id}`,
    period_label: scorecardDraft.period_label.trim() || 'Q4 2026 (Oct 1 – Dec 31)',
    overall_score: overall,
    grade: resolveGrade(overall),
    status: 'reviewed',
    lines
  };
  showScorecardModal.value = false;
  toast.success(`Scorecard recorded (${overall.toFixed(1)} / 100 • ${getGradeLabel(s.scorecard.grade)}).`);
};

const actionTypeOptions = [
  { value: 'corrective', label: 'Corrective' },
  { value: 'preventive', label: 'Preventive' },
  { value: 'warning', label: 'Formal Warning' }
];

const showActionModal = ref(false);
const actionForm = reactive({
  title: '',
  action_type: '',
  target_date: ''
});

const openActionModal = () => {
  actionForm.title = '';
  actionForm.action_type = '';
  actionForm.target_date = '';
  showActionModal.value = true;
};

const handleAddImprovementAction = () => {
  const s = supplier.value;
  if (!s) return;
  if (!actionForm.title.trim() || !actionForm.action_type || !actionForm.target_date) {
    toast.error('Please fill Action Title, Action Type, and Target Date.');
    return;
  }
  s.improvement_actions.unshift({
    id: Date.now(),
    code: `SIA-${String(10 + s.improvement_actions.length).padStart(4, '0')}`,
    title: actionForm.title.trim(),
    action_type: actionForm.action_type as SupplierImprovementActionItem['action_type'],
    target_date: actionForm.target_date,
    status: 'open'
  });
  showActionModal.value = false;
  toast.success('Improvement action added (status: Open).');
};

const getImprovementActionsMenu = (act: SupplierImprovementActionItem): DropdownMenuItem[] => [
  {
    key: 'in_progress',
    label: 'Mark In Progress',
    icon: Check,
    disabled: act.status === 'in_progress' || act.status === 'verified',
    onClick: () => {
      act.status = 'in_progress';
      toast.info(`${act.code} marked in progress.`);
    }
  },
  {
    key: 'verified',
    label: 'Mark Verified',
    icon: CheckCircle2,
    disabled: act.status === 'verified',
    onClick: () => {
      act.status = 'verified';
      toast.success(`${act.code} verified.`);
    }
  }
];
</script>

<template>
  <div class="supplier-detail-page">
    <!-- Transparent Canvas Breadcrumb (Zero Back Buttons, Zero Floating Header Buttons) -->
    <AppBreadcrumb :items="breadcrumbItems" :noMargin="true" />

    <div v-if="!supplier" class="detail-card empty-card">
      <p class="empty-title">Supplier not found</p>
      <p class="empty-sub">The requested supplier does not exist in the current store.</p>
    </div>

    <template v-else>
      <!-- CARD 1: MINIMALIST HERO IDENTITY CARD (Inspired by Figma 10803:71313) -->
      <div class="detail-card hero-card-wrap">
        <div class="hero-card">
          <div class="hero-left">
            <BaseAvatar
              :src="supplier.logo_url"
              :name="supplier.legal_name"
              size="2xl"
              :bordered="true"
              class="hero-supplier-avatar"
            />
            <div class="hero-identity">
              <div class="hero-title-row">
                <h1 class="hero-title">{{ supplier.legal_name }}</h1>
                <BaseBadge
                  size="sm"
                  :color="getEligibilityBadgeColor(supplier.eligibility_status)"
                >
                  {{ getEligibilityLabel(supplier.eligibility_status) }}
                </BaseBadge>
                <BaseBadge size="sm" :color="getRiskBadgeColor(supplier.risk.risk_level)">
                  {{ getRiskLabel(supplier.risk.risk_level) }}
                </BaseBadge>
              </div>
              <span class="hero-meta">
                {{ supplier.code }} • {{ supplier.origin === 'local' ? 'Local' : 'Foreign' }} • {{ supplier.business_type }}
              </span>
              <div class="hero-rating-inline">
                <div
                  :title="supplier.scorecard ? `${supplier.scorecard.overall_score.toFixed(1)} / 100 — click a star to rate` : 'Click a star to rate'"
                >
                  <StarRating
                    :model-value="starRatingValue"
                    :size="18"
                    :interactive="true"
                    :allow-half="true"
                    :aria-label="`Rate ${supplier.legal_name}`"
                    @select="openRatingFor"
                  />
                </div>
                <template v-if="supplier.scorecard">
                  <span class="hero-score-val">{{ Math.round(supplier.scorecard.overall_score) }}</span>
                  <span class="hero-score-rest">/ 100 • {{ getGradeLabel(supplier.scorecard.grade) }}</span>
                </template>
                <span v-else class="hero-score-rest">Not rated yet</span>
              </div>
            </div>
          </div>

          <!-- Right Company Credentials Stack (At-a-glance legal & headquarters info) -->
          <div class="hero-contacts">
            <span class="contact-item">
              <Hash :size="15" class="contact-icon" />
              <span>TIN {{ supplier.tin }}</span>
            </span>
            <span class="contact-item">
              <FileText :size="15" class="contact-icon" />
              <span>{{ supplier.vat_registration_number || 'Not VAT Registered' }}</span>
            </span>
            <span class="contact-item">
              <MapPin :size="15" class="contact-icon" />
              <span>{{ supplier.address }}</span>
            </span>
          </div>
        </div>
      </div>

      <!-- PRIMARY OPERATIONAL TABS (Directly on main #FAFAFA canvas — zero wrapper card) -->
      <div class="detail-tabs-row">
        <BaseTabs v-model="activeTab" :tabs="tabs" type="rounded" size="sm" />
      </div>

      <!-- ═════════ TAB 1: OVERVIEW (Clean Read-Only Standing — Zero Actions, Not Collapsible) ═════════ -->
      <div v-if="activeTab === 'overview'" class="overview-grid-2">
        <div class="detail-card section-card">
          <h3 class="section-title">Commercial Standing</h3>
          <div class="field-grid-3">
            <div class="field-cell">
              <span class="field-label">Approved Categories</span>
              <span class="field-value">{{ activeCategoriesSummary }}</span>
            </div>
            <div class="field-cell">
              <span class="field-label">Max Order Cap</span>
              <span class="field-value">
                {{
                  supplier.qualification.maximum_order_value !== null
                    ? formatCurrency(supplier.qualification.maximum_order_value, supplier.qualification.currency_id)
                    : 'No Cap'
                }}
              </span>
            </div>
            <div class="field-cell">
              <span class="field-label">Qualified Until</span>
              <span class="field-value">{{ formatDisplayDate(supplier.qualification.qualified_to) }}</span>
            </div>
          </div>
          <div class="field-grid-3">
            <div class="field-cell">
              <span class="field-label">Qualification Ref</span>
              <span class="field-value">{{ supplier.qualification.qualification_number }}</span>
            </div>
            <div class="field-cell">
              <span class="field-label">Price Lists</span>
              <span class="field-value">{{ supplier.price_lists.length }} Active</span>
            </div>
            <div class="field-cell">
              <span class="field-label">Purchase Orders</span>
              <span class="field-value">{{ supplier.linked_counts.purchase_orders }} POs</span>
            </div>
          </div>
          <div class="bank-pill-block">
            <span class="field-label">Settlement Bank Account</span>
            <div class="bank-pill-box">
              <div class="bank-pill-info">
                <span class="bank-pill-name">{{ parsedBank.bankName }}</span>
                <span v-if="parsedBank.maskedAccount" class="bank-pill-mask">
                  {{ showBankAccount ? parsedBank.fullAccount : parsedBank.maskedAccount }}
                </span>
              </div>
              <button
                v-if="parsedBank.maskedAccount"
                type="button"
                class="btn-reveal-bank"
                :aria-label="showBankAccount ? 'Hide bank account number' : 'Reveal bank account number'"
                @click="showBankAccount = !showBankAccount"
              >
                <EyeOff v-if="showBankAccount" :size="14" />
                <Eye v-else :size="14" />
                <span>{{ showBankAccount ? 'Hide' : 'Reveal' }}</span>
              </button>
            </div>
          </div>
        </div>

        <div class="detail-card section-card">
          <h3 class="section-title">Risk &amp; Performance Standing</h3>
          <div class="field-grid-3">
            <div class="field-cell">
              <span class="field-label">Risk Level</span>
              <div>
                <BaseBadge size="sm" :color="getRiskBadgeColor(supplier.risk.risk_level)">
                  {{ getRiskLabel(supplier.risk.risk_level) }} ({{ supplier.risk.risk_score }})
                </BaseBadge>
              </div>
            </div>
            <div class="field-cell">
              <span class="field-label">Spend Concentration</span>
              <span class="field-value">{{ supplier.risk.concentration_percent }}%</span>
            </div>
            <div class="field-cell">
              <span class="field-label">Dual PO Approval</span>
              <span class="field-value">{{ supplier.risk.requires_dual_approval ? 'Required' : 'Not Required' }}</span>
            </div>
          </div>
          <div class="field-grid-3">
            <div class="field-cell">
              <span class="field-label">Next Risk Review</span>
              <span class="field-value">{{ formatDisplayDate(supplier.risk.next_review_at) }}</span>
            </div>
            <div class="field-cell">
              <span class="field-label">Latest Scorecard</span>
              <span class="field-value">
                {{ supplier.scorecard ? `${supplier.scorecard.overall_score.toFixed(1)} / 100` : 'Not rated yet' }}
              </span>
            </div>
            <div class="field-cell">
              <span class="field-label">Open Risks</span>
              <span class="field-value">
                {{ supplier.risk.events.filter((e) => e.status === 'open').length }} Open
              </span>
            </div>
          </div>
          <div class="section-inline-divider"></div>
          <div class="field-grid-3">
            <div class="field-cell">
              <span class="field-label">Primary Contact</span>
              <span class="field-value">{{ supplier.contact_person }}</span>
            </div>
            <div class="field-cell">
              <span class="field-label">Official Email</span>
              <a :href="`mailto:${supplier.email}`" class="field-value field-value--link">{{ supplier.email }}</a>
            </div>
            <div class="field-cell">
              <span class="field-label">Phone</span>
              <span class="field-value">{{ supplier.phone }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- ═════════ TAB 2: RISK PROFILE & EVENTS (Authoritative Accordion Cards + DynamicSubTable) ═════════ -->
      <div v-else-if="activeTab === 'risk'" class="tab-stack">
        <div class="detail-card accordion-card">
          <div
            class="card-accordion-header"
            :class="{ 'is-collapsed': collapsedSections.riskProfile }"
            @click="collapsedSections.riskProfile = !collapsedSections.riskProfile"
          >
            <div class="accordion-header-left">
              <span>Supplier Risk Profile</span>
              <ChevronDown v-if="!collapsedSections.riskProfile" :size="16" class="header-chevron" />
              <ChevronRight v-else :size="16" class="header-chevron" />
            </div>
            <BaseBadge size="sm" :color="getRiskBadgeColor(supplier.risk.risk_level)">
              {{ getRiskLabel(supplier.risk.risk_level) }} • {{ supplier.risk.risk_score }} / 100
            </BaseBadge>
          </div>

          <div v-show="!collapsedSections.riskProfile" class="card-accordion-body">
            <div class="body-action-row">
              <p class="section-subtitle">
                Assessed by {{ supplier.risk.assessed_by }} on {{ formatDisplayDate(supplier.risk.assessed_at) }}.
              </p>
              <AppButton variant="secondary-gray" size="sm" @click="openRiskProfileModal">
                <Edit2 :size="14" />
                Update Risk Profile
              </AppButton>
            </div>

            <div class="field-grid-3">
              <div class="field-cell">
                <span class="field-label">Spend Concentration</span>
                <span class="field-value">{{ supplier.risk.concentration_percent }}%</span>
              </div>
              <div class="field-cell">
                <span class="field-label">Requires Dual PO Approval</span>
                <span class="field-value">{{ supplier.risk.requires_dual_approval ? 'Required' : 'Not Required' }}</span>
              </div>
              <div class="field-cell">
                <span class="field-label">Next Review Date</span>
                <span class="field-value">{{ formatDisplayDate(supplier.risk.next_review_at) }}</span>
              </div>
            </div>

            <div v-if="supplier.risk.restrictions && supplier.risk.restrictions !== 'None'" class="bank-pill-block">
              <span class="field-label">Active Trading Restrictions</span>
              <div class="bank-pill-box">
                <span class="bank-pill-name">{{ supplier.risk.restrictions }}</span>
              </div>
            </div>
          </div>
        </div>

        <div class="detail-card accordion-card">
          <div
            class="card-accordion-header"
            :class="{ 'is-collapsed': collapsedSections.riskEvents }"
            @click="collapsedSections.riskEvents = !collapsedSections.riskEvents"
          >
            <div class="accordion-header-left">
              <span>Risk Events Register</span>
              <ChevronDown v-if="!collapsedSections.riskEvents" :size="16" class="header-chevron" />
              <ChevronRight v-else :size="16" class="header-chevron" />
            </div>
            <BaseBadge size="sm" color="blue">
              {{ supplier.risk.events.length }} {{ supplier.risk.events.length === 1 ? 'Event' : 'Events' }}
            </BaseBadge>
          </div>

          <div v-show="!collapsedSections.riskEvents" class="card-accordion-body">
            <div class="body-action-row">
              <p class="section-subtitle">
                Audit log of supplier risk incidents and active mitigations. New events start as Open.
              </p>
              <AppButton variant="primary" size="sm" @click="openRiskModal">
                <Plus :size="15" />
                Add Risk Event
              </AppButton>
            </div>

            <div class="erp-table-wrap">
              <table class="erp-table">
                <thead>
                  <tr>
                    <th class="th-lead">Risk Incident</th>
                    <th>Type</th>
                    <th>Severity</th>
                    <th>Mitigation</th>
                    <th>Raised</th>
                    <th>Status</th>
                    <th class="th-actions">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-if="supplier.risk.events.length === 0">
                    <td colspan="7" class="empty-cell">No risk events recorded for this supplier.</td>
                  </tr>
                  <tr v-for="ev in supplier.risk.events" :key="ev.id" class="erp-row">
                    <td class="td-lead">
                      <div class="cell-stack">
                        <span class="cell-primary">{{ ev.description }}</span>
                        <span class="cell-sub">{{ ev.evidence_note }}</span>
                      </div>
                    </td>
                    <td><span class="cell-muted">{{ formatAppType(ev.risk_type) }}</span></td>
                    <td>
                      <BaseBadge size="sm" :color="getRiskBadgeColor(ev.risk_level)">
                        {{ formatAppType(ev.risk_level) }}
                      </BaseBadge>
                    </td>
                    <td><span class="cell-muted">{{ ev.mitigation }}</span></td>
                    <td><span class="cell-muted">{{ formatDisplayDate(ev.raised_at) }}</span></td>
                    <td>
                      <BaseBadge
                        size="sm"
                        :color="ev.status === 'closed' ? 'success' : ev.status === 'mitigated' ? 'blue' : 'warning'"
                      >
                        {{ formatAppType(ev.status) }}
                      </BaseBadge>
                    </td>
                    <td class="td-actions">
                      <BaseDropdownMenu :items="getRiskEventActions(ev)" minWidth="180px">
                        <template #trigger="{ toggle }">
                          <button type="button" class="btn-action-dots" title="Actions" @click.stop="toggle">
                            <MoreVertical :size="18" />
                          </button>
                        </template>
                      </BaseDropdownMenu>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <!-- ═════════ TAB 3: PRICE LISTS (QuickCreateModal [DIST] + Collapsible Accordion DynamicSubTable [LINE]) ═════════ -->
      <div v-else-if="activeTab === 'price_lists'" class="tab-stack">
        <div class="detail-card section-card">
          <div class="section-header-row">
            <div>
              <h3 class="section-title">Agreed Price Lists</h3>
              <p class="section-subtitle">Manage supplier catalogues, contract rate sheets, and itemized unit prices.</p>
            </div>
            <AppButton variant="primary" size="sm" @click="openPriceListModal">
              <Plus :size="15" />
              Add Price List
            </AppButton>
          </div>
        </div>

        <div v-if="supplier.price_lists.length === 0" class="detail-card empty-card">
          <p class="empty-title">No price lists configured</p>
          <p class="empty-sub">Use Add Price List above to record a catalogue or contract rate sheet.</p>
        </div>

        <div v-for="pl in supplier.price_lists" :key="pl.id" class="detail-card accordion-card">
          <div
            class="card-accordion-header"
            :class="{ 'is-collapsed': isPriceListCollapsed(pl.id) }"
            @click="togglePriceListCollapse(pl.id)"
          >
            <div class="accordion-header-left">
              <span>{{ pl.name }} ({{ pl.code }})</span>
              <ChevronDown v-if="!isPriceListCollapsed(pl.id)" :size="16" class="header-chevron" />
              <ChevronRight v-else :size="16" class="header-chevron" />
            </div>
            <BaseBadge size="sm" :color="pl.status === 'active' ? 'success' : 'primary'">
              {{ formatAppType(pl.status) }}
            </BaseBadge>
          </div>

          <div v-show="!isPriceListCollapsed(pl.id)" class="card-accordion-body">
            <p class="section-subtitle">
              {{ pl.source === 'contract' ? 'Contract Rate Sheet' : 'Supplier Catalogue' }} •
              {{ pl.currency_id }} •
              Valid {{ formatDisplayDate(pl.valid_from) }} → {{ formatDisplayDate(pl.valid_to, 'Open') }} •
              {{ pl.includes_tax ? 'Tax Included' : 'Excl. Tax' }} •
              {{ pl.includes_delivery ? 'Delivery Included' : 'Excl. Delivery' }}
            </p>

            <DynamicSubTable
              v-model="pl.items"
              :columns="priceListItemColumns"
              entity-name="Rate Item"
              entity-name-plural="Rate Items"
              empty-text="No rate items configured. Click Add Row below to add prices."
              :new-row-factory="() => createPriceListItemRow(pl.items.length)"
              :can-export="true"
              :can-import="true"
              :default-initial-row="false"
            >
              <template #expand-modal="{ row }">
                <div class="modal-form-stack">
                  <div class="modal-form-grid-2">
                    <FormInput
                      v-model="row.product_name"
                      label="Item / Service Name"
                      placeholder=""
                      required
                    />
                    <FormInput
                      v-model="row.supplier_item_code"
                      label="Supplier SKU / Code"
                      placeholder=""
                    />
                  </div>
                  <div class="modal-form-grid-2">
                    <FormInput
                      v-model="row.unit_price"
                      :label="`Unit Price (${pl.currency_id})`"
                      type="number"
                      placeholder=""
                      required
                    />
                    <FormInput
                      v-model="row.measurement_id"
                      label="Unit of Measure (UOM)"
                      placeholder=""
                      required
                    />
                  </div>
                  <div class="modal-form-grid-2">
                    <FormInput
                      v-model="row.minimum_quantity"
                      label="Minimum Quantity"
                      type="number"
                      placeholder=""
                    />
                    <FormInput
                      :model-value="row.maximum_quantity ?? ''"
                      label="Maximum Quantity"
                      type="number"
                      placeholder=""
                      @update:model-value="row.maximum_quantity = $event === '' ? null : Number($event)"
                    />
                  </div>
                  <div class="modal-form-grid-2">
                    <FormInput
                      v-model="row.lead_time_days"
                      label="Lead Time (Days)"
                      type="number"
                      placeholder=""
                    />
                    <FormInput
                      :model-value="row.minimum_billable_quantity ?? ''"
                      label="Min Billable Qty"
                      type="number"
                      placeholder=""
                      @update:model-value="row.minimum_billable_quantity = $event === '' ? null : Number($event)"
                    />
                  </div>
                  <FormCheckbox
                    v-model="row.is_available"
                    label="Available for Ordering"
                    description="Allow buyers to select this item on new purchase orders."
                  />
                </div>
              </template>
            </DynamicSubTable>
          </div>
        </div>
      </div>

      <!-- ═════════ TAB 4: PERFORMANCE (Authoritative Accordion Cards — Actions & Descriptions Inside Body) ═════════ -->
      <div v-else-if="activeTab === 'performance'" class="tab-stack">
        <div class="detail-card accordion-card">
          <div
            class="card-accordion-header"
            :class="{ 'is-collapsed': collapsedSections.scorecard }"
            @click="collapsedSections.scorecard = !collapsedSections.scorecard"
          >
            <div class="accordion-header-left">
              <span>{{ supplier.scorecard ? `${supplier.scorecard.scorecard_number} — ${supplier.scorecard.period_label}` : 'Scorecard Breakdown' }}</span>
              <ChevronDown v-if="!collapsedSections.scorecard" :size="16" class="header-chevron" />
              <ChevronRight v-else :size="16" class="header-chevron" />
            </div>
            <BaseBadge
              v-if="supplier.scorecard"
              size="sm"
              :color="getGradeBadgeColor(supplier.scorecard.grade)"
            >
              {{ supplier.scorecard.overall_score.toFixed(1) }} • {{ getGradeLabel(supplier.scorecard.grade) }}
            </BaseBadge>
          </div>

          <div v-show="!collapsedSections.scorecard" class="card-accordion-body">
            <div class="body-action-row">
              <p class="section-subtitle">
                Weighted KPI score distribution across delivery, quality, price variance, and responsiveness.
              </p>
              <AppButton variant="primary" size="sm" @click="openScorecardModal">
                <Plus :size="15" />
                Record Scorecard
              </AppButton>
            </div>

            <div v-if="supplier.scorecard" class="kpi-bars-list">
              <div v-for="line in supplier.scorecard.lines" :key="line.code" class="kpi-bar-row">
                <div class="kpi-bar-head">
                  <span class="kpi-bar-name">{{ line.name }} <span class="kpi-bar-weight">({{ line.weight }}% weight)</span></span>
                  <span class="kpi-bar-score">{{ line.score.toFixed(1) }} / 100</span>
                </div>
                <div class="kpi-bar-track">
                  <div
                    class="kpi-bar-fill"
                    :style="{ width: `${Math.min(100, Math.max(0, line.score))}%`, backgroundColor: getScoreBarColor(line.score) }"
                  ></div>
                </div>
              </div>
            </div>
            <div v-else class="empty-cell">No scorecard evaluated for this supplier yet. Click Record Scorecard above to log KPI scores.</div>
          </div>
        </div>

        <div class="detail-card accordion-card">
          <div
            class="card-accordion-header"
            :class="{ 'is-collapsed': collapsedSections.improvementActions }"
            @click="collapsedSections.improvementActions = !collapsedSections.improvementActions"
          >
            <div class="accordion-header-left">
              <span>Improvement Actions</span>
              <ChevronDown v-if="!collapsedSections.improvementActions" :size="16" class="header-chevron" />
              <ChevronRight v-else :size="16" class="header-chevron" />
            </div>
            <BaseBadge size="sm" color="blue">
              {{ supplier.improvement_actions.length }} {{ supplier.improvement_actions.length === 1 ? 'Action' : 'Actions' }}
            </BaseBadge>
          </div>

          <div v-show="!collapsedSections.improvementActions" class="card-accordion-body">
            <div class="body-action-row">
              <p class="section-subtitle">
                Corrective, preventive, or warning follow-ups assigned when scorecard targets are missed.
              </p>
              <AppButton variant="primary" size="sm" @click="openActionModal">
                <Plus :size="15" />
                Add Action
              </AppButton>
            </div>

            <div class="erp-table-wrap">
              <table class="erp-table">
                <thead>
                  <tr>
                    <th class="th-lead">Action</th>
                    <th>Type</th>
                    <th>Target Date</th>
                    <th>Status</th>
                    <th class="th-actions">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-if="supplier.improvement_actions.length === 0">
                    <td colspan="5" class="empty-cell">No improvement actions assigned.</td>
                  </tr>
                  <tr v-for="act in supplier.improvement_actions" :key="act.id" class="erp-row">
                    <td class="td-lead">
                      <div class="cell-stack">
                        <span class="cell-primary">{{ act.title }}</span>
                        <span class="cell-sub">{{ act.code }}</span>
                      </div>
                    </td>
                    <td><span class="cell-muted">{{ formatAppType(act.action_type) }}</span></td>
                    <td><span class="cell-muted">{{ formatDisplayDate(act.target_date) }}</span></td>
                    <td>
                      <BaseBadge
                        size="sm"
                        :color="act.status === 'verified' ? 'success' : act.status === 'in_progress' ? 'indigo' : 'warning'"
                      >
                        {{ formatAppType(act.status) }}
                      </BaseBadge>
                    </td>
                    <td class="td-actions">
                      <BaseDropdownMenu :items="getImprovementActionsMenu(act)" minWidth="180px">
                        <template #trigger="{ toggle }">
                          <button type="button" class="btn-action-dots" title="Actions" @click.stop="toggle">
                            <MoreVertical :size="18" />
                          </button>
                        </template>
                      </BaseDropdownMenu>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <!-- ═════════ INTERACTIVE RATING MODAL & QUICK CREATE MODALS ═════════ -->
      <SupplierRatingModal
        v-model="showRatingModal"
        :supplier="supplier"
        :initial-stars="ratingInitialStars"
      />

      <QuickCreateModal
        v-model="showPriceListModal"
        title="Create Price List"
        :show-expand-button="false"
        save-label="Save"
        width="md"
        @save="handleAddPriceList"
      >
        <div class="modal-form-stack">
          <FormInput v-model="priceListForm.name" label="Price List Name" placeholder="" required />
          <div class="modal-form-grid-2">
            <FormSelect
              v-model="priceListForm.source"
              label="Source"
              :options="priceListSourceOptions"
              placeholder="Select Source"
              required
            />
            <FormSelect
              v-model="priceListForm.currency_id"
              label="Currency"
              :options="currencyOptions"
              placeholder="Select Currency"
              required
            />
          </div>
          <div class="modal-form-grid-2">
            <FormInput v-model="priceListForm.valid_from" label="Valid From" type="date" placeholder="" required />
            <FormInput v-model="priceListForm.valid_to" label="Valid To" type="date" placeholder="" />
          </div>
          <div class="checkbox-row-2">
            <FormCheckbox
              v-model="priceListForm.includes_tax"
              label="Includes VAT / Tax"
              description="Unit prices already include applicable taxes."
            />
            <FormCheckbox
              v-model="priceListForm.includes_delivery"
              label="Includes Delivery"
              description="Quoted rates cover delivery to the receiving site."
            />
          </div>
        </div>
      </QuickCreateModal>

      <QuickCreateModal
        v-model="showScorecardModal"
        title="Record Scorecard"
        :show-expand-button="false"
        save-label="Save"
        width="md"
        @save="handleSaveScorecard"
      >
        <div class="modal-form-stack">
          <FormInput v-model="scorecardDraft.period_label" label="Evaluation Period" placeholder="" required />
          <div class="modal-form-grid-2">
            <FormInput v-model="scorecardDraft.otd" label="On-Time Delivery (35%)" type="number" placeholder="" required />
            <FormInput v-model="scorecardDraft.quality" label="Quality Acceptance (35%)" type="number" placeholder="" required />
          </div>
          <div class="modal-form-grid-2">
            <FormInput v-model="scorecardDraft.price" label="Price Variance (20%)" type="number" placeholder="" required />
            <FormInput v-model="scorecardDraft.comms" label="Responsiveness (10%)" type="number" placeholder="" required />
          </div>
        </div>
      </QuickCreateModal>

      <QuickCreateModal
        v-model="showRiskProfileModal"
        title="Update Risk Profile"
        :show-expand-button="false"
        save-label="Save"
        width="md"
        @save="handleUpdateRiskProfile"
      >
        <div class="modal-form-stack">
          <div class="modal-form-grid-2">
            <FormSelect
              v-model="riskProfileForm.risk_level"
              label="Risk Level"
              :options="riskLevelOptions"
              placeholder="Select Level"
              required
            />
            <FormInput
              v-model="riskProfileForm.risk_score"
              label="Risk Score (0 – 100)"
              type="number"
              placeholder=""
              required
            />
          </div>
          <div class="modal-form-grid-2">
            <FormInput
              v-model="riskProfileForm.concentration_percent"
              label="Spend Concentration (%)"
              type="number"
              placeholder=""
            />
            <FormInput
              v-model="riskProfileForm.next_review_at"
              label="Next Review Date"
              type="date"
              placeholder=""
            />
          </div>
          <FormInput
            v-model="riskProfileForm.restrictions"
            label="Active Trading Restrictions"
            placeholder=""
          />
          <FormCheckbox
            v-model="riskProfileForm.requires_dual_approval"
            label="Requires Dual PO Approval"
            description="Every purchase order issued to this supplier must be approved by a second approver."
          />
        </div>
      </QuickCreateModal>

      <QuickCreateModal
        v-model="showRiskModal"
        title="Add Risk Event"
        :show-expand-button="false"
        save-label="Save"
        width="md"
        @save="handleAddRiskEvent"
      >
        <div class="modal-form-stack">
          <div class="modal-form-grid-2">
            <FormSelect
              v-model="riskForm.risk_type"
              label="Risk Type"
              :options="riskTypeOptions"
              placeholder="Select Type"
              required
            />
            <FormSelect
              v-model="riskForm.risk_level"
              label="Severity"
              :options="riskLevelOptions"
              placeholder="Select Level"
              required
            />
          </div>
          <FormInput v-model="riskForm.description" label="Incident Summary" placeholder="" required />
          <div class="modal-form-grid-2">
            <FormInput v-model="riskForm.evidence_note" label="Evidence Reference" placeholder="" />
            <FormInput v-model="riskForm.review_due_at" label="Review Due Date" type="date" placeholder="" />
          </div>
          <FormInput v-model="riskForm.mitigation" label="Mitigation Plan" placeholder="" />
        </div>
      </QuickCreateModal>

      <QuickCreateModal
        v-model="showActionModal"
        title="Add Improvement Action"
        :show-expand-button="false"
        save-label="Save"
        width="md"
        @save="handleAddImprovementAction"
      >
        <div class="modal-form-stack">
          <FormInput v-model="actionForm.title" label="Action Title" placeholder="" required />
          <div class="modal-form-grid-2">
            <FormSelect
              v-model="actionForm.action_type"
              label="Action Type"
              :options="actionTypeOptions"
              placeholder="Select Type"
              required
            />
            <FormInput v-model="actionForm.target_date" label="Target Completion Date" type="date" placeholder="" required />
          </div>
        </div>
      </QuickCreateModal>
    </template>
  </div>
</template>

<style scoped>
.supplier-detail-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.detail-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  overflow: hidden;
}

.empty-card {
  padding: 48px 24px;
  text-align: center;
}

.empty-title {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #404040;
}

.empty-sub {
  margin: 6px 0 0;
  font-size: 13.5px;
  color: #737373;
}

/* Minimalist Hero Card (Inspired by Figma 10803:71313) */
.hero-card-wrap {
  display: flex;
  flex-direction: column;
}

.hero-card {
  padding: 20px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  flex-wrap: wrap;
}

.hero-left {
  display: flex;
  align-items: center;
  gap: 20px;
}

.hero-supplier-avatar {
  width: 88px !important;
  height: 88px !important;
  font-size: 26px !important;
  box-shadow: 0 2px 8px rgba(10, 13, 18, 0.06);
}

.hero-identity {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.hero-title-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.hero-title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #404040;
}

.hero-meta {
  font-size: 13px;
  font-weight: 400;
  color: #737373;
}

.hero-rating-inline {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
  margin-top: 2px;
}

.hero-star-row {
  display: inline-flex;
  align-items: center;
  gap: 2px;
}

.hero-star-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 1px;
  border: none;
  background: transparent;
  cursor: pointer;
  transition: transform 0.12s ease;
}

.hero-star-btn:hover {
  transform: scale(1.12);
}

.hero-star-img {
  display: block;
  width: 18px;
  height: 18px;
}

.hero-score-val {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.hero-score-rest {
  font-size: 12.5px;
  font-weight: 400;
  color: #737373;
}

.hero-contacts {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.contact-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  font-weight: 400;
  color: #737373;
  text-decoration: none;
}

.contact-item--link {
  color: #0b529c;
  font-weight: 400;
}

.contact-item--link:hover {
  text-decoration: underline;
}

.contact-icon {
  color: #737373;
  flex-shrink: 0;
}

.star-picker-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.star-btn {
  background: none;
  border: none;
  padding: 2px;
  cursor: pointer;
  display: inline-flex;
}

.rating-preview-text {
  margin-left: 8px;
  font-size: 13px;
  color: #737373;
}

/* Primary Tabs sitting directly on the main canvas */
.detail-tabs-row {
  display: flex;
  align-items: center;
}

.inline-action-link {
  background: none;
  border: none;
  padding: 0;
  font-size: 13px;
  font-weight: 500;
  color: #0b529c;
  text-decoration: underline;
  cursor: pointer;
}

/* Minimal Overview 2-Card Layout (Directly on main canvas) */
.overview-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 20px;
  align-items: start;
}

.tab-stack {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.section-card {
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.section-header-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}

.section-header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.section-title {
  margin: 0;
  font-size: 15.5px;
  font-weight: 600;
  color: #404040;
}

.section-subtitle {
  margin: 4px 0 0;
  font-size: 13px;
  font-weight: 400;
  color: #737373;
}

/* Minimal Field Hierarchy: Title = 600 #404040, Label = 400 #737373, Value = 400 #404040 (never competing bold) */
.field-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px 20px;
}

.field-cell {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.field-label {
  font-size: 12px;
  font-weight: 400;
  color: #737373;
}

.field-value {
  font-size: 14px;
  font-weight: 400;
  color: #404040;
  word-break: break-word;
}

.field-value--link {
  color: #0b529c;
  text-decoration: none;
}

.field-value--link:hover {
  text-decoration: underline;
}

.section-inline-divider {
  height: 1px;
  background-color: #f0f0f0;
  width: 100%;
}

.bank-pill-block {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.bank-pill-box {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 10px 14px;
  background-color: #fafafa;
  border: 1px solid #e5e5e5;
  border-radius: 10px;
}

.bank-pill-info {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.bank-pill-name,
.bank-pill-mask {
  font-size: 13px;
  font-weight: 400;
  color: #737373;
  font-variant-numeric: tabular-nums;
}

.btn-reveal-bank {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  padding: 4px 10px;
  font-size: 12px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  flex-shrink: 0;
  transition: background-color 0.15s ease, border-color 0.15s ease;
}

.btn-reveal-bank:hover {
  background-color: #f5f5f5;
  border-color: #d4d4d4;
}

/* Authoritative Collapsible Accordion Cards (Title + Chevron + Optional Badge ONLY in header) */
.accordion-card {
  display: flex;
  flex-direction: column;
}

.card-accordion-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 16px 24px;
  cursor: pointer;
  user-select: none;
  background-color: #ffffff;
  font-size: 14.5px;
  font-weight: 600;
  color: #404040;
  border-bottom: 1px solid #e5e5e5;
  transition: background-color 0.15s ease;
}

.card-accordion-header.is-collapsed {
  border-bottom: none;
}

.card-accordion-header:hover {
  background-color: #fafafa;
}

.accordion-header-left {
  display: flex;
  align-items: center;
  gap: 6px;
  min-width: 0;
}

.header-chevron {
  color: #737373;
  flex-shrink: 0;
}

.card-accordion-body {
  padding: 20px 24px 24px;
  background-color: #ffffff;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.body-action-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}

.readonly-badge-cell {
  display: flex;
  align-items: center;
  padding: 0 12px;
  height: 100%;
}

/* DynamicSubTable Container (Authoritative 24px inset padding) */
.subtable-card {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* QuickCreateModal & DynamicTableModal Form Grids */
.modal-form-stack {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.modal-form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.checkbox-row-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
  padding-top: 4px;
}

/* KPI Progress Bars */
.kpi-bars-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.kpi-bar-row {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.kpi-bar-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 13.5px;
}

.kpi-bar-name {
  font-weight: 400;
  color: #404040;
}

.kpi-bar-weight {
  font-weight: 400;
  color: #737373;
}

.kpi-bar-score {
  font-weight: 500;
  color: #404040;
}

.kpi-bar-track {
  height: 8px;
  width: 100%;
  background-color: #f5f5f5;
  border-radius: 9999px;
  overflow: hidden;
}

.kpi-bar-fill {
  height: 100%;
  border-radius: 9999px;
  transition: width 0.25s ease;
}

/* Tables */
.table-card {
  display: flex;
  flex-direction: column;
}

.card-heading {
  padding: 20px 24px;
  border-bottom: 1px solid #e9eaeb;
}

.price-list-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}

.erp-table-wrap {
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  overflow: hidden;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table thead th {
  height: 44px;
  padding: 0 16px;
  background-color: #fafafa;
  border-bottom: 1px solid #e9eaeb;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  text-align: left;
}

.erp-table thead th.th-lead {
  padding-left: 24px;
}

.erp-table thead th.th-actions {
  text-align: right;
  padding-right: 24px;
  width: 68px;
}

.erp-row {
  border-bottom: 1px solid #f0f0f0;
  transition: background-color 0.12s ease;
}

.erp-row:last-child {
  border-bottom: none;
}

.erp-row:hover {
  background-color: #fafafa;
}

.erp-table tbody td {
  padding: 14px 16px;
  vertical-align: middle;
}

.erp-table tbody td.td-lead {
  padding-left: 24px;
}

.erp-table tbody td.td-actions {
  padding-right: 24px;
  text-align: right;
}

.cell-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.cell-primary {
  font-size: 13.5px;
  font-weight: 400;
  color: #404040;
}

.cell-sub {
  font-size: 12px;
  font-weight: 400;
  color: #737373;
}

.cell-muted {
  font-size: 13.5px;
  font-weight: 400;
  color: #737373;
}

.empty-cell {
  padding: 32px 24px;
  text-align: center;
  font-size: 13.5px;
  color: #737373;
}

.btn-action-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  border: none;
  border-radius: 6px;
  background: transparent;
  color: #737373;
  cursor: pointer;
}

.btn-action-dots:hover {
  background-color: #f0f0f0;
  color: #404040;
}

@media (max-width: 1120px) {
  .overview-grid-2,
  .field-grid-3,
  .modal-form-grid-2 {
    grid-template-columns: 1fr;
  }
}
</style>
