<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { 
  ArrowLeftRight, Check, X, Clock, ArrowRight, MessageSquare,
  CheckCircle2, XCircle, Search, Filter, AlertCircle, Plus,
  ShieldCheck, UserCheck, Calendar, User, Hand
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import UnderlineTabs from '../../components/UnderlineTabs.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import MetricCard from '../../components/MetricCard.vue';

const router = useRouter();

// ─── Breadcrumbs ───
const breadcrumbItems = [
  { label: 'Shift Swaps' }
];

// ─── Role Context (Approver / Supervisor vs Employee) ───
export type UserRole = 'approver' | 'employee';
const activeRole = ref<UserRole>('approver');

// Logged-in Personas for Simulation
const currentEmployee = {
  id: 18,
  name: 'Dawit Yohannes',
  role: 'Senior Cashier & Merchandiser',
  avatar: 'DY',
  branch: 'Bole Commercial Branch'
};

const currentSupervisor = {
  id: 15,
  name: 'Sara Tefera',
  role: 'Retail Shift Supervisor',
  avatar: 'ST',
  branch: 'Bole Commercial Branch'
};

// ─── Types (HR_Schema_final-v4.sql lines 1425–1450) ───
export type SwapState = 'requested' | 'accepted' | 'approved' | 'rejected' | 'cancelled';

export interface ShiftSwapRecord {
  id: number;
  uuid: string;
  code: string;
  requester_id: number;
  requester_name: string;
  requester_role: string;
  requester_avatar: string;
  requester_date: string;
  requester_shift_name: string;
  requester_shift_time: string;

  counterpart_id: number | null;
  counterpart_name?: string;
  counterpart_role?: string;
  counterpart_avatar?: string;
  counterpart_date?: string;
  counterpart_shift_name?: string;
  counterpart_shift_time?: string;
  is_open_giveaway: boolean;

  reason: string;
  swap_state: SwapState;
  created_at: string;
  accepted_at?: string;
  approved_by_name?: string;
  approved_at?: string;
}

// ─── Mock Data Aligned with HR_Schema_final-v4.sql lines 1443–1450 ───
const swaps = ref<ShiftSwapRecord[]>([
  {
    id: 31,
    uuid: 'swp-uuid-031',
    code: 'SWP-2026-0031',
    requester_id: 14,
    requester_name: 'Abebe Kebede',
    requester_role: 'Head of Sales & Retail',
    requester_avatar: 'AK',
    requester_date: '2026-07-29',
    requester_shift_name: 'Retail Morning',
    requester_shift_time: '07:00 – 15:00',

    counterpart_id: 18,
    counterpart_name: 'Dawit Yohannes',
    counterpart_role: 'Senior Cashier & Merchandiser',
    counterpart_avatar: 'DY',
    counterpart_date: '2026-07-29',
    counterpart_shift_name: 'Retail Evening',
    counterpart_shift_time: '14:30 – 22:30',
    is_open_giveaway: false,

    reason: 'Family medical appointment in the morning; agreed with Dawit to take his evening shift.',
    swap_state: 'approved',
    created_at: '2026-07-18T10:00:00Z',
    accepted_at: '2026-07-18T14:00:00Z',
    approved_by_name: 'Sara Tefera (Supervisor)',
    approved_at: '2026-07-18T16:30:00Z'
  },
  {
    id: 32,
    uuid: 'swp-uuid-032',
    code: 'SWP-2026-0032',
    requester_id: 18,
    requester_name: 'Dawit Yohannes',
    requester_role: 'Senior Cashier & Merchandiser',
    requester_avatar: 'DY',
    requester_date: '2026-07-31',
    requester_shift_name: 'Retail Evening',
    requester_shift_time: '14:30 – 22:30',

    counterpart_id: 14,
    counterpart_name: 'Abebe Kebede',
    counterpart_role: 'Head of Sales & Retail',
    counterpart_avatar: 'AK',
    counterpart_date: '2026-07-31',
    counterpart_shift_name: 'Retail Morning',
    counterpart_shift_time: '07:00 – 15:00',
    is_open_giveaway: false,

    reason: 'Attending regional commercial logistics workshop in the afternoon.',
    swap_state: 'accepted',
    created_at: '2026-07-22T08:30:00Z',
    accepted_at: '2026-07-22T09:00:00Z'
  },
  {
    id: 33,
    uuid: 'swp-uuid-033',
    code: 'SWP-2026-0033',
    requester_id: 14,
    requester_name: 'Abebe Kebede',
    requester_role: 'Head of Sales & Retail',
    requester_avatar: 'AK',
    requester_date: '2026-08-01',
    requester_shift_name: 'Retail Morning',
    requester_shift_time: '07:00 – 15:00',

    counterpart_id: null,
    is_open_giveaway: true,

    reason: 'Open giveaway request: Personal leave day, seeking qualified peer cover.',
    swap_state: 'requested',
    created_at: '2026-07-24T11:15:00Z'
  },
  {
    id: 34,
    uuid: 'swp-uuid-034',
    code: 'SWP-2026-0034',
    requester_id: 7,
    requester_name: 'Tewodros Kassahun',
    requester_role: 'Plant Security Officer',
    requester_avatar: 'TK',
    requester_date: '2026-07-28',
    requester_shift_name: 'Night Guard',
    requester_shift_time: '22:00 – 06:00',

    counterpart_id: 18,
    counterpart_name: 'Dawit Yohannes',
    counterpart_role: 'Senior Cashier & Merchandiser',
    counterpart_avatar: 'DY',
    is_open_giveaway: false,

    reason: 'Cross-role exchange request rejected due to plant security certification prerequisites.',
    swap_state: 'rejected',
    created_at: '2026-07-25T11:00:00Z',
    accepted_at: '2026-07-25T12:00:00Z'
  }
]);

// ─── Filter Tabs ───
const activeFilter = ref('all');
const searchQuery = ref('');
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3500);
};

// Approver Metrics (Only for Supervisor/Approver)
const stats = computed(() => ({
  pendingApproval: swaps.value.filter(s => s.swap_state === 'accepted').length,
  openGiveaways: swaps.value.filter(s => s.is_open_giveaway && s.swap_state === 'requested').length,
  approved: swaps.value.filter(s => s.swap_state === 'approved').length,
  total: swaps.value.length,
}));

const filterTabs = computed(() => [
  { id: 'all', label: 'All Requests', count: swaps.value.length },
  { id: 'accepted', label: 'Pending Approval', count: swaps.value.filter(s => s.swap_state === 'accepted').length },
  { id: 'requested', label: 'Requested', count: swaps.value.filter(s => s.swap_state === 'requested').length },
  { id: 'approved', label: 'Approved', count: swaps.value.filter(s => s.swap_state === 'approved').length },
  { id: 'rejected', label: 'Rejected', count: swaps.value.filter(s => s.swap_state === 'rejected').length }
]);

const filteredSwaps = computed(() => {
  return swaps.value.filter(s => {
    const matchesTab = activeFilter.value === 'all' || s.swap_state === activeFilter.value;
    const matchesSearch = searchQuery.value === '' || 
      s.code.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      s.requester_name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      (s.counterpart_name && s.counterpart_name.toLowerCase().includes(searchQuery.value.toLowerCase()));
    return matchesTab && matchesSearch;
  });
});

// ─── Supervisor Approval Actions ───
const handleApprove = (swap: ShiftSwapRecord) => {
  swap.swap_state = 'approved';
  swap.approved_by_name = `${currentSupervisor.name} (Supervisor)`;
  swap.approved_at = new Date().toISOString();
  showToast(`Shift Swap ${swap.code} approved. Shift assignments updated.`);
};

const handleReject = (swap: ShiftSwapRecord) => {
  swap.swap_state = 'rejected';
  showToast(`Shift Swap ${swap.code} rejected.`);
};

// ─── Employee Actions (Claim cover / Accept peer swap) ───
const handleClaim = (swap: ShiftSwapRecord) => {
  swap.counterpart_id = currentEmployee.id;
  swap.counterpart_name = currentEmployee.name;
  swap.counterpart_role = currentEmployee.role;
  swap.counterpart_avatar = currentEmployee.avatar;
  swap.accepted_at = new Date().toISOString();
  swap.swap_state = 'accepted';
  showToast(`You have claimed the shift cover for ${swap.code}. Awaiting supervisor authorization.`);
};

const handleAcceptPeer = (swap: ShiftSwapRecord) => {
  swap.accepted_at = new Date().toISOString();
  swap.swap_state = 'accepted';
  showToast(`You accepted the shift exchange for ${swap.code}. Awaiting supervisor authorization.`);
};

const handleDeclinePeer = (swap: ShiftSwapRecord) => {
  swap.swap_state = 'rejected';
  showToast(`You declined the shift exchange request ${swap.code}.`);
};

// ─── Create Shift Swap Request Form & Modal ───
const showCreateModal = ref(false);

export interface ShiftOptionItem {
  value: string;
  date: string;
  shiftName: string;
  shiftTime: string;
  label: string;
}

export interface ColleagueOptionItem {
  value: string;
  name: string;
  role: string;
  avatar: string;
  label: string;
}

const myShiftOptions: ShiftOptionItem[] = [
  { value: 'shift-1', date: 'Wed, Jul 29', shiftName: 'Retail Morning', shiftTime: '07:00 – 15:00', label: 'Wed, Jul 29 — Retail Morning (07:00–15:00)' },
  { value: 'shift-2', date: 'Fri, Jul 31', shiftName: 'Retail Morning', shiftTime: '07:00 – 15:00', label: 'Fri, Jul 31 — Retail Morning (07:00–15:00)' },
  { value: 'shift-3', date: 'Sat, Aug 01', shiftName: 'Retail Evening', shiftTime: '14:30 – 22:30', label: 'Sat, Aug 01 — Retail Evening (14:30–22:30)' },
  { value: 'shift-4', date: 'Sun, Aug 02', shiftName: 'Retail Morning', shiftTime: '07:00 – 15:00', label: 'Sun, Aug 02 — Retail Morning (07:00–15:00)' },
];

const colleagueOptions: ColleagueOptionItem[] = [
  { value: '14', name: 'Abebe Kebede', role: 'Head of Sales & Retail', avatar: 'AK', label: 'Abebe Kebede — Head of Sales & Retail' },
  { value: '18', name: 'Dawit Yohannes', role: 'Senior Cashier & Merchandiser', avatar: 'DY', label: 'Dawit Yohannes — Senior Cashier & Merchandiser' },
  { value: '7',  name: 'Tewodros Kassahun', role: 'Plant Security Officer', avatar: 'TK', label: 'Tewodros Kassahun — Plant Security Officer' },
  { value: '15', name: 'Sara Tefera', role: 'Retail Shift Supervisor', avatar: 'ST', label: 'Sara Tefera — Retail Shift Supervisor' },
];

const colleagueShiftOptions: ShiftOptionItem[] = [
  { value: 'cshift-1', date: 'Wed, Jul 29', shiftName: 'Retail Evening', shiftTime: '14:30 – 22:30', label: 'Wed, Jul 29 — Retail Evening (14:30–22:30)' },
  { value: 'cshift-2', date: 'Thu, Jul 30', shiftName: 'Retail Morning', shiftTime: '07:00 – 15:00', label: 'Thu, Jul 30 — Retail Morning (07:00–15:00)' },
  { value: 'cshift-3', date: 'Fri, Jul 31', shiftName: 'Retail Evening', shiftTime: '14:30 – 22:30', label: 'Fri, Jul 31 — Retail Evening (14:30–22:30)' },
  { value: 'cshift-4', date: 'Sun, Aug 02', shiftName: 'Retail Evening', shiftTime: '14:30 – 22:30', label: 'Sun, Aug 02 — Retail Evening (14:30–22:30)' },
];

const createForm = ref({
  requester_id: '18',
  requester_name: 'Dawit Yohannes',
  requester_shift: 'shift-1',
  swap_type: 'peer' as 'peer' | 'giveaway',
  counterpart_id: '14',
  counterpart_shift: 'cshift-1',
  reason: '',
});

const selectedMyShift = computed(() => {
  return myShiftOptions.find(s => s.value === createForm.value.requester_shift);
});

const selectedCounterpart = computed(() => {
  return colleagueOptions.find(c => c.value === createForm.value.counterpart_id);
});

const selectedCounterpartShift = computed(() => {
  return colleagueShiftOptions.find(s => s.value === createForm.value.counterpart_shift);
});

const openCreateModal = () => {
  createForm.value = {
    requester_id: activeRole.value === 'employee' ? '18' : '14',
    requester_name: activeRole.value === 'employee' ? 'Dawit Yohannes' : 'Abebe Kebede',
    requester_shift: 'shift-1',
    swap_type: 'peer',
    counterpart_id: activeRole.value === 'employee' ? '14' : '18',
    counterpart_shift: 'cshift-1',
    reason: '',
  };
  showCreateModal.value = true;
};

const handleCreateSwap = () => {
  if (!createForm.value.reason.trim()) {
    showToast('Please provide a reason for the shift swap request.');
    return;
  }
  if (!createForm.value.requester_shift) {
    showToast('Please select your assigned shift slot to give away.');
    return;
  }
  if (createForm.value.swap_type === 'peer' && !createForm.value.counterpart_id) {
    showToast('Please select a counterpart colleague.');
    return;
  }
  if (createForm.value.swap_type === 'peer' && !createForm.value.counterpart_shift) {
    showToast('Please select the colleague shift slot.');
    return;
  }

  const isOpen = createForm.value.swap_type === 'giveaway';
  const reqShiftObj = selectedMyShift.value;
  const cColleague = selectedCounterpart.value;
  const cShiftObj = selectedCounterpartShift.value;

  const nextCodeNum = 35 + swaps.value.length;
  const newSwap: ShiftSwapRecord = {
    id: Date.now(),
    uuid: `swp-uuid-${nextCodeNum}`,
    code: `SWP-2026-00${nextCodeNum}`,
    requester_id: Number(createForm.value.requester_id) || 18,
    requester_name: createForm.value.requester_name || 'Dawit Yohannes',
    requester_role: 'Senior Cashier & Merchandiser',
    requester_avatar: 'DY',
    requester_date: reqShiftObj?.date || 'Wed, Jul 29',
    requester_shift_name: reqShiftObj?.shiftName || 'Retail Morning',
    requester_shift_time: reqShiftObj?.shiftTime || '07:00 – 15:00',
    counterpart_id: isOpen ? null : (Number(createForm.value.counterpart_id) || 14),
    counterpart_name: isOpen ? undefined : cColleague?.name,
    counterpart_role: isOpen ? undefined : cColleague?.role,
    counterpart_avatar: isOpen ? undefined : cColleague?.avatar,
    counterpart_date: isOpen ? undefined : cShiftObj?.date,
    counterpart_shift_name: isOpen ? undefined : cShiftObj?.shiftName,
    counterpart_shift_time: isOpen ? undefined : cShiftObj?.shiftTime,
    is_open_giveaway: isOpen,
    reason: createForm.value.reason.trim(),
    swap_state: 'requested',
    created_at: new Date().toISOString(),
  };

  swaps.value.unshift(newSwap);
  showCreateModal.value = false;
  showToast(`Shift swap request ${newSwap.code} created.`);
};
</script>

<template>
  <div class="shift-swaps-page">
    <!-- Breadcrumb Standard -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Notification Toast -->
    <div v-if="toastMessage" class="action-toast">
      <CheckCircle2 :size="16" class="text-emerald-600" />
      <span>{{ toastMessage }}</span>
    </div>

    <!-- Page Header & Actions -->
    <div class="swaps-header-block">
      <div>
        <h2 class="page-title">Shift Swaps</h2>
        <p class="page-subtitle">
          {{ activeRole === 'approver' 
            ? 'Supervisor View: Authorize peer-to-peer shift swaps, claim coverage, and audit roster adjustments.'
            : 'Employee View: Request shift swaps with colleagues or claim available open shift covers.' 
          }}
        </p>
      </div>

      <div class="header-right-controls">
        <!-- Role Switcher -->
        <div class="role-selector-pill">
          <span class="role-selector-label">Role:</span>
          <button 
            type="button" 
            class="btn-role-tab" 
            :class="{ active: activeRole === 'approver' }"
            @click="activeRole = 'approver'"
          >
            <ShieldCheck :size="13" />
            <span>Supervisor / Approver</span>
          </button>
          <button 
            type="button" 
            class="btn-role-tab" 
            :class="{ active: activeRole === 'employee' }"
            @click="activeRole = 'employee'"
          >
            <User :size="13" />
            <span>Employee (Staff)</span>
          </button>
        </div>

        <!-- Create Request Button -->
        <button 
          type="button" 
          class="btn-create-swap"
          @click="openCreateModal"
        >
          <Plus :size="14" />
          <span>Request Shift Swap</span>
        </button>
      </div>
    </div>

    <!-- ─── Metric Cards: ONLY FOR APPROVER / SUPERVISOR ─── -->
    <div v-if="activeRole === 'approver'" class="metrics-grid">
      <MetricCard
        label="Pending Approval"
        :value="stats.pendingApproval"
        subtext="Awaiting supervisor authorization"
        :icon="Clock"
        :show-menu="false"
      />
      <MetricCard
        label="Open Giveaways"
        :value="stats.openGiveaways"
        subtext="Available for peer cover claim"
        :icon="ArrowLeftRight"
        :show-menu="false"
      />
      <MetricCard
        label="Approved This Month"
        :value="stats.approved"
        subtext="Roster assignments updated"
        :icon="CheckCircle2"
        :show-menu="false"
      />
      <MetricCard
        label="Total Requests"
        :value="stats.total"
        subtext="Current scheduling cycle"
        :icon="Calendar"
        :show-menu="false"
      />
    </div>

    <!-- Sub-navigation Tabs & Search -->
    <div class="filter-and-search-row">
      <UnderlineTabs 
        v-model="activeFilter" 
        :tabs="filterTabs"
      />

      <div class="header-search-box">
        <Search :size="14" class="search-icon" />
        <input 
          v-model="searchQuery" 
          type="text" 
          class="search-input"
          aria-label="Search swap requests"
        />
      </div>
    </div>

    <!-- Swap Requests List -->
    <div class="swaps-cards-stack">
      <div 
        v-for="swap in filteredSwaps" 
        :key="swap.id"
        class="swap-card-container"
      >
        <!-- Card Top Bar -->
        <div class="swap-card-top">
          <div class="swap-code-group">
            <span class="swap-code-text">{{ swap.code }}</span>
            <span class="swap-date-text">Submitted {{ new Date(swap.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) }}</span>
            <span v-if="swap.requester_id === currentEmployee.id && activeRole === 'employee'" class="badge-my-request">My Request</span>
          </div>

          <div class="swap-state-badge-wrapper">
            <span 
              class="swap-status-pill" 
              :class="`state-${swap.swap_state}`"
            >
              <template v-if="swap.swap_state === 'approved'">
                <CheckCircle2 :size="12" /> Approved
              </template>
              <template v-else-if="swap.swap_state === 'accepted'">
                <Clock :size="12" /> Counterpart Accepted
              </template>
              <template v-else-if="swap.swap_state === 'rejected'">
                <XCircle :size="12" /> Rejected
              </template>
              <template v-else>
                <Clock :size="12" /> Awaiting Peer Consent
              </template>
            </span>
          </div>
        </div>

        <!-- Exchange Details Grid -->
        <div class="exchange-parties-grid">
          <!-- Requester Party -->
          <div class="party-block">
            <div class="party-header">
              <div class="squircle-avatar">
                <span>{{ swap.requester_avatar }}</span>
              </div>
              <div class="party-text">
                <span class="party-name">{{ swap.requester_name }}</span>
                <span class="party-role">{{ swap.requester_role }}</span>
              </div>
            </div>

            <div class="shift-exchange-info">
              <span class="info-label">Offering Shift:</span>
              <div class="info-tag-box">
                <span class="shift-name">{{ swap.requester_shift_name }}</span>
                <span class="shift-sub">{{ swap.requester_date }} ({{ swap.requester_shift_time }})</span>
              </div>
            </div>
          </div>

          <!-- Swap Indicator Icon -->
          <div class="exchange-icon-column">
            <div class="exchange-circle">
              <ArrowLeftRight :size="16" class="text-blue-600" />
            </div>
          </div>

          <!-- Counterpart Party -->
          <div class="party-block">
            <template v-if="!swap.is_open_giveaway && swap.counterpart_name">
              <div class="party-header">
                <div class="squircle-avatar counterpart">
                  <span>{{ swap.counterpart_avatar }}</span>
                </div>
                <div class="party-text">
                  <span class="party-name">{{ swap.counterpart_name }}</span>
                  <span class="party-role">{{ swap.counterpart_role }}</span>
                </div>
              </div>

              <div class="shift-exchange-info">
                <span class="info-label">Receiving in Exchange:</span>
                <div class="info-tag-box">
                  <span class="shift-name">{{ swap.counterpart_shift_name }}</span>
                  <span class="shift-sub">{{ swap.counterpart_date }} ({{ swap.counterpart_shift_time }})</span>
                </div>
              </div>
            </template>

            <template v-else>
              <div class="open-giveaway-box">
                <div class="squircle-avatar open-tag">
                  <span>?</span>
                </div>
                <div class="party-text">
                  <span class="party-name">Open Giveaway</span>
                  <span class="party-role">Any qualified department peer may claim</span>
                </div>
              </div>
              <div class="shift-exchange-info">
                <span class="info-label">Exchange Terms:</span>
                <div class="info-tag-box open-tag-box">
                  <span class="shift-name">One-Way Shift Cover</span>
                  <span class="shift-sub">No reciprocal slot required</span>
                </div>
              </div>
            </template>
          </div>
        </div>

        <!-- Reason Quote Box -->
        <div class="reason-quote-box">
          <MessageSquare :size="14" class="text-slate-400 shrink-0 mt-0.5" />
          <span class="reason-text">"{{ swap.reason }}"</span>
        </div>

        <!-- Supervisor Approval Row -->
        <div v-if="swap.approved_by_name" class="approval-audit-row">
          <ShieldCheck :size="14" class="text-emerald-600" />
          <span>Approved by <strong>{{ swap.approved_by_name }}</strong> on {{ new Date(swap.approved_at || '').toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) }}</span>
        </div>

        <!-- ─── ROLE-BASED ACTION FOOTER ─── -->
        <!-- 1. APPROVER / SUPERVISOR VIEW -->
        <div v-if="activeRole === 'approver' && (swap.swap_state === 'accepted' || swap.swap_state === 'requested')" class="swap-action-footer">
          <div class="footer-hint">
            <span v-if="swap.swap_state === 'accepted'">Both employees have signed off. Supervisory statutory authorization required.</span>
            <span v-else>Awaiting counterpart acceptance before supervisory authorization.</span>
          </div>

          <div v-if="swap.swap_state === 'accepted'" class="action-buttons-group">
            <button 
              type="button" 
              class="btn-reject-swap"
              @click="handleReject(swap)"
            >
              <X :size="14" />
              <span>Reject</span>
            </button>

            <button 
              type="button" 
              class="btn-approve-swap"
              @click="handleApprove(swap)"
            >
              <Check :size="14" />
              <span>Approve Swap</span>
            </button>
          </div>
        </div>

        <!-- 2. EMPLOYEE VIEW -->
        <div v-else-if="activeRole === 'employee' && (swap.swap_state === 'requested' || swap.swap_state === 'accepted')" class="swap-action-footer">
          <div class="footer-hint">
            <span v-if="swap.is_open_giveaway && swap.swap_state === 'requested' && swap.requester_id !== currentEmployee.id">
              Open shift cover available. Click to volunteer and claim this shift.
            </span>
            <span v-else-if="!swap.is_open_giveaway && swap.swap_state === 'requested' && swap.counterpart_id === currentEmployee.id">
              Your colleague requested this shift exchange with you. Accept to forward for supervisor authorization.
            </span>
            <span v-else-if="swap.requester_id === currentEmployee.id && swap.swap_state === 'requested'">
              Your swap request is awaiting colleague acceptance.
            </span>
            <span v-else-if="swap.swap_state === 'accepted'">
              Both peers have agreed. Currently awaiting supervisor authorization.
            </span>
            <span v-else>
              Swap in progress.
            </span>
          </div>

          <!-- Employee action buttons -->
          <div class="action-buttons-group">
            <!-- Claim Open Giveaway -->
            <button 
              v-if="swap.is_open_giveaway && swap.swap_state === 'requested' && swap.requester_id !== currentEmployee.id"
              type="button" 
              class="btn-claim-swap"
              @click="handleClaim(swap)"
            >
              <Hand :size="14" />
              <span>Claim Shift Cover</span>
            </button>

            <!-- Peer Consent to Exchange -->
            <template v-else-if="!swap.is_open_giveaway && swap.swap_state === 'requested' && swap.counterpart_id === currentEmployee.id">
              <button 
                type="button" 
                class="btn-reject-swap"
                @click="handleDeclinePeer(swap)"
              >
                <X :size="14" />
                <span>Decline</span>
              </button>
              <button 
                type="button" 
                class="btn-accept-swap"
                @click="handleAcceptPeer(swap)"
              >
                <Check :size="14" />
                <span>Accept Exchange</span>
              </button>
            </template>
          </div>
        </div>
      </div>
    </div>

    <!-- ─── Create Shift Swap Request Modal (HR_Schema_final-v4.sql lines 1425–1441) ─── -->
    <QuickCreateModal
      :show="showCreateModal"
      title="Request Shift Swap"
      :show-expand-button="false"
      save-label="Submit Swap Request"
      width="md"
      @save="handleCreateSwap"
      @cancel="showCreateModal = false"
    >
      <div class="create-swap-form">
        <!-- Requester Display / Selection -->
        <div v-if="activeRole === 'approver'" class="modal-field-block">
          <FormSelect
            label="Requesting Employee"
            v-model="createForm.requester_id"
            :options="colleagueOptions"
            placeholder="Select employee"
            required
          />
        </div>
        <div v-else class="modal-identity-card">
          <div class="identity-squircle">{{ currentEmployee.avatar }}</div>
          <div class="identity-details">
            <span class="identity-primary">{{ currentEmployee.name }}</span>
            <span class="identity-secondary">{{ currentEmployee.role }} &bull; {{ currentEmployee.branch }}</span>
          </div>
          <span class="identity-badge">Requester</span>
        </div>

        <!-- Arrangement Type: Visual 2-Card Selector -->
        <div class="arrangement-section">
          <label class="arrangement-label">Swap Arrangement</label>
          <div class="arrangement-grid">
            <button
              type="button"
              class="arrangement-card"
              :class="{ selected: createForm.swap_type === 'peer' }"
              @click="createForm.swap_type = 'peer'"
            >
              <div class="arrangement-card-top">
                <div class="arrangement-icon-box">
                  <ArrowLeftRight :size="15" />
                </div>
                <div class="arrangement-radio-circle">
                  <div v-if="createForm.swap_type === 'peer'" class="radio-inner-dot" />
                </div>
              </div>
              <div class="arrangement-text-group">
                <span class="arrangement-title">Peer Exchange</span>
                <span class="arrangement-desc">Direct 2-way trade with a colleague</span>
              </div>
            </button>

            <button
              type="button"
              class="arrangement-card"
              :class="{ selected: createForm.swap_type === 'giveaway' }"
              @click="createForm.swap_type = 'giveaway'"
            >
              <div class="arrangement-card-top">
                <div class="arrangement-icon-box">
                  <Hand :size="15" />
                </div>
                <div class="arrangement-radio-circle">
                  <div v-if="createForm.swap_type === 'giveaway'" class="radio-inner-dot" />
                </div>
              </div>
              <div class="arrangement-text-group">
                <span class="arrangement-title">Open Giveaway</span>
                <span class="arrangement-desc">1-way cover open to any peer</span>
              </div>
            </button>
          </div>
        </div>

        <!-- 1. Your Shift to Relinquish -->
        <div class="modal-field-block">
          <FormSelect
            label="Your Shift to Relinquish"
            v-model="createForm.requester_shift"
            :options="myShiftOptions"
            placeholder="Select shift slot"
            required
          />
          <!-- Live highlight strip when shift selected -->
          <div v-if="selectedMyShift" class="shift-live-badge">
            <div class="live-badge-left">
              <Calendar :size="13" class="text-blue-600 shrink-0" />
              <span class="badge-date">{{ selectedMyShift.date }}</span>
            </div>
            <div class="live-badge-divider"></div>
            <div class="live-badge-right">
              <span class="badge-name">{{ selectedMyShift.shiftName }}</span>
              <span class="badge-time">({{ selectedMyShift.shiftTime }})</span>
            </div>
          </div>
        </div>

        <!-- 2. Peer Exchange Details OR Open Giveaway Banner -->
        <div v-if="createForm.swap_type === 'peer'" class="peer-exchange-container">
          <div class="peer-inputs-grid">
            <FormSelect
              label="Colleague to Trade With"
              v-model="createForm.counterpart_id"
              :options="colleagueOptions.filter(c => c.value !== createForm.requester_id)"
              placeholder="Select colleague"
              required
            />
            <FormSelect
              label="Colleague's Shift in Return"
              v-model="createForm.counterpart_shift"
              :options="colleagueShiftOptions"
              placeholder="Select shift slot"
              required
            />
          </div>

          <!-- Visual Trade Summary Flow -->
          <div v-if="selectedMyShift && selectedCounterpart && selectedCounterpartShift" class="trade-summary-flow">
            <div class="trade-slot offering">
              <span class="slot-direction-label">You Give</span>
              <span class="slot-shift-title">{{ selectedMyShift.shiftName }}</span>
              <span class="slot-shift-meta">{{ selectedMyShift.date }} ({{ selectedMyShift.shiftTime }})</span>
            </div>
            <div class="trade-arrow-wrapper">
              <div class="trade-arrow-bubble">
                <ArrowLeftRight :size="13" />
              </div>
            </div>
            <div class="trade-slot receiving">
              <span class="slot-direction-label">You Receive (from {{ selectedCounterpart.name.split(' ')[0] }})</span>
              <span class="slot-shift-title">{{ selectedCounterpartShift.shiftName }}</span>
              <span class="slot-shift-meta">{{ selectedCounterpartShift.date }} ({{ selectedCounterpartShift.shiftTime }})</span>
            </div>
          </div>
        </div>

        <div v-else class="giveaway-info-banner">
          <AlertCircle :size="16" class="giveaway-info-icon" />
          <div class="giveaway-info-text">
            <span class="giveaway-info-title">Broadcasted Open Coverage</span>
            <p class="giveaway-info-p">
              This shift slot will be broadcast to your team board. Any eligible colleague in your branch can volunteer to cover it. Once claimed, supervisor authorization will update roster assignments.
            </p>
          </div>
        </div>

        <!-- 3. Reason for Request -->
        <div class="modal-field-block">
          <FormTextarea
            label="Reason for Request"
            v-model="createForm.reason"
            :rows="2"
            required
          />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.shift-swaps-page {
  padding: 1.25rem 2rem 3rem 2rem;
  background-color: #f8fafc;
  min-height: 100vh;
}

.breadcrumb-container {
  margin-bottom: 1.25rem;
}

.action-toast {
  position: fixed;
  bottom: 2rem;
  right: 2rem;
  display: flex;
  align-items: center;
  gap: 0.625rem;
  background: #ffffff;
  color: #404040;
  padding: 0.75rem 1.25rem;
  border-radius: 8px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
  border: 1px solid #e2e8f0;
  font-size: 13.5px;
  font-weight: 500;
  z-index: 9999;
}

.swaps-header-block {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 1rem;
}

.page-title {
  font-size: 20px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}

.page-subtitle {
  font-size: 13px;
  color: #737373;
  margin: 0;
}

.header-search-box {
  position: relative;
  width: 240px;
}

.search-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: #94a3b8;
  pointer-events: none;
}

.search-input {
  width: 100%;
  height: 38px;
  padding: 0 12px 0 30px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  background: #ffffff;
  outline: none;
  transition: border-color 0.15s ease;
}

.search-input:focus {
  border-color: #0B529C;
}

.tabs-subnav-container {
  margin-bottom: 1.25rem;
}

/* Cards Stack */
.swaps-cards-stack {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.swap-card-container {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.swap-card-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-bottom: 1rem;
  border-bottom: 1px solid #f1f5f9;
}

.swap-code-group {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.swap-code-text {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.swap-date-text {
  font-size: 12px;
  color: #737373;
}

.swap-status-pill {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11.5px;
  font-weight: 600;
  padding: 3px 10px;
  border-radius: 9999px;
}

.state-approved {
  background: #ecfdf5;
  color: #059669;
}

.state-accepted {
  background: #eff6ff;
  color: #2563eb;
}

.state-rejected {
  background: #fef2f2;
  color: #dc2626;
}

.state-requested {
  background: #fffbeb;
  color: #d97706;
}

/* Exchange Grid */
.exchange-parties-grid {
  display: grid;
  grid-template-columns: 1fr 60px 1fr;
  align-items: center;
  gap: 1.5rem;
  padding: 1.25rem 0;
}

@media (max-width: 768px) {
  .exchange-parties-grid {
    grid-template-columns: 1fr;
    gap: 1rem;
  }
}

.party-block {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 1rem;
}

.party-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 0.75rem;
}

.squircle-avatar {
  width: 38px;
  height: 38px;
  border-radius: 12px;
  background: #e0f2fe;
  color: #0369a1;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 600;
  flex-shrink: 0;
}

.squircle-avatar.counterpart {
  background: #ede9fe;
  color: #6d28d9;
}

.squircle-avatar.open-tag {
  background: #f1f5f9;
  color: #94a3b8;
}

.party-text {
  display: flex;
  flex-direction: column;
}

.party-name {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.party-role {
  font-size: 11.5px;
  color: #737373;
}

.open-giveaway-box {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 0.75rem;
}

.shift-exchange-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.info-label {
  font-size: 11px;
  font-weight: 500;
  color: #737373;
}

.info-tag-box {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  padding: 6px 10px;
  display: flex;
  flex-direction: column;
}

.info-tag-box.open-tag-box {
  background: #f8fafc;
  border-style: dashed;
}

.shift-name {
  font-size: 12.5px;
  font-weight: 600;
  color: #404040;
}

.shift-sub {
  font-size: 11px;
  color: #737373;
}

.exchange-icon-column {
  display: flex;
  align-items: center;
  justify-content: center;
}

.exchange-circle {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Reason Box */
.reason-quote-box {
  display: flex;
  align-items: flex-start;
  gap: 0.625rem;
  background: #fafafa;
  border: 1px solid #f1f5f9;
  border-radius: 8px;
  padding: 0.75rem 1rem;
  margin-bottom: 1rem;
}

.reason-text {
  font-size: 12.5px;
  color: #525252;
  font-style: italic;
  line-height: 1.4;
}

/* Approval audit */
.approval-audit-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 12px;
  color: #059669;
  background: #ecfdf5;
  padding: 6px 12px;
  border-radius: 6px;
}

/* Footer Actions */
.swap-action-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-top: 1rem;
  border-top: 1px solid #f1f5f9;
  flex-wrap: wrap;
  gap: 0.75rem;
}

.footer-hint {
  font-size: 12px;
  color: #737373;
}

.action-buttons-group {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.btn-reject-swap {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  height: 36px;
  padding: 0 1rem;
  background-color: #fee2e2;
  color: #b91c1c;
  font-size: 13px;
  font-weight: 500;
  border-radius: 8px;
  border: none;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-reject-swap:hover {
  background-color: #fecaca;
}

.btn-approve-swap {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  height: 36px;
  padding: 0 1.25rem;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 13px;
  font-weight: 500;
  border-radius: 8px;
  border: none;
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.btn-approve-swap:hover {
  background-color: #09427d;
}

/* ─── Header Right Controls & Role Switcher ─── */
.header-right-controls {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.role-selector-pill {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  background-color: #f1f5f9;
  border-radius: 9999px;
  padding: 3px 4px;
  border: 1px solid #e2e8f0;
}

.role-selector-label {
  font-size: 11.5px;
  font-weight: 500;
  color: #737373;
  padding-left: 8px;
  padding-right: 2px;
}

.btn-role-tab {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 28px;
  padding: 0 11px;
  border-radius: 9999px;
  border: none;
  background: transparent;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-role-tab.active {
  background-color: #ffffff;
  color: #0B529C;
  font-weight: 600;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.btn-create-swap {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
  white-space: nowrap;
}

.btn-create-swap:hover {
  background-color: #09437f;
}

/* ─── Metric Cards Grid (Approver Only) ─── */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 20px;
}

@media (max-width: 1024px) {
  .metrics-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 640px) {
  .metrics-grid {
    grid-template-columns: 1fr;
  }
}

/* ─── Filter and Search Row ─── */
.filter-and-search-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 1.25rem;
}

.badge-my-request {
  display: inline-flex;
  padding: 2px 8px;
  border-radius: 9999px;
  background-color: #e0f2fe;
  color: #0369a1;
  font-size: 11px;
  font-weight: 600;
}

/* ─── Employee Action Buttons ─── */
.btn-claim-swap, .btn-accept-swap {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 16px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-claim-swap:hover, .btn-accept-swap:hover {
  background-color: #09437f;
}

/* ─── Modal Form Styles ─── */
.create-swap-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.modal-field-block {
  display: flex;
  flex-direction: column;
}

.modal-identity-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 14px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}

.identity-squircle {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  background-color: #e0f2fe;
  color: #0369a1;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 13px;
  flex-shrink: 0;
}

.identity-details {
  display: flex;
  flex-direction: column;
}

.identity-primary {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.identity-secondary {
  font-size: 11.5px;
  color: #737373;
}

.identity-badge {
  font-size: 11px;
  font-weight: 500;
  color: #0B529C;
  background: #eff6ff;
  padding: 2px 8px;
  border-radius: 6px;
  margin-left: auto;
}

/* ─── Arrangement 2-Card Selector ─── */
.arrangement-section {
  display: flex;
  flex-direction: column;
}

.arrangement-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 6px;
}

.arrangement-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

@media (max-width: 640px) {
  .arrangement-grid {
    grid-template-columns: 1fr;
  }
}

.arrangement-card {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 12px 14px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  cursor: pointer;
  text-align: left;
  transition: all 0.15s ease;
}

.arrangement-card:hover {
  border-color: #cbd5e1;
  background-color: #f8fafc;
}

.arrangement-card.selected {
  border-color: #0B529C;
  background-color: #f0f7ff;
  box-shadow: 0 0 0 1px #0B529C;
}

.arrangement-card-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}

.arrangement-icon-box {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  background-color: #f1f5f9;
  color: #404040;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}

.arrangement-card.selected .arrangement-icon-box {
  background-color: #0B529C;
  color: #ffffff;
}

.arrangement-radio-circle {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  border: 1.5px solid #cbd5e1;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #ffffff;
}

.arrangement-card.selected .arrangement-radio-circle {
  border-color: #0B529C;
}

.radio-inner-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: #0B529C;
}

.arrangement-text-group {
  display: flex;
  flex-direction: column;
}

.arrangement-title {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
  line-height: 1.25;
}

.arrangement-desc {
  font-size: 11.5px;
  color: #737373;
  line-height: 1.35;
  margin-top: 2px;
}

/* ─── Shift Live Badge ─── */
.shift-live-badge {
  margin-top: 6px;
  padding: 8px 12px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 12px;
}

.live-badge-left {
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 500;
  color: #0B529C;
}

.badge-date {
  font-weight: 600;
}

.live-badge-divider {
  width: 1px;
  height: 14px;
  background-color: #cbd5e1;
}

.live-badge-right {
  display: flex;
  align-items: center;
  gap: 4px;
}

.badge-name {
  font-weight: 600;
  color: #404040;
}

.badge-time {
  color: #737373;
}

/* ─── Peer Exchange Container & Live Trade Flow ─── */
.peer-exchange-container {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 12px 14px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}

.peer-inputs-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

@media (max-width: 640px) {
  .peer-inputs-grid {
    grid-template-columns: 1fr;
  }
}

.trade-summary-flow {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 14px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  margin-top: 2px;
}

.trade-slot {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.trade-slot.receiving {
  text-align: right;
}

.slot-direction-label {
  font-size: 10.5px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  color: #0B529C;
}

.slot-shift-title {
  font-size: 12.5px;
  font-weight: 600;
  color: #404040;
}

.slot-shift-meta {
  font-size: 11px;
  color: #737373;
}

.trade-arrow-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 8px;
}

.trade-arrow-bubble {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background-color: #eff6ff;
  color: #0B529C;
  border: 1px solid #bfdbfe;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

/* ─── Giveaway Info Banner ─── */
.giveaway-info-banner {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 12px 14px;
  background-color: #f0f9ff;
  border: 1px solid #bae6fd;
  border-radius: 8px;
}

.giveaway-info-icon {
  color: #0284c7;
  margin-top: 1px;
  flex-shrink: 0;
}

.giveaway-info-text {
  display: flex;
  flex-direction: column;
}

.giveaway-info-title {
  font-size: 12.5px;
  font-weight: 600;
  color: #0369a1;
  margin-bottom: 2px;
}

.giveaway-info-p {
  font-size: 11.5px;
  color: #075985;
  line-height: 1.45;
  margin: 0;
}
</style>
