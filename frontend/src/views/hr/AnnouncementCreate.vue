<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  MoreVertical, X, FileText, Users,
  Building2, Briefcase, Plus, Trash2,
  Table, AlertCircle
} from 'lucide-vue-next';;

import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormRichText from '../../components/FormRichText.vue';

import {
  announcementsData,
  createAnnouncement,
  updateAnnouncement,
  type AnnouncementRecord,
  type AnnouncementTarget,
  type AnnouncementAudience,
  type AnnouncementState
} from './announcementData';

const router = useRouter();
const route = useRoute();

// ─── EDIT MODE DETECTION ──────────────────────────────────────────────────
const editId = computed(() => {
  if (route.params.id) return Number(route.params.id);
  if (route.query.id) return Number(route.query.id);
  return null;
});

const isEditMode = computed(() => editId.value !== null);

// ─── BREADCRUMBS (Rule 3 & 4: Exact Sidebar Page Name > Sub-page) ─────────
const breadcrumbItems = computed(() => [
  { label: 'Announcements', to: '/hr/announcements' },
  { label: isEditMode.value ? 'Edit Announcement' : 'Create Announcement' }
]);

// ─── SAVE / DRAFT STATE (Rule 30) ─────────────────────────────────────────
const isSaved = ref(false);
const isDraft = ref(false);
const showDraftMenu = ref(false);
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => {
    toastMessage.value = null;
  }, 3200);
};

// ─── TOP TABS (Rule 1: BaseTabs) ──────────────────────────────────────────
type CreationTab = 'details' | 'targeting';
const activeTab = ref<CreationTab>('details');

const creationTabs: BaseTabItem<CreationTab>[] = [
  { id: 'details', label: '1. Notice Details & Content' },
  { id: 'targeting', label: '2. Audience Target Lines (AnnouncementTarget)' }
];

// ─── FORM DATA MODEL (Strict 1:1 Schema Alignment) ────────────────────────
const formData = ref<{
  title: string;
  audience: AnnouncementAudience;
  publish_from: string;
  publish_to: string;
  requires_acknowledgment: boolean;
  acknowledgment_deadline: string;
  body: string;
  entity_id: number;
  published_by_employee_id: number | null;
}>({
  title: '',
  audience: 'all',
  publish_from: new Date().toISOString().slice(0, 16),
  publish_to: '',
  requires_acknowledgment: false,
  acknowledgment_deadline: '',
  body: '<p>Dear Colleagues,</p><p>Please be advised of the following official announcement regarding our operations.</p>',
  entity_id: 1,
  published_by_employee_id: 14
});

// ─── CHILD LINES: AnnouncementTarget [LINE] (Schema lines 3703-3720) ──────
const targetLines = ref<AnnouncementTarget[]>([]);

// Pre-defined options for target picker modal / inline rows
const unitCatalog = [
  { id: 2, name: 'Finance & Accounting Division', reach: 18 },
  { id: 5, name: 'Retail Operations & Customer Care', reach: 45 },
  { id: 8, name: 'Human Resources & People Operations', reach: 12 },
  { id: 12, name: 'Information Technology & Systems', reach: 15 },
  { id: 16, name: 'Supply Chain & Inventory Logistics', reach: 28 },
  { id: 1, name: 'Executive Directorate', reach: 6 }
];

const positionCatalog = [
  { id: 24, name: 'Frontline Cashier & POS Operator', reach: 24 },
  { id: 18, name: 'Senior Store Manager', reach: 8 },
  { id: 22, name: 'Senior Financial Analyst', reach: 4 },
  { id: 31, name: 'Talent Acquisition Partner', reach: 3 },
  { id: 15, name: 'Network Infrastructure Lead', reach: 2 }
];

const gradeCatalog = [
  { id: 8, name: 'Job Grade VIII (Professional II)', reach: 32 },
  { id: 9, name: 'Job Grade IX (Senior Professional)', reach: 20 },
  { id: 10, name: 'Job Grade X (Managerial)', reach: 14 },
  { id: 12, name: 'Executive Level (Director & VP)', reach: 6 }
];

const employeeCatalog = [
  { id: 22, name: 'Hana Mesfin Tadesse', code: 'EMP-0022', dept: 'Finance & Accounts' },
  { id: 14, name: 'Solomon Bekele Worku', code: 'EMP-0014', dept: 'HR & People' },
  { id: 31, name: 'Helen Berhanu Haile', code: 'EMP-0031', dept: 'HR & People' },
  { id: 124, name: 'Almaz Kebede Desta', code: 'EMP-00124', dept: 'Finance & Accounts' },
  { id: 12, name: 'Abebe Kebede Wolde', code: 'EMP-0012', dept: 'Retail Operations' },
  { id: 44, name: 'Dawit Tadesse Mengistu', code: 'EMP-0044', dept: 'Internal Audit' }
];

// Target line creation helper
const handleAddTargetLine = (
  type: 'organization_unit' | 'job_grade' | 'job_position' | 'employee'
) => {
  const newId = targetLines.value.length > 0
    ? Math.max(...targetLines.value.map(t => t.id)) + 1
    : 1;

  if (type === 'organization_unit') {
    const unit = unitCatalog[0];
    targetLines.value.push({
      id: newId,
      announcement_id: editId.value || 0,
      target_type: 'organization_unit',
      organization_unit_id: unit.id,
      unit_name: unit.name,
      state: 'active'
    });
  } else if (type === 'job_position') {
    const pos = positionCatalog[0];
    targetLines.value.push({
      id: newId,
      announcement_id: editId.value || 0,
      target_type: 'job_position',
      job_position_id: pos.id,
      position_name: pos.name,
      state: 'active'
    });
  } else if (type === 'job_grade') {
    const grade = gradeCatalog[0];
    targetLines.value.push({
      id: newId,
      announcement_id: editId.value || 0,
      target_type: 'job_grade',
      job_grade_id: grade.id,
      grade_name: grade.name,
      state: 'active'
    });
  } else if (type === 'employee') {
    const emp = employeeCatalog[0];
    targetLines.value.push({
      id: newId,
      announcement_id: editId.value || 0,
      target_type: 'employee',
      employee_id: emp.id,
      employee_name: emp.name,
      employee_code: emp.code,
      state: 'active'
    });
  }
};

const handleRemoveTargetLine = (index: number) => {
  targetLines.value.splice(index, 1);
};

// Target entity selector change handler
const handleTargetEntityChange = (line: AnnouncementTarget, targetIdVal: string | number) => {
  const numId = Number(targetIdVal);
  if (line.target_type === 'organization_unit') {
    const found = unitCatalog.find(u => u.id === numId);
    if (found) {
      line.organization_unit_id = found.id;
      line.unit_name = found.name;
    }
  } else if (line.target_type === 'job_position') {
    const found = positionCatalog.find(p => p.id === numId);
    if (found) {
      line.job_position_id = found.id;
      line.position_name = found.name;
    }
  } else if (line.target_type === 'job_grade') {
    const found = gradeCatalog.find(g => g.id === numId);
    if (found) {
      line.job_grade_id = found.id;
      line.grade_name = found.name;
    }
  } else if (line.target_type === 'employee') {
    const found = employeeCatalog.find(e => e.id === numId);
    if (found) {
      line.employee_id = found.id;
      line.employee_name = found.name;
      line.employee_code = found.code;
    }
  }
};

// Compute target summary for directory listing
const computedTargetSummary = computed(() => {
  if (formData.value.audience === 'all') return 'All Employees (Company-Wide)';
  if (targetLines.value.length === 0) return 'Custom Targeted Groups';
  const names = targetLines.value.map(t => {
    if (t.target_type === 'organization_unit') return t.unit_name || 'Unit';
    if (t.target_type === 'job_position') return t.position_name || 'Position';
    if (t.target_type === 'job_grade') return t.grade_name || 'Grade';
    return t.employee_name || 'Employee';
  });
  return names.slice(0, 2).join(', ') + (names.length > 2 ? ` (+${names.length - 2} more)` : '');
});

// Owning Entity options (entity_id)
const entityOptions = [
  { value: 1, label: 'Haleta Corporate Headquarters' },
  { value: 3, label: 'Haleta Addis Ababa Branch' }
];

// Published By options (published_by_employee_id -- FK Employee)
const publishedByOptions = [
  { value: 14, label: 'Solomon Bekele Worku (Director of Human Resources)' },
  { value: 22, label: 'Hana Mesfin Tadesse (Finance Manager)' },
  { value: 12, label: 'Abebe Kebede Wolde (Head of Retail Operations)' }
];

// Character counter for body
const bodyCharCount = computed(() => {
  const tmp = document.createElement('div');
  tmp.innerHTML = formData.value.body;
  return (tmp.textContent || tmp.innerText || '').length;
});

// Rich formatting toolbar helpers
const insertFormat = (tag: string) => {
  if (tag === 'b') formData.value.body += '<strong>Bold Text</strong> ';
  if (tag === 'i') formData.value.body += '<em>Italic Text</em> ';
  if (tag === 'ul') formData.value.body += '<ul><li>Action item 1</li><li>Action item 2</li></ul> ';
  if (tag === 'quote') formData.value.body += '<blockquote>Important statutory note...</blockquote> ';
};

// Pre-fill when editing
onMounted(() => {
  if (isEditMode.value && editId.value) {
    const item = announcementsData.value.find(a => a.id === editId.value);
    if (item) {
      formData.value.title = item.title;
      formData.value.audience = item.audience;
      formData.value.publish_from = item.publish_from.slice(0, 16);
      formData.value.publish_to = item.publish_to ? item.publish_to.slice(0, 16) : '';
      formData.value.requires_acknowledgment = item.requires_acknowledgment;
      formData.value.acknowledgment_deadline = item.acknowledgment_deadline || '';
      formData.value.body = item.body;
      formData.value.entity_id = item.entity_id;
      formData.value.published_by_employee_id = item.published_by_employee_id;
      targetLines.value = item.targets ? JSON.parse(JSON.stringify(item.targets)) : [];
      isSaved.value = true;
      isDraft.value = item.announcement_state === 'draft';
      return;
    }
  }
});

// Clear Form action (Rule 4 & 31)
const handleClearForm = () => {
  formData.value = {
    title: '',
    audience: 'all',
    publish_from: new Date().toISOString().slice(0, 16),
    publish_to: '',
    requires_acknowledgment: false,
    acknowledgment_deadline: '',
    body: '<p>Dear Colleagues,</p>',
    entity_id: 1,
    published_by_employee_id: 14
  };
  targetLines.value = [];
  isSaved.value = false;
  isDraft.value = false;
  showToast('Form cleared.');
};

// Save record (Draft or Published)
const saveRecord = (stateToSet: AnnouncementState) => {
  if (!formData.value.title.trim()) {
    showToast('Please enter an announcement title.');
    return;
  }

  if (formData.value.audience !== 'all' && targetLines.value.length === 0) {
    showToast('Please add at least one audience target line, or set scope to All Staff.');
    return;
  }

  const selectedPublisher = publishedByOptions.find(p => p.value === formData.value.published_by_employee_id);

  if (isEditMode.value && editId.value) {
    updateAnnouncement(editId.value, {
      title: formData.value.title,
      audience: formData.value.audience,
      target_summary: computedTargetSummary.value,
      targets: formData.value.audience === 'all' ? [] : [...targetLines.value],
      publish_from: formData.value.publish_from ? new Date(formData.value.publish_from).toISOString() : new Date().toISOString(),
      publish_to: formData.value.publish_to ? new Date(formData.value.publish_to).toISOString() : null,
      requires_acknowledgment: formData.value.requires_acknowledgment,
      acknowledgment_deadline: formData.value.requires_acknowledgment ? formData.value.acknowledgment_deadline : null,
      announcement_state: stateToSet,
      published_by_employee_id: formData.value.published_by_employee_id,
      published_by_name: selectedPublisher ? selectedPublisher.label.split(' (')[0] : null,
      body: formData.value.body
    });
    isSaved.value = true;
    isDraft.value = stateToSet === 'draft';
    showToast(`Announcement updated successfully (${stateToSet}).`);
  } else {
    const newRec = createAnnouncement({
      tenant_id: 1,
      entity_id: formData.value.entity_id,
      entity_name: formData.value.entity_id === 3 ? 'Haleta Addis Ababa Branch' : 'Haleta Corporate Headquarters',
      title: formData.value.title,
      body: formData.value.body,
      audience: formData.value.audience,
      target_summary: computedTargetSummary.value,
      targets: formData.value.audience === 'all' ? [] : [...targetLines.value],
      publish_from: formData.value.publish_from ? new Date(formData.value.publish_from).toISOString() : new Date().toISOString(),
      publish_to: formData.value.publish_to ? new Date(formData.value.publish_to).toISOString() : null,
      requires_acknowledgment: formData.value.requires_acknowledgment,
      acknowledgment_deadline: formData.value.requires_acknowledgment ? formData.value.acknowledgment_deadline : null,
      announcement_state: stateToSet,
      published_by_employee_id: formData.value.published_by_employee_id,
      published_by_name: selectedPublisher ? selectedPublisher.label.split(' (')[0] : null,
      published_by_role: 'Director of Human Resources',
      user_id: 7,
      state: 'active'
    });
    isSaved.value = true;
    isDraft.value = stateToSet === 'draft';
    showToast(`Announcement ${newRec.code} created (${stateToSet}).`);
  }

  showDraftMenu.value = false;
  setTimeout(() => {
    router.push('/hr/announcements');
  }, 1000);
};
</script>

<template>
  <div class="announcement-create-page">
    <!-- Toast message alert -->
    <div v-if="toastMessage" class="toast-alert">
      {{ toastMessage }}
    </div>

    <!-- Top Action Bar (AGENTS.md Rule 4 & 29: Zero-background, transparent) -->
    <div class="top-nav-bar">
      <div class="top-nav-left">
        <AppBreadcrumb :items="breadcrumbItems" noMargin>
          <template #badge>
            <SaveStateBadge :isSaved="isSaved" :isDraft="isDraft" />
          </template>
        </AppBreadcrumb>
      </div>

      <div class="top-nav-right">
        <!-- 3-Dots More Menu for Draft State (AGENTS.md Rule 4 & 59) -->
        <div class="draft-menu-container">
          <AppButton
            variant="outline"
            size="sm"
            iconOnly
            title="Additional actions"
            @click="showDraftMenu = !showDraftMenu"
          >
            <MoreVertical :size="16" />
          </AppButton>
          <div v-if="showDraftMenu" class="draft-dropdown-menu">
            <button type="button" class="dropdown-item" @click="saveRecord('draft')">
              Save as Draft
            </button>
          </div>
        </div>

        <!-- Secondary Clear Form Button (AGENTS.md Rule 4 & 31) -->
        <AppButton
          variant="outline"
          size="sm"
          @click="handleClearForm"
        >
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>

        <!-- Primary Save Button (Rule 4, 27: Plain text "Save", ZERO icons) -->
        <AppButton
          variant="primary"
          size="sm"
          @click="saveRecord('published')"
        >
          Save
        </AppButton>
      </div>
    </div>

    <!-- Top Tabs (AGENTS.md Rule 1: BaseTabs Capsule) -->
    <div class="top-tabs-bar">
      <BaseTabs
        v-model="activeTab"
        :tabs="creationTabs"
      />
    </div>

    <!-- Full-Width Document Workspace (No squeezed columns, no redundant preview) -->
    <div class="document-container">
      <!-- ─── TAB 1: NOTICE DETAILS & CONTENT ───────────────────────────── -->
      <div v-show="activeTab === 'details'" class="tab-pane-content">
        <!-- Card 1: Header & Scheduling -->
        <div class="clean-card">
          <h3 class="card-title">Notice Header & Schedule</h3>
          <p class="section-help-text">
            Specify the official announcement title, owning branch entity, and publication schedule.
          </p>

          <FormInput
            v-model="formData.title"
            label="Notice Title *"
            required
          />

          <div class="form-grid-2">
            <FormSelect
              v-model="formData.entity_id"
              label="Owning Entity *"
              :options="entityOptions"
            />
            <FormSelect
              v-model="formData.published_by_employee_id"
              label="Published By (Employee)"
              :options="publishedByOptions"
            />
          </div>

          <div class="form-grid-2">
            <FormInput
              v-model="formData.publish_from"
              label="Publish From Date & Time *"
              type="datetime-local"
            />
            <FormInput
              v-model="formData.publish_to"
              label="Publish Until (Optional Expiry)"
              type="datetime-local"
            />
          </div>

          <div class="ack-section-divider"></div>

          <!-- Statutory Compliance Acknowledgment (Schema lines 2177-2178) -->
          <div class="ack-checkbox-wrap">
            <FormCheckbox
              v-model="formData.requires_acknowledgment"
              label="Mandatory Employee Acknowledgment"
              description="Requires targeted staff to formally confirm receipt and understanding of this notice. Generates timestamped compliance audit proofs in AnnouncementAcknowledgment [LINE]."
            />
          </div>

          <div v-if="formData.requires_acknowledgment" class="deadline-input-container">
            <FormInput
              v-model="formData.acknowledgment_deadline"
              label="Statutory Compliance Deadline *"
              type="date"
            />
          </div>
        </div>

        <!-- Card 2: Announcement Body & Content (Figma Node 8779:68714 Rich Text Component) -->
        <div class="clean-card">
          <FormRichText
            v-model="formData.body"
            label="Announcement Body Content"
            help-text="Author the formal circular, policy directive, or operational memo with rich text formatting."
            required
            :max-length="5000"
          />
        </div>
      </div>

      <!-- ─── TAB 2: AUDIENCE TARGET LINES (AnnouncementTarget [LINE]) ──── -->
      <div v-show="activeTab === 'targeting'" class="tab-pane-content">
        <div class="clean-card">
          <h3 class="card-title">Audience Scope & Distribution</h3>
          <p class="section-help-text">
            Choose whether this notice broadcasts to the entire company or is targeted to specific units, positions, grades, or employees.
          </p>

          <!-- Audience Scope Selector -->
          <div class="audience-scope-selector">
            <label class="scope-radio-option" :class="{ selected: formData.audience === 'all' }">
              <input
                type="radio"
                name="audience_scope"
                value="all"
                :checked="formData.audience === 'all'"
                @change="formData.audience = 'all'"
              />
              <div class="radio-content">
                <span class="radio-title">All Employees (Company-Wide Broadcast)</span>
                <span class="radio-desc">Delivers notice to every active staff member across all operating entities and units.</span>
              </div>
            </label>

            <label class="scope-radio-option" :class="{ selected: formData.audience !== 'all' }">
              <input
                type="radio"
                name="audience_scope"
                value="organization_unit"
                :checked="formData.audience !== 'all'"
                @change="formData.audience = 'organization_unit'"
              />
              <div class="radio-content">
                <span class="radio-title">Targeted Groups (AnnouncementTarget [LINE])</span>
                <span class="radio-desc">Target specific organization units, job positions, job grades, or individual staff members.</span>
              </div>
            </label>
          </div>

          <!-- All Employees Banner -->
          <div v-if="formData.audience === 'all'" class="all-staff-banner">
            <Users :size="20" class="banner-icon" />
            <div>
              <span class="banner-title">Broadcasting to All Staff Members</span>
              <p class="banner-desc">
                In accordance with database schema rules, an audience = <code>all</code> announcement has no child target line rows. Every active staff member will see this notice.
              </p>
            </div>
          </div>

          <!-- Dynamic Child Sub-Table (AGENTS.md Rule 11: Mandatory Default Pattern for 1:N Lines) -->
          <div v-else class="child-target-table-wrap">
            <div class="table-section-header">
              <div>
                <h4 class="subtable-title">Audience Target Lines</h4>
                <p class="subtable-desc">
                  Schema Entity: <code>AnnouncementTarget [LINE]</code> — Define each recipient unit, grade, position, or employee row.
                </p>
              </div>

              <!-- Quick Line Adder Buttons -->
              <div class="add-line-buttons-group">
                <button
                  type="button"
                  class="btn-add-line-chip"
                  @click="handleAddTargetLine('organization_unit')"
                >
                  <Plus :size="13" />
                  <span>+ Add Organization Unit</span>
                </button>
                <button
                  type="button"
                  class="btn-add-line-chip"
                  @click="handleAddTargetLine('job_position')"
                >
                  <Plus :size="13" />
                  <span>+ Add Job Position</span>
                </button>
                <button
                  type="button"
                  class="btn-add-line-chip"
                  @click="handleAddTargetLine('job_grade')"
                >
                  <Plus :size="13" />
                  <span>+ Add Job Grade</span>
                </button>
                <button
                  type="button"
                  class="btn-add-line-chip"
                  @click="handleAddTargetLine('employee')"
                >
                  <Plus :size="13" />
                  <span>+ Add Employee</span>
                </button>
              </div>
            </div>

            <!-- The Child Lines Data Table (Rules 8, 11) -->
            <table class="erp-table child-lines-table">
              <thead>
                <tr>
                  <th class="th-no">#</th>
                  <th>Target Type</th>
                  <th>Targeted Entity / Recipient Scope</th>
                  <th>Estimated Reach</th>
                  <th>Line State</th>
                  <th class="th-action-col"></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(line, idx) in targetLines" :key="line.id" class="child-table-row">
                  <!-- Row Numbering (Rule 11) -->
                  <td class="td-no">{{ idx + 1 }}</td>

                  <!-- Target Type Column -->
                  <td class="td-type">
                    <span class="target-type-badge" :class="`badge-${line.target_type}`">
                      <component
                        :is="
                          line.target_type === 'organization_unit'
                            ? Building2
                            : line.target_type === 'job_position'
                            ? Briefcase
                            : line.target_type === 'job_grade'
                            ? FileText
                            : Users
                        "
                        :size="12"
                      />
                      <span>
                        {{
                          line.target_type === 'organization_unit'
                            ? 'Organization Unit'
                            : line.target_type === 'job_position'
                            ? 'Job Position'
                            : line.target_type === 'job_grade'
                            ? 'Job Grade'
                            : 'Specific Employee'
                        }}
                      </span>
                    </span>
                  </td>

                  <!-- Target Entity / Value Selector -->
                  <td class="td-entity">
                    <!-- Unit Selector -->
                    <select
                      v-if="line.target_type === 'organization_unit'"
                      :value="line.organization_unit_id"
                      class="table-inline-select"
                      @change="handleTargetEntityChange(line, ($event.target as HTMLSelectElement).value)"
                    >
                      <option v-for="u in unitCatalog" :key="u.id" :value="u.id">
                        {{ u.name }}
                      </option>
                    </select>

                    <!-- Position Selector -->
                    <select
                      v-else-if="line.target_type === 'job_position'"
                      :value="line.job_position_id"
                      class="table-inline-select"
                      @change="handleTargetEntityChange(line, ($event.target as HTMLSelectElement).value)"
                    >
                      <option v-for="p in positionCatalog" :key="p.id" :value="p.id">
                        {{ p.name }}
                      </option>
                    </select>

                    <!-- Grade Selector -->
                    <select
                      v-else-if="line.target_type === 'job_grade'"
                      :value="line.job_grade_id"
                      class="table-inline-select"
                      @change="handleTargetEntityChange(line, ($event.target as HTMLSelectElement).value)"
                    >
                      <option v-for="g in gradeCatalog" :key="g.id" :value="g.id">
                        {{ g.name }}
                      </option>
                    </select>

                    <!-- Employee Selector -->
                    <select
                      v-else-if="line.target_type === 'employee'"
                      :value="line.employee_id"
                      class="table-inline-select"
                      @change="handleTargetEntityChange(line, ($event.target as HTMLSelectElement).value)"
                    >
                      <option v-for="e in employeeCatalog" :key="e.id" :value="e.id">
                        {{ e.name }} ({{ e.code }}) • {{ e.dept }}
                      </option>
                    </select>
                  </td>

                  <!-- Estimated Reach Column (Tertiary text, Rule 5 & 6) -->
                  <td class="td-reach">
                    <span class="tertiary-text">
                      {{
                        line.target_type === 'organization_unit'
                          ? (unitCatalog.find(u => u.id === line.organization_unit_id)?.reach || 18) + ' Staff'
                          : line.target_type === 'job_position'
                          ? (positionCatalog.find(p => p.id === line.job_position_id)?.reach || 12) + ' Staff'
                          : line.target_type === 'job_grade'
                          ? (gradeCatalog.find(g => g.id === line.job_grade_id)?.reach || 20) + ' Staff'
                          : '1 Employee'
                      }}
                    </span>
                  </td>

                  <!-- Line State Column -->
                  <td class="td-state">
                    <span class="state-pill state-active">Active</span>
                  </td>

                  <!-- Delete Action Column -->
                  <td class="td-actions">
                    <button
                      type="button"
                      class="btn-delete-line"
                      title="Remove target line"
                      @click="handleRemoveTargetLine(idx)"
                    >
                      <Trash2 :size="14" />
                    </button>
                  </td>
                </tr>

                <!-- Empty State for Target Lines -->
                <tr v-if="targetLines.length === 0">
                  <td colspan="6" class="td-empty-lines">
                    <div class="empty-lines-box">
                      <AlertCircle :size="24" class="empty-icon" />
                      <p class="empty-lines-title">No target audience lines added</p>
                      <p class="empty-lines-desc">
                        Click the buttons above to target specific units, positions, grades, or staff members.
                      </p>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.announcement-create-page {
  padding: 0;
  background-color: #f8fafc;
  min-height: 100vh;
}

.toast-alert {
  position: fixed;
  top: 24px;
  right: 32px;
  z-index: 1000;
  background-color: #0b529c;
  color: #ffffff;
  padding: 10px 18px;
  border-radius: 8px;
  font-size: 13.5px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

/* ─── TOP ACTION BAR (AGENTS.md Rule 4 & 29) ────────────────────────────── */
.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 0;
}

.top-nav-left {
  display: flex;
  align-items: center;
  gap: 14px;
}

.top-nav-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.draft-menu-container {
  position: relative;
}

.btn-icon-more {
  width: 38px;
  height: 38px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 8px; /* Rule 6: 8-10px */
  color: #404040;
  cursor: pointer;
}

.btn-icon-more:hover {
  background-color: #f1f5f9;
}

.draft-dropdown-menu {
  position: absolute;
  top: 100%;
  left: 0;
  margin-top: 4px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  min-width: 140px;
  padding: 4px;
  z-index: 50;
}

.dropdown-item {
  width: 100%;
  padding: 8px 12px;
  font-size: 13px;
  color: #404040;
  background: transparent;
  border: none;
  border-radius: 6px;
  text-align: left;
  cursor: pointer;
}

.dropdown-item:hover {
  background-color: #f8fafc;
  color: #0b529c;
}

.btn-secondary-nav {
  height: 38px;
  padding: 0 16px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 8px; /* Rule 6: 8-10px */
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
}

.btn-secondary-nav:hover {
  background-color: #f1f5f9;
}

.btn-primary-save {
  height: 38px;
  padding: 0 22px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background-color: #0b529c;
  border: none;
  border-radius: 8px; /* Rule 6: 8-10px well-rounded rectangle */
  font-size: 13.5px;
  font-weight: 500;
  color: #ffffff;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-primary-save:hover {
  background-color: #09427d;
}

/* ─── TOP TABS (Rule 1: BaseTabs) ───────────────────────────────────────── */
.top-tabs-bar {
  margin-bottom: 24px;
}

/* ─── FULL-WIDTH DOCUMENT WORKSPACE ─────────────────────────────────────── */
.document-container {
  width: 100%;
  max-width: 1100px;
  margin: 0 auto;
}

.tab-pane-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.clean-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 24px 28px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040; /* Rule 7: Primary Dark */
  margin: 0;
}

.card-title-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.section-help-text {
  font-size: 12.5px;
  color: #737373; /* Rule 5: Tertiary Color */
  margin: -4px 0 0;
  line-height: 1.45;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

.form-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

@media (max-width: 840px) {
  .form-grid-3,
  .form-grid-2 {
    grid-template-columns: 1fr;
  }
}

/* ─── STANDARDIZED WYSIWYG RICH TEXT EDITOR (Rules 18 & 25) ──────────────── */
.wysiwyg-box {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.wysiwyg-toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  background-color: #ffffff;
  border-bottom: 1px solid #e2e8f0;
  flex-wrap: wrap;
}

.tb-dropdown-btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #404040;
  padding: 4px 6px;
  border-radius: 4px;
  cursor: pointer;
}

.tb-dropdown-btn:hover {
  background-color: #f1f5f9;
}

.tb-divider {
  width: 1px;
  height: 16px;
  background-color: #e2e8f0;
  margin: 0 4px;
}

.tb-icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  border: none;
  background: transparent;
  color: #64748b;
  border-radius: 4px;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.1s;
}

.tb-icon-btn:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.tb-spacer {
  flex: 1;
}

.wysiwyg-textarea {
  width: 100%;
  min-height: 180px;
  padding: 12px 16px;
  border: none;
  outline: none;
  font-size: 13.5px;
  color: #404040;
  line-height: 1.6;
  resize: vertical;
  background-color: #ffffff;
  font-family: inherit;
}

.wysiwyg-textarea:focus {
  background-color: #ffffff;
}

.wysiwyg-footer {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding: 6px 14px;
  background-color: #fafafa;
  border-top: 1px solid #f1f5f9;
}

.char-count-text {
  font-size: 11.5px;
  color: #94a3b8;
}

/* ─── AUDIENCE SCOPE RADIO SELECTOR ─────────────────────────────────────── */
.audience-scope-selector {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
  margin-top: 4px;
}

.scope-radio-option {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 16px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  background-color: #ffffff;
  cursor: pointer;
  transition: all 0.15s ease;
}

.scope-radio-option:hover {
  background-color: #f8fafc;
}

.scope-radio-option.selected {
  border-color: #0b529c;
  background-color: #f0f7ff;
}

.scope-radio-option input[type="radio"] {
  margin-top: 3px;
  accent-color: #0b529c;
}

.radio-content {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.radio-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.radio-desc {
  font-size: 12px;
  color: #737373;
  line-height: 1.4;
}

.all-staff-banner {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px 20px;
  background-color: #f0f9ff;
  border: 1px solid #bae6fd;
  border-radius: 10px;
  margin-top: 10px;
}

.banner-icon {
  color: #0284c7;
  flex-shrink: 0;
}

.banner-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #0369a1;
}

.banner-desc {
  font-size: 12px;
  color: #0284c7;
  margin: 2px 0 0;
}

/* ─── DYNAMIC CHILD SUB-TABLE: AnnouncementTarget [LINE] (Rule 11) ──────── */
.child-target-table-wrap {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 10px;
}

.table-section-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
}

.subtable-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.subtable-desc {
  font-size: 12px;
  color: #737373;
  margin: 2px 0 0;
}

.add-line-buttons-group {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.btn-add-line-chip {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background-color: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 8px; /* Rule 6: 8-10px */
  font-size: 12px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-add-line-chip:hover {
  background-color: #f1f5f9;
  border-color: #94a3b8;
  color: #0b529c;
}

/* Child Lines Table (Rule 8, 11) */
.erp-table {
  width: 100%;
  border-collapse: collapse;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
}

.erp-table th {
  height: 34px;
  padding: 6px 14px;
  background-color: #fafafa;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

.erp-table td {
  height: 44px;
  padding: 6px 14px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.th-no,
.td-no {
  width: 40px;
  text-align: center;
  color: #94a3b8 !important;
  font-size: 12px;
}

.target-type-badge {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: 11.5px;
  font-weight: 500;
  padding: 3px 8px;
  border-radius: 6px;
}

.badge-organization_unit {
  background-color: #f0fdf4;
  color: #16a34a;
}

.badge-job_position {
  background-color: #f0f9ff;
  color: #0284c7;
}

.badge-job_grade {
  background-color: #fefce8;
  color: #ca8a04;
}

.badge-employee {
  background-color: #fdf2f8;
  color: #db2777;
}

.table-inline-select {
  height: 34px;
  padding: 0 10px;
  font-size: 13px;
  color: #404040;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  background-color: #ffffff;
  outline: none;
  width: 100%;
  max-width: 380px;
}

.table-inline-select:focus {
  border-color: #0b529c;
}

.tertiary-text {
  color: #737373; /* Rule 5 */
  font-size: 12.5px;
}

.state-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: 9999px;
  font-size: 11px;
  font-weight: 500;
}

.state-active {
  background-color: #ecfdf5;
  color: #059669;
}

.th-action-col,
.td-actions {
  width: 44px;
  text-align: center;
}

.btn-delete-line {
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 6px;
  color: #94a3b8;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-delete-line:hover {
  background-color: #fee2e2;
  color: #dc2626;
}

.td-empty-lines {
  padding: 32px 0 !important;
  text-align: center;
}

.empty-lines-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.empty-icon {
  color: #94a3b8;
}

.empty-lines-title {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
  margin: 0;
}

.empty-lines-desc {
  font-size: 12px;
  color: #737373;
  margin: 0;
}

.ack-section-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 6px 0;
}

.ack-checkbox-wrap {
  padding-top: 4px;
}

.deadline-input-container {
  max-width: 320px;
  margin-top: 4px;
}
</style>
