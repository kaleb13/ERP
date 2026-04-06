<script setup lang="ts">
import { ref } from 'vue';
import { 
  Warehouse as WarehouseIcon, Layers, Box, ChevronRight, Plus, Search, 
  Settings, Info, MapPin, ArrowRight, Package
} from 'lucide-vue-next';
import HaletaHeader from '../components/HaletaHeader.vue';

const currentView = ref<'list' | 'create' | 'detail'>('list');
const selectedWarehouse = ref<any>(null);

// SCHEMA DEFINITIONS
const warehouseTypes = [
  { id: 1, name: 'Central Warehouse', code: 'central' },
  { id: 2, name: 'Store Backroom', code: 'store_backroom' },
  { id: 3, name: 'Kitchen Store', code: 'kitchen_store' },
  { id: 4, name: 'Cold Storage', code: 'cold_storage' },
  { id: 5, name: 'Wastage Storage', code: 'wastage_storage' },
  { id: 6, name: 'Transit Storage', code: 'transit_storage' }
];

const form = ref({
  name: '',
  admin_unit_id: '',
  warehouse_type_id: '',
  longitude: '',
  latitude: '',
  scope: 'branch', // e.g., branch, shop, org
  scope_id: '',
  warehouse_id: '', // parent
  is_group: false,
  level: 1,
  has_shelf: false,
  has_bin: false,
  state: 'active'
});

const warehouses = ref([
  { 
    id: 1, 
    name: 'Main Central Hub', 
    warehouse_type_id: 1,
    scope: 'organization',
    location: 'HQ Sector',
    has_shelf: true,
    has_bin: true,
    shelves: [
      { id: 10, name: 'Shelf A', tag: 'A', pins: [{ code: 'A1', name: 'Beverages' }, { code: 'A2', name: 'Snacks' }] }
    ]
  },
  { 
    id: 2, 
    name: 'Bole Kitchen Store', 
    warehouse_type_id: 3,
    scope: 'shop',
    location: 'Bole Branch',
    has_shelf: false,
    has_bin: false,
    shelves: []
  }
]);

const getTypeName = (id: number) => warehouseTypes.find(t => t.id == id)?.name || 'Unknown';

const viewWarehouse = (wh: any) => {
  selectedWarehouse.value = wh;
  currentView.value = 'detail';
};

const openCreate = () => {
  form.value = {
    name: '', admin_unit_id: '', warehouse_type_id: '', longitude: '', latitude: '',
    scope: 'branch', scope_id: '', warehouse_id: '', is_group: false, level: 1,
    has_shelf: false, has_bin: false, state: 'active'
  };
  currentView.value = 'create';
};

const saveWarehouse = () => {
  warehouses.value.push({
    id: Date.now(),
    name: form.value.name,
    warehouse_type_id: Number(form.value.warehouse_type_id),
    scope: form.value.scope,
    location: 'New Location',
    has_shelf: form.value.has_shelf,
    has_bin: form.value.has_bin,
    shelves: []
  });
  currentView.value = 'list';
};
</script>

<template>
  <div class="warehouse-manager">
    <!-- TOP NAV (Standardized) -->
    <HaletaHeader 
      :breadcrumbs="[
        { label: 'Home', onClick: () => currentView = 'list' },
        { label: currentView === 'list' ? 'Warehouses' : (currentView === 'detail' ? selectedWarehouse.name : 'Declare Warehouse'), isCurrent: true }
      ]"
      :statusBadge="currentView === 'create' ? 'Not Saved' : ''"
    >
      <template #actions>
        <button v-if="currentView === 'list'" class="btn btn-primary" @click="openCreate"><Plus :size="14" /> New Warehouse</button>
        <button v-else-if="currentView === 'create'" class="btn btn-primary" @click="saveWarehouse">Save Configuration</button>
      </template>
    </HaletaHeader>

    <!-- LIST VIEW -->
    <div v-if="currentView === 'list'" class="view-list px-lg">
      <div class="grid-layout">
        <div v-for="wh in warehouses" :key="wh.id" class="card wh-card" @click="viewWarehouse(wh)">
          <div class="wh-header">
            <div class="wh-icon">
              <WarehouseIcon :size="20" />
            </div>
            <div class="wh-badge">{{ getTypeName(wh.warehouse_type_id) }}</div>
          </div>
          <div class="wh-body">
            <h3 class="h3">{{ wh.name }}</h3>
            <p class="text-xs text-muted flex-center mt-xs">
              <MapPin :size="12" class="mr-xs" /> Scope: <strong class="ml-1 uppercase">{{ wh.scope }}</strong>
            </p>
          </div>
          <div class="wh-footer">
            <div class="stat">
              <span class="val">{{ wh.shelves.length }}</span>
              <span class="lbl">Shelves</span>
            </div>
            <ArrowRight :size="16" class="text-muted" />
          </div>
        </div>
      </div>
    </div>

    <!-- CREATE FORM VIEW -->
    <div v-else-if="currentView === 'create'" class="view-create px-lg">
      <div class="card p-lg max-w-4xl mx-auto">
        <h2 class="h2 mb-md border-b pb-sm">Warehouse Declaration</h2>
        
        <div class="grid grid-cols-2 gap-x-8 gap-y-6">
          <div class="form-group">
            <label class="form-label text-xs">Warehouse Name <span class="text-red-500">*</span></label>
            <input v-model="form.name" type="text" class="input w-full" placeholder="e.g. Main Distribution Center" />
          </div>
          
          <div class="form-group">
            <label class="form-label text-xs">Warehouse Type <span class="text-red-500">*</span></label>
            <select v-model="form.warehouse_type_id" class="input w-full font-bold text-slate-700 bg-slate-50">
              <option value="" disabled>Select Type</option>
              <option v-for="t in warehouseTypes" :key="t.id" :value="t.id">{{ t.name }} ({{ t.code }})</option>
            </select>
          </div>
          
          <div class="form-group">
            <label class="form-label text-xs">Operational Scope</label>
            <select v-model="form.scope" class="input w-full">
              <option value="organization">Organization Level</option>
              <option value="branch">Branch Level</option>
              <option value="shop">Shop Level</option>
            </select>
          </div>

          <div class="form-group">
            <label class="form-label text-xs">Administrative Unit ID</label>
            <input v-model="form.admin_unit_id" type="text" class="input w-full" placeholder="Link to HR/Admin unit" />
          </div>

          <div class="col-span-2 grid grid-cols-2 gap-8 border-t pt-4">
             <div class="form-group">
                <label class="form-label text-xs">Geolocation: Latitude (Optional)</label>
                <input v-model="form.latitude" type="text" class="input w-full" placeholder="e.g. 9.0222" />
             </div>
             <div class="form-group">
                <label class="form-label text-xs">Geolocation: Longitude (Optional)</label>
                <input v-model="form.longitude" type="text" class="input w-full" placeholder="e.g. 38.7468" />
             </div>
          </div>

          <!-- Hierarchy & Structure Config -->
          <div class="col-span-2 card bg-slate-50 p-md mt-4 border border-slate-200">
             <h4 class="text-sm font-bold mb-4 uppercase text-slate-500 flex items-center gap-2">
               <Settings :size="14" /> Storage Topology & Config
             </h4>
             <div class="grid grid-cols-2 gap-8">
                <div class="config-toggle-item flex justify-between items-center bg-white p-3 rounded-md border">
                   <div>
                      <div class="text-sm font-bold">Group Warehouse</div>
                      <div class="text-xs text-muted">Acts as a parent container for other warehouses</div>
                   </div>
                   <input type="checkbox" v-model="form.is_group" />
                </div>
                
                <div class="config-toggle-item flex justify-between items-center bg-white p-3 rounded-md border">
                   <div>
                      <div class="text-sm font-bold">Parent Warehouse</div>
                      <div class="text-xs text-muted">Nest this under a group warehouse</div>
                   </div>
                   <select v-model="form.warehouse_id" class="input w-32 border-none bg-slate-50 text-xs">
                      <option value="">None</option>
                      <!-- Example parent list -->
                      <option value="1">Main Central Hub</option>
                   </select>
                </div>

                <div class="config-toggle-item flex justify-between items-center bg-white p-3 rounded-md border">
                   <div>
                      <div class="text-sm font-bold">Enable Shelves</div>
                      <div class="text-xs text-muted">Activate internal shelf management</div>
                   </div>
                   <input type="checkbox" v-model="form.has_shelf" />
                </div>

                <div class="config-toggle-item flex justify-between items-center bg-white p-3 rounded-md border">
                   <div>
                      <div class="text-sm font-bold">Enable Bins</div>
                      <div class="text-xs text-muted">Activate granular bin-level tracking</div>
                   </div>
                   <input type="checkbox" v-model="form.has_bin" />
                </div>
             </div>
          </div>

        </div>
      </div>
    </div>

    <!-- DETAIL VIEW -->
    <div v-else-if="currentView === 'detail'" class="view-detail px-lg">
      <button class="btn btn-outline mb-lg" @click="currentView = 'list'">Back to List</button>
      
      <div class="doc-layout">
        <!-- Sidebar Config -->
        <div class="doc-side">
           <div class="card p-md sticky-top">
              <h4 class="text-xs text-muted font-bold uppercase mb-md">Warehouse Config</h4>
              <div class="config-item">
                 <div class="label">Has Shelves</div>
                 <div class="toggle" :class="{ active: selectedWarehouse.has_shelf }"></div>
              </div>
              <div class="config-item">
                 <div class="label">Has Bins</div>
                 <div class="toggle" :class="{ active: selectedWarehouse.has_bin }"></div>
              </div>
           </div>
        </div>

        <!-- Main Content -->
        <div class="doc-main">
           <div class="card mb-lg">
              <div class="card-header border-b px-lg py-md flex-between">
                 <h3 class="h3">Storage Organization</h3>
                 <button class="btn btn-outline btn-xs"><Plus :size="12" /> Add Shelf</button>
              </div>
              
                  <div v-if="selectedWarehouse.shelves.length > 0" class="shelf-list p-lg">
                     <div v-for="shelf in selectedWarehouse.shelves" :key="shelf.id" class="shelf-item card mb-4">
                        <div class="shelf-header">
                           <Layers :size="16" class="text-primary" />
                           <span class="font-bold">{{ shelf.name }} (Tag: {{ shelf.tag }})</span>
                        </div>
                        <div v-if="selectedWarehouse.has_bin" class="bin-grid">
                           <div v-for="bin in shelf.pins" :key="bin.code" class="bin-item">
                              <Box :size="14" class="text-muted mr-xs" /> 
                              <div class="flex flex-col text-left">
                                <span class="font-bold">{{ bin.code }}</span>
                                <span class="text-[10px] text-muted">{{ bin.name }}</span>
                              </div>
                           </div>
                           <button class="btn-add-bin"><Plus :size="12" /> Add Bin</button>
                        </div>
                     </div>
                  </div>

                  <div v-else class="empty-state">
                    <Package :size="48" class="text-muted mb-md" />
                    <p class="text-muted">No shelves or bins configured for this warehouse.</p>
                  </div>
               </div>
            </div>
         </div>
      </div>
    </div>
</template>

<style scoped>
.warehouse-manager { padding-bottom: 40px; }
.px-lg { padding-left: 24px; padding-right: 24px; }
.sticky-top { position: sticky; top: 100px; }

.sticky-top { position: sticky; top: 100px; }


.grid-layout {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 20px;
}

.wh-card {
  padding: 0;
  cursor: pointer;
  transition: all 0.2s;
}
.wh-card:hover { transform: translateY(-3px); box-shadow: var(--shadow-md); border-color: var(--color-primary); }

.wh-header { display: flex; justify-content: space-between; align-items: start; padding: 16px; }
.wh-icon { width: 40px; height: 40px; background: #f0f0fd; color: var(--color-primary); display: flex; align-items: center; justify-content: center; border-radius: 8px; }
.wh-badge { padding: 4px 10px; background: var(--color-bg); border-radius: 20px; font-size: 10px; font-weight: 800; text-transform: uppercase; color: var(--color-text-muted); }

.wh-body { padding: 0 16px 16px 16px; }
.wh-footer { padding: 12px 16px; background: #fafafa; display: flex; justify-content: space-between; align-items: center; border-top: 1px solid #f1f3f4; border-radius: 0 0 6px 6px; }
.stat { display: flex; flex-direction: column; }
.stat .val { font-weight: 800; font-size: 18px; }
.stat .lbl { font-size: 10px; color: var(--color-text-muted); text-transform: uppercase; }

/* DETAIL VIEW */
.doc-layout { display: grid; grid-template-columns: 240px 1fr; gap: 24px; align-items: start; }

.config-item { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.config-item .label { font-size: 13px; font-weight: 500; }
.toggle { width: 32px; height: 18px; border-radius: 20px; background: #ddd; position: relative; }
.toggle.active { background: var(--color-success); }
.toggle::after { content: ''; position: absolute; top: 2px; left: 2px; width: 14px; height: 14px; background: white; border-radius: 50%; transition: all 0.2s; }
.toggle.active::after { left: 16px; }

.shelf-item { margin-bottom: 16px; padding: 16px; }
.shelf-header { display: flex; align-items: center; gap: 10px; margin-bottom: 16px; }
.bin-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(80px, 1fr)); gap: 10px; }
.bin-item { padding: 6px; background: #f8f9fa; border: 1px solid #eee; border-radius: 4px; font-size: 12px; text-align: center; display: flex; align-items: center; justify-content: center; }
.btn-add-bin { border: 1px dashed #ccc; background: transparent; border-radius: 4px; display: flex; align-items: center; justify-content: center; color: #999; }

.empty-state { text-align: center; padding: 60px 0; }

.flex-center { display: flex; align-items: center; }
.mr-xs { margin-right: 4px; }
.mt-xs { margin-top: 4px; }
</style>
