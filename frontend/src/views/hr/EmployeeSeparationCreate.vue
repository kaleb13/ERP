<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { Calendar, MoreVertical, X } from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import BaseTabs from '../../components/BaseTabs.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormInput from '../../components/FormInput.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormRichText from '../../components/FormRichText.vue';
import { 
  addSeparationRecord, 
  type SeparationType, 
  type SeparationStatus 
} from './separationData';

const router = useRouter();
const route = useRoute();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3 & 4) ───
// [Monitor] > Employee Separations > Create Employee Separation
const breadcrumbItems = [
  { label: 'Employee Separations', to: '/hr/separations' },
  { label: 'Create Employee Separation' }
];

// ─── Status / Save State Standard (AGENTS.md Rule 30) ───
const isSaved = ref(false);
const isDraft = ref(false);
const showDraftMenu = ref(false);
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Top Level Tabs Standard (AGENTS.md Rule 1: BaseTabs) ───
const activeTab = ref('details');
const formTabs = [
  { id: 'details', label: 'Separation Details' },
  { id: 'governance', label: 'Exit Interview & Rehire' }
];

// ─── Form Model (100% Schema Mapped) ───
const formData = ref({
  employee_id: '',
  separation_type: 'resignation' as SeparationType,
  notice_date: new Date().toISOString().substring(0, 10),
  last_working_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().substring(0, 10),
  reason: '',
  disciplinary_action_id: null as number | null,
  disciplinary_reference: '',
  is_rehire_eligible: true,
  exit_interview_note: ''
});

// Pre-fill from route query if expanded from QuickCreateModal
onMounted(() => {
  if (route.query.employee_id) formData.value.employee_id = String(route.query.employee_id);
  if (route.query.separation_type) formData.value.separation_type = route.query.separation_type as SeparationType;
  if (route.query.notice_date) formData.value.notice_date = String(route.query.notice_date);
  if (route.query.last_working_date) formData.value.last_working_date = String(route.query.last_working_date);
  if (route.query.is_rehire_eligible) formData.value.is_rehire_eligible = route.query.is_rehire_eligible === 'true';
});

const employeeOptions = [
  { value: '18', label: 'Kidst Tesfaye (EMP-0018) • Plant Operations & Security' },
  { value: '19', label: 'Binyam Getachew (EMP-0019) • Finance & Accounting' },
  { value: '20', label: 'Tigist Alemu (EMP-0020) • Human Resources' },
  { value: '21', label: 'Kassahun Bekele (EMP-0021) • Operations & Logistics' },
  { value: '15', label: 'Marta Tadesse (EMP-0015) • Information Technology' },
  { value: '14', label: 'Abebe Kebede (EMP-0014) • Procurement & Stores' },
  { value: '22', label: 'Hana Mesfin (EMP-0022) • Finance & Accounting' }
];

const separationTypeOptions = [
  { value: 'resignation', label: 'Resignation' },
  { value: 'termination', label: 'Termination' },
  { value: 'end_of_contract', label: 'End of Contract' },
  { value: 'retirement', label: 'Retirement' },
  { value: 'redundancy', label: 'Redundancy' },
  { value: 'mutual_agreement', label: 'Mutual Agreement' },
  { value: 'death', label: 'Death in Service' }
];

const handleClearForm = () => {
  formData.value = {
    employee_id: '',
    separation_type: 'resignation',
    notice_date: new Date().toISOString().substring(0, 10),
    last_working_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().substring(0, 10),
    reason: '',
    disciplinary_action_id: null,
    disciplinary_reference: '',
    is_rehire_eligible: true,
    exit_interview_note: ''
  };
  reasonCharCount.value = 0;
  interviewCharCount.value = 0;
  isSaved.value = false;
  isDraft.value = false;
  showToast('Form cleared.');
};

const handleSaveAsDraft = () => {
  if (!formData.value.employee_id) {
    showToast('Please select an employee.');
    return;
  }
  saveRecord('draft');
};

const handleSave = () => {
  if (!formData.value.employee_id) {
    showToast('Please select an employee.');
    return;
  }
  saveRecord('pending');
};

const saveRecord = (status: SeparationStatus) => {
  const selectedEmp = employeeOptions.find(e => e.value === formData.value.employee_id);
  const nameParts = selectedEmp?.label.split(' • ') || ['Unknown Employee', 'General Operations'];
  const nameCode = nameParts[0].split(' (');
  const empName = nameCode[0];
  const empCode = nameCode[1] ? nameCode[1].replace(')', '') : 'EMP-0000';

  const newRec = addSeparationRecord({
    employee_id: parseInt(formData.value.employee_id, 10),
    employee_name: empName,
    employee_code: empCode,
    employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    department: nameParts[1] || 'Operations',
    position: nameParts[1] || 'Staff Member',
    separation_type: formData.value.separation_type,
    separation_state: status,
    notice_date: formData.value.notice_date,
    last_working_date: formData.value.last_working_date,
    reason: formData.value.reason || 'Standard notice submitted.',
    disciplinary_action_id: formData.value.disciplinary_action_id,
    disciplinary_reference: formData.value.disciplinary_reference || null,
    is_rehire_eligible: formData.value.is_rehire_eligible,
    exit_interview_note: formData.value.exit_interview_note || null,
    approved_by_employee_id: null,
    approved_by_name: null,
    approved_at: null
  });

  isSaved.value = true;
  isDraft.value = status === 'draft';
  showDraftMenu.value = false;
  showToast(`Separation ${newRec.code} ${status === 'draft' ? 'saved as draft' : 'submitted successfully'}.`);

  setTimeout(() => {
    router.push('/hr/separations');
  }, 1200);
};
</script>

<template>
  <div class="create-page-container">
    <!-- Top Action Bar (AGENTS.md Rule 29: Zero-background, transparent) -->
    <div class="top-nav-bar">
      <div class="top-nav-left">
        <AppBreadcrumb :items="breadcrumbItems" noMargin>
          <template #badge>
            <SaveStateBadge :isSaved="isSaved" :isDraft="isDraft" />
          </template>
        </AppBreadcrumb>
      </div>

      <div class="top-nav-right">
        <!-- Dynamic 3-Dots More Menu strictly for entities with 'draft' state (AGENTS.md Rule 4 & 59) -->
        <div class="draft-menu-container">
          <AppButton 
            variant="outline" 
            size="sm" 
            iconOnly
            title="Additional Actions"
            @click="showDraftMenu = !showDraftMenu"
          >
            <MoreVertical :size="16" />
          </AppButton>
          <div v-if="showDraftMenu" class="draft-dropdown-menu">
            <button type="button" class="dropdown-item" @click="handleSaveAsDraft">
              Save as Draft
            </button>
          </div>
        </div>

        <!-- Secondary Clear Form Button (AGENTS.md Rule 31) -->
        <AppButton 
          variant="outline" 
          size="sm" 
          @click="handleClearForm"
        >
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>

        <!-- Primary Save Button: Plain Text "Save", ZERO Icons (AGENTS.md Rule 27 & 31) -->
        <AppButton 
          variant="primary" 
          size="sm" 
          @click="handleSave"
        >
          Save
        </AppButton>
      </div>
    </div>

    <!-- Capsule Tabs across top (AGENTS.md Rule 1: BaseTabs) -->
    <div class="tabs-header-wrapper">
      <BaseTabs 
        v-model="activeTab" 
        :tabs="formTabs" 
      />
    </div>

    <!-- Master Creation Card (AGENTS.md Rule 15 & 32) -->
    <div class="master-form-card">
      
      <!-- TAB 1: Separation Logistics & Details -->
      <div v-if="activeTab === 'details'" class="form-tab-content">
        <!-- Section Riser 1 (AGENTS.md Rule 32) -->
        <div class="form-section-riser">
          <span class="riser-title">Employee & Exit Mode</span>
          <div class="riser-line"></div>
        </div>

        <div class="form-grid-3col">
          <FormSelect
            v-model="formData.employee_id"
            label="Employee"
            :options="employeeOptions"
            placeholder="Select"
            required
          />

          <FormSelect
            v-model="formData.separation_type"
            label="Separation Type"
            :options="separationTypeOptions"
            placeholder="Select"
            required
          />

          <FormInput
            v-if="formData.separation_type === 'termination'"
            v-model="formData.disciplinary_reference"
            label="Disciplinary Case Ref"
            hint="Associated disciplinary case document if exit is cause-based."
          />
        </div>

        <!-- Section Riser 2: Notice & Working Dates -->
        <div class="form-section-riser">
          <span class="riser-title">Statutory Notice & Effective Dates</span>
          <div class="riser-line"></div>
        </div>

        <div class="form-grid-2col">
          <div class="date-field-group">
            <label class="compact-field-label">Notice Date</label>
            <div class="calendar-input-wrapper">
              <Calendar :size="15" class="cal-left-icon" />
              <input 
                v-model="formData.notice_date" 
                type="date" 
                class="cal-input" 
                required
              />
              <span class="gc-pill-tag">GC</span>
            </div>
          </div>

          <div class="date-field-group">
            <label class="compact-field-label">Last Working Date</label>
            <div class="calendar-input-wrapper">
              <Calendar :size="15" class="cal-left-icon" />
              <input 
                v-model="formData.last_working_date" 
                type="date" 
                class="cal-input" 
                required
              />
              <span class="gc-pill-tag">GC</span>
            </div>
          </div>
        </div>

        <!-- Section Riser 3: Formal Reason & Notice Letter (AGENTS.md Rule 18 & 25) -->
        <div class="form-section-riser">
          <span class="riser-title">Resignation Notice & Formal Reason</span>
          <div class="riser-line"></div>
        </div>

        <FormRichText
          v-model="formData.reason"
          placeholder="Enter resignation notice or formal separation reason..."
          :max-length="5000"
        />
      </div>

      <!-- TAB 2: Exit Interview & Governance -->
      <div v-if="activeTab === 'governance'" class="form-tab-content">
        <div class="form-section-riser">
          <span class="riser-title">Rehire Eligibility & Future Consideration</span>
          <div class="riser-line"></div>
        </div>

        <FormCheckbox
          v-model="formData.is_rehire_eligible"
          label="Eligible for Rehire"
          description="Enables future application consideration. When unchecked, applicant screening will flag prior exit restriction in recruitment pipelines."
        />

        <div class="form-section-riser" style="margin-top: 24px;">
          <span class="riser-title">Exit Interview Documentation & Feedback</span>
          <div class="riser-line"></div>
        </div>

        <FormRichText
          v-model="formData.exit_interview_note"
          placeholder="Document employee exit interview responses and retention insights..."
          :max-length="5000"
        />
      </div>
    </div>

    <!-- Toast Notification -->
    <div v-if="toastMessage" class="toast-popup">
      {{ toastMessage }}
    </div>
  </div>
</template>

<style scoped>
.create-page-container {
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  background-color: var(--primitive-color-neutral-50, #f8fafc);
  min-height: 100vh;
}

/* ─── Top Navigation Bar (AGENTS.md Rule 29: Transparent, No Card) ─── */
.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: transparent;
  border: none;
  box-shadow: none;
  padding: 0;
}

.top-nav-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.top-nav-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.draft-menu-container {
  position: relative;
}

.btn-icon-more {
  width: 38px;
  height: 38px;
  border-radius: 8px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  color: #737373;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.btn-icon-more:hover {
  color: #0b529c;
  border-color: #0b529c;
}

.draft-dropdown-menu {
  position: absolute;
  top: 44px;
  left: 0;
  background-color: #ffffff;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  padding: 4px;
  z-index: 100;
  width: 140px;
}

.dropdown-item {
  width: 100%;
  padding: 8px 12px;
  background: none;
  border: none;
  font-size: 13px;
  text-align: left;
  color: #404040;
  cursor: pointer;
  border-radius: 6px;
}

.dropdown-item:hover {
  background-color: #f1f5f9;
  color: #0b529c;
}

.btn-secondary-clear {
  height: 38px;
  padding: 0 16px;
  border-radius: 8px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  color: #404040;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-secondary-clear:hover {
  border-color: #ef4444;
  color: #ef4444;
}

.btn-primary-save {
  height: 38px;
  padding: 0 22px;
  border-radius: 8px;
  background-color: #0b529c;
  color: #ffffff;
  font-size: 13.5px;
  font-weight: 500;
  border: none;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-primary-save:hover {
  background-color: #083e76;
}

.tabs-header-wrapper {
  margin-top: -4px;
}

/* ─── Master Form Card (AGENTS.md Rule 15) ─── */
.master-form-card {
  background-color: #ffffff;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  padding: 24px 28px;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.04);
}

.form-tab-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* ─── Section Risers (AGENTS.md Rule 32) ─── */
.form-section-riser {
  display: flex;
  align-items: center;
  gap: 14px;
  margin-top: 6px;
}

.riser-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
  white-space: nowrap;
}

.riser-line {
  height: 1px;
  background-color: #f1f5f9;
  width: 100%;
}

.form-grid-3col {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

.form-grid-2col {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

/* ─── Calendar Inputs (AGENTS.md Rule 17 & 23) ─── */
.date-field-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.compact-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.calendar-input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
}

.cal-left-icon {
  position: absolute;
  left: 10px;
  color: #94a3b8;
  pointer-events: none;
}

.cal-input {
  width: 100%;
  height: 38px;
  padding: 0 42px 0 34px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
}

.cal-input:focus {
  border-color: #0b529c;
  outline: none;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.cal-input::-webkit-calendar-picker-indicator {
  opacity: 0;
  width: 100%;
  height: 100%;
  position: absolute;
  left: 0;
  top: 0;
  cursor: pointer;
}

.gc-pill-tag {
  position: absolute;
  right: 8px;
  padding: 2px 6px;
  background-color: #f1f5f9;
  color: #64748b;
  font-size: 10.5px;
  font-weight: 600;
  border-radius: 4px;
  pointer-events: none;
}

/* ─── Rich Text Editor (AGENTS.md Rule 18 & 25) ─── */
.rich-editor-container {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  background-color: #ffffff;
}

.rich-editor-toolbar {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  background-color: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}

.toolbar-pill {
  font-size: 12px;
  color: #64748b;
  padding: 2px 8px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  cursor: pointer;
}

.toolbar-separator {
  width: 1px;
  height: 16px;
  background-color: #cbd5e1;
  margin: 0 4px;
}

.btn-tool-icon {
  background: none;
  border: none;
  color: #64748b;
  padding: 4px;
  border-radius: 4px;
  cursor: pointer;
}

.btn-tool-icon:hover {
  background-color: #e2e8f0;
  color: #0f172a;
}

.rich-editor-content {
  min-height: 120px;
  padding: 12px 14px;
  font-size: 13.5px;
  color: #404040;
  outline: none;
  line-height: 1.5;
}

.rich-editor-content:empty:before {
  content: 'Type explanation or notes...';
  color: #94a3b8;
}

.rich-editor-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 6px 12px;
  background-color: #fafafa;
  border-top: 1px solid #f1f5f9;
}

.char-counter {
  font-size: 11px;
  color: #737373;
}

.resize-handle {
  font-size: 11px;
  color: #cbd5e1;
  user-select: none;
}

.toast-popup {
  position: fixed;
  bottom: 24px;
  right: 24px;
  background-color: #1e293b;
  color: #ffffff;
  padding: 10px 18px;
  border-radius: 8px;
  font-size: 13px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  z-index: 2000;
}
</style>
