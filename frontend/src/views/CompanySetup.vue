<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import {
  Building2, Plus, Search, Filter, MoreVertical, ChevronRight, HelpCircle,
  X, Check, Lock, Edit2, Trash2, ArrowUpDown, Monitor
} from 'lucide-vue-next';
import BaseTabs from '../components/BaseTabs.vue';
import MetricCard from '../components/MetricCard.vue';
import BaseButton from '../components/BaseButton.vue';
import BaseTable from '../components/BaseTable.vue';
import AppBreadcrumb from '../components/AppBreadcrumb.vue';
import QuickCreateModal from '../components/QuickCreateModal.vue';
import FormInput from '../components/FormInput.vue';
import FormSelect from '../components/FormSelect.vue';
import FormCheckbox from '../components/FormCheckbox.vue';
import FormTextarea from '../components/FormTextarea.vue';

const route = useRoute();

// Active Tab
type CompanyTab = 'parties' | 'employees' | 'entity_types';
const activeTab = ref<CompanyTab>('parties');

const syncTabFromRoute = () => {
  const t = route.query.tab as string;
  if (t === 'entity_types') {
    activeTab.value = 'entity_types';
  } else if (t === 'employees') {
    activeTab.value = 'employees';
  } else {
    activeTab.value = 'parties';
  }
};

onMounted(() => { syncTabFromRoute(); });
watch(() => route.query.tab, () => { syncTabFromRoute(); });

const tabs: { id: CompanyTab; label: string }[] = [
  { id: 'parties', label: 'Parties Management' },
  { id: 'employees', label: 'Employee Directory' },
  { id: 'entity_types', label: 'Entity Hierarchy Types' }
];

// Pagination State
const currentPage = ref(1);
const perPage = ref(10);

// Form States
const showForm = ref(false);
const editMode = ref(false);
const selectedId = ref<number | null>(null);

// Search Query
const searchQuery = ref('');

// Clear search and reset page on tab switch
watch(activeTab, () => {
  searchQuery.value = '';
  currentPage.value = 1;
});

// Seed data
const entityTypes = ref([
  { id: 1, name: 'Business Group', code: 'BUSINESS_GROUP', level: 1, parent_id: 'None', description: 'Highest level corporate unit', state: 'Active' },
  { id: 2, name: 'Organization', code: 'ORG', level: 2, parent_id: 'Business Group', description: 'Primary company legal entity', state: 'Active' },
  { id: 3, name: 'Branch', code: 'BRANCH', level: 3, parent_id: 'Organization', description: 'Regional branch offices', state: 'Active' },
  { id: 4, name: 'Shop', code: 'SHOP', level: 4, parent_id: 'Branch', description: 'Retail point of sale location', state: 'Active' }
]);

const parties = ref([
  { id: 1, uuid: 'P-9812-BG', name: 'Haleta Enterprise Group', entity_type: 'Business Group', phone: '+251 911 000 001', email: 'corporate@haleta.com', tin: 'TIN-48921-2026', is_walkin: 'No', state: 'Active' },
  { id: 2, uuid: 'P-1284-BR', name: 'Bole Road Branch', entity_type: 'Branch', phone: '+251 911 123 456', email: 'bole@haleta.com', tin: 'TIN-48921-2026', is_walkin: 'No', state: 'Active' },
  { id: 3, uuid: 'P-8291-WI', name: 'Anonymous Walk-in Customer', entity_type: 'Individual', phone: 'N/A', email: 'N/A', tin: 'N/A', is_walkin: 'Yes', state: 'Active' }
]);

const employees = ref([
  { id: 1, uuid: 'EMP-001', name: 'Marta Tadesse', entity: 'Bole Road Branch', party_name: 'Marta Tadesse (Individual)', state: 'Active' },
  { id: 2, uuid: 'EMP-002', name: 'John Doe', entity: 'Haleta Enterprise Group', party_name: 'John Doe (Individual)', state: 'Active' }
]);

// Dynamic Counts for stats
const stats = computed(() => {
  return [
    { label: 'Total Entities', value: entityTypes.value.length.toString(), icon: Building2, color: 'text-indigo-600', bg: 'bg-indigo-50' },
    { label: 'Registered Parties', value: parties.value.length.toString(), icon: Building2, color: 'text-emerald-600', bg: 'bg-emerald-50' },
    { label: 'Active Employees', value: employees.value.length.toString(), icon: Building2, color: 'text-orange-600', bg: 'bg-orange-50' }
  ];
});

// Form input state
const formState = ref({
  // Entity Type fields
  et_name: '',
  et_code: '',
  et_level: 1,
  et_parent: 'None',
  et_desc: '',
  
  // Party fields
  p_name: '',
  p_entity_type: 'Branch',
  p_phone: '',
  p_email: '',
  p_tin: '',
  p_walkin: 'No',

  // Employee fields
  emp_name: '',
  emp_entity: 'Bole Road Branch',
  emp_party: ''
});

// Table Filtering and Search
const filteredParties = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return parties.value;
  return parties.value.filter(p => 
    p.name.toLowerCase().includes(q) || 
    p.uuid.toLowerCase().includes(q) || 
    p.phone.toLowerCase().includes(q) ||
    p.email.toLowerCase().includes(q)
  );
});

const filteredEmployees = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return employees.value;
  return employees.value.filter(e => 
    e.name.toLowerCase().includes(q) || 
    e.uuid.toLowerCase().includes(q) || 
    e.entity.toLowerCase().includes(q)
  );
});

const filteredEntityTypes = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return entityTypes.value;
  return entityTypes.value.filter(et => 
    et.name.toLowerCase().includes(q) || 
    et.code.toLowerCase().includes(q) || 
    et.parent_id.toLowerCase().includes(q)
  );
});

const currentList = computed(() => {
  if (activeTab.value === 'parties') return filteredParties.value;
  if (activeTab.value === 'employees') return filteredEmployees.value;
  return filteredEntityTypes.value;
});

const paginatedParties = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredParties.value.slice(start, start + perPage.value);
});

const paginatedEmployees = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredEmployees.value.slice(start, start + perPage.value);
});

const paginatedEntityTypes = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredEntityTypes.value.slice(start, start + perPage.value);
});

// Actions
const openAddForm = () => {
  editMode.value = false;
  selectedId.value = null;
  formState.value = {
    et_name: '', et_code: '', et_level: 1, et_parent: 'None', et_desc: '',
    p_name: '', p_entity_type: 'Branch', p_phone: '', p_email: '', p_tin: '', p_walkin: 'No',
    emp_name: '', emp_entity: 'Bole Road Branch', emp_party: ''
  };
  showForm.value = true;
};

const handleSave = () => {
  if (activeTab.value === 'entity_types') {
    if (!formState.value.et_name || !formState.value.et_code) {
      alert('Please fill out the Entity Type Name and Code.');
      return;
    }
    if (editMode.value && selectedId.value !== null) {
      const idx = entityTypes.value.findIndex(et => et.id === selectedId.value);
      if (idx !== -1) {
        entityTypes.value[idx].name = formState.value.et_name;
        entityTypes.value[idx].code = formState.value.et_code;
        entityTypes.value[idx].level = Number(formState.value.et_level);
        entityTypes.value[idx].parent_id = formState.value.et_parent;
        entityTypes.value[idx].description = formState.value.et_desc;
      }
    } else {
      entityTypes.value.push({
        id: Date.now(),
        name: formState.value.et_name,
        code: formState.value.et_code.toUpperCase().replace(/\s+/g, '_'),
        level: Number(formState.value.et_level),
        parent_id: formState.value.et_parent,
        description: formState.value.et_desc,
        state: 'Active'
      });
    }
  } else if (activeTab.value === 'parties') {
    if (!formState.value.p_name) {
      alert('Please fill out the Party Name.');
      return;
    }
    if (editMode.value && selectedId.value !== null) {
      const idx = parties.value.findIndex(p => p.id === selectedId.value);
      if (idx !== -1) {
        parties.value[idx].name = formState.value.p_name;
        parties.value[idx].entity_type = formState.value.p_entity_type;
        parties.value[idx].phone = formState.value.p_phone || 'N/A';
        parties.value[idx].email = formState.value.p_email || 'N/A';
        parties.value[idx].tin = formState.value.p_tin || 'N/A';
        parties.value[idx].is_walkin = formState.value.p_walkin;
      }
    } else {
      const formattedUuid = 'P-' + Math.floor(1000 + Math.random() * 9000) + '-' + formState.value.p_entity_type.substring(0, 2).toUpperCase();
      parties.value.push({
        id: Date.now(),
        uuid: formattedUuid,
        name: formState.value.p_name,
        entity_type: formState.value.p_entity_type,
        phone: formState.value.p_phone || 'N/A',
        email: formState.value.p_email || 'N/A',
        tin: formState.value.p_tin || 'N/A',
        is_walkin: formState.value.p_walkin,
        state: 'Active'
      });
    }
  } else if (activeTab.value === 'employees') {
    if (!formState.value.emp_name) {
      alert('Please fill out the Employee Name.');
      return;
    }
    if (editMode.value && selectedId.value !== null) {
      const idx = employees.value.findIndex(emp => emp.id === selectedId.value);
      if (idx !== -1) {
        employees.value[idx].name = formState.value.emp_name;
        employees.value[idx].entity = formState.value.emp_entity;
        employees.value[idx].party_name = formState.value.emp_party || formState.value.emp_name + ' (Individual)';
      }
    } else {
      const formattedUuid = 'EMP-' + Math.floor(100 + Math.random() * 900);
      employees.value.push({
        id: Date.now(),
        uuid: formattedUuid,
        name: formState.value.emp_name,
        entity: formState.value.emp_entity,
        party_name: formState.value.emp_party || formState.value.emp_name + ' (Individual)',
        state: 'Active'
      });
    }
  }
  showForm.value = false;
};

const handleEdit = (item: any) => {
  editMode.value = true;
  selectedId.value = item.id;
  if (activeTab.value === 'entity_types') {
    formState.value.et_name = item.name;
    formState.value.et_code = item.code;
    formState.value.et_level = item.level;
    formState.value.et_parent = item.parent_id;
    formState.value.et_desc = item.description;
  } else if (activeTab.value === 'parties') {
    formState.value.p_name = item.name;
    formState.value.p_entity_type = item.entity_type;
    formState.value.p_phone = item.phone === 'N/A' ? '' : item.phone;
    formState.value.p_email = item.email === 'N/A' ? '' : item.email;
    formState.value.p_tin = item.tin === 'N/A' ? '' : item.tin;
    formState.value.p_walkin = item.is_walkin;
  } else if (activeTab.value === 'employees') {
    formState.value.emp_name = item.name;
    formState.value.emp_entity = item.entity;
    formState.value.emp_party = item.party_name;
  }
  showForm.value = true;
};

const handleDelete = (id: number) => {
  if (!confirm('Are you sure you want to delete this record?')) return;
  if (activeTab.value === 'entity_types') {
    entityTypes.value = entityTypes.value.filter(et => et.id !== id);
  } else if (activeTab.value === 'parties') {
    parties.value = parties.value.filter(p => p.id !== id);
  } else if (activeTab.value === 'employees') {
    employees.value = employees.value.filter(emp => emp.id !== id);
  }
};
</script>

<template>
  <div class="company-setup-page">
    <!-- Breadcrumbs -->
    <div class="breadcrumbs">
      <router-link to="/dashboard" class="breadcrumb-link">
        <Monitor :size="16" />
      </router-link>
      <ChevronRight :size="12" class="breadcrumb-separator" />
      <span class="breadcrumb-active">Company Setup</span>
    </div>

    <!-- Stats Grid (Using Centralized MetricCard Component) -->
    <div class="stats-grid">
      <MetricCard 
        v-for="stat in stats" 
        :key="stat.label" 
        :label="stat.label" 
        :value="stat.value" 
        subtext="Active entity units"
      />
    </div>

    <!-- Main Content BaseTable -->
    <BaseTable
      title="Entities, Employees & Parties"
      subtitle="Organize company structures, employee associations, and party identities. Set up entity types like business groups or branches, register individual and enterprise party identifiers, and manage staff records."
      v-model:searchQuery="searchQuery"
      :totalEntries="currentList.length"
      v-model:currentPage="currentPage"
      v-model:perPage="perPage"
      :showFilter="false"
      :showColumns="false"
    >
      <template #header-bottom>
        <div class="tabs-bar mb-3">
          <BaseTabs v-model="activeTab" :tabs="tabs" />
        </div>
      </template>

      <template #actions>
        <BaseButton variant="primary" @click="openAddForm">
          <template #icon-left><Plus :size="18" stroke-width="2.5" /></template>
          <span>Add New Record</span>
        </BaseButton>
      </template>

      <!-- TAB 1: PARTIES -->
      <table v-if="activeTab === 'parties'" class="erp-table">
        <thead>
          <tr>
            <th width="150">Party ID</th>
            <th>Display Name</th>
            <th width="150">Entity Type</th>
            <th width="180">Phone Number</th>
            <th width="200">Email Address</th>
            <th width="120">TIN Number</th>
            <th width="110">Walk-In?</th>
            <th width="120">Status</th>
            <th width="120" class="text-right">Action</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in paginatedParties" :key="p.id">
            <td class="col-primary-title font-mono">{{ p.uuid }}</td>
            <td class="col-primary-title">{{ p.name }}</td>
            <td class="col-secondary-text">{{ p.entity_type }}</td>
            <td class="col-secondary-text">{{ p.phone }}</td>
            <td class="col-secondary-text">{{ p.email }}</td>
            <td class="col-secondary-text font-mono">{{ p.tin }}</td>
            <td>
              <span :class="['walkin-badge', p.is_walkin === 'Yes' ? 'yes' : 'no']">{{ p.is_walkin }}</span>
            </td>
            <td>
              <span class="status-pill pill-active">
                {{ p.state }}
              </span>
            </td>
            <td class="text-right">
              <div class="action-buttons-cell justify-end">
                <button @click="handleEdit(p)" class="btn-action-icon" title="Edit"><Edit2 :size="15" /></button>
                <button @click="handleDelete(p.id)" class="btn-action-icon text-red-500" title="Delete"><Trash2 :size="15" /></button>
              </div>
            </td>
          </tr>
          <tr v-if="filteredParties.length === 0">
            <td colspan="9" class="text-center py-8 text-slate-400">No parties found matching query.</td>
          </tr>
        </tbody>
      </table>

      <!-- TAB 2: EMPLOYEES -->
      <table v-if="activeTab === 'employees'" class="erp-table">
        <thead>
          <tr>
            <th width="150">Employee ID</th>
            <th>Full Name</th>
            <th>Assigned Entity</th>
            <th>Linked Party Identity</th>
            <th width="120">Status</th>
            <th width="120" class="text-right">Action</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="e in paginatedEmployees" :key="e.id">
            <td class="col-primary-title font-mono">{{ e.uuid }}</td>
            <td class="col-primary-title">{{ e.name }}</td>
            <td class="col-secondary-text">{{ e.entity }}</td>
            <td class="col-secondary-desc font-mono">{{ e.party_name }}</td>
            <td>
              <span class="status-pill pill-active">
                {{ e.state }}
              </span>
            </td>
            <td class="text-right">
              <div class="action-buttons-cell justify-end">
                <button @click="handleEdit(e)" class="btn-action-icon" title="Edit"><Edit2 :size="15" /></button>
                <button @click="handleDelete(e.id)" class="btn-action-icon text-red-500" title="Delete"><Trash2 :size="15" /></button>
              </div>
            </td>
          </tr>
          <tr v-if="filteredEmployees.length === 0">
            <td colspan="6" class="text-center py-8 text-slate-400">No employees found.</td>
          </tr>
        </tbody>
      </table>

      <!-- TAB 3: ENTITY TYPES -->
      <table v-if="activeTab === 'entity_types'" class="erp-table">
        <thead>
          <tr>
            <th width="80">Level</th>
            <th>Name</th>
            <th>System Code</th>
            <th>Parent Type</th>
            <th>Scope Description</th>
            <th width="120">Status</th>
            <th width="120" class="text-right">Action</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="et in paginatedEntityTypes" :key="et.id">
            <td class="text-center font-bold text-indigo-600">Lvl {{ et.level }}</td>
            <td class="col-primary-title">{{ et.name }}</td>
            <td class="col-secondary-text font-mono">{{ et.code }}</td>
            <td class="col-secondary-text">{{ et.parent_id }}</td>
            <td class="col-secondary-desc">{{ et.description }}</td>
            <td>
              <span class="status-pill pill-active">
                {{ et.state }}
              </span>
            </td>
            <td class="text-right">
              <div class="action-buttons-cell justify-end">
                <button @click="handleEdit(et)" class="btn-action-icon" title="Edit"><Edit2 :size="15" /></button>
                <button @click="handleDelete(et.id)" class="btn-action-icon text-red-500" title="Delete"><Trash2 :size="15" /></button>
              </div>
            </td>
          </tr>
          <tr v-if="filteredEntityTypes.length === 0">
            <td colspan="7" class="text-center py-8 text-slate-400">No entity types found.</td>
          </tr>
        </tbody>
      </table>
    </BaseTable>

    <!-- QUICK CREATE / EDIT MODAL -->
    <QuickCreateModal
      v-model:show="showForm"
      :title="`${editMode ? 'Edit' : 'Create'} ${activeTab === 'parties' ? 'Party Identity' : activeTab === 'employees' ? 'Employee Staff File' : 'Hierarchy Entity Type'}`"
      :showExpandButton="false"
      @save="handleSave"
    >
      <!-- FORM 1: PARTIES -->
      <div v-if="activeTab === 'parties'" class="space-y-3.5">
        <FormInput
          v-model="formState.p_name"
          label="Display Name"
          :required="true"
        />

        <div class="grid grid-cols-2 gap-3">
          <FormSelect
            v-model="formState.p_entity_type"
            label="Identity Type"
            :options="['Business Group', 'Organization', 'Branch', 'Shop', 'Individual']"
          />

          <FormInput
            v-model="formState.p_tin"
            label="Tax ID (TIN)"
          />
        </div>

        <div class="grid grid-cols-2 gap-3">
          <FormInput
            v-model="formState.p_phone"
            label="Primary Phone"
          />

          <FormInput
            v-model="formState.p_email"
            label="Primary Email"
            type="email"
          />
        </div>

        <FormCheckbox
          :modelValue="formState.p_walkin === 'Yes'"
          label="Mark as walk-in / temporary identity?"
          description="Enable fast tracking for unregistered consumer entities."
          @update:modelValue="(val) => formState.p_walkin = val ? 'Yes' : 'No'"
        />
      </div>

      <!-- FORM 2: EMPLOYEES -->
      <div v-if="activeTab === 'employees'" class="space-y-3.5">
        <FormInput
          v-model="formState.emp_name"
          label="Employee Full Name"
          :required="true"
        />

        <FormSelect
          v-model="formState.emp_entity"
          label="Assigned Entity Scope"
          :required="true"
          :options="['Haleta Enterprise Group', 'Bole Road Branch', 'Downtown Shop']"
        />

        <FormInput
          v-model="formState.emp_party"
          label="Linked Party Identity"
          helperText="Every employee represents a Party identity in the business world."
        />
      </div>

      <!-- FORM 3: ENTITY TYPES -->
      <div v-if="activeTab === 'entity_types'" class="space-y-3.5">
        <div class="grid grid-cols-2 gap-3">
          <FormInput
            v-model="formState.et_name"
            label="Human-Readable Name"
            :required="true"
          />

          <FormInput
            v-model="formState.et_code"
            label="System Code"
            :required="true"
          />
        </div>

        <div class="grid grid-cols-2 gap-3">
          <FormInput
            v-model="formState.et_level"
            label="Hierarchy Level"
            type="number"
          />

          <FormSelect
            v-model="formState.et_parent"
            label="Parent Type"
            :options="['None (Root Level)', 'Business Group', 'Organization', 'Branch']"
          />
        </div>

        <FormTextarea
          v-model="formState.et_desc"
          label="Scope Description"
          :rows="3"
        />
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.company-setup-page {
  animation: fadeIn 0.4s ease-out;
  display: flex;
  flex-direction: column;
  gap: 16px;
  font-family: 'Inter', sans-serif;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Breadcrumbs */
.breadcrumbs {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  margin-bottom: 20px;
}
.breadcrumb-link {
  color: #9ca3af;
  text-decoration: none;
  display: flex;
  align-items: center;
  transition: color 0.15s ease;
}
.breadcrumb-link:hover {
  color: #111827;
}
.breadcrumb-separator {
  color: #9ca3af;
  display: flex;
  align-items: center;
}
.breadcrumb-active {
  color: #111827;
  font-weight: 500;
}

/* Stats */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 24px;
}
.stat-card {
  background: white;
  padding: 24px;
  border-radius: 16px;
  border: 1px solid #f3f4f6;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}
.stat-header {
  margin-bottom: 12px;
}
.stat-icon-box {
  padding: 10px;
  border-radius: 12px;
  display: inline-flex;
}
.stat-label { font-size: 14px; color: #6b7280; margin-bottom: 4px; }
.stat-value { font-size: 24px; font-weight: 700; color: #111827; }

.bg-indigo-50 { background-color: #e0e7ff; }
.text-indigo-600 { color: #4f46e5; }
.bg-emerald-50 { background-color: #ecfdf5; }
.text-emerald-600 { color: #059669; }
.bg-orange-50 { background-color: #fff7ed; }
.text-orange-600 { color: #ea580c; }

/* Content Card */
.content-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  padding: 0;
  box-shadow: 0 1px 3px rgba(0,0,0,0.02);
  overflow: hidden;
}
.page-header {
  padding: 24px 24px 8px 24px;
}
.page-title {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin-bottom: 8px;
}
.page-description {
  font-size: 14px;
  color: #6b7280;
  line-height: 1.6;
}

/* Tabs Bar */
.tabs-bar {
  display: flex;
  padding: 16px 24px;
  background-color: #fcfcfd;
  border-bottom: 1px solid #e5e7eb;
}

/* Action Bar */
.action-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 24px;
  gap: 16px;
}
.action-bar-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}
.search-input-wrapper {
  position: relative;
  flex: 1;
  max-width: 320px;
}
.search-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: #9ca3af;
  z-index: 10;
}
.table-search {
  width: 100%;
  padding: 10px 12px 10px 40px;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  font-size: 14px;
  outline: none;
  transition: all 0.2s;
  height: 42px;
  background: white;
}
.table-search:focus { border-color: #d1d5db; box-shadow: 0 0 0 4px rgba(0,0,0,0.02); }

.btn-create {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 20px;
  height: 42px;
  background: var(--alias-color-brand-blue-primary);
  color: #ffffff;
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-create:hover {
  background: var(--alias-color-brand-blue-primary-hover);
  transform: translateY(-1px);
}

/* Tables */
.table-wrapper {
  overflow-x: auto;
  border-top: 1px solid #e5e7eb;
}
.gate-pass-table {
  width: 100%;
  border-collapse: collapse;
}
.gate-pass-table th {
  text-align: left;
  padding: 12px 24px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background: #fafafa;
  border-bottom: 1px solid #e5e7eb;
}
.gate-pass-table td {
  padding: 14px 24px;
  font-size: 13.5px;
  color: #737373;
  border-bottom: 1px solid #f3f4f6;
  vertical-align: middle;
}
.gate-pass-table td:nth-child(2) {
  color: #262626;
  font-weight: 600;
}
.gate-pass-table tr:hover {
  background-color: #fcfcfd;
}

code {
  background-color: #f1f5f9;
  padding: 2px 6px;
  border-radius: 4px;
  font-family: monospace;
  font-size: 12px;
  color: #0f172a;
}

.walkin-badge {
  display: inline-flex;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
}
.walkin-badge.yes { background-color: #fff7ed; color: #c2410c; }
.walkin-badge.no { background-color: #f1f5f9; color: #475569; }

.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
}
.status-completed { background: #ecfdf5; color: #059669; }
.dot { width: 6px; height: 6px; background: #10b981; border-radius: 50%; }

.action-buttons-cell {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}
.btn-action-icon {
  background: none;
  border: none;
  padding: 6px;
  border-radius: 6px;
  color: #6b7280;
  cursor: pointer;
  transition: all 0.15s;
}
.btn-action-icon:hover {
  background-color: #f3f4f6;
  color: #111827;
}

/* Modals */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(15, 23, 42, 0.4);
  backdrop-filter: blur(4px);
  z-index: 1100;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}
.modal-card {
  background: white;
  border-radius: 16px;
  width: 100%;
  max-width: 520px;
  padding: 24px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  position: relative;
  display: flex;
  flex-direction: column;
}
.modal-close-btn {
  position: absolute;
  top: 20px;
  right: 20px;
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 6px;
  border-radius: 50%;
  display: flex;
}
.modal-close-btn:hover { background-color: #f1f5f9; color: #475569; }

.modal-card-header h3 {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 20px;
}

.form-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.form-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}
.form-label {
  font-size: 13px;
  font-weight: 600;
  color: #374151;
}
.form-input, .form-select, .form-textarea {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 14px;
  outline: none;
  background-color: white;
  transition: all 0.15s ease;
}
.form-input:focus, .form-select:focus, .form-textarea:focus {
  border-color: #111827;
}
.form-tip-text {
  font-size: 11px;
  color: #9ca3af;
  margin-top: 2px;
}
.form-textarea {
  resize: vertical;
}

.inline-checkbox .column-option {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
  color: #374151;
  cursor: pointer;
  user-select: none;
}
.column-option input[type="checkbox"] {
  cursor: pointer;
  accent-color: #111827;
  width: 18px;
  height: 18px;
}

.modal-footer-row {
  display: flex;
  gap: 12px;
  margin-top: 24px;
}
.btn-modal-primary, .btn-modal-secondary {
  flex: 1;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  text-align: center;
}
.btn-modal-primary {
  background-color: var(--alias-color-brand-blue-primary);
  color: white;
  border: none;
}
.btn-modal-primary:hover { background-color: var(--alias-color-brand-blue-primary-hover); }
.btn-modal-secondary {
  background-color: white;
  color: #475569;
  border: 1px solid #e2e8f0;
}
.btn-modal-secondary:hover { background-color: #f8fafc; }
</style>
