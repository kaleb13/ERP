import { createRouter, createWebHistory } from 'vue-router';
import Organizations from '../views/Organizations.vue';

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      redirect: '/organizations'
    },
    {
      path: '/organizations',
      name: 'organizations',
      component: Organizations
    }
  ]
});

export default router;
