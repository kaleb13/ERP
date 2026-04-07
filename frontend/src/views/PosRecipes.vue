<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Search, Plus, MoreVertical, CheckCircle, ChefHat, Flame, Scale, ArrowRightLeft, Settings2
} from 'lucide-vue-next';

// View State Management
const currentView = ref('list');

// Data Types
const recipesList = ref([
  { id: 1, menu_item: 'Margherita Pizza (Large)', ingredients_count: 4, has_alternatives: true, state: 'Active' },
  { id: 2, menu_item: 'Classic Cheeseburger', ingredients_count: 5, has_alternatives: false, state: 'Active' },
  { id: 3, menu_item: 'Fresh Orange Juice', ingredients_count: 1, has_alternatives: false, state: 'Pending' }
]);

// Dummy Dropdown Data
const variants = [
  { id: 1, name: 'Margherita Pizza (Large)' },
  { id: 2, name: 'Classic Cheeseburger' },
  { id: 3, name: 'Pizza Dough Base' },
  { id: 4, name: 'Mozzarella Cheese' },
  { id: 5, name: 'Tomato Sauce' },
  { id: 6, name: 'Cheddar Slice' },
  { id: 7, name: 'Vegan Cheese Substitute' }
];

const measurements = [{ id: 1, name: 'Pieces' }, { id: 2, name: 'Grams (g)' }, { id: 3, name: 'Liters' }];

// Wizard State
const getBlankAlternative = () => ({ alternative_id: '', quantity: '', measurement_id: '', waste_percent: '' });
const getBlankIngredient = () => ({ 
  ingredient_id: '', quantity: '', measurement_id: '', waste_percent: '', is_optional: false, use_alternative: false,
  alternatives: [getBlankAlternative()]
});

const form = ref({
  menu_variant_id: '',
  ingredients: [ getBlankIngredient() ]
});

// Actions
const addIngredient = () => form.value.ingredients.push(getBlankIngredient());
const removeIngredient = (idx: number) => form.value.ingredients.splice(idx, 1);
const addAlternative = (ingIdx: number) => form.value.ingredients[ingIdx].alternatives.push(getBlankAlternative());
const removeAlternative = (ingIdx: number, altIdx: number) => form.value.ingredients[ingIdx].alternatives.splice(altIdx, 1);
</script>

<template>
  <DashboardLayout>
    <div class="org-layout relative">

      <!-- Breadcrumbs -->
      <div class="breadcrumb-bar flex items-center justify-between mb-4">
        <div class="breadcrumb flex items-center gap-2 text-xs text-gray-500">
          <Monitor :size="14" />
          <ChevronRight :size="12" class="text-gray-300" />
          <span class="text-gray-700 font-medium cursor-pointer hover:text-orange-600" @click="currentView = 'list'">Culinary Recipes & BOM</span>
          
          <template v-if="currentView === 'create'">
            <ChevronRight :size="12" class="text-gray-300" />
            <span class="text-gray-700 font-medium">Build Recipe Matrix</span>
            <span class="badge-warning ml-2">Not Saved</span>
          </template>
        </div>
        
        <div class="top-actions" v-if="currentView === 'create'">
          <button class="btn-primary flex items-center gap-2 text-sm px-6 py-2 bg-orange-600 font-bold shadow-md hover:bg-orange-700" @click="currentView = 'list'">
            <CheckCircle :size="16" /> Commit Recipe
          </button>
        </div>
      </div>

      <!-- LIST VIEW -->
      <div v-if="currentView === 'list'">
        <div class="page-container p-6 bg-white rounded-xl shadow-sm border border-gray-200 mb-6 flex gap-4 items-center">
          <div class="p-4 bg-orange-50 text-orange-600 rounded-lg drop-shadow-sm"><ChefHat :size="28" /></div>
          <div class="page-header">
             <h2 class="text-2xl font-black text-gray-900 mb-1 tracking-tight">Bill of Materials / Recipes</h2>
             <p class="text-sm text-gray-500 m-0">Determine exactly what physical inventory items are consumed from the warehouse when a specific hospitality variant is sold or produced.</p>
          </div>
        </div>

        <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
          <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between bg-gray-50/50">
            <div class="search-box">
               <Search :size="16" class="search-icon" />
               <input type="text" placeholder="Search menu items..." class="search-input bg-white" />
            </div>
            <button class="btn-primary bg-orange-600 hover:bg-orange-700 flex items-center gap-2 px-5 py-2.5 font-bold shadow-sm" @click="currentView = 'create'">
               <Plus :size="16" /> Draft New Recipe
            </button>
          </div>
          
          <table class="w-full text-left text-sm text-gray-700 border-collapse">
            <thead class="text-xs text-gray-500 border-b border-gray-100">
              <tr>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider">Produced Product (Target Variant)</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider text-center">Base Ingredients</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider text-center">Contains Substitutes</th>
                <th class="px-6 py-4 font-semibold uppercase tracking-wider w-32">Status</th>
                 <th class="px-6 py-4 font-semibold text-right">Settings</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="r in recipesList" :key="r.id" class="border-b border-gray-50 hover:bg-orange-50/30 transition-colors group">
                <td class="px-6 py-4">
                   <div class="font-bold text-gray-900 text-base mb-1">{{ r.menu_item }}</div>
                </td>
                <td class="px-6 py-4 text-center">
                   <span class="font-bold font-mono text-orange-600 bg-orange-50 px-3 py-1 rounded inline-block">{{ r.ingredients_count }} Items</span>
                </td>
                <td class="px-6 py-4 text-center">
                   <span v-if="r.has_alternatives" class="text-emerald-600 font-bold text-xs uppercase tracking-widest flex items-center justify-center gap-1"><ArrowRightLeft :size="12" /> Yes</span>
                   <span v-else class="text-gray-400 font-medium text-xs uppercase">No</span>
                </td>
                <td class="px-6 py-4">
                   <span :class="['badge', r.state === 'Active' ? 'badge-success' : 'badge-warning']">{{ r.state }}</span>
                </td>
                <td class="px-6 py-4 text-right">
                  <button class="text-gray-400 hover:text-gray-800 opacity-50 group-hover:opacity-100"><MoreVertical :size="16" /></button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- CREATE WIZARD -->
      <div v-else class="create-view max-w-5xl mx-auto space-y-6">
        
        <!-- Target Menu Item -->
        <div class="bg-white rounded-xl shadow-md border-t-4 border-t-orange-600 overflow-hidden">
           <div class="p-6 border-b border-gray-100 bg-gray-50/50 flex items-center justify-between">
              <div>
                <h3 class="font-black text-xl text-gray-900 drop-shadow-sm">Target Menu Architecture</h3>
                <p class="text-sm font-semibold text-gray-500 mb-0">What is the final object being produced?</p>
              </div>
           </div>
           <div class="p-8 pb-10">
              <label class="text-xs font-black uppercase tracking-widest text-orange-400 block mb-2">Hospitality Variant (Output)</label>
              <select class="input w-full font-black text-2xl p-4 shadow-sm border-orange-200 text-gray-900 bg-orange-50/30 focus:border-orange-500" v-model="form.menu_variant_id">
                 <option value="">Select Variant from Endpoints...</option>
                 <option v-for="v in variants" :key="v.id" :value="v.id">{{ v.name }}</option>
              </select>
           </div>
        </div>

        <!-- Ingredients BOM Repeater -->
        <div class="bg-white rounded-xl shadow-md border-t-4 border-t-gray-800 overflow-hidden animate-fade">
           <div class="p-6 border-b border-gray-100 flex items-center justify-between">
              <div>
                <h3 class="font-black text-xl text-gray-900 drop-shadow-sm flex items-center gap-2"><Flame class="text-orange-500" :size="20"/> Raw Ingredient Matrix</h3>
                <p class="text-sm font-semibold text-gray-500 mb-0">What items are deterministically consumed from inventory to build 1 unit of this output?</p>
              </div>
              <button class="btn-primary bg-gray-800 hover:bg-black font-bold flex items-center gap-2" @click="addIngredient">
                 <Plus :size="16"/> Inject Ingredient
              </button>
           </div>
           
           <div class="p-6 space-y-6 bg-gray-50/50">
              <div v-for="(ing, idx) in form.ingredients" :key="idx" class="bg-white border text-gray-900 border-gray-200 rounded-xl shadow-sm p-6 relative group transition-colors">
                 
                 <button @click="removeIngredient(idx)" v-if="form.ingredients.length > 1" class="absolute -right-3 -top-3 w-8 h-8 rounded-full bg-white border border-red-200 text-red-500 shadow-sm flex items-center justify-center opacity-0 group-hover:opacity-100 hover:bg-red-50 hover:text-red-600 transition-all z-10"><X :size="14" /></button>

                 <div class="grid grid-cols-12 gap-6 items-end">
                    <div class="col-span-5 form-group m-0">
                       <label class="text-xs uppercase font-bold text-gray-400">Ingredient Input Component</label>
                       <select class="input w-full font-bold shadow-sm" v-model="ing.ingredient_id">
                          <option value="">Attach Raw Material...</option>
                          <option v-for="v in variants" :key="v.id" :value="v.id">{{ v.name }}</option>
                       </select>
                    </div>
                    
                    <div class="col-span-2 form-group m-0">
                       <label class="text-xs uppercase font-bold text-gray-400">Deduct QTY</label>
                       <input type="number" class="input w-full font-mono font-black text-center text-lg p-2 shadow-sm" placeholder="100" v-model="ing.quantity" />
                    </div>
                    
                    <div class="col-span-3 form-group m-0">
                       <label class="text-xs uppercase font-bold text-gray-400 flex items-center gap-1"><Scale :size="12"/> Metric Unit</label>
                       <select class="input w-full font-medium shadow-sm" v-model="ing.measurement_id">
                          <option value="">e.g. Grams...</option>
                          <option v-for="m in measurements" :key="m.id" :value="m.id">{{ m.name }}</option>
                       </select>
                    </div>

                    <div class="col-span-2 form-group m-0">
                       <label class="text-xs uppercase font-bold text-orange-400">Loss % (Waste)</label>
                       <input type="number" class="input w-full font-mono text-center shadow-sm" placeholder="e.g. 5%" v-model="ing.waste_percent" />
                    </div>
                 </div>

                 <div class="grid grid-cols-2 gap-4 mt-6 pt-6 border-t border-gray-100">
                    <div class="flex flex-col">
                       <span class="text-sm font-bold text-gray-900">Optional Behavior Layer</span>
                       <span class="text-xs text-gray-500 mb-2">Can POS users entirely remove this from the recipe during sale?</span>
                       <label class="toggle-switch transform scale-90 self-start"><input type="checkbox" v-model="ing.is_optional"><span class="slider"></span></label>
                    </div>
                    <div class="flex flex-col border-l border-gray-100 pl-6">
                       <span class="text-sm font-bold text-blue-900 flex items-center gap-2">Substitute Substitutions <ArrowRightLeft :size="14"/></span>
                       <span class="text-xs text-gray-500 mb-2">Does this ingredient allow legal fallbacks if out of stock?</span>
                       <label class="toggle-switch transform scale-90 self-start"><input type="checkbox" v-model="ing.use_alternative"><span class="slider bg-blue-500"></span></label>
                    </div>
                 </div>

                 <!-- Alternatives Sub-Repeater Segment -->
                 <div v-if="ing.use_alternative" class="mt-4 p-4 bg-blue-50/50 border border-blue-100 rounded-lg animate-fade">
                    <div class="flex items-center justify-between mb-4">
                       <h4 class="text-xs font-black uppercase tracking-wider text-blue-600">Legal Subsets (Alternatives)</h4>
                       <button @click="addAlternative(idx)" class="text-xs font-bold text-blue-700 bg-white border border-blue-200 px-3 py-1 rounded hover:bg-blue-100 flex items-center gap-1 shadow-sm"><Plus :size="12" /> Add Alt</button>
                    </div>
                    
                    <div class="space-y-3">
                       <div v-for="(alt, aIdx) in ing.alternatives" :key="aIdx" class="flex items-center gap-3 bg-white p-2 border border-blue-100 rounded shadow-sm relative">
                          <select class="input p-2 flex-1 border-transparent outline-none shadow-none font-bold text-sm bg-gray-50" v-model="alt.alternative_id">
                             <option value="">Substitution Material...</option>
                             <option v-for="v in variants" :key="v.id" :value="v.id">{{ v.name }}</option>
                          </select>
                          <input type="number" class="input p-2 w-20 text-center font-mono text-sm border-transparent bg-gray-50" placeholder="QTY" v-model="alt.quantity" />
                          <select class="input p-2 w-32 border-transparent text-sm bg-gray-50" v-model="alt.measurement_id">
                             <option value="">Unit...</option>
                             <option v-for="m in measurements" :key="m.id" :value="m.id">{{ m.name }}</option>
                          </select>
                          <input type="number" class="input p-2 w-20 text-center font-mono text-sm text-orange-400 border-transparent bg-orange-50/50" placeholder="Loss%" v-model="alt.waste_percent" />
                          <button @click="removeAlternative(idx, aIdx)" class="text-gray-400 hover:text-red-500 px-2"><X :size="14"/></button>
                       </div>
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
.badge-success { background: #dcfce7; color: #16a34a; }
.search-box { position: relative; width: 300px; }
.search-input { width: 100%; padding: 8px 12px 8px 36px; border: 1px solid #e5e5e5; border-radius: 6px; font-size: 13px; outline: none; transition: border-color .2s; }
.search-input:focus { border-color: #ea580c; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }
.btn-primary { border: none; border-radius: 8px; cursor: pointer; transition: background 0.2s; }
.form-group label { display: block; font-size: 12px; font-weight: 600; color: #4b5563; margin-bottom: 6px; }
.input { border: 1px solid #e5e5e5; padding: 10px 12px; border-radius: 8px; font-size: 14px; outline: none; background: white; transition: all 0.2s; }
.input:focus { border-color: #f97316; box-shadow: 0 0 0 3px rgba(249, 115, 22, 0.1); }
.toggle-switch { position: relative; display: inline-block; width: 44px; height: 24px; }
.toggle-switch input { opacity: 0; width: 0; height: 0; }
.slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #d1d5db; transition: .3s cubic-bezier(0.4, 0, 0.2, 1); border-radius: 34px; }
.slider:before { position: absolute; content: ""; height: 18px; width: 18px; left: 3px; bottom: 3px; background-color: white; transition: .3s cubic-bezier(0.4, 0, 0.2, 1); border-radius: 50%; box-shadow: 0 2px 4px rgba(0,0,0,0.2); }
input:checked + .slider { background-color: #10b981; }
input:checked + .slider:before { transform: translateX(20px); }
.animate-fade { animation: fadeIn 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
</style>
