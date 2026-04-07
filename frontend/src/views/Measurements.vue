<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Search, Filter, Plus, MoreVertical, CheckCircle, ArrowRightLeft, FolderTree, Scale, X, Maximize2, Trash2
} from 'lucide-vue-next';

// View State Management
// 'list', 'create_unit', 'create_conversion', 'create_full'
const currentView = ref('list'); 
const activeTab = ref('categories'); // Table tabs

// Modal State
const showCategoryModal = ref(false);

// --- SCHEMA DATA STORE DUMMIES ---
const categoriesList = ref([
  { id: 1, name: 'Mass', state: 'Active' },
  { id: 2, name: 'Liquid Volume', state: 'Active' },
  { id: 3, name: 'Distance', state: 'Inactive' }
]);

const unitsList = ref([
  { id: 1, name: 'Kilogram', symbol: 'kg', category: 'Mass', decimalSupport: true, eimsCode: 'KGM', status: 'Active' },
  { id: 2, name: 'Piece', symbol: 'pcs', category: 'Count', decimalSupport: false, eimsCode: 'C62', status: 'Active' }
]);

const conversionsList = ref([
  { id: 1, from: 'Kilogram', to: 'Gram', rate: '1000', author: 'System Admin' }
]);

// Single Forms
const formUnit = ref({ name: '', name_plural: '', symbol: '', measurement_category_id: '', has_decimal_support: true, code: '', status: 'Active' });
const formConversion = ref({ from_measurement_id: '', to_measurement_id: '', conversion_rate: '' });

// Quick Modal Form state
const quickCategoryForm = ref({ name: '', state: true });

// Massive Unified Builder Form State
const getBlankUnit = () => ({ id: Date.now(), name: '', name_plural: '', symbol: '', has_decimal_support: true, code: '', status: 'Active' });
const fullForm = ref({
  category: { name: '', state: true },
  units: [ getBlankUnit() ],
  conversions: [ { id: Date.now(), from_index: '', to_index: '', conversion_rate: '' } ]
});

// Add/Remove dynamic rows
const addUnitRow = () => { fullForm.value.units.push(getBlankUnit()); };
const removeUnitRow = (index: number) => { fullForm.value.units.splice(index, 1); };

const addConversionRow = () => { fullForm.value.conversions.push({ id: Date.now(), from_index: '', to_index: '', conversion_rate: '' }); };
const removeConversionRow = (index: number) => { fullForm.value.conversions.splice(index, 1); };

// Actions
const saveQuickCategory = () => {
  categoriesList.value.push({ id: Date.now(), name: quickCategoryForm.value.name, state: quickCategoryForm.value.state ? 'Active' : 'Inactive' });
  showCategoryModal.value = false;
  quickCategoryForm.value = { name: '', state: true }; 
};

const goToFullExpandedForm = () => {
  fullForm.value.category.name = quickCategoryForm.value.name;
  fullForm.value.category.state = quickCategoryForm.value.state;
  fullForm.value.units = [ getBlankUnit() ];
  showCategoryModal.value = false;
  currentView.value = 'create_full';
};
</script>

<template>
  <DashboardLayout>
    <div class="org-layout relative">
      
      <!-- QUICK CATEGORY MODAL OVERLAY -->
      <div v-if="showCategoryModal" class="fixed inset-0 bg-gray-900/40 z-50 flex items-center justify-center p-4 backdrop-blur-sm">
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-[480px] overflow-hidden animate-spring">
          <!-- Header -->
          <div class="flex items-center justify-between p-6 pb-4">
            <h2 class="text-xl font-bold text-gray-900">Create Category</h2>
            <button @click="showCategoryModal = false" class="text-gray-400 hover:text-gray-600 rounded-lg p-1 hover:bg-gray-100 transition-colors">
              <X :size="20" />
            </button>
          </div>
          
          <!-- Body -->
          <div class="p-6 pt-2 space-y-6">
             <div class="form-group m-0">
               <label class="text-sm font-medium text-gray-700 mb-2 block">Name</label>
               <input type="text" class="input w-full p-3 border-gray-300 text-base shadow-sm focus:border-blue-500 focus:ring-1 focus:ring-blue-500" placeholder="Enter name" v-model="quickCategoryForm.name" />
             </div>
             
             <!-- Special Bordered Toggle -->
             <div class="flex items-center justify-between p-4 border border-gray-200 rounded-xl bg-white shadow-sm">
               <span class="text-base font-medium text-gray-800">Status</span>
               <label class="toggle-switch transform scale-110">
                 <input type="checkbox" v-model="quickCategoryForm.state">
                 <span class="slider bg-emerald-500 before:bg-white text-emerald-500 peer-checked:bg-emerald-500"></span>
               </label>
             </div>
          </div>
          
          <!-- Footer -->
          <div class="p-4 px-6 border-t border-gray-100 bg-gray-50/50 flex items-center justify-between">
             <button @click="goToFullExpandedForm" class="flex items-center justify-center gap-2 px-4 py-2.5 bg-white border border-gray-300 rounded-lg text-sm font-semibold text-gray-700 hover:bg-gray-50 hover:text-blue-700 transition-all shadow-sm">
               Expand Full Form <Maximize2 :size="14" />
             </button>
             <button @click="saveQuickCategory" class="px-6 py-2.5 bg-[#0e52a0] hover:bg-[#0b4284] text-white rounded-lg text-sm font-semibold transition-colors shadow-sm">
               Save
             </button>
          </div>
        </div>
      </div>

      <!-- Breadcrumb Bar -->
      <div class="breadcrumb-bar flex items-center justify-between mb-4">
        <div class="breadcrumb flex items-center gap-2 text-xs text-gray-500">
          <Monitor :size="14" />
          <ChevronRight :size="12" class="text-gray-300" />
          <span class="text-gray-700 font-medium cursor-pointer hover:text-blue-600" @click="currentView = 'list'">Measurements</span>
          
          <template v-if="currentView !== 'list'">
            <ChevronRight :size="12" class="text-gray-300" />
            <span class="text-gray-700 font-medium">
              <template v-if="currentView === 'create_full'">System Architecture Builder</template>
              <template v-if="currentView === 'create_unit'">Create Measurement Unit</template>
              <template v-if="currentView === 'create_conversion'">Create Conversion Rule</template>
            </span>
            <span class="badge-warning ml-2">Not Saved</span>
          </template>
        </div>

        <div class="top-actions" v-if="currentView !== 'list'">
          <button class="btn-primary flex items-center gap-2" @click="currentView = 'list'">
            <CheckCircle :size="14" /> {{ currentView === 'create_full' ? 'Commit Entire Architecture' : 'Save Record' }}
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

        <div class="flex gap-2 mb-6">
          <button :class="['seg-tab', { 'active': activeTab === 'categories' }]" @click="activeTab = 'categories'"><FolderTree :size="16" /> Category Groups</button>
          <button :class="['seg-tab', { 'active': activeTab === 'units' }]" @click="activeTab = 'units'"><Scale :size="16" /> Distinct Units</button>
          <button :class="['seg-tab', { 'active': activeTab === 'conversions' }]" @click="activeTab = 'conversions'"><ArrowRightLeft :size="16" /> Conversions</button>
        </div>

        <!-- Main Data Table Container -->
        <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
          <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between">
            <div class="toolbar-left flex gap-3">
              <div class="search-box">
                <Search :size="16" class="search-icon" />
                <input type="text" placeholder="Search physical attributes..." class="search-input" />
              </div>
            </div>
            <div class="toolbar-right">
              <!-- Smart Dynamic Target Action -->
              <button class="btn-primary flex items-center gap-2" @click="activeTab === 'categories' ? showCategoryModal = true : activeTab === 'units' ? currentView = 'create_unit' : currentView = 'create_conversion'">
                <Plus :size="14" /> {{ activeTab === 'categories' ? 'Create Category' : activeTab === 'units' ? 'Create Unity System' : 'Create Formula' }}
              </button>
            </div>
          </div>

          <!-- TABLES -->
          <div class="table-responsive">
            <table v-if="activeTab === 'categories'" class="w-full text-left text-sm text-gray-700">
              <thead class="text-xs text-gray-500 border-b border-gray-100">
                <tr><th class="px-6 py-4">Category Name</th><th class="px-6 py-4 w-32">State</th><th class="px-6 py-4 text-right w-24">Actions</th></tr>
              </thead>
              <tbody>
                <tr v-for="c in categoriesList" :key="c.id" class="border-b border-gray-50 hover:bg-gray-50">
                  <td class="px-6 py-4 font-bold text-gray-900">{{ c.name }}</td>
                  <td class="px-6 py-4"><span :class="['badge', c.state === 'Active' ? 'badge-success' : 'badge-danger']">{{ c.state }}</span></td>
                  <td class="px-6 py-4 text-right"><button class="text-gray-400 hover:text-gray-800"><MoreVertical :size="16" /></button></td>
                </tr>
              </tbody>
            </table>

            <table v-else-if="activeTab === 'units'" class="w-full text-left text-sm text-gray-700">
              <thead class="text-xs text-gray-500 border-b border-gray-100">
                <tr><th class="px-6 py-4">Basic Name</th><th class="px-6 py-4">Symbol</th><th class="px-6 py-4">Classification</th><th class="px-6 py-4">Status</th></tr>
              </thead>
              <tbody>
                <tr v-for="u in unitsList" :key="u.id" class="border-b border-gray-50 hover:bg-gray-50">
                  <td class="px-6 py-4 font-medium">{{ u.name }}</td>
                  <td class="px-6 py-4 font-bold">{{ u.symbol }}</td>
                  <td class="px-6 py-4">{{ u.category }} <span v-if="u.decimalSupport" class="chip ml-2">Decimals ✔</span></td>
                  <td class="px-6 py-4"><span class="badge badge-success">{{ u.status }}</span></td>
                </tr>
              </tbody>
            </table>

            <table v-else class="w-full text-left text-sm text-gray-700">
               <thead class="text-xs text-gray-500 border-b border-gray-100"><tr><th class="px-6 py-4">Formula Rule</th></tr></thead>
               <tbody>
                  <tr v-for="cv in conversionsList" :key="cv.id" class="border-b border-gray-50 hover:bg-gray-50">
                     <td class="px-6 py-4 font-mono text-blue-900 font-bold bg-blue-50/30">1 {{ cv.from }} = {{ cv.rate }} x {{ cv.to }}</td>
                  </tr>
               </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- ============================================== -->
      <!-- REGULAR FORM 1: STANDALONE MEASUREMENT UNIT    -->
      <!-- ============================================== -->
      <div v-else-if="currentView === 'create_unit'" class="create-view max-w-4xl mx-auto animate-fade">
         <div class="form-section mb-6">
           <h3 class="section-title">Naming & Nomenclature</h3>
           <p class="section-subtitle">Define structural nomenclature attributes for the system unit alias.</p>
           <div class="grid grid-cols-3 gap-6 mt-4">
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

         <div class="form-section mb-6 flex flex-col gap-6">
           <div>
             <h3 class="section-title mb-4">Classification & Behavior Settings</h3>
             <div class="grid grid-cols-2 gap-6">
               <div class="form-group m-0">
                 <label>Measurement Category</label>
                 <select class="input w-full" v-model="formUnit.measurement_category_id">
                   <option value="">Link to Category Structure...</option>
                   <option value="1">Mass</option>
                   <option value="2">Liquid Volume</option>
                 </select>
               </div>
               <div class="form-group m-0">
                 <label>Operational Status Override</label>
                 <select class="input w-full text-blue-800 font-semibold" v-model="formUnit.status">
                   <option value="Pending">Pending Validation</option>
                   <option value="Active">Operational / Active</option>
                   <option value="Inactive">Depreciated / Inactive</option>
                 </select>
               </div>
             </div>
           </div>
           
           <div class="flex items-center justify-between p-4 border rounded-lg bg-gray-50 border-gray-200">
             <div>
               <div class="text-sm font-semibold text-gray-900">Decimal Value Support Permitted</div>
               <div class="text-xs text-gray-500 mt-1">If enabled, standard arithmetic supports floating values (e.g. 1.5 kg). Turn off for discrete counts like 'Pieces'.</div>
             </div>
             <label class="toggle-switch transform scale-110"><input type="checkbox" v-model="formUnit.has_decimal_support"><span class="slider"></span></label>
           </div>
         </div>

         <div class="form-section shadow-sm border-t-2 border-t-blue-600">
           <h3 class="section-title">Government Integration (EIMS Framework)</h3>
           <p class="section-subtitle">Electronic invoicing management system compliance mapping.</p>
           <div class="form-group mt-2 w-1/2">
             <label>Unique 3-Digit Tax Engine Code</label>
             <input type="text" class="input w-full font-mono text-lg tracking-widest uppercase border-dashed" maxlength="3" placeholder="KGM" v-model="formUnit.code" />
           </div>
         </div>
      </div>

      <!-- ============================================== -->
      <!-- REGULAR FORM 2: STANDALONE CONVERSION RULE     -->
      <!-- ============================================== -->
      <div v-else-if="currentView === 'create_conversion'" class="create-view max-w-4xl mx-auto animate-fade">
         <div class="form-section border-t-4 border-t-blue-500">
           <h3 class="section-title">Physical Formula Declaration</h3>
           <p class="section-subtitle mb-6">Define the exact universal relationship multipliers existing across the framework space.</p>
           
           <div class="bg-blue-50 flex items-center gap-6 p-6 rounded-xl border border-blue-100 shadow-inner">
              <div class="form-group flex-1 m-0">
                <label class="text-blue-900">1 UNIT ROOT Origin</label>
                <select class="input w-full bg-white font-bold text-gray-800 shadow-sm border-white focus:border-blue-500" v-model="formConversion.from_measurement_id">
                  <option value="">FROM (Kilogram)</option>
                  <option value="1">Kilogram</option>
                  <option value="2">Piece</option>
                </select>
              </div>
              
              <h2 class="text-3xl font-black text-blue-900 mt-4">=</h2>
              
              <div class="form-group flex-1 m-0">
                <label class="text-blue-900">EQUATES EXACTLY TO</label>
                <input type="number" class="input w-full bg-white font-mono shadow-sm text-center font-bold text-xl placeholder-blue-200 border-white focus:border-blue-500" placeholder="MULTIPLIER" v-model="formConversion.conversion_rate" />
              </div>
              
              <h2 class="text-3xl font-black text-gray-400 mt-4">x</h2>
              
              <div class="form-group flex-1 m-0">
                <label class="text-gray-700">TARGET End Value</label>
                <select class="input w-full bg-white shadow-sm border-white focus:border-blue-500" v-model="formConversion.to_measurement_id">
                  <option value="">TO (Gram)</option>
                  <option value="1">Gram</option>
                  <option value="2">Box</option>
                </select>
              </div>
           </div>
           
           <div class="mt-6 flex justify-center text-blue-600 font-medium text-sm">
              <span class="bg-blue-50 px-4 py-2 rounded-full border border-blue-100">💡 Reference Output Template: "1 [FROM] = X [TO]"</span>
           </div>
         </div>
      </div>

      <!-- ============================================== -->
      <!-- FULL EXPANDED BUILDER VIEW (Massive Flow)      -->
      <!-- ============================================== -->
      <div v-else-if="currentView === 'create_full'" class="create-view max-w-5xl mx-auto space-y-6">
        
        <!-- Section 1: The Root Category Form -->
        <div class="form-section shadow-md border-t-4 border-t-blue-800">
           <div class="flex items-center gap-4 mb-6">
              <div class="w-10 h-10 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center font-bold text-xl">1</div>
              <div>
                <h3 class="section-title text-xl">Measurement Category Root</h3>
                <p class="section-subtitle mb-0">Define the overarching physics domain.</p>
              </div>
           </div>
           
           <div class="grid grid-cols-4 gap-6 bg-gray-50 p-6 rounded-xl border border-gray-200">
             <div class="form-group col-span-3 m-0">
               <label>Domain Nomenclature</label>
               <input type="text" class="input w-full text-xl shadow-inner border-gray-300 font-bold px-4 py-3" placeholder="E.g. Mass, Temperature, Liquid..." v-model="fullForm.category.name" />
             </div>
             <div class="form-group col-span-1 m-0 flex flex-col justify-center items-end bg-white p-4 border border-gray-200 rounded-lg">
               <span class="text-xs font-bold text-gray-400 uppercase tracking-wide block mb-2 text-right w-full">Activity State</span>
               <label class="toggle-switch scale-110">
                 <input type="checkbox" v-model="fullForm.category.state">
                 <span class="slider bg-[#0e52a0]"></span>
               </label>
             </div>
           </div>
        </div>

        <!-- Section 2: Units Under This Category -->
        <div class="border-t-4 border-t-emerald-500 bg-white rounded-xl shadow-md p-0 overflow-hidden animate-fade" style="animation-delay: 0.1s; animation-fill-mode: both;">
           <div class="p-8 border-b border-gray-100 flex items-center justify-between bg-emerald-50/30">
              <div class="flex items-center gap-4">
                 <div class="w-10 h-10 rounded-full bg-emerald-100 text-emerald-700 flex items-center justify-center font-bold text-xl">2</div>
                 <div>
                   <h3 class="section-title text-xl">Underlying System Units</h3>
                   <p class="section-subtitle mb-0 text-emerald-800/70">Construct regular operational units tied exactly to the domain mapped above.</p>
                 </div>
              </div>
              <button @click="addUnitRow" class="btn-primary bg-emerald-600 hover:bg-emerald-700 flex items-center gap-2"><Plus :size="16" /> Extract New Unit</button>
           </div>
           
           <!-- Standardized UI Units Repeater Block -->
           <div class="p-8 space-y-8 bg-gray-50/50">
              <div v-for="(unit, index) in fullForm.units" :key="unit.id" class="p-8 bg-white border border-gray-200 shadow-sm rounded-xl relative group transition-colors focus-within:border-emerald-300">
                <button @click="removeUnitRow(index)" v-if="fullForm.units.length > 1" class="absolute -right-3 -top-3 w-8 h-8 bg-white border border-red-200 text-red-500 hover:bg-red-50 hover:text-red-600 rounded-full flex items-center justify-center shadow-md opacity-0 group-hover:opacity-100 transition-opacity z-10">
                   <Trash2 :size="14" />
                </button>

                <!-- Regular Mode Look exactly mapping independent creation UX -->
                <div class="grid grid-cols-3 gap-6 mb-8 pb-8 border-b border-gray-100">
                   <div class="form-group m-0"><label>Name (Singular)</label><input type="text" class="input w-full" placeholder="Kilogram" v-model="unit.name" /></div>
                   <div class="form-group m-0"><label>Name (Plural)</label><input type="text" class="input w-full" placeholder="Kilograms" v-model="unit.name_plural" /></div>
                   <div class="form-group m-0"><label>Symbol</label><input type="text" class="input w-full font-bold bg-blue-50 text-blue-900 border-blue-200" placeholder="kg" v-model="unit.symbol" /></div>
                </div>
                
                <div class="grid grid-cols-2 gap-8 items-end">
                   <div class="form-group m-0">
                      <label>EIMS Tax Linking Code</label>
                      <input type="text" class="input w-full font-mono tracking-widest uppercase border-dashed bg-gray-50" maxlength="3" placeholder="KGM" v-model="unit.code" />
                   </div>
                   <div class="flex items-center justify-between p-4 border rounded-lg bg-gray-50 border-gray-200 h-full">
                      <div>
                        <div class="text-sm font-semibold text-gray-900 mb-1">Decimal Supports?</div>
                        <div class="text-xs text-gray-500">Allow fraction arithmetic</div>
                      </div>
                      <label class="toggle-switch scale-100"><input type="checkbox" v-model="unit.has_decimal_support"><span class="slider"></span></label>
                   </div>
                </div>

              </div>

              <!-- Empty State Catch -->
              <div v-if="fullForm.units.length === 0" class="p-8 border-2 border-dashed border-gray-200 rounded-xl text-center flex flex-col items-center justify-center bg-white shadow-sm">
                 <Scale :size="32" class="text-gray-300 mb-2" />
                 <span class="text-sm font-semibold text-gray-500 mb-4 block">No operative sub-units exist in this domain.</span>
                 <button @click="addUnitRow" class="btn-primary bg-emerald-600 border-none shadow-sm flex items-center gap-2 mx-auto"><Plus :size="14"/> Initialize Root Unit Segment</button>
              </div>
           </div>
        </div>

        <!-- Section 3: Internal Conversions Builder -->
        <div class="form-section shadow-md border-t-4 border-t-purple-600 animate-fade" style="animation-delay: 0.2s; animation-fill-mode: both;" v-if="fullForm.units.length >= 2">
           <div class="flex items-center justify-between mb-6">
              <div class="flex items-center gap-4">
                 <div class="w-10 h-10 rounded-full bg-purple-100 text-purple-700 flex items-center justify-center font-bold text-xl">3</div>
                 <div>
                   <h3 class="section-title text-xl">Cross-Architecture Conversions</h3>
                   <p class="section-subtitle mb-0">Draft deterministic formula arrays matching strictly the sub-units deployed above.</p>
                 </div>
              </div>
              <button @click="addConversionRow" class="btn-primary bg-purple-600 hover:bg-purple-700 flex items-center gap-2"><Plus :size="16" /> Declare Equation</button>
           </div>
           
           <div class="space-y-4">
              <div v-for="(conv, index) in fullForm.conversions" :key="conv.id" class="flex items-stretch gap-4 bg-purple-50/50 p-4 border border-purple-100 rounded-xl relative group hover:bg-purple-50 transition-colors">
                <button @click="removeConversionRow(index)" class="absolute -right-3 -top-3 w-8 h-8 bg-white border border-red-200 text-red-500 hover:bg-red-50 rounded-full flex items-center justify-center shadow-sm opacity-0 group-hover:opacity-100 transition-opacity z-10"><Trash2 :size="14" /></button>

                <!-- Equation block -->
                <div class="flex-1 bg-white p-3 rounded-lg border border-purple-200 flex items-center gap-4 shadow-sm">
                   <div class="font-bold text-purple-900 border border-purple-100 bg-purple-50 px-4 py-2 rounded">1</div>
                   <select class="input w-full font-bold bg-transparent border-transparent cursor-pointer hover:border-gray-200 outline-none" v-model="conv.from_index">
                      <option value="" disabled>SOURCE SYSTEM ORIGIN</option>
                       <option v-for="(u, idx) in fullForm.units" :key="idx" :value="idx">{{ u.name || 'Undefined Unit' }} {{ u.symbol ? `(${u.symbol})` : '' }}</option>
                   </select>
                </div>
                <h2 class="text-3xl font-black text-purple-900 flex flex-col justify-center translate-y-1">=</h2>
                <div class="flex-1 bg-white p-3 rounded-lg border border-purple-200 flex items-center shadow-sm">
                   <input type="number" class="input w-full text-center text-2xl font-black font-mono border-transparent shadow-none bg-transparent placeholder-purple-200 text-purple-600 p-0" placeholder="MULTIPLIER" v-model="conv.conversion_rate" />
                </div>
                <h2 class="text-2xl font-black text-purple-300 flex flex-col justify-center translate-y-1">x</h2>
                <div class="flex-1 bg-white p-3 rounded-lg border border-purple-200 flex items-center shadow-sm relative">
                    <select class="input w-full font-bold text-right bg-transparent border-transparent cursor-pointer hover:border-gray-200 appearance-none outline-none pr-8 text-gray-700" v-model="conv.to_index">
                      <option value="" disabled>OVERRIDE TARGET</option>
                       <option v-for="(u, idx) in fullForm.units" :key="idx" :value="idx">{{ u.name || 'Undefined Unit' }}</option>
                   </select>
                   <ChevronRight :size="16" class="absolute right-4 text-purple-300 pointer-events-none" />
                </div>
              </div>
           </div>
        </div>

      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.org-layout { max-width: 1200px; margin: 0 auto; min-height: 100vh;}
.badge { font-weight: 500; padding: 4px 12px; border-radius: 20px; font-size: 11px; }
.badge-warning { background-color: #fef3c7; color: #d97706; padding: 2px 8px; border-radius: 12px; font-weight: 600; font-size: 10px; }
.badge-success { background: #dcfce7; color: #16a34a; }
.badge-danger {  background: #fee2e2; color: #dc2626; }
.chip { background: #eff6ff; color: #2563eb; padding: 4px 8px; border-radius: 20px; font-size: 11px; font-weight: 500; }
.seg-tab { display: flex; align-items: center; gap: 8px; padding: 8px 16px; border-radius: 20px; font-size: 13px; font-weight: 500; color: #6b7280; background: white; border: 1px solid #e5e5e5; cursor: pointer; transition: all 0.2s; }
.seg-tab.active { background: #111827; color: white; border-color: #111827; }
.search-box { position: relative; width: 300px; }
.search-input { width: 100%; padding: 8px 12px 8px 36px; border: 1px solid #e5e5e5; border-radius: 6px; font-size: 13px; outline: none; transition: border-color .2s; }
.search-input:focus { border-color: #2563eb; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }
.btn-primary { padding: 8px 16px; background: #0056b3; color: white; border: none; border-radius: 6px; font-size: 13px; font-weight: 500; cursor: pointer; transition: background 0.2s; }
.btn-primary:hover { background: #004494; }
.btn-outline { padding: 8px 16px; border: 1px solid #e5e5e5; background: white; color: #374151; border-radius: 6px; font-size: 13px; font-weight: 500; cursor: pointer; }
.form-group label { display: block; font-size: 12px; font-weight: 600; color: #4b5563; margin-bottom: 6px; }
.form-group.m-0 label { margin-bottom: 4px; }
.input { border: 1px solid #e5e5e5; padding: 10px 12px; border-radius: 8px; font-size: 14px; outline: none; background: white; transition: all 0.2s; }
.input:focus { border-color: #2563eb; box-shadow: 0 0 0 3px rgba(37,99,235, 0.1); }
.form-section { background: white; border: 1px solid #e5e5e5; border-radius: 12px; padding: 32px; }
.section-title { font-weight: 800; color: #111827; margin-bottom: 4px; letter-spacing: -0.02em; }
.section-subtitle { font-size: 14px; color: #6b7280; font-weight: 500; }
.toggle-switch { position: relative; display: inline-block; width: 44px; height: 24px; }
.toggle-switch input { opacity: 0; width: 0; height: 0; }
.slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #d1d5db; transition: .3s cubic-bezier(0.4, 0, 0.2, 1); border-radius: 34px; }
.slider:before { position: absolute; content: ""; height: 18px; width: 18px; left: 3px; bottom: 3px; background-color: white; transition: .3s cubic-bezier(0.4, 0, 0.2, 1); border-radius: 50%; box-shadow: 0 2px 4px rgba(0,0,0,0.2); }
input:checked + .slider { background-color: #10b981; }
input:checked + .slider:before { transform: translateX(20px); }
.animate-fade { animation: fadeIn 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
.animate-spring { animation: springIn 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards; }
@keyframes springIn { from { opacity: 0; transform: scale(0.95) translateY(10px); } to { opacity: 1; transform: scale(1) translateY(0); } }
</style>
