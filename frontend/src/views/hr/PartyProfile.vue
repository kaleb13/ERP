<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { 
  Users, UserCheck, Plus, Search, Filter, ArrowUpDown, ChevronDown, 
  MapPin, Heart, GraduationCap, Award, Briefcase, Sparkles, Languages, 
  MoreVertical, Edit2, Trash2, Eye, Copy, Check, Phone, Mail, Globe, 
  Building2, ShieldCheck, FileText, Calendar, CheckCircle2, AlertCircle, 
  Layers, ExternalLink, X, PlusCircle, UserPlus, Info, ChevronLeft, ArrowDown, ArrowUp
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import BaseTabs from '../../components/BaseTabs.vue';
import UnderlineTabs from '../../components/UnderlineTabs.vue';
import MetricCard from '../../components/MetricCard.vue';
import BaseButton from '../../components/BaseButton.vue';
import BasePagination from '../../components/BasePagination.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';

// ─── Lookups & Types ───
export type BloodGroup = 'a_pos' | 'a_neg' | 'b_pos' | 'b_neg' | 'ab_pos' | 'ab_neg' | 'o_pos' | 'o_neg' | 'unknown';
export type GenderType = 'male' | 'female';
export type MaritalStatus = 'single' | 'married' | 'divorced' | 'widowed';
export type NationalityType = 'citizen' | 'resident_foreigner' | 'non_resident_foreigner' | 'dual_citizen';
export type AddressType = 'residence' | 'postal' | 'work' | 'emergency' | 'birth_place' | 'other';
export type DependentRelation = 'spouse' | 'child' | 'parent' | 'sibling' | 'other';
export type QualificationLevel = 'primary' | 'secondary' | 'tvet_certificate' | 'diploma' | 'bachelors' | 'masters' | 'phd';
export type EmploymentType = 'permanent' | 'contract' | 'temporary' | 'probation' | 'part_time' | 'intern' | 'consultant';
export type SkillProficiency = 'beginner' | 'intermediate' | 'advanced' | 'expert';
export type LanguageProficiency = 'basic' | 'conversational' | 'fluent' | 'native';
export type LanguageSkillLevel = 'none' | 'basic' | 'intermediate' | 'advanced' | 'native';
export type RowState = 'active' | 'inactive';

export interface PartyDetail {
  id: number;
  uuid: string;
  party_id: number;
  party_name: string;
  code: string;
  avatar?: string;
  email?: string;
  phone?: string;
  fayda_id?: string;
  gender_lookup_value_id: GenderType;
  blood_group_lookup_value_id: BloodGroup;
  birth_date: string;
  birth_place: string;
  nationality_country_id: string; // ISO code 'ET', 'KE', 'US'
  nationality_type_lookup_value_id: NationalityType;
  marital_status_lookup_value_id: MaritalStatus;
  state: RowState;
}

export interface PartyAddress {
  id: number;
  uuid: string;
  party_id: number;
  address_type_lookup_value_id: AddressType;
  admin_unit_id: string; // e.g. '305 (Bole)', '312 (Kirkos)'
  line: string;
  house_number: string;
  kebele: string;
  postal_code: string;
  is_primary: boolean;
  effective_from?: string;
  effective_to?: string;
  state: RowState;
}

export interface PartyDependent {
  id: number;
  uuid: string;
  party_id: number;
  dependent_party_id: number;
  dependent_name: string;
  relation_lookup_value_id: DependentRelation;
  birth_date: string;
  is_beneficiary: boolean;
  benefit_notes?: string;
  state: RowState;
}

export interface PartyQualification {
  id: number;
  uuid: string;
  party_id: number;
  level_lookup_value_id: QualificationLevel;
  field_of_study_name: string;
  institution_name: string;
  start_date?: string;
  graduation_date?: string;
  gpa?: number;
  state: RowState;
}

export interface PartyCertification {
  id: number;
  uuid: string;
  party_id: number;
  certification_name: string;
  issuing_institution_name: string;
  certificate_number: string;
  issued_date: string;
  expiry_date?: string;
  state: RowState;
}

export interface PartyExperience {
  id: number;
  uuid: string;
  party_id: number;
  employer_name: string;
  position_title: string;
  employment_type_lookup_value_id: EmploymentType;
  start_date: string;
  end_date?: string;
  responsibilities?: string;
  reason_for_leaving?: string;
  reference_person?: string;
  state: RowState;
}

export interface PartySkill {
  id: number;
  uuid: string;
  party_id: number;
  skill_name: string;
  proficiency_lookup_value_id: SkillProficiency;
  years_of_experience: number;
  state: RowState;
}

export interface PartyLanguage {
  id: number;
  uuid: string;
  party_id: number;
  language_name: string;
  proficiency_lookup_value_id: LanguageProficiency;
  speaking_level_lookup_value_id: LanguageSkillLevel;
  listening_level_lookup_value_id: LanguageSkillLevel;
  reading_level_lookup_value_id: LanguageSkillLevel;
  writing_level_lookup_value_id: LanguageSkillLevel;
  is_native: boolean;
  state: RowState;
}

// ─── Initial Seed Data ───
const initialParties: PartyDetail[] = [
  {
    id: 1,
    uuid: 'pty_101a-99b2',
    party_id: 101,
    party_name: 'Abebe Kebede',
    code: 'PTY-101',
    avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
    email: '',
    phone: '+251 922 235 458',
    fayda_id: '6535243542432',
    gender_lookup_value_id: 'male',
    blood_group_lookup_value_id: 'o_pos',
    birth_date: '1989-05-12',
    birth_place: 'Addis Ababa',
    nationality_country_id: 'ET',
    nationality_type_lookup_value_id: 'citizen',
    marital_status_lookup_value_id: 'married',
    state: 'active'
  },
  {
    id: 2,
    uuid: 'pty_102b-88c3',
    party_id: 102,
    party_name: 'Kidst Tesfaye',
    code: 'PTY-102',
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    email: 'kidst21@gmail.com',
    phone: '+251 922 235 458',
    fayda_id: '6535243542432',
    gender_lookup_value_id: 'female',
    blood_group_lookup_value_id: 'a_pos',
    birth_date: '1995-10-20',
    birth_place: 'Hawassa',
    nationality_country_id: 'ET',
    nationality_type_lookup_value_id: 'citizen',
    marital_status_lookup_value_id: 'single',
    state: 'active'
  },
  {
    id: 3,
    uuid: 'pty_103c-77d4',
    party_id: 103,
    party_name: 'Mihret Abera',
    code: 'PTY-103',
    avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
    email: 'mihret18@gmail.com',
    phone: '+251 922 235 458',
    fayda_id: '6535243542432',
    gender_lookup_value_id: 'female',
    blood_group_lookup_value_id: 'b_neg',
    birth_date: '1992-03-14',
    birth_place: 'Bahir Dar',
    nationality_country_id: 'ET',
    nationality_type_lookup_value_id: 'citizen',
    marital_status_lookup_value_id: 'single',
    state: 'inactive'
  },
  {
    id: 4,
    uuid: 'pty_431d-66e5',
    party_id: 431,
    party_name: 'Yared Tsegaye',
    code: 'PTY-431',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    email: 'yared.t@haletaerp.com',
    phone: '+251 94 555 1290',
    fayda_id: 'ET-FAYDA-3104928',
    gender_lookup_value_id: 'male',
    blood_group_lookup_value_id: 'o_neg',
    birth_date: '1988-07-09',
    birth_place: 'Bahir Dar',
    nationality_country_id: 'ET',
    nationality_type_lookup_value_id: 'citizen',
    marital_status_lookup_value_id: 'divorced',
    state: 'active'
  },
  {
    id: 5,
    uuid: 'pty_544e-55f6',
    party_id: 544,
    party_name: 'Amina Mohammed',
    code: 'PTY-544',
    avatar: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=150&auto=format&fit=crop&q=80',
    email: 'amina.m@haletaerp.com',
    phone: '+251 93 210 9988',
    fayda_id: 'KE-RES-990214',
    gender_lookup_value_id: 'female',
    blood_group_lookup_value_id: 'ab_pos',
    birth_date: '1985-03-15',
    birth_place: 'Nairobi',
    nationality_country_id: 'KE',
    nationality_type_lookup_value_id: 'resident_foreigner',
    marital_status_lookup_value_id: 'married',
    state: 'active'
  }
];

const initialAddresses: PartyAddress[] = [
  { id: 1, uuid: 'addr_1', party_id: 107, address_type_lookup_value_id: 'residence', admin_unit_id: '305 (Bole)', line: 'Cameroon St.', house_number: '214', kebele: '08', postal_code: '1000', is_primary: true, effective_from: '2022-01-10', state: 'active' },
  { id: 2, uuid: 'addr_2', party_id: 107, address_type_lookup_value_id: 'postal', admin_unit_id: '305 (Bole)', line: 'P.O.Box 1176', house_number: '-', kebele: '-', postal_code: '1176', is_primary: true, effective_from: '2022-01-10', state: 'active' },
  { id: 3, uuid: 'addr_3', party_id: 214, address_type_lookup_value_id: 'residence', admin_unit_id: '312 (Kirkos)', line: 'Wollo Sefer', house_number: '77/A', kebele: '03', postal_code: '1000', is_primary: true, effective_from: '2024-06-01', state: 'active' },
  { id: 4, uuid: 'addr_4', party_id: 322, address_type_lookup_value_id: 'residence', admin_unit_id: '401 (Bahir Dar)', line: 'Kebele 14 road', house_number: '9', kebele: '14', postal_code: '6000', is_primary: true, effective_from: '2021-09-15', state: 'active' },
  { id: 5, uuid: 'addr_5', party_id: 107, address_type_lookup_value_id: 'emergency', admin_unit_id: '305 (Bole)', line: 'Behind Edna Mall', house_number: '42', kebele: '08', postal_code: '1000', is_primary: true, state: 'active' }
];

const initialDependents: PartyDependent[] = [
  { id: 1, uuid: 'dep_1', party_id: 107, dependent_party_id: 611, dependent_name: 'Solomon Bekele', relation_lookup_value_id: 'spouse', birth_date: '1991-08-04', is_beneficiary: true, benefit_notes: 'Haleta Health Plus: Policy #HP-99018', state: 'active' },
  { id: 2, uuid: 'dep_2', party_id: 107, dependent_party_id: 612, dependent_name: 'Naol Solomon', relation_lookup_value_id: 'child', birth_date: '2019-12-01', is_beneficiary: true, benefit_notes: 'Child Wellness Plan coverage included', state: 'active' },
  { id: 3, uuid: 'dep_3', party_id: 322, dependent_party_id: 613, dependent_name: 'Eyob Daniel', relation_lookup_value_id: 'child', birth_date: '2016-04-22', is_beneficiary: true, benefit_notes: 'Standard Medical Plan coverage', state: 'active' },
  { id: 4, uuid: 'dep_4', party_id: 544, dependent_party_id: 614, dependent_name: 'Kiprono Koech', relation_lookup_value_id: 'spouse', birth_date: '1985-10-10', is_beneficiary: true, benefit_notes: 'Expat Spouse Comprehensive Plan', state: 'active' },
  { id: 5, uuid: 'dep_5', party_id: 431, dependent_party_id: 615, dependent_name: 'Tsegaye Demisse', relation_lookup_value_id: 'parent', birth_date: '1966-02-14', is_beneficiary: false, benefit_notes: 'Emergency Contact only (Non-dependent)', state: 'active' }
];

const initialQualifications: PartyQualification[] = [
  { id: 1, uuid: 'qual_1', party_id: 322, level_lookup_value_id: 'bachelors', field_of_study_name: 'Accounting', institution_name: 'Addis Ababa University (AAU)', start_date: '2010-09-20', graduation_date: '2014-07-05', gpa: 3.40, state: 'active' },
  { id: 2, uuid: 'qual_2', party_id: 544, level_lookup_value_id: 'masters', field_of_study_name: 'Finance & Investment', institution_name: 'Addis Ababa University (AAU)', start_date: '2010-09-15', graduation_date: '2012-07-07', gpa: 3.80, state: 'active' },
  { id: 3, uuid: 'qual_3', party_id: 107, level_lookup_value_id: 'bachelors', field_of_study_name: 'Human Resource Management', institution_name: 'Bahir Dar University (BDU)', start_date: '2012-09-10', graduation_date: '2016-07-02', gpa: 3.10, state: 'active' },
  { id: 4, uuid: 'qual_4', party_id: 214, level_lookup_value_id: 'diploma', field_of_study_name: 'Marketing Management', institution_name: 'Admas University', start_date: '2020-09-01', graduation_date: '2022-06-25', gpa: 3.00, state: 'active' },
  { id: 5, uuid: 'qual_5', party_id: 431, level_lookup_value_id: 'tvet_certificate', field_of_study_name: 'Supply Chain & Logistics', institution_name: 'Entoto TVET College', start_date: '2017-09-04', graduation_date: '2019-06-30', gpa: 3.65, state: 'active' }
];

const initialCertifications: PartyCertification[] = [
  { id: 1, uuid: 'cert_1', party_id: 322, certification_name: 'ACCA (Chartered Certified Accountant)', issuing_institution_name: 'ACCA Global', certificate_number: 'ACCA-1188220', issued_date: '2019-06-15', state: 'active' },
  { id: 2, uuid: 'cert_2', party_id: 544, certification_name: 'CPA (Certified Public Accountant)', issuing_institution_name: 'AABE (Accounting & Auditing Board of Ethiopia)', certificate_number: 'CPA-ET-4415', issued_date: '2015-09-01', state: 'active' },
  { id: 3, uuid: 'cert_3', party_id: 214, certification_name: 'Food Handler & Safety Compliance', issuing_institution_name: 'AA Food & Drug Authority', certificate_number: 'FH-2024-88412', issued_date: '2024-06-20', expiry_date: '2026-06-20', state: 'active' },
  { id: 4, uuid: 'cert_4', party_id: 431, certification_name: 'Procurement Specialist Certificate', issuing_institution_name: 'Federal Public Procurement Agency (PPA)', certificate_number: 'PPA-2023-1120', issued_date: '2023-04-10', expiry_date: '2027-04-10', state: 'active' },
  { id: 5, uuid: 'cert_5', party_id: 107, certification_name: 'Certified HR Professional (CHRP)', issuing_institution_name: 'Ethiopian Management Institute', certificate_number: 'EMI-HR-0450', issued_date: '2021-11-05', state: 'active' }
];

const initialExperiences: PartyExperience[] = [
  { id: 1, uuid: 'exp_1', party_id: 322, employer_name: 'Zemen Bank S.C.', position_title: 'Junior Accountant', employment_type_lookup_value_id: 'permanent', start_date: '2018-08-01', end_date: '2021-08-31', responsibilities: 'Managed branch cash registers, ledger reconciliation, and daily IFRS compliance reports.', reason_for_leaving: 'Career advancement and relocation to Haleta Group.', reference_person: 'Alemayehu T. (Branch Operations Mgr, +251 91 123 4567)', state: 'active' },
  { id: 2, uuid: 'exp_2', party_id: 544, employer_name: 'Awash Bank S.C.', position_title: 'Branch Accountant', employment_type_lookup_value_id: 'permanent', start_date: '2015-01-15', end_date: '2020-01-31', responsibilities: 'Supervised branch accounting transactions, internal audit preparations, and currency reconciliations.', reason_for_leaving: 'Transitioned to senior corporate role.', reference_person: 'Senait D. (Head of Audit, +251 92 987 6543)', state: 'active' },
  { id: 3, uuid: 'exp_3', party_id: 544, employer_name: 'Dashen Bank S.C.', position_title: 'Finance Analyst', employment_type_lookup_value_id: 'contract', start_date: '2020-02-15', end_date: '2022-02-28', responsibilities: 'Conducted commercial loan portfolio stress tests and quarterly macro-financial risk modeling.', reason_for_leaving: 'Completion of 2-year project consultancy term.', state: 'active' },
  { id: 4, uuid: 'exp_4', party_id: 214, employer_name: 'Shoa Supermarket PLC', position_title: 'Cashier & Front Counter Lead', employment_type_lookup_value_id: 'permanent', start_date: '2022-03-01', end_date: '2024-05-15', responsibilities: 'Handled POS settlements, barcode scanning inventory reconciliations, and customer billing inquiries.', reason_for_leaving: 'Joined Haleta retail logistics division.', reference_person: 'Mulugeta K. (+251 91 333 7777)', state: 'active' },
  { id: 5, uuid: 'exp_5', party_id: 431, employer_name: 'Kuriftu Resorts & Spa', position_title: 'Procurement Officer', employment_type_lookup_value_id: 'permanent', start_date: '2023-06-01', end_date: '2025-02-10', responsibilities: 'Coordinated vendor bidding, supplier negotiations, and hospitality consumable stock replenishment.', reason_for_leaving: 'Career growth opportunity in ERP procurement team.', state: 'active' }
];

const initialSkills: PartySkill[] = [
  { id: 1, uuid: 'skl_1', party_id: 322, skill_name: 'IFRS Financial Reporting', proficiency_lookup_value_id: 'advanced', years_of_experience: 5.0, state: 'active' },
  { id: 2, uuid: 'skl_2', party_id: 322, skill_name: 'Peachtree / Sage 50 Accounting', proficiency_lookup_value_id: 'expert', years_of_experience: 6.0, state: 'active' },
  { id: 3, uuid: 'skl_3', party_id: 214, skill_name: 'POS Operations & Cash Desk', proficiency_lookup_value_id: 'expert', years_of_experience: 2.0, state: 'active' },
  { id: 4, uuid: 'skl_4', party_id: 431, skill_name: 'Supplier Contract Negotiation', proficiency_lookup_value_id: 'intermediate', years_of_experience: 3.0, state: 'active' },
  { id: 5, uuid: 'skl_5', party_id: 107, skill_name: 'Labour Law & HR Compliance', proficiency_lookup_value_id: 'advanced', years_of_experience: 4.0, state: 'active' },
  { id: 6, uuid: 'skl_6', party_id: 544, skill_name: 'Financial Modeling & Valuation', proficiency_lookup_value_id: 'expert', years_of_experience: 8.5, state: 'active' }
];

const initialLanguages: PartyLanguage[] = [
  { id: 1, uuid: 'lng_1', party_id: 322, language_name: 'Amharic', proficiency_lookup_value_id: 'native', speaking_level_lookup_value_id: 'native', listening_level_lookup_value_id: 'native', reading_level_lookup_value_id: 'native', writing_level_lookup_value_id: 'native', is_native: true, state: 'active' },
  { id: 2, uuid: 'lng_2', party_id: 322, language_name: 'English', proficiency_lookup_value_id: 'fluent', speaking_level_lookup_value_id: 'advanced', listening_level_lookup_value_id: 'advanced', reading_level_lookup_value_id: 'advanced', writing_level_lookup_value_id: 'intermediate', is_native: false, state: 'active' },
  { id: 3, uuid: 'lng_3', party_id: 214, language_name: 'Afaan Oromo', proficiency_lookup_value_id: 'native', speaking_level_lookup_value_id: 'native', listening_level_lookup_value_id: 'native', reading_level_lookup_value_id: 'native', writing_level_lookup_value_id: 'advanced', is_native: true, state: 'active' },
  { id: 4, uuid: 'lng_4', party_id: 214, language_name: 'Amharic', proficiency_lookup_value_id: 'fluent', speaking_level_lookup_value_id: 'advanced', listening_level_lookup_value_id: 'advanced', reading_level_lookup_value_id: 'advanced', writing_level_lookup_value_id: 'advanced', is_native: false, state: 'active' },
  { id: 5, uuid: 'lng_5', party_id: 544, language_name: 'English', proficiency_lookup_value_id: 'conversational', speaking_level_lookup_value_id: 'intermediate', listening_level_lookup_value_id: 'intermediate', reading_level_lookup_value_id: 'advanced', writing_level_lookup_value_id: 'basic', is_native: false, state: 'active' },
  { id: 6, uuid: 'lng_6', party_id: 107, language_name: 'Amharic', proficiency_lookup_value_id: 'native', speaking_level_lookup_value_id: 'native', listening_level_lookup_value_id: 'native', reading_level_lookup_value_id: 'native', writing_level_lookup_value_id: 'native', is_native: true, state: 'active' },
  { id: 7, uuid: 'lng_7', party_id: 107, language_name: 'English', proficiency_lookup_value_id: 'fluent', speaking_level_lookup_value_id: 'fluent' as any, listening_level_lookup_value_id: 'fluent' as any, reading_level_lookup_value_id: 'fluent' as any, writing_level_lookup_value_id: 'advanced', is_native: false, state: 'active' }
];

// ─── Reactive State ───
const parties = ref<PartyDetail[]>([]);
const addresses = ref<PartyAddress[]>([]);
const dependents = ref<PartyDependent[]>([]);
const qualifications = ref<PartyQualification[]>([]);
const certifications = ref<PartyCertification[]>([]);
const experiences = ref<PartyExperience[]>([]);
const skills = ref<PartySkill[]>([]);
const languages = ref<PartyLanguage[]>([]);

// Storage Helper
const loadAllData = () => {
  const p = localStorage.getItem('haleta_erp_parties');
  parties.value = p ? JSON.parse(p) : initialParties;

  const a = localStorage.getItem('haleta_erp_addresses');
  addresses.value = a ? JSON.parse(a) : initialAddresses;

  const d = localStorage.getItem('haleta_erp_dependents');
  dependents.value = d ? JSON.parse(d) : initialDependents;

  const q = localStorage.getItem('haleta_erp_qualifications');
  qualifications.value = q ? JSON.parse(q) : initialQualifications;

  const c = localStorage.getItem('haleta_erp_certifications');
  certifications.value = c ? JSON.parse(c) : initialCertifications;

  const e = localStorage.getItem('haleta_erp_experiences');
  experiences.value = e ? JSON.parse(e) : initialExperiences;

  const s = localStorage.getItem('haleta_erp_skills');
  skills.value = s ? JSON.parse(s) : initialSkills;

  const l = localStorage.getItem('haleta_erp_languages');
  languages.value = l ? JSON.parse(l) : initialLanguages;
};

const saveAllData = () => {
  localStorage.setItem('haleta_erp_parties', JSON.stringify(parties.value));
  localStorage.setItem('haleta_erp_addresses', JSON.stringify(addresses.value));
  localStorage.setItem('haleta_erp_dependents', JSON.stringify(dependents.value));
  localStorage.setItem('haleta_erp_qualifications', JSON.stringify(qualifications.value));
  localStorage.setItem('haleta_erp_certifications', JSON.stringify(certifications.value));
  localStorage.setItem('haleta_erp_experiences', JSON.stringify(experiences.value));
  localStorage.setItem('haleta_erp_skills', JSON.stringify(skills.value));
  localStorage.setItem('haleta_erp_languages', JSON.stringify(languages.value));
};

onMounted(() => {
  loadAllData();
  window.addEventListener('click', closeActionMenu);
});

onUnmounted(() => {
  window.removeEventListener('click', closeActionMenu);
});

// ─── Primary Navigation (Master-Detail Mode) ───
const viewMode = ref<'list' | 'detail'>('list');

// ─── Selected Party State ───
const selectedPartyId = ref<number>(101);
const selectedParty = computed(() => {
  return parties.value.find(p => p.party_id === selectedPartyId.value) || parties.value[0] || null;
});

const selectPartyForDetail = (partyId: number) => {
  selectedPartyId.value = partyId;
  viewMode.value = 'detail';
};

const backToPartyList = () => {
  viewMode.value = 'list';
};

const breadcrumbItems = computed(() => {
  if (viewMode.value === 'detail' && selectedParty.value) {
    return [
      { label: 'Party Management', to: '/hr/parties', onClick: backToPartyList },
      { label: selectedParty.value.party_name }
    ];
  }
  return [
    { label: 'Party Management' }
  ];
});

// ─── Row Selection Checkbox State ───
const selectedRowIds = ref<number[]>([]);
const isAllSelected = computed(() => {
  return paginatedParties.value.length > 0 &&
    paginatedParties.value.every(item => selectedRowIds.value.includes(item.id));
});
const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = paginatedParties.value.map(item => item.id);
  }
};
const toggleRowSelection = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx >= 0) {
    selectedRowIds.value.splice(idx, 1);
  } else {
    selectedRowIds.value.push(id);
  }
};

// ─── Sub-Tabs for Profile Detail (UnderlineTabs) ───
type SubTabId = 'demographics' | 'addresses' | 'dependents' | 'qualifications' | 'certifications' | 'experiences' | 'skills_languages';
const activeSubTab = ref<SubTabId>('demographics');

// Computed Counts for UnderlineTabs
const partyAddresses = computed(() => addresses.value.filter(a => a.party_id === selectedPartyId.value));
const partyDependents = computed(() => dependents.value.filter(d => d.party_id === selectedPartyId.value));
const partyQualifications = computed(() => qualifications.value.filter(q => q.party_id === selectedPartyId.value));
const partyCertifications = computed(() => certifications.value.filter(c => c.party_id === selectedPartyId.value));
const partyExperiences = computed(() => experiences.value.filter(e => e.party_id === selectedPartyId.value));
const partySkills = computed(() => skills.value.filter(s => s.party_id === selectedPartyId.value));
const partyLanguages = computed(() => languages.value.filter(l => l.party_id === selectedPartyId.value));

const profileSubTabs = computed(() => [
  { id: 'demographics' as const, label: 'Demographics (1:1)', icon: Users },
  { id: 'addresses' as const, label: 'Addresses', count: partyAddresses.value.length, icon: MapPin },
  { id: 'dependents' as const, label: 'Dependents', count: partyDependents.value.length, icon: Heart },
  { id: 'qualifications' as const, label: 'Qualifications', count: partyQualifications.value.length, icon: GraduationCap },
  { id: 'certifications' as const, label: 'Certifications', count: partyCertifications.value.length, icon: Award },
  { id: 'experiences' as const, label: 'Work Experience', count: partyExperiences.value.length, icon: Briefcase },
  { id: 'skills_languages' as const, label: 'Skills & Languages', count: partySkills.value.length + partyLanguages.value.length, icon: Sparkles }
]);

// ─── Search, Filters & Sorting for Directory ───
const searchQuery = ref('');
const filterNationality = ref('All');
const filterGender = ref('All');
const filterMarital = ref('All');
const filterState = ref('All');

const currentSort = ref('state');
const sortOrder = ref<'asc' | 'desc'>('asc');

const toggleSortState = () => {
  if (currentSort.value === 'state') {
    sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
  } else {
    currentSort.value = 'state';
    sortOrder.value = 'asc';
  }
};

const sortOptions = [
  { key: 'name', label: 'Name' },
  { key: 'state', label: 'State' },
  { key: 'phone', label: 'Phone No.' }
];

const activeFilterCount = computed(() => {
  let count = 0;
  if (filterNationality.value !== 'All') count++;
  if (filterGender.value !== 'All') count++;
  if (filterMarital.value !== 'All') count++;
  if (filterState.value !== 'All') count++;
  return count;
});

const resetFilters = () => {
  filterNationality.value = 'All';
  filterGender.value = 'All';
  filterMarital.value = 'All';
  filterState.value = 'All';
  searchQuery.value = '';
};

// ─── Table Columns & Visibility (Minimalist + Column Hider Standard) ───
const tableColumns = ref<ColumnDef[]>([
  // Essential columns visible by default matching user design
  { key: 'name', label: 'Name', visible: true },
  { key: 'gender', label: 'Gender', visible: true },
  { key: 'phone', label: 'Phone No.', visible: true },
  { key: 'fayda_id', label: 'National ID', visible: true },
  { key: 'state', label: 'State', visible: true },

  // Secondary columns hidden by default, accessible in Column Hider menu
  { key: 'marital_status', label: 'Marital Status', visible: false },
  { key: 'blood_group', label: 'Blood Group', visible: false },
  { key: 'nationality_type', label: 'Nationality Type', visible: false },
  { key: 'country', label: 'Country', visible: false },
  { key: 'birth_date', label: 'Date of Birth', visible: false },
  { key: 'birth_place', label: 'Place of Birth', visible: false },
  { key: 'residence', label: 'Primary Residence', visible: false },
]);

const handleToggleColumn = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  if (col) {
    col.visible = col.visible === false ? true : false;
  }
};

const isColVisible = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  return col ? col.visible !== false : true;
};

const visibleColumnsCount = computed(() => {
  return tableColumns.value.filter(c => c.visible !== false).length;
});

const filteredParties = computed(() => {
  let list = parties.value.filter(item => {
    const q = searchQuery.value.toLowerCase().trim();
    const matchesSearch = !q ||
      item.party_name.toLowerCase().includes(q) ||
      item.code.toLowerCase().includes(q) ||
      (item.email && item.email.toLowerCase().includes(q)) ||
      (item.phone && item.phone.toLowerCase().includes(q)) ||
      (item.birth_place && item.birth_place.toLowerCase().includes(q)) ||
      (item.fayda_id && item.fayda_id.toLowerCase().includes(q));

    const matchesNat = filterNationality.value === 'All' || item.nationality_type_lookup_value_id === filterNationality.value;
    const matchesGen = filterGender.value === 'All' || item.gender_lookup_value_id === filterGender.value;
    const matchesMar = filterMarital.value === 'All' || item.marital_status_lookup_value_id === filterMarital.value;
    const matchesState = filterState.value === 'All' || item.state === filterState.value;

    return matchesSearch && matchesNat && matchesGen && matchesMar && matchesState;
  });

  if (currentSort.value === 'name') {
    list = [...list].sort((a, b) => sortOrder.value === 'asc' 
      ? a.party_name.localeCompare(b.party_name) 
      : b.party_name.localeCompare(a.party_name));
  } else if (currentSort.value === 'state') {
    list = [...list].sort((a, b) => sortOrder.value === 'asc'
      ? a.state.localeCompare(b.state)
      : b.state.localeCompare(a.state));
  }

  return list;
});

// Pagination
const currentPage = ref(1);
const perPage = ref(10);
const paginatedParties = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredParties.value.slice(start, start + perPage.value);
});

// Action Menu
const openMenuId = ref<number | null>(null);
const toggleActionMenu = (e: MouseEvent, id: number) => {
  e.stopPropagation();
  openMenuId.value = openMenuId.value === id ? null : id;
};
const closeActionMenu = () => {
  openMenuId.value = null;
};

// Copy helper
const copiedFaydaId = ref<number | null>(null);
const copyFayda = async (id: number, text: string) => {
  if (!text) return;
  await navigator.clipboard.writeText(text);
  copiedFaydaId.value = id;
  setTimeout(() => { copiedFaydaId.value = null; }, 1500);
};

// ─── Formatters & Badges ───
const formatBloodGroup = (bg: BloodGroup) => {
  if (!bg) return '-';
  const map: Record<string, string> = {
    a_pos: 'A+', a_neg: 'A-', b_pos: 'B+', b_neg: 'B-',
    ab_pos: 'AB+', ab_neg: 'AB-', o_pos: 'O+', o_neg: 'O-', unknown: 'Unknown'
  };
  return map[bg] || bg;
};

const formatNationalityType = (t: NationalityType) => {
  const map: Record<string, string> = {
    citizen: 'Citizen (National)',
    resident_foreigner: 'Resident Foreigner',
    non_resident_foreigner: 'Non-Resident Foreigner',
    dual_citizen: 'Dual Citizen'
  };
  return map[t] || t;
};

const getNationalityPillClass = (t: NationalityType) => {
  if (t === 'citizen') return 'pill-citizen';
  if (t === 'resident_foreigner') return 'pill-resident';
  if (t === 'dual_citizen') return 'pill-dual';
  return 'pill-foreigner';
};

const formatMaritalStatus = (m: MaritalStatus) => {
  return m ? m.charAt(0).toUpperCase() + m.slice(1) : '-';
};

const formatLevel = (lvl: QualificationLevel) => {
  const map: Record<string, string> = {
    primary: 'Primary School',
    secondary: 'Secondary (High School)',
    tvet_certificate: 'TVET Certificate',
    diploma: 'Diploma',
    bachelors: "Bachelor's Degree",
    masters: "Master's Degree",
    phd: 'Doctorate (Ph.D.)'
  };
  return map[lvl] || lvl;
};

// ─── Quick Create Party Modal (<= 5 Required Fields Standard) ───
const showQuickCreate = ref(false);
const quickForm = ref({
  party_name: '',
  gender_lookup_value_id: 'female' as GenderType,
  birth_date: '1995-01-01',
  nationality_type_lookup_value_id: 'citizen' as NationalityType,
  nationality_country_id: 'ET',
  birth_place: 'Addis Ababa',
  phone: '',
  marital_status_lookup_value_id: 'single' as MaritalStatus
});

const handleSaveQuickParty = () => {
  if (!quickForm.value.party_name) {
    alert('Please enter full party name.');
    return;
  }
  const nextId = parties.value.length ? Math.max(...parties.value.map(p => p.id)) + 1 : 1;
  const nextPartyId = parties.value.length ? Math.max(...parties.value.map(p => p.party_id)) + 1 : 600;

  const newParty: PartyDetail = {
    id: nextId,
    uuid: `pty_${nextPartyId}x-${Date.now().toString().slice(-4)}`,
    party_id: nextPartyId,
    party_name: quickForm.value.party_name,
    code: `PTY-${nextPartyId}`,
    phone: quickForm.value.phone || '+251 91 000 0000',
    email: `${quickForm.value.party_name.toLowerCase().replace(/\s+/g, '.')}@haletaerp.com`,
    fayda_id: `ET-FAYDA-${Math.floor(1000000 + Math.random() * 9000000)}`,
    gender_lookup_value_id: quickForm.value.gender_lookup_value_id,
    blood_group_lookup_value_id: 'o_pos',
    birth_date: quickForm.value.birth_date,
    birth_place: quickForm.value.birth_place,
    nationality_country_id: quickForm.value.nationality_country_id,
    nationality_type_lookup_value_id: quickForm.value.nationality_type_lookup_value_id,
    marital_status_lookup_value_id: quickForm.value.marital_status_lookup_value_id,
    state: 'active'
  };

  parties.value.unshift(newParty);
  saveAllData();
  showQuickCreate.value = false;
  selectPartyForDetail(newParty.party_id);
};

const router = useRouter();
const handleExpandPartyCreate = () => {
  showQuickCreate.value = false;
  router.push({
    path: '/hr/parties/create',
    query: {
      name: quickForm.value.party_name,
      phone: quickForm.value.phone,
      gender: quickForm.value.gender_lookup_value_id
    }
  });
};

// ─── Sub-Entity Creation Modals ───
const showAddAddressModal = ref(false);
const addressForm = ref({
  address_type_lookup_value_id: 'residence' as AddressType,
  admin_unit_id: '305 (Bole)',
  line: '',
  house_number: '',
  kebele: '',
  postal_code: '',
  is_primary: true
});

const handleSaveAddress = () => {
  const newAddr: PartyAddress = {
    id: addresses.value.length ? Math.max(...addresses.value.map(a => a.id)) + 1 : 1,
    uuid: `addr_${Date.now()}`,
    party_id: selectedPartyId.value,
    address_type_lookup_value_id: addressForm.value.address_type_lookup_value_id,
    admin_unit_id: addressForm.value.admin_unit_id,
    line: addressForm.value.line,
    house_number: addressForm.value.house_number,
    kebele: addressForm.value.kebele,
    postal_code: addressForm.value.postal_code,
    is_primary: addressForm.value.is_primary,
    state: 'active'
  };
  addresses.value.push(newAddr);
  saveAllData();
  showAddAddressModal.value = false;
};

const showAddDependentModal = ref(false);
const dependentForm = ref({
  dependent_name: '',
  relation_lookup_value_id: 'child' as DependentRelation,
  birth_date: '2018-05-12',
  is_beneficiary: true,
  benefit_notes: ''
});

const handleSaveDependent = () => {
  if (!dependentForm.value.dependent_name) return;
  const newDep: PartyDependent = {
    id: dependents.value.length ? Math.max(...dependents.value.map(d => d.id)) + 1 : 1,
    uuid: `dep_${Date.now()}`,
    party_id: selectedPartyId.value,
    dependent_party_id: Math.floor(700 + Math.random() * 100),
    dependent_name: dependentForm.value.dependent_name,
    relation_lookup_value_id: dependentForm.value.relation_lookup_value_id,
    birth_date: dependentForm.value.birth_date,
    is_beneficiary: dependentForm.value.is_beneficiary,
    benefit_notes: dependentForm.value.benefit_notes,
    state: 'active'
  };
  dependents.value.push(newDep);
  saveAllData();
  showAddDependentModal.value = false;
};

const showAddQualificationModal = ref(false);
const qualForm = ref({
  level_lookup_value_id: 'bachelors' as QualificationLevel,
  field_of_study_name: 'Accounting',
  institution_name: 'Addis Ababa University (AAU)',
  start_date: '2015-09-10',
  graduation_date: '2019-07-06',
  gpa: 3.50
});

const handleSaveQualification = () => {
  const newQual: PartyQualification = {
    id: qualifications.value.length ? Math.max(...qualifications.value.map(q => q.id)) + 1 : 1,
    uuid: `qual_${Date.now()}`,
    party_id: selectedPartyId.value,
    level_lookup_value_id: qualForm.value.level_lookup_value_id,
    field_of_study_name: qualForm.value.field_of_study_name,
    institution_name: qualForm.value.institution_name,
    start_date: qualForm.value.start_date,
    graduation_date: qualForm.value.graduation_date,
    gpa: qualForm.value.gpa,
    state: 'active'
  };
  qualifications.value.push(newQual);
  saveAllData();
  showAddQualificationModal.value = false;
};

const showAddCertModal = ref(false);
const certForm = ref({
  certification_name: 'ACCA (Chartered Certified Accountant)',
  issuing_institution_name: 'ACCA Global',
  certificate_number: '',
  issued_date: '2023-01-15',
  expiry_date: ''
});

const handleSaveCertification = () => {
  const newCert: PartyCertification = {
    id: certifications.value.length ? Math.max(...certifications.value.map(c => c.id)) + 1 : 1,
    uuid: `cert_${Date.now()}`,
    party_id: selectedPartyId.value,
    certification_name: certForm.value.certification_name,
    issuing_institution_name: certForm.value.issuing_institution_name,
    certificate_number: certForm.value.certificate_number || `CERT-${Date.now().toString().slice(-6)}`,
    issued_date: certForm.value.issued_date,
    expiry_date: certForm.value.expiry_date || undefined,
    state: 'active'
  };
  certifications.value.push(newCert);
  saveAllData();
  showAddCertModal.value = false;
};

const showAddExpModal = ref(false);
const expForm = ref({
  employer_name: '',
  position_title: '',
  employment_type_lookup_value_id: 'permanent' as EmploymentType,
  start_date: '2020-01-01',
  end_date: '',
  responsibilities: '',
  reason_for_leaving: '',
  reference_person: ''
});

const handleSaveExperience = () => {
  if (!expForm.value.employer_name) return;
  const newExp: PartyExperience = {
    id: experiences.value.length ? Math.max(...experiences.value.map(e => e.id)) + 1 : 1,
    uuid: `exp_${Date.now()}`,
    party_id: selectedPartyId.value,
    employer_name: expForm.value.employer_name,
    position_title: expForm.value.position_title,
    employment_type_lookup_value_id: expForm.value.employment_type_lookup_value_id,
    start_date: expForm.value.start_date,
    end_date: expForm.value.end_date || undefined,
    responsibilities: expForm.value.responsibilities,
    reason_for_leaving: expForm.value.reason_for_leaving,
    reference_person: expForm.value.reference_person,
    state: 'active'
  };
  experiences.value.push(newExp);
  saveAllData();
  showAddExpModal.value = false;
};

const showAddSkillModal = ref(false);
const skillForm = ref({
  skill_name: 'ifrs_reporting',
  proficiency_lookup_value_id: 'advanced' as SkillProficiency,
  years_of_experience: 3.0
});

const handleSaveSkill = () => {
  const newSkill: PartySkill = {
    id: skills.value.length ? Math.max(...skills.value.map(s => s.id)) + 1 : 1,
    uuid: `skl_${Date.now()}`,
    party_id: selectedPartyId.value,
    skill_name: skillForm.value.skill_name,
    proficiency_lookup_value_id: skillForm.value.proficiency_lookup_value_id,
    years_of_experience: skillForm.value.years_of_experience,
    state: 'active'
  };
  skills.value.push(newSkill);
  saveAllData();
  showAddSkillModal.value = false;
};

const showAddLangModal = ref(false);
const langForm = ref({
  language_name: 'Amharic',
  proficiency_lookup_value_id: 'fluent' as LanguageProficiency,
  speaking_level_lookup_value_id: 'advanced' as LanguageSkillLevel,
  listening_level_lookup_value_id: 'advanced' as LanguageSkillLevel,
  reading_level_lookup_value_id: 'advanced' as LanguageSkillLevel,
  writing_level_lookup_value_id: 'advanced' as LanguageSkillLevel,
  is_native: false
});

const handleSaveLanguage = () => {
  const newLang: PartyLanguage = {
    id: languages.value.length ? Math.max(...languages.value.map(l => l.id)) + 1 : 1,
    uuid: `lng_${Date.now()}`,
    party_id: selectedPartyId.value,
    language_name: langForm.value.language_name,
    proficiency_lookup_value_id: langForm.value.proficiency_lookup_value_id,
    speaking_level_lookup_value_id: langForm.value.speaking_level_lookup_value_id,
    listening_level_lookup_value_id: langForm.value.listening_level_lookup_value_id,
    reading_level_lookup_value_id: langForm.value.reading_level_lookup_value_id,
    writing_level_lookup_value_id: langForm.value.writing_level_lookup_value_id,
    is_native: langForm.value.is_native,
    state: 'active'
  };
  languages.value.push(newLang);
  saveAllData();
  showAddLangModal.value = false;
};

const deleteSubItem = (type: string, id: number) => {
  if (!confirm('Are you sure you want to remove this record?')) return;
  if (type === 'address') addresses.value = addresses.value.filter(a => a.id !== id);
  if (type === 'dependent') dependents.value = dependents.value.filter(d => d.id !== id);
  if (type === 'qual') qualifications.value = qualifications.value.filter(q => q.id !== id);
  if (type === 'cert') certifications.value = certifications.value.filter(c => c.id !== id);
  if (type === 'exp') experiences.value = experiences.value.filter(e => e.id !== id);
  if (type === 'skill') skills.value = skills.value.filter(s => s.id !== id);
  if (type === 'lang') languages.value = languages.value.filter(l => l.id !== id);
  saveAllData();
};
</script>

<template>
  <div class="party-profile-page">
    <!-- Breadcrumb -->
    <div class="page-breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- VIEW 1: PARTY MANAGEMENT DIRECTORY TABLE VIEW -->
    <div v-if="viewMode === 'list'" class="directory-view-wrapper">
      <AppDataTable
        title="Party Management"
        subtitle="Create and manage parties across the ERP, including individuals and organizations, and maintain their essential identity and contact information for use across customers, suppliers, employees, and other business relationships."
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search Name, Phone, Email and Fayda..."
        :showSearch="true"
        :showFilter="true"
        :filterCount="activeFilterCount"
        :showSort="true"
        :sortOptions="sortOptions"
        v-model:currentSort="currentSort"
        v-model:sortOrder="sortOrder"
        :showColumns="true"
        :columns="tableColumns"
        @toggleColumn="handleToggleColumn"
        @resetFilter="resetFilters"
        :showFullscreen="true"
        :totalEntries="filteredParties.length"
        v-model:currentPage="currentPage"
        v-model:perPage="perPage"
        :showPagination="true"
      >
        <!-- Primary Action on Table Toolbar Right -->
        <template #actions>
          <BaseButton variant="primary" size="md" @click="showQuickCreate = true">
            <Plus :size="16" />
            <span>Create Party</span>
          </BaseButton>
        </template>

        <!-- Filter Panel Slide Down -->
        <template #filter-panel>
          <div class="filter-grid">
            <FormSelect 
              label="Nationality Type"
              v-model="filterNationality"
              :options="['All', 'citizen', 'resident_foreigner', 'non_resident_foreigner', 'dual_citizen']"
            />
            <FormSelect 
              label="Gender"
              v-model="filterGender"
              :options="['All', 'female', 'male']"
            />
            <FormSelect 
              label="Marital Status"
              v-model="filterMarital"
              :options="['All', 'single', 'married', 'divorced', 'widowed']"
            />
            <FormSelect 
              label="State"
              v-model="filterState"
              :options="['All', 'active', 'inactive']"
            />
          </div>
        </template>

        <!-- Main ERP Data Table -->
        <table class="erp-table">
          <thead>
            <tr>
              <!-- Row Selection Checkbox Header -->
              <th style="width: 44px; text-align: center;">
                <input 
                  type="checkbox" 
                  :checked="isAllSelected" 
                  @change="toggleSelectAll" 
                  class="custom-checkbox" 
                />
              </th>
              <th v-if="isColVisible('name')" style="min-width: 240px;">Name</th>
              <th v-if="isColVisible('gender')">Gender</th>
              <th v-if="isColVisible('phone')">Phone No.</th>
              <th v-if="isColVisible('fayda_id')">National ID</th>
              <th v-if="isColVisible('state')" class="cursor-pointer" @click="toggleSortState">
                <div class="sort-header-cell">
                  <span>State</span>
                  <ArrowDown v-if="currentSort === 'state' && sortOrder === 'desc'" :size="13" class="sort-indicator" />
                  <ArrowUp v-else-if="currentSort === 'state' && sortOrder === 'asc'" :size="13" class="sort-indicator" />
                  <ArrowDown v-else :size="13" class="sort-indicator opacity-40" />
                </div>
              </th>
              <!-- Hidden by default secondary columns accessible in Column Hider -->
              <th v-if="isColVisible('marital_status')">Marital Status</th>
              <th v-if="isColVisible('blood_group')">Blood Group</th>
              <th v-if="isColVisible('nationality_type')">Nationality Type</th>
              <th v-if="isColVisible('country')">Country</th>
              <th v-if="isColVisible('birth_date')">Date of Birth</th>
              <th v-if="isColVisible('birth_place')">Place of Birth</th>
              <th v-if="isColVisible('residence')">Primary Residence</th>
              <th style="width: 80px; text-align: center;">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr 
              v-for="item in paginatedParties" 
              :key="item.id" 
              class="table-row cursor-pointer" 
              @click="selectPartyForDetail(item.party_id)"
            >
              <!-- Row Selection Checkbox Cell -->
              <td style="text-align: center;" @click.stop>
                <input 
                  type="checkbox" 
                  :checked="selectedRowIds.includes(item.id)" 
                  @change="toggleRowSelection(item.id)" 
                  class="custom-checkbox" 
                />
              </td>

              <!-- Name (Avatar + Bold Full Name + Email / Subtitle underneath) -->
              <td v-if="isColVisible('name')">
                <div class="user-identity-cell">
                  <img :src="item.avatar || 'https://i.pravatar.cc/150?u=' + item.party_id" class="party-avatar" />
                  <div class="identity-info">
                    <span class="party-name-bold">{{ item.party_name }}</span>
                    <span class="party-email-sub">{{ item.email || '-' }}</span>
                  </div>
                </div>
              </td>

              <!-- Gender -->
              <td v-if="isColVisible('gender')">
                <span class="table-text-val">{{ item.gender_lookup_value_id === 'female' ? 'Female' : 'Male' }}</span>
              </td>

              <!-- Phone No. -->
              <td v-if="isColVisible('phone')">
                <span class="table-text-val">{{ item.phone || '-' }}</span>
              </td>

              <!-- National ID (Fayda) with Inline Copy Button -->
              <td v-if="isColVisible('fayda_id')">
                <div class="national-id-cell" @click.stop="copyFayda(item.id, item.fayda_id || '')">
                  <span>{{ item.fayda_id || '-' }}</span>
                  <button v-if="item.fayda_id" class="btn-copy-id" title="Copy National ID">
                    <Check v-if="copiedFaydaId === item.id" :size="13" class="text-emerald-600" />
                    <Copy v-else :size="13" />
                  </button>
                </div>
              </td>

              <!-- State (Sorted, Active / Inactive Pill) -->
              <td v-if="isColVisible('state')">
                <span :class="['status-pill', item.state === 'active' ? 'status-active' : 'status-inactive']">
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </span>
              </td>

              <!-- Secondary Columns When Enabled in Column Hider -->
              <td v-if="isColVisible('marital_status')">
                <span class="marital-tag">{{ formatMaritalStatus(item.marital_status_lookup_value_id) }}</span>
              </td>
              <td v-if="isColVisible('blood_group')">
                <span class="blood-group-tag">{{ formatBloodGroup(item.blood_group_lookup_value_id) }}</span>
              </td>
              <td v-if="isColVisible('nationality_type')">
                <span :class="['nat-pill', getNationalityPillClass(item.nationality_type_lookup_value_id)]">
                  {{ formatNationalityType(item.nationality_type_lookup_value_id) }}
                </span>
              </td>
              <td v-if="isColVisible('country')">
                <span class="country-badge">{{ item.nationality_country_id }}</span>
              </td>
              <td v-if="isColVisible('birth_date')">
                <span class="table-text-val">{{ item.birth_date || '-' }}</span>
              </td>
              <td v-if="isColVisible('birth_place')">
                <span class="table-text-val">{{ item.birth_place || '-' }}</span>
              </td>
              <td v-if="isColVisible('residence')">
                <span class="table-text-val">
                  {{ addresses.find(a => a.party_id === item.party_id && a.is_primary)?.admin_unit_id || '-' }}
                </span>
              </td>

              <!-- Actions (More vertical dots) -->
              <td class="action-cell" @click.stop>
                <div class="action-dropdown-wrapper">
                  <button class="btn-action-dots" @click="toggleActionMenu($event, item.id)">
                    <MoreVertical :size="15" />
                  </button>

                  <div v-if="openMenuId === item.id" class="action-dropdown-menu">
                    <button class="action-menu-item" @click="selectPartyForDetail(item.party_id); closeActionMenu();">
                      <Eye :size="14" />
                      <span>View Details</span>
                    </button>
                    <button class="action-menu-item" @click="selectPartyForDetail(item.party_id); activeSubTab = 'addresses'; closeActionMenu();">
                      <MapPin :size="14" />
                      <span>Manage Addresses</span>
                    </button>
                    <button class="action-menu-item" @click="selectPartyForDetail(item.party_id); activeSubTab = 'qualifications'; closeActionMenu();">
                      <GraduationCap :size="14" />
                      <span>Qualifications & Certs</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>

            <tr v-if="paginatedParties.length === 0">
              <td :colspan="visibleColumnsCount + 2" class="empty-state-cell">
                <Info :size="24" class="empty-icon" />
                <p>No party records matched your search or filters.</p>
              </td>
            </tr>
          </tbody>
        </table>
      </AppDataTable>
    </div>

    <!-- VIEW 2: PROFILE DETAIL & 1:N EXTENSIONS VIEW -->
    <div v-else-if="viewMode === 'detail'" class="profile-detail-wrapper">
      <!-- Detail Top Navigation Bar -->
      <div class="detail-nav-header">
        <BaseButton variant="outline" size="sm" @click="backToPartyList">
          <ChevronLeft :size="15" />
          <span>Back to Parties</span>
        </BaseButton>

        <div class="detail-header-meta">
          <span class="detail-party-title">{{ selectedParty?.party_name }}</span>
          <span class="detail-code-badge">{{ selectedParty?.code }}</span>
          <span :class="['status-pill', selectedParty?.state === 'active' ? 'status-active' : 'status-inactive']">
            {{ selectedParty?.state === 'active' ? 'Active' : 'Inactive' }}
          </span>
        </div>
      </div>

      <!-- Main Profile Workspace -->
      <div v-if="selectedParty" class="profile-workspace-grid">
        <!-- LEFT: Permanent Demographic Summary Card -->
        <div class="profile-sidebar-card">
          <div class="card-hero-banner">
            <img :src="selectedParty.avatar || 'https://i.pravatar.cc/150?u=' + selectedParty.party_id" class="hero-avatar" />
          </div>

          <div class="card-content-body">
            <h2 class="person-full-name">{{ selectedParty.party_name }}</h2>
            <div class="person-meta-line">
              <code>{{ selectedParty.code }}</code>
              <span class="meta-dot">•</span>
              <span>Party ID: {{ selectedParty.party_id }}</span>
            </div>

            <!-- Nationality & Regulatory Tags -->
            <div class="person-status-row">
              <span :class="['nat-pill', getNationalityPillClass(selectedParty.nationality_type_lookup_value_id)]">
                {{ formatNationalityType(selectedParty.nationality_type_lookup_value_id) }}
              </span>
              <span :class="['status-pill', selectedParty.state === 'active' ? 'status-active' : 'status-inactive']">
                {{ selectedParty.state }}
              </span>
            </div>

            <div class="sidebar-divider"></div>

            <!-- Key Identity Specs -->
            <div class="identity-specs-list">
              <div class="spec-row">
                <span class="spec-label">Fayda National ID</span>
                <span class="spec-value">{{ selectedParty.fayda_id || '-' }}</span>
              </div>
              <div class="spec-row">
                <span class="spec-label">Phone</span>
                <span class="spec-value">{{ selectedParty.phone || '-' }}</span>
              </div>
              <div class="spec-row">
                <span class="spec-label">Email</span>
                <span class="spec-value truncate">{{ selectedParty.email || '-' }}</span>
              </div>
              <div class="spec-row">
                <span class="spec-label">Birth Date</span>
                <span class="spec-value">{{ selectedParty.birth_date }}</span>
              </div>
              <div class="spec-row">
                <span class="spec-label">Town of Birth</span>
                <span class="spec-value">{{ selectedParty.birth_place }}</span>
              </div>
              <div class="spec-row">
                <span class="spec-label">Blood Group</span>
                <span class="spec-value font-semibold">{{ formatBloodGroup(selectedParty.blood_group_lookup_value_id) }}</span>
              </div>
              <div class="spec-row">
                <span class="spec-label">Work Permit Req.</span>
                <span class="spec-value">
                  {{ selectedParty.nationality_type_lookup_value_id === 'resident_foreigner' || selectedParty.nationality_type_lookup_value_id === 'non_resident_foreigner' ? 'Yes (Mandatory)' : 'Exempt (Citizen)' }}
                </span>
              </div>
              <div class="spec-row">
                <span class="spec-label">Pension Applicable</span>
                <span class="spec-value">
                  {{ selectedParty.nationality_type_lookup_value_id === 'citizen' || selectedParty.nationality_type_lookup_value_id === 'dual_citizen' ? 'Yes (National Scheme)' : 'Optional / Excluded' }}
                </span>
              </div>
            </div>

            <!-- Quick Action -->
            <div class="sidebar-actions">
              <BaseButton variant="outline" size="sm" class="w-full">
                <Edit2 :size="13" />
                <span>Edit 1:1 Demographics</span>
              </BaseButton>
            </div>
          </div>
        </div>

        <!-- RIGHT: 1:N Sub-Sections with UnderlineTabs -->
        <div class="profile-extensions-card">
          <!-- Secondary UnderlineTabs Standard -->
          <div class="extensions-tab-bar">
            <UnderlineTabs 
              v-model="activeSubTab"
              :tabs="profileSubTabs"
              size="md"
              justify="start"
            />
          </div>

          <!-- SUB-TAB 1: 1:1 Demographics Detail -->
          <div v-if="activeSubTab === 'demographics'" class="sub-tab-content">
            <div class="sub-tab-header">
              <div>
                <h3 class="sub-title">1:1 Core Demographics (PartyDetail)</h3>
                <p class="sub-desc">Authoritative civil registration, legal identity, and statutory compliance properties.</p>
              </div>
            </div>

            <div class="demographics-detail-grid">
              <div class="detail-tile">
                <span class="tile-label">Gender</span>
                <span class="tile-value">{{ selectedParty.gender_lookup_value_id === 'female' ? 'Female' : 'Male' }}</span>
              </div>
              <div class="detail-tile">
                <span class="tile-label">Blood Group</span>
                <span class="tile-value">{{ formatBloodGroup(selectedParty.blood_group_lookup_value_id) }}</span>
              </div>
              <div class="detail-tile">
                <span class="tile-label">Date of Birth</span>
                <span class="tile-value">{{ selectedParty.birth_date }}</span>
              </div>
              <div class="detail-tile">
                <span class="tile-label">Birth Place / Town</span>
                <span class="tile-value">{{ selectedParty.birth_place }}</span>
              </div>
              <div class="detail-tile">
                <span class="tile-label">Nationality Country</span>
                <span class="tile-value">{{ selectedParty.nationality_country_id }} (Ethiopia)</span>
              </div>
              <div class="detail-tile">
                <span class="tile-label">Nationality Classification</span>
                <span class="tile-value">{{ formatNationalityType(selectedParty.nationality_type_lookup_value_id) }}</span>
              </div>
              <div class="detail-tile">
                <span class="tile-label">Marital Status</span>
                <span class="tile-value">{{ formatMaritalStatus(selectedParty.marital_status_lookup_value_id) }}</span>
              </div>
              <div class="detail-tile">
                <span class="tile-label">Record State</span>
                <span class="tile-value">{{ selectedParty.state }}</span>
              </div>
            </div>

            <div class="statutory-notice-box">
              <Info :size="16" class="notice-icon" />
              <div class="notice-text">
                <strong>Statutory Pension & Work Permit Impact:</strong>
                <span>Nationality type <code>{{ selectedParty.nationality_type_lookup_value_id }}</code> drives automatic pension scheme enrollment and validates work-permit requirements prior to any Employee row creation.</span>
              </div>
            </div>
          </div>

          <!-- SUB-TAB 2: Addresses (1:N PartyAddress) -->
          <div v-else-if="activeSubTab === 'addresses'" class="sub-tab-content">
            <div class="sub-tab-header">
              <div>
                <h3 class="sub-title">Addresses & Geography Spine (1:N)</h3>
                <p class="sub-desc">Normalized locations backed by AdminUnit geography hierarchy.</p>
              </div>
              <BaseButton variant="primary" size="sm" @click="showAddAddressModal = true">
                <Plus :size="14" />
                <span>Add Address</span>
              </BaseButton>
            </div>

            <div class="cards-list-grid">
              <div v-for="addr in partyAddresses" :key="addr.id" class="sub-item-card">
                <div class="item-card-top">
                  <div class="card-tag-group">
                    <span class="type-badge">{{ addr.address_type_lookup_value_id.toUpperCase() }}</span>
                    <span v-if="addr.is_primary" class="primary-badge">PRIMARY</span>
                  </div>
                  <button class="btn-delete-item" @click="deleteSubItem('address', addr.id)" title="Remove Address">
                    <Trash2 :size="14" />
                  </button>
                </div>
                <div class="item-card-body">
                  <div class="address-line-main">
                    <MapPin :size="15" class="map-icon" />
                    <span>{{ addr.line || 'No street line recorded' }}</span>
                  </div>
                  <div class="address-meta-grid">
                    <div><strong>Admin Unit:</strong> {{ addr.admin_unit_id }}</div>
                    <div><strong>House No:</strong> {{ addr.house_number || '-' }}</div>
                    <div><strong>Kebele:</strong> {{ addr.kebele || '-' }}</div>
                    <div><strong>Postal Code:</strong> {{ addr.postal_code || '-' }}</div>
                    <div><strong>Effective From:</strong> {{ addr.effective_from || 'Always Current' }}</div>
                  </div>
                </div>
              </div>

              <div v-if="partyAddresses.length === 0" class="sub-empty-state">
                <MapPin :size="28" class="empty-icon" />
                <p>No addresses recorded for this party yet.</p>
                <BaseButton variant="outline" size="sm" @click="showAddAddressModal = true">
                  <Plus :size="14" />
                  <span>Add First Address</span>
                </BaseButton>
              </div>
            </div>
          </div>

          <!-- SUB-TAB 3: Dependents (1:N PartyDependent) -->
          <div v-else-if="activeSubTab === 'dependents'" class="sub-tab-content">
            <div class="sub-tab-header">
              <div>
                <h3 class="sub-title">Dependents & Beneficiaries (1:N)</h3>
                <p class="sub-desc">Spouses, children, and parents feeding insurance, tax relief, and emergency records.</p>
              </div>
              <BaseButton variant="primary" size="sm" @click="showAddDependentModal = true">
                <Plus :size="14" />
                <span>Add Dependent</span>
              </BaseButton>
            </div>

            <div class="cards-list-grid">
              <div v-for="dep in partyDependents" :key="dep.id" class="sub-item-card">
                <div class="item-card-top">
                  <div class="card-tag-group">
                    <span class="relation-badge">{{ dep.relation_lookup_value_id.toUpperCase() }}</span>
                    <span :class="['beneficiary-pill', dep.is_beneficiary ? 'is-ben' : 'non-ben']">
                      {{ dep.is_beneficiary ? 'BENEFICIARY' : 'EMERGENCY ONLY' }}
                    </span>
                  </div>
                  <button class="btn-delete-item" @click="deleteSubItem('dependent', dep.id)">
                    <Trash2 :size="14" />
                  </button>
                </div>
                <div class="item-card-body">
                  <h4 class="dependent-name">{{ dep.dependent_name }}</h4>
                  <div class="dependent-meta-line">
                    <span>Party ID: {{ dep.dependent_party_id }}</span>
                    <span class="meta-dot">•</span>
                    <span>DOB: {{ dep.birth_date }}</span>
                  </div>
                  <div v-if="dep.benefit_notes" class="benefit-notes-box">
                    <ShieldCheck :size="13" />
                    <span>{{ dep.benefit_notes }}</span>
                  </div>
                </div>
              </div>

              <div v-if="partyDependents.length === 0" class="sub-empty-state">
                <Heart :size="28" class="empty-icon" />
                <p>No dependent relationships recorded.</p>
                <BaseButton variant="outline" size="sm" @click="showAddDependentModal = true">
                  <Plus :size="14" />
                  <span>Add Dependent</span>
                </BaseButton>
              </div>
            </div>
          </div>

          <!-- SUB-TAB 4: Qualifications (1:N PartyQualification) -->
          <div v-else-if="activeSubTab === 'qualifications'" class="sub-tab-content">
            <div class="sub-tab-header">
              <div>
                <h3 class="sub-title">Academic Qualifications & Credentials (1:N)</h3>
                <p class="sub-desc">Degrees, diplomas, and TVET certificates mapped to Field of Study catalogue.</p>
              </div>
              <BaseButton variant="primary" size="sm" @click="showAddQualificationModal = true">
                <Plus :size="14" />
                <span>Add Qualification</span>
              </BaseButton>
            </div>

            <div class="cards-list-grid">
              <div v-for="qual in partyQualifications" :key="qual.id" class="sub-item-card">
                <div class="item-card-top">
                  <span class="qual-level-pill">{{ formatLevel(qual.level_lookup_value_id) }}</span>
                  <button class="btn-delete-item" @click="deleteSubItem('qual', qual.id)">
                    <Trash2 :size="14" />
                  </button>
                </div>
                <div class="item-card-body">
                  <h4 class="qual-field">{{ qual.field_of_study_name }}</h4>
                  <div class="institution-name">{{ qual.institution_name }}</div>
                  <div class="qual-dates-row">
                    <span>Graduated: {{ qual.graduation_date || 'In Progress' }}</span>
                    <span v-if="qual.gpa" class="gpa-tag">GPA: {{ qual.gpa.toFixed(2) }} / 4.00</span>
                  </div>
                </div>
              </div>

              <div v-if="partyQualifications.length === 0" class="sub-empty-state">
                <GraduationCap :size="28" class="empty-icon" />
                <p>No academic credentials attached yet.</p>
                <BaseButton variant="outline" size="sm" @click="showAddQualificationModal = true">
                  <Plus :size="14" />
                  <span>Add Qualification</span>
                </BaseButton>
              </div>
            </div>
          </div>

          <!-- SUB-TAB 5: Certifications (1:N PartyCertification) -->
          <div v-else-if="activeSubTab === 'certifications'" class="sub-tab-content">
            <div class="sub-tab-header">
              <div>
                <h3 class="sub-title">Professional Certifications & Licenses (1:N)</h3>
                <p class="sub-desc">Chartered certificates, professional licenses, and regulatory compliance permits.</p>
              </div>
              <BaseButton variant="primary" size="sm" @click="showAddCertModal = true">
                <Plus :size="14" />
                <span>Add Certification</span>
              </BaseButton>
            </div>

            <div class="cards-list-grid">
              <div v-for="cert in partyCertifications" :key="cert.id" class="sub-item-card">
                <div class="item-card-top">
                  <span class="cert-badge">
                    <Award :size="13" />
                    <span>{{ cert.certificate_number }}</span>
                  </span>
                  <button class="btn-delete-item" @click="deleteSubItem('cert', cert.id)">
                    <Trash2 :size="14" />
                  </button>
                </div>
                <div class="item-card-body">
                  <h4 class="cert-name">{{ cert.certification_name }}</h4>
                  <div class="institution-name">{{ cert.issuing_institution_name }}</div>
                  <div class="cert-expiry-row">
                    <span>Issued: {{ cert.issued_date }}</span>
                    <span class="meta-dot">•</span>
                    <span :class="cert.expiry_date ? 'text-amber-600' : 'text-emerald-600'">
                      {{ cert.expiry_date ? 'Expires: ' + cert.expiry_date : 'Lifetime / No Expiry' }}
                    </span>
                  </div>
                </div>
              </div>

              <div v-if="partyCertifications.length === 0" class="sub-empty-state">
                <Award :size="28" class="empty-icon" />
                <p>No professional licenses or certificates on file.</p>
                <BaseButton variant="outline" size="sm" @click="showAddCertModal = true">
                  <Plus :size="14" />
                  <span>Add Certification</span>
                </BaseButton>
              </div>
            </div>
          </div>

          <!-- SUB-TAB 6: Experience (1:N PartyExperience) -->
          <div v-else-if="activeSubTab === 'experiences'" class="sub-tab-content">
            <div class="sub-tab-header">
              <div>
                <h3 class="sub-title">Prior Work History & Employment (1:N)</h3>
                <p class="sub-desc">Verified external job experiences and professional references.</p>
              </div>
              <BaseButton variant="primary" size="sm" @click="showAddExpModal = true">
                <Plus :size="14" />
                <span>Add Experience</span>
              </BaseButton>
            </div>

            <div class="experience-timeline">
              <div v-for="exp in partyExperiences" :key="exp.id" class="experience-card">
                <div class="exp-card-header">
                  <div>
                    <h4 class="exp-title">{{ exp.position_title }}</h4>
                    <div class="exp-employer">{{ exp.employer_name }}</div>
                  </div>
                  <div class="exp-right-tags">
                    <span class="emp-type-pill">{{ exp.employment_type_lookup_value_id }}</span>
                    <button class="btn-delete-item" @click="deleteSubItem('exp', exp.id)">
                      <Trash2 :size="14" />
                    </button>
                  </div>
                </div>
                <div class="exp-dates">
                  <Calendar :size="13" />
                  <span>{{ exp.start_date }} — {{ exp.end_date || 'Present' }}</span>
                </div>
                <p v-if="exp.responsibilities" class="exp-narrative">{{ exp.responsibilities }}</p>
                <div v-if="exp.reference_person" class="exp-reference-box">
                  <strong>Reference Contact:</strong> {{ exp.reference_person }}
                </div>
              </div>

              <div v-if="partyExperiences.length === 0" class="sub-empty-state">
                <Briefcase :size="28" class="empty-icon" />
                <p>No previous external work experience recorded.</p>
                <BaseButton variant="outline" size="sm" @click="showAddExpModal = true">
                  <Plus :size="14" />
                  <span>Add Experience</span>
                </BaseButton>
              </div>
            </div>
          </div>

          <!-- SUB-TAB 7: Skills & Languages -->
          <div v-else-if="activeSubTab === 'skills_languages'" class="sub-tab-content">
            <div class="skills-lang-two-col">
              <!-- Left Column: Skills Catalog -->
              <div class="col-section">
                <div class="section-top-bar">
                  <div>
                    <h4 class="col-title">Skills & Proficiencies</h4>
                    <p class="col-sub">Scoped skill matrix with years of experience.</p>
                  </div>
                  <BaseButton variant="outline" size="sm" @click="showAddSkillModal = true">
                    <Plus :size="13" />
                    <span>Add Skill</span>
                  </BaseButton>
                </div>

                <div class="skills-chips-wrap">
                  <div v-for="skl in partySkills" :key="skl.id" class="skill-item-row">
                    <div class="skill-info">
                      <span class="skill-title">{{ skl.skill_name.replace(/_/g, ' ') }}</span>
                      <span class="skill-exp">{{ skl.years_of_experience }} yrs exp</span>
                    </div>
                    <div class="skill-right">
                      <span :class="['prof-pill', `prof-${skl.proficiency_lookup_value_id}`]">
                        {{ skl.proficiency_lookup_value_id }}
                      </span>
                      <button class="btn-del-mini" @click="deleteSubItem('skill', skl.id)">
                        <X :size="12" />
                      </button>
                    </div>
                  </div>

                  <div v-if="partySkills.length === 0" class="sub-empty-state-mini">
                    <span>No skills added yet.</span>
                  </div>
                </div>
              </div>

              <!-- Right Column: 4-Axis Language Matrix -->
              <div class="col-section">
                <div class="section-top-bar">
                  <div>
                    <h4 class="col-title">Languages & 4-Axis Proficiency</h4>
                    <p class="col-sub">Speaking, listening, reading & writing evaluation.</p>
                  </div>
                  <BaseButton variant="outline" size="sm" @click="showAddLangModal = true">
                    <Plus :size="13" />
                    <span>Add Language</span>
                  </BaseButton>
                </div>

                <div class="languages-list">
                  <div v-for="lng in partyLanguages" :key="lng.id" class="language-card">
                    <div class="lang-top">
                      <div class="lang-title-group">
                        <span class="lang-name">{{ lng.language_name }}</span>
                        <span v-if="lng.is_native" class="native-tag">Native</span>
                      </div>
                      <div class="lang-right-tag">
                        <span class="summary-prof-tag">Composite: {{ lng.proficiency_lookup_value_id }}</span>
                        <button class="btn-del-mini" @click="deleteSubItem('lang', lng.id)">
                          <X :size="12" />
                        </button>
                      </div>
                    </div>

                    <!-- 4 Axis Matrix -->
                    <div class="axes-grid">
                      <div class="axis-box">
                        <span class="axis-lbl">Speaking</span>
                        <span class="axis-val">{{ lng.speaking_level_lookup_value_id }}</span>
                      </div>
                      <div class="axis-box">
                        <span class="axis-lbl">Listening</span>
                        <span class="axis-val">{{ lng.listening_level_lookup_value_id }}</span>
                      </div>
                      <div class="axis-box">
                        <span class="axis-lbl">Reading</span>
                        <span class="axis-val">{{ lng.reading_level_lookup_value_id }}</span>
                      </div>
                      <div class="axis-box">
                        <span class="axis-lbl">Writing</span>
                        <span class="axis-val">{{ lng.writing_level_lookup_value_id }}</span>
                      </div>
                    </div>
                  </div>

                  <div v-if="partyLanguages.length === 0" class="sub-empty-state-mini">
                    <span>No languages registered yet.</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- QUICK CREATE MODAL (Standard <= 5 Required Fields) -->
    <QuickCreateModal 
      :show="showQuickCreate"
      title="Create Party Profile"
      width="md"
      :showExpandButton="true"
      @update:show="showQuickCreate = $event"
      @save="handleSaveQuickParty"
      @cancel="showQuickCreate = false"
      @expand="handleExpandPartyCreate"
    >
      <div class="modal-form-body">
        <FormInput 
          label="Full Legal Name"
          v-model="quickForm.party_name"
          :required="true"
        />

        <div class="form-grid-two">
          <FormSelect 
            label="Gender"
            v-model="quickForm.gender_lookup_value_id"
            :required="true"
            :options="[
              { value: 'female', label: 'Female' },
              { value: 'male', label: 'Male' }
            ]"
          />
          <FormInput 
            label="Date of Birth"
            type="date"
            v-model="quickForm.birth_date"
            :required="true"
          />
        </div>

        <div class="form-grid-two">
          <FormSelect 
            label="Nationality Type"
            v-model="quickForm.nationality_type_lookup_value_id"
            :required="true"
            :options="[
              { value: 'citizen', label: 'Citizen (National)' },
              { value: 'resident_foreigner', label: 'Resident Foreigner' },
              { value: 'non_resident_foreigner', label: 'Non-Resident Foreigner' },
              { value: 'dual_citizen', label: 'Dual Citizen' }
            ]"
          />
          <FormInput 
            label="Place / Town of Birth"
            v-model="quickForm.birth_place"
            :required="true"
          />
        </div>

        <div class="form-grid-two">
          <FormInput 
            label="Primary Phone Number"
            v-model="quickForm.phone"
          />
          <FormSelect 
            label="Marital Status"
            v-model="quickForm.marital_status_lookup_value_id"
            :options="[
              { value: 'single', label: 'Single' },
              { value: 'married', label: 'Married' },
              { value: 'divorced', label: 'Divorced' },
              { value: 'widowed', label: 'Widowed' }
            ]"
          />
        </div>
      </div>
    </QuickCreateModal>

    <!-- SUB-ENTITY MODAL: Add Address -->
    <QuickCreateModal 
      :show="showAddAddressModal"
      title="Add Party Address"
      width="md"
      @update:show="showAddAddressModal = $event"
      @save="handleSaveAddress"
      @cancel="showAddAddressModal = false"
    >
      <div class="modal-form-body">
        <div class="form-grid-two">
          <FormSelect 
            label="Address Type"
            v-model="addressForm.address_type_lookup_value_id"
            :options="['residence', 'postal', 'work', 'emergency', 'birth_place', 'other']"
          />
          <FormSelect 
            label="Admin Unit (Sub-City / Woreda)"
            v-model="addressForm.admin_unit_id"
            :options="['305 (Bole)', '312 (Kirkos)', '318 (Yeka)', '320 (Arada)', '401 (Bahir Dar)', '402 (Hawassa)']"
          />
        </div>
        <FormInput label="Street / Locality Line" v-model="addressForm.line" />
        <div class="form-grid-two">
          <FormInput label="House Number" v-model="addressForm.house_number" />
          <FormInput label="Kebele" v-model="addressForm.kebele" />
        </div>
        <div class="form-grid-two">
          <FormInput label="Postal Code" v-model="addressForm.postal_code" />
          <div class="flex items-center pt-5">
            <FormCheckbox label="Set as Primary Address" v-model="addressForm.is_primary" />
          </div>
        </div>
      </div>
    </QuickCreateModal>

    <!-- SUB-ENTITY MODAL: Add Dependent -->
    <QuickCreateModal 
      :show="showAddDependentModal"
      title="Add Dependent / Beneficiary"
      width="md"
      @update:show="showAddDependentModal = $event"
      @save="handleSaveDependent"
      @cancel="showAddDependentModal = false"
    >
      <div class="modal-form-body">
        <FormInput label="Dependent Full Name" v-model="dependentForm.dependent_name" :required="true" />
        <div class="form-grid-two">
          <FormSelect 
            label="Relationship" 
            v-model="dependentForm.relation_lookup_value_id"
            :options="['spouse', 'child', 'parent', 'sibling', 'other']"
          />
          <FormInput label="Birth Date" type="date" v-model="dependentForm.birth_date" />
        </div>
        <FormInput label="Benefit / Insurance Policy Notes" v-model="dependentForm.benefit_notes" />
        <div class="pt-2">
          <FormCheckbox label="Include as Benefit Beneficiary (Health/Insurance)" v-model="dependentForm.is_beneficiary" />
        </div>
      </div>
    </QuickCreateModal>

    <!-- SUB-ENTITY MODAL: Add Qualification -->
    <QuickCreateModal 
      :show="showAddQualificationModal"
      title="Add Academic Qualification"
      width="md"
      @update:show="showAddQualificationModal = $event"
      @save="handleSaveQualification"
      @cancel="showAddQualificationModal = false"
    >
      <div class="modal-form-body">
        <div class="form-grid-two">
          <FormSelect 
            label="Qualification Level" 
            v-model="qualForm.level_lookup_value_id"
            :options="[
              { value: 'bachelors', label: 'Bachelor\'s Degree' },
              { value: 'masters', label: 'Master\'s Degree' },
              { value: 'phd', label: 'Doctorate (Ph.D.)' },
              { value: 'diploma', label: 'Diploma' },
              { value: 'tvet_certificate', label: 'TVET Certificate' },
              { value: 'secondary', label: 'Secondary School' }
            ]"
          />
          <FormInput label="Field of Study" v-model="qualForm.field_of_study_name" :required="true" />
        </div>
        <FormInput label="Awarding Institution" v-model="qualForm.institution_name" :required="true" />
        <div class="form-grid-two">
          <FormInput label="Graduation Date" type="date" v-model="qualForm.graduation_date" />
          <FormInput label="GPA (4.00 Scale)" type="number" step="0.01" v-model="qualForm.gpa" />
        </div>
      </div>
    </QuickCreateModal>

    <!-- SUB-ENTITY MODAL: Add Certification -->
    <QuickCreateModal 
      :show="showAddCertModal"
      title="Add Certification / License"
      width="md"
      @update:show="showAddCertModal = $event"
      @save="handleSaveCertification"
      @cancel="showAddCertModal = false"
    >
      <div class="modal-form-body">
        <FormInput label="Certification Name" v-model="certForm.certification_name" :required="true" />
        <FormInput label="Issuing Body / Institution" v-model="certForm.issuing_institution_name" :required="true" />
        <FormInput label="Certificate / License Number" v-model="certForm.certificate_number" />
        <div class="form-grid-two">
          <FormInput label="Issue Date" type="date" v-model="certForm.issued_date" />
          <FormInput label="Expiry Date (Leave empty if none)" type="date" v-model="certForm.expiry_date" />
        </div>
      </div>
    </QuickCreateModal>

    <!-- SUB-ENTITY MODAL: Add Experience -->
    <QuickCreateModal 
      :show="showAddExpModal"
      title="Add Prior Work Experience"
      width="lg"
      @update:show="showAddExpModal = $event"
      @save="handleSaveExperience"
      @cancel="showAddExpModal = false"
    >
      <div class="modal-form-body">
        <div class="form-grid-two">
          <FormInput label="Employer / Organization Name" v-model="expForm.employer_name" :required="true" />
          <FormInput label="Verbatim Position Title" v-model="expForm.position_title" :required="true" />
        </div>
        <div class="form-grid-two">
          <FormSelect 
            label="Employment Type"
            v-model="expForm.employment_type_lookup_value_id"
            :options="['permanent', 'contract', 'temporary', 'probation', 'part_time', 'intern', 'consultant']"
          />
          <div class="form-grid-two">
            <FormInput label="Start Date" type="date" v-model="expForm.start_date" />
            <FormInput label="End Date" type="date" v-model="expForm.end_date" />
          </div>
        </div>
        <FormTextarea label="Core Responsibilities" v-model="expForm.responsibilities" :rows="2" />
        <FormInput label="Reference Person & Contact" v-model="expForm.reference_person" />
      </div>
    </QuickCreateModal>

    <!-- SUB-ENTITY MODAL: Add Skill -->
    <QuickCreateModal 
      :show="showAddSkillModal"
      title="Add Candidate Skill"
      width="sm"
      @update:show="showAddSkillModal = $event"
      @save="handleSaveSkill"
      @cancel="showAddSkillModal = false"
    >
      <div class="modal-form-body">
        <FormSelect 
          label="Skill Name"
          v-model="skillForm.skill_name"
          :options="[
            { value: 'ifrs_reporting', label: 'IFRS Reporting' },
            { value: 'peachtree', label: 'Peachtree / Sage' },
            { value: 'food_safety', label: 'Food Safety & Hygiene' },
            { value: 'pos_operation', label: 'POS Operation' },
            { value: 'supplier_negotiation', label: 'Supplier Negotiation' },
            { value: 'labour_law_compliance', label: 'Labour Law Compliance' },
            { value: 'customer_service', label: 'Customer Service' },
            { value: 'warehouse_management', label: 'Warehouse Management' }
          ]"
        />
        <FormSelect 
          label="Proficiency Level"
          v-model="skillForm.proficiency_lookup_value_id"
          :options="['beginner', 'intermediate', 'advanced', 'expert']"
        />
        <FormInput label="Years of Experience" type="number" step="0.5" v-model="skillForm.years_of_experience" />
      </div>
    </QuickCreateModal>

    <!-- SUB-ENTITY MODAL: Add Language -->
    <QuickCreateModal 
      :show="showAddLangModal"
      title="Add Language Proficiency"
      width="md"
      @update:show="showAddLangModal = $event"
      @save="handleSaveLanguage"
      @cancel="showAddLangModal = false"
    >
      <div class="modal-form-body">
        <div class="form-grid-two">
          <FormSelect 
            label="Language"
            v-model="langForm.language_name"
            :options="['Amharic', 'English', 'Afaan Oromo', 'Tigrinya', 'Somali', 'Arabic', 'Sidama', 'Wolaytta']"
          />
          <FormSelect 
            label="Overall Proficiency"
            v-model="langForm.proficiency_lookup_value_id"
            :options="['basic', 'conversational', 'fluent', 'native']"
          />
        </div>
        <div class="form-grid-two">
          <FormSelect label="Speaking" v-model="langForm.speaking_level_lookup_value_id" :options="['none', 'basic', 'intermediate', 'advanced', 'native']" />
          <FormSelect label="Listening" v-model="langForm.listening_level_lookup_value_id" :options="['none', 'basic', 'intermediate', 'advanced', 'native']" />
        </div>
        <div class="form-grid-two">
          <FormSelect label="Reading" v-model="langForm.reading_level_lookup_value_id" :options="['none', 'basic', 'intermediate', 'advanced', 'native']" />
          <FormSelect label="Writing" v-model="langForm.writing_level_lookup_value_id" :options="['none', 'basic', 'intermediate', 'advanced', 'native']" />
        </div>
        <div class="pt-2">
          <FormCheckbox label="Mark as Native Language" v-model="langForm.is_native" />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.party-profile-page {
  padding: 20px 24px 32px 24px;
  background-color: #fafafa;
  min-height: 100%;
  box-sizing: border-box;
}

/* Breadcrumb & Header */
.page-breadcrumb-bar { margin-bottom: 12px; }
.page-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
  gap: 16px;
}
.page-title {
  font-size: 20px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}
.page-subtitle {
  font-size: 13px;
  color: #737373;
  margin: 0;
}
.page-actions-group {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* Metrics Grid */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 20px;
}

/* Main Tab Container */
.main-tabs-container {
  margin-bottom: 16px;
}

/* DIRECTORY VIEW */
.directory-view-wrapper {
  margin-bottom: 24px;
}
.filter-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
  width: 100%;
}

/* Table */
.erp-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}
.erp-table th {
  height: 34px;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background-color: #fafafa;
  border-bottom: 1px solid #f0f0f0;
  white-space: nowrap;
}
.erp-table td {
  height: 38px;
  padding: 8px 16px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #f5f5f5;
  vertical-align: middle;
}
.table-row {
  cursor: pointer;
  transition: background 0.15s;
}
.table-row:hover {
  background-color: #f9fafb;
}

/* Row Checkbox */
.custom-checkbox {
  width: 16px;
  height: 16px;
  border-radius: 4px;
  border: 1.5px solid #cbd5e1;
  accent-color: #0B529C;
  cursor: pointer;
}

/* User Identity Cell Matching Target UI */
.user-identity-cell {
  display: flex;
  align-items: center;
  gap: 12px;
}
.party-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
  background-color: #e2e8f0;
}
.identity-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.party-name-bold {
  font-size: 13.5px;
  font-weight: 600;
  color: #1e293b;
  line-height: 1.2;
}
.party-email-sub {
  font-size: 12px;
  color: #64748b;
  line-height: 1.2;
}

/* Text and Sort Headers */
.table-text-val {
  font-size: 13px;
  color: #404040;
  white-space: nowrap;
}

.sort-header-cell {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  cursor: pointer;
  user-select: none;
}
.sort-indicator {
  color: #64748b;
}

/* National ID Cell */
.national-id-cell {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #404040;
  cursor: pointer;
}
.btn-copy-id {
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 2px;
  display: inline-flex;
  align-items: center;
  transition: color 0.15s;
}
.btn-copy-id:hover {
  color: #0B529C;
}

/* Atomic Column Pills & Text */
.gender-tag {
  display: inline-block;
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 6px;
  font-weight: 500;
}
.gender-female {
  background: #fdf2f8;
  color: #db2777;
}
.gender-male {
  background: #eff6ff;
  color: #2563eb;
}

.contact-text, .data-date-text, .data-place-text, .data-residence-text {
  font-size: 12.5px;
  color: #404040;
  white-space: nowrap;
}

.blood-group-tag, .marital-tag {
  font-size: 11px;
  padding: 2px 7px;
  background: #f1f5f9;
  color: #475569;
  border-radius: 6px;
  font-weight: 500;
}
.blood-group-tag {
  background: #fee2e2;
  color: #b91c1c;
  font-weight: 600;
}
.nationality-cell {
  display: flex;
  align-items: center;
  gap: 6px;
}
.nat-pill {
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 6px;
  font-weight: 500;
}
.pill-citizen { background: #e0f2fe; color: #0369a1; }
.pill-resident { background: #fef3c7; color: #92400e; }
.pill-dual { background: #f3e8ff; color: #6b21a8; }
.pill-foreigner { background: #fee2e2; color: #991b1b; }
.country-badge {
  font-size: 10.5px;
  font-weight: 600;
  color: #737373;
  padding: 1px 5px;
  background: #f3f4f6;
  border-radius: 4px;
}

/* Status Pill */
.status-pill {
  display: inline-block;
  padding: 2px 10px;
  font-size: 11.5px;
  border-radius: 12px;
  font-weight: 500;
  text-transform: capitalize;
}
.status-active { background: #ecfdf5; color: #059669; }
.status-inactive { background: #f3f4f6; color: #6b7280; }

/* Detail Top Return Header */
.detail-nav-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 20px;
  padding: 12px 18px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
}
.detail-header-meta {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-left: auto;
}
.detail-party-title {
  font-size: 15px;
  font-weight: 600;
  color: #1e293b;
}
.detail-code-badge {
  font-size: 12px;
  font-family: monospace;
  background: #f1f5f9;
  color: #475569;
  padding: 2px 8px;
  border-radius: 6px;
}

/* Action dots */
.action-cell {
  text-align: center;
}
.action-dropdown-wrapper {
  position: relative;
  display: inline-block;
}
.btn-action-dots {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s;
}
.btn-action-dots:hover {
  background: #f0f0f0;
  color: #404040;
}
.action-dropdown-menu {
  position: absolute;
  right: 0;
  top: 100%;
  background: #ffffff;
  border: 1px solid #e5e7eb;
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
  border-radius: 8px;
  z-index: 50;
  width: 190px;
  padding: 4px;
}
.action-menu-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 10px;
  border: none;
  background: none;
  font-size: 12.5px;
  color: #404040;
  text-align: left;
  border-radius: 6px;
  cursor: pointer;
}
.action-menu-item:hover {
  background: #f8fafc;
  color: #0B529C;
}

.empty-state-cell {
  text-align: center;
  padding: 36px 0;
  color: #737373;
}
.empty-icon {
  margin: 0 auto 8px auto;
  color: #9ca3af;
}

.pagination-footer {
  padding: 12px 18px;
  border-top: 1px solid #f0f0f0;
}

/* PROFILE DETAIL WORKSPACE */
.profile-detail-wrapper {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.profile-workspace-grid {
  display: grid;
  grid-template-columns: 320px 1fr;
  gap: 18px;
}

/* Sidebar Card */
.profile-sidebar-card {
  background: #ffffff;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.04);
  overflow: hidden;
}
.card-hero-banner {
  background: linear-gradient(135deg, #0B529C 0%, #1e40af 100%);
  height: 70px;
  position: relative;
  margin-bottom: 36px;
}
.hero-avatar {
  position: absolute;
  bottom: -28px;
  left: 20px;
  width: 64px;
  height: 64px;
  border-radius: 12px;
  border: 3px solid #ffffff;
  object-fit: cover;
  background: #ffffff;
  box-shadow: 0 2px 6px rgba(0,0,0,0.08);
}
.card-content-body {
  padding: 0 20px 20px 20px;
}
.person-full-name {
  font-size: 17px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 2px 0;
}
.person-meta-line {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #737373;
  margin-bottom: 10px;
}
.person-status-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 14px;
}
.sidebar-divider {
  height: 1px;
  background: #f0f0f0;
  margin: 14px 0;
}
.identity-specs-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 18px;
}
.spec-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12.5px;
}
.spec-label { color: #737373; }
.spec-value { color: #404040; font-weight: 500; text-align: right; }
.sidebar-actions {
  display: flex;
}

/* Extensions Card */
.profile-extensions-card {
  background: #ffffff;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.04);
  padding: 16px 20px;
}
.extensions-tab-bar {
  margin-bottom: 16px;
}
.sub-tab-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.sub-tab-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-bottom: 12px;
  border-bottom: 1px solid #f0f0f0;
}
.sub-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 2px 0;
}
.sub-desc {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

/* Demographics Detail Grid */
.demographics-detail-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}
.detail-tile {
  background: #f8fafc;
  padding: 12px 14px;
  border-radius: 8px;
  border: 1px solid #f1f5f9;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.tile-label { font-size: 11.5px; color: #737373; font-weight: 500; }
.tile-value { font-size: 13.5px; color: #404040; font-weight: 600; }

.statutory-notice-box {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  background: #f0f9ff;
  border: 1px solid #bae6fd;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 12.5px;
  color: #0369a1;
}
.notice-icon { flex-shrink: 0; margin-top: 2px; }
.notice-text { line-height: 1.5; }

/* Sub-Item Cards */
.cards-list-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 14px;
}
.sub-item-card {
  background: #fafafa;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.item-card-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.card-tag-group {
  display: flex;
  align-items: center;
  gap: 6px;
}
.type-badge, .relation-badge {
  font-size: 10.5px;
  font-weight: 600;
  padding: 2px 7px;
  background: #e2e8f0;
  color: #334155;
  border-radius: 4px;
}
.primary-badge {
  font-size: 10px;
  font-weight: 700;
  background: #ecfdf5;
  color: #059669;
  padding: 2px 6px;
  border-radius: 4px;
}
.beneficiary-pill {
  font-size: 10.5px;
  font-weight: 600;
  padding: 2px 7px;
  border-radius: 4px;
}
.beneficiary-pill.is-ben { background: #e0f2fe; color: #0284c7; }
.beneficiary-pill.non-ben { background: #f3f4f6; color: #6b7280; }

.btn-delete-item {
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  padding: 4px;
  border-radius: 4px;
}
.btn-delete-item:hover {
  background: #fee2e2;
  color: #dc2626;
}

.address-line-main {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
  margin-bottom: 6px;
}
.map-icon { color: #0B529C; }
.address-meta-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 4px 10px;
  font-size: 12px;
  color: #737373;
}

.dependent-name, .qual-field, .cert-name {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 2px 0;
}
.dependent-meta-line, .qual-dates-row, .cert-expiry-row {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #737373;
}
.institution-name {
  font-size: 12.5px;
  color: #0B529C;
  font-weight: 500;
  margin-bottom: 4px;
}
.benefit-notes-box {
  display: flex;
  align-items: center;
  gap: 6px;
  background: #ffffff;
  padding: 6px 8px;
  border-radius: 6px;
  font-size: 11.5px;
  color: #475569;
  border: 1px solid #e2e8f0;
}
.qual-level-pill {
  font-size: 11px;
  font-weight: 600;
  background: #eff6ff;
  color: #1d4ed8;
  padding: 2px 8px;
  border-radius: 6px;
}
.gpa-tag {
  font-weight: 600;
  color: #059669;
  background: #ecfdf5;
  padding: 1px 6px;
  border-radius: 4px;
}
.cert-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  font-weight: 600;
  background: #fef3c7;
  color: #92400e;
  padding: 2px 8px;
  border-radius: 6px;
}

/* Experience Timeline */
.experience-timeline {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.experience-card {
  background: #fafafa;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.exp-card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}
.exp-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 2px 0;
}
.exp-employer {
  font-size: 12.5px;
  color: #0B529C;
  font-weight: 500;
}
.exp-right-tags {
  display: flex;
  align-items: center;
  gap: 8px;
}
.emp-type-pill {
  font-size: 11px;
  font-weight: 500;
  background: #e2e8f0;
  color: #334155;
  padding: 2px 8px;
  border-radius: 6px;
  text-transform: capitalize;
}
.exp-dates {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #737373;
}
.exp-narrative {
  font-size: 12.5px;
  color: #4b5563;
  margin: 4px 0;
  line-height: 1.4;
}
.exp-reference-box {
  font-size: 12px;
  color: #6b7280;
  background: #ffffff;
  padding: 6px 10px;
  border-radius: 6px;
  border: 1px solid #e5e7eb;
}

/* Skills & Languages Two Column */
.skills-lang-two-col {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}
.col-section {
  background: #fafafa;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  padding: 14px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.section-top-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid #e5e7eb;
  padding-bottom: 8px;
}
.col-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.col-sub {
  font-size: 11.5px;
  color: #737373;
  margin: 0;
}

.skills-chips-wrap {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.skill-item-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #ffffff;
  padding: 8px 12px;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
}
.skill-title {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  text-transform: capitalize;
}
.skill-exp {
  font-size: 11px;
  color: #737373;
  margin-left: 6px;
}
.skill-right {
  display: flex;
  align-items: center;
  gap: 8px;
}
.prof-pill {
  font-size: 10.5px;
  font-weight: 600;
  padding: 2px 7px;
  border-radius: 6px;
  text-transform: capitalize;
}
.prof-beginner { background: #f1f5f9; color: #475569; }
.prof-intermediate { background: #e0f2fe; color: #0369a1; }
.prof-advanced { background: #ecfdf5; color: #047857; }
.prof-expert { background: #fef3c7; color: #b45309; }

.btn-del-mini {
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  padding: 2px;
  border-radius: 4px;
}
.btn-del-mini:hover { color: #dc2626; }

.languages-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.language-card {
  background: #ffffff;
  padding: 10px 12px;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.lang-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.lang-title-group {
  display: flex;
  align-items: center;
  gap: 6px;
}
.lang-name {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}
.native-tag {
  font-size: 10px;
  font-weight: 700;
  background: #ecfdf5;
  color: #059669;
  padding: 1px 5px;
  border-radius: 4px;
}
.lang-right-tag {
  display: flex;
  align-items: center;
  gap: 6px;
}
.summary-prof-tag {
  font-size: 11px;
  color: #737373;
  background: #f3f4f6;
  padding: 2px 6px;
  border-radius: 4px;
}
.axes-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 6px;
}
.axis-box {
  background: #f8fafc;
  padding: 6px 8px;
  border-radius: 6px;
  display: flex;
  flex-direction: column;
  align-items: center;
}
.axis-lbl { font-size: 10px; color: #737373; text-transform: uppercase; }
.axis-val { font-size: 11.5px; font-weight: 600; color: #0B529C; text-transform: capitalize; }

.sub-empty-state {
  grid-column: span 2;
  text-align: center;
  padding: 30px;
  color: #737373;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}
.sub-empty-state-mini {
  text-align: center;
  padding: 20px;
  font-size: 12px;
  color: #9ca3af;
}

/* Modal Form Styles */
.modal-form-body {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.form-grid-two {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}
</style>
