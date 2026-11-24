<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, ArrowUpDown, MoreVertical, Eye, Edit2, Check, Trash2, Users
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
import BaseBadge from '../../components/BaseBadge.vue';
import {
  committeeMandatesStore,
  committeePurposeOptions,
  coreCommitteeOptions,
  categoryScopeOptions,
  unitScopeOptions,
  entityOptions,
  getPurposeLabel,
  getPurposeBadgeColor,
  getCoreCommittee,
  getEntityName,
  formatAmountBand,
  formatEffectivePeriod,
  type ProcurementCommitteeMandateRecord,
  type ProcurementCommitteePurpose
} from './procurementCommitteeMandateData';

const router = useRouter();
const { toast } = useToast();

// ─── View & Selection State ───
const searchQuery = ref('');
const filterPurpose = ref('');
const filterCommittee = ref('');
const filterCategory = ref('');
const filterUnit = ref('');
const filterState = ref('');
const currentSort = ref('committee_name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const currentPage = ref(1);
const perPage = ref(10);

const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const inspectingMandate = ref<ProcurementCommitteeMandateRecord | null>(null);

// ─── Breadcrumb Navigation (Exact Page Name Only; Transparent Canvas) ───
const breadcrumbItems = computed<BreadcrumbItem[]>(() => {
  if (inspectingMandate.value) {
    return [
      {
        label: 'Committee Mandates',
        to: '/procurement/committee-mandates',
        onClick: () => {
          inspectingMandate.value = null;
        }
      },
      {
        label: `${inspectingMandate.value.committee_name} · ${getPurposeLabel(inspectingMandate.value.purpose)}`
      }
    ];
  }
  return [{ label: 'Committee Mandates' }];
});

// ─── Table Columns & Column Hider ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'committee', label: 'Committee', visible: true, sortable: true, hideable: false },
  { key: 'purpose', label: 'Purpose', visible: true, sortable: true },
  { key: 'value_band', label: 'Value Band', visible: true, sortable: true },
  { key: 'quorum', label: 'Quorum', visible: true, sortable: true },
  { key: 'scope', label: 'Scope', visible: true, sortable: false },
  { key: 'effective_dates', label: 'Effective Dates', visible: true, sortable: true },
  { key: 'entity', label: 'Owning Entity', visible: false, sortable: false },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

const sortOptions: SortOption[] = [
  { key: 'committee_name', label: 'Committee Name' },
  { key: 'purpose', label: 'Procurement Purpose' },
  { key: 'minimum_amount', label: 'Value Band Floor' },
  { key: 'quorum', label: 'Quorum' },
  { key: 'effective_from', label: 'Effective From' },
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
  if (col && col.hideable !== false) {
    col.visible = col.visible === false;
  }
};

// ─── Filters & Sorting ───
const activeFilterCount = computed(() => {
  let count = 0;
  if (filterPurpose.value) count++;
  if (filterCommittee.value) count++;
  if (filterCategory.value) count++;
  if (filterUnit.value) count++;
  if (filterState.value) count++;
  return count;
});

const resetFilters = () => {
  filterPurpose.value = '';
  filterCommittee.value = '';
  filterCategory.value = '';
  filterUnit.value = '';
  filterState.value = '';
  searchQuery.value = '';
  currentPage.value = 1;
};

const filteredMandates = computed(() => {
  const q = searchQuery.value.trim().toLowerCase();
  const list = committeeMandatesStore.value.filter((item) => {
    if (filterPurpose.value && item.purpose !== filterPurpose.value) return false;
    if (filterCommittee.value && String(item.committee_id) !== filterCommittee.value) return false;
    if (filterCategory.value) {
      if (filterCategory.value === 'global' && item.procurement_category_id !== null) return false;
      if (
        filterCategory.value !== 'global' &&
        String(item.procurement_category_id ?? '') !== filterCategory.value
      ) {
        return false;
      }
    }
    if (filterUnit.value) {
      if (filterUnit.value === 'global' && item.procurement_unit_id !== null) return false;
      if (
        filterUnit.value !== 'global' &&
        String(item.procurement_unit_id ?? '') !== filterUnit.value
      ) {
        return false;
      }
    }
    if (filterState.value && item.state !== filterState.value) return false;

    if (q) {
      const haystack = [
        item.committee_name,
        item.committee_code,
        item.committee_chair,
        getPurposeLabel(item.purpose),
        item.category_name || 'All Categories',
        item.unit_name || 'All Units',
        getEntityName(item.entity_id)
      ]
        .join(' ')
        .toLowerCase();
      if (!haystack.includes(q)) return false;
    }
    return true;
  });

  const sorted = [...list].sort((a, b) => {
    const dir = sortOrder.value === 'asc' ? 1 : -1;
    switch (currentSort.value) {
      case 'purpose':
        return getPurposeLabel(a.purpose).localeCompare(getPurposeLabel(b.purpose)) * dir;
      case 'minimum_amount':
        return ((a.minimum_amount ?? -1) - (b.minimum_amount ?? -1)) * dir;
      case 'quorum':
        return (a.quorum - b.quorum) * dir;
      case 'effective_from':
        return a.effective_from.localeCompare(b.effective_from) * dir;
      case 'state':
        return a.state.localeCompare(b.state) * dir;
      case 'committee_name':
      default:
        return a.committee_name.localeCompare(b.committee_name) * dir;
    }
  });

  return sorted;
});

const paginatedMandates = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredMandates.value.slice(start, start + perPage.value);
});

watch([searchQuery, filterPurpose, filterCommittee, filterCategory, filterUnit, filterState], () => {
  currentPage.value = 1;
});

const handleSortColumn = (key: string) => {
  if (currentSort.value === key) {
    sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
  } else {
    currentSort.value = key;
    sortOrder.value = 'asc';
  }
};

// ─── Row Selection (Lead Checkbox) ───
const isAllSelected = computed(() => {
  if (paginatedMandates.value.length === 0) return false;
  return paginatedMandates.value.every((row) => selectedRowIds.value.includes(row.id));
});

const isPartiallySelected = computed(() => {
  if (paginatedMandates.value.length === 0) return false;
  const count = paginatedMandates.value.filter((row) => selectedRowIds.value.includes(row.id)).length;
  return count > 0 && count < paginatedMandates.value.length;
});

const toggleSelectAll = (checked: boolean) => {
  const pageIds = paginatedMandates.value.map((r) => r.id);
  if (checked) {
    const merged = new Set([...selectedRowIds.value, ...pageIds]);
    selectedRowIds.value = Array.from(merged);
  } else {
    selectedRowIds.value = selectedRowIds.value.filter((id) => !pageIds.includes(id));
  }
};

const toggleSelectRow = (id: number, checked: boolean) => {
  if (checked) {
    if (!selectedRowIds.value.includes(id)) {
      selectedRowIds.value = [...selectedRowIds.value, id];
    }
  } else {
    selectedRowIds.value = selectedRowIds.value.filter((rowId) => rowId !== id);
  }
};

// ─── Formatting Helpers ───
const formatScopePrimary = (item: ProcurementCommitteeMandateRecord): string => {
  const cat = item.category_name || 'All Categories';
  const unit = item.unit_name || 'All Units';
  return `${cat} · ${unit}`;
};

const getResolutionTierLabel = (item: ProcurementCommitteeMandateRecord): string => {
  if (item.procurement_category_id && item.procurement_unit_id) {
    return 'Category + Unit Override (Highest Specificity)';
  }
  if (item.procurement_category_id) {
    return 'Category-Specific Override';
  }
  if (item.procurement_unit_id) {
    return 'Unit-Specific Override';
  }
  return 'Entity-Wide Default';
};

// ─── Quick Create Modal (4 Required Schema Fields) ───
const showQuickModal = ref(false);
const quickFieldErrors = ref<{
  committee_id?: string;
  purpose?: string;
  quorum?: string;
  effective_from?: string;
}>({});
const quickForm = ref({
  committee_id: '',
  purpose: '' as ProcurementCommitteePurpose | '',
  quorum: 3,
  effective_from: new Date().toISOString().split('T')[0]
});

watch(
  quickForm,
  () => {
    if (quickForm.value.committee_id) quickFieldErrors.value.committee_id = undefined;
    if (quickForm.value.purpose) quickFieldErrors.value.purpose = undefined;
    if (quickForm.value.quorum >= 1) quickFieldErrors.value.quorum = undefined;
    if (quickForm.value.effective_from) quickFieldErrors.value.effective_from = undefined;
  },
  { deep: true }
);

const openQuickCreateModal = () => {
  quickFieldErrors.value = {};
  quickForm.value = {
    committee_id: '',
    purpose: '',
    quorum: 3,
    effective_from: new Date().toISOString().split('T')[0]
  };
  showQuickModal.value = true;
};

const handleExpandFullForm = () => {
  const query: Record<string, string> = {};
  if (quickForm.value.committee_id) query.committee_id = quickForm.value.committee_id;
  if (quickForm.value.purpose) query.purpose = quickForm.value.purpose;
  if (quickForm.value.quorum) query.quorum = String(quickForm.value.quorum);
  if (quickForm.value.effective_from) query.effective_from = quickForm.value.effective_from;
  showQuickModal.value = false;
  router.push({ path: '/procurement/committee-mandates/create', query });
};

const handleQuickSave = () => {
  const errors: typeof quickFieldErrors.value = {};
  const missing: string[] = [];

  if (!quickForm.value.committee_id) {
    errors.committee_id = 'Core Committee is required.';
    missing.push('Core Committee');
  }
  if (!quickForm.value.purpose) {
    errors.purpose = 'Procurement Purpose is required.';
    missing.push('Procurement Purpose');
  }
  const committee = quickForm.value.committee_id
    ? getCoreCommittee(Number(quickForm.value.committee_id))
    : undefined;
  if (!quickForm.value.quorum || quickForm.value.quorum < 1) {
    errors.quorum = 'Quorum must be at least 1 signed member.';
    missing.push('Valid Quorum');
  } else if (committee && quickForm.value.quorum > committee.memberCount) {
    errors.quorum = `Quorum cannot exceed ${committee.memberCount} members in ${committee.name}.`;
    missing.push('Quorum within Committee Size');
  }
  if (!quickForm.value.effective_from) {
    errors.effective_from = 'Effective From date is required.';
    missing.push('Effective From');
  }

  quickFieldErrors.value = errors;
  if (missing.length > 0) {
    toast.error('Please check the mandate details', `Review: ${missing.join(', ')}.`);
    return;
  }

  const committeeId = Number(quickForm.value.committee_id);
  const purpose = quickForm.value.purpose as ProcurementCommitteePurpose;
  const nextId = Math.max(0, ...committeeMandatesStore.value.map((m) => m.id)) + 1;

  committeeMandatesStore.value.unshift({
    id: nextId,
    uuid: `pcm-${String(nextId).padStart(4, '0')}-${purpose}`,
    committee_id: committeeId,
    committee_code: committee?.code ?? `COM-${committeeId}`,
    committee_name: committee?.name ?? `Committee #${committeeId}`,
    committee_chair: committee?.chair ?? 'Committee Chair',
    committee_member_count: committee?.memberCount ?? Math.max(quickForm.value.quorum, 3),
    purpose,
    quorum: Number(quickForm.value.quorum),
    minimum_amount: 0,
    maximum_amount: null,
    currency_code: 'ETB',
    procurement_unit_id: null,
    procurement_category_id: null,
    effective_from: quickForm.value.effective_from,
    effective_to: null,
    entity_id: 2,
    notes: '',
    state: 'active'
  });

  showQuickModal.value = false;
  toast.success(
    'Committee mandate created',
    `${committee?.name ?? 'Committee'} assigned to ${getPurposeLabel(purpose)} with quorum ${quickForm.value.quorum}.`
  );
};

// ─── Actions & Navigation ───
const goToCreateMandate = () => {
  openQuickCreateModal();
};

const goToEditMandate = (item: ProcurementCommitteeMandateRecord) => {
  activeActionMenuId.value = null;
  router.push(`/procurement/committee-mandates/${item.id}/edit`);
};

const openInspectMandate = (item: ProcurementCommitteeMandateRecord) => {
  activeActionMenuId.value = null;
  inspectingMandate.value = item;
};

const toggleActionMenu = (id: number) => {
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
};

const handleToggleState = (item: ProcurementCommitteeMandateRecord) => {
  item.state = item.state === 'active' ? 'inactive' : 'active';
  toast.success(
    'Committee Mandates',
    `Marked "${item.committee_name} (${getPurposeLabel(item.purpose)})" as ${
      item.state === 'active' ? 'Active' : 'Inactive'
    }.`
  );
  closeActionMenu();
};

const handleDeleteMandate = (item: ProcurementCommitteeMandateRecord) => {
  committeeMandatesStore.value = committeeMandatesStore.value.filter((m) => m.id !== item.id);
  selectedRowIds.value = selectedRowIds.value.filter((id) => id !== item.id);
  if (inspectingMandate.value?.id === item.id) {
    inspectingMandate.value = null;
  }
  toast.success(
    'Committee Mandates',
    `Deleted mandate for "${item.committee_name} (${getPurposeLabel(item.purpose)})".`
  );
  closeActionMenu();
};

const handleBatchStateChange = (newState: 'active' | 'inactive') => {
  const selectedSet = new Set(selectedRowIds.value);
  committeeMandatesStore.value.forEach((m) => {
    if (selectedSet.has(m.id)) {
      m.state = newState;
    }
  });
  toast.success(
    'Committee Mandates',
    `Updated ${selectedRowIds.value.length} selected mandate(s) to ${
      newState === 'active' ? 'Active' : 'Inactive'
    }.`
  );
  selectedRowIds.value = [];
};

const handleBatchDelete = () => {
  const selectedSet = new Set(selectedRowIds.value);
  const count = selectedRowIds.value.length;
  committeeMandatesStore.value = committeeMandatesStore.value.filter((m) => !selectedSet.has(m.id));
  selectedRowIds.value = [];
  toast.success('Committee Mandates', `Deleted ${count} selected committee mandate(s).`);
};

const selectAllFilteredMandates = () => {
  selectedRowIds.value = filteredMandates.value.map((m) => m.id);
};

const handleBatchChangeStatus = (status: string) => {
  const normalized = status.toLowerCase().includes('inactive') ? 'inactive' : 'active';
  handleBatchStateChange(normalized);
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
  <div class="committee-mandates-page">
    <!-- ═══ BREADCRUMB NAVIGATION (Transparent Canvas, Zero Back Buttons) ═══ -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" :noMargin="true" />
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- ISOLATED DETAIL VIEW (Zero Floating Action Buttons)            -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-if="inspectingMandate" class="detail-view-wrapper">
      <div class="detail-card">
        <div class="detail-header-row">
          <div>
            <h2 class="detail-title">{{ inspectingMandate.committee_name }}</h2>
            <span class="detail-code">
              {{ inspectingMandate.committee_code }} · Chair: {{ inspectingMandate.committee_chair }}
            </span>
          </div>
          <div class="detail-badges">
            <BaseBadge size="sm" :color="getPurposeBadgeColor(inspectingMandate.purpose)">
              {{ getPurposeLabel(inspectingMandate.purpose) }}
            </BaseBadge>
            <BaseBadge size="sm" :color="inspectingMandate.state === 'active' ? 'success' : 'gray'">
              {{ inspectingMandate.state === 'active' ? 'Active' : 'Inactive' }}
            </BaseBadge>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-meta-grid">
          <div class="meta-item">
            <span class="meta-label">Minimum Quorum</span>
            <span class="meta-value">
              {{ inspectingMandate.quorum }} of {{ inspectingMandate.committee_member_count }} signed members
            </span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Event Value Band</span>
            <span class="meta-value">
              {{
                formatAmountBand(
                  inspectingMandate.minimum_amount,
                  inspectingMandate.maximum_amount,
                  inspectingMandate.currency_code
                )
              }}
            </span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Resolution Precedence</span>
            <span class="meta-value">{{ getResolutionTierLabel(inspectingMandate) }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Procurement Category Scope</span>
            <span class="meta-value">{{ inspectingMandate.category_name || 'All Categories (Global)' }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Procurement Unit Scope</span>
            <span class="meta-value">{{ inspectingMandate.unit_name || 'All Buying Units (Global)' }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Owning Legal Entity</span>
            <span class="meta-value">{{ getEntityName(inspectingMandate.entity_id) }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Effective Period</span>
            <span class="meta-value">
              {{ formatEffectivePeriod(inspectingMandate.effective_from, inspectingMandate.effective_to) }}
            </span>
          </div>
        </div>

        <template v-if="inspectingMandate.notes">
          <div class="detail-divider"></div>
          <div class="detail-notes-block">
            <span class="meta-label">Mandate Charter & Governance Notes</span>
            <p class="detail-notes-text">{{ inspectingMandate.notes }}</p>
          </div>
        </template>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- DIRECTORY VIEW: STANDARD APP DATA TABLE                        -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <template v-else>
      <AppDataTable
        title="Committee Mandates"
        subtitle="Assign core committees to procurement evaluation, bid opening, inspection, and award review steps with quorum and value band rules."
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search by committee, purpose, category, or unit..."
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
        :totalEntries="filteredMandates.length"
        :showPagination="true"
        v-model:currentPage="currentPage"
        v-model:perPage="perPage"
        @toggleColumn="handleToggleColumn"
        @resetFilter="resetFilters"
      >
        <!-- Primary Action inside Toolbar (Direct Create Page per Tier 2 Rule) -->
        <template #actions>
          <AppButton variant="primary" size="sm" @click="goToCreateMandate">
            <template #icon-left>
              <Plus :size="15" />
            </template>
            Create Mandate
          </AppButton>
        </template>

        <!-- Filter Panel -->
        <template #filter-panel>
          <div class="filter-panel-grid">
            <FormSelect
              label="Procurement Purpose"
              v-model="filterPurpose"
              :options="[{ value: '', label: 'All Purposes' }, ...committeePurposeOptions]"
              placeholder="Select Purpose"
            />
            <FormSelect
              label="Core Committee"
              v-model="filterCommittee"
              :options="[{ value: '', label: 'All Committees' }, ...coreCommitteeOptions]"
              placeholder="Select Committee"
            />
            <FormSelect
              label="Category Scope"
              v-model="filterCategory"
              :options="[
                { value: '', label: 'All Scopes' },
                { value: 'global', label: 'Global (All Categories)' },
                ...categoryScopeOptions
              ]"
              placeholder="Select Category"
            />
            <FormSelect
              label="Unit Scope"
              v-model="filterUnit"
              :options="[
                { value: '', label: 'All Scopes' },
                { value: 'global', label: 'Global (All Units)' },
                ...unitScopeOptions
              ]"
              placeholder="Select Unit"
            />
            <FormSelect
              label="Lifecycle State"
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

        <!-- Table Content (Lead Checkbox integrated into Identity Column) -->
        <table class="erp-table">
          <thead>
            <tr>
              <th
                v-if="isColumnVisible('committee')"
                class="sortable"
                @click="handleSortColumn('committee_name')"
              >
                <div class="th-content name-header-content">
                  <FormCheckbox
                    :model-value="isAllSelected"
                    :indeterminate="isPartiallySelected"
                    size="md"
                    @click.stop
                    @update:model-value="toggleSelectAll"
                  >
                    <span class="sr-only">Select all committee mandates on this page</span>
                  </FormCheckbox>
                  <span>Committee</span>
                  <ArrowUpDown
                    v-if="currentSort === 'committee_name'"
                    :size="12"
                    class="sort-icon active-sort"
                  />
                </div>
              </th>

              <th
                v-if="isColumnVisible('purpose')"
                class="sortable"
                @click="handleSortColumn('purpose')"
              >
                <div class="th-content">
                  <span>Purpose</span>
                  <ArrowUpDown
                    v-if="currentSort === 'purpose'"
                    :size="12"
                    class="sort-icon active-sort"
                  />
                </div>
              </th>

              <th
                v-if="isColumnVisible('value_band')"
                class="sortable"
                @click="handleSortColumn('minimum_amount')"
              >
                <div class="th-content">
                  <span>Value Band</span>
                  <ArrowUpDown
                    v-if="currentSort === 'minimum_amount'"
                    :size="12"
                    class="sort-icon active-sort"
                  />
                </div>
              </th>

              <th
                v-if="isColumnVisible('quorum')"
                class="sortable"
                @click="handleSortColumn('quorum')"
              >
                <div class="th-content">
                  <span>Quorum</span>
                  <ArrowUpDown
                    v-if="currentSort === 'quorum'"
                    :size="12"
                    class="sort-icon active-sort"
                  />
                </div>
              </th>

              <th v-if="isColumnVisible('scope')">
                <div class="th-content"><span>Scope</span></div>
              </th>

              <th
                v-if="isColumnVisible('effective_dates')"
                class="sortable"
                @click="handleSortColumn('effective_from')"
              >
                <div class="th-content">
                  <span>Effective Dates</span>
                  <ArrowUpDown
                    v-if="currentSort === 'effective_from'"
                    :size="12"
                    class="sort-icon active-sort"
                  />
                </div>
              </th>

              <th v-if="isColumnVisible('entity')">
                <div class="th-content"><span>Owning Entity</span></div>
              </th>

              <th
                v-if="isColumnVisible('state')"
                class="sortable"
                @click="handleSortColumn('state')"
              >
                <div class="th-content">
                  <span>State</span>
                  <ArrowUpDown
                    v-if="currentSort === 'state'"
                    :size="12"
                    class="sort-icon active-sort"
                  />
                </div>
              </th>

              <th v-if="isColumnVisible('actions')" class="col-actions-header">
                <div class="th-content th-actions"><span>Actions</span></div>
              </th>
            </tr>
          </thead>

          <tbody>
            <tr v-if="paginatedMandates.length === 0">
              <td :colspan="visibleColumnCount" class="empty-table-cell">
                <div class="empty-state">
                  <Users :size="28" class="empty-icon" />
                  <p class="empty-title">No committee mandates found</p>
                  <p class="empty-subtitle">
                    Adjust your filters or create a new committee mandate to govern procurement steps.
                  </p>
                </div>
              </td>
            </tr>

            <tr
              v-for="item in paginatedMandates"
              :key="item.id"
              class="table-row"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
            >
              <!-- Lead Identity Column with Integrated Checkbox -->
              <td v-if="isColumnVisible('committee')" class="identity-cell">
                <div class="lead-identity-wrapper">
                  <FormCheckbox
                    :model-value="selectedRowIds.includes(item.id)"
                    size="md"
                    @click.stop
                    @update:model-value="(val) => toggleSelectRow(item.id, Boolean(val))"
                  >
                    <span class="sr-only">Select {{ item.committee_name }}</span>
                  </FormCheckbox>
                  <button
                    type="button"
                    class="identity-text-btn"
                    @click="openInspectMandate(item)"
                  >
                    <span class="identity-primary">{{ item.committee_name }}</span>
                    <span class="identity-secondary">{{ item.committee_code }}</span>
                  </button>
                </div>
              </td>

              <!-- Purpose Lookup (Semantic Badge for high-signal procurement step) -->
              <td v-if="isColumnVisible('purpose')">
                <BaseBadge size="sm" :color="getPurposeBadgeColor(item.purpose)">
                  {{ getPurposeLabel(item.purpose) }}
                </BaseBadge>
              </td>

              <!-- Value Band -->
              <td v-if="isColumnVisible('value_band')">
                <span class="secondary-text-cell">
                  {{ formatAmountBand(item.minimum_amount, item.maximum_amount, item.currency_code) }}
                </span>
              </td>

              <!-- Quorum -->
              <td v-if="isColumnVisible('quorum')">
                <span class="secondary-text-cell">
                  {{ item.quorum }} / {{ item.committee_member_count }} members
                </span>
              </td>

              <!-- Scope (Plain Tertiary Text — avoids badge clutter) -->
              <td v-if="isColumnVisible('scope')">
                <span class="tertiary-plain-text">{{ formatScopePrimary(item) }}</span>
              </td>

              <!-- Effective Dates -->
              <td v-if="isColumnVisible('effective_dates')">
                <span class="tertiary-plain-text">
                  {{ formatEffectivePeriod(item.effective_from, item.effective_to) }}
                </span>
              </td>

              <!-- Owning Entity (Hidden by default, toggleable) -->
              <td v-if="isColumnVisible('entity')">
                <span class="tertiary-plain-text">{{ getEntityName(item.entity_id) }}</span>
              </td>

              <!-- State (Always BaseBadge: success / gray) -->
              <td v-if="isColumnVisible('state')">
                <BaseBadge size="sm" :color="item.state === 'active' ? 'success' : 'gray'">
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </BaseBadge>
              </td>

              <!-- Actions (3-Dot Kebab Menu) -->
              <td v-if="isColumnVisible('actions')" class="col-actions">
                <div class="action-menu-container">
                  <button
                    type="button"
                    class="kebab-trigger"
                    aria-label="Mandate actions"
                    @click.stop="toggleActionMenu(item.id)"
                  >
                    <MoreVertical :size="16" />
                  </button>

                  <div v-if="activeActionMenuId === item.id" class="action-dropdown" @click.stop>
                    <button
                      type="button"
                      class="action-dropdown-item"
                      @click="openInspectMandate(item)"
                    >
                      <Eye :size="14" />
                      <span>View Details</span>
                    </button>
                    <button
                      type="button"
                      class="action-dropdown-item"
                      @click="goToEditMandate(item)"
                    >
                      <Edit2 :size="14" />
                      <span>Edit Mandate</span>
                    </button>
                    <button
                      type="button"
                      class="action-dropdown-item"
                      @click="handleToggleState(item)"
                    >
                      <Check :size="14" />
                      <span>{{ item.state === 'active' ? 'Deactivate' : 'Activate' }}</span>
                    </button>
                    <div class="action-dropdown-divider"></div>
                    <button
                      type="button"
                      class="action-dropdown-item danger"
                      @click="handleDeleteMandate(item)"
                    >
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

      <!-- Floating Bulk Action Bar -->
      <TableFloatingBar
        :show="selectedRowIds.length > 0"
        :selected-count="selectedRowIds.length"
        :total-count="filteredMandates.length"
        :show-duplicate="false"
        :show-edit="false"
        @changeStatus="handleBatchChangeStatus"
        @deactivate="handleBatchStateChange('inactive')"
        @delete="handleBatchDelete"
        @selectAll="selectAllFilteredMandates"
        @close="selectedRowIds = []"
        @clear="selectedRowIds = []"
      />
    </template>

    <!-- ═══ QUICK CREATE MODAL (4 Required Schema Fields) ═══ -->
    <QuickCreateModal
      v-model:show="showQuickModal"
      title="Create Committee Mandate"
      width="md"
      @expand="handleExpandFullForm"
      @save="handleQuickSave"
    >
      <div class="quick-modal-form">
        <div class="modal-grid-2">
          <FormSelect
            v-model="quickForm.committee_id"
            label="Core Committee"
            :options="coreCommitteeOptions"
            placeholder="Select Committee"
            :error="quickFieldErrors.committee_id"
            required
          />
          <FormSelect
            v-model="quickForm.purpose"
            label="Procurement Purpose"
            :options="committeePurposeOptions"
            placeholder="Select Purpose"
            :error="quickFieldErrors.purpose"
            required
          />
        </div>

        <div class="modal-grid-2">
          <FormInput
            v-model.number="quickForm.quorum"
            type="number"
            label="Minimum Quorum"
            :error="quickFieldErrors.quorum"
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
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.committee-mandates-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.breadcrumb-container {
  background: transparent;
  border: none;
  box-shadow: none;
  padding: 0;
}

/* ─── Detail Dossier Card ─── */
.detail-view-wrapper {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.detail-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  padding: 24px;
}

.detail-header-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}

.detail-title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #404040;
}

.detail-code {
  display: inline-block;
  margin-top: 4px;
  font-size: 13px;
  color: #737373;
}

.detail-badges {
  display: flex;
  align-items: center;
  gap: 8px;
}

.detail-divider {
  height: 1px;
  background-color: #e5e5e5;
  margin: 20px 0;
}

.detail-meta-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 20px;
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
  font-size: 14px;
  font-weight: 500;
  color: #404040;
}

.detail-notes-block {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.detail-notes-text {
  margin: 0;
  font-size: 14px;
  line-height: 1.6;
  color: #404040;
}

/* ─── Filter Panel ─── */
.filter-panel-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
}

.filter-panel-footer {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}

/* ─── Table Styles (QMT Standard) ─── */
.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table thead tr {
  background-color: #fafafa;
  border-bottom: 1px solid #e5e5e5;
}

.erp-table th {
  height: 44px;
  padding: 0 16px;
  text-align: left;
  font-size: 12px;
  font-weight: 600;
  color: #737373;
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
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.name-header-content {
  gap: 12px;
}

.th-actions {
  justify-content: center;
  width: 100%;
}

.sort-icon {
  color: #737373;
}

.sort-icon.active-sort {
  color: #404040;
}

.erp-table tbody tr.table-row {
  border-bottom: 1px solid #e5e5e5;
  transition: background-color 0.15s ease;
}

.erp-table tbody tr.table-row:last-child {
  border-bottom: none;
}

.erp-table tbody tr.table-row:hover {
  background-color: #fafafa;
}

.erp-table tbody tr.table-row.row-selected {
  background-color: #f5f9ff;
}

.erp-table td {
  height: 64px;
  padding: 12px 16px;
  vertical-align: middle;
}

.lead-identity-wrapper {
  display: flex;
  align-items: center;
  gap: 12px;
}

.identity-text-btn {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 2px;
  background: transparent;
  border: none;
  padding: 0;
  cursor: pointer;
  text-align: left;
}

.identity-primary {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
}

.identity-text-btn:hover .identity-primary {
  color: #0b529c;
}

.identity-secondary {
  font-size: 12px;
  color: #737373;
}

.secondary-text-cell {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  white-space: nowrap;
}

.tertiary-plain-text {
  font-size: 13px;
  color: #737373;
}

/* ─── Actions Kebab Menu ─── */
.col-actions-header,
.col-actions {
  width: 84px;
  text-align: center;
}

.action-menu-container {
  position: relative;
  display: inline-flex;
  justify-content: center;
}

.kebab-trigger {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: none;
  background: transparent;
  color: #737373;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background-color 0.15s ease, color 0.15s ease;
}

.kebab-trigger:hover {
  background-color: #f5f5f5;
  color: #404040;
}

.action-dropdown {
  position: absolute;
  top: 36px;
  right: 0;
  min-width: 170px;
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 10px;
  box-shadow: 0 10px 24px rgba(0, 0, 0, 0.08);
  padding: 6px;
  z-index: 40;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.action-dropdown-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 10px;
  border: none;
  border-radius: 6px;
  background: transparent;
  font-size: 13px;
  color: #404040;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.15s ease;
}

.action-dropdown-item:hover {
  background-color: #fafafa;
}

.action-dropdown-item.danger {
  color: #e7000b;
}

.action-dropdown-item.danger:hover {
  background-color: #fef2f2;
}

.action-dropdown-divider {
  height: 1px;
  background-color: #e5e5e5;
  margin: 4px 0;
}

/* ─── Empty State ─── */
.empty-table-cell {
  padding: 48px 24px !important;
  text-align: center;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.empty-icon {
  color: #737373;
  margin-bottom: 4px;
}

.empty-title {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.empty-subtitle {
  margin: 0;
  font-size: 13px;
  color: #737373;
}

.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

@media (max-width: 1024px) {
  .detail-meta-grid,
  .filter-panel-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

.quick-modal-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.modal-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
  align-items: start;
}

@media (max-width: 768px) {
  .detail-meta-grid,
  .filter-panel-grid,
  .modal-grid-2 {
    grid-template-columns: 1fr;
  }
}
</style>
