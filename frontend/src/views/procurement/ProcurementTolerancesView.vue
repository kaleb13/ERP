<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  Plus, ArrowUpDown, MoreVertical, Eye, Edit2, Trash2, Copy, Check, X, Sliders,
  PackageCheck, FileCheck2, ShieldAlert, CheckCircle2
} from 'lucide-vue-next';
import { useToast } from '../../composables/useToast';
import { formatDisplayDateRange } from '../../utils/dateFormat';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef, type SortOption } from '../../components/BaseTable.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import MetricCard from '../../components/MetricCard.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import {
  receiptToleranceRulesStore,
  type ReceiptToleranceRuleRecord,
  getActionLabel,
  getScopeLevel,
  actionOptions
} from './receiptToleranceRuleData';
import {
  matchingToleranceRulesStore,
  type MatchingToleranceRuleRecord,
  matchTypeOptions,
  exceptionActionOptions,
  getMatchTypeLabel,
  getMatchTypeBadgeColor,
  getExceptionActionLabel,
  getMatchingScopeSummary,
  getMatchingEntityName,
  formatEtb
} from './matchingToleranceRuleData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

// ─── Unified Tab State (Synced with ?tab=receipt|matching) ───
type ToleranceTabId = 'receipt' | 'matching';
const activeTab = ref<ToleranceTabId>(
  route.query.tab === 'matching' ? 'matching' : 'receipt'
);

watch(
  () => route.query.tab,
  (newTab) => {
    if (newTab === 'matching' || newTab === 'receipt') {
      activeTab.value = newTab;
    }
  }
);

watch(activeTab, (tab) => {
  inspectingRule.value = null;
  inspectingMatchingRule.value = null;
  if (route.query.tab !== tab) {
    router.replace({ query: { ...route.query, tab } });
  }
});

// Directory tabs have NO number badges per AGENTS.md rule
const toleranceTabs = computed<BaseTabItem<ToleranceTabId>[]>(() => [
  { id: 'receipt', label: 'Receipt Tolerances', icon: PackageCheck },
  { id: 'matching', label: 'Matching Tolerances', icon: FileCheck2 }
]);

// ─── Search, Filter, Sort & Pagination State ───
const searchQuery = ref('');
const filterScopeLevel = ref('');
const filterOverAction = ref('');
const filterUnderAction = ref('');
const filterState = ref('');
const currentSort = ref('priority');
const sortOrder = ref<'asc' | 'desc'>('asc');
const currentPage = ref(1);
const perPage = ref(10);

const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const inspectingRule = ref<ReceiptToleranceRuleRecord | null>(null);
const inspectingMatchingRule = ref<MatchingToleranceRuleRecord | null>(null);

// ─── Breadcrumb Navigation (Exact Page Name Only; Transparent Canvas) ───
const breadcrumbItems = computed<BreadcrumbItem[]>(() => {
  if (inspectingRule.value) {
    return [
      {
        label: 'Receipt & Matching Rule',
        to: '/procurement/tolerances?tab=receipt',
        onClick: () => {
          inspectingRule.value = null;
        }
      },
      {
        label: `${getScopeLevel(inspectingRule.value).summary} · Rule #${inspectingRule.value.id}`
      }
    ];
  }
  if (inspectingMatchingRule.value) {
    return [
      {
        label: 'Receipt & Matching Rule',
        to: '/procurement/tolerances?tab=matching',
        onClick: () => {
          inspectingMatchingRule.value = null;
        }
      },
      {
        label: `${getMatchingScopeSummary(inspectingMatchingRule.value).summary} · Match Rule #${inspectingMatchingRule.value.id}`
      }
    ];
  }
  return [{ label: 'Receipt & Matching Rule' }];
});

// ─── Table Columns (5-8 High-Signal Scanning Columns; Secondary in Column Hider) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'scope', label: 'Scope Target', visible: true, sortable: true, hideable: false },
  { key: 'over_tolerance', label: 'Over-Receipt Limit', visible: true, sortable: true },
  { key: 'under_tolerance', label: 'Under-Receipt Shortfall', visible: true, sortable: true },
  { key: 'schedule', label: 'Schedule Grace', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false },
  // Secondary Columns (Hidden by default, available in Column Hider):
  { key: 'priority', label: 'Priority', visible: false, sortable: true },
  { key: 'category_scope', label: 'Category Scope', visible: false, sortable: false },
  { key: 'supplier_scope', label: 'Supplier Scope', visible: false, sortable: false },
  { key: 'product_scope', label: 'Product Scope', visible: false, sortable: false },
  { key: 'validity', label: 'Validity Period', visible: false, sortable: false }
]);

const sortOptions: SortOption[] = [
  { key: 'priority', label: 'Priority (Highest Precedence)' },
  { key: 'scope', label: 'Scope Target' },
  { key: 'over_tolerance', label: 'Over-Receipt %' },
  { key: 'under_tolerance', label: 'Under-Receipt %' },
  { key: 'state', label: 'State' }
];

const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find((c) => c.key === key);
  return col ? col.visible !== false : true;
};

const handleToggleColumn = (key: string) => {
  const col = tableColumns.value.find((c) => c.key === key);
  if (col && col.hideable !== false) {
    col.visible = col.visible === false;
  }
};

// ─── Filters & Search ───
const activeFilterCount = computed(() => {
  let count = 0;
  if (filterScopeLevel.value) count++;
  if (filterOverAction.value) count++;
  if (filterUnderAction.value) count++;
  if (filterState.value) count++;
  return count;
});

const resetFilters = () => {
  filterScopeLevel.value = '';
  filterOverAction.value = '';
  filterUnderAction.value = '';
  filterState.value = '';
  searchQuery.value = '';
  currentPage.value = 1;
};

const filteredRules = computed(() => {
  let list = [...receiptToleranceRulesStore.value];

  if (searchQuery.value.trim()) {
    const q = searchQuery.value.trim().toLowerCase();
    list = list.filter((r) => {
      const scope = getScopeLevel(r);
      return (
        scope.summary.toLowerCase().includes(q) ||
        (r.category_name && r.category_name.toLowerCase().includes(q)) ||
        (r.supplier_name && r.supplier_name.toLowerCase().includes(q)) ||
        (r.product_name && r.product_name.toLowerCase().includes(q)) ||
        (r.product_sku && r.product_sku.toLowerCase().includes(q))
      );
    });
  }

  if (filterScopeLevel.value) {
    const lvl = Number(filterScopeLevel.value);
    list = list.filter((r) => getScopeLevel(r).level === lvl);
  }
  if (filterOverAction.value) {
    list = list.filter((r) => r.over_action_lookup_value_id === filterOverAction.value);
  }
  if (filterUnderAction.value) {
    list = list.filter((r) => r.under_action_lookup_value_id === filterUnderAction.value);
  }
  if (filterState.value) {
    list = list.filter((r) => r.state === filterState.value);
  }

  list.sort((a, b) => {
    let valA: string | number = '';
    let valB: string | number = '';
    switch (currentSort.value) {
      case 'priority':
        valA = a.priority;
        valB = b.priority;
        break;
      case 'scope':
        valA = getScopeLevel(a).summary.toLowerCase();
        valB = getScopeLevel(b).summary.toLowerCase();
        break;
      case 'over_tolerance':
        valA = a.over_receipt_percent;
        valB = b.over_receipt_percent;
        break;
      case 'under_tolerance':
        valA = a.under_receipt_percent;
        valB = b.under_receipt_percent;
        break;
      case 'state':
        valA = a.state;
        valB = b.state;
        break;
    }
    if (valA < valB) return sortOrder.value === 'asc' ? -1 : 1;
    if (valA > valB) return sortOrder.value === 'asc' ? 1 : -1;
    return 0;
  });

  return list;
});

const paginatedRules = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredRules.value.slice(start, start + perPage.value);
});

const handleSortColumn = (colKey: string) => {
  if (currentSort.value === colKey) {
    sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
  } else {
    currentSort.value = colKey;
    sortOrder.value = 'asc';
  }
};

// ─── Row Selection ───
const isAllSelected = computed(() => {
  if (paginatedRules.value.length === 0) return false;
  return paginatedRules.value.every((r) => selectedRowIds.value.includes(r.id));
});

const isPartiallySelected = computed(() => {
  const pageIds = paginatedRules.value.map((r) => r.id);
  const selectedOnPage = pageIds.filter((id) => selectedRowIds.value.includes(id));
  return selectedOnPage.length > 0 && selectedOnPage.length < pageIds.length;
});

const toggleSelectAll = (checked: boolean) => {
  const pageIds = paginatedRules.value.map((r) => r.id);
  if (checked) {
    const combined = new Set([...selectedRowIds.value, ...pageIds]);
    selectedRowIds.value = Array.from(combined);
  } else {
    selectedRowIds.value = selectedRowIds.value.filter((id) => !pageIds.includes(id));
  }
};

const toggleSelectRow = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx === -1) {
    selectedRowIds.value.push(id);
  } else {
    selectedRowIds.value.splice(idx, 1);
  }
};

// ─── Actions Popover ───
const toggleActionMenu = (id: number, e: Event) => {
  e.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
};

onMounted(() => {
  window.addEventListener('click', closeActionMenu);
});

onUnmounted(() => {
  window.removeEventListener('click', closeActionMenu);
});

// ─── CRUD Handlers ───
const goToCreate = () => {
  router.push('/procurement/receipt-tolerances/create');
};

const handleInspect = (rule: ReceiptToleranceRuleRecord) => {
  inspectingRule.value = rule;
  closeActionMenu();
};

const handleEdit = (id: number) => {
  closeActionMenu();
  router.push(`/procurement/receipt-tolerances/${id}/edit`);
};

const handleDuplicate = (rule: ReceiptToleranceRuleRecord) => {
  closeActionMenu();
  const nextId = Math.max(0, ...receiptToleranceRulesStore.value.map((r) => r.id)) + 1;
  const clone: ReceiptToleranceRuleRecord = {
    ...rule,
    id: nextId,
    uuid: `8a1f4b23-7e21-4f12-a1b9-d3e74c8100${nextId.toString().padStart(2, '0')}`,
    priority: rule.priority + 1
  };
  receiptToleranceRulesStore.value.unshift(clone);
  toast.success(`Rule duplicated as #${nextId}`);
};

const handleToggleState = (rule: ReceiptToleranceRuleRecord) => {
  closeActionMenu();
  const newState = rule.state === 'active' ? 'inactive' : 'active';
  rule.state = newState;
  toast.success(`Rule #${rule.id} marked as ${newState}.`);
};

const handleDelete = (id: number) => {
  closeActionMenu();
  const idx = receiptToleranceRulesStore.value.findIndex((r) => r.id === id);
  if (idx !== -1) {
    receiptToleranceRulesStore.value.splice(idx, 1);
    selectedRowIds.value = selectedRowIds.value.filter((i) => i !== id);
    if (inspectingRule.value?.id === id) {
      inspectingRule.value = null;
    }
    toast.success(`Rule #${id} removed.`);
  }
};

// ─── Bulk Actions ───
const handleBulkActivate = () => {
  receiptToleranceRulesStore.value.forEach((r) => {
    if (selectedRowIds.value.includes(r.id)) {
      r.state = 'active';
    }
  });
  toast.success(`${selectedRowIds.value.length} rules activated.`);
  selectedRowIds.value = [];
};

const handleBulkDeactivate = () => {
  receiptToleranceRulesStore.value.forEach((r) => {
    if (selectedRowIds.value.includes(r.id)) {
      r.state = 'inactive';
    }
  });
  toast.success(`${selectedRowIds.value.length} rules deactivated.`);
  selectedRowIds.value = [];
};

const handleBulkDelete = () => {
  const count = selectedRowIds.value.length;
  receiptToleranceRulesStore.value = receiptToleranceRulesStore.value.filter(
    (r) => !selectedRowIds.value.includes(r.id)
  );
  selectedRowIds.value = [];
  toast.success(`${count} rules deleted.`);
};

// ═══════════════════════════════════════════════════════════════
// TAB 2: MATCHING TOLERANCE RULES STATE & HANDLERS
// ═══════════════════════════════════════════════════════════════
const matchSearchQuery = ref('');
const filterMatchType = ref('');
const filterExceptionAction = ref('');
const filterAutoMatch = ref('');
const filterMatchState = ref('');
const matchSort = ref('priority');
const matchSortOrder = ref<'asc' | 'desc'>('asc');
const matchPage = ref(1);
const matchPerPage = ref(10);
const selectedMatchRowIds = ref<number[]>([]);
const activeMatchMenuId = ref<number | null>(null);

const matchTableColumns = ref<ColumnDef[]>([
  { key: 'scope', label: 'Scope Target', visible: true, sortable: true, hideable: false },
  { key: 'match_type', label: 'Match Type', visible: true, sortable: true },
  { key: 'price_variance', label: 'Price Variance', visible: true, sortable: true },
  { key: 'qty_total', label: 'Qty & Total Cap', visible: true, sortable: true },
  { key: 'auto_match', label: 'Auto-Match', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false },
  // Secondary Columns (Hidden by default in Column Hider):
  { key: 'exception_action', label: 'Exception Action', visible: false, sortable: false },
  { key: 'priority', label: 'Priority', visible: false, sortable: true },
  { key: 'category_scope', label: 'Category Scope', visible: false, sortable: false },
  { key: 'supplier_scope', label: 'Supplier Scope', visible: false, sortable: false },
  { key: 'validity', label: 'Validity Period', visible: false, sortable: false }
]);

const matchSortOptions: SortOption[] = [
  { key: 'priority', label: 'Priority (Highest Precedence)' },
  { key: 'scope', label: 'Scope Target' },
  { key: 'match_type', label: 'Match Type' },
  { key: 'price_variance', label: 'Price Variance %' },
  { key: 'state', label: 'State' }
];

const isMatchColVisible = (key: string) => {
  const col = matchTableColumns.value.find((c) => c.key === key);
  return col ? col.visible !== false : true;
};

const handleToggleMatchCol = (key: string) => {
  const col = matchTableColumns.value.find((c) => c.key === key);
  if (col && col.hideable !== false) {
    col.visible = col.visible === false;
  }
};

const activeMatchFilterCount = computed(() => {
  let count = 0;
  if (filterMatchType.value) count++;
  if (filterExceptionAction.value) count++;
  if (filterAutoMatch.value) count++;
  if (filterMatchState.value) count++;
  return count;
});

const resetMatchFilters = () => {
  filterMatchType.value = '';
  filterExceptionAction.value = '';
  filterAutoMatch.value = '';
  filterMatchState.value = '';
  matchSearchQuery.value = '';
  matchPage.value = 1;
};

const filteredMatchRules = computed(() => {
  let list = [...matchingToleranceRulesStore.value];

  if (matchSearchQuery.value.trim()) {
    const q = matchSearchQuery.value.trim().toLowerCase();
    list = list.filter((r) => {
      const scope = getMatchingScopeSummary(r);
      return (
        scope.summary.toLowerCase().includes(q) ||
        (r.category_name && r.category_name.toLowerCase().includes(q)) ||
        (r.supplier_name && r.supplier_name.toLowerCase().includes(q)) ||
        getMatchTypeLabel(r.match_type_lookup_value_id).toLowerCase().includes(q)
      );
    });
  }

  if (filterMatchType.value) {
    list = list.filter((r) => r.match_type_lookup_value_id === filterMatchType.value);
  }
  if (filterExceptionAction.value) {
    list = list.filter((r) => r.exception_action_lookup_value_id === filterExceptionAction.value);
  }
  if (filterAutoMatch.value) {
    const want = filterAutoMatch.value === 'true';
    list = list.filter((r) => r.auto_match_enabled === want);
  }
  if (filterMatchState.value) {
    list = list.filter((r) => r.state === filterMatchState.value);
  }

  list.sort((a, b) => {
    let valA: string | number = '';
    let valB: string | number = '';
    switch (matchSort.value) {
      case 'priority':
        valA = a.priority;
        valB = b.priority;
        break;
      case 'scope':
        valA = getMatchingScopeSummary(a).summary.toLowerCase();
        valB = getMatchingScopeSummary(b).summary.toLowerCase();
        break;
      case 'match_type':
        valA = a.match_type_lookup_value_id;
        valB = b.match_type_lookup_value_id;
        break;
      case 'price_variance':
        valA = a.price_variance_percent;
        valB = b.price_variance_percent;
        break;
      case 'state':
        valA = a.state;
        valB = b.state;
        break;
    }
    if (valA < valB) return matchSortOrder.value === 'asc' ? -1 : 1;
    if (valA > valB) return matchSortOrder.value === 'asc' ? 1 : -1;
    return 0;
  });

  return list;
});

const paginatedMatchRules = computed(() => {
  const start = (matchPage.value - 1) * matchPerPage.value;
  return filteredMatchRules.value.slice(start, start + matchPerPage.value);
});

const handleSortMatchCol = (colKey: string) => {
  if (matchSort.value === colKey) {
    matchSortOrder.value = matchSortOrder.value === 'asc' ? 'desc' : 'asc';
  } else {
    matchSort.value = colKey;
    matchSortOrder.value = 'asc';
  }
};

const isAllMatchSelected = computed(() => {
  if (paginatedMatchRules.value.length === 0) return false;
  return paginatedMatchRules.value.every((r) => selectedMatchRowIds.value.includes(r.id));
});

const isPartialMatchSelected = computed(() => {
  const pageIds = paginatedMatchRules.value.map((r) => r.id);
  const selectedOnPage = pageIds.filter((id) => selectedMatchRowIds.value.includes(id));
  return selectedOnPage.length > 0 && selectedOnPage.length < pageIds.length;
});

const toggleSelectAllMatch = (checked: boolean) => {
  const pageIds = paginatedMatchRules.value.map((r) => r.id);
  if (checked) {
    selectedMatchRowIds.value = Array.from(new Set([...selectedMatchRowIds.value, ...pageIds]));
  } else {
    selectedMatchRowIds.value = selectedMatchRowIds.value.filter((id) => !pageIds.includes(id));
  }
};

const toggleSelectMatchRow = (id: number) => {
  const idx = selectedMatchRowIds.value.indexOf(id);
  if (idx === -1) selectedMatchRowIds.value.push(id);
  else selectedMatchRowIds.value.splice(idx, 1);
};

const toggleMatchActionMenu = (id: number, e: Event) => {
  e.stopPropagation();
  activeMatchMenuId.value = activeMatchMenuId.value === id ? null : id;
};

const closeAllMenus = () => {
  activeActionMenuId.value = null;
  activeMatchMenuId.value = null;
};

onMounted(() => {
  window.addEventListener('click', closeAllMenus);
});

onUnmounted(() => {
  window.removeEventListener('click', closeAllMenus);
});

const goToCreateMatch = () => {
  router.push('/procurement/matching-tolerances/create');
};

const handleInspectMatch = (rule: MatchingToleranceRuleRecord) => {
  inspectingMatchingRule.value = rule;
  closeAllMenus();
};

const handleEditMatch = (id: number) => {
  closeAllMenus();
  router.push(`/procurement/matching-tolerances/${id}/edit`);
};

const handleDuplicateMatch = (rule: MatchingToleranceRuleRecord) => {
  closeAllMenus();
  const nextId = Math.max(0, ...matchingToleranceRulesStore.value.map((r) => r.id)) + 1;
  matchingToleranceRulesStore.value.unshift({
    ...rule,
    id: nextId,
    uuid: `9b2e5c34-8f32-4a23-b2c8-e4f85d9200${nextId.toString().padStart(2, '0')}`,
    priority: rule.priority + 1
  });
  toast.success(`Matching rule duplicated as #${nextId}`);
};

const handleToggleMatchState = (rule: MatchingToleranceRuleRecord) => {
  closeAllMenus();
  const newState = rule.state === 'active' ? 'inactive' : 'active';
  rule.state = newState;
  toast.success(`Matching rule #${rule.id} marked as ${newState}.`);
};

const handleDeleteMatch = (id: number) => {
  closeAllMenus();
  const idx = matchingToleranceRulesStore.value.findIndex((r) => r.id === id);
  if (idx !== -1) {
    matchingToleranceRulesStore.value.splice(idx, 1);
    selectedMatchRowIds.value = selectedMatchRowIds.value.filter((i) => i !== id);
    if (inspectingMatchingRule.value?.id === id) inspectingMatchingRule.value = null;
    toast.success(`Matching rule #${id} removed.`);
  }
};

// Unified Bulk Actions (active tab)
const activeSelectedCount = computed(() =>
  activeTab.value === 'receipt' ? selectedRowIds.value.length : selectedMatchRowIds.value.length
);

const clearActiveSelection = () => {
  if (activeTab.value === 'receipt') selectedRowIds.value = [];
  else selectedMatchRowIds.value = [];
};

const handleActiveBulkActivate = () => {
  if (activeTab.value === 'receipt') {
    handleBulkActivate();
    return;
  }
  matchingToleranceRulesStore.value.forEach((r) => {
    if (selectedMatchRowIds.value.includes(r.id)) r.state = 'active';
  });
  toast.success(`${selectedMatchRowIds.value.length} matching rules activated.`);
  selectedMatchRowIds.value = [];
};

const handleActiveBulkDeactivate = () => {
  if (activeTab.value === 'receipt') {
    handleBulkDeactivate();
    return;
  }
  matchingToleranceRulesStore.value.forEach((r) => {
    if (selectedMatchRowIds.value.includes(r.id)) r.state = 'inactive';
  });
  toast.success(`${selectedMatchRowIds.value.length} matching rules deactivated.`);
  selectedMatchRowIds.value = [];
};

const handleActiveBulkDelete = () => {
  if (activeTab.value === 'receipt') {
    handleBulkDelete();
    return;
  }
  const count = selectedMatchRowIds.value.length;
  matchingToleranceRulesStore.value = matchingToleranceRulesStore.value.filter(
    (r) => !selectedMatchRowIds.value.includes(r.id)
  );
  selectedMatchRowIds.value = [];
  toast.success(`${count} matching rules deleted.`);
};

// KPI Metric Counts
const autoMatchCount = computed(
  () => matchingToleranceRulesStore.value.filter((r) => r.state === 'active' && r.auto_match_enabled).length
);

const strictBlockCount = computed(
  () =>
    receiptToleranceRulesStore.value.filter((r) => r.over_action_lookup_value_id === 'block').length +
    matchingToleranceRulesStore.value.filter((r) => r.exception_action_lookup_value_id === 'block').length
);
</script>

<template>
  <div class="tolerances-page">
    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- BREADCRUMB BAR (Strict Canvas Standard: transparent, zero box) -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div class="breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- INSPECTION DOSSIER CARD (Inline detail view on row click)      -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-if="inspectingRule" class="inspection-wrapper">
      <div class="clean-card dossier-card">
        <div class="dossier-header-row">
          <div class="dossier-identity">
            <h1 class="dossier-title">{{ getScopeLevel(inspectingRule).summary }}</h1>
            <BaseBadge :color="inspectingRule.state === 'active' ? 'success' : 'gray'">
              {{ inspectingRule.state === 'active' ? 'Active' : 'Inactive' }}
            </BaseBadge>
          </div>
          <div class="dossier-close-btn" @click="inspectingRule = null">
            <X :size="18" />
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-meta-grid">
          <div class="meta-item">
            <span class="meta-label">Evaluation Precedence</span>
            <span class="meta-value text-bold">
              Level {{ getScopeLevel(inspectingRule).level }} ({{ getScopeLevel(inspectingRule).title }}) · Priority {{ inspectingRule.priority }}
            </span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Category Scope</span>
            <span class="meta-value">{{ inspectingRule.category_name || 'All Categories (Global)' }}</span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Supplier Scope</span>
            <span class="meta-value">{{ inspectingRule.supplier_name || 'All Suppliers (Global)' }}</span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Product / Item Scope</span>
            <span class="meta-value">
              {{ inspectingRule.product_name ? `${inspectingRule.product_name} (${inspectingRule.product_sku || 'SKU'})` : 'All Products (Global)' }}
            </span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Over-Receipt Limit</span>
            <span class="meta-value text-bold">
              +{{ inspectingRule.over_receipt_percent.toFixed(2) }}% ({{ getActionLabel(inspectingRule.over_action_lookup_value_id) }})
            </span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Under-Receipt Shortfall</span>
            <span class="meta-value text-bold">
              -{{ inspectingRule.under_receipt_percent.toFixed(2) }}% ({{ getActionLabel(inspectingRule.under_action_lookup_value_id) }})
            </span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Early Delivery Allowed</span>
            <span class="meta-value">{{ inspectingRule.early_delivery_days }} days early</span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Late Delivery Grace</span>
            <span class="meta-value">{{ inspectingRule.late_delivery_days }} days grace</span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Effective Dates</span>
            <span class="meta-value">
              {{ formatDisplayDateRange(inspectingRule.effective_from, inspectingRule.effective_to, 'Indefinite') }}
            </span>
          </div>
        </div>

      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- INSPECTION DOSSIER CARD: MATCHING TOLERANCE RULE               -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-else-if="inspectingMatchingRule" class="inspection-wrapper">
      <div class="clean-card dossier-card">
        <div class="dossier-header-row">
          <div class="dossier-identity">
            <h1 class="dossier-title">{{ getMatchingScopeSummary(inspectingMatchingRule).summary }}</h1>
            <BaseBadge :color="getMatchTypeBadgeColor(inspectingMatchingRule.match_type_lookup_value_id)">
              {{ getMatchTypeLabel(inspectingMatchingRule.match_type_lookup_value_id) }}
            </BaseBadge>
            <BaseBadge :color="inspectingMatchingRule.state === 'active' ? 'success' : 'gray'">
              {{ inspectingMatchingRule.state === 'active' ? 'Active' : 'Inactive' }}
            </BaseBadge>
          </div>
          <div class="dossier-close-btn" @click="inspectingMatchingRule = null">
            <X :size="18" />
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-meta-grid">
          <div class="meta-item">
            <span class="meta-label">Evaluation Precedence</span>
            <span class="meta-value text-bold">
              Level {{ getMatchingScopeSummary(inspectingMatchingRule).level }} ({{ getMatchingScopeSummary(inspectingMatchingRule).title }}) · Priority {{ inspectingMatchingRule.priority }}
            </span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Owning Legal Entity</span>
            <span class="meta-value">{{ getMatchingEntityName(inspectingMatchingRule.entity_id) }}</span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Exception Action</span>
            <span class="meta-value text-bold">{{ getExceptionActionLabel(inspectingMatchingRule.exception_action_lookup_value_id) }}</span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Category Scope</span>
            <span class="meta-value">{{ inspectingMatchingRule.category_name || 'All Categories (Global)' }}</span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Supplier Scope</span>
            <span class="meta-value">{{ inspectingMatchingRule.supplier_name || 'All Suppliers (Global)' }}</span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Auto-Match Mode</span>
            <span class="meta-value text-bold">
              {{ inspectingMatchingRule.auto_match_enabled ? 'Enabled (Zero-touch within band)' : 'Manual Review Required' }}
            </span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Price Variance Limit</span>
            <span class="meta-value text-bold">
              ±{{ inspectingMatchingRule.price_variance_percent.toFixed(2) }}% (Cap {{ formatEtb(inspectingMatchingRule.price_variance_amount) }})
            </span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Quantity &amp; Total Variance</span>
            <span class="meta-value text-bold">
              ±{{ inspectingMatchingRule.quantity_variance_percent.toFixed(2) }}% · Invoice Cap {{ formatEtb(inspectingMatchingRule.total_variance_amount) }}
            </span>
          </div>

          <div class="meta-item">
            <span class="meta-label">Effective Dates</span>
            <span class="meta-value">
              {{ formatDisplayDateRange(inspectingMatchingRule.effective_from, inspectingMatchingRule.effective_to, 'Indefinite') }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- UNIFIED DIRECTORY VIEW: TOP CARD (METRICS + TABS) + DATA TABLE -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <template v-else>
      <div class="tolerances-top-card">
        <div class="metrics-grid">
          <MetricCard
            label="RECEIPT TOLERANCES"
            :value="receiptToleranceRulesStore.length"
            subtext="Dock receiving limits"
            :icon="PackageCheck"
            :show-menu="false"
          />
          <MetricCard
            label="MATCHING TOLERANCES"
            :value="matchingToleranceRulesStore.length"
            subtext="Invoice variance policies"
            :icon="FileCheck2"
            :show-menu="false"
          />
          <MetricCard
            label="AUTO-MATCH ENABLED"
            :value="autoMatchCount"
            subtext="Zero-touch invoice posting"
            :icon="CheckCircle2"
            :show-menu="false"
          />
          <MetricCard
            label="STRICT BLOCK POLICIES"
            :value="strictBlockCount"
            subtext="Hard-stop exception controls"
            :icon="ShieldAlert"
            :show-menu="false"
          />
        </div>

        <div class="top-card-tabs-wrapper">
          <BaseTabs
            v-model="activeTab"
            :tabs="toleranceTabs"
            type="rounded"
            :showCount="false"
          />
        </div>
      </div>

      <!-- TAB 1: RECEIPT TOLERANCES -->
      <AppDataTable
        v-if="activeTab === 'receipt'"
        title="Receipt Tolerances"
        subtitle="Delivery limits and grace windows controlling allowed over-receipt, shortfall closure, and schedule variance."
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search by scope target, category, supplier, or product..."
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
        :totalEntries="filteredRules.length"
        :showPagination="true"
        v-model:currentPage="currentPage"
        v-model:perPage="perPage"
        @toggleColumn="handleToggleColumn"
        @resetFilter="resetFilters"
      >
        <!-- Primary Action inside Toolbar: Create Receipt Tolerance -->
        <template #actions>
          <AppButton variant="primary" size="sm" @click="goToCreate">
            <template #icon-left>
              <Plus :size="15" />
            </template>
            Create Receipt Tolerance
          </AppButton>
        </template>

        <!-- Filter Panel -->
        <template #filter-panel>
          <div class="filter-panel-grid">
            <FormSelect
              label="Scope Level"
              v-model="filterScopeLevel"
              :options="[
                { value: '', label: 'All Scope Levels' },
                { value: '4', label: 'Product Specific' },
                { value: '3', label: 'Supplier Specific' },
                { value: '2', label: 'Category Specific' },
                { value: '1', label: 'Entity Default' }
              ]"
              placeholder="Select Level"
            />
            <FormSelect
              label="Over-Receipt Action"
              v-model="filterOverAction"
              :options="[{ value: '', label: 'All Actions' }, ...actionOptions]"
              placeholder="Select Action"
            />
            <FormSelect
              label="Under-Receipt Action"
              v-model="filterUnderAction"
              :options="[{ value: '', label: 'All Actions' }, ...actionOptions]"
              placeholder="Select Action"
            />
            <FormSelect
              label="State"
              v-model="filterState"
              :options="[
                { value: '', label: 'All States' },
                { value: 'active', label: 'Active' },
                { value: 'inactive', label: 'Inactive' }
              ]"
              placeholder="Select State"
            />
          </div>
          <div v-if="activeFilterCount > 0" class="filter-panel-footer">
            <AppButton variant="outline" size="sm" @click="resetFilters">
              Reset Filters
            </AppButton>
          </div>
        </template>

        <!-- Table Content (Lead Checkbox integrated in Identity Column) -->
        <table class="erp-table">
          <thead>
            <tr>
              <th
                v-if="isColumnVisible('scope')"
                class="sortable"
                @click="handleSortColumn('scope')"
              >
                <div class="th-content name-header-content">
                  <FormCheckbox
                    :model-value="isAllSelected"
                    :indeterminate="isPartiallySelected"
                    size="md"
                    @click.stop
                    @update:model-value="toggleSelectAll"
                  >
                    <span class="sr-only">Select all rules on this page</span>
                  </FormCheckbox>
                  <span>Scope Target</span>
                  <ArrowUpDown v-if="currentSort === 'scope'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('over_tolerance')"
                class="sortable"
                @click="handleSortColumn('over_tolerance')"
              >
                <div class="th-content">
                  <span>Over-Receipt Limit</span>
                  <ArrowUpDown v-if="currentSort === 'over_tolerance'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('under_tolerance')"
                class="sortable"
                @click="handleSortColumn('under_tolerance')"
              >
                <div class="th-content">
                  <span>Under-Receipt Shortfall</span>
                  <ArrowUpDown v-if="currentSort === 'under_tolerance'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('schedule')"
                class="sortable"
                @click="handleSortColumn('schedule')"
              >
                <div class="th-content">
                  <span>Schedule Grace</span>
                  <ArrowUpDown v-if="currentSort === 'schedule'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('priority')"
                class="sortable"
                @click="handleSortColumn('priority')"
              >
                <div class="th-content">
                  <span>Priority</span>
                  <ArrowUpDown v-if="currentSort === 'priority'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th v-if="isColumnVisible('category_scope')">
                <div class="th-content"><span>Category Scope</span></div>
              </th>

              <th v-if="isColumnVisible('supplier_scope')">
                <div class="th-content"><span>Supplier Scope</span></div>
              </th>

              <th v-if="isColumnVisible('product_scope')">
                <div class="th-content"><span>Product Scope</span></div>
              </th>

              <th v-if="isColumnVisible('validity')">
                <div class="th-content"><span>Validity Period</span></div>
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

              <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr
              v-for="rule in paginatedRules"
              :key="rule.id"
              class="erp-row"
              :class="{ 'row-selected': selectedRowIds.includes(rule.id) }"
              @click="handleInspect(rule)"
            >
              <!-- 1. Scope Target Identity Cell -->
              <td v-if="isColumnVisible('scope')" class="td-name">
                <div class="name-cell-content">
                  <FormCheckbox
                    :model-value="selectedRowIds.includes(rule.id)"
                    size="md"
                    @click.stop
                    @update:model-value="toggleSelectRow(rule.id)"
                  >
                    <span class="sr-only">Select rule #{{ rule.id }}</span>
                  </FormCheckbox>
                  <div class="name-cell-stack">
                    <span class="table-name-primary">{{ getScopeLevel(rule).summary }}</span>
                    <span class="table-code-subtext">
                      {{ getScopeLevel(rule).title }} · Priority {{ rule.priority }}
                    </span>
                  </div>
                </div>
              </td>

              <!-- 2. Over-Receipt Limit -->
              <td v-if="isColumnVisible('over_tolerance')">
                <div class="tolerance-cell">
                  <span class="td-amount-bold">+{{ rule.over_receipt_percent.toFixed(1) }}%</span>
                  <span class="tertiary-subtext">{{ getActionLabel(rule.over_action_lookup_value_id) }}</span>
                </div>
              </td>

              <!-- 3. Under-Receipt Shortfall -->
              <td v-if="isColumnVisible('under_tolerance')">
                <div class="tolerance-cell">
                  <span class="td-amount-bold">-{{ rule.under_receipt_percent.toFixed(1) }}%</span>
                  <span class="tertiary-subtext">{{ getActionLabel(rule.under_action_lookup_value_id) }}</span>
                </div>
              </td>

              <!-- 4. Schedule Grace -->
              <td v-if="isColumnVisible('schedule')">
                <span class="table-cell-text">Early: {{ rule.early_delivery_days }}d · Late: {{ rule.late_delivery_days }}d</span>
              </td>

              <!-- Priority (Secondary) -->
              <td v-if="isColumnVisible('priority')">
                <span class="table-cell-text">P{{ rule.priority }}</span>
              </td>

              <!-- Category Scope (Secondary) -->
              <td v-if="isColumnVisible('category_scope')">
                <span class="tertiary-subtext">{{ rule.category_name || 'All Categories' }}</span>
              </td>

              <!-- Supplier Scope (Secondary) -->
              <td v-if="isColumnVisible('supplier_scope')">
                <span class="tertiary-subtext">{{ rule.supplier_name || 'All Suppliers' }}</span>
              </td>

              <!-- Product Scope (Secondary) -->
              <td v-if="isColumnVisible('product_scope')">
                <span class="tertiary-subtext">{{ rule.product_name || 'All Products' }}</span>
              </td>

              <!-- Validity Period (Secondary) -->
              <td v-if="isColumnVisible('validity')">
                <span class="tertiary-subtext">{{ formatDisplayDateRange(rule.effective_from, rule.effective_to, 'Open') }}</span>
              </td>

              <!-- State Badge -->
              <td v-if="isColumnVisible('state')">
                <BaseBadge
                  size="sm"
                  :color="rule.state === 'active' ? 'success' : 'gray'"
                >
                  {{ rule.state === 'active' ? 'Active' : 'Inactive' }}
                </BaseBadge>
              </td>

              <!-- Actions 3-Dot Kebab -->
              <td v-if="isColumnVisible('actions')" class="col-actions" @click.stop>
                <div class="action-menu-container">
                  <button
                    type="button"
                    class="btn-action-dots"
                    @click.stop="toggleActionMenu(rule.id, $event)"
                    aria-label="Actions"
                  >
                    <MoreVertical :size="14" />
                  </button>

                  <div
                    v-if="activeActionMenuId === rule.id"
                    class="action-dropdown-menu"
                    @click.stop
                  >
                    <button
                      type="button"
                      class="dropdown-menu-item"
                      @click="handleInspect(rule)"
                    >
                      <Eye :size="14" />
                      <span>View Details</span>
                    </button>
                    <button
                      type="button"
                      class="dropdown-menu-item"
                      @click="handleEdit(rule.id)"
                    >
                      <Edit2 :size="14" />
                      <span>Edit Rule</span>
                    </button>
                    <button
                      type="button"
                      class="dropdown-menu-item"
                      @click="handleDuplicate(rule)"
                    >
                      <Copy :size="14" />
                      <span>Duplicate Rule</span>
                    </button>
                    <div class="dropdown-menu-divider"></div>
                    <button
                      type="button"
                      class="dropdown-menu-item"
                      @click="handleToggleState(rule)"
                    >
                      <component :is="rule.state === 'active' ? X : Check" :size="14" />
                      <span>{{ rule.state === 'active' ? 'Deactivate' : 'Activate' }}</span>
                    </button>
                    <button
                      type="button"
                      class="dropdown-menu-item item-danger"
                      @click="handleDelete(rule.id)"
                    >
                      <Trash2 :size="14" />
                      <span>Delete Rule</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>

            <tr v-if="paginatedRules.length === 0">
              <td :colspan="tableColumns.filter(c => c.visible !== false).length" class="empty-state-cell">
                <div class="empty-state-container">
                  <Sliders :size="32" class="empty-state-icon" />
                  <p class="empty-state-title">No receipt tolerance rules found</p>
                  <p class="empty-state-subtext">Adjust your search or filters, or create a new tolerance policy rule.</p>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </AppDataTable>

      <!-- TAB 2: MATCHING TOLERANCES -->
      <AppDataTable
        v-else
        title="Matching Tolerances"
        subtitle="Invoice price and quantity variance limits for 2-way, 3-way, and 4-way automated matching."
        v-model:searchQuery="matchSearchQuery"
        searchPlaceholder="Search by scope target, category, supplier, or match type..."
        :showSearch="true"
        :showFilter="true"
        :showFullscreen="true"
        :filterCount="activeMatchFilterCount"
        :showSort="true"
        :sortOptions="matchSortOptions"
        v-model:currentSort="matchSort"
        v-model:sortOrder="matchSortOrder"
        :showColumns="true"
        :columns="matchTableColumns"
        :totalEntries="filteredMatchRules.length"
        :showPagination="true"
        v-model:currentPage="matchPage"
        v-model:perPage="matchPerPage"
        @toggleColumn="handleToggleMatchCol"
        @resetFilter="resetMatchFilters"
      >
        <template #actions>
          <AppButton variant="primary" size="sm" @click="goToCreateMatch">
            <template #icon-left>
              <Plus :size="15" />
            </template>
            Create Matching Tolerance
          </AppButton>
        </template>

        <template #filter-panel>
          <div class="filter-panel-grid">
            <FormSelect
              label="Match Type"
              v-model="filterMatchType"
              :options="[{ value: '', label: 'All Match Types' }, ...matchTypeOptions]"
              placeholder="Select Type"
            />
            <FormSelect
              label="Exception Action"
              v-model="filterExceptionAction"
              :options="[{ value: '', label: 'All Actions' }, ...exceptionActionOptions]"
              placeholder="Select Action"
            />
            <FormSelect
              label="Auto-Match Mode"
              v-model="filterAutoMatch"
              :options="[
                { value: '', label: 'All Modes' },
                { value: 'true', label: 'Auto-Match Enabled' },
                { value: 'false', label: 'Manual Review' }
              ]"
              placeholder="Select Mode"
            />
            <FormSelect
              label="State"
              v-model="filterMatchState"
              :options="[
                { value: '', label: 'All States' },
                { value: 'active', label: 'Active' },
                { value: 'inactive', label: 'Inactive' }
              ]"
              placeholder="Select State"
            />
          </div>
        </template>

        <table class="erp-table">
          <thead>
            <tr>
              <th v-if="isMatchColVisible('scope')" class="sortable" @click="handleSortMatchCol('scope')">
                <div class="th-content name-header-content">
                  <FormCheckbox
                    :model-value="isAllMatchSelected"
                    :indeterminate="isPartialMatchSelected"
                    size="md"
                    @click.stop
                    @update:model-value="toggleSelectAllMatch"
                  />
                  <span>Scope Target</span>
                  <ArrowUpDown v-if="matchSort === 'scope'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th v-if="isMatchColVisible('match_type')" class="sortable" @click="handleSortMatchCol('match_type')">
                <div class="th-content">
                  <span>Match Type</span>
                  <ArrowUpDown v-if="matchSort === 'match_type'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th v-if="isMatchColVisible('price_variance')" class="sortable" @click="handleSortMatchCol('price_variance')">
                <div class="th-content">
                  <span>Price Variance</span>
                  <ArrowUpDown v-if="matchSort === 'price_variance'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th v-if="isMatchColVisible('qty_total')">
                <div class="th-content"><span>Qty &amp; Total Cap</span></div>
              </th>

              <th v-if="isMatchColVisible('auto_match')">
                <div class="th-content"><span>Auto-Match</span></div>
              </th>

              <th v-if="isMatchColVisible('exception_action')">
                <div class="th-content"><span>Exception Action</span></div>
              </th>

              <th v-if="isMatchColVisible('priority')" class="sortable" @click="handleSortMatchCol('priority')">
                <div class="th-content">
                  <span>Priority</span>
                  <ArrowUpDown v-if="matchSort === 'priority'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th v-if="isMatchColVisible('category_scope')">
                <div class="th-content"><span>Category Scope</span></div>
              </th>

              <th v-if="isMatchColVisible('supplier_scope')">
                <div class="th-content"><span>Supplier Scope</span></div>
              </th>

              <th v-if="isMatchColVisible('validity')">
                <div class="th-content"><span>Validity Period</span></div>
              </th>

              <th v-if="isMatchColVisible('state')" class="sortable" @click="handleSortMatchCol('state')">
                <div class="th-content">
                  <span>State</span>
                  <ArrowUpDown v-if="matchSort === 'state'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th v-if="isMatchColVisible('actions')" class="col-actions">Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr v-if="paginatedMatchRules.length === 0">
              <td :colspan="matchTableColumns.filter((c) => c.visible !== false).length" class="empty-state-cell">
                <div class="empty-state-container">
                  <FileCheck2 :size="32" class="empty-state-icon" />
                  <p class="empty-state-title">No matching tolerance rules found</p>
                  <p class="empty-state-subtext">Adjust your filters or create a new matching tolerance rule.</p>
                </div>
              </td>
            </tr>

            <tr
              v-for="item in paginatedMatchRules"
              :key="item.id"
              class="table-row-hover"
              :class="{ 'row-selected': selectedMatchRowIds.includes(item.id) }"
              @click="handleInspectMatch(item)"
            >
              <td v-if="isMatchColVisible('scope')">
                <div class="name-cell-content">
                  <FormCheckbox
                    :model-value="selectedMatchRowIds.includes(item.id)"
                    size="md"
                    @click.stop
                    @update:model-value="toggleSelectMatchRow(item.id)"
                  />
                  <div class="name-cell-stack">
                    <span class="table-name-primary">{{ getMatchingScopeSummary(item).summary }}</span>
                    <span class="table-code-subtext">
                      {{ getMatchingScopeSummary(item).title }} · Priority {{ item.priority }}
                    </span>
                  </div>
                </div>
              </td>

              <td v-if="isMatchColVisible('match_type')">
                <BaseBadge :color="getMatchTypeBadgeColor(item.match_type_lookup_value_id)">
                  {{ getMatchTypeLabel(item.match_type_lookup_value_id) }}
                </BaseBadge>
              </td>

              <td v-if="isMatchColVisible('price_variance')">
                <div class="variance-cell-stack">
                  <span class="variance-primary">±{{ item.price_variance_percent.toFixed(1) }}%</span>
                  <span class="variance-action-subtext">Cap {{ formatEtb(item.price_variance_amount) }}</span>
                </div>
              </td>

              <td v-if="isMatchColVisible('qty_total')">
                <div class="variance-cell-stack">
                  <span class="variance-primary">±{{ item.quantity_variance_percent.toFixed(1) }}% Qty</span>
                  <span class="variance-action-subtext">Total {{ formatEtb(item.total_variance_amount) }}</span>
                </div>
              </td>

              <td v-if="isMatchColVisible('auto_match')">
                <BaseBadge :color="item.auto_match_enabled ? 'success' : 'gray'">
                  {{ item.auto_match_enabled ? 'Auto-Match' : 'Manual' }}
                </BaseBadge>
              </td>

              <td v-if="isMatchColVisible('exception_action')">
                <span class="secondary-cell-text">{{ getExceptionActionLabel(item.exception_action_lookup_value_id) }}</span>
              </td>

              <td v-if="isMatchColVisible('priority')">
                <span class="priority-text">P{{ item.priority }}</span>
              </td>

              <td v-if="isMatchColVisible('category_scope')">
                <span class="secondary-cell-text">{{ item.category_name || 'All Categories' }}</span>
              </td>

              <td v-if="isMatchColVisible('supplier_scope')">
                <span class="secondary-cell-text">{{ item.supplier_name || 'All Suppliers' }}</span>
              </td>

              <td v-if="isMatchColVisible('validity')">
                <span class="secondary-cell-text">{{ formatDisplayDateRange(item.effective_from, item.effective_to, 'Indefinite') }}</span>
              </td>

              <td v-if="isMatchColVisible('state')">
                <BaseBadge :color="item.state === 'active' ? 'success' : 'gray'">
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </BaseBadge>
              </td>

              <td v-if="isMatchColVisible('actions')" class="col-actions" @click.stop>
                <div class="action-menu-wrapper">
                  <button
                    type="button"
                    class="kebab-btn"
                    @click="toggleMatchActionMenu(item.id, $event)"
                    aria-label="Matching rule actions"
                  >
                    <MoreVertical :size="16" />
                  </button>

                  <div v-if="activeMatchMenuId === item.id" class="action-popover">
                    <button type="button" class="popover-item" @click="handleInspectMatch(item)">
                      <Eye :size="14" />
                      <span>View Details</span>
                    </button>
                    <button type="button" class="popover-item" @click="handleEditMatch(item.id)">
                      <Edit2 :size="14" />
                      <span>Edit Rule</span>
                    </button>
                    <button type="button" class="popover-item" @click="handleDuplicateMatch(item)">
                      <Copy :size="14" />
                      <span>Duplicate Rule</span>
                    </button>
                    <button type="button" class="popover-item" @click="handleToggleMatchState(item)">
                      <component :is="item.state === 'active' ? X : Check" :size="14" />
                      <span>{{ item.state === 'active' ? 'Deactivate' : 'Activate' }}</span>
                    </button>
                    <div class="popover-divider"></div>
                    <button type="button" class="popover-item popover-danger" @click="handleDeleteMatch(item.id)">
                      <Trash2 :size="14" />
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

    <!-- Floating Batch Selection Bar -->
    <TableFloatingBar
      v-if="activeSelectedCount > 0"
      :selected-count="activeSelectedCount"
      @clear="clearActiveSelection"
    >
      <AppButton variant="secondary" size="sm" @click="handleActiveBulkActivate">
        Activate Selected
      </AppButton>
      <AppButton variant="secondary" size="sm" @click="handleActiveBulkDeactivate">
        Deactivate Selected
      </AppButton>
      <AppButton variant="destructive" size="sm" @click="handleActiveBulkDelete">
        Delete Selected
      </AppButton>
    </TableFloatingBar>
  </div>
</template>

<style scoped>
.tolerances-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Breadcrumb Bar sits directly on canvas */
.breadcrumb-bar {
  background: transparent;
  border: none;
  box-shadow: none;
  padding: 0;
}

/* Clean White Card */
.clean-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
}

/* Unified Top Card (Metrics + BaseTabs) */
.tolerances-top-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
}

.top-card-tabs-wrapper {
  display: flex;
  align-items: center;
  width: 100%;
}

@media (max-width: 1100px) {
  .metrics-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Dossier Card */
.inspection-wrapper {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.dossier-card {
  padding: 24px;
}

.dossier-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.dossier-identity {
  display: flex;
  align-items: center;
  gap: 12px;
}

.dossier-title {
  font-size: 18px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.dossier-close-btn {
  cursor: pointer;
  padding: 6px;
  border-radius: 6px;
  color: #737373;
  display: flex;
  align-items: center;
  justify-content: center;
}

.dossier-close-btn:hover {
  background-color: #f5f5f5;
  color: #404040;
}

.detail-divider {
  height: 1px;
  background-color: #e5e5e5;
  margin: 20px 0;
}

.detail-meta-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}

.meta-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.meta-label {
  font-size: 11px;
  font-weight: 500;
  color: #737373;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.meta-value {
  font-size: 13px;
  color: #404040;
}

.text-bold {
  font-weight: 600;
}

.detail-notes-block {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.detail-notes-text {
  font-size: 13px;
  color: #404040;
  line-height: 1.6;
  margin: 0;
}

/* ERP Table Standards */
.erp-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  text-align: left;
}

.erp-table thead tr {
  background-color: #FAFAFA;
  border-bottom: 1px solid #e5e5e5;
}

.erp-table th {
  padding: 12px 16px;
  font-weight: 600;
  color: #404040;
  font-size: 12px;
  user-select: none;
  white-space: nowrap;
}

.erp-table th.sortable {
  cursor: pointer;
}

.th-content {
  display: flex;
  align-items: center;
  gap: 6px;
}

.name-header-content {
  display: flex;
  align-items: center;
  gap: 12px;
}

.sort-icon {
  color: #737373;
}

.sort-icon.active-sort {
  color: #0B529C;
}

.col-actions {
  width: 60px;
  text-align: center;
  padding: 12px 16px;
}

.erp-row {
  border-bottom: 1px solid #e5e5e5;
  transition: background-color 0.15s ease;
  cursor: pointer;
}

.erp-row:hover {
  background-color: #F5F5F5;
}

.erp-row.row-selected {
  background-color: #F0F9FF;
}

.erp-table td {
  padding: 14px 16px;
  vertical-align: middle;
  color: #404040;
}

.td-name {
  min-width: 240px;
}

.name-cell-content {
  display: flex;
  align-items: center;
  gap: 12px;
}

.name-cell-stack {
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
  font-size: 11px;
  color: #737373;
}

.tolerance-cell {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.td-amount-bold {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.tertiary-subtext {
  font-size: 11px;
  color: #737373;
}

.table-cell-text {
  font-size: 13px;
  color: #404040;
}

/* Action Kebab Menu */
.action-menu-container {
  position: relative;
  display: flex;
  justify-content: center;
}

.btn-action-dots {
  background: none;
  border: none;
  padding: 6px;
  border-radius: 6px;
  cursor: pointer;
  color: #737373;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.15s ease;
}

.btn-action-dots:hover {
  background-color: #E5E5E5;
  color: #404040;
}

.action-dropdown-menu {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  min-width: 160px;
  z-index: 50;
  padding: 4px 0;
}

.dropdown-menu-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  font-size: 12px;
  color: #404040;
  background: none;
  border: none;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.15s ease;
}

.dropdown-menu-item:hover {
  background-color: #FAFAFA;
}

.dropdown-menu-item.item-danger {
  color: #E7000B;
}

.dropdown-menu-item.item-danger:hover {
  background-color: #FEE2E2;
}

.dropdown-menu-divider {
  height: 1px;
  background-color: #e5e5e5;
  margin: 4px 0;
}

.filter-panel-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  padding: 12px;
  min-width: 380px;
}

.filter-panel-footer {
  display: flex;
  justify-content: flex-end;
  padding: 8px 12px 12px;
  border-top: 1px solid #e5e5e5;
}

.empty-state-cell {
  padding: 48px 16px;
  text-align: center;
}

.empty-state-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.empty-state-icon {
  color: #737373;
}

.empty-state-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.empty-state-subtext {
  font-size: 12px;
  color: #737373;
  margin: 0;
}

@media (max-width: 960px) {
  .detail-meta-grid {
    grid-template-columns: 1fr;
  }
}
</style>
