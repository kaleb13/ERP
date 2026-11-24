<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { Save, X, Info } from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import BaseTabs from '../../components/BaseTabs.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import AppButton from '../../components/AppButton.vue';

const router = useRouter();
const route = useRoute();

// ─── Breadcrumbs (Rule 4: [Monitor] > Work Shifts > Create Work Shift) ───
const breadcrumbItems = [
  { label: 'Work Shifts', to: '/hr/shifts' },
  { label: 'Create Work Shift' }
];

// ─── Tabs Configuration ───
const activeTab = ref('details');
const formTabs = [
  { id: 'details', label: 'Shift Details' },
  { id: 'breaks_tolerances', label: 'Breaks & Tolerances' },
  { id: 'night_work', label: 'Night Work Rules' }
];

// ─── Form State ───
const form = ref({
  code: '',
  name_en: '',
  name_am: '',
  category: 'fixed',
  entity_id: '3',
  start_time: '08:30',
  end_time: '17:30',
  is_overnight: false,
  break_minutes: 60,
  grace_in_minutes: 15,
  grace_out_minutes: 10,
  has_night_work: false,
  night_hours_from: '22:00',
  night_hours_to: '06:00',
  description: ''
});

const isSaved = ref(false);
const isSubmitting = ref(false);

// ─── Pre-fill from query (Expand Full Form Flow) ───
onMounted(() => {
  if (route.query.code) form.value.code = String(route.query.code);
  if (route.query.name) form.value.name_en = String(route.query.name);
  if (route.query.category) form.value.category = String(route.query.category);
  if (route.query.start_time) form.value.start_time = String(route.query.start_time);
  if (route.query.end_time) form.value.end_time = String(route.query.end_time);
});

// ─── Computed Duration & Analytics ───
const grossMinutes = computed(() => {
  if (!form.value.start_time || !form.value.end_time) return 0;
  const [sh, sm] = form.value.start_time.split(':').map(Number);
  const [eh, em] = form.value.end_time.split(':').map(Number);
  let startTotal = sh * 60 + sm;
  let endTotal = eh * 60 + em;
  if (form.value.is_overnight || endTotal <= startTotal) {
    endTotal += 24 * 60;
  }
  return endTotal - startTotal;
});

const netMinutes = computed(() => {
  return Math.max(0, grossMinutes.value - (Number(form.value.break_minutes) || 0));
});

function formatDuration(mins: number): string {
  const h = Math.floor(mins / 60);
  const m = mins % 60;
  if (m === 0) return `${h}.00 hrs`;
  return `${h}h ${m}m`;
}

// ─── Form Actions ───
const handleClearForm = () => {
  form.value = {
    code: '',
    name_en: '',
    name_am: '',
    category: 'fixed',
    entity_id: '3',
    start_time: '08:30',
    end_time: '17:30',
    is_overnight: false,
    break_minutes: 60,
    grace_in_minutes: 15,
    grace_out_minutes: 10,
    has_night_work: false,
    night_hours_from: '22:00',
    night_hours_to: '06:00',
    description: ''
  };
};

const handleSave = () => {
  if (!form.value.name_en || !form.value.code) return;
  isSubmitting.value = true;
  setTimeout(() => {
    isSubmitting.value = false;
    isSaved.value = true;
    setTimeout(() => {
      router.push('/hr/shifts');
    }, 800);
  }, 500);
};
</script>

<template>
  <div class="shift-create-page">
    <!-- Top Bar with Breadcrumbs & Actions -->
    <div class="top-nav-bar">
      <div class="left-section">
        <AppBreadcrumb :items="breadcrumbItems">
          <template #badge>
            <SaveStateBadge :is-saved="isSaved" />
          </template>
        </AppBreadcrumb>
      </div>

      <div class="right-actions">
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
          @click="handleSave"
        >
          {{ isSubmitting ? 'Saving...' : 'Save Shift' }}
        </AppButton>
      </div>
    </div>

    <!-- Top Tabs (Capsule/Pill BaseTabs Standard) -->
    <div class="tabs-wrapper">
      <BaseTabs 
        v-model="activeTab" 
        :tabs="formTabs" 
      />
    </div>

    <!-- Main Creation Form Card -->
    <div class="creation-content-container">
      <div class="clean-card">
        <!-- TAB 1: DETAILS -->
        <div v-show="activeTab === 'details'" class="tab-pane">
          <div class="section-header-block">
            <h3 class="section-title">Primary Shift Attributes</h3>
            <p class="section-desc">Configure the labour time classification, scheduled operational hours, and owning organizational entity.</p>
          </div>

          <div class="form-grid-3">
            <FormInput
              v-model="form.name_en"
              label="Shift Name (English)"
              required
            />

            <FormInput
              v-model="form.name_am"
              label="Shift Name (Amharic)"
            />

            <FormInput
              v-model="form.code"
              label="Shift Code"
              required
            />
          </div>

          <div class="form-grid-3 mt-4">
            <FormSelect
              v-model="form.category"
              label="Shift Category"
              placeholder="Select"
              :options="[
                { value: 'fixed', label: 'Fixed (Standard Day Shift)' },
                { value: 'rotating', label: 'Rotating (Morning / Evening Rota)' },
                { value: 'night', label: 'Night (Graveyard Shift)' },
                { value: 'split', label: 'Split Shift (Morning + Evening)' },
                { value: 'flexible', label: 'Flexible Window' }
              ]"
            />

            <FormSelect
              v-model="form.entity_id"
              label="Owning Entity"
              placeholder="Select"
              :options="[
                { value: '3', label: 'Haleta Addis Ababa HQ' },
                { value: '7', label: 'Bole Commercial Branch' },
                { value: '9', label: 'Hawassa Industrial Plant' },
                { value: '12', label: 'Piazza Boutique Store' }
              ]"
            />
          </div>

          <div class="timing-strip-box mt-6">
            <div class="timing-strip-header">
              <h4 class="strip-title">Operating Hours & Schedule Span</h4>
              <div class="duration-live-badge">
                <span>Gross: <strong>{{ formatDuration(grossMinutes) }}</strong></span>
                <span class="divider">·</span>
                <span>Net Work: <strong class="text-blue-600">{{ formatDuration(netMinutes) }}</strong></span>
              </div>
            </div>

            <div class="form-grid-3 mt-3">
              <FormInput
                v-model="form.start_time"
                label="Start Time"
                type="time"
                required
              />

              <FormInput
                v-model="form.end_time"
                label="End Time"
                type="time"
                required
              />

              <div class="checkbox-align-container">
                <FormCheckbox
                  v-model="form.is_overnight"
                  label="Overnight Shift (+1 Day)"
                  description="Check if shift ends on the following calendar day (e.g. 22:00 to 06:00)."
                />
              </div>
            </div>
          </div>

          <div class="mt-6">
            <FormTextarea
              v-model="form.description"
              label="Shift Description & Operational Notes"
              :rows="3"
            />
          </div>
        </div>

        <!-- TAB 2: BREAKS & TOLERANCES -->
        <div v-show="activeTab === 'breaks_tolerances'" class="tab-pane">
          <div class="section-header-block">
            <h3 class="section-title">Break Allowances & Punctuality Tolerances</h3>
            <p class="section-desc">Manage unpaid meal periods, early arrival allowances, and statutory grace margins before attendance flags are triggered.</p>
          </div>

          <div class="form-grid-3">
            <FormInput
              v-model="form.break_minutes"
              label="Unpaid Break Duration (Minutes)"
              type="number"
            />

            <FormInput
              v-model="form.grace_in_minutes"
              label="Grace In Tolerance (Minutes)"
              type="number"
            />

            <FormInput
              v-model="form.grace_out_minutes"
              label="Grace Out Tolerance (Minutes)"
              type="number"
            />
          </div>

          <div class="info-callout-box mt-6">
            <Info :size="16" class="text-blue-600 shrink-0" />
            <div class="callout-text">
              <p class="callout-title">Biometric Machine Synchronization</p>
              <p class="callout-desc">The Grace In threshold allows employees to clock in up to {{ form.grace_in_minutes }} minutes after {{ form.start_time }} without incurring a late attendance penalty deduction in monthly payroll.</p>
            </div>
          </div>
        </div>

        <!-- TAB 3: NIGHT WORK RULES -->
        <div v-show="activeTab === 'night_work'" class="tab-pane">
          <div class="section-header-block">
            <h3 class="section-title">Statutory Night Work Window & Premiums</h3>
            <p class="section-desc">Configure hours subject to Ethiopian labour proclamation night-work premiums (typically 22:00 to 06:00).</p>
          </div>

          <div class="checkbox-row-wrapper">
            <FormCheckbox
              v-model="form.has_night_work"
              label="Enable Night Work Rate Classification"
              description="Designate hours within this shift as night work for statutory overtime calculation."
            />
          </div>

          <div v-if="form.has_night_work" class="form-grid-3 mt-4">
            <FormInput
              v-model="form.night_hours_from"
              label="Night Hours From"
              type="time"
            />

            <FormInput
              v-model="form.night_hours_to"
              label="Night Hours To"
              type="time"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.shift-create-page {
  padding: 0;
  background-color: #fafafa;
  min-height: 100vh;
}

.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1.25rem;
}

.left-section {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.right-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

/* Button Standard: Well-rounded rectangle (8-10px), NEVER pill */
.btn-secondary-action {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  height: 38px;
  padding: 0 1rem;
  background-color: #ffffff;
  color: #404040;
  font-size: 13.5px;
  font-weight: 500;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-secondary-action:hover {
  background-color: #fafafa;
  border-color: #cbd5e1;
}

.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  height: 38px;
  padding: 0 1.25rem;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 13.5px;
  font-weight: 500;
  border-radius: 8px;
  border: none;
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.btn-primary-action:hover {
  background-color: #09427d;
}

.btn-primary-action:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Tabs */
.tabs-wrapper {
  margin-bottom: 1.25rem;
}

/* Main Card */
.creation-content-container {
  max-width: 100%;
}

.clean-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.75rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.section-header-block {
  margin-bottom: 1.5rem;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}

.section-desc {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

/* Grids */
.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

@media (max-width: 900px) {
  .form-grid-3 {
    grid-template-columns: 1fr;
  }
}

.timing-strip-box {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 1.25rem;
}

.timing-strip-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.strip-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.duration-live-badge {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 12.5px;
  color: #737373;
  background: #ffffff;
  padding: 4px 10px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
}

.divider {
  color: #cbd5e1;
}

.checkbox-align-container {
  display: flex;
  align-items: flex-end;
  padding-bottom: 6px;
}

.checkbox-row-wrapper {
  margin-bottom: 1rem;
}

.info-callout-box {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  background: #f0f7ff;
  border: 1px solid #bae6fd;
  border-radius: 8px;
  padding: 1rem;
}

.callout-title {
  font-size: 13px;
  font-weight: 600;
  color: #0369a1;
  margin: 0 0 2px 0;
}

.callout-desc {
  font-size: 12px;
  color: #0284c7;
  margin: 0;
  line-height: 1.45;
}
</style>
