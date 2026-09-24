<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Briefcase, Plus, Search, Filter, ArrowUpDown, ChevronDown, 
  MoreVertical, Edit2, Trash2, Eye, Copy, Check, Calendar, 
  CheckCircle2, AlertCircle, Maximize2, X, DollarSign,
  Layers, ChevronRight, ShieldAlert, GraduationCap, Award, FolderTree
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

const router = useRouter();

// ─── Lookups & Types (HR_Schema_final-v4.sql lines 1152–1201) ───
export type RowState = 'active' | 'inactive';

export interface PositionRequirementItem {
  id: number;
  requirement_type: string;
  required_lookup_value_id?: number | null;
  catalogue_code?: string | null;
  field_of_study_id?: number | null;
  description: string;
  min_value?: number | null;
  max_value?: number | null;
  is_mandatory: boolean;
  weight?: number | null;
}

export interface JobPositionRecord {
  id: number;
  uuid: string;
  code: string;
  job_title_id: number;
  title_name: string;
  job_level_id: number;
  level_name: string;
  full_name: string;
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  organization_unit_id: number;
  organization_unit_name: string;
  job_grade_id: number;
  job_grade_name: string;
  reports_to_position_id?: number | null;
  reports_to_title?: string | null;
  authorized_headcount: number;
  filled_headcount: number;
  is_key_position: boolean;
  guarantee_required_amount?: number | null;
  requirements_count: number;
  requirements: PositionRequirementItem[];
  state: RowState;
}

// ─── Breadcrumbs (Rule: Exact Page Name from Sidebar Only, Zero Section Titles) ───
const breadcrumbItems = [
  { label: 'Job Positions' }
];

// ─── State Management ───
const searchQuery = ref('');
const filterUnit = ref('All');
const filterGrade = ref('All');
const filterKeyPos = ref('All');
const filterState = ref('All');
const currentSort = ref('name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const showQuickCreate = ref(false);
const showDetailModal = ref(false);
const selectedPositionForDetail = ref<JobPositionRecord | null>(null);
const quickActionToast = ref<string | null>(null);

// ─── Table Columns (Strict Single-Information & Name-First Hierarchy) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Position Seat', visible: true, sortable: true },
  { key: 'org_unit', label: 'Organization Unit', visible: true, sortable: true },
  { key: 'job_grade', label: 'Pay Grade', visible: true, sortable: true },
  { key: 'headcount', label: 'Authorized Headcount', visible: true, sortable: true },
  { key: 'reports_to', label: 'Reports To', visible: true, sortable: true },
  { key: 'is_key', label: 'Key Position', visible: true, sortable: true },
  { key: 'guarantee', label: 'Surety / Guarantee', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

// ─── Mock Data Aligned with HR_Schema_final-v4.sql lines 1169–1201 ───
const jobPositions = ref<JobPositionRecord[]>([
  {
    id: 12,
    uuid: 'pos-uuid-012',
    code: 'POS-HR-002',
    title_name: 'HR Officer',
    level_name: 'Officer',
    full_name: 'HR Officer — Officer',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    organization_unit_id: 104,
    organization_unit_name: 'Human Resources',
    job_grade_id: 5,
    job_grade_name: 'Grade B2',
    reports_to_position_id: 10,
    reports_to_title: 'HR Director',
    authorized_headcount: 2,
    filled_headcount: 2,
    is_key_position: false,
    guarantee_required_amount: null,
    requirements_count: 3,
    state: 'active',
    requirements: [
      { id: 1, requirement_type: 'qualification', field_of_study_id: 9, description: 'BA in Human Resources Management', is_mandatory: true, weight: 35 },
      { id: 2, requirement_type: 'experience_years', description: '2+ years relevant HR experience', min_value: 2, is_mandatory: true, weight: 35 },
      { id: 3, requirement_type: 'language', required_lookup_value_id: 301, catalogue_code: 'LANGUAGE_CATALOG: amharic', description: 'Fluent Amharic & Working English', is_mandatory: true, weight: 30 }
    ]
  },
  {
    id: 24,
    uuid: 'pos-uuid-024',
    code: 'POS-CSH-004',
    title_name: 'Senior Cashier',
    level_name: 'Senior',
    full_name: 'Senior Cashier — Senior',
    tenant_id: 1,
    entity_id: 7,
    entity_name: 'Haleta Grand Hotel & Suites',
    organization_unit_id: 109,
    organization_unit_name: 'Commercial Sales & Front Office',
    job_grade_id: 4,
    job_grade_name: 'Grade C2',
    reports_to_position_id: 20,
    reports_to_title: 'Finance Manager',
    authorized_headcount: 4,
    filled_headcount: 3,
    is_key_position: false,
    guarantee_required_amount: 50000,
    requirements_count: 4,
    state: 'active',
    requirements: [
      { id: 4, requirement_type: 'qualification', field_of_study_id: 3, description: 'Diploma / BA in Accounting or Banking', is_mandatory: true, weight: 30 },
      { id: 5, requirement_type: 'experience_years', description: '3+ years commercial cash handling', min_value: 3, is_mandatory: true, weight: 30 },
      { id: 6, requirement_type: 'skill', required_lookup_value_id: 103, catalogue_code: 'SKILL_CATALOG: pos_operation', description: 'Point of Sale (POS) & ERP Cash Module', is_mandatory: true, weight: 20 },
      { id: 7, requirement_type: 'certification', required_lookup_value_id: 209, catalogue_code: 'CERTIFICATION_CATALOG: first_aid', description: 'First Aid & Safety Clearance', is_mandatory: true, weight: 20 }
    ]
  },
  {
    id: 30,
    uuid: 'pos-uuid-030',
    code: 'POS-FIN-001',
    title_name: 'Finance Manager',
    level_name: 'Manager',
    full_name: 'Finance Manager — Manager',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    organization_unit_id: 103,
    organization_unit_name: 'Finance & Corporate Services Division',
    job_grade_id: 7,
    job_grade_name: 'Grade A3',
    reports_to_position_id: null,
    reports_to_title: 'Chief Financial Officer',
    authorized_headcount: 1,
    filled_headcount: 1,
    is_key_position: true,
    guarantee_required_amount: null,
    requirements_count: 5,
    state: 'active',
    requirements: [
      { id: 8, requirement_type: 'qualification', field_of_study_id: 3, description: 'MSc / BSc in Accounting & Finance', is_mandatory: true, weight: 30 },
      { id: 9, requirement_type: 'experience_years', description: '6+ years corporate finance management', min_value: 6, is_mandatory: true, weight: 25 },
      { id: 10, requirement_type: 'certification', required_lookup_value_id: 201, catalogue_code: 'CERTIFICATION_CATALOG: acca', description: 'ACCA / CPA certified', is_mandatory: false, weight: 20 },
      { id: 11, requirement_type: 'skill', required_lookup_value_id: 101, catalogue_code: 'SKILL_CATALOG: ifrs_reporting', description: 'IFRS reporting & Treasury management', is_mandatory: true, weight: 15 },
      { id: 12, requirement_type: 'language', required_lookup_value_id: 302, catalogue_code: 'LANGUAGE_CATALOG: english', description: 'English professional fluency', is_mandatory: true, weight: 10 }
    ]
  },
  {
    id: 31,
    uuid: 'pos-uuid-031',
    code: 'POS-ACC-003',
    title_name: 'Financial Accountant',
    level_name: 'Senior',
    full_name: 'Financial Accountant — Senior',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    organization_unit_id: 106,
    organization_unit_name: 'General Accounting & Audit',
    job_grade_id: 5,
    job_grade_name: 'Grade B2',
    reports_to_position_id: 30,
    reports_to_title: 'Finance Manager',
    authorized_headcount: 3,
    filled_headcount: 2,
    is_key_position: false,
    guarantee_required_amount: null,
    requirements_count: 5,
    state: 'active',
    requirements: [
      { id: 13, requirement_type: 'qualification', field_of_study_id: 3, description: 'BSc Accounting / Finance', is_mandatory: true, weight: 30 },
      { id: 14, requirement_type: 'experience_years', description: '3+ years in a corporate finance role', min_value: 3, is_mandatory: true, weight: 25 },
      { id: 15, requirement_type: 'skill', required_lookup_value_id: 102, catalogue_code: 'SKILL_CATALOG: peachtree', description: 'Peachtree / QuickBooks / ERP GL', is_mandatory: true, weight: 20 },
      { id: 16, requirement_type: 'language', required_lookup_value_id: 301, catalogue_code: 'LANGUAGE_CATALOG: amharic', description: 'Amharic fluent + English B2', is_mandatory: true, weight: 15 },
      { id: 17, requirement_type: 'certification', required_lookup_value_id: 201, catalogue_code: 'CERTIFICATION_CATALOG: acca', description: 'ACCA / CPA (preferred)', is_mandatory: false, weight: 10 }
    ]
  },
  {
    id: 40,
    uuid: 'pos-uuid-040',
    code: 'POS-PRC-002',
    title_name: 'Procurement Officer',
    level_name: 'Officer',
    full_name: 'Procurement Officer — Officer',
    tenant_id: 1,
    entity_id: 9,
    entity_name: 'Haleta Hawassa Hub',
    organization_unit_id: 105,
    organization_unit_name: 'Procurement & Logistics Department',
    job_grade_id: 4,
    job_grade_name: 'Grade C2',
    reports_to_position_id: 38,
    reports_to_title: 'Operations Lead',
    authorized_headcount: 2,
    filled_headcount: 1,
    is_key_position: false,
    guarantee_required_amount: 20000,
    requirements_count: 3,
    state: 'active',
    requirements: [
      { id: 18, requirement_type: 'qualification', field_of_study_id: 15, description: 'BA in Supply Chain or Management', is_mandatory: true, weight: 40 },
      { id: 19, requirement_type: 'experience_years', description: '2+ years vendor procurement', min_value: 2, is_mandatory: true, weight: 35 },
      { id: 20, requirement_type: 'skill', required_lookup_value_id: 105, catalogue_code: 'SKILL_CATALOG: supplier_negotiation', description: 'Public procurement directives & vendor negotiation', is_mandatory: true, weight: 25 }
    ]
  }
]);

// ─── Catalogue Options (FK Selects conforming to Schema lines 1152-1176) ───
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

const entityOptions = [
  { value: 1, label: 'QMT Business Group (HQ)' },
  { value: 3, label: 'Haleta Addis Ababa HQ' },
  { value: 7, label: 'Haleta Grand Hotel & Suites' },
  { value: 9, label: 'Haleta Hawassa Hub' }
];

const reportsToOptions = [
  { value: 30, label: 'Finance Manager (POS-FIN-001)' },
  { value: 11, label: 'HR Director (POS-HR-001)' },
  { value: 38, label: 'Operations Lead (POS-OPS-001)' },
  { value: 20, label: 'Commercial Sales Lead (POS-SALES-001)' }
];

// ─── Quick Create Form State (Strictly Using FK IDs) ───
const quickForm = ref({
  job_title_id: 12,
  job_level_id: 2,
  entity_id: 3,
  organization_unit_id: 1,
  job_grade_id: 5,
  reports_to_position_id: 30 as number | null,
  authorized_headcount: 1,
  is_key_position: false,
  guarantee_required_amount: ''
});

// ─── Filter & Search Logic ───
const activeFilterCount = computed(() => {
  let count = 0;
  if (filterUnit.value !== 'All') count++;
  if (filterGrade.value !== 'All') count++;
  if (filterKeyPos.value !== 'All') count++;
  if (filterState.value !== 'All') count++;
  return count;
});

const filteredJobPositions = computed(() => {
  return jobPositions.value.filter(p => {
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase();
      const matchTitle = p.title_name.toLowerCase().includes(q);
      const matchCode = p.code.toLowerCase().includes(q);
      const matchUnit = p.organization_unit_name.toLowerCase().includes(q);
      if (!matchTitle && !matchCode && !matchUnit) return false;
    }
    if (filterUnit.value !== 'All' && p.organization_unit_name !== filterUnit.value) return false;
    if (filterGrade.value !== 'All' && p.job_grade_name !== filterGrade.value) return false;
    if (filterKeyPos.value !== 'All' && (p.is_key_position ? 'Yes' : 'No') !== filterKeyPos.value) return false;
    if (filterState.value !== 'All' && p.state !== filterState.value.toLowerCase()) return false;
    return true;
  }).sort((a, b) => {
    let valA = a[currentSort.value as keyof JobPositionRecord];
    let valB = b[currentSort.value as keyof JobPositionRecord];
    if (valA === undefined || valA === null) valA = '';
    if (valB === undefined || valB === null) valB = '';
    if (valA < valB) return sortOrder.value === 'asc' ? -1 : 1;
    if (valA > valB) return sortOrder.value === 'asc' ? 1 : -1;
    return 0;
  });
});

// ─── Selection Logic ───
const isAllSelected = computed(() => {
  return filteredJobPositions.value.length > 0 && 
    filteredJobPositions.value.every(p => selectedRowIds.value.includes(p.id));
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = filteredJobPositions.value.map(p => p.id);
  }
};

const toggleRowSelection = (id: number) => {
  const index = selectedRowIds.value.indexOf(id);
  if (index > -1) {
    selectedRowIds.value.splice(index, 1);
  } else {
    selectedRowIds.value.push(id);
  }
};

const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

const handleToggleColumn = ({ key, visible }: { key: string; visible: boolean }) => {
  const col = tableColumns.value.find(c => c.key === key);
  if (col) col.visible = visible;
};

// ─── Actions Menu ───
const toggleActionMenu = (id: number, event: Event) => {
  event.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
};

const showToast = (msg: string) => {
  quickActionToast.value = msg;
  setTimeout(() => {
    quickActionToast.value = null;
  }, 4000);
};

const formatETB = (val: number) => {
  return new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(val);
};

// Open Detail Modal
const openDetailModal = (position: JobPositionRecord) => {
  closeActionMenu();
  selectedPositionForDetail.value = position;
  showDetailModal.value = true;
};

// ─── Quick Create Handlers ───
const handleQuickSave = () => {
  if (!quickForm.value.job_title_id) {
    alert('Please select a Job Title.');
    return;
  }

  const selectedTitle = jobTitleOptions.find(t => t.value === quickForm.value.job_title_id);
  const selectedLevel = jobLevelOptions.find(l => l.value === quickForm.value.job_level_id);
  const selectedEntity = entityOptions.find(e => e.value === quickForm.value.entity_id);
  const selectedUnit = orgUnitOptions.find(u => u.value === quickForm.value.organization_unit_id);
  const selectedGrade = jobGradeOptions.find(g => g.value === quickForm.value.job_grade_id);
  const selectedReports = reportsToOptions.find(r => r.value === quickForm.value.reports_to_position_id);

  const titleName = selectedTitle ? selectedTitle.label.split(' (')[0] : 'Role Seat';
  const levelName = selectedLevel ? selectedLevel.label.split(' (')[0] : 'Officer';
  const unitName = selectedUnit ? selectedUnit.label.split(' (')[0] : 'Department';
  const gradeName = selectedGrade ? selectedGrade.label.split(' (')[0] : 'Grade B2';
  const reportsTitle = selectedReports ? selectedReports.label.split(' (')[0] : null;

  const newId = Date.now();
  const titleAbbr = titleName.substring(0, 3).toUpperCase();
  const newRecord: JobPositionRecord = {
    id: newId,
    uuid: `pos-${newId}`,
    code: `POS-${titleAbbr}-00${jobPositions.value.length + 1}`,
    job_title_id: quickForm.value.job_title_id,
    title_name: titleName,
    job_level_id: quickForm.value.job_level_id,
    level_name: levelName,
    full_name: `${titleName} — ${levelName}`,
    tenant_id: 1,
    entity_id: quickForm.value.entity_id,
    entity_name: selectedEntity ? selectedEntity.label : 'Haleta Addis Ababa HQ',
    organization_unit_id: quickForm.value.organization_unit_id,
    organization_unit_name: unitName,
    job_grade_id: quickForm.value.job_grade_id,
    job_grade_name: gradeName,
    reports_to_position_id: quickForm.value.reports_to_position_id,
    reports_to_title: reportsTitle,
    authorized_headcount: Number(quickForm.value.authorized_headcount) || 1,
    filled_headcount: 0,
    is_key_position: quickForm.value.is_key_position,
    guarantee_required_amount: quickForm.value.guarantee_required_amount ? Number(quickForm.value.guarantee_required_amount) : null,
    requirements_count: 0,
    requirements: [],
    state: 'active'
  };

  jobPositions.value.unshift(newRecord);
  showQuickCreate.value = false;
  showToast(`Position Seat "${newRecord.full_name}" created successfully.`);

  // Reset
  quickForm.value = {
    job_title_id: 12,
    job_level_id: 2,
    entity_id: 3,
    organization_unit_id: 1,
    job_grade_id: 5,
    reports_to_position_id: 30,
    authorized_headcount: 1,
    is_key_position: false,
    guarantee_required_amount: ''
  };
};

const handleExpandFullForm = () => {
  showQuickCreate.value = false;
  router.push({
    path: '/hr/job-positions/create',
    query: {
      title_id: quickForm.value.job_title_id,
      level_id: quickForm.value.job_level_id,
      entity_id: quickForm.value.entity_id,
      unit_id: quickForm.value.organization_unit_id,
      grade_id: quickForm.value.job_grade_id,
      reports_to_id: quickForm.value.reports_to_position_id || '',
      headcount: quickForm.value.authorized_headcount
    }
  });
};

// Batch Delete
const handleBatchDelete = () => {
  jobPositions.value = jobPositions.value.filter(p => !selectedRowIds.value.includes(p.id));
  selectedRowIds.value = [];
  showToast('Selected job positions deleted.');
};

onMounted(() => {
  window.addEventListener('click', closeActionMenu);
});

onUnmounted(() => {
  window.removeEventListener('click', closeActionMenu);
});
</script>

<template>
  <div class="job-positions-page">
    <!-- Breadcrumb Bar -->
    <div class="page-breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Toast Notification Banner -->
    <div v-if="quickActionToast" class="quick-toast-banner">
      <CheckCircle2 :size="15" class="text-emerald-600" />
      <span>{{ quickActionToast }}</span>
    </div>

    <!-- MAIN DATA TABLE -->
    <div class="directory-view-wrapper">
      <AppDataTable
        title="Job Positions & Structural Seats"
        subtitle="Manage approved establishment seats (JobPosition), organizational placements, seniority levels, authorized headcounts, reporting lines, and surety requirements."
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search Name..."
        :showSearch="true"
        :showFilter="true"
        :filterCount="activeFilterCount"
        :showSort="true"
        v-model:currentSort="currentSort"
        v-model:sortOrder="sortOrder"
        :showColumns="true"
        :columns="tableColumns"
        @toggleColumn="handleToggleColumn"
      >
        <!-- Primary Action -->
        <template #actions>
          <button 
            type="button" 
            class="btn-primary-create" 
            @click="showQuickCreate = true"
          >
            <Plus :size="15" />
            <span>Create Position</span>
          </button>
        </template>

        <!-- Filter Popover Content -->
        <template #filter>
          <div class="filter-grid">
            <FormSelect
              label="Organization Unit"
              v-model="filterUnit"
              :options="['All', 'Human Resources', 'Finance & Corporate Services Division', 'General Accounting & Audit', 'Commercial Sales & Front Office', 'Procurement & Logistics Department']"
            />
            <FormSelect
              label="Pay Grade"
              v-model="filterGrade"
              :options="['All', 'Grade C2', 'Grade B2', 'Grade A3']"
            />
            <FormSelect
              label="Key Position"
              v-model="filterKeyPos"
              :options="['All', 'Yes', 'No']"
            />
            <FormSelect
              label="Record State"
              v-model="filterState"
              :options="['All', 'Active', 'Inactive']"
            />
          </div>
        </template>

        <!-- Table Listing -->
        <table class="erp-table">
          <thead>
            <tr>
              <th class="col-checkbox">
                <input 
                  type="checkbox" 
                  class="custom-checkbox" 
                  :checked="isAllSelected" 
                  @change="toggleSelectAll"
                  aria-label="Select All" 
                />
              </th>

              <!-- Name Column (Secondary color) with Code as sub-text in tertiary color -->
              <th v-if="isColumnVisible('name')" class="col-name sortable" @click="currentSort = 'title_name'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>Position Seat</span>
                  <ArrowUpDown v-if="currentSort === 'title_name'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>

              <!-- Subsequent Columns strictly in Tertiary Color -->
              <th v-if="isColumnVisible('org_unit')" class="col-unit">Organization Unit</th>
              <th v-if="isColumnVisible('job_grade')" class="col-grade">Pay Grade</th>
              <th v-if="isColumnVisible('headcount')" class="col-headcount">Authorized Headcount</th>
              <th v-if="isColumnVisible('reports_to')" class="col-reports">Reports To</th>
              <th v-if="isColumnVisible('is_key')" class="col-key">Key Position</th>
              <th v-if="isColumnVisible('guarantee')" class="col-guarantee">Surety / Guarantee</th>
              <th v-if="isColumnVisible('state')" class="col-state sortable" @click="currentSort = 'state'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>State</span>
                  <ArrowUpDown v-if="currentSort === 'state'" :size="12" class="sort-icon active-sort" />
                </div>
              </th>
              <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr 
              v-for="item in filteredJobPositions" 
              :key="item.id"
              class="erp-row cursor-pointer"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
              @click="openDetailModal(item)"
            >
              <td class="col-checkbox" @click.stop>
                <input 
                  type="checkbox" 
                  class="custom-checkbox" 
                  :checked="selectedRowIds.includes(item.id)" 
                  @change="toggleRowSelection(item.id)" 
                />
              </td>

              <!-- Rule 4 & 5: Name is Secondary Color (#404040), Code is Tertiary subtext (#737373) -->
              <td v-if="isColumnVisible('name')" class="col-name">
                <div class="name-cell-stack">
                  <span class="table-name-primary">{{ item.full_name }}</span>
                  <span class="table-code-subtext font-mono">{{ item.code }}</span>
                </div>
              </td>

              <!-- Rule 5 & 6: Tertiary plain text, NO decorative badges for counts or categories -->
              <td v-if="isColumnVisible('org_unit')" class="col-unit">
                <span class="text-tertiary">{{ item.organization_unit_name }}</span>
              </td>

              <td v-if="isColumnVisible('job_grade')" class="col-grade">
                <span class="text-tertiary">{{ item.job_grade_name }}</span>
              </td>

              <td v-if="isColumnVisible('headcount')" class="col-headcount">
                <span class="text-tertiary">{{ item.authorized_headcount }} Seats ({{ item.filled_headcount }} Filled)</span>
              </td>

              <!-- Rule 8: Plain text reference to supervisor position without foreign avatar -->
              <td v-if="isColumnVisible('reports_to')" class="col-reports">
                <span class="text-tertiary">{{ item.reports_to_title || 'Top Executive' }}</span>
              </td>

              <td v-if="isColumnVisible('is_key')" class="col-key">
                <span class="text-tertiary">{{ item.is_key_position ? 'Yes' : 'No' }}</span>
              </td>

              <td v-if="isColumnVisible('guarantee')" class="col-guarantee">
                <span class="text-tertiary font-mono">
                  {{ item.guarantee_required_amount ? `${formatETB(item.guarantee_required_amount)} ETB` : 'None' }}
                </span>
              </td>

              <!-- Badges reserved strictly for lifecycle state -->
              <td v-if="isColumnVisible('state')" class="col-state">
                <span class="status-pill" :class="item.state === 'active' ? 'status-pill-active' : 'status-pill-inactive'">
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </span>
              </td>

              <!-- Action 3-dots -->
              <td v-if="isColumnVisible('actions')" class="col-actions" @click.stop>
                <div class="action-dropdown-container">
                  <button 
                    type="button" 
                    class="btn-action-dots" 
                    @click="toggleActionMenu(item.id, $event)"
                    aria-label="Actions"
                  >
                    <MoreVertical :size="15" />
                  </button>

                  <div v-if="activeActionMenuId === item.id" class="action-popup-menu">
                    <button type="button" class="menu-item" @click="openDetailModal(item)">
                      <Eye :size="14" />
                      <span>View Position Profile</span>
                    </button>
                    <button type="button" class="menu-item" @click="router.push(`/hr/job-positions/create?edit=${item.id}`)">
                      <Edit2 :size="14" />
                      <span>Edit Specifications</span>
                    </button>
                    <button 
                      type="button" 
                      class="menu-item"
                      @click="item.state = item.state === 'active' ? 'inactive' : 'active'; showToast(`Updated ${item.code} state.`); closeActionMenu();"
                    >
                      <Check :size="14" />
                      <span>{{ item.state === 'active' ? 'Deactivate Seat' : 'Activate Seat' }}</span>
                    </button>
                    <div class="menu-divider"></div>
                    <button 
                      type="button" 
                      class="menu-item text-rose-600 hover:bg-rose-50"
                      @click="jobPositions = jobPositions.filter(p => p.id !== item.id); showToast(`Deleted position ${item.code}`); closeActionMenu();"
                    >
                      <Trash2 :size="14" />
                      <span>Delete Position</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>

            <tr v-if="filteredJobPositions.length === 0">
              <td colspan="9" class="table-empty-row">
                <div class="empty-state-box">
                  <p class="empty-title">No Job Positions Found</p>
                  <p class="empty-subtitle">Adjust your filter options or create a new structural position seat.</p>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </AppDataTable>
    </div>

    <!-- FLOATING BATCH ACTIONS BAR -->
    <TableFloatingBar 
      :count="selectedRowIds.length" 
      @delete="handleBatchDelete" 
    />

    <!-- QUICK CREATE MODAL (Standard: <= 5 Required Fields, No Subtitle, No Bottom Divider Line) -->
    <QuickCreateModal
      v-model:show="showQuickCreate"
      title="Create Job Position"
      saveLabel="Save"
      @save="handleQuickSave"
      @expand="handleExpandFullForm"
      :showExpandButton="true"
      width="md"
    >
      <div class="quick-create-form-body">
        <!-- Job Title from Catalogue: FK job_title_id (Rule 5: Select with 'Select' placeholder) -->
        <FormSelect
          label="Job Title"
          v-model="quickForm.job_title_id"
          :options="jobTitleOptions"
          placeholder="Select"
          required
        />

        <!-- Seniority Level: FK job_level_id -->
        <FormSelect
          label="Seniority Level"
          v-model="quickForm.job_level_id"
          :options="jobLevelOptions"
          placeholder="Select"
          required
        />

        <!-- Owning Entity: FK entity_id (Schema line 1157) -->
        <FormSelect
          label="Owning Entity"
          v-model="quickForm.entity_id"
          :options="entityOptions"
          placeholder="Select"
          required
        />

        <!-- Organization Unit: FK organization_unit_id -->
        <FormSelect
          label="Organization Unit"
          v-model="quickForm.organization_unit_id"
          :options="orgUnitOptions"
          placeholder="Select"
          required
        />

        <div class="form-row-dual">
          <!-- Pay Grade: FK job_grade_id -->
          <FormSelect
            label="Job Grade"
            v-model="quickForm.job_grade_id"
            :options="jobGradeOptions"
            placeholder="Select"
            required
          />

          <!-- Authorized Headcount -->
          <FormInput
            label="Authorized Headcount"
            v-model="quickForm.authorized_headcount"
            type="number"
            required
          />
        </div>

        <!-- Reports To Position: FK reports_to_position_id -->
        <FormSelect
          label="Reports To Position"
          v-model="quickForm.reports_to_position_id"
          :options="reportsToOptions"
          placeholder="Select"
        />

        <!-- Key Succession Position Checkbox: Rule 5 (Label & Business Description) -->
        <FormCheckbox
          v-model="quickForm.is_key_position"
          label="Key Succession Position"
          description="Designates this position as critical, flagging it in enterprise succession coverage audits if vacant without designated successors."
        />
      </div>
    </QuickCreateModal>

    <!-- POSITION PROFILE / REQUIREMENTS INSPECTION MODAL -->
    <div v-if="showDetailModal && selectedPositionForDetail" class="position-modal-backdrop" @click="showDetailModal = false">
      <div class="position-modal-content" @click.stop>
        <div class="modal-header">
          <div>
            <h2 class="modal-title">{{ selectedPositionForDetail.full_name }}</h2>
            <div class="modal-submeta">
              <span class="font-mono text-neutral-500">{{ selectedPositionForDetail.code }}</span>
              <span class="meta-dot">•</span>
              <span>{{ selectedPositionForDetail.organization_unit_name }}</span>
              <span class="meta-dot">•</span>
              <span>{{ selectedPositionForDetail.job_grade_name }}</span>
              <span class="meta-dot">•</span>
              <span class="font-medium text-slate-700">Headcount: {{ selectedPositionForDetail.authorized_headcount }} Seats ({{ selectedPositionForDetail.filled_headcount }} Filled)</span>
            </div>
          </div>
          <button type="button" class="btn-close-modal" @click="showDetailModal = false">
            <X :size="18" />
          </button>
        </div>

        <div class="modal-body">
          <!-- Placement & Governance Overview Cards -->
          <div class="overview-grid mb-4">
            <div class="overview-card">
              <span class="overview-label">Reports To</span>
              <span class="overview-val">{{ selectedPositionForDetail.reports_to_title || 'Executive Leadership' }}</span>
            </div>
            <div class="overview-card">
              <span class="overview-label">Surety / Guarantee</span>
              <span class="overview-val font-mono">
                {{ selectedPositionForDetail.guarantee_required_amount ? `${formatETB(selectedPositionForDetail.guarantee_required_amount)} ETB` : 'None Required' }}
              </span>
            </div>
            <div class="overview-card">
              <span class="overview-label">Key Position Status</span>
              <span class="overview-val">{{ selectedPositionForDetail.is_key_position ? 'Yes (Critical)' : 'No (Standard)' }}</span>
            </div>
          </div>

          <!-- Position Requirements Sub-table (JobPositionRequirement lines 1177–1201) -->
          <div class="requirements-box">
            <div class="requirements-header">
              <span class="req-title">Position Qualification & Skill Requirements (JobPositionRequirement)</span>
              <span class="req-count">{{ selectedPositionForDetail.requirements.length }} Requirements</span>
            </div>

            <table class="req-table">
              <thead>
                <tr>
                  <th style="width: 150px;">Requirement Type</th>
                  <th>Specification & Catalogue Link</th>
                  <th style="width: 110px;">Mandatory</th>
                  <th style="width: 110px;">Weight (%)</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="r in selectedPositionForDetail.requirements" :key="r.id">
                  <td class="req-type font-mono">{{ r.requirement_type }}</td>
                  <td class="req-desc">
                    <div class="desc-stack">
                      <span class="desc-main">{{ r.description }}</span>
                      <span v-if="r.catalogue_code" class="catalogue-badge font-mono">{{ r.catalogue_code }}</span>
                      <span v-else-if="r.field_of_study_id" class="catalogue-badge font-mono">FIELD_OF_STUDY: ID #{{ r.field_of_study_id }}</span>
                      <span v-else-if="r.min_value" class="catalogue-badge font-mono">Min Threshold: {{ r.min_value }}</span>
                    </div>
                  </td>
                  <td class="req-mand">
                    <span class="mand-text" :class="r.is_mandatory ? 'mand-yes' : 'mand-no'">
                      {{ r.is_mandatory ? 'Must Have' : 'Preferred' }}
                    </span>
                  </td>
                  <td class="req-weight font-mono">{{ r.weight || '--' }}%</td>
                </tr>
                <tr v-if="selectedPositionForDetail.requirements.length === 0">
                  <td colspan="4" class="req-empty">No recruitment requirements configured for this seat.</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="modal-footer">
          <div class="footer-hint">
            <span>* Requirements drive candidate matching in JobRequisition and succession coverage scoring.</span>
          </div>
          <button type="button" class="btn-primary" @click="showDetailModal = false">
            Close
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.job-positions-page {
  padding: 24px;
  background-color: var(--primitive-color-neutral-50, #f8fafc);
  min-height: 100vh;
  box-sizing: border-box;
}

.page-breadcrumb-bar {
  margin-bottom: 16px;
}

/* Toast Banner */
.quick-toast-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  padding: 10px 16px;
  margin-bottom: 16px;
  font-size: 13.5px;
  color: #065f46;
  animation: fadeIn 0.2s ease-in-out;
}

.directory-view-wrapper {
  background: #ffffff;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

/* Primary Create Button (Well-rounded rectangle: 8px-10px) */
.btn-primary-create {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 38px;
  padding: 0 16px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-primary-create:hover {
  background-color: #09427d;
}

/* Filter Grid in Popover */
.filter-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  padding: 16px;
}

/* ERP Table Core */
.erp-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  background-color: #fafafa;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
}

.erp-table th.sortable {
  cursor: pointer;
  user-select: none;
}

.th-content {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.sort-icon {
  color: #94a3b8;
}

.erp-row {
  height: 48px;
  border-bottom: 1px solid #f1f5f9;
  transition: background-color 0.12s ease;
}

.erp-row:hover {
  background-color: #f8fafc;
}

.erp-row.row-selected {
  background-color: #f0f7ff;
}

.erp-table td {
  padding: 8px 16px;
  font-size: 13px;
  vertical-align: middle;
}

/* Checkbox */
.col-checkbox {
  width: 44px;
  text-align: center;
  padding: 0 8px !important;
}

.custom-checkbox {
  width: 16px;
  height: 16px;
  cursor: pointer;
  accent-color: #0B529C;
  border-radius: 4px;
}

/* Rule 4 & 5: Name Cell Stack */
.col-name {
  min-width: 250px;
}

.name-cell-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040; /* Secondary Color for primary entity name */
}

.table-code-subtext {
  font-size: 11.5px;
  color: #737373; /* Tertiary color for code subtext */
}

/* Tertiary text color for all subsequent columns */
.text-tertiary {
  color: #737373;
  font-size: 13px;
}

/* Lifecycle Status Pills */
.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
}

.status-pill-active {
  background-color: #ecfdf5;
  color: #059669;
}

.status-pill-inactive {
  background-color: #f1f5f9;
  color: #64748b;
}

/* Action 3-dots Menu */
.col-actions {
  width: 60px;
  text-align: center;
}

.action-dropdown-container {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: 1px solid transparent;
  background: transparent;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.action-popup-menu {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  min-width: 180px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  padding: 4px 0;
  z-index: 40;
  animation: fadeIn 0.12s ease-in-out;
}

.menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 14px;
  border: none;
  background: none;
  font-size: 12.5px;
  color: #404040;
  text-align: left;
  cursor: pointer;
  transition: background-color 0.1s ease;
}

.menu-item:hover {
  background-color: #f8fafc;
}

.menu-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 4px 0;
}

/* Empty State */
.table-empty-row {
  padding: 48px 16px !important;
  text-align: center;
}

.empty-state-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.empty-title {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
}

.empty-subtitle {
  font-size: 12.5px;
  color: #737373;
}

/* Quick Create Form Content */
.quick-create-form-body {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-row-dual {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
}

/* Detail Modal */
.position-modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
  padding: 20px;
}

.position-modal-content {
  background: #ffffff;
  border-radius: 12px;
  width: 100%;
  max-width: 800px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.modal-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 18px 24px;
  border-bottom: 1px solid #e2e8f0;
}

.modal-title {
  font-size: 17px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}

.modal-submeta {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12.5px;
  color: #737373;
}

.meta-dot {
  color: #cbd5e1;
}

.btn-close-modal {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #94a3b8;
  cursor: pointer;
}

.btn-close-modal:hover {
  background: #f1f5f9;
  color: #404040;
}

.modal-body {
  padding: 20px 24px;
  overflow-y: auto;
  flex: 1;
}

.overview-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.overview-card {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.overview-label {
  font-size: 11.5px;
  color: #737373;
}

.overview-val {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
}

.requirements-box {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
}

.requirements-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 14px;
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
}

.req-title {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.req-count {
  font-size: 11px;
  color: #64748b;
  background: #f1f5f9;
  padding: 2px 8px;
  border-radius: 9999px;
  font-weight: 500;
}

.req-table {
  width: 100%;
  border-collapse: collapse;
}

.req-table th {
  padding: 8px 14px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  border-bottom: 1px solid #e2e8f0;
  background-color: #f8fafc;
  text-align: left;
}

.req-table td {
  padding: 10px 14px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
}

.req-type {
  font-size: 11.5px;
  color: #64748b;
  text-transform: capitalize;
}

.mand-text {
  font-size: 12px;
  font-weight: 500;
}

.mand-yes {
  color: #059669;
}

.mand-no {
  color: #64748b;
}

.desc-stack {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.desc-main {
  font-size: 13px;
  color: #404040;
}

.catalogue-badge {
  font-size: 11px;
  color: #0284c7;
  background-color: #f0f9ff;
  border-radius: 4px;
  padding: 1px 6px;
  width: fit-content;
}

.req-empty {
  text-align: center;
  padding: 20px;
  color: #737373;
}

.modal-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 24px;
  border-top: 1px solid #e2e8f0;
  background-color: #f8fafc;
}

.footer-hint {
  font-size: 12px;
  color: #737373;
}

.btn-primary {
  display: inline-flex;
  align-items: center;
  height: 34px;
  padding: 0 20px;
  background: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-primary:hover {
  background: #09427d;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-3px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
