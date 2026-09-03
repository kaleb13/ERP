<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import {
  ShoppingBag, Plus, Search, ChevronRight, HelpCircle,
  X, Check, Lock, Edit2, Trash2, Monitor
} from 'lucide-vue-next';
import BaseTabs from '../components/BaseTabs.vue';
import BaseButton from '../components/BaseButton.vue';
import BaseTable from '../components/BaseTable.vue';
import MetricCard from '../components/MetricCard.vue';
import AppBreadcrumb from '../components/AppBreadcrumb.vue';
import QuickCreateModal from '../components/QuickCreateModal.vue';
import FormInput from '../components/FormInput.vue';
import FormSelect from '../components/FormSelect.vue';
import FormTextarea from '../components/FormTextarea.vue';

// Active Tab
const activeTab = ref<'customers' | 'customer_groups'>('customers');
const tabs: { id: 'customers' | 'customer_groups'; label: string }[] = [
  { id: 'customers', label: 'Customers List' },
  { id: 'customer_groups', label: 'Customer Groups' }
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

// Clear the search box and reset page whenever the active tab changes
watch(activeTab, () => {
  searchQuery.value = '';
  currentPage.value = 1;
});

// Seed data
const customerGroups = ref([
  { id: 1, name: 'Wholesale Customers', description: 'Bulk buying discount tier', entity: 'Haleta Enterprise Group', status_lookup: 'Approved', state: 'Active' },
  { id: 2, name: 'Retail Customers', description: 'Standard consumer tier', entity: 'Bole Road Branch', status_lookup: 'Approved', state: 'Active' },
  { id: 3, name: 'Corporate Clients', description: 'Special contract accounts', entity: 'Haleta Enterprise Group', status_lookup: 'Pending Approval', state: 'Active' }
]);

const customers = ref([
  { id: 1, uuid: 'CUST-0098', party_name: 'Almaz Abraham', entity: 'Bole Road Branch', group: 'Retail Customers', credit_limit: 15000, loyalty: 'Yes', state: 'Active' },
  { id: 2, uuid: 'CUST-0045', party_name: 'Kebede & Sons Trading', entity: 'Haleta Enterprise Group', group: 'Wholesale Customers', credit_limit: 250000, loyalty: 'No', state: 'Active' }
]);

// Dynamic Counts for stats
const stats = computed(() => {
  return [
    { label: 'Total Customers', value: customers.value.length.toString(), icon: ShoppingBag, color: 'text-indigo-600', bg: 'bg-indigo-50' },
    { label: 'Customer Groups', value: customerGroups.value.length.toString(), icon: ShoppingBag, color: 'text-emerald-600', bg: 'bg-emerald-50' },
    { label: 'Credit Allocated', value: '$' + customers.value.reduce((acc, curr) => acc + curr.credit_limit, 0).toLocaleString(), icon: ShoppingBag, color: 'text-orange-600', bg: 'bg-orange-50' }
  ];
});

// Form input state
const formState = ref({
  // Customer Group fields
  cg_name: '',
  cg_desc: '',
  cg_entity: 'Haleta Enterprise Group',
  cg_status: 'Approved',
  
  // Customer fields
  c_party: '',
  c_entity: 'Bole Road Branch',
  c_group: 'Retail Customers',
  c_limit: 10000,
  c_loyalty: 'No'
});

// Table Filtering and Search
const filteredCustomers = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return customers.value;
  return customers.value.filter(c => 
    c.party_name.toLowerCase().includes(q) || 
    c.uuid.toLowerCase().includes(q) || 
    c.group.toLowerCase().includes(q)
  );
});

const filteredCustomerGroups = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return customerGroups.value;
  return customerGroups.value.filter(cg => 
    cg.name.toLowerCase().includes(q) || 
    cg.entity.toLowerCase().includes(q)
  );
});

const currentList = computed(() => {
  if (activeTab.value === 'customers') return filteredCustomers.value;
  return filteredCustomerGroups.value;
});

const paginatedCustomers = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredCustomers.value.slice(start, start + perPage.value);
});

const paginatedCustomerGroups = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredCustomerGroups.value.slice(start, start + perPage.value);
});

// Actions
const openAddForm = () => {
  editMode.value = false;
  selectedId.value = null;
  formState.value = {
    cg_name: '', cg_desc: '', cg_entity: 'Haleta Enterprise Group', cg_status: 'Approved',
    c_party: '', c_entity: 'Bole Road Branch', c_group: 'Retail Customers', c_limit: 10000, c_loyalty: 'No'
  };
  showForm.value = true;
};

const handleSave = () => {
  if (activeTab.value === 'customer_groups') {
    if (!formState.value.cg_name) {
      alert('Please fill out the Customer Group Name.');
      return;
    }
    if (editMode.value && selectedId.value !== null) {
      const idx = customerGroups.value.findIndex(cg => cg.id === selectedId.value);
      if (idx !== -1) {
        customerGroups.value[idx].name = formState.value.cg_name;
        customerGroups.value[idx].description = formState.value.cg_desc;
        customerGroups.value[idx].entity = formState.value.cg_entity;
        customerGroups.value[idx].status_lookup = formState.value.cg_status;
      }
    } else {
      customerGroups.value.push({
        id: Date.now(),
        name: formState.value.cg_name,
        description: formState.value.cg_desc || 'No description',
        entity: formState.value.cg_entity,
        status_lookup: formState.value.cg_status,
        state: 'Active'
      });
    }
  } else if (activeTab.value === 'customers') {
    if (!formState.value.c_party) {
      alert('Please fill out the Customer / Party Name.');
      return;
    }
    if (editMode.value && selectedId.value !== null) {
      const idx = customers.value.findIndex(c => c.id === selectedId.value);
      if (idx !== -1) {
        customers.value[idx].party_name = formState.value.c_party;
        customers.value[idx].entity = formState.value.c_entity;
        customers.value[idx].group = formState.value.c_group;
        customers.value[idx].credit_limit = Number(formState.value.c_limit);
        customers.value[idx].loyalty = formState.value.c_loyalty;
      }
    } else {
      const formattedUuid = 'CUST-' + Math.floor(1000 + Math.random() * 9000);
      customers.value.push({
        id: Date.now(),
        uuid: formattedUuid,
        party_name: formState.value.c_party,
        entity: formState.value.c_entity,
        group: formState.value.c_group,
        credit_limit: Number(formState.value.c_limit),
        loyalty: formState.value.c_loyalty,
        state: 'Active'
      });
    }
  }
  showForm.value = false;
};

const handleEdit = (item: any) => {
  editMode.value = true;
  selectedId.value = item.id;
  if (activeTab.value === 'customer_groups') {
    formState.value.cg_name = item.name;
    formState.value.cg_desc = item.description;
    formState.value.cg_entity = item.entity;
    formState.value.cg_status = item.status_lookup;
  } else if (activeTab.value === 'customers') {
    formState.value.c_party = item.party_name;
    formState.value.c_entity = item.entity;
    formState.value.c_group = item.group;
    formState.value.c_limit = item.credit_limit;
    formState.value.c_loyalty = item.loyalty;
  }
  showForm.value = true;
};

const handleDelete = (id: number) => {
  if (!confirm('Are you sure you want to delete this record?')) return;
  if (activeTab.value === 'customer_groups') {
    customerGroups.value = customerGroups.value.filter(cg => cg.id !== id);
  } else if (activeTab.value === 'customers') {
    customers.value = customers.value.filter(c => c.id !== id);
  }
};
</script>

<template>
  <div class="sales-module-page">
    <!-- Standard Breadcrumbs -->
    <AppBreadcrumb :items="[{ label: 'Sales Module' }]" />

    <!-- Stats Grid (Using Centralized MetricCard Component) -->
    <div class="stats-grid mb-5">
      <MetricCard
        v-for="stat in stats"
        :key="stat.label"
        :label="stat.label"
        :value="stat.value"
        :icon="stat.icon"
        :showMenu="false"
      />
    </div>

    <!-- Main Content BaseTable -->
    <BaseTable
      title="Customers & Customer Groups"
      subtitle="Administer customer registry and segmentation profiles. Set credit boundaries, enroll key clients in custom wholesale/retail loyalty tiers, and manage billing entity assignments."
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
          <span>Add New {{ activeTab === 'customers' ? 'Customer' : 'Group' }}</span>
        </BaseButton>
      </template>

      <!-- TAB 1: CUSTOMERS -->
      <table v-if="activeTab === 'customers'" class="erp-table">
        <thead>
          <tr>
            <th width="150">Customer ID</th>
            <th>Customer Name (Party)</th>
            <th>Assigned Entity</th>
            <th>Customer Group</th>
            <th>Credit Limit ($)</th>
            <th width="150" class="text-center">Loyalty Opt-In?</th>
            <th width="120">Status</th>
            <th width="120" class="text-right">Action</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="c in paginatedCustomers" :key="c.id">
            <td class="col-primary-title font-mono">{{ c.uuid }}</td>
            <td class="col-primary-title">{{ c.party_name }}</td>
            <td class="col-secondary-text">{{ c.entity }}</td>
            <td>
              <span class="group-tag">{{ c.group }}</span>
            </td>
            <td class="col-primary-title font-semibold">${{ c.credit_limit.toLocaleString() }}</td>
            <td class="text-center">
              <span :class="['loyalty-badge', c.loyalty === 'Yes' ? 'yes' : 'no']">{{ c.loyalty }}</span>
            </td>
            <td>
              <span class="status-pill pill-active">
                {{ c.state }}
              </span>
            </td>
            <td class="text-right">
              <div class="action-buttons-cell justify-end">
                <button @click="handleEdit(c)" class="btn-action-icon" title="Edit"><Edit2 :size="15" /></button>
                <button @click="handleDelete(c.id)" class="btn-action-icon text-red-500" title="Delete"><Trash2 :size="15" /></button>
              </div>
            </td>
          </tr>
          <tr v-if="filteredCustomers.length === 0">
            <td colspan="8" class="text-center py-8 text-slate-400">No customers found matching query.</td>
          </tr>
        </tbody>
      </table>

      <!-- TAB 2: CUSTOMER GROUPS -->
      <table v-if="activeTab === 'customer_groups'" class="erp-table">
        <thead>
          <tr>
            <th>Group Name</th>
            <th>Group Scope / Description</th>
            <th>Assigned Entity</th>
            <th width="180">Status Lookup Value</th>
            <th width="120">State</th>
            <th width="120" class="text-right">Action</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="cg in paginatedCustomerGroups" :key="cg.id">
            <td class="col-primary-title">{{ cg.name }}</td>
            <td class="col-secondary-desc">{{ cg.description }}</td>
            <td class="col-secondary-text">{{ cg.entity }}</td>
            <td>
              <span :class="['status-lookup-badge', cg.status_lookup === 'Approved' ? 'approved' : 'pending']">
                {{ cg.status_lookup }}
              </span>
            </td>
            <td>
              <span class="status-pill pill-active">
                {{ cg.state }}
              </span>
            </td>
            <td class="text-right">
              <div class="action-buttons-cell justify-end">
                <button @click="handleEdit(cg)" class="btn-action-icon" title="Edit"><Edit2 :size="15" /></button>
                <button @click="handleDelete(cg.id)" class="btn-action-icon text-red-500" title="Delete"><Trash2 :size="15" /></button>
              </div>
            </td>
          </tr>
          <tr v-if="filteredCustomerGroups.length === 0">
            <td colspan="6" class="text-center py-8 text-slate-400">No customer groups found.</td>
          </tr>
        </tbody>
      </table>
    </BaseTable>

    <!-- QUICK CREATE / EDIT MODAL -->
    <QuickCreateModal
      v-model:show="showForm"
      :title="`${editMode ? 'Edit' : 'Create'} ${activeTab === 'customers' ? 'Customer Profile' : 'Customer Segment Group'}`"
      :showExpandButton="false"
      @save="handleSave"
    >
      <!-- FORM 1: CUSTOMER -->
      <div v-if="activeTab === 'customers'" class="space-y-3.5">
        <FormInput
          v-model="formState.c_party"
          label="Customer Name (Party Link)"
          :required="true"
        />

        <div class="grid grid-cols-2 gap-3">
          <FormSelect
            v-model="formState.c_group"
            label="Customer Segment Group"
            :options="customerGroups.map(g => ({ value: g.name, label: g.name }))"
          />

          <FormSelect
            v-model="formState.c_entity"
            label="Assigned Entity"
            :options="['Haleta Enterprise Group', 'Bole Road Branch']"
          />
        </div>

        <div class="grid grid-cols-2 gap-3">
          <FormInput
            v-model="formState.c_limit"
            label="Allowed Credit Limit ($)"
            type="number"
            :required="true"
          />

          <FormSelect
            v-model="formState.c_loyalty"
            label="Loyalty Tier Enroll"
            :options="['Yes', 'No']"
          />
        </div>
      </div>

      <!-- FORM 2: CUSTOMER GROUPS -->
      <div v-if="activeTab === 'customer_groups'" class="space-y-3.5">
        <FormInput
          v-model="formState.cg_name"
          label="Group Category Name"
          :required="true"
        />

        <div class="grid grid-cols-2 gap-3">
          <FormSelect
            v-model="formState.cg_entity"
            label="Assigned Entity Scope"
            :options="['Haleta Enterprise Group', 'Bole Road Branch']"
          />

          <FormSelect
            v-model="formState.cg_status"
            label="Registration Status"
            :options="['Approved', 'Pending Approval']"
          />
        </div>

        <FormTextarea
          v-model="formState.cg_desc"
          label="Group Description"
          :rows="3"
        />
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.sales-module-page {
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

.group-tag {
  background-color: #f1f5f9;
  padding: 3px 8px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  color: #334155;
  border: 1px solid #e2e8f0;
}

.loyalty-badge {
  display: inline-flex;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
}
.loyalty-badge.yes { background-color: #ecfdf5; color: #047857; }
.loyalty-badge.no { background-color: #f1f5f9; color: #475569; }

.status-lookup-badge {
  display: inline-flex;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
}
.status-lookup-badge.approved { background-color: #e0f2fe; color: #0369a1; }
.status-lookup-badge.pending { background-color: #fef3c7; color: #b45309; }

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
  gap: 4px;
}
.form-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}
.form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 3px;
}
.form-input, .form-select {
  width: 100%;
  height: 38px;
  padding: 0 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  outline: none;
  background-color: white;
  color: #1e293b;
  transition: all 0.15s ease;
}
.form-textarea {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  outline: none;
  background-color: white;
  color: #1e293b;
  transition: all 0.15s ease;
}
.form-input:focus, .form-select:focus, .form-textarea:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}
.form-tip-text {
  font-size: 11px;
  color: #9ca3af;
  margin-top: 2px;
}
.form-textarea {
  resize: vertical;
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
