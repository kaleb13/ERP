<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { 
  Plus, Search, Filter, MoreVertical, 
  ArrowUpRight, ArrowDownLeft, Maximize, List, ChevronLeft, ChevronRight, Monitor, HelpCircle,
  Columns, ArrowUpDown, ChevronDown, ArrowLeft, ArrowRight, RotateCcw,
  Eye, Edit2, Trash2, X
} from 'lucide-vue-next';
import BaseButton from '../components/BaseButton.vue';

// Mock data from the image
const gatePasses = ref([
  { id: 1, no: 'GP-0055-2026', type: 'Outward', location: 'Main Warehouse', date: 'May 4, 2026 - 16:30', status: 'Completed' },
  { id: 2, no: 'GP-0054-2026', type: 'Inward', location: 'Warehouse - 22', date: 'May 4, 2026 - 16:30', status: 'Initiated' },
]);

// Active action menu id
const activeActionMenuId = ref<number | null>(null);
const showViewModal = ref(false);
const viewItem = ref<any>(null);

const toggleActionMenu = (e: Event, id: number) => {
  e.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeAllMenus = () => {
  activeActionMenuId.value = null;
};

onMounted(() => {
  window.addEventListener('click', closeAllMenus);
});

onUnmounted(() => {
  window.removeEventListener('click', closeAllMenus);
});

const triggerView = (item: any) => {
  viewItem.value = item;
  showViewModal.value = true;
  closeAllMenus();
};

const triggerEdit = (item: any) => {
  alert(`Editing Gate Pass ${item.no}. In a fully connected server database system, this would load the complete gate pass record into the document editor.`);
  closeAllMenus();
};

const triggerDelete = (id: number) => {
  if (!confirm('Are you sure you want to delete this gate pass record?')) return;
  gatePasses.value = gatePasses.value.filter(gp => gp.id !== id);
  closeAllMenus();
};

const getStatusClass = (status: string) => {
  switch (status) {
    case 'Initiated': return 'status-initiated';
    case 'Completed': return 'status-completed';
    default: return '';
  }
};

// Checkbox selection states
const selectedRows = ref<number[]>([]);
const selectAll = ref(false);

const toggleSelectAll = () => {
  if (selectAll.value) {
    selectedRows.value = filteredGatePasses.value.map(gp => gp.id);
  } else {
    selectedRows.value = [];
  }
};

// Custom interactive states
const visibleColumns = ref({
  no: true,
  type: true,
  location: true,
  date: true,
  status: true,
  action: true
});

const showColumnDropdown = ref(false);
const showSortDropdown = ref(false);
const showFilterPanel = ref(false);
const activeSort = ref('no-desc');
const isFullscreen = ref(false);

// Search and Filter variables
const searchQuery = ref('');
const filterType = ref('All');
const filterLocation = ref('All');
const filterStatus = ref('All');

const toggleColumnDropdown = () => {
  showColumnDropdown.value = !showColumnDropdown.value;
  if (showColumnDropdown.value) {
    showSortDropdown.value = false;
  }
};

const toggleSortDropdown = () => {
  showSortDropdown.value = !showSortDropdown.value;
  if (showSortDropdown.value) {
    showColumnDropdown.value = false;
  }
};

const toggleFilterPanel = () => {
  showFilterPanel.value = !showFilterPanel.value;
};

const resetFilters = () => {
  filterType.value = 'All';
  filterLocation.value = 'All';
  filterStatus.value = 'All';
  searchQuery.value = '';
};

const applySort = (type: string) => {
  activeSort.value = type;
  showSortDropdown.value = false;
  
  if (type === 'no-asc') {
    gatePasses.value.sort((a, b) => a.no.localeCompare(b.no));
  } else if (type === 'no-desc') {
    gatePasses.value.sort((a, b) => b.no.localeCompare(a.no));
  } else if (type === 'date-new') {
    gatePasses.value.sort((a, b) => b.date.localeCompare(a.date));
  } else if (type === 'date-old') {
    gatePasses.value.sort((a, b) => a.date.localeCompare(b.date));
  }
};

const toggleFullscreen = () => {
  isFullscreen.value = !isFullscreen.value;
};

// Computed property for complete filtering and search
const filteredGatePasses = computed(() => {
  return gatePasses.value.filter(gp => {
    const matchesSearch = searchQuery.value === '' || 
      gp.no.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      gp.location.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      gp.status.toLowerCase().includes(searchQuery.value.toLowerCase());
    
    const matchesType = filterType.value === 'All' || gp.type === filterType.value;
    const matchesLocation = filterLocation.value === 'All' || gp.location === filterLocation.value;
    const matchesStatus = filterStatus.value === 'All' || gp.status === filterStatus.value;
    
    return matchesSearch && matchesType && matchesLocation && matchesStatus;
  });
});
</script>

<template>
  <div class="gate-pass-page">
    <!-- Breadcrumbs -->
    <div class="breadcrumbs">
      <router-link to="/dashboard" class="breadcrumb-link">
        <Monitor :size="16" />
      </router-link>
      <ChevronRight :size="12" class="breadcrumb-separator" />
      <span class="breadcrumb-active">Gate Pass</span>
    </div>

    <!-- Main Content Card -->
    <div :class="['content-card', { 'is-fullscreen': isFullscreen }]">
      <header class="page-header">
        <div class="title-area">
          <h1 class="page-title">Gate Pass Document</h1>
          <p class="page-description">
            Generate and manage gate pass documents for physical inventory movement, including product verification, vehicle information, receiving personnel, and linked warehouse operations.
          </p>
        </div>
      </header>

      <!-- Search and Action Bar -->
      <div class="action-bar">
        <!-- Left Side Actions -->
        <div class="action-bar-left">
          <div class="search-input-wrapper">
            <Search :size="18" class="search-icon" />
            <input v-model="searchQuery" type="text" placeholder="Search..." class="table-search" />
          </div>
          
          <button @click="toggleFilterPanel" class="btn-filter" :class="{ 'active': showFilterPanel }">
            <Filter :size="18" />
            <span>Filter</span>
          </button>

          <!-- Sort Dropdown -->
          <div class="sort-toggle-wrapper">
            <button @click="toggleSortDropdown" class="btn-sort" :class="{ 'active': showSortDropdown }">
              <ArrowUpDown :size="18" />
              <span>Sort</span>
              <ChevronDown :size="14" class="ml-1" />
            </button>
            <div v-if="showSortDropdown" class="sort-dropdown-menu">
              <div class="dropdown-header">Sort By</div>
              <button @click="applySort('no-asc')" class="sort-option" :class="{ 'active': activeSort === 'no-asc' }">
                <span>Document No (A to Z)</span>
                <span v-if="activeSort === 'no-asc'" class="active-dot"></span>
              </button>
              <button @click="applySort('no-desc')" class="sort-option" :class="{ 'active': activeSort === 'no-desc' }">
                <span>Document No (Z to A)</span>
                <span v-if="activeSort === 'no-desc'" class="active-dot"></span>
              </button>
              <button @click="applySort('date-new')" class="sort-option" :class="{ 'active': activeSort === 'date-new' }">
                <span>Date (Newest First)</span>
                <span v-if="activeSort === 'date-new'" class="active-dot"></span>
              </button>
              <button @click="applySort('date-old')" class="sort-option" :class="{ 'active': activeSort === 'date-old' }">
                <span>Date (Oldest First)</span>
                <span v-if="activeSort === 'date-old'" class="active-dot"></span>
              </button>
            </div>
          </div>
        </div>

        <!-- Right Side Actions -->
        <div class="action-bar-right">
          <!-- Column Toggle Dropdown -->
          <div class="column-toggle-wrapper">
            <button @click="toggleColumnDropdown" class="btn-icon-square" :class="{ 'active': showColumnDropdown }" title="Show/Hide Columns">
              <Columns :size="18" />
            </button>
            <div v-if="showColumnDropdown" class="column-dropdown-menu">
              <div class="dropdown-header">Show/Hide Columns</div>
              <label class="column-option">
                <input type="checkbox" v-model="visibleColumns.no" />
                <span>Document No</span>
              </label>
              <label class="column-option">
                <input type="checkbox" v-model="visibleColumns.type" />
                <span>Type</span>
              </label>
              <label class="column-option">
                <input type="checkbox" v-model="visibleColumns.location" />
                <span>Location</span>
              </label>
              <label class="column-option">
                <input type="checkbox" v-model="visibleColumns.date" />
                <span>Date</span>
              </label>
              <label class="column-option">
                <input type="checkbox" v-model="visibleColumns.status" />
                <span>Status</span>
              </label>
              <label class="column-option">
                <input type="checkbox" v-model="visibleColumns.action" />
                <span>Action</span>
              </label>
            </div>
          </div>

          <!-- Maximize Fullscreen Toggle -->
          <button @click="toggleFullscreen" class="btn-icon-square" :class="{ 'active': isFullscreen }" title="Toggle Fullscreen">
            <Maximize :size="18" />
          </button>

          <!-- Primary Action Button (Brand Blue) -->
          <router-link to="/gate-pass/create" style="text-decoration: none;">
            <BaseButton variant="primary">
              <template #icon-left><Plus :size="18" stroke-width="2.5" /></template>
              <span>Create Document</span>
            </BaseButton>
          </router-link>
        </div>
      </div>

      <!-- Dynamic Filter Panel -->
      <transition name="slide-down">
        <div v-if="showFilterPanel" class="filter-panel">
          <div class="filter-group">
            <label class="filter-label">Document Type</label>
            <select v-model="filterType" class="filter-select">
              <option value="All">All Types</option>
              <option value="Outward">Outward</option>
              <option value="Inward">Inward</option>
            </select>
          </div>
          
          <div class="filter-group">
            <label class="filter-label">Location</label>
            <select v-model="filterLocation" class="filter-select">
              <option value="All">All Locations</option>
              <option value="Main Warehouse">Main Warehouse</option>
              <option value="Warehouse - 22">Warehouse - 22</option>
            </select>
          </div>
          
          <div class="filter-group">
            <label class="filter-label">Status</label>
            <select v-model="filterStatus" class="filter-select">
              <option value="All">All Statuses</option>
              <option value="Completed">Completed</option>
              <option value="Initiated">Initiated</option>
            </select>
          </div>

          <BaseButton variant="secondary" size="sm" @click="resetFilters">
            <template #icon-left><RotateCcw :size="14" /></template>
            <span>Reset Filters</span>
          </BaseButton>
        </div>
      </transition>

      <!-- Table Section -->
      <div class="table-wrapper">
        <table class="gate-pass-table">
          <thead>
            <tr>
              <th width="40" class="text-center">
                <input type="checkbox" v-model="selectAll" @change="toggleSelectAll" class="table-checkbox" />
              </th>
              <th v-if="visibleColumns.no" width="200">Document No</th>
              <th v-if="visibleColumns.type" width="150">Type</th>
              <th v-if="visibleColumns.location">Location</th>
              <th v-if="visibleColumns.date" width="200">Date</th>
              <th v-if="visibleColumns.status" width="120">Status <HelpCircle :size="14" class="inline ml-1 text-gray-400" /></th>
              <th v-if="visibleColumns.action" width="80" class="text-center">Action</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="gp in filteredGatePasses" :key="gp.id" :class="{ 'row-selected': selectedRows.includes(gp.id) }">
              <td class="text-center">
                <input type="checkbox" v-model="selectedRows" :value="gp.id" class="table-checkbox" />
              </td>
              <td v-if="visibleColumns.no" class="font-medium text-gray-800">{{ gp.no }}</td>
              <td v-if="visibleColumns.type">
                <div class="type-cell">
                  <ArrowUpRight v-if="gp.type === 'Outward'" :size="16" class="text-gray-500" />
                  <ArrowDownLeft v-else :size="16" class="text-gray-500" />
                  <span class="text-gray-700">{{ gp.type }}</span>
                </div>
              </td>
              <td v-if="visibleColumns.location" class="text-gray-600">{{ gp.location }}</td>
              <td v-if="visibleColumns.date" class="text-gray-500">{{ gp.date }}</td>
              <td v-if="visibleColumns.status">
                <span :class="['status-badge', getStatusClass(gp.status)]">
                  <span v-if="gp.status === 'Completed'" class="dot"></span>
                  <span v-else class="dot-gray"></span>
                  {{ gp.status }}
                </span>
              </td>
              <td v-if="visibleColumns.action" class="text-center">
                <!-- Floating action menu -->
                <div class="action-menu-container">
                  <button @click="toggleActionMenu($event, gp.id)" class="btn-three-dots" title="Actions">
                    <MoreVertical :size="18" />
                  </button>
                  <div v-if="activeActionMenuId === gp.id" class="action-dropdown-menu" @click.stop>
                    <button @click="triggerView(gp)" class="action-dropdown-item">
                      <Eye :size="14" class="text-gray-500" />
                      <span>View</span>
                    </button>
                    <button @click="triggerEdit(gp)" class="action-dropdown-item">
                      <Edit2 :size="14" class="text-gray-500" />
                      <span>Edit</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button @click="triggerDelete(gp.id)" class="action-dropdown-item text-red-650">
                      <Trash2 :size="14" />
                      <span>Delete</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Footer / Pagination -->
      <div class="table-footer">
        <div class="footer-info">
          Showing 1 to 2 of 2 entries
          <span class="per-page-selector">
            Per Page: 
            <select class="page-select">
              <option>1</option>
              <option selected>2</option>
              <option>10</option>
            </select>
          </span>
        </div>

        <div class="pagination-controls">
          <button class="page-nav-btn">
            <ArrowLeft :size="14" class="mr-1.5" />
            Previous
          </button>
          <button class="page-num active">1</button>
          <button class="page-num">2</button>
          <button class="page-num">3</button>
          <span class="pagination-ellipsis">...</span>
          <button class="page-num">8</button>
          <button class="page-num">9</button>
          <button class="page-num">10</button>
          <button class="page-nav-btn">
            Next
            <ArrowRight :size="14" class="ml-1.5" />
          </button>
        </div>
      <!-- VIEW DETAILS MODAL -->
      <div v-if="showViewModal" class="modal-overlay" @click.self="showViewModal = false">
        <div class="modal-card">
          <button class="modal-close-btn" @click="showViewModal = false">
            <X :size="18" />
          </button>

          <header class="modal-card-header">
            <h3>Gate Pass Details — {{ viewItem?.no }}</h3>
          </header>

          <div class="modal-body-content">
            <div class="view-details-grid">
              <div class="detail-item full-width">
                <span class="detail-label">Gate Pass Document Number</span>
                <span class="detail-value text-lg font-semibold text-gray-900">{{ viewItem?.no }}</span>
              </div>

              <div class="detail-item">
                <span class="detail-label">Movement Type</span>
                <span class="detail-value font-medium text-gray-800">
                  <ArrowUpRight v-if="viewItem?.type === 'Outward'" :size="14" class="inline mr-1 text-gray-500" />
                  <ArrowDownLeft v-else :size="14" class="inline mr-1 text-gray-500" />
                  {{ viewItem?.type }}
                </span>
              </div>

              <div class="detail-item">
                <span class="detail-label">Location / Origin</span>
                <span class="detail-value text-gray-800">{{ viewItem?.location }}</span>
              </div>

              <div class="detail-item">
                <span class="detail-label">Creation Date</span>
                <span class="detail-value text-gray-800">{{ viewItem?.date }}</span>
              </div>

              <div class="detail-item">
                <span class="detail-label">Operational Status</span>
                <span :class="['status-badge mt-1', getStatusClass(viewItem?.status || '')]">
                  <span v-if="viewItem?.status === 'Completed'" class="dot"></span>
                  <span v-else class="dot-gray"></span>
                  {{ viewItem?.status }}
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
  </div>
</div>
</template>

<style scoped>
.gate-pass-page {
  animation: fadeIn 0.4s ease-out;
  display: flex;
  flex-direction: column;
  gap: 16px;
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
  font-family: 'Inter', sans-serif;
}

.breadcrumb-link {
  color: #9ca3af; /* Perfect gray-like color */
  text-decoration: none;
  display: flex;
  align-items: center;
  transition: color 0.15s ease;
}

.breadcrumb-link:hover {
  color: #111827; /* Dark on hover */
}

.breadcrumb-separator {
  color: #9ca3af; /* Light gray chevron */
  display: flex;
  align-items: center;
}

.breadcrumb-active {
  color: #111827; /* Dark black color for active page */
  font-weight: 500;
}

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
  padding: 16px 16px 8px 16px;
  margin-bottom: 0;
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
  max-width: 900px;
}

/* Action Bar */
.action-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 16px 12px 16px;
  margin-bottom: 0;
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

.btn-filter, .btn-sort {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 16px;
  height: 42px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 500;
  color: #374151;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-filter:hover, .btn-sort:hover { background: #f9fafb; border-color: #d1d5db; }
.btn-filter.active, .btn-sort.active { background: #f3f4f6; color: #111827; border-color: #d1d5db; }

.btn-icon-square {
  width: 42px;
  height: 42px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  color: #374151;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-icon-square:hover { background: #f9fafb; border-color: #d1d5db; }
.btn-icon-square.active { background: #f3f4f6; color: #111827; border-color: #d1d5db; }

/* Sort Dropdown Menu */
.sort-toggle-wrapper {
  position: relative;
}
.sort-dropdown-menu {
  position: absolute;
  top: calc(100% + 8px);
  left: 0;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05), 0 4px 6px -2px rgba(0,0,0,0.01);
  padding: 12px;
  min-width: 200px;
  z-index: 100;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.sort-option {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 8px 12px;
  font-size: 13px;
  color: #374151;
  background: none;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  transition: all 0.15s ease;
}
.sort-option:hover {
  background: #f9fafb;
  color: #111827;
}
.sort-option.active {
  background: #f3f4f6;
  color: #111827;
  font-weight: 500;
}
.active-dot {
  width: 6px;
  height: 6px;
  background: #111827;
  border-radius: 50%;
}

/* Column Toggle Dropdown */
.column-toggle-wrapper {
  position: relative;
}
.column-dropdown-menu {
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05), 0 4px 6px -2px rgba(0,0,0,0.01);
  padding: 12px;
  min-width: 180px;
  z-index: 100;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.dropdown-header {
  font-size: 11px;
  font-weight: 700;
  color: #9ca3af;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 4px;
  padding-bottom: 4px;
  border-bottom: 1px solid #f3f4f6;
}
.column-option {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #374151;
  cursor: pointer;
  padding: 4px 0;
  user-select: none;
}
.column-option input[type="checkbox"] {
  cursor: pointer;
  accent-color: #111827;
}

/* Dynamic Filter Panel */
.filter-panel {
  display: flex;
  align-items: flex-end;
  gap: 20px;
  background: #f9fafb; /* Soft light neutral background */
  border-top: 1px solid #e5e7eb;
  border-bottom: 1px solid #e5e7eb;
  border-left: none;
  border-right: none;
  border-radius: 0;
  padding: 12px 16px;
  margin-bottom: 16px;
  animation: slideDown 0.2s ease-out;
}
@keyframes slideDown {
  from { opacity: 0; transform: translateY(-8px); }
  to { opacity: 1; transform: translateY(0); }
}
.filter-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex: 1;
}
.filter-label {
  font-size: 11px;
  font-weight: 700;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.filter-select {
  width: 100%;
  height: 40px;
  padding: 0 32px 0 12px;
  background: white url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e") no-repeat right 12px center/16px;
  appearance: none;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13px;
  color: #374151;
  outline: none;
  cursor: pointer;
  transition: all 0.15s ease;
}
.filter-select:focus {
  border-color: #111827;
  box-shadow: 0 0 0 1px #111827;
}
.btn-reset-filters {
  height: 40px;
  padding: 0 16px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13px;
  color: #374151;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-reset-filters:hover {
  background: #f9fafb;
  border-color: #d1d5db;
}

/* Fullscreen Mode */
.content-card.is-fullscreen {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 9999;
  background: white;
  border-radius: 0;
  padding: 32px;
  overflow-y: auto;
  margin: 0 !important;
}

.btn-create {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 20px;
  height: 42px;
  background: var(--alias-color-brand-blue-primary);
  color: #ffffff; /* White text */
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}
.btn-create:hover {
  background: var(--alias-color-brand-blue-primary-hover);
  transform: translateY(-1px);
}

/* Table and Checkboxes */
.table-wrapper {
  margin-bottom: 12px;
  overflow-x: auto;
  border: none;
  border-top: 1px solid #e5e7eb;
  border-bottom: 1px solid #e5e7eb;
  border-radius: 0;
  background: white;
}
.gate-pass-table {
  width: 100%;
  border-collapse: collapse;
}
.gate-pass-table th {
  text-align: left;
  padding: 12px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background: #fafafa;
  border-bottom: 1px solid #e5e7eb;
}
.gate-pass-table th:first-child, .gate-pass-table td:first-child {
  padding-left: 16px;
}
.gate-pass-table th:last-child, .gate-pass-table td:last-child {
  padding-right: 16px;
}
.gate-pass-table td {
  padding: 12px 16px;
  font-size: 13.5px;
  color: #737373;
  border-bottom: 1px solid #f3f4f6;
  vertical-align: middle;
}
.gate-pass-table td:nth-child(2) {
  color: #262626;
  font-weight: 600;
}
.gate-pass-table tr.row-selected {
  background: #f9fafb;
}
.gate-pass-table tr:last-child td {
  border-bottom: none;
}

.table-checkbox {
  appearance: none;
  cursor: pointer;
  width: 18px;
  height: 18px;
  border-radius: 6px; /* A little more rounded but not a full circle */
  border: 1.5px solid #d1d5db;
  background-color: white;
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  transition: all 0.2s ease;
}
.table-checkbox:hover {
  border-color: #9ca3af;
}
.table-checkbox:checked {
  background-color: #111827;
  border-color: #111827;
}
.table-checkbox:checked::after {
  content: '';
  width: 4.5px;
  height: 9px;
  border: solid white;
  border-width: 0 2px 2px 0;
  transform: rotate(45deg);
  position: absolute;
  top: 1.5px;
}

.type-cell { display: flex; align-items: center; gap: 8px; }

.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 400;
}
.status-completed { background: #ecfdf5; color: #059669; }
.status-initiated { background: #f3f4f6; color: #6b7280; }

.dot { width: 6px; height: 6px; background: #10b981; border-radius: 50%; }
.dot-gray { width: 6px; height: 6px; background: #6b7280; border-radius: 50%; }

.btn-more {
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  padding: 4px;
  border-radius: 6px;
}
.btn-more:hover { color: #111827; background: #f3f4f6; }

/* Table Footer */
.table-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px 16px 16px; /* Decreased padding to reduce overall section size */
  margin-top: 0;
}
.footer-info {
  font-size: 13px;
  color: #6b7280;
  display: flex;
  align-items: center;
}
.per-page-selector {
  margin-left: 24px;
  display: flex;
  align-items: center;
  color: #6b7280;
}
.page-select {
  padding: 4px 28px 4px 10px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13px;
  margin-left: 8px;
  outline: none;
  background: white url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e") no-repeat right 8px center/16px;
  appearance: none;
  cursor: pointer;
}

.pagination-controls {
  display: flex;
  align-items: center;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  overflow: hidden;
  background: white;
  box-shadow: 0 1px 2px rgba(0,0,0,0.02);
}
.page-nav-btn, .page-num {
  border: none;
  border-right: 1px solid #e5e7eb;
  background: white;
  color: #374151;
  height: 36px;
  padding: 0 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  border-radius: 0;
  transition: all 0.15s ease;
}
.page-nav-btn:last-child {
  border-right: none;
}
.page-num {
  width: 36px;
  padding: 0;
}
.page-num.active {
  background: #111827; /* Our primary color */
  color: white;
  font-weight: 600;
}
.page-nav-btn:hover, .page-num:hover:not(.active) {
  background: #f9fafb;
  color: #111827;
}
.pagination-ellipsis {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  font-size: 13px;
  color: #9ca3af;
  border-right: 1px solid #e5e7eb;
  background: white;
  user-select: none;
}

/* Floating Action Dropdown Menu & Modals */
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
