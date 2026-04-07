<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Search, Plus, MoreVertical, CheckCircle, ShieldAlert, AlertTriangle, ArrowDownToLine, ArrowUpToLine, PackageSearch
} from 'lucide-vue-next';

// Shared State
const currentView = ref('list');

const dummyPolicies = ref([
  { id: 1, target: 'Margherita Pizza Base', level: 'Variant', warehouse: 'Main Hub', safety: 50, reorder: 100, max: 1000, state: 'Active' },
  { id: 2, target: 'Raw Produce (All)', level: 'Product', warehouse: 'Downtown ColdStore', safety: 200, reorder: 350, max: 5000, state: 'Active' }
]);

const variants = [{ id: 1, name: 'Margherita Pizza Base' }, { id: 2, name: 'Standard Dough' }];
const products = [{ id: 1, name: 'Raw Produce (All)' }, { id: 2, name: 'Beverages' }];
const warehouses = [{ id: 1, name: 'Main Hub' }, { id: 2, name: 'Downtown ColdStore' }];

const form = ref({
  targetType: 'variant', // 'variant' or 'product'
  product_variant_id: '',
  product_id: '',
  warehouse_id: '',
  
  reorder_level: '',
  reorder_quantity: '',
  min_order_quantity: '',
  minimum_stock_level: '',
  maximum_stock_level: '',
  safety_stock: '',
  lead_time_days: '',
  state: true
});

</script>

<template>
  <DashboardLayout>
    <div class="org-layout relative">

      <!-- Breadcrumbs -->
      <div class="breadcrumb-bar flex items-center justify-between mb-4">
        <div class="breadcrumb flex items-center gap-2 text-xs text-gray-500">
          <Monitor :size="14" />
          <ChevronRight :size="12" class="text-gray-300" />
          <span class="text-gray-700 font-medium cursor-pointer hover:text-red-600" @click="currentView = 'list'">Procurement Settings</span>
          <template v-if="currentView === 'create'">
            <ChevronRight :size="12" class="text-gray-300" />
            <span class="text-gray-700 font-medium">Define Hard Limits</span>
            <span class="badge-warning ml-2">Not Saved</span>
          </template>
        </div>
        <div class="top-actions" v-if="currentView === 'create'">
          <button class="btn-primary flex items-center gap-2 text-sm px-6 py-2 bg-red-600 font-bold shadow-md hover:bg-red-700" @click="currentView = 'list'">
            <CheckCircle :size="16" /> Commit Policy
          </button>
        </div>
      </div>

      <!-- LIST VIEW -->
      <div v-if="currentView === 'list'">
        <div class="page-container p-6 bg-white rounded-xl shadow-sm border border-gray-200 mb-6 flex gap-4 items-center">
          <div class="p-4 bg-red-50 text-red-600 rounded-lg drop-shadow-sm"><ShieldAlert :size="28" /></div>
          <div class="page-header">
             <h2 class="text-2xl font-black text-gray-900 mb-1 tracking-tight">Inventory Procurement Policies</h2>
             <p class="text-sm text-gray-500 m-0">Define hard mathematical constraints managing safe thresholds, reorder autonomy limits, and exact supplier lead metrics.</p>
          </div>
        </div>

        <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
          <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between bg-gray-50/50">
            <div class="search-box">
               <Search :size="16" class="search-icon" />
               <input type="text" placeholder="Search targets..." class="search-input bg-white" />
            </div>
            <button class="btn-primary bg-red-600 hover:bg-red-700 flex items-center gap-2 px-5 py-2.5 font-bold shadow-sm" @click="currentView = 'create'">
               <Plus :size="16" /> Add Boundary Guard
            </button>
          </div>
          
          <table class="w-full text-left text-sm text-gray-700 border-collapse">
            <thead class="text-xs text-gray-500 border-b border-gray-100">
              <tr>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider">Policy Target Base</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider">Isolation Bound</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider text-center bg-red-50/50" title="Safety Minimums">Guard Floor</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider text-center" title="Reorder Trigger">Reorder Mark</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider text-center bg-blue-50/50" title="Maximum Capacity">Ceiling Limit</th>
                <th class="px-6 py-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="p in dummyPolicies" :key="p.id" class="border-b border-gray-50 hover:bg-red-50/20 transition-colors group">
                <td class="px-6 py-4">
                   <div class="font-bold text-gray-900 text-sm mb-1">{{ p.target }}</div>
                   <div class="font-mono text-[10px] text-gray-500 bg-gray-100 inline-block px-2 py-0.5 rounded tracking-widest">{{ p.level }} Level</div>
                </td>
                <td class="px-6 py-4 font-semibold text-gray-600">{{ p.warehouse }}</td>
                <td class="px-6 py-4 text-center font-mono font-bold text-red-600 bg-red-50/20">{{ p.safety }}</td>
                <td class="px-6 py-4 text-center font-mono font-bold text-gray-900 border-x border-gray-50">{{ p.reorder }}</td>
                <td class="px-6 py-4 text-center font-mono font-bold text-blue-600 bg-blue-50/20">{{ p.max }}</td>
                <td class="px-6 py-4 text-right">
                  <button class="text-gray-400 hover:text-gray-800 opacity-50 group-hover:opacity-100"><MoreVertical :size="16" /></button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- CREATE FORM -->
      <div v-else class="create-view max-w-5xl mx-auto space-y-6">
        
        <div class="bg-white rounded-xl shadow-md border-t-4 border-t-red-600 overflow-hidden">
           <div class="p-6 border-b border-gray-100 bg-gray-50/50 flex items-center justify-between">
              <div>
                <h3 class="font-black text-xl text-gray-900 drop-shadow-sm flex items-center gap-2"><PackageSearch class="text-red-500" :size="20"/> Target Identification Boundary</h3>
                <p class="text-sm font-semibold text-gray-500 mb-0">What literal object (or entire global product line) does this limit apply to?</p>
              </div>
              <div class="flex items-center justify-between p-3 border border-gray-200 rounded-lg bg-white shadow-sm gap-4">
                 <span class="text-xs font-bold text-gray-800 uppercase tracking-widest">Policy Active Guard</span>
                 <label class="toggle-switch transform scale-100"><input type="checkbox" v-model="form.state"><span class="slider bg-red-500 peer-checked:bg-red-500 text-white before:bg-white"></span></label>
              </div>
           </div>
           
           <div class="p-8 pb-10 grid grid-cols-2 gap-8">
              <div class="form-group m-0 col-span-2 flex gap-4 p-4 border border-red-100 bg-red-50 rounded-xl">
                 <label :class="['flex-1 p-3 border rounded text-center cursor-pointer font-bold font-mono transition-colors', form.targetType === 'variant' ? 'bg-red-600 text-white shadow-md border-red-600' : 'bg-white border-red-200 text-red-600']">
                    <input type="radio" v-model="form.targetType" value="variant" class="hidden"> ISOLATED VARIANT EXPLICIT
                 </label>
                 <label :class="['flex-1 p-3 border rounded text-center cursor-pointer font-bold font-mono transition-colors', form.targetType === 'product' ? 'bg-red-600 text-white shadow-md border-red-600' : 'bg-white border-red-200 text-red-600']">
                    <input type="radio" v-model="form.targetType" value="product" class="hidden"> ENTIRE BASE PRODUCT GLOBALLY
                 </label>
              </div>

              <div class="form-group m-0 col-span-1">
                 <label class="text-xs font-black uppercase tracking-widest text-gray-400 block mb-2">{{ form.targetType === 'variant' ? 'Target Specific Variant Node' : 'Target Entire Product Umbrella' }}</label>
                 <select class="input w-full font-bold text-lg p-3 shadow-sm border-gray-200 focus:border-red-500" v-if="form.targetType === 'variant'" v-model="form.product_variant_id">
                    <option value="">Select Variant...</option>
                    <option v-for="v in variants" :key="v.id" :value="v.id">{{ v.name }}</option>
                 </select>
                 <select class="input w-full font-bold text-lg p-3 shadow-sm border-gray-200 focus:border-red-500" v-else v-model="form.product_id">
                    <option value="">Select Global Product...</option>
                    <option v-for="p in products" :key="p.id" :value="p.id">{{ p.name }}</option>
                 </select>
              </div>

              <div class="form-group m-0 col-span-1 border-l pl-8 border-gray-100">
                 <label class="text-xs font-black uppercase tracking-widest text-gray-400 block mb-2">Location Isolation (Optional)</label>
                 <select class="input w-full font-medium p-3 shadow-sm border-gray-200 focus:border-red-500" v-model="form.warehouse_id">
                    <option value="">Map Generic / All Warehouses Globally</option>
                    <option v-for="w in warehouses" :key="w.id" :value="w.id">Isolate to {{ w.name }}</option>
                 </select>
              </div>
           </div>
        </div>

        <!-- Procurement Guard Grid -->
        <div class="bg-white rounded-xl shadow-md border-t-4 border-t-gray-800 overflow-hidden">
           <div class="p-6 border-b border-gray-100 flex items-center justify-between">
              <div>
                <h3 class="font-black text-xl text-gray-900 drop-shadow-sm flex items-center gap-2"><ArrowDownToLine class="text-gray-800" :size="20"/> Mathematical Triggers & Blocks</h3>
                <p class="text-sm font-semibold text-gray-500 mb-0">What explicit integer limits define safety vs overflow?</p>
              </div>
           </div>
           
           <div class="p-8 grid grid-cols-3 gap-6 bg-gray-50/50">
              
              <div class="col-span-1 form-group m-0 bg-red-50 p-4 border border-red-200 rounded-xl relative overflow-hidden">
                 <AlertTriangle class="absolute right-2 top-2 text-red-200 opacity-50" :size="48"/>
                 <label class="text-xs uppercase font-bold text-red-900 relative z-10 block mb-2">Absolute Minimum Level</label>
                 <span class="text-[10px] text-red-700 leading-tight block mb-3 relative z-10">Lowest allowed inventory before the system completely blocks operations entirely.</span>
                 <input type="number" class="input w-full font-mono font-black text-2xl text-center shadow-inner relative z-10 focus:border-red-500 border-red-300" v-model="form.minimum_stock_level" />
              </div>

              <div class="col-span-1 form-group m-0 bg-orange-50 p-4 border border-orange-200 rounded-xl">
                 <label class="text-xs uppercase font-bold text-orange-900 block mb-2">Safety Buffer Stock</label>
                 <span class="text-[10px] text-orange-700 leading-tight block mb-3">Extra stock deliberately reserved to protect strictly against emergency operations.</span>
                 <input type="number" class="input w-full font-mono font-black text-2xl text-center shadow-inner focus:border-orange-500 border-orange-300" v-model="form.safety_stock" />
              </div>

              <div class="col-span-1 form-group m-0 bg-blue-50 p-4 border border-blue-200 rounded-xl relative overflow-hidden">
                 <ArrowUpToLine class="absolute right-2 top-2 text-blue-200 opacity-50" :size="48"/>
                 <label class="text-xs uppercase font-bold text-blue-900 block relative z-10 mb-2">Maximum Capacity Limit</label>
                 <span class="text-[10px] text-blue-700 leading-tight block mb-3 relative z-10">Absolute physical or systemic warehouse storage capacity limit ceiling.</span>
                 <input type="number" class="input w-full font-mono font-black text-2xl text-center shadow-inner relative z-10 focus:border-blue-500 border-blue-300" v-model="form.maximum_stock_level" />
              </div>

           </div>
           
           <div class="p-8 grid grid-cols-4 gap-6 border-t border-gray-100 bg-white">
              <div class="form-group m-0 col-span-1">
                 <label class="text-[10px] font-black uppercase text-gray-500">Trigger Alert At</label>
                 <input type="number" class="input w-full font-mono font-bold bg-gray-50 text-center" placeholder="Reorder Level" v-model="form.reorder_level" />
              </div>
              <div class="form-group m-0 col-span-1">
                 <label class="text-[10px] font-black uppercase text-gray-500">Autonomous Buy QTY</label>
                 <input type="number" class="input w-full font-mono font-bold bg-gray-50 text-center" placeholder="Reorder Target" v-model="form.reorder_quantity" />
              </div>
              <div class="form-group m-0 col-span-1">
                 <label class="text-[10px] font-black uppercase text-gray-500">Vendor Minimum Sub (Block)</label>
                 <input type="number" class="input w-full font-mono font-bold bg-gray-50 text-center" placeholder="Min Order" v-model="form.min_order_quantity" />
              </div>
              <div class="form-group m-0 col-span-1">
                 <label class="text-[10px] font-black uppercase text-gray-500">Supplier Transport Expected</label>
                 <div class="relative">
                    <input type="number" class="input w-full font-mono font-bold bg-gray-50 text-center" placeholder="Days" v-model="form.lead_time_days" />
                    <span class="absolute right-3 top-[10px] text-xs font-bold text-gray-400 pointer-events-none">Days</span>
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
.search-box { position: relative; width: 300px; }
.search-input { width: 100%; padding: 8px 12px 8px 36px; border: 1px solid #e5e5e5; border-radius: 6px; font-size: 13px; outline: none; transition: border-color .2s; }
.search-input:focus { border-color: #dc2626; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }
.btn-primary { border: none; border-radius: 8px; cursor: pointer; transition: background 0.2s; }
.form-group label { display: block; font-size: 12px; font-weight: 600; color: #4b5563; margin-bottom: 6px; }
.input { border: 1px solid #e5e5e5; padding: 10px 12px; border-radius: 8px; font-size: 14px; outline: none; background: white; transition: all 0.2s; }
.input:focus { box-shadow: 0 0 0 3px rgba(220, 38, 38, 0.1); }
.toggle-switch { position: relative; display: inline-block; width: 44px; height: 24px; }
.toggle-switch input { opacity: 0; width: 0; height: 0; }
.slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #d1d5db; transition: .3s cubic-bezier(0.4, 0, 0.2, 1); border-radius: 34px; }
.slider:before { position: absolute; content: ""; height: 18px; width: 18px; left: 3px; bottom: 3px; background-color: white; transition: .3s cubic-bezier(0.4, 0, 0.2, 1); border-radius: 50%; box-shadow: 0 2px 4px rgba(0,0,0,0.2); }
input:checked + .slider { background-color: #ef4444; }
input:checked + .slider:before { transform: translateX(20px); }
.animate-fade { animation: fadeIn 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
</style>
