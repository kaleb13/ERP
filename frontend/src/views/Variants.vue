<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Search, Plus, MoreVertical, CheckCircle, Layers, Link
} from 'lucide-vue-next';

const currentView = ref('list');

const variantMatrix = [
  { id: 1, name: 'Standard Sizing Matrix', attributes: ['Small', 'Medium', 'Large', 'Extra Large'], count: 4, mapped: '12 Products' },
  { id: 2, name: 'Color Hues (Phones)', attributes: ['Midnight Black', 'Starlight', 'Product Red'], count: 3, mapped: '8 Products' },
  { id: 3, name: 'Material Fabric', attributes: ['Cotton', 'Polyester Blended'], count: 2, mapped: '0 Products' }
];

const form = ref({
  name: '',
  values: [{ value: '' }]
});

const addVariantValue = () => {
  form.value.values.push({ value: '' });
};
</script>

<template>
  <DashboardLayout>
    <div class="org-layout">
      <!-- Breadcrumbs -->
      <div class="breadcrumb-bar flex items-center justify-between mb-4">
        <div class="breadcrumb flex items-center gap-2 text-xs text-gray-500">
          <Monitor :size="14" />
          <ChevronRight :size="12" class="text-gray-300" />
          <span class="text-gray-700 font-medium cursor-pointer hover:text-blue-600" @click="currentView = 'list'">Global Variant Structures</span>
          <template v-if="currentView === 'create'">
            <ChevronRight :size="12" class="text-gray-300" />
            <span class="text-gray-700 font-medium">Map Variant Attribute</span>
            <span class="badge-warning ml-2">Not Saved</span>
          </template>
        </div>
        <div class="top-actions" v-if="currentView === 'create'">
          <button class="btn-primary flex items-center gap-2" @click="currentView = 'list'">
            <CheckCircle :size="14" /> Save Master Attribute
          </button>
        </div>
      </div>

      <div v-if="currentView === 'list'">
        <div class="page-container p-6 bg-white rounded-xl shadow-sm border border-gray-200 mb-6 flex gap-4 items-center">
          <div class="p-4 bg-gray-50 text-gray-400 rounded-lg"><Layers :size="24" /></div>
          <div class="page-header">
            <h2 class="text-xl font-bold text-gray-900 mb-1">Variant Attributes (Matrix Database)</h2>
            <p class="text-sm text-gray-500 m-0">Standardize repetitive data structures (like standard Colors and universal Sizes) before binding them deeply inside Products.</p>
          </div>
        </div>

        <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
          <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between">
            <div class="search-box">
               <Search :size="16" class="search-icon" />
               <input type="text" placeholder="Search standard attributes..." class="search-input" />
            </div>
            <button class="btn-primary flex items-center gap-2" @click="currentView = 'create'">
               <Plus :size="14" /> Create Matrix Attribute
            </button>
          </div>
          <table class="w-full text-left text-sm text-gray-700">
            <thead class="text-xs text-gray-500 border-b border-gray-100">
              <tr>
                <th class="px-6 py-4 font-semibold">Master Identifier Name</th>
                <th class="px-6 py-4 font-semibold">Sub-Attribute Vectors</th>
                <th class="px-6 py-4 font-semibold text-center w-32">Usage Linkage</th>
                <th class="px-6 py-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="v in variantMatrix" :key="v.id" class="border-b border-gray-50 hover:bg-gray-50">
                <td class="px-6 py-4 font-bold text-gray-900">{{ v.name }}</td>
                <td class="px-6 py-4">
                   <div class="flex flex-wrap gap-2">
                      <span class="chip-extra text-[10px]" v-for="(val, i) in v.attributes" :key="i">{{ val }}</span>
                   </div>
                </td>
                <td class="px-6 py-4 text-center">
                   <span class="text-xs font-semibold bg-blue-50 text-blue-600 py-1 px-3 border border-blue-100 rounded-lg flex items-center justify-center gap-1">
                     <Link :size="10" /> {{ v.mapped }}
                   </span>
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
         <div class="bg-blue-50 p-6 border border-blue-100 rounded-xl mb-6">
            <h3 class="text-lg font-bold text-blue-900 mb-2">Architecting a Master Matrix</h3>
            <p class="text-sm text-blue-700">These data points act as the blueprints. "Color" acts as the key, giving the Products exactly what properties are generated when the Product variant grid triggers mathematically.</p>
         </div>

         <div class="form-section mb-6">
            <h3 class="section-title">Attribute Key Mapping</h3>
            <div class="grid grid-cols-2 gap-6">
               <div class="form-group col-span-2">
                 <label>Main Attribute String Identifier</label>
                 <input type="text" class="input w-full text-xl font-bold p-4 shadow-inner" placeholder="E.g. Shoe Size (EU)" v-model="form.name" />
               </div>
            </div>
         </div>

         <div class="form-section mb-6 bg-gray-50">
            <h3 class="section-title">Values Scope Arrays</h3>
            <p class="text-sm text-gray-500 mb-4">Dynamically build exactly what attributes the product holds.</p>
            
            <div class="space-y-4">
              <div v-for="(val, index) in form.values" :key="index" class="flex gap-4 items-center bg-white p-3 border rounded-lg shadow-sm">
                <div class="w-8 h-8 rounded bg-gray-100 text-gray-400 flex items-center justify-center font-bold text-xs">{{ index + 1 }}</div>
                <div class="form-group flex-1 m-0">
                  <input type="text" class="input w-full font-mono text-sm border-transparent focus:border-blue-500 bg-transparent p-1" placeholder="Define discrete vector..." v-model="val.value" />
                </div>
              </div>

              <button class="w-full p-4 border border-blue-200 border-dashed rounded-lg text-blue-600 font-semibold hover:bg-blue-50 transition-colors flex items-center justify-center gap-2" @click="addVariantValue">
                 <Plus :size="16" /> Inject Further Value
              </button>
            </div>
         </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.org-layout { max-width: 1000px; margin: 0 auto; }
.badge-warning { background-color: #fef3c7; color: #d97706; font-size: 10px; font-weight: 600; padding: 2px 8px; border-radius: 12px; }
.search-box { position: relative; width: 300px; }
.search-input { width: 100%; padding: 8px 12px 8px 36px; border: 1px solid #e5e5e5; border-radius: 6px; font-size: 13px; outline: none; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }
.btn-primary { padding: 8px 16px; background: #0056b3; color: white; border: none; border-radius: 6px; font-size: 13px; font-weight: 500; cursor: pointer; }
.chip-extra { background: #f3f4f6; color: #4b5563; padding: 4px 8px; border-radius: 20px; font-weight: 500; }
.form-group label { display: block; font-size: 12px; font-weight: 600; color: #4b5563; margin-bottom: 6px; }
.form-group.m-0 label { margin: 0; }
.input { border: 1px solid #e5e5e5; border-radius: 8px; outline: none; transition: border 0.3s; }
.input:focus { border-color: #0056b3; box-shadow: 0 0 0 3px rgba(0,86,179, 0.1); }
.form-section { background: white; border: 1px solid #e5e5e5; border-radius: 12px; padding: 24px; }
.section-title { font-size: 15px; font-weight: 700; color: #111827; margin-bottom: 4px; }
</style>
