<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { 
  Monitor, Plus, Search, ChevronRight, HelpCircle,
  X, Check, Lock, Edit2, Trash2, MoreVertical, Eye, Users,
  Filter, ArrowUpDown, RefreshCw, Columns, Maximize2, ChevronDown,
  ArrowLeft, ArrowRight, Expand, ExternalLink
} from 'lucide-vue-next';
import BasePagination from '../components/BasePagination.vue';
import BaseTable from '../components/BaseTable.vue';
import BaseButton from '../components/BaseButton.vue';

// Data State
const customers = ref([
  { 
    id: 1, 
    uuid: 'CUST-0098', 
    party_name: 'Almaz Abraham', 
    entity: 'Global Trade Co.', 
    group: 'Retail Customers', 
    credit_limit: 15000, 
    loyalty: 'Yes', 
    state: 'Active',
    customer_type: 'Individual',
    phone: '+251 911 000 111',
    email: 'almaz.a@globaltrade.com',
    tin_number: 'TIN-98124-2026',
    walk_in: false,
    enable_loyalty: true
  },
  { 
    id: 2, 
    uuid: 'CUST-0045', 
    party_name: 'Kebede & Sons Trading', 
    entity: 'Haleta Enterprise Group', 
    group: 'Wholesale Customers', 
    credit_limit: 250000, 
    loyalty: 'No', 
    state: 'Active',
    customer_type: 'Company',
    phone: '+251 911 222 333',
    email: 'info@kebedesons.com',
    tin_number: 'TIN-48921-2026',
    walk_in: false,
    enable_loyalty: false
  }
]);

const customerGroups = ref([
  { id: 1, name: 'Wholesale Customers' },
  { id: 2, name: 'Retail Customers' },
  { id: 3, name: 'Corporate Clients' }
]);

// Interactive state
const activeActionMenuId = ref<number | null>(null);
const showQuickModal = ref(false);
const showFullForm = ref(false);
const showViewModal = ref(false);
const editMode = ref(false);
const selectedId = ref<number | null>(null);
const viewItem = ref<any>(null);

// Pagination & Search
const searchQuery = ref('');
const currentPage = ref(1);
const perPage = ref(10);

// Layout states
const showColumnsDropdown = ref(false);

// Form input state
const formState = ref({
  customer_type: '',
  customer_name: '',
  phone: '',
  email: '',
  walk_in: false,
  group: 'Retail Customers',
  tin_number: '0',
  credit_limit: 0,
  enable_loyalty: false,
  entity: 'Global Trade Co.'
});

// Load from LocalStorage on mount
onMounted(() => {
  const savedCustomers = localStorage.getItem('haleta_erp_customers');
  if (savedCustomers) {
    customers.value = JSON.parse(savedCustomers);
  }
  const savedGroups = localStorage.getItem('haleta_erp_customer_groups');
  if (savedGroups) {
    customerGroups.value = JSON.parse(savedGroups);
  }
  window.addEventListener('click', closeAllMenus);
});

onUnmounted(() => {
  window.removeEventListener('click', closeAllMenus);
});

const saveToLocalStorage = () => {
  localStorage.setItem('haleta_erp_customers', JSON.stringify(customers.value));
};

const closeAllMenus = () => {
  activeActionMenuId.value = null;
  showColumnsDropdown.value = false;
};

// Search & Filtering
const filteredCustomers = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return customers.value;
  return customers.value.filter(c => 
    c.party_name.toLowerCase().includes(q) || 
    c.uuid.toLowerCase().includes(q) || 
    c.group.toLowerCase().includes(q) ||
    c.entity.toLowerCase().includes(q)
  );
});

// Pagination Calculations
const totalEntries = computed(() => filteredCustomers.value.length);
const totalPages = computed(() => Math.ceil(totalEntries.value / perPage.value) || 1);
const startIndex = computed(() => totalEntries.value === 0 ? 0 : (currentPage.value - 1) * perPage.value + 1);
const endIndex = computed(() => Math.min(currentPage.value * perPage.value, totalEntries.value));

const paginatedCustomers = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredCustomers.value.slice(start, start + perPage.value);
});

const changePage = (page: number) => {
  if (page >= 1 && page <= totalPages.value) {
    currentPage.value = page;
  }
};

// Actions
const toggleActionMenu = (e: Event, id: number) => {
  e.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const openAddForm = () => {
  editMode.value = false;
  selectedId.value = null;
  formState.value = {
    customer_type: '',
    customer_name: '',
    phone: '',
    email: '',
    walk_in: false,
    group: 'Retail Customers',
    tin_number: '0',
    credit_limit: 0,
    enable_loyalty: false,
    entity: 'Global Trade Co.'
  };
  showQuickModal.value = true;
  showFullForm.value = false;
  closeAllMenus();
};

const expandFullForm = () => {
  showQuickModal.value = false;
  showFullForm.value = true;
};

const handleSave = () => {
  const name = formState.value.customer_name.trim();
  if (!formState.value.customer_type) {
    alert('Please select a Customer Type.');
    return;
  }
  if (!name) {
    alert('Please fill out the Customer Name.');
    return;
  }

  if (editMode.value && selectedId.value !== null) {
    const idx = customers.value.findIndex(c => c.id === selectedId.value);
    if (idx !== -1) {
      customers.value[idx].party_name = name;
      customers.value[idx].customer_type = formState.value.customer_type;
      customers.value[idx].phone = formState.value.phone;
      customers.value[idx].email = formState.value.email;
      customers.value[idx].walk_in = formState.value.walk_in;
      customers.value[idx].group = formState.value.group;
      customers.value[idx].tin_number = formState.value.tin_number;
      customers.value[idx].credit_limit = Number(formState.value.credit_limit);
      customers.value[idx].enable_loyalty = formState.value.enable_loyalty;
      customers.value[idx].loyalty = formState.value.enable_loyalty ? 'Yes' : 'No';
      customers.value[idx].entity = formState.value.entity;
    }
  } else {
    const formattedUuid = 'CUST-' + Math.floor(1000 + Math.random() * 9000);
    customers.value.push({
      id: Date.now(),
      uuid: formattedUuid,
      party_name: name,
      customer_type: formState.value.customer_type,
      phone: formState.value.phone,
      email: formState.value.email,
      walk_in: formState.value.walk_in,
      group: formState.value.group,
      tin_number: formState.value.tin_number,
      credit_limit: Number(formState.value.credit_limit),
      enable_loyalty: formState.value.enable_loyalty,
      loyalty: formState.value.enable_loyalty ? 'Yes' : 'No',
      entity: formState.value.entity,
      state: 'Active'
    });
  }

  saveToLocalStorage();
  showQuickModal.value = false;
  showFullForm.value = false;
};

const triggerEdit = (item: any) => {
  editMode.value = true;
  selectedId.value = item.id;
  formState.value = {
    customer_type: item.customer_type || 'Individual',
    customer_name: item.party_name,
    phone: item.phone || '',
    email: item.email || '',
    walk_in: item.walk_in || false,
    group: item.group || 'Retail Customers',
    tin_number: item.tin_number || '0',
    credit_limit: item.credit_limit || 0,
    enable_loyalty: item.enable_loyalty || false,
    entity: item.entity || 'Global Trade Co.'
  };
  showFullForm.value = true;
  closeAllMenus();
};

const triggerView = (item: any) => {
  viewItem.value = item;
  showViewModal.value = true;
  closeAllMenus();
};

const triggerDelete = (id: number) => {
  if (!confirm('Are you sure you want to delete this customer record?')) return;
  customers.value = customers.value.filter(c => c.id !== id);
  saveToLocalStorage();
  closeAllMenus();
};

const handleRefresh = () => {
  currentPage.value = 1;
  searchQuery.value = '';
};
</script>

<template>
  <div class="customers-page">
    
    <!-- ==================== FLOW 1: DETAILED FULL FORM VIEW ==================== -->
    <div v-if="showFullForm" class="full-form-view">
      <!-- Top Action Bar & Breadcrumbs -->
      <div class="page-top-bar">
        <div class="breadcrumbs">
          <router-link to="/dashboard" class="breadcrumb-link">
            <Monitor :size="16" />
          </router-link>
          <ChevronRight :size="12" class="breadcrumb-separator" />
          <button @click="showFullForm = false" class="breadcrumb-link-btn">Customer</button>
          <ChevronRight :size="12" class="breadcrumb-separator" />
          <span class="breadcrumb-active">Create Customer</span>
          
          <!-- Status Badge matching screenshot exactly -->
          <span class="status-badge-detailed">Not Saved</span>
        </div>
        
        <div class="top-actions">
          <button @click="handleSave" class="btn-save-detailed">Save</button>
        </div>
      </div>

      <!-- Main Form Container -->
      <div class="content-card detailed-form-card">
        <div class="detailed-form-grid">
          <!-- Row 1 -->
          <div class="form-group">
            <label class="form-label-premium">Customer Type <span class="required-asterisk">*</span></label>
            <div class="custom-select-wrapper">
              <select v-model="formState.customer_type" class="form-select-premium">
                <option value="" disabled selected hidden>Select option</option>
                <option value="Individual">Individual</option>
                <option value="Company">Company</option>
              </select>
              <ChevronDown :size="18" class="select-arrow" />
            </div>
          </div>

          <div class="form-group">
            <label class="form-label-premium">Customer Group</label>
            <div class="custom-select-wrapper">
              <select v-model="formState.group" class="form-select-premium">
                <option value="" disabled selected hidden>Select option</option>
                <option v-for="grp in customerGroups" :key="grp.id" :value="grp.name">{{ grp.name }}</option>
              </select>
              <ChevronDown :size="18" class="select-arrow" />
            </div>
          </div>

          <!-- Row 2 -->
          <div class="form-group">
            <label class="form-label-premium">Customer Name <span class="required-asterisk">*</span></label>
            <input v-model="formState.customer_name" type="text" placeholder="" class="form-input-premium" />
          </div>

          <div class="form-group">
            <label class="form-label-premium">Tin Number</label>
            <input v-model="formState.tin_number" type="text" placeholder="" class="form-input-premium" />
          </div>

          <!-- Row 3 -->
          <div class="form-group">
            <label class="form-label-premium">Phone</label>
            <input v-model="formState.phone" type="text" placeholder="" class="form-input-premium" />
          </div>

          <div class="form-group">
            <label class="form-label-premium">Email</label>
            <input v-model="formState.email" type="email" placeholder="" class="form-input-premium" />
          </div>

          <!-- Row 4 (Full Width) -->
          <div class="form-group full-width">
            <label class="form-label-premium">Credit Limit</label>
            <input v-model="formState.credit_limit" type="number" placeholder="" class="form-input-premium" />
            <span class="field-helper-desc">
              Set the maximum amount of unpaid balance this customer is allowed to owe before new credit sales or invoices are restricted. Leave empty or set to 0 to disable credit purchasing.
            </span>
          </div>
        </div>

        <!-- Checkboxes Row (Side-by-Side) -->
        <div class="checkboxes-row-detailed">
          <label class="custom-checkbox-row" @click.stop>
            <input type="checkbox" v-model="formState.walk_in" class="hidden-checkbox" />
            <div class="custom-checkbox-box" :class="{ 'checked': formState.walk_in }">
              <Check v-if="formState.walk_in" :size="14" class="checkbox-checkmark" />
            </div>
            <div class="checkbox-label-block">
              <span class="checkbox-label-title">Walk-in Customer</span>
              <span class="checkbox-label-desc">
                Enable this option if the customer is a temporary or one-time customer without a registered account or detailed profile. Walk-in customers can be used for quick sales and faster checkout processes.
              </span>
            </div>
          </label>

          <label class="custom-checkbox-row" @click.stop>
            <input type="checkbox" v-model="formState.enable_loyalty" class="hidden-checkbox" />
            <div class="custom-checkbox-box" :class="{ 'checked': formState.enable_loyalty }">
              <Check v-if="formState.enable_loyalty" :size="14" class="checkbox-checkmark" />
            </div>
            <div class="checkbox-label-block">
              <span class="checkbox-label-title">Enable Loyalty Program</span>
              <span class="checkbox-label-desc">
                Allow this customer to earn, collect, and redeem loyalty points based on the configured loyalty rules and reward programs. Disable this option if the customer should not participate in loyalty benefits.
              </span>
            </div>
          </label>
        </div>
      </div>
    </div>

    <!-- ==================== FLOW 2: STANDARD REGISTRY LIST VIEW ==================== -->
    <div v-else class="registry-list-view">
      <!-- Breadcrumbs -->
      <div class="breadcrumbs">
        <router-link to="/dashboard" class="breadcrumb-link">
          <Monitor :size="16" />
        </router-link>
        <ChevronRight :size="12" class="breadcrumb-separator" />
        <span class="breadcrumb-active">Customer</span>
      </div>

      <!-- Main Content Table Card via BaseTable -->
      <BaseTable
        title="Customers"
        subtitle="Manage customer information, loyalty, and credit settings."
        v-model:searchQuery="searchQuery"
        :totalEntries="totalEntries"
        v-model:currentPage="currentPage"
        v-model:perPage="perPage"
        :showFilter="false"
        :showColumns="false"
      >
        <template #actions>
          <BaseButton variant="primary" @click="openAddForm">
            <template #icon-left><Plus :size="18" stroke-width="2.5" /></template>
            <span>Create Customer</span>
          </BaseButton>
        </template>

        <table class="erp-table">
          <thead>
            <tr>
              <th class="text-left">Name</th>
              <th class="text-left">Assigned Entity</th>
              <th class="text-left">Customer Group</th>
              <th class="text-left">State</th>
              <th width="80" class="text-right">Action</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="c in paginatedCustomers" :key="c.id">
              <td class="col-primary-title">
                {{ c.party_name }}
              </td>
              <td class="col-secondary-text">{{ c.entity }}</td>
              <td class="col-secondary-text">{{ c.group }}</td>
              <td>
                <span class="status-pill pill-active">
                  {{ c.state }}
                </span>
              </td>
              <td class="text-right">
                <div class="action-menu-container">
                  <button @click="toggleActionMenu($event, c.id)" class="btn-action-dots" title="Actions">
                    <MoreVertical :size="16" />
                  </button>
                  <div v-if="activeActionMenuId === c.id" class="action-dropdown-menu" @click.stop>
                    <button @click="triggerView(c)" class="action-dropdown-item">
                      <Eye :size="14" class="text-gray-500" />
                      <span>View Details</span>
                    </button>
                    <button @click="triggerEdit(c)" class="action-dropdown-item">
                      <Edit2 :size="14" class="text-gray-500" />
                      <span>Edit Form</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button @click="triggerDelete(c.id)" class="action-dropdown-item text-red-600 hover:bg-red-50">
                      <Trash2 :size="14" class="text-red-500" />
                      <span class="text-red-600 font-medium">Remove Client</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
            <tr v-if="filteredCustomers.length === 0">
              <td colspan="5" class="text-center py-12 text-slate-400">
                <div class="empty-state-box">
                  <Users :size="32" class="text-slate-300 mb-2" />
                  <p>No registered customer accounts found matching search scope.</p>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </BaseTable>
    </div>

    <!-- ==================== FLOW 3: QUICK CREATE MODAL ==================== -->
    <div v-if="showQuickModal" class="modal-overlay" @click.self="showQuickModal = false">
      <div class="modal-card quick-create-modal">
        <button class="modal-close-btn" @click="showQuickModal = false">
          <X :size="20" />
        </button>

        <header class="modal-card-header">
          <h3>Create Customer</h3>
        </header>

        <div class="modal-body-content">
          <div class="form-container">
            <div class="form-group">
              <label class="form-label-premium">Customer Type <span class="required-asterisk">*</span></label>
              <div class="custom-select-wrapper">
                <select v-model="formState.customer_type" class="form-select-premium">
                  <option value="" disabled selected hidden>Select option</option>
                  <option value="Individual">Individual</option>
                  <option value="Company">Company</option>
                </select>
                <ChevronDown :size="18" class="select-arrow" />
              </div>
            </div>

            <div class="form-group">
              <label class="form-label-premium">Customer Name <span class="required-asterisk">*</span></label>
              <input v-model="formState.customer_name" type="text" placeholder="" class="form-input-premium" />
            </div>

            <div class="form-grid-2">
              <div class="form-group">
                <label class="form-label-premium">Phone</label>
                <input v-model="formState.phone" type="text" placeholder="" class="form-input-premium" />
              </div>

              <div class="form-group">
                <label class="form-label-premium">Email</label>
                <input v-model="formState.email" type="email" placeholder="" class="form-input-premium" />
              </div>
            </div>

            <!-- Highly refined custom checkbox element -->
            <label class="custom-checkbox-row" @click.stop>
              <input type="checkbox" v-model="formState.walk_in" class="hidden-checkbox" />
              <div class="custom-checkbox-box" :class="{ 'checked': formState.walk_in }">
                <Check v-if="formState.walk_in" :size="14" class="checkbox-checkmark" />
              </div>
              <div class="checkbox-label-block">
                <span class="checkbox-label-title">Walk-in Customer</span>
                <span class="checkbox-label-desc">
                  Enable this option if the customer is a temporary or one-time customer without a registered account or detailed profile. Walk-in customers can be used for quick sales and faster checkout processes.
                </span>
              </div>
            </label>
          </div>
        </div>

        <div class="modal-footer-row">
          <button @click="expandFullForm" class="btn-expand-form">
            <span>Expand Full Form</span>
            <Expand :size="14" class="ml-2.5" />
          </button>
          
          <button @click="handleSave" class="btn-modal-save">
            <span>Save</span>
          </button>
        </div>
      </div>
    </div>

    <!-- ==================== FLOW 4: VIEW DETAILS MODAL ==================== -->
    <div v-if="showViewModal" class="modal-overlay" @click.self="showViewModal = false">
      <div class="modal-card">
        <button class="modal-close-btn" @click="showViewModal = false">
          <X :size="18" />
        </button>

        <header class="modal-card-header">
          <h3>Customer Details — {{ viewItem?.uuid }}</h3>
        </header>

        <div class="modal-body-content">
          <div class="view-details-grid">
            <div class="detail-item full-width">
              <span class="detail-label">Display Name</span>
              <span class="detail-value text-lg font-bold text-gray-900">{{ viewItem?.party_name }}</span>
            </div>
            
            <div class="detail-item">
              <span class="detail-label">Segment Group</span>
              <span class="detail-value font-medium text-gray-800">
                <Users :size="14" class="inline mr-1 text-gray-500" />
                {{ viewItem?.group }}
              </span>
            </div>

            <div class="detail-item">
              <span class="detail-label">Assigned Entity</span>
              <span class="detail-value text-gray-800 font-semibold">{{ viewItem?.entity }}</span>
            </div>

            <div class="detail-item">
              <span class="detail-label">Credit Limit</span>
              <span class="detail-value text-dark-charcoal font-bold">${{ viewItem?.credit_limit?.toLocaleString() }}</span>
            </div>

            <div class="detail-item">
              <span class="detail-label">Loyalty Tier Enroll</span>
              <span :class="['loyalty-badge inline-block mt-1', viewItem?.loyalty === 'Yes' ? 'yes' : 'no']">{{ viewItem?.loyalty }}</span>
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
.customers-page {
  animation: fadeIn 0.4s ease-out;
  display: flex;
  flex-direction: column;
  gap: 16px;
  font-family: 'Inter', sans-serif;
  color: #1f2937;
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
  margin-bottom: 24px;
}
.breadcrumb-link, .breadcrumb-link-btn {
  color: #9ca3af;
  text-decoration: none;
  display: flex;
  align-items: center;
  transition: color 0.15s ease;
  background: none;
  border: none;
  font-size: 13px;
  cursor: pointer;
  padding: 0;
}
.breadcrumb-link:hover, .breadcrumb-link-btn:hover {
  color: #111827;
}
.breadcrumb-separator {
  color: #9ca3af;
  display: flex;
  align-items: center;
}
.breadcrumb-active {
  color: #4b5563;
  font-weight: 500;
}

.status-badge {
  margin-left: 12px;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
}
.badge-notsaved { background: #fef3c7; color: #b45309; }
.badge-saved { background: #ecfdf5; color: #059669; }

/* Page Top Bar for form flow */
.page-top-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}
.top-actions {
  display: flex;
  gap: 12px;
}
.btn-cancel {
  height: 40px;
  padding: 0 20px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  color: #4b5563;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-cancel:hover {
  background: #f9fafb;
  border-color: #d1d5db;
}
.btn-save {
  height: 40px;
  padding: 0 24px;
  background: var(--alias-color-brand-blue-primary);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-save:hover {
  background: var(--alias-color-brand-blue-primary-hover);
}

/* Page Header in Registry */
.page-header {
  padding: 28px 28px 8px 28px;
}
.page-title {
  font-size: 20px;
  font-weight: 600;
  color: #111827;
  margin-bottom: 6px;
  letter-spacing: -0.01em;
}
.page-description {
  font-size: 13.5px;
  color: #6b7280;
  line-height: 1.5;
}
.btn-create-dark {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 16px;
  height: 42px;
  background-color: var(--alias-color-brand-blue-primary);
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  flex-shrink: 0;
}
.btn-create-dark:hover {
  background-color: var(--alias-color-brand-blue-primary-hover);
}

/* Action Bar in Registry */
.action-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 28px;
  background-color: white;
  border-bottom: 1px solid #f3f4f6;
  gap: 16px;
}
.action-bar-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}
.action-bar-right {
  display: flex;
  align-items: center;
  gap: 12px;
}
.search-input-wrapper {
  position: relative;
  flex: 1;
  max-width: 320px;
}
.search-icon {
  position: absolute;
  left: 14px;
  top: 50%;
  transform: translateY(-50%);
  color: #9ca3af;
  z-index: 10;
}
.table-search {
  width: 100%;
  padding: 10px 12px 10px 42px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 14px;
  outline: none;
  transition: all 0.2s;
  height: 42px;
  background: white;
  color: #1f2937;
}
.table-search:focus {
  border-color: #cbd5e1;
}
.btn-action-white {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 16px;
  height: 42px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  color: #1f2937;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-action-white:hover {
  background: #f9fafb;
}
.btn-icon-grey {
  color: #6b7280;
}
.btn-sort {
  padding-right: 12px;
}
.btn-chevron-down {
  color: #9ca3af;
  margin-left: 2px;
}

.btn-icon-action {
  width: 42px;
  height: 42px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  color: #6b7280;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-icon-action:hover {
  background: #f9fafb;
  color: #111827;
}

/* Dropdown Menu Columns */
.relative-container {
  position: relative;
}
.columns-menu {
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05);
  padding: 12px;
  min-width: 180px;
  z-index: 100;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.columns-menu-title {
  font-size: 11px;
  font-weight: 700;
  color: #9ca3af;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding-bottom: 4px;
  border-bottom: 1px solid #f3f4f6;
}
.menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #374151;
}

/* Content Card general */
.content-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 0;
  box-shadow: 0 1px 3px rgba(0,0,0,0.01);
  overflow: visible;
}

/* Forms layout */
.form-page-card {
  padding: 32px;
}
.form-section-header {
  border-bottom: 1px solid #f3f4f6;
  padding-bottom: 20px;
  margin-bottom: 24px;
}
.form-section-title {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  margin-bottom: 6px;
}
.form-section-desc {
  font-size: 13px;
  color: #6b7280;
}
.detailed-form-card {
  padding: 0;
  border-radius: 16px;
  overflow: hidden;
  background: white;
  border: 1px solid #e5e7eb;
}
.detailed-form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px 24px;
  padding: 28px;
}
.detailed-form-grid .full-width {
  grid-column: span 2;
}
.field-helper-desc {
  font-size: 13.5px;
  color: #6b7280;
  margin-top: 8px;
  line-height: 1.5;
  display: inline-block;
}
.checkboxes-row-detailed {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 32px;
  padding: 0 28px 28px 28px;
}
.status-badge-detailed {
  margin-left: 12px;
  padding: 4px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 600;
  background-color: #fef3c7;
  color: #b45309;
  display: inline-flex;
  align-items: center;
}
.btn-save-detailed {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 10px 24px;
  background-color: var(--alias-color-brand-blue-primary);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 14.5px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.2s;
}
.btn-save-detailed:hover {
  background-color: var(--alias-color-brand-blue-primary-hover);
}
.form-column {
  display: flex;
  flex-direction: column;
  gap: 20px;
}
.form-group-row {
  display: flex;
  gap: 16px;
}
.flex-1 { flex: 1; }
.flex-2 { flex: 2; }

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.form-label {
  font-size: 13px;
  font-weight: 600;
  color: #374151;
}
.required-asterisk {
  color: #dc2626;
  font-weight: 600;
  margin-left: 2px;
}
.form-input, .form-select {
  width: 100%;
  padding: 11px 14px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 14px;
  outline: none;
  background-color: white;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}
.form-input:focus, .form-select:focus {
  border-color: #111827;
  box-shadow: 0 0 0 3px rgba(17, 24, 39, 0.05);
}
.field-desc-text {
  font-size: 11px;
  color: #9ca3af;
  margin-top: 2px;
}

/* Checkboxes on form */
.checkboxes-section {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  border-top: 1px solid #f3f4f6;
  padding-top: 24px;
  margin-top: 24px;
}
.form-checkbox-card {
  display: flex;
  gap: 14px;
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  padding: 16px;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
}
.form-checkbox-card:hover {
  background: #f3f4f6;
  border-color: #d1d5db;
}
.form-checkbox-input {
  width: 18px;
  height: 18px;
  margin-top: 2px;
  accent-color: #111827;
  cursor: pointer;
}
.checkbox-texts {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.checkbox-title {
  font-size: 14px;
  font-weight: 600;
  color: #111827;
}
.checkbox-desc {
  font-size: 12px;
  color: #6b7280;
  line-height: 1.4;
}

.form-bottom-actions {
  display: flex;
  justify-content: flex-end;
  border-top: 1px solid #f3f4f6;
  padding-top: 24px;
  margin-top: 32px;
}
.btn-primary-dark {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 24px;
  height: 44px;
  background: var(--alias-color-brand-blue-primary);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-primary-dark:hover {
  background: var(--alias-color-brand-blue-primary-hover);
  transform: translateY(-1px);
}

/* Tables style matching Image orientation and design exactly */
.table-wrapper {
  overflow-x: auto;
}
.gate-pass-table {
  width: 100%;
  border-collapse: collapse;
}
.gate-pass-table th {
  padding: 14px 28px;
  font-size: 12.5px;
  font-weight: 600;
  color: #374151;
  background: #fdfdfd;
  border-top: 1px solid #f3f4f6;
  border-bottom: 1px solid #f3f4f6;
}
.gate-pass-table td {
  padding: 18px 28px;
  font-size: 14px;
  color: #374151;
  border-bottom: 1px solid #f9fafb;
  vertical-align: middle;
}
.gate-pass-table tr:hover {
  background-color: #fafafa;
}

/* Specific alignments matching the image */
.text-left { text-align: left; }
.text-right { text-align: right; }
.text-center { text-align: center; }

.header-name, .cell-name { width: 25%; }
.header-entity, .cell-entity { width: 25%; color: #6b7280 !important; }
.header-group, .cell-group { width: 25%; color: #6b7280 !important; }
.header-state, .cell-state { width: 15%; }
.header-action, .cell-action { width: 10%; }

.cell-name {
  color: #111827 !important;
  font-weight: 500;
}

/* Premium pill style matching screenshot */
.status-badge-premium {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 3px 10px;
  border-radius: 9999px;
  font-size: 12px;
  font-weight: 500;
  background-color: #def7ec;
  color: #03543f;
}

/* Floating action dropdown */
.action-menu-container {
  position: relative;
  display: inline-flex;
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
  min-width: 150px;
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

/* Pagination Footer matching screenshot */
.table-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 28px;
  border-top: 1px solid #f3f4f6;
  background-color: white;
}
.footer-info {
  font-size: 13.5px;
  color: #4b5563;
  display: flex;
  align-items: center;
  gap: 16px;
}
.per-page-selector {
  color: #4b5563;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}
.page-select {
  padding: 6px 32px 6px 12px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background-color: white;
  outline: none;
  font-size: 13px;
  cursor: pointer;
  color: #1f2937;
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='%239ca3af'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M19 9l-7 7-7-7'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 10px center;
  background-size: 14px;
}
.page-select:focus {
  border-color: #cbd5e1;
}

.pagination-controls {
  display: flex;
  align-items: center;
  gap: 4px;
}
.page-nav-btn {
  display: flex;
  align-items: center;
  height: 38px;
  padding: 0 16px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #374151;
  cursor: pointer;
  transition: all 0.2s;
}
.page-nav-btn:hover:not(:disabled) {
  background: #f9fafb;
}
.page-nav-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.page-num {
  width: 38px;
  height: 38px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #374151;
  cursor: pointer;
  transition: all 0.2s;
}
.page-num:hover {
  background: #f9fafb;
}
.page-num.active {
  background: #111827; /* Charcoal theme active pagination */
  color: white;
  border-color: #111827;
}

/* Modals Overlay - Replicating the exact screenshot modal visual style */
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
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  position: relative;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  border: 1px solid #f3f4f6;
}
.quick-create-modal {
  max-width: 600px; /* Aligned with generous modal width from image */
}
.modal-close-btn {
  position: absolute;
  top: 24px;
  right: 24px;
  background: none;
  border: none;
  color: #6b7280;
  cursor: pointer;
  padding: 6px;
  border-radius: 50%;
  display: flex;
  transition: background-color 0.2s, color 0.2s;
}
.modal-close-btn:hover {
  background-color: #f3f4f6;
  color: #111827;
}
.modal-card-header {
  padding: 28px 28px 12px 28px;
}
.modal-card-header h3 {
  font-size: 22px;
  font-weight: 700;
  color: #111827;
  margin: 0;
  letter-spacing: -0.02em;
}

.modal-body-content {
  padding: 12px 28px 28px 28px;
}

.form-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.form-label-premium {
  font-size: 14px;
  font-weight: 600;
  color: #374151;
  margin-bottom: 8px;
  display: inline-block;
}

/* Custom premium select styling to replicate the screenshot */
.custom-select-wrapper {
  position: relative;
  width: 100%;
}
.form-select-premium {
  width: 100%;
  padding: 13px 16px;
  border: 1.5px solid #e5e7eb;
  border-radius: 12px;
  font-size: 15px;
  outline: none;
  background-color: white;
  color: #1f2937;
  appearance: none;
  cursor: pointer;
  transition: border-color 0.2s, box-shadow 0.2s;
}
.form-select-premium:focus {
  border-color: #cbd5e1;
}
.select-arrow {
  position: absolute;
  right: 16px;
  top: 50%;
  transform: translateY(-50%);
  color: #6b7280;
  pointer-events: none;
}

/* Premium input styling */
.form-input-premium {
  width: 100%;
  padding: 13px 16px;
  border: 1.5px solid #e5e7eb;
  border-radius: 12px;
  font-size: 15px;
  outline: none;
  background-color: white;
  color: #1f2937;
  transition: border-color 0.2s, box-shadow 0.2s;
}
.form-input-premium:focus {
  border-color: #cbd5e1;
}

/* Replicating the beautifully stylized custom checkbox row exactly */
.custom-checkbox-row {
  display: flex;
  gap: 16px;
  align-items: flex-start;
  cursor: pointer;
  padding: 4px 0;
  margin-top: 8px;
  user-select: none;
}
.hidden-checkbox {
  display: none;
}
.custom-checkbox-box {
  width: 22px;
  height: 22px;
  border: 1.5px solid #d1d5db;
  border-radius: 6px;
  background-color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: all 0.2s;
  margin-top: 2px;
}
.custom-checkbox-box.checked {
  background-color: #111827; /* Charcoal theme checkbox fill */
  border-color: #111827;
}
.checkbox-checkmark {
  color: white;
}
.checkbox-label-block {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.checkbox-label-title {
  font-size: 15px;
  font-weight: 600;
  color: #1f2937;
}
.checkbox-label-desc {
  font-size: 13px;
  color: #6b7280;
  line-height: 1.5;
}

/* Modal Footer Container styling to replicate the grey bar separator and background */
.modal-footer-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 28px;
  background-color: #f9fafb;
  border-top: 1.5px solid #f3f4f6;
}

/* White Expand button replicating image style exactly */
.btn-expand-form {
  display: flex;
  align-items: center;
  background-color: white;
  border: 1.5px solid #e5e7eb;
  border-radius: 10px;
  padding: 12px 20px;
  font-size: 14.5px;
  font-weight: 600;
  color: #374151;
  cursor: pointer;
  transition: background-color 0.2s, border-color 0.2s;
}
.btn-expand-form:hover {
  background-color: #f9fafb;
  border-color: #cbd5e1;
}

/* Solid Premium Save Button aligned with color specifications */
.btn-modal-save {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 90px;
  height: 44px;
  background-color: var(--alias-color-brand-blue-primary);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 14.5px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.2s;
}
.btn-modal-save:hover {
  background-color: var(--alias-color-brand-blue-primary-hover);
}

.btn-modal-secondary {
  flex: 1;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  text-align: center;
  background-color: white;
  color: #475569;
  border: 1px solid #e2e8f0;
}
.btn-modal-secondary:hover {
  background-color: #f8fafc;
}
.btn-modal-primary {
  flex: 1;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  text-align: center;
  background-color: var(--alias-color-brand-blue-primary);
  color: white;
  border: none;
}
.btn-modal-primary:hover {
  background-color: var(--alias-color-brand-blue-primary-hover);
}

.full-width {
  width: 100% !important;
  flex: 1 1 100% !important;
}

/* Empty state style */
.empty-state-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

/* View Details Grid */
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
.text-dark-charcoal {
  color: #111827;
}
.text-lg {
  font-size: 18px;
}
</style>
