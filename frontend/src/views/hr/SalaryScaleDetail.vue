<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { 
  Printer, Calendar, Banknote, X, CheckCircle2
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import UnderlineTabs from '../../components/UnderlineTabs.vue';
import SalaryScalePrintModal from '../../components/SalaryScalePrintModal.vue';

const route = useRoute();
const router = useRouter();

// ─── Scale ID from Route ───
const scaleId = computed(() => Number(route.params.id) || 3);

// ─── Active Tab State ───
const activeTab = ref('matrix');
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3500);
};

// ─── Types Strictly Aligned with HR_Schema_final-v4.sql lines 1044–1109 ───
export interface StepDetail {
  step_number: number;
  amount: number;
  increment_years: number | null;
  description: string;
}

export interface GradeDetail {
  id: number;
  code: string;
  name: string;
  level: number;
  roman_level: string;
  base_salary: number;
  ceiling_salary: number;
  description: string;
  attached_positions_count: number;
  sample_titles: string[];
  steps: StepDetail[];
}

export interface ScaleDetailData {
  id: number;
  uuid: string;
  code: string;
  entity_id: number;
  entity_name: string;
  effective_from: string;
  effective_to: string | null;
  number_of_steps: number;
  currency_code: string;
  currency_name: string;
  is_default: boolean;
  state: 'active' | 'inactive';
  grades: GradeDetail[];
}

// ─── Scales Database (Matching User's Reference Screenshot) ───
const scalesDatabase = ref<Record<number, ScaleDetailData>>({
  3: {
    id: 3,
    uuid: 'sm-003',
    code: '00124',
    entity_id: 1,
    entity_name: 'QMT Business Group',
    effective_from: '2023-07-01',
    effective_to: '2026-07-07',
    number_of_steps: 3,
    currency_code: 'ETB',
    currency_name: 'Ethiopian Birr',
    is_default: true,
    state: 'active',
    grades: [
      {
        id: 1,
        code: 'C1',
        name: 'Operational Support',
        level: 1,
        roman_level: 'I',
        base_salary: 4500,
        ceiling_salary: 4500,
        description: 'Custodial, driving, courier and security service personnel supporting enterprise branch operations.',
        attached_positions_count: 8,
        sample_titles: ['Office Assistant', 'Driver', 'Facilities Guard'],
        steps: [
          { step_number: 1, amount: 4500, increment_years: null, description: 'Starting probationary / entry step' },
          { step_number: 2, amount: 4115, increment_years: 2, description: 'Core operational step advancement' },
          { step_number: 3, amount: 4115, increment_years: 2, description: 'Senior qualification ceiling step' }
        ]
      },
      {
        id: 2,
        code: 'C2',
        name: 'Technical Clerical',
        level: 2,
        roman_level: 'II',
        base_salary: 4500,
        ceiling_salary: 4500,
        description: 'Administrative associates, clerical officers, dispatchers, and technical assistants.',
        attached_positions_count: 14,
        sample_titles: ['Data Entry Clerk', 'Accounts Assistant', 'Customer Rep'],
        steps: [
          { step_number: 1, amount: 4500, increment_years: null, description: 'Entry Baseline' },
          { step_number: 2, amount: 4500, increment_years: 2, description: 'Proficiency progression step' },
          { step_number: 3, amount: 4500, increment_years: 2, description: 'Grade maximum ceiling step' }
        ]
      },
      {
        id: 3,
        code: 'B2',
        name: 'Professional Staff',
        level: 3,
        roman_level: 'III',
        base_salary: 4500,
        ceiling_salary: 4500,
        description: 'Degree-qualified analysts, accountants, legal specialists, and systems engineers.',
        attached_positions_count: 22,
        sample_titles: ['Senior Accountant', 'Software Engineer', 'HR Officer'],
        steps: [
          { step_number: 1, amount: 4500, increment_years: null, description: 'Entry Baseline' },
          { step_number: 2, amount: 4500, increment_years: 2, description: 'Professional milestone progression' },
          { step_number: 3, amount: 4500, increment_years: 2, description: 'Lead specialist band ceiling' }
        ]
      },
      {
        id: 4,
        code: 'B1',
        name: 'Section Heads & Leads',
        level: 4,
        roman_level: 'IV',
        base_salary: 4500,
        ceiling_salary: 4500,
        description: 'Unit leaders, operational supervisors, and chief technical leads managing departments.',
        attached_positions_count: 10,
        sample_titles: ['Unit Head', 'Operations Lead', 'Audit Supervisor'],
        steps: [
          { step_number: 1, amount: 4500, increment_years: null, description: 'Entry Baseline' },
          { step_number: 2, amount: 4500, increment_years: 2, description: 'Supervisory tenure progression' },
          { step_number: 3, amount: 4500, increment_years: 2, description: 'Senior management ceiling' }
        ]
      },
      {
        id: 5,
        code: 'A3',
        name: 'Department Directors',
        level: 5,
        roman_level: 'V',
        base_salary: 4500,
        ceiling_salary: 4500,
        description: 'Division directors, general counsel, and enterprise functional executives.',
        attached_positions_count: 4,
        sample_titles: ['Finance Director', 'Managing Director', 'CTO'],
        steps: [
          { step_number: 1, amount: 4500, increment_years: null, description: 'Entry Baseline' },
          { step_number: 2, amount: 4500, increment_years: 2, description: 'Executive tenure increment' },
          { step_number: 3, amount: 4500, increment_years: 2, description: 'Executive cap ceiling' }
        ]
      }
    ]
  }
});

// Current Active Scale
const currentScale = computed<ScaleDetailData>(() => {
  return scalesDatabase.value[scaleId.value] || scalesDatabase.value[3];
});

// ─── Currency & Date Formatting ───
const formatCurrency = (val: number): string => {
  return new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2
  }).format(val);
};

const formatDate = (dateStr: string | null): string => {
  if (!dateStr) return 'Present';
  const d = new Date(dateStr);
  return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
};

// ─── Metrics Computed ───
const totalGrades = computed(() => currentScale.value.grades.length);
const totalSteps = computed(() => currentScale.value.number_of_steps);

const minEntryPay = computed(() => {
  const allBases = currentScale.value.grades.map(g => g.base_salary);
  return allBases.length > 0 ? Math.min(...allBases) : 4500;
});

const maxCeilingPay = computed(() => {
  return 38740; // Guardrail maximum from reference design
});

// ─── Read-Only View Detail Modal State (Rule: Zero Editing on View Page) ───
const showViewModal = ref(false);
const selectedGradeForView = ref<GradeDetail | null>(null);

const openViewGradeModal = (grade: GradeDetail) => {
  selectedGradeForView.value = grade;
  showViewModal.value = true;
};

// ─── Print Settings Drawer/Modal State ───
const showPrintModal = ref(false);

const handleOpenPrint = () => {
  showPrintModal.value = true;
};

const handleEditScale = () => {
  router.push(`/hr/salary-scales/create?edit=${currentScale.value.id}`);
};

// Breadcrumb (Clean Page Names ONLY: Exact Sidebar Page Name)
const breadcrumbItems = computed(() => [
  { label: 'Salary Scales', to: '/hr/salary-scales' },
  { label: currentScale.value.id === 3 ? 'Haleta Addis Ababa' : currentScale.value.entity_name }
]);

const tabs = computed(() => [
  { id: 'matrix', label: 'Salary Matrix Sheet' },
  { id: 'grades', label: 'Job Grade Details' }
]);
</script>

<template>
  <div class="salary-scale-detail-page">
    <!-- ═══ TOP DOCUMENT ACTION BAR (Clean Breadcrumb Only - Zero Back Button) ═══ -->
    <div class="top-nav-bar no-print">
      <div class="top-bar-left">
        <AppBreadcrumb :items="breadcrumbItems" />
      </div>

      <div class="top-bar-right">
        <button type="button" class="btn-pdf-export" @click="handleOpenPrint">
          <Printer :size="14" />
          <span>Print / PDF Export</span>
        </button>
      </div>
    </div>

    <!-- Toast Notification -->
    <div v-if="toastMessage" class="quick-toast-banner no-print">
      <CheckCircle2 :size="15" class="toast-icon" />
      <span>{{ toastMessage }}</span>
    </div>

    <!-- ═══ OFFICIAL SCALE HEADER CARD (Matching Reference Image) ═══ -->
    <div class="scale-document-header clean-card">
      <div class="doc-header-main">
        <div class="doc-identity-side">
          <!-- Logo Emblem with Stylized Initial (Matching QMT Logo in Screenshot) -->
          <div class="entity-avatar-logo">
            <svg class="logo-svg" viewBox="0 0 44 44" fill="none">
              <circle cx="22" cy="22" r="21" stroke="#0B529C" stroke-width="2" fill="#f8fafc" />
              <path d="M12 30V15L22 25L32 15V30" stroke="#0B529C" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
              <path d="M12 21L22 30L32 21" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>

          <div class="entity-info-block">
            <h1 class="entity-title">{{ currentScale.entity_name }}</h1>
            <div class="entity-sub-row">
              <span class="entity-code font-mono">Code-{{ currentScale.code }} - </span>
              <span class="status-pill status-pill-active">
                {{ currentScale.state === 'active' ? 'Active' : 'Inactive' }}
              </span>
            </div>
          </div>
        </div>

        <!-- Plain-Text Metadata (Calendar & Currency Lines: Clean Typography) -->
        <div class="doc-meta-side">
          <div class="meta-line">
            <Calendar :size="14" class="meta-icon" />
            <span class="meta-text">{{ formatDate(currentScale.effective_from) }} – {{ formatDate(currentScale.effective_to) }}</span>
          </div>
          <div class="meta-line">
            <Banknote :size="14" class="meta-icon" />
            <span class="meta-text">{{ currentScale.currency_code }} — {{ currentScale.currency_name }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- ═══ UNIFIED WHITE SECTION (Metrics Columns + Information Narrative + Tabs) ═══ -->
    <div class="salary-scale-middle-card clean-card no-print">
      <!-- 1. The Matrix Columns (4 Minimalist Metric Cards) -->
      <div class="metrics-grid-row">
        <div class="metric-card-box">
          <div class="metric-top-label">CONFIGURED JOB GRADES</div>
          <div class="metric-main-val">{{ totalGrades }} Grades</div>
          <div class="metric-sub-label">Seniority Level 1 through Level {{ totalGrades }}</div>
        </div>

        <div class="metric-card-box">
          <div class="metric-top-label">PROGRESSION STEPS</div>
          <div class="metric-main-val">{{ totalSteps }} Steps</div>
          <div class="metric-sub-label">Present on all days</div>
        </div>

        <div class="metric-card-box">
          <div class="metric-top-label">MINIMUM ENTRY PAY</div>
          <div class="metric-main-val font-mono">
            {{ formatCurrency(minEntryPay) }} <span class="val-currency">{{ currentScale.currency_code }}</span>
          </div>
          <div class="metric-sub-label">Dec 2024 Evaluation</div>
        </div>

        <div class="metric-card-box">
          <div class="metric-top-label">MAXIMUM GRADE CEILING</div>
          <div class="metric-main-val font-mono">
            {{ formatCurrency(maxCeilingPay) }} <span class="val-currency">{{ currentScale.currency_code }}</span>
          </div>
          <div class="metric-sub-label">Monthly base &amp; allowances</div>
        </div>
      </div>

      <!-- 2. Centralized Information Section with Text -->
      <div class="salary-scale-info-section">
        <p class="info-narrative-text">
          All records and documentation for this salary matrix are centralized below. While the Salary Matrix Sheet presents high-level highlights and key indicators, you can access detailed, granular information by navigating through each specific tab. If any details are outdated or need to be updated in any way, please click on the 
          <a href="#" class="edit-salary-link" @click.prevent="handleEditScale">Edit Salary Scale</a> 
          to make the necessary changes.
        </p>
      </div>

      <!-- 3. The Tabs -->
      <div class="view-tabs-container">
        <UnderlineTabs :tabs="tabs" v-model="activeTab" />
      </div>
    </div>

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- TAB 1: COMPENSATION MATRIX GRID (Matching User's Reference UI) -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <div v-if="activeTab === 'matrix'" class="matrix-sheet-card clean-card print-visible">
      <!-- Printable Document Header (Appears only when printed) -->
      <div class="print-official-header only-print">
        <h2>{{ currentScale.entity_name }}</h2>
        <h3>የመንግሥትና የድርጅት ሠራተኞች የደመወዝ ስኬል / Master Salary Scale Matrix</h3>
        <p>Effective Date: {{ formatDate(currentScale.effective_from) }} | Currency: {{ currentScale.currency_code }} ({{ currentScale.currency_name }})</p>
      </div>

      <!-- Matrix Header Row -->
      <div class="matrix-sheet-topbar no-print">
        <div class="matrix-topbar-left">
          <h2 class="matrix-sheet-title">Compensation Matrix Grid</h2>
          <p class="matrix-sheet-hint">
            Horizontal step progression path for all {{ totalGrades }} recognized salary bands in Haleta Addis Ababa HQ.
          </p>
        </div>
        <div class="matrix-topbar-right">
          <span class="currency-mode-tag">
            Value Shown in {{ currentScale.currency_code }} (Monthly)
          </span>
        </div>
      </div>

      <!-- The 2D Salary Grid Table (Clean Minimalist: Level | Job Grade name | Bse Salary | Steps | Ceiling | View) -->
      <div class="matrix-table-wrapper">
        <table class="compensation-matrix-table">
          <thead>
            <tr>
              <th class="th-level" style="width: 65px;">Level</th>
              <th class="th-name">Job Grade name</th>
              <th class="th-base">Bse Salary</th>
              <!-- Dynamic Step Columns 1..N -->
              <th 
                v-for="s in currentScale.number_of_steps" 
                :key="'col-step-' + s" 
                class="th-step"
              >
                Step {{ s }}
              </th>
              <th class="th-ceiling">Ceiling Salary</th>
              <th class="th-action no-print" style="width: 100px; text-align: center;">View</th>
            </tr>
          </thead>
          <tbody>
            <tr 
              v-for="grade in currentScale.grades" 
              :key="grade.id" 
              class="matrix-data-row"
            >
              <!-- Level Column: 1, 2, 3 ... (Tertiary Color #737373) -->
              <td class="td-level">{{ grade.level }}</td>

              <!-- Job Grade Name (Darker Secondary Color #404040, Font-Weight 600) -->
              <td class="td-name">{{ grade.name }}</td>

              <!-- Base Salary (Tertiary Color #737373) -->
              <td class="td-amount font-mono">
                {{ formatCurrency(grade.base_salary) }} {{ currentScale.currency_code }}
              </td>

              <!-- Steps Columns (1..N) (Tertiary Color #737373) -->
              <td 
                v-for="step in grade.steps" 
                :key="'step-' + grade.id + '-' + step.step_number" 
                class="td-amount font-mono"
              >
                {{ formatCurrency(step.amount) }} {{ currentScale.currency_code }}
              </td>

              <!-- Ceiling Salary (Tertiary Color #737373) -->
              <td class="td-amount font-mono">
                {{ formatCurrency(grade.ceiling_salary) }} {{ currentScale.currency_code }}
              </td>

              <!-- View Detail Action (Brand Color #0B529C with Underline) -->
              <td class="td-action no-print" style="text-align: center;">
                <button 
                  type="button" 
                  class="btn-view-detail-link" 
                  @click="openViewGradeModal(grade)"
                >
                  View Detail
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Printable Document Footer / Signatures -->
      <div class="print-official-footer only-print">
        <div class="print-sign-row">
          <div class="sign-box">
            <p class="sign-title">Prepared By: Compensation Analyst</p>
            <div class="sign-line"></div>
            <p class="sign-sub">Signature &amp; Date</p>
          </div>
          <div class="sign-box">
            <p class="sign-title">Reviewed By: Human Resources Director</p>
            <div class="sign-line"></div>
            <p class="sign-sub">Signature &amp; Date</p>
          </div>
          <div class="sign-box">
            <p class="sign-title">Approved By: Chief Executive Officer</p>
            <div class="sign-line"></div>
            <p class="sign-sub">Official Stamp &amp; Signature</p>
          </div>
        </div>
      </div>
    </div>

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- TAB 2: JOB GRADE DETAILS (Read-Only Specification Cards)        -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <div v-if="activeTab === 'grades'" class="grades-spec-container no-print">
      <div class="grade-specs-grid">
        <div 
          v-for="grade in currentScale.grades" 
          :key="'spec-' + grade.id" 
          class="grade-spec-card clean-card"
        >
          <div class="grade-spec-header">
            <div class="spec-header-left">
              <span class="spec-grade-badge">Grade {{ grade.code }}</span>
              <span class="spec-level-tag">Level {{ grade.level }} ({{ grade.roman_level }})</span>
            </div>
            <div class="spec-header-right">
              <button 
                type="button" 
                class="btn-view-detail-link" 
                @click="openViewGradeModal(grade)"
              >
                View Detail
              </button>
            </div>
          </div>

          <h3 class="spec-grade-title">{{ grade.name }}</h3>
          <p class="spec-grade-desc">{{ grade.description || 'No description configured for this grade band.' }}</p>

          <div class="spec-guardrails-row">
            <div class="guardrail-box">
              <span class="guardrail-label">Starting Base</span>
              <span class="guardrail-value font-mono">{{ formatCurrency(grade.base_salary) }} {{ currentScale.currency_code }}</span>
            </div>
            <div class="guardrail-box">
              <span class="guardrail-label">Ceiling Salary</span>
              <span class="guardrail-value font-mono font-bold">{{ formatCurrency(grade.ceiling_salary) }} {{ currentScale.currency_code }}</span>
            </div>
            <div class="guardrail-box">
              <span class="guardrail-label">Steps Ladder</span>
              <span class="guardrail-value">{{ grade.steps.length }} Steps</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- READ-ONLY VIEW DETAIL MODAL (No Inputs / No Editing)           -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <div v-if="showViewModal && selectedGradeForView" class="modal-backdrop" @click="showViewModal = false">
      <div class="modal-dialog-box modal-lg" @click.stop>
        <div class="modal-dialog-header">
          <div>
            <h3 class="modal-dialog-title">{{ selectedGradeForView.name }}</h3>
            <span class="modal-dialog-subtitle">Seniority Level {{ selectedGradeForView.level }} ({{ selectedGradeForView.roman_level }}) · Grade {{ selectedGradeForView.code }}</span>
          </div>
          <button type="button" class="btn-modal-close" @click="showViewModal = false">
            <X :size="16" />
          </button>
        </div>

        <div class="modal-dialog-body">
          <!-- Read-Only Summary Grid -->
          <div class="view-summary-grid">
            <div class="summary-item">
              <span class="summary-label">Starting Base Salary</span>
              <span class="summary-val font-mono">{{ formatCurrency(selectedGradeForView.base_salary) }} {{ currentScale.currency_code }}</span>
            </div>
            <div class="summary-item">
              <span class="summary-label">Maximum Ceiling Salary</span>
              <span class="summary-val font-mono font-bold">{{ formatCurrency(selectedGradeForView.ceiling_salary) }} {{ currentScale.currency_code }}</span>
            </div>
            <div class="summary-item">
              <span class="summary-label">Attached Seats</span>
              <span class="summary-val">{{ selectedGradeForView.attached_positions_count }} Positions</span>
            </div>
          </div>

          <!-- Description Box -->
          <div v-if="selectedGradeForView.description" class="view-desc-card">
            <span class="desc-card-label">Grade Scope &amp; Responsibilities</span>
            <p class="desc-card-text">{{ selectedGradeForView.description }}</p>
          </div>

          <!-- Read-Only Steps Table -->
          <div class="view-steps-block">
            <div class="steps-block-header">Step Progression Ladder</div>
            <table class="view-steps-table">
              <thead>
                <tr>
                  <th style="width: 70px;">Step</th>
                  <th>Monthly Amount</th>
                  <th>Wait Year to Qualify</th>
                  <th>Step Progression Description</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="step in selectedGradeForView.steps" :key="step.step_number">
                  <td class="font-semibold">Step {{ step.step_number }}</td>
                  <td class="font-mono">{{ formatCurrency(step.amount) }} {{ currentScale.currency_code }}</td>
                  <td>{{ step.step_number === 1 ? 'Entry Baseline' : (step.increment_years ? step.increment_years + ' Years' : '2 Years') }}</td>
                  <td>{{ step.description || (step.step_number === 1 ? 'Entry starting step' : step.step_number === selectedGradeForView.steps.length ? 'Grade ceiling maximum salary' : 'Standard advancement step') }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="modal-dialog-footer">
          <button type="button" class="btn-modal-close-action" @click="showViewModal = false">
            Close
          </button>
        </div>
      </div>
    </div>

    <!-- ═══ HIGH-FIDELITY PRINT SETTINGS & LIVE PREVIEW MODAL / DRAWER ═══ -->
    <SalaryScalePrintModal 
      v-model:show="showPrintModal" 
      :scale="currentScale" 
    />
  </div>
</template>

<style scoped>
/* ═══════════════════════════════════════════ */
/* SALARY SCALE DETAIL VIEW                    */
/* ═══════════════════════════════════════════ */

.salary-scale-detail-page {
  min-height: 100vh;
  padding: 24px 28px 60px;
  background-color: #f8fafc;
}

/* ═══ TOP DOCUMENT ACTION BAR ═══ */
.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}

.top-bar-left {
  display: flex;
  align-items: center;
}

.top-bar-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.btn-pdf-export {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
  transition: all 0.15s ease;
}
.btn-pdf-export:hover {
  background-color: #f1f5f9;
  border-color: #cbd5e1;
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

/* ═══ CARD BASES ═══ */
.clean-card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}

/* ═══ OFFICIAL SCALE HEADER CARD ═══ */
.scale-document-header {
  padding: 22px 24px;
  margin-bottom: 20px;
}

.doc-header-main {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
}

.doc-identity-side {
  display: flex;
  align-items: center;
  gap: 16px;
}

.entity-avatar-logo {
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.logo-svg {
  width: 44px;
  height: 44px;
}

.entity-info-block {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.entity-title {
  font-size: 17px;
  font-weight: 700;
  color: #1e293b;
  margin: 0;
}

.entity-sub-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #64748b;
}

.entity-code {
  color: #64748b;
}

.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 9px;
  font-size: 11.5px;
  font-weight: 600;
  border-radius: 9999px;
}
.status-pill-active {
  background-color: #ecfdf5;
  color: #059669;
}

.doc-meta-side {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 6px;
}

.meta-line {
  display: flex;
  align-items: center;
  gap: 7px;
  font-size: 13px;
  color: #64748b;
}

.meta-icon {
  color: #94a3b8;
}

.meta-text {
  font-weight: 500;
  color: #475569;
}

/* ═══ UNIFIED MIDDLE CARD (Metrics + Info Narrative + Tabs) ═══ */
.salary-scale-middle-card {
  padding: 24px 24px 0 24px;
  margin-bottom: 20px;
}

/* ═══ METRICS CARDS ROW ═══ */
.metrics-grid-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 20px;
}

@media (max-width: 960px) {
  .metrics-grid-row {
    grid-template-columns: repeat(2, 1fr);
  }
}

.metric-card-box {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
}

.metric-top-label {
  font-size: 11px;
  font-weight: 600;
  color: #737373;
  letter-spacing: 0.3px;
}

.metric-main-val {
  font-size: 24px;
  font-weight: 600;
  color: #404040;
  margin: 6px 0 4px;
}

.val-currency {
  font-size: 14px;
  font-weight: 500;
  color: #737373;
}

.metric-sub-label {
  font-size: 12px;
  color: #737373;
}

/* ═══ CENTRALIZED INFO NARRATIVE SECTION ═══ */
.salary-scale-info-section {
  background-color: transparent;
  padding: 0;
  margin-bottom: 20px;
}

.info-narrative-text {
  font-size: 12.5px;
  color: #737373;
  line-height: 1.6;
  margin: 0;
}

.edit-salary-link {
  color: #0B529C;
  font-weight: 600;
  text-decoration: underline;
  cursor: pointer;
  transition: color 0.15s ease;
}
.edit-salary-link:hover {
  color: #083b70;
}

/* ═══ VIEW TABS ═══ */
.view-tabs-container {
  margin-bottom: 0;
}

/* ═══ COMPENSATION MATRIX GRID CARD ═══ */
.matrix-sheet-card {
  padding: 22px 24px 28px;
}

.matrix-sheet-topbar {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 20px;
  margin-bottom: 18px;
}

.matrix-sheet-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.matrix-sheet-hint {
  font-size: 12.5px;
  color: #737373;
  margin: 4px 0 0;
}

.currency-mode-tag {
  display: inline-flex;
  align-items: center;
  padding: 4px 14px;
  background-color: #f1f5f9;
  border: 1px solid #e2e8f0;
  color: #737373;
  font-size: 11.5px;
  font-weight: 500;
  border-radius: 9999px;
  white-space: nowrap;
}

.matrix-table-wrapper {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  overflow: hidden;
}

.compensation-matrix-table {
  width: 100%;
  border-collapse: collapse;
}

.compensation-matrix-table th {
  height: 40px;
  padding: 10px 16px;
  background-color: #fafafa;
  color: #525252;
  font-size: 12.5px;
  font-weight: 600;
  text-align: left;
  border: 1px solid #e5e7eb;
}

.compensation-matrix-table td {
  height: 48px;
  padding: 10px 16px;
  font-size: 13px;
  border: 1px solid #e5e7eb;
  vertical-align: middle;
}

.td-level {
  font-weight: 400;
  color: #737373;
}

.td-name {
  font-weight: 600;
  color: #404040;
}

.td-amount {
  font-weight: 400;
  color: #737373;
}

.btn-view-detail-link {
  border: none;
  background: transparent;
  color: #0B529C;
  font-size: 12.5px;
  font-weight: 600;
  text-decoration: underline;
  cursor: pointer;
  padding: 0;
  transition: color 0.15s ease;
}
.btn-view-detail-link:hover {
  color: #083b70;
  text-decoration: underline;
}

/* ═══ TAB 2: JOB GRADE DETAILS ═══ */
.grades-spec-container {
  margin-top: 4px;
}

.grade-specs-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

@media (max-width: 900px) {
  .grade-specs-grid {
    grid-template-columns: 1fr;
  }
}

.grade-spec-card {
  padding: 20px 22px;
}

.grade-spec-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.spec-header-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.spec-grade-badge {
  display: inline-flex;
  align-items: center;
  padding: 2px 9px;
  background-color: #e0f2fe;
  color: #0284c7;
  font-size: 11.5px;
  font-weight: 600;
  border-radius: 4px;
}

.spec-level-tag {
  font-size: 12px;
  color: #64748b;
  font-weight: 500;
}

.spec-grade-title {
  font-size: 15px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 6px;
}

.spec-grade-desc {
  font-size: 12.5px;
  color: #64748b;
  line-height: 1.5;
  margin: 0 0 16px;
}

.spec-guardrails-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  background-color: #f8fafc;
  padding: 12px 14px;
  border-radius: 8px;
}

.guardrail-box {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.guardrail-label {
  font-size: 11px;
  color: #737373;
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.guardrail-value {
  font-size: 13px;
  color: #1e293b;
}

/* ═══ READ-ONLY VIEW DETAIL MODAL ═══ */
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
  max-width: 640px;
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
  align-items: flex-start;
  justify-content: space-between;
  padding: 20px 24px 14px;
  border-bottom: 1px solid #f1f5f9;
}

.modal-dialog-title {
  font-size: 16px;
  font-weight: 600;
  color: #1e293b;
  margin: 0;
}

.modal-dialog-subtitle {
  font-size: 12.5px;
  color: #64748b;
  margin-top: 2px;
  display: block;
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
  padding: 18px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  max-height: 70vh;
  overflow-y: auto;
}

.view-summary-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  background-color: #f8fafc;
  padding: 12px 16px;
  border-radius: 8px;
  border: 1px solid #f1f5f9;
}

.summary-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.summary-label {
  font-size: 11px;
  color: #737373;
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.summary-val {
  font-size: 13.5px;
  color: #1e293b;
}

.view-desc-card {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.desc-card-label {
  font-size: 11.5px;
  font-weight: 600;
  color: #475569;
}

.desc-card-text {
  font-size: 13px;
  color: #64748b;
  line-height: 1.5;
  margin: 0;
}

.view-steps-block {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.steps-block-header {
  font-size: 12.5px;
  font-weight: 600;
  color: #475569;
}

.view-steps-table {
  width: 100%;
  border-collapse: collapse;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  overflow: hidden;
}

.view-steps-table th {
  height: 32px;
  padding: 6px 12px;
  background-color: #fafafa;
  color: #555555;
  font-size: 11.5px;
  font-weight: 600;
  text-align: left;
  border-bottom: 1px solid #e5e7eb;
}

.view-steps-table td {
  height: 36px;
  padding: 6px 12px;
  font-size: 12.5px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
}

.view-steps-table tr:last-child td {
  border-bottom: none;
}

.modal-dialog-footer {
  padding: 12px 24px 16px;
  border-top: 1px solid #f1f5f9;
  display: flex;
  justify-content: flex-end;
}

.btn-modal-close-action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 36px;
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
.btn-modal-close-action:hover {
  background-color: #09427d;
}

/* Helpers */
.font-mono { font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', monospace; }
.font-semibold { font-weight: 600; }
.font-bold { font-weight: 700; }

/* ═══ PRINT STYLES ═══ */
@media print {
  .no-print { display: none !important; }
  .only-print { display: block !important; }
  .salary-scale-detail-page { padding: 0; background: #fff; }
  .clean-card { border: none; box-shadow: none; }
  .compensation-matrix-table th { background: #f1f5f9 !important; -webkit-print-color-adjust: exact; }
}

.only-print {
  display: none;
}
</style>
