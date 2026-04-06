<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Search, CheckCircle, Store, Box, LogIn
} from 'lucide-vue-next';

// State rules mirroring the precise prompt demand (Selector + Table Bulk Setup)
const selectedShop = ref('');

const allProductsList = ref([
  { id: 1, name: 'Caffe Macchiato (Small)', available: true },
  { id: 2, name: 'Double Espresso Pack', available: false },
  { id: 3, name: 'Seasonal Apple Tart', available: true },
  { id: 4, name: 'Raw Sugar 1kg Box', available: false },
]);
</script>

<template>
  <DashboardLayout>
    <div class="org-layout">
      <!-- Breadcrumb Bar -->
      <div class="breadcrumb-bar flex items-center justify-between mb-4">
        <div class="breadcrumb flex items-center gap-2 text-xs text-gray-500">
          <Monitor :size="14" />
          <ChevronRight :size="12" class="text-gray-300" />
          <span class="text-gray-700 font-medium">Shop Product Allocations</span>
        </div>
      </div>

      <!-- Shop Selector & Information Header -->
      <div class="page-container p-6 bg-white rounded-xl shadow-sm border border-gray-200 mb-6 relative overflow-hidden">
        <div class="absolute right-0 top-0 opacity-5 pointer-events-none p-4">
          <Store :size="120" />
        </div>
        <div class="max-w-xl">
           <h2 class="text-xl font-bold text-gray-900 mb-1">Storefront Distribution Matrix</h2>
           <p class="text-sm text-gray-500 mb-6">Logically map and limit exactly which products are explicitly exposed globally or isolated to specific point of sale storefronts.</p>
           
           <div class="flex flex-col gap-2 relative z-10 bg-white/80 p-4 border border-blue-100 rounded-xl shadow-inner backgdrop-blur-sm">
             <label class="text-xs font-bold tracking-widest text-blue-900 uppercase">1. Isolate Shop Target Context</label>
             <select class="select-lg w-full font-bold text-gray-800" v-model="selectedShop">
               <option value="" disabled>--- Select a specific physical or virtual shop ---</option>
               <option value="1">Central Addis Market (Main)</option>
               <option value="2">Bole Airport Kiosk C3</option>
               <option value="3">Digital eCommerce Engine</option>
             </select>
           </div>
        </div>
      </div>

      <!-- Product Configuration Table -->
      <div v-if="selectedShop !== ''" class="animate-fade">
         <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
           
           <div class="p-4 border-b border-gray-100 flex items-center justify-between bg-blue-50/50 rounded-t-xl">
             <div class="flex items-center gap-2 text-blue-900 font-bold">
               <LogIn :size="18" /> Product Binding Roster
             </div>
             <div class="search-box">
                <Search :size="16" class="search-icon" />
                <input type="text" placeholder="Filter isolated products..." class="search-input bg-white" />
              </div>
           </div>

           <!-- Minimalist Bullet UX bulk matrix representation -->
           <table class="w-full text-left text-sm text-gray-700">
             <thead class="text-xs text-gray-500 border-b border-gray-100 bg-gray-50">
               <tr>
                 <th class="px-6 py-4 font-semibold w-24 text-center">In Store Matrix?</th>
                 <th class="px-6 py-4 font-semibold border-l border-gray-100">Saleable Product Identification</th>
               </tr>
             </thead>
             <tbody>
               <tr v-for="p in allProductsList" :key="p.id" :class="['border-b border-gray-50 transition-colors', p.available ? 'bg-white hover:bg-blue-50' : 'bg-gray-50 opacity-70']">
                 <td class="px-6 py-4 border-r border-gray-100">
                    <label class="toggle-switch transform scale-90 block mx-auto text-center" title="Assign Matrix Binding">
                      <input type="checkbox" v-model="p.available">
                      <span class="slider"></span>
                    </label>
                 </td>
                 <td class="px-6 py-4">
                    <div class="flex items-center gap-3">
                      <Box :size="20" :class="p.available ? 'text-blue-600' : 'text-gray-300'" />
                      <span :class="['font-medium text-base', p.available ? 'text-gray-900' : 'text-gray-500 line-through']">{{ p.name }}</span>
                    </div>
                 </td>
               </tr>
             </tbody>
           </table>
         </div>
         <p class="text-center mt-6 text-sm text-gray-400">💡 UI Rule Mechanism constraint: "Which products are sold exactly in this shop mapped over array parameters."</p>
      </div>

    </div>
  </DashboardLayout>
</template>

<style scoped>
.org-layout { max-width: 1200px; margin: 0 auto; }
.search-box { position: relative; width: 300px; }
.search-input { width: 100%; padding: 8px 12px 8px 36px; border: 1px solid #e5e5e5; border-radius: 6px; font-size: 13px; outline: none; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }
.select-lg { border: 2px solid #93c5fd; padding: 12px 14px; border-radius: 10px; font-size: 16px; outline: none; background: #fff; cursor: pointer; transition: all 0.2s; }
.select-lg:focus { border-color: #2563eb; box-shadow: 0 4px 14px rgba(37, 99, 235, 0.1); }
.toggle-switch { position: relative; display: inline-block; width: 44px; height: 24px; }
.toggle-switch input { opacity: 0; width: 0; height: 0; }
.slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #d1d5db; transition: .4s; border-radius: 34px; }
.slider:before { position: absolute; content: ""; height: 18px; width: 18px; left: 3px; bottom: 3px; background-color: white; transition: .4s; border-radius: 50%; box-shadow: 0 1px 2px rgba(0,0,0,0.1); }
input:checked + .slider { background-color: #2563eb; }
input:checked + .slider:before { transform: translateX(20px); }
.animate-fade { animation: fadeIn 0.3s ease-in-out; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
</style>
