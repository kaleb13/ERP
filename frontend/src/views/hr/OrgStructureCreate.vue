<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { 
  Monitor, ChevronRight, X, GitBranch, FolderTree,
  Plus, Trash2, Calendar, ChevronDown, Columns,
  List, Table, Link as LinkIcon, Image as ImageIcon,
  Undo, Redo, MoreVertical, FileText
} from 'lucide-vue-next';
import BaseTabs, { type TabItem } from '../../components/BaseTabs.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';

const router = useRouter();
const route = useRoute();

// ─── Document State ───
const isSaved = ref(false);
const quickActionToast = ref<string | null>(null);
const isUnitPlacementOpen = ref(true);

// ─── Active Tab (BaseTabs Standard Matching Critic Screenshot) ───
type TabId = 'structures' | 'units';
const activeTab = ref<TabId>('structures');

const tabs = computed<TabItem[]>(() => [
  { id: 'structures', label: 'Organization Structures', icon: GitBranch },
  { id: 'units', label: 'Organization Units', icon: FolderTree }
]);

// ─── Master Form State (Schema Lines 968–990 - Zero Manual Code Input) ───
const form = ref({
  name: '',
  entity_id: '',
  structure_state_lookup_value_id: 'active',
  effective_from: new Date().toISOString().split('T')[0],
  effective_to: '',
  description: ''
});

// ─── Master Catalog of Existing Organization Units ───
export interface MasterOrgUnit {
  id: number;
  code: string;
  name: string;
  type: string;
}

const masterOrgUnits: MasterOrgUnit[] = [
  { id: 101, code: 'OU - EXEC', name: 'Executive Board & CEO Office', type: 'Board / Office' },
  { id: 102, code: 'OU - OPS', name: 'Operations Division', type: 'Division' },
  { id: 103, code: 'OU - FIN', name: 'Finance & Corporate Services Division', type: 'Division' },
  { id: 104, code: 'OU - HR', name: 'Human Resources', type: 'Department' },
  { id: 105, code: 'OU - PROC', name: 'Procurement & Logistics Department', type: 'Department' },
  { id: 106, code: 'OU - ACC', name: 'General Accounting & Audit', type: 'Department' },
  { id: 107, code: 'OU - PAY', name: 'Payroll & Statutory Benefits', type: 'Section' },
  { id: 108, code: 'OU - REC', name: 'Talent Acquisition & Onboarding', type: 'Section' },
  { id: 109, code: 'OU - COMM', name: 'Commercial Sales & Business Development', type: 'Division' },
  { id: 110, code: 'OU - EAST', name: 'East Region Operations', type: 'Region' }
];

// ─── Dynamic Child Organization Units (Dynamic Table Rows) ───
export interface StructureUnitRow {
  id: number;
  unit_id: number | null;
  code: string;
  name: string;
  type: string;
}

const unitsList = ref<StructureUnitRow[]>([]);
const selectedUnitIds = ref<number[]>([]);

// ─── Selection Management for Sub-table ───
const isAllUnitsSelected = computed(() => {
  return unitsList.value.length > 0 && unitsList.value.every(u => selectedUnitIds.value.includes(u.id));
});

const toggleSelectAllUnits = () => {
  if (isAllUnitsSelected.value) {
    selectedUnitIds.value = [];
  } else {
    selectedUnitIds.value = unitsList.value.map(u => u.id);
  }
};

const toggleUnitSelection = (id: number) => {
  const idx = selectedUnitIds.value.indexOf(id);
  if (idx > -1) {
    selectedUnitIds.value.splice(idx, 1);
  } else {
    selectedUnitIds.value.push(id);
  }
};

// ─── Dynamic Table Inline Actions (Select on the go) ───
const handleSelectUnit = (row: StructureUnitRow) => {
  if (!row.unit_id) {
    row.code = '';
    row.name = '';
    row.type = '';
    return;
  }
  const found = masterOrgUnits.find(u => u.id === Number(row.unit_id));
  if (found) {
    row.code = found.code;
    row.name = found.name;
    row.type = found.type;
  }
};

const addUnitRow = () => {
  unitsList.value.push({
    id: Date.now(),
    unit_id: null,
    code: '',
    name: '',
    type: ''
  });
};

const removeUnitRow = (id: number) => {
  unitsList.value = unitsList.value.filter(u => u.id !== id);
  selectedUnitIds.value = selectedUnitIds.value.filter(uid => uid !== id);
  showToast('Row removed.');
};

const handleBatchDeleteUnits = () => {
  const toDelete = new Set(selectedUnitIds.value);
  unitsList.value = unitsList.value.filter(u => !toDelete.has(u.id));
  selectedUnitIds.value = [];
  showToast('Selected rows removed.');
};

// ─── Global Save & Clear ───
const handleSave = () => {
  if (!form.value.name.trim()) {
    showToast('Please enter Structure Name.');
    return;
  }

  isSaved.value = true;
  showToast(`Organization Structure "${form.value.name}" saved successfully.`);

  setTimeout(() => {
    router.push('/hr/org-structures');
  }, 1200);
};

const clearForm = () => {
  form.value = {
    name: '',
    entity_id: '',
    effective_from: new Date().toISOString().split('T')[0],
    effective_to: '',
    description: ''
  };
  unitsList.value = [];
  selectedUnitIds.value = [];
  isSaved.value = false;
  showToast('Form cleared.');
};

const showToast = (msg: string) => {
  quickActionToast.value = msg;
  setTimeout(() => {
    quickActionToast.value = null;
  }, 4000);
};

const showMoreMenu = ref(false);

const handleSaveAsDraft = () => {
  showMoreMenu.value = false;
  form.value.structure_state_lookup_value_id = 'draft';
  isSaved.value = true;
  quickActionToast.value = 'Organization structure saved as Draft.';
  setTimeout(() => {
    router.push('/hr/org-structures');
  }, 500);
};

const onDocumentClick = (e: MouseEvent) => {
  const target = e.target as HTMLElement;
  if (!target.closest('.header-more-menu-wrapper')) {
    showMoreMenu.value = false;
  }
};

// ─── Mounted: Hydrate from Route Query if expanded ───
onMounted(() => {
  document.addEventListener('click', onDocumentClick);
  if (route.query.name) form.value.name = String(route.query.name);
  if (route.query.entity_id) form.value.entity_id = String(route.query.entity_id);
  if (route.query.effective_from) form.value.effective_from = String(route.query.effective_from);
  if (route.query.effective_to) form.value.effective_to = String(route.query.effective_to);
  if (route.query.description) form.value.description = String(route.query.description);
});

onUnmounted(() => {
  document.removeEventListener('click', onDocumentClick);
});
</script>

<template>
  <div class="org-structure-create-page">
    <!-- Top Action & Breadcrumb Navigation Bar (Exact Critic Match) -->
    <div class="create-header-bar">
      <div class="header-left">
        <div class="breadcrumb-strip">
          <router-link to="/home" class="bc-home-icon" title="Home">
            <Monitor :size="15" />
          </router-link>
          <ChevronRight :size="13" class="bc-sep" />
          <router-link to="/hr/org-structures" class="bc-link">Org Structures</router-link>
          <ChevronRight :size="13" class="bc-sep" />
          <span class="bc-current">Create Org Structure</span>
          <SaveStateBadge :isSaved="isSaved" :isDraft="form.structure_state === 'draft'" />
        </div>
      </div>

      <div class="header-actions">
        <!-- 3-Dots Action Menu (Available for Draft support) -->
        <div class="header-more-menu-wrapper">
          <button 
            type="button" 
            class="btn-more-action" 
            @click.stop="showMoreMenu = !showMoreMenu"
            aria-label="More Options"
          >
            <MoreVertical :size="16" />
          </button>
          
          <div v-if="showMoreMenu" class="header-more-dropdown" @click.stop>
            <button type="button" class="more-menu-item" @click="handleSaveAsDraft">
              <FileText :size="14" class="menu-item-icon" />
              <span>Save as Draft</span>
            </button>
          </div>
        </div>

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

    <!-- Capsule Tabs Navigation Standard (<BaseTabs /> Matching Image 1 & 2) -->
    <div class="create-tabs-wrapper">
      <BaseTabs 
        v-model="activeTab"
        :tabs="tabs"
        size="md"
      />
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 1: ORGANIZATION STRUCTURES (Information Card)             -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'structures'" class="tab-content-container">
      <div class="clean-card">
        <div class="section-title-box">
          <h2 class="section-title">Organization Structure Information</h2>
        </div>

        <!-- 3-Column Responsive Grid (No Code Input - Clean Critic Layout) -->
        <div class="form-grid-3">
          <FormInput 
            label="Structure Name" 
            v-model="form.name" 
            required 
          />

          <FormSelect
            label="Owning Entity"
            v-model="form.entity_id"
            placeholder="Select Entity"
            :options="[
              { label: 'QMT Bole', value: '1' },
              { label: 'QMT Mekanisa', value: '2' },
              { label: 'QMT koye', value: '3' },
              { label: 'Haleta Addis Ababa HQ', value: '4' }
            ]"
          />

          <!-- Effective From Date with [GC] Badge -->
          <div class="gc-date-field">
            <label class="gc-field-label">Effective From Date <span class="required-star">*</span></label>
            <div class="gc-date-input-wrap">
              <Calendar :size="15" class="gc-cal-icon" />
              <input
                type="date"
                v-model="form.effective_from"
                class="gc-date-input"
                required
              />
              <span class="gc-pill-tag">GC</span>
            </div>
          </div>

          <!-- Effective To Date with [GC] Badge -->
          <div class="gc-date-field">
            <label class="gc-field-label">Effective To Date <span class="required-star">*</span></label>
            <div class="gc-date-input-wrap">
              <Calendar :size="15" class="gc-cal-icon" />
              <input
                type="date"
                v-model="form.effective_to"
                class="gc-date-input"
                required
              />
              <span class="gc-pill-tag">GC</span>
            </div>
          </div>
        </div>

        <!-- Strategic Description Rich Text Editor (Exact Match to Critic) -->
        <div class="biography-section mt-5">
          <label class="gc-field-label">Strategic Description</label>

          <div class="rich-editor-container">
            <!-- Toolbar -->
            <div class="editor-toolbar">
              <div class="toolbar-dropdown">
                <span>Paragraph</span>
                <ChevronDown :size="12" />
              </div>

              <div class="toolbar-divider"></div>

              <div class="toolbar-dropdown">
                <span>Font Type</span>
                <ChevronDown :size="12" />
              </div>

              <div class="toolbar-divider"></div>

              <div class="toolbar-icon-group">
                <button type="button" class="editor-icon-btn" title="List"><List :size="14" /><ChevronDown :size="10" /></button>
                <button type="button" class="editor-icon-btn font-bold" title="Bold">B</button>
                <button type="button" class="editor-icon-btn italic" title="Italic">I</button>
                <button type="button" class="editor-icon-btn underline" title="Underline">U</button>
                <button type="button" class="editor-icon-btn line-through" title="Strikethrough">S</button>
                <button type="button" class="editor-icon-btn" title="Code">&lt;&gt;</button>
                <button type="button" class="editor-icon-btn" title="Table"><Table :size="14" /></button>
              </div>

              <div class="toolbar-divider"></div>

              <div class="toolbar-icon-group">
                <button type="button" class="editor-color-box" title="Text Color"></button>
                <button type="button" class="editor-icon-btn" title="Insert Link"><LinkIcon :size="14" /></button>
                <button type="button" class="editor-icon-btn" title="Insert Image"><ImageIcon :size="14" /></button>
              </div>

              <div class="toolbar-icon-group ml-auto">
                <button type="button" class="editor-icon-btn" title="Undo"><Undo :size="14" /></button>
                <button type="button" class="editor-icon-btn" title="Redo"><Redo :size="14" /></button>
              </div>
            </div>

            <!-- Text Area -->
            <textarea
              v-model="form.description"
              rows="6"
              class="editor-textarea"
            ></textarea>

            <!-- Footer Bar with Character Counter -->
            <div class="editor-footer">
              <span class="char-count-pill">{{ form.description.length }} / 5,000 Characters</span>
              <div class="editor-resize-handle">//</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 2: ORGANIZATION UNITS (Unit Placement Card)               -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'units'" class="tab-content-container">
      <div class="clean-card">
        <!-- Accordion Title: Unit Placement ⌵ (Image 1 Critic) -->
        <div 
          class="section-accordion-header" 
          @click="isUnitPlacementOpen = !isUnitPlacementOpen"
        >
          <span class="accordion-title-text">Unit Placement</span>
          <ChevronDown 
            :size="15" 
            class="accordion-chevron"
            :class="{ 'rotate-180': !isUnitPlacementOpen }" 
          />
        </div>

        <div v-show="isUnitPlacementOpen" class="accordion-body-content mt-3">
          <!-- Dynamic Child Sub-Table (Columns: Checkbox, No., Organization Unit, Unit Type, Column Icon) -->
          <div class="child-table-wrapper">
            <table class="child-table">
              <thead>
                <tr class="child-table-header">
                  <th class="child-th child-th-check">
                    <input 
                      type="checkbox" 
                      class="table-checkbox" 
                      :checked="isAllUnitsSelected" 
                      @change="toggleSelectAllUnits"
                      aria-label="Select All Units" 
                    />
                  </th>
                  <th class="child-th child-th-no">No.</th>
                  <th class="child-th" style="min-width: 280px;">Organization Unit</th>
                  <th class="child-th" style="min-width: 200px;">Unit Type</th>
                  <th class="child-th child-th-col-icon text-center">
                    <Columns :size="14" class="col-icon-hider" />
                  </th>
                </tr>
              </thead>
              <tbody>
                <!-- Empty State (Exact Match: "No Row" in Center) -->
                <tr v-if="unitsList.length === 0">
                  <td colspan="5" class="child-td-empty">No Row</td>
                </tr>

                <!-- Populated Dynamic Rows -->
                <tr 
                  v-else
                  v-for="(row, idx) in unitsList" 
                  :key="row.id"
                  class="child-tr"
                  :class="{ 'row-selected': selectedUnitIds.includes(row.id) }"
                >
                  <td class="child-td child-td-check" @click.stop>
                    <input 
                      type="checkbox" 
                      class="table-checkbox" 
                      :checked="selectedUnitIds.includes(row.id)" 
                      @change="toggleUnitSelection(row.id)" 
                    />
                  </td>

                  <td class="child-td child-td-no">{{ idx + 1 }}</td>

                  <td class="child-td">
                    <select 
                      v-model="row.unit_id" 
                      @change="handleSelectUnit(row)" 
                      class="child-inline-select"
                    >
                      <option :value="null" disabled>Select Organization Unit</option>
                      <option 
                        v-for="unit in masterOrgUnits" 
                        :key="unit.id" 
                        :value="unit.id"
                      >
                        {{ unit.name }}
                      </option>
                    </select>
                  </td>

                  <td class="child-td">
                    <span v-if="row.type" class="type-pill capitalize">{{ row.type }}</span>
                    <span v-else class="text-slate-400 text-xs">—</span>
                  </td>

                  <td class="child-td child-td-col-icon text-center">
                    <button 
                      type="button" 
                      class="btn-icon-danger"
                      title="Remove row"
                      @click="removeUnitRow(row.id)"
                    >
                      <Trash2 :size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- + Add Row Button (Always Below Table Matching Image 1) -->
          <button type="button" class="btn-add-row" @click="addUnitRow">
            <Plus :size="13" />
            <span>Add Row</span>
          </button>
        </div>
      </div>

      <!-- Floating Bar for Child Sub-Table -->
      <TableFloatingBar 
        :show="selectedUnitIds.length > 0"
        :selected-count="selectedUnitIds.length"
        :total-count="unitsList.length"
        @delete="handleBatchDeleteUnits"
        @close="selectedUnitIds = []"
      />
    </div>
  </div>
</template>

<style scoped>
.org-structure-create-page {
  padding: 16px 24px 80px;
  background-color: var(--primitive-color-neutral-50, #f8fafc);
  min-height: calc(100vh - 60px);
}

/* Header Bar */
.create-header-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.header-left {
  display: flex;
  align-items: center;
}

.breadcrumb-strip {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
}

.bc-home-icon {
  color: #64748b;
  display: flex;
  align-items: center;
  text-decoration: none;
}
.bc-home-icon:hover { color: #0B529C; }

.bc-sep {
  color: #94a3b8;
}

.bc-link {
  color: #64748b;
  text-decoration: none;
  font-weight: 500;
}
.bc-link:hover {
  color: #0B529C;
}

.bc-current {
  color: #404040;
  font-weight: 600;
}

.state-pill {
  display: inline-block;
  padding: 1.5px 8px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: 600;
  margin-left: 6px;
}
.state-unsaved {
  background-color: #fffbeb;
  color: #d97706;
  border: 1px solid #fde68a;
}
.state-saved {
  background-color: #ecfdf5;
  color: #059669;
  border: 1px solid #a7f3d0;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.header-more-menu-wrapper {
  position: relative;
  display: inline-flex;
}

.btn-more-action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-more-action:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.header-more-dropdown {
  position: absolute;
  top: calc(100% + 6px);
  left: 0;
  min-width: 170px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.08);
  padding: 4px 0;
  z-index: 50;
  animation: fadeIn 0.12s ease-in-out;
}

.more-menu-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  border: none;
  background: transparent;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.1s ease;
}
.more-menu-item:hover {
  background-color: #f8fafc;
  color: #0B529C;
}

.menu-item-icon {
  color: #64748b;
}
.more-menu-item:hover .menu-item-icon {
  color: #0B529C;
}

.btn-clear-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 12px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #404040;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
}
.btn-clear-action:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.btn-save-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 18px;
  background-color: #0B529C;
  border: none;
  border-radius: 8px;
  color: #ffffff;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
}
.btn-save-action:hover {
  background-color: #094482;
}

/* Toast */
.quick-toast-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #ecfdf5;
  border: 1px solid #a7f3d0;
  color: #065f46;
  padding: 7px 12px;
  border-radius: 6px;
  font-size: 12.5px;
  margin-bottom: 12px;
}

/* Tabs */
.create-tabs-wrapper {
  margin-bottom: 16px;
}

/* Card & Content */
.tab-content-container {
  animation: fadeIn 0.15s ease;
}

.clean-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 20px 22px;
}

.section-title-box {
  margin-bottom: 16px;
}
.section-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}

/* GC Date Input with Calendar Badge */
.gc-date-field {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.gc-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}
.required-star {
  color: #ef4444;
}

.gc-date-input-wrap {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
  height: 38px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #ffffff;
  padding: 0 10px;
  transition: all 0.15s ease;
}
.gc-date-input-wrap:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.gc-cal-icon {
  color: #64748b;
  margin-right: 8px;
  flex-shrink: 0;
}

.gc-date-input {
  flex: 1;
  border: none;
  height: 100%;
  font-size: 13px;
  color: #404040;
  outline: none;
  background: transparent;
}

.gc-pill-tag {
  font-size: 11px;
  font-weight: 600;
  color: #64748b;
  background-color: #f1f5f9;
  padding: 2px 6px;
  border-radius: 4px;
  user-select: none;
}

/* Strategic Description Rich Editor */
.biography-section {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.rich-editor-container {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  background: #ffffff;
}

.editor-toolbar {
  display: flex;
  align-items: center;
  padding: 6px 10px;
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
  gap: 6px;
  flex-wrap: wrap;
}

.toolbar-dropdown {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 12px;
  font-weight: 500;
  color: #475569;
  cursor: pointer;
  padding: 3px 6px;
  border-radius: 4px;
}
.toolbar-dropdown:hover { background: #f1f5f9; }

.toolbar-divider {
  width: 1px;
  height: 16px;
  background-color: #e2e8f0;
}

.toolbar-icon-group {
  display: flex;
  align-items: center;
  gap: 2px;
}

.editor-icon-btn {
  background: none;
  border: none;
  padding: 4px 6px;
  border-radius: 4px;
  color: #475569;
  font-size: 12px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 2px;
  transition: background 0.15s;
}
.editor-icon-btn:hover { background: #e2e8f0; color: #0f172a; }

.editor-color-box {
  width: 14px;
  height: 14px;
  background: #0f172a;
  border: 1px solid #cbd5e1;
  border-radius: 2px;
  cursor: pointer;
  margin: 0 4px;
}

.editor-textarea {
  width: 100%;
  padding: 12px 14px;
  border: none;
  outline: none;
  font-size: 13px;
  color: #404040;
  line-height: 1.55;
  resize: vertical;
  font-family: inherit;
}

.editor-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 12px;
  border-top: 1px solid #f1f5f9;
  background-color: #ffffff;
}

.char-count-pill {
  font-size: 11px;
  color: #64748b;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 2px 8px;
  border-radius: 9999px;
}

.editor-resize-handle {
  font-size: 11px;
  color: #cbd5e1;
  cursor: se-resize;
  user-select: none;
}

/* Accordion in Tab 2 */
.section-accordion-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: pointer;
  padding: 2px 0 8px;
  user-select: none;
}

.accordion-title-text {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.accordion-chevron {
  color: #64748b;
  transition: transform 0.2s ease;
}

/* Dynamic Child Sub-Table Standards */
.child-table-wrapper {
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  overflow: hidden;
  background: #ffffff;
}

.child-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.child-table-header {
  background-color: #f8fafc;
  border-bottom: 1px solid #e5e7eb;
}

.child-th {
  padding: 8px 12px;
  font-size: 12px;
  font-weight: 500;
  color: #404040;
  border-right: 1px solid #e5e7eb;
  white-space: nowrap;
  user-select: none;
}
.child-th:last-child {
  border-right: none;
}

.child-th-check {
  width: 44px;
  text-align: center;
}

.child-th-no {
  width: 44px;
  text-align: center;
}

.child-th-col-icon {
  width: 44px;
  text-align: center;
}

.col-icon-hider {
  color: #94a3b8;
  margin: 0 auto;
}

.child-tr {
  border-bottom: 1px solid #f1f5f9;
  transition: background-color 0.1s ease;
}
.child-tr:last-child {
  border-bottom: none;
}
.child-tr:hover {
  background-color: #fbfcfd;
}

.child-td {
  padding: 4px 8px;
  font-size: 12.5px;
  color: #737373;
  border-right: 1px solid #e5e7eb;
  vertical-align: middle;
}
.child-td:last-child {
  border-right: none;
}

.child-td-empty {
  padding: 36px 16px;
  text-align: center;
  font-size: 13px;
  font-weight: 500;
  color: #94a3b8;
  background-color: #ffffff;
}

.child-td-check {
  width: 44px;
  text-align: center;
}

.child-td-no {
  width: 44px;
  text-align: center;
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
}

.child-td-col-icon {
  width: 44px;
  text-align: center;
}

.child-inline-select {
  width: 100%;
  height: 30px;
  border: 1px solid transparent;
  border-radius: 4px;
  padding: 0 6px;
  font-size: 12.5px;
  color: #404040;
  background: transparent;
  outline: none;
  cursor: pointer;
  transition: all 0.15s ease;
}
.child-inline-select:hover {
  background-color: #f8fafc;
  border-color: #e2e8f0;
}
.child-inline-select:focus {
  background-color: #ffffff;
  border-color: #0B529C;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.08);
}

.table-checkbox {
  appearance: none;
  -webkit-appearance: none;
  width: 17px;
  height: 17px;
  min-width: 17px;
  min-height: 17px;
  border-radius: 5px;
  border: 1.5px solid #d1d5db;
  background-color: #ffffff;
  cursor: pointer;
  display: inline-grid;
  place-content: center;
  position: relative;
  vertical-align: middle;
  outline: none;
  margin: 0;
  padding: 0;
  transition: all 0.15s ease;
  flex-shrink: 0;
}

.table-checkbox:hover:not(:checked):not(:disabled) {
  border-color: #9ca3af;
  background-color: #f9fafb;
}

.table-checkbox:checked {
  background-color: #0B529C;
  border-color: #0B529C;
  background-image: url("data:image/svg+xml,%3csvg viewBox='0 0 16 16' fill='none' stroke='white' stroke-width='2.6' stroke-linecap='round' stroke-linejoin='round' xmlns='http://www.w3.org/2000/svg'%3e%3cpolyline points='3.5 8.5 6.5 11.5 12.5 5.5'/%3e%3c/svg%3e");
  background-position: center;
  background-repeat: no-repeat;
  background-size: 75% 75%;
}

.btn-add-row {
  height: 32px;
  padding: 0 14px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  margin-top: 12px;
  transition: all 0.15s ease;
}
.btn-add-row:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.row-selected td {
  background-color: #eff6ff !important;
}

.type-pill {
  display: inline-block;
  padding: 1.5px 7px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 500;
  background-color: #eff6ff;
  color: #0369a1;
  border: 1px solid #bae6fd;
}

.btn-icon-danger {
  background: transparent;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 4px;
  border-radius: 4px;
  transition: all 0.15s ease;
}
.btn-icon-danger:hover {
  color: #ef4444;
  background-color: #fef2f2;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(2px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
