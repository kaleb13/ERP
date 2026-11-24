<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { X } from 'lucide-vue-next';;

import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormRichText from '../../components/FormRichText.vue';
import { useToast } from '../../composables/useToast';

import {
  serviceRequestsData,
  createServiceRequest,
  updateServiceRequest,
  type HRServiceRequestRecord,
  type HRServiceRequestCategory,
  type HRServiceRequestState
} from './hrServiceRequestData';

const router = useRouter();
const route = useRoute();

// ─── EDIT MODE DETECTION ──────────────────────────────────────────────────
const editId = computed(() => {
  if (route.params.id) return Number(route.params.id);
  if (route.query.id) return Number(route.query.id);
  return null;
});

const isEditMode = computed(() => editId.value !== null);

// ─── BREADCRUMBS (Rule 3 & 4: Exact Sidebar Page Name > Sub-page) ─────────
const breadcrumbItems = computed(() => [
  { label: 'HR Service Requests', to: '/hr/service-requests' },
  { label: isEditMode.value ? 'Edit Service Request' : 'Create Service Request' }
]);

// ─── SAVE STATE (Rule 30) ─────────────────────────────────────────────────
const { toast } = useToast();
const isSaved = ref(false);

const showToast = (msg: string) => {
  toast.success(msg);
};

// ─── FORM DATA MODEL (Strict 1:1 Schema Mapping - Intake Facts Only) ─────
const formData = ref<{
  employee_id: number;
  entity_id: number;
  category_lookup_value_id: HRServiceRequestCategory;
  subject: string;
  description: string;
}>({
  employee_id: 22,
  entity_id: 1,
  category_lookup_value_id: 'letter',
  subject: '',
  description: ''
});

// Employee catalog
const employeeOptions = [
  { value: 22, label: 'Hana Mesfin Tadesse (EMP-0022 - Senior Financial Analyst)' },
  { value: 14, label: 'Solomon Bekele Worku (EMP-0014 - Director of HR)' },
  { value: 31, label: 'Helen Berhanu Haile (EMP-0031 - Talent Acquisition Partner)' },
  { value: 44, label: 'Dawit Tadesse Mengistu (EMP-0044 - Lead Internal Auditor)' },
  { value: 15, label: 'Yared Alemu Kassaye (EMP-0015 - Network Infrastructure Lead)' },
  { value: 12, label: 'Abebe Kebede Wolde (EMP-0012 - Head of Retail)' }
];

// Owning Entity options
const entityOptions = [
  { value: 1, label: 'Haleta Corporate Headquarters' },
  { value: 3, label: 'Haleta Addis Ababa Branch' }
];

// Service Category options (Schema enum: HR_SERVICE_REQUEST_CATEGORY)
const categoryOptions = [
  { value: 'letter', label: 'Official Employee Letter (Certificate, Bank Letter)' },
  { value: 'id_card', label: 'Staff ID & RFID Access Badge Replacement' },
  { value: 'payslip_copy', label: 'Certified Payslip Copy Request' },
  { value: 'data_correction', label: 'Profile & Statutory Data Correction' },
  { value: 'benefit_inquiry', label: 'Benefits & Medical Insurance Inquiry' },
  { value: 'general', label: 'General HR Service Inquiry' }
];

// Selected employee helper
const selectedEmployee = computed(() => {
  return employeeOptions.find(e => e.value === formData.value.employee_id);
});

// Pre-fill on mounted (supports route query from QuickCreate modal expand)
onMounted(() => {
  // Check route queries from QuickCreateModal expand
  if (route.query.employee_id) formData.value.employee_id = Number(route.query.employee_id);
  if (route.query.entity_id) formData.value.entity_id = Number(route.query.entity_id);
  if (route.query.category) formData.value.category_lookup_value_id = route.query.category as HRServiceRequestCategory;
  if (route.query.subject) formData.value.subject = String(route.query.subject);
  if (route.query.description) formData.value.description = String(route.query.description);

  // Check edit mode
  if (isEditMode.value && editId.value) {
    const item = serviceRequestsData.value.find(r => r.id === editId.value);
    if (item) {
      formData.value.employee_id = item.employee_id;
      formData.value.entity_id = item.entity_id;
      formData.value.category_lookup_value_id = item.category_lookup_value_id;
      formData.value.subject = item.subject;
      formData.value.description = item.description || '';
      isSaved.value = true;
    }
  }
});

// Clear Form action (Rule 4 & 31)
const handleClearForm = () => {
  formData.value = {
    employee_id: 22,
    entity_id: 1,
    category_lookup_value_id: 'letter',
    subject: '',
    description: ''
  };
  isSaved.value = false;
  showToast('Form cleared.');
};

// Submit Request action (Intake creates in 'open' state with null assignee)
const handleSubmitRequest = () => {
  if (!formData.value.subject.trim()) {
    showToast('Please enter a request subject.');
    return;
  }

  const emp = employeeOptions.find(e => e.value === formData.value.employee_id);
  const empName = emp ? emp.label.split(' (')[0] : 'Employee';
  const empCode = emp ? emp.label.split('(')[1]?.split(' -')[0] || 'EMP-0000' : 'EMP-0000';

  if (isEditMode.value && editId.value) {
    updateServiceRequest(editId.value, {
      employee_id: formData.value.employee_id,
      employee_name: empName,
      employee_code: empCode,
      entity_id: formData.value.entity_id,
      entity_name: formData.value.entity_id === 3 ? 'Haleta Addis Ababa Branch' : 'Haleta Corporate Headquarters',
      category_lookup_value_id: formData.value.category_lookup_value_id,
      subject: formData.value.subject.trim(),
      description: formData.value.description.trim() || null
    });
    isSaved.value = true;
    showToast('Service request updated successfully.');
  } else {
    const newRecord = createServiceRequest({
      employee_id: formData.value.employee_id,
      employee_name: empName,
      employee_code: empCode,
      department: 'Corporate Department',
      position: 'Staff Member',
      tenant_id: 1,
      entity_id: formData.value.entity_id,
      entity_name: formData.value.entity_id === 3 ? 'Haleta Addis Ababa Branch' : 'Haleta Corporate Headquarters',
      category_lookup_value_id: formData.value.category_lookup_value_id,
      subject: formData.value.subject.trim(),
      description: formData.value.description.trim() || null,
      request_state_lookup_value_id: 'open',
      assigned_to_employee_id: null,
      assigned_to_name: null,
      linked_reference: null,
      resolution_note: null,
      resolved_at: null,
      user_id: 7,
      state: 'active'
    });
    isSaved.value = true;
    showToast(`Service request ${newRecord.code} submitted successfully.`);
  }

  setTimeout(() => {
    router.push('/hr/service-requests');
  }, 1000);
};
</script>

<template>
  <div class="service-request-create-page">
    <!-- ─── TOP ACTION BAR (Rule 4) ────────────────────────────────────── -->
    <!-- ─── TOP ACTION BAR (Rule 4 & 29: Zero-background, transparent) ──── -->
    <div class="creation-top-bar">
      <div class="top-bar-left">
        <AppBreadcrumb :items="breadcrumbItems" noMargin>
          <template #badge>
            <SaveStateBadge :isSaved="isSaved" />
          </template>
        </AppBreadcrumb>
      </div>

      <div class="top-bar-actions">
        <!-- Schema has no 'draft' in HR_SERVICE_REQUEST_STATE, so Rule 4 omits 3-dots draft button -->
        <AppButton
          variant="outline"
          size="sm"
          @click="handleClearForm"
        >
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>

        <!-- Primary Save Button (Rule 4, 27: Plain text "Save", ZERO icons) -->
        <AppButton
          variant="primary"
          size="sm"
          @click="handleSubmitRequest"
        >
          Save
        </AppButton>
      </div>
    </div>

    <!-- ─── MASTER CREATION CONTAINER ──────────────────────────────────── -->
    <div class="creation-content-container">
      <!-- Card 1: Requester & Category Identification -->
      <div class="clean-card">
        <h3 class="card-title">Requester & Service Categorization</h3>
        <p class="section-help-text">
          Select the requesting staff member, branch entity, and statutory service category.
        </p>

        <div class="form-grid-3">
          <FormSelect
            v-model="formData.employee_id"
            label="Requester Employee *"
            :options="employeeOptions"
          />
          <FormSelect
            v-model="formData.category_lookup_value_id"
            label="Service Category *"
            :options="categoryOptions"
          />
          <FormSelect
            v-model="formData.entity_id"
            label="Owning Entity *"
            :options="entityOptions"
          />
        </div>
      </div>

      <!-- Card 2: Subject & Detailed Ask Context (WYSIWYG Standard Rules 18 & 25) -->
      <div class="clean-card">
        <h3 class="card-title">Request Subject & Details</h3>
        <p class="section-help-text">
          Provide a concise subject headline followed by detailed operational background and context.
        </p>

        <FormInput
          v-model="formData.subject"
          label="Subject Headline *"
          required
        />

        <FormRichText
          v-model="formData.description"
          label="Detailed Description & Operational Background"
          placeholder="Provide detailed description and operational background for this HR request..."
          :max-length="5000"
        />
      </div>

    </div>
  </div>
</template>

<style scoped>
.service-request-create-page {
  padding: 0;
  background-color: #fafafa;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
}

/* Top bar (AGENTS.md Rule 4 & 29: Zero-background, transparent) */
.creation-top-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}

.top-bar-left {
  display: flex;
  align-items: center;
  gap: 14px;
}

.top-bar-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.btn-clear-form {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 14px;
  background-color: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 8px; /* Rule 6: 8-10px well-rounded rectangle */
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-clear-form:hover {
  background-color: #f5f5f5;
}

.btn-primary-save {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 38px;
  padding: 0 22px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px; /* Rule 6: 8-10px well-rounded rectangle */
  font-size: 13.5px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-primary-save:hover {
  background-color: #09427d;
}

/* ─── STANDARDIZED WYSIWYG RICH TEXT EDITOR (Rules 18 & 25) ──────────────── */
.wysiwyg-box {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.wysiwyg-toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  background-color: #ffffff;
  border-bottom: 1px solid #e2e8f0;
  flex-wrap: wrap;
}

.tb-dropdown-btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #404040;
  padding: 4px 6px;
  border-radius: 4px;
  cursor: pointer;
}

.tb-dropdown-btn:hover {
  background-color: #f5f5f5;
}

.tb-divider {
  width: 1px;
  height: 16px;
  background-color: #e5e5e5;
  margin: 0 4px;
}

.tb-icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  border: none;
  background: transparent;
  color: #737373;
  border-radius: 4px;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.1s;
}

.tb-icon-btn:hover {
  background-color: #f5f5f5;
  color: #404040;
}

.tb-spacer {
  flex: 1;
}

.wysiwyg-textarea {
  width: 100%;
  min-height: 160px;
  padding: 12px 16px;
  border: none;
  outline: none;
  font-size: 13.5px;
  color: #404040;
  line-height: 1.6;
  resize: vertical;
  background-color: #ffffff;
  font-family: inherit;
}

.wysiwyg-textarea:focus {
  background-color: #ffffff;
}

.wysiwyg-footer {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding: 6px 14px;
  background-color: #fafafa;
  border-top: 1px solid #f1f5f9;
}

.char-count-text {
  font-size: 11.5px;
  color: #94a3b8;
}

/* Container */
.creation-content-container {
  max-width: 960px;
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Clean card */
.clean-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
}

.card-title {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: #404040; /* Rule 7 */
}

.section-help-text {
  margin: -10px 0 6px 0;
  font-size: 12px;
  color: #737373;
}

/* Grids */
.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

.form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

.textarea-wrap {
  margin-top: -4px;
}
</style>
