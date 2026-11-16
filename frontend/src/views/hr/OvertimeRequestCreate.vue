<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  X, Save, MoreVertical, Clock,
  FileText
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import { useToast } from '../../composables/useToast';
import { 
  createOvertimeRequest, 
  OVERTIME_TYPE_MAP, 
  type OvertimeType, 
  type OvertimeCompensation,
  type OvertimeRequestState
} from './overtimeData';

const router = useRouter();
const route = useRoute();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3 & 4) ───
const breadcrumbItems = [
  { label: 'Overtime Requests', to: '/hr/overtime-requests' },
  { label: 'Create Overtime Request' }
];

const { toast } = useToast();
const isSaved = ref(false);
const showDraftMenu = ref(false);

const showToast = (msg: string) => {
  toast.success(msg);
};

// ─── Master Form State conforming to Schema Lines 1953–1982 ───
const form = ref({
  employee_id: 14,
  date: '2026-07-29',
  attendance_day_id: null as number | null,
  overtime_type: 'normal_day' as OvertimeType,
  compensation: 'paid' as OvertimeCompensation,
  start_time: '17:30',
  end_time: '19:30',
  requested_minutes: 120,
  reason: ''
});

onMounted(() => {
  if (route.query.employee_id) {
    form.value.employee_id = Number(route.query.employee_id);
  }
  if (route.query.date) {
    form.value.date = String(route.query.date);
  }
  if (route.query.attendance_day_id) {
    form.value.attendance_day_id = Number(route.query.attendance_day_id);
  }
});

// Employee catalogue options
const employeeOptions = [
  { value: 14, label: 'Abebe Kebede (EMP-014) — Senior Accountant • Bole Commercial' },
  { value: 18, label: 'Dawit Yohannes (EMP-018) — Sales Representative • Bole Commercial' },
  { value: 22, label: 'Bethlehem Haile (EMP-022) — Inventory Controller • Bole Commercial' },
  { value: 7,  label: 'Tewodros Kassahun (EMP-007) — Security Guard • Hawassa Plant' },
  { value: 8,  label: 'Mulugeta Belete (EMP-008) — Night Guard Lead • Hawassa Plant' },
  { value: 9,  label: 'Almaz Mengistu (EMP-009) — HR Operations Lead • Addis HQ' },
  { value: 31, label: 'Ephrem Tadesse (EMP-031) — Operations Analyst • Bahir Dar Hub' }
];

// Evidence Attendance Day options (FK AttendanceDay nullable)
const attendanceDayOptions = [
  { value: null, label: 'None (Advance Approval / No Punch Linked)' },
  { value: 810221, label: 'Attendance Day #810221 — 2026-07-29 (Rostered: 08:30 – 17:30)' },
  { value: 810223, label: 'Attendance Day #810223 — 2026-07-27 (Rostered: Night 22:00 – 06:00)' },
  { value: 810225, label: 'Attendance Day #810225 — 2026-07-26 (Weekend Roster)' },
  { value: 810202, label: 'Attendance Day #810202 — 2026-07-20 (Rostered: 08:30 – 17:30)' },
  { value: 810190, label: 'Attendance Day #810190 — 2026-07-13 (Weekend Roster)' }
];

// Overtime type options
const overtimeTypeOptions = [
  { value: 'normal_day', label: 'Normal Working Day (1.25× Base Hourly Rate)' },
  { value: 'night', label: 'Night Shift Work (1.50× Base Hourly Rate)' },
  { value: 'weekend', label: 'Weekly Rest / Weekend Day (2.00× Base Hourly Rate)' },
  { value: 'public_holiday', label: 'Statutory Public Holiday (2.50× Base Hourly Rate)' }
];

// Compensation mode options
const compensationOptions = [
  { value: 'paid', label: 'Monetary Compensation (Disbursed via Payroll Run)' },
  { value: 'compensatory_leave', label: 'Compensatory Leave (Credited to Leave Balance)' }
];

// ─── Reactive Calculation of Hours & Minutes ───
const calculateDuration = () => {
  if (!form.value.start_time || !form.value.end_time) return;
  const [sh, sm] = form.value.start_time.split(':').map(Number);
  const [eh, em] = form.value.end_time.split(':').map(Number);
  let startMinutes = sh * 60 + sm;
  let endMinutes = eh * 60 + em;

  if (endMinutes < startMinutes) {
    // Crosses midnight
    endMinutes += 24 * 60;
  }

  const diff = Math.max(0, endMinutes - startMinutes);
  form.value.requested_minutes = diff;
};

const formattedDurationHours = computed(() => {
  return (form.value.requested_minutes / 60).toFixed(1);
});

const currentRateInfo = computed(() => {
  return OVERTIME_TYPE_MAP[form.value.overtime_type];
});

// ─── Clear Form Action ───
const handleClearForm = () => {
  if (confirm('Are you sure you want to clear this overtime request form?')) {
    form.value = {
      employee_id: 14,
      date: new Date().toISOString().slice(0, 10),
      attendance_day_id: null,
      overtime_type: 'normal_day',
      compensation: 'paid',
      start_time: '17:30',
      end_time: '19:30',
      requested_minutes: 120,
      reason: ''
    };
  }
};

// ─── Save Action (Rule 4 Standard) ───
const executeSave = (state: OvertimeRequestState = 'pending') => {
  if (!form.value.employee_id) {
    alert('Please select an employee.');
    return;
  }
  if (!form.value.date) {
    alert('Please select a work date.');
    return;
  }
  if (form.value.requested_minutes <= 0) {
    alert('Please specify a valid start and end time with positive overtime duration.');
    return;
  }

  const chosenEmp = employeeOptions.find(e => e.value === form.value.employee_id);
  const empParts = chosenEmp?.label.split('—') || [];
  const nameWithCode = empParts[0]?.trim() || 'Abebe Kebede';
  const roleWithBranch = empParts[1]?.trim() || 'Staff';

  const newRecord = createOvertimeRequest({
    employee_id: form.value.employee_id,
    employee_name: nameWithCode.split('(')[0].trim(),
    employee_code: nameWithCode.includes('(') ? nameWithCode.split('(')[1].replace(')', '').trim() : 'EMP-001',
    employee_role: roleWithBranch.split('•')[0].trim(),
    entity_id: 7,
    entity_name: roleWithBranch.split('•')[1]?.trim() || 'Haleta Corporate',
    date: form.value.date,
    attendance_day_id: form.value.attendance_day_id,
    overtime_type: form.value.overtime_type,
    request_state: state,
    start_at: `${form.value.date}T${form.value.start_time}:00Z`,
    end_at: `${form.value.date}T${form.value.end_time}:00Z`,
    requested_minutes: form.value.requested_minutes,
    approved_minutes: state === 'approved' ? form.value.requested_minutes : null,
    compensation: form.value.compensation,
    reason: form.value.reason
  });

  isSaved.value = true;
  showToast(state === 'draft' ? 'Overtime request saved as draft.' : `Overtime request ${newRecord.code} submitted for supervisory approval.`);

  setTimeout(() => {
    router.push('/hr/overtime-requests');
  }, 800);
};
</script>

<template>
  <div class="overtime-create-page">
    <!-- ═══ TOP BAR NAVIGATION (AGENTS.md Rule 4 & Breadcrumb Standard) ═══ -->
    <div class="top-nav-bar">
      <AppBreadcrumb :items="breadcrumbItems">
        <template #badge>
          <SaveStateBadge :isSaved="isSaved" />
        </template>
      </AppBreadcrumb>

      <div class="top-actions-cluster">
        <!-- Dynamic 3-Dots More Menu [ ⋮ ] (Draft Support AGENTS.md Rule 4) -->
        <div class="dropdown-wrap">
          <AppButton
            variant="outline"
            size="sm"
            iconOnly
            @click="showDraftMenu = !showDraftMenu"
            title="More actions"
          >
            <MoreVertical :size="16" />
          </AppButton>
          <div v-if="showDraftMenu" class="dropdown-menu">
            <button type="button" class="dropdown-item" @click="executeSave('draft'); showDraftMenu = false;">
              <FileText :size="14" />
              <span>Save as Draft</span>
            </button>
          </div>
        </div>

        <!-- Clear Form Secondary Button -->
        <AppButton 
          variant="outline" 
          size="sm" 
          @click="handleClearForm"
        >
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>

        <!-- Save Primary Blue Button -->
        <AppButton 
          variant="primary" 
          size="sm" 
          @click="executeSave('pending')"
        >
          Submit for Approval
        </AppButton>
      </div>
    </div>

    <!-- ═══ MASTER CREATION CARD ═══ -->
    <div class="clean-card">
      <div class="card-header-bar">
        <div class="header-titles">
          <h2 class="card-title">Overtime Request Details</h2>
          <p class="card-subtitle">
            Log extra hours performed outside scheduled rosters in adherence to statutory Ethiopian labor proclamations.
          </p>
        </div>
      </div>

      <!-- Statutory Multiplier Information Banner -->
      <div class="statutory-rate-banner">
        <div class="rate-badge">
          <span class="rate-val">{{ currentRateInfo.multiplier }}×</span>
          <span class="rate-unit">Multiplier</span>
        </div>
        <div class="rate-details">
          <h4 class="rate-title">{{ currentRateInfo.label }}</h4>
          <p class="rate-desc">{{ currentRateInfo.description }}</p>
        </div>
      </div>

      <!-- Main Form Grid (3 Columns Responsive) -->
      <div class="form-grid-3col">
        <!-- Employee Selector -->
        <div class="form-group col-span-2">
          <label class="form-label required">Employee</label>
          <FormSelect
            v-model="form.employee_id"
            :options="employeeOptions"
            placeholder="Select"
            required
          />
        </div>

        <!-- Work Date -->
        <div class="form-group">
          <label class="form-label required">Work Date</label>
          <FormInput
            type="date"
            v-model="form.date"
            required
          />
        </div>

        <!-- Overtime Type (Schema line 1962: overtime_type_lookup_value_id) -->
        <div class="form-group col-span-2">
          <label class="form-label required">Overtime Type</label>
          <FormSelect
            v-model="form.overtime_type"
            :options="overtimeTypeOptions"
            placeholder="Select"
            required
          />
        </div>

        <!-- Compensation Method (Schema line 1968: compensation_lookup_value_id) -->
        <div class="form-group">
          <label class="form-label required">Compensation Method</label>
          <FormSelect
            v-model="form.compensation"
            :options="compensationOptions"
            placeholder="Select"
            required
          />
        </div>

        <!-- Start Time -->
        <div class="form-group">
          <label class="form-label required">Start Time</label>
          <FormInput
            type="time"
            v-model="form.start_time"
            @change="calculateDuration"
            required
          />
        </div>

        <!-- End Time -->
        <div class="form-group">
          <label class="form-label required">End Time</label>
          <FormInput
            type="time"
            v-model="form.end_time"
            @change="calculateDuration"
            required
          />
        </div>

        <!-- Computed Duration (Readonly / Calculated) -->
        <div class="form-group">
          <label class="form-label">Computed Extra Duration</label>
          <div class="duration-display-field">
            <Clock :size="16" class="duration-icon" />
            <span class="duration-val">{{ formattedDurationHours }} hrs</span>
            <span class="duration-sub">({{ form.requested_minutes }} minutes)</span>
          </div>
        </div>

        <!-- Evidence Attendance Day (FK AttendanceDay nullable, Schema line 1961) -->
        <div class="form-group col-span-3">
          <label class="form-label">Evidence Attendance Day</label>
          <FormSelect
            v-model="form.attendance_day_id"
            :options="attendanceDayOptions"
            placeholder="Select"
          />
        </div>

        <!-- Operational Reason (Schema line 1969: reason) -->
        <div class="form-group col-span-3">
          <label class="form-label required">Operational Reason</label>
          <FormTextarea
            v-model="form.reason"
            :rows="3"
            hint="Describe the operational urgency or task (e.g. inventory audit, month-end closing, emergency repairs)."
            required
          />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.overtime-create-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: var(--alias-color-bg-canvas, #f8fafc);
  min-height: 100vh;
}

/* ─── Top Bar Navigation (Rule 4 Standard) ─── */
.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.top-actions-cluster {
  display: flex;
  align-items: center;
  gap: 10px;
}



.pill-not-saved {
  background-color: #fef3c7;
  color: #b45309;
}

.pill-saved {
  background-color: #ecfdf5;
  color: #059669;
}

/* 3-Dots Dropdown */
.dropdown-wrap {
  position: relative;
}

.btn-icon-more {
  width: 38px;
  height: 38px;
  border-radius: 8px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  color: #737373;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.btn-icon-more:hover {
  background-color: #f8fafc;
  color: #404040;
}

.dropdown-menu {
  position: absolute;
  top: 44px;
  left: 0;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  min-width: 160px;
  padding: 4px;
  z-index: 100;
}

.dropdown-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  font-size: 13px;
  color: #404040;
  background: transparent;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
}

.dropdown-item:hover {
  background-color: #f1f5f9;
}

.btn-secondary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  color: #404040;
  padding: 0 14px;
  height: 38px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-secondary-action:hover {
  background-color: #f8fafc;
}

.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: var(--alias-color-brand-primary, #0B529C);
  color: #ffffff;
  padding: 0 16px;
  height: 38px;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  border: none;
  cursor: pointer;
}

.btn-primary-action:hover {
  background-color: #09427d;
}

/* ─── Card Architecture ─── */
.clean-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 24px;
}

.card-header-bar {
  margin-bottom: 20px;
}

.card-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.card-subtitle {
  font-size: 12.5px;
  color: #737373;
  margin: 4px 0 0 0;
}

/* Statutory Rate Banner */
.statutory-rate-banner {
  display: flex;
  align-items: center;
  gap: 16px;
  background: #f0f9ff;
  border: 1px solid #bae6fd;
  border-radius: 8px;
  padding: 12px 16px;
  margin-bottom: 24px;
}

.rate-badge {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: #0B529C;
  color: #ffffff;
  padding: 6px 14px;
  border-radius: 6px;
  min-width: 70px;
}

.rate-val {
  font-size: 18px;
  font-weight: 700;
  line-height: 1;
}

.rate-unit {
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.rate-details {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.rate-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #0369a1;
  margin: 0;
}

.rate-desc {
  font-size: 12px;
  color: #0c4a6e;
  margin: 0;
}

/* Form Grid */
.form-grid-3col {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

@media (max-width: 900px) {
  .form-grid-3col {
    grid-template-columns: 1fr;
  }
  .col-span-2, .col-span-3 {
    grid-column: span 1 !important;
  }
}

.col-span-2 {
  grid-column: span 2;
}

.col-span-3 {
  grid-column: span 3;
}

.form-group {
  display: flex;
  flex-direction: column;
}

.form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 4px;
}

.form-label.required::after {
  content: " *";
  color: #ef4444;
}

.duration-display-field {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 38px;
  padding: 0 12px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}

.duration-icon {
  color: #0B529C;
}

.duration-val {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.duration-sub {
  font-size: 11.5px;
  color: #737373;
}
</style>
