<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Sliders, Plus, Search, Filter, ArrowUpDown, ChevronDown, 
  MoreVertical, Edit2, Trash2, Eye, Copy, Check, Calendar, 
  CheckCircle2, AlertCircle, Maximize2, Award, X, DollarSign,
  Layers, ChevronRight, Grid
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

const router = useRouter();

// ─── Lookups & Types (HR_Schema_final-v4.sql lines 1044–1109) ───
export type RowState = 'active' | 'inactive';

export interface SalaryMatrixRecord {
  id: number;
  uuid: string;
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  effective_from: string;
  effective_to?: string | null;
  number_of_steps: number;
  currency_id: number;
  currency_code: string;
  is_default: boolean;
  grades_count: number;
  state: RowState;
}

export interface MatrixGridStep {
  step_number: number;
  amount: number;
  increment_years?: number | null;
  description?: string;
}

export interface MatrixGridGrade {
  id: number;
  code: string;
  name: string;
  level: number;
  base_salary: number;
  ceiling_salary: number;
  steps: MatrixGridStep[];
}

// ─── Breadcrumbs (Clean Page Names ONLY: Rule 3.2) ───
const breadcrumbItems = [
  { label: 'Salary Matrices' }
];

// ─── State Management ───
const searchQuery = ref('');
const filterEntity = ref('All');
const filterCurrency = ref('All');
const filterState = ref('All');
const currentSort = ref('entity');
const sortOrder = ref<'asc' | 'desc'>('asc');
const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const showQuickCreate = ref(false);
const showMatrixGridModal = ref(false);
const selectedMatrixForGrid = ref<SalaryMatrixRecord | null>(null);
const quickActionToast = ref<string | null>(null);

// ─── Table Columns (Strict Schema Alignment - Zero Phantom Columns) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'entity', label: 'Owning Entity', visible: true, sortable: true },
  { key: 'effective_timeline', label: 'Effective Timeline', visible: true, sortable: true },
  { key: 'steps_per_grade', label: 'Steps per Grade', visible: true, sortable: true },
  { key: 'grades_count', label: 'Mapped Grades', visible: true, sortable: true },
  { key: 'currency', label: 'Currency', visible: true, sortable: true },
  { key: 'is_default', label: 'Default Matrix', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

// ─── Mock Data Strictly Aligned with HR_Schema_final-v4.sql lines 1056–1063 ───
const matrices = ref<SalaryMatrixRecord[]>([
  {
    id: 1,
    uuid: 'sm-uuid-001',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    effective_from: '2020-01-01',
    effective_to: '2023-06-30',
    number_of_steps: 5,
    currency_id: 1,
    currency_code: 'ETB',
    is_default: false,
    grades_count: 5,
    state: 'active'
  },
  {
    id: 2,
    uuid: 'sm-uuid-002',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    effective_from: '2023-07-01',
    effective_to: '2026-07-07',
    number_of_steps: 5,
    currency_id: 1,
    currency_code: 'ETB',
    is_default: false,
    grades_count: 5,
    state: 'active'
  },
  {
    id: 3,
    uuid: 'sm-uuid-003',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    effective_from: '2026-07-08',
    effective_to: null,
    number_of_steps: 7,
    currency_id: 1,
    currency_code: 'ETB',
    is_default: true,
    grades_count: 5,
    state: 'active'
  },
  {
    id: 4,
    uuid: 'sm-uuid-004',
    tenant_id: 1,
    entity_id: 7,
    entity_name: 'Haleta Grand Hotel & Suites',
    effective_from: '2026-07-08',
    effective_to: null,
    number_of_steps: 5,
    currency_id: 1,
    currency_code: 'ETB',
    is_default: true,
    grades_count: 4,
    state: 'active'
  },
  {
    id: 5,
    uuid: 'sm-uuid-005',
    tenant_id: 1,
    entity_id: 9,
    entity_name: 'Haleta Hawassa Hub',
    effective_from: '2026-07-08',
    effective_to: null,
    number_of_steps: 5,
    currency_id: 1,
    currency_code: 'ETB',
    is_default: true,
    grades_count: 3,
    state: 'active'
  }
]);

// ─── Mock 2D Grid Data for Visual Inspection ───
const matrixGrids: Record<number, MatrixGridGrade[]> = {
  1: [
    {
      id: 3,
      code: 'C1',
      name: 'Grade C1',
      level: 3,
      base_salary: 5000,
      ceiling_salary: 9000,
      steps: [
        { step_number: 1, amount: 6500, increment_years: null, description: 'Entry Step' },
        { step_number: 2, amount: 7150, increment_years: 2, description: 'Scale Step 2' },
        { step_number: 3, amount: 7850, increment_years: 2, description: 'Long-service Step' },
        { step_number: 4, amount: 8400, increment_years: 2, description: 'Advanced Step' },
        { step_number: 5, amount: 8950, increment_years: 2, description: 'Grade Ceiling Step' }
      ]
    },
    {
      id: 4,
      code: 'C2',
      name: 'Grade C2',
      level: 4,
      base_salary: 8000,
      ceiling_salary: 13000,
      steps: [
        { step_number: 1, amount: 8500, increment_years: null, description: 'Entry Step' },
        { step_number: 2, amount: 9400, increment_years: 2, description: 'Scale Step 2' },
        { step_number: 3, amount: 10500, increment_years: 2, description: 'Standard Step' },
        { step_number: 4, amount: 11600, increment_years: 2, description: 'Senior Step' },
        { step_number: 5, amount: 12800, increment_years: 2, description: 'Grade Ceiling Step' }
      ]
    },
    {
      id: 5,
      code: 'B2',
      name: 'Grade B2',
      level: 5,
      base_salary: 11000,
      ceiling_salary: 18000,
      steps: [
        { step_number: 1, amount: 12000, increment_years: null, description: 'Entry Step' },
        { step_number: 2, amount: 13500, increment_years: 2, description: 'Scale Step 2' },
        { step_number: 3, amount: 14900, increment_years: 2, description: 'Mid Step' },
        { step_number: 4, amount: 16300, increment_years: 2, description: 'Senior Step' },
        { step_number: 5, amount: 17800, increment_years: 2, description: 'Grade Ceiling Step' }
      ]
    },
    {
      id: 6,
      code: 'B1',
      name: 'Grade B1',
      level: 6,
      base_salary: 17000,
      ceiling_salary: 27000,
      steps: [
        { step_number: 1, amount: 18500, increment_years: null, description: 'Entry Step' },
        { step_number: 2, amount: 20500, increment_years: 2, description: 'Scale Step 2' },
        { step_number: 3, amount: 22500, increment_years: 2, description: 'Mid Step' },
        { step_number: 4, amount: 24700, increment_years: 2, description: 'Senior Step' },
        { step_number: 5, amount: 26800, increment_years: 2, description: 'Grade Ceiling Step' }
      ]
    },
    {
      id: 7,
      code: 'A3',
      name: 'Grade A3',
      level: 7,
      base_salary: 26000,
      ceiling_salary: 40000,
      steps: [
        { step_number: 1, amount: 28000, increment_years: null, description: 'Entry Step' },
        { step_number: 2, amount: 31000, increment_years: 2, description: 'Scale Step 2' },
        { step_number: 3, amount: 34000, increment_years: 2, description: 'Mid Step' },
        { step_number: 4, amount: 37000, increment_years: 2, description: 'Principal Step' },
        { step_number: 5, amount: 39800, increment_years: 2, description: 'Grade Ceiling Step' }
      ]
    }
  ]
};

// ─── Quick Create Form State ───
const quickForm = ref({
  entity_id: 'Haleta Addis Ababa HQ',
  effective_from: new Date().toISOString().split('T')[0],
  number_of_steps: 5,
  currency_code: 'ETB',
  is_default: true
});

// ─── Filter & Search Logic ───
const activeFilterCount = computed(() => {
  let count = 0;
  if (filterEntity.value !== 'All') count++;
  if (filterCurrency.value !== 'All') count++;
  if (filterState.value !== 'All') count++;
  return count;
});

const filteredMatrices = computed(() => {
  return matrices.value.filter(m => {
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase();
      const matchEntity = m.entity_name.toLowerCase().includes(q);
      const matchPeriod = `${m.effective_from} ${m.effective_to || ''}`.toLowerCase().includes(q);
      if (!matchEntity && !matchPeriod) return false;
    }
    if (filterEntity.value !== 'All' && m.entity_name !== filterEntity.value) return false;
    if (filterCurrency.value !== 'All' && m.currency_code !== filterCurrency.value) return false;
    if (filterState.value !== 'All' && m.state !== filterState.value.toLowerCase()) return false;
    return true;
  }).sort((a, b) => {
    let valA = a[currentSort.value as keyof SalaryMatrixRecord];
    let valB = b[currentSort.value as keyof SalaryMatrixRecord];
    if (valA === undefined || valA === null) valA = '';
    if (valB === undefined || valB === null) valB = '';
    if (valA < valB) return sortOrder.value === 'asc' ? -1 : 1;
    if (valA > valB) return sortOrder.value === 'asc' ? 1 : -1;
    return 0;
  });
});

// ─── Selection Logic ───
const isAllSelected = computed(() => {
  return filteredMatrices.value.length > 0 && 
    filteredMatrices.value.every(m => selectedRowIds.value.includes(m.id));
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = filteredMatrices.value.map(m => m.id);
  }
};

const toggleRowSelection = (id: number) => {
  const index = selectedRowIds.value.indexOf(id);
  if (index > -1) {
    selectedRowIds.value.splice(index, 1);
  } else {
    selectedRowIds.value.push(id);
  }
};

const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

const handleToggleColumn = ({ key, visible }: { key: string; visible: boolean }) => {
  const col = tableColumns.value.find(c => c.key === key);
  if (col) col.visible = visible;
};

// ─── Actions Menu ───
const toggleActionMenu = (id: number, event: Event) => {
  event.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
};

const showToast = (msg: string) => {
  quickActionToast.value = msg;
  setTimeout(() => {
    quickActionToast.value = null;
  }, 4000);
};

// ─── Quick Create Handlers ───
const handleQuickSave = () => {
  if (!quickForm.value.entity_id) {
    alert('Please select an Owning Entity.');
    return;
  }

  const newId = Date.now();
  const newRecord: SalaryMatrixRecord = {
    id: newId,
    uuid: `sm-${newId}`,
    tenant_id: 1,
    entity_id: quickForm.value.entity_id.includes('HQ') ? 1 : 7,
    entity_name: quickForm.value.entity_id,
    effective_from: quickForm.value.effective_from,
    effective_to: null,
    number_of_steps: Number(quickForm.value.number_of_steps),
    currency_id: 1,
    currency_code: quickForm.value.currency_code,
    is_default: quickForm.value.is_default,
    grades_count: 0,
    state: 'active'
  };

  matrices.value.unshift(newRecord);
  showQuickCreate.value = false;
  showToast(`Salary Matrix for "${newRecord.entity_name}" created successfully.`);
};

// Navigate to Expand Full Form
const handleExpandFullForm = () => {
  showQuickCreate.value = false;
  router.push({
    path: '/hr/salary-matrices/create',
    query: {
      entity: quickForm.value.entity_id,
      steps: quickForm.value.number_of_steps,
      effective_from: quickForm.value.effective_from
    }
  });
};

// ─── Inspect Matrix 2D Grid ───
const openMatrixGrid = (matrix: SalaryMatrixRecord) => {
  closeActionMenu();
  selectedMatrixForGrid.value = matrix;
  showMatrixGridModal.value = true;
};

const currentMatrixGridData = computed(() => {
  if (!selectedMatrixForGrid.value) return [];
  return matrixGrids[selectedMatrixForGrid.value.id] || matrixGrids[1];
});

// Format Currency
const formatETB = (val: number) => {
  return new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(val);
};

// Floating Bar Actions
const handleBatchDelete = () => {
  matrices.value = matrices.value.filter(m => !selectedRowIds.value.includes(m.id));
  selectedRowIds.value = [];
  showToast('Selected salary matrices deleted.');
};

onMounted(() => {
  window.addEventListener('click', closeActionMenu);
});

onUnmounted(() => {
  window.removeEventListener('click', closeActionMenu);
});
</script>

<template>
  <div class="salary-matrices-page">
    <!-- Breadcrumb Bar -->
    <div class="page-breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Toast Notification Banner -->
    <div v-if="quickActionToast" class="quick-toast-banner">
      <CheckCircle2 :size="15" class="text-emerald-600" />
      <span>{{ quickActionToast }}</span>
    </div>

    <!-- MAIN DATA TABLE -->
    <div class="directory-view-wrapper">
      <AppDataTable
        title="Salary Matrices"
        subtitle="Manage enterprise compensation pay grids, prescriptive grade-step progression ladders, statutory currency baselines, and effective-dated salary versioning across entities."
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search by Owning Entity..."
        :showSearch="true"
        :showFilter="true"
        :filterCount="activeFilterCount"
        :showSort="true"
        v-model:currentSort="currentSort"
        v-model:sortOrder="sortOrder"
        :showColumns="true"
        :columns="tableColumns"
        @toggleColumn="handleToggleColumn"
      >
        <!-- Primary Action -->
        <template #actions>
          <button 
            type="button" 
            class="btn-primary-create" 
            @click="router.push('/hr/salary-matrices/create')"
          >
            <Plus :size="15" />
            <span>Create Salary Matrix</span>
          </button>
        </template>

        <!-- Filter Drawer Popover Content -->
        <template #filter>
          <div class="filter-grid">
            <FormSelect
              label="Owning Entity"
              v-model="filterEntity"
              :options="['All', 'Haleta Addis Ababa HQ', 'Haleta Grand Hotel & Suites', 'Haleta Hawassa Hub']"
            />
            <FormSelect
              label="Currency"
              v-model="filterCurrency"
              :options="['All', 'ETB']"
            />
            <FormSelect
              label="Record State"
              v-model="filterState"
              :options="['All', 'Active', 'Inactive']"
            />
          </div>
        </template>

        <!-- Table Listing -->
        <table class="erp-table">
          <thead>
            <tr>
              <th class="col-checkbox">
                <input 
                  type="checkbox" 
                  class="custom-checkbox" 
                  :checked="isAllSelected" 
                  @change="toggleSelectAll" 
                  aria-label="Select All" 
                />
              </th>

              <!-- Rule 5: Primary Column is Owning Entity (Secondary Color #404040) -->
              <th v-if="isColumnVisible('entity')" class="col-entity sortable" @click="currentSort = 'entity_name'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>Owning Entity</span>
                  <ArrowUpDown :size="12" class="sort-icon" />
                </div>
              </th>

              <!-- All Subsequent Columns in Tertiary Color -->
              <th v-if="isColumnVisible('effective_timeline')" class="col-period sortable" @click="currentSort = 'effective_from'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>Effective Timeline</span>
                  <ArrowUpDown :size="12" class="sort-icon" />
                </div>
              </th>
              <th v-if="isColumnVisible('steps_per_grade')" class="col-steps sortable" @click="currentSort = 'number_of_steps'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>Steps per Grade</span>
                  <ArrowUpDown :size="12" class="sort-icon" />
                </div>
              </th>
              <th v-if="isColumnVisible('grades_count')" class="col-grades">Mapped Grades</th>
              <th v-if="isColumnVisible('currency')" class="col-currency">Currency</th>
              <th v-if="isColumnVisible('is_default')" class="col-default">Default Matrix</th>
              <th v-if="isColumnVisible('state')" class="col-state sortable" @click="currentSort = 'state'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>State</span>
                  <ArrowUpDown :size="12" class="sort-icon" />
                </div>
              </th>
              <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr 
              v-for="item in filteredMatrices" 
              :key="item.id"
              class="erp-row cursor-pointer"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
              @click="openMatrixGrid(item)"
            >
              <td class="col-checkbox" @click.stop>
                <input 
                  type="checkbox" 
                  class="custom-checkbox" 
                  :checked="selectedRowIds.includes(item.id)" 
                  @change="toggleRowSelection(item.id)" 
                />
              </td>

              <!-- Rule 5: Primary Column is Owning Entity styled in Secondary Color (#404040, font-weight 500) -->
              <td v-if="isColumnVisible('entity')" class="col-entity">
                <span class="table-entity-primary">{{ item.entity_name }}</span>
              </td>

              <!-- Rule 5 & 6: All subsequent columns in Tertiary plain text (#737373), NO decorative badges -->
              <td v-if="isColumnVisible('effective_timeline')" class="col-period">
                <span class="text-tertiary">{{ item.effective_from }} - {{ item.effective_to || 'Current' }}</span>
              </td>

              <td v-if="isColumnVisible('steps_per_grade')" class="col-steps">
                <span class="text-tertiary">{{ item.number_of_steps }} Steps</span>
              </td>

              <td v-if="isColumnVisible('grades_count')" class="col-grades">
                <span class="text-tertiary">{{ item.grades_count }} Grades</span>
              </td>

              <td v-if="isColumnVisible('currency')" class="col-currency">
                <span class="text-tertiary font-mono">{{ item.currency_code }}</span>
              </td>

              <td v-if="isColumnVisible('is_default')" class="col-default">
                <span class="text-tertiary">{{ item.is_default ? 'Default Baseline' : 'Secondary' }}</span>
              </td>

              <!-- Badges reserved strictly for lifecycle state -->
              <td v-if="isColumnVisible('state')" class="col-state">
                <span class="status-pill" :class="item.state === 'active' ? 'status-pill-active' : 'status-pill-inactive'">
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </span>
              </td>

              <!-- Action 3-dots -->
              <td v-if="isColumnVisible('actions')" class="col-actions" @click.stop>
                <div class="action-dropdown-container">
                  <button 
                    type="button" 
                    class="btn-action-dots" 
                    @click="toggleActionMenu(item.id, $event)"
                    aria-label="Actions"
                  >
                    <MoreVertical :size="15" />
                  </button>

                    <div v-if="activeActionMenuId === item.id" class="action-popup-menu">
                      <button type="button" class="menu-item" @click="router.push(`/hr/salary-matrices/create?entity=${encodeURIComponent(item.entity_name)}&steps=${item.number_of_steps}&effective_from=${item.effective_from}&mode=preview`); closeActionMenu();">
                        <Eye :size="14" />
                        <span>View Pay Grid Matrix</span>
                      </button>
                      <button type="button" class="menu-item" @click="router.push(`/hr/salary-matrices/create?entity=${encodeURIComponent(item.entity_name)}&steps=${item.number_of_steps}&effective_from=${item.effective_from}&mode=edit`); closeActionMenu();">
                        <Edit2 :size="14" />
                        <span>Edit Matrix Grid</span>
                      </button>
                    <button 
                      type="button" 
                      class="menu-item"
                      @click="item.state = item.state === 'active' ? 'inactive' : 'active'; showToast(`Updated matrix for ${item.entity_name} state.`); closeActionMenu();"
                    >
                      <Check :size="14" />
                      <span>{{ item.state === 'active' ? 'Deactivate Matrix' : 'Activate Matrix' }}</span>
                    </button>
                    <div class="menu-divider"></div>
                    <button 
                      type="button" 
                      class="menu-item text-rose-600 hover:bg-rose-50"
                      @click="matrices = matrices.filter(m => m.id !== item.id); showToast(`Deleted matrix for ${item.entity_name}`); closeActionMenu();"
                    >
                      <Trash2 :size="14" />
                      <span>Delete Matrix</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>

            <tr v-if="filteredMatrices.length === 0">
              <td colspan="8" class="table-empty-row">
                <div class="empty-state-box">
                  <p class="empty-title">No Salary Matrices Found</p>
                  <p class="empty-subtitle">Adjust your filter options or create a new salary matrix grid.</p>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </AppDataTable>
    </div>

    <!-- FLOATING BATCH ACTIONS BAR -->
    <TableFloatingBar 
      :count="selectedRowIds.length" 
      @delete="handleBatchDelete" 
    />

    <!-- QUICK CREATE MODAL (Standard: <= 5 Required Fields, No Header Subtitle, No Bottom Divider Line) -->
    <QuickCreateModal
      v-model:show="showQuickCreate"
      title="Create Salary Matrix"
      saveLabel="Save"
      @save="handleQuickSave"
      @expand="handleExpandFullForm"
      :showExpandButton="true"
      width="md"
    >
      <div class="quick-create-form-body">
        <!-- Owning Entity: Strict Rule 5 (Select Placeholder Only) -->
        <FormSelect
          label="Owning Entity"
          v-model="quickForm.entity_id"
          :options="['Haleta Addis Ababa HQ', 'Haleta Grand Hotel & Suites', 'Haleta Hawassa Hub']"
          placeholder="Select"
          required
        />

        <!-- Effective From Date with [GC] Gregorian Tag -->
        <div class="form-group-date">
          <label class="erp-field-label">Effective From Date <span class="required-star">*</span></label>
          <div class="date-input-wrapper">
            <Calendar :size="15" class="date-icon" />
            <input 
              type="date" 
              v-model="quickForm.effective_from" 
              class="erp-date-input" 
              required
            />
            <span class="gc-pill-tag">GC</span>
          </div>
        </div>

        <div class="form-row-dual">
          <!-- Number of Steps: Prescriptive Grid parameter -->
          <FormSelect
            label="Steps per Grade"
            v-model="quickForm.number_of_steps"
            :options="[3, 5, 7, 10]"
            placeholder="Select"
            required
          />

          <!-- Currency -->
          <FormSelect
            label="Currency"
            v-model="quickForm.currency_code"
            :options="['ETB']"
            placeholder="Select"
            required
          />
        </div>

        <!-- Default Matrix Checkbox: Strict Rule 5 (Must have BOTH Label and Description) -->
        <FormCheckbox
          v-model="quickForm.is_default"
          label="Default Salary Matrix"
          description="Designates this compensation matrix as the active pay baseline for newly configured job grades and positions."
        />
      </div>
    </QuickCreateModal>

    <!-- 2D PAY GRID INSPECTION MODAL (Grade x Step Progression Ladder) -->
    <div v-if="showMatrixGridModal && selectedMatrixForGrid" class="matrix-grid-modal-backdrop" @click="showMatrixGridModal = false">
      <div class="matrix-grid-modal-content" @click.stop>
        <!-- Modal Header -->
        <div class="matrix-grid-modal-header">
          <div class="header-left">
            <h2 class="modal-title">{{ selectedMatrixForGrid.entity_name }} — Pay Scale Matrix</h2>
            <div class="modal-submeta">
              <span>Effective: {{ selectedMatrixForGrid.effective_from }} - {{ selectedMatrixForGrid.effective_to || 'Current' }}</span>
              <span class="meta-dot">•</span>
              <span class="font-medium text-blue-700">{{ selectedMatrixForGrid.number_of_steps }} Progression Steps</span>
              <span class="meta-dot">•</span>
              <span class="font-mono text-neutral-500">{{ selectedMatrixForGrid.currency_code }}</span>
            </div>
          </div>
          <button type="button" class="btn-close-modal" @click="showMatrixGridModal = false" aria-label="Close">
            <X :size="18" />
          </button>
        </div>

        <!-- 2D Grid Table -->
        <div class="matrix-grid-table-container">
          <table class="grid-table">
            <thead>
              <tr>
                <th class="th-grade">Job Grade</th>
                <th class="th-level">Level</th>
                <th class="th-guardrail">Base Floor (ETB)</th>
                <th 
                  v-for="s in selectedMatrixForGrid.number_of_steps" 
                  :key="s" 
                  class="th-step"
                >
                  Step {{ s }}
                </th>
                <th class="th-guardrail">Ceiling (ETB)</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="g in currentMatrixGridData" :key="g.id">
                <td class="td-grade">
                  <span class="grade-title">{{ g.name }}</span>
                  <span class="grade-code font-mono">{{ g.code }}</span>
                </td>
                <td class="td-level">
                  <span class="text-tertiary">Level {{ g.level }}</span>
                </td>
                <td class="td-guardrail">
                  <span class="guardrail-amount">{{ formatETB(g.base_salary) }}</span>
                </td>
                <td 
                  v-for="s in selectedMatrixForGrid.number_of_steps" 
                  :key="s" 
                  class="td-step"
                >
                  <div class="step-cell-content">
                    <span class="step-amount">{{ formatETB(g.steps[s - 1]?.amount || (g.base_salary + (s * 1000))) }}</span>
                    <span v-if="g.steps[s - 1]?.increment_years" class="step-rule font-mono">
                      +{{ g.steps[s - 1].increment_years }}y wait
                    </span>
                    <span v-else class="step-rule text-slate-400">Entry</span>
                  </div>
                </td>
                <td class="td-guardrail">
                  <span class="guardrail-amount">{{ formatETB(g.ceiling_salary) }}</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Modal Footer Actions -->
        <div class="matrix-grid-modal-footer">
          <div class="footer-hint">
            <span>* Discrete step amounts dictate monthly base salaries on grade movements. Guardrails enforce upper/lower bands.</span>
          </div>
          <div class="footer-actions">
            <button 
              type="button" 
              class="btn-secondary" 
              @click="router.push(`/hr/job-grades?matrix=${selectedMatrixForGrid.id}`)"
            >
              <Award :size="14" />
              <span>Manage Job Grades</span>
            </button>
            <button 
              type="button" 
              class="btn-primary" 
              @click="showMatrixGridModal = false"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.salary-matrices-page {
  padding: 24px;
  background-color: var(--primitive-color-neutral-50, #f8fafc);
  min-height: 100vh;
  box-sizing: border-box;
}

.page-breadcrumb-bar {
  margin-bottom: 16px;
}

/* Toast Banner */
.quick-toast-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  padding: 10px 16px;
  margin-bottom: 16px;
  font-size: 13.5px;
  color: #065f46;
  animation: fadeIn 0.2s ease-in-out;
}

.directory-view-wrapper {
  background: #ffffff;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

/* Primary Create Button (Well-rounded rectangle: 8px-10px) */
.btn-primary-create {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 38px;
  padding: 0 16px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-primary-create:hover {
  background-color: #09427d;
}

/* Filter Grid in Popover */
.filter-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  padding: 16px;
}

/* ERP Table Core */
.erp-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  background-color: #fafafa;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
}

.erp-table th.sortable {
  cursor: pointer;
  user-select: none;
}

.th-content {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.sort-icon {
  color: #94a3b8;
}

.erp-row {
  height: 48px;
  border-bottom: 1px solid #f1f5f9;
  transition: background-color 0.12s ease;
}

.erp-row:hover {
  background-color: #f8fafc;
}

.erp-row.row-selected {
  background-color: #f0f7ff;
}

.erp-table td {
  padding: 8px 16px;
  font-size: 13px;
  vertical-align: middle;
}

/* Checkbox */
.col-checkbox {
  width: 44px;
  text-align: center;
  padding: 0 8px !important;
}

.custom-checkbox {
  width: 16px;
  height: 16px;
  cursor: pointer;
  accent-color: #0B529C;
  border-radius: 4px;
}

/* Rule 4 & 5: Name Cell Stack */
.col-name {
  min-width: 260px;
}

.name-cell-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary,
.table-entity-primary {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040; /* Secondary Color for primary entity name */
}

.table-code-subtext {
  font-size: 11.5px;
  color: #737373; /* Tertiary color for code subtext */
}

/* Tertiary text color for all subsequent columns */
.text-tertiary {
  color: #737373;
  font-size: 13px;
}

/* Lifecycle Status Pills */
.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
}

.status-pill-active {
  background-color: #ecfdf5;
  color: #059669;
}

.status-pill-inactive {
  background-color: #f1f5f9;
  color: #64748b;
}

/* Action 3-dots Menu */
.col-actions {
  width: 60px;
  text-align: center;
}

.action-dropdown-container {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: 1px solid transparent;
  background: transparent;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s ease;
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
  min-width: 180px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  padding: 4px 0;
  z-index: 40;
  animation: fadeIn 0.12s ease-in-out;
}

.menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 14px;
  border: none;
  background: none;
  font-size: 12.5px;
  color: #404040;
  text-align: left;
  cursor: pointer;
  transition: background-color 0.1s ease;
}

.menu-item:hover {
  background-color: #f8fafc;
}

.menu-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 4px 0;
}

/* Empty State */
.table-empty-row {
  padding: 48px 16px !important;
  text-align: center;
}

.empty-state-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.empty-title {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
}

.empty-subtitle {
  font-size: 12.5px;
  color: #737373;
}

/* Quick Create Form Content */
.quick-create-form-body {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-row-dual {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
}

/* Date Input with GC Tag */
.form-group-date {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.erp-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.required-star {
  color: #e11d48;
}

.date-input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  height: 38px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 0 12px;
  transition: all 0.15s ease;
}

.date-input-wrapper:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.date-icon {
  color: #94a3b8;
  margin-right: 8px;
  flex-shrink: 0;
}

.erp-date-input {
  border: none;
  background: transparent;
  width: 100%;
  font-size: 13.5px;
  color: #404040;
  outline: none;
}

.gc-pill-tag {
  background-color: #f1f5f9;
  color: #64748b;
  font-size: 10.5px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 4px;
  letter-spacing: 0.5px;
}

/* Matrix 2D Inspection Modal */
.matrix-grid-modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
  padding: 24px;
}

.matrix-grid-modal-content {
  background: #ffffff;
  border-radius: 12px;
  width: 100%;
  max-width: 1100px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.matrix-grid-modal-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid #e2e8f0;
}

.modal-title {
  font-size: 18px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}

.modal-submeta {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12.5px;
  color: #737373;
}

.meta-dot {
  color: #cbd5e1;
}

.btn-close-modal {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #94a3b8;
  cursor: pointer;
}

.btn-close-modal:hover {
  background: #f1f5f9;
  color: #404040;
}

.matrix-grid-table-container {
  padding: 20px 24px;
  overflow-x: auto;
  overflow-y: auto;
  flex: 1;
}

.grid-table {
  width: 100%;
  border-collapse: collapse;
}

.grid-table th {
  background: #f8fafc;
  padding: 10px 14px;
  font-size: 12px;
  font-weight: 600;
  color: #475569;
  border: 1px solid #e2e8f0;
  text-align: left;
}

.grid-table td {
  padding: 12px 14px;
  border: 1px solid #e2e8f0;
  font-size: 13px;
  vertical-align: middle;
}

.td-grade {
  min-width: 150px;
}

.grade-title {
  display: block;
  font-weight: 500;
  color: #404040;
}

.grade-code {
  font-size: 11px;
  color: #737373;
}

.guardrail-amount {
  font-weight: 500;
  color: #475569;
}

.step-cell-content {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.step-amount {
  font-weight: 500;
  color: #0B529C;
  font-size: 13px;
}

.step-rule {
  font-size: 10.5px;
  color: #64748b;
}

.matrix-grid-modal-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 24px;
  border-top: 1px solid #e2e8f0;
  background: #f8fafc;
}

.footer-hint {
  font-size: 12px;
  color: #737373;
}

.footer-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.btn-secondary {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  border: 1px solid #e2e8f0;
  background: #ffffff;
  color: #404040;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-secondary:hover {
  background: #f1f5f9;
}

.btn-primary {
  display: inline-flex;
  align-items: center;
  height: 38px;
  padding: 0 20px;
  background: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-primary:hover {
  background: #09427d;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-3px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
