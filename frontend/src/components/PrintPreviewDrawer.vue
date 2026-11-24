<script setup lang="ts">
import { ref, watch } from 'vue';
import { X, Download, Printer } from 'lucide-vue-next';
import FormToggle from './FormToggle.vue';
import AppButton from './AppButton.vue';
import defaultLogoUrl from '../assets/Logo.png';

interface CustomToggle {
  id: string;
  label: string;
  value: boolean;
}

interface Props {
  show: boolean;
  title?: string;
  subtitle?: string;
  documentTitle?: string;
  documentSubtitle?: string;
  documentCode?: string;
  documentDate?: string;
  documentMeta?: string;
  logoUrl?: string;
  currentPage?: number;
  totalPages?: number;
  showLogoToggle?: boolean;
  showTitleToggle?: boolean;
  initialLogo?: boolean;
  initialTitle?: boolean;
  customToggles?: CustomToggle[];
  pdfLoading?: boolean;
  printLoading?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  title: 'Print Settings',
  subtitle: 'Configure Document layout and Visibility',
  documentTitle: 'Document Title',
  documentSubtitle: 'QMT Business Group',
  documentCode: '',
  documentDate: '',
  documentMeta: 'ETB — Ethiopian Birr',
  logoUrl: defaultLogoUrl,
  currentPage: 1,
  totalPages: 1,
  showLogoToggle: true,
  showTitleToggle: true,
  initialLogo: true,
  initialTitle: true,
  customToggles: () => [],
  pdfLoading: false,
  printLoading: false
});

const emit = defineEmits<{
  'update:show': [value: boolean];
  'close': [];
  'print': [settings: { showCompanyLogo: boolean; showDocumentTitle: boolean; customValues: Record<string, boolean> }];
  'pdf': [settings: { showCompanyLogo: boolean; showDocumentTitle: boolean; customValues: Record<string, boolean> }];
  'toggle-change': [key: string, value: boolean];
}>();

// ─── Toggles State ───
const showCompanyLogo = ref(props.initialLogo);
const showDocumentTitle = ref(props.initialTitle);
const localCustomValues = ref<Record<string, boolean>>({});

// Initialize custom toggles
watch(
  () => props.customToggles,
  (toggles) => {
    toggles.forEach(t => {
      if (localCustomValues.value[t.id] === undefined) {
        localCustomValues.value[t.id] = t.value;
      }
    });
  },
  { immediate: true, deep: true }
);

watch(() => props.initialLogo, (val) => { showCompanyLogo.value = val; });
watch(() => props.initialTitle, (val) => { showDocumentTitle.value = val; });

const handleToggleCustom = (id: string, val: boolean) => {
  localCustomValues.value[id] = val;
  emit('toggle-change', id, val);
};

const handleClose = () => {
  emit('update:show', false);
  emit('close');
};

const getSettingsPayload = () => ({
  showCompanyLogo: showCompanyLogo.value,
  showDocumentTitle: showDocumentTitle.value,
  customValues: { ...localCustomValues.value }
});

const handlePrint = () => {
  emit('print', getSettingsPayload());
  window.print();
};

const handlePDF = () => {
  emit('pdf', getSettingsPayload());
  window.print();
};
</script>

<template>
  <Teleport to="body">
    <div v-if="show" class="print-drawer-backdrop" @click="handleClose">
      <!-- ═══ BOTTOM DRAWER SHEET (Figma Node 5005:78527) ═══ -->
      <div class="print-drawer-container" @click.stop>
        
        <!-- Top Drawer Header (Figma Node 5005:78528) -->
        <div class="drawer-header">
          <div class="header-titles">
            <h2 class="drawer-title">{{ title }}</h2>
            <p class="drawer-subtitle">{{ subtitle }}</p>
          </div>
          <button 
            type="button" 
            class="btn-close-circle" 
            @click="handleClose" 
            aria-label="Close Print Preview"
          >
            <X :size="16" />
          </button>
        </div>

        <!-- Drawer Body: Left Customization Sidebar + Right Live Preview (Figma Node 5005:78538) -->
        <div class="drawer-body">
          
          <!-- ─── LEFT: SETTINGS SIDEBAR (Figma Node 5005:78539) ─── -->
          <div class="settings-sidebar">
            <div class="settings-list">
              <!-- Always-Visible Standard Toggle 1: Company Logo -->
              <div v-if="showLogoToggle" class="setting-row">
                <span class="setting-label">Company Logo</span>
                <FormToggle 
                  v-model="showCompanyLogo" 
                  size="sm" 
                  aria-label="Company Logo"
                  @change="(val) => emit('toggle-change', 'companyLogo', val)" 
                />
              </div>

              <!-- Always-Visible Standard Toggle 2: Document Title -->
              <div v-if="showTitleToggle" class="setting-row">
                <span class="setting-label">Document Title</span>
                <FormToggle 
                  v-model="showDocumentTitle" 
                  size="sm" 
                  aria-label="Document Title"
                  @change="(val) => emit('toggle-change', 'documentTitle', val)" 
                />
              </div>

              <!-- Configurable Custom Toggles from Props -->
              <div 
                v-for="custom in customToggles" 
                :key="custom.id" 
                class="setting-row"
              >
                <span class="setting-label">{{ custom.label }}</span>
                <FormToggle 
                  :modelValue="localCustomValues[custom.id] ?? custom.value" 
                  size="sm" 
                  :aria-label="custom.label"
                  @update:modelValue="(val) => handleToggleCustom(custom.id, val)" 
                />
              </div>

              <!-- Slot for Advanced Content-Specific Custom Controls -->
              <slot 
                name="settings" 
                :settings="{ 
                  showCompanyLogo, 
                  showDocumentTitle, 
                  customValues: localCustomValues 
                }" 
              />
            </div>
          </div>

          <!-- ─── RIGHT: LIVE SCROLLABLE PREVIEW CANVAS (Figma Node 5005:78549) ─── -->
          <div class="preview-canvas-wrapper">
            <!-- White Document Sheet Canvas (Figma Node 5005:78550) -->
            <div class="printable-paper-sheet printable-document-area">
              
              <!-- Sheet Header (Figma Node 5005:78552) -->
              <div class="sheet-header">
                <!-- Left: Logo + Document Title Group -->
                <div class="sheet-header-left">
                  <!-- Company Logo (Toggled) -->
                  <div v-if="showCompanyLogo" class="sheet-logo-container">
                    <slot name="header-logo">
                      <div class="qmt-brand-emblem">
                        <img :src="props.logoUrl" alt="Company Logo" class="sheet-company-logo" />
                      </div>
                    </slot>
                  </div>

                  <!-- Document Title (Toggled) -->
                  <div v-if="showDocumentTitle" class="sheet-title-block">
                    <h1 class="sheet-main-title">{{ documentTitle }}</h1>
                    <p class="sheet-subtitle">{{ documentSubtitle }}</p>
                  </div>
                </div>

                <!-- Right: Document Metadata & Dates -->
                <div class="sheet-header-right">
                  <slot name="document-header-right">
                    <span v-if="documentCode" class="sheet-code-tag">{{ documentCode }}</span>
                    <p v-if="documentDate" class="sheet-date-text">{{ documentDate }}</p>
                    <p v-if="documentMeta" class="sheet-meta-text">{{ documentMeta }}</p>
                  </slot>
                </div>
              </div>

              <!-- Sheet Body Content Slot -->
              <div class="sheet-content-slot">
                <slot 
                  name="document" 
                  :settings="{ 
                    showCompanyLogo, 
                    showDocumentTitle, 
                    customValues: localCustomValues 
                  }"
                >
                  <slot 
                    :settings="{ 
                      showCompanyLogo, 
                      showDocumentTitle, 
                      customValues: localCustomValues 
                    }" 
                  />
                </slot>
              </div>

            </div>

            <!-- Page Indicator Pill (Figma Node 5005:78623) -->
            <div class="page-indicator-pill">
              Page {{ currentPage }}/{{ totalPages }}
            </div>
          </div>

        </div>

        <!-- Drawer Footer (Figma Node 5005:78626) -->
        <div class="drawer-footer">
          <AppButton 
            variant="secondary-gray" 
            size="md" 
            @click="handleClose"
          >
            <template #icon-left><X :size="16" /></template>
            <span>Close</span>
          </AppButton>

          <div class="footer-actions-right">
            <AppButton 
              variant="secondary-gray" 
              size="md" 
              :loading="pdfLoading"
              @click="handlePDF"
            >
              <template #icon-left><Download :size="16" /></template>
              <span>PDF</span>
            </AppButton>

            <AppButton 
              variant="primary" 
              size="md" 
              :loading="printLoading"
              @click="handlePrint"
            >
              <template #icon-left><Printer :size="16" /></template>
              <span>Print</span>
            </AppButton>
          </div>
        </div>

      </div>
    </div>
  </Teleport>
</template>

<style scoped>
/* ═══════════════════════════════════════════════════════════════════ */
/* BOTTOM DRAWER STYLING (Strict QMT & Figma Node 5005:78527)        */
/* ═══════════════════════════════════════════════════════════════════ */

.print-drawer-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(2px);
  z-index: 9999;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  animation: fadeIn 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.print-drawer-container {
  background: #ffffff;
  width: 100%;
  height: 92vh;
  max-height: 94vh;
  border-top-left-radius: 16px;
  border-top-right-radius: 16px;
  border-top: 1px solid #d4d4d4;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  box-shadow: 0 -10px 40px rgba(0, 0, 0, 0.15);
  animation: slideUp 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes slideUp {
  from { transform: translateY(100%); }
  to { transform: translateY(0); }
}

/* ─── Drawer Header (Figma Node 5005:78528) ─── */
.drawer-header {
  padding: 24px;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  background: #ffffff;
  flex-shrink: 0;
}

.header-titles {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.drawer-title {
  font-family: 'Inter', -apple-system, sans-serif;
  font-size: 20px;
  font-weight: 600;
  line-height: 30px;
  color: #404040; /* Secondary */
  margin: 0;
}

.drawer-subtitle {
  font-family: 'Inter', -apple-system, sans-serif;
  font-size: 12px;
  font-weight: 400;
  line-height: 18px;
  color: #737373; /* Tertiary */
  margin: 0;
}

.btn-close-circle {
  width: 32px;
  height: 32px;
  border-radius: 9999px;
  background: #ffffff;
  border: 1px solid #e5e5e5;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: #737373;
  transition: all 0.15s ease;
}

.btn-close-circle:hover {
  background: #f5f5f5;
  color: #404040;
}

/* ─── Drawer Body (Figma Node 5005:78538) ─── */
.drawer-body {
  flex: 1;
  display: flex;
  gap: 24px;
  padding: 0 24px;
  overflow: hidden;
  min-height: 0;
}

/* ─── Left Settings Sidebar (Figma Node 5005:78539) ─── */
.settings-sidebar {
  width: 272px;
  flex-shrink: 0;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
}

.settings-list {
  display: flex;
  flex-direction: column;
}

.setting-row {
  padding: 20px 12px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 0.5px solid #f5f5f5;
}

.setting-label {
  font-family: 'Inter', -apple-system, sans-serif;
  font-size: 14px;
  font-weight: 500;
  line-height: 20px;
  color: #404040; /* Secondary */
}

/* ─── Right Live Preview Canvas (Figma Node 5005:78549) ─── */
.preview-canvas-wrapper {
  flex: 1;
  background: #fafafa; /* Canvas */
  border-top: 1px solid #e5e5e5;
  border-left: 1px solid #e5e5e5;
  border-right: 1px solid #e5e5e5;
  border-top-left-radius: 16px;
  border-top-right-radius: 16px;
  padding: 32px 24px 80px 24px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
}

/* ─── White Printable Document Sheet (Figma Node 5005:78550) ─── */
.printable-paper-sheet {
  background: #ffffff;
  border: 1px solid #e5e5e5;
  width: 100%;
  max-width: 846px;
  min-height: 920px;
  padding: 32px;
  box-shadow: 0 1px 3px rgba(10, 13, 18, 0.05);
  display: flex;
  flex-direction: column;
  gap: 20px;
  position: relative;
  box-sizing: border-box;
}

/* Sheet Top Identity Bar (Figma Node 5005:78552) */
.sheet-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 78px;
  padding-bottom: 16px;
  border-bottom: 1px solid #e5e5e5;
}

.sheet-header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.sheet-logo-container {
  display: flex;
  align-items: center;
  justify-content: center;
}

.qmt-brand-emblem {
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.sheet-company-logo {
  width: 48px;
  height: 48px;
  object-fit: contain;
  display: block;
}

.sheet-title-block {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.sheet-main-title {
  font-family: 'Inter', -apple-system, sans-serif;
  font-size: 20px;
  font-weight: 600;
  line-height: 30px;
  color: #404040; /* Secondary */
  margin: 0;
}

.sheet-subtitle {
  font-family: 'Inter', -apple-system, sans-serif;
  font-size: 14px;
  font-weight: 400;
  line-height: 20px;
  color: #737373; /* Tertiary */
  margin: 0;
}

.sheet-header-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
  text-align: right;
}

.sheet-code-tag {
  font-family: monospace;
  font-size: 12px;
  font-weight: 600;
  color: #0b529c;
  background: #f0f7ff;
  padding: 2px 8px;
  border-radius: 4px;
}

.sheet-date-text,
.sheet-meta-text {
  font-family: 'Inter', -apple-system, sans-serif;
  font-size: 14px;
  font-weight: 400;
  line-height: 20px;
  color: #737373; /* Tertiary */
  margin: 0;
}

.sheet-content-slot {
  display: flex;
  flex-direction: column;
  gap: 20px;
  flex: 1;
}

/* Page Indicator Floating Pill (Figma Node 5005:78623) */
.page-indicator-pill {
  position: absolute;
  bottom: 24px;
  right: 36px;
  z-index: 10;
  background: #ffffff;
  border: 1px solid #d9d9d9;
  border-radius: 9999px;
  padding: 8px 18px;
  box-shadow: 0px 1px 2px 0px rgba(10, 13, 18, 0.05);
  font-family: 'Inter', -apple-system, sans-serif;
  font-size: 14px;
  font-weight: 600;
  color: #414651;
  pointer-events: none;
}

/* ─── Drawer Footer (Figma Node 5005:78626) ─── */
.drawer-footer {
  background: #fafafa; /* Canvas */
  border-top: 1px solid #e5e5e5;
  padding: 20px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-shrink: 0;
}

.footer-actions-right {
  display: flex;
  gap: 20px;
  align-items: center;
}

/* ═══════════════════════════════════════════════════════════════════ */
/* PRINT MEDIA QUERY: Isolates printable-document-area                */
/* ═══════════════════════════════════════════════════════════════════ */
@media print {
  body * {
    visibility: hidden;
  }
  .print-drawer-backdrop {
    position: static !important;
    background: transparent !important;
    backdrop-filter: none !important;
    padding: 0 !important;
  }
  .drawer-header,
  .settings-sidebar,
  .page-indicator-pill,
  .drawer-footer,
  .btn-close-circle {
    display: none !important;
  }
  .preview-canvas-wrapper {
    background: transparent !important;
    border: none !important;
    padding: 0 !important;
    overflow: visible !important;
  }
  .printable-document-area,
  .printable-document-area * {
    visibility: visible !important;
  }
  .printable-document-area {
    position: absolute !important;
    left: 0 !important;
    top: 0 !important;
    width: 100% !important;
    max-width: 100% !important;
    border: none !important;
    box-shadow: none !important;
    padding: 0 !important;
    margin: 0 !important;
  }
}
</style>
