<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  ChevronLeft, ChevronRight, Wand2, CheckCircle2,
  Save, X, RotateCcw
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormInput from '../../components/FormInput.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';

const router = useRouter();

// ─── Breadcrumbs (Rule 4: Child Page Breadcrumb) ───
const breadcrumbItems = [
  { label: 'Shift Assignments', to: '/hr/shift-assignments' },
  { label: 'Assign Shifts' }
];

// ─── State & Save Tracking ───
const isSaved = ref(false);
const isDraft = ref(true);
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Scope Parameters ───
const selectedEntityId = ref('7'); // Bole Commercial Branch
const selectedOrgUnitId = ref('all');

const entityOptions = [
  { label: 'Bole Commercial Branch', value: '7' },
  { label: 'Hawassa Industrial Plant', value: '9' },
  { label: 'Haleta Addis Ababa HQ', value: '3' }
];

const orgUnitOptions = computed(() => {
  if (selectedEntityId.value === '7') {
    return [
      { label: 'All Departments', value: 'all' },
      { label: 'Retail Operations', value: '1' },
      { label: 'Customer Cashiers', value: '2' },
      { label: 'Warehouse & Inventory', value: '3' }
    ];
  } else if (selectedEntityId.value === '9') {
    return [
      { label: 'All Departments', value: 'all' },
      { label: 'Plant Security', value: '4' }
    ];
  } else {
    return [
      { label: 'All Departments', value: 'all' },
      { label: 'Human Resources', value: '5' },
      { label: 'Administration', value: '6' }
    ];
  }
});

// ─── Week Navigation ───
function addDays(d: Date, n: number): Date {
  const r = new Date(d);
  r.setDate(r.getDate() + n);
  return r;
}

function toIso(d: Date): string {
  return d.toISOString().slice(0, 10);
}

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

// ─── Shifts & Patterns Catalog (HR_Schema_final-v4.sql lines 1334–1385) ───
interface ShiftDef {
  id: number;
  code: string;
  name: string;
  start_time: string;
  end_time: string;
  hours: number;
  color_class: string;
}

const shiftCatalog: Record<number, ShiftDef> = {
  1: { id: 1, code: 'OFF', name: 'Office Day', start_time: '08:30', end_time: '17:30', hours: 8.0, color_class: 'shift-tag-blue' },
  2: { id: 2, code: 'MORN', name: 'Retail Morning', start_time: '07:00', end_time: '15:00', hours: 7.5, color_class: 'shift-tag-amber' },
  3: { id: 3, code: 'EVE', name: 'Retail Evening', start_time: '14:30', end_time: '22:30', hours: 7.5, color_class: 'shift-tag-purple' },
  4: { id: 4, code: 'NGHT', name: 'Night Guard', start_time: '22:00', end_time: '06:00', hours: 7.25, color_class: 'shift-tag-slate' },
  5: { id: 5, code: 'SPLT', name: 'Shop Split', start_time: '09:00', end_time: '20:00', hours: 8.0, color_class: 'shift-tag-emerald' }
};

const patternTemplates = [
  { id: 1, code: 'PAT-OFF-5D', name: 'Office Mon-Fri (5 Work, 2 Off)', cycle_days: 7, shifts: [1, 1, 1, 1, 1, null, null] },
  { id: 2, code: 'PAT-RETAIL-6D', name: 'Retail 6-Day Rota (6 Work, 1 Off)', cycle_days: 7, shifts: [2, 2, 2, 2, 2, 2, null] },
  { id: 3, code: 'PAT-2M2E2O', name: 'Continuous 2-2-2 (2 Morn, 2 Eve, 2 Off)', cycle_days: 6, shifts: [2, 2, 3, 3, null, null] },
  { id: 4, code: 'PAT-GUARD-4C', name: 'Night Guard 4-Day Cycle (2 Night, 2 Off)', cycle_days: 4, shifts: [4, 4, null, null] }
];

// ─── Master Staff Pool ───
interface StaffMember {
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

const allStaff: StaffMember[] = [
  { id: 14, code: 'EMP-014', name: 'Abebe Kebede', role: 'Head of Retail', org_unit_id: 1, org_unit_name: 'Retail Operations', avatar_initials: 'AK', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 15, code: 'EMP-015', name: 'Sara Tefera', role: 'Shift Supervisor', org_unit_id: 1, org_unit_name: 'Retail Operations', avatar_initials: 'ST', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 18, code: 'EMP-018', name: 'Dawit Yohannes', role: 'Senior Cashier', org_unit_id: 2, org_unit_name: 'Customer Cashiers', avatar_initials: 'DY', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 22, code: 'EMP-022', name: 'Bethlehem Haile', role: 'Inventory Controller', org_unit_id: 3, org_unit_name: 'Warehouse & Inventory', avatar_initials: 'BH', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 7,  code: 'EMP-007', name: 'Tewodros Kassahun', role: 'Security Guard', org_unit_id: 4, org_unit_name: 'Plant Security', avatar_initials: 'TK', entity_id: 9, entity_name: 'Hawassa Industrial Plant' },
  { id: 8,  code: 'EMP-008', name: 'Mulugeta Belete', role: 'Night Guard Lead', org_unit_id: 4, org_unit_name: 'Plant Security', avatar_initials: 'MB', entity_id: 9, entity_name: 'Hawassa Industrial Plant' },
  { id: 9,  code: 'EMP-009', name: 'Almaz Mengistu', role: 'HR Operations Lead', org_unit_id: 5, org_unit_name: 'Human Resources', avatar_initials: 'AM', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ' },
  { id: 11, code: 'EMP-011', name: 'Kassahun Bekele', role: 'Facilities Officer', org_unit_id: 6, org_unit_name: 'Administration', avatar_initials: 'KB', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ' }
];

// Filtered Staff in Scope
const scopedStaff = computed(() => {
  return allStaff.filter(s => {
    const matchEntity = String(s.entity_id) === selectedEntityId.value;
    const matchUnit = selectedOrgUnitId.value === 'all' || String(s.org_unit_id) === selectedOrgUnitId.value;
    return matchEntity && matchUnit;
  });
});

// ─── Active Assignments Grid Map ───
export interface ActiveRosterSlot {
  id: number;
  employee_id: number;
  date: string;
  shift_id: number | null; // null = rest day
  state: 'planned' | 'published' | 'swapped' | 'cancelled';
  pattern_name?: string;
  swapped_with_name?: string;
  notes?: string;
}

const rosterSlots = ref<ActiveRosterSlot[]>([
  // Abebe
  { id: 101, employee_id: 14, date: '2026-07-27', shift_id: 2, state: 'published', pattern_name: 'PAT-RETAIL-6D' },
  { id: 102, employee_id: 14, date: '2026-07-28', shift_id: 2, state: 'published', pattern_name: 'PAT-RETAIL-6D' },
  { id: 103, employee_id: 14, date: '2026-07-29', shift_id: 3, state: 'swapped', pattern_name: 'PAT-RETAIL-6D', swapped_with_name: 'Sara Tefera' },
  { id: 104, employee_id: 14, date: '2026-07-30', shift_id: 3, state: 'published', pattern_name: 'PAT-RETAIL-6D' },
  { id: 105, employee_id: 14, date: '2026-07-31', shift_id: null, state: 'published', pattern_name: 'PAT-RETAIL-6D' },
  { id: 106, employee_id: 14, date: '2026-08-01', shift_id: 2, state: 'published', pattern_name: 'PAT-RETAIL-6D' },
  { id: 107, employee_id: 14, date: '2026-08-02', shift_id: null, state: 'published', pattern_name: 'PAT-RETAIL-6D' },

  // Sara
  { id: 201, employee_id: 15, date: '2026-07-27', shift_id: 3, state: 'published', pattern_name: 'PAT-RETAIL-6D' },
  { id: 202, employee_id: 15, date: '2026-07-28', shift_id: 3, state: 'published', pattern_name: 'PAT-RETAIL-6D' },
  { id: 203, employee_id: 15, date: '2026-07-29', shift_id: 2, state: 'swapped', pattern_name: 'PAT-RETAIL-6D', swapped_with_name: 'Abebe Kebede' },
  { id: 204, employee_id: 15, date: '2026-07-30', shift_id: 2, state: 'planned', pattern_name: 'PAT-RETAIL-6D' },
  { id: 205, employee_id: 15, date: '2026-07-31', shift_id: 2, state: 'planned', pattern_name: 'PAT-RETAIL-6D' },
  { id: 206, employee_id: 15, date: '2026-08-01', shift_id: 3, state: 'planned', pattern_name: 'PAT-RETAIL-6D' },
  { id: 207, employee_id: 15, date: '2026-08-02', shift_id: null, state: 'planned', pattern_name: 'PAT-RETAIL-6D' },

  // Dawit
  { id: 301, employee_id: 18, date: '2026-07-27', shift_id: 2, state: 'published', pattern_name: 'PAT-RETAIL-6D' },
  { id: 302, employee_id: 18, date: '2026-07-28', shift_id: 2, state: 'published', pattern_name: 'PAT-RETAIL-6D' },
  { id: 303, employee_id: 18, date: '2026-07-29', shift_id: 2, state: 'published', pattern_name: 'PAT-RETAIL-6D' },
  { id: 304, employee_id: 18, date: '2026-07-30', shift_id: null, state: 'published', pattern_name: 'PAT-RETAIL-6D' },
  { id: 305, employee_id: 18, date: '2026-07-31', shift_id: 3, state: 'planned', pattern_name: 'PAT-RETAIL-6D' },
  { id: 306, employee_id: 18, date: '2026-08-01', shift_id: 3, state: 'planned', pattern_name: 'PAT-RETAIL-6D' },
  { id: 307, employee_id: 18, date: '2026-08-02', shift_id: null, state: 'planned', pattern_name: 'PAT-RETAIL-6D' },

  // Bethlehem
  { id: 401, employee_id: 22, date: '2026-07-27', shift_id: 5, state: 'published', pattern_name: 'PAT-RETAIL-6D' },
  { id: 402, employee_id: 22, date: '2026-07-28', shift_id: 5, state: 'published', pattern_name: 'PAT-RETAIL-6D' },
  { id: 403, employee_id: 22, date: '2026-07-29', shift_id: 5, state: 'published', pattern_name: 'PAT-RETAIL-6D' },
  { id: 404, employee_id: 22, date: '2026-07-30', shift_id: 5, state: 'planned', pattern_name: 'PAT-RETAIL-6D' },
  { id: 405, employee_id: 22, date: '2026-07-31', shift_id: 5, state: 'planned', pattern_name: 'PAT-RETAIL-6D' },
  { id: 406, employee_id: 22, date: '2026-08-01', shift_id: null, state: 'planned', pattern_name: 'PAT-RETAIL-6D' },
  { id: 407, employee_id: 22, date: '2026-08-02', shift_id: null, state: 'planned', pattern_name: 'PAT-RETAIL-6D' }
]);

const getSlot = (employeeId: number, dateIso: string): ActiveRosterSlot | undefined => {
  return rosterSlots.value.find(s => s.employee_id === employeeId && s.date === dateIso);
};

// ─── Weekly Hours Calculation & OT Guardrails ───
const getStaffWeeklyHours = (empId: number): number => {
  const dates = weekDays.value.map(d => d.iso);
  let total = 0;
  for (const date of dates) {
    const slot = getSlot(empId, date);
    if (slot && slot.shift_id && slot.state !== 'cancelled') {
      const shift = shiftCatalog[slot.shift_id];
      total += shift ? shift.hours : 8.0;
    }
  }
  return Number(total.toFixed(1));
};

// Summary Metrics
const stats = computed(() => {
  let totalHours = 0;
  let scheduledShifts = 0;
  let overtimeRisks = 0;
  let plannedCount = 0;
  let publishedCount = 0;

  scopedStaff.value.forEach(s => {
    const h = getStaffWeeklyHours(s.id);
    totalHours += h;
    if (h > 48.0) overtimeRisks++;
  });

  const dates = weekDays.value.map(d => d.iso);
  scopedStaff.value.forEach(s => {
    dates.forEach(d => {
      const slot = getSlot(s.id, d);
      if (slot && slot.shift_id && slot.state !== 'cancelled') {
        scheduledShifts++;
        if (slot.state === 'planned') plannedCount++;
        if (slot.state === 'published') publishedCount++;
      }
    });
  });

  return {
    headcount: scopedStaff.value.length,
    totalHours: Number(totalHours.toFixed(1)),
    scheduledShifts,
    overtimeRisks,
    plannedCount,
    publishedCount
  };
});

// ─── Pattern Generator Modal ───
const showPatternModal = ref(false);
const patternForm = ref({
  pattern_id: '2',
  overwrite_planned: true
});

const handleApplyPattern = () => {
  const chosenPattern = patternTemplates.find(p => String(p.id) === patternForm.value.pattern_id);
  if (!chosenPattern) return;

  let generatedCount = 0;
  scopedStaff.value.forEach(staff => {
    weekDays.value.forEach((day, dayIdx) => {
      const cycleIdx = dayIdx % chosenPattern.cycle_days;
      const targetShiftId = chosenPattern.shifts[cycleIdx];

      const existingIdx = rosterSlots.value.findIndex(s => 
        s.employee_id === staff.id && s.date === day.iso
      );

      if (existingIdx > -1) {
        const existing = rosterSlots.value[existingIdx];
        if (existing.state !== 'planned' || !patternForm.value.overwrite_planned) {
          return;
        }
      }

      const newSlot: ActiveRosterSlot = {
        id: existingIdx > -1 ? rosterSlots.value[existingIdx].id : Date.now() + Math.floor(Math.random() * 100000),
        employee_id: staff.id,
        date: day.iso,
        shift_id: targetShiftId,
        state: 'planned',
        pattern_name: chosenPattern.code
      };

      if (existingIdx > -1) {
        rosterSlots.value[existingIdx] = newSlot;
      } else {
        rosterSlots.value.push(newSlot);
      }
      generatedCount++;
    });
  });

  isDraft.value = true;
  isSaved.value = false;
  showPatternModal.value = false;
  showToast(`Applied ${chosenPattern.code} to ${scopedStaff.value.length} employees (${generatedCount} slots updated).`);
};

// ─── Slot Editor Popover / Modal ───
const showSlotModal = ref(false);
const activeEditingSlot = ref<{
  employee: StaffMember;
  date: string;
  dayName: string;
  shift_id: string;
  state: 'planned' | 'published';
  notes: string;
} | null>(null);

const openSlotEditor = (staff: StaffMember, dateIso: string, dayName: string) => {
  const existing = getSlot(staff.id, dateIso);
  activeEditingSlot.value = {
    employee: staff,
    date: dateIso,
    dayName,
    shift_id: existing ? (existing.shift_id === null ? 'rest' : String(existing.shift_id)) : '2',
    state: existing ? (existing.state === 'published' ? 'published' : 'planned') : 'planned',
    notes: existing?.notes || ''
  };
  showSlotModal.value = true;
};

const handleSaveSlot = () => {
  if (!activeEditingSlot.value) return;

  const { employee, date, shift_id, state, notes } = activeEditingSlot.value;
  const targetShiftId = shift_id === 'rest' ? null : Number(shift_id);

  const existingIdx = rosterSlots.value.findIndex(s => s.employee_id === employee.id && s.date === date);
  const payload: ActiveRosterSlot = {
    id: existingIdx > -1 ? rosterSlots.value[existingIdx].id : Date.now(),
    employee_id: employee.id,
    date,
    shift_id: targetShiftId,
    state,
    notes: notes.trim() || undefined
  };

  if (existingIdx > -1) {
    rosterSlots.value[existingIdx] = payload;
  } else {
    rosterSlots.value.push(payload);
  }

  isDraft.value = true;
  isSaved.value = false;
  showSlotModal.value = false;
  showToast(`Shift updated for ${employee.name}.`);
};

// ─── Header Action Handlers ───
const handleClearPlanned = () => {
  const dates = weekDays.value.map(d => d.iso);
  rosterSlots.value = rosterSlots.value.filter(s => {
    const isTargetWeek = dates.includes(s.date);
    return !(isTargetWeek && s.state === 'planned');
  });
  isSaved.value = false;
  showToast('Cleared all draft/planned shifts for this week.');
};

const handleSaveDraft = () => {
  isDraft.value = true;
  isSaved.value = true;
  showToast('Roster saved as draft.');
};

const handlePublishRoster = () => {
  const dates = weekDays.value.map(d => d.iso);
  let publishedCount = 0;
  rosterSlots.value.forEach(s => {
    if (dates.includes(s.date) && s.state === 'planned') {
      s.state = 'published';
      publishedCount++;
    }
  });

  isDraft.value = false;
  isSaved.value = true;
  showToast(publishedCount > 0 
    ? `Published ${publishedCount} shifts. Roster is now live.` 
    : 'All shifts for this period are already published.'
  );
};
</script>

<template>
  <div class="shift-planner-page">
    <!-- Top Action Bar -->
    <div class="planner-top-bar">
      <div class="top-bar-left">
        <AppBreadcrumb :items="breadcrumbItems">
          <template #badge>
            <SaveStateBadge :is-saved="isSaved" :is-draft="isDraft" />
          </template>
        </AppBreadcrumb>
      </div>

      <div class="top-bar-actions">
        <AppButton
          variant="outline"
          size="sm"
          @click="handleClearPlanned"
        >
          <template #icon-left><RotateCcw :size="13" /></template>
          Clear Draft Shifts
        </AppButton>

        <AppButton
          variant="outline"
          size="sm"
          @click="handleSaveDraft"
        >
          <template #icon-left><Save :size="13" /></template>
          Save Draft
        </AppButton>

        <AppButton
          variant="primary"
          size="sm"
          @click="handlePublishRoster"
        >
          Publish Roster
        </AppButton>
      </div>
    </div>

    <!-- Toast Notification -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <!-- Scope & Parameters Toolbar -->
    <div class="scope-toolbar-card">
      <div class="scope-controls-group">
        <div class="scope-field">
          <FormSelect
            v-model="selectedEntityId"
            label="Facility / Branch"
            :options="entityOptions"
            placeholder="Select Facility"
          />
        </div>

        <div class="scope-field">
          <FormSelect
            v-model="selectedOrgUnitId"
            label="Department"
            :options="orgUnitOptions"
            placeholder="Select Department"
          />
        </div>
      </div>

      <!-- Planning Period Week Navigator -->
      <div class="week-navigator-box">
        <button type="button" class="btn-nav-arrow" @click="handlePrevWeek">
          <ChevronLeft :size="16" />
        </button>

        <div class="week-label-display">
          <span class="week-primary-text">{{ weekLabel }}</span>
          <button type="button" class="btn-this-week" @click="handleThisWeek">This Week</button>
        </div>

        <button type="button" class="btn-nav-arrow" @click="handleNextWeek">
          <ChevronRight :size="16" />
        </button>
      </div>

      <!-- Pattern Auto-Fill Action -->
      <div class="scope-actions-right">
        <button
          type="button"
          class="btn-pattern-generator"
          @click="showPatternModal = true"
        >
          <Wand2 :size="14" />
          <span>Auto-Fill from Pattern</span>
        </button>
      </div>
    </div>

    <!-- Summary Metrics Strip (Rule 2 Standard) -->
    <div class="metrics-strip">
      <div class="metric-block">
        <span class="m-label">Scheduled Staff</span>
        <span class="m-value">{{ stats.headcount }}</span>
        <span class="m-sub">Active in Scope</span>
      </div>
      <div class="metric-divider"></div>

      <div class="metric-block">
        <span class="m-label">Rostered Shifts</span>
        <span class="m-value">{{ stats.scheduledShifts }}</span>
        <span class="m-sub">{{ stats.publishedCount }} Published &bull; {{ stats.plannedCount }} Draft</span>
      </div>
      <div class="metric-divider"></div>

      <div class="metric-block">
        <span class="m-label">Total Planned Hours</span>
        <span class="m-value">{{ stats.totalHours }}h</span>
        <span class="m-sub">Weekly Cumulative</span>
      </div>
      <div class="metric-divider"></div>

      <div class="metric-block" :class="{ 'metric-warn': stats.overtimeRisks > 0 }">
        <span class="m-label">Overtime Risks (&gt;48h)</span>
        <span class="m-value">{{ stats.overtimeRisks }}</span>
        <span class="m-sub">{{ stats.overtimeRisks > 0 ? 'Exceeds statutory cap' : 'Compliant' }}</span>
      </div>
    </div>

    <!-- Interactive Schedule Matrix Grid -->
    <div class="matrix-card">
      <div class="matrix-table-wrapper">
        <table class="roster-matrix-table">
          <thead>
            <tr>
              <th class="th-staff">Staff Member &amp; Role</th>
              <th
                v-for="day in weekDays"
                :key="day.iso"
                class="th-day"
                :class="{ 'th-weekend': day.isWeekend }"
              >
                <div class="day-th-content">
                  <span class="day-name">{{ day.dayName }}</span>
                  <span class="day-date">{{ day.monthShort }} {{ day.dayNum }}</span>
                </div>
              </th>
              <th class="th-weekly-hrs">Total Hours</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="staff in scopedStaff" :key="staff.id">
              <!-- Staff Member Cell -->
              <td class="td-staff">
                <div class="staff-card-cell">
                  <div class="avatar-squircle">{{ staff.avatar_initials }}</div>
                  <div class="staff-details">
                    <span class="staff-name">{{ staff.name }}</span>
                    <span class="staff-role">{{ staff.code }} &bull; {{ staff.role }}</span>
                  </div>
                </div>
              </td>

              <!-- 7 Day Matrix Slots -->
              <td
                v-for="day in weekDays"
                :key="day.iso"
                class="td-slot"
                :class="{ 'td-weekend-slot': day.isWeekend }"
                @click="openSlotEditor(staff, day.iso, day.dayName)"
              >
                <!-- Existing Assigned Slot -->
                <div
                  v-if="getSlot(staff.id, day.iso)"
                  class="slot-chip"
                  :class="[
                    getSlot(staff.id, day.iso)?.shift_id ? shiftCatalog[getSlot(staff.id, day.iso)!.shift_id!].color_class : 'shift-tag-rest',
                    `slot-state-${getSlot(staff.id, day.iso)!.state}`
                  ]"
                >
                  <template v-if="getSlot(staff.id, day.iso)?.shift_id">
                    <div class="chip-top">
                      <span class="chip-code">{{ shiftCatalog[getSlot(staff.id, day.iso)!.shift_id!].code }}</span>
                      <span class="chip-hours">{{ shiftCatalog[getSlot(staff.id, day.iso)!.shift_id!].hours }}h</span>
                    </div>
                    <div class="chip-bottom">
                      <span class="chip-times">
                        {{ shiftCatalog[getSlot(staff.id, day.iso)!.shift_id!].start_time }}–{{ shiftCatalog[getSlot(staff.id, day.iso)!.shift_id!].end_time }}
                      </span>
                      <span v-if="getSlot(staff.id, day.iso)!.state === 'published'" class="state-indicator state-pub">✓</span>
                      <span v-else-if="getSlot(staff.id, day.iso)!.state === 'swapped'" class="state-indicator state-swp">⇄</span>
                      <span v-else class="state-indicator state-dft">•</span>
                    </div>
                  </template>
                  <template v-else>
                    <span class="chip-rest-text">Rest Day</span>
                  </template>
                </div>

                <!-- Empty Unassigned Slot Placeholder -->
                <div v-else class="slot-empty-plus">
                  <span>+</span>
                </div>
              </td>

              <!-- Weekly Hours Total Cell -->
              <td class="td-weekly-hrs">
                <div class="hrs-container">
                  <span class="hrs-val">{{ getStaffWeeklyHours(staff.id) }}h</span>
                  <span
                    v-if="getStaffWeeklyHours(staff.id) > 48.0"
                    class="ot-warning-pill"
                    title="Exceeds standard 48 hours maximum per week"
                  >
                    &gt;48h OT
                  </span>
                </div>
              </td>
            </tr>

            <!-- Empty Staff in Scope -->
            <tr v-if="scopedStaff.length === 0">
              <td colspan="9" class="empty-matrix-row">
                <p>No employees found in the selected facility or department.</p>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Modal: Pattern Auto-Fill Engine -->
    <div v-if="showPatternModal" class="modal-backdrop" @click="showPatternModal = false">
      <div class="modal-box" @click.stop>
        <div class="modal-header">
          <span class="modal-title">Auto-Fill from Shift Pattern</span>
          <button type="button" class="btn-close" @click="showPatternModal = false">
            <X :size="16" />
          </button>
        </div>

        <div class="modal-body-content">
          <p class="modal-explainer">
            Generate rotating schedules for all <strong>{{ scopedStaff.length }}</strong> employees in the selected scope across {{ weekLabel }}.
          </p>

          <FormSelect
            v-model="patternForm.pattern_id"
            label="Shift Pattern Template"
            :options="patternTemplates.map(p => ({ value: String(p.id), label: `${p.code} • ${p.name}` }))"
            required
          />

          <FormCheckbox
            v-model="patternForm.overwrite_planned"
            label="Overwrite Existing Draft Shifts"
            description="Replaces uncommitted draft slots with the new pattern sequence while preserving published shifts."
          />
        </div>

        <div class="modal-footer">
          <AppButton variant="outline" size="sm" @click="showPatternModal = false">Cancel</AppButton>
          <AppButton variant="primary" size="sm" @click="handleApplyPattern">Apply Pattern</AppButton>
        </div>
      </div>
    </div>

    <!-- Modal: Single Slot Quick Edit -->
    <div v-if="showSlotModal && activeEditingSlot" class="modal-backdrop" @click="showSlotModal = false">
      <div class="modal-box" @click.stop>
        <div class="modal-header">
          <span class="modal-title">Edit Shift Slot</span>
          <button type="button" class="btn-close" @click="showSlotModal = false">
            <X :size="16" />
          </button>
        </div>

        <div class="modal-body-content">
          <div class="slot-target-info">
            <div class="sti-row">
              <span class="sti-label">Staff Member:</span>
              <span class="sti-val">{{ activeEditingSlot.employee.name }} ({{ activeEditingSlot.employee.code }})</span>
            </div>
            <div class="sti-row">
              <span class="sti-label">Date:</span>
              <span class="sti-val">{{ activeEditingSlot.dayName }}, {{ activeEditingSlot.date }}</span>
            </div>
          </div>

          <FormSelect
            v-model="activeEditingSlot.shift_id"
            label="Shift Window"
            :options="[
              { value: '1', label: 'Office Day (08:30 – 17:30 • 8.0h)' },
              { value: '2', label: 'Retail Morning (07:00 – 15:00 • 7.5h)' },
              { value: '3', label: 'Retail Evening (14:30 – 22:30 • 7.5h)' },
              { value: '4', label: 'Night Guard (22:00 – 06:00 • 7.25h)' },
              { value: '5', label: 'Shop Split (09:00 – 20:00 • 8.0h)' },
              { value: 'rest', label: 'Rest Day (Off • 0.0h)' }
            ]"
            required
          />

          <FormSelect
            v-model="activeEditingSlot.state"
            label="Lifecycle State"
            :options="[
              { value: 'planned', label: 'Planned (Draft / Unpublished)' },
              { value: 'published', label: 'Published (Active)' }
            ]"
            required
          />

          <FormInput
            v-model="activeEditingSlot.notes"
            label="Operational Notes"
          />
        </div>

        <div class="modal-footer">
          <AppButton variant="outline" size="sm" @click="showSlotModal = false">Cancel</AppButton>
          <AppButton variant="primary" size="sm" @click="handleSaveSlot">Save Slot</AppButton>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.shift-planner-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: var(--alias-color-bg-canvas, #f8fafc);
  min-height: 100vh;
}

/* Top Action Bar */
.planner-top-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.top-bar-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.top-bar-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-top-secondary {
  height: 36px;
  padding: 0 14px;
  display: flex;
  align-items: center;
  gap: 6px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-top-secondary:hover {
  background-color: #f8fafc;
}

.btn-top-primary {
  height: 36px;
  padding: 0 16px;
  display: flex;
  align-items: center;
  gap: 6px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-top-primary:hover {
  background-color: #094380;
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

/* Scope & Parameters Toolbar */
.scope-toolbar-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 20px;
  background-color: #ffffff;
  border: 1px solid #f1f5f9;
  border-radius: 10px;
  gap: 16px;
  flex-wrap: wrap;
}

.scope-controls-group {
  display: flex;
  align-items: center;
  gap: 16px;
}

.scope-field {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.scope-label {
  font-size: 11.5px;
  font-weight: 500;
  color: #737373;
}

.scope-select {
  height: 36px;
  padding: 0 10px;
  font-size: 13px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  color: #404040;
  outline: none;
  cursor: pointer;
}

/* Week Navigator */
.week-navigator-box {
  display: flex;
  align-items: center;
  gap: 10px;
  background-color: #f8fafc;
  padding: 4px 10px;
  border-radius: 8px;
  border: 1px solid #f1f5f9;
}

.btn-nav-arrow {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  color: #64748b;
  cursor: pointer;
}

.btn-nav-arrow:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.week-label-display {
  display: flex;
  align-items: center;
  gap: 8px;
}

.week-primary-text {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.btn-this-week {
  padding: 2px 8px;
  background: transparent;
  border: 1px solid #cbd5e1;
  border-radius: 4px;
  font-size: 11px;
  color: #475569;
  cursor: pointer;
}

.btn-this-week:hover {
  background-color: #ffffff;
}

.btn-pattern-generator {
  height: 36px;
  padding: 0 14px;
  display: flex;
  align-items: center;
  gap: 6px;
  background-color: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 8px;
  color: #1d4ed8;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-pattern-generator:hover {
  background-color: #dbeafe;
}

/* Metrics Strip */
.metrics-strip {
  display: flex;
  align-items: center;
  background-color: #ffffff;
  border: 1px solid #f1f5f9;
  border-radius: 10px;
  padding: 12px 20px;
}

.metric-block {
  display: flex;
  flex-direction: column;
  gap: 1px;
  flex: 1;
}

.m-label {
  font-size: 12px;
  color: #737373;
  font-weight: 500;
}

.m-value {
  font-size: 22px;
  font-weight: 600;
  color: #404040;
}

.m-sub {
  font-size: 11.5px;
  color: #737373;
}

.metric-divider {
  width: 1px;
  height: 40px;
  background-color: #f1f5f9;
  margin: 0 16px;
}

.metric-warn .m-value {
  color: #dc2626;
}

/* Matrix Card */
.matrix-card {
  background-color: #ffffff;
  border: 1px solid #f1f5f9;
  border-radius: 10px;
  overflow: hidden;
}

.matrix-table-wrapper {
  overflow-x: auto;
}

.roster-matrix-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.roster-matrix-table th {
  padding: 10px 12px;
  background-color: #fafafa;
  border-bottom: 1px solid #f1f5f9;
  border-right: 1px solid #f8fafc;
}

.th-staff {
  width: 220px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
}

.th-day {
  min-width: 120px;
}

.day-th-content {
  display: flex;
  flex-direction: column;
  gap: 1px;
  align-items: center;
}

.day-name {
  font-size: 11.5px;
  font-weight: 600;
  color: #404040;
}

.day-date {
  font-size: 11px;
  color: #737373;
}

.th-weekend {
  background-color: #f8fafc;
}

.th-weekly-hrs {
  width: 110px;
  text-align: center;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
}

.roster-matrix-table td {
  padding: 8px 10px;
  border-bottom: 1px solid #f8fafc;
  border-right: 1px solid #f8fafc;
  vertical-align: middle;
}

.td-staff {
  width: 220px;
}

.staff-card-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.avatar-squircle {
  width: 30px;
  height: 30px;
  border-radius: 8px;
  background: linear-gradient(135deg, #e0f2fe, #bae6fd);
  color: #0284c7;
  font-size: 11px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.staff-details {
  display: flex;
  flex-direction: column;
}

.staff-name {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.staff-role {
  font-size: 11px;
  color: #737373;
}

.td-slot {
  cursor: pointer;
  transition: background-color 0.15s;
}

.td-slot:hover {
  background-color: #f1f5f9;
}

.td-weekend-slot {
  background-color: #fafbfc;
}

/* Slot Chip */
.slot-chip {
  border-radius: 6px;
  padding: 4px 6px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  transition: transform 0.1s, box-shadow 0.1s;
}

.slot-chip:hover {
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.chip-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.chip-code {
  font-size: 10.5px;
  font-weight: 700;
  text-transform: uppercase;
}

.chip-hours {
  font-size: 10px;
  opacity: 0.85;
}

.chip-bottom {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.chip-times {
  font-size: 9.5px;
  opacity: 0.85;
}

.state-indicator {
  font-size: 10px;
}

.state-pub { color: #059669; }
.state-swp { color: #7c3aed; }
.state-dft { color: #2563eb; }

/* Tag Colors */
.shift-tag-amber {
  background-color: #fef3c7;
  color: #b45309;
}

.shift-tag-purple {
  background-color: #f3e8ff;
  color: #6b21a8;
}

.shift-tag-blue {
  background-color: #e0f2fe;
  color: #0369a1;
}

.shift-tag-slate {
  background-color: #e2e8f0;
  color: #334155;
}

.shift-tag-emerald {
  background-color: #d1fae5;
  color: #047857;
}

.shift-tag-rest {
  background-color: #f1f5f9;
  color: #64748b;
  padding: 6px 8px;
  text-align: center;
}

.chip-rest-text {
  font-size: 11px;
  font-weight: 500;
}

.slot-empty-plus {
  height: 38px;
  border: 1px dashed #e2e8f0;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #cbd5e1;
  font-size: 16px;
  transition: border-color 0.15s, color 0.15s;
}

.slot-empty-plus:hover {
  border-color: #94a3b8;
  color: #64748b;
}

/* Weekly Hours Total */
.td-weekly-hrs {
  text-align: center;
}

.hrs-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.hrs-val {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.ot-warning-pill {
  font-size: 10px;
  font-weight: 600;
  background-color: #fef2f2;
  color: #dc2626;
  padding: 1px 5px;
  border-radius: 4px;
}

.empty-matrix-row {
  text-align: center;
  padding: 36px 12px;
  color: #737373;
  font-size: 13px;
}

/* Modals */
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

.modal-box {
  width: 100%;
  max-width: 460px;
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

.btn-close {
  background: transparent;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 4px;
  border-radius: 6px;
}

.btn-close:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.modal-body-content {
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.modal-explainer {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
  line-height: 1.5;
}

.slot-target-info {
  background-color: #f8fafc;
  border-radius: 8px;
  padding: 10px 12px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.sti-row {
  display: flex;
  gap: 6px;
  font-size: 12px;
}

.sti-label {
  color: #737373;
}

.sti-val {
  color: #404040;
  font-weight: 600;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  padding: 12px 20px;
  background-color: #f8fafc;
  border-top: 1px solid #f1f5f9;
}

.btn-cancel {
  height: 34px;
  padding: 0 14px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  color: #404040;
  cursor: pointer;
}

.btn-cancel:hover {
  background-color: #f1f5f9;
}

.btn-confirm {
  height: 34px;
  padding: 0 16px;
  background-color: #0B529C;
  border: none;
  border-radius: 8px;
  color: #ffffff;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
}

.btn-confirm:hover {
  background-color: #094380;
}
</style>
