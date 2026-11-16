<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useRouter } from 'vue-router';
import {
  Clock, AlertTriangle, CheckCircle2, Plus,
  Search, Filter, MoreVertical, Calendar,
  X, ChevronLeft, ChevronRight, RotateCcw,
  Fingerprint, ArrowDownLeft, ArrowUpRight, Lock,
  Unlock, XCircle, Play
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseButton from '../../components/BaseButton.vue';
import BaseBadge, { type BadgeColor } from '../../components/BaseBadge.vue';
import BadgeGroup from '../../components/BadgeGroup.vue';
import MetricCard from '../../components/MetricCard.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormInput from '../../components/FormInput.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import { useToast } from '../../composables/useToast';

const router = useRouter();
const { toast } = useToast();

// ─── Breadcrumb ───
const breadcrumbItems = [
  { label: 'Daily Attendance' }
];

// ─── Active Tab State (Figma Node 7221:140238) ───
type TabKey = 'reconciliation' | 'punches' | 'exceptions';
const activeTab = ref<TabKey>('reconciliation');

// ─── Filter & Scope State ───
const selectedEntityFilter = ref('all');
const selectedShiftFilter = ref('all');
const selectedStatusFilter = ref('all');
const searchQuery = ref('');
const currentDateIso = ref('2026-07-27'); // Mon, Jul 27, 2026 (Matches Figma Node 7221:140229)
const showFiltersDropdown = ref(false);
const showColumnsModal = ref(false);
const isFullscreen = ref(false);
const sortAscending = ref(true);

// ─── Pagination State ───
const currentPage = ref(1);
const pageSize = ref(10);

// ─── Toast (Strict useToast Standard) ───
const showToast = (msg: string) => {
  toast.success('Attendance', msg);
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
  currentDateIso.value = '2026-07-27';
};

const handleFilterByStatus = (status: AttendanceDayStatus) => {
  activeTab.value = 'reconciliation';
  currentPage.value = 1;
  if (selectedStatusFilter.value === status) {
    selectedStatusFilter.value = 'all';
  } else {
    selectedStatusFilter.value = status;
  }
};

const handleSelectExceptionsTab = () => {
  activeTab.value = 'exceptions';
  selectedStatusFilter.value = 'all';
  currentPage.value = 1;
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
  { value: '4', label: 'Night Guard (22:00–06:00)' },
  { value: '5', label: 'Shop Split (09:00–20:00)' }
];

const statusFilterOptions = [
  { value: 'all', label: 'All Statuses' },
  { value: 'on_duty', label: 'On Duty' },
  { value: 'present', label: 'Present' },
  { value: 'late', label: 'Late Arrival' },
  { value: 'absent', label: 'Absent' },
  { value: 'on_leave', label: 'On Leave' },
  { value: 'scheduled', label: 'Scheduled' }
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
  avatar?: string;
}

export interface AttendanceLogRecord {
  id: number;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_role?: string;
  entity_id: number;
  entity_name: string;
  device_code: string;
  device_name: string;
  direction: 'in' | 'out';
  source: 'device' | 'mobile' | 'web' | 'manual';
  punched_at: string;
  time_display: string;
  verification_method: string;
  avatar?: string;
}

export interface AttendanceExceptionRecord {
  id: number;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_role?: string;
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
  avatar?: string;
}

// ─── Dataset: 12 AttendanceDay Records (Matches Figma Node 7221:140229) ───
const attendanceDays = ref<AttendanceDayRecord[]>([
  {
    id: 810221,
    employee_id: 12,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP 0012',
    employee_role: 'Head of Retail',
    org_unit_name: 'Retail Operations',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    date: '2026-07-27',
    shift_id: 3,
    shift_name: 'Retail Evening',
    scheduled_start: '14:30',
    scheduled_end: '22:30',
    day_status: 'on_duty',
    first_in_at: '14:26',
    first_in_device: 'DEV-BOLE-01',
    last_out_at: '22:30',
    last_out_device: null,
    scheduled_minutes: 480,
    worked_minutes: 270,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    variance_text: 'Punctual (-4m Early In)',
    is_locked: false,
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80'
  },
  {
    id: 810222,
    employee_id: 14,
    employee_name: 'Kidst Tesfaye',
    employee_code: 'EMP 0014',
    employee_role: 'Senior Cashier',
    org_unit_name: 'Customer Cashiers',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    date: '2026-07-27',
    shift_id: 2,
    shift_name: 'Retail Morning',
    scheduled_start: '07:00',
    scheduled_end: '15:00',
    day_status: 'present',
    first_in_at: '06:55',
    first_in_device: 'DEV-BOLE-01',
    last_out_at: '15:02',
    last_out_device: 'DEV-BOLE-01',
    scheduled_minutes: 480,
    worked_minutes: 487,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 60,
    variance_text: 'Completed (+60m OT approved)',
    is_locked: true,
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80'
  },
  {
    id: 810223,
    employee_id: 18,
    employee_name: 'Mihret Abera',
    employee_code: 'EMP 0018',
    employee_role: 'Cashier',
    org_unit_name: 'Customer Cashiers',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    date: '2026-07-27',
    shift_id: 2,
    shift_name: 'Retail Morning',
    scheduled_start: '07:00',
    scheduled_end: '15:00',
    day_status: 'late',
    first_in_at: '07:18',
    first_in_device: 'DEV-BOLE-01',
    last_out_at: '15:05',
    last_out_device: 'DEV-BOLE-01',
    scheduled_minutes: 480,
    worked_minutes: 467,
    late_minutes: 18,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    variance_text: '+18m Late Clock-In',
    is_locked: false,
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80'
  },
  {
    id: 810224,
    employee_id: 22,
    employee_name: 'Bethlehem Haile',
    employee_code: 'EMP 0022',
    employee_role: 'Inventory Controller',
    org_unit_name: 'Warehouse & Inventory',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    date: '2026-07-27',
    shift_id: 5,
    shift_name: 'Shop Split',
    scheduled_start: '09:00',
    scheduled_end: '20:00',
    day_status: 'on_duty',
    first_in_at: '08:58',
    first_in_device: 'DEV-BOLE-01',
    last_out_at: null,
    last_out_device: null,
    scheduled_minutes: 480,
    worked_minutes: 360,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    variance_text: 'On Duty (Mid-day break)',
    is_locked: false,
    avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80'
  },
  {
    id: 810225,
    employee_id: 9,
    employee_name: 'Almaz Mengistu',
    employee_code: 'EMP 0009',
    employee_role: 'HR Operations Lead',
    org_unit_name: 'Human Resources',
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    date: '2026-07-27',
    shift_id: 1,
    shift_name: 'Office Day',
    scheduled_start: '08:30',
    scheduled_end: '17:30',
    day_status: 'present',
    first_in_at: '08:28',
    first_in_device: 'DEV-HQ-01',
    last_out_at: '17:35',
    last_out_device: 'DEV-HQ-01',
    scheduled_minutes: 480,
    worked_minutes: 487,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 120,
    variance_text: 'Completed (+2.0h OT approved)',
    is_locked: true,
    avatar: 'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=150&auto=format&fit=crop&q=80'
  },
  {
    id: 810226,
    employee_id: 11,
    employee_name: 'Kassahun Bekele',
    employee_code: 'EMP 0011',
    employee_role: 'Facilities Officer',
    org_unit_name: 'Administration',
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    date: '2026-07-27',
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
    is_locked: true,
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80'
  },
  {
    id: 810227,
    employee_id: 7,
    employee_name: 'Tewodros Kassahun',
    employee_code: 'EMP 0007',
    employee_role: 'Security Guard',
    org_unit_name: 'Plant Security',
    entity_id: 9,
    entity_name: 'Hawassa Industrial Plant',
    date: '2026-07-27',
    shift_id: 4,
    shift_name: 'Night Guard',
    scheduled_start: '22:00',
    scheduled_end: '06:00',
    day_status: 'scheduled',
    first_in_at: null,
    first_in_device: null,
    last_out_at: null,
    last_out_device: null,
    scheduled_minutes: 480,
    worked_minutes: 0,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    variance_text: 'Starts tonight at 22:00',
    is_locked: false,
    avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80'
  },
  {
    id: 810228,
    employee_id: 8,
    employee_name: 'Mulugeta Belete',
    employee_code: 'EMP 0008',
    employee_role: 'Night Guard Lead',
    org_unit_name: 'Plant Security',
    entity_id: 9,
    entity_name: 'Hawassa Industrial Plant',
    date: '2026-07-27',
    shift_id: 4,
    shift_name: 'Night Guard',
    scheduled_start: '22:00',
    scheduled_end: '06:00',
    day_status: 'absent',
    first_in_at: null,
    first_in_device: null,
    last_out_at: null,
    last_out_device: null,
    scheduled_minutes: 480,
    worked_minutes: 0,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    variance_text: 'Unscheduled Absence',
    is_locked: false,
    avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80'
  },
  {
    id: 810229,
    employee_id: 25,
    employee_name: 'Selamawit Desta',
    employee_code: 'EMP 0025',
    employee_role: 'Quality Inspector',
    org_unit_name: 'Manufacturing Quality',
    entity_id: 9,
    entity_name: 'Hawassa Industrial Plant',
    date: '2026-07-27',
    shift_id: 1,
    shift_name: 'Office Day',
    scheduled_start: '08:30',
    scheduled_end: '17:30',
    day_status: 'scheduled',
    first_in_at: null,
    first_in_device: null,
    last_out_at: null,
    last_out_device: null,
    scheduled_minutes: 480,
    worked_minutes: 0,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    variance_text: 'Rostered shift scheduled',
    is_locked: false,
    avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80'
  },
  {
    id: 810230,
    employee_id: 31,
    employee_name: 'Henok Tadesse',
    employee_code: 'EMP 0031',
    employee_role: 'Maintenance Tech',
    org_unit_name: 'Plant Maintenance',
    entity_id: 9,
    entity_name: 'Hawassa Industrial Plant',
    date: '2026-07-27',
    shift_id: 1,
    shift_name: 'Office Day',
    scheduled_start: '08:30',
    scheduled_end: '17:30',
    day_status: 'scheduled',
    first_in_at: null,
    first_in_device: null,
    last_out_at: null,
    last_out_device: null,
    scheduled_minutes: 480,
    worked_minutes: 0,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    variance_text: 'Rostered shift scheduled',
    is_locked: false,
    avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80'
  },
  {
    id: 810231,
    employee_id: 42,
    employee_name: 'Bilen Assefa',
    employee_code: 'EMP 0042',
    employee_role: 'Customer Service Lead',
    org_unit_name: 'Customer Support',
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    date: '2026-07-27',
    shift_id: 1,
    shift_name: 'Office Day',
    scheduled_start: '08:30',
    scheduled_end: '17:30',
    day_status: 'scheduled',
    first_in_at: null,
    first_in_device: null,
    last_out_at: null,
    last_out_device: null,
    scheduled_minutes: 480,
    worked_minutes: 0,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    variance_text: 'Rostered shift scheduled',
    is_locked: false,
    avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80'
  },
  {
    id: 810232,
    employee_id: 55,
    employee_name: 'Yared Girma',
    employee_code: 'EMP 0055',
    employee_role: 'Dispatch Driver',
    org_unit_name: 'Logistics',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    date: '2026-07-27',
    shift_id: 3,
    shift_name: 'Retail Evening',
    scheduled_start: '14:30',
    scheduled_end: '22:30',
    day_status: 'scheduled',
    first_in_at: null,
    first_in_device: null,
    last_out_at: null,
    last_out_device: null,
    scheduled_minutes: 480,
    worked_minutes: 0,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    variance_text: 'Rostered shift scheduled',
    is_locked: false,
    avatar: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&auto=format&fit=crop&q=80'
  }
]);

// ─── Dataset: 12 AttendanceLog Records (Matches Figma Node 7221:140393) ───
const rawPunches = ref<AttendanceLogRecord[]>([
  { id: 700301, employee_id: 12, employee_name: 'Abebe Kebede', employee_code: 'EMP 0012', employee_role: 'Head of Retail', entity_id: 7, entity_name: 'Bole Commercial', device_code: 'DEV-BOLE-01', device_name: 'Bole Fingerprint', direction: 'out', source: 'device', punched_at: '2026-07-27T11:26:12Z', time_display: '14:26:12', verification_method: 'Biometric Fingerprint', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80' },
  { id: 700302, employee_id: 14, employee_name: 'Kidst Tesfaye', employee_code: 'EMP 0018', employee_role: 'Head of Retail', entity_id: 7, entity_name: 'Bole Commercial', device_code: 'DEV-HQ-01', device_name: 'HQ Fingerprint', direction: 'out', source: 'device', punched_at: '2026-07-27T11:26:12Z', time_display: '14:26:12', verification_method: 'Mobile GPS', avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80' },
  { id: 700303, employee_id: 18, employee_name: 'Mihret Abera', employee_code: 'EMP 0812', employee_role: 'Head of Retail', entity_id: 7, entity_name: 'Bole Commercial', device_code: 'DEV-LOBBY-01', device_name: 'Lobby Fingerprint', direction: 'in', source: 'device', punched_at: '2026-07-27T11:26:12Z', time_display: '14:26:12', verification_method: 'Mobile GPS', avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80' },
  { id: 700304, employee_id: 22, employee_name: 'Bethlehem Haile', employee_code: 'EMP 0022', employee_role: 'Inventory Controller', entity_id: 7, entity_name: 'Bole Commercial', device_code: 'DEV-BOLE-01', device_name: 'Bole Fingerprint', direction: 'in', source: 'device', punched_at: '2026-07-27T05:58:22Z', time_display: '08:58:22', verification_method: 'Biometric Fingerprint', avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80' },
  { id: 700305, employee_id: 9,  employee_name: 'Almaz Mengistu', employee_code: 'EMP 0009', employee_role: 'HR Operations Lead', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ', device_code: 'DEV-HQ-01', device_name: 'HQ Lobby Face Terminal', direction: 'out', source: 'device', punched_at: '2026-07-27T14:35:44Z', time_display: '17:35:44', verification_method: 'Facial Biometric Recognition', avatar: 'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=150&auto=format&fit=crop&q=80' },
  { id: 700306, employee_id: 9,  employee_name: 'Almaz Mengistu', employee_code: 'EMP 0009', employee_role: 'HR Operations Lead', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ', device_code: 'DEV-HQ-01', device_name: 'HQ Lobby Face Terminal', direction: 'in', source: 'device', punched_at: '2026-07-27T05:28:10Z', time_display: '08:28:10', verification_method: 'Facial Biometric Recognition', avatar: 'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=150&auto=format&fit=crop&q=80' },
  { id: 700307, employee_id: 18, employee_name: 'Mihret Abera', employee_code: 'EMP 0018', employee_role: 'Cashier', entity_id: 7, entity_name: 'Bole Commercial', device_code: 'DEV-BOLE-01', device_name: 'Bole Fingerprint', direction: 'in', source: 'device', punched_at: '2026-07-27T04:18:40Z', time_display: '07:18:40', verification_method: 'Biometric Fingerprint', avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80' },
  { id: 700308, employee_id: 14, employee_name: 'Kidst Tesfaye', employee_code: 'EMP 0014', employee_role: 'Senior Cashier', entity_id: 7, entity_name: 'Bole Commercial', device_code: 'DEV-BOLE-01', device_name: 'Bole Fingerprint', direction: 'in', source: 'device', punched_at: '2026-07-27T03:55:04Z', time_display: '06:55:04', verification_method: 'Biometric Fingerprint', avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80' },
  { id: 700309, employee_id: 25, employee_name: 'Selamawit Desta', employee_code: 'EMP 0025', employee_role: 'Quality Inspector', entity_id: 9, entity_name: 'Hawassa Industrial Plant', device_code: 'DEV-HW-02', device_name: 'Production Gate Scanner', direction: 'in', source: 'device', punched_at: '2026-07-27T05:31:00Z', time_display: '08:31:00', verification_method: 'Biometric Fingerprint', avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80' },
  { id: 700310, employee_id: 31, employee_name: 'Henok Tadesse', employee_code: 'EMP 0031', employee_role: 'Maintenance Tech', entity_id: 9, entity_name: 'Hawassa Industrial Plant', device_code: 'DEV-HW-02', device_name: 'Production Gate Scanner', direction: 'in', source: 'device', punched_at: '2026-07-27T05:45:00Z', time_display: '08:45:00', verification_method: 'Biometric Fingerprint', avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80' },
  { id: 700311, employee_id: 42, employee_name: 'Bilen Assefa', employee_code: 'EMP 0042', employee_role: 'Customer Service Lead', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ', device_code: 'DEV-HQ-01', device_name: 'HQ Lobby Face Terminal', direction: 'in', source: 'device', punched_at: '2026-07-27T05:25:00Z', time_display: '08:25:00', verification_method: 'Facial Biometric Recognition', avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80' },
  { id: 700312, employee_id: 55, employee_name: 'Yared Girma', employee_code: 'EMP 0055', employee_role: 'Dispatch Driver', entity_id: 7, entity_name: 'Bole Commercial', device_code: 'DEV-BOLE-01', device_name: 'Bole Fingerprint', direction: 'in', source: 'device', punched_at: '2026-07-27T11:20:00Z', time_display: '14:20:00', verification_method: 'Biometric Fingerprint', avatar: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&auto=format&fit=crop&q=80' }
]);

// ─── Dataset: 5 Open Exceptions (Matches Figma Node 7221:140547) ───
const exceptions = ref<AttendanceExceptionRecord[]>([
  { id: 5501, employee_id: 12, employee_name: 'Abebe Kebede', employee_code: 'EMP 0012', employee_role: 'Head of Retail', entity_name: 'Bole Commercial Branch', attendance_day_id: 810221, date: '2026-07-27', exception_type: 'late_arrival', exception_state: 'open', scheduled_time: '07:00', actual_time: '07:18 (+18m)', employee_note: 'Unexpected road traffic delay near Megenagna roundabout.', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80' },
  { id: 5502, employee_id: 14, employee_name: 'Kidst Tesfaye', employee_code: 'EMP 0018', employee_role: 'Head of Retail', entity_name: 'Hawassa Industrial Plant', attendance_day_id: 810222, date: '2026-07-27', exception_type: 'unscheduled_absence', exception_state: 'regularized', scheduled_time: '07:00', actual_time: 'No Punch', employee_note: 'Guard lead did not report for scheduled night roster.', avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80' },
  { id: 5503, employee_id: 18, employee_name: 'Mihret Abera', employee_code: 'EMP 0812', employee_role: 'Head of Retail', entity_name: 'Bole Commercial Branch', attendance_day_id: 810223, date: '2026-07-27', exception_type: 'early_departure', exception_state: 'justified', scheduled_time: '15:00', actual_time: '14:35 (-25m)', employee_note: 'Medical permission by shift supervisor.', avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80' },
  { id: 5504, employee_id: 22, employee_name: 'Bethlehem Haile', employee_code: 'EMP 0022', employee_role: 'Inventory Controller', entity_name: 'Bole Commercial Branch', attendance_day_id: 810224, date: '2026-07-27', exception_type: 'device_mismatch', exception_state: 'open', scheduled_time: '09:00', actual_time: 'Device Key Mismatch', employee_note: 'Manual key entry logged by shift manager.', avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80' },
  { id: 5505, employee_id: 31, employee_name: 'Henok Tadesse', employee_code: 'EMP 0031', employee_role: 'Maintenance Tech', entity_name: 'Hawassa Industrial Plant', attendance_day_id: 810230, date: '2026-07-27', exception_type: 'late_arrival', exception_state: 'open', scheduled_time: '08:30', actual_time: '08:45 (+15m)', employee_note: 'Heavy transport shuttle delay.', avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80' }
]);

// ─── Metric Cards Computed (Matches Figma Frame 7221:140238) ───
const metrics = computed(() => {
  const onDutyCount = attendanceDays.value.filter(d => d.day_status === 'on_duty').length;
  const presentCount = attendanceDays.value.filter(d => d.day_status === 'present').length;
  const lateCount = attendanceDays.value.filter(d => d.day_status === 'late').length;
  const openExceptions = exceptions.value.filter(e => e.exception_state === 'open').length;

  return {
    onDutyCount,
    presentCount,
    lateCount,
    openExceptions
  };
});

// ─── Dynamic Tab KPI Metrics (Matches Figma Nodes 7221:140229, 7221:140393, 7221:140547) ───
const tabMetrics = computed(() => {
  if (activeTab.value === 'exceptions') {
    return [
      {
        id: 'on_duty',
        label: 'ON DUTY RIGHT NOW',
        value: `${metrics.value.onDutyCount} Staff`,
        subtext: 'Live on working shifts',
        active: false,
        onClick: () => { activeTab.value = 'reconciliation'; handleFilterByStatus('on_duty'); }
      },
      {
        id: 'present',
        label: 'PRESENT & COMPLETED',
        value: `${metrics.value.presentCount}`,
        subtext: 'Successfully finished scheduled hours',
        active: false,
        onClick: () => { activeTab.value = 'reconciliation'; handleFilterByStatus('present'); }
      },
      {
        id: 'late',
        label: 'LATE CLOCK-INS',
        value: `${metrics.value.lateCount}`,
        subtext: 'Exceeded 10–15m grace window',
        active: false,
        onClick: () => { activeTab.value = 'reconciliation'; handleFilterByStatus('late'); }
      },
      {
        id: 'open_exceptions',
        label: 'OPEN EXCEPTIONS',
        value: `${metrics.value.openExceptions}`,
        subtext: 'Missed punches',
        active: true,
        onClick: () => {}
      }
    ];
  }

  // reconciliation & punches (Tabs 1 & 2 in Figma use identical metric cards)
  return [
    {
      id: 'on_duty',
      label: 'ON DUTY',
      value: `${metrics.value.onDutyCount} Staff`,
      subtext: 'Currently clocked in on shift',
      active: selectedStatusFilter.value === 'on_duty' && activeTab.value === 'reconciliation',
      onClick: () => handleFilterByStatus('on_duty')
    },
    {
      id: 'present',
      label: 'PRESENT',
      value: `${metrics.value.presentCount}`,
      subtext: 'Completed scheduled shift',
      active: selectedStatusFilter.value === 'present' && activeTab.value === 'reconciliation',
      onClick: () => handleFilterByStatus('present')
    },
    {
      id: 'late',
      label: 'LATE ARRIVALS',
      value: `${metrics.value.lateCount}`,
      subtext: 'Clocked in after shift grace period',
      active: selectedStatusFilter.value === 'late' && activeTab.value === 'reconciliation',
      onClick: () => handleFilterByStatus('late')
    },
    {
      id: 'open_exceptions',
      label: 'OPEN EXCEPTIONS',
      value: `${metrics.value.openExceptions}`,
      subtext: 'Pending supervisor review',
      active: false,
      onClick: handleSelectExceptionsTab
    }
  ];
});

// ─── Tabs Configuration (Primary BaseTabs Capsule Standard) ───
const attendanceTabs = computed<BaseTabItem<TabKey>[]>(() => [
  { id: 'reconciliation', label: 'Daily Attendance Records', icon: Calendar, count: 12 },
  { id: 'punches', label: 'Attendance Logs', icon: Fingerprint, count: 12 },
  { id: 'exceptions', label: 'Attendance Exceptions', icon: AlertTriangle, count: 5, badgeVariant: 'warning' }
]);

// ─── Table Columns Standards ───
const reconciliationColumns = ref<ColumnDef[]>([
  { key: 'employee', label: 'Name', visible: true },
  { key: 'shift', label: 'Rostered Shift', visible: true },
  { key: 'clock_in', label: 'Clock In', visible: true },
  { key: 'clock_out', label: 'Clock Out', visible: true },
  { key: 'variance', label: 'Shift Variance', visible: true },
  { key: 'status', label: 'Status', visible: true },
  { key: 'is_locked', label: 'Status', visible: true },
  { key: 'actions', label: 'Actions', visible: true }
]);

const logColumns = ref<ColumnDef[]>([
  { key: 'employee', label: 'Name', visible: true },
  { key: 'punched_at', label: 'Punched At', visible: true },
  { key: 'direction', label: 'Direction', visible: true },
  { key: 'device', label: 'Attendance Device (Device)', visible: true },
  { key: 'verification', label: 'Biometric Verification', visible: true },
  { key: 'location', label: 'Work Location', visible: true },
  { key: 'actions', label: 'Actions', visible: true }
]);

const exceptionColumns = ref<ColumnDef[]>([
  { key: 'employee', label: 'Employee', visible: true },
  { key: 'exception_type', label: 'Exception Type', visible: true },
  { key: 'scheduled_vs_actual', label: 'Scheduled vs Actual', visible: true },
  { key: 'employee_reason', label: 'Employee Reason', visible: true },
  { key: 'status', label: 'Status', visible: true },
  { key: 'actions', label: 'Actions', visible: true }
]);

const currentColumns = computed<ColumnDef[]>({
  get() {
    if (activeTab.value === 'reconciliation') return reconciliationColumns.value;
    if (activeTab.value === 'punches') return logColumns.value;
    return exceptionColumns.value;
  },
  set(val) {
    if (activeTab.value === 'reconciliation') reconciliationColumns.value = val;
    else if (activeTab.value === 'punches') logColumns.value = val;
    else exceptionColumns.value = val;
  }
});

const handleToggleColumn = (colKey: string) => {
  const col = currentColumns.value.find(c => c.key === colKey);
  if (col) col.visible = !col.visible;
};

const isColVisible = (key: string) => {
  const col = currentColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

// ─── Filtered Data ───
const filteredAttendanceDays = computed(() => {
  return attendanceDays.value.filter(row => {
    const matchesSearch = !searchQuery.value ||
      row.employee_name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      row.employee_code.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      row.employee_role.toLowerCase().includes(searchQuery.value.toLowerCase());

    const matchesEntity = selectedEntityFilter.value === 'all' || String(row.entity_id) === selectedEntityFilter.value;
    const matchesShift = selectedShiftFilter.value === 'all' || String(row.shift_id) === selectedShiftFilter.value;
    const matchesStatus = selectedStatusFilter.value === 'all' || row.day_status === selectedStatusFilter.value;

    return matchesSearch && matchesEntity && matchesShift && matchesStatus;
  });
});

const filteredPunches = computed(() => {
  return rawPunches.value.filter(row => {
    return !searchQuery.value ||
      row.employee_name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      row.employee_code.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      row.device_code.toLowerCase().includes(searchQuery.value.toLowerCase());
  });
});

const filteredExceptions = computed(() => {
  return exceptions.value.filter(row => {
    return !searchQuery.value ||
      row.employee_name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      row.employee_code.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      row.exception_type.toLowerCase().includes(searchQuery.value.toLowerCase());
  });
});

// ─── Paginated Records ───
const paginatedAttendanceDays = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value;
  return filteredAttendanceDays.value.slice(start, start + pageSize.value);
});

const paginatedPunches = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value;
  return filteredPunches.value.slice(start, start + pageSize.value);
});

const paginatedExceptions = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value;
  return filteredExceptions.value.slice(start, start + pageSize.value);
});

const totalRecordsCount = computed(() => {
  if (activeTab.value === 'reconciliation') {
    return filteredAttendanceDays.value.length;
  }
  if (activeTab.value === 'punches') {
    return filteredPunches.value.length;
  }
  return filteredExceptions.value.length;
});

const totalPages = computed(() => {
  return Math.max(1, Math.ceil(totalRecordsCount.value / pageSize.value));
});

const paginationStart = computed(() => {
  if (totalRecordsCount.value === 0) return 0;
  return (currentPage.value - 1) * pageSize.value + 1;
});

const paginationEnd = computed(() => {
  return Math.min(currentPage.value * pageSize.value, totalRecordsCount.value);
});

// ─── Row Selection & Active Tab Slice ───
const selectedRowIds = ref<number[]>([]);

const currentTabItems = computed(() => {
  if (activeTab.value === 'reconciliation') {
    return paginatedAttendanceDays.value;
  }
  if (activeTab.value === 'punches') {
    return paginatedPunches.value;
  }
  return paginatedExceptions.value;
});

const isCurrentTabAllSelected = computed(() => {
  return currentTabItems.value.length > 0 && selectedRowIds.value.length === currentTabItems.value.length;
});

const isCurrentTabIndeterminate = computed(() => {
  return selectedRowIds.value.length > 0 && selectedRowIds.value.length < currentTabItems.value.length;
});

const handleToggleSelectAll = (checked: boolean) => {
  selectedRowIds.value = checked ? currentTabItems.value.map(r => r.id) : [];
};

const handleToggleRow = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx > -1) selectedRowIds.value.splice(idx, 1);
  else selectedRowIds.value.push(id);
};

watch(activeTab, () => {
  selectedRowIds.value = [];
  currentPage.value = 1;
});

// ─── Sorting ───
const handleToggleSort = () => {
  sortAscending.value = !sortAscending.value;
  if (activeTab.value === 'reconciliation') {
    attendanceDays.value.sort((a, b) => {
      return sortAscending.value 
        ? a.employee_name.localeCompare(b.employee_name)
        : b.employee_name.localeCompare(a.employee_name);
    });
  } else if (activeTab.value === 'punches') {
    rawPunches.value.sort((a, b) => {
      return sortAscending.value
        ? a.employee_name.localeCompare(b.employee_name)
        : b.employee_name.localeCompare(a.employee_name);
    });
  } else if (activeTab.value === 'exceptions') {
    exceptions.value.sort((a, b) => {
      return sortAscending.value
        ? a.employee_name.localeCompare(b.employee_name)
        : b.employee_name.localeCompare(a.employee_name);
    });
  }
  showToast(`Sorted records ${sortAscending.value ? 'A-Z' : 'Z-A'}.`);
};

// ─── Top Level Action Handlers ───
const handleRunAttendance = () => {
  showToast('Running daily attendance synthesis pipeline...');
};

const handleRefreshFeed = () => {
  showToast('Refreshed biometric punch stream from connected devices.');
};

const handleInspectPunch = (punch: AttendanceLogRecord) => {
  showToast(`Inspecting punch record for ${punch.employee_name} (${punch.time_display}).`);
};

// ─── Status Formatter ───
const formatStatusLabel = (status: AttendanceDayStatus) => {
  switch (status) {
    case 'on_duty': return 'On Duty';
    case 'present': return 'Present';
    case 'late': return 'Late';
    case 'absent': return 'Absent';
    case 'on_leave': return 'On Leave';
    case 'scheduled': return 'Scheduled';
    default: return status.replace('_', ' ');
  }
};

const getDayStatusBadgeColor = (status: string): BadgeColor => {
  switch (status) {
    case 'present': return 'success';
    case 'on_duty': return 'primary';
    case 'late': return 'warning';
    case 'absent': return 'error';
    case 'on_leave':
    case 'scheduled':
    default: return 'gray';
  }
};

const getExceptionTypeColor = (type: string): BadgeColor => {
  switch (type) {
    case 'missed_punch': return 'warning';
    case 'late_arrival': return 'warning';
    case 'early_departure': return 'primary';
    case 'unscheduled_absence': return 'error';
    case 'device_mismatch': return 'gray';
    default: return 'gray';
  }
};

const formatExceptionType = (type: string) => {
  if (type === 'unscheduled_absence') return 'Absence';
  if (type === 'late_arrival') return 'Late Arrival';
  if (type === 'early_departure') return 'Early Departure';
  if (type === 'missed_punch') return 'Missed Punch';
  if (type === 'device_mismatch') return 'Device Mismatch';
  return type.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
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
  employee_id: '12',
  entity_id: '7',
  date: currentDateIso.value,
  time: '08:30',
  direction: 'in' as 'in' | 'out',
  source: 'manual',
  reason: ''
});

const employeeSelectOptions = [
  { value: '12', label: 'Abebe Kebede (EMP 0012 • Head of Retail)' },
  { value: '14', label: 'Kidst Tesfaye (EMP 0014 • Senior Cashier)' },
  { value: '18', label: 'Mihret Abera (EMP 0018 • Cashier)' },
  { value: '22', label: 'Bethlehem Haile (EMP 0022 • Inventory Controller)' }
];

const handleOpenManualPunch = () => {
  manualPunchForm.value = {
    employee_id: '12',
    entity_id: '7',
    date: currentDateIso.value,
    time: '08:30',
    direction: 'in',
    source: 'manual',
    reason: ''
  };
  showManualPunchModal.value = true;
};

const handleSaveManualPunch = () => {
  const empOption = employeeSelectOptions.find(e => e.value === manualPunchForm.value.employee_id);
  const empName = empOption ? empOption.label.split(' (')[0] : 'Manual Employee';

  const newLog: AttendanceLogRecord = {
    id: Date.now(),
    employee_id: Number(manualPunchForm.value.employee_id),
    employee_name: empName,
    employee_code: `EMP-0${manualPunchForm.value.employee_id}`,
    entity_id: Number(manualPunchForm.value.entity_id),
    entity_name: 'Bole Commercial Branch',
    device_code: 'DEV-MANUAL',
    device_name: 'Manual HR Override Entry',
    direction: manualPunchForm.value.direction,
    source: 'manual',
    punched_at: `${manualPunchForm.value.date}T${manualPunchForm.value.time}:00Z`,
    time_display: `${manualPunchForm.value.time}:00`,
    verification_method: 'Manual Supervisor Keying',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80'
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
  if (state === 'regularized') {
    const day = attendanceDays.value.find(d => d.id === ex.attendance_day_id);
    if (day) {
      day.day_status = 'present';
      day.variance_text = 'Regularized by Supervisor';
      if (exceptionResolutionForm.value.requested_in) {
        day.first_in_at = exceptionResolutionForm.value.requested_in;
      }
      if (exceptionResolutionForm.value.requested_out) {
        day.last_out_at = exceptionResolutionForm.value.requested_out;
      }
    }
  }
  showToast(`Exception for ${ex.employee_name} marked as ${state}.`);
  inspectingException.value = null;
};
</script>

<template>
  <div class="daily-attendance-page" :class="{ 'is-fullscreen': isFullscreen }">
    <!-- Breadcrumb Standard -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ════════════════════════════════════════════════════════════════════════ -->
    <!-- CARD 1: TOP SUMMARY CARD (Figma Node 7221:140238)                        -->
    <!-- ════════════════════════════════════════════════════════════════════════ -->
    <div class="attendance-top-card">
      <!-- Row 1: Date Navigator & Biometric Status (Calendar Navigation Standard + QMT BadgeGroup Figma 5221:28673) -->
      <div class="date-scope-bar">
        <!-- Today Button (Figma 6328:119469: 102x40) -->
        <button type="button" class="btn-today-pill" @click="handleToday">
          <Calendar :size="18" class="icon-calendar" />
          <span>Today</span>
        </button>

        <!-- Circular Date Navigators & Title (Figma 6328:119471) -->
        <div class="month-nav-group">
          <button type="button" class="btn-circle-nav" @click="handlePrevDay" title="Previous Day">
            <ChevronLeft :size="18" />
          </button>
          <span class="nav-date-title">{{ formattedCurrentDate }}</span>
          <button type="button" class="btn-circle-nav" @click="handleNextDay" title="Next Day">
            <ChevronRight :size="18" />
          </button>
        </div>

        <!-- Biometric Sync Badge Group (QMT Team Library Figma Node 5221:28673 / Symbol 5221:3640) -->
        <BadgeGroup
          badgePosition="trailing"
          badgeLabel="Biometric Sync"
          message="3 Devices Online"
          color="success"
          type="modern"
          size="md"
          :dot="true"
          :arrow="false"
          to="/hr/biometric-devices"
          title="View Biometric Devices"
        />
      </div>

      <!-- Row 2: 4 Metric Cards Grid (Dynamic across tabs per Figma 7221:140229, 7221:140393, 7221:140547) -->
      <div class="metrics-grid">
        <div
          v-for="card in tabMetrics"
          :key="card.id"
          class="metric-interactive"
          :class="{ 'metric-active': card.active }"
          @click="card.onClick"
        >
          <MetricCard
            :label="card.label"
            :value="card.value"
            :subtext="card.subtext"
            size="md"
            :show-menu="false"
          />
        </div>
      </div>

      <!-- Row 3: Primary BaseTabs Capsule -->
      <div class="top-card-tabs-wrapper">
        <BaseTabs
          v-model="activeTab"
          :tabs="attendanceTabs"
          type="rounded"
          size="sm"
          class="attendance-primary-tabs"
        />
      </div>
    </div>

    <!-- ════════════════════════════════════════════════════════════════════════ -->
    <!-- CARD 2: BOTTOM TABLE CARD (AppDataTable Standard with BasePagination)   -->
    <!-- ════════════════════════════════════════════════════════════════════════ -->
    <div class="attendance-table-section">
      <AppDataTable
        :title="activeTab === 'reconciliation' ? 'Daily Attendance Records' : activeTab === 'punches' ? 'Attendance Logs' : 'Attendance Exceptions'"
        :subtitle="activeTab === 'reconciliation' 
            ? 'Daily attendance ledger synthesized from shift rosters, punch logs, and approved leave.' 
            : activeTab === 'punches' 
              ? 'Raw punch stream capturing device scans, mobile GPS check-ins, and manual entries.' 
              : 'Attendance anomalies including missed punches, late arrivals, and early departures requiring review.'"
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search category or code..."
        :columns="currentColumns"
        :totalEntries="totalRecordsCount"
        v-model:currentPage="currentPage"
        v-model:perPage="pageSize"
        :perPageOptions="[5, 10, 20, 50]"
        :showPagination="true"
        :showFilter="true"
        :filterCount="selectedEntityFilter !== 'all' || selectedShiftFilter !== 'all' || selectedStatusFilter !== 'all' ? 1 : 0"
        :showSort="true"
        :showColumns="true"
        :showFullscreen="true"
        @toggleColumn="handleToggleColumn"
        @resetFilter="selectedEntityFilter = 'all'; selectedShiftFilter = 'all'; selectedStatusFilter = 'all'; searchQuery = ''"
      >
        <template #header-extra>
          <AppButton 
            v-if="activeTab === 'reconciliation'"
            variant="primary" 
            size="md" 
            @click="handleRunAttendance"
          >
            <template #icon-left><Play :size="16" fill="currentColor" /></template>
            Run Attendance
          </AppButton>
        </template>

        <template #actions>
          <AppButton 
            v-if="activeTab === 'reconciliation'" 
            variant="outline" 
            size="sm" 
            @click="handleOpenManualPunch"
          >
            <template #icon-left><Plus :size="15" /></template>
            Log Manual Punch
          </AppButton>
          <AppButton 
            v-else-if="activeTab === 'punches'" 
            variant="outline" 
            size="sm" 
            @click="handleRefreshFeed"
          >
            <template #icon-left><RotateCcw :size="14" /></template>
            Refresh Feed
          </AppButton>
        </template>

        <template #filter-panel>
          <div class="attendance-filter-panel-row flex items-end gap-3 flex-wrap">
            <div class="w-52">
              <FormSelect
                v-model="selectedEntityFilter"
                label="Facility / Branch"
                :options="entityOptions"
              />
            </div>

            <div class="w-52">
              <FormSelect
                v-model="selectedShiftFilter"
                label="Rostered Shift"
                :options="shiftFilterOptions"
              />
            </div>

            <div class="w-48">
              <FormSelect
                v-model="selectedStatusFilter"
                label="Status"
                :options="statusFilterOptions"
              />
            </div>

            <BaseButton 
              type="button" 
              variant="tertiary-gray"
              size="sm"
              class="mb-0.5"
              @click="selectedEntityFilter = 'all'; selectedShiftFilter = 'all'; selectedStatusFilter = 'all'; searchQuery = ''"
            >
              Reset Filters
            </BaseButton>
          </div>
        </template>

        <template #default>
          <!-- ─── Tab 1: Daily Attendance Records Table (Figma Node 7221:140229) ─── -->
          <div v-if="activeTab === 'reconciliation'" class="table-scroll-wrapper">
            <table class="erp-table">
              <thead>
                <tr>
                  <th v-if="isColVisible('employee')" class="th-name">
                    <div class="name-header-content">
                      <FormCheckbox
                        :model-value="isCurrentTabAllSelected"
                        :indeterminate="isCurrentTabIndeterminate"
                        size="sm"
                        @change="(val) => handleToggleSelectAll(Boolean(val))"
                        aria-label="Select all rows"
                      />
                      <span>Name</span>
                    </div>
                  </th>
                  <th v-if="isColVisible('shift')">Rostered Shift</th>
                  <th v-if="isColVisible('clock_in')">Clock In</th>
                  <th v-if="isColVisible('clock_out')">Clock Out</th>
                  <th v-if="isColVisible('variance')">Shift Variance</th>
                  <th v-if="isColVisible('status')">Status</th>
                  <th v-if="isColVisible('is_locked')">Status</th>
                  <th v-if="isColVisible('actions')" class="th-actions">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="item in paginatedAttendanceDays"
                  :key="item.id"
                  :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
                  @click="handleInspectDay(item)"
                >
                  <!-- Name (Lead Checkbox + 40px Circular Avatar + Name Stack) -->
                  <td v-if="isColVisible('employee')" class="td-name">
                    <div class="name-cell-content">
                      <FormCheckbox
                        :model-value="selectedRowIds.includes(item.id)"
                        size="sm"
                        @click.stop
                        @change="() => handleToggleRow(item.id)"
                        :aria-label="`Select ${item.employee_name}`"
                      />
                      <div class="avatar-circular">
                        <img v-if="item.avatar" :src="item.avatar" :alt="item.employee_name" class="avatar-img" />
                        <span v-else class="avatar-initials">{{ item.employee_name.split(' ').map(n => n[0]).join('') }}</span>
                      </div>
                      <div class="name-cell-stack">
                        <span class="table-name-primary">{{ item.employee_name }}</span>
                        <span class="table-code-subtext">{{ item.employee_code }} • {{ item.employee_role }}</span>
                      </div>
                    </div>
                  </td>

                  <!-- Rostered Shift -->
                  <td v-if="isColVisible('shift')">
                    <span class="table-name-primary">{{ item.shift_name }}</span>
                  </td>

                  <!-- Clock In -->
                  <td v-if="isColVisible('clock_in')">
                    <span class="variance-text">{{ item.first_in_at || '—' }}</span>
                  </td>

                  <!-- Clock Out -->
                  <td v-if="isColVisible('clock_out')">
                    <span class="variance-text">{{ item.last_out_at || (item.day_status === 'on_duty' ? 'On Duty' : '—') }}</span>
                  </td>

                  <!-- Shift Variance -->
                  <td v-if="isColVisible('variance')">
                    <span class="variance-text">{{ item.variance_text }}</span>
                  </td>

                  <!-- Status: BaseBadge pill-color with dot -->
                  <td v-if="isColVisible('status')">
                    <BaseBadge
                      type="pill-color"
                      :color="getDayStatusBadgeColor(item.day_status)"
                      :dot="item.day_status === 'on_duty'"
                      size="sm"
                    >
                      {{ formatStatusLabel(item.day_status) }}
                    </BaseBadge>
                  </td>

                  <!-- Lock Status: BaseBadge pill-color with Lock/Unlock Icon (Figma 7221:140229) -->
                  <td v-if="isColVisible('is_locked')">
                    <BaseBadge
                      v-if="item.is_locked"
                      type="pill-color"
                      color="gray"
                      size="sm"
                    >
                      <template #icon-left><Lock :size="12" /></template>
                      Locked
                    </BaseBadge>
                    <BaseBadge
                      v-else
                      type="pill-color"
                      color="success"
                      size="sm"
                    >
                      <template #icon-left><Unlock :size="12" /></template>
                      Open
                    </BaseBadge>
                  </td>

                  <!-- Actions -->
                  <td v-if="isColVisible('actions')" class="td-actions" @click.stop>
                    <button
                      type="button"
                      class="btn-row-action"
                      @click="handleInspectDay(item)"
                      title="Inspect Day"
                    >
                      <MoreVertical :size="16" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- ─── Tab 2: Attendance Logs (Figma Node 7221:140393) ─── -->
          <div v-else-if="activeTab === 'punches'" class="table-scroll-wrapper">
            <table class="erp-table">
              <thead>
                <tr>
                  <th v-if="isColVisible('employee')" class="th-name">
                    <div class="name-header-content">
                      <FormCheckbox
                        :model-value="isCurrentTabAllSelected"
                        :indeterminate="isCurrentTabIndeterminate"
                        size="sm"
                        @change="(val) => handleToggleSelectAll(Boolean(val))"
                        aria-label="Select all rows"
                      />
                      <span>Name</span>
                    </div>
                  </th>
                  <th v-if="isColVisible('punched_at')">Punched At</th>
                  <th v-if="isColVisible('direction')">Direction</th>
                  <th v-if="isColVisible('device')">Attendance Device (Device)</th>
                  <th v-if="isColVisible('verification')">Biometric Verification</th>
                  <th v-if="isColVisible('location')">Work Location</th>
                  <th v-if="isColVisible('actions')" class="th-actions">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="item in paginatedPunches"
                  :key="item.id"
                  :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
                  @click="handleInspectPunch(item)"
                >
                  <!-- Name (Lead Checkbox + Avatar + Name Stack) -->
                  <td v-if="isColVisible('employee')" class="td-name">
                    <div class="name-cell-content">
                      <FormCheckbox
                        :model-value="selectedRowIds.includes(item.id)"
                        size="sm"
                        @click.stop
                        @change="() => handleToggleRow(item.id)"
                        :aria-label="`Select ${item.employee_name}`"
                      />
                      <div class="avatar-circular">
                        <img v-if="item.avatar" :src="item.avatar" :alt="item.employee_name" class="avatar-img" />
                        <span v-else class="avatar-initials">{{ item.employee_name.split(' ').map(n => n[0]).join('') }}</span>
                      </div>
                      <div class="name-cell-stack">
                        <span class="table-name-primary">{{ item.employee_name }}</span>
                        <span class="table-code-subtext">{{ item.employee_code }} • {{ item.employee_role }}</span>
                      </div>
                    </div>
                  </td>

                  <!-- Punched At -->
                  <td v-if="isColVisible('punched_at')">
                    <span class="variance-text">{{ item.time_display }}</span>
                  </td>

                  <!-- Direction -->
                  <td v-if="isColVisible('direction')">
                    <BaseBadge
                      v-if="item.direction === 'out'"
                      type="pill-color"
                      color="primary"
                      size="sm"
                    >
                      <template #icon-left><ArrowUpRight :size="12" /></template>
                      Out
                    </BaseBadge>
                    <BaseBadge
                      v-else
                      type="pill-color"
                      color="success"
                      size="sm"
                    >
                      <template #icon-left><ArrowDownLeft :size="12" /></template>
                      In
                    </BaseBadge>
                  </td>

                  <!-- Attendance Device (Device) -->
                  <td v-if="isColVisible('device')">
                    <span class="table-name-primary">{{ item.device_name }}</span>
                  </td>

                  <!-- Biometric Verification -->
                  <td v-if="isColVisible('verification')">
                    <span class="variance-text">{{ item.verification_method }}</span>
                  </td>

                  <!-- Work Location -->
                  <td v-if="isColVisible('location')">
                    <span class="variance-text">{{ item.entity_name }}</span>
                  </td>

                  <!-- Actions -->
                  <td v-if="isColVisible('actions')" class="td-actions" @click.stop>
                    <button
                      type="button"
                      class="btn-row-action"
                      @click="handleInspectPunch(item)"
                      title="Inspect Punch Record"
                    >
                      <MoreVertical :size="16" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- ─── Tab 3: Attendance Exceptions (Figma Node 7221:140547) ─── -->
          <div v-else-if="activeTab === 'exceptions'" class="table-scroll-wrapper">
            <table class="erp-table">
              <thead>
                <tr>
                  <th v-if="isColVisible('employee')" class="th-name">
                    <div class="name-header-content">
                      <FormCheckbox
                        :model-value="isCurrentTabAllSelected"
                        :indeterminate="isCurrentTabIndeterminate"
                        size="sm"
                        @change="(val) => handleToggleSelectAll(Boolean(val))"
                        aria-label="Select all rows"
                      />
                      <span>Employee</span>
                    </div>
                  </th>
                  <th v-if="isColVisible('exception_type')">Exception Type</th>
                  <th v-if="isColVisible('scheduled_vs_actual')">Scheduled vs Actual</th>
                  <th v-if="isColVisible('employee_reason')">Employee Reason</th>
                  <th v-if="isColVisible('status')">Status</th>
                  <th v-if="isColVisible('actions')" class="th-actions">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="ex in paginatedExceptions"
                  :key="ex.id"
                  :class="{ 'row-selected': selectedRowIds.includes(ex.id) }"
                  @click="openRegularizeModal(ex)"
                >
                  <!-- Employee (Lead Checkbox + Avatar + Name Stack) -->
                  <td v-if="isColVisible('employee')" class="td-name">
                    <div class="name-cell-content">
                      <FormCheckbox
                        :model-value="selectedRowIds.includes(ex.id)"
                        size="sm"
                        @click.stop
                        @change="() => handleToggleRow(ex.id)"
                        :aria-label="`Select ${ex.employee_name}`"
                      />
                      <div class="avatar-circular">
                        <img v-if="ex.avatar" :src="ex.avatar" :alt="ex.employee_name" class="avatar-img" />
                        <span v-else class="avatar-initials">{{ ex.employee_name.split(' ').map(n => n[0]).join('') }}</span>
                      </div>
                      <div class="name-cell-stack">
                        <span class="table-name-primary">{{ ex.employee_name }}</span>
                        <span class="table-code-subtext">{{ ex.employee_code }} • {{ ex.employee_role }}</span>
                      </div>
                    </div>
                  </td>

                  <!-- Exception Type: BaseBadge pill-color standard -->
                  <td v-if="isColVisible('exception_type')">
                    <BaseBadge
                      type="pill-color"
                      :color="getExceptionTypeColor(ex.exception_type)"
                      size="sm"
                    >
                      {{ formatExceptionType(ex.exception_type) }}
                    </BaseBadge>
                  </td>

                  <!-- Scheduled vs Actual -->
                  <td v-if="isColVisible('scheduled_vs_actual')">
                    <span class="variance-text">{{ ex.scheduled_time }} - {{ ex.actual_time }}</span>
                  </td>

                  <!-- Employee Reason -->
                  <td v-if="isColVisible('employee_reason')">
                    <span class="variance-text">{{ ex.employee_note || 'No note provided' }}</span>
                  </td>

                  <!-- Status -->
                  <td v-if="isColVisible('status')">
                    <BaseBadge
                      type="pill-color"
                      :color="ex.exception_state === 'open' ? 'warning' : ex.exception_state === 'regularized' ? 'success' : 'primary'"
                      size="sm"
                    >
                      {{ ex.exception_state === 'open' ? 'Open' : ex.exception_state === 'regularized' ? 'Regularized' : 'Justified' }}
                    </BaseBadge>
                  </td>

                  <!-- Actions -->
                  <td v-if="isColVisible('actions')" class="td-actions" @click.stop>
                    <button
                      type="button"
                      class="btn-row-action"
                      @click="openRegularizeModal(ex)"
                      title="Inspect / Regularize Exception"
                    >
                      <MoreVertical :size="16" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

        </template>
      </AppDataTable>
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

    <!-- Column Visibility Modal -->
    <div v-if="showColumnsModal" class="modal-backdrop" @click="showColumnsModal = false">
      <div class="columns-modal-box" @click.stop>
        <div class="modal-header">
          <span class="modal-title">Customize Table Columns</span>
          <button type="button" class="btn-close-modal" @click="showColumnsModal = false">
            <X :size="16" />
          </button>
        </div>
        <div class="columns-checklist">
          <div 
            v-for="col in currentColumns" 
            :key="col.key"
            class="column-check-item"
          >
            <FormCheckbox 
              :model-value="col.visible" 
              :label="col.label"
              size="sm"
              @change="() => handleToggleColumn(col.key)" 
            />
          </div>
        </div>
        <div class="modal-footer-row">
          <AppButton variant="primary" size="sm" @click="showColumnsModal = false">
            Done
          </AppButton>
        </div>
      </div>
    </div>

    <!-- Exception Regularization Modal -->
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
            <span class="info-sub">{{ inspectingException.employee_code }} • {{ inspectingException.entity_name }}</span>
          </div>

          <div class="info-group">
            <span class="info-label">Exception Anomaly</span>
            <div class="mt-1">
              <BaseBadge type="pill-color" :color="getExceptionTypeColor(inspectingException.exception_type)" :dot="true" size="sm">
                {{ formatExceptionType(inspectingException.exception_type) }}
              </BaseBadge>
            </div>
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
          <AppButton variant="outline" size="sm" @click="inspectingException = null">
            Cancel
          </AppButton>
          <AppButton
            variant="destructive"
            size="sm"
            @click="handleResolveException(inspectingException, 'rejected')"
          >
            <template #icon-left><XCircle :size="14" /></template>
            <span>Reject Justification</span>
          </AppButton>
          <AppButton
            variant="outline"
            size="sm"
            @click="handleResolveException(inspectingException, 'justified')"
          >
            Mark Justified
          </AppButton>
          <AppButton
            variant="primary"
            size="sm"
            @click="handleResolveException(inspectingException, 'regularized')"
          >
            <template #icon-left><CheckCircle2 :size="14" /></template>
            <span>Regularize &amp; Apply</span>
          </AppButton>
        </div>
      </div>
    </div>

    <!-- Day Breakdown Inspection Modal -->
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
            <span class="info-sub">{{ inspectingDay.employee_code }} • {{ inspectingDay.employee_role }}</span>
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
            <div class="mt-1">
              <BaseBadge
                type="pill-color"
                :color="getDayStatusBadgeColor(inspectingDay.day_status)"
                :dot="true"
                size="sm"
              >
                {{ formatStatusLabel(inspectingDay.day_status) }}
              </BaseBadge>
            </div>
          </div>

          <div class="info-group">
            <span class="info-label">Payroll Lock</span>
            <div class="mt-1">
              <span v-if="inspectingDay.is_locked" class="lock-pill locked">
                <Lock :size="12" />
                <span>Locked for Payroll</span>
              </span>
              <span v-else class="lock-pill open">
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
          <AppButton variant="outline" size="sm" @click="inspectingDay = null">
            Close Breakdown
          </AppButton>
        </div>
      </div>
    </div>

    <!-- Floating Batch Action Bar -->
    <TableFloatingBar
      v-if="activeTab === 'reconciliation' || activeTab === 'punches'"
      :show="selectedRowIds.length > 0"
      :selected-count="selectedRowIds.length"
      :total-count="currentTabItems.length"
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
  gap: 24px;
  padding: 0;
  background-color: #FAFAFA;
  min-height: 100vh;
}

.daily-attendance-page.is-fullscreen {
  position: fixed;
  inset: 0;
  z-index: 1000;
  background-color: #FAFAFA;
  padding: 24px;
  overflow-y: auto;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
}

/* ════════════════════════════════════════════════════════════════════════════ */
/* CARD 1: TOP SUMMARY CARD (Figma Node 7221:140238)                           */
/* ════════════════════════════════════════════════════════════════════════════ */
.attendance-top-card {
  background: #ffffff;
  border: 1px solid #E5E5E5;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
}

.date-scope-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 12px 16px;
  background: #ffffff;
  border: 1px solid #E5E5E5;
  border-radius: 12px;
}

.btn-today-pill {
  height: 40px;
  padding: 0 16px;
  background: #ffffff;
  border: 1px solid #d9d9d9;
  border-radius: 8px;
  color: #404040;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  box-shadow: 0px 1px 2px 0px rgba(10, 13, 18, 0.05);
  transition: all 0.15s ease;
}

.btn-today-pill:hover {
  background: #fafafa;
  border-color: #bfbfbf;
}

.icon-calendar {
  color: #404040;
}

.month-nav-group {
  display: flex;
  align-items: center;
  gap: 16px;
}

.btn-circle-nav {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 1px solid #d9d9d9;
  background: #ffffff;
  color: #404040;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0px 1px 2px 0px rgba(10, 13, 18, 0.05);
  transition: all 0.15s ease;
}

.btn-circle-nav:hover {
  background: #fafafa;
  border-color: #bfbfbf;
}

.nav-date-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  min-width: 180px;
  text-align: center;
}


/* Metrics Grid */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

.metric-interactive {
  cursor: pointer;
  border-radius: 16px;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}

.metric-interactive:hover {
  transform: translateY(-2px);
}

.metric-interactive.metric-active {
  box-shadow: 0 0 0 2px #0B529C;
  border-radius: 16px;
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

/* Primary Tabs Wrapper in Top Card */
.top-card-tabs-wrapper {
  margin-top: 8px;
  display: flex;
  align-items: center;
}

/* ════════════════════════════════════════════════════════════════════════════ */
/* CARD 2: BOTTOM TABLE SECTION (AppDataTable Standard)                         */
/* ════════════════════════════════════════════════════════════════════════════ */
.attendance-table-section {
  width: 100%;
}

.attendance-filter-panel-row {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 14px 16px;
  background: #FAFAFA;
  border: 1px solid #E5E5E5;
  border-radius: 8px;
  flex-wrap: wrap;
  width: 100%;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.filter-label {
  font-size: 11px;
  font-weight: 500;
  color: #737373;
}

.filter-select {
  height: 34px;
  padding: 0 10px;
  font-size: 12.5px;
  color: #404040;
  background: #ffffff;
  border: 1px solid #E5E5E5;
  border-radius: 6px;
  outline: none;
  cursor: pointer;
}

.btn-reset-filters {
  margin-top: 18px;
  padding: 6px 12px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background: transparent;
  border: 1px solid #E5E5E5;
  border-radius: 6px;
  cursor: pointer;
}

.btn-reset-filters:hover {
  background: #ffffff;
  color: #404040;
}

/* Table Scroll Wrapper */
.table-scroll-wrapper {
  overflow-x: auto;
  width: 100%;
}

/* Table Design */
.erp-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  text-align: left;
}

.erp-table thead tr {
  border-bottom: 1px solid #E5E5E5;
}

.erp-table th {
  padding: 12px 14px;
  font-size: 12px;
  font-weight: 600;
  color: #737373;
  white-space: nowrap;
  background: #FAFAFA;
}

.erp-table tbody tr {
  border-bottom: 1px solid #F0F0F0;
  transition: background 0.15s ease;
  cursor: pointer;
}

.erp-table tbody tr:hover {
  background: #F9FAFB;
}

.erp-table tbody tr:last-child {
  border-bottom: none;
}

.erp-table td {
  padding: 14px 14px;
  vertical-align: middle;
}

.th-name {
  min-width: 240px;
}

.td-name {
  min-width: 240px;
}

.name-header-content {
  display: inline-flex;
  align-items: center;
  gap: 12px;
}

.name-cell-content {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.name-cell-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.table-name-primary {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.table-code-subtext {
  font-size: 12px;
  color: #737373;
}

.text-positive {
  color: #009966;
}

.th-actions, .td-actions {
  width: 60px;
  text-align: right;
  padding-right: 14px;
}

/* Employee Identity Cell (Circular 40px Avatar) */
.employee-identity-cell {
  display: flex;
  align-items: center;
  gap: 12px;
}

.avatar-circular {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  overflow: hidden;
  background: #E5E7EB;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-initials {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.identity-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.employee-name-text {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.employee-meta-text {
  font-size: 12px;
  color: #737373;
}

.shift-cell {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.shift-name-text {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.shift-time-text {
  font-size: 12px;
  color: #737373;
}

.punch-cell {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.punch-time-val {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.device-tag {
  font-size: 11px;
  color: #737373;
}

.variance-text {
  font-size: 13px;
  color: #404040;
}

.text-tertiary {
  color: #737373;
  font-size: 13px;
}

/* Status Pills (Figma QMT System) */











.lock-pill.open {
  background: #EBFDF2;
  color: #027A48;
  border: 1px solid #A6F4C5;
}

.lock-pill.locked {
  background: #F5F5F5;
  color: #525252;
  border: 1px solid #E5E5E5;
}

.btn-row-action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  border-radius: 6px;
  background: transparent;
  border: none;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-row-action:hover {
  background: #F0F0F0;
  color: #404040;
}

/* Direction Badge for Raw Punches */
.direction-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 3px 8px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 600;
}

.direction-badge.dir-in {
  background: #EBFDF2;
  color: #027A48;
}

.direction-badge.dir-out {
  background: #FFF9EB;
  color: #B54708;
}

/* Exception Type Pill */
.exception-type-pill {
  display: inline-flex;
  align-items: center;
  padding: 3px 8px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 500;
  background: #F5F5F5;
  color: #404040;
}

.exception-actions-row {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.btn-regularize-approve {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  border-radius: 6px;
  background: #EBF3FC;
  border: 1px solid #CCE1F8;
  color: #0B529C;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
}
.btn-regularize-approve:hover {
  background: #CCE1F8;
}

.btn-regularize-reject {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  border-radius: 6px;
  background: #FEF3F2;
  border: 1px solid #FECDCA;
  color: #B42318;
  cursor: pointer;
}
.btn-regularize-reject:hover {
  background: #FECDCA;
}


/* Modals */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
  padding: 16px;
}

.details-modal-box {
  background: #ffffff;
  border-radius: 12px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
  width: 100%;
  max-width: 640px;
  overflow: hidden;
  border: 1px solid #E5E5E5;
}

.columns-modal-box {
  background: #ffffff;
  border-radius: 12px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
  width: 100%;
  max-width: 380px;
  overflow: hidden;
  border: 1px solid #E5E5E5;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid #E5E5E5;
}

.modal-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
}

.btn-close-modal {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  background: transparent;
  border: none;
  color: #737373;
  cursor: pointer;
}

.btn-close-modal:hover {
  background: #F5F5F5;
  color: #404040;
}

.columns-checklist {
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.column-check-item {
  display: flex;
  align-items: center;
  font-size: 13px;
  color: #404040;
  cursor: pointer;
}

.column-check-item :deep(.qmt-checkbox-wrapper) {
  width: 100%;
  margin: 0;
  padding: 0;
}

.column-check-item :deep(.qmt-checkbox-label) {
  font-size: 13px;
  color: #404040;
}

.modal-content-grid {
  padding: 20px;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

.info-group {
  display: flex;
  flex-direction: column;
}

.info-group.full-width {
  grid-column: span 2;
}

.info-label {
  font-size: 11px;
  font-weight: 500;
  color: #737373;
  margin-bottom: 4px;
}

.info-val {
  font-size: 13.5px;
  color: #404040;
}

.info-val-bold {
  font-size: 14.5px;
  font-weight: 600;
  color: #404040;
}

.info-sub {
  font-size: 12px;
  color: #737373;
  margin-top: 2px;
}

.info-justification {
  font-size: 13px;
  color: #404040;
  background: #FAFAFA;
  border: 1px solid #E5E5E5;
  border-radius: 6px;
  padding: 8px 12px;
  margin: 4px 0 0;
}

.review-box {
  background: #F9FAFB;
  border: 1px solid #E5E5E5;
  border-radius: 8px;
  padding: 14px;
  margin-top: 6px;
}

.review-box-title {
  font-size: 12.5px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 10px;
}

.review-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.form-label {
  font-size: 11.5px;
  font-weight: 500;
  color: #404040;
}

.modal-input {
  height: 36px;
  padding: 0 10px;
  font-size: 13px;
  color: #404040;
  border: 1px solid #E5E5E5;
  border-radius: 6px;
  background: #ffffff;
}

.modal-textarea {
  width: 100%;
  padding: 8px 10px;
  font-size: 13px;
  color: #404040;
  border: 1px solid #E5E5E5;
  border-radius: 6px;
  background: #ffffff;
  resize: vertical;
}

.modal-footer-row {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
  padding: 14px 20px;
  border-top: 1px solid #E5E5E5;
  background: #FAFAFA;
}

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

.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.2s ease;
}

.fade-slide-enter-from,
.fade-slide-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

@keyframes pulse {
  0% { transform: scale(0.95); opacity: 0.8; }
  50% { transform: scale(1.15); opacity: 1; }
  100% { transform: scale(0.95); opacity: 0.8; }
}
</style>
