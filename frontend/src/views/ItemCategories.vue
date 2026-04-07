<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Search, Filter, Plus, MoreVertical, FolderTree, Folder, Tag, X
} from 'lucide-vue-next';

// Modal State
const showModal = ref(false);

const categoriesList = [
  { id: 1, name: 'Electronics', code: 'ELEC', level: 1, isGroup: true, parent: 'None', state: 'Active' },
  { id: 2, name: 'Smartphones', code: 'PHON', level: 2, isGroup: false, parent: 'Electronics', state: 'Active' },
  { id: 3, name: 'Peripherals', code: 'PERI', level: 2, isGroup: false, parent: 'Electronics', state: 'Inactive' },
  { id: 4, name: 'Raw Materials', code: 'RAW', level: 1, isGroup: true, parent: 'None', state: 'Active' },
];

const form = ref({
  name: '',
  code: '',
  parent_id: '',
  is_group: false,
  state: true
});

const saveCategory = () => {
  // Logic to save category
  showModal.value = false;
  // Reset form
  form.value = { name: '', code: '', parent_id: '', is_group: false, state: true };
};
</script>

<template>
  <DashboardLayout>
    <div class="org-layout relative">
      
      <!-- CREATE CATEGORY MODAL OVERLAY -->
      <div v-if="showModal" class="fixed inset-0 bg-gray-900/40 z-50 flex flex-col items-center justify-center p-4 backdrop-blur-sm">
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-[500px] overflow-hidden animate-spring">
          <!-- Header -->
          <div class="flex items-center justify-between p-6 pb-4 border-b border-gray-100">
            <h2 class="text-xl font-bold text-gray-900">Define Hierarchy Node</h2>
            <button @click="showModal = false" class="text-gray-400 hover:text-gray-600 rounded-lg p-1 hover:bg-gray-100 transition-colors">
              <X :size="20" />
            </button>
          </div>
          
          <!-- Body -->
          <div class="p-6 space-y-5 bg-gray-50/50">
             <div class="grid grid-cols-2 gap-4">
                <div class="form-group col-span-2 m-0">
                  <label class="text-sm font-medium text-gray-700 mb-1 block">Category Name Identifier</label>
                  <input type="text" class="input w-full p-2.5 shadow-sm" placeholder="e.g. Services" v-model="form.name" />
                </div>
                <div class="form-group col-span-2 md:col-span-1 m-0">
                  <label class="text-sm font-medium text-gray-700 mb-1 block">System Code</label>
                  <input type="text" class="input w-full p-2.5 font-mono shadow-sm" placeholder="CAT-XX" v-model="form.code" />
                </div>
                <div class="form-group col-span-2 md:col-span-1 m-0">
                  <label class="text-sm font-medium text-gray-700 mb-1 block">Parent Node Linkage</label>
                  <select class="input w-full p-2.5 shadow-sm" v-model="form.parent_id">
                    <option value="">Absolute Root (None)</option>
                    <option value="1">Electronics</option>
                  </select>
                </div>
             </div>

             <div class="flex flex-col gap-3 mt-2">
                <!-- Is Group Toggle -->
                <div class="flex items-center justify-between p-4 border border-gray-200 rounded-xl bg-white shadow-sm hover:border-blue-200 transition-colors">
                  <div>
                     <span class="text-sm font-bold text-gray-800 block">Classify as Virtual Group Folder?</span>
                     <span class="text-xs text-gray-500">Unselectable placeholder node meant exclusively for routing abstraction.</span>
                  </div>
                  <label class="toggle-switch transform scale-110">
                    <input type="checkbox" v-model="form.is_group">
                    <span class="slider bg-blue-500 before:bg-white peer-checked:bg-blue-600"></span>
                  </label>
                </div>

                <!-- Status Toggle -->
                <div class="flex items-center justify-between p-4 border border-gray-200 rounded-xl bg-white shadow-sm hover:border-emerald-200 transition-colors">
                  <span class="text-sm font-bold text-gray-800">Operational Active State</span>
                  <label class="toggle-switch transform scale-110">
                    <input type="checkbox" v-model="form.state">
                    <span class="slider bg-emerald-500 before:bg-white peer-checked:bg-emerald-500"></span>
                  </label>
                </div>
             </div>
          </div>
          
          <!-- Footer -->
          <div class="p-4 px-6 border-t border-gray-100 bg-white flex items-center justify-end gap-3">
             <button @click="showModal = false" class="px-5 py-2 hover:bg-gray-100 text-gray-700 rounded-lg text-sm font-bold transition-colors">
               Cancel
             </button>
             <button @click="saveCategory" class="px-6 py-2 bg-[#0e52a0] hover:bg-[#0b4284] text-white rounded-lg text-sm font-semibold transition-colors shadow-sm">
               Commit Node Entity
             </button>
          </div>
        </div>
      </div>

      <!-- Breadcrumb Bar -->
      <div class="breadcrumb-bar flex items-center justify-between mb-4">
        <div class="breadcrumb flex items-center gap-2 text-xs text-gray-500">
          <Monitor :size="14" />
          <ChevronRight :size="12" class="text-gray-300" />
          <span class="text-gray-700 font-medium">Item Categories</span>
        </div>
      </div>

      <!-- Context Header -->
      <div class="page-container p-6 bg-white rounded-xl shadow-sm border border-gray-200 mb-6 flex gap-4 items-center">
        <div class="p-4 bg-gray-50 text-gray-400 rounded-lg"><FolderTree :size="24" /></div>
        <div class="page-header">
          <h2 class="text-xl font-bold text-gray-900 mb-1">Item Categories (Tree)</h2>
          <p class="text-sm text-gray-500 m-0">Hierarchical categorization of base items controlling logical groupings.</p>
        </div>
      </div>

      <!-- MAIN TREE TABLE -->
      <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
        <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between">
          <div class="toolbar-left flex gap-3">
            <div class="search-box">
              <Search :size="16" class="search-icon" />
              <input type="text" placeholder="Search categories..." class="search-input" />
            </div>
          </div>
          <div class="toolbar-right">
            <!-- Modal Trigger strictly requested -->
            <button class="btn-primary flex items-center gap-2" @click="showModal = true">
              <Plus :size="14" /> Create Category
            </button>
          </div>
        </div>
        
        <table class="w-full text-left text-sm text-gray-700 border-collapse">
          <thead class="text-xs text-gray-500 border-b border-gray-100 bg-gray-50/50">
            <tr>
              <th class="px-6 py-4 font-semibold w-1/2">Tree Structural Name</th>
              <th class="px-6 py-4 font-semibold">Origin Parent Linkage</th>
              <th class="px-6 py-4 font-semibold">State</th>
              <th class="px-6 py-4 font-semibold text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="c in categoriesList" :key="c.id" class="border-b border-gray-50 hover:bg-blue-50/20 group transition-colors">
              <td class="px-6 py-4">
                <div class="flex items-start gap-4">
                  <!-- Visual Tree Depth Mechanism Rendering -->
                  <div class="tree-line self-stretch border-l-2 border-gray-200 relative left-1" v-if="c.level > 1" :style="{ marginLeft: `${(c.level - 2) * 2.5}rem` }">
                     <div class="w-4 h-0 border-t-2 border-gray-200 absolute top-4 left-0"></div>
                  </div>
                  
                  <div class="flex items-start gap-3 relative z-10" :style="{ marginLeft: c.level === 1 ? '0' : '1.5rem' }">
                     <!-- Folder vs Leaf icon -->
                     <div class="mt-0.5">
                       <Folder v-if="c.isGroup" :size="20" class="text-blue-500 fill-blue-50" />
                       <Tag v-else :size="18" class="text-gray-400" />
                     </div>
                     <div>
                        <!-- Required Rule: Name Above Code -->
                        <div class="font-bold text-gray-900 text-base mb-0.5">{{ c.name }}</div>
                        <div class="font-mono text-[10px] text-gray-400 bg-gray-50 inline-block px-1.5 py-0.5 rounded border border-gray-200">#{{ c.code }}</div>
                     </div>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4">
                 <span v-if="c.parent === 'None'" class="text-gray-400 font-mono text-xs italic">Absolute Root Node</span>
                 <span v-else class="text-gray-600 font-medium">{{ c.parent }}</span>
              </td>
              <td class="px-6 py-4">
                <span :class="['badge', c.state === 'Active' ? 'badge-success' : 'badge-danger']">{{ c.state }}</span>
              </td>
              <td class="px-6 py-4 text-right">
                <button class="text-gray-400 hover:text-gray-600 opacity-0 group-hover:opacity-100 transition-opacity"><MoreVertical :size="16" /></button>
              </td>
            </tr>
          </tbody>
        </table>
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
.search-box { position: relative; width: 300px; }
.search-input { width: 100%; padding: 8px 12px 8px 36px; border: 1px solid #e5e5e5; border-radius: 6px; font-size: 13px; outline: none; transition: border-color .2s; }
.search-input:focus { border-color: #2563eb; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }
.btn-primary { padding: 8px 16px; background: #0056b3; color: white; border: none; border-radius: 6px; font-size: 13px; font-weight: 500; cursor: pointer; transition: background 0.2s; }
.btn-primary:hover { background: #004494; }
.input { border: 1px solid #e5e5e5; border-radius: 8px; font-size: 14px; outline: none; background: white; transition: all 0.2s; }
.input:focus { border-color: #2563eb; box-shadow: 0 0 0 3px rgba(37,99,235, 0.1); }
.toggle-switch { position: relative; display: inline-block; width: 44px; height: 24px; }
.toggle-switch input { opacity: 0; width: 0; height: 0; }
.slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #d1d5db; transition: .3s flex; border-radius: 34px; }
.slider:before { position: absolute; content: ""; height: 18px; width: 18px; left: 3px; bottom: 3px; background-color: white; transition: .3s ease-in-out; border-radius: 50%; box-shadow: 0 2px 4px rgba(0,0,0,0.2); }
input:checked + .slider { background-color: #10b981; }
input:checked + .slider:before { transform: translateX(20px); }
.animate-spring { animation: springIn 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards; }
@keyframes springIn { from { opacity: 0; transform: scale(0.95) translateY(10px); } to { opacity: 1; transform: scale(1) translateY(0); } }
</style>
