import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import Dashboard from '../views/Dashboard.vue';
import EntityManager from '../views/EntityManager.vue';
import HierarchyManager from '../views/HierarchyManager.vue';
import WarehouseManager from '../views/WarehouseManager.vue';
import BlankView from '../views/BlankView.vue';

const routes: Array<RouteRecordRaw> = [
  {
    path: '/',
    component: DashboardLayout,
    children: [
      { path: '', redirect: '/dashboard' },
      { path: '/dashboard', name: 'Dashboard', component: Dashboard },
      { path: '/hierarchy-manager', name: 'HierarchyManager', component: HierarchyManager },
      { path: '/business-groups', name: 'BusinessGroups', component: EntityManager },
      { path: '/organizations', name: 'Organizations', component: EntityManager },
      { path: '/branches', name: 'Branches', component: EntityManager },
      { path: '/branch-shops', name: 'BranchShops', component: EntityManager },
      { path: '/outlets', name: 'Outlets', component: EntityManager },
      { path: '/warehouses', name: 'Warehouses', component: WarehouseManager },
      { path: '/warehouse-shelves', name: 'WarehouseShelves', component: BlankView },
      { path: '/warehouse-bins', name: 'WarehouseBins', component: BlankView },
      { path: '/legal-entity-types', name: 'LegalEntityTypes', component: BlankView },
      { path: '/customer-groups', name: 'CustomerGroups', component: BlankView },
      { path: '/sectors', name: 'Sectors', component: BlankView },
      { path: '/currency', name: 'Currency', component: BlankView },
      { path: '/costing-rules', name: 'CostingRules', component: BlankView },
      { path: '/suppliers', name: 'Suppliers', component: BlankView },
      { path: '/base-currency', name: 'BaseCurrency', component: BlankView },
    ]
  }
];

const router = createRouter({
  history: createWebHistory(),
  routes
});

export default router;
