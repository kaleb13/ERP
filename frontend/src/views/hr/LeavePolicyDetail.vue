<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import {
  ShieldCheck, Calendar, Clock, Building2,
  CheckCircle2, AlertCircle, X,
  Check, Scale, Edit3, Calculator, MoreVertical,
  Eye, Copy
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import { useToast } from '../../composables/useToast';
import AppButton from '../../components/AppButton.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import UnderlineTabs, { type UnderlineTabItem } from '../../components/UnderlineTabs.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import { 
  getPolicyById, 
  leavePoliciesData, 
  type LeavePolicyRecord, 
  type LeavePolicyRuleRecord 
} from './leavePolicyData';

const route = useRoute();
const router = useRouter();
const { toast } = useToast();

const policyId = Number(route.params.id);
const policy = ref<LeavePolicyRecord | undefined>(getPolicyById(policyId) || leavePoliciesData.value[0]);

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3: Child Page Breadcrumb) ───
const breadcrumbItems = computed(() => [
  { label: 'Leave Policies', to: '/hr/leave-policies' },
  { label: policy.value ? `${policy.value.code} — ${policy.value.name}` : 'Policy Detail' }
]);

// ─── Navigation to Edit ───
const goToEdit = () => {
  if (policy.value) {
    router.push({
      path: '/hr/leave-policies/create',
      query: { editId: policy.value.id }
    });
  }
};

// ─── Table Row Actions Menu ───
const openMenuId = ref<number | null>(null);

const toggleActionMenu = (id: number) => {
  openMenuId.value = openMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  openMenuId.value = null;
};

const copyText = (text: string) => {
  navigator?.clipboard?.writeText(text);
  toast.success('Copied to Clipboard', text);
};

// Close popover when clicking outside
const handleDocumentClick = (e: MouseEvent) => {
  const target = e.target as HTMLElement;
  if (!target.closest('.action-cell-wrapper')) {
    closeActionMenu();
  }
};

onMounted(() => {
  document.addEventListener('click', handleDocumentClick);
});

onUnmounted(() => {
  document.removeEventListener('click', handleDocumentClick);
});

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

// ─── Tab 1: AppDataTable Architecture for Entitlement Rules ───
const ruleSearchQuery = ref('');
const ruleCurrentPage = ref(1);
const rulePerPage = ref(10);

const ruleColumns = ref<ColumnDef[]>([
  { key: 'lead', label: 'No.', hideable: false, visible: true },
  { key: 'leave_type', label: 'Leave Type & Code', hideable: false, visible: true },
  { key: 'accrual_method', label: 'Accrual Method', visible: true },
  { key: 'base_days', label: 'Base Entitlement', visible: true },
  { key: 'increment', label: 'Increment / Yr', visible: true },
  { key: 'max_cap', label: 'Ceiling Cap', visible: true },
  { key: 'pay_rate', label: 'Compensation Pay', visible: true },
  { key: 'carry_forward', label: 'Carry-Forward', visible: true },
  { key: 'notice_days', label: 'Notice Days', visible: false },
  { key: 'gender', label: 'Eligible Gender', visible: false },
  { key: 'actions', label: 'Actions', hideable: false, visible: true }
]);

const isColVisible = (key: string) => {
  const col = ruleColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

const handleToggleColumn = (key: string) => {
  const col = ruleColumns.value.find(c => c.key === key);
  if (col && col.hideable !== false) {
    col.visible = !col.visible;
  }
};

const filteredRules = computed(() => {
  if (!policy.value) return [];
  const q = ruleSearchQuery.value.trim().toLowerCase();
  if (!q) return policy.value.rules;
  return policy.value.rules.filter(r => 
    r.leave_type_name.toLowerCase().includes(q) ||
    r.leave_type_code.toLowerCase().includes(q) ||
    r.accrual_method.toLowerCase().includes(q)
  );
});

const paginatedRules = computed(() => {
  const start = (ruleCurrentPage.value - 1) * rulePerPage.value;
  return filteredRules.value.slice(start, start + rulePerPage.value);
});

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

// FormSelect options for Simulator
const simRuleOptions = computed<SelectOption[]>(() => {
  if (!policy.value) return [];
  return policy.value.rules.map(rule => ({
    value: rule.id,
    label: `${rule.leave_type_name} (${rule.leave_type_code}) — Base: ${rule.days_per_year}d`
  }));
});

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
    <!-- Top Bar Navigation (Strict Transparent Canvas Standard - ZERO Action Buttons) -->
    <div class="top-nav-bar">
      <AppBreadcrumb :items="breadcrumbItems">
        <template #badge>
          <BaseBadge v-if="policy" :color="policy.state === 'active' ? 'success' : 'gray'">
            {{ policy.state === 'active' ? 'Active Policy' : 'Inactive Policy' }}
          </BaseBadge>
        </template>
      </AppBreadcrumb>
    </div>

    <div v-if="policy" class="policy-detail-content">
      <!-- SECTION 1: MASTER POLICY IDENTITY HERO CARD (White Card Container Guarantee) -->
      <div class="white-card hero-policy-card">
        <div class="hero-card-left">
          <div class="policy-icon-box">
            <ShieldCheck :size="26" />
          </div>
          <div class="policy-hero-text">
            <div class="title-row">
              <h1 class="policy-headline">{{ policy.name }}</h1>
              <BaseBadge color="indigo" size="md">{{ policy.code }}</BaseBadge>
            </div>
            <p v-if="policy.description" class="policy-description">{{ policy.description }}</p>
          </div>
        </div>

        <!-- 2 High-Signal Pillars on the Right, matching the 2 lines on the Left -->
        <div class="hero-metadata-pillars">
          <div class="hero-meta-item">
            <Building2 :size="15" class="meta-icon" />
            <span class="meta-label">Owning Entity:</span>
            <span class="meta-value">{{ policy.entity_name }}</span>
          </div>
          <div class="hero-meta-item">
            <Clock :size="15" class="meta-icon" />
            <span class="meta-label">Work Calendar:</span>
            <span class="meta-value">{{ policy.work_calendar_name }} ({{ policy.calendar_weekly_hours }}h/wk)</span>
          </div>
        </div>
      </div>

      <!-- SECTION 2: MASTER WORKSPACE CARD (White Card Container, 4 KPIs, Narrative & Flush Underline Tabs) -->
      <div class="white-card master-workspace-card">
        <!-- Row 1: KPI Metrics Grid (20px gap, 20px padding) -->
        <div class="metrics-kpi-grid">
          <div class="metric-box">
            <span class="metric-label">ENTITLEMENT RULES</span>
            <span class="metric-value">{{ policy.rules.length }} Rules</span>
            <span class="metric-subtext">Configured grant formulas</span>
          </div>
          <div class="metric-box">
            <div class="metric-header-row">
              <span class="metric-label">FULLY PAID (100%)</span>
              <BaseBadge color="success" size="sm">100%</BaseBadge>
            </div>
            <span class="metric-value">{{ policy.rules.filter(r => r.pay_percent === 100).length }} Types</span>
            <span class="metric-subtext">Basic salary protection</span>
          </div>
          <div class="metric-box">
            <span class="metric-label">STATUTORY CAP</span>
            <span class="metric-value">30.0 Days</span>
            <span class="metric-subtext">Annual legal maximum</span>
          </div>
          <div class="metric-box">
            <span class="metric-label">MAX ROLLOVER</span>
            <span class="metric-value">10.0 Days</span>
            <span class="metric-subtext">2-year statutory rollover</span>
          </div>
        </div>

        <!-- Row 2: Explanatory Narrative with Inline Action Link (The ONLY edit trigger) -->
        <div class="workspace-narrative-row">
          <p class="workspace-narrative-text">
            All statutory entitlement rules, service year progressions, and carry-forward formulas for this organizational policy are centralized below. While the Entitlement Rules tab presents the active grant catalog, you can inspect granular formulas or test progressions in the Accrual Simulator. If any rules need to be updated, please click on the 
            <a href="javascript:void(0)" class="inline-edit-link" @click="goToEdit">Edit Policy</a>
            to make the necessary changes.
          </p>
        </div>

        <!-- Row 3: Secondary Underline Tabs (Flush directly at bottom of card, ZERO extra box, ZERO gap) -->
        <div class="workspace-tabs-container">
          <UnderlineTabs
            :tabs="tabs"
            v-model="activeTab"
            size="md"
          />
        </div>
      </div>

      <!-- SECTION 3: TAB CONTENT (Rendered below the Master Workspace Card with a clean 20px gap) -->
      <!-- TAB 1: ENTITLEMENT RULES & MATRICES VIA AUTHORITATIVE <AppDataTable /> -->
      <div v-if="activeTab === 'rules'" class="tab-pane-content">
        <AppDataTable
          title="Configured Leave Entitlements"
          subtitle="Active formulas, statutory increments, carry-forward caps, and encashment rights configured for this policy."
          v-model:searchQuery="ruleSearchQuery"
          searchPlaceholder="Search rule by leave type, code, or accrual method..."
          :showSearch="true"
          :showFilter="false"
          :showSort="false"
          :showColumns="true"
          :columns="ruleColumns"
          :totalEntries="filteredRules.length"
          v-model:currentPage="ruleCurrentPage"
          v-model:perPage="rulePerPage"
          :perPageOptions="[5, 10, 20]"
          :showPagination="filteredRules.length > 5"
          @toggleColumn="handleToggleColumn"
        >
          <template #default>
            <div class="sub-table-wrap">
              <table class="erp-table child-table">
                <thead>
                  <tr>
                    <th v-if="isColVisible('lead')" class="th-lead">No.</th>
                    <th v-if="isColVisible('leave_type')">Leave Type</th>
                    <th v-if="isColVisible('accrual_method')">Accrual Method</th>
                    <th v-if="isColVisible('base_days')">Base Entitlement</th>
                    <th v-if="isColVisible('increment')">Increment / Yr</th>
                    <th v-if="isColVisible('max_cap')">Ceiling Cap</th>
                    <th v-if="isColVisible('pay_rate')">Compensation Pay</th>
                    <th v-if="isColVisible('carry_forward')">Carry-Forward</th>
                    <th v-if="isColVisible('notice_days')">Notice Days</th>
                    <th v-if="isColVisible('gender')">Eligible Gender</th>
                    <th v-if="isColVisible('actions')" class="th-actions text-center">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr 
                    v-for="(rule, idx) in paginatedRules" 
                    :key="rule.id" 
                    class="erp-row clickable-row"
                    @click="openInspectModal(rule)"
                  >
                    <!-- Row number in lead column -->
                    <td v-if="isColVisible('lead')" class="td-lead">
                      {{ (ruleCurrentPage - 1) * rulePerPage + idx + 1 }}
                    </td>

                    <!-- Leave Type (Name on top, Code on bottom) -->
                    <td v-if="isColVisible('leave_type')">
                      <div class="rule-type-cell">
                        <span class="table-name-primary">{{ rule.leave_type_name }}</span>
                        <span class="table-code-subtext">{{ rule.leave_type_code }}</span>
                      </div>
                    </td>

                    <!-- Accrual Method -->
                    <td v-if="isColVisible('accrual_method')">
                      <span class="table-text-tertiary">
                        {{ rule.accrual_method === 'per_service_year' ? 'Per Service Year' :
                           rule.accrual_method === 'annual_grant' ? 'Annual Grant' :
                           rule.accrual_method === 'monthly_accrual' ? 'Monthly Accrual' : 'Fixed Allocation' }}
                      </span>
                    </td>

                    <!-- Base Days -->
                    <td v-if="isColVisible('base_days')">
                      <span class="table-text-primary font-medium">{{ rule.days_per_year.toFixed(1) }} d/yr</span>
                    </td>

                    <!-- Extra / Service Year -->
                    <td v-if="isColVisible('increment')">
                      <span class="table-text-tertiary font-mono">
                        {{ rule.extra_days_per_service_year > 0 ? `+${rule.extra_days_per_service_year.toFixed(1)} d/yr` : '—' }}
                      </span>
                    </td>

                    <!-- Ceiling Cap -->
                    <td v-if="isColVisible('max_cap')">
                      <span class="table-text-tertiary font-medium">
                        {{ rule.max_days ? `${rule.max_days.toFixed(1)} d` : 'Unlimited' }}
                      </span>
                    </td>

                    <!-- Compensation Pay Rate with BaseBadge -->
                    <td v-if="isColVisible('pay_rate')">
                      <BaseBadge 
                        :color="rule.pay_percent === 100 ? 'success' : rule.pay_percent > 0 ? 'warning' : 'gray'"
                        size="sm"
                      >
                        {{ rule.pay_percent === 100 ? '100% Full Pay' : rule.pay_percent > 0 ? `${rule.pay_percent}% Pay` : 'Unpaid' }}
                      </BaseBadge>
                    </td>

                    <!-- Carry Forward -->
                    <td v-if="isColVisible('carry_forward')">
                      <span class="table-text-tertiary">
                        {{ rule.max_carry_forward_days > 0 ? `${rule.max_carry_forward_days.toFixed(1)} d (${rule.carry_forward_expiry_months || 24}m)` : '0 d' }}
                      </span>
                    </td>

                    <!-- Notice Days -->
                    <td v-if="isColVisible('notice_days')">
                      <span class="table-text-tertiary">
                        {{ rule.notice_days > 0 ? `${rule.notice_days} days` : 'Immediate' }}
                      </span>
                    </td>

                    <!-- Gender Restriction -->
                    <td v-if="isColVisible('gender')">
                      <span class="table-text-tertiary capitalize">
                        {{ rule.gender ? `${rule.gender} only` : 'All Staff' }}
                      </span>
                    </td>

                    <!-- Standard 3-Dot Kebab Actions Column (AGENTS.md Rule) -->
                    <td v-if="isColVisible('actions')" class="td-actions text-center" @click.stop>
                      <div class="action-cell-wrapper">
                        <button 
                          type="button" 
                          class="btn-action-dots" 
                          @click="toggleActionMenu(rule.id)"
                          title="Actions"
                          aria-label="Actions"
                        >
                          <MoreVertical :size="15" />
                        </button>

                        <div v-if="openMenuId === rule.id" class="action-dropdown-menu">
                          <button class="action-menu-item" @click="openInspectModal(rule); closeActionMenu()">
                            <Eye :size="14" />
                            <span>Inspect Parameters</span>
                          </button>
                          <button class="action-menu-item" @click="goToEdit(); closeActionMenu()">
                            <Edit3 :size="14" />
                            <span>Edit in Policy Editor</span>
                          </button>
                          <button class="action-menu-item" @click="copyText(rule.leave_type_code); closeActionMenu()">
                            <Copy :size="14" />
                            <span>Copy Type Code</span>
                          </button>
                        </div>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </template>
        </AppDataTable>
      </div>

      <!-- TAB 2: POLICY SCOPE & BLUEPRINT ARCHITECTURE -->
      <div v-else-if="activeTab === 'scope'" class="tab-pane-content">
        <div class="scope-cards-grid">
          <!-- Card 1: Organizational Tenancy & Scope -->
          <div class="white-card blueprint-card">
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
                <span class="bp-val text-emerald-700 font-medium">Applies automatically to all child units and staff</span>
              </div>
            </div>
          </div>

          <!-- Card 2: Work Calendar & Day-Counting Engine -->
          <div class="white-card blueprint-card">
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
                <span class="bp-val text-emerald-700 font-medium">Excluded (0h counted; leave balance preserved)</span>
              </div>
              <div class="bp-meta-row">
                <span class="bp-lbl">Counting Engine:</span>
                <span class="bp-val font-mono text-xs">WorkCalendar::SkipWeekendsAndHolidays</span>
              </div>
            </div>
          </div>

          <!-- Card 3: Regulatory Compliance & Governance -->
          <div class="white-card blueprint-card">
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
                <span class="bp-val">{{ policy.effective_from }} – {{ policy.effective_to || 'Current (Open)' }}</span>
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

      <!-- TAB 3: STATUTORY ACCRUAL SIMULATOR (QMT <FormSelect /> Dropdown) -->
      <div v-else-if="activeTab === 'simulator'" class="tab-pane-content">
        <div class="simulator-layout-grid">
          <!-- Left: Simulation Controls -->
          <div class="white-card sim-controls-card">
            <div class="card-header-bar-internal">
              <h3 class="card-title flex items-center gap-2">
                <Calculator :size="17" class="text-sky-600" />
                Simulator Parameter Testing
              </h3>
              <p class="card-subtitle">Adjust employee service years to inspect dynamic entitlement calculations.</p>
            </div>

            <!-- Mandatory QMT FormSelect Dropdown (Replaces raw browser select) -->
            <div class="sim-control-group">
              <FormSelect
                label="Select Leave Rule to Simulate"
                v-model="selectedSimRuleId"
                :options="simRuleOptions"
                :searchable="true"
                placeholder="Select Leave Rule"
              />
            </div>

            <!-- Service Years Slider -->
            <div class="sim-control-group">
              <div class="slider-header-row">
                <label class="sim-label">Continuous Service Years:</label>
                <span class="slider-val-badge">{{ simYearsOfService }} {{ simYearsOfService === 1 ? 'Year' : 'Years' }}</span>
              </div>
              <input 
                type="range" 
                min="0" 
                max="15" 
                step="1" 
                v-model.number="simYearsOfService" 
                class="sim-range-slider"
              />
              <div class="slider-ticks-row">
                <span>0 yr (Base)</span>
                <span>5 yrs</span>
                <span>10 yrs</span>
                <span>15+ yrs</span>
              </div>
            </div>

            <!-- Calculated Result Hero Box -->
            <div class="sim-result-hero" v-if="selectedSimRule">
              <div class="sim-result-top">
                <div>
                  <span class="sim-res-sub">Projected Annual Quota</span>
                  <div class="sim-res-number">
                    {{ simCalculatedDays.toFixed(1) }}
                    <span class="sim-res-unit">Working Days</span>
                  </div>
                </div>
                <BaseBadge :color="simIsCapped ? 'warning' : 'success'" size="sm">
                  {{ simIsCapped ? 'Statutory Cap Reached' : 'Active Growth Rate' }}
                </BaseBadge>
              </div>

              <!-- Mathematical formula trace -->
              <div class="sim-formula-box">
                <span class="formula-label">Active Calculation Formula:</span>
                <span class="formula-math font-mono" v-if="selectedSimRule.accrual_method === 'per_service_year'">
                  {{ selectedSimRule.days_per_year }} base + ({{ selectedSimRule.extra_days_per_service_year }}d × {{ simYearsOfService }} yrs) = {{ simCalculatedDays }}d
                  <span v-if="simIsCapped" class="text-amber-700">[Capped at {{ selectedSimRule.max_days }}d max]</span>
                </span>
                <span class="formula-math font-mono" v-else>
                  Fixed statutory allocation = {{ selectedSimRule.days_per_year }} days/year
                </span>
              </div>
            </div>
          </div>

          <!-- Right: 15-Year Progression Schedule Table -->
          <div class="white-card sim-schedule-card">
            <div class="card-header-bar">
              <div>
                <h3 class="card-title">15-Year Statutory Progression Matrix</h3>
                <p class="card-subtitle">Continuous service projection for <strong>{{ selectedSimRule?.leave_type_name }}</strong>.</p>
              </div>
            </div>

            <div class="progression-table-wrap">
              <table class="erp-table progression-table">
                <thead>
                  <tr>
                    <th>Service Years</th>
                    <th>Projected Quota</th>
                    <th>Tenure Status</th>
                    <th>Increment Reason</th>
                  </tr>
                </thead>
                <tbody>
                  <tr 
                    v-for="row in simProgressionRows" 
                    :key="row.year" 
                    :class="{ 'active-progression-row': row.year === simYearsOfService }"
                  >
                    <td class="font-medium">
                      {{ row.year }} {{ row.year === 1 ? 'Year' : 'Years' }}
                      <span v-if="row.year === simYearsOfService" class="text-xs font-semibold text-sky-700 ml-1">◄ Simulated</span>
                    </td>
                    <td>
                      <span class="prog-days-val">{{ row.days.toFixed(1) }} Days</span>
                    </td>
                    <td>
                      <span v-if="row.isCap" class="prog-tag prog-tag--cap">Statutory Ceiling</span>
                      <span v-else-if="row.year === 0" class="prog-tag prog-tag--base">Entry Baseline</span>
                      <span v-else class="prog-tag prog-tag--acc">Tenure Increment</span>
                    </td>
                    <td class="text-xs text-neutral-500">
                      {{ row.year === 0 ? 'Base statutory grant' :
                         row.isCap ? 'Capped by Ethiopian Labour Law' :
                         `+${selectedSimRule?.extra_days_per_service_year || 1}d tenure bonus` }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State Fallback -->
    <div v-else class="white-card empty-fallback">
      <AlertCircle :size="40" class="empty-icon" />
      <h3 class="empty-title">Policy Record Not Found</h3>
      <p class="empty-desc">The leave policy you are trying to view does not exist or has been removed.</p>
      <AppButton variant="primary" size="md" @click="router.push('/hr/leave-policies')">
        Return to Leave Policies
      </AppButton>
    </div>

    <!-- RULE INSPECTION MODAL SYSTEM -->
    <Teleport to="body">
      <div v-if="selectedInspectRule" class="modal-backdrop" @click.self="closeInspectModal">
        <div class="rule-modal-card">
          <div class="modal-header">
            <div>
              <h3 class="modal-title">{{ selectedInspectRule.leave_type_name }}</h3>
              <span class="modal-subtitle">Parameter Specification • {{ selectedInspectRule.leave_type_code }}</span>
            </div>
            <button class="modal-close-btn" @click="closeInspectModal" aria-label="Close modal">
              <X :size="18" />
            </button>
          </div>

          <div class="modal-body">
            <!-- Primary Specifications Grid -->
            <div class="inspect-details-grid">
              <div class="inspect-item">
                <span class="inspect-label">Base Entitlement</span>
                <span class="inspect-value">{{ selectedInspectRule.days_per_year }} Days / Year</span>
              </div>
              <div class="inspect-item">
                <span class="inspect-label">Increment / Service Year</span>
                <span class="inspect-value font-mono">
                  {{ selectedInspectRule.extra_days_per_service_year > 0 ? `+${selectedInspectRule.extra_days_per_service_year} Days` : 'None' }}
                </span>
              </div>
              <div class="inspect-item">
                <span class="inspect-label">Ceiling Maximum</span>
                <span class="inspect-value">
                  {{ selectedInspectRule.max_days ? `${selectedInspectRule.max_days} Days` : 'Unlimited' }}
                </span>
              </div>
              <div class="inspect-item">
                <span class="inspect-label">Compensation Pay</span>
                <span class="inspect-value">
                  {{ selectedInspectRule.pay_percent }}% ({{ selectedInspectRule.pay_percent === 100 ? 'Fully Paid' : 'Partial' }})
                </span>
              </div>
              <div class="inspect-item">
                <span class="inspect-label">Max Carry Forward</span>
                <span class="inspect-value">{{ selectedInspectRule.max_carry_forward_days }} Days</span>
              </div>
              <div class="inspect-item">
                <span class="inspect-label">Carry-Forward Expiry</span>
                <span class="inspect-value">{{ selectedInspectRule.carry_forward_expiry_months || 24 }} Months</span>
              </div>
              <div class="inspect-item">
                <span class="inspect-label">Notice Days Required</span>
                <span class="inspect-value">
                  {{ selectedInspectRule.notice_days > 0 ? `${selectedInspectRule.notice_days} Days` : 'Immediate' }}
                </span>
              </div>
              <div class="inspect-item">
                <span class="inspect-label">Eligible Gender</span>
                <span class="inspect-value capitalize">{{ selectedInspectRule.gender || 'All Employees' }}</span>
              </div>
            </div>

            <!-- Permission & Policy Gates Box -->
            <div class="inspect-permissions-box">
              <h4 class="permissions-title">Operational Permissions &amp; Policy Gates</h4>
              <div class="permissions-grid">
                <div class="perm-row">
                  <span :class="['perm-icon-wrap', selectedInspectRule.allow_half_day ? 'perm-yes' : 'perm-no']">
                    <Check v-if="selectedInspectRule.allow_half_day" :size="12" />
                    <X v-else :size="12" />
                  </span>
                  <span class="perm-text">Allow Half-Day Booking</span>
                </div>
                <div class="perm-row">
                  <span :class="['perm-icon-wrap', selectedInspectRule.allow_encashment ? 'perm-yes' : 'perm-no']">
                    <Check v-if="selectedInspectRule.allow_encashment" :size="12" />
                    <X v-else :size="12" />
                  </span>
                  <span class="perm-text">Eligible for Encashment</span>
                </div>
                <div class="perm-row">
                  <span :class="['perm-icon-wrap', selectedInspectRule.requires_attachment ? 'perm-yes' : 'perm-no']">
                    <Check v-if="selectedInspectRule.requires_attachment" :size="12" />
                    <X v-else :size="12" />
                  </span>
                  <span class="perm-text">Supporting Document Mandatory</span>
                </div>
                <div class="perm-row">
                  <span :class="['perm-icon-wrap', selectedInspectRule.is_compensatory ? 'perm-yes' : 'perm-no']">
                    <Check v-if="selectedInspectRule.is_compensatory" :size="12" />
                    <X v-else :size="12" />
                  </span>
                  <span class="perm-text">Compensatory Off-In-Lieu</span>
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
/* Page Layout */
.leave-policy-detail-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding: 0;
  background-color: var(--color-background-primary, #fafafa);
  min-height: 100vh;
}

/* Top Bar - Strict Transparent Canvas Standard */
.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: transparent;
  border: none;
  box-shadow: none;
  padding: 0;
}

/* Policy Detail Content Stack (Authoritative 20px gap) */
.policy-detail-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* White Card Container Standard (Rule 6: Solid White Card Container Guarantee) */
.white-card {
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 16px;
}

/* Card 1: Master Hero Identity Card */
.hero-policy-card {
  padding: 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
}

@media (max-width: 960px) {
  .hero-policy-card {
    flex-direction: column;
    align-items: flex-start;
  }
}

.hero-card-left {
  display: flex;
  align-items: center;
  gap: 16px;
  flex: 1;
}

.policy-icon-box {
  width: 52px;
  height: 52px;
  border-radius: 14px;
  background-color: #eff6ff;
  color: var(--color-brand-blue-primary, #0B529C);
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
  color: var(--alias-color-text-secondary, #404040);
  margin: 0;
  line-height: 26px;
}

.policy-description {
  font-size: 13.5px;
  color: var(--alias-color-text-tertiary, #737373);
  margin: 0;
  line-height: 20px;
  max-width: 640px;
}

/* Right Side Metadata Pillars inside the Hero Card (Balanced 2 lines) */
.hero-metadata-pillars {
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex-shrink: 0;
}

.hero-meta-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  line-height: 20px;
}

.meta-icon {
  color: var(--color-brand-blue-primary, #0B529C);
  flex-shrink: 0;
}

.meta-label {
  font-size: 12.5px;
  color: var(--alias-color-text-tertiary, #737373);
  font-weight: 400;
}

.meta-value {
  font-size: 13px;
  color: var(--alias-color-text-secondary, #404040);
  font-weight: 500;
}

/* Card 2: Master Workspace Card (Archetype 2 Standard) */
.master-workspace-card {
  padding: 24px 24px 0 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* KPI 4-Card Grid (Figma 4965:57281: 20px gap, 20px padding) */
.metrics-kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
}

@media (max-width: 1024px) {
  .metrics-kpi-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

.metric-box {
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 16px;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.metric-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.metric-label {
  font-size: 12px;
  font-weight: 500;
  color: var(--alias-color-text-tertiary, #737373);
  text-transform: uppercase;
  letter-spacing: 0.02em;
}

.metric-value {
  font-size: 24px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  line-height: 32px;
}

.metric-subtext {
  font-size: 12px;
  color: var(--alias-color-text-tertiary, #737373);
}

/* Workspace Narrative Row with Inline Link (The ONLY edit trigger) */
.workspace-narrative-row {
  padding-top: 0;
}

.workspace-narrative-text {
  font-size: 14px;
  line-height: 20px;
  color: var(--alias-color-text-tertiary, #737373);
  margin: 0;
}

.inline-edit-link {
  color: var(--color-brand-blue-primary, #0B529C);
  font-weight: 600;
  text-decoration: underline;
  cursor: pointer;
}

/* Flush Underline Tabs (Zero extra box, Zero gap between tabs) */
.workspace-tabs-container {
  margin-top: 0;
}

.workspace-tabs-container :deep(.qmt-underline-tabs) {
  gap: 0px !important;
}

/* Tab Pane Stacks */
.tab-pane-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Table Sub-Wrap inside AppDataTable */
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
  height: 40px;
  padding: 0 16px;
  font-size: 12px;
  font-weight: 500;
  color: var(--alias-color-text-tertiary, #737373);
  background-color: var(--color-background-primary, #fafafa);
  border-bottom: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  white-space: nowrap;
  text-align: left;
}

.child-table td {
  height: 48px;
  padding: 0 16px;
  font-size: 13px;
  border-bottom: 1px solid var(--alias-color-border-subtle, #f1f5f9);
  vertical-align: middle;
}

.clickable-row {
  cursor: pointer;
  transition: background-color 0.12s ease;
}
.clickable-row:hover {
  background-color: var(--color-background-primary, #fafafa);
}

.th-lead, .td-lead {
  width: 68px;
  min-width: 68px;
  max-width: 68px;
  color: var(--alias-color-text-tertiary, #737373);
  font-size: 12px;
  font-weight: 500;
}

.rule-type-cell {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.table-name-primary {
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
}
.table-code-subtext {
  font-size: 11px;
  color: var(--alias-color-text-tertiary, #737373);
  font-family: monospace;
}

.table-text-primary {
  color: var(--alias-color-text-secondary, #404040);
}
.table-text-tertiary {
  color: var(--alias-color-text-tertiary, #737373);
}

.th-actions, .td-actions {
  width: 80px;
  text-align: center;
}

/* 3-Dot Kebab Menu Standard */
.action-cell-wrapper {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.btn-action-dots {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  background-color: #ffffff;
  color: var(--alias-color-text-secondary, #404040);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  outline: none !important;
  box-shadow: none !important;
  transition: all 0.15s ease;
}
.btn-action-dots:hover {
  background-color: var(--color-background-primary, #fafafa);
  border-color: #d4d4d4;
}

.action-dropdown-menu {
  position: absolute;
  top: calc(100% + 4px);
  right: 0;
  z-index: 50;
  min-width: 170px;
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 10px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  padding: 4px;
  display: flex;
  flex-direction: column;
}

.action-menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 12px;
  border: none;
  background: transparent;
  border-radius: 6px;
  font-size: 12.5px;
  color: var(--alias-color-text-secondary, #404040);
  cursor: pointer;
  text-align: left;
  transition: background-color 0.12s ease;
}
.action-menu-item:hover {
  background-color: var(--color-background-primary, #fafafa);
  color: var(--color-brand-blue-primary, #0B529C);
}

/* TAB 2: Scope Blueprint Cards (3-Column Grid, 20px gap, 24px padding) */
.scope-cards-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}

@media (max-width: 1024px) {
  .scope-cards-grid {
    grid-template-columns: 1fr;
  }
}

.blueprint-card {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.bp-card-header {
  display: flex;
  align-items: center;
  gap: 10px;
}

.bp-icon {
  color: var(--color-brand-blue-primary, #0B529C);
}

.bp-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  margin: 0;
}

.bp-desc {
  font-size: 13px;
  color: var(--alias-color-text-tertiary, #737373);
  margin: 0;
  line-height: 19px;
}

.bp-meta-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding-top: 14px;
  border-top: 1px solid var(--alias-color-border-subtle, #f1f5f9);
}

.bp-meta-row {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.bp-lbl {
  font-size: 12px;
  color: var(--alias-color-text-tertiary, #737373);
  font-weight: 500;
}

.bp-val {
  font-size: 13.5px;
  color: var(--alias-color-text-secondary, #404040);
  font-weight: 500;
}

/* TAB 3: Simulator Layout (2-Column Grid, 20px gap) */
.simulator-layout-grid {
  display: grid;
  grid-template-columns: 1fr 1.25fr;
  gap: 20px;
}

@media (max-width: 960px) {
  .simulator-layout-grid {
    grid-template-columns: 1fr;
  }
}

.sim-controls-card {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.sim-control-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.sim-label {
  font-size: 13px;
  font-weight: 500;
  color: var(--alias-color-text-secondary, #404040);
}

.slider-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.slider-val-badge {
  font-size: 13px;
  font-weight: 600;
  color: var(--color-brand-blue-primary, #0B529C);
  background-color: #e0f2fe;
  padding: 2px 10px;
  border-radius: 6px;
}

.sim-range-slider {
  width: 100%;
  accent-color: var(--color-brand-blue-primary, #0B529C);
  cursor: pointer;
  margin-top: 6px;
}

.slider-ticks-row {
  display: flex;
  justify-content: space-between;
  font-size: 11px;
  color: var(--alias-color-text-tertiary, #737373);
}

/* Simulation Result Hero Box */
.sim-result-hero {
  background: linear-gradient(135deg, #f0f9ff 0%, #ffffff 100%);
  border: 1px solid #bae6fd;
  border-radius: 12px;
  padding: 20px;
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
  font-size: 28px;
  font-weight: 700;
  color: var(--color-brand-blue-primary, #0B529C);
  line-height: 1.1;
  display: flex;
  align-items: baseline;
  gap: 6px;
  margin-top: 2px;
}

.sim-res-unit {
  font-size: 14px;
  font-weight: 500;
  color: #0369a1;
}

.sim-formula-box {
  background-color: #ffffff;
  border: 1px solid #e0f2fe;
  border-radius: 8px;
  padding: 10px 14px;
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.formula-label {
  font-size: 11px;
  color: var(--alias-color-text-tertiary, #737373);
  font-weight: 500;
}

.formula-math {
  font-size: 13px;
  color: var(--alias-color-text-secondary, #404040);
  font-weight: 500;
}

/* Progression Schedule Card */
.sim-schedule-card {
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.card-header-bar {
  padding: 20px 24px;
  border-bottom: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-header-bar-internal {
  padding-bottom: 16px;
  border-bottom: 1px solid var(--alias-color-border-subtle, #f1f5f9);
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.card-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  margin: 0;
}

.card-subtitle {
  font-size: 13px;
  color: var(--alias-color-text-tertiary, #737373);
  margin: 3px 0 0;
}

.progression-table-wrap {
  max-height: 520px;
  overflow-y: auto;
}

.progression-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
}

.progression-table th {
  height: 38px;
  padding: 0 16px;
  font-size: 12px;
  font-weight: 500;
  color: var(--alias-color-text-tertiary, #737373);
  background-color: var(--color-background-primary, #fafafa);
  border-bottom: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  position: sticky;
  top: 0;
  z-index: 2;
  text-align: left;
}

.progression-table td {
  height: 40px;
  padding: 0 16px;
  font-size: 13px;
  color: var(--alias-color-text-secondary, #404040);
  border-bottom: 1px solid var(--alias-color-border-subtle, #f1f5f9);
}

.active-progression-row {
  background-color: #e0f2fe !important;
}

.prog-days-val {
  font-weight: 600;
  color: var(--color-brand-blue-primary, #0B529C);
}

/* Inspection Modal */
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
  border-radius: 16px;
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
  padding: 20px 24px;
  border-bottom: 1px solid var(--alias-color-border-subtle, #f1f5f9);
}

.modal-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  margin: 0;
}

.modal-subtitle {
  font-size: 12px;
  color: var(--alias-color-text-tertiary, #737373);
  font-family: monospace;
}

.modal-close-btn {
  border: none;
  background: transparent;
  color: var(--alias-color-text-tertiary, #737373);
  cursor: pointer;
  padding: 6px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}
.modal-close-btn:hover {
  background-color: var(--color-background-primary, #fafafa);
  color: var(--alias-color-text-secondary, #404040);
}

.modal-body {
  padding: 20px 24px;
  overflow-y: auto;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.inspect-details-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px 20px;
}

.inspect-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.inspect-label {
  font-size: 12px;
  color: var(--alias-color-text-tertiary, #737373);
  font-weight: 500;
}

.inspect-value {
  font-size: 13.5px;
  color: var(--alias-color-text-secondary, #404040);
  font-weight: 600;
}

.inspect-permissions-box {
  background-color: var(--color-background-primary, #fafafa);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 12px;
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.permissions-title {
  font-size: 12px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 0.02em;
}

.permissions-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px 16px;
}

.perm-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.perm-icon-wrap {
  width: 18px;
  height: 18px;
  border-radius: 4px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.perm-yes {
  background-color: #e6f7ef;
  color: var(--color-success, #009966);
}

.perm-no {
  background-color: #f5f5f5;
  color: var(--alias-color-text-tertiary, #737373);
}

.perm-text {
  font-size: 12.5px;
  color: var(--alias-color-text-secondary, #404040);
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  padding: 16px 24px;
  background-color: var(--color-background-primary, #fafafa);
  border-top: 1px solid var(--alias-color-border-subtle, #e5e5e5);
}
</style>
