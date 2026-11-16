<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Plus, Search, MoreVertical, Trash2, Eye, CheckCircle2, X 
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormInput from '../../components/FormInput.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

const router = useRouter();

// ─── Breadcrumb (Rule 3: Exact Sidebar Page Name Only) ───
const breadcrumbItems = [
  { label: 'Shift Assignments' }
];

// ─── Types & Interfaces (HR_Schema_final-v4.sql lines 1402–1424) ───
export type AssignmentState = 'planned' | 'published' | 'swapped' | 'cancelled';

export interface ShiftAssignmentRecord {
  id: number;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_role: string;
  org_unit_name: string;
  entity_id: number;
  entity_name: string;
  date: string; // YYYY-MM-DD
  shift_id: number | null;
  shift_name?: string;
  start_time?: string;
  end_time?: string;
  is_overnight?: boolean;
  assignment_state: AssignmentState;
  shift_pattern_id?: number | null;
  pattern_name?: string;
  swapped_with_name?: string;
  notes?: string;
}

interface ShiftDefinition {
  id: number;
  code: string;
  name: string;
  start_time: string;
  end_time: string;
  hours: number;
}

// ─── Master Shifts Catalog ───
const shiftCatalog: Record<number, ShiftDefinition> = {
  1: { id: 1, code: 'SH-OFF', name: 'Office Day', start_time: '08:30', end_time: '17:30', hours: 8.0 },
  2: { id: 2, code: 'SH-MORN', name: 'Retail Morning', start_time: '07:00', end_time: '15:00', hours: 7.5 },
  3: { id: 3, code: 'SH-EVE', name: 'Retail Evening', start_time: '14:30', end_time: '22:30', hours: 7.5 },
  4: { id: 4, code: 'SH-NIGHT', name: 'Night Guard', start_time: '22:00', end_time: '06:00', hours: 7.25 },
  5: { id: 5, code: 'SH-SPLIT', name: 'Shop Split', start_time: '09:00', end_time: '20:00', hours: 8.0 }
};

// ─── Master Employees List ───
const employees = [
  { id: 14, code: 'EMP-014', name: 'Abebe Kebede', role: 'Head of Retail', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 15, code: 'EMP-015', name: 'Sara Tefera', role: 'Shift Supervisor', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 18, code: 'EMP-018', name: 'Dawit Yohannes', role: 'Senior Cashier', org_unit_name: 'Customer Cashiers', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 22, code: 'EMP-022', name: 'Bethlehem Haile', role: 'Inventory Controller', org_unit_name: 'Warehouse & Inventory', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 7,  code: 'EMP-007', name: 'Tewodros Kassahun', role: 'Security Guard', org_unit_name: 'Plant Security', entity_id: 9, entity_name: 'Hawassa Industrial Plant' },
  { id: 8,  code: 'EMP-008', name: 'Mulugeta Belete', role: 'Night Guard Lead', org_unit_name: 'Plant Security', entity_id: 9, entity_name: 'Hawassa Industrial Plant' },
  { id: 9,  code: 'EMP-009', name: 'Almaz Mengistu', role: 'HR Operations Lead', org_unit_name: 'Human Resources', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ' },
  { id: 11, code: 'EMP-011', name: 'Kassahun Bekele', role: 'Facilities Officer', org_unit_name: 'Administration', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ' }
];

// ─── Shift Assignments Dataset (Pure Scheduling Roster conforming to lines 1402–1424) ───
const assignments = ref<ShiftAssignmentRecord[]>([
  { id: 40013, employee_id: 14, employee_name: 'Abebe Kebede', employee_code: 'EMP-014', employee_role: 'Head of Retail', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-29', shift_id: 3, shift_name: 'Retail Evening', start_time: '14:30', end_time: '22:30', assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40023, employee_id: 15, employee_name: 'Sara Tefera', employee_code: 'EMP-015', employee_role: 'Shift Supervisor', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-29', shift_id: 2, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40033, employee_id: 18, employee_name: 'Dawit Yohannes', employee_code: 'EMP-018', employee_role: 'Senior Cashier', org_unit_name: 'Customer Cashiers', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-29', shift_id: 2, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', assignment_state: 'swapped', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D', swapped_with_name: 'Sara Tefera', notes: 'Trade approved by manager (SWP-2026-0031)' },
  { id: 40043, employee_id: 7,  employee_name: 'Tewodros Kassahun', employee_code: 'EMP-007', employee_role: 'Security Guard', org_unit_name: 'Plant Security', entity_id: 9, entity_name: 'Hawassa Industrial Plant', date: '2026-07-29', shift_id: 4, shift_name: 'Night Guard', start_time: '22:00', end_time: '06:00', is_overnight: true, assignment_state: 'published', shift_pattern_id: 4, pattern_name: 'PAT-GUARD-4C' },
  { id: 40053, employee_id: 9,  employee_name: 'Almaz Mengistu', employee_code: 'EMP-009', employee_role: 'HR Operations Lead', org_unit_name: 'Human Resources', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ', date: '2026-07-29', shift_id: 1, shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', assignment_state: 'published', shift_pattern_id: 1, pattern_name: 'PAT-OFF-5D' },

  { id: 40012, employee_id: 14, employee_name: 'Abebe Kebede', employee_code: 'EMP-014', employee_role: 'Head of Retail', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-28', shift_id: 2, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40022, employee_id: 15, employee_name: 'Sara Tefera', employee_code: 'EMP-015', employee_role: 'Shift Supervisor', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-28', shift_id: 3, shift_name: 'Retail Evening', start_time: '14:30', end_time: '22:30', assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40032, employee_id: 18, employee_name: 'Dawit Yohannes', employee_code: 'EMP-018', employee_role: 'Senior Cashier', org_unit_name: 'Customer Cashiers', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-28', shift_id: 2, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40054, employee_id: 9,  employee_name: 'Almaz Mengistu', employee_code: 'EMP-009', employee_role: 'HR Operations Lead', org_unit_name: 'Human Resources', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ', date: '2026-07-28', shift_id: 1, shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', assignment_state: 'cancelled', shift_pattern_id: 1, pattern_name: 'PAT-OFF-5D', notes: 'Excused Leave' },

  { id: 40014, employee_id: 14, employee_name: 'Abebe Kebede', employee_code: 'EMP-014', employee_role: 'Head of Retail', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-30', shift_id: 3, shift_name: 'Retail Evening', start_time: '14:30', end_time: '22:30', assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40024, employee_id: 15, employee_name: 'Sara Tefera', employee_code: 'EMP-015', employee_role: 'Shift Supervisor', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-30', shift_id: 2, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', assignment_state: 'planned', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40035, employee_id: 18, employee_name: 'Dawit Yohannes', employee_code: 'EMP-018', employee_role: 'Senior Cashier', org_unit_name: 'Customer Cashiers', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-31', shift_id: 3, shift_name: 'Retail Evening', start_time: '14:30', end_time: '22:30', assignment_state: 'planned' }
]);

// ─── Table Columns (Rule 9: Atomic Columns Standard) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'employee', label: 'Employee', visible: true },
  { key: 'date', label: 'Rostered Date', visible: true },
  { key: 'shift', label: 'Shift Window', visible: true },
  { key: 'state', label: 'Roster State', visible: true },
  { key: 'pattern', label: 'Pattern Origin', visible: true },
  { key: 'counterparty', label: 'Swapped With', visible: false },
  { key: 'location', label: 'Location & Unit', visible: false },
  { key: 'notes', label: 'Operational Notes', visible: false },
  { key: 'actions', label: 'Actions', visible: true }
]);

const handleToggleColumn = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  if (col) col.visible = !col.visible;
};

// ─── Filters & Search ───
const searchQuery = ref('');
const entityFilter = ref('all');
const shiftTypeFilter = ref('all');
const stateFilter = ref('all');
const selectedRowIds = ref<number[]>([]);
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

const entityOptions = [
  { label: 'All Facilities', value: 'all' },
  { label: 'Bole Commercial Branch', value: '7' },
  { label: 'Hawassa Industrial Plant', value: '9' },
  { label: 'Haleta Addis Ababa HQ', value: '3' }
];

const shiftTypeOptions = [
  { label: 'All Shifts', value: 'all' },
  { label: 'Office Day (08:30–17:30)', value: '1' },
  { label: 'Retail Morning (07:00–15:00)', value: '2' },
  { label: 'Retail Evening (14:30–22:30)', value: '3' },
  { label: 'Night Guard (22:00–06:00)', value: '4' }
];

const stateOptions = [
  { label: 'All Roster States', value: 'all' },
  { label: 'Published', value: 'published' },
  { label: 'Planned (Draft)', value: 'planned' },
  { label: 'Swapped', value: 'swapped' },
  { label: 'Cancelled', value: 'cancelled' }
];

const filteredAssignments = computed(() => {
  return assignments.value.filter(a => {
    const matchesSearch = !searchQuery.value || 
      a.employee_name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      a.employee_code.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      (a.shift_name && a.shift_name.toLowerCase().includes(searchQuery.value.toLowerCase()));
    
    const matchesEntity = entityFilter.value === 'all' || String(a.entity_id) === entityFilter.value;
    const matchesShift = shiftTypeFilter.value === 'all' || String(a.shift_id) === shiftTypeFilter.value;
    const matchesState = stateFilter.value === 'all' || a.assignment_state === stateFilter.value;

    return matchesSearch && matchesEntity && matchesShift && matchesState;
  });
});

// ─── Row Selection ───
const handleToggleSelectAll = (checked: boolean) => {
  selectedRowIds.value = checked ? filteredAssignments.value.map(a => a.id) : [];
};

const handleToggleRow = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx > -1) selectedRowIds.value.splice(idx, 1);
  else selectedRowIds.value.push(id);
};

// ─── Date Formatter ───
const formatDate = (dateStr: string) => {
  if (!dateStr) return '—';
  const d = new Date(dateStr + 'T00:00:00');
  return d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' });
};

// ─── Quick Assign Modal ───
const showQuickModal = ref(false);
const quickForm = ref({
  employee_id: '14',
  date: new Date().toISOString().slice(0, 10),
  shift_id: '2',
  notes: ''
});

const handleOpenQuickCreate = () => {
  quickForm.value = {
    employee_id: '14',
    date: new Date().toISOString().slice(0, 10),
    shift_id: '2',
    notes: ''
  };
  showQuickModal.value = true;
};

const handleExpandFullForm = () => {
  showQuickModal.value = false;
  router.push({
    path: '/hr/shift-assignments/create',
    query: {
      employee_id: quickForm.value.employee_id,
      date: quickForm.value.date,
      shift_id: quickForm.value.shift_id,
      notes: quickForm.value.notes
    }
  });
};

const handleSaveQuickAssign = () => {
  const emp = employees.find(e => String(e.id) === quickForm.value.employee_id) || employees[0];
  const isRest = quickForm.value.shift_id === 'rest';
  const shiftNum = isRest ? null : Number(quickForm.value.shift_id);
  const def = shiftNum ? shiftCatalog[shiftNum] : null;

  const newRecord: ShiftAssignmentRecord = {
    id: Date.now(),
    employee_id: emp.id,
    employee_name: emp.name,
    employee_code: emp.code,
    employee_role: emp.role,
    org_unit_name: emp.org_unit_name,
    entity_id: emp.entity_id,
    entity_name: emp.entity_name,
    date: quickForm.value.date,
    shift_id: shiftNum,
    shift_name: def ? def.name : (isRest ? 'Rest Day' : undefined),
    start_time: def ? def.start_time : undefined,
    end_time: def ? def.end_time : undefined,
    is_overnight: def ? def.is_overnight : false,
    assignment_state: 'planned',
    notes: quickForm.value.notes.trim() || undefined
  };

  assignments.value.unshift(newRecord);
  showQuickModal.value = false;
  showToast(`Shift slot assigned for ${emp.name} on ${quickForm.value.date}.`);
};

// ─── Actions & Row Details ───
const activeMenuId = ref<number | null>(null);
const toggleActionMenu = (id: number, e: Event) => {
  e.stopPropagation();
  activeMenuId.value = activeMenuId.value === id ? null : id;
};

const closeActionMenus = () => {
  activeMenuId.value = null;
};

const viewingRecord = ref<ShiftAssignmentRecord | null>(null);
const handleViewDetails = (record: ShiftAssignmentRecord) => {
  viewingRecord.value = record;
  activeMenuId.value = null;
};

const handleDeleteSingle = (id: number) => {
  assignments.value = assignments.value.filter(a => a.id !== id);
  activeMenuId.value = null;
  showToast('Shift assignment deleted.');
};

const handleUpdateStateSingle = (record: ShiftAssignmentRecord, newState: AssignmentState) => {
  record.assignment_state = newState;
  activeMenuId.value = null;
  showToast(`Updated assignment state to ${newState}.`);
};

// ─── Batch Floating Bar Handlers ───
const handleBatchPublish = () => {
  assignments.value.forEach(a => {
    if (selectedRowIds.value.includes(a.id)) {
      a.assignment_state = 'published';
    }
  });
  showToast(`Published ${selectedRowIds.value.length} shifts.`);
  selectedRowIds.value = [];
};

const handleBatchCancel = () => {
  assignments.value.forEach(a => {
    if (selectedRowIds.value.includes(a.id)) {
      a.assignment_state = 'cancelled';
    }
  });
  showToast(`Cancelled ${selectedRowIds.value.length} shifts.`);
  selectedRowIds.value = [];
};

const handleBatchDelete = () => {
  assignments.value = assignments.value.filter(a => !selectedRowIds.value.includes(a.id));
  showToast(`Deleted ${selectedRowIds.value.length} shift assignments.`);
  selectedRowIds.value = [];
};

// Dropdown options
const employeeSelectOptions = employees.map(e => ({
  value: String(e.id),
  label: `${e.name} (${e.code} • ${e.role})`
}));

const shiftSelectOptions = [
  { value: '1', label: 'Office Day (08:30 – 17:30 • 8.0h)' },
  { value: '2', label: 'Retail Morning (07:00 – 15:00 • 7.5h)' },
  { value: '3', label: 'Retail Evening (14:30 – 22:30 • 7.5h)' },
  { value: '4', label: 'Night Guard (22:00 – 06:00 • 7.25h)' },
  { value: 'rest', label: 'Rest Day (0.0h)' }
];
</script>

<template>
  <div class="shift-assignments-page" @click="closeActionMenus">
    <!-- Breadcrumb Standard (Rule 3) -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Toast Notification -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <!-- Master Unified Table Card (Rule 10) -->
    <AppDataTable
      title="Shift Assignments"
      subtitle="Manage employee shift roster assignments, planned cycles, shift patterns, and published scheduling slots across facilities."
      :columns="tableColumns"
      :show-view-action="false"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Top Right Toolbar Actions (One Create Button Standard) -->
      <template #actions>
        <AppButton variant="primary" size="sm" @click="handleOpenQuickCreate">
  <template #icon-left><Plus :size="15" /></template>
  Assign Shift
</AppButton>
      </template>

      <!-- Filter Controls Strip (Filter by Shift Window, Facility, State) -->
      <template #filters>
        <div class="filter-controls-row">
          <div class="filter-search-box">
            <Search :size="14" class="search-icon" />
            <input
              type="text"
              v-model="searchQuery"
              class="search-input"
              placeholder=""
            />
          </div>

          <!-- Shift Window Filter -->
          <div class="filter-select-item">
            <FormSelect
              v-model="shiftTypeFilter"
              :options="shiftTypeOptions"
              placeholder="Select Shift Window"
            />
          </div>

          <!-- Facility Filter -->
          <div class="filter-select-item">
            <FormSelect
              v-model="entityFilter"
              :options="entityOptions"
              placeholder="Select Facility"
            />
          </div>

          <!-- Roster State Filter -->
          <div class="filter-select-item">
            <FormSelect
              v-model="stateFilter"
              :options="stateOptions"
              placeholder="Select State"
            />
          </div>
        </div>
      </template>

      <!-- Data Table Body -->
      <template #default>
        <table class="erp-table">
          <thead>
            <tr>
              <th class="th-checkbox">
                <FormCheckbox
                  :model-value="filteredAssignments.length > 0 && selectedRowIds.length === filteredAssignments.length"
                  :indeterminate="selectedRowIds.length > 0 && selectedRowIds.length < filteredAssignments.length"
                  size="sm"
                  @change="(val) => handleToggleSelectAll(Boolean(val))"
                  aria-label="Select all rows"
                />
              </th>
              <th v-if="tableColumns.find(c => c.key === 'employee')?.visible">Employee</th>
              <th v-if="tableColumns.find(c => c.key === 'date')?.visible">Rostered Date</th>
              <th v-if="tableColumns.find(c => c.key === 'shift')?.visible">Shift Window</th>
              <th v-if="tableColumns.find(c => c.key === 'counterparty')?.visible">Swapped With</th>
              <th v-if="tableColumns.find(c => c.key === 'state')?.visible">State</th>
              <th v-if="tableColumns.find(c => c.key === 'pattern')?.visible">Pattern Origin</th>
              <th v-if="tableColumns.find(c => c.key === 'location')?.visible">Location &amp; Unit</th>
              <th v-if="tableColumns.find(c => c.key === 'notes')?.visible">Operational Notes</th>
              <th v-if="tableColumns.find(c => c.key === 'actions')?.visible" class="th-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="item in filteredAssignments"
              :key="item.id"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
            >
              <!-- Checkbox -->
              <td class="td-checkbox" @click.stop>
                <FormCheckbox
                  :model-value="selectedRowIds.includes(item.id)"
                  size="sm"
                  @change="() => handleToggleRow(item.id)"
                  aria-label="Select row"
                />
              </td>

              <!-- Employee: Squircle Avatar + Secondary Color Name + Code Subtext -->
              <td v-if="tableColumns.find(c => c.key === 'employee')?.visible">
                <div class="identity-cell">
                  <div class="avatar-squircle">
                    {{ item.employee_name.split(' ').map(n => n[0]).join('') }}
                  </div>
                  <div class="identity-info">
                    <span class="table-name-primary">{{ item.employee_name }}</span>
                    <span class="table-code-subtext">{{ item.employee_code }} &bull; {{ item.employee_role }}</span>
                  </div>
                </div>
              </td>

              <!-- Date (Tertiary Color) -->
              <td v-if="tableColumns.find(c => c.key === 'date')?.visible">
                <span class="td-tertiary">{{ formatDate(item.date) }}</span>
              </td>

              <!-- Shift Window (Plain Text) -->
              <td v-if="tableColumns.find(c => c.key === 'shift')?.visible">
                <div v-if="item.shift_id" class="shift-desc-cell">
                  <span class="shift-title">{{ item.shift_name }}</span>
                  <span class="shift-hours-sub">{{ item.start_time }} – {{ item.end_time }}</span>
                </div>
                <span v-else class="td-tertiary">Rest Day (0.0h)</span>
              </td>

              <!-- Swapped With (Counterparty) -->
              <td v-if="tableColumns.find(c => c.key === 'counterparty')?.visible">
                <span class="td-tertiary">{{ item.swapped_with_name || '—' }}</span>
              </td>

              <!-- State: Lifecycle Pills Strictly Reserved -->
              <td v-if="tableColumns.find(c => c.key === 'state')?.visible">
                <span
                  class="status-pill"
                  :class="`state-${item.assignment_state}`"
                >
                  {{ item.assignment_state.charAt(0).toUpperCase() + item.assignment_state.slice(1) }}
                </span>
              </td>

              <!-- Pattern Origin -->
              <td v-if="tableColumns.find(c => c.key === 'pattern')?.visible">
                <span class="td-tertiary">{{ item.pattern_name || '—' }}</span>
              </td>

              <!-- Location & Unit -->
              <td v-if="tableColumns.find(c => c.key === 'location')?.visible">
                <span class="td-tertiary">{{ item.entity_name }} &bull; {{ item.org_unit_name }}</span>
              </td>

              <!-- Notes -->
              <td v-if="tableColumns.find(c => c.key === 'notes')?.visible">
                <span class="td-tertiary">{{ item.notes || '—' }}</span>
              </td>

              <!-- Actions (28px x 28px action dots) -->
              <td v-if="tableColumns.find(c => c.key === 'actions')?.visible" class="td-actions">
                <div class="action-dropdown-wrapper">
                  <button
                    type="button"
                    class="btn-action-dots"
                    @click="toggleActionMenu(item.id, $event)"
                  >
                    <MoreVertical :size="14" />
                  </button>

                  <div
                    v-if="activeMenuId === item.id"
                    class="action-popover"
                    @click.stop
                  >
                    <button
                      type="button"
                      class="menu-item"
                      @click="handleViewDetails(item)"
                    >
                      <Eye :size="13" />
                      <span>View Details</span>
                    </button>
                    
                    <button
                      v-if="item.assignment_state === 'planned'"
                      type="button"
                      class="menu-item"
                      @click="handleUpdateStateSingle(item, 'published')"
                    >
                      <CheckCircle2 :size="13" />
                      <span>Publish Slot</span>
                    </button>

                    <button
                      v-if="item.assignment_state !== 'cancelled'"
                      type="button"
                      class="menu-item"
                      @click="handleUpdateStateSingle(item, 'cancelled')"
                    >
                      <X :size="13" />
                      <span>Cancel Shift</span>
                    </button>

                    <div class="menu-divider"></div>

                    <button
                      type="button"
                      class="menu-item text-danger"
                      @click="handleDeleteSingle(item.id)"
                    >
                      <Trash2 :size="13" />
                      <span>Delete</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>

            <!-- Empty State -->
            <tr v-if="filteredAssignments.length === 0">
              <td colspan="10" class="empty-state-cell">
                <div class="empty-box">
                  <p class="empty-title">No shift assignments found</p>
                  <p class="empty-sub">Adjust your search query or apply filters to view records.</p>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </template>
    </AppDataTable>

    <!-- Floating Batch Action Bar -->
    <TableFloatingBar
      :count="selectedRowIds.length"
      @delete="handleBatchDelete"
    >
      <template #custom-actions>
        <button
          type="button"
          class="btn-floating-action"
          @click="handleBatchPublish"
        >
          <CheckCircle2 :size="13" />
          <span>Publish Selected</span>
        </button>
        <button
          type="button"
          class="btn-floating-action"
          @click="handleBatchCancel"
        >
          <X :size="13" />
          <span>Cancel Selected</span>
        </button>
      </template>
    </TableFloatingBar>

    <!-- Quick Create Modal (<= 5 Required Fields Standard) -->
    <QuickCreateModal
      :show="showQuickModal"
      title="Assign Shift"
      @close="showQuickModal = false"
      @save="handleSaveQuickAssign"
      @expand="handleExpandFullForm"
    >
      <div class="quick-form-body">
        <FormSelect
          v-model="quickForm.employee_id"
          label="Employee"
          :options="employeeSelectOptions"
          placeholder="Select"
          required
        />

        <FormInput
          v-model="quickForm.date"
          label="Rostered Date"
          type="date"
          required
        />

        <FormSelect
          v-model="quickForm.shift_id"
          label="Shift Window"
          :options="shiftSelectOptions"
          placeholder="Select"
          required
        />

        <FormInput
          v-model="quickForm.notes"
          label="Operational Note"
        />
      </div>
    </QuickCreateModal>

    <!-- View Record Inspection Modal -->
    <div v-if="viewingRecord" class="modal-backdrop" @click="viewingRecord = null">
      <div class="details-modal-box" @click.stop>
        <div class="modal-header">
          <span class="modal-title">Shift Assignment Details</span>
          <button type="button" class="btn-close-modal" @click="viewingRecord = null">
            <X :size="16" />
          </button>
        </div>

        <div class="modal-content-grid">
          <div class="info-group">
            <span class="info-label">Employee</span>
            <span class="info-val-bold">{{ viewingRecord.employee_name }}</span>
            <span class="info-sub">{{ viewingRecord.employee_code }} &bull; {{ viewingRecord.employee_role }}</span>
          </div>

          <div class="info-group">
            <span class="info-label">Rostered Date</span>
            <span class="info-val">{{ formatDate(viewingRecord.date) }}</span>
          </div>

          <div class="info-group">
            <span class="info-label">Shift Window</span>
            <span class="info-val">{{ viewingRecord.shift_name || 'Rest Day' }}</span>
            <span v-if="viewingRecord.start_time" class="info-sub">{{ viewingRecord.start_time }} – {{ viewingRecord.end_time }}</span>
          </div>

          <div class="info-group">
            <span class="info-label">Pattern Origin</span>
            <span class="info-val">{{ viewingRecord.pattern_name || '—' }}</span>
          </div>

          <div v-if="viewingRecord.swapped_with_name" class="info-group">
            <span class="info-label">Swapped With</span>
            <span class="info-val">{{ viewingRecord.swapped_with_name }}</span>
          </div>

          <div class="info-group">
            <span class="info-label">Roster State</span>
            <span class="status-pill" :class="`state-${viewingRecord.assignment_state}`">
              {{ viewingRecord.assignment_state }}
            </span>
          </div>

          <div class="info-group">
            <span class="info-label">Facility &amp; Department</span>
            <span class="info-val">{{ viewingRecord.entity_name }}</span>
            <span class="info-sub">{{ viewingRecord.org_unit_name }}</span>
          </div>

          <div v-if="viewingRecord.notes" class="info-group full-width">
            <span class="info-label">Notes</span>
            <span class="info-val">{{ viewingRecord.notes }}</span>
          </div>
        </div>

        <div class="modal-footer-row">
          <AppButton variant="outline" size="sm" @click="viewingRecord = null">
            Close
          </AppButton>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.shift-assignments-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: var(--alias-color-bg-canvas, #f8fafc);
  min-height: 100vh;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
}

/* Toast */
.toast-bar {
  position: fixed;
  bottom: 24px;
  right: 24px;
  background-color: #0f172a;
  color: #ffffff;
  font-size: 13px;
  padding: 10px 16px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  gap: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  z-index: 9999;
}

.toast-fade-enter-active,
.toast-fade-leave-active {
  transition: opacity 0.2s, transform 0.2s;
}

.toast-fade-enter-from,
.toast-fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

/* Table Actions Strip */
.table-actions-strip {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-create-assignment {
  height: 36px;
  padding: 0 16px;
  display: flex;
  align-items: center;
  gap: 6px;
  background-color: #0B529C;
  color: #ffffff;
  border: 1px solid #0B529C;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s, box-shadow 0.15s;
  box-shadow: 0 1px 2px rgba(11, 82, 156, 0.12);
}

.btn-create-assignment:hover {
  background-color: #094380;
  border-color: #094380;
  box-shadow: 0 2px 6px rgba(11, 82, 156, 0.2);
}

/* Filters */
.filter-controls-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.filter-search-box {
  position: relative;
  width: 200px;
}

.search-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: #94a3b8;
  pointer-events: none;
}

.search-input {
  width: 100%;
  height: 36px;
  padding: 0 10px 0 32px;
  font-size: 13px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  color: #404040;
  outline: none;
  transition: border-color 0.15s;
}

.search-input:focus {
  border-color: #0B529C;
}

.filter-select {
  height: 36px;
  padding: 0 12px;
  font-size: 12.5px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  color: #404040;
  outline: none;
  cursor: pointer;
}

/* Table Standard */
.erp-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background-color: #fafafa;
  border-bottom: 1px solid #f1f5f9;
  user-select: none;
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  font-size: 13px;
  border-bottom: 1px solid #f8fafc;
}

.erp-table tbody tr:hover {
  background-color: #fafafa;
}

.row-selected {
  background-color: #f0f7ff !important;
}

.th-checkbox,
.td-checkbox {
  width: 40px;
  padding: 0 12px;
  text-align: center;
}

.table-checkbox {
  width: 15px;
  height: 15px;
  cursor: pointer;
  accent-color: #0B529C;
}

/* Identity Cell */
.identity-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.avatar-squircle {
  width: 32px;
  height: 32px;
  border-radius: 9px;
  background: linear-gradient(135deg, #e0f2fe, #bae6fd);
  color: #0284c7;
  font-size: 11px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.identity-info {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.table-code-subtext {
  font-size: 11.5px;
  color: #737373;
}

.td-tertiary {
  color: #737373;
  font-size: 12.5px;
}

.shift-desc-cell {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.shift-title {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.shift-hours-sub {
  font-size: 11px;
  color: #737373;
}

/* Status Pills */
.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 9px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
}

.state-planned {
  background-color: #eff6ff;
  color: #2563eb;
}

.state-published {
  background-color: #ecfdf5;
  color: #059669;
}

.state-swapped {
  background-color: #fef3c7;
  color: #d97706;
}

.state-cancelled {
  background-color: #f1f5f9;
  color: #64748b;
}

/* Actions Menu */
.th-actions,
.td-actions {
  width: 50px;
  text-align: right;
  padding-right: 14px;
}

.action-dropdown-wrapper {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 6px;
  color: #64748b;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.action-popover {
  position: absolute;
  top: 100%;
  right: 0;
  width: 140px;
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
  border: 1px solid #f1f5f9;
  padding: 4px;
  z-index: 50;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.menu-item {
  width: 100%;
  height: 30px;
  padding: 0 8px;
  display: flex;
  align-items: center;
  gap: 8px;
  background: transparent;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  color: #404040;
  cursor: pointer;
  text-align: left;
}

.menu-item:hover {
  background-color: #f8fafc;
}

.menu-item.text-danger {
  color: #ef4444;
}

.menu-item.text-danger:hover {
  background-color: #fef2f2;
}

.menu-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 2px 0;
}

/* Empty State */
.empty-state-cell {
  text-align: center;
  padding: 48px 16px;
}

.empty-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.empty-title {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
  margin: 0;
}

.empty-sub {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

/* Quick Create Body */
.quick-form-body {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 4px 0;
}

/* Floating Bar Custom Action */
.btn-floating-action {
  height: 30px;
  padding: 0 10px;
  display: flex;
  align-items: center;
  gap: 6px;
  background-color: rgba(255, 255, 255, 0.12);
  color: #ffffff;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  cursor: pointer;
}

.btn-floating-action:hover {
  background-color: rgba(255, 255, 255, 0.2);
}

/* Inspection Modal */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 16px;
}

.details-modal-box {
  width: 100%;
  max-width: 480px;
  background-color: #ffffff;
  border-radius: 12px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
  overflow: hidden;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid #f1f5f9;
}

.modal-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.btn-close-modal {
  background: transparent;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 4px;
  border-radius: 6px;
}

.btn-close-modal:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.modal-content-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
  padding: 20px;
}

.info-group {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.info-group.full-width {
  grid-column: span 2;
}

.info-label {
  font-size: 11.5px;
  color: #737373;
}

.info-val {
  font-size: 13px;
  color: #404040;
}

.info-val-bold {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.info-sub {
  font-size: 11.5px;
  color: #737373;
}

.modal-footer-row {
  display: flex;
  justify-content: flex-end;
  padding: 12px 20px;
  background-color: #f8fafc;
  border-top: 1px solid #f1f5f9;
}

.btn-modal-dismiss {
  height: 34px;
  padding: 0 16px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
}

.btn-modal-dismiss:hover {
  background-color: #f1f5f9;
}
</style>
