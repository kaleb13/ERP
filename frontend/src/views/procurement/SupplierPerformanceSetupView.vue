<script setup lang="ts">
import { ref, computed } from 'vue';
import {
  Plus, Sliders, Award, MoreVertical, Check, X, Trash2
} from 'lucide-vue-next';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable, { type ColumnDef, type SortOption } from '../../components/AppDataTable.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import BaseDropdownMenu, { type DropdownMenuItem } from '../../components/BaseDropdownMenu.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import TableToggleCell from '../../components/TableToggleCell.vue';
import { useToast } from '../../composables/useToast';
import { formatDisplayDate } from '../../utils/dateFormat';
import {
  performanceCriteriaStore,
  ratingBandsStore,
  type CriterionSource,
  type ScorecardGradeKey,
  type PerformanceCriterionRecord,
  type RatingBandRecord,
  criterionSourceOptions,
  scorecardGradeOptions,
  getCriterionSourceLabel,
  getScorecardGradeLabel,
  getScorecardGradeColor
} from './supplierPerformanceData';

const { toast } = useToast();

const breadcrumbItems: BreadcrumbItem[] = [{ label: 'Performance Setup' }];

type SetupTabKey = 'criteria' | 'bands';
const activeTab = ref<SetupTabKey>('criteria');
const setupTabs: BaseTabItem<SetupTabKey>[] = [
  { id: 'criteria', label: 'KPI Criteria', icon: Sliders },
  { id: 'bands', label: 'Rating Bands', icon: Award }
];

// ─── Tab 1: KPI Criteria State ───────────────────────────────────────────────
const searchCriteria = ref('');
const filterCriteriaSource = ref('');
const filterCriteriaState = ref('');
const sortCriteria = ref('display_order');
const sortCriteriaOrder = ref<'asc' | 'desc'>('asc');
const criteriaPage = ref(1);
const criteriaPerPage = ref(10);
const selectedCriteriaIds = ref<number[]>([]);

const criteriaSortOptions: SortOption[] = [
  { key: 'display_order', label: 'Display Order' },
  { key: 'name', label: 'KPI Name' },
  { key: 'weight_percent', label: 'Weight %' }
];

const criteriaColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'KPI Criterion', visible: true, sortable: true, hideable: false },
  { key: 'source', label: 'Data Source', visible: true, sortable: false },
  { key: 'weight', label: 'Weight %', visible: true, sortable: true },
  { key: 'target_floor', label: 'Target / Floor', visible: true, sortable: false },
  { key: 'effective', label: 'Effective From', visible: true, sortable: false },
  { key: 'state', label: 'State', visible: true, sortable: false },
  { key: 'actions', label: 'Actions', visible: true, sortable: false, hideable: false }
]);

const isCriteriaColVisible = (key: string) =>
  criteriaColumns.value.find((c) => c.key === key)?.visible !== false;

const handleToggleCriteriaCol = (key: string) => {
  const col = criteriaColumns.value.find((c) => c.key === key);
  if (col && col.hideable !== false) col.visible = !col.visible;
};

const activeCriteriaFilterCount = computed(() => {
  let c = 0;
  if (filterCriteriaSource.value) c += 1;
  if (filterCriteriaState.value) c += 1;
  return c;
});

const resetCriteriaFilters = () => {
  filterCriteriaSource.value = '';
  filterCriteriaState.value = '';
  criteriaPage.value = 1;
};

const activeWeightTotal = computed(() =>
  performanceCriteriaStore.value
    .filter((c) => c.state === 'active')
    .reduce((sum, c) => sum + Number(c.weight_percent || 0), 0)
);

const filteredCriteria = computed(() => {
  const q = searchCriteria.value.trim().toLowerCase();
  let rows = performanceCriteriaStore.value.filter((c) => {
    if (filterCriteriaSource.value && c.source_lookup_value_id !== filterCriteriaSource.value) return false;
    if (filterCriteriaState.value && c.state !== filterCriteriaState.value) return false;
    if (!q) return true;
    return (
      c.code.toLowerCase().includes(q) ||
      c.name.toLowerCase().includes(q) ||
      c.category_label.toLowerCase().includes(q)
    );
  });

  rows = rows.slice().sort((a, b) => {
    let cmp = 0;
    if (sortCriteria.value === 'name') cmp = a.name.localeCompare(b.name);
    else if (sortCriteria.value === 'weight_percent') cmp = a.weight_percent - b.weight_percent;
    else cmp = a.display_order - b.display_order;
    return sortCriteriaOrder.value === 'asc' ? cmp : -cmp;
  });
  return rows;
});

const paginatedCriteria = computed(() => {
  const start = (criteriaPage.value - 1) * criteriaPerPage.value;
  return filteredCriteria.value.slice(start, start + criteriaPerPage.value);
});

const isAllCriteriaSelected = computed(
  () =>
    paginatedCriteria.value.length > 0 &&
    paginatedCriteria.value.every((c) => selectedCriteriaIds.value.includes(c.id))
);

const toggleSelectAllCriteria = (checked: boolean) => {
  if (checked) {
    selectedCriteriaIds.value = Array.from(
      new Set([...selectedCriteriaIds.value, ...paginatedCriteria.value.map((c) => c.id)])
    );
  } else {
    const pageSet = new Set(paginatedCriteria.value.map((c) => c.id));
    selectedCriteriaIds.value = selectedCriteriaIds.value.filter((id) => !pageSet.has(id));
  }
};

const toggleSelectCriteria = (id: number, checked: boolean) => {
  if (checked) {
    if (!selectedCriteriaIds.value.includes(id)) selectedCriteriaIds.value.push(id);
  } else {
    selectedCriteriaIds.value = selectedCriteriaIds.value.filter((x) => x !== id);
  }
};

// ─── Tab 2: Rating Bands State ───────────────────────────────────────────────
const searchBands = ref('');
const filterBandGrade = ref('');
const filterBandImprovement = ref('');
const filterBandState = ref('');
const sortBands = ref('minimum_score');
const sortBandsOrder = ref<'asc' | 'desc'>('desc');
const bandPage = ref(1);
const bandPerPage = ref(10);
const selectedBandIds = ref<number[]>([]);

const bandSortOptions: SortOption[] = [
  { key: 'minimum_score', label: 'Minimum Score' },
  { key: 'maximum_score', label: 'Maximum Score' },
  { key: 'grade', label: 'Grade' }
];

const bandColumns = ref<ColumnDef[]>([
  { key: 'grade', label: 'Rating Grade', visible: true, sortable: true, hideable: false },
  { key: 'range', label: 'Score Range', visible: true, sortable: true },
  { key: 'consequence', label: 'Consequence', visible: true, sortable: false },
  { key: 'improvement', label: 'Requires Improvement Action', visible: true, sortable: false },
  { key: 'state', label: 'State', visible: true, sortable: false },
  { key: 'actions', label: 'Actions', visible: true, sortable: false, hideable: false }
]);

const isBandColVisible = (key: string) =>
  bandColumns.value.find((c) => c.key === key)?.visible !== false;

const handleToggleBandCol = (key: string) => {
  const col = bandColumns.value.find((c) => c.key === key);
  if (col && col.hideable !== false) col.visible = !col.visible;
};

const activeBandFilterCount = computed(() => {
  let c = 0;
  if (filterBandGrade.value) c += 1;
  if (filterBandImprovement.value) c += 1;
  if (filterBandState.value) c += 1;
  return c;
});

const resetBandFilters = () => {
  filterBandGrade.value = '';
  filterBandImprovement.value = '';
  filterBandState.value = '';
  bandPage.value = 1;
};

const filteredBands = computed(() => {
  const q = searchBands.value.trim().toLowerCase();
  let rows = ratingBandsStore.value.filter((b) => {
    if (filterBandGrade.value && b.grade_lookup_value_id !== filterBandGrade.value) return false;
    if (filterBandImprovement.value === 'yes' && !b.requires_improvement_action) return false;
    if (filterBandImprovement.value === 'no' && b.requires_improvement_action) return false;
    if (filterBandState.value && b.state !== filterBandState.value) return false;
    if (!q) return true;
    return (
      getScorecardGradeLabel(b.grade_lookup_value_id).toLowerCase().includes(q) ||
      b.consequence.toLowerCase().includes(q)
    );
  });

  rows = rows.slice().sort((a, b) => {
    let cmp = 0;
    if (sortBands.value === 'maximum_score') cmp = a.maximum_score - b.maximum_score;
    else if (sortBands.value === 'grade') cmp = a.grade_lookup_value_id.localeCompare(b.grade_lookup_value_id);
    else cmp = a.minimum_score - b.minimum_score;
    return sortBandsOrder.value === 'asc' ? cmp : -cmp;
  });
  return rows;
});

const paginatedBands = computed(() => {
  const start = (bandPage.value - 1) * bandPerPage.value;
  return filteredBands.value.slice(start, start + bandPerPage.value);
});

const isAllBandsSelected = computed(
  () =>
    paginatedBands.value.length > 0 &&
    paginatedBands.value.every((b) => selectedBandIds.value.includes(b.id))
);

const toggleSelectAllBands = (checked: boolean) => {
  if (checked) {
    selectedBandIds.value = Array.from(
      new Set([...selectedBandIds.value, ...paginatedBands.value.map((b) => b.id)])
    );
  } else {
    const pageSet = new Set(paginatedBands.value.map((b) => b.id));
    selectedBandIds.value = selectedBandIds.value.filter((id) => !pageSet.has(id));
  }
};

const toggleSelectBand = (id: number, checked: boolean) => {
  if (checked) {
    if (!selectedBandIds.value.includes(id)) selectedBandIds.value.push(id);
  } else {
    selectedBandIds.value = selectedBandIds.value.filter((x) => x !== id);
  }
};

// ─── Quick Create: KPI Criterion ─────────────────────────────────────────────
const showCriterionModal = ref(false);
const criterionForm = ref({
  name: '',
  source_lookup_value_id: 'manual' as CriterionSource,
  weight_percent: 10,
  target_value: 100 as number | null,
  floor_value: 0 as number | null
});

const openCriterionModal = () => {
  criterionForm.value = {
    name: '',
    source_lookup_value_id: 'manual',
    weight_percent: 10,
    target_value: 100,
    floor_value: 0
  };
  showCriterionModal.value = true;
};

const handleSaveCriterion = () => {
  if (!criterionForm.value.name.trim()) {
    toast.error('KPI Name is required.');
    return;
  }
  const nextId = Math.max(0, ...performanceCriteriaStore.value.map((c) => c.id)) + 1;
  const code = criterionForm.value.name
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, '_')
    .slice(0, 10);

  performanceCriteriaStore.value.push({
    id: nextId,
    code,
    name: criterionForm.value.name.trim(),
    source_lookup_value_id: criterionForm.value.source_lookup_value_id,
    weight_percent: Number(criterionForm.value.weight_percent) || 0,
    target_value: criterionForm.value.target_value,
    floor_value: criterionForm.value.floor_value,
    display_order: nextId,
    category_label: 'Default (All Categories)',
    effective_from: new Date().toISOString().split('T')[0],
    effective_to: null,
    state: 'active'
  });
  showCriterionModal.value = false;
  toast.success(`KPI criterion "${criterionForm.value.name.trim()}" created.`);
};

// ─── Quick Create: Rating Band ───────────────────────────────────────────────
const showBandModal = ref(false);
const bandForm = ref({
  grade_lookup_value_id: 'satisfactory' as ScorecardGradeKey,
  minimum_score: 70,
  maximum_score: 84.99,
  consequence: '',
  requires_improvement_action: false
});

const openBandModal = () => {
  bandForm.value = {
    grade_lookup_value_id: 'satisfactory',
    minimum_score: 70,
    maximum_score: 84.99,
    consequence: '',
    requires_improvement_action: false
  };
  showBandModal.value = true;
};

const handleSaveBand = () => {
  if (bandForm.value.maximum_score <= bandForm.value.minimum_score) {
    toast.error('Maximum score must be greater than minimum score.');
    return;
  }
  const nextId = Math.max(0, ...ratingBandsStore.value.map((b) => b.id)) + 1;
  ratingBandsStore.value.push({
    id: nextId,
    grade_lookup_value_id: bandForm.value.grade_lookup_value_id,
    minimum_score: Number(bandForm.value.minimum_score),
    maximum_score: Number(bandForm.value.maximum_score),
    consequence: bandForm.value.consequence.trim() || 'Standard rating band rule.',
    requires_improvement_action: bandForm.value.requires_improvement_action,
    effective_from: new Date().toISOString().split('T')[0],
    effective_to: null,
    state: 'active'
  });
  showBandModal.value = false;
  toast.success(`Rating band "${getScorecardGradeLabel(bandForm.value.grade_lookup_value_id)}" added.`);
};

const getCriterionActions = (row: PerformanceCriterionRecord): DropdownMenuItem[] => [
  {
    key: 'toggle',
    label: row.state === 'active' ? 'Deactivate' : 'Activate',
    icon: row.state === 'active' ? X : Check,
    onClick: () => {
      row.state = row.state === 'active' ? 'inactive' : 'active';
      toast.success(`${row.code} marked ${row.state}.`);
    }
  },
  { key: 'div', divider: true },
  {
    key: 'delete',
    label: 'Delete',
    icon: Trash2,
    destructive: true,
    onClick: () => {
      performanceCriteriaStore.value = performanceCriteriaStore.value.filter((c) => c.id !== row.id);
      toast.success(`${row.code} deleted.`);
    }
  }
];

const getBandActions = (row: RatingBandRecord): DropdownMenuItem[] => [
  {
    key: 'toggle',
    label: row.state === 'active' ? 'Deactivate' : 'Activate',
    icon: row.state === 'active' ? X : Check,
    onClick: () => {
      row.state = row.state === 'active' ? 'inactive' : 'active';
      toast.success(`Band marked ${row.state}.`);
    }
  },
  { key: 'div', divider: true },
  {
    key: 'delete',
    label: 'Delete',
    icon: Trash2,
    destructive: true,
    onClick: () => {
      ratingBandsStore.value = ratingBandsStore.value.filter((b) => b.id !== row.id);
      toast.success('Rating band deleted.');
    }
  }
];
</script>

<template>
  <div class="performance-setup-page">
    <AppBreadcrumb :items="breadcrumbItems" :noMargin="true" />

    <!-- Top Header Card -->
    <div class="setup-top-card">
      <div class="header-main-row">
        <div>
          <h1 class="page-title">Performance Setup</h1>
          <p class="page-subtitle">
            Configure KPI criteria weights (must total 100%) and score-to-grade rating bands used when evaluating suppliers.
          </p>
        </div>
        <BaseBadge size="sm" :color="activeWeightTotal === 100 ? 'success' : 'warning'">
          Active KPI Weight Total: {{ activeWeightTotal }}%
        </BaseBadge>
      </div>

      <BaseTabs v-model="activeTab" :tabs="setupTabs" type="rounded" size="sm" />
    </div>

    <!-- TAB 1: KPI CRITERIA (SupplierPerformanceCriterion) -->
    <AppDataTable
      v-if="activeTab === 'criteria'"
      title="Supplier Performance Criteria"
      subtitle="KPIs, weights, targets, and floors used to calculate supplier scorecards."
      v-model:searchQuery="searchCriteria"
      searchPlaceholder="Search KPI criteria by code, name, or category..."
      :showSearch="true"
      :showFilter="true"
      :filterCount="activeCriteriaFilterCount"
      :showSort="true"
      :sortOptions="criteriaSortOptions"
      v-model:currentSort="sortCriteria"
      v-model:sortOrder="sortCriteriaOrder"
      :showColumns="true"
      :columns="criteriaColumns"
      :showFullscreen="true"
      :totalEntries="filteredCriteria.length"
      :showPagination="true"
      v-model:currentPage="criteriaPage"
      v-model:perPage="criteriaPerPage"
      @toggleColumn="handleToggleCriteriaCol"
      @resetFilter="resetCriteriaFilters"
    >
      <template #actions>
        <AppButton variant="primary" size="sm" @click="openCriterionModal">
          <template #icon-left><Plus :size="15" /></template>
          Create KPI Criterion
        </AppButton>
      </template>

      <template #filter-panel>
        <div class="filter-panel-grid">
          <FormSelect
            v-model="filterCriteriaSource"
            label="Data Source"
            :options="[{ value: '', label: 'All Data Sources' }, ...criterionSourceOptions]"
            placeholder="Select Source"
          />
          <FormSelect
            v-model="filterCriteriaState"
            label="State"
            :options="[
              { value: '', label: 'All States' },
              { value: 'active', label: 'Active' },
              { value: 'inactive', label: 'Inactive' }
            ]"
            placeholder="Select State"
          />
        </div>
        <div v-if="activeCriteriaFilterCount > 0" class="filter-panel-footer">
          <AppButton variant="outline" size="sm" @click="resetCriteriaFilters">
            Reset Filters
          </AppButton>
        </div>
      </template>

      <table class="erp-table">
        <thead>
          <tr>
            <th class="th-lead">
              <div class="lead-cell-wrap">
                <FormCheckbox
                  :modelValue="isAllCriteriaSelected"
                  @update:modelValue="(v: boolean) => toggleSelectAllCriteria(Boolean(v))"
                />
                <span>KPI Criterion</span>
              </div>
            </th>
            <th v-if="isCriteriaColVisible('source')">Data Source</th>
            <th v-if="isCriteriaColVisible('weight')">Weight</th>
            <th v-if="isCriteriaColVisible('target_floor')">Target / Floor</th>
            <th v-if="isCriteriaColVisible('effective')">Effective From</th>
            <th v-if="isCriteriaColVisible('state')">State</th>
            <th v-if="isCriteriaColVisible('actions')" class="th-actions">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in paginatedCriteria" :key="item.id" class="erp-row">
            <td class="td-lead" @click.stop>
              <div class="lead-cell-wrap">
                <FormCheckbox
                  :modelValue="selectedCriteriaIds.includes(item.id)"
                  @update:modelValue="(v: boolean) => toggleSelectCriteria(item.id, Boolean(v))"
                />
                <div class="cell-stack">
                  <span class="cell-primary">{{ item.name }}</span>
                  <span class="cell-sub">{{ item.code }} • {{ item.category_label }}</span>
                </div>
              </div>
            </td>
            <td v-if="isCriteriaColVisible('source')">
              <BaseBadge
                size="sm"
                :color="item.source_lookup_value_id === 'manual' ? 'purple' : 'blue'"
              >
                {{ getCriterionSourceLabel(item.source_lookup_value_id) }}
              </BaseBadge>
            </td>
            <td v-if="isCriteriaColVisible('weight')">
              <span class="cell-primary">{{ item.weight_percent }}%</span>
            </td>
            <td v-if="isCriteriaColVisible('target_floor')">
              <span class="cell-muted">
                Target {{ item.target_value ?? '—' }} / Floor {{ item.floor_value ?? '—' }}
              </span>
            </td>
            <td v-if="isCriteriaColVisible('effective')">
              <span class="cell-muted">{{ formatDisplayDate(item.effective_from) }}</span>
            </td>
            <td v-if="isCriteriaColVisible('state')">
              <BaseBadge size="sm" :color="item.state === 'active' ? 'success' : 'gray'">
                {{ item.state === 'active' ? 'Active' : 'Inactive' }}
              </BaseBadge>
            </td>
            <td v-if="isCriteriaColVisible('actions')" class="td-actions">
              <BaseDropdownMenu :items="getCriterionActions(item)" minWidth="168px">
                <template #trigger="{ toggle }">
                  <button type="button" class="btn-action-dots" title="Actions" @click.stop="toggle">
                    <MoreVertical :size="18" />
                  </button>
                </template>
              </BaseDropdownMenu>
            </td>
          </tr>
        </tbody>
      </table>
    </AppDataTable>

    <!-- TAB 2: RATING BANDS (SupplierRatingBand) -->
    <AppDataTable
      v-else
      title="Supplier Rating Bands"
      subtitle="Score bands (0–100) mapping overall scorecard scores to grades and mandatory improvement actions."
      v-model:searchQuery="searchBands"
      searchPlaceholder="Search rating grades or consequences..."
      :showSearch="true"
      :showFilter="true"
      :filterCount="activeBandFilterCount"
      :showSort="true"
      :sortOptions="bandSortOptions"
      v-model:currentSort="sortBands"
      v-model:sortOrder="sortBandsOrder"
      :showColumns="true"
      :columns="bandColumns"
      :showFullscreen="true"
      :totalEntries="filteredBands.length"
      :showPagination="true"
      v-model:currentPage="bandPage"
      v-model:perPage="bandPerPage"
      @toggleColumn="handleToggleBandCol"
      @resetFilter="resetBandFilters"
    >
      <template #actions>
        <AppButton variant="primary" size="sm" @click="openBandModal">
          <template #icon-left><Plus :size="15" /></template>
          Create Rating Band
        </AppButton>
      </template>

      <template #filter-panel>
        <div class="filter-panel-grid">
          <FormSelect
            v-model="filterBandGrade"
            label="Rating Grade"
            :options="[{ value: '', label: 'All Grades' }, ...scorecardGradeOptions]"
            placeholder="Select Grade"
          />
          <FormSelect
            v-model="filterBandImprovement"
            label="Improvement Action"
            :options="[
              { value: '', label: 'All Rules' },
              { value: 'yes', label: 'Requires Action' },
              { value: 'no', label: 'No Action Required' }
            ]"
            placeholder="Select Rule"
          />
          <FormSelect
            v-model="filterBandState"
            label="State"
            :options="[
              { value: '', label: 'All States' },
              { value: 'active', label: 'Active' },
              { value: 'inactive', label: 'Inactive' }
            ]"
            placeholder="Select State"
          />
        </div>
        <div v-if="activeBandFilterCount > 0" class="filter-panel-footer">
          <AppButton variant="outline" size="sm" @click="resetBandFilters">
            Reset Filters
          </AppButton>
        </div>
      </template>

      <table class="erp-table">
        <thead>
          <tr>
            <th class="th-lead">
              <div class="lead-cell-wrap">
                <FormCheckbox
                  :modelValue="isAllBandsSelected"
                  @update:modelValue="(v: boolean) => toggleSelectAllBands(Boolean(v))"
                />
                <span>Rating Grade</span>
              </div>
            </th>
            <th v-if="isBandColVisible('range')">Score Range</th>
            <th v-if="isBandColVisible('consequence')">Consequence</th>
            <th v-if="isBandColVisible('improvement')">Requires Improvement Action</th>
            <th v-if="isBandColVisible('state')">State</th>
            <th v-if="isBandColVisible('actions')" class="th-actions">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="band in paginatedBands" :key="band.id" class="erp-row">
            <td class="td-lead" @click.stop>
              <div class="lead-cell-wrap">
                <FormCheckbox
                  :modelValue="selectedBandIds.includes(band.id)"
                  @update:modelValue="(v: boolean) => toggleSelectBand(band.id, Boolean(v))"
                />
                <BaseBadge size="sm" :color="getScorecardGradeColor(band.grade_lookup_value_id)">
                  {{ getScorecardGradeLabel(band.grade_lookup_value_id) }}
                </BaseBadge>
              </div>
            </td>
            <td v-if="isBandColVisible('range')">
              <span class="cell-primary">{{ band.minimum_score }} – {{ band.maximum_score }}</span>
            </td>
            <td v-if="isBandColVisible('consequence')">
              <span class="cell-muted">{{ band.consequence }}</span>
            </td>
            <td v-if="isBandColVisible('improvement')">
              <TableToggleCell
                v-model="band.requires_improvement_action"
                aria-label="Toggle improvement action requirement"
              />
            </td>
            <td v-if="isBandColVisible('state')">
              <BaseBadge size="sm" :color="band.state === 'active' ? 'success' : 'gray'">
                {{ band.state === 'active' ? 'Active' : 'Inactive' }}
              </BaseBadge>
            </td>
            <td v-if="isBandColVisible('actions')" class="td-actions">
              <BaseDropdownMenu :items="getBandActions(band)" minWidth="168px">
                <template #trigger="{ toggle }">
                  <button type="button" class="btn-action-dots" title="Actions" @click.stop="toggle">
                    <MoreVertical :size="18" />
                  </button>
                </template>
              </BaseDropdownMenu>
            </td>
          </tr>
        </tbody>
      </table>
    </AppDataTable>

    <!-- Quick Create Modal: KPI Criterion -->
    <QuickCreateModal
      v-model:show="showCriterionModal"
      title="Create KPI Criterion"
      :showExpandButton="false"
      saveLabel="Save"
      width="md"
      @save="handleSaveCriterion"
    >
      <div class="quick-form-body">
        <div class="modal-grid-2">
          <FormInput v-model="criterionForm.name" label="KPI Name" required />
          <FormSelect
            v-model="criterionForm.source_lookup_value_id"
            label="Data Source"
            :options="criterionSourceOptions"
            placeholder="Select Source"
            required
          />
        </div>
        <div class="modal-grid-3">
          <FormInput v-model.number="criterionForm.weight_percent" type="number" label="Weight (%)" required />
          <FormInput v-model.number="criterionForm.target_value" type="number" label="Target Value" />
          <FormInput v-model.number="criterionForm.floor_value" type="number" label="Floor Value" />
        </div>
      </div>
    </QuickCreateModal>

    <!-- Quick Create Modal: Rating Band -->
    <QuickCreateModal
      v-model:show="showBandModal"
      title="Create Rating Band"
      :showExpandButton="false"
      saveLabel="Save"
      width="md"
      @save="handleSaveBand"
    >
      <div class="quick-form-body">
        <div class="modal-grid-2">
          <FormSelect
            v-model="bandForm.grade_lookup_value_id"
            label="Rating Grade"
            :options="scorecardGradeOptions"
            placeholder="Select Grade"
            required
          />
          <FormInput v-model="bandForm.consequence" label="Consequence" />
        </div>
        <div class="modal-grid-2">
          <FormInput v-model.number="bandForm.minimum_score" type="number" label="Minimum Score" required />
          <FormInput v-model.number="bandForm.maximum_score" type="number" label="Maximum Score" required />
        </div>
        <div class="modal-checkbox-grid">
          <FormCheckbox
            v-model="bandForm.requires_improvement_action"
            label="Requires Improvement Action"
            description="Automatically opens a Supplier Improvement Action when a scorecard falls into this band."
          />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.performance-setup-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.setup-top-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.header-main-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
}

.page-title {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
  color: #404040;
}

.page-subtitle {
  margin: 4px 0 0;
  font-size: 14px;
  color: #737373;
}

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

.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table thead th {
  height: 44px;
  padding: 0 16px;
  background-color: #fafafa;
  border-bottom: 1px solid #e9eaeb;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  text-align: left;
  white-space: nowrap;
}

.erp-table thead th.th-lead {
  padding-left: 24px;
}

.erp-table thead th.th-actions {
  text-align: center;
  padding-right: 24px;
  width: 80px;
}

.erp-row {
  height: 72px;
  border-bottom: 1px solid #e9eaeb;
}

.erp-row:last-child {
  border-bottom: none;
}

.erp-table tbody td {
  padding: 12px 16px;
  vertical-align: middle;
}

.erp-table tbody td.td-lead {
  padding-left: 24px;
}

.erp-table tbody td.td-actions {
  text-align: center;
  padding-right: 24px;
}

.lead-cell-wrap {
  display: flex;
  align-items: center;
  gap: 12px;
}

.cell-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.cell-primary {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
}

.cell-sub {
  font-size: 12px;
  color: #737373;
}

.cell-muted {
  font-size: 13.5px;
  color: #737373;
}

.btn-action-dots {
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
  outline: none !important;
  box-shadow: none !important;
  -webkit-tap-highlight-color: transparent !important;
}

.btn-action-dots:hover {
  background-color: #f5f5f5;
  color: #404040;
}

.quick-form-body {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.modal-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.modal-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
}

.modal-checkbox-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 20px 16px;
  padding-top: 8px;
}
</style>
