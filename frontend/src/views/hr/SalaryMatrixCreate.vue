<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { 
  Monitor, ChevronRight, X, Sliders, Award,
  Plus, Trash2, Calendar, ChevronDown, Columns,
  Maximize2, Check, Calculator, Sparkles, Grid, Eye, Edit3,
  Percent, ArrowRight, Download, Printer
} from 'lucide-vue-next';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';

const router = useRouter();
const route = useRoute();

// ─── Mode: Interactive Editor vs Official Document View ───
type ViewMode = 'edit' | 'preview';
const viewMode = ref<ViewMode>('edit');

// ─── Document State ───
const isSaved = ref(false);
const quickActionToast = ref<string | null>(null);
const showAdjustmentModal = ref(false);
const adjustmentPercent = ref(10);

// ─── Master Matrix Header State (HR_Schema_final-v4.sql lines 1044–1064 - ZERO PHANTOM NAME) ───
const form = ref({
  entity_id: 'Haleta Addis Ababa HQ',
  currency_code: 'ETB',
  number_of_steps: 9, // Exactly 9 steps like the official transition table!
  effective_from: new Date().toISOString().split('T')[0],
  effective_to: '',
  is_default: true
});

// ─── Step Definition for each Grade ───
export interface GridStepCell {
  step_number: number;
  amount: number;
  increment_years?: number | null;
  description?: string;
}

// ─── Grade Row in the 2D Grid (HR_Schema_final-v4.sql lines 1065–1087) ───
export interface MatrixGridRow {
  id: number;
  code: string;           // e.g. "I", "II", "III", "IV" or "C1", "B2"
  name: string;           // localized title
  level: number;          // seniority order
  base_salary: number;    // Starting / መነሻ ደመወዝ
  steps: GridStepCell[];  // Steps 1..N / የእርከን ደመወዝ
  ceiling_salary: number; // Ceiling cap / ጣሪያ
}

// ─── Mock Data: Inspired Directly by the Official Real-Life Transition Table Document ───
const gridRows = ref<MatrixGridRow[]>([
  {
    id: 1,
    code: 'Grade I',
    name: 'Operational Support Band',
    level: 1,
    base_salary: 4760,
    ceiling_salary: 4760,
    steps: [
      { step_number: 1, amount: 4760, increment_years: null, description: 'Entry' },
      { step_number: 2, amount: 4760, increment_years: 2, description: 'Step 2' },
      { step_number: 3, amount: 4760, increment_years: 2, description: 'Step 3' },
      { step_number: 4, amount: 4760, increment_years: 2, description: 'Step 4' },
      { step_number: 5, amount: 4760, increment_years: 2, description: 'Step 5' },
      { step_number: 6, amount: 4760, increment_years: 2, description: 'Step 6' },
      { step_number: 7, amount: 4760, increment_years: 2, description: 'Step 7' },
      { step_number: 8, amount: 4760, increment_years: 2, description: 'Step 8' },
      { step_number: 9, amount: 4760, increment_years: 2, description: 'Ceiling' }
    ]
  },
  {
    id: 2,
    code: 'Grade II',
    name: 'Frontline Administrative Support',
    level: 2,
    base_salary: 4929,
    ceiling_salary: 4929,
    steps: [
      { step_number: 1, amount: 4929, increment_years: null, description: 'Entry' },
      { step_number: 2, amount: 4929, increment_years: 2, description: 'Step 2' },
      { step_number: 3, amount: 4929, increment_years: 2, description: 'Step 3' },
      { step_number: 4, amount: 4929, increment_years: 2, description: 'Step 4' },
      { step_number: 5, amount: 4929, increment_years: 2, description: 'Step 5' },
      { step_number: 6, amount: 4929, increment_years: 2, description: 'Step 6' },
      { step_number: 7, amount: 4929, increment_years: 2, description: 'Step 7' },
      { step_number: 8, amount: 4929, increment_years: 2, description: 'Step 8' },
      { step_number: 9, amount: 4929, increment_years: 2, description: 'Ceiling' }
    ]
  },
  {
    id: 3,
    code: 'Grade III',
    name: 'Technical & Clerical Staff',
    level: 3,
    base_salary: 5104,
    ceiling_salary: 5104,
    steps: [
      { step_number: 1, amount: 5104, increment_years: null, description: 'Entry' },
      { step_number: 2, amount: 5104, increment_years: 2, description: 'Step 2' },
      { step_number: 3, amount: 5104, increment_years: 2, description: 'Step 3' },
      { step_number: 4, amount: 5104, increment_years: 2, description: 'Step 4' },
      { step_number: 5, amount: 5104, increment_years: 2, description: 'Step 5' },
      { step_number: 6, amount: 5104, increment_years: 2, description: 'Step 6' },
      { step_number: 7, amount: 5104, increment_years: 2, description: 'Step 7' },
      { step_number: 8, amount: 5104, increment_years: 2, description: 'Step 8' },
      { step_number: 9, amount: 5104, increment_years: 2, description: 'Ceiling' }
    ]
  },
  {
    id: 4,
    code: 'Grade IV',
    name: 'Senior Clerical & Assistant Officers',
    level: 4,
    base_salary: 5283,
    ceiling_salary: 5283,
    steps: [
      { step_number: 1, amount: 5283, increment_years: null, description: 'Entry' },
      { step_number: 2, amount: 5283, increment_years: 2, description: 'Step 2' },
      { step_number: 3, amount: 5283, increment_years: 2, description: 'Step 3' },
      { step_number: 4, amount: 5283, increment_years: 2, description: 'Step 4' },
      { step_number: 5, amount: 5283, increment_years: 2, description: 'Step 5' },
      { step_number: 6, amount: 5283, increment_years: 2, description: 'Step 6' },
      { step_number: 7, amount: 5283, increment_years: 2, description: 'Step 7' },
      { step_number: 8, amount: 5283, increment_years: 2, description: 'Step 8' },
      { step_number: 9, amount: 5283, increment_years: 2, description: 'Ceiling' }
    ]
  },
  {
    id: 5,
    code: 'Grade V',
    name: 'Professional Officers & Specialists',
    level: 5,
    base_salary: 5659,
    ceiling_salary: 5659,
    steps: [
      { step_number: 1, amount: 5659, increment_years: null, description: 'Entry' },
      { step_number: 2, amount: 5659, increment_years: 2, description: 'Step 2' },
      { step_number: 3, amount: 5659, increment_years: 2, description: 'Step 3' },
      { step_number: 4, amount: 5659, increment_years: 2, description: 'Step 4' },
      { step_number: 5, amount: 5659, increment_years: 2, description: 'Step 5' },
      { step_number: 6, amount: 5659, increment_years: 2, description: 'Step 6' },
      { step_number: 7, amount: 5659, increment_years: 2, description: 'Step 7' },
      { step_number: 8, amount: 5659, increment_years: 2, description: 'Step 8' },
      { step_number: 9, amount: 5659, increment_years: 2, description: 'Ceiling' }
    ]
  },
  {
    id: 6,
    code: 'Grade VI',
    name: 'Senior Officers & Team Leads',
    level: 6,
    base_salary: 6058,
    ceiling_salary: 6058,
    steps: [
      { step_number: 1, amount: 6058, increment_years: null, description: 'Entry' },
      { step_number: 2, amount: 6058, increment_years: 2, description: 'Step 2' },
      { step_number: 3, amount: 6058, increment_years: 2, description: 'Step 3' },
      { step_number: 4, amount: 6058, increment_years: 2, description: 'Step 4' },
      { step_number: 5, amount: 6058, increment_years: 2, description: 'Step 5' },
      { step_number: 6, amount: 6058, increment_years: 2, description: 'Step 6' },
      { step_number: 7, amount: 6058, increment_years: 2, description: 'Step 7' },
      { step_number: 8, amount: 6058, increment_years: 2, description: 'Step 8' },
      { step_number: 9, amount: 6058, increment_years: 2, description: 'Ceiling' }
    ]
  },
  {
    id: 7,
    code: 'Grade VII',
    name: 'Section Heads & Principals',
    level: 7,
    base_salary: 6485,
    ceiling_salary: 6709,
    steps: [
      { step_number: 1, amount: 6485, increment_years: null, description: 'Entry' },
      { step_number: 2, amount: 6485, increment_years: 2, description: 'Step 2' },
      { step_number: 3, amount: 6485, increment_years: 2, description: 'Step 3' },
      { step_number: 4, amount: 6485, increment_years: 2, description: 'Step 4' },
      { step_number: 5, amount: 6485, increment_years: 2, description: 'Step 5' },
      { step_number: 6, amount: 6485, increment_years: 2, description: 'Step 6' },
      { step_number: 7, amount: 6485, increment_years: 2, description: 'Step 7' },
      { step_number: 8, amount: 6485, increment_years: 2, description: 'Step 8' },
      { step_number: 9, amount: 6709, increment_years: 2, description: 'Ceiling' }
    ]
  },
  {
    id: 8,
    code: 'Grade VIII',
    name: 'Department Managers & Division Directors',
    level: 8,
    base_salary: 6940,
    ceiling_salary: 7676,
    steps: [
      { step_number: 1, amount: 6940, increment_years: null, description: 'Entry' },
      { step_number: 2, amount: 6940, increment_years: 2, description: 'Step 2' },
      { step_number: 3, amount: 6940, increment_years: 2, description: 'Step 3' },
      { step_number: 4, amount: 6940, increment_years: 2, description: 'Step 4' },
      { step_number: 5, amount: 6940, increment_years: 2, description: 'Step 5' },
      { step_number: 6, amount: 6940, increment_years: 2, description: 'Step 6' },
      { step_number: 7, amount: 6940, increment_years: 2, description: 'Step 7' },
      { step_number: 8, amount: 7424, increment_years: 2, description: 'Step 8' },
      { step_number: 9, amount: 7676, increment_years: 2, description: 'Ceiling' }
    ]
  }
]);

// ─── Reactive Steps Count Synchronization ───
const handleStepsCountChange = () => {
  const targetSteps = Number(form.value.number_of_steps);
  gridRows.value.forEach(row => {
    // If expanding
    while (row.steps.length < targetSteps) {
      const nextNo = row.steps.length + 1;
      const prevAmount = row.steps.length > 0 ? row.steps[row.steps.length - 1].amount : row.base_salary;
      row.steps.push({
        step_number: nextNo,
        amount: prevAmount,
        increment_years: 2,
        description: nextNo === targetSteps ? 'Ceiling' : `Step ${nextNo}`
      });
    }
    // If trimming
    if (row.steps.length > targetSteps) {
      row.steps = row.steps.slice(0, targetSteps);
    }
  });
  showToast(`Adjusted matrix grid dimension to ${targetSteps} progression steps.`);
};

// Add a new Grade Row at the bottom
const handleAddGradeRow = () => {
  const nextLevel = gridRows.value.length + 1;
  const romanNumerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII', 'XIII', 'XIV', 'XV'];
  const code = nextLevel <= romanNumerals.length ? `Grade ${romanNumerals[nextLevel - 1]}` : `Grade ${nextLevel}`;

  const targetSteps = Number(form.value.number_of_steps);
  const lastBase = gridRows.value.length > 0 ? gridRows.value[gridRows.value.length - 1].base_salary : 4000;
  const newBase = Math.round(lastBase * 1.08);
  const newCeiling = Math.round(newBase * 1.15);

  const steps: GridStepCell[] = [];
  for (let s = 1; s <= targetSteps; s++) {
    steps.push({
      step_number: s,
      amount: newBase,
      increment_years: s === 1 ? null : 2,
      description: s === 1 ? 'Entry' : s === targetSteps ? 'Ceiling' : `Step ${s}`
    });
  }

  gridRows.value.push({
    id: Date.now() + nextLevel,
    code,
    name: 'New Grade Band',
    level: nextLevel,
    base_salary: newBase,
    ceiling_salary: newCeiling,
    steps
  });

  showToast(`Added ${code} to matrix grid.`);
};

// Remove Grade Row
const handleRemoveRow = (idx: number) => {
  if (gridRows.value.length <= 1) {
    alert('A salary matrix must contain at least one pay grade row.');
    return;
  }
  const removed = gridRows.value.splice(idx, 1)[0];
  // Re-level
  gridRows.value.forEach((r, i) => {
    r.level = i + 1;
  });
  showToast(`Removed ${removed.code} from matrix grid.`);
};

// Linear step interpolation for a single row
const autoDistributeRow = (row: MatrixGridRow) => {
  const stepsCount = row.steps.length;
  if (stepsCount <= 1) return;
  const min = Number(row.base_salary);
  const max = Number(row.ceiling_salary);
  const inc = (max - min) / (stepsCount - 1);

  row.steps.forEach((s, i) => {
    s.amount = Math.round(min + (i * inc));
  });
  showToast(`Calculated linear progression ladder for ${row.code}.`);
};

// Global Scale Adjustment (% across the entire matrix transition table)
const applyGlobalAdjustment = () => {
  const pct = Number(adjustmentPercent.value);
  if (isNaN(pct) || pct === 0) return;
  const multiplier = 1 + (pct / 100);

  gridRows.value.forEach(row => {
    row.base_salary = Math.round(row.base_salary * multiplier);
    row.ceiling_salary = Math.round(row.ceiling_salary * multiplier);
    row.steps.forEach(s => {
      s.amount = Math.round(s.amount * multiplier);
    });
  });

  showAdjustmentModal.value = false;
  showToast(`Applied ${pct > 0 ? '+' : ''}${pct}% adjustment across the entire salary matrix transition grid.`);
};

// ─── Format Currency ───
const formatETB = (val: number) => {
  return new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2
  }).format(val);
};

// ─── Save Salary Matrix ───
const handleSave = () => {
  if (!form.value.entity_id) {
    showToast('Please select Owning Entity.');
    return;
  }

  isSaved.value = true;
  showToast(`Salary Matrix for "${form.value.entity_id}" successfully published with ${gridRows.value.length} grades and ${form.value.number_of_steps} steps.`);

  setTimeout(() => {
    router.push('/hr/salary-matrices');
  }, 1200);
};

const clearForm = () => {
  form.value = {
    entity_id: 'Haleta Addis Ababa HQ',
    currency_code: 'ETB',
    number_of_steps: 9,
    effective_from: new Date().toISOString().split('T')[0],
    effective_to: '',
    is_default: true
  };
  isSaved.value = false;
  showToast('Salary matrix grid reset.');
};

const showToast = (msg: string) => {
  quickActionToast.value = msg;
  setTimeout(() => {
    quickActionToast.value = null;
  }, 4000);
};

onMounted(() => {
  if (route.query.entity) form.value.entity_id = String(route.query.entity);
  if (route.query.steps) {
    form.value.number_of_steps = Number(route.query.steps);
    handleStepsCountChange();
  }
  if (route.query.effective_from) form.value.effective_from = String(route.query.effective_from);
  if (route.query.mode === 'preview') viewMode.value = 'preview';
});
</script>

<template>
  <div class="salary-matrix-grid-page">
    <!-- Top Action & Breadcrumb Navigation Bar -->
    <div class="create-header-bar">
      <div class="header-left">
        <div class="breadcrumb-strip">
          <router-link to="/home" class="bc-home-icon" title="Home">
            <Monitor :size="15" />
          </router-link>
          <ChevronRight :size="13" class="bc-sep" />
          <router-link to="/hr/salary-matrices" class="bc-link">Salary Matrices</router-link>
          <ChevronRight :size="13" class="bc-sep" />
          <span class="bc-current">{{ form.entity_id || 'Entity' }} — Pay Scale Matrix</span>
          <span :class="['state-pill', isSaved ? 'state-saved' : 'state-unsaved']">
            {{ isSaved ? 'Saved' : 'Draft / Unsaved' }}
          </span>
        </div>
      </div>

      <div class="header-actions">
        <!-- Mode Switcher: Edit Grid vs Official Preview -->
        <div class="top-meta-badge">
          <Sliders :size="14" class="text-blue-600" />
          <span class="meta-label font-medium">Compensation Matrix Builder</span>
        </div>

        <button 
          type="button" 
          class="btn-clear-action" 
          @click="clearForm"
        >
          <X :size="14" />
          <span>Reset Grid</span>
        </button>
        
        <button 
          type="button" 
          class="btn-save-action" 
          @click="handleSave"
        >
          <Check :size="14" />
          <span>Save Salary Matrix</span>
        </button>
      </div>
    </div>

    <!-- Quick Toast Banner -->
    <div v-if="quickActionToast" class="quick-toast-banner">
      <span>{{ quickActionToast }}</span>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- MASTER HEADER PARAMETERS CARD (Strict SalaryMatrix Schema)    -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div class="clean-card parameters-card">
      <div class="parameters-grid">
        <!-- Owning Entity: schema line 1048 -->
        <div class="param-item">
          <label class="param-label">Owning Entity <span class="required-star">*</span></label>
          <select v-model="form.entity_id" class="param-select">
            <option value="Haleta Addis Ababa HQ">Haleta Addis Ababa HQ</option>
            <option value="Haleta Grand Hotel & Suites">Haleta Grand Hotel & Suites</option>
            <option value="Haleta Hawassa Hub">Haleta Hawassa Hub</option>
          </select>
        </div>

        <!-- Effective From Date with [GC] Tag: schema line 1049 -->
        <div class="param-item">
          <label class="param-label">Effective From Date <span class="required-star">*</span></label>
          <div class="date-input-wrap">
            <Calendar :size="14" class="date-icon" />
            <input 
              type="date" 
              v-model="form.effective_from" 
              class="param-date-input" 
              required 
            />
            <span class="gc-pill-tag">GC</span>
          </div>
        </div>

        <!-- Effective To Date with [GC] Tag (Nullable): schema line 1050 -->
        <div class="param-item">
          <label class="param-label">Effective To Date (Successor Window)</label>
          <div class="date-input-wrap">
            <Calendar :size="14" class="date-icon" />
            <input 
              type="date" 
              v-model="form.effective_to" 
              class="param-date-input" 
            />
            <span class="gc-pill-tag">GC</span>
          </div>
        </div>

        <!-- Number of Steps: schema line 1051 -->
        <div class="param-item">
          <label class="param-label">Grid Steps Dimension</label>
          <select 
            v-model="form.number_of_steps" 
            class="param-select" 
            @change="handleStepsCountChange"
          >
            <option :value="5">5 Steps Ladder</option>
            <option :value="7">7 Steps Ladder</option>
            <option :value="9">9 Steps Ladder (Official Scale)</option>
            <option :value="10">10 Steps Ladder</option>
          </select>
        </div>

        <!-- Currency: schema line 1052 -->
        <div class="param-item">
          <label class="param-label">Currency</label>
          <div class="currency-readonly-badge">
            <span class="font-mono font-semibold">{{ form.currency_code }}</span>
            <span class="currency-subtext">Ethiopian Birr</span>
          </div>
        </div>

        <!-- Default Matrix: schema line 1053 -->
        <div class="param-item-check">
          <label class="param-label">Governance Baseline</label>
          <FormCheckbox
            v-model="form.is_default"
            label="Default Salary Matrix"
            description="Designates this compensation grid as the active pay baseline for newly attached job grades."
          />
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- THE 2D SALARY MATRIX GRID (Inspired by Real-Life Scale)       -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div class="clean-card matrix-grid-card">
      <!-- Grid Toolbar -->
      <div class="grid-toolbar-strip">
        <div class="toolbar-left">
          <div class="document-badge-stack">
            <span class="doc-badge-primary">Salary Scale Matrix Grid</span>
            <span class="doc-badge-meta">{{ form.entity_id }} • {{ form.effective_from }} — {{ form.effective_to || 'Current' }}</span>
          </div>
        </div>

        <div class="toolbar-right">
          <!-- Add Grade Row Button -->
          <button 
            type="button" 
            class="btn-grid-tool" 
            @click="handleAddGradeRow"
          >
            <Plus :size="14" />
            <span>Add Grade Row</span>
          </button>

          <!-- Scale % Adjustment Button (Transition Table Feature) -->
          <button 
            type="button" 
            class="btn-grid-tool" 
            @click="showAdjustmentModal = true"
          >
            <Percent :size="13" />
            <span>Apply % Adjustment</span>
          </button>
        </div>
      </div>

      <!-- ─── INTERACTIVE SPREADSHEET GRID ─── -->
      <div class="grid-table-viewport">
        <table class="salary-spreadsheet-grid">
          <thead>
            <tr>
              <th class="th-fixed th-grade">Grade / Band</th>
              <th class="th-fixed th-desc">Grade Title / Role</th>
              <th class="th-fixed th-level">Level</th>
              <th class="th-fixed th-base">Base Floor (ETB)</th>
              
              <!-- Dynamic Step Columns (1 to N) -->
              <th 
                v-for="s in Number(form.number_of_steps)" 
                :key="s" 
                class="th-step-col"
              >
                <div class="th-step-header">
                  <span class="step-th-title">Step {{ s }}</span>
                </div>
              </th>

              <th class="th-fixed th-ceiling">Ceiling Salary (ETB)</th>
              <th class="th-fixed th-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(row, idx) in gridRows" :key="row.id" class="grid-body-row">
              <!-- Grade Code (e.g. Grade I, Grade II) -->
              <td class="td-grade-cell">
                <input 
                  type="text" 
                  v-model="row.code" 
                  class="cell-input-code"
                />
              </td>

              <!-- Grade Title -->
              <td class="td-desc-cell">
                <input 
                  type="text" 
                  v-model="row.name" 
                  class="cell-input-text"
                />
              </td>

              <!-- Seniority Level -->
              <td class="td-level-cell">
                <input 
                  type="number" 
                  v-model.number="row.level" 
                  class="cell-input-level"
                  min="1"
                  max="20"
                />
              </td>

              <!-- Base Starting Floor -->
              <td class="td-num-cell">
                <input 
                  type="number" 
                  v-model.number="row.base_salary" 
                  class="cell-input-num font-mono"
                  @change="autoSpreadRow(row)"
                />
              </td>

              <!-- Dynamic Step Cells (1 to N) -->
              <td 
                v-for="s in Number(form.number_of_steps)" 
                :key="s" 
                class="td-num-cell td-step-cell"
              >
                <input 
                  v-if="row.steps[s - 1]"
                  type="number" 
                  v-model.number="row.steps[s - 1].amount" 
                  class="cell-input-num font-mono cell-step-amount"
                />
              </td>

              <!-- Ceiling Salary -->
              <td class="td-num-cell">
                <input 
                  type="number" 
                  v-model.number="row.ceiling_salary" 
                  class="cell-input-num font-mono"
                  @change="autoSpreadRow(row)"
                />
              </td>

              <!-- Row Action Tools -->
              <td class="td-actions-cell">
                <div class="row-tools-wrap">
                  <button 
                    type="button" 
                    class="btn-row-action" 
                    title="Auto-spread linear progression"
                    @click="autoSpreadRow(row)"
                  >
                    <Calculator :size="13" />
                  </button>
                  <button 
                    type="button" 
                    class="btn-row-action btn-del" 
                    title="Remove row"
                    @click="handleRemoveGradeRow(row.id)"
                  >
                    <Trash2 :size="13" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- GLOBAL ADJUSTMENT MODAL (% Transition Calculator) -->
    <div v-if="showAdjustmentModal" class="adjustment-modal-backdrop" @click="showAdjustmentModal = false">
      <div class="adjustment-modal-box" @click.stop>
        <div class="modal-header">
          <h3 class="modal-title">Apply Global Scale Adjustment</h3>
          <button type="button" class="btn-close" @click="showAdjustmentModal = false"><X :size="16" /></button>
        </div>

        <div class="modal-body">
          <p class="modal-intro">
            Simulate a general salary increase or cost-of-living scale revision (like the Transition Table in the official document).
          </p>

          <div class="input-field-group">
            <label class="field-label">Adjustment Percentage (%)</label>
            <div class="pct-input-wrap">
              <input 
                type="number" 
                v-model.number="adjustmentPercent" 
                class="pct-input" 
                step="1"
              />
              <span class="pct-symbol">%</span>
            </div>
            <span class="field-hint">e.g. enter 15 for a +15% across-the-board transition revision.</span>
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn-cancel" @click="showAdjustmentModal = false">Cancel</button>
          <button type="button" class="btn-apply" @click="applyGlobalAdjustment">Apply Adjustment</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.salary-matrix-grid-page {
  padding: 20px 32px 64px 32px;
  background-color: #f8fafc;
  min-height: 100vh;
}

/* Header & Breadcrumbs */
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
  gap: 12px;
}

/* Mode Switcher */
.mode-toggle-group {
  display: inline-flex;
  background-color: #f1f5f9;
  border-radius: 8px;
  padding: 3px;
  gap: 2px;
}

.mode-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 12px;
  border: none;
  background: transparent;
  color: #64748b;
  font-size: 12.5px;
  font-weight: 500;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.mode-btn-active {
  background-color: #ffffff;
  color: #0B529C;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.btn-clear-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
}

.btn-clear-action:hover {
  background-color: #f8fafc;
}

.btn-save-action {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  height: 38px;
  padding: 0 20px;
  background-color: #0B529C;
  border: none;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  color: #ffffff;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(11, 82, 156, 0.2);
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

/* Parameters Card */
.clean-card {
  background-color: #ffffff;
  border-radius: 12px;
  border: 1px solid #f1f5f9;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.parameters-card {
  padding: 18px 24px;
  margin-bottom: 20px;
}

.parameters-grid {
  display: grid;
  grid-template-columns: 1.4fr 1.1fr 1.1fr 1.2fr 0.9fr 1.5fr;
  gap: 16px;
  align-items: flex-end;
}

.param-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.param-label {
  font-size: 12px;
  font-weight: 500;
  color: #737373;
}

.required-star {
  color: #e11d48;
}

.param-select {
  height: 38px;
  padding: 0 28px 0 10px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
  cursor: pointer;
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='14' height='14' viewBox='0 0 24 24' fill='none' stroke='%23737373' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='m6 9 6 6 6-6'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 8px center;
}

.param-select:focus {
  border-color: #0B529C;
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
}

.param-date-input {
  width: 100%;
  height: 38px;
  padding: 0 40px 0 32px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  color: #404040;
  outline: none;
}

.param-date-input:focus {
  border-color: #0B529C;
}

.gc-pill-tag {
  position: absolute;
  right: 8px;
  background-color: #eff6ff;
  color: #0284c7;
  font-size: 10px;
  font-weight: 600;
  padding: 2px 5px;
  border-radius: 4px;
}

.currency-readonly-badge {
  height: 38px;
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 0 12px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
}

.currency-subtext {
  font-size: 11px;
  color: #737373;
}

.param-item-check {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

/* 2D Matrix Grid Card */
.matrix-grid-card {
  padding: 20px 24px;
  overflow: hidden;
}

.grid-toolbar-strip {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 16px;
  border-bottom: 1px solid #f1f5f9;
  margin-bottom: 16px;
}

.document-badge-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.doc-badge-primary {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.doc-badge-meta {
  font-size: 12px;
  color: #737373;
}

.toolbar-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-grid-tool {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 34px;
  padding: 0 14px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-grid-tool:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

/* ─── 1. SPREADSHEET-STYLE INTERACTIVE GRID ─── */
.grid-table-viewport {
  overflow-x: auto;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}

.salary-spreadsheet-grid {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  background-color: #ffffff;
}

.salary-spreadsheet-grid th {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 8px 10px;
  font-size: 12px;
  font-weight: 600;
  color: #475569;
  text-align: left;
  white-space: nowrap;
}

.th-grade {
  width: 110px;
}

.th-desc {
  min-width: 200px;
}

.th-level {
  width: 60px;
  text-align: center !important;
}

.th-base,
.th-ceiling {
  width: 120px;
  text-align: right !important;
}

.th-step-col {
  min-width: 105px;
  text-align: right !important;
}

.th-step-header {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 1px;
}

.step-th-title {
  font-weight: 600;
}

.step-th-amharic {
  font-size: 10px;
  color: #94a3b8;
}

.th-actions {
  width: 70px;
  text-align: center !important;
}

.salary-spreadsheet-grid td {
  border: 1px solid #e2e8f0;
  padding: 4px 6px;
  vertical-align: middle;
}

.grid-body-row:hover {
  background-color: #fafbfd;
}

/* Cell Inputs */
.cell-input-code,
.cell-input-text,
.cell-input-level,
.cell-input-numeric {
  height: 32px;
  width: 100%;
  border: 1px solid transparent;
  border-radius: 4px;
  padding: 0 6px;
  font-size: 12.5px;
  color: #404040;
  background-color: transparent;
  outline: none;
  transition: all 0.15s ease;
}

.cell-input-code {
  font-weight: 600;
  color: #0B529C;
}

.cell-input-level {
  text-align: center;
}

.cell-input-numeric {
  text-align: right;
  font-weight: 500;
}

.cell-input-code:focus,
.cell-input-text:focus,
.cell-input-level:focus,
.cell-input-numeric:focus {
  background-color: #ffffff;
  border-color: #0B529C;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.15);
}

.row-actions-group {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
}

.btn-cell-action {
  width: 26px;
  height: 26px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  border-radius: 4px;
  color: #737373;
  cursor: pointer;
}

.btn-cell-action:hover {
  background-color: #f1f5f9;
}

/* ─── 2. OFFICIAL REAL-LIFE DOCUMENT PRESENTATION (Matches Photo) ─── */
.official-document-view {
  background-color: #e2e8f0;
  padding: 32px;
  border-radius: 8px;
  display: flex;
  justify-content: center;
}

.document-paper {
  background-color: #ffffff;
  width: 100%;
  max-width: 1080px;
  padding: 48px 40px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
  border: 1px solid #cbd5e1;
}

.doc-official-header {
  text-align: center;
  margin-bottom: 24px;
  border-bottom: 2px solid #0f172a;
  padding-bottom: 16px;
}

.doc-main-title {
  font-size: 19px;
  font-weight: 700;
  color: #0f172a;
  letter-spacing: 0.5px;
}

.doc-sub-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #334155;
  margin-top: 4px;
}

.doc-meta-timeline {
  font-size: 12px;
  color: #64748b;
  margin-top: 4px;
}

.official-scale-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
  border: 2px solid #0f172a;
}

.official-scale-table th,
.official-scale-table td {
  border: 1px solid #334155;
  padding: 6px 8px;
}

.official-th-row-main th {
  background-color: #f1f5f9;
  font-weight: 700;
  color: #0f172a;
  text-align: center;
  vertical-align: middle;
}

.official-th-row-sub th {
  background-color: #f8fafc;
  font-weight: 600;
  color: #1e293b;
  text-align: right;
  padding: 4px 6px;
}

.doc-td-grade {
  text-align: center;
  background-color: #f8fafc;
  color: #0f172a;
}

.doc-td-desc {
  color: #1e293b;
}

.doc-td-num {
  text-align: right;
  color: #0f172a;
}

.doc-body-row:nth-child(even) {
  background-color: #fafbfc;
}

.doc-official-footer {
  display: flex;
  justify-content: space-between;
  margin-top: 48px;
  padding-top: 24px;
}

.footer-sign-block {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 240px;
}

.sign-line {
  width: 100%;
  height: 1px;
  background-color: #0f172a;
  margin-bottom: 6px;
}

.sign-label {
  font-size: 11px;
  font-weight: 500;
  color: #475569;
}

/* Adjustment Modal */
.adjustment-modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(2px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.adjustment-modal-box {
  background: #ffffff;
  border-radius: 12px;
  width: 440px;
  max-width: 90vw;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid #f1f5f9;
}

.modal-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.btn-close {
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
}

.modal-body {
  padding: 20px;
}

.modal-intro {
  font-size: 12.5px;
  color: #64748b;
  margin-bottom: 16px;
  line-height: 1.4;
}

.input-field-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.pct-input-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.pct-input {
  height: 38px;
  width: 100%;
  padding: 0 32px 0 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  color: #0B529C;
  outline: none;
}

.pct-input:focus {
  border-color: #0B529C;
}

.pct-symbol {
  position: absolute;
  right: 12px;
  font-size: 14px;
  font-weight: 600;
  color: #737373;
}

.field-hint {
  font-size: 11.5px;
  color: #737373;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 14px 20px;
  border-top: 1px solid #f1f5f9;
  background-color: #fafafa;
}

.btn-cancel {
  height: 36px;
  padding: 0 16px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  cursor: pointer;
}

.btn-apply {
  height: 36px;
  padding: 0 18px;
  background: #0B529C;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #ffffff;
  cursor: pointer;
}
</style>
