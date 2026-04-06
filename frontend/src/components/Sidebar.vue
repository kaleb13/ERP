<script setup lang="ts">

import { useRoute } from 'vue-router';
import { 
  LayoutDashboard, 
  Building2, 
  Building,
  GitBranch,
  Store,
  ShoppingCart,
  Warehouse,
  Layers,
  Box,
  FileText,
  Users,
  PieChart,
  Coins,
  Calculator,
  Truck,
  DollarSign,
  ChevronRight,
  Plus,
  ExternalLink
} from 'lucide-vue-next';

const route = useRoute();

const menuGroups = [
  {
    title: 'Home',
    items: [
      { name: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
      { name: 'Hierarchy Tree', path: '/hierarchy-manager', icon: GitBranch }
    ]
  },
  {
    title: 'Organization Setup',
    items: [
      { name: 'Business Groups', path: '/business-groups', icon: Building2 },
      { name: 'Organizations', path: '/organizations', icon: Building },
      { name: 'Branches', path: '/branches', icon: GitBranch },
      { name: 'Branch Shops', path: '/branch-shops', icon: Store },
      { name: 'Outlets', path: '/outlets', icon: ShoppingCart }
    ]
  },
  {
    title: 'Operations',
    items: [
      { name: 'Warehouses', path: '/warehouses', icon: Warehouse },
      { name: 'Warehouse Shelves', path: '/warehouse-shelves', icon: Layers },
      { name: 'Warehouse Bins', path: '/warehouse-bins', icon: Box }
    ]
  },
  {
    title: 'Configuration',
    items: [
      { name: 'Legal Entity Types', path: '/legal-entity-types', icon: FileText },
      { name: 'Customer Groups', path: '/customer-groups', icon: Users },
      { name: 'Sectors', path: '/sectors', icon: PieChart },
      { name: 'Currency', path: '/currency', icon: Coins },
      { name: 'Costing Rules', path: '/costing-rules', icon: Calculator }
    ]
  },
  {
    title: 'Relationships',
    items: [
      { name: 'Suppliers', path: '/suppliers', icon: Truck },
      { name: 'Base Currency', path: '/base-currency', icon: DollarSign }
    ]
  }
];
</script>

<template>
  <aside class="sidebar">
    <div class="brand">
      <div class="logo-box">
         <Box :size="20" color="white" />
      </div>
      <div class="brand-text">
        <h2 class="h3">ERPNext</h2>
      </div>
    </div>

    <div class="nav-content">
      <div v-for="group in menuGroups" :key="group.title" class="nav-group">
        <div class="nav-title">{{ group.title }}</div>
        
        <router-link 
          v-for="item in group.items" 
          :key="item.path"
          :to="item.path"
          class="nav-item"
          :class="{ active: route.path === item.path }"
        >
          <div class="nav-item-inner">
            <component :is="item.icon" :size="16" class="icon" />
            <span class="text-sm">{{ item.name }}</span>
          </div>
          <ChevronRight :size="14" class="chevron" v-if="route.path === item.path" />
        </router-link>
      </div>
    </div>

    <div class="user-profile">
      <img src="https://i.pravatar.cc/150?img=68" alt="Profile" class="avatar" />
      <div class="user-info">
        <div class="name">Asrat Z.</div>
        <div class="status-indicator"></div>
      </div>
    </div>
  </aside>
</template>

<style scoped>
.sidebar {
  width: 240px;
  background-color: #f4f5f7; /* Very light grey for ERPNext feel */
  border-right: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
}

.brand {
  padding: 16px 20px;
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
}

.logo-box {
  width: 32px;
  height: 32px;
  background-color: var(--color-primary);
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.brand-text h2 {
  font-size: 18px;
  font-weight: 700;
  color: #1a1c21;
}

.nav-content {
  padding: 0 12px;
  flex: 1;
  overflow-y: auto;
}

.nav-group {
  margin-bottom: 20px;
}

.nav-title {
  padding: 8px 12px;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  color: #8c9096;
  letter-spacing: 0.05em;
}

.nav-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  margin-bottom: 2px;
  border-radius: 6px;
  color: #4a4d55;
  transition: all 0.1s ease;
  text-decoration: none;
}

.nav-item-inner {
  display: flex;
  align-items: center;
  gap: 10px;
}

.nav-item .icon {
  color: #64748b;
}

.nav-item:hover {
  background-color: #e2e4e9;
  color: #1a1c21;
}

.nav-item.active {
  background-color: white;
  color: var(--color-primary);
  box-shadow: var(--shadow-sm);
  font-weight: 600;
}

.nav-item.active .icon {
  color: var(--color-primary);
}

.chevron {
  color: var(--color-primary);
}

.user-profile {
  padding: 16px;
  margin: 12px;
  background: white;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
}

.avatar {
  width: 28px;
  height: 28px;
  border-radius: 4px;
}

.user-info {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.name {
  font-size: 13px;
  font-weight: 600;
}

.status-indicator {
  width: 8px;
  height: 8px;
  background-color: var(--color-success);
  border-radius: 50%;
}
</style>
