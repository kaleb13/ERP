<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useRouter } from 'vue-router';
import {
  MoreVertical, X, Calendar, User,
  Info, ChevronDown, ChevronUp, Save
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseDropdownMenu, { type DropdownMenuItem } from '../../components/BaseDropdownMenu.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import FormInput from '../../components/FormInput.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormCheckboxCard from '../../components/FormCheckboxCard.vue';
import FormRichText from '../../components/FormRichText.vue';
import { useToast } from '../../composables/useToast';

const router = useRouter();
const { toast } = useToast();

// ─── Breadcrumb (Image 1 & 2: "[Monitor] > Employee Movement > Create Movement") ───
const breadcrumbItems = [
  { label: 'Employee Movement', to: '/hr/movements' },
  { label: 'Create Movement' }
];

// ─── Action Menu State ───
const showMoreDropdown = ref(false);
const isDescriptionOpen = ref(true);

// ─── Employees Directory Dataset (Matching Image 1 & 2) ───
export interface EmployeeProfileItem {
  id: number;
  name: string;
  code: string;
  role: string;
  salary: number;
  works_at: string;
  avatar: string;
  entity_id: string;
  position_id: string;
}

const employees: EmployeeProfileItem[] = [
  {
    id: 124,
    name: 'Almaz Kebede',
    code: 'EMP-00124',
    role: 'Senior Accountant',
    salary: 7150,
    works_at: 'Bole Branch - Finance Department',
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    entity_id: 'bole_branch',
    position_id: 'senior_accountant'
  },
  {
    id: 12,
    name: 'Abebe Kebede',
    code: 'EMP-0012',
    role: 'Inventory Controller',
    salary: 6500,
    works_at: 'Bole Branch - Retail Operations',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    entity_id: 'bole_branch',
    position_id: 'inventory_controller'
  },
  {
    id: 18,
    name: 'Kidst Tesfaye',
    code: 'EMP-0018',
    role: 'HQ Security Guard',
    salary: 5800,
    works_at: 'Haleta HQ - Administration',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    entity_id: 'haleta_hq',
    position_id: 'security_guard'
  },
  {
    id: 812,
    name: 'Mihret Abera',
    code: 'EMP-0812',
    role: 'Inventory Controller',
    salary: 6500,
    works_at: 'Hawassa Plant - Logistics',
    avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
    entity_id: 'hawassa_plant',
    position_id: 'inventory_controller'
  }
];

// Employee dropdown options
const employeeOptions: SelectOption[] = employees.map(e => ({
  value: e.id,
  label: `${e.name} (${e.code})`
}));

// Movement Type options
const movementTypeOptions: SelectOption[] = [
  { value: 'promotion', label: 'Promotion' },
  { value: 'lateral_transfer', label: 'Lateral Transfer' },
  { value: 'grade_increment', label: 'Grade Increment' },
  { value: 'demotion', label: 'Demotion' },
  { value: 'secondment', label: 'Secondment' },
  { value: 'hire', label: 'Hire' },
  { value: 'separation', label: 'Separation' }
];

// Assignment Type options
const assignmentTypeOptions: SelectOption[] = [
  { value: 'primary', label: 'Primary Posting' },
  { value: 'acting', label: 'Acting Appointment' },
  { value: 'secondment', label: 'Secondment Deployment' },
  { value: 'additional', label: 'Additional Concurrent Posting' }
];

// Target Entity options
const entityOptions: SelectOption[] = [
  { value: 'bole_branch', label: 'Bole Branch' },
  { value: 'haleta_hq', label: 'Haleta Addis Ababa HQ' },
  { value: 'hawassa_plant', label: 'Hawassa Industrial Plant' },
  { value: 'piazza_retail', label: 'Piazza Retail Outlet' }
];

// Proposed Job Position options
const positionOptions: SelectOption[] = [
  { value: 'senior_accountant', label: 'Senior Accountant' },
  { value: 'shift_supervisor', label: 'Shift Supervisor' },
  { value: 'plant_security', label: 'Plant Security Guard' },
  { value: 'inventory_controller', label: 'Inventory Controller' },
  { value: 'procurement_officer', label: 'Procurement Officer' }
];

// Proposed Seniority Level options
const levelOptions: SelectOption[] = [
  { value: 'level_1', label: 'Level 1 (Entry)' },
  { value: 'level_2', label: 'Level 2' },
  { value: 'level_3', label: 'Level 3 (Senior)' },
  { value: 'level_4', label: 'Level 4 (Lead / Specialist)' }
];

// Target Work Shift options
const shiftOptions: SelectOption[] = [
  { value: 'regular_day', label: 'Regular Day Shift (08:00 – 17:00)' },
  { value: 'morning_retail', label: 'Retail Morning Shift (07:00 – 15:30)' },
  { value: 'evening_retail', label: 'Retail Evening Shift (14:30 – 22:30)' },
  { value: 'security_rota', label: 'Plant Security 12h Rota' }
];

// Manager options
const managerOptions: SelectOption[] = [
  { value: 44, label: 'Kassahun Belay (Head of Branch Operations)' },
  { value: 15, label: 'Sara Tefera (Retail Shift Supervisor)' },
  { value: 18, label: 'Rahel Girma (Finance Operations Director)' },
  { value: 7, label: 'Tewodros Kassahun (Security Operations Lead)' }
];

// ─── Form State ───
// Pre-selecting Almaz Kebede (ID 124) by default to match Image 1
const form = ref({
  employee_id: 124 as number | '',
  movement_type: 'promotion',
  assignment_type: 'primary',
  effective_date: '2026-10-12',
  to_entity_id: 'bole_branch',
  to_position_id: 'senior_accountant',
  to_seniority_level: 'level_2',
  to_salary: 10500,
  to_shift_pattern_id: 'regular_day',
  require_guarantee_refresh: false,
  sync_direct_manager: true, // checked in Image 1
  to_manager_id: 44 as number | '',
  description: ''
});

// Currently selected employee object
const selectedEmployee = computed<EmployeeProfileItem | null>(() => {
  if (!form.value.employee_id) return null;
  return employees.find(e => e.id === Number(form.value.employee_id)) || null;
});

// When employee changes, update proposed terms with realistic defaults
watch(() => form.value.employee_id, (newId) => {
  if (!newId) return;
  const emp = employees.find(e => e.id === Number(newId));
  if (emp) {
    form.value.to_salary = Math.round(emp.salary * 1.4685); // +46.9% like in Image 1
  }
});

// Compensation Delta Computation (Matching Image 1: Current 7,150 -> Proposed 10,500 = +3,350 (+46.9%))
const currentSalary = computed(() => selectedEmployee.value?.salary || 0);
const proposedSalary = computed(() => Number(form.value.to_salary) || 0);
const deltaAmount = computed(() => proposedSalary.value - currentSalary.value);
const deltaPercent = computed(() => {
  if (!currentSalary.value) return 0;
  return ((deltaAmount.value / currentSalary.value) * 100).toFixed(1);
});

const formatNumber = (val: number) => {
  return new Intl.NumberFormat('en-US').format(val);
};

// ─── Actions ───
const moreMenuItems: DropdownMenuItem[] = [
  {
    key: 'save-draft',
    label: 'Save as Draft',
    icon: Save,
    onClick: () => handleSaveDraft()
  }
];

const handleClearForm = () => {
  form.value = {
    employee_id: '',
    movement_type: '',
    assignment_type: '',
    effective_date: '2026-10-12',
    to_entity_id: '',
    to_position_id: '',
    to_seniority_level: '',
    to_salary: 0,
    to_shift_pattern_id: '',
    require_guarantee_refresh: false,
    sync_direct_manager: false,
    to_manager_id: '',
    description: ''
  };
  toast.info('Form Cleared', 'Form cleared.');
};

const handleSaveDraft = () => {
  showMoreDropdown.value = false;
  toast.success('Draft Saved', 'Movement proposal saved as Draft.');
};

const handleSave = () => {
  if (!form.value.employee_id) {
    toast.error('Validation Error', 'Please select an employee.');
    return;
  }
  toast.success('Movement Created', 'Movement proposal saved successfully.');
  setTimeout(() => {
    router.push('/hr/movements');
  }, 1000);
};

const closeMenus = () => {
  showMoreDropdown.value = false;
};
</script>

<template>
  <div class="create-movement-page" @click="closeMenus">
    <!-- ─── TOP BAR: Breadcrumb + Not Saved Badge + Action Buttons (Matching Image 1 & 2) ─── -->
    <div class="top-nav-bar">
      <div class="breadcrumb-group">
        <AppBreadcrumb :items="breadcrumbItems">
          <template #badge>
            <SaveStateBadge :isSaved="false" />
          </template>
        </AppBreadcrumb>
      </div>

      <div class="actions-group">
        <!-- 3-Dots More Options (Save as Draft via BaseDropdownMenu) -->
        <BaseDropdownMenu :items="moreMenuItems" minWidth="180px">
          <template #trigger="{ isOpen, toggle }">
            <AppButton
              variant="secondary-gray"
              size="sm"
              :iconOnly="true"
              :active="isOpen"
              title="More actions"
              @click="toggle"
            >
              <MoreVertical :size="16" />
            </AppButton>
          </template>
        </BaseDropdownMenu>

        <!-- Clear Form Button -->
        <AppButton
          variant="secondary-gray"
          size="sm"
          @click="handleClearForm"
        >
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>

        <!-- Primary Workflow Submit Button -->
        <AppButton
          variant="primary"
          size="sm"
          @click="handleSave"
        >
          Submit
        </AppButton>
      </div>
    </div>

    <!-- ─── CARD 1: Employee Target & Classification ─── -->
    <div class="form-section-card">
      <h3 class="section-title">1. Employee Target &amp; Classification</h3>

      <!-- 3 Columns: Select Employee, Movement Type, Assignment Type -->
      <div class="grid-3col">
        <div>
          <FormSelect
            v-model="form.employee_id"
            label="Select Employee"
            :options="employeeOptions"
            placeholder="Select Employee"
            :required="true"
          />
        </div>
        <div>
          <FormSelect
            v-model="form.movement_type"
            label="Movement Type"
            :options="movementTypeOptions"
            placeholder="Select Type"
            :required="true"
          />
        </div>
        <div>
          <FormSelect
            v-model="form.assignment_type"
            label="Assignment Type"
            :options="assignmentTypeOptions"
            placeholder="Select Type"
            :required="true"
          />
        </div>
      </div>

      <!-- Effective Date Row (Strict 3-Column Grid: 1 slot occupied) -->
      <div class="grid-3col">
        <div>
          <FormInput
            v-model="form.effective_date"
            type="date"
            label="Effective Date"
            :required="true"
          />
        </div>
      </div>

      <!-- Employee Preview Section: Image 1 (Selected) vs Image 2 (Empty) -->
      <div class="employee-preview-wrapper">
        <!-- Selected Employee Profile Card (Image 1) -->
        <div v-if="selectedEmployee" class="employee-profile-card">
          <div class="profile-left">
            <img 
              :src="selectedEmployee.avatar" 
              :alt="selectedEmployee.name" 
              class="profile-avatar-img"
            />
            <div class="profile-info-col">
              <span class="profile-name">{{ selectedEmployee.name }}</span>
              <div class="profile-meta-line">
                <span class="profile-code">{{ selectedEmployee.code }}</span>
                <span class="profile-dash">-</span>
                <span class="profile-role-tag">{{ selectedEmployee.role }}</span>
              </div>
            </div>
          </div>

          <div class="profile-right">
            <span class="profile-salary-text">
              Current Base Salary : <strong class="salary-highlight">ETB {{ formatNumber(selectedEmployee.salary) }}</strong>
            </span>
            <span class="profile-works-at-text">
              Works at : {{ selectedEmployee.works_at }}
            </span>
          </div>
        </div>

        <!-- Empty State Preview Box (Image 2) -->
        <div v-else class="employee-empty-preview">
          <User :size="16" class="empty-preview-icon" />
          <span class="empty-preview-text">Employee Preview Section</span>
        </div>
      </div>
    </div>

    <!-- ─── CARD 2: Proposed Target Placement & Terms ─── -->
    <div class="form-section-card">
      <h3 class="section-title">2. Proposed Target Placement &amp; Terms</h3>

      <!-- Row 1: Target Entity, Proposed Job Position, Proposed Seniority Level -->
      <div class="grid-3col">
        <div>
          <FormSelect
            v-model="form.to_entity_id"
            label="Target Entity"
            :options="entityOptions"
            placeholder="Select Entity"
            :required="true"
          />
        </div>
        <div>
          <FormSelect
            v-model="form.to_position_id"
            label="Proposed Job Position"
            :options="positionOptions"
            placeholder="Select Position"
            :required="true"
          />
        </div>
        <div>
          <FormSelect
            v-model="form.to_seniority_level"
            label="Proposed Seniority Level"
            :options="levelOptions"
            placeholder="Select Level"
            :required="true"
          />
        </div>
      </div>

      <!-- Row 2: Proposed Base Salary, Target Work Shift -->
      <div class="grid-3col row-salary-shift">
        <div>
          <FormInput
            v-model="form.to_salary"
            type="number"
            label="Proposed Base Salary"
            :required="true"
          />
        </div>
        <div>
          <FormSelect
            v-model="form.to_shift_pattern_id"
            label="Target Work Shift"
            :options="shiftOptions"
            placeholder="Select Shift"
            :required="true"
          />
        </div>
        <!-- 3rd column intentionally empty to match the 2-field layout in Image 1 & 2 -->
        <div></div>
      </div>

      <!-- Row 3: Two Side-by-Side Checkbox Panels (Matching Image 1 & 2 exactly) -->
      <div class="checkbox-panels-grid">
        <!-- Left Panel: Require Financial Surety / Guarantor Refresh -->
        <div class="checkbox-panel-box">
          <FormCheckbox
            v-model="form.require_guarantee_refresh"
            label="Require Financial Surety / Guarantor Refresh"
            description="Flag Position if surety collateral or guarantor endorsement is mandated by corporate cash-handling policy before posting."
          />
        </div>

        <!-- Right Panel: Synchronize Direct Reporting manager (FormCheckboxCard) -->
        <FormCheckboxCard
          v-model="form.sync_direct_manager"
          label="Synchronize Direct Reporting manager"
          description="Automatically update the employee's active supervision chain in company organization chart upon effectuation."
          :expandWhenChecked="true"
        >
          <FormSelect
            v-model="form.to_manager_id"
            label="New Direct Reporting Manager"
            :options="managerOptions"
            placeholder="Select Manager"
            :required="true"
          />
        </FormCheckboxCard>
      </div>

      <!-- Row 4: Compensation Delta Banner (Image 1) -->
      <div v-if="selectedEmployee" class="compensation-delta-banner">
        <Info :size="18" class="delta-info-icon" />
        <div class="delta-text-content">
          <span class="delta-title">
            Compensation Delta: {{ deltaAmount >= 0 ? '+' : '' }}ETB {{ formatNumber(deltaAmount) }} ({{ deltaPercent >= 0 ? '+' : '' }}{{ deltaPercent }}%)
          </span>
          <span class="delta-subtext">
            Current: ETB {{ formatNumber(currentSalary) }} &rarr; Proposed: ETB {{ formatNumber(proposedSalary) }}
          </span>
        </div>
      </div>
    </div>

    <!-- ─── CARD 3: Movement Description (Accordion with Standard Rich Text Component) ─── -->
    <div class="accordion-section-card">
      <div class="accordion-header" @click="isDescriptionOpen = !isDescriptionOpen">
        <span class="accordion-title">Movement Description</span>
        <component :is="isDescriptionOpen ? ChevronUp : ChevronDown" :size="16" class="accordion-chevron" />
      </div>

      <div v-if="isDescriptionOpen" class="accordion-content-body" style="padding: 16px 20px 20px 20px;">
        <FormRichText 
          v-model="form.description" 
          placeholder="Document the reason, business justification, or relevant terms for this movement..."
          :max-length="5000"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.create-movement-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: var(--alias-color-background-primary, #fafafa);
  min-height: 100vh;
}

/* ─── Top Bar ─── */
.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 2px;
}

.breadcrumb-group {
  display: flex;
  align-items: center;
  gap: 8px;
}

.badge-not-saved {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  background-color: #fef3c7;
  color: #d97706;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
  line-height: 1.2;
}

.actions-group {
  display: flex;
  align-items: center;
  gap: 8px;
}

.more-menu-wrapper {
  position: relative;
}

.btn-more-options {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-more-options:hover {
  background-color: #fafafa;
  border-color: #cbd5e1;
}

.more-dropdown-menu {
  position: absolute;
  top: 42px;
  right: 0;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  min-width: 150px;
  z-index: 50;
  padding: 4px;
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 12px;
  background: none;
  border: none;
  font-size: 13px;
  color: #404040;
  cursor: pointer;
  border-radius: 6px;
  text-align: left;
}

.dropdown-item:hover {
  background-color: #f5f5f5;
}

.btn-clear-form {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 14px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-clear-form:hover {
  background-color: #fafafa;
  border-color: #cbd5e1;
}

.btn-save-primary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 36px;
  padding: 0 22px;
  background-color: #0B529C;
  border: none;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  color: #ffffff;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-save-primary:hover {
  background-color: #094380;
}

/* ─── Form Cards ─── */
.form-section-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 22px 24px;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.section-title {
  margin: 0;
  font-size: 14.5px;
  font-weight: 500;
  color: #404040;
}

.grid-3col {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
}

@media (max-width: 900px) {
  .grid-3col {
    grid-template-columns: 1fr;
  }
}

.row-salary-shift {
  margin-top: -2px;
}

/* ─── Effective Date Row with [GC] badge ─── */
.effective-date-row {
  display: flex;
  flex-direction: column;
  gap: 4px;
  width: calc((100% - 32px) / 3); /* matches exactly 1 column width */
}

@media (max-width: 900px) {
  .effective-date-row {
    width: 100%;
  }
}

.field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.required-star {
  color: #ef4444;
}

.date-input-container {
  display: flex;
  align-items: center;
  height: 38px;
  padding: 0 10px 0 12px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  gap: 8px;
  transition: border-color 0.15s;
}

.date-input-container:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.calendar-prefix-icon {
  color: #737373;
  flex-shrink: 0;
}

.native-date-input {
  border: none;
  outline: none;
  font-size: 13.5px;
  color: #404040;
  width: 100%;
  background: transparent;
}

.gc-badge-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  background-color: #f5f5f5;
  color: #737373;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
  flex-shrink: 0;
}

/* ─── Employee Preview Section (Image 1 & 2) ─── */
.employee-preview-wrapper {
  margin-top: 4px;
}

/* Empty State Preview (Image 2) */
.employee-empty-preview {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 18px 24px;
  border: 1px dashed #cbd5e1;
  border-radius: 8px;
  background-color: #ffffff;
  color: #737373;
  font-size: 13px;
  font-weight: 500;
}

.empty-preview-icon {
  color: #94a3b8;
}

/* Selected Employee Card (Image 1) */
.employee-profile-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 20px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  background-color: #ffffff;
}

@media (max-width: 768px) {
  .employee-profile-card {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }
}

.profile-left {
  display: flex;
  align-items: center;
  gap: 14px;
}

.profile-avatar-img {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
}

.profile-info-col {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.profile-name {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.profile-meta-line {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
}

.profile-code {
  color: #737373;
}

.profile-dash {
  color: #cbd5e1;
}

.profile-role-tag {
  display: inline-block;
  padding: 2px 8px;
  background-color: #f5f5f5;
  color: #737373;
  border-radius: 4px;
  font-size: 11.5px;
  font-weight: 500;
}

.profile-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
}

@media (max-width: 768px) {
  .profile-right {
    align-items: flex-start;
  }
}

.profile-salary-text {
  font-size: 12.5px;
  color: #737373;
}

.salary-highlight {
  color: #404040;
  font-weight: 600;
}

.profile-works-at-text {
  font-size: 12px;
  color: #737373;
}

/* ─── Checkbox Panels Grid (Image 1 & 2) ─── */
.checkbox-panels-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-top: 4px;
}

@media (max-width: 768px) {
  .checkbox-panels-grid {
    grid-template-columns: 1fr;
  }
}

.checkbox-panel-box {
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 18px;
  background-color: #ffffff;
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
}

.checkbox-panel-box.has-manager-dropdown {
  gap: 14px;
}

.sub-manager-field {
  padding-top: 10px;
  border-top: 1px solid #f1f5f9;
}

/* ─── Compensation Delta Banner ─── */
.compensation-delta-banner {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 12px 16px;
  background-color: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 8px;
  margin-top: 4px;
}

.delta-info-icon {
  color: #0B529C;
  flex-shrink: 0;
  margin-top: 1px;
}

.delta-text-content {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.delta-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #1e40af;
}

.delta-subtext {
  font-size: 12px;
  color: #1d4ed8;
}

/* ─── Accordion WYSIWYG Card ─── */
.accordion-section-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.accordion-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: pointer;
  user-select: none;
}

.accordion-title {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
}

.accordion-chevron {
  color: #737373;
}

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
  min-height: 180px;
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

.wysiwyg-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 12px;
  background-color: #fafafa;
  border-top: 1px solid #f1f5f9;
}

.char-count-text {
  font-size: 11.5px;
  color: #737373;
}
</style>
