import { createRouter, createWebHistory } from 'vue-router';
import InventoryDashboard from '../views/InventoryDashboard.vue';
import StockSummary from '../views/StockSummary.vue';
import StockLedger from '../views/StockLedger.vue';
import GatePass from '../views/GatePass.vue';
import GatePassCreate from '../views/GatePassCreate.vue';
import StockReservation from '../views/StockReservation.vue';
import StockReservationCreate from '../views/StockReservationCreate.vue';
import Home from '../views/Home.vue';
import CompanySetup from '../views/CompanySetup.vue';
import Customers from '../views/Customers.vue';
import CustomerGroups from '../views/CustomerGroups.vue';
import BuyingModule from '../views/BuyingModule.vue';
import Products from '../views/Products.vue';
import ProductVariants from '../views/ProductVariants.vue';
import ProductModifiers from '../views/ProductModifiers.vue';

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      redirect: '/home'
    },
    {
      path: '/home',
      name: 'home',
      component: Home,
      meta: { noSidebar: true }
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: InventoryDashboard
    },
    {
      path: '/stock-summary',
      name: 'stockSummary',
      component: StockSummary
    },
    {
      path: '/stock-ledger',
      name: 'stockLedger',
      component: StockLedger
    },
    {
      path: '/gate-pass',
      name: 'gatePass',
      component: GatePass
    },
    {
      path: '/gate-pass/create',
      name: 'gatePassCreate',
      component: GatePassCreate
    },
    {
      path: '/stock-reservation',
      name: 'stockReservation',
      component: StockReservation
    },
    {
      path: '/stock-reservation/create',
      name: 'stockReservationCreate',
      component: StockReservationCreate
    },
    {
      path: '/company-setup',
      name: 'companySetup',
      component: CompanySetup
    },
    {
      path: '/sales',
      redirect: '/sales/customers'
    },
    {
      path: '/sales/customers',
      name: 'customers',
      component: Customers
    },
    {
      path: '/sales/customer-groups',
      name: 'customerGroups',
      component: CustomerGroups
    },
    {
      path: '/buying',
      name: 'buying',
      component: BuyingModule
    },
    {
      path: '/inventory/products',
      name: 'products',
      component: Products
    },
    {
      path: '/inventory/product-variants',
      name: 'productVariants',
      component: ProductVariants
    },
    {
      path: '/inventory/product-modifiers',
      name: 'productModifiers',
      component: ProductModifiers
    },
    {
      path: '/inventory/product-group',
      redirect: '/inventory/products'
    },
    {
      path: '/inventory/product-attribute',
      redirect: '/inventory/products'
    },
    {
      path: '/inventory/locations',
      redirect: '/inventory/products'
    }
  ]
});

export default router;
