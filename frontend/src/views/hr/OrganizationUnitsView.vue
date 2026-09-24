<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { 
  FolderTree, Plus, Search, Filter, ArrowUpDown, ChevronDown, 
  MoreVertical, Edit2, Trash2, Eye, Copy, Check, Calendar, 
  CheckCircle2, AlertCircle, ChevronLeft, ChevronRight,
  Building2, Layers, Network, User, UserCheck, ShieldCheck,
  Clock, ArrowRight, CornerDownRight, Users, UserPlus
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

// ─── Lookups & Types (HR_Schema_final-v4.sql lines 991–1043) ───
export type OrgUnitType = 
  | 'department' | 'section' | 'team' | 'unit' | 'division' 
  | 'region' | 'project_office' | 'branch' | 'office' | 'outlet' 
  | 'cluster' | 'board' | 'committee' | 'other';

export type RowState = 'active' | 'inactive';

export interface UnitHeadRecord {
  id: number;
  uuid: string;
  organization_unit_id: number;
  employee_id: number;
  employee_name: string;
  employee_number: string;
  employee_avatar: string;
  job_title: string;
  start_date: string;
  end_date?: string | null;
  tenure: string;
  state: RowState;
}

export interface OrganizationUnitRecord {
  id: number;
  uuid: string;
  code: string;
  name: string;
  description?: string;
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  organization_unit_type_lookup_value_id: OrgUnitType;
  org_structure_id: number;
  org_structure_code: string;
  org_structure_name: string;
  parent_id?: number | null;
  parent_name?: string | null;
  order: number;
  is_visible: boolean;
  path: string;
  effective_from: string;
  effective_to?: string | null;
  current_head?: UnitHeadRecord | null;
  heads_history: UnitHeadRecord[];
  state: RowState;
}

// ─── Breadcrumb Configuration (Rule: Exact Page Name from Sidebar Only, Zero Section Titles) ───
const breadcrumbItems = computed(() => {
  if (viewMode.value === 'detail' && selectedUnit.value) {
    return [
      { label: 'Organization Units', onClick: () => { viewMode.value = 'list'; selectedUnit.value = null; } },
      { label: selectedUnit.value.name, current: true }
    ];
  }
  return [
    { label: 'Organization Units' }
  ];
});

// ─── State Management ───
const viewMode = ref<'list' | 'detail'>('list');
const selectedUnit = ref<OrganizationUnitRecord | null>(null);
const searchQuery = ref('');
const filterStructure = ref('All');
const filterType = ref('All');
const filterState = ref('All');
const currentSort = ref('name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const selectedRowIds = ref<number[]>([]);
const selectedHeadRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const activeHeadMenuId = ref<number | null>(null);
const showQuickCreate = ref(false);
const showAppointModal = ref(false);
const quickActionToast = ref<string | null>(null);

// ─── Table Columns Definition (Single Information & Name-First Rule) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Name', visible: true, sortable: true },
  { key: 'type', label: 'Unit Type', visible: true, sortable: true },
  { key: 'parent', label: 'Parent Unit', visible: true, sortable: true },
  { key: 'current_head', label: 'Current Manager', visible: true, sortable: false },
  { key: 'org_structure', label: 'Blueprint', visible: false, sortable: true },
  { key: 'is_visible', label: 'Diagram Visibility', visible: false, sortable: true },
  { key: 'path', label: 'Path', visible: false, sortable: false },
  { key: 'effective_from', label: 'Effective Date', visible: false, sortable: true },
  { key: 'state', label: 'State', visible: false, sortable: true },
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

// ─── Staff Pool for Manager Appointments ───
const availableEmployees = [
  { id: 1, name: 'Fitsum Assefa', code: 'EMP-00101', title: 'Managing Director / CEO', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=80' },
  { id: 2, name: 'Almaz Ayana', code: 'EMP-00124', title: 'Senior Accountant', avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80' },
  { id: 3, name: 'Tigist Alemu', code: 'EMP-0022', title: 'Treasury Supervisor', avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80' },
  { id: 4, name: 'Dawit Tadesse', code: 'EMP-00185', title: 'Operations Lead', avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=80' },
  { id: 5, name: 'Raleh Girma', code: 'EMP-00088', title: 'Finance Director', avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80' },
  { id: 6, name: 'Solomon Mengistu', code: 'EMP-00142', title: 'HR Director', avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&auto=format&fit=crop&q=80' },
  { id: 7, name: 'Samuel Bekele', code: 'EMP-00198', title: 'Supply Chain Manager', avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=100&auto=format&fit=crop&q=80' }
];

// ─── Mock Database Data (Aligned Exactly with Screenshot 3) ───
const units = ref<Array<OrganizationUnitRecord>>([
  {
    id: 1,
    uuid: 'ou-001',
    code: 'OU - EAST',
    name: 'East Region Operations',
    description: 'Regional operations across Eastern branch offices.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    organization_unit_type_lookup_value_id: 'department',
    org_structure_id: 1,
    org_structure_code: 'CORP - 2027',
    org_structure_name: 'Corporate 2027',
    parent_id: null,
    parent_name: null,
    order: 1,
    is_visible: true,
    path: '1',
    effective_from: '2026-05-04',
    effective_to: null,
    current_head: {
      id: 101,
      uuid: 'ou-head-101',
      organization_unit_id: 1,
      employee_id: 4,
      employee_name: 'Dawit Tadesse',
      employee_number: 'EMP-00185',
      employee_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=80',
      job_title: 'Operations Lead',
      start_date: '2024-01-10',
      end_date: null,
      tenure: '2 yrs',
      state: 'active'
    },
    heads_history: [],
    state: 'active'
  },
  {
    id: 2,
    uuid: 'ou-002',
    code: 'OU - HR',
    name: 'Human Resources',
    description: 'Central talent management and workforce relations.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    organization_unit_type_lookup_value_id: 'section',
    org_structure_id: 1,
    org_structure_code: 'CORP - 2027',
    org_structure_name: 'Corporate 2027',
    parent_id: null,
    parent_name: null,
    order: 2,
    is_visible: true,
    path: '2',
    effective_from: '2026-05-04',
    effective_to: null,
    current_head: {
      id: 102,
      uuid: 'ou-head-102',
      organization_unit_id: 2,
      employee_id: 5,
      employee_name: 'Raleh Girma',
      employee_number: 'EMP-00088',
      employee_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80',
      job_title: 'HR Manager',
      start_date: '2023-01-10',
      end_date: null,
      tenure: '3 yrs',
      state: 'active'
    },
    heads_history: [],
    state: 'active'
  },
  {
    id: 3,
    uuid: 'ou-003',
    code: 'CORP - FC',
    name: 'Finance & Corporate Services',
    description: 'Corporate finance and audit accounting.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    organization_unit_type_lookup_value_id: 'region',
    org_structure_id: 1,
    org_structure_code: 'CORP - 2027',
    org_structure_name: 'Corporate 2027',
    parent_id: 2,
    parent_name: 'Human Resources',
    order: 3,
    is_visible: true,
    path: '2.1',
    effective_from: '2026-05-04',
    effective_to: null,
    current_head: {
      id: 103,
      uuid: 'ou-head-103',
      organization_unit_id: 3,
      employee_id: 6,
      employee_name: 'Solomon Mengistu',
      employee_number: 'EMP-00142',
      employee_avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&auto=format&fit=crop&q=80',
      job_title: 'Finance Lead',
      start_date: '2023-05-01',
      end_date: null,
      tenure: '3 yrs',
      state: 'active'
    },
    heads_history: [],
    state: 'active'
  },
  {
    id: 6,
    uuid: 'ou-006',
    code: 'OU-PAY',
    name: 'Payroll & Statutory Remittances',
    description: 'Monthly salary disbursements, tax deductions, and POESSA pension withholdings.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    organization_unit_type_lookup_value_id: 'section',
    org_structure_id: 1,
    org_structure_code: 'CORP-2026',
    org_structure_name: 'Corporate Blueprint 2026',
    parent_id: 2,
    parent_name: 'Finance & Corporate Services',
    order: 1,
    is_visible: true,
    path: '2/6',
    effective_from: '2026-01-01',
    effective_to: null,
    current_head: {
      id: 601,
      uuid: 'ou-head-601',
      organization_unit_id: 6,
      employee_id: 3,
      employee_name: 'Tigist Alemu',
      employee_number: 'EMP-0022',
      employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
      job_title: 'Payroll Officer',
      start_date: '2021-09-15',
      end_date: null,
      tenure: '4 yrs 6 mos',
      state: 'active'
    },
    heads_history: [
      {
        id: 601,
        uuid: 'ou-head-601',
        organization_unit_id: 6,
        employee_id: 3,
        employee_name: 'Tigist Alemu',
        employee_number: 'EMP-0022',
        employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
        job_title: 'Payroll Officer',
        start_date: '2021-09-15',
        end_date: null,
        tenure: '4 yrs 6 mos',
        state: 'active'
      },
      {
        id: 602,
        uuid: 'ou-head-602',
        organization_unit_id: 6,
        employee_id: 2,
        employee_name: 'Almaz Ayana',
        employee_number: 'EMP-00124',
        employee_avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80',
        job_title: 'Senior Accountant',
        start_date: '2021-01-01',
        end_date: '2021-09-14',
        tenure: '8 mos',
        state: 'active'
      }
    ],
    state: 'active'
  },
  {
    id: 8,
    uuid: 'ou-008',
    code: 'OU-EAST',
    name: 'East Region Operations',
    description: 'Regional distribution, customer relationship desks, and supply operations across eastern zones.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    organization_unit_type_lookup_value_id: 'region',
    org_structure_id: 2,
    org_structure_code: 'REGIONAL-2026',
    org_structure_name: 'Regional Operations 2026',
    parent_id: null,
    parent_name: null,
    order: 1,
    is_visible: true,
    path: '8',
    effective_from: '2026-01-01',
    effective_to: null,
    current_head: {
      id: 801,
      uuid: 'ou-head-801',
      organization_unit_id: 8,
      employee_id: 4,
      employee_name: 'Dawit Tadesse',
      employee_number: 'EMP-00185',
      employee_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=80',
      job_title: 'Regional Operations Director',
      start_date: '2026-02-17',
      end_date: null,
      tenure: '1 mo',
      state: 'active'
    },
    heads_history: [
      {
        id: 801,
        uuid: 'ou-head-801',
        organization_unit_id: 8,
        employee_id: 4,
        employee_name: 'Dawit Tadesse',
        employee_number: 'EMP-00185',
        employee_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=80',
        job_title: 'Regional Operations Director',
        start_date: '2026-02-17',
        end_date: null,
        tenure: '1 mo',
        state: 'active'
      }
    ],
    state: 'active'
  },
  {
    id: 9,
    uuid: 'ou-009',
    code: 'OU-PAY-E',
    name: 'Payroll East Regional Desk',
    description: 'Disbursing operational wages for field agents and distribution drivers across East Region.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    organization_unit_type_lookup_value_id: 'section',
    org_structure_id: 2,
    org_structure_code: 'REGIONAL-2026',
    org_structure_name: 'Regional Operations 2026',
    parent_id: 8,
    parent_name: 'East Region Operations',
    order: 1,
    is_visible: true,
    path: '8/9',
    effective_from: '2026-01-01',
    effective_to: null,
    current_head: null,
    heads_history: [],
    state: 'active'
  }
]);

// ─── Filtering & Sorting ───
const activeFilterCount = computed(() => {
  let count = 0;
  if (filterStructure.value !== 'All') count++;
  if (filterType.value !== 'All') count++;
  if (filterState.value !== 'All') count++;
  return count;
});

const filteredUnits = computed(() => {
  return units.value.filter(u => {
    // Search
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase();
      const matchesCode = u.code.toLowerCase().includes(q);
      const matchesName = u.name.toLowerCase().includes(q);
      const matchesHead = u.current_head?.employee_name.toLowerCase().includes(q);
      if (!matchesCode && !matchesName && !matchesHead) return false;
    }
    // Filter Structure
    if (filterStructure.value !== 'All' && u.org_structure_code !== filterStructure.value) {
      return false;
    }
    // Filter Type
    if (filterType.value !== 'All' && u.organization_unit_type_lookup_value_id !== filterType.value.toLowerCase()) {
      return false;
    }
    // Filter State
    if (filterState.value !== 'All' && u.state !== filterState.value.toLowerCase()) {
      return false;
    }
    return true;
  }).sort((a, b) => {
    let valA: any = a[currentSort.value as keyof OrganizationUnitRecord] ?? '';
    let valB: any = b[currentSort.value as keyof OrganizationUnitRecord] ?? '';
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
  return filteredUnits.value.length > 0 && 
    filteredUnits.value.every(u => selectedRowIds.value.includes(u.id));
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = filteredUnits.value.map(u => u.id);
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

// Child Sub-table Selection Management
const isAllHeadsSelected = computed(() => {
  if (!selectedUnit.value) return false;
  return selectedUnit.value.heads_history.length > 0 &&
    selectedUnit.value.heads_history.every(h => selectedHeadRowIds.value.includes(h.id));
});

const toggleSelectAllHeads = () => {
  if (!selectedUnit.value) return;
  if (isAllHeadsSelected.value) {
    selectedHeadRowIds.value = [];
  } else {
    selectedHeadRowIds.value = selectedUnit.value.heads_history.map(h => h.id);
  }
};

const toggleHeadSelection = (id: number) => {
  const index = selectedHeadRowIds.value.indexOf(id);
  if (index > -1) {
    selectedHeadRowIds.value.splice(index, 1);
  } else {
    selectedHeadRowIds.value.push(id);
  }
};

// ─── Action Handlers ───
const toggleActionMenu = (id: number, e: MouseEvent) => {
  e.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const toggleHeadMenu = (id: number, e: MouseEvent) => {
  e.stopPropagation();
  activeHeadMenuId.value = activeHeadMenuId.value === id ? null : id;
};

const closeMenus = () => {
  activeActionMenuId.value = null;
  activeHeadMenuId.value = null;
};

const viewUnitDetail = (item: OrganizationUnitRecord) => {
  closeMenus();
  selectedUnit.value = item;
  selectedHeadRowIds.value = [];
  viewMode.value = 'detail';
};

const handleBackToList = () => {
  viewMode.value = 'list';
  selectedUnit.value = null;
  selectedHeadRowIds.value = [];
};

// Quick Create Form State
// Quick Create Form State (Zero Manual Code Input Standard)
const quickForm = ref({
  org_structure_code: 'CORP-2026',
  name: '',
  type: 'department',
  parent_id: '',
  head_employee_id: '',
  is_visible: true
});

const handleSaveQuickUnit = () => {
  if (!quickForm.value.name.trim()) return;

  const parentUnit = units.value.find(u => String(u.id) === quickForm.value.parent_id);
  const headEmp = availableEmployees.find(e => String(e.id) === quickForm.value.head_employee_id);

  const newUnitId = Date.now();
  const parentPath = parentUnit ? parentUnit.path : '';
  const newPath = parentPath ? `${parentPath}/${newUnitId}` : String(newUnitId);

  const cleanPrefix = quickForm.value.name.trim().replace(/[^a-zA-Z0-9]/g, '').slice(0, 4).toUpperCase() || 'UNIT';
  const autoCode = `OU - ${cleanPrefix}`;

  let initialHead: UnitHeadRecord | null = null;
  let headsHistory: UnitHeadRecord[] = [];

  if (headEmp) {
    initialHead = {
      id: Date.now() + 1,
      uuid: `ou-head-${Date.now()}`,
      organization_unit_id: newUnitId,
      employee_id: headEmp.id,
      employee_name: headEmp.name,
      employee_number: headEmp.code,
      employee_avatar: headEmp.avatar,
      job_title: headEmp.title,
      start_date: new Date().toISOString().split('T')[0],
      end_date: null,
      tenure: 'Current appointment',
      state: 'active'
    };
    headsHistory.push(initialHead);
  }

  const newRecord: OrganizationUnitRecord = {
    id: newUnitId,
    uuid: `ou-${Date.now().toString().slice(-4)}`,
    code: autoCode,
    name: quickForm.value.name.trim(),
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    organization_unit_type_lookup_value_id: quickForm.value.type as OrgUnitType,
    org_structure_id: quickForm.value.org_structure_code === 'CORP-2026' ? 1 : 2,
    org_structure_code: quickForm.value.org_structure_code,
    org_structure_name: quickForm.value.org_structure_code === 'CORP-2026' ? 'Corporate Blueprint 2026' : 'Regional Operations 2026',
    parent_id: parentUnit ? parentUnit.id : null,
    parent_name: parentUnit ? parentUnit.name : null,
    order: 1,
    is_visible: quickForm.value.is_visible,
    path: newPath,
    effective_from: new Date().toISOString().split('T')[0],
    effective_to: null,
    current_head: initialHead,
    heads_history: headsHistory,
    state: 'active'
  };

  units.value.unshift(newRecord);
  showQuickCreate.value = false;

  // Reset form
  quickForm.value = {
    org_structure_code: 'CORP-2026',
    code: '',
    name: '',
    type: 'department',
    parent_id: '',
    head_employee_id: '',
    is_visible: true
  };

  showToast(`Organization unit ${newRecord.code} (${newRecord.name}) created successfully.`);
};

const handleExpandToFullForm = () => {
  showQuickCreate.value = false;
  router.push({
    path: '/hr/org-structures/create',
    query: {
      tab: 'units',
      unit_name: quickForm.value.name,
      unit_type: quickForm.value.type,
      org_structure: quickForm.value.org_structure_code
    }
  });
};

// Appoint Head State & Workflow
const appointForm = ref({
  employee_id: '',
  start_date: new Date().toISOString().split('T')[0]
});

const openAppointModal = (unit: OrganizationUnitRecord) => {
  closeMenus();
  selectedUnit.value = unit;
  appointForm.value = {
    employee_id: '',
    start_date: new Date().toISOString().split('T')[0]
  };
  showAppointModal.value = true;
};

const handleSaveAppointHead = () => {
  if (!selectedUnit.value || !appointForm.value.employee_id) return;

  const emp = availableEmployees.find(e => String(e.id) === appointForm.value.employee_id);
  if (!emp) return;

  const unit = selectedUnit.value;
  const newStartDate = appointForm.value.start_date;

  // 1. Stamp end_date on incumbent head if one exists
  if (unit.current_head) {
    const prevIncumbent = unit.heads_history.find(h => h.id === unit.current_head!.id);
    if (prevIncumbent) {
      prevIncumbent.end_date = newStartDate;
    }
  }

  // 2. Add new head row
  const newHeadRecord: UnitHeadRecord = {
    id: Date.now(),
    uuid: `ou-head-${Date.now()}`,
    organization_unit_id: unit.id,
    employee_id: emp.id,
    employee_name: emp.name,
    employee_number: emp.code,
    employee_avatar: emp.avatar,
    job_title: emp.title,
    start_date: newStartDate,
    end_date: null,
    tenure: 'Active incumbent',
    state: 'active'
  };

  unit.heads_history.unshift(newHeadRecord);
  unit.current_head = newHeadRecord;

  showAppointModal.value = false;
  showToast(`Appointed ${emp.name} as manager of ${unit.name}. Previous tenure updated.`);
};

const showToast = (msg: string) => {
  quickActionToast.value = msg;
  setTimeout(() => {
    quickActionToast.value = null;
  }, 4000);
};

// Batch deletions
const handleBatchDeleteUnits = () => {
  units.value = units.value.filter(u => !selectedRowIds.value.includes(u.id));
  selectedRowIds.value = [];
  showToast('Selected organization units removed.');
};

const handleBatchDeleteHeads = () => {
  if (!selectedUnit.value) return;
  selectedUnit.value.heads_history = selectedUnit.value.heads_history.filter(h => !selectedHeadRowIds.value.includes(h.id));
  if (selectedUnit.value.current_head && selectedHeadRowIds.value.includes(selectedUnit.value.current_head.id)) {
    selectedUnit.value.current_head = selectedUnit.value.heads_history.find(h => !h.end_date) || null;
  }
  selectedHeadRowIds.value = [];
  showToast('Selected leadership records removed.');
};

onMounted(() => {
  window.addEventListener('click', closeMenus);
});

onUnmounted(() => {
  window.removeEventListener('click', closeMenus);
});
</script>

<template>
  <div class="org-units-page">
    <!-- Breadcrumbs -->
    <div class="page-breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Toast Notification -->
    <div v-if="quickActionToast" class="quick-toast-banner">
      <CheckCircle2 :size="15" class="text-emerald-600" />
      <span>{{ quickActionToast }}</span>
    </div>

    <!-- VIEW 1: ORGANIZATION UNITS DIRECTORY TABLE -->
    <div v-if="viewMode === 'list'" class="directory-view-wrapper">
      <AppDataTable
        title="Organization Units"
        subtitle="Manage daily operational departments, divisions, branches, regional offices, and section hierarchies with current unit managers."
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
            <span>Create Organization Unit</span>
          </button>
        </template>

        <template #filter-panel>
          <div class="filter-grid">
            <FormSelect
              label="Org Blueprint"
              v-model="filterStructure"
              :options="['All', 'CORP-2026', 'REGIONAL-2026']"
            />
            <FormSelect
              label="Unit Type"
              v-model="filterType"
              :options="['All', 'Department', 'Division', 'Section', 'Region', 'Team']"
            />
            <FormSelect
              label="Record State"
              v-model="filterState"
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

              <th v-if="isColumnVisible('type')" class="col-type">Unit Type</th>

              <th v-if="isColumnVisible('parent')" class="col-parent">Parent Unit</th>

              <th v-if="isColumnVisible('current_head')" class="col-head">Current Manager</th>

              <th v-if="isColumnVisible('org_structure')" class="col-struct">Org Blueprint</th>

              <th v-if="isColumnVisible('is_visible')" class="col-visible">Diagram Visible</th>

              <th v-if="isColumnVisible('path')" class="col-path">Path</th>

              <th v-if="isColumnVisible('effective_from')" class="col-effective">Effective Date</th>

              <th v-if="isColumnVisible('state')" class="col-status">State</th>

              <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr 
              v-for="item in filteredUnits" 
              :key="item.id"
              class="erp-row cursor-pointer"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
              @click="viewUnitDetail(item)"
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

              <td v-if="isColumnVisible('type')" class="col-type">
                <span class="text-tertiary capitalize">{{ item.organization_unit_type_lookup_value_id }}</span>
              </td>

              <td v-if="isColumnVisible('parent')" class="col-parent">
                <span class="text-tertiary">{{ item.parent_name || '- (Root)' }}</span>
              </td>

              <td v-if="isColumnVisible('current_head')" class="col-head">
                <span class="text-tertiary">{{ item.current_head?.employee_name || '—' }}</span>
              </td>

              <td v-if="isColumnVisible('org_structure')" class="col-struct">
                <span class="struct-tag font-mono">{{ item.org_structure_code }}</span>
              </td>

              <td v-if="isColumnVisible('is_visible')" class="col-visible">
                <span 
                  class="visibility-tag text-xs font-medium"
                  :class="item.is_visible ? 'vis-shown' : 'vis-hidden'"
                >
                  {{ item.is_visible ? 'Visible' : 'Hidden' }}
                </span>
              </td>

              <td v-if="isColumnVisible('path')" class="col-path">
                <span class="font-mono text-xs text-slate-500">{{ item.path }}</span>
              </td>

              <td v-if="isColumnVisible('effective_from')" class="col-effective">
                <span class="font-mono text-xs">{{ item.effective_from }}</span>
              </td>

              <td v-if="isColumnVisible('state')" class="col-status">
                <span class="status-pill status-active capitalize">{{ item.state }}</span>
              </td>

              <td v-if="isColumnVisible('actions')" class="col-actions" @click.stop>
                <div class="action-cell-wrapper">
                  <button 
                    type="button" 
                    class="btn-action-dots" 
                    @click="toggleActionMenu(item.id, $event)"
                    title="Unit Actions"
                  >
                    <MoreVertical :size="15" />
                  </button>

                  <div v-if="activeActionMenuId === item.id" class="action-dropdown-menu">
                    <button class="action-menu-item" @click="viewUnitDetail(item)">
                      <Eye :size="13" />
                      <span>View Unit & Leadership</span>
                    </button>
                    <button class="action-menu-item text-primary" @click="openAppointModal(item)">
                      <UserPlus :size="13" />
                      <span>Appoint New Head</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>

            <tr v-if="filteredUnits.length === 0">
              <td colspan="10" class="empty-state-cell">
                <FolderTree :size="24" class="empty-icon" />
                <p>No organization units found for the selected filters.</p>
              </td>
            </tr>
          </tbody>
        </table>
      </AppDataTable>

      <!-- Floating Bar for Selection -->
      <TableFloatingBar 
        :show="selectedRowIds.length > 0"
        :selected-count="selectedRowIds.length"
        :total-count="filteredUnits.length"
        @delete="handleBatchDeleteUnits"
        @close="selectedRowIds = []"
      />
    </div>

    <!-- VIEW 2: UNIT MASTER DETAIL & LEADERSHIP SUB-TABLE -->
    <div v-else-if="viewMode === 'detail' && selectedUnit" class="unit-detail-wrapper">
      <!-- Back Bar -->
      <div class="detail-top-bar">
        <button type="button" class="btn-back" @click="handleBackToList">
          <ChevronLeft :size="16" />
          <span>Back to Organization Units</span>
        </button>

        <button 
          type="button" 
          class="btn-primary-action"
          @click="openAppointModal(selectedUnit)"
        >
          <UserPlus :size="14" />
          <span>Appoint New Manager / Head</span>
        </button>
      </div>

      <!-- Unit Master Metadata Card -->
      <div class="unit-master-card">
        <div class="unit-card-left">
          <div class="unit-header-title-row">
            <span class="unit-code-tag font-mono">{{ selectedUnit.code }}</span>
            <h1 class="unit-title">{{ selectedUnit.name }}</h1>
            <span class="type-pill capitalize">{{ selectedUnit.organization_unit_type_lookup_value_id }}</span>
          </div>

          <p class="unit-desc">{{ selectedUnit.description }}</p>

          <div class="unit-meta-grid">
            <div class="meta-item">
              <span class="meta-label">Org Blueprint:</span>
              <span class="meta-value font-mono font-medium">{{ selectedUnit.org_structure_name }} ({{ selectedUnit.org_structure_code }})</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Parent Unit:</span>
              <span class="meta-value font-medium">{{ selectedUnit.parent_name || 'Root Department' }}</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Ancestor Path:</span>
              <span class="meta-value font-mono text-xs">{{ selectedUnit.path }}</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Effective Date:</span>
              <span class="meta-value font-mono">{{ selectedUnit.effective_from }}</span>
            </div>
          </div>
        </div>

        <!-- Incumbent Head Quick View Card -->
        <div class="incumbent-card" v-if="selectedUnit.current_head">
          <div class="incumbent-label">Current Appointed Head</div>
          <div class="incumbent-profile">
            <img :src="selectedUnit.current_head.employee_avatar" class="incumbent-avatar" alt="" />
            <div class="incumbent-info">
              <span class="incumbent-name">{{ selectedUnit.current_head.employee_name }}</span>
              <span class="incumbent-role">{{ selectedUnit.current_head.job_title }}</span>
              <span class="incumbent-tenure font-mono text-xs">Since {{ selectedUnit.current_head.start_date }}</span>
            </div>
          </div>
        </div>

        <div class="incumbent-card unassigned-card" v-else>
          <div class="incumbent-label">Current Appointed Head</div>
          <div class="flex items-center gap-2 mt-1">
            <Users :size="20" class="text-slate-400" />
            <span class="text-sm font-medium text-slate-600">No active head assigned</span>
          </div>
          <button 
            type="button" 
            class="btn-appoint-inline mt-2" 
            @click="openAppointModal(selectedUnit)"
          >
            Assign Manager
          </button>
        </div>
      </div>

      <!-- LEADERSHIP HISTORY DYNAMIC CHILD SUB-TABLE (AGENTS.MD SECTION 11 COMPLIANT) -->
      <div class="child-subtable-card">
        <div class="subtable-header">
          <div class="subtable-titles">
            <h2 class="subtable-title">Unit Leadership History (OrganizationUnitHead)</h2>
            <p class="subtable-subtitle">
              Historical appointments for this department. Schema mandates exactly one active head (<code>end_date IS NULL</code>).
            </p>
          </div>

          <button 
            type="button" 
            class="btn-secondary-action"
            @click="openAppointModal(selectedUnit)"
          >
            <UserPlus :size="13" />
            <span>+ Appoint New Head</span>
          </button>
        </div>

        <div class="subtable-container">
          <table class="erp-table child-erp-table">
            <thead>
              <tr>
                <th class="child-th-check">
                  <input 
                    type="checkbox" 
                    class="custom-checkbox" 
                    :checked="isAllHeadsSelected" 
                    @change="toggleSelectAllHeads"
                    aria-label="Select All Leadership Records" 
                  />
                </th>
                <th class="child-th-no">#</th>
                <th class="child-th-head">Appointed Unit Head</th>
                <th class="child-th-start">Appointment Start</th>
                <th class="child-th-end">Appointment End</th>
                <th class="child-th-tenure">Tenure Duration</th>
                <th class="child-th-status">Leadership Status</th>
                <th class="child-th-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="(head, idx) in selectedUnit.heads_history" 
                :key="head.id"
                class="erp-row"
                :class="{ 'row-selected': selectedHeadRowIds.includes(head.id) }"
              >
                <td class="child-th-check" @click.stop>
                  <input 
                    type="checkbox" 
                    class="custom-checkbox" 
                    :checked="selectedHeadRowIds.includes(head.id)" 
                    @change="toggleHeadSelection(head.id)" 
                  />
                </td>

                <td class="child-th-no font-mono text-xs text-slate-500">{{ idx + 1 }}</td>

                <td class="child-th-head">
                  <div class="head-profile-cell">
                    <img :src="head.employee_avatar" class="head-avatar" alt="" />
                    <div class="head-meta">
                      <span class="head-name font-medium">{{ head.employee_name }}</span>
                      <span class="head-sub text-xs text-slate-500 font-mono">{{ head.employee_number }} · {{ head.job_title }}</span>
                    </div>
                  </div>
                </td>

                <td class="child-th-start font-mono text-xs">{{ head.start_date }}</td>

                <td class="child-th-end">
                  <span v-if="!head.end_date" class="current-head-badge">Current Incumbent</span>
                  <span v-else class="font-mono text-xs text-slate-600">{{ head.end_date }}</span>
                </td>

                <td class="child-th-tenure text-xs text-slate-700">{{ head.tenure }}</td>

                <td class="child-th-status">
                  <span 
                    class="status-pill text-xs"
                    :class="!head.end_date ? 'status-active' : 'status-inactive'"
                  >
                    {{ !head.end_date ? 'Active Head' : 'Past Head' }}
                  </span>
                </td>

                <td class="child-th-actions" @click.stop>
                  <div class="action-cell-wrapper">
                    <button 
                      type="button" 
                      class="btn-action-dots" 
                      @click="toggleHeadMenu(head.id, $event)"
                    >
                      <MoreVertical :size="14" />
                    </button>

                    <div v-if="activeHeadMenuId === head.id" class="action-dropdown-menu">
                      <button 
                        v-if="!head.end_date" 
                        class="action-menu-item text-rose-700" 
                        @click="head.end_date = new Date().toISOString().split('T')[0]; closeMenus(); showToast('Appointment ended.');"
                      >
                        <Clock :size="13" />
                        <span>Conclude Tenure (End Date)</span>
                      </button>
                      <button class="action-menu-item" @click="closeMenus()">
                        <Edit2 :size="13" />
                        <span>Edit Record</span>
                      </button>
                    </div>
                  </div>
                </td>
              </tr>

              <tr v-if="selectedUnit.heads_history.length === 0">
                <td colspan="8" class="empty-state-cell">
                  <User :size="20" class="empty-icon" />
                  <p>No historical leadership appointments recorded for this unit.</p>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Floating Bar for Leadership Sub-table -->
      <TableFloatingBar 
        :show="selectedHeadRowIds.length > 0"
        :selected-count="selectedHeadRowIds.length"
        :total-count="selectedUnit.heads_history.length"
        @delete="handleBatchDeleteHeads"
        @close="selectedHeadRowIds = []"
      />
    </div>

    <!-- QUICK CREATE MODAL (Organization Unit Architecture) -->
    <QuickCreateModal
      v-model:show="showQuickCreate"
      title="Create Organization Unit"
      saveLabel="Save"
      :showExpandButton="true"
      @save="handleSaveQuickUnit"
      @expand="handleExpandToFullForm"
      @cancel="showQuickCreate = false"
    >
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <FormInput 
          label="Unit Name" 
          v-model="quickForm.name" 
          required 
        />
        <FormSelect
          label="Unit Type"
          v-model="quickForm.type"
          placeholder="Select Type"
          :options="[
            { label: 'Department', value: 'department' },
            { label: 'Division', value: 'division' },
            { label: 'Section', value: 'section' },
            { label: 'Region', value: 'region' },
            { label: 'Branch', value: 'branch' }
          ]"
          required
        />
        <FormSelect
          label="Org Structure"
          v-model="quickForm.org_structure_code"
          placeholder="Select Structure"
          :options="[
            { label: 'Corporate 2027 (CORP - 2027)', value: 'CORP - 2027' },
            { label: 'Corporate Baseline (CORP - 2027)', value: 'CORP-BASE' },
            { label: 'Corporate Blueprint (CORP - 2027)', value: 'CORP-BLUE' }
          ]"
          required
        />
        <FormSelect
          label="Parent Unit"
          v-model="quickForm.parent_id"
          placeholder="Select Unit"
          :options="[
            { label: '- (Root)', value: '' },
            ...units.map(u => ({ label: `${u.name}`, value: String(u.id) }))
          ]"
          required
        />
        <div class="md:col-span-1">
          <FormSelect
            label="Unit Head Manager"
            v-model="quickForm.head_employee_id"
            placeholder="Select Head"
            :options="[
              { label: 'Dawit Tadesse', value: '4' },
              { label: 'Raleh Girma', value: '5' },
              { label: 'Solomon Mengistu', value: '6' }
            ]"
          />
        </div>
        <div class="md:col-span-2 pt-2">
          <FormCheckbox
            label="Show in Organization Diagrams"
            description="When enabled, this operational unit is rendered visually on top-level corporate organizational charts and department reporting trees."
            v-model="quickForm.is_visible"
          />
        </div>
      </div>
    </QuickCreateModal>

    <!-- APPOINT UNIT HEAD MODAL -->
    <QuickCreateModal
      v-model:show="showAppointModal"
      title="Appoint Organization Unit Head"
      saveLabel="Appoint as Current Head"
      :showExpandButton="false"
      @save="handleSaveAppointHead"
      @cancel="showAppointModal = false"
    >
      <div class="appoint-modal-content" v-if="selectedUnit">
        <p class="text-sm text-slate-600 mb-3">
          Appointing a new manager for <strong class="text-slate-800">{{ selectedUnit.name }}</strong> (<code>{{ selectedUnit.code }}</code>).
        </p>

        <div class="quick-modal-grid">
          <div class="col-span-2">
            <FormSelect
              label="Select Employee from Registry"
              v-model="appointForm.employee_id"
              :options="availableEmployees.map(e => ({ label: `${e.name} (${e.code} · ${e.title})`, value: String(e.id) }))"
              required
            />
          </div>

          <div class="col-span-2">
            <FormInput
              label="Appointment Effective Date"
              type="date"
              v-model="appointForm.start_date"
              required
            />
          </div>
        </div>

        <div class="bg-amber-50 border border-amber-200 rounded-lg p-3 text-xs text-amber-800 flex items-start gap-2 mt-3">
          <AlertCircle :size="15" class="text-amber-600 shrink-0 mt-0.5" />
          <span>
            <strong>Schema Constraint:</strong> Appointing this employee will set the end date of 
            <span v-if="selectedUnit.current_head"><strong>{{ selectedUnit.current_head.employee_name }}</strong></span>
            <span v-else>the previous head</span> 
            to the effective appointment date. Historical records remain preserved.
          </span>
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.org-units-page {
  padding: 16px 24px;
  background-color: var(--primitive-color-neutral-50, #f8fafc);
  min-height: calc(100vh - 60px);
}

.page-breadcrumb-bar {
  margin-bottom: 12px;
}

.directory-view-wrapper, .unit-detail-wrapper {
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

/* Badges & Cells */
.parent-text {
  color: #737373; /* Tertiary color */
}

.type-pill {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11.5px;
  font-weight: 500;
  background-color: #eff6ff;
  color: #0369a1;
  border: 1px solid #bae6fd;
}

.struct-tag {
  font-size: 11.5px;
  padding: 1.5px 6px;
  border-radius: 4px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  color: #737373; /* Tertiary color */
}

.head-profile-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}
.head-avatar {
  width: 26px;
  height: 26px;
  border-radius: 50%;
  object-fit: cover;
}
.head-meta {
  display: flex;
  flex-direction: column;
}
.head-name {
  font-size: 12.5px;
  color: #737373; /* Tertiary color */
}

.text-tertiary {
  color: #737373;
  font-size: 13px;
}

.unassigned-pill {
  display: inline-block;
  padding: 1.5px 7px;
  border-radius: 4px;
  background-color: #f1f5f9;
  color: #94a3b8;
  font-weight: 500;
}

.visibility-tag {
  display: inline-block;
  padding: 1px 6px;
  border-radius: 4px;
}
.vis-shown {
  background-color: #ecfdf5;
  color: #059669;
}
.vis-hidden {
  background-color: #f1f5f9;
  color: #64748b;
}

.status-pill {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 10px;
  font-size: 11.5px;
  font-weight: 500;
}
.status-active {
  background-color: #ecfdf5;
  color: #059669;
}
.status-inactive {
  background-color: #f1f5f9;
  color: #64748b;
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
  min-width: 180px;
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
   VIEW 2: UNIT MASTER DETAIL & LEADERSHIP SUB-TABLE
   ═══════════════════════════════════════════════════════════ */
.detail-top-bar {
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

.btn-secondary-action {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 28px;
  padding: 0 10px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  color: #404040;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
}
.btn-secondary-action:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.unit-master-card {
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

.unit-card-left {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.unit-header-title-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.unit-code-tag {
  font-size: 12px;
  font-weight: 600;
  color: #0B529C;
  background-color: #eff6ff;
  border: 1px solid #bfdbfe;
  padding: 2px 8px;
  border-radius: 6px;
}

.unit-title {
  font-size: 18px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.unit-desc {
  font-size: 12.5px;
  color: #64748b;
  max-width: 650px;
  margin: 0;
  line-height: 1.4;
}

.unit-meta-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  font-size: 12px;
  margin-top: 4px;
}

.incumbent-card {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 16px;
  min-width: 220px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.incumbent-label {
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  color: #737373;
}
.incumbent-profile {
  display: flex;
  align-items: center;
  gap: 10px;
}
.incumbent-avatar {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  object-fit: cover;
}
.incumbent-info {
  display: flex;
  flex-direction: column;
}
.incumbent-name {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}
.incumbent-role {
  font-size: 11.5px;
  color: #64748b;
}

.unassigned-card {
  border-style: dashed;
}

.btn-appoint-inline {
  background: transparent;
  border: 1px solid #0B529C;
  color: #0B529C;
  font-size: 11.5px;
  font-weight: 500;
  padding: 3px 8px;
  border-radius: 4px;
  cursor: pointer;
}
.btn-appoint-inline:hover {
  background: #eff6ff;
}

/* ═══════════════════════════════════════════════════════════
   CHILD SUB-TABLE STYLING (AGENTS.MD SECTION 11)
   ═══════════════════════════════════════════════════════════ */
.child-subtable-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 20px;
}

.subtable-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}
.subtable-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.subtable-subtitle {
  font-size: 12px;
  color: #737373;
  margin: 2px 0 0;
}

.subtable-container {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
}

.child-erp-table th {
  background-color: #f8fafc;
  font-size: 11.5px;
}

.child-th-check { width: 36px; text-align: center; }
.child-th-no { width: 32px; text-align: center; }
.child-th-actions { width: 50px; text-align: center; }

.current-head-badge {
  display: inline-block;
  padding: 1.5px 7px;
  border-radius: 4px;
  background-color: #ecfdf5;
  color: #059669;
  font-size: 11px;
  font-weight: 600;
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

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(2px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
