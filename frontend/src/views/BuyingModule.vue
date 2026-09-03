<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { 
  ShoppingCart, Plus, Search, ChevronRight, HelpCircle,
  X, Check, Lock, Edit2, Trash2, MoreVertical, Eye, Monitor
} from 'lucide-vue-next';
import BaseTable from '../components/BaseTable.vue';
import BaseButton from '../components/BaseButton.vue';
import QuickCreateModal from '../components/QuickCreateModal.vue';
import FormInput from '../components/FormInput.vue';
import FormSelect from '../components/FormSelect.vue';

// Form States
const showForm = ref(false);
const showViewModal = ref(false);
const editMode = ref(false);
const selectedId = ref<number | null>(null);
const viewItem = ref<any>(null);

// Pagination State
const currentPage = ref(1);
const perPage = ref(10);

// Active action menu id
const activeActionMenuId = ref<number | null>(null);

// Search Query
const searchQuery = ref('');

// Seed data
const suppliers = ref([
  { id: 1, uuid: 'SPL-8291', party_name: 'Apex Global Logistics', entity: 'Haleta Enterprise Group', supplier_type: 'International', lead_time: 15, state: 'Active' },
  { id: 2, uuid: 'SPL-1204', party_name: 'Ethio Printing Supplies', entity: 'Bole Road Branch', supplier_type: 'Local', lead_time: 3, state: 'Active' },
  { id: 3, uuid: 'SPL-5421', party_name: 'Zemen Packaging Ltd', entity: 'Haleta Enterprise Group', supplier_type: 'Local', lead_time: 5, state: 'Active' }
]);

// Form input state
const formState = ref({
  party_name: '',
  entity: 'Haleta Enterprise Group',
  supplier_type: 'Local',
  lead_time: 5
});

// Load from LocalStorage if available
onMounted(() => {
  const savedSuppliers = localStorage.getItem('haleta_erp_suppliers');
  if (savedSuppliers) {
    suppliers.value = JSON.parse(savedSuppliers);
  }
  window.addEventListener('click', closeAllMenus);
});

onUnmounted(() => {
  window.removeEventListener('click', closeAllMenus);
});

const saveToLocalStorage = () => {
  localStorage.setItem('haleta_erp_suppliers', JSON.stringify(suppliers.value));
};

const closeAllMenus = () => {
  activeActionMenuId.value = null;
};

// Table Filtering and Search
const filteredSuppliers = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return suppliers.value;
  return suppliers.value.filter(s => 
    s.party_name.toLowerCase().includes(q) || 
    s.uuid.toLowerCase().includes(q) || 
    s.supplier_type.toLowerCase().includes(q)
  );
});

const paginatedSuppliers = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredSuppliers.value.slice(start, start + perPage.value);
});

// Actions
const toggleActionMenu = (e: Event, id: number) => {
  e.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const openAddForm = () => {
  editMode.value = false;
  selectedId.value = null;
  formState.value = {
    party_name: '',
    entity: 'Haleta Enterprise Group',
    supplier_type: 'Local',
    lead_time: 5
  };
  showForm.value = true;
  closeAllMenus();
};

const handleSave = () => {
  if (!formState.value.party_name) {
    alert('Please fill out the Supplier / Party Name.');
    return;
  }
  if (editMode.value && selectedId.value !== null) {
    const idx = suppliers.value.findIndex(s => s.id === selectedId.value);
    if (idx !== -1) {
      suppliers.value[idx].party_name = formState.value.party_name;
      suppliers.value[idx].entity = formState.value.entity;
      suppliers.value[idx].supplier_type = formState.value.supplier_type;
      suppliers.value[idx].lead_time = Number(formState.value.lead_time);
    }
  } else {
    const formattedUuid = 'SPL-' + Math.floor(1000 + Math.random() * 9000);
    suppliers.value.push({
      id: Date.now(),
      uuid: formattedUuid,
      party_name: formState.value.party_name,
      entity: formState.value.entity,
      supplier_type: formState.value.supplier_type,
      lead_time: Number(formState.value.lead_time),
      state: 'Active'
    });
  }
  saveToLocalStorage();
  showForm.value = false;
};

const triggerEdit = (item: any) => {
  editMode.value = true;
  selectedId.value = item.id;
  formState.value = {
    party_name: item.party_name,
    entity: item.entity,
    supplier_type: item.supplier_type,
    lead_time: item.lead_time
  };
  showForm.value = true;
  closeAllMenus();
};

const triggerView = (item: any) => {
  viewItem.value = item;
  showViewModal.value = true;
  closeAllMenus();
};

const triggerDelete = (id: number) => {
  if (!confirm('Are you sure you want to delete this supplier?')) return;
  suppliers.value = suppliers.value.filter(s => s.id !== id);
  saveToLocalStorage();
  closeAllMenus();
};
</script>

<template>
  <div class="buying-module-page">
    <!-- Breadcrumbs -->
    <div class="breadcrumbs">
      <router-link to="/dashboard" class="breadcrumb-link">
        <Monitor :size="16" />
      </router-link>
      <ChevronRight :size="12" class="breadcrumb-separator" />
      <span class="breadcrumb-active">Buying Module</span>
    </div>

    <!-- Main Content Table Card via BaseTable -->
    <BaseTable
      title="Supplier Directory"
      subtitle="Oversee supplier relationship profiles and parameters. Configure operational delivery lead times, distinguish local versus international procurement types, and align linked enterprise transactional entities."
      v-model:searchQuery="searchQuery"
      :totalEntries="filteredSuppliers.length"
      v-model:currentPage="currentPage"
      v-model:perPage="perPage"
      :showFilter="false"
      :showColumns="false"
    >
      <template #actions>
        <BaseButton variant="primary" @click="openAddForm">
          <template #icon-left><Plus :size="18" stroke-width="2.5" /></template>
          <span>Add New Supplier</span>
        </BaseButton>
      </template>

      <table class="erp-table">
        <thead>
          <tr>
            <th width="140">Supplier ID</th>
            <th>Supplier Name (Party)</th>
            <th>Assigned Entity Scope</th>
            <th>Supplier Type</th>
            <th>Est. Delivery Lead Time</th>
            <th width="120">State</th>
            <th width="80" class="text-right">Action</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="s in paginatedSuppliers" :key="s.id">
            <td class="col-secondary-text font-mono font-medium">{{ s.uuid }}</td>
            <td class="col-primary-title">{{ s.party_name }}</td>
            <td class="col-secondary-text">{{ s.entity }}</td>
            <td>
              <span :class="['type-badge', s.supplier_type === 'International' ? 'intl' : 'local']">
                {{ s.supplier_type }}
              </span>
            </td>
            <td class="col-secondary-text">{{ s.lead_time }} Days</td>
            <td>
              <span class="status-pill pill-active">
                {{ s.state }}
              </span>
            </td>
            <td class="text-right">
              <div class="action-menu-container">
                <button @click="toggleActionMenu($event, s.id)" class="btn-action-dots" title="Actions">
                  <MoreVertical :size="16" />
                </button>
                <div v-if="activeActionMenuId === s.id" class="action-dropdown-menu" @click.stop>
                  <button @click="triggerView(s)" class="action-dropdown-item">
                    <Eye :size="14" class="text-gray-500" />
                    <span>View</span>
                  </button>
                  <button @click="triggerEdit(s)" class="action-dropdown-item">
                    <Edit2 :size="14" class="text-gray-500" />
                    <span>Edit</span>
                  </button>
                  <div class="dropdown-divider"></div>
                  <button @click="triggerDelete(s.id)" class="action-dropdown-item text-red-600 hover:bg-red-50">
                    <Trash2 :size="14" class="text-red-500" />
                    <span class="text-red-600 font-medium">Delete</span>
                  </button>
                </div>
              </div>
            </td>
          </tr>
          <tr v-if="filteredSuppliers.length === 0">
            <td colspan="7" class="text-center py-8 text-slate-400">
              No suppliers found matching your search.
            </td>
          </tr>
        </tbody>
      </table>
    </BaseTable>

    <!-- QUICK CREATE / EDIT MODAL -->
    <QuickCreateModal
      v-model:show="showForm"
      :title="`${editMode ? 'Edit' : 'Create'} Supplier Profile`"
      :showExpandButton="false"
      @save="handleSave"
    >
      <div class="space-y-3.5">
        <FormInput
          v-model="formState.party_name"
          label="Supplier Name (Party Link)"
          :required="true"
        />

        <div class="grid grid-cols-2 gap-3">
          <FormSelect
            v-model="formState.supplier_type"
            label="Procurement Type"
            :options="['Local', 'International']"
          />

          <FormSelect
            v-model="formState.entity"
            label="Assigned Entity"
            :options="['Haleta Enterprise Group', 'Bole Road Branch']"
          />
        </div>

        <FormInput
          v-model="formState.lead_time"
          label="Est. Delivery Lead Time (Days)"
          type="number"
          helperText="Estimated time between placing an order and receiving items."
        />
      </div>
    </QuickCreateModal>

    <!-- VIEW DETAILS MODAL -->
    <div v-if="showViewModal" class="modal-overlay" @click.self="showViewModal = false">
      <div class="modal-card">
        <button class="modal-close-btn" @click="showViewModal = false">
          <X :size="18" />
        </button>

        <header class="modal-card-header">
          <h3>Supplier Details — {{ viewItem?.uuid }}</h3>
        </header>

        <div class="modal-body-content">
          <div class="view-details-grid">
            <div class="detail-item full-width">
              <span class="detail-label">Supplier Name</span>
              <span class="detail-value text-lg font-semibold text-gray-900">{{ viewItem?.party_name }}</span>
            </div>

            <div class="detail-item">
              <span class="detail-label">Procurement Type</span>
              <span :class="['type-badge inline-block mt-1', viewItem?.supplier_type === 'International' ? 'intl' : 'local']">
                {{ viewItem?.supplier_type }}
              </span>
            </div>

            <div class="detail-item">
              <span class="detail-label">Assigned Entity Scope</span>
              <span class="detail-value text-gray-800">{{ viewItem?.entity }}</span>
            </div>

            <div class="detail-item">
              <span class="detail-label">Delivery Lead Time</span>
              <span class="detail-value font-medium text-gray-800">{{ viewItem?.lead_time }} Days</span>
            </div>

            <div class="detail-item">
              <span class="detail-label">Status</span>
              <span class="status-badge status-completed mt-1">
                <span class="dot"></span>{{ viewItem?.state }}
              </span>
            </div>
          </div>
        </div>

        <div class="modal-footer-row">
          <button @click="showViewModal = false" class="btn-modal-primary full-width">Close Details</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.buying-module-page {
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

/* Content Card */
.content-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  padding: 0;
  box-shadow: 0 1px 3px rgba(0,0,0,0.02);
  overflow: visible; /* Crucial for action dropdown menus to overlay properly */
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
  font-size: 13px;
  font-weight: 500;
  color: #4b5563;
  background: #f9fafb;
  border-bottom: 1px solid #e5e7eb;
}
.gate-pass-table td {
  padding: 14px 24px;
  font-size: 14px;
  color: #374151;
  border-bottom: 1px solid #f3f4f6;
  vertical-align: middle;
}
.gate-pass-table tr:hover {
  background-color: #fcfcfd;
}

.type-badge {
  display: inline-flex;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
}
.type-badge.intl { background-color: #f5f3ff; color: #6d28d9; }
.type-badge.local { background-color: #eff6ff; color: #1d4ed8; }

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

/* Action Dropdown Menu */
.action-menu-container {
  position: relative;
  display: inline-block;
}
.btn-three-dots {
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  padding: 6px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}
.btn-three-dots:hover {
  background-color: #f3f4f6;
  color: #111827;
}

.action-dropdown-menu {
  position: absolute;
  top: 100%;
  right: 0;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.08), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
  z-index: 999;
  min-width: 140px;
  padding: 6px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  animation: dropFade 0.15s ease-out;
}
@keyframes dropFade {
  from { opacity: 0; transform: translateY(-5px); }
  to { opacity: 1; transform: translateY(0); }
}

.action-dropdown-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  font-size: 13px;
  color: #475569;
  background: none;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  width: 100%;
  transition: all 0.15s ease;
}
.action-dropdown-item:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}
.dropdown-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 4px 6px;
}
.action-dropdown-item.text-red-650 {
  color: #ef4444;
}
.action-dropdown-item.text-red-650:hover {
  background-color: #fef2f2;
  color: #dc2626;
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
.form-input, .form-select {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 14px;
  outline: none;
  background-color: white;
  transition: all 0.15s ease;
}
.form-input:focus, .form-select:focus {
  border-color: #111827;
}
.form-tip-text {
  font-size: 11px;
  color: #9ca3af;
  margin-top: 2px;
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

.full-width {
  flex: 1 1 100% !important;
  width: 100% !important;
}

/* View Details Styles */
.view-details-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}
.detail-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.detail-item.full-width {
  grid-column: span 2;
  border-bottom: 1px solid #f1f5f9;
  padding-bottom: 12px;
  margin-bottom: 4px;
}
.detail-label {
  font-size: 11px;
  font-weight: 700;
  color: #9ca3af;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.detail-value {
  font-size: 14px;
  color: #334155;
}
.text-lg {
  font-size: 18px;
}
</style>
