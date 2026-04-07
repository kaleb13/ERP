<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Search, Filter, Plus, MoreVertical, CheckCircle, Package, X, Maximize2
} from 'lucide-vue-next';

// View Management
const currentView = ref('list'); // 'list' or 'create_full'
const showModal = ref(false);

const itemsList = ref([
  { id: 1, name: 'Samsung L-Type Processor', category: 'Microchips', type: 'Goods', status: 'Active' },
  { id: 2, name: 'General Consultation', category: 'Services Dept', type: 'Service', status: 'Active' },
  { id: 3, name: 'Raw Plastic Resins', category: 'Materials', type: 'Goods', status: 'Pending' }
]);

// Quick Modal Data
const quickForm = ref({
  name: '',
  item_category_id: '',
  item_type: 'goods'
});

// Full Details Data
const fullForm = ref({
  name: '',
  item_category_id: '',
  item_type: 'goods',
  status: 'Pending',
  allowed_measurements: [] as string[]
});

// Actions
const saveQuickItem = () => {
  itemsList.value.push({
    id: Date.now(),
    name: quickForm.value.name,
    category: quickForm.value.item_category_id === '1' ? 'Electronics' : 'Materials',
    type: quickForm.value.item_type === 'goods' ? 'Goods' : 'Service',
    status: 'Pending'
  });
  showModal.value = false;
  quickForm.value = { name: '', item_category_id: '', item_type: 'goods' };
};

const expandFullForm = () => {
  // Transfer to full form context
  fullForm.value.name = quickForm.value.name;
  fullForm.value.item_category_id = quickForm.value.item_category_id;
  fullForm.value.item_type = quickForm.value.item_type;
  
  showModal.value = false;
  currentView.value = 'create_full';
};
</script>

<template>
  <DashboardLayout>
    <div class="org-layout relative">
      
      <!-- QUICK CREATE MODAL -->
      <div v-if="showModal" class="fixed inset-0 bg-gray-900/40 z-50 flex items-center justify-center p-4 backdrop-blur-sm">
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-[480px] overflow-hidden animate-spring">
          <!-- Header -->
          <div class="flex items-center justify-between p-6 pb-4 border-b border-gray-100">
            <h2 class="text-xl font-bold text-gray-900">Define Baseline Item</h2>
            <button @click="showModal = false" class="text-gray-400 hover:text-gray-600 rounded-lg p-1 hover:bg-gray-100 transition-colors">
              <X :size="20" />
            </button>
          </div>
          
          <!-- Body -->
          <div class="p-6 pt-5 space-y-5 bg-gray-50/50">
             <div class="form-group m-0 border border-gray-200 bg-white rounded-xl p-4 shadow-sm">
               <label class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2 block">Universal Name</label>
               <input type="text" class="input w-full p-2 border-transparent shadow-none px-0 text-lg font-bold bg-transparent focus:border-transparent placeholder-gray-300" placeholder="e.g. Raw Lumber Core" v-model="quickForm.name" />
             </div>
             
             <div class="grid grid-cols-2 gap-4">
                <div class="form-group m-0 col-span-2 md:col-span-1 border border-gray-200 bg-white rounded-xl p-3 shadow-sm hover:border-blue-200 transition-colors">
                   <label class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2 block">Category Match</label>
                   <select class="input w-full bg-transparent border-transparent px-0 font-medium text-gray-800 shadow-none focus:border-transparent" v-model="quickForm.item_category_id">
                     <option value="">Map Category Node...</option>
                     <option value="1">Electronics (ELEC)</option>
                     <option value="2">Raw Materials (RAW)</option>
                   </select>
                </div>
                
                <div class="form-group m-0 col-span-2 md:col-span-1 border border-gray-200 bg-white rounded-xl p-3 shadow-sm hover:border-blue-200 transition-colors">
                   <label class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2 block">Physics Class</label>
                   <select class="input w-full bg-transparent border-transparent px-0 font-bold shadow-none focus:border-transparent cursor-pointer" :class="quickForm.item_type === 'goods' ? 'text-gray-900' : 'text-blue-700'" v-model="quickForm.item_type">
                     <option value="goods">Physical Goods</option>
                     <option value="service" class="bg-blue-50">Abstract Service</option>
                   </select>
                </div>
             </div>
          </div>
          
          <!-- Footer -->
          <div class="p-4 px-6 border-t border-gray-100 bg-white flex items-center justify-between">
             <button @click="expandFullForm" class="flex items-center justify-center gap-2 px-4 py-2.5 bg-white border border-gray-300 rounded-lg text-sm font-semibold text-gray-700 hover:bg-gray-50 hover:text-blue-700 transition-all shadow-sm">
               Expand Full Blueprint <Maximize2 :size="14" />
             </button>
             <button @click="saveQuickItem" class="px-6 py-2.5 bg-[#0e52a0] hover:bg-[#0b4284] text-white rounded-lg text-sm font-semibold transition-colors shadow-sm">
               Initialize Item
             </button>
          </div>
        </div>
      </div>

      <!-- Breadcrumb Bar -->
      <div class="breadcrumb-bar flex items-center justify-between mb-4">
        <div class="breadcrumb flex items-center gap-2 text-xs text-gray-500">
          <Monitor :size="14" />
          <ChevronRight :size="12" class="text-gray-300" />
          <span class="text-gray-700 font-medium cursor-pointer hover:text-blue-600" @click="currentView = 'list'">Base Items</span>
          <template v-if="currentView === 'create_full'">
            <ChevronRight :size="12" class="text-gray-300" />
            <span class="text-gray-700 font-medium">Architecture Framework Details</span>
            <span class="badge-warning ml-2">Not Saved</span>
          </template>
        </div>
        <div class="top-actions" v-if="currentView === 'create_full'">
          <button class="btn-primary flex items-center gap-2" @click="currentView = 'list'">
            <CheckCircle :size="14" /> Commit Global Item
          </button>
        </div>
      </div>

      <!-- LIST VIEW -->
      <div v-if="currentView === 'list'">
        <!-- Context Header Layout -->
        <div class="page-container p-6 bg-white rounded-xl shadow-sm border border-gray-200 mb-6 flex gap-4 items-center">
          <div class="p-4 bg-gray-50 text-gray-400 rounded-lg"><Package :size="24" /></div>
          <div class="page-header">
            <h2 class="text-xl font-bold text-gray-900 mb-1">Generic Base Items</h2>
            <p class="text-sm text-gray-500 m-0">Define the fundamental definitions mapping what objects exist materially or philosophically across the domain.</p>
          </div>
        </div>

        <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
          <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between bg-gray-50/50 rounded-t-xl">
            <div class="toolbar-left flex gap-3">
              <div class="search-box">
                <Search :size="16" class="search-icon" />
                <input type="text" placeholder="Search item identifiers..." class="search-input bg-white" />
              </div>
            </div>
            <div class="toolbar-right">
              <!-- Instantly trigger Modal pipeline on creation intent -->
              <button class="btn-primary flex items-center gap-2" @click="showModal = true">
                <Plus :size="14" /> Construct Item Entity
              </button>
            </div>
          </div>

          <div class="table-responsive">
             <table class="w-full text-left text-sm text-gray-700 border-collapse">
               <thead class="text-xs text-gray-500 border-b border-gray-100">
                 <tr>
                   <th class="px-6 py-4 font-semibold">Generic Nomenclature</th>
                   <th class="px-6 py-4 font-semibold">Folder Categorization</th>
                   <th class="px-6 py-4 font-semibold">Physics Type</th>
                   <th class="px-6 py-4 font-semibold">Override Status</th>
                   <th class="px-6 py-4 font-semibold text-right">Settings</th>
                 </tr>
               </thead>
               <tbody>
                 <tr v-for="i in itemsList" :key="i.id" class="border-b border-gray-50 hover:bg-blue-50/20 transition-colors group">
                   <td class="px-6 py-4 font-bold text-gray-900">{{ i.name }}</td>
                   <td class="px-6 py-4 text-gray-500 font-medium">{{ i.category }}</td>
                   <td class="px-6 py-4">
                     <span v-if="i.type === 'Goods'" class="chip font-mono bg-emerald-50 text-emerald-700 border border-emerald-100">Physical Goods</span>
                     <span v-else class="chip-extra font-mono bg-blue-50 text-blue-700 border border-blue-100">Abstract Service</span>
                   </td>
                   <td class="px-6 py-4">
                     <span :class="['badge', i.status === 'Active' ? 'badge-success' : i.status === 'Pending' ? 'badge-warning' : 'badge-danger']">{{ i.status }}</span>
                   </td>
                   <td class="px-6 py-4 text-right">
                     <button class="text-gray-400 hover:text-gray-600 opacity-50 group-hover:opacity-100 transition-opacity"><MoreVertical :size="16" /></button>
                   </td>
                 </tr>
               </tbody>
             </table>
          </div>
        </div>
      </div>

      <!-- FULL EXPANDED BUILDER VIEW -->
      <div v-else class="create-view max-w-5xl mx-auto animate-fade space-y-6">
        
        <!-- Clean minimal UI representation without excessive descriptive noise -->
        <div class="bg-white rounded-xl shadow-md border-t-4 border-t-blue-700 overflow-hidden">
           <div class="p-6 border-b border-gray-100 bg-gray-50/30 flex items-center justify-between">
              <h3 class="text-xl font-bold text-gray-900 flex items-center gap-3"><Package :size="20" class="text-blue-600"/> Foundation Properties</h3>
              <div class="form-group m-0 w-64">
                <select class="input w-full font-bold text-blue-800 bg-blue-50 border-blue-200 cursor-pointer" v-model="fullForm.status">
                  <option value="Pending">Process: Pending QA Check</option>
                  <option value="Active">Process: Active Operational</option>
                  <option value="Deactive">Process: Locked Invalid</option>
                </select>
              </div>
           </div>
           
           <div class="p-8 grid grid-cols-12 gap-8 items-start">
              <div class="col-span-12 md:col-span-8 form-group m-0">
                 <label class="text-xs uppercase font-bold text-gray-400 tracking-wider mb-2 block">Item Nomenclature Parameter</label>
                 <input type="text" class="input w-full text-2xl font-black p-4 border-gray-200 bg-gray-50 focus:bg-white" placeholder="Core System Identity..." v-model="fullForm.name" />
              </div>
              <div class="col-span-12 md:col-span-4 space-y-6 form-group m-0">
                 <div>
                    <label class="text-xs uppercase font-bold text-gray-400 tracking-wider mb-2 block">Logical Tree Attachment</label>
                    <select class="input w-full font-medium" v-model="fullForm.item_category_id">
                      <option value="">Absence of Parent...</option>
                      <option value="1">Electronics Layer</option>
                      <option value="2">Raw Materials</option>
                    </select>
                 </div>
                 <div>
                    <label class="text-xs uppercase font-bold text-gray-400 tracking-wider mb-2 block">Physics Definition</label>
                    <select class="input w-full font-medium" :class="fullForm.item_type === 'goods' ? 'border-emerald-200 text-emerald-800 bg-emerald-50' : 'border-blue-200 text-blue-800 bg-blue-50'" v-model="fullForm.item_type">
                      <option value="goods">Tangible Asset (Goods)</option>
                      <option value="service" class="bg-blue-50">Intangible (Service)</option>
                    </select>
                 </div>
              </div>
           </div>
        </div>

        <!-- Strict Embedded Array Mapping -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
           <div class="p-6 border-b border-gray-100 bg-gray-50/30 flex items-center justify-between">
              <div>
                 <h3 class="text-lg font-bold text-gray-900">Supported System Measurements</h3>
                 <p class="text-sm text-gray-500 m-0">Determine exactly which operational bounds apply mathematically to this object.</p>
              </div>
           </div>
           
           <div class="p-8">
              <div class="grid grid-cols-4 gap-4">
                 <label class="flex items-center gap-3 p-4 border border-blue-200 rounded-xl cursor-pointer hover:bg-blue-50/50 bg-blue-50 relative group transition-colors">
                    <input type="checkbox" checked class="w-4 h-4 text-blue-600 absolute right-4 top-4" />
                    <div class="flex flex-col"><span class="font-bold text-gray-900">Piece Matrix</span><span class="text-xs text-blue-600 font-mono font-medium mt-1">pcs</span></div>
                 </label>
                 
                 <label class="flex items-center gap-3 p-4 border border-gray-200 rounded-xl cursor-pointer hover:border-gray-300 relative transition-colors">
                    <input type="checkbox" class="w-4 h-4 text-gray-400 absolute right-4 top-4" />
                    <div class="flex flex-col"><span class="font-bold text-gray-900">Kilogram Weight</span><span class="text-xs text-gray-500 font-mono font-medium mt-1">kg</span></div>
                 </label>
                 
                 <label class="flex items-center gap-3 p-4 border border-gray-200 rounded-xl cursor-pointer hover:border-gray-300 relative transition-colors">
                    <input type="checkbox" class="w-4 h-4 text-gray-400 absolute right-4 top-4" />
                    <div class="flex flex-col"><span class="font-bold text-gray-900">Liter Volume</span><span class="text-xs text-gray-500 font-mono font-medium mt-1">L</span></div>
                 </label>

                 <label class="flex items-center gap-3 p-4 border border-gray-200 border-dashed rounded-xl cursor-pointer hover:bg-gray-50 bg-gray-50/50 justify-center group transition-colors">
                    <div class="text-sm font-semibold text-gray-400 group-hover:text-blue-600 flex items-center gap-2"><Plus :size="16" /> Missing Rule</div>
                 </label>
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
.chip { padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 500; }
.chip-extra { padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 500; }
.search-box { position: relative; width: 300px; }
.search-input { width: 100%; padding: 8px 12px 8px 36px; border: 1px solid #e5e5e5; border-radius: 6px; font-size: 13px; outline: none; transition: border-color .2s; }
.search-input:focus { border-color: #2563eb; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }
.btn-primary { padding: 8px 16px; background: #0056b3; color: white; border: none; border-radius: 6px; font-size: 13px; font-weight: 500; cursor: pointer; transition: background 0.2s; }
.btn-primary:hover { background: #004494; }
.btn-outline { padding: 8px 16px; border: 1px solid #e5e5e5; background: white; color: #374151; border-radius: 6px; font-size: 13px; font-weight: 500; cursor: pointer; }
.form-group label { display: block; font-size: 12px; font-weight: 600; color: #4b5563; margin-bottom: 6px; }
.input { border: 1px solid #e5e5e5; padding: 10px 12px; border-radius: 8px; font-size: 14px; outline: none; background: white; transition: all 0.2s; }
.input:focus { border-color: #2563eb; box-shadow: 0 0 0 3px rgba(37,99,235, 0.1); }
.animate-fade { animation: fadeIn 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
.animate-spring { animation: springIn 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards; }
@keyframes springIn { from { opacity: 0; transform: scale(0.95) translateY(10px); } to { opacity: 1; transform: scale(1) translateY(0); } }
</style>
