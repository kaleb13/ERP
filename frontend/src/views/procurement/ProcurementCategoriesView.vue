<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, ArrowUpDown, MoreVertical, Eye, Edit2, Check, Trash2,
  FolderTree, ChevronDown, ChevronRight
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

const getGovernanceBadgeColor = (status: string): BadgeColor => {
  if (status === 'acceptForAll') return 'success';
  if (status === 'acceptForThis') return 'primary';
  if (status === 'pending') return 'warning';
  if (status === 'reject') return 'error';
  return 'gray';
};
import {
  procurementCategoriesStore,
  type ProcurementCategoryRecord,
  type SpendClass,
  type ReceiptMode,
  spendClassOptions,
  receiptModeOptions,
  itemCategoryOptions,
  getSpendClassLabel,
  getReceiptModeLabel,
  getGovernanceStatusLabel,
  getEntityName,
  getItemCategoryName,
  generateCategoryCode
} from './procurementCategoryData';

const router = useRouter();
const { toast } = useToast();

// ─── View & Selection State ───
const searchQuery = ref('');
const filterClass = ref('');
const filterReceiptMode = ref('');
const filterHierarchy = ref('');
const filterStatus = ref('');
const filterState = ref('');
const currentSort = ref('name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const currentPage = ref(1);
const perPage = ref(10);

const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const inspectingCategory = ref<ProcurementCategoryRecord | null>(null);
const isDetailDescriptionOpen = ref(false);

// ─── Quick Create / Edit Modal State ───
const showQuickModal = ref(false);
const editingCategoryId = ref<number | null>(null);
const quickFieldErrors = ref<{
  name?: string;
  class_code?: string;
  receipt_mode?: string;
}>({});
const quickForm = ref({
  name: '',
  class_code: '' as SpendClass | '',
  receipt_mode: '' as ReceiptMode | '',
  parent_id: '',
  item_category_id: '',
  requires_inspection: false,
  requires_contract: false,
  requires_budget_line: false
});

// ─── Breadcrumb Navigation (AGENTS.md Rule 3) ───
const breadcrumbItems = computed<BreadcrumbItem[]>(() => {
  if (inspectingCategory.value) {
    return [
      {
        label: 'Procurement Categories',
        to: '/procurement/categories',
        onClick: () => {
          inspectingCategory.value = null;
        }
      },
      { label: inspectingCategory.value.name }
    ];
  }
  return [{ label: 'Procurement Categories' }];
});

// ─── Atomic Columns & Column Hider (AGENTS.md Rule 9) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Category Name', visible: true, sortable: true, hideable: false },
  { key: 'spend_class', label: 'Spend Class', visible: true, sortable: true },
  { key: 'receipt_mode', label: 'Receipt Mode', visible: true, sortable: true },
  { key: 'parent', label: 'Parent Category', visible: true, sortable: true },
  { key: 'requires_inspection', label: 'Inspection Required', visible: false, sortable: false },
  { key: 'requires_contract', label: 'Contract Required', visible: false, sortable: false },
  { key: 'requires_budget_line', label: 'Budget Line Required', visible: false, sortable: false },
  { key: 'item_category', label: 'Item Category', visible: false, sortable: false },
  { key: 'entity', label: 'Owning Entity', visible: false, sortable: false },
  { key: 'status', label: 'Status', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

const sortOptions: SortOption[] = [
  { key: 'name', label: 'Category Name' },
  { key: 'spend_class', label: 'Spend Class' },
  { key: 'receipt_mode', label: 'Receipt Mode' },
  { key: 'parent', label: 'Parent Category' },
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

// ─── Hierarchy Helpers ───
const getParentName = (parentId: number | null): string => {
  if (!parentId) return 'Top Level';
  const parent = procurementCategoriesStore.value.find((c) => c.id === parentId);
  return parent ? parent.name : 'Top Level';
};

const getChildCategories = (parentId: number) => {
  return procurementCategoriesStore.value.filter((c) => c.parent_id === parentId);
};

const parentCategoryOptions = computed(() => {
  return procurementCategoriesStore.value
    .filter((c) => c.id !== editingCategoryId.value && c.state === 'active')
    .map((c) => ({
      value: String(c.id),
      label: c.name
    }));
});

// ─── Filters & Sorting ───
const activeFilterCount = computed(() => {
  let count = 0;
  if (filterClass.value) count++;
  if (filterReceiptMode.value) count++;
  if (filterHierarchy.value) count++;
  if (filterStatus.value) count++;
  if (filterState.value) count++;
  return count;
});

const resetFilters = () => {
  filterClass.value = '';
  filterReceiptMode.value = '';
  filterHierarchy.value = '';
  filterStatus.value = '';
  filterState.value = '';
  currentPage.value = 1;
};

const filteredCategories = computed(() => {
  const q = searchQuery.value.trim().toLowerCase();
  let rows = [...procurementCategoriesStore.value];

  if (q) {
    rows = rows.filter(
      (c) =>
        c.name.toLowerCase().includes(q) ||
        c.code.toLowerCase().includes(q) ||
        getParentName(c.parent_id).toLowerCase().includes(q)
    );
  }

  if (filterClass.value) {
    rows = rows.filter((c) => c.class_code === filterClass.value);
  }
  if (filterReceiptMode.value) {
    rows = rows.filter((c) => c.receipt_mode === filterReceiptMode.value);
  }
  if (filterHierarchy.value === 'top_level') {
    rows = rows.filter((c) => c.parent_id === null);
  } else if (filterHierarchy.value === 'sub_category') {
    rows = rows.filter((c) => c.parent_id !== null);
  }
  if (filterStatus.value) {
    rows = rows.filter((c) => c.status === filterStatus.value);
  }
  if (filterState.value) {
    rows = rows.filter((c) => c.state === filterState.value);
  }

  rows.sort((a, b) => {
    let valA = '';
    let valB = '';
    switch (currentSort.value) {
      case 'name':
        valA = a.name.toLowerCase();
        valB = b.name.toLowerCase();
        break;
      case 'spend_class':
        valA = getSpendClassLabel(a.class_code).toLowerCase();
        valB = getSpendClassLabel(b.class_code).toLowerCase();
        break;
      case 'receipt_mode':
        valA = getReceiptModeLabel(a.receipt_mode).toLowerCase();
        valB = getReceiptModeLabel(b.receipt_mode).toLowerCase();
        break;
      case 'parent':
        valA = getParentName(a.parent_id).toLowerCase();
        valB = getParentName(b.parent_id).toLowerCase();
        break;
      case 'status':
        valA = getGovernanceStatusLabel(a.status).toLowerCase();
        valB = getGovernanceStatusLabel(b.status).toLowerCase();
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

const paginatedCategories = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredCategories.value.slice(start, start + perPage.value);
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
  if (paginatedCategories.value.length === 0) return false;
  return paginatedCategories.value.every((c) => selectedRowIds.value.includes(c.id));
});

const isPartiallySelected = computed(() => {
  const selectedCount = paginatedCategories.value.filter((category) =>
    selectedRowIds.value.includes(category.id)
  ).length;
  return selectedCount > 0 && selectedCount < paginatedCategories.value.length;
});

const toggleSelectAll = () => {
  const checked = !isAllSelected.value;
  if (checked) {
    const pageIds = paginatedCategories.value.map((c) => c.id);
    selectedRowIds.value = Array.from(new Set([...selectedRowIds.value, ...pageIds]));
  } else {
    const pageIds = new Set(paginatedCategories.value.map((c) => c.id));
    selectedRowIds.value = selectedRowIds.value.filter((id) => !pageIds.has(id));
  }
};

const toggleSelectRow = (id: number) => {
  if (selectedRowIds.value.includes(id)) {
    selectedRowIds.value = selectedRowIds.value.filter((i) => i !== id);
  } else {
    selectedRowIds.value.push(id);
  }
};

const selectAllFilteredCategories = () => {
  const filteredIds = filteredCategories.value.map((category) => category.id);
  selectedRowIds.value = Array.from(new Set([...selectedRowIds.value, ...filteredIds]));
};

// ─── Toast Helper (QMT BaseToaster) ───
const showToast = (msg: string, variant: 'success' | 'error' | 'warning' = 'success') => {
  toast[variant](msg);
};

// ─── Quick Create & Edit Handlers ───
const openCreateModal = () => {
  editingCategoryId.value = null;
  quickFieldErrors.value = {};
  quickForm.value = {
    name: '',
    class_code: '',
    receipt_mode: '',
    parent_id: '',
    item_category_id: '',
    requires_inspection: false,
    requires_contract: false,
    requires_budget_line: false
  };
  showQuickModal.value = true;
};

const openEditModal = (item: ProcurementCategoryRecord) => {
  editingCategoryId.value = item.id;
  quickFieldErrors.value = {};
  quickForm.value = {
    name: item.name,
    class_code: item.class_code,
    receipt_mode: item.receipt_mode,
    parent_id: item.parent_id ? String(item.parent_id) : '',
    item_category_id: item.item_category_id ? String(item.item_category_id) : '',
    requires_inspection: item.requires_inspection,
    requires_contract: item.requires_contract,
    requires_budget_line: item.requires_budget_line
  };
  showQuickModal.value = true;
  activeActionMenuId.value = null;
};

watch(
  quickForm,
  () => {
    if (quickForm.value.name.trim()) quickFieldErrors.value.name = undefined;
    if (quickForm.value.class_code) quickFieldErrors.value.class_code = undefined;
    if (quickForm.value.receipt_mode) quickFieldErrors.value.receipt_mode = undefined;
  },
  { deep: true }
);

const handleSaveQuick = () => {
  const errors: typeof quickFieldErrors.value = {};
  const missingLabels: string[] = [];

  if (!quickForm.value.name.trim()) {
    errors.name = 'Category Name is required.';
    missingLabels.push('Category Name');
  }
  if (!quickForm.value.class_code) {
    errors.class_code = 'Spend Class is required.';
    missingLabels.push('Spend Class');
  }
  if (!quickForm.value.receipt_mode) {
    errors.receipt_mode = 'Receipt Mode is required.';
    missingLabels.push('Receipt Mode');
  }

  quickFieldErrors.value = errors;

  if (missingLabels.length > 0) {
    toast.error(
      'Please fill in all required fields',
      `Missing: ${missingLabels.join(', ')}.`
    );
    return;
  }

  const parentId = quickForm.value.parent_id ? Number(quickForm.value.parent_id) : null;
  const itemCategoryId = quickForm.value.item_category_id ? Number(quickForm.value.item_category_id) : null;

  if (editingCategoryId.value) {
    const idx = procurementCategoriesStore.value.findIndex((c) => c.id === editingCategoryId.value);
    if (idx !== -1) {
      const existing = procurementCategoriesStore.value[idx];
      procurementCategoriesStore.value[idx] = {
        ...existing,
        name: quickForm.value.name.trim(),
        class_code: quickForm.value.class_code as SpendClass,
        receipt_mode: quickForm.value.receipt_mode as ReceiptMode,
        parent_id: parentId,
        item_category_id: itemCategoryId,
        requires_inspection: quickForm.value.requires_inspection,
        requires_contract: quickForm.value.requires_contract,
        requires_budget_line: quickForm.value.requires_budget_line
      };
      if (inspectingCategory.value?.id === existing.id) {
        inspectingCategory.value = procurementCategoriesStore.value[idx];
      }
      showToast(`Updated "${quickForm.value.name.trim()}".`);
    }
  } else {
    const existingCodes = procurementCategoriesStore.value.map((c) => c.code);
    const nextId = Math.max(0, ...procurementCategoriesStore.value.map((c) => c.id)) + 1;
    const generatedCode = generateCategoryCode(quickForm.value.name, existingCodes);

    procurementCategoriesStore.value.unshift({
      id: nextId,
      uuid: `pc-uuid-${nextId}`,
      code: generatedCode,
      name: quickForm.value.name.trim(),
      description: '',
      requires_inspection: quickForm.value.requires_inspection,
      requires_contract: quickForm.value.requires_contract,
      requires_budget_line: quickForm.value.requires_budget_line,
      class_code: quickForm.value.class_code as SpendClass,
      receipt_mode: quickForm.value.receipt_mode as ReceiptMode,
      parent_id: parentId,
      entity_id: 2,
      item_category_id: itemCategoryId,
      status: 'pending',
      state: 'active'
    });
    showToast(`Created procurement category "${quickForm.value.name.trim()}".`);
  }

  showQuickModal.value = false;
};

const handleExpandFullForm = () => {
  showQuickModal.value = false;
  router.push({
    path: '/procurement/categories/create',
    query: {
      name: quickForm.value.name || undefined,
      class_code: quickForm.value.class_code || undefined,
      receipt_mode: quickForm.value.receipt_mode || undefined,
      parent_id: quickForm.value.parent_id || undefined,
      item_category_id: quickForm.value.item_category_id || undefined,
      requires_inspection: quickForm.value.requires_inspection ? '1' : undefined,
      requires_contract: quickForm.value.requires_contract ? '1' : undefined,
      requires_budget_line: quickForm.value.requires_budget_line ? '1' : undefined
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

const openDetailView = (item: ProcurementCategoryRecord) => {
  inspectingCategory.value = item;
  isDetailDescriptionOpen.value = false;
  activeActionMenuId.value = null;
};

const handleToggleState = (item: ProcurementCategoryRecord) => {
  item.state = item.state === 'active' ? 'inactive' : 'active';
  showToast(`Marked "${item.name}" as ${item.state === 'active' ? 'Active' : 'Inactive'}.`);
  closeActionMenu();
};

const handleDelete = (item: ProcurementCategoryRecord) => {
  const hasChildren = procurementCategoriesStore.value.some((c) => c.parent_id === item.id);
  if (hasChildren) {
    showToast(`Cannot delete "${item.name}" while sub-categories reference it.`, 'error');
    closeActionMenu();
    return;
  }
  procurementCategoriesStore.value = procurementCategoriesStore.value.filter((c) => c.id !== item.id);
  selectedRowIds.value = selectedRowIds.value.filter((i) => i !== item.id);
  if (inspectingCategory.value?.id === item.id) {
    inspectingCategory.value = null;
  }
  showToast(`Deleted "${item.name}".`);
  closeActionMenu();
};

const handleBatchDelete = () => {
  const selectedSet = new Set(selectedRowIds.value);
  const blocked = procurementCategoriesStore.value.some(
    (c) => c.parent_id !== null && selectedSet.has(c.parent_id) && !selectedSet.has(c.id)
  );
  if (blocked) {
    showToast('Deselect parent categories that still have active child categories, or include their sub-categories.', 'error');
    return;
  }
  procurementCategoriesStore.value = procurementCategoriesStore.value.filter((c) => !selectedSet.has(c.id));
  showToast(`Deleted ${selectedRowIds.value.length} selected categories.`);
  selectedRowIds.value = [];
};

const handleGlobalClick = (e: MouseEvent) => {
  const target = e.target as HTMLElement;
  if (!target.closest('.action-menu-container')) {
    closeActionMenu();
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
  <div class="procurement-categories-page">
    <!-- ═══ BREADCRUMB NAVIGATION (Rule 3: Exact Page Name Only, Zero Section Titles) ═══ -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" :noMargin="true" />
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- ISOLATED DETAIL VIEW (Rule 10.3 & Rule 10.5)                   -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-if="inspectingCategory" class="detail-view-wrapper">
      <div class="detail-card">
        <div class="detail-header-row">
          <div>
            <h2 class="detail-title">{{ inspectingCategory.name }}</h2>
            <span class="detail-code">{{ inspectingCategory.code }}</span>
          </div>
          <div class="detail-badges">
            <BaseBadge
              size="sm"
              :color="getGovernanceBadgeColor(inspectingCategory.status)"
            >
              {{ getGovernanceStatusLabel(inspectingCategory.status) }}
            </BaseBadge>
            <BaseBadge
              size="sm"
              :color="inspectingCategory.state === 'active' ? 'success' : 'gray'"
            >
              {{ inspectingCategory.state === 'active' ? 'Active' : 'Inactive' }}
            </BaseBadge>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Spend Class</span>
            <span class="detail-value">{{ getSpendClassLabel(inspectingCategory.class_code) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Receipt Mode</span>
            <span class="detail-value">{{ getReceiptModeLabel(inspectingCategory.receipt_mode) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Parent Category</span>
            <span class="detail-value">{{ getParentName(inspectingCategory.parent_id) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Owning Entity</span>
            <span class="detail-value">{{ getEntityName(inspectingCategory.entity_id) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Inventory Item Category</span>
            <span class="detail-value">{{ getItemCategoryName(inspectingCategory.item_category_id) }}</span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Requires Quality Inspection</span>
            <span class="detail-value">{{ inspectingCategory.requires_inspection ? 'Yes (Goods Inspection Mandatory)' : 'No' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Requires Contract</span>
            <span class="detail-value">{{ inspectingCategory.requires_contract ? 'Yes (PO Blocked Without Contract)' : 'No' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Requires Budget Line</span>
            <span class="detail-value">{{ inspectingCategory.requires_budget_line ? 'Yes (PR Line Requires Budget Line)' : 'No' }}</span>
          </div>
        </div>

        <!-- Child Sub-Categories Mini Table (if this category has children) -->
        <template v-if="getChildCategories(inspectingCategory.id).length > 0">
          <div class="detail-divider"></div>
          <table class="nested-mini-table">
            <thead>
              <tr>
                <th>Sub-Category Name</th>
                <th>Spend Class</th>
                <th>Receipt Mode</th>
                <th>State</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="child in getChildCategories(inspectingCategory.id)" :key="child.id" class="cursor-pointer" @click="openDetailView(child)">
                <td class="td-primary">
                  <span class="table-name-primary">{{ child.name }}</span>
                  <span class="table-code-subtext">{{ child.code }}</span>
                </td>
                <td class="td-tertiary">{{ getSpendClassLabel(child.class_code) }}</td>
                <td class="td-tertiary">{{ getReceiptModeLabel(child.receipt_mode) }}</td>
                <td>
                  <BaseBadge
                    size="sm"
                    :color="child.state === 'active' ? 'success' : 'gray'"
                  >
                    {{ child.state === 'active' ? 'Active' : 'Inactive' }}
                  </BaseBadge>
                </td>
              </tr>
            </tbody>
          </table>
        </template>
      </div>

      <!-- Collapsible Description Section -->
      <div class="clean-card accordion-card">
        <div
          class="card-accordion-header"
          :class="{ 'is-collapsed': !isDetailDescriptionOpen }"
          @click="isDetailDescriptionOpen = !isDetailDescriptionOpen"
        >
          <span>Description</span>
          <ChevronDown v-if="isDetailDescriptionOpen" :size="16" class="header-chevron" />
          <ChevronRight v-else :size="16" class="header-chevron" />
        </div>
        <div v-show="isDetailDescriptionOpen" class="card-accordion-body">
          <p class="detail-description">
            {{ inspectingCategory.description || 'No description provided.' }}
          </p>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- DIRECTORY VIEW: SINGLE TABLE CARD (Rule 10.1 & Rule 21)       -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <template v-else>
      <AppDataTable
        title="Procurement Categories"
        subtitle="Hierarchical spend classification tree governing quality inspection, contract requirements, budget validation, and receipt confirmation paths."
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search category or code..."
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
        :totalEntries="filteredCategories.length"
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
            Create Category
          </AppButton>
        </template>

        <!-- Filter Panel -->
        <template #filter-panel>
          <div class="filter-panel-grid">
            <FormSelect
              label="Spend Class"
              v-model="filterClass"
              :options="[{ value: '', label: 'All Spend Classes' }, ...spendClassOptions]"
              placeholder="Select"
            />
            <FormSelect
              label="Receipt Mode"
              v-model="filterReceiptMode"
              :options="[{ value: '', label: 'All Receipt Modes' }, ...receiptModeOptions]"
              placeholder="Select"
            />
            <FormSelect
              label="Hierarchy Level"
              v-model="filterHierarchy"
              :options="[
                { value: '', label: 'All Levels' },
                { value: 'top_level', label: 'Top-Level Only' },
                { value: 'sub_category', label: 'Sub-Categories Only' }
              ]"
              placeholder="Select"
            />
            <FormSelect
              label="Status"
              v-model="filterStatus"
              :options="[
                { value: '', label: 'All Statuses' },
                { value: 'acceptForAll', label: 'Approved for All Entities' },
                { value: 'acceptForThis', label: 'Approved for This Entity Only' },
                { value: 'pending', label: 'Pending Approval' },
                { value: 'reject', label: 'Rejected' }
              ]"
              placeholder="Select"
            />
            <FormSelect
              label="State"
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

        <!-- Table Content (Rule 8, Rule 9, Rule 28) -->
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
                    <span class="sr-only">Select all categories on this page</span>
                  </FormCheckbox>
                  <span>Category Name</span>
                  <ArrowUpDown v-if="currentSort === 'name'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('spend_class')"
                class="sortable"
                @click="handleSortColumn('spend_class')"
              >
                <div class="th-content">
                  <span>Spend Class</span>
                  <ArrowUpDown v-if="currentSort === 'spend_class'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('receipt_mode')"
                class="sortable"
                @click="handleSortColumn('receipt_mode')"
              >
                <div class="th-content">
                  <span>Receipt Mode</span>
                  <ArrowUpDown v-if="currentSort === 'receipt_mode'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('parent')"
                class="sortable"
                @click="handleSortColumn('parent')"
              >
                <div class="th-content">
                  <span>Parent Category</span>
                  <ArrowUpDown v-if="currentSort === 'parent'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th v-if="isColumnVisible('requires_inspection')">
                <div class="th-content"><span>Inspection Required</span></div>
              </th>

              <th v-if="isColumnVisible('requires_contract')">
                <div class="th-content"><span>Contract Required</span></div>
              </th>

              <th v-if="isColumnVisible('requires_budget_line')">
                <div class="th-content"><span>Budget Line Required</span></div>
              </th>

              <th v-if="isColumnVisible('item_category')">
                <div class="th-content"><span>Item Category</span></div>
              </th>

              <th v-if="isColumnVisible('entity')">
                <div class="th-content"><span>Owning Entity</span></div>
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

              <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr v-if="paginatedCategories.length === 0">
              <td :colspan="visibleColumnCount" class="empty-state-cell">
                <div class="empty-state-container">
                  <FolderTree :size="32" class="empty-state-icon" />
                  <p class="empty-state-title">No procurement categories found</p>
                  <p class="empty-state-subtext">Adjust your search or filters, or create a new category.</p>
                </div>
              </td>
            </tr>

            <tr
              v-for="item in paginatedCategories"
              :key="item.id"
              class="erp-row"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
              @click="openDetailView(item)"
            >
              <!-- Rule 9.4 & 9.5: Name (#404040) + Code subtext (#737373), Zero decorative icons -->
              <td v-if="isColumnVisible('name')" class="td-name">
                <div class="name-cell-content">
                  <FormCheckbox
                    :model-value="selectedRowIds.includes(item.id)"
                    size="md"
                    @click.stop
                    @update:model-value="() => toggleSelectRow(item.id)"
                  >
                    <span class="sr-only">Select {{ item.name }}</span>
                  </FormCheckbox>
                  <div class="name-cell-stack">
                    <span class="table-name-primary">{{ item.name }}</span>
                    <span class="table-code-subtext">{{ item.code }}</span>
                  </div>
                </div>
              </td>

              <!-- Rule 9.5 & 9.6: Tertiary Plain Text (#737373), Anti-Badge Standard -->
              <td v-if="isColumnVisible('spend_class')">
                <span class="tertiary-plain-text">{{ getSpendClassLabel(item.class_code) }}</span>
              </td>

              <td v-if="isColumnVisible('receipt_mode')">
                <span class="tertiary-plain-text">{{ getReceiptModeLabel(item.receipt_mode) }}</span>
              </td>

              <td v-if="isColumnVisible('parent')">
                <span class="tertiary-plain-text">{{ getParentName(item.parent_id) }}</span>
              </td>

              <td v-if="isColumnVisible('requires_inspection')">
                <span class="tertiary-plain-text">{{ item.requires_inspection ? 'Yes' : 'No' }}</span>
              </td>

              <td v-if="isColumnVisible('requires_contract')">
                <span class="tertiary-plain-text">{{ item.requires_contract ? 'Yes' : 'No' }}</span>
              </td>

              <td v-if="isColumnVisible('requires_budget_line')">
                <span class="tertiary-plain-text">{{ item.requires_budget_line ? 'Yes' : 'No' }}</span>
              </td>

              <td v-if="isColumnVisible('item_category')">
                <span class="tertiary-plain-text">{{ getItemCategoryName(item.item_category_id) }}</span>
              </td>

              <td v-if="isColumnVisible('entity')">
                <span class="tertiary-plain-text">{{ getEntityName(item.entity_id) }}</span>
              </td>

              <!-- Governance Status Pill -->
              <td v-if="isColumnVisible('status')">
                <BaseBadge
                  size="sm"
                  :color="getGovernanceBadgeColor(item.status)"
                >
                  {{ getGovernanceStatusLabel(item.status) }}
                </BaseBadge>
              </td>

              <!-- Lifecycle State Pill (Rule 9.9: Active/Inactive strictly on State) -->
              <td v-if="isColumnVisible('state')">
                <BaseBadge
                  size="sm"
                  :color="item.state === 'active' ? 'success' : 'gray'"
                >
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </BaseBadge>
              </td>

              <!-- Row Actions -->
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

                  <div v-if="activeActionMenuId === item.id" class="action-dropdown" @click.stop>
                    <button type="button" class="dropdown-item" @click="openDetailView(item)">
                      <Eye :size="14" class="dropdown-icon" />
                      <span>View Details</span>
                    </button>
                    <button type="button" class="dropdown-item" @click="openEditModal(item)">
                      <Edit2 :size="14" class="dropdown-icon" />
                      <span>Edit Category</span>
                    </button>
                    <button type="button" class="dropdown-item" @click="handleToggleState(item)">
                      <Check :size="14" class="dropdown-icon" />
                      <span>{{ item.state === 'active' ? 'Deactivate' : 'Activate' }}</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button type="button" class="dropdown-item dropdown-item-danger" @click="handleDelete(item)">
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

      <!-- Floating Batch Action Bar (Rule 11.3) -->
      <TableFloatingBar
        :show="selectedRowIds.length > 0"
        :selected-count="selectedRowIds.length"
        :total-count="filteredCategories.length"
        @delete="handleBatchDelete"
        @selectAll="selectAllFilteredCategories"
      />
    </template>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- QUICK CREATE / EDIT MODAL (Rule 4, 5, 14.4, 16, 20, 24, 26, 27)-->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <QuickCreateModal
      v-model:show="showQuickModal"
      :title="editingCategoryId ? 'Edit Procurement Category' : 'Create Procurement Category'"
      :showExpandButton="!editingCategoryId"
      saveLabel="Save"
      width="md"
      @save="handleSaveQuick"
      @expand="handleExpandFullForm"
    >
      <div class="quick-form-body">
        <!-- Category Name (Rule 5: Zero placeholder, Rule 16: Zero manual code input) -->
        <FormInput
          v-model="quickForm.name"
          label="Category Name"
          :error="quickFieldErrors.name"
          required
        />

        <div class="modal-grid-2">
          <!-- Spend Class -->
          <FormSelect
            v-model="quickForm.class_code"
            label="Spend Class"
            :options="spendClassOptions"
            placeholder="Select Class"
            :error="quickFieldErrors.class_code"
            required
          />

          <!-- Receipt Mode -->
          <FormSelect
            v-model="quickForm.receipt_mode"
            label="Receipt Mode"
            :options="receiptModeOptions"
            placeholder="Select Mode"
            :error="quickFieldErrors.receipt_mode"
            required
          />
        </div>

        <div class="modal-grid-2">
          <!-- Parent Category -->
          <FormSelect
            v-model="quickForm.parent_id"
            label="Parent Category"
            :options="parentCategoryOptions"
            placeholder="Select Parent"
          />

          <!-- Inventory Item Category -->
          <FormSelect
            v-model="quickForm.item_category_id"
            label="Inventory Item Category"
            :options="itemCategoryOptions"
            placeholder="Select Item Category"
          />
        </div>

        <!-- Rule 5: All booleans MUST use <FormCheckbox /> with Title + Description -->
        <div class="modal-checkbox-stack">
          <FormCheckbox
            v-model="quickForm.requires_inspection"
            label="Requires Quality Inspection"
            description="Deliveries in this category must pass Goods Inspection before final stock acceptance."
          />
          <FormCheckbox
            v-model="quickForm.requires_contract"
            label="Requires Contract"
            description="Purchase orders for this category cannot be issued without an active procurement contract."
          />
          <FormCheckbox
            v-model="quickForm.requires_budget_line"
            label="Requires Budget Line"
            description="Purchase requisition lines must reference an approved budget line before submission."
          />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.procurement-categories-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  width: 100%;
  padding: 0;
  box-sizing: border-box;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
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
  border-bottom: 1px solid #e2e8f0;
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

.name-cell-content .name-cell-stack {
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
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.erp-row {
  cursor: pointer;
  transition: background-color 0.12s ease;
}

.erp-row:hover {
  background-color: #fafafa;
}

.row-selected {
  background-color: #eff6ff;
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

/* Action 3-dots & Dropdown (Rule 8) */
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
  background: #f1f5f9;
  color: #404040;
}

.action-dropdown {
  position: absolute;
  right: 0;
  top: 32px;
  min-width: 170px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
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
  background: #f8fafc;
}

.dropdown-icon {
  color: #737373;
}

.dropdown-divider {
  height: 1px;
  background: #f1f5f9;
  margin: 4px 0;
}

.dropdown-item-danger {
  color: #dc2626;
}

.dropdown-item-danger .dropdown-icon {
  color: #dc2626;
}

.dropdown-item-danger:hover {
  background: #fef2f2;
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
  color: #94a3b8;
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

/* Quick Create Modal Body */
.quick-form-body {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.modal-error-banner {
  padding: 8px 12px;
  border-radius: 8px;
  background: #fef2f2;
  border: 1px solid #fecaca;
  color: #dc2626;
  font-size: 12.5px;
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

/* Detail View (Rule 10.3 & 10.5) */
.detail-view-wrapper {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.detail-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
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

.detail-title {
  margin: 0;
  font-size: 18px;
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

.detail-divider {
  height: 1px;
  background: #f1f5f9;
}

.clean-card.accordion-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
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

.detail-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
}

.detail-field {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.detail-label {
  font-size: 12px;
  color: #737373;
}

.detail-value {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
}

.detail-description {
  margin: 0;
  font-size: 13.5px;
  color: #404040;
  line-height: 1.55;
}

.nested-mini-table {
  width: 100%;
  border-collapse: collapse;
  border: 1px solid #f1f5f9;
  border-radius: 8px;
  overflow: hidden;
}

.nested-mini-table th {
  height: 34px;
  padding: 8px 14px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background: #fafafa;
  border-bottom: 1px solid #e2e8f0;
  text-align: left;
}

.nested-mini-table td {
  height: 38px;
  padding: 8px 14px;
  font-size: 13px;
  border-bottom: 1px solid #f1f5f9;
}

.td-tertiary {
  color: #737373;
}

@media (max-width: 768px) {
  .modal-grid-2,
  .detail-grid-3 {
    grid-template-columns: 1fr;
  }
}
</style>

