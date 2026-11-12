<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { RotateCcw, Send, CheckCircle2, AlertCircle } from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import AppButton from '../../components/AppButton.vue';
import FormRichText from '../../components/FormRichText.vue';

const router = useRouter();

// ─── Breadcrumbs ───
const breadcrumbItems = [
  { label: 'Shift Swaps', to: '/hr/shift-swaps' },
  { label: 'Create Shift Swaps' }
];

const isSaved = ref(false);
const isSubmitting = ref(false);
const toastMessage = ref<string | null>(null);
const errorMessage = ref<string | null>(null);

// ─── Form Model Aligned with HR_Schema_final-v4.sql lines 1425–1450 ───
const form = ref({
  requester_id: '14',
  requester_shift_id: 'shift-1',
  counterpart_id: '',
  counterpart_shift_id: '',
  reason: '',
});

// ─── Mock Data for Selection ───
interface EmployeeOption {
  id: string;
  name: string;
  role: string;
  avatar: string;
  branch: string;
}

interface ShiftOption {
  id: string;
  employee_id: string;
  date: string;
  shiftName: string;
  shiftTime: string;
  label: string;
}

const employees: EmployeeOption[] = [
  { id: '14', name: 'Abebe Kebede', role: 'Head of Sales & Retail', avatar: 'AK', branch: 'Bole Commercial Branch' },
  { id: '18', name: 'Dawit Yohannes', role: 'Senior Cashier & Merchandiser', avatar: 'DY', branch: 'Bole Commercial Branch' },
  { id: '7',  name: 'Tewodros Kassahun', role: 'Plant Security Officer', avatar: 'TK', branch: 'Bole Commercial Branch' },
  { id: '15', name: 'Sara Tefera', role: 'Retail Shift Supervisor', avatar: 'ST', branch: 'Bole Commercial Branch' },
  { id: '22', name: 'Almaz Ayana', role: 'Chief Executive Officer', avatar: 'AA', branch: 'Executive Office' },
];

const allShifts: ShiftOption[] = [
  { id: 'shift-1', employee_id: '14', date: 'Wed, Jul 29', shiftName: 'Retail Morning', shiftTime: '07:00 – 15:00', label: 'Wed, Jul 29 — Retail Morning (07:00 – 15:00)' },
  { id: 'shift-2', employee_id: '14', date: 'Fri, Jul 31', shiftName: 'Retail Morning', shiftTime: '07:00 – 15:00', label: 'Fri, Jul 31 — Retail Morning (07:00 – 15:00)' },
  { id: 'shift-3', employee_id: '18', date: 'Wed, Jul 29', shiftName: 'Retail Evening', shiftTime: '14:30 – 22:30', label: 'Wed, Jul 29 — Retail Evening (14:30 – 22:30)' },
  { id: 'shift-4', employee_id: '18', date: 'Fri, Jul 31', shiftName: 'Retail Evening', shiftTime: '14:30 – 22:30', label: 'Fri, Jul 31 — Retail Evening (14:30 – 22:30)' },
  { id: 'shift-5', employee_id: '7',  date: 'Thu, Jul 30', shiftName: 'Night Guard', shiftTime: '22:00 – 06:00', label: 'Thu, Jul 30 — Night Guard (22:00 – 06:00)' },
  { id: 'shift-6', employee_id: '15', date: 'Mon, Aug 03', shiftName: 'Supervisor Shift', shiftTime: '08:00 – 17:00', label: 'Mon, Aug 03 — Supervisor Shift (08:00 – 17:00)' },
  { id: 'shift-7', employee_id: '22', date: 'Fri, Jul 31', shiftName: 'Executive Roster', shiftTime: '09:00 – 17:00', label: 'Fri, Jul 31 — Executive Roster (09:00 – 17:00)' },
];

// Available shifts for requester
const availableRequesterShifts = computed(() => {
  return allShifts.filter(s => s.employee_id === form.value.requester_id);
});

// Counterpart colleagues (all employees except selected requester)
const availableCounterparts = computed(() => {
  return employees.filter(e => e.id !== form.value.requester_id);
});

// Available shifts for selected counterpart
const availableCounterpartShifts = computed(() => {
  if (!form.value.counterpart_id) return [];
  return allShifts.filter(s => s.employee_id === form.value.counterpart_id);
});

// When requester changes, auto-select first available shift and reset counterpart if same
const onRequesterChange = () => {
  const reqShifts = availableRequesterShifts.value;
  form.value.requester_shift_id = reqShifts.length > 0 ? reqShifts[0].id : '';
  if (form.value.counterpart_id === form.value.requester_id) {
    form.value.counterpart_id = '';
    form.value.counterpart_shift_id = '';
  }
};

// When counterpart changes, reset counterpart shift
const onCounterpartChange = () => {
  const cShifts = availableCounterpartShifts.value;
  form.value.counterpart_shift_id = cShifts.length > 0 ? cShifts[0].id : '';
};

// ─── Clear Form ───
const handleClearForm = () => {
  form.value = {
    requester_id: '14',
    requester_shift_id: 'shift-1',
    counterpart_id: '',
    counterpart_shift_id: '',
    reason: '',
  };
  errorMessage.value = null;
  toastMessage.value = 'Form cleared.';
  setTimeout(() => { toastMessage.value = null; }, 2500);
};

// ─── Submit Shift Swap Request ───
const handleRequest = () => {
  errorMessage.value = null;

  if (!form.value.requester_id) {
    errorMessage.value = 'Please select a requesting employee.';
    return;
  }

  if (!form.value.requester_shift_id) {
    errorMessage.value = 'Please select the assigned shift slot to give away.';
    return;
  }

  if (form.value.counterpart_id && !form.value.counterpart_shift_id) {
    errorMessage.value = 'Please select the counterpart colleague\'s shift in return, or clear the counterpart to create an Open Giveaway.';
    return;
  }

  isSubmitting.value = true;

  setTimeout(() => {
    isSubmitting.value = false;
    isSaved.value = true;
    toastMessage.value = 'Shift swap request successfully created!';

    setTimeout(() => {
      router.push('/hr/shift-swaps');
    }, 1200);
  }, 600);
};
</script>

<template>
  <div class="shift-swap-create-page">
    <!-- Top Bar with Breadcrumbs & Action Buttons (Figma Node 6328:117787) -->
    <div class="create-header-bar">
      <div class="header-left">
        <AppBreadcrumb :items="breadcrumbItems" noMargin>
          <template #badge>
            <SaveStateBadge :isSaved="isSaved" :isDraft="!isSaved" />
          </template>
        </AppBreadcrumb>
      </div>

      <div class="header-actions">
        <!-- Clear Form Button -->
        <AppButton 
          variant="outline" 
          size="sm"
          @click="handleClearForm"
        >
          <template #icon-left><RotateCcw :size="14" /></template>
          <span>Clear Form</span>
        </AppButton>

        <!-- Request Button (Primary Brand Blue #0B529C) -->
        <AppButton 
          variant="primary" 
          size="sm"
          :disabled="isSubmitting"
          @click="handleRequest"
        >
          <template #icon-left><Send :size="14" /></template>
          <span>{{ isSubmitting ? 'Submitting...' : 'Request' }}</span>
        </AppButton>
      </div>
    </div>

    <!-- Feedback Alerts -->
    <div v-if="toastMessage" class="feedback-toast success">
      <CheckCircle2 :size="16" class="text-emerald-600" />
      <span>{{ toastMessage }}</span>
    </div>

    <div v-if="errorMessage" class="feedback-toast error">
      <AlertCircle :size="16" class="text-red-600" />
      <span>{{ errorMessage }}</span>
    </div>

    <!-- Main Content Container -->
    <div class="create-form-canvas">
      <!-- Card 1: Shift Swap Configuration (Figma Node 6328:117787) -->
      <div class="qmt-form-card">
        <div class="card-section-header">
          <div class="section-title-wrap">
            <h3 class="section-title">Shift Swap Details</h3>
            <p class="section-subtitle">
              Configure peer-to-peer reciprocal exchange or create an open giveaway shift cover.
            </p>
          </div>
        </div>

        <div class="form-grid-layout">
          <!-- Row 1: Requesting Employee & Assigned Shift To Give Away -->
          <div class="form-row">
            <!-- Requesting Employee -->
            <div class="form-field-group">
              <label class="field-label">
                <span>Requesting Employee</span>
                <span class="required-star">*</span>
              </label>
              <div class="select-wrapper">
                <select 
                  v-model="form.requester_id" 
                  class="qmt-native-select"
                  @change="onRequesterChange"
                >
                  <option v-for="emp in employees" :key="emp.id" :value="emp.id">
                    {{ emp.name }} — {{ emp.role }}
                  </option>
                </select>
              </div>
            </div>

            <!-- Assigned Shift To Give Away -->
            <div class="form-field-group">
              <label class="field-label">
                <span>Assigned Shift To Give Away</span>
                <span class="required-star">*</span>
              </label>
              <div class="select-wrapper">
                <select 
                  v-model="form.requester_shift_id" 
                  class="qmt-native-select"
                >
                  <option value="" disabled>Select Shift</option>
                  <option v-for="shift in availableRequesterShifts" :key="shift.id" :value="shift.id">
                    {{ shift.label }}
                  </option>
                </select>
              </div>
            </div>
          </div>

          <!-- Row 2: Counterpart Colleague & Colleague Shift in Return -->
          <div class="form-row">
            <!-- Counterpart Colleague -->
            <div class="form-field-group">
              <label class="field-label">
                <span>Counterpart Colleague</span>
              </label>
              <div class="select-wrapper">
                <select 
                  v-model="form.counterpart_id" 
                  class="qmt-native-select"
                  @change="onCounterpartChange"
                >
                  <option value="">(None — Create Open Giveaway Cover)</option>
                  <option v-for="colleague in availableCounterparts" :key="colleague.id" :value="colleague.id">
                    {{ colleague.name }} — {{ colleague.role }}
                  </option>
                </select>
              </div>
              <p class="field-helper-text">
                If you don't select a counter party the system will create a give away shift swap request and it will be a one way cover open to any colleague.
              </p>
            </div>

            <!-- Colleague Shift in Return -->
            <div class="form-field-group">
              <label class="field-label">
                <span>Colleague Shift in Return</span>
              </label>
              <div class="select-wrapper">
                <select 
                  v-model="form.counterpart_shift_id" 
                  class="qmt-native-select"
                  :disabled="!form.counterpart_id"
                >
                  <option value="">{{ form.counterpart_id ? 'Select Shift' : 'No reciprocal slot required' }}</option>
                  <option v-for="shift in availableCounterpartShifts" :key="shift.id" :value="shift.id">
                    {{ shift.label }}
                  </option>
                </select>
              </div>
              <p v-if="!form.counterpart_id" class="field-helper-text-muted">
                One-way shift cover: recipient earns coverage without sacrificing a scheduled shift slot.
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Card 2: Reason for Swap (Figma Node 6328:118988 / 8779:68714 Rich Text) -->
      <div class="qmt-form-card">
        <div class="card-section-header">
          <div class="section-title-wrap">
            <h3 class="section-title">Reason for swap</h3>
            <p class="section-subtitle">
              Detail the operational justification, personal circumstance, or coverage arrangement for audit tracking.
            </p>
          </div>
        </div>

        <div class="editor-section-body">
          <FormRichText
            v-model="form.reason"
            placeholder="Document the specific justification, agreed reciprocal arrangement, or operational coverage rationale..."
            minHeight="180px"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.shift-swap-create-page {
  display: flex;
  flex-direction: column;
  gap: 24px;
  width: 100%;
  padding-bottom: 60px;
  background-color: var(--alias-color-background-primary, #fafafa);
  min-height: 100vh;
}

/* Header Bar */
.create-header-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 0 4px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

/* Feedback Toast */
.feedback-toast {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  border-radius: var(--alias-radius-lg, 8px);
  font-size: 13px;
  font-weight: 500;
  box-shadow: 0 1px 3px rgba(10, 13, 18, 0.05);
}

.feedback-toast.success {
  background-color: var(--alias-color-background-success-surface, #ecfdf5);
  border: 1px solid var(--alias-color-background-success-subtle, #a4f4cf);
  color: var(--alias-color-success-700, #007a55);
}

.feedback-toast.error {
  background-color: var(--alias-color-background-error-surface, #fef2f2);
  border: 1px solid var(--alias-color-background-error-subtle, #ffc9c9);
  color: var(--primitive-color-red-600, #e7000b);
}

/* Canvas & Cards (Figma: rounded 16px, subtle border #e5e5e5, white surface) */
.create-form-canvas {
  display: flex;
  flex-direction: column;
  gap: 24px;
  width: 100%;
}

.qmt-form-card {
  background-color: var(--alias-color-generic-white, #ffffff);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: var(--alias-radius-2xl, 16px);
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.03);
}

.card-section-header {
  border-bottom: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  padding-bottom: 16px;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  line-height: 24px;
  color: var(--alias-color-text-primary, #262626);
  margin: 0;
}

.section-subtitle {
  font-size: 13px;
  font-weight: 400;
  line-height: 18px;
  color: var(--alias-color-text-tertiary, #737373);
  margin: 4px 0 0 0;
}

/* Form Grid */
.form-grid-layout {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
}

@media (max-width: 768px) {
  .form-row {
    grid-template-columns: 1fr;
  }
}

.form-field-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  width: 100%;
}

.field-label {
  font-size: 13px;
  font-weight: 500;
  line-height: 20px;
  color: var(--alias-color-text-secondary, #404040);
  display: flex;
  align-items: center;
  gap: 2px;
}

.required-star {
  color: var(--primitive-color-red-600, #e7000b);
}

.select-wrapper {
  position: relative;
  width: 100%;
}

.qmt-native-select {
  width: 100%;
  height: 42px;
  padding: 0 14px;
  background-color: var(--alias-color-generic-white, #ffffff);
  border: 1px solid var(--alias-color-border-primary, #d4d4d4);
  border-radius: var(--alias-radius-lg, 8px);
  font-size: 14px;
  color: var(--alias-color-text-primary, #262626);
  outline: none;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
  appearance: auto;
}

.qmt-native-select:focus {
  border-color: var(--alias-color-brand-blue-primary, #0b529c);
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.1);
}

.qmt-native-select:disabled {
  background-color: var(--alias-color-background-secondary, #f5f5f5);
  color: var(--alias-color-text-tertiary, #737373);
  cursor: not-allowed;
  opacity: 0.8;
}

.field-helper-text {
  font-size: 12px;
  line-height: 18px;
  color: var(--alias-color-text-tertiary, #737373);
  margin: 2px 0 0 0;
}

.field-helper-text-muted {
  font-size: 12px;
  line-height: 18px;
  color: var(--alias-color-text-tertiary, #737373);
  font-style: italic;
  margin: 2px 0 0 0;
}

.editor-section-body {
  width: 100%;
}
</style>
