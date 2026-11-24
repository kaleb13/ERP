<script setup lang="ts">
import { ref, computed } from 'vue';
import FormToggle from './FormToggle.vue';
import FormRadio from './FormRadio.vue';
import PrintPreviewDrawer from './PrintPreviewDrawer.vue';
import type { ScaleDetailData } from '../views/hr/SalaryScaleDetail.vue';

const props = defineProps<{
  show: boolean;
  scale: ScaleDetailData;
}>();

const emit = defineEmits<{
  'update:show': [value: boolean];
}>();

// ─── Print Settings Reactive State (Matching Figma Node 5005:78527) ───
const printSettings = ref({
  showAmharicHeader: true,
  showOfficialStamp: true,
  showSignatures: true,
  displayMode: 'detailed' as 'detailed' | 'summary'
});

// Currency Formatter
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

// Summary metrics
const minPay = computed(() => {
  const allBases = props.scale.grades.map(g => g.base_salary);
  return allBases.length > 0 ? Math.min(...allBases) : 4500;
});

const maxPay = computed(() => {
  const allCeilings = props.scale.grades.map(g => g.ceiling_salary);
  return allCeilings.length > 0 ? Math.max(...allCeilings) : 38740;
});
</script>

<template>
  <PrintPreviewDrawer
    :show="show"
    title="Print Settings"
    subtitle="Configure Document layout and Visibility"
    documentTitle="Master Salary Scale Matrix"
    :documentSubtitle="scale.entity_name"
    :documentCode="'SCALE-' + (scale.code || '00124')"
    :documentDate="formatDate(scale.effective_from) + ' – ' + formatDate(scale.effective_to)"
    :documentMeta="scale.currency_code + ' — ' + scale.currency_name"
    :currentPage="1"
    :totalPages="1"
    @update:show="(val) => emit('update:show', val)"
  >
    <!-- ─── Content-Specific Custom Settings on the Left ─── -->
    <template #settings>
      <!-- Amharic Official Header -->
      <div class="setting-toggle-row">
        <span class="setting-toggle-title">Amharic Official Header</span>
        <FormToggle v-model="printSettings.showAmharicHeader" size="sm" aria-label="Amharic Official Header" />
      </div>

      <!-- Official Stamp & Seal -->
      <div class="setting-toggle-row">
        <span class="setting-toggle-title">Official Stamp &amp; Seal</span>
        <FormToggle v-model="printSettings.showOfficialStamp" size="sm" aria-label="Official Stamp and Seal" />
      </div>

      <!-- Signatures Section -->
      <div class="setting-toggle-row">
        <span class="setting-toggle-title">Signatures &amp; Endorsement</span>
        <FormToggle v-model="printSettings.showSignatures" size="sm" aria-label="Signatures and Endorsement" />
      </div>

      <!-- Matrix Display Layout Selector -->
      <div class="layout-selector-section">
        <span class="selector-section-label">Salary Matrix Display Layout</span>

        <!-- Option 1: Detail List / 2D Grid -->
        <div
          class="layout-radio-option"
          :class="{ 'radio-selected': printSettings.displayMode === 'detailed' }"
          @click="printSettings.displayMode = 'detailed'"
        >
          <FormRadio
            v-model="printSettings.displayMode"
            name="salaryDisplayMode"
            value="detailed"
            size="sm"
            label="Detail Matrix Grid"
            description="Full 2D compensation grid with all grade bands and step progression columns."
          />
        </div>

        <!-- Option 2: Summary Mode -->
        <div
          class="layout-radio-option"
          :class="{ 'radio-selected': printSettings.displayMode === 'summary' }"
          @click="printSettings.displayMode = 'summary'"
        >
          <FormRadio
            v-model="printSettings.displayMode"
            name="salaryDisplayMode"
            value="summary"
            size="sm"
            label="Summary Mode"
            description="Displays a compact card showing consolidated pay guardrails and grade ranges."
          />
        </div>
      </div>
    </template>

    <!-- ─── Printable Document Sheet on the Right ─── -->
    <template #document>
      <!-- Amharic Official Banner (Optional) -->
      <div v-if="printSettings.showAmharicHeader" class="amharic-header-group">
        <span class="amharic-table-pill">ሠንጠረዥ-2</span>
        <h2 class="amharic-doc-title">የመንግሥትና የድርጅት ሠራተኞች የደመወዝ ስኬል የመሸጋገሪያ ሠንጠረዥ</h2>
        <span class="amharic-date-sub">ጥቅምት 2017 ዓ.ም</span>
      </div>

      <!-- Metadata Summary Card (Figma Node 5005:78562) -->
      <div class="sheet-meta-card">
        <div class="meta-card-item">
          <span class="meta-item-lbl">Owning Entity</span>
          <span class="meta-item-val">{{ scale.entity_name }}</span>
        </div>
        <div class="meta-card-item">
          <span class="meta-item-lbl">Grid Architecture</span>
          <span class="meta-item-val">{{ scale.grades.length }} Grades × {{ scale.number_of_steps }} Steps</span>
        </div>
        <div class="meta-card-item">
          <span class="meta-item-lbl">Generated Date</span>
          <span class="meta-item-val">{{ new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) }}</span>
        </div>
      </div>

      <!-- ─── DETAILED 2D MATRIX VIEW (Figma Node 5005:78573) ─── -->
      <div v-if="printSettings.displayMode === 'detailed'" class="sheet-matrix-table-container">
        <table class="official-salary-grid-table">
          <thead>
            <tr>
              <th class="th-lvl" style="width: 55px;">ደረጃ<br><span class="sub-th">Level</span></th>
              <th class="th-name">የሥራ መደብ / Job Grade Band</th>
              <th class="th-base">መነሻ ደመወዝ<br><span class="sub-th">Base Salary</span></th>
              <th 
                v-for="s in scale.number_of_steps" 
                :key="'step-head-' + s" 
                class="th-step"
              >
                እርከን {{ s }}<br><span class="sub-th">Step {{ s }}</span>
              </th>
              <th class="th-ceil">ጣሪያ ደመወዝ<br><span class="sub-th">Ceiling Salary</span></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="grade in scale.grades" :key="grade.id">
              <td class="td-lvl font-bold">{{ grade.roman_level || ('LV ' + grade.level) }}</td>
              <td class="td-name font-medium">
                <span class="grade-title-text">{{ grade.name }}</span>
                <span class="grade-code-pill font-mono">{{ grade.code }}</span>
              </td>
              <td class="td-amt font-mono">{{ formatCurrency(grade.base_salary) }}</td>
              <td 
                v-for="step in grade.steps" 
                :key="'step-' + grade.id + '-' + step.step_number" 
                class="td-amt font-mono"
              >
                {{ formatCurrency(step.amount) }}
              </td>
              <td class="td-amt font-mono font-bold">{{ formatCurrency(grade.ceiling_salary) }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- ─── SUMMARY MODE VIEW ─── -->
      <div v-else class="sheet-summary-mode-container">
        <div class="summary-highlight-cards">
          <div class="summary-stat-box">
            <span class="stat-lbl">Total Configured Grades</span>
            <span class="stat-num">{{ scale.grades.length }} Pay Bands</span>
          </div>
          <div class="summary-stat-box">
            <span class="stat-lbl">Progression Step Intervals</span>
            <span class="stat-num">{{ scale.number_of_steps }} Increments</span>
          </div>
          <div class="summary-stat-box">
            <span class="stat-lbl">Minimum Starting Floor</span>
            <span class="stat-num font-mono">{{ formatCurrency(minPay) }} {{ scale.currency_code }}</span>
          </div>
          <div class="summary-stat-box">
            <span class="stat-lbl">Maximum Ceiling Cap</span>
            <span class="stat-num font-mono">{{ formatCurrency(maxPay) }} {{ scale.currency_code }}</span>
          </div>
        </div>

        <table class="summary-grades-compact-table">
          <thead>
            <tr>
              <th style="width: 70px;">Level</th>
              <th>Job Grade Band</th>
              <th>Floor Base Pay</th>
              <th>Ceiling Cap Pay</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="grade in scale.grades" :key="'sum-' + grade.id">
              <td class="font-bold">Level {{ grade.level }}</td>
              <td>{{ grade.name }}</td>
              <td class="font-mono">{{ formatCurrency(grade.base_salary) }} {{ scale.currency_code }}</td>
              <td class="font-mono font-bold">{{ formatCurrency(grade.ceiling_salary) }} {{ scale.currency_code }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- ─── FOOTER SIGNATURES & OFFICIAL SEAL ─── -->
      <div v-if="printSettings.showSignatures || printSettings.showOfficialStamp" class="sheet-endorsement-footer">
        <!-- Official Stamp Seal -->
        <div v-if="printSettings.showOfficialStamp" class="official-seal-wrapper">
          <svg class="official-stamp-svg" viewBox="0 0 160 160">
            <circle cx="80" cy="80" r="74" stroke="#0B529C" stroke-width="2.5" fill="none" opacity="0.85" />
            <circle cx="80" cy="80" r="68" stroke="#0B529C" stroke-width="1.2" stroke-dasharray="3,2" fill="none" opacity="0.85" />
            <path id="curveTopScale" d="M 22 80 A 58 58 0 0 1 138 80" fill="none" />
            <text font-size="8.5" font-weight="700" fill="#0B529C" opacity="0.85" letter-spacing="1.2">
              <textPath href="#curveTopScale" startOffset="50%" text-anchor="middle">
                ★ የገንዘብ ሚኒስቴር / COMPENSATION SEAL ★
              </textPath>
            </text>
            <polygon points="80,50 83,62 95,62 85,70 88,82 80,74 72,82 75,70 65,62 77,62" fill="#0B529C" opacity="0.85" />
            <text x="80" y="96" font-size="10" font-weight="800" fill="#0B529C" text-anchor="middle" opacity="0.85">APPROVED</text>
            <text x="80" y="107" font-size="7.5" font-weight="600" fill="#0B529C" text-anchor="middle" opacity="0.85">SALARY SCALE</text>
            <path id="curveBottomScale" d="M 138 80 A 58 58 0 0 1 22 80" fill="none" />
            <text font-size="8.5" font-weight="700" fill="#0B529C" opacity="0.85" letter-spacing="1.2">
              <textPath href="#curveBottomScale" startOffset="50%" text-anchor="middle">
                HALETA ENTERPRISE ERP SYSTEM
              </textPath>
            </text>
          </svg>
        </div>

        <!-- Signatures Grid -->
        <div v-if="printSettings.showSignatures" class="sheet-signatures-group">
          <div class="sig-column">
            <div class="sig-line"></div>
            <span class="sig-role">Prepared By: Analyst</span>
            <span class="sig-note">Signature &amp; Date</span>
          </div>
          <div class="sig-column">
            <div class="sig-line"></div>
            <span class="sig-role">Verified By: HR Director</span>
            <span class="sig-note">Signature &amp; Date</span>
          </div>
          <div class="sig-column">
            <div class="sig-line"></div>
            <span class="sig-role">Approved By: Managing Director</span>
            <span class="sig-note">Official Signature &amp; Date</span>
          </div>
        </div>
      </div>
    </template>
  </PrintPreviewDrawer>
</template>

<style scoped>
/* ─── Settings Sidebar Custom Styling ─── */
.setting-toggle-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 12px;
  border-bottom: 0.5px solid #f5f5f5;
}

.setting-toggle-title {
  font-family: 'Inter', -apple-system, sans-serif;
  font-size: 14px;
  font-weight: 500;
  line-height: 20px;
  color: #404040; /* Secondary */
}

.layout-selector-section {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-top: 14px;
  padding: 16px 12px;
  border-top: 1px solid #f5f5f5;
}

.selector-section-label {
  font-family: 'Inter', -apple-system, sans-serif;
  font-size: 12px;
  font-weight: 600;
  color: #737373;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.layout-radio-option {
  padding: 12px;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  background: #ffffff;
  cursor: pointer;
  transition: all 0.15s ease;
}

.layout-radio-option:hover {
  border-color: #d4d4d4;
  background: #fafafa;
}

.layout-radio-option.radio-selected {
  border-color: #0b529c;
  background: #f0f7ff;
}

/* ─── Amharic Banner ─── */
.amharic-header-group {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  gap: 4px;
  padding: 8px 0;
  border-bottom: 1px dashed #e5e5e5;
}

.amharic-table-pill {
  font-size: 11px;
  font-weight: 700;
  color: #0b529c;
  background: #e1eefd;
  padding: 2px 8px;
  border-radius: 4px;
}

.amharic-doc-title {
  font-size: 15px;
  font-weight: 700;
  color: #404040;
  margin: 0;
}

.amharic-date-sub {
  font-size: 12px;
  color: #737373;
}

/* ─── Metadata Summary Card (Figma Node 5005:78562) ─── */
.sheet-meta-card {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  padding: 16px 24px;
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
}

.meta-card-item {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.meta-item-lbl {
  font-family: 'Inter', -apple-system, sans-serif;
  font-size: 14px;
  font-weight: 400;
  color: #737373; /* Tertiary */
}

.meta-item-val {
  font-family: 'Inter', -apple-system, sans-serif;
  font-size: 16px;
  font-weight: 600;
  color: #404040; /* Secondary */
}

/* ─── Detailed 2D Matrix Table (Figma Node 5005:78573) ─── */
.sheet-matrix-table-container {
  overflow-x: auto;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
}

.official-salary-grid-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
  text-align: left;
}

.official-salary-grid-table thead th {
  background-color: #fafafa;
  color: #404040;
  font-size: 12px;
  font-weight: 600;
  padding: 10px 8px;
  border-bottom: 1px solid #e5e5e5;
  border-right: 1px solid #e5e5e5;
  text-align: center;
  vertical-align: middle;
}

.official-salary-grid-table thead th:last-child {
  border-right: none;
}

.sub-th {
  font-size: 10px;
  font-weight: 400;
  color: #737373;
}

.official-salary-grid-table tbody td {
  padding: 12px 8px;
  border-bottom: 1px solid #e9eaeb;
  border-right: 1px solid #e9eaeb;
  color: #404040;
}

.official-salary-grid-table tbody td:last-child {
  border-right: none;
}

.td-lvl {
  text-align: center;
  font-weight: 700;
  color: #404040;
}

.td-name {
  min-width: 160px;
}

.grade-title-text {
  display: block;
  font-weight: 500;
  color: #404040;
}

.grade-code-pill {
  display: inline-block;
  font-size: 10px;
  color: #737373;
}

.td-amt {
  text-align: right;
  white-space: nowrap;
}

/* ─── Summary Mode ─── */
.sheet-summary-mode-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.summary-highlight-cards {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}

.summary-stat-box {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stat-lbl {
  font-size: 11px;
  color: #737373;
}

.stat-num {
  font-size: 14px;
  font-weight: 700;
  color: #404040;
}

.summary-grades-compact-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
  border: 1px solid #e5e5e5;
  border-radius: 6px;
}

.summary-grades-compact-table th {
  background: #fafafa;
  padding: 8px 12px;
  border-bottom: 1px solid #e5e5e5;
  text-align: left;
  font-weight: 600;
  color: #404040;
}

.summary-grades-compact-table td {
  padding: 8px 12px;
  border-bottom: 1px solid #f1f5f9;
  color: #404040;
}

/* ─── Footer Signatures & Official Seal ─── */
.sheet-endorsement-footer {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-top: 32px;
  padding-top: 24px;
  border-top: 1px solid #e5e5e5;
}

.official-seal-wrapper {
  width: 120px;
  height: 120px;
}

.official-stamp-svg {
  width: 100%;
  height: 100%;
}

.sheet-signatures-group {
  display: flex;
  gap: 32px;
}

.sig-column {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 140px;
  text-align: center;
  gap: 4px;
}

.sig-line {
  width: 100%;
  height: 1px;
  background: #404040;
  margin-bottom: 6px;
}

.sig-role {
  font-size: 11px;
  font-weight: 600;
  color: #404040;
}

.sig-note {
  font-size: 10px;
  color: #737373;
}
</style>
