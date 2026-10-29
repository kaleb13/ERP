<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  FileText, Plus, Eye, CheckCircle2, XCircle, Clock,
  Calendar, ShieldCheck, ArrowRight, ShieldAlert,
  AlertTriangle, Filter, MoreVertical, Maximize2,
  Printer, Download, Send, Building2, User, Check, X,
  Sparkles, SlidersHorizontal, RefreshCw, Briefcase,
  ChevronDown, ChevronRight, ExternalLink, ArrowUpDown,
  Columns, ArrowUpRight
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import MetricCard from '../../components/MetricCard.vue';
import UnderlineTabs, { type UnderlineTabItem } from '../../components/UnderlineTabs.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormInput from '../../components/FormInput.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import {
  employeeLettersData,
  letterTemplatesData,
  LETTER_TYPE_MAP,
  LETTER_STATE_MAP,
  LETTER_DIRECTION_MAP,
  addEmployeeLetter,
  updateLetterStatus,
  renderTemplatePreview,
  type LetterType,
  type LetterState,
  type LetterDirection,
  type EmployeeLetterRecord
} from './letterData';

const router = useRouter();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3) ───
// Exact Sidebar Page Name Only: [Monitor] > Employee Letters
const breadcrumbItems = [
  { label: 'Employee Letters' }
];

// ─── Active Tab Filter (UnderlineTabs Standard AGENTS.md Rule 1) ───
type LetterTabKey = 'all' | 'pending_approval' | 'approved' | 'issued' | 'revoked' | 'draft';
const activeTab = ref<LetterTabKey>('all');

const searchQuery = ref('');
const selectedTypeFilter = ref<string>('all');
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Metric Cards Computed (Matches Figma 7454:138268 exactly) ───
const metrics = computed(() => {
  const total = employeeLettersData.value.length;
  const pending = employeeLettersData.value.filter(l => l.letter_state === 'pending_approval').length;
  const issued = employeeLettersData.value.filter(l => l.letter_state === 'issued').length;
  const separationReminders = employeeLettersData.value.filter(l => l.remind_on_separation && l.letter_state === 'issued').length;

  return {
    total,
    pending,
    issued,
    separationReminders
  };
});

// ─── Tabs Configuration ───
const underlineTabs = computed<UnderlineTabItem<LetterTabKey>[]>(() => [
  { id: 'all', label: 'All Letters', count: employeeLettersData.value.length },
  { id: 'pending_approval', label: 'Pending Approval', count: employeeLettersData.value.filter(l => l.letter_state === 'pending_approval').length, badgeVariant: 'warning' },
  { id: 'approved', label: 'Approved', count: employeeLettersData.value.filter(l => l.letter_state === 'approved').length, badgeVariant: 'primary' },
  { id: 'issued', label: 'Issued & Active', count: employeeLettersData.value.filter(l => l.letter_state === 'issued').length, badgeVariant: 'success' },
  { id: 'draft', label: 'Draft', count: employeeLettersData.value.filter(l => l.letter_state === 'draft').length },
  { id: 'revoked', label: 'Revoked', count: employeeLettersData.value.filter(l => l.letter_state === 'revoked').length, badgeVariant: 'danger' }
]);

// ─── Filtered Dataset ───
const filteredLetters = computed(() => {
  return employeeLettersData.value.filter(l => {
    // State Tab filter
    if (activeTab.value !== 'all' && l.letter_state !== activeTab.value) return false;

    // Type filter
    if (selectedTypeFilter.value !== 'all' && l.letter_type !== selectedTypeFilter.value) return false;

    // Search query
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase();
      const matchName = l.employee_name.toLowerCase().includes(q);
      const matchCode = l.code.toLowerCase().includes(q);
      const matchEmpCode = l.employee_code.toLowerCase().includes(q);
      const matchOrg = l.addressed_to?.organization?.toLowerCase().includes(q) || false;
      const matchPurpose = l.purpose?.toLowerCase().includes(q) || false;
      if (!matchName && !matchCode && !matchEmpCode && !matchOrg && !matchPurpose) return false;
    }

    return true;
  });
});

// ─── Table Columns (Matching Figma 7454:138268 exactly) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'select', label: '', width: '40px', sortable: false, visible: true },
  { key: 'employee', label: 'Name', sortable: true, visible: true },
  { key: 'letter_template', label: 'Letter Template', sortable: true, visible: true },
  { key: 'review_on_exit', label: 'Review on Exit', sortable: false, visible: true },
  { key: 'addressed_to', label: 'Addressed To', sortable: true, visible: true },
  { key: 'letter_state', label: 'Direction', sortable: true, visible: true },
  { key: 'state', label: 'Status', sortable: true, visible: true },
  { key: 'actions', label: 'Actions', width: '60px', sortable: false, visible: true }
]);

const handleToggleColumn = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  if (col) col.visible = !col.visible;
};

// ─── Structured Letter Creation Bottom Drawer State ───
const isCreateDrawerOpen = ref(false);
const drawerActiveMode = ref<'split' | 'editor' | 'preview'>('split');
const isDynamicFieldsOpen = ref(true);
const isPurposeOpen = ref(false);

interface EmployeeProfileOption {
  value: number;
  code: string;
  name: string;
  label: string;
  department: string;
  position: string;
  salary: number;
  allowance: number;
  hire_date: string;
  avatar: string;
}

const employeeProfiles: EmployeeProfileOption[] = [
  {
    value: 124,
    code: 'EMP-00124',
    name: 'Almaz Kebede',
    label: 'EMP-00124 - Almaz Kebede (Finance & Accounts)',
    department: 'Finance & Accounting Division',
    position: 'Senior Accountant',
    salary: 32000,
    allowance: 4500,
    hire_date: '2022-07-20',
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80'
  },
  {
    value: 12,
    code: 'EMP-0012',
    name: 'Abebe Kebede',
    label: 'EMP-0012 - Abebe Kebede (Head of Retail)',
    department: 'Retail Operations & Sales',
    position: 'Head of Retail',
    salary: 28000,
    allowance: 5000,
    hire_date: '2021-06-01',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80'
  },
  {
    value: 18,
    code: 'EMP-0018',
    name: 'Kidst Tesfaye',
    label: 'EMP-0018 - Kidst Tesfaye (Head of Retail)',
    department: 'Retail Operations & Sales',
    position: 'Head of Retail',
    salary: 26500,
    allowance: 4000,
    hire_date: '2022-09-01',
    avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80'
  },
  {
    value: 812,
    code: 'EMP-0812',
    name: 'Mihret Abera',
    label: 'EMP-0812 - Mihret Abera (Head of Retail)',
    department: 'Retail Operations & Sales',
    position: 'Head of Retail',
    salary: 25000,
    allowance: 3500,
    hire_date: '2023-03-10',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80'
  },
  {
    value: 22,
    code: 'EMP-0022',
    name: 'Hana Mesfin',
    label: 'EMP-0022 - Hana Mesfin (Finance & Accounting)',
    department: 'Finance & Accounting Division',
    position: 'Senior Financial Analyst',
    salary: 28500,
    allowance: 6200,
    hire_date: '2023-01-15',
    avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80'
  }
];

const employeeOptions = employeeProfiles.map(e => ({ value: e.value, label: e.name }));

const templateOptions = computed(() => {
  return letterTemplatesData.value.map(t => ({
    value: t.id,
    label: t.name
  }));
});

const positionOptions = [
  { value: 'Senior Financial Analyst', label: 'Senior Financial Analyst' },
  { value: 'Lead Financial Systems Analyst', label: 'Lead Financial Systems Analyst' },
  { value: 'Sales Officer', label: 'Sales Officer' },
  { value: 'Operations Lead', label: 'Operations Lead' },
  { value: 'Retail Branch Manager', label: 'Retail Branch Manager' }
];

// Reactive form state matching Figma design
const newLetterForm = ref({
  employee_id: 124, // Almaz Kebede (Figma default)
  letter_template_id: 7, // Employee Promotion
  addressed_organization: 'Zemen Bank',
  addressed_attention: 'HR Department',
  purpose: 'In recognition of your outstanding performance, leadership, and dedicated service, Executive Management is pleased to confirm your promotion.',
  remind_on_separation: false,

  // 1. Promotion (Figma screen 7454:138647)
  new_position: 'Sales Officer',
  new_department: 'Retail Operations & Sales',
  new_salary: 32000,
  effective_date: '2027-07-25',

  // 2. Salary Certificate & General Financials
  basic_salary: 32000,
  monthly_allowance: 4500,
  bank_name: 'Zemen Bank',
  facility_type: 'Housing Mortgage Loan',
  guarantor_amount: 1500000,

  // 3. Work Experience
  hire_date: '2022-07-20',
  last_working_date: '2027-07-20',
  conduct_rating: 'Exemplary Conduct & Diligence',
  job_responsibilities: 'Financial reporting, variance analysis, and audit preparation.',

  // 4. Written Warning
  incident_date: '2026-08-12',
  warning_level: 'First Formal Warning',
  infraction_reason: 'Operational variance and unverified expenditure protocol',
  corrective_action: 'Must complete internal financial compliance training within 14 calendar days.'
});

const currentSelectedEmployee = computed(() => {
  return employeeProfiles.find(e => e.value === newLetterForm.value.employee_id) || employeeProfiles[0];
});

const currentSelectedTemplate = computed(() => {
  return letterTemplatesData.value.find(t => t.id === newLetterForm.value.letter_template_id) || letterTemplatesData.value[0];
});

// Auto-hydrate form fields when employee is selected
const handleEmployeeChange = () => {
  const emp = currentSelectedEmployee.value;
  if (emp) {
    newLetterForm.value.basic_salary = emp.salary;
    newLetterForm.value.monthly_allowance = emp.allowance;
    newLetterForm.value.hire_date = emp.hire_date;
    newLetterForm.value.new_salary = emp.salary;
  }
};

// Open the bottom drawer
const handleOpenCreateDrawer = () => {
  newLetterForm.value.employee_id = 124;
  newLetterForm.value.letter_template_id = 7;
  newLetterForm.value.addressed_organization = 'Zemen Bank';
  newLetterForm.value.addressed_attention = 'HR Department';
  newLetterForm.value.purpose = 'In recognition of your outstanding performance, leadership, and dedicated service, Executive Management is pleased to confirm your promotion.';
  newLetterForm.value.remind_on_separation = false;
  handleEmployeeChange();
  isCreateDrawerOpen.value = true;
};

// Computed live rendered letter body
const liveRenderedBody = computed(() => {
  const tmpl = currentSelectedTemplate.value;
  const emp = currentSelectedEmployee.value;
  if (!tmpl || !emp) return '';

  const activePosition = tmpl.letter_type === 'promotion'
    ? (newLetterForm.value.new_position || emp.position)
    : emp.position;

  const activeSalary = tmpl.letter_type === 'promotion'
    ? (newLetterForm.value.new_salary || newLetterForm.value.basic_salary)
    : newLetterForm.value.basic_salary;

  const sampleData: Record<string, string> = {
    '{{employee_name}}': emp.name,
    '{{employee_code}}': emp.code,
    '{{position}}': activePosition,
    '{{department}}': tmpl.letter_type === 'promotion'
      ? (newLetterForm.value.new_department || emp.department)
      : emp.department,
    '{{basic_salary}}': Number(activeSalary).toLocaleString() + '.00',
    '{{monthly_allowance}}': Number(newLetterForm.value.monthly_allowance || 0).toLocaleString() + '.00',
    '{{hire_date}}': newLetterForm.value.hire_date || emp.hire_date,
    '{{last_working_date}}': newLetterForm.value.last_working_date || 'Current Active Service',
    '{{effective_date}}': newLetterForm.value.effective_date || 'Jul 25, 2027',
    '{{current_date}}': new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' }),
    '{{addressed_organization}}': newLetterForm.value.addressed_organization || 'To Whom It May Concern',
    '{{addressed_attention}}': newLetterForm.value.addressed_attention || 'Consular / Credit Affairs',
    '{{purpose}}': newLetterForm.value.purpose || 'Official employment verification'
  };

  return renderTemplatePreview(tmpl.body, sampleData);
});

const handleSaveBottomDrawer = () => {
  const emp = currentSelectedEmployee.value;
  const tmpl = currentSelectedTemplate.value;
  if (!emp || !tmpl) return;

  const structuredMergeData: Record<string, any> = {
    employee_name: emp.name,
    employee_code: emp.code,
    department: emp.department,
    position: emp.position,
    hire_date: newLetterForm.value.hire_date || emp.hire_date
  };

  if (tmpl.letter_type === 'promotion') {
    structuredMergeData.new_position = newLetterForm.value.new_position;
    structuredMergeData.new_department = newLetterForm.value.new_department;
    structuredMergeData.new_salary = Number(newLetterForm.value.new_salary || newLetterForm.value.basic_salary);
    structuredMergeData.effective_date = newLetterForm.value.effective_date;
  } else if (tmpl.letter_type === 'salary_certificate') {
    structuredMergeData.salary = Number(newLetterForm.value.basic_salary);
    structuredMergeData.basic_salary = Number(newLetterForm.value.basic_salary);
    structuredMergeData.monthly_allowance = Number(newLetterForm.value.monthly_allowance || 0);
    structuredMergeData.bank_name = newLetterForm.value.bank_name;
  } else if (tmpl.letter_type === 'experience') {
    structuredMergeData.last_working_date = newLetterForm.value.last_working_date;
    structuredMergeData.conduct_rating = newLetterForm.value.conduct_rating;
    structuredMergeData.job_responsibilities = newLetterForm.value.job_responsibilities;
  } else if (tmpl.letter_type === 'warning') {
    structuredMergeData.incident_date = newLetterForm.value.incident_date;
    structuredMergeData.warning_level = newLetterForm.value.warning_level;
    structuredMergeData.infraction_reason = newLetterForm.value.infraction_reason;
  }

  addEmployeeLetter({
    direction: 'outgoing',
    remind_on_separation: newLetterForm.value.remind_on_separation,
    employee_id: emp.value,
    employee_name: emp.name,
    employee_code: emp.code,
    employee_avatar: emp.avatar,
    department: emp.department,
    position: emp.position,
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa Branch',
    letter_template_id: tmpl.id,
    template_name: tmpl.name,
    letter_type: tmpl.letter_type,
    letter_state: tmpl.requires_approval ? 'pending_approval' : 'issued',
    merge_data: structuredMergeData,
    addressed_to: newLetterForm.value.addressed_organization ? {
      organization: newLetterForm.value.addressed_organization,
      attention: newLetterForm.value.addressed_attention || undefined
    } : null,
    purpose: newLetterForm.value.purpose || 'Official employment verification',
    requested_by_employee_id: emp.value,
    requested_by_name: emp.name,
    issued_by_employee_id: tmpl.requires_approval ? null : 7,
    issued_by_name: tmpl.requires_approval ? null : 'Solomon Worku',
    issued_at: tmpl.requires_approval ? null : new Date().toISOString(),
    user_id: 1,
    state: 'active'
  });

  isCreateDrawerOpen.value = false;
  showToast(`Official ${tmpl.name} generated successfully for ${emp.name}.`);
};

// ─── Print Settings Drawer State (Matches Figma 7454:138562) ───
const isPrintSettingsOpen = ref(false);
const printSettings = ref({
  companyLogo: true,
  documentTitle: true,
  letterPurpose: true,
  letterBody: true,
  showDynamicFields: true,
  upgradedPosition: true,
  revisedSalary: true,
  promotionEffectiveDate: true
});

const handleOpenPrintSettings = () => {
  isPrintSettingsOpen.value = true;
};

// ─── Document Inspection Modal ───
const selectedLetter = ref<EmployeeLetterRecord | null>(null);
const isDocumentModalOpen = ref(false);

const handleViewDocument = (letter: EmployeeLetterRecord) => {
  selectedLetter.value = letter;
  isDocumentModalOpen.value = true;
};

const handleApproveLetter = (letter: EmployeeLetterRecord) => {
  updateLetterStatus(letter.id, 'approved');
  showToast(`Letter ${letter.code} approved.`);
};

const handleIssueLetter = (letter: EmployeeLetterRecord) => {
  updateLetterStatus(letter.id, 'issued', 'Solomon Worku (HR Director)');
  showToast(`Letter ${letter.code} officially issued with signed corporate seal.`);
};

const handleRevokeLetter = (letter: EmployeeLetterRecord) => {
  const reason = prompt('Please enter the revocation reason:');
  if (reason) {
    updateLetterStatus(letter.id, 'revoked');
    letter.revoke_reason = reason;
    showToast(`Letter ${letter.code} has been revoked.`);
  }
};
</script>

<template>
  <div class="employee-letters-page">
    <!-- Breadcrumb Standard (AGENTS.md Rule 3) -->
    <AppBreadcrumb :items="breadcrumbItems" />

    <!-- Toast Notification -->
    <transition name="fade">
      <div v-if="toastMessage" class="toast-notification">
        <CheckCircle2 :size="16" class="toast-icon" />
        <span>{{ toastMessage }}</span>
      </div>
    </transition>

    <!-- Top KPI Metrics (Matches Figma 7454:138268 exactly) -->
    <div class="metrics-grid">
      <MetricCard
        label="TOTAL LETTERS ISSUED"
        :value="metrics.total"
        subtext="All letters on corporate file"
      />
      <MetricCard
        label="PENDING HR APPROVAL"
        :value="metrics.pending"
        subtext="Awaiting executive sign-off"
      />
      <MetricCard
        label="ACTIVE ISSUED LETTERS"
        :value="metrics.issued"
        subtext="Official valid documentation"
      />
      <MetricCard
        label="EXIT BOND REVIEWS"
        :value="metrics.separationReminders"
        subtext="Tracked on employee exit"
      />
    </div>

    <!-- Main Data Table Container (Matching Figma 7454:138268) -->
    <AppDataTable
      title="Employee Letters"
      subtitle="Manage official company letters, employment certificates, bank undertakings, and statutory experience letters."
      :columns="tableColumns"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Actions Slot -->
      <template #actions>
        <button class="btn-primary-blue" @click="handleOpenCreateDrawer">
          <Plus :size="16" />
          <span>+ Create Letter</span>
        </button>
      </template>

      <!-- Subheader Filters & Search -->
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
              <button class="btn-secondary-toolbar" title="Filter letters">
                <Filter :size="14" />
                <span>Filter</span>
              </button>

              <button class="btn-secondary-toolbar" title="Sort letters">
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
                <th v-if="tableColumns[2].visible">Letter Template</th>
                <th v-if="tableColumns[3].visible">Review on Exit</th>
                <th v-if="tableColumns[4].visible">Addressed To</th>
                <th v-if="tableColumns[5].visible">Direction</th>
                <th v-if="tableColumns[6].visible">Status</th>
                <th v-if="tableColumns[7].visible" class="th-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="letter in filteredLetters"
                :key="letter.id"
                class="table-row-hover"
                @click="handleViewDocument(letter)"
              >
                <!-- Checkbox -->
                <td v-if="tableColumns[0].visible" class="td-check" @click.stop>
                  <input type="checkbox" class="table-checkbox" />
                </td>

                <!-- Primary Identity: Avatar + Name + Subtext (Figma 7454:138268) -->
                <td v-if="tableColumns[1].visible" class="td-employee">
                  <div class="employee-identity-cell">
                    <img :src="letter.employee_avatar" :alt="letter.employee_name" class="emp-avatar" />
                    <div class="emp-details">
                      <span class="table-name-primary">{{ letter.employee_name }}</span>
                      <span class="table-code-subtext">{{ letter.employee_code }} • {{ letter.position }}</span>
                    </div>
                  </div>
                </td>

                <!-- Letter Template (Plain text) -->
                <td v-if="tableColumns[2].visible" class="td-tertiary">
                  <span class="cell-plain-text">{{ letter.template_name }}</span>
                </td>

                <!-- Review on Exit (Plain text: Yes / No) -->
                <td v-if="tableColumns[3].visible" class="td-tertiary">
                  <span class="cell-plain-text">{{ letter.remind_on_separation ? 'Yes' : 'No' }}</span>
                </td>

                <!-- Addressed To -->
                <td v-if="tableColumns[4].visible" class="td-tertiary">
                  <span class="cell-plain-text">{{ letter.addressed_to?.organization || '—' }}</span>
                </td>

                <!-- Direction / Lifecycle Status (Soft pill) -->
                <td v-if="tableColumns[5].visible" class="td-status">
                  <span class="direction-soft-pill" :class="'dir-' + letter.letter_state">
                    {{ letter.letter_state === 'pending_approval' ? 'Pending' : (letter.letter_state === 'issued' ? 'Issued' : (letter.letter_state === 'draft' ? 'Draft' : letter.letter_state)) }}
                  </span>
                </td>

                <!-- Status (Active / Inactive state pill) -->
                <td v-if="tableColumns[6].visible" class="td-state">
                  <span class="state-pill" :class="letter.state === 'active' ? 'state-active' : 'state-inactive'">
                    {{ letter.state === 'active' ? 'Active' : 'Inactive' }}
                  </span>
                </td>

                <!-- Row Actions -->
                <td v-if="tableColumns[7].visible" class="td-actions" @click.stop>
                  <button class="btn-action-dots" title="More options" @click="handleViewDocument(letter)">
                    <MoreVertical :size="16" />
                  </button>
                </td>
              </tr>

              <!-- Empty State -->
              <tr v-if="filteredLetters.length === 0">
                <td colspan="8" class="empty-state-cell">
                  <div class="empty-container">
                    <FileText :size="36" class="empty-icon" />
                    <p class="empty-title">No letters found</p>
                    <p class="empty-desc">No letters match the current filter or search criteria.</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>

          <!-- Minimalist Pagination Bar matching Figma -->
          <div class="figma-pagination-bar">
            <div class="pagination-left">
              <span>Showing 1 to {{ filteredLetters.length }} of {{ filteredLetters.length }} entries</span>
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
    <!-- BOTTOM DRAWER: CREATE EMPLOYEE LETTER (Figma 7454:138481 & 7454:138647) -->
    <!-- ═══════════════════════════════════════════════════════════════════════ -->
    <div v-if="isCreateDrawerOpen" class="drawer-backdrop" @click="isCreateDrawerOpen = false">
      <div class="bottom-drawer-container" @click.stop>
        <!-- Top Drag Pill -->
        <div class="drawer-drag-pill"></div>

        <!-- Drawer Header -->
        <div class="drawer-header">
          <div class="drawer-header-left">
            <h2 class="drawer-title">Create Employee Letter</h2>
            <p class="drawer-subtext">Official Employee Letter</p>
          </div>

          <div class="drawer-header-right">
            <!-- Go to Printing button (Matches Figma 7454:138647) -->
            <button class="btn-outline-action" @click="handleOpenPrintSettings">
              <ArrowUpRight :size="15" />
              <span>Go to Printing</span>
            </button>

            <!-- Segmented View Mode Switcher -->
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
          <!-- LEFT PANE: DYNAMIC CREATE FORM -->
          <div v-show="drawerActiveMode === 'split' || drawerActiveMode === 'editor'" class="drawer-form-pane">
            <div class="pane-scroll-inner">
              <!-- Card 1: Core Selection & Recipient (Figma 7454:138647) -->
              <div class="figma-form-card">
                <div class="form-grid-2">
                  <FormSelect
                    v-model="newLetterForm.employee_id"
                    label="Target Employee *"
                    :options="employeeOptions"
                    required
                    @change="handleEmployeeChange"
                  />

                  <FormSelect
                    v-model="newLetterForm.letter_template_id"
                    label="Letter Template *"
                    :options="templateOptions"
                    required
                  />
                </div>

                <!-- Employee Preview Section (Figma 7454:138647) -->
                <div class="figma-emp-preview-bar">
                  <div class="emp-preview-left">
                    <img :src="currentSelectedEmployee.avatar" :alt="currentSelectedEmployee.name" class="emp-preview-avatar" />
                    <div class="emp-preview-meta">
                      <span class="emp-preview-name">{{ currentSelectedEmployee.name }}</span>
                      <div class="emp-preview-tagline">
                        <span>{{ currentSelectedEmployee.code }} - </span>
                        <span class="emp-role-pill">{{ currentSelectedEmployee.position }}</span>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Address To & Attention Person / Department -->
                <div class="form-grid-2">
                  <FormInput
                    v-model="newLetterForm.addressed_organization"
                    label="Address To *"
                    required
                  />
                  <FormInput
                    v-model="newLetterForm.addressed_attention"
                    label="Attention Person / Department *"
                    required
                  />
                </div>

                <!-- Flag for Review on Employee Separation Checkbox -->
                <FormCheckbox
                  v-model="newLetterForm.remind_on_separation"
                  label="Flag for Review on Employee Separation"
                  description="If enabled, this undertaking or certification will trigger a mandatory alert during exit clearance and final settlement to verify satisfaction of obligations."
                />
              </div>

              <!-- Card 2: Accordion for Dynamic Information Data fields (Figma 7454:138647) -->
              <div class="figma-accordion-card">
                <div class="accordion-header" @click="isDynamicFieldsOpen = !isDynamicFieldsOpen">
                  <span class="accordion-title">Dynamic Information Data fields</span>
                  <component :is="isDynamicFieldsOpen ? ChevronDown : ChevronRight" :size="16" class="accordion-chevron" />
                </div>

                <div v-show="isDynamicFieldsOpen" class="accordion-body">
                  <!-- Promotion Specific Fields (Figma 7454:138647) -->
                  <div v-if="currentSelectedTemplate.letter_type === 'promotion'" class="dynamic-form-rows">
                    <div class="form-grid-2">
                      <FormSelect
                        v-model="newLetterForm.new_position"
                        label="Upgraded Position"
                        :options="positionOptions"
                      />
                      <FormInput
                        v-model="newLetterForm.new_salary"
                        label="Revised Monthly Salary"
                      />
                    </div>
                    <div class="form-grid-1 mt-3">
                      <div class="form-field-wrapper">
                        <label class="figma-field-label">Promotion Effective Date</label>
                        <div class="date-input-with-badge">
                          <input
                            v-model="newLetterForm.effective_date"
                            type="text"
                            class="figma-date-input"
                          />
                          <span class="gc-badge">GC</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- Salary Certificate Specific Fields -->
                  <div v-else-if="currentSelectedTemplate.letter_type === 'salary_certificate'" class="dynamic-form-rows">
                    <div class="form-grid-2">
                      <FormInput
                        v-model="newLetterForm.basic_salary"
                        label="Basic Monthly Salary"
                        required
                      />
                      <FormInput
                        v-model="newLetterForm.monthly_allowance"
                        label="Regular Monthly Allowances"
                      />
                    </div>
                    <div class="form-grid-2 mt-3">
                      <FormInput
                        v-model="newLetterForm.bank_name"
                        label="Designated Commercial Bank"
                      />
                      <div class="computed-stat-card">
                        <span class="stat-title">Computed Gross Monthly</span>
                        <span class="stat-number">ETB {{ (Number(newLetterForm.basic_salary || 0) + Number(newLetterForm.monthly_allowance || 0)).toLocaleString() }}.00</span>
                      </div>
                    </div>
                  </div>

                  <!-- Work Experience Fields -->
                  <div v-else-if="currentSelectedTemplate.letter_type === 'experience'" class="dynamic-form-rows">
                    <div class="form-grid-2">
                      <FormInput
                        v-model="newLetterForm.hire_date"
                        label="Employment Start Date"
                        required
                      />
                      <FormInput
                        v-model="newLetterForm.last_working_date"
                        label="Last Working Date / Separation"
                        required
                      />
                    </div>
                    <div class="form-grid-2 mt-3">
                      <FormInput
                        v-model="newLetterForm.conduct_rating"
                        label="Conduct & Disciplinary Standing"
                        required
                      />
                      <FormInput
                        v-model="newLetterForm.job_responsibilities"
                        label="Primary Scope & Duties"
                      />
                    </div>
                  </div>

                  <!-- Warning Fields -->
                  <div v-else-if="currentSelectedTemplate.letter_type === 'warning'" class="dynamic-form-rows">
                    <div class="form-grid-2">
                      <FormInput
                        v-model="newLetterForm.incident_date"
                        label="Incident Record Date"
                        required
                      />
                      <FormInput
                        v-model="newLetterForm.warning_level"
                        label="Warning Severity Level"
                        required
                      />
                    </div>
                    <div class="form-grid-1 mt-3">
                      <FormInput
                        v-model="newLetterForm.infraction_reason"
                        label="Infraction / Non-Compliance Summary"
                        required
                      />
                    </div>
                  </div>

                  <!-- Default Fallback Fields -->
                  <div v-else class="dynamic-form-rows">
                    <div class="form-grid-2">
                      <FormInput
                        v-model="newLetterForm.hire_date"
                        label="Commencement Date"
                        required
                      />
                      <FormInput
                        :model-value="currentSelectedEmployee.position"
                        label="Confirmed Designation"
                        disabled
                      />
                    </div>
                  </div>
                </div>
              </div>

              <!-- Card 3: Accordion for Letter Purpose (Figma 7454:138647) -->
              <div class="figma-accordion-card">
                <div class="accordion-header" @click="isPurposeOpen = !isPurposeOpen">
                  <span class="accordion-title">Letter Purpose</span>
                  <component :is="isPurposeOpen ? ChevronDown : ChevronRight" :size="16" class="accordion-chevron" />
                </div>

                <div v-show="isPurposeOpen" class="accordion-body">
                  <FormInput
                    v-model="newLetterForm.purpose"
                    label="Specific Request Purpose"
                    required
                  />
                </div>
              </div>
            </div>
          </div>

          <!-- RIGHT PANE: REAL-TIME LIVE LETTER PREVIEW (Figma 7454:138647) -->
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

                <!-- Structured Fact Sheet Table (Figma 7454:138647) -->
                <div class="figma-fact-sheet-card">
                  <table class="figma-fact-table">
                    <thead>
                      <tr>
                        <th>Full Name</th>
                        <th v-if="currentSelectedTemplate.letter_type === 'promotion'">Upgraded Position</th>
                        <th v-if="currentSelectedTemplate.letter_type === 'promotion'">Revised Monthly Salary</th>
                        <th v-if="currentSelectedTemplate.letter_type === 'promotion'">Promotion Effective Date</th>
                        <th v-if="currentSelectedTemplate.letter_type !== 'promotion'">Verified Position</th>
                        <th v-if="currentSelectedTemplate.letter_type !== 'promotion'">Department</th>
                        <th v-if="currentSelectedTemplate.letter_type !== 'promotion'">Basic Salary</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <!-- Full Name -->
                        <td class="fact-bold-val">{{ currentSelectedEmployee.name }}</td>

                        <!-- Dynamic Columns for Promotion -->
                        <template v-if="currentSelectedTemplate.letter_type === 'promotion'">
                          <td class="fact-bold-val">{{ newLetterForm.new_position || 'Sales Officer' }}</td>
                          <td class="fact-bold-val">ETB {{ Number(newLetterForm.new_salary || 32000).toLocaleString() }}</td>
                          <td class="fact-val">{{ newLetterForm.effective_date || 'Jul 25, 2027' }}</td>
                        </template>

                        <!-- Dynamic Columns for Other Templates -->
                        <template v-else>
                          <td class="fact-bold-val">{{ currentSelectedEmployee.position }}</td>
                          <td class="fact-val">{{ currentSelectedEmployee.department }}</td>
                          <td class="fact-bold-val">ETB {{ Number(newLetterForm.basic_salary).toLocaleString() }}</td>
                        </template>
                      </tr>
                    </tbody>
                  </table>
                </div>

                <!-- Body Content Text Block -->
                <div class="figma-letter-body-block">
                  <p class="body-lead-text">
                    {{ newLetterForm.purpose || 'In recognition of your outstanding performance, leadership, and dedicated service, Executive Management is pleased to confirm your promotion.' }}
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

        <!-- Drawer Footer (Matches Figma 7454:138647) -->
        <div class="drawer-footer">
          <button class="btn-footer-close" @click="isCreateDrawerOpen = false">
            <X :size="14" />
            <span>Close</span>
          </button>

          <button class="btn-footer-save" @click="handleSaveBottomDrawer">
            <span>Save</span>
          </button>
        </div>
      </div>
    </div>

    <!-- ═══════════════════════════════════════════════════════════════════════ -->
    <!-- PRINT SETTINGS DRAWER / MODAL (Matches Figma 7454:138562)              -->
    <!-- ═══════════════════════════════════════════════════════════════════════ -->
    <div v-if="isPrintSettingsOpen" class="drawer-backdrop" @click="isPrintSettingsOpen = false">
      <div class="bottom-drawer-container print-settings-drawer" @click.stop>
        <!-- Top Drag Pill -->
        <div class="drawer-drag-pill"></div>

        <!-- Header -->
        <div class="drawer-header">
          <div class="drawer-header-left">
            <h2 class="drawer-title">Print Settings</h2>
            <p class="drawer-subtext">Configure Document layout and Visibility</p>
          </div>
          <button class="btn-close-header" @click="isPrintSettingsOpen = false">
            <X :size="18" />
          </button>
        </div>

        <!-- Body: Left Toggles & Right Dynamic Sheet -->
        <div class="drawer-split-body mode-split">
          <!-- Left: Toggle Controls -->
          <div class="drawer-form-pane print-settings-pane">
            <div class="pane-scroll-inner">
              <!-- Switch Row: Company Logo -->
              <div class="toggle-switch-row">
                <span class="toggle-switch-label">Company Logo</span>
                <label class="ios-switch">
                  <input v-model="printSettings.companyLogo" type="checkbox" />
                  <span class="slider round"></span>
                </label>
              </div>

              <!-- Switch Row: Document Title -->
              <div class="toggle-switch-row">
                <span class="toggle-switch-label">Document Title</span>
                <label class="ios-switch">
                  <input v-model="printSettings.documentTitle" type="checkbox" />
                  <span class="slider round"></span>
                </label>
              </div>

              <!-- Switch Row: Letter Purpose -->
              <div class="toggle-switch-row">
                <span class="toggle-switch-label">Letter Purpose</span>
                <label class="ios-switch">
                  <input v-model="printSettings.letterPurpose" type="checkbox" />
                  <span class="slider round"></span>
                </label>
              </div>

              <!-- Switch Row: Letter Body -->
              <div class="toggle-switch-row">
                <span class="toggle-switch-label">Letter Body</span>
                <label class="ios-switch">
                  <input v-model="printSettings.letterBody" type="checkbox" />
                  <span class="slider round"></span>
                </label>
              </div>

              <!-- Dynamic Information Card with Sub-toggles -->
              <div class="dynamic-toggles-card">
                <div class="toggle-switch-row card-main-toggle">
                  <span class="toggle-switch-label">Show Dynamic Information Data fields</span>
                  <label class="ios-switch">
                    <input v-model="printSettings.showDynamicFields" type="checkbox" />
                    <span class="slider round"></span>
                  </label>
                </div>

                <div v-show="printSettings.showDynamicFields" class="card-sub-toggles">
                  <div class="toggle-switch-row sub-row">
                    <span class="toggle-switch-label sub-label">Upgraded Position</span>
                    <label class="ios-switch">
                      <input v-model="printSettings.upgradedPosition" type="checkbox" />
                      <span class="slider round"></span>
                    </label>
                  </div>

                  <div class="toggle-switch-row sub-row">
                    <span class="toggle-switch-label sub-label">Revised Monthly Salary</span>
                    <label class="ios-switch">
                      <input v-model="printSettings.revisedSalary" type="checkbox" />
                      <span class="slider round"></span>
                    </label>
                  </div>

                  <div class="toggle-switch-row sub-row">
                    <span class="toggle-switch-label sub-label">Promotion Effective Date</span>
                    <label class="ios-switch">
                      <input v-model="printSettings.promotionEffectiveDate" type="checkbox" />
                      <span class="slider round"></span>
                    </label>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Right: Live Sheet reflecting toggles -->
          <div class="drawer-preview-pane">
            <div class="preview-scroll-viewport">
              <div class="figma-document-sheet">
                <!-- Header Logo (Toggled) -->
                <div v-if="printSettings.companyLogo" class="doc-header-row">
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
                    <p class="meta-line">Date: Jul 20, 2027</p>
                    <p class="meta-line">ETB &mdash; Ethiopian Birr</p>
                  </div>
                </div>

                <!-- Fact Sheet Table (Toggled) -->
                <div v-if="printSettings.showDynamicFields" class="figma-fact-sheet-card">
                  <table class="figma-fact-table">
                    <thead>
                      <tr>
                        <th>Full Name</th>
                        <th v-if="printSettings.upgradedPosition">Upgraded Position</th>
                        <th v-if="printSettings.revisedSalary">Revised Monthly Salary</th>
                        <th v-if="printSettings.promotionEffectiveDate">Promotion Effective Date</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <td class="fact-bold-val">{{ currentSelectedEmployee.name }}</td>
                        <td v-if="printSettings.upgradedPosition" class="fact-bold-val">{{ newLetterForm.new_position }}</td>
                        <td v-if="printSettings.revisedSalary" class="fact-bold-val">ETB {{ Number(newLetterForm.new_salary || 32000).toLocaleString() }}</td>
                        <td v-if="printSettings.promotionEffectiveDate" class="fact-val">{{ newLetterForm.effective_date || 'Jul 25, 2027' }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>

                <!-- Letter Body (Toggled) -->
                <div v-if="printSettings.letterBody" class="figma-letter-body-block">
                  <p class="body-lead-text">
                    In recognition of your outstanding performance, leadership, and dedicated service, Executive Management is pleased to confirm your promotion.
                  </p>
                </div>

                <!-- Letter Purpose (Toggled) -->
                <div v-if="printSettings.letterPurpose" class="figma-purpose-section">
                  <h5 class="purpose-section-title">Purpose</h5>
                  <p class="purpose-body-text">
                    In recognition of your exceptional dedication, proven leadership, and exemplary performance, Executive Management is pleased to formally announce your promotion to Lead Financial Systems Analyst within the Finance & Accounting Division, effective 01 November 2026.
                  </p>
                  <p class="purpose-body-text mt-2">
                    With this promotion, your revised monthly basic salary will be adjusted to ETB 35,000.00, alongside the benefits and statutory allowances corresponding to your upgraded job grade.
                  </p>
                </div>

                <!-- Page 1/1 Pill -->
                <div class="page-counter-pill">
                  <span>Page 1/1</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div class="drawer-footer">
          <button class="btn-footer-close" @click="isPrintSettingsOpen = false">
            <X :size="14" />
            <span>Close</span>
          </button>

          <div class="footer-right-buttons">
            <button class="btn-footer-pdf" @click="showToast('Exporting PDF document...')">
              <Download :size="14" />
              <span>PDF</span>
            </button>
            <button class="btn-footer-print" @click="window.print()">
              <Printer :size="14" />
              <span>Print</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Document Inspection Modal -->
    <div v-if="isDocumentModalOpen && selectedLetter" class="modal-backdrop" @click="isDocumentModalOpen = false">
      <div class="document-modal-content" @click.stop>
        <div class="doc-modal-header">
          <div class="doc-header-info">
            <span class="doc-code-pill">{{ selectedLetter.code }}</span>
            <h2 class="doc-title">{{ selectedLetter.template_name }}</h2>
          </div>
          <div class="doc-header-actions">
            <button class="btn-outline-action" @click="window.print()">
              <Printer :size="14" />
              <span>Print</span>
            </button>
            <button class="btn-close-header" @click="isDocumentModalOpen = false">
              <X :size="18" />
            </button>
          </div>
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
                <p class="meta-line">Ref: {{ selectedLetter.code }}</p>
                <p class="meta-line">Date: {{ selectedLetter.issued_at ? new Date(selectedLetter.issued_at).toLocaleDateString('en-GB') : 'Draft / Pending' }}</p>
              </div>
            </div>

            <div class="figma-fact-sheet-card">
              <table class="figma-fact-table">
                <thead>
                  <tr>
                    <th>Full Name</th>
                    <th>Verified Position</th>
                    <th>Department</th>
                    <th>Salary</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="fact-bold-val">{{ selectedLetter.employee_name }}</td>
                    <td class="fact-bold-val">{{ selectedLetter.position }}</td>
                    <td class="fact-val">{{ selectedLetter.department }}</td>
                    <td class="fact-bold-val">ETB {{ (selectedLetter.merge_data?.salary || selectedLetter.merge_data?.new_salary || 28500).toLocaleString() }}</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div class="figma-letter-body-block">
              <p class="body-lead-text">
                {{ selectedLetter.purpose || 'Official employment record confirmation and verified attestation.' }}
              </p>
            </div>

            <div class="page-counter-pill">
              <span>Page 1/1</span>
            </div>
          </div>
        </div>

        <div class="drawer-footer">
          <button class="btn-footer-close" @click="isDocumentModalOpen = false">
            <X :size="14" />
            <span>Close</span>
          </button>
          <div class="footer-right-buttons">
            <button
              v-if="selectedLetter.letter_state === 'pending_approval'"
              class="btn-footer-save"
              @click="handleApproveLetter(selectedLetter)"
            >
              Approve Letter
            </button>
            <button
              v-if="selectedLetter.letter_state === 'approved'"
              class="btn-footer-save"
              @click="handleIssueLetter(selectedLetter)"
            >
              Issue & Seal Letter
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.employee-letters-page {
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

/* Metric Cards Grid */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

@media (max-width: 900px) {
  .metrics-grid {
    grid-template-columns: repeat(2, 1fr);
  }
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

/* Employee Identity Cell (Figma 7454:138268) */
.employee-identity-cell {
  display: flex;
  align-items: center;
  gap: 12px;
}

.emp-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  object-fit: cover;
}

.emp-details {
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

/* Direction Soft Pills (Figma 7454:138268) */
.direction-soft-pill {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
}

.dir-draft { background-color: #fce7f3; color: #db2777; }
.dir-pending_approval, .dir-pending { background-color: #fef3c7; color: #d97706; }
.dir-issued { background-color: #e0f2fe; color: #0284c7; }
.dir-revoked { background-color: #fee2e2; color: #dc2626; }

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

/* Pagination Bar (Figma 7454:138268) */
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
/* BOTTOM DRAWER STYLES (Figma 7454:138481 & 7454:138647)                     */
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

.btn-outline-action {
  height: 34px;
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

.btn-outline-action:hover {
  background-color: #f8fafc;
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

.figma-emp-preview-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 14px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}

.emp-preview-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.emp-preview-avatar {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  object-fit: cover;
}

.emp-preview-meta {
  display: flex;
  flex-direction: column;
}

.emp-preview-name {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.emp-preview-tagline {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #737373;
}

.emp-role-pill {
  background-color: #f1f5f9;
  color: #404040;
  padding: 1px 8px;
  border-radius: 9999px;
  font-size: 11px;
  font-weight: 500;
}

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

.dynamic-form-rows {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.form-grid-1 {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
}

.mt-3 {
  margin-top: 12px;
}

.mt-2 {
  margin-top: 8px;
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

.date-input-with-badge {
  position: relative;
  display: flex;
  align-items: center;
}

.figma-date-input {
  width: 100%;
  height: 38px;
  padding: 0 44px 0 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  color: #404040;
  outline: none;
}

.figma-date-input:focus {
  border-color: #0b529c;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.gc-badge {
  position: absolute;
  right: 10px;
  font-size: 11px;
  font-weight: 600;
  color: #737373;
  background-color: #f1f5f9;
  padding: 2px 6px;
  border-radius: 4px;
}

.computed-stat-card {
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 8px 14px;
  background-color: #f0f7ff;
  border: 1px dashed #93c5fd;
  border-radius: 8px;
}

.stat-title {
  font-size: 11px;
  color: #0b529c;
  font-weight: 600;
}

.stat-number {
  font-size: 13.5px;
  font-weight: 700;
  color: #0f172a;
}

/* Right Preview Pane (Figma 7454:138647) */
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

/* Fact Sheet Table (Figma 7454:138647) */
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

.fact-val {
  color: #475569;
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

.figma-purpose-section {
  border-top: 1px solid #f1f5f9;
  padding-top: 18px;
  margin-top: 12px;
}

.purpose-section-title {
  font-size: 14px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 8px 0;
}

.purpose-body-text {
  font-size: 12.5px;
  line-height: 1.6;
  color: #475569;
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

/* ═══════════════════════════════════════════════════════════════════════════ */
/* PRINT SETTINGS DRAWER & TOGGLES (Figma 7454:138562)                         */
/* ═══════════════════════════════════════════════════════════════════════════ */
.print-settings-pane {
  padding: 24px;
}

.toggle-switch-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 0;
  border-bottom: 1px solid #f8fafc;
}

.toggle-switch-label {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
}

.dynamic-toggles-card {
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 14px 16px;
  margin-top: 12px;
  background-color: #ffffff;
}

.card-main-toggle {
  border-bottom: 1px solid #f1f5f9;
  padding-bottom: 12px;
}

.card-sub-toggles {
  padding-top: 8px;
  display: flex;
  flex-direction: column;
}

.sub-row {
  padding: 8px 0;
  border-bottom: none;
}

.sub-label {
  font-size: 13px;
  color: #64748b;
}

/* iOS Toggle Switch Standard */
.ios-switch {
  position: relative;
  display: inline-block;
  width: 40px;
  height: 22px;
}

.ios-switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.slider {
  position: absolute;
  cursor: pointer;
  inset: 0;
  background-color: #cbd5e1;
  transition: 0.25s;
  border-radius: 9999px;
}

.slider:before {
  position: absolute;
  content: "";
  height: 16px;
  width: 16px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: 0.25s;
  border-radius: 50%;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
}

input:checked + .slider {
  background-color: #0b529c;
}

input:checked + .slider:before {
  transform: translateX(18px);
}

.footer-right-buttons {
  display: flex;
  align-items: center;
  gap: 10px;
}

.btn-footer-pdf {
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
}

.btn-footer-pdf:hover {
  background-color: #f8fafc;
}

.btn-footer-print {
  height: 36px;
  padding: 0 18px;
  background-color: #0b529c;
  border: none;
  border-radius: 8px;
  color: #ffffff;
  font-size: 13px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
}

.btn-footer-print:hover {
  background-color: #083e76;
}

/* Modal Backdrop */
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

.doc-header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
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
