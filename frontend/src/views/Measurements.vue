<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Search, Filter, Plus, MoreVertical, CheckCircle, ArrowRightLeft, FolderTree, Scale
} from 'lucide-vue-next';

// State Management
const currentView = ref('list'); // 'list' or 'create'
const activeTab = ref('units'); // 'categories', 'units', 'conversions'

// --- SCEMA DATA STORE (DUMMY REPRESENTATIONS) ---

// 1. Categories
const categoriesList = [
  { id: 1, name: 'Mass', state: 'Active' },
  { id: 2, name: 'Liquid Volume', state: 'Active' },
  { id: 3, name: 'Distance', state: 'Inactive' }
];

// 2. Units
const unitsList = [
  { id: 1, name: 'Kilogram', symbol: 'kg', category: 'Mass', decimalSupport: true, eimsCode: 'KGM', status: 'Active' },
  { id: 2, name: 'Piece', symbol: 'pcs', category: 'Count', decimalSupport: false, eimsCode: 'C62', status: 'Active' },
  { id: 3, name: 'Liter', symbol: 'L', category: 'Liquid Volume', decimalSupport: true, eimsCode: 'LTR', status: 'Pending' }
];

// 3. Conversions
const conversionsList = [
  { id: 1, from: 'Kilogram', to: 'Gram', rate: '1000', author: 'System Admin' },
  { id: 2, from: 'Box (24)', to: 'Piece', rate: '24', author: 'System Admin' }
];

// Form States mapped strictly to the schemas
const formCategory = ref({ name: '', state: true });

const formUnit = ref({
  name: '',
  name_plural: '',
  symbol: '',
  measurement_category_id: '',
  has_decimal_support: true,
  code: '',
  status: 'Active'
});

const formConversion = ref({
  from_measurement_id: '',
  to_measurement_id: '',
  conversion_rate: ''
});
</script>

<template>
  <DashboardLayout>
    <div class="org-layout">
      <!-- Breadcrumb Bar -->
      <div class="breadcrumb-bar flex items-center justify-between mb-4">
        <div class="breadcrumb flex items-center gap-2 text-xs text-gray-500">
          <Monitor :size="14" />
          <ChevronRight :size="12" class="text-gray-300" />
          <span class="text-gray-700 font-medium cursor-pointer hover:text-blue-600" @click="currentView = 'list'">Measurements</span>
          
          <template v-if="currentView === 'create'">
            <ChevronRight :size="12" class="text-gray-300" />
            <span class="text-gray-700 font-medium">
              <template v-if="activeTab === 'categories'">Create Category</template>
              <template v-if="activeTab === 'units'">Create Measurement Unit</template>
              <template v-if="activeTab === 'conversions'">Create Conversion Rule</template>
            </span>
            <span class="badge-warning ml-2">Not Saved</span>
          </template>
        </div>

        <div class="top-actions" v-if="currentView === 'create'">
          <button class="btn-primary flex items-center gap-2" @click="currentView = 'list'">
            <CheckCircle :size="14" /> Save Record
          </button>
        </div>
      </div>

      <!-- LIST VIEW -->
      <div v-if="currentView === 'list'">
        <!-- Header -->
        <div class="page-container p-6 bg-white rounded-xl shadow-sm border border-gray-200 mb-6">
          <div class="page-header">
            <h2 class="text-xl font-bold text-gray-900 mb-1">Measurements & Conversions</h2>
            <p class="text-sm text-gray-500 m-0">Define the global physics layer for item metrics, handling raw base units to global conversion constants.</p>
          </div>
        </div>

        <!-- Segmented Tabs Array -->
        <div class="flex gap-2 mb-6">
          <button :class="['seg-tab', { 'active': activeTab === 'categories' }]" @click="activeTab = 'categories'">
            <FolderTree :size="16" /> Measurement Categories
          </button>
          <button :class="['seg-tab', { 'active': activeTab === 'units' }]" @click="activeTab = 'units'">
            <Scale :size="16" /> Measurement Units
          </button>
          <button :class="['seg-tab', { 'active': activeTab === 'conversions' }]" @click="activeTab = 'conversions'">
            <ArrowRightLeft :size="16" /> Global Conversions
          </button>
        </div>

        <!-- Main Data Table Container -->
        <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
          <!-- Toolbar -->
          <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between">
            <div class="toolbar-left flex gap-3">
              <div class="search-box">
                <Search :size="16" class="search-icon" />
                <input type="text" placeholder="Search parameters..." class="search-input" />
              </div>
              <button class="btn-outline flex items-center gap-2">
                <Filter :size="14" /> Filters
              </button>
            </div>
            <div class="toolbar-right">
              <button class="btn-primary flex items-center gap-2" @click="currentView = 'create'">
                <Plus :size="14" /> Create {{ activeTab === 'units' ? 'Unit' : activeTab === 'categories' ? 'Category' : 'Rule' }}
              </button>
            </div>
          </div>

          <!-- DYNAMIC TABLES SWITCHER -->
          <div class="table-responsive">
            
            <!-- 1. CATEGORIES TABLE -->
            <table v-if="activeTab === 'categories'" class="w-full text-left text-sm text-gray-700">
              <thead class="text-xs text-gray-500 border-b border-gray-100">
                <tr>
                  <th class="px-6 py-4 font-semibold">Category Name</th>
                  <th class="px-6 py-4 font-semibold w-32">State</th>
                  <th class="px-6 py-4 font-semibold text-right w-24">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="c in categoriesList" :key="c.id" class="border-b border-gray-50 hover:bg-gray-50">
                  <td class="px-6 py-4 font-medium text-gray-900">{{ c.name }}</td>
                  <td class="px-6 py-4">
                    <span :class="['badge', c.state === 'Active' ? 'badge-success' : 'badge-danger']">{{ c.state }}</span>
                  </td>
                  <td class="px-6 py-4 text-right">
                    <button class="text-gray-400 hover:text-gray-600"><MoreVertical :size="16" /></button>
                  </td>
                </tr>
              </tbody>
            </table>

            <!-- 2. UNITS TABLE -->
            <table v-else-if="activeTab === 'units'" class="w-full text-left text-sm text-gray-700">
              <thead class="text-xs text-gray-500 border-b border-gray-100">
                <tr>
                  <th class="px-6 py-4 font-semibold">Basic Name</th>
                  <th class="px-6 py-4 font-semibold">Symbol Mapping</th>
                  <th class="px-6 py-4 font-semibold">Classification</th>
                  <th class="px-6 py-4 font-semibold">EIMS Linkage</th>
                  <th class="px-6 py-4 font-semibold">Status</th>
                  <th class="px-6 py-4 font-semibold text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="u in unitsList" :key="u.id" class="border-b border-gray-50 hover:bg-gray-50">
                  <td class="px-6 py-4 font-medium text-gray-900">{{ u.name }}</td>
                  <td class="px-6 py-4 font-bold text-gray-500">{{ u.symbol }}</td>
                  <td class="px-6 py-4 text-gray-500">{{ u.category }} <span v-if="u.decimalSupport" class="chip ml-2">Decimals ✔</span></td>
                  <td class="px-6 py-4 font-mono text-xs">{{ u.eimsCode }}</td>
                  <td class="px-6 py-4">
                    <span :class="['badge', u.status === 'Active' ? 'badge-success' : u.status === 'Pending' ? 'badge-warning' : 'badge-danger']">{{ u.status }}</span>
                  </td>
                  <td class="px-6 py-4 text-right">
                    <button class="text-gray-400 hover:text-gray-600"><MoreVertical :size="16" /></button>
                  </td>
                </tr>
              </tbody>
            </table>

            <!-- 3. CONVERSIONS TABLE -->
            <table v-else-if="activeTab === 'conversions'" class="w-full text-left text-sm text-gray-700">
              <thead class="text-xs text-gray-500 border-b border-gray-100">
                <tr>
                  <th class="px-6 py-4 font-semibold">From Origin Unit</th>
                  <th class="px-6 py-4 font-semibold">To Expected Unit</th>
                  <th class="px-6 py-4 font-semibold">Universal Conversion Rate</th>
                  <th class="px-6 py-4 font-semibold">Registry Author</th>
                  <th class="px-6 py-4 font-semibold text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="cv in conversionsList" :key="cv.id" class="border-b border-gray-50 hover:bg-gray-50">
                  <td class="px-6 py-4 font-medium">{{ cv.from }}</td>
                  <td class="px-6 py-4 text-blue-600 font-medium">{{ cv.to }}</td>
                  <td class="px-6 py-4"><span class="chip">x {{ cv.rate }}</span></td>
                  <td class="px-6 py-4 text-gray-500">{{ cv.author }}</td>
                  <td class="px-6 py-4 text-right">
                    <button class="text-gray-400 hover:text-gray-600"><MoreVertical :size="16" /></button>
                  </td>
                </tr>
              </tbody>
            </table>

          </div>
          <!-- Pagination -->
          <div class="pagination-footer p-4 border-t border-gray-100 flex items-center justify-between text-sm text-gray-500">
            <div class="flex items-center gap-4">
              <span>Showing elements based on active context</span>
            </div>
            <div class="flex items-center border border-gray-200 rounded-md overflow-hidden">
              <button class="page-btn flex items-center gap-1 border-r border-gray-200 px-3">
                <ChevronRight class="rotate-180" :size="14" /> Prev
              </button>
              <button class="page-btn active">1</button>
              <button class="page-btn flex items-center gap-1 border-l border-gray-200 px-3">
                Next <ChevronRight :size="14" />
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- CREATE VIEW MULTIPLEXER -->
      <div v-else class="create-view max-w-4xl">
        
        <!-- FORM 1: CATEGORY CREATOR -->
        <div v-if="activeTab === 'categories'" class="animate-fade">
           <div class="form-section mb-6">
             <h3 class="section-title">Measurement Classification Grouping</h3>
             <p class="section-subtitle">Define high-level logical groups (e.g. Mass or Liquid).</p>
             <div class="grid grid-cols-2 gap-6">
               <div class="form-group col-span-2 md:col-span-1">
                 <label>Category Label</label>
                 <input type="text" class="input w-full" placeholder="E.g. Temperature" v-model="formCategory.name" />
               </div>
               <div class="form-group col-span-2 md:col-span-1 flex items-center gap-6 mt-6">
                 <div>
                   <div class="text-sm font-semibold text-gray-900">State Toggle</div>
                   <div class="text-xs text-gray-500">Maintain operational activity.</div>
                 </div>
                 <label class="toggle-switch"><input type="checkbox" v-model="formCategory.state"><span class="slider"></span></label>
               </div>
             </div>
           </div>
        </div>

        <!-- FORM 2: MEASUREMENT UNIT CREATOR -->
        <div v-if="activeTab === 'units'" class="animate-fade">
           <div class="form-section mb-6">
             <h3 class="section-title">Naming & Nomenclature</h3>
             <div class="grid grid-cols-3 gap-6">
               <div class="form-group">
                 <label>Name (Singular)</label>
                 <input type="text" class="input w-full" placeholder="Kilogram" v-model="formUnit.name" />
               </div>
               <div class="form-group">
                 <label>Name (Plural Variant)</label>
                 <input type="text" class="input w-full" placeholder="Kilograms" v-model="formUnit.name_plural" />
               </div>
               <div class="form-group">
                 <label>Scientific Symbol</label>
                 <input type="text" class="input w-full font-bold" placeholder="kg" v-model="formUnit.symbol" />
               </div>
             </div>
           </div>

           <div class="form-section mb-6">
             <h3 class="section-title">Classification & Behavior Settings</h3>
             <div class="grid grid-cols-2 gap-6">
               <div class="form-group">
                 <label>Measurement Category</label>
                 <select class="input w-full" v-model="formUnit.measurement_category_id">
                   <option value="">Link to Category Structure...</option>
                   <option value="1">Mass</option>
                   <option value="2">Liquid Volume</option>
                 </select>
               </div>
               <div class="form-group">
                 <label>Operational Status Override</label>
                 <select class="input w-full text-blue-800 font-semibold" v-model="formUnit.status">
                   <option value="Pending">Pending Validation</option>
                   <option value="Active">Operational / Active</option>
                   <option value="Inactive">Depreciated / Inactive</option>
                 </select>
               </div>
             </div>
             
             <div class="flex items-center justify-between p-4 border rounded-lg bg-gray-50 mt-6 border-gray-200">
               <div>
                 <div class="text-sm font-semibold text-gray-900">Decimal Value Support Permitted</div>
                 <div class="text-xs text-gray-500 mt-1">If enabled, standard arithmetic supports floating values (e.g. 1.5 kg). Turn off for discrete counts like 'Pieces'.</div>
               </div>
               <label class="toggle-switch"><input type="checkbox" v-model="formUnit.has_decimal_support"><span class="slider"></span></label>
             </div>
           </div>

           <div class="form-section mb-6">
             <h3 class="section-title">Government Integration (EIMS Framework)</h3>
             <p class="section-subtitle m-0">Electronic invoicing management system compliance mapping.</p>
             <div class="form-group mt-4 md:w-1/2">
               <label>Unique 3-Digit Tax Engine Code</label>
               <input type="text" class="input w-full font-mono text-lg tracking-widest uppercase" maxlength="3" placeholder="KGM" v-model="formUnit.code" />
             </div>
           </div>
        </div>

        <!-- FORM 3: CONVERSION CREATOR -->
        <div v-if="activeTab === 'conversions'" class="animate-fade">
           <div class="form-section mb-6 border-l-4 border-blue-500">
             <h3 class="section-title">Physical Formula Declaration</h3>
             <p class="section-subtitle">Define the exact universal relationship multipliers existing across the framework space.</p>
             
             <div class="bg-blue-50 flex items-center gap-6 p-6 rounded-xl border border-blue-100">
                <div class="form-group flex-1 m-0">
                  <label class="text-blue-900">1 UNIT ROOT Origin</label>
                  <select class="input w-full bg-white font-bold text-gray-700 shadow-sm" v-model="formConversion.from_measurement_id">
                    <option value="">FROM (Kilogram)</option>
                  </select>
                </div>
                
                <h2 class="text-2xl font-black text-blue-900 mt-5">=</h2>
                
                <div class="form-group flex-1 m-0">
                  <label class="text-blue-900">EQUATES EXACTLY TO Multiplier Amount</label>
                  <input type="number" class="input w-full bg-white font-mono shadow-sm border-blue-300" placeholder="1000" v-model="formConversion.conversion_rate" />
                </div>
                
                <h2 class="text-2xl font-black text-gray-400 mt-5">x</h2>
                
                <div class="form-group flex-1 m-0">
                  <label class="text-gray-700">TO End Target Value</label>
                  <select class="input w-full bg-white shadow-sm" v-model="formConversion.to_measurement_id">
                    <option value="">TO (Gram)</option>
                  </select>
                </div>
             </div>
             
             <div class="mt-4 flex justify-between">
                <span class="text-blue-600 font-medium text-sm w-full text-center">💡 Formula Output Preview Rule: "1 FROM = X TO"</span>
             </div>
           </div>
        </div>

      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.org-layout { max-width: 1200px; margin: 0 auto; }
.badge-warning { background-color: #fef3c7; color: #d97706; font-size: 11px; font-weight: 600; padding: 4px 12px; border-radius: 12px; }
.badge-success { background: #dcfce7; color: #16a34a; padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 500; }
.badge-danger {  background: #fee2e2; color: #dc2626; padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 500; }

.seg-tab { display: flex; align-items: center; gap: 8px; padding: 8px 16px; border-radius: 20px; font-size: 13px; font-weight: 500; color: #6b7280; background: white; border: 1px solid #e5e5e5; cursor: pointer; }
.seg-tab.active { background: #f3f4f6; color: #111827; }

.search-box { position: relative; width: 300px; }
.search-input { width: 100%; padding: 8px 12px 8px 36px; border: 1px solid #e5e5e5; border-radius: 6px; font-size: 13px; outline: none; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }

.btn-outline { padding: 8px 16px; border: 1px solid #e5e5e5; background: white; color: #374151; border-radius: 6px; font-size: 13px; font-weight: 500; cursor: pointer; }
.btn-primary { padding: 8px 16px; background: #0056b3; color: white; border: none; border-radius: 6px; font-size: 13px; font-weight: 500; cursor: pointer; }

.chip { background: #eff6ff; color: #2563eb; padding: 4px 8px; border-radius: 20px; font-size: 11px; font-weight: 500; }

.page-btn { padding: 6px 12px; background: white; border: none; border-right: 1px solid #e5e5e5; color: #374151; cursor: pointer; font-size: 13px; }
.page-btn:last-child { border-right: none; }
.page-btn:hover { background: #f9fafb; }
.page-btn.active { background: #0056b3; color: white; font-weight: 500; }

.form-group label { display: block; font-size: 12px; font-weight: 600; color: #4b5563; margin-bottom: 6px; }
.form-group.m-0 label { margin-bottom: 4px; }
.input { border: 1px solid #e5e5e5; padding: 10px 12px; border-radius: 8px; font-size: 14px; outline: none; background: white; transition: border 0.3s; }
.input:focus { border-color: #0056b3; box-shadow: 0 0 0 3px rgba(0,86,179, 0.1); }

.form-section { background: white; border: 1px solid #e5e5e5; border-radius: 12px; padding: 24px; }
.section-title { font-size: 15px; font-weight: 700; color: #111827; margin-bottom: 4px; }
.section-subtitle { font-size: 13px; color: #6b7280; margin-bottom: 16px; }

.toggle-switch { position: relative; display: inline-block; width: 44px; height: 24px; }
.toggle-switch input { opacity: 0; width: 0; height: 0; }
.slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #d1d5db; transition: .4s; border-radius: 34px; }
.slider:before { position: absolute; content: ""; height: 18px; width: 18px; left: 3px; bottom: 3px; background-color: white; transition: .4s; border-radius: 50%; box-shadow: 0 1px 2px rgba(0,0,0,0.1); }
input:checked + .slider { background-color: #0056b3; }
input:checked + .slider:before { transform: translateX(20px); }

.animate-fade { animation: fadeIn 0.3s ease-in-out; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(5px); } to { opacity: 1; transform: translateY(0); } }
</style>
