<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Activity, Clock, UserCheck, AlertTriangle, AlertCircle, 
  CheckCircle2, Plus, Search, Filter, MoreVertical, Eye,
  Calendar, Check, X, Building2, User, ChevronLeft, ChevronRight,
  RotateCcw, Sparkles, Fingerprint, ShieldCheck, MapPin, 
  Smartphone, Wifi, Radio, ArrowDownLeft, ArrowUpRight,
  Lock, Unlock
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import MetricCard from '../../components/MetricCard.vue';
import UnderlineTabs, { type UnderlineTabItem } from '../../components/UnderlineTabs.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormInput from '../../components/FormInput.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';

const router = useRouter();

// ─── Breadcrumb Standard (Rule 3: Exact Sidebar Page Name Only) ───
const breadcrumbItems = [
  { label: 'Daily Attendance' }
];

// ─── Active Tab State (Rule 1: UnderlineTabs for Sub-sections/Views) ───
type TabKey = 'reconciliation' | 'punches' | 'exceptions';
const activeTab = ref<TabKey>('reconciliation');

// ─── Filter & Scope State ───
const selectedEntityFilter = ref('all');
const selectedShiftFilter = ref('all');
const selectedStatusFilter = ref('all');
const searchQuery = ref('');
const currentDateIso = ref('2026-07-29'); // Wednesday
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Date Navigation ───
const formattedCurrentDate = computed(() => {
  const d = new Date(currentDateIso.value + 'T00:00:00');
  return d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' });
});

const handlePrevDay = () => {
  const d = new Date(currentDateIso.value + 'T00:00:00');
  d.setDate(d.getDate() - 1);
  currentDateIso.value = d.toISOString().slice(0, 10);
};

const handleNextDay = () => {
  const d = new Date(currentDateIso.value + 'T00:00:00');
  d.setDate(d.getDate() + 1);
  currentDateIso.value = d.toISOString().slice(0, 10);
};

const handleToday = () => {
  currentDateIso.value = '2026-07-29';
};

// ─── Catalogues ───
const entityOptions = [
  { value: 'all', label: 'All Facilities & Branches' },
  { value: '7', label: 'Bole Commercial Branch' },
  { value: '9', label: 'Hawassa Industrial Plant' },
  { value: '3', label: 'Haleta Addis Ababa HQ' }
];

const shiftFilterOptions = [
  { value: 'all', label: 'All Shifts' },
  { value: '1', label: 'Office Day (08:30–17:30)' },
  { value: '2', label: 'Retail Morning (07:00–15:00)' },
  { value: '3', label: 'Retail Evening (14:30–22:30)' },
  { value: '4', label: 'Night Guard (22:00–06:00)' }
];

const statusFilterOptions = [
  { value: 'all', label: 'All Statuses' },
  { value: 'on_duty', label: 'On Duty Right Now' },
  { value: 'present', label: 'Present / Completed' },
  { value: 'late', label: 'Late Arrival' },
  { value: 'absent', label: 'Absent' },
  { value: 'on_leave', label: 'On Approved Leave' },
  { value: 'scheduled', label: 'Upcoming Scheduled' }
];

// ─── Types conforming to HR_Schema_final-v4.sql Section 7 ───
export type AttendanceDayStatus = 'present' | 'absent' | 'late' | 'early_leave' | 'half_day' | 'on_leave' | 'holiday' | 'weekend' | 'on_duty' | 'scheduled';

export interface AttendanceDayRecord {
  id: number;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_role: string;
  org_unit_name: string;
  entity_id: number;
  entity_name: string;
  date: string;
  shift_id: number | null;
  shift_name: string;
  scheduled_start: string;
  scheduled_end: string;
  day_status: AttendanceDayStatus;
  first_in_at: string | null;
  first_in_device: string | null;
  last_out_at: string | null;
  last_out_device: string | null;
  scheduled_minutes: number;
  worked_minutes: number;
  late_minutes: number;
  early_leave_minutes: number;
  overtime_minutes: number;
  variance_text: string;
  is_locked: boolean;
}

export interface AttendanceLogRecord {
  id: number;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  entity_id: number;
  entity_name: string;
  device_code: string;
  device_name: string;
  direction: 'in' | 'out';
  source: 'device' | 'mobile' | 'web' | 'manual';
  punched_at: string;
  time_display: string;
  verification_method: string;
}

export interface AttendanceExceptionRecord {
  id: number;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  entity_name: string;
  attendance_day_id: number;
  date: string;
  exception_type: 'missed_punch' | 'late_arrival' | 'early_departure' | 'unscheduled_absence' | 'device_mismatch';
  exception_state: 'open' | 'justified' | 'rejected' | 'regularized';
  scheduled_time: string;
  actual_time: string;
  employee_note?: string;
  requested_in?: string;
  requested_out?: string;
  reviewer_name?: string;
  resolution_note?: string;
}

// ─── Dataset: AttendanceDay (Reconciliation) ───
const attendanceDays = ref<AttendanceDayRecord[]>([
  {
    id: 810221,
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-014',
    employee_role: 'Head of Retail',
    org_unit_name: 'Retail Operations',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    date: '2026-07-29',
    shift_id: 3,
    shift_name: 'Retail Evening',
    scheduled_start: '14:30',
    scheduled_end: '22:30',
    day_status: 'on_duty',
    first_in_at: '14:26:12',
    first_in_device: 'DEV-BOLE-01',
    last_out_at: null,
    last_out_device: null,
    scheduled_minutes: 450,
    worked_minutes: 270,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    variance_text: 'Punctual (-4m Early In)',
    is_locked: false
  },
  {
    id: 810222,
    employee_id: 15,
    employee_name: 'Sara Tefera',
    employee_code: 'EMP-015',
    employee_role: 'Shift Supervisor',
    org_unit_name: 'Retail Operations',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    date: '2026-07-29',
    shift_id: 2,
    shift_name: 'Retail Morning',
    scheduled_start: '07:00',
    scheduled_end: '15:00',
    day_status: 'present',
    first_in_at: '06:55:04',
    first_in_device: 'DEV-BOLE-01',
    last_out_at: '15:02:19',
    last_out_device: 'DEV-BOLE-01',
    scheduled_minutes: 450,
    worked_minutes: 456,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 60,
    variance_text: 'Completed (+60m OT approved)',
    is_locked: true
  },
  {
    id: 810223,
    employee_id: 18,
    employee_name: 'Dawit Yohannes',
    employee_code: 'EMP-018',
    employee_role: 'Senior Cashier',
    org_unit_name: 'Customer Cashiers',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    date: '2026-07-29',
    shift_id: 2,
    shift_name: 'Retail Morning',
    scheduled_start: '07:00',
    scheduled_end: '15:00',
    day_status: 'late',
    first_in_at: '07:18:40',
    first_in_device: 'DEV-BOLE-01',
    last_out_at: '15:05:11',
    last_out_device: 'DEV-BOLE-01',
    scheduled_minutes: 450,
    worked_minutes: 436,
    late_minutes: 18,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    variance_text: '+18m Late Clock-In',
    is_locked: false
  },
  {
    id: 810224,
    employee_id: 22,
    employee_name: 'Bethlehem Haile',
    employee_code: 'EMP-022',
    employee_role: 'Inventory Controller',
    org_unit_name: 'Warehouse & Inventory',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    date: '2026-07-29',
    shift_id: 5,
    shift_name: 'Shop Split',
    scheduled_start: '09:00',
    scheduled_end: '20:00',
    day_status: 'on_duty',
    first_in_at: '08:58:22',
    first_in_device: 'DEV-BOLE-01',
    last_out_at: null,
    last_out_device: null,
    scheduled_minutes: 480,
    worked_minutes: 360,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    variance_text: 'On Duty (Mid-day break)',
    is_locked: false
  },
  {
    id: 810225,
    employee_id: 9,
    employee_name: 'Almaz Mengistu',
    employee_code: 'EMP-009',
    employee_role: 'HR Operations Lead',
    org_unit_name: 'Human Resources',
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    date: '2026-07-29',
    shift_id: 1,
    shift_name: 'Office Day',
    scheduled_start: '08:30',
    scheduled_end: '17:30',
    day_status: 'present',
    first_in_at: '08:28:10',
    first_in_device: 'DEV-HQ-01',
    last_out_at: '17:35:44',
    last_out_device: 'DEV-HQ-01',
    scheduled_minutes: 480,
    worked_minutes: 487,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 120,
    variance_text: 'Completed (+2.0h OT approved)',
    is_locked: true
  },
  {
    id: 810226,
    employee_id: 11,
    employee_name: 'Kassahun Bekele',
    employee_code: 'EMP-011',
    employee_role: 'Facilities Officer',
    org_unit_name: 'Administration',
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    date: '2026-07-29',
    shift_id: 1,
    shift_name: 'Office Day',
    scheduled_start: '08:30',
    scheduled_end: '17:30',
    day_status: 'on_leave',
    first_in_at: null,
    first_in_device: null,
    last_out_at: null,
    last_out_device: null,
    scheduled_minutes: 480,
    worked_minutes: 0,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    variance_text: 'Approved Annual Leave',
    is_locked: true
  },
  {
    id: 810227,
    employee_id: 7,
    employee_name: 'Tewodros Kassahun',
    employee_code: 'EMP-007',
    employee_role: 'Security Guard',
    org_unit_name: 'Plant Security',
    entity_id: 9,
    entity_name: 'Hawassa Industrial Plant',
    date: '2026-07-29',
    shift_id: 4,
    shift_name: 'Night Guard',
    scheduled_start: '22:00',
    scheduled_end: '06:00',
    day_status: 'scheduled',
    first_in_at: null,
    first_in_device: null,
    last_out_at: null,
    last_out_device: null,
    scheduled_minutes: 435,
    worked_minutes: 0,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    variance_text: 'Starts tonight at 22:00',
    is_locked: false
  },
  {
    id: 810228,
    employee_id: 8,
    employee_name: 'Mulugeta Belete',
    employee_code: 'EMP-008',
    employee_role: 'Night Guard Lead',
    org_unit_name: 'Plant Security',
    entity_id: 9,
    entity_name: 'Hawassa Industrial Plant',
    date: '2026-07-29',
    shift_id: 4,
    shift_name: 'Night Guard',
    scheduled_start: '22:00',
    scheduled_end: '06:00',
    day_status: 'absent',
    first_in_at: null,
    first_in_device: null,
    last_out_at: null,
    last_out_device: null,
    scheduled_minutes: 435,
    worked_minutes: 0,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    variance_text: 'Unscheduled Absence',
    is_locked: false
  }
]);

// ─── Dataset: AttendanceLog (Raw Biometric Stream) ───
const rawPunches = ref<AttendanceLogRecord[]>([
  { id: 700301, employee_id: 14, employee_name: 'Abebe Kebede', employee_code: 'EMP-014', entity_id: 7, entity_name: 'Bole Commercial Branch', device_code: 'DEV-BOLE-01', device_name: 'Bole Fingerprint Scanner', direction: 'in', source: 'device', punched_at: '2026-07-29T11:26:12Z', time_display: '14:26:12', verification_method: 'Biometric Fingerprint Match' },
  { id: 700302, employee_id: 15, employee_name: 'Sara Tefera', employee_code: 'EMP-015', entity_id: 7, entity_name: 'Bole Commercial Branch', device_code: 'DEV-BOLE-01', device_name: 'Bole Fingerprint Scanner', direction: 'out', source: 'device', punched_at: '2026-07-29T12:02:19Z', time_display: '15:02:19', verification_method: 'Biometric Fingerprint Match' },
  { id: 700303, employee_id: 18, employee_name: 'Dawit Yohannes', employee_code: 'EMP-018', entity_id: 7, entity_name: 'Bole Commercial Branch', device_code: 'DEV-BOLE-01', device_name: 'Bole Fingerprint Scanner', direction: 'out', source: 'device', punched_at: '2026-07-29T12:05:11Z', time_display: '15:05:11', verification_method: 'Biometric Fingerprint Match' },
  { id: 700304, employee_id: 22, employee_name: 'Bethlehem Haile', employee_code: 'EMP-022', entity_id: 7, entity_name: 'Bole Commercial Branch', device_code: 'DEV-BOLE-01', device_name: 'Bole Fingerprint Scanner', direction: 'in', source: 'device', punched_at: '2026-07-29T05:58:22Z', time_display: '08:58:22', verification_method: 'Biometric Fingerprint Match' },
  { id: 700305, employee_id: 9,  employee_name: 'Almaz Mengistu', employee_code: 'EMP-009', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ', device_code: 'DEV-HQ-01', device_name: 'HQ Lobby Face Terminal', direction: 'out', source: 'device', punched_at: '2026-07-29T14:35:44Z', time_display: '17:35:44', verification_method: 'Facial Biometric Recognition' },
  { id: 700306, employee_id: 9,  employee_name: 'Almaz Mengistu', employee_code: 'EMP-009', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ', device_code: 'DEV-HQ-01', device_name: 'HQ Lobby Face Terminal', direction: 'in', source: 'device', punched_at: '2026-07-29T05:28:10Z', time_display: '08:28:10', verification_method: 'Facial Biometric Recognition' },
  { id: 700307, employee_id: 18, employee_name: 'Dawit Yohannes', employee_code: 'EMP-018', entity_id: 7, entity_name: 'Bole Commercial Branch', device_code: 'DEV-BOLE-01', device_name: 'Bole Fingerprint Scanner', direction: 'in', source: 'device', punched_at: '2026-07-29T04:18:40Z', time_display: '07:18:40', verification_method: 'Biometric Fingerprint Match' },
  { id: 700308, employee_id: 15, employee_name: 'Sara Tefera', employee_code: 'EMP-015', entity_id: 7, entity_name: 'Bole Commercial Branch', device_code: 'DEV-BOLE-01', device_name: 'Bole Fingerprint Scanner', direction: 'in', source: 'device', punched_at: '2026-07-29T03:55:04Z', time_display: '06:55:04', verification_method: 'Biometric Fingerprint Match' }
]);

// ─── Dataset: AttendanceException (Anomalies) ───
const exceptions = ref<AttendanceExceptionRecord[]>([
  { id: 5501, employee_id: 18, employee_name: 'Dawit Yohannes', employee_code: 'EMP-018', entity_name: 'Bole Commercial Branch', attendance_day_id: 810223, date: '2026-07-29', exception_type: 'late_arrival', exception_state: 'open', scheduled_time: '07:00', actual_time: '07:18 (+18m)', employee_note: 'Unexpected road traffic delay near Megenagna roundabout.' },
  { id: 5502, employee_id: 8,  employee_name: 'Mulugeta Belete', employee_code: 'EMP-008', entity_name: 'Hawassa Industrial Plant', attendance_day_id: 810228, date: '2026-07-29', exception_type: 'unscheduled_absence', exception_state: 'open', scheduled_time: '22:00', actual_time: 'No punch recorded', employee_note: 'Guard lead did not report for scheduled night roster.' },
  { id: 5503, employee_id: 14, employee_name: 'Abebe Kebede', employee_code: 'EMP-014', entity_name: 'Bole Commercial Branch', attendance_day_id: 810212, date: '2026-07-28', exception_type: 'missed_punch', exception_state: 'regularized', scheduled_time: '15:00', actual_time: 'Manual Regularization', employee_note: 'Fingerprint device offline during power cut at 15:00.', requested_out: '15:00' },
  { id: 5504, employee_id: 7,  employee_name: 'Tewodros Kassahun', employee_code: 'EMP-007', entity_name: 'Hawassa Industrial Plant', attendance_day_id: 810214, date: '2026-07-27', exception_type: 'early_departure', exception_state: 'justified', scheduled_time: '15:00', actual_time: '14:35 (-25m)', employee_note: 'Granted medical permission by shift supervisor.' }
]);

// ─── Metric Cards Computed (Rule 2 Standard) ───
const metrics = computed(() => {
  const onDutyCount = attendanceDays.value.filter(d => d.day_status === 'on_duty').length;
  const presentCount = attendanceDays.value.filter(d => d.day_status === 'present').length;
  const lateCount = attendanceDays.value.filter(d => d.day_status === 'late').length;
  const absentCount = attendanceDays.value.filter(d => d.day_status === 'absent').length;
  const openExceptions = exceptions.value.filter(e => e.exception_state === 'open').length;

  return {
    onDutyCount,
    presentCount,
    lateCount,
    absentCount,
    openExceptions
  };
});

// ─── Tabs Configuration (Rule 1: UnderlineTabs Standard) ───
const underlineTabs = computed<UnderlineTabItem<TabKey>[]>(() => [
  { id: 'reconciliation', label: 'Daily Attendance', count: attendanceDays.value.length, icon: Calendar },
  { id: 'punches', label: 'Attendance Logs', count: rawPunches.value.length, icon: Fingerprint },
  { id: 'exceptions', label: 'Attendance Exceptions', count: exceptions.value.filter(e => e.exception_state === 'open').length, icon: AlertTriangle, badgeVariant: 'warning' }
]);

// ─── Table Columns Standard (Rule 9: Atomic Columns) ───
const reconciliationColumns = ref<ColumnDef[]>([
  { key: 'employee', label: 'Employee', visible: true },
  { key: 'shift', label: 'Rostered Shift', visible: true },
  { key: 'clock_in', label: 'First In', visible: true },
  { key: 'clock_out', label: 'Last Out', visible: true },
  { key: 'worked_hours', label: 'Worked Hours', visible: true },
  { key: 'overtime', label: 'Overtime', visible: true },
  { key: 'variance', label: 'Shift Variance', visible: true },
  { key: 'status', label: 'Status', visible: true },
  { key: 'is_locked', label: 'Payroll Lock', visible: true },
  { key: 'location', label: 'Location', visible: false },
  { key: 'actions', label: 'Actions', visible: true }
]);

const handleToggleColumn = (colKey: string) => {
  const col = reconciliationColumns.value.find(c => c.key === colKey);
  if (col) col.visible = !col.visible;
};

// ─── Filtered Data ───
const filteredAttendanceDays = computed(() => {
  return attendanceDays.value.filter(row => {
    const matchesSearch = !searchQuery.value ||
      row.employee_name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      row.employee_code.toLowerCase().includes(searchQuery.value.toLowerCase());

    const matchesEntity = selectedEntityFilter.value === 'all' || String(row.entity_id) === selectedEntityFilter.value;
    const matchesShift = selectedShiftFilter.value === 'all' || String(row.shift_id) === selectedShiftFilter.value;
    const matchesStatus = selectedStatusFilter.value === 'all' || row.day_status === selectedStatusFilter.value;

    return matchesSearch && matchesEntity && matchesShift && matchesStatus;
  });
});

// ─── Row Selection ───
const selectedRowIds = ref<number[]>([]);
const handleToggleSelectAll = (checked: boolean) => {
  selectedRowIds.value = checked ? filteredAttendanceDays.value.map(r => r.id) : [];
};

const handleToggleRow = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx > -1) selectedRowIds.value.splice(idx, 1);
  else selectedRowIds.value.push(id);
};

// ─── Batch Floating Bar Actions ───
const handleBatchChangeStatus = (status: string) => {
  const count = selectedRowIds.value.length;
  if (status === 'Locked') {
    attendanceDays.value.forEach(d => {
      if (selectedRowIds.value.includes(d.id)) {
        d.is_locked = true;
      }
    });
    showToast(`Locked ${count} attendance day records for payroll.`);
  } else if (status === 'Approved') {
    attendanceDays.value.forEach(d => {
      if (selectedRowIds.value.includes(d.id)) {
        d.day_status = 'present';
        d.variance_text = 'Approved by Supervisor';
      }
    });
    showToast(`Approved ${count} attendance day records.`);
  } else if (status === 'Pending') {
    attendanceDays.value.forEach(d => {
      if (selectedRowIds.value.includes(d.id)) {
        d.is_locked = false;
      }
    });
    showToast(`Unlocked ${count} attendance day records.`);
  } else {
    showToast(`Batch status '${status}' applied to ${count} records.`);
  }
  selectedRowIds.value = [];
};

const handleBatchLockDays = () => {
  const count = selectedRowIds.value.length;
  attendanceDays.value.forEach(d => {
    if (selectedRowIds.value.includes(d.id)) {
      d.is_locked = !d.is_locked;
    }
  });
  showToast(`Toggled lock status on ${count} attendance records.`);
  selectedRowIds.value = [];
};

const handleBatchExport = () => {
  showToast(`Exported ${selectedRowIds.value.length} attendance records to CSV.`);
  selectedRowIds.value = [];
};

// ─── Manual Punch Modal ───
const showManualPunchModal = ref(false);
const manualPunchForm = ref({
  employee_id: '14',
  entity_id: '7',
  date: currentDateIso.value,
  time: '08:30',
  direction: 'in' as 'in' | 'out',
  source: 'manual',
  reason: ''
});

const employeeSelectOptions = [
  { value: '14', label: 'Abebe Kebede (EMP-014 • Head of Retail)' },
  { value: '15', label: 'Sara Tefera (EMP-015 • Shift Supervisor)' },
  { value: '18', label: 'Dawit Yohannes (EMP-018 • Senior Cashier)' },
  { value: '22', label: 'Bethlehem Haile (EMP-022 • Inventory Controller)' },
  { value: '9',  label: 'Almaz Mengistu (EMP-009 • HR Operations Lead)' },
  { value: '7',  label: 'Tewodros Kassahun (EMP-007 • Security Guard)' },
  { value: '8',  label: 'Mulugeta Belete (EMP-008 • Night Guard Lead)' }
];

const handleOpenManualPunch = () => {
  manualPunchForm.value = {
    employee_id: '14',
    entity_id: '7',
    date: currentDateIso.value,
    time: '15:00',
    direction: 'out',
    source: 'manual',
    reason: ''
  };
  showManualPunchModal.value = true;
};

const handleSaveManualPunch = () => {
  const emp = employeeSelectOptions.find(e => e.value === manualPunchForm.value.employee_id);
  const selectedEntity = entityOptions.find(e => e.value === String(manualPunchForm.value.entity_id));
  const newLog: AttendanceLogRecord = {
    id: Date.now(),
    employee_id: Number(manualPunchForm.value.employee_id),
    employee_name: emp ? emp.label.split(' (')[0] : 'Employee',
    employee_code: emp ? emp.label.match(/EMP-\d+/)?.[0] || 'EMP' : 'EMP',
    entity_id: Number(manualPunchForm.value.entity_id),
    entity_name: selectedEntity ? selectedEntity.label : 'Bole Commercial Branch',
    device_code: 'MANUAL-HR',
    device_name: 'Manual HR Override Entry',
    direction: manualPunchForm.value.direction,
    source: 'manual',
    punched_at: `${manualPunchForm.value.date}T${manualPunchForm.value.time}:00Z`,
    time_display: `${manualPunchForm.value.time}:00`,
    verification_method: 'Manual Supervisor Keying'
  };

  rawPunches.value.unshift(newLog);
  showManualPunchModal.value = false;
  showToast(`Manual ${manualPunchForm.value.direction.toUpperCase()} punch logged for ${newLog.employee_name}.`);
};

// ─── Inspection Modal ───
const inspectingDay = ref<AttendanceDayRecord | null>(null);
const handleInspectDay = (row: AttendanceDayRecord) => {
  inspectingDay.value = row;
};

// ─── Regularize Exception Modal ───
const inspectingException = ref<AttendanceExceptionRecord | null>(null);
const exceptionResolutionForm = ref({
  requested_in: '',
  requested_out: '',
  reviewer_note: ''
});

const openRegularizeModal = (ex: AttendanceExceptionRecord) => {
  inspectingException.value = ex;
  exceptionResolutionForm.value = {
    requested_in: ex.requested_in || '08:30',
    requested_out: ex.requested_out || '17:30',
    reviewer_note: ''
  };
};

const handleResolveException = (ex: AttendanceExceptionRecord, state: 'justified' | 'regularized' | 'rejected') => {
  ex.exception_state = state;
  ex.resolution_note = exceptionResolutionForm.value.reviewer_note;
  ex.reviewer_name = 'Almaz Mengistu (HR Lead)';
  // If regularized, sync back into AttendanceDay
  if (state === 'regularized') {
    const day = attendanceDays.value.find(d => d.id === ex.attendance_day_id);
    if (day) {
      day.day_status = 'present';
      day.variance_text = 'Regularized by Supervisor';
      if (exceptionResolutionForm.value.requested_in) {
        day.first_in_at = exceptionResolutionForm.value.requested_in + ':00';
      }
      if (exceptionResolutionForm.value.requested_out) {
        day.last_out_at = exceptionResolutionForm.value.requested_out + ':00';
      }
    }
  }
  showToast(`Exception for ${ex.employee_name} marked as ${state}.`);
  inspectingException.value = null;
};
</script>

<template>
  <div class="daily-attendance-page">
    <!-- Breadcrumb Standard (Rule 3) -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Notification Toast -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <!-- Top KPI / Metrics Cards Grid (Rule 2 Standard) -->
    <div class="metrics-grid">
      <MetricCard
        label="On Duty"
        :value="`${metrics.onDutyCount} Staff`"
        subtext="Currently clocked in on shift"
        :icon="UserCheck"
        size="md"
        :show-menu="false"
      />

      <MetricCard
        label="Present"
        :value="`${metrics.presentCount}`"
        subtext="Completed scheduled shift"
        :icon="CheckCircle2"
        size="md"
        :show-menu="false"
      />

      <MetricCard
        label="Late Arrivals"
        :value="`${metrics.lateCount}`"
        subtext="Clocked in after shift grace period"
        :icon="AlertTriangle"
        size="md"
        :show-menu="false"
      />

      <MetricCard
        label="Open Exceptions"
        :value="`${metrics.openExceptions}`"
        subtext="Pending supervisor review"
        :icon="AlertCircle"
        size="md"
        :show-menu="false"
      />
    </div>

    <!-- Supervisor Shift Control Strip (Date & Facility Filter Bar) -->
    <div class="control-scope-strip">
      <div class="scope-date-picker-wrap">
        <button type="button" class="btn-date-nav" @click="handlePrevDay" title="Previous Day">
          <ChevronLeft :size="15" />
        </button>

        <div class="current-date-badge">
          <Calendar :size="14" class="date-icon" />
          <span class="date-text">{{ formattedCurrentDate }}</span>
          <button type="button" class="btn-today-chip" @click="handleToday">Today</button>
        </div>

        <button type="button" class="btn-date-nav" @click="handleNextDay" title="Next Day">
          <ChevronRight :size="15" />
        </button>
      </div>

      <div class="scope-filters-right">
        <!-- Live Biometric Sync Status Indicator -->
        <div class="device-heartbeat-pill">
          <span class="pulse-dot"></span>
          <span>Biometric Sync: 4 Devices Online</span>
        </div>

        <!-- Facility Filter -->
        <div class="facility-select-box">
          <select v-model="selectedEntityFilter" class="compact-select">
            <option v-for="opt in entityOptions" :key="opt.value" :value="opt.value">
              {{ opt.label }}
            </option>
          </select>
        </div>
      </div>
    </div>

    <!-- Master Unified Card Container -->
    <div class="attendance-unified-card">
      <!-- Secondary Tabs Standard (Rule 1: UnderlineTabs) -->
      <div class="card-tabs-header">
        <UnderlineTabs
          v-model="activeTab"
          :tabs="underlineTabs"
        />
      </div>

      <!-- Tab 1: Shift Roster Reconciliation View -->
      <div v-if="activeTab === 'reconciliation'" class="tab-content-area">
        <AppDataTable
          title="Daily Attendance Records"
          subtitle="Daily attendance ledger synthesized from shift rosters, punch logs, and approved leave."
          :columns="reconciliationColumns"
          :show-view-action="false"
          @toggleColumn="handleToggleColumn"
        >
          <!-- Table Toolbar Primary Action (Rule 6: 8-10px radius) -->
          <template #actions>
            <button
              type="button"
              class="btn-primary-punch"
              @click="handleOpenManualPunch"
            >
              <Plus :size="15" />
              <span>Log Manual Punch</span>
            </button>
          </template>

          <!-- Table Filters Strip -->
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

              <!-- Shift Filter -->
              <div class="filter-select-item">
                <select v-model="selectedShiftFilter" class="filter-select">
                  <option v-for="opt in shiftFilterOptions" :key="opt.value" :value="opt.value">
                    {{ opt.label }}
                  </option>
                </select>
              </div>

              <!-- Status Filter -->
              <div class="filter-select-item">
                <select v-model="selectedStatusFilter" class="filter-select">
                  <option v-for="opt in statusFilterOptions" :key="opt.value" :value="opt.value">
                    {{ opt.label }}
                  </option>
                </select>
              </div>
            </div>
          </template>

          <!-- Table Body -->
          <template #default>
            <table class="erp-table">
              <thead>
                <tr>
                  <th class="th-checkbox">
                    <input
                      type="checkbox"
                      class="table-checkbox"
                      :checked="filteredAttendanceDays.length > 0 && selectedRowIds.length === filteredAttendanceDays.length"
                      @change="handleToggleSelectAll(($event.target as HTMLInputElement).checked)"
                    />
                  </th>
                  <th v-if="reconciliationColumns.find(c => c.key === 'employee')?.visible">Employee</th>
                  <th v-if="reconciliationColumns.find(c => c.key === 'shift')?.visible">Rostered Shift</th>
                  <th v-if="reconciliationColumns.find(c => c.key === 'clock_in')?.visible">First In</th>
                  <th v-if="reconciliationColumns.find(c => c.key === 'clock_out')?.visible">Last Out</th>
                  <th v-if="reconciliationColumns.find(c => c.key === 'worked_hours')?.visible">Worked Hours</th>
                  <th v-if="reconciliationColumns.find(c => c.key === 'overtime')?.visible">Overtime</th>
                  <th v-if="reconciliationColumns.find(c => c.key === 'variance')?.visible">Shift Variance</th>
                  <th v-if="reconciliationColumns.find(c => c.key === 'status')?.visible">Status</th>
                  <th v-if="reconciliationColumns.find(c => c.key === 'is_locked')?.visible">Payroll Lock</th>
                  <th v-if="reconciliationColumns.find(c => c.key === 'location')?.visible">Location</th>
                  <th v-if="reconciliationColumns.find(c => c.key === 'actions')?.visible" class="th-actions">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="item in filteredAttendanceDays"
                  :key="item.id"
                  :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
                  @click="handleInspectDay(item)"
                >
                  <!-- Selection Checkbox -->
                  <td class="td-checkbox" @click.stop>
                    <input
                      type="checkbox"
                      class="table-checkbox"
                      :checked="selectedRowIds.includes(item.id)"
                      @change="handleToggleRow(item.id)"
                    />
                  </td>

                  <!-- Employee (Squircle avatar + Name primary + Code/Role subtext) -->
                  <td v-if="reconciliationColumns.find(c => c.key === 'employee')?.visible">
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

                  <!-- Rostered Shift -->
                  <td v-if="reconciliationColumns.find(c => c.key === 'shift')?.visible">
                    <div class="shift-desc-cell">
                      <span class="shift-title">{{ item.shift_name }}</span>
                      <span class="shift-hours-sub">{{ item.scheduled_start }} – {{ item.scheduled_end }}</span>
                    </div>
                  </td>

                  <!-- Clock-In (First In) -->
                  <td v-if="reconciliationColumns.find(c => c.key === 'clock_in')?.visible">
                    <div v-if="item.first_in_at" class="punch-time-cell">
                      <span class="punch-val-text">{{ item.first_in_at }}</span>
                      <span class="device-tag-sub">{{ item.first_in_device }}</span>
                    </div>
                    <span v-else class="td-tertiary">No punch recorded</span>
                  </td>

                  <!-- Clock-Out (Last Out) -->
                  <td v-if="reconciliationColumns.find(c => c.key === 'clock_out')?.visible">
                    <div v-if="item.last_out_at" class="punch-time-cell">
                      <span class="punch-val-text">{{ item.last_out_at }}</span>
                      <span class="device-tag-sub">{{ item.last_out_device }}</span>
                    </div>
                    <div v-else-if="item.day_status === 'on_duty'" class="on-duty-indicator">
                      <span class="pulse-indicator"></span>
                      <span>On Duty Right Now</span>
                    </div>
                    <span v-else class="td-tertiary">—</span>
                  </td>

                  <!-- Worked Hours (Net of breaks) -->
                  <td v-if="reconciliationColumns.find(c => c.key === 'worked_hours')?.visible">
                    <span v-if="item.worked_minutes > 0" class="td-tertiary">
                      {{ (item.worked_minutes / 60).toFixed(2) }} hrs
                    </span>
                    <span v-else class="td-tertiary">—</span>
                  </td>

                  <!-- Overtime Hours -->
                  <td v-if="reconciliationColumns.find(c => c.key === 'overtime')?.visible">
                    <span v-if="(item.overtime_minutes || 0) > 0" class="td-tertiary font-medium">
                      +{{ ((item.overtime_minutes || 0) / 60).toFixed(1) }} hrs
                    </span>
                    <span v-else class="td-tertiary">—</span>
                  </td>

                  <!-- Shift Variance / Punctuality -->
                  <td v-if="reconciliationColumns.find(c => c.key === 'variance')?.visible">
                    <span class="td-tertiary">{{ item.variance_text }}</span>
                  </td>

                  <!-- Attendance Status (Pill strictly reserved for status) -->
                  <td v-if="reconciliationColumns.find(c => c.key === 'status')?.visible">
                    <span class="status-pill" :class="`status-${item.day_status}`">
                      {{ item.day_status.replace('_', ' ').toUpperCase() }}
                    </span>
                  </td>

                  <!-- Lock State -->
                  <td v-if="reconciliationColumns.find(c => c.key === 'is_locked')?.visible">
                    <span v-if="item.is_locked" class="lock-indicator locked" title="Locked for Payroll">
                      <Lock :size="11" />
                      <span>Locked</span>
                    </span>
                    <span v-else class="lock-indicator open" title="Unlocked &amp; Modifiable">
                      <Unlock :size="11" />
                      <span>Open</span>
                    </span>
                  </td>

                  <!-- Location -->
                  <td v-if="reconciliationColumns.find(c => c.key === 'location')?.visible">
                    <span class="td-tertiary">{{ item.entity_name }} &bull; {{ item.org_unit_name }}</span>
                  </td>

                  <!-- Actions Dots -->
                  <td v-if="reconciliationColumns.find(c => c.key === 'actions')?.visible" class="td-actions" @click.stop>
                    <button
                      type="button"
                      class="btn-action-dots"
                      @click="handleInspectDay(item)"
                      title="Inspect Day"
                    >
                      <Eye :size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </template>
        </AppDataTable>
      </div>

      <!-- Tab 2: Live Biometric Punch Stream (AttendanceLog) -->
      <div v-else-if="activeTab === 'punches'" class="tab-content-area">
        <div class="live-punches-card">
          <div class="live-punches-header">
            <div>
              <h3 class="inner-title">Attendance Logs</h3>
              <p class="inner-subtitle">Raw punch stream capturing device scans, mobile GPS check-ins, and manual entries.</p>
            </div>
            <button type="button" class="btn-refresh-stream" @click="showToast('Punch stream refreshed.')">
              <RotateCcw :size="13" />
              <span>Refresh Feed</span>
            </button>
          </div>

          <table class="erp-table">
            <thead>
              <tr>
                <th>Punched At</th>
                <th>Employee</th>
                <th>Direction</th>
                <th>Attendance Device</th>
                <th>Biometric Verification</th>
                <th>Location</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="punch in rawPunches" :key="punch.id">
                <td>
                  <span class="table-name-primary">{{ punch.time_display }}</span>
                </td>
                <td>
                  <div class="identity-cell">
                    <div class="avatar-squircle">
                      {{ punch.employee_name.split(' ').map(n => n[0]).join('') }}
                    </div>
                    <div class="identity-info">
                      <span class="table-name-primary">{{ punch.employee_name }}</span>
                      <span class="table-code-subtext">{{ punch.employee_code }}</span>
                    </div>
                  </div>
                </td>
                <td>
                  <span class="direction-badge" :class="`dir-${punch.direction}`">
                    <ArrowDownLeft v-if="punch.direction === 'in'" :size="12" />
                    <ArrowUpRight v-else :size="12" />
                    <span>{{ punch.direction.toUpperCase() }}</span>
                  </span>
                </td>
                <td>
                  <span class="table-name-primary">{{ punch.device_code }}</span>
                  <span class="table-code-subtext">{{ punch.device_name }}</span>
                </td>
                <td>
                  <span class="td-tertiary">{{ punch.verification_method }}</span>
                </td>
                <td>
                  <span class="td-tertiary">{{ punch.entity_name }}</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Tab 3: Attendance Exceptions (AttendanceException) -->
      <div v-else-if="activeTab === 'exceptions'" class="tab-content-area">
        <div class="live-punches-card">
          <div class="live-punches-header">
            <div>
              <h3 class="inner-title">Attendance Exceptions</h3>
              <p class="inner-subtitle">Attendance anomalies including missed punches, late arrivals, and early departures requiring review.</p>
            </div>
          </div>

          <table class="erp-table">
            <thead>
              <tr>
                <th>Employee</th>
                <th>Exception Type</th>
                <th>Scheduled vs. Actual</th>
                <th>Employee Explanation / Note</th>
                <th>Resolution Status</th>
                <th class="th-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="ex in exceptions" :key="ex.id">
                <td>
                  <div class="identity-cell">
                    <div class="avatar-squircle">
                      {{ ex.employee_name.split(' ').map(n => n[0]).join('') }}
                    </div>
                    <div class="identity-info">
                      <span class="table-name-primary">{{ ex.employee_name }}</span>
                      <span class="table-code-subtext">{{ ex.employee_code }} &bull; {{ ex.entity_name }}</span>
                    </div>
                  </div>
                </td>
                <td>
                  <span class="exception-type-pill" :class="`type-${ex.exception_type}`">
                    {{ ex.exception_type.replace('_', ' ').toUpperCase() }}
                  </span>
                </td>
                <td>
                  <span class="table-name-primary">{{ ex.scheduled_time }}</span>
                  <span class="table-code-subtext">{{ ex.actual_time }}</span>
                </td>
                <td>
                  <span class="td-tertiary">{{ ex.employee_note || 'No note provided' }}</span>
                </td>
                <td>
                  <span class="status-pill" :class="`state-${ex.exception_state}`">
                    {{ ex.exception_state.toUpperCase() }}
                  </span>
                </td>
                <td class="td-actions">
                  <div v-if="ex.exception_state === 'open'" class="exception-actions-row">
                    <button
                      type="button"
                      class="btn-regularize-approve"
                      @click="openRegularizeModal(ex)"
                      title="Regularize / Inspect Anomaly"
                    >
                      <Check :size="13" />
                      <span>Regularize</span>
                    </button>
                    <button
                      type="button"
                      class="btn-regularize-reject"
                      @click="handleResolveException(ex, 'rejected')"
                      title="Reject Justification"
                    >
                      <X :size="13" />
                    </button>
                  </div>
                  <span v-else class="td-tertiary">Resolved</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Quick Manual Punch Modal -->
    <QuickCreateModal
      :show="showManualPunchModal"
      title="Log Manual Punch Entry"
      :show-expand-button="false"
      @close="showManualPunchModal = false"
      @save="handleSaveManualPunch"
    >
      <div class="quick-form-body">
        <FormSelect
          v-model="manualPunchForm.employee_id"
          label="Employee"
          :options="employeeSelectOptions"
          placeholder="Select"
          required
        />

        <FormSelect
          v-model="manualPunchForm.entity_id"
          label="Punch Location / Branch"
          :options="entityOptions.filter(e => e.value !== 'all')"
          placeholder="Select"
          required
        />

        <div class="form-2col-row">
          <FormInput
            v-model="manualPunchForm.date"
            label="Punch Date"
            type="date"
            required
          />

          <FormInput
            v-model="manualPunchForm.time"
            label="Punch Time"
            type="time"
            required
          />
        </div>

        <FormSelect
          v-model="manualPunchForm.direction"
          label="Punch Direction"
          :options="[
            { value: 'in', label: 'Clock-In (Shift Arrival)' },
            { value: 'out', label: 'Clock-Out (Shift Departure)' }
          ]"
          placeholder="Select"
          required
        />

        <FormTextarea
          v-model="manualPunchForm.reason"
          label="Operational Reason / Justification"
          placeholder="e.g. Employee badge reader timeout or temporary card replacement"
          :rows="2"
        />
      </div>
    </QuickCreateModal>

    <!-- Exception Regularization & Audit Modal (AttendanceException) -->
    <div v-if="inspectingException" class="modal-backdrop" @click="inspectingException = null">
      <div class="details-modal-box" @click.stop>
        <div class="modal-header">
          <span class="modal-title">Attendance Exception Regularization</span>
          <button type="button" class="btn-close-modal" @click="inspectingException = null">
            <X :size="16" />
          </button>
        </div>

        <div class="modal-content-grid">
          <div class="info-group">
            <span class="info-label">Employee</span>
            <span class="info-val-bold">{{ inspectingException.employee_name }}</span>
            <span class="info-sub">{{ inspectingException.employee_code }} &bull; {{ inspectingException.entity_name }}</span>
          </div>

          <div class="info-group">
            <span class="info-label">Exception Anomaly</span>
            <span class="status-pill mt-1" :class="`type-${inspectingException.exception_type}`">
              {{ inspectingException.exception_type.replace('_', ' ').toUpperCase() }}
            </span>
          </div>

          <div class="info-group">
            <span class="info-label">Scheduled Time Window</span>
            <span class="info-val">{{ inspectingException.scheduled_time }}</span>
          </div>

          <div class="info-group">
            <span class="info-label">Actual Punch Stream</span>
            <span class="info-val">{{ inspectingException.actual_time }}</span>
          </div>

          <div class="info-group full-width">
            <span class="info-label">Employee Justification Note</span>
            <p class="info-justification">{{ inspectingException.employee_note || 'No explanation submitted.' }}</p>
          </div>

          <div class="review-box full-width">
            <h4 class="review-box-title">Apply Regularized Punch Overrides to Attendance Day</h4>
            <div class="review-grid">
              <div class="form-group">
                <label class="form-label">Approved Clock-In Time</label>
                <input
                  type="time"
                  v-model="exceptionResolutionForm.requested_in"
                  class="modal-input"
                />
              </div>
              <div class="form-group">
                <label class="form-label">Approved Clock-Out Time</label>
                <input
                  type="time"
                  v-model="exceptionResolutionForm.requested_out"
                  class="modal-input"
                />
              </div>
            </div>

            <div class="form-group full-width mt-3">
              <label class="form-label">Supervisor Resolution Note / Audit</label>
              <textarea
                v-model="exceptionResolutionForm.reviewer_note"
                class="modal-textarea"
                rows="2"
                placeholder="State operational reason or audit justification for regularizing or rejecting this exception..."
              ></textarea>
            </div>
          </div>
        </div>

        <div class="modal-footer-row">
          <button type="button" class="btn-modal-dismiss" @click="inspectingException = null">
            Cancel
          </button>
          <button
            type="button"
            class="btn-reject"
            @click="handleResolveException(inspectingException, 'rejected')"
          >
            <XCircle :size="14" />
            <span>Reject Justification</span>
          </button>
          <button
            type="button"
            class="btn-modal-dismiss"
            @click="handleResolveException(inspectingException, 'justified')"
          >
            <span>Mark Justified</span>
          </button>
          <button
            type="button"
            class="btn-approve"
            @click="handleResolveException(inspectingException, 'regularized')"
          >
            <CheckCircle2 :size="14" />
            <span>Regularize &amp; Apply</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Inspection Modal (Day Detail Audit) -->
    <div v-if="inspectingDay" class="modal-backdrop" @click="inspectingDay = null">
      <div class="details-modal-box" @click.stop>
        <div class="modal-header">
          <span class="modal-title">Daily Attendance Breakdown</span>
          <button type="button" class="btn-close-modal" @click="inspectingDay = null">
            <X :size="16" />
          </button>
        </div>

        <div class="modal-content-grid">
          <div class="info-group">
            <span class="info-label">Employee</span>
            <span class="info-val-bold">{{ inspectingDay.employee_name }}</span>
            <span class="info-sub">{{ inspectingDay.employee_code }} &bull; {{ inspectingDay.employee_role }}</span>
          </div>

          <div class="info-group">
            <span class="info-label">Rostered Shift</span>
            <span class="info-val">{{ inspectingDay.shift_name }}</span>
            <span class="info-sub">{{ inspectingDay.scheduled_start }} – {{ inspectingDay.scheduled_end }}</span>
          </div>

          <div class="info-group">
            <span class="info-label">First In</span>
            <span class="info-val">{{ inspectingDay.first_in_at || 'No punch' }}</span>
            <span v-if="inspectingDay.first_in_device" class="info-sub">Device: {{ inspectingDay.first_in_device }}</span>
          </div>

          <div class="info-group">
            <span class="info-label">Last Out</span>
            <span class="info-val">{{ inspectingDay.last_out_at || (inspectingDay.day_status === 'on_duty' ? 'On Duty Right Now' : 'No punch') }}</span>
            <span v-if="inspectingDay.last_out_device" class="info-sub">Device: {{ inspectingDay.last_out_device }}</span>
          </div>

          <div class="info-group">
            <span class="info-label">Worked Hours</span>
            <span class="info-val">{{ inspectingDay.worked_minutes > 0 ? (inspectingDay.worked_minutes / 60).toFixed(2) + ' hrs' : '0.00 hrs' }}</span>
            <span class="info-sub">Scheduled: {{ (inspectingDay.scheduled_minutes / 60).toFixed(2) }} hrs</span>
          </div>

          <div class="info-group">
            <span class="info-label">Approved Overtime</span>
            <span class="info-val">{{ (inspectingDay.overtime_minutes || 0) > 0 ? ((inspectingDay.overtime_minutes || 0) / 60).toFixed(1) + ' hrs' : '0.0 hrs' }}</span>
            <span class="info-sub">Approved via OvertimeRequest</span>
          </div>

          <div class="info-group">
            <span class="info-label">Status</span>
            <span class="status-pill" :class="`status-${inspectingDay.day_status}`">
              {{ inspectingDay.day_status.replace('_', ' ').toUpperCase() }}
            </span>
          </div>

          <div class="info-group">
            <span class="info-label">Payroll Lock</span>
            <div class="mt-1">
              <span v-if="inspectingDay.is_locked" class="lock-indicator locked">
                <Lock :size="12" />
                <span>Locked for Payroll</span>
              </span>
              <span v-else class="lock-indicator open">
                <Unlock :size="12" />
                <span>Unlocked &amp; Editable</span>
              </span>
            </div>
          </div>

          <div class="info-group full-width">
            <span class="info-label">Shift Variance &amp; Punctuality</span>
            <span class="info-val">{{ inspectingDay.variance_text }}</span>
          </div>
        </div>

        <div class="modal-footer-row">
          <button type="button" class="btn-modal-dismiss" @click="inspectingDay = null">
            Close Breakdown
          </button>
        </div>
      </div>
    </div>

    <!-- Floating Batch Action Bar -->
    <TableFloatingBar
      v-if="activeTab === 'reconciliation'"
      :show="selectedRowIds.length > 0"
      :selected-count="selectedRowIds.length"
      :total-count="filteredAttendanceDays.length"
      :show-duplicate="false"
      :show-edit="false"
      :show-delete="false"
      :show-change-status="true"
      @change-status="handleBatchChangeStatus"
      @deactivate="handleBatchLockDays"
      @export="handleBatchExport"
      @close="selectedRowIds = []"
      @select-all="handleToggleSelectAll(true)"
    />
  </div>
</template>

<style scoped>
.daily-attendance-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 20px 24px 80px 24px;
  background-color: var(--alias-color-bg-canvas, #f8fafc);
  min-height: 100vh;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
}

/* ─── Metrics Grid (Rule 2) ─── */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

@media (max-width: 1024px) {
  .metrics-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 640px) {
  .metrics-grid {
    grid-template-columns: 1fr;
  }
}

/* ─── Scope Strip ─── */
.control-scope-strip {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 10px 16px;
  gap: 16px;
}

.scope-date-picker-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-date-nav {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 6px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-date-nav:hover {
  background: #f8fafc;
  color: #404040;
  border-color: #cbd5e1;
}

.current-date-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 5px 12px;
}

.date-icon {
  color: #0B529C;
}

.date-text {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.btn-today-chip {
  padding: 2px 8px;
  border-radius: 4px;
  background: #0B529C;
  color: #ffffff;
  border: none;
  font-size: 11px;
  font-weight: 500;
  cursor: pointer;
}

.scope-filters-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.device-heartbeat-pill {
  display: flex;
  align-items: center;
  gap: 6px;
  background: #ecfdf5;
  border: 1px solid #a7f3d0;
  color: #065f46;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 500;
}

.pulse-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background-color: #10b981;
  animation: pulse 1.8s infinite;
}

.compact-select {
  height: 34px;
  padding: 0 10px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  cursor: pointer;
}

/* ─── Unified Card ─── */
.attendance-unified-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}

.card-tabs-header {
  padding: 4px 16px 0;
  background: #ffffff;
  border-bottom: 1px solid #f1f5f9;
}

.tab-content-area {
  padding: 16px 20px 24px;
}

/* ─── Toolbar Action ─── */
.btn-primary-punch {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 16px;
  background-color: #0B529C;
  color: #ffffff;
  border: 1px solid #0B529C;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
  box-shadow: 0 1px 2px rgba(11, 82, 156, 0.12);
}

.btn-primary-punch:hover {
  background-color: #094380;
  border-color: #094380;
}

/* ─── Filters Row ─── */
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
}

.search-input {
  width: 100%;
  height: 36px;
  padding: 0 10px 0 32px;
  font-size: 13px;
  color: #404040;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
}

.filter-select {
  height: 36px;
  padding: 0 10px;
  font-size: 13px;
  color: #404040;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
}

/* ─── Table Design (Rule 8 & 9) ─── */
.erp-table {
  width: 100%;
  border-collapse: collapse;
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
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.erp-table tbody tr:hover {
  background-color: #f8fafc;
  cursor: pointer;
}

.row-selected {
  background-color: #f0f7ff !important;
}

.th-checkbox, .td-checkbox {
  width: 40px;
  padding: 0 0 0 16px !important;
}

.th-actions, .td-actions {
  width: 60px;
  text-align: right;
  padding-right: 16px;
}

/* ─── Identity Cell (Rule 9 Avatar squircle) ─── */
.identity-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.avatar-squircle {
  width: 32px;
  height: 32px;
  border-radius: 10px;
  background-color: #e0f2fe;
  color: #0284c7;
  font-size: 11.5px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.identity-info {
  display: flex;
  flex-direction: column;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.table-code-subtext {
  font-size: 11px;
  color: #737373;
}

.td-tertiary {
  color: #737373;
  font-size: 13px;
}

.shift-desc-cell {
  display: flex;
  flex-direction: column;
}

.shift-title {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.shift-hours-sub {
  font-size: 11px;
  color: #737373;
}

.punch-time-cell {
  display: flex;
  flex-direction: column;
}

.punch-val-text {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
  font-variant-numeric: tabular-nums;
}

.device-tag-sub {
  font-size: 10.5px;
  color: #737373;
}

.on-duty-indicator {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: #059669;
  font-size: 12px;
  font-weight: 600;
}

.pulse-indicator {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background-color: #10b981;
  animation: pulse 1.8s infinite;
}

/* ─── Status Pills ─── */
.status-pill {
  display: inline-block;
  padding: 2px 10px;
  font-size: 11px;
  font-weight: 600;
  border-radius: 9999px;
  text-transform: capitalize;
  letter-spacing: 0.02em;
}

.status-present { background-color: #ecfdf5; color: #059669; }
.status-on_duty { background-color: #eff6ff; color: #0284c7; }
.status-late { background-color: #fef3c7; color: #b45309; }
.status-absent { background-color: #fef2f2; color: #dc2626; }
.status-on_leave { background-color: #f5f3ff; color: #7c3aed; }
.status-scheduled { background-color: #f1f5f9; color: #64748b; }

.state-open { background-color: #fef3c7; color: #b45309; }
.state-regularized { background-color: #ecfdf5; color: #059669; }
.state-justified { background-color: #eff6ff; color: #0284c7; }
.state-rejected { background-color: #fef2f2; color: #dc2626; }

.lock-indicator {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  border-radius: 9999px;
  font-size: 11px;
  font-weight: 500;
}

.lock-indicator.locked {
  background-color: #f1f5f9;
  color: #475569;
}

.lock-indicator.open {
  background-color: #ecfdf5;
  color: #059669;
}

.direction-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
}

.dir-in { background-color: #ecfdf5; color: #059669; }
.dir-out { background-color: #eff6ff; color: #0284c7; }

.exception-type-pill {
  display: inline-block;
  padding: 2px 8px;
  font-size: 11px;
  font-weight: 500;
  border-radius: 4px;
}

.type-late_arrival { background: #fef3c7; color: #b45309; }
.type-unscheduled_absence { background: #fef2f2; color: #dc2626; }
.type-missed_punch { background: #fee2e2; color: #991b1b; }
.type-early_departure { background: #f1f5f9; color: #475569; }

/* ─── Tab 2 & 3 Cards ─── */
.live-punches-card {
  background: #ffffff;
}

.live-punches-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.inner-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}

.inner-subtitle {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

.btn-refresh-stream {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 12px;
  border-radius: 6px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  color: #404040;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
}

.btn-refresh-stream:hover {
  background: #f8fafc;
}

.exception-actions-row {
  display: flex;
  align-items: center;
  gap: 6px;
  justify-content: flex-end;
}

.btn-regularize-approve {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 3px 8px;
  border-radius: 6px;
  background: #ecfdf5;
  border: 1px solid #a7f3d0;
  color: #065f46;
  font-size: 11.5px;
  font-weight: 500;
  cursor: pointer;
}

.btn-regularize-approve:hover {
  background: #d1fae5;
}

.btn-regularize-reject {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  border-radius: 6px;
  background: #fef2f2;
  border: 1px solid #fecaca;
  color: #dc2626;
  cursor: pointer;
}

/* ─── Devices Grid ─── */
.devices-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

@media (max-width: 768px) {
  .devices-grid {
    grid-template-columns: 1fr;
  }
}

.device-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 20px;
}

.device-card-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 14px;
}

.device-code {
  font-size: 11px;
  font-weight: 600;
  color: #0B529C;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.device-name {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 2px 0 0 0;
}

.device-online-badge {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  background: #ecfdf5;
  border: 1px solid #a7f3d0;
  color: #065f46;
  padding: 2px 8px;
  border-radius: 9999px;
  font-size: 10.5px;
  font-weight: 700;
}

.device-pulse-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #10b981;
}

.device-meta-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.device-meta-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 12.5px;
}

.meta-label {
  color: #737373;
}

.meta-val {
  font-weight: 500;
  color: #404040;
}

/* ─── Modals ─── */
.quick-form-body {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.form-2col-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  backdrop-filter: blur(2px);
}

.details-modal-box {
  background: #ffffff;
  border-radius: 12px;
  width: 90%;
  max-width: 580px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  overflow: hidden;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid #e2e8f0;
}

.modal-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.btn-close-modal {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  color: #94a3b8;
  border-radius: 6px;
  cursor: pointer;
}

.btn-close-modal:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.modal-content-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  padding: 20px;
}

.info-group {
  display: flex;
  flex-direction: column;
}

.info-group.full-width {
  grid-column: span 2;
}

.info-label {
  font-size: 11.5px;
  font-weight: 500;
  color: #737373;
  margin-bottom: 2px;
}

.info-val-bold {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.info-val {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
}

.info-sub {
  font-size: 11.5px;
  color: #737373;
}

.review-box {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 14px 16px;
  margin-top: 8px;
}

.review-box-title {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 12px 0;
}

.review-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.modal-input {
  width: 100%;
  height: 36px;
  padding: 0 10px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
  font-size: 13px;
  color: #404040;
  background-color: #ffffff;
}

.modal-input:focus {
  outline: none;
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.modal-textarea {
  width: 100%;
  resize: vertical;
  min-height: 56px;
  padding: 8px 10px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
  font-size: 13px;
  font-family: inherit;
  color: #404040;
  background-color: #ffffff;
}

.modal-textarea:focus {
  outline: none;
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.modal-footer-row {
  display: flex;
  justify-content: flex-end;
  padding: 12px 20px;
  border-top: 1px solid #f1f5f9;
  background-color: #fafafa;
}

.btn-modal-dismiss {
  height: 34px;
  padding: 0 16px;
  font-size: 12.5px;
  font-weight: 500;
  border-radius: 6px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  color: #404040;
  cursor: pointer;
}

.btn-modal-dismiss:hover {
  background-color: #f8fafc;
}

.btn-action-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  background: transparent;
  border: none;
  color: #737373;
  cursor: pointer;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #404040;
}

/* ─── Toast ─── */
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

@keyframes pulse {
  0% { transform: scale(0.95); opacity: 0.8; }
  50% { transform: scale(1.15); opacity: 1; }
  100% { transform: scale(0.95); opacity: 0.8; }
}

/* ─── Device Toolbar & Pill Switcher ─── */
.devices-toolbar-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 16px;
}

.device-pill-switcher {
  display: inline-flex;
  align-items: center;
  background-color: #f1f5f9;
  padding: 3px;
  border-radius: 8px;
  gap: 4px;
}

.device-pill-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  border-radius: 6px;
  font-size: 12.5px;
  font-weight: 500;
  color: #64748b;
  background: transparent;
  border: none;
  cursor: pointer;
  transition: all 0.15s ease;
}

.device-pill-btn.pill-active {
  background-color: #ffffff;
  color: #0B529C;
  font-weight: 600;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.enrollments-table-wrapper {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
}

.btn-revoke {
  padding: 3px 10px;
  font-size: 11px;
  font-weight: 500;
  border-radius: 6px;
  background-color: #fef2f2;
  border: 1px solid #fecaca;
  color: #dc2626;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-revoke:hover {
  background-color: #fee2e2;
}

.btn-approve {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 0 16px;
  height: 38px;
  border-radius: 8px;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 13px;
  font-weight: 500;
  border: none;
  cursor: pointer;
}

.btn-approve:hover {
  background-color: #09427d;
}

.btn-reject {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 0 14px;
  height: 38px;
  border-radius: 8px;
  background-color: #fef2f2;
  border: 1px solid #fecaca;
  color: #dc2626;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-reject:hover {
  background-color: #fee2e2;
}
</style>
