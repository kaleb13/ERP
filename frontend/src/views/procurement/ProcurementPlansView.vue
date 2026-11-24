<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  ClipboardList, ListChecks, CheckCircle2, Clock, Banknote,
  Plus, MoreVertical, Eye, Edit2, GitBranch,
  Trash2, Check, X
} from 'lucide-vue-next';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable, { type ColumnDef, type SortOption } from '../../components/AppDataTable.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import MetricCard from '../../components/MetricCard.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import BaseDropdownMenu, { type DropdownMenuItem } from '../../components/BaseDropdownMenu.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import { useToast } from '../../composables/useToast';
import { formatDisplayDateRange } from '../../utils/dateFormat';

import {
  procurementPlansStore,
  procurementPlanVersionsStore,
  procurementPlanLinesStore,
  type ProcurementPlanRecord,
  type PlanPeriodType,
  type PlanStatus,
  planPeriodTypeOptions,
  planStatusOptions,
  planLineStatusOptions,
  fiscalYearOptions,
  categoryOptions,
  unitOptions,
  generatePlanNumber,
  getPlanPeriodTypeLabel,
  getPlanStatusLabel,
  getPlanStatusBadgeColor,
  getPlanLineStatusLabel,
  getPlanLineStatusBadgeColor,
  getCurrentPlanVersion,
  getPlanTotalEstimatedAmount,
  formatCurrencyETB
} from './procurementPlanData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

const breadcrumbItems: BreadcrumbItem[] = [{ label: 'Procurement Plans' }];

type PlanTabKey = 'plans' | 'lines';
const activeTab = ref<PlanTabKey>(route.query.tab === 'lines' ? 'lines' : 'plans');
watch(
  () => route.query.tab,
  (tab) => {
    if (tab === 'lines' || tab === 'plans') {
      activeTab.value = tab;
    }
  }
);
const planTabs = computed<BaseTabItem<PlanTabKey>[]>(() => [
  { id: 'plans', label: 'Procurement Plans', icon: ClipboardList },
  { id: 'lines', label: 'Planned Items', icon: ListChecks }
]);

// ─── Table State ──────────────────────────────────────────────────────────────
const searchQuery = ref('');
const currentPage = ref(1);
const perPage = ref(10);
const currentSort = ref('plan_number');
const sortOrder = ref<'asc' | 'desc'>('asc');

const filterPeriodType = ref('');
const filterStatus = ref('');
const filterUnitId = ref('');

const selectedIds = ref<number[]>([]);

const sortOptions: SortOption[] = [
  { key: 'plan_number', label: 'Plan Number' },
  { key: 'name', label: 'Plan Name' },
  { key: 'period_start', label: 'Period Start' },
  { key: 'estimated_total', label: 'Planned Amount' }
];

const tableColumns = ref<ColumnDef[]>([
  { key: 'plan_number', label: 'Plan', visible: true, sortable: true, hideable: false },
  { key: 'period_type', label: 'Period Type', visible: true, sortable: false },
  { key: 'period_window', label: 'Coverage Window', visible: true, sortable: true },
  { key: 'procurement_unit', label: 'Procurement Unit', visible: true, sortable: false },
  { key: 'current_version', label: 'Version', visible: true, sortable: false },
  { key: 'estimated_total', label: 'Planned Budget', visible: true, sortable: true },
  { key: 'plan_status', label: 'Plan Status', visible: true, sortable: false },
  { key: 'state', label: 'State', visible: true, sortable: false },
  { key: 'actions', label: 'Actions', visible: true, sortable: false, hideable: false },
  // Secondary columns (hidden by default in Column Hider):
  { key: 'entity_name', label: 'Entity', visible: false, sortable: false },
  { key: 'fiscal_year', label: 'Fiscal Year', visible: false, sortable: false },
  { key: 'budget_id', label: 'Budget', visible: false, sortable: false }
]);

const isColumnVisible = (key: string) =>
  tableColumns.value.find((c) => c.key === key)?.visible !== false;

const handleToggleColumn = (key: string) => {
  const col = tableColumns.value.find((c) => c.key === key);
  if (col && col.hideable !== false) {
    col.visible = !col.visible;
  }
};

// ─── Metrics ──────────────────────────────────────────────────────────────────
const totalPlansCount = computed(() => procurementPlansStore.value.length);
const approvedPlansCount = computed(
  () =>
    procurementPlansStore.value.filter((p) => p.plan_status_lookup_value_id === 'approved').length
);
const inReviewPlansCount = computed(
  () =>
    procurementPlansStore.value.filter((p) =>
      ['draft', 'submitted', 'returned', 'revised'].includes(p.plan_status_lookup_value_id)
    ).length
);
const totalPlannedBudget = computed(() =>
  procurementPlansStore.value.reduce((sum, p) => sum + getPlanTotalEstimatedAmount(p.id), 0)
);

// ─── Filtering & Sorting ──────────────────────────────────────────────────────
const activeFilterCount = computed(() => {
  let count = 0;
  if (filterPeriodType.value) count += 1;
  if (filterStatus.value) count += 1;
  if (filterUnitId.value) count += 1;
  return count;
});

const resetFilters = () => {
  filterPeriodType.value = '';
  filterStatus.value = '';
  filterUnitId.value = '';
  searchQuery.value = '';
  currentPage.value = 1;
};

const filteredPlans = computed(() => {
  const q = searchQuery.value.trim().toLowerCase();
  let rows = procurementPlansStore.value.filter((p) => {
    if (filterPeriodType.value && p.period_type_lookup_value_id !== filterPeriodType.value) {
      return false;
    }
    if (filterStatus.value && p.plan_status_lookup_value_id !== filterStatus.value) {
      return false;
    }
    if (filterUnitId.value) {
      if (filterUnitId.value === 'whole_entity' && p.procurement_unit_id !== null) return false;
      if (
        filterUnitId.value !== 'whole_entity' &&
        String(p.procurement_unit_id ?? '') !== filterUnitId.value
      ) {
        return false;
      }
    }
    if (!q) return true;
    return (
      p.plan_number.toLowerCase().includes(q) ||
      p.name.toLowerCase().includes(q) ||
      p.procurement_unit_name.toLowerCase().includes(q) ||
      p.fiscal_year_id.toLowerCase().includes(q)
    );
  });

  rows = rows.slice().sort((a, b) => {
    let cmp = 0;
    if (currentSort.value === 'estimated_total') {
      cmp = getPlanTotalEstimatedAmount(a.id) - getPlanTotalEstimatedAmount(b.id);
    } else if (currentSort.value === 'period_start') {
      cmp = a.period_start.localeCompare(b.period_start);
    } else if (currentSort.value === 'name') {
      cmp = a.name.localeCompare(b.name);
    } else {
      cmp = a.plan_number.localeCompare(b.plan_number);
    }
    return sortOrder.value === 'asc' ? cmp : -cmp;
  });

  return rows;
});

const paginatedPlans = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredPlans.value.slice(start, start + perPage.value);
});

// ─── Selection ────────────────────────────────────────────────────────────────
const isAllPageSelected = computed(() => {
  if (paginatedPlans.value.length === 0) return false;
  return paginatedPlans.value.every((p) => selectedIds.value.includes(p.id));
});

const toggleSelectAllPage = (checked: boolean) => {
  if (checked) {
    const merged = new Set([...selectedIds.value, ...paginatedPlans.value.map((p) => p.id)]);
    selectedIds.value = Array.from(merged);
  } else {
    const pageSet = new Set(paginatedPlans.value.map((p) => p.id));
    selectedIds.value = selectedIds.value.filter((id) => !pageSet.has(id));
  }
};

const toggleSelectRow = (id: number, checked: boolean) => {
  if (checked) {
    if (!selectedIds.value.includes(id)) selectedIds.value.push(id);
  } else {
    selectedIds.value = selectedIds.value.filter((x) => x !== id);
  }
};

const selectAllFiltered = () => {
  selectedIds.value = filteredPlans.value.map((p) => p.id);
};

// ─── Actions ──────────────────────────────────────────────────────────────────
const showQuickModal = ref(false);
const quickForm = ref({
  name: '',
  period_type_lookup_value_id: 'annual' as PlanPeriodType,
  fiscal_year_id: 'FY-2026',
  period_start: '2026-07-01',
  period_end: '2027-06-30'
});
const quickErrors = ref<{
  name?: string;
  period_start?: string;
  period_end?: string;
}>({});

const openQuickCreate = () => {
  quickForm.value = {
    name: '',
    period_type_lookup_value_id: 'annual',
    fiscal_year_id: 'FY-2026',
    period_start: '2026-07-01',
    period_end: '2027-06-30'
  };
  quickErrors.value = {};
  showQuickModal.value = true;
};

const handleSaveQuick = () => {
  quickErrors.value = {};
  if (!quickForm.value.name.trim()) {
    quickErrors.value.name = 'Plan Name is required.';
  }
  if (!quickForm.value.period_start) {
    quickErrors.value.period_start = 'Period Start is required.';
  }
  if (!quickForm.value.period_end) {
    quickErrors.value.period_end = 'Period End is required.';
  } else if (
    quickForm.value.period_start &&
    quickForm.value.period_end < quickForm.value.period_start
  ) {
    quickErrors.value.period_end = 'Period End must be on or after Period Start.';
  }

  if (Object.keys(quickErrors.value).length > 0) {
    toast.error('Please fill in all required fields.');
    return;
  }

  const nextPlanId = Math.max(0, ...procurementPlansStore.value.map((p) => p.id)) + 1;
  const planNumber = generatePlanNumber(procurementPlansStore.value.map((p) => p.plan_number));
  const today = new Date().toISOString().split('T')[0];

  procurementPlansStore.value.unshift({
    id: nextPlanId,
    uuid: `pp-${nextPlanId}-quick`,
    plan_number: planNumber,
    name: quickForm.value.name.trim(),
    period_start: quickForm.value.period_start,
    period_end: quickForm.value.period_end,
    approved_at: null,
    notes: '',
    period_type_lookup_value_id: quickForm.value.period_type_lookup_value_id,
    procurement_unit_id: null,
    procurement_unit_name: 'Whole Entity (Shared)',
    tenant_id: 1,
    entity_id: 2,
    entity_name: 'Sheraton Ethiopia',
    currency_id: 'ETB',
    fiscal_year_id: quickForm.value.fiscal_year_id,
    budget_id: null,
    budget_name: 'No Linked Budget',
    document_id: `DOC-PP-${nextPlanId}`,
    plan_status_lookup_value_id: 'draft',
    user_id: 10,
    state: 'active'
  });

  const nextVerId = Math.max(0, ...procurementPlanVersionsStore.value.map((v) => v.id)) + 1;
  procurementPlanVersionsStore.value.push({
    id: nextVerId,
    uuid: `ppv-${nextVerId}-v0`,
    procurement_plan_id: nextPlanId,
    version_number: 0,
    reason: null,
    revised_at: today,
    superseded_at: null,
    document_id: `DOC-PP-${nextPlanId}-V0`,
    revised_by: 'Marta Tadesse',
    plan_version_status_lookup_value_id: 'submitted',
    user_id: 10,
    state: 'active'
  });

  showQuickModal.value = false;
  toast.success(`Procurement plan "${planNumber}" created.`);
};

const handleExpandFullForm = () => {
  showQuickModal.value = false;
  router.push({
    path: '/procurement/plans/create',
    query: {
      name: quickForm.value.name || undefined,
      period_type: quickForm.value.period_type_lookup_value_id || undefined,
      fiscal_year_id: quickForm.value.fiscal_year_id || undefined,
      period_start: quickForm.value.period_start || undefined,
      period_end: quickForm.value.period_end || undefined
    }
  });
};

const goToDetail = (plan: ProcurementPlanRecord) => {
  router.push(`/procurement/plans/${plan.id}`);
};

const goToEdit = (plan: ProcurementPlanRecord) => {
  router.push(`/procurement/plans/${plan.id}/edit`);
};

const goToRevise = (plan: ProcurementPlanRecord) => {
  router.push({ path: '/procurement/plans/create', query: { reviseId: String(plan.id) } });
};

const handleToggleState = (plan: ProcurementPlanRecord) => {
  plan.state = plan.state === 'active' ? 'inactive' : 'active';
  toast.success(
    `${plan.plan_number} marked as ${plan.state === 'active' ? 'Active' : 'Inactive'}.`
  );
};

const handleDelete = (plan: ProcurementPlanRecord) => {
  const versions = procurementPlanVersionsStore.value.filter(
    (v) => v.procurement_plan_id === plan.id
  );
  const versionIds = new Set(versions.map((v) => v.id));
  procurementPlanLinesStore.value = procurementPlanLinesStore.value.filter(
    (l) => !versionIds.has(l.procurement_plan_version_id)
  );
  procurementPlanVersionsStore.value = procurementPlanVersionsStore.value.filter(
    (v) => v.procurement_plan_id !== plan.id
  );
  procurementPlansStore.value = procurementPlansStore.value.filter((p) => p.id !== plan.id);
  selectedIds.value = selectedIds.value.filter((id) => id !== plan.id);
  toast.success(`Procurement plan "${plan.plan_number}" deleted.`);
};

const handleBulkActivate = () => {
  const set = new Set(selectedIds.value);
  procurementPlansStore.value.forEach((p) => {
    if (set.has(p.id)) p.state = 'active';
  });
  toast.success(`${selectedIds.value.length} plan(s) set to Active.`);
  selectedIds.value = [];
};

const handleBulkDeactivate = () => {
  const set = new Set(selectedIds.value);
  procurementPlansStore.value.forEach((p) => {
    if (set.has(p.id)) p.state = 'inactive';
  });
  toast.success(`${selectedIds.value.length} plan(s) set to Inactive.`);
  selectedIds.value = [];
};

const handleBulkDelete = () => {
  const set = new Set(selectedIds.value);
  const versionIds = new Set(
    procurementPlanVersionsStore.value
      .filter((v) => set.has(v.procurement_plan_id))
      .map((v) => v.id)
  );
  procurementPlanLinesStore.value = procurementPlanLinesStore.value.filter(
    (l) => !versionIds.has(l.procurement_plan_version_id)
  );
  procurementPlanVersionsStore.value = procurementPlanVersionsStore.value.filter(
    (v) => !set.has(v.procurement_plan_id)
  );
  procurementPlansStore.value = procurementPlansStore.value.filter((p) => !set.has(p.id));
  toast.success(`${selectedIds.value.length} procurement plan(s) deleted.`);
  selectedIds.value = [];
};

const getPlanActionItems = (plan: ProcurementPlanRecord): DropdownMenuItem[] => [
  {
    key: 'view',
    label: 'View Plan & Versions',
    icon: Eye,
    onClick: () => goToDetail(plan)
  },
  {
    key: 'edit',
    label: 'Edit Plan',
    icon: Edit2,
    onClick: () => goToEdit(plan)
  },
  {
    key: 'revise',
    label: 'Update (New Version)',
    icon: GitBranch,
    onClick: () => goToRevise(plan)
  },
  {
    key: 'toggle-state',
    label: plan.state === 'active' ? 'Deactivate' : 'Activate',
    icon: plan.state === 'inactive' ? Check : X,
    onClick: () => handleToggleState(plan)
  },
  { key: 'div', divider: true },
  {
    key: 'delete',
    label: 'Delete Plan',
    icon: Trash2,
    destructive: true,
    onClick: () => handleDelete(plan)
  }
];

const getFilterUnitOptions = computed(() => [
  { value: '', label: 'All Procurement Units' },
  { value: 'whole_entity', label: 'Whole Entity (Shared)' },
  ...unitOptions.filter((u) => u.value !== '')
]);

// ─── Tab 2: Planned Items (ProcurementPlanVersionLine) ───────────────────────
const lineSearchQuery = ref('');
const linePage = ref(1);
const linePerPage = ref(10);
const lineSort = ref('plan_number');
const lineSortOrder = ref<'asc' | 'desc'>('asc');
const filterLineStatus = ref('');
const filterLineCategory = ref('');

const lineSortOptions: SortOption[] = [
  { key: 'plan_number', label: 'Plan Number' },
  { key: 'product_name', label: 'Item / Product' },
  { key: 'estimated_amount', label: 'Estimated Amount' }
];

const lineTableColumns = ref<ColumnDef[]>([
  { key: 'item', label: 'Item & Plan', visible: true, sortable: true, hideable: false },
  { key: 'category_dept', label: 'Category', visible: true, sortable: false },
  { key: 'planned_qty', label: 'Planned Qty', visible: true, sortable: false },
  { key: 'estimated_amount', label: 'Est. Amount', visible: true, sortable: true },
  { key: 'execution', label: 'PR / PO / Recv', visible: true, sortable: false },
  { key: 'line_status', label: 'Line Status', visible: true, sortable: false }
]);

const isLineColVisible = (key: string) =>
  lineTableColumns.value.find((c) => c.key === key)?.visible !== false;

const handleToggleLineCol = (key: string) => {
  const col = lineTableColumns.value.find((c) => c.key === key);
  if (col && col.hideable !== false) {
    col.visible = !col.visible;
  }
};

const activeLineFilterCount = computed(() => {
  let count = 0;
  if (filterLineStatus.value) count += 1;
  if (filterLineCategory.value) count += 1;
  return count;
});

const resetLineFilters = () => {
  filterLineStatus.value = '';
  filterLineCategory.value = '';
  lineSearchQuery.value = '';
  linePage.value = 1;
};

const currentVersionLines = computed(() => {
  const result: Array<{
    line: (typeof procurementPlanLinesStore.value)[number];
    plan: ProcurementPlanRecord;
    versionNumber: number;
  }> = [];

  for (const plan of procurementPlansStore.value) {
    const ver = getCurrentPlanVersion(plan.id);
    if (!ver) continue;
    const lines = procurementPlanLinesStore.value.filter(
      (l) => l.procurement_plan_version_id === ver.id
    );
    for (const line of lines) {
      result.push({ line, plan, versionNumber: ver.version_number });
    }
  }
  return result;
});

const filteredLines = computed(() => {
  const q = lineSearchQuery.value.trim().toLowerCase();
  let rows = currentVersionLines.value.filter(({ line, plan }) => {
    if (filterLineStatus.value && line.plan_line_status_lookup_value_id !== filterLineStatus.value) {
      return false;
    }
    if (
      filterLineCategory.value &&
      String(line.procurement_category_id) !== filterLineCategory.value
    ) {
      return false;
    }
    if (!q) return true;
    return (
      line.product_name.toLowerCase().includes(q) ||
      line.description.toLowerCase().includes(q) ||
      plan.plan_number.toLowerCase().includes(q) ||
      line.category_name.toLowerCase().includes(q)
    );
  });

  rows = rows.slice().sort((a, b) => {
    let cmp = 0;
    if (lineSort.value === 'estimated_amount') {
      cmp = a.line.estimated_amount - b.line.estimated_amount;
    } else if (lineSort.value === 'product_name') {
      cmp = a.line.product_name.localeCompare(b.line.product_name);
    } else {
      cmp = a.plan.plan_number.localeCompare(b.plan.plan_number) || a.line.line_number - b.line.line_number;
    }
    return lineSortOrder.value === 'asc' ? cmp : -cmp;
  });

  return rows;
});

const paginatedLines = computed(() => {
  const start = (linePage.value - 1) * linePerPage.value;
  return filteredLines.value.slice(start, start + linePerPage.value);
});
</script>

<template>
  <div class="procurement-plans-page">
    <!-- Breadcrumb on transparent canvas -->
    <AppBreadcrumb :items="breadcrumbItems" :noMargin="true" />

    <!-- Top Summary KPI Card + Unified Master-Child Tabs -->
    <div class="plans-top-card">
      <div class="metrics-grid">
        <MetricCard
          label="Total Procurement Plans"
          :value="totalPlansCount"
          subtext="Annual & periodic buying plans"
          :icon="ClipboardList"
          :show-menu="false"
        />
        <MetricCard
          label="Approved Plans"
          :value="approvedPlansCount"
          subtext="Active for requisition drawdown"
          :icon="CheckCircle2"
          :show-menu="false"
        />
        <MetricCard
          label="Draft & In Review"
          :value="inReviewPlansCount"
          subtext="Pending submission or revision"
          :icon="Clock"
          :show-menu="false"
        />
        <MetricCard
          label="Total Planned Value"
          :value="formatCurrencyETB(totalPlannedBudget)"
          subtext="Sum of current version estimates"
          :icon="Banknote"
          :show-menu="false"
        />
      </div>

      <div class="top-card-tabs-wrapper">
        <BaseTabs
          v-model="activeTab"
          :tabs="planTabs"
          type="rounded"
          size="sm"
        />
      </div>
    </div>

    <!-- TAB 1: PROCUREMENT PLANS DIRECTORY -->
    <AppDataTable
      v-if="activeTab === 'plans'"
      title="Procurement Plans"
      subtitle="Annual and periodic buying plans with versioned revisions, budget alignment, and requisition drawdown tracking."
      v-model:searchQuery="searchQuery"
      searchPlaceholder="Search by plan number, name, unit, or fiscal year..."
      :showSearch="true"
      :showFilter="true"
      :filterCount="activeFilterCount"
      :showSort="true"
      :sortOptions="sortOptions"
      v-model:currentSort="currentSort"
      v-model:sortOrder="sortOrder"
      :showColumns="true"
      :columns="tableColumns"
      :showFullscreen="true"
      :totalEntries="filteredPlans.length"
      v-model:currentPage="currentPage"
      v-model:perPage="perPage"
      @toggleColumn="handleToggleColumn"
      @resetFilter="resetFilters"
    >
      <template #actions>
        <AppButton variant="primary" size="sm" @click="openQuickCreate">
          <template #icon-left><Plus :size="15" /></template>
          Create Procurement Plan
        </AppButton>
      </template>

      <template #filter-panel>
        <div class="filter-panel-grid">
          <FormSelect
            v-model="filterPeriodType"
            label="Period Type"
            :options="[{ value: '', label: 'All Period Types' }, ...planPeriodTypeOptions]"
            placeholder="Select Type"
          />
          <FormSelect
            v-model="filterStatus"
            label="Plan Status"
            :options="[{ value: '', label: 'All Statuses' }, ...planStatusOptions]"
            placeholder="Select Status"
          />
          <FormSelect
            v-model="filterUnitId"
            label="Procurement Unit"
            :options="getFilterUnitOptions"
            placeholder="Select Unit"
          />
        </div>
        <div v-if="activeFilterCount > 0" class="filter-panel-footer">
          <AppButton variant="outline" size="sm" @click="resetFilters">
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
                  :modelValue="isAllPageSelected"
                  @update:modelValue="(v) => toggleSelectAllPage(Boolean(v))"
                />
                <span>Plan</span>
              </div>
            </th>
            <th v-if="isColumnVisible('period_type')">Period Type</th>
            <th v-if="isColumnVisible('period_window')">Coverage Window</th>
            <th v-if="isColumnVisible('procurement_unit')">Procurement Unit</th>
            <th v-if="isColumnVisible('current_version')">Current Version</th>
            <th v-if="isColumnVisible('estimated_total')" class="th-right">Planned Budget</th>
            <th v-if="isColumnVisible('plan_status')">Plan Status</th>
            <th v-if="isColumnVisible('state')">State</th>
            <th v-if="isColumnVisible('entity_name')">Entity</th>
            <th v-if="isColumnVisible('fiscal_year')">Fiscal Year</th>
            <th v-if="isColumnVisible('budget_id')">Budget</th>
            <th v-if="isColumnVisible('actions')" class="th-actions">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="paginatedPlans.length === 0">
            <td :colspan="9" class="empty-row-cell">
              <div class="empty-state-box">
                <ClipboardList :size="32" class="empty-state-icon" />
                <p class="empty-state-title">No procurement plans found</p>
                <p class="empty-state-sub">
                  Adjust your search or filters, or create a new annual/periodic procurement plan.
                </p>
              </div>
            </td>
          </tr>

          <tr
            v-for="plan in paginatedPlans"
            :key="plan.id"
            class="erp-row"
            :class="{ 'row-selected': selectedIds.includes(plan.id) }"
            @click="goToDetail(plan)"
          >
            <!-- Lead Identity Column -->
            <td class="td-lead" @click.stop>
              <div class="lead-cell-wrap">
                <FormCheckbox
                  :modelValue="selectedIds.includes(plan.id)"
                  @update:modelValue="(v) => toggleSelectRow(plan.id, Boolean(v))"
                />
                <div class="lead-text-stack" @click="goToDetail(plan)">
                  <span class="cell-primary-title">{{ plan.name }}</span>
                  <span class="cell-subtext">{{ plan.plan_number }} • {{ plan.fiscal_year_id }}</span>
                </div>
              </div>
            </td>

            <td v-if="isColumnVisible('period_type')">
              <BaseBadge size="sm" color="blue">
                {{ getPlanPeriodTypeLabel(plan.period_type_lookup_value_id) }}
              </BaseBadge>
            </td>

            <td v-if="isColumnVisible('period_window')">
              <span class="cell-secondary-text">{{ formatDisplayDateRange(plan.period_start, plan.period_end) }}</span>
            </td>

            <td v-if="isColumnVisible('procurement_unit')">
              <span class="tertiary-plain-text">{{ plan.procurement_unit_name }}</span>
            </td>

            <td v-if="isColumnVisible('current_version')">
              <BaseBadge size="sm" color="indigo">
                v{{ getCurrentPlanVersion(plan.id)?.version_number ?? 0 }}
              </BaseBadge>
            </td>

            <td v-if="isColumnVisible('estimated_total')" class="td-right">
              <span class="cell-amount-text">
                {{ formatCurrencyETB(getPlanTotalEstimatedAmount(plan.id), plan.currency_id) }}
              </span>
            </td>

            <td v-if="isColumnVisible('plan_status')">
              <BaseBadge size="sm" :color="getPlanStatusBadgeColor(plan.plan_status_lookup_value_id)">
                {{ getPlanStatusLabel(plan.plan_status_lookup_value_id) }}
              </BaseBadge>
            </td>

            <td v-if="isColumnVisible('state')">
              <BaseBadge size="sm" :color="plan.state === 'active' ? 'success' : 'gray'">
                {{ plan.state === 'active' ? 'Active' : 'Inactive' }}
              </BaseBadge>
            </td>

            <td v-if="isColumnVisible('entity_name')">
              <span class="tertiary-plain-text">{{ plan.entity_name }}</span>
            </td>

            <td v-if="isColumnVisible('fiscal_year')">
              <span class="tertiary-plain-text">{{ plan.fiscal_year_id }}</span>
            </td>

            <td v-if="isColumnVisible('budget_id')">
              <span class="tertiary-plain-text">{{ plan.budget_id || '—' }}</span>
            </td>

            <td v-if="isColumnVisible('actions')" class="td-actions" @click.stop>
              <BaseDropdownMenu :items="getPlanActionItems(plan)" minWidth="200px">
                <template #trigger="{ toggle }">
                  <button
                    type="button"
                    class="btn-action-dots"
                    title="Plan Actions"
                    @click.stop="toggle"
                  >
                    <MoreVertical :size="18" />
                  </button>
                </template>
              </BaseDropdownMenu>
            </td>
          </tr>
        </tbody>
      </table>
    </AppDataTable>

    <!-- TAB 2: PLANNED ITEMS (ProcurementPlanVersionLine Matrix) -->
    <AppDataTable
      v-else
      title="Planned Items"
      subtitle="Line-level items across current procurement plan versions with category, budget allocation, and PR/PO/Receipt drawdown."
      v-model:searchQuery="lineSearchQuery"
      searchPlaceholder="Search by item, description, plan number, or category..."
      :showSearch="true"
      :showFilter="true"
      :filterCount="activeLineFilterCount"
      :showSort="true"
      :sortOptions="lineSortOptions"
      v-model:currentSort="lineSort"
      v-model:sortOrder="lineSortOrder"
      :showColumns="true"
      :columns="lineTableColumns"
      :showFullscreen="true"
      :totalEntries="filteredLines.length"
      v-model:currentPage="linePage"
      v-model:perPage="linePerPage"
      @toggleColumn="handleToggleLineCol"
      @resetFilter="resetLineFilters"
    >
      <template #actions>
        <AppButton variant="primary" size="sm" @click="router.push('/procurement/plans/items/create')">
          <template #icon-left><Plus :size="15" /></template>
          Add Planned Item
        </AppButton>
      </template>

      <template #filter-panel>
        <div class="filter-panel-grid">
          <FormSelect
            v-model="filterLineStatus"
            label="Line Status"
            :options="[{ value: '', label: 'All Line Statuses' }, ...planLineStatusOptions]"
            placeholder="Select Status"
          />
          <FormSelect
            v-model="filterLineCategory"
            label="Category"
            :options="[{ value: '', label: 'All Categories' }, ...categoryOptions]"
            placeholder="Select Category"
          />
        </div>
        <div v-if="activeLineFilterCount > 0" class="filter-panel-footer">
          <AppButton variant="outline" size="sm" @click="resetLineFilters">
            Reset Filters
          </AppButton>
        </div>
      </template>

      <table class="erp-table">
        <thead>
          <tr>
            <th class="th-lead">Item &amp; Plan</th>
            <th v-if="isLineColVisible('category_dept')">Category</th>
            <th v-if="isLineColVisible('planned_qty')" class="th-right">Planned Qty</th>
            <th v-if="isLineColVisible('estimated_amount')" class="th-right">Est. Amount</th>
            <th v-if="isLineColVisible('execution')" class="th-right">PR / PO / Recv</th>
            <th v-if="isLineColVisible('line_status')">Line Status</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="paginatedLines.length === 0">
            <td :colspan="6" class="empty-row-cell">
              <div class="empty-state-box">
                <ClipboardList :size="32" class="empty-state-icon" />
                <p class="empty-state-title">No planned items found</p>
                <p class="empty-state-sub">
                  Adjust your search or filters, or create a procurement plan to add planned items.
                </p>
              </div>
            </td>
          </tr>

          <tr
            v-for="{ line, plan, versionNumber } in paginatedLines"
            :key="line.id"
            class="erp-row"
            @click="goToDetail(plan)"
          >
            <td class="td-lead">
              <div class="lead-text-stack">
                <span class="cell-primary-title">{{ line.product_name }}</span>
                <span class="cell-subtext">{{ plan.plan_number }} (v{{ versionNumber }}) • Line #{{ line.line_number }}</span>
              </div>
            </td>

            <td v-if="isLineColVisible('category_dept')">
              <span class="cell-secondary-text">{{ line.category_name }}</span>
            </td>

            <td v-if="isLineColVisible('planned_qty')" class="td-right">
              <span class="cell-secondary-text">
                {{ line.planned_quantity.toLocaleString() }} {{ line.measurement_id || '' }}
              </span>
            </td>

            <td v-if="isLineColVisible('estimated_amount')" class="td-right">
              <span class="cell-amount-text">
                {{ formatCurrencyETB(line.estimated_amount, plan.currency_id) }}
              </span>
            </td>

            <td v-if="isLineColVisible('execution')" class="td-right">
              <span class="tertiary-plain-text">
                {{ line.requisitioned_quantity.toLocaleString() }} /
                {{ line.ordered_quantity.toLocaleString() }} /
                {{ line.received_quantity.toLocaleString() }}
              </span>
            </td>

            <td v-if="isLineColVisible('line_status')">
              <BaseBadge size="sm" :color="getPlanLineStatusBadgeColor(line.plan_line_status_lookup_value_id)">
                {{ getPlanLineStatusLabel(line.plan_line_status_lookup_value_id) }}
              </BaseBadge>
            </td>
          </tr>
        </tbody>
      </table>
    </AppDataTable>

    <!-- Floating Batch Action Bar -->
    <TableFloatingBar
      v-if="selectedIds.length > 0"
      :selectedCount="selectedIds.length"
      :totalCount="filteredPlans.length"
      @selectAll="selectAllFiltered"
      @clearSelection="selectedIds = []"
    >
      <template #actions>
        <AppButton variant="secondary-gray" size="sm" @click="handleBulkActivate">
          Activate
        </AppButton>
        <AppButton variant="secondary-gray" size="sm" @click="handleBulkDeactivate">
          Deactivate
        </AppButton>
        <AppButton variant="destructive" size="sm" @click="handleBulkDelete">
          Delete
        </AppButton>
      </template>
    </TableFloatingBar>

    <!-- QUICK CREATE MODAL (5 Essential Fields + Expand Full Form) -->
    <QuickCreateModal
      v-model:show="showQuickModal"
      title="Create Procurement Plan"
      :showExpandButton="true"
      saveLabel="Save"
      width="md"
      @save="handleSaveQuick"
      @expand="handleExpandFullForm"
    >
      <div class="quick-form-body">
        <FormInput
          v-model="quickForm.name"
          label="Plan Name"
          :error="quickErrors.name"
          required
        />

        <div class="modal-form-row">
          <FormSelect
            v-model="quickForm.period_type_lookup_value_id"
            label="Period Type"
            :options="planPeriodTypeOptions"
            placeholder="Select Type"
            required
          />
          <FormSelect
            v-model="quickForm.fiscal_year_id"
            label="Fiscal Year"
            :options="fiscalYearOptions"
            placeholder="Select Year"
            required
          />
        </div>

        <div class="modal-form-row">
          <FormInput
            v-model="quickForm.period_start"
            type="date"
            label="Period Start"
            :error="quickErrors.period_start"
            required
          />
          <FormInput
            v-model="quickForm.period_end"
            type="date"
            label="Period End"
            :error="quickErrors.period_end"
            required
          />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.procurement-plans-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.plans-top-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.top-card-tabs-wrapper {
  padding-top: 4px;
}

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
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

.erp-table thead th.th-right {
  text-align: right;
}

.erp-table thead th.th-actions {
  text-align: center;
  padding-right: 24px;
  width: 80px;
}

.erp-row {
  height: 72px;
  border-bottom: 1px solid #e9eaeb;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.erp-row:hover {
  background-color: #fafafa;
}

.erp-row.row-selected {
  background-color: #f0f7ff;
}

.erp-table tbody td {
  padding: 12px 16px;
  vertical-align: middle;
}

.erp-table tbody td.td-lead {
  padding-left: 24px;
}

.erp-table tbody td.td-right {
  text-align: right;
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

.lead-text-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.cell-primary-title {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
}

.cell-secondary-text {
  font-size: 13.5px;
  color: #404040;
}

.cell-subtext {
  font-size: 12px;
  color: #737373;
}

.tertiary-plain-text {
  font-size: 13.5px;
  color: #737373;
}

.cell-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.cell-amount-text {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
  font-variant-numeric: tabular-nums;
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
  transition: background-color 0.15s ease, color 0.15s ease;
}

.btn-action-dots:hover {
  background-color: #f5f5f5;
  color: #404040;
}

.empty-row-cell {
  padding: 48px 24px !important;
  text-align: center;
}

.empty-state-box {
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
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.empty-state-sub {
  margin: 0;
  font-size: 13px;
  color: #737373;
}

.quick-form-body {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.modal-form-row {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

@media (max-width: 1120px) {
  .metrics-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 640px) {
  .metrics-grid {
    grid-template-columns: 1fr;
  }
}
</style>
