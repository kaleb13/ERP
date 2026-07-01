<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { 
  Plus, Search, ChevronRight, HelpCircle,
  X, Check, Lock, Edit2, Trash2, MoreVertical, Eye, Users, Layers, Monitor
} from 'lucide-vue-next';

// State
const customerGroups = ref([
  { id: 1, name: 'Wholesale Customers', description: 'Bulk buying discount tier', entity: 'Haleta Enterprise Group', status_lookup: 'Approved', state: 'Active' },
  { id: 2, name: 'Retail Customers', description: 'Standard consumer tier', entity: 'Bole Road Branch', status_lookup: 'Approved', state: 'Active' },
  { id: 3, name: 'Corporate Clients', description: 'Special contract accounts', entity: 'Haleta Enterprise Group', status_lookup: 'Pending Approval', state: 'Active' }
]);

// Active dropdown id
const activeActionMenuId = ref<number | null>(null);

// Form / View States
const showForm = ref(false);
const showViewModal = ref(false);
const editMode = ref(false);
const selectedId = ref<number | null>(null);
const viewItem = ref<any>(null);

// Search Query
const searchQuery = ref('');

// Form input state
const formState = ref({
  cg_name: '',
  cg_desc: '',
  cg_entity: 'Haleta Enterprise Group',
  cg_status: 'Approved'
});

// Load from LocalStorage if available
onMounted(() => {
  const savedGroups = localStorage.getItem('haleta_erp_customer_groups');
  if (savedGroups) {
    customerGroups.value = JSON.parse(savedGroups);
  } else {
    // If not found, seed the localStorage first
    localStorage.setItem('haleta_erp_customer_groups', JSON.stringify(customerGroups.value));
  }
  window.addEventListener('click', closeAllMenus);
});

onUnmounted(() => {
  window.removeEventListener('click', closeAllMenus);
});

const saveToLocalStorage = () => {
  localStorage.setItem('haleta_erp_customer_groups', JSON.stringify(customerGroups.value));
};

const closeAllMenus = () => {
  activeActionMenuId.value = null;
};

// Table Filtering and Search
const filteredCustomerGroups = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return customerGroups.value;
  return customerGroups.value.filter(cg => 
    cg.name.toLowerCase().includes(q) || 
    cg.entity.toLowerCase().includes(q) ||
    cg.description.toLowerCase().includes(q)
  );
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
    cg_name: '', cg_desc: '', cg_entity: 'Haleta Enterprise Group', cg_status: 'Approved'
  };
  showForm.value = true;
  closeAllMenus();
};

const handleSave = () => {
  if (!formState.value.cg_name.trim()) {
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
  saveToLocalStorage();
  showForm.value = false;
};

const triggerEdit = (item: any) => {
  editMode.value = true;
  selectedId.value = item.id;
  formState.value = {
    cg_name: item.name,
    cg_desc: item.description,
    cg_entity: item.entity,
    cg_status: item.status_lookup
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
  if (!confirm('Are you sure you want to delete this customer group?')) return;
  customerGroups.value = customerGroups.value.filter(cg => cg.id !== id);
  saveToLocalStorage();
  closeAllMenus();
};
</script>

<template>
  <div class="customer-groups-page">
    <!-- Breadcrumbs -->
    <div class="breadcrumbs">
      <router-link to="/dashboard" class="breadcrumb-link">
        <Monitor :size="16" />
      </router-link>
      <ChevronRight :size="12" class="breadcrumb-separator" />
      <span class="breadcrumb-active">Customer Groups</span>
    </div>

    <!-- Main Content Card -->
    <div class="content-card">
      <header class="page-header">
        <div class="title-area">
          <h1 class="page-title">Customer Groups</h1>
          <p class="page-description">
            Administer and segment customer pricing profiles, retail/wholesale tiers, and assign linked corporate accounts.
          </p>
        </div>
      </header>

      <!-- Action & Search Bar -->
      <div class="action-bar">
        <div class="action-bar-left">
          <div class="search-input-wrapper">
            <Search :size="18" class="search-icon" />
            <input 
              v-model="searchQuery" 
              type="text" 
              placeholder="Search groups..." 
              class="table-search" 
            />
          </div>
        </div>

        <div class="action-bar-right">
          <button @click="openAddForm" class="btn-create">
            <Plus :size="20" />
            <span>Add New Group</span>
          </button>
        </div>
      </div>

      <!-- Tables Content -->
      <div class="table-wrapper">
        <table class="gate-pass-table">
          <thead>
            <tr>
              <th>Group Name</th>
              <th>Group Scope / Description</th>
              <th>Assigned Entity</th>
              <th width="180">Status Lookup Value</th>
              <th width="120">State</th>
              <th width="80" class="text-center">Action</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="cg in filteredCustomerGroups" :key="cg.id">
              <td class="font-semibold text-gray-900">
                <div class="group-name-cell">
                  <div class="group-icon-box">
                    <Users :size="14" class="text-emerald-600" />
                  </div>
                  <span>{{ cg.name }}</span>
                </div>
              </td>
              <td class="text-gray-600">{{ cg.description }}</td>
              <td class="text-gray-700">{{ cg.entity }}</td>
              <td>
                <span :class="['status-lookup-badge', cg.status_lookup === 'Approved' ? 'approved' : 'pending']">
                  {{ cg.status_lookup }}
                </span>
              </td>
              <td>
                <span class="status-badge status-completed">
                  <span class="dot"></span>{{ cg.state }}
                </span>
              </td>
              <td class="text-center">
                <!-- Floating action menu -->
                <div class="action-menu-container">
                  <button @click="toggleActionMenu($event, cg.id)" class="btn-three-dots" title="Actions">
                    <MoreVertical :size="18" />
                  </button>
                  <div v-if="activeActionMenuId === cg.id" class="action-dropdown-menu" @click.stop>
                    <button @click="triggerView(cg)" class="action-dropdown-item">
                      <Eye :size="14" class="text-gray-500" />
                      <span>View</span>
                    </button>
                    <button @click="triggerEdit(cg)" class="action-dropdown-item">
                      <Edit2 :size="14" class="text-gray-500" />
                      <span>Edit</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button @click="triggerDelete(cg.id)" class="action-dropdown-item text-red-650">
                      <Trash2 :size="14" />
                      <span>Delete</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
            <tr v-if="filteredCustomerGroups.length === 0">
              <td colspan="6" class="text-center py-8 text-gray-400">No customer groups found matching search query.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- FORM OVERLAY MODAL -->
    <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
      <div class="modal-card">
        <button class="modal-close-btn" @click="showForm = false">
          <X :size="18" />
        </button>

        <header class="modal-card-header">
          <h3>{{ editMode ? 'Edit Customer Segment Group' : 'Create Customer Segment Group' }}</h3>
        </header>

        <div class="modal-body-content">
          <div class="form-container">
            <div class="form-group">
              <label class="form-label">Group Category Name *</label>
              <input v-model="formState.cg_name" type="text" placeholder="e.g. Wholesale T1, VIP" class="form-input" />
            </div>

            <div class="form-grid-2">
              <div class="form-group">
                <label class="form-label">Assigned Entity Scope</label>
                <select v-model="formState.cg_entity" class="form-select">
                  <option value="Haleta Enterprise Group">Haleta Enterprise Group</option>
                  <option value="Bole Road Branch">Bole Road Branch</option>
                </select>
              </div>

              <div class="form-group">
                <label class="form-label">Registration Status</label>
                <select v-model="formState.cg_status" class="form-select">
                  <option value="Approved">Approved</option>
                  <option value="Pending Approval">Pending Approval</option>
                </select>
              </div>
            </div>

            <div class="form-group">
              <label class="form-label">Group Description</label>
              <textarea v-model="formState.cg_desc" rows="3" placeholder="Describe pricing discount tier constraints" class="form-textarea"></textarea>
            </div>
          </div>
        </div>

        <div class="modal-footer-row">
          <button @click="showForm = false" class="btn-modal-secondary">Cancel</button>
          <button @click="handleSave" class="btn-modal-primary">Save Changes</button>
        </div>
      </div>
    </div>

    <!-- VIEW DETAILS MODAL -->
    <div v-if="showViewModal" class="modal-overlay" @click.self="showViewModal = false">
      <div class="modal-card">
        <button class="modal-close-btn" @click="showViewModal = false">
          <X :size="18" />
        </button>

        <header class="modal-card-header">
          <h3>Customer Group Details</h3>
        </header>

        <div class="modal-body-content">
          <div class="view-details-grid">
            <div class="detail-item full-width">
              <span class="detail-label">Group Category Name</span>
              <span class="detail-value text-lg font-semibold text-gray-900">{{ viewItem?.name }}</span>
            </div>

            <div class="detail-item full-width">
              <span class="detail-label">Group Scope / Description</span>
              <span class="detail-value text-gray-700">{{ viewItem?.description }}</span>
            </div>

            <div class="detail-item">
              <span class="detail-label">Assigned Entity Scope</span>
              <span class="detail-value text-gray-800">{{ viewItem?.entity }}</span>
            </div>

            <div class="detail-item">
              <span class="detail-label">Registration Status</span>
              <span :class="['status-lookup-badge inline-block mt-1', viewItem?.status_lookup === 'Approved' ? 'approved' : 'pending']">
                {{ viewItem?.status_lookup }}
              </span>
            </div>

            <div class="detail-item">
              <span class="detail-label">State</span>
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
.customer-groups-page {
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
  overflow: visible; /* Crucial for dropdown action menu to overlay correctly */
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

.group-name-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}
.group-icon-box {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background-color: #ecfdf5;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #a7f3d0;
}

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
