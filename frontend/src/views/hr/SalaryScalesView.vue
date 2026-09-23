<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Award, Plus, Search, Filter, ArrowUpDown, ChevronDown, 
  MoreVertical, Edit2, Trash2, Eye, Copy, Check, Calendar, 
  CheckCircle2, AlertCircle, X, Sliders, Grid, Building2
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

const router = useRouter();

// ─── Types Strictly Mapped to HR_Schema_final-v4.sql lines 1044–1064 ───
// SalaryMatrix has NO name, NO code, NO description — zero phantom fields.
export type RowState = 'active' | 'inactive';

export interface SalaryScaleListItem {
  id: number;
  uuid: string;
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  effective_from: string;
  effective_to: string | null;
  number_of_steps: number;
  currency_id: number;
  currency_code: string;
  is_default: boolean;
  grades_count: number; // derived: count of JobGrade rows linked to this matrix
  state: RowState;
}

// ─── Breadcrumbs (Clean Page Names ONLY: Rule 3.2) ───
const breadcrumbItems = [
  { label: 'Salary Scales' }
];

// ─── State Management ───
const searchQuery = ref('');
const filterEntity = ref('All');
const filterState = ref('All');
const currentSort = ref('effective_from');
const sortOrder = ref<'asc' | 'desc'>('desc');
const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const quickActionToast = ref<string | null>(null);

// ─── Table Columns (Atomic, Minimalist Default, Name-First: Rule 9) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'entity', label: 'Owning Entity', visible: true, sortable: true },
  { key: 'effective_period', label: 'Effective Timeline', visible: true, sortable: true },
  { key: 'number_of_steps', label: 'Steps', visible: true, sortable: true },
  { key: 'grades_count', label: 'Mapped Grade', visible: true, sortable: true },
  { key: 'is_default', label: 'Default', visible: false, sortable: true },
  { key: 'currency', label: 'Currency', visible: false, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

// ─── Mock Data Aligned with Image 4 & Schema Examples ───
const salaryScales = ref<SalaryScaleListItem[]>([
  {
    id: 1,
    uuid: 'sm-001',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa',
    effective_from: '2026-05-04',
    effective_to: null,
    number_of_steps: 5,
    currency_id: 1,
    currency_code: 'ETB',
    is_default: true,
    grades_count: 5,
    state: 'active'
  },
  {
    id: 2,
    uuid: 'sm-002',
    tenant_id: 1,
    entity_id: 7,
    entity_name: 'Grand Hotel',
    effective_from: '2026-05-04',
    effective_to: null,
    number_of_steps: 5,
    currency_id: 1,
    currency_code: 'ETB',
    is_default: true,
    grades_count: 2,
    state: 'active'
  },
  {
    id: 3,
    uuid: 'sm-003',
    tenant_id: 1,
    entity_id: 9,
    entity_name: 'Mola Trading',
    effective_from: '2026-05-04',
    effective_to: '2026-05-04',
    number_of_steps: 5,
    currency_id: 1,
    currency_code: 'ETB',
    is_default: false,
    grades_count: 4,
    state: 'inactive'
  }
]);

// ─── Computed: Filters & Sort ───
const activeFilterCount = computed(() => {
  let count = 0;
  if (filterEntity.value !== 'All') count++;
  if (filterState.value !== 'All') count++;
  return count;
});

const entityOptions = computed(() => {
  const entities = [...new Set(salaryScales.value.map(s => s.entity_name))];
  return ['All', ...entities];
});

const filteredScales = computed(() => {
  let list = [...salaryScales.value];

  // Search by entity name
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase();
    list = list.filter(s => s.entity_name.toLowerCase().includes(q));
  }

  // Filters
  if (filterEntity.value !== 'All') {
    list = list.filter(s => s.entity_name === filterEntity.value);
  }
  if (filterState.value !== 'All') {
    list = list.filter(s => s.state === filterState.value.toLowerCase());
  }

  // Sort
  list.sort((a, b) => {
    let valA: any, valB: any;
    switch (currentSort.value) {
      case 'entity':
        valA = a.entity_name; valB = b.entity_name; break;
      case 'effective_from':
        valA = a.effective_from; valB = b.effective_from; break;
      case 'number_of_steps':
        valA = a.number_of_steps; valB = b.number_of_steps; break;
      case 'grades_count':
        valA = a.grades_count; valB = b.grades_count; break;
      default:
        valA = a.effective_from; valB = b.effective_from;
    }
    const cmp = valA < valB ? -1 : valA > valB ? 1 : 0;
    return sortOrder.value === 'asc' ? cmp : -cmp;
  });

  return list;
});

// ─── Helpers ───
const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

const handleToggleColumn = ({ key, visible }: { key: string; visible: boolean }) => {
  const col = tableColumns.value.find(c => c.key === key);
  if (col) col.visible = visible;
};

const formatDate = (d: string) => {
  const date = new Date(d);
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
};

const toggleActionMenu = (id: number, event: Event) => {
  event.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
};

const showToast = (msg: string) => {
  quickActionToast.value = msg;
  setTimeout(() => { quickActionToast.value = null; }, 4000);
};

// ─── Row Selection ───
const isAllSelected = computed(() => {
  return filteredScales.value.length > 0 && selectedRowIds.value.length === filteredScales.value.length;
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = filteredScales.value.map(s => s.id);
  }
};

const toggleRowSelect = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx === -1) selectedRowIds.value.push(id);
  else selectedRowIds.value.splice(idx, 1);
};

// ─── Actions ───
const handleBatchDelete = () => {
  salaryScales.value = salaryScales.value.filter(s => !selectedRowIds.value.includes(s.id));
  selectedRowIds.value = [];
  showToast('Selected salary scales deleted.');
};

const handleDelete = (item: SalaryScaleListItem) => {
  salaryScales.value = salaryScales.value.filter(s => s.id !== item.id);
  closeActionMenu();
  showToast(`Deleted salary scale for ${item.entity_name}.`);
};

const handleToggleState = (item: SalaryScaleListItem) => {
  item.state = item.state === 'active' ? 'inactive' : 'active';
  closeActionMenu();
  showToast(`Updated state for ${item.entity_name} scale.`);
};

const handleViewDetails = (item: SalaryScaleListItem) => {
  closeActionMenu();
  router.push(`/hr/salary-scales/${item.id}`);
};

// ─── Quick Create Modal State & Handler (Rule 4 Standard) ───
const showQuickModal = ref(false);
const quickScaleForm = ref({
  entity_name: 'Haleta Addis Ababa',
  effective_from: '2026-05-04',
  effective_to: '',
  number_of_steps: 5,
  currency_code: 'ETB',
  is_default: false
});

const handleSaveQuickScale = () => {
  const newId = salaryScales.value.length > 0 ? Math.max(...salaryScales.value.map(s => s.id)) + 1 : 1;
  const newScale: SalaryScaleListItem = {
    id: newId,
    uuid: `sm-00${newId}`,
    tenant_id: 1,
    entity_id: 1,
    entity_name: quickScaleForm.value.entity_name,
    effective_from: quickScaleForm.value.effective_from,
    effective_to: quickScaleForm.value.effective_to || null,
    number_of_steps: Number(quickScaleForm.value.number_of_steps),
    currency_id: 1,
    currency_code: quickScaleForm.value.currency_code,
    is_default: quickScaleForm.value.is_default,
    grades_count: 0,
    state: 'active'
  };
  salaryScales.value.unshift(newScale);
  showQuickModal.value = false;
  showToast(`Salary scale created for ${newScale.entity_name}.`);
  router.push({
    path: `/hr/salary-scales/${newId}`,
    query: {
      entity: newScale.entity_name,
      effective_from: newScale.effective_from,
      effective_to: newScale.effective_to || '',
      number_of_steps: String(newScale.number_of_steps),
      currency: newScale.currency_code
    }
  });
};

onMounted(() => {
  window.addEventListener('click', closeActionMenu);
});

onUnmounted(() => {
  window.removeEventListener('click', closeActionMenu);
});
</script>

<template>
  <div class="salary-scales-page">
    <!-- Breadcrumb Bar -->
    <div class="page-breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Toast Notification Banner -->
    <div v-if="quickActionToast" class="quick-toast-banner">
      <CheckCircle2 :size="15" class="toast-icon" />
      <span>{{ quickActionToast }}</span>
    </div>

    <!-- Single Table Card (Rule 10: Unified Table Card Layout) -->
    <div class="directory-view-wrapper">
      <AppDataTable
        title="Salary Scales"
        subtitle="Manage effective-dated compensation grids, define job grade structures, step progression ladders, and salary band guardrails across enterprise entities."
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search by entity name..."
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
        <!-- Primary Action (Rule 10.2 / Rule 4) -->
        <template #actions>
          <button 
            type="button" 
            class="btn-primary-create" 
            @click="showQuickModal = true"
          >
            <Plus :size="15" />
            <span>Create Salary Scale</span>
          </button>
        </template>

        <!-- Filter Drawer Content -->
        <template #filter-panel>
          <div class="filter-grid">
            <FormSelect
              label="Owning Entity"
              v-model="filterEntity"
              :options="entityOptions"
              placeholder="Select"
            />
            <FormSelect
              label="State"
              v-model="filterState"
              :options="['All', 'Active', 'Inactive']"
              placeholder="Select"
            />
          </div>
        </template>

        <!-- Data Table (Default Slot) -->
        <table class="erp-table">
            <thead>
              <tr>
                <th class="col-check">
                  <input 
                    type="checkbox" 
                    class="table-checkbox" 
                    :checked="isAllSelected" 
                    @change="toggleSelectAll"
                  />
                </th>
                <th v-if="isColumnVisible('entity')" class="col-entity">Owning Entity</th>
                <th v-if="isColumnVisible('effective_period')" class="col-period">Effective Timeline</th>
                <th v-if="isColumnVisible('number_of_steps')" class="col-steps">Steps</th>
                <th v-if="isColumnVisible('grades_count')" class="col-grades">Mapped Grade</th>
                <th v-if="isColumnVisible('is_default')" class="col-default">Default</th>
                <th v-if="isColumnVisible('currency')" class="col-currency">Currency</th>
                <th v-if="isColumnVisible('state')" class="col-state">State</th>
                <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="item in filteredScales" 
                :key="item.id"
                :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
                @click="handleViewDetails(item)"
              >
                <td class="col-check" @click.stop>
                  <input 
                    type="checkbox" 
                    class="table-checkbox" 
                    :checked="selectedRowIds.includes(item.id)"
                    @change="toggleRowSelect(item.id)"
                  />
                </td>

                <!-- Primary Column: Entity Name (Secondary #404040, font-weight 500) -->
                <td v-if="isColumnVisible('entity')" class="col-entity">
                  <span class="table-name-primary">{{ item.entity_name }}</span>
                </td>

                <!-- Effective Timeline (Tertiary #737373) -->
                <td v-if="isColumnVisible('effective_period')" class="col-period">
                  <span class="text-tertiary">
                    {{ formatDate(item.effective_from) }} - {{ item.effective_to ? formatDate(item.effective_to) : 'Current' }}
                  </span>
                </td>

                <!-- Steps Count -->
                <td v-if="isColumnVisible('number_of_steps')" class="col-steps">
                  <span class="text-tertiary">{{ item.number_of_steps }} Steps</span>
                </td>

                <!-- Grades Count -->
                <td v-if="isColumnVisible('grades_count')" class="col-grades">
                  <span class="text-tertiary">{{ item.grades_count }} {{ item.grades_count === 1 ? 'Grade' : item.grades_count === 5 ? 'Grade' : 'Grades' }}</span>
                </td>

                <!-- Default Status -->
                <td v-if="isColumnVisible('is_default')" class="col-default">
                  <span class="text-tertiary">{{ item.is_default ? 'Yes' : 'No' }}</span>
                </td>

                <!-- Currency -->
                <td v-if="isColumnVisible('currency')" class="col-currency">
                  <span class="text-tertiary font-mono">{{ item.currency_code }}</span>
                </td>

                <!-- State (Lifecycle badge — only state gets a badge, Rule 6) -->
                <td v-if="isColumnVisible('state')" class="col-state">
                  <span class="status-pill" :class="item.state === 'active' ? 'status-pill-active' : 'status-pill-inactive'">
                    {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                  </span>
                </td>

                <!-- Actions 3-dots -->
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
                      <button type="button" class="menu-item" @click="handleViewDetails(item)">
                        <Eye :size="14" />
                        <span>View Pay Scale Grid</span>
                      </button>
                      <button type="button" class="menu-item" @click="handleViewDetails(item)">
                        <Edit2 :size="14" />
                        <span>Edit Salary Scale</span>
                      </button>
                      <button type="button" class="menu-item" @click="handleToggleState(item)">
                        <Check :size="14" />
                        <span>{{ item.state === 'active' ? 'Deactivate' : 'Activate' }}</span>
                      </button>
                      <div class="menu-divider"></div>
                      <button 
                        type="button" 
                        class="menu-item menu-item-danger"
                        @click="handleDelete(item)"
                      >
                        <Trash2 :size="14" />
                        <span>Delete Scale</span>
                      </button>
                    </div>
                  </div>
                </td>
              </tr>

              <tr v-if="filteredScales.length === 0">
                <td colspan="9" class="table-empty-row">
                  <div class="empty-state-box">
                    <p class="empty-title">No Salary Scales Found</p>
                    <p class="empty-subtitle">Adjust your search criteria or create a new salary scale.</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
      </AppDataTable>
    </div>

    <!-- Floating Batch Actions -->
    <TableFloatingBar 
      :count="selectedRowIds.length" 
      @delete="handleBatchDelete" 
    />

    <!-- Quick Create Salary Scale Modal (Rule 4 Standard: <= 5 fields) -->
    <QuickCreateModal
      v-model:show="showQuickModal"
      title="Create Salary Scale"
      expandRoute="/hr/salary-scales/create"
      @save="handleSaveQuickScale"
    >
      <div class="quick-modal-grid">
        <!-- Row 1: Owning Entity (Left) & Currency * (Right) -->
        <div class="quick-field-group">
          <label class="quick-field-label">Owning Entity</label>
          <select v-model="quickScaleForm.entity_name" class="quick-field-select">
            <option value="" disabled>Select Entity</option>
            <option value="Haleta Addis Ababa">Haleta Addis Ababa</option>
            <option value="Grand Hotel">Grand Hotel</option>
            <option value="Mola Trading">Mola Trading</option>
          </select>
        </div>

        <div class="quick-field-group">
          <label class="quick-field-label">Currency <span class="required-star">*</span></label>
          <select v-model="quickScaleForm.currency_code" class="quick-field-select">
            <option value="ETB">ETB</option>
            <option value="USD">USD</option>
            <option value="EUR">EUR</option>
            <option value="GBP">GBP</option>
          </select>
        </div>

        <!-- Row 2: Number of Steps * (Left) & Effective From * (Right) -->
        <div class="quick-field-group">
          <label class="quick-field-label">Number of Steps <span class="required-star">*</span></label>
          <input 
            type="number" 
            v-model.number="quickScaleForm.number_of_steps" 
            class="quick-field-input font-mono" 
            min="1" 
            max="50"
            required 
          />
        </div>

        <div class="quick-field-group">
          <label class="quick-field-label">Effective From <span class="required-star">*</span></label>
          <div class="quick-date-wrap">
            <Calendar :size="14" class="date-icon" />
            <input type="date" v-model="quickScaleForm.effective_from" class="quick-field-input-date" required />
            <span class="gc-pill-tag">GC</span>
          </div>
        </div>

        <!-- Row 3: Effective Until (Left) -->
        <div class="quick-field-group">
          <label class="quick-field-label">Effective Until</label>
          <div class="quick-date-wrap">
            <Calendar :size="14" class="date-icon" />
            <input type="date" v-model="quickScaleForm.effective_to" class="quick-field-input-date" />
            <span class="gc-pill-tag">GC</span>
          </div>
        </div>

        <!-- Row 4: Default Salary Scale Checkbox (Col span 2) -->
        <div class="quick-field-group col-span-2 mt-1">
          <FormCheckbox
            v-model="quickScaleForm.is_default"
            label="Default Salary Scale"
            description="Designates this compensation grid as the active pay baseline for newly attached job grades in this entity."
          />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
/* ═══════════════════════════════════════════ */
/* SALARY SCALES DIRECTORY LISTING             */
/* ═══════════════════════════════════════════ */

.salary-scales-page {
  min-height: 100vh;
  background: var(--alias-color-background-page, #f8fafc);
}

.page-breadcrumb-bar {
  padding: 18px 28px 0;
}

/* ─── Toast ─── */
.quick-toast-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 12px 28px 0;
  padding: 10px 16px;
  background: #ecfdf5;
  color: #059669;
  font-size: 13px;
  font-weight: 500;
  border-radius: 8px;
  animation: toastSlideIn 0.3s ease;
}

.toast-icon { color: #059669; flex-shrink: 0; }

@keyframes toastSlideIn {
  from { opacity: 0; transform: translateY(-6px); }
  to { opacity: 1; transform: translateY(0); }
}

/* ─── Directory Table Container ─── */
.directory-view-wrapper {
  padding: 16px 28px 28px;
}

/* ─── Filters ─── */
.filter-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
}

/* ─── Primary Create Button (Rule 6: 8-10px radius, NOT pill) ─── */
.btn-primary-create {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  background: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.15s;
  white-space: nowrap;
}

.btn-primary-create:hover {
  background: #094280;
}

/* ═══ TABLE STYLES ═══ */
.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table th {
  padding: 8px 16px;
  height: 34px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  text-align: left;
  background: #fafafa;
  white-space: nowrap;
}

.erp-table td {
  padding: 8px 16px;
  height: 38px;
  font-size: 13px;
  color: #404040;
  vertical-align: middle;
}

.erp-table tbody tr {
  cursor: pointer;
  transition: background 0.12s;
}

.erp-table tbody tr:hover {
  background: #f8fafc;
}

.erp-table tbody tr.row-selected {
  background: #f0f7ff;
}

/* ─── Cell Specifics ─── */
.col-check { width: 40px; text-align: center; }

.table-checkbox {
  width: 15px;
  height: 15px;
  accent-color: #0B529C;
  cursor: pointer;
}

/* Name Cell: Primary = Secondary Color (#404040), Subtext = Tertiary (#737373) */
.name-cell-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  line-height: 1.3;
}

.table-code-subtext {
  font-size: 11.5px;
  color: #737373;
  line-height: 1.3;
}

/* Period Cell */
.period-cell {
  display: flex;
  align-items: center;
  gap: 6px;
}

.period-separator {
  color: #a1a1aa;
  font-size: 12px;
}

.text-tertiary {
  color: #737373;
}

.font-mono { font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', monospace; }

/* ─── Status Pill (Rule 6: Badges reserved for lifecycle state) ─── */
.status-pill {
  display: inline-flex;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
  white-space: nowrap;
}

.status-pill-active {
  background: #ecfdf5;
  color: #059669;
}

.status-pill-inactive {
  background: #f1f5f9;
  color: #64748b;
}

/* ─── Actions ─── */
.btn-action-dots {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  border-radius: 6px;
  color: #737373;
  cursor: pointer;
  transition: background 0.12s;
}

.btn-action-dots:hover {
  background: #f1f5f9;
}

.action-dropdown-container {
  position: relative;
}

.action-popup-menu {
  position: absolute;
  top: 100%;
  right: 0;
  width: 200px;
  background: #ffffff;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.1), 0 1px 3px rgba(0,0,0,0.06);
  z-index: 50;
  padding: 4px 0;
  animation: menuPop 0.14s ease;
}

@keyframes menuPop {
  from { opacity: 0; transform: translateY(-4px); }
  to { opacity: 1; transform: translateY(0); }
}

.menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 7px 14px;
  background: none;
  border: none;
  font-size: 13px;
  color: #404040;
  cursor: pointer;
  text-align: left;
  transition: background 0.1s;
}

.menu-item:hover { background: #f8fafc; }

.menu-item-danger { color: #e11d48; }
.menu-item-danger:hover { background: #fff1f2; }

.menu-divider {
  height: 1px;
  background: #f1f5f9;
  margin: 4px 0;
}

/* ─── Empty State ─── */
.table-empty-row {
  text-align: center;
  padding: 48px 16px !important;
}

.empty-state-box { display: flex; flex-direction: column; align-items: center; gap: 4px; }

.empty-title {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
}

.empty-subtitle {
  font-size: 12.5px;
  color: #737373;
}

/* ─── Quick Create Modal Styles (Rule 4 Standard) ─── */
.quick-modal-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px 16px;
  padding: 8px 4px 12px;
}

.quick-field-group {
  display: flex;
  flex-direction: column;
}

.col-span-2 {
  grid-column: span 2;
}

.mt-1 {
  margin-top: 4px;
}

.quick-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 4px;
}

.required-star {
  color: #e11d48;
}

.quick-field-input,
.quick-field-select {
  height: 38px;
  padding: 0 12px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
  transition: all 0.15s ease;
  width: 100%;
}
.quick-field-select {
  cursor: pointer;
}
.quick-field-input:focus,
.quick-field-select:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.quick-date-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.date-icon {
  position: absolute;
  left: 10px;
  color: #64748b;
  pointer-events: none;
}

.quick-field-input-date {
  width: 100%;
  height: 38px;
  padding: 0 40px 0 32px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
  transition: all 0.15s ease;
}
.quick-field-input-date:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.gc-pill-tag {
  position: absolute;
  right: 8px;
  padding: 2px 6px;
  background: #e0f2fe;
  color: #0284c7;
  font-size: 10px;
  font-weight: 600;
  border-radius: 4px;
  letter-spacing: 0.5px;
}

.quick-readonly-pill {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 38px;
  padding: 0 12px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}
</style>
