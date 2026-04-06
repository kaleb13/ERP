<script setup lang="ts">
import { ref } from 'vue';
import { 
  Building2, Building, GitBranch, Store, ShoppingCart, 
  Warehouse, Layers, Box, ChevronRight, Plus, MoreVertical, Search, ExternalLink 
} from 'lucide-vue-next';

// This is a "Parent" View that manages the relationship
const currentView = ref<'dashboard' | 'organization_detail'>('dashboard');
const selectedOrg = ref<any>(null);

const organizations = ref([
  { 
    id: 1, 
    name: 'Qelem Meda Group', 
    branches: [
      { 
        id: 101, 
        name: 'Bole Branch', 
        shops: [
          { id: 201, name: 'Bole Shop A', outlets: [{ id: 301, name: 'POS 01' }, { id: 302, name: 'POS 02' }] }
        ]
      },
      { 
        id: 102, 
        name: 'Kazanchis Branch', 
        shops: []
      }
    ] 
  }
]);

const selectOrg = (org: any) => {
  selectedOrg.value = org;
  currentView.value = 'organization_detail';
};
</script>

<template>
  <div class="hierarchy-manager">
    <!-- TOP NAV -->
    <div class="erp-nav">
      <div class="erp-nav-left">
        <div class="breadcrumb text-sm">
          <span class="root">Home</span>
          <ChevronRight :size="14" class="sep" />
          <span class="current">Hierarchy Manager</span>
        </div>
        <div class="view-title">
          <h1 class="h2">{{ currentView === 'dashboard' ? 'Business Hierarchy' : selectedOrg.name }}</h1>
        </div>
      </div>
    </div>

    <!-- DASHBOARD VIEW -->
    <div v-if="currentView === 'dashboard'" class="dashboard-grid">
      <div v-for="org in organizations" :key="org.id" class="card org-card" @click="selectOrg(org)">
        <div class="org-header">
           <Building :size="24" class="text-primary" />
           <h3 class="h3">{{ org.name }}</h3>
        </div>
        <div class="org-stats">
           <div class="stat">
              <span class="count">{{ org.branches.length }}</span>
              <span class="label">Branches</span>
           </div>
        </div>
        <div class="card-footer">
           <span class="text-xs font-bold text-primary">MANAGE HIERARCHY</span>
           <ExternalLink :size="14" class="text-primary" />
        </div>
      </div>
    </div>

    <!-- DETAIL HIERARCHY VIEW -->
    <div v-else class="hierarchy-detail">
      <button class="btn btn-outline mb-lg" @click="currentView = 'dashboard'">Back to List</button>
      
      <div class="hierarchy-tree">
        <!-- ORGANIZATION LEVEL -->
        <div class="tree-node org-node">
           <div class="node-content card">
              <div class="node-icon"><Building :size="18" /></div>
              <div class="node-text">
                 <div class="text-xs text-muted uppercase font-bold">Organization</div>
                 <div class="font-bold">{{ selectedOrg.name }}</div>
              </div>
              <button class="btn-icon add-btn"><Plus :size="14" /></button>
           </div>

           <!-- BRANCH LEVEL -->
           <div class="node-children">
              <div v-for="branch in selectedOrg.branches" :key="branch.id" class="tree-node branch-node">
                 <div class="node-line"></div>
                 <div class="node-content card">
                    <div class="node-icon"><GitBranch :size="16" /></div>
                    <div class="node-text">
                       <div class="text-xs text-muted uppercase font-bold">Branch</div>
                       <div class="font-bold">{{ branch.name }}</div>
                    </div>
                    <button class="btn-icon add-btn"><Plus :size="14" /></button>
                 </div>

                 <!-- SHOP LEVEL -->
                 <div class="node-children">
                    <div v-for="shop in branch.shops" :key="shop.id" class="tree-node shop-node">
                       <div class="node-line"></div>
                       <div class="node-content card">
                          <div class="node-icon"><Store :size="14" /></div>
                          <div class="node-text">
                             <div class="text-xs text-muted uppercase font-bold">Shop</div>
                             <div>{{ shop.name }}</div>
                          </div>
                          <button class="btn-icon add-btn"><Plus :size="12" /></button>
                       </div>

                       <!-- OUTLET LEVEL -->
                       <div class="node-children">
                          <div v-for="outlet in shop.outlets" :key="outlet.id" class="tree-node outlet-node">
                             <div class="node-line"></div>
                             <div class="node-content tag">
                                <ShoppingCart :size="12" class="mr-sm" />
                                <span class="text-sm">{{ outlet.name }}</span>
                             </div>
                          </div>
                       </div>
                    </div>
                    
                    <!-- EMPTY STATE FOR SHOPS -->
                    <div v-if="branch.shops.length === 0" class="empty-node text-xs text-muted">
                        No shops registered
                    </div>
                 </div>
              </div>
           </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.hierarchy-manager { padding: 0; }

.erp-nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 20px;
  background-color: white;
  border-bottom: 1px solid var(--color-border);
  margin-bottom: 24px;
}

.breadcrumb { display: flex; align-items: center; gap: 6px; color: var(--color-text-muted); margin-bottom: 4px; }
.sep { color: #ccc; }
.current { color: #1a1c21; font-weight: 500; }

.dashboard-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
  padding: 0 20px;
}

.org-card {
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
  border-left: 4px solid var(--color-primary);
}
.org-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-md);
}

.org-header { display: flex; align-items: center; gap: 12px; margin-bottom: 16px; }
.org-stats { padding: 12px 0; border-top: 1px solid #f1f3f4; }
.stat { display: flex; flex-direction: column; }
.stat .count { font-size: 24px; font-weight: 800; color: #1a1c21; }
.stat .label { font-size: 12px; font-weight: 700; color: var(--color-text-muted); text-transform: uppercase; }

.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #f1f3f4;
}

/* HIERARCHY TREE */
.hierarchy-detail { padding: 0 20px; }
.mb-lg { margin-bottom: 24px; }

.hierarchy-tree {
  max-width: 800px;
}

.tree-node {
  position: relative;
  margin-bottom: 12px;
}

.node-content {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 16px;
  width: fit-content;
  min-width: 200px;
  background: white;
  z-index: 2;
  position: relative;
}

.node-content.tag {
  background: #f1f3f4;
  border-radius: 4px;
  padding: 4px 10px;
  border: 1px solid transparent;
  min-width: auto;
}

.node-icon {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  background: var(--color-primary-light);
  color: var(--color-primary);
}

.node-text { flex: 1; }

.add-btn {
  background: #f8f9fa;
  border: 1px dashed #ccc;
  width: 24px;
  height: 24px;
}
.add-btn:hover { background: var(--color-primary); color: white; border-color: var(--color-primary); }

.node-children {
  padding-left: 48px;
  margin-top: 12px;
  border-left: 2px solid #e2e4e9;
  margin-left: 24px;
}

.node-line {
  position: absolute;
  top: 18px;
  left: -24px;
  width: 24px;
  height: 2px;
  background: #e2e4e9;
}

.branch-node .node-icon { background: #e8f5e9; color: #2e7d32; }
.shop-node .node-icon { background: #fff3e0; color: #ef6c00; }

.empty-node { padding: 4px 0 12px 12px; font-style: italic; }

.mr-sm { margin-right: 8px; }
</style>
