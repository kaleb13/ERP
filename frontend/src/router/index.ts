import { createRouter, createWebHistory } from 'vue-router';
import Organizations from '../views/Organizations.vue';
import Warehouse from '../views/Warehouse.vue';
import Product from '../views/Product.vue';
import Brands from '../views/Brands.vue';
import Measurements from '../views/Measurements.vue';
import ItemCategories from '../views/ItemCategories.vue';
import Items from '../views/Items.vue';
import ProductGroups from '../views/ProductGroups.vue';
import Variants from '../views/Variants.vue';
import ShopProducts from '../views/ShopProducts.vue';

import PosAttributes from '../views/PosAttributes.vue';
import PosRecipes from '../views/PosRecipes.vue';
import InventoryPolicies from '../views/InventoryPolicies.vue';
import Warranties from '../views/Warranties.vue';

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      redirect: '/warehouses'
    },
    {
      path: '/organizations',
      name: 'organizations',
      component: Organizations
    },
    {
      path: '/warehouses',
      name: 'warehouses',
      component: Warehouse
    },
    {
      path: '/products',
      name: 'products',
      component: Product
    },
    {
      path: '/brands',
      name: 'brands',
      component: Brands
    },
    {
      path: '/measurements',
      name: 'measurements',
      component: Measurements
    },
    {
      path: '/item-categories',
      name: 'itemCategories',
      component: ItemCategories
    },
    {
      path: '/items',
      name: 'items',
      component: Items
    },
    {
      path: '/product-groups',
      name: 'productGroups',
      component: ProductGroups
    },
    {
      path: '/variants',
      name: 'variants',
      component: Variants
    },
    {
      path: '/shop-products',
      name: 'shopProducts',
      component: ShopProducts
    },
    {
      path: '/pos-attributes',
      name: 'posAttributes',
      component: PosAttributes
    },
    {
      path: '/pos-recipes',
      name: 'posRecipes',
      component: PosRecipes
    },
    {
      path: '/inventory-policies',
      name: 'inventoryPolicies',
      component: InventoryPolicies
    },
    {
      path: '/warranties',
      name: 'warranties',
      component: Warranties
    }
  ]
});

export default router;
