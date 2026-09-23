<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { 
  Monitor, ChevronRight, X, Award, Sliders,
  Plus, Trash2, Calendar, ChevronDown, Columns,
  Maximize2, Check, Calculator, Sparkles, Layers
} from 'lucide-vue-next';
import BaseTabs, { type TabItem } from '../../components/BaseTabs.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

const router = useRouter();
const route = useRoute();

// ─── Document State ───
const isSaved = ref(false);
const quickActionToast = ref<string | null>(null);
const isStepsSectionOpen = ref(true);

// ─── Active Tab (<BaseTabs /> Capsule Pill Standard) ───
type TabId = 'details' | 'steps';
const activeTab = ref<TabId>('details');

const tabs = computed<TabItem[]>(() => [
  { id: 'details', label: 'Grade Details', icon: Award },
  { id: 'steps', label: 'Discrete Step Ladder', icon: Layers }
]);

// ─── Master Form State (Schema lines 1065–1087 - Zero Manual Code Input) ───
const form = ref({
  name: '',
  entity_id: 'Haleta Addis Ababa HQ',
  level: 3,
  base_salary: 6000,
  ceiling_salary: 11000,
  description: ''
});

// Auto-derived code (Rule 16: Zero manual code input)
const derivedCode = computed(() => {
  if (!form.value.name.trim()) return 'JG-NEW';
  const parts = form.value.name.trim().split(' ');
  return parts.length > 1 ? parts[1].toUpperCase() : parts[0].substring(0, 3).toUpperCase();
});

// ─── Step Item within a Grade (JobGradeStep lines 1088–1109) ───
export interface GradeStepRow {
  id: number;
  step_number: number;
  amount: number;
  increment_years: number | null;
  description: string;
}

const stepsList = ref<GradeStepRow[]>([]);
const selectedStepIds = ref<number[]>([]);

// ─── Sub-table Selection Management ───
const isAllStepsSelected = computed(() => {
  return stepsList.value.length > 0 && stepsList.value.every(s => selectedStepIds.value.includes(s.id));
});

const toggleSelectAllSteps = () => {
  if (isAllStepsSelected.value) {
    selectedStepIds.value = [];
  } else {
    selectedStepIds.value = stepsList.value.map(s => s.id);
  }
};

const toggleStepSelection = (id: number) => {
  const idx = selectedStepIds.value.indexOf(id);
  if (idx > -1) {
    selectedStepIds.value.splice(idx, 1);
  } else {
    selectedStepIds.value.push(id);
  }
};

// ─── Step Actions ───
const handleAddStep = () => {
  const nextStepNo = stepsList.value.length + 1;
  const lastAmount = stepsList.value.length > 0 
    ? stepsList.value[stepsList.value.length - 1].amount 
    : form.value.base_salary;
  
  const increment = Math.round((form.value.ceiling_salary - form.value.base_salary) / 4);
  const newAmount = Math.min(form.value.ceiling_salary, lastAmount + increment);

  stepsList.value.push({
    id: Date.now() + nextStepNo,
    step_number: nextStepNo,
    amount: newAmount,
    increment_years: nextStepNo === 1 ? null : 2,
    description: nextStepNo === 1 ? 'Entry Step' : `Scale Step ${nextStepNo}`
  });

  showToast(`Added Step ${nextStepNo}.`);
};

const handleRemoveStep = (idx: number) => {
  stepsList.value.splice(idx, 1);
  // Re-sequence
  stepsList.value.forEach((s, i) => {
    s.step_number = i + 1;
  });
  showToast('Step removed and sequence updated.');
};

const handleBatchDeleteSteps = () => {
  stepsList.value = stepsList.value.filter(s => !selectedStepIds.value.includes(s.id));
  selectedStepIds.value = [];
  // Re-sequence
  stepsList.value.forEach((s, i) => {
    s.step_number = i + 1;
  });
  showToast('Selected steps deleted.');
};

// Auto-Calculate Linear Steps from Base to Ceiling
const autoCalculateSteps = () => {
  const count = 5;
  const min = Number(form.value.base_salary) || 5000;
  const max = Number(form.value.ceiling_salary) || 10000;
  const stepInc = (max - min) / (count - 1 || 1);

  stepsList.value = [];
  for (let s = 1; s <= count; s++) {
    stepsList.value.push({
      id: Date.now() + s,
      step_number: s,
      amount: Math.round(min + (s - 1) * stepInc),
      increment_years: s === 1 ? null : 2,
      description: s === 1 ? 'Entry Step' : s === count ? 'Ceiling Step' : `Scale Step ${s}`
    });
  }
  showToast(`Auto-calculated ${count} progression steps from base floor to ceiling.`);
};

// ─── Global Save & Clear ───
const handleSave = () => {
  if (!form.value.name.trim()) {
    showToast('Please enter Job Grade Name.');
    activeTab.value = 'details';
    return;
  }
  if (!form.value.entity_id) {
    showToast('Please select Owning Entity.');
    activeTab.value = 'details';
    return;
  }

  isSaved.value = true;
  showToast(`Job Grade "${form.value.name}" saved successfully with ${stepsList.value.length} discrete steps.`);

  setTimeout(() => {
    router.push('/hr/job-grades');
  }, 1200);
};

const clearForm = () => {
  form.value = {
    name: '',
    entity_id: 'Haleta Addis Ababa HQ',
    level: 3,
    base_salary: 6000,
    ceiling_salary: 11000,
    description: ''
  };
  stepsList.value = [];
  selectedStepIds.value = [];
  isSaved.value = false;
  showToast('Form cleared.');
};

const showToast = (msg: string) => {
  quickActionToast.value = msg;
  setTimeout(() => {
    quickActionToast.value = null;
  }, 4000);
};

const formatETB = (val: number) => {
  return new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(val);
};

// Hydrate from Route Query if navigated from Quick Create
onMounted(() => {
  if (route.query.name) form.value.name = String(route.query.name);
  if (route.query.entity) form.value.entity_id = String(route.query.entity);
  if (route.query.level) form.value.level = Number(route.query.level);
  if (route.query.base) form.value.base_salary = Number(route.query.base);
  if (route.query.ceiling) form.value.ceiling_salary = Number(route.query.ceiling);

  // Initialize standard 5 steps
  autoCalculateSteps();
});
</script>

<template>
  <div class="job-grade-create-page">
    <!-- Top Action & Breadcrumb Navigation Bar -->
    <div class="create-header-bar">
      <div class="header-left">
        <div class="breadcrumb-strip">
          <router-link to="/home" class="bc-home-icon" title="Home">
            <Monitor :size="15" />
          </router-link>
          <ChevronRight :size="13" class="bc-sep" />
          <router-link to="/hr/job-grades" class="bc-link">Job Grades & Pay Scales</router-link>
          <ChevronRight :size="13" class="bc-sep" />
          <span class="bc-current">Create Job Grade</span>
          <span :class="['state-pill', isSaved ? 'state-saved' : 'state-unsaved']">
            {{ isSaved ? 'Saved' : 'Not Saved' }}
          </span>
        </div>
      </div>

      <div class="header-actions">
        <button 
          type="button" 
          class="btn-clear-action" 
          @click="clearForm"
        >
          <X :size="14" />
          <span>Clear Form</span>
        </button>
        <button 
          type="button" 
          class="btn-save-action" 
          @click="handleSave"
        >
          <span>Save</span>
        </button>
      </div>
    </div>

    <!-- Quick Toast Notification -->
    <div v-if="quickActionToast" class="quick-toast-banner">
      <span>{{ quickActionToast }}</span>
    </div>

    <!-- Capsule Tabs Navigation Standard (<BaseTabs />) -->
    <div class="create-tabs-wrapper">
      <BaseTabs 
        v-model="activeTab"
        :tabs="tabs"
        size="md"
      />
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 1: GRADE DETAILS                                          -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'details'" class="tab-content-container">
      <div class="clean-card">
        <div class="section-title-box">
          <div class="title-with-badge">
            <h2 class="section-title">Job Grade Information</h2>
            <span class="code-preview-pill">Auto Code: {{ derivedCode }}</span>
          </div>
          <p class="section-subtitle">
            Configure pay grade band boundaries, statutory base floor and ceiling compensation limits.
          </p>
        </div>

        <!-- 3-Column Responsive Grid (Rule 16: Zero Code Input) -->
        <div class="form-grid-3">
          <!-- Grade Name: Rule 5 (No Placeholder) -->
          <FormInput 
            label="Grade Name" 
            v-model="form.name" 
            required 
          />

          <!-- Owning Entity -->
          <FormSelect
            label="Owning Entity"
            v-model="form.entity_id"
            placeholder="Select"
            :options="[
              'Haleta Addis Ababa HQ',
              'Haleta Grand Hotel & Suites',
              'Haleta Hawassa Hub'
            ]"
            required
          />

          <!-- Seniority Level -->
          <FormSelect
            label="Seniority Level"
            v-model="form.level"
            placeholder="Select"
            :options="[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
            required
          />

          <!-- Base Floor Salary -->
          <FormInput
            label="Base Floor Salary (ETB)"
            type="number"
            v-model="form.base_salary"
            required
          />

          <!-- Ceiling Salary -->
          <FormInput
            label="Ceiling Salary Cap (ETB)"
            type="number"
            v-model="form.ceiling_salary"
            required
          />

          <!-- Auto Attached Matrix Notice -->
          <div class="matrix-attached-info-wrap">
            <label class="info-field-label">Attached Pay Scale</label>
            <div class="matrix-info-display">
              <span class="matrix-info-text">Active Baseline Pay Scale (Default)</span>
            </div>
          </div>
        </div>

        <!-- Description Textarea (Schema line 1070: jsonb/text description) -->
        <div class="form-group-full mt-4">
          <FormTextarea
            label="Grade Scope & Definition"
            v-model="form.description"
            rows="4"
          />
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 2: DISCRETE STEP LADDER (Dynamic Child Sub-table)          -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'steps'" class="tab-content-container">
      <div class="clean-card">
        <!-- Accordion Title -->
        <div 
          class="section-accordion-header" 
          @click="isStepsSectionOpen = !isStepsSectionOpen"
        >
          <div class="accordion-title-left">
            <span class="accordion-title-text">Discrete Step Ladder</span>
            <span class="badge-count">{{ stepsList.length }} Steps</span>
          </div>
          <div class="accordion-title-right">
            <button 
              type="button" 
              class="btn-calc-steps" 
              @click.stop="autoCalculateSteps"
            >
              <Calculator :size="13" />
              <span>Auto-Distribute Steps</span>
            </button>
            <ChevronDown 
              :size="16" 
              :class="['acc-chevron', { 'rotate-180': !isStepsSectionOpen }]" 
            />
          </div>
        </div>

        <div v-show="isStepsSectionOpen" class="accordion-body">
          <div class="child-subtable-container">
            <table class="child-table">
              <thead>
                <tr>
                  <th class="child-th child-th-check">
                    <input 
                      type="checkbox" 
                      class="custom-checkbox" 
                      :checked="isAllStepsSelected" 
                      @change="toggleSelectAllSteps" 
                    />
                  </th>
                  <th class="child-th child-th-no">#</th>
                  <th class="child-th child-th-step">Step Number</th>
                  <th class="child-th child-th-amount">Monthly Amount (ETB)</th>
                  <th class="child-th child-th-wait">Wait Time (Years)</th>
                  <th class="child-th child-th-desc">Description / Purpose</th>
                  <th class="child-th child-th-action">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr 
                  v-for="(step, idx) in stepsList" 
                  :key="step.id" 
                  class="child-tr"
                  :class="{ 'row-selected': selectedStepIds.includes(step.id) }"
                >
                  <td class="child-td child-td-check">
                    <input 
                      type="checkbox" 
                      class="custom-checkbox" 
                      :checked="selectedStepIds.includes(step.id)" 
                      @change="toggleStepSelection(step.id)" 
                    />
                  </td>
                  <td class="child-td child-td-no">{{ idx + 1 }}</td>
                  <td class="child-td child-td-step">
                    <span class="font-semibold text-slate-800">Step {{ step.step_number }}</span>
                  </td>
                  <td class="child-td child-td-amount">
                    <input 
                      type="number" 
                      v-model.number="step.amount" 
                      class="child-inline-input font-mono" 
                    />
                  </td>
                  <td class="child-td child-td-wait">
                    <input 
                      type="number" 
                      v-model.number="step.increment_years" 
                      class="child-inline-input"
                      placeholder="Entry" 
                    />
                  </td>
                  <td class="child-td child-td-desc">
                    <input 
                      type="text" 
                      v-model="step.description" 
                      class="child-inline-input" 
                    />
                  </td>
                  <td class="child-td child-td-action">
                    <button 
                      type="button" 
                      class="btn-row-delete" 
                      @click="handleRemoveStep(idx)" 
                      title="Delete Step"
                    >
                      <Trash2 :size="14" />
                    </button>
                  </td>
                </tr>

                <tr v-if="stepsList.length === 0">
                  <td colspan="7" class="child-td-empty">
                    <span>No discrete steps defined yet. Click below or Auto-Distribute to populate.</span>
                  </td>
                </tr>
              </tbody>
            </table>

            <!-- Add Row Button directly beneath table -->
            <button 
              type="button" 
              class="btn-add-row" 
              @click="handleAddStep"
            >
              <Plus :size="14" />
              <span>Add Step</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Floating Batch Action Bar -->
    <TableFloatingBar 
      :count="selectedStepIds.length" 
      @delete="handleBatchDeleteSteps" 
    />
  </div>
</template>

<style scoped>
.job-grade-create-page {
  padding: 20px 32px 64px 32px;
  background-color: #f8fafc;
  min-height: 100vh;
}

/* Header & Breadcrumb Bar */
.create-header-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 18px;
}

.breadcrumb-strip {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
}

.bc-home-icon {
  color: #737373;
  display: flex;
  align-items: center;
}

.bc-home-icon:hover {
  color: #0B529C;
}

.bc-sep {
  color: #cbd5e1;
}

.bc-link {
  color: #737373;
  text-decoration: none;
}

.bc-link:hover {
  color: #0B529C;
}

.bc-current {
  color: #404040;
  font-weight: 500;
}

.state-pill {
  font-size: 11px;
  font-weight: 500;
  padding: 2px 8px;
  border-radius: 9999px;
  margin-left: 6px;
}

.state-unsaved {
  background-color: #fff1f2;
  color: #e11d48;
}

.state-saved {
  background-color: #ecfdf5;
  color: #059669;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* Button Standard: Rule 6 Well-rounded rectangle (8px-10px) */
.btn-clear-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-clear-action:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.btn-save-action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 38px;
  padding: 0 20px;
  background-color: #0B529C;
  border: none;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  color: #ffffff;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-save-action:hover {
  background-color: #09427d;
}

/* Toast */
.quick-toast-banner {
  position: fixed;
  top: 24px;
  right: 32px;
  z-index: 1000;
  padding: 10px 18px;
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.08);
  font-size: 13px;
  color: #404040;
}

/* Tabs */
.create-tabs-wrapper {
  margin-bottom: 20px;
}

.tab-content-container {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

/* Clean Card */
.clean-card {
  background-color: #ffffff;
  border-radius: 12px;
  border: 1px solid #f1f5f9;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  padding: 24px;
}

.section-title-box {
  margin-bottom: 20px;
}

.title-with-badge {
  display: flex;
  align-items: center;
  gap: 12px;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
}

.code-preview-pill {
  background-color: #f1f5f9;
  color: #475569;
  font-size: 11.5px;
  font-weight: 600;
  font-family: monospace;
  padding: 2px 8px;
  border-radius: 4px;
}

.section-subtitle {
  font-size: 12.5px;
  color: #737373;
  margin-top: 4px;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 18px;
}

.matrix-attached-info-wrap {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.info-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.matrix-info-display {
  height: 38px;
  display: flex;
  align-items: center;
  padding: 0 12px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #64748b;
}

/* Accordion */
.section-accordion-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  user-select: none;
}

.accordion-title-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.accordion-title-text {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.badge-count {
  background-color: #f1f5f9;
  color: #475569;
  font-size: 11.5px;
  font-weight: 500;
  padding: 1px 8px;
  border-radius: 9999px;
}

.accordion-title-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.btn-calc-steps {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 30px;
  padding: 0 12px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
}

.btn-calc-steps:hover {
  border-color: #0B529C;
  color: #0B529C;
}

.acc-chevron {
  color: #737373;
  transition: transform 0.2s ease;
}

.rotate-180 {
  transform: rotate(180deg);
}

.accordion-body {
  margin-top: 20px;
}

/* Child Sub-Table */
.child-subtable-container {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.child-table {
  width: 100%;
  border-collapse: collapse;
}

.child-th {
  height: 32px;
  padding: 6px 12px;
  background-color: #f8fafc;
  font-size: 11.5px;
  font-weight: 500;
  color: #737373;
  text-align: left;
  border-bottom: 1px solid #f1f5f9;
}

.child-td {
  padding: 8px 12px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.child-th-check,
.child-td-check {
  width: 36px;
  padding-left: 8px;
}

.child-th-no,
.child-td-no {
  width: 40px;
  font-size: 12px;
  color: #737373;
}

.child-th-step,
.child-td-step {
  width: 110px;
}

.child-th-amount,
.child-td-amount {
  width: 180px;
}

.child-th-wait,
.child-td-wait {
  width: 150px;
}

.child-th-action,
.child-td-action {
  width: 60px;
  text-align: center;
}

.child-inline-input {
  height: 34px;
  width: 100%;
  padding: 0 10px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 13px;
  color: #404040;
  outline: none;
  background-color: #ffffff;
}

.child-inline-input:focus {
  border-color: #0B529C;
}

.btn-row-delete {
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  color: #94a3b8;
  cursor: pointer;
  border-radius: 4px;
}

.btn-row-delete:hover {
  background-color: #fff1f2;
  color: #e11d48;
}

.child-td-empty {
  padding: 32px;
  text-align: center;
  font-size: 12.5px;
  color: #737373;
}

.btn-add-row {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  align-self: flex-start;
  height: 34px;
  padding: 0 14px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
}

.btn-add-row:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.custom-checkbox {
  width: 16px;
  height: 16px;
  accent-color: #0B529C;
  border-radius: 4px;
  cursor: pointer;
}

.mt-4 {
  margin-top: 16px;
}
</style>
