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
import UserAndAccess from '../views/UserAndAccess.vue';
import CreateUser from '../views/CreateUser.vue';
import AuditLogs from '../views/AuditLogs.vue';
import Customers from '../views/Customers.vue';
import CustomerGroups from '../views/CustomerGroups.vue';
import BuyingModule from '../views/BuyingModule.vue';
import Products from '../views/Products.vue';
import ProductVariants from '../views/ProductVariants.vue';
import ProductModifiers from '../views/ProductModifiers.vue';
import ProductGroups from '../views/ProductGroups.vue';
import EmployeeProfile from '../views/hr/EmployeeProfile.vue';
import EmployeeCreate from '../views/hr/EmployeeCreate.vue';
import OrgStructuresView from '../views/hr/OrgStructuresView.vue';
import OrgStructureCreate from '../views/hr/OrgStructureCreate.vue';
import OrganizationUnitsView from '../views/hr/OrganizationUnitsView.vue';
import SalaryScalesView from '../views/hr/SalaryScalesView.vue';
import SalaryScaleCreate from '../views/hr/SalaryScaleCreate.vue';
import SalaryScaleDetail from '../views/hr/SalaryScaleDetail.vue';
import JobPositionsView from '../views/hr/JobPositionsView.vue';
import JobPositionCreate from '../views/hr/JobPositionCreate.vue';
import JobTitlesView from '../views/hr/JobTitlesView.vue';
import JobTitleCreate from '../views/hr/JobTitleCreate.vue';
import JobLevelsView from '../views/hr/JobLevelsView.vue';


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
      path: '/company-setup/user-and-access',
      name: 'userAndAccess',
      component: UserAndAccess
    },
    {
      path: '/company-setup/user-and-access/users/create',
      name: 'createUser',
      component: CreateUser
    },
    {
      path: '/company-setup/user-and-access/users/:id',
      name: 'editUser',
      component: CreateUser
    },
    {
      path: '/company-setup/audit-logs',
      name: 'auditLogs',
      component: AuditLogs
    },
    {
      path: '/system-config/audit-logs',
      redirect: '/company-setup/audit-logs'
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
      name: 'productGroups',
      component: ProductGroups
    },
    {
      path: '/inventory/product-attribute',
      redirect: '/inventory/products'
    },
    {
      path: '/inventory/locations',
      redirect: '/inventory/products'
    },
    // Human Resources (HR) Module Routes
    {
      path: '/hr',
      redirect: '/hr/employees'
    },
    {
      path: '/hr/employees',
      name: 'hrEmployees',
      component: EmployeeProfile
    },
    {
      path: '/hr/employees/create',
      name: 'hrEmployeeCreate',
      component: EmployeeCreate
    },
    {
      path: '/hr/org-structures',
      name: 'hrOrgStructures',
      component: OrgStructuresView
    },
    {
      path: '/hr/org-structures/create',
      name: 'hrOrgStructureCreate',
      component: OrgStructureCreate
    },
    {
      path: '/hr/org-units',
      name: 'hrOrgUnits',
      component: OrganizationUnitsView
    },
    {
      path: '/hr/salary-scales',
      name: 'hrSalaryScales',
      component: SalaryScalesView
    },
    {
      path: '/hr/salary-scales/create',
      name: 'hrSalaryScaleCreate',
      component: SalaryScaleCreate
    },
    {
      path: '/hr/salary-scales/:id',
      name: 'hrSalaryScaleDetail',
      component: SalaryScaleDetail
    },
    // Redirects from old routes
    {
      path: '/hr/salary-matrices',
      redirect: '/hr/salary-scales'
    },
    {
      path: '/hr/salary-matrices/create',
      redirect: '/hr/salary-scales/create'
    },
    {
      path: '/hr/job-grades',
      redirect: '/hr/salary-scales'
    },
    {
      path: '/hr/job-grades/create',
      redirect: '/hr/salary-scales/create'
    },
    {
      path: '/hr/job-positions',
      name: 'hrJobPositions',
      component: JobPositionsView
    },
    {
      path: '/hr/job-positions/create',
      name: 'hrJobPositionCreate',
      component: JobPositionCreate
    },
    {
      path: '/hr/job-titles',
      name: 'hrJobTitles',
      component: JobTitlesView
    },
    {
      path: '/hr/job-titles/create',
      name: 'hrJobTitleCreate',
      component: JobTitleCreate
    },
    {
      path: '/hr/job-levels',
      name: 'hrJobLevels',
      component: JobLevelsView
    },

  ]
});

export default router;
