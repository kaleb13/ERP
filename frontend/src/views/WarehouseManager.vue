<script setup lang="ts">
import { ref } from 'vue';
import { 
  Warehouse, Layers, Box, ChevronRight, Plus, Search, 
  Settings, Info, MapPin, ArrowRight, Package, Monitor
} from 'lucide-vue-next';
import HaletaHeader from '../components/HaletaHeader.vue';

const currentView = ref<'list' | 'detail'>('list');
const selectedWarehouse = ref<any>(null);

const warehouses = ref([
  { 
    id: 1, 
    name: 'Main Central Warehouse', 
    type: 'Central',
    location: 'Addis Ababa',
    has_shelf: true,
    has_bin: true,
    shelves: [
      { id: 10, name: 'Shelf A', pins: ['A1', 'A2', 'A3'] },
      { id: 11, name: 'Shelf B', pins: ['B1', 'B2'] }
    ]
  },
  { 
    id: 2, 
    name: 'Kitchen Store', 
    type: 'Kitchen',
    location: 'Bole Branch',
    has_shelf: false,
    has_bin: false,
    shelves: []
  }
]);

const viewWarehouse = (wh: any) => {
  selectedWarehouse.value = wh;
  currentView.value = 'detail';
};
</script>

<template>
  <div class="warehouse-manager">
    <!-- TOP NAV (Standardized) -->
    <HaletaHeader 
      :icon="Warehouse" 
      :breadcrumbs="[
        { label: 'Home', onClick: () => currentView = 'list' },
        { label: currentView === 'list' ? 'Warehouses' : selectedWarehouse.name, isCurrent: true }
      ]"
    >
      <template #actions>
        <button v-if="currentView === 'list'" class="btn btn-primary"><Plus :size="14" /> New Warehouse</button>
      </template>
    </HaletaHeader>

    <!-- LIST VIEW -->
    <div v-if="currentView === 'list'" class="view-list px-lg">
      <div class="grid-layout">
        <div v-for="wh in warehouses" :key="wh.id" class="card wh-card" @click="viewWarehouse(wh)">
          <div class="wh-header">
            <div class="wh-icon">
              <Warehouse :size="20" />
            </div>
            <div class="wh-badge">{{ wh.type }}</div>
          </div>
          <div class="wh-body">
            <h3 class="h3">{{ wh.name }}</h3>
            <p class="text-xs text-muted flex-center mt-xs">
              <MapPin :size="12" class="mr-xs" /> {{ wh.location }}
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

    <!-- DETAIL VIEW -->
    <div v-else class="view-detail px-lg">
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
              
              <div class="shelf-list p-lg">
                 <div v-for="shelf in selectedWarehouse.shelves" :key="shelf.id" class="shelf-item card">
                    <div class="shelf-header">
                       <Layers :size="16" class="text-primary" />
                       <span class="font-bold">{{ shelf.name }}</span>
                    </div>
                    <div class="bin-grid">
                       <div v-for="bin in shelf.pins" :key="bin" class="bin-item">
                          <Box :size="14" class="text-muted mr-xs" /> {{ bin }}
                       </div>
                       <button class="btn-add-bin"><Plus :size="12" /></button>
                    </div>
                 </div>

                 <div v-if="selectedWarehouse.shelves.length === 0" class="empty-state">
                    <Package :size="48" class="text-muted mb-md" />
                    <p class="text-muted">No shelves or bins configured for this warehouse.</p>
                 </div>
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
