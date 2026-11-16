<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import {
  Building2, Plus, Search, Filter,
  MoreVertical, Edit2, Trash2, Eye,
  Copy, Check, CheckCircle2, X,
  Globe, ExternalLink
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import { useToast } from '../../composables/useToast';

const router = useRouter();

// ─── Lookups & Types (HR Schema Designer 1.sql lines 218, 239–253) ───
export type RowState = 'active' | 'inactive';
export type GovernanceStatus = 'pending' | 'acceptForAll' | 'acceptForThis' | 'reject';
export type InstitutionType = 
  | 'university' 
  | 'college' 
  | 'tvet' 
  | 'high_school' 
  | 'professional_body' 
  | 'training_center' 
  | 'regulator';

export interface InstitutionRecord {
  id: number;
  uuid: string;
  code: string;
  name: string;
  institution_type_lookup_value_id: InstitutionType;
  institution_type_label: string;
  country_id: string;
  country_name: string;
  admin_unit_id?: number | null;
  admin_unit_name?: string | null;
  party_id?: number | null;
  website?: string | null;
  tenant_id: number;
  entity_id?: number | null;
  entity_name: string;
  is_system: boolean;
  status: GovernanceStatus;
  status_label: string;
  state: RowState;
}

// ─── Breadcrumbs (Rule: Exact Page Name from Sidebar Only, Zero Section Titles) ───
const breadcrumbItems = [
  { label: 'Institutions' }
];

// ─── State Management ───
const searchQuery = ref('');
const filterType = ref('All');
const filterCountry = ref('All');
const filterStatus = ref('All');
const filterState = ref('All');
const currentSort = ref('name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const showQuickCreate = ref(false);
const editingInstitutionId = ref<number | null>(null);
const inspectingInstitution = ref<InstitutionRecord | null>(null);
const { toast } = useToast();

// ─── Table Columns (Strict Schema Alignment & Name-First Hierarchy: Rule 9 & Rule 14) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Institution Name', visible: true, sortable: true },
  { key: 'type', label: 'Institution Type', visible: true, sortable: true },
  { key: 'country', label: 'Country', visible: true, sortable: true },
  { key: 'admin_unit', label: 'Exact Location (Ethiopia)', visible: true, sortable: true },
  { key: 'website', label: 'Website Portal', visible: true, sortable: false },
  { key: 'entity', label: 'Owning Entity', visible: false, sortable: true },
  { key: 'status', label: 'Governance Status', visible: false, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

// ─── Mock Data Aligned 100% with HR Schema Designer 1.sql lines 254–260 ───
const institutions = ref<InstitutionRecord[]>([
  {
    id: 1,
    uuid: 'inst-uuid-001',
    code: 'AAU',
    name: 'Addis Ababa University',
    institution_type_lookup_value_id: 'university',
    institution_type_label: 'University',
    country_id: 'ET',
    country_name: 'Ethiopia',
    admin_unit_id: 305,
    admin_unit_name: '305 (Bole, Addis Ababa)',
    party_id: null,
    website: 'http://www.aau.edu.et',
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 2,
    uuid: 'inst-uuid-002',
    code: 'BDU',
    name: 'Bahir Dar University',
    institution_type_lookup_value_id: 'university',
    institution_type_label: 'University',
    country_id: 'ET',
    country_name: 'Ethiopia',
    admin_unit_id: 401,
    admin_unit_name: '401 (Bahir Dar)',
    party_id: null,
    website: 'https://www.bdu.edu.et',
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 4,
    uuid: 'inst-uuid-004',
    code: 'ADMAS',
    name: 'Admas University College',
    institution_type_lookup_value_id: 'college',
    institution_type_label: 'College',
    country_id: 'ET',
    country_name: 'Ethiopia',
    admin_unit_id: 315,
    admin_unit_name: '315 (Kirkos, Addis Ababa)',
    party_id: null,
    website: 'https://admasuniversity.edu.et',
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 7,
    uuid: 'inst-uuid-007',
    code: 'ACCA_GLOBAL',
    name: 'ACCA Global',
    institution_type_lookup_value_id: 'professional_body',
    institution_type_label: 'Professional Body',
    country_id: 'GB',
    country_name: 'United Kingdom',
    admin_unit_id: null,
    admin_unit_name: null,
    party_id: null,
    website: 'https://www.accaglobal.com',
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 8,
    uuid: 'inst-uuid-008',
    code: 'AABE',
    name: 'Accounting & Auditing Board (ET)',
    institution_type_lookup_value_id: 'regulator',
    institution_type_label: 'Regulator',
    country_id: 'ET',
    country_name: 'Ethiopia',
    admin_unit_id: 305,
    admin_unit_name: '305 (Bole, Addis Ababa)',
    party_id: null,
    website: 'https://www.aabe.gov.et',
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 5,
    uuid: 'inst-uuid-005',
    code: 'ENTOTO_TVET',
    name: 'Entoto TVET College',
    institution_type_lookup_value_id: 'tvet',
    institution_type_label: 'TVET',
    country_id: 'ET',
    country_name: 'Ethiopia',
    admin_unit_id: 302,
    admin_unit_name: '302 (Gulele, Addis Ababa)',
    party_id: null,
    website: null,
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 9,
    uuid: 'inst-uuid-009',
    code: 'FPPA',
    name: 'Federal Public Procurement and Property Authority',
    institution_type_lookup_value_id: 'regulator',
    institution_type_label: 'Regulator',
    country_id: 'ET',
    country_name: 'Ethiopia',
    admin_unit_id: 308,
    admin_unit_name: '308 (Arada, Addis Ababa)',
    party_id: null,
    website: 'https://www.ppa.gov.et',
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  },
  {
    id: 10,
    uuid: 'inst-uuid-010',
    code: 'EMI',
    name: 'Ethiopian Management Institute',
    institution_type_lookup_value_id: 'training_center',
    institution_type_label: 'Training Center',
    country_id: 'ET',
    country_name: 'Ethiopia',
    admin_unit_id: 305,
    admin_unit_name: '305 (Bole, Addis Ababa)',
    party_id: null,
    website: 'https://www.emi.gov.et',
    tenant_id: 1,
    entity_id: null,
    entity_name: 'Platform Standard',
    is_system: true,
    status: 'acceptForAll',
    status_label: 'Approved for All Entities',
    state: 'active'
  }
]);

// ─── Filter & Dropdown Options (Schema lookups line 218) ───
const institutionTypeOptions = [
  { value: 'university', label: 'University' },
  { value: 'college', label: 'College' },
  { value: 'tvet', label: 'TVET' },
  { value: 'high_school', label: 'High School' },
  { value: 'professional_body', label: 'Professional Body' },
  { value: 'training_center', label: 'Training Center' },
  { value: 'regulator', label: 'Regulator' }
];

const countryOptions = [
  { value: 'ET', label: 'Ethiopia (ET)' },
  { value: 'GB', label: 'United Kingdom (GB)' },
  { value: 'US', label: 'United States (US)' },
  { value: 'KE', label: 'Kenya (KE)' },
  { value: 'ZA', label: 'South Africa (ZA)' },
  { value: 'DE', label: 'Germany (DE)' }
];

const governanceStatusOptions = [
  { value: 'acceptForAll', label: 'Approved for All Entities (acceptForAll)' },
  { value: 'acceptForThis', label: 'Approved for This Entity Only (acceptForThis)' },
  { value: 'pending', label: 'Pending Verification (pending)' },
  { value: 'reject', label: 'Rejected (reject)' }
];

const entityOptions = [
  { value: 0, label: 'Platform Standard (All Entities)' },
  { value: 1, label: 'QMT Business Group' },
  { value: 3, label: 'Haleta Addis Ababa HQ' },
  { value: 7, label: 'Haleta Grand Hotel & Suites' },
  { value: 9, label: 'Haleta East Regional Office' }
];

// ─── Computed Filtered Records ───
const filteredInstitutions = computed(() => {
  let result = [...institutions.value];

  // Search filter (name, code, country, admin unit)
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.trim().toLowerCase();
    result = result.filter(i => 
      i.name.toLowerCase().includes(q) ||
      i.code.toLowerCase().includes(q) ||
      i.country_name.toLowerCase().includes(q) ||
      (i.admin_unit_name && i.admin_unit_name.toLowerCase().includes(q)) ||
      i.institution_type_label.toLowerCase().includes(q)
    );
  }

  // Type filter
  if (filterType.value !== 'All') {
    result = result.filter(i => i.institution_type_lookup_value_id === filterType.value);
  }

  // Country filter
  if (filterCountry.value !== 'All') {
    result = result.filter(i => i.country_id === filterCountry.value);
  }

  // Governance status filter
  if (filterStatus.value !== 'All') {
    result = result.filter(i => i.status === filterStatus.value);
  }

  // State filter
  if (filterState.value !== 'All') {
    result = result.filter(i => i.state === filterState.value);
  }

  // Sorting
  result.sort((a, b) => {
    let aVal: any = a[currentSort.value as keyof InstitutionRecord] ?? '';
    let bVal: any = b[currentSort.value as keyof InstitutionRecord] ?? '';

    if (typeof aVal === 'string') {
      aVal = aVal.toLowerCase();
      bVal = (bVal as string).toLowerCase();
    }

    if (aVal < bVal) return sortOrder.value === 'asc' ? -1 : 1;
    if (aVal > bVal) return sortOrder.value === 'asc' ? 1 : -1;
    return 0;
  });

  return result;
});

// Selection helpers
const isAllSelected = computed(() => {
  return filteredInstitutions.value.length > 0 && selectedRowIds.value.length === filteredInstitutions.value.length;
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = filteredInstitutions.value.map(r => r.id);
  }
};

const toggleSelectRow = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx > -1) {
    selectedRowIds.value.splice(idx, 1);
  } else {
    selectedRowIds.value.push(id);
  }
};

const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

const handleToggleColumn = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  if (col) col.visible = !col.visible;
};

// ─── Quick Create / Edit Form State (<= 5 Required Fields Flow: Rule 4) ───
const quickForm = ref({
  name: '',
  institution_type: 'university' as InstitutionType,
  custom_code: '',
  country_id: 'ET',
  admin_unit_name: '305 (Bole, Addis Ababa)',
  website: '',
  entity_id: 0,
  status: 'acceptForAll' as GovernanceStatus
});

const showToast = (message: string) => {
  toast.success(message);
};

const openCreateModal = () => {
  editingInstitutionId.value = null;
  quickForm.value = {
    name: '',
    institution_type: 'university',
    custom_code: '',
    country_id: 'ET',
    admin_unit_name: '',
    website: '',
    entity_id: 0,
    status: 'acceptForAll'
  };
  showQuickCreate.value = true;
};

const openEditModal = (inst: InstitutionRecord) => {
  editingInstitutionId.value = inst.id;
  quickForm.value = {
    name: inst.name,
    institution_type: inst.institution_type_lookup_value_id,
    custom_code: inst.code,
    country_id: inst.country_id,
    admin_unit_name: inst.admin_unit_name || '',
    website: inst.website || '',
    entity_id: inst.entity_id || 0,
    status: inst.status
  };
  showQuickCreate.value = true;
  closeActionMenu();
};

const handleSaveQuickCreate = () => {
  if (!quickForm.value.name.trim()) {
    alert('Please enter an Institution name.');
    return;
  }

  const typeObj = institutionTypeOptions.find(t => t.value === quickForm.value.institution_type);
  const countryObj = countryOptions.find(c => c.value === quickForm.value.country_id);
  const statusObj = governanceStatusOptions.find(s => s.value === quickForm.value.status);
  const entityObj = entityOptions.find(e => e.value === quickForm.value.entity_id);

  // Derive human-readable code automatically if omitted
  let finalCode = quickForm.value.custom_code.trim().toUpperCase();
  if (!finalCode) {
    finalCode = quickForm.value.name.trim().toUpperCase().replace(/[^A-Z0-9]/g, '_');
  }

  if (editingInstitutionId.value) {
    // Edit existing record
    const target = institutions.value.find(i => i.id === editingInstitutionId.value);
    if (target) {
      target.name = quickForm.value.name.trim();
      target.institution_type_lookup_value_id = quickForm.value.institution_type;
      target.institution_type_label = typeObj ? typeObj.label : 'University';
      target.code = finalCode;
      target.country_id = quickForm.value.country_id;
      target.country_name = countryObj ? countryObj.label.split(' ')[0] : 'Ethiopia';
      target.admin_unit_name = quickForm.value.admin_unit_name.trim() || null;
      target.website = quickForm.value.website.trim() || null;
      target.entity_id = quickForm.value.entity_id === 0 ? null : quickForm.value.entity_id;
      target.entity_name = entityObj ? entityObj.label : 'Platform Standard';
      target.status = quickForm.value.status;
      target.status_label = statusObj ? statusObj.label : 'Approved for All Entities';
      showToast(`Institution "${target.name}" updated successfully.`);
    }
  } else {
    // Insert new record
    const newId = Date.now();
    institutions.value.unshift({
      id: newId,
      uuid: `inst-uuid-${newId}`,
      code: finalCode,
      name: quickForm.value.name.trim(),
      institution_type_lookup_value_id: quickForm.value.institution_type,
      institution_type_label: typeObj ? typeObj.label : 'University',
      country_id: quickForm.value.country_id,
      country_name: countryObj ? countryObj.label.split(' ')[0] : 'Ethiopia',
      admin_unit_id: quickForm.value.country_id === 'ET' ? 305 : null,
      admin_unit_name: quickForm.value.admin_unit_name.trim() || (quickForm.value.country_id === 'ET' ? '305 (Bole, Addis Ababa)' : null),
      party_id: null,
      website: quickForm.value.website.trim() || null,
      tenant_id: 1,
      entity_id: quickForm.value.entity_id === 0 ? null : quickForm.value.entity_id,
      entity_name: entityObj ? entityObj.label : 'Platform Standard',
      is_system: false,
      status: quickForm.value.status,
      status_label: statusObj ? statusObj.label : 'Approved for All Entities',
      state: 'active'
    });
    showToast(`Institution "${quickForm.value.name.trim()}" registered successfully.`);
  }

  showQuickCreate.value = false;
  editingInstitutionId.value = null;
};

// ─── Actions Menu Handlers ───
const toggleActionMenu = (id: number) => {
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
};

const handleInspect = (inst: InstitutionRecord) => {
  inspectingInstitution.value = inst;
  closeActionMenu();
};

const handleToggleState = (inst: InstitutionRecord) => {
  inst.state = inst.state === 'active' ? 'inactive' : 'active';
  showToast(`Institution "${inst.name}" is now ${inst.state}.`);
  closeActionMenu();
};

const handleDuplicate = (inst: InstitutionRecord) => {
  const newId = Date.now();
  institutions.value.push({
    ...inst,
    id: newId,
    uuid: `inst-uuid-${newId}`,
    code: `${inst.code}_COPY`,
    name: `${inst.name} (Copy)`,
    is_system: false,
    state: 'active'
  });
  showToast(`Duplicated institution as "${inst.name} (Copy)".`);
  closeActionMenu();
};

const handleDelete = (id: number) => {
  institutions.value = institutions.value.filter(i => i.id !== id);
  selectedRowIds.value = selectedRowIds.value.filter(idNum => idNum !== id);
  showToast('Institution deleted successfully.');
  closeActionMenu();
};

const handleBatchDelete = () => {
  institutions.value = institutions.value.filter(i => !selectedRowIds.value.includes(i.id));
  showToast(`Deleted ${selectedRowIds.value.length} selected institutions.`);
  selectedRowIds.value = [];
};

const handleGlobalClick = (e: MouseEvent) => {
  const target = e.target as HTMLElement;
  if (!target.closest('.action-menu-container')) {
    closeActionMenu();
  }
};

onMounted(() => {
  window.addEventListener('click', handleGlobalClick);
});

onUnmounted(() => {
  window.removeEventListener('click', handleGlobalClick);
});
</script>

<template>
  <div class="institutions-page">
    <!-- ═══ BREADCRUMB NAVIGATION (Rule 3: Exact Sidebar Page Name Only) ═══ -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ═══ UNIFIED TABLE CARD: <AppDataTable /> (Rule 10.1 & Rule 9) ═══ -->
    <AppDataTable
      title="Institutions"
      subtitle="External education and certification bodies including universities, colleges, TVET, professional bodies, and regulators."
      :columns="tableColumns"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Toolbar Filter Controls -->
      <template #filters>
        <!-- Search Input -->
        <div class="filter-search-box">
          <Search :size="14" class="search-icon" />
          <input 
            type="text" 
            v-model="searchQuery" 
            placeholder="Search institution, code, or location..." 
            class="filter-search-input"
          />
          <button v-if="searchQuery" @click="searchQuery = ''" class="search-clear-btn" aria-label="Clear search">
            <X :size="12" />
          </button>
        </div>

        <!-- Institution Type Filter -->
        <div class="filter-select-box">
          <FormSelect
            v-model="filterType"
            label="Type:"
            :options="[
              { value: 'All', label: 'All Institution Types' },
              ...institutionTypeOptions
            ]"
            placeholder="Select Type"
          />
        </div>

        <!-- Country Filter -->
        <div class="filter-select-box">
          <FormSelect
            v-model="filterCountry"
            label="Country:"
            :options="[
              { value: 'All', label: 'All Countries' },
              ...countryOptions
            ]"
            placeholder="Select Country"
          />
        </div>

        <!-- State Filter -->
        <div class="filter-select-box">
          <FormSelect
            v-model="filterState"
            label="State:"
            :options="[
              { value: 'All', label: 'All States' },
              { value: 'active', label: 'Active' },
              { value: 'inactive', label: 'Inactive' }
            ]"
            placeholder="Select State"
          />
        </div>
      </template>

      <!-- Primary Action: + Add Institution (Rule 10.2) -->
      <template #actions>
        <AppButton variant="primary" size="sm" @click="openCreateModal">
  <template #icon-left><Plus :size="15" /></template>
  Add Institution
</AppButton>
      </template>

      <!-- Table Body -->
      <div class="table-container">
        <table class="erp-table">
          <thead>
            <tr>
              <!-- Checkbox Select All -->
              <th class="col-checkbox">
                <input 
                  type="checkbox" 
                  :checked="isAllSelected" 
                  @change="toggleSelectAll" 
                  class="table-checkbox" 
                />
              </th>

              <!-- Name Header (Rule 9.4 & 9.5) -->
              <th v-if="isColumnVisible('name')" class="col-name">Institution Name</th>
              <th v-if="isColumnVisible('type')" class="col-type">Institution Type</th>
              <th v-if="isColumnVisible('country')" class="col-country">Country</th>
              <th v-if="isColumnVisible('admin_unit')" class="col-admin-unit">Exact Location</th>
              <th v-if="isColumnVisible('website')" class="col-web">Website Portal</th>
              <th v-if="isColumnVisible('entity')" class="col-entity">Owning Entity</th>
              <th v-if="isColumnVisible('status')" class="col-status">Status</th>
              <th v-if="isColumnVisible('state')" class="col-state">State</th>
              <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <!-- Empty State -->
            <tr v-if="filteredInstitutions.length === 0">
              <td :colspan="tableColumns.length + 1" class="empty-state-cell">
                <div class="empty-state-container">
                  <Building2 :size="36" class="empty-state-icon" />
                  <p class="empty-state-title">No institutions found</p>
                  <p class="empty-state-subtext">No academic or professional institutions match your search and filter criteria.</p>
                </div>
              </td>
            </tr>

            <!-- Data Rows -->
            <tr 
              v-for="item in filteredInstitutions" 
              :key="item.id"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
            >
              <!-- Checkbox Cell -->
              <td class="col-checkbox">
                <input 
                  type="checkbox" 
                  :checked="selectedRowIds.includes(item.id)" 
                  @change="toggleSelectRow(item.id)" 
                  class="table-checkbox" 
                />
              </td>

              <!-- Name & Code (Rule 9.4 & 9.5: Secondary Color #404040 for Name, Subtext Code) -->
              <td v-if="isColumnVisible('name')" class="col-name" @click="handleInspect(item)">
                <div class="field-name-block cursor-pointer">
                  <span class="table-name-primary">{{ item.name }}</span>
                  <span class="table-code-subtext">{{ item.code }}</span>
                </div>
              </td>

              <!-- Institution Type (Rule 9.6: Plain Tertiary Text #737373, Anti-Badge) -->
              <td v-if="isColumnVisible('type')" class="col-type">
                <span class="tertiary-plain-text">{{ item.institution_type_label }}</span>
              </td>

              <!-- Country (Rule 9.5: Tertiary Text #737373) -->
              <td v-if="isColumnVisible('country')" class="col-country">
                <span class="tertiary-plain-text">{{ item.country_name }}</span>
              </td>

              <!-- Admin Unit / Exact Location (Rule 9.5: Tertiary Text #737373) -->
              <td v-if="isColumnVisible('admin_unit')" class="col-admin-unit">
                <span class="tertiary-plain-text">{{ item.admin_unit_name || '—' }}</span>
              </td>

              <!-- Website -->
              <td v-if="isColumnVisible('website')" class="col-web">
                <a 
                  v-if="item.website" 
                  :href="item.website" 
                  target="_blank" 
                  rel="noopener noreferrer" 
                  class="external-portal-link"
                  @click.stop
                >
                  <Globe :size="12" />
                  <span>Portal</span>
                </a>
                <span v-else class="tertiary-plain-text">—</span>
              </td>

              <!-- Owning Entity -->
              <td v-if="isColumnVisible('entity')" class="col-entity">
                <span class="tertiary-plain-text">{{ item.entity_name }}</span>
              </td>

              <!-- Governance Status -->
              <td v-if="isColumnVisible('status')" class="col-status">
                <span class="tertiary-plain-text">{{ item.status_label }}</span>
              </td>

              <!-- Lifecycle State (Rule 9.9: Reserved exclusively for State) -->
              <td v-if="isColumnVisible('state')" class="col-state">
                <BaseBadge 
                  :color="item.state === 'active' ? 'success' : 'gray'"
                  size="sm"
                >
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </BaseBadge>
              </td>

              <!-- Actions Dropdown -->
              <td v-if="isColumnVisible('actions')" class="col-actions">
                <div class="action-menu-container">
                  <button 
                    type="button" 
                    class="btn-action-dots" 
                    @click.stop="toggleActionMenu(item.id)"
                    aria-label="Actions"
                  >
                    <MoreVertical :size="14" />
                  </button>

                  <div v-if="activeActionMenuId === item.id" class="action-dropdown" @click.stop>
                    <button class="dropdown-item" @click="handleInspect(item)">
                      <Eye :size="14" class="dropdown-icon" />
                      <span>View Details</span>
                    </button>
                    <button class="dropdown-item" @click="openEditModal(item)">
                      <Edit2 :size="14" class="dropdown-icon" />
                      <span>Edit Institution</span>
                    </button>
                    <a 
                      v-if="item.website" 
                      :href="item.website" 
                      target="_blank" 
                      rel="noopener noreferrer" 
                      class="dropdown-item"
                    >
                      <ExternalLink :size="14" class="dropdown-icon" />
                      <span>Visit Website</span>
                    </a>
                    <button class="dropdown-item" @click="handleDuplicate(item)">
                      <Copy :size="14" class="dropdown-icon" />
                      <span>Duplicate</span>
                    </button>
                    <button class="dropdown-item" @click="handleToggleState(item)">
                      <Check :size="14" class="dropdown-icon" />
                      <span>{{ item.state === 'active' ? 'Deactivate' : 'Activate' }}</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button class="dropdown-item dropdown-item-danger" @click="handleDelete(item.id)">
                      <Trash2 :size="14" class="dropdown-icon" />
                      <span>Delete</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </AppDataTable>

    <!-- ═══ FLOATING BATCH ACTION BAR (Rule 11.3) ═══ -->
    <TableFloatingBar 
      :count="selectedRowIds.length" 
      @delete="handleBatchDelete" 
    />

    <!-- ═══ QUICK CREATE / EDIT MODAL (< 5 Required Fields Flow: Rule 4) ═══ -->
    <QuickCreateModal
      :show="showQuickCreate"
      :title="editingInstitutionId ? 'Edit Institution' : 'Add Institution'"
      :showExpandButton="false"
      saveLabel="Save"
      @update:show="showQuickCreate = $event"
      @save="handleSaveQuickCreate"
      @cancel="showQuickCreate = false"
    >
      <div class="modal-form-stack">
        <!-- Field 1: Name (Schema column: name) -->
        <div class="modal-form-group">
          <label class="modal-field-label">
            Institution Name <span class="required-star">*</span>
          </label>
          <FormInput 
            v-model="quickForm.name" 
            placeholder=""
          />
        </div>

        <!-- Field 2: Institution Type (Schema column: institution_type_lookup_value_id) -->
        <div class="modal-form-group">
          <label class="modal-field-label">
            Institution Type <span class="required-star">*</span>
          </label>
          <FormSelect 
            v-model="quickForm.institution_type" 
            :options="institutionTypeOptions"
            placeholder="Select Type"
          />
        </div>

        <!-- Field 3: Location (Country & Admin Unit) (Schema columns: country_id, admin_unit_id) -->
        <div class="modal-form-row">
          <div class="modal-form-group flex-1">
            <label class="modal-field-label">Home Country <span class="required-star">*</span></label>
            <FormSelect 
              v-model="quickForm.country_id" 
              :options="countryOptions"
              placeholder="Select Country"
            />
          </div>
          <div class="modal-form-group flex-1">
            <label class="modal-field-label">Exact Location (Admin Unit)</label>
            <FormInput 
              v-model="quickForm.admin_unit_name" 
              hint="e.g. 305 (Bole, Addis Ababa) or 401 (Bahir Dar)"
            />
          </div>
        </div>

        <!-- Field 4: Website URL (Schema column: website) -->
        <div class="modal-form-group">
          <label class="modal-field-label">Official Website Portal (Optional)</label>
          <FormInput 
            v-model="quickForm.website" 
            placeholder=""
          />
        </div>

        <!-- Field 5: Governance Scope (Schema column: status_lookup_value_id) -->
        <div class="modal-form-group">
          <label class="modal-field-label">Governance Scope</label>
          <FormSelect 
            v-model="quickForm.status" 
            :options="governanceStatusOptions"
            placeholder="Select Status"
          />
        </div>
      </div>
    </QuickCreateModal>

    <!-- ═══ DETAIL INSPECTION MODAL ═══ -->
    <QuickCreateModal
      v-if="inspectingInstitution"
      :show="!!inspectingInstitution"
      title="Institution Details"
      :showExpandButton="false"
      saveLabel="Close"
      @update:show="inspectingInstitution = null"
      @save="inspectingInstitution = null"
      @cancel="inspectingInstitution = null"
    >
      <div class="inspect-details-grid">
        <div class="inspect-item">
          <span class="inspect-label">Institution Code</span>
          <span class="inspect-val font-mono">{{ inspectingInstitution.code }}</span>
        </div>
        <div class="inspect-item">
          <span class="inspect-label">Institution Name</span>
          <span class="inspect-val font-semibold">{{ inspectingInstitution.name }}</span>
        </div>
        <div class="inspect-item">
          <span class="inspect-label">Institution Classification</span>
          <span class="inspect-val">{{ inspectingInstitution.institution_type_label }}</span>
        </div>
        <div class="inspect-item">
          <span class="inspect-label">Home Country</span>
          <span class="inspect-val">{{ inspectingInstitution.country_name }} ({{ inspectingInstitution.country_id }})</span>
        </div>
        <div class="inspect-item">
          <span class="inspect-label">Exact Location (Admin Unit)</span>
          <span class="inspect-val">{{ inspectingInstitution.admin_unit_name || '—' }}</span>
        </div>
        <div class="inspect-item">
          <span class="inspect-label">Owning Entity</span>
          <span class="inspect-val">{{ inspectingInstitution.entity_name }}</span>
        </div>
        <div class="inspect-item">
          <span class="inspect-label">Governance Scope</span>
          <span class="inspect-val">{{ inspectingInstitution.status_label }}</span>
        </div>
        <div class="inspect-item" v-if="inspectingInstitution.website">
          <span class="inspect-label">Website Portal</span>
          <a :href="inspectingInstitution.website" target="_blank" class="external-portal-link">
            {{ inspectingInstitution.website }}
          </a>
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.institutions-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  width: 100%;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
}

/* Filter Toolbar Controls */
.filter-search-box {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 38px;
  padding: 0 10px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  min-width: 260px;
  transition: border-color 0.15s ease;
}

.filter-search-box:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.search-icon {
  color: #737373;
  flex-shrink: 0;
}

.filter-search-input {
  border: none;
  background: transparent;
  font-size: 13px;
  color: #404040;
  width: 100%;
  outline: none;
}

.filter-search-input::placeholder {
  color: #94a3b8;
}

.search-clear-btn {
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 2px;
  display: flex;
  align-items: center;
}

.filter-select-box {
  display: flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 10px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}

.filter-label {
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  white-space: nowrap;
}

.filter-select {
  border: none;
  background: transparent;
  font-size: 13px;
  color: #404040;
  outline: none;
  cursor: pointer;
}

/* Primary Action Button (Rule 6: 8px-10px radius, well-rounded rectangle) */
.btn-primary-create {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
  white-space: nowrap;
}

.btn-primary-create:hover {
  background-color: #09427d;
}

/* Table Standards (Rule 8 & Rule 9) */
.table-container {
  overflow-x: auto;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  background-color: #fafafa;
  color: #737373;
  font-size: 12px;
  font-weight: 500;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  border-bottom: 1px solid #f1f5f9;
  font-size: 13px;
  color: #404040;
  vertical-align: middle;
}

.erp-table tr:hover td {
  background-color: #f8fafc;
}

.row-selected td {
  background-color: #eff6ff !important;
}

/* Column Widths & Alignments */
.col-checkbox {
  width: 44px;
  padding: 0 0 0 16px !important;
  text-align: center;
}

.table-checkbox {
  width: 15px;
  height: 15px;
  accent-color: #0B529C;
  cursor: pointer;
}

.col-name {
  min-width: 240px;
}

.col-type {
  min-width: 160px;
}

.col-country {
  min-width: 120px;
}

.col-admin-unit {
  min-width: 180px;
}

.col-count {
  min-width: 140px;
}

.col-web {
  min-width: 120px;
}

.col-status {
  min-width: 160px;
}

.col-state {
  width: 100px;
}

.col-actions {
  width: 50px;
  text-align: right;
  padding-right: 16px !important;
}

/* Primary Name & Subtext Code (Rule 9.4 & 9.5) */
.field-name-block {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.table-code-subtext {
  font-size: 11px;
  font-family: monospace;
  color: #737373;
}

/* Tertiary Plain Text (Rule 9.5 & 9.6: Anti-Badge Standard) */
.tertiary-plain-text {
  color: #737373;
  font-size: 13px;
}

.external-portal-link {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  color: #0B529C;
  text-decoration: none;
  font-size: 12.5px;
  font-weight: 500;
}

.external-portal-link:hover {
  text-decoration: underline;
}

/* Action Dots Button */
.action-menu-container {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border: 1px solid transparent;
  background: transparent;
  border-radius: 6px;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #404040;
}

/* Action Dropdown Menu */
.action-dropdown {
  position: absolute;
  top: 100%;
  right: 0;
  width: 170px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.08), 0 4px 6px -2px rgba(0, 0, 0, 0.04);
  padding: 4px;
  z-index: 50;
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 7px 10px;
  font-size: 12.5px;
  color: #404040;
  background: none;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  text-decoration: none;
  transition: background-color 0.15s ease;
}

.dropdown-item:hover {
  background-color: #f1f5f9;
}

.dropdown-item-danger {
  color: #dc2626;
}

.dropdown-item-danger:hover {
  background-color: #fef2f2;
}

.dropdown-icon {
  flex-shrink: 0;
}

.dropdown-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 3px 0;
}

/* Empty State */
.empty-state-cell {
  padding: 48px 16px !important;
  text-align: center;
}

.empty-state-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.empty-state-icon {
  color: #cbd5e1;
  margin-bottom: 12px;
}

.empty-state-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}

.empty-state-subtext {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

/* Modal Form Stack */
.modal-form-stack {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.modal-form-row {
  display: flex;
  gap: 12px;
}

.flex-1 {
  flex: 1;
}

.modal-form-group {
  display: flex;
  flex-direction: column;
}

.modal-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 4px;
}

.required-star {
  color: #dc2626;
}

/* Inspect Modal Details */
.inspect-details-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 14px;
  padding: 4px 0;
}

.inspect-item {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.inspect-label {
  font-size: 11.5px;
  color: #737373;
  font-weight: 500;
}

.inspect-val {
  font-size: 13px;
  color: #404040;
}

.cursor-pointer {
  cursor: pointer;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-3px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
