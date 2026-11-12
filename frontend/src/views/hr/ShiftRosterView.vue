<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  CalendarRange, List, ChevronLeft, ChevronRight,
  Plus, Search, Filter, CheckCircle2,
  ArrowLeftRight, Send, Wand2, Trash2,
  Coffee, Edit2, Calendar
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormInput from '../../components/FormInput.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

const router = useRouter();

// ─── Breadcrumbs (Rule 3: Exact Sidebar Page Name Only) ───
const breadcrumbItems = [
  { label: 'Shift Roster' }
];

// ─── View Modes (Table Directory vs. Scoped Weekly Matrix) ───
type RosterViewMode = 'table' | 'matrix';
const viewMode = ref<RosterViewMode>('table');

// ─── Types (HR_Schema_final-v4.sql lines 1402–1450) ───
export type AssignmentState = 'planned' | 'published' | 'swapped' | 'cancelled';

export interface EmployeeRosterItem {
  id: number;
  code: string;
  name: string;
  role: string;
  org_unit_id: number;
  org_unit_name: string;
  avatar_initials: string;
  entity_id: number;
  entity_name: string;
}

export interface ShiftAssignmentRecord {
  id: number;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_role: string;
  org_unit_name: string;
  entity_id: number;
  entity_name: string;
  date: string; // "YYYY-MM-DD"
  shift_id: number | null;
  shift_name?: string;
  start_time?: string;
  end_time?: string;
  is_overnight?: boolean;
  assignment_state: AssignmentState;
  shift_pattern_id?: number | null;
  pattern_name?: string;
  swapped_with_employee_id?: number | null;
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
  is_overnight?: boolean;
  color_class: string;
}

// ─── Master Shifts Catalog (HR_Schema_final-v4.sql lines 1334–1363) ───
const shiftCatalog: Record<number, ShiftDefinition> = {
  1: { id: 1, code: 'SH-OFF', name: 'Office Day', start_time: '08:30', end_time: '17:30', hours: 8.0, color_class: 'tag-blue' },
  2: { id: 2, code: 'SH-MORN', name: 'Retail Morning', start_time: '07:00', end_time: '15:00', hours: 7.5, color_class: 'tag-amber' },
  3: { id: 3, code: 'SH-EVE', name: 'Retail Evening', start_time: '14:30', end_time: '22:30', hours: 7.5, color_class: 'tag-purple' },
  4: { id: 4, code: 'SH-NIGHT', name: 'Night Guard', start_time: '22:00', end_time: '06:00', hours: 7.25, is_overnight: true, color_class: 'tag-slate' },
  5: { id: 5, code: 'SH-SPLIT', name: 'Shop Split', start_time: '09:00', end_time: '20:00', hours: 8.0, color_class: 'tag-emerald' }
};

// ─── Shift Patterns (HR_Schema_final-v4.sql lines 1364–1385) ───
const patternTemplates = [
  { id: 1, code: 'PAT-OFF-5D', name: 'Office Mon-Fri (5 Work, 2 Off)', cycle_days: 7, shifts: [1, 1, 1, 1, 1, null, null] },
  { id: 2, code: 'PAT-RETAIL-6D', name: 'Retail 6-Day Rota (6 Work, 1 Off)', cycle_days: 7, shifts: [2, 2, 2, 2, 2, 2, null] },
  { id: 3, code: 'PAT-2M2E2O', name: 'Continuous 2-2-2 (2 Morn, 2 Eve, 2 Off)', cycle_days: 6, shifts: [2, 2, 3, 3, null, null] },
  { id: 4, code: 'PAT-GUARD-4C', name: 'Night Guard 4-Day Cycle (2 Night, 2 Off)', cycle_days: 4, shifts: [4, 4, null, null] }
];

// ─── Table Columns (Rule 9: Atomic Columns Standard) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'employee', label: 'Employee', visible: true },
  { key: 'date', label: 'Rostered Date', visible: true },
  { key: 'shift', label: 'Shift Window', visible: true },
  { key: 'pattern', label: 'Pattern Origin', visible: true },
  { key: 'location', label: 'Location & Unit', visible: false },
  { key: 'state', label: 'Assignment State', visible: true },
  { key: 'counterparty', label: 'Swap Counterparty', visible: false },
  { key: 'notes', label: 'Operational Notes', visible: false },
  { key: 'actions', label: 'Actions', visible: true }
]);

// ─── Week Calendar Date Calculations ───
function addDays(d: Date, n: number): Date {
  const r = new Date(d);
  r.setDate(r.getDate() + n);
  return r;
}

function toIso(d: Date): string {
  return d.toISOString().slice(0, 10);
}

// Reference week: Monday July 27, 2026
const currentWeekStart = ref(new Date('2026-07-27T00:00:00'));

const weekDays = computed(() => {
  return Array.from({ length: 7 }, (_, i) => {
    const d = addDays(currentWeekStart.value, i);
    const iso = toIso(d);
    return {
      date: d,
      iso,
      dayName: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
      dayNum: d.getDate(),
      monthShort: d.toLocaleDateString('en-US', { month: 'short' }),
      isWeekend: i >= 5
    };
  });
});

const weekLabel = computed(() => {
  const start = weekDays.value[0];
  const end = weekDays.value[6];
  return `${start.monthShort} ${start.dayNum} – ${end.monthShort} ${end.dayNum}, ${end.date.getFullYear()}`;
});

const handlePrevWeek = () => {
  currentWeekStart.value = addDays(currentWeekStart.value, -7);
};

const handleNextWeek = () => {
  currentWeekStart.value = addDays(currentWeekStart.value, 7);
};

const handleThisWeek = () => {
  currentWeekStart.value = new Date('2026-07-27T00:00:00');
};

// ─── Master Employees List (Multi-Department) ───
const employees = ref<EmployeeRosterItem[]>([
  { id: 14, code: 'EMP-014', name: 'Abebe Kebede', role: 'Head of Retail', org_unit_id: 1, org_unit_name: 'Retail Operations', avatar_initials: 'AK', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 15, code: 'EMP-015', name: 'Sara Tefera', role: 'Shift Supervisor', org_unit_id: 1, org_unit_name: 'Retail Operations', avatar_initials: 'ST', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 18, code: 'EMP-018', name: 'Dawit Yohannes', role: 'Senior Cashier', org_unit_id: 2, org_unit_name: 'Customer Cashiers', avatar_initials: 'DY', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 22, code: 'EMP-022', name: 'Bethlehem Haile', role: 'Inventory Controller', org_unit_id: 3, org_unit_name: 'Warehouse & Inventory', avatar_initials: 'BH', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 7,  code: 'EMP-007', name: 'Tewodros Kassahun', role: 'Security Guard', org_unit_id: 4, org_unit_name: 'Plant Security', avatar_initials: 'TK', entity_id: 9, entity_name: 'Hawassa Industrial Plant' },
  { id: 8,  code: 'EMP-008', name: 'Mulugeta Belete', role: 'Night Guard Lead', org_unit_id: 4, org_unit_name: 'Plant Security', avatar_initials: 'MB', entity_id: 9, entity_name: 'Hawassa Industrial Plant' },
  { id: 9,  code: 'EMP-009', name: 'Almaz Mengistu', role: 'HR Operations Lead', org_unit_id: 5, org_unit_name: 'Human Resources', avatar_initials: 'AM', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ' },
  { id: 11, code: 'EMP-011', name: 'Kassahun Bekele', role: 'Facilities Officer', org_unit_id: 6, org_unit_name: 'Administration', avatar_initials: 'KB', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ' }
]);

// ─── Shift Assignments Dataset (HR_Schema_final-v4.sql lines 1402–1424) ───
const assignments = ref<ShiftAssignmentRecord[]>([
  // Abebe
  { id: 40011, employee_id: 14, employee_name: 'Abebe Kebede', employee_code: 'EMP-014', employee_role: 'Head of Retail', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-27', shift_id: 2, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40012, employee_id: 14, employee_name: 'Abebe Kebede', employee_code: 'EMP-014', employee_role: 'Head of Retail', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-28', shift_id: 2, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40013, employee_id: 14, employee_name: 'Abebe Kebede', employee_code: 'EMP-014', employee_role: 'Head of Retail', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-29', shift_id: 3, shift_name: 'Retail Evening', start_time: '14:30', end_time: '22:30', assignment_state: 'swapped', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D', swapped_with_employee_id: 15, swapped_with_name: 'Sara Tefera', notes: 'Trade approved by manager (SWP-2026-0031)' },
  { id: 40014, employee_id: 14, employee_name: 'Abebe Kebede', employee_code: 'EMP-014', employee_role: 'Head of Retail', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-30', shift_id: 3, shift_name: 'Retail Evening', start_time: '14:30', end_time: '22:30', assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40015, employee_id: 14, employee_name: 'Abebe Kebede', employee_code: 'EMP-014', employee_role: 'Head of Retail', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-31', shift_id: null, assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40016, employee_id: 14, employee_name: 'Abebe Kebede', employee_code: 'EMP-014', employee_role: 'Head of Retail', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-08-01', shift_id: null, assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },

  // Sara
  { id: 40021, employee_id: 15, employee_name: 'Sara Tefera', employee_code: 'EMP-015', employee_role: 'Shift Supervisor', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-27', shift_id: 3, shift_name: 'Retail Evening', start_time: '14:30', end_time: '22:30', assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40022, employee_id: 15, employee_name: 'Sara Tefera', employee_code: 'EMP-015', employee_role: 'Shift Supervisor', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-28', shift_id: 3, shift_name: 'Retail Evening', start_time: '14:30', end_time: '22:30', assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40023, employee_id: 15, employee_name: 'Sara Tefera', employee_code: 'EMP-015', employee_role: 'Shift Supervisor', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-29', shift_id: 2, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', assignment_state: 'swapped', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D', swapped_with_employee_id: 14, swapped_with_name: 'Abebe Kebede' },
  { id: 40024, employee_id: 15, employee_name: 'Sara Tefera', employee_code: 'EMP-015', employee_role: 'Shift Supervisor', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-30', shift_id: 2, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', assignment_state: 'planned', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40025, employee_id: 15, employee_name: 'Sara Tefera', employee_code: 'EMP-015', employee_role: 'Shift Supervisor', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-31', shift_id: 2, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', assignment_state: 'planned', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },

  // Dawit
  { id: 40031, employee_id: 18, employee_name: 'Dawit Yohannes', employee_code: 'EMP-018', employee_role: 'Senior Cashier', org_unit_name: 'Customer Cashiers', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-27', shift_id: 2, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40032, employee_id: 18, employee_name: 'Dawit Yohannes', employee_code: 'EMP-018', employee_role: 'Senior Cashier', org_unit_name: 'Customer Cashiers', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-28', shift_id: 2, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40033, employee_id: 18, employee_name: 'Dawit Yohannes', employee_code: 'EMP-018', employee_role: 'Senior Cashier', org_unit_name: 'Customer Cashiers', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-29', shift_id: 2, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40034, employee_id: 18, employee_name: 'Dawit Yohannes', employee_code: 'EMP-018', employee_role: 'Senior Cashier', org_unit_name: 'Customer Cashiers', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-30', shift_id: null, assignment_state: 'published', shift_pattern_id: 2, pattern_name: 'PAT-RETAIL-6D' },
  { id: 40035, employee_id: 18, employee_name: 'Dawit Yohannes', employee_code: 'EMP-018', employee_role: 'Senior Cashier', org_unit_name: 'Customer Cashiers', entity_id: 7, entity_name: 'Bole Commercial Branch', date: '2026-07-31', shift_id: 3, shift_name: 'Retail Evening', start_time: '14:30', end_time: '22:30', assignment_state: 'planned' },

  // Tewodros (Security)
  { id: 40041, employee_id: 7,  employee_name: 'Tewodros Kassahun', employee_code: 'EMP-007', employee_role: 'Security Guard', org_unit_name: 'Plant Security', entity_id: 9, entity_name: 'Hawassa Industrial Plant', date: '2026-07-27', shift_id: 4, shift_name: 'Night Guard', start_time: '22:00', end_time: '06:00', is_overnight: true, assignment_state: 'published', shift_pattern_id: 4, pattern_name: 'PAT-GUARD-4C' },
  { id: 40042, employee_id: 7,  employee_name: 'Tewodros Kassahun', employee_code: 'EMP-007', employee_role: 'Security Guard', org_unit_name: 'Plant Security', entity_id: 9, entity_name: 'Hawassa Industrial Plant', date: '2026-07-28', shift_id: 4, shift_name: 'Night Guard', start_time: '22:00', end_time: '06:00', is_overnight: true, assignment_state: 'published', shift_pattern_id: 4, pattern_name: 'PAT-GUARD-4C' },
  { id: 40043, employee_id: 7,  employee_name: 'Tewodros Kassahun', employee_code: 'EMP-007', employee_role: 'Security Guard', org_unit_name: 'Plant Security', entity_id: 9, entity_name: 'Hawassa Industrial Plant', date: '2026-07-29', shift_id: null, assignment_state: 'published', shift_pattern_id: 4, pattern_name: 'PAT-GUARD-4C' },
  { id: 40044, employee_id: 7,  employee_name: 'Tewodros Kassahun', employee_code: 'EMP-007', employee_role: 'Security Guard', org_unit_name: 'Plant Security', entity_id: 9, entity_name: 'Hawassa Industrial Plant', date: '2026-07-30', shift_id: null, assignment_state: 'published', shift_pattern_id: 4, pattern_name: 'PAT-GUARD-4C' },

  // Almaz (HQ Office)
  { id: 40051, employee_id: 9,  employee_name: 'Almaz Mengistu', employee_code: 'EMP-009', employee_role: 'HR Operations Lead', org_unit_name: 'Human Resources', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ', date: '2026-07-27', shift_id: 1, shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', assignment_state: 'published', shift_pattern_id: 1, pattern_name: 'PAT-OFF-5D' },
  { id: 40052, employee_id: 9,  employee_name: 'Almaz Mengistu', employee_code: 'EMP-009', employee_role: 'HR Operations Lead', org_unit_name: 'Human Resources', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ', date: '2026-07-28', shift_id: 1, shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', assignment_state: 'published', shift_pattern_id: 1, pattern_name: 'PAT-OFF-5D' },
  { id: 40053, employee_id: 9,  employee_name: 'Almaz Mengistu', employee_code: 'EMP-009', employee_role: 'HR Operations Lead', org_unit_name: 'Human Resources', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ', date: '2026-07-29', shift_id: 1, shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', assignment_state: 'published', shift_pattern_id: 1, pattern_name: 'PAT-OFF-5D' },
  { id: 40054, employee_id: 9,  employee_name: 'Almaz Mengistu', employee_code: 'EMP-009', employee_role: 'HR Operations Lead', org_unit_name: 'Human Resources', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ', date: '2026-07-30', shift_id: 1, shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', assignment_state: 'cancelled', shift_pattern_id: 1, pattern_name: 'PAT-OFF-5D', notes: 'Emergency medical leave granted' },
  { id: 40055, employee_id: 9,  employee_name: 'Almaz Mengistu', employee_code: 'EMP-009', employee_role: 'HR Operations Lead', org_unit_name: 'Human Resources', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ', date: '2026-07-31', shift_id: 1, shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', assignment_state: 'published', shift_pattern_id: 1, pattern_name: 'PAT-OFF-5D' }
]);

// ─── Filter & Search State ───
const searchQuery = ref('');
const entityFilter = ref('all');
const orgUnitFilter = ref('all');
const stateFilter = ref('all');
const shiftTypeFilter = ref('all');
const toastMessage = ref<string | null>(null);

// Table selection
const selectedRowIds = ref<number[]>([]);

// Table pagination
const currentPage = ref(1);
const perPage = ref(15);

// ─── Filtered Assignments ───
const filteredAssignments = computed(() => {
  return assignments.value.filter(a => {
    const matchesSearch = !searchQuery.value || 
      a.employee_name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      a.employee_code.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      (a.shift_name && a.shift_name.toLowerCase().includes(searchQuery.value.toLowerCase()));
    
    const matchesEntity = entityFilter.value === 'all' || String(a.entity_id) === entityFilter.value;
    const matchesState = stateFilter.value === 'all' || a.assignment_state === stateFilter.value;
    const matchesShift = shiftTypeFilter.value === 'all' || String(a.shift_id) === shiftTypeFilter.value;

    return matchesSearch && matchesEntity && matchesState && matchesShift;
  });
});

const paginatedAssignments = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredAssignments.value.slice(start, start + perPage.value);
});

// ─── Scoped Matrix Staff Filter & Pagination (Solving the 100+ Staff Issue) ───
const matrixOrgUnitScope = ref('all');
const matrixPage = ref(1);
const matrixStaffPerPage = 8;

const scopedMatrixEmployees = computed(() => {
  return employees.value.filter(e => {
    const matchesEntity = entityFilter.value === 'all' || String(e.entity_id) === entityFilter.value;
    const matchesUnit = matrixOrgUnitScope.value === 'all' || String(e.org_unit_id) === matrixOrgUnitScope.value;
    const matchesSearch = !searchQuery.value || e.name.toLowerCase().includes(searchQuery.value.toLowerCase());
    return matchesEntity && matchesUnit && matchesSearch;
  });
});

const totalMatrixPages = computed(() => {
  return Math.ceil(scopedMatrixEmployees.value.length / matrixStaffPerPage) || 1;
});

const pagedMatrixEmployees = computed(() => {
  const start = (matrixPage.value - 1) * matrixStaffPerPage;
  return scopedMatrixEmployees.value.slice(start, start + matrixStaffPerPage);
});

function getAssignment(employeeId: number, dateIso: string): ShiftAssignmentRecord | undefined {
  return assignments.value.find(a => a.employee_id === employeeId && a.date === dateIso);
}

// ─── Weekly Hours Calculation ───
const getEmployeeWeeklyHours = (empId: number): number => {
  const dates = weekDays.value.map(d => d.iso);
  let total = 0;
  for (const date of dates) {
    const a = getAssignment(empId, date);
    if (a && a.shift_id && a.assignment_state !== 'cancelled') {
      const shift = shiftCatalog[a.shift_id];
      total += shift ? shift.hours : 8.0;
    }
  }
  return Number(total.toFixed(1));
};

const isOvertimeRisk = (empId: number): boolean => {
  return getEmployeeWeeklyHours(empId) > 48;
};

// ─── Selection Handlers ───
const handleToggleSelectAll = (checked: boolean) => {
  selectedRowIds.value = checked ? paginatedAssignments.value.map(a => a.id) : [];
};

const handleToggleRow = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx > -1) selectedRowIds.value.splice(idx, 1);
  else selectedRowIds.value.push(id);
};

const handleToggleColumn = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  if (col) col.visible = !col.visible;
};

// ─── Shift Modal (Quick Assign / Edit) ───
const showShiftModal = ref(false);
const isEditingExisting = ref(false);
const activeAssignmentId = ref<number | null>(null);

const shiftForm = ref({
  employee_id: 14,
  date: toIso(new Date()),
  shift_id: '1',
  assignment_state: 'planned' as AssignmentState,
  swapped_with_employee_id: '',
  notes: ''
});

const openAssignModal = (emp?: EmployeeRosterItem, dateIso?: string) => {
  isEditingExisting.value = false;
  activeAssignmentId.value = null;
  shiftForm.value = {
    employee_id: emp ? emp.id : (employees.value[0]?.id || 14),
    date: dateIso || toIso(new Date()),
    shift_id: '1',
    assignment_state: 'planned',
    swapped_with_employee_id: '',
    notes: ''
  };
  showShiftModal.value = true;
};

const openEditModal = (assignment: ShiftAssignmentRecord) => {
  isEditingExisting.value = true;
  activeAssignmentId.value = assignment.id;
  shiftForm.value = {
    employee_id: assignment.employee_id,
    date: assignment.date,
    shift_id: assignment.shift_id === null ? 'rest' : String(assignment.shift_id),
    assignment_state: assignment.assignment_state,
    swapped_with_employee_id: assignment.swapped_with_employee_id ? String(assignment.swapped_with_employee_id) : '',
    notes: assignment.notes || ''
  };
  showShiftModal.value = true;
};

const handleSaveShift = () => {
  const emp = employees.value.find(e => e.id === Number(shiftForm.value.employee_id)) || employees.value[0];
  const isRest = shiftForm.value.shift_id === 'rest';
  const shiftNum = isRest ? null : Number(shiftForm.value.shift_id);
  const def = shiftNum ? shiftCatalog[shiftNum] : null;

  let cpName: string | undefined = undefined;
  if (shiftForm.value.assignment_state === 'swapped' && shiftForm.value.swapped_with_employee_id) {
    const cp = employees.value.find(e => String(e.id) === shiftForm.value.swapped_with_employee_id);
    if (cp) cpName = cp.name;
  }

  const payload: ShiftAssignmentRecord = {
    id: activeAssignmentId.value || Date.now(),
    employee_id: emp.id,
    employee_name: emp.name,
    employee_code: emp.code,
    employee_role: emp.role,
    org_unit_name: emp.org_unit_name,
    entity_id: emp.entity_id,
    entity_name: emp.entity_name,
    date: shiftForm.value.date,
    shift_id: shiftNum,
    shift_name: def ? def.name : (isRest ? 'Rest Day' : undefined),
    start_time: def ? def.start_time : undefined,
    end_time: def ? def.end_time : undefined,
    is_overnight: def ? def.is_overnight : false,
    assignment_state: shiftForm.value.assignment_state,
    swapped_with_employee_id: shiftForm.value.swapped_with_employee_id ? Number(shiftForm.value.swapped_with_employee_id) : null,
    swapped_with_name: cpName,
    notes: shiftForm.value.notes.trim() || undefined
  };

  const existingIdx = assignments.value.findIndex(a => 
    a.employee_id === payload.employee_id && a.date === payload.date
  );

  if (existingIdx > -1) {
    assignments.value[existingIdx] = payload;
  } else {
    assignments.value.unshift(payload);
  }

  showShiftModal.value = false;
  toastMessage.value = `Shift assignment saved for ${emp.name}.`;
  setTimeout(() => { toastMessage.value = null; }, 3000);
};

const handleDeleteAssignment = (id?: number) => {
  const targetId = id || activeAssignmentId.value;
  if (!targetId) return;
  assignments.value = assignments.value.filter(a => a.id !== targetId);
  showShiftModal.value = false;
  toastMessage.value = 'Shift assignment deleted.';
  setTimeout(() => { toastMessage.value = null; }, 3000);
};

// ─── Pattern Generator Modal ───
const showPatternModal = ref(false);
const patternForm = ref({
  pattern_id: '2',
  entity_id: '7',
  org_unit_id: 'all',
  overwrite_planned: true
});

const handleGenerateFromPattern = () => {
  const chosenPattern = patternTemplates.find(p => String(p.id) === patternForm.value.pattern_id);
  if (!chosenPattern) return;

  const targetEmps = employees.value.filter(e => {
    const matchEntity = patternForm.value.entity_id === 'all' || String(e.entity_id) === patternForm.value.entity_id;
    const matchUnit = patternForm.value.org_unit_id === 'all' || String(e.org_unit_id) === patternForm.value.org_unit_id;
    return matchEntity && matchUnit;
  });

  let generatedCount = 0;
  for (const emp of targetEmps) {
    weekDays.value.forEach((day, dayIdx) => {
      const cycleIdx = dayIdx % chosenPattern.cycle_days;
      const targetShiftId = chosenPattern.shifts[cycleIdx];
      const def = targetShiftId ? shiftCatalog[targetShiftId] : null;

      const existingIdx = assignments.value.findIndex(a => 
        a.employee_id === emp.id && a.date === day.iso
      );

      if (existingIdx > -1) {
        const existing = assignments.value[existingIdx];
        if (existing.assignment_state !== 'planned' || !patternForm.value.overwrite_planned) {
          return;
        }
      }

      const newAssignment: ShiftAssignmentRecord = {
        id: existingIdx > -1 ? assignments.value[existingIdx].id : (Date.now() + Math.floor(Math.random() * 100000)),
        employee_id: emp.id,
        employee_name: emp.name,
        employee_code: emp.code,
        employee_role: emp.role,
        org_unit_name: emp.org_unit_name,
        entity_id: emp.entity_id,
        entity_name: emp.entity_name,
        date: day.iso,
        shift_id: targetShiftId,
        shift_name: def ? def.name : (targetShiftId === null ? 'Rest Day' : undefined),
        start_time: def ? def.start_time : undefined,
        end_time: def ? def.end_time : undefined,
        is_overnight: def ? def.is_overnight : false,
        assignment_state: 'planned',
        shift_pattern_id: chosenPattern.id,
        pattern_name: chosenPattern.code
      };

      if (existingIdx > -1) {
        assignments.value[existingIdx] = newAssignment;
      } else {
        assignments.value.unshift(newAssignment);
      }
      generatedCount++;
    });
  }

  showPatternModal.value = false;
  toastMessage.value = `Generated ${generatedCount} shift slots from ${chosenPattern.code} for ${targetEmps.length} employee(s).`;
  setTimeout(() => { toastMessage.value = null; }, 3500);
};

// ─── Batch Floating Bar Actions ───
const handleBatchStatus = (newStatus: string) => {
  const validState = newStatus.toLowerCase() as AssignmentState;
  assignments.value.forEach(a => {
    if (selectedRowIds.value.includes(a.id)) {
      a.assignment_state = validState;
    }
  });
  toastMessage.value = `Updated ${selectedRowIds.value.length} shifts to "${newStatus}".`;
  selectedRowIds.value = [];
  setTimeout(() => { toastMessage.value = null; }, 3000);
};

const handleBatchDelete = () => {
  assignments.value = assignments.value.filter(a => !selectedRowIds.value.includes(a.id));
  toastMessage.value = `Deleted ${selectedRowIds.value.length} shift assignments.`;
  selectedRowIds.value = [];
  setTimeout(() => { toastMessage.value = null; }, 3000);
};

const handlePublishAllPlanned = () => {
  let count = 0;
  assignments.value.forEach(a => {
    if (a.assignment_state === 'planned') {
      a.assignment_state = 'published';
      count++;
    }
  });
  toastMessage.value = count > 0 
    ? `Published ${count} planned shifts. Notifications dispatched.` 
    : 'All shifts are already published.';
  setTimeout(() => { toastMessage.value = null; }, 3500);
};

// Counterparty options
const counterpartOptions = computed(() => {
  return employees.value
    .filter(e => e.id !== Number(shiftForm.value.employee_id))
    .map(e => ({ value: String(e.id), label: `${e.name} (${e.role})` }));
});
</script>

<template>
  <div class="shift-roster-page">
    <!-- Breadcrumb Standard -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Notification Toast -->
    <div v-if="toastMessage" class="action-toast">
      <CheckCircle2 :size="16" class="text-emerald-600 flex-shrink-0" />
      <span>{{ toastMessage }}</span>
    </div>

    <!-- Unified Table Card Standard (Rule 10 Layout) -->
    <AppDataTable
      title="Shift Roster"
      subtitle="Manage operational shift assignments (ShiftAssignment [DIST]), track published rosters, swap requests, and apply repeating patterns across branches and units."
      :columns="tableColumns"
      :data="filteredAssignments"
      :total-entries="filteredAssignments.length"
      :current-page="currentPage"
      :per-page="perPage"
      @update:current-page="(p) => currentPage = p"
      @update:per-page="(pp) => perPage = pp"
      @update:search-query="(q) => searchQuery = q"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Toolbar Actions Slot -->
      <template #actions>
        <div class="toolbar-actions-cluster">
          <!-- View Switcher Standard: Canonical Table vs. Scoped Matrix -->
          <div class="view-mode-pill-group">
            <button 
              type="button" 
              class="btn-view-pill" 
              :class="{ active: viewMode === 'table' }"
              @click="viewMode = 'table'"
              title="Canonical Paginated Table Directory"
            >
              <List :size="14" />
              <span>Table Directory</span>
            </button>
            <button 
              type="button" 
              class="btn-view-pill" 
              :class="{ active: viewMode === 'matrix' }"
              @click="viewMode = 'matrix'"
              title="Scoped Unit Weekly Matrix"
            >
              <CalendarRange :size="14" />
              <span>Weekly Matrix</span>
            </button>
          </div>

          <!-- Secondary Action: Pattern Auto-Generator -->
          <AppButton 
            variant="outline" 
            size="sm"
            @click="showPatternModal = true"
            title="Generate recurring shift roster from pattern"
          >
            <template #icon-left>
              <Wand2 :size="14" />
            </template>
            Generate from Pattern
          </AppButton>

          <!-- Secondary Action: Publish All Planned -->
          <AppButton 
            variant="outline" 
            size="sm"
            @click="handlePublishAllPlanned"
            title="Publish all draft shifts in current view"
          >
            <template #icon-left>
              <Send :size="14" />
            </template>
            Publish Drafts
          </AppButton>

          <!-- Primary Action: Assign Shift -->
          <AppButton 
            variant="primary" 
            size="sm"
            @click="openAssignModal()"
          >
            <template #icon-left>
              <Plus :size="15" />
            </template>
            Assign Shift
          </AppButton>
        </div>
      </template>

      <!-- Filter Panel Slot -->
      <template #filter-panel>
        <div class="filter-panel-grid">
          <FormSelect
            v-model="entityFilter"
            label="Location / Branch"
            placeholder="Select"
            :options="[
              { value: 'all', label: 'All Branches' },
              { value: '7', label: 'Bole Commercial Branch' },
              { value: '9', label: 'Hawassa Industrial Plant' },
              { value: '3', label: 'Haleta Addis Ababa HQ' }
            ]"
          />

          <FormSelect
            v-model="stateFilter"
            label="Assignment State"
            placeholder="Select"
            :options="[
              { value: 'all', label: 'All States' },
              { value: 'planned', label: 'Planned (Draft)' },
              { value: 'published', label: 'Published (Active)' },
              { value: 'swapped', label: 'Swapped (Shift Trade)' },
              { value: 'cancelled', label: 'Cancelled' }
            ]"
          />

          <FormSelect
            v-model="shiftTypeFilter"
            label="Shift Window"
            placeholder="Select"
            :options="[
              { value: 'all', label: 'All Shift Types' },
              { value: '1', label: 'Office Day (08:30–17:30)' },
              { value: '2', label: 'Retail Morning (07:00–15:00)' },
              { value: '3', label: 'Retail Evening (14:30–22:30)' },
              { value: '4', label: 'Night Guard (22:00–06:00)' }
            ]"
          />
        </div>
      </template>

      <!-- MODE 1: CANONICAL TABLE DIRECTORY (Rule 8, 9, 10 Standard) -->
      <template v-if="viewMode === 'table'" #default>
        <div class="table-responsive">
          <table class="erp-table">
            <thead>
              <tr>
                <th class="th-checkbox">
                  <FormCheckbox 
                    :model-value="selectedRowIds.length === paginatedAssignments.length && paginatedAssignments.length > 0"
                    :indeterminate="selectedRowIds.length > 0 && selectedRowIds.length < paginatedAssignments.length"
                    size="sm"
                    @change="(val) => handleToggleSelectAll(Boolean(val))"
                    aria-label="Select all rows"
                  />
                </th>
                <th v-if="tableColumns.find(c => c.key === 'employee')?.visible">Employee</th>
                <th v-if="tableColumns.find(c => c.key === 'date')?.visible">Rostered Date</th>
                <th v-if="tableColumns.find(c => c.key === 'shift')?.visible">Assigned Shift</th>
                <th v-if="tableColumns.find(c => c.key === 'pattern')?.visible">Pattern Source</th>
                <th v-if="tableColumns.find(c => c.key === 'location')?.visible">Branch & Unit</th>
                <th v-if="tableColumns.find(c => c.key === 'state')?.visible">State</th>
                <th v-if="tableColumns.find(c => c.key === 'counterparty')?.visible">Swap Counterparty</th>
                <th v-if="tableColumns.find(c => c.key === 'notes')?.visible">Notes</th>
                <th class="th-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="item in paginatedAssignments" 
                :key="item.id"
                :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
              >
                <!-- Selection Checkbox -->
                <td class="td-checkbox" @click.stop>
                  <FormCheckbox 
                    :model-value="selectedRowIds.includes(item.id)"
                    size="sm"
                    @change="() => handleToggleRow(item.id)"
                    aria-label="Select row"
                  />
                </td>

                <!-- 1. Employee (Name in Secondary #404040, Role/Code in Tertiary #737373) -->
                <td v-if="tableColumns.find(c => c.key === 'employee')?.visible" class="td-identity">
                  <div class="identity-flex">
                    <div class="squircle-avatar-small">
                      <span>{{ item.employee_name.split(' ').map(n => n[0]).join('') }}</span>
                    </div>
                    <div class="identity-texts">
                      <span class="emp-name-link" @click="openEditModal(item)">{{ item.employee_name }}</span>
                      <span class="emp-code-sub">{{ item.employee_code }} • {{ item.employee_role }}</span>
                    </div>
                  </div>
                </td>

                <!-- 2. Rostered Date -->
                <td v-if="tableColumns.find(c => c.key === 'date')?.visible" class="td-tertiary">
                  <span class="date-plain">{{ item.date }}</span>
                </td>

                <!-- 3. Shift Window -->
                <td v-if="tableColumns.find(c => c.key === 'shift')?.visible" class="td-tertiary">
                  <div v-if="item.shift_id" class="shift-cell-info">
                    <span class="shift-title">{{ item.shift_name }}</span>
                    <span class="shift-time-range">{{ item.start_time }} – {{ item.end_time }} <span v-if="item.is_overnight" class="badge-overnight">+1</span></span>
                  </div>
                  <span v-else class="text-rest-plain">Rest Day / Off</span>
                </td>

                <!-- 4. Pattern Source -->
                <td v-if="tableColumns.find(c => c.key === 'pattern')?.visible" class="td-tertiary">
                  <span>{{ item.pattern_name || 'Manual Assignment' }}</span>
                </td>

                <!-- 5. Location & Unit (Column Hider default false) -->
                <td v-if="tableColumns.find(c => c.key === 'location')?.visible" class="td-tertiary">
                  <span>{{ item.entity_name }} ({{ item.org_unit_name }})</span>
                </td>

                <!-- 6. State (Strict Status Pill) -->
                <td v-if="tableColumns.find(c => c.key === 'state')?.visible">
                  <span class="status-pill" :class="`pill-${item.assignment_state}`">
                    <ArrowLeftRight v-if="item.assignment_state === 'swapped'" :size="10" />
                    <span class="capitalize">{{ item.assignment_state }}</span>
                  </span>
                </td>

                <!-- 7. Counterparty -->
                <td v-if="tableColumns.find(c => c.key === 'counterparty')?.visible" class="td-tertiary">
                  <span>{{ item.swapped_with_name || '—' }}</span>
                </td>

                <!-- 8. Notes -->
                <td v-if="tableColumns.find(c => c.key === 'notes')?.visible" class="td-tertiary">
                  <span>{{ item.notes || '—' }}</span>
                </td>

                <!-- Actions -->
                <td class="td-actions">
                  <button 
                    type="button" 
                    class="btn-row-action" 
                    @click="openEditModal(item)"
                    title="Manage Shift"
                  >
                    <Edit2 :size="14" />
                  </button>
                  <button 
                    type="button" 
                    class="btn-row-action text-red-500 hover:text-red-700" 
                    @click="handleDeleteAssignment(item.id)"
                    title="Delete Shift"
                  >
                    <Trash2 :size="14" />
                  </button>
                </td>
              </tr>

              <tr v-if="paginatedAssignments.length === 0">
                <td :colspan="tableColumns.filter(c => c.visible).length + 2" class="td-empty">
                  No shift assignments found for the current criteria.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>

      <!-- MODE 2: SCOPED UNIT WEEKLY MATRIX (Solving the 100+ Staff Issue) -->
      <template v-else-if="viewMode === 'matrix'" #customTable>
        <div class="matrix-view-container">
          <!-- Matrix Scoping & Week Navigation Controls -->
          <div class="matrix-scoped-toolbar">
            <div class="matrix-left-scopers">
              <!-- Unit / Squad Scoper -->
              <div class="scoper-item">
                <span class="scoper-label">Scoping Unit:</span>
                <div class="scoper-select">
                  <FormSelect
                    v-model="matrixOrgUnitScope"
                    label=""
                    placeholder="Select"
                    :options="[
                      { value: 'all', label: `All Staff (${employees.length})` },
                      { value: '1', label: 'Retail Operations (2)' },
                      { value: '2', label: 'Customer Cashiers (1)' },
                      { value: '3', label: 'Warehouse & Inventory (1)' },
                      { value: '4', label: 'Plant Security Squad (2)' },
                      { value: '5', label: 'Human Resources (1)' },
                      { value: '6', label: 'Administration (1)' }
                    ]"
                  />
                </div>
              </div>

              <!-- Week Navigator -->
              <div class="matrix-week-navigator">
                <button type="button" class="btn-matrix-nav" @click="handlePrevWeek" title="Previous Week">
                  <ChevronLeft :size="15" />
                </button>
                <span class="matrix-week-text">{{ weekLabel }}</span>
                <button type="button" class="btn-matrix-nav" @click="handleNextWeek" title="Next Week">
                  <ChevronRight :size="15" />
                </button>
                <button type="button" class="btn-matrix-today" @click="handleThisWeek">This Week</button>
              </div>
            </div>

            <!-- Matrix Staff Pagination (8 Staff per View to Prevent Scrolling Bloat) -->
            <div class="matrix-staff-pagination">
              <span class="staff-page-indicator">
                Showing {{ (matrixPage - 1) * matrixStaffPerPage + 1 }}–{{ Math.min(matrixPage * matrixStaffPerPage, scopedMatrixEmployees.length) }} of {{ scopedMatrixEmployees.length }} staff
              </span>
              <div class="page-arrow-buttons">
                <button 
                  type="button" 
                  class="btn-page-arrow" 
                  :disabled="matrixPage <= 1"
                  @click="matrixPage--"
                >
                  <ChevronLeft :size="14" />
                </button>
                <button 
                  type="button" 
                  class="btn-page-arrow" 
                  :disabled="matrixPage >= totalMatrixPages"
                  @click="matrixPage++"
                >
                  <ChevronRight :size="14" />
                </button>
              </div>
            </div>
          </div>

          <!-- The Weekly Matrix Grid -->
          <div class="matrix-grid-scroll">
            <div class="matrix-table-grid">
              <!-- Matrix Header Row -->
              <div class="m-grid-header">
                <div class="col-emp-head">
                  <span>Rostered Staff ({{ scopedMatrixEmployees.length }})</span>
                </div>
                <div 
                  v-for="day in weekDays" 
                  :key="day.iso" 
                  class="col-day-head"
                  :class="{ 'is-weekend': day.isWeekend }"
                >
                  <div class="day-head-top">
                    <span class="day-name">{{ day.dayName }}</span>
                    <span class="day-month-short">{{ day.monthShort }}</span>
                  </div>
                  <div class="day-num">{{ day.dayNum }}</div>
                </div>
                <div class="col-load-head">
                  <span>Weekly Load</span>
                </div>
              </div>

              <!-- Matrix Body Rows -->
              <div 
                v-for="emp in pagedMatrixEmployees" 
                :key="emp.id"
                class="m-grid-row"
              >
                <!-- Employee Card -->
                <div class="col-emp-cell">
                  <div class="squircle-avatar-matrix">
                    <span>{{ emp.avatar_initials }}</span>
                  </div>
                  <div class="emp-matrix-details">
                    <span class="emp-name-matrix">{{ emp.name }}</span>
                    <span class="emp-role-matrix">{{ emp.role }} • {{ emp.org_unit_name }}</span>
                  </div>
                </div>

                <!-- 7 Daily Slots -->
                <div 
                  v-for="day in weekDays" 
                  :key="day.iso" 
                  class="col-day-cell"
                  :class="{ 'is-weekend': day.isWeekend }"
                >
                  <!-- Has Assignment -->
                  <template v-if="getAssignment(emp.id, day.iso)">
                    <!-- Working Shift Card -->
                    <div 
                      v-if="getAssignment(emp.id, day.iso)?.shift_id" 
                      class="shift-card-tile"
                      :class="`state-${getAssignment(emp.id, day.iso)?.assignment_state}`"
                      @click="openEditModal(getAssignment(emp.id, day.iso)!)"
                      title="Click to manage assignment"
                    >
                      <div class="tile-top-row">
                        <span class="tile-shift-name">{{ getAssignment(emp.id, day.iso)?.shift_name }}</span>
                        <span v-if="getAssignment(emp.id, day.iso)?.is_overnight" class="badge-overnight">+1</span>
                      </div>
                      <div class="tile-time-range">
                        {{ getAssignment(emp.id, day.iso)?.start_time }} – {{ getAssignment(emp.id, day.iso)?.end_time }}
                      </div>
                      <div class="tile-footer-state">
                        <span class="status-pill-mini" :class="`pill-${getAssignment(emp.id, day.iso)?.assignment_state}`">
                          <ArrowLeftRight v-if="getAssignment(emp.id, day.iso)?.assignment_state === 'swapped'" :size="9" />
                          <span class="capitalize">{{ getAssignment(emp.id, day.iso)?.assignment_state }}</span>
                        </span>
                      </div>
                    </div>

                    <!-- Rest Day Tile -->
                    <div 
                      v-else 
                      class="rest-card-tile"
                      @click="openEditModal(getAssignment(emp.id, day.iso)!)"
                      title="Rest Day. Click to assign shift."
                    >
                      <Coffee :size="12" class="text-slate-400 mr-1" />
                      <span>Off</span>
                    </div>
                  </template>

                  <!-- Empty Slot -->
                  <template v-else>
                    <button 
                      type="button" 
                      class="btn-add-slot-trigger"
                      @click="openAssignModal(emp, day.iso)"
                      title="Assign Shift"
                    >
                      <Plus :size="13" />
                    </button>
                  </template>
                </div>

                <!-- Weekly Hours Total -->
                <div class="col-load-cell">
                  <span 
                    class="load-hours-text"
                    :class="isOvertimeRisk(emp.id) ? 'hours-alert' : 'hours-normal'"
                  >
                    {{ getEmployeeWeeklyHours(emp.id) }}h
                  </span>
                  <span v-if="isOvertimeRisk(emp.id)" class="ot-statutory-pill" title="Exceeds statutory 48h/week limit">
                    &gt;48h OT
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Bottom Legend Strip -->
          <div class="matrix-legend-footer">
            <div class="legend-cluster">
              <span class="legend-heading">Active Shifts:</span>
              <div class="legend-items">
                <span class="legend-pill tag-blue">Office Day (8.0h)</span>
                <span class="legend-pill tag-amber">Retail Morning (7.5h)</span>
                <span class="legend-pill tag-purple">Retail Evening (7.5h)</span>
                <span class="legend-pill tag-slate">Night Guard (7.25h)</span>
              </div>
            </div>
            <div class="legend-sep"></div>
            <div class="legend-cluster">
              <span class="legend-heading">State Badges:</span>
              <div class="legend-items">
                <span class="status-pill pill-planned">Planned</span>
                <span class="status-pill pill-published">Published</span>
                <span class="status-pill pill-swapped"><ArrowLeftRight :size="10" /> Swapped</span>
                <span class="status-pill pill-cancelled">Cancelled</span>
              </div>
            </div>
          </div>
        </div>
      </template>
    </AppDataTable>

    <!-- Floating Batch Action Bar (Standard Component) -->
    <TableFloatingBar
      :show="selectedRowIds.length > 0"
      :selected-count="selectedRowIds.length"
      :total-count="filteredAssignments.length"
      :show-duplicate="false"
      :show-edit="false"
      @change-status="handleBatchStatus"
      @delete="handleBatchDelete"
      @close="selectedRowIds = []"
    />

    <!-- Quick Assign / Edit Shift Modal (Rule 4 Standard) -->
    <QuickCreateModal
      :show="showShiftModal"
      :title="isEditingExisting ? `Manage Shift Assignment` : `Assign Shift`"
      @close="showShiftModal = false"
      @save="handleSaveShift"
    >
      <div class="assign-form-stack">
        <FormSelect
          v-model="shiftForm.employee_id"
          label="Employee"
          placeholder="Select"
          :options="employees.map(e => ({ value: e.id, label: `${e.name} (${e.code} — ${e.role})` }))"
        />

        <div class="form-grid-2">
          <FormInput
            v-model="shiftForm.date"
            label="Date"
            type="date"
            required
          />

          <FormSelect
            v-model="shiftForm.shift_id"
            label="Shift Schedule"
            placeholder="Select"
            :options="[
              { value: '1', label: 'SH-OFF — Office Day (08:30 – 17:30, 8.0h)' },
              { value: '2', label: 'SH-MORN — Retail Morning (07:00 – 15:00, 7.5h)' },
              { value: '3', label: 'SH-EVE — Retail Evening (14:30 – 22:30, 7.5h)' },
              { value: '4', label: 'SH-NIGHT — Night Guard (22:00 – 06:00, 7.25h)' },
              { value: '5', label: 'SH-SPLIT — Shop Split (09:00 – 20:00, 8.0h)' },
              { value: 'rest', label: 'Designated Rest Day / Off (0h)' }
            ]"
          />
        </div>

        <div class="form-grid-2">
          <FormSelect
            v-model="shiftForm.assignment_state"
            label="Assignment State"
            placeholder="Select"
            :options="[
              { value: 'planned', label: 'Planned (Draft Schedule)' },
              { value: 'published', label: 'Published (Active On-Roster)' },
              { value: 'swapped', label: 'Swapped (Shift Trade)' },
              { value: 'cancelled', label: 'Cancelled (Absence / Sick)' }
            ]"
          />

          <FormSelect
            v-if="shiftForm.assignment_state === 'swapped'"
            v-model="shiftForm.swapped_with_employee_id"
            label="Swapped With Counterparty"
            placeholder="Select"
            :options="counterpartOptions"
          />
        </div>

        <FormTextarea
          v-model="shiftForm.notes"
          label="Operational Notes / Swap Details"
          :rows="2"
        />

        <!-- Clear / Delete Action -->
        <div v-if="isEditingExisting" class="modal-delete-strip">
          <button 
            type="button" 
            class="btn-delete-plain" 
            @click="handleDeleteAssignment()"
          >
            <Trash2 :size="14" />
            <span>Delete / Clear Shift Assignment</span>
          </button>
        </div>
      </div>
    </QuickCreateModal>

    <!-- Generate Roster from Pattern Modal -->
    <QuickCreateModal
      :show="showPatternModal"
      title="Generate Roster from Shift Pattern"
      @close="showPatternModal = false"
      @save="handleGenerateFromPattern"
    >
      <div class="pattern-generate-stack">
        <p class="modal-intro-text">
          Roll out a repeating statutory rotation pattern across rostered staff for the current week. 
          Stamps <code class="text-xs bg-slate-100 px-1 py-0.5 rounded">shift_pattern_id</code> generator provenance.
        </p>

        <FormSelect
          v-model="patternForm.pattern_id"
          label="Shift Pattern Template"
          placeholder="Select"
          :options="patternTemplates.map(p => ({ value: String(p.id), label: `${p.code} — ${p.name}` }))"
        />

        <div class="form-grid-2">
          <FormSelect
            v-model="patternForm.entity_id"
            label="Target Branch / Location"
            placeholder="Select"
            :options="[
              { value: 'all', label: 'All Active Branches' },
              { value: '7', label: 'Bole Commercial Branch' },
              { value: '9', label: 'Hawassa Industrial Plant' },
              { value: '3', label: 'Haleta Addis Ababa HQ' }
            ]"
          />

          <FormSelect
            v-model="patternForm.org_unit_id"
            label="Target Operational Unit"
            placeholder="Select"
            :options="[
              { value: 'all', label: 'All Staff in Location' },
              { value: '1', label: 'Retail Operations' },
              { value: '2', label: 'Customer Cashiers' },
              { value: '4', label: 'Plant Security Squad' },
              { value: '5', label: 'Human Resources' }
            ]"
          />
        </div>

        <div class="mt-2">
          <FormCheckbox
            v-model="patternForm.overwrite_planned"
            label="Overwrite Existing Planned Shifts"
            description="Replaces unconfirmed draft shifts for the week while preserving already published or swapped assignments."
          />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.shift-roster-page {
  padding: 0;
  background-color: #f8fafc;
  min-height: 100vh;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
}

.action-toast {
  position: fixed;
  bottom: 2rem;
  right: 2rem;
  display: flex;
  align-items: center;
  gap: 0.625rem;
  background: #ffffff;
  color: #404040;
  padding: 0.75rem 1.25rem;
  border-radius: 8px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
  border: 1px solid #e2e8f0;
  font-size: 13.5px;
  font-weight: 500;
  z-index: 9999;
}

/* Toolbar Actions Cluster */
.toolbar-actions-cluster {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-wrap: wrap;
}

/* Dual View Mode Switcher Pills */
.view-mode-pill-group {
  display: flex;
  align-items: center;
  background-color: #f1f5f9;
  padding: 3px;
  border-radius: 8px;
  gap: 2px;
}

.btn-view-pill {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  padding: 5px 10px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #737373;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-view-pill.active {
  background-color: #ffffff;
  color: #0B529C;
  font-weight: 600;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

.btn-view-pill:hover:not(.active) {
  color: #404040;
}

/* Secondary Button Standard (Rule 6: 8px-10px border-radius) */
.btn-secondary-action {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  height: 38px;
  padding: 0 12px;
  background-color: #ffffff;
  color: #404040;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-secondary-action:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

/* Primary Button Standard */
.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  height: 38px;
  padding: 0 14px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.btn-primary-action:hover {
  background-color: #09427d;
}

/* Filter Panel Grid */
.filter-panel-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 1rem;
  padding: 1rem 1.5rem;
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}

/* Table Responsive (Rule 8, 9 Standard) */
.table-responsive {
  width: 100%;
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
  font-size: 12px;
  font-weight: 600;
  color: #737373;
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  font-size: 13px;
  color: #737373;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.erp-table tr:hover td {
  background-color: #fafbfc;
}

.erp-table tr.row-selected td {
  background-color: #f0f7ff;
}

.th-checkbox, .td-checkbox {
  width: 40px;
  text-align: center;
  padding: 8px 12px !important;
}

.td-identity {
  color: #404040 !important;
}

.identity-flex {
  display: flex;
  align-items: center;
  gap: 0.625rem;
}

/* Avatar Squircle Standard */
.squircle-avatar-small {
  width: 32px;
  height: 32px;
  border-radius: 10px;
  background: #e0f2fe;
  color: #0369a1;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11.5px;
  font-weight: 600;
  flex-shrink: 0;
}

.identity-texts {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.emp-name-link {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
  cursor: pointer;
  transition: color 0.15s ease;
}

.emp-name-link:hover {
  color: #0B529C;
  text-decoration: underline;
}

.emp-code-sub {
  font-size: 11px;
  color: #737373;
}

.date-plain {
  font-size: 13px;
  color: #404040;
  font-weight: 500;
}

.shift-cell-info {
  display: flex;
  flex-direction: column;
}

.shift-title {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.shift-time-range {
  font-size: 11px;
  color: #737373;
  display: flex;
  align-items: center;
  gap: 4px;
}

.text-rest-plain {
  font-size: 12px;
  color: #94a3b8;
  font-style: italic;
}

.badge-overnight {
  font-size: 9px;
  font-weight: 700;
  background: #ede9fe;
  color: #6d28d9;
  padding: 0 4px;
  border-radius: 3px;
}

/* Status Pills (Rule 9 Standard) */
.status-pill {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  padding: 2px 10px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 500;
}

.status-pill-mini {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  padding: 1px 5px;
  border-radius: 4px;
  font-size: 9.5px;
  font-weight: 600;
}

.pill-planned { background: #eff6ff; color: #2563eb; }
.pill-published { background: #ecfdf5; color: #059669; }
.pill-swapped { background: #f5f3ff; color: #7c3aed; }
.pill-cancelled { background: #fef2f2; color: #dc2626; }

.th-actions, .td-actions {
  width: 90px;
  text-align: right;
  padding-right: 16px !important;
}

.btn-row-action {
  background: transparent;
  border: none;
  color: #94a3b8;
  padding: 4px 6px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-row-action:hover {
  background: #f1f5f9;
  color: #404040;
}

.td-empty {
  text-align: center;
  padding: 3rem !important;
  color: #94a3b8;
  font-size: 13.5px;
}

/* ══════════════════════════════════════════════════════════════
   SCOPED MATRIX VIEW STYLES
   ══════════════════════════════════════════════════════════════ */
.matrix-view-container {
  display: flex;
  flex-direction: column;
  background: #ffffff;
}

.matrix-scoped-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.875rem 1.5rem;
  border-bottom: 1px solid #e2e8f0;
  background: #fafbfc;
  flex-wrap: wrap;
  gap: 1rem;
}

.matrix-left-scopers {
  display: flex;
  align-items: center;
  gap: 1.25rem;
  flex-wrap: wrap;
}

.scoper-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.scoper-label {
  font-size: 12.5px;
  font-weight: 600;
  color: #404040;
  white-space: nowrap;
}

.scoper-select {
  width: 220px;
}

.scoper-select :deep(.form-group) {
  margin-bottom: 0;
}

.matrix-week-navigator {
  display: flex;
  align-items: center;
  gap: 0.375rem;
}

.btn-matrix-nav {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  background: #ffffff;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-matrix-nav:hover {
  background: #f8fafc;
  border-color: #cbd5e1;
}

.matrix-week-text {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
  min-width: 170px;
  text-align: center;
}

.btn-matrix-today {
  height: 30px;
  padding: 0 10px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  background: #ffffff;
  color: #737373;
  font-size: 11.5px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-matrix-today:hover {
  background: #f8fafc;
  color: #404040;
}

.matrix-staff-pagination {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.staff-page-indicator {
  font-size: 12px;
  color: #737373;
}

.page-arrow-buttons {
  display: flex;
  gap: 3px;
}

.btn-page-arrow {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  background: #ffffff;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-page-arrow:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.btn-page-arrow:not(:disabled):hover {
  background: #f1f5f9;
}

/* Matrix Table Grid */
.matrix-grid-scroll {
  overflow-x: auto;
}

.matrix-table-grid {
  min-width: 1040px;
  display: flex;
  flex-direction: column;
}

.m-grid-header {
  display: grid;
  grid-template-columns: 220px repeat(7, 1fr) 95px;
  background: #fafafa;
  border-bottom: 1px solid #e2e8f0;
}

.col-emp-head {
  padding: 10px 16px;
  font-size: 12px;
  font-weight: 600;
  color: #737373;
  display: flex;
  align-items: center;
}

.col-day-head {
  padding: 10px 6px;
  border-left: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.col-day-head.is-weekend {
  background: #f8fafc;
}

.day-head-top {
  display: flex;
  align-items: center;
  gap: 4px;
}

.day-name {
  font-size: 11px;
  font-weight: 600;
  color: #737373;
}

.day-month-short {
  font-size: 10px;
  color: #94a3b8;
}

.day-num {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.col-load-head {
  padding: 10px 6px;
  border-left: 1px solid #e2e8f0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
  color: #737373;
  background: #fafafa;
}

.m-grid-row {
  display: grid;
  grid-template-columns: 220px repeat(7, 1fr) 95px;
  border-bottom: 1px solid #f1f5f9;
  transition: background-color 0.15s ease;
}

.m-grid-row:hover {
  background-color: #fafbfc;
}

.col-emp-cell {
  padding: 10px 14px;
  display: flex;
  align-items: center;
  gap: 0.625rem;
}

.squircle-avatar-matrix {
  width: 34px;
  height: 34px;
  border-radius: 11px;
  background: #e0f2fe;
  color: #0369a1;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
  flex-shrink: 0;
}

.emp-matrix-details {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.emp-name-matrix {
  font-size: 12.5px;
  font-weight: 600;
  color: #404040;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.emp-role-matrix {
  font-size: 10.5px;
  color: #737373;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.col-day-cell {
  border-left: 1px solid #f1f5f9;
  padding: 5px;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 70px;
}

.col-day-cell.is-weekend {
  background: #fafafa;
}

.col-load-cell {
  border-left: 1px solid #f1f5f9;
  padding: 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2px;
  background: #ffffff;
}

.load-hours-text {
  font-size: 12.5px;
  font-weight: 600;
}

.hours-normal { color: #404040; }
.hours-alert { color: #b45309; }

.ot-statutory-pill {
  font-size: 9px;
  font-weight: 700;
  background: #fef3c7;
  color: #b45309;
  padding: 1px 4px;
  border-radius: 4px;
}

/* Shift Card Tile */
.shift-card-tile {
  width: 100%;
  height: 100%;
  padding: 5px 7px;
  border-radius: 6px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 2px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.shift-card-tile:hover {
  border-color: #0B529C;
  box-shadow: 0 2px 6px rgba(11, 82, 156, 0.08);
}

.shift-card-tile.state-cancelled {
  background: #fef2f2;
  border-color: #fecaca;
  opacity: 0.75;
}

.tile-top-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.tile-shift-name {
  font-size: 11px;
  font-weight: 600;
  color: #404040;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.tile-time-range {
  font-size: 10px;
  color: #737373;
}

.tile-footer-state {
  margin-top: 1px;
}

.rest-card-tile {
  width: 100%;
  height: 100%;
  border: 1px dashed #e2e8f0;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  color: #94a3b8;
  cursor: pointer;
  transition: all 0.15s ease;
}

.rest-card-tile:hover {
  border-color: #cbd5e1;
  background: #f8fafc;
  color: #64748b;
}

.btn-add-slot-trigger {
  width: 100%;
  height: 100%;
  min-height: 48px;
  border: 1px dashed transparent;
  border-radius: 6px;
  background: transparent;
  color: transparent;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-add-slot-trigger:hover {
  border-color: #0B529C;
  background: #f0f7ff;
  color: #0B529C;
}

/* Bottom Legend Strip */
.matrix-legend-footer {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  padding: 0.75rem 1.5rem;
  background: #fafafa;
  border-top: 1px solid #e2e8f0;
  flex-wrap: wrap;
}

.legend-cluster {
  display: flex;
  align-items: center;
  gap: 0.625rem;
}

.legend-sep {
  width: 1px;
  height: 16px;
  background: #e2e8f0;
}

.legend-heading {
  font-size: 11.5px;
  font-weight: 600;
  color: #737373;
}

.legend-items {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.legend-pill {
  font-size: 10.5px;
  padding: 2px 7px;
  border-radius: 4px;
  font-weight: 500;
}

.tag-blue { background: #e0f2fe; color: #0369a1; }
.tag-amber { background: #fef3c7; color: #b45309; }
.tag-purple { background: #f3e8ff; color: #7e22ce; }
.tag-slate { background: #f1f5f9; color: #475569; }

/* Modals */
.assign-form-stack, .pattern-generate-stack {
  display: flex;
  flex-direction: column;
  gap: 0.875rem;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

.modal-intro-text {
  font-size: 12.5px;
  color: #737373;
  line-height: 1.45;
  margin-bottom: 0.25rem;
}

.modal-delete-strip {
  margin-top: 0.5rem;
  padding-top: 0.75rem;
  border-top: 1px solid #f1f5f9;
  display: flex;
  justify-content: flex-start;
}

.btn-delete-plain {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  background: transparent;
  border: none;
  color: #ef4444;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  padding: 4px 6px;
  border-radius: 4px;
  transition: background-color 0.15s ease;
}

.btn-delete-plain:hover {
  background-color: #fef2f2;
}
</style>
