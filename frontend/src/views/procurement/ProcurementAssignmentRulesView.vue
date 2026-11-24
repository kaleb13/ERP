<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, ArrowUpDown, MoreVertical, Eye, Edit2, Trash2,
  GitPullRequest, ShieldCheck, Building2, Globe, ChevronDown, ChevronRight,
  Layers, Check
} from 'lucide-vue-next';
import { useToast } from '../../composables/useToast';
import { formatDisplayDate, formatDisplayDateRange } from '../../utils/dateFormat';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef, type SortOption } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormCheckboxCard from '../../components/FormCheckboxCard.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import BaseBadge, { type BadgeColor } from '../../components/BaseBadge.vue';
import BaseAvatar from '../../components/BaseAvatar.vue';
import MetricCard from '../../components/MetricCard.vue';

import {
  assignmentRulesStore,
  type ProcurementAssignmentRuleRecord,
  type SourcingOrigin,
  unitOptions,
  buyerOptions,
  originOptions,
  categoryScopeOptions,
  methodScopeOptions,
  requestingEntityOptions,
  priorityOptions,
  formatCurrency,
  getUnitName,
  getBuyerName,
  getBuyerAvatar,
  getCategoryName,
  getOriginLabel,
  getEntityName,
  getMethodName
} from './procurementAssignmentRuleData';

const router = useRouter();
const { toast } = useToast();

// ─── View & Selection State ───
const searchQuery = ref('');
const filterUnit = ref('');
const filterBuyer = ref('');
const filterCategory = ref('');
const filterOrigin = ref('');
const filterRequestingEntity = ref('');
const filterState = ref('');
const currentSort = ref('priority');
const sortOrder = ref<'asc' | 'desc'>('asc');
const currentPage = ref(1);
const perPage = ref(10);

const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const inspectingRule = ref<ProcurementAssignmentRuleRecord | null>(null);
const isDetailNotesOpen = ref(false);

// ─── Quick Create / Edit Modal State ───
const showQuickModal = ref(false);
const editingRuleId = ref<number | null>(null);
const quickFieldErrors = ref<{
  procurement_unit_id?: string;
  minimum_amount?: string;
  maximum_amount?: string;
  effective_from?: string;
}>({});

const quickForm = ref({
  procurement_unit_id: '',
  default_buyer_employee_id: '',
  procurement_category_id: '',
  origin_lookup_value_id: '' as SourcingOrigin | '',
  minimum_amount: 0,
  maximum_amount: null as number | null,
  is_unlimited: true,
  priority: 1,
  effective_from: new Date().toISOString().split('T')[0],
  requesting_entity_id: '',
  notes: ''
});

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3) ───
const breadcrumbItems = computed<BreadcrumbItem[]>(() => {
  if (inspectingRule.value) {
    return [
      {
        label: 'Assignment Rules',
        to: '/procurement/assignment-rules',
        onClick: () => {
          inspectingRule.value = null;
        }
      },
      { label: `${inspectingRule.value.unit_name} — Rule #${inspectingRule.value.id}` }
    ];
  }
  return [{ label: 'Assignment Rules' }];
});

// ─── Atomic Columns & Column Hider (AGENTS.md Rule 9) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'assigned_unit', label: 'Buying Desk', visible: true, sortable: true, hideable: false },
  { key: 'default_buyer', label: 'Default Buyer', visible: true, sortable: true },
  { key: 'category', label: 'Spend Category', visible: true, sortable: true },
  { key: 'origin', label: 'Sourcing Origin', visible: false, sortable: true },
  { key: 'floor_amount', label: 'Floor Amount', visible: false, sortable: true },
  { key: 'ceiling_amount', label: 'Ceiling Amount', visible: true, sortable: true },
  { key: 'requesting_entity', label: 'Requesting Branch', visible: false, sortable: true },
  { key: 'priority', label: 'Priority', visible: true, sortable: true },
  { key: 'validity', label: 'Validity Period', visible: false, sortable: false },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

const sortOptions: SortOption[] = [
  { key: 'priority', label: 'Priority (Highest First)' },
  { key: 'assigned_unit', label: 'Buying Desk' },
  { key: 'default_buyer', label: 'Default Buyer' },
  { key: 'floor_amount', label: 'Floor Amount' },
  { key: 'ceiling_amount', label: 'Ceiling Amount' },
  { key: 'state', label: 'State' }
];

const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find((c) => c.key === key);
  return col ? col.visible !== false : true;
};

const visibleColumnCount = computed(() => {
  return tableColumns.value.filter((c) => c.visible !== false).length;
});

const handleToggleColumn = (colKey: string) => {
  const col = tableColumns.value.find((c) => c.key === colKey);
  if (col && col.hideable !== false) {
    col.visible = !col.visible;
  }
};

// ─── Filter Counts & Reset ───
const activeFilterCount = computed(() => {
  let count = 0;
  if (filterUnit.value) count++;
  if (filterBuyer.value) count++;
  if (filterCategory.value) count++;
  if (filterOrigin.value) count++;
  if (filterRequestingEntity.value) count++;
  if (filterState.value) count++;
  return count;
});

const resetFilters = () => {
  filterUnit.value = '';
  filterBuyer.value = '';
  filterCategory.value = '';
  filterOrigin.value = '';
  filterRequestingEntity.value = '';
  filterState.value = '';
  currentPage.value = 1;
};

watch(
  [searchQuery, filterUnit, filterBuyer, filterCategory, filterOrigin, filterRequestingEntity, filterState],
  () => {
    currentPage.value = 1;
  }
);

// ─── Filter & Sorting Pipeline ───
const filteredRules = computed(() => {
  let rows = [...assignmentRulesStore.value];

  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase().trim();
    rows = rows.filter((r) =>
      r.unit_name.toLowerCase().includes(q) ||
      (r.buyer_name && r.buyer_name.toLowerCase().includes(q)) ||
      (r.category_name && r.category_name.toLowerCase().includes(q)) ||
      (r.requesting_entity_name && r.requesting_entity_name.toLowerCase().includes(q)) ||
      (r.notes && r.notes.toLowerCase().includes(q))
    );
  }

  if (filterUnit.value) {
    rows = rows.filter((r) => String(r.procurement_unit_id) === filterUnit.value);
  }
  if (filterBuyer.value) {
    rows = rows.filter((r) => String(r.default_buyer_employee_id) === filterBuyer.value);
  }
  if (filterCategory.value) {
    rows = rows.filter((r) => String(r.procurement_category_id) === filterCategory.value);
  }
  if (filterOrigin.value) {
    rows = rows.filter((r) => r.origin_lookup_value_id === filterOrigin.value);
  }
  if (filterRequestingEntity.value) {
    rows = rows.filter((r) => String(r.requesting_entity_id) === filterRequestingEntity.value);
  }
  if (filterState.value) {
    rows = rows.filter((r) => r.state === filterState.value);
  }

  rows.sort((a, b) => {
    let valA: string | number = '';
    let valB: string | number = '';
    switch (currentSort.value) {
      case 'priority':
        valA = a.priority;
        valB = b.priority;
        break;
      case 'assigned_unit':
        valA = a.unit_name.toLowerCase();
        valB = b.unit_name.toLowerCase();
        break;
      case 'default_buyer':
        valA = (a.buyer_name || '').toLowerCase();
        valB = (b.buyer_name || '').toLowerCase();
        break;
      case 'floor_amount':
        valA = a.minimum_amount;
        valB = b.minimum_amount;
        break;
      case 'ceiling_amount':
        valA = a.maximum_amount ?? Number.MAX_SAFE_INTEGER;
        valB = b.maximum_amount ?? Number.MAX_SAFE_INTEGER;
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

  return rows;
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
  const selectedCount = paginatedRules.value.filter((r) =>
    selectedRowIds.value.includes(r.id)
  ).length;
  return selectedCount > 0 && selectedCount < paginatedRules.value.length;
});

const toggleSelectAll = () => {
  const checked = !isAllSelected.value;
  if (checked) {
    const pageIds = paginatedRules.value.map((r) => r.id);
    selectedRowIds.value = Array.from(new Set([...selectedRowIds.value, ...pageIds]));
  } else {
    const pageIds = new Set(paginatedRules.value.map((r) => r.id));
    selectedRowIds.value = selectedRowIds.value.filter((id) => !pageIds.has(id));
  }
};

const toggleSelectRow = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx > -1) {
    selectedRowIds.value.splice(idx, 1);
  } else {
    selectedRowIds.value.push(id);
  }
};

// ─── Quick Create / Edit Actions ───
const openCreateModal = () => {
  editingRuleId.value = null;
  quickFieldErrors.value = {};
  quickForm.value = {
    procurement_unit_id: '',
    default_buyer_employee_id: '',
    procurement_category_id: '',
    origin_lookup_value_id: '',
    minimum_amount: 0,
    maximum_amount: null,
    is_unlimited: true,
    priority: 1,
    effective_from: new Date().toISOString().split('T')[0],
    requesting_entity_id: '',
    notes: ''
  };
  showQuickModal.value = true;
};

const openEditModal = (item: ProcurementAssignmentRuleRecord) => {
  editingRuleId.value = item.id;
  quickFieldErrors.value = {};
  quickForm.value = {
    procurement_unit_id: String(item.procurement_unit_id),
    default_buyer_employee_id: item.default_buyer_employee_id ? String(item.default_buyer_employee_id) : '',
    procurement_category_id: item.procurement_category_id ? String(item.procurement_category_id) : '',
    origin_lookup_value_id: item.origin_lookup_value_id || '',
    minimum_amount: item.minimum_amount,
    maximum_amount: item.maximum_amount,
    is_unlimited: item.maximum_amount === null,
    priority: item.priority,
    effective_from: item.effective_from,
    requesting_entity_id: item.requesting_entity_id ? String(item.requesting_entity_id) : '',
    notes: item.notes || ''
  };
  showQuickModal.value = true;
  closeActionMenu();
};

const handleSaveQuick = () => {
  const errors: typeof quickFieldErrors.value = {};
  const missingLabels: string[] = [];

  if (!quickForm.value.procurement_unit_id) {
    errors.procurement_unit_id = 'Assigned Buying Desk is required.';
    missingLabels.push('Assigned Buying Desk');
  }
  if (!quickForm.value.effective_from) {
    errors.effective_from = 'Effective From date is required.';
    missingLabels.push('Effective From');
  }
  if (quickForm.value.minimum_amount < 0) {
    errors.minimum_amount = 'Floor amount cannot be negative.';
    missingLabels.push('Valid Floor Amount');
  }
  if (!quickForm.value.is_unlimited && quickForm.value.maximum_amount !== null) {
    if (quickForm.value.maximum_amount < quickForm.value.minimum_amount) {
      errors.maximum_amount = 'Ceiling amount must exceed floor amount.';
      missingLabels.push('Ceiling > Floor');
    }
  }

  quickFieldErrors.value = errors;

  if (missingLabels.length > 0) {
    toast.error(
      'Please fill in all required fields',
      `Missing: ${missingLabels.join(', ')}.`
    );
    return;
  }

  const selectedUnit = unitOptions.find((u) => u.value === quickForm.value.procurement_unit_id);
  const buyerId = quickForm.value.default_buyer_employee_id ? Number(quickForm.value.default_buyer_employee_id) : null;
  const buyerName = buyerId ? getBuyerName(buyerId) : undefined;
  const buyerAvatar = buyerId ? getBuyerAvatar(buyerId) : undefined;
  const categoryId = quickForm.value.procurement_category_id ? Number(quickForm.value.procurement_category_id) : null;
  const categoryName = categoryId ? getCategoryName(categoryId) : undefined;
  const requestingEntityId = quickForm.value.requesting_entity_id ? Number(quickForm.value.requesting_entity_id) : null;
  const requestingEntityName = requestingEntityId ? getEntityName(requestingEntityId) : 'All Branches (Enterprise)';
  const ceiling = quickForm.value.is_unlimited ? null : quickForm.value.maximum_amount;
  const origin = quickForm.value.origin_lookup_value_id ? (quickForm.value.origin_lookup_value_id as SourcingOrigin) : null;

  if (editingRuleId.value) {
    const idx = assignmentRulesStore.value.findIndex((r) => r.id === editingRuleId.value);
    if (idx !== -1) {
      const existing = assignmentRulesStore.value[idx];
      assignmentRulesStore.value[idx] = {
        ...existing,
        procurement_unit_id: Number(quickForm.value.procurement_unit_id),
        unit_name: selectedUnit?.label ?? `Buying Unit #${quickForm.value.procurement_unit_id}`,
        default_buyer_employee_id: buyerId,
        buyer_name: buyerName,
        buyer_avatar: buyerAvatar,
        procurement_category_id: categoryId,
        category_name: categoryName,
        origin_lookup_value_id: origin,
        minimum_amount: Number(quickForm.value.minimum_amount),
        maximum_amount: ceiling,
        priority: Number(quickForm.value.priority),
        effective_from: quickForm.value.effective_from,
        requesting_entity_id: requestingEntityId,
        requesting_entity_name: requestingEntityName,
        notes: quickForm.value.notes.trim()
      };
      if (inspectingRule.value?.id === existing.id) {
        inspectingRule.value = assignmentRulesStore.value[idx];
      }
      toast.success('Assignment rule updated', `Rule #${existing.id} has been modified.`);
    }
  } else {
    const nextId = Math.max(0, ...assignmentRulesStore.value.map((r) => r.id)) + 1;
    assignmentRulesStore.value.unshift({
      id: nextId,
      uuid: `par-${String(nextId).padStart(4, '0')}-custom`,
      procurement_unit_id: Number(quickForm.value.procurement_unit_id),
      unit_name: selectedUnit?.label ?? `Buying Unit #${quickForm.value.procurement_unit_id}`,
      default_buyer_employee_id: buyerId,
      buyer_name: buyerName,
      buyer_avatar: buyerAvatar,
      procurement_category_id: categoryId,
      category_name: categoryName,
      origin_lookup_value_id: origin,
      purchase_method_id: null,
      minimum_amount: Number(quickForm.value.minimum_amount),
      maximum_amount: ceiling,
      currency_code: 'ETB',
      priority: Number(quickForm.value.priority),
      requesting_entity_id: requestingEntityId,
      requesting_entity_name: requestingEntityName,
      entity_id: 2,
      effective_from: quickForm.value.effective_from,
      effective_to: null,
      notes: quickForm.value.notes.trim(),
      state: 'active'
    });
    toast.success('Assignment rule created', `New assignment rule registered for ${selectedUnit?.code ?? ''}.`);
  }

  showQuickModal.value = false;
};

const handleExpandFullForm = () => {
  showQuickModal.value = false;
  router.push({
    path: '/procurement/assignment-rules/create',
    query: {
      procurement_unit_id: quickForm.value.procurement_unit_id || undefined,
      default_buyer_employee_id: quickForm.value.default_buyer_employee_id || undefined,
      procurement_category_id: quickForm.value.procurement_category_id || undefined,
      origin_lookup_value_id: quickForm.value.origin_lookup_value_id || undefined,
      minimum_amount: quickForm.value.minimum_amount !== undefined ? String(quickForm.value.minimum_amount) : undefined,
      maximum_amount: quickForm.value.maximum_amount !== null ? String(quickForm.value.maximum_amount) : undefined,
      is_unlimited: quickForm.value.is_unlimited ? '1' : '0',
      priority: String(quickForm.value.priority),
      effective_from: quickForm.value.effective_from || undefined,
      requesting_entity_id: quickForm.value.requesting_entity_id || undefined
    }
  });
};

// ─── Row Actions & Detail View ───
const toggleActionMenu = (id: number) => {
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
};

const openDetailView = (item: ProcurementAssignmentRuleRecord) => {
  inspectingRule.value = item;
  isDetailNotesOpen.value = false;
  activeActionMenuId.value = null;
};

const handleToggleState = (item: ProcurementAssignmentRuleRecord) => {
  item.state = item.state === 'active' ? 'inactive' : 'active';
  toast.success(
    'Rule State Updated',
    `Marked assignment rule #${item.id} as ${item.state === 'active' ? 'Active' : 'Inactive'}.`
  );
  closeActionMenu();
};

const handleDelete = (item: ProcurementAssignmentRuleRecord) => {
  const idx = assignmentRulesStore.value.findIndex((r) => r.id === item.id);
  if (idx !== -1) {
    assignmentRulesStore.value.splice(idx, 1);
    selectedRowIds.value = selectedRowIds.value.filter((id) => id !== item.id);
    if (inspectingRule.value?.id === item.id) {
      inspectingRule.value = null;
    }
    toast.success('Assignment rule deleted', `Rule #${item.id} has been removed.`);
  }
  closeActionMenu();
};

// ─── Bulk Floating Bar Actions ───
const handleBulkActivate = () => {
  assignmentRulesStore.value.forEach((r) => {
    if (selectedRowIds.value.includes(r.id)) {
      r.state = 'active';
    }
  });
  toast.success('Bulk Update', `Activated ${selectedRowIds.value.length} assignment rules.`);
  selectedRowIds.value = [];
};

const handleBulkDeactivate = () => {
  assignmentRulesStore.value.forEach((r) => {
    if (selectedRowIds.value.includes(r.id)) {
      r.state = 'inactive';
    }
  });
  toast.success('Bulk Update', `Deactivated ${selectedRowIds.value.length} assignment rules.`);
  selectedRowIds.value = [];
};

const handleBulkDelete = () => {
  assignmentRulesStore.value = assignmentRulesStore.value.filter(
    (r) => !selectedRowIds.value.includes(r.id)
  );
  toast.success('Bulk Delete', `Deleted ${selectedRowIds.value.length} assignment rules.`);
  selectedRowIds.value = [];
};

// Global click outside to dismiss kebab menu
const handleDocumentClick = (e: MouseEvent) => {
  const target = e.target as HTMLElement | null;
  if (!target?.closest('.action-menu-container')) {
    activeActionMenuId.value = null;
  }
};

onMounted(() => {
  document.addEventListener('click', handleDocumentClick);
});

onUnmounted(() => {
  document.removeEventListener('click', handleDocumentClick);
});

// Priority badge color helper (indigo for 1, blue for 2, purple for 3, gray for 4+)
const getPriorityBadgeColor = (p: number): BadgeColor => {
  if (p === 1) return 'indigo';
  if (p === 2) return 'blue';
  if (p === 3) return 'purple';
  return 'gray';
};
</script>

<template>
  <div class="assignment-rules-view">
    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- BREADCRUMB ROW (AGENTS.md: Zero Background Card Standard)      -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div class="breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- INSPECTION DOSSIER CARD (Clean White Dossier on Canvas)        -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-if="inspectingRule" class="detail-view-wrapper">
      <div class="detail-card">
        <div class="detail-header-row">
          <div>
            <h2 class="detail-title">{{ inspectingRule.unit_name }}</h2>
            <span class="detail-code">UUID: {{ inspectingRule.uuid }}</span>
          </div>
          <div class="detail-badges">
            <BaseBadge size="sm" :color="getPriorityBadgeColor(inspectingRule.priority)">
              Priority {{ inspectingRule.priority }} ({{ inspectingRule.priority === 1 ? 'Highest' : 'Standard' }})
            </BaseBadge>
            <BaseBadge
              size="sm"
              :color="inspectingRule.state === 'active' ? 'success' : 'gray'"
            >
              {{ inspectingRule.state === 'active' ? 'Active' : 'Inactive' }}
            </BaseBadge>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Assigned Buying Desk</span>
            <span class="detail-value text-bold">{{ inspectingRule.unit_name }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Default Assigned Buyer</span>
            <div class="buyer-profile-inline">
              <BaseAvatar
                v-if="inspectingRule.default_buyer_employee_id"
                :src="inspectingRule.buyer_avatar"
                :name="inspectingRule.buyer_name || 'Buyer'"
                size="sm"
              />
              <span class="detail-value" :class="{ 'text-bold': inspectingRule.default_buyer_employee_id }">
                {{ inspectingRule.buyer_name || 'Unassigned (Desk Lead Dispatches)' }}
              </span>
            </div>
          </div>
          <div class="detail-field">
            <span class="detail-label">Precedence Priority</span>
            <span class="detail-value">Priority {{ inspectingRule.priority }} (Lowest wins on tie)</span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <!-- Scope & Origin Rules -->
        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Spend Category Scope</span>
            <span class="detail-value">{{ getCategoryName(inspectingRule.procurement_category_id) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Sourcing Origin</span>
            <span class="detail-value">{{ getOriginLabel(inspectingRule.origin_lookup_value_id) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Requesting Branch / Entity</span>
            <span class="detail-value">{{ inspectingRule.requesting_entity_name || 'All Branches (Enterprise)' }}</span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <!-- Value Threshold Parameters -->
        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Minimum Floor Requisition Value</span>
            <span class="detail-value text-bold">{{ formatCurrency(inspectingRule.minimum_amount) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Maximum Ceiling Requisition Value</span>
            <span class="detail-value text-bold">
              {{ inspectingRule.maximum_amount !== null ? formatCurrency(inspectingRule.maximum_amount) : 'Unlimited (Open Ceiling)' }}
            </span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Purchase Method Restriction</span>
            <span class="detail-value">{{ getMethodName(inspectingRule.purchase_method_id) }}</span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <!-- Validity Dates -->
        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Effective From</span>
            <span class="detail-value">{{ formatDisplayDate(inspectingRule.effective_from) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Effective To</span>
            <span class="detail-value">{{ formatDisplayDate(inspectingRule.effective_to, 'Open-ended (No expiry)') }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Rule Identification ID</span>
            <span class="detail-value">#{{ inspectingRule.id }}</span>
          </div>
        </div>
      </div>

      <!-- Collapsible Operational Rationale & Sourcing Memo Card -->
      <div class="clean-card accordion-card">
        <div
          class="card-accordion-header"
          :class="{ 'is-collapsed': !isDetailNotesOpen }"
          @click="isDetailNotesOpen = !isDetailNotesOpen"
        >
          <span>Sourcing Guidelines & Operational Memo</span>
          <ChevronDown v-if="isDetailNotesOpen" :size="16" class="header-chevron" />
          <ChevronRight v-else :size="16" class="header-chevron" />
        </div>
        <div v-show="isDetailNotesOpen" class="card-accordion-body">
          <p class="detail-description">
            {{ inspectingRule.notes || 'No specific sourcing instructions documented for this assignment rule.' }}
          </p>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- DIRECTORY VIEW: METRIC CARDS + APPDATATABLE                     -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <template v-else>
      <!-- Top 4 Summary KPI Metric Cards (Figma 10178:31133 Standard) -->
      <div class="metrics-grid">
        <MetricCard
          label="TOTAL RULES"
          :value="assignmentRulesStore.length"
          subtext="Configured assignment policies"
          :icon="GitPullRequest"
          :show-menu="false"
        />
        <MetricCard
          label="ACTIVE RULES"
          :value="assignmentRulesStore.filter((r) => r.state === 'active').length"
          subtext="Currently dispatching requisitions"
          :icon="ShieldCheck"
          :show-menu="false"
        />
        <MetricCard
          label="LOCAL SOURCING RULES"
          :value="assignmentRulesStore.filter((r) => r.origin_lookup_value_id === 'local').length"
          subtext="Domestic market fulfillment"
          :icon="Building2"
          :show-menu="false"
        />
        <MetricCard
          label="IMPORT / CROSS-BORDER"
          :value="assignmentRulesStore.filter((r) => r.origin_lookup_value_id === 'foreign').length"
          subtext="Customs clearance & LC financing"
          :icon="Globe"
          :show-menu="false"
        />
      </div>

      <!-- Master Data Table Card -->
      <AppDataTable
        title="Procurement Assignment Rules"
        subtitle="Automatic requisition routing rules directing approved purchase demand to designated buying desks and default buyers by category, origin, value thresholds, and branch entity."
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search rules, buyers, desks, categories..."
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
        <!-- Primary Action inside Toolbar: Direct to Full Create Page (Full Information Standard) -->
        <template #actions>
          <AppButton variant="primary" size="sm" @click="() => router.push('/procurement/assignment-rules/create')">
            <template #icon-left>
              <Plus :size="15" />
            </template>
            Create Assignment Rule
          </AppButton>
        </template>

        <!-- Filter Popover Panel -->
        <template #filter-panel>
          <div class="filter-panel-grid">
            <FormSelect
              label="Assigned Buying Desk"
              v-model="filterUnit"
              :options="[{ value: '', label: 'All Buying Desks' }, ...unitOptions]"
              placeholder="Select Buying Desk"
            />
            <FormSelect
              label="Default Buyer"
              v-model="filterBuyer"
              :options="[{ value: '', label: 'All Buyers' }, ...buyerOptions]"
              placeholder="Select Buyer"
            />
            <FormSelect
              label="Spend Category"
              v-model="filterCategory"
              :options="categoryScopeOptions"
              placeholder="Select Category"
            />
            <FormSelect
              label="Sourcing Origin"
              v-model="filterOrigin"
              :options="originOptions"
              placeholder="Select Origin"
            />
            <FormSelect
              label="Requesting Branch"
              v-model="filterRequestingEntity"
              :options="requestingEntityOptions"
              placeholder="Select Entity"
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

        <!-- Table Content -->
        <table class="erp-table">
          <thead>
            <tr>
              <th
                v-if="isColumnVisible('assigned_unit')"
                class="sortable"
                @click="handleSortColumn('assigned_unit')"
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
                  <span>Assigned Buying Desk</span>
                  <ArrowUpDown v-if="currentSort === 'assigned_unit'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('default_buyer')"
                class="sortable"
                @click="handleSortColumn('default_buyer')"
              >
                <div class="th-content">
                  <span>Default Buyer</span>
                  <ArrowUpDown v-if="currentSort === 'default_buyer'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('category')"
                class="sortable"
                @click="handleSortColumn('category')"
              >
                <div class="th-content">
                  <span>Spend Category</span>
                  <ArrowUpDown v-if="currentSort === 'category'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('origin')"
                class="sortable"
                @click="handleSortColumn('origin')"
              >
                <div class="th-content">
                  <span>Origin</span>
                  <ArrowUpDown v-if="currentSort === 'origin'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('floor_amount')"
                class="sortable"
                @click="handleSortColumn('floor_amount')"
              >
                <div class="th-content">
                  <span>Floor Amount</span>
                  <ArrowUpDown v-if="currentSort === 'floor_amount'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('ceiling_amount')"
                class="sortable"
                @click="handleSortColumn('ceiling_amount')"
              >
                <div class="th-content">
                  <span>Ceiling Amount</span>
                  <ArrowUpDown v-if="currentSort === 'ceiling_amount'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('requesting_entity')"
                class="sortable"
                @click="handleSortColumn('requesting_entity')"
              >
                <div class="th-content">
                  <span>Requesting Branch</span>
                  <ArrowUpDown v-if="currentSort === 'requesting_entity'" :size="12" class="sort-icon active-sort" />
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

              <th v-if="isColumnVisible('validity')">
                <div class="th-content"><span>Validity</span></div>
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
            <tr v-if="paginatedRules.length === 0">
              <td :colspan="visibleColumnCount" class="empty-state-cell">
                <div class="empty-state-container">
                  <GitPullRequest :size="32" class="empty-state-icon" />
                  <p class="empty-state-title">No assignment rules found</p>
                  <p class="empty-state-subtext">Adjust your search or filters, or create a new assignment rule.</p>
                </div>
              </td>
            </tr>

            <tr
              v-for="item in paginatedRules"
              :key="item.id"
              class="erp-row"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
              @click="openDetailView(item)"
            >
              <!-- Identity Column: Buying Desk Name + ID Subtext -->
              <td v-if="isColumnVisible('assigned_unit')" class="td-name">
                <div class="name-cell-content">
                  <FormCheckbox
                    :model-value="selectedRowIds.includes(item.id)"
                    size="md"
                    @click.stop
                    @update:model-value="() => toggleSelectRow(item.id)"
                  >
                    <span class="sr-only">Select rule #{{ item.id }}</span>
                  </FormCheckbox>
                  <div class="name-cell-stack">
                    <span class="table-name-primary">{{ item.unit_name }}</span>
                    <span class="table-code-subtext">Rule #{{ item.id }} · {{ item.uuid.slice(0, 12) }}...</span>
                  </div>
                </div>
              </td>

              <!-- Default Buyer Cell with Avatar -->
              <td v-if="isColumnVisible('default_buyer')">
                <div v-if="item.default_buyer_employee_id" class="buyer-table-cell">
                  <BaseAvatar
                    :src="item.buyer_avatar"
                    :name="item.buyer_name || 'Buyer'"
                    size="xs"
                  />
                  <span class="table-buyer-name">{{ item.buyer_name }}</span>
                </div>
                <span v-else class="tertiary-italic">Unassigned (Desk Lead)</span>
              </td>

              <!-- Spend Category -->
              <td v-if="isColumnVisible('category')">
                <span :class="item.category_name ? 'table-category-text' : 'tertiary-plain-text'">
                  {{ item.category_name || 'All Categories (Global)' }}
                </span>
              </td>

              <!-- Sourcing Origin Badge -->
              <td v-if="isColumnVisible('origin')">
                <BaseBadge
                  v-if="item.origin_lookup_value_id === 'foreign'"
                  size="sm"
                  color="blue"
                >
                  Foreign / Import
                </BaseBadge>
                <BaseBadge
                  v-else-if="item.origin_lookup_value_id === 'local'"
                  size="sm"
                  color="indigo"
                >
                  Local Market
                </BaseBadge>
                <span v-else class="tertiary-plain-text">All Origins</span>
              </td>

              <!-- Floor Amount -->
              <td v-if="isColumnVisible('floor_amount')">
                <span class="td-amount-bold">{{ formatCurrency(item.minimum_amount) }}</span>
              </td>

              <!-- Ceiling Amount -->
              <td v-if="isColumnVisible('ceiling_amount')">
                <span v-if="item.maximum_amount !== null" class="td-amount-bold">
                  {{ formatCurrency(item.maximum_amount) }}
                </span>
                <BaseBadge v-else size="sm" color="blue">
                  Unlimited
                </BaseBadge>
              </td>

              <!-- Requesting Branch / Entity -->
              <td v-if="isColumnVisible('requesting_entity')">
                <span class="tertiary-plain-text">
                  {{ item.requesting_entity_name || 'All Branches (Enterprise)' }}
                </span>
              </td>

              <!-- Priority Badge -->
              <td v-if="isColumnVisible('priority')">
                <BaseBadge size="sm" :color="getPriorityBadgeColor(item.priority)">
                  Priority {{ item.priority }}
                </BaseBadge>
              </td>

              <!-- Validity Period -->
              <td v-if="isColumnVisible('validity')">
                <span class="tertiary-plain-text">
                  {{ formatDisplayDateRange(item.effective_from, item.effective_to, 'Open') }}
                </span>
              </td>

              <!-- State Badge -->
              <td v-if="isColumnVisible('state')">
                <BaseBadge
                  size="sm"
                  :color="item.state === 'active' ? 'success' : 'gray'"
                >
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </BaseBadge>
              </td>

              <!-- Row 3-Dots Action Menu -->
              <td v-if="isColumnVisible('actions')" class="col-actions" @click.stop>
                <div class="action-menu-container">
                  <button
                    type="button"
                    class="btn-action-dots"
                    @click.stop="toggleActionMenu(item.id)"
                    aria-label="Actions"
                  >
                    <MoreVertical :size="14" />
                  </button>

                  <div v-if="activeActionMenuId === item.id" class="action-dropdown-menu">
                    <button
                      type="button"
                      class="dropdown-menu-item"
                      @click="openDetailView(item)"
                    >
                      <Eye :size="14" class="menu-item-icon" />
                      <span>View Rule Details</span>
                    </button>
                    <button
                      type="button"
                      class="dropdown-menu-item"
                      @click="openEditModal(item)"
                    >
                      <Edit2 :size="14" class="menu-item-icon" />
                      <span>Quick Edit Rule</span>
                    </button>
                    <button
                      type="button"
                      class="dropdown-menu-item"
                      @click="() => { closeActionMenu(); router.push({ path: '/procurement/assignment-rules/create', query: { editId: item.id } }); }"
                    >
                      <Layers :size="14" class="menu-item-icon" />
                      <span>Full Editor Mode</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button
                      type="button"
                      class="dropdown-menu-item"
                      @click="handleToggleState(item)"
                    >
                      <Check :size="14" class="menu-item-icon" />
                      <span>{{ item.state === 'active' ? 'Deactivate Rule' : 'Activate Rule' }}</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button
                      type="button"
                      class="dropdown-menu-item text-danger"
                      @click="handleDelete(item)"
                    >
                      <Trash2 :size="14" class="menu-item-icon" />
                      <span>Delete Rule</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </AppDataTable>
    </template>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- QUICK CREATE / EDIT MODAL (Rule 18 & Rule 31)                  -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <QuickCreateModal
      v-model:isOpen="showQuickModal"
      :title="editingRuleId ? 'Edit Assignment Rule' : 'Create Assignment Rule'"
      :subtitle="editingRuleId ? 'Modify buying desk routing, default buyer, and sourcing eligibility parameters.' : 'Automatically dispatch approved purchase demand to the responsible buying desk and buyer.'"
      :confirmText="editingRuleId ? 'Save Changes' : 'Create Rule'"
      :showExpandButton="!editingRuleId"
      @confirm="handleSaveQuick"
      @cancel="() => (showQuickModal = false)"
      @expand="handleExpandFullForm"
    >
      <div class="modal-form-stack">
        <div class="modal-form-row">
          <FormSelect
            v-model="quickForm.procurement_unit_id"
            label="Assigned Buying Desk"
            :options="unitOptions"
            placeholder="Select Buying Desk"
            :error="quickFieldErrors.procurement_unit_id"
            required
          />

          <FormSelect
            v-model="quickForm.default_buyer_employee_id"
            label="Default Assigned Buyer"
            :options="buyerOptions"
            placeholder="Select Buyer"
          />
        </div>

        <div class="modal-form-row">
          <FormSelect
            v-model="quickForm.procurement_category_id"
            label="Spend Category"
            :options="categoryScopeOptions"
            placeholder="Select Category"
          />

          <FormSelect
            v-model.number="quickForm.priority"
            label="Precedence Priority"
            :options="priorityOptions"
            placeholder="Select Priority"
            required
          />
        </div>

        <div class="modal-form-row">
          <FormInput
            v-model.number="quickForm.minimum_amount"
            type="number"
            label="Minimum Floor Amount (ETB)"
            :error="quickFieldErrors.minimum_amount"
            required
          />

          <FormInput
            v-model="quickForm.effective_from"
            type="date"
            label="Effective From"
            :error="quickFieldErrors.effective_from"
            required
          />
        </div>

        <FormCheckboxCard
          v-model="quickForm.is_unlimited"
          :expand-when-checked="false"
          label="Unlimited / Open Ceiling"
          description="Rule applies to all demand values exceeding the minimum floor without upper limit."
        >
          <FormInput
            v-model.number="quickForm.maximum_amount"
            type="number"
            label="Maximum Ceiling Amount (ETB)"
            :error="quickFieldErrors.maximum_amount"
            placeholder="Enter Ceiling"
            required
          />
        </FormCheckboxCard>
      </div>
    </QuickCreateModal>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- BULK ACTIONS FLOATING BAR (Rule 17)                            -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <TableFloatingBar
      v-model:selectedCount="selectedRowIds.length"
      @clear="() => (selectedRowIds = [])"
    >
      <AppButton variant="secondary-gray" size="sm" @click="handleBulkActivate">
        Activate Selected
      </AppButton>
      <AppButton variant="secondary-gray" size="sm" @click="handleBulkDeactivate">
        Deactivate Selected
      </AppButton>
      <AppButton variant="danger" size="sm" @click="handleBulkDelete">
        Delete Selected
      </AppButton>
    </TableFloatingBar>
  </div>
</template>

<style scoped>
.assignment-rules-view {
  display: flex;
  flex-direction: column;
  gap: 20px;
  width: 100%;
}

/* Breadcrumb Header Row on Transparent Canvas */
.breadcrumb-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: transparent;
  padding: 0;
  margin: 0;
}

/* 4 KPI Metrics Grid (Figma 10178:31133 Standard) */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
}

/* Filter Popover Panel Styles */
.filter-panel-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  padding: 16px;
}
.filter-panel-footer {
  display: flex;
  justify-content: flex-end;
  padding: 10px 16px;
  border-top: 1px solid #e5e5e5;
  background-color: #fafafa;
}

/* ERP Table Standards */
.erp-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
  font-size: 13px;
}

.erp-table thead tr {
  background-color: #fafafa;
  border-bottom: 1px solid #e5e5e5;
}

.erp-table th {
  padding: 12px 16px;
  font-size: 12px;
  font-weight: 600;
  color: #737373;
  letter-spacing: 0.02em;
  user-select: none;
}

.erp-table th.sortable {
  cursor: pointer;
}

.erp-table th.sortable:hover {
  color: #404040;
}

.th-content {
  display: flex;
  align-items: center;
  gap: 6px;
}

.name-header-content {
  gap: 12px;
}

.sort-icon {
  color: #a3a3a3;
}

.active-sort {
  color: #0b529c;
}

.erp-row {
  border-bottom: 1px solid #e5e5e5;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.erp-row:hover {
  background-color: #fafafa;
}

.erp-row.row-selected {
  background-color: #f0f7ff;
}

.erp-table td {
  padding: 14px 16px;
  vertical-align: middle;
}

/* Identity / Assigned Unit Cell */
.td-name {
  min-width: 220px;
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
  font-weight: 600;
  color: #404040;
  font-size: 13px;
}

.table-code-subtext {
  font-size: 11px;
  color: #737373;
  font-family: monospace;
}

.buyer-table-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.table-buyer-name {
  color: #404040;
  font-weight: 500;
  font-size: 13px;
}

.table-category-text {
  color: #404040;
  font-size: 13px;
  font-weight: 500;
}

.tertiary-plain-text {
  color: #737373;
  font-size: 13px;
}

.tertiary-italic {
  color: #737373;
  font-size: 12px;
  font-style: italic;
}

.td-amount-bold {
  font-weight: 600;
  color: #404040;
  font-size: 13px;
  white-space: nowrap;
}

/* Actions Column & Kebab Menu */
.col-actions {
  text-align: right;
  width: 60px;
}

.action-menu-container {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 6px;
  border-radius: 6px;
  color: #737373;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.15s ease, color 0.15s ease;
}

.btn-action-dots:hover {
  background-color: #f5f5f5;
  color: #404040;
}

.action-dropdown-menu {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
  z-index: 100;
  min-width: 190px;
  padding: 4px;
}

.dropdown-menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 12px;
  background: transparent;
  border: none;
  text-align: left;
  font-size: 13px;
  color: #404040;
  border-radius: 6px;
  cursor: pointer;
  transition: background-color 0.12s ease;
}

.dropdown-menu-item:hover {
  background-color: #f5f5f5;
}

.dropdown-menu-item.text-danger {
  color: #e7000b;
}

.dropdown-menu-item.text-danger:hover {
  background-color: #fee2e2;
}

.menu-item-icon {
  color: #737373;
}

.dropdown-menu-item.text-danger .menu-item-icon {
  color: #e7000b;
}

.dropdown-divider {
  height: 1px;
  background-color: #e5e5e5;
  margin: 4px 0;
}

/* Empty State */
.empty-state-cell {
  padding: 60px 16px;
  text-align: center;
}

.empty-state-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.empty-state-icon {
  color: #a3a3a3;
}

.empty-state-title {
  font-weight: 600;
  color: #404040;
  font-size: 14px;
  margin: 0;
}

.empty-state-subtext {
  font-size: 13px;
  color: #737373;
  margin: 0;
}

/* Modal Form Styles */
.modal-form-stack {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.modal-form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

/* Inspection Dossier Styles */
.detail-view-wrapper {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.detail-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.detail-header-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
}

.detail-title {
  font-size: 20px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}

.detail-code {
  font-size: 12px;
  color: #737373;
  font-family: monospace;
}

.detail-badges {
  display: flex;
  align-items: center;
  gap: 8px;
}

.detail-divider {
  height: 1px;
  background-color: #e5e5e5;
  width: 100%;
}

.detail-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}

.detail-field {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.detail-label {
  font-size: 12px;
  font-weight: 500;
  color: #737373;
}

.detail-value {
  font-size: 14px;
  color: #404040;
}

.detail-value.text-bold {
  font-weight: 600;
}

.buyer-profile-inline {
  display: flex;
  align-items: center;
  gap: 8px;
}

/* Accordion Description Card */
.clean-card.accordion-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  overflow: hidden;
}

.card-accordion-header {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 4px;
  padding: 16px 24px;
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  cursor: pointer;
  user-select: none;
  background-color: #ffffff;
  border-bottom: 1px solid #e5e5e5;
  transition: background-color 0.15s ease;
}

.card-accordion-header.is-collapsed {
  border-bottom: none;
}

.card-accordion-header:hover {
  background-color: #fafafa;
}

.header-chevron {
  color: #737373;
  flex-shrink: 0;
}

.card-accordion-body {
  padding: 20px 24px 24px;
  background-color: #ffffff;
}

.detail-description {
  font-size: 14px;
  line-height: 1.6;
  color: #404040;
  margin: 0;
}
</style>
