<script setup lang="ts">
import { ref, computed } from 'vue';
import { 
  X, Printer, Download, Calendar, Banknote, Building2, Check, FileSpreadsheet
} from 'lucide-vue-next';
import type { ScaleDetailData } from '../views/hr/SalaryScaleDetail.vue';

const props = defineProps<{
  show: boolean;
  scale: ScaleDetailData;
}>();

const emit = defineEmits<{
  'update:show': [value: boolean];
}>();

// ─── Print Settings Reactive State (Matching Image 1) ───
const printSettings = ref({
  showCompanyLogo: true,
  showDocumentTitle: true,
  showAmharicHeader: true,
  showOfficialStamp: true,
  showSignatures: true,
  displayMode: 'detailed' as 'detailed' | 'summary'
});

const closeModal = () => {
  emit('update:show', false);
};

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

// Print execution
const executePrint = () => {
  window.print();
};

const downloadPDF = () => {
  window.print();
};
</script>

<template>
  <div v-if="show" class="print-modal-overlay" @click="closeModal">
    <div class="print-modal-card" @click.stop>
      
      <!-- ═══ MODAL HEADER (Matching Image 1) ═══ -->
      <div class="print-modal-header">
        <div class="header-titles">
          <h2 class="modal-title">Print Settings</h2>
          <p class="modal-subtitle">Configure Document layout and Visibility</p>
        </div>
        <button type="button" class="btn-modal-close" @click="closeModal" aria-label="Close">
          <X :size="20" />
        </button>
      </div>

      <!-- ═══ MODAL BODY: LEFT SETTINGS + RIGHT LIVE PREVIEW (Matching Image 1) ═══ -->
      <div class="print-modal-body">
        
        <!-- ─── LEFT: SETTINGS SIDEBAR ─── -->
        <div class="print-settings-sidebar">
          
          <!-- Company Logo Toggle -->
          <div class="setting-toggle-row">
            <span class="setting-toggle-title">Company Logo</span>
            <label class="switch">
              <input type="checkbox" v-model="printSettings.showCompanyLogo" />
              <span class="slider round"></span>
            </label>
          </div>

          <!-- Document Title Toggle -->
          <div class="setting-toggle-row">
            <span class="setting-toggle-title">Document Title</span>
            <label class="switch">
              <input type="checkbox" v-model="printSettings.showDocumentTitle" />
              <span class="slider round"></span>
            </label>
          </div>

          <!-- Amharic Official Header (Image 2 Inspiration) -->
          <div class="setting-toggle-row">
            <span class="setting-toggle-title">Amharic Official Header</span>
            <label class="switch">
              <input type="checkbox" v-model="printSettings.showAmharicHeader" />
              <span class="slider round"></span>
            </label>
          </div>

          <!-- Official Stamp & Seal (Image 2 Inspiration) -->
          <div class="setting-toggle-row">
            <span class="setting-toggle-title">Official Stamp &amp; Seal</span>
            <label class="switch">
              <input type="checkbox" v-model="printSettings.showOfficialStamp" />
              <span class="slider round"></span>
            </label>
          </div>

          <!-- Signatures Section -->
          <div class="setting-toggle-row">
            <span class="setting-toggle-title">Signatures &amp; Endorsement</span>
            <label class="switch">
              <input type="checkbox" v-model="printSettings.showSignatures" />
              <span class="slider round"></span>
            </label>
          </div>

          <!-- Matrix Display Layout Selector (Matching Image 1 Segmented Radios) -->
          <div class="layout-selector-section">
            <span class="selector-section-label">Salary Matrix Display Layout</span>

            <!-- Option 1: Detail List / 2D Grid -->
            <label class="layout-radio-option" :class="{ 'radio-selected': printSettings.displayMode === 'detailed' }">
              <input 
                type="radio" 
                name="salaryDisplayMode" 
                value="detailed" 
                v-model="printSettings.displayMode" 
              />
              <span class="radio-custom-circle"></span>
              <div class="radio-content">
                <span class="radio-title">Detail Matrix Grid</span>
                <span class="radio-desc">
                  Full 2D compensation grid with all grade bands and step progression columns. Paginated to A4 paper.
                </span>
              </div>
            </label>

            <!-- Option 2: Summary Mode -->
            <label class="layout-radio-option" :class="{ 'radio-selected': printSettings.displayMode === 'summary' }">
              <input 
                type="radio" 
                name="salaryDisplayMode" 
                value="summary" 
                v-model="printSettings.displayMode" 
              />
              <span class="radio-custom-circle"></span>
              <div class="radio-content">
                <span class="radio-title">Summary Mode</span>
                <span class="radio-desc">
                  Displays a compact card showing consolidated pay guardrails and grade ranges. Fits on 1 page.
                </span>
              </div>
            </label>
          </div>

        </div>

        <!-- ─── RIGHT: LIVE SCROLLABLE PREVIEW CANVAS (Matching Image 1 & Image 2) ─── -->
        <div class="print-preview-container">
          <div class="preview-scroll-wrapper">
            
            <!-- White Document Sheet (Real-Time Reactive to Left Controls) -->
            <div class="printable-paper-sheet printable-document-area">
              
              <!-- Sheet Header Group -->
              <div class="sheet-header-block">
                
                <!-- Left: Logo & Titles -->
                <div class="sheet-identity-left">
                  <!-- Company Logo -->
                  <div v-if="printSettings.showCompanyLogo" class="sheet-logo-circle">
                    <svg class="sheet-logo-svg" viewBox="0 0 44 44" fill="none">
                      <circle cx="22" cy="22" r="21" stroke="#0B529C" stroke-width="2" fill="#f8fafc" />
                      <path d="M12 30V15L22 25L32 15V30" stroke="#0B529C" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
                      <path d="M12 21L22 30L32 21" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                  </div>

                  <!-- Document Title & Amharic Inspiration (Image 2) -->
                  <div class="sheet-titles-col">
                    <!-- Amharic Official Banner (From Image 2) -->
                    <div v-if="printSettings.showAmharicHeader" class="amharic-header-group">
                      <span class="amharic-table-pill">ሠንጠረዥ-2</span>
                      <h2 class="amharic-doc-title">የመንግሥትና የድርጅት ሠራተኞች የደመወዝ ስኬል የመሸጋገሪያ ሠንጠረዥ</h2>
                      <span class="amharic-date-sub">ጥቅምት 2017 ዓ.ም</span>
                    </div>

                    <!-- English Title -->
                    <div v-if="printSettings.showDocumentTitle" class="english-title-group">
                      <h1 class="sheet-main-title">Master Salary Scale Matrix</h1>
                      <span class="sheet-company-name">{{ scale.entity_name }}</span>
                    </div>
                  </div>
                </div>

                <!-- Right: Scale Identifier & Reference Code -->
                <div class="sheet-identity-right">
                  <span class="sheet-doc-code font-mono">SCALE-{{ scale.code || '00124' }}</span>
                  <div class="sheet-timeline-tag">
                    {{ formatDate(scale.effective_from) }} – {{ formatDate(scale.effective_to) }}
                  </div>
                  <span class="sheet-currency-tag font-mono">{{ scale.currency_code }} ({{ scale.currency_name }})</span>
                </div>
              </div>

              <!-- Metadata Summary Card (Matching GatePass style in Image 1) -->
              <div class="sheet-meta-card">
                <div class="meta-card-item">
                  <span class="meta-item-val">{{ scale.entity_name }}</span>
                  <span class="meta-item-lbl">Owning Entity</span>
                </div>
                <div class="meta-card-item">
                  <span class="meta-item-val">{{ scale.grades.length }} Grades × {{ scale.number_of_steps }} Steps</span>
                  <span class="meta-item-lbl">Grid Architecture</span>
                </div>
                <div class="meta-card-item">
                  <span class="meta-item-val">{{ new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) }}</span>
                  <span class="meta-item-lbl">Generated Date</span>
                </div>
              </div>

              <!-- ─── DETAILED 2D MATRIX VIEW (Image 2 Inspiration) ─── -->
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
                      <!-- Level in Roman Numeral (Image 2 style: I, II, III, IV, V) -->
                      <td class="td-lvl font-bold">{{ grade.roman_level || ('LV ' + grade.level) }}</td>
                      
                      <!-- Grade Name -->
                      <td class="td-name font-medium">
                        <span class="grade-title-text">{{ grade.name }}</span>
                        <span class="grade-code-pill font-mono">{{ grade.code }}</span>
                      </td>

                      <!-- Base Salary -->
                      <td class="td-amt font-mono">{{ formatCurrency(grade.base_salary) }}</td>

                      <!-- Progression Steps (1..N) -->
                      <td 
                        v-for="step in grade.steps" 
                        :key="'step-' + grade.id + '-' + step.step_number" 
                        class="td-amt font-mono"
                      >
                        {{ formatCurrency(step.amount) }}
                      </td>

                      <!-- Ceiling Salary -->
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

              <!-- ─── FOOTER SIGNATURES & OFFICIAL SEAL (Image 2 Inspiration) ─── -->
              <div v-if="printSettings.showSignatures || printSettings.showOfficialStamp" class="sheet-endorsement-footer">
                
                <!-- Official Stamp Seal (Image 2 Circular Stamp Effect) -->
                <div v-if="printSettings.showOfficialStamp" class="official-seal-wrapper">
                  <svg class="official-stamp-svg" viewBox="0 0 160 160">
                    <circle cx="80" cy="80" r="74" stroke="#1d4ed8" stroke-width="2.5" fill="none" opacity="0.85" />
                    <circle cx="80" cy="80" r="68" stroke="#1d4ed8" stroke-width="1.2" stroke-dasharray="3,2" fill="none" opacity="0.85" />
                    <!-- Curving Text Path Top -->
                    <path id="curveTop" d="M 22 80 A 58 58 0 0 1 138 80" fill="none" />
                    <text font-size="8.5" font-weight="700" fill="#1d4ed8" opacity="0.85" letter-spacing="1.2">
                      <textPath href="#curveTop" startOffset="50%" text-anchor="middle">
                        ★ የገንዘብ ሚኒስቴር / COMPENSATION SEAL ★
                      </textPath>
                    </text>
                    <!-- Star & Center Text -->
                    <polygon points="80,50 83,62 95,62 85,70 88,82 80,74 72,82 75,70 65,62 77,62" fill="#1d4ed8" opacity="0.85" />
                    <text x="80" y="96" font-size="10" font-weight="800" fill="#1d4ed8" text-anchor="middle" opacity="0.85">APPROVED</text>
                    <text x="80" y="107" font-size="7.5" font-weight="600" fill="#1d4ed8" text-anchor="middle" opacity="0.85">SALARY SCALE</text>
                    <!-- Curving Text Path Bottom -->
                    <path id="curveBottom" d="M 138 80 A 58 58 0 0 1 22 80" fill="none" />
                    <text font-size="8.5" font-weight="700" fill="#1d4ed8" opacity="0.85" letter-spacing="1.2">
                      <textPath href="#curveBottom" startOffset="50%" text-anchor="middle">
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

              <!-- Page 1/1 Badge (Matching Image 1) -->
              <div class="sheet-page-badge">
                Page 1/1
              </div>

            </div>

          </div>
        </div>

      </div>

      <!-- ═══ MODAL FOOTER (Matching Image 1) ═══ -->
      <div class="print-modal-footer">
        <button type="button" class="btn-footer-close" @click="closeModal">
          <X :size="15" />
          <span>Close</span>
        </button>

        <div class="footer-action-buttons">
          <button type="button" class="btn-footer-pdf" @click="downloadPDF">
            <Download :size="15" />
            <span>PDF</span>
          </button>
          <button type="button" class="btn-footer-print" @click="executePrint">
            <Printer :size="15" />
            <span>Print</span>
          </button>
        </div>
      </div>

    </div>
  </div>
</template>

<style scoped>
/* ═══════════════════════════════════════════ */
/* HIGH-FIDELITY PRINT MODAL / DRAWER STYLES    */
/* ═══════════════════════════════════════════ */

.print-modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 999;
  backdrop-filter: blur(4px);
  padding: 30px;
}

.print-modal-card {
  background: #ffffff;
  width: 95vw;
  max-width: 1240px;
  height: 88vh;
  border-radius: 16px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  border: 1px solid #e2e8f0;
  animation: modalScaleUp 0.24s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes modalScaleUp {
  from { opacity: 0; transform: scale(0.96) translateY(8px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}

/* ═══ MODAL HEADER ═══ */
.print-modal-header {
  padding: 18px 26px;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  border-bottom: 1px solid #f1f5f9;
  background: #ffffff;
}

.header-titles {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.modal-title {
  font-size: 18px;
  font-weight: 700;
  color: #1e293b;
  margin: 0;
}

.modal-subtitle {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

.btn-modal-close {
  background: transparent;
  border: none;
  cursor: pointer;
  color: #94a3b8;
  padding: 4px;
  border-radius: 6px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}
.btn-modal-close:hover {
  background: #f1f5f9;
  color: #1e293b;
}

/* ═══ MODAL BODY: LEFT CONTROLS + RIGHT PREVIEW ═══ */
.print-modal-body {
  display: flex;
  flex-direction: row;
  flex: 1;
  overflow: hidden;
  background: #ffffff;
}

/* ─── LEFT: SETTINGS SIDEBAR (Matching Image 1) ─── */
.print-settings-sidebar {
  width: 320px;
  flex-shrink: 0;
  padding: 24px;
  border-right: 1px solid #f1f5f9;
  background: #ffffff;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.setting-toggle-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 4px 0;
}

.setting-toggle-title {
  font-size: 13.5px;
  font-weight: 500;
  color: #334155;
}

/* iOS-Style Toggle Switch */
.switch {
  position: relative;
  display: inline-block;
  width: 44px;
  height: 24px;
  flex-shrink: 0;
}
.switch input { opacity: 0; width: 0; height: 0; }

.slider {
  position: absolute;
  cursor: pointer;
  top: 0; left: 0; right: 0; bottom: 0;
  background-color: #cbd5e1;
  transition: 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  border-radius: 24px;
}
.slider:before {
  position: absolute;
  content: "";
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  border-radius: 50%;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.15);
}
input:checked + .slider {
  background-color: #0B529C;
}
input:checked + .slider:before {
  transform: translateX(20px);
}

/* Layout Selector Section (Image 1 Radios) */
.layout-selector-section {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-top: 10px;
  padding-top: 18px;
  border-top: 1px solid #f1f5f9;
}

.selector-section-label {
  font-size: 13px;
  font-weight: 600;
  color: #334155;
  margin-bottom: 4px;
}

.layout-radio-option {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 10px 12px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  cursor: pointer;
  background: #ffffff;
  transition: all 0.15s ease;
  position: relative;
}
.layout-radio-option:hover {
  border-color: #cbd5e1;
  background: #fafbfd;
}
.layout-radio-option.radio-selected {
  border-color: #0B529C;
  background: #f0f7ff;
}

.layout-radio-option input {
  position: absolute;
  opacity: 0;
}

.radio-custom-circle {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  border: 1.5px solid #cbd5e1;
  margin-top: 2px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}
.radio-selected .radio-custom-circle {
  border-color: #0B529C;
  background-color: #ffffff;
}
.radio-selected .radio-custom-circle:after {
  content: "";
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: #0B529C;
}

.radio-content {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.radio-title {
  font-size: 13px;
  font-weight: 600;
  color: #1e293b;
}

.radio-desc {
  font-size: 11.5px;
  color: #64748b;
  line-height: 1.45;
}

/* ─── RIGHT: SCROLLABLE PREVIEW CANVAS (Matching Image 1) ─── */
.print-preview-container {
  flex: 1;
  overflow-y: auto;
  padding: 30px;
  display: flex;
  justify-content: center;
  align-items: flex-start;
  background: #f8fafc;
  box-sizing: border-box;
}

.preview-scroll-wrapper {
  width: 100%;
  max-width: 860px;
  display: flex;
  flex-direction: column;
  align-items: center;
}

/* White Printable Sheet */
.printable-paper-sheet {
  background: #ffffff;
  width: 100%;
  min-height: 297mm;
  padding: 16mm 20mm;
  box-sizing: border-box;
  position: relative;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.06);
}

/* Sheet Header Block */
.sheet-header-block {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  border-bottom: 2px solid #0f172a;
  padding-bottom: 14px;
  margin-bottom: 18px;
}

.sheet-identity-left {
  display: flex;
  align-items: flex-start;
  gap: 14px;
}

.sheet-logo-circle {
  width: 48px;
  height: 48px;
  flex-shrink: 0;
}

.sheet-logo-svg {
  width: 48px;
  height: 48px;
}

.sheet-titles-col {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

/* Amharic Header (Inspired by Image 2) */
.amharic-header-group {
  display: flex;
  flex-direction: column;
  gap: 2px;
  margin-bottom: 4px;
}

.amharic-table-pill {
  font-size: 13px;
  font-weight: 700;
  color: #0f172a;
  letter-spacing: 0.5px;
}

.amharic-doc-title {
  font-size: 15px;
  font-weight: 800;
  color: #0f172a;
  margin: 0;
  line-height: 1.3;
}

.amharic-date-sub {
  font-size: 12px;
  font-weight: 600;
  color: #475569;
}

.english-title-group {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.sheet-main-title {
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
  margin: 0;
  letter-spacing: -0.01em;
}

.sheet-company-name {
  font-size: 12.5px;
  color: #475569;
  font-weight: 500;
}

.sheet-identity-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 3px;
  text-align: right;
}

.sheet-doc-code {
  font-size: 12px;
  font-weight: 700;
  color: #0f172a;
  letter-spacing: 0.5px;
}

.sheet-timeline-tag {
  font-size: 11.5px;
  color: #475569;
  font-weight: 500;
}

.sheet-currency-tag {
  font-size: 11px;
  font-weight: 600;
  color: #0B529C;
}

/* Subheader Meta Card (Matching Image 1) */
.sheet-meta-card {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 16px;
  margin-bottom: 20px;
}

.meta-card-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.meta-item-val {
  font-size: 13.5px;
  font-weight: 600;
  color: #0f172a;
}

.meta-item-lbl {
  font-size: 11px;
  color: #64748b;
}

/* ─── OFFICIAL 2D SALARY MATRIX TABLE (Matching Image 2) ─── */
.sheet-matrix-table-container {
  margin-bottom: 28px;
  overflow: hidden;
}

.official-salary-grid-table {
  width: 100%;
  border-collapse: collapse;
  border: 1.5px solid #0f172a;
}

.official-salary-grid-table th {
  padding: 8px 10px;
  background-color: #f1f5f9;
  color: #0f172a;
  font-size: 12px;
  font-weight: 700;
  text-align: center;
  border: 1px solid #0f172a;
  line-height: 1.25;
}

.sub-th {
  font-size: 10px;
  font-weight: 500;
  color: #475569;
}

.official-salary-grid-table td {
  padding: 8px 10px;
  font-size: 12px;
  color: #0f172a;
  border: 1px solid #0f172a;
  text-align: center;
  vertical-align: middle;
}

.td-lvl {
  font-size: 13px;
  background-color: #fafafa;
}

.td-name {
  text-align: left !important;
  padding-left: 12px !important;
}

.grade-title-text {
  font-size: 12.5px;
  color: #0f172a;
}

.grade-code-pill {
  margin-left: 6px;
  font-size: 10px;
  padding: 1px 5px;
  background-color: #e2e8f0;
  color: #334155;
  border-radius: 3px;
}

.td-amt {
  font-weight: 600;
}

/* ─── SUMMARY MODE CONTAINER ─── */
.sheet-summary-mode-container {
  margin-bottom: 28px;
}

.summary-highlight-cards {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
  margin-bottom: 18px;
}

.summary-stat-box {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stat-lbl {
  font-size: 11px;
  color: #64748b;
  font-weight: 500;
}

.stat-num {
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
}

.summary-grades-compact-table {
  width: 100%;
  border-collapse: collapse;
  border: 1px solid #cbd5e1;
}

.summary-grades-compact-table th {
  padding: 8px 12px;
  background-color: #f1f5f9;
  font-size: 12px;
  font-weight: 600;
  color: #0f172a;
  border: 1px solid #cbd5e1;
  text-align: left;
}

.summary-grades-compact-table td {
  padding: 8px 12px;
  font-size: 12.5px;
  color: #334155;
  border: 1px solid #cbd5e1;
}

/* ─── FOOTER ENDORSEMENTS (Image 2 Authenticity) ─── */
.sheet-endorsement-footer {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  padding-top: 14px;
  margin-top: 20px;
}

.official-seal-wrapper {
  transform: rotate(-4deg);
  opacity: 0.88;
  filter: drop-shadow(0 2px 4px rgba(29, 78, 216, 0.15));
}

.official-stamp-svg {
  width: 130px;
  height: 130px;
}

.sheet-signatures-group {
  display: flex;
  gap: 28px;
}

.sig-column {
  display: flex;
  flex-direction: column;
  width: 150px;
}

.sig-line {
  height: 1px;
  background-color: #0f172a;
  margin-bottom: 6px;
}

.sig-role {
  font-size: 11px;
  font-weight: 700;
  color: #0f172a;
}

.sig-note {
  font-size: 10px;
  color: #64748b;
}

/* Page 1/1 Badge (Matching Image 1) */
.sheet-page-badge {
  position: absolute;
  bottom: 14px;
  right: 18px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 9999px;
  padding: 3px 12px;
  font-size: 11px;
  font-weight: 600;
  color: #475569;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.06);
}

/* ═══ MODAL FOOTER (Matching Image 1) ═══ */
.print-modal-footer {
  padding: 14px 26px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-top: 1px solid #f1f5f9;
  background: #ffffff;
}

.btn-footer-close {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 18px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-footer-close:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.footer-action-buttons {
  display: flex;
  align-items: center;
  gap: 10px;
}

.btn-footer-pdf {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 18px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-footer-pdf:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
  color: #0B529C;
}

.btn-footer-print {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 22px;
  background: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(11, 82, 156, 0.2);
  transition: background-color 0.15s ease;
}
.btn-footer-print:hover {
  background-color: #09427d;
}

/* Helpers */
.font-mono { font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', monospace; }
.font-medium { font-weight: 500; }
.font-bold { font-weight: 700; }

/* ═══ PRINT MEDIA QUERY ═══ */
@media print {
  /* Hide all elements except the sheet preview */
  body * {
    visibility: hidden;
  }
  .printable-document-area,
  .printable-document-area * {
    visibility: visible;
  }
  .printable-document-area {
    position: absolute;
    left: 0;
    top: 0;
    width: 100% !important;
    padding: 0 !important;
    margin: 0 !important;
    border: none !important;
    box-shadow: none !important;
  }
  .sheet-page-badge {
    display: none !important;
  }
}
</style>
