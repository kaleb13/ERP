<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import {
  GraduationCap, Plus, Search, Filter,
  MoreVertical, Edit2, Trash2, Eye,
  Copy, Check, CheckCircle2, X
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

const router = useRouter();

// ─── Lookups & Types (HR Schema Designer 1.sql lines 220–238) ───
export type RowState = 'active' | 'inactive';
export type GovernanceStatus = 'pending' | 'acceptForAll' | 'acceptForThis' | 'reject';

export interface FieldOfStudyRecord {
  id: number;
  uuid: string;
  code: string;
  name: string;
  parent_id?: number | null;
  parent_name?: string | null;
  tenant_id: number;
  entity_id?: number | null;
  entity_name: string;
  is_system: boolean;
  status: GovernanceStatus;
  status_label: string;
  state: RowState;
}

// ─── Breadcrumbs (Rule: Exact Page Name from Sidebar Only, Zero Section Titles) ───
const breadcrumbItems = [
  { label: 'Fields of Study' }
];

// ─── State Management ───
const searchQuery = ref('');
const filterParent = ref('All');
const filterStatus = ref('All');
const filterState = ref('All');
const currentSort = ref('name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const showQuickCreate = ref(false);
const editingFieldId = ref<number | null>(null);
const inspectingField = ref<FieldOfStudyRecord | null>(null);
const quickActionToast = ref<string | null>(null);

// ─── Table Columns (Strict Schema Alignment & Name-First Hierarchy: Rule 9 & Rule 14) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Field of Study Name', visible: true, sortable: true },
  { key: 'parent', label: 'Parent Discipline', visible: true, sortable: true },
  { key: 'entity', label: 'Owning Entity', visible: true, sortable: true },
  { key: 'status', label: 'Governance Status', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

// ─── Mock Data Aligned 100% with HR Schema Designer 1.sql lines 230–238 ───
const fieldsOfStudy = ref<FieldOfStudyRecord[]>([
  {
    id: 1,
    uuid: 'fos-uuid-001',
    code: 'BUSINESS',
    name: 'Business Administration',
    parent_id: null,
    parent_name: null,
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 3,
    uuid: 'fos-uuid-003',
    code: 'ACCOUNTING',
    name: 'Accounting',
    parent_id: 1,
    parent_name: 'Business Administration',
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 7,
    uuid: 'fos-uuid-007',
    code: 'FINANCE',
    name: 'Finance',
    parent_id: 1,
    parent_name: 'Business Administration',
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 9,
    uuid: 'fos-uuid-009',
    code: 'HRM',
    name: 'Human Resource Management',
    parent_id: 1,
    parent_name: 'Business Administration',
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 15,
    uuid: 'fos-uuid-015',
    code: 'SUPPLY_CHAIN',
    name: 'Supply Chain Management',
    parent_id: 1,
    parent_name: 'Business Administration',
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 2,
    uuid: 'fos-uuid-002',
    code: 'ENGINEERING',
    name: 'Engineering & Technology',
    parent_id: null,
    parent_name: null,
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 18,
    uuid: 'fos-uuid-018',
    code: 'SOFTWARE_ENGINEERING',
    name: 'Software Engineering',
    parent_id: 2,
    parent_name: 'Engineering & Technology',
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 21,
    uuid: 'fos-uuid-021',
    code: 'CIVIL_ENG',
    name: 'Civil Engineering',
    parent_id: 2,
    parent_name: 'Engineering & Technology',
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 25,
    uuid: 'fos-uuid-025',
    code: 'ELECTRICAL_ENG',
    name: 'Electrical Engineering',
    parent_id: 2,
    parent_name: 'Engineering & Technology',
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 12,
    uuid: 'fos-uuid-012',
    code: 'MARKETING',
    name: 'Marketing Management',
    parent_id: 1,
    parent_name: 'Business Administration',
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  }
]);

// ─── Filter & Dropdown Options ───
const parentDisciplineOptions = computed(() => {
  const topLevels = fieldsOfStudy.value.filter(f => !f.parent_id);
  return topLevels.map(t => ({
    value: t.id,
    label: t.name
  }));
});

const governanceStatusOptions = [
  { value: 'acceptForAll', label: 'Approved for All Entities (acceptForAll)' },
  { value: 'acceptForThis', label: 'Approved for This Entity Only (acceptForThis)' },
  { value: 'pending', label: 'Pending Verification (pending)' },
  { value: 'reject', label: 'Rejected (reject)' }
];

const entityOptions = [
  { value: 0, label: 'Platform Standard (All Entities)' },
  { value: 1, label: 'QMT Business Group' },
  { value: 3, label: 'Haleta Addis Ababa HQ' },
  { value: 7, label: 'Haleta Grand Hotel & Suites' },
  { value: 9, label: 'Haleta East Regional Office' }
];

// ─── Computed Filtered Records ───
const filteredFields = computed(() => {
  let result = [...fieldsOfStudy.value];

  // Search filter (name or code)
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.trim().toLowerCase();
    result = result.filter(f => 
      f.name.toLowerCase().includes(q) ||
      f.code.toLowerCase().includes(q) ||
      (f.parent_name && f.parent_name.toLowerCase().includes(q))
    );
  }

  // Parent Discipline filter
  if (filterParent.value !== 'All') {
    if (filterParent.value === 'root') {
      result = result.filter(f => !f.parent_id);
    } else {
      result = result.filter(f => f.parent_id === Number(filterParent.value));
    }
  }

  // Governance status filter
  if (filterStatus.value !== 'All') {
    result = result.filter(f => f.status === filterStatus.value);
  }

  // State filter
  if (filterState.value !== 'All') {
    result = result.filter(f => f.state === filterState.value);
  }

  // Sorting
  result.sort((a, b) => {
    let aVal: any = a[currentSort.value as keyof FieldOfStudyRecord] ?? '';
    let bVal: any = b[currentSort.value as keyof FieldOfStudyRecord] ?? '';

    if (typeof aVal === 'string') {
      aVal = aVal.toLowerCase();
      bVal = (bVal as string).toLowerCase();
    }

    if (aVal < bVal) return sortOrder.value === 'asc' ? -1 : 1;
    if (aVal > bVal) return sortOrder.value === 'asc' ? 1 : -1;
    return 0;
  });

  return result;
});

// Selection helpers
const isAllSelected = computed(() => {
  return filteredFields.value.length > 0 && selectedRowIds.value.length === filteredFields.value.length;
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = filteredFields.value.map(r => r.id);
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
  return col ? col.visible !== false : true;
};

const handleToggleColumn = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  if (col) col.visible = !col.visible;
};

// ─── Quick Create / Edit Form State (<= 5 Required Fields Flow: Rule 4) ───
const quickForm = ref({
  name: '',
  parent_id: null as number | null,
  custom_code: '',
  entity_id: 0,
  status: 'acceptForAll' as GovernanceStatus
});

const showToast = (message: string) => {
  quickActionToast.value = message;
  setTimeout(() => { quickActionToast.value = null; }, 3500);
};

const openCreateModal = () => {
  editingFieldId.value = null;
  quickForm.value = {
    name: '',
    parent_id: null,
    custom_code: '',
    entity_id: 0,
    status: 'acceptForAll'
  };
  showQuickCreate.value = true;
};

const openEditModal = (field: FieldOfStudyRecord) => {
  editingFieldId.value = field.id;
  quickForm.value = {
    name: field.name,
    parent_id: field.parent_id || null,
    custom_code: field.code,
    entity_id: field.entity_id || 0,
    status: field.status
  };
  showQuickCreate.value = true;
  closeActionMenu();
};

const handleSaveQuickCreate = () => {
  if (!quickForm.value.name.trim()) {
    alert('Please enter a Field of Study name.');
    return;
  }

  const parentObj = fieldsOfStudy.value.find(f => f.id === quickForm.value.parent_id);
  const statusObj = governanceStatusOptions.find(s => s.value === quickForm.value.status);
  const entityObj = entityOptions.find(e => e.value === quickForm.value.entity_id);

  // Derive human-readable code automatically if omitted
  let finalCode = quickForm.value.custom_code.trim().toUpperCase();
  if (!finalCode) {
    finalCode = quickForm.value.name.trim().toUpperCase().replace(/[^A-Z0-9]/g, '_');
  }

  if (editingFieldId.value) {
    // Edit existing record
    const target = fieldsOfStudy.value.find(f => f.id === editingFieldId.value);
    if (target) {
      target.name = quickForm.value.name.trim();
      target.parent_id = quickForm.value.parent_id;
      target.parent_name = parentObj ? parentObj.name : null;
      target.code = finalCode;
      target.entity_id = quickForm.value.entity_id === 0 ? null : quickForm.value.entity_id;
      target.entity_name = entityObj ? entityObj.label : 'Platform Standard';
      target.status = quickForm.value.status;
      target.status_label = statusObj ? statusObj.label : 'Approved for All Entities';
      showToast(`Field of Study "${target.name}" updated successfully.`);
    }
  } else {
    // Insert new record
    const newId = Date.now();
    fieldsOfStudy.value.unshift({
      id: newId,
      uuid: `fos-uuid-${newId}`,
      code: finalCode,
      name: quickForm.value.name.trim(),
      parent_id: quickForm.value.parent_id,
      parent_name: parentObj ? parentObj.name : null,
      tenant_id: 1,
      entity_id: quickForm.value.entity_id === 0 ? null : quickForm.value.entity_id,
      entity_name: entityObj ? entityObj.label : 'Platform Standard',
      is_system: false,
      status: quickForm.value.status,
      status_label: statusObj ? statusObj.label : 'Approved for All Entities',
      state: 'active'
    });
    showToast(`Field of Study "${quickForm.value.name.trim()}" created successfully.`);
  }

  showQuickCreate.value = false;
  editingFieldId.value = null;
};

// ─── Actions Menu Handlers ───
const toggleActionMenu = (id: number) => {
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
};

const handleInspect = (field: FieldOfStudyRecord) => {
  inspectingField.value = field;
  closeActionMenu();
};

const handleToggleState = (field: FieldOfStudyRecord) => {
  field.state = field.state === 'active' ? 'inactive' : 'active';
  showToast(`Field of Study "${field.name}" is now ${field.state}.`);
  closeActionMenu();
};

const handleDuplicate = (field: FieldOfStudyRecord) => {
  const newId = Date.now();
  fieldsOfStudy.value.push({
    ...field,
    id: newId,
    uuid: `fos-uuid-${newId}`,
    code: `${field.code}_COPY`,
    name: `${field.name} (Copy)`,
    is_system: false,
    state: 'active'
  });
  showToast(`Duplicated discipline as "${field.name} (Copy)".`);
  closeActionMenu();
};

const handleDelete = (id: number) => {
  fieldsOfStudy.value = fieldsOfStudy.value.filter(f => f.id !== id);
  selectedRowIds.value = selectedRowIds.value.filter(i => i !== id);
  showToast('Field of study deleted successfully.');
  closeActionMenu();
};

const handleBatchDelete = () => {
  fieldsOfStudy.value = fieldsOfStudy.value.filter(f => !selectedRowIds.value.includes(f.id));
  showToast(`Deleted ${selectedRowIds.value.length} selected fields of study.`);
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
  <div class="fields-of-study-page">
    <!-- ═══ BREADCRUMB NAVIGATION (Rule 3: Exact Sidebar Page Name Only) ═══ -->
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
      title="Fields of Study"
      subtitle="Shared academic disciplines and specialization hierarchy for qualification requirements, staffing, and candidate matching."
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
            placeholder="Search field of study or code..." 
            class="filter-search-input"
          />
          <button v-if="searchQuery" @click="searchQuery = ''" class="search-clear-btn" aria-label="Clear search">
            <X :size="12" />
          </button>
        </div>

        <!-- Parent Hierarchy Filter -->
        <div class="filter-select-box">
          <FormSelect
            v-model="filterParent"
            label="Discipline Hierarchy:"
            :options="[
              { value: 'All', label: 'All Disciplines' },
              { value: 'root', label: 'Root / Top-Level Only' },
              ...parentDisciplineOptions
            ]"
            placeholder="Select Discipline"
          />
        </div>

        <!-- Governance Status Filter -->
        <div class="filter-select-box">
          <FormSelect
            v-model="filterStatus"
            label="Status:"
            :options="[
              { value: 'All', label: 'All Statuses' },
              { value: 'acceptForAll', label: 'Approved for All' },
              { value: 'acceptForThis', label: 'Entity Specific' },
              { value: 'pending', label: 'Pending Approval' }
            ]"
            placeholder="Select Status"
          />
        </div>

        <!-- State Filter -->
        <div class="filter-select-box">
          <FormSelect
            v-model="filterState"
            label="State:"
            :options="[
              { value: 'All', label: 'All States' },
              { value: 'active', label: 'Active' },
              { value: 'inactive', label: 'Inactive' }
            ]"
            placeholder="Select State"
          />
        </div>
      </template>

      <!-- Primary Action: + Add Field of Study (Rule 10.2) -->
      <template #actions>
        <AppButton variant="primary" size="sm" @click="openCreateModal">
  <template #icon-left><Plus :size="15" /></template>
  Add Field of Study
</AppButton>
      </template>

      <!-- Table Body -->
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

              <!-- Name & Code Header (Rule 9.4 & 9.5) -->
              <th v-if="isColumnVisible('name')" class="col-name">Field of Study Name</th>
              <th v-if="isColumnVisible('parent')" class="col-parent">Parent Discipline</th>
              <th v-if="isColumnVisible('entity')" class="col-entity">Owning Entity</th>
              <th v-if="isColumnVisible('status')" class="col-status">Status</th>
              <th v-if="isColumnVisible('state')" class="col-state">State</th>
              <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <!-- Empty State -->
            <tr v-if="filteredFields.length === 0">
              <td :colspan="tableColumns.length + 1" class="empty-state-cell">
                <div class="empty-state-container">
                  <GraduationCap :size="36" class="empty-state-icon" />
                  <p class="empty-state-title">No fields of study found</p>
                  <p class="empty-state-subtext">No academic disciplines match your current filter and search criteria.</p>
                </div>
              </td>
            </tr>

            <!-- Data Rows -->
            <tr 
              v-for="item in filteredFields" 
              :key="item.id"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
            >
              <!-- Checkbox Cell -->
              <td class="col-checkbox">
                <input 
                  type="checkbox" 
                  :checked="selectedRowIds.includes(item.id)" 
                  @change="toggleSelectRow(item.id)" 
                  class="table-checkbox" 
                />
              </td>

              <!-- Name & Code (Rule 9.4 & 9.5: Secondary Color #404040 for Name, Subtext Code) -->
              <td v-if="isColumnVisible('name')" class="col-name" @click="handleInspect(item)">
                <div class="field-name-block cursor-pointer">
                  <span class="table-name-primary">{{ item.name }}</span>
                  <span class="table-code-subtext">{{ item.code }}</span>
                </div>
              </td>

              <!-- Parent Discipline (Rule 9.6: Plain Tertiary Text #737373, Anti-Badge) -->
              <td v-if="isColumnVisible('parent')" class="col-parent">
                <span class="tertiary-plain-text">{{ item.parent_name || '— (Root Discipline)' }}</span>
              </td>

              <!-- Owning Entity -->
              <td v-if="isColumnVisible('entity')" class="col-entity">
                <span class="tertiary-plain-text">{{ item.entity_name }}</span>
              </td>

              <!-- Governance Status -->
              <td v-if="isColumnVisible('status')" class="col-status">
                <span class="tertiary-plain-text">{{ item.status_label }}</span>
              </td>

              <!-- Lifecycle State (Rule 9.9: Rounded State Pills solely for Active/Inactive) -->
              <td v-if="isColumnVisible('state')" class="col-state">
                <span 
                  class="status-pill" 
                  :class="item.state === 'active' ? 'status-pill-active' : 'status-pill-inactive'"
                >
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </span>
              </td>

              <!-- Actions Dropdown -->
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

                  <div v-if="activeActionMenuId === item.id" class="action-dropdown" @click.stop>
                    <button class="dropdown-item" @click="handleInspect(item)">
                      <Eye :size="14" class="dropdown-icon" />
                      <span>View Details</span>
                    </button>
                    <button class="dropdown-item" @click="openEditModal(item)">
                      <Edit2 :size="14" class="dropdown-icon" />
                      <span>Edit Field</span>
                    </button>
                    <button class="dropdown-item" @click="handleDuplicate(item)">
                      <Copy :size="14" class="dropdown-icon" />
                      <span>Duplicate</span>
                    </button>
                    <button class="dropdown-item" @click="handleToggleState(item)">
                      <Check :size="14" class="dropdown-icon" />
                      <span>{{ item.state === 'active' ? 'Deactivate' : 'Activate' }}</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button class="dropdown-item dropdown-item-danger" @click="handleDelete(item.id)">
                      <Trash2 :size="14" class="dropdown-icon" />
                      <span>Delete</span>
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
      :count="selectedRowIds.length" 
      @delete="handleBatchDelete" 
    />

    <!-- ═══ QUICK CREATE / EDIT MODAL (< 5 Required Fields Flow: Rule 4) ═══ -->
    <QuickCreateModal
      :show="showQuickCreate"
      :title="editingFieldId ? 'Edit Field of Study' : 'Add Field of Study'"
      :showExpandButton="false"
      saveLabel="Save"
      @update:show="showQuickCreate = $event"
      @save="handleSaveQuickCreate"
      @cancel="showQuickCreate = false"
    >
      <div class="modal-form-stack">
        <!-- Field 1: Name (Schema column: name) -->
        <div class="modal-form-group">
          <label class="modal-field-label">
            Field of Study Name <span class="required-star">*</span>
          </label>
          <FormInput 
            v-model="quickForm.name" 
            placeholder=""
          />
        </div>

        <!-- Field 2: Parent Discipline (Schema column: parent_id) -->
        <div class="modal-form-group">
          <label class="modal-field-label">Parent Discipline (Optional)</label>
          <FormSelect 
            v-model="quickForm.parent_id" 
            :options="parentDisciplineOptions"
            placeholder="Select Parent Discipline (e.g. Business Administration)"
          />
        </div>

        <!-- Field 3: Owning Entity (Schema column: entity_id) -->
        <div class="modal-form-group">
          <label class="modal-field-label">Owning Entity</label>
          <FormSelect 
            v-model="quickForm.entity_id" 
            :options="entityOptions"
            placeholder="Select Owning Entity"
          />
        </div>

        <!-- Field 4: Governance Scope (Schema column: status_lookup_value_id) -->
        <div class="modal-form-group">
          <label class="modal-field-label">Governance Scope</label>
          <FormSelect 
            v-model="quickForm.status" 
            :options="governanceStatusOptions"
            placeholder="Select Status"
          />
        </div>
      </div>
    </QuickCreateModal>

    <!-- ═══ DETAIL INSPECTION MODAL ═══ -->
    <QuickCreateModal
      v-if="inspectingField"
      :show="!!inspectingField"
      title="Field of Study Details"
      :showExpandButton="false"
      saveLabel="Close"
      @update:show="inspectingField = null"
      @save="inspectingField = null"
      @cancel="inspectingField = null"
    >
      <div class="inspect-details-grid">
        <div class="inspect-item">
          <span class="inspect-label">Discipline Code</span>
          <span class="inspect-val font-mono">{{ inspectingField.code }}</span>
        </div>
        <div class="inspect-item">
          <span class="inspect-label">Discipline Name</span>
          <span class="inspect-val font-semibold">{{ inspectingField.name }}</span>
        </div>
        <div class="inspect-item">
          <span class="inspect-label">Parent Discipline</span>
          <span class="inspect-val">{{ inspectingField.parent_name || 'Root Discipline' }}</span>
        </div>
        <div class="inspect-item">
          <span class="inspect-label">Owning Entity</span>
          <span class="inspect-val">{{ inspectingField.entity_name }}</span>
        </div>
        <div class="inspect-item">
          <span class="inspect-label">Governance Status</span>
          <span class="inspect-val">{{ inspectingField.status_label }}</span>
        </div>
        <div class="inspect-item">
          <span class="inspect-label">System Seeded</span>
          <span class="inspect-val">{{ inspectingField.is_system ? 'Yes (Platform Catalogue)' : 'No (Tenant Created)' }}</span>
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.fields-of-study-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  width: 100%;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
}

/* Toast Banner */
.quick-toast-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  background-color: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  color: #065f46;
  font-size: 13px;
  font-weight: 500;
  animation: fadeIn 0.2s ease-in;
}

.toast-icon {
  color: #059669;
  flex-shrink: 0;
}

/* Filter Toolbar Controls */
.filter-search-box {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 38px;
  padding: 0 10px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  min-width: 260px;
  transition: border-color 0.15s ease;
}

.filter-search-box:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.search-icon {
  color: #737373;
  flex-shrink: 0;
}

.filter-search-input {
  border: none;
  background: transparent;
  font-size: 13px;
  color: #404040;
  width: 100%;
  outline: none;
}

.filter-search-input::placeholder {
  color: #94a3b8;
}

.search-clear-btn {
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 2px;
  display: flex;
  align-items: center;
}

.filter-select-box {
  display: flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 10px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}

.filter-label {
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  white-space: nowrap;
}

.filter-select {
  border: none;
  background: transparent;
  font-size: 13px;
  color: #404040;
  outline: none;
  cursor: pointer;
}

/* Primary Action Button (Rule 6: 8px-10px radius, well-rounded rectangle) */
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
  transition: background-color 0.15s ease;
  white-space: nowrap;
}

.btn-primary-create:hover {
  background-color: #09427d;
}

/* Table Standards (Rule 8 & Rule 9) */
.table-container {
  overflow-x: auto;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  background-color: #fafafa;
  color: #737373;
  font-size: 12px;
  font-weight: 500;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  border-bottom: 1px solid #f1f5f9;
  font-size: 13px;
  color: #404040;
  vertical-align: middle;
}

.erp-table tr:hover td {
  background-color: #f8fafc;
}

.row-selected td {
  background-color: #eff6ff !important;
}

/* Column Widths & Alignments */
.col-checkbox {
  width: 44px;
  padding: 0 0 0 16px !important;
  text-align: center;
}

.table-checkbox {
  width: 15px;
  height: 15px;
  accent-color: #0B529C;
  cursor: pointer;
}

.col-name {
  min-width: 240px;
}

.col-parent {
  min-width: 200px;
}

.col-count {
  min-width: 140px;
}

.col-entity {
  min-width: 160px;
}

.col-status {
  min-width: 160px;
}

.col-state {
  width: 100px;
}

.col-actions {
  width: 50px;
  text-align: right;
  padding-right: 16px !important;
}

/* Primary Name & Subtext Code (Rule 9.4 & 9.5) */
.field-name-block {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.table-code-subtext {
  font-size: 11px;
  font-family: monospace;
  color: #737373;
}

/* Tertiary Plain Text (Rule 9.5 & 9.6: Anti-Badge Standard) */
.tertiary-plain-text {
  color: #737373;
  font-size: 13px;
}

/* Lifecycle Status Pills (Rule 9.9: Reserved exclusively for State) */
.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
  line-height: 1.4;
}

.status-pill-active {
  background-color: #ecfdf5;
  color: #059669;
}

.status-pill-inactive {
  background-color: #f1f5f9;
  color: #64748b;
}

/* Action Dots Button */
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
  border-radius: 6px;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #404040;
}

/* Action Dropdown Menu */
.action-dropdown {
  position: absolute;
  top: 100%;
  right: 0;
  width: 170px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.08), 0 4px 6px -2px rgba(0, 0, 0, 0.04);
  padding: 4px;
  z-index: 50;
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 7px 10px;
  font-size: 12.5px;
  color: #404040;
  background: none;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.15s ease;
}

.dropdown-item:hover {
  background-color: #f1f5f9;
}

.dropdown-item-danger {
  color: #dc2626;
}

.dropdown-item-danger:hover {
  background-color: #fef2f2;
}

.dropdown-icon {
  flex-shrink: 0;
}

.dropdown-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 3px 0;
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
  justify-content: center;
}

.empty-state-icon {
  color: #cbd5e1;
  margin-bottom: 12px;
}

.empty-state-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}

.empty-state-subtext {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

/* Modal Form Stack */
.modal-form-stack {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.modal-form-group {
  display: flex;
  flex-direction: column;
}

.modal-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 4px;
}

.required-star {
  color: #dc2626;
}

/* Inspect Modal Details */
.inspect-details-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 14px;
  padding: 4px 0;
}

.inspect-item {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.inspect-label {
  font-size: 11.5px;
  color: #737373;
  font-weight: 500;
}

.inspect-val {
  font-size: 13px;
  color: #404040;
}

.cursor-pointer {
  cursor: pointer;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-3px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
