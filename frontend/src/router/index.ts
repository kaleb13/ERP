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
import HeadcountPlanningView from '../views/hr/HeadcountPlanningView.vue';
import HeadcountPlanCreate from '../views/hr/HeadcountPlanCreate.vue';
import HeadcountMonitoringView from '../views/hr/HeadcountMonitoringView.vue';
import FieldsOfStudyView from '../views/hr/FieldsOfStudyView.vue';
import InstitutionsView from '../views/hr/InstitutionsView.vue';
import CommitteesView from '../views/hr/CommitteesView.vue';
import CommitteeCreate from '../views/hr/CommitteeCreate.vue';
import WorkCalendarsView from '../views/hr/WorkCalendarsView.vue';
import WorkCalendarCreate from '../views/hr/WorkCalendarCreate.vue';
import CalendarView from '../views/hr/CalendarView.vue';
import WorkShiftsView from '../views/hr/WorkShiftsView.vue';
import WorkShiftCreate from '../views/hr/WorkShiftCreate.vue';
import ShiftPatternsView from '../views/hr/ShiftPatternsView.vue';
import ShiftPatternCreate from '../views/hr/ShiftPatternCreate.vue';
import MyShiftsView from '../views/hr/MyShiftsView.vue';
import ShiftAssignmentsView from '../views/hr/ShiftAssignmentsView.vue';
import ShiftAssignmentCreate from '../views/hr/ShiftAssignmentCreate.vue';
import ShiftAssignPlanner from '../views/hr/ShiftAssignPlanner.vue';
import AttendanceView from '../views/hr/AttendanceView.vue';
import BiometricDevicesView from '../views/hr/BiometricDevicesView.vue';
import DeviceCreate from '../views/hr/DeviceCreate.vue';
import OvertimeRequestsView from '../views/hr/OvertimeRequestsView.vue';
import OvertimeRequestCreate from '../views/hr/OvertimeRequestCreate.vue';
import ShiftSwapsView from '../views/hr/ShiftSwapsView.vue';
import HolidaysView from '../views/hr/HolidaysView.vue';
import HolidayCreate from '../views/hr/HolidayCreate.vue';
import EmployeeMovementsView from '../views/hr/EmployeeMovementsView.vue';
import EmployeeMovementCreate from '../views/hr/EmployeeMovementCreate.vue';
import EmployeeMovementDetail from '../views/hr/EmployeeMovementDetail.vue';
import EmployeeMovementsAdminView from '../views/hr/EmployeeMovementsAdminView.vue';
import LeaveRequestsView from '../views/hr/LeaveRequestsView.vue';
import LeaveRequestCreate from '../views/hr/LeaveRequestCreate.vue';
import LeaveRequestDetail from '../views/hr/LeaveRequestDetail.vue';
import LeaveApprovalsView from '../views/hr/LeaveApprovalsView.vue';
import LeaveAllocationsView from '../views/hr/LeaveAllocationsView.vue';
import LeaveAllocationCreate from '../views/hr/LeaveAllocationCreate.vue';
import LeaveAllocationDetail from '../views/hr/LeaveAllocationDetail.vue';
import LeaveBalancesView from '../views/hr/LeaveBalancesView.vue';
import LeaveEncashmentsView from '../views/hr/LeaveEncashmentsView.vue';
import LeaveEncashmentCreate from '../views/hr/LeaveEncashmentCreate.vue';
import LeaveEncashmentDetail from '../views/hr/LeaveEncashmentDetail.vue';
import LeavePoliciesView from '../views/hr/LeavePoliciesView.vue';
import LeavePolicyCreate from '../views/hr/LeavePolicyCreate.vue';
import LeavePolicyDetail from '../views/hr/LeavePolicyDetail.vue';
import LeaveTypesView from '../views/hr/LeaveTypesView.vue';
import LeaveSetupView from '../views/hr/LeaveSetupView.vue';
import LeaveTypeCreate from '../views/hr/LeaveTypeCreate.vue';
import EmployeeSeparationsView from '../views/hr/EmployeeSeparationsView.vue';
import EmployeeSeparationCreate from '../views/hr/EmployeeSeparationCreate.vue';
import EmployeeSeparationDetail from '../views/hr/EmployeeSeparationDetail.vue';
import ExitClearanceView from '../views/hr/ExitClearanceView.vue';
import FinalSettlementsView from '../views/hr/FinalSettlementsView.vue';
import EmployeeLettersView from '../views/hr/EmployeeLettersView.vue';
import LetterTemplatesView from '../views/hr/LetterTemplatesView.vue';
import AnnouncementsView from '../views/hr/AnnouncementsView.vue';
import AnnouncementCreate from '../views/hr/AnnouncementCreate.vue';
import HRServiceRequestsView from '../views/hr/HRServiceRequestsView.vue';
import HRServiceRequestCreate from '../views/hr/HRServiceRequestCreate.vue';
import HRServiceAgreementsView from '../views/hr/HRServiceAgreementsView.vue';
import HRServiceAgreementCreate from '../views/hr/HRServiceAgreementCreate.vue';
import ClientAssignmentsView from '../views/hr/ClientAssignmentsView.vue';
import ClientAssignmentCreate from '../views/hr/ClientAssignmentCreate.vue';

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
      path: '/hr/movements',
      name: 'hrEmployeeMovements',
      component: EmployeeMovementsView
    },
    {
      path: '/hr/movements/admin',
      name: 'hrEmployeeMovementsAdmin',
      component: EmployeeMovementsAdminView
    },
    {
      path: '/hr/movements/create',
      name: 'hrEmployeeMovementCreate',
      component: EmployeeMovementCreate
    },
    {
      path: '/hr/movements/:id',
      name: 'hrEmployeeMovementDetail',
      component: EmployeeMovementDetail
    },
    {
      path: '/hr/leave-requests',
      name: 'hrLeaveRequests',
      component: LeaveRequestsView
    },
    {
      path: '/hr/leave-requests/create',
      name: 'hrLeaveRequestCreate',
      component: LeaveRequestCreate
    },
    {
      path: '/hr/leave-requests/:id',
      name: 'hrLeaveRequestDetail',
      component: LeaveRequestDetail
    },
    {
      path: '/hr/leave-approvals',
      redirect: '/hr/leave-requests'
    },
    {
      path: '/hr/leave-allocations',
      name: 'hrLeaveAllocations',
      component: LeaveAllocationsView
    },
    {
      path: '/hr/leave-allocations/create',
      name: 'hrLeaveAllocationCreate',
      component: LeaveAllocationCreate
    },
    {
      path: '/hr/leave-allocations/:id',
      name: 'hrLeaveAllocationDetail',
      component: LeaveAllocationDetail
    },
    {
      path: '/hr/leave-balances',
      name: 'hrLeaveBalances',
      component: LeaveBalancesView
    },
    {
      path: '/hr/leave-encashments',
      name: 'hrLeaveEncashments',
      component: LeaveEncashmentsView
    },
    {
      path: '/hr/leave-encashments/create',
      name: 'hrLeaveEncashmentCreate',
      component: LeaveEncashmentCreate
    },
    {
      path: '/hr/leave-encashments/:id',
      name: 'hrLeaveEncashmentDetail',
      component: LeaveEncashmentDetail
    },
    {
      path: '/hr/leave-setup',
      redirect: '/hr/leave-policies'
    },
    {
      path: '/hr/leave-policies',
      name: 'hrLeavePolicies',
      component: LeavePoliciesView
    },
    {
      path: '/hr/leave-policies/create',
      name: 'hrLeavePolicyCreate',
      component: LeavePolicyCreate
    },
    {
      path: '/hr/leave-policies/:id',
      name: 'hrLeavePolicyDetail',
      component: LeavePolicyDetail
    },
    {
      path: '/hr/leave-types',
      name: 'hrLeaveTypes',
      component: LeaveTypesView
    },
    {
      path: '/hr/leave-types/create',
      name: 'hrLeaveTypeCreate',
      component: LeaveTypeCreate
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
    {
      path: '/hr/headcount-planning',
      name: 'hrHeadcountPlanning',
      component: HeadcountPlanningView
    },
    {
      path: '/hr/headcount-planning/create',
      name: 'hrHeadcountPlanCreate',
      component: HeadcountPlanCreate
    },
    {
      path: '/hr/headcount-planning/:id',
      name: 'hrHeadcountPlanDetail',
      component: HeadcountPlanCreate
    },
    {
      path: '/hr/headcount-monitoring',
      name: 'hrHeadcountMonitoring',
      component: HeadcountMonitoringView
    },
    // Redirects from legacy headcount-budgets route
    {
      path: '/hr/headcount-budgets',
      redirect: '/hr/headcount-planning'
    },
    {
      path: '/hr/headcount-budgets/create',
      redirect: '/hr/headcount-planning/create'
    },
    {
      path: '/hr/fields-of-study',
      name: 'hrFieldsOfStudy',
      component: FieldsOfStudyView
    },
    {
      path: '/hr/institutions',
      name: 'hrInstitutions',
      component: InstitutionsView
    },
    {
      path: '/hr/committees',
      name: 'hrCommittees',
      component: CommitteesView
    },
    {
      path: '/hr/committees/create',
      name: 'hrCommitteeCreate',
      component: CommitteeCreate
    },
    {
      path: '/hr/work-calendars',
      name: 'hrWorkCalendars',
      component: WorkCalendarsView
    },
    {
      path: '/hr/work-calendars/create',
      name: 'hrWorkCalendarCreate',
      component: WorkCalendarCreate
    },
    {
      path: '/hr/work-calendars/:id',
      name: 'hrWorkCalendarDetail',
      component: WorkCalendarCreate
    },
    {
      path: '/hr/calendar',
      name: 'hrCalendar',
      component: CalendarView
    },
    {
      path: '/hr/shifts',
      name: 'hrWorkShifts',
      component: WorkShiftsView
    },
    {
      path: '/hr/shifts/create',
      name: 'hrWorkShiftCreate',
      component: WorkShiftCreate
    },
    {
      path: '/hr/shift-patterns',
      name: 'hrShiftPatterns',
      component: ShiftPatternsView
    },
    {
      path: '/hr/shift-patterns/create',
      name: 'hrShiftPatternCreate',
      component: ShiftPatternCreate
    },
    {
      path: '/hr/my-shifts',
      name: 'hrMyShifts',
      component: MyShiftsView
    },
    {
      path: '/hr/shift-assignments',
      name: 'hrShiftAssignments',
      component: ShiftAssignmentsView
    },
    {
      path: '/hr/shift-assignments/create',
      name: 'hrShiftAssignmentCreate',
      component: ShiftAssignmentCreate
    },
    {
      path: '/hr/shift-assignments/assign',
      name: 'hrShiftAssignPlanner',
      component: ShiftAssignPlanner
    },
    {
      path: '/hr/attendance',
      name: 'hrAttendance',
      component: AttendanceView
    },
    {
      path: '/hr/attendance-devices',
      name: 'hrAttendanceDevices',
      component: BiometricDevicesView
    },
    {
      path: '/hr/attendance-devices/create',
      name: 'hrAttendanceDeviceCreate',
      component: DeviceCreate
    },
    {
      path: '/hr/overtime-requests',
      name: 'hrOvertimeRequests',
      component: OvertimeRequestsView
    },
    {
      path: '/hr/overtime-requests/create',
      name: 'hrOvertimeRequestCreate',
      component: OvertimeRequestCreate
    },
    {
      path: '/hr/shift-roster',
      redirect: '/hr/shift-assignments'
    },
    {
      path: '/hr/shift-swaps',
      name: 'hrShiftSwaps',
      component: ShiftSwapsView
    },
    {
      path: '/hr/holidays',
      name: 'hrHolidays',
      component: HolidaysView
    },
    {
      path: '/hr/holidays/create',
      name: 'hrHolidayCreate',
      component: HolidayCreate
    },
    {
      path: '/hr/separations',
      name: 'hrEmployeeSeparations',
      component: EmployeeSeparationsView
    },
    {
      path: '/hr/separations/create',
      name: 'hrEmployeeSeparationCreate',
      component: EmployeeSeparationCreate
    },
    {
      path: '/hr/separations/:id',
      name: 'hrEmployeeSeparationDetail',
      component: EmployeeSeparationDetail
    },
    {
      path: '/hr/exit-clearance',
      name: 'hrExitClearance',
      component: ExitClearanceView
    },
    {
      path: '/hr/final-settlements',
      name: 'hrFinalSettlements',
      component: FinalSettlementsView
    },
    // Letters, Announcements & Employee Services (Section 13)
    {
      path: '/hr/letters',
      name: 'hrEmployeeLetters',
      component: EmployeeLettersView
    },
    {
      path: '/hr/employee-letters',
      redirect: '/hr/letters'
    },
    {
      path: '/hr/letter-templates',
      name: 'hrLetterTemplates',
      component: LetterTemplatesView
    },
    {
      path: '/hr/announcements',
      name: 'hrAnnouncements',
      component: AnnouncementsView
    },
    {
      path: '/hr/announcements/create',
      name: 'hrAnnouncementCreate',
      component: AnnouncementCreate
    },
    {
      path: '/hr/announcements/:id/edit',
      name: 'hrAnnouncementEdit',
      component: AnnouncementCreate
    },
    {
      path: '/hr/service-requests',
      name: 'hrServiceRequests',
      component: HRServiceRequestsView
    },
    {
      path: '/hr/service-requests/create',
      name: 'hrServiceRequestCreate',
      component: HRServiceRequestCreate
    },
    {
      path: '/hr/service-requests/:id/edit',
      name: 'hrServiceRequestEdit',
      component: HRServiceRequestCreate
    },
    // Multi-entity Workforce (Section 19)
    {
      path: '/hr/service-agreements',
      name: 'hrServiceAgreements',
      component: HRServiceAgreementsView
    },
    {
      path: '/hr/service-agreements/create',
      name: 'hrServiceAgreementCreate',
      component: HRServiceAgreementCreate
    },
    {
      path: '/hr/service-agreements/:id/edit',
      name: 'hrServiceAgreementEdit',
      component: HRServiceAgreementCreate
    },
    {
      path: '/hr/client-assignments',
      name: 'hrClientAssignments',
      component: ClientAssignmentsView
    },
    {
      path: '/hr/client-assignments/create',
      name: 'hrClientAssignmentCreate',
      component: ClientAssignmentCreate
    },
    {
      path: '/hr/client-assignments/:id/edit',
      name: 'hrClientAssignmentEdit',
      component: ClientAssignmentCreate
    }
  ]
});

export default router;
