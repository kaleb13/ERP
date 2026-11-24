import { createRouter, createWebHistory } from 'vue-router';
import Home from '../views/Home.vue';
import StockSummary from '../views/StockSummary.vue';
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
import MyAttendanceView from '../views/hr/MyAttendanceView.vue';
import BiometricDevicesView from '../views/hr/BiometricDevicesView.vue';
import DeviceCreate from '../views/hr/DeviceCreate.vue';
import OvertimeRequestsView from '../views/hr/OvertimeRequestsView.vue';
import OvertimeRequestCreate from '../views/hr/OvertimeRequestCreate.vue';
import ShiftSwapsView from '../views/hr/ShiftSwapsView.vue';
import ShiftSwapCreate from '../views/hr/ShiftSwapCreate.vue';
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
import ProcurementCategoriesView from '../views/procurement/ProcurementCategoriesView.vue';
import ProcurementCategoryCreate from '../views/procurement/ProcurementCategoryCreate.vue';
import ProcurementUnitsView from '../views/procurement/ProcurementUnitsView.vue';
import ProcurementUnitCreate from '../views/procurement/ProcurementUnitCreate.vue';
import ProcurementMethodsView from '../views/procurement/ProcurementMethodsView.vue';
import ProcurementMethodCreate from '../views/procurement/ProcurementMethodCreate.vue';
import ProcurementApprovalRoutesView from '../views/procurement/ProcurementApprovalRoutesView.vue';
import ProcurementApprovalRouteCreate from '../views/procurement/ProcurementApprovalRouteCreate.vue';
import ProcurementAssignmentRulesView from '../views/procurement/ProcurementAssignmentRulesView.vue';
import ProcurementAssignmentRuleCreate from '../views/procurement/ProcurementAssignmentRuleCreate.vue';
import ProcurementApprovalDelegationCreate from '../views/procurement/ProcurementApprovalDelegationCreate.vue';
import ProcurementRoutingRulesView from '../views/procurement/ProcurementRoutingRulesView.vue';
import ProcurementCommitteeMandatesView from '../views/procurement/ProcurementCommitteeMandatesView.vue';
import ProcurementCommitteeMandateCreate from '../views/procurement/ProcurementCommitteeMandateCreate.vue';
import ProcurementTolerancesView from '../views/procurement/ProcurementTolerancesView.vue';
import ReceiptToleranceRuleCreate from '../views/procurement/ReceiptToleranceRuleCreate.vue';
import MatchingToleranceRuleCreate from '../views/procurement/MatchingToleranceRuleCreate.vue';
import ProcurementPlansView from '../views/procurement/ProcurementPlansView.vue';
import ProcurementPlanCreate from '../views/procurement/ProcurementPlanCreate.vue';
import ProcurementPlanDetail from '../views/procurement/ProcurementPlanDetail.vue';
import SupplierRegistrationsView from '../views/procurement/SupplierRegistrationsView.vue';
import SupplierRegistrationCreate from '../views/procurement/SupplierRegistrationCreate.vue';
import SupplierRegistrationDetail from '../views/procurement/SupplierRegistrationDetail.vue';
import SuppliersView from '../views/procurement/SuppliersView.vue';
import SupplierDetail from '../views/procurement/SupplierDetail.vue';
import SupplierPerformanceSetupView from '../views/procurement/SupplierPerformanceSetupView.vue';
import ProcurementPlanItemCreate from '../views/procurement/ProcurementPlanItemCreate.vue';

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'home',
      component: Home,
      meta: { noSidebar: true }
    },
    {
      path: '/home',
      redirect: '/'
    },
    {
      path: '/inventory',
      redirect: '/inventory/stock-summary'
    },
    {
      path: '/inventory/stock-summary',
      name: 'stockSummary',
      component: StockSummary
    },
    {
      path: '/stock-summary',
      redirect: '/inventory/stock-summary'
    },
    {
      path: '/stock-ledger',
      redirect: '/inventory/stock-summary'
    },
    {
      path: '/procurement',
      redirect: '/procurement/categories'
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
      redirect: '/hr/movements'
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
      redirect: '/hr/org-structures'
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
      redirect: '/hr/calendar'
    },
    {
      path: '/hr/work-calendars/create',
      redirect: '/hr/calendar'
    },
    {
      path: '/hr/work-calendars/:id',
      redirect: '/hr/calendar'
    },
    {
      path: '/hr/calendar',
      name: 'hrCalendar',
      component: CalendarView
    },
    {
      path: '/hr/shifts',
      redirect: '/hr/calendar'
    },
    {
      path: '/hr/shifts/create',
      redirect: '/hr/calendar'
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
      redirect: '/hr/calendar'
    },
    {
      path: '/hr/shift-assignments',
      redirect: '/hr/calendar'
    },
    {
      path: '/hr/shift-assignments/create',
      redirect: '/hr/calendar'
    },
    {
      path: '/hr/shift-assignments/assign',
      redirect: '/hr/calendar'
    },
    {
      path: '/hr/my-attendance',
      redirect: '/hr/attendance'
    },
    {
      path: '/hr/attendance',
      name: 'hrAttendance',
      component: AttendanceView
    },
    {
      path: '/hr/attendance-devices',
      redirect: '/hr/attendance'
    },
    {
      path: '/hr/attendance-devices/create',
      redirect: '/hr/attendance'
    },
    {
      path: '/hr/overtime-requests',
      redirect: '/hr/calendar'
    },
    {
      path: '/hr/overtime-requests/create',
      redirect: '/hr/calendar'
    },
    {
      path: '/hr/shift-roster',
      redirect: '/hr/calendar'
    },
    {
      path: '/hr/shift-swaps',
      name: 'hrShiftSwaps',
      component: ShiftSwapsView
    },
    {
      path: '/hr/shift-swaps/create',
      name: 'hrShiftSwapCreate',
      component: ShiftSwapCreate
    },
    {
      path: '/hr/holidays',
      redirect: '/hr/calendar'
    },
    {
      path: '/hr/holidays/create',
      redirect: '/hr/calendar'
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
    },
    {
      path: '/procurement/categories',
      name: 'procurementCategories',
      component: ProcurementCategoriesView
    },
    {
      path: '/procurement/categories/create',
      name: 'procurementCategoryCreate',
      component: ProcurementCategoryCreate
    },
    {
      path: '/procurement/units',
      name: 'procurementUnits',
      component: ProcurementUnitsView
    },
    {
      path: '/procurement/units/create',
      name: 'procurementUnitCreate',
      component: ProcurementUnitCreate
    },
    {
      path: '/procurement/methods',
      name: 'procurementMethods',
      component: ProcurementMethodsView
    },
    {
      path: '/procurement/methods/create',
      name: 'procurementMethodCreate',
      component: ProcurementMethodCreate
    },
    {
      path: '/procurement/thresholds',
      redirect: '/procurement/methods'
    },
    {
      path: '/procurement/routing-rules',
      name: 'procurementRoutingRules',
      component: ProcurementRoutingRulesView
    },
    {
      path: '/procurement/approval-routes',
      redirect: '/procurement/routing-rules?tab=approval'
    },
    {
      path: '/procurement/approval-routes/create',
      name: 'procurementApprovalRouteCreate',
      component: ProcurementApprovalRouteCreate
    },
    {
      path: '/procurement/approval-routes/:id/edit',
      name: 'procurementApprovalRouteEdit',
      component: ProcurementApprovalRouteCreate
    },
    {
      path: '/procurement/assignment-rules',
      redirect: '/procurement/routing-rules?tab=assignment'
    },
    {
      path: '/procurement/assignment-rules/create',
      name: 'procurementAssignmentRuleCreate',
      component: ProcurementAssignmentRuleCreate
    },
    {
      path: '/procurement/assignment-rules/:id/edit',
      name: 'procurementAssignmentRuleEdit',
      component: ProcurementAssignmentRuleCreate
    },
    {
      path: '/procurement/delegations',
      redirect: '/procurement/routing-rules?tab=delegations'
    },
    {
      path: '/procurement/delegations/create',
      name: 'procurementApprovalDelegationCreate',
      component: ProcurementApprovalDelegationCreate
    },
    {
      path: '/procurement/delegations/:id/edit',
      name: 'procurementApprovalDelegationEdit',
      component: ProcurementApprovalDelegationCreate
    },
    {
      path: '/procurement/committee-mandates',
      name: 'procurementCommitteeMandates',
      component: ProcurementCommitteeMandatesView
    },
    {
      path: '/procurement/committee-mandates/create',
      name: 'procurementCommitteeMandateCreate',
      component: ProcurementCommitteeMandateCreate
    },
    {
      path: '/procurement/committee-mandates/:id/edit',
      name: 'procurementCommitteeMandateEdit',
      component: ProcurementCommitteeMandateCreate
    },
    {
      path: '/procurement/tolerances',
      name: 'procurementTolerances',
      component: ProcurementTolerancesView
    },
    {
      path: '/procurement/receipt-tolerances',
      redirect: '/procurement/tolerances?tab=receipt'
    },
    {
      path: '/procurement/receipt-tolerances/create',
      name: 'receiptToleranceRuleCreate',
      component: ReceiptToleranceRuleCreate
    },
    {
      path: '/procurement/receipt-tolerances/:id/edit',
      name: 'receiptToleranceRuleEdit',
      component: ReceiptToleranceRuleCreate
    },
    {
      path: '/procurement/matching-tolerances',
      redirect: '/procurement/tolerances?tab=matching'
    },
    {
      path: '/procurement/matching-tolerances/create',
      name: 'matchingToleranceRuleCreate',
      component: MatchingToleranceRuleCreate
    },
    {
      path: '/procurement/matching-tolerances/:id/edit',
      name: 'matchingToleranceRuleEdit',
      component: MatchingToleranceRuleCreate
    },
    {
      path: '/procurement/plans',
      name: 'procurementPlans',
      component: ProcurementPlansView
    },
    {
      path: '/procurement/plans/create',
      name: 'procurementPlanCreate',
      component: ProcurementPlanCreate
    },
    {
      path: '/procurement/plans/items/create',
      name: 'procurementPlanItemCreate',
      component: ProcurementPlanItemCreate
    },
    {
      path: '/procurement/plans/:id',
      name: 'procurementPlanDetail',
      component: ProcurementPlanDetail
    },
    {
      path: '/procurement/plans/:id/edit',
      name: 'procurementPlanEdit',
      component: ProcurementPlanCreate
    },
    {
      path: '/procurement/supplier-registrations',
      name: 'supplierRegistrations',
      component: SupplierRegistrationsView
    },
    {
      path: '/procurement/supplier-registrations/create',
      name: 'supplierRegistrationCreate',
      component: SupplierRegistrationCreate
    },
    {
      path: '/procurement/supplier-registrations/:id',
      name: 'supplierRegistrationDetail',
      component: SupplierRegistrationDetail
    },
    {
      path: '/procurement/supplier-registrations/:id/edit',
      name: 'supplierRegistrationEdit',
      component: SupplierRegistrationCreate
    },
    {
      path: '/procurement/suppliers',
      name: 'suppliers',
      component: SuppliersView
    },
    {
      path: '/procurement/suppliers/:id',
      name: 'supplierDetail',
      component: SupplierDetail
    },
    {
      path: '/procurement/performance-setup',
      name: 'supplierPerformanceSetup',
      component: SupplierPerformanceSetupView
    }
  ]
});

export default router;
