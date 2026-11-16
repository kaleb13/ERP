<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  ArrowLeftRight, Check, X, Clock,
  CheckCircle2, Plus, Info, LayoutGrid,
  Hand, List, MoreVertical
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import AppButton from '../../components/AppButton.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import { useToast } from '../../composables/useToast';

const router = useRouter();

// ─── Breadcrumbs ───
const breadcrumbItems = [
  { label: 'Shift Swaps' }
];

// ─── View Mode (Card View vs Table View) ───
export type ViewMode = 'cards' | 'table';
const viewMode = ref<ViewMode>('cards');

const swapTabs = computed<BaseTabItem<ViewMode>[]>(() => [
  { id: 'cards', label: 'Card View', icon: LayoutGrid },
  { id: 'table', label: 'List View', icon: List }
]);

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
  show_consent_banner?: boolean;
  approved_by_name?: string;
  approved_at?: string;
}

// ─── Mock Data exactly matching Figma Node 6328:117880 ───
const swaps = ref<ShiftSwapRecord[]>([
  // Card 1: SWP-2026-003 with Blue Prompt Banner
  {
    id: 1,
    uuid: 'swp-uuid-003',
    code: 'SWP-2026-003',
    requester_id: 101,
    requester_name: 'Almaz Ayana',
    requester_role: 'Chef Executive Officer',
    requester_avatar: 'AA',
    requester_date: '2026 - 07 - 31',
    requester_shift_name: 'Retail Evening',
    requester_shift_time: '14:30 - 22:30',

    counterpart_id: 102,
    counterpart_name: 'Abebe Kebede',
    counterpart_role: 'Chef Executive Director',
    counterpart_avatar: 'AK',
    counterpart_date: '2026 - 07 - 31',
    counterpart_shift_name: 'Retail Morning',
    counterpart_shift_time: '14:30 - 22:30',
    is_open_giveaway: false,

    reason: 'Family medical appointment in the morning; agreed with Dawit to take his evening shift.',
    swap_state: 'requested',
    show_consent_banner: true,
    created_at: '2026-07-22T08:30:00Z'
  },
  // Card 2: SWP-2026-002 with Counterpart Accepted & Supervisor Action Buttons
  {
    id: 2,
    uuid: 'swp-uuid-002',
    code: 'SWP-2026-003',
    requester_id: 101,
    requester_name: 'Almaz Ayana',
    requester_role: 'Chef Executive Officer',
    requester_avatar: 'AA',
    requester_date: '2026 - 07 - 31',
    requester_shift_name: 'Retail Evening',
    requester_shift_time: '14:30 - 22:30',

    counterpart_id: 102,
    counterpart_name: 'Abebe Kebede',
    counterpart_role: 'Chef Executive Officer',
    counterpart_avatar: 'AK',
    counterpart_date: '2026 - 07 - 31',
    counterpart_shift_name: 'Retail Morning',
    counterpart_shift_time: '14:30 - 22:30',
    is_open_giveaway: false,

    reason: 'Family medical appointment in the morning; agreed with Dawit to take his evening shift.',
    swap_state: 'accepted',
    show_consent_banner: false,
    created_at: '2026-07-22T08:30:00Z'
  },
  // Card 3: SWP-2026-001 Open Giveaway with Claim button
  {
    id: 3,
    uuid: 'swp-uuid-001',
    code: 'SWP-2026-003',
    requester_id: 101,
    requester_name: 'Almaz Ayana',
    requester_role: 'Chef Executive Officer',
    requester_avatar: 'AA',
    requester_date: '2026 - 07 - 31',
    requester_shift_name: 'Retail Evening',
    requester_shift_time: '14:30 - 22:30',

    counterpart_id: null,
    is_open_giveaway: true,

    reason: 'Family medical appointment in the morning; agreed with Dawit to take his evening shift.',
    swap_state: 'requested',
    show_consent_banner: false,
    created_at: '2026-07-22T08:30:00Z'
  },
  // Approved record to populate the 4th metric card
  {
    id: 4,
    uuid: 'swp-uuid-004',
    code: 'SWP-2026-004',
    requester_id: 14,
    requester_name: 'Dawit Yohannes',
    requester_role: 'Senior Cashier & Merchandiser',
    requester_avatar: 'DY',
    requester_date: '2026 - 07 - 28',
    requester_shift_name: 'Retail Morning',
    requester_shift_time: '07:00 - 15:00',

    counterpart_id: 15,
    counterpart_name: 'Sara Tefera',
    counterpart_role: 'Retail Shift Supervisor',
    counterpart_avatar: 'ST',
    counterpart_date: '2026 - 07 - 28',
    counterpart_shift_name: 'Retail Evening',
    counterpart_shift_time: '14:30 - 22:30',
    is_open_giveaway: false,

    reason: 'Mutual agreement for inventory stock audit coverage.',
    swap_state: 'approved',
    show_consent_banner: false,
    created_at: '2026-07-20T10:00:00Z',
    approved_by_name: 'HR Shift Admin',
    approved_at: '2026-07-21T11:00:00Z'
  }
]);

// ─── Notification Toast & Status Helpers ───
const { toast } = useToast();
const activeActionMenuId = ref<string | null>(null);

const getSwapStatusColor = (state: string): 'success' | 'blue' | 'warning' | 'error' => {
  switch (state) {
    case 'approved': return 'success';
    case 'accepted': return 'blue';
    case 'requested': return 'warning';
    case 'rejected':
    case 'cancelled':
      return 'error';
    default: return 'blue';
  }
};

const getSwapStatusLabel = (state: string): string => {
  switch (state) {
    case 'approved': return 'Approved';
    case 'accepted': return 'Counterpart Accepted';
    case 'rejected': return 'Rejected';
    default: return 'Awaiting Consent';
  }
};

const showToast = (msg: string) => {
  toast.success(msg);
};

// ─── Metrics (Figma Node 6328:117898) ───
const stats = computed(() => ({
  total: 4,
  pendingApproval: swaps.value.filter(s => s.swap_state === 'accepted').length || 1,
  openGiveaways: swaps.value.filter(s => s.is_open_giveaway && s.swap_state === 'requested').length || 2,
  approved: 3
}));

// ─── Interactive Actions ───
// Banner Actions (Card 1)
const handleBannerAccept = (swap: ShiftSwapRecord) => {
  swap.swap_state = 'accepted';
  swap.show_consent_banner = false;
  showToast(`You accepted the shift swap request ${swap.code}. Awaiting supervisor authorization.`);
};

const handleBannerReject = (swap: ShiftSwapRecord) => {
  swap.swap_state = 'rejected';
  swap.show_consent_banner = false;
  showToast(`You rejected the shift swap request ${swap.code}.`);
};

// Supervisor Actions (Card 2)
const handleApprove = (swap: ShiftSwapRecord) => {
  swap.swap_state = 'approved';
  swap.approved_by_name = 'Supervisor';
  swap.approved_at = new Date().toISOString();
  showToast(`Shift Swap ${swap.code} approved. Shift roster updated.`);
};

const handleReject = (swap: ShiftSwapRecord) => {
  swap.swap_state = 'rejected';
  showToast(`Shift Swap ${swap.code} rejected.`);
};

// Open Giveaway Claim (Card 3)
const handleClaim = (swap: ShiftSwapRecord) => {
  swap.counterpart_id = 102;
  swap.counterpart_name = 'Abebe Kebede';
  swap.counterpart_role = 'Chef Executive Director';
  swap.counterpart_avatar = 'AK';
  swap.counterpart_shift_name = 'Retail Morning';
  swap.counterpart_date = '2026 - 07 - 31';
  swap.counterpart_shift_time = '14:30 - 22:30';
  swap.is_open_giveaway = false;
  swap.swap_state = 'accepted';
  showToast(`You claimed shift cover for ${swap.code}. Awaiting supervisor authorization.`);
};

// Quick Create Modal State
const showCreateModal = ref(false);
const colleagueOptions = [
  { value: '102', label: 'Abebe Kebede — Chef Executive Director' },
  { value: '103', label: 'Dawit Yohannes — Senior Cashier' },
  { value: '104', label: 'Sara Tefera — Retail Shift Supervisor' }
];

const createForm = ref({
  counterpart_id: '102',
  reason: ''
});

const handleCreateSubmit = () => {
  if (!createForm.value.reason.trim()) {
    showToast('Please provide a reason for the swap.');
    return;
  }
  const newSwap: ShiftSwapRecord = {
    id: Date.now(),
    uuid: `swp-uuid-${swaps.value.length + 1}`,
    code: `SWP-2026-00${swaps.value.length + 1}`,
    requester_id: 101,
    requester_name: 'Almaz Ayana',
    requester_role: 'Chef Executive Officer',
    requester_avatar: 'AA',
    requester_date: '2026 - 08 - 05',
    requester_shift_name: 'Retail Evening',
    requester_shift_time: '14:30 - 22:30',
    counterpart_id: 102,
    counterpart_name: 'Abebe Kebede',
    counterpart_role: 'Chef Executive Director',
    counterpart_avatar: 'AK',
    counterpart_date: '2026 - 08 - 05',
    counterpart_shift_name: 'Retail Morning',
    counterpart_shift_time: '07:00 - 15:00',
    is_open_giveaway: false,
    reason: createForm.value.reason.trim(),
    swap_state: 'requested',
    show_consent_banner: true,
    created_at: new Date().toISOString()
  };
  swaps.value.unshift(newSwap);
  showCreateModal.value = false;
  showToast(`Shift swap request ${newSwap.code} created.`);
};

// ─── Table View State (AppDataTable Standard) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'code', label: 'Swap Code', visible: true },
  { key: 'requester', label: 'Requesting Employee & Shift', visible: true },
  { key: 'type', label: 'Type', visible: true },
  { key: 'counterpart', label: 'Counterpart Colleague & Shift', visible: true },
  { key: 'status', label: 'Status', visible: true },
  { key: 'submitted', label: 'Submitted Date', visible: true },
  { key: 'actions', label: 'Actions', visible: true }
]);

const handleToggleColumn = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  if (col) col.visible = !col.visible;
};

const isColVisible = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  return col ? col.visible !== false : true;
};

const tableSearchQuery = ref('');
const tableCurrentPage = ref(1);
const tablePerPage = ref(10);
const tableStatusFilter = ref('all');

const filteredTableSwaps = computed(() => {
  return swaps.value.filter(s => {
    const matchesSearch = !tableSearchQuery.value ||
      s.code.toLowerCase().includes(tableSearchQuery.value.toLowerCase()) ||
      s.requester_name.toLowerCase().includes(tableSearchQuery.value.toLowerCase()) ||
      (s.counterpart_name && s.counterpart_name.toLowerCase().includes(tableSearchQuery.value.toLowerCase()));
    const matchesStatus = tableStatusFilter.value === 'all' || s.swap_state === tableStatusFilter.value;
    return matchesSearch && matchesStatus;
  });
});

const paginatedTableSwaps = computed(() => {
  const start = (tableCurrentPage.value - 1) * tablePerPage.value;
  return filteredTableSwaps.value.slice(start, start + tablePerPage.value);
});
</script>

<template>
  <div class="shift-swaps-page">
    <!-- Breadcrumb Standard -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ─── UNIFIED TOP SECTION CARD (Figma Node 6328:117889 "personal details") ─── -->
    <div class="swaps-top-card">
      <!-- Row 1: Header Row with Title, Subtitle, and + Create Shift Swaps Button -->
      <div class="swaps-header-row">
        <div class="header-text-block">
          <h2 class="page-title">Shift Swaps</h2>
          <p class="page-subtitle">
            Supervisor View: Authorize peer-to-peer shift swaps, claim coverage, and audit roster adjustments.
          </p>
        </div>

        <AppButton 
          variant="primary" 
          @click="router.push('/hr/shift-swaps/create')"
        >
          <template #icon-left><Plus :size="16" /></template>
          Create Shift Swaps
        </AppButton>
      </div>

      <!-- Row 2: 4 Metric Cards in a single row (Figma Node 6328:117898) -->
      <div class="metrics-row">
        <!-- Metric 1: Total Requests -->
        <div class="metric-card-item">
          <span class="metric-label">TOTAL REQUESTS</span>
          <span class="metric-value">{{ stats.total }}</span>
          <span class="metric-subtext">Current Scheduling Cycle</span>
        </div>

        <!-- Metric 2: Pending Approval -->
        <div class="metric-card-item">
          <span class="metric-label">PENDING APPROVAL</span>
          <span class="metric-value">{{ stats.pendingApproval }}</span>
          <span class="metric-subtext">Awaiting Supervisor Authorization</span>
        </div>

        <!-- Metric 3: Open Giveaways -->
        <div class="metric-card-item">
          <span class="metric-label">OPEN GIVEAWAYS</span>
          <span class="metric-value">{{ stats.openGiveaways }}</span>
          <span class="metric-subtext">Available for Peer Cover Claim</span>
        </div>

        <!-- Metric 4: Approved this Month -->
        <div class="metric-card-item">
          <span class="metric-label">APPROVED THIS MONTH</span>
          <span class="metric-value">{{ stats.approved }}</span>
          <span class="metric-subtext">Roster Assignment Updated</span>
        </div>
      </div>

      <!-- Row 3: Primary Tab Group (Figma Node 5603:2799 / BaseTabs Capsule) -->
      <div class="swaps-primary-tabs-row">
        <BaseTabs
          v-model="viewMode"
          :tabs="swapTabs"
          type="rounded"
          size="sm"
          class="swaps-primary-tabs"
        />
      </div>
    </div>

    <!-- ─── 1. CARD VIEW (Figma Node 6328:117880 Stack of 3 Cards) ─── -->
    <div v-if="viewMode === 'cards'" class="swaps-cards-stack">
      <!-- ─── CARD 1: SWP-2026-003 with Light Blue Prompt Banner (Figma Node 6328:117928) ─── -->
      <div class="swap-card">
        <!-- Top bar: Code, Date & Status Badge -->
        <div class="swap-card-header">
          <div class="swap-header-left">
            <span class="swap-card-code">{{ swaps[0].code }}</span>
            <span class="swap-card-date">Submitted on Jul 22, 2026</span>
          </div>

          <div class="badge-awaiting-consent">
            <Clock :size="12" />
            <span>Awaiting Peer Consent</span>
          </div>
        </div>

        <!-- Blue Prompt Banner (Figma Node 6328:117934 & 6328:117935) -->
        <div v-if="swaps[0].show_consent_banner && swaps[0].swap_state === 'requested'" class="banner-wrapper">
          <div class="banner-prompt-box">
            <div class="banner-top">
              <Info :size="20" class="banner-info-icon" />
              <div class="banner-text-col">
                <h4 class="banner-title">Shift Swaps Requst</h4>
                <p class="banner-desc">
                  {{ swaps[0].requester_name }} the {{ swaps[0].requester_role }} would like to swap shift with you {{ swaps[0].counterpart_name }} the {{ swaps[0].counterpart_role }} So If you think this swap is appropriate and you would like to accept the offer you can click accept the offer if not you can reject the swap request.
                </p>
              </div>
            </div>
            <div class="banner-actions">
              <button 
                type="button" 
                class="btn-banner-accept"
                @click="handleBannerAccept(swaps[0])"
              >
                <Check :size="16" />
                <span>Accept the Swap</span>
              </button>
              <button 
                type="button" 
                class="btn-banner-reject"
                @click="handleBannerReject(swaps[0])"
              >
                <X :size="16" />
                <span>Reject the Swap</span>
              </button>
            </div>
          </div>
        </div>

        <!-- Exchange Parties Grid (Figma Node 6328:117951) -->
        <div class="exchange-row">
          <!-- Requester Party Card -->
          <div class="party-card">
            <div class="party-top">
              <div class="party-avatar-circle">
                <span>{{ swaps[0].requester_avatar }}</span>
              </div>
              <div class="party-meta">
                <span class="party-title">{{ swaps[0].requester_name }}</span>
                <span class="party-subtitle">{{ swaps[0].requester_role }}</span>
              </div>
            </div>
            <div class="party-divider">
              <span class="party-shift-label">Offering Shift</span>
              <span class="party-shift-val">{{ swaps[0].requester_shift_name }} : {{ swaps[0].requester_date }} ({{ swaps[0].requester_shift_time }})</span>
            </div>
          </div>

          <!-- Circular Exchange Button -->
          <div class="exchange-btn-circle" title="Shift Exchange">
            <ArrowLeftRight :size="18" />
          </div>

          <!-- Counterpart Party Card -->
          <div class="party-card">
            <div class="party-top">
              <div class="party-avatar-circle">
                <span>{{ swaps[0].counterpart_avatar }}</span>
              </div>
              <div class="party-meta">
                <span class="party-title">{{ swaps[0].counterpart_name }}</span>
                <span class="party-subtitle">{{ swaps[0].counterpart_role }}</span>
              </div>
            </div>
            <div class="party-divider">
              <span class="party-shift-label">Receiving in Exchange</span>
              <span class="party-shift-val">{{ swaps[0].counterpart_shift_name }} : {{ swaps[0].counterpart_date }} ({{ swaps[0].counterpart_shift_time }})</span>
            </div>
          </div>
        </div>

        <!-- Reason for Swap Container (Figma Node 6328:117977) -->
        <div class="reason-container">
          <span class="reason-label">Reason for Swap</span>
          <div class="reason-input-box">
            <span>"{{ swaps[0].reason }}"</span>
          </div>
          <span class="reason-status-hint">
            Awaiting Counterparty Acceptance Before Supervisory Authorization.
          </span>
        </div>
      </div>

      <!-- ─── CARD 2: SWP-2026-003 with Counterpart Accepted & Approve/Reject (Figma Node 6328:117982) ─── -->
      <div class="swap-card">
        <!-- Top bar: Code, Date & Status Badge -->
        <div class="swap-card-header">
          <div class="swap-header-left">
            <span class="swap-card-code">{{ swaps[1].code }}</span>
            <span class="swap-card-date">Submitted on Jul 22, 2026</span>
          </div>

          <div class="badge-counterpart-accepted">
            <Clock :size="12" />
            <span>Counterpart Accepted</span>
          </div>
        </div>

        <!-- Exchange Parties Grid (Figma Node 6328:117988) -->
        <div class="exchange-row">
          <!-- Requester Party Card -->
          <div class="party-card">
            <div class="party-top">
              <div class="party-avatar-circle">
                <span>{{ swaps[1].requester_avatar }}</span>
              </div>
              <div class="party-meta">
                <span class="party-title">{{ swaps[1].requester_name }}</span>
                <span class="party-subtitle">{{ swaps[1].requester_role }}</span>
              </div>
            </div>
            <div class="party-divider">
              <span class="party-shift-label">Offering Shift</span>
              <span class="party-shift-val">{{ swaps[1].requester_shift_name }} : {{ swaps[1].requester_date }} ({{ swaps[1].requester_shift_time }})</span>
            </div>
          </div>

          <!-- Circular Exchange Button -->
          <div class="exchange-btn-circle" title="Shift Exchange">
            <ArrowLeftRight :size="18" />
          </div>

          <!-- Counterpart Party Card -->
          <div class="party-card">
            <div class="party-top">
              <div class="party-avatar-circle">
                <span>{{ swaps[1].counterpart_avatar }}</span>
              </div>
              <div class="party-meta">
                <span class="party-title">{{ swaps[1].counterpart_name }}</span>
                <span class="party-subtitle">{{ swaps[1].counterpart_role }}</span>
              </div>
            </div>
            <div class="party-divider">
              <span class="party-shift-label">Receiving in Exchange</span>
              <span class="party-shift-val">{{ swaps[1].counterpart_shift_name }} : {{ swaps[1].counterpart_date }} ({{ swaps[1].counterpart_shift_time }})</span>
            </div>
          </div>
        </div>

        <!-- Reason for Swap Container (Figma Node 6328:118014) -->
        <div class="reason-container">
          <span class="reason-label">Reason for swap</span>
          <div class="reason-input-box">
            <span>"{{ swaps[1].reason }}"</span>
          </div>
          <span class="reason-status-hint">
            Awaiting Counterparty Acceptance Before Supervisory Authorization.
          </span>
        </div>

        <!-- Action Buttons: Reject & Approve Swap at bottom-right (Figma Node 6328:118019) -->
        <div v-if="swaps[1].swap_state === 'accepted'" class="card-footer-actions">
          <button 
            type="button" 
            class="btn-action-reject"
            @click="handleReject(swaps[1])"
          >
            <X :size="16" />
            <span>Reject</span>
          </button>

          <button 
            type="button" 
            class="btn-action-approve"
            @click="handleApprove(swaps[1])"
          >
            <Check :size="16" />
            <span>Approve Swap</span>
          </button>
        </div>
      </div>

      <!-- ─── CARD 3: SWP-2026-003 Open Giveaway with Claim Button (Figma Node 6328:118022) ─── -->
      <div class="swap-card">
        <!-- Top bar: Code, Date & Status Badge -->
        <div class="swap-card-header">
          <div class="swap-header-left">
            <span class="swap-card-code">{{ swaps[2].code }}</span>
            <span class="swap-card-date">Submitted on Jul 22, 2026</span>
          </div>

          <div class="badge-awaiting-consent">
            <Clock :size="12" />
            <span>Awaiting Peer Consent</span>
          </div>
        </div>

        <!-- Exchange Parties Grid (Figma Node 6328:118028) -->
        <div class="exchange-row">
          <!-- Requester Party Card -->
          <div class="party-card">
            <div class="party-top">
              <div class="party-avatar-circle">
                <span>{{ swaps[2].requester_avatar }}</span>
              </div>
              <div class="party-meta">
                <span class="party-title">{{ swaps[2].requester_name }}</span>
                <span class="party-subtitle">{{ swaps[2].requester_role }}</span>
              </div>
            </div>
            <div class="party-divider">
              <span class="party-shift-label">Offering Shift</span>
              <span class="party-shift-val">{{ swaps[2].requester_shift_name }} : {{ swaps[2].requester_date }} ({{ swaps[2].requester_shift_time }})</span>
            </div>
          </div>

          <!-- Circular Exchange Button -->
          <div class="exchange-btn-circle" title="Shift Exchange">
            <ArrowLeftRight :size="18" />
          </div>

          <!-- Counterpart Party Card (Open Giveaway) -->
          <div class="party-card">
            <div class="open-giveaway-top-row">
              <div class="party-top">
                <div class="party-avatar-circle open">
                  <span>?</span>
                </div>
                <div class="party-meta">
                  <span class="party-title">Open Giveaway</span>
                  <span class="party-subtitle">Any qualified department peer may claim</span>
                </div>
              </div>

              <!-- Blue Claim Button on top right (Figma Node 6328:118052) -->
              <button 
                type="button" 
                class="btn-card-claim"
                @click="handleClaim(swaps[2])"
              >
                <Hand :size="15" />
                <span>Claim</span>
              </button>
            </div>

            <div class="party-divider">
              <span class="party-shift-label">One Way Shift Cover</span>
              <span class="party-shift-val">No Reciprocal Slot Required</span>
            </div>
          </div>
        </div>

        <!-- Reason for Swap Container (Figma Node 6328:118057) -->
        <div class="reason-container">
          <span class="reason-label">Reason for swap</span>
          <div class="reason-input-box">
            <span>"{{ swaps[2].reason }}"</span>
          </div>
          <span class="reason-status-hint">
            Awaiting Counterparty Acceptance Before Supervisory Authorization.
          </span>
        </div>
      </div>
    </div>

    <!-- ─── 2. TABLE VIEW (Authorized AppDataTable Standard with BasePagination) ─── -->
    <div v-else-if="viewMode === 'table'" class="swaps-table-view-card">
      <AppDataTable
        title="Shift Swaps Directory"
        subtitle="Tabular directory of shift swap requests, consent status, and supervisory approvals."
        v-model:searchQuery="tableSearchQuery"
        searchPlaceholder="Search by Employee or Code..."
        :columns="tableColumns"
        :totalEntries="filteredTableSwaps.length"
        v-model:currentPage="tableCurrentPage"
        v-model:perPage="tablePerPage"
        :showPagination="true"
        :showFilter="true"
        :filterCount="tableStatusFilter !== 'all' ? 1 : 0"
        :showSort="false"
        :showColumns="true"
        :showFullscreen="true"
        @toggleColumn="handleToggleColumn"
      >
        <template #actions>
          <AppButton variant="primary" size="sm" @click="router.push('/hr/shift-swaps/create')">
            <template #icon-left><Plus :size="15" /></template>
            Create Shift Swaps
          </AppButton>
        </template>

        <template #filter-panel>
          <div class="swaps-filter-panel-row">
            <FormSelect
              v-model="tableStatusFilter"
              label="Filter by Status:"
              :options="[
                { value: 'all', label: 'All States' },
                { value: 'requested', label: 'Awaiting Peer Consent' },
                { value: 'accepted', label: 'Counterpart Accepted' },
                { value: 'approved', label: 'Approved' },
                { value: 'rejected', label: 'Rejected' }
              ]"
              placeholder="Select Status"
            />
          </div>
        </template>

        <template #default>
          <table class="erp-table">
            <thead>
              <tr>
                <th v-if="isColVisible('code')">Swap Code</th>
                <th v-if="isColVisible('requester')">Requesting Employee &amp; Shift</th>
                <th v-if="isColVisible('type')">Type</th>
                <th v-if="isColVisible('counterpart')">Counterpart Colleague &amp; Shift</th>
                <th v-if="isColVisible('status')">Status</th>
                <th v-if="isColVisible('submitted')">Submitted</th>
                <th v-if="isColVisible('actions')" class="th-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="swap in paginatedTableSwaps" :key="swap.id">
                <td v-if="isColVisible('code')" class="code-cell">
                  <span class="swap-code-link font-semibold">{{ swap.code }}</span>
                </td>
                <td v-if="isColVisible('requester')">
                  <div class="table-user-cell">
                    <div class="table-avatar">{{ swap.requester_avatar }}</div>
                    <div class="table-user-info">
                      <span class="user-name">{{ swap.requester_name }}</span>
                      <span class="user-sub">{{ swap.requester_shift_name }} ({{ swap.requester_date }})</span>
                    </div>
                  </div>
                </td>
                <td v-if="isColVisible('type')">
                  <span class="type-pill" :class="{ 'is-open': swap.is_open_giveaway }">
                    {{ swap.is_open_giveaway ? 'Open Giveaway' : 'Peer Exchange' }}
                  </span>
                </td>
                <td v-if="isColVisible('counterpart')">
                  <div v-if="swap.is_open_giveaway" class="table-user-cell open">
                    <div class="table-avatar open">?</div>
                    <div class="table-user-info">
                      <span class="user-name open-title">Open Giveaway</span>
                      <span class="user-sub">Any qualified peer may claim</span>
                    </div>
                  </div>
                  <div v-else class="table-user-cell">
                    <div class="table-avatar counterpart">{{ swap.counterpart_avatar }}</div>
                    <div class="table-user-info">
                      <span class="user-name">{{ swap.counterpart_name }}</span>
                      <span class="user-sub">{{ swap.counterpart_shift_name }} ({{ swap.counterpart_date }})</span>
                    </div>
                  </div>
                </td>
                <td v-if="isColVisible('status')">
                  <BaseBadge :color="getSwapStatusColor(swap.swap_state)">
                    {{ getSwapStatusLabel(swap.swap_state) }}
                  </BaseBadge>
                </td>
                <td v-if="isColVisible('submitted')" class="date-cell">
                  {{ new Date(swap.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) }}
                </td>
                <td v-if="isColVisible('actions')" class="th-actions" @click.stop>
                  <div class="action-dropdown-wrapper">
                    <button
                      type="button"
                      class="btn-action-dots"
                      title="Actions"
                      @click="activeActionMenuId = activeActionMenuId === swap.id ? null : swap.id"
                    >
                      <MoreVertical :size="15" />
                    </button>

                    <div v-if="activeActionMenuId === swap.id" class="action-popup-menu">
                      <template v-if="swap.swap_state === 'accepted'">
                        <button type="button" class="popup-item item-approve" @click="handleApprove(swap); activeActionMenuId = null;">
                          <Check :size="13" />
                          <span>Approve Swap</span>
                        </button>
                        <button type="button" class="popup-item item-reject" @click="handleReject(swap); activeActionMenuId = null;">
                          <X :size="13" />
                          <span>Reject Swap</span>
                        </button>
                      </template>
                      <button 
                        v-else-if="swap.is_open_giveaway && swap.swap_state === 'requested'"
                        type="button" 
                        class="popup-item"
                        @click="handleClaim(swap); activeActionMenuId = null;"
                      >
                        <Hand :size="13" />
                        <span>Claim Coverage</span>
                      </button>
                      <button type="button" class="popup-item" @click="activeActionMenuId = null;">
                        <Info :size="13" />
                        <span>View Details</span>
                      </button>
                    </div>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </template>
      </AppDataTable>
    </div>

    <!-- Quick Modal Form -->
    <QuickCreateModal
      :show="showCreateModal"
      title="Request Shift Swap"
      save-label="Submit Swap Request"
      width="md"
      @save="handleCreateSubmit"
      @cancel="showCreateModal = false"
    >
      <div class="create-swap-modal-form">
        <FormSelect
          label="Counterpart Colleague"
          v-model="createForm.counterpart_id"
          :options="colleagueOptions"
          placeholder="Select colleague"
          required
        />
        <FormTextarea
          label="Reason for Swap Request"
          v-model="createForm.reason"
          placeholder="Describe why you need this shift swap..."
          :rows="3"
          required
        />
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.shift-swaps-page {
  padding: 0;
  background-color: #fafafa;
  min-height: 100vh;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
  margin-bottom: 12px;
}

/* ─── UNIFIED TOP SECTION CARD (Figma Node 6328:117889) ─── */
.swaps-top-card {
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin-bottom: 24px;
}

.swaps-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
}

.header-text-block {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.page-title {
  font-size: 16px;
  font-weight: 600;
  color: #414651;
  margin: 0;
  line-height: 24px;
}

.page-subtitle {
  font-size: 14px;
  font-weight: 400;
  color: #737373;
  margin: 0;
  line-height: 20px;
}

.btn-create-swap {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  background-color: #0B529C;
  border: 1px solid #0B529C;
  border-radius: 8px;
  color: #ffffff;
  font-size: 14px;
  font-weight: 600;
  line-height: 20px;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  cursor: pointer;
  transition: background-color 0.15s ease;
  white-space: nowrap;
}

.btn-create-swap:hover {
  background-color: #09427d;
}

/* 4 Metric Cards in a Row */
.metrics-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
  width: 100%;
}

@media (max-width: 1024px) {
  .metrics-row {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 640px) {
  .metrics-row {
    grid-template-columns: 1fr;
  }
}

.metric-card-item {
  background: #ffffff;
  border: 1px solid #e9eaeb;
  border-radius: 16px;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  justify-content: center;
}

.metric-label {
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  text-transform: uppercase;
  letter-spacing: 0.02em;
  line-height: 18px;
}

.metric-value {
  font-size: 24px;
  font-weight: 600;
  color: #404040;
  line-height: 32px;
}

.metric-subtext {
  font-size: 12px;
  font-weight: 400;
  color: #737373;
  line-height: 18px;
}

/* Secondary Tab Group (Figma Node 8802:107198) */
.swaps-primary-tabs-row {
  width: 100%;
  margin-top: 4px;
  display: flex;
  align-items: center;
}

/* ─── CARDS STACK ─── */
.swaps-cards-stack {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.swap-card {
  background: #ffffff;
  border: 1px solid #e9eaeb;
  border-radius: 16px;
  box-shadow: 0 1px 3px rgba(10, 13, 18, 0.1), 0 1px 2px rgba(10, 13, 18, 0.06);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  gap: 24px;
  padding-bottom: 24px;
}

.swap-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 24px;
  border-bottom: 1px solid #e5e5e5;
}

.swap-header-left {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.swap-card-code {
  font-size: 12px;
  font-weight: 600;
  color: #404040;
  line-height: 18px;
}

.swap-card-date {
  font-size: 12px;
  font-weight: 400;
  color: #737373;
  line-height: 18px;
}

/* Badges */
.badge-awaiting-consent {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  background: #fef3c6;
  color: #bb4d00;
  padding: 2px 8px;
  border-radius: 16px;
  font-size: 12px;
  font-weight: 500;
  line-height: 18px;
}

.badge-counterpart-accepted {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  background: #e1eefd;
  color: #0b529c;
  padding: 2px 8px;
  border-radius: 16px;
  font-size: 12px;
  font-weight: 500;
  line-height: 18px;
}

/* Blue Prompt Banner (Card 1, Figma Node 6328:117934 & 6328:117935) */
.banner-wrapper {
  padding: 0 24px;
  width: 100%;
}

.banner-prompt-box {
  background: #e1eefd;
  border: 1px solid #83bff6;
  border-radius: 16px;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  width: 100%;
}

.banner-top {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.banner-info-icon {
  color: #0b529c;
  flex-shrink: 0;
  margin-top: 2px;
}

.banner-text-col {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.banner-title {
  font-size: 16px;
  font-weight: 600;
  color: #0b529c;
  line-height: 24px;
  margin: 0;
}

.banner-desc {
  font-size: 12px;
  font-weight: 400;
  color: #0b529c;
  line-height: 18px;
  margin: 0;
}

.banner-actions {
  display: flex;
  align-items: center;
  gap: 12px;
  padding-left: 32px;
}

.btn-banner-accept {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  background-color: #0b529c;
  border: 1px solid #0b529c;
  border-radius: 8px;
  color: #ffffff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  transition: background-color 0.15s ease;
}

.btn-banner-accept:hover {
  background-color: #09427d;
}

.btn-banner-reject {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  background-color: #ffffff;
  border: 1px solid #d5d7da;
  border-radius: 8px;
  color: #414651;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  transition: background-color 0.15s ease;
}

.btn-banner-reject:hover {
  background-color: #f5f5f5;
}

/* Exchange Row */
.exchange-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  gap: 20px;
  padding: 0 24px;
}

@media (max-width: 900px) {
  .exchange-row {
    flex-direction: column;
    gap: 16px;
  }
}

.party-card {
  flex: 1 1 0%;
  width: 100%;
  min-width: 0;
  background: #ffffff;
  border: 1px solid #d4d4d4;
  border-radius: 16px;
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.party-top {
  display: flex;
  align-items: center;
  gap: 12px;
}

.party-avatar-circle {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  border: 1.5px solid #ffffff;
  box-shadow: 0 4px 6px -1.5px rgba(10, 13, 18, 0.08), 0 1.5px 2px -0.75px rgba(10, 13, 18, 0.03);
  background: #e1eefd;
  color: #0b529c;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 600;
  flex-shrink: 0;
}

.party-avatar-circle.open {
  background: #fafafa;
  border: 1.5px solid #e5e5e5;
  color: #737373;
}

.party-meta {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.party-title {
  font-size: 14px;
  font-weight: 600;
  color: #414651;
  line-height: 20px;
}

.party-subtitle {
  font-size: 12px;
  font-weight: 400;
  color: #737373;
  line-height: 18px;
}

.party-divider {
  border-top: 1px solid #e5e5e5;
  padding: 6px 0;
  display: flex;
  flex-direction: column;
}

.party-shift-label {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  line-height: 20px;
}

.party-shift-val {
  font-size: 12px;
  font-weight: 400;
  color: #737373;
  line-height: 18px;
}

.exchange-btn-circle {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #ffffff;
  border: 1px solid #d5d7da;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #414651;
  flex-shrink: 0;
}

.open-giveaway-top-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  width: 100%;
}

.btn-card-claim {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  background-color: #0b529c;
  border: 1px solid #0b529c;
  border-radius: 8px;
  color: #ffffff;
  font-size: 14px;
  font-weight: 600;
  line-height: 20px;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  transition: background-color 0.15s ease;
}

.btn-card-claim:hover {
  background-color: #09427d;
}

/* Reason Container */
.reason-container {
  padding: 0 24px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.reason-label {
  font-size: 12px;
  font-weight: 400;
  color: #737373;
  line-height: 18px;
}

.reason-input-box {
  background: #fafafa;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  height: 35px;
  padding: 0 13px;
  display: flex;
  align-items: center;
  font-size: 12px;
  color: #737373;
  line-height: 18px;
}

.reason-status-hint {
  font-size: 12px;
  font-weight: 400;
  color: #737373;
  line-height: 18px;
}

/* Card 2 Footer Action Buttons */
.card-footer-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 8px;
  padding: 0 24px;
}

.btn-action-reject {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  background-color: #e7000b;
  border: 1px solid #ffa2a2;
  border-radius: 8px;
  color: #ffffff;
  font-size: 14px;
  font-weight: 600;
  line-height: 20px;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  transition: background-color 0.15s ease;
}

.btn-action-reject:hover {
  background-color: #c9000a;
}

.btn-action-approve {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  background-color: #009966;
  border: 1px solid #5ee9b5;
  border-radius: 8px;
  color: #ffffff;
  font-size: 14px;
  font-weight: 600;
  line-height: 20px;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  transition: background-color 0.15s ease;
}

.btn-action-approve:hover {
  background-color: #008055;
}

/* ─── TABLE VIEW ─── */
.qmt-table-container {
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(10, 13, 18, 0.05);
}

.qmt-swaps-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.qmt-swaps-table th {
  background-color: #fafafa;
  color: #737373;
  font-weight: 500;
  font-size: 12px;
  text-align: left;
  padding: 12px 16px;
  border-bottom: 1px solid #e5e5e5;
}

.qmt-swaps-table td {
  padding: 14px 16px;
  border-bottom: 1px solid #f5f5f5;
  color: #404040;
  vertical-align: middle;
}

.qmt-swaps-table tr:hover td {
  background-color: #f5f5f5;
}

.table-user-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.table-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background-color: #f5f5f5;
  border: 1px solid #e5e5e5;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 600;
  color: #404040;
  flex-shrink: 0;
}

.table-avatar.open {
  background-color: #fafafa;
  color: #737373;
}

.table-avatar.counterpart {
  background-color: #e1eefd;
  color: #0b529c;
}

.table-user-info {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.table-user-info .user-name {
  font-weight: 600;
  font-size: 13px;
  color: #404040;
}

.table-user-info .user-sub {
  font-size: 12px;
  color: #737373;
}

.type-pill {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11.5px;
  font-weight: 500;
  background-color: #f5f5f5;
  color: #404040;
}

.type-pill.is-open {
  background-color: #e1eefd;
  color: #0b529c;
}

.swap-code-link {
  font-weight: 600;
  color: #404040;
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
  border: none;
  background: transparent;
  border-radius: 6px;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.action-popup-menu {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  min-width: 150px;
  padding: 4px;
  z-index: 50;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.popup-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 12px;
  font-size: 13px;
  color: #404040;
  background: transparent;
  border: none;
  border-radius: 6px;
  text-align: left;
  cursor: pointer;
  transition: background 0.15s;
}

.popup-item:hover {
  background-color: #f8fafc;
}

.popup-item.item-approve {
  color: #009966;
}

.popup-item.item-approve:hover {
  background-color: #ecfdf5;
}

.popup-item.item-reject {
  color: #e7000b;
}

.popup-item.item-reject:hover {
  background-color: #fef2f2;
}

.btn-table-claim {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  border-radius: 6px;
  background-color: #0b529c;
  color: #ffffff;
  border: none;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
}

.table-audit-state {
  font-size: 12px;
  color: #737373;
}

.create-swap-modal-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.swaps-filter-panel-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 0;
}

.swaps-table-view-card :deep(.erp-table) {
  width: 100%;
  border-collapse: collapse;
}

.swaps-table-view-card :deep(.erp-table th) {
  background-color: #FAFAFA;
  color: #737373;
  font-size: 12px;
  font-weight: 600;
  padding: 12px 16px;
  text-align: left;
  border-bottom: 1px solid #E5E5E5;
}

.swaps-table-view-card :deep(.erp-table td) {
  padding: 12px 16px;
  border-bottom: 1px solid #F0F0F0;
  vertical-align: middle;
}

.swaps-table-view-card :deep(.erp-table tr:hover td) {
  background-color: #F9FAFB;
}
</style>
