<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, CalendarDays, Award, Clock,
  AlertCircle, ExternalLink,
  MoreVertical, Eye, Download, FileText
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import AppButton from '../../components/AppButton.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import MetricCard from '../../components/MetricCard.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

const router = useRouter();

// ─── Breadcrumb Navigation Standard (AGENTS.md: Exact Sidebar Page Name Only) ───
const breadcrumbItems = [
  { label: 'Leave Balances' }
];

// ─── Staff Profiles for Context Switcher ───
export interface StaffProfile {
  id: number;
  name: string;
  code: string;
  position: string;
  entity_name: string;
  hire_date: string;
  service_years: number;
  gender: 'male' | 'female';
  avatar: string;
}

const staffProfiles: StaffProfile[] = [
  {
    id: 14,
    name: 'Abebe Kebede',
    code: 'EMP 0014',
    position: 'Senior Cashier',
    entity_name: 'Bole Commercial Branch',
    hire_date: '2024-06-01',
    service_years: 2,
    gender: 'male',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    id: 22,
    name: 'Almaz Ayana',
    code: 'EMP 0124',
    position: 'Senior Accountant',
    entity_name: 'Haleta Corporate Headquarters',
    hire_date: '2021-09-15',
    service_years: 5,
    gender: 'female',
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    id: 31,
    name: 'Dawit Yohannes',
    code: 'EMP 0031',
    position: 'Logistics Officer',
    entity_name: 'Bahir Dar Regional Hub',
    hire_date: '2025-02-17',
    service_years: 1,
    gender: 'male',
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    id: 44,
    name: 'Kassahun Belay',
    code: 'EMP 0044',
    position: 'Branch Head',
    entity_name: 'Haleta Corporate Headquarters',
    hire_date: '2020-03-02',
    service_years: 6,
    gender: 'male',
    avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&h=120&q=80'
  },
  {
    id: 7,
    name: 'Marta Tadesse',
    code: 'EMP 0007',
    position: 'Branch Manager',
    entity_name: 'Haleta Corporate Headquarters',
    hire_date: '2022-01-10',
    service_years: 4,
    gender: 'female',
    avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80'
  }
];

const selectedEmployeeId = ref<number>(22);

const employeeSelectOptions = computed<SelectOption[]>(() => {
  return staffProfiles.map(s => ({
    value: s.id,
    label: `${s.name} (${s.code} • ${s.position})`
  }));
});

const currentStaff = computed<StaffProfile>(() => {
  return staffProfiles.find(s => s.id === selectedEmployeeId.value) || staffProfiles[1];
});

// ─── Schema Datasets: LeaveBalance [LINE] (Lines 1662–1687) ───
export interface LeaveBalanceRecord {
  id: number;
  uuid: string;
  employee_id: number;
  leave_type_id: number;
  leave_type_code: string;
  leave_type_name: string;
  leave_allocation_id?: number;
  allocation_code?: string;
  period_start: string;
  period_end: string;
  entitled_days: number;   // allocated + carried
  taken_days: number;      // approved & taken
  pending_days: number;    // requested, awaiting approval
  encashed_days: number;   // cashed out
  expired_days: number;    // expired rollover
  adjusted_days: number;   // manual adjustments
  available_days: number;  // entitled - taken - pending - encashed - expired + adjusted
  recalculated_at: string;
  state: 'active' | 'inactive';
  policy_note: string;
}

const balancesDatabase: Record<number, LeaveBalanceRecord[]> = {
  14: [
    {
      id: 3,
      uuid: 'bal-0014-01',
      employee_id: 14,
      leave_type_id: 1,
      leave_type_code: 'ANNUAL',
      leave_type_name: 'Annual Leave',
      leave_allocation_id: 453,
      allocation_code: 'LAL-2026-0453',
      period_start: '2026-07-08',
      period_end: '2027-07-07',
      entitled_days: 18.0,
      taken_days: 0.0,
      pending_days: 2.0,
      encashed_days: 0.0,
      expired_days: 0.0,
      adjusted_days: 0.0,
      available_days: 16.0,
      recalculated_at: '2026-07-08 00:00:00',
      state: 'active',
      policy_note: '16 statutory base + 2 service addition days. 10d carry-forward ceiling.'
    },
    {
      id: 4,
      uuid: 'bal-0014-02',
      employee_id: 14,
      leave_type_id: 2,
      leave_type_code: 'SICK',
      leave_type_name: 'Sick Leave',
      period_start: '2026-07-08',
      period_end: '2027-07-07',
      entitled_days: 180.0,
      taken_days: 0.0,
      pending_days: 0.0,
      encashed_days: 0.0,
      expired_days: 0.0,
      adjusted_days: 0.0,
      available_days: 180.0,
      recalculated_at: '2026-07-08 00:00:00',
      state: 'active',
      policy_note: 'Tiered compensation (100% first month, 50% next two months).'
    },
    {
      id: 5,
      uuid: 'bal-0014-03',
      employee_id: 14,
      leave_type_id: 4,
      leave_type_code: 'PATERNITY',
      leave_type_name: 'Paternity Leave',
      period_start: '2026-07-08',
      period_end: '2027-07-07',
      entitled_days: 3.0,
      taken_days: 0.0,
      pending_days: 0.0,
      encashed_days: 0.0,
      expired_days: 0.0,
      adjusted_days: 0.0,
      available_days: 3.0,
      recalculated_at: '2026-07-08 00:00:00',
      state: 'active',
      policy_note: 'Statutory 3 consecutive working days with full pay.'
    }
  ],
  22: [
    {
      id: 1,
      uuid: 'bal-0022-01',
      employee_id: 22,
      leave_type_id: 1,
      leave_type_code: 'LV 0012',
      leave_type_name: 'Annual Leave',
      leave_allocation_id: 450,
      allocation_code: 'LAL-2026-0450',
      period_start: '2026-06-08',
      period_end: '2027-07-07',
      entitled_days: 18.0,
      taken_days: 16.0,
      pending_days: 2.0,
      encashed_days: 2.0,
      expired_days: 0.0,
      adjusted_days: 0.0,
      available_days: 16.0,
      recalculated_at: '2026-07-08 00:00:00',
      state: 'active',
      policy_note: '16 statutory base + 2 service addition days. 10d carry-forward ceiling.'
    },
    {
      id: 2,
      uuid: 'bal-0022-02',
      employee_id: 22,
      leave_type_id: 2,
      leave_type_code: 'LV 0012',
      leave_type_name: 'Sick Leave',
      period_start: '2026-06-08',
      period_end: '2027-07-07',
      entitled_days: 18.0,
      taken_days: 10.0,
      pending_days: 0.0,
      encashed_days: 0.0,
      expired_days: 0.0,
      adjusted_days: 0.0,
      available_days: 8.0,
      recalculated_at: '2026-07-08 00:00:00',
      state: 'active',
      policy_note: 'Tiered compensation (100% first month, 50% next two months).'
    },
    {
      id: 3,
      uuid: 'bal-0022-03',
      employee_id: 22,
      leave_type_id: 4,
      leave_type_code: 'LV 0012',
      leave_type_name: 'Paternity Leave',
      period_start: '2026-06-08',
      period_end: '2027-07-07',
      entitled_days: 18.0,
      taken_days: 13.0,
      pending_days: 0.0,
      encashed_days: 0.0,
      expired_days: 0.0,
      adjusted_days: 0.0,
      available_days: 5.0,
      recalculated_at: '2026-07-08 00:00:00',
      state: 'active',
      policy_note: 'Statutory 3 consecutive working days with full pay.'
    }
  ]
};

// ─── Schema Datasets: LeaveLedger [LINE] ───
export interface LeaveLedgerRecord {
  id: number;
  uuid: string;
  employee_id: number;
  leave_type_name: string;
  leave_type_code: string;
  allocation_code: string;
  transaction_type: 'allocation' | 'carry_forward' | 'request' | 'cancellation' | 'expiry' | 'adjustment' | 'encashment';
  reference_doc: string;
  days: number;
  balance_after: number;
  transacted_at: string;
  period_start: string;
  period_end: string;
  state: 'active' | 'inactive';
  notes: string;
}

const transactionsDatabase: Record<number, LeaveLedgerRecord[]> = {
  22: [
    {
      id: 11001,
      uuid: 'txn-001',
      employee_id: 22,
      leave_type_name: 'Annual Leave',
      leave_type_code: 'LV 0012',
      allocation_code: 'LAL-2026-0450',
      transaction_type: 'allocation',
      reference_doc: 'LAL-2026-0450',
      days: 16.0,
      balance_after: 16.0,
      transacted_at: '2026-06-08 00:00:00',
      period_start: '2026-06-08',
      period_end: '2027-07-07',
      state: 'active',
      notes: 'Initial statutory annual grant for FY 2026/27.'
    },
    {
      id: 11002,
      uuid: 'txn-002',
      employee_id: 22,
      leave_type_name: 'Annual Leave',
      leave_type_code: 'LV 0012',
      allocation_code: 'LAL-2026-0450',
      transaction_type: 'carry_forward',
      reference_doc: 'LAL-2025-0449',
      days: 5.0,
      balance_after: 21.0,
      transacted_at: '2026-06-08 00:00:01',
      period_start: '2026-06-08',
      period_end: '2027-07-07',
      state: 'active',
      notes: 'Rollover balance carried forward from previous fiscal period.'
    },
    {
      id: 11003,
      uuid: 'txn-003',
      employee_id: 22,
      leave_type_name: 'Annual Leave',
      leave_type_code: 'LV 0012',
      allocation_code: 'LAL-2026-0450',
      transaction_type: 'request',
      reference_doc: 'LVR-2026-0731',
      days: -5.0,
      balance_after: 16.0,
      transacted_at: '2026-07-28 07:10:00',
      period_start: '2026-06-08',
      period_end: '2027-07-07',
      state: 'active',
      notes: 'Approved 5-day annual leave taken (Jul 27 – Jul 31).'
    },
    {
      id: 11004,
      uuid: 'txn-004',
      employee_id: 22,
      leave_type_name: 'Sick Leave',
      leave_type_code: 'LV 0013',
      allocation_code: 'LAL-2026-0451',
      transaction_type: 'allocation',
      reference_doc: 'LAL-2026-0451',
      days: 180.0,
      balance_after: 180.0,
      transacted_at: '2026-06-08 00:00:00',
      period_start: '2026-06-08',
      period_end: '2027-07-07',
      state: 'active',
      notes: 'Statutory 6-month sick entitlement pool.'
    },
    {
      id: 11005,
      uuid: 'txn-005',
      employee_id: 22,
      leave_type_name: 'Sick Leave',
      leave_type_code: 'LV 0013',
      allocation_code: 'LAL-2026-0451',
      transaction_type: 'request',
      reference_doc: 'LVR-2026-0734',
      days: -2.0,
      balance_after: 178.0,
      transacted_at: '2026-08-15 09:30:00',
      period_start: '2026-06-08',
      period_end: '2027-07-07',
      state: 'active',
      notes: 'Doctor-certified outpatient medical leave.'
    }
  ],
  14: [
    {
      id: 11010,
      uuid: 'txn-010',
      employee_id: 14,
      leave_type_name: 'Annual Leave',
      leave_type_code: 'LV 0014',
      allocation_code: 'LAL-2026-0453',
      transaction_type: 'allocation',
      reference_doc: 'LAL-2026-0453',
      days: 18.0,
      balance_after: 18.0,
      transacted_at: '2026-07-08 00:00:00',
      period_start: '2026-07-08',
      period_end: '2027-07-07',
      state: 'active',
      notes: 'Statutory annual grant for FY 2026/27.'
    }
  ]
};

// ─── Reactive State for Current Employee ───
const currentBalances = computed(() => {
  return balancesDatabase[selectedEmployeeId.value] || balancesDatabase[22];
});

const currentTransactions = computed(() => {
  return transactionsDatabase[selectedEmployeeId.value] || transactionsDatabase[22];
});

// ─── Aggregated Metrics ───
const totalUsableDays = computed(() => {
  return currentBalances.value.reduce((acc, b) => acc + b.available_days, 0);
});

const totalTakenDays = computed(() => {
  return currentBalances.value.reduce((acc, b) => acc + b.taken_days, 0);
});

const totalPendingDays = computed(() => {
  return currentBalances.value.reduce((acc, b) => acc + b.pending_days, 0);
});

// ─── Horizontal Scroll Rail Logic ───
const quotaRailRef = ref<HTMLElement | null>(null);

const scrollRail = (direction: 'left' | 'right') => {
  if (!quotaRailRef.value) return;
  const scrollAmount = 360;
  if (direction === 'left') {
    quotaRailRef.value.scrollBy({ left: -scrollAmount, behavior: 'smooth' });
  } else {
    quotaRailRef.value.scrollBy({ left: scrollAmount, behavior: 'smooth' });
  }
};

// ─── Table Columns & Filter State (Figma Node 7009:115080) ───
const searchQuery = ref('');
const activeActionMenuId = ref<number | null>(null);

const selectedBalanceIds = ref<number[]>([]);

const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Name', visible: true, sortable: true },
  { key: 'period', label: 'Fiscal Period', visible: true, sortable: true },
  { key: 'entitled', label: 'Entitled', visible: true, sortable: true },
  { key: 'taken', label: 'Taken', visible: true, sortable: true },
  { key: 'pending', label: 'Pending', visible: true, sortable: true },
  { key: 'encashed', label: 'Encashed', visible: true, sortable: true },
  { key: 'expired', label: 'Expired', visible: true, sortable: true },
  { key: 'available', label: 'Available', visible: true, sortable: true },
  { key: 'state', label: 'Status', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', width: '70px', align: 'center', visible: true }
]);

const handleToggleColumn = (colKey: string | { key: string; visible: boolean }) => {
  const k = typeof colKey === 'string' ? colKey : colKey.key;
  const col = tableColumns.value.find(c => c.key === k);
  if (col) col.visible = typeof colKey === 'string' ? !col.visible : colKey.visible;
};

const filteredBalances = computed(() => {
  return currentBalances.value.filter(item => {
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase().trim();
      const matchName = item.leave_type_name.toLowerCase().includes(q);
      const matchCode = item.leave_type_code.toLowerCase().includes(q);
      if (!matchName && !matchCode) return false;
    }
    return true;
  });
});

const isAllSelected = computed(() => {
  return filteredBalances.value.length > 0 && selectedBalanceIds.value.length === filteredBalances.value.length;
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedBalanceIds.value = [];
  } else {
    selectedBalanceIds.value = filteredBalances.value.map(t => t.id);
  }
};

const toggleSelectRow = (id: number) => {
  const idx = selectedBalanceIds.value.indexOf(id);
  if (idx > -1) {
    selectedBalanceIds.value.splice(idx, 1);
  } else {
    selectedBalanceIds.value.push(id);
  }
};

const handleBatchDelete = () => {
  selectedBalanceIds.value = [];
};

// ─── Navigation ───
const handleNavigateToRequest = () => {
  router.push({
    path: '/hr/leave-requests/create',
    query: { employee_id: selectedEmployeeId.value }
  });
};

const formatDateRange = (start: string, end: string) => {
  const dStart = new Date(start);
  const dEnd = new Date(end);
  const opt: Intl.DateTimeFormatOptions = { month: 'short', day: 'numeric', year: 'numeric' };
  return `${dStart.toLocaleDateString('en-US', opt)} – ${dEnd.toLocaleDateString('en-US', opt)}`;
};

const formatTransactionType = (t: string) => {
  switch (t) {
    case 'allocation': return 'Annual Grant';
    case 'carry_forward': return 'Rollover Credit';
    case 'request': return 'Absence Debit';
    case 'cancellation': return 'Cancellation Credit';
    case 'expiry': return 'Rollover Expiry';
    case 'adjustment': return 'Adjustment';
    case 'encashment': return 'Cash Encashment';
    default: return t;
  }
};
</script>

<template>
  <div class="leave-balances-page" @click="activeActionMenuId = null">
    <!-- Breadcrumb Standard (AGENTS.md: Exact Sidebar Page Name Only) -->
    <div class="breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ─── EMPLOYEE HERO CONTEXT & ACTION BAR (Figma Node 7009:115090) ─── -->
    <div class="employee-hero-card">
      <div class="hero-left">
        <img :src="currentStaff.avatar" :alt="currentStaff.name" class="hero-avatar" />
        <div class="hero-info">
          <div class="hero-title-row">
            <h2 class="hero-name">{{ currentStaff.name }}</h2>
            <span class="hero-code-badge">{{ currentStaff.code }}</span>
            <span class="hero-pos-badge">{{ currentStaff.position }}</span>
          </div>
          <p class="hero-meta">
            Works at Bole Branch — <b>Finance Department</b> | {{ currentStaff.service_years }} Years Continuous Service
          </p>
        </div>
      </div>

      <div class="hero-right">
        <!-- Switch Employee Dropdown -->
        <div class="employee-switcher-box">
          <label class="switcher-label">View Balance Holder</label>
          <FormSelect
            v-model="selectedEmployeeId"
            :options="employeeSelectOptions"
            placeholder="Select Employee"
            class="switcher-select"
          />
        </div>
      </div>
    </div>

    <!-- ─── TOP SECTION: ACTIVE ENTITLEMENT BUCKETS & METRICS (Figma Node 7009:115080) ─── -->
    <div class="entitlement-section-card">
      <div class="entitlement-section-header">
        <div class="header-text-block">
          <h3 class="section-title">Active Entitlement Buckets</h3>
          <p class="section-sub">Current statutory allowances, consumed quantities, and remaining usable quotas.</p>
        </div>

        <AppButton 
          variant="primary" 
          size="md"
          @click="handleNavigateToRequest"
        >
          <span>Create Leave Request</span>
          <template #icon-right><ExternalLink :size="15" /></template>
        </AppButton>
      </div>

      <!-- 4 Metric Cards (Category B Status per Rule 2) -->
      <div class="metrics-grid">
        <MetricCard
          label="TOTAL USABLE BALANCE"
          :value="`${totalUsableDays.toFixed(1)} Days`"
          subtext="Available across all approved leave buckets"
          :icon="Award"
          :show-menu="false"
        />
        <MetricCard
          label="TAKEN THIS YEAR"
          :value="`${totalTakenDays.toFixed(1)} Days`"
          subtext="Approved absences utilized in FY 2026/27"
          :icon="CalendarDays"
          :show-menu="false"
        />
        <MetricCard
          label="PENDING IN PIPELINE"
          :value="`${totalPendingDays.toFixed(1)} Days`"
          subtext="Awaiting line manager review"
          :icon="Clock"
          :show-menu="false"
        />
        <MetricCard
          label="EXPIRING ROLLOVER"
          value="0.0 Days"
          subtext="Subject to 2-year statutory rollover window"
          :icon="AlertCircle"
          :show-menu="false"
        />
      </div>

      <!-- STATIC 3-COLUMN CARDS GRID (Figma Node 7009:115080) - Not scrollable -->
      <div class="quota-cards-grid">
        <div 
          v-for="b in currentBalances" 
          :key="b.id"
          class="quota-bucket-card"
        >
          <div class="qc-top">
            <div class="qc-header-info">
              <span class="qc-type-name">{{ b.leave_type_name }}</span>
              <span class="qc-period">{{ formatDateRange(b.period_start, b.period_end) }}</span>
            </div>
            <BaseBadge color="primary">
              {{ b.available_days.toFixed(1) }} d Available
            </BaseBadge>
          </div>

          <!-- Progress Track -->
          <div class="qc-progress-track">
            <div 
              class="qc-progress-fill" 
              :style="{ width: `${Math.min(100, Math.max(5, (b.available_days / (b.entitled_days || 1)) * 100))}%` }"
            ></div>
          </div>

          <!-- Mini Stats Grid -->
          <div class="qc-stats-grid">
            <div class="qc-stat-item">
              <span class="stat-lbl">Entitled</span>
              <span class="stat-num">{{ b.entitled_days.toFixed(1) }} d</span>
            </div>
            <div class="qc-stat-item">
              <span class="stat-lbl">Consumed</span>
              <span class="stat-num">{{ b.taken_days.toFixed(1) }} d</span>
            </div>
            <div class="qc-stat-item">
              <span class="stat-lbl">Pending</span>
              <span class="stat-num">{{ b.pending_days.toFixed(1) }} d</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ─── UNIFIED DIRECTORY TABLE: LEAVE BALANCES & AUDIT LEDGER (Figma Node 7009:115080) ─── -->
    <div class="table-container-card">
      <AppDataTable
        title="Leave Balances & Audit Ledger"
        subtitle="Denormalized cache projection per leave allocation and immutable ledger of all balance credits, debits, and adjustments."
        :columns="tableColumns"
        :data="filteredBalances"
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search balances by leave type or code..."
        @toggleColumn="handleToggleColumn"
      >
        <!-- Table Body -->
        <template #default>
          <div class="table-responsive">
            <table class="erp-table">
              <thead>
                <tr>
                  <th class="th-checkbox" width="40">
                    <FormCheckbox
                      :model-value="isAllSelected"
                      :indeterminate="selectedBalanceIds.length > 0 && !isAllSelected"
                      @update:model-value="toggleSelectAll"
                      aria-label="Select all balances"
                    />
                  </th>
                  <th 
                    v-for="col in tableColumns.filter(c => c.visible !== false)" 
                    :key="col.key"
                    :style="{ width: col.width, textAlign: col.align || 'left' }"
                  >
                    {{ col.label }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr 
                  v-for="item in filteredBalances" 
                  :key="item.id"
                  class="erp-row"
                >
                  <!-- Checkbox -->
                  <td class="td-checkbox" @click.stop>
                    <FormCheckbox
                      :model-value="selectedBalanceIds.includes(item.id)"
                      @update:model-value="toggleSelectRow(item.id)"
                      aria-label="Select row"
                    />
                  </td>

                  <!-- Name Column: Bold #404040 with code subtext (LV 0012) -->
                  <td v-if="tableColumns.find(c => c.key === 'name')?.visible !== false">
                    <div class="name-column-wrap">
                      <span class="table-name-primary">{{ item.leave_type_name }}</span>
                      <span class="table-code-subtext">{{ item.leave_type_code }}</span>
                    </div>
                  </td>

                  <!-- Fiscal Period -->
                  <td v-if="tableColumns.find(c => c.key === 'period')?.visible !== false">
                    <span class="table-text-tertiary">
                      {{ formatDateRange(item.period_start, item.period_end) }}
                    </span>
                  </td>

                  <!-- Entitled -->
                  <td v-if="tableColumns.find(c => c.key === 'entitled')?.visible !== false">
                    <span class="table-text-secondary font-medium">
                      {{ item.entitled_days.toFixed(1) }} Days
                    </span>
                  </td>

                  <!-- Taken -->
                  <td v-if="tableColumns.find(c => c.key === 'taken')?.visible !== false">
                    <span class="table-text-secondary font-medium">
                      {{ item.taken_days.toFixed(1) }} Days
                    </span>
                  </td>

                  <!-- Pending -->
                  <td v-if="tableColumns.find(c => c.key === 'pending')?.visible !== false">
                    <span class="table-text-secondary font-medium">
                      {{ item.pending_days > 0 ? `${item.pending_days.toFixed(1)} Days` : '0 Days' }}
                    </span>
                  </td>

                  <!-- Encashed -->
                  <td v-if="tableColumns.find(c => c.key === 'encashed')?.visible !== false">
                    <span class="table-text-tertiary">
                      {{ item.encashed_days > 0 ? `${item.encashed_days.toFixed(1)} Days` : '—' }}
                    </span>
                  </td>

                  <!-- Expired -->
                  <td v-if="tableColumns.find(c => c.key === 'expired')?.visible !== false">
                    <span class="table-text-tertiary">
                      {{ item.expired_days > 0 ? `${item.expired_days.toFixed(1)} Days` : (item.id === 1 ? '0 Days' : '—') }}
                    </span>
                  </td>

                  <!-- Available -->
                  <td v-if="tableColumns.find(c => c.key === 'available')?.visible !== false">
                    <span class="table-text-primary font-semibold">
                      {{ item.available_days.toFixed(1) }} Days
                    </span>
                  </td>

                  <!-- Status -->
                  <td v-if="tableColumns.find(c => c.key === 'state')?.visible !== false">
                    <BaseBadge :color="item.state === 'active' ? 'success' : 'gray'">
                      {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                    </BaseBadge>
                  </td>

                  <!-- Actions (3-dot kebab menu) -->
                  <td 
                    v-if="tableColumns.find(c => c.key === 'actions')?.visible !== false" 
                    class="td-actions"
                    @click.stop
                  >
                    <div class="action-menu-relative">
                      <button 
                        type="button"
                        class="btn-action-dots" 
                        @click="activeActionMenuId = activeActionMenuId === item.id ? null : item.id"
                        title="Actions"
                      >
                        <MoreVertical :size="15" />
                      </button>

                      <div v-if="activeActionMenuId === item.id" class="dropdown-action-menu">
                        <button class="dropdown-item" @click="activeActionMenuId = null">
                          <Eye :size="14" />
                          <span>View Balance Details</span>
                        </button>
                        <button class="dropdown-item" @click="activeActionMenuId = null">
                          <FileText :size="14" />
                          <span>Audit Ledger Records</span>
                        </button>
                      </div>
                    </div>
                  </td>
                </tr>

                <tr v-if="filteredBalances.length === 0">
                  <td colspan="10" class="empty-table-row">
                    No leave balances match the search criteria.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </template>
      </AppDataTable>

      <!-- Floating Batch Bar -->
      <TableFloatingBar
        :show="selectedBalanceIds.length > 0"
        :count="selectedBalanceIds.length"
        :total="filteredBalances.length"
        @delete="handleBatchDelete"
        @close="selectedBalanceIds = []"
        @clear="selectedBalanceIds = []"
      />
    </div>
  </div>
</template>

<style scoped>
.leave-balances-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: #fafafa;
  min-height: 100vh;
}

.breadcrumb-bar {
  display: flex;
  align-items: center;
}

/* ─── Hero Employee Card (Figma Node 7009:115090) ─── */
.employee-hero-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
}

.hero-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.hero-avatar {
  width: 54px;
  height: 54px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid #ffffff;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08);
}

.hero-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.hero-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.hero-name {
  font-size: 18px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.hero-code-badge {
  font-size: 13px;
  color: #737373;
}

.hero-pos-badge {
  font-size: 12px;
  font-weight: 500;
  color: #404040;
  background-color: #f5f5f5;
  padding: 2px 8px;
  border-radius: 12px;
}

.hero-meta {
  font-size: 14px;
  color: #737373;
  margin: 0;
}

.hero-meta b {
  color: #404040;
}

.hero-right {
  display: flex;
  align-items: center;
  gap: 16px;
}

.employee-switcher-box {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.switcher-label {
  font-size: 11px;
  color: #737373;
  font-weight: 500;
  text-transform: uppercase;
}

.switcher-select {
  min-width: 260px;
}

/* ─── Top Entitlement Buckets Card Container (Figma Node 7009:115106) ─── */
.entitlement-section-card {
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.entitlement-section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
}

.header-text-block {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.section-sub {
  font-size: 14px;
  color: #737373;
  margin: 0;
}

.rail-nav-controls {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-rail-nav {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: 1px solid #e5e5e5;
  background-color: #ffffff;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-rail-nav:hover {
  background-color: #f5f5f5;
  border-color: #d4d4d4;
}

/* 4 Metric Cards Grid */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
}

@media (max-width: 1024px) {
  .metrics-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Static 3-Column Cards Grid (Figma Node 7009:115080) - Not scrollable */
.quota-cards-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  width: 100%;
}

@media (max-width: 900px) {
  .quota-cards-grid {
    grid-template-columns: 1fr;
  }
}

.quota-bucket-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  transition: all 0.15s ease;
}

.quota-bucket-card:hover {
  border-color: #d4d4d4;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.04);
}

.qc-top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.qc-header-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.qc-type-name {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
}

.qc-period {
  font-size: 12px;
  color: #737373;
}

.qc-progress-track {
  width: 100%;
  height: 8px;
  background-color: #e5e5e5;
  border-radius: 999px;
  overflow: hidden;
}

.qc-progress-fill {
  height: 100%;
  background-color: #0B529C;
  border-radius: 999px;
  transition: width 0.3s ease;
}

.qc-stats-grid {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 4px;
}

.qc-stat-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.stat-lbl {
  font-size: 11px;
  color: #737373;
  text-transform: uppercase;
}

.stat-num {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

/* ─── Table Container Card ─── */
.table-container-card {
  width: 100%;
}

.table-responsive {
  width: 100%;
  overflow-x: auto;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  text-align: left;
}

.erp-table thead th {
  padding: 12px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  border-bottom: 1px solid #e5e5e5;
  background-color: #fafafa;
  white-space: nowrap;
}

.th-checkbox,
.td-checkbox {
  width: 40px;
  padding: 12px 0 12px 16px;
  text-align: center;
}

.table-checkbox {
  cursor: pointer;
  width: 16px;
  height: 16px;
  accent-color: #0B529C;
}

.erp-row {
  border-bottom: 1px solid #f0f0f0;
  transition: background-color 0.15s ease;
}

.erp-row:hover {
  background-color: #f8fafc;
}

.erp-table tbody td {
  padding: 14px 16px;
  vertical-align: middle;
}

.name-column-wrap {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.table-code-subtext {
  font-size: 12px;
  color: #737373;
}

.table-text-tertiary {
  color: #737373;
  font-size: 13px;
}

.table-text-secondary {
  color: #404040;
  font-size: 13px;
}

.text-positive {
  color: #009966;
}

.text-negative {
  color: #e7000b;
}

/* Filter dropdown wrap */
.filter-controls-cluster {
  display: flex;
  align-items: center;
  gap: 8px;
}

.filter-dropdown-wrap {
  min-width: 200px;
}

/* 3-Dot Action Menu */
.td-actions {
  width: 48px;
  text-align: center;
  position: relative;
}

.action-menu-relative {
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
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  outline: none !important;
  box-shadow: none !important;
  transition: all 0.15s ease;
}

.btn-action-dots:hover {
  background-color: #f0f0f0;
  color: #404040;
}

.btn-action-dots:focus,
.btn-action-dots:focus-visible,
.btn-action-dots:active {
  outline: none !important;
  box-shadow: none !important;
}

.dropdown-action-menu {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  padding: 4px;
  min-width: 200px;
  z-index: 50;
  display: flex;
  flex-direction: column;
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  font-size: 13px;
  color: #404040;
  background: none;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.15s ease;
  width: 100%;
}

.dropdown-item:hover {
  background-color: #f5f5f5;
}

.empty-table-row {
  text-align: center;
  padding: 40px;
  color: #737373;
  font-size: 13px;
}
</style>
