<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Layers, Box, CheckCircle, XCircle,
  Search, Filter, ArrowUpDown, Plus, MoreVertical, Warehouse as WarehouseIcon
} from 'lucide-vue-next';

const currentView = ref('list'); // 'list' or 'create'

// Realistic dummy data based on schemas
const warehousesList = [
  { id: 1, name: 'Main Central Hub', type: 'Central Warehouse', scope: 'Organization', adminUnit: 'Admin-01', location: 'Addis Ababa', state: 'Active' },
  { id: 2, name: 'Bole Store Backroom', type: 'Store Backroom', scope: 'Branch', adminUnit: 'Admin-Bole', location: 'Bole District', state: 'Active' }
];

const shelvesList = [
  { id: 1, name: 'Dried Goods Section', tag: 'SH-DG-001', warehouse: 'Main Central Hub', state: 'Active' },
  { id: 2, name: 'Cold Storage Racks', tag: 'SH-CS-042', warehouse: 'Bole Store Backroom', state: 'Active' }
];

const binsList = [
  { id: 1, category: 'Beverages', code: 'A1', warehouse: 'Main Central Hub', shelf: 'Dried Goods Section', state: 'Active' },
  { id: 2, category: 'Dairy Products', code: 'C4', warehouse: 'Bole Store Backroom', shelf: 'Cold Storage Racks', state: 'Active' },
  { id: 3, category: 'Bulk Flour', code: 'BULK-01', warehouse: 'Main Central Hub', shelf: 'None (Direct)', state: 'Inactive' }
];

const activeTab = ref('Warehouse');

// Form state reflecting exact database schema
const form = ref({
  name: '',
  warehouse_id: '', // nullable parent
  warehouse_type_id: '',
  admin_unit_id: '', // Used for the dynamic selector
  scope: '', // e.g., organization, branch
  scope_id: '',
  mapMethod: 'DD',
  latitude: '',
  longitude: '',
  is_group: false,
  has_shelf: true,
  has_bin: true,
  shelves: [{ name: '', tag: '' }],
  bins: [{ name: '', code: '', warehouse_shelf_id: '' }] // name (Food, Beverages), code (A1), shelf_id
});

const addShelf = () => {
  form.value.shelves.push({ name: '', tag: '' });
};

const addBin = () => {
  form.value.bins.push({ name: '', code: '', warehouse_shelf_id: '' });
};
</script>

<template>
  <DashboardLayout>
    <div class="org-layout">
      <!-- Breadcrumb Bar - Global Container for layout sync -->
      <div class="breadcrumb-bar flex items-center justify-between mb-4">
        <div class="breadcrumb flex items-center gap-2 text-xs text-gray-500">
          <Monitor :size="14" />
          <ChevronRight :size="12" class="text-gray-300" />
          <span class="text-gray-700 font-medium cursor-pointer" @click="currentView = 'list'">Warehouse</span>
          
          <!-- Dynamic tail for create mode -->
          <template v-if="currentView === 'create'">
            <ChevronRight :size="12" class="text-gray-300" />
            <span class="text-gray-700 font-medium">Create Warehouse</span>
            <span class="badge-warning ml-2">Not Saved</span>
          </template>
        </div>

        <div class="top-actions" v-if="currentView === 'create'">
          <button class="btn-primary" @click="currentView = 'list'">Save</button>
        </div>
      </div>

      <!-- LIST VIEW -->
      <div v-if="currentView === 'list'">
        <!-- Header Section -->
        <div class="page-container p-6 bg-white rounded-xl shadow-sm border border-gray-200 mb-6">
          <div class="page-header">
            <h2 class="text-xl font-bold text-gray-900 mb-1">Warehouse Details</h2>
            <p class="text-sm text-gray-500 m-0">Establish legally distinct parent warehouses, internal shelves, and physical sorting bins.</p>
          </div>
        </div>

        <!-- Segmented Tabs -->
        <div class="flex gap-2 mb-6">
          <button 
            :class="['seg-tab', { 'active': activeTab === 'Warehouse' }]" 
            @click="activeTab = 'Warehouse'">
            <WarehouseIcon :size="16" /> Warehouse
          </button>
          <button 
            :class="['seg-tab', { 'active': activeTab === 'Shelves' }]" 
            @click="activeTab = 'Shelves'">
            <Layers :size="16" /> Shelves
          </button>
          <button 
            :class="['seg-tab', { 'active': activeTab === 'Bins' }]" 
            @click="activeTab = 'Bins'">
            <Box :size="16" /> Bins
          </button>
        </div>

        <!-- Main Table Section -->
        <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
          <!-- Toolbar -->
          <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between">
            <div class="toolbar-left flex gap-3">
              <div class="search-box">
                <Search :size="16" class="search-icon" />
                <input type="text" placeholder="Search..." class="search-input" />
              </div>
              <button class="btn-outline flex items-center gap-2">
                <Filter :size="14" /> Filter
              </button>
              <button class="btn-outline flex items-center gap-2">
                <ArrowUpDown :size="14" /> Sort <ChevronDown class="ml-1" :size="12"/>
              </button>
            </div>
            <div class="toolbar-right">
              <button class="btn-primary flex items-center gap-2" @click="currentView = 'create'">
                <Plus :size="14" /> Create Warehouse
              </button>
            </div>
          </div>

          <!-- Table View Swapper -->
          <div class="table-responsive">
            
            <!-- WAREHOUSES TABLE -->
            <table v-if="activeTab === 'Warehouse'" class="w-full text-left text-sm text-gray-700">
              <thead class="text-xs text-gray-500 border-b border-gray-100">
                <tr>
                  <th class="px-6 py-4 font-semibold">Warehouse Name</th>
                  <th class="px-6 py-4 font-semibold">Type</th>
                  <th class="px-6 py-4 font-semibold">Administrative Link</th>
                  <th class="px-6 py-4 font-semibold">Location Data</th>
                  <th class="px-6 py-4 font-semibold">State</th>
                  <th class="px-6 py-4 font-semibold text-right">Action</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="w in warehousesList" :key="w.id" class="border-b border-gray-50 hover:bg-gray-50">
                  <td class="px-6 py-4 font-medium text-gray-900">{{ w.name }}</td>
                  <td class="px-6 py-4 text-gray-500">{{ w.type }}</td>
                  <td class="px-6 py-4">
                    <div class="text-xs text-gray-900 font-medium">Scope: {{ w.scope }}</div>
                    <div class="text-xs text-gray-400">Unit: {{ w.adminUnit }}</div>
                  </td>
                  <td class="px-6 py-4 text-gray-500">{{ w.location }}</td>
                  <td class="px-6 py-4">
                    <span :class="['badge', w.state === 'Active' ? 'badge-success' : 'badge-danger']">{{ w.state }}</span>
                  </td>
                  <td class="px-6 py-4 text-right">
                    <button class="text-gray-400 hover:text-gray-600"><MoreVertical :size="16" /></button>
                  </td>
                </tr>
              </tbody>
            </table>

            <!-- SHELVES TABLE -->
            <table v-if="activeTab === 'Shelves'" class="w-full text-left text-sm text-gray-700">
              <thead class="text-xs text-gray-500 border-b border-gray-100">
                <tr>
                  <th class="px-6 py-4 font-semibold">Shelf Name</th>
                  <th class="px-6 py-4 font-semibold">Tracking Tag</th>
                  <th class="px-6 py-4 font-semibold">Parent Warehouse</th>
                  <th class="px-6 py-4 font-semibold">State</th>
                  <th class="px-6 py-4 font-semibold text-right">Action</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="s in shelvesList" :key="s.id" class="border-b border-gray-50 hover:bg-gray-50">
                  <td class="px-6 py-4 font-medium text-gray-900">{{ s.name }}</td>
                  <td class="px-6 py-4"><span class="chip">{{ s.tag }}</span></td>
                  <td class="px-6 py-4 text-gray-500">{{ s.warehouse }}</td>
                  <td class="px-6 py-4">
                    <span :class="['badge', s.state === 'Active' ? 'badge-success' : 'badge-danger']">{{ s.state }}</span>
                  </td>
                  <td class="px-6 py-4 text-right">
                    <button class="text-gray-400 hover:text-gray-600"><MoreVertical :size="16" /></button>
                  </td>
                </tr>
              </tbody>
            </table>

            <!-- BINS TABLE -->
            <table v-if="activeTab === 'Bins'" class="w-full text-left text-sm text-gray-700">
              <thead class="text-xs text-gray-500 border-b border-gray-100">
                <tr>
                  <th class="px-6 py-4 font-semibold">Bin Code</th>
                  <th class="px-6 py-4 font-semibold">Category (Name)</th>
                  <th class="px-6 py-4 font-semibold">Parent Linkage</th>
                  <th class="px-6 py-4 font-semibold">State</th>
                  <th class="px-6 py-4 font-semibold text-right">Action</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="b in binsList" :key="b.id" class="border-b border-gray-50 hover:bg-gray-50">
                  <td class="px-6 py-4 font-medium text-gray-900">{{ b.code }}</td>
                  <td class="px-6 py-4 text-gray-500">{{ b.category }}</td>
                  <td class="px-6 py-4">
                    <div class="text-xs text-gray-900 font-medium">Warehouse: {{ b.warehouse }}</div>
                    <div class="text-xs text-gray-400">Shelf: {{ b.shelf }}</div>
                  </td>
                  <td class="px-6 py-4">
                    <span :class="['badge', b.state === 'Active' ? 'badge-success' : 'badge-danger']">{{ b.state }}</span>
                  </td>
                  <td class="px-6 py-4 text-right">
                    <button class="text-gray-400 hover:text-gray-600"><MoreVertical :size="16" /></button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Pagination Footer -->
          <div class="pagination-footer p-4 border-t border-gray-100 flex items-center justify-between text-sm text-gray-500">
            <div class="flex items-center gap-4">
              <span>Showing 1 to 2 of 2 entries</span>
              <div class="flex items-center gap-2">
                <span>Per Page:</span>
                <select class="per-page-select">
                  <option>1</option>
                  <option>10</option>
                  <option>50</option>
                </select>
              </div>
            </div>
            
            <div class="flex items-center border border-gray-200 rounded-md overflow-hidden">
              <button class="page-btn flex items-center gap-1 border-r border-gray-200 px-3">
                <ChevronRight class="rotate-180" :size="14" /> Previous
              </button>
              <button class="page-btn active">1</button>
              <button class="page-btn">2</button>
              <button class="page-btn">3</button>
              <button class="page-btn px-2">...</button>
              <button class="page-btn">8</button>
              <button class="page-btn">9</button>
              <button class="page-btn border-r-0">10</button>
              <button class="page-btn flex items-center gap-1 border-l border-gray-200 px-3">
                Next <ChevronRight :size="14" />
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- CREATE VIEW -->
      <div v-else class="create-view">
        <div class="form-grid">
          <!-- General Details -->
          <div class="form-group">
            <label>Name</label>
            <input type="text" class="input flex-1 w-full" placeholder="Warehouse" v-model="form.name" />
          </div>
          <div class="form-group" v-if="!form.is_group">
            <label>Parent Warehouse</label>
            <select class="input flex-1 w-full" v-model="form.warehouse_id">
              <option value="">Select warehouse</option>
            </select>
          </div>
          <div class="form-group" v-else>
             <!-- Spacer if it is a group and shouldn't have a parent -->
          </div>
          
          <div class="form-group">
            <label>Entity Type (Warehouse Type)</label>
            <select class="input flex-1 w-full" v-model="form.warehouse_type_id">
              <option value="">Select</option>
            </select>
          </div>
          <div class="form-group">
            <label>Scope (Admin Unit)</label>
            <select class="input flex-1 w-full" v-model="form.scope">
              <option value="">Select Scope</option>
            </select>
          </div>
          <div class="form-group">
            <label>Scope Selection</label>
            <select class="input flex-1 w-full" v-model="form.scope_id">
              <option value="">Select Specific Structure</option>
            </select>
          </div>
          <div class="form-group">
            <label>Admin Unit ID</label>
            <input type="text" class="input flex-1 w-full" placeholder="Admin Unit Link" v-model="form.admin_unit_id" />
          </div>
        </div>

        <!-- Map Integration -->
        <div class="form-section mt-6">
          <h3 class="section-title">Map Integration</h3>
          <p class="section-subtitle">Choose the Method and Select insert the coordinates</p>
          
          <div class="segmented-control inline-flex bg-gray-100 rounded-lg p-1 mb-6">
            <button 
              :class="['seg-btn', { active: form.mapMethod === 'DD' }]"
              @click="form.mapMethod = 'DD'">Decimal degrees (DD)</button>
            <button 
              :class="['seg-btn', { active: form.mapMethod === 'DMS' }]"
              @click="form.mapMethod = 'DMS'">Degrees, minutes, and seconds (DMS)</button>
          </div>

          <div class="grid grid-cols-2 gap-6">
            <div class="form-group">
              <label>latitude</label>
              <input type="text" class="input w-full" placeholder="eg.40.40338, 2.17..." v-model="form.latitude" />
            </div>
            <div class="form-group">
              <label>longitude</label>
              <input type="text" class="input w-full" placeholder="eg.41.40338, 2.17..." v-model="form.longitude" />
            </div>
          </div>
        </div>

        <!-- Group Warehouse -->
        <div class="form-section mt-4 flex items-center justify-between">
          <div>
            <h3 class="section-title">Group Warehouse</h3>
            <p class="section-subtitle m-0">Acts as a parent container for other warehouses</p>
          </div>
          <label class="toggle-switch">
            <input type="checkbox" v-model="form.is_group">
            <span class="slider"></span>
          </label>
        </div>

        <!-- Has Shelves -->
        <div class="form-section mt-4">
          <div class="flex items-center justify-between mb-4">
            <div>
              <h3 class="section-title">Has Shelves</h3>
              <p class="section-subtitle m-0">Enable shelf-level organization inside this warehouse to group storage spaces logically.</p>
            </div>
            <label class="toggle-switch">
              <input type="checkbox" v-model="form.has_shelf">
              <span class="slider"></span>
            </label>
          </div>
          
          <div class="config-block border border-gray-200 rounded-xl p-6" v-if="form.has_shelf">
            <div class="flex gap-6 mb-6" v-for="(shelf, index) in form.shelves" :key="'shelf'+index">
              <div class="form-group flex-1">
                <label>Shelf Name</label>
                <input type="text" class="input w-full" placeholder="Shelf 1" v-model="shelf.name" />
              </div>
              <div class="form-group flex-1">
                <label>Tag</label>
                <input type="text" class="input w-full" placeholder="Tag 1" v-model="shelf.tag" />
              </div>
            </div>
            <button class="btn-dashed w-full" @click="addShelf"><Plus :size="14" /> Add Shelf</button>
          </div>
        </div>

        <!-- Has Bins -->
        <div class="form-section mt-4 mb-10">
          <div class="flex items-center justify-between mb-4">
            <div>
              <h3 class="section-title">Has Bins</h3>
              <p class="section-subtitle m-0">Enable bin-level tracking for precise item storage within shelves or directly in the warehouse.</p>
            </div>
            <label class="toggle-switch">
              <input type="checkbox" v-model="form.has_bin">
              <span class="slider"></span>
            </label>
          </div>
          
          <div class="config-block border border-gray-200 rounded-xl p-6" v-if="form.has_bin">
            <div class="flex gap-6 mb-6" v-for="(bin, index) in form.bins" :key="'bin'+index">
              <div class="form-group flex-1">
                <label>Bin Name (Category)</label>
                <input type="text" class="input w-full" placeholder="e.g. Beverages" v-model="bin.name" />
              </div>
              <div class="form-group flex-1">
                <label>Bin Code</label>
                <input type="text" class="input w-full" placeholder="e.g. A1" v-model="bin.code" />
              </div>
              <div class="form-group flex-1" v-if="form.has_shelf">
                <label>Shelf</label>
                <select class="input w-full" v-model="bin.warehouse_shelf_id">
                  <option value="">Select Shelf</option>
                  <option v-for="(s, idx) in form.shelves" :key="idx" :value="idx">{{ s.name || 'Shelf '+(idx+1) }}</option>
                </select>
              </div>
            </div>
            <button class="btn-dashed w-full" @click="addBin"><Plus :size="14" /> Add Bin</button>
          </div>
        </div>
      </div>

    </div>
  </DashboardLayout>
</template>

<style scoped>
.org-layout {
  max-width: 1200px;
  margin: 0 auto;
}

.badge-warning {
  background-color: #fef3c7;
  color: #d97706;
  font-size: 10px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 12px;
}

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

.metric-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
}

.metric-icon-box {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.seg-tab {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 500;
  color: #6b7280;
  background: white;
  border: 1px solid #e5e5e5;
  cursor: pointer;
}
.seg-tab.active {
  background: #f3f4f6;
  color: #111827;
}

.search-box {
  position: relative;
  width: 300px;
}
.search-input {
  width: 100%;
  padding: 8px 12px 8px 36px;
  border: 1px solid #e5e5e5;
  border-radius: 6px;
  font-size: 13px;
  outline: none;
}
.search-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: #9ca3af;
}

.btn-outline {
  padding: 8px 16px;
  border: 1px solid #e5e5e5;
  background: white;
  color: #374151;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-primary {
  padding: 8px 16px;
  background: #0056b3;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.chip {
  background: #eff6ff;
  color: #2563eb;
  padding: 4px 8px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 500;
}
.chip-extra {
  background: #f3f4f6;
  color: #4b5563;
  padding: 4px 8px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 500;
}

.badge-success {
  background: #dcfce7;
  color: #16a34a;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 500;
}

.badge-danger {
  background: #fee2e2;
  color: #dc2626;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 500;
}

.help-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 14px;
  height: 14px;
  border: 1px solid #d1d5db;
  border-radius: 50%;
  font-size: 9px;
  color: #6b7280;
}

.per-page-select {
  border: 1px solid #e5e5e5;
  border-radius: 4px;
  padding: 4px 8px;
  font-size: 13px;
  outline: none;
}

.page-btn {
  padding: 6px 12px;
  background: white;
  border: none;
  border-right: 1px solid #e5e5e5;
  color: #374151;
  cursor: pointer;
  font-size: 13px;
}
.page-btn:last-child { border-right: none; }
.page-btn:hover { background: #f9fafb; }
.page-btn.active {
  background: #0056b3;
  color: white;
  font-weight: 500;
}

/* Create Form Styles */
.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  row-gap: 24px;
  column-gap: 24px;
}

.form-group label {
  display: block;
  font-size: 12px;
  font-weight: 600;
  color: #4b5563;
  margin-bottom: 6px;
}

.input {
  border: 1px solid #e5e5e5;
  padding: 10px 12px;
  border-radius: 8px;
  font-size: 14px;
  outline: none;
  background-color: white;
}
.input:focus {
  border-color: #0056b3;
}

.form-section {
  background: white;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  padding: 24px;
}

.section-title {
  font-size: 15px;
  font-weight: 700;
  color: #111827;
  margin-bottom: 4px;
}
.section-subtitle {
  font-size: 13px;
  color: #6b7280;
  margin-bottom: 16px;
}

.seg-btn {
  padding: 6px 14px;
  font-size: 12px;
  font-weight: 500;
  color: #6b7280;
  border-radius: 6px;
  background: transparent;
  border: none;
  cursor: pointer;
}
.seg-btn.active {
  background: white;
  color: #111827;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}

.btn-dashed {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 10px;
  border: 1px dashed #d1d5db;
  border-radius: 8px;
  background: #fafafa;
  color: #4b5563;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}
.btn-dashed:hover {
  background: #f3f4f6;
  border-color: #9ca3af;
}

/* Apple style toggle */
.toggle-switch {
  position: relative;
  display: inline-block;
  width: 44px;
  height: 24px;
}
.toggle-switch input {
  opacity: 0;
  width: 0;
  height: 0;
}
.slider {
  position: absolute;
  cursor: pointer;
  top: 0; left: 0; right: 0; bottom: 0;
  background-color: #d1d5db;
  transition: .4s;
  border-radius: 34px;
}
.slider:before {
  position: absolute;
  content: "";
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: .4s;
  border-radius: 50%;
  box-shadow: 0 1px 2px rgba(0,0,0,0.1);
}
input:checked + .slider {
  background-color: #0056b3;
}
input:checked + .slider:before {
  transform: translateX(20px);
}
</style>
