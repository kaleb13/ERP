<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Search, Filter, Plus, MoreVertical, CheckCircle, Tag, Image as ImageIcon
} from 'lucide-vue-next';

// State
const currentView = ref('list');

// Dummy Data mapped to Schema
const brandsList = [
  { id: 1, name: 'Apple Inc.', code: 'BRD-APL', entity: 'Global', status: 'Active', logoUrl: 'https://cdn-icons-png.flaticon.com/512/0/747.png' },
  { id: 2, name: 'Samsung Group', code: 'BRD-SMG', entity: 'Regional', status: 'Active', logoUrl: '' },
  { id: 3, name: 'Generic Brand', code: 'BRD-GEN', entity: 'Local', status: 'Inactive', logoUrl: '' }
];

// Form Schema
const form = ref({
  name: '',
  code: '',
  description: '',
  logoUrl: '',
  entity_id: '',
  state: true // true = Active, false = Inactive
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
          <span class="text-gray-700 font-medium cursor-pointer hover:text-blue-600" @click="currentView = 'list'">Brands</span>
          
          <template v-if="currentView === 'create'">
            <ChevronRight :size="12" class="text-gray-300" />
            <span class="text-gray-700 font-medium">Create Brand</span>
            <span class="badge-warning ml-2">Not Saved</span>
          </template>
        </div>

        <div class="top-actions" v-if="currentView === 'create'">
          <button class="btn-primary flex items-center gap-2" @click="currentView = 'list'">
            <CheckCircle :size="14" /> Save Brand
          </button>
        </div>
      </div>

      <!-- LIST VIEW -->
      <div v-if="currentView === 'list'">
        <!-- Header Section -->
        <div class="page-container p-6 bg-white rounded-xl shadow-sm border border-gray-200 mb-6">
          <div class="page-header">
            <h2 class="text-xl font-bold text-gray-900 mb-1">Brand Management</h2>
            <p class="text-sm text-gray-500 m-0">Define manufacturer names technically mapped to products and items across your tenants.</p>
          </div>
        </div>

        <!-- Main Data Table Section -->
        <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
          <!-- Toolbar -->
          <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between">
            <div class="toolbar-left flex gap-3">
              <div class="search-box">
                <Search :size="16" class="search-icon" />
                <input type="text" placeholder="Search brands by name or code..." class="search-input" />
              </div>
              <button class="btn-outline flex items-center gap-2">
                <Filter :size="14" /> Filters
              </button>
            </div>
            <div class="toolbar-right">
              <button class="btn-primary flex items-center gap-2" @click="currentView = 'create'">
                <Plus :size="14" /> Create Brand
              </button>
            </div>
          </div>

          <!-- Table -->
          <div class="table-responsive">
            <table class="w-full text-left text-sm text-gray-700">
              <thead class="text-xs text-gray-500 border-b border-gray-100">
                <tr>
                  <th class="px-6 py-4 font-semibold w-16">Logo</th>
                  <th class="px-6 py-4 font-semibold">Brand Name</th>
                  <th class="px-6 py-4 font-semibold">Code</th>
                  <th class="px-6 py-4 font-semibold">Entity Owner</th>
                  <th class="px-6 py-4 font-semibold">Status</th>
                  <th class="px-6 py-4 font-semibold text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="b in brandsList" :key="b.id" class="border-b border-gray-50 hover:bg-gray-50">
                  <td class="px-6 py-4">
                    <div class="w-10 h-10 rounded-lg border border-gray-200 flex items-center justify-center bg-gray-50 overflow-hidden">
                      <img v-if="b.logoUrl" :src="b.logoUrl" class="w-full h-full object-contain p-1" />
                      <ImageIcon v-else :size="16" class="text-gray-300" />
                    </div>
                  </td>
                  <td class="px-6 py-4 font-medium text-gray-900 flex items-center gap-2">
                     {{ b.name }}
                  </td>
                  <td class="px-6 py-4 font-mono text-xs text-gray-500">{{ b.code }}</td>
                  <td class="px-6 py-4 text-gray-500">{{ b.entity }}</td>
                  <td class="px-6 py-4">
                    <span :class="['badge', b.status === 'Active' ? 'badge-success' : 'badge-danger']">{{ b.status }}</span>
                  </td>
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
              <span>Showing 1 to 3 of 3 entries</span>
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

      <!-- CREATE VIEW -->
      <div v-else class="create-view max-w-4xl">
        <div class="form-section mb-6">
          <h3 class="section-title">Basic Info</h3>
          <p class="section-subtitle">Core identity properties of the brand.</p>
          <div class="grid grid-cols-2 gap-6">
            <div class="form-group col-span-2 md:col-span-1">
              <label>Name <span class="text-red-500">*</span></label>
              <input type="text" class="input w-full" placeholder="e.g. Apple Inc." v-model="form.name" />
            </div>
            <div class="form-group col-span-2 md:col-span-1">
              <label>Code (Auto or Manual)</label>
              <input type="text" class="input w-full font-mono text-sm" placeholder="BRD-XX" v-model="form.code" />
            </div>
            <div class="form-group col-span-2">
              <label>Description</label>
              <textarea class="input w-full p-3 h-24 resize-none" placeholder="Optional details..." v-model="form.description"></textarea>
            </div>
          </div>
        </div>

        <div class="form-section mb-6">
          <h3 class="section-title">Media Integration</h3>
          <p class="section-subtitle">Upload corporate brand imagery.</p>
          <div class="border-2 border-dashed border-gray-300 rounded-xl p-8 flex flex-col items-center justify-center bg-gray-50 cursor-pointer hover:bg-gray-100 transition-colors">
             <ImageIcon :size="32" class="text-gray-400 mb-3" />
             <div class="text-sm font-semibold text-blue-600">Click to upload brand logo</div>
             <div class="text-xs text-gray-500 mt-1">PNG, JPG, SVG up to 2MB</div>
          </div>
        </div>

        <div class="form-section mb-6">
          <div class="grid grid-cols-2 gap-6">
            <div class="form-group col-span-2 md:col-span-1">
              <h3 class="section-title">Ownership</h3>
              <p class="section-subtitle">Multi-tenant scope isolation.</p>
              <label>Entity Array Mapping</label>
              <select class="input w-full" v-model="form.entity_id">
                <option value="">Global (Available to all)</option>
                <option value="1">Central Corporate Only</option>
              </select>
            </div>
            
            <div class="form-group col-span-2 md:col-span-1 border-l pl-6">
               <h3 class="section-title">Status Rule</h3>
               <p class="section-subtitle">Dictate operational availability.</p>
               <div class="flex items-center justify-between p-3 border rounded-lg bg-gray-50 mt-6">
                 <div>
                   <div class="text-sm font-semibold text-gray-900">Brand Available</div>
                   <div class="text-xs text-gray-500">Allow brand selection during product setup</div>
                 </div>
                 <label class="toggle-switch"><input type="checkbox" v-model="form.state"><span class="slider"></span></label>
               </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.org-layout { max-width: 1200px; margin: 0 auto; }
.badge-warning { background-color: #fef3c7; color: #d97706; font-size: 10px; font-weight: 600; padding: 2px 8px; border-radius: 12px; }
.badge-success { background: #dcfce7; color: #16a34a; padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 500; }
.badge-danger {  background: #fee2e2; color: #dc2626; padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 500; }

.search-box { position: relative; width: 300px; }
.search-input { width: 100%; padding: 8px 12px 8px 36px; border: 1px solid #e5e5e5; border-radius: 6px; font-size: 13px; outline: none; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }

.btn-outline { padding: 8px 16px; border: 1px solid #e5e5e5; background: white; color: #374151; border-radius: 6px; font-size: 13px; font-weight: 500; cursor: pointer; }
.btn-primary { padding: 8px 16px; background: #0056b3; color: white; border: none; border-radius: 6px; font-size: 13px; font-weight: 500; cursor: pointer; }

.page-btn { padding: 6px 12px; background: white; border: none; border-right: 1px solid #e5e5e5; color: #374151; cursor: pointer; font-size: 13px; }
.page-btn:last-child { border-right: none; }
.page-btn:hover { background: #f9fafb; }
.page-btn.active { background: #0056b3; color: white; font-weight: 500; }

.form-group label { display: block; font-size: 12px; font-weight: 600; color: #4b5563; margin-bottom: 6px; }
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
</style>
