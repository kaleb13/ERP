<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, ArrowUpDown, MoreVertical, Eye, Edit2, Trash2,
  Route, ShieldCheck, FileText, ShoppingCart, ChevronDown, ChevronRight,
  Filter, Check, Layers, AlertCircle
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
import MetricCard from '../../components/MetricCard.vue';

import {
  approvalRoutesStore,
  type ProcurementApprovalRouteRecord,
  documentTypeOptions,
  workflowOptions,
  priorityOptions,
  categoryScopeOptions,
  methodScopeOptions,
  unitScopeOptions,
  entityOptions,
  formatCurrency,
  getDocumentTypeLabel,
  getWorkflowLabel,
  getCategoryLabel,
  getMethodLabel,
  getUnitLabel
} from './procurementApprovalRouteData';

const router = useRouter();
const { toast } = useToast();

// ─── View & Selection State ───
const searchQuery = ref('');
const filterDocType = ref('');
const filterWorkflow = ref('');
const filterPriority = ref('');
const filterCategory = ref('');
const filterState = ref('');
const currentSort = ref('priority');
const sortOrder = ref<'asc' | 'desc'>('asc');
const currentPage = ref(1);
const perPage = ref(10);

const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const inspectingRoute = ref<ProcurementApprovalRouteRecord | null>(null);
const isDetailNotesOpen = ref(false);

// ─── Quick Create / Edit Modal State ───
const showQuickModal = ref(false);
const editingRouteId = ref<number | null>(null);
const quickFieldErrors = ref<{
  document_type_id?: string;
  workflow_id?: string;
  minimum_amount?: string;
  maximum_amount?: string;
}>({});

const quickForm = ref({
  document_type_id: '',
  workflow_id: '',
  minimum_amount: 0,
  maximum_amount: null as number | null,
  is_unlimited: false,
  priority: 1,
  entity_id: '2',
  effective_from: new Date().toISOString().split('T')[0],
  notes: ''
});

// Filter workflows based on selected document type in quick form
const quickWorkflowOptions = computed(() => {
  if (!quickForm.value.document_type_id) {
    return workflowOptions;
  }
  const filtered = workflowOptions.filter((w) => w.docType === quickForm.value.document_type_id);
  return filtered.length > 0 ? filtered : workflowOptions;
});

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3) ───
const breadcrumbItems = computed<BreadcrumbItem[]>(() => {
  if (inspectingRoute.value) {
    return [
      {
        label: 'Approval Routes',
        to: '/procurement/approval-routes',
        onClick: () => {
          inspectingRoute.value = null;
        }
      },
      { label: `${inspectingRoute.value.document_type_id} — ${inspectingRoute.value.workflow_name}` }
    ];
  }
  return [{ label: 'Approval Routes' }];
});

// ─── Atomic Columns & Column Hider (AGENTS.md Rule 9) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'document_type', label: 'Document Type', visible: true, sortable: true, hideable: false },
  { key: 'workflow', label: 'Approval Workflow', visible: true, sortable: true },
  { key: 'floor_amount', label: 'Floor Amount', visible: false, sortable: true },
  { key: 'ceiling_amount', label: 'Ceiling Amount', visible: true, sortable: true },
  { key: 'priority', label: 'Priority', visible: true, sortable: true },
  { key: 'scope_summary', label: 'Scope Rules', visible: false, sortable: false },
  { key: 'validity', label: 'Validity Period', visible: false, sortable: false },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

const sortOptions: SortOption[] = [
  { key: 'priority', label: 'Priority (Highest First)' },
  { key: 'document_type', label: 'Document Type' },
  { key: 'workflow', label: 'Workflow' },
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
  if (filterDocType.value) count++;
  if (filterWorkflow.value) count++;
  if (filterPriority.value) count++;
  if (filterCategory.value) count++;
  if (filterState.value) count++;
  return count;
});

const resetFilters = () => {
  filterDocType.value = '';
  filterWorkflow.value = '';
  filterPriority.value = '';
  filterCategory.value = '';
  filterState.value = '';
  currentPage.value = 1;
};

watch(
  [searchQuery, filterDocType, filterWorkflow, filterPriority, filterCategory, filterState],
  () => {
    currentPage.value = 1;
  }
);

// ─── Filter & Sorting Pipeline ───
const filteredRoutes = computed(() => {
  let rows = [...approvalRoutesStore.value];

  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase().trim();
    rows = rows.filter((r) =>
      r.document_type_id.toLowerCase().includes(q) ||
      r.document_type_name.toLowerCase().includes(q) ||
      r.workflow_name.toLowerCase().includes(q) ||
      (r.notes && r.notes.toLowerCase().includes(q)) ||
      (r.category_name && r.category_name.toLowerCase().includes(q)) ||
      (r.method_name && r.method_name.toLowerCase().includes(q)) ||
      (r.unit_name && r.unit_name.toLowerCase().includes(q))
    );
  }

  if (filterDocType.value) {
    rows = rows.filter((r) => r.document_type_id === filterDocType.value);
  }
  if (filterWorkflow.value) {
    rows = rows.filter((r) => String(r.workflow_id) === filterWorkflow.value);
  }
  if (filterPriority.value) {
    rows = rows.filter((r) => String(r.priority) === filterPriority.value);
  }
  if (filterCategory.value) {
    rows = rows.filter((r) => String(r.procurement_category_id) === filterCategory.value);
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
      case 'document_type':
        valA = a.document_type_id;
        valB = b.document_type_id;
        break;
      case 'workflow':
        valA = a.workflow_name.toLowerCase();
        valB = b.workflow_name.toLowerCase();
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

const paginatedRoutes = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredRoutes.value.slice(start, start + perPage.value);
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
  if (paginatedRoutes.value.length === 0) return false;
  return paginatedRoutes.value.every((r) => selectedRowIds.value.includes(r.id));
});

const isPartiallySelected = computed(() => {
  const selectedCount = paginatedRoutes.value.filter((r) =>
    selectedRowIds.value.includes(r.id)
  ).length;
  return selectedCount > 0 && selectedCount < paginatedRoutes.value.length;
});

const toggleSelectAll = () => {
  const checked = !isAllSelected.value;
  if (checked) {
    const pageIds = paginatedRoutes.value.map((r) => r.id);
    selectedRowIds.value = Array.from(new Set([...selectedRowIds.value, ...pageIds]));
  } else {
    const pageIds = new Set(paginatedRoutes.value.map((r) => r.id));
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
  editingRouteId.value = null;
  quickFieldErrors.value = {};
  quickForm.value = {
    document_type_id: '',
    workflow_id: '',
    minimum_amount: 0,
    maximum_amount: null,
    is_unlimited: true,
    priority: 1,
    entity_id: '2',
    notes: ''
  };
  showQuickModal.value = true;
};

const openEditModal = (item: ProcurementApprovalRouteRecord) => {
  editingRouteId.value = item.id;
  quickFieldErrors.value = {};
  quickForm.value = {
    document_type_id: item.document_type_id,
    workflow_id: String(item.workflow_id),
    minimum_amount: item.minimum_amount,
    maximum_amount: item.maximum_amount,
    is_unlimited: item.maximum_amount === null,
    priority: item.priority,
    entity_id: String(item.entity_id),
    notes: item.notes || ''
  };
  showQuickModal.value = true;
  closeActionMenu();
};

const handleSaveQuick = () => {
  const errors: typeof quickFieldErrors.value = {};
  const missingLabels: string[] = [];

  if (!quickForm.value.document_type_id) {
    errors.document_type_id = 'Document Type is required.';
    missingLabels.push('Document Type');
  }
  if (!quickForm.value.workflow_id) {
    errors.workflow_id = 'Workflow is required.';
    missingLabels.push('Workflow');
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

  const selectedDocType = documentTypeOptions.find((d) => d.value === quickForm.value.document_type_id);
  const selectedWorkflow = workflowOptions.find((w) => w.value === quickForm.value.workflow_id);
  const ceiling = quickForm.value.is_unlimited ? null : quickForm.value.maximum_amount;

  if (editingRouteId.value) {
    const idx = approvalRoutesStore.value.findIndex((r) => r.id === editingRouteId.value);
    if (idx !== -1) {
      const existing = approvalRoutesStore.value[idx];
      approvalRoutesStore.value[idx] = {
        ...existing,
        document_type_id: quickForm.value.document_type_id,
        document_type_name: selectedDocType?.label ?? quickForm.value.document_type_id,
        workflow_id: Number(quickForm.value.workflow_id),
        workflow_name: selectedWorkflow?.label ?? `Workflow #${quickForm.value.workflow_id}`,
        minimum_amount: Number(quickForm.value.minimum_amount),
        maximum_amount: ceiling,
        priority: Number(quickForm.value.priority),
        notes: quickForm.value.notes.trim()
      };
      if (inspectingRoute.value?.id === existing.id) {
        inspectingRoute.value = approvalRoutesStore.value[idx];
      }
      toast.success('Approval route updated', `Route #${existing.id} has been modified.`);
    }
  } else {
    const nextId = Math.max(0, ...approvalRoutesStore.value.map((r) => r.id)) + 1;
    approvalRoutesStore.value.unshift({
      id: nextId,
      uuid: `par-${String(nextId).padStart(4, '0')}-custom`,
      document_type_id: quickForm.value.document_type_id,
      document_type_name: selectedDocType?.label ?? quickForm.value.document_type_id,
      workflow_id: Number(quickForm.value.workflow_id),
      workflow_name: selectedWorkflow?.label ?? `Workflow #${quickForm.value.workflow_id}`,
      minimum_amount: Number(quickForm.value.minimum_amount),
      maximum_amount: ceiling,
      currency_code: 'ETB',
      priority: Number(quickForm.value.priority),
      procurement_category_id: null,
      purchase_method_id: null,
      procurement_unit_id: null,
      effective_from: new Date().toISOString().split('T')[0],
      effective_to: null,
      entity_id: Number(quickForm.value.entity_id) || 2,
      notes: quickForm.value.notes.trim(),
      state: 'active'
    });
    toast.success('Approval route created', `New route for ${selectedDocType?.code ?? ''} registered successfully.`);
  }

  showQuickModal.value = false;
};

const handleExpandFullForm = () => {
  showQuickModal.value = false;
  router.push({
    path: '/procurement/approval-routes/create',
    query: {
      document_type_id: quickForm.value.document_type_id || undefined,
      workflow_id: quickForm.value.workflow_id || undefined,
      minimum_amount: quickForm.value.minimum_amount !== undefined ? String(quickForm.value.minimum_amount) : undefined,
      maximum_amount: quickForm.value.maximum_amount !== null ? String(quickForm.value.maximum_amount) : undefined,
      is_unlimited: quickForm.value.is_unlimited ? '1' : '0',
      priority: String(quickForm.value.priority)
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

const openDetailView = (item: ProcurementApprovalRouteRecord) => {
  inspectingRoute.value = item;
  isDetailNotesOpen.value = false;
  activeActionMenuId.value = null;
};

const handleToggleState = (item: ProcurementApprovalRouteRecord) => {
  item.state = item.state === 'active' ? 'inactive' : 'active';
  toast.success(
    'Route State Updated',
    `Marked route #${item.id} (${item.document_type_id}) as ${item.state === 'active' ? 'Active' : 'Inactive'}.`
  );
  closeActionMenu();
};

const handleDelete = (item: ProcurementApprovalRouteRecord) => {
  const idx = approvalRoutesStore.value.findIndex((r) => r.id === item.id);
  if (idx !== -1) {
    approvalRoutesStore.value.splice(idx, 1);
    selectedRowIds.value = selectedRowIds.value.filter((id) => id !== item.id);
    if (inspectingRoute.value?.id === item.id) {
      inspectingRoute.value = null;
    }
    toast.success('Approval route deleted', `Route #${item.id} has been removed.`);
  }
  closeActionMenu();
};

// ─── Bulk Floating Bar Actions ───
const handleBulkActivate = () => {
  approvalRoutesStore.value.forEach((r) => {
    if (selectedRowIds.value.includes(r.id)) {
      r.state = 'active';
    }
  });
  toast.success('Bulk Update', `Activated ${selectedRowIds.value.length} approval routes.`);
  selectedRowIds.value = [];
};

const handleBulkDeactivate = () => {
  approvalRoutesStore.value.forEach((r) => {
    if (selectedRowIds.value.includes(r.id)) {
      r.state = 'inactive';
    }
  });
  toast.success('Bulk Update', `Deactivated ${selectedRowIds.value.length} approval routes.`);
  selectedRowIds.value = [];
};

const handleBulkDelete = () => {
  approvalRoutesStore.value = approvalRoutesStore.value.filter(
    (r) => !selectedRowIds.value.includes(r.id)
  );
  toast.success('Bulk Delete', `Deleted ${selectedRowIds.value.length} approval routes.`);
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
  <div class="approval-routes-view">
    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- BREADCRUMB ROW (AGENTS.md: Zero Background Card Standard)      -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div class="breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- INSPECTION DOSSIER CARD (Clean White Dossier on Canvas)        -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-if="inspectingRoute" class="detail-view-wrapper">
      <div class="detail-card">
        <div class="detail-header-row">
          <div>
            <h2 class="detail-title">{{ inspectingRoute.document_type_name }}</h2>
            <span class="detail-code">UUID: {{ inspectingRoute.uuid }}</span>
          </div>
          <div class="detail-badges">
            <BaseBadge size="sm" :color="getPriorityBadgeColor(inspectingRoute.priority)">
              Priority {{ inspectingRoute.priority }} ({{ inspectingRoute.priority === 1 ? 'Highest' : 'Standard' }})
            </BaseBadge>
            <BaseBadge
              size="sm"
              :color="inspectingRoute.state === 'active' ? 'success' : 'gray'"
            >
              {{ inspectingRoute.state === 'active' ? 'Active' : 'Inactive' }}
            </BaseBadge>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Assigned Approval Workflow</span>
            <span class="detail-value text-bold">{{ inspectingRoute.workflow_name }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Precedence Priority</span>
            <span class="detail-value">Priority {{ inspectingRoute.priority }} (Lowest wins on tie)</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Owning Legal Entity</span>
            <span class="detail-value">Haleta General Hospital (Entity #{{ inspectingRoute.entity_id }})</span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <!-- Monetary Parameters -->
        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Minimum Floor Amount</span>
            <span class="detail-value text-bold">{{ formatCurrency(inspectingRoute.minimum_amount) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Maximum Ceiling Amount</span>
            <span class="detail-value text-bold">
              {{ inspectingRoute.maximum_amount !== null ? formatCurrency(inspectingRoute.maximum_amount) : 'Unlimited (Open Ceiling)' }}
            </span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Operating Currency</span>
            <span class="detail-value">{{ inspectingRoute.currency_code }}</span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <!-- Scope & Eligibility Rules -->
        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Procurement Category Scope</span>
            <span class="detail-value">{{ getCategoryLabel(inspectingRoute.procurement_category_id) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Purchase Method Scope</span>
            <span class="detail-value">{{ getMethodLabel(inspectingRoute.purchase_method_id) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Procurement Unit / Buying Desk</span>
            <span class="detail-value">{{ getUnitLabel(inspectingRoute.procurement_unit_id) }}</span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <!-- Validity Dates -->
        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Effective From</span>
            <span class="detail-value">{{ formatDisplayDate(inspectingRoute.effective_from) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Effective To</span>
            <span class="detail-value">{{ formatDisplayDate(inspectingRoute.effective_to, 'Open-ended (No expiry)') }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Route Identification ID</span>
            <span class="detail-value">#{{ inspectingRoute.id }}</span>
          </div>
        </div>
      </div>

      <!-- Collapsible Operational Rationale & Policy Notes Card -->
      <div class="clean-card accordion-card">
        <div
          class="card-accordion-header"
          :class="{ 'is-collapsed': !isDetailNotesOpen }"
          @click="isDetailNotesOpen = !isDetailNotesOpen"
        >
          <span>Policy Notes & Operational Rationale</span>
          <ChevronDown v-if="isDetailNotesOpen" :size="16" class="header-chevron" />
          <ChevronRight v-else :size="16" class="header-chevron" />
        </div>
        <div v-show="isDetailNotesOpen" class="card-accordion-body">
          <p class="detail-description">
            {{ inspectingRoute.notes || 'No specific routing rationale documented for this approval route.' }}
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
          label="TOTAL ROUTES"
          :value="approvalRoutesStore.length"
          subtext="Configured workflow policies"
          :icon="Route"
          :show-menu="false"
        />
        <MetricCard
          label="ACTIVE POLICIES"
          :value="approvalRoutesStore.filter((r) => r.state === 'active').length"
          subtext="Currently resolving documents"
          :icon="ShieldCheck"
          :show-menu="false"
        />
        <MetricCard
          label="REQUISITION RULES (PREQ)"
          :value="approvalRoutesStore.filter((r) => r.document_type_id === 'PREQ').length"
          subtext="Internal demand sign-off paths"
          :icon="FileText"
          :show-menu="false"
        />
        <MetricCard
          label="ORDER RULES (PO)"
          :value="approvalRoutesStore.filter((r) => r.document_type_id === 'PO').length"
          subtext="Commercial supplier commitment"
          :icon="ShoppingCart"
          :show-menu="false"
        />
      </div>

      <!-- Master Data Table Card -->
      <AppDataTable
        title="Approval Routes"
        subtitle="Dynamic matrix governing workflow resolution based on document type, monetary thresholds, procurement category, buying desk, and legal entity."
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search routes, workflows, notes..."
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
        :totalEntries="filteredRoutes.length"
        :showPagination="true"
        v-model:currentPage="currentPage"
        v-model:perPage="perPage"
        @toggleColumn="handleToggleColumn"
        @resetFilter="resetFilters"
      >
        <!-- Primary Action inside Toolbar: Direct to Full Create Page (Full Information Standard) -->
        <template #actions>
          <AppButton variant="primary" size="sm" @click="() => router.push('/procurement/approval-routes/create')">
            <template #icon-left>
              <Plus :size="15" />
            </template>
            Create Approval Route
          </AppButton>
        </template>

        <!-- Filter Popover Panel -->
        <template #filter-panel>
          <div class="filter-panel-grid">
            <FormSelect
              label="Document Type"
              v-model="filterDocType"
              :options="[{ value: '', label: 'All Document Types' }, ...documentTypeOptions]"
              placeholder="Select Type"
            />
            <FormSelect
              label="Workflow"
              v-model="filterWorkflow"
              :options="[{ value: '', label: 'All Workflows' }, ...workflowOptions]"
              placeholder="Select Workflow"
            />
            <FormSelect
              label="Priority"
              v-model="filterPriority"
              :options="[{ value: '', label: 'All Priorities' }, ...priorityOptions]"
              placeholder="Select Priority"
            />
            <FormSelect
              label="Category Scope"
              v-model="filterCategory"
              :options="[{ value: '', label: 'All Categories' }, ...categoryScopeOptions]"
              placeholder="Select Scope"
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
                v-if="isColumnVisible('document_type')"
                class="sortable"
                @click="handleSortColumn('document_type')"
              >
                <div class="th-content name-header-content">
                  <FormCheckbox
                    :model-value="isAllSelected"
                    :indeterminate="isPartiallySelected"
                    size="md"
                    @click.stop
                    @update:model-value="toggleSelectAll"
                  >
                    <span class="sr-only">Select all routes on this page</span>
                  </FormCheckbox>
                  <span>Document Type</span>
                  <ArrowUpDown v-if="currentSort === 'document_type'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('workflow')"
                class="sortable"
                @click="handleSortColumn('workflow')"
              >
                <div class="th-content">
                  <span>Approval Workflow</span>
                  <ArrowUpDown v-if="currentSort === 'workflow'" :size="12" class="sort-icon active-sort" />
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
                v-if="isColumnVisible('priority')"
                class="sortable"
                @click="handleSortColumn('priority')"
              >
                <div class="th-content">
                  <span>Priority</span>
                  <ArrowUpDown v-if="currentSort === 'priority'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th v-if="isColumnVisible('scope_summary')">
                <div class="th-content"><span>Scope Rules</span></div>
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
            <tr v-if="paginatedRoutes.length === 0">
              <td :colspan="visibleColumnCount" class="empty-state-cell">
                <div class="empty-state-container">
                  <Route :size="32" class="empty-state-icon" />
                  <p class="empty-state-title">No approval routes configured</p>
                  <p class="empty-state-subtext">Adjust your search or filters, or create a new route policy.</p>
                </div>
              </td>
            </tr>

            <tr
              v-for="item in paginatedRoutes"
              :key="item.id"
              class="erp-row"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
              @click="openDetailView(item)"
            >
              <!-- Identity Column: Selection Checkbox + Document Type + Code Subtext -->
              <td v-if="isColumnVisible('document_type')" class="td-name">
                <div class="name-cell-content">
                  <FormCheckbox
                    :model-value="selectedRowIds.includes(item.id)"
                    size="md"
                    @click.stop
                    @update:model-value="() => toggleSelectRow(item.id)"
                  >
                    <span class="sr-only">Select route #{{ item.id }}</span>
                  </FormCheckbox>
                  <div class="name-cell-stack">
                    <span class="table-name-primary">{{ item.document_type_name }}</span>
                    <span class="table-code-subtext">{{ item.document_type_id }} · #{{ item.id }}</span>
                  </div>
                </div>
              </td>

              <!-- Workflow Assignment -->
              <td v-if="isColumnVisible('workflow')">
                <span class="table-workflow-text">{{ item.workflow_name }}</span>
              </td>

              <!-- Minimum Floor -->
              <td v-if="isColumnVisible('floor_amount')">
                <span class="td-amount-bold">{{ formatCurrency(item.minimum_amount) }}</span>
              </td>

              <!-- Maximum Ceiling -->
              <td v-if="isColumnVisible('ceiling_amount')">
                <span v-if="item.maximum_amount !== null" class="td-amount-bold">
                  {{ formatCurrency(item.maximum_amount) }}
                </span>
                <BaseBadge v-else size="sm" color="blue">
                  Unlimited
                </BaseBadge>
              </td>

              <!-- Priority Badge -->
              <td v-if="isColumnVisible('priority')">
                <BaseBadge size="sm" :color="getPriorityBadgeColor(item.priority)">
                  Priority {{ item.priority }}
                </BaseBadge>
              </td>

              <!-- Scope Rules -->
              <td v-if="isColumnVisible('scope_summary')">
                <div class="scope-badges-cell">
                  <span v-if="!item.procurement_category_id && !item.purchase_method_id && !item.procurement_unit_id" class="scope-text-global">
                    Global Scope (All)
                  </span>
                  <template v-else>
                    <span v-if="item.category_name" class="scope-pill">Cat: {{ item.category_name }}</span>
                    <span v-if="item.method_name" class="scope-pill">Method: {{ item.method_name }}</span>
                    <span v-if="item.unit_name" class="scope-pill">Desk: {{ item.unit_name }}</span>
                  </template>
                </div>
              </td>

              <!-- Validity Window -->
              <td v-if="isColumnVisible('validity')">
                <span class="tertiary-plain-text">
                  {{ formatDisplayDateRange(item.effective_from, item.effective_to, 'Open') }}
                </span>
              </td>

              <!-- Lifecycle State Badge -->
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
                      <span>View Route Details</span>
                    </button>
                    <button
                      type="button"
                      class="dropdown-menu-item"
                      @click="openEditModal(item)"
                    >
                      <Edit2 :size="14" class="menu-item-icon" />
                      <span>Quick Edit Route</span>
                    </button>
                    <button
                      type="button"
                      class="dropdown-menu-item"
                      @click="() => { closeActionMenu(); router.push({ path: '/procurement/approval-routes/create', query: { editId: item.id } }); }"
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
                      <span>{{ item.state === 'active' ? 'Deactivate Route' : 'Activate Route' }}</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button
                      type="button"
                      class="dropdown-menu-item text-danger"
                      @click="handleDelete(item)"
                    >
                      <Trash2 :size="14" class="menu-item-icon" />
                      <span>Delete Route</span>
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
      :title="editingRouteId ? 'Edit Approval Route' : 'Create Approval Route'"
      :subtitle="editingRouteId ? 'Modify threshold amounts, precedence priority, and workflow dispatch target.' : 'Define routing parameters for automatic document dispatch based on value thresholds.'"
      :confirmText="editingRouteId ? 'Save Changes' : 'Create Route'"
      :showExpandButton="!editingRouteId"
      @confirm="handleSaveQuick"
      @cancel="() => (showQuickModal = false)"
      @expand="handleExpandFullForm"
    >
      <div class="modal-form-stack">
        <div class="modal-form-row">
          <FormSelect
            v-model="quickForm.document_type_id"
            label="Document Type"
            :options="documentTypeOptions"
            placeholder="Select Type"
            :error="quickFieldErrors.document_type_id"
            required
          />

          <FormSelect
            v-model="quickForm.workflow_id"
            label="Target Workflow"
            :options="quickWorkflowOptions"
            placeholder="Select Workflow"
            :error="quickFieldErrors.workflow_id"
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

          <FormSelect
            v-model.number="quickForm.priority"
            label="Precedence Priority"
            :options="priorityOptions"
            placeholder="Select Priority"
            required
          />
        </div>

        <FormInput
          v-model="quickForm.effective_from"
          type="date"
          label="Effective From"
          required
        />

        <FormCheckboxCard
          v-model="quickForm.is_unlimited"
          :expand-when-checked="false"
          label="Unlimited / Open Ceiling"
          description="No upper limit above the minimum floor amount."
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
.approval-routes-view {
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

/* Identity / Document Type Cell */
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

.table-workflow-text {
  color: #404040;
  font-size: 13px;
  font-weight: 500;
  max-width: 280px;
  display: inline-block;
  line-height: 1.3;
}

.td-amount-bold {
  font-weight: 600;
  color: #404040;
  font-size: 13px;
  white-space: nowrap;
}

.tertiary-plain-text {
  color: #737373;
  font-size: 13px;
}

/* Scope Rule Pill Badges */
.scope-badges-cell {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  align-items: center;
}

.scope-text-global {
  font-size: 12px;
  color: #737373;
  font-style: italic;
}

.scope-pill {
  font-size: 11px;
  background-color: #f5f5f5;
  color: #404040;
  padding: 2px 6px;
  border-radius: 4px;
  border: 1px solid #e5e5e5;
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
  gap: 16px;
}

.modal-checkbox-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px 16px;
  padding-top: 4px;
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
