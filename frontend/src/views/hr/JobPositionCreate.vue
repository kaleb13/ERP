<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { 
  Monitor, ChevronRight, X, Briefcase, GraduationCap,
  Plus, Trash2, Calendar, ChevronDown, Columns,
  List, Table, Link as LinkIcon, Image as ImageIcon,
  Undo, Redo, Maximize2, Check, ShieldAlert, Award
} from 'lucide-vue-next';
import BaseTabs, { type TabItem } from '../../components/BaseTabs.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

const router = useRouter();
const route = useRoute();

// ─── Document State ───
const isSaved = ref(false);
const quickActionToast = ref<string | null>(null);
const isRequirementsOpen = ref(true);

// ─── Active Tab (BaseTabs Capsule Standard) ───
type TabId = 'position' | 'requirements';
const activeTab = ref<TabId>('position');

const tabs = computed<TabItem[]>(() => [
  { id: 'position', label: 'Position Details', icon: Briefcase },
  { id: 'requirements', label: 'Requirements & Qualifications', icon: GraduationCap }
]);

// ─── Catalogue Options (FK Selects conforming to Schema lines 1152-1176) ───
// ─── Catalogue Options (FK Selects conforming to Schema lines 1152-1201) ───
const jobTitleOptions = [
  { value: 12, label: 'HR Officer (JT-HR-OFF)' },
  { value: 24, label: 'Senior Cashier (JT-SR-CSH)' },
  { value: 30, label: 'Finance Manager (JT-FIN-MGR)' },
  { value: 31, label: 'Financial Accountant (JT-FIN-ACC)' },
  { value: 40, label: 'Procurement Officer (JT-PRC-OFF)' }
];

const jobLevelOptions = [
  { value: 1, label: 'Junior (LVL-JR)' },
  { value: 2, label: 'Officer (LVL-OFF)' },
  { value: 3, label: 'Senior (LVL-SR)' },
  { value: 4, label: 'Lead (LVL-LEAD)' },
  { value: 5, label: 'Manager (LVL-MGR)' },
  { value: 6, label: 'Director (LVL-DIR)' }
];

const orgUnitOptions = [
  { value: 1, label: 'Human Resources (OU-HR)' },
  { value: 2, label: 'Finance & Corporate Services Division (OU-FIN)' },
  { value: 6, label: 'Payroll & Benefits Section (OU-PAY)' },
  { value: 8, label: 'Commercial Sales & Front Office (OU-SALES)' },
  { value: 4, label: 'Procurement & Logistics Department (OU-PRC)' }
];

const jobGradeOptions = [
  { value: 3, label: 'Grade C1 (Base: 5,000 ETB)' },
  { value: 4, label: 'Grade C2 (Base: 8,000 ETB)' },
  { value: 5, label: 'Grade B2 (Base: 11,000 ETB)' },
  { value: 6, label: 'Grade B1 (Base: 17,000 ETB)' },
  { value: 7, label: 'Grade A3 (Base: 26,000 ETB)' }
];

const reportsToOptions = [
  { value: 30, label: 'Finance Manager (POS-FIN-001)' },
  { value: 11, label: 'HR Director (POS-HR-001)' },
  { value: 38, label: 'Operations Lead (POS-OPS-001)' },
  { value: 20, label: 'Commercial Sales Lead (POS-SALES-001)' }
];

const entityOptions = [
  { value: 1, label: 'QMT Business Group (HQ)' },
  { value: 3, label: 'Haleta Addis Ababa HQ' },
  { value: 7, label: 'Haleta Grand Hotel & Suites' },
  { value: 9, label: 'Haleta Hawassa Hub' }
];

const fieldOfStudyOptions = [
  { value: 1, label: 'Business Administration (BUSINESS)' },
  { value: 3, label: 'Accounting & Finance (ACCOUNTING)' },
  { value: 7, label: 'Finance & Banking (FINANCE)' },
  { value: 9, label: 'Human Resource Management (HRM)' },
  { value: 15, label: 'Supply Chain Management (SUPPLY_CHAIN)' },
  { value: 20, label: 'Computer Science & Software Engineering (CS_SE)' }
];

// All 9 enum values from schema line 1181: POSITION_REQUIREMENT_TYPE
const requirementTypeOptions = [
  { value: 'qualification', label: 'Academic Qualification (qualification)' },
  { value: 'certification', label: 'Professional Certification (certification)' },
  { value: 'skill', label: 'Technical Skill (skill)' },
  { value: 'experience_years', label: 'Years of Experience (experience_years)' },
  { value: 'language', label: 'Spoken Language (language)' },
  { value: 'age_min', label: 'Minimum Age (age_min)' },
  { value: 'age_max', label: 'Maximum Age (age_max)' },
  { value: 'physical_ability', label: 'Physical Ability (physical_ability)' },
  { value: 'driving_license', label: 'Driving License (driving_license)' }
];

// SKILL_CATALOG (Schema line 277)
const skillCatalogOptions = [
  { value: 101, label: 'IFRS Reporting & Standards (ifrs_reporting)' },
  { value: 102, label: 'Peachtree / QuickBooks Accounting (peachtree)' },
  { value: 103, label: 'Point of Sale Operation (pos_operation)' },
  { value: 104, label: 'Cash Management & Treasury (cash_management)' },
  { value: 105, label: 'Supplier Negotiation & Procurement (supplier_negotiation)' },
  { value: 106, label: 'Ethiopian Labour Law Compliance (labour_law_compliance)' },
  { value: 107, label: 'Customer Service & Hospitality (customer_service)' },
  { value: 108, label: 'Data Entry & Spreadsheet Analysis (data_entry)' },
  { value: 109, label: 'Warehouse Management & Inventory (warehouse_management)' },
  { value: 110, label: 'Forklift Operation & Heavy Equipment (forklift_operation)' },
  { value: 111, label: 'Food Safety & Hygiene Standards (food_safety)' },
  { value: 112, label: 'Housekeeping Standards (housekeeping)' },
  { value: 113, label: 'Barista & Beverage Preparation (barista)' },
  { value: 114, label: 'Front Desk Operations (front_desk)' },
  { value: 199, label: 'Other Specialised Skill (other)' }
];

// CERTIFICATION_CATALOG (Schema line 275)
const certCatalogOptions = [
  { value: 201, label: 'ACCA Certified Chartered Accountant (acca)' },
  { value: 202, label: 'CPA Certified Public Accountant (cpa)' },
  { value: 203, label: 'CFA Chartered Financial Analyst (cfa)' },
  { value: 204, label: 'CIA Certified Internal Auditor (cia)' },
  { value: 205, label: 'CISA Certified Information Systems Auditor (cisa)' },
  { value: 206, label: 'Certified HR Professional (hr_professional)' },
  { value: 207, label: 'Public Procurement Specialist (procurement_specialist)' },
  { value: 208, label: 'Occupational Safety & Health (occupational_safety)' },
  { value: 209, label: 'First Aid & Emergency Response (first_aid)' },
  { value: 210, label: 'Food Handler Health Clearance (food_handler)' },
  { value: 211, label: 'Fire Safety & Firefighting (fire_safety)' },
  { value: 212, label: 'Driving License Category B (driving_license_b)' },
  { value: 213, label: 'Driving License Category C (driving_license_c)' },
  { value: 214, label: 'Driving License Category D (driving_license_d)' },
  { value: 215, label: 'Driving License Category F (driving_license_f)' },
  { value: 216, label: 'Engineering Professional License (engineering_license)' },
  { value: 299, label: 'Other Certification (other)' }
];

// LANGUAGE_CATALOG (Schema line 279)
const languageCatalogOptions = [
  { value: 301, label: 'Amharic (amharic)' },
  { value: 302, label: 'English (english)' },
  { value: 303, label: 'Afaan Oromo (afaan_oromo)' },
  { value: 304, label: 'Tigrinya (tigrinya)' },
  { value: 305, label: 'Somali (somali)' },
  { value: 306, label: 'Arabic (arabic)' },
  { value: 307, label: 'Sidama (sidama)' },
  { value: 308, label: 'Wolaytta (wolaytta)' },
  { value: 309, label: 'Hadiyya (hadiyya)' },
  { value: 310, label: 'Afar (afar)' },
  { value: 311, label: 'French (french)' },
  { value: 399, label: 'Other Language (other)' }
];

// ─── Master Form State (Schema lines 1152–1176 - Zero Manual Code Input) ───
const form = ref({
  job_title_id: 12,
  job_level_id: 2,
  entity_id: 3,
  organization_unit_id: 1,
  job_grade_id: 5,
  reports_to_position_id: 30 as number | null,
  authorized_headcount: 1,
  is_key_position: false,
  guarantee_required_amount: '',
  description: ''
});

// ─── Dynamic Requirements Row Model (JobPositionRequirement lines 1177–1201) ───
export interface PositionRequirementRow {
  id: number;
  requirement_type: string; // POSITION_REQUIREMENT_TYPE: qualification | certification | skill | experience_years | language | age_min | age_max | physical_ability | driving_license
  required_lookup_value_id?: number | string | null; // FK LookupValue (SKILL_CATALOG / CERTIFICATION_CATALOG / LANGUAGE_CATALOG)
  field_of_study_id?: number | string | null; // FK FieldOfStudy for qualifications
  description: string;
  min_value: number | string;
  max_value?: number | string;
  is_mandatory: boolean;
  weight: number | string;
}

// Seeded standard initial requirements matching Schema lines 1194–1200
const requirementsList = ref<PositionRequirementRow[]>([
  {
    id: 1,
    requirement_type: 'qualification',
    required_lookup_value_id: null,
    field_of_study_id: 3,
    description: 'BSc Accounting / Finance or related discipline',
    min_value: '',
    max_value: '',
    is_mandatory: true,
    weight: 30
  },
  {
    id: 2,
    requirement_type: 'experience_years',
    required_lookup_value_id: null,
    field_of_study_id: null,
    description: '3+ years corporate finance or accounting experience',
    min_value: 3,
    max_value: '',
    is_mandatory: true,
    weight: 25
  },
  {
    id: 3,
    requirement_type: 'skill',
    required_lookup_value_id: 102,
    field_of_study_id: null,
    description: 'Peachtree / ERP general ledger posting proficiency',
    min_value: 3,
    max_value: '',
    is_mandatory: true,
    weight: 20
  },
  {
    id: 4,
    requirement_type: 'language',
    required_lookup_value_id: 301,
    field_of_study_id: null,
    description: 'Amharic fluent + Professional English (B2/C1)',
    min_value: '',
    max_value: '',
    is_mandatory: true,
    weight: 15
  },
  {
    id: 5,
    requirement_type: 'certification',
    required_lookup_value_id: 201,
    field_of_study_id: null,
    description: 'ACCA / CPA accredited standing (preferred)',
    min_value: '',
    max_value: '',
    is_mandatory: false,
    weight: 10
  }
]);
const selectedReqIds = ref<number[]>([]);

// ─── Expand Row Modal State ───
const showReqModal = ref(false);
const activeReqRow = ref<PositionRequirementRow | null>(null);

// ─── Sub-table Selection Management ───
const isAllReqsSelected = computed(() => {
  return requirementsList.value.length > 0 && requirementsList.value.every(r => selectedReqIds.value.includes(r.id));
});

const toggleSelectAllReqs = () => {
  if (isAllReqsSelected.value) {
    selectedReqIds.value = [];
  } else {
    selectedReqIds.value = requirementsList.value.map(r => r.id);
  }
};

const toggleReqSelection = (id: number) => {
  const idx = selectedReqIds.value.indexOf(id);
  if (idx > -1) {
    selectedReqIds.value.splice(idx, 1);
  } else {
    selectedReqIds.value.push(id);
  }
};

// ─── Handler when requirement_type changes ───
const onReqTypeChange = (row: PositionRequirementRow) => {
  if (row.requirement_type === 'skill') {
    row.required_lookup_value_id = 101;
    row.field_of_study_id = null;
    row.description = 'IFRS Reporting & Financial Analysis';
    row.min_value = 3;
    row.max_value = '';
  } else if (row.requirement_type === 'certification') {
    row.required_lookup_value_id = 201;
    row.field_of_study_id = null;
    row.description = 'ACCA / CPA Certified Professional';
    row.min_value = '';
    row.max_value = '';
  } else if (row.requirement_type === 'driving_license') {
    row.required_lookup_value_id = 212;
    row.field_of_study_id = null;
    row.description = 'Valid Driving License Category B';
    row.min_value = '';
    row.max_value = '';
  } else if (row.requirement_type === 'language') {
    row.required_lookup_value_id = 301;
    row.field_of_study_id = null;
    row.description = 'Amharic fluent & business English communication';
    row.min_value = '';
    row.max_value = '';
  } else if (row.requirement_type === 'qualification') {
    row.required_lookup_value_id = null;
    row.field_of_study_id = 3;
    row.description = 'BSc Degree in Accounting / Finance or related discipline';
    row.min_value = '';
    row.max_value = '';
  } else if (row.requirement_type === 'experience_years') {
    row.required_lookup_value_id = null;
    row.field_of_study_id = null;
    row.description = 'Minimum relevant industry experience';
    row.min_value = 3;
    row.max_value = '';
  } else if (row.requirement_type === 'age_min') {
    row.required_lookup_value_id = null;
    row.field_of_study_id = null;
    row.description = 'Statutory minimum age requirement';
    row.min_value = 18;
    row.max_value = '';
  } else if (row.requirement_type === 'age_max') {
    row.required_lookup_value_id = null;
    row.field_of_study_id = null;
    row.description = 'Operational maximum age limit';
    row.min_value = '';
    row.max_value = 60;
  } else if (row.requirement_type === 'physical_ability') {
    row.required_lookup_value_id = null;
    row.field_of_study_id = null;
    row.description = 'Occupational fitness & health clearance';
    row.min_value = '';
    row.max_value = '';
  }
};

const syncCatalogueDescription = (row: PositionRequirementRow) => {
  if (row.requirement_type === 'skill' && row.required_lookup_value_id) {
    const s = skillCatalogOptions.find(opt => opt.value === row.required_lookup_value_id);
    if (s) row.description = s.label.split(' (')[0];
  } else if ((row.requirement_type === 'certification' || row.requirement_type === 'driving_license') && row.required_lookup_value_id) {
    const c = certCatalogOptions.find(opt => opt.value === row.required_lookup_value_id);
    if (c) row.description = c.label.split(' (')[0];
  } else if (row.requirement_type === 'language' && row.required_lookup_value_id) {
    const l = languageCatalogOptions.find(opt => opt.value === row.required_lookup_value_id);
    if (l) row.description = `${l.label.split(' (')[0]} (Fluent Proficiency)`;
  } else if (row.requirement_type === 'qualification' && row.field_of_study_id) {
    const f = fieldOfStudyOptions.find(opt => opt.value === row.field_of_study_id);
    if (f) row.description = `BSc / BA in ${f.label.split(' (')[0]}`;
  }
};

// ─── Sub-table Actions ───
const addRequirementRow = () => {
  const newId = Date.now();
  requirementsList.value.push({
    id: newId,
    requirement_type: 'qualification',
    required_lookup_value_id: null,
    field_of_study_id: 3,
    description: 'BSc Accounting / Finance or related field',
    min_value: '',
    max_value: '',
    is_mandatory: true,
    weight: 20
  });
  showToast('New requirement row added.');
};

const removeReqRow = (id: number) => {
  requirementsList.value = requirementsList.value.filter(r => r.id !== id);
  selectedReqIds.value = selectedReqIds.value.filter(rid => rid !== id);
  showToast('Requirement removed.');
};

const handleBatchDeleteReqs = () => {
  const toDelete = new Set(selectedReqIds.value);
  requirementsList.value = requirementsList.value.filter(r => !toDelete.has(r.id));
  selectedReqIds.value = [];
  showToast('Selected requirements deleted.');
};

const openReqModal = (row: PositionRequirementRow) => {
  activeReqRow.value = row;
  showReqModal.value = true;
};

const closeReqModal = () => {
  showReqModal.value = false;
  activeReqRow.value = null;
};

// Total scoring weight
const totalWeight = computed(() => {
  return requirementsList.value.reduce((sum, r) => sum + (Number(r.weight) || 0), 0);
});

// ─── Global Save & Clear ───
const handleSave = () => {
  if (!form.value.job_title_id) {
    showToast('Please select Job Title.');
    activeTab.value = 'position';
    return;
  }
  if (!form.value.organization_unit_id) {
    showToast('Please select Organization Unit.');
    activeTab.value = 'position';
    return;
  }

  const selectedTitle = jobTitleOptions.find(t => t.value === form.value.job_title_id);
  const selectedLevel = jobLevelOptions.find(l => l.value === form.value.job_level_id);
  const titleName = selectedTitle ? selectedTitle.label.split(' (')[0] : 'Position Seat';
  const levelName = selectedLevel ? selectedLevel.label.split(' (')[0] : 'Officer';

  isSaved.value = true;
  showToast(`Job Position "${titleName} — ${levelName}" saved with ${requirementsList.value.length} requirements.`);

  setTimeout(() => {
    router.push('/hr/job-positions');
  }, 1200);
};

const clearForm = () => {
  form.value = {
    job_title_id: 12,
    job_level_id: 2,
    entity_id: 3,
    organization_unit_id: 1,
    job_grade_id: 5,
    reports_to_position_id: 30,
    authorized_headcount: 1,
    is_key_position: false,
    guarantee_required_amount: '',
    description: ''
  };
  requirementsList.value = [];
  selectedReqIds.value = [];
  isSaved.value = false;
  showToast('Form cleared.');
};

const showToast = (msg: string) => {
  quickActionToast.value = msg;
  setTimeout(() => {
    quickActionToast.value = null;
  }, 4000);
};

// ─── Mounted: Hydrate from Route Query if navigated from Quick Create ───
onMounted(() => {
  if (route.query.title_id) form.value.job_title_id = Number(route.query.title_id);
  if (route.query.level_id) form.value.job_level_id = Number(route.query.level_id);
  if (route.query.entity_id) form.value.entity_id = Number(route.query.entity_id);
  if (route.query.unit_id) form.value.organization_unit_id = Number(route.query.unit_id);
  if (route.query.grade_id) form.value.job_grade_id = Number(route.query.grade_id);
  if (route.query.reports_to_id) form.value.reports_to_position_id = Number(route.query.reports_to_id);
  if (route.query.headcount) form.value.authorized_headcount = Number(route.query.headcount);
});
</script>

<template>
  <div class="job-position-create-page">
    <!-- Top Action & Breadcrumb Navigation Bar (Exact Critic Standard) -->
    <div class="create-header-bar">
      <div class="header-left">
        <div class="breadcrumb-strip">
          <router-link to="/home" class="bc-home-icon" title="Home">
            <Monitor :size="15" />
          </router-link>
          <ChevronRight :size="13" class="bc-sep" />
          <router-link to="/hr/job-positions" class="bc-link">Job Positions</router-link>
          <ChevronRight :size="13" class="bc-sep" />
          <span class="bc-current">Create Job Position</span>
          <span :class="['state-pill', isSaved ? 'state-saved' : 'state-unsaved']">
            {{ isSaved ? 'Saved' : 'Not Saved' }}
          </span>
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

    <!-- Capsule Tabs Navigation Standard (<BaseTabs />) -->
    <div class="create-tabs-wrapper">
      <BaseTabs 
        v-model="activeTab"
        :tabs="tabs"
        size="md"
      />
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 1: POSITION DETAILS (JobPosition lines 1152–1176)          -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'position'" class="tab-content-container">
      <div class="clean-card">
        <div class="section-title-box">
          <h2 class="section-title">Position Seat Specifications</h2>
        </div>

        <!-- 3-Column Responsive Grid (Rule 16: Zero Code Input) -->
        <div class="form-grid-3">
          <!-- Job Title from Catalogue: FK job_title_id -->
          <FormSelect
            label="Job Title"
            v-model="form.job_title_id"
            placeholder="Select"
            :options="jobTitleOptions"
            required
          />

          <!-- Seniority Level: FK job_level_id -->
          <FormSelect
            label="Seniority Level"
            v-model="form.job_level_id"
            placeholder="Select"
            :options="jobLevelOptions"
            required
          />

          <!-- Owning Entity / Branch: FK entity_id (Schema line 1157) -->
          <FormSelect
            label="Owning Entity / Branch"
            v-model="form.entity_id"
            placeholder="Select"
            :options="entityOptions"
            required
          />

          <!-- Organization Unit Placement: FK organization_unit_id -->
          <FormSelect
            label="Organization Unit"
            v-model="form.organization_unit_id"
            placeholder="Select"
            :options="orgUnitOptions"
            required
          />

          <!-- Pay Grade: FK job_grade_id -->
          <FormSelect
            label="Job Grade"
            v-model="form.job_grade_id"
            placeholder="Select"
            :options="jobGradeOptions"
            required
          />

          <!-- Reports To Position: FK reports_to_position_id -->
          <FormSelect
            label="Reports To Position"
            v-model="form.reports_to_position_id"
            placeholder="Select"
            :options="reportsToOptions"
          />

          <!-- Authorized Headcount -->
          <FormInput
            label="Authorized Headcount (Seats)"
            v-model="form.authorized_headcount"
            type="number"
            required
          />
        </div>

        <!-- Guarantee / Surety Row (Cashier / Storekeeper surety bonds) -->
        <div class="guarantee-row mt-4">
          <div class="form-grid-3">
            <FormInput
              label="Guarantee Required Amount (ETB)"
              v-model="form.guarantee_required_amount"
              type="number"
            />
          </div>
          <p class="field-helper-note">
            Required surety bond posted before taking the seat (e.g., cashier or warehouse storekeeper), validated against EmployeeGuarantee.
          </p>
        </div>

        <!-- Key Succession Position Checkbox: Rule 5 (Both Title & Description) -->
        <div class="checkbox-row mt-4">
          <FormCheckbox
            v-model="form.is_key_position"
            label="Key Succession Position"
            description="Flags this position as critical in succession coverage reporting. Audits require a designated emergency or planned successor."
          />
        </div>

        <!-- Strategic Job Summary Rich Text Editor (Rule 18 Standard) -->
        <div class="biography-section mt-5">
          <label class="gc-field-label">Job Purpose & Operational Scope</label>

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
    <!-- TAB 2: REQUIREMENTS (JobPositionRequirement lines 1177–1201)   -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'requirements'" class="tab-content-container">
      <div class="clean-card">
        <!-- Accordion Title -->
        <div 
          class="section-accordion-header" 
          @click="isRequirementsOpen = !isRequirementsOpen"
        >
          <div class="accordion-title-left">
            <span class="accordion-title-text">Position Qualification & Skill Requirements</span>
            <span class="badge-count">{{ requirementsList.length }} Requirements</span>
            <span v-if="totalWeight > 0" class="badge-weight font-mono">Weight: {{ totalWeight }}%</span>
          </div>
          <ChevronDown 
            :size="15" 
            class="accordion-chevron"
            :class="{ 'rotate-180': !isRequirementsOpen }" 
          />
        </div>

        <div v-show="isRequirementsOpen" class="accordion-body-content mt-3">
          <!-- Dynamic Child Sub-Table -->
          <div class="child-table-wrapper">
            <table class="child-table">
              <thead>
                <tr class="child-table-header">
                  <th class="child-th child-th-check">
                    <input 
                      type="checkbox" 
                      class="table-checkbox" 
                      :checked="isAllReqsSelected"
                      @change="toggleSelectAllReqs"
                    />
                  </th>
                  <th class="child-th child-th-no">No.</th>
                  <th class="child-th" style="width: 170px;">Requirement Type</th>
                  <th class="child-th">Description / Specification</th>
                  <th class="child-th" style="width: 120px;">Min Threshold</th>
                  <th class="child-th text-center" style="width: 110px;">Mandatory</th>
                  <th class="child-th" style="width: 110px;">Weight (%)</th>
                  <th class="child-th child-th-col-icon">
                    <Columns :size="14" class="text-slate-400" />
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr 
                  v-for="(row, idx) in requirementsList" 
                  :key="row.id" 
                  class="child-table-row"
                  :class="{ 'child-row-selected': selectedReqIds.includes(row.id) }"
                >
                  <td class="child-td child-td-check">
                    <input 
                      type="checkbox" 
                      class="table-checkbox" 
                      :checked="selectedReqIds.includes(row.id)"
                      @change="toggleReqSelection(row.id)"
                    />
                  </td>
                  <td class="child-td child-td-no">{{ idx + 1 }}</td>

                  <!-- Requirement Type (all 9 options from Schema line 1181) -->
                  <td class="child-td">
                    <select 
                      v-model="row.requirement_type" 
                      class="child-inline-select"
                      @change="onReqTypeChange(row)"
                    >
                      <option v-for="opt in requirementTypeOptions" :key="opt.value" :value="opt.value">
                        {{ opt.label.split(' (')[0] }}
                      </option>
                    </select>
                  </td>

                  <!-- Description / Specification -->
                  <td class="child-td">
                    <input 
                      type="text" 
                      v-model="row.description" 
                      class="child-inline-input"
                    />
                  </td>

                  <!-- Min Threshold -->
                  <td class="child-td">
                    <input 
                      type="number" 
                      v-model="row.min_value" 
                      class="child-inline-input"
                    />
                  </td>

                  <!-- Mandatory Checkbox -->
                  <td class="child-td text-center">
                    <input 
                      type="checkbox" 
                      v-model="row.is_mandatory" 
                      class="custom-checkbox"
                    />
                  </td>

                  <!-- Scoring Weight -->
                  <td class="child-td">
                    <input 
                      type="number" 
                      v-model.number="row.weight" 
                      class="child-inline-input"
                    />
                  </td>

                  <!-- Action Buttons -->
                  <td class="child-td child-td-actions">
                    <div class="row-actions-group">
                      <button 
                        type="button" 
                        class="btn-row-expand" 
                        title="Expand Details" 
                        @click="openReqModal(row)"
                      >
                        <Maximize2 :size="13" />
                      </button>
                      <button 
                        type="button" 
                        class="btn-row-remove" 
                        title="Remove" 
                        @click="removeReqRow(row.id)"
                      >
                        <Trash2 :size="13" />
                      </button>
                    </div>
                  </td>
                </tr>

                <!-- Empty State -->
                <tr v-if="requirementsList.length === 0">
                  <td colspan="8" class="child-td-empty">
                    <span>No Row</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Bottom Action: + Add Requirement -->
          <div class="add-row-action-bar">
            <button 
              type="button" 
              class="btn-add-row" 
              @click="addRequirementRow"
            >
              <Plus :size="13" />
              <span>Add Requirement</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Floating Batch Action Bar -->
    <TableFloatingBar 
      :count="selectedReqIds.length" 
      @delete="handleBatchDeleteReqs" 
    />

    <!-- EXPAND ROW MODAL (Standard Haleta ERP Pattern) -->
    <div v-if="showReqModal && activeReqRow" class="row-modal-overlay" @click="closeReqModal">
      <div class="row-modal-container" @click.stop>
        <div class="row-modal-header">
          <h3 class="row-modal-title">Position Requirement Specification</h3>
          <button type="button" class="btn-modal-close" @click="closeReqModal">
            <X :size="16" />
          </button>
        </div>

        <div class="row-modal-body">
          <div class="modal-form-grid">
            <!-- 1. Requirement Type (FK requirement_type_lookup_value_id: All 9 options from Schema line 1181) -->
            <div class="modal-form-group">
              <label class="modal-field-label">Requirement Type (FK requirement_type_lookup_value_id) <span class="required-star">*</span></label>
              <select 
                v-model="activeReqRow.requirement_type" 
                class="child-inline-select"
                @change="onReqTypeChange(activeReqRow)"
              >
                <option v-for="opt in requirementTypeOptions" :key="opt.value" :value="opt.value">
                  {{ opt.label }}
                </option>
              </select>
            </div>

            <!-- Scoring Weight -->
            <div class="modal-form-group">
              <label class="modal-field-label">Scoring Weight (0–100%)</label>
              <input 
                type="number" 
                v-model.number="activeReqRow.weight" 
                class="child-inline-input"
              />
            </div>

            <!-- 2. Catalogue Value Selector (FK required_lookup_value_id): Skill Catalogue -->
            <div v-if="activeReqRow.requirement_type === 'skill'" class="modal-form-group col-span-2">
              <label class="modal-field-label">Catalogue Value (FK required_lookup_value_id: SKILL_CATALOG) <span class="required-star">*</span></label>
              <select 
                v-model="activeReqRow.required_lookup_value_id" 
                class="child-inline-select" 
                @change="syncCatalogueDescription(activeReqRow)"
              >
                <option :value="null">Select Skill from SKILL_CATALOG</option>
                <option v-for="skill in skillCatalogOptions" :key="skill.value" :value="skill.value">
                  {{ skill.label }}
                </option>
              </select>
              <span class="field-helper-hint">Joins PartySkill.skill_lookup_value_id for candidate matching and talent gap analysis.</span>
            </div>

            <!-- 2. Catalogue Value Selector (FK required_lookup_value_id): Certification Catalogue -->
            <div v-else-if="activeReqRow.requirement_type === 'certification' || activeReqRow.requirement_type === 'driving_license'" class="modal-form-group col-span-2">
              <label class="modal-field-label">Catalogue Value (FK required_lookup_value_id: CERTIFICATION_CATALOG) <span class="required-star">*</span></label>
              <select 
                v-model="activeReqRow.required_lookup_value_id" 
                class="child-inline-select" 
                @change="syncCatalogueDescription(activeReqRow)"
              >
                <option :value="null">Select Certification / License from CERTIFICATION_CATALOG</option>
                <option v-for="cert in certCatalogOptions" :key="cert.value" :value="cert.value">
                  {{ cert.label }}
                </option>
              </select>
              <span class="field-helper-hint">Joins PartyCertification.certification_lookup_value_id for applicant credential verification.</span>
            </div>

            <!-- 2. Catalogue Value Selector (FK required_lookup_value_id): Language Catalogue -->
            <div v-else-if="activeReqRow.requirement_type === 'language'" class="modal-form-group col-span-2">
              <label class="modal-field-label">Catalogue Value (FK required_lookup_value_id: LANGUAGE_CATALOG) <span class="required-star">*</span></label>
              <select 
                v-model="activeReqRow.required_lookup_value_id" 
                class="child-inline-select" 
                @change="syncCatalogueDescription(activeReqRow)"
              >
                <option :value="null">Select Language from LANGUAGE_CATALOG</option>
                <option v-for="lang in languageCatalogOptions" :key="lang.value" :value="lang.value">
                  {{ lang.label }}
                </option>
              </select>
              <span class="field-helper-hint">Joins PartyLanguage.language_lookup_value_id for linguistic proficiency evaluation.</span>
            </div>

            <!-- Field of Study: FK field_of_study_id for Academic Qualification -->
            <div v-else-if="activeReqRow.requirement_type === 'qualification'" class="modal-form-group col-span-2">
              <label class="modal-field-label">Field of Study Discipline (FK field_of_study_id)</label>
              <select 
                v-model="activeReqRow.field_of_study_id" 
                class="child-inline-select" 
                @change="syncCatalogueDescription(activeReqRow)"
              >
                <option :value="null">Select Academic Field of Study</option>
                <option v-for="fos in fieldOfStudyOptions" :key="fos.value" :value="fos.value">
                  {{ fos.label }}
                </option>
              </select>
              <span class="field-helper-hint">Joins PartyQualification.field_of_study_id for educational qualification matching.</span>
            </div>

            <!-- Specification / Description (description jsonb) -->
            <div class="modal-form-group col-span-2">
              <label class="modal-field-label">Requirement Title / Specification (description jsonb) <span class="required-star">*</span></label>
              <input 
                type="text" 
                v-model="activeReqRow.description" 
                class="child-inline-input"
              />
            </div>

            <!-- Adaptive Thresholds (min_value & max_value) -->
            <div class="modal-form-group">
              <label class="modal-field-label">
                {{ 
                  activeReqRow.requirement_type === 'experience_years' ? 'Minimum Experience (Years)' : 
                  activeReqRow.requirement_type === 'age_min' ? 'Minimum Age (Years)' : 
                  (activeReqRow.requirement_type === 'skill' || activeReqRow.requirement_type === 'language') ? 'Min Proficiency Level (1-4)' : 
                  'Minimum Threshold (min_value)' 
                }}
              </label>
              <input 
                type="number" 
                v-model="activeReqRow.min_value" 
                class="child-inline-input"
              />
            </div>

            <div class="modal-form-group">
              <label class="modal-field-label">
                {{ 
                  activeReqRow.requirement_type === 'age_max' ? 'Maximum Age Threshold (Years)' : 
                  'Maximum Threshold (max_value)' 
                }}
              </label>
              <input 
                type="number" 
                v-model="activeReqRow.max_value" 
                class="child-inline-input"
              />
            </div>

            <!-- Mandatory Checkbox with Rule 5 Title & Business Description -->
            <div class="modal-form-group col-span-2 mt-2">
              <FormCheckbox
                v-model="activeReqRow.is_mandatory"
                label="Mandatory Requirement (is_mandatory: Must Have)"
                description="When enabled, applicant matching hard-filters applications lacking this requirement before scoring. Nice-to-have requirements contribute only to ranking weight."
              />
            </div>
          </div>
        </div>

        <div class="row-modal-footer">
          <button type="button" class="btn-done" @click="closeReqModal">
            Done
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.job-position-create-page {
  padding: 16px 24px 80px 24px;
  background-color: var(--primitive-color-neutral-50, #f8fafc);
  min-height: 100vh;
  box-sizing: border-box;
}

/* Top Header Bar */
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
  color: #cbd5e1;
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
  margin-left: 4px;
}

.state-unsaved {
  background-color: #fffbeb;
  color: #d97706;
}

.state-saved {
  background-color: #ecfdf5;
  color: #059669;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.btn-clear-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  color: #404040;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-clear-action:hover {
  background-color: #f1f5f9;
}

.btn-save-action {
  display: inline-flex;
  align-items: center;
  height: 38px;
  padding: 0 24px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-save-action:hover {
  background-color: #09427d;
}

/* Toast */
.quick-toast-banner {
  background-color: #ecfdf5;
  border: 1px solid #a7f3d0;
  color: #065f46;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 13px;
  margin-bottom: 16px;
}

/* Tabs */
.create-tabs-wrapper {
  margin-bottom: 20px;
}

.tab-content-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.clean-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 20px 24px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
}

.section-title-box {
  margin-bottom: 16px;
}

.section-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
}

@media (max-width: 900px) {
  .form-grid-3 {
    grid-template-columns: 1fr;
  }
}

.field-helper-note {
  font-size: 12px;
  color: #737373;
  margin: 6px 0 0 0;
}

.gc-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

/* Rich Editor */
.rich-editor-container {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  margin-top: 6px;
}

.editor-toolbar {
  display: flex;
  align-items: center;
  gap: 4px;
  background-color: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
  padding: 6px 10px;
}

.toolbar-dropdown {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #404040;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
}

.toolbar-dropdown:hover {
  background-color: #edf2f7;
}

.toolbar-divider {
  width: 1px;
  height: 18px;
  background-color: #e2e8f0;
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
  background: transparent;
  border: none;
  border-radius: 4px;
  color: #404040;
  font-size: 12px;
  cursor: pointer;
}

.editor-icon-btn:hover {
  background-color: #e2e8f0;
}

.editor-color-box {
  width: 16px;
  height: 16px;
  background-color: #404040;
  border: 1px solid #cbd5e1;
  border-radius: 3px;
  margin: 0 4px;
  cursor: pointer;
}

.editor-textarea {
  width: 100%;
  border: none;
  outline: none;
  padding: 12px;
  font-size: 13.5px;
  color: #404040;
  box-sizing: border-box;
  font-family: inherit;
  resize: vertical;
}

.editor-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 12px;
  background-color: #fafafa;
  border-top: 1px solid #f1f5f9;
}

.char-count-pill {
  font-size: 11px;
  color: #737373;
}

.editor-resize-handle {
  font-size: 10px;
  color: #cbd5e1;
  cursor: se-resize;
  user-select: none;
}

/* Accordion Section */
.section-accordion-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: pointer;
  user-select: none;
}

.accordion-title-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.accordion-title-text {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.badge-count {
  background: #f1f5f9;
  color: #64748b;
  font-size: 11.5px;
  font-weight: 500;
  padding: 2px 8px;
  border-radius: 9999px;
}

.badge-weight {
  background: #ecfdf5;
  color: #059669;
  font-size: 11.5px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 9999px;
}

.accordion-chevron {
  color: #94a3b8;
  transition: transform 0.2s ease;
}

/* Sub-Table */
.child-table-wrapper {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  margin-top: 12px;
}

.child-table {
  width: 100%;
  border-collapse: collapse;
}

.child-table-header {
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
}

.child-th {
  height: 34px;
  padding: 6px 12px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  text-align: left;
}

.child-th-check {
  width: 40px;
  text-align: center;
}

.child-th-no {
  width: 50px;
  text-align: center;
}

.child-th-col-icon {
  width: 70px;
  text-align: center;
}

.child-table-row {
  height: 42px;
  border-bottom: 1px solid #f1f5f9;
}

.child-table-row:hover {
  background-color: #f8fafc;
}

.child-row-selected {
  background-color: #f0f7ff;
}

.child-td {
  padding: 6px 12px;
  font-size: 13px;
  color: #404040;
}

.child-td-check, .child-td-no {
  text-align: center;
}

.child-inline-select, .child-inline-input {
  height: 32px;
  padding: 0 8px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 13px;
  color: #404040;
  background: #ffffff;
  outline: none;
  width: 100%;
  box-sizing: border-box;
}

.child-inline-select:focus, .child-inline-input:focus {
  border-color: #0B529C;
}

.custom-checkbox {
  width: 16px;
  height: 16px;
  cursor: pointer;
  accent-color: #0B529C;
  border-radius: 4px;
}

.row-actions-group {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
}

.btn-row-expand, .btn-row-remove {
  width: 24px;
  height: 24px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  border-radius: 4px;
  cursor: pointer;
  color: #94a3b8;
}

.btn-row-expand:hover {
  background-color: #e0f2fe;
  color: #0284c7;
}

.btn-row-remove:hover {
  background-color: #fee2e2;
  color: #ef4444;
}

.child-td-empty {
  text-align: center;
  padding: 24px 0;
  color: #737373;
  font-size: 13px;
}

.add-row-action-bar {
  margin-top: 10px;
}

.btn-add-row {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 12px;
  border: 1px dashed #cbd5e1;
  background-color: #ffffff;
  color: #404040;
  border-radius: 6px;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
}

.btn-add-row:hover {
  border-color: #0B529C;
  color: #0B529C;
}

/* Expand Modal (Haleta Standard from EmployeeCreate) */
.row-modal-overlay {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
  padding: 16px;
}

.row-modal-container {
  background-color: #ffffff;
  border-radius: 12px;
  width: 100%;
  max-width: 600px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.row-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 24px;
  border-bottom: 1px solid #e2e8f0;
}

.row-modal-title {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #404040;
}

.btn-modal-close {
  border: none;
  background: transparent;
  color: #94a3b8;
  cursor: pointer;
}

.row-modal-body {
  padding: 20px 24px;
}

.modal-form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
}

.col-span-2 {
  grid-column: span 2;
}

.modal-form-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.modal-field-label {
  font-size: 12px;
  font-weight: 500;
  color: #404040;
}

.required-star {
  color: #e11d48;
}

.row-modal-footer {
  display: flex;
  justify-content: flex-end;
  padding: 14px 24px;
  border-top: 1px solid #e2e8f0;
  background-color: #f8fafc;
}

.btn-done {
  height: 34px;
  padding: 0 20px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-done:hover {
  background-color: #09427d;
}

.field-helper-hint {
  font-size: 11px;
  color: #737373;
  margin-top: 3px;
}
</style>
