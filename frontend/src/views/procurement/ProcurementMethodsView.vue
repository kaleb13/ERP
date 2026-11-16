<script setup lang="ts">
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue';
import {
  Plus, Eye, Edit2, Trash2, X, Scale, Building2, FolderTree, Info, MoreVertical, Check
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
import IconColumnSolid from '../../components/IconColumnSolid.vue';
import {
  purchaseMethodsStore,
  thresholdBandsStore,
  type PurchaseMethodRecord,
  type PurchaseMethodThresholdRecord,
  formatCurrency,
  methodOptions,
  categoryOptions,
  unitOptions
} from './procurementMethodData';

// ─── Breadcrumb Navigation Standard (AGENTS.md Exact Sidebar Page Name Only) ───
const breadcrumbItems = computed<BreadcrumbItem[]>(() => {
  if (inspectingBand.value) {
    return [
      {
        label: 'Spend Threshold Bands',
        to: '/procurement/thresholds',
        onClick: () => {
          inspectingBand.value = null;
        }
      },
      { label: `${inspectingBand.value.method_name} Band` }
    ];
  }
  return [{ label: 'Spend Threshold Bands' }];
});

// ─── Toast Feedback ───
const { toast } = useToast();

const showToast = (msg: string, variant: 'success' | 'error' = 'success') => {
  if (variant === 'error') {
    toast.error(msg);
  } else {
    toast.success(msg);
  }
};

// ─── Search & Filter State ───
const searchQuery = ref('');
const filterMethodId = ref('');
const filterEnforcement = ref('');
const filterCategory = ref('');
const filterUnit = ref('');
const filterState = ref('');

// ─── Selection State ───
const selectedRowIds = ref<number[]>([]);

// ─── Sorting State ───
const currentSortKey = ref('minimum_amount');
const sortOrder = ref<'asc' | 'desc'>('asc');
const currentPage = ref(1);
const perPage = ref(10);

// ─── Modals & Drawers ───
const showQuickModal = ref(false);
const editingId = ref<number | null>(null);
const inspectingBand = ref<PurchaseMethodThresholdRecord | null>(null);

// ─── Column Hider Popover ───
const isColumnHiderOpen = ref(false);
const columnToggleRef = ref<HTMLElement | null>(null);
const columnPopoverRef = ref<HTMLElement | null>(null);
const columnPopoverPosition = ref({ top: 0, left: 0 });

// ─── Table Columns Configuration (table-architecture.instructions.md) ───
const columns = ref<ColumnDef[]>([
  { key: 'method_name', label: 'Purchase Method', visible: true, hideable: false },
  { key: 'amount_range', label: 'Order Value Band (ETB)', visible: true },
  { key: 'is_mandatory', label: 'Enforcement', visible: true },
  { key: 'category_name', label: 'Category Scope', visible: false },
  { key: 'unit_name', label: 'Buying Desk Scope', visible: false },
  { key: 'effective_range', label: 'Validity Period', visible: false },
  { key: 'state', label: 'State', visible: true },
  { key: 'actions', label: 'Actions', visible: true, hideable: false }
]);

const sortOptions: SortOption[] = [
  { key: 'minimum_amount', label: 'Value Floor (Lowest to Highest)' },
  { key: 'method_name', label: 'Purchase Method (A-Z)' },
  { key: 'is_mandatory', label: 'Enforcement (Mandatory First)' },
  { key: 'state', label: 'State (Active First)' }
];

// ─── Filter Options ───
const enforcementFilterOptions = [
  { value: '', label: 'All Enforcement Types' },
  { value: 'mandatory', label: 'Mandatory (Forces Method)' },
  { value: 'permissive', label: 'Permissive (Permits Method)' }
];

const stateFilterOptions = [
  { value: '', label: 'All States' },
  { value: 'active', label: 'Active Only' },
  { value: 'inactive', label: 'Inactive Only' }
];

const categoryScopeOptions = categoryOptions.filter((option) => option.value !== '');
const unitScopeOptions = unitOptions.filter((option) => option.value !== '');

// ─── QMT Semantic Badge Colors for Lookups ───
// Gray is strictly reserved for Inactive states. Active policy lookups use vibrant QMT colors.
const getEnforcementBadgeColor = (isMandatory: boolean): BadgeColor => {
  return isMandatory ? 'indigo' : 'blue';
};

const activeFilterCount = computed(() => [
  filterMethodId.value,
  filterEnforcement.value,
  filterCategory.value,
  filterUnit.value,
  filterState.value
].filter(Boolean).length);

// ─── Filtered & Sorted Threshold Bands ───
const filteredBands = computed(() => {
  let list = [...thresholdBandsStore.value];

  // Search filter
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase().trim();
    list = list.filter((b) =>
      b.method_name.toLowerCase().includes(q) ||
      b.method_code.toLowerCase().includes(q) ||
      (b.category_name && b.category_name.toLowerCase().includes(q)) ||
      (b.unit_name && b.unit_name.toLowerCase().includes(q))
    );
  }

  // Method filter
  if (filterMethodId.value) {
    list = list.filter((b) => String(b.purchase_method_id) === filterMethodId.value);
  }

  // Enforcement filter
  if (filterEnforcement.value === 'mandatory') {
    list = list.filter((b) => b.is_mandatory);
  } else if (filterEnforcement.value === 'permissive') {
    list = list.filter((b) => !b.is_mandatory);
  }

  // Category filter
  if (filterCategory.value) {
    list = list.filter((b) => String(b.procurement_category_id) === filterCategory.value);
  }

  // Unit filter
  if (filterUnit.value) {
    list = list.filter((b) => String(b.procurement_unit_id) === filterUnit.value);
  }

  // State filter
  if (filterState.value) {
    list = list.filter((b) => b.state === filterState.value);
  }

  // Sort
  list.sort((a, b) => {
    let cmp = 0;
    if (currentSortKey.value === 'minimum_amount') {
      cmp = a.minimum_amount - b.minimum_amount;
    } else if (currentSortKey.value === 'method_name') {
      cmp = a.method_name.localeCompare(b.method_name);
    } else if (currentSortKey.value === 'is_mandatory') {
      cmp = (b.is_mandatory ? 1 : 0) - (a.is_mandatory ? 1 : 0);
    } else if (currentSortKey.value === 'state') {
      cmp = a.state.localeCompare(b.state);
    }
    return sortOrder.value === 'asc' ? cmp : -cmp;
  });

  return list;
});

const paginatedBands = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredBands.value.slice(start, start + perPage.value);
});

const visibleColumnCount = computed(
  () => columns.value.filter((column) => column.visible !== false).length
);

watch(
  [searchQuery, filterMethodId, filterEnforcement, filterCategory, filterUnit, filterState],
  () => {
    currentPage.value = 1;
  }
);

watch(
  [() => filteredBands.value.length, perPage],
  ([total, pageSize]) => {
    currentPage.value = Math.min(
      currentPage.value,
      Math.max(1, Math.ceil(total / pageSize))
    );
  }
);

// ─── Selection Handlers (table-architecture.instructions.md) ───
const isAllSelected = computed(() => {
  if (paginatedBands.value.length === 0) return false;
  return paginatedBands.value.every((b) => selectedRowIds.value.includes(b.id));
});

const isSomeSelected = computed(() => {
  return paginatedBands.value.some((b) => selectedRowIds.value.includes(b.id)) &&
    !isAllSelected.value;
});

const handleSelectAll = (checked: boolean) => {
  const pageIds = new Set(paginatedBands.value.map((band) => band.id));
  if (checked) {
    selectedRowIds.value = [...new Set([...selectedRowIds.value, ...pageIds])];
  } else {
    selectedRowIds.value = selectedRowIds.value.filter((id) => !pageIds.has(id));
  }
};

const handleSelectRow = (id: number, checked: boolean) => {
  if (checked) {
    if (!selectedRowIds.value.includes(id)) {
      selectedRowIds.value.push(id);
    }
  } else {
    selectedRowIds.value = selectedRowIds.value.filter((i) => i !== id);
  }
};

// ─── Quick Create / Edit Form Model ───
const quickForm = ref({
  purchase_method_id: '1',
  minimum_amount: 0,
  maximum_amount: 50000 as number | null,
  noLimit: false,
  is_mandatory: true,
  procurement_category_id: '',
  procurement_unit_id: '',
  effective_from: new Date().toISOString().split('T')[0],
  effective_to: ''
});

const quickErrors = ref<{
  purchase_method_id?: string;
  minimum_amount?: string;
  maximum_amount?: string;
  effective_from?: string;
  effective_to?: string;
  overlap?: string;
}>({});

const resetFilter = () => {
  searchQuery.value = '';
  filterMethodId.value = '';
  filterEnforcement.value = '';
  filterCategory.value = '';
  filterUnit.value = '';
  filterState.value = '';
};

const openQuickCreateModal = () => {
  editingId.value = null;
  quickErrors.value = {};
  quickForm.value = {
    purchase_method_id: '1',
    minimum_amount: 0,
    maximum_amount: 50000,
    noLimit: false,
    is_mandatory: true,
    procurement_category_id: '',
    procurement_unit_id: '',
    effective_from: new Date().toISOString().split('T')[0],
    effective_to: ''
  };
  showQuickModal.value = true;
};

const openEditModal = (band: PurchaseMethodThresholdRecord) => {
  editingId.value = band.id;
  quickErrors.value = {};
  quickForm.value = {
    purchase_method_id: String(band.purchase_method_id),
    minimum_amount: band.minimum_amount,
    maximum_amount: band.maximum_amount,
    noLimit: band.maximum_amount === null,
    is_mandatory: band.is_mandatory,
    procurement_category_id: band.procurement_category_id ? String(band.procurement_category_id) : '',
    procurement_unit_id: band.procurement_unit_id ? String(band.procurement_unit_id) : '',
    effective_from: band.effective_from,
    effective_to: band.effective_to || ''
  };
  showQuickModal.value = true;
};

const handleSaveBand = () => {
  quickErrors.value = {};
  const errors: typeof quickErrors.value = {};

  if (!quickForm.value.purchase_method_id) {
    errors.purchase_method_id = 'Select a statutory purchase method.';
  }
  if (
    quickForm.value.minimum_amount === null ||
    !Number.isFinite(quickForm.value.minimum_amount) ||
    quickForm.value.minimum_amount < 0
  ) {
    errors.minimum_amount = 'Floor amount must be 0 or greater.';
  }
  if (!quickForm.value.noLimit) {
    if (
      quickForm.value.maximum_amount === null ||
      !Number.isFinite(quickForm.value.maximum_amount) ||
      quickForm.value.maximum_amount <= 0
    ) {
      errors.maximum_amount = 'Ceiling amount must be greater than 0.';
    } else if (quickForm.value.maximum_amount <= quickForm.value.minimum_amount) {
      errors.maximum_amount = 'Ceiling must be greater than the floor amount.';
    }
  }
  if (!quickForm.value.effective_from) {
    errors.effective_from = 'Effective from date is required.';
  }
  if (
    quickForm.value.effective_from &&
    quickForm.value.effective_to &&
    quickForm.value.effective_to < quickForm.value.effective_from
  ) {
    errors.effective_to = 'Effective to must be on or after the start date.';
  }

  if (
    quickForm.value.is_mandatory &&
    !errors.minimum_amount &&
    !errors.maximum_amount &&
    !errors.effective_from &&
    !errors.effective_to
  ) {
    const editedBand = thresholdBandsStore.value.find((band) => band.id === editingId.value);
    const entityId = editedBand?.entity_id ?? 2;
    const minimumAmount = Number(quickForm.value.minimum_amount);
    const maximumAmount = quickForm.value.noLimit
      ? null
      : Number(quickForm.value.maximum_amount);
    const categoryId = quickForm.value.procurement_category_id
      ? Number(quickForm.value.procurement_category_id)
      : null;
    const unitId = quickForm.value.procurement_unit_id
      ? Number(quickForm.value.procurement_unit_id)
      : null;
    const overlaps = thresholdBandsStore.value.some((band) => {
      if (
        !band.is_mandatory ||
        band.entity_id !== entityId ||
        band.id === editingId.value
      ) {
        return false;
      }

      const categoryOverlaps =
        band.procurement_category_id === null ||
        categoryId === null ||
        band.procurement_category_id === categoryId;
      const unitOverlaps =
        band.procurement_unit_id === null ||
        unitId === null ||
        band.procurement_unit_id === unitId;
      const amountOverlaps =
        (band.maximum_amount === null || minimumAmount <= band.maximum_amount) &&
        (maximumAmount === null || band.minimum_amount <= maximumAmount);
      const datesOverlap =
        (!band.effective_to || quickForm.value.effective_from <= band.effective_to) &&
        (!quickForm.value.effective_to || band.effective_from <= quickForm.value.effective_to);

      return categoryOverlaps && unitOverlaps && amountOverlaps && datesOverlap;
    });

    if (overlaps) {
      errors.overlap = 'This mandatory band overlaps an existing band for the same scope and effective dates.';
    }
  }

  if (Object.keys(errors).length > 0) {
    quickErrors.value = errors;
    return;
  }

  const selectedMethod = purchaseMethodsStore.value.find(
    (m) => String(m.id) === quickForm.value.purchase_method_id
  );
  const selectedCat = categoryOptions.find((c) => c.value === quickForm.value.procurement_category_id);
  const selectedU = unitOptions.find((u) => u.value === quickForm.value.procurement_unit_id);

  const finalMax = quickForm.value.noLimit ? null : Number(quickForm.value.maximum_amount);
  const catId = quickForm.value.procurement_category_id ? Number(quickForm.value.procurement_category_id) : null;
  const unitId = quickForm.value.procurement_unit_id ? Number(quickForm.value.procurement_unit_id) : null;

  if (editingId.value) {
    const idx = thresholdBandsStore.value.findIndex((b) => b.id === editingId.value);
    if (idx !== -1) {
      thresholdBandsStore.value[idx] = {
        ...thresholdBandsStore.value[idx],
        purchase_method_id: Number(quickForm.value.purchase_method_id),
        method_name: selectedMethod ? selectedMethod.name : 'Unknown Method',
        method_code: selectedMethod ? selectedMethod.code : 'CUSTOM',
        minimum_amount: Number(quickForm.value.minimum_amount),
        maximum_amount: finalMax,
        is_mandatory: quickForm.value.is_mandatory,
        procurement_category_id: catId,
        category_name: selectedCat && selectedCat.value ? selectedCat.label : 'All Categories',
        procurement_unit_id: unitId,
        unit_name: selectedU && selectedU.value ? selectedU.label : 'All Buying Units',
        effective_from: quickForm.value.effective_from,
        effective_to: quickForm.value.effective_to || null
      };
      showToast('Spend threshold band updated successfully.');
    }
  } else {
    const nextId = Date.now();
    const newBand: PurchaseMethodThresholdRecord = {
      id: nextId,
      uuid: `pmt-uuid-${nextId}`,
      purchase_method_id: Number(quickForm.value.purchase_method_id),
      method_name: selectedMethod ? selectedMethod.name : 'Unknown Method',
      method_code: selectedMethod ? selectedMethod.code : 'CUSTOM',
      minimum_amount: Number(quickForm.value.minimum_amount),
      maximum_amount: finalMax,
      currency_code: 'ETB',
      is_mandatory: quickForm.value.is_mandatory,
      procurement_category_id: catId,
      category_name: selectedCat && selectedCat.value ? selectedCat.label : 'All Categories',
      procurement_unit_id: unitId,
      unit_name: selectedU && selectedU.value ? selectedU.label : 'All Buying Units',
      effective_from: quickForm.value.effective_from,
      effective_to: quickForm.value.effective_to || null,
      entity_id: 2,
      state: 'active'
    };
    thresholdBandsStore.value.unshift(newBand);
    showToast('Spend threshold band created successfully.');
  }

  showQuickModal.value = false;
};

// ─── Actions Dropdown Menu (3-Dot Kebab Standard) ───
const activeActionMenuId = ref<number | null>(null);

const toggleActionMenu = (id: number, event: MouseEvent) => {
  event.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
};

const handleToggleBandState = (band: PurchaseMethodThresholdRecord) => {
  band.state = band.state === 'active' ? 'inactive' : 'active';
  showToast(`Spend threshold band is now ${band.state}.`);
};

const handleActionMenuOutsideClick = (event: MouseEvent) => {
  if (activeActionMenuId.value !== null) {
    const target = event.target as HTMLElement | null;
    if (!target?.closest('.action-dropdown-wrapper')) {
      closeActionMenu();
    }
  }
};

// ─── Single Row Actions ───
const openInspectDrawer = (band: PurchaseMethodThresholdRecord) => {
  inspectingBand.value = band;
};

const closeInspectDrawer = () => {
  inspectingBand.value = null;
};

const handleDeleteBand = (band: PurchaseMethodThresholdRecord) => {
  thresholdBandsStore.value = thresholdBandsStore.value.filter((b) => b.id !== band.id);
  selectedRowIds.value = selectedRowIds.value.filter((i) => i !== band.id);
  if (inspectingBand.value?.id === band.id) {
    inspectingBand.value = null;
  }
  showToast(`Deleted spend threshold band rule.`);
};

// ─── Bulk Actions ───
const handleBatchDelete = () => {
  const count = selectedRowIds.value.length;
  if (!count) return;
  thresholdBandsStore.value = thresholdBandsStore.value.filter((b) => !selectedRowIds.value.includes(b.id));
  selectedRowIds.value = [];
  showToast(`Deleted ${count} spend threshold band(s).`);
};

const handleBatchToggleState = () => {
  const count = selectedRowIds.value.length;
  if (!count) return;
  thresholdBandsStore.value.forEach((b) => {
    if (selectedRowIds.value.includes(b.id)) {
      b.state = b.state === 'active' ? 'inactive' : 'active';
    }
  });
  showToast(`Updated state for ${count} threshold band(s).`);
};

// ─── Underlying Statutory Specs for Drawer ───
const inspectingMethodSpecs = computed<PurchaseMethodRecord | null>(() => {
  if (!inspectingBand.value) return null;
  return (
    purchaseMethodsStore.value.find((m) => m.id === inspectingBand.value?.purchase_method_id) || null
  );
});

// ─── Column Helpers ───
const isColVisible = (colKey: string) => {
  const col = columns.value.find((c) => c.key === colKey);
  return col ? col.visible !== false : true;
};

const handleToggleColumn = (key: string) => {
  const column = columns.value.find((item) => item.key === key);
  if (column && column.hideable !== false) {
    column.visible = column.visible === false;
  }
};

const updateColumnPopoverPosition = () => {
  const trigger = columnToggleRef.value;
  if (!trigger) return;

  const rect = trigger.getBoundingClientRect();
  const width = 240;
  const height = columnPopoverRef.value?.getBoundingClientRect().height ?? 300;
  const left = Math.min(
    window.innerWidth - width - 8,
    Math.max(8, rect.right - width)
  );
  const top = rect.bottom + height > window.innerHeight
    ? Math.max(8, rect.top - height - 8)
    : rect.bottom + 8;

  columnPopoverPosition.value = { top, left };
};

const closeColumnHider = () => {
  isColumnHiderOpen.value = false;
  window.removeEventListener('resize', updateColumnPopoverPosition);
  window.removeEventListener('scroll', updateColumnPopoverPosition, true);
  document.removeEventListener('pointerdown', handleColumnPopoverOutsideClick);
  document.removeEventListener('keydown', handleColumnPopoverKeydown);
};

const handleColumnPopoverOutsideClick = (event: PointerEvent) => {
  const target = event.target as Node;
  if (
    !columnToggleRef.value?.contains(target) &&
    !columnPopoverRef.value?.contains(target)
  ) {
    closeColumnHider();
  }
};

const handleColumnPopoverKeydown = (event: KeyboardEvent) => {
  if (event.key === 'Escape') closeColumnHider();
};

const toggleColumnHider = async () => {
  if (isColumnHiderOpen.value) {
    closeColumnHider();
    return;
  }

  isColumnHiderOpen.value = true;
  await nextTick();
  updateColumnPopoverPosition();
  window.addEventListener('resize', updateColumnPopoverPosition);
  window.addEventListener('scroll', updateColumnPopoverPosition, true);
  document.addEventListener('pointerdown', handleColumnPopoverOutsideClick);
  document.addEventListener('keydown', handleColumnPopoverKeydown);
};

onMounted(() => {
  window.addEventListener('click', handleActionMenuOutsideClick);
});

onUnmounted(() => {
  window.removeEventListener('click', handleActionMenuOutsideClick);
  closeColumnHider();
});
</script>

<template>
  <div class="spend-thresholds-view">
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" :noMargin="true" />
    </div>

    <AppDataTable
      title="Spend Threshold Bands"
      subtitle="Configure statutory procurement procedures, value bands, and category or buying desk scope."
      v-model:searchQuery="searchQuery"
      searchPlaceholder="Search by method, category, or buying desk..."
      :showFilter="true"
      :filterCount="activeFilterCount"
      :showSort="true"
      :sortOptions="sortOptions"
      v-model:currentSort="currentSortKey"
      v-model:sortOrder="sortOrder"
      :showColumns="false"
      :columns="columns"
      :totalEntries="filteredBands.length"
      :showPagination="true"
      v-model:currentPage="currentPage"
      v-model:perPage="perPage"
      @toggleColumn="handleToggleColumn"
    >
      <template #actions>
        <AppButton variant="primary" size="sm" @click="openQuickCreateModal">
          <template #icon-left>
            <Plus :size="15" />
          </template>
          Create Threshold Band
        </AppButton>
      </template>

      <template #toolbar-right>
        <button
          ref="columnToggleRef"
          type="button"
          class="btn-column-toggle"
          title="Customize columns"
          aria-label="Customize table columns"
          :aria-expanded="isColumnHiderOpen"
          @click.stop="toggleColumnHider"
        >
          <IconColumnSolid :size="16" />
        </button>

        <Teleport to="body">
          <div
            v-if="isColumnHiderOpen"
            ref="columnPopoverRef"
            class="column-hider-popover"
            :style="{
              top: `${columnPopoverPosition.top}px`,
              left: `${columnPopoverPosition.left}px`
            }"
            role="dialog"
            aria-label="Table columns"
            @click.stop
          >
            <div class="column-hider-title">Table Columns</div>
            <div class="column-hider-list">
              <FormCheckbox
                v-for="column in columns.filter((item) => item.hideable !== false)"
                :key="column.key"
                :model-value="column.visible !== false"
                :label="column.label"
                size="sm"
                @update:model-value="handleToggleColumn(column.key)"
              />
            </div>
          </div>
        </Teleport>
      </template>

      <template #filter-panel>
        <div class="filter-panel-grid">
          <FormSelect
            v-model="filterMethodId"
            :options="[{ value: '', label: 'All Statutory Methods' }, ...methodOptions]"
            label="Filter by Method"
            placeholder="All Statutory Methods"
            :teleport="true"
          />

          <FormSelect
            v-model="filterEnforcement"
            :options="enforcementFilterOptions"
            label="Policy Enforcement"
            placeholder="All Enforcement Types"
            :teleport="true"
          />

          <FormSelect
            v-model="filterCategory"
            :options="categoryOptions"
            label="Category Scope"
            placeholder="All Categories"
            :teleport="true"
          />

          <FormSelect
            v-model="filterUnit"
            :options="unitOptions"
            label="Buying Desk Scope"
            placeholder="All Buying Desks"
            :teleport="true"
          />

          <FormSelect
            v-model="filterState"
            :options="stateFilterOptions"
            label="State"
            placeholder="All States"
            :teleport="true"
          />
        </div>

        <div class="filter-panel-footer">
          <AppButton variant="secondary" size="sm" @click="resetFilter">
            Reset Filters
          </AppButton>
        </div>
      </template>

      <table class="erp-table">
        <thead>
          <tr>
            <th v-if="isColVisible('method_name')">
              <div class="th-content-with-checkbox">
                <FormCheckbox
                  :model-value="isAllSelected"
                  :indeterminate="isSomeSelected"
                  size="md"
                  @click.stop
                  @update:model-value="handleSelectAll"
                >
                  <span class="sr-only">Select all threshold bands on this page</span>
                </FormCheckbox>
                <span>Purchase Method</span>
              </div>
            </th>
            <th v-if="isColVisible('amount_range')">Order Value Band (ETB)</th>
            <th v-if="isColVisible('is_mandatory')">Enforcement</th>
            <th v-if="isColVisible('category_name')">Category Scope</th>
            <th v-if="isColVisible('unit_name')">Buying Desk Scope</th>
            <th v-if="isColVisible('effective_range')">Validity Period</th>
            <th v-if="isColVisible('state')">State</th>
            <th v-if="isColVisible('actions')" class="col-actions">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="paginatedBands.length === 0">
            <td :colspan="visibleColumnCount" class="empty-state-cell">
              No spend threshold bands found. Adjust your search or filters, or create a new band.
            </td>
          </tr>
          <tr
            v-for="row in paginatedBands"
            :key="row.id"
            class="erp-row"
            :class="{ 'row-selected': selectedRowIds.includes(row.id) }"
          >
            <td v-if="isColVisible('method_name')" class="td-name">
              <div class="identity-cell-content">
                <FormCheckbox
                  :model-value="selectedRowIds.includes(row.id)"
                  size="md"
                  @click.stop
                  @update:model-value="(checked: boolean) => handleSelectRow(row.id, checked)"
                >
                  <span class="sr-only">Select {{ row.method_name }} threshold band</span>
                </FormCheckbox>
                <div class="name-cell-stack">
                  <span class="method-title">{{ row.method_name }}</span>
                  <span class="table-code-subtext">{{ row.method_code }}</span>
                </div>
              </div>
            </td>
            <td v-if="isColVisible('amount_range')">
              <div class="value-band-cell">
                <span class="amount-primary">{{ formatCurrency(row.minimum_amount) }}</span>
                <span class="amount-separator">to</span>
                <span v-if="row.maximum_amount !== null" class="amount-primary">
                  {{ formatCurrency(row.maximum_amount) }}
                </span>
                <span v-else class="amount-unlimited">Open Ceiling (No Limit)</span>
              </div>
            </td>
            <td v-if="isColVisible('is_mandatory')">
              <BaseBadge :color="getEnforcementBadgeColor(row.is_mandatory)" size="sm">
                {{ row.is_mandatory ? 'Mandatory' : 'Permissive' }}
              </BaseBadge>
            </td>
            <td v-if="isColVisible('category_name')">
              <span class="tertiary-plain-text">{{ row.category_name || 'All Categories' }}</span>
            </td>
            <td v-if="isColVisible('unit_name')">
              <span class="tertiary-plain-text">{{ row.unit_name || 'All Buying Desks' }}</span>
            </td>
            <td v-if="isColVisible('effective_range')">
              <span class="validity-text">{{ row.effective_from }} — {{ row.effective_to || 'Ongoing' }}</span>
            </td>
            <td v-if="isColVisible('state')">
              <BaseBadge :color="row.state === 'active' ? 'success' : 'gray'" size="sm">
                {{ row.state === 'active' ? 'Active' : 'Inactive' }}
              </BaseBadge>
            </td>
            <td v-if="isColVisible('actions')" class="col-actions">
              <div class="action-dropdown-wrapper" @click.stop>
                <button
                  type="button"
                  class="btn-action-dots"
                  title="More actions"
                  @click="toggleActionMenu(row.id, $event)"
                >
                  <MoreVertical :size="15" />
                </button>

                <!-- Popup Dropdown Menu -->
                <div
                  v-if="activeActionMenuId === row.id"
                  class="action-menu-popup"
                  @click.stop
                >
                  <button
                    type="button"
                    class="menu-item"
                    @click="() => { closeActionMenu(); openInspectDrawer(row); }"
                  >
                    <Eye :size="14" />
                    <span>Inspect Specs</span>
                  </button>
                  <button
                    type="button"
                    class="menu-item"
                    @click="() => { closeActionMenu(); openEditModal(row); }"
                  >
                    <Edit2 :size="14" />
                    <span>Edit Band</span>
                  </button>
                  <button
                    type="button"
                    class="menu-item"
                    @click="() => { closeActionMenu(); handleToggleBandState(row); }"
                  >
                    <Check :size="14" />
                    <span>{{ row.state === 'active' ? 'Deactivate Band' : 'Activate Band' }}</span>
                  </button>
                  <div class="menu-divider"></div>
                  <button
                    type="button"
                    class="menu-item danger"
                    @click="() => { closeActionMenu(); handleDeleteBand(row); }"
                  >
                    <Trash2 :size="14" />
                    <span>Delete Band</span>
                  </button>
                </div>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </AppDataTable>

    <!-- Floating Batch Action Bar (AGENTS.md & Table Architecture) -->
    <TableFloatingBar
      :show="selectedRowIds.length > 0"
      :selected-count="selectedRowIds.length"
      @clear-selection="selectedRowIds = []"
    >
      <template #actions>
        <AppButton variant="secondary" size="sm" @click="handleBatchToggleState">
          Toggle Active State
        </AppButton>
        <AppButton variant="destructive" size="sm" @click="handleBatchDelete">
          Delete Selected
        </AppButton>
      </template>
    </TableFloatingBar>

    <!-- Quick Create / Edit Modal (creation-ux.instructions.md <= 5-7 fields, zero child lines) -->
    <QuickCreateModal
      v-model:show="showQuickModal"
      :title="editingId ? 'Edit Spend Threshold Band' : 'Create Spend Threshold Band'"
      :show-expand-button="false"
      width="md"
      @save="handleSaveBand"
    >
      <div class="modal-form-grid">
        <p v-if="quickErrors.overlap" class="form-error-message" role="alert">
          {{ quickErrors.overlap }}
        </p>

        <!-- Statutory Purchase Method -->
        <div class="form-row-full">
          <FormSelect
            v-model="quickForm.purchase_method_id"
            :options="methodOptions"
            label="Statutory Purchase Method"
            placeholder="Select Method"
            :error="quickErrors.purchase_method_id"
            required
            :teleport="true"
          />
        </div>

        <!-- Value Floor & Ceiling -->
        <div class="form-row-split">
          <FormInput
            v-model.number="quickForm.minimum_amount"
            type="number"
            :step="0.01"
            label="Floor Value (Minimum ETB)"
            :error="quickErrors.minimum_amount"
            required
          />

          <FormInput
            v-model.number="quickForm.maximum_amount"
            type="number"
            :step="0.01"
            label="Ceiling Value (Maximum ETB)"
            :disabled="quickForm.noLimit"
            :error="quickErrors.maximum_amount"
          />
        </div>

        <!-- No Limit Toggle -->
        <div class="form-row-full">
          <FormCheckbox
            v-model="quickForm.noLimit"
            label="No Upper Limit (Open Ceiling)"
            description="Expenditures exceeding the floor value will route through this method without a cap."
          />
        </div>

        <!-- Mandatory Policy Enforcement -->
        <div class="form-row-full">
          <FormCheckbox
            v-model="quickForm.is_mandatory"
            label="Mandatory Policy Enforcement"
            description="True forces the purchase method; false permits it as an authorized optional method."
          />
        </div>

        <!-- Category & Unit Scope -->
        <div class="form-row-split">
          <FormSelect
            v-model="quickForm.procurement_category_id"
            :options="categoryScopeOptions"
            label="Category Scope (Optional)"
            placeholder="Select Scope"
            :teleport="true"
          />

          <FormSelect
            v-model="quickForm.procurement_unit_id"
            :options="unitScopeOptions"
            label="Buying Desk Scope (Optional)"
            placeholder="Select Scope"
            :teleport="true"
          />
        </div>

        <!-- Effective Validity Dates -->
        <div class="form-row-split">
          <FormInput
            v-model="quickForm.effective_from"
            type="date"
            label="Effective From"
            :error="quickErrors.effective_from"
            required
          />

          <FormInput
            v-model="quickForm.effective_to"
            type="date"
            label="Effective To (Optional)"
            :error="quickErrors.effective_to"
          />
        </div>
      </div>
    </QuickCreateModal>

    <!-- Slide-over Inspection Drawer for Deep Legal & Policy Specs -->
    <Teleport to="body">
      <div v-if="inspectingBand" class="drawer-backdrop" @click.self="closeInspectDrawer">
        <div class="drawer-panel">
          <div class="drawer-header">
            <div class="drawer-header-title">
              <Scale :size="18" class="drawer-header-icon" />
              <div>
                <h2>{{ inspectingBand.method_name }}</h2>
                <span class="drawer-subtitle">
                  Threshold Policy Rule #{{ inspectingBand.id }}
                </span>
              </div>
            </div>
            <button type="button" class="btn-drawer-close" @click="closeInspectDrawer">
              <X :size="18" />
            </button>
          </div>

          <div class="drawer-body">
            <!-- Section 1: Financial Range & Enforcement -->
            <div class="drawer-card">
              <h3 class="card-section-title">Financial Value Band</h3>
              <div class="drawer-metric-grid">
                <div class="metric-box">
                  <span class="metric-label">Floor Amount</span>
                  <span class="metric-val">{{ formatCurrency(inspectingBand.minimum_amount) }}</span>
                </div>
                <div class="metric-box">
                  <span class="metric-label">Ceiling Amount</span>
                  <span class="metric-val">
                    {{ inspectingBand.maximum_amount !== null ? formatCurrency(inspectingBand.maximum_amount) : 'Open Ceiling' }}
                  </span>
                </div>
                <div class="metric-box">
                  <span class="metric-label">Policy Rule</span>
                  <BaseBadge
                    :color="getEnforcementBadgeColor(inspectingBand.is_mandatory)"
                    size="sm"
                  >
                    {{ inspectingBand.is_mandatory ? 'Mandatory Policy' : 'Permissive Alternative' }}
                  </BaseBadge>
                </div>
                <div class="metric-box">
                  <span class="metric-label">Current State</span>
                  <BaseBadge
                    :color="inspectingBand.state === 'active' ? 'success' : 'gray'"
                    size="sm"
                  >
                    {{ inspectingBand.state === 'active' ? 'Active' : 'Inactive' }}
                  </BaseBadge>
                </div>
              </div>
            </div>

            <!-- Section 2: Underlying Statutory Method Specifications (procurement-v4.sql Lines 364–390) -->
            <div v-if="inspectingMethodSpecs" class="drawer-card">
              <h3 class="card-section-title">
                Statutory Method Specifications
                <span class="spec-legal-ref">[REF: procurement-v4.sql]</span>
              </h3>
              <p class="spec-description">{{ inspectingMethodSpecs.description }}</p>

              <div class="specs-checklist">
                <div class="spec-item">
                  <span class="spec-label">Quotation Quorum</span>
                  <span class="spec-value">
                    {{ inspectingMethodSpecs.minimum_quotations === 0 ? 'None (Single Source)' : `${inspectingMethodSpecs.minimum_quotations} competitive quotations` }}
                  </span>
                </div>
                <div class="spec-item">
                  <span class="spec-label">Tender Committee Evaluation</span>
                  <span class="spec-tag" :class="{ 'tag-yes': inspectingMethodSpecs.requires_committee }">
                    {{ inspectingMethodSpecs.requires_committee ? 'Mandatory Committee' : 'Buyer Level Evaluation' }}
                  </span>
                </div>
                <div class="spec-item">
                  <span class="spec-label">Sealed Bidding Protocol</span>
                  <span class="spec-tag" :class="{ 'tag-yes': inspectingMethodSpecs.requires_sealed_bid }">
                    {{ inspectingMethodSpecs.requires_sealed_bid ? 'Simultaneous Opening' : 'Standard Quotation' }}
                  </span>
                </div>
                <div class="spec-item">
                  <span class="spec-label">Emergency Post-Facto Ratification</span>
                  <span class="spec-tag" :class="{ 'tag-warning': inspectingMethodSpecs.requires_post_facto_approval }">
                    {{ inspectingMethodSpecs.requires_post_facto_approval ? 'Post-Facto Ratified' : 'Pre-Approval Required' }}
                  </span>
                </div>
                <div class="spec-item">
                  <span class="spec-label">Single-Source Allowed</span>
                  <span class="spec-tag">
                    {{ inspectingMethodSpecs.allows_single_source ? 'Allowed' : 'Competitive Only' }}
                  </span>
                </div>
                <div class="spec-item">
                  <span class="spec-label">Invitation Scope</span>
                  <span class="spec-tag">
                    {{ inspectingMethodSpecs.is_open_invitation ? 'Public Advertisement' : 'Invited Pre-Qualified' }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Section 3: Organizational Applicability -->
            <div class="drawer-card">
              <h3 class="card-section-title">Applicability & Validity</h3>
              <div class="scope-grid">
                <div class="scope-row">
                  <FolderTree :size="16" class="scope-icon" />
                  <div>
                    <span class="scope-title">Procurement Category</span>
                    <span class="scope-detail">{{ inspectingBand.category_name || 'All Categories (Global Scope)' }}</span>
                  </div>
                </div>
                <div class="scope-row">
                  <Building2 :size="16" class="scope-icon" />
                  <div>
                    <span class="scope-title">Buying Desk</span>
                    <span class="scope-detail">{{ inspectingBand.unit_name || 'All Buying Desks (Global Scope)' }}</span>
                  </div>
                </div>
                <div class="scope-row">
                  <Info :size="16" class="scope-icon" />
                  <div>
                    <span class="scope-title">Effective Date Window</span>
                    <span class="scope-detail">{{ inspectingBand.effective_from }} — {{ inspectingBand.effective_to || 'Ongoing' }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="drawer-footer">
            <AppButton variant="secondary" size="md" @click="closeInspectDrawer">
              Close
            </AppButton>
            <AppButton
              variant="primary"
              size="md"
              @click="() => { const b = inspectingBand; closeInspectDrawer(); if (b) openEditModal(b); }"
            >
              Edit Threshold Band
            </AppButton>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.spend-thresholds-view {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.btn-column-toggle {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  color: #404040;
  cursor: pointer;
  transition: background-color 0.15s, border-color 0.15s;
}

.btn-column-toggle:hover {
  background-color: #fafafa;
  border-color: #d4d4d4;
}

/* Column Hider Popover */
.column-hider-popover {
  position: fixed;
  width: 240px;
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  padding: 12px;
  z-index: 10000;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.column-hider-title {
  font-size: 12px;
  font-weight: 600;
  color: #404040;
  padding-bottom: 6px;
  border-bottom: 1px solid #f0f0f0;
}

.column-hider-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 260px;
  overflow-y: auto;
}

.filter-panel-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 14px;
}

.filter-panel-footer {
  display: flex;
  justify-content: flex-end;
  margin-top: 12px;
}

/* Table Cells Formatting */
.th-content-with-checkbox {
  display: flex;
  align-items: center;
  gap: 10px;
}

.identity-cell-content {
  display: flex;
  align-items: center;
  gap: 10px;
}

.method-title {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.value-band-cell {
  display: flex;
  align-items: center;
  gap: 6px;
  font-variant-numeric: tabular-nums;
  font-size: 13px;
}

.amount-primary {
  font-weight: 500;
  color: #404040;
}

.amount-separator {
  color: #737373;
  font-size: 12px;
}

.amount-unlimited {
  color: #0B529C;
  font-weight: 500;
  font-size: 12px;
}

.tertiary-plain-text {
  font-size: 13px;
  color: #737373;
}

.validity-text {
  font-size: 12px;
  color: #737373;
  font-variant-numeric: tabular-nums;
}

.col-actions {
  text-align: right;
  position: relative;
}

.action-dropdown-wrapper {
  position: relative;
  display: inline-flex;
  justify-content: flex-end;
}

.btn-action-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: 1px solid transparent;
  background-color: transparent;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-action-dots:hover {
  background-color: #f5f5f5;
  color: #404040;
  border-color: #e5e5e5;
}

.action-menu-popup {
  position: absolute;
  top: 100%;
  right: 0;
  margin-top: 4px;
  z-index: 50;
  min-width: 175px;
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  padding: 4px;
  display: flex;
  flex-direction: column;
}

.menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  font-size: 13px;
  color: #404040;
  background: transparent;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.12s;
  white-space: nowrap;
}

.menu-item:hover {
  background-color: #f5f5f5;
  color: #0b529c;
}

.menu-item.danger {
  color: #e7000b;
}

.menu-item.danger:hover {
  background-color: #fef2f2;
}

.menu-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 4px 0;
}

.empty-state-cell {
  padding: 24px;
  color: #737373;
  text-align: center;
}

/* Modal Form Styles */
.modal-form-grid {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-error-message {
  margin: 0;
  color: #C10007;
  font-size: 12px;
}

.form-row-full {
  width: 100%;
}

.form-row-split {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
}

/* Inspection Drawer */
.drawer-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(0, 0, 0, 0.4);
  z-index: 1000;
  display: flex;
  justify-content: flex-end;
  animation: fadeIn 0.15s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.drawer-panel {
  width: 480px;
  max-width: 90vw;
  height: 100%;
  background-color: #ffffff;
  display: flex;
  flex-direction: column;
  box-shadow: -4px 0 24px rgba(0, 0, 0, 0.12);
  animation: slideDrawer 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes slideDrawer {
  from { transform: translateX(100%); }
  to { transform: translateX(0); }
}

.drawer-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  border-bottom: 1px solid #e5e5e5;
}

.drawer-header-title {
  display: flex;
  align-items: center;
  gap: 12px;
}

.drawer-header-icon {
  color: #0B529C;
}

.drawer-header-title h2 {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.drawer-subtitle {
  font-size: 12px;
  color: #737373;
}

.btn-drawer-close {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 6px;
  border: none;
  background-color: transparent;
  color: #737373;
  cursor: pointer;
}

.btn-drawer-close:hover {
  background-color: #f5f5f5;
  color: #404040;
}

.drawer-body {
  flex: 1;
  overflow-y: auto;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.drawer-card {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 16px;
  border-radius: 8px;
  border: 1px solid #e5e5e5;
  background-color: #fafafa;
}

.card-section-title {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
  margin: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.spec-legal-ref {
  font-size: 10px;
  font-family: monospace;
  color: #737373;
}

.drawer-metric-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.metric-box {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.metric-label {
  font-size: 11px;
  color: #737373;
}

.metric-val {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  font-variant-numeric: tabular-nums;
}

.spec-description {
  font-size: 12px;
  color: #737373;
  line-height: 1.4;
  margin: 0;
}

.specs-checklist {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding-top: 8px;
  border-top: 1px solid #e5e5e5;
}

.spec-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
}

.spec-label {
  color: #737373;
}

.spec-value {
  font-weight: 500;
  color: #404040;
}

.spec-tag {
  font-size: 11px;
  font-weight: 500;
  padding: 2px 6px;
  border-radius: 4px;
  background-color: #f0f0f0;
  color: #737373;
}

.spec-tag.tag-yes {
  background-color: #EFF6FF;
  color: #0B529C;
}

.spec-tag.tag-warning {
  background-color: #FFF7ED;
  color: #E17100;
}

.scope-grid {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.scope-row {
  display: flex;
  align-items: flex-start;
  gap: 10px;
}

.scope-icon {
  color: #737373;
  margin-top: 2px;
  flex-shrink: 0;
}

.scope-title {
  display: block;
  font-size: 11px;
  color: #737373;
}

.scope-detail {
  display: block;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.drawer-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 16px 24px;
  border-top: 1px solid #e5e5e5;
  background-color: #ffffff;
}
</style>
