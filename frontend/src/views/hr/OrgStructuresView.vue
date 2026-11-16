<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import {
  Table, Network, Plus, Search,
  Filter, ArrowUpDown, MoreVertical, Edit2,
  Trash2, Copy, Calendar, CheckCircle2,
  FolderTree, ZoomIn, ZoomOut, RotateCcw,
  PanelLeftClose, PanelLeftOpen, List
} from 'lucide-vue-next';;
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import { useToast } from '../../composables/useToast';

const router = useRouter();
const { toast } = useToast();

// ─── Lookups & Types (HR_Schema_final-v4.sql lines 968–1043) ───
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
  created_at: string;
  state: RowState;
}

export interface StructureTreeNode {
  id: number;
  code: string;
  name: string;
  type: string;
  head_name: string;
  head_avatar: string;
  head_title: string;
  order: number;
  path: string;
  is_visible: boolean;
  children?: StructureTreeNode[];
}

// ─── Breadcrumb ───
const breadcrumbItems = computed(() => [
  { label: 'Organization Structures' }
]);

// ─── Top Tabs: Primary Tab (Figma Node 5603:2799 / BaseTabs Capsule) ───
const activeMainTab = ref<'tree' | 'table'>('tree');

const mainTabs = computed<BaseTabItem<'tree' | 'table'>[]>(() => [
  { id: 'tree', label: 'Tree View', icon: Network },
  { id: 'table', label: 'List View', icon: List }
]);

// ─── Structures Database Records (Aligned with Screenshots) ───
const structures = ref<Array<OrgStructureRecord>>([
  {
    id: 1,
    uuid: 'org-str-001',
    code: 'CORP - 2027',
    name: 'Corporate Blueprint',
    description: 'Master organizational blueprint covering corporate governance and regional directorates.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'QMT Bole Branch',
    structure_state_lookup_value_id: 'active',
    effective_from: 'May 4, 2026',
    effective_to: null,
    superseded_by_id: null,
    superseded_by_code: null,
    created_at: '2026-05-04',
    state: 'active'
  },
  {
    id: 2,
    uuid: 'org-str-002',
    code: 'CORP - 2027',
    name: 'Corporate 2027',
    description: 'Upcoming restructuring plan for Hawassa regional integration.',
    tenant_id: 1,
    entity_id: 2,
    entity_name: 'QMT Hawassa Branch',
    structure_state_lookup_value_id: 'draft',
    effective_from: 'May 4, 2026',
    effective_to: null,
    superseded_by_id: null,
    superseded_by_code: null,
    created_at: '2026-05-04',
    state: 'active'
  },
  {
    id: 3,
    uuid: 'org-str-003',
    code: 'CORP - 2027',
    name: 'Corporate Baseline',
    description: 'Prior operational hierarchy baseline across New York overseas branch.',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'QMT Newyork Branch',
    structure_state_lookup_value_id: 'superseded',
    effective_from: 'May 4, 2026',
    effective_to: 'May 4, 2026',
    superseded_by_id: 1,
    superseded_by_code: 'CORP-2027',
    created_at: '2026-05-04',
    state: 'inactive'
  }
]);

// ─── Active Selected Structure for Org Three View ───
const selectedStructureId = ref<number>(1);
const selectedStructure = computed(() => {
  return structures.value.find(s => s.id === selectedStructureId.value) || structures.value[0];
});

// ─── Available Staff Pool ───
const availableEmployees = [
  { id: 1, name: 'Almaz Ayana', code: 'EMP-00124', title: 'Chief Executive Officer', avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80' },
  { id: 2, name: 'Dawit Tadesse', code: 'EMP-00185', title: 'Director of Operations', avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=80' },
  { id: 3, name: 'Rahel Girma', code: 'EMP-00088', title: 'Chief Financial Officer', avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80' },
  { id: 4, name: 'Fitsum Assefa', code: 'EMP-00101', title: 'Managing Director', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=80' },
  { id: 5, name: 'Solomon Mengistu', code: 'EMP-00142', title: 'HR Director', avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&auto=format&fit=crop&q=80' },
  { id: 6, name: 'Samuel Bekele', code: 'EMP-00198', title: 'Logistics Manager', avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=100&auto=format&fit=crop&q=80' }
];

// ─── Hierarchy Trees per Structure (Aligned Exactly with Screenshot 2) ───
const hierarchyTrees = ref<Record<number, StructureTreeNode>>({
  1: {
    id: 101,
    code: 'OU - EAST',
    name: 'East Region Operations',
    type: 'Department',
    head_name: 'Almaz Ayana',
    head_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80',
    head_title: 'Chief Executive Officer',
    order: 1,
    path: '101',
    is_visible: true,
    children: [
      {
        id: 102,
        code: 'OU - EAST',
        name: 'East Region Operations',
        type: 'Department',
        head_name: 'Almaz Ayana',
        head_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80',
        head_title: 'Chief Executive Officer',
        order: 1,
        path: '101/102',
        is_visible: true,
        children: [
          {
            id: 105,
            code: 'OU - EAST',
            name: 'East Region Operations',
            type: 'Department',
            head_name: 'Almaz Ayana',
            head_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80',
            head_title: 'Chief Executive Officer',
            order: 1,
            path: '101/102/105',
            is_visible: true
          }
        ]
      },
      {
        id: 103,
        code: 'OU - EAST',
        name: 'East Region Operations',
        type: 'Department',
        head_name: 'Almaz Ayana',
        head_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80',
        head_title: 'Chief Executive Officer',
        order: 2,
        path: '101/103',
        is_visible: true,
        children: [
          {
            id: 106,
            code: 'OU - EAST',
            name: 'East Region Operations',
            type: 'Department',
            head_name: 'Almaz Ayana',
            head_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80',
            head_title: 'Chief Executive Officer',
            order: 1,
            path: '101/103/106',
            is_visible: true,
            children: [
              {
                id: 107,
                code: 'OU - EAST',
                name: 'East Region Operations',
                type: 'Department',
                head_name: 'Almaz Ayana',
                head_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80',
                head_title: 'Chief Executive Officer',
                order: 1,
                path: '101/103/106/107',
                is_visible: true
              }
            ]
          }
        ]
      }
    ]
  },
  2: {
    id: 201,
    code: 'OU - HAW',
    name: 'Hawassa Regional Office',
    type: 'Division',
    head_name: 'Dawit Tadesse',
    head_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=80',
    head_title: 'Regional Operations Director',
    order: 1,
    path: '201',
    is_visible: true,
    children: []
  },
  3: {
    id: 301,
    code: 'OU - NY',
    name: 'New York Branch Office',
    type: 'Branch',
    head_name: 'Rahel Girma',
    head_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
    head_title: 'Branch Director',
    order: 1,
    path: '301',
    is_visible: true,
    children: []
  }
});

// ─── Tree Recursive Helpers ───
const countTreeNodes = (node?: StructureTreeNode): number => {
  if (!node) return 0;
  let count = 1;
  if (node.children) {
    for (const child of node.children) {
      count += countTreeNodes(child);
    }
  }
  return count;
};

const activeUnitsMappedCount = computed(() => {
  const tree = hierarchyTrees.value[selectedStructureId.value];
  return countTreeNodes(tree);
});

const findNode = (current: StructureTreeNode, targetId: number): StructureTreeNode | null => {
  if (current.id === targetId) return current;
  if (current.children) {
    for (const child of current.children) {
      const res = findNode(child, targetId);
      if (res) return res;
    }
  }
  return null;
};

const deleteNode = (current: StructureTreeNode, targetId: number): boolean => {
  if (!current.children) return false;
  const idx = current.children.findIndex(c => c.id === targetId);
  if (idx > -1) {
    current.children.splice(idx, 1);
    return true;
  }
  for (const child of current.children) {
    if (deleteNode(child, targetId)) return true;
  }
  return false;
};

// ─── Search & Filters for Tree Left Card & Table ───
const searchQuery = ref('');
const treeSearchQuery = ref('');
const filterStatus = ref('All');
const filterEntity = ref('All');
const filterLifecycle = ref('All');
const currentSort = ref('name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const selectedRowIds = ref<number[]>([]);

const filteredTreeStructures = computed(() => {
  if (!treeSearchQuery.value.trim()) return structures.value;
  const q = treeSearchQuery.value.toLowerCase();
  return structures.value.filter(s => 
    s.name.toLowerCase().includes(q) || 
    s.entity_name.toLowerCase().includes(q) ||
    s.code.toLowerCase().includes(q)
  );
});

const filteredTableStructures = computed(() => {
  return structures.value.filter(s => {
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase();
      const matchesCode = s.code.toLowerCase().includes(q);
      const matchesName = s.name.toLowerCase().includes(q);
      const matchesEntity = s.entity_name.toLowerCase().includes(q);
      if (!matchesCode && !matchesName && !matchesEntity) return false;
    }
    if (filterStatus.value !== 'All') {
      const target = filterStatus.value === 'Published' ? 'active' : filterStatus.value.toLowerCase();
      if (s.structure_state_lookup_value_id !== target) return false;
    }
    if (filterEntity.value !== 'All' && s.entity_name !== filterEntity.value) return false;
    if (filterLifecycle.value !== 'All' && s.state !== filterLifecycle.value.toLowerCase()) return false;
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

// ─── Table Columns (Strict Rule 9 & Rule 14 Compliant) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Name', visible: true, sortable: true },
  { key: 'entity', label: 'Owning Entity', visible: true, sortable: true },
  { key: 'effective_from', label: 'Effective From', visible: true, sortable: true },
  { key: 'effective_to', label: 'Effective Until', visible: true, sortable: true },
  { key: 'status', label: 'Status', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

const getStructureStateColor = (stateId: string): 'success' | 'warning' | 'gray' => {
  switch (stateId) {
    case 'active': return 'success';
    case 'draft': return 'warning';
    case 'superseded': return 'gray';
    default: return 'gray';
  }
};

const handleToggleColumn = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  if (col) col.visible = !col.visible;
};

// ─── Selection for Table ───
const isAllSelected = computed(() => {
  return filteredTableStructures.value.length > 0 && 
    filteredTableStructures.value.every(s => selectedRowIds.value.includes(s.id));
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = filteredTableStructures.value.map(s => s.id);
  }
};

const toggleRowSelection = (id: number) => {
  const index = selectedRowIds.value.indexOf(id);
  if (index > -1) selectedRowIds.value.splice(index, 1);
  else selectedRowIds.value.push(id);
};

const handleBatchDelete = () => {
  structures.value = structures.value.filter(s => !selectedRowIds.value.includes(s.id));
  selectedRowIds.value = [];
  showToast('Selected blueprints removed.');
};

// ─── 3-Dot Menus State Management (Screenshots 3 & 4) ───
const activeStructureMenuId = ref<number | null>(null);
const activeNodeMenuId = ref<number | null>(null);
const activeTableMenuId = ref<number | null>(null);

const toggleStructureMenu = (id: number, e: MouseEvent) => {
  e.stopPropagation();
  closeAllMenus();
  activeStructureMenuId.value = id;
};

const toggleNodeMenu = (id: number, e: MouseEvent) => {
  e.stopPropagation();
  closeAllMenus();
  activeNodeMenuId.value = id;
};

const toggleTableMenu = (id: number, e: MouseEvent) => {
  e.stopPropagation();
  closeAllMenus();
  activeTableMenuId.value = id;
};

const closeAllMenus = () => {
  activeStructureMenuId.value = null;
  activeNodeMenuId.value = null;
  activeTableMenuId.value = null;
};

// ─── Structure Modal (Create & Edit) ───
const showStructureModal = ref(false);
const isEditingStructure = ref(false);
const structureForm = ref({
  id: 0,
  name: '',
  entity_id: '1',
  effective_from: new Date().toISOString().split('T')[0],
  effective_to: '',
  structure_state: 'active' as OrgStructureState
});

const handleOpenCreateStructure = () => {
  closeAllMenus();
  isEditingStructure.value = false;
  structureForm.value = {
    id: 0,
    name: '',
    entity_id: '1',
    effective_from: new Date().toISOString().split('T')[0],
    effective_to: '',
    structure_state: 'active'
  };
  showStructureModal.value = true;
};

const handleEditStructure = (item: OrgStructureRecord) => {
  closeAllMenus();
  isEditingStructure.value = true;
  structureForm.value = {
    id: item.id,
    name: item.name,
    entity_id: String(item.entity_id),
    effective_from: item.effective_from,
    effective_to: item.effective_to || '',
    structure_state: item.structure_state_lookup_value_id
  };
  showStructureModal.value = true;
};

const handleSaveStructure = () => {
  if (!structureForm.value.name.trim()) return;

  const entityNameLookup: Record<string, string> = {
    '1': 'QMT Bole Branch',
    '2': 'QMT Hawassa Branch',
    '3': 'QMT Newyork Branch',
    '4': 'Haleta Addis Ababa HQ'
  };

  if (isEditingStructure.value) {
    const target = structures.value.find(s => s.id === structureForm.value.id);
    if (target) {
      target.name = structureForm.value.name.trim();
      target.entity_id = Number(structureForm.value.entity_id);
      target.entity_name = entityNameLookup[structureForm.value.entity_id] || target.entity_name;
      target.effective_from = structureForm.value.effective_from;
      target.effective_to = structureForm.value.effective_to || null;
      target.structure_state_lookup_value_id = structureForm.value.structure_state;
      showToast(`Structure "${target.name}" updated successfully.`);
    }
  } else {
    const cleanName = structureForm.value.name.trim().toUpperCase();
    const prefix = cleanName.replace(/[^A-Z]/g, '').slice(0, 4) || 'CORP';
    const autoCode = `${prefix} - 2027`;
    const newId = Date.now();

    const newRecord: OrgStructureRecord = {
      id: newId,
      uuid: `org-str-${Date.now().toString().slice(-4)}`,
      code: autoCode,
      name: structureForm.value.name.trim(),
      tenant_id: 1,
      entity_id: Number(structureForm.value.entity_id),
      entity_name: entityNameLookup[structureForm.value.entity_id] || 'QMT Bole Branch',
      structure_state_lookup_value_id: structureForm.value.structure_state,
      effective_from: structureForm.value.effective_from,
      effective_to: structureForm.value.effective_to || null,
      created_at: new Date().toISOString().split('T')[0],
      state: 'active'
    };

    structures.value.unshift(newRecord);
    selectedStructureId.value = newId;

    // Seed default root node
    hierarchyTrees.value[newId] = {
      id: Date.now() + 10,
      code: `OU - ROOT`,
      name: `${newRecord.name} Executive Office`,
      type: 'Department',
      head_name: 'Almaz Ayana',
      head_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80',
      head_title: 'Chief Executive Officer',
      order: 1,
      path: '1',
      is_visible: true,
      children: []
    };

    showToast(`Blueprint "${newRecord.name}" created successfully.`);
  }

  showStructureModal.value = false;
};

const handleDeleteStructure = (id: number) => {
  closeAllMenus();
  structures.value = structures.value.filter(s => s.id !== id);
  if (selectedStructureId.value === id && structures.value.length > 0) {
    selectedStructureId.value = structures.value[0].id;
  }
  showToast('Structure removed from blueprint registry.');
};

// ─── Focus Mode & Active Tree Node Selection ───
const isSidebarCollapsed = ref(false);
const selectedNodeId = ref<number | null>(null);

const toggleSelectNode = (nodeId: number) => {
  if (selectedNodeId.value === nodeId) {
    selectedNodeId.value = null;
  } else {
    selectedNodeId.value = nodeId;
  }
};

// ─── Copy Structure Logic (Image 3) ───
const showCopyModal = ref(false);
const sourceStructureToCopy = ref<OrgStructureRecord | null>(null);
const copyForm = ref({
  name: '',
  entity_id: '1',
  effective_from: new Date().toISOString().split('T')[0],
  clone_hierarchy: true,
  structure_state: 'draft' as OrgStructureState
});

const handleOpenCopyStructure = (item: OrgStructureRecord) => {
  closeAllMenus();
  sourceStructureToCopy.value = item;
  copyForm.value = {
    name: `${item.name} - Copy`,
    entity_id: String(item.entity_id),
    effective_from: new Date().toISOString().split('T')[0],
    clone_hierarchy: true,
    structure_state: 'draft'
  };
  showCopyModal.value = true;
};

// Recursive clone helper for tree nodes
const cloneTreeNode = (node: StructureTreeNode, parentPath: string = ''): StructureTreeNode => {
  const newId = Date.now() + Math.floor(Math.random() * 10000);
  const currentPath = parentPath ? `${parentPath}/${newId}` : `${newId}`;
  return {
    ...node,
    id: newId,
    path: currentPath,
    children: node.children ? node.children.map(child => cloneTreeNode(child, currentPath)) : []
  };
};

const handleSaveCopyStructure = () => {
  if (!sourceStructureToCopy.value || !copyForm.value.name.trim()) return;

  const entityNameLookup: Record<string, string> = {
    '1': 'QMT Bole Branch',
    '2': 'QMT Hawassa Branch',
    '3': 'QMT Newyork Branch',
    '4': 'Haleta Addis Ababa HQ'
  };

  const newId = Date.now();
  const cleanName = copyForm.value.name.trim().toUpperCase();
  const prefix = cleanName.replace(/[^A-Z]/g, '').slice(0, 4) || 'CORP';
  const autoCode = `${prefix} - 2027`;

  const newRecord: OrgStructureRecord = {
    id: newId,
    uuid: `org-str-${Date.now().toString().slice(-4)}`,
    code: autoCode,
    name: copyForm.value.name.trim(),
    tenant_id: sourceStructureToCopy.value.tenant_id,
    entity_id: Number(copyForm.value.entity_id),
    entity_name: entityNameLookup[copyForm.value.entity_id] || sourceStructureToCopy.value.entity_name,
    structure_state_lookup_value_id: 'draft',
    effective_from: copyForm.value.effective_from,
    effective_to: null,
    created_at: new Date().toISOString().split('T')[0],
    state: 'active'
  };

  structures.value.unshift(newRecord);
  selectedStructureId.value = newId;

  if (copyForm.value.clone_hierarchy && hierarchyTrees.value[sourceStructureToCopy.value.id]) {
    hierarchyTrees.value[newId] = cloneTreeNode(hierarchyTrees.value[sourceStructureToCopy.value.id]);
  } else {
    hierarchyTrees.value[newId] = {
      id: Date.now() + 10,
      code: `OU - ROOT`,
      name: `${newRecord.name} Executive Office`,
      type: 'Department',
      head_name: 'Almaz Ayana',
      head_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80',
      head_title: 'Chief Executive Officer',
      order: 1,
      path: '1',
      is_visible: true,
      children: []
    };
  }

  showCopyModal.value = false;
  activeMainTab.value = 'tree';
  showToast(`Blueprint "${newRecord.name}" cloned with full hierarchy in Draft state.`);
};

// ─── Publish Blueprint Action ───
const handlePublishStructure = (item: OrgStructureRecord) => {
  closeAllMenus();
  item.structure_state_lookup_value_id = 'active';
  showToast(`Blueprint "${item.name}" has been published and set to Active.`);
};

// ─── Print / Export Diagram ───
const handlePrintDiagram = () => {
  window.print();
};

// ─── Dynamic Unit Hierarchy Parent Options ───
const flatUnitOptions = computed(() => {
  const tree = hierarchyTrees.value[selectedStructureId.value];
  if (!tree) return [{ label: '- (Root)', value: '' }];
  const list: { label: string; value: string }[] = [{ label: '- (Root)', value: '' }];
  const collect = (node: StructureTreeNode, level = 0) => {
    const indent = level > 0 ? '— '.repeat(level) : '';
    list.push({ label: `${indent}${node.name} (${node.type})`, value: String(node.id) });
    if (node.children) {
      for (const child of node.children) {
        collect(child, level + 1);
      }
    }
  };
  collect(tree);
  return list;
});

// ─── Unit Modal (Create & Edit) ───
const showUnitModal = ref(false);
const isEditingNode = ref(false);
const targetNodeParent = ref<StructureTreeNode | null>(null);
const editingNodeRef = ref<StructureTreeNode | null>(null);

const unitForm = ref({
  name: '',
  type: 'Department',
  head_employee_id: '1',
  parent_id: '',
  order: 1,
  is_visible: true
});

const handleOpenCreateUnitsGlobal = () => {
  closeAllMenus();
  isEditingNode.value = false;
  targetNodeParent.value = null;
  editingNodeRef.value = null;

  unitForm.value = {
    name: 'East Region Operations',
    type: 'Department',
    head_employee_id: '1',
    parent_id: selectedNodeId.value ? String(selectedNodeId.value) : '',
    order: 1,
    is_visible: true
  };
  showUnitModal.value = true;
};

const handleOpenAddUnitForStructure = (item: OrgStructureRecord) => {
  closeAllMenus();
  selectedStructureId.value = item.id;
  activeMainTab.value = 'tree';
  handleOpenCreateUnitsGlobal();
};

const handleAddDivisionToNode = (node: StructureTreeNode) => {
  closeAllMenus();
  isEditingNode.value = false;
  targetNodeParent.value = node;
  editingNodeRef.value = null;

  unitForm.value = {
    name: 'East Region Operations',
    type: 'Department',
    head_employee_id: '1',
    parent_id: String(node.id),
    order: (node.children?.length ?? 0) + 1,
    is_visible: true
  };
  showUnitModal.value = true;
};

const handleEditNode = (node: StructureTreeNode) => {
  closeAllMenus();
  isEditingNode.value = true;
  editingNodeRef.value = node;
  targetNodeParent.value = null;

  const emp = availableEmployees.find(e => e.name === node.head_name);
  unitForm.value = {
    name: node.name,
    type: node.type,
    head_employee_id: emp ? String(emp.id) : '1',
    parent_id: '',
    order: node.order,
    is_visible: node.is_visible
  };
  showUnitModal.value = true;
};

const handleSaveUnit = () => {
  if (!unitForm.value.name.trim()) return;
  const tree = hierarchyTrees.value[selectedStructureId.value];
  const emp = availableEmployees.find(e => String(e.id) === unitForm.value.head_employee_id) || availableEmployees[0];

  if (isEditingNode.value && editingNodeRef.value) {
    editingNodeRef.value.name = unitForm.value.name.trim();
    editingNodeRef.value.type = unitForm.value.type;
    editingNodeRef.value.head_name = emp.name;
    editingNodeRef.value.head_avatar = emp.avatar;
    editingNodeRef.value.head_title = emp.title;
    editingNodeRef.value.order = unitForm.value.order;
    editingNodeRef.value.is_visible = unitForm.value.is_visible;
    showToast(`Unit "${editingNodeRef.value.name}" updated successfully.`);
  } else {
    const newUnitId = Date.now();
    const newNode: StructureTreeNode = {
      id: newUnitId,
      code: 'OU - EAST',
      name: unitForm.value.name.trim(),
      type: unitForm.value.type,
      head_name: emp.name,
      head_avatar: emp.avatar,
      head_title: emp.title,
      order: unitForm.value.order,
      path: '',
      is_visible: unitForm.value.is_visible,
      children: []
    };

    if (!tree) {
      hierarchyTrees.value[selectedStructureId.value] = newNode;
    } else if (targetNodeParent.value) {
      if (!targetNodeParent.value.children) targetNodeParent.value.children = [];
      targetNodeParent.value.children.push(newNode);
    } else if (unitForm.value.parent_id) {
      const parent = findNode(tree, Number(unitForm.value.parent_id));
      if (parent) {
        if (!parent.children) parent.children = [];
        parent.children.push(newNode);
      } else {
        if (!tree.children) tree.children = [];
        tree.children.push(newNode);
      }
    } else {
      if (!tree.children) tree.children = [];
      tree.children.push(newNode);
    }
    showToast(`Unit "${newNode.name}" added to ${selectedStructure.value.name}.`);
  }

  showUnitModal.value = false;
};

const handleDeleteNode = (nodeId: number) => {
  closeAllMenus();
  const tree = hierarchyTrees.value[selectedStructureId.value];
  if (!tree) return;
  if (tree.id === nodeId) {
    showToast('Root executive unit cannot be deleted directly.');
    return;
  }
  const deleted = deleteNode(tree, nodeId);
  if (deleted) {
    showToast('Unit removed from hierarchy tree.');
  }
};

// ─── Canvas Zoom Controls ───
const zoomLevel = ref(0.8);
const handleZoomIn = () => { if (zoomLevel.value < 1.4) zoomLevel.value = +(zoomLevel.value + 0.1).toFixed(1); };
const handleZoomOut = () => { if (zoomLevel.value > 0.5) zoomLevel.value = +(zoomLevel.value - 0.1).toFixed(1); };
const handleResetZoom = () => { zoomLevel.value = 0.8; };

// ─── Toast (Strict useToast Standard) ───
const showToast = (msg: string) => {
  toast.success('Org Structures', msg);
};

onMounted(() => {
  window.addEventListener('click', closeAllMenus);
});

onUnmounted(() => {
  window.removeEventListener('click', closeAllMenus);
});
</script>

<template>
  <div class="org-structures-page">
    <!-- Breadcrumbs -->
    <div class="page-breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ══════════════════════════════════════════════════════════ -->
    <!-- MASTER PAGE HEADER & SECONDARY TABS (Figma 5520:79074)     -->
    <!-- ══════════════════════════════════════════════════════════ -->
    <div class="master-header-card">
      <div class="header-top-row">
        <div class="header-text-block">
          <h1 class="header-main-title">Organization Structures</h1>
          <p class="header-subtitle">
            Manage macro organizational blueprints, effective-dated versions, restructuring plans, and structural hierarchy baselines across enterprise entities.
          </p>
        </div>

        <AppButton 
          variant="primary" 
          @click="handleOpenCreateStructure"
        >
          <template #icon-left><Plus :size="16" /></template>
          Create Structure
        </AppButton>
      </div>

      <div class="header-tabs-row">
        <!-- Primary Tab Group (Figma Node 5603:2799 / BaseTabs Capsule) -->
        <BaseTabs
          v-model="activeMainTab"
          :tabs="mainTabs"
          type="rounded"
          size="sm"
          class="org-primary-tabs"
        />
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════ -->
    <!-- VIEW 1: ORG TABLE TAB (Screenshot 1)                       -->
    <!-- ══════════════════════════════════════════════════════════ -->
    <div v-if="activeMainTab === 'table'" class="table-view-section">
      <AppDataTable
        title=""
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search Name..."
        :showSearch="true"
        :showFilter="true"
        :filterCount="0"
        :showSort="true"
        v-model:currentSort="currentSort"
        v-model:sortOrder="sortOrder"
        :showColumns="true"
        :columns="tableColumns"
        @toggleColumn="handleToggleColumn"
      >
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
              :options="['All', 'QMT Bole Branch', 'QMT Hawassa Branch', 'QMT Newyork Branch']"
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

              <th v-if="isColumnVisible('effective_from')" class="col-period sortable" @click="currentSort = 'effective_from'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>Effective From</span>
                  <ArrowUpDown v-if="currentSort === 'effective_from'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th v-if="isColumnVisible('effective_to')" class="col-period sortable" @click="currentSort = 'effective_to'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>Effective Until</span>
                  <ArrowUpDown v-if="currentSort === 'effective_to'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

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

              <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr 
              v-for="item in filteredTableStructures" 
              :key="item.id"
              class="erp-row cursor-pointer"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
              @click="selectedStructureId = item.id; activeMainTab = 'tree'"
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

              <td v-if="isColumnVisible('effective_from')" class="col-period">
                <span class="text-tertiary">{{ item.effective_from }}</span>
              </td>

              <td v-if="isColumnVisible('effective_to')" class="col-period">
                <span class="text-tertiary">{{ item.effective_to || '— (Current)' }}</span>
              </td>

              <td v-if="isColumnVisible('status')" class="col-status">
                <BaseBadge :color="getStructureStateColor(item.structure_state_lookup_value_id)">
                  {{ item.structure_state_lookup_value_id === 'active' ? 'Published' : (item.structure_state_lookup_value_id === 'draft' ? 'Draft' : 'Superseded') }}
                </BaseBadge>
              </td>

              <td v-if="isColumnVisible('state')" class="col-state">
                <BaseBadge :color="item.state === 'active' ? 'success' : 'gray'">
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </BaseBadge>
              </td>

              <td v-if="isColumnVisible('actions')" class="col-actions" @click.stop>
                <div class="action-cell-wrapper">
                  <button 
                    type="button" 
                    class="btn-action-dots" 
                    @click="toggleTableMenu(item.id, $event)"
                    title="Structure Actions"
                  >
                    <MoreVertical :size="15" />
                  </button>

                  <div v-if="activeTableMenuId === item.id" class="dropdown-popover-menu" @click.stop>
                    <button class="popover-menu-item" @click="handleEditStructure(item)">
                      <Edit2 :size="15" />
                      <span>Edit</span>
                    </button>
                    <button class="popover-menu-item" @click="handleOpenAddUnitForStructure(item)">
                      <Plus :size="15" />
                      <span>Add Unit</span>
                    </button>
                    <button class="popover-menu-item" @click="handleOpenCopyStructure(item)">
                      <Copy :size="15" />
                      <span>Copy Structure</span>
                    </button>
                    <button v-if="item.structure_state_lookup_value_id === 'draft'" class="popover-menu-item item-publish" @click="handlePublishStructure(item)">
                      <CheckCircle2 :size="15" class="text-emerald-600" />
                      <span>Publish</span>
                    </button>
                    <button class="popover-menu-item item-delete" @click="handleDeleteStructure(item.id)">
                      <Trash2 :size="15" />
                      <span>Delete</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </AppDataTable>

      <TableFloatingBar 
        :show="selectedRowIds.length > 0"
        :selected-count="selectedRowIds.length"
        :total-count="structures.length"
        @delete="handleBatchDelete"
        @close="selectedRowIds = []"
      />
    </div>

    <!-- ══════════════════════════════════════════════════════════ -->
    <!-- VIEW 2: ORG THREE VIEW TAB (Screenshots 2, 3, 4)           -->
    <!-- ══════════════════════════════════════════════════════════ -->
    <div v-else-if="activeMainTab === 'tree'" class="tree-view-split-layout" :class="{ 'sidebar-collapsed': isSidebarCollapsed }">
      <!-- ─── LEFT CARD: STRUCTURES LISTER (Screenshot 2) ─── -->
      <div v-show="!isSidebarCollapsed" class="tree-left-card">
        <!-- Search & Filter Row -->
        <div class="left-search-filter-row">
          <div class="input-search-wrapper">
            <Search :size="14" class="icon-search" />
            <input 
              type="text" 
              v-model="treeSearchQuery" 
              placeholder="Search Name..." 
              class="search-text-input"
            />
          </div>
          <button type="button" class="btn-filter-toggle">
            <Filter :size="14" />
            <span>Filter</span>
          </button>
        </div>

        <!-- Vertical Stack of Structure Cards -->
        <div class="structures-vertical-stack">
          <div 
            v-for="item in filteredTreeStructures" 
            :key="item.id"
            class="tree-structure-item-card"
            :class="{ 'item-selected': selectedStructureId === item.id }"
            @click="selectedStructureId = item.id"
          >
            <!-- Card Top Row: Name + Status Pill + 3-Dot Button -->
            <div class="item-card-top-row">
              <div class="item-title-cluster">
                <span class="structure-card-title">{{ item.name }}</span>
                <BaseBadge :color="getStructureStateColor(item.structure_state_lookup_value_id)">
                  {{ item.structure_state_lookup_value_id === 'active' ? 'Published' : (item.structure_state_lookup_value_id === 'draft' ? 'Draft' : 'Superseded') }}
                </BaseBadge>
              </div>

              <!-- 3-Dot Menu Button on Structure Card (Screenshot 3) -->
              <div class="menu-relative-wrapper" @click.stop>
                <button 
                  type="button" 
                  class="btn-card-dots" 
                  @click="toggleStructureMenu(item.id, $event)"
                  title="Structure Options"
                >
                  <MoreVertical :size="15" />
                </button>

                <!-- Structure 3-Dot Floating Menu (Screenshot 3) -->
                <div v-if="activeStructureMenuId === item.id" class="dropdown-popover-menu" @click.stop>
                  <button class="popover-menu-item" @click="handleEditStructure(item)">
                    <Edit2 :size="16" />
                    <span>Edit</span>
                  </button>
                  <button class="popover-menu-item" @click="handleOpenAddUnitForStructure(item)">
                    <Plus :size="16" />
                    <span>Add Unit</span>
                  </button>
                  <button class="popover-menu-item" @click="handleOpenCopyStructure(item)">
                    <Copy :size="16" />
                    <span>Copy Structure</span>
                  </button>
                  <button v-if="item.structure_state_lookup_value_id === 'draft'" class="popover-menu-item item-publish" @click="handlePublishStructure(item)">
                    <CheckCircle2 :size="16" class="text-emerald-600" />
                    <span>Publish</span>
                  </button>
                  <button class="popover-menu-item item-delete" @click="handleDeleteStructure(item.id)">
                    <Trash2 :size="16" />
                    <span>Delete</span>
                  </button>
                </div>
              </div>
            </div>

            <!-- Card Bottom Row: Branch Subtitle -->
            <div class="structure-card-branch-text">
              {{ item.entity_name }}
            </div>
          </div>
        </div>
      </div>

      <!-- ─── RIGHT CARD: HIERARCHY DIAGRAM CANVAS (Screenshot 2) ─── -->
      <div class="tree-right-card">
        <!-- Right Card Header Row -->
        <div class="right-card-header-bar">
          <div class="right-header-left">
            <div class="active-struct-title-row">
              <span class="active-struct-name">{{ selectedStructure.name }}</span>
              <BaseBadge :color="getStructureStateColor(selectedStructure.structure_state_lookup_value_id)">
                {{ selectedStructure.structure_state_lookup_value_id === 'active' ? 'Published' : (selectedStructure.structure_state_lookup_value_id === 'draft' ? 'Draft' : 'Superseded') }}
              </BaseBadge>
            </div>
            <p class="active-struct-subtext">
              {{ selectedStructure.entity_name }} - Effective: {{ selectedStructure.effective_from }} - {{ selectedStructure.effective_to || 'Current' }} - {{ activeUnitsMappedCount }} Units Mapped
            </p>
          </div>

          <div class="right-header-actions-group">
            <!-- Focus Mode Toggle (Hide/Show Left List) -->
            <button 
              type="button" 
              class="btn-header-action" 
              @click="isSidebarCollapsed = !isSidebarCollapsed"
              :title="isSidebarCollapsed ? 'Show Structures List' : 'Focus Mode (Hide List)'"
            >
              <PanelLeftOpen v-if="isSidebarCollapsed" :size="15" />
              <PanelLeftClose v-else :size="15" />
              <span>Focus</span>
            </button>

            <!-- + Create Units Action Button -->
            <button 
              type="button" 
              class="btn-secondary-create-units" 
              @click="handleOpenCreateUnitsGlobal"
            >
              <Plus :size="15" />
              <span>Create Units</span>
            </button>
          </div>
        </div>

        <!-- Canvas Body with Floating Zoom Tools (Figma Node 5520:79204) -->
        <div class="diagram-canvas-viewport">
          <!-- Floating Zoom Bar on Top Right (Figma Node 5520:79204) -->
          <div class="floating-zoom-tools">
            <button type="button" class="zoom-btn" @click="handleZoomOut" title="Zoom Out">
              <ZoomOut :size="14" />
            </button>
            <span class="zoom-level-text">{{ Math.round(zoomLevel * 100) }}%</span>
            <button type="button" class="zoom-btn" @click="handleZoomIn" title="Zoom In">
              <ZoomIn :size="14" />
            </button>
            <div class="zoom-divider"></div>
            <button type="button" class="zoom-btn" @click="handleResetZoom" title="Reset Zoom">
              <RotateCcw :size="14" />
            </button>
          </div>

          <!-- Scaled Diagram Area -->
          <div 
            class="diagram-zoom-wrapper"
            :style="{
              transform: `scale(${zoomLevel})`,
              transformOrigin: 'top center',
              transition: 'transform 0.15s ease-out'
            }"
          >
            <div v-if="hierarchyTrees[selectedStructure.id]" class="tree-hierarchy-flow">
              <!-- LEVEL 0: ROOT NODE CARD (Screenshot 2) -->
              <div class="tree-node-wrapper">
                <div 
                  class="org-unit-node-card cursor-pointer"
                  :class="{ 'node-active': selectedNodeId === hierarchyTrees[selectedStructure.id].id }"
                  @click="toggleSelectNode(hierarchyTrees[selectedStructure.id].id)"
                >
                  <div class="node-card-header">
                    <span class="node-unit-name">{{ hierarchyTrees[selectedStructure.id].name }}</span>
                    
                    <!-- 3-Dot Menu on Node (Screenshot 4) -->
                    <div class="menu-relative-wrapper" @click.stop>
                      <button 
                        type="button" 
                        class="btn-node-dots" 
                        @click="toggleNodeMenu(hierarchyTrees[selectedStructure.id].id, $event)"
                        title="Unit Options"
                      >
                        <MoreVertical :size="14" />
                      </button>

                      <div v-if="activeNodeMenuId === hierarchyTrees[selectedStructure.id].id" class="dropdown-popover-menu" @click.stop>
                        <button class="popover-menu-item" @click="handleEditNode(hierarchyTrees[selectedStructure.id])">
                          <Edit2 :size="16" />
                          <span>Edit</span>
                        </button>
                        <button class="popover-menu-item" @click="handleAddDivisionToNode(hierarchyTrees[selectedStructure.id])">
                          <Plus :size="16" />
                          <span>Add Division</span>
                        </button>
                        <button class="popover-menu-item item-delete" @click="handleDeleteNode(hierarchyTrees[selectedStructure.id].id)">
                          <Trash2 :size="16" />
                          <span>Delete</span>
                        </button>
                      </div>
                    </div>
                  </div>

                  <div class="node-unit-type-subtext">
                    Type: {{ hierarchyTrees[selectedStructure.id].type }}
                  </div>

                  <div class="node-card-divider"></div>

                  <!-- Head Manager Profile Row -->
                  <div class="node-profile-row">
                    <img 
                      :src="hierarchyTrees[selectedStructure.id].head_avatar" 
                      class="node-profile-avatar" 
                      alt="" 
                    />
                    <div class="node-profile-meta">
                      <span class="node-profile-name">{{ hierarchyTrees[selectedStructure.id].head_name }}</span>
                      <span class="node-profile-title">{{ hierarchyTrees[selectedStructure.id].head_title }}</span>
                    </div>
                  </div>
                </div>

                <!-- Vertical stem line -->
                <div 
                  v-if="hierarchyTrees[selectedStructure.id].children && hierarchyTrees[selectedStructure.id].children!.length > 0" 
                  class="connector-stem-vertical"
                ></div>
              </div>

              <!-- LEVEL 1: CHILDREN ROW (Screenshot 2) -->
              <div 
                v-if="hierarchyTrees[selectedStructure.id].children && hierarchyTrees[selectedStructure.id].children!.length > 0" 
                class="tree-children-branches-row"
              >
                <div 
                  v-for="childNode in hierarchyTrees[selectedStructure.id].children" 
                  :key="childNode.id"
                  class="tree-branch-column"
                >
                  <!-- Child Node Card -->
                  <div 
                    class="org-unit-node-card cursor-pointer"
                    :class="{ 'node-active': selectedNodeId === childNode.id }"
                    @click="toggleSelectNode(childNode.id)"
                  >
                    <div class="node-card-header">
                      <span class="node-unit-name">{{ childNode.name }}</span>
                      
                      <!-- 3-Dot Menu on Child Node -->
                      <div class="menu-relative-wrapper" @click.stop>
                        <button 
                          type="button" 
                          class="btn-node-dots" 
                          @click="toggleNodeMenu(childNode.id, $event)"
                          title="Unit Options"
                        >
                          <MoreVertical :size="14" />
                        </button>

                        <div v-if="activeNodeMenuId === childNode.id" class="dropdown-popover-menu" @click.stop>
                          <button class="popover-menu-item" @click="handleEditNode(childNode)">
                            <Edit2 :size="16" />
                            <span>Edit</span>
                          </button>
                          <button class="popover-menu-item" @click="handleAddDivisionToNode(childNode)">
                            <Plus :size="16" />
                            <span>Add Division</span>
                          </button>
                          <button class="popover-menu-item item-delete" @click="handleDeleteNode(childNode.id)">
                            <Trash2 :size="16" />
                            <span>Delete</span>
                          </button>
                        </div>
                      </div>
                    </div>

                    <div class="node-unit-type-subtext">
                      Type: {{ childNode.type }}
                    </div>

                    <div class="node-card-divider"></div>

                    <div class="node-profile-row">
                      <img 
                        :src="childNode.head_avatar" 
                        class="node-profile-avatar" 
                        alt="" 
                      />
                      <div class="node-profile-meta">
                        <span class="node-profile-name">{{ childNode.head_name }}</span>
                        <span class="node-profile-title">{{ childNode.head_title }}</span>
                      </div>
                    </div>
                  </div>

                  <!-- Connector from Child to Sub-Children -->
                  <div 
                    v-if="childNode.children && childNode.children.length > 0" 
                    class="connector-stem-vertical-sm"
                  ></div>

                  <!-- LEVEL 2: SUB-CHILDREN STACK (Screenshot 2 right side) -->
                  <div 
                    v-if="childNode.children && childNode.children.length > 0" 
                    class="sub-children-stack"
                  >
                    <div 
                      v-for="subNode in childNode.children" 
                      :key="subNode.id"
                      class="sub-node-branch-item"
                    >
                      <div 
                        class="org-unit-node-card cursor-pointer"
                        :class="{ 'node-active': selectedNodeId === subNode.id }"
                        @click="toggleSelectNode(subNode.id)"
                      >
                        <div class="node-card-header">
                          <span class="node-unit-name">{{ subNode.name }}</span>
                          
                          <!-- 3-Dot Menu on Sub Node -->
                          <div class="menu-relative-wrapper" @click.stop>
                            <button 
                              type="button" 
                              class="btn-node-dots" 
                              @click="toggleNodeMenu(subNode.id, $event)"
                              title="Unit Options"
                            >
                              <MoreVertical :size="14" />
                            </button>

                            <div v-if="activeNodeMenuId === subNode.id" class="dropdown-popover-menu" @click.stop>
                              <button class="popover-menu-item" @click="handleEditNode(subNode)">
                                <Edit2 :size="16" />
                                <span>Edit</span>
                              </button>
                              <button class="popover-menu-item" @click="handleAddDivisionToNode(subNode)">
                                <Plus :size="16" />
                                <span>Add Division</span>
                              </button>
                              <button class="popover-menu-item item-delete" @click="handleDeleteNode(subNode.id)">
                                <Trash2 :size="16" />
                                <span>Delete</span>
                              </button>
                            </div>
                          </div>
                        </div>

                        <div class="node-unit-type-subtext">
                          Type: {{ subNode.type }}
                        </div>

                        <div class="node-card-divider"></div>

                        <div class="node-profile-row">
                          <img 
                            :src="subNode.head_avatar" 
                            class="node-profile-avatar" 
                            alt="" 
                          />
                          <div class="node-profile-meta">
                            <span class="node-profile-name">{{ subNode.head_name }}</span>
                            <span class="node-profile-title">{{ subNode.head_title }}</span>
                          </div>
                        </div>
                      </div>

                      <!-- Sub-sub children connector -->
                      <div v-if="subNode.children && subNode.children.length > 0" class="connector-stem-vertical-sm"></div>

                      <div v-if="subNode.children && subNode.children.length > 0" class="sub-children-stack">
                        <div 
                          v-for="deepNode in subNode.children" 
                          :key="deepNode.id"
                          class="org-unit-node-card cursor-pointer"
                          :class="{ 'node-active': selectedNodeId === deepNode.id }"
                          @click="toggleSelectNode(deepNode.id)"
                        >
                          <div class="node-card-header">
                            <span class="node-unit-name">{{ deepNode.name }}</span>
                            <div class="menu-relative-wrapper" @click.stop>
                              <button 
                                type="button" 
                                class="btn-node-dots" 
                                @click="toggleNodeMenu(deepNode.id, $event)"
                              >
                                <MoreVertical :size="14" />
                              </button>

                              <div v-if="activeNodeMenuId === deepNode.id" class="dropdown-popover-menu" @click.stop>
                                <button class="popover-menu-item" @click="handleEditNode(deepNode)">
                                  <Edit2 :size="16" />
                                  <span>Edit</span>
                                </button>
                                <button class="popover-menu-item" @click="handleAddDivisionToNode(deepNode)">
                                  <Plus :size="16" />
                                  <span>Add Division</span>
                                </button>
                                <button class="popover-menu-item item-delete" @click="handleDeleteNode(deepNode.id)">
                                  <Trash2 :size="16" />
                                  <span>Delete</span>
                                </button>
                              </div>
                            </div>
                          </div>
                          <div class="node-unit-type-subtext">Type: {{ deepNode.type }}</div>
                          <div class="node-card-divider"></div>
                          <div class="node-profile-row">
                            <img :src="deepNode.head_avatar" class="node-profile-avatar" alt="" />
                            <div class="node-profile-meta">
                              <span class="node-profile-name">{{ deepNode.head_name }}</span>
                              <span class="node-profile-title">{{ deepNode.head_title }}</span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Empty State for Structure with 0 Units -->
            <div v-else class="canvas-empty-state">
              <FolderTree :size="36" class="text-slate-400 mb-2" />
              <h3 class="font-semibold text-slate-700">No Units Attached</h3>
              <p class="text-xs text-slate-500 mt-1 max-w-sm text-center">
                This structure has no departments yet. Click below to add the root operational unit.
              </p>
              <button 
                type="button" 
                class="btn-secondary-create-units mt-3" 
                @click="handleOpenCreateUnitsGlobal"
              >
                <Plus :size="14" />
                <span>Create Units</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════ -->
    <!-- MODAL: CREATE / EDIT STRUCTURE                             -->
    <!-- ══════════════════════════════════════════════════════════ -->
    <QuickCreateModal
      v-model:show="showStructureModal"
      :title="isEditingStructure ? 'Edit Organization Structure' : 'Create Organization Structure'"
      saveLabel="Save"
      :showExpandButton="false"
      @save="handleSaveStructure"
      @cancel="showStructureModal = false"
    >
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <FormInput 
          label="Structure Name" 
          v-model="structureForm.name" 
          required 
        />
        <FormSelect
          label="Owning Entity"
          v-model="structureForm.entity_id"
          placeholder="Select Entity"
          :options="[
            { label: 'QMT Bole Branch', value: '1' },
            { label: 'QMT Hawassa Branch', value: '2' },
            { label: 'QMT Newyork Branch', value: '3' },
            { label: 'Haleta Addis Ababa HQ', value: '4' }
          ]"
        />
        <div class="gc-date-field">
          <label class="gc-field-label">Effective From <span class="required-star">*</span></label>
          <div class="gc-date-input-wrap">
            <Calendar :size="14" class="gc-cal-icon" />
            <input
              type="date"
              v-model="structureForm.effective_from"
              class="gc-date-input"
              required
            />
            <span class="gc-pill-tag">GC</span>
          </div>
        </div>
        <div class="gc-date-field">
          <label class="gc-field-label">Effective Until</label>
          <div class="gc-date-input-wrap">
            <Calendar :size="14" class="gc-cal-icon" />
            <input
              type="date"
              v-model="structureForm.effective_to"
              class="gc-date-input"
            />
            <span class="gc-pill-tag">GC</span>
          </div>
        </div>
      </div>
    </QuickCreateModal>

    <!-- ══════════════════════════════════════════════════════════ -->
    <!-- MODAL: CREATE / EDIT UNIT (Screenshots 1 & 2 Inputs)        -->
    <!-- ══════════════════════════════════════════════════════════ -->
    <QuickCreateModal
      v-model:show="showUnitModal"
      :title="isEditingNode ? 'Edit Organization Unit' : 'Create Organization Unit'"
      saveLabel="Save"
      :showExpandButton="false"
      @save="handleSaveUnit"
      @cancel="showUnitModal = false"
    >
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <FormInput 
          label="Unit Name" 
          v-model="unitForm.name" 
          required 
        />
        <FormSelect
          label="Unit Type"
          v-model="unitForm.type"
          placeholder="Select Type"
          :options="[
            { label: 'Department', value: 'Department' },
            { label: 'Division', value: 'Division' },
            { label: 'Section', value: 'Section' },
            { label: 'Region', value: 'Region' },
            { label: 'Branch', value: 'Branch' }
          ]"
          required
        />
        <FormInput 
          label="Org Structure" 
          :model-value="selectedStructure.name" 
          disabled 
        />
        <FormSelect
          label="Unit Head Manager"
          v-model="unitForm.head_employee_id"
          placeholder="Select Head"
          :options="availableEmployees.map(e => ({ label: `${e.name} (${e.title})`, value: String(e.id) }))"
        />
        <FormSelect
          label="Parent Unit"
          v-model="unitForm.parent_id"
          placeholder="Select Unit"
          :options="flatUnitOptions"
        />
        <FormInput
          label="Order"
          type="number"
          v-model.number="unitForm.order"
        />
        <div class="md:col-span-2 pt-1">
          <FormCheckbox
            label="Show in Organization Diagrams"
            description="When enabled, this operational unit is rendered visually on top-level corporate organizational charts and department reporting trees."
            v-model="unitForm.is_visible"
          />
        </div>
      </div>
    </QuickCreateModal>

    <!-- ══════════════════════════════════════════════════════════ -->
    <!-- MODAL: COPY / CLONE STRUCTURE (Image 3 Workflow)           -->
    <!-- ══════════════════════════════════════════════════════════ -->
    <QuickCreateModal
      v-model:show="showCopyModal"
      title="Copy Organization Structure"
      saveLabel="Clone Blueprint"
      :showExpandButton="false"
      @save="handleSaveCopyStructure"
      @cancel="showCopyModal = false"
    >
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="md:col-span-2">
          <div class="copy-source-banner">
            <Copy :size="15" class="text-blue-600 flex-shrink-0" />
            <span class="text-xs text-slate-700">
              Cloning from source blueprint: <strong>{{ sourceStructureToCopy?.name }}</strong> ({{ sourceStructureToCopy?.entity_name }})
            </span>
          </div>
        </div>

        <FormInput 
          label="New Structure Name" 
          v-model="copyForm.name" 
          required 
        />
        <FormSelect
          label="Target Owning Entity"
          v-model="copyForm.entity_id"
          placeholder="Select Entity"
          :options="[
            { label: 'QMT Bole Branch', value: '1' },
            { label: 'QMT Hawassa Branch', value: '2' },
            { label: 'QMT Newyork Branch', value: '3' },
            { label: 'Haleta Addis Ababa HQ', value: '4' }
          ]"
        />
        <div class="gc-date-field">
          <label class="gc-field-label">Effective From <span class="required-star">*</span></label>
          <div class="gc-date-input-wrap">
            <Calendar :size="14" class="gc-cal-icon" />
            <input
              type="date"
              v-model="copyForm.effective_from"
              class="gc-date-input"
              required
            />
            <span class="gc-pill-tag">GC</span>
          </div>
        </div>
        <FormInput
          label="Lifecycle State"
          model-value="Draft (Restructuring Plan)"
          disabled
        />

        <div class="md:col-span-2 pt-1">
          <FormCheckbox
            label="Clone Complete Unit Hierarchy"
            description="Duplicates all departments, divisions, reporting managers, and organizational trees from the source blueprint into this new draft."
            v-model="copyForm.clone_hierarchy"
          />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.org-structures-page {
  padding: 0;
  background-color: #f8fafc;
  min-height: calc(100vh - 60px);
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
}

.page-breadcrumb-bar {
  margin-bottom: 2px;
}

/* ─── Master Header Card (Figma Node 5520:79074) ─── */
.master-header-card {
  background-color: #ffffff;
  border: 1px solid #E5E5E5;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.header-top-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 20px;
  width: 100%;
}

.header-text-block {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.header-main-title {
  font-size: 20px;
  font-weight: 600;
  color: #404040;
  margin: 0;
  line-height: 1.3;
}

.header-subtitle {
  font-size: 14px;
  color: #737373;
  line-height: 1.45;
  margin: 0;
}

.btn-primary-create-struct {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  background-color: #0B529C;
  border: 1px solid #0B529C;
  border-radius: 8px;
  color: #ffffff;
  font-size: 14px;
  font-weight: 600;
  line-height: 20px;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  cursor: pointer;
  transition: background-color 0.15s ease;
  white-space: nowrap;
}

.btn-primary-create-struct:hover {
  background-color: #09427d;
}

.header-tabs-row {
  width: 100%;
  display: flex;
  align-items: center;
}

/* ─── Table Section ─── */
.table-view-section {
  display: flex;
  flex-direction: column;
}

.filter-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
  padding: 12px;
  background-color: #FAFAFA;
  border-radius: 8px;
  margin-bottom: 8px;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table th {
  background-color: #FAFAFA;
  color: #737373;
  font-size: 12px;
  font-weight: 500;
  padding: 8px 16px;
  text-align: left;
  border-bottom: 1px solid #E5E5E5;
  height: 34px;
}

.erp-table td {
  padding: 8px 16px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #E5E5E5;
  height: 38px;
}

.erp-row:hover td {
  background-color: #FAFAFA;
}

.name-cell-stack {
  display: flex;
  flex-direction: column;
}

.table-name-primary {
  font-weight: 600;
  color: #404040;
}

.table-code-subtext {
  font-size: 11px;
  color: #737373;
}

.text-tertiary {
  color: #737373;
}

.btn-action-dots {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-action-dots:hover {
  background-color: #FAFAFA;
  color: #404040;
}

.action-cell-wrapper {
  position: relative;
}

/* ─── Master-Detail Layout (Figma Node 5520:79083) ─── */
.tree-view-split-layout {
  display: flex;
  gap: 16px;
  height: calc(100vh - 230px);
  min-height: 620px;
}

/* Left Card: Structures Lister (Figma Node 5520:79084) */
.tree-left-card {
  width: 360px;
  min-width: 360px;
  background-color: #ffffff;
  border: 1px solid #E5E5E5;
  border-radius: 16px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.left-search-filter-row {
  display: flex;
  gap: 8px;
}

.input-search-wrapper {
  flex: 1;
  position: relative;
  display: flex;
  align-items: center;
}

.icon-search {
  position: absolute;
  left: 10px;
  color: #737373;
  pointer-events: none;
}

.search-text-input {
  width: 100%;
  height: 38px;
  padding: 0 12px 0 32px;
  border: 1px solid #E5E5E5;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  background-color: #ffffff;
  outline: none;
}

.search-text-input:focus {
  border-color: #0B529C;
}

.btn-filter-toggle {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 14px;
  border: 1px solid #E5E5E5;
  border-radius: 8px;
  background-color: #ffffff;
  color: #404040;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-filter-toggle:hover {
  background-color: #FAFAFA;
}

.structures-vertical-stack {
  display: flex;
  flex-direction: column;
  gap: 10px;
  overflow-y: auto;
}

.tree-structure-item-card {
  background-color: #ffffff;
  border: 1px solid #E5E5E5;
  border-radius: 12px;
  padding: 14px 16px 12px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
  position: relative;
}

.tree-structure-item-card:hover {
  border-color: #d4d4d4;
  background-color: #FAFAFA;
}

.tree-structure-item-card.item-selected {
  border: 1.5px solid #0B529C;
  background-color: #ffffff;
  box-shadow: 0 1px 4px rgba(11, 82, 156, 0.08);
}

.tree-structure-item-card.item-selected .structure-card-title {
  color: #0B529C;
  font-weight: 600;
}

.item-card-top-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.item-title-cluster {
  display: flex;
  align-items: center;
  gap: 8px;
}

.structure-card-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.structure-card-branch-text {
  font-size: 12.5px;
  color: #737373;
}

.btn-card-dots,
.btn-node-dots {
  width: 26px;
  height: 26px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-card-dots:hover,
.btn-node-dots:hover {
  background-color: #FAFAFA;
  color: #404040;
}

/* ─── 3-Dot Floating Popover Menus ─── */
.menu-relative-wrapper {
  position: relative;
}

.dropdown-popover-menu {
  position: absolute;
  right: 0;
  top: calc(100% + 4px);
  background-color: #ffffff;
  border: 1px solid #E5E5E5;
  border-radius: 12px;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.08);
  min-width: 155px;
  padding: 6px;
  z-index: 60;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.popover-menu-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  border: none;
  background: transparent;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.12s ease;
}

.popover-menu-item:hover {
  background-color: #FAFAFA;
}

.popover-menu-item.item-delete {
  color: #E7000B;
}

.popover-menu-item.item-delete:hover {
  background-color: #FEF3F2;
}

.popover-menu-item.item-publish {
  color: #009966;
}

.popover-menu-item.item-publish:hover {
  background-color: #EBFDF2;
}

/* ─── Right Card: Tree Studio (Figma Node 5520:79113) ─── */
.tree-right-card {
  flex: 1;
  background-color: #ffffff;
  border: 1px solid #E5E5E5;
  border-radius: 16px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  position: relative;
}

.right-card-header-bar {
  padding: 16px 24px;
  border-bottom: 1px solid #E5E5E5;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.right-header-left {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.active-struct-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.active-struct-name {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
}

.active-struct-subtext {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

.right-header-actions-group {
  display: flex;
  align-items: center;
  gap: 10px;
}

.btn-header-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 14px;
  background-color: #ffffff;
  color: #404040;
  border: 1px solid #E5E5E5;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-header-action:hover {
  background-color: #FAFAFA;
  border-color: #d4d4d4;
}

.btn-secondary-create-units {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  background-color: #ffffff;
  color: #404040;
  border: 1px solid #E5E5E5;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-secondary-create-units:hover {
  background-color: #FAFAFA;
  border-color: #d4d4d4;
}

/* ─── Floating Zoom Bar (Figma Node 5520:79204) ─── */
.floating-zoom-tools {
  position: absolute;
  top: 16px;
  right: 20px;
  display: flex;
  align-items: center;
  background-color: #ffffff;
  border: 1px solid #E5E5E5;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  padding: 3px 6px;
  gap: 4px;
  z-index: 30;
}

.zoom-btn {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.zoom-btn:hover {
  background-color: #FAFAFA;
  color: #404040;
}

.zoom-level-text {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  min-width: 40px;
  text-align: center;
}

.zoom-divider {
  width: 1px;
  height: 16px;
  background-color: #E5E5E5;
}

/* ─── Diagram Viewport ─── */
.diagram-canvas-viewport {
  flex: 1;
  position: relative;
  overflow: auto;
  padding: 40px 24px 60px;
  background-color: #ffffff;
  display: flex;
  justify-content: center;
}

.diagram-zoom-wrapper {
  display: inline-block;
  min-width: 100%;
}

.tree-hierarchy-flow {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0;
}

.tree-node-wrapper {
  display: flex;
  flex-direction: column;
  align-items: center;
}

/* ─── Individual Org Node Card (Figma Node 5520:79115) ─── */
.org-unit-node-card {
  width: 280px;
  background-color: #ffffff;
  border: 1px solid #E5E5E5;
  border-radius: 12px;
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  transition: all 0.15s ease;
  position: relative;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
}

.org-unit-node-card:hover {
  border-color: #d4d4d4;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.06);
}

.org-unit-node-card.node-active {
  border: 1.5px solid #0B529C;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.1);
}

.node-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.node-unit-name {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.node-unit-type-subtext {
  font-size: 12px;
  color: #737373;
  margin-top: 2px;
}

.node-card-divider {
  height: 1px;
  background-color: #E5E5E5;
  margin: 10px 0 12px;
  width: 100%;
}

.node-profile-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.node-profile-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
}

.node-profile-meta {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.node-profile-name {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.node-profile-title {
  font-size: 12px;
  color: #737373;
}

/* ─── Connecting Tree Lines ─── */
.connector-stem-vertical {
  width: 2px;
  height: 32px;
  background-color: #E5E5E5;
}

.connector-stem-vertical-sm {
  width: 2px;
  height: 24px;
  background-color: #E5E5E5;
}

.tree-children-branches-row {
  display: flex;
  gap: 40px;
  position: relative;
  padding-top: 24px;
}

.tree-children-branches-row::before {
  content: '';
  position: absolute;
  top: 0;
  left: 140px;
  right: 140px;
  height: 2px;
  background-color: #E5E5E5;
}

.tree-branch-column {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
}

.tree-branch-column::before {
  content: '';
  position: absolute;
  top: -24px;
  left: 50%;
  width: 2px;
  height: 24px;
  background-color: #E5E5E5;
  transform: translateX(-50%);
}

.sub-children-stack {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
}

.sub-node-branch-item {
  display: flex;
  flex-direction: column;
  align-items: center;
}

/* Ethiopian GC Date field */
.gc-date-field {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.gc-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.required-star {
  color: #E7000B;
}

.gc-date-input-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.gc-cal-icon {
  position: absolute;
  left: 10px;
  color: #737373;
  pointer-events: none;
}

.gc-date-input {
  width: 100%;
  height: 38px;
  padding: 0 42px 0 32px;
  border: 1px solid #E5E5E5;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  outline: none;
}

.gc-date-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.gc-pill-tag {
  position: absolute;
  right: 8px;
  background-color: #FAFAFA;
  color: #737373;
  font-size: 11px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 4px;
  pointer-events: none;
}

.custom-checkbox {
  width: 15px;
  height: 15px;
  cursor: pointer;
}

.canvas-empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
}

@media print {
  .page-breadcrumb-bar,
  .master-header-card,
  .tree-left-card,
  .right-header-actions-group,
  .floating-zoom-tools {
    display: none !important;
  }
  .tree-view-split-layout {
    height: auto !important;
    display: block !important;
  }
  .tree-right-card {
    border: none !important;
    box-shadow: none !important;
  }
  .diagram-canvas-viewport {
    padding: 0 !important;
  }
}
</style>
