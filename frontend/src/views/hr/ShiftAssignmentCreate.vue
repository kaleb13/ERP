<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  CalendarRange, Clock, Save, X,
  CheckCircle2, MoreVertical, User, Building2
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';

const router = useRouter();
const route = useRoute();

// ─── Breadcrumbs (Rule 4: [Monitor] > Shift Assignments > Create Shift Assignment) ───
const breadcrumbItems = [
  { label: 'Shift Assignments', to: '/hr/shift-assignments' },
  { label: 'Create Shift Assignment' }
];

// ─── Document Lifecycle State (HR_Schema_final-v4.sql lines 1402–1424) ───
const isSaved = ref(false);
const isDraft = ref(true);
const isSubmitting = ref(false);
const showMoreMenu = ref(false);
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3500);
};

// ─── Tabs Configuration (BaseTabs Capsule Standard) ───
type TabKey = 'details' | 'shift_specs';
const activeTab = ref<TabKey>('details');

const formTabs: BaseTabItem<TabKey>[] = [
  { id: 'details', label: 'Assignment Details', icon: CalendarRange },
  { id: 'shift_specs', label: 'Shift Specification & Timings', icon: Clock }
];

// ─── Master Catalogues conforming strictly to Schema ───
interface EmployeeOption {
  id: number;
  code: string;
  name: string;
  role: string;
  org_unit_name: string;
  entity_id: number;
  entity_name: string;
}

const employeesCatalog: EmployeeOption[] = [
  { id: 14, code: 'EMP-014', name: 'Abebe Kebede', role: 'Head of Retail', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 15, code: 'EMP-015', name: 'Sara Tefera', role: 'Shift Supervisor', org_unit_name: 'Retail Operations', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 18, code: 'EMP-018', name: 'Dawit Yohannes', role: 'Senior Cashier', org_unit_name: 'Customer Cashiers', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 22, code: 'EMP-022', name: 'Bethlehem Haile', role: 'Inventory Controller', org_unit_name: 'Warehouse & Inventory', entity_id: 7, entity_name: 'Bole Commercial Branch' },
  { id: 7,  code: 'EMP-007', name: 'Tewodros Kassahun', role: 'Security Guard', org_unit_name: 'Plant Security', entity_id: 9, entity_name: 'Hawassa Industrial Plant' },
  { id: 8,  code: 'EMP-008', name: 'Mulugeta Belete', role: 'Night Guard Lead', org_unit_name: 'Plant Security', entity_id: 9, entity_name: 'Hawassa Industrial Plant' },
  { id: 9,  code: 'EMP-009', name: 'Almaz Mengistu', role: 'HR Operations Lead', org_unit_name: 'Human Resources', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ' },
  { id: 11, code: 'EMP-011', name: 'Kassahun Bekele', role: 'Facilities Officer', org_unit_name: 'Administration', entity_id: 3, entity_name: 'Haleta Addis Ababa HQ' }
];

const employeeSelectOptions = employeesCatalog.map(e => ({
  value: String(e.id),
  label: `${e.name} (${e.code} • ${e.role})`
}));

const entityOptions = [
  { value: '3', label: 'Haleta Addis Ababa HQ' },
  { value: '7', label: 'Bole Commercial Branch' },
  { value: '9', label: 'Hawassa Industrial Plant' },
  { value: '12', label: 'Piazza Central Branch' }
];

interface ShiftDefinition {
  id: number | null;
  code: string;
  name: string;
  category: string;
  start_time: string;
  end_time: string;
  hours: number;
  break_minutes: number;
  grace_in: number;
  grace_out: number;
  is_overnight: boolean;
  night_hours_from?: string;
  night_hours_to?: string;
}

const shiftsCatalog: Record<string, ShiftDefinition> = {
  'rest': {
    id: null,
    code: 'REST',
    name: 'Rest Day (Off)',
    category: 'Rest',
    start_time: '—',
    end_time: '—',
    hours: 0,
    break_minutes: 0,
    grace_in: 0,
    grace_out: 0,
    is_overnight: false
  },
  '1': {
    id: 1,
    code: 'SH-OFF',
    name: 'Office Day',
    category: 'Fixed',
    start_time: '08:30',
    end_time: '17:30',
    hours: 8.0,
    break_minutes: 60,
    grace_in: 15,
    grace_out: 10,
    is_overnight: false
  },
  '2': {
    id: 2,
    code: 'SH-MORN',
    name: 'Retail Morning',
    category: 'Rotating',
    start_time: '07:00',
    end_time: '15:00',
    hours: 7.5,
    break_minutes: 30,
    grace_in: 10,
    grace_out: 10,
    is_overnight: false
  },
  '3': {
    id: 3,
    code: 'SH-EVE',
    name: 'Retail Evening',
    category: 'Rotating',
    start_time: '14:30',
    end_time: '22:30',
    hours: 7.5,
    break_minutes: 30,
    grace_in: 10,
    grace_out: 10,
    is_overnight: false
  },
  '4': {
    id: 4,
    code: 'SH-NIGHT',
    name: 'Night Guard',
    category: 'Night',
    start_time: '22:00',
    end_time: '06:00',
    hours: 7.25,
    break_minutes: 45,
    grace_in: 15,
    grace_out: 15,
    is_overnight: true,
    night_hours_from: '22:00',
    night_hours_to: '06:00'
  },
  '5': {
    id: 5,
    code: 'SH-SPLIT',
    name: 'Shop Split',
    category: 'Split',
    start_time: '09:00',
    end_time: '20:00',
    hours: 8.0,
    break_minutes: 180,
    grace_in: 10,
    grace_out: 10,
    is_overnight: false
  }
};

const shiftSelectOptions = [
  { value: '1', label: 'Office Day (08:30 – 17:30 • 8.0h)' },
  { value: '2', label: 'Retail Morning (07:00 – 15:00 • 7.5h)' },
  { value: '3', label: 'Retail Evening (14:30 – 22:30 • 7.5h)' },
  { value: '4', label: 'Night Guard (22:00 – 06:00 • 7.25h • Overnight)' },
  { value: '5', label: 'Shop Split (09:00 – 20:00 • 8.0h)' },
  { value: 'rest', label: 'Rest Day (No working hours)' }
];

const patternSelectOptions = [
  { value: '', label: 'None (Ad-Hoc / Standalone Assignment)' },
  { value: '1', label: 'PAT-OFF-5D — Office Mon-Fri (5 Work, 2 Off)' },
  { value: '2', label: 'PAT-RETAIL-6D — Retail 6-Day Rota (6 Work, 1 Off)' },
  { value: '3', label: 'PAT-2M2E2O — Continuous 2 Morn 2 Eve 2 Off' },
  { value: '4', label: 'PAT-GUARD-4C — Guard 4-Day Cycle (2 Night, 2 Off)' }
];

// ─── Form State (HR_Schema_final-v4.sql lines 1402–1415) ───
const form = ref({
  employee_id: '14',
  entity_id: '7',
  date: new Date().toISOString().slice(0, 10),
  shift_id: '2',
  shift_pattern_id: '',
  notes: ''
});

// ─── Pre-fill from route query params (Expand Full Form Flow) ───
onMounted(() => {
  if (route.query.employee_id) form.value.employee_id = String(route.query.employee_id);
  if (route.query.date) form.value.date = String(route.query.date);
  if (route.query.shift_id) form.value.shift_id = String(route.query.shift_id);
  if (route.query.notes) form.value.notes = String(route.query.notes);
  if (route.query.shift_pattern_id) form.value.shift_pattern_id = String(route.query.shift_pattern_id);

  // Sync entity with selected employee
  syncEntityFromEmployee();
});

const syncEntityFromEmployee = () => {
  const emp = employeesCatalog.find(e => String(e.id) === form.value.employee_id);
  if (emp) {
    form.value.entity_id = String(emp.entity_id);
  }
};

const handleEmployeeChange = () => {
  syncEntityFromEmployee();
};

// ─── Selected Data Helpers ───
const selectedEmployee = computed(() => {
  return employeesCatalog.find(e => String(e.id) === form.value.employee_id);
});

const selectedShift = computed<ShiftDefinition>(() => {
  return shiftsCatalog[form.value.shift_id] || shiftsCatalog['1'];
});

// ─── Form Actions ───
const handleClearForm = () => {
  form.value = {
    employee_id: '14',
    entity_id: '7',
    date: new Date().toISOString().slice(0, 10),
    shift_id: '2',
    shift_pattern_id: '',
    notes: ''
  };
  isSaved.value = false;
  isDraft.value = true;
  showToast('Form has been cleared.');
};

const handleSavePlanned = () => {
  isSubmitting.value = true;
  showMoreMenu.value = false;
  setTimeout(() => {
    isSubmitting.value = false;
    isDraft.value = true;
    isSaved.value = true;
    showToast('Shift assignment saved as Planned (Draft).');
    setTimeout(() => {
      router.push('/hr/shift-assignments');
    }, 1000);
  }, 400);
};

const handleSavePublished = () => {
  if (!form.value.employee_id || !form.value.date || !form.value.shift_id) {
    showToast('Please fill all required fields.');
    return;
  }
  isSubmitting.value = true;
  setTimeout(() => {
    isSubmitting.value = false;
    isDraft.value = false;
    isSaved.value = true;
    showToast('Shift assignment published successfully.');
    setTimeout(() => {
      router.push('/hr/shift-assignments');
    }, 1000);
  }, 400);
};
</script>

<template>
  <div class="shift-assignment-create-page" @click="showMoreMenu = false">
    <!-- Top Action Bar -->
    <div class="top-bar-container">
      <div class="top-bar-left">
        <AppBreadcrumb :items="breadcrumbItems">
          <template #badge>
            <SaveStateBadge :is-saved="isSaved" :is-draft="isDraft" />
          </template>
        </AppBreadcrumb>
      </div>

      <div class="top-bar-actions">
        <!-- 3-Dots More Menu (Draft state supported in schema SHIFT_ASSIGNMENT_STATE) -->
        <div class="more-menu-wrapper" @click.stop>
          <AppButton 
            variant="outline" 
            size="sm"
            iconOnly
            @click="showMoreMenu = !showMoreMenu"
            title="More Options"
          >
            <MoreVertical :size="16" />
          </AppButton>
          <div v-if="showMoreMenu" class="more-dropdown-menu">
            <button 
              type="button" 
              class="more-menu-item"
              @click="handleSavePlanned"
            >
              <span>Save as Planned (Draft)</span>
            </button>
          </div>
        </div>

        <AppButton 
          variant="outline" 
          size="sm"
          @click="handleClearForm"
        >
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>

        <AppButton 
          variant="primary" 
          size="sm"
          :disabled="isSubmitting"
          :loading="isSubmitting"
          @click="handleSavePublished"
        >
          Save
        </AppButton>
      </div>
    </div>

    <!-- Notification Toast -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="action-toast">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <!-- Main Form Container -->
    <div class="form-body-wrapper">
      <!-- Top BaseTabs Capsule Standard (Rule 1) -->
      <div class="tabs-header-row">
        <BaseTabs 
          v-model="activeTab" 
          :tabs="formTabs" 
        />
      </div>

      <!-- Tab 1: Assignment Details -->
      <div v-show="activeTab === 'details'" class="tab-pane">
        <div class="master-form-card">
          <div class="card-section-header">
            <div class="section-title-wrap">
              <h2 class="section-title">Roster Slot Information</h2>
              <p class="section-subtitle">
                Assign an employee to a scheduled working shift window or designated rest day for a specific calendar date.
              </p>
            </div>
          </div>

          <div class="form-grid-3col">
            <!-- Employee Selection -->
            <div class="form-field-group">
              <FormSelect
                v-model="form.employee_id"
                label="Employee"
                :options="employeeSelectOptions"
                placeholder="Select"
                required
                @change="handleEmployeeChange"
              />
            </div>

            <!-- Rostered Date -->
            <div class="form-field-group">
              <FormInput
                v-model="form.date"
                label="Rostered Date"
                type="date"
                required
              />
            </div>

            <!-- Shift Window Selection -->
            <div class="form-field-group">
              <FormSelect
                v-model="form.shift_id"
                label="Shift Window"
                :options="shiftSelectOptions"
                placeholder="Select"
                required
              />
            </div>

            <!-- Work Location / Entity -->
            <div class="form-field-group">
              <FormSelect
                v-model="form.entity_id"
                label="Work Location / Branch"
                :options="entityOptions"
                placeholder="Select"
                required
              />
            </div>

            <!-- Shift Pattern Provenance -->
            <div class="form-field-group">
              <FormSelect
                v-model="form.shift_pattern_id"
                label="Shift Pattern Provenance"
                :options="patternSelectOptions"
                placeholder="Select"
                hint="Identifies the generator rota cycle if this slot originates from a repeating pattern."
              />
            </div>
          </div>

          <!-- Selected Employee & Shift Summary Banner -->
          <div v-if="selectedEmployee" class="roster-slot-preview-card">
            <div class="preview-card-item">
              <div class="item-icon-box">
                <User :size="15" />
              </div>
              <div class="item-text-box">
                <span class="item-label">Employee</span>
                <span class="item-val">{{ selectedEmployee.name }} ({{ selectedEmployee.code }})</span>
                <span class="item-sub">{{ selectedEmployee.role }} • {{ selectedEmployee.org_unit_name }}</span>
              </div>
            </div>

            <div class="preview-divider"></div>

            <div class="preview-card-item">
              <div class="item-icon-box">
                <Clock :size="15" />
              </div>
              <div class="item-text-box">
                <span class="item-label">Scheduled Window</span>
                <span class="item-val">{{ selectedShift.name }}</span>
                <span class="item-sub" v-if="selectedShift.id !== null">
                  {{ selectedShift.start_time }} – {{ selectedShift.end_time }} ({{ selectedShift.hours.toFixed(2) }} hrs)
                </span>
                <span class="item-sub" v-else>No daily working hours (Rest Day)</span>
              </div>
            </div>

            <div class="preview-divider"></div>

            <div class="preview-card-item">
              <div class="item-icon-box">
                <Building2 :size="15" />
              </div>
              <div class="item-text-box">
                <span class="item-label">Facility</span>
                <span class="item-val">{{ selectedEmployee.entity_name }}</span>
                <span class="item-sub">Owning Work Location</span>
              </div>
            </div>
          </div>

          <!-- Operational Notes -->
          <div class="form-full-row">
            <FormTextarea
              v-model="form.notes"
              label="Operational Notes"
              :rows="3"
            />
          </div>
        </div>
      </div>

      <!-- Tab 2: Shift Specification & Timings -->
      <div v-show="activeTab === 'shift_specs'" class="tab-pane">
        <div class="master-form-card">
          <div class="card-section-header">
            <div class="section-title-wrap">
              <h2 class="section-title">Shift Timing &amp; Punctuality Tolerances</h2>
              <p class="section-subtitle">
                Operational parameters governing the selected shift window, including break deductions and clock-in grace windows.
              </p>
            </div>
          </div>

          <div class="shift-specs-grid">
            <div class="spec-card">
              <span class="spec-label">Working Window</span>
              <span class="spec-value">{{ selectedShift.start_time }} – {{ selectedShift.end_time }}</span>
              <span class="spec-meta">Category: {{ selectedShift.category }}</span>
            </div>

            <div class="spec-card">
              <span class="spec-label">Standard Labour Hours</span>
              <span class="spec-value">{{ selectedShift.hours.toFixed(2) }} hrs</span>
              <span class="spec-meta">Credited daily duration</span>
            </div>

            <div class="spec-card">
              <span class="spec-label">Unpaid Break Deduction</span>
              <span class="spec-value">{{ selectedShift.break_minutes }} min</span>
              <span class="spec-meta">Auto-deducted from gross time</span>
            </div>

            <div class="spec-card">
              <span class="spec-label">Grace Period (In / Out)</span>
              <span class="spec-value">+{{ selectedShift.grace_in }}m / +{{ selectedShift.grace_out }}m</span>
              <span class="spec-meta">Punctuality leeway window</span>
            </div>

            <div class="spec-card" :class="{ 'highlight-night': selectedShift.is_overnight }">
              <span class="spec-label">Overnight / Night Window</span>
              <span class="spec-value">{{ selectedShift.is_overnight ? 'Yes (Overnight)' : 'Day Shift' }}</span>
              <span class="spec-meta" v-if="selectedShift.is_overnight">Night OT rate applies</span>
              <span class="spec-meta" v-else>Standard daytime rate</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.shift-assignment-create-page {
  padding: 0;
  max-width: 1200px;
  margin: 0 auto;
}

/* ─── Top Bar ─── */
.top-bar-container {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
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

/* ─── More Menu (3-Dots) ─── */
.more-menu-wrapper {
  position: relative;
}

.btn-more-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 38px;
  height: 38px;
  border-radius: 8px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-more-dots:hover {
  background: #f8fafc;
  color: #404040;
  border-color: #cbd5e1;
}

.more-dropdown-menu {
  position: absolute;
  top: 100%;
  left: 0;
  margin-top: 4px;
  min-width: 190px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.08), 0 4px 6px -2px rgba(0, 0, 0, 0.04);
  padding: 4px;
  z-index: 50;
}

.more-menu-item {
  display: flex;
  align-items: center;
  width: 100%;
  padding: 8px 12px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  background: transparent;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  transition: background 0.15s ease;
}

.more-menu-item:hover {
  background: #f1f5f9;
  color: #0B529C;
}

/* ─── Top Bar Buttons ─── */
.btn-clear-form {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 14px;
  border-radius: 8px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  color: #737373;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-clear-form:hover {
  background: #f8fafc;
  color: #404040;
  border-color: #cbd5e1;
}

.btn-save-primary {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 18px;
  border-radius: 8px;
  background: #0B529C;
  border: 1px solid #0B529C;
  color: #ffffff;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(11, 82, 156, 0.12);
  transition: all 0.15s ease;
}

.btn-save-primary:hover:not(:disabled) {
  background: #094482;
  border-color: #094482;
}

.btn-save-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* ─── Toast ─── */
.action-toast {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #ecfdf5;
  border: 1px solid #a7f3d0;
  color: #065f46;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  margin-bottom: 16px;
}

.toast-fade-enter-active,
.toast-fade-leave-active {
  transition: all 0.2s ease;
}

.toast-fade-enter-from,
.toast-fade-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}

/* ─── Tabs Row ─── */
.tabs-header-row {
  margin-bottom: 20px;
}

/* ─── Master Form Card ─── */
.master-form-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}

.card-section-header {
  margin-bottom: 20px;
}

.section-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}

.section-subtitle {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

/* ─── Grids ─── */
.form-grid-3col {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
  margin-bottom: 20px;
}

@media (max-width: 900px) {
  .form-grid-3col {
    grid-template-columns: 1fr;
  }
}

.form-full-row {
  margin-top: 16px;
}

/* ─── Slot Preview Card ─── */
.roster-slot-preview-card {
  display: flex;
  align-items: center;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 20px;
  margin-bottom: 20px;
  gap: 20px;
}

.preview-card-item {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}

.item-icon-box {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  color: #0B529C;
}

.item-text-box {
  display: flex;
  flex-direction: column;
}

.item-label {
  font-size: 11px;
  font-weight: 500;
  color: #737373;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.item-val {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.item-sub {
  font-size: 11.5px;
  color: #737373;
}

.preview-divider {
  width: 1px;
  height: 36px;
  background: #e2e8f0;
}

/* ─── Shift Specs Tab Grid ─── */
.shift-specs-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.spec-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px;
  display: flex;
  flex-direction: column;
}

.spec-label {
  font-size: 11.5px;
  font-weight: 500;
  color: #737373;
  margin-bottom: 6px;
}

.spec-value {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin-bottom: 4px;
}

.spec-meta {
  font-size: 11.5px;
  color: #737373;
}

.highlight-night {
  background: #f1f5f9;
  border-color: #cbd5e1;
}
</style>
