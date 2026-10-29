<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  FileText, Plus, Eye, CheckCircle2, Clock,
  Filter, MoreVertical, Maximize2,
  Printer, Download, Building2, User, Check, X,
  Copy, Edit3, Trash2, ShieldCheck, Tag, ArrowUpRight,
  Sparkles, FileCheck, AlertCircle, RefreshCw,
  ChevronDown, ChevronRight, ArrowUpDown, Columns
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormInput from '../../components/FormInput.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import {
  letterTemplatesData,
  LETTER_TYPE_MAP,
  AVAILABLE_MERGE_TOKENS,
  renderTemplatePreview,
  addLetterTemplate,
  updateLetterTemplate,
  deleteLetterTemplate,
  duplicateLetterTemplate,
  type LetterType,
  type LetterTemplateRecord,
  type MergeToken
} from './letterData';

const router = useRouter();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3) ───
// Exact Sidebar Page Name Only: [Monitor] > Letter Templates
const breadcrumbItems = [
  { label: 'Letter Templates' }
];

const searchQuery = ref('');
const selectedTypeFilter = ref<string>('all');
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Filtered Dataset ───
const filteredTemplates = computed(() => {
  return letterTemplatesData.value.filter(t => {
    // Type filter
    if (selectedTypeFilter.value !== 'all' && t.letter_type !== selectedTypeFilter.value) return false;

    // Search query
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase();
      const matchName = t.name.toLowerCase().includes(q);
      const matchCode = t.code.toLowerCase().includes(q);
      const matchDesc = t.description.toLowerCase().includes(q);
      if (!matchName && !matchCode && !matchDesc) return false;
    }

    return true;
  });
});

// ─── Table Columns (Matching Figma 7454:138158 exactly) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'select', label: '', width: '40px', sortable: false, visible: true },
  { key: 'name', label: 'Name', sortable: true, visible: true },
  { key: 'template_type', label: 'Template Type', sortable: true, visible: true },
  { key: 'approval_required', label: 'Approval Required', sortable: true, visible: true },
  { key: 'owning_entity', label: 'Owning Entity', sortable: true, visible: true },
  { key: 'status', label: 'Status', sortable: true, visible: true },
  { key: 'actions', label: 'Actions', width: '60px', sortable: false, visible: true }
]);

const handleToggleColumn = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  if (col) col.visible = !col.visible;
};

// ─── Bottom Drawer State (Figma 7454:138406 & 7454:138747) ───
const isCreateDrawerOpen = ref(false);
const drawerActiveMode = ref<'split' | 'editor' | 'preview'>('split');
const isDescriptionAccordionOpen = ref(false);

const typeOptions: { value: LetterType; label: string }[] = [
  { value: 'promotion', label: 'Promotion' },
  { value: 'experience', label: 'Experience Letter' },
  { value: 'salary_certificate', label: 'Salary Certificate' },
  { value: 'employment_confirmation', label: 'Employment Confirmation' },
  { value: 'bank_reference', label: 'Bank Reference' },
  { value: 'warning', label: 'Warning Letter' },
  { value: 'offer', label: 'Job Offer' },
  { value: 'transfer', label: 'Transfer Directive' },
  { value: 'termination', label: 'Termination Notice' }
];

// Fetch Information's Tokens State
type TokenCategory = 'Employee' | 'Position & Org' | 'Compensation' | 'Dates' | 'Recipient';
const activeTokenCategory = ref<TokenCategory>('Position & Org');

const tokenCategories: TokenCategory[] = [
  'Employee',
  'Position & Org',
  'Compensation',
  'Dates',
  'Recipient'
];

// Currently selected fetch information tokens
const selectedFetchTokens = ref<string[]>([
  '{{employee_name}}',
  '{{position}}',
  '{{department}}'
]);

const tokensByCategory = computed(() => {
  return AVAILABLE_MERGE_TOKENS.filter(t => t.category === activeTokenCategory.value);
});

const isTokenSelected = (token: string) => {
  return selectedFetchTokens.value.includes(token);
};

const toggleFetchToken = (token: string) => {
  const idx = selectedFetchTokens.value.indexOf(token);
  if (idx >= 0) {
    selectedFetchTokens.value.splice(idx, 1);
  } else {
    selectedFetchTokens.value.push(token);
  }
};

// Form state for creating template
const templateForm = ref({
  name: 'For Promotion',
  code: 'LT-PRO',
  letter_type: 'promotion' as LetterType,
  requires_approval: true,
  body: 'In recognition of your outstanding performance, leadership, and dedicated service, Executive Management is pleased to confirm your promotion.',
  description: 'Corporate promotion letter template for grade advancement and salary revision.'
});

const handleOpenCreateDrawer = () => {
  templateForm.value = {
    name: 'For Promotion',
    code: 'LT-PRO',
    letter_type: 'promotion',
    requires_approval: true,
    body: 'In recognition of your outstanding performance, leadership, and dedicated service, Executive Management is pleased to confirm your promotion.',
    description: 'Corporate promotion letter template for grade advancement and salary revision.'
  };
  selectedFetchTokens.value = ['{{employee_name}}', '{{position}}', '{{department}}'];
  isCreateDrawerOpen.value = true;
};

// Computed fact sheet columns for preview
const previewFactColumns = computed(() => {
  const map: Record<string, { label: string; sample: string }> = {
    '{{employee_name}}': { label: 'Full Name', sample: 'Employee name' },
    '{{position}}': { label: 'Job Position', sample: 'Employee Position' },
    '{{department}}': { label: 'Department Unit', sample: 'Employee Dept.' },
    '{{job_grade}}': { label: 'Job Grade', sample: 'Grade IX' },
    '{{basic_salary}}': { label: 'Revised Salary', sample: 'ETB 32,000' },
    '{{monthly_allowance}}': { label: 'Allowances', sample: 'ETB 4,500' },
    '{{effective_date}}': { label: 'Effective Date', sample: 'Jul 25, 2027' },
    '{{hire_date}}': { label: 'Hire Date', sample: 'Jan 15, 2023' },
    '{{last_working_date}}': { label: 'Last Working Date', sample: 'Jul 20, 2027' },
    '{{addressed_organization}}': { label: 'Addressed Org', sample: 'Zemen Bank' }
  };

  return selectedFetchTokens.value.map(token => ({
    token,
    label: map[token]?.label || token.replace(/[{}]/g, '').replace(/_/g, ' '),
    sample: map[token]?.sample || '-'
  }));
});

const handleSaveTemplate = () => {
  if (!templateForm.value.name || !templateForm.value.code) {
    showToast('Please fill in required fields.');
    return;
  }

  addLetterTemplate({
    code: templateForm.value.code,
    name: templateForm.value.name,
    description: templateForm.value.description,
    letter_type: templateForm.value.letter_type,
    entity_id: null,
    entity_name: 'Bole Branch',
    document_type_id: 101,
    body: templateForm.value.body,
    requires_approval: templateForm.value.requires_approval,
    is_system: false,
    status: 'acceptForAll',
    user_id: 1,
    state: 'active'
  });

  isCreateDrawerOpen.value = false;
  showToast(`Template "${templateForm.value.name}" created successfully.`);
};

// Preview inspection modal
const inspectingTemplate = ref<LetterTemplateRecord | null>(null);
const isInspectionModalOpen = ref(false);

const handleInspectTemplate = (tmpl: LetterTemplateRecord) => {
  inspectingTemplate.value = tmpl;
  isInspectionModalOpen.value = true;
};
</script>

<template>
  <div class="letter-templates-page">
    <!-- Breadcrumb Standard (AGENTS.md Rule 3) -->
    <AppBreadcrumb :items="breadcrumbItems" />

    <!-- Toast Notification -->
    <transition name="fade">
      <div v-if="toastMessage" class="toast-notification">
        <CheckCircle2 :size="16" class="toast-icon" />
        <span>{{ toastMessage }}</span>
      </div>
    </transition>

    <!-- Unified Data Table Container (Matching Figma 7454:138158) -->
    <AppDataTable
      title="Letter Templates"
      subtitle="Configure corporate letter designs, dynamic merge tokens, and governance sign-off workflows."
      :columns="tableColumns"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Actions Slot -->
      <template #actions>
        <button class="btn-primary-blue" @click="handleOpenCreateDrawer">
          <Plus :size="16" />
          <span>+ Create Template</span>
        </button>
      </template>

      <!-- Subheader Filters & Search (Figma 7454:138158) -->
      <template #subheader>
        <div class="table-controls-wrapper">
          <div class="table-filter-bar">
            <div class="search-box">
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Search by Name..."
                class="search-input"
              />
            </div>

            <div class="table-toolbar-actions">
              <button class="btn-secondary-toolbar" title="Filter templates">
                <Filter :size="14" />
                <span>Filter</span>
              </button>

              <button class="btn-secondary-toolbar" title="Sort templates">
                <ArrowUpDown :size="14" />
                <span>Sort</span>
                <ChevronDown :size="12" />
              </button>

              <button class="btn-icon-toolbar" title="Toggle columns">
                <Columns :size="16" />
              </button>

              <button class="btn-icon-toolbar" title="Maximize view">
                <Maximize2 :size="16" />
              </button>
            </div>
          </div>
        </div>
      </template>

      <!-- Table Body -->
      <template #default>
        <div class="table-responsive">
          <table class="erp-table">
            <thead>
              <tr>
                <th v-if="tableColumns[0].visible" class="th-check">
                  <input type="checkbox" class="table-checkbox" />
                </th>
                <th v-if="tableColumns[1].visible" class="th-name">Name</th>
                <th v-if="tableColumns[2].visible">Template Type</th>
                <th v-if="tableColumns[3].visible">Approval Required</th>
                <th v-if="tableColumns[4].visible">Owning Entity</th>
                <th v-if="tableColumns[5].visible">Status</th>
                <th v-if="tableColumns[6].visible" class="th-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="tmpl in filteredTemplates"
                :key="tmpl.id"
                class="table-row-hover"
                @click="handleInspectTemplate(tmpl)"
              >
                <!-- Checkbox -->
                <td v-if="tableColumns[0].visible" class="td-check" @click.stop>
                  <input type="checkbox" class="table-checkbox" />
                </td>

                <!-- Name Column (Title on top, code on bottom) -->
                <td v-if="tableColumns[1].visible" class="td-name">
                  <div class="template-name-cell">
                    <span class="table-name-primary">{{ tmpl.name }}</span>
                    <span class="table-code-subtext">{{ tmpl.code }}</span>
                  </div>
                </td>

                <!-- Template Type (Plain text) -->
                <td v-if="tableColumns[2].visible" class="td-tertiary">
                  <span class="cell-plain-text">{{ LETTER_TYPE_MAP[tmpl.letter_type]?.label || tmpl.letter_type }}</span>
                </td>

                <!-- Approval Required (Plain text: Yes / No) -->
                <td v-if="tableColumns[3].visible" class="td-tertiary">
                  <span class="cell-plain-text">{{ tmpl.requires_approval ? 'Yes' : 'No' }}</span>
                </td>

                <!-- Owning Entity -->
                <td v-if="tableColumns[4].visible" class="td-tertiary">
                  <span class="cell-plain-text">{{ tmpl.entity_name || 'Bole Branch' }}</span>
                </td>

                <!-- Status (Active / Inactive State Pill) -->
                <td v-if="tableColumns[5].visible" class="td-state">
                  <span class="state-pill" :class="tmpl.state === 'active' ? 'state-active' : 'state-inactive'">
                    {{ tmpl.state === 'active' ? 'Active' : 'Inactive' }}
                  </span>
                </td>

                <!-- Row Actions -->
                <td v-if="tableColumns[6].visible" class="td-actions" @click.stop>
                  <button class="btn-action-dots" title="More options" @click="handleInspectTemplate(tmpl)">
                    <MoreVertical :size="16" />
                  </button>
                </td>
              </tr>

              <!-- Empty State -->
              <tr v-if="filteredTemplates.length === 0">
                <td colspan="7" class="empty-state-cell">
                  <div class="empty-container">
                    <FileText :size="36" class="empty-icon" />
                    <p class="empty-title">No templates found</p>
                    <p class="empty-desc">No letter templates match the current filter or search criteria.</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>

          <!-- Minimalist Pagination Bar matching Figma 7454:138158 -->
          <div class="figma-pagination-bar">
            <div class="pagination-left">
              <span>Showing 1 to {{ filteredTemplates.length }} of {{ filteredTemplates.length }} entries</span>
              <div class="per-page-wrapper">
                <span>Per Page:</span>
                <select class="per-page-select">
                  <option value="10">10</option>
                  <option value="25">25</option>
                  <option value="50">50</option>
                </select>
              </div>
            </div>

            <div class="pagination-right">
              <button class="btn-pag-nav" disabled>
                <span>&larr; Previous</span>
              </button>
              <button class="btn-pag-num active">1</button>
              <button class="btn-pag-num">2</button>
              <span class="pag-ellipsis">...</span>
              <button class="btn-pag-num">9</button>
              <button class="btn-pag-num">10</button>
              <button class="btn-pag-nav">
                <span>Next &rarr;</span>
              </button>
            </div>
          </div>
        </div>
      </template>
    </AppDataTable>

    <!-- ═══════════════════════════════════════════════════════════════════════ -->
    <!-- BOTTOM DRAWER: CREATE LETTER TEMPLATE (Figma 7454:138406 & 7454:138747) -->
    <!-- ═══════════════════════════════════════════════════════════════════════ -->
    <div v-if="isCreateDrawerOpen" class="drawer-backdrop" @click="isCreateDrawerOpen = false">
      <div class="bottom-drawer-container" @click.stop>
        <!-- Top Drag Pill -->
        <div class="drawer-drag-pill"></div>

        <!-- Drawer Header -->
        <div class="drawer-header">
          <div class="drawer-header-left">
            <h2 class="drawer-title">Create Letter Template</h2>
            <p class="drawer-subtext">Configure Letter layout and Visibility</p>
          </div>

          <div class="drawer-header-right">
            <!-- Segmented View Mode Switcher (Figma 7454:138406) -->
            <div class="drawer-segmented-pills">
              <button
                class="seg-pill-btn"
                :class="{ active: drawerActiveMode === 'split' }"
                @click="drawerActiveMode = 'split'"
              >
                Split View
              </button>
              <button
                class="seg-pill-btn"
                :class="{ active: drawerActiveMode === 'editor' }"
                @click="drawerActiveMode = 'editor'"
              >
                Editor
              </button>
              <button
                class="seg-pill-btn"
                :class="{ active: drawerActiveMode === 'preview' }"
                @click="drawerActiveMode = 'preview'"
              >
                Preview
              </button>
            </div>

            <!-- Close icon button -->
            <button class="btn-close-header" @click="isCreateDrawerOpen = false">
              <X :size="18" />
            </button>
          </div>
        </div>

        <!-- Drawer Body: Side-by-Side Flex Layout -->
        <div class="drawer-split-body" :class="'mode-' + drawerActiveMode">
          <!-- LEFT PANE: CREATE FORM (Figma 7454:138747) -->
          <div v-show="drawerActiveMode === 'split' || drawerActiveMode === 'editor'" class="drawer-form-pane">
            <div class="pane-scroll-inner">
              <!-- Main Form Card -->
              <div class="figma-form-card">
                <!-- Template Name & Template Code -->
                <div class="form-grid-2">
                  <FormInput
                    v-model="templateForm.name"
                    label="Template Name *"
                    required
                  />
                  <FormInput
                    v-model="templateForm.code"
                    label="Template Code *"
                    required
                  />
                </div>

                <!-- Template Type -->
                <FormSelect
                  v-model="templateForm.letter_type"
                  label="Template Type *"
                  :options="typeOptions"
                  required
                />

                <!-- Approval Workflow Required Checkbox -->
                <FormCheckbox
                  v-model="templateForm.requires_approval"
                  label="Approval Workflow Required"
                  description="When active, outgoing letters generated from this template require authorized hr sign-off before official corporate sealing."
                />

                <!-- Fetch Information's Card (Figma 7454:138747) -->
                <div class="fetch-info-card">
                  <div class="fetch-info-header">
                    <span class="fetch-info-title">Fetch Information's</span>
                    <span class="fetch-info-count-pill">
                      <Tag :size="12" />
                      <span>{{ selectedFetchTokens.length }} Selected</span>
                    </span>
                  </div>

                  <p class="fetch-info-desc">
                    Click the information fields to insert them into the template body. The selected information will be visible in letters created using this template.
                  </p>

                  <!-- Category Pills -->
                  <div class="fetch-category-pills">
                    <button
                      v-for="cat in tokenCategories"
                      :key="cat"
                      class="category-pill-btn"
                      :class="{ active: activeTokenCategory === cat }"
                      @click="activeTokenCategory = cat"
                    >
                      {{ cat }}
                    </button>
                  </div>

                  <!-- Active Category Token Checkboxes -->
                  <div class="fetch-tokens-grid">
                    <label
                      v-for="t in tokensByCategory"
                      :key="t.token"
                      class="token-checkbox-label"
                    >
                      <input
                        type="checkbox"
                        :checked="isTokenSelected(t.token)"
                        class="token-checkbox"
                        @change="toggleFetchToken(t.token)"
                      />
                      <span class="token-label-text">{{ t.label }}</span>
                    </label>
                  </div>
                </div>

                <!-- Letter Body Textarea -->
                <div class="form-field-wrapper">
                  <label class="figma-field-label">Letter Body</label>
                  <textarea
                    v-model="templateForm.body"
                    rows="4"
                    class="figma-textarea"
                    placeholder="Enter letter body description..."
                  ></textarea>
                </div>
              </div>

              <!-- Accordion: Description For This template (Figma 7454:138406) -->
              <div class="figma-accordion-card">
                <div class="accordion-header" @click="isDescriptionAccordionOpen = !isDescriptionAccordionOpen">
                  <span class="accordion-title">Description For This template</span>
                  <component :is="isDescriptionAccordionOpen ? ChevronDown : ChevronRight" :size="16" class="accordion-chevron" />
                </div>

                <div v-show="isDescriptionAccordionOpen" class="accordion-body">
                  <FormInput
                    v-model="templateForm.description"
                    label="Template Governance Description"
                  />
                </div>
              </div>
            </div>
          </div>

          <!-- RIGHT PANE: REAL-TIME LIVE PREVIEW (Figma 7454:138747) -->
          <div v-show="drawerActiveMode === 'split' || drawerActiveMode === 'preview'" class="drawer-preview-pane">
            <div class="preview-scroll-viewport">
              <!-- Live Preview Test Context Pill -->
              <div class="live-test-context-pill">
                <span class="blue-dot"></span>
                <span>Live Preview Test Context</span>
              </div>

              <!-- Minimalist Document Paper Sheet -->
              <div class="figma-document-sheet">
                <!-- Letterhead Brand Row -->
                <div class="doc-header-row">
                  <div class="doc-brand-block">
                    <div class="brand-logo-m">
                      <svg width="36" height="36" viewBox="0 0 40 40" fill="none">
                        <circle cx="20" cy="20" r="19" stroke="#0B529C" stroke-width="2" />
                        <path d="M12 28L18 14L22 22L26 14L32 28" stroke="#0B529C" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
                      </svg>
                    </div>
                    <div class="brand-text-block">
                      <h4 class="brand-company-title">Qelem Meda Technologies</h4>
                      <p class="brand-company-sub">QMT - Addis Ababa, Ethiopia.</p>
                    </div>
                  </div>

                  <div class="doc-meta-block">
                    <p class="meta-line">Ref: Place for ref no.</p>
                    <p class="meta-line">Date: Place for Date.</p>
                  </div>
                </div>

                <!-- Structured Fact Sheet Table (Directly reflects selected Fetch Tokens!) -->
                <div class="figma-fact-sheet-card">
                  <table class="figma-fact-table">
                    <thead>
                      <tr>
                        <th v-for="col in previewFactColumns" :key="col.token">
                          {{ col.label }}
                        </th>
                        <th v-if="previewFactColumns.length === 0">
                          Full Name
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <td v-for="col in previewFactColumns" :key="col.token" class="fact-bold-val">
                          {{ col.sample }}
                        </td>
                        <td v-if="previewFactColumns.length === 0" class="fact-bold-val">
                          -
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>

                <!-- Body Content Text Block -->
                <div class="figma-letter-body-block">
                  <p class="body-lead-text">
                    {{ templateForm.body || 'Body Content...' }}
                  </p>
                </div>

                <!-- Minimalist Page 1/1 Pill (Bottom-Right) -->
                <div class="page-counter-pill">
                  <span>Page 1/1</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Drawer Footer (Figma 7454:138747) -->
        <div class="drawer-footer">
          <button class="btn-footer-close" @click="isCreateDrawerOpen = false">
            <X :size="14" />
            <span>Close</span>
          </button>

          <button class="btn-footer-save" @click="handleSaveTemplate">
            <span>Save</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Template Inspection Modal -->
    <div v-if="isInspectionModalOpen && inspectingTemplate" class="modal-backdrop" @click="isInspectionModalOpen = false">
      <div class="document-modal-content" @click.stop>
        <div class="doc-modal-header">
          <div class="doc-header-info">
            <span class="doc-code-pill">{{ inspectingTemplate.code }}</span>
            <h2 class="doc-title">{{ inspectingTemplate.name }}</h2>
          </div>
          <button class="btn-close-header" @click="isInspectionModalOpen = false">
            <X :size="18" />
          </button>
        </div>

        <div class="document-paper-container">
          <div class="figma-document-sheet modal-sheet">
            <div class="doc-header-row">
              <div class="doc-brand-block">
                <div class="brand-logo-m">
                  <svg width="36" height="36" viewBox="0 0 40 40" fill="none">
                    <circle cx="20" cy="20" r="19" stroke="#0B529C" stroke-width="2" />
                    <path d="M12 28L18 14L22 22L26 14L32 28" stroke="#0B529C" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
                  </svg>
                </div>
                <div class="brand-text-block">
                  <h4 class="brand-company-title">Qelem Meda Technologies</h4>
                  <p class="brand-company-sub">QMT - Addis Ababa, Ethiopia.</p>
                </div>
              </div>
              <div class="doc-meta-block">
                <p class="meta-line">Ref: {{ inspectingTemplate.code }}</p>
                <p class="meta-line">Type: {{ LETTER_TYPE_MAP[inspectingTemplate.letter_type]?.label }}</p>
              </div>
            </div>

            <div class="figma-fact-sheet-card">
              <table class="figma-fact-table">
                <thead>
                  <tr>
                    <th>Full Name</th>
                    <th>Verified Designation</th>
                    <th>Department</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="fact-bold-val">Sample Employee</td>
                    <td class="fact-bold-val">Verified Position</td>
                    <td class="fact-val">Assigned Department</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div class="figma-letter-body-block">
              <p class="body-lead-text">
                {{ inspectingTemplate.body }}
              </p>
            </div>

            <div class="page-counter-pill">
              <span>Page 1/1</span>
            </div>
          </div>
        </div>

        <div class="drawer-footer">
          <button class="btn-footer-close" @click="isInspectionModalOpen = false">
            <X :size="14" />
            <span>Close</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.letter-templates-page {
  padding: 24px;
  max-width: 1400px;
  margin: 0 auto;
}

/* Toast */
.toast-notification {
  position: fixed;
  top: 24px;
  right: 24px;
  background-color: #065f46;
  color: #ffffff;
  padding: 10px 18px;
  border-radius: 8px;
  font-size: 13.5px;
  display: flex;
  align-items: center;
  gap: 8px;
  z-index: 2000;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.toast-icon {
  color: #34d399;
}

/* Table Controls */
.table-controls-wrapper {
  padding: 0 16px 14px 16px;
}

.table-filter-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
}

.search-box {
  flex: 1;
  max-width: 380px;
}

.search-input {
  width: 100%;
  height: 38px;
  padding: 0 12px;
  font-size: 13px;
  color: #404040;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
  background-color: #ffffff;
}

.search-input:focus {
  border-color: #0b529c;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.table-toolbar-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-secondary-toolbar {
  height: 36px;
  padding: 0 14px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #404040;
  font-size: 12.5px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-secondary-toolbar:hover {
  background-color: #f8fafc;
}

.btn-icon-toolbar {
  width: 36px;
  height: 36px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  color: #64748b;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.btn-icon-toolbar:hover {
  background-color: #f8fafc;
  color: #0f172a;
}

.btn-primary-blue {
  height: 36px;
  padding: 0 16px;
  background-color: #0b529c;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: background-color 0.15s ease;
}

.btn-primary-blue:hover {
  background-color: #083e76;
}

/* Table Styles Standard */
.table-responsive {
  width: 100%;
  overflow-x: auto;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table th {
  height: 38px;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
  text-align: left;
}

.erp-table td {
  height: 52px;
  padding: 8px 16px;
  font-size: 13px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.table-row-hover:hover {
  background-color: #f8fafc;
  cursor: pointer;
}

.th-check, .td-check {
  width: 40px;
  text-align: center;
}

.table-checkbox {
  width: 16px;
  height: 16px;
  accent-color: #0b529c;
  cursor: pointer;
}

.template-name-cell {
  display: flex;
  flex-direction: column;
}

.table-name-primary {
  color: #404040;
  font-weight: 600;
  font-size: 13.5px;
}

.table-code-subtext {
  color: #737373;
  font-size: 12px;
}

.cell-plain-text {
  color: #737373;
  font-size: 13px;
}

/* Status State Pill (Active / Inactive) */
.state-pill {
  display: inline-block;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
}

.state-active { background-color: #ecfdf5; color: #059669; }
.state-inactive { background-color: #f1f5f9; color: #64748b; }

.btn-action-dots {
  width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  border-radius: 6px;
  color: #94a3b8;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #404040;
}

/* Pagination Bar (Figma 7454:138158) */
.figma-pagination-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 14px 16px;
  border-top: 1px solid #f1f5f9;
  font-size: 12.5px;
  color: #737373;
}

.pagination-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.per-page-wrapper {
  display: flex;
  align-items: center;
  gap: 6px;
}

.per-page-select {
  height: 30px;
  padding: 0 8px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  background-color: #ffffff;
  color: #404040;
  font-size: 12px;
  outline: none;
}

.pagination-right {
  display: flex;
  align-items: center;
  gap: 4px;
}

.btn-pag-nav {
  height: 30px;
  padding: 0 12px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  background-color: #ffffff;
  color: #404040;
  font-size: 12px;
  cursor: pointer;
}

.btn-pag-nav:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-pag-num {
  width: 30px;
  height: 30px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  background-color: #ffffff;
  color: #404040;
  font-size: 12px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-pag-num.active {
  background-color: #0b529c;
  border-color: #0b529c;
  color: #ffffff;
  font-weight: 600;
}

.pag-ellipsis {
  padding: 0 4px;
}

/* ═══════════════════════════════════════════════════════════════════════════ */
/* BOTTOM DRAWER STYLES (Figma 7454:138406 & 7454:138747)                     */
/* ═══════════════════════════════════════════════════════════════════════════ */
.drawer-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(4px);
  z-index: 1050;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  animation: fadeIn 0.2s ease-out;
}

.bottom-drawer-container {
  width: 100%;
  height: 88vh;
  max-height: 92vh;
  background-color: #ffffff;
  border-top-left-radius: 16px;
  border-top-right-radius: 16px;
  box-shadow: 0 -20px 40px rgba(0, 0, 0, 0.2);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  animation: slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

.drawer-drag-pill {
  width: 44px;
  height: 4px;
  background-color: #cbd5e1;
  border-radius: 9999px;
  margin: 8px auto 0 auto;
}

.drawer-header {
  padding: 14px 28px 16px 28px;
  background-color: #ffffff;
  border-bottom: 1px solid #f1f5f9;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.drawer-header-left {
  display: flex;
  flex-direction: column;
}

.drawer-title {
  font-size: 18px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.drawer-subtext {
  font-size: 12.5px;
  color: #737373;
  margin: 2px 0 0 0;
}

.drawer-header-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.drawer-segmented-pills {
  display: flex;
  background-color: #f1f5f9;
  padding: 3px;
  border-radius: 9999px;
  gap: 2px;
}

.seg-pill-btn {
  border: none;
  background: transparent;
  padding: 5px 14px;
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
  border-radius: 9999px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.seg-pill-btn.active {
  background-color: #ffffff;
  color: #0f172a;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
  font-weight: 600;
}

.btn-close-header {
  width: 32px;
  height: 32px;
  border: none;
  background: transparent;
  color: #64748b;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.btn-close-header:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

/* Split Body */
.drawer-split-body {
  flex: 1;
  display: flex;
  overflow: hidden;
  height: calc(100% - 130px);
}

.drawer-split-body.mode-split .drawer-form-pane {
  width: 48%;
  border-right: 1px solid #f1f5f9;
}

.drawer-split-body.mode-split .drawer-preview-pane {
  width: 52%;
}

.drawer-split-body.mode-editor .drawer-form-pane {
  width: 100%;
  max-width: 900px;
  margin: 0 auto;
}

.drawer-split-body.mode-editor .drawer-preview-pane {
  display: none;
}

.drawer-split-body.mode-preview .drawer-form-pane {
  display: none;
}

.drawer-split-body.mode-preview .drawer-preview-pane {
  width: 100%;
}

/* Form Pane */
.drawer-form-pane {
  overflow-y: auto;
  padding: 24px 28px;
  background-color: #ffffff;
}

.pane-scroll-inner {
  display: flex;
  flex-direction: column;
  gap: 16px;
  max-width: 680px;
}

.figma-form-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 18px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
}

.form-field-wrapper {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.figma-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.figma-textarea {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  color: #404040;
  outline: none;
  font-family: inherit;
  resize: vertical;
}

.figma-textarea:focus {
  border-color: #0b529c;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

/* Fetch Information Card (Figma 7454:138747) */
.fetch-info-card {
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 16px;
  background-color: #ffffff;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.fetch-info-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.fetch-info-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #1e293b;
}

.fetch-info-count-pill {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  background-color: #e0f2fe;
  color: #0284c7;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 600;
}

.fetch-info-desc {
  font-size: 12px;
  color: #737373;
  margin: 0;
  line-height: 1.5;
}

.fetch-category-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 4px;
}

.category-pill-btn {
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  border-radius: 9999px;
  padding: 4px 12px;
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s ease;
}

.category-pill-btn.active {
  background-color: #0b529c;
  border-color: #0b529c;
  color: #ffffff;
}

.fetch-tokens-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  padding-top: 8px;
  border-top: 1px solid #f1f5f9;
}

.token-checkbox-label {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 12.5px;
  color: #404040;
  cursor: pointer;
  user-select: none;
}

.token-checkbox {
  width: 15px;
  height: 15px;
  accent-color: #0b529c;
}

/* Accordion Card */
.figma-accordion-card {
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  overflow: hidden;
  background-color: #ffffff;
}

.accordion-header {
  padding: 14px 18px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  user-select: none;
  background-color: #ffffff;
  transition: background-color 0.15s ease;
}

.accordion-header:hover {
  background-color: #f8fafc;
}

.accordion-title {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
}

.accordion-chevron {
  color: #94a3b8;
}

.accordion-body {
  padding: 16px 18px 20px 18px;
  border-top: 1px solid #f1f5f9;
  background-color: #ffffff;
}

/* Right Preview Pane (Figma 7454:138747) */
.drawer-preview-pane {
  overflow-y: auto;
  padding: 24px;
  background-color: #ffffff;
  display: flex;
  justify-content: center;
  align-items: flex-start;
}

.preview-scroll-viewport {
  width: 100%;
  max-width: 680px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.live-test-context-pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #e0f2fe;
  color: #0284c7;
  font-size: 11.5px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 9999px;
  align-self: flex-start;
}

.blue-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background-color: #0284c7;
}

.figma-document-sheet {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 36px 40px;
  min-height: 520px;
  display: flex;
  flex-direction: column;
  position: relative;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.modal-sheet {
  border: none;
  box-shadow: none;
  padding: 24px;
}

.doc-header-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 24px;
}

.doc-brand-block {
  display: flex;
  align-items: center;
  gap: 12px;
}

.brand-company-title {
  font-size: 15px;
  font-weight: 600;
  color: #1e293b;
  margin: 0;
}

.brand-company-sub {
  font-size: 11.5px;
  color: #737373;
  margin: 2px 0 0 0;
}

.doc-meta-block {
  text-align: right;
  font-size: 11.5px;
  color: #737373;
  line-height: 1.5;
}

.meta-line {
  margin: 0;
}

/* Fact Sheet Table */
.figma-fact-sheet-card {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  margin-bottom: 24px;
}

.figma-fact-table {
  width: 100%;
  border-collapse: collapse;
}

.figma-fact-table th {
  background-color: #ffffff;
  padding: 10px 14px;
  font-size: 11.5px;
  font-weight: 500;
  color: #737373;
  text-align: left;
  border-bottom: 1px solid #f1f5f9;
}

.figma-fact-table td {
  padding: 12px 14px;
  font-size: 13px;
  color: #404040;
}

.fact-bold-val {
  font-weight: 600;
  color: #1e293b;
}

.figma-letter-body-block {
  font-size: 13px;
  line-height: 1.7;
  color: #475569;
  margin-bottom: 24px;
}

.body-lead-text {
  margin: 0;
}

.page-counter-pill {
  position: absolute;
  bottom: 20px;
  right: 24px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  border-radius: 9999px;
  padding: 4px 12px;
  font-size: 11.5px;
  font-weight: 500;
  color: #404040;
}

/* Drawer Footer */
.drawer-footer {
  height: 64px;
  background-color: #ffffff;
  border-top: 1px solid #e2e8f0;
  padding: 0 28px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.btn-footer-close {
  height: 36px;
  padding: 0 16px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #404040;
  font-size: 13px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-footer-close:hover {
  background-color: #f8fafc;
}

.btn-footer-save {
  height: 36px;
  padding: 0 24px;
  background-color: #0b529c;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-footer-save:hover {
  background-color: #083e76;
}

/* Inspection Modal */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1100;
}

.document-modal-content {
  background-color: #ffffff;
  border-radius: 12px;
  width: 780px;
  max-width: 95vw;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.2);
  overflow: hidden;
}

.doc-modal-header {
  padding: 16px 24px;
  border-bottom: 1px solid #e2e8f0;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.doc-header-info {
  display: flex;
  align-items: center;
  gap: 10px;
}

.doc-code-pill {
  background-color: #f1f5f9;
  color: #404040;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 600;
}

.doc-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.btn-close-header {
  width: 32px;
  height: 32px;
  border: none;
  background: transparent;
  color: #64748b;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.btn-close-header:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.document-paper-container {
  padding: 24px;
  overflow-y: auto;
  flex: 1;
}

/* Animations */
@keyframes slideUp {
  from {
    transform: translateY(100%);
  }
  to {
    transform: translateY(0);
  }
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}
</style>
