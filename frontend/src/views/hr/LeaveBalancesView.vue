<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { 
  PieChart, Plus, Calendar, CalendarDays, Award, Clock,
  CheckCircle2, AlertCircle, TrendingDown, ArrowUpRight,
  ArrowDownLeft, History, FileText, ChevronRight, User,
  Building2, Briefcase, RefreshCw, Layers, Check
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import UnderlineTabs, { type UnderlineTabItem } from '../../components/UnderlineTabs.vue';
import MetricCard from '../../components/MetricCard.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';

const router = useRouter();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3: Exact Sidebar Page Name Only) ───
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
    name: 'Almaz Kebede',
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

const selectedEmployeeId = ref<number>(14);

const employeeSelectOptions = computed<SelectOption[]>(() => {
  return staffProfiles.map(s => ({
    value: s.id,
    label: `${s.name} (${s.code} • ${s.position})`
  }));
});

const currentStaff = computed<StaffProfile>(() => {
  return staffProfiles.find(s => s.id === selectedEmployeeId.value) || staffProfiles[0];
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
      recalculated_at: '2026-08-01 10:00:00',
      state: 'active',
      policy_note: 'Labor Proclamation 1156/2019: 16d base + 2-year service increment (+1.0d).'
    },
    {
      id: 103,
      uuid: 'bal-0014-02',
      employee_id: 14,
      leave_type_id: 2,
      leave_type_code: 'SICK',
      leave_type_name: 'Sick Leave',
      period_start: '2026-07-08',
      period_end: '2027-07-07',
      entitled_days: 30.0,
      taken_days: 0.0,
      pending_days: 0.0,
      encashed_days: 0.0,
      expired_days: 0.0,
      adjusted_days: 0.0,
      available_days: 30.0,
      recalculated_at: '2026-07-08 00:00:00',
      state: 'active',
      policy_note: '100% paid basic salary up to 30 working days. Medical certificate required for absences > 2 days.'
    },
    {
      id: 203,
      uuid: 'bal-0014-03',
      employee_id: 14,
      leave_type_id: 4,
      leave_type_code: 'PATER',
      leave_type_name: 'Paternity Leave',
      period_start: '2026-07-08',
      period_end: '2027-07-07',
      entitled_days: 5.0,
      taken_days: 0.0,
      pending_days: 0.0,
      encashed_days: 0.0,
      expired_days: 0.0,
      adjusted_days: 0.0,
      available_days: 5.0,
      recalculated_at: '2026-07-08 00:00:00',
      state: 'active',
      policy_note: '5 consecutive working days with full pay upon spouse childbirth.'
    },
    {
      id: 303,
      uuid: 'bal-0014-04',
      employee_id: 14,
      leave_type_id: 5,
      leave_type_code: 'COMPASSION',
      leave_type_name: 'Compassionate Leave',
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
      policy_note: 'Statutory 3 paid days granted for mourning of close family relatives.'
    }
  ],
  22: [
    {
      id: 4,
      uuid: 'bal-0124-01',
      employee_id: 22,
      leave_type_id: 1,
      leave_type_code: 'ANNUAL',
      leave_type_name: 'Annual Leave',
      leave_allocation_id: 454,
      allocation_code: 'LAL-2026-0454',
      period_start: '2026-07-08',
      period_end: '2027-07-07',
      entitled_days: 27.0,
      taken_days: 5.0,
      pending_days: 0.0,
      encashed_days: 0.0,
      expired_days: 0.0,
      adjusted_days: 0.0,
      available_days: 22.0,
      recalculated_at: '2026-08-01 10:00:00',
      state: 'active',
      policy_note: 'Includes 6.0 days carry-forward from FY 2025/26 (expires Jul 7, 2028).'
    },
    {
      id: 104,
      uuid: 'bal-0124-02',
      employee_id: 22,
      leave_type_id: 2,
      leave_type_code: 'SICK',
      leave_type_name: 'Sick Leave',
      period_start: '2026-07-08',
      period_end: '2027-07-07',
      entitled_days: 30.0,
      taken_days: 0.0,
      pending_days: 0.0,
      encashed_days: 0.0,
      expired_days: 0.0,
      adjusted_days: 0.0,
      available_days: 30.0,
      recalculated_at: '2026-07-08 00:00:00',
      state: 'active',
      policy_note: '100% basic pay coverage.'
    },
    {
      id: 204,
      uuid: 'bal-0124-03',
      employee_id: 22,
      leave_type_id: 3,
      leave_type_code: 'MATER',
      leave_type_name: 'Maternity Leave',
      period_start: '2026-07-08',
      period_end: '2027-07-07',
      entitled_days: 120.0,
      taken_days: 0.0,
      pending_days: 0.0,
      encashed_days: 0.0,
      expired_days: 0.0,
      adjusted_days: 0.0,
      available_days: 120.0,
      recalculated_at: '2026-07-08 00:00:00',
      state: 'active',
      policy_note: 'Statutory 120 calendar days prenatal and postnatal paid leave.'
    }
  ],
  7: [
    {
      id: 2,
      uuid: 'bal-0007-01',
      employee_id: 7,
      leave_type_id: 1,
      leave_type_code: 'ANNUAL',
      leave_type_name: 'Annual Leave',
      leave_allocation_id: 452,
      allocation_code: 'LAL-2026-0452',
      period_start: '2026-07-08',
      period_end: '2027-07-07',
      entitled_days: 44.0,
      taken_days: 3.0,
      pending_days: 0.0,
      encashed_days: 0.0,
      expired_days: 0.0,
      adjusted_days: 0.0,
      available_days: 41.0,
      recalculated_at: '2026-07-16 10:00:00',
      state: 'active',
      policy_note: '20.0d statutory allocation + 24.0d prior rolled balance.'
    },
    {
      id: 107,
      uuid: 'bal-0007-02',
      employee_id: 7,
      leave_type_id: 2,
      leave_type_code: 'SICK',
      leave_type_name: 'Sick Leave',
      period_start: '2026-07-08',
      period_end: '2027-07-07',
      entitled_days: 30.0,
      taken_days: 0.0,
      pending_days: 0.0,
      encashed_days: 0.0,
      expired_days: 0.0,
      adjusted_days: 0.0,
      available_days: 30.0,
      recalculated_at: '2026-07-08 00:00:00',
      state: 'active',
      policy_note: 'Annual medical absence ceiling.'
    }
  ]
};

// ─── Schema Datasets: LeaveTransaction [DIST] (Lines 1761–1784) ───
export interface LeaveTransactionRecord {
  id: number;
  uuid: string;
  employee_id: number;
  leave_type_name: string;
  transaction_type: 'allocation' | 'accrual' | 'request' | 'cancellation' | 'carry_forward' | 'encashment' | 'expiry' | 'adjustment';
  reference_doc: string;
  days: number; // signed
  balance_after: number;
  transacted_at: string;
  notes: string;
}

const transactionsDatabase: Record<number, LeaveTransactionRecord[]> = {
  14: [
    {
      id: 12010,
      uuid: 'txn-001',
      employee_id: 14,
      leave_type_name: 'Annual Leave',
      transaction_type: 'allocation',
      reference_doc: 'LAL-2026-0453',
      days: 18.0,
      balance_after: 18.0,
      transacted_at: '2026-07-08 00:10:00',
      notes: 'FY 2026/27 annual statutory grant (16d base + 2-year service addition).'
    },
    {
      id: 12011,
      uuid: 'txn-002',
      employee_id: 14,
      leave_type_name: 'Annual Leave',
      transaction_type: 'request',
      reference_doc: 'LVR-2026-0732',
      days: -2.0,
      balance_after: 16.0,
      transacted_at: '2026-08-01 14:22:00',
      notes: 'Debit hold: 2-day pending annual leave request submitted.'
    }
  ],
  22: [
    {
      id: 12004,
      uuid: 'txn-003',
      employee_id: 22,
      leave_type_name: 'Annual Leave',
      transaction_type: 'allocation',
      reference_doc: 'LAL-2026-0454',
      days: 21.0,
      balance_after: 21.0,
      transacted_at: '2026-07-08 00:10:00',
      notes: 'FY 2026/27 annual statutory quota.'
    },
    {
      id: 12005,
      uuid: 'txn-004',
      employee_id: 22,
      leave_type_name: 'Annual Leave',
      transaction_type: 'carry_forward',
      reference_doc: 'LAL-2025-0450',
      days: 6.0,
      balance_after: 27.0,
      transacted_at: '2026-07-08 00:10:01',
      notes: 'Approved unconsumed rollover from FY 2025/26.'
    },
    {
      id: 12006,
      uuid: 'txn-005',
      employee_id: 22,
      leave_type_name: 'Annual Leave',
      transaction_type: 'request',
      reference_doc: 'LVR-2026-0731',
      days: -5.0,
      balance_after: 22.0,
      transacted_at: '2026-07-28 07:10:00',
      notes: 'Approved 5-day annual leave taken (Jul 27 – Jul 31).'
    }
  ],
  7: [
    {
      id: 12001,
      uuid: 'txn-006',
      employee_id: 7,
      leave_type_name: 'Annual Leave',
      transaction_type: 'allocation',
      reference_doc: 'LAL-2026-0452',
      days: 20.0,
      balance_after: 20.0,
      transacted_at: '2026-07-08 00:10:00',
      notes: 'Statutory annual grant.'
    },
    {
      id: 12002,
      uuid: 'txn-007',
      employee_id: 7,
      leave_type_name: 'Annual Leave',
      transaction_type: 'carry_forward',
      reference_doc: 'LAL-2025-0451',
      days: 24.0,
      balance_after: 44.0,
      transacted_at: '2026-07-08 00:10:01',
      notes: 'Rolled forward unutilized balance.'
    },
    {
      id: 12003,
      uuid: 'txn-008',
      employee_id: 7,
      leave_type_name: 'Annual Leave',
      transaction_type: 'request',
      reference_doc: 'LVR-2026-0733',
      days: -3.0,
      balance_after: 41.0,
      transacted_at: '2026-07-14 09:00:00',
      notes: 'Approved annual absence debited (Jul 14 – Jul 16).'
    }
  ]
};

// ─── Absence History Dataset ───
export interface AbsenceHistoryRecord {
  id: number;
  code: string;
  leave_type_name: string;
  start_date: string;
  end_date: string;
  days: number;
  approver_name: string;
  reason: string;
  state: 'pending' | 'approved' | 'rejected' | 'taken';
}

const historyDatabase: Record<number, AbsenceHistoryRecord[]> = {
  14: [
    {
      id: 732,
      code: 'LVR-2026-0732',
      leave_type_name: 'Annual Leave',
      start_date: '2026-08-10',
      end_date: '2026-08-11',
      days: 2.0,
      approver_name: 'Kassahun Belay',
      reason: 'Personal family travel to Adama.',
      state: 'pending'
    }
  ],
  22: [
    {
      id: 731,
      code: 'LVR-2026-0731',
      leave_type_name: 'Annual Leave',
      start_date: '2026-07-27',
      end_date: '2026-07-31',
      days: 5.0,
      approver_name: 'Kassahun Belay',
      reason: 'Scheduled rest and annual family break.',
      state: 'approved'
    }
  ],
  7: [
    {
      id: 733,
      code: 'LVR-2026-0733',
      leave_type_name: 'Annual Leave',
      start_date: '2026-07-14',
      end_date: '2026-07-16',
      days: 3.0,
      approver_name: 'General Manager',
      reason: 'Administrative leave extension.',
      state: 'taken'
    }
  ]
};

// ─── Reactive State for Current Employee ───
const currentBalances = computed(() => {
  return balancesDatabase[selectedEmployeeId.value] || balancesDatabase[14];
});

const currentTransactions = computed(() => {
  return transactionsDatabase[selectedEmployeeId.value] || [];
});

const currentHistory = computed(() => {
  return historyDatabase[selectedEmployeeId.value] || [];
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

const annualLeaveBalance = computed(() => {
  return currentBalances.value.find(b => b.leave_type_code === 'ANNUAL') || currentBalances.value[0];
});

// ─── Sub-views & Tabs (Rule 1: UnderlineTabs) ───
type TabKey = 'balances' | 'ledger' | 'history';
const activeTab = ref<TabKey>('balances');

const subTabs = computed<UnderlineTabItem[]>(() => [
  { id: 'balances', label: 'Balance Summary', count: currentBalances.value.length },
  { id: 'ledger', label: 'Transaction Ledger', count: currentTransactions.value.length },
  { id: 'history', label: 'Absence History', count: currentHistory.value.length }
]);

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
  <div class="leave-balances-page">
    <!-- Breadcrumb Standard (Rule 3: Exact Sidebar Page Name Only) -->
    <div class="breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ─── EMPLOYEE HERO CONTEXT & ACTION BAR ─── -->
    <div class="employee-hero-card">
      <div class="hero-left">
        <img :src="currentStaff.avatar" :alt="currentStaff.name" class="hero-avatar" />
        <div class="hero-info">
          <div class="hero-title-row">
            <h2 class="hero-name">{{ currentStaff.name }}</h2>
            <span class="hero-code-badge">{{ currentStaff.code }}</span>
          </div>
          <p class="hero-meta">
            {{ currentStaff.position }} • {{ currentStaff.entity_name }} • {{ currentStaff.service_years }} Years Continuous Service
          </p>
        </div>
      </div>

      <div class="hero-right">
        <!-- Switch Employee Dropdown (For HR / Department Heads) -->
        <div class="employee-switcher-box">
          <label class="switcher-label">View Balance Holder</label>
          <FormSelect
            v-model="selectedEmployeeId"
            :options="employeeSelectOptions"
            placeholder="Select Employee"
            class="switcher-select"
          />
        </div>

        <!-- Primary Request Leave Action -->
        <button 
          type="button" 
          class="btn-request-leave"
          @click="handleNavigateToRequest"
        >
          <Plus :size="16" />
          <span>Request Leave</span>
        </button>
      </div>
    </div>

    <!-- ─── 4 METRIC CARDS (Category B Operational Status per Rule 2) ─── -->
    <div class="metrics-grid">
      <!-- Card 1: Total Usable Balance -->
      <MetricCard
        label="TOTAL USABLE BALANCE"
        :value="`${totalUsableDays.toFixed(1)} Days`"
        subtext="Available across all approved leave buckets"
        :icon="Award"
        :show-menu="false"
      />

      <!-- Card 2: Taken This Year -->
      <MetricCard
        label="TAKEN THIS YEAR"
        :value="`${totalTakenDays.toFixed(1)} Days`"
        subtext="Approved absences utilized in FY 2026/27"
        :icon="CalendarDays"
        :show-menu="false"
      />

      <!-- Card 3: Pending Requests -->
      <MetricCard
        label="PENDING IN PIPELINE"
        :value="`${totalPendingDays.toFixed(1)} Days`"
        subtext="Awaiting line manager review"
        :icon="Clock"
        :show-menu="false"
      />

      <!-- Card 4: Rollover Expiry -->
      <MetricCard
        label="EXPIRING ROLLOVER"
        value="0.0 Days"
        subtext="Subject to 2-year statutory rollover window"
        :icon="AlertCircle"
        :show-menu="false"
      />
    </div>

    <!-- ─── LEAVE CATEGORY QUOTA CARDS (Visual Buckets per LeaveBalance) ─── -->
    <div class="quota-buckets-section">
      <div class="section-heading">
        <h3 class="section-title">Active Entitlement Buckets</h3>
        <p class="section-sub">Current statutory allowances, consumed quantities, and remaining usable quotas.</p>
      </div>

      <div class="quota-grid">
        <div 
          v-for="b in currentBalances" 
          :key="b.id"
          class="quota-card"
        >
          <div class="qc-top">
            <div class="qc-header-info">
              <span class="qc-type-name">{{ b.leave_type_name }}</span>
              <span class="qc-period">{{ formatDateRange(b.period_start, b.period_end) }}</span>
            </div>
            <span class="qc-avail-badge">
              <b>{{ b.available_days.toFixed(1) }}</b> d Available
            </span>
          </div>

          <!-- Progress Bar -->
          <div class="qc-progress-track">
            <div 
              class="qc-progress-fill"
              :style="{ width: `${Math.min(100, Math.max(0, (b.available_days / (b.entitled_days || 1)) * 100))}%` }"
            ></div>
          </div>

          <!-- Micro Breakdown Numbers -->
          <div class="qc-stats-row">
            <div class="qc-stat-item">
              <span class="qc-stat-k">Entitled</span>
              <span class="qc-stat-v">{{ b.entitled_days.toFixed(1) }} d</span>
            </div>
            <div class="qc-stat-item">
              <span class="qc-stat-k">Taken</span>
              <span class="qc-stat-v text-muted">{{ b.taken_days.toFixed(1) }} d</span>
            </div>
            <div class="qc-stat-item">
              <span class="qc-stat-k">Pending</span>
              <span class="qc-stat-v text-amber">{{ b.pending_days.toFixed(1) }} d</span>
            </div>
            <div class="qc-stat-item">
              <span class="qc-stat-k">Allocation Code</span>
              <span class="qc-stat-v">{{ b.allocation_code || 'Policy Grant' }}</span>
            </div>
          </div>

          <p class="qc-policy-note">{{ b.policy_note }}</p>
        </div>
      </div>
    </div>

    <!-- ─── MASTER DATA TABLE CARD (Rule 10: Unified card layout) ─── -->
    <AppDataTable
      title="Leave Balances &amp; Audit Ledger"
      subtitle="Denormalized cache projection per leave allocation and immutable ledger of all balance credits, debits, and adjustments."
      :show-view-action="false"
    >
      <!-- Sub-view Underline Tabs (Rule 1) -->
      <template #header-extra>
        <div class="tabs-subview-wrapper">
          <UnderlineTabs
            v-model="activeTab"
            :tabs="subTabs"
            size="sm"
          />
        </div>
      </template>

      <!-- ─── TAB 1: BALANCE SUMMARY TABLE (LeaveBalance [LINE]) ─── -->
      <template v-if="activeTab === 'balances'" #default>
        <table class="erp-table">
          <thead>
            <tr>
              <th>Leave Type</th>
              <th>Fiscal Period</th>
              <th>Entitled</th>
              <th>Taken</th>
              <th>Pending</th>
              <th>Encashed</th>
              <th>Expired</th>
              <th>Adjusted</th>
              <th>Available Days</th>
              <th>State</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="item in currentBalances"
              :key="item.id"
              class="table-row-hover"
            >
              <!-- Name Column: Bold #404040 with code subtext -->
              <td class="td-name-cell">
                <div class="name-subtext-group">
                  <span class="table-name-primary">{{ item.leave_type_name }}</span>
                  <span class="table-code-subtext">{{ item.allocation_code || item.leave_type_code }}</span>
                </div>
              </td>

              <!-- Fiscal Period: Tertiary #737373 -->
              <td class="td-tertiary">
                {{ formatDateRange(item.period_start, item.period_end) }}
              </td>

              <!-- Entitled: Tertiary #737373 -->
              <td class="td-tertiary">
                {{ item.entitled_days.toFixed(1) }} d
              </td>

              <!-- Taken: Tertiary #737373 -->
              <td class="td-tertiary">
                {{ item.taken_days.toFixed(1) }} d
              </td>

              <!-- Pending: Tertiary #737373 -->
              <td class="td-tertiary">
                {{ item.pending_days.toFixed(1) }} d
              </td>

              <!-- Encashed: Tertiary #737373 -->
              <td class="td-tertiary">
                {{ item.encashed_days.toFixed(1) }} d
              </td>

              <!-- Expired: Tertiary #737373 -->
              <td class="td-tertiary">
                {{ item.expired_days.toFixed(1) }} d
              </td>

              <!-- Adjusted: Tertiary #737373 -->
              <td class="td-tertiary">
                {{ item.adjusted_days.toFixed(1) }} d
              </td>

              <!-- Available: Primary Brand Blue #0B529C Semi-Bold -->
              <td class="td-available-blue">
                {{ item.available_days.toFixed(1) }} d
              </td>

              <!-- State: Rounded Pill -->
              <td>
                <span class="status-pill status-approved">
                  Active
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </template>

      <!-- ─── TAB 2: TRANSACTION LEDGER TABLE (LeaveTransaction [DIST]) ─── -->
      <template v-else-if="activeTab === 'ledger'" #default>
        <table class="erp-table">
          <thead>
            <tr>
              <th>Date &amp; Time</th>
              <th>Transaction Type</th>
              <th>Leave Type</th>
              <th>Document Ref</th>
              <th>Movement</th>
              <th>Balance After</th>
              <th>Justification / Notes</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="txn in currentTransactions"
              :key="txn.id"
              class="table-row-hover"
            >
              <!-- Date: Secondary #404040 -->
              <td class="td-primary-dark">
                {{ txn.transacted_at }}
              </td>

              <!-- Transaction Type: Plain text #737373 -->
              <td class="td-tertiary">
                {{ formatTransactionType(txn.transaction_type) }}
              </td>

              <!-- Leave Type: Plain text #737373 -->
              <td class="td-tertiary">
                {{ txn.leave_type_name }}
              </td>

              <!-- Document Ref: Plain text #737373 -->
              <td class="td-tertiary font-mono">
                {{ txn.reference_doc }}
              </td>

              <!-- Signed Days: Green for credit (+), Slate for debit (-) -->
              <td :class="txn.days > 0 ? 'td-credit-green' : 'td-debit-slate'">
                {{ txn.days > 0 ? `+${txn.days.toFixed(1)} d` : `${txn.days.toFixed(1)} d` }}
              </td>

              <!-- Balance After: Plain text #737373 -->
              <td class="td-tertiary font-semibold">
                {{ txn.balance_after.toFixed(1) }} d
              </td>

              <!-- Notes: Plain text #737373 -->
              <td class="td-tertiary td-notes">
                {{ txn.notes }}
              </td>
            </tr>
          </tbody>
        </table>
      </template>

      <!-- ─── TAB 3: ABSENCE HISTORY TABLE ─── -->
      <template v-else-if="activeTab === 'history'" #default>
        <table class="erp-table">
          <thead>
            <tr>
              <th>Request Code</th>
              <th>Leave Type</th>
              <th>Date Range</th>
              <th>Days</th>
              <th>Approver</th>
              <th>Reason</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="req in currentHistory"
              :key="req.id"
              class="table-row-hover"
            >
              <!-- Code: Bold #404040 -->
              <td class="td-primary-dark font-medium">
                {{ req.code }}
              </td>

              <!-- Leave Type: Tertiary #737373 -->
              <td class="td-tertiary">
                {{ req.leave_type_name }}
              </td>

              <!-- Date Range: Tertiary #737373 -->
              <td class="td-tertiary">
                {{ formatDateRange(req.start_date, req.end_date) }}
              </td>

              <!-- Days: Tertiary #737373 -->
              <td class="td-tertiary font-semibold">
                {{ req.days.toFixed(1) }} d
              </td>

              <!-- Approver: Tertiary #737373 -->
              <td class="td-tertiary">
                {{ req.approver_name }}
              </td>

              <!-- Reason: Tertiary #737373 -->
              <td class="td-tertiary td-notes">
                {{ req.reason }}
              </td>

              <!-- Status Pill -->
              <td>
                <span class="status-pill" :class="`status-${req.state}`">
                  {{ req.state.charAt(0).toUpperCase() + req.state.slice(1) }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </template>
    </AppDataTable>
  </div>
</template>

<style scoped>
.leave-balances-page {
  padding: 16px 24px 40px;
  max-width: 1360px;
  margin: 0 auto;
}

.breadcrumb-bar {
  margin-bottom: 16px;
}

/* ─── Hero Context Card ─── */
.employee-hero-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  padding: 16px 20px;
  background-color: #ffffff;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  margin-bottom: 20px;
}

.hero-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.hero-avatar {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
}

.hero-info {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.hero-title-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.hero-name {
  font-size: 18px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.hero-code-badge {
  font-size: 12px;
  font-weight: 500;
  color: #0B529C;
  background-color: #e0f2fe;
  padding: 2px 8px;
  border-radius: 6px;
}

.hero-meta {
  font-size: 13px;
  color: #737373;
  margin: 0;
}

.hero-right {
  display: flex;
  align-items: center;
  gap: 16px;
}

.employee-switcher-box {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 250px;
}

.switcher-label {
  font-size: 11px;
  font-weight: 500;
  color: #737373;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.switcher-select {
  margin: 0;
}

.btn-request-leave {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  height: 38px;
  padding: 0 16px;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 13px;
  font-weight: 500;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  white-space: nowrap;
  transition: background-color 0.15s ease;
  margin-top: 14px;
}

.btn-request-leave:hover {
  background-color: #09427d;
}

/* ─── Metrics Grid ─── */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

@media (max-width: 1024px) {
  .metrics-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  .employee-hero-card {
    flex-direction: column;
    align-items: flex-start;
  }
  .hero-right {
    width: 100%;
    justify-content: space-between;
  }
}

@media (max-width: 640px) {
  .metrics-grid {
    grid-template-columns: 1fr;
  }
  .hero-right {
    flex-direction: column;
    align-items: stretch;
  }
}

/* ─── Quota Buckets Cards ─── */
.quota-buckets-section {
  margin-bottom: 24px;
}

.section-heading {
  margin-bottom: 12px;
}

.section-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 2px;
}

.section-sub {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

.quota-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(290px, 1fr));
  gap: 16px;
}

.quota-card {
  background-color: #ffffff;
  border-radius: 12px;
  padding: 16px 18px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  display: flex;
  flex-direction: column;
  gap: 12px;
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
  font-size: 14.5px;
  font-weight: 600;
  color: #404040;
}

.qc-period {
  font-size: 11.5px;
  color: #737373;
}

.qc-avail-badge {
  font-size: 12.5px;
  color: #0B529C;
  background-color: #f0f9ff;
  padding: 3px 10px;
  border-radius: 20px;
  white-space: nowrap;
}

.qc-progress-track {
  width: 100%;
  height: 6px;
  background-color: #f1f5f9;
  border-radius: 9999px;
  overflow: hidden;
}

.qc-progress-fill {
  height: 100%;
  background-color: #0B529C;
  border-radius: 9999px;
  transition: width 0.3s ease;
}

.qc-stats-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 6px;
  padding: 8px 10px;
  background-color: #f8fafc;
  border-radius: 8px;
}

.qc-stat-item {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.qc-stat-k {
  font-size: 10.5px;
  color: #737373;
  text-transform: uppercase;
}

.qc-stat-v {
  font-size: 12px;
  font-weight: 600;
  color: #404040;
}

.text-muted {
  color: #737373 !important;
}

.text-amber {
  color: #d97706 !important;
}

.qc-policy-note {
  font-size: 11.5px;
  color: #737373;
  line-height: 1.45;
  margin: 0;
}

/* ─── Table & Cells ─── */
.tabs-subview-wrapper {
  margin-top: 10px;
  margin-bottom: 4px;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.erp-table thead th {
  height: 34px;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background-color: #fafafa;
  text-align: left;
  border-bottom: 1px solid #f1f5f9;
  white-space: nowrap;
}

.erp-table tbody td {
  height: 38px;
  padding: 8px 16px;
  font-size: 13px;
  border-bottom: 1px solid #f8fafc;
  vertical-align: middle;
}

.table-row-hover:hover {
  background-color: #f8fafc;
}

.name-subtext-group {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.table-name-primary {
  color: #404040;
  font-weight: 500;
  font-size: 13px;
}

.table-code-subtext {
  color: #737373;
  font-size: 11.5px;
}

.td-primary-dark {
  color: #404040;
}

.td-tertiary {
  color: #737373;
}

.td-available-blue {
  color: #0B529C;
  font-weight: 600;
}

.td-credit-green {
  color: #059669;
  font-weight: 600;
}

.td-debit-slate {
  color: #404040;
  font-weight: 500;
}

.td-notes {
  max-width: 280px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.font-mono {
  font-family: monospace;
}

.font-medium {
  font-weight: 500;
}

.font-semibold {
  font-weight: 600;
}

/* ─── Status Pills ─── */
.status-pill {
  display: inline-block;
  padding: 2px 10px;
  font-size: 11.5px;
  font-weight: 500;
  border-radius: 9999px;
  white-space: nowrap;
}

.status-approved, .status-taken {
  background-color: #ecfdf5;
  color: #059669;
}

.status-pending {
  background-color: #fffbeb;
  color: #d97706;
}

.status-rejected {
  background-color: #fef2f2;
  color: #dc2626;
}
</style>
