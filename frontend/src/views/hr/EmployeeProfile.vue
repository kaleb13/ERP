<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Users, User, UserCheck, Plus, Search, Filter, ArrowUpDown, ChevronDown, 
  MapPin, Heart, GraduationCap, Award, Briefcase, Sparkles, Languages, 
  MoreVertical, Edit2, Trash2, Eye, EyeOff, Copy, Check, Phone, Mail, Globe, 
  Building2, ShieldCheck, FileText, Calendar, CheckCircle2, AlertCircle, 
  Layers, ExternalLink, X, PlusCircle, UserPlus, Info, ChevronLeft, ArrowDown, ArrowUp,
  CreditCard, Landmark, Shield, Clock, FileCheck, AlertTriangle, Download,
  LayoutDashboard, ChevronRight, UploadCloud, Monitor, DollarSign, CalendarDays,
  Clock4, CheckCircle, ArrowUpRight
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import MetricCard from '../../components/MetricCard.vue';
import UnderlineTabs, { type UnderlineTabItem } from '../../components/UnderlineTabs.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

// ─── Lookups & Types ───
export type EmploymentStatus = 'draft' | 'probation' | 'active' | 'suspended' | 'on_leave' | 'separated' | 'deactivated';
export type EmploymentType = 'permanent' | 'contract' | 'temporary' | 'probation' | 'part_time' | 'intern' | 'consultant';
export type ComplianceItemType = 'fayda_verification' | 'pension_registration' | 'work_permit' | 'medical_check' | 'police_clearance' | 'professional_license' | 'tax_registration';
export type ComplianceStatus = 'pending' | 'valid' | 'expiring' | 'expired' | 'waived' | 'rejected';
export type BankAccountState = 'pending_verification' | 'verified' | 'rejected' | 'closed';
export type EmergencyRelation = 'spouse' | 'parent' | 'child' | 'sibling' | 'relative' | 'friend' | 'colleague';
export type DisabilitySeverity = 'mild' | 'moderate' | 'severe';
export type DisabilityType = 'visual' | 'hearing' | 'physical' | 'speech' | 'intellectual' | 'psychosocial' | 'multiple' | 'other';
export type ContractState = 'draft' | 'pending_signature' | 'active' | 'expiring' | 'expired' | 'terminated' | 'renewed';
export type ContractType = 'indefinite' | 'fixed_term' | 'project_based' | 'casual';
export type GuaranteePurpose = 'cash_handling' | 'loan' | 'study_bond' | 'asset_custody' | 'general';
export type GuaranteeState = 'draft' | 'active' | 'expired' | 'revoked' | 'released';
export type GuaranteeRevocationState = 'pending' | 'approved' | 'rejected';
export type CollateralStatus = 'requested' | 'approved' | 'rejected' | 'finished';
export type CollateralApprovalState = 'pending' | 'approved' | 'rejected';
export type NamePrefix = 'ato' | 'woizero' | 'woizerit' | 'dr' | 'prof' | 'eng' | 'other';
export type RowState = 'active' | 'inactive';

// ─── Interfaces ───
export interface EmployeeRecord {
  id: number;
  uuid: string;
  employee_id: number;
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  employee_number: string;
  employee_name: string;
  first_name?: string;
  middle_name?: string;
  last_name?: string;
  job_title: string;
  job_grade?: string;
  job_grade_step?: string;
  department_name: string;
  reports_to?: string;
  hire_date: string;
  probation_end_date?: string;
  confirmation_date?: string;
  employment_type: EmploymentType;
  employment_status: EmploymentStatus;
  pension_number?: string;
  tin?: string;
  photo?: string;
  notes?: string;
  hired_from_candidate_id?: number;
  hired_from_recruitment_result_id?: number;
  hired_from_job_offer_id?: number;
  hired_from_job_posting_id?: number;
  work_email?: string;
  personal_email?: string;
  phone?: string;
  fayda_id?: string;
  signature?: string;
  // Demographics (PartyDetail)
  gender?: string;
  birth_date?: string;
  birth_place?: string;
  marital_status?: string;
  blood_group?: string;
  nationality_country?: string;
  nationality_type?: string;
  // Residence (PartyAddress)
  address_type?: string;
  address_country?: string;
  residence_region?: string;
  residence_subcity?: string;
  residence_woreda?: string;
  residence_kebele?: string;
  residence_house_number?: string;
  residence_line?: string;
  residence_postal_code?: string;
  address_effective_from?: string;
  address_effective_to?: string;
  // Remuneration & Compensation Package (EmployeeSalary)
  basic_amount?: number;
  transport_allowance?: number;
  housing_allowance?: number;
  other_allowance?: number;
  currency?: string;
  payroll_group?: string;
  salary_structure?: string;
  salary_effective_date?: string;
  package_authorized_by?: string;
  state: RowState;
}

export interface EmployeeStatusHistory {
  id: number;
  uuid: string;
  employee_id: number;
  status_lookup_value_id: EmploymentStatus;
  effective_date: string;
  end_date?: string;
  reason?: string;
  source_type: string;
  source_id: number;
  state: RowState;
}

export interface EmploymentContract {
  id: number;
  uuid: string;
  code: string;
  employee_id: number;
  contract_type_lookup_value_id: ContractType;
  contract_state_lookup_value_id: ContractState;
  start_date: string;
  end_date?: string;
  probation_months?: number;
  is_working_days_only: boolean;
  notice_period_days?: number;
  weekly_hours: number;
  shift_pattern?: string;
  signed_at?: string;
  terms?: string;
  state: RowState;
}

export interface EmployeeCompliance {
  id: number;
  uuid: string;
  employee_id: number;
  item_type_lookup_value_id: ComplianceItemType;
  status_lookup_value_id: ComplianceStatus;
  reference_number?: string;
  issued_date?: string;
  expiry_date?: string;
  verified_by_employee_id?: number;
  verified_by_name?: string;
  verified_at?: string;
  notes?: string;
  state: RowState;
}

export interface EmployeeBankAccount {
  id: number;
  uuid: string;
  employee_id: number;
  payment_provider_id: number;
  bank_name: string;
  account_number: string;
  account_holder_name: string;
  branch_name?: string;
  currency_id: string;
  is_primary: boolean;
  split_percent?: number;
  account_state_lookup_value_id: BankAccountState;
  state: RowState;
}

export interface EmployeeGuarantee {
  id: number;
  uuid: string;
  code: string;
  employee_id: number;
  tenant_id?: number;
  entity_id?: number;
  guarantor_party_id: number;
  guarantor_name: string;
  guarantor_phone?: string;
  guarantor_id_number?: string;
  relation_lookup_value_id?: EmergencyRelation;
  guarantor_employer_party_id?: number;
  guarantor_employer_name?: string;
  guarantor_monthly_income?: number;
  purpose_lookup_value_id: GuaranteePurpose;
  guaranteed_amount: number;
  currency_id: string;
  letter_number?: string;
  letter_date?: string;
  start_date: string;
  end_date?: string | null;
  attachment?: string;
  guarantee_state_lookup_value_id: GuaranteeState;
  state: RowState;
}

export interface StatutoryExemptionRecord {
  id: number;
  rule_type: string;
  category: string;
  effective_from: string;
  effective_to?: string | null;
  status: string;
  notes?: string;
}

export interface EmployeeDependentItem {
  id: number;
  uuid: string;
  employee_id: number;
  dependent_name: string;
  relation: EmergencyRelation;
  birth_date: string;
  is_beneficiary: boolean;
  benefit_notes?: string;
  state: RowState;
}

export interface EmployeeEmergencyContactItem {
  id: number;
  uuid: string;
  employee_id: number;
  contact_name: string;
  phone: string;
  relation: EmergencyRelation;
  priority: number;
  city: string;
  sub_city: string;
  state: RowState;
}

export interface EmployeeDisabilityItem {
  id: number;
  uuid: string;
  employee_id: number;
  disability_type: DisabilityType;
  severity?: DisabilitySeverity;
  is_self_declared: boolean;
  certificate_reference?: string;
  affects_work_capacity: boolean;
  is_confidential: boolean;
  accommodation_notes?: string;
  is_verified: boolean;
  verified_by?: string;
  state: RowState;
}

export interface EmployeeQualificationItem {
  id: number;
  uuid: string;
  employee_id: number;
  level: string;
  field_of_study: string;
  institution: string;
  country?: string;
  start_date?: string;
  graduation_date: string;
  gpa: number;
  is_verified: boolean;
  verified_by?: string;
  state: RowState;
}

export interface EmployeeCertificationItem {
  id: number;
  uuid: string;
  employee_id: number;
  name: string;
  institution: string;
  certificate_number: string;
  issued_date: string;
  expiry_date?: string;
  url?: string;
  is_verified: boolean;
  verified_by?: string;
  state: RowState;
}

export interface EmployeeExperienceItem {
  id: number;
  uuid: string;
  employee_id: number;
  employer_name: string;
  position_title: string;
  employment_type?: string;
  start_date: string;
  end_date?: string;
  responsibilities?: string;
  reason_for_leaving?: string;
  reference_person?: string;
  reference_phone?: string;
  is_relevant: boolean;
  is_verified: boolean;
  state: RowState;
}

// ─── Initial Seed Data (Ethiopian ERP Grounded) ───
const initialEmployees: EmployeeRecord[] = [
  {
    id: 1,
    uuid: 'emp_0007',
    employee_id: 7,
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    employee_number: 'EMP-0007',
    employee_name: 'Selamawit Bekele',
    first_name: 'Selamawit',
    middle_name: 'Bekele',
    last_name: 'Haile',
    job_title: 'Head of People & Culture',
    job_grade: 'Grade A1',
    job_grade_step: 'Step 3',
    department_name: 'Human Resources',
    reports_to: 'Executive Committee',
    hire_date: '2022-01-10',
    confirmation_date: '2022-03-10',
    employment_type: 'permanent',
    employment_status: 'active',
    pension_number: 'PN-104921',
    tin: '0045213387',
    photo: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    work_email: 's.bekele@haleta.et',
    personal_email: 'selam.bekele@gmail.com',
    phone: '+251 91 123 4567',
    fayda_id: 'FYD-33018820714',
    gender: 'Female',
    birth_date: '1990-04-12',
    birth_place: 'Addis Ababa',
    marital_status: 'Married',
    blood_group: 'A+',
    nationality_country: 'Ethiopia',
    nationality_type: 'Citizen',
    residence_region: 'Addis Ababa',
    residence_subcity: 'Bole Sub-City',
    residence_kebele: 'Woreda 03 / Kebele 08',
    residence_house_number: 'B24/11',
    residence_line: 'Cameroon Street, near Edna Mall',
    residence_postal_code: '1176',
    basic_amount: 54000,
    transport_allowance: 2200,
    housing_allowance: 8000,
    other_allowance: 0,
    currency: 'ETB',
    payroll_group: 'Executive & Management',
    salary_structure: 'Executive & Leadership Tier',
    notes: 'Member of human resources committee. Handles senior management appointments.',
    state: 'active'
  },
  {
    id: 2,
    uuid: 'emp_0014',
    employee_id: 14,
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    employee_number: 'EMP-00124',
    employee_name: 'Abebe Kebede',
    first_name: 'Abebe',
    middle_name: 'Kebede',
    last_name: 'Mola',
    job_title: 'Senior Accountant',
    job_grade: 'Grade B2',
    job_grade_step: 'Step 2',
    department_name: 'Finance',
    reports_to: 'Fitsum Assefa (Finance Manager)',
    hire_date: '2024-01-15',
    probation_end_date: '2024-07-15',
    confirmation_date: '2024-07-16',
    employment_type: 'permanent',
    employment_status: 'active',
    pension_number: 'PN-204415',
    tin: '0051177245',
    photo: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
    work_email: 'abebe.kebede@haleta.com',
    personal_email: 'abebe.kebede.m@gmail.com',
    phone: '+251 911 123 456',
    fayda_id: 'FYD-90114522208',
    gender: 'Male',
    birth_date: '1992-03-12',
    birth_place: 'Hawassa',
    marital_status: 'Married',
    blood_group: 'O+',
    nationality_country: 'Ethiopian',
    nationality_type: 'Citizen',
    residence_region: 'Addis Ababa',
    residence_subcity: 'Bole',
    residence_kebele: 'Kebele 04 / Piazza',
    residence_house_number: 'H-102',
    residence_line: 'Main Commercial Boulevard',
    residence_postal_code: '1700',
    basic_amount: 72000,
    transport_allowance: 4240,
    housing_allowance: 11000,
    other_allowance: 1500,
    currency: 'ETB',
    payroll_group: 'Standard Monthly Payroll',
    salary_structure: 'Standard Commercial Staff Grade',
    salary_effective_date: '2024-01-15',
    package_authorized_by: 'Executive Committee',
    hired_from_candidate_id: 487,
    hired_from_recruitment_result_id: 774,
    hired_from_job_offer_id: 29,
    hired_from_job_posting_id: 15,
    notes: 'Recruited from 2024 Talent Pool. Top interview score for general ledger accounting and treasury disbursements.',
    state: 'active'
  },
  {
    id: 3,
    uuid: 'emp_0022',
    employee_id: 22,
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    employee_number: 'EMP-0022',
    employee_name: 'Tigist Alemu',
    first_name: 'Tigist',
    middle_name: 'Alemu',
    last_name: 'Desta',
    job_title: 'Treasury Supervisor',
    job_grade: 'Grade B1',
    job_grade_step: 'Step 4',
    department_name: 'Treasury',
    reports_to: 'Rahel Girma (Finance Director)',
    hire_date: '2021-09-15',
    confirmation_date: '2021-11-15',
    employment_type: 'permanent',
    employment_status: 'active',
    pension_number: 'PN-098412',
    tin: '0032890114',
    photo: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
    work_email: 't.alemu@haleta.et',
    personal_email: 'tigist.alemu88@yahoo.com',
    phone: '+251 91 234 5678',
    fayda_id: 'FYD-55102938471',
    gender: 'Female',
    birth_date: '1993-11-20',
    birth_place: 'Addis Ababa',
    marital_status: 'Single',
    blood_group: 'B+',
    nationality_country: 'Ethiopia',
    nationality_type: 'Citizen',
    residence_region: 'Addis Ababa',
    residence_subcity: 'Kirkos Sub-City',
    residence_kebele: 'Woreda 02',
    residence_house_number: 'K44/19',
    residence_line: 'Olympia, near Dembel City Center',
    residence_postal_code: '1000',
    basic_amount: 32000,
    transport_allowance: 2200,
    housing_allowance: 3000,
    other_allowance: 0,
    currency: 'ETB',
    payroll_group: 'Standard Monthly Payroll',
    salary_structure: 'Standard Commercial Staff Grade',
    notes: 'Handles major banking operations and treasury disbursements.',
    state: 'active'
  }
];

// ─── Reactive State ───
const router = useRouter();
const employees = ref<EmployeeRecord[]>(initialEmployees);
const viewMode = ref<'list' | 'detail'>('list');
const selectedEmployeeId = ref<number>(14);

const selectedEmployee = computed(() => {
  return employees.value.find(e => e.employee_id === selectedEmployeeId.value) || employees.value[0] || null;
});

const selectedEmployeeGross = computed(() => {
  if (!selectedEmployee.value) return '0 ETB';
  const basic = selectedEmployee.value.basic_amount || 72000;
  const transport = selectedEmployee.value.transport_allowance ?? 4240;
  const housing = selectedEmployee.value.housing_allowance ?? 11000;
  const other = selectedEmployee.value.other_allowance ?? 1500;
  return `${(basic + transport + housing + other).toLocaleString()} ETB`;
});

// Breadcrumbs with Clickable Directory Link
const breadcrumbItems = computed(() => {
  if (viewMode.value === 'detail' && selectedEmployee.value) {
    return [
      { label: 'Employee Directory', to: '/hr/employees', onClick: () => { viewMode.value = 'list'; } },
      { label: `${selectedEmployee.value.employee_number} — ${selectedEmployee.value.employee_name}` }
    ];
  }
  return [
    { label: 'Employee Directory' }
  ];
});

// ─── Table Search & Filter State ───
const searchQuery = ref('');
const filterStatus = ref('All');
const filterType = ref('All');
const filterDepartment = ref('All');
const currentSort = ref('name');
const sortOrder = ref<'asc' | 'desc'>('asc');

const activeFilterCount = computed(() => {
  let count = 0;
  if (filterStatus.value !== 'All') count++;
  if (filterType.value !== 'All') count++;
  if (filterDepartment.value !== 'All') count++;
  return count;
});

// ─── Table Columns Configuration ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'identity', label: 'Employee Name & Identity', visible: true, sortable: true },
  { key: 'phone', label: 'Phone Number', visible: true, sortable: false },
  { key: 'email', label: 'Work Email', visible: true, sortable: false },
  { key: 'position', label: 'Job Title & Grade', visible: true, sortable: true },
  { key: 'department', label: 'Department', visible: true, sortable: true },
  { key: 'gender', label: 'Gender', visible: false, sortable: true },
  { key: 'type', label: 'Contract Type', visible: true, sortable: true },
  { key: 'fayda', label: 'Fayda ID (NIDP)', visible: false, sortable: false },
  { key: 'tin', label: 'TIN Number', visible: false, sortable: false },
  { key: 'pension', label: 'POESSA Pension', visible: false, sortable: false },
  { key: 'status', label: 'State', visible: true, sortable: true }
]);

const handleToggleColumn = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  if (col) {
    col.visible = !col.visible;
  }
};

const isColumnVisible = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  return col ? col.visible !== false : true;
};

const visibleColumnsCount = computed(() => {
  return tableColumns.value.filter(c => c.visible !== false).length;
});

// Row Selection
const selectedRowIds = ref<number[]>([]);
const isAllSelected = computed(() => {
  return filteredEmployees.value.length > 0 && selectedRowIds.value.length === filteredEmployees.value.length;
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = filteredEmployees.value.map(e => e.id);
  }
};

const toggleRowSelection = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx > -1) {
    selectedRowIds.value.splice(idx, 1);
  } else {
    selectedRowIds.value.push(id);
  }
};

// Filtering & Pagination
const departmentOptions = computed(() => {
  const depts = new Set(employees.value.map(e => e.department_name));
  return ['All', ...Array.from(depts)];
});

const filteredEmployees = computed(() => {
  return employees.value.filter(emp => {
    const q = searchQuery.value.trim().toLowerCase();
    if (q) {
      const matchName = emp.employee_name.toLowerCase().includes(q);
      const matchCode = emp.employee_number.toLowerCase().includes(q);
      const matchTitle = emp.job_title.toLowerCase().includes(q);
      const matchDept = emp.department_name.toLowerCase().includes(q);
      const matchEmail = (emp.work_email || '').toLowerCase().includes(q);
      const matchPhone = (emp.phone || '').includes(q);
      if (!matchName && !matchCode && !matchTitle && !matchDept && !matchEmail && !matchPhone) {
        return false;
      }
    }
    if (filterStatus.value !== 'All' && emp.employment_status !== filterStatus.value.toLowerCase()) return false;
    if (filterType.value !== 'All' && emp.employment_type !== filterType.value.toLowerCase()) return false;
    if (filterDepartment.value !== 'All' && emp.department_name !== filterDepartment.value) return false;
    return true;
  }).sort((a, b) => {
    let factor = sortOrder.value === 'asc' ? 1 : -1;
    if (currentSort.value === 'name') {
      return a.employee_name.localeCompare(b.employee_name) * factor;
    } else if (currentSort.value === 'status') {
      return a.employment_status.localeCompare(b.employment_status) * factor;
    } else if (currentSort.value === 'department') {
      return a.department_name.localeCompare(b.department_name) * factor;
    } else if (currentSort.value === 'position') {
      return a.job_title.localeCompare(b.job_title) * factor;
    }
    return 0;
  });
});

const currentPage = ref(1);
const pageSize = ref(10);

const paginatedEmployees = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value;
  return filteredEmployees.value.slice(start, start + pageSize.value);
});

// Action Dots Dropdown Menu
const openMenuId = ref<number | null>(null);
const toggleActionMenu = (e: MouseEvent, id: number) => {
  e.stopPropagation();
  openMenuId.value = openMenuId.value === id ? null : id;
};
const closeActionMenu = () => {
  openMenuId.value = null;
};

// Copy helper
const copiedId = ref<string | null>(null);
const copyText = async (val?: string) => {
  if (!val) return;
  await navigator.clipboard.writeText(val);
  copiedId.value = val;
  setTimeout(() => { copiedId.value = null; }, 1500);
};

// Master to Detail
const selectEmployeeForDetail = (empId: number) => {
  selectedEmployeeId.value = empId;
  viewMode.value = 'detail';
  activeTab.value = 'overview';
};

// ─── Tabs for Profile Detail (UnderlineTabs Standard) ───
type ProfileTabId = 'overview' | 'personal' | 'employment' | 'compensation' | 'qualifications' | 'compliance' | 'family';
const activeTab = ref<ProfileTabId>('overview');

const profileTabs = computed<UnderlineTabItem<ProfileTabId>[]>(() => [
  { id: 'overview', label: 'Overview', icon: LayoutDashboard },
  { id: 'personal', label: 'Personal', icon: User },
  { id: 'employment', label: 'Employment', icon: Briefcase },
  { id: 'compensation', label: 'Compensation', count: bankAccounts.value.length, icon: Landmark },
  { id: 'qualifications', label: 'Qualifications', count: qualifications.value.length + certifications.value.length + experiences.value.length, icon: GraduationCap },
  { id: 'compliance', label: 'Compliance', count: complianceItems.value.length + guarantees.value.length, icon: ShieldCheck },
  { id: 'family', label: 'Family', count: emergencyContacts.value.length + dependents.value.length, icon: Heart }
]);

// ─── Sub-Records (Aligned with EmployeeCreate.vue Form Models) ───
const statusHistory = ref<EmployeeStatusHistory[]>([
  { id: 1, uuid: 'sh_1', employee_id: 14, status_lookup_value_id: 'probation', effective_date: '2024-01-15', end_date: '2024-07-15', reason: 'Initial hire appointment', source_type: 'EmployeeMovement', source_id: 101, state: 'active' },
  { id: 2, uuid: 'sh_2', employee_id: 14, status_lookup_value_id: 'active', effective_date: '2024-07-16', reason: 'Probation confirmed by HR', source_type: 'ConfirmationMovement', source_id: 108, state: 'active' }
]);

const contracts = ref<EmploymentContract[]>([
  { id: 1, uuid: 'ctr_1', code: 'CTR-2024-0014', employee_id: 14, contract_type_lookup_value_id: 'indefinite', contract_state_lookup_value_id: 'active', start_date: '2024-01-15', probation_months: 6, is_working_days_only: true, notice_period_days: 30, weekly_hours: 40, shift_pattern: 'Standard 5-Day Daytime Shift', signed_at: '2024-01-10T10:00:00Z', terms: 'Standard Haleta Group Full-Time Employment Agreement with 5-day operating schedule.', state: 'active' }
]);

const complianceItems = ref<EmployeeCompliance[]>([
  { id: 1, uuid: 'cmp_1', employee_id: 14, item_type_lookup_value_id: 'fayda_verification', status_lookup_value_id: 'valid', reference_number: 'FYD-90114522208', issued_date: '2024-01-10', verified_by_employee_id: 7, verified_by_name: 'Selamawit Bekele', verified_at: '2024-01-10T09:30:00Z', notes: 'National ID verified against Fayda civil registry API.', state: 'active' },
  { id: 2, uuid: 'cmp_2', employee_id: 14, item_type_lookup_value_id: 'medical_check', status_lookup_value_id: 'valid', reference_number: 'MC-2025-4411', issued_date: '2025-01-10', expiry_date: '2026-01-10', verified_by_employee_id: 7, verified_by_name: 'Selamawit Bekele', verified_at: '2025-01-10T11:00:00Z', notes: 'Annual occupational fitness screening at Bethzatha Hospital.', state: 'active' },
  { id: 3, uuid: 'cmp_3', employee_id: 14, item_type_lookup_value_id: 'police_clearance', status_lookup_value_id: 'valid', reference_number: 'FP-2024-9182', issued_date: '2024-01-05', verified_by_employee_id: 7, verified_by_name: 'Selamawit Bekele', verified_at: '2024-01-08T11:00:00Z', notes: 'Federal Police Forensic Division Background Clearance Certificate.', state: 'active' },
  { id: 4, uuid: 'cmp_4', employee_id: 14, item_type_lookup_value_id: 'professional_license', status_lookup_value_id: 'valid', reference_number: 'ACCA-ETH-2022-841', issued_date: '2022-04-10', verified_by_employee_id: 7, verified_by_name: 'Selamawit Bekele', verified_at: '2024-01-20T14:15:00Z', notes: 'ACCA Ethiopian Board of Accounting and Auditing license verification.', state: 'active' }
]);

const statutoryExemptions = ref<StatutoryExemptionRecord[]>([
  {
    id: 1,
    rule_type: 'POESSA Permanent Pension Remittance',
    category: 'Statutory Pension Law No. 715/2011',
    effective_from: '2024-01-15',
    effective_to: null,
    status: 'Standard Contributor (7% + 11%)',
    notes: 'Standard private organization statutory pension contribution.'
  },
  {
    id: 2,
    rule_type: 'Employment Income Tax (PIT)',
    category: 'Federal Tax Administration Proclamation',
    effective_from: '2024-01-15',
    effective_to: null,
    status: 'Progressive Schedule (0% – 35%)',
    notes: 'Automated PAYE progressive tax schedule deduction.'
  }
]);

const bankAccounts = ref<EmployeeBankAccount[]>([
  { id: 1, uuid: 'bnk_1', employee_id: 14, payment_provider_id: 4, bank_name: 'Commercial Bank of Ethiopia (CBE)', account_number: '1000512230871', account_holder_name: 'Abebe Kebede Mola', branch_name: 'Bole Medhanealem Branch', currency_id: 'ETB', is_primary: true, split_percent: 80, account_state_lookup_value_id: 'verified', state: 'active' },
  { id: 2, uuid: 'bnk_2', employee_id: 14, payment_provider_id: 7, bank_name: 'Awash International Bank', account_number: '0134420115523', account_holder_name: 'Abebe Kebede Mola', branch_name: 'Addis Ababa Main Branch', currency_id: 'ETB', is_primary: false, split_percent: 20, account_state_lookup_value_id: 'verified', state: 'active' }
]);

const guarantees = ref<EmployeeGuarantee[]>([
  {
    id: 1,
    uuid: 'grt_1',
    code: 'GRT-2024-0011',
    employee_id: 14,
    tenant_id: 1,
    entity_id: 3,
    guarantor_party_id: 941,
    guarantor_name: 'Daniel Kebede Mola',
    guarantor_phone: '+251 91 144 8872',
    guarantor_id_number: 'FYD-8820194412',
    relation_lookup_value_id: 'sibling',
    guarantor_employer_party_id: 88,
    guarantor_employer_name: 'Awash Bank S.C.',
    guarantor_monthly_income: 38500,
    purpose_lookup_value_id: 'cash_handling',
    guaranteed_amount: 150000,
    currency_id: 'ETB',
    letter_number: 'AIB/HR/2024/991',
    letter_date: '2024-01-10',
    start_date: '2024-01-15',
    end_date: null,
    attachment: 'GRT-2024-0011_signed_surety.pdf',
    guarantee_state_lookup_value_id: 'active',
    state: 'active'
  }
]);

const dependents = ref<EmployeeDependentItem[]>([
  { id: 1, uuid: 'dep_1', employee_id: 14, dependent_name: 'Solomon Kebede', relation: 'child', birth_date: '2019-04-12', is_beneficiary: true, benefit_notes: 'Haleta Medical Plan & POESSA survivor registered', state: 'active' },
  { id: 2, uuid: 'dep_2', employee_id: 14, dependent_name: 'Hiwot Tadesse', relation: 'spouse', birth_date: '1995-10-08', is_beneficiary: true, benefit_notes: 'POESSA pension survivor registered', state: 'active' }
]);

const emergencyContacts = ref<EmployeeEmergencyContactItem[]>([
  { id: 1, uuid: 'ec_1', employee_id: 14, contact_name: 'Hiwot Tadesse', phone: '+251 91 298 3341', relation: 'spouse', priority: 1, city: 'Addis Ababa', sub_city: 'Bole Sub-City', state: 'active' },
  { id: 2, uuid: 'ec_2', employee_id: 14, contact_name: 'Daniel Kebede', phone: '+251 91 144 8872', relation: 'sibling', priority: 2, city: 'Addis Ababa', sub_city: 'Kirkos Sub-City', state: 'active' }
]);

const disabilities = ref<EmployeeDisabilityItem[]>([
  { id: 1, uuid: 'dis_1', employee_id: 14, disability_type: 'hearing', severity: 'moderate', is_self_declared: true, certificate_reference: 'MOLS-DIS-2024-88', affects_work_capacity: false, is_confidential: true, accommodation_notes: 'Equipped with digital hearing assistive unit and visual workstation fire alarm beacon.', is_verified: true, verified_by: 'Selamawit Bekele', state: 'active' }
]);

const qualifications = ref<EmployeeQualificationItem[]>([
  { id: 1, uuid: 'q_1', employee_id: 14, level: 'Bachelor of Science (B.Sc.)', field_of_study: 'Accounting & Finance', institution: 'Addis Ababa University', country: 'Ethiopia', start_date: '2012-09-01', graduation_date: '2016-07-15', gpa: 3.75, is_verified: true, verified_by: 'Selamawit Bekele', state: 'active' },
  { id: 2, uuid: 'q_2', employee_id: 14, level: 'Master of Science (M.Sc.)', field_of_study: 'Finance & Financial Analytics', institution: 'Addis Ababa University', country: 'Ethiopia', start_date: '2021-09-01', graduation_date: '2023-06-30', gpa: 3.88, is_verified: true, verified_by: 'Selamawit Bekele', state: 'active' }
]);

const certifications = ref<EmployeeCertificationItem[]>([
  { id: 1, uuid: 'c_1', employee_id: 14, name: 'Chartered Certified Accountant (ACCA)', institution: 'ACCA Global', certificate_number: 'ACCA-ETH-2022-841', issued_date: '2022-04-10', url: 'https://www.accaglobal.com', is_verified: true, verified_by: 'Selamawit Bekele', state: 'active' }
]);

const experiences = ref<EmployeeExperienceItem[]>([
  { 
    id: 1, 
    uuid: 'e_1', 
    employee_id: 14, 
    employer_name: 'Shoa Supermarket S.C.', 
    position_title: 'Operations Accountant', 
    employment_type: 'Permanent',
    start_date: '2018-09-01', 
    end_date: '2023-12-31', 
    responsibilities: 'Managed high-volume inventory accounting, branch reconciliation, supplier invoice verification, and VAT declarations.', 
    reason_for_leaving: 'Career advancement & relocation to Haleta HQ',
    reference_person: 'Ato Solomon Tadesse (Finance Director)',
    reference_phone: '+251 911 234 890',
    is_relevant: true, 
    is_verified: true, 
    state: 'active' 
  },
  { 
    id: 2, 
    uuid: 'e_2', 
    employee_id: 14, 
    employer_name: 'Awash Wine S.C.', 
    position_title: 'Junior Cost Accountant', 
    employment_type: 'Permanent',
    start_date: '2016-07-01', 
    end_date: '2018-08-31', 
    responsibilities: 'Assisted in production batch costing, inventory reconciliations, and factory payroll verification.', 
    reason_for_leaving: 'Opportunity for promotion to senior role',
    reference_person: 'W/ro Bethlehem Girma (Chief Accountant)',
    reference_phone: '+251 922 456 781',
    is_relevant: true, 
    is_verified: true, 
    state: 'active' 
  }
]);

const skillsList = ref<string[]>([
  'Financial Modeling', 'IFRS Standards', 'General Ledger Accounting', 'Tax Filings & e-Tax', 'Haleta ERP', 'Auditing', 'Cash Flow Analysis'
]);

const languagesList = ref([
  { name: 'Amharic', level: 'Native', speaking: 'Native', writing: 'Native', reading: 'Native', listening: 'Native' },
  { name: 'English', level: 'Fluent (C2)', speaking: 'Fluent', writing: 'Fluent', reading: 'Fluent', listening: 'Fluent' },
  { name: 'Afaan Oromoo', level: 'Conversational', speaking: 'Intermediate', writing: 'Basic', reading: 'Intermediate', listening: 'Intermediate' }
]);

// ─── Bank Masking State & Helpers ───
const showBankNumbers = ref<Record<string | number, boolean>>({});
const toggleBankMask = (id: string | number) => {
  showBankNumbers.value[id] = !showBankNumbers.value[id];
};

const getMaskedAccountNumber = (accNo: string, id: string | number) => {
  if (!accNo) return '—';
  if (showBankNumbers.value[id]) return accNo;
  const lastFour = accNo.slice(-4);
  return `•••• •••• •••• ${lastFour}`;
};

// ─── Date & Tenure Formatting Helpers ───
const formatDate = (dateStr?: string) => {
  if (!dateStr) return '—';
  try {
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;
    return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
  } catch {
    return dateStr;
  }
};

const calculateAge = (birthDateStr?: string) => {
  if (!birthDateStr) return 32;
  try {
    const b = new Date(birthDateStr);
    const now = new Date();
    let age = now.getFullYear() - b.getFullYear();
    const m = now.getMonth() - b.getMonth();
    if (m < 0 || (m === 0 && now.getDate() < b.getDate())) age--;
    return age > 0 ? age : 32;
  } catch {
    return 32;
  }
};

const calculateTenure = (hireDateStr?: string) => {
  if (!hireDateStr) return '1 yr 7 mos';
  try {
    const h = new Date(hireDateStr);
    const now = new Date();
    const diffMonths = (now.getFullYear() - h.getFullYear()) * 12 + (now.getMonth() - h.getMonth());
    const years = Math.floor(diffMonths / 12);
    const months = diffMonths % 12;
    if (years <= 0) return `${months} mos`;
    if (months === 0) return `${years} yr${years > 1 ? 's' : ''}`;
    return `${years} yr${years > 1 ? 's' : ''} ${months} mo${months > 1 ? 's' : ''}`;
  } catch {
    return '1 yr 7 mos';
  }
};

// ─── Quick Actions Feedback Toast ───
const quickActionToast = ref<string | null>(null);
const handleQuickAction = (action: string) => {
  if (action === 'edit') {
    router.push({ path: '/hr/employees/create', query: { editId: selectedEmployee.value?.id } });
    return;
  }
  const messages: Record<string, string> = {
    leave: 'Assign Leave drawer opened for ' + (selectedEmployee.value?.employee_name || 'employee'),
    position: 'Position transfer & promotion dialog initiated',
    document: 'Document upload repository opened',
    asset: 'Asset checkout & assignment catalog opened'
  };
  quickActionToast.value = messages[action] || 'Action triggered';
  setTimeout(() => {
    quickActionToast.value = null;
  }, 2500);
};

// ─── Quick Create Employee Modal ───
const showQuickCreate = ref(false);
const quickForm = ref({
  employee_name: '',
  hire_date: new Date().toISOString().split('T')[0],
  employment_type: 'permanent' as EmploymentType,
  employment_status: 'probation' as EmploymentStatus,
  job_title: 'Junior Auditor',
  department_name: 'Finance & Accounts',
  phone: '',
  work_email: '',
  tin: ''
});

const computedExpandRoute = computed(() => ({
  path: '/hr/employees/create',
  query: {
    name: quickForm.value.employee_name || undefined,
    email: quickForm.value.work_email || undefined,
    phone: quickForm.value.phone || undefined,
    title: quickForm.value.job_title || undefined,
    type: quickForm.value.employment_type || undefined,
    hire_date: quickForm.value.hire_date || undefined
  }
}));

const handleSaveQuickEmployee = () => {
  if (!quickForm.value.employee_name) return;
  const newId = employees.value.length ? Math.max(...employees.value.map(e => e.id)) + 1 : 1;
  const newEmpId = employees.value.length ? Math.max(...employees.value.map(e => e.employee_id)) + 1 : 101;
  const autoEmpNumber = `EMP-${newEmpId.toString().padStart(4, '0')}`;

  const nameParts = quickForm.value.employee_name.trim().split(' ');
  const fName = nameParts[0] || '';
  const mName = nameParts[1] || '';
  const lName = nameParts.slice(2).join(' ') || '';

  const newRec: EmployeeRecord = {
    id: newId,
    uuid: `emp_${Date.now()}`,
    employee_id: newEmpId,
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    employee_number: autoEmpNumber,
    employee_name: quickForm.value.employee_name,
    first_name: fName,
    middle_name: mName,
    last_name: lName,
    job_title: quickForm.value.job_title,
    department_name: quickForm.value.department_name,
    hire_date: quickForm.value.hire_date,
    employment_type: quickForm.value.employment_type,
    employment_status: quickForm.value.employment_status,
    phone: quickForm.value.phone,
    work_email: quickForm.value.work_email,
    tin: quickForm.value.tin,
    state: 'active'
  };

  employees.value.unshift(newRec);
  showQuickCreate.value = false;
  quickForm.value = {
    employee_name: '',
    hire_date: new Date().toISOString().split('T')[0],
    employment_type: 'permanent',
    employment_status: 'probation',
    job_title: 'Junior Auditor',
    department_name: 'Finance & Accounts',
    phone: '',
    work_email: '',
    tin: ''
  };
};

// Floating Bar Action Handlers
const handleFloatingSelectAllEmployees = () => {
  selectedRowIds.value = filteredEmployees.value.map(e => e.id);
};
const handleFloatingDuplicateEmployees = () => {
  alert(`Duplicate requested for ${selectedRowIds.value.length} employee records.`);
};
const handleFloatingEditEmployee = () => {
  if (selectedRowIds.value.length === 1) {
    selectEmployeeForDetail(selectedRowIds.value[0]);
  }
};
const handleFloatingDeleteEmployees = () => {
  employees.value = employees.value.filter(e => !selectedRowIds.value.includes(e.id));
  selectedRowIds.value = [];
};
const handleFloatingChangeStatusEmployees = (newStatus: string) => {
  employees.value.forEach(e => {
    if (selectedRowIds.value.includes(e.id)) {
      e.employment_status = newStatus as EmploymentStatus;
    }
  });
  selectedRowIds.value = [];
};
const handleFloatingExportEmployees = () => {
  alert(`Exporting ${selectedRowIds.value.length} employee profiles.`);
};
const handleFloatingDeactivateEmployees = () => {
  employees.value.forEach(e => {
    if (selectedRowIds.value.includes(e.id)) {
      e.employment_status = 'deactivated';
    }
  });
  selectedRowIds.value = [];
};

const getStatusPillClass = (status: EmploymentStatus) => {
  switch (status) {
    case 'active': return 'status-active';
    case 'probation': return 'status-probation';
    case 'suspended': return 'status-suspended';
    case 'on_leave': return 'status-leave';
    case 'separated':
    case 'deactivated': return 'status-separated';
    case 'draft': default: return 'status-draft';
  }
};

const formatStatus = (status: EmploymentStatus) => {
  switch (status) {
    case 'active': return 'Active';
    case 'probation': return 'Probation';
    case 'suspended': return 'Suspended';
    case 'on_leave': return 'On Leave';
    case 'separated': return 'Separated';
    case 'deactivated': return 'Deactivated';
    case 'draft': return 'Draft';
    default: return status;
  }
};

onMounted(() => {
  window.addEventListener('click', closeActionMenu);
});

onUnmounted(() => {
  window.removeEventListener('click', closeActionMenu);
});
</script>

<template>
  <div class="employee-master-page">
    <!-- Breadcrumb Bar (Clean & Standard) -->
    <div class="page-breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Quick Action Toast Notification -->
    <div v-if="quickActionToast" class="quick-toast-banner">
      <CheckCircle2 :size="15" class="text-emerald-600" />
      <span>{{ quickActionToast }}</span>
    </div>

    <!-- VIEW 1: CANONICAL EMPLOYEE DIRECTORY (APPDATATABLE) -->
    <div v-if="viewMode === 'list'" class="directory-view-wrapper">
      <AppDataTable
        title="Employee Directory"
        subtitle="Manage organizational staff master records, employment lifecycle events, statutory POESSA pension & tax filings, compensation bank accounts, and surety guarantees."
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search Name, Code, TIN, Pension, Email..."
        :showSearch="true"
        :showFilter="true"
        :filterCount="activeFilterCount"
        :showSort="true"
        v-model:currentSort="currentSort"
        v-model:sortOrder="sortOrder"
        :showColumns="true"
        :columns="tableColumns"
        @toggleColumn="handleToggleColumn"
      >
        <template #actions>
          <button 
            type="button" 
            class="btn-primary-create" 
            @click="showQuickCreate = true"
          >
            <Plus :size="15" />
            <span>+ Create Employee</span>
          </button>
        </template>

        <template #filter>
          <div class="filter-grid">
            <FormSelect
              label="Employment Status"
              v-model="filterStatus"
              :options="['All', 'Active', 'Probation', 'Suspended', 'On_Leave', 'Separated', 'Draft']"
            />
            <FormSelect
              label="Contract Type"
              v-model="filterType"
              :options="['All', 'Permanent', 'Contract', 'Temporary', 'Probation', 'Part_Time', 'Intern']"
            />
            <FormSelect
              label="Department"
              v-model="filterDepartment"
              :options="departmentOptions"
            />
          </div>
        </template>

        <table class="erp-table">
          <thead>
            <tr>
              <th class="col-checkbox">
                <input 
                  type="checkbox" 
                  class="custom-checkbox" 
                  :checked="isAllSelected" 
                  @change="toggleSelectAll"
                  aria-label="Select All" 
                />
              </th>
              
              <th v-if="isColumnVisible('identity')" class="col-name sortable" @click="currentSort = 'name'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>Employee Name</span>
                  <ArrowUpDown :size="12" class="sort-icon" />
                </div>
              </th>

              <th v-if="isColumnVisible('phone')" class="col-phone">Phone Number</th>
              <th v-if="isColumnVisible('email')" class="col-email">Work Email</th>
              
              <th v-if="isColumnVisible('position')" class="col-position sortable" @click="currentSort = 'position'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>Job Position</span>
                  <ArrowUpDown :size="12" class="sort-icon" />
                </div>
              </th>

              <th v-if="isColumnVisible('department')" class="col-dept sortable" @click="currentSort = 'department'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>Department</span>
                  <ArrowUpDown :size="12" class="sort-icon" />
                </div>
              </th>

              <th v-if="isColumnVisible('gender')" class="col-gender">Gender</th>
              <th v-if="isColumnVisible('type')" class="col-type">Contract Type</th>
              <th v-if="isColumnVisible('fayda')" class="col-fayda">Fayda ID</th>
              <th v-if="isColumnVisible('tin')" class="col-tin">TIN Number</th>
              <th v-if="isColumnVisible('pension')" class="col-pension">Pension No.</th>

              <th v-if="isColumnVisible('status')" class="col-status sortable" @click="currentSort = 'status'; sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'">
                <div class="th-content">
                  <span>State</span>
                  <ArrowUpDown :size="12" class="sort-icon" />
                </div>
              </th>

              <th class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr 
              v-for="item in paginatedEmployees" 
              :key="item.id" 
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
              @click="selectEmployeeForDetail(item.employee_id)"
              class="cursor-pointer"
            >
              <td class="col-checkbox" @click.stop>
                <input 
                  type="checkbox" 
                  class="custom-checkbox" 
                  :checked="selectedRowIds.includes(item.id)" 
                  @change="toggleRowSelection(item.id)" 
                />
              </td>

              <td v-if="isColumnVisible('identity')" class="col-name">
                <div class="employee-identity-cell">
                  <img 
                    :src="item.photo || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80'" 
                    class="employee-table-avatar" 
                    alt="" 
                  />
                  <div class="employee-meta">
                    <span class="employee-name-text">{{ item.employee_name }}</span>
                    <span class="employee-sub-text font-mono">{{ item.employee_number }}</span>
                  </div>
                </div>
              </td>

              <td v-if="isColumnVisible('phone')" class="col-phone" @click.stop>
                <span class="table-text-val font-mono text-xs">{{ item.phone || '—' }}</span>
              </td>

              <td v-if="isColumnVisible('email')" class="col-email" @click.stop>
                <span class="table-text-val text-primary text-xs">{{ item.work_email || '—' }}</span>
              </td>

              <td v-if="isColumnVisible('position')" class="col-position">
                <span class="table-text-val font-medium">{{ item.job_title }}</span>
              </td>

              <td v-if="isColumnVisible('department')" class="col-dept">
                <span class="table-text-val">{{ item.department_name }}</span>
              </td>

              <td v-if="isColumnVisible('gender')" class="col-gender">
                <span class="table-text-val">{{ item.gender || '—' }}</span>
              </td>

              <td v-if="isColumnVisible('type')" class="col-type">
                <span class="table-type-tag capitalize">{{ item.employment_type }}</span>
              </td>

              <td v-if="isColumnVisible('fayda')" class="col-fayda" @click.stop>
                <span class="table-text-val font-mono text-xs">{{ item.fayda_id || '—' }}</span>
              </td>

              <td v-if="isColumnVisible('tin')" class="col-tin" @click.stop>
                <span class="table-text-val font-mono text-xs">{{ item.tin || '—' }}</span>
              </td>

              <td v-if="isColumnVisible('pension')" class="col-pension" @click.stop>
                <span class="table-text-val font-mono text-xs">{{ item.pension_number || '—' }}</span>
              </td>

              <td v-if="isColumnVisible('status')" class="col-status">
                <span :class="['status-pill', getStatusPillClass(item.employment_status)]">
                  <span class="status-dot"></span>
                  {{ formatStatus(item.employment_status) }}
                </span>
              </td>

              <td class="col-actions" @click.stop>
                <div class="action-cell-wrapper">
                  <button 
                    type="button" 
                    class="btn-action-dots" 
                    @click="toggleActionMenu($event, item.id)"
                    aria-label="Row Actions"
                  >
                    <MoreVertical :size="15" />
                  </button>
                  <div v-if="openMenuId === item.id" class="action-dropdown-menu">
                    <button class="action-menu-item" @click="selectEmployeeForDetail(item.employee_id); closeActionMenu()">
                      <Eye :size="13.5" />
                      <span>View Profile</span>
                    </button>
                    <button class="action-menu-item" @click="router.push({ path: '/hr/employees/create', query: { editId: item.id } }); closeActionMenu()">
                      <Edit2 :size="13.5" />
                      <span>Edit Master</span>
                    </button>
                    <button class="action-menu-item" @click="copyText(item.employee_number); closeActionMenu()">
                      <Copy :size="13.5" />
                      <span>Copy Employee ID</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>

            <tr v-if="paginatedEmployees.length === 0">
              <td :colspan="visibleColumnsCount + 2" class="empty-state-cell">
                <Info :size="24" class="empty-icon" />
                <p>No employee records matched your search or filters.</p>
              </td>
            </tr>
          </tbody>
        </table>
      </AppDataTable>
    </div>

    <!-- VIEW 2: THE 360° EMPLOYEE MASTER PROFILE -->
    <div v-else-if="viewMode === 'detail'" class="profile-detail-wrapper">
      <div v-if="selectedEmployee" class="profile-container">
        
        <!-- HERO PROFILE HEADER BANNER (CLEAN & ALIGNED) -->
        <div class="profile-hero-banner">
          <div class="hero-left-section">
            <div class="hero-avatar-wrapper">
              <img 
                :src="selectedEmployee.photo || 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80'" 
                class="hero-avatar-img" 
                alt="Employee Photo" 
              />
              <div class="avatar-status-badge"></div>
            </div>

            <div class="hero-identity-block">
              <div class="hero-name-row">
                <h1 class="hero-employee-name">{{ selectedEmployee.employee_name }}</h1>
              </div>

              <div class="hero-code-title">
                <span class="font-mono text-xs font-semibold text-slate-700">{{ selectedEmployee.employee_number }}</span>
                <span class="sep-bullet">&bull;</span>
                <span class="hero-title-text">{{ selectedEmployee.job_title }}</span>
                <span class="sep-bullet">&bull;</span>
                <span class="text-xs font-medium text-slate-500">{{ selectedEmployee.job_grade || 'Grade B2' }} ({{ selectedEmployee.job_grade_step || 'Step 2' }})</span>
              </div>

              <div class="hero-tags-row">
                <span class="hero-tag">
                  <Building2 :size="12" class="tag-icon" />
                  {{ selectedEmployee.department_name }}
                </span>
                <span class="hero-tag">
                  <MapPin :size="12" class="tag-icon" />
                  {{ selectedEmployee.residence_subcity || 'Addis Ababa' }}
                </span>
                <span :class="['status-pill', getStatusPillClass(selectedEmployee.employment_status)]">
                  <span class="status-dot"></span>
                  {{ formatStatus(selectedEmployee.employment_status) }}
                </span>
                <span class="hero-tenure-tag">
                  <CalendarDays :size="12" class="tenure-icon" />
                  Joined {{ formatDate(selectedEmployee.hire_date) }} ({{ calculateTenure(selectedEmployee.hire_date) }})
                </span>
              </div>
            </div>
          </div>

          <div class="hero-right-section">
            <div class="hero-contact-card">
              <div class="hero-contact-item">
                <Mail :size="13" class="contact-icon" />
                <a :href="'mailto:' + selectedEmployee.work_email" class="contact-link">{{ selectedEmployee.work_email || 'abebe.kebede@haleta.com' }}</a>
              </div>
              <div class="hero-contact-item">
                <Phone :size="13" class="contact-icon" />
                <span class="font-mono">{{ selectedEmployee.phone || '+251 911 123 456' }}</span>
              </div>
              <div class="hero-contact-item">
                <User :size="13" class="contact-icon" />
                <div>
                  <span class="manager-label">Reports to: </span>
                  <span class="manager-name">{{ selectedEmployee.reports_to || 'Fitsum Assefa (Finance Manager)' }}</span>
                </div>
              </div>
            </div>
            
            <div class="hero-header-actions">
              <button class="btn-hero-edit" @click="handleQuickAction('edit')" title="Edit full master record">
                <Edit2 :size="13" />
                <span>Edit Record</span>
              </button>
            </div>
          </div>
        </div>

        <!-- UNDERLINE TABS BAR (7 STANDARDIZED DOMAINS) -->
        <div class="profile-tabs-wrapper">
          <UnderlineTabs 
            v-model="activeTab"
            :tabs="profileTabs"
            size="md"
            justify="start"
            :showCount="true"
          />
        </div>

        <!-- TAB WORKSPACE CONTENT -->
        <div class="tab-content-area">
          
          <!-- TAB 1: OVERVIEW (EXECUTIVE SUMMARY OF ALL 6 DOMAINS) -->
          <div v-if="activeTab === 'overview'" class="overview-view">
            <!-- Row 1: KPI Metrics Grid (Using Centralized MetricCard Component) -->
            <div class="profile-kpi-grid">
              <MetricCard
                label="Total Leave Balance"
                value="14 Days"
                subtext="Annual leave balance"
                :icon="CalendarDays"
                :showMenu="false"
                class="cursor-pointer"
                @click="activeTab = 'employment'"
              />

              <MetricCard
                label="Attendance (This Month)"
                value="22 / 22 Days"
                subtext="Present on all scheduled days"
                trend="100%"
                trendType="up"
                :icon="Clock4"
                :showMenu="false"
                class="cursor-pointer"
                @click="activeTab = 'employment'"
              />

              <MetricCard
                label="Performance Rating"
                value="4.2 / 5.0"
                subtext="Dec 2024 Evaluation"
                trend="Exceeds"
                trendType="up"
                :icon="Sparkles"
                :showMenu="false"
                class="cursor-pointer"
                @click="activeTab = 'employment'"
              />

              <MetricCard
                label="Current Gross Package"
                :value="selectedEmployeeGross"
                subtext="Monthly base & allowances"
                :icon="Landmark"
                :showMenu="false"
                class="cursor-pointer"
                @click="activeTab = 'compensation'"
              />
            </div>

            <!-- Quick Action Toolbar Strip (Minimalist & Compact) -->
            <div class="quick-action-strip">
              <span class="qa-strip-title">Quick Actions:</span>
              <div class="qa-strip-buttons">
                <button class="qa-strip-btn" @click="handleQuickAction('edit')">
                  <Edit2 :size="13" />
                  <span>Edit Profile</span>
                </button>
                <button class="qa-strip-btn" @click="handleQuickAction('leave')">
                  <Calendar :size="13" />
                  <span>Assign Leave</span>
                </button>
                <button class="qa-strip-btn" @click="handleQuickAction('position')">
                  <Briefcase :size="13" />
                  <span>Transfer / Promotion</span>
                </button>
                <button class="qa-strip-btn" @click="handleQuickAction('document')">
                  <UploadCloud :size="13" />
                  <span>Upload Document</span>
                </button>
                <button class="qa-strip-btn" @click="handleQuickAction('asset')">
                  <Monitor :size="13" />
                  <span>Assign Asset</span>
                </button>
              </div>
            </div>

            <!-- 2-Column Balanced Overview Grid -->
            <div class="overview-dual-grid">
              <!-- Column 1: Employment & Compensation Glance -->
              <div class="overview-column">
                <!-- Employment Glance Card -->
                <div class="content-section-card">
                  <div class="section-card-header">
                    <div class="flex items-center gap-2">
                      <Briefcase :size="14" class="text-primary" />
                      <h3 class="section-card-title">Employment & Placement</h3>
                    </div>
                    <button class="card-header-link" @click="activeTab = 'employment'">Full Record &rarr;</button>
                  </div>
                  <div class="fields-compact-grid">
                    <div class="detail-field">
                      <span class="detail-field-label">Department</span>
                      <span class="detail-field-value font-medium">{{ selectedEmployee.department_name }}</span>
                    </div>
                    <div class="detail-field">
                      <span class="detail-field-label">Position Title</span>
                      <span class="detail-field-value font-medium">{{ selectedEmployee.job_title }}</span>
                    </div>
                    <div class="detail-field">
                      <span class="detail-field-label">Contract Type</span>
                      <span class="detail-field-value capitalize">{{ selectedEmployee.employment_type }} Full-Time</span>
                    </div>
                    <div class="detail-field">
                      <span class="detail-field-label">Work Schedule</span>
                      <span class="detail-field-value">40 hrs / week (5 days)</span>
                    </div>
                    <div class="detail-field">
                      <span class="detail-field-label">Hire Date</span>
                      <span class="detail-field-value">{{ formatDate(selectedEmployee.hire_date) }}</span>
                    </div>
                    <div class="detail-field">
                      <span class="detail-field-label">Probation Confirmation</span>
                      <span class="detail-field-value text-emerald-700 font-medium">Confirmed ({{ formatDate(selectedEmployee.confirmation_date) }})</span>
                    </div>
                  </div>
                </div>

                <!-- Compensation Glance Card -->
                <div class="content-section-card">
                  <div class="section-card-header">
                    <div class="flex items-center gap-2">
                      <Landmark :size="14" class="text-primary" />
                      <h3 class="section-card-title">Compensation & Bank Accounts</h3>
                    </div>
                    <button class="card-header-link" @click="activeTab = 'compensation'">Full Package &rarr;</button>
                  </div>
                  <div class="fields-compact-grid">
                    <div class="detail-field">
                      <span class="detail-field-label">Monthly Base Salary</span>
                      <span class="detail-field-value font-semibold text-emerald-700">ETB {{ (selectedEmployee.basic_amount || 72000).toLocaleString() }}</span>
                    </div>
                    <div class="detail-field">
                      <span class="detail-field-label">Monthly Allowances</span>
                      <span class="detail-field-value">ETB {{ ((selectedEmployee.transport_allowance ?? 4240) + (selectedEmployee.housing_allowance ?? 11000) + (selectedEmployee.other_allowance ?? 1500)).toLocaleString() }}</span>
                    </div>
                    <div class="detail-field span-full">
                      <span class="detail-field-label">Primary Bank Disbursement</span>
                      <div class="flex items-center justify-between mt-1 p-2 bg-slate-50 border border-slate-200 rounded-md text-xs">
                        <span class="font-medium text-slate-700">Commercial Bank of Ethiopia (CBE)</span>
                        <span class="font-mono text-slate-600">•••• •••• •••• 0871 (80% Split)</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Column 2: Personal, Compliance & Family Glance -->
              <div class="overview-column">
                <!-- Personal Glance Card -->
                <div class="content-section-card">
                  <div class="section-card-header">
                    <div class="flex items-center gap-2">
                      <User :size="14" class="text-primary" />
                      <h3 class="section-card-title">Identity & Demographics</h3>
                    </div>
                    <button class="card-header-link" @click="activeTab = 'personal'">Full Profile &rarr;</button>
                  </div>
                  <div class="fields-compact-grid">
                    <div class="detail-field">
                      <span class="detail-field-label">Legal Name</span>
                      <span class="detail-field-value font-semibold">{{ selectedEmployee.employee_name }}</span>
                    </div>
                    <div class="detail-field">
                      <span class="detail-field-label">Gender & Age</span>
                      <span class="detail-field-value">{{ selectedEmployee.gender }} &bull; {{ calculateAge(selectedEmployee.birth_date) }} years</span>
                    </div>
                    <div class="detail-field">
                      <span class="detail-field-label">Fayda National ID</span>
                      <span class="detail-field-value font-mono text-xs font-semibold text-emerald-700">{{ selectedEmployee.fayda_id || 'FYD-90114522208' }} &check;</span>
                    </div>
                    <div class="detail-field">
                      <span class="detail-field-label">Marital Status</span>
                      <span class="detail-field-value">{{ selectedEmployee.marital_status || 'Married' }}</span>
                    </div>
                    <div class="detail-field span-full">
                      <span class="detail-field-label">Residence Address</span>
                      <span class="detail-field-value text-xs">{{ selectedEmployee.residence_line || 'Main Commercial Boulevard' }}, {{ selectedEmployee.residence_subcity || 'Bole' }}, {{ selectedEmployee.residence_region || 'Addis Ababa' }}</span>
                    </div>
                  </div>
                </div>

                <!-- Compliance & Family Glance Card -->
                <div class="content-section-card">
                  <div class="section-card-header">
                    <div class="flex items-center gap-2">
                      <ShieldCheck :size="14" class="text-primary" />
                      <h3 class="section-card-title">Compliance & Statutory</h3>
                    </div>
                    <button class="card-header-link" @click="activeTab = 'compliance'">View All &rarr;</button>
                  </div>
                  <div class="fields-compact-grid">
                    <div class="detail-field">
                      <span class="detail-field-label">TIN Number</span>
                      <span class="detail-field-value font-mono text-xs">{{ selectedEmployee.tin || '0051177245' }}</span>
                    </div>
                    <div class="detail-field">
                      <span class="detail-field-label">POESSA Pension No.</span>
                      <span class="detail-field-value font-mono text-xs">{{ selectedEmployee.pension_number || 'PN-204415' }}</span>
                    </div>
                    <div class="detail-field">
                      <span class="detail-field-label">Guarantor Bond</span>
                      <span class="detail-field-value font-medium text-xs">Daniel Kebede (ETB 150,000 Bond)</span>
                    </div>
                    <div class="detail-field">
                      <span class="detail-field-label">Emergency Next of Kin</span>
                      <span class="detail-field-value font-medium text-xs">Hiwot Tadesse (Spouse &bull; +251 91 298 3341)</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- TAB 2: PERSONAL (ALL CREATION TAB 1 FIELDS) -->
          <div v-else-if="activeTab === 'personal'" class="domain-tab-view">
            <!-- Section 1: Names, Contact & Core Demographics -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Basic Information</h3>
                <span class="section-badge">Basic Information</span>
              </div>
              <div class="fields-compact-grid">
                <div class="detail-field">
                  <span class="detail-field-label">First Name</span>
                  <span class="detail-field-value font-medium">{{ selectedEmployee.first_name || 'Abebe' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Middle Name (Father)</span>
                  <span class="detail-field-value font-medium">{{ selectedEmployee.middle_name || 'Kebede' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Last Name (Grandfather)</span>
                  <span class="detail-field-value font-medium">{{ selectedEmployee.last_name || 'Mola' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Gender</span>
                  <span class="detail-field-value">{{ selectedEmployee.gender || 'Male' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Date of Birth</span>
                  <span class="detail-field-value">{{ formatDate(selectedEmployee.birth_date) }} ({{ calculateAge(selectedEmployee.birth_date) }} years)</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Mobile Phone</span>
                  <span class="detail-field-value font-mono text-xs font-semibold">{{ selectedEmployee.phone || '+251 911 123 456' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Personal Email</span>
                  <span class="detail-field-value text-slate-600 text-xs">{{ selectedEmployee.personal_email || 'abebe.kebede.m@gmail.com' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Work Email</span>
                  <span class="detail-field-value text-primary text-xs">{{ selectedEmployee.work_email || 'abebe.kebede@haleta.com' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Marital Status</span>
                  <span class="detail-field-value">{{ selectedEmployee.marital_status || 'Married' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Blood Group</span>
                  <span class="detail-field-value font-mono font-medium">{{ selectedEmployee.blood_group || 'O+' }}</span>
                </div>
              </div>
            </div>

            <!-- Section 2: Demographics & National ID -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Demographics & Citizenship</h3>
                <span class="section-badge">Civil Identity</span>
              </div>
              <div class="fields-compact-grid">
                <div class="detail-field">
                  <span class="detail-field-label">National ID (Fayda NIDP)</span>
                  <div class="flex items-center gap-2 mt-0.5">
                    <span class="detail-field-value font-mono text-xs font-semibold text-slate-800">{{ selectedEmployee.fayda_id || 'FYD-90114522208' }}</span>
                    <span class="verified-tag"><Check :size="11" /> Verified NIDP</span>
                  </div>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Place of Birth</span>
                  <span class="detail-field-value">{{ selectedEmployee.birth_place || 'Hawassa' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Nationality Country</span>
                  <span class="detail-field-value">{{ selectedEmployee.nationality_country || 'Ethiopian' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Nationality Type</span>
                  <span class="detail-field-value">{{ selectedEmployee.nationality_type || 'Citizen' }}</span>
                </div>
              </div>
            </div>

            <!-- Section 3: Residential Address -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Residential Address</h3>
                <span class="section-badge">Physical Domicile</span>
              </div>
              <div class="fields-compact-grid">
                <div class="detail-field">
                  <span class="detail-field-label">Address Type</span>
                  <span class="detail-field-value">{{ selectedEmployee.address_type || 'Residence / Primary Home' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Country</span>
                  <span class="detail-field-value">{{ selectedEmployee.address_country || 'Ethiopia' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Region / City Administration</span>
                  <span class="detail-field-value">{{ selectedEmployee.residence_region || 'Addis Ababa' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Sub-City / Zone</span>
                  <span class="detail-field-value">{{ selectedEmployee.residence_subcity || 'Bole Sub-City' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Woreda</span>
                  <span class="detail-field-value">{{ selectedEmployee.residence_woreda || 'Woreda 03' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Kebele</span>
                  <span class="detail-field-value">{{ selectedEmployee.residence_kebele || 'Kebele 08' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">House Number</span>
                  <span class="detail-field-value font-mono">{{ selectedEmployee.residence_house_number || 'H-102' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Postal Code / P.O. Box</span>
                  <span class="detail-field-value font-mono">{{ selectedEmployee.residence_postal_code || '1176' }}</span>
                </div>
                <div class="detail-field span-full">
                  <span class="detail-field-label">Street / Locality Line</span>
                  <span class="detail-field-value">{{ selectedEmployee.residence_line || 'Cameroon St., Near Edna Mall' }}</span>
                </div>
                <div class="detail-field span-full">
                  <span class="detail-field-label">Effective Domicile Period</span>
                  <span class="detail-field-value font-mono text-xs">{{ selectedEmployee.address_effective_from || '2022-01-10' }} &rarr; {{ selectedEmployee.address_effective_to || 'Current (Active Domicile)' }}</span>
                </div>
              </div>
            </div>

            <!-- Section 4: Biography Notes -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Biography & HR Remarks</h3>
                <span class="section-badge">Remarks</span>
              </div>
              <p class="text-xs leading-relaxed text-slate-700 bg-slate-50 p-3 rounded-md border border-slate-200">
                {{ selectedEmployee.notes || 'No intake remarks recorded.' }}
              </p>
            </div>

            <!-- Section 5: Disability & Accommodations -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Disability & Accommodations</h3>
                <span class="section-badge badge-confidential"><Shield :size="11" /> Confidential HR Record</span>
              </div>
              <div v-for="d in disabilities" :key="d.id" class="p-3 bg-slate-50 border border-slate-200 rounded-md">
                <div class="flex items-center justify-between mb-1.5">
                  <span class="font-semibold text-slate-800 text-xs capitalize">{{ d.disability_type }} Support Required</span>
                  <span class="tax-tag tax-exempt capitalize">{{ d.severity }} Priority</span>
                </div>
                <p class="text-xs text-slate-700 mb-2">{{ d.accommodation_notes }}</p>
                <div class="flex items-center justify-between text-xs text-slate-500 pt-1.5 border-t border-slate-200">
                  <span class="font-mono">Ref: {{ d.certificate_reference }}</span>
                  <span class="verified-tag"><Check :size="11" /> Verified by {{ d.verified_by }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- TAB 3: EMPLOYMENT (ALL CREATION TAB 2 FIELDS) -->
          <div v-else-if="activeTab === 'employment'" class="domain-tab-view">
            <!-- Section 1: Org Placement -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Organization Placement</h3>
                <span class="section-badge">Structure Tree</span>
              </div>
              <div class="fields-compact-grid">
                <div class="detail-field">
                  <span class="detail-field-label">Operating Legal Entity</span>
                  <span class="detail-field-value font-medium">{{ selectedEmployee.entity_name }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Business Division</span>
                  <span class="detail-field-value">Commercial Operations</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Department</span>
                  <span class="detail-field-value font-medium">{{ selectedEmployee.department_name }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Job Position Title</span>
                  <span class="detail-field-value font-semibold text-primary">{{ selectedEmployee.job_title }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Direct Manager / Reports To</span>
                  <span class="detail-field-value">{{ selectedEmployee.reports_to || 'Fitsum Assefa (Director)' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Duty Station / Work Location</span>
                  <span class="detail-field-value">Addis Ababa Head Office</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Cost Center Code</span>
                  <span class="detail-field-value font-mono">CC-FIN-104</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Work Arrangement</span>
                  <span class="detail-field-value">On-Site (Full Office)</span>
                </div>
              </div>
            </div>

            <!-- Section 2: Contract Terms & Schedule -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Employment Contract</h3>
                <span class="section-badge">Active Terms</span>
              </div>
              <div v-for="ctr in contracts" :key="ctr.id">
                <div class="fields-compact-grid">
                  <div class="detail-field">
                    <span class="detail-field-label">Contract Reference Code</span>
                    <span class="detail-field-value font-mono font-medium text-primary">{{ ctr.code }}</span>
                  </div>
                  <div class="detail-field">
                    <span class="detail-field-label">Contract Type</span>
                    <span class="detail-field-value capitalize">{{ ctr.contract_type_lookup_value_id }} Agreement</span>
                  </div>
                  <div class="detail-field">
                    <span class="detail-field-label">Start Date</span>
                    <span class="detail-field-value">{{ formatDate(ctr.start_date) }}</span>
                  </div>
                  <div class="detail-field">
                    <span class="detail-field-label">Contract End Date</span>
                    <span class="detail-field-value">{{ ctr.end_date ? formatDate(ctr.end_date) : 'Indefinite' }}</span>
                  </div>
                  <div class="detail-field">
                    <span class="detail-field-label">Shift Pattern</span>
                    <span class="detail-field-value">{{ ctr.shift_pattern || 'Standard 5-Day Daytime Shift' }}</span>
                  </div>
                  <div class="detail-field">
                    <span class="detail-field-label">Weekly Working Hours</span>
                    <span class="detail-field-value font-medium">{{ ctr.weekly_hours }} Hours / Week</span>
                  </div>
                  <div class="detail-field">
                    <span class="detail-field-label">Probation Period</span>
                    <span class="detail-field-value">{{ ctr.probation_months }} Months (Confirmed)</span>
                  </div>
                  <div class="detail-field">
                    <span class="detail-field-label">Notice Period</span>
                    <span class="detail-field-value">{{ ctr.notice_period_days }} Days</span>
                  </div>
                  <div class="detail-field span-full">
                    <span class="detail-field-label">Terms Description</span>
                    <span class="detail-field-value text-xs text-slate-600">{{ ctr.terms }}</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Section 3: Status History -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Status History</h3>
                <span class="section-badge">Chronological Log</span>
              </div>
              <table class="nested-mini-table">
                <thead>
                  <tr>
                    <th>Status</th>
                    <th>Effective Date</th>
                    <th>Reason / Justification</th>
                    <th>Movement Source</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="sh in statusHistory" :key="sh.id">
                    <td>
                      <span :class="['status-pill', getStatusPillClass(sh.status_lookup_value_id)]">
                        {{ formatStatus(sh.status_lookup_value_id) }}
                      </span>
                    </td>
                    <td class="font-mono text-xs">{{ formatDate(sh.effective_date) }}</td>
                    <td class="text-xs">{{ sh.reason }}</td>
                    <td class="font-mono text-xs text-slate-500">{{ sh.source_type }} #{{ sh.source_id }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- TAB 4: COMPENSATION (ALL CREATION TAB 3 FIELDS) -->
          <div v-else-if="activeTab === 'compensation'" class="domain-tab-view">
            <!-- Section 1: Remuneration Package -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Base Salary & Remuneration</h3>
                <span class="section-badge">Approved Compensation</span>
              </div>
              <div class="fields-compact-grid">
                <div class="detail-field">
                  <span class="detail-field-label">Monthly Base Salary</span>
                  <span class="detail-field-value text-base font-bold text-emerald-700">ETB {{ (selectedEmployee.basic_amount || 72000).toLocaleString() }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Total Gross Package</span>
                  <span class="detail-field-value text-base font-bold text-primary">ETB {{ ((selectedEmployee.basic_amount || 72000) + (selectedEmployee.transport_allowance ?? 4240) + (selectedEmployee.housing_allowance ?? 11000) + (selectedEmployee.other_allowance ?? 1500)).toLocaleString() }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Job Grade & Step</span>
                  <span class="detail-field-value font-medium">{{ selectedEmployee.job_grade || 'Grade B2' }} ({{ selectedEmployee.job_grade_step || 'Step 2' }})</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Package Authorized By</span>
                  <span class="detail-field-value">{{ selectedEmployee.package_authorized_by || 'Board Resolution BR-2024-001' }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Effective Date</span>
                  <span class="detail-field-value">{{ formatDate(selectedEmployee.salary_effective_date || '2024-01-15') }}</span>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">Payroll Group</span>
                  <span class="detail-field-value">{{ selectedEmployee.payroll_group || 'Monthly Regular Payroll Group' }}</span>
                </div>
              </div>
            </div>

            <!-- Section 2: Allowances Breakdown -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Allowances & Benefits</h3>
                <span class="section-badge">Pay Components</span>
              </div>
              <table class="nested-mini-table">
                <thead>
                  <tr>
                    <th>Component Name</th>
                    <th>Classification</th>
                    <th>Monthly Amount</th>
                    <th>Tax Exemption Rule</th>
                    <th>Frequency</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="font-medium text-slate-800">Transport Allowance</td>
                    <td>Operational Mobility</td>
                    <td class="font-semibold text-slate-800 font-mono">ETB {{ (selectedEmployee.transport_allowance ?? 4240).toLocaleString() }}</td>
                    <td><span class="tax-tag tax-exempt">Non-Taxable Limit</span></td>
                    <td>Monthly Recurring</td>
                  </tr>
                  <tr>
                    <td class="font-medium text-slate-800">Housing Allowance</td>
                    <td>Living Assistance</td>
                    <td class="font-semibold text-slate-800 font-mono">ETB {{ (selectedEmployee.housing_allowance ?? 11000).toLocaleString() }}</td>
                    <td><span class="tax-tag tax-taxable">Standard Progressive Tax</span></td>
                    <td>Monthly Recurring</td>
                  </tr>
                  <tr>
                    <td class="font-medium text-slate-800">Communication / Mobile Allowance</td>
                    <td>Operational Duty</td>
                    <td class="font-semibold text-slate-800 font-mono">ETB {{ (selectedEmployee.other_allowance ?? 1500).toLocaleString() }}</td>
                    <td><span class="tax-tag tax-exempt">Non-Taxable Limit</span></td>
                    <td>Monthly Recurring</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Section 3: Salary Disbursement Accounts (Masked Bank UX) -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Salary Disbursement Accounts</h3>
                <span class="section-badge">Direct Deposit</span>
              </div>
              <div class="bank-accounts-grid">
                <div v-for="b in bankAccounts" :key="b.id" class="bank-account-card">
                  <div class="bank-card-top">
                    <div class="bank-logo-wrap">
                      <Landmark :size="16" class="text-primary" />
                      <div>
                        <div class="bank-name-text">{{ b.bank_name }}</div>
                        <div class="branch-name-text">{{ b.branch_name }}</div>
                      </div>
                    </div>
                    <span v-if="b.is_primary" class="primary-badge">Primary ({{ b.split_percent }}%)</span>
                    <span v-else class="secondary-badge">Split ({{ b.split_percent }}%)</span>
                  </div>

                  <div class="account-num-row">
                    <span class="acc-label">Account Number:</span>
                    <div class="acc-val-group">
                      <span class="acc-val-masked font-mono font-semibold">{{ getMaskedAccountNumber(b.account_number, b.id) }}</span>
                      <button 
                        type="button" 
                        class="btn-toggle-mask" 
                        :title="showBankNumbers[b.id] ? 'Hide Account Number' : 'Reveal Account Number'"
                        @click="toggleBankMask(b.id)"
                      >
                        <EyeOff v-if="showBankNumbers[b.id]" :size="13" />
                        <Eye v-else :size="13" />
                      </button>
                      <button 
                        type="button" 
                        class="btn-copy-acc" 
                        title="Copy Account Number"
                        @click="copyText(b.account_number)"
                      >
                        <Copy :size="13" />
                      </button>
                    </div>
                  </div>

                  <div class="bank-card-footer">
                    <div class="holder-name font-medium">Holder: {{ b.account_holder_name }}</div>
                    <span class="verified-tag"><Check :size="11" /> Verified</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- TAB 5: QUALIFICATIONS (ALL CREATION TAB 4 FIELDS) -->
          <div v-else-if="activeTab === 'qualifications'" class="domain-tab-view">
            <!-- Academic Qualifications -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Academic Qualifications</h3>
                <span class="section-badge">Higher Education</span>
              </div>
              <table class="nested-mini-table">
                <thead>
                  <tr>
                    <th>Degree / Award</th>
                    <th>Institution</th>
                    <th>Field of Study</th>
                    <th>Country</th>
                    <th>Graduation Date</th>
                    <th>GPA</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="q in qualifications" :key="q.id">
                    <td class="font-semibold text-slate-800">{{ q.level }}</td>
                    <td>{{ q.institution }}</td>
                    <td>{{ q.field_of_study }}</td>
                    <td>{{ q.country || 'Ethiopia' }}</td>
                    <td class="font-mono text-xs">{{ formatDate(q.graduation_date) }}</td>
                    <td class="font-mono font-semibold">{{ q.gpa.toFixed(2) }}</td>
                    <td><span class="verified-tag"><Check :size="11" /> Certified</span></td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Professional Certifications -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Professional Certifications</h3>
                <span class="section-badge">Accreditations</span>
              </div>
              <table class="nested-mini-table">
                <thead>
                  <tr>
                    <th>Certification Name</th>
                    <th>Issuing Body</th>
                    <th>License / Certificate No</th>
                    <th>Issued Date</th>
                    <th>License Status</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="c in certifications" :key="c.id">
                    <td class="font-semibold text-slate-800">{{ c.name }}</td>
                    <td>{{ c.institution }}</td>
                    <td class="font-mono text-xs">{{ c.certificate_number }}</td>
                    <td class="font-mono text-xs">{{ formatDate(c.issued_date) }}</td>
                    <td><span class="verified-tag"><Check :size="11" /> Active License</span></td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Prior Work Experience -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Work Experience</h3>
                <span class="section-badge">Employment Record</span>
              </div>
              <table class="nested-mini-table">
                <thead>
                  <tr>
                    <th>Previous Employer</th>
                    <th>Position Title</th>
                    <th>Period of Service</th>
                    <th>Reason for Leaving</th>
                    <th>Reference Person & Contact</th>
                    <th>Verification</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="e in experiences" :key="e.id">
                    <td class="font-semibold text-slate-800">{{ e.employer_name }}</td>
                    <td>{{ e.position_title }}</td>
                    <td class="font-mono text-xs">{{ formatDate(e.start_date) }} &rarr; {{ formatDate(e.end_date) }}</td>
                    <td class="text-xs text-slate-600">{{ e.reason_for_leaving || '—' }}</td>
                    <td class="text-xs text-slate-700">
                      <div class="font-medium">{{ e.reference_person || '—' }}</div>
                      <div v-if="e.reference_phone" class="font-mono text-[11px] text-slate-500">{{ e.reference_phone }}</div>
                    </td>
                    <td><span class="verified-tag"><Check :size="11" /> Verified</span></td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Skills & Language Competencies -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Skills & Language Competencies</h3>
                <span class="section-badge">Capabilities</span>
              </div>
              <div class="mb-3">
                <div class="detail-field-label mb-1.5">Technical & Functional Competencies</div>
                <div class="flex flex-wrap gap-1.5">
                  <span v-for="s in skillsList" :key="s" class="hero-tag font-medium">{{ s }}</span>
                </div>
              </div>
              <div class="mt-3 pt-3 border-t border-slate-100">
                <div class="detail-field-label mb-1.5">Spoken & Written Languages</div>
                <table class="nested-mini-table">
                  <thead>
                    <tr>
                      <th>Language</th>
                      <th>Overall Proficiency</th>
                      <th>Speaking</th>
                      <th>Writing</th>
                      <th>Reading</th>
                      <th>Listening</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="l in languagesList" :key="l.name">
                      <td class="font-semibold text-slate-800">{{ l.name }}</td>
                      <td><span class="tax-tag tax-exempt">{{ l.level }}</span></td>
                      <td>{{ l.speaking }}</td>
                      <td>{{ l.writing }}</td>
                      <td>{{ l.reading }}</td>
                      <td>{{ l.listening }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <!-- TAB 6: COMPLIANCE (ALL CREATION TAB 5 FIELDS) -->
          <div v-else-if="activeTab === 'compliance'" class="domain-tab-view">
            <!-- Statutory Registration -->
            <div class="content-section-card">
              <div class="section-card-header">
                <div class="flex items-center gap-2">
                  <h3 class="section-card-title">Statutory Registration</h3>
                  <span class="section-badge">Tax & Pension</span>
                </div>
              </div>
              <div class="fields-compact-grid">
                <div class="detail-field">
                  <span class="detail-field-label">Taxpayer Identification Number (TIN)</span>
                  <div class="flex items-center gap-2 mt-0.5">
                    <span class="detail-field-value font-mono font-semibold">{{ selectedEmployee.tin || '0051177245' }}</span>
                    <button class="btn-copy-acc" title="Copy TIN" @click="copyText(selectedEmployee.tin)"><Copy :size="12" /></button>
                    <span class="verified-tag"><Check :size="11" /> Active</span>
                  </div>
                </div>
                <div class="detail-field">
                  <span class="detail-field-label">POESSA Permanent Pension Number</span>
                  <div class="flex items-center gap-2 mt-0.5">
                    <span class="detail-field-value font-mono font-semibold">{{ selectedEmployee.pension_number || 'PN-204415' }}</span>
                    <button class="btn-copy-acc" title="Copy Pension No." @click="copyText(selectedEmployee.pension_number)"><Copy :size="12" /></button>
                    <span class="verified-tag"><Check :size="11" /> Registered</span>
                  </div>
                </div>
              </div>

              <!-- Statutory Contribution & Exemption Regimes (Nested Mini Table) -->
              <div class="mt-4 pt-3 border-t border-slate-100">
                <div class="flex items-center justify-between mb-2">
                  <span class="text-xs font-semibold text-neutral-700">Tax & Pension Statutory Regimes</span>
                  <span class="text-xs text-neutral-500">Statutory Payroll Deductions</span>
                </div>
                <table class="nested-mini-table">
                  <thead>
                    <tr>
                      <th>Rule / Exemption Regime</th>
                      <th>Legal Framework</th>
                      <th>Effective Period</th>
                      <th>Statutory Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="st in statutoryExemptions" :key="st.id">
                      <td class="font-medium text-slate-800">{{ st.rule_type }}</td>
                      <td class="text-xs text-slate-600">{{ st.category }}</td>
                      <td class="font-mono text-xs">{{ formatDate(st.effective_from) }} &ndash; {{ st.effective_to ? formatDate(st.effective_to) : 'Indefinite' }}</td>
                      <td><span class="verified-tag"><Check :size="11" /> {{ st.status }}</span></td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- Regulatory Clearances -->
            <div class="content-section-card">
              <div class="section-card-header">
                <div class="flex items-center gap-2">
                  <h3 class="section-card-title">Regulatory Clearances</h3>
                  <span class="section-badge">Government Certs</span>
                </div>
              </div>
              <table class="nested-mini-table">
                <thead>
                  <tr>
                    <th>Clearance Type</th>
                    <th>Reference No.</th>
                    <th>Issued Date</th>
                    <th>Expiry Date</th>
                    <th>Verified Authority</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="cmp in complianceItems" :key="cmp.id">
                    <td class="font-semibold capitalize text-slate-800">{{ cmp.item_type_lookup_value_id.replace('_', ' ') }}</td>
                    <td class="font-mono text-xs">{{ cmp.reference_number }}</td>
                    <td class="font-mono text-xs">{{ formatDate(cmp.issued_date) }}</td>
                    <td class="font-mono text-xs">{{ cmp.expiry_date ? formatDate(cmp.expiry_date) : 'Indefinite' }}</td>
                    <td>{{ cmp.verified_by_name || 'Selamawit Bekele' }}</td>
                    <td><span class="verified-tag"><Check :size="11" /> Valid</span></td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Employee Guarantor (EmployeeGuarantee - HR_Schema_final-v4.sql Line 839) -->
            <div class="content-section-card">
              <div class="section-card-header">
                <div class="flex items-center gap-2">
                  <h3 class="section-card-title">Employee Guarantor</h3>
                  <span class="section-badge">Surety & Indemnity</span>
                </div>
                <span class="text-xs text-slate-500">Legal Surety Guarantee</span>
              </div>

              <div v-for="g in guarantees" :key="g.id" class="guarantor-profile-card">
                <div class="guarantor-header-row">
                  <div class="guarantor-title-group">
                    <div class="guarantor-shield-icon">
                      <ShieldCheck :size="18" class="text-primary" />
                    </div>
                    <div>
                      <div class="flex items-center gap-2">
                        <span class="guarantor-name">{{ g.guarantor_name }}</span>
                        <span class="status-pill status-active">Active Surety</span>
                        <span class="guarantor-relation-tag capitalize">{{ g.relation_lookup_value_id }}</span>
                      </div>
                      <div class="guarantor-meta-subline">
                        <span class="font-mono text-xs text-neutral-500">{{ g.code }}</span>
                        <span class="dot-sep">&bull;</span>
                        <span class="text-xs text-neutral-500">FK Party #{{ g.guarantor_party_id }}</span>
                      </div>
                    </div>
                  </div>

                  <div class="guarantor-bond-badge">
                    <span class="bond-label">Surety Bond Amount</span>
                    <span class="bond-amount font-mono">ETB {{ g.guaranteed_amount.toLocaleString() }}</span>
                  </div>
                </div>

                <div class="fields-compact-grid mt-3 pt-3 border-t border-slate-100">
                  <div class="detail-field">
                    <span class="detail-field-label">Guarantor National ID / Fayda</span>
                    <span class="detail-field-value font-mono text-xs font-semibold text-slate-800">{{ g.guarantor_id_number || 'FYD-8820194412' }}</span>
                  </div>
                  <div class="detail-field">
                    <span class="detail-field-label">Guarantor Contact Phone</span>
                    <span class="detail-field-value font-mono text-xs font-semibold text-slate-800">{{ g.guarantor_phone }}</span>
                  </div>
                  <div class="detail-field">
                    <span class="detail-field-label">Employer Organization</span>
                    <span class="detail-field-value font-medium text-xs">{{ g.guarantor_employer_name }}</span>
                  </div>
                  <div class="detail-field">
                    <span class="detail-field-label">Guarantor Monthly Income</span>
                    <span class="detail-field-value font-mono text-xs">ETB {{ g.guarantor_monthly_income?.toLocaleString() }} (Verified Capacity)</span>
                  </div>
                  <div class="detail-field">
                    <span class="detail-field-label">Surety Purpose</span>
                    <span class="detail-field-value capitalize text-xs">{{ g.purpose_lookup_value_id.replace('_', ' ') }} (Cash Handling & Asset Custody)</span>
                  </div>
                  <div class="detail-field">
                    <span class="detail-field-label">Notarized Letter Reference</span>
                    <div class="flex items-center gap-2 mt-0.5">
                      <span class="detail-field-value font-mono text-xs">{{ g.letter_number }} ({{ formatDate(g.letter_date) }})</span>
                      <span class="guarantor-doc-tag">
                        <FileText :size="11" />
                        <span>Signed Bond PDF</span>
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- TAB 7: FAMILY (ALL CREATION TAB 6 FIELDS) -->
          <div v-else-if="activeTab === 'family'" class="domain-tab-view">
            <!-- Emergency Contacts -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Emergency Contacts</h3>
                <span class="section-badge">Emergency Call Order</span>
              </div>
              <table class="nested-mini-table">
                <thead>
                  <tr>
                    <th>Contact Name</th>
                    <th>Relationship</th>
                    <th>Phone Number</th>
                    <th>Residential Locality</th>
                    <th>Call Priority</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="ec in emergencyContacts" :key="ec.id">
                    <td class="font-semibold text-slate-800">{{ ec.contact_name }}</td>
                    <td class="capitalize">{{ ec.relation }}</td>
                    <td class="font-mono text-xs font-semibold text-slate-800">{{ ec.phone }}</td>
                    <td>{{ ec.sub_city }}, {{ ec.city }}</td>
                    <td><span class="priority-badge">Priority {{ ec.priority }}</span></td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Dependents -->
            <div class="content-section-card">
              <div class="section-card-header">
                <h3 class="section-card-title">Dependents</h3>
                <span class="section-badge">Welfare & Insurance</span>
              </div>
              <table class="nested-mini-table">
                <thead>
                  <tr>
                    <th>Dependent Name</th>
                    <th>Relationship</th>
                    <th>Date of Birth</th>
                    <th>Benefit Eligibility</th>
                    <th>Coverage Notes</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="dep in dependents" :key="dep.id">
                    <td class="font-semibold text-slate-800">{{ dep.dependent_name }}</td>
                    <td class="capitalize">{{ dep.relation }}</td>
                    <td class="font-mono text-xs">{{ formatDate(dep.birth_date) }}</td>
                    <td>
                      <span v-if="dep.is_beneficiary" class="verified-tag"><Check :size="11" /> Benefit Eligible</span>
                      <span v-else class="text-xs text-slate-400">Non-Eligible</span>
                    </td>
                    <td class="text-xs text-slate-600">{{ dep.benefit_notes || '—' }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

        </div>
      </div>
    </div>

    <!-- QUICK CREATE MODAL -->
    <QuickCreateModal
      v-model:show="showQuickCreate"
      title="Create Employee"
      :expandRoute="computedExpandRoute"
      expandLabel="Expand Full Form"
      :showExpandButton="true"
      saveLabel="Save Employee"
      @save="handleSaveQuickEmployee"
    >
      <div class="quick-create-grid">
        <FormInput 
          label="Full Legal Name" 
          v-model="quickForm.employee_name" 
          required 
        />
        <FormInput 
          label="Job Position Title" 
          v-model="quickForm.job_title" 
          required 
        />
        <FormSelect 
          label="Department" 
          v-model="quickForm.department_name" 
          :options="['Finance & Accounts', 'Human Resources', 'Supply Chain & Logistics', 'Executive & Finance', 'Operations']" 
          required 
        />
        <FormInput 
          label="Official Hire Date" 
          type="date" 
          v-model="quickForm.hire_date" 
          required 
        />
        <FormSelect 
          label="Employment Type" 
          v-model="quickForm.employment_type" 
          :options="[
            { label: 'Permanent / Indefinite', value: 'permanent' },
            { label: 'Fixed-Term Contract', value: 'contract' },
            { label: 'Temporary / Daily Labor', value: 'temporary' },
            { label: 'Part-Time Hire', value: 'part_time' },
            { label: 'Student Intern', value: 'intern' },
            { label: 'Professional Consultant', value: 'consultant' }
          ]" 
          required 
        />
        <FormInput 
          label="Mobile Phone Number" 
          v-model="quickForm.phone" 
          required 
        />
        <FormInput 
          label="Work Email" 
          type="email" 
          v-model="quickForm.work_email" 
        />
      </div>
    </QuickCreateModal>

    <!-- Floating Bulk Action Bar for Normal Directory Table -->
    <TableFloatingBar 
      :show="selectedRowIds.length > 0 && viewMode === 'list'"
      :selected-count="selectedRowIds.length"
      :total-count="filteredEmployees.length"
      @select-all="handleFloatingSelectAllEmployees"
      @duplicate="handleFloatingDuplicateEmployees"
      @edit="handleFloatingEditEmployee"
      @delete="handleFloatingDeleteEmployees"
      @change-status="handleFloatingChangeStatusEmployees"
      @export="handleFloatingExportEmployees"
      @deactivate="handleFloatingDeactivateEmployees"
      @close="selectedRowIds = []"
    />
  </div>
</template>

<style scoped>
.employee-master-page {
  padding: 16px 24px;
  background-color: var(--primitive-color-neutral-50, #f8fafc);
  min-height: calc(100vh - 60px);
}

.page-breadcrumb-bar {
  margin-bottom: 12px;
}

.directory-view-wrapper {
  animation: fadeIn 0.15s ease;
}

/* Quick Action Toast */
.quick-toast-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #ecfdf5;
  border: 1px solid #a7f3d0;
  color: #065f46;
  padding: 7px 12px;
  border-radius: 6px;
  font-size: 12.5px;
  margin-bottom: 12px;
}

/* Custom Checkbox (Standard Squircle Design) */
.custom-checkbox {
  appearance: none;
  -webkit-appearance: none;
  width: 16px;
  height: 16px;
  min-width: 16px;
  min-height: 16px;
  border-radius: 4px;
  border: 1.5px solid #d1d5db;
  background-color: #ffffff;
  cursor: pointer;
  display: inline-grid;
  place-content: center;
  position: relative;
  vertical-align: middle;
  outline: none;
  margin: 0;
  padding: 0;
  transition: all 0.15s ease;
  flex-shrink: 0;
}
.custom-checkbox:hover:not(:checked):not(:disabled) {
  border-color: #9ca3af;
  background-color: #f9fafb;
}
.custom-checkbox:checked {
  background-color: #0B529C;
  border-color: #0B529C;
  background-image: url("data:image/svg+xml,%3csvg viewBox='0 0 16 16' fill='none' stroke='white' stroke-width='2.6' stroke-linecap='round' stroke-linejoin='round' xmlns='http://www.w3.org/2000/svg'%3e%3cpolyline points='3.5 8.5 6.5 11.5 12.5 5.5'/%3e%3c/svg%3e");
  background-position: center;
  background-repeat: no-repeat;
  background-size: 75% 75%;
}

/* Table Identity Cell */
.employee-identity-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.employee-table-avatar {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  object-fit: cover;
  background-color: #f1f5f9;
  flex-shrink: 0;
}

.employee-meta {
  display: flex;
  flex-direction: column;
}

.employee-name-text {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.employee-sub-text {
  font-size: 11px;
  color: #737373;
}

.table-text-val {
  font-size: 12.5px;
  color: #404040;
}

.table-type-tag {
  display: inline-block;
  padding: 2px 6px;
  border-radius: 4px;
  background: #f1f5f9;
  color: #475569;
  font-size: 11px;
  font-weight: 500;
}

/* Status Pills */
.status-pill {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 7.5px;
  border-radius: 100px;
  font-size: 11px;
  font-weight: 600;
  white-space: nowrap;
}

.status-dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background-color: currentColor;
}

.status-active { background-color: #ecfdf5; color: #059669; }
.status-probation { background-color: #eff6ff; color: #0284c7; }
.status-suspended { background-color: #fef2f2; color: #dc2626; }
.status-leave { background-color: #fefce8; color: #ca8a04; }
.status-separated { background-color: #f1f5f9; color: #64748b; }
.status-draft { background-color: #f8fafc; color: #94a3b8; }

.btn-primary-create {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 14px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-primary-create:hover { background-color: #094482; }

.btn-action-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #64748b;
  cursor: pointer;
}
.btn-action-dots:hover {
  background: #f1f5f9;
  color: #0f172a;
}

.action-cell-wrapper {
  position: relative;
  display: inline-block;
}

.action-dropdown-menu {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  padding: 4px;
  min-width: 150px;
  z-index: 50;
}

.action-menu-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 8px;
  border: none;
  background: transparent;
  font-size: 12px;
  color: #404040;
  border-radius: 4px;
  cursor: pointer;
  text-align: left;
}
.action-menu-item:hover {
  background-color: #f8fafc;
  color: #0B529C;
}

.filter-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 12px;
  padding: 10px 14px;
  background-color: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}

.empty-state-cell {
  padding: 28px 16px;
  text-align: center;
  color: #737373;
}
.empty-icon {
  margin: 0 auto 6px;
  color: #94a3b8;
}

/* ═══════════════════════════════════════════════════════════
   VIEW 2: 360° PROFILE VIEW STYLING (MINIMALIST & SLEEK)
   ═══════════════════════════════════════════════════════════ */
.profile-detail-wrapper {
  animation: fadeIn 0.15s ease;
}

.profile-container {
  display: flex;
  flex-direction: column;
  gap: 14px;
  width: 100%;
}

/* HERO PROFILE HEADER BANNER */
.profile-hero-banner {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
}

.hero-left-section {
  display: flex;
  align-items: center;
  gap: 16px;
}

.hero-avatar-wrapper {
  position: relative;
  width: 72px;
  height: 72px;
  flex-shrink: 0;
}

.hero-avatar-img {
  width: 100%;
  height: 100%;
  border-radius: 16px;
  object-fit: cover;
  background-color: #f1f5f9;
  border: 2px solid #ffffff;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.05);
}

.avatar-status-badge {
  position: absolute;
  bottom: -1px;
  right: -1px;
  width: 13px;
  height: 13px;
  border-radius: 50%;
  background-color: #10b981;
  border: 2px solid #ffffff;
}

.hero-identity-block {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.hero-employee-name {
  font-size: 20px;
  font-weight: 700;
  color: #404040;
  line-height: 1.2;
  margin: 0;
}

.hero-code-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
}

.sep-bullet {
  color: #cbd5e1;
}

.hero-title-text {
  font-weight: 500;
  color: #64748b;
}

.hero-tags-row {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 2px;
  flex-wrap: wrap;
}

.hero-tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 7px;
  border-radius: 5px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  font-size: 11px;
  color: #475569;
  font-weight: 500;
}

.hero-tenure-tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  color: #737373;
}

.tag-icon { color: #64748b; }
.tenure-icon { color: #94a3b8; }

/* Hero Right: Contact Card */
.hero-right-section {
  display: flex;
  align-items: center;
  gap: 20px;
  flex-shrink: 0;
}

.hero-contact-card {
  display: flex;
  flex-direction: column;
  gap: 4px;
  font-size: 12px;
  color: #404040;
}

.hero-contact-item {
  display: flex;
  align-items: center;
  gap: 7px;
}

.contact-icon {
  color: #64748b;
  flex-shrink: 0;
}

.contact-link {
  color: #0B529C;
  text-decoration: none;
}
.contact-link:hover {
  text-decoration: underline;
}

.manager-label { color: #737373; }
.manager-name { font-weight: 600; color: #404040; }

.btn-hero-edit {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 32px;
  padding: 0 12px;
  background-color: #ffffff;
  color: #404040;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-hero-edit:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
  color: #0B529C;
}

/* Tabs Bar */
.profile-tabs-wrapper {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 2px 12px;
}

.tab-content-area {
  width: 100%;
}

/* ── OVERVIEW TAB (COMPACT & SLEEK) ── */
.overview-view {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

/* KPI Metrics Grid (Using Centralized MetricCard Component) */
.profile-kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
}

/* Quick Action Strip */
.quick-action-strip {
  display: flex;
  align-items: center;
  gap: 10px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 8px 14px;
}

.qa-strip-title {
  font-size: 12px;
  font-weight: 600;
  color: #737373;
  white-space: nowrap;
}

.qa-strip-buttons {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.qa-strip-btn {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 4px 10px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
  background-color: #f8fafc;
  color: #404040;
  font-size: 11.5px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}
.qa-strip-btn:hover {
  background-color: #eff6ff;
  border-color: #bfdbfe;
  color: #0B529C;
}

/* Dual Column Overview Grid */
.overview-dual-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  align-items: start;
}

.overview-column {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

/* ── DOMAIN DETAIL CARDS (TABS 2 TO 7) ── */
.domain-tab-view {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.content-section-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 14px 16px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
}

.section-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #f1f5f9;
}

.section-card-title {
  font-size: 12px;
  font-weight: 600;
  color: #404040;
  letter-spacing: 0.03em;
  text-transform: uppercase;
  margin: 0;
}

.section-badge {
  font-size: 10.5px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 4px;
  background-color: #f1f5f9;
  color: #475569;
}
.badge-confidential {
  background-color: #fef2f2;
  color: #991b1b;
  display: inline-flex;
  align-items: center;
  gap: 3px;
}

.card-header-link {
  background: none;
  border: none;
  color: #0B529C;
  font-size: 11.5px;
  font-weight: 600;
  cursor: pointer;
  padding: 0;
}
.card-header-link:hover { text-decoration: underline; }

.fields-compact-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px 18px;
}

.detail-field {
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.span-full {
  grid-column: span 2;
}

.detail-field-label {
  font-size: 11px;
  font-weight: 500;
  color: #737373;
}

.detail-field-value {
  font-size: 12.5px;
  color: #404040;
}

.verified-tag {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  padding: 1.5px 6px;
  border-radius: 4px;
  font-size: 10.5px;
  font-weight: 600;
  background-color: #dcfce7;
  color: #15803d;
}

/* Nested Mini Tables */
.nested-mini-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12.5px;
}

.nested-mini-table th {
  background-color: #f8fafc;
  color: #737373;
  font-size: 11px;
  font-weight: 600;
  text-align: left;
  padding: 7px 10px;
  border-bottom: 1px solid #e2e8f0;
}

.nested-mini-table td {
  padding: 8px 10px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.tax-tag {
  display: inline-block;
  padding: 1.5px 5px;
  border-radius: 3px;
  font-size: 10.5px;
  font-weight: 500;
}
.tax-exempt { background: #eff6ff; color: #0369a1; }
.tax-taxable { background: #fef2f2; color: #b91c1c; }

.priority-badge {
  display: inline-block;
  padding: 1.5px 6px;
  border-radius: 10px;
  font-size: 10.5px;
  font-weight: 600;
  background: #f1f5f9;
  color: #334155;
}

/* Bank Accounts Grid */
.bank-accounts-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.bank-account-card {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px;
  background-color: #ffffff;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.bank-card-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.bank-logo-wrap {
  display: flex;
  align-items: center;
  gap: 7px;
}

.bank-name-text {
  font-size: 12.5px;
  font-weight: 600;
  color: #404040;
}

.branch-name-text {
  font-size: 11px;
  color: #737373;
}

.primary-badge {
  font-size: 10.5px;
  font-weight: 600;
  padding: 1.5px 6px;
  border-radius: 4px;
  background-color: #eff6ff;
  color: #0B529C;
}

.secondary-badge {
  font-size: 10.5px;
  font-weight: 600;
  padding: 1.5px 6px;
  border-radius: 4px;
  background-color: #f1f5f9;
  color: #64748b;
}

.account-num-row {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.acc-label {
  font-size: 11px;
  color: #737373;
}

.acc-val-group {
  display: flex;
  align-items: center;
  gap: 6px;
}

.acc-val-masked {
  font-size: 13px;
  color: #0f172a;
  letter-spacing: 0.02em;
}

.btn-toggle-mask,
.btn-copy-acc {
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 2px;
  border-radius: 3px;
  display: inline-flex;
  align-items: center;
}
.btn-toggle-mask:hover,
.btn-copy-acc:hover {
  color: #0B529C;
  background: #f1f5f9;
}

.bank-card-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-top: 6px;
  border-top: 1px solid #f1f5f9;
  font-size: 11px;
}

/* ─── Guarantor Profile Card ─── */
.guarantor-profile-card {
  background-color: #fafafa;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 14px 16px;
}

.guarantor-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 10px;
}

.guarantor-title-group {
  display: flex;
  align-items: center;
  gap: 10px;
}

.guarantor-shield-icon {
  width: 34px;
  height: 34px;
  border-radius: 8px;
  background-color: #eff6ff;
  display: flex;
  align-items: center;
  justify-content: center;
}

.guarantor-name {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.guarantor-relation-tag {
  font-size: 11px;
  font-weight: 500;
  color: #475569;
  background-color: #f1f5f9;
  padding: 1.5px 7px;
  border-radius: 4px;
}

.guarantor-meta-subline {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 1px;
}

.dot-sep {
  color: #94a3b8;
  font-size: 10px;
}

.guarantor-bond-badge {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  padding: 4px 10px;
}

.bond-label {
  font-size: 10px;
  font-weight: 500;
  color: #737373;
  text-transform: uppercase;
  letter-spacing: 0.02em;
}

.bond-amount {
  font-size: 13px;
  font-weight: 700;
  color: #059669;
}

.guarantor-doc-tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 1.5px 7px;
  border-radius: 4px;
  background-color: #eff6ff;
  color: #0B529C;
  font-size: 11px;
  font-weight: 500;
  text-decoration: none;
}

.quick-create-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

@media (max-width: 1100px) {
  .profile-kpi-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  .overview-dual-grid {
    grid-template-columns: 1fr;
  }
  .profile-hero-banner {
    flex-direction: column;
    align-items: flex-start;
  }
  .hero-right-section {
    width: 100%;
    justify-content: space-between;
  }
}

@media (max-width: 640px) {
  .profile-kpi-grid {
    grid-template-columns: 1fr;
  }
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(2px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
