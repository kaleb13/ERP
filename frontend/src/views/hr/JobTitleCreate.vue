<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { 
  Monitor, ChevronRight, X, Briefcase, Plus, Trash2, 
  ChevronDown, Search, Check, List, Table, Link as LinkIcon, 
  Image as ImageIcon, Undo, Redo, UserCheck, DollarSign, 
  Calculator, Truck, Building2, Scale, Laptop, ShieldCheck, 
  Award, BadgeCheck, Users, Landmark, Clock, HeartPulse, 
  FileText, ShoppingBag, Target, BookOpen, Wrench, GraduationCap
} from 'lucide-vue-next';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';

const router = useRouter();
const route = useRoute();

// ─── Document State ───
const isSaved = ref(false);
const quickActionToast = ref<string | null>(null);
const showIconPickerModal = ref(false);
const iconSearchQuery = ref('');
const selectedIconCategory = ref('All');

// ─── Options & Catalogues ───
const categoryOptions = [
  { label: 'Non-Management (OT & Benefits Eligible)', value: 'non_management' },
  { label: 'Management (Leadership / Salaried)', value: 'management' },
  { label: 'Executive (C-Suite / Executive Board)', value: 'executive' }
];

const entityOptions = [
  { value: 1, label: 'QMT Business Group (HQ)' },
  { value: 3, label: 'Haleta Addis Ababa HQ' },
  { value: 7, label: 'Haleta Grand Hotel & Suites' },
  { value: 9, label: 'Haleta Hawassa Hub' }
];

const statusOptions = [
  { label: 'Approved for All Entities (acceptForAll)', value: 'acceptForAll' },
  { label: 'Approved for This Entity Only (acceptForThis)', value: 'acceptForThis' },
  { label: 'Pending Approval (pending)', value: 'pending' }
];

// ─── Form State (Schema lines 1110–1122) ───
const form = ref({
  name: '',
  category: 'non_management',
  entity_id: 3,
  status: 'acceptForAll',
  icon_id: null as number | null,
  icon_name: null as string | null,
  description: ''
});

// ─── Icon Catalogue (HR_Schema_final-v4 lines 1119 & 1124) ───
interface RoleIconItem {
  id: number;
  name: string;
  label: string;
  category: string;
  component: any;
}

const iconCatalogue: RoleIconItem[] = [
  { id: 20, name: 'Briefcase', label: 'General Role', category: 'Executive', component: Briefcase },
  { id: 21, name: 'UserCheck', label: 'HR Officer', category: 'Human Resources', component: UserCheck },
  { id: 22, name: 'DollarSign', label: 'Cashier', category: 'Finance', component: DollarSign },
  { id: 23, name: 'Calculator', label: 'Financial Accountant', category: 'Finance', component: Calculator },
  { id: 24, name: 'Truck', label: 'Procurement Officer', category: 'Operations', component: Truck },
  { id: 25, name: 'Building2', label: 'Finance Manager', category: 'Executive', component: Building2 },
  { id: 26, name: 'Users', label: 'People & Culture', category: 'Human Resources', component: Users },
  { id: 27, name: 'ShieldCheck', label: 'Compliance Officer', category: 'Governance', component: ShieldCheck },
  { id: 28, name: 'Award', label: 'Director / Executive', category: 'Executive', component: Award },
  { id: 29, name: 'BadgeCheck', label: 'Certified Specialist', category: 'Governance', component: BadgeCheck },
  { id: 30, name: 'Scale', label: 'Legal Counsel', category: 'Governance', component: Scale },
  { id: 31, name: 'Laptop', label: 'Systems & IT Analyst', category: 'Technical', component: Laptop },
  { id: 32, name: 'Landmark', label: 'Treasury & Banking', category: 'Finance', component: Landmark },
  { id: 33, name: 'Clock', label: 'Shift Roster Lead', category: 'Operations', component: Clock },
  { id: 34, name: 'HeartPulse', label: 'Occupational Health', category: 'Human Resources', component: HeartPulse },
  { id: 35, name: 'FileText', label: 'Executive Administrator', category: 'Administration', component: FileText },
  { id: 36, name: 'ShoppingBag', label: 'Commercial Sales', category: 'Operations', component: ShoppingBag },
  { id: 37, name: 'Target', label: 'Strategic Planning', category: 'Executive', component: Target },
  { id: 38, name: 'BookOpen', label: 'Learning & Dev Lead', category: 'Human Resources', component: BookOpen },
  { id: 39, name: 'Wrench', label: 'Facilities Engineer', category: 'Technical', component: Wrench },
  { id: 40, name: 'GraduationCap', label: 'Training Officer', category: 'Human Resources', component: GraduationCap }
];

const iconCategories = ['All', 'Executive', 'Human Resources', 'Finance', 'Operations', 'Governance', 'Technical', 'Administration'];

const filteredIcons = computed(() => {
  return iconCatalogue.filter(item => {
    if (selectedIconCategory.value !== 'All' && item.category !== selectedIconCategory.value) {
      return false;
    }
    if (iconSearchQuery.value.trim()) {
      const q = iconSearchQuery.value.toLowerCase();
      return item.name.toLowerCase().includes(q) || item.label.toLowerCase().includes(q) || item.category.toLowerCase().includes(q);
    }
    return true;
  });
});

const selectedIconComponent = computed(() => {
  if (!form.value.icon_name) return null;
  const match = iconCatalogue.find(i => i.name === form.value.icon_name);
  return match ? match.component : null;
});

const selectIcon = (item: RoleIconItem) => {
  form.value.icon_id = item.id;
  form.value.icon_name = item.name;
  showIconPickerModal.value = false;
  showToast(`Selected icon: ${item.label}`);
};

const clearSelectedIcon = () => {
  form.value.icon_id = null;
  form.value.icon_name = null;
  showToast('Icon cleared.');
};

// ─── Toast Banner ───
const showToast = (msg: string) => {
  quickActionToast.value = msg;
  setTimeout(() => {
    quickActionToast.value = null;
  }, 3500);
};

// ─── Actions ───
const handleSave = () => {
  if (!form.value.name.trim()) {
    showToast('Please provide a Job Title Name.');
    return;
  }

  isSaved.value = true;
  showToast(`Job Title "${form.value.name.trim()}" created successfully.`);

  setTimeout(() => {
    router.push('/hr/job-titles');
  }, 1200);
};

const clearForm = () => {
  form.value = {
    name: '',
    category: 'non_management',
    entity_id: 3,
    status: 'acceptForAll',
    icon_id: null,
    icon_name: null,
    description: ''
  };
  isSaved.value = false;
  showToast('Form cleared.');
};

// ─── Mounted: Hydrate from Route Query if navigated from Quick Create ───
onMounted(() => {
  if (route.query.name) form.value.name = String(route.query.name);
  if (route.query.category) form.value.category = String(route.query.category);
  if (route.query.entity_id) form.value.entity_id = Number(route.query.entity_id);
});
</script>

<template>
  <div class="job-title-create-page">
    <!-- Top Action & Breadcrumb Navigation Bar (Exact Critic Standard) -->
    <div class="create-header-bar">
      <div class="header-left">
        <div class="breadcrumb-strip">
          <router-link to="/home" class="bc-home-icon" title="Home">
            <Monitor :size="15" />
          </router-link>
          <ChevronRight :size="13" class="bc-sep" />
          <router-link to="/hr/job-titles" class="bc-link">Job Titles &amp; Roles</router-link>
          <ChevronRight :size="13" class="bc-sep" />
          <span class="bc-current">Create Job Title</span>
          <SaveStateBadge :isSaved="isSaved" />
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

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- MASTER CARD: JOB TITLE FULL SPECIFICATIONS (Schema 1110–1131) -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div class="create-content-container">
      <div class="clean-card">
        <div class="section-title-box">
          <h2 class="section-title">Job Title &amp; Role Specifications</h2>
          <p class="section-subtitle">
            Establish standardized enterprise role nomenclature, functional categorization, governance approval scope, visual iconography, and operational scope.
          </p>
        </div>

        <!-- ─── THE ICON SECTION CARD (Exact Pixel-Aligned Match to User UI) ─── -->
        <div class="icon-selector-card">
          <div class="icon-card-left">
            <!-- Blank Squircle / Selected Icon Box -->
            <div class="icon-preview-box">
              <component 
                :is="selectedIconComponent" 
                v-if="selectedIconComponent" 
                :size="22" 
                class="selected-role-icon" 
              />
            </div>

            <!-- Title and Subtitle Text Block -->
            <div class="icon-card-meta">
              <span class="icon-card-title">Select an icon</span>
              <span class="icon-card-subtitle">Pick from your icon library</span>
            </div>
          </div>

          <!-- Right Action: Browse Button -->
          <div class="icon-card-actions">
            <button 
              v-if="form.icon_name" 
              type="button" 
              class="btn-remove-icon" 
              @click="clearSelectedIcon"
            >
              Remove
            </button>
            <button 
              type="button" 
              class="btn-browse-icon" 
              @click="showIconPickerModal = true"
            >
              Browse
            </button>
          </div>
        </div>

        <!-- ─── CORE ATTRIBUTES GRID (Rule 16: Zero Manual Code Input) ─── -->
        <div class="form-grid-2">
          <!-- Job Title Name: Schema localized name -->
          <FormInput
            label="Job Title Name"
            v-model="form.name"
            required
          />

          <!-- Position Category: Schema category_lookup_value_id -->
          <FormSelect
            label="Position Category"
            v-model="form.category"
            :options="categoryOptions"
            placeholder="Select Category"
            required
          />

          <!-- Owning Entity: Schema entity_id FK -->
          <FormSelect
            label="Owning Entity"
            v-model="form.entity_id"
            :options="entityOptions"
            placeholder="Select Entity"
            required
          />

          <!-- Governance Approval Scope: Schema status_lookup_value_id -->
          <FormSelect
            label="Governance Approval Scope"
            v-model="form.status"
            :options="statusOptions"
            placeholder="Select Scope"
            required
          />
        </div>

        <!-- ─── STRATEGIC JOB SUMMARY & SCOPE (Rule 18 Standard Rich Editor) ─── -->
        <div class="biography-section mt-5">
          <label class="gc-field-label">Role Purpose &amp; Operational Scope</label>

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
    <!-- ICON PICKER MODAL (Browse From Icon Library)                  -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-if="showIconPickerModal" class="icon-modal-backdrop" @click="showIconPickerModal = false">
      <div class="icon-modal-content" @click.stop>
        <div class="icon-modal-header">
          <div>
            <h3 class="icon-modal-title">Role Icon Library</h3>
            <p class="icon-modal-subtitle">Select a standard icon to visually represent this job title in directories and rosters.</p>
          </div>
          <button type="button" class="btn-modal-close" @click="showIconPickerModal = false">
            <X :size="16" />
          </button>
        </div>

        <!-- Search & Category Filters -->
        <div class="icon-modal-controls">
          <div class="icon-search-bar">
            <Search :size="14" class="icon-search-icon" />
            <input 
              type="text" 
              v-model="iconSearchQuery" 
              placeholder="Search icons (e.g. HR, cashier, manager, truck)..."
              class="icon-search-input" 
            />
          </div>

          <div class="icon-category-chips">
            <button 
              v-for="cat in iconCategories" 
              :key="cat"
              type="button" 
              class="icon-chip"
              :class="{ 'chip-active': selectedIconCategory === cat }"
              @click="selectedIconCategory = cat"
            >
              {{ cat }}
            </button>
          </div>
        </div>

        <!-- Icons Grid -->
        <div class="icon-grid-scroll">
          <div class="icon-grid">
            <button
              v-for="item in filteredIcons"
              :key="item.id"
              type="button"
              class="icon-grid-item"
              :class="{ 'icon-item-selected': form.icon_id === item.id }"
              @click="selectIcon(item)"
            >
              <div class="icon-box-inner">
                <component :is="item.component" :size="20" class="catalog-icon" />
              </div>
              <span class="icon-item-label">{{ item.label }}</span>
            </button>
          </div>

          <div v-if="filteredIcons.length === 0" class="icon-empty-state">
            <p>No icons found matching "{{ iconSearchQuery }}".</p>
          </div>
        </div>

        <div class="icon-modal-footer">
          <button type="button" class="btn-modal-cancel" @click="showIconPickerModal = false">
            Cancel
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.job-title-create-page {
  padding: 16px 24px 80px 24px;
  background-color: var(--primitive-color-neutral-50, #f8fafc);
  min-height: 100vh;
  box-sizing: border-box;
}

/* Header Bar */
.create-header-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
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

.bc-sep {
  color: #94a3b8;
}

.bc-link {
  color: #737373;
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
  padding: 2px 8px;
  border-radius: 9999px;
  font-size: 11px;
  font-weight: 500;
  margin-left: 8px;
}

.state-unsaved {
  background-color: #fef3c7;
  color: #92400e;
}

.state-saved {
  background-color: #ecfdf5;
  color: #065f46;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.btn-clear-action {
  display: flex;
  align-items: center;
  gap: 6px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 8px 14px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-clear-action:hover {
  background: #f8fafc;
  color: #dc2626;
  border-color: #fca5a5;
}

.btn-save-action {
  background: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  padding: 8px 20px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-save-action:hover {
  background: #09427d;
}

/* Quick Toast */
.quick-toast-banner {
  background: #ecfdf5;
  border: 1px solid #a7f3d0;
  color: #065f46;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 13.5px;
  margin-bottom: 16px;
}

/* Master Card */
.create-content-container {
  max-width: 1000px;
  margin: 0 auto;
}

.clean-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
}

.section-title-box {
  margin-bottom: 20px;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}

.section-subtitle {
  font-size: 13px;
  color: #737373;
  margin: 0;
}

/* ─── THE ICON SELECTOR CARD (Exact Match to User Image 2) ─── */
.icon-selector-card {
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 14px 20px;
  background: #ffffff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24px;
}

.icon-card-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.icon-preview-box {
  width: 46px;
  height: 46px;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  background: #f8fafc;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.selected-role-icon {
  color: #0B529C;
}

.icon-card-meta {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.icon-card-title {
  font-size: 15px;
  font-weight: 600;
  color: #1e293b;
  line-height: 1.2;
}

.icon-card-subtitle {
  font-size: 13px;
  color: #737373;
}

.icon-card-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.btn-browse-icon {
  background: transparent;
  border: none;
  font-size: 14px;
  font-weight: 500;
  color: #525252;
  cursor: pointer;
  padding: 6px 14px;
  border-radius: 6px;
  transition: all 0.15s ease;
}

.btn-browse-icon:hover {
  color: #0B529C;
  background: #f1f5f9;
}

.btn-remove-icon {
  background: transparent;
  border: none;
  font-size: 12.5px;
  font-weight: 500;
  color: #ef4444;
  cursor: pointer;
  padding: 6px 10px;
  border-radius: 6px;
}

.btn-remove-icon:hover {
  background: #fef2f2;
}

/* Form Grid */
.form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 18px 20px;
}

/* Strategic Rich Text Editor (Rule 18) */
.biography-section {
  margin-top: 24px;
}

.gc-field-label {
  display: block;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 6px;
}

.rich-editor-container {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  background: #ffffff;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.rich-editor-container:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.editor-toolbar {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
  flex-wrap: wrap;
}

.toolbar-dropdown {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #404040;
  padding: 4px 8px;
  border-radius: 4px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  cursor: pointer;
}

.toolbar-divider {
  width: 1px;
  height: 18px;
  background: #e2e8f0;
  margin: 0 4px;
}

.toolbar-icon-group {
  display: flex;
  align-items: center;
  gap: 2px;
}

.editor-icon-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  border: none;
  background: transparent;
  border-radius: 4px;
  color: #404040;
  font-size: 12px;
  cursor: pointer;
  transition: background 0.12s;
}

.editor-icon-btn:hover {
  background: #e2e8f0;
}

.editor-color-box {
  width: 18px;
  height: 18px;
  border-radius: 3px;
  background: #0B529C;
  border: 1px solid #e2e8f0;
  cursor: pointer;
  margin: 0 4px;
}

.editor-textarea {
  width: 100%;
  padding: 12px 14px;
  font-size: 13.5px;
  color: #404040;
  border: none;
  outline: none;
  resize: vertical;
  min-height: 120px;
  box-sizing: border-box;
  font-family: inherit;
  line-height: 1.5;
}

.editor-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 12px;
  border-top: 1px solid #f1f5f9;
  background: #fafafa;
}

.char-count-pill {
  font-size: 11.5px;
  color: #737373;
}

.editor-resize-handle {
  font-size: 11px;
  color: #94a3b8;
  user-select: none;
}

/* Icon Picker Modal */
.icon-modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.4);
  backdrop-filter: blur(2px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 999;
}

.icon-modal-content {
  background: #ffffff;
  border-radius: 12px;
  width: 580px;
  max-width: 90vw;
  max-height: 80vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  overflow: hidden;
}

.icon-modal-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 18px 20px;
  border-bottom: 1px solid #f1f5f9;
}

.icon-modal-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}

.icon-modal-subtitle {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

.btn-modal-close {
  background: transparent;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 4px;
  border-radius: 6px;
}

.btn-modal-close:hover {
  color: #404040;
  background: #f1f5f9;
}

.icon-modal-controls {
  padding: 14px 20px;
  border-bottom: 1px solid #f1f5f9;
  background: #fafafa;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.icon-search-bar {
  position: relative;
  display: flex;
  align-items: center;
}

.icon-search-icon {
  position: absolute;
  left: 10px;
  color: #94a3b8;
}

.icon-search-input {
  width: 100%;
  height: 36px;
  padding: 0 12px 0 32px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  outline: none;
  background: #ffffff;
}

.icon-search-input:focus {
  border-color: #0B529C;
}

.icon-category-chips {
  display: flex;
  gap: 6px;
  overflow-x: auto;
  padding-bottom: 2px;
}

.icon-chip {
  padding: 4px 10px;
  border-radius: 9999px;
  border: 1px solid #e2e8f0;
  background: #ffffff;
  font-size: 12px;
  color: #64748b;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.12s ease;
}

.icon-chip:hover {
  border-color: #cbd5e1;
  color: #334155;
}

.icon-chip.chip-active {
  background: #0B529C;
  color: #ffffff;
  border-color: #0B529C;
}

.icon-grid-scroll {
  padding: 16px 20px;
  overflow-y: auto;
  max-height: 360px;
}

.icon-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}

.icon-grid-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 12px 8px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  background: #ffffff;
  cursor: pointer;
  transition: all 0.15s ease;
}

.icon-grid-item:hover {
  border-color: #0B529C;
  background: #f0f7ff;
}

.icon-grid-item.icon-item-selected {
  border-color: #0B529C;
  background: #f0f7ff;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.15);
}

.icon-box-inner {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  background: #f8fafc;
  display: flex;
  align-items: center;
  justify-content: center;
}

.catalog-icon {
  color: #0B529C;
}

.icon-item-label {
  font-size: 11.5px;
  color: #404040;
  text-align: center;
  font-weight: 500;
  line-height: 1.2;
}

.icon-empty-state {
  padding: 32px 16px;
  text-align: center;
  color: #94a3b8;
  font-size: 13px;
}

.icon-modal-footer {
  display: flex;
  justify-content: flex-end;
  padding: 12px 20px;
  border-top: 1px solid #f1f5f9;
  background: #fafafa;
}

.btn-modal-cancel {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 6px 14px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
}

.btn-modal-cancel:hover {
  background: #f8fafc;
}
</style>
