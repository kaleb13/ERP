<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Search, Filter, Plus, MoreVertical, CheckCircle, Package
} from 'lucide-vue-next';

const currentView = ref('list');

const itemsList = [
  { id: 1, name: 'Samsung L-Type Processor', category: 'Microchips', type: 'Goods', status: 'Active' },
  { id: 2, name: 'General Consultation', category: 'Services Dept', type: 'Service', status: 'Active' },
  { id: 3, name: 'Raw Plastic Resins', category: 'Materials', type: 'Goods', status: 'Pending' }
];

const form = ref({
  name: '',
  item_category_id: '',
  item_type: 'goods',
  status: 'Active',
  allowed_measurements: [] as string[]
});
</script>

<template>
  <DashboardLayout>
    <div class="org-layout">
      <!-- Breadcrumb -->
      <div class="breadcrumb-bar flex items-center justify-between mb-4">
        <div class="breadcrumb flex items-center gap-2 text-xs text-gray-500">
          <Monitor :size="14" />
          <ChevronRight :size="12" class="text-gray-300" />
          <span class="text-gray-700 font-medium cursor-pointer hover:text-blue-600" @click="currentView = 'list'">Base Items</span>
          <template v-if="currentView === 'create'">
            <ChevronRight :size="12" class="text-gray-300" />
            <span class="text-gray-700 font-medium">Create Generic Item</span>
            <span class="badge-warning ml-2">Not Saved</span>
          </template>
        </div>
        <div class="top-actions" v-if="currentView === 'create'">
          <button class="btn-primary flex items-center gap-2" @click="currentView = 'list'">
            <CheckCircle :size="14" /> Save Item
          </button>
        </div>
      </div>

      <!-- LIST VIEW -->
      <div v-if="currentView === 'list'">
        <div class="page-container p-6 bg-white rounded-xl shadow-sm border border-gray-200 mb-6 flex gap-4 items-center">
          <div class="p-4 bg-gray-50 text-gray-400 rounded-lg"><Package :size="24" /></div>
          <div class="page-header">
            <h2 class="text-xl font-bold text-gray-900 mb-1">Generic Items</h2>
            <p class="text-sm text-gray-500 m-0">The core definition of physical goods or abstract services consumed, manufactured, or sold.</p>
          </div>
        </div>

        <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
          <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between">
            <div class="toolbar-left flex gap-3">
              <div class="search-box">
                <Search :size="16" class="search-icon" />
                <input type="text" placeholder="Search operational items..." class="search-input" />
              </div>
              <button class="btn-outline flex items-center gap-2"><Filter :size="14" /> Category/Type</button>
            </div>
            <div class="toolbar-right">
              <button class="btn-primary flex items-center gap-2" @click="currentView = 'create'">
                <Plus :size="14" /> Create Item
              </button>
            </div>
          </div>

          <table class="w-full text-left text-sm text-gray-700">
            <thead class="text-xs text-gray-500 border-b border-gray-100">
              <tr>
                <th class="px-6 py-4 font-semibold">Generic Name</th>
                <th class="px-6 py-4 font-semibold">Categorization</th>
                <th class="px-6 py-4 font-semibold">Class Type</th>
                <th class="px-6 py-4 font-semibold">Status</th>
                <th class="px-6 py-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="i in itemsList" :key="i.id" class="border-b border-gray-50 hover:bg-gray-50">
                <td class="px-6 py-4 font-medium text-gray-900">{{ i.name }}</td>
                <td class="px-6 py-4 text-gray-500">{{ i.category }}</td>
                <td class="px-6 py-4">
                  <span v-if="i.type === 'Goods'" class="chip">Physical Goods</span>
                  <span v-else class="chip-extra">Abstract Service</span>
                </td>
                <td class="px-6 py-4">
                  <span :class="['badge', i.status === 'Active' ? 'badge-success' : i.status === 'Pending' ? 'badge-warning' : 'badge-danger']">{{ i.status }}</span>
                </td>
                <td class="px-6 py-4 text-right">
                  <button class="text-gray-400 hover:text-gray-600"><MoreVertical :size="16" /></button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- CREATE VIEW -->
      <div v-else class="create-view max-w-4xl">
        <div class="form-section mb-6">
          <h3 class="section-title">Baseline Definition</h3>
          <p class="section-subtitle">Name and strictly map the fundamental physics of the object.</p>
          <div class="grid grid-cols-2 gap-6">
            <div class="form-group col-span-2">
              <label>Universal Abstract Name</label>
              <input type="text" class="input w-full text-lg" placeholder="Raw Lumber Core" v-model="form.name" />
            </div>
            
            <div class="form-group">
              <label>Structural Item Category Link</label>
              <div class="flex items-stretch gap-2">
                 <select class="input w-full" v-model="form.item_category_id">
                   <option value="">Select Category Tree...</option>
                   <option value="1">Electronics</option>
                   <option value="2">Raw Materials</option>
                 </select>
                 <button class="btn-outline px-3 border-dashed bg-gray-50 text-blue-600 flex items-center justify-center whitespace-nowrap" title="Inline Creation UX Win"> + </button>
              </div>
            </div>

            <div class="form-group">
              <label>Class Behavior Mechanism</label>
              <select class="input w-full font-bold" v-model="form.item_type">
                <option value="goods">Tangible Goods</option>
                <option value="service" class="bg-blue-50 text-blue-800">Intangible Service [Bypasses Stocking]</option>
              </select>
            </div>
          </div>
        </div>

        <div class="form-section mb-6">
          <h3 class="section-title">Permitted Item Measurements</h3>
          <p class="section-subtitle">Statically define the logical measuring units that theoretically apply to this item.</p>
          <div class="grid grid-cols-4 gap-4">
             <label class="flex items-center gap-3 p-4 border border-blue-200 rounded-xl cursor-pointer hover:bg-blue-50 relative overflow-hidden group">
                <input type="checkbox" checked class="w-4 h-4 text-blue-600 absolute right-3 top-3" />
                <div class="flex flex-col"><span class="font-bold text-gray-800">Piece</span><span class="text-xs text-gray-500 font-mono mt-1">pcs</span></div>
             </label>
             <label class="flex items-center gap-3 p-4 border border-gray-200 rounded-xl cursor-pointer hover:bg-gray-50 relative overflow-hidden group">
                <input type="checkbox" class="w-4 h-4 text-blue-600 absolute right-3 top-3" />
                <div class="flex flex-col"><span class="font-bold text-gray-800">Kilogram</span><span class="text-xs text-gray-500 font-mono mt-1">kg</span></div>
             </label>
             <label class="flex items-center gap-3 p-4 border border-gray-200 border-dashed rounded-xl cursor-pointer hover:bg-blue-50 bg-gray-50 justify-center">
                <div class="text-sm font-semibold text-blue-600">+ Add Measurement</div>
             </label>
          </div>
        </div>

        <div class="form-section mb-6">
           <h3 class="section-title">Operational Status Override</h3>
           <p class="section-subtitle">Determines if the item can be bound to saleable products currently.</p>
           <div class="w-1/2">
             <select class="input w-full font-bold text-blue-800" v-model="form.status">
               <option value="Pending">Pending QA Mapping</option>
               <option value="Active">Authorized / Active</option>
               <option value="Deactive">Locked / Deactive</option>
             </select>
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
.search-box { position: relative; width: 300px; }
.search-input { width: 100%; padding: 8px 12px 8px 36px; border: 1px solid #e5e5e5; border-radius: 6px; font-size: 13px; outline: none; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }
.btn-outline { padding: 8px 16px; border: 1px solid #e5e5e5; background: white; color: #374151; border-radius: 6px; font-size: 13px; font-weight: 500; cursor: pointer; }
.btn-primary { padding: 8px 16px; background: #0056b3; color: white; border: none; border-radius: 6px; font-size: 13px; font-weight: 500; cursor: pointer; }
.chip { background: #eff6ff; color: #2563eb; padding: 4px 8px; border-radius: 20px; font-size: 11px; font-weight: 500; }
.chip-extra { background: #f3f4f6; color: #4b5563; padding: 4px 8px; border-radius: 20px; font-size: 11px; font-weight: 500; }
.form-group label { display: block; font-size: 12px; font-weight: 600; color: #4b5563; margin-bottom: 6px; }
.input { border: 1px solid #e5e5e5; padding: 10px 12px; border-radius: 8px; font-size: 14px; outline: none; background: white; transition: border 0.3s; }
.input:focus { border-color: #0056b3; box-shadow: 0 0 0 3px rgba(0,86,179, 0.1); }
.form-section { background: white; border: 1px solid #e5e5e5; border-radius: 12px; padding: 24px; }
.section-title { font-size: 15px; font-weight: 700; color: #111827; margin-bottom: 4px; }
.section-subtitle { font-size: 13px; color: #6b7280; margin-bottom: 16px; }
</style>
