<script setup lang="ts">
import { ref, computed } from 'vue';
import {
  Clock, AlertTriangle, AlertCircle, CheckCircle2,
  Send, Eye
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import MetricCard from '../../components/MetricCard.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import FormInput from '../../components/FormInput.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import type { ColumnDef, SortOption } from '../../components/BaseTable.vue';

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3: Exact Sidebar Page Name Only) ───
const breadcrumbItems = [
  { label: 'My Attendance' }
];

// ─── Logged-In Employee Context ───
const currentUser = {
  id: 14,
  name: 'Abebe Kebede',
  code: 'EMP-014',
  role: 'Head of Retail',
  entity_id: 7,
  entity_name: 'Bole Commercial Branch',
  org_unit: 'Retail Operations'
};

// ─── Top Tabs (AGENTS.md Rule 1: <BaseTabs /> Standard) ───
type TabKey = 'timesheet' | 'exceptions';
const activeTab = ref<TabKey>('timesheet');

// ─── Month Navigation ───
const selectedMonth = ref('2026-07');
const monthOptions = [
  { value: '2026-07', label: 'July 2026' },
  { value: '2026-06', label: 'June 2026' },
  { value: '2026-05', label: 'May 2026' }
];

// ─── Type Definitions (Schema Alignment: AttendanceDay & AttendanceException) ───
export interface PersonalAttendanceDay {
  id: number;
  date: string;
  day_name: string;
  shift_name: string;
  shift_code: string;
  first_in_at: string | null;
  last_out_at: string | null;
  scheduled_minutes: number;
  worked_minutes: number;
  late_minutes: number;
  early_leave_minutes: number;
  overtime_minutes: number;
  day_status: 'present' | 'absent' | 'late' | 'early_leave' | 'half_day' | 'on_leave' | 'holiday' | 'weekend';
  has_exception: boolean;
  exception_id?: number;
}

export interface PersonalAttendanceException {
  id: number;
  attendance_day_id: number;
  date: string;
  shift_name: string;
  exception_type: 'missed_punch' | 'late_arrival' | 'early_departure' | 'unscheduled_absence' | 'device_mismatch';
  exception_state: 'open' | 'justified' | 'rejected' | 'regularized';
  actual_first_in: string | null;
  actual_last_out: string | null;
  requested_first_in_at: string | null;
  requested_last_out_at: string | null;
  employee_note: string | null;
  reviewer_name: string | null;
  reviewed_at: string | null;
  resolution_note: string | null;
}

// ─── Mock Dataset: My Attendance Timesheet (AttendanceDay) ───
const timesheetRecords = ref<PersonalAttendanceDay[]>([
  {
    id: 810221,
    date: '2026-07-27',
    day_name: 'Monday',
    shift_name: 'Morning Retail Shift (08:00 – 17:00)',
    shift_code: 'SFT-MRN-01',
    first_in_at: '08:02:11',
    last_out_at: null,
    scheduled_minutes: 480,
    worked_minutes: 240,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    day_status: 'present',
    has_exception: true,
    exception_id: 5501
  },
  {
    id: 810222,
    date: '2026-07-28',
    day_name: 'Tuesday',
    shift_name: 'Morning Retail Shift (08:00 – 17:00)',
    shift_code: 'SFT-MRN-01',
    first_in_at: '08:24:00',
    last_out_at: '17:05:00',
    scheduled_minutes: 480,
    worked_minutes: 461,
    late_minutes: 24,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    day_status: 'late',
    has_exception: true,
    exception_id: 5502
  },
  {
    id: 810223,
    date: '2026-07-29',
    day_name: 'Wednesday',
    shift_name: 'Morning Retail Shift (08:00 – 17:00)',
    shift_code: 'SFT-MRN-01',
    first_in_at: '07:58:30',
    last_out_at: '17:03:10',
    scheduled_minutes: 480,
    worked_minutes: 480,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    day_status: 'present',
    has_exception: false
  },
  {
    id: 810224,
    date: '2026-07-30',
    day_name: 'Thursday',
    shift_name: 'Morning Retail Shift (08:00 – 17:00)',
    shift_code: 'SFT-MRN-01',
    first_in_at: '08:00:15',
    last_out_at: '18:30:00',
    scheduled_minutes: 480,
    worked_minutes: 570,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 90,
    day_status: 'present',
    has_exception: false
  },
  {
    id: 810225,
    date: '2026-07-31',
    day_name: 'Friday',
    shift_name: 'Morning Retail Shift (08:00 – 17:00)',
    shift_code: 'SFT-MRN-01',
    first_in_at: '08:05:00',
    last_out_at: '17:01:00',
    scheduled_minutes: 480,
    worked_minutes: 476,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    day_status: 'present',
    has_exception: false
  },
  {
    id: 810226,
    date: '2026-07-25',
    day_name: 'Saturday',
    shift_name: 'Weekend Coverage (09:00 – 14:00)',
    shift_code: 'SFT-WKD-01',
    first_in_at: '09:02:10',
    last_out_at: '14:05:00',
    scheduled_minutes: 300,
    worked_minutes: 303,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    day_status: 'present',
    has_exception: false
  },
  {
    id: 810227,
    date: '2026-07-26',
    day_name: 'Sunday',
    shift_name: 'Weekly Rest Day',
    shift_code: 'REST',
    first_in_at: null,
    last_out_at: null,
    scheduled_minutes: 0,
    worked_minutes: 0,
    late_minutes: 0,
    early_leave_minutes: 0,
    overtime_minutes: 0,
    day_status: 'weekend',
    has_exception: false
  }
]);

// ─── Mock Dataset: My Attendance Exceptions (AttendanceException) ───
const myExceptions = ref<PersonalAttendanceException[]>([
  {
    id: 5501,
    attendance_day_id: 810221,
    date: '2026-07-27',
    shift_name: 'Morning Retail Shift (08:00 – 17:00)',
    exception_type: 'missed_punch',
    exception_state: 'open',
    actual_first_in: '08:02:11',
    actual_last_out: null,
    requested_first_in_at: null,
    requested_last_out_at: null,
    employee_note: null,
    reviewer_name: null,
    reviewed_at: null,
    resolution_note: null
  },
  {
    id: 5502,
    attendance_day_id: 810222,
    date: '2026-07-28',
    shift_name: 'Morning Retail Shift (08:00 – 17:00)',
    exception_type: 'late_arrival',
    exception_state: 'open',
    actual_first_in: '08:24:00',
    actual_last_out: '17:05:00',
    requested_first_in_at: null,
    requested_last_out_at: null,
    employee_note: null,
    reviewer_name: null,
    reviewed_at: null,
    resolution_note: null
  },
  {
    id: 5488,
    attendance_day_id: 810190,
    date: '2026-07-14',
    shift_name: 'Morning Retail Shift (08:00 – 17:00)',
    exception_type: 'missed_punch',
    exception_state: 'regularized',
    actual_first_in: '08:00:10',
    actual_last_out: null,
    requested_first_in_at: '08:00:00',
    requested_last_out_at: '17:00:00',
    employee_note: 'Biometric reader at Bole main gate lost power during branch closing rush.',
    reviewer_name: 'Dawit Yohannes',
    reviewed_at: '2026-07-15 09:30',
    resolution_note: 'Verified with security ledger. Times regularized to standard shift hours.'
  },
  {
    id: 5460,
    attendance_day_id: 810150,
    date: '2026-07-03',
    shift_name: 'Morning Retail Shift (08:00 – 17:00)',
    exception_type: 'late_arrival',
    exception_state: 'justified',
    actual_first_in: '08:45:00',
    actual_last_out: '17:00:00',
    requested_first_in_at: '08:45:00',
    requested_last_out_at: '17:00:00',
    employee_note: 'Severe transport obstruction on Airport Road due to official convoy.',
    reviewer_name: 'Dawit Yohannes',
    reviewed_at: '2026-07-04 11:15',
    resolution_note: 'City traffic event verified. Excused without penalty.'
  }
]);

// ─── Metrics Computations ───
const openExceptionsCount = computed(() => {
  return myExceptions.value.filter(e => e.exception_state === 'open').length;
});

const totalWorkedHours = computed(() => {
  const totalMin = timesheetRecords.value.reduce((acc, r) => acc + r.worked_minutes, 0);
  return (totalMin / 60).toFixed(1);
});

const presentDaysCount = computed(() => {
  return timesheetRecords.value.filter(r => r.day_status === 'present').length;
});

const lateDaysCount = computed(() => {
  return timesheetRecords.value.filter(r => r.day_status === 'late').length;
});

// ─── Tabs Definition ───
const tabItems = computed<BaseTabItem<TabKey>[]>(() => [
  {
    id: 'timesheet',
    label: 'My Timesheet / Clock Log',
    icon: Clock
  },
  {
    id: 'exceptions',
    label: 'Attendance Exceptions',
    icon: AlertCircle,
    count: openExceptionsCount.value > 0 ? openExceptionsCount.value : undefined,
    badgeVariant: 'warning'
  }
]);

// ─── Table Columns (AGENTS.md Rule 9: Atomic Columns Standard) ───
const timesheetColumns: ColumnDef[] = [
  { key: 'date', label: 'Date', sortable: true, visible: true },
  { key: 'shift_name', label: 'Rostered Shift', sortable: false, visible: true },
  { key: 'first_in_at', label: 'First In', sortable: true, visible: true },
  { key: 'last_out_at', label: 'Last Out', sortable: true, visible: true },
  { key: 'scheduled_hours', label: 'Scheduled', sortable: false, visible: true },
  { key: 'worked_hours', label: 'Worked', sortable: true, visible: true },
  { key: 'overtime_hours', label: 'Overtime', sortable: false, visible: true },
  { key: 'day_status', label: 'Status', sortable: true, visible: true },
  { key: 'actions', label: 'Action', sortable: false, visible: true }
];

const exceptionsColumns: ColumnDef[] = [
  { key: 'date', label: 'Date', sortable: true, visible: true },
  { key: 'shift_name', label: 'Rostered Shift', sortable: false, visible: true },
  { key: 'exception_type', label: 'Anomaly Type', sortable: true, visible: true },
  { key: 'actual_times', label: 'Recorded Punches', sortable: false, visible: true },
  { key: 'requested_times', label: 'Requested Punches', sortable: false, visible: true },
  { key: 'employee_note', label: 'My Justification', sortable: false, visible: true },
  { key: 'exception_state', label: 'State', sortable: true, visible: true },
  { key: 'actions', label: 'Action', sortable: false, visible: true }
];

const timesheetSearch = ref('');
const exceptionsSearch = ref('');

// ─── Filtering Datasets ───
const filteredTimesheet = computed(() => {
  const q = timesheetSearch.value.trim().toLowerCase();
  if (!q) return timesheetRecords.value;
  return timesheetRecords.value.filter(r => 
    r.date.includes(q) || 
    r.day_name.toLowerCase().includes(q) || 
    r.shift_name.toLowerCase().includes(q) ||
    r.day_status.toLowerCase().includes(q)
  );
});

const filteredExceptions = computed(() => {
  const q = exceptionsSearch.value.trim().toLowerCase();
  if (!q) return myExceptions.value;
  return myExceptions.value.filter(e => 
    e.date.includes(q) || 
    e.shift_name.toLowerCase().includes(q) ||
    e.exception_type.toLowerCase().includes(q) ||
    e.exception_state.toLowerCase().includes(q) ||
    (e.employee_note && e.employee_note.toLowerCase().includes(q))
  );
});

// ─── Justification Submission Modal (AGENTS.md Rule 4 & 5) ───
const showJustificationModal = ref(false);
const activeExceptionForJustification = ref<PersonalAttendanceException | null>(null);

const justificationForm = ref({
  requested_in: '',
  requested_out: '',
  employee_note: ''
});

const openJustifyModal = (exception: PersonalAttendanceException) => {
  activeExceptionForJustification.value = exception;
  justificationForm.value = {
    requested_in: exception.actual_first_in ? exception.actual_first_in.slice(0, 5) : '08:00',
    requested_out: exception.actual_last_out ? exception.actual_last_out.slice(0, 5) : '17:00',
    employee_note: exception.employee_note || ''
  };
  showJustificationModal.value = true;
};

const closeJustifyModal = () => {
  showJustificationModal.value = false;
  activeExceptionForJustification.value = null;
};

const handleSubmitJustification = () => {
  if (!activeExceptionForJustification.value) return;
  if (!justificationForm.value.employee_note.trim()) {
    alert('Please enter an operational reason or explanation.');
    return;
  }

  // Update in-memory record
  const ex = myExceptions.value.find(e => e.id === activeExceptionForJustification.value!.id);
  if (ex) {
    ex.requested_first_in_at = justificationForm.value.requested_in + ':00';
    ex.requested_last_out_at = justificationForm.value.requested_out + ':00';
    ex.employee_note = justificationForm.value.employee_note;
    // Remains 'open' but with justification attached awaiting supervisor decision
  }

  closeJustifyModal();
};

// ─── Detail Inspection Modal for Resolved Exceptions ───
const showDetailModal = ref(false);
const inspectingException = ref<PersonalAttendanceException | null>(null);

const openDetailModal = (exception: PersonalAttendanceException) => {
  inspectingException.value = exception;
  showDetailModal.value = true;
};

const closeDetailModal = () => {
  showDetailModal.value = false;
  inspectingException.value = null;
};

// ─── Format Helpers ───
const formatMinutes = (mins: number) => {
  if (!mins) return '0h';
  const h = Math.floor(mins / 60);
  const m = mins % 60;
  return m > 0 ? `${h}h ${m}m` : `${h}h`;
};

const getExceptionTypeLabel = (type: string) => {
  switch (type) {
    case 'missed_punch': return 'Missed Punch';
    case 'late_arrival': return 'Late Arrival';
    case 'early_departure': return 'Early Departure';
    case 'unscheduled_absence': return 'Unscheduled Absence';
    case 'device_mismatch': return 'Device Mismatch';
    default: return type;
  }
};
</script>

<template>
  <div class="my-attendance-page">
    <!-- Top Breadcrumb (Rule 3: Exact Page Name Only) -->
    <div class="page-header">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Employee Profile Banner -->
    <div class="employee-context-card">
      <div class="context-avatar">
        {{ currentUser.name.split(' ').map(n => n[0]).join('') }}
      </div>
      <div class="context-details">
        <h2 class="context-name">{{ currentUser.name }}</h2>
        <p class="context-meta">
          <span>{{ currentUser.code }}</span> &bull; 
          <span>{{ currentUser.role }}</span> &bull; 
          <span>{{ currentUser.org_unit }}</span> &bull; 
          <span>{{ currentUser.entity_name }}</span>
        </p>
      </div>
      <div class="context-filter">
        <select v-model="selectedMonth" class="month-select">
          <option v-for="opt in monthOptions" :key="opt.value" :value="opt.value">
            {{ opt.label }}
          </option>
        </select>
      </div>
    </div>

    <!-- Top KPI / Metrics Cards Grid (AGENTS.md Rule 2 Standard) -->
    <div class="metrics-grid">
      <div class="metric-wrapper">
        <MetricCard
          label="Total Worked"
          :value="`${totalWorkedHours} Hrs`"
          subtext="Net of break time this period"
          :icon="Clock"
          size="md"
          :show-menu="false"
        />
      </div>

      <div class="metric-wrapper">
        <MetricCard
          label="Days Present"
          :value="`${presentDaysCount} Days`"
          subtext="Scheduled shifts fulfilled"
          :icon="CheckCircle2"
          size="md"
          :show-menu="false"
        />
      </div>

      <div class="metric-wrapper">
        <MetricCard
          label="Late Arrivals"
          :value="`${lateDaysCount} Incident`"
          subtext="Clocked after shift grace"
          :icon="AlertTriangle"
          size="md"
          :show-menu="false"
        />
      </div>

      <div 
        class="metric-wrapper metric-interactive" 
        :class="{ 'metric-active': activeTab === 'exceptions' }"
        @click="activeTab = 'exceptions'"
      >
        <MetricCard
          label="Open Exceptions"
          :value="`${openExceptionsCount}`"
          subtext="Click to view & justify anomalies"
          :icon="AlertCircle"
          size="md"
          :show-menu="false"
        />
      </div>
    </div>

    <!-- Primary Tabs (AGENTS.md Rule 1: <BaseTabs /> Standard) -->
    <div class="tabs-row">
      <BaseTabs v-model="activeTab" :tabs="tabItems" />
    </div>

    <!-- Tab 1: My Timesheet / Clock Log -->
    <div v-if="activeTab === 'timesheet'" class="tab-pane">
      <AppDataTable
        title="Personal Attendance Timesheet"
        subtitle="Daily records of punch logs, scheduled duration, actual worked hours, and status."
        v-model:searchQuery="timesheetSearch"
        :columns="timesheetColumns"
        :totalEntries="filteredTimesheet.length"
        :showFilter="false"
        :showSort="false"
      >
        <table class="erp-table">
          <thead>
            <tr>
              <th class="th-date">Date</th>
              <th>Rostered Shift</th>
              <th>First In</th>
              <th>Last Out</th>
              <th>Scheduled</th>
              <th>Worked</th>
              <th>Overtime</th>
              <th>Status</th>
              <th class="th-action text-right">Action</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in filteredTimesheet" :key="row.id">
              <!-- Name/Primary Column: Secondary Color (#404040, font-weight 500) -->
              <td class="td-primary">
                <span class="cell-date-main">{{ row.date }}</span>
                <span class="cell-subtext">{{ row.day_name }}</span>
              </td>

              <!-- Tertiary Color (#737373) for all subsequent columns (Rule 5) -->
              <td class="td-tertiary">
                {{ row.shift_name }}
              </td>

              <td class="td-tertiary font-mono">
                {{ row.first_in_at || '—' }}
              </td>

              <td class="td-tertiary font-mono">
                {{ row.last_out_at || '—' }}
              </td>

              <td class="td-tertiary">
                {{ formatMinutes(row.scheduled_minutes) }}
              </td>

              <td class="td-tertiary font-medium">
                {{ formatMinutes(row.worked_minutes) }}
              </td>

              <td class="td-tertiary">
                <span v-if="row.overtime_minutes > 0" class="ot-text">+{{ formatMinutes(row.overtime_minutes) }}</span>
                <span v-else>—</span>
              </td>

              <!-- Status Column (Pill strictly reserved for status, Rule 6 & 9) -->
              <td>
                <span class="status-pill" :class="`status-${row.day_status}`">
                  {{ row.day_status.replace('_', ' ').toUpperCase() }}
                </span>
              </td>

              <!-- Action Column -->
              <td class="text-right">
                <button
                  v-if="row.has_exception"
                  type="button"
                  class="btn-exception-link"
                  @click="activeTab = 'exceptions'"
                >
                  <AlertCircle :size="13" />
                  <span>View Anomaly</span>
                </button>
                <span v-else class="text-subtle">—</span>
              </td>
            </tr>
          </tbody>
        </table>
      </AppDataTable>
    </div>

    <!-- Tab 2: Attendance Exceptions & Justifications -->
    <div v-else-if="activeTab === 'exceptions'" class="tab-pane">
      <AppDataTable
        title="My Attendance Exceptions"
        subtitle="Automated punch anomalies detected by the attendance engine. Submit justification to regularize your times."
        v-model:searchQuery="exceptionsSearch"
        :columns="exceptionsColumns"
        :totalEntries="filteredExceptions.length"
        :showFilter="false"
        :showSort="false"
      >
        <table class="erp-table">
          <thead>
            <tr>
              <th class="th-date">Date</th>
              <th>Rostered Shift</th>
              <th>Anomaly Type</th>
              <th>Recorded Punches</th>
              <th>Requested Punches</th>
              <th>My Justification</th>
              <th>State</th>
              <th class="th-action text-right">Action</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="ex in filteredExceptions" :key="ex.id">
              <!-- First column in Secondary Color (#404040) -->
              <td class="td-primary">
                <span class="cell-date-main">{{ ex.date }}</span>
              </td>

              <!-- Subsequent columns in Tertiary Color (#737373) -->
              <td class="td-tertiary">
                {{ ex.shift_name }}
              </td>

              <td class="td-tertiary">
                <span class="anomaly-tag">{{ getExceptionTypeLabel(ex.exception_type) }}</span>
              </td>

              <td class="td-tertiary font-mono">
                {{ ex.actual_first_in ? ex.actual_first_in.slice(0, 5) : '—' }} &rarr; 
                {{ ex.actual_last_out ? ex.actual_last_out.slice(0, 5) : '[Missing]' }}
              </td>

              <td class="td-tertiary font-mono">
                <span v-if="ex.requested_first_in_at">
                  {{ ex.requested_first_in_at.slice(0, 5) }} &rarr; {{ ex.requested_last_out_at ? ex.requested_last_out_at.slice(0, 5) : '—' }}
                </span>
                <span v-else class="text-subtle">Not requested</span>
              </td>

              <td class="td-tertiary max-w-xs truncate" :title="ex.employee_note || ''">
                <span v-if="ex.employee_note">{{ ex.employee_note }}</span>
                <span v-else class="text-subtle font-italic">No note submitted</span>
              </td>

              <!-- State Column (Rule 9) -->
              <td>
                <span class="status-pill" :class="`state-${ex.exception_state}`">
                  {{ ex.exception_state.toUpperCase() }}
                </span>
              </td>

              <!-- Actions (Rule 6: Rectangular button 8px radius, NEVER fully rounded) -->
              <td class="text-right">
                <button
                  v-if="ex.exception_state === 'open'"
                  type="button"
                  class="btn-action-primary"
                  @click="openJustifyModal(ex)"
                >
                  <Send :size="13" />
                  <span>{{ ex.employee_note ? 'Edit Justification' : 'Justify' }}</span>
                </button>
                <button
                  v-else
                  type="button"
                  class="btn-action-secondary"
                  @click="openDetailModal(ex)"
                >
                  <Eye :size="13" />
                  <span>Audit Detail</span>
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </AppDataTable>
    </div>

    <!-- ═══ MODAL: Submit Attendance Justification (Rule 4 & 5) ═══ -->
    <div v-if="showJustificationModal && activeExceptionForJustification" class="modal-backdrop" @click="closeJustifyModal">
      <div class="modal-dialog" @click.stop>
        <!-- Modal Header (Rule 4: Title ONLY, no subtitle, NO bottom divider line) -->
        <div class="modal-header-clean">
          <h3 class="modal-title-text">Submit Attendance Justification</h3>
          <button type="button" class="btn-modal-close" @click="closeJustifyModal">&times;</button>
        </div>

        <div class="modal-body">
          <!-- Anomaly Summary Card -->
          <div class="anomaly-summary-box">
            <div class="summary-item">
              <span class="summary-label">Date & Shift</span>
              <span class="summary-val">{{ activeExceptionForJustification.date }} &bull; {{ activeExceptionForJustification.shift_name }}</span>
            </div>
            <div class="summary-item">
              <span class="summary-label">Detected Anomaly</span>
              <span class="summary-val text-amber-700 font-semibold">{{ getExceptionTypeLabel(activeExceptionForJustification.exception_type) }}</span>
            </div>
            <div class="summary-item">
              <span class="summary-label">Actual Punch Times</span>
              <span class="summary-val font-mono">
                Clock In: {{ activeExceptionForJustification.actual_first_in || 'No Punch' }} &bull; 
                Clock Out: {{ activeExceptionForJustification.actual_last_out || 'No Punch' }}
              </span>
            </div>
          </div>

          <!-- Form Grid: Requested Punch Times -->
          <div class="time-adjustments-grid">
            <FormInput
              v-model="justificationForm.requested_in"
              label="Requested Clock-In Time"
              type="time"
              :required="true"
            />
            <FormInput
              v-model="justificationForm.requested_out"
              label="Requested Clock-Out Time"
              type="time"
              :required="true"
            />
          </div>

          <!-- Form Control: Employee Explanation Note (Rule 5: No placeholder) -->
          <div class="mt-4">
            <FormTextarea
              v-model="justificationForm.employee_note"
              label="Reason & Operational Explanation"
              :required="true"
              :rows="4"
              helperText="State why the punch was missed or delayed (e.g. power outage, field duty, emergency support)."
            />
          </div>
        </div>

        <!-- Modal Footer Actions (Rule 6: Well-rounded rectangle 8px radius) -->
        <div class="modal-footer-clean">
          <AppButton variant="outline" size="sm" @click="closeJustifyModal">
            Dismiss
          </AppButton>
          <AppButton variant="primary" size="sm" @click="handleSubmitJustification">
            <template #icon-left><Send :size="14" /></template>
            Submit to Supervisor
          </AppButton>
        </div>
      </div>
    </div>

    <!-- ═══ MODAL: Audit & Review Detail View ═══ -->
    <div v-if="showDetailModal && inspectingException" class="modal-backdrop" @click="closeDetailModal">
      <div class="modal-dialog" @click.stop>
        <div class="modal-header-clean">
          <h3 class="modal-title-text">Exception Audit & Decision</h3>
          <button type="button" class="btn-modal-close" @click="closeDetailModal">&times;</button>
        </div>

        <div class="modal-body">
          <div class="audit-status-strip">
            <span class="status-pill" :class="`state-${inspectingException.exception_state}`">
              {{ inspectingException.exception_state.toUpperCase() }}
            </span>
            <span class="text-tertiary text-xs ml-3">
              Reviewed by <strong>{{ inspectingException.reviewer_name || 'System / Line Manager' }}</strong> on {{ inspectingException.reviewed_at || '—' }}
            </span>
          </div>

          <div class="audit-block mt-4">
            <h4 class="audit-label">My Submitted Justification:</h4>
            <div class="audit-card-text">
              {{ inspectingException.employee_note || 'No note provided.' }}
            </div>
          </div>

          <div class="audit-block mt-4">
            <h4 class="audit-label">Supervisor / HR Resolution Audit Note:</h4>
            <div class="audit-card-text bg-gray-50 border border-gray-100">
              {{ inspectingException.resolution_note || 'Pending formal review note.' }}
            </div>
          </div>

          <div class="audit-block mt-4">
            <h4 class="audit-label">Regularized Punch Times:</h4>
            <div class="font-mono text-sm text-neutral-700">
              Clock In: <strong>{{ inspectingException.requested_first_in_at || '—' }}</strong> &bull; 
              Clock Out: <strong>{{ inspectingException.requested_last_out_at || '—' }}</strong>
            </div>
          </div>
        </div>

        <div class="modal-footer-clean">
          <AppButton variant="outline" size="sm" @click="closeDetailModal">
            Close
          </AppButton>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.my-attendance-page {
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
}

.page-header {
  margin-bottom: 4px;
}

/* ─── Employee Context Banner ─── */
.employee-context-card {
  display: flex;
  align-items: center;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 20px;
  gap: 16px;
}

.context-avatar {
  width: 46px;
  height: 46px;
  border-radius: 50%;
  background: #0B529C;
  color: #ffffff;
  font-size: 16px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.context-details {
  flex: 1;
}

.context-name {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 2px 0;
}

.context-meta {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

.context-filter {
  margin-left: auto;
}

.month-select {
  height: 36px;
  padding: 0 12px;
  font-size: 13px;
  color: #404040;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  outline: none;
}

.month-select:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

/* ─── Metrics Grid (AGENTS.md Rule 2) ─── */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

.metric-wrapper {
  min-height: 106px;
}

.metric-interactive {
  cursor: pointer;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}

.metric-interactive:hover {
  transform: translateY(-1px);
}

.metric-active {
  outline: 2px solid #0B529C;
  border-radius: 10px;
}

/* ─── Tabs Row ─── */
.tabs-row {
  margin-top: 4px;
}

.tab-pane {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* ─── Table Architecture (AGENTS.md Rule 8 & 9) ─── */
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
  background: #fafafa;
  border-bottom: 1px solid #f1f5f9;
  text-align: left;
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  font-size: 13px;
  border-bottom: 1px solid #f8fafc;
}

.td-primary {
  color: #404040;
  font-weight: 500;
}

.cell-date-main {
  display: block;
  font-size: 13px;
  color: #404040;
}

.cell-subtext {
  display: block;
  font-size: 11.5px;
  color: #737373;
}

.td-tertiary {
  color: #737373;
}

.font-mono {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}

.ot-text {
  color: #059669;
  font-weight: 500;
}

.text-subtle {
  color: #94a3b8;
}

.anomaly-tag {
  font-size: 12px;
  color: #404040;
  background: #f1f5f9;
  padding: 3px 8px;
  border-radius: 6px;
}

/* ─── Status Pills (Rule 8 & 9 Standard) ─── */
.status-pill {
  display: inline-block;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
  letter-spacing: 0.02em;
}

.status-present {
  background: #ecfdf5;
  color: #059669;
}

.status-late {
  background: #fffbeb;
  color: #d97706;
}

.status-absent {
  background: #fef2f2;
  color: #dc2626;
}

.status-weekend, .status-holiday {
  background: #f1f5f9;
  color: #64748b;
}

.status-on_leave {
  background: #eff6ff;
  color: #2563eb;
}

/* Exception States */
.state-open {
  background: #fef3c7;
  color: #b45309;
}

.state-regularized {
  background: #ecfdf5;
  color: #059669;
}

.state-justified {
  background: #f3e8ff;
  color: #7e22ce;
}

.state-rejected {
  background: #fef2f2;
  color: #dc2626;
}

/* ─── Buttons (AGENTS.md Rule 6: 8px to 10px Rectangular Shape) ─── */
.btn-exception-link {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 28px;
  padding: 0 10px;
  border-radius: 8px;
  font-size: 12px;
  color: #d97706;
  background: #fffbeb;
  border: 1px solid #fde68a;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-exception-link:hover {
  background: #fef3c7;
}

.btn-action-primary {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 30px;
  padding: 0 12px;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  color: #ffffff;
  background: #0B529C;
  border: none;
  cursor: pointer;
  transition: background 0.15s ease;
}

.btn-action-primary:hover {
  background: #09427d;
}

.btn-action-secondary {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 30px;
  padding: 0 12px;
  border-radius: 8px;
  font-size: 12.5px;
  color: #404040;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  cursor: pointer;
  transition: background 0.15s ease;
}

.btn-action-secondary:hover {
  background: #f1f5f9;
}

/* ─── Modal Architecture (Rule 4 Standard) ─── */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  backdrop-filter: blur(2px);
}

.modal-dialog {
  background: #ffffff;
  width: 100%;
  max-width: 540px;
  border-radius: 12px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.modal-header-clean {
  padding: 20px 24px 14px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.modal-title-text {
  font-size: 18px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.btn-modal-close {
  background: transparent;
  border: none;
  font-size: 24px;
  color: #94a3b8;
  cursor: pointer;
  line-height: 1;
}

.btn-modal-close:hover {
  color: #404040;
}

.modal-body {
  padding: 0 24px 20px 24px;
}

.anomaly-summary-box {
  background: #f8fafc;
  border: 1px solid #f1f5f9;
  border-radius: 8px;
  padding: 12px 16px;
  margin-bottom: 16px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.summary-item {
  display: flex;
  justify-content: space-between;
  font-size: 12.5px;
}

.summary-label {
  color: #737373;
}

.summary-val {
  color: #404040;
}

.time-adjustments-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.modal-footer-clean {
  padding: 14px 24px 20px 24px;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.btn-modal-secondary {
  height: 38px;
  padding: 0 16px;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  cursor: pointer;
  transition: background 0.15s ease;
}

.btn-modal-secondary:hover {
  background: #f8fafc;
}

.btn-modal-primary {
  height: 38px;
  padding: 0 18px;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  color: #ffffff;
  background: #0B529C;
  border: none;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  transition: background 0.15s ease;
}

.btn-modal-primary:hover {
  background: #09427d;
}

/* ─── Audit Modal Elements ─── */
.audit-status-strip {
  display: flex;
  align-items: center;
  padding-bottom: 12px;
  border-bottom: 1px solid #f1f5f9;
}

.audit-block {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.audit-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin: 0;
}

.audit-card-text {
  font-size: 13px;
  color: #404040;
  padding: 10px 14px;
  border-radius: 8px;
  background: #f8fafc;
  line-height: 1.45;
}
</style>

