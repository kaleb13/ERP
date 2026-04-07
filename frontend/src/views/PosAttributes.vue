<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Search, Plus, MoreVertical, CheckCircle, ListPlus, GripVertical, Image as ImageIcon, X, Maximize2, Trash2, SlidersHorizontal, Settings2, Fingerprint, Layers
} from 'lucide-vue-next';

// View State Management
// 'list', 'create_value', 'create_full'
const currentView = ref('list'); 
const activeTab = ref('attributes'); // 'attributes', 'values', 'assignments'

// Modal State
const showAttrModal = ref(false);

// --- SCHEMA DATA STORE DUMMIES ---
const attributesList = ref([
  { id: 1, name: 'Size Portfolio', input_type: 'text', state: 'Active' },
  { id: 2, name: 'Color Spectrum', input_type: 'text', state: 'Active' },
  { id: 3, name: 'Thermal Level', input_type: 'number', state: 'Active' }
]);

const valuesList = ref([
  { id: 1, attribute: 'Size Portfolio', value: 'Small', sort_order: 1, has_attachment: false, state: 'Active' },
  { id: 2, attribute: 'Size Portfolio', value: 'Medium', sort_order: 2, has_attachment: false, state: 'Active' },
  { id: 3, attribute: 'Color Spectrum', value: 'Midnight Red', sort_order: 1, has_attachment: true, state: 'Active' }
]);

const assignmentsList = ref([
  { id: 1, attribute: 'Size Portfolio', category: 'Apparel', usage: 'Global' },
  { id: 2, attribute: 'Thermal Level', category: 'Hot Beverages', usage: 'Branch Specific' }
]);

// Single Forms
const quickAttrForm = ref({ name: '', input_type: 'text', state: true });
const standaloneValueForm = ref({ product_attribute_id: '', value: '', sort_order: 1, state: 'Active' });

// Massive Unified Builder Form State (The "Relatable" Architecture Builder)
const getBlankValue = (index: number) => ({ id: Date.now() + index, value: '', sort_order: index + 1, attachment: null, state: true });

const fullForm = ref({
  attribute: { name: '', input_type: 'text', state: true },
  values: [ getBlankValue(0) ],
  assignment: { category_id: '', usage_type: 'Global' }
});

// Row Add/Remove Logic
const addValueRow = () => { fullForm.value.values.push(getBlankValue(fullForm.value.values.length)); };
const removeValueRow = (index: number) => { fullForm.value.values.splice(index, 1); };

// Drag & Drop visual dummy state tracking
const dragState = ref<number | null>(null);
const dragStart = (index: number) => { dragState.value = index; };
const dragDrop = (targetIndex: number) => {
  if (dragState.value === null) return;
  const item = fullForm.value.values.splice(dragState.value, 1)[0];
  fullForm.value.values.splice(targetIndex, 0, item);
  // Reassign sort orders
  fullForm.value.values.forEach((v, i) => v.sort_order = i + 1);
  dragState.value = null;
};

// Actions
const saveQuickAttr = () => {
  attributesList.value.push({ id: Date.now(), name: quickAttrForm.value.name, input_type: quickAttrForm.value.input_type, state: quickAttrForm.value.state ? 'Active' : 'Inactive' });
  showAttrModal.value = false;
  quickAttrForm.value = { name: '', input_type: 'text', state: true }; 
};

const goToFullExpandedForm = () => {
  fullForm.value.attribute.name = quickAttrForm.value.name;
  fullForm.value.attribute.input_type = quickAttrForm.value.input_type;
  fullForm.value.attribute.state = quickAttrForm.value.state;
  fullForm.value.values = [ getBlankValue(0) ];
  showAttrModal.value = false;
  currentView.value = 'create_full';
};
</script>

<template>
  <DashboardLayout>
    <div class="org-layout relative">
      
      <!-- QUICK ATTRIBUTE MODAL OVERLAY -->
      <div v-if="showAttrModal" class="fixed inset-0 bg-gray-900/40 z-50 flex items-center justify-center p-4 backdrop-blur-sm">
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-[480px] overflow-hidden animate-spring border border-white/20">
          <!-- Header -->
          <div class="flex items-center justify-between p-6 pb-4">
            <h2 class="text-xl font-bold text-gray-900">Define Product Attribute</h2>
            <button @click="showAttrModal = false" class="text-gray-400 hover:text-gray-600 rounded-lg p-1 hover:bg-gray-100 transition-colors">
              <X :size="20" />
            </button>
          </div>
          
          <!-- Body -->
          <div class="p-6 pt-2 space-y-5">
             <div class="form-group m-0">
               <label class="text-sm font-medium text-gray-700 mb-2 block">Attribute Name (e.g. Color, Size, Flavor)</label>
               <input type="text" class="input w-full p-3 border-gray-300 text-base font-bold shadow-sm focus:border-blue-500 focus:ring-1 focus:ring-blue-500" placeholder="Type name..." v-model="quickAttrForm.name" />
             </div>

             <div class="form-group m-0">
                <label class="text-sm font-medium text-gray-700 mb-2 block">DataType Vector Constraint</label>
                <select class="input w-full p-3 shadow-sm border-gray-300 focus:border-blue-500" v-model="quickAttrForm.input_type">
                  <option value="text">String / Text Format (Letters & Words)</option>
                  <option value="number">Numeric Format (Integer Numbers)</option>
                  <option value="boolean">Boolean Switch (True/False)</option>
                </select>
             </div>
             
             <!-- Special Bordered Toggle -->
             <div class="flex items-center justify-between p-4 border border-gray-200 rounded-xl bg-white shadow-sm">
               <span class="text-base font-medium text-gray-800">Operational Status</span>
               <label class="toggle-switch transform scale-110">
                 <input type="checkbox" v-model="quickAttrForm.state">
                 <span class="slider bg-emerald-500 before:bg-white text-emerald-500 peer-checked:bg-emerald-500"></span>
               </label>
             </div>
          </div>
          
          <!-- Footer -->
          <div class="p-4 px-6 border-t border-gray-100 bg-gray-50/50 flex items-center justify-between">
             <button @click="goToFullExpandedForm" class="flex items-center justify-center gap-2 px-4 py-2.5 bg-white border border-gray-300 rounded-lg text-sm font-semibold text-gray-700 hover:bg-gray-50 hover:text-blue-700 transition-all shadow-sm">
               Expand Options Wizard <Maximize2 :size="14" />
             </button>
             <button @click="saveQuickAttr" class="px-6 py-2.5 bg-[#0e52a0] hover:bg-[#0b4284] text-white rounded-lg text-sm font-semibold transition-colors shadow-sm">
               Save Root
             </button>
          </div>
        </div>
      </div>

      <!-- Breadcrumbs -->
      <div class="breadcrumb-bar flex items-center justify-between mb-4">
         <div class="breadcrumb flex items-center gap-2 text-xs text-gray-500">
          <Monitor :size="14" />
          <ChevronRight :size="12" class="text-gray-300" />
          <span class="text-gray-700 font-medium cursor-pointer hover:text-blue-600" @click="currentView = 'list'">Product Attributes</span>
          
          <template v-if="currentView !== 'list'">
            <ChevronRight :size="12" class="text-gray-300" />
            <span class="text-gray-700 font-medium">
              <template v-if="currentView === 'create_full'">Attribute Builder</template>
              <template v-if="currentView === 'create_value'">Create Attribute Value</template>
            </span>
            <span class="badge-warning ml-2">Not Saved</span>
          </template>
        </div>
        <div class="top-actions" v-if="currentView !== 'list'">
          <button class="btn-primary flex items-center gap-2" @click="currentView = 'list'">
            <CheckCircle :size="14" /> Save
          </button>
        </div>
      </div>

      <!-- LIST VIEW -->
      <div v-if="currentView === 'list'">
        <!-- Hero Header (Matching Measurement Pattern) -->
        <div class="page-container p-8 bg-white rounded-xl shadow-sm border border-gray-200 mb-6 flex gap-6 items-center">
          <div class="p-5 bg-blue-50 text-blue-600 rounded-2xl shadow-inner border border-blue-100 flex items-center justify-center"><Fingerprint :size="32" /></div>
          <div class="page-header">
            <h2 class="text-2xl font-black text-gray-900 mb-1 tracking-tight">Product Attributes & Values</h2>
            <p class="text-sm text-gray-500 m-0 max-w-2xl leading-relaxed">Define the global variable parameters (Color, Size, Flavor) and map their allowed attribute values universally to product variations.</p>
          </div>
        </div>

        <!-- TABS (3-Tab Relatable Layout) -->
        <div class="flex gap-2 mb-6 p-1 bg-gray-100/50 rounded-2xl w-fit border border-gray-200/50">
          <button :class="['seg-tab', { 'active': activeTab === 'attributes' }]" @click="activeTab = 'attributes'"><SlidersHorizontal :size="16" /> Attributes</button>
          <button :class="['seg-tab', { 'active': activeTab === 'values' }]" @click="activeTab = 'values'"><ListPlus :size="16" /> Attribute Values</button>
          <button :class="['seg-tab', { 'active': activeTab === 'assignments' }]" @click="activeTab = 'assignments'"><Layers :size="16" /> Product Usage</button>
        </div>

        <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between bg-gray-50/30">
            <div class="toolbar-left flex gap-3">
              <div class="search-box">
                <Search :size="16" class="search-icon" />
                <input type="text" placeholder="Search product attributes..." class="search-input shadow-inner" />
              </div>
            </div>
            <div class="toolbar-right">
              <!-- Smart dynamic trigger -->
              <button class="btn-primary flex items-center gap-2 shadow-md" @click="activeTab === 'attributes' ? showAttrModal = true : activeTab === 'values' ? currentView = 'create_value' : showAttrModal = true">
                <Plus :size="14" /> {{ activeTab === 'attributes' ? 'Create Attribute' : activeTab === 'values' ? 'Create Attribute Value' : 'Assign to Product' }}
              </button>
            </div>
          </div>

          <!-- TABULAR VIEWS -->
          <div class="table-responsive">
            <table v-if="activeTab === 'attributes'" class="w-full text-left text-sm text-gray-700 border-collapse">
              <thead class="text-xs text-gray-400 border-b border-gray-100 bg-white">
                <tr><th class="px-6 py-4 font-bold uppercase tracking-wider">Attribute Name</th><th class="px-6 py-4 font-bold uppercase tracking-wider text-center">Data Array Type</th><th class="px-6 py-4 font-bold uppercase tracking-wider w-32">State</th><th class="px-6 py-4 text-right w-24">Actions</th></tr>
              </thead>
              <tbody>
                <tr v-for="a in attributesList" :key="a.id" class="border-b border-gray-50 hover:bg-blue-50/30 transition-colors">
                  <td class="px-6 py-4 font-black text-gray-900 border-l-4 border-transparent hover:border-blue-500 pl-5">{{ a.name }}</td>
                  <td class="px-6 py-4 text-center"><span class="chip-extra font-mono text-gray-600 bg-gray-100 border border-gray-200 uppercase tracking-wider text-[10px]">{{ a.input_type }}</span></td>
                  <td class="px-6 py-4"><span :class="['badge', a.state === 'Active' ? 'badge-success' : 'badge-danger']">{{ a.state }}</span></td>
                  <td class="px-6 py-4 text-right"><button class="text-gray-400 hover:text-gray-800"><MoreVertical :size="16" /></button></td>
                </tr>
              </tbody>
            </table>

            <table v-else-if="activeTab === 'values'" class="w-full text-left text-sm text-gray-700">
              <thead class="text-xs text-gray-400 border-b border-gray-100 bg-white">
                <tr><th class="px-6 py-4 w-12 text-center text-gray-300">#</th><th class="px-6 py-4 font-bold uppercase tracking-wider">Attribute Reference</th><th class="px-6 py-4 font-bold uppercase tracking-wider">Attribute Value</th><th class="px-6 py-4 text-center font-bold uppercase tracking-wider">Attachment</th><th class="px-6 py-4 text-right uppercase tracking-wider">Actions</th></tr>
              </thead>
              <tbody>
                <tr v-for="v in valuesList" :key="v.id" class="border-b border-gray-50 hover:bg-indigo-50/30 transition-colors">
                  <td class="px-6 py-4 font-mono font-bold text-gray-300 text-center border-r border-gray-50">{{ v.sort_order }}</td>
                  <td class="px-6 py-4 text-xs font-black text-gray-400 tracking-wider uppercase bg-gray-50/50">{{ v.attribute }}</td>
                  <td class="px-6 py-4 font-bold text-gray-900 text-base drop-shadow-sm">{{ v.value }}</td>
                  <td class="px-6 py-4 text-center">
                     <span v-if="v.has_attachment" class="inline-flex drop-shadow-sm items-center justify-center p-1.5 rounded-lg bg-blue-50 text-blue-600 border border-blue-200"><ImageIcon :size="16" /></span>
                     <span v-else class="font-mono text-[9px] text-gray-200 uppercase tracking-tighter">no_asset</span>
                  </td>
                  <td class="px-6 py-4 text-right"><button class="text-gray-400 hover:text-gray-800"><MoreVertical :size="16" /></button></td>
                </tr>
              </tbody>
            </table>

            <table v-else class="w-full text-left text-sm text-gray-700">
              <thead class="text-xs text-gray-400 border-b border-gray-100 bg-white">
                <tr><th class="px-6 py-4 font-bold uppercase tracking-wider">Linked Attribute</th><th class="px-6 py-4 font-bold uppercase tracking-wider">Functional Category</th><th class="px-6 py-4 font-bold uppercase tracking-wider text-right">Deployment Status</th></tr>
              </thead>
              <tbody>
                <tr v-for="as in assignmentsList" :key="as.id" class="border-b border-gray-50 hover:bg-emerald-50/30 transition-colors">
                  <td class="px-6 py-4 font-bold text-blue-900">{{ as.attribute }}</td>
                  <td class="px-6 py-4 font-medium text-gray-600">{{ as.category }}</td>
                  <td class="px-6 py-4 text-right"><span class="px-3 py-1 bg-emerald-100 text-emerald-700 rounded-full text-[10px] font-bold uppercase tracking-widest border border-emerald-200">{{ as.usage }}</span></td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- ============================================== -->
      <!-- REGULAR FORM: STANDALONE DISCRETE VALUE CREATE -->
      <!-- ============================================== -->
      <div v-else-if="currentView === 'create_value'" class="create-view max-w-4xl mx-auto animate-fade mt-6">
         <div class="form-section mb-6 border-t-8 border-t-blue-600 shadow-xl rounded-2xl bg-white p-10">
           <div class="flex items-center gap-4 mb-8">
              <div class="w-12 h-12 bg-blue-50 text-blue-600 rounded-xl flex items-center justify-center shadow-inner"><Plus :size="24" /></div>
              <div>
                <h3 class="text-2xl font-black text-gray-900 tracking-tight">Create Attribute Value</h3>
                <p class="text-sm text-gray-500">Add a new allowed value to an existing product attribute.</p>
              </div>
           </div>
           
           <div class="grid grid-cols-2 gap-8">
             <div class="form-group m-0 border border-gray-200 rounded-2xl p-6 bg-gray-50/50 focus-within:bg-white focus-within:border-blue-400 transition-all shadow-sm">
               <label class="text-xs uppercase tracking-widest text-gray-400 font-black mb-3 block">Product Attribute</label>
               <select class="input w-full shadow-none border-transparent font-black text-lg bg-transparent px-0 focus:ring-0" v-model="standaloneValueForm.product_attribute_id">
                 <option value="">Choose Existing Attribute...</option>
                 <option value="1">Size Portfolio (STRING)</option>
                 <option value="2">Color Spectrum (STRING)</option>
               </select>
             </div>
             <div class="form-group m-0 border border-gray-200 rounded-2xl p-6 bg-gray-50/50 focus-within:bg-white focus-within:border-blue-400 transition-all shadow-sm">
               <label class="text-xs uppercase tracking-widest text-gray-400 font-black mb-3 block">Attribute Value String</label>
               <input type="text" class="input w-full shadow-none font-black text-2xl border-transparent bg-transparent px-0 p-0 focus:ring-0" placeholder="e.g. Extra Large" v-model="standaloneValueForm.value" />
             </div>
           </div>

           <div class="mt-8 p-6 border-2 border-dashed border-gray-200 rounded-2xl bg-gray-50/30 flex items-center justify-between group hover:bg-white hover:border-blue-300 transition-all">
              <div class="flex items-center gap-4">
                 <div class="p-3 bg-white rounded-lg shadow-sm group-hover:text-blue-600 transition-colors"><ImageIcon :size="24" /></div>
                 <div>
                    <div class="font-bold text-gray-900 text-base">Media Attachment</div>
                    <div class="text-xs text-gray-400">Link an image representing this attribute value (e.g. Color Hex Tile).</div>
                 </div>
              </div>
              <button class="px-6 py-2.5 bg-white border border-gray-300 rounded-xl hover:bg-blue-600 hover:text-white transition-all shadow-sm font-bold text-sm">Upload Attachment</button>
           </div>
         </div>
      </div>

      <!-- ============================================== -->
      <!-- FULL EXPANDED UI WIZARD (Architecture Builder) -->
      <!-- ============================================== -->
      <div v-else-if="currentView === 'create_full'" class="create-view max-w-5xl mx-auto space-y-8 mt-6">
        
        <!-- SECTION 1: MASTER NODE (Relatable to "Measurement Category") -->
        <div class="bg-white rounded-3xl shadow-xl border-t-8 border-t-blue-800 overflow-hidden border border-gray-100">
           <div class="flex items-center gap-5 p-8 border-b border-gray-100 bg-gray-50/50">
              <div class="w-14 h-14 rounded-2xl bg-blue-100 text-blue-800 flex items-center justify-center font-black text-2xl shadow-inner border border-blue-200">1</div>
              <div class="flex-1">
                <h3 class="text-2xl font-black text-gray-900 tracking-tight">Product Attribute</h3>
                <p class="text-sm text-gray-500 mb-0 font-medium font-serif italic">Establish the universal property namespace for product variations.</p>
              </div>
           </div>
           
           <div class="grid grid-cols-4 gap-8 p-10">
              <div class="form-group col-span-2 m-0 group">
                <label class="text-xs font-black uppercase tracking-widest text-gray-400 mb-3 block group-hover:text-blue-600 transition-colors">Attribute Name (e.g. Color)</label>
                <input type="text" class="input w-full text-3xl border-none shadow-none font-black bg-transparent p-0 focus:ring-0 mt-1 placeholder-gray-200" placeholder="Attribute Name..." v-model="fullForm.attribute.name" />
              </div>
              
              <div class="form-group col-span-1 m-0">
                <label class="text-xs font-black uppercase tracking-widest text-gray-400 mb-3 block">Logic Return Type</label>
                <select class="input w-full mt-2 font-mono font-bold bg-gray-100/50 text-gray-700 border-gray-200 p-3 rounded-xl focus:bg-white" v-model="fullForm.attribute.input_type">
                   <option value="text">STRING FORMAT</option>
                   <option value="number">NUMERIC DATA</option>
                   <option value="boolean">BOOLEAN BIT</option>
                </select>
              </div>

              <div class="form-group col-span-1 m-0 flex flex-col items-end">
                <span class="text-xs font-black text-gray-400 uppercase tracking-widest block mb-4 text-right">System State</span>
                <label class="toggle-switch scale-150 origin-right">
                  <input type="checkbox" v-model="fullForm.attribute.state">
                  <span class="slider bg-[#0e52a0]"></span>
                </label>
              </div>
           </div>
        </div>

        <!-- SECTION 2: VALUE MATRIX (Relatable to "Distinct Units") -->
        <div class="bg-white rounded-3xl shadow-xl border-t-8 border-t-indigo-500 overflow-hidden border border-gray-100 animate-fade" style="animation-delay: 0.1s; animation-fill-mode: both;">
           <div class="p-8 border-b border-gray-100 flex items-center justify-between bg-indigo-50/40">
              <div class="flex items-center gap-5">
                 <div class="w-14 h-14 rounded-2xl bg-indigo-100 text-indigo-800 flex items-center justify-center font-black text-2xl shadow-inner border border-indigo-200">2</div>
                 <div>
                    <h3 class="text-2xl font-black text-gray-900 tracking-tight">Allowed Attribute Values</h3>
                    <p class="text-sm text-gray-500 mb-0 font-medium">Map the allowed variations that items can inherit from this attribute.</p>
                 </div>
              </div>
              <button @click="addValueRow" class="btn-primary bg-indigo-600 hover:bg-indigo-700 flex items-center gap-2 shadow-lg scale-105 active:scale-95 transition-transform"><Plus :size="18" /> Add Attribute Value</button>
           </div>
           
           <div class="p-8 space-y-4 bg-gray-50/30 min-h-[200px]">
              <!-- Draggable Array Repeater Items -->
              <div v-for="(v, index) in fullForm.values" :key="v.id" 
                   draggable="true" @dragstart="dragStart(index)" @dragover.prevent @drop="dragDrop(index)"
                   :class="['flex items-center gap-6 p-6 bg-white border border-gray-200 shadow-sm rounded-2xl relative group transition-all', dragState === index ? 'opacity-40 border-dashed border-indigo-400 scale-[0.98]' : 'hover:border-indigo-300 hover:shadow-md']">
                 
                 <!-- Visual Grip Sort -->
                 <div class="cursor-grab hover:text-indigo-600 text-gray-300 px-2 active:cursor-grabbing"><GripVertical :size="24" /></div>
                 
                 <div class="w-14 h-14 bg-indigo-50 text-indigo-900 border border-indigo-100 rounded-xl flex flex-col items-center justify-center shadow-inner">
                    <span class="text-[9px] font-black text-indigo-400 tracking-widest uppercase mb-1">Rank</span>
                    <span class="font-black font-mono leading-none text-xl">{{ v.sort_order }}</span>
                 </div>

                 <!-- Node String Input -->
                 <div class="flex-1 form-group m-0 pb-1 border-b-2 border-gray-100 focus-within:border-indigo-500 transition-colors">
                    <input type="text" class="input w-full text-2xl font-black border-none shadow-none px-2 focus:ring-0 bg-transparent placeholder-gray-200" placeholder="Value (e.g. Red, XL, 44)..." v-model="v.value" />
                 </div>

                 <!-- Media Connector -->
                 <div class="px-6 border-l border-gray-100 pl-8 border-r pr-8 relative">
                    <button class="w-12 h-12 border-2 border-dashed border-gray-300 text-gray-400 rounded-xl flex items-center justify-center hover:bg-indigo-50 hover:border-indigo-400 hover:text-indigo-600 transition-all group/btn">
                       <ImageIcon :size="20" />
                    </button>
                    <span class="absolute -top-8 left-1/2 -translate-x-1/2 bg-gray-900 text-white text-[10px] font-black px-2.5 py-1 rounded-md opacity-0 group-hover/btn:opacity-100 pointer-events-none transition-opacity shadow-lg uppercase tracking-widest">Attachment</span>
                 </div>

                 <button @click="removeValueRow(index)" class="w-12 h-12 bg-white border border-gray-100 text-gray-300 hover:bg-red-50 hover:text-red-600 hover:border-red-200 rounded-full flex items-center justify-center shadow-sm opacity-50 group-hover:opacity-100 transition-all"><Trash2 :size="18" /></button>
              </div>

              <!-- Empty State Catch -->
              <div v-if="fullForm.values.length === 0" class="p-12 border-4 border-dashed border-gray-100 rounded-3xl text-center shadow-inner bg-white/50 flex flex-col items-center justify-center">
                 <div class="p-4 bg-gray-50 rounded-full mb-4"><ListPlus :size="48" class="text-gray-200" /></div>
                 <span class="font-black text-gray-400 uppercase tracking-widest block mb-6">No Values Added</span>
                 <button @click="addValueRow" class="btn-primary bg-indigo-600 px-8 py-3 rounded-2xl shadow-xl flex items-center gap-3 font-black text-base transition-all hover:translate-y-[-2px] uppercase tracking-wider"><Plus :size="20"/> Initialize Value Array</button>
              </div>
           </div>
        </div>

        <!-- SECTION 3: CATEGORY DEPLOYMENT (Relatable to "Conversions/Formulas") -->
        <div class="bg-white rounded-3xl shadow-xl border-t-8 border-t-emerald-600 p-0 overflow-hidden animate-fade border border-gray-100" style="animation-delay: 0.2s; animation-fill-mode: both;">
           <div class="p-8 border-b border-gray-100 flex items-center justify-between bg-emerald-50/40">
              <div class="flex items-center gap-5">
                 <div class="w-14 h-14 rounded-2xl bg-emerald-100 text-emerald-800 flex items-center justify-center font-black text-2xl shadow-inner border border-emerald-200">3</div>
                 <div>
                    <h3 class="text-2xl font-black text-gray-900 tracking-tight">Product Association</h3>
                    <p class="text-sm text-gray-500 mb-0 font-medium">Link this attribute to product categories.</p>
                 </div>
              </div>
           </div>

           <div class="p-10 grid grid-cols-2 gap-10 bg-gray-50/20">
              <div class="form-group m-0 p-8 bg-white border border-gray-200 rounded-3xl shadow-sm hover:border-emerald-300 transition-colors">
                 <label class="text-xs font-black uppercase tracking-widest text-gray-400 mb-4 block">Target Hierarchy Category</label>
                 <select class="input w-full text-lg font-black border-none bg-gray-50/50 p-4 rounded-2xl focus:bg-white transition-all shadow-inner" v-model="fullForm.assignment.category_id">
                    <option value="">Select Domain Root Category...</option>
                    <option value="1">Apparel / Clothing</option>
                    <option value="2">Cold Drinks / Beverages</option>
                    <option value="3">Raw Ingredients</option>
                 </select>
              </div>

              <div class="form-group m-0 p-8 bg-white border border-gray-200 rounded-3xl shadow-sm hover:border-emerald-300 transition-colors">
                 <label class="text-xs font-black uppercase tracking-widest text-gray-400 mb-4 block">Deployment Scope Intensity</label>
                 <div class="flex gap-4">
                    <button @click="fullForm.assignment.usage_type = 'Global'" :class="['flex-1 p-4 rounded-2xl border-2 font-black text-sm transition-all shadow-sm', fullForm.assignment.usage_type === 'Global' ? 'bg-emerald-600 border-emerald-700 text-white shadow-emerald-200' : 'bg-gray-50 border-gray-100 text-gray-400 hover:bg-white']">GLOBAL</button>
                    <button @click="fullForm.assignment.usage_type = 'Branch'" :class="['flex-1 p-4 rounded-2xl border-2 font-black text-sm transition-all shadow-sm', fullForm.assignment.usage_type === 'Branch' ? 'bg-emerald-600 border-emerald-700 text-white shadow-emerald-200' : 'bg-gray-50 border-gray-100 text-gray-400 hover:bg-white']">LOCAL ONLY</button>
                 </div>
              </div>
           </div>
        </div>

      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.org-layout { max-width: 1200px; margin: 0 auto; min-height: 100vh; padding-bottom: 5rem;}
.badge { font-weight: 700; padding: 4px 14px; border-radius: 20px; font-size: 10px; text-transform: uppercase; letter-spacing: 0.05em; }
.badge-warning { background-color: #fffbeb; color: #b45309; border: 1px solid #fef3c7; }
.badge-success { background: #ecfdf5; color: #059669; border: 1px solid #d1fae5; }
.badge-danger {  background: #fef2f2; color: #dc2626; border: 1px solid #fee2e2; }
.chip-extra { padding: 5px 12px; border-radius: 8px; font-weight: 800; font-size: 10px; box-shadow: inset 0 1px 2px rgba(0,0,0,0.05); }
.seg-tab { display: flex; align-items: center; gap: 10px; padding: 10px 20px; border-radius: 14px; font-size: 13px; font-weight: 700; color: #64748b; background: transparent; border: none; cursor: pointer; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
.seg-tab.active { background: white; color: #0f172a; shadow-sm: 0 4px 6px -1px rgb(0 0 0 / 0.1); box-shadow: 0 4px 15px -3px rgba(0,0,0,0.1); }
.search-box { position: relative; width: 340px; }
.search-input { width: 100%; padding: 12px 14px 12px 42px; border: 1px solid #e2e8f0; border-radius: 12px; font-size: 14px; outline: none; transition: all 0.2s; background: white; }
.search-input:focus { border-color: #3b82f6; box-shadow: 0 0 0 4px rgba(59,130,246, 0.1); }
.search-icon { position: absolute; left: 16px; top: 50%; transform: translateY(-50%); color: #94a3b8; }
.btn-primary { padding: 10px 24px; background: #0056b3; color: white; border: none; border-radius: 12px; font-size: 14px; font-weight: 700; cursor: pointer; transition: all 0.2s; }
.btn-primary:hover { background: #004494; transform: translateY(-1px); box-shadow: 0 4px 12px rgba(0,86,179, 0.3); }
.form-group label { display: block; font-size: 12px; font-weight: 700; color: #64748b; margin-bottom: 8px; }
.input { border: 1px solid #e2e8f0; padding: 12px 16px; border-radius: 12px; font-size: 15px; outline: none; background: white; transition: all 0.2s; }
.input:focus { border-color: #3b82f6; box-shadow: 0 0 0 4px rgba(59,130,246, 0.1); }
.section-title { font-weight: 900; color: #0f172a; margin-bottom: 6px; letter-spacing: -0.025em; }
.toggle-switch { position: relative; display: inline-block; width: 44px; height: 24px; }
.toggle-switch input { opacity: 0; width: 0; height: 0; }
.slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #e2e8f0; transition: .4s cubic-bezier(0.4, 0, 0.2, 1); border-radius: 34px; }
.slider:before { position: absolute; content: ""; height: 18px; width: 18px; left: 3px; bottom: 3px; background-color: white; transition: .4s cubic-bezier(0.4, 0, 0.2, 1); border-radius: 50%; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
input:checked + .slider { background-color: #10b981; }
input:checked + .slider:before { transform: translateX(20px); }
.animate-fade { animation: fadeIn 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
.animate-spring { animation: springIn 0.6s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards; }
@keyframes springIn { from { opacity: 0; transform: scale(0.9) translateY(30px); } to { opacity: 1; transform: scale(1) translateY(0); } }

/* Advanced Table Scoping */
.table-responsive::-webkit-scrollbar { height: 6px; }
.table-responsive::-webkit-scrollbar-thumb { background: #e2e8f0; border-radius: 10px; }
</style>
