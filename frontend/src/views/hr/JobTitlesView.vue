<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { 
  BadgeCheck, Plus, Search, Filter, ArrowUpDown, ChevronDown, 
  MoreVertical, Edit2, Trash2, Eye, Copy, Check, Calendar, 
  CheckCircle2, AlertCircle, X, Layers, ChevronRight, Briefcase,
  UserCheck, DollarSign, Calculator, Truck, Building2, Scale,
  Laptop, ShieldCheck, Award, Maximize2
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

const router = useRouter();

// ─── Lookups & Types (HR_Schema_final-v4.sql lines 1110–1131) ───
export type RowState = 'active' | 'inactive';
export type PositionCategory = 'management' | 'non_management' | 'executive';
export type GovernanceStatus = 'pending' | 'acceptForAll' | 'acceptForThis' | 'reject';

export interface JobTitleRecord {
  id: number;
  uuid: string;
  code: string;
  name: string;
  description?: string;
  icon_id?: number | null;
  icon_name?: string | null;
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  category: PositionCategory;
  category_label: string;
  status: GovernanceStatus;
  status_label: string;
  positions_count: number;
  state: RowState;
}

// ─── Breadcrumbs (Rule: Exact Page Name from Sidebar Only, Zero Section Titles) ───
const breadcrumbItems = [
  { label: 'Job Titles & Roles' }
];

// ─── State Management ───
const searchQuery = ref('');
const filterCategory = ref('All');
const filterStatus = ref('All');
const filterState = ref('All');
const currentSort = ref('name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const showQuickCreate = ref(false);
const quickActionToast = ref<string | null>(null);

// ─── Table Columns (Strict Single-Information & Name-First Hierarchy) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Job Title / Role', visible: true, sortable: true },
  { key: 'category', label: 'Position Category', visible: true, sortable: true },
  { key: 'entity', label: 'Owning Entity', visible: true, sortable: true },
  { key: 'status', label: 'Status', visible: true, sortable: true },
  { key: 'positions_count', label: 'Active Positions', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

// ─── Mock Data Aligned with HR_Schema_final-v4.sql lines 1124–1130 ───
const jobTitles = ref<JobTitleRecord[]>([
  {
    id: 12,
    uuid: 'jt-uuid-012',
    code: 'JT-HR-OFF',
    name: 'HR Officer',
    description: 'Human resources operational administration and recruitment support.',
    icon_id: 21,
    icon_name: 'UserCheck',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    category: 'non_management',
    category_label: 'Non-Management',
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    positions_count: 2,
    state: 'active'
  },
  {
    id: 24,
    uuid: 'jt-uuid-024',
    code: 'JT-SR-CSH',
    name: 'Senior Cashier',
    description: 'Frontline commercial financial disbursements and cash operations.',
    icon_id: 22,
    icon_name: 'DollarSign',
    tenant_id: 1,
    entity_id: 7,
    entity_name: 'Haleta Grand Hotel & Suites',
    category: 'non_management',
    category_label: 'Non-Management',
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    positions_count: 4,
    state: 'active'
  },
  {
    id: 30,
    uuid: 'jt-uuid-030',
    code: 'JT-FIN-MGR',
    name: 'Finance Manager',
    description: 'Corporate accounting, financial planning, audit compliance, and statutory filing.',
    icon_id: 25,
    icon_name: 'Building2',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    category: 'management',
    category_label: 'Management',
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    positions_count: 1,
    state: 'active'
  },
  {
    id: 31,
    uuid: 'jt-uuid-031',
    code: 'JT-FIN-ACC',
    name: 'Financial Accountant',
    description: 'General ledger reconciliations, payroll audits, and financial reporting.',
    icon_id: 23,
    icon_name: 'Calculator',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    category: 'non_management',
    category_label: 'Non-Management',
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    positions_count: 3,
    state: 'active'
  },
  {
    id: 40,
    uuid: 'jt-uuid-040',
    code: 'JT-PRC-OFF',
    name: 'Procurement Officer',
    description: 'Vendor relationship management, bidding, and purchase order tracking.',
    icon_id: 24,
    icon_name: 'Truck',
    tenant_id: 1,
    entity_id: 9,
    entity_name: 'Haleta Hawassa Hub',
    category: 'non_management',
    category_label: 'Non-Management',
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    positions_count: 2,
    state: 'active'
  }
]);

// ─── Entity Options (FK Entity lines 1118) ───
const entityOptions = [
  { value: 1, label: 'QMT Business Group (HQ)' },
  { value: 3, label: 'Haleta Addis Ababa HQ' },
  { value: 7, label: 'Haleta Grand Hotel & Suites' },
  { value: 9, label: 'Haleta Hawassa Hub' }
];

// ─── Quick Create Form State (Strictly Using FK IDs) ───
const quickForm = ref({
  name: '',
  category: 'non_management' as PositionCategory,
  entity_id: 3,
  status: 'acceptForAll' as GovernanceStatus,
  description: ''
});

// ─── Filter & Search Logic ───
const activeFilterCount = computed(() => {
  let count = 0;
  if (filterCategory.value !== 'All') count++;
  if (filterStatus.value !== 'All') count++;
  if (filterState.value !== 'All') count++;
  return count;
});

const filteredJobTitles = computed(() => {
  return jobTitles.value.filter(t => {
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase();
      const matchName = t.name.toLowerCase().includes(q);
      const matchCode = t.code.toLowerCase().includes(q);
      if (!matchName && !matchCode) return false;
    }
    if (filterCategory.value !== 'All' && t.category_label !== filterCategory.value) return false;
    if (filterStatus.value !== 'All' && t.status_label !== filterStatus.value) return false;
    if (filterState.value !== 'All' && t.state !== filterState.value.toLowerCase()) return false;
    return true;
  }).sort((a, b) => {
    let valA = a[currentSort.value as keyof JobTitleRecord];
    let valB = b[currentSort.value as keyof JobTitleRecord];
    if (valA === undefined || valA === null) valA = '';
    if (valB === undefined || valB === null) valB = '';
    if (valA < valB) return sortOrder.value === 'asc' ? -1 : 1;
    if (valA > valB) return sortOrder.value === 'asc' ? 1 : -1;
    return 0;
  });
});

// ─── Selection Logic ───
const isAllSelected = computed(() => {
  return filteredJobTitles.value.length > 0 && 
    filteredJobTitles.value.every(t => selectedRowIds.value.includes(t.id));
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = filteredJobTitles.value.map(t => t.id);
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
  if (!quickForm.value.name.trim()) {
    alert('Please enter a Job Title Name.');
    return;
  }

  const newId = Date.now();
  const nameParts = quickForm.value.name.trim().split(' ');
  const codeSuffix = nameParts.length > 1 
    ? `${nameParts[0].substring(0, 2)}-${nameParts[1].substring(0, 3)}`.toUpperCase()
    : nameParts[0].substring(0, 4).toUpperCase();

  const categoryMap: Record<PositionCategory, string> = {
    management: 'Management',
    non_management: 'Non-Management',
    executive: 'Executive'
  };

  const statusMap: Record<GovernanceStatus, string> = {
    acceptForAll: 'Approved for All Entities',
    acceptForThis: 'Approved for This Entity Only',
    pending: 'Pending Approval',
    reject: 'Rejected'
  };

  const selectedEntity = entityOptions.find(e => e.value === quickForm.value.entity_id);

  const newRecord: JobTitleRecord = {
    id: newId,
    uuid: `jt-${newId}`,
    code: `JT-${codeSuffix}`,
    name: quickForm.value.name.trim(),
    description: quickForm.value.description,
    tenant_id: 1,
    entity_id: quickForm.value.entity_id,
    entity_name: selectedEntity ? selectedEntity.label : 'Haleta Addis Ababa HQ',
    category: quickForm.value.category,
    category_label: categoryMap[quickForm.value.category],
    status: quickForm.value.status,
    status_label: statusMap[quickForm.value.status],
    positions_count: 0,
    state: 'active'
  };

  jobTitles.value.unshift(newRecord);
  showQuickCreate.value = false;
  showToast(`Job Title "${newRecord.name}" created successfully.`);

  // Reset
  quickForm.value.name = '';
  quickForm.value.description = '';
  quickForm.value.entity_id = 3;
};

// Expand to dedicated creation page (Rule 4 standard)
const handleExpandFullForm = () => {
  showQuickCreate.value = false;
  router.push({
    path: '/hr/job-titles/create',
    query: {
      name: quickForm.value.name,
      category: quickForm.value.category,
      entity_id: quickForm.value.entity_id
    }
  });
};

const getIconComponent = (name?: string | null) => {
  switch (name) {
    case 'UserCheck': return UserCheck;
    case 'DollarSign': return DollarSign;
    case 'Calculator': return Calculator;
    case 'Truck': return Truck;
    case 'Building2': return Building2;
    case 'Award': return Award;
    case 'ShieldCheck': return ShieldCheck;
    case 'Briefcase': return Briefcase;
    default: return Briefcase;
  }
};

// Batch Delete
const handleBatchDelete = () => {
  jobTitles.value = jobTitles.value.filter(t => !selectedRowIds.value.includes(t.id));
  selectedRowIds.value = [];
  showToast('Selected job titles removed.');
};

onMounted(() => {
  window.addEventListener('click', closeActionMenu);
});

onUnmounted(() => {
  window.removeEventListener('click', closeActionMenu);
});
</script>

<template>
  <div class="job-titles-page">
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
        title="Job Titles & Roles Catalogue"
        subtitle="Maintain standardized enterprise role nomenclature (JobTitle), position categories driving OT-exemption and statutory benefit eligibility, and multi-entity governance approvals."
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search Name..."
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
            @click="showQuickCreate = true"
          >
            <Plus :size="15" />
            <span>Create Job Title</span>
          </button>
        </template>

        <!-- Filter Popover -->
        <template #filter>
          <div class="filter-grid">
            <FormSelect
              label="Position Category"
              v-model="filterCategory"
              :options="['All', 'Non-Management', 'Management', 'Executive']"
            />
            <FormSelect
              label="Status"
              v-model="filterStatus"
              :options="['All', 'Approved for All Entities', 'Approved for This Entity Only']"
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

              <!-- Name Column (Secondary color) with Code as sub-text in tertiary color -->
              <th v-if="isColumnVisible('name')" class="col-name sortable" @click="currentSort = 'name'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>Job Title / Role</span>
                  <ArrowUpDown v-if="currentSort === 'name'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <!-- Subsequent Columns strictly in Tertiary Color -->
              <th v-if="isColumnVisible('category')" class="col-category">Position Category</th>
              <th v-if="isColumnVisible('entity')" class="col-entity">Owning Entity</th>
              <th v-if="isColumnVisible('status')" class="col-status sortable" @click="currentSort = 'status'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>Status</span>
                  <ArrowUpDown v-if="currentSort === 'status'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>
              <th v-if="isColumnVisible('positions_count')" class="col-count">Active Positions</th>
              <th v-if="isColumnVisible('state')" class="col-state sortable" @click="currentSort = 'state'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>State</span>
                  <ArrowUpDown v-if="currentSort === 'state'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>
              <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr 
              v-for="item in filteredJobTitles" 
              :key="item.id"
              class="erp-row cursor-pointer"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
            >
              <td class="col-checkbox" @click.stop>
                <input 
                  type="checkbox" 
                  class="custom-checkbox" 
                  :checked="selectedRowIds.includes(item.id)" 
                  @change="toggleRowSelection(item.id)" 
                />
              </td>

              <!-- Rule 4 & 5: Name is Secondary Color (#404040), Code is Tertiary subtext (#737373) -->
              <td v-if="isColumnVisible('name')" class="col-name">
                <div class="title-identity-cell">
                  <div class="role-icon-box" v-if="item.icon_name">
                    <component :is="getIconComponent(item.icon_name)" :size="15" class="role-icon" />
                  </div>
                  <div class="name-cell-stack">
                    <span class="table-name-primary">{{ item.name }}</span>
                    <span class="table-code-subtext font-mono">{{ item.code }}</span>
                  </div>
                </div>
              </td>

              <!-- Rule 5 & 6: Tertiary plain text, NO decorative badges for categories or counts -->
              <td v-if="isColumnVisible('category')" class="col-category">
                <span class="text-tertiary">{{ item.category_label }}</span>
              </td>

              <td v-if="isColumnVisible('entity')" class="col-entity">
                <span class="text-tertiary">{{ item.entity_name }}</span>
              </td>

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

              <td v-if="isColumnVisible('positions_count')" class="col-count">
                <span class="text-tertiary">{{ item.positions_count }} Positions</span>
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
                    <button type="button" class="menu-item" @click="router.push(`/hr/job-positions?title=${item.name}`)">
                      <Briefcase :size="14" />
                      <span>View Position Seats</span>
                    </button>
                    <button 
                      type="button" 
                      class="menu-item"
                      @click="item.state = item.state === 'active' ? 'inactive' : 'active'; showToast(`Updated ${item.code} state.`); closeActionMenu();"
                    >
                      <Check :size="14" />
                      <span>{{ item.state === 'active' ? 'Deactivate Title' : 'Activate Title' }}</span>
                    </button>
                    <div class="menu-divider"></div>
                    <button 
                      type="button" 
                      class="menu-item text-rose-600 hover:bg-rose-50"
                      @click="jobTitles = jobTitles.filter(t => t.id !== item.id); showToast(`Deleted title ${item.code}`); closeActionMenu();"
                    >
                      <Trash2 :size="14" />
                      <span>Delete Title</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>

            <tr v-if="filteredJobTitles.length === 0">
              <td colspan="7" class="table-empty-row">
                <div class="empty-state-box">
                  <p class="empty-title">No Job Titles Found</p>
                  <p class="empty-subtitle">Adjust your filter options or create a new job title catalogue role.</p>
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

    <!-- QUICK CREATE MODAL (Standard: <= 5 Required Fields, No Subtitle, No Bottom Divider Line) -->
    <QuickCreateModal
      v-model:show="showQuickCreate"
      title="Create Job Title"
      saveLabel="Save"
      @save="handleQuickSave"
      @expand="handleExpandFullForm"
      :showExpandButton="true"
      width="md"
    >
      <div class="quick-create-form-body">
        <div class="modal-row-grid">
          <!-- Job Title Name: Rule 5 & 14 (Zero Placeholder) -->
          <FormInput
            label="Job Title Name"
            v-model="quickForm.name"
            required
          />

          <!-- Position Category (POSITION_CATEGORY: management | non_management | executive) -->
          <FormSelect
            label="Position Category"
            v-model="quickForm.category"
            :options="[
              { label: 'Non-Management', value: 'non_management' },
              { label: 'Management', value: 'management' },
              { label: 'Executive', value: 'executive' }
            ]"
            placeholder="Select Category"
            required
          />
        </div>

        <div class="modal-row-grid mt-3">
          <!-- Owning Entity: FK entity_id (Schema line 1118) -->
          <FormSelect
            label="Owning Entity"
            v-model="quickForm.entity_id"
            :options="entityOptions"
            placeholder="Select Entity"
            required
          />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.job-titles-page {
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
  min-width: 250px;
}

.name-cell-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary {
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
  gap: 12px;
}

.modal-row-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

/* Title Identity Cell with Icon */
.title-identity-cell {
  display: flex;
  align-items: center;
  gap: 12px;
}

.role-icon-box {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background-color: #f0f7ff;
  border: 1px solid #dbeafe;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.role-icon {
  color: #0B529C;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-3px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
