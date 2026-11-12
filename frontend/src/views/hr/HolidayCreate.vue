<script setup lang="ts">
import { ref, onMounted } from 'vue';
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

// ─── Breadcrumbs ───
const breadcrumbItems = [
  { label: 'Holidays', to: '/hr/holidays' },
  { label: 'Create Holiday' }
];

// ─── Tabs ───
const activeTab = ref('details');
const formTabs = [
  { id: 'details', label: 'Holiday Details' },
  { id: 'scope', label: 'Jurisdiction & Overtime Rules' }
];

// ─── Form State ───
const form = ref({
  code: '',
  name_en: '',
  name_am: '',
  holiday_type: 'public',
  date: '2026-09-11',
  is_recurring: true,
  is_recurring_after_days: 365,
  is_paid: true,
  entity_id: '',
  is_regional: false,
  admin_unit: '',
  description: ''
});

const isSaved = ref(false);
const isSubmitting = ref(false);

onMounted(() => {
  if (route.query.code) form.value.code = String(route.query.code);
  if (route.query.name) form.value.name_en = String(route.query.name);
  if (route.query.holiday_type) form.value.holiday_type = String(route.query.holiday_type);
  if (route.query.date) form.value.date = String(route.query.date);
});

const handleClearForm = () => {
  form.value = {
    code: '',
    name_en: '',
    name_am: '',
    holiday_type: 'public',
    date: '2026-09-11',
    is_recurring: true,
    is_recurring_after_days: 365,
    is_paid: true,
    entity_id: '',
    is_regional: false,
    admin_unit: '',
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
      router.push('/hr/holidays');
    }, 800);
  }, 500);
};
</script>

<template>
  <div class="holiday-create-page">
    <!-- Top Nav Bar -->
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
          {{ isSubmitting ? 'Saving...' : 'Save Holiday' }}
        </AppButton>
      </div>
    </div>

    <!-- Tabs -->
    <div class="tabs-wrapper">
      <BaseTabs 
        v-model="activeTab" 
        :tabs="formTabs" 
      />
    </div>

    <!-- Main Card -->
    <div class="creation-content-container">
      <div class="clean-card">
        <!-- TAB 1: DETAILS -->
        <div v-show="activeTab === 'details'" class="tab-pane">
          <div class="section-header-block">
            <h3 class="section-title">Holiday Identification</h3>
            <p class="section-desc">Record official legal title, Amharic localization, date of observance, and statutory classification.</p>
          </div>

          <div class="form-grid-3">
            <FormInput
              v-model="form.name_en"
              label="Holiday Name (English)"
              required
            />

            <FormInput
              v-model="form.name_am"
              label="Holiday Name (Amharic)"
            />

            <FormInput
              v-model="form.code"
              label="Business Code"
              required
            />
          </div>

          <div class="form-grid-3 mt-4">
            <FormInput
              v-model="form.date"
              label="Date of Observance"
              type="date"
              required
            />

            <FormSelect
              v-model="form.holiday_type"
              label="Holiday Classification"
              placeholder="Select"
              :options="[
                { value: 'public', label: 'Public Statutory Holiday' },
                { value: 'religious', label: 'Religious Feast Observance' },
                { value: 'company', label: 'Corporate / Company Holiday' }
              ]"
            />

            <FormSelect
              v-model="form.entity_id"
              label="Owning Tenant / Entity"
              placeholder="Select"
              :options="[
                { value: '', label: 'National (Applies to All Entities)' },
                { value: '1', label: 'Haleta Corporate Group' },
                { value: '3', label: 'Haleta Addis Ababa HQ' },
                { value: '7', label: 'Bole Commercial Branch' },
                { value: '9', label: 'Hawassa Industrial Plant' }
              ]"
            />
          </div>

          <div class="checkboxes-stack mt-6">
            <FormCheckbox
              v-model="form.is_recurring"
              label="Annual Fixed-Date Recurrence"
              description="Check if the holiday recurs every year on this exact calendar date (e.g. Enkutatash, Meskel, Genna)."
            />

            <FormCheckbox
              v-model="form.is_paid"
              label="Paid Statutory Holiday (Drives Public Holiday Overtime Rate)"
              description="Mandatory for statutory public holidays under Ethiopian labour proclamation. Work performed on paid holidays commands a 2.5x overtime multiplier."
            />
          </div>

          <div class="mt-6">
            <FormTextarea
              v-model="form.description"
              label="Holiday Proclamation Notes & Statutory Citations"
              :rows="3"
            />
          </div>
        </div>

        <!-- TAB 2: JURISDICTION -->
        <div v-show="activeTab === 'scope'" class="tab-pane">
          <div class="section-header-block">
            <h3 class="section-title">Regional Jurisdiction & Statutory Scope</h3>
            <p class="section-desc">Designate regional or chartered-city observances that do not apply nationwide across all corporate facilities.</p>
          </div>

          <div class="checkbox-row-box">
            <FormCheckbox
              v-model="form.is_regional"
              label="Regional / State Specific Observance"
              description="Restrict this holiday observance exclusively to facilities and employees located within a designated regional administration (e.g. Irreecha festival in Oromia)."
            />
          </div>

          <div v-if="form.is_regional" class="form-grid-3 mt-4">
            <FormSelect
              v-model="form.admin_unit"
              label="Exact Administrative Jurisdiction"
              placeholder="Select"
              :options="[
                { value: 'oromia', label: 'Oromia Regional State' },
                { value: 'amhara', label: 'Amhara Regional State' },
                { value: 'addis_ababa', label: 'Addis Ababa City Administration' },
                { value: 'sidama', label: 'Sidama Regional State' },
                { value: 'dire_dawa', label: 'Dire Dawa Administration' }
              ]"
            />
          </div>

          <div class="statutory-callout mt-6">
            <Info :size="16" class="text-blue-600 shrink-0" />
            <div class="callout-content">
              <p class="callout-heading">Labour Law Notice (Proclamation No. 1156/2019)</p>
              <p class="callout-body">Employees required to work on a declared statutory public holiday shall be entitled to their regular wage plus remuneration at the rate of two and one-half (2.5) times their ordinary hourly rate for all hours rendered.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.holiday-create-page {
  padding: 0;
  background-color: #f8fafc;
  min-height: 100vh;
}

.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 0;
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
  background-color: #f8fafc;
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

.tabs-wrapper {
  margin-bottom: 1.25rem;
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

.checkboxes-stack {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.checkbox-row-box {
  margin-bottom: 1rem;
}

.statutory-callout {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  background: #f0f7ff;
  border: 1px solid #bae6fd;
  border-radius: 8px;
  padding: 1rem;
}

.callout-heading {
  font-size: 13px;
  font-weight: 600;
  color: #0369a1;
  margin: 0 0 2px 0;
}

.callout-body {
  font-size: 12px;
  color: #0284c7;
  margin: 0;
  line-height: 1.45;
}
</style>
