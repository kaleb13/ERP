<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { 
  X, Save, CheckCircle2, ShieldCheck, 
  Calendar, Heart, Activity, UserCheck, 
  Users, GraduationCap, Clock, Check
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import { createLeaveType } from './leavePolicyData';

const router = useRouter();
const route = useRoute();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3 & 4) ───
// STRICTLY NO separate back button! Breadcrumb itself is the sole navigation.
const breadcrumbItems = [
  { label: 'Leave Type', to: '/hr/leave-types' },
  { label: 'Create Leave Type' }
];

const isSaved = ref(false);
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Entity Scope Options (Schema line 1559: NULL = Platform Seed) ───
const entityScopeOptions: SelectOption[] = [
  { value: 0, label: 'Platform Global Scope (All Branches & Entities)' },
  { value: 3, label: 'Haleta Corporate Headquarters Only' },
  { value: 7, label: 'Bole Commercial Branch Only' },
  { value: 9, label: 'Bahir Dar Regional Hub Only' }
];

// ─── Governance Status (Schema line 1564: status_lookup_value_id) ───
const governanceStatusOptions: SelectOption[] = [
  { value: 'acceptForAll', label: 'Accepted for All Tenants & Policies (Standard Statutory)' },
  { value: 'acceptForThis', label: 'Accepted for Owning Entity Only' },
  { value: 'pending', label: 'Pending Governance Review' }
];

// ─── Icon Options ───
const iconOptions: SelectOption[] = [
  { value: 'Calendar', label: 'Calendar (Standard Rest)' },
  { value: 'Activity', label: 'Activity (Medical / Hospitalization)' },
  { value: 'Heart', label: 'Heart (Maternity / Family)' },
  { value: 'UserCheck', label: 'UserCheck (Paternity / Personal)' },
  { value: 'Users', label: 'Users (Bereavement / Compassionate)' },
  { value: 'GraduationCap', label: 'GraduationCap (Academic / Exam)' },
  { value: 'Clock', label: 'Clock (Unpaid / Deferral)' }
];

// ─── Master Form State (Schema Lines 1553–1566) ───
const form = ref({
  code: '',
  name: '',
  description: '',
  entity_id: 0,
  icon_name: 'Calendar',
  governance_status: 'acceptForAll',
  is_paid: true,
  requires_attachment: false,
  affects_attendance: true
});

// Auto-capitalize code on input
const handleNameBlur = () => {
  if (form.value.name && !form.value.code) {
    form.value.code = form.value.name
      .toUpperCase()
      .replace(/[^A-Z0-9]/g, '_')
      .replace(/_+/g, '_');
  }
};

// Sync from route query if expanded from QuickCreateModal
onMounted(() => {
  if (route.query.code) form.value.code = String(route.query.code);
  if (route.query.name) form.value.name = String(route.query.name);
  if (route.query.description) form.value.description = String(route.query.description);
  if (route.query.is_paid !== undefined) form.value.is_paid = route.query.is_paid === 'true';
  if (route.query.requires_attachment !== undefined) form.value.requires_attachment = route.query.requires_attachment === 'true';
  if (route.query.affects_attendance !== undefined) form.value.affects_attendance = route.query.affects_attendance === 'true';
});

const handleClearForm = () => {
  form.value = {
    code: '',
    name: '',
    description: '',
    entity_id: 0,
    icon_name: 'Calendar',
    governance_status: 'acceptForAll',
    is_paid: true,
    requires_attachment: false,
    affects_attendance: true
  };
  showToast('Form cleared.');
};

const handleSave = () => {
  if (!form.value.code.trim()) {
    alert('Please enter a unique leave code (e.g. ANNUAL, SABBATICAL).');
    return;
  }
  if (!form.value.name.trim()) {
    alert('Please enter a leave category name.');
    return;
  }

  const newRec = createLeaveType({
    code: form.value.code,
    name: form.value.name,
    description: form.value.description,
    is_paid: form.value.is_paid,
    requires_attachment: form.value.requires_attachment,
    affects_attendance: form.value.affects_attendance
  });

  isSaved.value = true;
  showToast(`Leave category "${newRec.name}" created successfully.`);
  setTimeout(() => {
    router.push('/hr/leave-types');
  }, 800);
};
</script>

<template>
  <div class="leave-type-create-page">
    <!-- Top Bar (AGENTS.md Rule 4 & Breadcrumb Standard) -->
    <div class="top-nav-bar">
      <!-- STRICTLY NO separate back button! Breadcrumb itself navigates. -->
      <AppBreadcrumb :items="breadcrumbItems" />

      <div class="top-actions-cluster">
        <span class="save-status-pill" :class="isSaved ? 'pill-saved' : 'pill-not-saved'">
          {{ isSaved ? 'Saved' : 'Not Saved' }}
        </span>

        <!-- Clear Form Secondary Button -->
        <button class="btn-secondary-action" @click="handleClearForm">
          <X :size="14" />
          <span>Clear Form</span>
        </button>

        <!-- Save Primary Blue Button -->
        <button class="btn-primary-action" @click="handleSave">
          <Save :size="15" />
          <span>Save</span>
        </button>
      </div>
    </div>

    <!-- Toast Notification -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <div class="creation-body-stack">
      <!-- MASTER CARD: LEAVE CATEGORY DEFINITION (Schema Lines 1553–1566) -->
      <div class="clean-card">
        <div class="card-header-bar">
          <h2 class="card-title">Leave Category Specification</h2>
          <p class="card-subtitle">Define catalog nomenclature, organization scope, and statutory governance attributes.</p>
        </div>

        <div class="form-grid-2">
          <!-- Code -->
          <div class="form-group">
            <label class="form-label required">Leave Code</label>
            <FormInput
              v-model="form.code"
              hint="Statutory uppercase identifier, e.g. ANNUAL, SABBATICAL, STUDY"
            />
          </div>

          <!-- Name -->
          <div class="form-group">
            <label class="form-label required">Leave Category Name</label>
            <FormInput
              v-model="form.name"
              @blur="handleNameBlur"
            />
          </div>

          <!-- Entity Scope -->
          <div class="form-group">
            <label class="form-label required">Organizational Scope</label>
            <FormSelect
              v-model="form.entity_id"
              :options="entityScopeOptions"
              placeholder="Select"
              hint="Choose Platform Global Scope or restrict to specific corporate branch"
            />
          </div>

          <!-- Visual Icon -->
          <div class="form-group">
            <label class="form-label required">Visual Icon Indicator</label>
            <FormSelect
              v-model="form.icon_name"
              :options="iconOptions"
              placeholder="Select"
            />
          </div>
        </div>

        <!-- Governance Status -->
        <div class="form-group full-width-group">
          <label class="form-label required">Core Governance Acceptance</label>
          <FormSelect
            v-model="form.governance_status"
            :options="governanceStatusOptions"
            placeholder="Select"
          />
        </div>

        <!-- Description -->
        <div class="form-group full-width-group">
          <label class="form-label">Category Scope Description</label>
          <FormInput
            v-model="form.description"
          />
        </div>

        <!-- Section: Boolean Governance Rules (AGENTS.md Rule 5) -->
        <div class="flags-section">
          <h3 class="flags-section-title">Statutory Governance &amp; Payroll Impact</h3>

          <div class="flags-stack">
            <FormCheckbox
              v-model="form.is_paid"
              label="Paid Leave Compensation"
              description="Employees receive regular basic salary compensation during this absence. Unchecking designates this as unpaid absence."
            />

            <FormCheckbox
              v-model="form.requires_attachment"
              label="Mandatory Supporting Document / Evidence"
              description="Leave requests under this category must carry formal medical certificate, legal summons, or academic documentation."
            />

            <FormCheckbox
              v-model="form.affects_attendance"
              label="Affects Attendance &amp; Shift Rosters"
              description="Writes on_leave status into automated daily attendance ledgers and exempts staff from shift clocking infractions."
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.leave-type-create-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 20px 24px 80px;
  background-color: #f8fafc;
  min-height: 100vh;
}

/* Top Nav Bar */
.top-nav-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background-color: #ffffff;
  padding: 12px 18px;
  border-radius: 10px;
  border: 1px solid #e2e8f0;
}

.top-actions-cluster {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* Status Pill */
.save-status-pill {
  font-size: 11.5px;
  font-weight: 500;
  padding: 3px 10px;
  border-radius: 9999px;
}
.pill-not-saved {
  background-color: #fef3c7;
  color: #92400e;
}
.pill-saved {
  background-color: #ecfdf5;
  color: #059669;
}

/* Toast */
.toast-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #ecfdf5;
  color: #065f46;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  padding: 10px 14px;
  font-size: 13px;
  font-weight: 500;
  width: fit-content;
}

.toast-fade-enter-active,
.toast-fade-leave-active {
  transition: all 0.25s ease;
}
.toast-fade-enter-from,
.toast-fade-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}

/* Buttons (Rule 6: 8px to 10px rounded rectangle, NEVER pills) */
.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  height: 38px;
  padding: 0 16px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-primary-action:hover {
  background-color: #09427d;
}

.btn-secondary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #ffffff;
  color: #404040;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  height: 38px;
  padding: 0 14px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}
.btn-secondary-action:hover {
  background-color: #f8fafc;
}

/* Main Form */
.creation-body-stack {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.clean-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 20px 24px;
}

.card-header-bar {
  margin-bottom: 18px;
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
  margin: 4px 0 0;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px 20px;
  margin-bottom: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
}

.full-width-group {
  margin-bottom: 16px;
}

.form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 4px;
}
.form-label.required::after {
  content: ' *';
  color: #dc2626;
}

.flags-section {
  border-top: 1px solid #f1f5f9;
  padding-top: 18px;
  margin-top: 10px;
}
.flags-section-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 14px;
}
.flags-stack {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
</style>
