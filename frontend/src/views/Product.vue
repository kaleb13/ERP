<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, Search, Filter, ArrowUpDown, Plus, MoreVertical, 
  ShoppingBag, CheckCircle, Package, Columns, Tag, Scale, Settings
} from 'lucide-vue-next';

// View State Management
const currentView = ref('list'); // 'list' or 'create'
const formTab = ref('basic'); // 'basic', 'behavior', 'inventory', 'pricing', 'brands', 'measurements', 'variants'

// Dummy Data exactly mapped to User Request
const productList = [
  { id: 1, code: 'PRD-001', name: 'Premium Coffee Beans', item: 'Coffee (Goods)', type: 'Direct Sale', trackStock: true, status: 'Active' },
  { id: 2, code: 'PRD-002', name: 'Barista Service Package', item: 'Service', type: 'Combo', trackStock: false, status: 'Active' },
  { id: 3, code: 'PRD-003', name: 'Almond Milk (1L)', item: 'Milk Base (Goods)', type: 'Direct Sale', trackStock: true, status: 'Inactive' }
];

// Master Product Schema Definition
const form = ref({
  // Basic Info
  name: '',
  code: '',
  item_id: '',
  entity_id: '',
  color: '#000000',
  
  // Behavior Settings
  product_type: 'Direct Sale',
  registration_type: 'Both',
  is_fixed_asset: false,
  has_serial_number: false,
  has_warranty: false,
  has_variant: false,
  
  // Inventory Rules
  track_stock: true,
  track_batch: false,
  track_expiry: false,
  is_transferable: true,
  
  // Pricing & Tax
  is_tax_included: false,
  costing_rule: 'FIFO',
  
  // Array Multi-selections
  allowed_brands: [] as string[],
  allowed_measurements: [] as string[],
  variants: [{ attribute: 'Size', values: '' }]
});

// Helper for dynamic UI variants array
const addVariantRow = () => {
  form.value.variants.push({ attribute: '', values: '' });
};

</script>

<template>
  <DashboardLayout>
    <div class="org-layout">
      <!-- Breadcrumb Bar -->
      <div class="breadcrumb-bar flex items-center justify-between mb-4">
        <div class="breadcrumb flex items-center gap-2 text-xs text-gray-500">
          <Monitor :size="14" />
          <ChevronRight :size="12" class="text-gray-300" />
          <span class="text-gray-700 font-medium cursor-pointer hover:text-blue-600" @click="currentView = 'list'">Products</span>
          
          <template v-if="currentView === 'create'">
            <ChevronRight :size="12" class="text-gray-300" />
            <span class="text-gray-700 font-medium">Create Product</span>
            <span class="badge-warning ml-2">Not Saved</span>
          </template>
        </div>

        <div class="top-actions" v-if="currentView === 'create'">
          <button class="btn-primary flex items-center gap-2" @click="currentView = 'list'">
            <CheckCircle :size="14" /> Save Product
          </button>
        </div>
      </div>

      <!-- LIST VIEW -->
      <div v-if="currentView === 'list'">
        <!-- Header Section -->
        <div class="page-container p-6 bg-white rounded-xl shadow-sm border border-gray-200 mb-6">
          <div class="page-header">
            <h2 class="text-xl font-bold text-gray-900 mb-1">Product Management</h2>
            <p class="text-sm text-gray-500 m-0">Define your primary operational product listings globally accessible through POS, Sales, and Purchase.</p>
          </div>
        </div>

        <!-- Main Product Table Section -->
        <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
          <!-- Toolbar -->
          <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between">
            <div class="toolbar-left flex gap-3">
              <div class="search-box">
                <Search :size="16" class="search-icon" />
                <input type="text" placeholder="Search products..." class="search-input" />
              </div>
              <button class="btn-outline flex items-center gap-2">
                <Filter :size="14" /> Filters
              </button>
            </div>
            <div class="toolbar-right">
              <button class="btn-primary flex items-center gap-2" @click="currentView = 'create'">
                <Plus :size="14" /> Create Product
              </button>
            </div>
          </div>

          <!-- Product Data Table -->
          <div class="table-responsive">
            <table class="w-full text-left text-sm text-gray-700">
              <thead class="text-xs text-gray-500 border-b border-gray-100">
                <tr>
                  <th class="px-6 py-4 font-semibold">Product Name</th>
                  <th class="px-6 py-4 font-semibold">General Item Link</th>
                  <th class="px-6 py-4 font-semibold">Sales Type</th>
                  <th class="px-6 py-4 font-semibold">Global Stock Track</th>
                  <th class="px-6 py-4 font-semibold">State</th>
                  <th class="px-6 py-4 font-semibold text-right">Action</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="w in productList" :key="w.id" class="border-b border-gray-50 hover:bg-gray-50">
                  <td class="px-6 py-4">
                    <div class="font-medium text-gray-900">{{ w.name }}</div>
                    <div class="text-xs text-gray-400 font-mono mt-1">{{ w.code }}</div>
                  </td>
                  <td class="px-6 py-4 text-gray-500 flex items-center gap-2">
                    <Package :size="14" class="text-gray-400" /> {{ w.item }}
                  </td>
                  <td class="px-6 py-4 font-medium">{{ w.type }}</td>
                  <td class="px-6 py-4">
                    <span v-if="w.trackStock" class="chip">Tracked</span>
                    <span v-else class="chip-extra">Bypassed</span>
                  </td>
                  <td class="px-6 py-4">
                    <span :class="['badge', w.status === 'Active' ? 'badge-success' : 'badge-danger']">{{ w.status }}</span>
                  </td>
                  <td class="px-6 py-4 text-right">
                    <button class="text-gray-400 hover:text-gray-600"><MoreVertical :size="16" /></button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Pagination Footer -->
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

      <!-- CREATE VIEW MULTI-TAB ARCHITECTURE -->
      <div v-else class="create-view">
        <div class="flex gap-6">
          
          <!-- Product Creation Vertical Tab Menu -->
          <div class="w-64 flex-shrink-0">
            <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-2 flex flex-col gap-1 sticky top-6">
              <button :class="['tab-btn', { active: formTab === 'basic' }]" @click="formTab = 'basic'">
                <ShoppingBag :size="16" /> Basic Profile
              </button>
              <button :class="['tab-btn', { active: formTab === 'behavior' }]" @click="formTab = 'behavior'">
                <Settings :size="16" /> Behavior Config
              </button>
              <button :class="['tab-btn', { active: formTab === 'inventory' }]" @click="formTab = 'inventory'">
                <Columns :size="16" /> Inventory Rules
              </button>
              <button :class="['tab-btn', { active: formTab === 'pricing' }]" @click="formTab = 'pricing'">
                <Box :size="16" /> Pricing & Tax
              </button>
              <button :class="['tab-btn', { active: formTab === 'brands' }]" @click="formTab = 'brands'">
                <Tag :size="16" /> Authorized Brands
              </button>
              <button :class="['tab-btn', { active: formTab === 'measurements' }]" @click="formTab = 'measurements'">
                <Scale :size="16" /> Measurements
              </button>
              <button v-if="form.has_variant" :class="['tab-btn', { active: formTab === 'variants' }]" @click="formTab = 'variants'">
                <Layers :size="16" /> Variations Grid
              </button>
            </div>
          </div>

          <!-- Product Tab Forms Container -->
          <div class="flex-1 bg-white rounded-xl shadow-sm border border-gray-200 p-8">
            
            <!-- Tab 1: Basic Info -->
            <div v-show="formTab === 'basic'" class="animate-fade">
              <h3 class="text-lg font-bold text-gray-900 mb-6 border-b pb-2">Basic Profile</h3>
              <div class="grid grid-cols-2 gap-6">
                <div class="form-group col-span-2">
                  <label>Product Name</label>
                  <input type="text" class="input w-full text-lg font-medium" placeholder="E.g. iPhone 15 Pro Max" v-model="form.name" />
                </div>
                <div class="form-group">
                  <label>System Code</label>
                  <input type="text" class="input w-full font-mono text-xs" placeholder="SYS-PRD-000X" v-model="form.code" />
                </div>
                <div class="form-group">
                  <label>Core Item Linkage</label>
                  <select class="input w-full" v-model="form.item_id">
                    <option value="">Search Master Item...</option>
                    <option value="1">Electronics Layer</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Tenant Entity Scope</label>
                  <select class="input w-full" v-model="form.entity_id">
                    <option value="">Global Network</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Visual UI Color Identifier</label>
                  <input type="color" class="input h-10 w-full p-1 rounded-md" v-model="form.color" />
                </div>
              </div>
            </div>

            <!-- Tab 2: Behaviors -->
            <div v-show="formTab === 'behavior'" class="animate-fade">
              <h3 class="text-lg font-bold text-gray-900 mb-6 border-b pb-2">Behavior System</h3>
              <div class="grid grid-cols-2 gap-6">
                <div class="form-group">
                  <label>Product Type Mechanism</label>
                  <select class="input w-full font-semibold" v-model="form.product_type">
                    <option value="Direct Sale">Direct Sale</option>
                    <option value="Bundle">Bundle</option>
                    <option value="Combo">Combo</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Registration Paradigm</label>
                  <select class="input w-full" v-model="form.registration_type">
                    <option value="Both">Both (Purchase & Sale)</option>
                    <option value="Sales Only">Sales Only</option>
                    <option value="Purchases Only">Purchases Only</option>
                  </select>
                </div>
              </div>
              <div class="mt-8 flex flex-col gap-4">
                <div class="flex items-center justify-between p-3 border rounded-lg bg-gray-50">
                  <div class="text-sm font-semibold">Treat as Fixed Asset <div class="text-xs text-gray-500 font-normal">Calculates depreciation and hardware tracking.</div></div>
                  <label class="toggle-switch"><input type="checkbox" v-model="form.is_fixed_asset"><span class="slider"></span></label>
                </div>
                <div class="flex items-center justify-between p-3 border rounded-lg bg-gray-50">
                  <div class="text-sm font-semibold">Requires Serial Number Registration <div class="text-xs text-gray-500 font-normal">Enforce strict per-unit barcoding upon receipt.</div></div>
                  <label class="toggle-switch"><input type="checkbox" v-model="form.has_serial_number"><span class="slider"></span></label>
                </div>
                <div class="flex items-center justify-between p-3 border rounded-lg bg-gray-50">
                  <div class="text-sm font-semibold">Is Product Warranted <div class="text-xs text-gray-500 font-normal">Generates digital warranty contract on dispatch.</div></div>
                  <label class="toggle-switch"><input type="checkbox" v-model="form.has_warranty"><span class="slider"></span></label>
                </div>
                
                <!-- Magic Toggle That Exposes Tab 7 -->
                <div class="flex items-center justify-between p-3 border-2 border-blue-100 rounded-lg bg-blue-50 mt-4">
                  <div class="text-sm font-bold text-blue-900">Enable Complex Variants <div class="text-xs text-blue-700 font-normal mt-1">Activate dimensional matrices (Color, Size, Material). This opens the Variation Grid setup.</div></div>
                  <label class="toggle-switch"><input type="checkbox" v-model="form.has_variant"><span class="slider"></span></label>
                </div>
              </div>
            </div>

            <!-- Tab 3: Inventory -->
            <div v-show="formTab === 'inventory'" class="animate-fade">
              <h3 class="text-lg font-bold text-gray-900 mb-6 border-b pb-2">Inventory Physics</h3>
              <div v-if="!form.track_stock" class="p-4 bg-orange-50 border border-orange-200 rounded-lg mb-6 text-sm text-orange-800 flex gap-2 items-center font-medium">
                Warehouse validation is bypassed because Track Global Stock is off!
              </div>

              <div class="flex flex-col gap-4">
                <div class="flex items-center justify-between p-3 border rounded-lg">
                  <div class="text-sm font-semibold">Track Global Stock <div class="text-xs text-gray-500 font-normal">Affect physical inventory counts and availability grids.</div></div>
                  <label class="toggle-switch"><input type="checkbox" v-model="form.track_stock"><span class="slider"></span></label>
                </div>

                <template v-if="form.track_stock">
                  <div class="flex items-center justify-between p-3 border rounded-lg ml-6 relative before:absolute before:-left-4 before:top-6 before:w-4 before:h-px before:bg-gray-300">
                    <div class="text-sm font-semibold">Track Logistic Batch <div class="text-xs text-gray-500 font-normal">Trace distinct manufacturing lot metrics.</div></div>
                    <label class="toggle-switch"><input type="checkbox" v-model="form.track_batch"><span class="slider"></span></label>
                  </div>
                  <div class="flex items-center justify-between p-3 border rounded-lg ml-6 relative before:absolute before:-left-4 before:top-6 before:w-4 before:h-px before:bg-gray-300">
                    <div class="text-sm font-semibold">Strict Expiry Management <div class="text-xs text-gray-500 font-normal">System rejects distribution of items past expiry threshold.</div></div>
                    <label class="toggle-switch"><input type="checkbox" v-model="form.track_expiry"><span class="slider"></span></label>
                  </div>
                  <div class="flex items-center justify-between p-3 border rounded-lg ml-6 relative before:absolute before:-left-4 before:top-6 before:w-4 before:h-px before:bg-gray-300">
                    <div class="text-sm font-semibold">Permit Internal Transfer <div class="text-xs text-gray-500 font-normal">Can be moved between internal network stores safely.</div></div>
                    <label class="toggle-switch"><input type="checkbox" v-model="form.is_transferable"><span class="slider"></span></label>
                  </div>
                </template>
              </div>
            </div>

            <!-- Tab 4: Pricing -->
            <div v-show="formTab === 'pricing'" class="animate-fade">
              <h3 class="text-lg font-bold text-gray-900 mb-6 border-b pb-2">Financial Blueprint</h3>
              <div class="grid grid-cols-2 gap-6">
                <div class="form-group flex flex-col justify-center gap-2">
                  <label>Base Price Registration Mode</label>
                  <div class="flex items-center gap-3">
                    <label class="toggle-switch"><input type="checkbox" v-model="form.is_tax_included"><span class="slider"></span></label>
                    <span class="text-sm font-semibold text-gray-700">{{ form.is_tax_included ? "Listed Inclusive of Universal Tax" : "Tax Computed Exceptionally at POS" }}</span>
                  </div>
                </div>
                <div class="form-group">
                  <label>Costing Algorithm</label>
                  <select class="input w-full font-mono text-sm" v-model="form.costing_rule">
                    <option value="FIFO">First In, First Out (FIFO)</option>
                    <option value="LIFO">Last In, First Out (LIFO)</option>
                    <option value="MOVING_AVERAGE">Moving Average Cost</option>
                    <option value="STANDARD">Standard Fixed Default Cost</option>
                  </select>
                </div>
              </div>
            </div>

            <!-- Tab 5: Brands -->
            <div v-show="formTab === 'brands'" class="animate-fade">
              <h3 class="text-lg font-bold text-gray-900 mb-4 border-b pb-2">Brand Constraints</h3>
              <p class="text-sm text-gray-500 mb-6">Select which registered brands can technically manufacture or supply this specific product template.</p>
              
              <div class="flex gap-4 mb-4">
                <!-- Multi-select visual dummy representation -->
                <label class="flex items-center gap-3 p-4 border rounded-xl cursor-pointer hover:bg-gray-50 flex-1">
                  <input type="checkbox" checked class="w-4 h-4 text-blue-600 rounded">
                  <span class="font-medium">Apple Inc.</span>
                </label>
                <label class="flex items-center gap-3 p-4 border rounded-xl cursor-pointer hover:bg-gray-50 flex-1">
                  <input type="checkbox" class="w-4 h-4 text-blue-600 rounded">
                  <span class="font-medium">Samsung Group</span>
                </label>
              </div>
            </div>

            <!-- Tab 6: Measurements -->
            <div v-show="formTab === 'measurements'" class="animate-fade">
              <h3 class="text-lg font-bold text-gray-900 mb-4 border-b pb-2">Operational Dimensions</h3>
              <p class="text-sm text-gray-500 mb-6">Authorize which universal units of volume or weight are strictly acceptable during transactions.</p>
              
              <div class="grid grid-cols-3 gap-3">
                <label class="flex items-center gap-3 p-3 border rounded-lg cursor-pointer hover:bg-blue-50 border-blue-200">
                  <input type="checkbox" checked class="w-4 h-4 text-blue-600">
                  <div class="flex flex-col"><span class="font-semibold text-sm">Piece</span><span class="text-xs text-gray-400">pcs</span></div>
                </label>
                <label class="flex items-center gap-3 p-3 border rounded-lg cursor-pointer hover:bg-gray-50">
                  <input type="checkbox" class="w-4 h-4 text-blue-600">
                  <div class="flex flex-col"><span class="font-semibold text-sm">Kilogram</span><span class="text-xs text-gray-400">kg</span></div>
                </label>
                <label class="flex items-center gap-3 p-3 border rounded-lg cursor-pointer hover:bg-gray-50">
                  <input type="checkbox" class="w-4 h-4 text-blue-600">
                  <div class="flex flex-col"><span class="font-semibold text-sm">Liter</span><span class="text-xs text-gray-400">L</span></div>
                </label>
              </div>
            </div>

            <!-- Tab 7: Variants Grid -->
            <div v-show="formTab === 'variants' && form.has_variant" class="animate-fade">
              <h3 class="text-lg font-bold text-blue-900 mb-4 border-b pb-2 border-blue-100">Variation Matrix Array</h3>
              <p class="text-sm text-gray-500 mb-6">Build property arrays natively. The system automatically creates discrete unified products across grid iterations.</p>
              
              <div class="bg-gray-50 p-4 border rounded-xl space-y-4">
                <div class="flex gap-4 items-end" v-for="(v, index) in form.variants" :key="index">
                  <div class="form-group flex-1 m-0">
                    <label>Attribute Array Key</label>
                    <input type="text" class="input w-full font-bold" placeholder="E.g. Size" v-model="v.attribute" />
                  </div>
                  <div class="form-group flex-[2] m-0">
                    <label>Value Scope (Comma separated)</label>
                    <input type="text" class="input w-full font-mono text-sm shadow-inner" placeholder="E.g. Small, Medium, Large" v-model="v.values" />
                  </div>
                </div>
                <button class="text-sm font-semibold text-blue-600 hover:text-blue-800 flex items-center gap-1 mt-4" @click="addVariantRow">
                  <Plus :size="14" /> Attach Nested Attribute Level
                </button>
              </div>
            </div>

          </div>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.org-layout {
  max-width: 1200px;
  margin: 0 auto;
}
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

.page-btn { padding: 6px 12px; background: white; border: none; border-right: 1px solid #e5e5e5; color: #374151; cursor: pointer; font-size: 13px; }
.page-btn:last-child { border-right: none; }
.page-btn:hover { background: #f9fafb; }
.page-btn.active { background: #0056b3; color: white; font-weight: 500; }

/* Tabs Array Form UX */
.tab-btn {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  width: 100%;
  border: none;
  background: white;
  border-radius: 8px;
  text-align: left;
  font-size: 14px;
  font-weight: 600;
  color: #6b7280;
  cursor: pointer;
  transition: all 0.2s ease;
}
.tab-btn:hover { background: #f9fafb; color: #374151; }
.tab-btn.active {
  background: #eff6ff;
  color: #1d4ed8;
}

/* Base Form Standard UX */
.form-group label { display: block; font-size: 12px; font-weight: 600; color: #4b5563; margin-bottom: 6px; }
.input { border: 1px solid #e5e5e5; padding: 10px 12px; border-radius: 8px; font-size: 14px; outline: none; background: white; transition: border 0.3s; }
.input:focus { border-color: #0056b3; box-shadow: 0 0 0 3px rgba(0,86,179, 0.1); }

/* Standard OS Toggle Switch */
.toggle-switch { position: relative; display: inline-block; width: 44px; height: 24px; }
.toggle-switch input { opacity: 0; width: 0; height: 0; }
.slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #d1d5db; transition: .4s; border-radius: 34px; }
.slider:before { position: absolute; content: ""; height: 18px; width: 18px; left: 3px; bottom: 3px; background-color: white; transition: .4s; border-radius: 50%; box-shadow: 0 1px 2px rgba(0,0,0,0.1); }
input:checked + .slider { background-color: #0056b3; }
input:checked + .slider:before { transform: translateX(20px); }

.animate-fade { animation: fadeIn 0.3s ease-in-out; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(5px); } to { opacity: 1; transform: translateY(0); } }
</style>
