<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Search, Filter, Plus, MoreVertical, CheckCircle, FolderTree
} from 'lucide-vue-next';

const currentView = ref('list');

const categoriesList = [
  { id: 1, name: 'Electronics', code: 'ELEC', level: 1, isGroup: true, parent: 'None', state: 'Active' },
  { id: 2, name: 'Smartphones', code: 'PHON', level: 2, isGroup: false, parent: 'Electronics', state: 'Active' },
  { id: 3, name: 'Peripherals', code: 'PERI', level: 2, isGroup: false, parent: 'Electronics', state: 'Inactive' }
];

const form = ref({
  name: '',
  code: '',
  parent_id: '',
  is_group: false,
  state: true
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
          <span class="text-gray-700 font-medium cursor-pointer hover:text-blue-600" @click="currentView = 'list'">Item Categories</span>
          <template v-if="currentView === 'create'">
            <ChevronRight :size="12" class="text-gray-300" />
            <span class="text-gray-700 font-medium">Create Category</span>
            <span class="badge-warning ml-2">Not Saved</span>
          </template>
        </div>
        <div class="top-actions" v-if="currentView === 'create'">
          <button class="btn-primary flex items-center gap-2" @click="currentView = 'list'">
            <CheckCircle :size="14" /> Save Category
          </button>
        </div>
      </div>

      <div v-if="currentView === 'list'">
        <div class="page-container p-6 bg-white rounded-xl shadow-sm border border-gray-200 mb-6 flex gap-4 items-center">
          <div class="p-4 bg-gray-50 text-gray-400 rounded-lg"><FolderTree :size="24" /></div>
          <div class="page-header">
            <h2 class="text-xl font-bold text-gray-900 mb-1">Item Categories (Tree)</h2>
            <p class="text-sm text-gray-500 m-0">Hierarchical categorization of base items controlling logical groupings.</p>
          </div>
        </div>

        <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
          <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between">
            <div class="toolbar-left flex gap-3">
              <div class="search-box">
                <Search :size="16" class="search-icon" />
                <input type="text" placeholder="Search categories..." class="search-input" />
              </div>
            </div>
            <div class="toolbar-right">
              <button class="btn-primary flex items-center gap-2" @click="currentView = 'create'">
                <Plus :size="14" /> Create Category
              </button>
            </div>
          </div>
          <table class="w-full text-left text-sm text-gray-700">
            <thead class="text-xs text-gray-500 border-b border-gray-100">
              <tr>
                <th class="px-6 py-4 font-semibold">Structure Name</th>
                <th class="px-6 py-4 font-semibold">Hierarchy Data</th>
                <th class="px-6 py-4 font-semibold">Is Group?</th>
                <th class="px-6 py-4 font-semibold">State</th>
                <th class="px-6 py-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="c in categoriesList" :key="c.id" class="border-b border-gray-50 hover:bg-gray-50">
                <td class="px-6 py-4">
                  <div class="font-medium text-gray-900 flex items-center gap-2">
                    <span v-if="c.parent !== 'None'" class="text-gray-300 ml-4">↳</span> {{ c.name }}
                  </div>
                </td>
                <td class="px-6 py-4">
                  <div class="text-xs text-gray-400">Code: <span class="font-mono text-gray-900">{{ c.code }}</span></div>
                  <div class="text-xs text-gray-400">Parent: {{ c.parent }}</div>
                </td>
                <td class="px-6 py-4">
                  <span v-if="c.isGroup" class="chip">Folder / Group</span>
                  <span v-else class="chip-extra">Leaf Category</span>
                </td>
                <td class="px-6 py-4">
                  <span :class="['badge', c.state === 'Active' ? 'badge-success' : 'badge-danger']">{{ c.state }}</span>
                </td>
                <td class="px-6 py-4 text-right">
                  <button class="text-gray-400 hover:text-gray-600"><MoreVertical :size="16" /></button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div v-else class="create-view max-w-4xl">
        <div class="form-section mb-6">
          <h3 class="section-title">Category Node Definition</h3>
          <p class="section-subtitle">Set up hierarchical base grouping logic for raw materials and items.</p>
          <div class="grid grid-cols-2 gap-6">
            <div class="form-group col-span-2 md:col-span-1">
              <label>Name Identifier</label>
              <input type="text" class="input w-full" placeholder="e.g. Services" v-model="form.name" />
            </div>
            <div class="form-group col-span-2 md:col-span-1">
              <label>Structural Code</label>
              <input type="text" class="input w-full font-mono text-sm" placeholder="CAT-XX" v-model="form.code" />
            </div>
            <div class="form-group col-span-2">
              <label>Parent Category</label>
              <select class="input w-full" v-model="form.parent_id">
                <option value="">Top Level (Root) Node</option>
                <option value="1">Electronics</option>
              </select>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-6">
          <div class="form-section mb-6 flex flex-col justify-between">
            <h3 class="section-title">Is Group Definition</h3>
            <p class="section-subtitle">If enabled, this acts as an unselectable folder for nesting only.</p>
            <div class="flex items-center justify-between p-3 border rounded-lg bg-gray-50">
              <span class="text-sm font-semibold text-gray-900">Virtual Group Folder</span>
              <label class="toggle-switch"><input type="checkbox" v-model="form.is_group"><span class="slider"></span></label>
            </div>
          </div>
          <div class="form-section mb-6 flex flex-col justify-between">
            <h3 class="section-title">Operational Status</h3>
            <p class="section-subtitle">Toggling this globally hides the branch.</p>
            <div class="flex items-center justify-between p-3 border rounded-lg bg-gray-50">
              <span class="text-sm font-semibold text-gray-900">State</span>
              <label class="toggle-switch"><input type="checkbox" v-model="form.state"><span class="slider"></span></label>
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
.chip { background: #eff6ff; color: #2563eb; padding: 4px 8px; border-radius: 20px; font-size: 11px; font-weight: 500; }
.chip-extra { background: #f3f4f6; color: #4b5563; padding: 4px 8px; border-radius: 20px; font-size: 11px; font-weight: 500; }
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
