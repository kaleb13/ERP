<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import {
  ShieldCheck, Calendar, Clock, Building2,
  CheckCircle2, AlertCircle, Maximize2, X,
  Check, Scale, Edit3, Calculator
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import UnderlineTabs, { type UnderlineTabItem } from '../../components/UnderlineTabs.vue';
import { 
  getPolicyById, 
  leavePoliciesData, 
  type LeavePolicyRecord, 
  type LeavePolicyRuleRecord 
} from './leavePolicyData';

const route = useRoute();
const router = useRouter();

const policyId = Number(route.params.id);
const policy = ref<LeavePolicyRecord | undefined>(getPolicyById(policyId) || leavePoliciesData.value[0]);

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3: Child Page Breadcrumb) ───
const breadcrumbItems = computed(() => [
  { label: 'Leave Policies', to: '/hr/leave-policies' },
  { label: policy.value ? `${policy.value.code} — ${policy.value.name}` : 'Policy Detail' }
]);

const toastMessage = ref<string | null>(null);
const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── State Management ───
const togglePolicyState = () => {
  if (!policy.value) return;
  policy.value.state = policy.value.state === 'active' ? 'inactive' : 'active';
  showToast(`Policy state updated to ${policy.value.state.toUpperCase()}.`);
};

const goToEdit = () => {
  if (policy.value) {
    router.push({
      path: '/hr/leave-policies/create',
      query: { editId: policy.value.id }
    });
  }
};

// ─── Sub-Navigation Underline Tabs ───
type DetailTabKey = 'rules' | 'scope' | 'simulator';
const activeTab = ref<DetailTabKey>('rules');

const tabs = computed<UnderlineTabItem<DetailTabKey>[]>(() => [
  { 
    id: 'rules', 
    label: 'Entitlement Rules & Matrices', 
    count: policy.value ? policy.value.rules.length : 0 
  },
  { 
    id: 'scope', 
    label: 'Policy Scope & Blueprint' 
  },
  { 
    id: 'simulator', 
    label: 'Statutory Accrual Simulator' 
  }
]);

// ─── Inspection Modal for a Rule ───
const selectedInspectRule = ref<LeavePolicyRuleRecord | null>(null);

const openInspectModal = (rule: LeavePolicyRuleRecord) => {
  selectedInspectRule.value = rule;
};

const closeInspectModal = () => {
  selectedInspectRule.value = null;
};

// ─── Accrual Simulator State ───
const selectedSimRuleId = ref<number>(policy.value?.rules[0]?.id || 101);
const simYearsOfService = ref<number>(3);

const selectedSimRule = computed(() => {
  if (!policy.value) return null;
  return policy.value.rules.find(r => r.id === selectedSimRuleId.value) || policy.value.rules[0] || null;
});

const simCalculatedDays = computed(() => {
  const rule = selectedSimRule.value;
  if (!rule) return 0;
  if (rule.accrual_method === 'per_service_year') {
    const raw = rule.days_per_year + (rule.extra_days_per_service_year * simYearsOfService.value);
    return rule.max_days ? Math.min(raw, rule.max_days) : raw;
  }
  return rule.days_per_year;
});

const simIsCapped = computed(() => {
  const rule = selectedSimRule.value;
  if (!rule || !rule.max_days) return false;
  const raw = rule.days_per_year + (rule.extra_days_per_service_year * simYearsOfService.value);
  return raw >= rule.max_days;
});

// 15-Year Progression Schedule for Simulator
const simProgressionRows = computed(() => {
  const rule = selectedSimRule.value;
  if (!rule) return [];
  const rows = [];
  for (let y = 0; y <= 15; y++) {
    let days = rule.days_per_year;
    if (rule.accrual_method === 'per_service_year') {
      const raw = rule.days_per_year + (rule.extra_days_per_service_year * y);
      days = rule.max_days ? Math.min(raw, rule.max_days) : raw;
    }
    const isCap = rule.max_days ? days >= rule.max_days : false;
    rows.push({ year: y, days, isCap });
  }
  return rows;
});
</script>

<template>
  <div class="leave-policy-detail-page">
    <!-- Top Bar (AGENTS.md Rule 3 & Breadcrumb Standard) -->
    <div class="top-nav-bar">
      <AppBreadcrumb :items="breadcrumbItems" />

      <div class="top-actions-cluster" v-if="policy">
        <!-- State Status Pill (Rule 9: Active/Inactive reserved for State) -->
        <span 
          class="status-pill"
          :class="policy.state === 'active' ? 'state-active' : 'state-inactive'"
        >
          {{ policy.state === 'active' ? 'Active Policy' : 'Inactive Policy' }}
        </span>

        <!-- Edit Policy Action -->
        <AppButton variant="outline" size="sm" @click="goToEdit">
          <template #icon-left><Edit3 :size="14" /></template>
          Edit Policy
        </AppButton>

        <!-- Toggle State Action Button -->
        <AppButton variant="outline" size="sm" @click="togglePolicyState">
          <template #icon-left><ShieldCheck :size="14" /></template>
          Mark as {{ policy.state === 'active' ? 'Inactive' : 'Active' }}
        </AppButton>
      </div>
    </div>

    <!-- Toast Feedback -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <div v-if="policy" class="policy-detail-content">
      <!-- SECTION 1: MASTER POLICY IDENTITY HERO CARD (Strict Schema Alignment) -->
      <div class="clean-card hero-policy-card">
        <div class="card-hero-bar">
          <div class="policy-hero-text">
            <div class="title-row">
              <h1 class="policy-headline">{{ policy.name }}</h1>
              <span class="policy-code-badge">{{ policy.code }}</span>
            </div>
            <p v-if="policy.description" class="policy-description">{{ policy.description }}</p>
          </div>
        </div>

        <!-- 4 Key Scope Pillars -->
        <div class="meta-stats-grid">
          <!-- Owning Entity / Branch -->
          <div class="meta-stat-item">
            <span class="meta-stat-label">Owning Entity</span>
            <span class="meta-stat-value">{{ policy.entity_name }}</span>
            <span class="meta-stat-subtext">Line Tenancy • Full Subtree Scope</span>
          </div>

          <!-- Work Calendar -->
          <div class="meta-stat-item">
            <span class="meta-stat-label">Work Calendar Engine</span>
            <span class="meta-stat-value">{{ policy.work_calendar_name }}</span>
            <span class="meta-stat-subtext">{{ policy.calendar_weekly_hours }} hrs/wk • Skip Statutory Holidays</span>
          </div>

          <!-- Effective Period -->
          <div class="meta-stat-item">
            <span class="meta-stat-label">Effective Period</span>
            <span class="meta-stat-value">
              {{ policy.effective_from }} ➔ {{ policy.effective_to || 'Current' }}
            </span>
            <span class="meta-stat-subtext">Statutory Ethiopian Fiscal Cycle</span>
          </div>

          <!-- Configured Rules -->
          <div class="meta-stat-item">
            <span class="meta-stat-label">Rules Catalog</span>
            <span class="meta-stat-value">{{ policy.rules.length }} Entitlement Rules</span>
            <span class="meta-stat-subtext">100% Statutory Compliant</span>
          </div>
        </div>
      </div>

      <!-- SECTION 2: SUB-NAVIGATION TABS (AGENTS.md Rule 1: UnderlineTabs Standard) -->
      <div class="detail-tabs-wrap">
        <UnderlineTabs
          :tabs="tabs"
          v-model="activeTab"
          size="md"
        />
      </div>

      <!-- TAB 1: ENTITLEMENT RULES & MATRICES -->
      <div v-if="activeTab === 'rules'" class="tab-pane-content">
        <!-- Summary Metrics Strip -->
        <div class="rules-summary-strip">
          <div class="summary-stat-cell">
            <span class="stat-num">{{ policy.rules.length }}</span>
            <span class="stat-lbl">Entitlement Rules</span>
          </div>
          <div class="strip-divider"></div>
          <div class="summary-stat-cell">
            <span class="stat-num">{{ policy.rules.filter(r => r.pay_percent === 100).length }}</span>
            <span class="stat-lbl">Fully Paid (100% Basic)</span>
          </div>
          <div class="strip-divider"></div>
          <div class="summary-stat-cell">
            <span class="stat-num">30.0 d</span>
            <span class="stat-lbl">Statutory Annual Cap</span>
          </div>
          <div class="strip-divider"></div>
          <div class="summary-stat-cell">
            <span class="stat-num">10.0 d</span>
            <span class="stat-lbl">Max Carry-Forward (24 Mo)</span>
          </div>
        </div>

        <!-- Rules Table Card -->
        <div class="clean-card table-card-wrap">
          <div class="card-header-bar">
            <div>
              <h2 class="card-title">Configured Leave Entitlements</h2>
              <p class="card-subtitle">Active formulas, statutory increments, carry-forward caps, and encashment rights configured for this policy.</p>
            </div>
          </div>

          <div class="sub-table-wrap">
            <table class="erp-table child-table">
              <thead>
                <tr>
                  <th width="40" class="th-no">#</th>
                  <th>Leave Type</th>
                  <th>Accrual Method</th>
                  <th>Base Entitlement</th>
                  <th>Increment / Yr</th>
                  <th>Ceiling Cap</th>
                  <th>Compensation Pay</th>
                  <th>Carry-Forward</th>
                  <th>Notice Days</th>
                  <th>Eligible Gender</th>
                  <th width="50" class="th-actions text-center">Inspect</th>
                </tr>
              </thead>
              <tbody>
                <tr 
                  v-for="(rule, idx) in policy.rules" 
                  :key="rule.id" 
                  class="erp-row clickable-row"
                  @click="openInspectModal(rule)"
                >
                  <!-- Row number -->
                  <td class="td-no">{{ idx + 1 }}</td>

                  <!-- Leave Type (Name on top, Code on bottom) -->
                  <td>
                    <div class="rule-type-cell">
                      <span class="table-name-primary">{{ rule.leave_type_name }}</span>
                      <span class="table-code-subtext">{{ rule.leave_type_code }}</span>
                    </div>
                  </td>

                  <!-- Accrual Method -->
                  <td>
                    <span class="table-text-tertiary">
                      {{ rule.accrual_method === 'per_service_year' ? 'Per Service Year' :
                         rule.accrual_method === 'annual_grant' ? 'Annual Grant' :
                         rule.accrual_method === 'monthly_accrual' ? 'Monthly Accrual' : 'Fixed Allocation' }}
                    </span>
                  </td>

                  <!-- Base Days -->
                  <td>
                    <span class="table-text-primary font-medium">{{ rule.days_per_year.toFixed(1) }} d/yr</span>
                  </td>

                  <!-- Extra / Service Year -->
                  <td>
                    <span class="table-text-tertiary font-mono">
                      {{ rule.extra_days_per_service_year > 0 ? `+${rule.extra_days_per_service_year.toFixed(1)} d/yr` : '—' }}
                    </span>
                  </td>

                  <!-- Ceiling Cap -->
                  <td>
                    <span class="table-text-tertiary font-medium">
                      {{ rule.max_days ? `${rule.max_days.toFixed(1)} d` : 'Unlimited' }}
                    </span>
                  </td>

                  <!-- Compensation Pay Rate -->
                  <td>
                    <span 
                      class="pay-rate-badge"
                      :class="{
                        'pay-full': rule.pay_percent === 100,
                        'pay-half': rule.pay_percent > 0 && rule.pay_percent < 100,
                        'pay-unpaid': rule.pay_percent === 0
                      }"
                    >
                      {{ rule.pay_percent === 100 ? '100% Full Pay' : rule.pay_percent > 0 ? `${rule.pay_percent}% Pay` : 'Unpaid' }}
                    </span>
                  </td>

                  <!-- Carry Forward -->
                  <td>
                    <span class="table-text-tertiary">
                      {{ rule.max_carry_forward_days > 0 ? `${rule.max_carry_forward_days.toFixed(1)} d (${rule.carry_forward_expiry_months || 24}m)` : '0 d' }}
                    </span>
                  </td>

                  <!-- Notice Days -->
                  <td>
                    <span class="table-text-tertiary">
                      {{ rule.notice_days > 0 ? `${rule.notice_days} days` : 'Immediate' }}
                    </span>
                  </td>

                  <!-- Gender Restriction -->
                  <td>
                    <span class="table-text-tertiary capitalize">
                      {{ rule.gender ? `${rule.gender} only` : 'All Staff' }}
                    </span>
                  </td>

                  <!-- Inspect Button -->
                  <td class="td-actions text-center" @click.stop="openInspectModal(rule)">
                    <button type="button" class="btn-icon-sub" title="Inspect Full Parameters">
                      <Maximize2 :size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- TAB 2: POLICY SCOPE & BLUEPRINT ARCHITECTURE -->
      <div v-else-if="activeTab === 'scope'" class="tab-pane-content">
        <div class="scope-cards-grid">
          <!-- Card 1: Organizational Tenancy & Scope -->
          <div class="clean-card blueprint-card">
            <div class="bp-card-header">
              <Building2 :size="18" class="bp-icon" />
              <h3 class="bp-title">Organizational Scope &amp; Tenancy</h3>
            </div>
            <p class="bp-desc">Tenancy boundary and inherited branch application rules.</p>

            <div class="bp-meta-list">
              <div class="bp-meta-row">
                <span class="bp-lbl">Owning Entity:</span>
                <span class="bp-val">{{ policy.entity_name }}</span>
              </div>
              <div class="bp-meta-row">
                <span class="bp-lbl">Tenancy Level:</span>
                <span class="bp-val">Line Tenancy (Header Inheritance)</span>
              </div>
              <div class="bp-meta-row">
                <span class="bp-lbl">Tenant Root:</span>
                <span class="bp-val">Haleta Corporate Global</span>
              </div>
              <div class="bp-meta-row">
                <span class="bp-lbl">Multi-lingual Identifiers:</span>
                <span class="bp-val font-mono text-xs">en: {{ policy.name }}</span>
              </div>
              <div class="bp-meta-row">
                <span class="bp-lbl">Subtree Application:</span>
                <span class="bp-val text-emerald-700">Applies automatically to all child units and staff</span>
              </div>
            </div>
          </div>

          <!-- Card 2: Work Calendar & Day-Counting Engine -->
          <div class="clean-card blueprint-card">
            <div class="bp-card-header">
              <Clock :size="18" class="bp-icon" />
              <h3 class="bp-title">Work Calendar &amp; Day-Counting Engine</h3>
            </div>
            <p class="bp-desc">Day-counting rhythm, weekend exclusions, and holiday deduction logic.</p>

            <div class="bp-meta-list">
              <div class="bp-meta-row">
                <span class="bp-lbl">Work Calendar:</span>
                <span class="bp-val">{{ policy.work_calendar_name }}</span>
              </div>
              <div class="bp-meta-row">
                <span class="bp-lbl">Standard Working Hours:</span>
                <span class="bp-val">{{ policy.calendar_weekly_hours }}.0 Hours / Week (Monday – Friday)</span>
              </div>
              <div class="bp-meta-row">
                <span class="bp-lbl">Rest Days (Excluded):</span>
                <span class="bp-val">Saturday &amp; Sunday (Non-working)</span>
              </div>
              <div class="bp-meta-row">
                <span class="bp-lbl">Public Holiday Deduction:</span>
                <span class="bp-val text-emerald-700">Excluded (0h counted; leave balance preserved)</span>
              </div>
              <div class="bp-meta-row">
                <span class="bp-lbl">Counting Engine:</span>
                <span class="bp-val font-mono text-xs">WorkCalendar::SkipWeekendsAndHolidays</span>
              </div>
            </div>
          </div>

          <!-- Card 3: Regulatory Compliance & Governance -->
          <div class="clean-card blueprint-card">
            <div class="bp-card-header">
              <Scale :size="18" class="bp-icon" />
              <h3 class="bp-title">Statutory Basis &amp; Audit Log</h3>
            </div>
            <p class="bp-desc">Statutory proclamation alignment, effective dates, and audit trail.</p>

            <div class="bp-meta-list">
              <div class="bp-meta-row">
                <span class="bp-lbl">Governing Labour Law:</span>
                <span class="bp-val">Ethiopian Labour Proclamation 1156/2019</span>
              </div>
              <div class="bp-meta-row">
                <span class="bp-lbl">Key Statutory Articles:</span>
                <span class="bp-val">Articles 76–86 (Leave Rights &amp; Encashement)</span>
              </div>
              <div class="bp-meta-row">
                <span class="bp-lbl">Effective Date Range:</span>
                <span class="bp-val">{{ policy.effective_from }} ➔ {{ policy.effective_to || 'Current (Open)' }}</span>
              </div>
              <div class="bp-meta-row">
                <span class="bp-lbl">Creation Audit:</span>
                <span class="bp-val">Registered on {{ policy.created_at }}</span>
              </div>
              <div class="bp-meta-row">
                <span class="bp-lbl">Policy Status:</span>
                <span class="bp-val text-emerald-700 font-medium">Published &amp; Active Blueprint</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- TAB 3: STATUTORY ACCRUAL SIMULATOR -->
      <div v-else-if="activeTab === 'simulator'" class="tab-pane-content">
        <div class="simulator-layout-grid">
          <!-- Left: Simulation Controls -->
          <div class="clean-card sim-controls-card">
            <div class="card-header-bar">
              <div>
                <h3 class="card-title flex items-center gap-2">
                  <Calculator :size="17" class="text-sky-600" />
                  <span>Accrual Calculation Sandbox</span>
                </h3>
                <p class="card-subtitle">Test how entitlement formulas, service increments, and statutory ceilings evaluate for any employee.</p>
              </div>
            </div>

            <!-- Rule Selection -->
            <div class="sim-control-group">
              <label class="sim-label">Target Leave Type Rule</label>
              <select v-model="selectedSimRuleId" class="sim-select">
                <option v-for="r in policy.rules" :key="r.id" :value="r.id">
                  {{ r.leave_type_name }} ({{ r.accrual_method.replace(/_/g, ' ') }})
                </option>
              </select>
            </div>

            <!-- Years of Service Slider -->
            <div class="sim-control-group">
              <div class="slider-header-row">
                <label class="sim-label">Employee Completed Service</label>
                <span class="slider-val-badge">{{ simYearsOfService }} Years of Service</span>
              </div>
              <input 
                type="range" 
                v-model.number="simYearsOfService" 
                min="0" 
                max="15" 
                step="1"
                class="sim-range-slider"
              />
              <div class="slider-ticks-row">
                <span>0 yrs (Hire)</span>
                <span>5 yrs</span>
                <span>10 yrs</span>
                <span>15+ yrs</span>
              </div>
            </div>

            <!-- Live Entitlement Card Result -->
            <div v-if="selectedSimRule" class="sim-result-hero">
              <div class="sim-result-top">
                <div>
                  <span class="sim-res-sub">Computed Annual Entitlement</span>
                  <div class="sim-res-number">
                    <span>{{ simCalculatedDays.toFixed(1) }}</span>
                    <span class="sim-res-unit">Working Days / Year</span>
                  </div>
                </div>
                <div 
                  class="cap-pill"
                  :class="simIsCapped ? 'cap-pill--max' : 'cap-pill--active'"
                >
                  {{ simIsCapped ? '★ Maximum Statutory Cap' : 'Accruing Service Tier' }}
                </div>
              </div>

              <div class="sim-formula-box">
                <span class="formula-label">Calculation Formula:</span>
                <span class="formula-math" v-if="selectedSimRule.accrual_method === 'per_service_year'">
                  {{ selectedSimRule.days_per_year.toFixed(0) }} Base Days + ({{ selectedSimRule.extra_days_per_service_year.toFixed(0) }} Extra × {{ simYearsOfService }} Service Yrs) = {{ (selectedSimRule.days_per_year + selectedSimRule.extra_days_per_service_year * simYearsOfService).toFixed(0) }} Days
                  <span v-if="simIsCapped" class="text-amber-700 font-semibold"> (Capped at {{ selectedSimRule.max_days }}d)</span>
                </span>
                <span class="formula-math" v-else>
                  Fixed Grant = {{ selectedSimRule.days_per_year.toFixed(0) }} Working Days per annual cycle
                </span>
              </div>

              <div class="sim-perks-list">
                <div class="sim-perk-row">
                  <Check :size="14" class="text-emerald-600" />
                  <span><strong>Carry Forward:</strong> Up to {{ selectedSimRule.max_carry_forward_days }} days rollover permitted (expires in {{ selectedSimRule.carry_forward_expiry_months || 24 }} months)</span>
                </div>
                <div class="sim-perk-row">
                  <Check :size="14" class="text-emerald-600" />
                  <span><strong>Compensation Pay:</strong> {{ selectedSimRule.pay_percent }}% of basic gross salary</span>
                </div>
                <div class="sim-perk-row">
                  <Check :size="14" class="text-emerald-600" />
                  <span><strong>Encashment:</strong> {{ selectedSimRule.allow_encashment ? 'Eligible for final separation cash conversion' : 'No separation cash encashment' }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Right: Complete 15-Year Progression Schedule -->
          <div class="clean-card sim-schedule-card">
            <div class="card-header-bar">
              <div>
                <h3 class="card-title">15-Year Service Progression Matrix</h3>
                <p class="card-subtitle">Year-by-year entitlement path under this policy's statutory formulas.</p>
              </div>
            </div>

            <div class="progression-table-wrap">
              <table class="progression-table">
                <thead>
                  <tr>
                    <th>Service Year</th>
                    <th>Annual Days</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  <tr 
                    v-for="row in simProgressionRows" 
                    :key="row.year"
                    :class="{ 'active-progression-row': row.year === simYearsOfService }"
                  >
                    <td>
                      <span class="font-medium">Year {{ row.year }}</span>
                      <span v-if="row.year === 0" class="text-xs text-gray-400"> (Initial Hire)</span>
                    </td>
                    <td>
                      <span class="prog-days-val">{{ row.days.toFixed(1) }} Days</span>
                    </td>
                    <td>
                      <span v-if="row.isCap" class="prog-tag prog-tag--cap">Cap Reached</span>
                      <span v-else-if="row.year === 0" class="prog-tag prog-tag--base">Statutory Base</span>
                      <span v-else class="prog-tag prog-tag--acc">+{{ row.days - simProgressionRows[0].days }}d Accrued</span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Fallback if not found -->
    <div v-else class="clean-card empty-fallback">
      <AlertCircle :size="36" class="empty-icon" />
      <h2 class="empty-title">Policy Not Found</h2>
      <p class="empty-desc">The requested leave policy could not be found or has been removed.</p>
      <AppButton variant="primary" size="sm" @click="router.push('/hr/leave-policies')">
        Go to Leave Policies
      </AppButton>
    </div>

    <!-- ─── RULE INSPECTION MODAL (AGENTS.md Rule 11 Architecture) ─── -->
    <Teleport to="body">
      <div v-if="selectedInspectRule" class="modal-backdrop" @click="closeInspectModal">
        <div class="rule-modal-card" @click.stop>
          <div class="modal-header">
            <div>
              <h3 class="modal-title">
                {{ selectedInspectRule.leave_type_name }} Entitlement Specification
              </h3>
              <span class="modal-subtitle">{{ selectedInspectRule.leave_type_code }} • Policy Rule #{{ selectedInspectRule.id }}</span>
            </div>
            <button class="modal-close-btn" @click="closeInspectModal" title="Close">
              <X :size="16" />
            </button>
          </div>

          <div class="modal-body">
            <div class="inspect-details-grid">
              <div class="inspect-item">
                <span class="inspect-label">Accrual Method</span>
                <span class="inspect-value capitalize">{{ selectedInspectRule.accrual_method.replace(/_/g, ' ') }}</span>
              </div>

              <div class="inspect-item">
                <span class="inspect-label">Base Entitlement</span>
                <span class="inspect-value">{{ selectedInspectRule.days_per_year.toFixed(1) }} Days / Year</span>
              </div>

              <div class="inspect-item">
                <span class="inspect-label">Service Year Increment</span>
                <span class="inspect-value">
                  {{ selectedInspectRule.extra_days_per_service_year > 0 ? `+${selectedInspectRule.extra_days_per_service_year.toFixed(1)} Days / Year` : 'None' }}
                </span>
              </div>

              <div class="inspect-item">
                <span class="inspect-label">Entitlement Ceiling (Max Cap)</span>
                <span class="inspect-value">
                  {{ selectedInspectRule.max_days ? `${selectedInspectRule.max_days.toFixed(1)} Days` : 'Unlimited' }}
                </span>
              </div>

              <div class="inspect-item">
                <span class="inspect-label">Compensation Pay Rate</span>
                <span class="inspect-value">{{ selectedInspectRule.pay_percent }}% of Basic Salary</span>
              </div>

              <div class="inspect-item">
                <span class="inspect-label">Min Service Required</span>
                <span class="inspect-value">{{ selectedInspectRule.min_service_months }} Months</span>
              </div>

              <div class="inspect-item">
                <span class="inspect-label">Carry Forward Ceiling</span>
                <span class="inspect-value">{{ selectedInspectRule.max_carry_forward_days.toFixed(1) }} Days</span>
              </div>

              <div class="inspect-item">
                <span class="inspect-label">Carry Forward Expiry</span>
                <span class="inspect-value">
                  {{ selectedInspectRule.carry_forward_expiry_months > 0 ? `${selectedInspectRule.carry_forward_expiry_months} Months (2 FYs)` : 'Expire at year end' }}
                </span>
              </div>

              <div class="inspect-item">
                <span class="inspect-label">Advance Notice Required</span>
                <span class="inspect-value">{{ selectedInspectRule.notice_days }} Calendar Days</span>
              </div>

              <div class="inspect-item">
                <span class="inspect-label">Fractional Rounding</span>
                <span class="inspect-value capitalize">{{ selectedInspectRule.rounding.replace(/_/g, ' ') }}</span>
              </div>

              <div class="inspect-item">
                <span class="inspect-label">Gender Restriction</span>
                <span class="inspect-value capitalize">{{ selectedInspectRule.gender ? `${selectedInspectRule.gender} only` : 'All Genders' }}</span>
              </div>

              <div class="inspect-item">
                <span class="inspect-label">Max Request Splits / Year</span>
                <span class="inspect-value">{{ selectedInspectRule.max_splits_per_year ? `${selectedInspectRule.max_splits_per_year} Requests` : 'Unlimited' }}</span>
              </div>
            </div>

            <!-- Governance Permissions Checklist -->
            <div class="inspect-permissions-box">
              <h4 class="permissions-title">Policy Governance &amp; Statutory Permissions</h4>
              <div class="permissions-grid">
                <div class="perm-row">
                  <span class="perm-indicator" :class="selectedInspectRule.allow_encashment ? 'perm-yes' : 'perm-no'">
                    {{ selectedInspectRule.allow_encashment ? '✓' : '✕' }}
                  </span>
                  <span class="perm-text">Encashment Convertible to Cash Payout</span>
                </div>
                <div class="perm-row">
                  <span class="perm-indicator" :class="selectedInspectRule.allow_half_day ? 'perm-yes' : 'perm-no'">
                    {{ selectedInspectRule.allow_half_day ? '✓' : '✕' }}
                  </span>
                  <span class="perm-text">Half-Day (0.5d) Bookings Allowed</span>
                </div>
                <div class="perm-row">
                  <span class="perm-indicator" :class="selectedInspectRule.requires_attachment ? 'perm-yes' : 'perm-no'">
                    {{ selectedInspectRule.requires_attachment ? '✓' : '✕' }}
                  </span>
                  <span class="perm-text">Mandatory Supporting Attachment / Certificate</span>
                </div>
                <div class="perm-row">
                  <span class="perm-indicator" :class="selectedInspectRule.allow_negative_balance ? 'perm-yes' : 'perm-no'">
                    {{ selectedInspectRule.allow_negative_balance ? '✓' : '✕' }}
                  </span>
                  <span class="perm-text">Advance Borrowing (Negative Balance) Allowed</span>
                </div>
              </div>
            </div>
          </div>

          <div class="modal-footer">
            <AppButton variant="primary" size="sm" @click="closeInspectModal">
              Dismiss
            </AppButton>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.leave-policy-detail-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: #f8fafc;
  min-height: 100vh;
}

/* Top Bar */
.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
}

.top-actions-cluster {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* Status Pill */
.status-pill {
  font-size: 11.5px;
  font-weight: 500;
  padding: 3px 12px;
  border-radius: 9999px;
  white-space: nowrap;
}
.state-active {
  background-color: #ecfdf5;
  color: #059669;
}
.state-inactive {
  background-color: #f1f5f9;
  color: #64748b;
}

/* Toast */
.toast-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #ecfdf5;
  color: #065f46;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  padding: 10px 14px;
  font-size: 13px;
  font-weight: 500;
  width: fit-content;
}

.toast-fade-enter-active,
.toast-fade-leave-active {
  transition: all 0.25s ease;
}
.toast-fade-enter-from,
.toast-fade-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}

/* Button Standard (Rule 6: 8px to 10px rounded rectangle, NEVER pills) */
.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  height: 36px;
  padding: 0 16px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-primary-action:hover {
  background-color: #09427d;
}

.btn-secondary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #ffffff;
  color: #404040;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  height: 36px;
  padding: 0 14px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-secondary-action:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

/* Policy Content */
.policy-detail-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.clean-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 20px 24px;
}

/* Hero Policy Card */
.hero-policy-card {
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}

.card-hero-bar {
  border-bottom: 1px solid #f1f5f9;
  padding-bottom: 18px;
  margin-bottom: 18px;
}

.policy-identity-wrap {
  display: flex;
  align-items: flex-start;
  gap: 16px;
}

.policy-icon-box {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background-color: #eff6ff;
  color: #0B529C;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.policy-hero-text {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.title-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.policy-headline {
  font-size: 20px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.policy-code-badge {
  font-size: 11.5px;
  font-weight: 600;
  color: #0B529C;
  background-color: #e0f2fe;
  padding: 2px 8px;
  border-radius: 6px;
  font-family: monospace;
}

.policy-description {
  font-size: 13px;
  color: #737373;
  margin: 2px 0 0;
  line-height: 1.45;
}

.hero-compliance-tag {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: 11.5px;
  color: #059669;
  background-color: #ecfdf5;
  padding: 2px 8px;
  border-radius: 6px;
  width: fit-content;
  margin-top: 4px;
}

/* Meta Stats Grid */
.meta-stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
}
@media (max-width: 900px) {
  .meta-stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

.meta-stat-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.meta-stat-label {
  font-size: 12px;
  color: #737373;
  font-weight: 500;
}
.meta-stat-value {
  font-size: 14px;
  color: #404040;
  font-weight: 600;
}
.meta-stat-subtext {
  font-size: 11.5px;
  color: #94a3b8;
}

/* Sub-Navigation Underline Tabs Wrapper */
.detail-tabs-wrap {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 0 16px;
}

.tab-pane-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* TAB 1: Rules Summary Strip */
.rules-summary-strip {
  display: flex;
  align-items: center;
  justify-content: space-around;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 20px;
}
.summary-stat-cell {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}
.stat-num {
  font-size: 18px;
  font-weight: 700;
  color: #404040;
}
.stat-lbl {
  font-size: 11.5px;
  color: #737373;
}
.strip-divider {
  width: 1px;
  height: 28px;
  background-color: #f1f5f9;
}

/* Table Card */
.table-card-wrap {
  padding: 0;
  overflow: hidden;
}

.card-header-bar {
  padding: 18px 20px 14px;
  border-bottom: 1px solid #f1f5f9;
}
.card-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.card-subtitle {
  font-size: 12.5px;
  color: #737373;
  margin: 2px 0 0;
}

.sub-table-wrap {
  width: 100%;
  overflow-x: auto;
}

.child-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
}

.child-table th {
  height: 36px;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
}

.child-table td {
  height: 48px;
  padding: 8px 16px;
  font-size: 13px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.clickable-row {
  cursor: pointer;
  transition: background-color 0.12s ease;
}
.clickable-row:hover {
  background-color: #f8fafc;
}

.th-no, .td-no {
  width: 40px;
  text-align: center;
  color: #94a3b8;
  font-size: 12px;
  font-weight: 600;
}

.rule-type-cell {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.table-name-primary {
  font-weight: 600;
  color: #404040;
}
.table-code-subtext {
  font-size: 11px;
  color: #737373;
  font-family: monospace;
}

.table-text-primary {
  color: #404040;
}
.table-text-tertiary {
  color: #737373;
}

/* Pay Rate Badges */
.pay-rate-badge {
  display: inline-flex;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 500;
  white-space: nowrap;
}
.pay-full {
  background-color: #ecfdf5;
  color: #059669;
}
.pay-half {
  background-color: #fef3c7;
  color: #b45309;
}
.pay-unpaid {
  background-color: #f1f5f9;
  color: #64748b;
}

.btn-icon-sub {
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  color: #737373;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-icon-sub:hover {
  background-color: #f1f5f9;
  color: #0B529C;
}

/* TAB 2: Scope Blueprint Cards */
.scope-cards-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}
@media (max-width: 1024px) {
  .scope-cards-grid {
    grid-template-columns: 1fr;
  }
}

.blueprint-card {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.bp-card-header {
  display: flex;
  align-items: center;
  gap: 8px;
}
.bp-icon {
  color: #0B529C;
}
.bp-title {
  font-size: 14.5px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.bp-desc {
  font-size: 12px;
  color: #737373;
  margin: 0;
  line-height: 1.4;
}
.bp-meta-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding-top: 10px;
  border-top: 1px solid #f1f5f9;
}
.bp-meta-row {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.bp-lbl {
  font-size: 11.5px;
  color: #737373;
  font-weight: 500;
}
.bp-val {
  font-size: 13px;
  color: #404040;
  font-weight: 500;
}

/* TAB 3: Simulator Layout */
.simulator-layout-grid {
  display: grid;
  grid-template-columns: 1.2fr 1fr;
  gap: 16px;
}
@media (max-width: 960px) {
  .simulator-layout-grid {
    grid-template-columns: 1fr;
  }
}

.sim-controls-card {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.sim-control-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.sim-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}
.sim-select {
  height: 38px;
  padding: 0 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  background-color: #ffffff;
  outline: none;
  cursor: pointer;
}
.sim-select:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.slider-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.slider-val-badge {
  font-size: 12.5px;
  font-weight: 600;
  color: #0B529C;
  background-color: #e0f2fe;
  padding: 2px 10px;
  border-radius: 6px;
}

.sim-range-slider {
  width: 100%;
  accent-color: #0B529C;
  cursor: pointer;
  margin-top: 6px;
}
.slider-ticks-row {
  display: flex;
  justify-content: space-between;
  font-size: 11px;
  color: #94a3b8;
}

/* Simulation Result Box */
.sim-result-hero {
  background: linear-gradient(135deg, #f0f9ff 0%, #ffffff 100%);
  border: 1px solid #bae6fd;
  border-radius: 10px;
  padding: 16px 18px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.sim-result-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}
.sim-res-sub {
  font-size: 12px;
  color: #0369a1;
  font-weight: 500;
}
.sim-res-number {
  font-size: 26px;
  font-weight: 700;
  color: #0B529C;
  line-height: 1.1;
  display: flex;
  align-items: baseline;
  gap: 6px;
  margin-top: 2px;
}
.sim-res-unit {
  font-size: 13px;
  font-weight: 500;
  color: #0369a1;
}

.cap-pill {
  font-size: 11px;
  font-weight: 600;
  padding: 3px 8px;
  border-radius: 6px;
  white-space: nowrap;
}
.cap-pill--max {
  background-color: #fef3c7;
  color: #b45309;
}
.cap-pill--active {
  background-color: #ecfdf5;
  color: #059669;
}

.sim-formula-box {
  background-color: #ffffff;
  border: 1px solid #e0f2fe;
  border-radius: 6px;
  padding: 8px 12px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.formula-label {
  font-size: 11px;
  color: #737373;
  font-weight: 500;
}
.formula-math {
  font-size: 12.5px;
  color: #404040;
  font-weight: 500;
}

.sim-perks-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 12px;
  color: #404040;
}
.sim-perk-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

/* Progression Table */
.sim-schedule-card {
  padding: 0;
  overflow: hidden;
}
.progression-table-wrap {
  max-height: 480px;
  overflow-y: auto;
}
.progression-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
}
.progression-table th {
  height: 34px;
  padding: 8px 16px;
  font-size: 11.5px;
  font-weight: 500;
  color: #737373;
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
  position: sticky;
  top: 0;
  z-index: 2;
}
.progression-table td {
  height: 38px;
  padding: 6px 16px;
  font-size: 12.5px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
}
.active-progression-row {
  background-color: #e0f2fe !important;
}
.prog-days-val {
  font-weight: 600;
  color: #0B529C;
}
.prog-tag {
  font-size: 11px;
  font-weight: 500;
  padding: 2px 6px;
  border-radius: 4px;
}
.prog-tag--cap {
  background-color: #fef3c7;
  color: #92400e;
}
.prog-tag--base {
  background-color: #f1f5f9;
  color: #475569;
}
.prog-tag--acc {
  background-color: #ecfdf5;
  color: #065f46;
}

/* Fallback */
.empty-fallback {
  text-align: center;
  padding: 60px 24px;
}
.empty-icon {
  color: #94a3b8;
  margin-bottom: 12px;
}
.empty-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 6px;
}
.empty-desc {
  font-size: 13px;
  color: #737373;
  margin: 0 0 16px;
}

/* ═════════════════════════════════════════════════════════════════════ */
/* RULE INSPECTION MODAL SYSTEM                                          */
/* ═════════════════════════════════════════════════════════════════════ */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(2px);
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
}

.rule-modal-card {
  background-color: #ffffff;
  border-radius: 14px;
  width: 100%;
  max-width: 680px;
  max-height: 88vh;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  animation: modalFadeIn 0.15s ease-out;
}

@keyframes modalFadeIn {
  from { opacity: 0; transform: scale(0.97); }
  to { opacity: 1; transform: scale(1); }
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 24px 14px;
  border-bottom: 1px solid #f1f5f9;
}

.modal-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.modal-subtitle {
  font-size: 12px;
  color: #737373;
  font-family: monospace;
}

.modal-close-btn {
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  padding: 6px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}
.modal-close-btn:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.modal-body {
  padding: 18px 24px 20px;
  overflow-y: auto;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.inspect-details-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 14px 20px;
}

.inspect-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.inspect-label {
  font-size: 11.5px;
  color: #737373;
  font-weight: 500;
}
.inspect-value {
  font-size: 13px;
  color: #404040;
  font-weight: 600;
}

.inspect-permissions-box {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.permissions-title {
  font-size: 12px;
  font-weight: 600;
  color: #404040;
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 0.02em;
}

.permissions-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px 14px;
}
@media (max-width: 600px) {
  .permissions-grid {
    grid-template-columns: 1fr;
  }
}

.perm-row {
  display: flex;
  align-items: center;
  gap: 8px;
}
.perm-indicator {
  width: 18px;
  height: 18px;
  border-radius: 4px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 700;
}
.perm-yes {
  background-color: #dcfce7;
  color: #15803d;
}
.perm-no {
  background-color: #fee2e2;
  color: #b91c1c;
}
.perm-text {
  font-size: 12px;
  color: #404040;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  padding: 14px 24px;
  background-color: #f8fafc;
  border-top: 1px solid #f1f5f9;
}
</style>
