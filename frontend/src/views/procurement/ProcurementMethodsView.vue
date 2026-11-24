<!--
  ══════════════════════════════════════════════════════════════════════════════
  HALETA ERP ARCHITECTURAL SPECIFICATION — DIRECTORY & VIEW STANDARD:
  1. SCHEMA FIDELITY & NAMING: Entity is PurchaseMethod. Page title is strictly "Purchase Methods".
     Threshold child lines are "Threshold Bands". Never use ad-hoc jargon like "Spend Threshold Bands".
  2. BREADCRUMB ONLY NAVIGATION: Zero back buttons. Exact page name only on top level:
     [{ label: 'Purchase Methods' }]. Expands to [{ label: 'Purchase Methods', to: '...' }, { label: item.name }]
     when inspecting. Breadcrumbs sit directly on canvas with zero card containers.
  3. ZERO FLOATING ACTION BUTTONS: View/inspect details MUST present a clean dossier card directly
     below the breadcrumb. Never float Edit or Deactivate buttons above detail view cards.
  4. 3-DOT ACTIONS ONLY: Standard MoreVertical kebab menu popover for all table rows.
  ══════════════════════════════════════════════════════════════════════════════
-->
<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { formatDisplayDate } from '../../utils/dateFormat';
import { useRouter } from 'vue-router';
import {
  Plus, ArrowUpDown, MoreVertical, Eye, Edit2, Check, Trash2,
  Scale, Layers
} from 'lucide-vue-next';
import { useToast } from '../../composables/useToast';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef, type SortOption } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import BaseBadge, { type BadgeColor } from '../../components/BaseBadge.vue';
import {
  purchaseMethodsStore,
  thresholdBandsStore,
  type PurchaseMethodRecord,
  type PurchaseMethodThresholdRecord,
  type GovernanceStatus,
  categoryOptions,
  unitOptions,
  governanceStatusOptions,
  formatCurrency,
  getGovernanceStatusLabel,
  generateMethodCode
} from './procurementMethodData';

const router = useRouter();
const { toast } = useToast();

const getGovernanceBadgeColor = (status: GovernanceStatus): BadgeColor => {
  if (status === 'acceptForAll') return 'success';
  if (status === 'acceptForThis') return 'primary';
  if (status === 'pending') return 'warning';
  if (status === 'reject') return 'error';
  return 'gray';
};

const getEnforcementBadgeColor = (isMandatory: boolean): BadgeColor => {
  return isMandatory ? 'indigo' : 'blue';
};

// ─── View & Selection State ───
const searchQuery = ref('');
const filterQuotations = ref('');
const filterCommittee = ref('');
const filterSealedBid = ref('');
const filterInvitation = ref('');
const filterStatus = ref('');
const filterState = ref('');
const currentSort = ref('name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const currentPage = ref(1);
const perPage = ref(10);

const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const inspectingMethod = ref<PurchaseMethodRecord | null>(null);

// ─── Modal State: Purchase Method ───
const showMethodModal = ref(false);
const editingMethodId = ref<number | null>(null);
const methodFormErrors = ref<{ code?: string; name?: string }>({});
const methodForm = ref({
  code: '',
  name: '',
  description: '',
  minimum_quotations: 3,
  requires_committee: false,
  requires_sealed_bid: false,
  requires_post_facto_approval: false,
  allows_single_source: false,
  is_open_invitation: false
});

// ─── Modal State: Threshold Band ───
const showBandModal = ref(false);
const editingBandId = ref<number | null>(null);
const bandFormErrors = ref<{ minimum_amount?: string; maximum_amount?: string; dates?: string }>({});
const bandForm = ref({
  minimum_amount: 0,
  maximum_amount: 50000 as number | null,
  noLimit: false,
  is_mandatory: true,
  procurement_category_id: '',
  procurement_unit_id: '',
  effective_from: new Date().toISOString().split('T')[0],
  effective_to: ''
});

// ─── Toast Feedback Helper ───
const showLocalToast = (msg: string, variant: 'success' | 'error' = 'success') => {
  if (variant === 'error') {
    toast.error('Purchase Methods', msg);
  } else {
    toast.success('Purchase Methods', msg);
  }
};

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3) ───
const breadcrumbItems = computed<BreadcrumbItem[]>(() => {
  if (inspectingMethod.value) {
    return [
      {
        label: 'Purchase Methods',
        to: '/procurement/methods',
        onClick: () => {
          inspectingMethod.value = null;
        }
      },
      { label: inspectingMethod.value.name }
    ];
  }
  return [{ label: 'Purchase Methods' }];
});

// ─── Atomic Columns & Column Hider (AGENTS.md Table Architecture) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Purchase Method', visible: true, sortable: true, hideable: false },
  { key: 'minimum_quotations', label: 'Quotation Rule', visible: true, sortable: true },
  { key: 'requires_committee', label: 'Committee Mandate', visible: true, sortable: true },
  { key: 'requires_sealed_bid', label: 'Sealed Bids', visible: false, sortable: true },
  { key: 'is_open_invitation', label: 'Invitation Scope', visible: true, sortable: true },
  { key: 'allows_single_source', label: 'Single Source', visible: false, sortable: true },
  { key: 'requires_post_facto_approval', label: 'Emergency Ratification', visible: false, sortable: true },
  { key: 'threshold_bands', label: 'Configured Bands', visible: true, sortable: false },
  { key: 'status', label: 'Status', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

const sortOptions: SortOption[] = [
  { key: 'name', label: 'Method Name (A-Z)' },
  { key: 'minimum_quotations', label: 'Quotation Rule' },
  { key: 'requires_committee', label: 'Committee Mandate' },
  { key: 'status', label: 'Status' },
  { key: 'state', label: 'State' }
];

const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find((c) => c.key === key);
  return col ? col.visible !== false : true;
};

const visibleColumnCount = computed(
  () => tableColumns.value.filter((column) => column.visible !== false).length
);

const handleToggleColumn = (key: string) => {
  const col = tableColumns.value.find((c) => c.key === key);
  if (col) {
    col.visible = col.visible === false;
  }
};

// ─── Threshold Bands Association Helpers ───
const getMethodBands = (methodId: number): PurchaseMethodThresholdRecord[] => {
  return thresholdBandsStore.value.filter((b) => b.purchase_method_id === methodId);
};

const getMethodBandsCount = (methodId: number): number => {
  return thresholdBandsStore.value.filter((b) => b.purchase_method_id === methodId).length;
};

// ─── Filter & Sorting Logic ───
const activeFilterCount = computed(() => {
  let count = 0;
  if (filterQuotations.value) count++;
  if (filterCommittee.value) count++;
  if (filterSealedBid.value) count++;
  if (filterInvitation.value) count++;
  if (filterStatus.value) count++;
  if (filterState.value) count++;
  return count;
});

const resetFilters = () => {
  filterQuotations.value = '';
  filterCommittee.value = '';
  filterSealedBid.value = '';
  filterInvitation.value = '';
  filterStatus.value = '';
  filterState.value = '';
  currentPage.value = 1;
};

watch(
  [searchQuery, filterQuotations, filterCommittee, filterSealedBid, filterInvitation, filterStatus, filterState],
  () => {
    currentPage.value = 1;
  }
);

const filteredMethods = computed(() => {
  let list = [...purchaseMethodsStore.value];

  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase().trim();
    list = list.filter((m) =>
      m.name.toLowerCase().includes(q) ||
      m.code.toLowerCase().includes(q) ||
      (m.description && m.description.toLowerCase().includes(q))
    );
  }

  if (filterQuotations.value === 'zero') {
    list = list.filter((m) => m.minimum_quotations === 0);
  } else if (filterQuotations.value === 'competitive') {
    list = list.filter((m) => m.minimum_quotations > 0);
  }

  if (filterCommittee.value === 'yes') {
    list = list.filter((m) => m.requires_committee);
  } else if (filterCommittee.value === 'no') {
    list = list.filter((m) => !m.requires_committee);
  }

  if (filterSealedBid.value === 'yes') {
    list = list.filter((m) => m.requires_sealed_bid);
  } else if (filterSealedBid.value === 'no') {
    list = list.filter((m) => !m.requires_sealed_bid);
  }

  if (filterInvitation.value === 'open') {
    list = list.filter((m) => m.is_open_invitation);
  } else if (filterInvitation.value === 'invited') {
    list = list.filter((m) => !m.is_open_invitation);
  }

  if (filterStatus.value) {
    list = list.filter((m) => m.status === filterStatus.value);
  }

  if (filterState.value) {
    list = list.filter((m) => m.state === filterState.value);
  }

  list.sort((a, b) => {
    let cmp = 0;
    if (currentSort.value === 'name') {
      cmp = a.name.localeCompare(b.name);
    } else if (currentSort.value === 'minimum_quotations') {
      cmp = a.minimum_quotations - b.minimum_quotations;
    } else if (currentSort.value === 'requires_committee') {
      cmp = (b.requires_committee ? 1 : 0) - (a.requires_committee ? 1 : 0);
    } else if (currentSort.value === 'status') {
      cmp = a.status.localeCompare(b.status);
    } else if (currentSort.value === 'state') {
      cmp = a.state.localeCompare(b.state);
    }
    return sortOrder.value === 'asc' ? cmp : -cmp;
  });

  return list;
});

const paginatedMethods = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredMethods.value.slice(start, start + perPage.value);
});

watch(
  [() => filteredMethods.value.length, perPage],
  ([total, pageSize]) => {
    currentPage.value = Math.min(
      currentPage.value,
      Math.max(1, Math.ceil(total / pageSize))
    );
  }
);

// ─── Selection Management (Lead Column Integration) ───
const isAllSelected = computed(() => {
  if (paginatedMethods.value.length === 0) return false;
  return paginatedMethods.value.every((m) => selectedRowIds.value.includes(m.id));
});

const isPartiallySelected = computed(() => {
  return (
    paginatedMethods.value.some((m) => selectedRowIds.value.includes(m.id)) &&
    !isAllSelected.value
  );
});

const toggleSelectAll = (checked: boolean) => {
  const pageIds = new Set(paginatedMethods.value.map((m) => m.id));
  if (checked) {
    selectedRowIds.value = [...new Set([...selectedRowIds.value, ...pageIds])];
  } else {
    selectedRowIds.value = selectedRowIds.value.filter((id) => !pageIds.has(id));
  }
};

const toggleSelectRow = (id: number, checked: boolean) => {
  if (checked) {
    if (!selectedRowIds.value.includes(id)) {
      selectedRowIds.value.push(id);
    }
  } else {
    selectedRowIds.value = selectedRowIds.value.filter((i) => i !== id);
  }
};

const handleSortColumn = (key: string) => {
  if (currentSort.value === key) {
    sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
  } else {
    currentSort.value = key;
    sortOrder.value = 'asc';
  }
};

// ─── Modal Actions: Purchase Method ───
const openCreateModal = () => {
  editingMethodId.value = null;
  methodFormErrors.value = {};
  methodForm.value = {
    code: '',
    name: '',
    description: '',
    minimum_quotations: 3,
    requires_committee: false,
    requires_sealed_bid: false,
    requires_post_facto_approval: false,
    allows_single_source: false,
    is_open_invitation: false
  };
  showMethodModal.value = true;
};

const handleExpandFullForm = () => {
  showMethodModal.value = false;
  router.push({
    path: '/procurement/methods/create',
    query: {
      name: methodForm.value.name || undefined,
      minimum_quotations: String(methodForm.value.minimum_quotations || 3),
      requires_committee: methodForm.value.requires_committee ? '1' : undefined,
      requires_sealed_bid: methodForm.value.requires_sealed_bid ? '1' : undefined,
      is_open_invitation: methodForm.value.is_open_invitation ? '1' : undefined,
      allows_single_source: methodForm.value.allows_single_source ? '1' : undefined,
      requires_post_facto_approval: methodForm.value.requires_post_facto_approval ? '1' : undefined
    }
  });
};

const openEditModal = (item: PurchaseMethodRecord) => {
  editingMethodId.value = item.id;
  methodFormErrors.value = {};
  methodForm.value = {
    code: item.code,
    name: item.name,
    description: item.description || '',
    minimum_quotations: item.minimum_quotations,
    requires_committee: item.requires_committee,
    requires_sealed_bid: item.requires_sealed_bid,
    requires_post_facto_approval: item.requires_post_facto_approval,
    allows_single_source: item.allows_single_source,
    is_open_invitation: item.is_open_invitation
  };
  showMethodModal.value = true;
};

const handleSaveMethod = () => {
  const errors: typeof methodFormErrors.value = {};
  if (!methodForm.value.name.trim()) errors.name = 'Method Name is required.';
  methodFormErrors.value = errors;

  if (Object.keys(errors).length > 0) {
    toast.error('Please fill in required fields', 'Method Name is mandatory.');
    return;
  }

  if (editingMethodId.value) {
    const idx = purchaseMethodsStore.value.findIndex((m) => m.id === editingMethodId.value);
    if (idx !== -1) {
      const existing = purchaseMethodsStore.value[idx];
      purchaseMethodsStore.value[idx] = {
        ...existing,
        name: methodForm.value.name.trim(),
        minimum_quotations: Number(methodForm.value.minimum_quotations),
        requires_committee: methodForm.value.requires_committee,
        requires_sealed_bid: methodForm.value.requires_sealed_bid,
        requires_post_facto_approval: methodForm.value.requires_post_facto_approval,
        allows_single_source: methodForm.value.allows_single_source,
        is_open_invitation: methodForm.value.is_open_invitation
      };
      if (inspectingMethod.value?.id === existing.id) {
        inspectingMethod.value = purchaseMethodsStore.value[idx];
      }
      showLocalToast(`Updated "${methodForm.value.name.trim()}".`);
    }
  } else {
    const existingCodes = purchaseMethodsStore.value.map((m) => m.code);
    const nextId = Math.max(0, ...purchaseMethodsStore.value.map((m) => m.id)) + 1;
    const generatedCode = generateMethodCode(methodForm.value.name.trim(), existingCodes);
    const newMethod: PurchaseMethodRecord = {
      id: nextId,
      uuid: `pm-uuid-${nextId}`,
      code: generatedCode,
      name: methodForm.value.name.trim(),
      description: '',
      minimum_quotations: Number(methodForm.value.minimum_quotations),
      requires_committee: methodForm.value.requires_committee,
      requires_sealed_bid: methodForm.value.requires_sealed_bid,
      requires_post_facto_approval: methodForm.value.requires_post_facto_approval,
      allows_single_source: methodForm.value.allows_single_source,
      is_open_invitation: methodForm.value.is_open_invitation,
      entity_id: 2,
      status: 'acceptForAll',
      state: 'active'
    };
    purchaseMethodsStore.value.unshift(newMethod);
    showLocalToast(`Created purchase method "${methodForm.value.name.trim()}".`);
  }

  showMethodModal.value = false;
};

// ─── Modal Actions: Threshold Band ───
const openAddBandModal = () => {
  editingBandId.value = null;
  bandFormErrors.value = {};
  bandForm.value = {
    minimum_amount: 0,
    maximum_amount: 50000,
    noLimit: false,
    is_mandatory: true,
    procurement_category_id: '',
    procurement_unit_id: '',
    effective_from: new Date().toISOString().split('T')[0],
    effective_to: ''
  };
  showBandModal.value = true;
};

const openEditBandModal = (band: PurchaseMethodThresholdRecord) => {
  editingBandId.value = band.id;
  bandFormErrors.value = {};
  bandForm.value = {
    minimum_amount: band.minimum_amount,
    maximum_amount: band.maximum_amount,
    noLimit: band.maximum_amount === null,
    is_mandatory: band.is_mandatory,
    procurement_category_id: band.procurement_category_id ? String(band.procurement_category_id) : '',
    procurement_unit_id: band.procurement_unit_id ? String(band.procurement_unit_id) : '',
    effective_from: band.effective_from,
    effective_to: band.effective_to || ''
  };
  showBandModal.value = true;
};

const handleSaveBand = () => {
  if (!inspectingMethod.value) return;

  const minAmt = Number(bandForm.value.minimum_amount);
  const maxAmt = bandForm.value.noLimit ? null : Number(bandForm.value.maximum_amount);

  if (maxAmt !== null && maxAmt <= minAmt) {
    toast.error('Invalid Amount Range', 'Maximum ceiling must be strictly greater than minimum floor.');
    return;
  }

  const category = categoryOptions.find((c) => c.value === bandForm.value.procurement_category_id);
  const unit = unitOptions.find((u) => u.value === bandForm.value.procurement_unit_id);

  if (editingBandId.value) {
    const idx = thresholdBandsStore.value.findIndex((b) => b.id === editingBandId.value);
    if (idx !== -1) {
      thresholdBandsStore.value[idx] = {
        ...thresholdBandsStore.value[idx],
        minimum_amount: minAmt,
        maximum_amount: maxAmt,
        is_mandatory: bandForm.value.is_mandatory,
        procurement_category_id: bandForm.value.procurement_category_id ? Number(bandForm.value.procurement_category_id) : null,
        category_name: category ? category.label.split(' (')[0] : 'All Categories',
        procurement_unit_id: bandForm.value.procurement_unit_id ? Number(bandForm.value.procurement_unit_id) : null,
        unit_name: unit ? unit.label.split(' (')[0] : 'All Buying Desks',
        effective_from: bandForm.value.effective_from,
        effective_to: bandForm.value.effective_to || null
      };
      showLocalToast('Updated threshold band.');
    }
  } else {
    const nextBandId = Math.max(0, ...thresholdBandsStore.value.map((b) => b.id)) + 1;
    thresholdBandsStore.value.push({
      id: nextBandId,
      uuid: `pmt-uuid-${nextBandId}`,
      purchase_method_id: inspectingMethod.value.id,
      method_name: inspectingMethod.value.name,
      method_code: inspectingMethod.value.code,
      minimum_amount: minAmt,
      maximum_amount: maxAmt,
      currency_code: 'ETB',
      is_mandatory: bandForm.value.is_mandatory,
      procurement_category_id: bandForm.value.procurement_category_id ? Number(bandForm.value.procurement_category_id) : null,
      category_name: category ? category.label.split(' (')[0] : 'All Categories',
      procurement_unit_id: bandForm.value.procurement_unit_id ? Number(bandForm.value.procurement_unit_id) : null,
      unit_name: unit ? unit.label.split(' (')[0] : 'All Buying Desks',
      effective_from: bandForm.value.effective_from,
      effective_to: bandForm.value.effective_to || null,
      entity_id: 2,
      state: 'active'
    });
    showLocalToast('Added threshold band to method.');
  }

  showBandModal.value = false;
};

const activeBandActionMenuId = ref<number | null>(null);

const toggleBandActionMenu = (id: number) => {
  activeBandActionMenuId.value = activeBandActionMenuId.value === id ? null : id;
};

const closeBandActionMenu = () => {
  activeBandActionMenuId.value = null;
};

const handleToggleBandState = (band: PurchaseMethodThresholdRecord) => {
  band.state = band.state === 'active' ? 'inactive' : 'active';
  showLocalToast(`Marked band as ${band.state === 'active' ? 'Active' : 'Inactive'}.`);
  closeBandActionMenu();
};

const handleDeleteBand = (band: PurchaseMethodThresholdRecord) => {
  thresholdBandsStore.value = thresholdBandsStore.value.filter((b) => b.id !== band.id);
  showLocalToast('Threshold band removed.');
  closeBandActionMenu();
};

// ─── Row Actions & Detail View ───
const toggleActionMenu = (id: number) => {
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
};

const openDetailView = (item: PurchaseMethodRecord) => {
  inspectingMethod.value = item;
  activeActionMenuId.value = null;
  activeBandActionMenuId.value = null;
};

const handleToggleState = (item: PurchaseMethodRecord) => {
  item.state = item.state === 'active' ? 'inactive' : 'active';
  showLocalToast(`Marked "${item.name}" as ${item.state === 'active' ? 'Active' : 'Inactive'}.`);
  closeActionMenu();
};

const handleDelete = (item: PurchaseMethodRecord) => {
  const bands = thresholdBandsStore.value.filter((b) => b.purchase_method_id === item.id);
  if (bands.length > 0) {
    showLocalToast(`Cannot delete "${item.name}" while threshold bands are configured for it.`, 'error');
    closeActionMenu();
    return;
  }
  purchaseMethodsStore.value = purchaseMethodsStore.value.filter((m) => m.id !== item.id);
  selectedRowIds.value = selectedRowIds.value.filter((i) => i !== item.id);
  if (inspectingMethod.value?.id === item.id) {
    inspectingMethod.value = null;
  }
  showLocalToast(`Deleted "${item.name}".`);
  closeActionMenu();
};

const handleBatchDelete = () => {
  const selectedSet = new Set(selectedRowIds.value);
  const blocked = purchaseMethodsStore.value.some(
    (m) => selectedSet.has(m.id) && thresholdBandsStore.value.some((b) => b.purchase_method_id === m.id)
  );
  if (blocked) {
    showLocalToast('Some selected methods have threshold bands. Remove those bands before deleting.', 'error');
    return;
  }
  purchaseMethodsStore.value = purchaseMethodsStore.value.filter((m) => !selectedSet.has(m.id));
  showLocalToast(`Deleted ${selectedRowIds.value.length} selected methods.`);
  selectedRowIds.value = [];
};

// ─── Global Click Outside Listener ───
const handleGlobalClick = (e: MouseEvent) => {
  const target = e.target as HTMLElement;
  if (!target.closest('.action-menu-container')) {
    closeActionMenu();
    closeBandActionMenu();
  }
};

onMounted(() => {
  window.addEventListener('click', handleGlobalClick);
});

onUnmounted(() => {
  window.removeEventListener('click', handleGlobalClick);
});
</script>

<template>
  <div class="purchase-methods-page">
    <!-- ═══ BREADCRUMB NAVIGATION (Rule 3: Exact Page Name Only) ═══ -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" :noMargin="true" />
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- ISOLATED DETAIL VIEW (AGENTS.md Rule 10.3 & Rule 10.5)         -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-if="inspectingMethod" class="detail-view-wrapper">
      <!-- Method Profile Summary Card -->
      <div class="detail-card">
        <div class="detail-header-row">
          <div>
            <h2 class="detail-title">{{ inspectingMethod.name }}</h2>
            <span class="detail-code">{{ inspectingMethod.code }}</span>
          </div>
          <div class="detail-badges">
            <BaseBadge size="sm" :color="getGovernanceBadgeColor(inspectingMethod.status)">
              {{ getGovernanceStatusLabel(inspectingMethod.status) }}
            </BaseBadge>
            <BaseBadge size="sm" :color="inspectingMethod.state === 'active' ? 'success' : 'gray'">
              {{ inspectingMethod.state === 'active' ? 'Active' : 'Inactive' }}
            </BaseBadge>
          </div>
        </div>

        <p class="detail-desc-text">{{ inspectingMethod.description || 'Statutory procurement method definition.' }}</p>

        <div class="detail-divider"></div>

        <div class="detail-meta-grid">
          <div class="meta-item">
            <span class="meta-label">Quotation Requirement</span>
            <span class="meta-value">{{ inspectingMethod.minimum_quotations > 0 ? `${inspectingMethod.minimum_quotations} Independent Quotes` : 'None (Off-the-shelf)' }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Tender Invitation Scope</span>
            <span class="meta-value">{{ inspectingMethod.is_open_invitation ? 'Open Public Advert' : 'Invited Shortlist' }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Evaluation Committee</span>
            <span class="meta-value">{{ inspectingMethod.requires_committee ? 'Mandatory Committee' : 'Buyer Evaluation' }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Sealed Simultaneous Bids</span>
            <span class="meta-value">{{ inspectingMethod.requires_sealed_bid ? 'Strict Sealed Bids' : 'Standard Quotation' }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Single Source Supplier</span>
            <span class="meta-value">{{ inspectingMethod.allows_single_source ? 'Allowed (Single Supplier)' : 'Prohibited (Competitive)' }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Emergency Post-Facto Ratification</span>
            <span class="meta-value">{{ inspectingMethod.requires_post_facto_approval ? 'Post-Facto Allowed' : 'Strict Pre-Approval' }}</span>
          </div>
        </div>
      </div>

      <!-- Child Lines: PurchaseMethodThreshold Sub-Table Card -->
      <div class="detail-card">
        <div class="detail-header-row">
          <div class="title-with-badge">
            <h3 class="section-title">Threshold Bands</h3>
            <span class="tertiary-plain-text">
              {{ getMethodBands(inspectingMethod.id).length }} bands
            </span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <table class="erp-table members-subtable">
          <thead>
            <tr>
              <th>Order Value Band (ETB)</th>
              <th>Enforcement Mode</th>
              <th>Category Scope</th>
              <th>Buying Desk Scope</th>
              <th>Valid From</th>
              <th>Valid To</th>
              <th>State</th>
              <th class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="getMethodBands(inspectingMethod.id).length === 0">
              <td colspan="8" class="empty-state-cell">
                <div class="empty-state-container">
                  <Scale :size="28" class="empty-state-icon" />
                  <p class="empty-state-title">No threshold bands configured for this method</p>
                  <p class="empty-state-subtext">Edit this purchase method to configure value ceilings and scopes.</p>
                </div>
              </td>
            </tr>
            <tr
              v-for="band in getMethodBands(inspectingMethod.id)"
              :key="band.id"
              class="subtable-row"
            >
              <td>
                <span class="table-name-primary">
                  {{ formatCurrency(band.minimum_amount) }} to {{ band.maximum_amount !== null ? formatCurrency(band.maximum_amount) : 'Open Ceiling (No Limit)' }}
                </span>
              </td>
              <td>
                <BaseBadge
                  size="sm"
                  :color="getEnforcementBadgeColor(band.is_mandatory)"
                >
                  {{ band.is_mandatory ? 'Mandatory' : 'Permissive' }}
                </BaseBadge>
              </td>
              <td>
                <span class="tertiary-plain-text">{{ band.category_name || 'All Categories' }}</span>
              </td>
              <td>
                <span class="tertiary-plain-text">{{ band.unit_name || 'All Buying Desks' }}</span>
              </td>
              <td>
                <span class="tertiary-plain-text">{{ formatDisplayDate(band.effective_from) }}</span>
              </td>
              <td>
                <span class="tertiary-plain-text">{{ formatDisplayDate(band.effective_to, 'Indefinite') }}</span>
              </td>
              <td>
                <BaseBadge
                  size="sm"
                  :color="band.state === 'active' ? 'success' : 'gray'"
                >
                  {{ band.state === 'active' ? 'Active' : 'Inactive' }}
                </BaseBadge>
              </td>
              <td class="col-actions">
                <div class="action-menu-container">
                  <button
                    type="button"
                    class="btn-action-dots"
                    title="Actions"
                    @click.stop="toggleBandActionMenu(band.id)"
                  >
                    <MoreVertical :size="15" />
                  </button>

                  <div
                    v-if="activeBandActionMenuId === band.id"
                    class="action-dropdown"
                    @click.stop
                  >
                    <button
                      type="button"
                      class="dropdown-item"
                      @click="handleToggleBandState(band)"
                    >
                      <Check :size="14" class="dropdown-icon" />
                      <span>{{ band.state === 'active' ? 'Deactivate' : 'Activate' }}</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button
                      type="button"
                      class="dropdown-item dropdown-item-danger"
                      @click="handleDeleteBand(band)"
                    >
                      <Trash2 :size="14" class="dropdown-icon" />
                      <span>Remove Band</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- DIRECTORY VIEW: SINGLE TABLE CARD (AGENTS.md Rule 10.1 & 21)   -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <template v-else>
      <AppDataTable
        title="Purchase Methods"
        subtitle="Statutory procurement procedures, evaluation rules, committee mandates, and order value threshold bands."
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search method by name, code, or description..."
        :showSearch="true"
        :showFilter="true"
        :showFullscreen="true"
        :filterCount="activeFilterCount"
        :showSort="true"
        :sortOptions="sortOptions"
        v-model:currentSort="currentSort"
        v-model:sortOrder="sortOrder"
        :showColumns="true"
        :columns="tableColumns"
        :totalEntries="filteredMethods.length"
        :showPagination="true"
        v-model:currentPage="currentPage"
        v-model:perPage="perPage"
        @toggleColumn="handleToggleColumn"
        @resetFilter="resetFilters"
      >
        <!-- Primary Action inside Toolbar (Rule 10.2 & Rule 31) -->
        <template #actions>
          <AppButton variant="primary" size="sm" @click="openCreateModal">
            <template #icon-left>
              <Plus :size="15" />
            </template>
            Create Method
          </AppButton>
        </template>

        <!-- Filter Panel -->
        <template #filter-panel>
          <div class="filter-panel-grid">
            <FormSelect
              label="Quotation Rule"
              v-model="filterQuotations"
              :options="[
                { value: '', label: 'All Quotation Rules' },
                { value: 'zero', label: 'None (Direct Off-the-shelf)' },
                { value: 'competitive', label: 'Competitive (3+ Quotes)' }
              ]"
              placeholder="Select"
            />
            <FormSelect
              label="Committee Mandate"
              v-model="filterCommittee"
              :options="[
                { value: '', label: 'All Mandates' },
                { value: 'yes', label: 'Mandatory Committee' },
                { value: 'no', label: 'Buyer Evaluation Only' }
              ]"
              placeholder="Select"
            />
            <FormSelect
              label="Sealed Bids"
              v-model="filterSealedBid"
              :options="[
                { value: '', label: 'All Bidding Modes' },
                { value: 'yes', label: 'Strict Sealed Bids' },
                { value: 'no', label: 'Standard Quotations' }
              ]"
              placeholder="Select"
            />
            <FormSelect
              label="Invitation Scope"
              v-model="filterInvitation"
              :options="[
                { value: '', label: 'All Invitation Scopes' },
                { value: 'open', label: 'Open Public Advert' },
                { value: 'invited', label: 'Invited Shortlist' }
              ]"
              placeholder="Select"
            />
            <FormSelect
              label="Governance Status"
              v-model="filterStatus"
              :options="[{ value: '', label: 'All Statuses' }, ...governanceStatusOptions]"
              placeholder="Select"
            />
            <FormSelect
              label="Lifecycle State"
              v-model="filterState"
              :options="[
                { value: '', label: 'All States' },
                { value: 'active', label: 'Active' },
                { value: 'inactive', label: 'Inactive' }
              ]"
              placeholder="Select"
            />
          </div>
          <div v-if="activeFilterCount > 0" class="filter-panel-footer">
            <AppButton variant="outline" size="sm" @click="resetFilters">
              Reset Filters
            </AppButton>
          </div>
        </template>

        <!-- Table Content (Lead Checkbox in Identity Column) -->
        <table class="erp-table">
          <thead>
            <tr>
              <th
                v-if="isColumnVisible('name')"
                class="sortable"
                @click="handleSortColumn('name')"
              >
                <div class="th-content name-header-content">
                  <FormCheckbox
                    :model-value="isAllSelected"
                    :indeterminate="isPartiallySelected"
                    size="md"
                    @click.stop
                    @update:model-value="toggleSelectAll"
                  >
                    <span class="sr-only">Select all methods on this page</span>
                  </FormCheckbox>
                  <span>Purchase Method</span>
                  <ArrowUpDown v-if="currentSort === 'name'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('minimum_quotations')"
                class="sortable"
                @click="handleSortColumn('minimum_quotations')"
              >
                <div class="th-content">
                  <span>Quotation Rule</span>
                  <ArrowUpDown v-if="currentSort === 'minimum_quotations'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('requires_committee')"
                class="sortable"
                @click="handleSortColumn('requires_committee')"
              >
                <div class="th-content">
                  <span>Committee Mandate</span>
                  <ArrowUpDown v-if="currentSort === 'requires_committee'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th v-if="isColumnVisible('requires_sealed_bid')">
                <div class="th-content"><span>Sealed Bids</span></div>
              </th>

              <th v-if="isColumnVisible('is_open_invitation')">
                <div class="th-content"><span>Invitation Scope</span></div>
              </th>

              <th v-if="isColumnVisible('allows_single_source')">
                <div class="th-content"><span>Single Source</span></div>
              </th>

              <th v-if="isColumnVisible('requires_post_facto_approval')">
                <div class="th-content"><span>Emergency Ratification</span></div>
              </th>

              <th v-if="isColumnVisible('threshold_bands')">
                <div class="th-content"><span>Configured Bands</span></div>
              </th>

              <th
                v-if="isColumnVisible('status')"
                class="sortable"
                @click="handleSortColumn('status')"
              >
                <div class="th-content">
                  <span>Status</span>
                  <ArrowUpDown v-if="currentSort === 'status'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('state')"
                class="sortable"
                @click="handleSortColumn('state')"
              >
                <div class="th-content">
                  <span>State</span>
                  <ArrowUpDown v-if="currentSort === 'state'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="paginatedMethods.length === 0">
              <td :colspan="visibleColumnCount" class="empty-state-cell">
                <div class="empty-state-container">
                  <Scale :size="32" class="empty-state-icon" />
                  <p class="empty-state-title">No purchase methods found</p>
                  <p class="empty-state-subtext">Try adjusting your search criteria or create a new method.</p>
                </div>
              </td>
            </tr>
            <tr
              v-for="row in paginatedMethods"
              :key="row.id"
              class="erp-row"
              :class="{ 'row-selected': selectedRowIds.includes(row.id) }"
              @click="openDetailView(row)"
            >
              <!-- Identity Column (Lead Checkbox + Primary Name + Code) -->
              <td v-if="isColumnVisible('name')">
                <div class="name-cell-content">
                  <FormCheckbox
                    :model-value="selectedRowIds.includes(row.id)"
                    size="md"
                    @click.stop
                    @update:model-value="(checked: boolean) => toggleSelectRow(row.id, checked)"
                  >
                    <span class="sr-only">Select {{ row.name }}</span>
                  </FormCheckbox>
                  <div class="name-cell-stack">
                    <span class="table-name-primary">{{ row.name }}</span>
                    <span class="table-code-subtext">{{ row.code }}</span>
                  </div>
                </div>
              </td>

              <!-- Quotation Rule -->
              <td v-if="isColumnVisible('minimum_quotations')">
                <span class="tertiary-plain-text">
                  {{ row.minimum_quotations > 0 ? `${row.minimum_quotations} Independent Quotes` : 'None (Off-the-shelf)' }}
                </span>
              </td>

              <!-- Committee Mandate -->
              <td v-if="isColumnVisible('requires_committee')">
                <span class="tertiary-plain-text">
                  {{ row.requires_committee ? 'Mandatory Committee' : 'Buyer Evaluation' }}
                </span>
              </td>

              <!-- Sealed Bids -->
              <td v-if="isColumnVisible('requires_sealed_bid')">
                <span class="tertiary-plain-text">
                  {{ row.requires_sealed_bid ? 'Strict Sealed Bids' : 'Standard Quotation' }}
                </span>
              </td>

              <!-- Invitation Scope -->
              <td v-if="isColumnVisible('is_open_invitation')">
                <span class="tertiary-plain-text">
                  {{ row.is_open_invitation ? 'Open Public Advert' : 'Invited Shortlist' }}
                </span>
              </td>

              <!-- Single Source -->
              <td v-if="isColumnVisible('allows_single_source')">
                <span class="tertiary-plain-text">
                  {{ row.allows_single_source ? 'Allowed' : 'Prohibited' }}
                </span>
              </td>

              <!-- Emergency Post-Facto -->
              <td v-if="isColumnVisible('requires_post_facto_approval')">
                <span class="tertiary-plain-text">
                  {{ row.requires_post_facto_approval ? 'Post-Facto Allowed' : 'Pre-Approval Only' }}
                </span>
              </td>

              <!-- Configured Threshold Bands Summary -->
              <td v-if="isColumnVisible('threshold_bands')">
                <span class="tertiary-plain-text">
                  {{ getMethodBandsCount(row.id) }} configured
                </span>
              </td>

              <!-- Status -->
              <td v-if="isColumnVisible('status')">
                <BaseBadge
                  size="sm"
                  :color="getGovernanceBadgeColor(row.status)"
                >
                  {{ getGovernanceStatusLabel(row.status) }}
                </BaseBadge>
              </td>

              <!-- State -->
              <td v-if="isColumnVisible('state')">
                <BaseBadge
                  size="sm"
                  :color="row.state === 'active' ? 'success' : 'gray'"
                >
                  {{ row.state === 'active' ? 'Active' : 'Inactive' }}
                </BaseBadge>
              </td>

              <!-- Actions (3-Dot Kebab Menu) -->
              <td class="col-actions" @click.stop>
                <div class="action-menu-container">
                  <button
                    type="button"
                    class="btn-action-dots"
                    title="Actions"
                    @click="toggleActionMenu(row.id)"
                  >
                    <MoreVertical :size="15" />
                  </button>

                  <div
                    v-if="activeActionMenuId === row.id"
                    class="action-dropdown"
                  >
                    <button
                      type="button"
                      class="dropdown-item"
                      @click="openDetailView(row)"
                    >
                      <Eye :size="14" class="dropdown-icon" />
                      <span>Inspect Specs</span>
                    </button>
                    <button
                      type="button"
                      class="dropdown-item"
                      @click="() => { openEditModal(row); closeActionMenu(); }"
                    >
                      <Edit2 :size="14" class="dropdown-icon" />
                      <span>Edit Method</span>
                    </button>
                    <button
                      type="button"
                      class="dropdown-item"
                      @click="handleToggleState(row)"
                    >
                      <Check :size="14" class="dropdown-icon" />
                      <span>{{ row.state === 'active' ? 'Deactivate' : 'Activate' }}</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button
                      type="button"
                      class="dropdown-item dropdown-item-danger"
                      @click="handleDelete(row)"
                    >
                      <Trash2 :size="14" class="dropdown-icon" />
                      <span>Delete</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </AppDataTable>
    </template>

    <!-- ═══ SELECTION FLOATING BAR (AGENTS.md Table Architecture) ═══ -->
    <TableFloatingBar
      :selected-count="selectedRowIds.length"
      @clear="selectedRowIds = []"
    >
      <AppButton
        variant="outline"
        size="sm"
        @click="selectedRowIds.forEach(id => {
          const item = purchaseMethodsStore.find(m => m.id === id);
          if (item) item.state = 'inactive';
        }); selectedRowIds = []; showLocalToast('Deactivated selected methods.');"
      >
        Deactivate Selected
      </AppButton>
      <AppButton
        variant="destructive"
        size="sm"
        @click="handleBatchDelete"
      >
        Delete Selected
      </AppButton>
    </TableFloatingBar>

    <!-- ═══ MODAL: CREATE / EDIT PURCHASE METHOD ═══ -->
    <QuickCreateModal
      v-model:show="showMethodModal"
      :title="editingMethodId ? 'Edit Purchase Method' : 'Create Purchase Method'"
      :showExpandButton="!editingMethodId"
      saveLabel="Save"
      width="md"
      @save="handleSaveMethod"
      @expand="handleExpandFullForm"
    >
      <div class="quick-form-body">
        <div class="modal-grid-2">
          <FormInput
            v-model="methodForm.name"
            label="Method Name"
            :error="methodFormErrors.name"
            required
          />

          <FormInput
            v-model="methodForm.minimum_quotations"
            type="number"
            label="Minimum Quotations Required"
            required
          />
        </div>

        <!-- Rule 5: All booleans MUST use <FormCheckbox /> with Title + Description -->
        <div class="modal-checkbox-stack">
          <FormCheckbox
            v-model="methodForm.requires_committee"
            label="Requires Procurement Committee Evaluation"
            description="A designated procurement evaluation committee must review, score, and sanction supplier awards."
          />
          <FormCheckbox
            v-model="methodForm.requires_sealed_bid"
            label="Requires Simultaneous Sealed Bids"
            description="Supplier bids must remain cryptographically sealed and opened simultaneously in committee session."
          />
          <FormCheckbox
            v-model="methodForm.is_open_invitation"
            label="Open Public Advert"
            description="Notice is advertised publicly to all qualified market suppliers rather than restricted to an invited shortlist."
          />
          <FormCheckbox
            v-model="methodForm.allows_single_source"
            label="Allows Single Source Supplier"
            description="Permits direct award to a sole-source or proprietary supplier without solicitation of multiple quotes."
          />
          <FormCheckbox
            v-model="methodForm.requires_post_facto_approval"
            label="Allows Emergency Post-Facto Ratification"
            description="Permits immediate operational procurement with formal committee ratification conducted after placement."
          />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.purchase-methods-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

/* Filter Panel */
.filter-panel-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
  gap: 14px;
}

.filter-panel-footer {
  display: flex;
  justify-content: flex-end;
  margin-top: 12px;
}

/* Table Standards (Rule 8, 9, 28) */
.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background-color: #fafafa;
  border-bottom: 1px solid #E5E5E5;
  text-align: left;
  white-space: nowrap;
}

.erp-table th.sortable {
  cursor: pointer;
  user-select: none;
}

.erp-table th.sortable:hover {
  color: #404040;
}

.th-content {
  display: inline-flex !important;
  align-items: center !important;
  gap: 5px !important;
  white-space: nowrap !important;
  vertical-align: middle !important;
}

.name-header-content,
.name-cell-content {
  gap: 12px;
}

.name-cell-content {
  display: flex;
  align-items: center;
  min-width: 0;
}

.sort-icon {
  color: #0B529C;
  flex-shrink: 0;
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  font-size: 13px;
  border-bottom: 1px solid #E5E5E5;
  vertical-align: middle;
}

.erp-row {
  cursor: pointer;
  transition: background-color 0.12s ease;
}

.erp-row:hover {
  background-color: #F5F5F5;
}

.row-selected {
  background-color: #E1EEFD;
}

.name-cell-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary {
  color: #404040;
  font-weight: 500;
  font-size: 13px;
}

.table-code-subtext {
  color: #737373;
  font-size: 11.5px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}

.tertiary-plain-text {
  color: #737373;
  font-size: 13px;
}

/* Action Dropdown */
.col-actions {
  width: 64px;
  text-align: right;
}

.action-menu-container {
  position: relative;
  display: inline-flex;
  justify-content: flex-end;
}

.btn-action-dots {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: 1px solid transparent;
  background: transparent;
  color: #737373;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.btn-action-dots:hover {
  background: #F5F5F5;
  color: #404040;
}

.action-dropdown {
  position: absolute;
  right: 0;
  top: 32px;
  min-width: 170px;
  background: #ffffff;
  border: 1px solid #E5E5E5;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.08);
  padding: 4px;
  z-index: 40;
}

.dropdown-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 7px 10px;
  font-size: 12.5px;
  color: #404040;
  background: transparent;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
}

.dropdown-item:hover {
  background: #F5F5F5;
}

.dropdown-icon {
  color: #737373;
}

.dropdown-divider {
  height: 1px;
  background: #F5F5F5;
  margin: 4px 0;
}

.dropdown-item-danger {
  color: #E7000B;
}

.dropdown-item-danger .dropdown-icon {
  color: #E7000B;
}

.dropdown-item-danger:hover {
  background: #FEF2F2;
}

/* Empty State */
.empty-state-cell {
  padding: 48px 16px !important;
  text-align: center;
}

.empty-state-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.empty-state-icon {
  color: #737373;
  margin-bottom: 4px;
}

.empty-state-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.empty-state-subtext {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

/* Quick Form Body */
.quick-form-body {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.modal-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
}

.modal-checkbox-stack {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
  padding-top: 6px;
}

.unlimited-placeholder-box {
  display: flex;
  align-items: center;
  height: 42px;
  padding: 0 14px;
  background: #f5f5f5;
  border: 1px dashed #d4d4d4;
  border-radius: 8px;
  margin-top: 24px;
}

.unlimited-label {
  font-size: 13px;
  font-weight: 500;
  color: #0b529c;
}

/* Detail View */
.detail-view-wrapper {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.detail-card {
  background: #ffffff;
  border: 1px solid #E5E5E5;
  border-radius: 12px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.detail-header-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
}

.title-with-badge {
  display: flex;
  align-items: center;
  gap: 10px;
}

.detail-title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #404040;
}

.section-title {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.detail-code {
  display: inline-block;
  margin-top: 2px;
  font-size: 12px;
  color: #737373;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}

.detail-badges {
  display: flex;
  align-items: center;
  gap: 8px;
}

.detail-desc-text {
  font-size: 13.5px;
  color: #525252;
  margin: 0;
  line-height: 1.5;
}

.detail-divider {
  height: 1px;
  background: #F5F5F5;
}

.detail-meta-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 16px;
}

.meta-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.meta-label {
  font-size: 12px;
  font-weight: 500;
  color: #737373;
}

.meta-value {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
}

/* Sub-table in detail view */
.members-subtable {
  margin-top: 4px;
}

.subtable-row:hover {
  background-color: #F5F5F5;
}

.subtable-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 4px;
}

.btn-icon-subtle {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  border-radius: 6px;
  border: 1px solid transparent;
  background: transparent;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-icon-subtle:hover {
  background-color: #F5F5F5;
  color: #404040;
}

.btn-danger-subtle:hover {
  background-color: #FEF2F2;
  color: #E7000B;
}
/* Filter Panel Horizontal Wrap Standard */
.filter-panel-grid {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  gap: 14px 16px;
  width: 100%;
}

.filter-panel-grid :deep(.form-control-wrapper) {
  flex: 1 1 200px;
  min-width: 180px;
  max-width: 280px;
  width: auto;
}

.filter-panel-footer {
  display: flex;
  justify-content: flex-end;
  width: 100%;
  margin-top: 10px;
}
</style>
