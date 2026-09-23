<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Plus, Search, Filter, ArrowUpDown, ChevronDown, 
  MoreVertical, Edit2, Trash2, Eye, Copy, Check, Calendar, 
  CheckCircle2, AlertCircle, X, Layers, ChevronRight, Award,
  Briefcase
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

const router = useRouter();

// ─── Lookups & Types (HR_Schema_final-v4.sql lines 1132–1150) ───
export type RowState = 'active' | 'inactive';
export type GovernanceStatus = 'pending' | 'acceptForAll' | 'acceptForThis' | 'reject';

export interface JobLevelRecord {
  id: number;
  uuid: string;
  code: string;
  name: string;
  description: string;
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  status: GovernanceStatus;
  status_label: string;
  positions_count: number;
  sample_titles: string[];
  state: RowState;
}

// ─── Breadcrumbs ───
const breadcrumbItems = [
  { label: 'Job Architecture', to: '/hr/job-positions' },
  { label: 'Job Levels', current: true }
];

// ─── State Management ───
const searchQuery = ref('');
const filterStatus = ref('All');
const filterState = ref('All');
const currentSort = ref('name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const showQuickCreate = ref(false);
const quickActionToast = ref<string | null>(null);

// ─── Table Columns (Strict Single-Information & Name-First Hierarchy: Rule 9) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Level Name & Code', visible: true, sortable: true },
  { key: 'description', label: 'Scope & Autonomy', visible: true, sortable: false },
  { key: 'entity', label: 'Owning Entity', visible: false, sortable: true },
  { key: 'positions_count', label: 'Attached Positions', visible: true, sortable: true },
  { key: 'status', label: 'Status', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

// ─── Mock Data Aligned with HR_Schema_final-v4.sql lines 1144–1150 ───
const jobLevels = ref<JobLevelRecord[]>([
  {
    id: 1,
    uuid: 'lvl-uuid-001',
    code: 'LVL-JR',
    name: 'Junior',
    description: 'Entry-level professionals operating under direct supervision. Focuses on foundational skill building and task execution.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'QMT Business Group',
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    positions_count: 8,
    sample_titles: ['Junior Accountant', 'Junior Developer', 'Office Assistant'],
    state: 'active'
  },
  {
    id: 2,
    uuid: 'lvl-uuid-002',
    code: 'LVL-OFF',
    name: 'Officer',
    description: 'Independent contributor with operational mastery. Executes routine tasks, standard analyses, and business transactions autonomously.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'QMT Business Group',
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    positions_count: 14,
    sample_titles: ['HR Officer', 'Procurement Officer', 'Cashier'],
    state: 'active'
  },
  {
    id: 3,
    uuid: 'lvl-uuid-003',
    code: 'LVL-SR',
    name: 'Senior',
    description: 'Advanced specialist possessing deep domain knowledge. Handles complex problem solving, audits, and coaches junior staff.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'QMT Business Group',
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    positions_count: 11,
    sample_titles: ['Senior Financial Accountant', 'Senior Cashier', 'Senior Systems Analyst'],
    state: 'active'
  },
  {
    id: 4,
    uuid: 'lvl-uuid-004',
    code: 'LVL-LEAD',
    name: 'Lead',
    description: 'Principal technical or team lead responsible for sprint delivery, workflow standards, quality review, and mentorship.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'QMT Business Group',
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    positions_count: 6,
    sample_titles: ['Lead Architect', 'Payroll Lead', 'Operations Lead'],
    state: 'active'
  },
  {
    id: 5,
    uuid: 'lvl-uuid-005',
    code: 'LVL-MGR',
    name: 'Manager',
    description: 'Operational and tactical head responsible for departmental budget, performance management, resource planning, and approvals.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'QMT Business Group',
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    positions_count: 4,
    sample_titles: ['Finance Manager', 'HR Manager', 'Branch Manager'],
    state: 'active'
  },
  {
    id: 6,
    uuid: 'lvl-uuid-006',
    code: 'LVL-DIR',
    name: 'Director',
    description: 'Executive leadership level driving long-term enterprise strategy, organizational transformation, and board-level reporting.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'QMT Business Group',
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    positions_count: 2,
    sample_titles: ['Director of Operations', 'Director of Human Capital'],
    state: 'active'
  }
]);

// ─── Filter & Sorting Computations ───
const filteredLevels = computed(() => {
  return jobLevels.value.filter(level => {
    // Search filter
    const matchesSearch = !searchQuery.value || 
      level.name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      level.code.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      level.description.toLowerCase().includes(searchQuery.value.toLowerCase());

    // Governance status filter
    const matchesStatus = filterStatus.value === 'All' || level.status === filterStatus.value;

    // State filter
    const matchesState = filterState.value === 'All' || level.state === filterState.value;

    return matchesSearch && matchesStatus && matchesState;
  }).sort((a, b) => {
    let valA: any = a[currentSort.value as keyof JobLevelRecord];
    let valB: any = b[currentSort.value as keyof JobLevelRecord];

    if (typeof valA === 'string') {
      valA = valA.toLowerCase();
      valB = (valB as string).toLowerCase();
    }

    if (valA < valB) return sortOrder.value === 'asc' ? -1 : 1;
    if (valA > valB) return sortOrder.value === 'asc' ? 1 : -1;
    return 0;
  });
});

// Selection Helpers
const isAllSelected = computed(() => {
  return filteredLevels.value.length > 0 && 
    filteredLevels.value.every(row => selectedRowIds.value.includes(row.id));
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = filteredLevels.value.map(r => r.id);
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

const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible : true;
};

const handleToggleColumn = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  if (col) col.visible = !col.visible;
};

// ─── Quick Create Modal State (< 5 Required Fields Flow: Rule 4) ───
const quickForm = ref({
  name: '',
  entity_id: 1,
  status: 'acceptForAll' as GovernanceStatus,
  description: ''
});

const entityOptions = [
  { value: 1, label: 'QMT Business Group' },
  { value: 3, label: 'Haleta Addis Ababa HQ' },
  { value: 7, label: 'Haleta Grand Hotel & Suites' },
  { value: 9, label: 'Haleta East Regional Office' }
];

const showToast = (message: string) => {
  quickActionToast.value = message;
  setTimeout(() => { quickActionToast.value = null; }, 3500);
};

const handleSaveQuickCreate = () => {
  if (!quickForm.value.name.trim()) {
    alert('Please provide a Level Name.');
    return;
  }

  // Derive human-readable code automatically (Rule 16: Zero manual code inputs)
  const cleanName = quickForm.value.name.trim().toUpperCase();
  const derivedCode = 'LVL-' + cleanName.substring(0, 4).replace(/[^A-Z]/g, '');

  const selectedEntity = entityOptions.find(e => e.value === quickForm.value.entity_id);

  const statusMap: Record<GovernanceStatus, string> = {
    acceptForAll: 'Approved for All Entities',
    acceptForThis: 'Approved for This Entity Only',
    pending: 'Pending Approval',
    reject: 'Rejected'
  };

  const newId = Date.now();
  jobLevels.value.unshift({
    id: newId,
    uuid: `lvl-uuid-${newId}`,
    code: derivedCode,
    name: quickForm.value.name.trim(),
    description: quickForm.value.description.trim() || 'Standard enterprise career progression level.',
    tenant_id: 1,
    entity_id: quickForm.value.entity_id,
    entity_name: selectedEntity ? selectedEntity.label : 'QMT Business Group',
    status: quickForm.value.status,
    status_label: statusMap[quickForm.value.status],
    positions_count: 0,
    sample_titles: [],
    state: 'active'
  });

  // Reset form
  quickForm.value = {
    name: '',
    entity_id: 1,
    status: 'acceptForAll',
    description: ''
  };

  showQuickCreate.value = false;
  showToast(`Career Level "${cleanName}" created successfully.`);
};

// Actions Menu Helpers
const toggleActionMenu = (id: number) => {
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
};

const handleToggleState = (level: JobLevelRecord) => {
  level.state = level.state === 'active' ? 'inactive' : 'active';
  showToast(`Career Level "${level.name}" is now ${level.state}.`);
  closeActionMenu();
};

const handleDuplicate = (level: JobLevelRecord) => {
  const newId = Date.now();
  jobLevels.value.push({
    ...level,
    id: newId,
    uuid: `lvl-uuid-${newId}`,
    code: `${level.code}-CPY`,
    name: `${level.name} (Copy)`,
    positions_count: 0,
    state: 'active'
  });
  showToast(`Duplicated level as "${level.name} (Copy)".`);
  closeActionMenu();
};

const handleDelete = (id: number) => {
  jobLevels.value = jobLevels.value.filter(l => l.id !== id);
  selectedRowIds.value = selectedRowIds.value.filter(i => i !== id);
  showToast('Career level deleted successfully.');
  closeActionMenu();
};

const handleBatchDelete = () => {
  jobLevels.value = jobLevels.value.filter(l => !selectedRowIds.value.includes(l.id));
  showToast(`Deleted ${selectedRowIds.value.length} selected levels.`);
  selectedRowIds.value = [];
};

// Global click listener to close dropdowns
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
  <div class="job-levels-page">
    <!-- ═══ BREADCRUMB NAVIGATION (Rule 3) ═══ -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ═══ TOAST BANNER NOTIFICATION ═══ -->
    <div v-if="quickActionToast" class="quick-toast-banner">
      <CheckCircle2 :size="15" class="toast-icon" />
      <span>{{ quickActionToast }}</span>
    </div>

    <!-- ═══ UNIFIED TABLE CARD: <AppDataTable /> (Rule 10.1 & Rule 9) ═══ -->
    <AppDataTable
      title="Job Levels"
      subtitle="Standardized seniority tiers, career advancement ladder, and autonomy definitions across enterprise positions."
      :columns="tableColumns"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Toolbar Filter Controls -->
      <template #filters>
        <!-- Search Input -->
        <div class="filter-search-box">
          <Search :size="14" class="search-icon" />
          <input 
            type="text" 
            v-model="searchQuery" 
            placeholder="Search level or code..." 
            class="filter-search-input"
          />
          <button v-if="searchQuery" @click="searchQuery = ''" class="search-clear-btn">
            <X :size="12" />
          </button>
        </div>

        <!-- Status Filter -->
        <div class="filter-select-box">
          <label class="filter-label">Status:</label>
          <select v-model="filterStatus" class="filter-select">
            <option value="All">All Statuses</option>
            <option value="acceptForAll">Approved for All</option>
            <option value="acceptForThis">Entity Specific</option>
            <option value="pending">Pending Approval</option>
          </select>
        </div>

        <!-- Lifecycle State Filter -->
        <div class="filter-select-box">
          <label class="filter-label">State:</label>
          <select v-model="filterState" class="filter-select">
            <option value="All">All States</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>
      </template>

      <!-- Toolbar Actions Slot: Primary Create Action (Rule 10.2) -->
      <template #actions>
        <button 
          type="button" 
          class="btn-primary-create" 
          @click="showQuickCreate = true"
        >
          <Plus :size="14" />
          <span>Create Job Level</span>
        </button>
      </template>

      <!-- Table Body Slot -->
      <div class="table-container">
        <table class="erp-table">
          <thead>
            <tr>
              <!-- Checkbox Select All -->
              <th class="col-checkbox">
                <input 
                  type="checkbox" 
                  :checked="isAllSelected" 
                  @change="toggleSelectAll" 
                  class="table-checkbox" 
                />
              </th>

              <!-- Name & Code Header (Secondary text column: Rule 9.4 & 9.5) -->
              <th v-if="isColumnVisible('name')" class="col-name">Level Name</th>
              <th v-if="isColumnVisible('description')" class="col-desc">Scope &amp; Autonomy</th>
              <th v-if="isColumnVisible('entity')" class="col-entity">Owning Entity</th>
              <th v-if="isColumnVisible('positions_count')" class="col-count">Attached Positions</th>
              <th v-if="isColumnVisible('status')" class="col-status">Status</th>
              <th v-if="isColumnVisible('state')" class="col-state">State</th>
              <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <!-- Empty State -->
            <tr v-if="filteredLevels.length === 0">
              <td colspan="7" class="table-empty-row">
                <div class="empty-state-content">
                  <Award :size="32" class="empty-icon" />
                  <p class="empty-title">No Job Levels Found</p>
                  <p class="empty-subtitle">Adjust your search filters or create a new standardized seniority level.</p>
                  <button type="button" class="btn-primary-empty" @click="showQuickCreate = true">
                    <Plus :size="14" />
                    <span>Create Level</span>
                  </button>
                </div>
              </td>
            </tr>

            <!-- Table Rows -->
            <tr 
              v-for="item in filteredLevels" 
              :key="item.id" 
              class="table-row" 
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
            >
              <!-- Row Selection Checkbox -->
              <td class="col-checkbox">
                <input 
                  type="checkbox" 
                  :checked="selectedRowIds.includes(item.id)" 
                  @change="toggleSelectRow(item.id)" 
                  class="table-checkbox" 
                />
              </td>

              <!-- Level Name (Secondary Color #404040) + Code Subtext (Rule 9.4 & 9.5) -->
              <td v-if="isColumnVisible('name')" class="col-name">
                <div class="level-name-cell">
                  <span class="table-name-primary">{{ item.name }}</span>
                  <span class="table-code-subtext font-mono">{{ item.code }}</span>
                </div>
              </td>

              <!-- Scope & Autonomy Description (Tertiary Color #737373) -->
              <td v-if="isColumnVisible('description')" class="col-desc">
                <span class="text-tertiary truncate-desc" :title="item.description">
                  {{ item.description }}
                </span>
              </td>

              <!-- Owning Entity (Tertiary Color #737373) -->
              <td v-if="isColumnVisible('entity')" class="col-entity">
                <span class="text-tertiary">{{ item.entity_name }}</span>
              </td>

              <!-- Attached Positions Count (Rule 9.6: Strict Anti-Badge Plain Text) -->
              <td v-if="isColumnVisible('positions_count')" class="col-count">
                <span class="text-tertiary">{{ item.positions_count }} Positions</span>
              </td>

              <!-- Status Badge Pill -->
              <td v-if="isColumnVisible('status')" class="col-status">
                <span 
                  class="status-pill"
                  :class="{
                    'status-pill-approved': item.status === 'acceptForAll',
                    'status-pill-entity': item.status === 'acceptForThis',
                    'status-pill-pending': item.status === 'pending',
                    'status-pill-rejected': item.status === 'rejected'
                  }"
                >
                  {{ item.status_label }}
                </span>
              </td>

              <!-- Lifecycle State (Rule 9.6: Badges reserved for lifecycle state) -->
              <td v-if="isColumnVisible('state')" class="col-state">
                <span 
                  class="status-pill" 
                  :class="item.state === 'active' ? 'status-pill-active' : 'status-pill-inactive'"
                >
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </span>
              </td>

              <!-- Actions 3-Dots Dropdown -->
              <td v-if="isColumnVisible('actions')" class="col-actions">
                <div class="action-menu-container">
                  <button 
                    type="button" 
                    class="btn-action-dots" 
                    @click.stop="toggleActionMenu(item.id)" 
                    aria-label="Actions"
                  >
                    <MoreVertical :size="14" />
                  </button>

                  <!-- Floating Action Dropdown Menu -->
                  <div 
                    v-if="activeActionMenuId === item.id" 
                    class="action-dropdown-popup" 
                    @click.stop
                  >
                    <button 
                      type="button" 
                      class="dropdown-item" 
                      @click="router.push('/hr/job-positions')"
                    >
                      <Briefcase :size="13" />
                      <span>View Attached Positions</span>
                    </button>
                    <button 
                      type="button" 
                      class="dropdown-item" 
                      @click="handleDuplicate(item)"
                    >
                      <Copy :size="13" />
                      <span>Duplicate Level</span>
                    </button>
                    <button 
                      type="button" 
                      class="dropdown-item" 
                      @click="handleToggleState(item)"
                    >
                      <Check :size="13" />
                      <span>{{ item.state === 'active' ? 'Mark Inactive' : 'Activate Level' }}</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button 
                      type="button" 
                      class="dropdown-item dropdown-item-danger" 
                      @click="handleDelete(item.id)"
                    >
                      <Trash2 :size="13" />
                      <span>Delete Level</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </AppDataTable>

    <!-- ═══ FLOATING BATCH ACTION BAR (Rule 11.3) ═══ -->
    <TableFloatingBar 
      v-if="selectedRowIds.length > 0" 
      :count="selectedRowIds.length" 
      @delete="handleBatchDelete" 
    />

    <!-- ═══ QUICK CREATE MODAL (<= 5 Required Fields Flow: Rule 4) ═══ -->
    <QuickCreateModal
      v-model:show="showQuickCreate"
      title="Create Job Level"
      :showExpandButton="false"
      @save="handleSaveQuickCreate"
    >
      <div class="quick-modal-grid">
        <!-- Level Name Input (Rule 5: Zero Placeholder) -->
        <div class="form-row">
          <FormInput
            label="Level Name"
            v-model="quickForm.name"
            required
          />
        </div>

        <!-- Governance Approval Scope (FK status_lookup_value_id Schema line 1140) -->
        <div class="form-row">
          <FormSelect
            label="Governance Approval Scope"
            v-model="quickForm.status"
            :options="[
              { label: 'Approved for All Entities (acceptForAll)', value: 'acceptForAll' },
              { label: 'Approved for This Entity Only (acceptForThis)', value: 'acceptForThis' }
            ]"
            placeholder="Select"
            required
          />
        </div>

        <!-- Owning Entity Dropdown -->
        <div class="form-row">
          <FormSelect
            label="Owning Entity"
            v-model="quickForm.entity_id"
            :options="entityOptions"
            required
          />
        </div>

        <!-- Description (Scope of Autonomy) -->
        <div class="form-row">
          <FormTextarea
            label="Scope of Autonomy &amp; Seniority"
            v-model="quickForm.description"
            rows="3"
          />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
/* ═══════════════════════════════════════════ */
/* JOB LEVELS DIRECTORY VIEW                   */
/* ═══════════════════════════════════════════ */

.job-levels-page {
  min-height: 100vh;
  padding: 24px 28px 60px;
  background-color: #f8fafc;
}

.breadcrumb-container {
  margin-bottom: 20px;
}

/* ═══ TOAST NOTIFICATION BANNER ═══ */
.quick-toast-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  margin-bottom: 16px;
  background-color: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  color: #065f46;
  font-size: 13px;
  animation: fadeIn 0.2s ease;
}
.toast-icon { color: #059669; }

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-4px); }
  to { opacity: 1; transform: translateY(0); }
}

/* ═══ TOOLBAR FILTERS & ACTIONS ═══ */
.filter-search-box {
  position: relative;
  display: flex;
  align-items: center;
}

.search-icon {
  position: absolute;
  left: 10px;
  color: #94a3b8;
  pointer-events: none;
}

.filter-search-input {
  height: 38px;
  padding: 0 30px 0 32px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  background: #ffffff;
  outline: none;
  width: 220px;
  transition: all 0.15s ease;
}
.filter-search-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.search-clear-btn {
  position: absolute;
  right: 8px;
  border: none;
  background: transparent;
  color: #94a3b8;
  cursor: pointer;
  padding: 2px;
}

.filter-select-box {
  display: flex;
  align-items: center;
  gap: 6px;
}

.filter-label {
  font-size: 12px;
  color: #737373;
  font-weight: 500;
}

.filter-select {
  height: 38px;
  padding: 0 28px 0 10px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  color: #404040;
  background: #ffffff;
  outline: none;
  cursor: pointer;
  transition: border-color 0.15s ease;
}
.filter-select:focus {
  border-color: #0B529C;
}

/* Primary Create Button (Rule 6: Well-Rounded Rectangle 8px) */
.btn-primary-create {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(11, 82, 156, 0.2);
  transition: background-color 0.15s ease;
}
.btn-primary-create:hover {
  background-color: #083b70;
}

/* ═══ TABLE STYLING (Rule 8 & Rule 9) ═══ */
.table-container {
  overflow-x: auto;
  background: #ffffff;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  background-color: #fafafa;
  color: #737373;
  font-size: 12px;
  font-weight: 600;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
}

.erp-table td {
  height: 44px;
  padding: 8px 16px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.table-row:hover {
  background-color: #f8fafc;
}

.table-row.row-selected {
  background-color: #f0f7ff;
}

.col-checkbox {
  width: 40px;
  text-align: center;
}

.table-checkbox {
  width: 15px;
  height: 15px;
  cursor: pointer;
  accent-color: #0B529C;
}

/* Level Name Cell (Rule 9.4: Name Primary, Code Subtext) */
.level-name-cell {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 600;
  color: #404040; /* Rule 7 & 9.5: Secondary dark color */
}

.table-code-subtext {
  font-size: 11px;
  color: #737373; /* Rule 9.4: Tertiary subtext */
}

/* All Right Columns Strictly Tertiary Color (Rule 9.5) */
.text-tertiary {
  color: #737373;
  font-size: 12.5px;
}

.truncate-desc {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
  max-width: 320px;
}

/* Status Pills (Rule 9.6: Badges reserved for lifecycle status) */
.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  font-size: 11.5px;
  font-weight: 500;
  border-radius: 9999px;
}
.status-pill-active,
.status-pill-approved {
  background-color: #ecfdf5;
  color: #059669;
}

.status-pill-entity {
  background-color: #eff6ff;
  color: #1d4ed8;
}

.status-pill-pending {
  background-color: #fefce8;
  color: #a16207;
}

.status-pill-rejected {
  background-color: #fef2f2;
  color: #dc2626;
}

.status-pill-inactive {
  background-color: #f1f5f9;
  color: #64748b;
}

/* 3-Dots Action Button & Dropdown */
.col-actions {
  width: 50px;
  text-align: center;
}

.action-menu-container {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border: 1px solid transparent;
  background: transparent;
  color: #64748b;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-action-dots:hover {
  background-color: #f1f5f9;
  border-color: #e2e8f0;
  color: #404040;
}

.action-dropdown-popup {
  position: absolute;
  top: 100%;
  right: 0;
  z-index: 50;
  min-width: 190px;
  margin-top: 4px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  padding: 4px;
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 7px 10px;
  font-size: 12.5px;
  color: #404040;
  background: transparent;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.12s ease;
}
.dropdown-item:hover {
  background-color: #f1f5f9;
}

.dropdown-item-danger {
  color: #ef4444;
}
.dropdown-item-danger:hover {
  background-color: #fef2f2;
}

.dropdown-divider {
  height: 1px;
  background-color: #e2e8f0;
  margin: 4px 0;
}

/* Empty State */
.table-empty-row {
  padding: 48px 16px;
  text-align: center;
}

.empty-state-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.empty-icon {
  color: #cbd5e1;
}

.empty-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.empty-subtitle {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

.btn-primary-empty {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin-top: 8px;
  height: 34px;
  padding: 0 14px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
}

/* Quick Create Modal Grid */
.quick-modal-grid {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-row {
  display: flex;
  flex-direction: column;
}
</style>
