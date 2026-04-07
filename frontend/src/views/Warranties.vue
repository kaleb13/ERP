<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Search, Plus, MoreVertical, CheckCircle, ShieldCheck, FileText, PackageCheck, CalendarDays, KeyRound
} from 'lucide-vue-next';

// State
const activeTab = ref('types'); // 'types', 'assignments', 'instances'
const currentView = ref('list'); // 'list', 'create_type', 'create_assignment'

// Dummy Data
const warrantyTypes = ref([
  { id: 1, name: 'Standard 1-Year Hardware', description: 'Base coverage for mechanical failure of internal components.', entity: 'Main HQ', state: 'Active' },
  { id: 2, name: 'Premium 3-Year Zero-Fault', description: 'Complete replacement regardless of fault logic.', entity: 'System Global', state: 'Active' }
]);

const assignments = ref([
  { id: 1, target: 'Coffee Machine v4', level: 'Variant Target', type_name: 'Standard 1-Year Hardware', days: 365, state: 'Active' }
]);

const activeInstances = ref([
  { id: 1, variant: 'Coffee Machine v4', serial: 'CM4-9981-002', start: '2025-10-01', end: '2026-10-01', state: 'Active' }
]);

const variants = [{ id: 1, name: 'Coffee Machine v4' }, { id: 2, name: 'POS Register Screen' }];
const products = [{ id: 1, name: 'Coffee Machines (All Models)' }, { id: 2, name: 'Kitchen Hardware' }];

// Forms
const formType = ref({ name: '', description: '', state: true });
const formAssignment = ref({
  targetLevel: 'variant',
  product_variant_id: '',
  product_id: '',
  warranty_type_id: '',
  days: 365
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
          <span class="text-gray-700 font-medium cursor-pointer hover:text-emerald-600" @click="currentView = 'list'">Warranty & Protection</span>
          
          <template v-if="currentView === 'create_type'">
            <ChevronRight :size="12" class="text-gray-300" />
            <span class="text-gray-700 font-medium">Construct Policy Legal</span>
          </template>
          <template v-else-if="currentView === 'create_assignment'">
            <ChevronRight :size="12" class="text-gray-300" />
            <span class="text-gray-700 font-medium">Attach Automatic Rule</span>
          </template>
        </div>
        
        <div class="top-actions" v-if="currentView !== 'list'">
          <button class="btn-primary flex items-center gap-2 text-sm px-6 py-2 bg-emerald-700 font-bold shadow-md hover:bg-emerald-800" @click="currentView = 'list'">
            <CheckCircle :size="16" /> Commit Record
          </button>
        </div>
      </div>

      <!-- LIST VIEW -->
      <div v-if="currentView === 'list'">
        
        <div class="page-container p-6 bg-white rounded-xl shadow-sm border border-gray-200 mb-6 flex gap-4 items-center">
          <div class="p-4 bg-emerald-50 text-emerald-600 rounded-lg drop-shadow-sm"><ShieldCheck :size="28" /></div>
          <div class="page-header">
             <h2 class="text-2xl font-black text-gray-900 mb-1 tracking-tight">Legal Protection Matrix</h2>
             <p class="text-sm text-gray-500 m-0">Define abstract Warranty legal policies, map them automatically to hardware classes, and track active lifecycle claims.</p>
          </div>
        </div>

        <!-- Seg Tabs -->
        <div class="flex gap-2 mb-6">
          <button :class="['seg-tab', { 'active': activeTab === 'types' }]" @click="activeTab = 'types'"><FileText :size="16" /> Base Definitions</button>
          <button :class="['seg-tab', { 'active': activeTab === 'assignments' }]" @click="activeTab = 'assignments'"><PackageCheck :size="16" /> Product Linkage Engine</button>
          <button :class="['seg-tab', { 'active': activeTab === 'instances' }]" @click="activeTab = 'instances'"><CalendarDays :size="16" /> Active Bound Instances</button>
        </div>

        <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
          <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between bg-gray-50/50">
            <div class="search-box">
               <Search :size="16" class="search-icon" />
               <input type="text" placeholder="Search systems..." class="search-input bg-white focus:border-emerald-500" />
            </div>
            
            <button v-if="activeTab === 'types'" class="btn-primary bg-emerald-600 hover:bg-emerald-700 flex items-center gap-2 font-bold shadow-sm" @click="currentView = 'create_type'">
               <Plus :size="16" /> Draft Warranty Type
            </button>
            <button v-else-if="activeTab === 'assignments'" class="btn-primary bg-emerald-600 hover:bg-emerald-700 flex items-center gap-2 font-bold shadow-sm" @click="currentView = 'create_assignment'">
               <Plus :size="16" /> Bind New Logic Assignment
            </button>
            <div v-else class="text-xs font-bold text-gray-400 uppercase tracking-widest"><KeyRound :size="14" class="inline mb-0.5 text-orange-400" /> Auto-Generated via POS Engine</div>
          </div>
          
          <!-- TYPES TABLE -->
          <table v-if="activeTab === 'types'" class="w-full text-left text-sm text-gray-700 border-collapse">
            <thead class="text-xs text-gray-500 border-b border-gray-100">
              <tr>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider">Universal Legal Title</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider">Description Payload</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider w-32">Status</th>
                 <th class="px-6 py-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="t in warrantyTypes" :key="t.id" class="border-b border-gray-50 hover:bg-emerald-50/30 transition-colors group">
                <td class="px-6 py-4">
                   <div class="font-bold text-gray-900 text-base mb-1">{{ t.name }}</div>
                   <div class="font-mono text-[10px] text-gray-500 bg-gray-100 inline-block px-2 py-0.5 rounded tracking-widest">Global Node: {{ t.entity }}</div>
                </td>
                <td class="px-6 py-4 text-xs font-medium text-gray-600 max-w-sm">{{ t.description }}</td>
                <td class="px-6 py-4"><span class="badge badge-success">{{ t.state }}</span></td>
                <td class="px-6 py-4 text-right"><button class="text-gray-400 hover:text-gray-800 opacity-50 group-hover:opacity-100"><MoreVertical :size="16" /></button></td>
              </tr>
            </tbody>
          </table>

          <!-- ASSIGNMENTS TABLE -->
          <table v-else-if="activeTab === 'assignments'" class="w-full text-left text-sm text-gray-700 border-collapse">
             <thead class="text-xs text-gray-500 border-b border-gray-100">
              <tr>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider">Object Designation</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider">Target Legal Coverage</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider text-center bg-gray-50">Valid Days Length</th>
                 <th class="px-6 py-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
               <tr v-for="a in assignments" :key="a.id" class="border-b border-gray-50 hover:bg-emerald-50/30 transition-colors group">
                <td class="px-6 py-4">
                   <div class="font-bold text-gray-900 mb-1">{{ a.target }}</div>
                   <div class="font-mono text-[10px] text-gray-500 uppercase">{{ a.level }}</div>
                </td>
                <td class="px-6 py-4 font-bold text-emerald-800">{{ a.type_name }}</td>
                <td class="px-6 py-4 text-center">
                    <span class="font-bold text-lg font-mono bg-gray-100 px-3 py-1 rounded-lg border border-gray-200">{{ a.days }}</span>
                </td>
                <td class="px-6 py-4 text-right"><button class="text-gray-400 hover:text-gray-800 opacity-50 group-hover:opacity-100"><MoreVertical :size="16" /></button></td>
              </tr>
            </tbody>
          </table>

          <!-- INSTANCES TABLE -->
          <table v-else class="w-full text-left text-sm text-gray-700 border-collapse">
             <thead class="text-xs text-gray-500 border-b border-gray-100 bg-gray-50/30">
              <tr>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider">Serial Reference</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider">Sale Start</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider">System Expiry Target</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider w-32">Status</th>
              </tr>
            </thead>
            <tbody>
               <tr v-for="i in activeInstances" :key="i.id" class="border-b border-gray-50 hover:bg-gray-50 transition-colors">
                <td class="px-6 py-4">
                   <div class="font-bold text-gray-900 mb-1">{{ i.variant }}</div>
                   <div class="font-mono text-xs font-bold text-emerald-700 bg-emerald-50 inline px-2 py-0.5 rounded border border-emerald-100"><KeyRound :size="12" class="inline mb-0.5 mr-1" />{{ i.serial }}</div>
                </td>
                <td class="px-6 py-4 font-mono text-sm text-gray-600">{{ i.start }}</td>
                <td class="px-6 py-4 font-mono font-bold">{{ i.end }}</td>
                <td class="px-6 py-4"><span class="badge badge-success">{{ i.state }}</span></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- CREATE TYPE FORM -->
      <div v-else-if="currentView === 'create_type'" class="create-view max-w-3xl mx-auto space-y-6 mt-4">
        <div class="bg-white rounded-xl shadow-md border border-gray-200 overflow-hidden animate-fade">
           <div class="p-6 border-b border-emerald-100 bg-emerald-50/50 flex items-center justify-between">
              <div>
                <h3 class="font-black text-xl text-emerald-950 flex items-center gap-2"><FileText class="text-emerald-500" :size="20"/> Global Legal Definition</h3>
                <p class="text-sm font-semibold text-emerald-800/60 mb-0">Construct the base legal text determining replacement logic limits universally.</p>
              </div>
           </div>
           
           <div class="p-8 space-y-6">
              <div class="form-group m-0 border border-gray-200 p-4 rounded-xl bg-gray-50 focus-within:bg-white focus-within:border-emerald-300 transition-colors">
                 <label class="text-xs font-black uppercase text-gray-500 tracking-widest block mb-2">Legal Master Title</label>
                 <input type="text" class="input w-full shadow-none font-bold text-2xl border-transparent bg-transparent p-0" placeholder="e.g. 1 Year Internal Repair..." v-model="formType.name" />
              </div>
              <div class="form-group m-0">
                 <label class="text-xs font-black uppercase text-gray-500 tracking-widest block mb-2 px-1">Description Protocol / Payload</label>
                 <textarea class="input w-full p-4 shadow-inner border-gray-200 focus:border-emerald-500 resize-none font-medium text-gray-600" rows="4" placeholder="Detailed terms explicitly bound to this historical state object..."></textarea>
              </div>
              <div class="flex items-center justify-between border-t border-gray-100 pt-6">
                 <div>
                    <h4 class="font-bold text-sm text-gray-900">Valid Action Status</h4>
                 </div>
                 <label class="toggle-switch transform scale-110"><input type="checkbox" v-model="formType.state"><span class="slider bg-emerald-500"></span></label>
              </div>
           </div>
        </div>
      </div>

      <!-- CREATE ASSIGNMENT FORM -->
      <div v-else-if="currentView === 'create_assignment'" class="create-view max-w-4xl mx-auto space-y-6 mt-4">
         <div class="bg-gray-800 rounded-xl shadow-md overflow-hidden animate-fade relative">
            <div class="absolute right-0 bottom-0 w-64 h-64 bg-gray-700 opacity-50 rounded-full translate-x-1/4 translate-y-1/4 blur-2xl pointer-events-none"></div>
            
            <div class="p-6 border-b border-gray-700 text-white relative z-10 flex items-center justify-between">
              <div>
                <h3 class="font-black text-xl text-white flex items-center gap-2"><PackageCheck class="text-emerald-400" :size="20"/> Autonomous Target Binder</h3>
                <p class="text-sm font-medium text-gray-400 mb-0">Whenever this structural item is sold, the exact policy listed below is automatically rendered natively.</p>
              </div>
            </div>

            <div class="p-8 space-y-8 bg-gray-900 relative z-10">
               
               <div class="p-5 border border-dashed border-gray-600 rounded-xl bg-gray-800/50">
                   <div class="flex gap-4 mb-4">
                     <label :class="['flex-1 p-3 border rounded-lg text-center cursor-pointer font-bold font-mono transition-colors text-sm', formAssignment.targetLevel === 'variant' ? 'bg-emerald-600 text-white shadow-md border-emerald-500' : 'bg-gray-800 border-gray-700 text-gray-400 hover:text-white']">
                        <input type="radio" v-model="formAssignment.targetLevel" value="variant" class="hidden"> BINARY VARIANT EXPLICIT
                     </label>
                     <label :class="['flex-1 p-3 border rounded-lg text-center cursor-pointer font-bold font-mono transition-colors text-sm', formAssignment.targetLevel === 'product' ? 'bg-emerald-600 text-white shadow-md border-emerald-500' : 'bg-gray-800 border-gray-700 text-gray-400 hover:text-white']">
                        <input type="radio" v-model="formAssignment.targetLevel" value="product" class="hidden"> GLOBAL PRODUCT ORIGIN
                     </label>
                  </div>
                  <div class="form-group m-0">
                     <label class="text-xs font-black uppercase tracking-widest text-emerald-500 mb-2 block">Identified Selling Node Target</label>
                     <select class="input w-full font-bold text-base p-3 border-gray-600 text-white bg-gray-800 focus:border-emerald-400" v-if="formAssignment.targetLevel === 'variant'" v-model="formAssignment.product_variant_id">
                        <option value="">Attach Node Target...</option>
                        <option v-for="v in variants" :key="v.id" :value="v.id">{{ v.name }}</option>
                     </select>
                     <select class="input w-full font-bold text-base p-3 border-gray-600 text-white bg-gray-800 focus:border-emerald-400" v-else v-model="formAssignment.product_id">
                        <option value="">Attach Global Target...</option>
                        <option v-for="p in products" :key="p.id" :value="p.id">{{ p.name }}</option>
                     </select>
                  </div>
               </div>

               <div class="flex items-center gap-6 p-4 bg-emerald-950/30 border border-emerald-900 rounded-xl justify-between">
                  <div class="form-group m-0 flex-1">
                     <label class="text-[10px] font-black uppercase text-emerald-500 tracking-wider mb-2 block">Inject Which Legal Context?</label>
                     <select class="input w-full font-bold p-3 border-emerald-800 text-white bg-gray-800 focus:border-emerald-400" v-model="formAssignment.warranty_type_id">
                        <option value="">Target Foreign Key...</option>
                        <option v-for="w in warrantyTypes" :key="w.id" :value="w.id">{{ w.name }}</option>
                     </select>
                  </div>
                  <div class="text-2xl font-black text-gray-600">x</div>
                  <div class="form-group m-0 w-48">
                     <label class="text-[10px] font-black uppercase text-emerald-500 tracking-wider mb-2 block text-center">Span Math (Days)</label>
                     <input type="number" class="input w-full font-mono font-black text-2xl text-center p-2 border-emerald-800 text-white bg-gray-800 focus:border-emerald-400" v-model="formAssignment.days" />
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
.seg-tab { display: flex; align-items: center; gap: 8px; padding: 8px 16px; border-radius: 20px; font-size: 13px; font-weight: 500; color: #6b7280; background: white; border: 1px solid #e5e5e5; cursor: pointer; transition: all 0.2s; }
.seg-tab.active { background: #111827; color: white; border-color: #111827; }
.search-box { position: relative; width: 300px; }
.search-input { width: 100%; padding: 8px 12px 8px 36px; border: 1px solid #e5e5e5; border-radius: 6px; font-size: 13px; outline: none; transition: border-color .2s; }
.search-input:focus { border-color: #10b981; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }
.btn-primary { border: none; border-radius: 8px; cursor: pointer; transition: background 0.2s; }
.form-group label { display: block; font-size: 12px; font-weight: 600; color: #4b5563; margin-bottom: 6px; }
.input { border: 1px solid #e5e5e5; padding: 10px 12px; border-radius: 8px; font-size: 14px; outline: none; background: white; transition: all 0.2s; }
.toggle-switch { position: relative; display: inline-block; width: 44px; height: 24px; }
.toggle-switch input { opacity: 0; width: 0; height: 0; }
.slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #d1d5db; transition: .3s cubic-bezier(0.4, 0, 0.2, 1); border-radius: 34px; }
.slider:before { position: absolute; content: ""; height: 18px; width: 18px; left: 3px; bottom: 3px; background-color: white; transition: .3s cubic-bezier(0.4, 0, 0.2, 1); border-radius: 50%; box-shadow: 0 2px 4px rgba(0,0,0,0.2); }
input:checked + .slider { background-color: #10b981; }
input:checked + .slider:before { transform: translateX(20px); }
.animate-fade { animation: fadeIn 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
</style>
