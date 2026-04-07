<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Search, Plus, MoreVertical, CheckCircle, PackageSearch, SplitSquareHorizontal, Store, Factory, Tag, ClipboardList
} from 'lucide-vue-next';

// Data Arrays
const variantsList = ref([
  { id: 1, name: 'Margherita Pizza - Large', sku: 'PZ-MARG-LG', brand: 'House', group: 'Pizza', track_stock: true, is_locally_produced: true, state: 'Active' },
  { id: 2, name: 'Coca Cola 330ml Can', sku: 'BEV-COK-330', brand: 'Coca Cola', group: 'Beverages', track_stock: true, is_locally_produced: false, state: 'Active' }
]);

// Tabs & State
const currentView = ref('list');
const activeFormTab = ref('core'); 
// Form tabs: 'core' (Base Info), 'attribute' (Option Linkage), 'pos' (Hospitality vs Retail rules)

const form = ref({
  sku: '',
  barcode: '',
  product_id: '',
  brand_id: '',
  entity_id: '',
  measurement_id: '',
  product_group_id: '',
  
  // POS Specific Toggles
  has_ingredient: false,
  is_locally_produced: false,
  is_tax_included: false,
  
  // Tracking Rules
  track_stock: false,
  track_batch: false,
  track_expiry: false,
  is_transferable: true,
  costing_rule: '',
  state: true,
  
  // Attributes Linkage (e.g. Size -> Large)
  attributes: [
    { attribute_id: '', value_id: '' }
  ]
});

// Mock Dropdown data
const products = [{ id: '1', name: 'Margherita Pizza' }, { id: '2', name: 'Coca Cola' }];
const brands = [{ id: '1', name: 'House' }, { id: '2', name: 'Coca Cola' }];
const entities = [{ id: '1', name: 'Main HQ' }, { id: '2', name: 'Downtown Branch' }];
const groups = [{ id: '1', name: 'Pizza' }, { id: '2', name: 'Beverages' }];
const measurements = [{ id: '1', name: 'Pieces (pcs)' }, { id: '2', name: 'Liters (L)' }];

// Options logic
const addAttributeRow = () => form.value.attributes.push({ attribute_id: '', value_id: '' });
</script>

<template>
  <DashboardLayout>
    <div class="org-layout relative">

      <!-- Breadcrumbs -->
      <div class="breadcrumb-bar flex items-center justify-between mb-4">
        <div class="breadcrumb flex items-center gap-2 text-xs text-gray-500">
          <Monitor :size="14" />
          <ChevronRight :size="12" class="text-gray-300" />
          <span class="text-gray-700 font-medium cursor-pointer hover:text-blue-600" @click="currentView = 'list'">Product Variations</span>
          
          <template v-if="currentView === 'create'">
            <ChevronRight :size="12" class="text-gray-300" />
            <span class="text-gray-700 font-medium">Configure Physical Object</span>
            <span class="badge-warning ml-2">Design Mode</span>
          </template>
        </div>
        
        <div class="top-actions" v-if="currentView === 'create'">
          <button class="btn-primary flex items-center gap-2 text-sm px-6 py-2 bg-blue-700 font-bold shadow-md hover:bg-blue-800" @click="currentView = 'list'">
            <CheckCircle :size="16" /> Commit POS Object
          </button>
        </div>
      </div>

      <!-- LIST VIEW -->
      <div v-if="currentView === 'list'">
        <!-- Hero Header -->
        <div class="page-container p-6 bg-white rounded-xl shadow-sm border border-gray-200 mb-6 flex gap-4 items-center">
          <div class="p-4 bg-blue-50 text-blue-600 rounded-lg drop-shadow-sm"><SplitSquareHorizontal :size="28" /></div>
          <div class="page-header">
             <h2 class="text-2xl font-black text-gray-900 mb-1 tracking-tight">Sellable End-Points (Variants)</h2>
             <p class="text-sm text-gray-500 m-0">The actual physical or logical items tracked in stock, produced locally via ingredients, or sold via barcode in POS.</p>
          </div>
        </div>

        <!-- Table Core -->
        <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
          <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between">
            <div class="search-box">
               <Search :size="16" class="search-icon" />
               <input type="text" placeholder="Search SKU, Barcode, Name..." class="search-input bg-gray-50/50 hover:bg-white transition-colors" />
            </div>
            <button class="btn-primary flex items-center gap-2 px-5 py-2.5 font-bold shadow-sm" @click="currentView = 'create'">
               <Plus :size="16" /> Compile Variant Entity
            </button>
          </div>
          
          <table class="w-full text-left text-sm text-gray-700 border-collapse">
            <thead class="text-xs text-gray-500 border-b border-gray-100 bg-gray-50/30">
              <tr>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider">Internal Reference</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider">Parent Logic</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider text-center">POS Matrix Properties</th>
                 <th class="px-6 py-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="v in variantsList" :key="v.id" class="border-b border-gray-50 hover:bg-gray-50 transition-colors">
                <td class="px-6 py-4">
                   <div class="font-bold text-gray-900 text-base mb-1">{{ v.name }}</div>
                   <div class="font-mono text-[10px] text-gray-500 bg-gray-100 inline-block px-2 py-0.5 rounded uppercase font-bold tracking-widest border border-gray-200">SKU: {{ v.sku }}</div>
                </td>
                <td class="px-6 py-4">
                  <div class="text-sm font-semibold text-gray-700">{{ v.group }}</div>
                  <div class="text-xs text-gray-400 font-medium">Brand: {{ v.brand }}</div>
                </td>
                <td class="px-6 py-4 text-center">
                   <div class="flex items-center justify-center gap-2">
                     <span v-if="v.track_stock" title="Inventory Tracked" class="p-1.5 rounded-md bg-blue-50 text-blue-600 border border-blue-100"><Store :size="14" /></span>
                     <span v-if="v.is_locally_produced" title="Requires Recipe Pipeline" class="p-1.5 rounded-md bg-orange-50 text-orange-600 border border-orange-100"><Factory :size="14" /></span>
                   </div>
                </td>
                <td class="px-6 py-4 text-right">
                  <button class="text-gray-400 hover:text-gray-800"><MoreVertical :size="16" /></button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- MASSIVE CREATE VIEW -->
      <div v-else class="create-view max-w-6xl mx-auto flex gap-8">
        
        <!-- Sticky Sidebar Navigation within the Form -->
        <div class="w-64 flex-shrink-0">
           <div class="sticky top-6 flex flex-col gap-2">
              <button @click="activeFormTab = 'core'" :class="['w-full text-left px-4 py-3 rounded-lg font-bold text-sm flex items-center gap-3 transition-colors', activeFormTab === 'core' ? 'bg-blue-600 text-white shadow-md' : 'text-gray-600 hover:bg-gray-100']">
                 <PackageSearch :size="18" /> Core Identity
              </button>
              <button @click="activeFormTab = 'attribute'" :class="['w-full text-left px-4 py-3 rounded-lg font-bold text-sm flex items-center gap-3 transition-colors', activeFormTab === 'attribute' ? 'bg-blue-600 text-white shadow-md' : 'text-gray-600 hover:bg-gray-100']">
                 <Tag :size="18" /> Configurable Options
              </button>
              <button @click="activeFormTab = 'pos'" :class="['w-full text-left px-4 py-3 rounded-lg font-bold text-sm flex items-center gap-3 transition-colors', activeFormTab === 'pos' ? 'bg-orange-500 text-white shadow-md' : 'text-gray-600 hover:bg-gray-100']">
                 <Store :size="18" /> POS Hospitality Overrides
              </button>
              <button @click="activeFormTab = 'inventory'" :class="['w-full text-left px-4 py-3 rounded-lg font-bold text-sm flex items-center gap-3 transition-colors', activeFormTab === 'inventory' ? 'bg-emerald-600 text-white shadow-md' : 'text-gray-600 hover:bg-gray-100']">
                 <ClipboardList :size="18" /> Physical Tracking Rules
              </button>
           </div>
        </div>

        <!-- Form Context Area -->
        <div class="flex-1 space-y-6 pb-24">
           
           <!-- TAB 1: CORE IDENTITY -->
           <div v-if="activeFormTab === 'core'" class="animate-fade">
              <h2 class="text-2xl font-black text-gray-900 mb-6 drop-shadow-sm">System Identifier Definitions</h2>
              
              <div class="bg-white p-8 rounded-xl shadow-sm border border-gray-200">
                 <div class="grid grid-cols-2 gap-8">
                    <div class="form-group m-0 col-span-2">
                      <label class="text-xs uppercase tracking-wider font-bold text-gray-500 mb-2">Foreign Key Dependencies</label>
                      <div class="grid grid-cols-3 gap-4">
                        <select class="input bg-gray-50/50" v-model="form.product_id">
                          <option value="">Base Product Target...</option>
                          <option v-for="p in products" :key="p.id" :value="p.id">{{ p.name }}</option>
                        </select>
                        <select class="input bg-gray-50/50" v-model="form.brand_id">
                          <option value="">Attach Brand Origin...</option>
                          <option v-for="b in brands" :key="b.id" :value="b.id">{{ b.name }}</option>
                        </select>
                        <select class="input bg-gray-50/50" v-model="form.measurement_id">
                          <option value="">Base Inventory Unit...</option>
                          <option v-for="m in measurements" :key="m.id" :value="m.id">{{ m.name }}</option>
                        </select>
                      </div>
                    </div>
                    
                    <div class="form-group m-0 col-span-1">
                       <label class="text-xs uppercase tracking-wider font-bold text-gray-500 mb-2">SKU Logic (TSRM)</label>
                       <input type="text" class="input w-full font-mono text-xl font-bold p-3" v-model="form.sku" placeholder="E.g. PIZZA-LG" />
                    </div>
                    
                    <div class="form-group m-0 col-span-1">
                       <label class="text-xs uppercase tracking-wider font-bold text-gray-500 mb-2">Scanned Barcode</label>
                       <div class="relative">
                         <Search class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" :size="16" />
                         <input type="text" class="input w-full font-mono font-bold p-3 pl-10" v-model="form.barcode" placeholder="94819482..." />
                       </div>
                    </div>
                 </div>
              </div>
           </div>

           <!-- TAB 2: ATTRIBUTE LINKAGE -->
           <div v-if="activeFormTab === 'attribute'" class="animate-fade">
              <h2 class="text-2xl font-black text-gray-900 mb-6 drop-shadow-sm">Parameter Bindings</h2>
              
              <div class="bg-indigo-50 border border-indigo-100 p-8 rounded-xl relative overflow-hidden shadow-inner">
                 <div class="absolute right-0 top-0 w-32 h-32 bg-indigo-500 opacity-5 rounded-full -translate-y-1/2 translate-x-1/2"></div>
                 
                 <p class="text-sm font-semibold text-indigo-900 pb-4 mb-4 border-b border-indigo-200/50">Does this specific variant exist as a unique parameter? E.g. If Parent is "Jacket", link this specific Variant to "Size: X-Large" and "Color: Red".</p>
                 
                 <div class="space-y-4 relative z-10">
                    <div v-for="(attr, idx) in form.attributes" :key="idx" class="flex items-center gap-4 bg-white p-3 border border-indigo-200 shadow-sm rounded-lg">
                       <div class="bg-indigo-500 text-white font-bold px-3 py-1 rounded text-sm">SET</div>
                       <select class="input flex-1 border-transparent focus:border-indigo-400 focus:bg-indigo-50 transition-colors bg-gray-50" v-model="attr.attribute_id">
                         <option value="">Choose Attribute Master...</option>
                         <option value="1">Size</option>
                         <option value="2">Color</option>
                       </select>
                       <span class="text-lg font-bold text-indigo-300">➜</span>
                       <select class="input flex-1 border-transparent focus:border-indigo-400 focus:bg-indigo-50 transition-colors bg-gray-50" v-model="attr.value_id">
                         <option value="">Link Exact Value Variant...</option>
                         <option value="1">Small</option>
                         <option value="2">Large</option>
                         <option value="3">Red Config</option>
                       </select>
                    </div>
                    
                    <button @click="addAttributeRow" class="text-sm font-bold text-indigo-700 bg-white border border-indigo-200 px-4 py-2 rounded-lg shadow-sm hover:bg-indigo-50 flex items-center gap-2">
                       <Plus :size="14" /> Declare Parameter Binding
                    </button>
                 </div>
              </div>
           </div>

           <!-- TAB 3: POS HOSPITALITY (ORANGE) -->
           <div v-if="activeFormTab === 'pos'" class="animate-fade">
              <h2 class="text-2xl font-black text-gray-900 mb-6 drop-shadow-sm">Hospitality & Culinary Engine</h2>
              
              <div class="grid grid-cols-2 gap-6">
                 <!-- Ingredient Logic -->
                 <div class="bg-white p-6 border-2 border-orange-100 rounded-xl shadow-sm hover:border-orange-300 transition-colors flex flex-col justify-between">
                    <div>
                       <div class="flex items-center gap-3 mb-2"><Factory class="text-orange-500" :size="24" /><h3 class="text-lg font-bold text-gray-900">Locally Produced</h3></div>
                       <p class="text-xs font-semibold text-gray-500 mb-6">Does this item exist mathematically only as a construct of other ingredients within the establishment? (E.g. A Hamburger).</p>
                    </div>
                    <label class="toggle-switch transform scale-125 self-start"><input type="checkbox" v-model="form.is_locally_produced"><span class="slider bg-orange-400 before:bg-white peer-checked:bg-orange-500"></span></label>
                 </div>
                 
                 <div class="bg-white p-6 border-2 border-orange-100 rounded-xl shadow-sm hover:border-orange-300 transition-colors flex flex-col justify-between">
                    <div>
                       <div class="flex items-center gap-3 mb-2"><Store class="text-orange-500" :size="24" /><h3 class="text-lg font-bold text-gray-900">Constituent Ingredients</h3></div>
                       <p class="text-xs font-semibold text-gray-500 mb-6">Does this physical item act as a raw material consumed by the Culinary Engine during other productions?</p>
                    </div>
                    <label class="toggle-switch transform scale-125 self-start"><input type="checkbox" v-model="form.has_ingredient"><span class="slider bg-orange-400 before:bg-white peer-checked:bg-orange-500"></span></label>
                 </div>

                 <!-- Tax Matrix -->
                 <div class="bg-white p-6 border border-gray-200 rounded-xl shadow-sm col-span-2 flex items-center justify-between">
                    <div>
                        <h3 class="font-bold text-gray-900 text-base">POS Display Tax Included</h3>
                        <p class="text-xs text-gray-500">Render pricing globally including base tax constants natively.</p>
                    </div>
                    <label class="toggle-switch transform scale-110"><input type="checkbox" v-model="form.is_tax_included"><span class="slider"></span></label>
                 </div>
              </div>
           </div>

           <!-- TAB 4: INVENTORY TRACKING (EMERALD) -->
           <div v-if="activeFormTab === 'inventory'" class="animate-fade">
              <h2 class="text-2xl font-black text-gray-900 mb-6 drop-shadow-sm">Physical Warehouse Constraints</h2>
              
              <div class="bg-white border text-emerald-900 border-emerald-200 p-8 rounded-xl shadow-sm space-y-6 relative overflow-hidden">
                 <!-- BG ACCENT -->
                 <div class="absolute -right-10 -top-10 w-48 h-48 bg-emerald-50 rounded-full z-0 opacity-50 blur-xl"></div>
                 
                 <div class="relative z-10 flex items-center justify-between pb-6 border-b border-gray-100">
                    <div class="pr-12">
                        <h3 class="font-bold text-lg">Continuous Stock Tracking</h3>
                        <p class="text-xs font-semibold text-emerald-700/60 mt-1">Should the base inventory engine explicitly track quantities of this object over time?</p>
                    </div>
                    <label class="toggle-switch transform scale-125 flex-shrink-0"><input type="checkbox" v-model="form.track_stock"><span class="slider bg-emerald-500 peer-checked:bg-emerald-600 text-white before:bg-white"></span></label>
                 </div>

                 <div class="relative z-10 flex items-center justify-between pb-6 border-b border-gray-100">
                    <div class="pr-12">
                        <h3 class="font-bold text-lg">Batch & Lot Governance</h3>
                        <p class="text-xs font-semibold text-emerald-700/60 mt-1">Is this object delivered in explicit batches requiring identical tracking logic natively?</p>
                    </div>
                    <label class="toggle-switch transform scale-125 flex-shrink-0"><input type="checkbox" v-model="form.track_batch"><span class="slider bg-emerald-500 peer-checked:bg-emerald-600 text-white before:bg-white"></span></label>
                 </div>

                 <div class="relative z-10 flex items-center justify-between pb-6 border-b border-gray-100">
                    <div class="pr-12">
                        <h3 class="font-bold text-lg">Hard Expiry Chronology</h3>
                        <p class="text-xs font-semibold text-emerald-700/60 mt-1">Enforce date dependencies to prevent POS sales of dangerous or void assets autonomously.</p>
                    </div>
                    <label class="toggle-switch transform scale-125 flex-shrink-0"><input type="checkbox" v-model="form.track_expiry"><span class="slider bg-emerald-500 peer-checked:bg-emerald-600 text-white before:bg-white"></span></label>
                 </div>

                 <div class="relative z-10 grid grid-cols-2 gap-4 pt-4">
                    <div class="form-group m-0 bg-white p-4 rounded-xl border border-gray-200">
                       <label class="text-xs uppercase tracking-wider font-bold text-gray-500">Costing Abstraction Rule</label>
                       <select class="input w-full mt-2 font-bold bg-gray-50 shadow-none border-transparent text-gray-700 focus:bg-white focus:border-emerald-300" v-model="form.costing_rule">
                          <option value="">Default FIFO Model</option>
                          <option value="fifo">Strict FIFO (First In First Out)</option>
                          <option value="lifo">LIFO (Last In First Out)</option>
                          <option value="weighted">Weighted Moving Average</option>
                       </select>
                    </div>
                    <div class="flex items-center justify-between bg-white p-4 rounded-xl border border-gray-200">
                       <div>
                          <div class="font-bold text-sm text-gray-900">Transferable Matrix</div>
                          <div class="text-[10px] text-gray-400 uppercase tracking-widest font-bold mt-1">Between Warehouses</div>
                       </div>
                       <label class="toggle-switch transform"><input type="checkbox" v-model="form.is_transferable"><span class="slider"></span></label>
                    </div>
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
.search-input:focus { border-color: #2563eb; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }
.btn-primary { border: none; border-radius: 8px; cursor: pointer; transition: background 0.2s; }
.form-group label { display: block; font-size: 12px; font-weight: 600; color: #4b5563; margin-bottom: 6px; }
.input { border: 1px solid #e5e5e5; padding: 10px 12px; border-radius: 8px; font-size: 14px; outline: none; background: white; transition: all 0.2s; }
.input:focus { border-color: #2563eb; box-shadow: 0 0 0 3px rgba(37,99,235, 0.1); }
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
