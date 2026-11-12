<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import {
  Eye, CheckCircle2, DollarSign, Calendar,
  Printer, Check, X, MoreVertical,
  Zap, User
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import MetricCard from '../../components/MetricCard.vue';
import UnderlineTabs, { type UnderlineTabItem } from '../../components/UnderlineTabs.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import {
  finalSettlementsData,
  separationsData,
  clearanceItemsData,
  SETTLEMENT_STATE_MAP,
  SETTLEMENT_LINE_TYPE_MAP,
  updateSettlementStatus,
  type SettlementState,
  type FinalSettlementRecord,
  type FinalSettlementLineRecord,
  type SettlementLineType
} from './separationData';

const router = useRouter();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3) ───
// Exact Sidebar Page Name Only: [Monitor] > Final Settlements
const breadcrumbItems = [
  { label: 'Final Settlements' }
];

// ─── Role-Adaptive View Switcher ───
const isAdminView = ref(true);

// ─── Active Tab Filter (UnderlineTabs Standard AGENTS.md Rule 1) ───
type SettlementTabKey = 'all' | 'draft' | 'calculated' | 'approved' | 'paid';
const activeTab = ref<SettlementTabKey>('all');

const searchQuery = ref('');
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Metric Cards Computed (AGENTS.md Rule 2 & Rule 21) ───
const metrics = computed(() => {
  const total = finalSettlementsData.value.length;
  const grossSum = finalSettlementsData.value
    .reduce((sum, s) => sum + s.gross_amount, 0)
    .toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const dedSum = finalSettlementsData.value
    .reduce((sum, s) => sum + s.deduction_amount, 0)
    .toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const pendingPayment = finalSettlementsData.value
    .filter(s => s.settlement_state === 'approved').length;

  return {
    total,
    grossSum: `${grossSum} ETB`,
    dedSum: `${dedSum} ETB`,
    pendingPayment
  };
});

// ─── Tabs Configuration ───
const underlineTabs = computed<UnderlineTabItem<SettlementTabKey>[]>(() => [
  { id: 'all', label: 'All Settlements', count: finalSettlementsData.value.length },
  { id: 'draft', label: 'Ready for Calculation', count: finalSettlementsData.value.filter(s => s.settlement_state === 'draft').length, badgeVariant: 'warning' },
  { id: 'calculated', label: 'Calculated (Pending Review)', count: finalSettlementsData.value.filter(s => s.settlement_state === 'calculated').length, badgeVariant: 'primary' },
  { id: 'approved', label: 'Approved (Payment Ready)', count: finalSettlementsData.value.filter(s => s.settlement_state === 'approved').length, badgeVariant: 'success' },
  { id: 'paid', label: 'Paid & Disbursed', count: finalSettlementsData.value.filter(s => s.settlement_state === 'paid').length }
]);

const readyCount = computed(() => finalSettlementsData.value.filter(s => s.settlement_state === 'draft').length);

// ─── Filtered Dataset ───
const filteredSettlements = computed(() => {
  return finalSettlementsData.value.filter(item => {
    // Tab filter
    if (activeTab.value !== 'all' && item.settlement_state !== activeTab.value) return false;

    // Search query
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase();
      const matchEmp = item.employee_name.toLowerCase().includes(q);
      const matchCode = item.code.toLowerCase().includes(q);
      const matchSepCode = item.separation_code.toLowerCase().includes(q);
      const matchDept = item.department.toLowerCase().includes(q);
      if (!matchEmp && !matchCode && !matchSepCode && !matchDept) return false;
    }

    return true;
  });
});

// ─── Table Columns (AGENTS.md Rule 9: Atomic Columns) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'employee', label: 'Employee', visible: true },
  { key: 'separation_code', label: 'Separation Case', visible: true },
  { key: 'service_years', label: 'Service Tenure', visible: true },
  { key: 'gross_amount', label: 'Gross Amount', visible: true },
  { key: 'deduction_amount', label: 'Deductions', visible: true },
  { key: 'net_amount', label: 'Net Payable', visible: true },
  { key: 'settlement_state', label: 'Settlement Status', visible: true },
  { key: 'payroll_run', label: 'Payroll Run Ref', visible: false },
  { key: 'state', label: 'State', visible: false }
]);

const handleToggleColumn = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  if (col) col.visible = !col.visible;
};

// ─── Currency / Amount Formatter ───
const formatMoney = (val?: number | null) => {
  if (val === undefined || val === null) return '0.00 ETB';
  return `${val.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ETB`;
};

// ─── Settlement Sheet Inspection Modal / Bottom Drawer ───
const selectedSettlement = ref<FinalSettlementRecord | null>(null);
const isSheetModalOpen = ref(false);

const selectedSeparation = computed(() => {
  if (!selectedSettlement.value) return null;
  return separationsData.value.find(s => 
    s.id === selectedSettlement.value?.employee_separation_id || 
    s.code === selectedSettlement.value?.separation_code
  );
});

const openSettlementSheet = (item: FinalSettlementRecord) => {
  selectedSettlement.value = item;
  isSheetModalOpen.value = true;
};

const handleApproveFromSheet = () => {
  if (!selectedSettlement.value) return;
  updateSettlementStatus(selectedSettlement.value.id, 'approved');
  showToast(`Settlement ${selectedSettlement.value.code} approved for final payment execution.`);
};

const handleMarkPaidFromSheet = () => {
  if (!selectedSettlement.value) return;
  updateSettlementStatus(selectedSettlement.value.id, 'paid');
  showToast(`Settlement ${selectedSettlement.value.code} disbursed via payroll run.`);
};

// ─── Automated Settlement Computation Engine (Schema Sections 12 & StatutoryRules) ───
const handleComputeSettlement = (item: FinalSettlementRecord) => {
  const sep = separationsData.value.find(s => s.id === item.employee_separation_id);
  const tenureYears = item.service_years || (sep?.id === 13 ? 1.00 : 2.50);

  // Daily wage rate based on employee position / salary scale
  const dailyRate = 750.00;
  const monthlyWage = dailyRate * 26; // ~19,500 ETB

  // Severance Pay (Statutory formula: 1 month salary for 1st year + 1/3 for each subsequent year)
  const severanceAmount = monthlyWage + ((tenureYears - 1) * (monthlyWage / 3));

  // Leave encashment (e.g. 10 unused accrued days from LeaveAllocation)
  const leaveDays = 10;
  const leaveEncashment = leaveDays * dailyRate;

  // Prorated worked days in final cutoff month (e.g. 15 days)
  const workedDays = 15;
  const proratedSalary = workedDays * dailyRate;

  // Cross-check ClearanceItem for any flagged deductions!
  const clearanceDeductions: FinalSettlementLineRecord[] = clearanceItemsData.value
    .filter(c => c.employee_separation_id === item.employee_separation_id && c.clearance_state === 'flagged' && c.flagged_amount)
    .map((c, idx) => ({
      id: 200 + idx,
      uuid: `fsl-ded-${c.id}-${Date.now()}`,
      tenant_id: 1,
      entity_id: 3,
      final_settlement_id: item.id,
      line_type: 'deduction' as SettlementLineType,
      description: `Clearance Deduction: ${c.title} (${c.organization_unit_name})`,
      quantity: null,
      rate: null,
      amount: -Math.abs(c.flagged_amount || 0),
      source_type: 'ClearanceItem' as const,
      source_id: c.id,
      order: 4 + idx,
      state: 'active' as const
    }));

  const taxDeduction = 2800.00;

  const lines: FinalSettlementLineRecord[] = [
    {
      id: 1,
      uuid: `fsl-${item.id}-1`,
      tenant_id: 1,
      entity_id: 3,
      final_settlement_id: item.id,
      line_type: 'prorated_salary',
      description: `Worked days in final cutoff month (${workedDays} days)`,
      quantity: workedDays,
      rate: dailyRate,
      amount: proratedSalary,
      source_type: 'Manual',
      order: 1,
      state: 'active'
    },
    {
      id: 2,
      uuid: `fsl-${item.id}-2`,
      tenant_id: 1,
      entity_id: 3,
      final_settlement_id: item.id,
      line_type: 'severance',
      description: `Statutory Severance Pay (${tenureYears.toFixed(2)} yrs service per Labor Code)`,
      quantity: tenureYears,
      rate: null,
      amount: Math.round(severanceAmount * 100) / 100,
      source_type: 'StatutoryRule',
      order: 2,
      state: 'active'
    },
    {
      id: 3,
      uuid: `fsl-${item.id}-3`,
      tenant_id: 1,
      entity_id: 3,
      final_settlement_id: item.id,
      line_type: 'leave_encashment',
      description: `Unused annual leave encashment (${leaveDays} accrued days)`,
      quantity: leaveDays,
      rate: dailyRate,
      amount: leaveEncashment,
      source_type: 'LeaveAllocation',
      order: 3,
      state: 'active'
    },
    ...clearanceDeductions,
    {
      id: 4 + clearanceDeductions.length,
      uuid: `fsl-${item.id}-tax`,
      tenant_id: 1,
      entity_id: 3,
      final_settlement_id: item.id,
      line_type: 'deduction',
      description: 'Terminal statutory income tax withholding',
      quantity: null,
      rate: null,
      amount: -taxDeduction,
      source_type: 'Manual',
      order: 4 + clearanceDeductions.length,
      state: 'active'
    }
  ];

  const gross = lines.filter(l => l.amount > 0).reduce((sum, l) => sum + l.amount, 0);
  const deductions = Math.abs(lines.filter(l => l.amount < 0).reduce((sum, l) => sum + l.amount, 0));
  const net = gross - deductions;

  item.lines = lines;
  item.service_years = tenureYears;
  item.gross_amount = gross;
  item.deduction_amount = deductions;
  item.net_amount = net;
  item.settlement_state = 'calculated';

  showToast(`Terminal settlement ${item.code} calculated for ${item.employee_name}.`);
  openSettlementSheet(item);
};

const handleComputeNextReady = () => {
  const nextDraft = finalSettlementsData.value.find(s => s.settlement_state === 'draft');
  if (nextDraft) {
    handleComputeSettlement(nextDraft);
  } else {
    showToast('No pending exit cases waiting for calculation.');
  }
};

// ─── Standardized 3-Dots Action Dropdown Menu (AGENTS.md Rule 8) ───
const activeActionMenuId = ref<number | null>(null);

const toggleActionMenu = (id: number) => {
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenus = () => {
  activeActionMenuId.value = null;
};

const handleGlobalKeydown = (e: KeyboardEvent) => {
  if (e.key === 'Escape') {
    isSheetModalOpen.value = false;
    closeActionMenus();
  }
};

onMounted(() => {
  if (typeof window !== 'undefined') {
    window.addEventListener('click', closeActionMenus);
    window.addEventListener('keydown', handleGlobalKeydown);
  }
});

onUnmounted(() => {
  if (typeof window !== 'undefined') {
    window.removeEventListener('click', closeActionMenus);
    window.removeEventListener('keydown', handleGlobalKeydown);
  }
});

// ─── Clickable Metric Cards as Quick Filters ───
const handleMetricClick = (tabKey: SettlementTabKey) => {
  if (activeTab.value === tabKey && tabKey !== 'all') {
    activeTab.value = 'all';
  } else {
    activeTab.value = tabKey;
  }
};
</script>

<template>
  <div class="page-container">
    <!-- Breadcrumb Standard (AGENTS.md Rule 3: Exact Sidebar Page Name Only) -->
    <div class="breadcrumb-header-row">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Admin KPI Metrics Grid (AGENTS.md Rule 2 & Rule 21 Type B) -->
    <div class="metrics-grid">
      <div 
        class="metric-clickable-wrapper" 
        :class="{ 'is-active-filter': activeTab === 'all' }"
        @click="handleMetricClick('all')"
      >
        <MetricCard
          label="Total Settlements"
          :value="metrics.total"
          subtext="Terminal severance & payout computations"
          :showMenu="false"
        />
      </div>
      <div 
        class="metric-clickable-wrapper" 
        :class="{ 'is-active-filter': activeTab === 'calculated' }"
        @click="handleMetricClick('calculated')"
      >
        <MetricCard
          label="Total Gross Amount"
          :value="metrics.grossSum"
          subtext="Gross earnings, severance & leave payout sums"
          :showMenu="false"
        />
      </div>
      <div 
        class="metric-clickable-wrapper" 
        :class="{ 'is-active-filter': activeTab === 'approved' }"
        @click="handleMetricClick('approved')"
      >
        <MetricCard
          label="Pending Payout"
          :value="metrics.pendingPayment"
          subtext="Approved by HR, pending payroll disbursement"
          :showMenu="false"
        />
      </div>
      <div 
        class="metric-clickable-wrapper" 
        :class="{ 'is-active-filter': activeTab === 'paid' }"
        @click="handleMetricClick('paid')"
      >
        <MetricCard
          label="Recovered Deductions"
          :value="metrics.dedSum"
          subtext="Total clearance deductions & loan offsets"
          :showMenu="false"
        />
      </div>
    </div>

    <!-- Admin UnderlineTabs (AGENTS.md Rule 1) -->
    <div class="tabs-wrapper">
      <UnderlineTabs
        v-model="activeTab"
        :tabs="underlineTabs"
      />
    </div>

    <!-- Master Single Table Card Standard (AGENTS.md Rule 10) -->
    <AppDataTable
      title="Final Settlements"
      subtitle="Terminal compensation calculation, severance computations, leave balance encashments, and clearance recovery deductions."
      v-model:searchQuery="searchQuery"
      :columns="tableColumns"
      :totalEntries="filteredSettlements.length"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Primary Action in Toolbar #actions Slot (AGENTS.md Rule 10) -->
      <template #actions>
        <AppButton
          v-if="readyCount > 0"
          variant="primary"
          size="sm"
          @click="handleComputeNextReady"
        >
          <template #icon-left><Zap :size="15" /></template>
          Calculate Next ({{ readyCount }} Ready)
        </AppButton>
      </template>

      <!-- Canonical Table (AGENTS.md Rule 8, 9, 10) -->
      <template #default>
        <table class="erp-table">
          <thead>
            <tr>
              <th class="th-checkbox"><input type="checkbox" /></th>
              <th>Employee</th>
              <th v-if="tableColumns.find(c => c.key === 'separation_code')?.visible">Separation Case</th>
              <th v-if="tableColumns.find(c => c.key === 'service_years')?.visible">Service Tenure</th>
              <th v-if="tableColumns.find(c => c.key === 'gross_amount')?.visible">Gross Amount</th>
              <th v-if="tableColumns.find(c => c.key === 'deduction_amount')?.visible">Deductions</th>
              <th v-if="tableColumns.find(c => c.key === 'net_amount')?.visible">Net Payable</th>
              <th v-if="tableColumns.find(c => c.key === 'payroll_run')?.visible">Payroll Run</th>
              <th v-if="tableColumns.find(c => c.key === 'settlement_state')?.visible">Settlement Status</th>
              <th v-if="tableColumns.find(c => c.key === 'state')?.visible">State</th>
              <th class="th-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="filteredSettlements.length === 0">
              <td colspan="9" class="td-empty">No settlement records found matching criteria.</td>
            </tr>
            <tr 
              v-for="item in filteredSettlements" 
              :key="item.id"
              class="clickable-row"
              @click="openSettlementSheet(item)"
            >
              <td class="td-checkbox" @click.stop><input type="checkbox" /></td>

              <!-- Name in Secondary #404040, Settlement Code in Tertiary #737373 (Rule 4 & 5) -->
              <td class="td-identity">
                <img :src="item.employee_avatar" :alt="item.employee_name" class="table-avatar" />
                <div class="identity-text">
                  <span class="table-name-primary">{{ item.employee_name }}</span>
                  <span class="table-code-subtext">{{ item.code }} • {{ item.department }}</span>
                </div>
              </td>

              <td v-if="tableColumns.find(c => c.key === 'separation_code')?.visible" class="td-tertiary">
                {{ item.separation_code }}
              </td>

              <td v-if="tableColumns.find(c => c.key === 'service_years')?.visible" class="td-tertiary font-numeric">
                <span v-if="item.settlement_state === 'draft'" class="text-tertiary">Pending Calc</span>
                <span v-else>{{ item.service_years.toFixed(2) }} Years</span>
              </td>

              <td v-if="tableColumns.find(c => c.key === 'gross_amount')?.visible" class="td-tertiary font-numeric">
                <span v-if="item.settlement_state === 'draft'" class="text-tertiary">—</span>
                <span v-else>{{ formatMoney(item.gross_amount) }}</span>
              </td>

              <td v-if="tableColumns.find(c => c.key === 'deduction_amount')?.visible" class="td-tertiary font-numeric" :class="{ 'text-danger': item.deduction_amount > 0 }">
                <span v-if="item.settlement_state === 'draft'" class="text-tertiary">—</span>
                <span v-else-if="item.deduction_amount > 0">-{{ formatMoney(item.deduction_amount) }}</span>
                <span v-else>0.00 ETB</span>
              </td>

              <!-- Net Payable in Strong Secondary Color #404040 (Rule 5) -->
              <td v-if="tableColumns.find(c => c.key === 'net_amount')?.visible" class="td-net font-numeric" @click.stop>
                <button 
                  v-if="item.settlement_state === 'draft'"
                  type="button" 
                  class="btn-row-calculate"
                  title="Compute terminal severance, leave encashment, and clearance offsets"
                  @click="handleComputeSettlement(item)"
                >
                  <Zap :size="12" />
                  <span>Calculate Settlement</span>
                </button>
                <span v-else>{{ formatMoney(item.net_amount) }}</span>
              </td>

              <!-- Payroll Run Ref (Optional) -->
              <td v-if="tableColumns.find(c => c.key === 'payroll_run')?.visible" class="td-tertiary">
                {{ item.payroll_run_code || '—' }}
              </td>

              <!-- Status Pills strictly for Lifecycle State (Rule 6 & 9) -->
              <td v-if="tableColumns.find(c => c.key === 'settlement_state')?.visible" class="td-state">
                <span 
                  class="status-pill"
                  :style="{ 
                    backgroundColor: SETTLEMENT_STATE_MAP[item.settlement_state].bg, 
                    color: SETTLEMENT_STATE_MAP[item.settlement_state].color 
                  }"
                >
                  {{ SETTLEMENT_STATE_MAP[item.settlement_state].label }}
                </span>
              </td>

              <!-- State (Rule 9: Active / Inactive reserved for State) -->
              <td v-if="tableColumns.find(c => c.key === 'state')?.visible">
                <span class="status-pill" :class="item.state === 'active' ? 'status-active' : 'status-inactive'">
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </span>
              </td>

              <!-- Standardized 3-Dots Action Dropdown Menu (AGENTS.md Rule 8) -->
              <td class="td-actions" @click.stop>
                <div class="action-dropdown-wrapper">
                  <button 
                    type="button" 
                    class="btn-action-dots"
                    title="Actions"
                    @click="toggleActionMenu(item.id)"
                  >
                    <MoreVertical :size="15" />
                  </button>

                  <div v-if="activeActionMenuId === item.id" class="action-popup-menu">
                    <button 
                      v-if="item.settlement_state === 'draft'"
                      type="button" 
                      class="popup-item item-calc" 
                      @click="activeActionMenuId = null; handleComputeSettlement(item)"
                    >
                      <Zap :size="13" />
                      <span>Calculate Settlement</span>
                    </button>
                    <button type="button" class="popup-item" @click="activeActionMenuId = null; openSettlementSheet(item)">
                      <Eye :size="13" />
                      <span>View Statement Sheet</span>
                    </button>
                    <button 
                      v-if="item.settlement_state === 'calculated'"
                      type="button" 
                      class="popup-item item-approve" 
                      @click="activeActionMenuId = null; updateSettlementStatus(item.id, 'approved'); showToast(`Settlement ${item.code} approved.`);"
                    >
                      <Check :size="13" />
                      <span>Approve Settlement</span>
                    </button>
                    <button 
                      v-if="item.settlement_state === 'approved'"
                      type="button" 
                      class="popup-item item-pay" 
                      @click="activeActionMenuId = null; updateSettlementStatus(item.id, 'paid'); showToast(`Settlement ${item.code} disbursed via payroll.`);"
                    >
                      <DollarSign :size="13" />
                      <span>Disburse & Pay</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </template>
    </AppDataTable>

    <!-- Itemized Settlement Bottom Drawer (Dynamic Sub-Table Standard Rule 11 & 19) -->
    <div v-if="isSheetModalOpen && selectedSettlement" class="drawer-backdrop" @click="isSheetModalOpen = false">
      <div class="bottom-drawer" @click.stop>
        
        <!-- Drag Handle Indicator Pill -->
        <div class="drawer-handle-bar">
          <div class="drawer-handle-pill"></div>
        </div>

        <!-- Drawer Header with Prominent User Profile ("Show the User") -->
        <div class="drawer-header">
          <div class="drawer-user-card">
            <!-- Avatar with ring and fallback -->
            <div class="drawer-avatar-wrap">
              <img 
                v-if="selectedSettlement.employee_avatar || selectedSeparation?.employee_avatar"
                :src="selectedSettlement.employee_avatar || selectedSeparation?.employee_avatar" 
                :alt="selectedSettlement.employee_name" 
                class="drawer-avatar-img" 
              />
              <div v-else class="drawer-avatar-placeholder">
                <User :size="24" />
              </div>
            </div>

            <!-- User Identification & Statement Metadata -->
            <div class="drawer-user-info">
              <div class="drawer-meta-pills">
                <span class="drawer-doc-code">{{ selectedSettlement.code }}</span>
                <span class="drawer-emp-code">{{ selectedSettlement.employee_code }}</span>
                <span class="drawer-sep-case">Case: {{ selectedSettlement.separation_code }}</span>
                <span v-if="selectedSeparation?.separation_type" class="drawer-sep-type">
                  {{ selectedSeparation.separation_type.replace(/_/g, ' ') }}
                </span>
              </div>
              <div class="drawer-title-row">
                <h2 class="drawer-employee-name">{{ selectedSettlement.employee_name }}</h2>
                <span class="drawer-separator">•</span>
                <span class="drawer-statement-title">Terminal Payout Statement</span>
              </div>
              <div class="drawer-employee-meta">
                <span class="meta-item meta-role">{{ selectedSettlement.position || selectedSeparation?.position }}</span>
                <span class="meta-dot">·</span>
                <span class="meta-item meta-dept">{{ selectedSettlement.department || selectedSeparation?.department }}</span>
                <template v-if="selectedSeparation?.last_working_date">
                  <span class="meta-dot">·</span>
                  <span class="meta-item meta-date">Exit Date: {{ selectedSeparation.last_working_date }}</span>
                </template>
              </div>
            </div>
          </div>

          <div class="drawer-header-actions">
            <span 
              class="status-pill status-pill-lg"
              :style="{ 
                backgroundColor: SETTLEMENT_STATE_MAP[selectedSettlement.settlement_state].bg, 
                color: SETTLEMENT_STATE_MAP[selectedSettlement.settlement_state].color 
              }"
            >
              {{ SETTLEMENT_STATE_MAP[selectedSettlement.settlement_state].label }}
            </span>
            <button 
              type="button" 
              class="btn-drawer-close" 
              title="Close drawer (Esc)"
              @click="isSheetModalOpen = false"
            >
              <X :size="18" />
            </button>
          </div>
        </div>

        <!-- Drawer Body -->
        <div class="drawer-body">
          <!-- Summary Metrics Strip -->
          <div class="sheet-metrics-strip">
            <div class="metric-strip-item">
              <span class="strip-label">Service Tenure</span>
              <span class="strip-value font-numeric">{{ selectedSettlement.service_years.toFixed(2) }} Years</span>
            </div>
            <div class="metric-strip-item">
              <span class="strip-label">Gross Amount</span>
              <span class="strip-value font-numeric text-success">+{{ formatMoney(selectedSettlement.gross_amount) }}</span>
            </div>
            <div class="metric-strip-item">
              <span class="strip-label">Total Deductions</span>
              <span class="strip-value font-numeric text-danger">-{{ formatMoney(selectedSettlement.deduction_amount) }}</span>
            </div>
            <div class="metric-strip-item is-highlight">
              <span class="strip-label">Net Terminal Payout</span>
              <span class="strip-value font-numeric text-net">{{ formatMoney(selectedSettlement.net_amount) }}</span>
            </div>
          </div>

          <!-- Critic-Aligned Dynamic Sub-Table (AGENTS.md Rule 11 & 19) -->
          <div class="subtable-accordion-header">
            <span class="subtable-title">Itemized Compensation & Deductions Breakdown (FinalSettlementLine)</span>
          </div>

          <table class="sub-erp-table">
            <thead>
              <tr>
                <th class="sub-th-no">#</th>
                <th>Line Type</th>
                <th>Description</th>
                <th>Quantity</th>
                <th>Rate</th>
                <th class="sub-th-amount">Amount (ETB)</th>
                <th>Source Origin</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(line, idx) in selectedSettlement.lines" :key="line.id">
                <td class="sub-td-no">{{ idx + 1 }}</td>
                <td class="sub-td-type">{{ SETTLEMENT_LINE_TYPE_MAP[line.line_type] }}</td>
                <td class="sub-td-desc">{{ line.description }}</td>
                <td class="sub-td-numeric">{{ line.quantity !== null && line.quantity !== undefined ? line.quantity : '—' }}</td>
                <td class="sub-td-numeric">{{ line.rate !== null && line.rate !== undefined ? line.rate.toFixed(2) : '—' }}</td>
                <td class="sub-td-amount font-numeric" :class="line.amount >= 0 ? 'amount-plus' : 'amount-minus'">
                  {{ line.amount >= 0 ? '+' : '' }}{{ line.amount.toLocaleString('en-US', { minimumFractionDigits: 2 }) }}
                </td>
                <td class="sub-td-source">{{ line.source_type }}</td>
              </tr>
            </tbody>
            <tfoot>
              <tr class="sub-tfoot-row">
                <td colspan="5" class="tfoot-label">Net Payable Terminal Balance</td>
                <td class="tfoot-net font-numeric">{{ formatMoney(selectedSettlement.net_amount) }}</td>
                <td></td>
              </tr>
            </tfoot>
          </table>
        </div>

        <!-- Drawer Footer Actions -->
        <div class="drawer-footer">
          <div class="footer-left">
            <button type="button" class="btn-footer-secondary" @click="isSheetModalOpen = false">
              Close
            </button>
            <button 
              type="button" 
              class="btn-footer-ghost" 
              title="Print official terminal voucher"
              @click="showToast('Printing terminal settlement statement voucher...')"
            >
              <Printer :size="14" />
              <span>Print Statement</span>
            </button>
          </div>
          
          <div class="footer-right">
            <button 
              v-if="selectedSettlement.settlement_state === 'draft'"
              type="button" 
              class="btn-footer-primary is-calc" 
              @click="handleComputeSettlement(selectedSettlement)"
            >
              <Zap :size="14" />
              <span>Calculate Settlement</span>
            </button>

            <button 
              v-if="selectedSettlement.settlement_state === 'calculated'"
              type="button" 
              class="btn-footer-primary" 
              @click="handleApproveFromSheet"
            >
              <Check :size="14" />
              <span>Approve Terminal Statement</span>
            </button>

            <button 
              v-if="selectedSettlement.settlement_state === 'approved'"
              type="button" 
              class="btn-footer-primary is-pay" 
              @click="handleMarkPaidFromSheet"
            >
              <DollarSign :size="14" />
              <span>Execute Payout & Mark Paid</span>
            </button>

            <div v-if="selectedSettlement.settlement_state === 'paid'" class="paid-audit-stamp">
              <CheckCircle2 :size="14" />
              <span>Paid & Disbursed via {{ selectedSettlement.payroll_run_code || 'Batch Payroll Run' }}</span>
            </div>
          </div>
        </div>

      </div>
    </div>

    <!-- Toast Notification -->
    <div v-if="toastMessage" class="toast-popup">
      {{ toastMessage }}
    </div>
  </div>
</template>

<style scoped>
.page-container {
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  background-color: var(--primitive-color-neutral-50, #f8fafc);
  min-height: 100vh;
}

.breadcrumb-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.role-switcher-badge {
  display: flex;
  align-items: center;
  gap: 8px;
}

.role-switcher-label {
  font-size: 12px;
  color: var(--alias-color-text-tertiary, #737373);
}

.role-pill-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 28px;
  padding: 0 12px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 500;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}

.role-pill-btn.is-active {
  background-color: #eff6ff;
  border-color: #bfdbfe;
  color: #0b529c;
}

.role-icon {
  color: #0b529c;
}

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
}

.tabs-wrapper {
  margin-top: -4px;
}

.btn-primary-create {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 18px;
  border-radius: 8px;
  background-color: #0b529c;
  color: #ffffff;
  font-size: 13.5px;
  font-weight: 500;
  border: none;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-primary-create:hover {
  background-color: #083e76;
}

/* ─── Table Cell Proportions (AGENTS.md Rule 8 & 9) ─── */
.erp-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  background-color: #fafafa;
  color: #737373;
  font-size: 12px;
  font-weight: 500;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.clickable-row {
  cursor: pointer;
  transition: background-color 0.1s ease;
}

.clickable-row:hover {
  background-color: #f8fafc;
}

.th-checkbox, .td-checkbox {
  width: 38px;
  text-align: center;
}

.td-identity {
  display: flex;
  align-items: center;
  gap: 10px;
}

.table-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  object-fit: cover;
}

.identity-text {
  display: flex;
  flex-direction: column;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.table-code-subtext {
  font-size: 11.5px;
  color: #737373;
}

.td-tertiary {
  color: #737373;
}

.font-numeric {
  font-variant-numeric: tabular-nums;
}

.text-danger {
  color: #dc2626;
}

.text-success {
  color: #059669;
}

.td-net {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.status-pill {
  display: inline-block;
  padding: 2.5px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
}

.metric-clickable-wrapper {
  cursor: pointer;
  border-radius: 10px;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}

.metric-clickable-wrapper:hover {
  transform: translateY(-2px);
}

.metric-clickable-wrapper.is-active-filter {
  box-shadow: 0 0 0 2px #0b529c;
}

.action-dropdown-wrapper {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-action-dots:hover {
  color: #0b529c;
  border-color: #0b529c;
  background-color: #f8fafc;
}

.action-popup-menu {
  position: absolute;
  right: 0;
  top: 32px;
  background-color: #ffffff;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  padding: 4px;
  z-index: 100;
  min-width: 175px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.popup-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 7px 10px;
  background: none;
  border: none;
  font-size: 12.5px;
  color: #404040;
  text-align: left;
  border-radius: 6px;
  cursor: pointer;
  transition: background-color 0.12s ease;
}

.popup-item:hover {
  background-color: #f1f5f9;
  color: #0b529c;
}

.popup-item.item-approve {
  color: #059669;
}

.popup-item.item-approve:hover {
  background-color: #ecfdf5;
}

.popup-item.item-pay {
  color: #0284c7;
}

.popup-item.item-pay:hover {
  background-color: #f0f9ff;
}

.td-empty {
  text-align: center;
  padding: 36px 0;
  color: #737373;
}

/* ─── Calendar Input Standard ─── */
.quick-form-grid {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.date-field-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.compact-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.calendar-input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
}

.cal-left-icon {
  position: absolute;
  left: 10px;
  color: #94a3b8;
  pointer-events: none;
}

.cal-input {
  width: 100%;
  height: 38px;
  padding: 0 42px 0 34px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
}

.cal-input:focus {
  border-color: #0b529c;
  outline: none;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.cal-input::-webkit-calendar-picker-indicator {
  opacity: 0;
  width: 100%;
  height: 100%;
  position: absolute;
  left: 0;
  top: 0;
  cursor: pointer;
}

.gc-pill-tag {
  position: absolute;
  right: 8px;
  padding: 2px 6px;
  background-color: #f1f5f9;
  color: #64748b;
  font-size: 10.5px;
  font-weight: 600;
  border-radius: 4px;
  pointer-events: none;
}

/* ─── Bottom Drawer & Overlay ─── */
.drawer-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(3px);
  display: flex;
  align-items: flex-end; /* Anchors the drawer to the bottom */
  justify-content: center;
  z-index: 1000;
  animation: fadeInDrawerOverlay 0.2s ease-out forwards;
}

@keyframes fadeInDrawerOverlay {
  from { opacity: 0; }
  to { opacity: 1; }
}

.bottom-drawer {
  background-color: #ffffff;
  border-top-left-radius: 20px;
  border-top-right-radius: 20px;
  width: 100%;
  max-width: 1080px;
  max-height: 88vh;
  box-shadow: 0 -12px 36px rgba(15, 23, 42, 0.16);
  border-top: 1px solid rgba(226, 232, 240, 0.85);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  animation: slideUpBottomDrawer 0.28s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes slideUpBottomDrawer {
  from {
    transform: translateY(100%);
  }
  to {
    transform: translateY(0);
  }
}

/* Drag Handle / Pill */
.drawer-handle-bar {
  padding: 10px 0 2px;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: #ffffff;
}

.drawer-handle-pill {
  width: 44px;
  height: 4px;
  border-radius: 9999px;
  background-color: #cbd5e1;
}

/* Drawer Header with Prominent User Identity */
.drawer-header {
  padding: 12px 24px 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid #f1f5f9;
  background-color: #ffffff;
  gap: 16px;
}

.drawer-user-card {
  display: flex;
  align-items: center;
  gap: 16px;
  flex: 1;
  min-width: 0;
}

.drawer-avatar-wrap {
  width: 54px;
  height: 54px;
  flex-shrink: 0;
  position: relative;
}

.drawer-avatar-img {
  width: 54px;
  height: 54px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid #e2e8f0;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.drawer-avatar-placeholder {
  width: 54px;
  height: 54px;
  border-radius: 50%;
  background-color: #f1f5f9;
  color: #64748b;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid #e2e8f0;
}

.drawer-user-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.drawer-meta-pills {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.drawer-doc-code {
  display: inline-flex;
  align-items: center;
  padding: 2px 7px;
  background-color: #eff6ff;
  color: #0b529c;
  font-size: 11px;
  font-weight: 600;
  border-radius: 4px;
  font-family: monospace;
}

.drawer-emp-code {
  display: inline-flex;
  align-items: center;
  padding: 2px 7px;
  background-color: #f1f5f9;
  color: #475569;
  font-size: 11px;
  font-weight: 600;
  border-radius: 4px;
  font-family: monospace;
}

.drawer-sep-case {
  display: inline-flex;
  align-items: center;
  padding: 2px 7px;
  background-color: #faf5ff;
  color: #7e22ce;
  font-size: 11px;
  font-weight: 500;
  border-radius: 4px;
}

.drawer-sep-type {
  display: inline-flex;
  align-items: center;
  padding: 2px 6px;
  background-color: #fef3c7;
  color: #92400e;
  font-size: 10px;
  font-weight: 600;
  border-radius: 4px;
  text-transform: capitalize;
}

.drawer-title-row {
  display: flex;
  align-items: baseline;
  gap: 8px;
  flex-wrap: wrap;
}

.drawer-employee-name {
  font-size: 18px;
  font-weight: 600;
  color: #404040;
  margin: 0;
  letter-spacing: -0.2px;
}

.drawer-separator {
  color: #cbd5e1;
  font-size: 14px;
}

.drawer-statement-title {
  font-size: 14.5px;
  font-weight: 500;
  color: #737373;
}

.drawer-employee-meta {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12.5px;
  color: #737373;
  flex-wrap: wrap;
}

.meta-role {
  font-weight: 500;
  color: #525252;
}

.meta-dot {
  color: #cbd5e1;
}

.meta-dept {
  color: #737373;
}

.meta-date {
  color: #737373;
}

.drawer-header-actions {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
}

.status-pill-lg {
  padding: 4px 12px;
  font-size: 12px;
  font-weight: 600;
  border-radius: 9999px;
}

.btn-drawer-close {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  color: #64748b;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-drawer-close:hover {
  background-color: #f8fafc;
  color: #0f172a;
  border-color: #cbd5e1;
}

/* Drawer Body */
.drawer-body {
  padding: 20px 24px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 16px;
  flex: 1;
}

.sheet-metrics-strip {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
  background-color: #f8fafc;
  padding: 12px 16px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.metric-strip-item {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.metric-strip-item.is-highlight {
  border-left: 2px solid #0b529c;
  padding-left: 10px;
}

.strip-label {
  font-size: 11px;
  color: #737373;
  font-weight: 500;
}

.strip-value {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.text-net {
  color: #0b529c;
  font-size: 15px;
}

.subtable-accordion-header {
  border-bottom: 1px solid #e2e8f0;
  padding-bottom: 6px;
  margin-top: 4px;
}

.subtable-title {
  font-size: 12.5px;
  font-weight: 600;
  color: #404040;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

/* Dynamic Sub-Table */
.sub-erp-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12.5px;
}

.sub-erp-table th {
  height: 32px;
  padding: 6px 12px;
  background-color: #f8fafc;
  color: #737373;
  font-size: 11.5px;
  font-weight: 500;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

.sub-erp-table td {
  padding: 8px 12px;
  border-bottom: 1px solid #f1f5f9;
}

.sub-th-no, .sub-td-no {
  width: 32px;
  text-align: center;
  color: #94a3b8;
}

.sub-td-type {
  font-weight: 500;
  color: #404040;
}

.sub-td-desc {
  color: #737373;
}

.sub-td-numeric {
  font-variant-numeric: tabular-nums;
  color: #737373;
}

.sub-th-amount, .sub-td-amount {
  text-align: right;
  font-weight: 600;
}

.amount-plus {
  color: #059669;
}

.amount-minus {
  color: #dc2626;
}

.sub-td-source {
  color: #94a3b8;
  font-size: 11px;
}

.sub-tfoot-row td {
  padding: 12px;
  background-color: #fafafa;
  border-top: 2px solid #e2e8f0;
}

.tfoot-label {
  text-align: right;
  font-weight: 600;
  color: #404040;
}

.tfoot-net {
  text-align: right;
  font-size: 14px;
  font-weight: 700;
  color: #0b529c;
}

.drawer-footer {
  padding: 14px 24px;
  background-color: #fafbfc;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  border-top: 1px solid #f1f5f9;
  flex-shrink: 0;
}

.footer-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.footer-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.btn-footer-secondary {
  height: 36px;
  padding: 0 16px;
  border-radius: 8px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  color: #404040;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-footer-secondary:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.btn-footer-ghost {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 14px;
  border-radius: 8px;
  background-color: transparent;
  border: 1px solid #e2e8f0;
  color: #64748b;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-footer-ghost:hover {
  background-color: #f1f5f9;
  color: #334155;
  border-color: #cbd5e1;
}

.btn-footer-primary {
  height: 36px;
  padding: 0 18px;
  border-radius: 8px;
  background-color: #0b529c;
  color: #ffffff;
  font-size: 13px;
  font-weight: 500;
  border: none;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  transition: all 0.15s ease;
}

.btn-footer-primary:hover {
  background-color: #083c74;
}

.btn-footer-primary.is-pay {
  background-color: #059669;
}

.btn-footer-primary.is-pay:hover {
  background-color: #047857;
}

.btn-footer-primary.is-calc {
  background-color: #0b529c;
}

.paid-audit-stamp {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 12.5px;
  font-weight: 500;
  color: #059669;
  background-color: #ecfdf5;
  padding: 6px 14px;
  border-radius: 8px;
}

.btn-row-calculate {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 27px;
  padding: 0 11px;
  border-radius: 8px;
  background-color: #0b529c;
  color: #ffffff;
  border: 1px solid #0b529c;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.18s ease;
  white-space: nowrap;
}

.btn-row-calculate:hover {
  background-color: #083c74;
  border-color: #083c74;
  transform: translateY(-1px);
  box-shadow: 0 2px 6px rgba(11, 82, 156, 0.2);
}

.popup-item.item-calc {
  color: #0b529c;
  font-weight: 500;
}

.toast-popup {
  position: fixed;
  bottom: 24px;
  right: 24px;
  background-color: #1e293b;
  color: #ffffff;
  padding: 10px 18px;
  border-radius: 8px;
  font-size: 13px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  z-index: 2000;
}
</style>
