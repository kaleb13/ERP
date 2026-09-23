<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useRouter } from 'vue-router';
import { 
  X, Sliders, Plus, Trash2, Calendar, 
  Check, Percent, CheckCircle2,
  ChevronDown, ChevronRight, Columns, Maximize2,
  FileSpreadsheet
} from 'lucide-vue-next';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';

const router = useRouter();

// ─── Active Tab State (Capsule Tabs: Salary Scale Detail vs Pay Grade & Steps) ───
type TabKey = 'scale' | 'grades';
const activeTab = ref<TabKey>('scale');

const tabs: BaseTabItem<TabKey>[] = [
  { id: 'scale', label: 'Salary Scale Detail', icon: Sliders },
  { id: 'grades', label: 'Pay Grade & Steps', icon: FileSpreadsheet }
];

// ─── Document State ───
const isSaved = ref(false);
const quickActionToast = ref<string | null>(null);
const showAdjustmentModal = ref(false);
const adjustmentPercent = ref(0);

// Step Modal State
const showStepModal = ref(false);
const activeStepData = ref<{
  gradeName: string;
  stepNumber: number;
  amount: number;
  incrementYears: number | null;
  description: string;
} | null>(null);

// ─── SalaryMatrix Header (Schema lines 1044–1064: ZERO phantom fields) ───
const form = ref({
  entity_id: 'Haleta Addis Ababa',
  currency_code: 'ETB',
  number_of_steps: 3,
  effective_from: '2026-05-04',
  effective_to: '',
  is_default: false
});

// ─── Types (strictly aligned with schema lines 1066–1109) ───
export interface StepCell {
  step_number: number;
  amount: number;
  increment_years: number | null;
  description: string;
}

export interface GradeCard {
  id: number;
  code: string;
  name: string;
  level: number;
  description: string;
  base_salary: number;
  ceiling_salary: number;
  is_collapsed: boolean;
  steps: StepCell[];
}

// ─── Dynamic step count helper ───
const stepCount = computed(() => Math.max(1, Number(form.value.number_of_steps) || 1));

// ─── Helper: Create steps array ───
const makeDefaultSteps = (count: number, base: number, ceiling: number): StepCell[] => {
  const steps: StepCell[] = [];
  const inc = count > 1 ? (ceiling - base) / (count - 1) : 0;
  for (let i = 1; i <= count; i++) {
    steps.push({
      step_number: i,
      amount: Math.round(base + (i - 1) * inc),
      increment_years: i === 1 ? null : 2,
      description: i === 1 ? 'Entry Baseline' : ''
    });
  }
  return steps;
};

// ─── Grade Cards (Initialized matching Image 3) ───
const gradeRows = ref<GradeCard[]>([
  { 
    id: 1, 
    code: 'C1', 
    name: 'Operational Support', 
    level: 1, 
    description: '', 
    base_salary: 2500, 
    ceiling_salary: 9000, 
    is_collapsed: false,
    steps: [
      { step_number: 1, amount: 2500, increment_years: null, description: 'Entry Baseline' },
      { step_number: 2, amount: 5000, increment_years: 5, description: '' },
      { step_number: 3, amount: 9000, increment_years: 2, description: '' }
    ]
  },
  { 
    id: 2, 
    code: 'C2', 
    name: '', 
    level: 2, 
    description: '', 
    base_salary: 0, 
    ceiling_salary: 0, 
    is_collapsed: false,
    steps: [
      { step_number: 1, amount: 0, increment_years: null, description: 'Entry Baseline' },
      { step_number: 2, amount: 0, increment_years: 2, description: '' },
      { step_number: 3, amount: 0, increment_years: 2, description: '' }
    ]
  }
]);

// ─── Watch: Resize steps dynamically when number_of_steps changes ───
watch(() => form.value.number_of_steps, (newVal) => {
  const count = Math.max(1, Number(newVal) || 1);
  gradeRows.value.forEach(row => {
    if (row.steps.length < count) {
      const lastAmt = row.steps.length > 0 ? row.steps[row.steps.length - 1].amount : row.base_salary;
      const remaining = count - row.steps.length;
      const gap = row.ceiling_salary > lastAmt ? (row.ceiling_salary - lastAmt) / (remaining + 1) : 0;
      for (let i = row.steps.length + 1; i <= count; i++) {
        row.steps.push({
          step_number: i,
          amount: Math.round(lastAmt + (i - row.steps.length) * gap),
          increment_years: 2,
          description: ''
        });
      }
    } else if (row.steps.length > count) {
      row.steps = row.steps.slice(0, count);
    }
    row.steps.forEach((s, idx) => { s.step_number = idx + 1; });
  });
});

// ─── Handlers ───
const showToast = (msg: string) => {
  quickActionToast.value = msg;
  setTimeout(() => { quickActionToast.value = null; }, 4000);
};

const handleAddGradeRow = () => {
  const count = stepCount.value;
  const nextLevel = gradeRows.value.length > 0 ? Math.max(...gradeRows.value.map(r => r.level)) + 1 : 1;
  gradeRows.value.push({
    id: Date.now(),
    code: '',
    name: '',
    level: nextLevel,
    description: '',
    base_salary: 0,
    ceiling_salary: 0,
    is_collapsed: false,
    steps: makeDefaultSteps(count, 0, 0)
  });
  showToast('New pay grade card added.');
};

const removeGradeItem = (index: number) => {
  gradeRows.value.splice(index, 1);
  showToast('Job grade card removed.');
};

const autoDistributeRow = (row: GradeCard) => {
  const count = row.steps.length;
  if (count < 2 || row.base_salary <= 0 || row.ceiling_salary <= 0) {
    return;
  }
  const inc = (row.ceiling_salary - row.base_salary) / (count - 1);
  row.steps.forEach((step, idx) => {
    step.amount = Math.round(row.base_salary + idx * inc);
  });
};

const handleApplyAdjustment = () => {
  const pct = (Number(adjustmentPercent.value) || 0) / 100;
  gradeRows.value.forEach(row => {
    row.base_salary = Math.round(row.base_salary * (1 + pct));
    row.ceiling_salary = Math.round(row.ceiling_salary * (1 + pct));
    row.steps.forEach(s => { s.amount = Math.round(s.amount * (1 + pct)); });
  });
  showAdjustmentModal.value = false;
  showToast(`Applied ${adjustmentPercent.value}% adjustment across all grades.`);
};

const openStepModal = (step: StepCell, row: GradeCard) => {
  activeStepData.value = {
    gradeName: row.name || `Level ${row.level}`,
    stepNumber: step.step_number,
    amount: step.amount,
    incrementYears: step.increment_years,
    description: step.description
  };
  showStepModal.value = true;
};

const saveStepModal = () => {
  if (!activeStepData.value) return;
  gradeRows.value.forEach(row => {
    row.steps.forEach(s => {
      if (s.step_number === activeStepData.value?.stepNumber && (row.name === activeStepData.value?.gradeName || `Level ${row.level}` === activeStepData.value?.gradeName)) {
        s.amount = activeStepData.value.amount;
        s.increment_years = activeStepData.value.incrementYears;
        s.description = activeStepData.value.description;
      }
    });
  });
  showStepModal.value = false;
  showToast('Step details updated.');
};

const clearForm = () => {
  form.value = {
    entity_id: 'Haleta Addis Ababa',
    currency_code: 'ETB',
    number_of_steps: 3,
    effective_from: '2026-05-04',
    effective_to: '',
    is_default: false
  };
  gradeRows.value = [
    { 
      id: 1, 
      code: 'C1', 
      name: '', 
      level: 1, 
      description: '', 
      base_salary: 0, 
      ceiling_salary: 0, 
      is_collapsed: false,
      steps: makeDefaultSteps(3, 0, 0)
    }
  ];
  isSaved.value = false;
  showToast('Form reset to defaults.');
};

const handleSave = () => {
  if (gradeRows.value.length === 0) {
    showToast('Please add at least one job grade card.');
    return;
  }
  isSaved.value = true;
  showToast('Salary scale saved successfully.');
};

// Breadcrumb strictly page names only (Rule 3.2: zero section names)
const breadcrumbItems = [
  { label: 'Salary Scale', to: '/hr/salary-scales' },
  { label: 'Create Salary Scale' }
];
</script>

<template>
  <div class="scale-create-page">
    <!-- ═══ TOP BAR (Clean Breadcrumbs Only - Zero Back Button) ═══ -->
    <div class="top-action-bar">
      <div class="top-bar-left">
        <AppBreadcrumb :items="breadcrumbItems" />
        <span :class="['save-status-pill', isSaved ? 'status-saved' : 'status-unsaved']">
          {{ isSaved ? 'Saved' : 'Not Saved' }}
        </span>
      </div>
      <div class="top-bar-right">
        <button type="button" class="btn-secondary-action" @click="clearForm">
          <X :size="14" />
          <span>Clear Form</span>
        </button>
        <button type="button" class="btn-primary-action" @click="handleSave">
          <Check :size="14" />
          <span>Save</span>
        </button>
      </div>
    </div>

    <!-- Toast Banner -->
    <div v-if="quickActionToast" class="quick-toast-banner">
      <CheckCircle2 :size="15" class="toast-icon" />
      <span>{{ quickActionToast }}</span>
    </div>

    <!-- ═══ PRIMARY TABS (<BaseTabs /> Capsule Pills) ═══ -->
    <div class="page-tabs-container">
      <BaseTabs :tabs="tabs" v-model="activeTab" />
    </div>

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- TAB 1: SALARY SCALE DETAIL (Matching Image 5)                  -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <div v-if="activeTab === 'scale'" class="scale-detail-card clean-card">
      <div class="card-section-title">Salary Scale Detail</div>

      <div class="scale-form-content">
        <!-- Row 1: 3-column parameters grid -->
        <div class="form-grid-3">
          <div class="form-field-group">
            <label class="form-field-label">Owning Entity</label>
            <select v-model="form.entity_id" class="form-select">
              <option value="" disabled>Select Entity</option>
              <option value="Haleta Addis Ababa">Haleta Addis Ababa</option>
              <option value="Grand Hotel">Grand Hotel</option>
              <option value="Mola Trading">Mola Trading</option>
            </select>
          </div>

          <div class="form-field-group">
            <label class="form-field-label">Number of Steps <span class="required-star">*</span></label>
            <input 
              type="number" 
              v-model.number="form.number_of_steps" 
              class="form-input font-mono" 
              min="1" 
              max="50"
              required 
            />
          </div>

          <div class="form-field-group">
            <label class="form-field-label">Currency</label>
            <select v-model="form.currency_code" class="form-select">
              <option value="ETB">ETB</option>
              <option value="USD">USD</option>
              <option value="EUR">EUR</option>
              <option value="GBP">GBP</option>
            </select>
          </div>
        </div>

        <!-- Row 2: 2-column dates grid with [GC] pill -->
        <div class="form-grid-2">
          <div class="form-field-group">
            <label class="form-field-label">Effective From Date <span class="required-star">*</span></label>
            <div class="date-input-wrap">
              <Calendar :size="14" class="date-icon" />
              <input type="date" v-model="form.effective_from" class="form-input date-input" required />
              <span class="gc-pill-tag">GC</span>
            </div>
          </div>

          <div class="form-field-group">
            <label class="form-field-label">Effective Until</label>
            <div class="date-input-wrap">
              <Calendar :size="14" class="date-icon" />
              <input type="date" v-model="form.effective_to" class="form-input date-input" />
              <span class="gc-pill-tag">GC</span>
            </div>
          </div>
        </div>

        <!-- Row 3: Standalone FormCheckbox with Title & Description -->
        <div class="form-checkbox-row">
          <FormCheckbox
            v-model="form.is_default"
            label="Default Salary Scale"
            description="Designates this compensation grid as the active pay baseline for newly attached job grades in this entity."
          />
        </div>
      </div>
    </div>

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- TAB 2: PAY GRADE & STEPS (Matching Image 3)                    -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <div v-if="activeTab === 'grades'" class="pay-grades-container">
      <!-- Section Outer Card -->
      <div class="clean-card pay-grades-master-card">
        <div class="pay-grades-header-row">
          <div class="pay-grades-header-text">
            <h2 class="pay-grades-title">Pay Grade &amp; Steps</h2>
            <p class="pay-grades-subtitle">
              Configure pay grade bands with base and ceiling salary guardrails. Each card features its complete step progression below with amounts, wait years, and descriptions directly editable without opening any modal.
            </p>
          </div>
          <div class="pay-grades-header-action">
            <button 
              type="button" 
              class="btn-adjust-all" 
              @click="showAdjustmentModal = true"
            >
              <span>Adjust All</span>
              <Percent :size="13" class="btn-icon-pct" />
            </button>
          </div>
        </div>

        <!-- Stacked Grade Cards Repeater -->
        <div class="grade-cards-repeater">
          <div 
            v-for="(row, idx) in gradeRows" 
            :key="row.id" 
            class="grade-repeater-card"
          >
            <!-- Card Header: Title, Level Badge, Chevron, Delete -->
            <div class="grade-card-bar" @click="row.is_collapsed = !row.is_collapsed">
              <div class="grade-bar-left">
                <span class="grade-bar-name">{{ row.name || '--' }}</span>
                <span class="grade-bar-level-pill">Level {{ row.level }}</span>
                <button type="button" class="btn-bar-toggle" @click.stop="row.is_collapsed = !row.is_collapsed">
                  <ChevronDown v-if="!row.is_collapsed" :size="15" />
                  <ChevronRight v-else :size="15" />
                </button>
              </div>
              <div class="grade-bar-right" @click.stop>
                <button 
                  v-if="gradeRows.length > 1"
                  type="button" 
                  class="btn-card-trash" 
                  @click="removeGradeItem(idx)" 
                  title="Remove Grade Band"
                >
                  <Trash2 :size="14" />
                </button>
              </div>
            </div>

            <!-- Card Body: Form Fields & Steps Table -->
            <div v-if="!row.is_collapsed" class="grade-card-content">
              <!-- 3-Column Inputs: Grade Name, Base Salary, Ceiling Salary -->
              <div class="grade-fields-grid-3">
                <div class="form-field-group">
                  <label class="form-field-label">Grade Name <span class="required-star">*</span></label>
                  <input 
                    type="text" 
                    v-model="row.name" 
                    class="form-input" 
                  />
                </div>

                <div class="form-field-group">
                  <label class="form-field-label">Base Salary</label>
                  <input 
                    type="number" 
                    v-model.number="row.base_salary" 
                    class="form-input font-mono" 
                    @change="autoDistributeRow(row)"
                  />
                </div>

                <div class="form-field-group">
                  <label class="form-field-label">Ceiling Salary</label>
                  <input 
                    type="number" 
                    v-model.number="row.ceiling_salary" 
                    class="form-input font-mono" 
                    @change="autoDistributeRow(row)"
                  />
                </div>
              </div>

              <!-- Full-Width Input: Grade Description -->
              <div class="form-field-group grade-desc-group">
                <label class="form-field-label">Grade Description</label>
                <input 
                  type="text" 
                  v-model="row.description" 
                  class="form-input" 
                />
              </div>

              <!-- Inline Steps Sub-Table (Rule 11) -->
              <div class="grade-steps-table-wrapper">
                <table class="repeater-steps-table">
                  <thead>
                    <tr>
                      <th class="th-no" style="width: 50px;">No.</th>
                      <th class="th-amount">Monthly Amount</th>
                      <th class="th-wait">Wait Year to Qualify</th>
                      <th class="th-actions" style="width: 44px; text-align: right;">
                        <Columns :size="14" class="header-col-icon" />
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(step, sIdx) in row.steps" :key="step.step_number">
                      <td class="td-no">{{ sIdx + 1 }}</td>
                      <td class="td-amount">
                        <div class="step-amount-cell">
                          <input 
                            type="number" 
                            v-model.number="step.amount" 
                            class="step-amount-input font-mono"
                          />
                          <span class="step-currency-label">{{ form.currency_code }}</span>
                        </div>
                      </td>
                      <td class="td-wait">
                        <span v-if="step.step_number === 1" class="step-baseline-text">
                          Entry Baseline
                        </span>
                        <div v-else class="step-wait-input-wrap">
                          <input 
                            type="number" 
                            v-model.number="step.increment_years" 
                            class="step-wait-input font-mono"
                            min="1"
                            max="10"
                          />
                        </div>
                      </td>
                      <td class="td-actions" style="text-align: right;">
                        <button 
                          type="button" 
                          class="btn-step-expand" 
                          @click="openStepModal(step, row)" 
                          title="Expand Step Details"
                        >
                          <Maximize2 :size="13" />
                        </button>
                      </td>
                    </tr>
                  </tbody>
                </table>
                <div class="table-progress-note">
                  Automatic Progress Path Configuration for this Grade.
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Add Grade Band Action -->
        <div class="add-grade-action-row">
          <button type="button" class="btn-add-grade" @click="handleAddGradeRow">
            <Plus :size="14" />
            <span>Add Grade Band</span>
          </button>
        </div>
      </div>
    </div>

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- MODAL: APPLY GLOBAL SCALE ADJUSTMENT (Matching Image 2)        -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <div v-if="showAdjustmentModal" class="modal-backdrop" @click="showAdjustmentModal = false">
      <div class="modal-dialog-box" @click.stop>
        <div class="modal-dialog-header">
          <h3 class="modal-dialog-title">Apply Global Scale Adjestment</h3>
          <button type="button" class="btn-modal-close" @click="showAdjustmentModal = false">
            <X :size="16" />
          </button>
        </div>

        <div class="modal-dialog-body">
          <p class="modal-desc-text">
            Apply a percentage increase or decrease across all grade rows and their step amounts. Useful for cost of living adjustments or fiscal-year scale revisions.
          </p>

          <div class="modal-input-group">
            <label class="modal-input-label">Adjustment Percentage (%)</label>
            <input 
              type="number" 
              v-model.number="adjustmentPercent" 
              class="modal-text-input font-mono" 
              placeholder="0"
            />
          </div>
        </div>

        <div class="modal-dialog-footer">
          <button type="button" class="btn-modal-primary" @click="handleApplyAdjustment">
            Apply Adjustment
          </button>
        </div>
      </div>
    </div>

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- MODAL: EXPAND STEP ROW MODAL (Rule 11 Expand Modal)            -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <div v-if="showStepModal && activeStepData" class="modal-backdrop" @click="showStepModal = false">
      <div class="modal-dialog-box" @click.stop>
        <div class="modal-dialog-header">
          <h3 class="modal-dialog-title">{{ activeStepData.gradeName }} — Step {{ activeStepData.stepNumber }}</h3>
          <button type="button" class="btn-modal-close" @click="showStepModal = false">
            <X :size="16" />
          </button>
        </div>

        <div class="modal-dialog-body">
          <div class="form-grid-2">
            <div class="form-field-group">
              <label class="form-field-label">Monthly Amount ({{ form.currency_code }})</label>
              <input 
                type="number" 
                v-model.number="activeStepData.amount" 
                class="form-input font-mono" 
              />
            </div>
            <div class="form-field-group">
              <label class="form-field-label">Wait Years to Qualify</label>
              <input 
                v-if="activeStepData.stepNumber > 1"
                type="number" 
                v-model.number="activeStepData.incrementYears" 
                class="form-input font-mono" 
                min="1"
                max="10"
              />
              <input 
                v-else
                type="text" 
                value="Entry Baseline" 
                class="form-input" 
                disabled 
              />
            </div>
          </div>

          <div class="form-field-group mt-3">
            <label class="form-field-label">Progression Description</label>
            <input 
              type="text" 
              v-model="activeStepData.description" 
              class="form-input" 
            />
          </div>
        </div>

        <div class="modal-dialog-footer">
          <button type="button" class="btn-modal-primary" @click="saveStepModal">
            Save Details
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* ═══════════════════════════════════════════ */
/* SALARY SCALE CREATE PAGE                     */
/* ═══════════════════════════════════════════ */

.scale-create-page {
  min-height: 100vh;
  padding: 24px 28px 60px;
  background-color: #f8fafc;
}

/* ═══ TOP ACTION BAR ═══ */
.top-action-bar {
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

.save-status-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  font-size: 11px;
  font-weight: 600;
  border-radius: 4px;
}
.status-unsaved {
  background-color: #fef3c7;
  color: #d97706;
}
.status-saved {
  background-color: #ecfdf5;
  color: #059669;
}

.top-bar-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.btn-secondary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 14px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-secondary-action:hover {
  background-color: #f1f5f9;
  border-color: #cbd5e1;
}

.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 18px;
  background: #0B529C;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #ffffff;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-primary-action:hover {
  background-color: #09427d;
}

/* ═══ TOAST BANNER ═══ */
.quick-toast-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  margin-bottom: 16px;
  background-color: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  color: #065f46;
  font-size: 13px;
  animation: fadeIn 0.2s ease;
}
.toast-icon { color: #059669; }

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-4px); }
  to { opacity: 1; transform: translateY(0); }
}

/* ═══ PRIMARY TABS (<BaseTabs /> Capsule Container) ═══ */
.page-tabs-container {
  margin-bottom: 18px;
}

/* ═══ CARD BASES ═══ */
.clean-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}

/* ═══ TAB 1: SALARY SCALE DETAIL (Matching Image 5) ═══ */
.scale-detail-card {
  padding: 22px 24px 28px;
}

.card-section-title {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 20px;
}

.scale-form-content {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

@media (max-width: 860px) {
  .form-grid-3,
  .form-grid-2 {
    grid-template-columns: 1fr;
  }
}

.form-field-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.form-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.required-star {
  color: #ef4444;
}

.form-input {
  width: 100%;
  height: 38px;
  padding: 0 12px;
  font-size: 13.5px;
  color: #404040;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  transition: border-color 0.15s, box-shadow 0.15s;
}
.form-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
  outline: none;
}

.form-select {
  width: 100%;
  height: 38px;
  padding: 0 12px;
  font-size: 13.5px;
  color: #404040;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  transition: border-color 0.15s, box-shadow 0.15s;
  appearance: auto;
}
.form-select:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
  outline: none;
}

.date-input-wrap {
  position: relative;
  display: flex;
  align-items: center;
}
.date-icon {
  position: absolute;
  left: 10px;
  color: #737373;
  pointer-events: none;
  z-index: 1;
}
.date-input {
  padding: 0 40px 0 32px;
}
.gc-pill-tag {
  position: absolute;
  right: 8px;
  padding: 2px 6px;
  background: #e0f2fe;
  color: #0284c7;
  font-size: 10.5px;
  font-weight: 600;
  border-radius: 4px;
  letter-spacing: 0.5px;
}

.form-checkbox-row {
  margin-top: 4px;
}

/* ═══ TAB 2: PAY GRADE & STEPS (Matching Image 3) ═══ */
.pay-grades-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.pay-grades-master-card {
  padding: 22px 24px 28px;
}

.pay-grades-header-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 20px;
  margin-bottom: 22px;
}

.pay-grades-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.pay-grades-subtitle {
  font-size: 12.5px;
  color: #737373;
  line-height: 1.5;
  margin: 4px 0 0;
  max-width: 720px;
}

.btn-adjust-all {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 34px;
  padding: 0 14px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.15s ease;
}
.btn-adjust-all:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
  color: #0B529C;
}
.btn-icon-pct {
  color: #737373;
}

/* Stacked Repeater Cards */
.grade-cards-repeater {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-bottom: 16px;
}

.grade-repeater-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 18px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
  transition: border-color 0.15s ease;
}
.grade-repeater-card:hover {
  border-color: #cbd5e1;
}

.grade-card-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: pointer;
  user-select: none;
  padding: 2px 0;
}

.grade-bar-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.grade-bar-name {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.grade-bar-level-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  background-color: #e0f2fe;
  color: #0284c7;
  font-size: 11px;
  font-weight: 600;
  border-radius: 9999px;
}

.btn-bar-toggle {
  display: inline-flex;
  align-items: center;
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
}

.btn-card-trash {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  color: #94a3b8;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-card-trash:hover {
  color: #ef4444;
  background-color: #fee2e2;
}

.grade-card-content {
  margin-top: 14px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.grade-fields-grid-3 {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr;
  gap: 14px;
}

@media (max-width: 800px) {
  .grade-fields-grid-3 {
    grid-template-columns: 1fr;
  }
}

.grade-desc-group {
  width: 100%;
}

/* Steps Sub-Table */
.grade-steps-table-wrapper {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
}

.repeater-steps-table {
  width: 100%;
  border-collapse: collapse;
}

.repeater-steps-table th {
  height: 34px;
  padding: 6px 14px;
  background-color: #fafafa;
  color: #737373;
  font-size: 12px;
  font-weight: 500;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

.repeater-steps-table td {
  height: 38px;
  padding: 6px 14px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.repeater-steps-table tr:last-child td {
  border-bottom: none;
}

.td-no {
  font-weight: 500;
  color: #737373;
}

.step-amount-cell {
  display: flex;
  align-items: center;
  gap: 6px;
}

.step-amount-input {
  width: 110px;
  height: 30px;
  padding: 0 8px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 13px;
  color: #404040;
  background: #ffffff;
}
.step-amount-input:focus {
  border-color: #0B529C;
  outline: none;
}

.step-currency-label {
  font-size: 11.5px;
  font-weight: 500;
  color: #737373;
}

.step-baseline-text {
  font-size: 12.5px;
  color: #737373;
}

.step-wait-input-wrap {
  display: flex;
  align-items: center;
}

.step-wait-input {
  width: 60px;
  height: 30px;
  padding: 0 8px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 13px;
  color: #404040;
  background: #ffffff;
}
.step-wait-input:focus {
  border-color: #0B529C;
  outline: none;
}

.header-col-icon {
  color: #737373;
}

.btn-step-expand {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  border: none;
  background: transparent;
  color: #737373;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-step-expand:hover {
  background-color: #f1f5f9;
  color: #0B529C;
}

.table-progress-note {
  padding: 10px 14px;
  font-size: 12px;
  color: #737373;
  border-top: 1px solid #f1f5f9;
  background-color: #ffffff;
}

.add-grade-action-row {
  margin-top: 4px;
}

.btn-add-grade {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 34px;
  padding: 0 14px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-add-grade:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
  color: #0B529C;
}

/* ═══ MODAL: APPLY GLOBAL SCALE ADJUSTMENT (Matching Image 2) ═══ */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.4);
  backdrop-filter: blur(2px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 999;
  padding: 16px;
}

.modal-dialog-box {
  background: #ffffff;
  border-radius: 12px;
  width: 100%;
  max-width: 520px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  animation: modalPop 0.18s ease-out;
}

@keyframes modalPop {
  from { transform: scale(0.96); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}

.modal-dialog-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 22px 14px;
}

.modal-dialog-title {
  font-size: 16px;
  font-weight: 600;
  color: #0f172a;
  margin: 0;
}

.btn-modal-close {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  color: #64748b;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-modal-close:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.modal-dialog-body {
  padding: 0 22px 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.modal-desc-text {
  font-size: 13px;
  color: #64748b;
  line-height: 1.5;
  margin: 0;
}

.modal-input-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.modal-input-label {
  font-size: 13px;
  font-weight: 500;
  color: #334155;
}

.modal-text-input {
  width: 100%;
  height: 40px;
  padding: 0 12px;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  font-size: 14px;
  color: #0f172a;
  background-color: #ffffff;
  transition: border-color 0.15s, box-shadow 0.15s;
}
.modal-text-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.1);
  outline: none;
}

.modal-dialog-footer {
  padding: 14px 22px 18px;
  border-top: 1px solid #f1f5f9;
  display: flex;
  justify-content: flex-end;
}

.btn-modal-primary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 38px;
  padding: 0 20px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-modal-primary:hover {
  background-color: #09427d;
}

/* Helpers */
.font-mono { font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', monospace; }
.mt-3 { margin-top: 12px; }
</style>
