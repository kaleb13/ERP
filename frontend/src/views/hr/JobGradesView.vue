<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { 
  Award, Plus, Search, Filter, ArrowUpDown, ChevronDown, 
  MoreVertical, Edit2, Trash2, Eye, Copy, Check, Calendar, 
  CheckCircle2, AlertCircle, Maximize2, X, DollarSign,
  Layers, ChevronRight, Sliders, Calculator, Grid, Building2
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import BaseTabs, { type TabItem } from '../../components/BaseTabs.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

const router = useRouter();
const route = useRoute();

// ─── Active Top Tab (<BaseTabs /> Capsule Standard) ───
type HubTabId = 'matrix' | 'grades';
const activeHubTab = ref<HubTabId>('matrix');

const hubTabs = computed<TabItem[]>(() => [
  { id: 'matrix', label: 'Pay Scale Matrix', icon: Grid },
  { id: 'grades', label: 'Job Grades Directory', icon: Award }
]);

// ─── Types strictly mapped to HR_Schema_final-v4.sql lines 1044–1109 ───
export type RowState = 'active' | 'inactive';

// SalaryMatrix (lines 1044–1064): ZERO phantom name/code/desc
export interface SalaryMatrixRecord {
  id: number;
  uuid: string;
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  effective_from: string;
  effective_to?: string | null;
  number_of_steps: number;
  currency_id: number;
  currency_code: string;
  is_default: boolean;
  state: RowState;
}

// JobGradeStep (lines 1088–1109)
export interface JobGradeStepItem {
  id: number;
  step_number: number;
  amount: number;
  increment_years: number | null;
  description?: string;
  state: RowState;
}

// JobGrade (lines 1065–1087)
export interface JobGradeRecord {
  id: number;
  uuid: string;
  code: string;
  name: string;
  description?: string;
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  level: number;
  base_salary: number;
  ceiling_salary: number;
  salary_matrix_id: number;
  matrix_timeline: string;
  steps_count: number;
  steps: JobGradeStepItem[];
  state: RowState;
}

// ─── Breadcrumbs (Clean Page Names ONLY: Rule 3.2) ───
const breadcrumbItems = [
  { label: 'Job Grades & Pay Scales' }
];

// ─── State Management ───
const selectedEntityForMatrix = ref('Haleta Addis Ababa HQ');
const searchQuery = ref('');
const filterEntity = ref('All');
const filterLevel = ref('All');
const filterState = ref('All');
const currentSort = ref('level');
const sortOrder = ref<'asc' | 'desc'>('asc');
const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);

// Modal states
const showQuickCreateGrade = ref(false);
const showReviseScaleModal = ref(false);
const showStepLadderModal = ref(false);
const selectedGradeForSteps = ref<JobGradeRecord | null>(null);
const quickActionToast = ref<string | null>(null);

// ─── Active Matrices per Entity (Schema lines 1056–1063) ───
const activeMatrices = ref<SalaryMatrixRecord[]>([
  {
    id: 3,
    uuid: 'sm-003',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    effective_from: '2026-07-08',
    effective_to: null,
    number_of_steps: 5,
    currency_id: 1,
    currency_code: 'ETB',
    is_default: true,
    state: 'active'
  },
  {
    id: 4,
    uuid: 'sm-004',
    tenant_id: 1,
    entity_id: 7,
    entity_name: 'Haleta Grand Hotel & Suites',
    effective_from: '2026-07-08',
    effective_to: null,
    number_of_steps: 5,
    currency_id: 1,
    currency_code: 'ETB',
    is_default: true,
    state: 'active'
  },
  {
    id: 5,
    uuid: 'sm-005',
    tenant_id: 1,
    entity_id: 9,
    entity_name: 'Haleta Hawassa Hub',
    effective_from: '2026-07-08',
    effective_to: null,
    number_of_steps: 5,
    currency_id: 1,
    currency_code: 'ETB',
    is_default: true,
    state: 'active'
  }
]);

// Currently selected matrix for Tab 1
const currentActiveMatrix = computed(() => {
  return activeMatrices.value.find(m => m.entity_name === selectedEntityForMatrix.value) 
    || activeMatrices.value[0];
});

// ─── Mock JobGrades Aligned with Schema lines 1080–1109 ───
const jobGrades = ref<JobGradeRecord[]>([
  {
    id: 3,
    uuid: 'jg-uuid-003',
    code: 'C1',
    name: 'Grade C1 - Operational Support',
    description: 'Entry operational and frontline support band.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    level: 3,
    base_salary: 5000,
    ceiling_salary: 9000,
    salary_matrix_id: 3,
    matrix_timeline: '2026-07-08 to Current',
    steps_count: 5,
    state: 'active',
    steps: [
      { id: 1, step_number: 1, amount: 6500, increment_years: null, description: 'Entry Step', state: 'active' },
      { id: 2, step_number: 2, amount: 7150, increment_years: 2, description: 'Scale Step 2', state: 'active' },
      { id: 3, step_number: 3, amount: 7850, increment_years: 2, description: 'Long-service Step', state: 'active' },
      { id: 4, step_number: 4, amount: 8400, increment_years: 2, description: 'Scale Step 4', state: 'active' },
      { id: 5, step_number: 5, amount: 8950, increment_years: 2, description: 'Grade Ceiling Step', state: 'active' }
    ]
  },
  {
    id: 4,
    uuid: 'jg-uuid-004',
    code: 'C2',
    name: 'Grade C2 - Technical & Clerical',
    description: 'Core administrative and technical specialists.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    level: 4,
    base_salary: 8000,
    ceiling_salary: 13000,
    salary_matrix_id: 3,
    matrix_timeline: '2026-07-08 to Current',
    steps_count: 5,
    state: 'active',
    steps: [
      { id: 6, step_number: 1, amount: 8500, increment_years: null, description: 'Entry Step', state: 'active' },
      { id: 7, step_number: 2, amount: 9400, increment_years: 2, description: 'Scale Step 2', state: 'active' },
      { id: 8, step_number: 3, amount: 10500, increment_years: 2, description: 'Mid Step 3', state: 'active' },
      { id: 9, step_number: 4, amount: 11600, increment_years: 2, description: 'Senior Step 4', state: 'active' },
      { id: 10, step_number: 5, amount: 12800, increment_years: 2, description: 'Ceiling Step 5', state: 'active' }
    ]
  },
  {
    id: 5,
    uuid: 'jg-uuid-005',
    code: 'B2',
    name: 'Grade B2 - Professional & Senior Staff',
    description: 'Professional domain specialists and officers.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    level: 5,
    base_salary: 11000,
    ceiling_salary: 18000,
    salary_matrix_id: 3,
    matrix_timeline: '2026-07-08 to Current',
    steps_count: 5,
    state: 'active',
    steps: [
      { id: 11, step_number: 1, amount: 12000, increment_years: null, description: 'Entry Step', state: 'active' },
      { id: 12, step_number: 2, amount: 13500, increment_years: 2, description: 'Scale Step 2', state: 'active' },
      { id: 13, step_number: 3, amount: 14900, increment_years: 2, description: 'Mid Step 3', state: 'active' },
      { id: 14, step_number: 4, amount: 16300, increment_years: 2, description: 'Senior Step 4', state: 'active' },
      { id: 15, step_number: 5, amount: 17800, increment_years: 2, description: 'Ceiling Step 5', state: 'active' }
    ]
  },
  {
    id: 6,
    uuid: 'jg-uuid-006',
    code: 'B1',
    name: 'Grade B1 - Section Heads & Leads',
    description: 'Operational team leaders and section coordinators.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    level: 6,
    base_salary: 17000,
    ceiling_salary: 27000,
    salary_matrix_id: 3,
    matrix_timeline: '2026-07-08 to Current',
    steps_count: 5,
    state: 'active',
    steps: [
      { id: 16, step_number: 1, amount: 18500, increment_years: null, description: 'Entry Step', state: 'active' },
      { id: 17, step_number: 2, amount: 20500, increment_years: 2, description: 'Scale Step 2', state: 'active' },
      { id: 18, step_number: 3, amount: 22500, increment_years: 2, description: 'Mid Step 3', state: 'active' },
      { id: 19, step_number: 4, amount: 24700, increment_years: 2, description: 'Senior Step 4', state: 'active' },
      { id: 20, step_number: 5, amount: 26800, increment_years: 2, description: 'Ceiling Step 5', state: 'active' }
    ]
  },
  {
    id: 7,
    uuid: 'jg-uuid-007',
    code: 'A3',
    name: 'Grade A3 - Department Managers & Specialists',
    description: 'Senior management and principal domain leaders.',
    tenant_id: 1,
    entity_id: 1,
    entity_name: 'Haleta Addis Ababa HQ',
    level: 7,
    base_salary: 26000,
    ceiling_salary: 40000,
    salary_matrix_id: 3,
    matrix_timeline: '2026-07-08 to Current',
    steps_count: 5,
    state: 'active',
    steps: [
      { id: 21, step_number: 1, amount: 28000, increment_years: null, description: 'Entry Step', state: 'active' },
      { id: 22, step_number: 2, amount: 31000, increment_years: 2, description: 'Scale Step 2', state: 'active' },
      { id: 23, step_number: 3, amount: 34000, increment_years: 2, description: 'Mid Step 3', state: 'active' },
      { id: 24, step_number: 4, amount: 37000, increment_years: 2, description: 'Principal Step 4', state: 'active' },
      { id: 25, step_number: 5, amount: 39800, increment_years: 2, description: 'Ceiling Step 5', state: 'active' }
    ]
  },
  {
    id: 8,
    uuid: 'jg-uuid-008',
    code: 'H1',
    name: 'Grade H1 - Guest Service Specialists',
    description: 'Front of house hospitality and guest relation roles.',
    tenant_id: 1,
    entity_id: 7,
    entity_name: 'Haleta Grand Hotel & Suites',
    level: 3,
    base_salary: 6000,
    ceiling_salary: 10500,
    salary_matrix_id: 4,
    matrix_timeline: '2026-07-08 to Current',
    steps_count: 5,
    state: 'active',
    steps: [
      { id: 26, step_number: 1, amount: 6800, increment_years: null, description: 'Entry Step', state: 'active' },
      { id: 27, step_number: 2, amount: 7600, increment_years: 2, description: 'Scale Step 2', state: 'active' },
      { id: 28, step_number: 3, amount: 8500, increment_years: 2, description: 'Standard Step 3', state: 'active' },
      { id: 29, step_number: 4, amount: 9500, increment_years: 2, description: 'Senior Step 4', state: 'active' },
      { id: 30, step_number: 5, amount: 10400, increment_years: 2, description: 'Ceiling Step 5', state: 'active' }
    ]
  }
]);

// 2D Grid grades for the selected entity in Tab 1
const currentMatrixGrades = computed(() => {
  return jobGrades.value
    .filter(g => g.entity_name === selectedEntityForMatrix.value)
    .sort((a, b) => a.level - b.level);
});

// ─── Quick Create JobGrade State (Schema lines 1065–1087 - Zero Manual Code) ───
const quickGradeForm = ref({
  name: '',
  entity_id: 'Haleta Addis Ababa HQ',
  level: 3,
  base_salary: 6000,
  ceiling_salary: 10000,
  description: ''
});

// ─── Revise Pay Scale State (SalaryMatrix lines 1044–1064 - ZERO PHANTOM NAME) ───
const reviseScaleForm = ref({
  effective_from: new Date().toISOString().split('T')[0],
  number_of_steps: 5,
  currency_code: 'ETB',
  is_default: true
});

// ─── Table Columns for Tab 2 (Strict Single-Information & Name-First Hierarchy) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Name', visible: true, sortable: true },
  { key: 'level', label: 'Seniority Level', visible: true, sortable: true },
  { key: 'base_salary', label: 'Base Floor (ETB)', visible: true, sortable: true },
  { key: 'ceiling_salary', label: 'Ceiling Salary (ETB)', visible: true, sortable: true },
  { key: 'steps_count', label: 'Discrete Steps', visible: true, sortable: true },
  { key: 'entity', label: 'Owning Entity', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

// ─── Filter & Search Logic for Tab 2 ───
const activeFilterCount = computed(() => {
  let count = 0;
  if (filterEntity.value !== 'All') count++;
  if (filterLevel.value !== 'All') count++;
  if (filterState.value !== 'All') count++;
  return count;
});

const filteredJobGrades = computed(() => {
  return jobGrades.value.filter(g => {
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase();
      const matchName = g.name.toLowerCase().includes(q);
      const matchCode = g.code.toLowerCase().includes(q);
      const matchEntity = g.entity_name.toLowerCase().includes(q);
      if (!matchName && !matchCode && !matchEntity) return false;
    }
    if (filterEntity.value !== 'All' && g.entity_name !== filterEntity.value) return false;
    if (filterLevel.value !== 'All' && `Level ${g.level}` !== filterLevel.value) return false;
    if (filterState.value !== 'All' && g.state !== filterState.value.toLowerCase()) return false;
    return true;
  }).sort((a, b) => {
    let valA = a[currentSort.value as keyof JobGradeRecord];
    let valB = b[currentSort.value as keyof JobGradeRecord];
    if (valA === undefined || valA === null) valA = '';
    if (valB === undefined || valB === null) valB = '';
    if (valA < valB) return sortOrder.value === 'asc' ? -1 : 1;
    if (valA > valB) return sortOrder.value === 'asc' ? 1 : -1;
    return 0;
  });
});

// Selection Logic
const isAllSelected = computed(() => {
  return filteredJobGrades.value.length > 0 && 
    filteredJobGrades.value.every(g => selectedRowIds.value.includes(g.id));
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = filteredJobGrades.value.map(g => g.id);
  }
};

const toggleRowSelection = (id: number) => {
  const index = selectedRowIds.value.indexOf(id);
  if (index > -1) {
    selectedRowIds.value.splice(index, 1);
  } else {
    selectedRowIds.value.push(id);
  }
};

const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

const handleToggleColumn = ({ key, visible }: { key: string; visible: boolean }) => {
  const col = tableColumns.value.find(c => c.key === key);
  if (col) col.visible = visible;
};

// Actions Menu
const toggleActionMenu = (id: number, event: Event) => {
  event.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
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

// Open Step Ladder Modal
const openStepLadder = (grade: JobGradeRecord) => {
  closeActionMenu();
  selectedGradeForSteps.value = grade;
  showStepLadderModal.value = true;
};

// Recalculate linear progression steps
const autoDistributeSteps = () => {
  if (!selectedGradeForSteps.value) return;
  const grade = selectedGradeForSteps.value;
  const count = grade.steps_count || 5;
  const min = grade.base_salary;
  const max = grade.ceiling_salary;
  const stepInc = (max - min) / (count - 1 || 1);

  grade.steps = [];
  for (let s = 1; s <= count; s++) {
    grade.steps.push({
      id: Date.now() + s,
      step_number: s,
      amount: Math.round(min + (s - 1) * stepInc),
      increment_years: s === 1 ? null : 2,
      description: s === 1 ? 'Entry Step' : s === count ? 'Ceiling Step' : `Scale Step ${s}`,
      state: 'active'
    });
  }
  showToast('Steps recalculated linearly across band guardrails.');
};

// ─── Quick Create JobGrade Handler ───
const handleQuickSaveGrade = () => {
  if (!quickGradeForm.value.name.trim()) {
    alert('Please enter a Job Grade Name.');
    return;
  }

  const newId = Date.now();
  // Auto-generate code from Name (Rule 16: Zero manual code input)
  const words = quickGradeForm.value.name.trim().split(' ');
  const derivedCode = words.length > 1 ? words[1].toUpperCase() : words[0].substring(0, 3).toUpperCase();

  const stepCount = currentActiveMatrix.value?.number_of_steps || 5;
  const min = Number(quickGradeForm.value.base_salary) || 5000;
  const max = Number(quickGradeForm.value.ceiling_salary) || 9000;
  const stepInc = (max - min) / (stepCount - 1 || 1);

  const initialSteps: JobGradeStepItem[] = [];
  for (let s = 1; s <= stepCount; s++) {
    initialSteps.push({
      id: newId + s,
      step_number: s,
      amount: Math.round(min + (s - 1) * stepInc),
      increment_years: s === 1 ? null : 2,
      description: s === 1 ? 'Entry Step' : s === stepCount ? 'Ceiling Step' : `Scale Step ${s}`,
      state: 'active'
    });
  }

  const newRecord: JobGradeRecord = {
    id: newId,
    uuid: `jg-${newId}`,
    code: derivedCode,
    name: quickGradeForm.value.name.trim(),
    description: quickGradeForm.value.description,
    tenant_id: 1,
    entity_id: quickGradeForm.value.entity_id.includes('HQ') ? 1 : 7,
    entity_name: quickGradeForm.value.entity_id,
    level: Number(quickGradeForm.value.level),
    base_salary: min,
    ceiling_salary: max,
    salary_matrix_id: currentActiveMatrix.value?.id || 3,
    matrix_timeline: `${currentActiveMatrix.value?.effective_from} to Current`,
    steps_count: stepCount,
    state: 'active',
    steps: initialSteps
  };

  jobGrades.value.unshift(newRecord);
  showQuickCreateGrade.value = false;
  showToast(`Job Grade "${newRecord.name}" created successfully.`);

  // Reset
  quickGradeForm.value.name = '';
  quickGradeForm.value.description = '';
};

// Navigate to Expand Full Form for JobGrade
const handleExpandFullFormGrade = () => {
  showQuickCreateGrade.value = false;
  router.push({
    path: '/hr/job-grades/create',
    query: {
      name: quickGradeForm.value.name,
      entity: quickGradeForm.value.entity_id,
      level: quickGradeForm.value.level,
      base: quickGradeForm.value.base_salary,
      ceiling: quickGradeForm.value.ceiling_salary
    }
  });
};

// ─── Revise Pay Scale Handler (SalaryMatrix lines 1044–1064: ZERO PHANTOM NAME) ───
const handleSaveReviseScale = () => {
  const newMatrixId = Date.now();
  const entity = selectedEntityForMatrix.value;

  // Stamping previous matrix effective_to
  const prevMatrix = activeMatrices.value.find(m => m.entity_name === entity);
  if (prevMatrix) {
    prevMatrix.effective_to = reviseScaleForm.value.effective_from;
  }

  const newMatrix: SalaryMatrixRecord = {
    id: newMatrixId,
    uuid: `sm-${newMatrixId}`,
    tenant_id: 1,
    entity_id: entity.includes('HQ') ? 1 : 7,
    entity_name: entity,
    effective_from: reviseScaleForm.value.effective_from,
    effective_to: null,
    number_of_steps: Number(reviseScaleForm.value.number_of_steps),
    currency_id: 1,
    currency_code: reviseScaleForm.value.currency_code,
    is_default: reviseScaleForm.value.is_default,
    state: 'active'
  };

  activeMatrices.value.unshift(newMatrix);
  showReviseScaleModal.value = false;
  showToast(`Published revised pay scale for "${entity}" effective ${newMatrix.effective_from}.`);
};

// Floating Bar Actions
const handleBatchDelete = () => {
  jobGrades.value = jobGrades.value.filter(g => !selectedRowIds.value.includes(g.id));
  selectedRowIds.value = [];
  showToast('Selected job grades deleted.');
};

onMounted(() => {
  window.addEventListener('click', closeActionMenu);
});

onUnmounted(() => {
  window.removeEventListener('click', closeActionMenu);
});
</script>

<template>
  <div class="job-grades-page">
    <!-- Breadcrumb Bar -->
    <div class="page-breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Toast Notification Banner -->
    <div v-if="quickActionToast" class="quick-toast-banner">
      <CheckCircle2 :size="15" class="text-emerald-600" />
      <span>{{ quickActionToast }}</span>
    </div>

    <!-- Top Tab Navigation (<BaseTabs /> Capsule Standard) -->
    <div class="hub-tabs-container">
      <BaseTabs 
        v-model="activeHubTab"
        :tabs="hubTabs"
        size="md"
      />
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 1: 2D PAY SCALE MATRIX VISUALIZER                         -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeHubTab === 'matrix'" class="tab-pane-container">
      <div class="clean-card matrix-view-card">
        <!-- Control Header: Entity Switcher & Active Matrix Metadata -->
        <div class="matrix-control-bar">
          <div class="control-left">
            <div class="entity-selector-wrap">
              <label class="control-label">Owning Entity</label>
              <select v-model="selectedEntityForMatrix" class="entity-dropdown">
                <option value="Haleta Addis Ababa HQ">Haleta Addis Ababa HQ</option>
                <option value="Haleta Grand Hotel & Suites">Haleta Grand Hotel & Suites</option>
                <option value="Haleta Hawassa Hub">Haleta Hawassa Hub</option>
              </select>
            </div>

            <div class="matrix-metadata-pill-strip">
              <span class="meta-item">
                <Calendar :size="13" class="meta-icon" />
                <span>Effective: {{ currentActiveMatrix?.effective_from }} - {{ currentActiveMatrix?.effective_to || 'Current' }}</span>
                <span class="gc-pill-tag">GC</span>
              </span>
              <span class="meta-sep">•</span>
              <span class="meta-item font-medium text-slate-700">
                {{ currentActiveMatrix?.number_of_steps }} Progression Steps
              </span>
              <span class="meta-sep">•</span>
              <span class="meta-item font-mono text-slate-600">
                {{ currentActiveMatrix?.currency_code }}
              </span>
              <span class="meta-sep">•</span>
              <span class="status-pill status-pill-active">
                Default Pay Scale
              </span>
            </div>
          </div>

          <div class="control-right">
            <button 
              type="button" 
              class="btn-revise-scale"
              @click="showReviseScaleModal = true"
            >
              <Sliders :size="14" />
              <span>Revise Pay Scale</span>
            </button>
          </div>
        </div>

        <!-- 2D Pay Matrix Grid Table -->
        <div class="pay-grid-table-container">
          <table class="grid-table">
            <thead>
              <tr>
                <th class="th-grade">Job Grade</th>
                <th class="th-level">Level</th>
                <th class="th-guardrail">Base Floor (ETB)</th>
                <th 
                  v-for="s in currentActiveMatrix?.number_of_steps || 5" 
                  :key="s" 
                  class="th-step"
                >
                  Step {{ s }}
                </th>
                <th class="th-guardrail">Ceiling (ETB)</th>
                <th class="th-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="g in currentMatrixGrades" :key="g.id" class="grid-row">
                <td class="td-grade">
                  <span class="grade-title">{{ g.name }}</span>
                  <span class="grade-code font-mono">{{ g.code }}</span>
                </td>
                <td class="td-level">
                  <span class="text-tertiary">Level {{ g.level }}</span>
                </td>
                <td class="td-guardrail">
                  <span class="guardrail-amount">{{ formatETB(g.base_salary) }}</span>
                </td>
                <td 
                  v-for="s in currentActiveMatrix?.number_of_steps || 5" 
                  :key="s" 
                  class="td-step"
                >
                  <div class="step-cell-box">
                    <span class="step-amount">{{ formatETB(g.steps[s - 1]?.amount || (g.base_salary + (s * 1000))) }}</span>
                    <span v-if="g.steps[s - 1]?.increment_years" class="step-rule font-mono">
                      +{{ g.steps[s - 1].increment_years }}y wait
                    </span>
                    <span v-else class="step-rule text-slate-400">Entry</span>
                  </div>
                </td>
                <td class="td-guardrail">
                  <span class="guardrail-amount">{{ formatETB(g.ceiling_salary) }}</span>
                </td>
                <td class="td-actions">
                  <button 
                    type="button" 
                    class="btn-tune-row" 
                    @click="openStepLadder(g)" 
                    title="Configure Discrete Step Ladder"
                  >
                    <Sliders :size="13" />
                    <span>Tune</span>
                  </button>
                </td>
              </tr>

              <tr v-if="currentMatrixGrades.length === 0">
                <td :colspan="(currentActiveMatrix?.number_of_steps || 5) + 4" class="empty-grid-cell">
                  <div class="empty-state-box">
                    <p class="empty-title">No Job Grades Configured for this Pay Scale</p>
                    <p class="empty-subtitle">Switch to Job Grades Directory to add pay bands to this entity.</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 2: JOB GRADES ATOMIC DIRECTORY                            -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeHubTab === 'grades'" class="tab-pane-container">
      <div class="directory-view-wrapper">
        <AppDataTable
          title="Job Grades"
          subtitle="Manage enterprise compensation guardrails, band ceilings, seniority rank order, and discrete salary step progression ladders."
          v-model:searchQuery="searchQuery"
          searchPlaceholder="Search by Grade Name..."
          :showSearch="true"
          :showFilter="true"
          :filterCount="activeFilterCount"
          :showSort="true"
          v-model:currentSort="currentSort"
          v-model:sortOrder="sortOrder"
          :showColumns="true"
          :columns="tableColumns"
          @toggleColumn="handleToggleColumn"
        >
          <!-- Primary Action in Toolbar -->
          <template #actions>
            <button 
              type="button" 
              class="btn-primary-create" 
              @click="showQuickCreateGrade = true"
            >
              <Plus :size="15" />
              <span>Add Job Grade</span>
            </button>
          </template>

          <!-- Filter Drawer Content -->
          <template #filter>
            <div class="filter-grid">
              <FormSelect
                label="Owning Entity"
                v-model="filterEntity"
                :options="['All', 'Haleta Addis Ababa HQ', 'Haleta Grand Hotel & Suites', 'Haleta Hawassa Hub']"
              />
              <FormSelect
                label="Seniority Level"
                v-model="filterLevel"
                :options="['All', 'Level 3', 'Level 4', 'Level 5', 'Level 6', 'Level 7']"
              />
              <FormSelect
                label="Record State"
                v-model="filterState"
                :options="['All', 'Active', 'Inactive']"
              />
            </div>
          </template>

          <!-- Table Listing -->
          <table class="erp-table">
            <thead>
              <tr>
                <th class="col-checkbox">
                  <input 
                    type="checkbox" 
                    class="custom-checkbox" 
                    :checked="isAllSelected" 
                    @change="toggleSelectAll" 
                    aria-label="Select All" 
                  />
                </th>

                <!-- Rule 4 & 5: Name is Secondary Color (#404040), Code is Tertiary subtext (#737373) -->
                <th v-if="isColumnVisible('name')" class="col-name sortable" @click="currentSort = 'name'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                  <div class="th-content">
                    <span>Name</span>
                    <ArrowUpDown :size="12" class="sort-icon" />
                  </div>
                </th>

                <!-- All Subsequent Columns in Tertiary Color (#737373) -->
                <th v-if="isColumnVisible('level')" class="col-level sortable" @click="currentSort = 'level'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                  <div class="th-content">
                    <span>Seniority Level</span>
                    <ArrowUpDown :size="12" class="sort-icon" />
                  </div>
                </th>
                <th v-if="isColumnVisible('base_salary')" class="col-salary sortable" @click="currentSort = 'base_salary'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                  <div class="th-content">
                    <span>Base Floor (ETB)</span>
                    <ArrowUpDown :size="12" class="sort-icon" />
                  </div>
                </th>
                <th v-if="isColumnVisible('ceiling_salary')" class="col-salary sortable" @click="currentSort = 'ceiling_salary'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                  <div class="th-content">
                    <span>Ceiling Salary (ETB)</span>
                    <ArrowUpDown :size="12" class="sort-icon" />
                  </div>
                </th>
                <th v-if="isColumnVisible('steps_count')" class="col-steps">Discrete Steps</th>
                <th v-if="isColumnVisible('entity')" class="col-entity">Owning Entity</th>
                <th v-if="isColumnVisible('state')" class="col-state sortable" @click="currentSort = 'state'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                  <div class="th-content">
                    <span>State</span>
                    <ArrowUpDown :size="12" class="sort-icon" />
                  </div>
                </th>
                <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="item in filteredJobGrades" 
                :key="item.id"
                class="erp-row cursor-pointer"
                :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
                @click="openStepLadder(item)"
              >
                <td class="col-checkbox" @click.stop>
                  <input 
                    type="checkbox" 
                    class="custom-checkbox" 
                    :checked="selectedRowIds.includes(item.id)" 
                    @change="toggleRowSelection(item.id)" 
                  />
                </td>

                <!-- Rule 4 & 5: Name is Secondary Color (#404040), Code is Tertiary subtext (#737373) -->
                <td v-if="isColumnVisible('name')" class="col-name">
                  <div class="name-cell-stack">
                    <span class="table-name-primary">{{ item.name }}</span>
                    <span class="table-code-subtext font-mono">{{ item.code }}</span>
                  </div>
                </td>

                <!-- Rule 5 & 6: Tertiary plain text, NO decorative badges for numbers or counts -->
                <td v-if="isColumnVisible('level')" class="col-level">
                  <span class="text-tertiary">Level {{ item.level }}</span>
                </td>

                <td v-if="isColumnVisible('base_salary')" class="col-salary">
                  <span class="text-tertiary font-mono">{{ formatETB(item.base_salary) }}</span>
                </td>

                <td v-if="isColumnVisible('ceiling_salary')" class="col-salary">
                  <span class="text-tertiary font-mono">{{ formatETB(item.ceiling_salary) }}</span>
                </td>

                <td v-if="isColumnVisible('steps_count')" class="col-steps">
                  <span class="text-tertiary">{{ item.steps_count }} Steps</span>
                </td>

                <td v-if="isColumnVisible('entity')" class="col-entity">
                  <span class="text-tertiary">{{ item.entity_name }}</span>
                </td>

                <!-- Badges reserved strictly for lifecycle state -->
                <td v-if="isColumnVisible('state')" class="col-state">
                  <span class="status-pill" :class="item.state === 'active' ? 'status-pill-active' : 'status-pill-inactive'">
                    {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                  </span>
                </td>

                <!-- Action 3-dots -->
                <td v-if="isColumnVisible('actions')" class="col-actions" @click.stop>
                  <div class="action-dropdown-container">
                    <button 
                      type="button" 
                      class="btn-action-dots" 
                      @click="toggleActionMenu(item.id, $event)"
                      aria-label="Actions"
                    >
                      <MoreVertical :size="15" />
                    </button>

                    <div v-if="activeActionMenuId === item.id" class="action-popup-menu">
                      <button type="button" class="menu-item" @click="openStepLadder(item)">
                        <Eye :size="14" />
                        <span>View Step Ladder</span>
                      </button>
                      <button type="button" class="menu-item" @click="router.push(`/hr/job-grades/create?edit=${item.id}`)">
                        <Edit2 :size="14" />
                        <span>Edit Grade Details</span>
                      </button>
                      <button 
                        type="button" 
                        class="menu-item"
                        @click="item.state = item.state === 'active' ? 'inactive' : 'active'; showToast(`Updated ${item.name} state.`); closeActionMenu();"
                      >
                        <Check :size="14" />
                        <span>{{ item.state === 'active' ? 'Deactivate Grade' : 'Activate Grade' }}</span>
                      </button>
                      <div class="menu-divider"></div>
                      <button 
                        type="button" 
                        class="menu-item text-rose-600 hover:bg-rose-50"
                        @click="jobGrades = jobGrades.filter(g => g.id !== item.id); showToast(`Deleted grade ${item.name}`); closeActionMenu();"
                      >
                        <Trash2 :size="14" />
                        <span>Delete Grade</span>
                      </button>
                    </div>
                  </div>
                </td>
              </tr>

              <tr v-if="filteredJobGrades.length === 0">
                <td colspan="8" class="table-empty-row">
                  <div class="empty-state-box">
                    <p class="empty-title">No Job Grades Found</p>
                    <p class="empty-subtitle">Adjust your search criteria or add a new job grade.</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </AppDataTable>
      </div>
    </div>

    <!-- FLOATING BATCH ACTIONS BAR -->
    <TableFloatingBar 
      :count="selectedRowIds.length" 
      @delete="handleBatchDelete" 
    />

    <!-- QUICK CREATE MODAL: JOB GRADE (Strict Schema lines 1065–1087) -->
    <QuickCreateModal
      v-model:show="showQuickCreateGrade"
      title="Create Job Grade"
      saveLabel="Save"
      @save="handleQuickSaveGrade"
      @expand="handleExpandFullFormGrade"
      :showExpandButton="true"
      width="md"
    >
      <div class="quick-create-form-body">
        <!-- Grade Name: Rule 5 & 14 (No Placeholder) -->
        <FormInput
          label="Grade Name"
          v-model="quickGradeForm.name"
          required
        />

        <!-- Owning Entity -->
        <FormSelect
          label="Owning Entity"
          v-model="quickGradeForm.entity_id"
          :options="['Haleta Addis Ababa HQ', 'Haleta Grand Hotel & Suites', 'Haleta Hawassa Hub']"
          placeholder="Select"
          required
        />

        <!-- Seniority Level (Integer) -->
        <FormSelect
          label="Seniority Level"
          v-model="quickGradeForm.level"
          :options="[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
          placeholder="Select"
          required
        />

        <div class="form-row-dual">
          <!-- Base Floor Salary -->
          <FormInput
            label="Base Floor Salary (ETB)"
            type="number"
            v-model="quickGradeForm.base_salary"
            required
          />

          <!-- Ceiling Salary Cap -->
          <FormInput
            label="Ceiling Salary Cap (ETB)"
            type="number"
            v-model="quickGradeForm.ceiling_salary"
            required
          />
        </div>

        <p class="helper-text-info">
          Attached to active pay scale grid with {{ currentActiveMatrix?.number_of_steps || 5 }} progression steps.
        </p>
      </div>
    </QuickCreateModal>

    <!-- MODAL: REVISE PAY SCALE (Strict SalaryMatrix lines 1044–1064 - ZERO PHANTOM NAME) -->
    <QuickCreateModal
      v-model:show="showReviseScaleModal"
      title="Revise Entity Pay Scale"
      saveLabel="Publish Revision"
      @save="handleSaveReviseScale"
      :showExpandButton="false"
      width="md"
    >
      <div class="quick-create-form-body">
        <div class="info-alert-box">
          <p class="alert-title">Publishing Successor Salary Matrix</p>
          <p class="alert-body">
            This stamps the current active scale for <strong>{{ selectedEntityForMatrix }}</strong> and activates this new revision. Existing grade amounts carry over into the new scale timeline.
          </p>
        </div>

        <!-- Effective From Date with [GC] Gregorian Tag -->
        <div class="form-group-date">
          <label class="erp-field-label">Effective From Date <span class="required-star">*</span></label>
          <div class="date-input-wrapper">
            <Calendar :size="15" class="date-icon" />
            <input 
              type="date" 
              v-model="reviseScaleForm.effective_from" 
              class="erp-date-input" 
              required
            />
            <span class="gc-pill-tag">GC</span>
          </div>
        </div>

        <div class="form-row-dual">
          <!-- Steps per Grade -->
          <FormSelect
            label="Steps per Grade"
            v-model="reviseScaleForm.number_of_steps"
            :options="[3, 5, 7, 10]"
            placeholder="Select"
            required
          />

          <!-- Currency -->
          <FormSelect
            label="Currency"
            v-model="reviseScaleForm.currency_code"
            :options="['ETB']"
            placeholder="Select"
            required
          />
        </div>

        <!-- Default Salary Matrix Checkbox -->
        <FormCheckbox
          v-model="reviseScaleForm.is_default"
          label="Default Salary Matrix"
          description="Designates this compensation grid as the primary baseline for newly created job grades and positions in this entity."
        />
      </div>
    </QuickCreateModal>

    <!-- STEP LADDER DRAWER / MODAL -->
    <div v-if="showStepLadderModal && selectedGradeForSteps" class="step-ladder-modal-backdrop" @click="showStepLadderModal = false">
      <div class="step-ladder-modal-content" @click.stop>
        <div class="modal-header-strip">
          <div class="header-titles">
            <h2 class="ladder-title">{{ selectedGradeForSteps.name }}</h2>
            <div class="ladder-meta">
              <span class="font-mono text-slate-500">{{ selectedGradeForSteps.code }}</span>
              <span class="meta-dot">•</span>
              <span>Level {{ selectedGradeForSteps.level }}</span>
              <span class="meta-dot">•</span>
              <span>Base: {{ formatETB(selectedGradeForSteps.base_salary) }} ETB</span>
              <span class="meta-dot">•</span>
              <span>Ceiling: {{ formatETB(selectedGradeForSteps.ceiling_salary) }} ETB</span>
            </div>
          </div>
          <button type="button" class="btn-close-modal" @click="showStepLadderModal = false" aria-label="Close">
            <X :size="18" />
          </button>
        </div>

        <!-- Sub-table of Steps -->
        <div class="ladder-table-container">
          <table class="ladder-table">
            <thead>
              <tr>
                <th class="th-step-no">Step #</th>
                <th class="th-step-amount">Monthly Amount (ETB)</th>
                <th class="th-step-wait">Wait Time (Years)</th>
                <th class="th-step-desc">Description / Purpose</th>
                <th class="th-step-state">State</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="step in selectedGradeForSteps.steps" :key="step.id">
                <td class="td-step-no">
                  <span class="font-semibold text-slate-800">Step {{ step.step_number }}</span>
                </td>
                <td class="td-step-amount">
                  <input 
                    type="number" 
                    v-model.number="step.amount" 
                    class="step-amount-input"
                  />
                </td>
                <td class="td-step-wait">
                  <input 
                    type="number" 
                    v-model.number="step.increment_years" 
                    class="step-wait-input"
                    placeholder="Entry"
                  />
                </td>
                <td class="td-step-desc">
                  <input 
                    type="text" 
                    v-model="step.description" 
                    class="step-desc-input"
                  />
                </td>
                <td class="td-step-state">
                  <span class="status-pill status-pill-active">Active</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="modal-footer-strip">
          <button 
            type="button" 
            class="btn-recalc" 
            @click="autoDistributeSteps"
          >
            <Calculator :size="14" />
            <span>Auto-Calculate Linear Steps</span>
          </button>
          <button 
            type="button" 
            class="btn-save-steps" 
            @click="showStepLadderModal = false; showToast(`Updated steps for ${selectedGradeForSteps.name}.`);"
          >
            <Check :size="14" />
            <span>Done</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.job-grades-page {
  padding: 24px 32px;
  background-color: #f8fafc;
  min-height: 100vh;
}

.page-breadcrumb-bar {
  margin-bottom: 20px;
}

/* Toast Banner */
.quick-toast-banner {
  position: fixed;
  top: 24px;
  right: 32px;
  z-index: 1000;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.08);
  font-size: 13px;
  color: #404040;
}

/* Hub Tabs Switcher */
.hub-tabs-container {
  margin-bottom: 20px;
}

.tab-pane-container {
  width: 100%;
}

/* Card Standard */
.clean-card {
  background: #ffffff;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.matrix-view-card {
  padding: 24px;
}

/* 2D Matrix Control Bar */
.matrix-control-bar {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  padding-bottom: 20px;
  border-bottom: 1px solid #f1f5f9;
  margin-bottom: 20px;
}

.control-left {
  display: flex;
  align-items: center;
  gap: 24px;
  flex-wrap: wrap;
}

.entity-selector-wrap {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.control-label {
  font-size: 12px;
  font-weight: 500;
  color: #737373;
}

.entity-dropdown {
  height: 38px;
  padding: 0 32px 0 12px;
  font-size: 13.5px;
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
  background-position: right 10px center;
}

.entity-dropdown:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.matrix-metadata-pill-strip {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 12.5px;
  color: #737373;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 6px;
}

.meta-icon {
  color: #737373;
}

.meta-sep {
  color: #cbd5e1;
}

.gc-pill-tag {
  background-color: #eff6ff;
  color: #0284c7;
  font-size: 10.5px;
  font-weight: 600;
  padding: 1px 6px;
  border-radius: 4px;
}

/* Button Standard: Rule 6 Well-rounded rectangle (8px-10px) */
.btn-revise-scale {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  height: 38px;
  padding: 0 16px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-revise-scale:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

/* 2D Pay Grid Table */
.pay-grid-table-container {
  overflow-x: auto;
}

.grid-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.grid-table th {
  height: 36px;
  padding: 8px 12px;
  background-color: #f8fafc;
  border: 1px solid #f1f5f9;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  text-align: left;
  white-space: nowrap;
}

.th-step,
.td-step {
  text-align: right;
  min-width: 120px;
}

.grid-row td {
  padding: 10px 12px;
  border: 1px solid #f1f5f9;
  color: #404040;
  vertical-align: middle;
}

.grid-row:hover {
  background-color: #fafbfd;
}

.td-grade {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.grade-title {
  font-weight: 500;
  color: #404040;
}

.grade-code {
  font-size: 11.5px;
  color: #737373;
}

.guardrail-amount {
  font-family: monospace;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.step-cell-box {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
}

.step-amount {
  font-family: monospace;
  font-size: 13px;
  font-weight: 500;
  color: #0B529C;
}

.step-rule {
  font-size: 11px;
  color: #737373;
}

.btn-tune-row {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  height: 28px;
  padding: 0 10px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
}

.btn-tune-row:hover {
  border-color: #0B529C;
  color: #0B529C;
}

.empty-grid-cell {
  padding: 48px;
  text-align: center;
}

/* Directory Listing Styles (Rule 4, 5, 8, 9) */
.directory-view-wrapper {
  background-color: #ffffff;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  overflow: hidden;
}

.btn-primary-create {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  cursor: pointer;
}

.btn-primary-create:hover {
  background-color: #09427d;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  background-color: #fafafa;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  text-align: left;
  border-bottom: 1px solid #f1f5f9;
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  font-size: 13px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.erp-row:hover {
  background-color: #fafafa;
}

.row-selected {
  background-color: #f0f7ff !important;
}

.col-checkbox {
  width: 40px;
  padding: 8px 0 8px 16px !important;
}

.custom-checkbox {
  width: 16px;
  height: 16px;
  accent-color: #0B529C;
  border-radius: 4px;
  cursor: pointer;
}

/* Rule 4 & 5: Name Cell Stack */
.col-name {
  min-width: 240px;
}

.name-cell-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040; /* Secondary Color for primary entity name */
}

.table-code-subtext {
  font-size: 11.5px;
  color: #737373; /* Tertiary color for code subtext */
}

/* Tertiary text color for all subsequent columns */
.text-tertiary {
  color: #737373;
  font-size: 13px;
}

/* Status Pills */
.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
}

.status-pill-active {
  background-color: #ecfdf5;
  color: #059669;
}

.status-pill-inactive {
  background-color: #f1f5f9;
  color: #64748b;
}

/* Action Dropdown */
.action-dropdown-container {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.action-popup-menu {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  width: 180px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  padding: 4px;
  z-index: 50;
}

.menu-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border: none;
  background: transparent;
  font-size: 12.5px;
  color: #404040;
  border-radius: 6px;
  cursor: pointer;
}

.menu-item:hover {
  background-color: #f8fafc;
}

.menu-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 4px 0;
}

.filter-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
  padding: 16px;
}

.form-row-dual {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.quick-create-form-body {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.helper-text-info {
  font-size: 11.5px;
  color: #737373;
}

/* Date Field with [GC] Gregorian Tag (Rule 17) */
.form-group-date {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.erp-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.required-star {
  color: #e11d48;
}

.date-input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
}

.date-icon {
  position: absolute;
  left: 12px;
  color: #737373;
  pointer-events: none;
}

.erp-date-input {
  width: 100%;
  height: 38px;
  padding: 0 44px 0 36px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  outline: none;
}

.erp-date-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.gc-pill-tag {
  position: absolute;
  right: 10px;
  background-color: #eff6ff;
  color: #0284c7;
  font-size: 10.5px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 4px;
  pointer-events: none;
}

/* Info Box */
.info-alert-box {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 14px;
  font-size: 12px;
  color: #404040;
}

.alert-title {
  font-weight: 600;
  margin-bottom: 2px;
  color: #0B529C;
}

/* Step Ladder Modal */
.step-ladder-modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(2px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}

.step-ladder-modal-content {
  background: #ffffff;
  border-radius: 12px;
  width: 720px;
  max-width: 94vw;
  max-height: 88vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
}

.modal-header-strip {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 20px 24px;
  border-bottom: 1px solid #f1f5f9;
}

.ladder-title {
  font-size: 18px;
  font-weight: 600;
  color: #404040;
}

.ladder-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: #737373;
  margin-top: 4px;
}

.ladder-table-container {
  padding: 16px 24px;
  overflow-y: auto;
  max-height: 50vh;
}

.ladder-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.ladder-table th {
  height: 32px;
  padding: 6px 12px;
  background-color: #f8fafc;
  font-size: 11.5px;
  font-weight: 500;
  color: #737373;
  text-align: left;
}

.ladder-table td {
  padding: 8px 12px;
  border-bottom: 1px solid #f1f5f9;
}

.step-amount-input,
.step-wait-input,
.step-desc-input {
  height: 32px;
  padding: 0 8px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12.5px;
  color: #404040;
  outline: none;
  width: 100%;
}

.step-amount-input {
  font-family: monospace;
  font-weight: 500;
}

.step-amount-input:focus,
.step-wait-input:focus,
.step-desc-input:focus {
  border-color: #0B529C;
}

.modal-footer-strip {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  border-top: 1px solid #f1f5f9;
  background-color: #fafafa;
}

.btn-recalc {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 14px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
}

.btn-save-steps {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 18px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-close-modal {
  width: 32px;
  height: 32px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  color: #737373;
  border-radius: 6px;
  cursor: pointer;
}

.btn-close-modal:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.table-empty-row {
  padding: 48px;
  text-align: center;
}

.empty-state-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.empty-title {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
}

.empty-subtitle {
  font-size: 12.5px;
  color: #737373;
}
</style>
