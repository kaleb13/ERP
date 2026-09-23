<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { 
  Monitor, ChevronRight, ChevronDown, X, Check, Loader2, Image as ImageIcon,
  User, Briefcase, Landmark, GraduationCap, ShieldCheck, Heart,
  Calendar, UploadCloud, Upload, Info, Plus, Trash2, List, ListOrdered,
  Square, Link, Undo2, Redo2, Table, Expand, Copy, ArrowDown, ArrowUp,
  ShieldAlert, MapPin
} from 'lucide-vue-next';
import BaseTabs from '../../components/BaseTabs.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormCombobox, { type ComboboxOption } from '../../components/FormCombobox.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

const router = useRouter();
const route = useRoute();

// ─── Document State ───
const isSaved = ref(false);
const isVerifying = ref(false);
const isIdVerified = ref(false);
const fileInput = ref<HTMLInputElement | null>(null);
const sigFileInput = ref<HTMLInputElement | null>(null);
const guaranteeFileInput = ref<HTMLInputElement | null>(null);
const medicalFileInput = ref<HTMLInputElement | null>(null);

// ─── Active Tab (6 Standard Unified Domains) ───
type TabId = 'personal' | 'job' | 'compensation' | 'credentials' | 'compliance' | 'family';
const activeTab = ref<TabId>('personal');

const tabs = [
  { id: 'personal' as const, label: 'Personal', icon: User },
  { id: 'job' as const, label: 'Employment', icon: Briefcase },
  { id: 'compensation' as const, label: 'Compensation', icon: Landmark },
  { id: 'credentials' as const, label: 'Qualifications', icon: GraduationCap },
  { id: 'compliance' as const, label: 'Compliance', icon: ShieldCheck },
  { id: 'family' as const, label: 'Family', icon: Heart }
];

// ─── Master Form State ───
const form = ref({
  // Avatar & Specimen
  avatar: '',
  signature: '',

  // National ID
  fayda_id: '',

  // Personal Names & Contact
  first_name: '',
  middle_name: '',
  last_name: '',
  phone: '',
  personal_email: '',
  work_email: '',

  // Demographics
  gender: '',
  birth_date: '',
  birth_place: '',
  marital_status: '',
  blood_group: '',
  nationality_country: '',
  nationality_type: '',

  // Residential Address (PartyAddress)
  address_type: 'Residence / Primary Home',
  address_country: 'Ethiopia',
  residence_region: '',
  residence_subcity: '',
  residence_woreda: '',
  residence_kebele: '',
  residence_house_number: '',
  residence_line: '',
  residence_postal_code: '',
  address_effective_from: '',
  address_effective_to: '',

  // Organizational Placement & Hierarchy
  entity_id: '',
  department_name: '',
  job_title: '',
  work_location: '',
  reports_to: '',

  // Employment Lifecycle & Contract Terms
  employment_type: '',
  contract_type: '',
  hire_date: '',
  end_date: '',
  shift_pattern_id: '',
  is_working_days_only: false,
  weekly_hours: '40',
  probation_months: '0',
  probation_end_date: '',
  notice_period_days: '0',
  tin: '',
  pension_number: '',
  notes: '',

  // Remuneration & Package (Moved Grade & Steps here for unified UX)
  job_grade: '',
  job_grade_step: '',
  salary_structure: '',
  basic_amount: '',
  currency: 'ETB',
  payroll_group: '',
  salary_effective_date: '',
  salary_effective_until: '',
  transport_allowance: '',
  housing_allowance: '',
  compensation_supervisor: '',

  // Primary Salary Bank Account
  bank_name: '',
  branch_name: '',
  account_number: '',
  account_holder_name: '',
  has_secondary_bank: false,
  primary_split_percent: 80,
  secondary_bank_name: '',
  secondary_account_number: '',
  secondary_account_holder_name: '',
  secondary_branch_name: '',

  // Special Provisions & Workplace Safeguards (Compliance Tab)
  has_guarantor: false,
  guarantor_party_id: null as number | null,
  guarantor_name: '',
  guarantor_phone: '',
  guarantor_id_number: '',
  guarantor_relation: '',
  guarantee_purpose: '',
  guaranteed_amount: '',
  guarantor_employer_party_id: null as number | null,
  guarantor_employer: '',
  guarantor_monthly_income: '',
  guarantee_letter_ref_no: '',
  letter_agreement_date: '',
  coverage_start_date: '',
  coverage_end_date: '',
  guarantee_attachment: '',
  guarantor_notes: '',

  has_accessibility: false,
  disability_category: '',
  disability_severity: '',
  is_self_declared: false,
  affects_work_capacity: false,
  is_confidential: true,
  is_verified: false,
  medical_certificate_ref: '',
  medical_cert_attachment: '',
  accommodation_notes: ''
});

// ─── Collapsible Sections State (Matching Screenshots) ───
const sections = ref({
  // Tab 1: Personal
  demographics: false,
  residenceAddress: false,
  remarksSignature: false,

  // Tab 2: Employment (OrgPlacement expanded by default)
  orgPlacement: true,
  contractDetails: false,
  statutoryRegistration: false,

  // Tab 3: Compensation (Screenshot: Remuneration and PrimaryBank expanded)
  remuneration: true,
  allowances: true,
  primaryBank: true,

  // Tab 4: Qualifications (Screenshot: AcademicQualifications expanded)
  academicQualifications: true,
  professionalCertifications: false,
  priorWorkExperience: false,
  skillsLanguages: false,

  // Tab 5: Compliance
  regulatoryClearances: true,
  employeeGuarantor: false,
  workplaceAccessibility: false,

  // Tab 6: Family
  emergencyContacts: true,
  dependents: true
});

const toggleSection = (key: keyof typeof sections.value) => {
  sections.value[key] = !sections.value[key];
};

// ─── Child Sub-Tables Data Models ───

// ─── Child Sub-Tables Data Models & Expand Modal System ───
export type ChildTableType = 
  | 'academicQualifications' 
  | 'professionalCertifications' 
  | 'priorWorkExperiences' 
  | 'technicalSkills' 
  | 'spokenLanguages' 
  | 'regulatoryClearances' 
  | 'emergencyContactsList' 
  | 'dependentsList'
  | 'statutoryExemptionsList'
  | 'bankAccountsList'
  | 'salaryComponentsList'
  | 'addressesList';

export interface PartyAddressRow {
  id: number;
  selected: boolean;
  address_type: 'residence' | 'postal' | 'work' | 'emergency' | 'birth_place' | 'other';
  admin_unit: string;
  country?: string;
  region?: string;
  subcity_zone?: string;
  woreda?: string;
  line: string;
  house_number: string;
  kebele?: string;
  postal_code?: string;
  is_primary: boolean;
  effective_from?: string;
  effective_to?: string;
}

export interface EmployeeSalaryComponentRow {
  id: number;
  selected: boolean;
  component_name: string;
  calc_type: 'Fixed Amount' | 'Percentage of Basic';
  amount: number | string;
  percent?: number | string;
  payroll_formula?: string;
  effective_from?: string;
  effective_to?: string;
  order?: number;
}

export interface EmployeeBankAccountRow {
  id: number;
  selected: boolean;
  payment_provider: string;
  account_number: string;
  account_holder_name: string;
  branch_name: string;
  split_percent: number | string;
  is_primary: boolean;
}

export interface StatutoryExemptionRow {
  id: number;
  selected: boolean;
  rule_type: string;
  effective_from: string;
  effective_to: string;
  reason: string;
  approved_by: string;
}

export interface AcademicQualificationRow {
  id: number;
  selected: boolean;
  degree_level: string;
  field_of_study: string;
  awarding_institute: string;
  graduation_date: string;
  start_date: string;
  gpa: string;
}

export interface ProfessionalCertificationRow {
  id: number;
  selected: boolean;
  certification: string;
  issuing_institution: string;
  certificate_number: string;
  issued_date: string;
  expiry_date: string;
}

export interface PriorWorkExperienceRow {
  id: number;
  selected: boolean;
  previous_employer: string;
  job_title: string;
  employment_type: string;
  start_date: string;
  end_date: string;
  reason_for_leaving: string;
  supervisor_reference: string;
  responsibilities: string;
  is_relevant: boolean;
}

export interface TechnicalSkillRow {
  id: number;
  selected: boolean;
  skill: string;
  proficiency: string;
  years_of_experience: number | string;
}

export interface SpokenLanguageRow {
  id: number;
  selected: boolean;
  language: string;
  fluency_level: string;
  is_native: boolean;
  speaking_level: string;
  listening_level: string;
  reading_level: string;
  writing_level: string;
}

export interface RegulatoryClearanceRow {
  id: number;
  selected: boolean;
  clearance_type: string;
  ref_number: string;
  issue_date: string;
  expiry_date: string;
  verification_status: string;
  verified_by?: string;
  notes: string;
}

export interface EmergencyContactRow {
  id: number;
  selected: boolean;
  full_name: string;
  phone: string;
  relationship: string;
  priority: number | string;
  city_location: string;
}

export interface DependentRow {
  id: number;
  selected: boolean;
  dependent_name: string;
  relationship: string;
  birth_date: string;
  is_beneficiary: boolean;
  benefit_notes: string;
}

// Reactive table arrays
const addressesList = ref<PartyAddressRow[]>([
  {
    id: 1,
    selected: false,
    address_type: 'residence',
    country: 'Ethiopia',
    region: 'Addis Ababa',
    subcity_zone: 'Bole Sub-City',
    woreda: 'Woreda 03',
    kebele: 'Kebele 01',
    line: 'Cameroon St., near Edna Mall',
    house_number: '214',
    postal_code: '',
    is_primary: true,
    effective_from: '2024-01-15',
    effective_to: '',
    admin_unit: 'Addis Ababa > Bole Sub-City > Woreda 03 > Kebele 01'
  }
]);
const academicQualifications = ref<AcademicQualificationRow[]>([]);
const professionalCertifications = ref<ProfessionalCertificationRow[]>([]);
const priorWorkExperiences = ref<PriorWorkExperienceRow[]>([]);
const technicalSkills = ref<TechnicalSkillRow[]>([]);
const spokenLanguages = ref<SpokenLanguageRow[]>([]);
const regulatoryClearances = ref<RegulatoryClearanceRow[]>([]);
const emergencyContactsList = ref<EmergencyContactRow[]>([]);
const dependentsList = ref<DependentRow[]>([]);
const statutoryExemptionsList = ref<StatutoryExemptionRow[]>([]);
const bankAccountsList = ref<EmployeeBankAccountRow[]>([
  {
    id: 1,
    selected: false,
    payment_provider: 'Commercial Bank of Ethiopia (CBE)',
    account_number: '1000234511209',
    account_holder_name: 'Abebe Kebede Wolde',
    branch_name: 'Bole Medhanealem Branch',
    split_percent: 100,
    is_primary: true
  }
]);
const salaryComponentsList = ref<EmployeeSalaryComponentRow[]>([
  {
    id: 1,
    selected: false,
    component_name: 'Transport Allowance',
    calc_type: 'Fixed Amount',
    amount: 2200,
    effective_from: '',
    effective_to: ''
  },
  {
    id: 2,
    selected: false,
    component_name: 'Housing Allowance',
    calc_type: 'Fixed Amount',
    amount: 3000,
    effective_from: '',
    effective_to: ''
  }
]);

// Factory for blank row models
const createBlankRow = (type: ChildTableType): any => {
  const id = Date.now() + Math.floor(Math.random() * 1000);
  switch (type) {
    case 'academicQualifications':
      return {
        id,
        selected: false,
        degree_level: '',
        field_of_study: '',
        awarding_institute: '',
        graduation_date: '',
        start_date: '',
        gpa: ''
      };
    case 'professionalCertifications':
      return {
        id,
        selected: false,
        certification: '',
        issuing_institution: '',
        certificate_number: '',
        issued_date: '',
        expiry_date: ''
      };
    case 'priorWorkExperiences':
      return {
        id,
        selected: false,
        previous_employer: '',
        job_title: '',
        employment_type: 'Permanent',
        start_date: '',
        end_date: '',
        reason_for_leaving: '',
        supervisor_reference: '',
        responsibilities: '',
        is_relevant: true
      };
    case 'technicalSkills':
      return {
        id,
        selected: false,
        skill: '',
        proficiency: 'Intermediate',
        years_of_experience: 1
      };
    case 'spokenLanguages':
      return {
        id,
        selected: false,
        language: '',
        fluency_level: 'Fluent',
        is_native: false,
        speaking_level: 'Fluent',
        listening_level: 'Fluent',
        reading_level: 'Fluent',
        writing_level: 'Fluent'
      };
    case 'regulatoryClearances':
      return {
        id,
        selected: false,
        clearance_type: '',
        ref_number: '',
        issue_date: '',
        expiry_date: '',
        verification_status: 'Valid / Cleared',
        verified_by: '',
        notes: ''
      };
    case 'emergencyContactsList':
      return {
        id,
        selected: false,
        full_name: '',
        phone: '',
        relationship: '',
        priority: emergencyContactsList.value.length === 0 ? 1 : 2,
        city_location: ''
      };
    case 'dependentsList':
      return {
        id,
        selected: false,
        dependent_name: '',
        relationship: '',
        birth_date: '',
        is_beneficiary: true,
        benefit_notes: ''
      };
    case 'statutoryExemptionsList':
      return {
        id,
        selected: false,
        rule_type: '',
        effective_from: form.value.salary_effective_date || form.value.hire_date || '',
        effective_to: '',
        reason: '',
        approved_by: ''
      };
    case 'bankAccountsList':
      return {
        id,
        selected: false,
        payment_provider: '',
        account_number: '',
        account_holder_name: form.value.first_name ? `${form.value.first_name} ${form.value.middle_name || ''} ${form.value.last_name || ''}`.trim() : '',
        branch_name: '',
        split_percent: bankAccountsList.value.length === 0 ? 100 : 0,
        is_primary: bankAccountsList.value.length === 0
      };
    case 'salaryComponentsList':
      return {
        id,
        selected: false,
        component_name: 'Transport Allowance',
        calc_type: 'Fixed Amount',
        amount: '',
        payroll_formula: 'Default Component Formula',
        effective_from: '',
        effective_to: ''
      };
    case 'addressesList':
      return {
        id,
        selected: false,
        address_type: 'residence',
        country: 'Ethiopia',
        region: 'Addis Ababa',
        subcity_zone: '',
        woreda: '',
        kebele: '',
        line: '',
        house_number: '',
        postal_code: '',
        is_primary: addressesList.value.length === 0,
        effective_from: form.value.hire_date || new Date().toISOString().split('T')[0],
        effective_to: '',
        admin_unit: ''
      };
  }
};

// Add Row handlers
const addAddressItem = () => addressesList.value.push(createBlankRow('addressesList'));
const removeAddressItem = (index: number) => {
  addressesList.value.splice(index, 1);
};
const addAcademicQualification = () => academicQualifications.value.push(createBlankRow('academicQualifications'));
const addProfessionalCertification = () => professionalCertifications.value.push(createBlankRow('professionalCertifications'));
const addPriorWorkExperience = () => priorWorkExperiences.value.push(createBlankRow('priorWorkExperiences'));
const addTechnicalSkill = () => technicalSkills.value.push(createBlankRow('technicalSkills'));
const addSpokenLanguage = () => spokenLanguages.value.push(createBlankRow('spokenLanguages'));
const addRegulatoryClearance = () => regulatoryClearances.value.push(createBlankRow('regulatoryClearances'));
const addEmergencyContactPerson = () => emergencyContactsList.value.push(createBlankRow('emergencyContactsList'));
const addDependentItem = () => dependentsList.value.push(createBlankRow('dependentsList'));
const addStatutoryExemptionRow = () => statutoryExemptionsList.value.push(createBlankRow('statutoryExemptionsList'));
const addBankAccount = () => bankAccountsList.value.push(createBlankRow('bankAccountsList'));
const addSalaryComponent = () => salaryComponentsList.value.push(createBlankRow('salaryComponentsList'));

// ─── Address Cards Repeater Helpers ───
const getRegionsForRow = (row: PartyAddressRow) => {
  if (!row.country || row.country === 'Ethiopia') {
    return ethiopianRegions;
  }
  if (row.country === 'Kenya') {
    return ['Nairobi County', 'Mombasa County', 'Kisumu County', 'Nakuru County', 'Kiambu County'];
  }
  if (row.country === 'Djibouti') {
    return ['Djibouti City', 'Ali Sabieh', 'Dikhil', 'Tadjourah', 'Obock', 'Arta'];
  }
  if (row.country === 'United States') {
    return ['California', 'New York', 'Texas', 'Washington', 'Virginia', 'Maryland'];
  }
  if (row.country === 'United Kingdom') {
    return ['Greater London', 'West Midlands', 'Greater Manchester', 'Scotland'];
  }
  return [];
};

const getZonesForRow = (row: PartyAddressRow) => {
  if (!row.region) return [];
  return subcitiesByRegion[row.region] || [
    'Central Zone', 'North Zone', 'South Zone', 'East Zone', 'West Zone', 'Special Zone'
  ];
};

const getWoredasForRow = (row: PartyAddressRow) => {
  if (!row.subcity_zone) return [];
  if (woredasBySubcity[row.subcity_zone]) {
    return woredasBySubcity[row.subcity_zone];
  }
  return [
    'Woreda 01', 'Woreda 02', 'Woreda 03', 'Woreda 04', 'Woreda 05',
    'Woreda 06', 'Woreda 07', 'Woreda 08', 'Woreda 09', 'Woreda 10'
  ];
};

const getKebelesForRow = (_row: PartyAddressRow) => {
  return [
    'Kebele 01', 'Kebele 02', 'Kebele 03', 'Kebele 04', 'Kebele 05',
    'Kebele 06', 'Kebele 07', 'Kebele 08', 'Kebele 09', 'Kebele 10',
    'Kebele 11', 'Kebele 12', 'Kebele 13', 'Kebele 14', 'Kebele 15'
  ];
};

const onRowCountryChange = (row: PartyAddressRow) => {
  row.region = '';
  row.subcity_zone = '';
  row.woreda = '';
  row.kebele = '';
  syncAdminUnitForRow(row);
};

const onRowRegionChange = (row: PartyAddressRow) => {
  row.subcity_zone = '';
  row.woreda = '';
  row.kebele = '';
  syncAdminUnitForRow(row);
};

const onRowZoneChange = (row: PartyAddressRow) => {
  row.woreda = '';
  row.kebele = '';
  syncAdminUnitForRow(row);
};

const onRowWoredaChange = (row: PartyAddressRow) => {
  row.kebele = '';
  syncAdminUnitForRow(row);
};

const onRowKebeleChange = (row: PartyAddressRow) => {
  syncAdminUnitForRow(row);
};

const syncAdminUnitForRow = (row: PartyAddressRow) => {
  const parts: string[] = [];
  if (row.region) parts.push(row.region);
  if (row.subcity_zone) parts.push(row.subcity_zone);
  if (row.woreda) parts.push(row.woreda);
  if (row.kebele) parts.push(row.kebele);
  row.admin_unit = parts.join(' > ');
};

// ─── Exact Geographic Location Catalog & Reactive Hierarchy ───
const ethiopianRegions = [
  'Addis Ababa',
  'Dire Dawa',
  'Oromia',
  'Amhara',
  'Sidama',
  'Tigray',
  'Central Ethiopia',
  'South Ethiopia',
  'South West Ethiopia',
  'Somali',
  'Afar',
  'Benishangul-Gumuz',
  'Gambela',
  'Harari'
];

const subcitiesByRegion: Record<string, string[]> = {
  'Addis Ababa': [
    'Bole Sub-City',
    'Kirkos Sub-City',
    'Yeka Sub-City',
    'Arada Sub-City',
    'Lideta Sub-City',
    'Gulele Sub-City',
    'Nifas Silk-Lafto Sub-City',
    'Kolfe Keranio Sub-City',
    'Akaki Kality Sub-City',
    'Lemi Kura Sub-City',
    'Addis Ketema Sub-City'
  ],
  'Dire Dawa': [
    'Dire Dawa City',
    'Gurgura'
  ],
  'Oromia': [
    'Sheger City',
    'East Shewa Zone (Adama)',
    'Finfine Special Zone',
    'West Shewa Zone (Ambo)',
    'Jimma Zone',
    'Arsi Zone (Asella)',
    'West Arsi Zone (Shashamane)',
    'North Shewa Zone'
  ],
  'Amhara': [
    'Bahir Dar Special Zone',
    'North Shewa Zone (Debre Berhan)',
    'South Gondar Zone (Debre Tabor)',
    'North Gondar Zone (Gondar City)',
    'West Gojjam Zone',
    'East Gojjam Zone',
    'South Wollo Zone (Dessie)'
  ],
  'Sidama': [
    'Hawassa City Administration',
    'Aleta Wondo',
    'Dale',
    'Yirgalem'
  ],
  'Tigray': [
    'Mekelle Special Zone',
    'Central Tigray',
    'Eastern Tigray'
  ],
  'Central Ethiopia': [
    'Gurage Zone',
    'Silte Zone',
    'Hadiya Zone'
  ],
  'South Ethiopia': [
    'Wolayita Zone (Sodo)',
    'Gamo Zone (Arba Minch)',
    'Gofa Zone'
  ],
  'Somali': [
    'Fafan Zone (Jigjiga)',
    'Siti Zone'
  ],
  'Harari': [
    'Harar City'
  ]
};

const woredasBySubcity: Record<string, string[]> = {
  'Bole Sub-City': ['Woreda 01', 'Woreda 02', 'Woreda 03', 'Woreda 04', 'Woreda 05', 'Woreda 06', 'Woreda 07', 'Woreda 08', 'Woreda 09', 'Woreda 10', 'Woreda 11', 'Woreda 12', 'Woreda 13', 'Woreda 14'],
  'Kirkos Sub-City': ['Woreda 01', 'Woreda 02', 'Woreda 03', 'Woreda 04', 'Woreda 05', 'Woreda 06', 'Woreda 07', 'Woreda 08', 'Woreda 09', 'Woreda 10', 'Woreda 11'],
  'Yeka Sub-City': ['Woreda 01', 'Woreda 02', 'Woreda 03', 'Woreda 04', 'Woreda 05', 'Woreda 06', 'Woreda 07', 'Woreda 08', 'Woreda 09', 'Woreda 10', 'Woreda 11', 'Woreda 12', 'Woreda 13'],
  'Arada Sub-City': ['Woreda 01', 'Woreda 02', 'Woreda 03', 'Woreda 04', 'Woreda 05', 'Woreda 06', 'Woreda 07', 'Woreda 08', 'Woreda 09', 'Woreda 10'],
  'Lideta Sub-City': ['Woreda 01', 'Woreda 02', 'Woreda 03', 'Woreda 04', 'Woreda 05', 'Woreda 06', 'Woreda 07', 'Woreda 08', 'Woreda 09', 'Woreda 10'],
  'Gulele Sub-City': ['Woreda 01', 'Woreda 02', 'Woreda 03', 'Woreda 04', 'Woreda 05', 'Woreda 06', 'Woreda 07', 'Woreda 08', 'Woreda 09', 'Woreda 10'],
  'Nifas Silk-Lafto Sub-City': ['Woreda 01', 'Woreda 02', 'Woreda 03', 'Woreda 04', 'Woreda 05', 'Woreda 06', 'Woreda 07', 'Woreda 08', 'Woreda 09', 'Woreda 10', 'Woreda 11', 'Woreda 12', 'Woreda 13', 'Woreda 14', 'Woreda 15'],
  'Kolfe Keranio Sub-City': ['Woreda 01', 'Woreda 02', 'Woreda 03', 'Woreda 04', 'Woreda 05', 'Woreda 06', 'Woreda 07', 'Woreda 08', 'Woreda 09', 'Woreda 10', 'Woreda 11', 'Woreda 12', 'Woreda 13', 'Woreda 14', 'Woreda 15'],
  'Akaki Kality Sub-City': ['Woreda 01', 'Woreda 02', 'Woreda 03', 'Woreda 04', 'Woreda 05', 'Woreda 06', 'Woreda 07', 'Woreda 08', 'Woreda 09', 'Woreda 10', 'Woreda 11', 'Woreda 12', 'Woreda 13'],
  'Lemi Kura Sub-City': ['Woreda 01', 'Woreda 02', 'Woreda 03', 'Woreda 04', 'Woreda 05', 'Woreda 06', 'Woreda 07', 'Woreda 08', 'Woreda 09', 'Woreda 10'],
  'Addis Ketema Sub-City': ['Woreda 01', 'Woreda 02', 'Woreda 03', 'Woreda 04', 'Woreda 05', 'Woreda 06', 'Woreda 07', 'Woreda 08', 'Woreda 09', 'Woreda 10']
};

const isCustomSubcity = ref(false);
const customSubcityText = ref('');
const isCustomWoreda = ref(false);
const customWoredaText = ref('');

const currentRegionOptions = computed(() => {
  if (!activeRowData.value) return ethiopianRegions;
  const c = activeRowData.value.country;
  if (!c || c === 'Ethiopia') return ethiopianRegions;
  if (c === 'Kenya') return ['Nairobi County', 'Mombasa County', 'Kisumu County', 'Nakuru County', 'Kiambu County'];
  if (c === 'Djibouti') return ['Djibouti City', 'Ali Sabieh', 'Dikhil', 'Tadjourah', 'Obock', 'Arta'];
  if (c === 'United States') return ['California', 'New York', 'Texas', 'Washington', 'Virginia', 'Maryland'];
  if (c === 'United Kingdom') return ['Greater London', 'West Midlands', 'Greater Manchester', 'Scotland'];
  return [];
});

const currentSubcityOptions = computed(() => {
  if (!activeRowData.value || !activeRowData.value.region) return [];
  return subcitiesByRegion[activeRowData.value.region] || [];
});

const currentWoredaOptions = computed(() => {
  if (!activeRowData.value || !activeRowData.value.subcity_zone) return [];
  return woredasBySubcity[activeRowData.value.subcity_zone] || [];
});

const onCountryChange = () => {
  if (!activeRowData.value) return;
  activeRowData.value.region = '';
  activeRowData.value.subcity_zone = '';
  activeRowData.value.woreda = '';
  isCustomSubcity.value = false;
  customSubcityText.value = '';
  isCustomWoreda.value = false;
  customWoredaText.value = '';
  updateAdminUnitSummary();
};

const onRegionChange = () => {
  if (!activeRowData.value) return;
  activeRowData.value.subcity_zone = '';
  activeRowData.value.woreda = '';
  isCustomSubcity.value = false;
  customSubcityText.value = '';
  isCustomWoreda.value = false;
  customWoredaText.value = '';
  updateAdminUnitSummary();
};

const onSubcityChange = () => {
  if (!activeRowData.value) return;
  if (activeRowData.value.subcity_zone === '__custom__') {
    isCustomSubcity.value = true;
    activeRowData.value.subcity_zone = customSubcityText.value || '';
  } else {
    isCustomSubcity.value = false;
    customSubcityText.value = '';
  }
  activeRowData.value.woreda = '';
  isCustomWoreda.value = false;
  customWoredaText.value = '';
  updateAdminUnitSummary();
};

const onCustomSubcityInput = () => {
  if (!activeRowData.value) return;
  activeRowData.value.subcity_zone = customSubcityText.value;
  updateAdminUnitSummary();
};

const onWoredaChange = () => {
  if (!activeRowData.value) return;
  if (activeRowData.value.woreda === '__custom__') {
    isCustomWoreda.value = true;
    activeRowData.value.woreda = customWoredaText.value || '';
  } else {
    isCustomWoreda.value = false;
    customWoredaText.value = '';
  }
  updateAdminUnitSummary();
};

const onCustomWoredaInput = () => {
  if (!activeRowData.value) return;
  activeRowData.value.woreda = customWoredaText.value;
  updateAdminUnitSummary();
};

const updateAdminUnitSummary = () => {
  if (!activeRowData.value) return;
  const parts: string[] = [];
  if (activeRowData.value.region) parts.push(activeRowData.value.region);
  if (activeRowData.value.subcity_zone && activeRowData.value.subcity_zone !== '__custom__') {
    parts.push(activeRowData.value.subcity_zone);
  }
  if (activeRowData.value.woreda && activeRowData.value.woreda !== '__custom__') {
    parts.push(activeRowData.value.woreda);
  }
  activeRowData.value.admin_unit = parts.length > 0 ? parts.join(' > ') : '';
};

const syncRowFromAdminUnitString = (row: PartyAddressRow) => {
  if (!row.admin_unit) return;
  const parts = row.admin_unit.split('>').map(s => s.trim()).filter(Boolean);
  if (parts.length >= 1 && ethiopianRegions.includes(parts[0])) {
    row.region = parts[0];
    row.country = 'Ethiopia';
  }
  if (parts.length >= 2) {
    row.subcity_zone = parts[1];
  }
  if (parts.length >= 3) {
    row.woreda = parts[2];
  }
};

const setPrimaryAddress = (selectedIdx: number) => {
  const targetType = addressesList.value[selectedIdx].address_type;
  addressesList.value.forEach((addr, idx) => {
    if (addr.address_type === targetType) {
      addr.is_primary = (idx === selectedIdx);
    }
  });
};

const setPrimaryAccount = (selectedIdx: number) => {
  bankAccountsList.value.forEach((acc, idx) => {
    acc.is_primary = (idx === selectedIdx);
  });
};

// ─── Modal State & Operations ───
const showRowModal = ref(false);
const activeModalType = ref<ChildTableType>('academicQualifications');
const activeRowData = ref<any>(null);
const activeRowIndex = ref<number>(0);

const modalSectionTitles: Record<ChildTableType, string> = {
  addressesList: 'Address & Physical Domicile',
  academicQualifications: 'Academic Qualification',
  professionalCertifications: 'Certification & License',
  priorWorkExperiences: 'Work Experience',
  technicalSkills: 'Technical Skill',
  spokenLanguages: 'Spoken Language',
  regulatoryClearances: 'Statutory Clearance & Compliance',
  emergencyContactsList: 'Emergency Contact',
  dependentsList: 'Dependent & Insurance Beneficiary',
  statutoryExemptionsList: 'Tax & Pension Exemption',
  bankAccountsList: 'Bank Account',
  salaryComponentsList: 'Allowance & Benefit'
};

const getListByType = (type: ChildTableType): any[] => {
  switch (type) {
    case 'addressesList': return addressesList.value;
    case 'academicQualifications': return academicQualifications.value;
    case 'professionalCertifications': return professionalCertifications.value;
    case 'priorWorkExperiences': return priorWorkExperiences.value;
    case 'technicalSkills': return technicalSkills.value;
    case 'spokenLanguages': return spokenLanguages.value;
    case 'regulatoryClearances': return regulatoryClearances.value;
    case 'emergencyContactsList': return emergencyContactsList.value;
    case 'dependentsList': return dependentsList.value;
    case 'statutoryExemptionsList': return statutoryExemptionsList.value;
    case 'bankAccountsList': return bankAccountsList.value;
    case 'salaryComponentsList': return salaryComponentsList.value;
  }
};

const openRowModal = (type: ChildTableType, row: any, idx: number) => {
  activeModalType.value = type;
  activeRowData.value = row;
  activeRowIndex.value = idx;
  if (type === 'addressesList' && row) {
    const availableSubcities = subcitiesByRegion[row.region] || [];
    if (row.subcity_zone && !availableSubcities.includes(row.subcity_zone)) {
      isCustomSubcity.value = true;
      customSubcityText.value = row.subcity_zone;
    } else {
      isCustomSubcity.value = false;
      customSubcityText.value = '';
    }

    const availableWoredas = woredasBySubcity[row.subcity_zone] || [];
    if (row.woreda && !availableWoredas.includes(row.woreda)) {
      isCustomWoreda.value = true;
      customWoredaText.value = row.woreda;
    } else {
      isCustomWoreda.value = false;
      customWoredaText.value = '';
    }
  }
  showRowModal.value = true;
};

const closeRowModal = () => {
  showRowModal.value = false;
  activeRowData.value = null;
};

const modalTitle = computed(() => {
  const sectionTitle = modalSectionTitles[activeModalType.value] || 'Row Item';
  return `${sectionTitle} (Row ${activeRowIndex.value + 1})`;
});

const isFirstRow = computed(() => activeRowIndex.value <= 0);
const isLastRow = computed(() => {
  const list = getListByType(activeModalType.value);
  return !list || activeRowIndex.value >= list.length - 1;
});

const deleteModalRow = () => {
  const list = getListByType(activeModalType.value);
  if (!list || activeRowIndex.value < 0 || activeRowIndex.value >= list.length) return;
  list.splice(activeRowIndex.value, 1);
  if (list.length === 0) {
    closeRowModal();
  } else {
    if (activeRowIndex.value >= list.length) {
      activeRowIndex.value = list.length - 1;
    }
    activeRowData.value = list[activeRowIndex.value];
  }
};

const moveRowDown = () => {
  const list = getListByType(activeModalType.value);
  if (!list || activeRowIndex.value >= list.length - 1) return;
  const curr = list[activeRowIndex.value];
  const next = list[activeRowIndex.value + 1];
  list[activeRowIndex.value] = next;
  list[activeRowIndex.value + 1] = curr;
  activeRowIndex.value++;
  activeRowData.value = list[activeRowIndex.value];
};

const moveRowUp = () => {
  const list = getListByType(activeModalType.value);
  if (!list || activeRowIndex.value <= 0) return;
  const curr = list[activeRowIndex.value];
  const prev = list[activeRowIndex.value - 1];
  list[activeRowIndex.value] = prev;
  list[activeRowIndex.value - 1] = curr;
  activeRowIndex.value--;
  activeRowData.value = list[activeRowIndex.value];
};

const duplicateModalRow = () => {
  const list = getListByType(activeModalType.value);
  if (!list || !activeRowData.value) return;
  const clone = JSON.parse(JSON.stringify(activeRowData.value));
  clone.id = Date.now() + Math.floor(Math.random() * 1000);
  clone.selected = false;
  list.splice(activeRowIndex.value + 1, 0, clone);
  activeRowIndex.value++;
  activeRowData.value = list[activeRowIndex.value];
};

const insertRowAbove = () => {
  const list = getListByType(activeModalType.value);
  if (!list) return;
  const newRow = createBlankRow(activeModalType.value);
  list.splice(activeRowIndex.value, 0, newRow);
  activeRowData.value = list[activeRowIndex.value];
};

const insertRowBelow = () => {
  const list = getListByType(activeModalType.value);
  if (!list) return;
  const newRow = createBlankRow(activeModalType.value);
  list.splice(activeRowIndex.value + 1, 0, newRow);
  activeRowIndex.value++;
  activeRowData.value = list[activeRowIndex.value];
};

// Select All Handlers
const toggleSelectAll = (list: Array<{ selected: boolean }>, e: Event) => {
  const isChecked = (e.target as HTMLInputElement).checked;
  list.forEach(item => item.selected = isChecked);
};

// ─── Dynamic Floating Action Bar Engine (Matching Images 1 & 2) ───
const activeSelectedTable = computed<ChildTableType | null>(() => {
  if (salaryComponentsList.value.some(r => r.selected)) return 'salaryComponentsList';
  if (bankAccountsList.value.some(r => r.selected)) return 'bankAccountsList';
  if (addressesList.value.some(r => r.selected)) return 'addressesList';
  if (statutoryExemptionsList.value.some(r => r.selected)) return 'statutoryExemptionsList';
  if (academicQualifications.value.some(r => r.selected)) return 'academicQualifications';
  if (professionalCertifications.value.some(r => r.selected)) return 'professionalCertifications';
  if (priorWorkExperiences.value.some(r => r.selected)) return 'priorWorkExperiences';
  if (technicalSkills.value.some(r => r.selected)) return 'technicalSkills';
  if (spokenLanguages.value.some(r => r.selected)) return 'spokenLanguages';
  if (regulatoryClearances.value.some(r => r.selected)) return 'regulatoryClearances';
  if (emergencyContactsList.value.some(r => r.selected)) return 'emergencyContactsList';
  if (dependentsList.value.some(r => r.selected)) return 'dependentsList';
  return null;
});

const currentSelectedList = computed<any[]>(() => {
  if (!activeSelectedTable.value) return [];
  return getListByType(activeSelectedTable.value) || [];
});

const floatingSelectedCount = computed(() => {
  return currentSelectedList.value.filter(r => r.selected).length;
});

const floatingTotalCount = computed(() => {
  return currentSelectedList.value.length;
});

const handleFloatingSelectAll = () => {
  currentSelectedList.value.forEach(r => r.selected = true);
};

const handleFloatingDuplicate = () => {
  const table = activeSelectedTable.value;
  if (!table) return;
  const list = getListByType(table);
  const selectedItems = list.filter(r => r.selected);
  selectedItems.forEach(item => {
    const cloned = JSON.parse(JSON.stringify(item));
    cloned.id = Date.now() + Math.floor(Math.random() * 1000);
    cloned.selected = false;
    list.push(cloned);
  });
  list.forEach(r => r.selected = false);
};

const handleFloatingDelete = () => {
  const table = activeSelectedTable.value;
  if (!table) return;
  const list = getListByType(table);
  const remaining = list.filter(r => !r.selected);
  list.length = 0;
  remaining.forEach(r => list.push(r));
};

const handleFloatingEdit = () => {
  const table = activeSelectedTable.value;
  if (!table) return;
  const list = getListByType(table);
  const idx = list.findIndex(r => r.selected);
  if (idx !== -1) {
    openRowModal(table, list[idx], idx);
  }
};

const handleFloatingChangeStatus = (status: string) => {
  const list = currentSelectedList.value;
  list.filter(r => r.selected).forEach(r => {
    if ('verification_status' in r) (r as any).verification_status = status;
    if ('status' in r) (r as any).status = status;
    if ('state' in r) (r as any).state = status;
  });
  list.forEach(r => r.selected = false);
};

const handleFloatingClose = () => {
  currentSelectedList.value.forEach(r => r.selected = false);
};

// Payment Providers Catalog
const paymentProviders = [
  'JPMorgan Chase / Commercial Banking',
  'Citibank / Treasury & Trade Solutions',
  'HSBC Global Liquidity',
  'Standard Chartered Bank',
  'Barclays Corporate Banking',
  'Bank of America Merrill Lynch',
  'Direct ACH Clearing',
  'Commercial Bank of Ethiopia (CBE)',
  'Awash Bank',
  'Corporate Wire Transfer',
  'Enterprise Digital Wallet'
];

// Computed Gross Monthly Package
const grossStartingPackage = computed(() => {
  const base = Number(form.value.basic_amount) || 0;
  const allowancesTotal = salaryComponentsList.value.reduce((sum, item) => {
    if (item.calc_type === 'Percentage of Basic') {
      return sum + (base * (Number(item.amount) || 0) / 100);
    }
    return sum + (Number(item.amount) || 0);
  }, 0);
  const total = base + allowancesTotal;
  return total > 0 ? total : null;
});

// Auto-align Job Grade when Job Position is selected (Schema: JobPosition.job_grade_id)
const positionGradeMap: Record<string, string> = {
  'Junior Auditor': 'Grade C1',
  'Financial Accountant': 'Grade B2',
  'Chief Accountant': 'Grade B1',
  'Treasury Officer': 'Grade B2',
  'HR Officer': 'Grade C2',
  'Senior HR Specialist': 'Grade B1',
  'Procurement Officer': 'Grade C2',
  'Supply Chain Analyst': 'Grade B2',
  'Operations Supervisor': 'Grade B1',
  'Senior Cashier': 'Grade C1',
  'Software Engineer': 'Grade B1'
};

watch(() => form.value.job_title, (val) => {
  if (val && positionGradeMap[val]) {
    form.value.job_grade = positionGradeMap[val];
    const data = gradeScaleTable[form.value.job_grade];
    if (data && data.steps.length > 0) {
      form.value.job_grade_step = `Step 1 (Entry - ${data.steps[0].toLocaleString()} ETB)`;
      form.value.basic_amount = data.steps[0];
    }
  }
});

// Dynamic Grade Scale & Benchmark Engine (Schema JobGrade & JobGradeStep)
const gradeScaleTable: Record<string, { floor: number; ceiling: number; steps: number[] }> = {
  'Grade C1': { floor: 5000, ceiling: 9000, steps: [6500, 7150, 7850, 8500, 9000] },
  'Grade C2': { floor: 8000, ceiling: 13000, steps: [9500, 10500, 11500, 12200, 13000] },
  'Grade B2': { floor: 11000, ceiling: 18000, steps: [12000, 13500, 15000, 16500, 18000] },
  'Grade B1': { floor: 17000, ceiling: 27000, steps: [19000, 21000, 23000, 25000, 27000] },
  'Grade A3': { floor: 26000, ceiling: 40000, steps: [29000, 32000, 35000, 38000, 40000] },
  'Grade A2': { floor: 35000, ceiling: 55000, steps: [39000, 43000, 47000, 51000, 55000] },
  'Grade A1': { floor: 50000, ceiling: 80000, steps: [55000, 61000, 67000, 73000, 80000] }
};

const availableGradeSteps = computed(() => {
  const g = form.value.job_grade || 'Grade B2';
  const data = gradeScaleTable[g];
  if (!data) return ['Step 1 (Entry)', 'Step 2', 'Step 3', 'Step 4', 'Step 5'];
  return data.steps.map((amount, idx) => {
    return idx === 0 
      ? `Step 1 (Entry - ${amount.toLocaleString()} ETB)` 
      : `Step ${idx + 1} (${amount.toLocaleString()} ETB)`;
  });
});

const activeGradeScale = computed(() => {
  const g = form.value.job_grade || 'Grade B2';
  const data = gradeScaleTable[g] || gradeScaleTable['Grade B2'];
  let stepIndex = 0;
  if (form.value.job_grade_step) {
    const match = form.value.job_grade_step.match(/\d+/);
    if (match) {
      stepIndex = Math.max(0, Math.min(data.steps.length - 1, parseInt(match[0], 10) - 1));
    }
  }
  const stepAmount = data.steps[stepIndex] || data.steps[0];
  return {
    grade: g,
    floor: data.floor,
    ceiling: data.ceiling,
    stepAmount
  };
});

// Update basic salary when step is picked
watch(() => form.value.job_grade_step, (stepVal) => {
  if (!stepVal) return;
  const match = stepVal.match(/Step\s*(\d+)/i);
  if (match) {
    const stepNum = parseInt(match[1], 10);
    const g = form.value.job_grade || 'Grade B2';
    const data = gradeScaleTable[g];
    if (data && data.steps[stepNum - 1] !== undefined) {
      form.value.basic_amount = data.steps[stepNum - 1];
    }
  }
});

// Salary Structure Templates (Schema Section 8: SalaryStructure & SalaryStructureLine)
const salaryStructures: Record<string, { basic: number; transport: number; housing: number }> = {
  'Standard Professional Package': { basic: 14500, transport: 2200, housing: 3000 },
  'Executive & Management Package': { basic: 32000, transport: 5000, housing: 8000 },
  'Plant & Factory Staff Package': { basic: 7500, transport: 1200, housing: 1500 },
  'Sales & Field Package': { basic: 11000, transport: 3500, housing: 2000 }
};

watch(() => form.value.salary_structure, (val) => {
  if (val && salaryStructures[val]) {
    const template = salaryStructures[val];
    form.value.basic_amount = template.basic;
    salaryComponentsList.value = [
      {
        id: Date.now() + 1,
        selected: false,
        component_name: 'Transport Allowance',
        calc_type: 'Fixed Amount',
        amount: template.transport,
        effective_from: '',
        effective_to: ''
      },
      {
        id: Date.now() + 2,
        selected: false,
        component_name: 'Housing Allowance',
        calc_type: 'Fixed Amount',
        amount: template.housing,
        effective_from: '',
        effective_to: ''
      }
    ];
  }
});

// Auto-sync salary effective date to hire date
watch(() => form.value.hire_date, (val) => {
  if (val && (!form.value.salary_effective_date || form.value.salary_effective_date === '')) {
    form.value.salary_effective_date = val;
  }
});

// Payday calculation helper based on PayrollGroup (payday on the 26th of month)
const nextPaydayInfo = computed(() => {
  const dateStr = form.value.salary_effective_date || form.value.hire_date;
  if (!dateStr) return null;
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return null;

  const paydayDay = 26; // Standard payroll payday from PayrollGroup in schema
  const year = d.getFullYear();
  const month = d.getMonth();
  const day = d.getDate();

  let nextPayday = new Date(year, month, paydayDay);
  if (day > paydayDay) {
    nextPayday = new Date(year, month + 1, paydayDay);
  }

  const diffDays = Math.max(1, Math.round((nextPayday.getTime() - d.getTime()) / (1000 * 60 * 60 * 24)));
  const formatted = nextPayday.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });

  return {
    dateFormatted: formatted,
    daysWorked: diffDays,
    isProrated: day !== 1
  };
});

// Auto compute Planned Probation End Date
watch([() => form.value.hire_date, () => form.value.probation_months], ([hDate, pMonths]) => {
  if (hDate && pMonths && Number(pMonths) > 0) {
    const d = new Date(hDate);
    if (!isNaN(d.getTime())) {
      d.setMonth(d.getMonth() + Number(pMonths));
      form.value.probation_end_date = d.toISOString().split('T')[0];
    }
  } else {
    form.value.probation_end_date = '';
  }
});

// ─── Dynamic Position Guarantee Requirement (JobPosition.guarantee_required_amount) ───
interface PositionGuaranteeInfo {
  required: boolean;
  amount: number;
  reason: string;
}

const positionGuaranteeMap: Record<string, PositionGuaranteeInfo> = {
  'Senior Cashier': { 
    required: true, 
    amount: 50000, 
    reason: 'Daily retail vault custody, cash till settlement, and high-volume disbursements under Company Risk Policy.' 
  },
  'Treasury Officer': { 
    required: true, 
    amount: 40000, 
    reason: 'Bank mandate execution, treasury transfers, and check clearing fiduciary responsibility.' 
  },
  'Operations Supervisor': { 
    required: true, 
    amount: 25000, 
    reason: 'Warehouse inventory access, plant asset security, and custody of finished goods.' 
  },
  'Procurement Officer': { 
    required: true, 
    amount: 20000, 
    reason: 'Supplier purchase commitments and direct cash procurement advances.' 
  },
  'Junior Auditor': { 
    required: true, 
    amount: 10000, 
    reason: 'Fiduciary audit sampling and petty cash spot-audit handling.' 
  }
};

const currentPositionGuarantee = computed<PositionGuaranteeInfo | null>(() => {
  if (!form.value.job_title) return null;
  return positionGuaranteeMap[form.value.job_title] || { 
    required: false, 
    amount: 0, 
    reason: '' 
  };
});

const applyPositionGuarantee = () => {
  if (currentPositionGuarantee.value && currentPositionGuarantee.value.required) {
    sections.value.employeeGuarantor = true;
    form.value.has_guarantor = true;
    form.value.guaranteed_amount = currentPositionGuarantee.value.amount.toString();
    if (form.value.job_title === 'Senior Cashier' || form.value.job_title === 'Treasury Officer') {
      form.value.guarantee_purpose = 'Cash Handling Surety (Cashier / Treasury)';
    } else if (form.value.job_title === 'Operations Supervisor') {
      form.value.guarantee_purpose = 'Asset Custody (Storekeeper / Warehouse)';
    } else if (form.value.job_title === 'Procurement Officer') {
      form.value.guarantee_purpose = 'Staff Loan / Financial Collateral';
    } else {
      form.value.guarantee_purpose = 'General Employment Surety';
    }
  }
};

// ─── Party Registry Data for Combobox Selectors (Lines 849, 851) ───
const guarantorPartyOptions = ref<ComboboxOption[]>([
  {
    id: 941,
    title: 'Solomon Kebede',
    subtitle: 'Phone: +251 911 234567',
    raw: {
      phone: '+251 911 234567',
      tin: 'NID-ET-994821',
      national_id: 'NID-ET-994821',
      kebele_id: '04/129/AA',
      employer: 'Commercial Bank of Ethiopia',
      employer_party_id: 801
    }
  },
  {
    id: 942,
    title: 'Solomon Abera',
    subtitle: 'Phone: +251 918 274558',
    raw: {
      phone: '+251 918 274558',
      tin: 'NID-ET-883712',
      national_id: 'NID-ET-883712',
      kebele_id: '02/441/AA',
      employer: 'Ethio Telecom',
      employer_party_id: 802
    }
  },
  {
    id: 943,
    title: 'Solomon Chanyalew',
    subtitle: 'Phone: +251 956 296500',
    raw: {
      phone: '+251 956 296500',
      tin: 'NID-ET-772654',
      national_id: 'NID-ET-772654',
      kebele_id: '09/112/AA',
      employer: 'Awash Bank',
      employer_party_id: 803
    }
  },
  {
    id: 944,
    title: 'Almaz Tadesse',
    subtitle: 'Phone: +251 912 345678',
    raw: {
      phone: '+251 912 345678',
      tin: 'NID-ET-281947',
      national_id: 'NID-ET-281947',
      kebele_id: '01/220/AA',
      employer: 'Ethio Telecom',
      employer_party_id: 802
    }
  },
  {
    id: 945,
    title: 'Dawit Mengistu',
    subtitle: 'Phone: +251 913 456789',
    raw: {
      phone: '+251 913 456789',
      tin: 'NID-ET-192847',
      national_id: 'NID-ET-192847',
      kebele_id: '05/334/AA',
      employer: 'Awash Bank',
      employer_party_id: 803
    }
  },
  {
    id: 946,
    title: 'Bethlehem Haile',
    subtitle: 'Phone: +251 914 567890',
    raw: {
      phone: '+251 914 567890',
      tin: 'NID-ET-661543',
      national_id: 'NID-ET-661543',
      kebele_id: '08/551/AA',
      employer: 'Ethiopian Airlines Group',
      employer_party_id: 804
    }
  },
  {
    id: 947,
    title: 'Yonas Bekele',
    subtitle: 'Phone: +251 915 678901',
    raw: {
      phone: '+251 915 678901',
      tin: 'NID-ET-550432',
      national_id: 'NID-ET-550432',
      fayda_id: 'ET-FAY-82910',
      employer: 'Ministry of Health (Ethiopia)',
      employer_party_id: 805
    }
  }
]);

const employerOrganizationOptions = ref<ComboboxOption[]>([
  {
    id: 801,
    title: 'Commercial Bank of Ethiopia',
    subtitle: 'Phone: +251 11 515 0200',
    raw: { phone: '+251 11 515 0200', sector: 'Banking' }
  },
  {
    id: 802,
    title: 'Ethio Telecom',
    subtitle: 'Phone: +251 11 550 0000',
    raw: { phone: '+251 11 550 0000', sector: 'Telecommunications' }
  },
  {
    id: 803,
    title: 'Awash Bank',
    subtitle: 'Phone: +251 11 557 0001',
    raw: { phone: '+251 11 557 0001', sector: 'Banking' }
  },
  {
    id: 804,
    title: 'Ethiopian Airlines Group',
    subtitle: 'Phone: +251 11 665 2222',
    raw: { phone: '+251 11 665 2222', sector: 'Aviation' }
  },
  {
    id: 805,
    title: 'Ministry of Health (Ethiopia)',
    subtitle: 'Phone: +251 11 551 7011',
    raw: { phone: '+251 11 551 7011', sector: 'Government' }
  },
  {
    id: 806,
    title: 'Dashen Bank',
    subtitle: 'Phone: +251 11 518 0300',
    raw: { phone: '+251 11 518 0300', sector: 'Banking' }
  },
  {
    id: 807,
    title: 'Dangote Industries Ethiopia',
    subtitle: 'Phone: +251 11 661 5000',
    raw: { phone: '+251 11 661 5000', sector: 'Manufacturing' }
  }
]);

const onGuarantorPartySelected = (opt: ComboboxOption) => {
  form.value.guarantor_name = opt.title;
  form.value.guarantor_party_id = typeof opt.id === 'number' ? opt.id : null;
  if (opt.raw) {
    if (opt.raw.phone) form.value.guarantor_phone = opt.raw.phone;
    if (opt.raw.tin) form.value.guarantor_id_number = opt.raw.tin;
    if (opt.raw.employer) {
      form.value.guarantor_employer = opt.raw.employer;
      if (opt.raw.employer_party_id) {
        form.value.guarantor_employer_party_id = opt.raw.employer_party_id;
      }
    }
  }
};

const onGuarantorEmployerSelected = (opt: ComboboxOption) => {
  form.value.guarantor_employer = opt.title;
  form.value.guarantor_employer_party_id = typeof opt.id === 'number' ? opt.id : null;
};

// When job title is set to a role requiring a guarantee, auto-expand the guarantor card
watch(() => form.value.job_title, (newTitle) => {
  const req = positionGuaranteeMap[newTitle];
  if (req && req.required) {
    sections.value.employeeGuarantor = true;
    form.value.has_guarantor = true;
  }
});

// Shift pattern & weekly hours reactive sync
watch(() => form.value.is_working_days_only, (is5Day) => {
  form.value.weekly_hours = is5Day ? '40' : '48';
});

watch(() => form.value.shift_pattern_id, (pattern) => {
  if (pattern === 'PAT-OFF-5D') {
    form.value.is_working_days_only = true;
    form.value.weekly_hours = '40';
  } else if (pattern === 'PAT-RETAIL-6D' || pattern === 'PAT-SHOP-6D') {
    form.value.is_working_days_only = false;
    form.value.weekly_hours = '48';
  }
});

// Calculate planned probation end date from hire date and probation months
watch([() => form.value.hire_date, () => form.value.probation_months], ([hDate, pMonths]) => {
  if (!hDate || !pMonths || Number(pMonths) <= 0) {
    if (Number(pMonths) === 0) form.value.probation_end_date = '';
    return;
  }
  const parts = hDate.split('/');
  if (parts.length === 3) {
    const m = parseInt(parts[0], 10);
    const d = parseInt(parts[1], 10);
    const y = parseInt(parts[2], 10);
    if (!isNaN(m) && !isNaN(d) && !isNaN(y)) {
      const dt = new Date(y, m - 1 + Number(pMonths), d);
      const resM = String(dt.getMonth() + 1).padStart(2, '0');
      const resD = String(dt.getDate()).padStart(2, '0');
      const resY = dt.getFullYear();
      form.value.probation_end_date = `${resM}/${resD}/${resY}`;
    }
  }
});

// Media Handlers
const triggerFileInput = () => fileInput.value?.click();
const triggerSigInput = () => sigFileInput.value?.click();
const triggerGuaranteeInput = () => guaranteeFileInput.value?.click();
const triggerMedicalInput = () => medicalFileInput.value?.click();

const onFileSelected = (event: Event) => {
  const target = event.target as HTMLInputElement;
  if (target.files && target.files[0]) {
    const reader = new FileReader();
    reader.onload = (e) => {
      form.value.avatar = e.target?.result as string;
    };
    reader.readAsDataURL(target.files[0]);
  }
};

const onSigSelected = (event: Event) => {
  const target = event.target as HTMLInputElement;
  if (target.files && target.files[0]) {
    const reader = new FileReader();
    reader.onload = (e) => {
      form.value.signature = e.target?.result as string;
    };
    reader.readAsDataURL(target.files[0]);
  }
};

// ─── Dual-Mode Signature Canvas System ───
const signatureMode = ref<'upload' | 'draw'>('upload');
const signatureCanvas = ref<HTMLCanvasElement | null>(null);
const isDrawing = ref(false);
const hasDrawn = ref(false);

const startDrawing = (e: MouseEvent | TouchEvent) => {
  const canvas = signatureCanvas.value;
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  if (!ctx) return;
  isDrawing.value = true;
  hasDrawn.value = true;
  const rect = canvas.getBoundingClientRect();
  const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
  const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
  ctx.beginPath();
  ctx.moveTo(clientX - rect.left, clientY - rect.top);
};

const draw = (e: MouseEvent | TouchEvent) => {
  if (!isDrawing.value) return;
  const canvas = signatureCanvas.value;
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  if (!ctx) return;
  const rect = canvas.getBoundingClientRect();
  const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
  const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
  ctx.lineTo(clientX - rect.left, clientY - rect.top);
  ctx.strokeStyle = '#0f172a';
  ctx.lineWidth = 2.5;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  ctx.stroke();
  if ('touches' in e) e.preventDefault();
};

const stopDrawing = () => {
  isDrawing.value = false;
};

const clearSignatureCanvas = () => {
  const canvas = signatureCanvas.value;
  if (canvas) {
    const ctx = canvas.getContext('2d');
    if (ctx) ctx.clearRect(0, 0, canvas.width, canvas.height);
  }
  hasDrawn.value = false;
  form.value.signature = '';
};

const adoptDrawnSignature = () => {
  const canvas = signatureCanvas.value;
  if (!canvas) return;
  form.value.signature = canvas.toDataURL('image/png');
};

// ─── Dynamic Employment Type Logic & Watchers ───
const isPermanentEmployment = computed(() => {
  const t = (form.value.employment_type || '').toLowerCase();
  return t.includes('permanent') || t.includes('indefinite');
});

const isInternOrConsultant = computed(() => {
  const t = (form.value.employment_type || '').toLowerCase();
  return t.includes('intern') || t.includes('consultant');
});

const isPartTimeEmployment = computed(() => {
  const t = (form.value.employment_type || '').toLowerCase();
  return t.includes('part-time') || t.includes('part_time');
});

watch(() => form.value.employment_type, (newType) => {
  if (!newType) return;
  const val = newType.toLowerCase();
  if (val.includes('permanent') || val.includes('indefinite')) {
    form.value.contract_type = 'Indefinite Duration (Permanent)';
    form.value.end_date = '';
    form.value.probation_months = '2';
    form.value.weekly_hours = '40';
    form.value.notice_period_days = '30';
  } else if (val.includes('intern')) {
    form.value.contract_type = 'Fixed-Term / Internship Agreement';
    form.value.probation_months = '0';
    form.value.probation_end_date = '';
    form.value.weekly_hours = '30';
    form.value.notice_period_days = '7';
  } else if (val.includes('consultant')) {
    form.value.contract_type = 'Service Agreement / Independent Consultant';
    form.value.probation_months = '0';
    form.value.probation_end_date = '';
    form.value.weekly_hours = '20';
    form.value.notice_period_days = '15';
  } else if (val.includes('part-time') || val.includes('part_time')) {
    form.value.weekly_hours = '20';
    form.value.notice_period_days = '15';
  } else if (val.includes('fixed-term') || val.includes('contract') || val.includes('temporary')) {
    form.value.contract_type = 'Fixed-Term (Definite Period)';
    form.value.probation_months = '1';
    form.value.weekly_hours = '40';
    form.value.notice_period_days = '30';
  }
});

const onGuaranteeSelected = (event: Event) => {
  const target = event.target as HTMLInputElement;
  if (target.files && target.files[0]) {
    const reader = new FileReader();
    reader.onload = (e) => {
      form.value.guarantee_attachment = e.target?.result as string;
    };
    reader.readAsDataURL(target.files[0]);
  }
};

const onMedicalCertSelected = (event: Event) => {
  const target = event.target as HTMLInputElement;
  if (target.files && target.files[0]) {
    const reader = new FileReader();
    reader.onload = (e) => {
      form.value.medical_cert_attachment = e.target?.result as string;
    };
    reader.readAsDataURL(target.files[0]);
  }
};

// Fayda Verification Simulation
const verifyFayda = () => {
  if (!form.value.fayda_id) return;
  isVerifying.value = true;
  setTimeout(() => {
    isVerifying.value = false;
    isIdVerified.value = true;
  }, 600);
};

// Global Clear Form
const clearForm = () => {
  form.value = {
    avatar: '',
    signature: '',
    fayda_id: '',
    first_name: '',
    middle_name: '',
    last_name: '',
    phone: '',
    personal_email: '',
    work_email: '',
    gender: '',
    birth_date: '',
    birth_place: '',
    marital_status: '',
    blood_group: '',
    nationality_country: '',
    nationality_type: '',
    address_type: 'Residence / Primary Home',
    address_country: 'Ethiopia',
    residence_region: '',
    residence_subcity: '',
    residence_woreda: '',
    residence_kebele: '',
    residence_house_number: '',
    residence_line: '',
    residence_postal_code: '',
    address_effective_from: '',
    address_effective_to: '',
    entity_id: '',
    department_name: '',
    job_title: '',
    work_location: '',
    reports_to: '',
    employment_type: '',
    contract_type: '',
    hire_date: '',
    end_date: '',
    shift_pattern_id: 'PAT-OFF-5D',
    is_working_days_only: true,
    weekly_hours: '40',
    probation_months: '2',
    probation_end_date: '',
    notice_period_days: '30',
    tin: '',
    pension_number: '',
    notes: '',
    job_grade: 'Grade B2',
    job_grade_step: 'Step 1 (Entry)',
    salary_structure: '',
    basic_amount: '',
    currency: 'ETB',
    payroll_group: 'Standard Monthly Payroll',
    salary_effective_date: '',
    transport_allowance: '',
    housing_allowance: '',
    compensation_supervisor: '',
    bank_name: '',
    branch_name: '',
    account_number: '',
    account_holder_name: '',
    has_secondary_bank: false,
    primary_split_percent: 80,
    secondary_bank_name: '',
    secondary_account_number: '',
    secondary_account_holder_name: '',
    secondary_branch_name: '',
    has_guarantor: false,
    guarantor_party_id: null,
    guarantor_name: '',
    guarantor_phone: '',
    guarantor_id_number: '',
    guarantor_relation: '',
    guarantee_purpose: '',
    guaranteed_amount: '',
    guarantor_employer_party_id: null,
    guarantor_employer: '',
    guarantor_monthly_income: '',
    guarantee_letter_ref_no: '',
    letter_argument_date: '',
    coverage_start_date: '',
    coverage_end_date: '',
    guarantee_attachment: '',
    has_accessibility: false,
    disability_category: '',
    disability_severity: '',
    is_self_declared: false,
    affects_work_capacity: false,
    is_confidential: true,
    is_verified: false,
    medical_certificate_ref: '',
    accommodation_notes: ''
  };
  isIdVerified.value = false;
  addressesList.value = [];
  academicQualifications.value = [];
  professionalCertifications.value = [];
  priorWorkExperiences.value = [];
  technicalSkills.value = [];
  spokenLanguages.value = [];
  regulatoryClearances.value = [];
  emergencyContactsList.value = [];
  dependentsList.value = [];
  statutoryExemptionsList.value = [];
  bankAccountsList.value = [];
  salaryComponentsList.value = [];
  sections.value.regulatoryClearances = true;
  sections.value.employeeGuarantor = false;
  sections.value.workplaceAccessibility = false;
};

const handleSave = () => {
  isSaved.value = true;
  setTimeout(() => {
    router.push('/hr/employees');
  }, 400);
};

onMounted(() => {
  if (route.query.name) {
    const parts = String(route.query.name).trim().split(' ');
    form.value.first_name = parts[0] || '';
    form.value.middle_name = parts[1] || '';
    form.value.last_name = parts.slice(2).join(' ') || '';
  }
  if (route.query.email) form.value.work_email = String(route.query.email);
  if (route.query.phone) form.value.phone = String(route.query.phone);
  if (route.query.title) form.value.job_title = String(route.query.title);
  if (route.query.type) form.value.employment_type = String(route.query.type);
});
</script>

<template>
  <div class="employee-create-page">
    <!-- Top Action & Breadcrumb Navigation Bar -->
    <div class="create-header-bar">
      <div class="header-left">
        <div class="breadcrumb-strip">
          <router-link to="/home" class="bc-home-icon" title="Home">
            <Monitor :size="15" />
          </router-link>
          <ChevronRight :size="13" class="bc-sep" />
          <router-link to="/hr/employees" class="bc-link">Employee Directory</router-link>
          <ChevronRight :size="13" class="bc-sep" />
          <span class="bc-current">Create Employee</span>
          <span :class="['state-pill', isSaved ? 'state-saved' : 'state-unsaved']">
            {{ isSaved ? 'Saved' : 'Not Saved' }}
          </span>
        </div>
      </div>

      <div class="header-actions">
        <button type="button" class="btn-clear-action" @click="clearForm">
          <X :size="14" />
          <span>Clear Form</span>
        </button>
        <button type="button" class="btn-save-action" @click="handleSave">
          <span>Save</span>
        </button>
      </div>
    </div>

    <!-- Capsule / Pill Tabs Navigation Standard (BaseTabs) -->
    <div class="create-tabs-wrapper">
      <BaseTabs 
        v-model="activeTab"
        :tabs="tabs"
        size="md"
      />
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 1: PERSONAL                                               -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'personal'" class="tab-content-container">
      <!-- Master Party Card (Always Open) -->
      <div class="clean-card master-party-card">
        <!-- Avatar Section -->
        <div class="avatar-photo-row">
          <div class="avatar-circle-box">
            <img v-if="form.avatar" :src="form.avatar" class="avatar-circle-img" alt="Photo" />
            <div v-else class="no-media-content">
              <ImageIcon :size="26" class="no-media-icon" />
              <span class="no-media-text">No Media</span>
            </div>
          </div>
          <div class="avatar-meta-col">
            <input ref="fileInput" type="file" accept="image/*" class="hidden-file-input" @change="onFileSelected" />
            <button type="button" class="btn-upload-photo" @click="triggerFileInput">
              Upload New Photo
            </button>
            <span class="avatar-advice-text">
              At least 800×800 px recommended and size should be less than 10MB. JPG or PNG is allowed
            </span>
          </div>
        </div>

        <!-- National ID Verification Row -->
        <div class="national-id-row">
          <label class="field-label">National ID</label>
          <div class="national-id-input-group">
            <div class="id-input-wrap">
              <input 
                type="text" 
                v-model="form.fayda_id" 
                class="standard-text-input" 
                @input="isIdVerified = false"
              />
            </div>
            <button 
              type="button" 
              class="btn-verify-id" 
              :disabled="!form.fayda_id || isVerifying"
              @click="verifyFayda"
            >
              <Loader2 v-if="isVerifying" :size="14" class="animate-spin" />
              <span v-else>{{ isIdVerified ? 'Verified' : 'Verify ID' }}</span>
            </button>
          </div>
          <p v-if="isIdVerified" class="id-verified-subtext">
            ID Verified Successfully.
          </p>
        </div>

        <!-- Employee Information Subtitle -->
        <div class="section-subtitle">Employee Information</div>

        <!-- Full Name 3-Column Grid -->
        <div class="form-grid-3">
          <FormInput label="First Name" v-model="form.first_name" required />
          <FormInput label="Middle Name" v-model="form.middle_name" />
          <FormInput label="Last Name" v-model="form.last_name" />
        </div>

        <!-- Contact Channels 3-Column Grid -->
        <div class="form-grid-3 mt-4">
          <!-- Phone Input Group -->
          <div class="form-field-wrap">
            <label class="field-label">Phone Number <span class="required-asterisk">*</span></label>
            <div class="phone-composite-input">
              <div class="country-pill-btn">
                <span>ET</span>
                <ChevronDown :size="12" class="text-neutral-500" />
              </div>
              <input 
                type="tel" 
                v-model="form.phone" 
                class="phone-field-inner"
              />
            </div>
          </div>

          <FormInput label="Personal Email" type="email" v-model="form.personal_email" />
          <FormInput label="Work Email" type="email" v-model="form.work_email" />
        </div>

        <!-- Gender, DOB, Marital Status, Blood Group 4-Column Grid -->
        <div class="form-grid-4 mt-4">
          <FormSelect 
            label="Gender" 
            v-model="form.gender" 
            :options="['Female', 'Male']" 
            placeholder="Select" 
            required 
          />

          <!-- Date of Birth with Calendar Icon & GC Badge -->
          <div class="form-field-wrap">
            <label class="field-label">Date of Birth <span class="required-asterisk">*</span></label>
            <div class="date-composite-input">
              <Calendar :size="15" class="date-cal-icon" />
              <input 
                type="text" 
                v-model="form.birth_date" 
                class="date-field-inner"
              />
              <span class="gc-badge">GC</span>
            </div>
          </div>

          <FormSelect 
            label="Marital Status" 
            v-model="form.marital_status" 
            :options="['Single', 'Married', 'Divorced', 'Widowed']" 
            placeholder="Select" 
          />

          <FormSelect 
            label="Blood Group" 
            v-model="form.blood_group" 
            :options="['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown']" 
            placeholder="Select" 
          />
        </div>
      </div>

      <!-- Accordion Card 2: Demographics & Citizenship -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('demographics')">
          <span>Demographics & Citizenship</span>
          <ChevronDown v-if="sections.demographics" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.demographics" class="card-accordion-divider" />
        <div v-if="sections.demographics" class="card-accordion-body">
          <div class="form-grid-3">
            <FormInput label="Place of Birth" v-model="form.birth_place" />
            <FormSelect 
              label="Nationality Country" 
              v-model="form.nationality_country" 
              :options="['Ethiopia', 'Kenya', 'Uganda', 'United States', 'United Kingdom', 'Other']" 
              placeholder="Select" 
              helper-text="Determines right-to-work eligibility and applicable tax treaties."
            />
            <FormSelect 
              label="Nationality Type" 
              v-model="form.nationality_type" 
              :options="['Citizen', 'Resident Foreigner', 'Non-Resident Foreigner', 'Dual Citizen']" 
              placeholder="Select" 
            />
          </div>
        </div>
      </div>

      <!-- Accordion Card 3: Address (Matching User Settled Design) -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('residenceAddress')">
          <span>Address</span>
          <ChevronDown v-if="sections.residenceAddress" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.residenceAddress" class="card-accordion-divider" />
        <div v-if="sections.residenceAddress" class="card-accordion-body address-section-body">
          <!-- Stack of Address Cards -->
          <div class="address-cards-stack">
            <div 
              v-for="(row, idx) in addressesList" 
              :key="row.id" 
              class="address-item-card"
            >
              <!-- Card Header: Pill Badge & Delete Icon -->
              <div class="address-card-header">
                <span class="address-card-badge">Address {{ idx + 1 }}</span>
                <button 
                  type="button" 
                  class="btn-delete-address-card" 
                  @click="removeAddressItem(idx)" 
                  title="Remove Address"
                >
                  <Trash2 :size="16" />
                </button>
              </div>

              <!-- Grid Row 1: Address Type | Country | Region -->
              <div class="address-form-grid">
                <div class="address-form-group">
                  <label class="address-field-label">Address Type</label>
                  <select v-model="row.address_type" class="address-field-select">
                    <option value="" disabled>Select Type</option>
                    <option value="residence">Residence / Primary Home</option>
                    <option value="postal">Postal Address</option>
                    <option value="work">Work Location</option>
                    <option value="emergency">Emergency Domicile</option>
                    <option value="birth_place">Place of Birth</option>
                    <option value="other">Other Domicile</option>
                  </select>
                </div>

                <div class="address-form-group">
                  <label class="address-field-label">Country</label>
                  <select v-model="row.country" class="address-field-select" @change="onRowCountryChange(row)">
                    <option value="" disabled>Select Country</option>
                    <option value="Ethiopia">Ethiopia</option>
                    <option value="Kenya">Kenya</option>
                    <option value="Djibouti">Djibouti</option>
                    <option value="United States">United States</option>
                    <option value="United Kingdom">United Kingdom</option>
                  </select>
                </div>

                <div class="address-form-group">
                  <label class="address-field-label">Region</label>
                  <select v-model="row.region" class="address-field-select" @change="onRowRegionChange(row)">
                    <option value="" disabled>Select Region</option>
                    <option v-for="r in getRegionsForRow(row)" :key="r" :value="r">{{ r }}</option>
                  </select>
                </div>
              </div>

              <!-- Grid Row 2: Zone | Woreda | Kebele -->
              <div class="address-form-grid">
                <div class="address-form-group">
                  <label class="address-field-label">Zone</label>
                  <select v-model="row.subcity_zone" class="address-field-select" @change="onRowZoneChange(row)">
                    <option value="" disabled>Select Zone</option>
                    <option v-for="z in getZonesForRow(row)" :key="z" :value="z">{{ z }}</option>
                  </select>
                </div>

                <div class="address-form-group">
                  <label class="address-field-label">Woreda</label>
                  <select v-model="row.woreda" class="address-field-select" @change="onRowWoredaChange(row)">
                    <option value="" disabled>Select Woreda</option>
                    <option v-for="w in getWoredasForRow(row)" :key="w" :value="w">{{ w }}</option>
                  </select>
                </div>

                <div class="address-form-group">
                  <label class="address-field-label">Kebele</label>
                  <select v-model="row.kebele" class="address-field-select" @change="onRowKebeleChange(row)">
                    <option value="" disabled>Select Kebele</option>
                    <option v-for="k in getKebelesForRow(row)" :key="k" :value="k">{{ k }}</option>
                  </select>
                </div>
              </div>

              <!-- Grid Row 3: House Number | Street | Postal Code / P.O. Box -->
              <div class="address-form-grid">
                <div class="address-form-group">
                  <label class="address-field-label">House Number</label>
                  <input type="text" v-model="row.house_number" class="address-field-input" />
                  <p class="address-field-hint">Used for legal address records and official correspondence.</p>
                </div>

                <div class="address-form-group">
                  <label class="address-field-label">Street</label>
                  <input type="text" v-model="row.line" class="address-field-input" />
                </div>

                <div class="address-form-group">
                  <label class="address-field-label">Postal Code / P.O. Box</label>
                  <input type="text" v-model="row.postal_code" class="address-field-input" />
                </div>
              </div>

              <!-- Row 4: Primary Address Checkbox -->
              <div class="address-primary-row">
                <FormCheckbox 
                  :id="'address_primary_' + row.id"
                  v-model="row.is_primary"
                  label="Primary Address"
                  description="Designates this record as the employee's official primary residence for statutory tax remittance, administrative notices, and emergency routing."
                  @change="setPrimaryAddress(idx)"
                />
              </div>
            </div>
          </div>

          <!-- Empty State -->
          <div v-if="addressesList.length === 0" class="address-empty-state">
            <p class="text-sm text-slate-500">No address configured. Click below to add an address record.</p>
          </div>

          <!-- Add Address Action Button -->
          <button type="button" class="btn-add-address-card" @click="addAddressItem">
            <Plus :size="15" />
            <span>Add Address</span>
          </button>
        </div>
      </div>

      <!-- Accordion Card 4: Signature & Remarks -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('remarksSignature')">
          <span>Signature & Remarks</span>
          <ChevronDown v-if="sections.remarksSignature" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.remarksSignature" class="card-accordion-divider" />
        <div v-if="sections.remarksSignature" class="card-accordion-body">
          <div class="scanned-sig-wrapper">
            <div class="flex items-center justify-between mb-2">
              <label class="field-label mb-0">Legal Specimen Signature</label>
              <div class="sig-mode-switch">
                <button 
                  type="button" 
                  class="sig-tab-btn" 
                  :class="{ 'active': signatureMode === 'upload' }"
                  @click="signatureMode = 'upload'"
                >
                  <Upload :size="13" />
                  <span>Upload Specimen</span>
                </button>
                <button 
                  type="button" 
                  class="sig-tab-btn" 
                  :class="{ 'active': signatureMode === 'draw' }"
                  @click="signatureMode = 'draw'"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/>
                    <path d="m15 5 4 4"/>
                  </svg>
                  <span>Draw Digital Signature</span>
                </button>
              </div>
            </div>

            <!-- Mode 1: Upload File -->
            <div v-if="signatureMode === 'upload'">
              <input ref="sigFileInput" type="file" accept="image/*" class="hidden-file-input" @change="onSigSelected" />
              <div class="scanned-sig-dropzone" @click="triggerSigInput">
                <div v-if="form.signature" class="sig-preview-content">
                  <img :src="form.signature" class="sig-preview-img" alt="Scanned signature" />
                  <span class="sig-replace-link">Click to replace signature</span>
                </div>
                <div v-else class="sig-empty-content">
                  <Upload :size="18" class="sig-upload-icon" />
                  <div class="sig-upload-text">
                    <span class="text-blue-600 font-medium">Click to upload</span> or drag and drop
                  </div>
                  <div class="sig-upload-subtext">Picture files up to 10MB</div>
                </div>
              </div>
            </div>

            <!-- Mode 2: Draw on Canvas -->
            <div v-else class="sig-draw-container">
              <div v-if="form.signature && !isDrawing && !hasDrawn" class="sig-adopted-box">
                <div class="flex items-center justify-between p-2.5 bg-emerald-50 border border-emerald-200 rounded-md mb-2">
                  <div class="flex items-center gap-2 text-xs font-semibold text-emerald-800">
                    <Check :size="14" class="text-emerald-600" />
                    <span>Digital Signature Adopted & Stored</span>
                  </div>
                  <button type="button" class="text-xs text-rose-600 hover:underline font-medium" @click="clearSignatureCanvas">
                    Redraw / Clear
                  </button>
                </div>
                <div class="p-3 bg-white border border-slate-200 rounded-md flex justify-center items-center h-28">
                  <img :src="form.signature" class="max-h-24 max-w-full object-contain" alt="Adopted Digital Signature" />
                </div>
              </div>

              <div v-else>
                <div class="sig-canvas-header mb-1 flex items-center justify-between text-xs text-slate-500">
                  <span>Sign within the box below using mouse or stylus:</span>
                  <button 
                    type="button" 
                    class="text-xs text-slate-500 hover:text-slate-700 underline" 
                    @click="clearSignatureCanvas"
                  >
                    Clear Canvas
                  </button>
                </div>
                <div class="sig-canvas-wrapper">
                  <canvas 
                    ref="signatureCanvas" 
                    width="500" 
                    height="130" 
                    class="sig-canvas"
                    @mousedown="startDrawing"
                    @mousemove="draw"
                    @mouseup="stopDrawing"
                    @mouseleave="stopDrawing"
                    @touchstart="startDrawing"
                    @touchmove="draw"
                    @touchend="stopDrawing"
                  ></canvas>
                </div>
                <div class="flex items-center justify-between mt-2">
                  <span class="text-[11px] text-slate-400">Merged onto payslips, contracts, and letters.</span>
                  <div class="flex items-center gap-2">
                    <button 
                      type="button" 
                      class="btn-secondary-sm" 
                      @click="clearSignatureCanvas"
                    >
                      Clear
                    </button>
                    <button 
                      type="button" 
                      class="btn-adopt-sig" 
                      @click="adoptDrawnSignature"
                    >
                      <Check :size="13" />
                      <span>Adopt Signature</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="remark-editor-wrapper mt-4">
            <label class="field-label">Remark</label>
            <div class="wysiwyg-editor-box">
              <div class="wysiwyg-toolbar">
                <select class="toolbar-select">
                  <option>Paragraph</option>
                  <option>Heading 1</option>
                  <option>Heading 2</option>
                </select>
                <select class="toolbar-select">
                  <option>Font Type</option>
                  <option>Sans Serif</option>
                  <option>Monospace</option>
                </select>
                <span class="toolbar-divider" />
                <button type="button" class="tb-btn" title="Bullet List"><List :size="14" /></button>
                <button type="button" class="tb-btn" title="Numbered List"><ListOrdered :size="14" /></button>
                <span class="toolbar-divider" />
                <button type="button" class="tb-btn font-bold" title="Bold">B</button>
                <button type="button" class="tb-btn italic font-serif" title="Italic">I</button>
                <button type="button" class="tb-btn underline" title="Underline">U</button>
                <button type="button" class="tb-btn line-through" title="Strikethrough">S</button>
                <button type="button" class="tb-btn" title="Code">&lt;&gt;</button>
                <button type="button" class="tb-btn" title="Table"><Table :size="14" /></button>
                <span class="toolbar-divider" />
                <button type="button" class="tb-btn" title="Color"><Square :size="14" class="fill-current text-neutral-800" /></button>
                <button type="button" class="tb-btn" title="Link"><Link :size="14" /></button>
                <button type="button" class="tb-btn" title="Image"><ImageIcon :size="14" /></button>
                <div class="toolbar-spacer" />
                <button type="button" class="tb-btn" title="Undo"><Undo2 :size="14" /></button>
                <button type="button" class="tb-btn" title="Redo"><Redo2 :size="14" /></button>
              </div>
              <textarea 
                v-model="form.notes" 
                class="wysiwyg-textarea"
                maxlength="5000"
              />
              <div class="wysiwyg-status-bar">
                <span class="char-count">{{ (form.notes || '').length }} / 5,000 Characters</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Card 5: Disability & Accommodations -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('workplaceAccessibility')">
          <span>Disability & Accommodations</span>
          <ChevronDown v-if="sections.workplaceAccessibility" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.workplaceAccessibility" class="card-accordion-divider" />
        <div v-if="sections.workplaceAccessibility" class="card-accordion-body">
          <p class="child-sub-desc mb-4">Record employee disability classifications, medical board verification, and approved workplace accommodations.</p>

          <!-- Row 1 (3 cols) -->
          <div class="form-grid-3">
            <FormSelect 
              label="Disability Category" 
              v-model="form.disability_category" 
              :options="['Physical Impairment', 'Visual Impairment', 'Hearing Impairment', 'Speech Impairment', 'Intellectual Impairment', 'Psychosocial Condition', 'Multiple Impairments', 'Other Impairment']" 
               
              helper-text="Primary impairment category that guides ergonomic, software, and facility accessibility adjustments."
            />
            <FormSelect 
              label="Severity Level" 
              v-model="form.disability_severity" 
              :options="['Mild Impairment', 'Moderate Impairment', 'Severe Impairment']" 
               
              helper-text="Operational classification for adaptive workplace provisions."
            />
            <FormInput 
              label="Medical Board / MOLS Certificate Ref" 
              v-model="form.medical_certificate_ref" 
              helper-text="Official document identifier issued by the certifying clinical provider or medical authority."
            />
          </div>

          <!-- Row 2: Statutory & Medical Certification Flags -->
          <div class="form-grid-2 mt-4 pt-1">
            <FormCheckbox 
              id="isSelfDeclared"
              v-model="form.is_self_declared" 
              label="Self-Declared Condition"
              description="Indicates the condition was declared directly by the employee rather than certified by an accredited medical board."
            />
            <FormCheckbox 
              id="affectsWorkCapacity"
              v-model="form.affects_work_capacity" 
              label="Affects Daily Work Capacity"
              description="Determines whether core duties, heavy physical tasks, or shift schedules require operational adaptation."
            />
            <FormCheckbox 
              id="isConfidential"
              v-model="form.is_confidential" 
              label="Confidential Medical Record"
              description="Restricts record visibility strictly to authorized HR medical officers to protect diagnostic privacy."
            />
            <FormCheckbox 
              id="isVerified"
              v-model="form.is_verified" 
              label="Medically Verified by HR"
              description="Confirms HR compliance has inspected and authenticated the official hospital medical board or MOLS certificate."
            />
          </div>

          <!-- Row 3: Approved Workplace Accommodations / Assistive Tools -->
          <div class="remark-editor-wrapper mt-4">
            <label class="field-label">Approved Workplace Accommodations / Assistive Tools</label>
            <div class="wysiwyg-editor-box">
              <div class="wysiwyg-toolbar">
                <select class="toolbar-select">
                  <option>Paragraph</option>
                  <option>Heading 1</option>
                  <option>Heading 2</option>
                </select>
                <select class="toolbar-select">
                  <option>Font Type</option>
                  <option>Sans Serif</option>
                  <option>Monospace</option>
                </select>
                <span class="toolbar-divider" />
                <button type="button" class="tb-btn" title="Bullet List"><List :size="14" /></button>
                <button type="button" class="tb-btn" title="Numbered List"><ListOrdered :size="14" /></button>
                <span class="toolbar-divider" />
                <button type="button" class="tb-btn font-bold" title="Bold">B</button>
                <button type="button" class="tb-btn italic font-serif" title="Italic">I</button>
                <button type="button" class="tb-btn underline" title="Underline">U</button>
                <button type="button" class="tb-btn line-through" title="Strikethrough">S</button>
                <button type="button" class="tb-btn" title="Code">&lt;&gt;</button>
                <button type="button" class="tb-btn" title="Table"><Table :size="14" /></button>
                <span class="toolbar-divider" />
                <button type="button" class="tb-btn" title="Color"><Square :size="14" class="fill-current text-neutral-800" /></button>
                <button type="button" class="tb-btn" title="Link"><Link :size="14" /></button>
                <button type="button" class="tb-btn" title="Image"><ImageIcon :size="14" /></button>
                <div class="toolbar-spacer" />
                <button type="button" class="tb-btn" title="Undo"><Undo2 :size="14" /></button>
                <button type="button" class="tb-btn" title="Redo"><Redo2 :size="14" /></button>
              </div>
              <textarea 
                v-model="form.accommodation_notes" 
                class="wysiwyg-textarea"
                maxlength="5000"
              />
              <div class="wysiwyg-status-bar">
                <span class="char-count">{{ (form.accommodation_notes || '').length }} / 5,000 Characters</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 2: EMPLOYMENT                                             -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'job'" class="tab-content-container">
      <!-- Accordion Card 1: Organizational Placement -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('orgPlacement')">
          <span>Organizational Placement</span>
          <ChevronDown v-if="sections.orgPlacement" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.orgPlacement" class="card-accordion-divider" />
        <div v-if="sections.orgPlacement" class="card-accordion-body">
          <div class="form-grid-3">
            <FormSelect 
              label="Employee Entity" 
              v-model="form.entity_id" 
              :options="['Haleta Addis Ababa HQ', 'Haleta Hawassa Branch', 'Haleta Bahir Dar Factory', 'Haleta Dire Dawa Outlet']" 
               
              helper-text="The contracting legal entity that controls cost center allocation, labor policies, and payroll jurisdiction."
            />
            <FormSelect 
              label="Assigned Department" 
              v-model="form.department_name" 
              :options="['Finance & Accounts', 'Human Resources', 'Treasury', 'Supply Chain & Logistics', 'Operations & Processing', 'Engineering & IT']" 
               
            />
            <FormSelect 
              label="Job Position" 
              v-model="form.job_title" 
              :options="['Junior Auditor', 'Financial Accountant', 'Chief Accountant', 'Treasury Officer', 'HR Officer', 'Senior HR Specialist', 'Procurement Officer', 'Supply Chain Analyst', 'Operations Supervisor', 'Senior Cashier', 'Software Engineer']" 
               
            />
          </div>

          <div class="card-row-divider" />

          <div class="form-grid-2">
            <FormSelect 
              label="Work Location / Branch" 
              v-model="form.work_location" 
              :options="['Addis Ababa - Main Campus', 'Bole Branch Office', 'Hawassa Industrial Park', 'Bahir Dar Plant', 'Dire Dawa Hub']" 
               
            />
            <FormSelect 
              label="Direct Supervisor" 
              v-model="form.reports_to" 
              :options="['Selamawit Bekele (Head of HR)', 'Abebe Kebede (Finance Director)', 'Dawit Alemu (Operations Manager)', 'Meron Tadesse (Senior HR Specialist)']" 
               
              helper-text="Direct line manager responsible for attendance, leave approvals, and appraisals."
            />
          </div>
        </div>
      </div>

      <!-- Accordion Card 2: Contract & Working Hours -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('contractDetails')">
          <span>Contract & Working Hours</span>
          <ChevronDown v-if="sections.contractDetails" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.contractDetails" class="card-accordion-divider" />
        <div v-if="sections.contractDetails" class="card-accordion-body">
          <!-- Contextual Employment Type Guidance Banner -->
          <div v-if="form.employment_type" class="mb-4 p-3 bg-slate-50 border border-slate-200 rounded-lg flex items-start gap-2.5 text-xs text-slate-700">
            <Info :size="15" class="text-blue-600 shrink-0 mt-0.5" />
            <div>
              <span v-if="isPermanentEmployment">
                <strong>Permanent Staff:</strong> Indefinite tenure under Ethiopian Labour Proclamation. Mandatory POESSA social security pension (7% employee / 11% employer). Probation evaluation is up to 90 days.
              </span>
              <span v-else-if="form.employment_type.includes('Contract') || form.employment_type.includes('Temporary')">
                <strong>Fixed-Term Engagement:</strong> Definite duration engagement. Requires explicit contract expiration date and milestone/renewal terms.
              </span>
              <span v-else-if="form.employment_type.includes('Intern')">
                <strong>Student Internship:</strong> Practical education training agreement. Exempt from POESSA social security pension; probation trial is not applicable.
              </span>
              <span v-else-if="form.employment_type.includes('Consultant')">
                <strong>Professional Consultancy:</strong> Independent retainer agreement. Subject to 2% withholding tax; exempt from social security pension.
              </span>
              <span v-else-if="isPartTimeEmployment">
                <strong>Part-Time Staff:</strong> Reduced working schedule. Weekly working hours determine pro-rata benefits and statutory eligibility.
              </span>
            </div>
          </div>

          <div class="form-grid-2">
            <FormSelect 
              label="Employment Type" 
              v-model="form.employment_type" 
              :options="[
                'Permanent / Indefinite',
                'Fixed-Term Contract',
                'Temporary / Daily Labor',
                'Student Intern',
                'Professional Consultant',
                'Part-Time Staff'
              ]" 
               
            />
            <FormSelect 
              label="Legal Contract Type" 
              v-model="form.contract_type" 
              :options="[
                'Indefinite Duration (Permanent)',
                'Fixed-Term (Definite Period)',
                'Fixed-Term / Internship Agreement',
                'Service Agreement / Independent Consultant',
                'Project-Based',
                'Casual / Daily Labor'
              ]" 
               
              helper-text="Contractual engagement type that governs notice periods, severance entitlements, and renewal obligations."
            />
          </div>

          <div class="form-grid-4 mt-4">
            <div class="form-field-wrap">
              <label class="field-label">Contract Start Date</label>
              <div class="date-composite-input">
                <Calendar :size="15" class="date-cal-icon" />
                <input 
                  type="date" 
                  v-model="form.hire_date" 
                  class="date-field-inner"
                />
                <span class="gc-badge">GC</span>
              </div>
            </div>

            <div class="form-field-wrap">
              <label class="field-label">
                Contract Expiration Date 
                <span v-if="!isPermanentEmployment" class="text-rose-500">*</span>
              </label>
              <div v-if="isPermanentEmployment" class="date-composite-disabled">
                <span class="text-xs text-slate-500 font-medium">Indefinite Duration (N/A)</span>
              </div>
              <div v-else class="date-composite-input">
                <Calendar :size="15" class="date-cal-icon" />
                <input 
                  type="date" 
                  v-model="form.end_date" 
                  class="date-field-inner"
                />
                <span class="gc-badge">GC</span>
              </div>
            </div>

            <FormSelect 
              label="Assigned Shift" 
              v-model="form.shift_pattern_id" 
              :options="[
                'PAT-OFF-5D (Office Mon-Fri 08:30-17:30)',
                'PAT-RETAIL-6D (Retail 6-Day Rota)',
                'PAT-2M2E2O (Plant 2-Morn / 2-Eve / 2-Off)',
                'PAT-GUARD-4C (Security Guard 4-Day Cycle)',
                'PAT-SHOP-6D (Commercial Outlet 6-Day)'
              ]" 
               
            />

            <FormInput 
              label="Weekly Hour" 
              type="number" 
              v-model="form.weekly_hours" 
              :helper-text="isPartTimeEmployment ? 'Part-time schedule (typical 20-30 hrs)' : undefined"
            />
          </div>

          <div v-if="!isInternOrConsultant" class="form-grid-3 mt-4">
            <FormInput 
              label="Probation Period (Month)" 
              type="number" 
              v-model="form.probation_months" 
              helper-text="Defined trial period for performance evaluation before full employment confirmation."
            />
            <div class="form-field-wrap">
              <label class="field-label">Planned Probation End Date</label>
              <div class="date-composite-input">
                <Calendar :size="15" class="date-cal-icon" />
                <input 
                  type="date" 
                  v-model="form.probation_end_date" 
                  class="date-field-inner"
                  readonly
                />
                <span class="gc-badge">GC</span>
              </div>
            </div>
            <FormInput 
              label="Notice Period (Days)" 
              type="number" 
              v-model="form.notice_period_days" 
            />
          </div>
          <div v-else class="p-3 bg-slate-50 border border-slate-200 rounded-md text-xs text-slate-500 mt-4 flex items-center gap-2">
            <Info :size="14" class="text-slate-400 shrink-0" />
            <span>Probation trial evaluation is not applicable for {{ form.employment_type || 'this employment type' }}.</span>
          </div>

          <!-- Working Days Only Standalone Checkbox -->
          <div class="mt-4">
            <FormCheckbox 
              id="isWorkingDaysOnly"
              v-model="form.is_working_days_only" 
              label="Working Days Only"
              description="Enable this if employment follows a 5-day workweek where Saturday is a non-working rest day. Disable for a standard 6-day workweek where Saturday is an ordinary working day."
            />
          </div>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 3: COMPENSATION (Matching Screenshot 1)                   -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'compensation'" class="tab-content-container">
      <!-- Accordion Card 1: Base Salary & Pay Scale -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('remuneration')">
          <span>Base Salary & Pay Scale</span>
          <ChevronDown v-if="sections.remuneration" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.remuneration" class="card-accordion-divider" />
        <div v-if="sections.remuneration" class="card-accordion-body">
          <!-- Row 1: Grade, Step, Salary Structure Template -->
          <div class="form-grid-3">
            <FormSelect 
              label="Job Pay Grade" 
              v-model="form.job_grade" 
              :options="['Grade A1', 'Grade A2', 'Grade B1', 'Grade B2', 'Grade C1', 'Grade C2', 'Grade D1']" 
              :disabled="true"
               
              helper-text="Determined automatically by the assigned job position."
            />
            <FormSelect 
              label="Grade Scale Steps" 
              v-model="form.job_grade_step" 
              :options="availableGradeSteps" 
               
              helper-text="Discrete step increment inside the position's grade ladder."
            />
            <FormSelect 
              label="Salary Structure Template" 
              v-model="form.salary_structure" 
              :options="['Standard Professional Package', 'Executive & Management Package', 'Plant & Factory Staff Package', 'Sales & Field Package']" 
               
              helper-text="Standard compensation template that auto-populates base salary and recurring allowances."
            />
          </div>

          <!-- Row 2: Monthly Base Salary, Currency, Payroll Processing Group -->
          <div class="form-grid-3 mt-4">
            <FormInput 
              label="Monthly Base Salary (ETB)" 
              type="number" 
              v-model="form.basic_amount" 
              helper-text="Fixed gross monthly salary that serves as the base for overtime, pension, and income tax calculations."
            />
            <FormSelect 
              label="Currency" 
              v-model="form.currency" 
              :options="['ETB', 'USD', 'EUR', 'GBP', 'KES', 'AED']" 
               
            />
            <FormSelect 
              label="Payroll Processing Group" 
              v-model="form.payroll_group" 
              :options="['Standard Monthly Payroll', 'Executive & Management', 'Plant & Factory Staff', 'Daily / Casual Payroll']" 
               
              helper-text="Assigned payroll cycle that determines pay frequency, cut-off dates, and disbursement approval routing."
            />
          </div>

          <!-- Row 3: Package Authorized By, Salary Effective Date, Effective Until -->
          <div class="form-grid-3 mt-4">
            <FormSelect 
              label="Package Authorized By" 
              v-model="form.compensation_supervisor" 
              :options="['Selamawit Bekele (Head of HR)', 'Abebe Kebede (Finance Director)', 'Dawit Alemu (Operations Manager)']" 
               
              helper-text="Designated officer who approved this compensation package offer."
            />
            <div class="form-field-wrap">
              <label class="field-label">Salary Effective Date</label>
              <div class="date-composite-input">
                <Calendar :size="15" class="date-cal-icon" />
                <input 
                  type="text" 
                  v-model="form.salary_effective_date" 
                  class="date-field-inner"
                  
                />
                <span class="gc-badge">GC</span>
              </div>
            </div>
            <div class="form-field-wrap">
              <label class="field-label">Effective Until</label>
              <div class="date-composite-input">
                <Calendar :size="15" class="date-cal-icon" />
                <input 
                  type="text" 
                  v-model="form.salary_effective_until" 
                  class="date-field-inner"
                  
                />
                <span class="gc-badge">GC</span>
              </div>
            </div>
          </div>

        </div>
      </div>

      <!-- Accordion Card 2: Allowances & Benefits -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('allowances')">
          <div class="flex items-center gap-3">
            <span>Allowances & Benefits</span>
            <span class="text-xs px-2.5 py-0.5 rounded-full bg-slate-100 text-[#404040] font-medium border border-slate-200">
              {{ salaryComponentsList.length }} {{ salaryComponentsList.length === 1 ? 'allowance' : 'allowances' }}
            </span>
          </div>
          <div class="flex items-center gap-3">
            <div v-if="grossStartingPackage" class="gross-summary-pill">
              <span class="gross-summary-label">Total Monthly Gross:</span>
              <span class="gross-summary-value">{{ grossStartingPackage.toLocaleString() }} ETB</span>
            </div>
            <ChevronDown v-if="sections.allowances" :size="15" class="header-chevron" />
            <ChevronRight v-else :size="15" class="header-chevron" />
          </div>
        </div>
        <div v-if="sections.allowances" class="card-accordion-divider" />
        <div v-if="sections.allowances" class="card-accordion-body">
          <p class="card-plain-desc">Configure monthly recurring cash allowances (transport, housing, hardship, representation) and non-base earnings attached to this employee's salary package.</p>

          <div class="child-table-wrapper">
            <table class="child-table">
              <thead>
                <tr class="child-table-header">
                  <th class="child-th child-th-check">
                    <input type="checkbox" @change="toggleSelectAll(salaryComponentsList, $event)" class="table-checkbox" />
                  </th>
                  <th class="child-th child-th-no">No.</th>
                  <th class="child-th" style="min-width: 240px;">Allowance / Component</th>
                  <th class="child-th" style="min-width: 180px;">Calculation Type</th>
                  <th class="child-th" style="min-width: 160px;">Amount / Value</th>
                  <th class="child-th child-th-col-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="currentColor" class="col-icon-solid">
                      <rect x="3" y="3" width="4" height="18" rx="1.5" />
                      <rect x="10" y="3" width="4" height="18" rx="1.5" />
                      <rect x="17" y="3" width="4" height="18" rx="1.5" />
                    </svg>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="salaryComponentsList.length === 0">
                  <td colspan="6" class="child-td-empty">No Recurring Allowances Added (Basic Salary Only)</td>
                </tr>
                <tr v-else v-for="(row, idx) in salaryComponentsList" :key="row.id" class="child-tr">
                  <td class="child-td child-td-check">
                    <input type="checkbox" v-model="row.selected" class="table-checkbox" />
                  </td>
                  <td class="child-td child-td-no">{{ idx + 1 }}</td>
                  <td class="child-td">
                    <select v-model="row.component_name" class="child-inline-select">
                      <option value="Transport Allowance">Transport Allowance</option>
                      <option value="Housing Allowance">Housing Allowance</option>
                      <option value="Representation Allowance">Representation Allowance</option>
                      <option value="Hardship Allowance">Hardship Allowance</option>
                      <option value="Fuel & Mileage Allowance">Fuel & Mileage Allowance</option>
                      <option value="Mobile & Communication">Mobile & Communication Allowance</option>
                      <option value="Food & Subsistence">Food Allowance</option>
                      <option value="Other Special Allowance">Other Allowance</option>
                    </select>
                  </td>
                  <td class="child-td">
                    <select v-model="row.calc_type" class="child-inline-select">
                      <option value="Fixed Amount">Fixed Amount (ETB)</option>
                      <option value="Percentage of Basic">% of Basic Salary</option>
                    </select>
                  </td>
                  <td class="child-td">
                    <div class="relative flex items-center">
                      <input type="number" v-model="row.amount" class="child-inline-input text-right pr-9" />
                      <span class="absolute right-2 text-[11px] font-semibold text-slate-400 select-none pointer-events-none">
                        {{ row.calc_type === 'Percentage of Basic' ? '%' : 'ETB' }}
                      </span>
                    </div>
                  </td>
                  <td class="child-td child-td-col-icon">
                    <button type="button" class="btn-row-expand" @click="openRowModal('salaryComponentsList', row, idx)" title="Expand Allowance Details">
                      <Expand :size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <button type="button" class="btn-add-row" @click="addSalaryComponent">
            <Plus :size="13" />
            <span>Add Allowance</span>
          </button>
        </div>
      </div>

      <!-- Accordion Card 3: Bank & Payment Accounts -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('primaryBank')">
          <span>Bank & Payment Accounts</span>
          <ChevronDown v-if="sections.primaryBank" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.primaryBank" class="card-accordion-divider" />
        <div v-if="sections.primaryBank" class="card-accordion-body">
          <p class="card-plain-desc">Configure direct deposit bank accounts, mobile wallets, and payment percentage splits for payroll disbursement.</p>

          <div class="child-table-wrapper">
            <table class="child-table">
              <thead>
                <tr class="child-table-header">
                  <th class="child-th child-th-check">
                    <input type="checkbox" @change="toggleSelectAll(bankAccountsList, $event)" class="table-checkbox" />
                  </th>
                  <th class="child-th child-th-no">No.</th>
                  <th class="child-th" style="min-width: 170px;">Payment Provider</th>
                  <th class="child-th" style="min-width: 150px;">Account Number / Wallet ID</th>
                  <th class="child-th" style="min-width: 160px;">Account Holder Name</th>
                  <th class="child-th" style="min-width: 140px;">Branch Name</th>
                  <th class="child-th" style="width: 110px;">Split Share (%)</th>
                  <th class="child-th text-center" style="width: 80px;">Primary</th>
                  <th class="child-th child-th-col-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="currentColor" class="col-icon-solid">
                      <rect x="3" y="3" width="4" height="18" rx="1.5" />
                      <rect x="10" y="3" width="4" height="18" rx="1.5" />
                      <rect x="17" y="3" width="4" height="18" rx="1.5" />
                    </svg>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="bankAccountsList.length === 0">
                  <td colspan="9" class="child-td-empty">No Account Configured (Disbursed in Cash)</td>
                </tr>
                <tr v-else v-for="(row, idx) in bankAccountsList" :key="row.id" class="child-tr">
                  <td class="child-td child-td-check">
                    <input type="checkbox" v-model="row.selected" class="table-checkbox" />
                  </td>
                  <td class="child-td child-td-no">{{ idx + 1 }}</td>
                  <td class="child-td">
                    <select v-model="row.payment_provider" class="child-inline-select">
                      <option value="" disabled>Select Provider</option>
                      <option v-for="prov in paymentProviders" :key="prov" :value="prov">{{ prov }}</option>
                    </select>
                  </td>
                  <td class="child-td">
                    <input type="text" v-model="row.account_number" class="child-inline-input"  />
                  </td>
                  <td class="child-td">
                    <input type="text" v-model="row.account_holder_name" class="child-inline-input"  />
                  </td>
                  <td class="child-td">
                    <input type="text" v-model="row.branch_name" class="child-inline-input"  />
                  </td>
                  <td class="child-td">
                    <input type="number" v-model="row.split_percent" class="child-inline-input text-right"  min="1" max="100" />
                  </td>
                  <td class="child-td text-center">
                    <input 
                      type="checkbox" 
                      :checked="row.is_primary" 
                      @change="setPrimaryAccount(idx)" 
                      class="custom-squircle-check" 
                      title="Primary Account"
                    />
                  </td>
                  <td class="child-td child-td-col-icon">
                    <button type="button" class="btn-row-expand" @click="openRowModal('bankAccountsList', row, idx)" title="Expand Row Details">
                      <Expand :size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <button type="button" class="btn-add-row" @click="addBankAccount">
            <Plus :size="13" />
            <span>Add Account</span>
          </button>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 4: QUALIFICATIONS                                         -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'credentials'" class="tab-content-container">
      <!-- Card 1: Academic Qualifications -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('academicQualifications')">
          <span>Academic Qualifications</span>
          <ChevronDown v-if="sections.academicQualifications" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.academicQualifications" class="card-accordion-divider" />
        <div v-if="sections.academicQualifications" class="card-accordion-body">
          <div class="child-table-wrapper">
            <table class="child-table">
              <thead>
                <tr class="child-table-header">
                  <th class="child-th child-th-check">
                    <input type="checkbox" @change="toggleSelectAll(academicQualifications, $event)" class="table-checkbox" />
                  </th>
                  <th class="child-th child-th-no">No.</th>
                  <th class="child-th">Degree Level</th>
                  <th class="child-th">Field of Study</th>
                  <th class="child-th">Awarding Institute</th>
                  <th class="child-th">Graduation Date</th>
                  <th class="child-th child-th-col-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="currentColor" class="col-icon-solid">
                      <rect x="3" y="3" width="4" height="18" rx="1.5" />
                      <rect x="10" y="3" width="4" height="18" rx="1.5" />
                      <rect x="17" y="3" width="4" height="18" rx="1.5" />
                    </svg>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="academicQualifications.length === 0">
                  <td colspan="7" class="child-td-empty">No Row</td>
                </tr>
                <tr v-else v-for="(row, idx) in academicQualifications" :key="row.id" class="child-tr">
                  <td class="child-td child-td-check">
                    <input type="checkbox" v-model="row.selected" class="table-checkbox" />
                  </td>
                  <td class="child-td child-td-no">{{ idx + 1 }}</td>
                  <td class="child-td" style="min-width: 140px;">
                    <select v-model="row.degree_level" class="child-inline-select">
                      <option value="" disabled>Select</option>
                      <option value="Primary School">Primary</option>
                      <option value="Secondary School">Secondary</option>
                      <option value="TVET / Level IV Certificate">TVET Certificate</option>
                      <option value="Diploma">Diploma</option>
                      <option value="Bachelor's Degree">Bachelor's Degree</option>
                      <option value="Master's Degree">Master's Degree</option>
                      <option value="Doctorate (PhD)">Doctorate (PhD)</option>
                    </select>
                  </td>
                  <td class="child-td" style="min-width: 160px;">
                    <input type="text" v-model="row.field_of_study" class="child-inline-input" list="fieldsOfStudyList" />
                  </td>
                  <td class="child-td" style="min-width: 170px;">
                    <input type="text" v-model="row.awarding_institute" class="child-inline-input" list="institutionsList" />
                  </td>
                  <td class="child-td" style="min-width: 130px;">
                    <input type="date" v-model="row.graduation_date" class="child-inline-input" />
                  </td>
                  <td class="child-td child-td-col-icon">
                    <button type="button" class="btn-row-expand" @click="openRowModal('academicQualifications', row, idx)" title="Expand Row Details">
                      <Expand :size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <button type="button" class="btn-add-row" @click="addAcademicQualification">
            <Plus :size="13" />
            <span>Add Row</span>
          </button>
        </div>
      </div>

      <!-- Card 2: Certifications & Licenses -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('professionalCertifications')">
          <span>Certifications & Licenses</span>
          <ChevronDown v-if="sections.professionalCertifications" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.professionalCertifications" class="card-accordion-divider" />
        <div v-if="sections.professionalCertifications" class="card-accordion-body">
          <div class="child-table-wrapper">
            <table class="child-table">
              <thead>
                <tr class="child-table-header">
                  <th class="child-th child-th-check">
                    <input type="checkbox" @change="toggleSelectAll(professionalCertifications, $event)" class="table-checkbox" />
                  </th>
                  <th class="child-th child-th-no">No.</th>
                  <th class="child-th">Certification / License</th>
                  <th class="child-th">Issuing Institution</th>
                  <th class="child-th">Certificate / License No.</th>
                  <th class="child-th">Issued Date</th>
                  <th class="child-th">Expiry Date</th>
                  <th class="child-th child-th-col-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="currentColor" class="col-icon-solid">
                      <rect x="3" y="3" width="4" height="18" rx="1.5" />
                      <rect x="10" y="3" width="4" height="18" rx="1.5" />
                      <rect x="17" y="3" width="4" height="18" rx="1.5" />
                    </svg>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="professionalCertifications.length === 0">
                  <td colspan="8" class="child-td-empty">No Row</td>
                </tr>
                <tr v-else v-for="(row, idx) in professionalCertifications" :key="row.id" class="child-tr">
                  <td class="child-td child-td-check">
                    <input type="checkbox" v-model="row.selected" class="table-checkbox" />
                  </td>
                  <td class="child-td child-td-no">{{ idx + 1 }}</td>
                  <td class="child-td" style="min-width: 170px;">
                    <input type="text" v-model="row.certification" class="child-inline-input" list="certificationsList" />
                  </td>
                  <td class="child-td" style="min-width: 160px;">
                    <input type="text" v-model="row.issuing_institution" class="child-inline-input" list="certInstitutionsList" />
                  </td>
                  <td class="child-td" style="min-width: 140px;">
                    <input type="text" v-model="row.certificate_number" class="child-inline-input" />
                  </td>
                  <td class="child-td" style="min-width: 120px;">
                    <input type="date" v-model="row.issued_date" class="child-inline-input" />
                  </td>
                  <td class="child-td" style="min-width: 120px;">
                    <input type="date" v-model="row.expiry_date" class="child-inline-input" />
                  </td>
                  <td class="child-td child-td-col-icon">
                    <button type="button" class="btn-row-expand" @click="openRowModal('professionalCertifications', row, idx)" title="Expand Row Details">
                      <Expand :size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <button type="button" class="btn-add-row" @click="addProfessionalCertification">
            <Plus :size="13" />
            <span>Add Row</span>
          </button>
        </div>
      </div>

      <!-- Card 3: Work Experience -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('priorWorkExperience')">
          <span>Work Experience</span>
          <ChevronDown v-if="sections.priorWorkExperience" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.priorWorkExperience" class="card-accordion-divider" />
        <div v-if="sections.priorWorkExperience" class="card-accordion-body">
          <div class="child-table-wrapper">
            <table class="child-table">
              <thead>
                <tr class="child-table-header">
                  <th class="child-th child-th-check">
                    <input type="checkbox" @change="toggleSelectAll(priorWorkExperiences, $event)" class="table-checkbox" />
                  </th>
                  <th class="child-th child-th-no">No.</th>
                  <th class="child-th" style="min-width: 170px;">Previous Employer</th>
                  <th class="child-th" style="min-width: 160px;">Job Title</th>
                  <th class="child-th" style="min-width: 140px;">Employment Type</th>
                  <th class="child-th" style="min-width: 130px;">Start Date</th>
                  <th class="child-th" style="min-width: 130px;">End Date</th>
                  <th class="child-th child-th-col-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="currentColor" class="col-icon-solid">
                      <rect x="3" y="3" width="4" height="18" rx="1.5" />
                      <rect x="10" y="3" width="4" height="18" rx="1.5" />
                      <rect x="17" y="3" width="4" height="18" rx="1.5" />
                    </svg>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="priorWorkExperiences.length === 0">
                  <td colspan="8" class="child-td-empty">No Row</td>
                </tr>
                <tr v-else v-for="(row, idx) in priorWorkExperiences" :key="row.id" class="child-tr">
                  <td class="child-td child-td-check">
                    <input type="checkbox" v-model="row.selected" class="table-checkbox" />
                  </td>
                  <td class="child-td child-td-no">{{ idx + 1 }}</td>
                  <td class="child-td">
                    <input type="text" v-model="row.previous_employer" class="child-inline-input" />
                  </td>
                  <td class="child-td">
                    <input type="text" v-model="row.job_title" class="child-inline-input" />
                  </td>
                  <td class="child-td">
                    <select v-model="row.employment_type" class="child-inline-select">
                      <option value="" disabled>Select</option>
                      <option value="Permanent">Permanent</option>
                      <option value="Contract">Contract</option>
                      <option value="Temporary">Temporary</option>
                      <option value="Probation">Probation</option>
                      <option value="Part-time">Part-time</option>
                      <option value="Internship">Internship</option>
                      <option value="Consultancy">Consultancy</option>
                    </select>
                  </td>
                  <td class="child-td">
                    <input type="date" v-model="row.start_date" class="child-inline-input" />
                  </td>
                  <td class="child-td">
                    <input type="date" v-model="row.end_date" class="child-inline-input" />
                  </td>
                  <td class="child-td child-td-col-icon">
                    <button type="button" class="btn-row-expand" @click="openRowModal('priorWorkExperiences', row, idx)" title="Expand Row Details">
                      <Expand :size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <button type="button" class="btn-add-row" @click="addPriorWorkExperience">
            <Plus :size="13" />
            <span>Add Row</span>
          </button>
        </div>
      </div>

      <!-- Card 4: Skills & Languages -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('skillsLanguages')">
          <span>Skills & Languages</span>
          <ChevronDown v-if="sections.skillsLanguages" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.skillsLanguages" class="card-accordion-divider" />
        <div v-if="sections.skillsLanguages" class="card-accordion-body">
          <div class="sub-section-title">Technical Skills</div>
          <p class="table-section-desc">Select practical capabilities and expertise level.</p>

          <div class="child-table-wrapper">
            <table class="child-table">
              <thead>
                <tr class="child-table-header">
                  <th class="child-th child-th-check">
                    <input type="checkbox" @change="toggleSelectAll(technicalSkills, $event)" class="table-checkbox" />
                  </th>
                  <th class="child-th child-th-no">No.</th>
                  <th class="child-th" style="min-width: 180px;">Skill / Competency</th>
                  <th class="child-th" style="min-width: 140px;">Proficiency</th>
                  <th class="child-th" style="width: 110px;">Years of Exp.</th>
                  <th class="child-th child-th-col-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="currentColor" class="col-icon-solid">
                      <rect x="3" y="3" width="4" height="18" rx="1.5" />
                      <rect x="10" y="3" width="4" height="18" rx="1.5" />
                      <rect x="17" y="3" width="4" height="18" rx="1.5" />
                    </svg>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="technicalSkills.length === 0">
                  <td colspan="6" class="child-td-empty">No Row</td>
                </tr>
                <tr v-else v-for="(row, idx) in technicalSkills" :key="row.id" class="child-tr">
                  <td class="child-td child-td-check">
                    <input type="checkbox" v-model="row.selected" class="table-checkbox" />
                  </td>
                  <td class="child-td child-td-no">{{ idx + 1 }}</td>
                  <td class="child-td">
                    <input type="text" v-model="row.skill" class="child-inline-input" list="skillsCatalogList" />
                  </td>
                  <td class="child-td">
                    <select v-model="row.proficiency" class="child-inline-select">
                      <option value="" disabled>Select</option>
                      <option value="Beginner">Beginner</option>
                      <option value="Intermediate">Intermediate</option>
                      <option value="Advanced">Advanced</option>
                      <option value="Expert">Expert</option>
                    </select>
                  </td>
                  <td class="child-td">
                    <input type="number" step="0.5" v-model="row.years_of_experience" class="child-inline-input text-right" />
                  </td>
                  <td class="child-td child-td-col-icon">
                    <button type="button" class="btn-row-expand" @click="openRowModal('technicalSkills', row, idx)" title="Expand Row Details">
                      <Expand :size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <button type="button" class="btn-add-row mb-6" @click="addTechnicalSkill">
            <Plus :size="13" />
            <span>Add Row</span>
          </button>

          <div class="sub-section-title mt-4">Spoken Languages</div>
          <p class="table-section-desc">Multilingual capabilities for client and team operations.</p>

          <div class="child-table-wrapper">
            <table class="child-table">
              <thead>
                <tr class="child-table-header">
                  <th class="child-th child-th-check">
                    <input type="checkbox" @change="toggleSelectAll(spokenLanguages, $event)" class="table-checkbox" />
                  </th>
                  <th class="child-th child-th-no">No.</th>
                  <th class="child-th">Language</th>
                  <th class="child-th">Fluency Level</th>
                  <th class="child-th text-center" style="width: 110px;">Mother Tongue</th>
                  <th class="child-th child-th-col-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="currentColor" class="col-icon-solid">
                      <rect x="3" y="3" width="4" height="18" rx="1.5" />
                      <rect x="10" y="3" width="4" height="18" rx="1.5" />
                      <rect x="17" y="3" width="4" height="18" rx="1.5" />
                    </svg>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="spokenLanguages.length === 0">
                  <td colspan="6" class="child-td-empty">No Row</td>
                </tr>
                <tr v-else v-for="(row, idx) in spokenLanguages" :key="row.id" class="child-tr">
                  <td class="child-td child-td-check">
                    <input type="checkbox" v-model="row.selected" class="table-checkbox" />
                  </td>
                  <td class="child-td child-td-no">{{ idx + 1 }}</td>
                  <td class="child-td" style="min-width: 160px;">
                    <input type="text" v-model="row.language" class="child-inline-input" list="languagesCatalogList" />
                  </td>
                  <td class="child-td" style="min-width: 140px;">
                    <select v-model="row.fluency_level" class="child-inline-select">
                      <option value="" disabled>Select</option>
                      <option value="Basic">Basic</option>
                      <option value="Conversational">Conversational</option>
                      <option value="Fluent">Fluent</option>
                      <option value="Native">Native</option>
                    </select>
                  </td>
                  <td class="child-td text-center">
                    <input 
                      type="checkbox" 
                      v-model="row.is_native" 
                      class="custom-squircle-check" 
                      title="Mother Tongue / Native Language"
                    />
                  </td>
                  <td class="child-td child-td-col-icon">
                    <button type="button" class="btn-row-expand" @click="openRowModal('spokenLanguages', row, idx)" title="Expand Row Details">
                      <Expand :size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <button type="button" class="btn-add-row" @click="addSpokenLanguage">
            <Plus :size="13" />
            <span>Add Row</span>
          </button>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 5: COMPLIANCE (Matching Screenshot 4)                     -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'compliance'" class="tab-content-container">
      <!-- Card 1: Statutory Registration -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('statutoryRegistration')">
          <span>Statutory Registration</span>
          <ChevronDown v-if="sections.statutoryRegistration" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.statutoryRegistration" class="card-accordion-divider" />
        <div v-if="sections.statutoryRegistration" class="card-accordion-body">
          <div class="form-grid-2">
            <FormInput label="TIN Number" type="number" v-model="form.tin" />
            <FormInput 
              label="POESSA Pension Number" 
              type="number"
              v-model="form.pension_number" 
              helper-text="Official registration number required for automated pension contribution calculation and statutory remittance."
            />
          </div>

          <!-- Dynamic Child Sub-Table: Tax & Pension Exemptions -->
          <div class="mt-5">
            <div class="mb-2">
              <span class="field-label block font-semibold text-neutral-700">Tax & Pension Exemptions</span>
              <p class="table-section-desc mb-0">Record authorized tax or pension exemptions (e.g. bilateral expatriate pension waiver, diplomatic tax status, or re-hired retirees).</p>
            </div>

            <div class="child-table-wrapper">
              <table class="child-table">
                <thead>
                  <tr class="child-table-header">
                    <th class="child-th child-th-check">
                      <input type="checkbox" @change="toggleSelectAll(statutoryExemptionsList, $event)" class="table-checkbox" />
                    </th>
                    <th class="child-th child-th-no">No.</th>
                    <th class="child-th" style="min-width: 240px;">Rule Type</th>
                    <th class="child-th">Legal Reason / Exemption Basis</th>
                    <th class="child-th child-th-col-icon">
                      <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="currentColor" class="col-icon-solid">
                        <rect x="3" y="3" width="4" height="18" rx="1.5" />
                        <rect x="10" y="3" width="4" height="18" rx="1.5" />
                        <rect x="17" y="3" width="4" height="18" rx="1.5" />
                      </svg>
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-if="statutoryExemptionsList.length === 0">
                    <td colspan="5" class="child-td-empty">No Row</td>
                  </tr>
                  <tr v-else v-for="(row, idx) in statutoryExemptionsList" :key="row.id" class="child-tr">
                    <td class="child-td child-td-check">
                      <input type="checkbox" v-model="row.selected" class="table-checkbox" />
                    </td>
                    <td class="child-td child-td-no">{{ idx + 1 }}</td>
                    <td class="child-td">
                      <select v-model="row.rule_type" class="child-inline-select">
                        <option value="" disabled>Select</option>
                        <option value="pension_employee">Pension (Employee Contribution)</option>
                        <option value="pension_employer">Pension (Employer Contribution)</option>
                        <option value="income_tax">Employment Income Tax</option>
                        <option value="overtime_rate">Overtime Rate</option>
                        <option value="working_hours_weekly">Weekly Working Hours Limit</option>
                        <option value="severance">Severance Pay</option>
                        <option value="notice_period">Notice Period</option>
                        <option value="annual_leave_minimum">Annual Leave Minimum</option>
                        <option value="probation_maximum">Probation Maximum</option>
                      </select>
                    </td>
                    <td class="child-td">
                      <input type="text" v-model="row.reason" class="child-inline-input" />
                    </td>
                    <td class="child-td child-td-col-icon">
                      <button type="button" class="btn-row-expand" @click="openRowModal('statutoryExemptionsList', row, idx)" title="Expand Row Details">
                        <Expand :size="14" />
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <button type="button" class="btn-add-row" @click="addStatutoryExemptionRow">
              <Plus :size="13" />
              <span>Add Row</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Card 2: Statutory Clearances & Compliance -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('regulatoryClearances')">
          <span>Statutory Clearances & Compliance</span>
          <ChevronDown v-if="sections.regulatoryClearances" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.regulatoryClearances" class="card-accordion-divider" />
        <div v-if="sections.regulatoryClearances" class="card-accordion-body">
          <p class="child-sub-desc mb-4">Record mandatory pre-employment medical checks, police background clearances, work permits, and statutory compliance verifications.</p>

        <div class="child-table-wrapper">
          <table class="child-table">
            <thead>
              <tr class="child-table-header">
                <th class="child-th child-th-check">
                  <input type="checkbox" @change="toggleSelectAll(regulatoryClearances, $event)" class="table-checkbox" />
                </th>
                <th class="child-th child-th-no">No.</th>
                <th class="child-th" style="min-width: 220px;">Compliance Item</th>
                <th class="child-th" style="min-width: 170px;">Reference / Permit No.</th>
                <th class="child-th" style="min-width: 130px;">Expiry Date</th>
                <th class="child-th" style="min-width: 150px;">Compliance Status</th>
                <th class="child-th child-th-col-icon">
                  <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="currentColor" class="col-icon-solid">
                    <rect x="3" y="3" width="4" height="18" rx="1.5" />
                    <rect x="10" y="3" width="4" height="18" rx="1.5" />
                    <rect x="17" y="3" width="4" height="18" rx="1.5" />
                  </svg>
                </th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="regulatoryClearances.length === 0">
                <td colspan="7" class="child-td-empty">No Row</td>
              </tr>
              <tr v-else v-for="(row, idx) in regulatoryClearances" :key="row.id" class="child-tr">
                <td class="child-td child-td-check">
                  <input type="checkbox" v-model="row.selected" class="table-checkbox" />
                </td>
                <td class="child-td child-td-no">{{ idx + 1 }}</td>
                <td class="child-td">
                  <select v-model="row.clearance_type" class="child-inline-select">
                    <option value="" disabled>Select</option>
                    <option value="fayda_verification">Fayda National ID Verification</option>
                    <option value="pension_registration">Pension Registration Confirmation</option>
                    <option value="work_permit">Work Permit / Visa</option>
                    <option value="medical_check">Pre-Employment Medical Check</option>
                    <option value="police_clearance">Police Background Clearance</option>
                    <option value="professional_license">Professional / Board License</option>
                    <option value="tax_registration">Tax Registration / TIN Verification</option>
                  </select>
                </td>
                <td class="child-td">
                  <input type="text" v-model="row.ref_number" class="child-inline-input" />
                </td>
                <td class="child-td">
                  <input type="date" v-model="row.expiry_date" class="child-inline-input" />
                </td>
                <td class="child-td">
                  <select v-model="row.verification_status" class="child-inline-select">
                    <option value="" disabled>Select</option>
                    <option value="Valid / Cleared">Valid / Cleared</option>
                    <option value="Pending Verification">Pending Verification</option>
                    <option value="Statutorily Waived">Statutorily Waived</option>
                  </select>
                </td>
                <td class="child-td child-td-col-icon">
                  <button type="button" class="btn-row-expand" @click="openRowModal('regulatoryClearances', row, idx)" title="Expand Row Details">
                    <Expand :size="14" />
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <button type="button" class="btn-add-row" @click="addRegulatoryClearance">
          <Plus :size="13" />
          <span>Add Row</span>
        </button>
        </div>
      </div>

      <!-- Card 2: Employee Guarantor -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('employeeGuarantor')">
          <span>Employee Guarantor</span>
          <ChevronDown v-if="sections.employeeGuarantor" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.employeeGuarantor" class="card-accordion-divider" />
        <div v-if="sections.employeeGuarantor" class="card-accordion-body">
          <p class="child-sub-desc mb-4">Required under Company Risk Policy for roles with cash handling, asset custody, storekeeping, or company study bonds.</p>

          <!-- Dynamic Position Guarantee Requirement Alert Banner (Shown if required by role) -->
          <div v-if="currentPositionGuarantee?.required" class="guarantee-requirement-banner mb-4">
            <div class="banner-icon-col">
              <ShieldAlert :size="20" class="text-amber-600" />
            </div>
            <div class="banner-body">
              <div class="banner-top-row">
                <div class="banner-title-group">
                  <span class="banner-title">Mandatory Position Surety Required</span>
                  <span class="banner-role-tag">{{ form.job_title }}</span>
                </div>
                <div class="banner-badge-group">
                  <span class="banner-amount-badge">Required: {{ currentPositionGuarantee.amount.toLocaleString() }} ETB</span>
                </div>
              </div>
              <p class="banner-reason">{{ currentPositionGuarantee.reason }}</p>
              <div class="banner-footer-row">
                <button 
                  v-if="form.guaranteed_amount !== currentPositionGuarantee.amount.toString()" 
                  type="button" 
                  class="banner-apply-btn" 
                  @click="applyPositionGuarantee"
                >
                  Apply Required Amount ({{ currentPositionGuarantee.amount.toLocaleString() }} ETB)
                </button>
                <div v-else class="banner-satisfied-pill">
                  <Check :size="13" class="text-emerald-600" />
                  <span>Requirement Amount Matched</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Row 1: 3 columns -->
          <div class="form-grid-3">
            <FormCombobox 
              label="Guarantor Full Name" 
              v-model="form.guarantor_name" 
              v-model:selectedId="form.guarantor_party_id"
              :options="guarantorPartyOptions"
              placeholder="Select"
              search-placeholder="Search by Name, Phone...."
              create-label="Create and Continue"
              helper-text="Search by name or phone, or click “+ Create and Continue” if not found."
              @select="onGuarantorPartySelected"
            />
            <FormInput 
              label="Guarantor Phone Number" 
              v-model="form.guarantor_phone" 
              helper-text="Primary contact line for official notifications."
            />
            <FormInput 
              label="Guarantor National ID / Kebele / TIN" 
              v-model="form.guarantor_id_number" 
            />
          </div>

          <!-- Row 2: 3 columns -->
          <div class="form-grid-3 mt-4">
            <FormSelect 
              label="Relationship to Employee" 
              v-model="form.guarantor_relation" 
              :options="['Spouse', 'Parent', 'Child', 'Sibling', 'Relative', 'Colleague', 'Friend']" 
               
            />
            <FormSelect 
              label="Guarantee Purpose" 
              v-model="form.guarantee_purpose" 
              :options="['Cash Handling Surety (Cashier / Treasury)', 'Asset Custody (Storekeeper / Warehouse)', 'Staff Loan / Financial Collateral', 'Company Study / Training Bond', 'General Employment Surety']" 
               
            />
            <FormInput 
              label="Guaranteed Amount (ETB)" 
              v-model="form.guaranteed_amount" 
              helper-text="Maximum amount the guarantor is liable for in the event of contractual default or breach."
            />
          </div>

          <!-- Row 3: 3 columns -->
          <div class="form-grid-3 mt-4">
            <FormCombobox 
              label="Guarantor Employer Organization" 
              v-model="form.guarantor_employer" 
              v-model:selectedId="form.guarantor_employer_party_id"
              :options="employerOrganizationOptions"
              placeholder="Select"
              search-placeholder="Search by Name, Phone...."
              create-label="Create and Continue"
              helper-text="Search by name or phone, or click “+ Create and Continue” if not found."
              @select="onGuarantorEmployerSelected"
            />
            <FormInput 
              label="Guarantor Monthly Income (ETB)" 
              v-model="form.guarantor_monthly_income" 
              helper-text="Verified monthly earnings backing the surety pledge to ensure financial capacity."
            />
            <FormInput 
              label="Official Guarantee Letter Ref No." 
              v-model="form.guarantee_letter_ref_no" 
            />
          </div>

          <!-- Row 4: 3 columns (Dates) -->
          <div class="form-grid-3 mt-4">
            <div class="form-field-wrap">
              <label class="field-label">Letter Agreement Date</label>
              <div class="date-composite-input">
                <Calendar :size="15" class="date-cal-icon" />
                <input type="text" v-model="form.letter_agreement_date" class="date-field-inner"  />
                <span class="gc-badge">GC</span>
              </div>
            </div>

            <div class="form-field-wrap">
              <label class="field-label">Coverage Start Date</label>
              <div class="date-composite-input">
                <Calendar :size="15" class="date-cal-icon" />
                <input type="text" v-model="form.coverage_start_date" class="date-field-inner"  />
                <span class="gc-badge">GC</span>
              </div>
            </div>

            <div class="form-field-wrap">
              <label class="field-label">Coverage End Date</label>
              <div class="date-composite-input">
                <Calendar :size="15" class="date-cal-icon" />
                <input type="text" v-model="form.coverage_end_date" class="date-field-inner"  />
                <span class="gc-badge">GC</span>
              </div>
            </div>
          </div>

          <!-- Row 5: Signed Guarantee Letter Dropzone -->
          <div class="scanned-sig-wrapper mt-4">
            <label class="field-label">Signed Guarantee Letter</label>
            <input ref="guaranteeFileInput" type="file" accept="image/*,.pdf" class="hidden-file-input" @change="onGuaranteeSelected" />
            <div class="scanned-sig-dropzone" @click="triggerGuaranteeInput">
              <div v-if="form.guarantee_attachment" class="sig-preview-content">
                <span class="sig-upload-text text-emerald-600 font-medium">Guarantee Bond Attached</span>
                <span class="sig-replace-link">Click to replace</span>
              </div>
              <div v-else class="sig-empty-content">
                <Upload :size="20" class="sig-upload-icon" />
                <span class="sig-upload-text">
                  <span class="text-brand-blue font-medium">Click to upload</span> or drag and drop
                </span>
                <span class="sig-upload-subtext">Picture files up to 10MB</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 6: FAMILY (Matching Screenshot 1)                         -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'family'" class="tab-content-container">
      <!-- Card 1: Emergency Contacts -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('emergencyContacts')">
          <span>Emergency Contacts</span>
          <ChevronDown v-if="sections.emergencyContacts" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.emergencyContacts" class="card-accordion-divider" />
        <div v-if="sections.emergencyContacts" class="card-accordion-body">
          <div class="child-table-wrapper">
            <table class="child-table">
              <thead>
                <tr class="child-table-header">
                  <th class="child-th child-th-check">
                    <input type="checkbox" @change="toggleSelectAll(emergencyContactsList, $event)" class="table-checkbox" />
                  </th>
                  <th class="child-th child-th-no">No.</th>
                  <th class="child-th" style="min-width: 170px;">Contact Full Name</th>
                  <th class="child-th" style="min-width: 140px;">Relationship</th>
                  <th class="child-th" style="min-width: 150px;">Primary Phone</th>
                  <th class="child-th" style="width: 120px;">Call Priority</th>
                  <th class="child-th child-th-col-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="currentColor" class="col-icon-solid">
                      <rect x="3" y="3" width="4" height="18" rx="1.5" />
                      <rect x="10" y="3" width="4" height="18" rx="1.5" />
                      <rect x="17" y="3" width="4" height="18" rx="1.5" />
                    </svg>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="emergencyContactsList.length === 0">
                  <td colspan="7" class="child-td-empty">No Row</td>
                </tr>
                <tr v-else v-for="(row, idx) in emergencyContactsList" :key="row.id" class="child-tr">
                  <td class="child-td child-td-check">
                    <input type="checkbox" v-model="row.selected" class="table-checkbox" />
                  </td>
                  <td class="child-td child-td-no">{{ idx + 1 }}</td>
                  <td class="child-td">
                    <input type="text" v-model="row.full_name" class="child-inline-input" />
                  </td>
                  <td class="child-td">
                    <select v-model="row.relationship" class="child-inline-select">
                      <option value="" disabled>Select</option>
                      <option value="Spouse">Spouse</option>
                      <option value="Parent">Parent</option>
                      <option value="Child">Child</option>
                      <option value="Sibling">Sibling</option>
                      <option value="Relative">Relative</option>
                      <option value="Colleague">Colleague</option>
                      <option value="Friend">Friend</option>
                    </select>
                  </td>
                  <td class="child-td">
                    <input type="tel" v-model="row.phone" class="child-inline-input" />
                  </td>
                  <td class="child-td">
                    <select v-model="row.priority" class="child-inline-select">
                      <option value="" disabled>Select</option>
                      <option :value="1">1 - Primary</option>
                      <option :value="2">2 - Secondary</option>
                    </select>
                  </td>
                  <td class="child-td child-td-col-icon">
                    <button type="button" class="btn-row-expand" @click="openRowModal('emergencyContactsList', row, idx)" title="Expand Row Details">
                      <Expand :size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <button type="button" class="btn-add-row" @click="addEmergencyContactPerson">
            <Plus :size="13" />
            <span>Add Row</span>
          </button>
        </div>
      </div>

      <!-- Card 2: Dependents & Beneficiaries -->
      <div class="clean-card">
        <div class="card-accordion-header" @click="toggleSection('dependents')">
          <span>Dependents & Insurance Beneficiaries</span>
          <ChevronDown v-if="sections.dependents" :size="15" class="header-chevron" />
          <ChevronRight v-else :size="15" class="header-chevron" />
        </div>
        <div v-if="sections.dependents" class="card-accordion-divider" />
        <div v-if="sections.dependents" class="card-accordion-body">
          <div class="child-table-wrapper">
            <table class="child-table">
              <thead>
                <tr class="child-table-header">
                  <th class="child-th child-th-check">
                    <input type="checkbox" @change="toggleSelectAll(dependentsList, $event)" class="table-checkbox" />
                  </th>
                  <th class="child-th child-th-no">No.</th>
                  <th class="child-th" style="min-width: 170px;">Dependent Full Name</th>
                  <th class="child-th" style="min-width: 140px;">Relationship</th>
                  <th class="child-th" style="min-width: 130px;">Date of Birth</th>
                  <th class="child-th text-center" style="width: 100px;">Beneficiary</th>
                  <th class="child-th child-th-col-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="currentColor" class="col-icon-solid">
                      <rect x="3" y="3" width="4" height="18" rx="1.5" />
                      <rect x="10" y="3" width="4" height="18" rx="1.5" />
                      <rect x="17" y="3" width="4" height="18" rx="1.5" />
                    </svg>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="dependentsList.length === 0">
                  <td colspan="7" class="child-td-empty">No Row</td>
                </tr>
                <tr v-else v-for="(row, idx) in dependentsList" :key="row.id" class="child-tr">
                  <td class="child-td child-td-check">
                    <input type="checkbox" v-model="row.selected" class="table-checkbox" />
                  </td>
                  <td class="child-td child-td-no">{{ idx + 1 }}</td>
                  <td class="child-td">
                    <input type="text" v-model="row.dependent_name" class="child-inline-input" />
                  </td>
                  <td class="child-td">
                    <select v-model="row.relationship" class="child-inline-select">
                      <option value="" disabled>Select</option>
                      <option value="Spouse">Spouse</option>
                      <option value="Child">Child</option>
                      <option value="Parent">Parent</option>
                      <option value="Sibling">Sibling</option>
                      <option value="Other">Other</option>
                    </select>
                  </td>
                  <td class="child-td">
                    <input type="date" v-model="row.birth_date" class="child-inline-input" />
                  </td>
                  <td class="child-td text-center">
                    <input 
                      type="checkbox" 
                      v-model="row.is_beneficiary" 
                      class="custom-squircle-check" 
                      title="Included in healthcare insurance and pension survivor benefits"
                    />
                  </td>
                  <td class="child-td child-td-col-icon">
                    <button type="button" class="btn-row-expand" @click="openRowModal('dependentsList', row, idx)" title="Expand Row Details">
                      <Expand :size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <button type="button" class="btn-add-row" @click="addDependentItem">
            <Plus :size="13" />
            <span>Add Row</span>
          </button>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- EXPAND ROW MODAL (Matching Reference Screenshots)            -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <div v-if="showRowModal && activeRowData" class="row-modal-overlay" @click="closeRowModal">
        <div class="row-modal-container" @click.stop>
          <!-- Header -->
          <div class="row-modal-header">
            <h3 class="row-modal-title">{{ modalTitle }}</h3>
            <button type="button" class="btn-modal-close" @click="closeRowModal" title="Close">
              <X :size="16" />
            </button>
          </div>

          <!-- Body -->
          <div class="row-modal-body">
            <!-- 1. Academic Qualification Fields (Aligned with PartyQualification Schema) -->
            <div v-if="activeModalType === 'academicQualifications'" class="modal-grid-2">
              <div class="modal-form-group">
                <label class="modal-form-label">Degree Level <span class="text-rose-500">*</span></label>
                <select v-model="activeRowData.degree_level" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option value="Primary School">Primary School</option>
                  <option value="Secondary School">Secondary School</option>
                  <option value="TVET / Level IV Certificate">TVET / Level IV Certificate</option>
                  <option value="Diploma">Diploma</option>
                  <option value="Bachelor's Degree">Bachelor's Degree</option>
                  <option value="Master's Degree">Master's Degree</option>
                  <option value="Doctorate (PhD)">Doctorate (PhD)</option>
                </select>
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Field of Study <span class="text-rose-500">*</span></label>
                <input type="text" v-model="activeRowData.field_of_study" class="modal-form-input" list="fieldsOfStudyList" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Awarding Institute <span class="text-rose-500">*</span></label>
                <input type="text" v-model="activeRowData.awarding_institute" class="modal-form-input" list="institutionsList" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Cumulative GPA (4.00 Scale)</label>
                <input type="text" v-model="activeRowData.gpa" class="modal-form-input" />
                <p class="modal-form-hint">
                  Cumulative grade point average on the 4.00 scale (e.g. 3.75).
                </p>
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Study Start Date</label>
                <input type="date" v-model="activeRowData.start_date" class="modal-form-input" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Graduation Date</label>
                <input type="date" v-model="activeRowData.graduation_date" class="modal-form-input" />
              </div>
            </div>

            <!-- 2. Professional Certification Fields (Aligned with PartyCertification Schema) -->
            <div v-else-if="activeModalType === 'professionalCertifications'" class="modal-grid-2">
              <div class="modal-form-group">
                <label class="modal-form-label">Certification / License <span class="text-rose-500">*</span></label>
                <input type="text" v-model="activeRowData.certification" class="modal-form-input" list="certificationsList" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Issuing Institution <span class="text-rose-500">*</span></label>
                <input type="text" v-model="activeRowData.issuing_institution" class="modal-form-input" list="certInstitutionsList" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Certificate / License Number</label>
                <input type="text" v-model="activeRowData.certificate_number" class="modal-form-input" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Issued Date <span class="text-rose-500">*</span></label>
                <input type="date" v-model="activeRowData.issued_date" class="modal-form-input" />
              </div>
              <div class="modal-form-group col-span-2">
                <label class="modal-form-label">Expiration Date</label>
                <input type="date" v-model="activeRowData.expiry_date" class="modal-form-input" />
                <p class="modal-form-hint">Leave blank if lifetime / never expires.</p>
              </div>
            </div>

            <!-- 3. Prior Work Experience Fields (Aligned with PartyExperience & EmployeeExperience Schema) -->
            <div v-else-if="activeModalType === 'priorWorkExperiences'" class="modal-grid-2">
              <div class="modal-form-group">
                <label class="modal-form-label">Previous Employer <span class="text-rose-500">*</span></label>
                <input type="text" v-model="activeRowData.previous_employer" class="modal-form-input" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Job Title / Position <span class="text-rose-500">*</span></label>
                <input type="text" v-model="activeRowData.job_title" class="modal-form-input" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Employment Type <span class="text-rose-500">*</span></label>
                <select v-model="activeRowData.employment_type" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option value="Permanent">Permanent</option>
                  <option value="Contract">Contract</option>
                  <option value="Temporary">Temporary</option>
                  <option value="Probation">Probation</option>
                  <option value="Part-time">Part-time</option>
                  <option value="Internship">Internship</option>
                  <option value="Consultancy">Consultancy</option>
                </select>
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Start Date <span class="text-rose-500">*</span></label>
                <input type="date" v-model="activeRowData.start_date" class="modal-form-input" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">End Date</label>
                <input type="date" v-model="activeRowData.end_date" class="modal-form-input" />
                <p class="modal-form-hint">Leave blank if still ongoing.</p>
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Reason for Leaving</label>
                <input type="text" v-model="activeRowData.reason_for_leaving" class="modal-form-input" />
              </div>
              <div class="modal-form-group col-span-2">
                <label class="modal-form-label">Supervisor Reference Contact</label>
                <input type="text" v-model="activeRowData.supervisor_reference" class="modal-form-input" />
                <p class="modal-form-hint">Contact person name, job title, and phone number or email.</p>
              </div>
              <div class="modal-form-group col-span-2">
                <label class="modal-form-label">Key Responsibilities & Deliverables</label>
                <textarea v-model="activeRowData.responsibilities" class="modal-form-textarea" rows="3"></textarea>
              </div>
              <div class="modal-form-group col-span-2 pt-2">
                <FormCheckbox 
                  id="expIsRelevant"
                  v-model="activeRowData.is_relevant" 
                  label="Directly Relevant to Current Role"
                  description="Flag this work experience as relevant to the current position. Used by HR for role-specific staffing, placement grading, and succession analysis."
                />
              </div>
            </div>

            <!-- 4. Key Competencies & Technical Skills Fields (Aligned with PartySkill Schema) -->
            <div v-else-if="activeModalType === 'technicalSkills'" class="modal-grid-2">
              <div class="modal-form-group">
                <label class="modal-form-label">Skill / Competency <span class="text-rose-500">*</span></label>
                <input type="text" v-model="activeRowData.skill" class="modal-form-input" list="skillsCatalogList" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Proficiency Level <span class="text-rose-500">*</span></label>
                <select v-model="activeRowData.proficiency" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option value="Beginner">Beginner</option>
                  <option value="Intermediate">Intermediate</option>
                  <option value="Advanced">Advanced</option>
                  <option value="Expert">Expert</option>
                </select>
              </div>
              <div class="modal-form-group col-span-2">
                <label class="modal-form-label">Years of Experience</label>
                <input type="number" step="0.5" v-model="activeRowData.years_of_experience" class="modal-form-input" />
                <p class="modal-form-hint">
                  Cumulative practical experience applying this skill (e.g. 3.5 years).
                </p>
              </div>
            </div>

            <!-- 5. Spoken Languages Fields -->
            <div v-else-if="activeModalType === 'spokenLanguages'" class="modal-grid-2">
              <div class="modal-form-group">
                <label class="modal-form-label">Language <span class="text-rose-500">*</span></label>
                <input type="text" v-model="activeRowData.language" class="modal-form-input" list="languagesCatalogList" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Overall Fluency Level <span class="text-rose-500">*</span></label>
                <select v-model="activeRowData.fluency_level" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option value="Basic">Basic</option>
                  <option value="Conversational">Conversational</option>
                  <option value="Fluent">Fluent</option>
                  <option value="Native">Native</option>
                </select>
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Speaking Competence</label>
                <select v-model="activeRowData.speaking_level" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option value="None">None</option>
                  <option value="Basic">Basic</option>
                  <option value="Intermediate">Intermediate</option>
                  <option value="Advanced">Advanced</option>
                  <option value="Native">Native</option>
                </select>
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Listening Competence</label>
                <select v-model="activeRowData.listening_level" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option value="None">None</option>
                  <option value="Basic">Basic</option>
                  <option value="Intermediate">Intermediate</option>
                  <option value="Advanced">Advanced</option>
                  <option value="Native">Native</option>
                </select>
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Reading Competence</label>
                <select v-model="activeRowData.reading_level" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option value="None">None</option>
                  <option value="Basic">Basic</option>
                  <option value="Intermediate">Intermediate</option>
                  <option value="Advanced">Advanced</option>
                  <option value="Native">Native</option>
                </select>
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Writing Competence</label>
                <select v-model="activeRowData.writing_level" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option value="None">None</option>
                  <option value="Basic">Basic</option>
                  <option value="Intermediate">Intermediate</option>
                  <option value="Advanced">Advanced</option>
                  <option value="Native">Native</option>
                </select>
              </div>
              <div class="modal-form-group col-span-2 pt-2">
                <FormCheckbox 
                  id="langIsNative"
                  v-model="activeRowData.is_native" 
                  label="Mother Tongue (Native Language)"
                  description="Designates this language as the employee's primary native language acquired from childhood."
                />
              </div>
            </div>

            <!-- 6. Statutory Clearances & Compliance Fields (Aligned with EmployeeCompliance Schema) -->
            <div v-else-if="activeModalType === 'regulatoryClearances'" class="modal-grid-2">
              <div class="modal-form-group">
                <label class="modal-form-label">Compliance Item <span class="text-rose-500">*</span></label>
                <select v-model="activeRowData.clearance_type" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option value="fayda_verification">Fayda National ID Verification</option>
                  <option value="pension_registration">Pension Registration Confirmation</option>
                  <option value="work_permit">Work Permit / Visa</option>
                  <option value="medical_check">Pre-Employment Medical Check</option>
                  <option value="police_clearance">Police Background Clearance</option>
                  <option value="professional_license">Professional / Board License</option>
                  <option value="tax_registration">Tax Registration / TIN Verification</option>
                </select>
                <p class="modal-form-hint">
                  Statutory compliance item required prior to employee onboarding.
                </p>
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Reference / Permit No. <span class="text-rose-500">*</span></label>
                <input type="text" v-model="activeRowData.ref_number" class="modal-form-input" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Compliance Status <span class="text-rose-500">*</span></label>
                <select v-model="activeRowData.verification_status" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option value="Valid / Cleared">Valid / Cleared</option>
                  <option value="Pending Verification">Pending Verification</option>
                  <option value="Statutorily Waived">Statutorily Waived</option>
                </select>
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Inspected & Verified By</label>
                <select v-model="activeRowData.verified_by" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option value="Selamawit Bekele (Head of HR)">Selamawit Bekele (Head of HR)</option>
                  <option value="Dawit Alemu (Compliance Officer)">Dawit Alemu (Compliance Officer)</option>
                  <option value="Abebe Kebede (Finance Director)">Abebe Kebede (Finance Director)</option>
                </select>
                <p class="modal-form-hint">Designated compliance officer who inspected and verified the documentation.</p>
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Issue Date</label>
                <input type="date" v-model="activeRowData.issue_date" class="modal-form-input" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Expiry / Renewal Date</label>
                <input type="date" v-model="activeRowData.expiry_date" class="modal-form-input" />
                <p class="modal-form-hint">
                  Leave blank if document does not expire.
                </p>
              </div>
              <div class="modal-form-group col-span-2">
                <label class="modal-form-label">Verification Notes & Institutional Reference</label>
                <textarea v-model="activeRowData.notes" class="modal-form-textarea" rows="2"></textarea>
              </div>
            </div>

            <!-- 7. Emergency Contacts Fields (Aligned with EmployeeEmergencyContact Schema) -->
            <div v-else-if="activeModalType === 'emergencyContactsList'" class="modal-grid-2">
              <div class="modal-form-group">
                <label class="modal-form-label">Contact Full Name <span class="text-rose-500">*</span></label>
                <input type="text" v-model="activeRowData.full_name" class="modal-form-input" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Relationship to Employee <span class="text-rose-500">*</span></label>
                <select v-model="activeRowData.relationship" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option value="Spouse">Spouse</option>
                  <option value="Parent">Parent</option>
                  <option value="Child">Child</option>
                  <option value="Sibling">Sibling</option>
                  <option value="Relative">Relative</option>
                  <option value="Colleague">Colleague</option>
                  <option value="Friend">Friend</option>
                </select>
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Primary Telephone <span class="text-rose-500">*</span></label>
                <input type="tel" v-model="activeRowData.phone" class="modal-form-input" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Call Priority <span class="text-rose-500">*</span></label>
                <select v-model="activeRowData.priority" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option :value="1">1 - Primary / First Call</option>
                  <option :value="2">2 - Secondary / Backup Call</option>
                </select>
                <p class="modal-form-hint">Emergency response dialing sequence.</p>
              </div>
              <div class="modal-form-group col-span-2">
                <label class="modal-form-label">City / Residential Location</label>
                <input type="text" v-model="activeRowData.city_location" class="modal-form-input" />
                <p class="modal-form-hint">Physical residence or kebele location for emergency dispatch.</p>
              </div>
            </div>

            <!-- 8. Dependents Fields (Aligned with PartyDependent Schema) -->
            <div v-else-if="activeModalType === 'dependentsList'" class="modal-grid-2">
              <div class="modal-form-group">
                <label class="modal-form-label">Dependent Full Name <span class="text-rose-500">*</span></label>
                <input type="text" v-model="activeRowData.dependent_name" class="modal-form-input" />
              </div>
              <div class="modal-form-group">
                <label class="modal-form-label">Relationship <span class="text-rose-500">*</span></label>
                <select v-model="activeRowData.relationship" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option value="Spouse">Spouse</option>
                  <option value="Child">Child</option>
                  <option value="Parent">Parent</option>
                  <option value="Sibling">Sibling</option>
                  <option value="Other">Other</option>
                </select>
              </div>
              <div class="modal-form-group col-span-2">
                <label class="modal-form-label">Date of Birth</label>
                <input type="date" v-model="activeRowData.birth_date" class="modal-form-input" />
                <p class="modal-form-hint">Required for statutory age-dependent health cover and benefit limits.</p>
              </div>
              <div class="modal-form-group col-span-2">
                <FormCheckbox 
                  v-model="activeRowData.is_beneficiary" 
                  label="Healthcare & Pension Survivor Beneficiary"
                  description="Designates whether this dependent is included in corporate health insurance coverage and statutory pension survivor benefits."
                />
              </div>
              <div class="modal-form-group col-span-2">
                <label class="modal-form-label">Benefit Remarks & Healthcare Card Details</label>
                <textarea v-model="activeRowData.benefit_notes" class="modal-form-textarea" rows="2"></textarea>
                <p class="modal-form-hint">
                  Coverage remarks, insurance policy card number, or specific healthcare exclusions.
                </p>
              </div>
            </div>

            <!-- 9. Statutory Rule Exemption Fields (with WYSIWYG Reason Editor) -->
            <div v-else-if="activeModalType === 'statutoryExemptionsList'" class="modal-grid-2">
              <div class="modal-form-group">
                <label class="modal-form-label">Rule Type <span class="text-rose-500">*</span></label>
                <select v-model="activeRowData.rule_type" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option value="pension_employee">Pension (Employee Contribution)</option>
                  <option value="pension_employer">Pension (Employer Contribution)</option>
                  <option value="income_tax">Employment Income Tax</option>
                  <option value="overtime_rate">Overtime Rate</option>
                  <option value="working_hours_weekly">Weekly Working Hours Limit</option>
                  <option value="severance">Severance Pay</option>
                  <option value="notice_period">Notice Period</option>
                  <option value="annual_leave_minimum">Annual Leave Minimum</option>
                  <option value="probation_maximum">Probation Maximum</option>
                </select>
                <p class="modal-form-hint">
                  Statutory tax or labor policy being waived under authorized exemption.
                </p>
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Exemption Authorized By <span class="text-rose-500">*</span></label>
                <select v-model="activeRowData.approved_by" class="modal-form-select">
                  <option value="" disabled>Select</option>
                  <option value="Selamawit Bekele (Head of HR)">Selamawit Bekele (Head of HR)</option>
                  <option value="Abebe Kebede (Finance Director)">Abebe Kebede (Finance Director)</option>
                  <option value="Dawit Alemu (Operations Manager)">Dawit Alemu (Operations Manager)</option>
                </select>
                <p class="modal-form-hint">
                  Designated officer who validated the legal basis for the waiver.
                </p>
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Effective From</label>
                <input type="date" v-model="activeRowData.effective_from" class="modal-form-input" />
                <p class="modal-form-hint">
                  Defaults to employment start date if left blank.
                </p>
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Effective Until (Optional)</label>
                <input type="date" v-model="activeRowData.effective_to" class="modal-form-input" />
                <p class="modal-form-hint">
                  Leave blank if waiver is indefinite or valid until revoked.
                </p>
              </div>

              <!-- Reason in Rich Text / WYSIWYG Editor as requested by user -->
              <div class="modal-form-group col-span-2">
                <label class="modal-form-label">Exemption Reason & Legal Justification (Rich Text)</label>
                <div class="wysiwyg-editor-box">
                  <div class="wysiwyg-toolbar">
                    <select class="toolbar-select">
                      <option>Paragraph</option>
                      <option>Heading 1</option>
                      <option>Heading 2</option>
                    </select>
                    <select class="toolbar-select">
                      <option>Font Type</option>
                      <option>Sans Serif</option>
                      <option>Monospace</option>
                    </select>
                    <span class="toolbar-divider" />
                    <button type="button" class="tb-btn font-bold" title="Bold">B</button>
                    <button type="button" class="tb-btn italic font-serif" title="Italic">I</button>
                    <button type="button" class="tb-btn underline" title="Underline">U</button>
                    <button type="button" class="tb-btn line-through" title="Strikethrough">S</button>
                    <button type="button" class="tb-btn" title="Table"><Table :size="14" /></button>
                    <span class="toolbar-divider" />
                    <button type="button" class="tb-btn" title="Bullet List"><List :size="14" /></button>
                    <button type="button" class="tb-btn" title="Numbered List"><ListOrdered :size="14" /></button>
                    <span class="toolbar-divider" />
                    <button type="button" class="tb-btn" title="Link"><Link :size="14" /></button>
                    <div class="toolbar-spacer" />
                    <button type="button" class="tb-btn" title="Undo"><Undo2 :size="14" /></button>
                    <button type="button" class="tb-btn" title="Redo"><Redo2 :size="14" /></button>
                  </div>
                  <textarea 
                    v-model="activeRowData.reason" 
                    class="wysiwyg-textarea" 
                    rows="4" 
                  ></textarea>
                  <div class="wysiwyg-status-bar">
                    <span class="char-count">{{ (activeRowData.reason || '').length }} Characters</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- 10. Salary Disbursement Account Fields -->
            <div v-else-if="activeModalType === 'bankAccountsList'" class="modal-grid-2">
              <div class="modal-form-group">
                <label class="modal-form-label">Payment Provider / Bank <span class="text-rose-500">*</span></label>
                <select v-model="activeRowData.payment_provider" class="modal-form-select">
                  <option value="" disabled>Select Provider</option>
                  <option v-for="prov in paymentProviders" :key="prov" :value="prov">{{ prov }}</option>
                </select>
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Branch Name</label>
                <input type="text" v-model="activeRowData.branch_name" class="modal-form-input" />
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Account Number / Wallet ID <span class="text-rose-500">*</span></label>
                <input type="text" v-model="activeRowData.account_number" class="modal-form-input" />
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Account Holder Name <span class="text-rose-500">*</span></label>
                <input type="text" v-model="activeRowData.account_holder_name" class="modal-form-input" />
                <p class="modal-form-hint">
                  Must match the official registered name on the bank account.
                </p>
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Split Share (%) <span class="text-rose-500">*</span></label>
                <input type="number" v-model="activeRowData.split_percent" class="modal-form-input" min="1" max="100" />
                <p class="modal-form-hint">
                  Percentage of net salary routed to this account (total must equal 100%).
                </p>
              </div>

              <div class="modal-form-group col-span-2 pt-2">
                <FormCheckbox 
                  id="modalBankAccountIsPrimary"
                  v-model="activeRowData.is_primary" 
                  label="Primary Disbursement Account"
                  description="Designates this bank account as the primary destination for automated monthly net salary electronic fund transfers."
                  @change="setPrimaryAccount(activeRowIndex)"
                />
              </div>
            </div>

            <!-- 11. Salary Component & Allowance Fields -->
            <div v-else-if="activeModalType === 'salaryComponentsList'" class="modal-grid-2">
              <div class="modal-form-group">
                <label class="modal-form-label">Payroll Component <span class="text-rose-500">*</span></label>
                <select v-model="activeRowData.component_name" class="modal-form-select">
                  <option value="Transport Allowance">Transport Allowance</option>
                  <option value="Housing Allowance">Housing Allowance</option>
                  <option value="Representation Allowance">Representation Allowance</option>
                  <option value="Hardship Allowance">Hardship Allowance</option>
                  <option value="Fuel & Mileage Allowance">Fuel & Mileage Allowance</option>
                  <option value="Mobile & Communication">Mobile & Communication Allowance</option>
                  <option value="Food & Subsistence">Food Allowance</option>
                  <option value="Other Special Allowance">Other Special Allowance</option>
                </select>
                <p class="modal-form-hint">
                  Select the recurring allowance or earning component to add to monthly compensation.
                </p>
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Calculation Type <span class="text-rose-500">*</span></label>
                <select v-model="activeRowData.calc_type" class="modal-form-select">
                  <option value="Fixed Amount">Fixed Amount (ETB)</option>
                  <option value="Percentage of Basic">% of Monthly Basic Salary</option>
                </select>
                <p class="modal-form-hint">
                  Choose whether this allowance is a fixed ETB amount or calculated as a percentage of basic salary.
                </p>
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Amount / Value <span class="text-rose-500">*</span></label>
                <input type="number" v-model="activeRowData.amount" class="modal-form-input" />
                <p class="modal-form-hint">
                  Enter the fixed amount in ETB or percentage rate (e.g. 15 for 15%).
                </p>
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Calculation Formula (Optional)</label>
                <select v-model="activeRowData.payroll_formula" class="modal-form-select">
                  <option value="Default Component Formula">Default Component Formula</option>
                  <option value="min(basic * 0.25, 2200)">Statutory Cap: min(basic * 0.25, 2200)</option>
                  <option value="Direct Value (No Formula)">Direct Value (No Formula Pin)</option>
                </select>
                <p class="modal-form-hint">
                  Optional automated calculation rule for statutory caps or tiered formulas.
                </p>
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Effective From (Optional)</label>
                <input type="date" v-model="activeRowData.effective_from" class="modal-form-input" />
                <p class="modal-form-hint">
                  Optional line start date; defaults to package effective date if left blank.
                </p>
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Effective To (Optional)</label>
                <input type="date" v-model="activeRowData.effective_to" class="modal-form-input" />
                <p class="modal-form-hint">
                  Optional expiration date; leave blank if ongoing throughout employment.
                </p>
              </div>
            </div>

            <!-- 12. Address & Physical Domicile Fields -->
            <div v-else-if="activeModalType === 'addressesList'" class="modal-grid-2">
              <div class="modal-form-group col-span-2">
                <label class="modal-form-label">Address Type <span class="text-rose-500">*</span></label>
                <select v-model="activeRowData.address_type" class="modal-form-select">
                  <option value="residence">Residence / Primary Home</option>
                  <option value="postal">Postal Address</option>
                  <option value="work">Work Location</option>
                  <option value="emergency">Emergency Domicile</option>
                  <option value="birth_place">Place of Birth</option>
                  <option value="other">Other Domicile</option>
                </select>
                <p class="modal-form-hint">
                  Classification of this address record for official Party identity.
                </p>
              </div>

              <!-- Exact Geographic Location Hierarchy (Spine) -->
              <div class="modal-form-group col-span-2">
                <div class="location-picker-card">
                  <div class="location-picker-header">
                    <div class="location-header-title">
                      <MapPin :size="15" class="location-pin-icon" />
                      <span>Exact Geographic Location</span>
                    </div>
                    <!-- Visual Dynamic Breadcrumb / Badge -->
                    <div class="location-breadcrumb-badge" :title="activeRowData.admin_unit || 'No location configured'">
                      <span class="breadcrumb-dot"></span>
                      <span class="breadcrumb-text">{{ activeRowData.admin_unit || 'Select Location Hierarchy' }}</span>
                    </div>
                  </div>

                  <div class="location-picker-body">
                    <!-- Level 1: Country -->
                    <div class="modal-form-group">
                      <label class="modal-form-label">Country <span class="text-rose-500">*</span></label>
                      <select v-model="activeRowData.country" class="modal-form-select" @change="onCountryChange">
                        <option value="Ethiopia">Ethiopia [ET]</option>
                        <option value="Kenya">Kenya [KE]</option>
                        <option value="Djibouti">Djibouti [DJ]</option>
                        <option value="United States">United States [US]</option>
                        <option value="United Kingdom">United Kingdom [GB]</option>
                      </select>
                      <p class="modal-form-hint">Primary sovereign jurisdiction.</p>
                    </div>

                    <!-- Level 2: Region / City Administration -->
                    <div class="modal-form-group">
                      <label class="modal-form-label">Region / City Administration <span class="text-rose-500">*</span></label>
                      <select v-model="activeRowData.region" class="modal-form-select" @change="onRegionChange">
                        <option value="" disabled>Select</option>
                        <option v-for="r in currentRegionOptions" :key="r" :value="r">{{ r }}</option>
                      </select>
                      <p class="modal-form-hint">Administrative state or chartered city.</p>
                    </div>

                    <!-- Level 3: Zone / Sub-City -->
                    <div class="modal-form-group">
                      <label class="modal-form-label">Zone / Sub-City</label>
                      <div v-if="currentSubcityOptions.length > 0" class="flex flex-col gap-1.5">
                        <select v-model="activeRowData.subcity_zone" class="modal-form-select" @change="onSubcityChange">
                          <option value="" disabled>Select</option>
                          <option v-for="sc in currentSubcityOptions" :key="sc" :value="sc">{{ sc }}</option>
                          <option value="__custom__">Other / Custom Zone...</option>
                        </select>
                        <input 
                          v-if="activeRowData.subcity_zone === '__custom__' || isCustomSubcity" 
                          type="text" 
                          v-model="customSubcityText" 
                          class="modal-form-input mt-1" 
                          @input="onCustomSubcityInput" 
                        />
                      </div>
                      <div v-else>
                        <input 
                          type="text" 
                          v-model="activeRowData.subcity_zone" 
                          class="modal-form-input" 
                          @input="updateAdminUnitSummary" 
                        />
                      </div>
                      <p class="modal-form-hint">{{ activeRowData.region === 'Addis Ababa' ? 'Chartered municipal sub-city.' : 'Provincial zone or municipal district.' }}</p>
                    </div>

                    <!-- Level 4: Woreda / District -->
                    <div class="modal-form-group">
                      <label class="modal-form-label">Woreda / District</label>
                      <div v-if="currentWoredaOptions.length > 0" class="flex flex-col gap-1.5">
                        <select v-model="activeRowData.woreda" class="modal-form-select" @change="onWoredaChange">
                          <option value="" disabled>Select</option>
                          <option v-for="w in currentWoredaOptions" :key="w" :value="w">{{ w }}</option>
                          <option value="__custom__">Other / Custom Woreda...</option>
                        </select>
                        <input 
                          v-if="activeRowData.woreda === '__custom__' || isCustomWoreda" 
                          type="text" 
                          v-model="customWoredaText" 
                          class="modal-form-input mt-1" 
                          @input="onCustomWoredaInput" 
                        />
                      </div>
                      <div v-else>
                        <input 
                          type="text" 
                          v-model="activeRowData.woreda" 
                          class="modal-form-input" 
                          @input="updateAdminUnitSummary" 
                        />
                      </div>
                      <p class="modal-form-hint">{{ activeRowData.region === 'Addis Ababa' ? 'e.g. Woreda 03, Woreda 08.' : 'Local district / woreda administration.' }}</p>
                    </div>
                  </div>
                </div>
              </div>

              <div class="modal-form-group col-span-2">
                <label class="modal-form-label">
                  {{ activeRowData.address_type === 'postal' ? 'P.O. Box & Branch Line' : 'Street / Locality Line' }}
                  <span class="text-rose-500">*</span>
                </label>
                <input type="text" v-model="activeRowData.line" class="modal-form-input" />
                <p class="modal-form-hint">
                  {{ activeRowData.address_type === 'postal' ? 'e.g. P.O. Box 1176, Central Post Office' : 'e.g. Cameroon St., near Edna Mall' }}
                </p>
              </div>

              <!-- House Number: physical addresses only -->
              <div v-if="activeRowData.address_type !== 'postal'" class="modal-form-group">
                <label class="modal-form-label">House Number</label>
                <input type="text" v-model="activeRowData.house_number" class="modal-form-input" />
                <p class="modal-form-hint">House number as printed on Fayda ID registration or door plaque.</p>
              </div>

              <!-- Postal Code: prominent for postal -->
              <div :class="activeRowData.address_type === 'postal' ? 'modal-form-group col-span-2' : 'modal-form-group'">
                <label class="modal-form-label">
                  Postal Code / Zip
                  <span v-if="activeRowData.address_type === 'postal'" class="text-rose-500">*</span>
                </label>
                <input type="text" v-model="activeRowData.postal_code" class="modal-form-input font-mono" />
                <p class="modal-form-hint">Official postal dispatch zip code (e.g. 1000, 1176).</p>
              </div>

              <!-- Temporal Effectivity (Audit) -->
              <div class="modal-form-group">
                <label class="modal-form-label">Effective From</label>
                <input type="date" v-model="activeRowData.effective_from" class="modal-form-input" />
                <p class="modal-form-hint">Defaults to current hire date or intake date.</p>
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Effective To</label>
                <input type="date" v-model="activeRowData.effective_to" class="modal-form-input" />
                <p class="modal-form-hint">Leave empty if this is an active current domicile.</p>
              </div>

              <div class="modal-form-group col-span-2 pt-2">
                <FormCheckbox 
                  id="modalAddressIsPrimary"
                  v-model="activeRowData.is_primary" 
                  label="Primary Address (Official Domicile)"
                  description="Designates this record as the employee's official primary residence for statutory tax remittance, administrative notices, and emergency routing."
                  @change="setPrimaryAddress(activeRowIndex)"
                />
              </div>
            </div>
          </div>

          <!-- Footer (Matching Screenshot 2) -->
          <div class="row-modal-footer">
            <button type="button" class="btn-modal-delete" @click="deleteModalRow">
              Delete
            </button>
            <div class="row-modal-actions-right">
              <button 
                type="button" 
                class="btn-modal-ctrl-icon" 
                :disabled="isLastRow" 
                @click="moveRowDown" 
                title="Move Down"
              >
                <ArrowDown :size="15" />
              </button>
              <button 
                type="button" 
                class="btn-modal-ctrl-icon" 
                :disabled="isFirstRow" 
                @click="moveRowUp" 
                title="Move Up"
              >
                <ArrowUp :size="15" />
              </button>
              <button 
                type="button" 
                class="btn-modal-ctrl-action" 
                @click="duplicateModalRow"
              >
                <Copy :size="13" />
                <span>Duplicate Row</span>
              </button>
              <button 
                type="button" 
                class="btn-modal-ctrl-action" 
                @click="insertRowAbove"
              >
                <Plus :size="13" />
                <span>Insert Above</span>
              </button>
              <button 
                type="button" 
                class="btn-modal-ctrl-action" 
                @click="insertRowBelow"
              >
                <Plus :size="13" />
                <span>Insert Below</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Floating Bulk Action Bar (Matching Images 1 & 2) -->
    <TableFloatingBar 
      :show="floatingSelectedCount > 0"
      :selected-count="floatingSelectedCount"
      :total-count="floatingTotalCount"
      @select-all="handleFloatingSelectAll"
      @duplicate="handleFloatingDuplicate"
      @edit="handleFloatingEdit"
      @delete="handleFloatingDelete"
      @change-status="handleFloatingChangeStatus"
      @close="handleFloatingClose"
    />

    <!-- Standard Catalog Datalists for Academic Qualifications -->
    <datalist id="fieldsOfStudyList">
      <option value="Accounting" />
      <option value="Finance" />
      <option value="Human Resource Management" />
      <option value="Computer Science & Software Engineering" />
      <option value="Information Technology" />
      <option value="Business Administration" />
      <option value="Economics" />
      <option value="Marketing & Sales Management" />
      <option value="Supply Chain & Logistics" />
      <option value="Electrical Engineering" />
      <option value="Mechanical Engineering" />
      <option value="Civil Engineering" />
      <option value="Law / Legal Studies" />
      <option value="Public Administration" />
      <option value="Statistics & Data Analytics" />
    </datalist>

    <datalist id="institutionsList">
      <option value="Addis Ababa University (AAU)" />
      <option value="Bahir Dar University (BDU)" />
      <option value="Hawassa University" />
      <option value="Jimma University" />
      <option value="Mekelle University" />
      <option value="Adama Science and Technology University (ASTU)" />
      <option value="Addis Ababa Science and Technology University (AASTU)" />
      <option value="Admas University" />
      <option value="Unity University" />
      <option value="St. Mary's University" />
      <option value="Rift Valley University" />
      <option value="Entoto TVET College" />
      <option value="General Wingate TVET College" />
      <option value="Foreign / International University" />
    </datalist>

    <datalist id="certificationsList">
      <option value="ACCA (Association of Chartered Certified Accountants)" />
      <option value="CPA (Certified Public Accountant)" />
      <option value="PMP (Project Management Professional)" />
      <option value="CIA (Certified Internal Auditor)" />
      <option value="CFA (Chartered Financial Analyst)" />
      <option value="Cisco CCNA / CCNP" />
      <option value="AWS Certified Solutions Architect" />
      <option value="SHRM-CP / SHRM-SCP (HR Professional)" />
      <option value="Certified Supply Chain Professional (CSCP)" />
      <option value="Professional Food Handler Certification" />
      <option value="Certified Procurement Specialist" />
    </datalist>

    <datalist id="certInstitutionsList">
      <option value="ACCA Global" />
      <option value="AABE (Accounting and Auditing Board of Ethiopia)" />
      <option value="Project Management Institute (PMI)" />
      <option value="Institute of Internal Auditors (IIA)" />
      <option value="Cisco Systems" />
      <option value="Amazon Web Services (AWS)" />
      <option value="Ethiopian Management Institute (EMI)" />
      <option value="Federal Public Procurement Authority (FPPA)" />
      <option value="Addis Ababa Food and Drug Authority" />
    </datalist>

    <datalist id="skillsCatalogList">
      <option value="IFRS Reporting & Financial Accounting" />
      <option value="Peachtree / Sage 50 Accounting" />
      <option value="Point of Sale (POS) Operation" />
      <option value="Cash Management & Daily Reconciliation" />
      <option value="Cost Accounting & Budgeting" />
      <option value="Tax Compliance & Withholding" />
      <option value="Procurement Negotiation" />
      <option value="Supply Chain & Inventory Management" />
      <option value="Warehouse Management & Stock Auditing" />
      <option value="Forklift Operation & Material Handling" />
      <option value="Food Safety & Hygiene Compliance" />
      <option value="Food Handler Technique & Prep" />
      <option value="Barista & Beverage Crafting" />
      <option value="Customer Service & Front Desk Operations" />
      <option value="Housekeeping & Facility Upkeep" />
      <option value="Data Entry & Documentation Integrity" />
      <option value="Labour Law & Employee Relations" />
      <option value="Payroll Processing & Statutory Remittance" />
      <option value="Talent Acquisition & Sourcing" />
      <option value="ERP System Administration & SQL" />
      <option value="Full-Stack Software Development" />
      <option value="Network Infrastructure & Security" />
    </datalist>

    <datalist id="languagesCatalogList">
      <option value="Amharic" />
      <option value="Afaan Oromo" />
      <option value="Tigrinya" />
      <option value="Somali" />
      <option value="Sidama" />
      <option value="Wolaytta" />
      <option value="English" />
      <option value="French" />
      <option value="Arabic" />
      <option value="Mandarin Chinese" />
      <option value="German" />
      <option value="Italian" />
    </datalist>
  </div>
</template>

<style scoped>
/* ─── Page Container & Header ─── */
.employee-create-page {
  padding: 16px 28px 48px;
  background-color: #fafafa;
  min-height: calc(100vh - 60px);
  font-family: inherit;
}

.create-header-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.breadcrumb-strip {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
}

.bc-home-icon {
  color: #737373;
  display: flex;
  align-items: center;
  transition: color 0.15s ease;
}
.bc-home-icon:hover {
  color: #0B529C;
}

.bc-sep {
  color: #94a3b8;
}

.bc-link {
  color: #737373;
  text-decoration: none;
  font-weight: 400;
  transition: color 0.15s ease;
}
.bc-link:hover {
  color: #0B529C;
}

.bc-current {
  color: #404040;
  font-weight: 500;
}

.state-pill {
  padding: 2px 8px;
  font-size: 11px;
  font-weight: 500;
  border-radius: 12px;
  margin-left: 4px;
}

.state-unsaved {
  background-color: #fef3c7;
  color: #b45309;
}

.state-saved {
  background-color: #ecfdf5;
  color: #059669;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-clear-action {
  height: 38px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 0 16px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-clear-action:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.btn-save-action {
  height: 38px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0 24px;
  background: #0B529C;
  border: none;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  color: #ffffff;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-save-action:hover {
  background-color: #094482;
}

.create-tabs-wrapper {
  margin-bottom: 16px;
}

/* ─── Clean Card & Accordion Standards ─── */
.tab-content-container {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.clean-card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
}

.master-party-card {
  padding: 24px;
}

.card-accordion-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 16px 22px;
  cursor: pointer;
  user-select: none;
  background: #ffffff;
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
  transition: background-color 0.15s ease;
}
.card-accordion-header:hover {
  background-color: #fafafa;
}

.header-chevron {
  color: #64748b;
  flex-shrink: 0;
}

.card-accordion-divider {
  height: 1px;
  background-color: #f3f4f6;
  width: 100%;
}

.card-accordion-body {
  padding: 20px 24px;
  background-color: #ffffff;
}

.card-plain-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin-bottom: 4px;
}

.card-plain-desc {
  font-size: 12px;
  color: #737373;
  margin-bottom: 16px;
  line-height: 1.4;
}

.sub-section-title {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
  margin-bottom: 2px;
}

.sub-section-desc {
  font-size: 11.5px;
  color: #737373;
  margin-bottom: 10px;
}

/* ─── Master Card Specifics (Avatar, ID, Subtitle) ─── */
.avatar-photo-row {
  display: flex;
  align-items: center;
  gap: 18px;
  margin-bottom: 22px;
}

.avatar-circle-box {
  width: 90px;
  height: 90px;
  border-radius: 50%;
  background-color: #f4f5f7;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  flex-shrink: 0;
}

.avatar-circle-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.no-media-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.no-media-icon {
  color: #9ca3af;
}

.no-media-text {
  font-size: 11px;
  color: #9ca3af;
  margin-top: 3px;
  font-weight: 500;
}

.avatar-meta-col {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 6px;
}

.hidden-file-input {
  display: none;
}

.btn-upload-photo {
  height: 34px;
  padding: 0 14px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-upload-photo:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.avatar-advice-text {
  font-size: 12px;
  color: #737373;
  line-height: 1.4;
}

/* National ID Verification Row */
.national-id-row {
  margin-bottom: 20px;
}

.national-id-input-group {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 4px;
}

.id-input-wrap {
  width: 320px;
  flex: none;
}

.standard-text-input {
  width: 100%;
  height: 38px;
  padding: 0 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  color: #404040;
  outline: none;
  background: #ffffff;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}
.standard-text-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.disabled-input {
  background-color: #f8fafc;
  color: #94a3b8;
  cursor: not-allowed;
}

.btn-verify-id {
  height: 38px;
  padding: 0 18px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.15s ease;
}
.btn-verify-id:hover:not(:disabled) {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}
.btn-verify-id:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  color: #94a3b8;
}

.id-verified-subtext {
  font-size: 12px;
  color: #059669;
  margin-top: 4px;
  font-weight: 500;
}

.section-subtitle {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
  margin-bottom: 12px;
}

/* ─── Form Control Elements ─── */
.form-field-wrap {
  display: flex;
  flex-direction: column;
  gap: 3px;
  width: 100%;
}

.field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  user-select: none;
  display: inline-flex;
  align-items: center;
  line-height: 1.2;
}

.required-asterisk {
  color: #e11d48;
  margin-left: 2px;
}

/* Composite Phone Input */
.phone-composite-input {
  display: flex;
  align-items: center;
  height: 38px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #ffffff;
  overflow: hidden;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}
.phone-composite-input:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.country-pill-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 0 10px;
  height: 100%;
  border-right: 1px solid #e2e8f0;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  background: #f8fafc;
  user-select: none;
  cursor: pointer;
}

.phone-field-inner {
  flex: 1;
  height: 100%;
  border: none;
  outline: none;
  padding: 0 12px;
  font-size: 13.5px;
  color: #404040;
  background: transparent;
}

/* Composite Date Input */
.date-composite-input {
  display: flex;
  align-items: center;
  height: 38px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #ffffff;
  padding: 0 10px;
  position: relative;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}
.date-composite-input:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.date-cal-icon {
  color: #94a3b8;
  flex-shrink: 0;
  margin-right: 6px;
}

.date-field-inner {
  flex: 1;
  height: 100%;
  border: none;
  outline: none;
  font-size: 13px;
  color: #404040;
  background: transparent;
}

.gc-badge {
  font-size: 11px;
  font-weight: 600;
  color: #64748b;
  background: #f1f5f9;
  padding: 2px 6px;
  border-radius: 4px;
  user-select: none;
}

/* ─── Form Grids ─── */
.form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}

.form-grid-4 {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

/* ─── Card Internal Row Divider ─── */
.card-row-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 16px 0;
  width: 100%;
}

.child-sub-section {
  margin-top: 6px;
}

.child-sub-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.child-sub-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 2px 0;
}

.child-sub-desc {
  font-size: 12px;
  color: #737373;
  margin: 0;
}

.gross-summary-pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #f0fdf4;
  border: 1px solid #bbf7d0;
  padding: 4px 12px;
  border-radius: 9999px;
  font-size: 12px;
}

.gross-summary-label {
  color: #166534;
  font-weight: 500;
}

.gross-summary-value {
  color: #15803d;
  font-weight: 600;
}

/* ─── Scanned Signature & Digital Draw Canvas ─── */
.scanned-sig-wrapper {
  max-width: 540px;
}

.sig-mode-switch {
  display: flex;
  align-items: center;
  gap: 4px;
  background-color: #f1f5f9;
  padding: 3px;
  border-radius: 8px;
}

.sig-tab-btn {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 4px 10px;
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
  border-radius: 6px;
  border: none;
  background: transparent;
  cursor: pointer;
  transition: all 0.15s ease;
}

.sig-tab-btn:hover {
  color: #0f172a;
}

.sig-tab-btn.active {
  background-color: #ffffff;
  color: #0B529C;
  font-weight: 600;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}

.sig-draw-container {
  margin-top: 4px;
}

.sig-canvas-wrapper {
  border: 1px solid #cbd5e1;
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: inset 0 1px 2px rgba(0,0,0,0.03);
  position: relative;
  overflow: hidden;
}

.sig-canvas {
  display: block;
  width: 100%;
  height: 130px;
  background: #ffffff;
  cursor: crosshair;
}

.btn-adopt-sig {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 12px;
  font-weight: 600;
  padding: 6px 12px;
  border-radius: 8px;
  border: none;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-adopt-sig:hover {
  background-color: #083c74;
}

.btn-secondary-sm {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  background-color: #f1f5f9;
  color: #475569;
  font-size: 12px;
  font-weight: 500;
  padding: 6px 12px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-secondary-sm:hover {
  background-color: #e2e8f0;
  color: #1e293b;
}

.date-composite-disabled {
  display: flex;
  align-items: center;
  height: 38px;
  padding: 0 12px;
  background-color: #f8fafc;
  border: 1px dashed #cbd5e1;
  border-radius: 8px;
  margin-top: 4px;
}

.scanned-sig-dropzone {
  border: 1px dashed #cbd5e1;
  background-color: #f8fafc;
  border-radius: 8px;
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  cursor: pointer;
  transition: all 0.15s ease;
  min-height: 90px;
  margin-top: 4px;
}
.scanned-sig-dropzone:hover {
  background-color: #f1f5f9;
  border-color: #94a3b8;
}

.sig-empty-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.sig-upload-icon {
  color: #64748b;
  margin-bottom: 2px;
}

.sig-upload-text {
  font-size: 13px;
  color: #404040;
}

.sig-upload-subtext {
  font-size: 11.5px;
  color: #737373;
}

.sig-preview-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.sig-preview-img {
  max-height: 52px;
  object-fit: contain;
}

.sig-replace-link {
  font-size: 11.5px;
  color: #0B529C;
  font-weight: 500;
}

/* ─── WYSIWYG Rich Text Box ─── */
.wysiwyg-editor-box {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  background: #ffffff;
  margin-top: 4px;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}
.wysiwyg-editor-box:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.wysiwyg-toolbar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 4px;
  padding: 6px 10px;
  background: #ffffff;
  border-bottom: 1px solid #f1f5f9;
}

.toolbar-select {
  height: 26px;
  padding: 0 6px;
  font-size: 12px;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  color: #404040;
  background: #ffffff;
  outline: none;
}

.toolbar-divider {
  width: 1px;
  height: 18px;
  background-color: #e2e8f0;
  margin: 0 4px;
}

.tb-btn {
  height: 26px;
  width: 26px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  border: none;
  background: transparent;
  color: #64748b;
  cursor: pointer;
  font-size: 12.5px;
  transition: all 0.1s ease;
}
.tb-btn:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.toolbar-spacer {
  flex: 1;
}

.wysiwyg-textarea {
  width: 100%;
  min-height: 140px;
  padding: 12px;
  border: none;
  outline: none;
  font-size: 13.5px;
  color: #404040;
  font-family: inherit;
  resize: vertical;
}

.wysiwyg-status-bar {
  padding: 6px 12px;
  font-size: 11.5px;
  color: #737373;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-top: 1px solid #f8fafc;
}

/* ─── Compensation Callout & Helper (Bullet style matching Screenshot 1) ─── */
.gross-package-callout {
  background-color: #f8fafc;
  border: 1px solid #f1f5f9;
  border-radius: 10px;
  padding: 16px 20px;
  max-width: 440px;
  margin-top: 18px;
}

.gross-package-title {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 4px;
}

.gross-package-val {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
}

.grade-benchmark-note-clean {
  margin-top: 16px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.benchmark-line-main {
  font-size: 12px;
  font-weight: 500;
  color: #525252;
}

.benchmark-line-sub {
  font-size: 11.5px;
  color: #737373;
}

/* ─── Child Sub-Table Standards ─── */
.child-table-wrapper {
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  overflow: hidden;
  background: #ffffff;
  margin-top: 6px;
}

.child-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.child-table-header {
  background-color: #f8fafc;
  border-bottom: 1px solid #e5e7eb;
}

.child-th {
  padding: 8px 12px;
  font-size: 12px;
  font-weight: 500;
  color: #404040;
  border-right: 1px solid #e5e7eb;
  white-space: nowrap;
  user-select: none;
}
.child-th:last-child {
  border-right: none;
}

.child-th-check {
  width: 44px;
  text-align: center;
}

.child-th-no {
  width: 48px;
  text-align: center;
}

.child-th-col-icon {
  width: 48px;
  text-align: center;
}

.col-icon-svg {
  color: #94a3b8;
  margin: 0 auto;
}

.child-td-empty {
  padding: 34px 16px;
  text-align: center;
  font-size: 13px;
  font-weight: 500;
  color: #737373;
  background-color: #ffffff;
}

.child-tr {
  border-bottom: 1px solid #f1f5f9;
  transition: background-color 0.1s ease;
}
.child-tr:last-child {
  border-bottom: none;
}
.child-tr:hover {
  background-color: #fbfcfd;
}

.child-td {
  padding: 4px 8px;
  font-size: 12.5px;
  color: #404040;
  border-right: 1px solid #e5e7eb;
  vertical-align: middle;
}
.child-td:last-child {
  border-right: none;
}

.child-td-check {
  width: 44px;
  text-align: center;
}

.child-td-no {
  width: 48px;
  text-align: center;
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
}

.child-td-col-icon {
  width: 48px;
  text-align: center;
}

.table-checkbox {
  appearance: none;
  -webkit-appearance: none;
  width: 17px;
  height: 17px;
  min-width: 17px;
  min-height: 17px;
  border-radius: 5px;
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

.table-checkbox:hover:not(:checked):not(:disabled) {
  border-color: #9ca3af;
  background-color: #f9fafb;
}

.table-checkbox:checked {
  background-color: #0B529C;
  border-color: #0B529C;
  background-image: url("data:image/svg+xml,%3csvg viewBox='0 0 16 16' fill='none' stroke='white' stroke-width='2.6' stroke-linecap='round' stroke-linejoin='round' xmlns='http://www.w3.org/2000/svg'%3e%3cpolyline points='3.5 8.5 6.5 11.5 12.5 5.5'/%3e%3c/svg%3e");
  background-position: center;
  background-repeat: no-repeat;
  background-size: 75% 75%;
}

.table-checkbox:checked:hover:not(:disabled) {
  background-color: #094482;
  border-color: #094482;
}

.table-checkbox:indeterminate {
  background-color: #0B529C;
  border-color: #0B529C;
  background-image: url("data:image/svg+xml,%3csvg viewBox='0 0 16 16' fill='none' stroke='white' stroke-width='2.6' stroke-linecap='round' stroke-linejoin='round' xmlns='http://www.w3.org/2000/svg'%3e%3cline x1='3.5' y1='8' x2='12.5' y2='8'/%3e%3c/svg%3e");
  background-position: center;
  background-repeat: no-repeat;
  background-size: 75% 75%;
}

.table-checkbox:active:not(:disabled) {
  transform: scale(0.94);
}

.table-checkbox:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  border-color: #e5e7eb;
  background-color: #f3f4f6;
}

.child-inline-input {
  width: 100%;
  height: 30px;
  border: 1px solid transparent;
  border-radius: 4px;
  padding: 0 8px;
  font-size: 12.5px;
  color: #404040;
  background: transparent;
  outline: none;
  transition: all 0.15s ease;
}
.child-inline-input:hover {
  background-color: #f8fafc;
  border-color: #e2e8f0;
}
.child-inline-input:focus {
  background-color: #ffffff;
  border-color: #0B529C;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.08);
}

.inline-location-cell {
  display: flex;
  align-items: center;
  gap: 4px;
  width: 100%;
}

.location-input {
  flex: 1;
  min-width: 0;
}

.btn-inline-location-picker {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 22px;
  height: 22px;
  border-radius: 4px;
  border: 1px solid transparent;
  background: transparent;
  color: #0B529C;
  cursor: pointer;
  padding: 0;
  transition: all 0.15s ease;
  flex-shrink: 0;
}
.btn-inline-location-picker:hover {
  background: rgba(11, 82, 156, 0.08);
  border-color: rgba(11, 82, 156, 0.2);
}

.child-inline-select {
  width: 100%;
  height: 30px;
  border: 1px solid transparent;
  border-radius: 4px;
  padding: 0 6px;
  font-size: 12.5px;
  color: #404040;
  background: transparent;
  outline: none;
  cursor: pointer;
  transition: all 0.15s ease;
}
.child-inline-select:hover {
  background-color: #f8fafc;
  border-color: #e2e8f0;
}
.child-inline-select:focus {
  background-color: #ffffff;
  border-color: #0B529C;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.08);
}

.btn-row-expand {
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  padding: 4px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: all 0.15s ease;
}
.btn-row-expand:hover {
  color: #0f172a;
  background-color: #f1f5f9;
}

.col-icon-solid {
  color: #737373;
  margin: 0 auto;
  display: block;
}

.btn-add-row {
  height: 32px;
  padding: 0 14px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  margin-top: 10px;
  transition: all 0.15s ease;
}
.btn-add-row:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

/* ─── Address Cards Repeater (Matching User Settled Design) ─── */
.address-section-body {
  padding: 20px 24px 24px;
}

.address-cards-stack {
  display: flex;
  flex-direction: column;
  gap: 18px;
  margin-bottom: 18px;
}

.address-item-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 22px 24px;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.02);
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.address-item-card:hover {
  border-color: #cbd5e1;
}

.address-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}

.address-card-badge {
  display: inline-flex;
  align-items: center;
  padding: 3px 12px;
  background-color: #e0f2fe;
  color: #0284c7;
  font-size: 12px;
  font-weight: 500;
  border-radius: 9999px;
  letter-spacing: 0.01em;
}

.btn-delete-address-card {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #94a3b8;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-delete-address-card:hover {
  color: #ef4444;
  background-color: #fee2e2;
}

.address-form-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
  margin-bottom: 16px;
}

@media (max-width: 768px) {
  .address-form-grid {
    grid-template-columns: 1fr;
  }
}

.address-form-group {
  display: flex;
  flex-direction: column;
}

.address-field-label {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 6px;
}

.address-field-select {
  height: 38px;
  padding: 0 12px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
  cursor: pointer;
  transition: all 0.15s ease;
}

.address-field-select:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.address-field-input {
  height: 38px;
  padding: 0 12px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
  transition: all 0.15s ease;
}

.address-field-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.address-field-hint {
  font-size: 11.5px;
  color: #737373;
  margin-top: 4px;
  line-height: 1.4;
}

.address-primary-row {
  margin-top: 12px;
  padding-top: 4px;
}

.address-empty-state {
  padding: 24px;
  text-align: center;
  background: #f8fafc;
  border: 1px dashed #e2e8f0;
  border-radius: 10px;
  margin-bottom: 16px;
}

.btn-add-address-card {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 16px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-add-address-card:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.table-section-desc {
  font-size: 12px;
  color: #737373;
  line-height: 1.45;
  margin-bottom: 12px;
}

.field-hint-text {
  font-size: 11.5px;
  color: #737373;
  line-height: 1.45;
  margin-top: 4px;
}

/* ─── Special Provisions & Safeguards Tiles ─── */
.safeguard-card-tile {
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 16px 20px;
  background-color: #ffffff;
  margin-bottom: 14px;
  transition: border-color 0.15s ease;
}
.safeguard-card-tile:last-child {
  margin-bottom: 0;
}
.safeguard-card-tile.is-active {
  background-color: #ffffff;
  border-color: #cbd5e1;
}

.safeguard-tile-header {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  cursor: pointer;
  user-select: none;
}

.safeguard-checkbox-custom {
  margin-top: 3px;
  width: 16px;
  height: 16px;
  border-radius: 4px;
  accent-color: #0B529C;
  cursor: pointer;
}

.safeguard-tile-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.safeguard-tile-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.safeguard-tile-desc {
  font-size: 12px;
  color: #737373;
  line-height: 1.4;
}

.safeguard-expanded-body {
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid #e5e7eb;
}

.exemption-chips-row {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.exemption-rule-chip {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 14px;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  cursor: pointer;
  user-select: none;
  transition: all 0.15s ease;
}

.exemption-rule-chip:hover {
  background-color: #f1f5f9;
  border-color: #cbd5e1;
}

.exemption-rule-chip.is-selected {
  background-color: #0B529C;
  color: #ffffff;
  border-color: #0B529C;
}

.chip-check {
  color: #ffffff;
}

/* Ensure inputs inside active safeguard tile are white */
.safeguard-card-tile :deep(.form-input),
.safeguard-card-tile :deep(.form-select),
.safeguard-card-tile .date-composite-input,
.safeguard-card-tile .wysiwyg-editor-box,
.safeguard-card-tile .compact-upload-bar,
.safeguard-card-tile .number-spinner-col {
  background-color: #ffffff;
}

/* ─── Compact Upload Bar System (Sleek, Small & Minimalist) ─── */
.compact-upload-wrapper {
  display: flex;
  flex-direction: column;
  gap: 3px;
  width: 100%;
}

.compact-upload-bar {
  border: 1px dashed #cbd5e1;
  background-color: #ffffff;
  border-radius: 8px;
  padding: 6px 14px;
  min-height: 40px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: pointer;
  transition: all 0.15s ease;
}
.compact-upload-bar:hover {
  background-color: #f8fafc;
  border-color: #94a3b8;
}

.compact-upload-prompt {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  gap: 12px;
}

.compact-cloud-icon {
  color: #0B529C;
  flex-shrink: 0;
}

.compact-prompt-text {
  font-size: 12.5px;
  color: #525252;
}

.compact-link {
  color: #0B529C;
  font-weight: 500;
}

.compact-format-tag {
  font-size: 11px;
  color: #94a3b8;
  background: #f1f5f9;
  padding: 2px 7px;
  border-radius: 4px;
  margin-left: 6px;
  font-weight: 500;
}

.compact-browse-pill {
  font-size: 11.5px;
  font-weight: 500;
  color: #404040;
  background-color: #f1f5f9;
  padding: 3px 10px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
  flex-shrink: 0;
  transition: background-color 0.15s ease;
}
.compact-upload-bar:hover .compact-browse-pill {
  background-color: #e2e8f0;
}

.compact-upload-attached {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}

.compact-attached-name {
  font-size: 12.5px;
  font-weight: 600;
  color: #059669;
}

.compact-attached-thumb {
  height: 28px;
  max-width: 90px;
  object-fit: contain;
  border-radius: 4px;
  border: 1px solid #e2e8f0;
  padding: 1px 4px;
  background: #ffffff;
  margin-left: 8px;
}

.compact-action-btn {
  font-size: 11.5px;
  font-weight: 500;
  color: #0B529C;
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 2px 6px;
  text-decoration: underline;
}
.compact-action-btn:hover {
  color: #0c65bd;
}

/* ─── Expand Row Modal System (Matching Screenshot 2) ─── */
.row-modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  background-color: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(2px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
}

.row-modal-container {
  background-color: #ffffff;
  border-radius: 16px;
  width: 100%;
  max-width: 760px;
  max-height: 88vh;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  animation: modalFadeIn 0.15s ease-out;
}

@keyframes modalFadeIn {
  from {
    opacity: 0;
    transform: scale(0.97);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.row-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px 16px;
  background-color: #ffffff;
}

.row-modal-title {
  margin: 0;
  font-size: 16.5px;
  font-weight: 600;
  color: #404040;
}

.btn-modal-close {
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  padding: 6px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}
.btn-modal-close:hover {
  color: #0f172a;
  background-color: #f1f5f9;
}

.row-modal-body {
  padding: 8px 24px 24px;
  overflow-y: auto;
  flex: 1;
}

.modal-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.modal-form-group {
  display: flex;
  flex-direction: column;
}

.modal-form-group.col-span-2 {
  grid-column: span 2 / span 2;
}

.modal-form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 4px;
}

.modal-form-hint {
  font-size: 11.5px;
  color: #737373;
  line-height: 1.45;
  margin-top: 4px;
}

.modal-form-input {
  height: 38px;
  padding: 0 12px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
  transition: all 0.15s ease;
}
.modal-form-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.modal-form-select {
  height: 38px;
  padding: 0 12px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
  cursor: pointer;
  transition: all 0.15s ease;
}
.modal-form-select:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.modal-form-textarea {
  padding: 8px 12px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
  resize: vertical;
  min-height: 72px;
  font-family: inherit;
  transition: all 0.15s ease;
}
.modal-form-textarea:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.modal-form-help {
  font-size: 11.5px;
  color: #737373;
  margin-top: 4px;
}

/* ─── Exact Geographic Location Picker Card ─── */
.location-picker-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 16px;
  margin-bottom: 2px;
}

.location-picker-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-bottom: 12px;
  margin-bottom: 14px;
  border-bottom: 1px solid #e2e8f0;
}

.location-header-title {
  display: flex;
  align-items: center;
  gap: 7px;
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.location-pin-icon {
  color: #0B529C;
}

.location-breadcrumb-badge {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 3px 10px;
  background: rgba(11, 82, 156, 0.08);
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  color: #0B529C;
  max-width: 65%;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.breadcrumb-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #0B529C;
  flex-shrink: 0;
}

.breadcrumb-text {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.location-picker-body {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.row-modal-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 24px;
  background-color: #f8fafc;
  border-top: 1px solid #f1f5f9;
}

.btn-modal-delete {
  background-color: #ef4444;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  padding: 8px 18px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-modal-delete:hover {
  background-color: #dc2626;
}

.row-modal-actions-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-modal-ctrl-icon {
  width: 34px;
  height: 34px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-modal-ctrl-icon:hover:not(:disabled) {
  background-color: #f1f5f9;
  color: #0f172a;
}
.btn-modal-ctrl-icon:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.btn-modal-ctrl-action {
  height: 34px;
  padding: 0 12px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-modal-ctrl-action:hover {
  background-color: #f1f5f9;
  color: #0f172a;
  border-color: #cbd5e1;
}

/* ─── Standalone Form Checkbox Item (Matches Component Pattern) ─── */
.field-checkbox-item {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  max-width: 50%;
  cursor: pointer;
  user-select: none;
}

.custom-squircle-check {
  margin-top: 2px;
  width: 17px;
  height: 17px;
  border-radius: 5px;
  border: 1.5px solid #d1d5db;
  background-color: #ffffff;
  cursor: pointer;
  flex-shrink: 0;
  appearance: none;
  -webkit-appearance: none;
  display: grid;
  place-content: center;
  transition: all 0.15s ease;
}

.custom-squircle-check:hover:not(:checked):not(:disabled) {
  border-color: #9ca3af;
  background-color: #f9fafb;
}

.custom-squircle-check:checked {
  background-color: #0B529C;
  border-color: #0B529C;
  background-image: url("data:image/svg+xml,%3csvg viewBox='0 0 16 16' fill='none' stroke='white' stroke-width='2.6' stroke-linecap='round' stroke-linejoin='round' xmlns='http://www.w3.org/2000/svg'%3e%3cpolyline points='3.5 8.5 6.5 11.5 12.5 5.5'/%3e%3c/svg%3e");
  background-position: center;
  background-repeat: no-repeat;
  background-size: 75% 75%;
}

.custom-squircle-check:checked:hover:not(:disabled) {
  background-color: #094482;
  border-color: #094482;
}

.custom-squircle-check:active:not(:disabled) {
  transform: scale(0.94);
}

.field-checkbox-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
  cursor: pointer;
}

.field-checkbox-title {
  font-size: 13.5px;
  font-weight: 500;
  color: #262626;
  line-height: 1.35;
}

.field-checkbox-desc {
  font-size: 12px;
  color: #737373;
  line-height: 1.45;
}

/* ─── Dynamic Position Guarantee Requirement Alerts & Badges ─── */
.tile-guarantee-badge {
  font-size: 11px;
  font-weight: 600;
  color: #b45309;
  background-color: #fef3c7;
  border: 1px solid #fde68a;
  padding: 1px 7px;
  border-radius: 4px;
}

.guarantee-requirement-banner {
  display: flex;
  gap: 12px;
  padding: 12px 16px;
  background-color: #fffbeb;
  border: 1px solid #fde68a;
  border-radius: 8px;
}
.banner-icon-col {
  flex-shrink: 0;
  margin-top: 1px;
}
.banner-body {
  display: flex;
  flex-direction: column;
  gap: 4px;
  flex: 1;
}
.banner-top-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 8px;
}
.banner-title-group {
  display: flex;
  align-items: center;
  gap: 8px;
}
.banner-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #92400e;
}
.banner-role-tag {
  font-size: 11.5px;
  font-weight: 600;
  background-color: #fef3c7;
  color: #b45309;
  padding: 1px 8px;
  border-radius: 5px;
  border: 1px solid #fcd34d;
}
.banner-amount-badge {
  font-size: 12px;
  font-weight: 700;
  color: #b45309;
  background: #ffffff;
  padding: 2px 10px;
  border-radius: 6px;
  border: 1px solid #fde68a;
}
.banner-reason {
  font-size: 12px;
  color: #78350f;
  line-height: 1.4;
  margin: 0;
}
.banner-footer-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 4px;
}
.banner-apply-btn {
  font-size: 12px;
  font-weight: 600;
  background-color: #b45309;
  color: #ffffff;
  padding: 4px 12px;
  border-radius: 6px;
  border: none;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.banner-apply-btn:hover {
  background-color: #92400e;
}
.banner-satisfied-pill {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: 11.5px;
  font-weight: 600;
  color: #065f46;
  background-color: #d1fae5;
  padding: 2px 8px;
  border-radius: 5px;
  border: 1px solid #a7f3d0;
}
.guarantee-optional-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  background-color: #f0f9ff;
  border: 1px solid #bae6fd;
  border-radius: 8px;
  font-size: 12px;
  color: #0369a1;
}
</style>
