<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Network, Plus, Search, Filter, ArrowUpDown, ChevronDown, 
  MoreVertical, Edit2, Trash2, Eye, Copy, Check, Calendar, 
  CheckCircle2, AlertCircle, ChevronLeft, ChevronRight,
  Building2, Layers, GitBranch, ArrowRight, FolderTree,
  CornerDownRight, Users, ShieldCheck, Clock
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

// ─── Lookups & Types (HR_Schema_final-v4.sql lines 968–990) ───
export type OrgStructureState = 'draft' | 'active' | 'superseded';
export type RowState = 'active' | 'inactive';

export interface OrgStructureRecord {
  id: number;
  uuid: string;
  code: string;
  name: string;
  description?: string;
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  structure_state_lookup_value_id: OrgStructureState;
  effective_from: string;
  effective_to?: string | null;
  superseded_by_id?: number | null;
  superseded_by_code?: string | null;
  units_count: number;
  created_at: string;
  state: RowState;
}

export interface StructureTreeNode {
  id: number;
  code: string;
  name: string;
  type: string;
  head_name?: string;
  head_avatar?: string;
  head_title?: string;
  order: number;
  path: string;
  is_visible: boolean;
  children?: StructureTreeNode[];
}

// ─── Breadcrumb Configuration (Rule: Exact Page Name from Sidebar Only, Zero Section Titles) ───
const breadcrumbItems = computed(() => {
  if (viewMode.value === 'tree' && selectedStructure.value) {
    return [
      { label: 'Org Structures', onClick: () => { viewMode.value = 'list'; } },
      { label: selectedStructure.value.name, current: true }
    ];
  }
  return [
    { label: 'Org Structures' }
  ];
});

// ─── State Management ───
const viewMode = ref<'list' | 'tree'>('list');
const selectedStructure = ref<OrgStructureRecord | null>(null);
const searchQuery = ref('');
const filterStatus = ref('All');
const filterEntity = ref('All');
const filterLifecycle = ref('All');
const currentSort = ref('name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const showQuickCreate = ref(false);
const showCloneModal = ref(false);
const structureToClone = ref<OrgStructureRecord | null>(null);
const quickActionToast = ref<string | null>(null);

// ─── Table Columns Definition (Single Information & Name-First Rule) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Name', visible: true, sortable: true },
  { key: 'entity', label: 'Owning Entity', visible: true, sortable: true },
  { key: 'effective_period', label: 'Effective Timeline', visible: true, sortable: true },
  { key: 'units_count', label: 'Mapped Units', visible: true, sortable: true },
  { key: 'status', label: 'Status', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'superseded_by', label: 'Successor Blueprint', visible: false, sortable: false },
  { key: 'description', label: 'Scope Description', visible: false, sortable: false },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

const handleToggleColumn = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  if (col) {
    col.visible = !col.visible;
  }
};

// ─── Mock Database Data (Aligned Exactly with Screenshot 1) ───
const structures = ref<Array<OrgStructureRecord>>([
  {
    id: 1,
    uuid: 'org-str-001',
    code: 'CORP - 2027',
    name: 'Corporate 2027',
    description: 'Enterprise baseline structure covering executive management and business units.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'QMT Bole',
    structure_state_lookup_value_id: 'active',
    effective_from: 'May 4, 2026',
    effective_to: null,
    superseded_by_id: null,
    superseded_by_code: null,
    units_count: 16,
    created_at: '2026-05-04',
    state: 'active'
  },
  {
    id: 2,
    uuid: 'org-str-002',
    code: 'CORP - 2027',
    name: 'Corporate Baseline',
    description: 'Corporate organizational blueprint for Mekanisa operations.',
    tenant_id: 1,
    entity_id: 2,
    entity_name: 'QMT Mekanisa',
    structure_state_lookup_value_id: 'active',
    effective_from: 'May 4, 2026',
    effective_to: null,
    superseded_by_id: null,
    superseded_by_code: null,
    units_count: 11,
    created_at: '2026-05-04',
    state: 'active'
  },
  {
    id: 3,
    uuid: 'org-str-003',
    code: 'CORP - 2027',
    name: 'Corporate Blueprint',
    description: 'Prior organizational model for Koye entity.',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'QMT koye',
    structure_state_lookup_value_id: 'superseded',
    effective_from: 'May 4, 2026',
    effective_to: 'May 4, 2026',
    superseded_by_id: 1,
    superseded_by_code: 'CORP-2027',
    units_count: 8,
    created_at: '2026-05-04',
    state: 'inactive'
  }
]);

// ─── Mock Hierarchy Trees per Structure ───
const hierarchyTrees = ref<Record<number, StructureTreeNode>>({
  1: {
    id: 101,
    code: 'OU-EXEC',
    name: 'Executive Board & CEO Office',
    type: 'Board / Office',
    head_name: 'Fitsum Assefa',
    head_avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=80',
    head_title: 'Chief Executive Officer',
    order: 1,
    path: '101',
    is_visible: true,
    children: [
      {
        id: 102,
        code: 'OU-OPS',
        name: 'Operations & Supply Chain Division',
        type: 'Division',
        head_name: 'Dawit Tadesse',
        head_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=80',
        head_title: 'Director of Operations',
        order: 1,
        path: '101/102',
        is_visible: true,
        children: [
          {
            id: 105,
            code: 'OU-LOG',
            name: 'Logistics & Warehousing',
            type: 'Department',
            head_name: 'Samuel Bekele',
            head_avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=100&auto=format&fit=crop&q=80',
            head_title: 'Logistics Manager',
            order: 1,
            path: '101/102/105',
            is_visible: true
          },
          {
            id: 106,
            code: 'OU-PROC',
            name: 'Procurement & Vendor Management',
            type: 'Department',
            head_name: 'Bethlehem Hailu',
            head_avatar: 'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=100&auto=format&fit=crop&q=80',
            head_title: 'Procurement Lead',
            order: 2,
            path: '101/102/106',
            is_visible: true
          }
        ]
      },
      {
        id: 103,
        code: 'OU-FIN',
        name: 'Finance & Corporate Services Division',
        type: 'Division',
        head_name: 'Rahel Girma',
        head_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80',
        head_title: 'Chief Financial Officer',
        order: 2,
        path: '101/103',
        is_visible: true,
        children: [
          {
            id: 107,
            code: 'OU-ACC',
            name: 'General Accounting & Audit',
            type: 'Department',
            head_name: 'Almaz Ayana',
            head_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80',
            head_title: 'Senior Accountant',
            order: 1,
            path: '101/103/107',
            is_visible: true
          },
          {
            id: 108,
            code: 'OU-PAY',
            name: 'Payroll & Statutory Benefits',
            type: 'Section',
            head_name: 'Tigist Alemu',
            head_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
            head_title: 'Payroll Officer',
            order: 2,
            path: '101/103/108',
            is_visible: true
          }
        ]
      },
      {
        id: 104,
        code: 'OU-HR',
        name: 'People, Culture & Talent Division',
        type: 'Division',
        head_name: 'Solomon Mengistu',
        head_avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&auto=format&fit=crop&q=80',
        head_title: 'Human Resources Director',
        order: 3,
        path: '101/104',
        is_visible: true,
        children: [
          {
            id: 109,
            code: 'OU-REC',
            name: 'Talent Acquisition & Onboarding',
            type: 'Section',
            head_name: 'Hanna Worku',
            head_avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=100&auto=format&fit=crop&q=80',
            head_title: 'Recruitment Specialist',
            order: 1,
            path: '101/104/109',
            is_visible: true
          }
        ]
      }
    ]
  }
});

// ─── Filtering & Sorting ───
const activeFilterCount = computed(() => {
  let count = 0;
  if (filterStatus.value !== 'All') count++;
  if (filterEntity.value !== 'All') count++;
  if (filterLifecycle.value !== 'All') count++;
  return count;
});

const filteredStructures = computed(() => {
  return structures.value.filter(s => {
    // Search query
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase();
      const matchesCode = s.code.toLowerCase().includes(q);
      const matchesName = s.name.toLowerCase().includes(q);
      const matchesEntity = s.entity_name.toLowerCase().includes(q);
      if (!matchesCode && !matchesName && !matchesEntity) return false;
    }
    // Filter Status
    if (filterStatus.value !== 'All') {
      const target = filterStatus.value === 'Published' ? 'active' : filterStatus.value.toLowerCase();
      if (s.structure_state_lookup_value_id !== target) {
        return false;
      }
    }
    // Filter Entity
    if (filterEntity.value !== 'All' && s.entity_name !== filterEntity.value) {
      return false;
    }
    // Filter Lifecycle
    if (filterLifecycle.value !== 'All' && s.state !== filterLifecycle.value.toLowerCase()) {
      return false;
    }
    return true;
  }).sort((a, b) => {
    let valA: any = a[currentSort.value as keyof OrgStructureRecord] ?? '';
    let valB: any = b[currentSort.value as keyof OrgStructureRecord] ?? '';
    if (typeof valA === 'string') {
      valA = valA.toLowerCase();
      valB = (valB as string).toLowerCase();
    }
    if (sortOrder.value === 'asc') return valA > valB ? 1 : -1;
    return valA < valB ? 1 : -1;
  });
});

// ─── Selection Management ───
const isAllSelected = computed(() => {
  return filteredStructures.value.length > 0 && 
    filteredStructures.value.every(s => selectedRowIds.value.includes(s.id));
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = filteredStructures.value.map(s => s.id);
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

// ─── Actions & Modals ───
const toggleActionMenu = (id: number, e: MouseEvent) => {
  e.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
};

const viewStructureTree = (item: OrgStructureRecord) => {
  closeActionMenu();
  selectedStructure.value = item;
  viewMode.value = 'tree';
};

const handleBackToList = () => {
  viewMode.value = 'list';
  selectedStructure.value = null;
};

// Quick Create Form State (Org Structure - Schema Lines 968-990)
const entityNameMap: Record<string, string> = {
  '1': 'QMT Bole',
  '2': 'QMT Mekanisa',
  '3': 'QMT koye',
  '4': 'Haleta Addis Ababa HQ'
};

const quickForm = ref({
  name: '',
  entity_id: '4',
  effective_from: new Date().toISOString().split('T')[0],
  effective_to: '',
  structure_state: 'active' as OrgStructureState,
  description: ''
});

const handleExpandToFullForm = () => {
  showQuickCreate.value = false;
  router.push({
    path: '/hr/org-structures/create',
    query: {
      name: quickForm.value.name,
      entity_id: quickForm.value.entity_id,
      effective_from: quickForm.value.effective_from,
      effective_to: quickForm.value.effective_to,
      description: quickForm.value.description
    }
  });
};

const handleSaveQuickStructure = () => {
  if (!quickForm.value.name.trim()) return;

  const cleanName = quickForm.value.name.trim().toUpperCase();
  const yearMatch = cleanName.match(/\b(20\d{2})\b/);
  const year = yearMatch ? yearMatch[1] : new Date().getFullYear();
  const prefix = cleanName.replace(/[^A-Z]/g, '').slice(0, 4) || 'CORP';
  const autoCode = `${prefix} - ${year}`;

  const entId = Number(quickForm.value.entity_id) || 4;
  const entName = entityNameMap[quickForm.value.entity_id] || 'Haleta Addis Ababa HQ';

  const newRecord: OrgStructureRecord = {
    id: Date.now(),
    uuid: `org-str-${Date.now().toString().slice(-4)}`,
    code: autoCode,
    name: quickForm.value.name.trim(),
    description: quickForm.value.description.trim() || undefined,
    tenant_id: 1,
    entity_id: entId,
    entity_name: entName,
    structure_state_lookup_value_id: quickForm.value.structure_state,
    effective_from: quickForm.value.effective_from || new Date().toISOString().split('T')[0],
    effective_to: quickForm.value.effective_to ? quickForm.value.effective_to : null,
    superseded_by_id: null,
    superseded_by_code: null,
    units_count: 0,
    created_at: new Date().toISOString().split('T')[0],
    state: quickForm.value.structure_state === 'active' ? 'active' : 'inactive'
  };

  structures.value.unshift(newRecord);
  showQuickCreate.value = false;

  // Reset form
  quickForm.value = {
    name: '',
    entity_id: '4',
    effective_from: new Date().toISOString().split('T')[0],
    effective_to: '',
    structure_state: 'active' as OrgStructureState,
    description: ''
  };

  showToast(`Organization Structure "${newRecord.name}" created successfully.`);
};

// Clone / Restructure Workflow
const handleOpenCloneModal = (item: OrgStructureRecord) => {
  closeActionMenu();
  structureToClone.value = item;
  showCloneModal.value = true;
};

const handleConfirmClone = () => {
  if (!structureToClone.value) return;

  const source = structureToClone.value;
  const successorCode = source.code.replace(/(\d{4})/, (year) => String(Number(year) + 1));

  const cloneRecord: OrgStructureRecord = {
    id: Date.now(),
    uuid: `org-str-${Date.now().toString().slice(-4)}`,
    code: successorCode !== source.code ? successorCode : `${source.code}-DRAFT`,
    name: `${source.name} (Restructure Plan)`,
    description: `Successor restructure drafted from ${source.code}. Preserves full parent-child hierarchy baseline for revision.`,
    tenant_id: source.tenant_id,
    entity_id: source.entity_id,
    entity_name: source.entity_name,
    structure_state_lookup_value_id: 'draft',
    effective_from: '2027-01-01',
    effective_to: null,
    superseded_by_id: null,
    superseded_by_code: null,
    units_count: source.units_count,
    created_at: new Date().toISOString().split('T')[0],
    state: 'active'
  };

  // Populate mock tree if source exists
  if (hierarchyTrees.value[source.id]) {
    hierarchyTrees.value[cloneRecord.id] = JSON.parse(JSON.stringify(hierarchyTrees.value[source.id]));
  }

  structures.value.unshift(cloneRecord);
  showCloneModal.value = false;
  showToast(`Created restructure blueprint draft ${cloneRecord.code} based on ${source.code}.`);
};

// Set as Active
const handleSetActive = (item: OrgStructureRecord) => {
  closeActionMenu();
  // Find current active for this entity
  const currentActive = structures.value.find(s => 
    s.entity_id === item.entity_id && 
    s.structure_state_lookup_value_id === 'active' && 
    s.id !== item.id
  );

  if (currentActive) {
    currentActive.structure_state_lookup_value_id = 'superseded';
    currentActive.effective_to = new Date().toISOString().split('T')[0];
    currentActive.superseded_by_id = item.id;
    currentActive.superseded_by_code = item.code;
  }

  item.structure_state_lookup_value_id = 'active';
  showToast(`${item.code} is now the Active Organization Blueprint for ${item.entity_name}.`);
};

const showToast = (msg: string) => {
  quickActionToast.value = msg;
  setTimeout(() => {
    quickActionToast.value = null;
  }, 4000);
};

// Floating bar actions
const handleBatchDelete = () => {
  structures.value = structures.value.filter(s => !selectedRowIds.value.includes(s.id));
  selectedRowIds.value = [];
  showToast('Selected organization blueprints removed.');
};

onMounted(() => {
  window.addEventListener('click', closeActionMenu);
});

onUnmounted(() => {
  window.removeEventListener('click', closeActionMenu);
});
</script>

<template>
  <div class="org-structures-page">
    <!-- Breadcrumbs -->
    <div class="page-breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Toast Notification -->
    <div v-if="quickActionToast" class="quick-toast-banner">
      <CheckCircle2 :size="15" class="text-emerald-600" />
      <span>{{ quickActionToast }}</span>
    </div>

    <!-- VIEW 1: STRUCTURE DIRECTORY TABLE -->
    <div v-if="viewMode === 'list'" class="directory-view-wrapper">
      <AppDataTable
        title="Organization Structures"
        subtitle="Manage macro organizational blueprints, effective-dated versions, restructuring plans, and structural hierarchy baselines across enterprise entities."
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
        <template #actions>
          <button 
            type="button" 
            class="btn-primary-create" 
            @click="showQuickCreate = true"
          >
            <Plus :size="15" />
            <span>Create Structure</span>
          </button>
        </template>

        <template #filter-panel>
          <div class="filter-grid">
            <FormSelect
              label="Status"
              v-model="filterStatus"
              :options="['All', 'Published', 'Draft', 'Superseded']"
            />
            <FormSelect
              label="Owning Entity"
              v-model="filterEntity"
              :options="['All', 'Haleta Addis Ababa HQ', 'Haleta Grand Hotel & Suites']"
            />
            <FormSelect
              label="State"
              v-model="filterLifecycle"
              :options="['All', 'Active', 'Inactive']"
            />
          </div>
        </template>

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

              <th v-if="isColumnVisible('name')" class="col-name sortable" @click="currentSort = 'name'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>Name</span>
                  <ArrowUpDown v-if="currentSort === 'name'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th v-if="isColumnVisible('entity')" class="col-entity">Owning Entity</th>

              <th v-if="isColumnVisible('effective_period')" class="col-period">Effective Timeline</th>

              <th v-if="isColumnVisible('units_count')" class="col-units">Mapped Units</th>

              <th v-if="isColumnVisible('status')" class="col-status sortable" @click="currentSort = 'status'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>Status</span>
                  <ArrowUpDown v-if="currentSort === 'status'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th v-if="isColumnVisible('state')" class="col-state sortable" @click="currentSort = 'state'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>State</span>
                  <ArrowUpDown v-if="currentSort === 'state'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th v-if="isColumnVisible('superseded_by')" class="col-successor">Successor Blueprint</th>

              <th v-if="isColumnVisible('description')" class="col-desc">Scope Description</th>

              <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr 
              v-for="item in filteredStructures" 
              :key="item.id"
              class="erp-row cursor-pointer"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
              @click="viewStructureTree(item)"
            >
              <td class="col-checkbox" @click.stop>
                <input 
                  type="checkbox" 
                  class="custom-checkbox" 
                  :checked="selectedRowIds.includes(item.id)" 
                  @change="toggleRowSelection(item.id)" 
                />
              </td>

              <td v-if="isColumnVisible('name')" class="col-name">
                <div class="name-cell-stack">
                  <span class="table-name-primary">{{ item.name }}</span>
                  <span class="table-code-subtext font-mono">{{ item.code }}</span>
                </div>
              </td>

              <td v-if="isColumnVisible('entity')" class="col-entity">
                <span class="text-tertiary">{{ item.entity_name }}</span>
              </td>

              <td v-if="isColumnVisible('effective_period')" class="col-period">
                <span class="text-tertiary">{{ item.effective_from }} - {{ item.effective_to || 'Current' }}</span>
              </td>

              <td v-if="isColumnVisible('units_count')" class="col-units">
                <span class="text-tertiary">{{ item.units_count }} Units</span>
              </td>

              <td v-if="isColumnVisible('status')" class="col-status">
                <span 
                  class="version-pill"
                  :class="{
                    'state-published': item.structure_state_lookup_value_id === 'active',
                    'state-draft': item.structure_state_lookup_value_id === 'draft',
                    'state-superseded': item.structure_state_lookup_value_id === 'superseded'
                  }"
                >
                  <span class="dot-indicator"></span>
                  <span>{{ item.structure_state_lookup_value_id === 'active' ? 'Published' : (item.structure_state_lookup_value_id === 'draft' ? 'Draft' : 'Superseded') }}</span>
                </span>
              </td>

              <td v-if="isColumnVisible('state')" class="col-state">
                <span class="status-pill" :class="item.state === 'active' ? 'status-pill-active' : 'status-pill-inactive'">
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </span>
              </td>

              <td v-if="isColumnVisible('superseded_by')" class="col-successor">
                <span v-if="item.superseded_by_code" class="successor-tag font-mono">
                  {{ item.superseded_by_code }}
                </span>
                <span v-else class="text-slate-400">—</span>
              </td>

              <td v-if="isColumnVisible('description')" class="col-desc">
                <span class="table-text-muted text-xs truncate max-w-xs block">{{ item.description || '—' }}</span>
              </td>

              <td v-if="isColumnVisible('actions')" class="col-actions" @click.stop>
                <div class="action-cell-wrapper">
                  <button 
                    type="button" 
                    class="btn-action-dots" 
                    @click="toggleActionMenu(item.id, $event)"
                    title="Structure Actions"
                  >
                    <MoreVertical :size="15" />
                  </button>

                  <div v-if="activeActionMenuId === item.id" class="action-dropdown-menu">
                    <button class="action-menu-item" @click="viewStructureTree(item)">
                      <Eye :size="13" />
                      <span>View Hierarchy Tree</span>
                    </button>
                    <button class="action-menu-item" @click="handleOpenCloneModal(item)">
                      <Copy :size="13" />
                      <span>Draft Restructure Successor</span>
                    </button>
                    <button 
                      v-if="item.structure_state_lookup_value_id !== 'active'" 
                      class="action-menu-item text-emerald-700" 
                      @click="handleSetActive(item)"
                    >
                      <ShieldCheck :size="13" />
                      <span>Promote to Active</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>

            <tr v-if="filteredStructures.length === 0">
              <td colspan="10" class="empty-state-cell">
                <Network :size="24" class="empty-icon" />
                <p>No organization structures match the current filters.</p>
              </td>
            </tr>
          </tbody>
        </table>
      </AppDataTable>

      <!-- Floating Bar for Selection -->
      <TableFloatingBar 
        :show="selectedRowIds.length > 0"
        :selected-count="selectedRowIds.length"
        :total-count="filteredStructures.length"
        @delete="handleBatchDelete"
        @close="selectedRowIds = []"
      />
    </div>

    <!-- VIEW 2: INTERACTIVE HIERARCHY TREE EXPLORER -->
    <div v-else-if="viewMode === 'tree' && selectedStructure" class="tree-view-wrapper">
      <!-- Back Bar -->
      <div class="tree-top-bar">
        <button type="button" class="btn-back" @click="handleBackToList">
          <ChevronLeft :size="16" />
          <span>Back to Organization Structures</span>
        </button>

        <div class="tree-top-actions">
          <button 
            type="button" 
            class="btn-secondary-action" 
            @click="router.push('/hr/org-units')"
          >
            <FolderTree :size="14" />
            <span>Manage Units in Directory</span>
          </button>
          <button 
            v-if="selectedStructure.structure_state_lookup_value_id !== 'active'" 
            type="button" 
            class="btn-primary-action"
            @click="handleSetActive(selectedStructure)"
          >
            <ShieldCheck :size="14" />
            <span>Set as Active Blueprint</span>
          </button>
        </div>
      </div>

      <!-- Structure Master Hero Card -->
      <div class="structure-hero-card">
        <div class="hero-left">
          <div class="hero-title-row">
            <span class="hero-code-tag font-mono">{{ selectedStructure.code }}</span>
            <h1 class="hero-name">{{ selectedStructure.name }}</h1>
            <span 
              class="version-pill"
              :class="{
                'state-active': selectedStructure.structure_state_lookup_value_id === 'active',
                'state-draft': selectedStructure.structure_state_lookup_value_id === 'draft',
                'state-superseded': selectedStructure.structure_state_lookup_value_id === 'superseded'
              }"
            >
              <span class="dot-indicator"></span>
              <span class="capitalize">{{ selectedStructure.structure_state_lookup_value_id }}</span>
            </span>
          </div>

          <p class="hero-desc">{{ selectedStructure.description }}</p>

          <div class="hero-meta-grid">
            <div class="meta-item">
              <span class="meta-label">Owning Entity:</span>
              <span class="meta-value">{{ selectedStructure.entity_name }}</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Effective From:</span>
              <span class="meta-value font-mono">{{ selectedStructure.effective_from }}</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Effective To:</span>
              <span class="meta-value font-mono">{{ selectedStructure.effective_to || 'Current (Open)' }}</span>
            </div>
            <div v-if="selectedStructure.superseded_by_code" class="meta-item">
              <span class="meta-label">Superseded By:</span>
              <span class="meta-value font-mono text-primary font-semibold">{{ selectedStructure.superseded_by_code }}</span>
            </div>
          </div>
        </div>

        <div class="hero-stat-card">
          <div class="stat-number">{{ selectedStructure.units_count }}</div>
          <div class="stat-label">Mapped Hierarchy Units</div>
          <div class="stat-subtext">Structure ID: #{{ selectedStructure.id }}</div>
        </div>
      </div>

      <!-- Tree Canvas Panel -->
      <div class="tree-canvas-panel">
        <div class="tree-panel-header">
          <div class="panel-header-left">
            <h2 class="panel-title">Hierarchy Blueprint Graph</h2>
            <p class="panel-subtitle">Explore operational reporting relationships and organizational placements effective within this structure version.</p>
          </div>
          <div class="panel-header-legend">
            <span class="legend-item"><span class="legend-box level-board"></span> Board & Exec</span>
            <span class="legend-item"><span class="legend-box level-division"></span> Division</span>
            <span class="legend-item"><span class="legend-box level-department"></span> Department</span>
            <span class="legend-item"><span class="legend-box level-section"></span> Section</span>
          </div>
        </div>

        <!-- Render Hierarchy Tree Nodes -->
        <div class="tree-nodes-flow">
          <div v-if="hierarchyTrees[selectedStructure.id]" class="tree-root-container">
            <!-- Level 0: Root Node -->
            <div class="tree-node-card node-board">
              <div class="node-badge-type">{{ hierarchyTrees[selectedStructure.id].type }}</div>
              <div class="node-main-title">{{ hierarchyTrees[selectedStructure.id].name }}</div>
              <div class="node-code-path font-mono">{{ hierarchyTrees[selectedStructure.id].code }}</div>

              <div class="node-head-info" v-if="hierarchyTrees[selectedStructure.id].head_name">
                <img :src="hierarchyTrees[selectedStructure.id].head_avatar" class="node-head-avatar" alt="" />
                <div class="node-head-meta">
                  <span class="node-head-name">{{ hierarchyTrees[selectedStructure.id].head_name }}</span>
                  <span class="node-head-role">{{ hierarchyTrees[selectedStructure.id].head_title }}</span>
                </div>
              </div>
            </div>

            <!-- Children connector -->
            <div class="tree-children-wrapper" v-if="hierarchyTrees[selectedStructure.id].children">
              <div 
                v-for="divNode in hierarchyTrees[selectedStructure.id].children" 
                :key="divNode.id" 
                class="division-column"
              >
                <!-- Level 1: Division Node -->
                <div class="tree-node-card node-division">
                  <div class="node-badge-type">{{ divNode.type }}</div>
                  <div class="node-main-title">{{ divNode.name }}</div>
                  <div class="node-code-path font-mono">{{ divNode.code }}</div>

                  <div class="node-head-info" v-if="divNode.head_name">
                    <img :src="divNode.head_avatar" class="node-head-avatar" alt="" />
                    <div class="node-head-meta">
                      <span class="node-head-name">{{ divNode.head_name }}</span>
                      <span class="node-head-role">{{ divNode.head_title }}</span>
                    </div>
                  </div>
                </div>

                <!-- Level 2: Sub-units (Departments & Sections) -->
                <div class="sub-nodes-stack" v-if="divNode.children">
                  <div 
                    v-for="deptNode in divNode.children" 
                    :key="deptNode.id" 
                    class="tree-node-card node-dept"
                  >
                    <div class="node-header-row">
                      <span class="node-badge-type text-xs">{{ deptNode.type }}</span>
                      <span class="node-code-path font-mono text-xs">{{ deptNode.code }}</span>
                    </div>
                    <div class="node-main-title text-sm">{{ deptNode.name }}</div>

                    <div class="node-head-info" v-if="deptNode.head_name">
                      <img :src="deptNode.head_avatar" class="node-head-avatar-sm" alt="" />
                      <div class="node-head-meta">
                        <span class="node-head-name text-xs">{{ deptNode.head_name }}</span>
                        <span class="node-head-role text-xs">{{ deptNode.head_title }}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-else class="tree-empty-state">
            <Layers :size="32" class="text-slate-400 mb-2" />
            <p class="font-medium text-slate-700">No organizational units attached yet to {{ selectedStructure.code }}.</p>
            <p class="text-xs text-slate-500 max-w-sm text-center mt-1">
              Add operational departments or navigate to Organization Units to assign placements to this blueprint.
            </p>
            <button 
              type="button" 
              class="btn-primary-action mt-3"
              @click="router.push('/hr/org-units')"
            >
              <Plus :size="14" />
              <span>Create Organization Unit</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- QUICK CREATE MODAL (Org Structure Architecture - HR_Schema_final-v4.sql lines 968-990) -->
    <QuickCreateModal
      v-model:show="showQuickCreate"
      title="Create Organization Structure"
      saveLabel="Save"
      :showExpandButton="true"
      @save="handleSaveQuickStructure"
      @expand="handleExpandToFullForm"
      @cancel="showQuickCreate = false"
    >
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <FormInput 
          label="Structure Name" 
          v-model="quickForm.name" 
          required 
        />
        <FormSelect
          label="Owning Entity"
          v-model="quickForm.entity_id"
          placeholder="Select Entity"
          :options="[
            { label: 'Haleta Addis Ababa HQ', value: '4' },
            { label: 'QMT Bole', value: '1' },
            { label: 'QMT Mekanisa', value: '2' },
            { label: 'QMT Koye', value: '3' }
          ]"
          required
        />
        <div class="gc-date-field">
          <label class="gc-field-label">Effective From Date <span class="required-star">*</span></label>
          <div class="gc-date-input-wrap">
            <Calendar :size="15" class="gc-cal-icon" />
            <input
              type="date"
              v-model="quickForm.effective_from"
              class="gc-date-input"
              required
            />
            <span class="gc-pill-tag">GC</span>
          </div>
        </div>
        <div class="gc-date-field">
          <label class="gc-field-label">Effective To Date</label>
          <div class="gc-date-input-wrap">
            <Calendar :size="15" class="gc-cal-icon" />
            <input
              type="date"
              v-model="quickForm.effective_to"
              class="gc-date-input"
            />
            <span class="gc-pill-tag">GC</span>
          </div>
        </div>
        <div class="md:col-span-2">
          <FormSelect
            label="Version State"
            v-model="quickForm.structure_state"
            placeholder="Select State"
            :options="[
              { label: 'Active', value: 'active' },
              { label: 'Draft', value: 'draft' }
            ]"
            required
          />
        </div>
      </div>
    </QuickCreateModal>

    <!-- CLONE / DRAFT RESTRUCTURE MODAL -->
    <QuickCreateModal
      v-model:show="showCloneModal"
      title="Draft Restructure Successor"
      saveLabel="Create Restructure Blueprint"
      :showExpandButton="false"
      @save="handleConfirmClone"
      @cancel="showCloneModal = false"
    >
      <div class="clone-modal-content" v-if="structureToClone">
        <p class="text-sm text-slate-600 mb-3">
          Cloning creates a new <strong>draft successor row</strong> in the <code>OrgStructure</code> table based on 
          <span class="font-mono font-semibold">{{ structureToClone.code }}</span>. 
          Historical baselines remain preserved and queryable forever.
        </p>

        <div class="bg-slate-50 border border-slate-200 rounded-lg p-3 text-xs text-slate-700 flex flex-col gap-1.5">
          <div class="flex justify-between">
            <span class="text-slate-500">Source Structure:</span>
            <span class="font-mono font-medium">{{ structureToClone.code }} ({{ structureToClone.name }})</span>
          </div>
          <div class="flex justify-between">
            <span class="text-slate-500">Initial State:</span>
            <span class="text-amber-700 font-semibold">Draft</span>
          </div>
          <div class="flex justify-between">
            <span class="text-slate-500">Units Preserved:</span>
            <span>{{ structureToClone.units_count }} operational units</span>
          </div>
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.org-structures-page {
  padding: 16px 24px;
  background-color: var(--primitive-color-neutral-50, #f8fafc);
  min-height: calc(100vh - 60px);
}

.page-breadcrumb-bar {
  margin-bottom: 12px;
}

.directory-view-wrapper, .tree-view-wrapper {
  animation: fadeIn 0.15s ease;
}

/* Toast */
.quick-toast-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #ecfdf5;
  border: 1px solid #a7f3d0;
  color: #065f46;
  padding: 7px 12px;
  border-radius: 6px;
  font-size: 12.5px;
  margin-bottom: 12px;
}

/* Custom Checkbox */
.custom-checkbox {
  appearance: none;
  -webkit-appearance: none;
  width: 16px;
  height: 16px;
  min-width: 16px;
  min-height: 16px;
  border-radius: 4px;
  border: 1.5px solid #d1d5db;
  background-color: #ffffff;
  cursor: pointer;
  display: inline-grid;
  place-content: center;
  position: relative;
  vertical-align: middle;
  outline: none;
  margin: 0;
  padding: 0;
  transition: all 0.15s ease;
}
.custom-checkbox:hover:not(:checked) {
  border-color: #9ca3af;
  background-color: #f9fafb;
}
.custom-checkbox:checked {
  background-color: #0B529C;
  border-color: #0B529C;
  background-image: url("data:image/svg+xml,%3csvg viewBox='0 0 16 16' fill='none' stroke='white' stroke-width='2.6' stroke-linecap='round' stroke-linejoin='round' xmlns='http://www.w3.org/2000/svg'%3e%3cpolyline points='3.5 8.5 6.5 11.5 12.5 5.5'/%3e%3c/svg%3e");
  background-position: center;
  background-repeat: no-repeat;
  background-size: 75% 75%;
}

/* ERP Table Styles */
.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table th {
  height: 34px;
  padding: 6px 14px;
  background-color: #fafafa;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
}

.erp-table td {
  height: 38px;
  padding: 6px 14px;
  font-size: 13px;
  color: #737373; /* Tertiary color for all subsequent columns */
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.erp-row:hover td {
  background-color: #f8fafc;
}

.row-selected td {
  background-color: #eff6ff !important;
}

.col-checkbox {
  width: 40px;
  text-align: center;
}

.col-name {
  color: #404040;
}

.name-cell-stack {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 500;
  color: #404040; /* Secondary color for the primary identity */
  line-height: 1.25;
}

.table-code-subtext {
  font-size: 11px;
  color: #737373; /* Tertiary color for metadata */
  line-height: 1.2;
}

.sortable {
  cursor: pointer;
  user-select: none;
}
.sortable:hover {
  background-color: #f1f5f9;
}
.th-content {
  display: inline-flex;
  align-items: center;
  gap: 5px;
}
.sort-icon {
  color: #94a3b8;
}

.entity-cell {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12.5px;
  color: #737373; /* Tertiary color */
}

.version-pill {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 2px 9px;
  border-radius: 12px;
  font-size: 11.5px;
  font-weight: 500;
}
.version-pill .dot-indicator {
  width: 6px;
  height: 6px;
  border-radius: 50%;
}

.text-tertiary {
  color: #737373;
  font-size: 13px;
}

.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
  line-height: 1.3;
}

.status-pill-active {
  background-color: #ecfdf5;
  color: #059669;
}

.status-pill-inactive {
  background-color: #f1f5f9;
  color: #64748b;
}

.state-active,
.state-published {
  background-color: #ecfdf5;
  color: #059669;
  border: 1px solid #a7f3d0;
}
.state-active .dot-indicator,
.state-published .dot-indicator { background-color: #10b981; }

.state-draft {
  background-color: #fffbeb;
  color: #d97706;
  border: 1px solid #fde68a;
}
.state-draft .dot-indicator { background-color: #f59e0b; }

.state-superseded {
  background-color: #f1f5f9;
  color: #64748b;
  border: 1px solid #e2e8f0;
}
.state-superseded .dot-indicator { background-color: #94a3b8; }

.successor-tag {
  font-size: 11.5px;
  padding: 1.5px 6px;
  border-radius: 4px;
  background-color: #f1f5f9;
  color: #737373;
}

.units-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #737373;
}

/* Actions */
.btn-primary-create {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 12px;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 12.5px;
  font-weight: 500;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-primary-create:hover { background-color: #094482; }

.btn-action-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #64748b;
  cursor: pointer;
}
.btn-action-dots:hover {
  background: #f1f5f9;
  color: #0f172a;
}

.action-cell-wrapper {
  position: relative;
  display: inline-block;
}

.action-dropdown-menu {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  padding: 4px;
  min-width: 190px;
  z-index: 50;
}

.action-menu-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 8px;
  border: none;
  background: transparent;
  font-size: 12px;
  color: #404040;
  border-radius: 4px;
  cursor: pointer;
  text-align: left;
}
.action-menu-item:hover {
  background-color: #f8fafc;
  color: #0B529C;
}

.filter-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 12px;
  padding: 10px 14px;
  background-color: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}

.empty-state-cell {
  padding: 28px 16px;
  text-align: center;
  color: #737373;
}
.empty-icon {
  margin: 0 auto 6px;
  color: #94a3b8;
}

/* ═══════════════════════════════════════════════════════════
   VIEW 2: TREE EXPLORER & BLUEPRINT CANVAS STYLES
   ═══════════════════════════════════════════════════════════ */
.tree-top-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
}

.btn-back {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: transparent;
  border: none;
  color: #475569;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 6px;
}
.btn-back:hover {
  background-color: #e2e8f0;
  color: #0f172a;
}

.tree-top-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-secondary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 12px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #404040;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
}
.btn-secondary-action:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 12px;
  background-color: #0B529C;
  border: none;
  border-radius: 8px;
  color: #ffffff;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
}
.btn-primary-action:hover {
  background-color: #094482;
}

.structure-hero-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 20px;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 20px;
  margin-bottom: 16px;
}

.hero-left {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.hero-title-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.hero-code-tag {
  font-size: 12px;
  font-weight: 600;
  color: #0B529C;
  background-color: #eff6ff;
  border: 1px solid #bfdbfe;
  padding: 2px 8px;
  border-radius: 6px;
}

.hero-name {
  font-size: 18px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.hero-desc {
  font-size: 12.5px;
  color: #64748b;
  max-width: 680px;
  margin: 0;
  line-height: 1.4;
}

.hero-meta-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  font-size: 12px;
  margin-top: 4px;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 4px;
}
.meta-label {
  color: #737373;
}
.meta-value {
  color: #404040;
  font-weight: 500;
}

.hero-stat-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 18px;
  min-width: 140px;
  flex-shrink: 0;
}
.stat-number {
  font-size: 24px;
  font-weight: 700;
  color: #0B529C;
}
.stat-label {
  font-size: 11.5px;
  font-weight: 500;
  color: #475569;
}
.stat-subtext {
  font-size: 10.5px;
  color: #94a3b8;
  margin-top: 2px;
}

/* Tree Canvas Panel */
.tree-canvas-panel {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 18px 20px;
  overflow-x: auto;
}

.tree-panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-bottom: 14px;
  border-bottom: 1px solid #f1f5f9;
  margin-bottom: 20px;
}

.panel-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.panel-subtitle {
  font-size: 12px;
  color: #737373;
  margin: 2px 0 0;
}

.panel-header-legend {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 11.5px;
  color: #64748b;
}
.legend-item {
  display: flex;
  align-items: center;
  gap: 4px;
}
.legend-box {
  width: 10px;
  height: 10px;
  border-radius: 2px;
}
.level-board { background-color: #0B529C; }
.level-division { background-color: #0284c7; }
.level-department { background-color: #0d9488; }
.level-section { background-color: #64748b; }

/* Tree Nodes Flow */
.tree-root-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 24px;
}

.tree-node-card {
  border-radius: 8px;
  padding: 12px 14px;
  border: 1px solid #e2e8f0;
  background: #ffffff;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  transition: all 0.15s ease;
}
.tree-node-card:hover {
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.08);
  border-color: #cbd5e1;
}

.node-board {
  min-width: 280px;
  border-top: 3px solid #0B529C;
  text-align: center;
}
.node-division {
  min-width: 240px;
  border-top: 3px solid #0284c7;
}
.node-dept {
  border-left: 3px solid #0d9488;
  background-color: #f8fafc;
}

.node-badge-type {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: #64748b;
  margin-bottom: 2px;
}

.node-main-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.node-code-path {
  font-size: 11px;
  color: #94a3b8;
  margin-bottom: 6px;
}

.node-head-info {
  display: flex;
  align-items: center;
  gap: 8px;
  padding-top: 6px;
  border-top: 1px solid #f1f5f9;
  margin-top: 4px;
}

.node-head-avatar {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  object-fit: cover;
}
.node-head-avatar-sm {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  object-fit: cover;
}

.node-head-meta {
  display: flex;
  flex-direction: column;
  text-align: left;
}
.node-head-name {
  font-size: 12px;
  font-weight: 600;
  color: #404040;
}
.node-head-role {
  font-size: 10.5px;
  color: #737373;
}

.tree-children-wrapper {
  display: flex;
  align-items: flex-start;
  gap: 20px;
  width: 100%;
  justify-content: center;
}

.division-column {
  display: flex;
  flex-direction: column;
  gap: 12px;
  flex: 1;
  max-width: 320px;
}

.sub-nodes-stack {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding-left: 12px;
  border-left: 2px dashed #cbd5e1;
  margin-left: 14px;
}

.tree-empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
}

/* Modals */
.quick-modal-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}
.col-span-2 {
  grid-column: span 2;
}

/* GC Date Field & Textarea */
.gc-date-field {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.gc-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.required-star {
  color: #ef4444;
}

.gc-date-input-wrap {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
  height: 38px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #ffffff;
  padding: 0 10px;
  transition: all 0.15s ease;
  box-sizing: border-box;
}

.gc-date-input-wrap:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.gc-cal-icon {
  color: #64748b;
  margin-right: 8px;
  flex-shrink: 0;
}

.gc-date-input {
  flex: 1;
  border: none;
  height: 100%;
  font-size: 13px;
  color: #404040;
  outline: none;
  background: transparent;
}

.gc-pill-tag {
  font-size: 11px;
  font-weight: 600;
  color: #64748b;
  background-color: #f1f5f9;
  padding: 2px 6px;
  border-radius: 4px;
  user-select: none;
}

.scope-textarea {
  width: 100%;
  padding: 8px 12px;
  font-size: 13px;
  color: #404040;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #ffffff;
  outline: none;
  resize: vertical;
  transition: all 0.15s ease;
  font-family: inherit;
  box-sizing: border-box;
}

.scope-textarea:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(2px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
