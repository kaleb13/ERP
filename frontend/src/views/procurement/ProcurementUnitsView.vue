<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, ArrowUpDown, MoreVertical, Eye, Edit2, Check, Trash2,
  ArrowLeft, Building2, Users, UserPlus
} from 'lucide-vue-next';
import { useToast } from '../../composables/useToast';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef, type SortOption } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import BaseBadge, { type BadgeColor } from '../../components/BaseBadge.vue';
import {
  procurementUnitsStore,
  unitMembersStore,
  type ProcurementUnitRecord,
  type ProcurementUnitMemberRecord,
  type ProcurementUnitMode,
  type ProcurementUnitRole,
  type GovernanceStatus,
  unitModeOptions,
  unitRoleOptions,
  employeeOptions,
  departmentOptions,
  entityOptions,
  governanceStatusOptions,
  getUnitModeLabel,
  getUnitRoleLabel,
  getGovernanceStatusLabel,
  getEntityName,
  getLocationName,
  generateUnitCode
} from './procurementUnitData';

const router = useRouter();
const { toast } = useToast();

const getGovernanceBadgeColor = (status: GovernanceStatus): BadgeColor => {
  if (status === 'acceptForAll') return 'success';
  if (status === 'acceptForThis') return 'primary';
  if (status === 'pending') return 'warning';
  if (status === 'reject') return 'error';
  return 'gray';
};

// ─── View & Selection State ───
const searchQuery = ref('');
const filterMode = ref('');
const filterEntity = ref('');
const filterScope = ref('');
const filterStatus = ref('');
const filterState = ref('');
const currentSort = ref('name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const currentPage = ref(1);
const perPage = ref(10);

const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const inspectingUnit = ref<ProcurementUnitRecord | null>(null);

// ─── Member Modal State inside Detail View ───
const showAddMemberModal = ref(false);
const editingMemberId = ref<number | null>(null);
const memberFormErrors = ref<{
  employee?: string;
  role?: string;
  valid_from?: string;
}>({});
const memberForm = ref({
  member_employee_id: '88',
  role: 'buyer' as ProcurementUnitRole,
  organization_unit_id: '',
  valid_from: new Date().toISOString().split('T')[0],
  valid_to: ''
});

// ─── Quick Create / Edit Modal State ───
const showQuickModal = ref(false);
const editingUnitId = ref<number | null>(null);
const quickFieldErrors = ref<{
  name?: string;
  mode?: string;
  entity_id?: string;
}>({});
const quickForm = ref({
  name: '',
  mode: '' as ProcurementUnitMode | '',
  entity_id: '2'
});

// ─── Toast Feedback Helper ───
const toastMessage = ref('');
const toastVariant = ref<'success' | 'error'>('success');
let toastTimer: ReturnType<typeof setTimeout> | null = null;

const showLocalToast = (msg: string, variant: 'success' | 'error' = 'success') => {
  toastMessage.value = msg;
  toastVariant.value = variant;
  if (toastTimer) clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    toastMessage.value = '';
  }, 3500);
};

// ─── Breadcrumb Navigation (AGENTS.md Rule 3) ───
const breadcrumbItems = computed<BreadcrumbItem[]>(() => {
  if (inspectingUnit.value) {
    return [
      {
        label: 'Procurement Units',
        to: '/procurement/units',
        onClick: () => {
          inspectingUnit.value = null;
        }
      },
      { label: inspectingUnit.value.name }
    ];
  }
  return [{ label: 'Procurement Units' }];
});

// ─── Atomic Columns & Column Hider (AGENTS.md Table Architecture) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Unit Name', visible: true, sortable: true, hideable: false },
  { key: 'mode', label: 'Operating Mode', visible: true, sortable: true },
  { key: 'authority_ceiling', label: 'Authority Ceiling', visible: true, sortable: true },
  { key: 'entity', label: 'Owning Entity', visible: false, sortable: false },
  { key: 'buys_for_descendants', label: 'Descendant Scope', visible: false, sortable: true },
  { key: 'default_location', label: 'Default Location', visible: false, sortable: false },
  { key: 'cost_center', label: 'Cost Center', visible: false, sortable: false },
  { key: 'members_count', label: 'Active Members', visible: false, sortable: false },
  { key: 'status', label: 'Status', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

const sortOptions: SortOption[] = [
  { key: 'name', label: 'Unit Name' },
  { key: 'mode', label: 'Operating Mode' },
  { key: 'authority_ceiling', label: 'Authority Ceiling' },
  { key: 'buys_for_descendants', label: 'Descendant Scope' },
  { key: 'status', label: 'Status' },
  { key: 'state', label: 'State' }
];

const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find((c) => c.key === key);
  return col ? col.visible !== false : true;
};

const visibleColumnCount = computed(
  () => tableColumns.value.filter((column) => column.visible !== false).length
);

const handleToggleColumn = (key: string) => {
  const col = tableColumns.value.find((c) => c.key === key);
  if (col) {
    col.visible = col.visible === false;
  }
};

// ─── Members Association Helpers ───
const getUnitMembers = (unitId: number): ProcurementUnitMemberRecord[] => {
  return unitMembersStore.value.filter((m) => m.procurement_unit_id === unitId);
};

const getActiveMembersCount = (unitId: number): number => {
  return unitMembersStore.value.filter(
    (m) => m.procurement_unit_id === unitId && m.state === 'active'
  ).length;
};

// ─── Filters & Sorting ───
const activeFilterCount = computed(() => {
  let count = 0;
  if (filterMode.value) count++;
  if (filterEntity.value) count++;
  if (filterScope.value) count++;
  if (filterStatus.value) count++;
  if (filterState.value) count++;
  return count;
});

const resetFilters = () => {
  filterMode.value = '';
  filterEntity.value = '';
  filterScope.value = '';
  filterStatus.value = '';
  filterState.value = '';
  currentPage.value = 1;
};

watch(
  [searchQuery, filterMode, filterEntity, filterScope, filterStatus, filterState],
  () => {
    currentPage.value = 1;
  }
);

const filteredUnits = computed(() => {
  const q = searchQuery.value.trim().toLowerCase();
  let rows = [...procurementUnitsStore.value];

  if (q) {
    rows = rows.filter(
      (u) =>
        u.name.toLowerCase().includes(q) ||
        u.code.toLowerCase().includes(q) ||
        getEntityName(u.entity_id).toLowerCase().includes(q)
    );
  }

  if (filterMode.value) {
    rows = rows.filter((u) => u.mode === filterMode.value);
  }
  if (filterEntity.value) {
    rows = rows.filter((u) => String(u.entity_id) === filterEntity.value);
  }
  if (filterScope.value === 'descendants') {
    rows = rows.filter((u) => u.buys_for_descendants === true);
  } else if (filterScope.value === 'unit_only') {
    rows = rows.filter((u) => u.buys_for_descendants === false);
  }
  if (filterStatus.value) {
    rows = rows.filter((u) => u.status === filterStatus.value);
  }
  if (filterState.value) {
    rows = rows.filter((u) => u.state === filterState.value);
  }

  rows.sort((a, b) => {
    let valA: string | number = '';
    let valB: string | number = '';
    switch (currentSort.value) {
      case 'name':
        valA = a.name.toLowerCase();
        valB = b.name.toLowerCase();
        break;
      case 'mode':
        valA = a.mode;
        valB = b.mode;
        break;
      case 'authority_ceiling':
        valA = a.authority_ceiling ?? Number.MAX_SAFE_INTEGER;
        valB = b.authority_ceiling ?? Number.MAX_SAFE_INTEGER;
        break;
      case 'buys_for_descendants':
        valA = a.buys_for_descendants ? 1 : 0;
        valB = b.buys_for_descendants ? 1 : 0;
        break;
      case 'status':
        valA = a.status;
        valB = b.status;
        break;
      case 'state':
        valA = a.state;
        valB = b.state;
        break;
    }
    if (valA < valB) return sortOrder.value === 'asc' ? -1 : 1;
    if (valA > valB) return sortOrder.value === 'asc' ? 1 : -1;
    return 0;
  });

  return rows;
});

const paginatedUnits = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredUnits.value.slice(start, start + perPage.value);
});

const handleSortColumn = (key: string) => {
  if (currentSort.value === key) {
    sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
  } else {
    currentSort.value = key;
    sortOrder.value = 'asc';
  }
};

// ─── Selection (Lead Checkbox in Identity Column) ───
const isAllSelected = computed(() => {
  const pageIds = paginatedUnits.value.map((u) => u.id);
  if (pageIds.length === 0) return false;
  return pageIds.every((id) => selectedRowIds.value.includes(id));
});

const isPartiallySelected = computed(() => {
  const pageIds = paginatedUnits.value.map((u) => u.id);
  const selectedOnPage = pageIds.filter((id) => selectedRowIds.value.includes(id));
  return selectedOnPage.length > 0 && selectedOnPage.length < pageIds.length;
});

const toggleSelectAll = (checked: boolean) => {
  const pageIds = paginatedUnits.value.map((u) => u.id);
  if (checked) {
    const combined = new Set([...selectedRowIds.value, ...pageIds]);
    selectedRowIds.value = Array.from(combined);
  } else {
    selectedRowIds.value = selectedRowIds.value.filter((id) => !pageIds.includes(id));
  }
};

const toggleSelectRow = (id: number) => {
  if (selectedRowIds.value.includes(id)) {
    selectedRowIds.value = selectedRowIds.value.filter((i) => i !== id);
  } else {
    selectedRowIds.value.push(id);
  }
};

const selectAllFilteredUnits = () => {
  selectedRowIds.value = filteredUnits.value.map((u) => u.id);
};

// ─── Currency / Amount Formatter ───
const formatCeiling = (ceiling: number | null, currency: string): string => {
  if (ceiling === null || ceiling === undefined) return 'Unlimited (No Cap)';
  return `${Number(ceiling).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ${currency}`;
};

// ─── Quick Create / Edit Actions ───
const openCreateModal = () => {
  editingUnitId.value = null;
  quickFieldErrors.value = {};
  quickForm.value = {
    name: '',
    mode: 'centralised',
    entity_id: '2'
  };
  showQuickModal.value = true;
};

const openEditModal = (item: ProcurementUnitRecord) => {
  editingUnitId.value = item.id;
  quickFieldErrors.value = {};
  quickForm.value = {
    name: item.name,
    mode: item.mode,
    entity_id: String(item.entity_id)
  };
  showQuickModal.value = true;
  closeActionMenu();
};

const handleSaveQuick = () => {
  const errors: typeof quickFieldErrors.value = {};
  const missingLabels: string[] = [];

  if (!quickForm.value.name.trim()) {
    errors.name = 'Unit Name is required.';
    missingLabels.push('Unit Name');
  }
  if (!unitModeOptions.some((option) => option.value === quickForm.value.mode)) {
    errors.mode = 'Operating Mode is required.';
    missingLabels.push('Operating Mode');
  }
  if (!entityOptions.some((option) => option.value === quickForm.value.entity_id)) {
    errors.entity_id = 'Owning Legal Entity is required.';
    missingLabels.push('Owning Legal Entity');
  }

  quickFieldErrors.value = errors;

  if (missingLabels.length > 0) {
    toast.error(
      'Please fill in all required fields',
      `Missing: ${missingLabels.join(', ')}.`
    );
    return;
  }

  const entityVal = Number(quickForm.value.entity_id);

  if (editingUnitId.value) {
    const idx = procurementUnitsStore.value.findIndex((u) => u.id === editingUnitId.value);
    if (idx !== -1) {
      const existing = procurementUnitsStore.value[idx];
      procurementUnitsStore.value[idx] = {
        ...existing,
        name: quickForm.value.name.trim(),
        mode: quickForm.value.mode as ProcurementUnitMode,
        entity_id: entityVal
      };
      if (inspectingUnit.value?.id === existing.id) {
        inspectingUnit.value = procurementUnitsStore.value[idx];
      }
      showLocalToast(`Updated "${quickForm.value.name.trim()}".`);
    }
  } else {
    const existingCodes = procurementUnitsStore.value.map((u) => u.code);
    const nextId = Math.max(0, ...procurementUnitsStore.value.map((u) => u.id)) + 1;
    const generatedCode = generateUnitCode(quickForm.value.name, existingCodes);

    const newUnit: ProcurementUnitRecord = {
      id: nextId,
      uuid: `pu-uuid-${nextId}`,
      code: generatedCode,
      name: quickForm.value.name.trim(),
      mode: quickForm.value.mode as ProcurementUnitMode,
      authority_ceiling: null,
      currency_code: 'ETB',
      buys_for_descendants: false,
      entity_id: entityVal,
      default_location_id: null,
      cost_center_dimension_id: null,
      status: 'acceptForAll',
      state: 'active'
    };

    procurementUnitsStore.value.unshift(newUnit);
    showLocalToast(`Created procurement unit "${quickForm.value.name.trim()}".`);
  }

  showQuickModal.value = false;
};

const handleExpandFullForm = () => {
  showQuickModal.value = false;
  router.push({
    path: '/procurement/units/create',
    query: {
      name: quickForm.value.name || undefined,
      mode: quickForm.value.mode || undefined,
      entity_id: quickForm.value.entity_id || undefined
    }
  });
};

// ─── Row Actions & Detail View ───
const toggleActionMenu = (id: number) => {
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
};

const openDetailView = (item: ProcurementUnitRecord) => {
  inspectingUnit.value = item;
  activeActionMenuId.value = null;
};

const handleToggleState = (item: ProcurementUnitRecord) => {
  item.state = item.state === 'active' ? 'inactive' : 'active';
  showLocalToast(`Marked "${item.name}" as ${item.state === 'active' ? 'Active' : 'Inactive'}.`);
  closeActionMenu();
};

const handleDelete = (item: ProcurementUnitRecord) => {
  const members = unitMembersStore.value.filter((m) => m.procurement_unit_id === item.id);
  if (members.length > 0) {
    showLocalToast(`Cannot delete "${item.name}" while member records are assigned to it.`, 'error');
    closeActionMenu();
    return;
  }
  procurementUnitsStore.value = procurementUnitsStore.value.filter((u) => u.id !== item.id);
  selectedRowIds.value = selectedRowIds.value.filter((i) => i !== item.id);
  if (inspectingUnit.value?.id === item.id) {
    inspectingUnit.value = null;
  }
  showLocalToast(`Deleted "${item.name}".`);
  closeActionMenu();
};

const handleBatchDelete = () => {
  const selectedSet = new Set(selectedRowIds.value);
  const blocked = procurementUnitsStore.value.some(
    (u) => selectedSet.has(u.id) && unitMembersStore.value.some((m) => m.procurement_unit_id === u.id)
  );
  if (blocked) {
    showLocalToast('Some selected units have member records. Remove those members before deleting.', 'error');
    return;
  }
  procurementUnitsStore.value = procurementUnitsStore.value.filter((u) => !selectedSet.has(u.id));
  showLocalToast(`Deleted ${selectedRowIds.value.length} selected units.`);
  selectedRowIds.value = [];
};

// ─── Member Roster Management in Detail View ───
const openAddMemberModal = () => {
  editingMemberId.value = null;
  memberFormErrors.value = {};
  memberForm.value = {
    member_employee_id: '88',
    role: 'buyer',
    organization_unit_id: '',
    valid_from: new Date().toISOString().split('T')[0],
    valid_to: ''
  };
  showAddMemberModal.value = true;
};

const openEditMemberModal = (member: ProcurementUnitMemberRecord) => {
  editingMemberId.value = member.id;
  memberFormErrors.value = {};
  memberForm.value = {
    member_employee_id: String(member.member_employee_id),
    role: member.role,
    organization_unit_id: member.organization_unit_id ? String(member.organization_unit_id) : '',
    valid_from: member.valid_from,
    valid_to: member.valid_to || ''
  };
  showAddMemberModal.value = true;
};

const handleSaveMember = () => {
  if (!inspectingUnit.value) return;

  const errors: typeof memberFormErrors.value = {};
  if (!employeeOptions.some((option) => option.value === memberForm.value.member_employee_id)) {
    errors.employee = 'Select an employee.';
  }
  if (!unitRoleOptions.some((option) => option.value === memberForm.value.role)) {
    errors.role = 'Select an assigned role.';
  }
  if (!memberForm.value.valid_from) errors.valid_from = 'Valid From is required.';
  if (
    memberForm.value.valid_to &&
    memberForm.value.valid_from &&
    memberForm.value.valid_to < memberForm.value.valid_from
  ) {
    errors.valid_from = 'Valid To must be on or after Valid From.';
  }
  memberFormErrors.value = errors;
  if (Object.keys(errors).length > 0) {
    toast.error('Check the member details', 'Complete the required fields and correct the validity dates.');
    return;
  }

  const empId = Number(memberForm.value.member_employee_id);
  const empOption = employeeOptions.find((e) => e.value === memberForm.value.member_employee_id);
  const empName = empOption ? empOption.label.split(' (')[0] : `Employee #${empId}`;
  const empCode = empOption && empOption.label.includes('(') ? empOption.label.split('(')[1].split(')')[0] : `EMP-${empId}`;

  const deptId = memberForm.value.organization_unit_id ? Number(memberForm.value.organization_unit_id) : null;
  const deptName = deptId ? (departmentOptions.find((d) => d.value === String(deptId))?.label ?? `Dept #${deptId}`) : 'All Departments';

  const duplicateAssignment = unitMembersStore.value.some((member) => (
    member.procurement_unit_id === inspectingUnit.value?.id &&
    member.id !== editingMemberId.value &&
    member.member_employee_id === empId &&
    member.role === memberForm.value.role &&
    member.organization_unit_id === deptId
  ));
  if (duplicateAssignment) {
    toast.error('Member assignment already exists', 'This employee already has this role for the selected department in the unit.');
    return;
  }

  if (editingMemberId.value) {
    const idx = unitMembersStore.value.findIndex((m) => m.id === editingMemberId.value);
    if (idx !== -1) {
      unitMembersStore.value[idx] = {
        ...unitMembersStore.value[idx],
        member_employee_id: empId,
        employee_name: empName,
        employee_code: empCode,
        role: memberForm.value.role,
        organization_unit_id: deptId,
        department_name: deptName,
        valid_from: memberForm.value.valid_from,
        valid_to: memberForm.value.valid_to || null
      };
      showLocalToast(`Updated member "${empName}".`);
    }
  } else {
    const nextMemberId = Math.max(0, ...unitMembersStore.value.map((m) => m.id)) + 1;
    unitMembersStore.value.push({
      id: nextMemberId,
      uuid: `pum-uuid-${nextMemberId}`,
      procurement_unit_id: inspectingUnit.value.id,
      member_employee_id: empId,
      employee_name: empName,
      employee_code: empCode,
      role: memberForm.value.role,
      organization_unit_id: deptId,
      department_name: deptName,
      valid_from: memberForm.value.valid_from,
      valid_to: memberForm.value.valid_to || null,
      state: 'active'
    });
    showLocalToast(`Added member "${empName}" to unit.`);
  }

  showAddMemberModal.value = false;
};

const handleToggleMemberState = (member: ProcurementUnitMemberRecord) => {
  member.state = member.state === 'active' ? 'inactive' : 'active';
  showLocalToast(`Marked member "${member.employee_name}" as ${member.state === 'active' ? 'Active' : 'Inactive'}.`);
};

const handleDeleteMember = (member: ProcurementUnitMemberRecord) => {
  unitMembersStore.value = unitMembersStore.value.filter((m) => m.id !== member.id);
  showLocalToast(`Removed "${member.employee_name}" from unit.`);
};

// ─── Click Outside Listener ───
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
  <div class="procurement-units-page">
    <!-- ═══ BREADCRUMB NAVIGATION (Rule 3: Exact Page Name Only) ═══ -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" :noMargin="true" />
    </div>

    <!-- ═══ LOCAL TOAST FEEDBACK BANNER ═══ -->
    <div v-if="toastMessage" class="toast-wrapper">
      <div class="toast-box" :class="{ 'toast-error': toastVariant === 'error' }">
        <Check v-if="toastVariant === 'success'" :size="15" class="toast-icon" />
        <span>{{ toastMessage }}</span>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- ISOLATED DETAIL VIEW (AGENTS.md Rule 10.3 & Rule 10.5)         -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-if="inspectingUnit" class="detail-view-wrapper">
      <div class="detail-top-actions">
        <AppButton variant="outline" size="sm" @click="inspectingUnit = null">
          <template #icon-left>
            <ArrowLeft :size="15" />
          </template>
          Back to Procurement Units
        </AppButton>

        <div class="detail-right-actions">
          <AppButton
            variant="outline"
            size="sm"
            @click="router.push({ path: '/procurement/units/create', query: { editId: String(inspectingUnit.id) } })"
          >
            <template #icon-left>
              <Edit2 :size="14" />
            </template>
            Edit Unit
          </AppButton>
          <AppButton
            variant="outline"
            size="sm"
            @click="handleToggleState(inspectingUnit)"
          >
            {{ inspectingUnit.state === 'active' ? 'Deactivate' : 'Activate' }}
          </AppButton>
        </div>
      </div>

      <!-- Unit Profile Summary Card -->
      <div class="detail-card">
        <div class="detail-header-row">
          <div>
            <h2 class="detail-title">{{ inspectingUnit.name }}</h2>
            <span class="detail-code">{{ inspectingUnit.code }}</span>
          </div>
          <div class="detail-badges">
            <span class="tertiary-plain-text">{{ getUnitModeLabel(inspectingUnit.mode) }}</span>
            <BaseBadge size="sm" :color="getGovernanceBadgeColor(inspectingUnit.status)">
              {{ getGovernanceStatusLabel(inspectingUnit.status) }}
            </BaseBadge>
            <BaseBadge size="sm" :color="inspectingUnit.state === 'active' ? 'success' : 'gray'">
              {{ inspectingUnit.state === 'active' ? 'Active' : 'Inactive' }}
            </BaseBadge>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-meta-grid">
          <div class="meta-item">
            <span class="meta-label">Authority Ceiling</span>
            <span class="meta-value">{{ formatCeiling(inspectingUnit.authority_ceiling, inspectingUnit.currency_code) }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Descendant Buying Scope</span>
            <span class="meta-value">{{ inspectingUnit.buys_for_descendants ? 'Child Entities Included' : 'Unit Only (Self)' }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Owning Legal Entity</span>
            <span class="meta-value">{{ getEntityName(inspectingUnit.entity_id) }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Default Warehouse / Store</span>
            <span class="meta-value">{{ getLocationName(inspectingUnit.default_location_id) }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Default Cost Center</span>
            <span class="meta-value">{{ inspectingUnit.cost_center_dimension_id || '—' }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Active Members</span>
            <span class="meta-value">{{ getActiveMembersCount(inspectingUnit.id) }} members assigned</span>
          </div>
        </div>
      </div>

      <!-- Unit Members Sub-Table Card -->
      <div class="detail-card">
        <div class="detail-header-row">
          <div class="title-with-badge">
            <h3 class="section-title">Unit Members & Assigned Roles</h3>
            <span class="tertiary-plain-text">
              {{ getUnitMembers(inspectingUnit.id).length }} members
            </span>
          </div>
          <AppButton variant="primary" size="sm" @click="openAddMemberModal">
            <template #icon-left>
              <UserPlus :size="14" />
            </template>
            Add Member
          </AppButton>
        </div>

        <div class="detail-divider"></div>

        <table class="erp-table members-subtable">
          <thead>
            <tr>
              <th>Employee / Buyer</th>
              <th>Assigned Role</th>
              <th>Department Served</th>
              <th>Valid From</th>
              <th>Valid To</th>
              <th>State</th>
              <th class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="getUnitMembers(inspectingUnit.id).length === 0">
              <td colspan="7" class="empty-state-cell">
                <div class="empty-state-container">
                  <Users :size="28" class="empty-state-icon" />
                  <p class="empty-state-title">No members assigned to this unit</p>
                  <p class="empty-state-subtext">Click "Add Member" to assign buyers, approvers, or receivers.</p>
                </div>
              </td>
            </tr>
            <tr
              v-for="member in getUnitMembers(inspectingUnit.id)"
              :key="member.id"
              class="subtable-row"
            >
              <td>
                <div class="name-cell-stack">
                  <span class="table-name-primary">{{ member.employee_name }}</span>
                  <span class="table-code-subtext">{{ member.employee_code }}</span>
                </div>
              </td>
              <td>
                <span class="tertiary-plain-text">{{ getUnitRoleLabel(member.role) }}</span>
              </td>
              <td>
                <span class="tertiary-plain-text">{{ member.department_name }}</span>
              </td>
              <td>
                <span class="tertiary-plain-text">{{ member.valid_from }}</span>
              </td>
              <td>
                <span class="tertiary-plain-text">{{ member.valid_to || 'Indefinite' }}</span>
              </td>
              <td>
                <BaseBadge
                  size="sm"
                  :color="member.state === 'active' ? 'success' : 'gray'"
                >
                  {{ member.state === 'active' ? 'Active' : 'Inactive' }}
                </BaseBadge>
              </td>
              <td class="col-actions">
                <div class="subtable-actions">
                  <button
                    type="button"
                    class="btn-icon-subtle"
                    title="Edit Member"
                    @click="openEditMemberModal(member)"
                  >
                    <Edit2 :size="13" />
                  </button>
                  <button
                    type="button"
                    class="btn-icon-subtle"
                    :title="member.state === 'active' ? 'Deactivate' : 'Activate'"
                    @click="handleToggleMemberState(member)"
                  >
                    <Check :size="13" />
                  </button>
                  <button
                    type="button"
                    class="btn-icon-subtle btn-danger-subtle"
                    title="Remove Member"
                    @click="handleDeleteMember(member)"
                  >
                    <Trash2 :size="13" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- DIRECTORY VIEW: SINGLE TABLE CARD (AGENTS.md Rule 10.1 & 21)   -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <template v-else>
      <AppDataTable
        title="Procurement Units"
        subtitle="Centralised buying hubs, branch buying desks, and decentralised units managing spend authority ceilings and role rosters."
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search unit by name, code, or entity..."
        :showSearch="true"
        :showFilter="true"
        :showFullscreen="true"
        :filterCount="activeFilterCount"
        :showSort="true"
        :sortOptions="sortOptions"
        v-model:currentSort="currentSort"
        v-model:sortOrder="sortOrder"
        :showColumns="true"
        :columns="tableColumns"
        :totalEntries="filteredUnits.length"
        :showPagination="true"
        v-model:currentPage="currentPage"
        v-model:perPage="perPage"
        @toggleColumn="handleToggleColumn"
        @resetFilter="resetFilters"
      >
        <!-- Primary Action inside Toolbar (Rule 10.2 & Rule 31) -->
        <template #actions>
          <AppButton variant="primary" size="sm" @click="openCreateModal">
            <template #icon-left>
              <Plus :size="15" />
            </template>
            Create Unit
          </AppButton>
        </template>

        <!-- Filter Panel -->
        <template #filter-panel>
          <div class="filter-panel-grid">
            <FormSelect
              label="Operating Mode"
              v-model="filterMode"
              :options="[{ value: '', label: 'All Modes' }, ...unitModeOptions]"
              placeholder="Select"
            />
            <FormSelect
              label="Owning Entity"
              v-model="filterEntity"
              :options="[{ value: '', label: 'All Entities' }, ...entityOptions]"
              placeholder="Select"
            />
            <FormSelect
              label="Descendant Scope"
              v-model="filterScope"
              :options="[
                { value: '', label: 'All Scopes' },
                { value: 'descendants', label: 'Child Entities Included' },
                { value: 'unit_only', label: 'Unit Only (Self)' }
              ]"
              placeholder="Select"
            />
            <FormSelect
              label="Governance Status"
              v-model="filterStatus"
              :options="[{ value: '', label: 'All Statuses' }, ...governanceStatusOptions]"
              placeholder="Select"
            />
            <FormSelect
              label="Lifecycle State"
              v-model="filterState"
              :options="[
                { value: '', label: 'All States' },
                { value: 'active', label: 'Active' },
                { value: 'inactive', label: 'Inactive' }
              ]"
              placeholder="Select"
            />
          </div>
          <div v-if="activeFilterCount > 0" class="filter-panel-footer">
            <AppButton variant="outline" size="sm" @click="resetFilters">
              Reset Filters
            </AppButton>
          </div>
        </template>

        <!-- Table Content (Lead Checkbox in Identity Column) -->
        <table class="erp-table">
          <thead>
            <tr>
              <th
                v-if="isColumnVisible('name')"
                class="sortable"
                @click="handleSortColumn('name')"
              >
                <div class="th-content name-header-content">
                  <FormCheckbox
                    :model-value="isAllSelected"
                    :indeterminate="isPartiallySelected"
                    size="md"
                    @click.stop
                    @update:model-value="toggleSelectAll"
                  >
                    <span class="sr-only">Select all units on this page</span>
                  </FormCheckbox>
                  <span>Unit Name</span>
                  <ArrowUpDown v-if="currentSort === 'name'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('mode')"
                class="sortable"
                @click="handleSortColumn('mode')"
              >
                <div class="th-content">
                  <span>Operating Mode</span>
                  <ArrowUpDown v-if="currentSort === 'mode'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('authority_ceiling')"
                class="sortable"
                @click="handleSortColumn('authority_ceiling')"
              >
                <div class="th-content">
                  <span>Authority Ceiling</span>
                  <ArrowUpDown v-if="currentSort === 'authority_ceiling'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('buys_for_descendants')"
                class="sortable"
                @click="handleSortColumn('buys_for_descendants')"
              >
                <div class="th-content">
                  <span>Descendant Scope</span>
                  <ArrowUpDown v-if="currentSort === 'buys_for_descendants'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th v-if="isColumnVisible('entity')">
                <div class="th-content"><span>Owning Entity</span></div>
              </th>

              <th v-if="isColumnVisible('default_location')">
                <div class="th-content"><span>Default Location</span></div>
              </th>

              <th v-if="isColumnVisible('cost_center')">
                <div class="th-content"><span>Cost Center</span></div>
              </th>

              <th v-if="isColumnVisible('members_count')">
                <div class="th-content"><span>Active Members</span></div>
              </th>

              <th
                v-if="isColumnVisible('status')"
                class="sortable"
                @click="handleSortColumn('status')"
              >
                <div class="th-content">
                  <span>Status</span>
                  <ArrowUpDown v-if="currentSort === 'status'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th
                v-if="isColumnVisible('state')"
                class="sortable"
                @click="handleSortColumn('state')"
              >
                <div class="th-content">
                  <span>State</span>
                  <ArrowUpDown v-if="currentSort === 'state'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr v-if="paginatedUnits.length === 0">
              <td :colspan="visibleColumnCount" class="empty-state-cell">
                <div class="empty-state-container">
                  <Building2 :size="32" class="empty-state-icon" />
                  <p class="empty-state-title">No procurement units found</p>
                  <p class="empty-state-subtext">Adjust your search or filters, or create a new unit.</p>
                </div>
              </td>
            </tr>

            <tr
              v-for="item in paginatedUnits"
              :key="item.id"
              class="erp-row"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
              @click="openDetailView(item)"
            >
              <!-- Name & Code with Lead Checkbox -->
              <td v-if="isColumnVisible('name')" class="td-name">
                <div class="name-cell-content">
                  <FormCheckbox
                    :model-value="selectedRowIds.includes(item.id)"
                    size="md"
                    @click.stop
                    @update:model-value="() => toggleSelectRow(item.id)"
                  >
                    <span class="sr-only">Select {{ item.name }}</span>
                  </FormCheckbox>
                  <div class="name-cell-stack">
                    <span class="table-name-primary">{{ item.name }}</span>
                    <span class="table-code-subtext">{{ item.code }}</span>
                  </div>
                </div>
              </td>

              <!-- Operating Mode Badge -->
              <td v-if="isColumnVisible('mode')">
                <span class="tertiary-plain-text">{{ getUnitModeLabel(item.mode) }}</span>
              </td>

              <!-- Authority Ceiling -->
              <td v-if="isColumnVisible('authority_ceiling')">
                <span class="tertiary-plain-text">
                  {{ formatCeiling(item.authority_ceiling, item.currency_code) }}
                </span>
              </td>

              <!-- Descendant Scope -->
              <td v-if="isColumnVisible('buys_for_descendants')">
                <span class="tertiary-plain-text">
                  {{ item.buys_for_descendants ? 'Child Entities Included' : 'Unit Only (Self)' }}
                </span>
              </td>

              <!-- Owning Entity -->
              <td v-if="isColumnVisible('entity')">
                <span class="tertiary-plain-text">{{ getEntityName(item.entity_id) }}</span>
              </td>

              <!-- Default Location -->
              <td v-if="isColumnVisible('default_location')">
                <span class="tertiary-plain-text">{{ getLocationName(item.default_location_id) }}</span>
              </td>

              <!-- Cost Center -->
              <td v-if="isColumnVisible('cost_center')">
                <span class="tertiary-plain-text">{{ item.cost_center_dimension_id || '—' }}</span>
              </td>

              <!-- Active Members Count -->
              <td v-if="isColumnVisible('members_count')" @click.stop="openDetailView(item)">
                <span class="tertiary-plain-text">
                  {{ getActiveMembersCount(item.id) }} members
                </span>
              </td>

              <!-- Governance Status -->
              <td v-if="isColumnVisible('status')">
                <BaseBadge size="sm" :color="getGovernanceBadgeColor(item.status)">
                  {{ getGovernanceStatusLabel(item.status) }}
                </BaseBadge>
              </td>

              <!-- State -->
              <td v-if="isColumnVisible('state')">
                <BaseBadge
                  size="sm"
                  :color="item.state === 'active' ? 'success' : 'gray'"
                >
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </BaseBadge>
              </td>

              <!-- Actions Dropdown -->
              <td v-if="isColumnVisible('actions')" class="col-actions" @click.stop>
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
                    <button type="button" class="dropdown-item" @click="openDetailView(item)">
                      <Eye :size="14" class="dropdown-icon" />
                      <span>View Details</span>
                    </button>
                    <button type="button" class="dropdown-item" @click="openEditModal(item)">
                      <Edit2 :size="14" class="dropdown-icon" />
                      <span>Edit Unit</span>
                    </button>
                    <button type="button" class="dropdown-item" @click="handleToggleState(item)">
                      <Check :size="14" class="dropdown-icon" />
                      <span>{{ item.state === 'active' ? 'Deactivate' : 'Activate' }}</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button type="button" class="dropdown-item dropdown-item-danger" @click="handleDelete(item)">
                      <Trash2 :size="14" class="dropdown-icon" />
                      <span>Delete</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </AppDataTable>

      <!-- Floating Batch Action Bar -->
      <TableFloatingBar
        :show="selectedRowIds.length > 0"
        :selected-count="selectedRowIds.length"
        :total-count="filteredUnits.length"
        @delete="handleBatchDelete"
        @selectAll="selectAllFilteredUnits"
      />
    </template>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- QUICK CREATE / EDIT MODAL                                      -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <QuickCreateModal
      v-model:show="showQuickModal"
      :title="editingUnitId ? 'Edit Procurement Unit' : 'Create Procurement Unit'"
      :showExpandButton="!editingUnitId"
      saveLabel="Save"
      width="md"
      @save="handleSaveQuick"
      @expand="handleExpandFullForm"
    >
      <div class="quick-form-body">
        <FormInput
          v-model="quickForm.name"
          label="Unit Name"
          :error="quickFieldErrors.name"
          required
        />

        <div class="modal-grid-2">
          <FormSelect
            v-model="quickForm.mode"
            label="Operating Mode"
            :options="unitModeOptions"
            placeholder="Select"
            :error="quickFieldErrors.mode"
            required
          />

          <FormSelect
            v-model="quickForm.entity_id"
            label="Owning Legal Entity"
            :options="entityOptions"
            placeholder="Select"
            :error="quickFieldErrors.entity_id"
            required
          />
        </div>
      </div>
    </QuickCreateModal>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- ADD / EDIT MEMBER MODAL (Inside Detail View)                   -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <QuickCreateModal
      v-model:show="showAddMemberModal"
      :title="editingMemberId ? 'Edit Unit Member' : 'Add Unit Member'"
      :showExpandButton="false"
      saveLabel="Save"
      width="md"
      @save="handleSaveMember"
    >
      <div class="quick-form-body">
        <FormSelect
          v-model="memberForm.member_employee_id"
          label="Employee / Person"
          :options="employeeOptions"
          placeholder="Select"
          :error="memberFormErrors.employee"
          required
        />

        <div class="modal-grid-2">
          <FormSelect
            v-model="memberForm.role"
            label="Assigned Role"
            :options="unitRoleOptions"
            placeholder="Select"
            :error="memberFormErrors.role"
            required
          />

          <FormSelect
            v-model="memberForm.organization_unit_id"
            label="Department Served"
            :options="departmentOptions"
            placeholder="Select department"
          />
        </div>

        <div class="modal-grid-2">
          <FormInput
            v-model="memberForm.valid_from"
            label="Valid From"
            type="date"
            :error="memberFormErrors.valid_from"
            required
          />

          <FormInput
            v-model="memberForm.valid_to"
            label="Valid To"
            type="date"
          />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.procurement-units-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

/* Toast Feedback */
.toast-wrapper {
  position: fixed;
  top: 24px;
  right: 24px;
  z-index: 100;
  animation: slideInToast 0.2s ease-out;
}

@keyframes slideInToast {
  from {
    transform: translateY(-8px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.toast-box {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 9px 14px;
  background-color: #ECFDF5;
  border: 1px solid #D0FAE5;
  border-radius: 8px;
  color: #007A55;
  font-size: 13px;
  font-weight: 500;
}

.toast-box.toast-error {
  background-color: #FEF2F2;
  border-color: #FFE2E2;
  color: #C10007;
}

.toast-icon {
  color: #009966;
  flex-shrink: 0;
}

/* Filter Panel */
.filter-panel-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
  gap: 14px;
}

.filter-panel-footer {
  display: flex;
  justify-content: flex-end;
  margin-top: 12px;
}

/* Table Standards (Rule 8, 9, 28) */
.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background-color: #fafafa;
  border-bottom: 1px solid #E5E5E5;
  text-align: left;
  white-space: nowrap;
}

.erp-table th.sortable {
  cursor: pointer;
  user-select: none;
}

.erp-table th.sortable:hover {
  color: #404040;
}

.th-content {
  display: inline-flex !important;
  align-items: center !important;
  gap: 5px !important;
  white-space: nowrap !important;
  vertical-align: middle !important;
}

.name-header-content,
.name-cell-content {
  gap: 12px;
}

.name-cell-content {
  display: flex;
  align-items: center;
  min-width: 0;
}

.sort-icon {
  color: #0B529C;
  flex-shrink: 0;
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  font-size: 13px;
  border-bottom: 1px solid #E5E5E5;
  vertical-align: middle;
}

.erp-row {
  cursor: pointer;
  transition: background-color 0.12s ease;
}

.erp-row:hover {
  background-color: #F5F5F5;
}

.row-selected {
  background-color: #E1EEFD;
}

.name-cell-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary {
  color: #404040;
  font-weight: 500;
  font-size: 13px;
}

.table-code-subtext {
  color: #737373;
  font-size: 11.5px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}

.tertiary-plain-text {
  color: #737373;
  font-size: 13px;
}

/* Action Dropdown */
.col-actions {
  width: 64px;
  text-align: right;
}

.action-menu-container {
  position: relative;
  display: inline-flex;
  justify-content: flex-end;
}

.btn-action-dots {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: 1px solid transparent;
  background: transparent;
  color: #737373;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.btn-action-dots:hover {
  background: #F5F5F5;
  color: #404040;
}

.action-dropdown {
  position: absolute;
  right: 0;
  top: 32px;
  min-width: 170px;
  background: #ffffff;
  border: 1px solid #E5E5E5;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.08);
  padding: 4px;
  z-index: 40;
}

.dropdown-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 7px 10px;
  font-size: 12.5px;
  color: #404040;
  background: transparent;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
}

.dropdown-item:hover {
  background: #F5F5F5;
}

.dropdown-icon {
  color: #737373;
}

.dropdown-divider {
  height: 1px;
  background: #F5F5F5;
  margin: 4px 0;
}

.dropdown-item-danger {
  color: #E7000B;
}

.dropdown-item-danger .dropdown-icon {
  color: #E7000B;
}

.dropdown-item-danger:hover {
  background: #FEF2F2;
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
  gap: 6px;
}

.empty-state-icon {
  color: #737373;
  margin-bottom: 4px;
}

.empty-state-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.empty-state-subtext {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

/* Quick Form Body */
.quick-form-body {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.modal-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
}

.modal-checkbox-stack {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding-top: 6px;
}

/* Detail View */
.detail-view-wrapper {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.detail-top-actions {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.detail-right-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.detail-card {
  background: #ffffff;
  border: 1px solid #E5E5E5;
  border-radius: 12px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.detail-header-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
}

.title-with-badge {
  display: flex;
  align-items: center;
  gap: 10px;
}

.detail-title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #404040;
}

.section-title {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.detail-code {
  display: inline-block;
  margin-top: 2px;
  font-size: 12px;
  color: #737373;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}

.detail-badges {
  display: flex;
  align-items: center;
  gap: 8px;
}

.detail-divider {
  height: 1px;
  background: #F5F5F5;
}

.detail-meta-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 16px;
}

.meta-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.meta-label {
  font-size: 12px;
  font-weight: 500;
  color: #737373;
}

.meta-value {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
}

/* Sub-table in detail view */
.members-subtable {
  margin-top: 4px;
}

.subtable-row:hover {
  background-color: #F5F5F5;
}

.subtable-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 4px;
}

.btn-icon-subtle {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  border-radius: 6px;
  border: 1px solid transparent;
  background: transparent;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-icon-subtle:hover {
  background-color: #F5F5F5;
  color: #404040;
}

.btn-danger-subtle:hover {
  background-color: #FEF2F2;
  color: #E7000B;
}

</style>
